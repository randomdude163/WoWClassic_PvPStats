local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Define all achievements here
AchievementSystem.achievements = {
    -- Paladin Achievements
    {
        id = "paladin_1",
        title = "Holy Moly",
        description = "Slay 100 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Paladins can be tough opponents with their healing abilities and plate armor. Take down 100 of these holy warriors to earn this achievement."
    },
    {
        id = "paladin_2",
        title = "Holy Moly Epic",
        description = "Slay 500 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Your reputation as a Paladin hunter grows. Defeat 500 Paladins to truly establish yourself as their nemesis."
    },
    {
        id = "paladin_3",
        title = "Holy Moly Legendary",
        description = "Slay 1000 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 1000
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The ultimate achievement for Paladin slayers. With 1000 Paladin eliminations, you've become a walking nightmare for anyone wielding the Light."
    },

    -- Priest Achievements
    {
        id = "priest_1",
        title = "Shadow Hunter",
        description = "Defeat 100 Priests",
        iconID = 136207, -- spell-shadow-shadowwordpain
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Priests may be healers, but they're no match for your combat skills. Eliminate 100 Priests to earn this achievement."
    },
    {
        id = "priest_2",
        title = "Shadow Hunter Epic",
        description = "Defeat 300 Priests",
        iconID = 136207, -- spell-shadow-shadowwordpain
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 300
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Your hatred for the cloth-wearing healers burns with intensity. Take down 300 Priests to prove your dedication."
    },
    {
        id = "priest_3",
        title = "Shadow Hunter Legendary",
        description = "Defeat 600 Priests",
        iconID = 136207, -- spell-shadow-shadowwordpain
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 600
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Neither Light nor Shadow can save them from you. With 600 Priest kills, you've become the ultimate Priest hunter."
    },

    -- Warrior Achievements
    {
        id = "warrior_1",
        title = "Warrior Slayer",
        description = "Eliminate 200 Warriors",
        iconID = 132355, -- ability-warrior-charge
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 200
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Warriors are everywhere on the battlefield. Show them who's boss by taking down 200 of these plate-wearers."
    },
    {
        id = "warrior_2",
        title = "Warrior Slayer Epic",
        description = "Eliminate 500 Warriors",
        iconID = 132355, -- ability-warrior-charge
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 500
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The battlefield is littered with the armor of Warriors you've defeated. Add 500 more to your tally."
    },
    {
        id = "warrior_3",
        title = "Warrior Slayer Legendary",
        description = "Eliminate 1000 Warriors",
        iconID = 132355, -- ability-warrior-charge
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 1000
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 1000 Warrior kills, you've become a legend. Even the mightiest Warriors tremble at the mention of your name."
    },

    -- Mage Achievements
    {
        id = "mage_1",
        title = "Mage Hunter",
        description = "Defeat 100 Mages",
        iconID = 135846, -- spell-frost-frostbolt02
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Mages may control the elements, but they can't control you. Defeat 100 of these spell-slingers."
    },
    {
        id = "mage_2",
        title = "Mage Crusher Epic",
        description = "Defeat 400 Mages",
        iconID = 135846, -- spell-frost-frostbolt02
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 400
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Fire, Frost, or Arcane - it doesn't matter to you. Take down 400 Mages to show your mastery."
    },
    {
        id = "mage_3",
        title = "Mage Crusher Legendary",
        description = "Defeat 800 Mages",
        iconID = 135846, -- spell-frost-frostbolt02
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 800
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 800 Mage kills, you've become immune to their spells through sheer experience. The arcane arts hold no mystery for you."
    },

    -- Rogue Achievements
    {
        id = "rogue_1",
        title = "Rogue Spotter",
        description = "Uncover and defeat 100 Rogues",
        iconID = 132320, -- ability-rogue-sinisterstrike
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Stealth won't save them from your keen senses. Find and eliminate 100 Rogues."
    },
    {
        id = "rogue_2",
        title = "Rogue Hunter Epic",
        description = "Uncover and defeat 250 Rogues",
        iconID = 132320, -- ability-rogue-sinisterstrike
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The shadows can't hide them from you anymore. Take down 250 Rogues to prove your vigilance."
    },
    {
        id = "rogue_3",
        title = "Rogue Hunter Legendary",
        description = "Uncover and defeat 500 Rogues",
        iconID = 132320, -- ability-rogue-sinisterstrike
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 500
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 500 Rogue eliminations, you've become the nightmare that haunts their dreams. No place to hide, no tricks left to play."
    },

    -- Warlock Achievements
    {
        id = "warlock_1",
        title = "Warlock Banisher",
        description = "Banish 100 Warlocks",
        iconID = 136197, -- spell-shadow-shadowbolt
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Those who dabble in dark magic must face justice. Eliminate 100 Warlocks to begin your crusade."
    },
    {
        id = "warlock_2",
        title = "Warlock Nemesis Epic",
        description = "Banish 350 Warlocks",
        iconID = 136197, -- spell-shadow-shadowbolt
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 350
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The demons they summon cannot save them from your wrath. Defeat 350 Warlocks to continue your mission."
    },
    {
        id = "warlock_3",
        title = "Warlock Nemesis Legendary",
        description = "Banish 700 Warlocks",
        iconID = 136197, -- spell-shadow-shadowbolt
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 700
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 700 Warlock kills, you've become a cleansing flame against the darkness. Your legend strikes fear into the hearts of fel-wielders everywhere."
    },

    -- Female Gender Achievement
    {
        id = "gender_female_1",
        title = "Ladies' Bane",
        description = "Defeat 50 female characters",
        iconID = 132938, -- spell-holy-powerwordshield
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 50
        end,
        unlocked = false,
        completedDate = nil,
        subText = "On the battlefield, you show no favoritism. Defeat 50 female characters to earn this achievement."
    },
    {
        id = "gender_female_2",
        title = "Ladies' Bane Epic",
        description = "Defeat 100 female characters",
        iconID = 132938, -- spell-holy-powerwordshield
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Your reputation for dispatching female opponents has grown. Eliminate 100 to prove your equal-opportunity approach to combat."
    },
    {
        id = "gender_female_3",
        title = "Ladies' Bane Legendary",
        description = "Defeat 200 female characters",
        iconID = 132938, -- spell-holy-powerwordshield
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 200
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 200 female character defeats, you've shown that chivalry has no place on the battlefield. Victory knows no gender."
    },

    -- Male Gender Achievement
    {
        id = "gender_male_1",
        title = "Gentleman's Bane",
        description = "Defeat 50 male characters",
        iconID = 132333, -- ability-warrior-bladestorm
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 50
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Male characters often dominate the battlefields. Take down 50 of them to start making your mark."
    },
    {
        id = "gender_male_2",
        title = "Gentleman's Bane Epic",
        description = "Defeat 100 male characters",
        iconID = 132333, -- ability-warrior-bladestorm
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Continue your campaign against male opponents by defeating 100 of them in battle."
    },
    {
        id = "gender_male_3",
        title = "Gentleman's Bane Legendary",
        description = "Defeat 200 male characters",
        iconID = 132333, -- ability-warrior-bladestorm
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 200
        end,
        unlocked = false,
        completedDate = nil,
        subText = "With 200 male character defeats, you've carved out a fearsome reputation. The battlefields echo with tales of your prowess."
    }
}

-- Function to check achievements and show popup if newly unlocked
function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M") -- Set completion date
            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = achievement.description
            })
        end
    end
end