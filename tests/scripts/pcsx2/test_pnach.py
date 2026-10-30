from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
import io
from pathlib import Path
import sys
import unittest
from unittest import mock


REPOSITORY = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPOSITORY / "scripts" / "pcsx2"))
import pnach


class Clock:
    now = 0.0

    def sleep(self, seconds: float) -> None:
        self.now += seconds


class MemoryClient:
    def __init__(self, *, paused: bool = False, clock: Clock | None = None, stop: float = 2.0):
        self.state = "paused" if paused else "running"
        self.memory = dict(enumerate(bytes(range(16)), 0x1000))
        self.events = []
        self.written = []
        self.fail_write = False
        self.bad_readback = False
        self.clock = clock
        self.stop = stop

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        pass

    def status(self):
        if self.clock is not None and self.clock.now >= self.stop:
            return "shutdown"
        return self.state

    def pause(self):
        self.events.append("pause")
        self.state = "paused"

    def resume(self):
        self.events.append("resume")
        self.state = "running"

    def read32(self, address):
        value = int.from_bytes(self.bytes(address, 4), "little")
        return value ^ 1 if self.bad_readback and self.written else value

    def write32(self, address, value):
        self.events.append("write")
        if self.fail_write:
            raise RuntimeError("write failed")
        self.written.append((address, value))
        self.memory.update(enumerate(value.to_bytes(4, "little"), address))

    def clear_execution_caches(self):
        self.events.append("clear")

    def bytes(self, address, count):
        return bytes(self.memory.get(at, 0) for at in range(address, address + count))


