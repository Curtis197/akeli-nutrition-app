# Branch Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a single clean `v1-ui` branch containing the best UI from `gemini-version`, the 22-file audit from `hallowed-serpent`, and no AI-tool artifacts — then replace `main` with it.

**Architecture:** `gemini-version` is the base. Worktrees are removed first (they live inside `.kilo/`), then the audit directory is pulled from `hallowed-serpent`, tracked noise is removed via `git rm`, untracked noise is deleted from the filesystem and added to `.gitignore`, untracked root files are moved into `akeli_docs/`, and finally `v1-ui` is force-pushed to `main`.

**Tech Stack:** Git, Flutter (verification only), Bash

---

## Task 1: Remove registered git worktrees

**Files:**
- Modify: `.git/worktrees/` (managed by git internally)

The two worktrees (`hallowed-serpent`, `spice-peak`) live inside `.kilo/worktrees/`. They must be deregistered with git before `.kilo/` is deleted, otherwise git's internal refs become orphaned.

- [ ] **Step 1: Confirm worktree list**

```bash
git worktree list
```

Expected output:
```
C:/Users/DELL LATITUDE 7480/akeli-nutrition-app                                  <hash> [gemini-version]
C:/Users/DELL LATITUDE 7480/akeli-nutrition-app/.kilo/worktrees/hallowed-serpent <hash> [hallowed-serpent]
C:/Users/DELL LATITUDE 7480/akeli-nutrition-app/.kilo/worktrees/spice-peak       <hash> [spice-peak]
```

- [ ] **Step 2: Remove the `hallowed-serpent` worktree**

```bash
git worktree remove --force ".kilo/worktrees/hallowed-serpent"
```

Expected: no output (success is silent).

- [ ] **Step 3: Remove the `spice-peak` worktree**

```bash
git worktree remove --force ".kilo/worktrees/spice-peak"
```

Expected: no output.

- [ ] **Step 4: Verify worktrees are gone**

```bash
git worktree list
```

Expected output — only main worktree remains:
```
C:/Users/DELL LATITUDE 7480/akeli-nutrition-app <hash> [gemini-version]
```

---

## Task 2: Create the `v1-ui` branch

**Files:**
- No file changes — git branch operation only

- [ ] **Step 1: Confirm current branch is `gemini-version`**

```bash
git branch --show-current
```

Expected: `gemini-version`

- [ ] **Step 2: Create `v1-ui` from current HEAD**

```bash
git checkout -b v1-ui
```

Expected:
```
Switched to a new branch 'v1-ui'
```

- [ ] **Step 3: Verify**

```bash
git branch --show-current
```

Expected: `v1-ui`

---

## Task 3: Pull audit files from `hallowed-serpent`

**Files:**
- Create: `audit/pages/` (22 markdown files)

`hallowed-serpent` added an `audit/pages/` directory that does not exist on `gemini-version`. We use `git checkout <branch> -- <path>` to copy it into the working tree and stage it — no merge, no history rewrite.

- [ ] **Step 1: Confirm `audit/` does not yet exist**

```bash
ls audit/ 2>/dev/null && echo "exists" || echo "not found"
```

Expected: `not found`

- [ ] **Step 2: Check out the audit directory from `hallowed-serpent`**

```bash
git checkout hallowed-serpent -- audit/
```

Expected: no output (success is silent).

- [ ] **Step 3: Verify 22 files were staged**

```bash
git status --short audit/
```

Expected: 22 lines, each starting with `A  audit/pages/...`

- [ ] **Step 4: Commit**

```bash
git commit -m "docs(audit): add 22-page UI audit from hallowed-serpent"
```

Expected: `1 file changed` → actually ~22 files changed, 1 directory added.

---

## Task 4: Remove the FlutterFlow legacy app (tracked)

**Files:**
- Delete: `flutterflow_application/` (tracked in git — requires `git rm`)

- [ ] **Step 1: Confirm it is tracked**

```bash
git ls-files flutterflow_application/ | wc -l
```

Expected: a number > 0 (the tracked file count).

- [ ] **Step 2: Remove from git and disk**

```bash
git rm -r flutterflow_application/
```

