# GitWorktreeCleaner

A small SwiftUI macOS app for cleaning up `git worktree`s. Register one or
more local repositories, pick the worktrees you no longer need, and remove
them in bulk with `git worktree remove --force`.

## Features

- **Multiple repositories** — repositories you add are kept in a sidebar and
  persisted across launches (UserDefaults).
- **Worktree list** — reads `git worktree list --porcelain` and shows each
  worktree's path, branch, HEAD SHA, and status (`bare`, `locked`,
  `prunable`). The repository's main worktree is shown but can't be selected
  for removal (git refuses to remove it anyway).
- **Bulk removal** — click anywhere on a row to toggle its checkbox, select
  several worktrees, and remove them all at once. A confirmation dialog
  warns that `--force` discards uncommitted/untracked changes before
  anything is deleted.

## Requirements

- macOS 27.0 or later (see `MACOSX_DEPLOYMENT_TARGET` in the Xcode project)
- Xcode 27 to build
- `git` available on your normal shell `PATH` (the app resolves it through a
  login shell, the same way a Terminal session would)

## Building & running

```sh
make open   # opens GitWorktreeCleaner.xcodeproj in Xcode
```

Then build and run the `GitWorktreeCleaner` scheme as usual (⌘R).

## Distributing a .app

```sh
make zip    # Release build -> build/GitWorktreeCleaner.zip
make clean  # removes build/
```

`make zip` builds a Release configuration `.app` and packages it with
`ditto` so the bundle stays intact after someone else downloads and unzips
it.

**Note on Gatekeeper:** this project is currently signed with a personal,
free-tier Apple ID ("Apple Development"), not a paid Developer ID. macOS
will block the app on other people's Macs with an "unidentified developer"
warning. Until this is signed with a Developer ID and notarized, anyone you
share the zip with needs to do one of the following the first time:

- Right-click (or Control-click) the app in Finder and choose **Open**, or
- Run `xattr -cr GitWorktreeCleaner.app` in Terminal to drop the quarantine
  flag Finder/Safari add to downloaded files.

## Safety notes

- Removal uses `git worktree remove --force`, which deletes the worktree's
  working directory **including any uncommitted or untracked changes**.
  This cannot be undone — make sure you actually want to discard those
  worktrees before confirming.
- The app runs without App Sandbox, since it needs to spawn `git` and read
  arbitrary repository paths on disk. It doesn't touch anything outside the
  repositories you explicitly add.
