# Handoff — Complete Neovim language wiring

Status: **Proposed** — audit and implementation deferred until the existing system and development-workbench improvements are complete.

Scope: Complete Neovim support for Rust, C, C++, Go, and Lua in NixOS4one. Preserve the working Python baseline; do not redesign the editor.

## Goals and constraints

- Declare system/editor wiring through NixOS4one.
- No Home Manager or system flakes.
- Prefer a small, coherent toolset over overlapping providers.
- Keep project-specific dependencies and toolchain selection in development environments where appropriate.
- Validate functionality in representative projects, not merely package installation.
- Rust editor support does not change Pipeline’s current Python/Pydantic scope.

## 1. Audit the existing configuration

Before adding packages or changing configuration, inspect:

- Neovim package and plugin declarations.
- Enabled language servers and their settings.
- Completion capabilities passed to each server.
- Formatter and diagnostic integrations.
- Syntax parser and indentation configuration.
- Executable availability inside and outside project shells.
- Existing keybindings for navigation, diagnostics, formatting, and code actions.

Record each language as working, partially configured, or missing. Do not replace functioning components merely to standardize their names or configuration style.

## 2. Target language coverage

| Language | Required validation focus |
|---|---|
| Rust | Toolchain discovery, project attachment, diagnostics, formatting, navigation, and code actions |
| C | Compiler/build-context discovery, headers, diagnostics, formatting, and navigation |
| C++ | Compiler/build-context discovery, headers, diagnostics, formatting, and navigation |
| Go | Module/project discovery, diagnostics, formatting, navigation, and code actions |
| Lua | Runtime/library context, diagnostics, formatting, and navigation, including Neovim configuration where applicable |

Specific servers, formatters, packages, and settings remain implementation decisions pending the audit.

## 3. Establish consistent editor behavior

For each language, verify:

- Syntax highlighting and indentation.
- Language-server attachment at the correct project root.
- Completion, hover, and signature help.
- Go-to-definition and references.
- Rename and supported code actions.
- Useful diagnostics without duplicate reports.
- An explicit formatting command and a clear formatter owner.
- Consistent use of the existing editor keybindings.

Preserve the current Python experience throughout. Avoid competing servers or formatting integrations unless there is a documented reason for both.

## 4. Define system versus project ownership

### System/editor responsibilities

- Neovim plugins and integration configuration.
- Shared keybindings and editor behavior.
- General-purpose language tooling where a system-wide version is appropriate.
- Clear behavior when required project tooling is unavailable.

### Project-environment responsibilities

- Project-specific compiler or interpreter versions.
- Native dependencies and build tools.
- Project configuration consumed by language tooling.
- Any tooling that must match the project’s selected environment.

The implementation must verify what Neovim actually discovers, especially when launched from an existing tmux session or outside an activated project environment.

## 5. Decisions to resolve during implementation

### Tool selection and ownership

- Which language servers and formatters are already present?
- Which should be installed globally, and which should come from project shells?
- Does each language need a separate formatter, or can the selected integration handle formatting adequately?
- Which diagnostic source owns each category of feedback?

### Formatting policy

- Manual formatting only or format-on-save?
- One policy across languages or explicit per-language exceptions?
- What happens when the preferred formatter is unavailable?

Default recommendation: establish reliable manual formatting first; enable automatic behavior only after validation.

### Project discovery

- How will tooling locate project roots and selected toolchains?
- For C/C++, how will build configuration reach the editor?
- For Lua, how will Neovim configuration context be distinguished from ordinary Lua projects?
- What should happen when Neovim was started before entering the project environment?

### Optional scope

Decide separately whether to include:

- Debugging integration.
- Test-running integration.
- Build/run shortcuts.
- Additional completion features beyond the working baseline.

These are not prerequisites for completing the core language wiring.

## 6. Validation plan

Use a small representative project for each language.

For each project:

1. Enter its intended development environment.
2. Launch a fresh Neovim instance.
3. Confirm the intended server attaches at the correct root.
4. Exercise completion, hover, signatures, and navigation.
5. Introduce a deliberate error and confirm useful diagnostics.
6. Test rename and an available code action.
7. Run formatting and confirm only the intended provider acts.
8. Restart the editor and repeat the essential checks.

For C and C++, validate each separately rather than treating one successful attachment as proof that both work.

Finally, rerun the Python baseline checks to catch regressions.

## Completion criteria

- All five requested languages pass their representative-project checks.
- Tool and formatter ownership is documented.
- Project environments provide the expected toolchains without hidden manual setup.
- No unexplained duplicate diagnostics or formatting providers remain.
- Existing Python support and editor keybindings continue to work.
- Optional debugging, testing, and build integrations are either explicitly included or left out.

## Suggested implementation order

1. Audit the current configuration.
2. Resolve tool ownership and formatting policy.
3. Complete one language at a time, starting with the smallest verified gap.
4. Validate C and C++ against their build contexts.
5. Run cross-language and Python regression checks.
6. Document the final tool matrix and remaining optional work.

This is a draft handoff only. No repository files, Neovim configuration, or installed tooling have been changed.