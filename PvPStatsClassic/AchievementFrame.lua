local addonName, PVPSC = ...

local AchievementFrame = CreateFrame("Frame", "PVPSCAchievementFrame", UIParent, "BasicFrameTemplateWithInset")
AchievementFrame:SetSize(1140, 520)
AchievementFrame:SetPoint("CENTER")
AchievementFrame:SetMovable(true)
AchievementFrame:EnableMouse(true)
AchievementFrame:RegisterForDrag("LeftButton")
AchievementFrame:SetScript("OnDragStart", AchievementFrame.StartMoving)
AchievementFrame:SetScript("OnDragStop", AchievementFrame.StopMovingOrSizing)
AchievementFrame:Hide()

tinsert(UISpecialFrames, "PVPSCAchievementFrame")

AchievementFrame.TitleText = AchievementFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
AchievementFrame.TitleText:SetPoint("TOP", AchievementFrame, "TOP", 0, -5)
AchievementFrame.TitleText:SetText("PvP Achievements")

-- Create content area for achievements
local contentFrame = CreateFrame("Frame", nil, AchievementFrame)
contentFrame:SetPoint("TOPLEFT", AchievementFrame, "TOPLEFT", 10, -30)
contentFrame:SetPoint("BOTTOMRIGHT", AchievementFrame, "BOTTOMRIGHT", -10, 15)

-- Create scroll frame for achievements
local scrollFrame = CreateFrame("ScrollFrame", "PVPSCAchievementScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, 0)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)

-- Create content for the scroll frame
local scrollContent = CreateFrame("Frame", "PVPSCAchievementContent", scrollFrame)
scrollContent:SetSize(scrollFrame:GetWidth(), 1) -- Height will be adjusted dynamically
scrollFrame:SetScrollChild(scrollContent)

-- Function to get player name for achievement text
local function GetPlayerName()
    local playerName = UnitName("player")
    return playerName or "You"
end

-- Function to replace placeholders in text with player name
local function PersonalizeText(text)
    if not text then return "" end

    if type(text) == "function" then
        text = text()
    end
    local playerName = GetPlayerName()
    return text:gsub("%[YOUR NAME%]", playerName)
end

-- Constants for achievement layout
local ACHIEVEMENT_WIDTH = 260
local ACHIEVEMENT_HEIGHT = 80
local ACHIEVEMENT_SPACING_H = 15
local ACHIEVEMENT_SPACING_V = 15
local ACHIEVEMENTS_PER_ROW = 4


local function GetPlayerStats()
    local characterKey = PSC_GetCharacterKey()
    local playerStats = {}

    if PSC_DB and PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey] then
        -- Get kill streak data
        playerStats.currentKillStreak = PSC_DB.PlayerKillCounts.Characters[characterKey].CurrentKillStreak or 0
        playerStats.highestKillStreak = PSC_DB.PlayerKillCounts.Characters[characterKey].HighestKillStreak or 0

        -- Additional stats if available
        if PSC_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill then
            playerStats.highestMultiKill = PSC_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill
        end
    end

    return playerStats
end

-- Helper function to calculate statistics that displays them for debugging
local function GetStatistics()
    -- Get statistics from PSC_DB
    local playerStats = GetPlayerStats()

    -- First, try to get the calculated statistics from the StatisticsFrame
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData = {}, {}, {}, {}, {}, {}, {}

    -- Try to access the function for calculating stats directly
    if PSC_CalculateBarChartStatistics then
        classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData =
            PSC_CalculateBarChartStatistics()
    end

    local summaryStats = {}
    if PSC_CalculateSummaryStatistics then
        summaryStats = PSC_CalculateSummaryStatistics()

        -- Update player stats with summary data
        if summaryStats.highestKillStreak and (not playerStats.highestKillStreak or summaryStats.highestKillStreak > playerStats.highestKillStreak) then
            playerStats.highestKillStreak = summaryStats.highestKillStreak
        end

        -- Get total and unique kills data
        if summaryStats.totalKills then
            playerStats.totalKills = summaryStats.totalKills
        end

        if summaryStats.uniqueKills then
            playerStats.uniqueKills = summaryStats.uniqueKills
        end
    end

    -- Add guild status data to playerStats if not already present
    if guildStatusData and guildStatusData["In Guild"] then
        playerStats.guildedKills = guildStatusData["In Guild"]
    end

    if guildStatusData and guildStatusData["No Guild"] then
        playerStats.loneWolfKills = guildStatusData["No Guild"]
    end

    return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, summaryStats, playerStats
