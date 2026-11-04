# Config Lineage

One config, versioned by confirmed upgrades. The root `configuration.nix`
is always the live one; everything versioned under `docs/` is history.

| File | Status | What it is |
|---|---|---|
| [`configuration.nix`](../configuration.nix) (repo root) | **Live** | The last confirmed-working `/etc/nixos/configuration.nix`. Updated only by promotion: stage a candidate, prove it with `nixos-rebuild switch`, promote, commit. |
| [`docs/configuration_v0.nix`](configuration_v0.nix) | Origin (archived) | The exact config this project started with — never edited. Every later version is measured against it. |
| [`docs/configuration_v1.nix`](configuration_v1.nix) | Archived | First confirmed system-wide upgrade; succeeded the Neovim Phase1 snapshots (`NV_01_01`–`NV_01_05` in `neovim/upgrades/Phase1/`). See [`configuration_v1_notes.md`](configuration_v1_notes.md). All of its improvements survive in the live config. |
| [`docs/LocalGitHost/configuration_LGit_01_01.nix`](LocalGitHost/configuration_LGit_01_01.nix) | Promoted | Staged upgrade adding local bare-repo git hosting. Promoted to root on 2026-11-04 ([commit 2158baf](https://github.com/frostytopper/NixOS4one/commit/2158baf09e089837680a547fca6b32942936be4f)). |

## Convention

- Works in progress live as staged files beside their upgrade docs, named
  `configuration_<SERIES>_<NN_NN>.nix`.
- A staged file is only promoted to root after `nixos-rebuild switch`
  proves it on the machine.
- Archived versions are immutable records — annotations go in their
  companion `.md` notes, never in the archived `.nix` itself.
