"""Client for PPSSPP's WebSocket debugger, the fork's counterpart of PINE."""
from __future__ import annotations

import argparse
import base64
import binascii
from dataclasses import dataclass
import json
import os
from pathlib import Path
import socket
import struct
import sys
import time
from typing import Any, Sequence

TIMEOUT_SECONDS = 10.0
SUBPROTOCOL = "debugger.ppsspp.org"
OP_TEXT = 0x1
OP_CLOSE = 0x8
OP_PING = 0x9
OP_PONG = 0xA

# The PSP buttons a pad state can name, as input.buttons.send spells them.
BUTTONS = (
    "cross", "circle", "triangle", "square", "up", "down", "left", "right",
    "start", "select", "ltrigger", "rtrigger",
)


class DebuggerError(RuntimeError):
    """PPSSPP answered a request with an error."""


@dataclass(frozen=True)
class PadState:
    buttons: tuple[str, ...] = ()
    x: float = 0.0
    y: float = 0.0

    def __post_init__(self) -> None:
        unknown = [button for button in self.buttons if button not in BUTTONS]
        if unknown:
            raise ValueError(f"unknown buttons: {', '.join(unknown)}")
        if not -1.0 <= self.x <= 1.0 or not -1.0 <= self.y <= 1.0:
            raise ValueError("stick values must be inside -1.0..1.0")

    def to_json(self) -> dict[str, Any]:
        return {"buttons": list(self.buttons), "x": self.x, "y": self.y}


@dataclass(frozen=True)
class FrameStep:
    start_frame: int
    end_frame: int


class DebuggerClient:
    def __init__(self, port: int, timeout: float = TIMEOUT_SECONDS) -> None:
        self._socket = socket.create_connection(("127.0.0.1", port), timeout=timeout)
        self._timeout = timeout
        self._buffer = b""
        self._ticket = 0
        self._upgrade(port)
        self.request("version", name="un-workshop", version="1")
        self.request("broadcast.config.set", disallowed={
            "logger": True, "game": True, "stepping": True, "input": True, "breakpoint": True,
        })

    def close(self) -> None:
        self._socket.close()

    def __enter__(self) -> "DebuggerClient":
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()

    def _upgrade(self, port: int) -> None:
        key = base64.b64encode(os.urandom(16)).decode("ascii")
        self._socket.sendall((
            f"GET /debugger HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nUpgrade: websocket\r\n"
            f"Connection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n"
            f"Sec-WebSocket-Protocol: {SUBPROTOCOL}\r\n\r\n"
        ).encode("ascii"))
        while b"\r\n\r\n" not in self._buffer:
            self._fill()
        head, self._buffer = self._buffer.split(b"\r\n\r\n", 1)
        status = head.split(b"\r\n", 1)[0]
        if b" 101 " not in status + b" ":
            raise RuntimeError(f"PPSSPP refused the debugger connection: {status.decode('latin-1')}")

    def _fill(self) -> None:
        data = self._socket.recv(65536)
        if not data:
            raise ConnectionError("PPSSPP closed the debugger connection")
        self._buffer += data

    def _read(self, size: int) -> bytes:
        while len(self._buffer) < size:
            self._fill()
        data, self._buffer = self._buffer[:size], self._buffer[size:]
        return data

    def _send_frame(self, opcode: int, payload: bytes) -> None:
        size = len(payload)
        if size < 126:
            header = bytes((0x80 | opcode, 0x80 | size))
        elif size < 1 << 16:
            header = bytes((0x80 | opcode, 0x80 | 126)) + struct.pack(">H", size)
        else:
            header = bytes((0x80 | opcode, 0x80 | 127)) + struct.pack(">Q", size)
        mask = os.urandom(4)
        masked = bytes(value ^ mask[index & 3] for index, value in enumerate(payload))
        self._socket.sendall(header + mask + masked)

    def _receive_text(self) -> str:
        message = bytearray()
        while True:
            first, second = self._read(2)
            opcode = first & 0x0F
            size = second & 0x7F
            if size == 126:
                size = struct.unpack(">H", self._read(2))[0]
            elif size == 127:
                size = struct.unpack(">Q", self._read(8))[0]
            payload = self._read(size)
            if opcode == OP_PING:
                self._send_frame(OP_PONG, payload)
            elif opcode == OP_CLOSE:
                raise ConnectionError("PPSSPP closed the debugger connection")
            elif opcode != OP_PONG:
                message += payload
                if first & 0x80:
                    return message.decode("utf-8")

    def request(self, event: str, *, timeout: float | None = None, **params: Any) -> dict[str, Any]:
        """Send one request and wait for its answer, ignoring broadcasts."""
        self._ticket += 1
        ticket = self._ticket
        self._send_frame(OP_TEXT, json.dumps({"event": event, "ticket": ticket, **params}).encode("utf-8"))
        deadline = time.monotonic() + (self._timeout if timeout is None else timeout)
        while True:
            self._socket.settimeout(max(deadline - time.monotonic(), 0.001))
            reply = json.loads(self._receive_text())
            if reply.get("ticket") != ticket:
                continue
            if reply.get("event") == "error":
                raise DebuggerError(f"{event}: {reply.get('message')}")
            return reply

    def notify(self, event: str, **params: Any) -> None:
        """Send a request whose answer comes later as a broadcast, if at all."""
        self._send_frame(OP_TEXT, json.dumps({"event": event, **params}).encode("utf-8"))

    def status(self) -> str:
        reply = self.request("game.status")
        if reply.get("game") is None:
            return "shutdown"
        cpu = self.request("cpu.status")
        return "paused" if cpu["stepping"] or cpu["paused"] else "running"

    def wait_for_stepping(self, stepping: bool, timeout: float = TIMEOUT_SECONDS) -> None:
        deadline = time.monotonic() + timeout
        while self.request("cpu.status")["stepping"] != stepping:
            if time.monotonic() >= deadline:
                raise TimeoutError("the CPU did not change state in time")
            time.sleep(0.01)

    def pause(self) -> None:
        self.notify("cpu.stepping")
        self.wait_for_stepping(True)

    def resume(self) -> None:
        self.notify("cpu.resume")
        self.wait_for_stepping(False)

    def read(self, address: int, size: int) -> bytes:
        return base64.b64decode(self.request("memory.read", address=address, size=size)["base64"])

    def write(self, address: int, data: bytes) -> None:
        self.request("memory.write", address=address, base64=base64.b64encode(data).decode("ascii"))

    def load_state(self, path: str | os.PathLike[str] | None = None, slot: int | None = None) -> None:
        self._state("game.state.load", path, slot)

    def save_state(self, path: str | os.PathLike[str] | None = None, slot: int | None = None) -> None:
        self._state("game.state.save", path, slot)

    def _state(self, event: str, path: str | os.PathLike[str] | None, slot: int | None) -> None:
        if (path is None) == (slot is None):
            raise ValueError("name a path or a slot")
        target = {"path": os.fspath(path)} if path is not None else {"slot": slot}
        self.request(event, wait=True, timeout=120.0, **target)

    def screenshot(self, path: str | os.PathLike[str]) -> None:
        """PPSSPP reads the screen only while stopped, so a running game is paused around it."""
        running = self.status() == "running"
        if running:
            self.pause()
        try:
            uri = self.request("gpu.buffer.screenshot", timeout=30.0)["uri"]
        finally:
            if running:
                self.resume()
        Path(path).write_bytes(base64.b64decode(uri.partition("base64,")[2]))

    def ge_dump(self, path: str | os.PathLike[str]) -> None:
        reply = self.request("gpu.record.dump", timeout=60.0)
        Path(path).write_bytes(base64.b64decode(reply["uri"].partition("base64,")[2]))

    def pad_pulse(self, button: str, frames: int = 1) -> None:
        self.request("input.buttons.press", button=button, duration=frames, timeout=30.0)

    def set_pad_state(self, state: PadState) -> None:
        self.request("agent.input.set", state=state.to_json())

    def get_pad_state(self) -> dict[str, Any]:
        return self.request("agent.input.get")

    def release_pad_state(self) -> None:
        self.request("agent.input.release")

    def step_frames(self, frames: int, state: PadState | None = None, *, timeout: float = 120.0) -> FrameStep:
        params = {} if state is None else {"state": state.to_json()}
        reply = self.request("agent.step", frames=frames, timeout=timeout, **params)
        return FrameStep(reply["startFrame"], reply["endFrame"])

    def replay_status(self) -> dict[str, Any]:
        return self.request("agent.replay.status")

    def replay_step(self, vblanks: int, *, timeout: float = 120.0) -> FrameStep:
        reply = self.request("agent.replay.step", vblanks=vblanks, timeout=timeout)
        return FrameStep(reply["startFrame"], reply["endFrame"])

    def shutdown(self) -> None:
        self.request("agent.shutdown")


