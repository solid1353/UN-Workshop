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
    configured = data.get("roots")
    if not isinstance(configured, dict) or not configured:
        raise ValueError("Workshop path manifest has no roots")
    roots: dict[str, Path] = {"repository": root}
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
        if not isinstance(raw, str) or not raw:
            raise ValueError(f"Invalid Workshop file {name!r}")
        if raw.startswith("@"):
            parts = raw[1:].replace("\\", "/").split("/", 1)
            if len(parts) != 2 or parts[0] not in roots:
                raise ValueError(f"Invalid Workshop file alias: {raw!r}")
            base = roots[parts[0]]
            child = Path(parts[1])
        else:
            base = root
            child = Path(raw)
        if child.is_absolute() or ".." in child.parts:
            raise ValueError(f"Invalid Workshop file path: {raw!r}")
        value = Path(os.path.abspath(base / child))
        if base not in value.parents:
            raise ValueError(f"Workshop file escapes its root: {raw!r}")
        files[name] = value

    return WorkshopPaths(
        manifest,
        MappingProxyType(roots),
        MappingProxyType(files),
    )


def load_project_paths(
    start: Path,
    workshop_paths: WorkshopPaths,
) -> WorkshopPaths:
    """Load a consuming project's roots over the shared Workshop roots."""
    root = start.resolve()
    manifest = root / "paths.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    configured = data.get("roots")
    if not isinstance(configured, dict) or not configured:
        raise ValueError("Project path manifest has no roots")
    roots = dict(workshop_paths.roots)
    roots["repository"] = root
    files = dict(workshop_paths.files)
    imports = data.get("imports", {})
    if not isinstance(imports, dict):
        raise ValueError("Project path imports must be an object")
    for name, raw in imports.items():
        if not isinstance(name, str) or not isinstance(raw, str) or not raw:
            raise ValueError("Invalid project path import")
        imported_manifest = Path(os.path.abspath(root / raw))
        if imported_manifest != workshop_paths.manifest:
            raise ValueError(f"Unsupported project path import: {raw!r}")
        roots[name] = workshop_paths.roots["repository"]

    resolving: set[str] = set()
    resolved: set[str] = set()

    def resolve_root(name: str) -> Path:
        if name in resolved:
            return roots[name]
        if name in resolving:
            raise ValueError(f"Project root cycle at {name!r}")
        if name not in configured:
            if name in roots:
                return roots[name]
            raise ValueError(f"Unknown project root {name!r}")
        raw = configured[name]
        if not isinstance(raw, str) or not raw:
            raise ValueError(f"Invalid project root {name!r}")
        resolving.add(name)
        if raw.startswith("@"):
            parts = raw[1:].replace("\\", "/").split("/", 1)
            parent = parts[0]
            child = Path(parts[1] if len(parts) == 2 else "")
            if child.is_absolute() or ".." in child.parts:
                raise ValueError(f"Invalid project root alias: {raw!r}")
            base = resolve_root(parent)
            value = Path(os.path.abspath(base / child))
            if value != base and base not in value.parents:
                raise ValueError(f"Project root escapes {parent!r}: {raw!r}")
        else:
            child = Path(raw)
            if child.is_absolute():
                raise ValueError(f"Project root must be relative: {raw!r}")
            value = Path(os.path.abspath(root / child))
        roots[name] = value
        resolving.remove(name)
        resolved.add(name)
        return value

    for name in configured:
        resolve_root(name)

    for name, raw in data.get("files", {}).items():
        if not isinstance(raw, str) or not raw:
            raise ValueError(f"Invalid project file {name!r}")
        if raw.startswith("@"):
            parts = raw[1:].replace("\\", "/").split("/", 1)
            if len(parts) != 2 or parts[0] not in roots:
                raise ValueError(f"Invalid project file alias: {raw!r}")
            base = roots[parts[0]]
            child = Path(parts[1])
        else:
            base = root
            child = Path(raw)
        if child.is_absolute() or ".." in child.parts:
            raise ValueError(f"Invalid project file path: {raw!r}")
        value = Path(os.path.abspath(base / child))
        if base not in value.parents:
            raise ValueError(f"Project file escapes its root: {raw!r}")
        files[name] = value

    return WorkshopPaths(
        manifest,
        MappingProxyType(roots),
        MappingProxyType(files),
    )
