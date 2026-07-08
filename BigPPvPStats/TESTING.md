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

## 6. Testing guild rivalry milestones specifically

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

For example, to walk up to the first tier against a made-up rival:

```
/bpp registerguildkill The Red Empire 10
```

This should pop a toast immediately (progress is recalculated after every
registered kill). Run it again at a higher count (e.g. `100`) to also see the
guild-chat callout fire (only guilded characters, and only tier 100+). Run it
once at a high count (e.g. `500`) to jump straight to the top and confirm the
whole chain of tiers fires in order without duplicates. Try a second,
different guild name too, to confirm each guild tracks independently.

Then check the aggregate view - `/bpp rivals`, or the "Show Rivals" button in
the Statistics window's button row (alongside Show Settings/Achievements/Kill
History/Kill Streak/Leaderboard). This sums `topGuildKills` (each
contributor's own top 10 rival guilds) across yourself, your alts, and anyone
else's broadcast data you've received - `/bpp sync` first if you want to pull
in a guildmate's data on demand.

`/bpp rivals digest`, or the "This Week" button inside the Most Hated Guilds
window, shows a summary of rival-guild kills from the last 7 days, computed
from raw kill history (this also fires automatically at most once per real
week, on login).

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
sound - separate from the rivalry milestone popup so the two can't cut each
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
seen. Entries drop off automatically 10 minutes after they're last seen.

Right-click any name for a menu to add/remove Kill On Sight, toggle Ignore,
or remove it from the panel. Names show red if they're KOS'd, gray if
ignored, otherwise colored by class. Hover a name for level/guild/class and
last-seen time.

## 9. Testing guild-wide Kill On Sight sharing

Your own KOS player/guild lists (capped to the most recently added 25 of
each) broadcast alongside your other stats, the same way `topGuildKills`
does for the rivalry board. Anyone else running the addon - guildmate, group
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

To test the Stealth alert specifically: have a rogue or druid (an alt, or a
nearby real one) go into Stealth/Prowl within combat-log range of you. You
should get a small purple-bordered popup and a short sound - this fires from
the combat log directly, so it works even if you never target or mouse over
them. It respects your Ignore list and the "Alert when a rogue/druid
stealths nearby" checkbox in Settings.

## 11. Undo the test data

Once you're done poking at it:

```
/bpp restore 1
```

or, for a guaranteed-clean state, paste back the `/bpp export` blob you saved in
step 4 via `/bpp import`. Either way, follow up with `/reload` so any open
windows (achievements, statistics, leaderboard) refresh against the restored
data.

## 12. How guild rivalry tracking works

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
- The "Most Hated Guilds" board (`/bpp rivals`) aggregates from a bounded top
  10 rival guilds per contributor (broadcast in `topGuildKills`), so the
  network payload and the board itself stay a fixed size no matter how many
  total guilds exist
- Browsing your own full per-guild kill history (not just the top 10) is
  already covered by the existing "Kills by Guild" table in `/bpp stats`
