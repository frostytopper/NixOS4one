# Handoff — Python development workbench improvements

Status: **Proposed** — implementation and open decisions deferred.

Scope: NixOS4one system and shared development tooling. Pipeline is a work-in-progress consumer of these capabilities, not an established codebase to repair.

## Goals and constraints

Improve the environment for building Pipeline and future Python/data projects while preserving the NixOS4one philosophy:

- No Home Manager or system flakes.
- Prefer native Nix/NixOS facilities where they reduce friction.
- Keep uv responsible for Python application dependencies.
- Let Nix supply interpreters, native dependencies, and reusable development utilities.
- Prefer simple local functionality over portability for its own sake.
- Introduce custom modules only when meaningful options and behavior justify them.
- Do not restructure or repair Pipeline’s application code as part of this work.

The existing shared shell was intentionally minimal: establish uv development using the local Nix-provided Python 3.14 interpreter. Extend that foundation rather than replacing it with a framework.

## 1. Parameterize the shared Python/uv shell

### Proposed implementation

Evolve `~/Projects/lib/py-uv-shell.nix` into a small shell constructor accepting:

| Input | Purpose |
|---|---|
| `pkgs` | Package set supplied by the caller |
| `python` | Interpreter; default to `pkgs.python314` |
| `nativePackages` | Project-specific native dependencies |
| `tools` | Additional development executables |

Explicitly set:

```nix
UV_PYTHON = "${python}/bin/python";
UV_PYTHON_DOWNLOADS = "never";
```

Keep Python application packages in the project’s `pyproject.toml` and `uv.lock`, not in the shared Nix shell.

### Decisions deferred

- Canonical source location: retain `~/Projects/lib`, or maintain the constructor in NixOS4one and expose it at a stable local path?
- Should the shared baseline include only Python and uv, or also common inspection tools?
- On project entry, should dependency synchronization remain explicit or happen automatically? Default recommendation: explicit.
- How should an interpreter change be handled? Default recommendation: diagnose it and provide an explicit environment-recreation procedure; never silently delete `.venv`.

### Completion criteria

A project can select its interpreter and native tools without editing the shared constructor. uv’s intended interpreter selection is explicit and verifiable.

## 2. Provide shared operations as Nix-packaged executables

### Proposed implementation

Use `pkgs.writeShellApplication` for operations that must work across fish, Bash, direnv, editors, and services.

First candidate: a credential-extraction command, provisionally:

```text
cred <service> <field>
```

The command should:

- Read the ciphertext location from the established configuration contract, such as `CREDENTIALS_FILE`.
- Decrypt only at runtime.
- Write the requested value to stdout.
- Send errors to stderr and return a nonzero status on failure.
- Avoid printing credential values in diagnostic messages.

Keep fish abbreviations for interactive editing and encryption. Do not make a fish-only function the shared interface.

### Correction to the earlier handoff

Direnv evaluates `.envrc` using Bash. A fish function cannot directly serve as the credential helper consumed by `.envrc`.

Nix should declare the helper and its dependencies—not decrypt secrets during evaluation or embed plaintext in store files.

### Decisions deferred

- Final command name and argument format.
- Whether it should support only the current service/field structure or arbitrary SOPS extraction expressions. Default recommendation: start narrow.
- Whether empty values count as extraction failure or are checked by each consumer.
- Whether to offer a separate credential-availability check that never outputs values.

### Completion criteria

The same helper works from fish and `.envrc`, with consistent error handling and no duplicated credential paths.

## 3. Add a development-environment diagnostic command

### Proposed implementation

Create a read-only command, provisionally `dev-doctor`, reporting:

- Current project directory.
- Selected Python executable and version.
- Actual `.venv` interpreter and version, when present.
- uv executable and version.
- Relevant interpreter-selection/download settings.
- Direnv activation indicators.
- Shared shell location or identifying metadata.
- Presence or absence of explicitly requested credential variables.

It should compare intended and actual interpreter selection rather than merely echoing environment variables.

### Safety boundary

The diagnostic must not:

- Print secrets.
- Delete or recreate virtual environments.
- Synchronize dependencies.
- Change Git configuration.
- Automatically “repair” discrepancies.

### Decisions deferred

- Human-readable output only, or optional machine-readable output?
- Explicit project checks via arguments, or a small project-local configuration?
- Which conditions return a nonzero exit status?
- How the shared shell exposes its identity for inspection.

### Completion criteria

A single command explains the common “which Python/environment am I actually using?” failures without modifying the project.

## 4. Integrate projects with the shared environment architecture

### Proposed implementation

Keep `.envrc` focused on environment activation and optional runtime credentials.

