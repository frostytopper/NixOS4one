# Handoff — approved implementation order

Status: **Approved** — implementation order and decision inventory recorded.
Implementation has not been performed.

Scope: NixOS4one system, mobile workflow, shared development foundation,
module extraction, Neovim language wiring, and environment-retention planning.
This document records sequencing and decisions only; it is not an
implementation guide or configuration change.

The PMC downloader is explicitly excluded from the blocking sequence. It can
be resumed or addressed at home and should not delay the work below.

## References

- [SOPS/direnv command surface](handoff-sops-direnv-command-surface.md)
- [Module extraction candidates](handoff-module-extraction-candidates.md)
- [Python development workbench](handoff-python-development-workbench.md)
- [Development-environment retention](handoff-development-environment-retention.md)
- [Neovim language wiring](handoff-neovim-language-wiring.md)

## Sequencing overview

Approved order: quick system fixes, mobile workflow, shared development
foundation, module extraction, then deferred tracks.

Two later workbench decisions supersede details in the earlier SOPS/direnv
handoff:

- The shared credential interface is a Nix-packaged executable because
  project `.envrc` files are evaluated by Bash, not fish.
- Project entry may verify Git configuration, but repository bootstrap or
  remote mutation remains an explicit command and must not happen silently.

## 1. Immediate system hygiene

1. Clean up leftover Neovim swap or backup files in `~/secrets`.  
   Decide whether any file needs inspection or preservation before removal.

2. Apply Tier 0 maintenance in one rebuild.  
   Decide final garbage-collection age, boot-generation limit, journal size
   cap, and zram enablement before implementation.

3. Apply mobile quality-of-life improvements separately: fish notifications,
   fzf, tmux clipboard passthrough, and mosh.  
   Decide the exact fish plugin set, fzf keybinding scope, and any required
   mosh firewall or port handling.

4. Harden SSH after testing a fresh key-only session.  
   Decide rollout timing and the rollback path in case remote access fails.

## 2. Shared development foundation

1. Establish package and file locations.  
   Decide canonical homes for the Python shell constructor, helper packages,
   package entry point, and shared direnv configuration.

2. Add independently buildable helper packaging.  
   Decide system-wide versus Brian-only installation, package structure, and
   whether job commands ship separately.

3. Parameterize the Python/uv shell.  
   Decide the default interpreter, baseline tools, project-native dependency
   inputs, explicit synchronization behavior, and interpreter-mismatch
   handling.

4. Implement the shared credential helper as a Nix-packaged executable.  
   Decide the command name, argument format, supported SOPS expressions,
   treatment of empty values, and whether to provide a nonprinting
   availability check.

5. Update project activation and Pipeline credential wiring.  
   Decide explicit shared-file paths versus a shared direnv helper,
   credentials on entry versus explicit acquisition, and the read-only Git
   verification boundary.

6. Add `dev-doctor`.  
   Decide output format, project-specific checks, shell identity reporting,
   and which conditions produce a nonzero exit status.

7. Add managed jobs.  
   Decide naming and collision policy, environment allowlist, credential
   delivery, log retention, resource limits, and whether user lingering is
   appropriate. Start with terminal independence only.

## 3. Module extraction

1. Extract the local git host first.  
   Decide option names and defaults for enablement, user, repository root,
   and authorized keys.

2. Extract persistent tmux second.  
   Decide user, session, and command options; UID derivation; and final
   resurrect/continuum behavior.

3. Add the shared project template and guarded post-commit hook.  
   Decide template-directory mechanism, missing-origin behavior,
   conflicting-remote behavior, and how projects adopt the template.

4. Consider a secrets-layout module.  
   Decide whether session variables, packages, and directory permissions
   genuinely justify one bundled option boundary.

5. Optionally extract maintenance defaults.  
   Decide whether the working Tier 0 configuration remains monolithic or
   becomes a curated reusable module.

## 4. Deferred tracks

1. Audit, then complete Neovim language wiring.  
   Decide system-versus-project ownership, server and formatter selection,
   formatting policy, project-root and toolchain discovery, and whether
   debugging, testing, or build integrations are in scope. Validate C and
   C++ separately and regression-test Python.

2. Establish environment-retention policy.  
   Decide active, dormant, and retired criteria; known-good environment
   handling; documentation versus maintenance command; preview behavior; and
   recovery testing.

3. Evaluate off-machine retention and `nix-serve`.  
   Decide the suitable host, selected closures, transfer and verification,
   storage and pruning policy, network exposure, signing and trust, key
   handling, and manual versus automated publication.

4. Revisit a development-toolchain pin.  
   Decide system package set versus independent pin, shared versus
   project-specific pinning, update ownership, testing, rollback, and
   storage location.

## First implementation session

The first concrete session can cover the secrets cleanup and Tier 0
maintenance, with mobile quality-of-life changes staged separately. Package
locations, helper packaging, and Python-shell parameterization should be
settled together before any helper implementation begins.
