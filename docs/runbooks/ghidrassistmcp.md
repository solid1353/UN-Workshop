# Read-only GhidrAssistMCP

Workshop owns the maintained GhidrAssistMCP installation and launch path. The
integration exposes existing Ghidra analysis to a local MCP client without
allowing that client to change a program, project, analysis configuration, or
host file.

## Pinned source

The maintained build uses GhidrAssistMCP `2.11.0` at commit
`0d412d1fe3203e98a32f7dc70df21dc8f6f57131`. Its published Ghidra 12.1 asset
has SHA-256
`BABA204A9FE839921A1487BE9DFB15526FAEA787E5E4312C8404281D82B3A1A7`.

The release asset is used only as a hash-verified dependency bundle and
extension skeleton. It is not installed directly: it contains generated
databases, a Lucene lock, and stale duplicate library versions that are absent
from the pinned source. The installer removes those files, compiles every Java
source file from the pinned commit against the installed Ghidra 12.1.2, and
applies
[`ghidrassistmcp-2.11.0-read-only.patch`](../../scripts/ghidra/ghidrassistmcp-2.11.0-read-only.patch).

The hardening patch forces `127.0.0.1` at the server connector, disables async
task execution, accepts both headless `key=value` and split `key value`
arguments, and makes this allow-list non-overridable:

- `get_binary_info`
- `list_binaries`
- `get_functions`
- `analyze_function`
- `get_function_signature`
- `get_segments`
- `get_imports`
- `get_exports`
- `get_strings`
- `get_data_vars`
- `get_namespaces`
- `get_relocations`
- `get_current_address`
- `get_current_function`
- `get_data_at`
- `xrefs`
- `get_code`
- `get_basic_blocks`
- `search_bytes`
- `classes`
- `search_functions_by_name`
- `get_function_statistics`
- `get_function_stack_layout`
- `search_strings`
- `get_entry_points`

Every other upstream tool remains disabled even if a caller names it directly
or a Ghidra setting tries to enable it. This excludes renaming, typing,
comments, bookmarks, patching, assembly, disassembly creation, auto-analysis,
scripts, file import, program export, task control, and program or project
lifecycle operations.

## Use

Use MCP before preserved exports for substantive disassembly or decompilation.
Confirm the required target with `list_binaries`. Use exports or raw bytes only
when MCP cannot expose the required evidence, and record why.

## Install

Run the installer with a disposable directory inside the active task's own
`@work/<chat title>/` root:

```powershell
& .\scripts\ghidra\install_ghidrassist_mcp.ps1 `
    -WorkRoot <resolved-task-work-directory>
```

The installer verifies Ghidra 12.1.2 PUBLIC, the upstream commit, the release
asset hash, the patch, the JDK, and the .NET SDK. It installs the hardened
extension and the existing pinned EmotionEngine processor extension below
`@tools/ghidra/Ghidra/Extensions`. It also publishes the windowless MCP router
below `@tools/ghidra/GhidrAssistMcpRouter`. Its disposable checkout, build, and
packaging files are removed after a successful install.

## Shared host

Install the per-user supervisor after installing the extension and router:

```powershell
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Install
```

The manager registers `UNWorkshop-GhidrAssistMCP` as a per-user Scheduled Task.
The task executes a Windows-subsystem application, and every descendant process
is launched without a console window. It starts at logon and restarts after a
supervisor failure.

The supervisor discovers every immediate `@disassembly/<target>/ghidra/*.gpr`
project. Program names come from the target's `manifest.tsv`, or from the
Ghidra project index when no manifest exists. This currently exposes `NA2`,
`NUN3`, `NUN5`, `NUN6`, and `shared`; future projects following the same layout
need no configuration change.

Each target runs in a separate hidden Ghidra backend on an OS-assigned temporary
loopback port. Each backend opens every program in its transient project, so
`program_name` selects the requested binary on each call instead of relying on
a persistent current-program selection. Ports are private runtime state and are
never part of Codex configuration. The supervisor copies each maintained analysis into
`@work/ghidraMCP/<target>/project`, opens the transient copy with
`-readOnly -noanalysis`, and removes it whenever the backend stops. Bounded
current and previous logs remain under `@work/ghidraMCP/<target>/logs`; global
supervisor state and logs remain directly below `@work/ghidraMCP`. The canonical
`@disassembly/<target>` archive is never opened directly or modified.

Manage the host through the same entrypoint:

```powershell
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Status
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Restart
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Stop
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Start
& .\scripts\ghidra\manage_ghidrassist_mcp.ps1 -Action Uninstall
```

Do not import a source binary or create another persistent Ghidra project for
this integration. Do not remove the launcher safeguards, retain its disposable
project copy, or point Ghidra at the maintained archive directly.

## Codex clients

The Workshop manager delegates global Codex registration to the tracked
`@codex-utils` installer. That installer owns only the `ghidrassist` entry in
the machine-local `%USERPROFILE%/.codex/config.toml` and preserves every other
setting. The entry launches the installed router through MCP stdio. Game
repositories contain no MCP configuration.

The stdio router connects to the hidden supervisor through a current-user-only
Windows named pipe. `list_binaries` can list every target or one named target.
Every other tool requires both `target` and `program_name`, so one Codex task
can switch projects on every call and concurrent tasks have no shared mutable
selection.

After installing the global registration for the first time, open a fresh Codex
task because an already-running task does not reload newly added MCP
configuration. Starting or restarting the supervisor does not require opening
another task. Full Access remains compatible; Custom permissions are not
required.
