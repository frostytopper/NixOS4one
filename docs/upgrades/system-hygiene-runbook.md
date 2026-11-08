# System hygiene runbook

Baseline: commit `818a561e21d657f43f7c06c3febc1ded29aa6fdb`, especially `configuration.nix` and `docs/handoff-approved-implementation-order.md`.

Status: instructions only; no system changes have been executed. Run commands on lati, not on the work computer. GitHub is the reading surface. Individual commands have separate blocks. Multi-line terminal blocks are simple Bash scripts using `#!/usr/bin/env bash`; save and run them with Bash rather than pasting them into fish. For individual Bash commands, enter `bash` first if your login shell is fish.

## Scope and proposed decisions

This implements only the first two immediate-hygiene items: inspect secret-adjacent editor artifacts, then Tier 0 maintenance. Mobile improvements, SSH hardening, helper packaging, module extraction, and development-retention design remain separate.

Proposed values: weekly GC deleting generations older than 30 days; eight systemd-boot entries; 512M persistent and 128M runtime journal limits; zram enabled with module defaults. These are starting policy choices, not measured hardware tuning.

GC is destructive: the age is a generation-retention rule, not a promise to retain every development environment for 30 days. Unrooted store paths can be collected regardless of age. If a dormant shell must remain available offline and you have not verified its GC roots or other retention, stop before enabling automatic GC. Boot-menu limits and GC are independent; eight boot entries do not guarantee eight surviving system generations.

## 1. Record a local baseline

Keep this output local; do not paste secret contents or machine inventory into GitHub. Do not copy hardware-configuration.nix or facter.json into the public repository.

If your login shell is fish, enter Bash first:

```bash
bash
```

Save and run the following Bash script on lati. It continues after command failures and displays output and errors while also writing them to a timestamped text file in `~/baselinelog/`. Keep the report local; do not upload machine inventory or secret contents to GitHub.

```bash
#!/usr/bin/env bash
set +e
umask 077
mkdir -p "$HOME/baselinelog"

{
  mkdir -p "$HOME/.local/state/nixos-hygiene"
  date -Is
  nixos-version
  readlink -f /run/current-system
  df -h / /boot /nix
  free -h
  swapon --show
  journalctl --disk-usage
  systemctl --failed
  sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
  systemctl list-timers --all 'nix-*'
} 2>&1 | tee "$HOME/baselinelog/baseline-$(date +%Y%m%d-%H%M%S).txt"
```

The committed file already enables automatic store optimisation and configuration copying. Preserve both. Do not change system.stateVersion, update channels, or use --upgrade during this maintenance pass. The repository is not a complete deployable machine configuration: its hardware imports remain local.

## 2. Inspect secrets-directory editor artifacts

Do not run a wildcard delete. Close or identify active editors before deciding a swap file is abandoned. The existing persistent tmux service may own an editor even when no interactive terminal is attached.

```bash
ls -ld "$HOME/secrets"
```

```bash
find "$HOME/secrets" -maxdepth 1 -type f \( -name '*.sw?' -o -name '*~' -o -name '*.bak' -o -name '*.orig' \) -printf '%M %u %s %f\n'
```

```bash
pgrep -a nvim || true
```

```bash
lsof +D "$HOME/secrets"
```

The filename patterns are a candidate inventory, not a complete leak detector. No lsof output is not proof that an artifact is safe to delete. Inspect metadata and editor ownership first.

For an abandoned swap needing recovery, use `nvim -r /absolute/path/to/original-file` locally. Recovery can display plaintext credentials; avoid shared screens, recordings, and copied terminal output. Preserve needed edits in an appropriate encrypted destination before removing the swap.

For each individually reviewed disposable artifact, run this simple Bash script and enter its exact absolute pathname:

```bash
#!/usr/bin/env bash
read -r -p 'Exact abandoned artifact path: ' artifact
ls -l -- "$artifact"
rm -i -- "$artifact"
unset artifact
```

Deletion is not guaranteed secure erasure, especially on SSDs or snapshots. If plaintext credentials escaped your intended boundary, rotate them rather than treating deletion as remediation. Do not disable editor recovery globally as part of this pass.

