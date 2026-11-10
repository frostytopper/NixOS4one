# Tier 2 — Current-system paths and shared-shell wiring

Status: Complete for this pass on lati, 2026-11-10. Applied and verified by Brian.
The uploaded current-system configuration is synchronized as `configuration.nix` in this commit, unchanged from `configuration-3.txt`. Shell-library and further permissions work are explicitly deferred.

## Completed

- ~~Centralize shared filesystem paths.~~ Extended `paths` using `rec`, allowing sibling references, and added an explanatory developer comment.
- ~~Declare credential and SOPS configuration locations.~~ `paths.credentials` identifies `~/secrets/credentials.yaml`; `paths.sopsConfig` identifies `~/secrets/.sops.yaml`. `CREDENTIALS_FILE` and `SOPS_CONFIG` reference those declarations through `environment.sessionVariables`.
- ~~Declare the secrets directory permission rule.~~ `systemd.tmpfiles.rules` declares `~/secrets` with mode 0700, owned by the configured user and group. Contents remain user-managed. The uploaded configuration has no shell-library tmpfiles rule; shell-library and other permissions work are deferred at Brian's request.
- ~~Relocate the existing Python/uv shell locally.~~ Shared shell: `~/.local/lib/nix/shells/py-uv-shell.nix`. Pipeline's shell/direnv wiring was updated; Brian confirmed activation on entry. The local shared-shell contents are not included in this commit.
- ~~Verify credential access and Pipeline integration.~~ Brian confirmed full paths and readable files from Pixel → lati. SOPS decryption and NCBI API-key extraction passed. Pipeline's `.envrc` already captures the credential; Brian confirmed using that integration for PMC downloads.
- ~~Declare on-demand HTTP file access.~~ `environment.systemPackages` includes the Nix-built `file-server` launcher. It creates a separate tmux session when absent, starts foreground Tailscale Serve with interactive sudo, and switches or attaches to the session on subsequent launches. No file-server boot service was added.
- ~~Verify HTTP access from Pixel.~~ Brian confirmed reconnecting and downloading the Tier 2 configuration on 2026-11-10. The uploaded `.txt` file is stored in the repository as `configuration.nix`.

## Verification and disclosure boundary

- System configuration test build previously passed on lati.
- Pipeline direnv activation passed.
- Path checks displayed locations, not secret contents.
- Standalone SOPS extraction redirected decrypted output to `/dev/null`; no credential value was displayed.
- Pipeline activation captures the credential without printing it.
- Plain SOPS extraction can still print secrets without redirection or capture; this is not a universal suppression guarantee.
- The extraction check did not test NCBI API authentication. PMC downloads are separately recorded as Brian's reported operational use.
- Reconnection and HTTP download are Brian-confirmed operational results. A fresh build of the uploaded snapshot, a stop-access test, and reboot behavior were not independently tested during repository synchronization.

## Operational handoff — home-directory file access from Pixel

Brian explicitly selected `/home/brian`, rather than only the configuration file. Launch on lati:

```fish
file-server
```

For a newly created session, the server command starts automatically and sudo can prompt in the pane. Open the printed URL on Pixel. Detach with Ctrl+B, then D. Run `file-server` again to switch or attach to the existing session; this does not restart a server that has already stopped.

The server command is:

```fish
sudo tailscale serve --http=8080 /home/brian
```

Stop by pressing Ctrl+C in the pane running Tailscale Serve. The launcher leaves a Fish shell available afterward; use the server command above inside that pane to restart serving.

Inspect output without attaching:

```fish
tmux capture-pane -p -t file-server
```

### Troubleshooting and access boundary

- The initial manual detached launch exited before its error could be inspected. Interactive launch exposed an authorization error: serving a filesystem path required elevated permissions.
- Use an absolute target path and sudo for direct file serving. The declared launcher uses the configured home path and Nix package paths.
- This uses Tailscale Serve, not public Tailscale Funnel.
- Serving the home directory exposes files beneath it through the endpoint to permitted clients. Local directory permissions are not a substitute for limiting the scope of an elevated file server.
- Non-disclosing credential checks do not guarantee files cannot be disclosed through this separate HTTP endpoint.
- The launcher is declared in NixOS, but file serving remains on demand and foreground-managed in tmux, not a verified reboot-persistent file-server service.

## Scope boundary and deferred work

This pass wires Brian's existing system and adds one on-demand launcher. No general tooling framework, Home Manager, or system flake was introduced.

Shell-library directory management and other permissions work are deferred at Brian's explicit request. `paths.shellLibrary` remains declared, without a corresponding tmpfiles rule in this snapshot.

SSH hardening, managed jobs, module extraction, and broader environment redesign remain outside this completed pass.

This commit preserves the complete uploaded configuration unchanged, including existing maintenance, networking, Fish, tmux, and Mosh changes; it does not claim every included setting was newly introduced or independently verified in Tier 2. Local shared-shell contents and Pipeline files are not included.
