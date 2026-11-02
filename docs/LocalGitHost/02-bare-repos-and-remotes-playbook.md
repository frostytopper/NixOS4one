# Step 2 playbook — first bare repo and the two remotes

Companion to `01-ssh-key-and-git-user.md` (prerequisite, already done)
and the design in `docs/local-git-hosting.md`. This document is the
walking aid for the NEXT chat session: the assistant guiding step 2
should follow this file.

State entering step 2:

- `git` system user exists, owns `/srv/git`, shell is `git-shell`
- brian's ed25519 public key is in the git user's authorizedKeys
- `nix.nixPath` carries both the nixpkgs pin and `nixos-config`
- `services.openssh.enable = true;`

## Interaction rules (do not skip — mobile session)

The operator is on a phone with a screen keyboard.

1. Present ONE terminal command per code box. Never put two commands in
   the same box.
2. A step may contain several boxes; keep them visually separate.
3. Wait for the operator's reported output before advancing to the next
   step. Treat any error as a stop-and-diagnose point, not a retry.
4. Config snippets (Nix) may be shown as one block — they are pasted as
   a unit into `configuration.nix`, not run.
5. Steps flow from the design doc's setup sequence; numbers below match
   `local-git-hosting.md` steps 2 through 6.

## 2.0 Choose the first project

Pick one existing working repository (e.g. the NixOS config checkout or
the Pipeline project). Record its path; the bare repo gets the name
`<Project>.git`.

## 2.1 Sanity check (design doc step 1 verification)

Confirm activation created the hosting user and directory:

```
id git
```

```
ls -ld /srv/git
```

Expected: user git exists; `/srv/git` owned by `git:git`, mode 0755.
If either fails, step 1 did not apply — stop and fix that first.

## 2.2 Create the bare repository (design doc step 2)

Create it ONCE, as the hosting user, outside the Nix store. Bare repo
contents are mutable data; a rebuild must never recreate or reset it,
so this is deliberately NOT declared in Nix.

```
sudo -u git git init --bare /srv/git/<Project>.git
```

Verify ownership and structure:

```
sudo -u git ls /srv/git/<Project>.git
```

Expected: HEAD description config hooks info objects refs — all owned
by git.

## 2.3 Rescue an existing origin (design doc step 5)

In the working repo, check what origin currently is:

```
cd /path/to/<Project>
```

```
git remote -v
```

If `origin` already points at GitHub, rename it so the local host can
take the origin slot:

```
git remote rename origin github
```

If there is no remote at all, skip the rename.

## 2.4 Point origin at the local host (design doc step 4)

Same-machine access still goes through sshd as the git user — this
exercises exactly the boundary the hosting account was built for:

```
git remote add origin git@localhost:/srv/git/<Project>.git
```

## 2.5 First push with upstream (design doc step 6)

```
git push -u origin main
```

First-time notes for this push:

- sshd will ask to confirm localhost's host key fingerprint once.
  Accept it.
- If brian's key has a passphrase, that prompt appears here (and on
  every push until an agent or a password-store helper is added —
  out of scope for step 2).

Confirm the push configuration so plain `git push` targets the local
host:

```
git config push.default simple
```

## 2.6 Verification (design doc step 8, partial)

Round-trip the remote without touching anything else on disk:

```
git ls-remote origin
```

```
git fetch origin
```

Expected: ls-remote lists main at the same commit as the working repo.
The interactive shell test should FAIL on purpose — that is the
boundary working:

```
ssh git@localhost
```

Expected: a git-shell rejection like "Interactive git shell is not
enabled". If you get a prompt, something is misconfigured — stop.

## GitHub publication stays explicit (design doc step 7)

Do NOT add a github remote in this session unless the project is being
published now. When it is, use the existing github.com repo URL:

```
git remote add github git@github.com:frostytopper/<Project>.git
```

Pushes to `origin` and `github` are fully independent; the local host
never forwards anything. (see local-git-hosting.md: Daily workflow,
Publication boundaries)

## Checkpoint for step 2

- [ ] /srv/git/<Project>.git exists, owned by git, created once via sudo -u git
- [ ] working repo's old GitHub origin renamed to `github` (if it existed)
- [ ] origin = git@localhost:/srv/git/<Project>.git
- [ ] git push -u origin main succeeded; branch upstream set
- [ ] git ls-remote origin matches the local main commit
- [ ] interactive ssh to git@localhost is rejected by git-shell

After this: repeat 2.2 per additional project; off-device backup of
/srv/git (design doc "Backup and recovery") deserves its own step 3.
