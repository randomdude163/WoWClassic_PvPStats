v1.0.0:
- Version numbering restarts here at 1.0.0 (previously 4.18.0) - this is treated as the fork's own first release rather than a continuation of the original addon's version history
- Renamed "Rivals"/"Rivalry" to "Trash" throughout: `/bpp rivals` is now `/bpp trash`, "Show Rivals" is now "Show Trash", the weekly popup is now "Weekly Trash Report", etc. The "Most Hated Guilds" window title and its milestone popups (already themed around guild kill counts) are unchanged
- Rebuilt the Stealth/Prowl popup to match Spy's own compact AlertWindow instead of a large opaque block: small icon (Ability_Stealth or Ability_Ambush for Prowl) + two short lines over a translucent tooltip-style backdrop, sized to fit the text instead of a fixed 260x50 box, so it no longer blocks the view behind it
- About tab rebrand: removed the "Developed by"/"Customized by" credit lines; Discord/GitHub/Contact/CurseForge fields are all placeholder "TBD" pending real values; added a small attribution line at the bottom crediting the original PvPStatsClassic authors (Severussnipe & Hkfarmer) it's based on
- Fixed the "Most Hated Guilds" window: clicking "This Week" used to pop open a separate floating toast on top of the window instead of updating its contents, which read as broken/redundant. It now toggles the window's own list in place between the combined all-time board and your personal past-7-days view, button label flips between "This Week"/"All Time" to show which view is active. The automatic once-per-week login notification and `/bpp trash digest` still use the toast popup, since neither has a window open to update in place

v4.18.0:
- Replaced the Blizzard stock sounds standing in for Kill On Sight/Stealth with Spy's own actual sound files (detected-kos.mp3, detected-stealth.mp3), bundled directly under sounds/Spy/ - not an approximation anymore
- Added a third sound, also Spy's own: detected-nearby.mp3 plays once the first time a hostile player is detected nearby at all (not just Kill On Sight/Stealth matches), matching Spy's default behavior (OnlySoundKoS=false) - new "Play a sound for new nearby sightings" checkbox in Settings > Kill On Sight controls it, on by default. Automatically skipped for Kill On Sight matches and Ignored players so it never overlaps the KOS or Stealth alert sounds for the same detection
- Corrected course on the KOS/Stealth sound change from the previous version - they're deliberately distinct sounds again (matching Spy's own separate sound files per alert type), not merged into one; the earlier "make them the same" was a misreading of what was actually being asked for (Spy parity, not internal consistency)

