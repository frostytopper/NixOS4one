# Tier 2 — Current-system paths and shared-shell wiring

Status: Complete on lati, 2026-11-10. Applied and verified by Brian.
Repository synchronization of the final working configuration is pending.

## Completed

- ~~Centralize shared filesystem paths.~~ Extended `paths` using `rec`, allowing sibling references, and added an explanatory developer comment.
- ~~Declare credential and SOPS configuration locations.~~ `paths.credentials` identifies `~/secrets/credentials.yaml`; `paths.sopsConfig` identifies `~/secrets/.sops.yaml`. `CREDENTIALS_FILE` and `SOPS_CONFIG` reference those declarations through `environment.sessionVariables`.
- ~~Declare directory permissions.~~ Added `systemd.tmpfiles.rules` for Brian-owned `~/secrets` (0700) and `~/.local/lib/nix/shells` (0755). Contents remain user-managed.
- ~~Relocate the existing Python/uv shell.~~ Shared shell: `~/.local/lib/nix/shells/py-uv-shell.nix`. Pipeline's shell/direnv wiring was updated; Brian confirmed activation on entry.
- ~~Verify credential access and Pipeline integration.~~ Brian confirmed full paths and readable files from Pixel → lati. SOPS decryption and NCBI API-key extraction passed. Pipeline's `.envrc` already captures the credential; Brian confirmed using that integration for PMC downloads.

## Verification and disclosure boundary

- System configuration test build passed.
- Pipeline direnv activation passed.
- Path checks displayed locations, not secret contents.
- Standalone SOPS extraction redirected decrypted output to `/dev/null`; no credential value was displayed.
- Pipeline activation captures the credential without printing it.
- Plain SOPS extraction can still print secrets without redirection or capture; this is not a universal suppression guarantee.
- The extraction check did not test NCBI API authentication. PMC downloads are separately recorded as Brian's reported operational use.

## Operational handoff — home-directory file access from Pixel

Temporarily serve Brian's home directory from lati over Tailscale, running the foreground server in a separate tmux session. Brian explicitly selected `/home/brian`, rather than only the configuration file.

### Create the session

Run on lati. Create `file-server` only if it does not already exist:

```fish
tmux list-sessions
```

```fish
tmux new-session -d -s file-server -c /home/brian
```

```fish
tmux set-option -t file-server remain-on-exit on
```

```fish
tmux attach-session -t file-server
```

### Start inside that session

Run interactively so sudo can prompt:

```fish
sudo tailscale serve --http=8080 /home/brian
```

Open the printed URL on Pixel. Detach with Ctrl+B, then D.

Return to the session:

```fish
tmux attach-session -t file-server
```

Inspect output without attaching:

```fish
tmux capture-pane -p -t file-server
```

To stop, attach and press Ctrl+C in the pane running Tailscale Serve.

### Troubleshooting and access boundary

- The initial detached launch exited before its error could be inspected.
- Interactive launch exposed an authorization error: serving a filesystem path required elevated permissions.
- Use an absolute target path and sudo for direct file serving.
- This uses Tailscale Serve, not public Tailscale Funnel.
- Serving the home directory exposes files beneath it through the endpoint to permitted clients. Local directory permissions are not a substitute for limiting the scope of an elevated file server.
- Non-disclosing credential checks do not guarantee files cannot be disclosed through this separate HTTP endpoint.
- Successful HTTP access from Pixel has not yet been confirmed in this session. This is an operational procedure, not a declarative service or verified reboot-persistent setup.

## Scope boundary

This pass wires Brian's existing system. No general NixOS4one tooling framework, helper-package architecture, Home Manager, or system flake was introduced.

SSH hardening, managed jobs, module extraction, and broader environment redesign remain outside this completed pass.

This documentation commit does not include the final working configuration or the local shared-shell contents. Capture and review those separately before repository synchronization.
