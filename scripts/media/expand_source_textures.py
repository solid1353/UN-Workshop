"""Create missing, read-only CCS texture views in an existing source extraction."""
from __future__ import annotations

import argparse
import os
import shutil
import stat
import struct
import sys
from pathlib import Path

import ccs

REPOSITORY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPOSITORY))
from scripts.lib.paths import load_workshop_paths


def expand(root: Path, *, protect: bool = True) -> tuple[int, int]:
    root = root.resolve()
    configured = load_workshop_paths(REPOSITORY)
    source = configured.path("source").resolve()
    task = os.environ.get("UN_TASK_WORK_ROOT")
    in_source = root.parent == source and root.name.lower().endswith(".iso.files")
    in_task = task and root.is_relative_to(Path(task).resolve())
    if not root.is_dir() or not (in_source or in_task):
        raise ValueError("Expected one source ISO extraction or a tree in UN_TASK_WORK_ROOT")
    if not protect and not in_task:
        raise ValueError("Unprotected staging is allowed only inside UN_TASK_WORK_ROOT")
    containers = images = 0
    for archive in sorted(root.rglob("*")):
        if not archive.is_file() or archive.suffix.lower() != ".ccs":
            continue
        try:
            views = ccs.texture_views(ccs.decompressed(archive.read_bytes()))
        except (ValueError, IndexError, struct.error) as error:
            print(f"WARNING: {archive.relative_to(root)}: texture views unavailable: {error}", file=sys.stderr)
            continue
        if not views:
            continue
        output = Path(str(archive) + ".files")
        if output.exists():
            ccs.verify_views(archive, output)
        else:
            parent_stat, timestamp = archive.parent.stat(), archive.stat().st_mtime
            created = False
            try:
                output.mkdir()
                created = True
                for name, data in views.items():
                    path = output / name
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(data)
                    os.utime(path, (timestamp, timestamp))
                ccs.verify_views(archive, output)
                for path in sorted((p for p in output.rglob("*") if p.is_dir()),
                                   key=lambda p: len(p.parts), reverse=True):
                    os.utime(path, (timestamp, timestamp))
                os.utime(output, (timestamp, timestamp))
                if protect:
                    for path in [*output.rglob("*"), output]:
                        os.chmod(path, stat.S_IREAD)
            except BaseException:
                if not created:
                    raise
                if output.resolve() != Path(str(archive.resolve()) + ".files") or not output.is_relative_to(root):
                    raise RuntimeError(f"Unsafe cleanup path: {output}")
                for path in [*output.rglob("*"), output]:
                    os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
                shutil.rmtree(output)
                raise
            finally:
                os.utime(archive.parent, ns=(parent_stat.st_atime_ns, parent_stat.st_mtime_ns))
        containers += 1
        images += len(views)
        if containers % 500 == 0:
            print(f"CCS texture views: {containers} containers, {images} PNGs", flush=True)
    print(f"CCS texture views complete: {containers} containers, {images} PNGs")
    return containers, images


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--staging", action="store_true")
    args = parser.parse_args()
    expand(args.source_dir, protect=not args.staging)
