local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

AchievementSystem.achievements = {
    -- Paladin Achievements
{
    id = "class_paladin_0",
    title = "White Knight Down",
    description = "Slay 100 Paladins",
    iconID = 626003,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They say 'I just want everyone to get along' while reporting half the BG for language. You’ve defeated 100 Paladins who unironically post minion memes and call every woman “m’lady” in raid chat."
}, {
    id = "class_paladin_1",
    title = "Bubble Popper",
    description = "Slay 250 Paladins",
    iconID = 135896 ,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Divine Shield bubbles popped! Turns out, the Light doesn't save them when [YOUR NAME] is around."
}, {
    id = "class_paladin_2",
    title = "It's on cooldown...",
    description = "Slay 500 Paladins",
    iconID = 134414,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Paladins discovered their Hearthstone was on cooldown. The Light abandoned them faster than their guild after a wipe."
}, {
    id = "class_paladin_3",
    title = "Divine Retirement Plan",
    description = "Slay 750 Paladins",
    iconID = 133176,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Paladins judged and executed. Every one of them still lives in their childhood bedroom, gives unsolicited advice about honor, and thinks 'simp' is the ultimate insult. Their Tinder bios all include 'protector of women.'"
}, -- Priest Achievements
{
    id = "class_priest_0",
    title = "Therapy Session Over",
    description = "Defeat 100 Priests",
    iconID = 626004,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Priests exorcised—and not just from the battlefield. These armchair therapists are one failed psych degree away from charging guildmates hourly. Every time you crit them, they ask if you're projecting."
}, {
    id = "class_priest_1",
    title = "Holy Word: Death",
    description = "Defeat 250 Priests",
    iconID = 135944,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Priests discovered that healing can't fix death! Their last confession? 'I should have rolled a Warlock.'"
}, {
    id = "class_priest_2",
    title = "Scripture Shreader",
    description = "Defeat 500 Priests",
    iconID = 135898,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Priests found out prayer cooldowns are longer than death timers! The Light's HR department is swamped with resignation letters."
}, {
    id = "class_priest_3",
    title = "Religious Persecution",
    description = "Defeat 750 Priests",
    iconID = 135922,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Priests discovered their Power Word: Shield was just plot armor! Churches now offer combat training instead of Sunday service."
}, -- Druid Achievements
{
    id = "class_druid_0",
    title = "I'm VEGAN, bro!",
    description = "Take down 100 Druids",
    iconID = 625999,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Druids sent back to their crystal shops! They're 'jack of all trades, master of none' incarnate but will still lecture you about your rotation. Their /yell macro includes the words 'spirit animal,' 'vibes,' and 'energy alignment,' and they've definitely tried to sell essential oils to their guildmates. Each one has explained they're vegan within 30 seconds of joining your party."
}, {
    id = "class_druid_1",
    title = "Roadkill Royale",
    description = "Take down 250 Druids",
    iconID = 132117,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Feral Druids brag about their movement speed—until they realize they’ve sprinted straight into 250 unavoidable deaths. Some say Travel Form is fast. You know what’s faster? A corpse run."
}, {
    id = "class_druid_2",
    title = "Animal Control",
    description = "Take down 500 Druids",
    iconID = 236167,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Druids exterminated! Cat form, bear form, dead form – you've seen them all. PETA has issued a statement."
}, {
    id = "class_druid_3",
    title = "Master of None",
    description = "Take down 750 Druids",
    iconID = 132138,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Druids claim they can do it all—tank, heal, DPS. 750 of them just proved they can also die in every imaginable way. At this point, even their Innervate couldn't restore their dignity."
}, -- Shaman Achievements
{
    id = "class_shaman_0",
    title = "Avatar State Deactivated",
    description = "Defeat 100 Shamans",
    iconID = 626006,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Shamans eliminated! These wannabe Avatars binge-watched too many cartoons and thought they'd be bending all four elements in-game. Reality hit harder than your weapon when they discovered their totems don't actually shoot fire or create tsunamis. They spend most raids frantically alt-tabbing to YouTube tutorials trying to figure out what their class actually does. When asked about their role, they reply 'Yes' and then fail at all of them."
}, {
    id = "class_shaman_1",
    title = "Totem Kicker",
    description = "Defeat 250 Shamans",
    iconID = 136052,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Shamans flattened — mostly Enhancement mains who picked the spec because someone told them Windfury makes big numbers. They’re now back in retail, crying about how Classic 'isn't fair'."
}, {
    id = "class_shaman_2",
    title = "Spirit Walking Dead",
    description = "Defeat 500 Shamans",
    iconID = 237589,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Shamans deleted their characters after realizing casting Lightning Bolt in melee range isn’t actually a good strategy. Their ancestors are embarrassed."
}, {
    id = "class_shaman_3",
    title = "Windfury Wipeout",
    description = "Defeat 750 Shamans",
    iconID = 136088,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The world is down 750 Shamans, and yet not a single one landed that mythical 3x Windfury crit. Meanwhile, Warriors are still laughing."
}, -- Hunter Achievements
{
    id = "class_hunter_0",
    title = "Bear Grylls Roleplayers",
    description = "Take down 100 Hunters",
    iconID = 626000,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You’ve taken out 100 Hunters who say “trust your instincts” but can’t trust themselves to park straight. They bring up Bear Grylls in Discord like it's a personality trait and probably drink their own piss “ironically.”"
}, {
    id = "class_hunter_1",
    title = "I'm so special",
    description = "Take down 250 Hunters",
    iconID = 132212,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Hunters down. All of them thought naming their pet 'Arthas' made them deep, and that spelling 'Légolâs' with special characters made them original. Congratulations — you just wiped out the world's largest unpaid cosplay convention."
}, {
    id = "class_hunter_2",
    title = "No More AFK Farmers and Backpedalers",
    description = "Take down 500 Hunters",
    iconID = 132208,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Hunters eliminated—most didn’t even notice. Their corpses still have Auto Shot toggled on. And the other half are still backpedaling to the graveyard."
}, {
    id = "class_hunter_3",
    title = "Click… No Ammo",
    description = "Take down 750 Hunters",
    iconID = 135618,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You’ve ended the WoW careers of 750 Hunters — that’s 750 dudes who think  they’re ‘PvP Gods’ because they once kited Bellygrub 40 yards to the Guards. Their last words? 'I swear I had ammo!'"
}, -- Warrior Achievements
{
    id = "class_warrior_0",
    title = "Protein Power Shortage",
    description = "Eliminate 100 Warriors",
    iconID = 626008,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Warriors down! These gym bros spent more time flexing in Ironforge than learning their rotation. Their emotional range is limited to 'mad,' 'hangry,' and 'where heals?' They consider counting to 10 as advanced mathematics and think reading quest text is for roleplayers. They also believe that 'PvP' stands for 'Protein vs. Pre-workout.'"
}, {
    id = "class_warrior_1",
    title = "Rage Against The Machine",
    description = "Eliminate 250 Warriors",
    iconID = 132333,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Warriors deleted! These walking protein shakers with keyboards think smashing random buttons is a 'rotation.' Their Discord profile pics are all gym selfies, and their vocabulary consists exclusively of 'bro,' 'gains,' and 'where heals?' The anger management clinic just closed after losing all 250 of their best customers to your weapon. The only thing they rage-quit faster than the battlefield is their cutting diet."
}, {
    id = "class_warrior_2",
    title = "Execute.exe Has Failed",
    description = "Eliminate 500 Warriors",
    iconID = 132355,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Warriors deleted! These mouth-breathing keyboard smashers think strategy means hitting whatever isn't on cooldown. Their collective IQ is lower than their average item level, and that's saying something after you've repeatedly ganked them naked. The warrior's guild is hiring anyone with a pulse now—previous candidates eliminated by natural selection and your weapon."
}, {
    id = "class_warrior_3",
    title = "Big Numbers, Small Brain",
    description = "Eliminate 750 Warriors",
    iconID = 132346,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Warriors down! Turns out, rolling the most played class doesn’t guarantee you rolled the smartest players."
}, -- Mage Achievements
{
    id = "class_mage_0",
    title = "Actually, ...",
    description = "Defeat 100 Mages",
    iconID = 626001,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Mages deleted! Each one was three credits short of a philosophy degree but will lecture you about existentialism anyway. These self-proclaimed intellectuals memorized all their 'actually' rebuttals from Reddit posts and believe their IQ is 'too high to measure.'"
}, {
    id = "class_mage_1",
    title = "Frost Nova'd Forever",
    description = "Defeat 250 Mages",
    iconID = 135848,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Local inn reports 250 frozen mage corpses! Their Ice Block and your Frostnova melted faster than their hopes of survival. At least they're well preserved."
}, {
    id = "class_mage_2",
    title = "Cast Time Cancelled",
    description = "Defeat 500 Mages",
    iconID = 135808,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "These 500 mages learned that Pyroblast's cast time is longer than their life expectancy! Their last words were 'Just one more second...'"
}, {
    id = "class_mage_3",
    title = "Arcane Accident",
    description = "Defeat 750 Mages",
    iconID = 135736,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 750 failed Blink escapes, local mages are petitioning to make Blink work properly. So far, no response from their corpses."
}, -- Rogue Achievements
{
    id = "class_rogue_0",
    title = "Energy Drink Depleted",
    description = "Uncover and defeat 100 Rogues",
    iconID = 626005,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Rogues eliminated! You can smell the Monster Energy and Doritos from here. These walking red flags all type 'ez' after winning 5v1s against level 20s. They've got fingerless gloves IRL, a 'Damaged' tattoo somewhere visible, and spend their free time making TikToks about their 'sigma male grindset.' Every one of them has a mechanical keyboard with blue switches specifically to annoy their roommates."
}, {
    id = "class_rogue_1",
    title = "Cheap Shot Champion",
    description = "Uncover and defeat 250 Rogues",
    iconID = 132092,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Found 250 rogues the hard way! Their stealth wasn't as good as they thought - maybe they should've spent more time practicing and less time ganking lowbies?"
}, {
    id = "class_rogue_2",
    title = "Swept Off Their Feet",
    description = "Uncover and defeat 500 Rogues",
    iconID = 132292,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Rogues got outplayed so hard, even Vanish couldn’t save them. The poison vendor is now offering a ‘No Refunds’ policy."
}, {
    id = "class_rogue_3",
    title = "xXShadowLegendXx Slayer",
    description = "Uncover and defeat 750 Rogues",
    iconID = 132299,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 rogues with names like 'Stábbyou' and 'Shadowkilla' won't be making any more YouTube 'EPIC 1V5 WORLD PVP' videos! Their Discord status is now permanently set to 'offline'."
}, -- Warlock Achievements
{
    id = "class_warlock_0",
    title = "Wand Wielding Weirdo Wipeout",
    description = "Banish 100 Warlocks",
    iconID = 626007,
    achievementPoints = 10,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 goths nuked! These misunderstood 'dark intellectuals' have black nail polish, a concerning collection of skeleton merchandise, and definitely own a katana. They've misquoted Nietzsche so many times that even their demons are rolling their eyes. Every guild message begins with 'I'm not trying to be negative, but...' before they proceed to be exactly that. "
}, {
    id = "class_warlock_1",
    title = "Demon't",
    description = "Banish 250 Warlocks",
    iconID = 136218,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Warlocks sent their demons back to HR! Soul Shards now come with a money-back guarantee."
}, {
    id = "class_warlock_2",
    title = "Forgot the Stone, Didn’t You?",
    description = "Banish 500 Warlocks",
    iconID = 134336,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Warlocks perished, and not a single Soulstone in sight. Their last words? 'Bro, I thought you had one on me.'"
}, {
    id = "class_warlock_3",
    title = "Curse you!",
    description = "Banish 750 Warlocks",
    iconID = 135818,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Warlocks cursed you with everything they had—bad posture, social anxiety, and a Steam library full of games they’ll never finish. Joke’s on them: you were already cursed with exposure to their forum posts."
}, -- Female Gender Achievement
{
    id = "general_gender_female_1",
    title = "Wife Beater",
    description = "Defeat 50 female characters",
    iconID = 134167,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Equal opportunity combat at its finest. You've sent 50 ladies to respawn and didn't even hold the graveyard gate open for them."
}, {
    id = "general_gender_female_2",
    title = "Wife Beater EPIC",
    description = "Defeat 100 female characters",
    iconID = 132356,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 female characters deleted with extreme prejudice. The Ironforge 'Women's Protection Society' has placed a bounty on your head. Prepare the shitstorm."
}, {
    id = "general_gender_female_3",
    title = "Wife Beater LEGENDARY",
    description = "Defeat 200 female characters",
    iconID = 135906,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 female characters obliterated! Your battle cry 'Equal rights means equal fights!' echoes across Azeroth. You've been banned from every tavern in Stormwind."
}, -- Male Gender Achievement
{
    id = "general_gender_male_1",
    title = "Widowmaker",
    description = "Defeat 50 male characters",
    iconID = 236557,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 husbands never made it home for dinner! Their wives are spending the Goblin Life Insurance payouts at the Auction House."
}, {
    id = "general_gender_male_2",
    title = "Widowmaker EPIC",
    description = "Defeat 100 male characters",
    iconID = 132352,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 male characters destroyed! You're single-handedly responsible for a dating app boom in Azeroth. Lonely hearts everywhere."
}, {
    id = "general_gender_male_3",
    title = "Widowmaker LEGENDARY",
    description = "Defeat 200 male characters",
    iconID = 134166,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 males sent to their maker! The orphanages are overflowing and the wedding ring market has crashed. Economics, baby!"
}, -- Zone-specific Achievements
{
    id = "general_zone_redridge",
    title = "Redridge Renovation",
    description = "Eliminate 500 players in Redridge Mountains",
    iconID = 236814,
    achievementPoints = 500,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Redridge Mountains"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 kills in Redridge! At this point, the Horde is considering annexing the territory and renaming it 'Corpseridge.' Real estate agents are advertising it as 'Lordaeron South - Now with 100% more corpses!' The Forsaken already filing paperwork to make it their summer vacation resort."
}, {
    id = "general_zone_elwynn",
    title = "Elwynn Exterminator",
    description = "Eliminate 100 players in Elwynn Forest",
    iconID = 236761,
    achievementPoints = 500,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Elwynn Forest"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "After 100 deaths in Elwynn, local humans are painting themselves green and practicing their 'zug zug'! Goldshire Inn's new special: 'Reroll Horde, Get Free Hearthstone to Durotar.' Even Marshal Dughan is considering a career in Orgrimmar."
}, {
    id = "general_zone_duskwood",
    title = "Darkshire Destroyer",
    description = "Eliminate 100 players in Duskwood",
    iconID = 236757,
    achievementPoints = 500,
    condition = function(playerStats)
        return (playerStats.zoneKills and playerStats.zoneKills["Duskwood"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The Night Watch counted 100 fresh corpses and decided to rename Darkshire to 'Deadshire'! Mor'Ladim is feeling professionally threatened, and Stiches filed for unemployment."
}, -- Total Kills Achievements
{
    id = "kills_total_1",
    title = "Body Count Rising",
    description = "Slay 500 players in total",
    iconID = 236399, -- spell_shadow_shadowfury
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 bodies dropped! Barrens chat has already moved on to debating whether you’re a bot, a multiboxer, or just deeply unhinged."
}, {
    id = "kills_total_2",
    title = "Graveyard Entrepreneur",
    description = "Slay 1000 players in total",
    iconID = 237542,
    achievementPoints = 100,
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "1000 kills! Spirit Healers are now offering you a commission for each body you send their way. The local gravediggers have named their shovels after you."
}, {
    id = "kills_total_3",
    title = "Death Incorporated",
    description = "Slay 3000 players in total",
    iconID = 132205,
    achievementPoints = 250,
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 3000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "3,000 confirmed kills! Even Mankrik’s wife had better odds of survival."
}, -- Unique Player Kills Achievements
{
    id = "kills_unique_1",
    title = "Variety Slayer",
    description = "Defeat 400 unique players",
    iconID = 133789,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "400 different players have fallen to you. At this point, you’re less of a PvPer and more of an extinction event. Azeroth is running out of fresh faces, and you’re the reason why."
}, {
    id = "kills_unique_2",
    title = "Equal Opportunity Executioner",
    description = "Defeat 800 unique players",
    iconID = 133787,
    achievementPoints = 100,
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 800
    end,
    unlocked = false,
    completedDate = nil,
    subText = "800 unique victims and counting! Players are now selling 'I Survived [YOUR NAME]' t-shirts - except none of them actually survived."
}, {
    id = "kills_unique_3",
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
    id = "race_human_0",
    title = "Human Error",
    description = "Eliminate 100 Humans",
    iconID = 236447,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Humans dispatched! Their racial ability 'Every Man for Himself' should really be called 'Every Man for the Graveyard.' So much for human ingenuity."
}, {
    id = "race_human_1",
    title = "Human Resources",
    description = "Eliminate 250 Humans",
    iconID = 134167,
    achievementPoints = 25,
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
    achievementPoints = 50,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Humans down! They picked the ‘best PvP race’ for the racial bonuses but forgot to read the part about positioning and cooldowns."
}, {
    id = "race_human_3",
    title = "Uniqueness",
    description = "Eliminate 750 Humans",
    iconID = 133730,
    achievementPoints = 75,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Human"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Humans permanently retired from Azeroth! The most basic, uninspired race choice in gaming history. These generic NPCs rolled Human because the character creation screen was 'too overwhelming' and they couldn't be bothered to scroll down. Half of them are definitely bots farming gold, the other half might as well be with their keyboard-turning skills. They all picked the 'optimal PvE race' based on some min-max guide and they thought they were 'playing the meta' but ended up being the punchline."
},

-- Night Elf Achievements
{
    id = "race_nightelf_0",
    title = "Moonlight Massacre",
    description = "Eliminate 100 Night Elves",
    iconID = 236449,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Night Elves slain! Half were dudes with 'Illidan' in their names trying to dual-wield everything, the other half were female characters made by players who just discovered hormones. Their deaths were as dramatic as their /dance animations. Time to let go of that purple dream, boys—Tyrande's not checking your DMs."
}, {
    id = "race_nightelf_1",
    title = "Shadowmeld Won't Save You",
    description = "Eliminate 250 Night Elves",
    iconID = 134162,
    achievementPoints = 25,
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
    achievementPoints = 50,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Night Elf"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Night Elf hippies permanently recycled back to nature! These Whole Foods shopping, kombucha brewing, crystal-healing enthusiasts thought their organic armor and free-range weapons would save them. They were too busy forming drum circles and protesting Goblin deforestation to notice your approach. Their last words were 'Namaste... in the graveyard.' Turns out their carbon footprint is now zero - just like their kill/death ratio."
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
    id = "race_dwarf_0",
    title = "Mumble rap",
    description = "Eliminate 100 Dwarves",
    iconID = 236443,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Dwarf"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Dwarves hammered down! These walking Scottish stereotypes died mumbling something that might have been a battle cry or just ordering another ale—nobody could understand a word through that accent. Next time they'll think twice before typing 'AYE LADDIE!' in every chat channel."
}, {
    id = "race_dwarf_1",
    title = "Short Term Solution",
    description = "Eliminate 250 Dwarves",
    iconID = 134160,
    achievementPoints = 25,
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
    achievementPoints = 50,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Dwarf"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Snow White and the 500 Dead Dwarfs! Not even Disney magic could save this tragic tale. The remaining dwarfs changed their names to 'Corpsey,' 'Deady,' 'Respawny,' 'Campy,' 'Ganky,' 'Ragey,' and 'Doc' (who rerolled a Priest). Mining productivity has dropped 70%, but beard wax sales plummeted 100%."
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
    id = "race_gnome_0",
    title = "Lawn Ornament Collector",
    description = "Eliminate 100 Gnomes",
    iconID = 236445,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Gnome"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Gnomes stepped on! All their engineering gadgets failed when they needed them most. At least they make cute decorations for your kill count."
}, {
    id = "race_gnome_1",
    title = "Pest Control",
    description = "Eliminate 250 Gnomes",
    iconID = 134165,
    achievementPoints = 25,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Gnome"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Gnomes punted out of existence! Their last words? 'Size doesn’t matter!' Their respawn timer says otherwise. So do their wifes."
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
    id = "race_orc_0",
    title = "Orc Slayer",
    description = "Eliminate 100 Orcs",
    iconID = 236451,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Orc"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Orcs sent to meet their ancestors! Their blood fury only made your attacks hurt more. So much for orcish resilience when faced with your wrath."
}, {
    id = "race_orc_1",
    title = "Green Peace",
    description = "Eliminate 250 Orcs",
    iconID = 134171,
    achievementPoints = 25,
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
    achievementPoints = 50,
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
    id = "race_undead_0",
    title = "Re-dead",
    description = "Eliminate 100 Undead",
    iconID = 236457,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Undead"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Undead returned to their graves! Turns out being already dead doesn't make you immune to a second death. Will of the Forsaken? More like Will to Respawn."
}, {
    id = "race_undead_1",
    title = "Double Dead",
    description = "Eliminate 250 Undead",
    iconID = 134180,
    achievementPoints = 25,
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
    achievementPoints = 50,
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
    id = "race_troll_0",
    title = "Troll Hunter",
    description = "Eliminate 100 Trolls",
    iconID = 236455,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Trolls made to stay dead! Their regeneration couldn't keep up with your damage output. The Darkspear tribe is sending angry letters about their population decline."
}, {
    id = "race_troll_1",
    title = "Voodoo Venue Closed",
    description = "Eliminate 250 Trolls",
    iconID = 134178,
    achievementPoints = 25,
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
    achievementPoints = 50,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Troll"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 trolls slain! Just like the keyboard warriors who play them—they talked big in forums but fell silent in actual combat. These Reddit moderators and Twitter reply-guys picked Trolls because they thought it was their spirit animal. They spammed 'git gud' to newbies while getting absolutely destroyed by you. The irony of trolls getting trolled is not lost on the rest of the server. Their abandoned forum accounts are now collecting dust just like their corpses."
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
    id = "race_tauren_0",
    title = "Sacred Cow",
    description = "Eliminate 100 Tauren",
    iconID = 236453,
    achievementPoints = 10,
    condition = function(playerStats)
        local _, raceData = PSC_CalculateBarChartStatistics()
        return (raceData["Tauren"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Tauren sent to the great plains in the sky! Those war stomps were no match for your superior combat skills. The Earth Mother has filed a complaint about your treatment of her children."
}, {
    id = "race_tauren_1",
    title = "Biggest Hitbox, Biggest Target",
    description = "Eliminate 250 Tauren",
    iconID = 134175,
    achievementPoints = 25,
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
    achievementPoints = 50,
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
    id = "kills_guild",
    title = "Guild Drama Generator",
    description = "Eliminate 500 guild members",
    iconID = 134473,
    achievementPoints = 50,
    condition = function(playerStats)
        local _, _, _, _, _, _, guildStatusData = PSC_CalculateBarChartStatistics()
        return (guildStatusData["In Guild"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 so-called 'guildmates' slaughtered! Turns out, that guild tag above their heads didn’t make them any less squishy. Maybe they should try a PvE guild—less world PvP, more coping in raid chat."
}, {
    id = "kills_guildless",
    title = "Lone Wolf Hunter",
    description = "Eliminate 500 guildless players",
    iconID = 132203,
    achievementPoints = 50,
    condition = function(playerStats)
        local _, _, _, _, _, _, guildStatusData = PSC_CalculateBarChartStatistics()
        return (guildStatusData["No Guild"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Sent 500 'social anxiety' players back to retail! Their 'I don't need a guild to play' attitude didn't help against your killing spree. At least they didn't have to explain their deaths in guild chat."
}, {
    id = "kills_grey_level",
    title = "Teach them young",
    description = "Eliminate 100 grey-level players",
    iconID = 134435,
    achievementPoints = 10,
    condition = function(playerStats)
        return PSC_CalculateGreyKills() >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "It ain't much but it's honest work!"
}, -- Kill Streak Achievements
{
    id = "kills_streak_25",
    title = "Serial Killer",
    description = "Achieve a 25-player kill streak",
    iconID = 133728,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 25
    end,
    unlocked = false,
    completedDate = nil,
    subText = "25 players deleted in a row! The graveyard is installing a '[YOUR NAME] Express Lane' with a self-checkout option."
},
{
    id = "kills_streak_50",
    title = "Crime Scene",
    description = "Achieve a 50-player kill streak",
    iconID = 133730,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 consecutive kills! Azeroth's investigators are gathering evidence, but all the witnesses keep mysteriously disappearing."
},
{
    id = "kills_streak_75",
    title = "Mass Extinction",
    description = "Achieve a 75-player kill streak",
    iconID = 133731,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 75
    end,
    unlocked = false,
    completedDate = nil,
    subText = "75 kills without dying? Players are filing tickets claiming you're hacking. Blizzard responded: 'No, they're just that good.'"
},
{
    id = "kills_streak_100",
    title = "TRIPLE D!!!",
    description = "Achieve a 100-player kill streak",
    iconID = 132734,
    achievementPoints = 100,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You've killed more players than some indie games have sales. Enemy raid leaders reference you like you're Voldemort — 'He-Who-Wipes-Raid-Groups.'' Even your local WiFi provider flagged you as a DDoS threat."
},
{
    id = "kills_streak_125",
    title = "PvP Plague",
    description = "Achieve a 125-player kill streak",
    iconID = 136123,
    achievementPoints = 125,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 125
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You're not a player anymore—you're a server-wide debuff. Whole zones avoid you like it's patch day. 125 kills and not a single scratch? That’s not PvP. That’s population control."
},
{
    id = "kills_streak_150",
    title = "Fine Wine",
    description = "Achieve a 150-player kill streak",
    iconID = 132789,
    achievementPoints = 150,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 150
    end,
    unlocked = false,
    completedDate = nil,
    subText = "150 uninterrupted kills! You're not just killing players—you're killing server populations. Like a fine wine, your murder spree only improves with time."
},
{
    id = "kills_streak_175",
    title = "Unstoppable Force",
    description = "Achieve a 175-player kill streak",
    iconID = 133050,
    achievementPoints = 175,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 175
    end,
    unlocked = false,
    completedDate = nil,
    subText = "175 bodies and counting! Like the legendary Alterac Valley weapon, you've become a force of nature—slow, powerful, and absolutely devastating. The Immovable Object has finally met its match, and it's your kill streak. Players have started putting 'killed by [YOUR NAME]' in their forum signatures as a badge of honor."
},
{
    id = "kills_streak_200",
    title = "/flex",
    description = "Achieve a 200-player kill streak",
    iconID = 236370,
    achievementPoints = 200,
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 unbroken kills! Your /flex emote now causes a 10-yard fear. Even raid bosses check their aggro tables when you log in. Blizzard added a new GM macro: /who [YOUR NAME] – for threat assessment."
},
{
    id = "kills_multi_3",
    title = "Triple Kill!",
    description = "Get 3 kills in a single combat",
    iconID = 236330,
    achievementPoints = 25,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 3
    end,
    unlocked = false,
    completedDate = nil,
    subText = "ACE! Three champions... er, players... fell to your blade in quick succession. The enemy team is crying 'nerf [YOUR NAME]' in all chat. Your Summoner Score is rising!"
},
{
    id = "kills_multi_4",
    title = "QUADRA KILL!",
    description = "Get 4 kills in a single combat",
    iconID = 236341,
    achievementPoints = 50,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 4
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The crowd goes wild as you secure your fourth elimination! 'GG [YOUR NAME] diff' echoes across Azeroth. The enemy team is calling for a surrender vote while spamming 'Report jungler no ganks' in chat."
},
{
    id = "kills_multi_5",
    title = "PENTAKILL!!",
    description = "Get 5 kills in a single combat",
    iconID = 236383,
    achievementPoints = 75,
    condition = function(playerStats)
        return (playerStats.highestMultiKill or 0) >= 5
    end,
    unlocked = false,
    completedDate = nil,
    subText = "LEGENDARY! You just went full Faker on these noobs! 'GG EZ' has never been more appropriate. The enemy team pressed Alt + F4 simultaneously and uninstalled the game. Your MVP status is unrivaled, and Riot Games is sending you a cease and desist letter for being too OP."
},

-- Most Killed Player Achievement
{
    id = "kills_favorite_target",
    title = "Personal Vendetta",
    description = "Kill the same player 10 times",
    iconID = 136168,  -- Red target icon
    achievementPoints = 25,
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
{
    id = "kills_big_game",
    title = "Big Game Hunter",
    description = "Eliminate 30 level ?? players",
    iconID = 135614,
    achievementPoints = 250,
    condition = function(playerStats)
        local _, _, _, _, _, levelData = PSC_CalculateBarChartStatistics()
        return (levelData["??"] or 0) >= 30
    end,
    unlocked = false,
    completedDate = nil,
    subText = "30 level ?? enemies deleted! While lesser mortals flee at the sight of a ?? mark, you hunt them for sport. These walking raid bosses thought their level advantage made them untouchable and overconfident — until they met [YOUR NAME]."
},
}

local function GetPlayerName()
    local playerName = UnitName("player")
    return playerName or "You"
end

local function PersonalizeText(text, playerName)
    if not text then return "" end

    if type(text) == "function" then
        text = text()
    end

    -- Add this check to prevent nil playerName
    local name = playerName or GetPlayerName() or "You"

    return text:gsub("%[YOUR NAME%]", name)
end

function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}
    local playerName = GetPlayerName()
    local achievementsUnlocked = 0

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M") -- Set completion date

            -- Save achievement data to PSC_DB using the DataStorage.lua function
            PSC_SaveAchievement(achievement.id, achievement.completedDate, achievement.achievementPoints)

            -- Personalize description
            local personalizedDescription = PersonalizeText(achievement.description, playerName)

            -- Also personalize the subText if it exists
            local personalizedSubText = achievement.subText
            if type(personalizedSubText) == "string" then
                personalizedSubText = PersonalizeText(personalizedSubText, playerName)
            end

            -- Show popup
            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = personalizedDescription,
                subText = personalizedSubText,
                rarity = achievement.rarity
            })

            achievementsUnlocked = achievementsUnlocked + 1
        end
    end

    -- Save the updated achievement points at the end
    self:SaveAchievementPoints()

    return achievementsUnlocked
end

local function GetRarityFromPoints(points)
    if points >= 250 then
        return "legendary"
    elseif points >= 75 then
        return "epic"
    elseif points >= 50 then
        return "rare"
    elseif points >= 25 then
        return "uncommon"
    else
        return "common"
    end
end

for _, achievement in ipairs(AchievementSystem.achievements) do
    if not achievement.rarity then
        achievement.rarity = GetRarityFromPoints(achievement.achievementPoints or 10)
    end
end

function AchievementSystem:SaveAchievementPoints()
    -- Calculate and store the total achievement points
    local totalPoints = 0

    if not PSC_DB.Achievements then
        PSC_DB.Achievements = {}
    end

    -- Store achievements with their point values directly in saved variables
    for _, achievement in ipairs(self.achievements) do
        local achievementID = achievement.id

        if PSC_DB.Achievements[achievementID] and PSC_DB.Achievements[achievementID].unlocked then
            -- If this achievement is unlocked, add its points
            totalPoints = totalPoints + (achievement.achievementPoints or 0)

            -- Store the points value in the achievement data
            PSC_DB.Achievements[achievementID].points = achievement.achievementPoints or 0
        end
    end

    -- Store the total for quick access
    PSC_DB.TotalAchievementPoints = totalPoints

    return totalPoints
end

function AchievementSystem:Initialize()
    -- Restore unlocked state from saved variables
    if PSC_DB.Achievements then
        for achievementID, achievementData in pairs(PSC_DB.Achievements) do
            for i, achievement in ipairs(self.achievements) do
                if achievement.id == achievementID and achievementData.unlocked then
                    self.achievements[i].unlocked = true
                    self.achievements[i].completedDate = achievementData.completedDate
                end
            end
        end
    end

    -- Calculate initial achievement points
    self:SaveAchievementPoints()
end

-- Add this to your addon's initialization
C_Timer.After(1, function()
    if PVPSC and PVPSC.AchievementSystem then
        PVPSC.AchievementSystem:Initialize()
    end
end)
