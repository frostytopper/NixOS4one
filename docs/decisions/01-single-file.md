# Decision 01: Single File - No Home-Manager - No Flake Config

One `configuration.nix` for the whole system.

- Every option is one grep away; every change is a one-file diff.
- Modules get introduced only when the file genuinely outgrows a head.
- Tradeoff accepted: Portability isn't as convenient without Flakes
- Tradeoff accepted: Excluding Home-Manager pushes configuration into
- Nix, dotfile management requires discipline from the start

