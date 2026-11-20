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


## Live viewer refinement — 2026-11-20
- [x] Replace text-labelled Sound, Share and Settings controls with compact transparent icon-only buttons at the top of the scoreboard.
- [x] Place batter/bowler stats inline beside each player name with role icons; remove Striker, Non-striker and Bowler text labels.
- [x] Keep regular ball-by-ball commentary concise; include batter strike rate only on boundaries and bowler economy only on wickets.
- [x] Add English/Hindi commentary language selection in viewer settings and use the selected speech locale for TTS.
- [x] Restyle popup advertisements with sponsor/company name centered above the centered image and a single X close control.
- [x] Expand the result banner to cover the scoreboard, include both team flags and names, animate a sky-style gradient, and show one Save & Start New Match action.
- [x] Change scorer Sponsor Management name/logo size choices to 2 pt, 4 pt and 6 pt.
- [x] Add generated crowd-like ambience, whistle-like tones and applause-like sound layers for boundaries, wickets and 50/100 milestones; low-volume ambience at over start.
- [ ] Verify on real mobile browsers: TTS language voice availability, audio unlock/autoplay policy, popup close/timing, result overlay and sponsor sizing.
- Note: stadium effects are synthesized locally with Web Audio; they are not licensed crowd/stadium recordings. Browser autoplay policies require a user gesture (tap Sound) before audio can play reliably. Commentary wording is original broadcast-style writing, not copied from Cricbuzz/ESPNcricinfo.


## Live viewer refinements — 2026-11-20 (requested follow-up)
- [x] Bowler stats remain inline by the bowler name; non-striker uses a stumps-like cricket icon and bowler a red-ball icon.
- [x] Increase scoreboard stats typography by 2 pt and player names by 1 pt.
- [x] Default TTS commentary and stadium sound to enabled; remove standalone TTS button and move both controls into Settings.
- [x] Keep Settings and Share icons at top-left; show tournament name below controls; label schedule KNOCKOUT MATCH.
- [x] Improve praise for boundaries and dot balls in commentary.
- [ ] Add over summaries with over runs and bowler stamp; verify audio/autoplay on mobile.
- Note: browser autoplay restrictions may require a user gesture before audio playback.


## Viewer and scoreboard refinements — 2026-11-20 (requested follow-up)
- [x] Replace non-striker glyph with a detailed three-stump and bails icon; replace bowler red dot with a red leather ball and white seam.
- [x] Show bowler extras as one total only, without wide/no-ball/bye breakdown in brackets.
- [x] Increase scorer scoreboard player-name and player-figures font sizes by 2 pt; increase matching viewer player-name and inline-stat text by 2 pt.
- [x] Remove the Start New Match action from the viewer result banner; add a cup logo, winning team and margin line, innings overs, and Man of the Match line.


## Scoreboard, commentary and finish-status refinement — 2026-11-20
- [x] Reduce the non-striker palette icon size and increase all scorer scoreboard player-name text by 1 pt.
- [x] Improve Hindi/English ball-by-ball commentary using a factual sequence: over.ball, bowler to batter, delivery outcome, fielding/dismissal context where available, and score after the delivery. Use original wording rather than copying ESPNcricinfo text.
- [x] Hide the viewer result overlay for completed/history matches; show a flashing Finished/Abandoned result line in the tournament-title position, including winning margin and overs where score data supports it.
- [x] Set scorer and viewer default scoreboard theme to Black.

- [x] Abandoned matches remain on the scorer scoreboard with an animated Abandoned status and reason, and publish that state to the viewer.
- [x] Reset any old viewer theme preference to Black on load so existing devices also open with the requested default.
