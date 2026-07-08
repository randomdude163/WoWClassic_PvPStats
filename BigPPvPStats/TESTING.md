# Testing Guide

This addon writes almost nothing to the screen without a real kill happening, so
testing relies on a set of debug slash commands that fabricate fake kills/deaths
against your **live** character data. This guide covers how to turn that on, how
to drive it, and how to undo it afterward so your real stats stay clean.

## 1. Install alongside the original addon

Both addons can be enabled at the same time - just drop the `BigPPvPStats` folder
into `Interface\AddOns\` next to (not replacing) the original `PvPStatsClassic`
folder. They no longer share any global names or a SavedVariables file, so they
won't interfere with each other. `/bpp` talks to this addon; `/psc` still talks
to the original.

## 2. Where your data lives

Everything is in one SavedVariables table, `BPP_DB`, written to disk on
logout/reload at:

```
WTF\Account\<YourAccount>\SavedVariables\BigPPvPStats.lua
```

It's account-wide - all characters share this one file, partitioned internally
by `Realm-CharacterName`.

## 3. Turn on debug/test commands

```
/bpp toggledebug
```

Run it again to turn debug mode back off. Type `/bpp` with no arguments any time
to see the full command list for your current mode.

## 4. Back up before you start testing

Test commands write into the same tables your real kills use, so back up first:

```
/bpp export
```

This opens a text box with a full copy of your current character's kill and
achievement data, pre-selected - copy it (Ctrl+C) and paste it into a text file
somewhere safe. If a test run goes wrong, `/bpp import` pastes it back.

There's also an automatic safety net: the addon snapshots your data internally
(inside the same SavedVariables file) once per real day on logout. List/restore
those with:

```
/bpp backups
/bpp restore [number]      -- 1 = most recent, defaults to 1
```

`/bpp export` is the only one of these that survives losing the SavedVariables
file itself, since it's the only one that leaves the file. `/bpp restore` is
faster for "I just broke something 5 minutes ago."

## 5. Generate test kills

```
/bpp registerkill [count]              -- random players, random guild
/bpp registerlevel1kill [count]        -- random level-1 players (spawn-camp style)
/bpp registernpckill <NPC name>        -- one of the tracked world-boss NPCs
/bpp registerstreakkill [days] [killsPerDay] [daysAgo]
/bpp simulatedeath [killers] [assists] -- simulate yourself dying
```

These feed the exact same code path as a real kill, so kill-streak popups,
milestone popups, announce messages, and achievement unlocks all fire normally.

## 6. Testing guild trash milestones specifically

Milestones (10/25/50/75/100/200/300/400/500 kills against a single guild) are
tracked automatically for *any* guild you fight - there's no name list to
maintain, and they're not achievements (no Achievement Frame entry, no
points) - just a highlight popup, plus a guild-chat callout for the bigger
tiers (100+). The random guild pool used by `/bpp registerkill` picks from a
small set of fake test guild names, so to test a specific one, use the
dedicated command instead:

```
/bpp registerguildkill <guild name> [count]
```

For example, to walk up to the first tier against a made-up target:

```
/bpp registerguildkill The Red Empire 10
```

This should pop a toast immediately (progress is recalculated after every
registered kill). Run it again at a higher count (e.g. `100`) to also see the
guild-chat callout fire (only guilded characters, and only tier 100+). Run it
once at a high count (e.g. `500`) to jump straight to the top and confirm the
whole chain of tiers fires in order without duplicates. Try a second,
different guild name too, to confirm each guild tracks independently.

Then check the aggregate view - `/bpp trash`, or the "Show Trash" button in
the Statistics window's button row (alongside Show Settings/Achievements/Kill
History/Kill Streak/Leaderboard). This sums `topGuildKills` (each
contributor's own top 10 trashed guilds) across yourself, your alts, and anyone
else's broadcast data you've received - `/bpp sync` first if you want to pull
in a guildmate's data on demand.

`/bpp trash digest` shows a summary of trashed-guild kills from the last 7
days as a popup, computed from raw kill history (this also fires
automatically at most once per real week, on login). The "This Week" button
inside the Most Hated Guilds window is different - it swaps that window's
own list between the combined all-time board and your personal past-7-days
view in place (button label flips to "All Time" to switch back), rather
than opening a separate popup. Click it a couple of times to confirm the
list content and button label both update with no extra popup appearing.

## 7. Testing the Kill On Sight list

The Kill On Sight (KOS) list doesn't need any fake kills - it fires off the
same target/mouseover/nameplate detection this addon already uses to resolve
player names and guilds, so you can test it against any real player nearby
(a guildmate on an alt, someone in a starting zone, etc.) - just not yourself.

```
/bpp kos                                        -- opens the KOS list window
/bpp kos add <name> [reason]                    -- add a player, e.g. /bpp kos add Somename ganked me at the lake
/bpp kos remove <name>
/bpp kos guild add <guild name> [- reason]      -- e.g. /bpp kos guild add The Red Empire - wiped our raid
/bpp kos guild remove <guild name>
```

To see the alert fire, add a real nearby player's exact name (or their exact
guild name) to the list, then target them, mouse over them, or let their
nameplate appear. You should get a red popup with a distinct "raid warning"
sound - separate from the trash milestone popup so the two can't cut each
other off. A named match takes priority over a guild match. Alerts are
deduped per player with a 60-second cooldown, so hovering back and forth
over the same target won't spam it.

Player and guild watchlists are account-wide (like PlayerInfoCache), not
per-character, and are not included in `/bpp export` - only your kill and
achievement data travels in that backup.

```
/bpp kos ignore <name>      -- suppress alerts for a player (personal and guild-aggregated)
/bpp kos unignore <name>
```

## 8. Testing the Nearby Enemies panel

```
/bpp nearby      -- toggle the panel on/off
```

Shown by default on login (drag it to reposition - the spot is remembered).
It lists every hostile player detected via the same target/mouseover/nameplate
hooks as the KOS list, sorted with KOS matches first, then most recently
seen. Nameplates alone (never having moused over or targeted that player)
should now be enough to detect them - previously this silently didn't work
until the first manual hover/target, because the addon's own player-info
lookup errored out on class/race data a fresh nameplate doesn't have cached
yet. To test: walk near hostile players without touching your mouse over any
of them and confirm they show up anyway.

Also test that using the addon at all (hovering/targeting enemies, letting
the panel auto-show) never locks up your keyboard or mouse in the game
world - this was a real, serious bug (the panel was mistakenly grabbing all
keyboard input into itself every time it was shown) that's now fixed. If
you ever do lose input again, that's a regression worth reporting
immediately, not something to work around with a relog.

Right-click any name for a menu to add/remove Kill On Sight, toggle Ignore,
or remove it from the panel. Rows are colored by class (red for KOS, gray
for ignored). Hover a name for level/guild/class, last-seen time, and
win/loss record.

The window itself is transparent apart from the title strip, so it doesn't
block your view. There's no scrollbar - it grows and shrinks vertically to
fit its rows automatically, up to 20 shown at once. Drag the right edge to
resize the width. Use the arrows in the title bar to cycle between four
views in the same window:

- **Nearby** - entries seen within the configurable window from Settings >
  Kill On Sight (5/10/15/30 min, default 10)
- **Last Hour** - the same underlying data, but showing everything seen in
  the last hour regardless of that shorter window
- **Kill On Sight** - your personal watchlist
- **Ignored** - players with alerts suppressed

Only the Nearby/Last Hour views expire entries at all (after a full hour,
hard cap); Kill On Sight and Ignored persist until you remove them.

## 9. Testing guild-wide Kill On Sight sharing

Your own KOS player/guild lists (capped to the most recently added 25 of
each) broadcast alongside your other stats, the same way `topGuildKills`
does for the trash board. Anyone else running the addon - guildmate, group
member, or alt - who receives that broadcast will also get alerted on your
watchlist entries, even if they never added them personally, and vice versa.

To test it: have a second character (an alt, or someone else's client)
add a player or guild to their KOS list, then `/bpp sync` on your main to
pull their broadcast in. Open `/bpp kos` - entries you didn't add yourself
should show up under "Guild KOS - Players" / "Guild KOS - Guilds" with a
"Reported by ..." tooltip, and detecting that player/guild should now alert
you too. Click "Add to my list" on one to adopt it into your own personal
list (optional - detection already covers it either way).

## 10. Testing the Kill On Sight settings tab and Stealth alert

`/bpp settings` (or the "Show Settings" button in Statistics) now has a
"Kill On Sight" tab covering everything above by checkbox/dropdown instead
of only slash commands: enable/disable alerts, alert sound, stealth alerts,
guild sharing (both broadcasting your list and receiving guildmates'),
Nearby panel show-on-login, class colors, and how long entries stay listed
before dropping off (5/10/15/30 minutes). All default to on/10-minutes, so
nothing changes for existing users until they touch it.

The Settings window is a fixed, screen-friendly size now - each tab scrolls
internally (mouse wheel, or drag the scrollbar) if its content runs longer
than the visible area, instead of the window itself growing every time a
new section gets added. Open the Kill On Sight tab (the tallest one) and
confirm the window fits comfortably on screen with nothing clipped off the
bottom, and that scrolling down reaches every control, all the way to the
"Test Alert Sound"/"Import from Spy" buttons at the very end.

To test the Stealth alert specifically: have a rogue or druid (an alt, or a
nearby real one) go into Stealth/Prowl within combat-log range of you. You
should get a small, mostly see-through popup (matching Spy's own alert
style - a small ability icon, "Stealth player detected!", and the name
below, not a large opaque box) and a short sound - this fires from the
combat log directly, so it works even if you never target or mouse over
them. A druid going Prowl should show a different icon (a dagger-strike
icon) than a rogue going Stealth. It respects your Ignore list and the
"Alert when a rogue/druid stealths nearby" checkbox in Settings.

## 11. Testing the minimap icon, auto-show, and zone exclusions

The minimap icon now has two more bindings (hover it to see the full list):

```
Shift+Right-Click   -- opens the Kill On Sight list
Alt+Right-Click     -- toggles the Nearby Enemies panel
```

Auto-show: close the Nearby panel (the X button, or `/bpp nearby`), then get
a real or simulated kill/detection against any nearby hostile player - the
panel should reopen on its own. Toggle it off via the "Auto-show panel when
an enemy is detected" checkbox in Settings > Kill On Sight to confirm it
stays closed instead.

Zone exclusions - two ways to test:

```
/bpp zone disable [zone name]   -- omit the name to disable your current zone
/bpp zone enable [zone name]
/bpp zone list
```

or check one of the per-zone boxes under "Disabled Zones" in Settings > Kill
On Sight (Booty Bay, Everlook, Gadgetzan, Ratchet, The Salty Sailor Tavern,
Cenarion Hold, Shattrath City, Area 52 - the neutral hubs both factions use,
matching Spy's own list; racial capitals aren't included since the opposing
faction can't normally enter them anyway), then travel there. Either way,
once in a disabled zone, Kill On Sight alerts, Stealth alerts,
and the Nearby panel should all go quiet - the Nearby panel simply won't
pick up new entries while you're there, even ones you'd normally be
watchlisted for.

## 12. Testing click-to-target, PvP scope, live sharing, and purge

Click a name in the Nearby panel (left-click) to target that player directly
- like every other secure click-to-target in WoW, this only works outside
combat lockdown, so it won't do anything mid-fight until the panel
refreshes again after combat ends.

PvP scope toggles (Settings > Kill On Sight > PvP Scope) - test by entering
a battleground/arena with the matching toggle on, and confirm detection
goes quiet; toggle "Disable detection while not PvP flagged" and confirm
detection stops as soon as you're not flagged (auto-flags off in most PvE
zones), and resumes once you flag up. Dungeons and raids are always
excluded regardless of any toggle (there's nothing to detect there) - queue
into one and confirm detection goes quiet with no setting involved.

Kill On Sight and Stealth alerts now play the identical sound (previously
two different ones) and the KOS popup now clears itself after ~4 seconds
total instead of lingering for 9 - `/bpp kos testsound` is the fastest way
to check both without waiting on a real detection.

Import from Spy - with Spy installed and loaded on the same character (see
section 1), add a player or two to Spy's own Kill On Sight/Ignore lists,
then use "Import from Spy" in Settings > Kill On Sight (or
`/bpp kos importspy`). Open `/bpp kos` afterward - the imported players
should show up with any reason Spy had stored for them carried over.
Running it again should report 0 newly imported (everything already on
your list), not duplicates.

The Nearby view's fall-off dropdown now has Spy's full six options (1/2/5/
10/15 minutes, Never) instead of just four. "Never" is the one to watch
closely - unlike the timed options, it also skips the panel's old 1-hour
hard cap, so an entry set that way should still be there after waiting over
an hour, not just within the shorter Nearby window.

Live sighting sharing - have a second character (an alt or a guildmate)
detect a new hostile player; if "Share live sightings with guild/party" is
on for both of you, it should show up in your own Nearby panel within a few
seconds, without you having seen them yourself.

Data retention - set "Auto-remove Kill On Sight/Ignore entries not seen in"
to 30 days, add a KOS entry, then manually backdate it for testing via
`/run BPP_DB.KOSPlayers["Name-Realm"].lastSeen = time() - 40*86400` and
`/reload` - it should be gone after the purge runs on login.

`/bpp kos testsound`, or "Test Alert Sound" in Settings, fires the Kill On
Sight popup and sound directly - use this first if sound seems broken, to
rule out "detection never fired" vs. "the sound itself didn't play."

Kill On Sight, Stealth, and new-nearby-sighting alerts each play one of
Spy's own bundled sounds now (sounds/Spy/detected-kos.mp3, detected-
stealth.mp3, detected-nearby.mp3) instead of a Blizzard stock sound - all
three should sound distinct from each other. Detect a brand new hostile
player (not on your Kill On Sight or Ignore list) to hear detected-nearby.mp3
fire once; detecting them again shouldn't replay it. Toggle "Play a sound
for new nearby sightings" off in Settings to confirm it goes quiet while
Kill On Sight/Stealth sounds keep working. Add that same player to your Kill
On Sight list first and detect them again - only the KOS sound should play,
not both at once.

## 13. Undo the test data

Once you're done poking at it:

```
/bpp restore 1
```

or, for a guaranteed-clean state, paste back the `/bpp export` blob you saved in
step 4 via `/bpp import`. Either way, follow up with `/reload` so any open
windows (achievements, statistics, leaderboard) refresh against the restored
data.

## 14. How guild trash tracking works

There's nothing to configure - every guild you kill a member of is tracked
automatically against a 9-tier ladder (10/25/50/75/100/200/300/400/500). See
`GuildRivalry.lua`. Guild name matching is exact (spelling and capitalization,
as reported by the game), so two guilds with near-identical names are tracked
separately.

This is deliberately *not* built as an achievement system - a fixed
per-guild-per-tier achievement list doesn't scale if your roster ends up
fighting hundreds of guilds over time (every tile in the Achievement Frame is
a fresh `CreateFrame()` call on every refresh, with no pooling). Instead:

- Only a single number is persisted per guild (the highest tier already
  announced), not a full record per tier
- Milestones show a lightweight popup, not an Achievement Frame entry, and
  don't add achievement points
- The "Most Hated Guilds" board (`/bpp trash`) aggregates from a bounded top
  10 trashed guilds per contributor (broadcast in `topGuildKills`), so the
  network payload and the board itself stay a fixed size no matter how many
  total guilds exist
- Browsing your own full per-guild kill history (not just the top 10) is
  already covered by the existing "Kills by Guild" table in `/bpp stats`