end


local currentCategory = "Class"  -- default category

-- Achievement Tabs!
local function FilterAchievements(achievements, category)
    local filtered = {}

    local playerFaction = UnitFactionGroup("player")

    for _, achievement in ipairs(achievements) do
        local prefix = string.match(achievement.id, "^([^_]+)")

        if prefix == category:lower() then
            if prefix == "class" then
                if string.find(achievement.id, "_paladin_") and playerFaction == "Horde" then
                    table.insert(filtered, achievement)
                elseif string.find(achievement.id, "_shaman_") and playerFaction == "Alliance" then
                    table.insert(filtered, achievement)
                elseif not string.find(achievement.id, "_paladin_") and
                       not string.find(achievement.id, "_shaman_") then
                    table.insert(filtered, achievement)
                end
            elseif prefix == "race" then
                if playerFaction == "Horde" then
                    if string.find(achievement.id, "_human_") or
                       string.find(achievement.id, "_nightelf_") or
                       string.find(achievement.id, "_dwarf_") or
                       string.find(achievement.id, "_gnome_") then
                        table.insert(filtered, achievement)
                    end
                elseif playerFaction == "Alliance" then
                    if string.find(achievement.id, "_orc_") or
                       string.find(achievement.id, "_undead_") or
                       string.find(achievement.id, "_troll_") or
                       string.find(achievement.id, "_tauren_") then
                        table.insert(filtered, achievement)
                    end
                end
            elseif prefix == "general" then
                if string.find(achievement.id, "_zone_") then
                    if playerFaction == "Horde" then
                        if string.find(achievement.id, "_redridge") or
                           string.find(achievement.id, "_elwynn") or
                           string.find(achievement.id, "_duskwood") or
                           string.find(achievement.id, "_westfall") then
                            table.insert(filtered, achievement)
                        end
                    elseif playerFaction == "Alliance" then
                        if string.find(achievement.id, "_barrens") or
                           string.find(achievement.id, "_durotar") or
                           string.find(achievement.id, "_tirisfal") then
                            table.insert(filtered, achievement)
                        end
                    end
                else
                    table.insert(filtered, achievement)
                end
            elseif prefix == "kills" then
                table.insert(filtered, achievement)
            end
        end
    end

    return filtered
end

