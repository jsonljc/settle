# Parallel Agents Setup (Cursor + Codex)

> **Rule:** Cursor and Codex must not edit the same files or branch simultaneously. Use separate worktrees and branches.

---

## Branch & Worktree Layout

| Agent | Role | Branch | Worktree path | Opens in |
|-------|------|--------|---------------|----------|
| **Cursor** | Implementation (UI, routes, core slice) | `impl/*` or `cursor/*` | `settle` (main) or `../settle-impl` | Cursor IDE |
| **Codex** | Verification (tests, lint, doc scans, tone sweep) | `verify/*` or `codex/*` | `../settle-verify` | Codex app / CLI |

`main` is the integration branch. Both agents merge into `main` (or a PR branch) when done.

---

## File Ownership (no overlap)

### Cursor (implementation worktree)

- `lib/screens/**`
- `lib/widgets/**`
- `lib/router.dart`
- `lib/main.dart`
- `lib/theme/**`
- `lib/models/**` (when adding new models)
- `lib/providers/**` (when adding new providers)
- `lib/services/**` (when adding new services)
- `lib/domain/**` (if present)
- `assets/**`

### Codex (verification worktree)

- `test/**`
- `analysis_options.yaml`
- `pubspec.yaml` (version / dependency bumps only; coordinate)
- `docs/**` (doc compliance, audits, checklists)
- `tool/**` (scripts, lint runners)
- `.cursor/rules/**`, `AGENTS.md` (when updating agent guidance)
- Tone-string sweeps across `lib/**` (copy only; avoid structural changes)

### Shared (coordinate before touching)

- `pubspec.yaml` — Cursor adds deps; Codex may bump versions. Merge order matters.
- `lib/router.dart` — Cursor adds routes; Codex may add route tests. Prefer Cursor first, then Codex adds tests.
- `AGENTS.md`, `docs/CANON.md` — Update rarely; decide owner per change.

---

## One-Time Setup

### 1. Create Codex verification worktree

From repo root (e.g. `~/settle`):

```bash
# Ensure main is clean or your work is committed
git checkout main
git pull

# Create verification branch and worktree
git branch verify/main 2>/dev/null || true
git worktree add ../settle-verify verify/main
```

### 2. Open in each tool

- **Cursor:** Open `~/settle` (or `~/settle-impl` if you move implementation to its own worktree).
- **Codex:** Open `~/settle-verify` as project root.

### 3. Optional: implementation worktree

If you want Cursor on a dedicated branch too:

```bash
git branch impl/main 2>/dev/null || true
git worktree add ../settle-impl impl/main
# Then open ../settle-impl in Cursor
```

---

## Workflow

1. **Cursor** implements on `impl/main` (or `main` if using single worktree for impl).
2. **Codex** runs verification on `verify/main`:
   - `flutter test`
   - `dart analyze`
   - Doc compliance (CANON, UX_RULES, ACCESSIBILITY)
   - Tone-string sweep
3. **Merge order:** Cursor merges to `main` first. Codex merges verification changes (tests, docs, lint) to `main` second, resolving any conflicts.
4. **Sync:** Periodically `git fetch` and `git merge main` (or rebase) in each worktree to stay current.

---

## Conflict Avoidance Checklist

Before starting a task, check:

- [ ] Am I in the right worktree? (`git worktree list`)
- [ ] Does my task touch files owned by the other agent? If yes, coordinate or sequence the work.
- [ ] If both need `lib/router.dart`: Cursor does route changes first; Codex adds/updates route tests after.

---

## Cursor Worktree Support

Cursor supports multiple folders/worktrees. Add each worktree as a separate folder in the workspace, or open them in separate Cursor windows. Each window = one worktree = one branch.

## Codex Support

Codex app: multiple agents/threads; each can target a different project path.  
Codex CLI: run in separate terminals, each `cd`'d to the appropriate worktree.
