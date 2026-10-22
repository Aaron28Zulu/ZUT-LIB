# AGENTS.md

Instructions for any AI coding agent (Claude, Copilot, Cursor, Codex, etc.) and any human
contributor working on ZutLib. Read this file first, then the file in `docs/` that matches
the task. `CLAUDE.md` points here so every tool reads the same rules.

## What this project is

ZutLib is a Flutter demonstration prototype for Zambia University College of Technology:
a multi-tenant past-paper library with digital borrowing (QR collection) and a rule-based
smart study assistant. The single source of truth for scope is the **ZutLib Software
Requirements Specification** (Google Doc in the ZUT-LIB Drive folder). Requirement IDs
such as `FR-BOR-06` or `NFR-07` come from that document. Use them in code comments, tests,
PR descriptions and issues so work stays traceable.

Everything runs offline. All backend behaviour is mocked behind abstract service
interfaces. All data is fictional seed data in `assets/seed/`.

## Repository map

| Path | Contents |
| --- | --- |
| `lib/core/` | Clock, errors, ids, theme, app-wide helpers |
| `lib/models/` | Plain Dart domain entities from SRS section 6 (all carry `tenantId` except `Tenant`) |
| `lib/data/` | `DataStore` (in-memory tables + persistence), seed loader, tenant-scoped repositories |
| `lib/services/` | Abstract service interfaces. Screens import only these |
| `lib/services/mock/` | Rule-based mock implementations of every interface |
| `lib/state/` | `AppState` (session, services wiring) exposed with `provider` |
| `lib/screens/<role>/` | Screens grouped by role: `common`, `student`, `librarian`, `admin`, `platform` |
| `lib/widgets/` | Shared widgets (empty states, status chips, section headers) |
| `assets/seed/` | Generated seed JSON. Do not hand-edit; change `tools/generate_seed.py` |
| `assets/papers/` | Sample PDFs (generated, clearly marked SAMPLE) |
| `test/` | Service-layer unit tests (tenant isolation, permissions, loans, quiz scoring) |
| `docs/` | Conventions referenced below |

## Commands

```bash
flutter pub get
flutter analyze                 # must be clean before every commit
flutter test                    # must pass before every commit
flutter test --coverage         # NFR-12: service layer >= 70% line coverage
flutter run -d emulator-5554    # Android (primary target)
flutter run -d chrome           # Web (projection)
flutter build apk --release     # NFR-14: keep under 60 MB
python tools/generate_seed.py   # regenerate assets/seed/*.json and assets/papers/*.pdf
```

## Hard rules (do not break these)

1. **Screens depend on interfaces only** (NFR-11). A file in `lib/screens/` must never import
   from `lib/services/mock/` or `lib/data/`. Wire implementations in `lib/state/app_state.dart`.
2. **Enforce permissions in the service layer** (FR-AUTH-08, NFR-07). Hiding a button is not
   a permission check. Every service method that reads or writes data calls the guard first.
3. **Every query is tenant-filtered** (FR-TEN-02). Use the tenant-scoped repositories; never
   iterate a raw `DataStore` table from a service without a `tenantId` filter.
4. **Use the demo clock** (FR-DEMO-03). Never call `DateTime.now()` outside `lib/core/clock.dart`.
5. **No ID numbers** (FR-BOR-13). Never add a field for an NRC, passport or national ID.
6. **No real personal data** anywhere, including tests and screenshots.
7. **No new dependency** without a one-line reason in the PR description. Prefer the SDK.
8. **Seed data is generated.** Edit `tools/generate_seed.py`, then regenerate.

## How agents communicate

Agents work asynchronously and often in parallel. Treat the repo as the shared channel.

- **Claim work before starting.** Open (or comment on) a GitHub issue, or add a line to
  `docs/WORKLOG.md` under "In progress" with your branch name and the requirement IDs.
  If someone else has already claimed it, pick something else or ask.
- **One task, one branch, one PR.** See `docs/GIT_WORKFLOW.md`.
- **Hand-offs are written, not implied.** When you stop mid-task, append to `docs/WORKLOG.md`:
  what is done, what is left, what you were unsure about, and the exact command that fails
  (if any). The next agent starts by reading the latest entry.
- **State facts, not feelings.** "3 tests fail in `loan_service_test.dart`: expiry uses
  wall time" beats "mostly working". Paste the failing output.
- **Ask instead of guessing on scope.** If the SRS is silent or ambiguous, write the question
  in the PR or issue, pick the most conservative reading, and mark it `// SRS-QUESTION:` in
  code so a human can find it.
- **Do not rewrite another agent's work in passing.** If you disagree with existing code,
  raise it in the PR or a separate issue; keep your diff scoped.
- **PR description template** (`.github/pull_request_template.md`): Summary, Requirement IDs,
  How tested, Screenshots (for UI), Follow-ups.
- **Escalate to a human** for: changes to the SRS scope, new dependencies, anything touching
  permissions matrix semantics, and deleting or renaming public service methods.

## Before you open a PR

- [ ] `flutter analyze` clean, `flutter test` green
- [ ] New service behaviour has a unit test, including the forbidden path
- [ ] UI follows `docs/DESIGN_CONVENTIONS.md` and passes `docs/ANTI_SLOP.md`
- [ ] Commit messages follow `docs/COMMITS.md`
- [ ] Requirement IDs listed in the PR description

## Further reading

- `docs/DESIGN_CONVENTIONS.md` - layout, typography, colour, components, copy
- `docs/ANTI_SLOP.md` - things that make an app look machine-generated; avoid all of them
- `docs/GIT_WORKFLOW.md` - branching model and PR flow
- `docs/COMMITS.md` - one-line commit message standard
- `docs/ARCHITECTURE.md` - layers, data flow, how to swap mocks for Firebase
- `docs/DEMO_SCRIPT.md` - the 15-step acceptance checklist from SRS section 11