def pad_state(text: str) -> PadState:
    """Parse cross+up or cross+up@0.5,-1, buttons then stick x,y."""
    buttons, separator, stick = text.partition("@")
    x, y = (0.0, 0.0)
    if separator:
        x, y = (float(value) for value in stick.split(","))
    return PadState(tuple(button for button in buttons.split("+") if button), x, y)


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, required=True)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("status", "pause", "resume", "replay-status", "shutdown"):
        commands.add_parser(name)
    for name in ("screenshot", "ge-dump", "save-state", "load-state"):
        commands.add_parser(name).add_argument("path", type=Path)
    step = commands.add_parser("step")
    step.add_argument("frames", type=int)
    step.add_argument("--state", type=pad_state)
    replay_step = commands.add_parser("replay-step")
    replay_step.add_argument("vblanks", type=int)
    args = parser.parse_args(argv)

    with DebuggerClient(args.port) as client:
        match args.command:
            case "status":
                print(client.status())
            case "pause":
                client.pause()
            case "resume":
                client.resume()
            case "replay-status":
                print(json.dumps(client.replay_status()))
            case "shutdown":
                client.shutdown()
            case "screenshot":
                client.screenshot(args.path.resolve())
            case "ge-dump":
                client.ge_dump(args.path.resolve())
            case "save-state":
                client.save_state(args.path.resolve())
            case "load-state":
                client.load_state(args.path.resolve())
            case "step":
                print(client.step_frames(args.frames, args.state))
            case "replay-step":
                print(client.replay_step(args.vblanks))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, binascii.Error) as exc:
        print(f"[debugger] {exc}", file=sys.stderr)
        raise SystemExit(1)
