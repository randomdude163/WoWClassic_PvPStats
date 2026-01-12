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

function PSC_InitializeGrayKillsCounter()
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]

    -- Calculate once using the existing function
    characterData.GrayKillsCount = PSC_CalculateGrayKills() or 0

    if PSC_Debug then
        print("[PvPStats]: Initialized gray kills counter with " .. characterData.GrayKillsCount .. " kills")
    end
end

-- Helper function to check if a kill is a gray level kill
function PSC_IsGrayLevelKill(playerLevel, targetLevel)
    if not playerLevel or not targetLevel or targetLevel == -1 then
        return false
    end

    -- Get the threshold from our table
    local threshold = PSC_GrayLevelThreshods[playerLevel] or 0

    -- If player's level minus threshold is higher than target's level, it's a gray kill
    local isGrayKill = targetLevel <= threshold
    return isGrayKill
end

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

    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData = PSC_CalculateBarChartStatistics(charactersToProcess)
    local summaryStats = PSC_CalculateSummaryStatistics(charactersToProcess)
    local stats = {
        classData = classData,
        raceData = raceData,
        genderData = genderData,
        unknownLevelClassData = unknownLevelClassData,
        zoneData = zoneData,
        levelData = levelData,
        guildStatusData = guildStatusData,
        guildData = guildData,
        totalKills = summaryStats.totalKills,
        uniqueKills = summaryStats.uniqueKills,
        highestKillStreak = summaryStats.highestKillStreak,
        highestMultiKill = summaryStats.highestMultiKill,
        mostKilledPlayer = summaryStats.mostKilledPlayer,
        mostKilledCount = summaryStats.mostKilledCount,
        totalAchievementPoints = PSC_GetCurrentAchievementPoints(),
        unlockedAchievements = PSC_GetUnlockedAchievementCount()
    }

    return stats
end


function AchievementSystem:CheckAchievements()
    local playerName = UnitName("player")
    local achievementsUnlocked = 0
    local stats = PSC_GetStatsForAchievements()
    local characterKey = PSC_GetCharacterKey()
    local unlockedList = {}

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(achievement, stats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M")

            PSC_SaveAchievement(achievement.id, achievement.completedDate, achievement.achievementPoints)

            local personalizedDescription = PSC_ReplacePlayerNamePlaceholder(achievement.description, playerName, achievement)
            local personalizedTitle = PSC_ReplacePlayerNamePlaceholder(achievement.title, playerName, achievement)
            local personalizedSubText = PSC_ReplacePlayerNamePlaceholder(achievement.subText, playerName, achievement)

            table.insert(unlockedList, {
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

    -- Show popups
    if achievementsUnlocked > 3 then
        -- Print achievements in chat
        print("|cffffffff[PvPStats]|r You have unlocked |cffffff00" .. achievementsUnlocked .. "|r new achievements:")
        for _, achievement in ipairs(unlockedList) do
            print("|cffffff00" .. achievement.title .. "|r: |cffffffff" .. achievement.description .. "|r")
        end

        PVPSC.AchievementPopup:ShowMultipleAchievementsPopup(achievementsUnlocked)
    else
        for _, popupData in ipairs(unlockedList) do
            PVPSC.AchievementPopup:ShowPopup(popupData)
        end
    end

    return achievementsUnlocked
end

local function GetRarityFromPoints(points)
    if points >= 250 then
        return "legendary"
    elseif points >= 100 then
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

function AchievementSystem:GetTotalPossiblePoints()
    local totalPossiblePoints = 0

    for _, achievement in ipairs(self.achievements) do
        if achievement.achievementPoints then
            totalPossiblePoints = totalPossiblePoints + achievement.achievementPoints
        end
    end

    return totalPossiblePoints
end

function AchievementSystem:LoadAchievementCompletedData()
    local characterKey = PSC_GetCharacterKey()

    self:CleanupObsoleteAchievements()

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

function PSC_ShareAchievementInChat(achievement)
    if not achievement or not achievement.unlocked then
        return
    end

    local titleText = type(achievement.title) == "function" and achievement.title(achievement) or achievement.title
    local personalizedTitle = PSC_ReplacePlayerNamePlaceholder(titleText, UnitName("player"), achievement)

    local descText = type(achievement.description) == "function" and achievement.description(achievement) or achievement.description
    local personalizedDesc = PSC_ReplacePlayerNamePlaceholder(descText, UnitName("player"), achievement)

    local shareText = personalizedTitle .. " (" .. personalizedDesc .. ") Completed: " .. achievement.completedDate

    if ChatFrame1EditBox:IsShown() then
        ChatFrame1EditBox:SetText(shareText)
        ChatFrame1EditBox:SetCursorPosition(string.len(shareText))
    else
        ChatFrame1EditBox:Show()
        ChatFrame1EditBox:SetText(shareText)
        ChatFrame1EditBox:SetCursorPosition(string.len(shareText))
        ChatFrame1EditBox:SetFocus()
    end
end

-- Generic function to clean up unlocked achievements that no longer exist in current definitions
function AchievementSystem:CleanupObsoleteAchievements()
    local characterKey = PSC_GetCharacterKey()

    -- Check both possible data structures for achievement storage
    local removedCount = 0

    -- Clean up PSC_DB.CharacterAchievements (the main one being used)
    if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[characterKey] then
        -- Create a lookup table of all current achievement IDs for fast checking
        local currentAchievementIDs = {}
        for _, achievement in ipairs(self.achievements) do
            currentAchievementIDs[achievement.id] = true
        end

        local characterAchievements = PSC_DB.CharacterAchievements[characterKey]

        for achievementId, _ in pairs(characterAchievements) do
            if not currentAchievementIDs[achievementId] then
                -- This achievement ID no longer exists in current definitions
                characterAchievements[achievementId] = nil
                removedCount = removedCount + 1
                if PSC_Debug then
                    PSC_Print("Removed obsolete achievement from CharacterAchievements: " .. achievementId)
                end
            end
        end
    end

    -- Also clean up PSC_DB.PlayerAchievements if it exists (legacy/alternative storage)
    if PSC_DB.PlayerAchievements and PSC_DB.PlayerAchievements[characterKey] then
        -- Create a lookup table of all current achievement IDs for fast checking
        local currentAchievementIDs = {}
        for _, achievement in ipairs(self.achievements) do
            currentAchievementIDs[achievement.id] = true
        end

        local playerAchievements = PSC_DB.PlayerAchievements[characterKey]

        for achievementId, _ in pairs(playerAchievements) do
            if not currentAchievementIDs[achievementId] then
                -- This achievement ID no longer exists in current definitions
                playerAchievements[achievementId] = nil
                removedCount = removedCount + 1
                PSC_Print("Removed obsolete achievement: " .. achievementId)
            end
        end
    end

    if removedCount > 0 then
        PSC_Print("Cleaned up " .. removedCount .. " obsolete achievement(s) from your progress.")

        -- Recalculate achievement points after cleanup
        self:SaveAchievementPoints()
    end

    return removedCount
end


-- Helper function to get zone kills across all language variants
function PSC_GetZoneKills(stats, zoneTranslations, zoneNameEnglish)
    if not stats.zoneData then return 0 end

    local translations = zoneTranslations[zoneNameEnglish]
    if not translations then
        return stats.zoneData[zoneNameEnglish] or 0
    end

    for _, zoneName in ipairs(translations) do
        local kills = stats.zoneData[zoneName]
        if kills and kills > 0 then
            return kills
        end
    end

    return 0
end
