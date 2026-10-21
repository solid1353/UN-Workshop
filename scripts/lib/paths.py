from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sys
from functools import lru_cache
from pathlib import Path
from types import MappingProxyType, ModuleType
from typing import Mapping

MANIFEST_NAME = "paths.json"
LAUNCH_SETTING_NAMES = ("startup_fast_forward_frames", "speed_after_startup")
# The startup-frame entry for every game a profile's map does not name.
LAUNCH_FRAMES_FALLBACK = "*"
WORKSHOP_ROOT = Path(__file__).resolve().parents[2]


class Paths:
    def __init__(
        self,
        manifest: Path,
        roots: Mapping[str, Path],
        files: Mapping[str, Path],
        settings: Mapping[str, object] | None = None,
        games: Mapping[str, Mapping[str, object]] | None = None,
    ) -> None:
        self.manifest = manifest
        self.roots = roots
        self.files = files
        self.settings = settings
        self.games = games if games is not None else MappingProxyType({})

    @property
    def repository(self) -> Path:
        return self.roots["repository"]

    def path(self, root: str, *children: str | Path) -> Path:
        try:
            result = self.roots[root]
        except KeyError as exc:
            raise KeyError(f"Unknown project root: {root}") from exc
        for child in children:
            result /= child
        return result

    def file(self, name: str) -> Path:
        try:
            return self.files[name]
        except KeyError as exc:
            raise KeyError(f"Unknown project file: {name}") from exc


