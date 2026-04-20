---
name: local-source-git
description: Use when a Perforce-managed or otherwise non-git workspace needs a local-only git repo for source tracking, experimental/test harness separation, or fix-only cleanup. Best when you want to keep the working tree at the project root, keep git metadata in a separate relative directory, and compare branches such as probe-mixed vs fix-only without affecting official SCM.
---

# Local Source Git

Use this skill when the workspace is not officially managed by git, but you still want local commit history and clean diffs while working.

This workflow is for:
- separating probe or test harness code from submit candidates
- keeping local-only history in a Perforce workspace
- tracking only the source trees you explicitly add

Do not use this to replace the official SCM. This is a local helper layer only.

## Defaults

- Worktree root: the project root
- Separate git dir: a path relative to the project root, usually `../LocalGit/<repo-name>-source-only`
- Initial branch: `local-main`
- Untracked files: hidden by default so large workspaces stay readable

## Initialize

From the project root, run the bundled script with a project-root-relative git dir:

```bash
scripts/init_local_source_git.sh --project-root . --git-dir ../LocalGit/<repo-name>-source-only
```

The script will:
- create a separate git dir
- write a relative `gitdir:` pointer in `.git`
- make the repo readable from both WSL and Windows tools
- set local defaults for source-only usage
- populate a local exclude file that ignores the workspace by default and re-allows only common UE source trees

If the project root already points to a different git dir, stop and resolve that first.

## Track Only Source

This workflow is source-only. Add only `Source` trees you want to track.
Do not add project metadata or workflow files such as `.uproject`, `.uplugin`, `AGENTS.md`, or `NEXT.md`.

Typical add examples:

```bash
git add Tsl/Source
git add Tsl/Plugins/*/Source
git add Engine/Source
git add Engine/Plugins/*/Source
```

Prefer smaller, task-relevant adds over tracking the whole tree.

## Suggested Branch Flow

Use branch names that describe the role of each snapshot:

- `local-main`: local baseline for the workspace
- `task/<ticket-or-topic>`: active work branch
- `probe/<topic>`: experimental or instrumentation branch
- `fix-only`: cleaned submit-candidate state

For probe-versus-fix cleanup:

1. Commit the mixed state on a branch such as `probe-mixed`.
2. Remove test-only code from the worktree.
3. Commit the cleaned state on `fix-only`.
4. Compare them with:

```bash
git diff probe-mixed..fix-only
```

For a single file:

```bash
git diff probe-mixed..fix-only -- Tsl/Source/...
```

To recover a file from the probe snapshot:

```bash
git show probe-mixed:Tsl/Source/...
```

## Windows GUI

When using a separate git dir, GUI tools should be pointed at the project root, not the separate git-dir folder.

- Right-click the project root in Explorer.
- The project root `.git` file should contain a relative `gitdir:` entry, not a WSL-only absolute path.

## Guardrails

- Never add local-source-git metadata to Perforce.
- Keep explanations and commands project-root-relative when possible.
- Do not rely on this repo for generated outputs or project metadata; it is for local source history only.
- After cleanup, verify the fix-only branch still builds before using it as the submit candidate view.
