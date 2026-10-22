# Design conventions

ZutLib is a working tool for students and library staff at a technical college. It should
feel like a well-kept library: calm, orderly, fast to scan. These rules apply to every screen.
They implement SRS section 8 and NFR-05/NFR-06.

## Principles

1. **Content first.** The paper list, the loan, the question. Chrome stays quiet.
2. **One primary action per screen.** It is a `FilledButton`. Everything else is
   `OutlinedButton`, `TextButton` or an icon button.
3. **Say what happened and what to do next.** Every empty state, error and success message.
4. **Same thing, same look.** A loan status always renders through `StatusChip`. A course
   code always renders in the mono style. Do not invent a variant for one screen.

## Navigation (SRS section 8)

- Students: `NavigationBar` with five destinations: Home, Search, Study, Loans, Profile.
- Staff (librarian, institution admin, platform admin): `NavigationDrawer` plus an app bar.
- Back always goes back. No dead ends: every leaf screen has an obvious way out.

## Layout and spacing

- 4 dp grid. Allowed spacing values: 4, 8, 12, 16, 24, 32. Use `Gap` constants in
  `lib/core/theme.dart` (`Space.s`, `Space.m`, ...), not raw numbers.
- Screen horizontal padding: 16 dp. Section spacing: 24 dp.
- Lists are `ListTile`-based with dividers or 8 dp gaps; no floating shadowed cards for
  every row. Use `Card` (filled or outlined variant, elevation 0) only to group a block of
  related information, such as the paper metadata panel.
- Tap targets at least 48 x 48 dp (NFR-06).
- Layout must survive 1.3x text scale (NFR-06): no fixed-height containers around text,
  allow wrapping, test with large font in the emulator.

## Typography

- Material 3 type scale only. Do not set font sizes by hand.
- Screen title: `titleLarge` in the app bar. Section headers: `titleSmall`, sentence case.
- Course codes and loan codes: `labelLarge` with `FontFeature.tabularFigures()` via
  `AppText.code`. They are identifiers and should look like identifiers.
- Sentence case everywhere ("Request copy", not "Request Copy"). No all-caps headings except
  the small overline labels already defined in `AppText.overline`.

## Colour

- `ColorScheme.fromSeed` with the tenant's `themeColour` (FR-TEN-04). Never hardcode a hex
  in a widget; take colours from `Theme.of(context).colorScheme`.
- Status colours are semantic and fixed in `StatusChip`: requested = secondary,
  approved = primary, collected = tertiary, overdue/rejected/expired = error,
  returned/cancelled = outline.
- Text contrast at least 4.5:1 (NFR-06). Do not put body text on `primaryContainer` with
  reduced opacity.
- Support dark mode through the scheme. No widget may assume a light background.

## Components

| Need | Use |
| --- | --- |
| Primary action | `FilledButton` |
| Secondary action | `OutlinedButton` / `TextButton` |
| Filters | `FilterChip` in a horizontally scrolling row; applied filters as `InputChip` with delete |
| Status | `StatusChip` (shared widget) |
| Empty list | `EmptyState` (shared widget): icon, one sentence, one action |
| Transient result | `SnackBar` with a plain sentence; undo where possible |
| Field error | `InputDecoration.errorText` next to the field (FR-RES-02) |
| Destructive confirm | `AlertDialog` with the verb on the button ("Archive", not "OK") |
| Loading | `LinearProgressIndicator` at top of content, not a centred spinner for fast ops |

## Copy

- Plain, specific language. "Incorrect email or password" (FR-AUTH-01).
- Use the user's words: "paper", "copy", "loan", "due date". Not "asset", "item", "entity".
- Buttons are verbs: "Request copy", "Approve", "Mark returned".
- Numbers and dates: `22 Oct 2026`, `14:00`. Relative times only under a week ("in 2 days").
- Errors say what went wrong and how to fix it: "You already have 3 active loans. Return
  one to request another."
- No exclamation marks, no emoji in UI copy.

## Icons and imagery

- Material Symbols (outlined) only. One icon per meaning across the app
  (e.g. `Icons.menu_book_outlined` = paper, `Icons.qr_code_2` = collection code).
- No stock illustrations or decorative blobs. Empty states use a single icon.
- Tenant logo placeholder: tenant short code in a rounded square on the tenant colour.

## Motion

- Default Material transitions. No custom page animations, bounces or parallax.
- Animate only to explain a change (a card leaving a queue after approval).

## Accessibility checklist per screen

- [ ] Every icon button has a `tooltip`
- [ ] Images and the QR code have a `semanticLabel`
- [ ] Works with TalkBack focus order top to bottom
- [ ] Readable at 1.3x font scale
- [ ] Contrast 4.5:1 for text
