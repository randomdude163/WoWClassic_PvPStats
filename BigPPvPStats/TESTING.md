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

## 6. Testing the per-guild kill milestones specifically

Kill milestones (10/25/50/75/100/200/300/400/500 kills against a single guild)
are generated automatically for *any* guild you fight - there's no name list to
maintain. The random guild pool used by `/bpp registerkill` picks from a small
set of fake test guild names, so to test a specific one, use the dedicated
command instead:

```
/bpp registerguildkill <guild name> [count]
```

For example, to walk up to the first tier against a made-up rival:

```
/bpp registerguildkill The Red Empire 10
```

This should pop "The Red Empire Menace I" immediately (progress is recalculated
after every registered kill) - and the achievement entry itself only appears
the first time you've registered a kill against that guild, since it's created
on the fly rather than pre-declared. Repeat with higher counts to walk through
the other tiers, or run it once at a high count (e.g. `500`) to jump straight to
the top tier and confirm the whole chain unlocks in order. Try a second,
different guild name too, to confirm each guild tracks independently.

Open `/bpp achievements` and the "Kills" tab to watch progress bars update live
without needing to close/reopen the window.

## 7. Undo the test data

Once you're done poking at it:

```
/bpp restore 1
```

or, for a guaranteed-clean state, paste back the `/bpp export` blob you saved in
step 4 via `/bpp import`. Either way, follow up with `/reload` so any open
windows (achievements, statistics, leaderboard) refresh against the restored
data.

## 8. How the per-guild kill milestones work

There's nothing to configure - every guild you kill a member of automatically
gets its own 9-tier ladder (10/25/50/75/100/200/300/400/500), generated the
first time `stats.guildData` shows a kill against a name it hasn't seen before
(see `GuildKillMilestones.lua`). Guild name matching is exact (spelling and
capitalization, as reported by the game), so two guilds with near-identical
names are tracked separately. There's no cap on how many guilds can accumulate
milestones - if your roster fights a lot of different enemy guilds over time,
expect the Kills tab to grow accordingly.
