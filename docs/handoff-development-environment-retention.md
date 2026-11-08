# Handoff — Development-environment retention and optional binary cache

Status: **Deferred** — revisit after the existing NixOS4one system and development-workbench improvements.

Scope: Manage the lifecycle of Nix development environments, reclaim local storage deliberately, and evaluate off-machine toolchain retention. No immediate implementation required.

## Goal

Keep active development environments reliable without retaining every abandoned environment indefinitely.

If a separate Nix host becomes available, consider using it to retain selected toolchains and serve them back to the working machine. Do not deploy `nix-serve` on lati merely as a storage-cleanup measure.

## 1. Establish a local environment-retention policy

### Recommendation

Distinguish four storage categories:

| Category | Lifecycle responsibility |
|---|---|
| System generations | NixOS generation-retention and garbage-collection policy |
| Development-shell roots | Project environment lifecycle |
| uv cache and virtual environments | Separate Python-development cleanup policy |
| Source, datasets, outputs, and credentials | Git, data-retention, and backup policies |

Start by inspecting what currently retains store paths before introducing additional cleanup automation.

For development environments, define three states:

- Active: retain the environment locally.
- Dormant: keep project definitions and dependency records; decide whether the local environment remains worth retaining.
- Retired: deliberately release environment roots and remove disposable local state as appropriate.

Do not infer retirement merely from a directory’s age.

### Decisions deferred

- What qualifies an environment as dormant or retired?
- Which known-good environments deserve longer retention?
- Should retirement remain a documented procedure or eventually become an explicit command?
- What confirmation and inspection output should precede cleanup?

### Completion criteria

We can identify which project environments retain store paths and retire one intentionally without deleting project source or valuable data.

## 2. Document a safe project-retirement procedure

### Recommendation

Create a short, explicit procedure covering:

1. Confirm the project’s source and dependency records are preserved.
2. Identify the project’s development-environment roots.
3. Confirm no running job still depends on the environment being retired.
4. Release the relevant roots using the mechanism appropriate to the installed nix-direnv version.
5. Handle `.venv` and uv cache cleanup separately.
6. Run or await garbage collection.
7. Verify that the project can be re-entered and its environment recreated when needed.

Avoid blanket deletion of `.direnv` directories or uv caches across all projects.

A root being released means store paths become eligible for collection only if nothing else retains them. Retirement should not promise a particular amount of recovered space.

### Decisions deferred

- Whether to offer a read-only retirement preview.
- Whether selected environments need a recovery test before their local roots are removed.
- Whether cleanup belongs in `dev-doctor`, a separate maintenance command, or documentation only.

### Completion criteria

The procedure clearly separates disposable environments from irreplaceable project material and has been tested on a disposable project.

## 3. Evaluate off-machine retention only when justified

### Recommendation

Consider a separate retention host when at least one concrete need exists:

- Multiple Nix machines reuse the same development toolchains.
- Custom native packages are expensive to rebuild.
- Locally collected toolchains need to remain readily recoverable.
- An always-on host has sufficient storage and a clear operational owner.

Proposed architecture:

```text
Working machine: lati
  Active project environments
  Routine local garbage collection
          │
          │ Retrieve matching Nix store paths
          ▼
Separate Nix retention host
  Selected closures copied to its store
  Explicit roots retain those closures
  Optional nix-serve exposes them as a binary cache
```

The three responsibilities must remain distinct:

- Copying transfers store contents.
- Roots preserve selected contents on the retention host.
- `nix-serve` makes retained contents available to clients.

Merely serving a store does not archive it or protect it from that host’s garbage collection.

### Decisions deferred

- Is a separate host actually available and worthwhile?
- Which closures should be transferred and retained?
- How are transfers initiated and verified?
- What retention period, storage budget, and pruning policy should the host use?
- Is a continuously available HTTP cache necessary, or would occasional direct store transfers suffice?

### Completion criteria

A selected development toolchain can be transferred, retained independently of lati, and retrieved after its local copy has been collected.

## 4. Add `nix-serve` only as the delivery layer

### Recommendation

If the separate-host use case is established, evaluate a minimal NixOS-declared `nix-serve` deployment.

Before enabling clients, settle:

- Network exposure: preferably restricted to the intended private network.
- Cache signing and client trust.
- Signing-key storage and permissions.
- Client substituter configuration.
- Service availability expectations.
- Server-side root and garbage-collection policy.

Do not weaken client signature requirements merely to simplify setup.

Start with explicit publication of selected known-good toolchains rather than automatically retaining every build.

### Decisions deferred

- Whether `nix-serve` is sufficient or another cache implementation offers a necessary feature.
- Whether the host is private-network-only.
- How signing keys are provisioned, backed up, and rotated.
- Whether publication stays manual or becomes a deliberate command.
- Whether cache configuration merits a reusable NixOS4one module.

### Completion criteria

Clients can retrieve an approved toolchain through the cache with the intended trust configuration, and server cleanup does not unexpectedly remove retained environments.

## 5. Keep the preservation boundary explicit

The proposed cache covers Nix store contents such as:

- Nix-provided Python interpreters.
- Native libraries and development tools.
- Nix-packaged helpers.
- Other deliberately retained store closures.

It is not a backup of:

- Mutable `.venv` directories.
- uv’s cache.
- Uncommitted source.
- Downloaded papers or datasets.
- Generated research outputs.
- Credentials.

Likewise, preserving a toolchain does not preserve every input required to reproduce a project’s behavior.

### Decisions deferred

- Which non-Nix project assets need separate backup or retention?
- Where those policies should be documented so a “cached environment” is never mistaken for a complete project backup.

## Suggested order

1. Finish the previously documented system and workbench improvements.
2. Inspect local roots and storage usage.
3. Document and test project retirement.
4. Evaluate whether a separate retention host solves a real problem.
5. Test explicit store transfer and retention.
6. Add binary-cache serving only if it improves that workflow.
7. Automate publication or pruning only after the manual lifecycle is understood.

Default outcome if no separate-host need emerges: keep local environment lifecycle management and skip `nix-serve`.

This is a deferred design handoff only. No configuration, cleanup actions, cache deployment, or repository changes have been performed.
