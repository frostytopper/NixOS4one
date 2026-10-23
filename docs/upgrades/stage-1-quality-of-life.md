# Stage 1: Quality of Life

Low-risk, high-yield additions. Details TBD — one at a time.

- `networking.firewall.enable = true;` (on by default upstream, but declare it)
- `services.fstrim.enable = true;` for SSD health
- `programs.mtr.enable = true;` (SUID wrapper for network diagnostics)
- `documentation.man.generateCaches = true;` for fast `man -k`
