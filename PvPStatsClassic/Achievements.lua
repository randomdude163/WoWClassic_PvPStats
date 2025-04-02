local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Define all achievements here
AchievementSystem.achievements = { -- Paladin Achievements
{
    id = "paladin_1",
    title = "Bubble Popper",
    description = "Slay 100 Paladins",
    iconID = 626003,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Divine Shield bubbles popped! Turns out, the Light doesn't save you when I'm around."
}, {
    id = "paladin_2",
    title = "Bubble Heartbreaker",
    description = "Slay 500 Paladins",
    iconID = 135962,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Paladins discovered their Hearthstone was on cooldown. The Light abandoned them faster than their guild after a wipe."
}, {
    id = "paladin_3",
    title = "The Light Extinguisher",
    description = "Slay 1000 Paladins",
    iconID = 133176,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "1000 holy warriors sent to meet their maker! The churches are empty, plate armor is on clearance sale, and bubble bath sales have plummeted."
}, -- Priest Achievements
{
    id = "priest_1",
    title = "Faith Healer Killer",
    description = "Defeat 100 Priests",
    iconID = 626004,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Priests discovered healing can't fix a severed head. They've got a holy problem that prayer won't solve!"
}, {
    id = "priest_2",
    title = "Scripture Shreader",
    description = "Defeat 300 Priests",
    iconID = 136221,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "300 Priests deleted! Churches are hiring bouncers and confession booths now come with panic buttons."
}, {
    id = "priest_3",
    title = "Religious Persecution",
    description = "Defeat 600 Priests",
    iconID = 136224,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 holy rollers permanently laid to rest! The seminary is empty and religious texts now include a chapter titled 'What to do when you see [YOUR NAME]'."
}, -- Druid Achievements
{
    id = "druid_1",
    title = "Tree Trimmer",
    description = "Take down 100 Druids",
    iconID = 625999,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Druids chopped down! Shape-shifting doesn't help when all forms end up as a corpse."
}, {
    id = "druid_2",
    title = "Animal Control",
    description = "Take down 300 Druids",
    iconID = 236167,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "300 Druids exterminated! Cat form, bear form, dead form – you've seen them all. PETA has issued a statement."
}, {
    id = "druid_3",
    title = "Nature's Nemesis",
    description = "Take down 600 Druids",
    iconID = 132138,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Druids composted! The Cenarion Circle has declared you a natural disaster and Moonglade now has your picture at all entrances."
}, -- Shaman Achievements
{
    id = "shaman_1",
    title = "Totem Kicker",
    description = "Defeat 100 Shamans",
    iconID = 626006,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Shamans discovered the elements don't answer when they're dead. You've kicked more totems than a clumsy tauren!"
}, {
    id = "shaman_2",
    title = "Spirit Breaker",
    description = "Defeat 300 Shamans",
    iconID = 237589,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "300 Shamans sent to commune with their ancestors! The elements have filed a restraining order against you."
}, {
    id = "shaman_3",
    title = "Element Bender",
    description = "Defeat 600 Shamans",
    iconID = 136088,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Shamans permanently grounded! Totem vendors are going bankrupt and the spirit world is overloaded with complaints about you."
}, -- Hunter Achievements
{
    id = "hunter_1",
    title = "Pet Cemetery Director",
    description = "Take down 100 Hunters",
    iconID = 626000, -- ability_marksmanship
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Hunters become the hunted! Their pets are still waiting for them to respawn... poor little things."
}, {
    id = "hunter_2",
    title = "Feign Death Verifier",
    description = "Take down 300 Hunters",
    iconID = 132208,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "300 Hunters learned Feign Death doesn't work when you're actually dead. The pet treat market has crashed!"
}, {
    id = "hunter_3",
    title = "Apex Predator",
    description = "Take down 600 Hunters",
    iconID = 132329,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Hunters eliminated! Pet stables are empty, bow strings are untensed, and 'How to survive [YOUR NAME]' is now standard reading at hunter training."
}, -- Warrior Achievements
{
    id = "warrior_1",
    title = "Rage Drain",
    description = "Eliminate 200 Warriors",
    iconID = 626008,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 Warriors rage-quit the battlefield! Their tantrums were almost as entertaining as their death animations."
}, {
    id = "warrior_2",
    title = "Plate Recycler",
    description = "Eliminate 500 Warriors",
    iconID = 132342,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Warriors worth of scrap metal collected! The goblin recycling center named you Employee of the Month."
}, {
    id = "warrior_3",
    title = "The Real Warrior",
    description = "Eliminate 1000 Warriors",
    iconID = 132346,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "1000 so-called 'Warriors' demolished! The armor vendor is having a going-out-of-business sale and the rage management support group is at full capacity."
}, -- Mage Achievements
{
    id = "mage_1",
    title = "Arcane Exterminator",
    description = "Defeat 100 Mages",
    iconID = 626001,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Mages turned into sheep food! Turns out, fireballs aren't so hot when you're lying face down in the dirt."
}, {
    id = "mage_2",
    title = "Frost Melter",
    description = "Defeat 400 Mages",
    iconID = 135812,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "400 Mages deleted! Ice Block sales have plummeted and the Teleport spell now comes with a warning label: 'May not work when [YOUR NAME] is nearby.'"
}, {
    id = "mage_3",
    title = "The Anti-Mage",
    description = "Defeat 800 Mages",
    iconID = 135808,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 800
    end,
    unlocked = false,
    completedDate = nil,
    subText = "800 spell-slingers sent to the shadow realm! The Kirin Tor has issued a travel advisory and magical colleges now offer a course called 'How to Avoid [YOUR NAME].'"
}, -- Rogue Achievements
{
    id = "rogue_1",
    title = "Stealth Detector",
    description = "Uncover and defeat 100 Rogues",
    iconID = 626005,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Rogues discovered invisibility isn't invincibility! Their last words were usually 'How did you see me?!'"
}, {
    id = "rogue_2",
    title = "Vanish This!",
    description = "Uncover and defeat 250 Rogues",
    iconID = 132308,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Rogues learned their Vanish button has a fatal delay. The dagger market is experiencing a surplus!"
}, {
    id = "rogue_3",
    title = "Backstabber Backstabber",
    description = "Uncover and defeat 500 Rogues",
    iconID = 135975,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Rogues permanently stealthed! The Shady Dealer's Union has declared bankruptcy and 'How To Avoid [YOUR NAME]' is now required reading in Rogue training."
}, -- Warlock Achievements
{
    id = "warlock_1",
    title = "Demon Dispatcher",
    description = "Banish 100 Warlocks",
    iconID = 626007,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Warlocks discovered their soul stones were just pretty rocks. Their demons have filed for hazard pay!"
}, {
    id = "warlock_2",
    title = "Soul Harvester",
    description = "Banish 350 Warlocks",
    iconID = 136140,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 350
    end,
    unlocked = false,
    completedDate = nil,
    subText = "350 Warlocks permanently banished! The Burning Legion has started a support group for demons who lost their masters to you."
}, {
    id = "warlock_3",
    title = "The Exorcist",
    description = "Banish 700 Warlocks",
    iconID = 135770,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 700
    end,
    unlocked = false,
    completedDate = nil,
    subText = "700 Warlocks exorcised from Azeroth! Demon pets are forming a union, and the Twisting Nether now has a restraining order against you."
}, -- Female Gender Achievement
{
    id = "gender_female_1",
    title = "Wife Beater",
    description = "Defeat 50 female characters",
    iconID = 132938, -- spell-holy-powerwordshield
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
    iconID = 132938, -- spell-holy-powerwordshield
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 female characters deleted with extreme prejudice. The Ironforge Women's Protection Society has placed a bounty on your head."
}, {
    id = "gender_female_3",
    title = "Wife Beater LEGENDARY",
    description = "Defeat 200 female characters",
    iconID = 132938, -- spell-holy-powerwordshield
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
    iconID = 132333, -- ability-warrior-bladestorm
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 husbands never made it home for dinner. Their wives thank you for the insurance payouts."
}, {
    id = "gender_male_2",
    title = "Widowmaker EPIC",
    description = "Defeat 100 male characters",
    iconID = 132333, -- ability-warrior-bladestorm
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
    iconID = 132333, -- ability-warrior-bladestorm
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
    subText = "500 kills in Redridge! At this point, the Horde is considering annexing the territory and renaming it 'Corpseridge.' The flight master has started charging hazard pay."
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
    subText = "100 players slain in Elwynn Forest! Goldshire Inn has a permanent memorial to your victims, and Stormwind is considering building a wall to keep you out. Even the kobolds are afraid to take your candle."
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
    subText = "100 players sent to permanent darkness in Duskwood! Local undead are holding job fairs due to increased competition. The Night Watch now checks under beds for you instead of monsters."
}, -- Total Kills Achievements
{
    id = "total_kills_1",
    title = "Body Count Rising",
    description = "Slay 500 players in total",
    iconID = 236293, -- spell_shadow_shadowfury
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 players sent to the graveyard. At this rate, the Spirit Healers are considering you for their employee of the month program."
}, {
    id = "total_kills_2",
    title = "Graveyard Entrepreneur",
    description = "Slay 1000 players in total",
    iconID = 135872, -- ability_creature_disease_05
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
    iconID = 136119, -- spell_shadow_deathscream
    condition = function(playerStats)
        return (playerStats.totalKills or 0) >= 3000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "3000 souls harvested! The Lich King himself just sent you a job application. Spirit Healers have unionized just to deal with your workload."
}, -- Unique Player Kills Achievements
{
    id = "unique_kills_1",
    title = "Variety Slayer",
    description = "Defeat 400 unique players",
    iconID = 132368, -- ability_warrior_challange
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "400 different players have met your blade. You're like a murderous butterfly collector, except instead of butterflies, it's players, and instead of collecting, it's... well, you know."
}, {
    id = "unique_kills_2",
    title = "Equal Opportunity Executioner",
    description = "Defeat 800 unique players",
    iconID = 132307, -- ability_warrior_warcry
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 800
    end,
    unlocked = false,
    completedDate = nil,
    subText = "800 unique names in your death ledger! You're not a killer, you're a collector of last moments. Some players now transfer servers when they see you log in."
}, {
    id = "unique_kills_3",
    title = "The Ultimate Black Book",
    description = "Defeat 2400 unique players",
    iconID = 132336, -- ability_warrior_battleshout
    condition = function(playerStats)
        return (playerStats.uniqueKills or 0) >= 2400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "2400 unique souls claimed! At this point, it's easier to list who you HAVEN'T killed. Your name is now used to scare children into eating their vegetables on multiple realms."
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
