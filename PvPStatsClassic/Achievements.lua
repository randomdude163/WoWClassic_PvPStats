local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

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
    subText = "750 Paladins judged and executed. Every one of them still lives in their childhood bedroom, gives unsolicited advice about honor, and thinks ‘simp’ is the ultimate insult. Their Tinder bios all include 'protector of women.'"
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
    subText = "250 Shamans flattened — mostly Enhancement mains who picked the spec because someone told them Windfury makes big numbers. They’re now back in retail, crying about how Classic 'isn't fair'."
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
    title = "I'm so special",
    description = "Take down 250 Hunters",
    iconID = 626000,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Hunters down. All of them thought naming their pet 'Arthas' made them deep, and that spelling 'Légolâs' with special characters made them original. Congratulations — you just wiped out the world's largest unpaid cosplay convention."
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
    subText = "You’ve ended the WoW careers of 750 Hunters — that’s 750 dudes who think  they’re ‘PvP Gods’ because they once kited Bellygrub 40 yards to the Guards. Their last words? 'I swear I had ammo!'"
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
    title = "Curse you!",
    description = "Banish 750 Warlocks",
    iconID = 135818,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Warlocks cursed you with everything they had—bad posture, social anxiety, and a Steam library full of games they’ll never finish. Joke’s on them: you were already cursed with exposure to their forum posts."
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
    subText = "50 husbands never made it home for dinner! Their wives are spending the Goblin Life Insurance payouts at the Auction House."
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
    iconID = 133789,
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
    iconID = 133787,
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
    iconID = 133785,
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
    subText = "250 Humans deleted! The most basic race in Azeroth, chosen by people who couldn’t be bothered to click twice. They died as they lived—completely unremarkable."
}, {
    id = "race_human_2",
    title = "Peak Meta, Peak Failure",
    description = "Eliminate 500 Humans",
    iconID = 236448,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Humans down! They picked the ‘best PvP race’ for the racial bonuses but forgot to read the part about positioning and cooldowns."
}, {
    id = "race_human_3",
    title = "Honorless Duelists",
    description = "Eliminate 750 Humans",
    iconID = 133730,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Stormwind's population just dropped by 750! Their precious Diplomacy racial couldn't talk their way out of a shallow grave. Undertakers are working overtime, and the Defias Brotherhood sent you a gift basket for finishing what they started. The Kingdom's orphanages are so overcrowded they're converting the Stockade into a daycare. Even the Lich King would tell you to chill out."
},

