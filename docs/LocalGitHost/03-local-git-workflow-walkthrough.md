**Draft** for `docs/LocalGitHost/03-local-git-workflow-walkthrough.md` below. This records the completed workflow, with one terminal command per code box. It has not been committed to GitHub.

---

# Local Git hosting walkthrough

Completed on November 2, 2026, on `lati`, operating as `brian` in `fish` through Termux SSH sessions.

This guide records the setup and synchronization commands used for NixOS4one. Initial setup is already complete: do not repeat repository creation or remote creation on the existing installation.

Run commands individually, inspect the output, and stop on errors.

## 1. Architecture

| Component | Location or name | Role |
|---|---|---|
| Working checkout | `/home/brian/Projects/NixOS4one` | Editing, committing, fetching, and pushing |
| Local bare repository | `/srv/git/NixOS4one.git` | Local Git host |
| Local remote | `origin` | SSH access to the bare repository |
| GitHub remote | `github` | Independent GitHub publication and retrieval |
| Hosting account | `git` | Restricted to `git-shell` |
| Working branch | `main` | Tracks `origin/main` |

NixOS configuration provides the hosting account, its restricted shell, authorized SSH key, OpenSSH, and the `/srv/git` directory.

The bare repository and working-checkout settings were established separately from `configuration.nix`.

## 2. Check the prerequisites

Check the hosting account:

```fish
id git
```

Recorded output:

```text
uid=989(git) gid=986(git) groups=986(git)
```

Check the hosting directory:

```fish
ls -ld /srv/git
```

Recorded output:

```text
drwxr-xr-x 2 git git 4096 Nov 2 15:03 /srv/git
```

The configured prerequisites were:

- `git` uses `git-shell`.
- Brian’s ed25519 public key is authorized for `git`.
- OpenSSH is enabled.
- `/srv/git` is owned by `git:git`, with mode `0755`.

## 3. Establish the repositories — one-time setup

The project was cloned successfully from GitHub into `/home/brian/Projects/NixOS4one`, on branch `main`. The exact clone command was not retained in the session record.

Create the bare repository once, as the hosting account:

```fish
sudo -u git git init --bare /srv/git/NixOS4one.git
```

Check its structure:

```fish
sudo -u git ls /srv/git/NixOS4one.git
```

Recorded output:

```text
config description HEAD hooks info objects refs
```

The bare repository is mutable data outside the Nix store. Its creation was deliberately kept separate from NixOS rebuilds.

## 4. Configure the two remotes — one-time setup

In the working checkout:

```fish
cd /home/brian/Projects/NixOS4one
```

Preserve the existing GitHub `origin` under the name `github`:

```fish
git remote rename origin github
```

Add the local bare repository as `origin`:

```fish
git remote add origin git@localhost:/srv/git/NixOS4one.git
```

Verify the remotes:

```fish
git remote -v
```

Recorded output:

```text
github  https://github.com/frostytopper/NixOS4one.git (fetch)
github  https://github.com/frostytopper/NixOS4one.git (push)
origin  git@localhost:/srv/git/NixOS4one.git (fetch)
origin  git@localhost:/srv/git/NixOS4one.git (push)
```

## 5. First push: verify SSH trust before accepting

Start the first push:

```fish
git push -u origin main
```

SSH paused at the first-connection confirmation for `localhost (::1)`.

Advertised fingerprint:

```text
SHA256:Uud+RlzS+n6WHdLoJv0jA7R4gbflVYbeImX/jp80ZYo
```

We left the prompt open and connected to `lati` from a second Termux session. We did not attach to tmux or establish its runtime status.

In that second shell on `lati`, inspect the host’s public-key fingerprint:

```fish
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Recorded output:

```text
256 SHA256:Uud+RlzS+n6WHdLoJv0jA7R4gbflVYbeImX/jp80ZYo root@lati (ED25519)
```

The fingerprints matched exactly. We returned to the original pending SSH prompt and entered:

```text
yes
```

That was a response to SSH, not a shell command.

SSH recorded localhost as a known host, and the push completed:

```text
To localhost:/srv/git/NixOS4one.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Set the repo-local push behavior:

```fish
git config push.default simple
```

The command returned without errors.

## 6. Verify the local host

Query the local remote’s refs:

```fish
git ls-remote origin
```

Recorded output:

```text
e60fe7cc7ab937b9d60025cc9b39736f7390ff3c        HEAD
e60fe7cc7ab937b9d60025cc9b39736f7390ff3c        refs/heads/main
```

Fetch from the local host:

```fish
git fetch origin
```

It returned without errors.

Compare local `main` with the fetched remote-tracking branch:

```fish
git rev-parse main origin/main
```

The operator confirmed an exact hash match.

Test the hosting account’s interactive-shell restriction:

```fish
ssh git@localhost
```

Recorded output:

```text
fatal: Interactive git shell is not enabled.
hint: ~/git-shell-commands should exist and have read and execute access.
Connection to localhost closed.
```

This was the intended rejection. No interactive shell was provided, and no `git-shell-commands` directory was created.

Step 2 was complete.

## 7. Synchronize a GitHub-side documentation commit

The completion record was then committed directly to GitHub through the connector:

| Item | Value |
|---|---|
| File | `docs/LocalGitHost/02-completion-record.md` |
| Branch | `main` |
| Commit | `0bc7f04bf6e20efa0c4baf5e823195680b6672e1` |
| Message | `docs: record completed local Git hosting step 2` |

That GitHub action did not update the working checkout or bare repository on `lati`. We synchronized them explicitly.

Check the working checkout:

```fish
git -C /home/brian/Projects/NixOS4one status --short --branch
```

Recorded output:

```text
## main...origin/main
```

The checkout was clean and on `main`.

The following commands were run from `/home/brian/Projects/NixOS4one`.

Fetch the GitHub changes:

```fish
git fetch github
```

Recorded branch update:

```text
e60fe7c..0bc7f04  main -> github/main
```

Integrate the fetched branch using a fast-forward only:

```fish
git merge --ff-only github/main
```

Recorded result:

```text
Updating e60fe7c..0bc7f04
Fast-forward
```

The completion record was added to the checkout.

Push the updated branch to the local bare repository:

```fish
git push origin main
```

Recorded result:

```text
To localhost:/srv/git/NixOS4one.git
   e60fe7c..0bc7f04  main -> main
```

The working branch, local bare repository’s `main`, and fetched `github/main` now agreed at `0bc7f04`.

## 8. What to repeat—and what not to repeat

For another GitHub-side update, the synchronization sequence we demonstrated is:

1. Check the working checkout.
2. Fetch `github`.
3. Fast-forward local `main` from `github/main`.
4. Push local `main` to `origin`.
5. Stop and diagnose if any command fails.

Do not repeat these completed setup actions:

- Creating `/srv/git/NixOS4one.git`.
- Renaming the original remote.
- Adding the local remote.
- Accepting an SSH host key without verification.

## 9. Scope and deferred work

- No terminal push to `github` was performed.
- GitHub publication and local hosting remain explicit, independent operations.
- No off-device backup was configured or tested.
- Backup remains deferred.
- Automation and command consolidation are future improvements; this guide preserves the individual-command workflow first.