v4.17.0:
- Added "Import from Spy": if a co-installed Spy addon is loaded on the current character, a new "Import from Spy" button in Settings > Kill On Sight (and /bpp kos importspy) copies its Kill On Sight and Ignore lists straight in - no copy/paste needed. Existing entries are left alone; imported KOS entries also carry over Spy's stored reason if it had one
- Expanded the Nearby panel's fall-off dropdown from 4 to Spy's exact 6 options: 1/2/5/10/15 minutes and Never (entries persist until removed by hand, matching Spy's "Never" behavior instead of still being capped by the old 1-hour hard limit)
- Rebuilt the PvP scope logic to mirror Spy's actual zone-change branching instead of an approximation: dungeons and raids are now always excluded unconditionally (previously not handled at all), battlegrounds now key off the same instance type Spy checks rather than this addon's own battleground-mode flag, and added a "Disable detection in world PvP zones" toggle for forced-PvP objective zones (off by default, matching Spy's Wintergrasp/Tol Barad handling)
- Fixed the Kill On Sight alert popup lingering far longer than Spy's (was 8s held + 1s fade = 9s total) - now matches Spy's own KOS alert timing exactly (3s held + 1s fade = 4s total)
- Confirmed Stealth/Prowl detection already matches Spy's method exactly (same combat log event, same aura-name match, same hostile-player-source flag check) - no change needed there
- Confirmed the Stealth/Prowl popup's timing already matches Spy's own stealth alert exactly (4s held + 1s fade = 5s total, deliberately longer than the 4s KOS alert - Spy uses different durations per alert type too)
- Fixed: a player detected going into Stealth/Prowl fired the popup but was never added to the Nearby list - stealth is detected purely from the combat log with no unit token to mouse over, so BPP_CheckStealthAlert now also records the sighting (enriched with cached level/class/race/guild if this addon has seen them before) the same way target/mouseover/nameplate detection does

v4.16.0:
- Fixed: Settings > Kill On Sight checkbox labels ran off the edge of the window into the game world - CreateCheckbox never bounded the label's width or enabled word-wrap, so any label longer than the pre-existing short ones (all of the new Kill On Sight checkboxes) overflowed uncontrolled
- Fixed: the Nearby panel's resize grip sat on top of the close button (both anchored to the top-right corner) - moved to the bottom-right corner, which now always sits right below the last row instead of halfway up a tall list
- Added click-to-target on Nearby panel rows: left-click a name to target that player directly (matches Spy; like Spy, this only works outside combat lockdown - WoW blocks addons from binding new secure click targets while you're in combat)
- Replaced the single "Disable in major cities" checkbox with one checkbox per zone, matching Spy's actual preset list - which turned out to be neutral hub towns (Booty Bay, Everlook, Gadgetzan, Ratchet, The Salty Sailor Tavern, Cenarion Hold, Shattrath City, Area 52), not the faction capitals originally guessed at (capitals are sanctuaries the opposing faction can't normally enter, so disabling detection there wouldn't do anything)
- Added PvP scope toggles matching Spy's defaults: disable detection in battlegrounds/arenas (both off by default), in sanctuaries (on by default), and while not PvP-flagged (on by default)
- Added live sighting sharing: when you detect a genuinely new hostile player, it's briefly broadcast to online guild/party members running the addon so it shows up in their Nearby panel too - throttled per-player, one-directional (no echo loops)
- Added a data retention setting: auto-remove Kill On Sight/Ignore entries not seen in 30/60/90 days (off by default), checked once per login
- Made the Kill On Sight and Stealth alert sounds more robust - they used named SOUNDKIT constants that aren't guaranteed to exist on every client version; PlaySound(nil) fails silently if they don't, so both now fall back to a raw numeric sound ID
- Added /bpp kos testsound (and a "Test Alert Sound" button in Settings) to fire the KOS popup+sound directly, bypassing detection entirely - isolates a sound problem from a detection problem when troubleshooting
- Settings window grew taller (690→840) to fit the new sections without any more overlapping text

v4.15.0:
- Added minimap icon bindings: Shift+Right-Click opens the Kill On Sight list, Alt+Right-Click toggles the Nearby Enemies panel
- The Nearby panel now auto-shows itself the moment an enemy is detected if it's currently closed, matching Spy's behavior - controllable via a new "Auto-show panel when an enemy is detected" checkbox in Settings > Kill On Sight (on by default)
- Added zone exclusions: Kill On Sight, Stealth alerts, and the Nearby panel can now be suppressed entirely in specific zones. A "Disable detection in major cities" checkbox in Settings covers the ten capital cities in one click; /bpp zone disable|enable|list [zone name] manages any other zone

v4.14.0:
- Fixed the Nearby panel's resize grip overlapping the close button, causing accidental closes - moved it from the top-right corner to the vertical middle of the right edge
- Added a "Show Nearby List" button next to "Show KOS List" in the Statistics window, so there's a permanent, discoverable way to reopen the panel if it gets closed (previously only `/bpp nearby` or the Settings checkbox)
- Fixed Achievement summary text overlapping the Statistics window's button row - increased the frame height and the clearance between the summary stats box and the buttons below it

v4.13.0:
- Fixed the Kill On Sight list window popping open unexpectedly when adding/removing a player from the Nearby panel's right-click menu - it was never explicitly hidden after creation, so WoW's default "frames are shown when created" behavior made it appear the first time it was built
- Fixed overlapping text in Settings > Kill On Sight - two section headers were anchored at fixed pixel offsets that didn't account for the stealth-alert checkbox added above them
- Fixed a leftover "No enemies detected yet." message staying visible behind newly-detected rows in the Nearby panel - `GetChildren()` only enumerates child frames, not loose text/texture regions, so the empty-state text was never being cleared on refresh
- Switched the Kill On Sight and Stealth alert sounds from guessed numeric sound IDs to Blizzard's named SOUNDKIT constants (RAID_WARNING, READY_CHECK), matching what the rest of the addon already uses reliably
- Added a "Last Hour" view to the Nearby panel's cycling arrows: Nearby entries still drop out of that view after the configurable window (5/10/15/30 min), but stay visible under Last Hour for a full hour
- Removed the Nearby panel's scrollbar - the window now grows and shrinks vertically to fit its rows automatically, capped at 20 displayed per view

v4.12.0:
- Reworked the Nearby Enemies panel to match Spy's look more closely: the window itself is now fully transparent (only a thin title strip has a background), each row is its own small class-colored bar with the name inside it, and it's resizable (drag the bottom-right corner) with the size remembered
- Added left/right arrows in the panel's title bar to cycle between Nearby, Kill On Sight, and Ignored views in the same small window, instead of needing to open separate windows
- Default panel size reduced to take up less screen space

v4.11.0:
- Added a "Kill On Sight" settings tab (ConfigUI.lua): enable/disable alerts, alert sound, stealth alerts, guild sharing (broadcast and/or receive), Nearby panel show-on-login, class colors, and cleanup timer (5/10/15/30 min) - all previously slash-command-only, per user request to prefer GUI configuration where it makes sense
- Added a Stealth/Prowl alert: a small distinct popup (with its own sound and 30s per-player cooldown) when a hostile player is seen going into Stealth or Prowl in the combat log, working even if they're never targeted or moused over. Respects the Ignore list and a new master toggle
- Nearby panel row tooltips now show your win/loss record against that specific player, derived from existing kill history and death-by-killer records rather than a new counter
- All new toggles default to their previous always-on behavior, so this is non-breaking for existing users

v4.10.0:
- Added a Nearby Enemies panel (NearbyList.lua), like the Spy addon's main window: a small movable panel, shown by default, listing every hostile player detected nearby (target/mouseover/nameplate), sorted with Kill On Sight matches first. Right-click any name to add/remove Kill On Sight or toggle Ignore. Toggle the panel with /bpp nearby; position is remembered
- Added a Kill On Sight Ignore list: suppresses alerts for a specific player (personal and guild-aggregated) without affecting the Nearby panel listing - /bpp kos ignore|unignore <name>, or right-click in the Nearby panel
- Added guild-wide Kill On Sight sharing: your own KOS watchlists (bounded to the most recently added entries) broadcast alongside your other stats, and everyone running the addon now also alerts on guildmates' reported players/guilds, not just their own - no shared editable list, just aggregated read-only detection. The Kill On Sight window shows a "Guild KOS" section for entries you haven't personally added, with a one-click "Add to my list" to adopt one
- Fixed the Kill On Sight list window's remove button rendering outside the visible row (a positive offset pushed it past the content frame's right edge instead of inset from it)

v4.9.0:
- Added a Kill On Sight list (KillOnSight.lua), inspired by the Spy addon: watch specific players and/or entire guilds, and get a loud, distinct popup alert the moment one is detected via target/mouseover/nameplate - reuses the same player/guild detection this addon already had for kill tracking, no separate scanning engine needed
- Added /bpp kos, /bpp kos add|remove <name>, /bpp kos guild add|remove <guild name>, and a "Show KOS List" button in the Statistics window's button row
- Alerts are deduped per player with a 60-second cooldown so lingering on a mouseover doesn't spam the popup

v4.8.2:
- Fixed the Most Hated Guilds window (and the export/import windows) not registering with the frame manager, so they could open behind an already-open window (Leaderboard, Statistics, Config) and appear to do nothing when clicked
- Removed the "Most Hated Guilds" button from the Leaderboard window - it's now only in the Statistics window ("Guild-wide..." next to "Kills by Guild")

v4.8.1:
- Fixed the rivalry popup's backdrop not resizing for multi-line content (the weekly digest could spill text below the border)
- Added UI buttons for the guild rivalry features: "Most Hated Guilds" in the Leaderboard window, "Guild-wide..." next to "Kills by Guild" in the Statistics window, and "This Week" inside the Most Hated Guilds window - no longer /bpp-command-only

v4.8.0:
- Replaced the per-guild kill milestone achievement system with lightweight rivalry tracking (GuildRivalry.lua): milestones now show a highlight popup instead of an Achievement Frame entry, so tracking hundreds of rival guilds doesn't bloat the achievement UI or your saved achievement points
- Added a guild-chat callout when a milestone of 100+ kills against a guild is reached
- Added /bpp rivals - a "Most Hated Guilds" board combining kills across every online guild/group member running the addon (each contributes their own top 10 rival guilds, broadcast alongside your other stats)
- Added /bpp rivals digest - a weekly summary of rival guild kills, computed from kill history; also shown automatically at most once per real week on login

v4.7.0:
- Replaced the fixed 10-guild kill milestone list with a dynamic system: every guild you kill a member of gets its own 9-tier ladder (10/25/50/75/100/200/300/400/500) automatically, generated the first time you kill someone from that guild - no name list to maintain
- Renamed remaining "PvP Stats (Classic)" text (settings window, minimap tooltip, leaderboard, What's New popup) to BigPPvP Stats
- Replaced the "[PvPStats]" chat message prefix with "[BigPPvP]" throughout

v4.6.0:
- Renamed the addon to BigPPvPStats (folder, SavedVariables, slash commands, and every internal global) so it can run side-by-side with the original PvPStatsClassic addon without the two clobbering each other's data
- Added rival-guild kill achievements: 9 tiers (10/25/50/75/100/200/300/400/500) per guild in the new BPP_TARGET_GUILDS list (see AchievementDefinitionsClassic.lua)
- Added automatic rolling backups (up to 3, at most one per day) of your kill/achievement data, restorable with /bpp restore
- Added /bpp export and /bpp import for a copy-pasteable text backup that survives outside the SavedVariables file
- Added /bpp registerguildkill debug command to test the new rival-guild achievements without needing to fight that guild
- Fixed /bpp toggledebug, which previously had no handler and was unreachable
- Changed the addon-comm protocol prefix from PVPSC to BPP, so this fork no longer talks to the original PvPStatsClassic addon over the network layer either
- Added /bpp sync to manually request an immediate stats refresh from nearby/guild/group players running the addon

v4.5.1:
- Fixed bug where the K/D of other players was incorrect when you view their detailed stats in the leaderboard.

v4.5:
- Added new charts to the Statistics Window and charts can now be reordered.
- Added zone achievements (100/250/500/1000 kills)
- Added achievements for kills in level-ranges (1-9, 10-19, etc.) and Deadwind Pass
- Various minor layout/text improvements and fixes

v4.4:
- Fixed "You aren't in a party" messages in BGs.
- Leaderboard now has option to show your own alts
- Fixed tooltip for Most killed player and Nemesis when viewing another player's stats
- Fixed leaderboard class and race not in English if the other player is using a non-English WoW client
- Added Bonus achievement to kill the Defias Traitor 250 times.

v4.3:
- Added Arena achievements
- Fixed "Unknown" zone name for kills/deaths in Arena
- Fixed kills for priests using the talent "Spirit of Redemption" unintentionally being counted twice
- Various graphical fixes and improvements

v4.2.2:
- Fixed score in mouseover toolip not showing deaths

v4.2.1:
- Fixed "You are not in a raid group messages" while in a BG
- Added "Send Stats To..." button in leaderboard frame for quick stats sharing
- Improved leaderboard UI layout

v4.2:
- Added command /bpp sendstats <player name>. With it you can directly send your stats to a player that isn't nearby or in your party/raid/guild.
- Fixed automatic Battleground Mode for Eye of the Storm.

v4.1.1:
- Fixed "The number of messages that can be sent is limited" warnings in the chat

-4.1:
- Fixed missing icons
- Fixed leaderboard layout issues
- Fixed a few of the Guild kills achievements not working
- Added feature for data import from previous installations (like Classic Era client)
- 9 new achievements ("The 16h/24h Ganker" and "First Step into Outland")
- Info popup if a new addon version is available

v4.0.0:
- Added Leaderboard that syncs with nearby players and party/raid/guild members.
- Performance optimizations

v3.3:
- Added achievements for Redridge and Westfall escort quests (Horde only)

v3.2:
- Significant performance improvements
- Added overall K/D ratio to statistics overview

v3.1:
- Support for TBC Anniversary

v3.0:
- Added 68 new achievements for TBC!
- Perfomance improvements when killing a player
- Added option to include Player details (Level, Class, Race, Guild Rank, Guild Name) in announce messages
- Fixed addon frames not closing in combat using the X button
- Layout tweaks for the Player Detail Frame
- Added new option to cap achievement progress values at the required value (for example 100/100 instead of 125/100)
- Added option to select which channel (group, raid, guild, own chat window) should be used for the announce messages