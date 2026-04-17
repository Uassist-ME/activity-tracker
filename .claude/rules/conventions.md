# Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` new feature
- `fix:` bug fix
- `chore:` maintenance, tooling, config
- `refactor:` code restructuring
- `docs:` documentation
- `test:` adding or updating tests
- `style:` formatting, no code change

# Architecture

- Hexagonal architecture with feature-based layout under `modules/`
- No API routes — use Server Actions as inbound adapters (placed in `modules/<module>/infrastructure/actions/`)
- Do not edit lock files directly
- Always use absolute imports (`@/` or `@db/`), never relative imports
- No barrel `index.ts` files — import from specific files directly

# Pre-commit Hooks

- Husky + lint-staged run automatically before every commit
- ESLint (with autofix) runs on staged `*.{ts,tsx}` files
- Prettier runs on staged `*.{ts,tsx,js,jsx,json,css,md}` files
- If lint fails, the commit is blocked — fix the errors before retrying
