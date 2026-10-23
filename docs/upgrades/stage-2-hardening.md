# Stage 2: Hardening

Tighten the exposed services. Details TBD — one at a time.

- sshd: `PasswordAuthentication = false`, `PermitRootLogin = "no"`
- `services.fail2ban.enable = true;` in front of sshd
- Targeted `boot.kernel.sysctl` hardening entries
- Review what actually needs OpenSSH on a Tailscale-meshed machine
