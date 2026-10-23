# Decision 03: Hardware as Data (facter)

`hardware.facter.reportPath` reads a JSON scan instead of a Nix module.

- Hardware config is data (`facter.json`), not hand-maintained Nix.
- Both `facter.json` and `hardware-configuration.nix` are gitignored:
  a full hardware manifest is sensitive and machine-specific.
- Fresh machine = run `nixos-facter`, keep the output local.
