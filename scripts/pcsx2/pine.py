#!/usr/bin/env python3
from __future__ import annotations

import argparse
import socket
import struct
from dataclasses import dataclass
from typing import Mapping, Sequence


READ32 = 0x02
WRITE32 = 0x06
LOAD_STATE = 0x0A
STATUS = 0x0F
SCREENSHOT = 0x11
PAUSE = 0x12
RESUME = 0x13
CLEAR_EXECUTION_CACHES = 0x14
PAD_PULSE = 0x15
SET_PAD_STATES = 0x16
STEP_FRAMES = 0x17
GET_PAD_STATES = 0x18
RELEASE_PAD_STATES = 0x19

AGENT_INPUT_VERSION = 1
PAD_STATE_SIZE = 18
PAD_NEUTRAL_STATE = bytes.fromhex(
    "FF FF 7F 7F 7F 7F 00 00 00 00 00 00 00 00 00 00 00 00"
)

PAD_BUTTONS = {
    "up": 0,
    "right": 1,
    "down": 2,
    "left": 3,
    "triangle": 4,
    "circle": 5,
    "cross": 6,
    "square": 7,
    "select": 8,
    "start": 9,
    "l1": 10,
    "l2": 11,
    "r1": 12,
    "r2": 13,
    "l3": 14,
    "r3": 15,
}

PAD_DIGITAL_BITS = {
    "select": (0, 0),
    "l3": (0, 1),
    "r3": (0, 2),
    "start": (0, 3),
    "up": (0, 4),
    "right": (0, 5),
    "down": (0, 6),
    "left": (0, 7),
    "l2": (1, 0),
    "r2": (1, 1),
    "l1": (1, 2),
    "r1": (1, 3),
    "triangle": (1, 4),
    "circle": (1, 5),
    "cross": (1, 6),
    "square": (1, 7),
}

PAD_PRESSURE_OFFSETS = {
    "right": 6,
    "left": 7,
    "up": 8,
    "down": 9,
    "triangle": 10,
    "circle": 11,
    "cross": 12,
    "square": 13,
    "l1": 14,
    "r1": 15,
    "l2": 16,
    "r2": 17,
}

STATUS_NAMES = {
    0: "running",
    1: "paused",
    2: "shutdown",
}


def _pad_byte(value: int, name: str) -> int:
    if not isinstance(value, int) or not 0 <= value <= 0xFF:
        raise ValueError(f"{name} is outside 0..255")
    return value


@dataclass(frozen=True)
class PadState:
    data: bytes = PAD_NEUTRAL_STATE

    def __post_init__(self) -> None:
        data = bytes(self.data)
        if len(data) != PAD_STATE_SIZE:
            raise ValueError(
                f"pad state must contain exactly {PAD_STATE_SIZE} bytes"
            )
        object.__setattr__(self, "data", data)

    @classmethod
    def neutral(cls) -> "PadState":
        return cls()

    @classmethod
    def from_controls(
        cls,
        buttons: Sequence[str] = (),
        *,
        pressures: Mapping[str, int] | None = None,
        right_stick: tuple[int, int] = (0x7F, 0x7F),
        left_stick: tuple[int, int] = (0x7F, 0x7F),
    ) -> "PadState":
        data = bytearray(PAD_NEUTRAL_STATE)
        pressed = set(buttons)
        unknown = pressed.difference(PAD_DIGITAL_BITS)
        if unknown:
            raise ValueError(f"unknown pad button: {sorted(unknown)[0]}")

        pressure_values = dict(pressures or {})
        unknown_pressures = set(pressure_values).difference(
            PAD_PRESSURE_OFFSETS
        )
        if unknown_pressures:
            raise ValueError(
                f"button has no pressure channel: "
                f"{sorted(unknown_pressures)[0]}"
            )
        for button, value in pressure_values.items():
            _pad_byte(value, f"{button} pressure")
            if value:
                pressed.add(button)

        for button in pressed:
            group, bit = PAD_DIGITAL_BITS[button]
            data[group] &= ~(1 << bit)
            pressure_offset = PAD_PRESSURE_OFFSETS.get(button)
            if pressure_offset is not None:
                data[pressure_offset] = pressure_values.get(button, 0xFF)

        if len(right_stick) != 2 or len(left_stick) != 2:
            raise ValueError("stick positions must be (x, y) pairs")
        data[2] = _pad_byte(right_stick[0], "right stick x")
        data[3] = _pad_byte(right_stick[1], "right stick y")
        data[4] = _pad_byte(left_stick[0], "left stick x")
        data[5] = _pad_byte(left_stick[1], "left stick y")
        return cls(bytes(data))


