I read the existing step-2 playbook through the GitHub connector. Below is a completion record for `docs/LocalGitHost/02-completion-record.md`. This documents the completed work; it has not been committed or published to GitHub.

The key distinction is **state**: NixOS configures the hosting service and account, while the bare repository, checkout, remotes, SSH trust, and branch tracking were established separately.

---

# Step 2 completion record — local NixOS4one hosting

Completed: November 2, 2026  
Host: `lati`  
Operator: `brian`  
Shell: `fish`

Companion documents:

- `02-bare-repos-and-remotes-playbook.md`
- `configuration_LGit_01_01.nix`

## Outcome

The existing GitHub project now has a working local bare repository accessed over SSH.

| Item | Completed configuration |
|---|---|
| Working checkout | `/home/brian/Projects/NixOS4one` |
| Bare repository | `/srv/git/NixOS4one.git` |
| Hosting account | `git` |
| Working branch | `main` |
| Local remote | `origin` → `git@localhost:/srv/git/NixOS4one.git` |
| GitHub remote | `github` → `https://github.com/frostytopper/NixOS4one.git` |
| Branch upstream | `main` tracks `origin/main` |
| Repo-local push behavior | `push.default = simple` |
| Interactive SSH access as `git` | Rejected as intended |

The commands below are a historical record, not instructions to repeat setup.

## 1. Prerequisites already completed

Before creating the bare repository:

- The `git` system account existed.
- Its shell was configured as `git-shell`.
- Brian’s ed25519 public key was configured in the git account’s authorized keys.
- OpenSSH was enabled.
- `/srv/git` existed with ownership `git:git` and mode `0755`.

Recorded account verification:

```text
uid=989(git) gid=986(git) groups=986(git)
```

Recorded directory verification:

```text
drwxr-xr-x 2 git git 4096 Nov 2 15:03 /srv/git
```

These account and service prerequisites belong to the NixOS configuration. The repository data and per-checkout Git settings below were established outside `configuration.nix`.

## 2. Working checkout and bare repository

The project was successfully cloned from GitHub into:

```text
/home/brian/Projects/NixOS4one
```

Its current branch was `main`.

The bare repository was created once, as the hosting account:

```fish
sudo -u git git init --bare /srv/git/NixOS4one.git
```

Its structure was checked:

```fish
sudo -u git ls /srv/git/NixOS4one.git
```

Observed output:

```text
config description HEAD hooks info objects refs
```

The bare repository is mutable project data outside the Nix store. It was deliberately not made into a repository-creation action that runs during NixOS rebuilds.

## 3. Separate local hosting from GitHub publication

In the working checkout, the original GitHub remote was renamed:

```fish
git remote rename origin github
```

The local SSH host was added as `origin`:

```fish
git remote add origin git@localhost:/srv/git/NixOS4one.git
```

The remote configuration was verified:

```fish
git remote -v
```

Observed output:

```text
github  https://github.com/frostytopper/NixOS4one.git (fetch)
github  https://github.com/frostytopper/NixOS4one.git (push)
origin  git@localhost:/srv/git/NixOS4one.git (fetch)
origin  git@localhost:/srv/git/NixOS4one.git (push)
```

GitHub remained available under its explicit name. It was not removed or used for publication during this step.

## 4. Verify localhost’s SSH identity before accepting it

The first local push was started:

```fish
git push -u origin main
```

SSH paused at its first-connection confirmation for `localhost (::1)`, advertising:

```text
SHA256:Uud+RlzS+n6WHdLoJv0jA7R4gbflVYbeImX/jp80ZYo
```

The prompt was left open while a second Termux session connected to `lati`. This avoided interrupting the push or relying on an unverified tmux runtime state.

In the second shell on `lati`, the host’s ed25519 public-key fingerprint was checked:

```fish
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Observed output:

```text
256 SHA256:Uud+RlzS+n6WHdLoJv0jA7R4gbflVYbeImX/jp80ZYo root@lati (ED25519)
```

The fingerprints matched exactly. Only after this comparison was `yes` entered at the original pending SSH prompt.

SSH reported:

```text
Warning: Permanently added 'localhost' (ED25519) to the list of known hosts.
```

No tmux attachment or runtime verification was performed as part of this workaround.

## 5. Complete the first push and establish upstream tracking

After accepting the verified host key, the pending push completed successfully:

```text
To localhost:/srv/git/NixOS4one.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

The repo-local push setting was then applied:

```fish
git config push.default simple
```

The command returned without errors.

## 6. Verify remote refs and fetch

The local server’s advertised refs were queried:

```fish
git ls-remote origin
```

Observed output:

```text
e60fe7cc7ab937b9d60025cc9b39736f7390ff3c        HEAD
e60fe7cc7ab937b9d60025cc9b39736f7390ff3c        refs/heads/main
```

A fetch was performed:

```fish
git fetch origin
```

It returned without errors.

Local `main` and the fetched remote-tracking branch were compared:

```fish
git rev-parse main origin/main
```

The operator confirmed that the hashes matched exactly.

Checkpoint commit:

```text
e60fe7cc7ab937b9d60025cc9b39736f7390ff3c
```

This records the commit at verification time, not a permanent expected value for future checks.

## 7. Verify that interactive shell access is rejected

The hosting account’s interactive SSH boundary was tested:

```fish
ssh git@localhost
```

Observed output:

```text
fatal: Interactive git shell is not enabled.
hint: ~/git-shell-commands should exist and have read and execute access.
Connection to localhost closed.
```

This was the expected rejection. No interactive shell was provided.

The hint was not treated as a setup error, and no `git-shell-commands` directory was created.

## 8. Final checkpoint

- [x] Created `/srv/git/NixOS4one.git` once as `git`.
- [x] Preserved GitHub as the `github` remote.
- [x] Configured local SSH hosting as `origin`.
- [x] Verified the SSH host fingerprint before accepting it.
- [x] Successfully pushed `main` to the local bare repository.
- [x] Established tracking of `origin/main`.
- [x] Set repo-local `push.default` to `simple`.
- [x] Queried the remote refs and fetched successfully.
- [x] Confirmed local `main` matches `origin/main`.
- [x] Confirmed interactive SSH access as `git` is rejected.

## Scope boundaries

No GitHub push was performed.

No off-device backup was configured or tested. Backup remains a separate future step 3.

Step 2 is complete.