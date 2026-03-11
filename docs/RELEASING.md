# PetBuddy2 Release Workflow

This mirrors the RGX/BLU release flow: bump metadata, land a focused commit, tag it, then push both the commit and tag.

## 1. Prep the release
1. Pick the new semantic version (`vX.Y.Z`).
2. Update every version string:
   - `PetBuddy2.toc`
   - README badge + compatibility table
   - `docs/README.md`
   - `docs/CHANGES.md` (add a dated section for the release)
3. Capture notable changes in `docs/CHANGES.md`.
4. Run `/reload` in-game (or equivalent) to verify UI changes, then re-export screenshots if anything visual changed.

## 2. Commit
```
git status
git add -A
git commit -m "Release vX.Y.Z"
```

## 3. Tag and push
```
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin main
git push origin vX.Y.Z
```
- Replace `main` if the default branch differs.
- The annotated tag keeps automation and Curse/Wago packagers happy.

## 4. Publish
1. Open GitHub → Releases → “Draft new release”.
2. Select the new tag, give it the version title, and paste the matching `docs/CHANGES.md` entry.
3. Attach the packaged zip if needed, then publish.

Following these steps keeps PetBuddy2’s release hygiene identical to BLU, with clean history and reproducible tags.
