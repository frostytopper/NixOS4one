# Headscale, HeadControl, and private file access

Status: design draft — implementation pending core-configuration verification.

## Goal

Provide easy browser access from Brian's phone to selected files on the NixOS laptop, `lati`, over a self-hosted private network.

Keep the setup small and declarative:

- Headscale as a native NixOS service.
- The existing Tailscale client on the laptop and the Tailscale app on the phone.
- A lightweight HTTP directory server on the laptop for browsing and downloading files.
- HeadControl as a private dashboard for monitoring and administration.

No Docker, Podman, or Compose is planned. This document records the design, not a tested deployment recipe. Exact options, package pins, commands, and firewall rules will follow verification against this system's nixpkgs revision.

## Component responsibilities

Headscale coordinates device registration and network membership. It does not launch the HTTP directory server or serve the laptop's files.

Tailscale clients establish the private connectivity used by the phone and laptop. Headscale replaces the hosted coordination service, not the clients.

The HTTP directory server provides directory listings and file downloads. It runs separately on `lati` and is accessible only through the intended private network.

HeadControl provides Headscale monitoring and administration. The selected project is `ahmadzip/HeadControl`, the Go-and-HTMX dashboard. It connects to Headscale using its HTTP API and an API key, not the Unix socket. It is not the filesystem browser.

## Layout

```text
lati — NixOS laptop
|
+-- headscale.service
|   +-- Persistent database and server keys
|
+-- tailscaled.service
|   +-- Laptop joins the Headscale-managed network
|
+-- HTTP directory server
|   +-- Selected directory; private browsing and downloads
|
+-- headcontrol.service
    +-- Private dashboard connected to the local Headscale API

phone
+-- Tailscale app connected to Headscale
+-- Browser
    +-- Private file-server URL on lati
    +-- Private HeadControl URL when administration is needed
```

Headscale is the coordination service, not an HTTP file-transfer proxy. File access uses the connectivity established by the Tailscale clients; relay use depends on network conditions and the configured DERP map.

## Native NixOS deployment

The implementation should declare:

1. Headscale through the existing `services.headscale` NixOS module.
2. HeadControl as a pinned Nix package launched by systemd.
3. An on-demand command or user service for the HTTP directory server.
4. Narrow firewall rules permitting only the intended access.
5. Persistent application state separately from declarative configuration.

Use SQLite for Headscale's state. The existing PostgreSQL service is not part of this design. HeadControl maintains its own local SQLite state.

Do not copy manually built executables into state directories as the final packaging strategy. Build application code through Nix; keep mutable state and credentials out of the repository.

## Everyday file-access workflow

1. Connect the phone's Tailscale app to the Headscale-managed network.
2. Start the directory server on `lati` when file access is needed.
3. Open a bookmarked private laptop URL in the phone's browser.
4. Browse directories and open or download files.
5. Stop the directory server when finished.

Initial scope is browsing and downloading only. Uploads, deletion, editing, synchronization, and a full remote file manager are out of scope.

Prefer an on-demand server initially. Python's `http.server` is a candidate for limited private use, not a public-facing production service. The implementation pass must verify its binding, firewall behavior, and served-directory boundaries, including symbolic links.

Do not make private HTTPS or Tailscale Serve certificate issuance a dependency of the initial file-browsing design. HTTP inside the encrypted private network is the initial target; browser-facing HTTPS can be evaluated separately.

## HeadControl workflow

HeadControl is for occasional monitoring and control, not a prerequisite for routine file access.

- Connect it to the local Headscale API using a dedicated administrative API key.
- Use it to inspect node and user status and perform supported administrative operations.
- Keep the Headscale CLI available for initial setup, recovery, and operations the dashboard does not support.
- Verify compatibility with the selected Headscale version before relying on particular dashboard actions.

Do not assume that the dashboard supports every registration or policy-management operation. Its documented baseline includes user management and node management such as renaming, expiry, deletion, tags, and routes.

## Exposure and security boundaries

Treat these as separate endpoints:

| Endpoint | Intended exposure |
| --- | --- |
| Headscale control server | Reachable by clients wherever the network is expected to operate |
| HTTP directory server | Private mesh access only |
| HeadControl dashboard | Private administrative access only |

Start with a dedicated sharing directory rather than exposing all of `/home/brian`. Credentials, private keys, and unrelated personal files must not become accessible accidentally. Review symbolic links and file permissions as part of the boundary.

The HTTP server's lack of application-level authentication is acceptable only if the verified network boundary provides the intended access restriction. Binding to a private address does not replace checking firewall and mesh access policy.

Treat HeadControl's API key and stored configuration as sensitive administrative state. A Headscale API key is not a substitute for dashboard access control; verify the dashboard's actual authentication behavior before exposing it beyond loopback.

## Control-server reachability

The starting design hosts Headscale on `lati`. The remaining deployment decision is how the phone reaches its control-server endpoint away from home.

For cellular use, choose a stable endpoint reachable independently of the private network Headscale establishes. Resolve public addressing, DNS, TLS, router forwarding or another suitable ingress method before declaring roaming supported.

Do not make access to Headscale depend solely on membership in the same Headscale-managed network. Do not assume that the laptop's short hostname resolves on the phone's Wi-Fi or cellular connection.

The laptop must be awake and reachable when coordination is needed. Existing peer connectivity can sometimes survive a control-server interruption, but that is not a substitute for a reachable control plane or a tested recovery path.

Embedded DERP hosting is not an initial requirement. Relay configuration and behavior must still be verified for the intended networks.

## Migration and recovery

Both devices must join the same Headscale-managed network for the intended workflow.

A single ordinary `tailscaled` instance is not simultaneously connected to the hosted Tailscale control plane and Headscale. Switching the laptop changes its active network membership; retaining the old account alone does not preserve an active fallback connection.

Perform migration with local laptop access available. Keep recovery instructions for returning to the previous control server, and do not stop systemd's daemon to launch a competing manual `tailscaled` process.

## Verification checklist

- [ ] Confirm package versions and configuration schema against the pinned nixpkgs revision.
- [ ] Headscale starts successfully from the native NixOS declaration.
- [ ] Headscale state and keys persist across service restarts and reboots.
- [ ] Phone and laptop join the same Headscale-managed network.
- [ ] HeadControl connects and displays both devices.
- [ ] Dashboard authentication and administrative exposure are reviewed.
- [ ] Phone can browse and download a test file from the selected directory.
- [ ] Files outside the intended sharing scope are not accidentally exposed.
- [ ] File server and dashboard are not reachable through unintended interfaces.
- [ ] Home Wi-Fi connectivity works.
- [ ] Cellular connectivity works after independent control-server ingress is configured.
- [ ] Laptop reboot, sleep/wake, and service recovery behavior are tested.
- [ ] Document a tested rollback and recovery procedure.

## Next documentation pass

After core-configuration verification, add the tested NixOS modules, HeadControl package definition, chosen control-server endpoint and TLS arrangement, file-server launch command, firewall rules, registration steps, backup procedure, and recovery commands.

Until then, this document is the design baseline rather than an installation guide.

## Upstream references

- Headscale: https://github.com/juanfont/headscale
- Brian's Headscale fork: https://github.com/frostytopper/headscale
- NixOS Headscale documentation: https://wiki.nixos.org/wiki/Headscale
- HeadControl: https://github.com/ahmadzip/HeadControl
- Python HTTP server documentation: https://docs.python.org/3/library/http.server.html
