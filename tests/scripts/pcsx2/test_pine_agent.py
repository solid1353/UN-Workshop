from __future__ import annotations

import importlib.util
import os
import struct
import sys
import unittest
from pathlib import Path

from scripts.lib.paths import load_workshop_paths


REPOSITORY = Path(__file__).resolve().parents[3]
MODULE_PATH = load_workshop_paths(REPOSITORY).files["pcsx2_pine_command"]
SPEC = importlib.util.spec_from_file_location("workshop_pine", MODULE_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"could not load {MODULE_PATH}")
PINE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = PINE
SPEC.loader.exec_module(PINE)


class PineAgentInputTests(unittest.TestCase):
    def test_pad_state_builds_full_dualshock_state(self) -> None:
        state = PINE.PadState.from_controls(
            ["start", "left", "cross"],
            pressures={"cross": 0x40, "r2": 0x20},
            right_stick=(1, 2),
            left_stick=(3, 4),
        )

        self.assertEqual(len(state.data), 18)
        self.assertEqual(state.data[:6], bytes([0x77, 0xBD, 1, 2, 3, 4]))
        self.assertEqual(state.data[7], 0xFF)
        self.assertEqual(state.data[12], 0x40)
        self.assertEqual(state.data[17], 0x20)
        self.assertEqual(PINE.PadState.neutral().data, PINE.PAD_NEUTRAL_STATE)

    def test_pad_state_rejects_bad_controls(self) -> None:
        with self.assertRaisesRegex(ValueError, "unknown pad button"):
            PINE.PadState.from_controls(["invalid"])
        with self.assertRaisesRegex(ValueError, "no pressure channel"):
            PINE.PadState.from_controls(pressures={"start": 1})
        with self.assertRaisesRegex(ValueError, "exactly 18 bytes"):
            PINE.PadState(b"short")

    def test_agent_commands_match_v1_wire_schema(self) -> None:
        neutral = PINE.PadState.neutral()
        cross = PINE.PadState.from_controls(["cross"])
        requests: list[bytes] = []

        def exchange(payload: bytes) -> bytes:
            requests.append(payload)
            opcode = payload[0]
            if opcode == PINE.STEP_FRAMES:
                return bytes([PINE.AGENT_INPUT_VERSION]) + struct.pack(
                    "<II", 100, 103
                )
            if opcode == PINE.GET_PAD_STATES:
                return (
                    bytes([PINE.AGENT_INPUT_VERSION, 2, 0, 1])
                    + cross.data
                    + bytes([1, 0])
                    + neutral.data
                )
            return bytes([PINE.AGENT_INPUT_VERSION])

        client = object.__new__(PINE.PineClient)
        client.exchange = exchange

        client.set_pad_states({1: neutral, 0: cross})
        self.assertEqual(
            requests[-1],
            bytes([PINE.SET_PAD_STATES, 1, 2, 0])
            + cross.data
            + bytes([1])
            + neutral.data,
        )

        step = client.step_frames(3, {0: cross})
        self.assertEqual(step, PINE.FrameStep(100, 103))
        self.assertEqual(
            requests[-1],
            bytes([PINE.STEP_FRAMES, 1])
            + struct.pack("<I", 3)
            + bytes([1, 0])
            + cross.data,
        )

        states = client.get_pad_states([0, 1])
        self.assertEqual(requests[-1], bytes([PINE.GET_PAD_STATES, 1, 2, 0, 1]))
        self.assertEqual(states[0], PINE.PadReadback(0, True, cross))
        self.assertEqual(states[1], PINE.PadReadback(1, False, neutral))

        client.release_pad_states([1])
        self.assertEqual(requests[-1], bytes([PINE.RELEASE_PAD_STATES, 1, 1, 1]))
        client.release_pad_states()
        self.assertEqual(requests[-1], bytes([PINE.RELEASE_PAD_STATES, 1, 0]))

    def test_agent_commands_reject_ambiguous_requests(self) -> None:
        client = object.__new__(PINE.PineClient)
        client.exchange = lambda _payload: bytes([PINE.AGENT_INPUT_VERSION])

        with self.assertRaisesRegex(ValueError, "count is outside 1..8"):
            client.set_pad_states({})
        with self.assertRaisesRegex(ValueError, "must be unique"):
            client.get_pad_states([0, 0])
        with self.assertRaisesRegex(ValueError, "frame count"):
            client.step_frames(0, {0: PINE.PadState.neutral()})

    def test_replay_analysis_commands_match_v1_wire_schema(self) -> None:
        requests: list[bytes] = []

        def exchange(payload: bytes) -> bytes:
            requests.append(payload)
            if payload[0] == PINE.REPLAY_STATUS:
                return bytes([PINE.REPLAY_ANALYSIS_VERSION]) + struct.pack(
                    "<III", 120, 900, 4567
                )
            if payload[0] == PINE.REPLAY_STEP:
                return bytes([PINE.REPLAY_ANALYSIS_VERSION]) + struct.pack(
                    "<IIII", 120, 123, 4567, 4570
                )
            return bytes([PINE.REPLAY_ANALYSIS_VERSION])

        client = object.__new__(PINE.PineClient)
        client.exchange = exchange

        status = client.replay_status()
        self.assertEqual(status, PINE.ReplayStatus(120, 900, 4567))
        self.assertEqual(
            requests[-1],
            bytes([PINE.REPLAY_STATUS, PINE.REPLAY_ANALYSIS_VERSION]),
        )

        step = client.replay_step(3)
        self.assertEqual(step, PINE.ReplayStep(120, 123, 4567, 4570))
        self.assertEqual(
            requests[-1],
            bytes([PINE.REPLAY_STEP, PINE.REPLAY_ANALYSIS_VERSION])
            + struct.pack("<I", 3),
        )

        screenshot = os.path.abspath("replay-frame.png")
        client.replay_screenshot(screenshot)
        encoded = screenshot.encode("utf-8")
        self.assertEqual(
            requests[-1],
            bytes([PINE.REPLAY_SCREENSHOT, PINE.REPLAY_ANALYSIS_VERSION])
            + struct.pack("<I", len(encoded))
            + encoded,
        )

        client.replay_gs_dump(screenshot, 4)
        self.assertEqual(
            requests[-1],
            bytes([PINE.REPLAY_GS_DUMP, PINE.REPLAY_ANALYSIS_VERSION])
            + struct.pack("<II", 4, len(encoded))
            + encoded,
        )

        client.replay_shutdown()
        self.assertEqual(
            requests[-1],
            bytes([PINE.REPLAY_SHUTDOWN, PINE.REPLAY_ANALYSIS_VERSION]),
        )

    def test_replay_analysis_rejects_invalid_requests(self) -> None:
        client = object.__new__(PINE.PineClient)
        client.exchange = lambda _payload: bytes([PINE.REPLAY_ANALYSIS_VERSION])

        with self.assertRaisesRegex(ValueError, "VBlank count"):
            client.replay_step(0)
        with self.assertRaisesRegex(ValueError, "must be absolute"):
            client.replay_screenshot("relative.png")
        with self.assertRaisesRegex(ValueError, "must be absolute"):
            client.replay_gs_dump("relative.png", 4)

    def test_replay_step_accepts_initial_vblank_offset(self) -> None:
        client = object.__new__(PINE.PineClient)
        client.exchange = lambda _payload: (
            bytes([PINE.REPLAY_ANALYSIS_VERSION])
            + struct.pack("<IIII", 0, 1, 0, 0)
        )

        self.assertEqual(client.replay_step(1), PINE.ReplayStep(0, 1, 0, 0))

    def test_batch_read_uses_one_compound_pine_request(self) -> None:
        requests: list[bytes] = []

        def exchange(payload: bytes) -> bytes:
            requests.append(payload)
            return struct.pack("<III", 0x11111111, 0x22222222, 0x33333333)

        client = object.__new__(PINE.PineClient)
        client.exchange = exchange

        values = client.read_ranges(((0x1000, 8), (0x2000, 4)))

        self.assertEqual(
            requests,
            [
                bytes([PINE.READ32])
                + struct.pack("<I", 0x1000)
                + bytes([PINE.READ32])
                + struct.pack("<I", 0x1004)
                + bytes([PINE.READ32])
                + struct.pack("<I", 0x2000)
            ],
        )
        self.assertEqual(
            values,
            (
                struct.pack("<II", 0x11111111, 0x22222222),
                struct.pack("<I", 0x33333333),
            ),
        )
        self.assertEqual(
            client.read_words((0x1000, 0x1004, 0x2000)),
            (0x11111111, 0x22222222, 0x33333333),
        )


if __name__ == "__main__":
    unittest.main()
