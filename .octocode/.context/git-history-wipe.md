# Wipe git repo history, keep current file content

Verified 2026-07-12 in a disposable test repo (3 commits, 3 different
authors, nested subdirectory) — squashes all commits into one, keeps
working-tree content exactly as-is, drops all author/commit history.

## Procedure

```bash
# 1. Create a new orphan branch (no parent history)
git checkout --orphan temp_history_wipe

# 2. Stage all current files
git add -A

# 3. Commit as a single new root commit
git commit -m "Initial commit"

# 4. Delete the old branch
git branch -D main        # or: master

# 5. Rename current branch to main
git branch -m main

# 6. Force push, overwriting remote history
git push -f origin main
```

## Confirmed behavior

- All commits collapse into one new root commit.
- File content (including nested dirs) is preserved exactly.
- All prior author identities disappear from `git log`.
- `git push -f` makes the remote branch show only the new commit.

## Caveats (important if the goal includes scrubbing secrets)

- Old commits are **not destroyed**, just unreferenced — they remain as
  loose objects on the remote until garbage collected
  (`git cat-file -t <old-sha>` still resolves after force-push).
- On GitHub specifically, old commits can stay reachable for a while via:
  - forks that already have the old history
  - cached PR diffs / GitHub's internal caches
  - anyone who already cloned/fetched before the force-push
- Other contributors' local clones still have full old history until they
  re-clone or hard-reset — force-push doesn't touch their machines.
- If secrets were ever committed, this alone is **not sufficient**:
  rotate/revoke those credentials regardless of history rewriting, and
  contact GitHub support if you need forks/caches purged.
- Force-push will be rejected if branch protection is enabled on the
  target branch — disable it temporarily first.
- This is irreversible on the remote once pushed. Confirm before running
  step 6 against a real/shared repo.
