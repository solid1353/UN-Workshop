from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


def consolidated_patches(plan_path: Path) -> list[tuple[int, bytes, bytes]]:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    patches: dict[int, tuple[bytes, bytes]] = {}
    for action in plan["actions"]:
        if action["action"] != "patch_memory":
            continue
        address = int(action["address"], 0)
        expected = bytes.fromhex(action["expected_hex"])
        replacement = bytes.fromhex(action["replacement_hex"])
        if address in patches:
            initial, current = patches[address]
            if current != expected:
                raise ValueError(
                    f"non-contiguous patch chain at 0x{address:08X}: "
                    f"{current.hex()} != {expected.hex()}"
                )
            patches[address] = (initial, replacement)
        else:
            patches[address] = (expected, replacement)
    return [
        (address, expected, replacement)
        for address, (expected, replacement) in sorted(patches.items())
        if expected != replacement
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("plan", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = args.source.resolve()
    plan = args.plan.resolve()
    output = args.output.resolve()
    if output.exists():
        raise FileExistsError(output)
    if not source.is_dir():
        raise ValueError(f"savestate is not a directory: {source}")

    source_files = sorted(
        path.relative_to(source) for path in source.rglob("*") if path.is_file()
    )
    if Path("eeMemory.bin") not in source_files:
        raise ValueError("savestate does not contain eeMemory.bin")

    memory = bytearray((source / "eeMemory.bin").read_bytes())
    if len(memory) != 32 * 1024 * 1024:
        raise ValueError(f"unexpected EE memory size: {len(memory)}")

    applied = 0
    for address, expected, replacement in consolidated_patches(plan):
        live = bytes(memory[address : address + len(expected)])
        if live != expected:
            raise ValueError(
                f"guard failed at 0x{address:08X}: "
                f"{live.hex()} != {expected.hex()}"
            )
        if len(expected) != len(replacement):
            raise ValueError(f"size change at 0x{address:08X}")
        memory[address : address + len(expected)] = replacement
        applied += 1
    shutil.copytree(source, output)
    memory_path = output / "eeMemory.bin"
    memory_path.write_bytes(memory)

    output_files = sorted(
        path.relative_to(output) for path in output.rglob("*") if path.is_file()
    )
    if output_files != source_files:
        raise ValueError("savestate inventory changed")
    patched_memory = memory_path.read_bytes()
    for address, _, replacement in consolidated_patches(plan):
        if patched_memory[address : address + len(replacement)] != replacement:
            raise ValueError(f"output verification failed at 0x{address:08X}")

    print(f"patches={applied}")
    print(f"output={output}")
    print(f"files={len(output_files)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
