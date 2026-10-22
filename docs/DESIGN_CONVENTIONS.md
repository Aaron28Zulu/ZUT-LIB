# Design conventions

ZutLib is a working tool for students and library staff at a technical college. It should
feel like a well-kept library: calm, orderly, fast to scan. The layout borrows the patterns
students already know from course platforms (Coursera, Udemy, edX, Khan Academy): a greeting
with "continue where you left off", shelves of recommendations, course-listing rows with a
thumbnail, progress bars, and a header band on the detail page. These rules apply to every screen.
They implement SRS section 8 and NFR-05/NFR-06.

## Principles

1. **Content first.** The paper list, the loan, the question. Chrome stays quiet.
2. **One primary action per screen.** It is a `FilledButton`. Everything else is
   `OutlinedButton`, `TextButton` or an icon button.
3. **Say what happened and what to do next.** Every empty state, error and success message.
4. **Same thing, same look.** A loan status always renders through `StatusChip`. A course
   code always renders in the mono style. Do not invent a variant for one screen.

## Navigation and breakpoints (SRS section 8)

- Students: five destinations, Home, Search, Study, Loans, Profile. `NavigationBar` under
  600 dp wide, `NavigationRail` from 600 dp, extended rail from 1000 dp.
- Staff (librarian, institution admin, platform admin): `NavigationDrawer` plus an app bar
  under 1000 dp, a permanent side menu from 1000 dp.
- Content is held to a readable width of 760 dp with `Readable` and centred on wide screens.
- Breakpoints live in `Breakpoints` in `lib/core/theme.dart`.
- Back always goes back. No dead ends: every leaf screen has an obvious way out.

## Layout and spacing

- 4 dp grid. Allowed spacing values: 4, 8, 12, 16, 24, 32. Use `Gap` constants in
  `lib/core/theme.dart` (`Space.s`, `Space.m`, ...), not raw numbers.
- Screen horizontal padding: 16 dp. Section spacing: 24 dp.
- Flat, not carded. Lists are rows separated by hairline dividers. Use `Panel` (a 1 dp
  outline, no shadow) only to group a block of related information, such as today's plan.
- Corner radii are small and fixed: 4 dp for tags and thumbnails, 6 dp for controls and
  panels, 8 dp for sheets and dialogs (`Radii`). No pill buttons, no 16 dp+ cards.
- No elevation and no gradients anywhere. Separation comes from whitespace and hairlines.
- A paper in a list is a `ResourceTile`: thumbnail, bold title, muted metadata line, tags.
  On a shelf it is a `ResourceCard`.
- Tap targets at least 48 x 48 dp (NFR-06).
- Layout must survive 1.3x text scale (NFR-06): no fixed-height containers around text,
  allow wrapping, test with large font in the emulator.

## Typography

- Two bundled families: Source Serif 4 for page and section headings (the academic voice),
  Inter for everything else. Both ship in `assets/fonts` with their OFL licences registered
  in `main.dart`. No runtime font downloads.
- Material 3 type scale only, set once in `lib/core/theme.dart`. Do not set font sizes by hand.
- Screen title: `PageHeader` at the top of the body. Section headers: `SectionHeader`,
  serif, sentence case.
- Course codes and loan codes: `labelLarge` with `FontFeature.tabularFigures()` via
  `AppText.code`. They are identifiers and should look like identifiers.
- Sentence case everywhere ("Request copy", not "Request Copy"). No all-caps headings except
  the small overline labels already defined in `AppText.overline`.

## Colour

- One hand-authored palette for light and dark in `lib/core/theme.dart`: academic blue
  (#0B5CD5) as the only accent, near-black ink, cool greys, white surfaces. No `fromSeed`.
- Never hardcode a hex in a widget; read `Theme.of(context).colorScheme` or `AppPalette.of`.
- The tenant's `themeColour` (FR-TEN-04) appears on `TenantMark` only, so every college keeps
  its identity without changing the app's contrast-checked palette.
- Status colours are semantic (`AppPalette`: success, warning, danger, info) and always come
  with an icon and a word. Colour is never the only signal.
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

- Lucide icons (`lucide_icons_flutter`), always through `AppIcons` in
  `lib/core/app_icons.dart`. One icon per meaning across the app (`AppIcons.paper`,
  `AppIcons.qr`). Add a new name there rather than using `LucideIcons` in a screen.
- Paper thumbnails are flat tinted rectangles with the course code printed on them.
- No stock illustrations or decorative blobs. Empty states use a single icon.
- Tenant logo placeholder: `TenantMark`, the tenant short code on the tenant colour.

## Motion

- Default Material transitions. No custom page animations, bounces or parallax.
- Animate only to explain a change (a card leaving a queue after approval).

## Accessibility checklist per screen

- [ ] Every icon button has a `tooltip`
- [ ] Images and the QR code have a `semanticLabel`
- [ ] Works with TalkBack focus order top to bottom
- [ ] Readable at 1.3x font scale
- [ ] Contrast 4.5:1 for text
