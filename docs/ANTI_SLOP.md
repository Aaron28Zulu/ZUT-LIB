# Anti-slop rules

"Slop" is the generic, over-decorated, low-information look and wording that generated
code and copy fall into by default. A panel of lecturers will notice it. Every PR touching
UI or copy is checked against this list. If a rule blocks something genuinely needed, say
why in the PR.

## Visual

1. **No gradient backgrounds** on screens, app bars, buttons or cards. Flat tonal surfaces only.
2. **No glassmorphism**, frosted blur, neon glow or coloured drop shadows.
3. **No card-per-row lists.** Rows are list tiles. Cards group information, they are not wallpaper.
4. **No hero banners** with a giant greeting ("Welcome back, Chanda!") taking half the screen.
   One line of context at most, then content.
5. **No decorative icons** beside every heading or inside every button. An icon must add meaning.
6. **No emoji** in UI, copy, commit messages or docs headings.
7. **No rainbow palettes.** Colour comes from the tenant seed and the fixed status semantics.
8. **No oversized corner radii** everywhere. Use the Material 3 defaults.
9. **No fake data visualisations.** A chart appears only when it plots real stored data.
10. **No centred spinners** for operations that take under 300 ms; the mock services are instant.
11. **No placeholder lorem ipsum** or "Coming soon" screens shipped in a build. Hide unbuilt features.
12. **No stat tiles for numbers nobody acts on.** Each dashboard figure must answer a question
    a librarian or administrator actually asks (SRS FR-ADM-03 lists them).

## Copy

13. **No hype words:** "seamless", "effortless", "powerful", "revolutionary", "unlock",
    "supercharge", "elevate", "journey", "dive in", "game-changer", "cutting-edge".
14. **No AI framing in the UI.** The study assistant is rule-based; call features what they do
    ("Practice quiz", "Revision plan"). Never say "AI-powered" or "magic".
15. **No filler sentences** ("Here you can find all your papers in one place."). The screen
    title already says it.
16. **No exclamation marks** in success messages. "Request sent. The librarian will review it."
17. **No vague errors** ("Something went wrong"). Say what failed and what to do.
18. **No title case on buttons** and no ALL CAPS shouting.
19. **No cheerful empty states** ("Nothing here yet! 🎉"). State the fact and the next action:
    "No saved papers. Tap the bookmark on a paper to save it."

## Code

20. **No comments that restate the code** (`// increment i`). Comment the why, or the
    requirement ID that forces the behaviour.
21. **No god widgets.** A screen file over ~300 lines gets split into private widgets.
22. **No speculative abstractions.** One implementation behind an interface is fine because
    the SRS requires the seam (NFR-11); a factory-of-factories is not.
23. **No dead code, unused imports, commented-out blocks or `print` calls** in a commit.
24. **No magic numbers** for rules: loan limits, durations and thresholds live in
    `lib/core/rules.dart` with the requirement ID beside them.
25. **No swallowed errors** (`catch (_) {}`). Show the user a message or rethrow.
26. **No generated boilerplate docs** (README sections nobody needs, badge walls, "Features ✨").

## Quick self-review

Before pushing, look at each changed screen at 1x and 1.3x text, light and dark, and ask:
would a librarian at ZUT understand every word, and is anything on screen only decoration?
