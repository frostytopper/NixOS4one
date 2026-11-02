# Local-first Git hosting

## Purpose

Keep everyday development and repository hosting on the NixOS machine. Use GitHub only as an explicit publication destination. For a handful of repositories, ordinary Git and SSH are sufficient: no web forge, database, containers, or automatic mirroring.

Commits are always local. Pushing transfers committed history to a chosen destination.

## Architecture

| Component | Responsibility |
| --- | --- |
| Working repositories, owned by your normal user | Editing, building, testing, and committing |
| Bare repositories, owned by a dedicated Linux `git` account | Receiving pushes and serving repository history over SSH |
| Optional GitHub repositories | Receiving deliberately published branches and tags |

Keep existing project folders where they are. Each hosted project gets a separate bare repository, such as `Pipeline.git`, in persistent storage. A bare repository has Git history and references but no editable checkout; it does not create a nested project folder.

The `git` account is a storage and access boundary, not a development account, Git author identity, or Nix package profile. Continue working as your normal user. A separate hosting account is optional for local-only Git, but provides the separation described here.

## NixOS responsibilities

Declare the hosting infrastructure in the existing system configuration:

- Git availability.
- The dedicated `git` user and its persistent repository directory.
- SSH access using authorized public keys, with access restricted to the intended Git operations.
- Directory ownership and permissions, plus any backup scheduling.

Keep repository contents outside the Nix store. They are mutable data, not system configuration. Create each bare repository once; rebuilding NixOS must not reset its contents. Keep private keys and other credentials out of committed configuration.

## Setup sequence

1. Choose a persistent hosting directory and establish the `git` account's ownership and SSH access.
2. Create one empty bare repository per project.
3. Keep or initialize each working repository under your normal account. Preserve existing history.
4. Configure `origin` to point to the corresponding local host repository over SSH.
5. If a project already uses `origin` for GitHub, rename that remote to `github` before adding the local `origin`.
6. Push the working branch to the local host and set its upstream there. Check the push configuration so ordinary pushes target the local host.
7. Add a `github` remote only for projects you intend to publish.
8. Verify clone, fetch, and push access, then establish an off-device backup.

## Daily workflow

1. Edit and test in the working repository.
2. Review changes and commit locally.
3. Push to the local `origin` as the normal checkpoint.
4. When ready to publish, explicitly push the intended branch or tag to `github`.

The two remotes are independent. A push to the local host does not automatically forward anything to GitHub. No hooks or synchronization service are required.

When using Termux to SSH into the laptop, development and Git operations still run on the laptop. A phone-side clone is unnecessary for that workflow.

## Publication boundaries

Pushing a branch publishes its reachable history, not just its latest file snapshot. Deleting a secret in a later commit does not remove it from earlier commits.

Keep credentials and private machine data out of publishable history from the start. Do not merge private-only history into a branch intended for publication. Inspect the destination, branch, and history before publishing; avoid blanket mirror pushes to GitHub.

## Backup and recovery

A working repository and a bare repository on the same disk are not an off-device backup. Back up the hosted repositories separately from the laptop. Preserve uncommitted and untracked working files separately when needed: they are not present in the hosted repository.

Recovery requires both the NixOS configuration that recreates the hosting environment and the backed-up repository data. Neither replaces the other.

## Scope

One development account, one narrow hosting account, one bare repository per project, explicit GitHub publication, and off-device backup. Add no further infrastructure unless a concrete requirement demands it.