-- Night Elf Achievements
{
    id = "race_nightelf_1",
    title = "Shadowmeld Won't Save You",
    description = "Eliminate 250 Night Elves",
    iconID = 236449,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Night Elves eliminated! They thought they disappeared… but all you saw was a free honor kill waiting to happen."
}, {
    id = "race_nightelf_2",
    title = "One with Nature, Now One with the Dirt",
    description = "Eliminate 500 Night Elves",
    iconID = 236450,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Half a thousand Night Elves sent to wisp chat. — congrats, you’ve outpaced deforestation. Teldrassil is applying for a UNESCO war crime investigation. "
}, {
    id = "race_nightelf_3",
    title = "Eternal No More",
    description = "Eliminate 750 Night Elves",
    iconID = 134161,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Night Elves in the dirt! All that jumping around didn't save them from [YOUR NAME]. Each one was still typing 'shadows meld me!' when you ended them. Most died while taking screenshots of sunsets or AFKing in character-select poses. Their precious 'front flip' jumping animation is much less impressive from a corpse."
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
    subText = "250 Dwarves crushed! Short, stout, and now six feet under. Their ‘legendary resilience’ apparently doesn’t apply when getting farmed for honor."
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
    subText = "250 Gnomes punted out of existence! Their last words? 'Size doesn’t matter!' Their respawn timer says otherwise."
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
    subText = "500 Gnomes deleted. You’ve wiped more STEM majors than a Silicon Valley hiring freeze. Their gadgets couldn’t save them, and their last words were all keyboard macros no one understood"
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
    subText = "Zug zug? More like zug zugged into the grave. 250 Orcs charged in, expecting an easy win—turns out, yelling ‘Lok’tar Ogar!’ doesn’t make you invincible."
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
    subText = "500 Orcs have rage-quit after meeting you! These keyboard smashers with names like 'Gorégut' and 'Axemastr' spent more time perfecting their /flex macro than learning to dodge. Greenpeace has formally requested you stop this endangered species extinction event. Their Blood Fury racial activated IRL as they typed angry whispers to you from the graveyard."
}, {
    id = "race_orc_3",
    title = "Green Graveyard",
    description = "Eliminate 750 Orcs",
    iconID = 134170,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Orc"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 min-maxing Orc players just discovered their PvP racial doesn't help when they keyboard turn! These meta-chasers who rolled the 'optimal race' couldn't optimize their way out of a [YOUR NAME] beatdown. All those forum guides didn't prepare them for someone who actually knows how to play. Should've practiced instead of bragging about stun resistance in trade chat!"
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
    subText = "250 Forsaken sent back to the character creation screen. Turns out, playing ‘the most hardcore race’ doesn’t make you any less of a free HK. Sylvanas won’t miss them—she doesn’t even miss her own people."
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
    subText = "500 Forsaken ganked! They picked Undead to look cool and ended up looking clueless. No, ‘Will of the Forsaken’ doesn’t make you invincible—if it did, they wouldn’t all be face-down in the dirt"
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
    subText = "750 Forsaken now even more dead than before! The Dark Lady's weekly newsletter now includes a [YOUR NAME] survival guide. These edgelords thought being already-dead made them cool until you showed them what 'dead-dead' feels like. Now Brill is a ghost town (even more than usual), and Tirisfal Glades real estate is free for the taking. Even the Scarlet Crusade thinks you're taking this whole 'purging the undead' thing too far."
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
    subText = "Da spirits be VERY angry wit' you mon, after 250 trolls found out their regeneration can't outpace your damage output. Their hunched backs didn't help them dodge your attacks—just made it easier for you to spot them from a distance. Zul'jin is considering therapy after watching your killing spree. Stay away from da voodoo!"
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
    subText = "500 trolls be dead, and their witch doctors can't figure out why! Their Berserking racial just helped them die faster. They attacked 15% quicker, but you still killed them 100% dead. The Echo Isles are now placing 'BEWARE: [YOUR NAME]' signs along the coast. Sen'jin Village is considering tribute payments just to appease you."
}, {
    id = "race_troll_3",
    title = "Hunched Back, Hunched Over in Defeat",
    description = "Eliminate 750 Trolls",
    iconID = 134177,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Trolls down! Their posture wasn’t the only thing broken today. Maybe they should’ve berserked their way to a real strategy instead of just hoping their racial would carry them."
},

