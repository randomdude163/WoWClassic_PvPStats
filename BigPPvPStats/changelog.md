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