Explicitly watch shared Nix files imported from outside the project, placing `watch_file` before `use nix`.

Conceptual structure:

```bash
watch_file /path/to/shared/py-uv-shell.nix
use nix

# Optional credential extraction through the shared executable.
```

Credential assignments should check extraction failure and required-value presence before export.

### Revised Git setup boundary

Do not automatically add or rewrite remotes on directory entry.

Instead:

- An explicit bootstrap command performs approved repository setup.
- `.envrc` may perform read-only verification and warn.
- Existing local-origin/GitHub separation remains intact.

This revises the earlier proposal that `.envrc` should establish the remote automatically.

### Decisions deferred

- Explicit paths in each project versus a shared direnv helper.
- Whether credentials load on every entry or only through an explicit acquisition/session command.
- Whether repository verification belongs in `.envrc` or `dev-doctor`.
- Bootstrap behavior when a remote already exists with a conflicting target. Default recommendation: stop and explain; do not overwrite.

### Completion criteria

Editing the shared shell triggers the expected refresh. Entering a project does not silently mutate repository configuration or synchronize dependencies.

## 5. Add a generic managed-job facility

### Proposed implementation

Build a small launcher around transient systemd user services.

Provisional interface:

```text
job-run <name> -- <command> [arguments...]
job-log <name>
job-status <name>
job-stop <name>
```

The launcher should establish:

- Job identity.
- Working directory.
- Executable and arguments.
- A deliberate environment-transfer policy.
- Discoverable logs and exit status.

Keep tmux for interactive work; use managed jobs for unattended work.

### Requirements to distinguish

These are separate capabilities, not one implied guarantee:

1. Survive terminal closure.
2. Continue after logout.
3. Restart after reboot.

Start with terminal independence. Evaluate lingering separately for logout persistence. Reserve persistent service declarations for jobs that genuinely require reboot behavior.

### Decisions deferred

- Job naming and collision behavior.
- Environment allowlist and credential delivery.
- Whether jobs capture an already activated environment or establish one themselves.
- Log/status retention and cleanup.
- Optional CPU, memory, and I/O policies.
- Whether user lingering is appropriate.

### Completion criteria

A test job survives terminal closure, runs in the intended directory/environment, exposes logs and final status, and can be stopped by name.

## 6. Consider a separate development-toolchain pin

### Proposed implementation

Keep the shell constructor accepting `pkgs`. Initially continue using the existing package-set policy.

If independent toolchain updates become useful, introduce one shared development Nixpkgs pin using a non-flake mechanism, such as a revision and content hash consumed by `builtins.fetchTarball`.

This separates development-toolchain changes from system updates without converting Python dependencies to Nix.

### Decisions deferred

- Continue following system `pkgs`, or introduce a development pin?
- One shared pin or project-specific overrides? Default recommendation: shared first.
- Who updates it, how updates are tested, and how rollback works.
- Where the pin is maintained.

### Limitations

A Nixpkgs pin fixes that toolchain input. It does not freeze project source, datasets, uv dependency state, credentials, or mutable virtual environments.

### Completion criteria

The selected policy is explicit. If pinning is adopted, updating or rolling back the development package set does not require changing the operating system package set.

## 7. Make helper packages independently buildable

### Proposed implementation

Maintain development utilities as ordinary Nix packages that the system configuration consumes.

Illustrative layout:

```text
NixOS4one/
├── configuration.nix
├── lib/
│   └── py-uv-shell.nix
└── packages/
    ├── cred.nix
    ├── dev-doctor.nix
    └── job-run.nix
```

Provide a straightforward non-flake package entry point so each utility can be built and tested with `nix-build` before a full system rebuild.

Preferred development loop:

```text
Edit → build package → test executable → integrate → rebuild system
```

Custom NixOS options should be added only when shared configuration or conditional behavior earns them—not merely because package files exist.

### Decisions deferred

- Package entry-point structure.
- System-wide installation versus installation only for Brian.
- Whether job commands share one package or remain separate.
- Which settings genuinely warrant module options.

### Completion criteria

Each utility builds and runs independently of a full NixOS rebuild, and the system installs the same tested package definitions.

## Suggested implementation order

1. Inspect the existing shared shell and settle its canonical location.
2. Establish independently buildable helper packaging from step 7.
3. Parameterize the shell from step 1.
4. Implement the credential executable from step 2.
5. Update project activation and shared-file watching from step 4.
6. Add diagnostics from step 3.
7. Implement managed jobs from step 5.
8. Revisit toolchain pinning from step 6 only when its value is concrete.

This handoff records proposed work and deferred decisions only; no configuration, repository files, or application code have been changed.