Expected: many lines of `rm 'flutterflow_application/...'`

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove FlutterFlow V0 legacy app"
```

---

## Task 5: Remove untracked AI-tool directories and guard `.gitignore`

**Files:**
- Delete from disk: `.kilo/`, `.qwen/`
- Modify: `.gitignore`

`.kilo/` and `.qwen/` are untracked — git does not know about them. We delete them from the filesystem and add entries to `.gitignore` so future AI tools cannot pollute the working tree silently.

- [ ] **Step 1: Confirm both directories are untracked**

```bash
git status --short | grep -E "^\?\? \.(kilo|qwen)"
```

Expected:
```
?? .kilo/
?? .qwen/
```

- [ ] **Step 2: Delete both directories from disk**

```bash
rm -rf .kilo/ .qwen/
```

Expected: no output.

- [ ] **Step 3: Confirm they are gone**

```bash
ls -d .kilo .qwen 2>/dev/null && echo "still present" || echo "gone"
```

Expected: `gone`

- [ ] **Step 4: Add entries to `.gitignore`**

Open `.gitignore` and append these lines at the end:

```
# AI tool working directories
.kilo/
.qwen/
```

- [ ] **Step 5: Commit the `.gitignore` change**

```bash
git add .gitignore
git commit -m "chore: add AI tool directories to .gitignore"
```

---

## Task 6: Move untracked root planning files into `akeli_docs/`

**Files:**
- Move (untracked → tracked): `LOGGING_INSTRUCTIONS.md` → `akeli_docs/LOGGING_INSTRUCTIONS.md`
- Move (untracked → tracked): `LOGGING_QUICK_REFERENCE.md` → `akeli_docs/LOGGING_QUICK_REFERENCE.md`
- Move (untracked → tracked): `LOGGING_README.md` → `akeli_docs/LOGGING_README.md`
- Move (untracked → tracked): `PROJECT_PLAN.md` → `akeli_docs/PROJECT_PLAN.md`

These files are untracked (not in git history). We move them into `akeli_docs/` so they are captured in version control and findable alongside the other documentation.

- [ ] **Step 1: Confirm the files exist at the root**

```bash
ls LOGGING_INSTRUCTIONS.md LOGGING_QUICK_REFERENCE.md LOGGING_README.md PROJECT_PLAN.md 2>/dev/null
```

Expected: all 4 filenames printed. (If any are missing, skip that file — do not error.)

- [ ] **Step 2: Move each file**

```bash
mv LOGGING_INSTRUCTIONS.md akeli_docs/LOGGING_INSTRUCTIONS.md
mv LOGGING_QUICK_REFERENCE.md akeli_docs/LOGGING_QUICK_REFERENCE.md
mv LOGGING_README.md akeli_docs/LOGGING_README.md
mv PROJECT_PLAN.md akeli_docs/PROJECT_PLAN.md
```

- [ ] **Step 3: Stage and commit**

```bash
git add akeli_docs/LOGGING_INSTRUCTIONS.md akeli_docs/LOGGING_QUICK_REFERENCE.md akeli_docs/LOGGING_README.md akeli_docs/PROJECT_PLAN.md
git commit -m "chore: move root planning files into akeli_docs"
```

---

## Task 7: Verify the Flutter build is clean

**Files:**
- Read-only verification — no changes

Before touching `main`, confirm the branch builds without errors.

- [ ] **Step 1: Fetch dependencies**

```bash
flutter pub get
```

Expected: `Got dependencies!` (no errors).

- [ ] **Step 2: Run the analyzer**

```bash
flutter analyze
```

Expected: `No issues found!` or only info-level hints — no errors or warnings that would block a build.

- [ ] **Step 3: If `flutter analyze` reports errors, fix them before proceeding**

Do not continue to Task 8 with a broken build.

---

## Task 8: Force-push `v1-ui` to `main`

**Files:**
- No local file changes — remote branch operation

- [ ] **Step 1: Confirm you are on `v1-ui`**

```bash
git branch --show-current
```

Expected: `v1-ui`

- [ ] **Step 2: Review the commits that will become `main`**

```bash
git log --oneline -10
```

Confirm the log looks clean — the last few commits should be your consolidation commits (audit, flutterflow removal, gitignore, file moves).

- [ ] **Step 3: Force-push `v1-ui` as the new `main`**

```bash
git push origin v1-ui:main --force
```

Expected:
```
To https://github.com/Curtis197/akeli-nutrition-app.git
 + <old_hash>...<new_hash> v1-ui -> main (forced update)
```

- [ ] **Step 4: Verify on GitHub**

Open `https://github.com/Curtis197/akeli-nutrition-app` and confirm:
- Default branch `main` shows your consolidation commits at the top
- Old branches (`gemini-version`, `hallowed-serpent`, `claude/akeli-nutrition-v1-eDrPn`, `spice-peak`, `projet-akeli-nutrition-app-26744`) are all still listed under Branches

---

## Task 9: Update local `main` to match remote

**Files:**
- No file changes — local branch pointer update

- [ ] **Step 1: Point local `main` to the same commit as `v1-ui`**

```bash
git branch -f main v1-ui
```

Expected: `Branch 'main' set up to track remote branch 'main' from 'origin'.` or silent success.

- [ ] **Step 2: Verify**

```bash
git log --oneline main -3
```

Expected: same 3 commits as `git log --oneline v1-ui -3`.

---

## Success Checklist

Run these after all tasks are complete:

- [ ] `git branch --show-current` → `v1-ui`
- [ ] `flutter analyze` → no errors
- [ ] `ls audit/pages/ | wc -l` → `22`
- [ ] `ls akeli_docs/ | grep -E "LOGGING|PROJECT_PLAN"` → 4 files found
- [ ] `ls .kilo .qwen 2>/dev/null` → no output (directories gone)
- [ ] `git ls-files flutterflow_application/` → no output (removed from git)
- [ ] `git log --oneline origin/main -3` → matches `v1-ui` HEAD
- [ ] All old branches visible: `git branch -r | grep -E "gemini-version|hallowed-serpent|claude/akeli"` → at least 3 results
