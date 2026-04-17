# Git Branching Strategy

## Branch Structure

- `main` — Production-ready code (protected, no direct commits)
- `staging` — Pre-production testing (protected, no direct commits)
- `dev` — Integration branch for active development
- `feat/<name>`, `fix/<name>`, `chore/<name>`, `refactor/<name>`, `docs/<name>` — Working branches

## Rules

- **Never commit directly to `main` or `staging`** — enforced by PreToolUse hook
- Always create feature branches from `dev`: `git checkout -b feat/<name> dev`
- Branch naming must match Conventional Commits prefixes: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`
- **Always use fast-forward merges** into `dev` (`git merge <branch>` without `--no-ff`) — no merge commits

## PR Flow

```
feature branch → dev → staging → main
```

1. Create branch from `dev`
2. Work & commit using Conventional Commits
3. Open PR to `dev` — code review required
4. Merge to `dev` — dev deployment
5. Promote `dev` → `staging` via PR — QA/testing
6. Promote `staging` → `main` via PR — production release
