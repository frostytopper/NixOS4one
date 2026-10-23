# Decision 01: Single File

One `configuration.nix` for the whole system.

- Every option is one grep away; every change is a one-file diff.
- Modules get introduced only when the file genuinely outgrows a head.
- Tradeoff accepted: no multi-host reuse. The audience is one person, one machine.
