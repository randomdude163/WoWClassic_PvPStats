local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Define all achievements here
AchievementSystem.achievements = {
    {
        id = "id_1",
        title = "HOLY MOLY!",
        description = "Slay 500 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_2",
        title = "Shadow Hunter",
        description = "Defeat 300 Priests",
        iconID = 136207, -- spell-shadow-shadowwordpain
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 300
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_3",
        title = "Warrior Slayer",
        description = "Eliminate 1000 Warriors",
        iconID = 132355, -- ability-warrior-charge
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 1000
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_4",
        title = "Mage Crusher",
        description = "Defeat 400 Mages",
        iconID = 135846, -- spell-frost-frostbolt02
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 400
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_5",
        title = "Rogue Hunter",
        description = "Uncover and defeat 250 Rogues",
        iconID = 132320, -- ability-rogue-sinisterstrike
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_6",
        title = "Warlock Nemesis",
        description = "Banish 350 Warlocks",
        iconID = 136197, -- spell-shadow-shadowbolt
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 350
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_7",
        title = "Wife Beater",
        description = "Defeat 100 female characters",
        iconID = 132938, -- spell-holy-powerwordshield
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_8",
        title = "Gentleman's Bane",
        description = "Defeat 100 male characters",
        iconID = 132333, -- ability-warrior-bladestorm
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil
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