local function UpdateAchievementLayout()
    -- Clear existing achievement frames first
    for _, child in pairs({scrollContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local allAchievements = PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements or {}
    local achievements = FilterAchievements(allAchievements, currentCategory)

    if #achievements == 0 then
        return
    end

    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, summaryStats, playerStats =
        GetStatistics()

    for i, achievement in ipairs(achievements) do
        local column = (i - 1) % ACHIEVEMENTS_PER_ROW
        local row = math.floor((i - 1) / ACHIEVEMENTS_PER_ROW)

        local xPos = column * (ACHIEVEMENT_WIDTH + ACHIEVEMENT_SPACING_H)
        local yPos = -row * (ACHIEVEMENT_HEIGHT + ACHIEVEMENT_SPACING_V)

        local tile = CreateFrame("Button", nil, scrollContent, BackdropTemplateMixin and "BackdropTemplate")
        tile:SetSize(ACHIEVEMENT_WIDTH, ACHIEVEMENT_HEIGHT + 5)
        tile:SetPoint("TOPLEFT", xPos, yPos)

        tile:SetBackdrop({
            bgFile = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 22,
            edgeSize = 22,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })

        local rarity = achievement.rarity or "common"
        if rarity == "uncommon" then
            tile:SetBackdropBorderColor(0.1, 1.0, 0.1) -- Green
        elseif rarity == "rare" then
            tile:SetBackdropBorderColor(0.0, 0.4, 1.0) -- Blue
        elseif rarity == "epic" then
            tile:SetBackdropBorderColor(0.8, 0.3, 0.9) -- Purple
        elseif rarity == "legendary" then
            tile:SetBackdropBorderColor(1.0, 0.5, 0.0) -- Orange
        else
            tile:SetBackdropBorderColor(0.7, 0.7, 0.7) -- Light gray for common
        end

        if not achievement.unlocked then
            local overlay = tile:CreateTexture(nil, "OVERLAY")
            overlay:SetAllPoints()
            overlay:SetColorTexture(0, 0, 0, 0.5)
        end

        local iconContainer = CreateFrame("Frame", nil, tile)
        iconContainer:SetSize(40, 40)
        iconContainer:SetPoint("TOPLEFT", tile, "TOPLEFT", 10, -10)

        local background = iconContainer:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
        background:SetSize(38, 38)
        background:SetTexture("Interface\\Buttons\\UI-EmptySlot")
        background:SetVertexColor(0.3, 0.3, 0.3, 0.8)

        local icon = iconContainer:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
        icon:SetTexture(achievement.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        if not achievement.unlocked then
            icon:SetDesaturated(true)
        end

        local rarity = achievement.rarity or "common"


        local progressBar = CreateFrame("StatusBar", nil, tile, BackdropTemplateMixin and "BackdropTemplate")
        progressBar:SetSize(ACHIEVEMENT_WIDTH - 60, 10)
        progressBar:SetPoint("TOPLEFT", tile, "TOPLEFT", (ACHIEVEMENT_WIDTH - (ACHIEVEMENT_WIDTH - 60)) / 2, -65)
        progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        progressBar:SetStatusBarColor(0.0, 0.65, 0.0)

        local targetValue = 0
        local currentProgress = 0

        -- Add these condition checks to handle the new entry-level achievements
        -- Insert right before the existing class achievement checks

        -- Entry level class achievements (100 kills)
        if achievement.id == "class_paladin_0" then
            targetValue = 100
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "class_priest_0" then
            targetValue = 100
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "class_warrior_0" then
            targetValue = 100
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "class_mage_0" then
            targetValue = 100
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "class_rogue_0" then
            targetValue = 100
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "class_warlock_0" then
            targetValue = 100
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "class_druid_0" then
            targetValue = 100
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "class_shaman_0" then
            targetValue = 100
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "class_hunter_0" then
            targetValue = 100
            currentProgress = classData["Hunter"] or 0

        -- Entry level race achievements (100 kills)
        elseif achievement.id == "race_human_0" then
            targetValue = 100
            currentProgress = raceData["Human"] or 0
        elseif achievement.id == "race_nightelf_0" then
            targetValue = 100
            currentProgress = raceData["Night Elf"] or 0
        elseif achievement.id == "race_dwarf_0" then
            targetValue = 100
            currentProgress = raceData["Dwarf"] or 0
        elseif achievement.id == "race_gnome_0" then
            targetValue = 100
            currentProgress = raceData["Gnome"] or 0
        elseif achievement.id == "race_orc_0" then
            targetValue = 100
            currentProgress = raceData["Orc"] or 0
        elseif achievement.id == "race_undead_0" then
            targetValue = 100
            currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
        elseif achievement.id == "race_troll_0" then
            targetValue = 100
            currentProgress = raceData["Troll"] or 0
        elseif achievement.id == "race_tauren_0" then
            targetValue = 100
            currentProgress = raceData["Tauren"] or 0

        -- Existing class achievement checks
        elseif achievement.id == "class_paladin_1" then
            targetValue = 250
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "class_paladin_2" then
            targetValue = 500
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "class_paladin_3" then
            targetValue = 750
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "class_priest_1" then
            targetValue = 250
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "class_priest_2" then
            targetValue = 500
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "class_priest_3" then
            targetValue = 750
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "class_warrior_1" then
            targetValue = 250
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "class_warrior_2" then
            targetValue = 500
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "class_warrior_3" then
            targetValue = 750
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "class_mage_1" then
            targetValue = 250
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "class_mage_2" then
            targetValue = 500
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "class_mage_3" then
            targetValue = 750
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "class_rogue_1" then
            targetValue = 250
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "class_rogue_2" then
            targetValue = 500
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "class_rogue_3" then
            targetValue = 750
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "class_warlock_1" then
            targetValue = 250
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "class_warlock_2" then
            targetValue = 500
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "class_warlock_3" then
            targetValue = 750
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "class_druid_1" then
            targetValue = 250
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "class_druid_2" then
            targetValue = 500
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "class_druid_3" then
            targetValue = 750
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "class_shaman_1" then
            targetValue = 250
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "class_shaman_2" then
            targetValue = 500
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "class_shaman_3" then
            targetValue = 750
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "class_hunter_1" then
            targetValue = 250
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "class_hunter_2" then
            targetValue = 500
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "class_hunter_3" then
            targetValue = 750
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "general_gender_female_1" then
            targetValue = 250
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "general_gender_female_2" then
            targetValue = 500
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "general_gender_female_3" then
            targetValue = 750
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "general_gender_female_4" then
            targetValue = 1000
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "general_gender_male_1" then
            targetValue = 250
            currentProgress = genderData["Male"] or 0
        elseif achievement.id == "general_gender_male_2" then
            targetValue = 500
            currentProgress = genderData["Male"] or 0
        elseif achievement.id == "general_gender_male_3" then
            targetValue = 750
            currentProgress = genderData["Male"] or 0
        elseif achievement.id == "general_gender_male_4" then
            targetValue = 1000
            currentProgress = genderData["Male"] or 0
        -- ALLIANCE RACES
        -- Human achievements
        elseif achievement.id == "race_human_1" then
            targetValue = 250
            currentProgress = raceData["Human"] or 0
        elseif achievement.id == "race_human_2" then
            targetValue = 500
            currentProgress = raceData["Human"] or 0
        elseif achievement.id == "race_human_3" then
            targetValue = 750
            currentProgress = raceData["Human"] or 0
        -- Night Elf achievements
        elseif achievement.id == "race_nightelf_1" then
            targetValue = 250
            currentProgress = raceData["Night Elf"] or 0
        elseif achievement.id == "race_nightelf_2" then
            targetValue = 500
            currentProgress = raceData["Night Elf"] or 0
        elseif achievement.id == "race_nightelf_3" then
            targetValue = 750
            currentProgress = raceData["Night Elf"] or 0
        -- Dwarf achievements
        elseif achievement.id == "race_dwarf_1" then
            targetValue = 250
            currentProgress = raceData["Dwarf"] or 0
        elseif achievement.id == "race_dwarf_2" then
            targetValue = 500
            currentProgress = raceData["Dwarf"] or 0
        elseif achievement.id == "race_dwarf_3" then
            targetValue = 750
            currentProgress = raceData["Dwarf"] or 0
        -- Gnome achievements
        elseif achievement.id == "race_gnome_1" then
            targetValue = 250
            currentProgress = raceData["Gnome"] or 0
        elseif achievement.id == "race_gnome_2" then
            targetValue = 500
            currentProgress = raceData["Gnome"] or 0
        elseif achievement.id == "race_gnome_3" then
            targetValue = 750
            currentProgress = raceData["Gnome"] or 0
        -- HORDE RACES
        -- Orc achievements
        elseif achievement.id == "race_orc_1" then
            targetValue = 250
            currentProgress = raceData["Orc"] or 0
        elseif achievement.id == "race_orc_2" then
            targetValue = 500
            currentProgress = raceData["Orc"] or 0
        elseif achievement.id == "race_orc_3" then
            targetValue = 750
            currentProgress = raceData["Orc"] or 0
        -- Troll achievements
        elseif achievement.id == "race_troll_1" then
            targetValue = 250
            currentProgress = raceData["Troll"] or 0
        elseif achievement.id == "race_troll_2" then
            targetValue = 500
            currentProgress = raceData["Troll"] or 0
        elseif achievement.id == "race_troll_3" then
            targetValue = 750
            currentProgress = raceData["Troll"] or 0
        -- Undead achievements
        elseif achievement.id == "race_undead_1" then
            targetValue = 250
            currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
        elseif achievement.id == "race_undead_2" then
            targetValue = 500
            currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
        elseif achievement.id == "race_undead_3" then
            targetValue = 750
            currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
        -- Tauren achievements
        elseif achievement.id == "race_tauren_1" then
            targetValue = 250
            currentProgress = raceData["Tauren"] or 0
        elseif achievement.id == "race_tauren_2" then
            targetValue = 500
            currentProgress = raceData["Tauren"] or 0
        elseif achievement.id == "race_tauren_3" then
            targetValue = 750
            currentProgress = raceData["Tauren"] or 0
        -- Other achievements
        elseif achievement.id == "kills_guild" then
            targetValue = 500
            currentProgress = guildStatusData["In Guild"] or 0
        elseif achievement.id == "kills_guildless" then
            targetValue = 500
            currentProgress = guildStatusData["No Guild"] or 0
        elseif achievement.id == "kills_grey_level" then
            targetValue = 100
            currentProgress = PSC_CalculateGreyKills()
        elseif achievement.id == "kills_streak_25" then
            targetValue = 25
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_50" then
            targetValue = 50
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_75" then
            targetValue = 75
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_100" then
            targetValue = 100
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_125" then
            targetValue = 125
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_150" then
            targetValue = 150
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_175" then
            targetValue = 175
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kills_streak_200" then
            targetValue = 200
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "general_zone_redridge" then
            targetValue = 500
            currentProgress = zoneData["Redridge Mountains"] or 0
        elseif achievement.id == "general_zone_elwynn" then
            targetValue = 100
            currentProgress = zoneData["Elwynn Forest"] or 0
        elseif achievement.id == "general_zone_duskwood" then
            targetValue = 250
            currentProgress = zoneData["Duskwood"] or 0
        elseif achievement.id == "general_zone_westfall" then
            targetValue = 100
            currentProgress = zoneData["Westfall"] or 0
        elseif achievement.id == "kills_total_1" then
            targetValue = 500
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "kills_total_2" then
            targetValue = 1000
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "kills_total_3" then
            targetValue = 3000
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "kills_unique_1" then
            targetValue = 400
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "kills_unique_2" then
            targetValue = 800
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "kills_unique_3" then
            targetValue = 2400
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "kills_multi_3" then
            targetValue = 3
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "kills_multi_4" then
            targetValue = 4
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "kills_multi_5" then
            targetValue = 5
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "kills_big_game" then
            targetValue = 30
            local _, _, _, _, _, levelData = PSC_CalculateBarChartStatistics()
            currentProgress = levelData["??"] or 0
        elseif achievement.id == "kills_favorite_target" then
            targetValue = 10

            local stats = PSC_CalculateSummaryStatistics()
            local mostKilledPlayer = stats.mostKilledPlayer or "None"
            local mostKilledCount = stats.mostKilledCount or 0

            currentProgress = mostKilledCount
            if achievement.subText and type(achievement.subText) == "function" then
                local dynamicText = achievement.subText()
                achievement.displayText = dynamicText
            end
        end

        local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
        if pointsImage then
            title:SetPoint("RIGHT", pointsImage, "LEFT", -10, 0)
        else
            title:SetPoint("RIGHT", tile, "RIGHT", -15, 0)
        end
        -- Use PersonalizeText to replace [YOUR NAME] in the title
        title:SetText(PersonalizeText(achievement.title))
        if achievement.unlocked then
            title:SetTextColor(1, 0.82, 0)  -- Gold color for unlocked
        else
            title:SetTextColor(0.5, 0.5, 0.5)  -- Gray color for locked
        end

        local desc = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        desc:SetPoint("RIGHT", tile, "RIGHT", -10, 0)
        desc:SetJustifyH("LEFT")
        desc:SetText(achievement.description)
        if achievement.unlocked then
            desc:SetTextColor(0.9, 0.9, 0.9)  -- Light gray for unlocked
        else
            desc:SetTextColor(0.4, 0.4, 0.4)  -- Dark gray for locked
        end

        local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)

        if achievement.unlocked then
            progressBar:SetMinMaxValues(0, targetValue)
            progressBar:SetValue(targetValue)
            progressText:SetText(targetValue.."/"..targetValue)
        else
            if currentProgress >= targetValue then
                achievement.unlocked = true
                achievement.completedDate = date("%d/%m/%Y %H:%M")

                progressBar:SetMinMaxValues(0, targetValue)
                progressBar:SetValue(targetValue)
                progressText:SetText(targetValue.."/"..targetValue)

                icon:SetDesaturated(false)

                for _, child in pairs({tile:GetChildren()}) do
                    if child:IsObjectType("Texture") and child:GetObjectType() == "Texture" then
                        if child:GetAlpha() == 0.5 then
                            child:Hide()
                        end
                    end
                end

                title:SetTextColor(1, 0.82, 0)

                desc:SetTextColor(0.9, 0.9, 0.9)

                if PVPSC.AchievementPopup then
                    PVPSC.AchievementPopup:ShowPopup({
                        icon = achievement.iconID,
                        title = achievement.title,
                        description = achievement.description
                    })
                end

                if not PSC_DB.Achievements then
                    PSC_DB.Achievements = {}
                end

                PSC_DB.Achievements[achievement.id] = {
                    unlocked = true,
                    completedDate = achievement.completedDate
                }
            else
                progressBar:SetMinMaxValues(0, targetValue)
                progressBar:SetValue(currentProgress)
                progressText:SetText(currentProgress.."/"..targetValue)
            end
        end

        -- Find the appropriate points image based on achievement points
        local function GetPointsImagePath(points)
            -- Ensure path is correct with proper extension (.tga, .blp, etc)
            local basePath = "Interface\\AddOns\\PvPStatsClassic\\achievement_img\\Achievement_icon"

            if points == 10 then return basePath .. "10"
            elseif points == 25 then return basePath .. "25"
            elseif points == 50 then return basePath .. "50"
            elseif points == 75 then return basePath .. "75"
            elseif points == 100 then return basePath .. "100"
            elseif points == 125 then return basePath .. "125"
            elseif points == 250 then return basePath .. "250"
            elseif points == 500 then return basePath .. "500"
            else return basePath end
        end

        local pointsValue = achievement.achievementPoints or 10
        local pointsImage = tile:CreateTexture(nil, "ARTWORK")
        pointsImage:SetSize(38, 32) -- Increased size for better visibility
        pointsImage:SetPoint("RIGHT", tile, "RIGHT", -15, 5) -- Adjusted position
        pointsImage:SetTexture(GetPointsImagePath(pointsValue))

        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
        title:SetPoint("RIGHT", pointsImage, "LEFT", -10, 0)  -- Updated to not overlap points

        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        desc:SetPoint("RIGHT", pointsImage, "LEFT", -10, 0)  -- Updated to not overlap points

        tile:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            local rarity = achievement.rarity or "common"
            local r, g, b = 1, 0.82, 0 -- Default gold color

            if rarity == "uncommon" then
                r, g, b = 0.1, 1.0, 0.1 -- Green
            elseif rarity == "rare" then
                r, g, b = 0.0, 0.4, 1.0 -- Blue
            elseif rarity == "epic" then
                r, g, b = 0.8, 0.3, 0.9 -- Purple
            elseif rarity == "legendary" then
                r, g, b = 1.0, 0.5, 0.0 -- Orange
            elseif rarity == "common" then
                r, g, b = 0.9, 0.9, 0.9 -- Light gray for common
            end

            local pointsText = achievement.achievementPoints or 10
            local personalizedTitle = PersonalizeText(achievement.title)
            GameTooltip:SetText(personalizedTitle .. " |cFF66CCFF(" .. pointsText .. ")|r", r, g, b)

            GameTooltip:AddLine(PersonalizeText(achievement.description), 1, 1, 1, true)
            if achievement.subText then
                GameTooltip:AddLine(" ")
                local personalizedSubText = PersonalizeText(achievement.subText)
                GameTooltip:AddLine(personalizedSubText, 0.7, 0.7, 1, true)
            end

            if achievement.unlocked and achievement.completedDate then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Completed: " .. achievement.completedDate, 1, 0.82, 0, true) -- Gold color
            end

            GameTooltip:Show()
        end)

        tile:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    local rowCount = math.ceil(#achievements / ACHIEVEMENTS_PER_ROW)
    local totalHeight = rowCount * (ACHIEVEMENT_HEIGHT + 5 + ACHIEVEMENT_SPACING_V)
    scrollContent:SetSize(scrollContent:GetWidth(), math.max(totalHeight, 1))
end

local function CreateAchievementTabSystem(parent)
    local tabNames = {"Class", "Race", "Kills", "General"}
    local tabs = {}
    local tabWidth, tabHeight = 85, 32

    local tabContainer = CreateFrame("Frame", nil, parent)
    tabContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -25)
    tabContainer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -7, 7)

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", parent:GetName() .. "Tab" .. i, parent, "CharacterFrameTabButtonTemplate")
        tab:SetText(name)
        tab:SetID(i)
        tab:SetSize(tabWidth, tabHeight)

        local tabMiddle = _G[tab:GetName() .. "Middle"]
        local tabLeft = _G[tab:GetName() .. "Left"]
        local tabRight = _G[tab:GetName() .. "Right"]
        local tabSelectedMiddle = _G[tab:GetName() .. "SelectedMiddle"]
        local tabSelectedLeft = _G[tab:GetName() .. "SelectedLeft"]
        local tabSelectedRight = _G[tab:GetName() .. "SelectedRight"]
        local tabText = _G[tab:GetName() .. "Text"]

        if tabMiddle then
            tabMiddle:ClearAllPoints()
            tabMiddle:SetPoint("LEFT", tabLeft, "RIGHT", 0, 0)
            tabMiddle:SetWidth(tabWidth - 31)
        end
        if tabSelectedMiddle then
            tabSelectedMiddle:ClearAllPoints()
            tabSelectedMiddle:SetPoint("LEFT", tabSelectedLeft, "RIGHT", 0, 0)
            tabSelectedMiddle:SetWidth(tabWidth - 31)
        end

        if i == 1 then
            tab:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, 0)
        else
            tab:SetPoint("LEFT", tabs[i-1], "RIGHT", -8, 0)
        end

        if tabText then
            tabText:ClearAllPoints()
            tabText:SetPoint("CENTER", tab, "CENTER", 0, 2)
            tabText:SetJustifyH("CENTER")
            tabText:SetWidth(tabWidth - 40)
        end

        tab:SetScript("OnClick", function()
            currentCategory = name
            UpdateAchievementLayout()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            PanelTemplates_SetTab(parent, i)

            for j = 1, #tabs do
                PanelTemplates_TabResize(tabs[j], 0)
            end
        end)

        tabs[i] = tab
    end

    parent.tabs = tabs
    parent.numTabs = #tabs

    PanelTemplates_SetNumTabs(parent, #tabs)

    for i = 1, #tabs do
        PanelTemplates_TabResize(tabs[i], 0)
    end

    PanelTemplates_SetTab(parent, 1)

    return tabs
end

CreateAchievementTabSystem(AchievementFrame)

local function LoadAchievementCompletionStatus()
    if not PSC_DB.Achievements then return end

    local achievements = PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements or {}

    for _, achievement in ipairs(achievements) do
        local savedData = PSC_DB.Achievements[achievement.id]
        if savedData and savedData.unlocked then
            achievement.unlocked = true
            achievement.completedDate = savedData.completedDate
        end
    end
end

local function ToggleAchievementFrame()
    if AchievementFrame:IsShown() then
        AchievementFrame:Hide()
    else
        LoadAchievementCompletionStatus()

        UpdateAchievementLayout()
        AchievementFrame:Show()
    end
end

PVPSC.AchievementFrame = AchievementFrame
PVPSC.ToggleAchievementFrame = ToggleAchievementFrame
PVPSC.UpdateAchievementLayout = UpdateAchievementLayout

SLASH_PVPSCACHIEVEMENTS1 = "/pvpachievements"
SlashCmdList["PVPSCACHIEVEMENTS"] = function()
    ToggleAchievementFrame()
end