@dataclass(frozen=True)
class FrameStep:
    start_frame: int
    end_frame: int


@dataclass(frozen=True)
class PadReadback:
    slot: int
    controlled: bool
    state: PadState


class PineClient:
    def __init__(self, port: int) -> None:
        self.socket = socket.create_connection(("127.0.0.1", port), timeout=3)
        self.socket.settimeout(3)

    def close(self) -> None:
        self.socket.close()

    def __enter__(self) -> "PineClient":
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()

    def _receive(self, size: int) -> bytes:
        result = bytearray()
        while len(result) < size:
            chunk = self.socket.recv(size - len(result))
            if not chunk:
                raise RuntimeError("PCSX2 closed the PINE connection")
            result.extend(chunk)
        return bytes(result)

    def exchange(self, payload: bytes) -> bytes:
        self.socket.sendall(struct.pack("<I", len(payload) + 4) + payload)
        reply_size = struct.unpack("<I", self._receive(4))[0]
        if reply_size < 5:
            raise RuntimeError(f"PINE returned invalid reply size {reply_size}")
        reply = self._receive(reply_size - 4)
        if reply[0] != 0:
            raise RuntimeError("PCSX2 rejected the PINE request")
        return reply[1:]

    def command(self, opcode: int) -> None:
        if self.exchange(bytes([opcode])):
            raise RuntimeError(f"PINE opcode 0x{opcode:02X} returned unexpected data")

    def status(self) -> str:
        reply = self.exchange(bytes([STATUS]))
        if len(reply) != 4:
            raise RuntimeError("PINE Status returned a malformed reply")
        value = struct.unpack("<I", reply)[0]
        try:
            return STATUS_NAMES[value]
        except KeyError as exc:
            raise RuntimeError(f"PINE returned unknown status {value}") from exc

    def pause(self) -> None:
        self.command(PAUSE)

    def load_state(self, slot: int) -> None:
        if not 0 <= slot <= 255:
            raise ValueError("savestate slot is outside 0..255")
        if self.exchange(bytes([LOAD_STATE, slot])):
            raise RuntimeError("PINE LoadState returned unexpected data")
        # LoadState is queued by PCSX2. The synchronous pause is a barrier:
        # its CPU-thread callback runs only after the queued load completes.
        self.pause()

    def resume(self) -> None:
        self.command(RESUME)

    def clear_execution_caches(self) -> None:
        self.command(CLEAR_EXECUTION_CACHES)

    def screenshot(self) -> None:
        self.command(SCREENSHOT)

    def pad_pulse(
        self, button: int, duration_ms: int, controller: int = 0
    ) -> None:
        if not 0 <= controller <= 7:
            raise ValueError("controller is outside 0..7")
        if not 0 <= button <= 15:
            raise ValueError("button is outside 0..15")
        if not 1 <= duration_ms <= 1000:
            raise ValueError("pulse duration is outside 1..1000 ms")
        reply = self.exchange(
            bytes([PAD_PULSE, controller, button])
            + struct.pack("<H", duration_ms)
        )
        if reply:
            raise RuntimeError("PINE PadPulse returned unexpected data")

    @staticmethod
    def _pad_records(
        states: Mapping[int, PadState | bytes],
    ) -> bytes:
        if not 1 <= len(states) <= 8:
            raise ValueError("pad state count is outside 1..8")
        records = bytearray()
        for slot, state in sorted(states.items()):
            if not isinstance(slot, int) or not 0 <= slot <= 7:
                raise ValueError("controller slot is outside 0..7")
            pad_state = state if isinstance(state, PadState) else PadState(state)
            records.append(slot)
            records.extend(pad_state.data)
        return bytes([AGENT_INPUT_VERSION, len(states)]) + bytes(records)

    @staticmethod
    def _pad_slots(slots: Sequence[int], *, allow_empty: bool) -> bytes:
        if not allow_empty and not 1 <= len(slots) <= 8:
            raise ValueError("controller slot count is outside 1..8")
        if allow_empty and len(slots) > 8:
            raise ValueError("controller slot count is outside 0..8")
        if len(set(slots)) != len(slots):
            raise ValueError("controller slots must be unique")
        for slot in slots:
            if not isinstance(slot, int) or not 0 <= slot <= 7:
                raise ValueError("controller slot is outside 0..7")
        return bytes([AGENT_INPUT_VERSION, len(slots), *slots])

    @staticmethod
    def _expect_agent_version(reply: bytes, operation: str) -> bytes:
        if not reply or reply[0] != AGENT_INPUT_VERSION:
            raise RuntimeError(
                f"PINE {operation} returned an unsupported agent-input reply"
            )
        return reply[1:]

    def set_pad_states(
        self, states: Mapping[int, PadState | bytes]
    ) -> None:
        reply = self.exchange(
            bytes([SET_PAD_STATES]) + self._pad_records(states)
        )
        body = self._expect_agent_version(reply, "SetPadStates")
        if body:
            raise RuntimeError("PINE SetPadStates returned a malformed reply")

    def step_frames(
        self, frame_count: int, states: Mapping[int, PadState | bytes]
    ) -> FrameStep:
        if not isinstance(frame_count, int) or not 1 <= frame_count <= 0xFFFFFFFF:
            raise ValueError("frame count is outside 1..4294967295")
        reply = self.exchange(
            bytes([STEP_FRAMES, AGENT_INPUT_VERSION])
            + struct.pack("<I", frame_count)
            + self._pad_records(states)[1:]
        )
        body = self._expect_agent_version(reply, "StepFrames")
        if len(body) != 8:
            raise RuntimeError("PINE StepFrames returned a malformed reply")
        start_frame, end_frame = struct.unpack("<II", body)
        if (end_frame - start_frame) & 0xFFFFFFFF != frame_count:
            raise RuntimeError(
                "PINE StepFrames returned an unexpected frame interval"
            )
        return FrameStep(start_frame, end_frame)

    def get_pad_states(self, slots: Sequence[int]) -> tuple[PadReadback, ...]:
        requested_slots = tuple(slots)
        reply = self.exchange(
            bytes([GET_PAD_STATES])
            + self._pad_slots(requested_slots, allow_empty=False)
        )
        body = self._expect_agent_version(reply, "GetPadStates")
        if not body or body[0] != len(requested_slots):
            raise RuntimeError("PINE GetPadStates returned a malformed reply")
        records = body[1:]
        record_size = 2 + PAD_STATE_SIZE
        if len(records) != record_size * len(requested_slots):
            raise RuntimeError("PINE GetPadStates returned a malformed reply")

        result = []
        returned_slots = set()
        for offset in range(0, len(records), record_size):
            slot = records[offset]
            controlled = records[offset + 1]
            if slot not in requested_slots or slot in returned_slots:
                raise RuntimeError(
                    "PINE GetPadStates returned an unexpected controller slot"
                )
            if controlled not in (0, 1):
                raise RuntimeError(
                    "PINE GetPadStates returned an invalid control flag"
                )
            returned_slots.add(slot)
            result.append(
                PadReadback(
                    slot,
                    bool(controlled),
                    PadState(records[offset + 2 : offset + record_size]),
                )
            )
        if returned_slots != set(requested_slots):
            raise RuntimeError(
                "PINE GetPadStates omitted a requested controller slot"
            )
        return tuple(result)

    def release_pad_states(self, slots: Sequence[int] = ()) -> None:
        reply = self.exchange(
            bytes([RELEASE_PAD_STATES])
            + self._pad_slots(tuple(slots), allow_empty=True)
        )
        body = self._expect_agent_version(reply, "ReleasePadStates")
        if body:
            raise RuntimeError("PINE ReleasePadStates returned a malformed reply")

    def read32(self, address: int) -> int:
        reply = self.exchange(bytes([READ32]) + struct.pack("<I", address))
        if len(reply) != 4:
            raise RuntimeError("PINE Read32 returned a malformed reply")
        return struct.unpack("<I", reply)[0]

    def write32(self, address: int, value: int) -> None:
        reply = self.exchange(
            bytes([WRITE32]) + struct.pack("<II", address, value)
        )
        if reply:
            raise RuntimeError("PINE Write32 returned unexpected data")

    def read(self, address: int, length: int) -> bytes:
        if address % 4 or length < 0 or length % 4:
            raise ValueError("PINE memory ranges must contain aligned EE words")
        return b"".join(
            struct.pack("<I", self.read32(address + offset))
            for offset in range(0, length, 4)
        )

    def write(self, address: int, value: bytes) -> None:
        if address % 4 or len(value) % 4:
            raise ValueError("PINE memory ranges must contain aligned EE words")
        for offset in range(0, len(value), 4):
            self.write32(
                address + offset,
                int.from_bytes(value[offset : offset + 4], "little"),
            )