## 3. Back up and edit the live configuration

Make a private local backup; do not overwrite /etc/nixos from the public example.

```bash
sudo install -d -m 0700 /root/nixos-hygiene-backups
```

```bash
#!/usr/bin/env bash
sudo install -m 0600 /etc/nixos/configuration.nix \
  "/root/nixos-hygiene-backups/configuration.nix.$(date +%Y%m%d-%H%M%S)"
```

```bash
sudoedit /etc/nixos/configuration.nix
```

Insert the following inside the existing top-level module body, alongside the current Nix and boot settings, not inside the let bindings or programs block. Search the actual live file first: merge existing definitions rather than duplicating them. Leave `nix.optimise.automatic = true;` in place.

```nix
  # Tier 0: bounded maintenance and memory-pressure relief.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.loader.systemd-boot.configurationLimit = 8;

  services.journald.extraConfig = ''
    SystemMaxUse=512M
    RuntimeMaxUse=128M
  '';

  zramSwap.enable = true;
```

Journal limits bound journal storage, not every application log, and need not shrink existing active files immediately. Zram supplies compressed RAM-backed swap; it is not extra physical RAM, a disk-swap replacement requirement, or hibernation storage. Keep existing swap configuration unchanged.

## 4. Build, review, and activate

```bash
sudo nixos-rebuild build
```

Stop on evaluation or build errors. This checks against your installed Nixpkgs rather than assuming that today's web documentation matches your system. Building does not activate the configuration.

Optionally inspect the built closure before activation:

```bash
nix store diff-closures /run/current-system ./result
```

Unexpected broad package changes are a reason to investigate the package-source baseline, not continue blindly. Once the build and diff are satisfactory:

```bash
sudo nixos-rebuild switch
```

This activates services and the GC timer. A due persistent timer can run after activation, so do not switch before accepting the retention policy. Do not manually start nix-gc.service or run nix-collect-garbage -d for this exercise. Build and switch are two commands, but only one activation.

## 5. Verify

Save and run this Bash script on lati. It continues after command failures and displays output on screen without writing a log.

```bash
#!/usr/bin/env bash
set +e

systemctl --failed
systemctl status nix-gc.timer --no-pager
systemctl list-timers --all nix-gc.timer
systemctl cat nix-gc.service
journalctl -u systemd-journald -b -n 30 --no-pager
journalctl --disk-usage
zramctl
swapon --show
free -h
bootctl list
df -h / /boot /nix
```

Confirm that the timer exists, its service uses the intended age, a zram swap device is active, and boot entries remain available. Bootctl can list non-NixOS entries too. Reboot when local recovery access is available; confirm normal login and desktop operation afterward. No immediate space reduction is required for success: GC is scheduled, and journal usage is workload-dependent.

## 6. Rollback and limits

If activation causes trouble while the previous generation still exists:

```bash
sudo nixos-rebuild switch --rollback
```

Alternatively select a previous retained NixOS entry at boot. Rollback does not restore the source configuration: edit /etc/nixos/configuration.nix back to the saved settings before a later rebuild. It also cannot resurrect collected store paths, deleted artifacts, or discarded journal history. Stop the timer if you need to pause pending collection:

```bash
sudo systemctl stop nix-gc.timer
```

Stopping the timer does not cancel a GC service already running and is not a declarative fix; correct the configuration afterward.

## Completion record

Record locally: build date, chosen values, artifact decisions without secret contents, verification outcome, and successful reboot. Only then mirror reviewed non-sensitive configuration changes into the educational repository. Keep hardware files and credentials local.

Next separate stages: mobile quality-of-life changes, then SSH hardening after a fresh key-only OpenSSH session and an explicit recovery plan. Tailscale SSH is a distinct access path; do not treat its success as proof of OpenSSH key authentication.

## Documentation

- NixOS option reference: https://nixos.org/manual/nixos/stable/options
- Bootloader limits: https://wiki.nixos.org/wiki/Bootloader
- Zram: https://wiki.nixos.org/wiki/Swap