@lru_cache(maxsize=None)
def _game_catalog() -> ModuleType:
    # Loaded on first use: game_catalog loads this module itself.
    path = Path(__file__).resolve().with_name("game_catalog.py")
    spec = importlib.util.spec_from_file_location("un_workshop_game_catalog", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Could not load Workshop game catalog: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _find_manifest(start: Path) -> Path:
    current = start.resolve()
    if current.is_file():
        current = current.parent
    for candidate_root in (current, *current.parents):
        candidate = candidate_root / MANIFEST_NAME
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(f"Could not find {MANIFEST_NAME} above {start}")


def load_workshop_paths(start: Path | None = None) -> Paths:
    """Load a Workshop manifest: roots and files, with no imports or checks."""
    root = (start or WORKSHOP_ROOT).resolve()
    manifest = root / MANIFEST_NAME
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

    return Paths(manifest, MappingProxyType(roots), MappingProxyType(files))


def _is_selector(value: object) -> bool:
    return (
        isinstance(value, str)
        and bool(value)
        and value[0].isalnum()
        and value.replace("_", "").isalnum()
    )


def _validate_launch_settings(settings: Mapping[str, object]) -> None:
    launch_settings = settings.get("launch_settings")
    if not isinstance(launch_settings, dict):
        raise ValueError("Project launch_settings must be an object")
    default = launch_settings.get("default")
    if not isinstance(default, dict):
        raise ValueError("Project launch_settings.default must be an object")
    for name, definition in launch_settings.items():
        label = f"Project launch_settings.{name}"
        if not isinstance(definition, dict):
            raise ValueError(f"{label} must be an object")
        if set(definition) - set(LAUNCH_SETTING_NAMES):
            raise ValueError(
                f"{label} may define only startup_fast_forward_frames and "
                "speed_after_startup"
            )
        frames = definition.get(
            "startup_fast_forward_frames", {LAUNCH_FRAMES_FALLBACK: 0}
        )
        if not isinstance(frames, dict) or LAUNCH_FRAMES_FALLBACK not in frames:
            raise ValueError(
                f"{label}.startup_fast_forward_frames must map games to frames, "
                f"with {LAUNCH_FRAMES_FALLBACK!r} for the rest"
            )
        for game, count in frames.items():
            if isinstance(count, bool) or not isinstance(count, int) or count < 0:
                raise ValueError(
                    f"{label}.startup_fast_forward_frames.{game} must be a "
                    "non-negative integer"
                )
        if definition.get("speed_after_startup", "normal") not in {"normal", "turbo"}:
            raise ValueError(f"{label}.speed_after_startup must be normal or turbo")
    for name in LAUNCH_SETTING_NAMES:
        if name not in default:
            raise ValueError(f"Project launch_settings.default must define {name}")


def load_project_paths(
    start: Path | None = None,
    *,
    include_imports: bool = True,
    include_games: bool = True,
) -> Paths:
    """Load a consuming project's manifest over the Workshop it imports.

    Without imports, only the project's own roots and files are loaded. Without
    games, its settings and game catalog are not loaded.
    """
    manifest_path = _find_manifest(start or Path.cwd())
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    configured = data.get("roots")
    if not isinstance(configured, dict) or not configured:
        raise ValueError("Project path manifest has no roots")

    repository = manifest_path.parent.resolve()
    roots: dict[str, Path] = {"repository": repository}
    files: dict[str, Path] = {}
    local_files = data.get("files")
    if not isinstance(local_files, dict) or not local_files:
        raise ValueError("Project path manifest has no files")

    imports = data.get("imports", {})
    if not isinstance(imports, dict):
        raise ValueError("Project path manifest imports must be an object")
    imported_roots: dict[str, Mapping[str, Path]] = {}
    for import_name, raw_manifest in imports.items() if include_imports else ():
        if (
            not isinstance(import_name, str)
            or not import_name
            or not isinstance(raw_manifest, str)
            or not raw_manifest
        ):
            raise ValueError("Invalid project path import")
        import_path = Path(raw_manifest)
        if import_path.is_absolute():
            raise ValueError(
                f"Project path import {import_name!r} must be relative"
            )
        imported_manifest = Path(os.path.abspath(repository / import_path))
        if not imported_manifest.is_file():
            raise FileNotFoundError(
                f"Project path import {import_name!r}: {imported_manifest}"
            )
        imported = load_workshop_paths(imported_manifest.parent)
        imported_roots[import_name] = imported.roots
        if import_name in roots:
            raise ValueError(f"Duplicate imported root: {import_name!r}")
        roots[import_name] = imported.roots["repository"]
        for name, value in imported.roots.items():
            if name == "repository" or name in configured:
                continue
            if name in roots:
                raise ValueError(f"Duplicate imported root: {name!r}")
            roots[name] = value
        for name, value in imported.files.items():
            if name in local_files:
                continue
            if name in files:
                raise ValueError(f"Duplicate imported file: {name!r}")
            files[name] = value

    resolving: set[str] = set()

    def resolve_root(name: str) -> Path:
        if name in roots:
            return roots[name]
        if name in resolving:
            raise ValueError(
                f"Project root aliases contain a dependency cycle at {name!r}"
            )
        raw_value = configured[name]
        if not isinstance(raw_value, str) or not raw_value:
            raise ValueError(
                f"Project root {name!r} must be a non-empty repository-relative "
                "path or @root path"
            )

        resolving.add(name)
        if raw_value.startswith("@"):
            root_and_child = raw_value[1:].replace("\\", "/").split("/", 1)
            parent_name = root_and_child[0]
            child = root_and_child[1] if len(root_and_child) == 2 else ""
            child_path = Path(child)
            if (
                not parent_name
                or (parent_name not in configured and parent_name not in roots)
                or child_path.is_absolute()
                or ".." in child_path.parts
            ):
                raise ValueError(
                    f"Project root {name!r} has an invalid root alias: {raw_value!r}"
                )
            base_path = resolve_root(parent_name)
            configured_path = Path(os.path.abspath(base_path / child_path))
        else:
            value = Path(raw_value)
            if value.is_absolute():
                raise ValueError(
                    f"Project root {name!r} must be a non-empty repository-relative "
                    "path or @root path"
                )
            configured_path = Path(os.path.abspath(repository / value))
        roots[name] = configured_path
        resolving.remove(name)
        return configured_path

    for name in configured:
        resolve_root(name)

    for name, raw_value in local_files.items():
        if not isinstance(raw_value, str) or not raw_value:
            raise ValueError(
                f"Project file {name!r} must be a non-empty "
                "repository-relative path or @root path"
            )

        if raw_value.startswith("@"):
            root_and_child = raw_value[1:].replace("\\", "/").split("/", 1)
            if len(root_and_child) != 2 or not all(root_and_child):
                raise ValueError(
                    f"Project file {name!r} has an invalid root alias: {raw_value!r}"
                )
            root, child = root_and_child
            try:
                base_path = roots[root]
            except KeyError as exc:
                raise ValueError(
                    f"Project file {name!r} references unknown project root "
                    f"{root!r}"
                ) from exc
            value = Path(child)
            if value.is_absolute() or ".." in value.parts:
                raise ValueError(
                    f"Project file {name!r} must remain within configured root "
                    f"{root!r}"
                )
        else:
            base_path = repository
            value = Path(raw_value)
            if value.is_absolute():
                raise ValueError(
                    f"Project file {name!r} must be a non-empty "
                    "repository-relative path or @root path"
                )

        configured_path = Path(os.path.abspath(base_path / value))
        if base_path not in configured_path.parents:
            scope = (
                "its configured root" if raw_value.startswith("@") else "the repository"
            )
            raise ValueError(f"Project file {name!r} must remain within {scope}")
        files[name] = configured_path

    settings: dict[str, object] | None = None
    games: dict[str, Mapping[str, object]] = {}
    settings_path = (
        files.get("project_settings") if include_imports and include_games else None
    )
    if settings_path is not None:
        if not settings_path.is_file():
            raise FileNotFoundError(f"Project settings not found: {settings_path}")
        settings = json.loads(settings_path.read_text(encoding="utf-8"))
        if not isinstance(settings, dict):
            raise ValueError("Project settings must be an object")
        _validate_launch_settings(settings)
        source_catalog_path = files.get("source_catalog")
        workshop_roots = imported_roots.get("workshop")
        if source_catalog_path is None or workshop_roots is None:
            raise ValueError("Project game catalogs require the Workshop import")
        if not source_catalog_path.is_file():
            raise FileNotFoundError(
                f"Source game catalog not found: {source_catalog_path}"
            )
        catalog = {
            "sources": json.loads(
                source_catalog_path.read_text(encoding="utf-8")
            ).get("sources"),
        }
        game_catalog = _game_catalog()
        content_roots = list(
            dict.fromkeys((roots["pcsx2_files"], workshop_roots["pcsx2_files"]))
        )

        def resolve_catalog_value(label: str, raw_value: object) -> object:
            if not isinstance(raw_value, str) or not raw_value:
                raise ValueError(f"{label} has an invalid value: {raw_value!r}")
            if not raw_value.startswith("@"):
                return raw_value
            root_and_child = raw_value[1:].replace("\\", "/").split("/", 1)
            if len(root_and_child) != 2 or not all(root_and_child):
                raise ValueError(f"{label} has an invalid path: {raw_value!r}")
            root_name, child = root_and_child
            try:
                base_path = roots[root_name]
            except KeyError as exc:
                raise ValueError(
                    f"{label} references unknown project root {root_name!r}"
                ) from exc
            child_path = Path(child)
            if child_path.is_absolute() or ".." in child_path.parts:
                raise ValueError(f"{label} must remain within {root_name!r}")
            return Path(os.path.abspath(base_path / child_path))

        definitions = catalog["sources"]
        if not isinstance(definitions, dict) or not definitions:
            raise ValueError("Game catalog has no non-empty 'sources' section")
        selectors: set[str] = set()
        for game_name, definition in definitions.items():
            if not _is_selector(game_name):
                raise ValueError(f"Invalid canonical game selector: {game_name!r}")
            if game_name.casefold() in selectors:
                raise ValueError(f"Duplicate game selector or alias: {game_name!r}")
            selectors.add(game_name.casefold())
            if not isinstance(definition, dict):
                raise ValueError(f"Game {game_name!r} definition must be an object")

            aliases = definition.get("aliases", [])
            if not isinstance(aliases, list):
                raise ValueError(f"Game {game_name!r} aliases must be a list")
            for alias in aliases:
                if not _is_selector(alias):
                    raise ValueError(
                        f"Invalid alias for game {game_name!r}: {alias!r}"
                    )
                if alias.casefold() in selectors:
                    raise ValueError(f"Duplicate game selector or alias: {alias!r}")
                selectors.add(alias.casefold())

            config: dict[str, object] = {}
            for config_name, raw_value in definition.items():
                if config_name == "aliases":
                    continue
                if not (
                    isinstance(config_name, str)
                    and config_name[:1].islower()
                    and config_name.replace("_", "").isalnum()
                ):
                    raise ValueError(
                        f"Invalid game {game_name!r} configuration name: "
                        f"{config_name!r}"
                    )
                config[config_name] = resolve_catalog_value(
                    f"Game {game_name!r} configuration {config_name!r}",
                    raw_value,
                )

            content = [
                root for root in content_roots if (root / "games" / game_name).is_dir()
            ]
            if len(content) != 1:
                raise ValueError(
                    f"Registered game {game_name!r} must exist in exactly one "
                    f"configured pcsx2_files root; found {len(content)}"
                )
            derived = game_catalog.derive_game_paths(
                game_name, catalog, {**roots, "pcsx2_files": content[0]}
            )
            for name in (
                "input_profile",
                "input_profile_overrides",
                "cheats",
                "game_settings",
            ):
                if name in derived:
                    config[name] = derived[name]
            files.setdefault("input_profile", derived["input_profile"])

            extracted_path = derived["extracted"]
            game_key = game_name.casefold()
            for kind, mapping, name, value in (
                ("root", roots, f"source_{game_key}", extracted_path),
                ("file", files, f"{game_key}_iso", derived["iso"]),
            ):
                if name in mapping:
                    raise ValueError(
                        f"Project {kind} {name!r} duplicates game catalogs"
                    )
                mapping[name] = value
            for alias in aliases:
                roots.setdefault(f"source_{alias.casefold()}", extracted_path)
                files.setdefault(f"{alias.casefold()}_iso", derived["iso"])
            games[game_name] = MappingProxyType(
                {"aliases": tuple(aliases), "config": MappingProxyType(config)}
            )

    return Paths(
        manifest_path,
        MappingProxyType(roots),
        MappingProxyType(files),
        settings,
        MappingProxyType(games),
    )


def resolve_alias(value: str, paths: Paths) -> Path:
    """Resolve @root/child syntax used by declarative profile root tables."""
    if not value.startswith("@"):
        raise ValueError(f"Project path alias must start with '@': {value!r}")
    root_and_child = value[1:].replace("\\", "/").split("/", 1)
    root = root_and_child[0]
    child = root_and_child[1] if len(root_and_child) == 2 else ""
    child_path = Path(child)
    if not root or child_path.is_absolute() or ".." in child_path.parts:
        raise ValueError(f"Invalid project path alias: {value!r}")
    return paths.path(root, child)


def _json_value(value: object) -> object:
    if isinstance(value, Path):
        return str(value)
    if isinstance(value, Mapping):
        return dict(value)
    raise TypeError(f"Cannot serialize {type(value).__name__}")


def main() -> int:
    """Print resolved paths as JSON for the PowerShell loader."""
    parser = argparse.ArgumentParser(description=main.__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--workshop", action="store_true")

    parser.add_argument("--local", action="store_true")
    parser.add_argument("--no-games", action="store_true")
    args = parser.parse_args()
    try:
        if args.workshop:
            paths = load_workshop_paths(args.manifest.resolve().parent)
        else:
            paths = load_project_paths(
                args.manifest,
                include_imports=not args.local,
                include_games=not args.no_games,
            )
    except (ImportError, KeyError, OSError, ValueError) as exc:
        print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
        return 1
    print(
        json.dumps(
            {
                "manifest": paths.manifest,
                "roots": paths.roots,
                "files": paths.files,
                "settings": paths.settings,
                "games": paths.games,
            },
            default=_json_value,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
