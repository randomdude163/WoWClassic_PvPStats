local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Define all achievements here
AchievementSystem.achievements = { -- Paladin Achievements
{
    id = "paladin_1",
    title = "Bubble Popper",
    description = "Slay 250 Paladins",
    iconID = 626003,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Divine Shield bubbles popped! Turns out, the Light doesn't save them when [YOUR NAME] is around."
}, {
    id = "paladin_2",
    title = "Bubble Heartbreaker",
    description = "Slay 500 Paladins",
    iconID = 135896,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Paladins discovered their Hearthstone was on cooldown. The Light abandoned them faster than their guild after a wipe."
}, {
    id = "paladin_3",
    title = "Divine Retirement Plan",
    description = "Slay 750 Paladins",
    iconID = 133176,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Paladins cashed in their pension early! The Light's insurance premiums have skyrocketed since you started playing."
}, -- Priest Achievements
{
    id = "priest_1",
    title = "Holy Word: Death",
    description = "Defeat 250 Priests",
    iconID = 626004,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Priests discovered that healing can't fix death! Their last confession? 'I should have rolled a Warlock.'"
}, {
    id = "priest_2",
    title = "Scripture Shreader",
    description = "Defeat 500 Priests",
    iconID = 135898,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Priests found out prayer cooldowns are longer than death timers! The Light's HR department is swamped with resignation letters."
}, {
    id = "priest_3",
    title = "Religious Persecution",
    description = "Defeat 750 Priests",
    iconID = 135922,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Priests discovered their Power Word: Shield was just plot armor! Churches now offer combat training instead of Sunday service."
}, -- Druid Achievements
{
    id = "druid_1",
    title = "Roadkill Royale",
    description = "Take down 250 Druids",
    iconID = 625999,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Feral Druids brag about their movement speed—until they realize they’ve sprinted straight into 250 unavoidable deaths. Some say Travel Form is fast. You know what’s faster? A corpse run."
}, {
    id = "druid_2",
    title = "Animal Control",
    description = "Take down 500 Druids",
    iconID = 236167,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Druids exterminated! Cat form, bear form, dead form – you've seen them all. PETA has issued a statement."
}, {
    id = "druid_3",
    title = "Master of None",
    description = "Take down 750 Druids",
    iconID = 132138,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Druids claim they can do it all—tank, heal, DPS. 750 of them just proved they can also die in every imaginable way. At this point, even their Innervate couldn't restore their dignity."
}, -- Shaman Achievements
{
    id = "shaman_1",
    title = "Totem Kicker",
    description = "Defeat 250 Shamans",
    iconID = 626006,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Shamans discovered the elements don't answer when they're dead. You've kicked more totems than a clumsy tauren!"
}, {
    id = "shaman_2",
    title = "Spirit Walking Dead",
    description = "Defeat 500 Shamans",
    iconID = 237589,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Shamans deleted their characters after realizing casting Lightning Bolt in melee range isn’t actually a good strategy. Their ancestors are embarrassed."
}, {
    id = "shaman_3",
    title = "Windfury Wipeout",
    description = "Defeat 750 Shamans",
    iconID = 136088,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The world is down 750 Shamans, and yet not a single one landed that mythical 3x Windfury crit. Meanwhile, Warriors are still laughing."
}, -- Hunter Achievements
{
    id = "hunter_1",
    title = "Need on Everything",
    description = "Take down 250 Hunters",
    iconID = 626000,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Hunters down, yet they still rolled Need on their own funeral. Some habits never die."
}, {
    id = "hunter_2",
    title = "No More AFK Farmers and Backpedalers",
    description = "Take down 500 Hunters",
    iconID = 132208,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Hunters eliminated—most didn’t even notice. Their corpses still have Auto Shot toggled on. And the other half are still backpedaling to the graveyard."
}, {
    id = "hunter_3",
    title = "Click… No Ammo",
    description = "Take down 750 Hunters",
    iconID = 135618,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Hunters just learned the hard way that rifles need bullets. The only thing their gun is firing now is disappointment."
}, -- Warrior Achievements
{
    id = "warrior_1",
    title = "Rage Against The Machine",
    description = "Eliminate 250 Warriors",
    iconID = 626008,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The anger management clinic closed after losing their best customers - all 250 warriors found peace. Permanently."
}, {
    id = "warrior_2",
    title = "Execute.exe Has Failed",
    description = "Eliminate 500 Warriors",
    iconID = 132355,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The warrior's guild is in shambles after losing 500 members! Their recruitment poster now reads: 'Seeking warriors - no experience necessary, previous applicants need not apply."
}, {
    id = "warrior_3",
    title = "Big Numbers, Small Brain",
    description = "Eliminate 750 Warriors",
    iconID = 132346,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Warriors down! Turns out, rolling the most played class doesn’t guarantee you rolled the smartest players."
}, -- Mage Achievements
{
    id = "mage_1",
    title = "Frost Nova'd Forever",
    description = "Defeat 250 Mages",
    iconID = 626001,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Local inn reports 250 frozen mage corpses! Their Ice Block and your Frostnova melted faster than their hopes of survival. At least they're well preserved."
}, {
    id = "mage_2",
    title = "Cast Time Cancelled",
    description = "Defeat 500 Mages",
    iconID = 135808,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "These 500 mages learned that Pyroblast's cast time is longer than their life expectancy! Their last words were 'Just one more second...'"
}, {
    id = "mage_3",
    title = "Arcane Accident",
    description = "Defeat 750 Mages",
    iconID = 135736,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 750 failed Blink escapes, local mages are petitioning to make Blink work properly. So far, no response from their corpses."
}, -- Rogue Achievements
{
    id = "rogue_1",
    title = "Cheap Shot Champion",
    description = "Uncover and defeat 250 Rogues",
    iconID = 626005,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Found 250 rogues the hard way! Their stealth wasn't as good as they thought - maybe they should've spent more time practicing and less time ganking lowbies?"
}, {
    id = "rogue_2",
    title = "Swept Off Their Feet",
    description = "Uncover and defeat 500 Rogues",
    iconID = 132292,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Rogues got outplayed so hard, even Vanish couldn’t save them. The poison vendor is now offering a ‘No Refunds’ policy."
}, {
    id = "rogue_3",
    title = "xXShadowLegendXx Slayer",
    description = "Uncover and defeat 750 Rogues",
    iconID = 132299,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 rogues with names like 'Stábbyou' and 'Shadowkilla' won't be making any more YouTube 'EPIC 1V5 WORLD PVP' videos! Their Discord status is now permanently set to 'offline'."
}, -- Warlock Achievements
{
    id = "warlock_1",
    title = "Demon't",
    description = "Banish 250 Warlocks",
    iconID = 626007,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Warlocks sent their demons back to HR! Soulstones now come with a money-back guarantee."
}, {
    id = "warlock_2",
    title = "Forgot the Stone, Didn’t You?",
    description = "Banish 500 Warlocks",
    iconID = 134336,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Warlocks perished, and not a single Soulstone in sight. Their last words? 'Bro, I thought you had one on me.'"
}, {
    id = "warlock_3",
    title = "Hellfire and Brimston't",
    description = "Banish 750 Warlocks",
    iconID = 135818,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Warlocks cursed their last curse! Turns out their soul stones were just fancy paperweights. Even their demons are filing for workplace compensation."
}, -- Female Gender Achievement
{
    id = "gender_female_1",
    title = "Wife Beater",
    description = "Defeat 50 female characters",
    iconID = 134167,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Equal opportunity combat at its finest. You've sent 50 ladies to respawn and didn't even hold the graveyard gate open for them."
}, {
    id = "gender_female_2",
    title = "Wife Beater EPIC",
    description = "Defeat 100 female characters",
    iconID = 132356,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 female characters deleted with extreme prejudice. The Ironforge 'Women's Protection Society' has placed a bounty on your head. Prepare the shitstorm."
}, {
    id = "gender_female_3",
    title = "Wife Beater LEGENDARY",
    description = "Defeat 200 female characters",
    iconID = 135906,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 female characters obliterated! Your battle cry 'Equal rights means equal fights!' echoes across Azeroth. You've been banned from every tavern in Stormwind."
}, -- Male Gender Achievement
{
    id = "gender_male_1",
    title = "Widowmaker",
    description = "Defeat 50 male characters",
    iconID = 236557,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 husbands never made it home for dinner! Their wives are spending the Goblin Life Insurance payouts at the Auction House while spamming 'ty for gold' in trade chat."
}, {
    id = "gender_male_2",
    title = "Widowmaker EPIC",
    description = "Defeat 100 male characters",
    iconID = 132352,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 male characters destroyed! You're single-handedly responsible for a dating app boom in Azeroth. Lonely hearts everywhere."
}, {
    id = "gender_male_3",
    title = "Widowmaker LEGENDARY",
    description = "Defeat 200 male characters",
    iconID = 134166,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 males sent to their maker! The orphanages are overflowing and the wedding ring market has crashed. Economics, baby!"
}, -- Zone-specific Achievements
{
    id = "zone_redridge",
    title = "Redridge Renovation",
    description = "Eliminate 500 players in Redridge Mountains",
    iconID = 135759,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Redridge Mountains"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 kills in Redridge! At this point, the Horde is considering annexing the territory and renaming it 'Corpseridge.' Real estate agents are advertising it as 'Lordaeron South - Now with 100% more corpses!' The Forsaken already filing paperwork to make it their summer vacation resort."
}, {
    id = "zone_elwynn",
    title = "Elwynn Exterminator",
    description = "Eliminate 100 players in Elwynn Forest",
    iconID = 135763,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Elwynn Forest"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 100 deaths in Elwynn, local humans are painting themselves green and practicing their 'zug zug'! Goldshire Inn's new special: 'Reroll Horde, Get Free Hearthstone to Durotar.' Even Marshal Dughan is considering a career in Orgrimmar."
}, {
    id = "zone_duskwood",
    title = "Darkshire Destroyer",
    description = "Eliminate 100 players in Duskwood",
    iconID = 136223,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Duskwood"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The Night Watch counted 100 fresh corpses and decided to rename Darkshire to 'Deadshire'! Mor'Ladim is feeling professionally threatened, and Stiches filed for unemployment."
}, -- Total Kills Achievements
{
    id = "total_kills_1",
    title = "Body Count Rising",
    description = "Slay 500 players in total",
    iconID = 236399, -- spell_shadow_shadowfury
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 bodies dropped! Barrens chat has already moved on to debating whether you’re a bot, a multiboxer, or just deeply unhinged."
}, {
    id = "total_kills_2",
    title = "Graveyard Entrepreneur",
    description = "Slay 1000 players in total",
    iconID = 237542,
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "1000 kills! Spirit Healers are now offering you a commission for each body you send their way. The local gravediggers have named their shovels after you."
}, {
    id = "total_kills_3",
    title = "Death Incorporated",
    description = "Slay 3000 players in total",
    iconID = 132205,
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 3000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "3,000 confirmed kills! Even Mankrik’s wife had better odds of survival."
}, -- Unique Player Kills Achievements
{
    id = "unique_kills_1",
    title = "Variety Slayer",
    description = "Defeat 400 unique players",
    iconID = 236539,
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "400 different players have fallen to you. At this point, you’re less of a PvPer and more of an extinction event. Azeroth is running out of fresh faces, and you’re the reason why."
}, {
    id = "unique_kills_2",
    title = "Equal Opportunity Executioner",
    description = "Defeat 800 unique players",
    iconID = 236535,
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 800
    end,
    unlocked = false,
    completedDate = nil,
    subText = "800 unique victims and counting! Players are now selling 'I Survived [YOUR NAME]' t-shirts - except none of them actually survived."
}, {
    id = "unique_kills_3",
    title = "Celebrity Stalker",
    description = "Defeat 2400 unique players",
    iconID = 236541,
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 2400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "2400 unique souls claimed! At this point, it's easier to list who you HAVEN'T killed. How’s that kill addiction treating you? "
}, -- Alliance Races
-- Human Achievements
{
    id = "race_human_1",
    title = "Human Resources",
    description = "Eliminate 250 Humans",
    iconID = 236447,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The Stormwind job market is in shambles after losing 250 employees! Local guards are now accepting Murlocs into their ranks."
}, {
    id = "race_human_2",
    title = "Stormwind Unemployment Office",
    description = "Eliminate 500 Humans",
    iconID = 236448,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Real estate prices in Stormwind dropped by 90% after 500 residents checked out permanently! Even the kobolds are turning down property viewings."
}, {
    id = "race_human_3",
    title = "Every Human for Themselves",
    description = "Eliminate 750 Humans",
    iconID = 133730,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 humans learned their racial isn't so great after all! Varian is considering rebranding Stormwind as 'Ghost Town - Now with 100% more spirit healers!'"
},

-- Night Elf Achievements
{
    id = "race_nightelf_1",
    title = "Tree Hugger Terminator",
    description = "Eliminate 250 Night Elves",
    iconID = 236449,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 250 Night Elves discovered Shadowmeld doesn't work against you, Darnassus tourism dropped faster than their corpses!"
}, {
    id = "race_nightelf_2",
    title = "Immortality Canceled",
    description = "Eliminate 500 Night Elves",
    iconID = 236450,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The Emerald Dream is getting crowded with 500 new permanent residents! Turns out, flips don't dodge arrows."
}, {
    id = "race_nightelf_3",
    title = "Hippy Recycling Program",
    description = "Eliminate 750 Night Elves",
    iconID = 134161,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Night Elves are now literally one with nature! Teldrassil real estate now advertised as 'Pre-burned condition'."
},

-- Dwarf Achievements
{
    id = "race_dwarf_1",
    title = "Short Term Solution",
    description = "Eliminate 250 Dwarves",
    iconID = 236443,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Dwarf"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The Ironforge beer consumption dropped by 250 mugs! Stone form turned out to be just fancy rigor mortis."
}, {
    id = "race_dwarf_2",
    title = "Beard Trimmer",
    description = "Eliminate 500 Dwarves",
    iconID = 236444,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Dwarf"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 dwarves discovered that being Made of Stone doesn't help against being Made Deceased! Local barbers filing for bankruptcy."
}, {
    id = "race_dwarf_3",
    title = "Height Disadvantage",
    description = "Eliminate 750 Dwarves",
    iconID = 134159,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Dwarf"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Ironforge engineers are designing smaller coffins after 750 'height-challenged' casualties! Their spirits are now discovering that the Great Forge isn't so great."
},

-- Gnome Achievements
{
    id = "race_gnome_1",
    title = "Pest Control",
    description = "Eliminate 250 Gnomes",
    iconID = 236445,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Gnome"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Gnomes learned that Engineering doesn't have a 'Resurrect' schematic! Their death animations are still playing at 0.5x speed."
}, {
    id = "race_gnome_2",
    title = "Garden Gnome Collection",
    description = "Eliminate 500 Gnomes",
    iconID = 236446,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Gnome"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Gnomes discovered that Escape Artist doesn't work on death! Now they're permanent lawn ornaments."
}, {
    id = "race_gnome_3",
    title = "Small Problems Solved",
    description = "Eliminate 750 Gnomes",
    iconID = 134164,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Gnome"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The graveyard is using 750 gnome corpses as speed bumps! Their families are demanding refunds on those expensive Engineering degrees."
},

-- Horde Races
-- Orc Achievements
{
    id = "race_orc_1",
    title = "Green Peace",
    description = "Eliminate 250 Orcs",
    iconID = 236451,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Orc"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Orcs learned that Blood Fury is just a fancy name for a nosebleed! Thrall is considering a 'No Dying' policy in Orgrimmar."
}, {
    id = "race_orc_2",
    title = "Anger Management Expert",
    description = "Eliminate 500 Orcs",
    iconID = 236452,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Orc"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Orcs discovered that Hardiness doesn't reduce death duration! The Warchief is now accepting applications from Murlocs."
}, {
    id = "race_orc_3",
    title = "Green Peace Treaty",
    description = "Eliminate 750 Orcs",
    iconID = 134170,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Orc"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Durotar's population decreased by 750! Now the spikes are just load-bearing decorations for empty buildings."
},

-- Undead Achievements
{
    id = "race_undead_1",
    title = "Double Dead",
    description = "Eliminate 250 Undead",
    iconID = 236457,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Undead"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Forsaken discovered you can die twice! Will of the Forsaken now comes with a stern warning label."
}, {
    id = "race_undead_2",
    title = "Zombies't",
    description = "Eliminate 500 Undead",
    iconID = 236458,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Undead"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Undead are now Twice-Dead! Sylvanas is running out of resurrection juice, and the Apothecary is offering two-for-one deals."
}, {
    id = "race_undead_3",
    title = "Permanent Death Status",
    description = "Eliminate 750 Undead",
    iconID = 136187,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Undead"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Undead finally achieved true death! The Dark Lady's 'Death to the Living' slogan needs revision after meeting you."
},

-- Troll Achievements
{
    id = "race_troll_1",
    title = "Voodoo Venue Closed",
    description = "Eliminate 250 Trolls",
    iconID = 236455,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Trolls discovered that regeneration has a fatal flaw! Their final words were 'Ya got me, mon...'"
}, {
    id = "race_troll_2",
    title = "Berserking Backfire",
    description = "Eliminate 500 Trolls",
    iconID = 236456,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Trolls won't be regenerating from this! Da voodoo shuffle couldn't dodge your killing blows, mon."
}, {
    id = "race_troll_3",
    title = "Rastafarian Retirement",
    description = "Eliminate 750 Trolls",
    iconID = 134177,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Trolls be taking the eternal voodoo nap, mon! Sen'jin Village is now offering discount mojo - previous owners won't be needing it."
},

-- Tauren Achievements
{
    id = "race_tauren_1",
    title = "Sacred Cow Tipper",
    description = "Eliminate 250 Tauren",
    iconID = 236453,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Tauren"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Thunder Bluff elevator claims fewer lives than you after 250 Tauren took their last step! War Stomp doesn't work in ghost form."
}, {
    id = "race_tauren_2",
    title = "No More Bull",
    description = "Eliminate 500 Tauren",
    iconID = 236454,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Tauren"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Tauren discovered that Nature Resistance doesn't protect against you! Mulgore is now accepting applications for lawn maintenance."
}, {
    id = "race_tauren_3",
    title = "Cattle Depopulation",
    description = "Eliminate 750 Tauren",
    iconID = 134174,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Tauren"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 750 Tauren deaths, Thunder Bluff is renaming itself to 'Empty Pasture'! The Grimtotem are taking notes on your technique."
}, -- Guild Achievements
{
    id = "guild_kills",
    title = "Guild Drama Generator",
    description = "Eliminate 500 guild members",
    iconID = 134473,
    condition = function(playerStats)
        local _, _, _, _, _, _, guildStatusData = PSC_CalculateBarChartStatistics()
        return (guildStatusData["In Guild"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 guild players deleted! Their guild banks are full of soulbound gear, and their Discord is just /gquit screenshots. Even Ragnaros is less toxic than their officer chat right now."
}, {
    id = "guildless_kills",
    title = "Lone Wolf Hunter",
    description = "Eliminate 500 guildless players",
    iconID = 132203,
    condition = function(playerStats)
        local _, _, _, _, _, _, guildStatusData = PSC_CalculateBarChartStatistics()
        return (guildStatusData["No Guild"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Sent 500 'social anxiety' players back to retail! Their 'I don't need a guild to play' attitude didn't help against your killing spree. At least they didn't have to explain their deaths in guild chat."
}, {
    id = "grey_level_kills",
    title = "Teach them young",
    description = "Eliminate 100 grey-level players",
    iconID = 134435,
    condition = function(playerStats)
        return PSC_CalculateGreyKills() >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "It ain't much but it's honest work!"
}}

-- Function to get player name for achievement text
local function GetPlayerName()
    local playerName = UnitName("player")
    return playerName or "You"
end

-- Function to replace placeholders in text with player name
local function PersonalizeText(text)
    if not text then return "" end
    local playerName = GetPlayerName()
    return text:gsub("%[YOUR NAME%]", playerName)
end

-- Function to check achievements and show popup if newly unlocked
function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}
    local playerName = GetPlayerName()

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M") -- Set completion date

            -- Personalize achievement text before showing popup
            local personalizedDescription = PersonalizeText(achievement.description)

            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = personalizedDescription
            })
        end
    end
end
