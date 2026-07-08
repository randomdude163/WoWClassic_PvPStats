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