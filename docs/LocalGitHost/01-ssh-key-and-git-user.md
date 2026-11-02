# Step 1 — SSH key and the dedicated `git` hosting user

Scope: get the NixOS machine to a state where a dedicated `git` account
owns `/srv/git` and accepts authenticated Git operations over SSH.
Building on the architecture in `docs/local-git-hosting.md`: the `git`
account is a storage and access boundary — never a development account.

## Prerequisite: a public keypair (do this FIRST)

The NixOS declaration below embeds your **public** key in the system
configuration. Generate the key before touching `configuration.nix`,
otherwise you stall mid-edit.

```bash
ssh-keygen -t ed25519 -C "you@yourhost"   # press Enter to accept the default path
```

Notes from the field:

- At the "Enter file in which to save the key" prompt, press **Enter with
  nothing typed**. `ssh-keygen` does not expand `~` — typing `~/.ssh/`
  here creates nothing and fails with "Saving key failed".
- A passphrase is optional; recommended if the laptop ever leaves your
  hands.

Print the public key; you will paste the entire line into the config:

```bash
cat ~/.ssh/id_ed25519.pub
```

Include the trailing comment (`brian@lati` style) — it is inert metadata
that labels whose key it is, and Nix string syntax requires the quotes:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC... brian@lati"   # one line, in quotes, comment included
];
```

## Declare the hosting user in `configuration.nix`

Project rule: declarative only — no manual `useradd`, no imperative
`chown`. Slice added under `# -- Local Git Host --`:

```nix
users.groups.git = { };

users.users.git = {
  isSystemUser = true;
  group = "git";
  home = "/srv/git";
  createHome = true;
  shell = "${pkgs.git}/bin/git-shell";
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC... brian@lati"
  ];
};
```

What each piece does:

- `createHome = true` → `/srv/git` is created at activation, owned by the
  `git` user — the persistent hosting directory from the design doc.
- `shell = "${pkgs.git}/bin/git-shell"` → the account can only ever run
  `git-receive-pack` / `git-upload-pack`. No interactive login surface.
  (The interpolated string form is type-valid for `shell`; no `pkgs.git`
  package object needed.)
- `openssh.authorizedKeys.keys` → key-only access; requires
  `services.openssh.enable = true;` (already present in this config).

## The `nixos-config` bootstrap — read this BEFORE rolling back

If your first rebuild after adding the block fails with:

```
error: file 'nixos-config' was not found in the Nix search path
```

**This is NOT caused by the git-user block.** Do not roll back.

### Why it happens

The error occurs at *search-path resolution* — before your config is ever
evaluated. `nixos-rebuild` needs the name `nixos-config` to resolve to
`/etc/nixos/configuration.nix` in `NIX_PATH`. On this machine the config
already pinned nixpkgs:

```nix
nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
```

`nix.nixPath` **replaces** the default list rather than appending, so
this line silently dropped the default `nixos-config=` entry. Prior
rebuilds worked because the login session at the time still exported the
old default `NIX_PATH`; after the pinning generation became active and a
fresh login inherited the narrowed path, the **next** rebuild — whatever
was in it — failed with this error. Any edit would have triggered it.

Diagnose with:

```
echo $NIX_PATH          # shows nixpkgs=... but no nixos-config=...
sudo nix-channel --list # confirms channels are fine; this is a path issue
```

### The permanent fix

Restore the `nixos-config` entry declaratively, keeping the pin:

```nix
nix.nixPath = [
  "nixpkgs=${pkgs.path}"
  "nixos-config=/etc/nixos/configuration.nix"
];
```

### The one-time bootstrap (NOT a bypass)

Chicken-and-egg: evaluating *this fix* itself requires `<nixos-config>`
to resolve once. So exactly one rebuild uses `-I` to seed the lookup:

```
sudo nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix
```

After this switch succeeds, the corrected `nix.nixPath` owns the setting
and every subsequent rebuild is plain `sudo nixos-rebuild switch`. This
is the "do it right" path: nothing lives in shell startup files as a
permanent workaround.

Verify the fix took hold with a clean follow-up:

```
sudo nixos-rebuild switch
```

## Checkpoint

- [ ] `~/.ssh/id_ed25519.pub` exists and is pasted into the config with quotes
- [ ] `git` user + group declared; `/srv/git` will be auto-created and owned
- [ ] `git-shell` restricts the account to Git operations only
- [ ] `nix.nixPath` contains BOTH `nixpkgs` (pinned) and `nixos-config`
- [ ] First rebuild seeded with `-I nixos-config=...`, follow-up rebuild clean

Next: Step 2 — creating the first bare repository in `/srv/git`.
