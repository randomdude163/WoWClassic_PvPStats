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
    title = "Tree Trimmer",
    description = "Take down 250 Druids",
    iconID = 625999,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Druids chopped down! Shape-shifting doesn't help when all forms end up as a corpse."
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
    title = "Nature's Nemesis",
    description = "Take down 750 Druids",
    iconID = 132138,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Druids returned to nature... permanently! Moonglade installed a warning siren and their travel form is now exclusively 'dead weight'."
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
    subText = "500 Shamans permanently ghost wolfed! The spirit world is experiencing unprecedented immigration levels."
}, {
    id = "shaman_3",
    title = "Element Bender",
    description = "Defeat 750 Shamans",
    iconID = 136088,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 750
    end,
    unlocked = false,
    completedDate = nil,
    subText = "750 Shamans permanently grounded! Totem vendors are going bankrupt and the spirit world is overloaded with complaints about you."
}, -- Hunter Achievements
{
    id = "hunter_1",
    title = "Pet Project",
    description = "Take down 250 Hunters",
    iconID = 626000,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "250 Hunters donated their pets to the shelter! Feign Death wasn't very effective."
}, {
    id = "hunter_2",
    title = "Bad Dog Day",
    description = "Take down 500 Hunters",
    iconID = 132208,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "500 Hunters and their pets had a ruff time! The stable master is running an adoption special."
}, {
    id = "hunter_3",
    title = "Click… No Ammo",
    description = "Take down 750 Hunters",
    iconID = 132329,
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
    subText = "These 500 mages learned that Pyroblast's cast time is longer than their life expectancy! Their last words were 'Just one more second..."
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
    subText = "50 husbands never made it home for dinner. Their wives thank you for the GG (Goblin Greed) insurance payouts."
}, {
    id = "gender_male_2",
    title = "Widowmaker EPIC",
    description = "Defeat 100 male characters",
    iconID = 236448,
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
