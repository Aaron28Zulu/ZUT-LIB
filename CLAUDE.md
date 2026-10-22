# CLAUDE.md

Read `AGENTS.md` first. It is the single set of rules for every agent in this repository.

Quick reminders:

- Screens import `lib/services/*.dart` interfaces only, never `lib/services/mock/` or `lib/data/`.
- Permission and tenant checks live in services. Add a test for the forbidden path.
- Use `Clock.now()`, never `DateTime.now()`.
- One-line commits: `type(scope): imperative summary` (see `docs/COMMITS.md`).
- Run `flutter analyze && flutter test` before committing.
