from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
from typing import Mapping


def _load_paths_module():
    path = Path(__file__).resolve().with_name("paths.py")
    spec = importlib.util.spec_from_file_location("un_workshop_paths", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load Workshop path module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PATHS = _load_paths_module()


def _read_definition(path: Path, label: str) -> dict[str, object]:
    if not path.is_file():
        raise FileNotFoundError(f"{label} not found: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def load_catalog(workshop_root: Path) -> dict[str, object]:
    workshop_root = workshop_root.resolve()
    workshop_paths = _PATHS.load_workshop_paths(workshop_root)
    shared = _read_definition(
        workshop_paths.files["source_catalog"], "Workshop game catalog"
    )
    sources = shared.get("sources")
    if not isinstance(sources, dict) or not sources:
        raise ValueError("Workshop game catalog has no source games")
    return {"sources": sources}


def _content_roots(
    workshop_root: Path, project_root: Path | None
) -> tuple[Path, list[Path]]:
    workshop_paths = _PATHS.load_workshop_paths(workshop_root)
    project_paths = (
        _PATHS.load_project_paths(project_root, include_games=False)
        if project_root is not None
        else workshop_paths
    )
    content_roots = list(
        dict.fromkeys(
            root.resolve()
            for root in (
                project_paths.roots["pcsx2_files"],
                workshop_paths.roots["pcsx2_files"],
            )
        )
    )
    return project_paths.roots["source"], content_roots


def _required_text(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be a non-empty string")
    return value


def find_definition(
    selector: str, catalog: Mapping[str, object]
) -> tuple[str, Mapping[str, object], Mapping[str, object]]:
    requested = selector.casefold()
    match: tuple[str, Mapping[str, object], Mapping[str, object]] | None = None
    definitions = catalog.get("sources")
    if not isinstance(definitions, dict) or not definitions:
        raise ValueError("Game catalog has no source games")

    for canonical_name, raw_definition in definitions.items():
        if not isinstance(canonical_name, str) or not canonical_name:
            raise ValueError(f"Invalid canonical game selector: {canonical_name!r}")
        if not isinstance(raw_definition, dict):
            raise ValueError(
                f"Game {canonical_name!r} definition must be an object"
            )
        aliases = raw_definition.get("aliases", [])
        if not isinstance(aliases, list) or any(
            not isinstance(alias, str) or not alias for alias in aliases
        ):
            raise ValueError(f"Game {canonical_name!r} aliases must be strings")
        if any(
            name.casefold() == requested for name in (canonical_name, *aliases)
        ):
            if match is not None:
                raise ValueError(f"Duplicate game selector or alias: {selector!r}")
            match = (canonical_name, raw_definition, definitions)

    if match is None:
        raise KeyError(f"Unknown game selector: {selector}")
    return match


def _content_file(name: str, content_roots: list[Path]) -> Path:
    """Find a game's file in ``games/`` of the content roots.

    A missing file resolves to the last root, the Workshop's, which owns the
    source catalog.
    """
    matches = [
        root / "games" / name
        for root in content_roots
        if (root / "games" / name).is_file()
    ]
    if len(matches) > 1:
        raise ValueError(f"{name} exists in multiple pcsx2_files roots")
    return matches[0] if matches else content_roots[-1] / "games" / name


def derive_game_paths(
    selector: str,
    catalog: Mapping[str, object],
    source_root: Path,
    content_roots: list[Path],
) -> dict[str, Path]:
    canonical_name, definition, _ = find_definition(selector, catalog)
    _required_text(definition.get("serial"), f"Game {canonical_name!r} serial")
    _required_text(definition.get("crc"), f"Game {canonical_name!r} crc")
    return {
        "iso": source_root / f"{canonical_name}.iso",
        "extracted": source_root / f"{canonical_name}.iso.files",
        "cheats": _content_file(f"{canonical_name}.pnach", content_roots),
        "game_settings": _content_file(f"{canonical_name}.ini", content_roots),
    }


def resolve_game(
    selector: str,
    workshop_root: Path,
    project_root: Path | None = None,
) -> dict[str, str]:
    workshop_root = workshop_root.resolve()
    project_root = project_root.resolve() if project_root is not None else None
    catalog = load_catalog(workshop_root)
    source_root, content_roots = _content_roots(workshop_root, project_root)
    return {
        name: os.path.abspath(path)
        for name, path in derive_game_paths(
            selector, catalog, source_root, content_roots
        ).items()
    }


def resolve_game_property_names(
    workshop_root: Path,
    project_root: Path | None = None,
) -> list[str]:
    workshop_root = workshop_root.resolve()
    project_root = project_root.resolve() if project_root is not None else None
    catalog = load_catalog(workshop_root)
    source_root, content_roots = _content_roots(workshop_root, project_root)
    names: dict[str, None] = {}
    for selector in catalog["sources"]:
        for name in derive_game_paths(selector, catalog, source_root, content_roots):
            names[name] = None
    return list(names)
