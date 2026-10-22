# Commit message standard

Every commit is **one line**, at most **72 characters**, in Conventional Commits form:

```
<type>(<scope>): <imperative summary>
```

No body is required. If a commit truly needs more context, put it in the PR description,
not the commit.

## Types

| Type | Use for |
| --- | --- |
| `feat` | New user-visible behaviour |
| `fix` | Bug fix |
| `refactor` | Code change with no behaviour change |
| `test` | Adding or fixing tests only |
| `docs` | Documentation only |
| `style` | Formatting only (`dart format`), no logic |
| `chore` | Tooling, dependencies, seed regeneration, config |
| `perf` | Performance improvement |
| `build` | Gradle, Android, web build config |
| `ci` | CI workflow changes |
| `revert` | Reverting a previous commit |

## Scopes

Use the feature area: `auth`, `tenancy`, `resources`, `search`, `loans`, `study`, `quiz`,
`flashcards`, `plan`, `notifications`, `admin`, `platform`, `demo`, `seed`, `theme`, `ui`,
`deps`, `android`, `web`, `agents`.

## Rules

1. Imperative mood: "add", "fix", "remove". Not "added", "adds", "adding".
2. Lowercase after the colon. No trailing full stop.
3. Say what changes, not how you felt: not "fix stuff", "wip", "update", "final version".
4. One logical change per commit. If the summary needs "and", consider two commits.
5. Append `!` after the scope for breaking changes to a service interface:
   `refactor(loans)!: rename approve to approveLoan`.
6. Requirement IDs go in the PR, not the commit line, unless they fit naturally.

## Good

```
feat(loans): generate single-use collection QR on approval
fix(search): keep filters when sort order changes
test(tenancy): assert northbridge user cannot read zut loans
chore(seed): regenerate questions for ict 2205
docs(agents): add hand-off rules for parallel agents
```

## Bad

```
Updated files
feat: Added the new QR feature and fixed some bugs in search.
WIP
fix(loans): Fixes
```

## Optional local hook

`tools/commit-msg` rejects messages that break the rules. Install with:

```bash
cp tools/commit-msg .git/hooks/commit-msg   # Windows Git Bash works the same
chmod +x .git/hooks/commit-msg
```
