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
DEFAULT_INPUT_PROFILE = "Default"


def _read_definition(path: Path, label: str) -> dict[str, object]:
    if not path.is_file():
        raise FileNotFoundError(f"{label} not found: {path}")
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    return value


def load_catalog(
    workshop_root: Path,
    project_root: Path | None = None,
) -> dict[str, object]:
    workshop_root = workshop_root.resolve()
    workshop_paths = _PATHS.load_workshop_paths(workshop_root)
    shared = _read_definition(
        workshop_paths.files["source_catalog"], "Workshop game catalog"
    )
    sources = shared.get("sources")
    if not isinstance(sources, dict) or not sources:
        raise ValueError("Workshop game catalog has no source games")

    project_paths = (
        _PATHS.load_project_paths(project_root.resolve(), workshop_paths)
        if project_root is not None
        else workshop_paths
    )
    content_roots: list[Path] = []
    for candidate in (
        project_paths.roots["pcsx2_files"],
        workshop_paths.roots["pcsx2_files"],
    ):
        candidate = candidate.resolve()
        if candidate not in content_roots:
            content_roots.append(candidate)
    available_sources: dict[str, object] = {}
    for name, definition in sources.items():
        matches = [
            root for root in content_roots if (root / "games" / name).is_dir()
        ]
        if len(matches) > 1:
            raise ValueError(
                f"Registered game {name!r} exists in multiple pcsx2_files roots"
            )
        if matches:
            available_sources[name] = definition
    if not available_sources:
        raise ValueError("No registered source games are available")

    return {"sources": available_sources}


def _required_text(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be a non-empty string")
    return value


def _root(roots: Mapping[str, Path], name: str) -> Path:
    try:
        return roots[name]
    except KeyError as exc:
        raise ValueError(f"Game path derivation requires root {name!r}") from exc


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


def derive_game_paths(
    selector: str,
    catalog: Mapping[str, object],
    roots: Mapping[str, Path],
) -> dict[str, Path]:
    canonical_name, definition, _ = find_definition(selector, catalog)
    profile_root = _root(roots, "pcsx2_input_profiles")
    override = (
        profile_root
        / "sources"
        / "overrides"
        / "games"
        / f"{canonical_name}.ini"
    )
    override_enabled = override.is_file()
    resolved_profile = (
        f"{DEFAULT_INPUT_PROFILE}_{canonical_name}"
        if override_enabled
        else f"{DEFAULT_INPUT_PROFILE}_Base"
    )
    input_profile_path = profile_root / f"{resolved_profile}.ini"

    serial = _required_text(
        definition.get("serial"), f"Game {canonical_name!r} serial"
    )
    crc = _required_text(
        definition.get("crc"), f"Game {canonical_name!r} crc"
    ).upper()
    source = _root(roots, "source")
    bundle = _root(roots, "pcsx2_files") / "games" / canonical_name
    result = {
        "iso": source / f"{canonical_name}.iso",
        "extracted": source / f"{canonical_name}.iso.files",
        "cheats": bundle / f"{canonical_name}.pnach",
        "memory_card": bundle / f"{canonical_name}.ps2",
        "game_settings": bundle / f"{canonical_name}.ini",
        "input_profile": input_profile_path,
    }
    if override_enabled:
        result["input_profile_overrides"] = override
    return result


def resolve_game(
    selector: str,
    workshop_root: Path,
    project_root: Path | None = None,
) -> dict[str, str]:
    workshop_root = workshop_root.resolve()
    project_root = project_root.resolve() if project_root is not None else None
    catalog = load_catalog(workshop_root, project_root)
    workshop_paths = _PATHS.load_workshop_paths(workshop_root)
    project_paths = (
        _PATHS.load_project_paths(project_root, workshop_paths)
        if project_root is not None
        else workshop_paths
    )
    canonical_name, _, _ = find_definition(selector, catalog)
    bundle_name = canonical_name
    candidates = [
        project_paths.roots["pcsx2_files"],
        workshop_paths.roots["pcsx2_files"],
    ]
    unique_candidates: list[Path] = []
    for candidate in candidates:
        candidate = candidate.resolve()
        if candidate not in unique_candidates:
            unique_candidates.append(candidate)
    matches = [
        candidate
        for candidate in unique_candidates
        if (candidate / "games" / bundle_name).is_dir()
    ]
    if len(matches) != 1:
        raise ValueError(
            f"Registered game {bundle_name!r} must exist in exactly one "
            f"configured pcsx2_files root; found {len(matches)}"
        )
    content_root = matches[0]
    roots = {
        name: project_paths.roots[name]
        for name in (
            "repository",
            "source",
            "pcsx2_files",
            "pcsx2_input_profiles",
        )
    }
    roots["pcsx2_files"] = content_root
    return {
        name: os.path.abspath(path)
        for name, path in derive_game_paths(selector, catalog, roots).items()
    }


def resolve_game_property_names(
    workshop_root: Path,
    project_root: Path | None = None,
) -> list[str]:
    workshop_root = workshop_root.resolve()
    project_root = project_root.resolve() if project_root is not None else None
    catalog = load_catalog(workshop_root, project_root)
    workshop_paths = _PATHS.load_workshop_paths(workshop_root)
    project_paths = (
        _PATHS.load_project_paths(project_root, workshop_paths)
        if project_root is not None
        else workshop_paths
    )
    roots = {
        name: project_paths.roots[name]
        for name in (
            "repository",
            "source",
            "pcsx2_files",
            "pcsx2_input_profiles",
        )
    }
    names: dict[str, None] = {}
    for selector in catalog["sources"]:
        for name in derive_game_paths(selector, catalog, roots):
            names[name] = None
    return list(names)