class PnachTests(unittest.TestCase):
    def test_parses_widths_padding_bom_and_comments(self):
        writes = pnach.parse_file(
            b"\xef\xbb\xbf// comment\n; comment\n# comment\n\n"
            b"patch=0,EE,00001000,byte,000000FF // inline\n"
            b"patch=1,EE,00001002,short,00001234\n"
            b"patch=2,EE,00001004,word,3F800000\n"
            b"patch=3,EE,00001008,double,0123456789ABCDEF\n", "input"
        )
        self.assertEqual(
            [(write.address, write.data.hex()) for write in writes],
            [(0x1000, "ff"), (0x1002, "3412"), (0x1004, "0000803f"),
             (0x1008, "efcdab8967452301")],
        )

    def test_rejects_unsupported_or_invalid_writes(self):
        for text in (
            "[Section]", "crc=12345678", "gametitle=Example",
            "patch=1,IOP,00001000,word,0", "patch=1,EE,00001000,extended,0",
            "patch=1,EE,00001000,bytes,00", "patch=1,EE,00001000,beword,0",
            "patch=4,EE,00001000,word,0", "patch=1,EE,02000000,word,0",
            "patch=1,EE,01FFFFFF,short,0", "patch=1,EE,00001000,byte,100",
            "patch=1,EE,0x1000,word,0", "patch=1,EE,00001000,word,-1",
        ):
            with self.subTest(text=text), self.assertRaises(ValueError):
                pnach.parse_line(text)

    def test_bad_later_line_prevents_connecting(self):
        with (
            mock.patch.object(sys, "argv", ["pnach", "--port", "28071", "--line",
                "patch=1,EE,00001000,word,1", "--line", "invalid"]),
            mock.patch.object(pnach, "PineClient") as connect,
            self.assertRaisesRegex(ValueError, "inline:2"),
        ):
            pnach.main()
        connect.assert_not_called()

    def test_requires_explicit_valid_port_before_connecting(self):
        for options in ([], ["--port", "0"], ["--port", "65536"]):
            with (
                self.subTest(options=options),
                mock.patch.object(sys, "argv", ["pnach", "--line", "// no writes", *options]),
                mock.patch.object(pnach, "PineClient") as connect,
                redirect_stderr(io.StringIO()),
                self.assertRaises(SystemExit) as failure,
            ):
                pnach.main()
            self.assertEqual(failure.exception.code, 2)
            connect.assert_not_called()

    def test_file_and_inline_inputs_use_the_supplied_port(self):
        for options in (["edits.pnach"], ["--line", "patch=1,EE,00001000,word,3F800000"]):
            client = MemoryClient()
            with (
                self.subTest(options=options),
                mock.patch.object(sys, "argv", ["pnach", *options, "--port", "28071"]),
                mock.patch.object(Path, "read_bytes", return_value=b"patch=1,EE,00001000,word,3F800000"),
                mock.patch.object(pnach, "PineClient", return_value=client) as connect,
                redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(pnach.main(), 0)
            connect.assert_called_once_with(28071)
            self.assertEqual(client.bytes(0x1000, 4).hex(), "0000803f")
            self.assertEqual(client.events, ["pause", "write", "clear", "resume"])

    def test_overlapping_small_writes_preserve_adjacent_bytes(self):
        client = MemoryClient()
        writes = pnach.parse_lines([
            "patch=1,EE,00001001,byte,FF", "patch=1,EE,00001002,short,1122",
            "patch=1,EE,00001003,word,55667788",
        ], "input")
        self.assertEqual(pnach.apply(client, writes, ()), 3)
        self.assertEqual(client.bytes(0x1000, 8).hex(), "00ff228877665507")
        self.assertEqual(client.state, "running")
        self.assertEqual(client.events[0], "pause")
        self.assertEqual(client.events[-2:], ["clear", "resume"])

    def test_all_expectations_precede_any_write(self):
        client = MemoryClient()
        writes = pnach.parse_lines(["patch=1,EE,00001000,word,0"], "input")
        expectations = tuple(pnach.parse_expectation(text) for text in ("0x1000:0001", "1002:FFFF"))
        with self.assertRaisesRegex(RuntimeError, "expected bytes differ"):
            pnach.apply(client, writes, expectations)
        self.assertEqual(client.bytes(0x1000, 8), bytes(range(8)))
        self.assertEqual(client.written, [])
        self.assertEqual(client.events, ["pause", "resume"])

    def test_paused_game_stays_paused_and_accepts_unaligned_expectations(self):
        client = MemoryClient(paused=True)
        writes = pnach.parse_lines(["patch=1,EE,00001000,byte,FF"], "input")
        pnach.apply(client, writes, (pnach.parse_expectation("1001:01020304"),))
        self.assertEqual(client.state, "paused")
        self.assertEqual(client.events, ["write", "clear"])

    def test_write_and_readback_failures_clear_caches_and_restore_state(self):
        for failure in ("fail_write", "bad_readback"):
            client = MemoryClient()
            setattr(client, failure, True)
            writes = pnach.parse_lines(["patch=1,EE,00001000,word,0"], "input")
            with self.subTest(failure=failure), self.assertRaises(RuntimeError):
                pnach.apply(client, writes, ())
            self.assertEqual(client.events[-2:], ["clear", "resume"])
            self.assertEqual(client.state, "running")

    def run_watch(self, contents, *, delayed=False):
        clock = Clock()
        client = MemoryClient(clock=clock, stop=1.8)

        def connect(_port):
            if delayed:
                clock.now = 0.5
            return client

        with (
            mock.patch.object(pnach.time, "monotonic", side_effect=lambda: clock.now),
            mock.patch.object(pnach.time, "sleep", side_effect=clock.sleep),
            mock.patch.object(pnach, "connect_for_watch", side_effect=connect),
            mock.patch.object(Path, "read_bytes", side_effect=lambda: contents(clock.now)),
            redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()) as errors,
        ):
            pnach.watch(Path("edits.pnach"), 28071, ())
        return [value for _address, value in client.written], errors.getvalue()

    def test_watch_debounces_edits_and_applies_only_settled_content(self):
        def contents(now):
            value = 1 if now < 0.1 else 2 if now < 0.3 else 3
            return f"patch=1,EE,00001000,word,{value}".encode()
        values, errors = self.run_watch(contents)
        self.assertEqual(values, [1, 3])
        self.assertEqual(errors, "")

    def test_watch_rejects_a_bad_save_and_accepts_its_correction(self):
        def contents(now):
            return (b"patch=1,EE,00001000,word,1" if now < 0.1 else
                    b"invalid" if now < 0.8 else b"patch=1,EE,00001000,word,3")
        values, errors = self.run_watch(contents)
        self.assertEqual(values, [1, 3])
        self.assertIn("no writes applied", errors)

    def test_watch_first_application_uses_edits_made_while_waiting_for_launch(self):
        def contents(now):
            value = 1 if now < 0.1 else 3
            return f"patch=1,EE,00001000,word,{value}".encode()
        values, errors = self.run_watch(contents, delayed=True)
        self.assertEqual(values, [3])
        self.assertEqual(errors, "")


if __name__ == "__main__":
    unittest.main()
