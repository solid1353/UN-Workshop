from __future__ import annotations

import json
import os
from pathlib import Path
from types import MappingProxyType
from typing import Mapping


class WorkshopPaths:
    def __init__(
        self,
        manifest: Path,
        roots: Mapping[str, Path],
        files: Mapping[str, Path],
    ) -> None:
        self.manifest = manifest
        self.roots = roots
        self.files = files


def load_workshop_paths(start: Path | None = None) -> WorkshopPaths:
    root = (start or Path(__file__).resolve().parents[2]).resolve()
    manifest = root / "paths.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError("Unsupported Workshop path schema")

    configured = data.get("roots")
    if not isinstance(configured, dict) or not configured:
        raise ValueError("Workshop path manifest has no roots")
    roots: dict[str, Path] = {}
    resolving: set[str] = set()

    def resolve_root(name: str) -> Path:
        if name in roots:
            return roots[name]
        if name in resolving:
            raise ValueError(f"Workshop root cycle at {name!r}")
        raw = configured.get(name)
        if not isinstance(raw, str) or not raw:
            raise ValueError(f"Invalid Workshop root {name!r}")
        resolving.add(name)
        if raw.startswith("@"):
            parts = raw[1:].replace("\\", "/").split("/", 1)
            parent = parts[0]
            child = Path(parts[1] if len(parts) == 2 else "")
            if parent not in configured or child.is_absolute() or ".." in child.parts:
                raise ValueError(f"Invalid Workshop root alias: {raw!r}")
            base = resolve_root(parent)
            value = Path(os.path.abspath(base / child))
            if value != base and base not in value.parents:
                raise ValueError(f"Workshop root escapes {parent!r}: {raw!r}")
        else:
            child = Path(raw)
            if child.is_absolute():
                raise ValueError(f"Workshop root must be relative: {raw!r}")
            value = Path(os.path.abspath(root / child))
        roots[name] = value
        resolving.remove(name)
        return value

    for name in configured:
        resolve_root(name)

    files: dict[str, Path] = {}
    for name, raw in data.get("files", {}).items():
        if not isinstance(raw, str) or not raw.startswith("@"):
            raise ValueError(f"Invalid Workshop file {name!r}")
        parts = raw[1:].replace("\\", "/").split("/", 1)
        if len(parts) != 2 or parts[0] not in roots:
            raise ValueError(f"Invalid Workshop file alias: {raw!r}")
        child = Path(parts[1])
        if child.is_absolute() or ".." in child.parts:
            raise ValueError(f"Invalid Workshop file path: {raw!r}")
        value = Path(os.path.abspath(roots[parts[0]] / child))
        if roots[parts[0]] not in value.parents:
            raise ValueError(f"Workshop file escapes its root: {raw!r}")
        files[name] = value

    return WorkshopPaths(
        manifest,
        MappingProxyType(roots),
        MappingProxyType(files),
    )
