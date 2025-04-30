local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem


PSC_GrayLevelThreshods = {
    [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0,
    [7] = 1, [8] = 2, [9] = 3, [10] = 4, [11] = 5, [12] = 6,
    [13] = 7, [14] = 8, [15] = 9, [16] = 10, [17] = 11, [18] = 12,
    [19] = 13, [20] = 13, [21] = 14, [22] = 15, [23] = 16, [24] = 17,
    [25] = 18, [26] = 19, [27] = 20, [28] = 21, [29] = 22, [30] = 22,
    [31] = 23, [32] = 24, [33] = 25, [34] = 26, [35] = 27, [36] = 28,
    [37] = 29, [38] = 30, [39] = 31, [40] = 31, [41] = 32, [42] = 33,
    [43] = 34, [44] = 35, [45] = 35, [46] = 36, [47] = 37, [48] = 38,
    [49] = 39, [50] = 39, [51] = 40, [52] = 41, [53] = 42, [54] = 43,
    [55] = 43, [56] = 44, [57] = 45, [58] = 46, [59] = 47, [60] = 47
}


function PSC_ReplacePlayerNamePlaceholder(text, playerName, achievement)
    if not text then return "" end

    if type(text) == "function" then
        text = text(achievement)
    end

    local name = playerName or UnitName("player")
    text = text:gsub("%[YOUR NAME%]", name)
    return text
end


function PSC_GetStatsForAchievements()
    local charactersToProcess = {}
    local currentCharacterKey = PSC_GetCharacterKey()
    charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]

    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData = PSC_CalculateBarChartStatistics(charactersToProcess)
    local summaryStats = PSC_CalculateSummaryStatistics(charactersToProcess)
    local stats = {
        classData = classData,
        raceData = raceData,
        genderData = genderData,
        unknownLevelClassData = unknownLevelClassData,
        zoneData = zoneData,
        levelData = levelData,
        guildStatusData = guildStatusData,
        totalKills = summaryStats.totalKills,
        uniqueKills = summaryStats.uniqueKills,
        highestKillStreak = summaryStats.highestKillStreak,
        highestMultiKill = summaryStats.highestMultiKill,
        mostKilledPlayer = summaryStats.mostKilledPlayer,
        mostKilledCount = summaryStats.mostKilledCount
    }

    return stats
end


function AchievementSystem:CheckAchievements()
    local playerName = UnitName("player")
    local achievementsUnlocked = 0
    local stats = PSC_GetStatsForAchievements()
    local characterKey = PSC_GetCharacterKey()

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(achievement, stats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M")

            PSC_SaveAchievement(achievement.id, achievement.completedDate, achievement.achievementPoints)

            local personalizedDescription = PSC_ReplacePlayerNamePlaceholder(achievement.description, playerName,
                achievement)
            local personalizedTitle = PSC_ReplacePlayerNamePlaceholder(achievement.title, playerName, achievement)
            local personalizedSubText = PSC_ReplacePlayerNamePlaceholder(achievement.subText, playerName, achievement)

            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = personalizedTitle,
                description = personalizedDescription,
                subText = personalizedSubText,
                rarity = achievement.rarity
            })

            achievementsUnlocked = achievementsUnlocked + 1
        end
    end

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
        achievement.rarity = GetRarityFromPoints(achievement.achievementPoints)
    end
end

function AchievementSystem:SaveAchievementPoints()
    local characterKey = PSC_GetCharacterKey()
    local totalPoints = 0

    if not PSC_DB.CharacterAchievements then
        PSC_InitializeAchievementDataStructure()
    end

    if not PSC_DB.CharacterAchievements[characterKey] then
        PSC_DB.CharacterAchievements[characterKey] = {}
    end

    for _, achievement in ipairs(self.achievements) do
        local achievementID = achievement.id

        if PSC_DB.CharacterAchievements[characterKey][achievementID] and
           PSC_DB.CharacterAchievements[characterKey][achievementID].unlocked then
            totalPoints = totalPoints + achievement.achievementPoints
            PSC_DB.CharacterAchievements[characterKey][achievementID].points = achievement.achievementPoints
        end
    end

    PSC_DB.CharacterAchievementPoints[characterKey] = totalPoints

    return totalPoints
end

function AchievementSystem:LoadAchievementCompletedData()
    local characterKey = PSC_GetCharacterKey()

    if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[characterKey] then
        for achievementID, achievementData in pairs(PSC_DB.CharacterAchievements[characterKey]) do
            for i, achievement in ipairs(self.achievements) do
                if achievement.id == achievementID and achievementData.unlocked then
                    self.achievements[i].unlocked = true
                    self.achievements[i].completedDate = achievementData.completedDate
                end
            end
        end
    end

    self:SaveAchievementPoints()
end

C_Timer.After(1, function()
    if PVPSC and PVPSC.AchievementSystem then
        PVPSC.AchievementSystem:LoadAchievementCompletedData()
    end
end)
