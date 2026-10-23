# Stage 0: Baseline

The repository `README` ("What's Inside") describes the live baseline.

- The pre-NixOS4One config snapshot lives in git history as
  `configuration_old.nix` (root) — kept for comparison, not for use.
- Validation loop for every stage below: `nixos-rebuild build` →
  `nixos-rebuild test` → only then `nixos-rebuild switch`.
- Rollback is a boot-menu entry away; keep one known-good generation around.