-- Tauren Achievements
{
    id = "race_tauren_1",
    title = "Biggest Hitbox, Biggest Target",
    description = "Eliminate 250 Tauren",
    iconID = 236453,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Tauren"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Tauren down! These walking steaks chose the biggest hitbox in the game then complained when your attacks connected. McDonald's just offered you a sponsorship deal after your record-breaking beef production. The 'got milk?' campaign is suing you for destroying their mascots. Next time they'll think twice before picking a race that can be seen from the other continent."
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
    subText = "500 Tauren players got exactly what they deserved for picking the 'gentle giant' stereotype! Their 5% bonus health just meant they died 3 seconds slower while panic-pressing War Stomp. The real stampede was them rushing to the forums to complain about 'unfair pvp balance.'"
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
    subText = "You've slaughtered 750 Tauren! Thunder Bluff elevator accidents are now the SECOND leading cause of Tauren death. These gentle giants had 5% more health than other races, which gave them exactly 3 extra seconds to contemplate their life choices before you ended them. Mulgore's milk industry has collapsed, and the Grimtotem are sending you fan mail. The Earth Mother has filed a restraining order against you."
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
    subText = "500 so-called 'guildmates' slaughtered! Turns out, that guild tag above their heads didn’t make them any less squishy. Maybe they should try a PvE guild—less world PvP, more coping in raid chat."
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
}, -- Kill Streak Achievements
{
    id = "kill_streak_25",
    title = "Serial Killer",
    description = "Achieve a 25-player kill streak",
    iconID = 133728,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 25
    end,
    unlocked = false,
    completedDate = nil,
    subText = "25 players deleted in a row! The graveyard is installing a '[YOUR NAME] Express Lane' with a self-checkout option."
},
{
    id = "kill_streak_50",
    title = "Crime Scene",
    description = "Achieve a 50-player kill streak",
    iconID = 133730,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 consecutive kills! Azeroth's investigators are gathering evidence, but all the witnesses keep mysteriously disappearing."
},
{
    id = "kill_streak_75",
    title = "Mass Extinction",
    description = "Achieve a 75-player kill streak",
    iconID = 133731,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 75
    end,
    unlocked = false,
    completedDate = nil,
    subText = "75 kills without dying? Players are filing tickets claiming you're hacking. Blizzard responded: 'No, they're just that good.'"
},
{
    id = "kill_streak_100",
    title = "TRIPLE D!!!",
    description = "Achieve a 100-player kill streak",
    iconID = 132734,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You've killed more players than some indie games have sales. Enemy raid leaders reference you like you're Voldemort — 'He-Who-Wipes-Raid-Groups.'' Even your local WiFi provider flagged you as a DDoS threat."
},
{
    id = "kill_streak_125",
    title = "PvP Plague",
    description = "Achieve a 125-player kill streak",
    iconID = 136123,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 125
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You're not a player anymore—you're a server-wide debuff. Whole zones avoid you like it's patch day. 125 kills and not a single scratch? That’s not PvP. That’s population control."
},
{
    id = "kill_streak_150",
    title = "Fine Wine",
    description = "Achieve a 150-player kill streak",
    iconID = 132789,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 150
    end,
    unlocked = false,
    completedDate = nil,
    subText = "150 uninterrupted kills! You're not just killing players—you're killing server populations. Like a fine wine, your murder spree only improves with time."
},
{
    id = "kill_streak_175",
    title = "Unstoppable Force",
    description = "Achieve a 175-player kill streak",
    iconID = 133050,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 175
    end,
    unlocked = false,
    completedDate = nil,
    subText = "175 bodies and counting! Like the legendary Alterac Valley weapon, you've become a force of nature—slow, powerful, and absolutely devastating. The Immovable Object has finally met its match, and it's your kill streak. Players have started putting 'killed by [YOUR NAME]' in their forum signatures as a badge of honor."
},
{
    id = "kill_streak_200",
    title = "Human Resources Nightmare",
    description = "Achieve a 200-player kill streak",
    iconID = 236370,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 unbroken kills! Your /flex emote now causes a 10-yard fear. Even raid bosses check their aggro tables when you log in. Blizzard added a new GM macro: /who [YOUR NAME] – for threat assessment."
},
{
    id = "multi_kill_3",
    title = "Triple Kill!",
    description = "Get 3 kills in a single combat",
    iconID = 236330,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 3
    end,
    unlocked = false,
    completedDate = nil,
    subText = "ACE! Three champions... er, players... fell to your blade in quick succession. The enemy team is crying 'nerf [YOUR NAME]' in all chat. Your Summoner Score is rising!"
},
{
    id = "multi_kill_4",
    title = "QUADRA KILL!",
    description = "Get 4 kills in a single combat",
    iconID = 236341,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 4
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The crowd goes wild as you secure your fourth elimination! 'GG [YOUR NAME] diff' echoes across Azeroth. The enemy team is calling for a surrender vote while spamming 'Report jungler no ganks' in chat."
},
{
    id = "multi_kill_5",
    title = "PENTAKILL!!",
    description = "Get 5 kills in a single combat",
    iconID = 236383,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 5
    end,
    unlocked = false,
    completedDate = nil,
    subText = "LEGENDARY! You just went full Faker on these noobs! 'GG EZ' has never been more appropriate. The enemy team pressed Alt + F4 simultaneously and uninstalled the game. Your MVP status is unrivaled, and Riot Games is sending you a cease and desist letter for being too OP."
},

-- Most Killed Player Achievement
{
    id = "favorite_target",
    title = "Personal Vendetta",
    description = "Kill the same player 10 times",
    iconID = 136168,  -- Red target icon
    condition = function(playerStats)
        local stats = PSC_CalculateSummaryStatistics()
        return stats.mostKilledCount >= 10
    end,
    unlocked = false,
    completedDate = nil,
    subText = function()
        local stats = PSC_CalculateSummaryStatistics()
        local playerName = stats.mostKilledPlayer or "Unknown"
        local killCount = stats.mostKilledCount or 0

        if playerName == "None" or killCount < 10 then
            return "You have developed an unhealthy obsession with " .. playerName
        end
        return playerName .. " has died to you " .. killCount .. " times! They've added your name to their '/who' macro and log off the moment you appear online. Their guild required them to change their hearthstone to a new continent just to avoid you. Every night, they check under their bed for [YOUR NAME] before going to sleep."
    end
},
}

local function GetPlayerName()
    local playerName = UnitName("player")
    return playerName or "You"
end

-- Update PersonalizeText function to handle function-based subText
local function PersonalizeText(text)
    if not text then return "" end

    -- If text is a function, call it to get the actual text
    if type(text) == "function" then
        text = text()
    end

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
