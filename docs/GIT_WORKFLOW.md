# Git workflow

Remote: `github.com/Stella05lulu/zutlib-app`. Model: lightweight Git Flow suited to a
one-developer academic project with AI agents contributing in parallel.

## Long-lived branches

| Branch | Purpose | Who merges into it |
| --- | --- | --- |
| `main` | Always demo-ready. Tagged for each demonstration/assessment milestone. | `release/*` and `hotfix/*` only |
| `develop` | Integration branch. Builds and passes tests at all times. | Feature, fix, docs, chore branches via PR |

Both are protected: no direct pushes, PR required, CI (`flutter analyze`, `flutter test`) must pass.

## Short-lived branches

Branch from `develop` unless stated. Name: `<type>/<req-id-or-scope>-<short-kebab-summary>`.

| Prefix | Use | Example |
| --- | --- | --- |
| `feature/` | New behaviour from the SRS | `feature/fr-bor-06-qr-collection` |
| `fix/` | Bug in `develop` | `fix/loan-expiry-uses-wall-clock` |
| `docs/` | Documentation only | `docs/demo-script-steps` |
| `chore/` | Tooling, deps, seed regeneration | `chore/regenerate-seed` |
| `test/` | Tests only | `test/tenant-isolation-loans` |
| `release/` | Stabilise a milestone, from `develop` | `release/1.0.0` |
| `hotfix/` | Urgent fix on `main`, from `main` | `hotfix/1.0.1-pdf-viewer-crash` |

Rules:

- One task per branch. Keep it under ~400 changed lines where possible.
- Rebase on `develop` before opening the PR (`git pull --rebase origin develop`). Do not
  rebase a branch someone else is pushing to.
- Delete the branch after merge.

## Pull requests

1. Open against `develop` (or `main` for `release/*` and `hotfix/*`).
2. Title follows the commit standard: `feat(loans): add QR collection scanning`.
3. Fill in `.github/pull_request_template.md`, including requirement IDs.
4. **Squash merge** feature/fix/docs/chore/test branches so `develop` has one commit per PR.
   The squash commit message is the PR title.
5. **Merge commit** (no squash) for `release/*` into `main` and back into `develop`, so history
   shows the release point.

## Releases

```bash
git switch develop && git pull
git switch -c release/1.0.0
# bump version in pubspec.yaml, run the demo script (docs/DEMO_SCRIPT.md) 3 times (NFR-10)
git commit -am "chore(release): bump version to 1.0.0"
# PR release/1.0.0 -> main, merge, then:
git tag -a v1.0.0 -m "Demonstration build 1.0.0"
git push origin v1.0.0
# merge main back into develop
```

Versioning: `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`. Milestones: `0.x` during build,
`1.0.0` for the panel demonstration.

## Hotfixes

Branch `hotfix/<version>-<summary>` from `main`, fix, PR to `main`, tag the patch version,
then merge `main` into `develop`.
