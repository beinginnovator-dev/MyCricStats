# MyCricStats Flutter — Master Change Register

This register is the source of truth for requested behaviour on the Flutter branch `testing/google-mix-ui`. Before every future edit or deployment, compare the branch against this list. Do not remove, move, rename, or change an existing feature unless the user explicitly requests it. After each change, verify each affected item in source/build/live deployment and update its status here.

## Preserve existing behaviour (regression checks)
- [ ] Re-toss / Correct Toss remains available in the pre-match Ready state; do not remove it.
- [ ] Active match, innings, ball-by-ball state and scoring data restore after minimising/reopening the app.
- [ ] Reopen the last viewed page/tab.
- [ ] Scoring pad keeps its existing layout and button actions; extras remain purple.
- [ ] Existing scorer flow, toss gating, opener selection, batter/bowler change rules, undo/redo, innings transition and match completion remain intact.
- [ ] Match history and cumulative statistics remain intact.
- [ ] Existing scoreboard, live commentary, player stats, 50/100 milestones, boundary/wicket animations and result banner remain intact.
- [ ] Do not modify the original HTML app, MySportzStats, Expense Tracker, production project, or unrelated branches unless specifically requested.

## Sponsors and advertisements
- [ ] Live page renders every sponsor configured in the scorer (not only the first sponsor).
- [ ] Each sponsor has name, logo/image URL, click-through URL and selectable animation: None, Breathing, Pulse, Glow, Shine.
- [ ] Sponsor animation settings are published with the live payload and applied on the live page.
- [ ] Pop-up ad editor supports duration choices of 3, 5, 6 and 8 seconds.
- [ ] Pop-up ad editor supports Small, Medium and Large size.
- [ ] Pop-up ad editor supports event triggers: boundaries (4/6), wickets and end of each over.
- [ ] Event animation appears first; the selected pop-up appears only after the event animation.
- [ ] Pop-ups auto-close after the selected duration.
- [ ] Existing advertisement enable/disable setting is respected.

## Live page match selection
- [ ] Remove the old-match tab/list/sequence from the live page.
- [ ] Show only matches updated on the current day when selecting the live display.
- [ ] Automatically show the latest live match of the day as soon as it starts; otherwise show the latest updated match for that day.
- [ ] Continue refreshing the selected match score without requiring a manual reload.
- [ ] Keep the live scoreboard, stats, commentary, squads, match info and result presentation.

## Release verification
- [ ] Flutter web build completes successfully.
- [ ] Cloudflare Pages build and deploy stages both report success.
- [ ] Confirm the deployed commit SHA and test URL.
- [ ] Verify the live page and scorer page load from the deployed artifact.
- [ ] Report any behaviour that could not be device-tested; do not claim it is verified when only source/build checks passed.

## Change log
- 2026-11-20: Added sponsor animation controls, pop-up ad size/duration/event-trigger controls, multi-sponsor live rendering, event-first pop-up flow, latest same-day live-match selection, and removed the old match sequence from the live page. Re-toss code intentionally preserved.

## Live viewer updates — 2026-11-20
- [x] Remove static advertisement card from every live viewer tab.
- [x] Disable pop-up advertisement rendering on the live viewer; scorer-side ad configuration remains stored and editable.
- [x] Rotate sponsor presentation one sponsor at a time at 3-second intervals.
- [x] Expand Match Info with match format, venue, toss, innings score, run rate, target and result.
- [x] Expand Squad presentation with player role and current batting/bowling figures.
- [x] Expand commentary using recorded delivery type, dismissal/fielder, batter figures, bowler figures and innings state; no unsupported shot descriptions are fabricated.
- [x] Add a same-day Match History tab, with match selection loading that match's scoreboard, stats, commentary, info and squads.
- [x] Live match directory now exposes the match's created/completed date separately from last update time.
- [ ] Verify the final Cloudflare test deployment and test multi-match navigation on a device.


## Live viewer upgrades — 2026-11-20
- [x] Overlay the completed-match result banner over the scoreboard with an animated sky-shot gradient.
- [x] Display each team flag beside its team name.
- [x] Display striker, non-striker and bowler as three full-width rows with live figures.
- [x] Automatically switch the unpinned live viewer to the newest live match when a new match starts.
- [x] Read squad figures from the live player-stat payload, with squad roster values as fallback.
- [x] Show each commentary delivery with an event badge (W, 4, 6, 0, extras) and over.ball stamp.
- [x] Retain TTS commentary and add toggleable stadium-style sound effects for boundaries, wickets and the start of an over; over-start sound is deliberately low-volume/low-frequency.
- [x] Trigger configured pop-up ads for their selected boundary, wicket or over-end events after the event animation; retain selected size and duration and omit static ad cards from tabs.
- [x] Add Red, Black and Blue viewer theme settings, sound on/off and share-link controls.
- [ ] Verify source syntax, Cloudflare build/deployment, event trigger timing and multi-match switching on a device.
- Note: stadium-style effects are generated locally with Web Audio (not external stadium audio recordings); browser audio requires a user gesture to unlock.


## Live viewer and scorer sponsor/schedule updates — 2026-11-20
- [x] Reduce live scoreboard top spacing and move sound/share/settings controls to the scoreboard's top-left corner.
- [x] Add scorer sponsor size control for +1 pt through +5 pt and publish the selected size to the viewer.
- [x] Add optional scoreboard background image URL and opacity controls in Sponsor Management; publish the settings to the viewer.
- [x] Show striker and non-striker runs, balls, strike rate, boundaries and batter-specific dot-ball counts.
- [x] Show bowler extras split into wides, no-balls and byes, plus total extras.
- [x] Pin a manually selected History match so periodic refresh does not switch back to the newest match.
- [x] Add fixture match name, venue, optional sponsor name/logo and show these fields in scorer and viewer schedule lists.
- [x] Add optional top and bottom caption text for popup advertisements and apply a thin translucent white border on a dark translucent popup.
- [x] Extend event animation to five seconds, reduce its display size, and delay configured popup display until the animation ends.
- [x] Improve TTS voice configuration and unlock stadium audio from the sound toggle user gesture.
- [ ] Run Flutter analyzer/build, verify Cloudflare test deployment, and device-test history navigation, audio, sponsor background/size, fixture display and popup timing.
- Note: browser TTS and Web Audio still require the viewer to be opened and enabled through a user gesture; device/browser permissions can affect playback.