def integer(value: str) -> int:
    try:
        return int(value, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid integer: {value!r}") from exc


def pad_state_spec(value: str) -> tuple[int, PadState]:
    slot_text, separator, state_text = value.partition("=")
    if not separator:
        raise argparse.ArgumentTypeError(
            "pad state must use SLOT=36_HEX_DIGITS"
        )
    try:
        slot = integer(slot_text)
        state = PadState(bytes.fromhex(state_text))
    except (argparse.ArgumentTypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError(str(exc)) from exc
    if not 0 <= slot <= 7:
        raise argparse.ArgumentTypeError("controller slot is outside 0..7")
    return slot, state


def pad_state_map(
    specifications: Sequence[tuple[int, PadState]],
) -> dict[int, PadState]:
    states = dict(specifications)
    if len(states) != len(specifications):
        raise ValueError("controller slots must be unique")
    return states


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Direct PCSX2 PINE client.")
    parser.add_argument("--port", required=True, type=int)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    commands.add_parser("pause")
    commands.add_parser("resume")
    commands.add_parser("refresh")
    commands.add_parser("screenshot")
    pad_pulse = commands.add_parser("pad-pulse")
    pad_pulse.add_argument("button", choices=sorted(PAD_BUTTONS))
    pad_pulse.add_argument("--controller", type=integer, default=0)
    pad_pulse.add_argument("--milliseconds", type=integer, default=100)
    set_states = commands.add_parser("set-states")
    set_states.add_argument("states", nargs="+", type=pad_state_spec)
    step = commands.add_parser("step")
    step.add_argument("frames", type=integer)
    step.add_argument("states", nargs="+", type=pad_state_spec)
    get_states = commands.add_parser("get-states")
    get_states.add_argument("slots", nargs="+", type=integer)
    release = commands.add_parser("release")
    release.add_argument("slots", nargs="*", type=integer)
    load_state = commands.add_parser("load-state")
    load_state.add_argument("slot", type=integer)
    read = commands.add_parser("read")
    read.add_argument("address", type=integer)
    read.add_argument("length", type=integer)
    write = commands.add_parser("write")
    write.add_argument("address", type=integer)
    write.add_argument("hex_bytes")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not 1 <= args.port <= 65535:
        raise ValueError("PINE port is outside 1..65535")
    with PineClient(args.port) as client:
        if args.command == "status":
            print(client.status())
        elif args.command == "pause":
            client.pause()
            print(client.status())
        elif args.command == "load-state":
            client.load_state(args.slot)
            print(f"savestate slot {args.slot} loaded; paused")
        elif args.command == "resume":
            client.resume()
            print(client.status())
        elif args.command == "refresh":
            client.clear_execution_caches()
            print("execution caches cleared")
        elif args.command == "screenshot":
            client.screenshot()
            print("screenshot queued")
        elif args.command == "pad-pulse":
            client.pad_pulse(
                PAD_BUTTONS[args.button],
                args.milliseconds,
                args.controller,
            )
            print(
                f"controller {args.controller} {args.button} pulsed for "
                f"{args.milliseconds} ms"
            )
        elif args.command == "set-states":
            states = pad_state_map(args.states)
            client.set_pad_states(states)
            print(f"set {len(states)} controller state(s)")
        elif args.command == "step":
            states = pad_state_map(args.states)
            result = client.step_frames(args.frames, states)
            print(
                f"advanced {args.frames} frame(s): "
                f"{result.start_frame} -> {result.end_frame}"
            )
        elif args.command == "get-states":
            for state in client.get_pad_states(args.slots):
                print(
                    f"slot={state.slot} controlled={int(state.controlled)} "
                    f"state={state.state.data.hex().upper()}"
                )
        elif args.command == "release":
            client.release_pad_states(args.slots)
            target = ",".join(str(slot) for slot in args.slots) or "all"
            print(f"released controller state(s): {target}")
        elif args.command == "read":
            print(client.read(args.address, args.length).hex().upper())
        elif args.command == "write":
            value = bytes.fromhex(args.hex_bytes)
            client.write(args.address, value)
            print(f"wrote {len(value)} bytes")
        else:
            raise AssertionError(args.command)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
