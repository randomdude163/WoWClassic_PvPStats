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

-- Helper: Remove all children from scrollContent
local function ClearAchievementTiles()
    for _, child in pairs({scrollContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
end

-- Helper: Get progress and target for an achievement
local function GetAchievementProgress(achievement, classData, raceData, genderData, zoneData, levelData, guildStatusData, summaryStats, playerStats)
    local id = achievement.id
    local targetValue = achievement.targetValue or 0
    local currentProgress = 0

    -- Class achievements
    for _, class in ipairs({"Paladin","Priest","Warrior","Mage","Rogue","Warlock","Druid","Shaman","Hunter"}) do
        for i = 0, 3 do
            if id == ("class_"..class:lower().."_"..i) then
                currentProgress = classData[class] or 0
                return targetValue, currentProgress
            end
        end
    end

    -- Race achievements
    for _, race in ipairs({"Human","Night Elf","Dwarf","Gnome","Orc","Undead","Troll","Tauren"}) do
        for i = 0, 3 do
            if id == ("race_"..race:lower():gsub(" ", "").."_"..i) then
                if race == "Undead" then
                    currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
                elseif race == "Night Elf" then
                    currentProgress = raceData["Night Elf"] or 0
                else
                    currentProgress = raceData[race] or 0
                end
                return targetValue, currentProgress
            end
        end
    end

    -- Gender achievements
    for _, gender in ipairs({"Female","Male"}) do
        for i = 1, 4 do
            if id == ("general_gender_"..gender:lower().."_"..i) then
                currentProgress = genderData[gender] or 0
                return targetValue, currentProgress
            end
        end
    end

    -- Zone achievements
    local zoneMap = {
        ["general_zone_redridge"] = "Redridge Mountains",
        ["general_zone_elwynn"] = "Elwynn Forest",
        ["general_zone_duskwood"] = "Duskwood",
        ["general_zone_westfall"] = "Westfall",
    }
    if zoneMap[id] then
        local zone = zoneMap[id]
        currentProgress = zoneData[zone] or 0
        return targetValue, currentProgress
    end

    -- Guild/guildless kills
    if id == "kills_guild" then
        currentProgress = guildStatusData["In Guild"] or 0
        return targetValue, currentProgress
    elseif id == "kills_guildless" then
        currentProgress = guildStatusData["No Guild"] or 0
        return targetValue, currentProgress
    end

    -- Grey level kills
    if id == "kills_grey_level" then
        currentProgress = PSC_CalculateGreyKills()
        return targetValue, currentProgress
    end

    -- Kill streaks
    if id:find("^kills_streak_") then
        currentProgress = summaryStats.highestKillStreak
        return targetValue, currentProgress
    end

    -- Total kills
    if id:find("^kills_total_") then
        currentProgress = summaryStats.totalKills or 0
        return targetValue, currentProgress
    end

    -- Unique kills
    if id:find("^kills_unique_") then
        currentProgress = summaryStats.uniqueKills or 0
        return targetValue, currentProgress
    end

    -- Multi-kill
    if id:find("^kills_multi_") then
        currentProgress = summaryStats.highestMultiKill
        return targetValue, currentProgress
    end

    -- Big game
    if id == "kills_big_game" then
        currentProgress = levelData["??"] or 0
        return targetValue, currentProgress
    end

    -- Favorite target
    if id == "kills_favorite_target" then
        currentProgress = summaryStats.mostKilledCount or 0
        if achievement.subText and type(achievement.subText) == "function" then
            achievement.displayText = achievement.subText()
        end
        return targetValue, currentProgress
    end

    return targetValue, currentProgress
end

-- Helper: Set tile border color by rarity
local function SetTileBorderColor(tile, rarity)
    if rarity == "uncommon" then
        tile:SetBackdropBorderColor(0.1, 1.0, 0.1)
    elseif rarity == "rare" then
        tile:SetBackdropBorderColor(0.0, 0.4, 1.0)
    elseif rarity == "epic" then
        tile:SetBackdropBorderColor(0.8, 0.3, 0.9)
    elseif rarity == "legendary" then
        tile:SetBackdropBorderColor(1.0, 0.5, 0.0)
    else
        tile:SetBackdropBorderColor(0.7, 0.7, 0.7)
    end
end

-- Helper: Create icon container and icon
local function CreateAchievementIcon(tile, achievement)
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

    return icon
end

-- Helper: Create points image
local function CreatePointsImage(tile, pointsValue)
    local function GetPointsImagePath(points)
        local basePath = "Interface\\AddOns\\PvPStatsClassic\\achievement_img\\Achievement_icon"
        if points == 10 then return basePath .. "10"
        else return basePath end
    end

    local pointsImage = tile:CreateTexture(nil, "ARTWORK")
    pointsImage:SetSize(38, 32)
    pointsImage:SetPoint("RIGHT", tile, "RIGHT", -15, 5)
    pointsImage:SetTexture(GetPointsImagePath(pointsValue))
    return pointsImage
end

-- Helper: Create title and description
local function CreateTitleAndDescription(tile, icon, pointsImage, achievement)
    local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    title:SetPoint("RIGHT", pointsImage, "LEFT", -10, 0)
    -- Call the function if title is a function, otherwise use as string
    local titleText = type(achievement.title) == "function" and achievement.title(achievement) or achievement.title
    title:SetText(PSC_ReplacePlayerNamePlaceholder(titleText, nil, achievement))
    if achievement.unlocked then
        title:SetTextColor(1, 0.82, 0)
    else
        title:SetTextColor(0.5, 0.5, 0.5)
    end

    local desc = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    desc:SetPoint("RIGHT", pointsImage, "LEFT", -10, 0)
    desc:SetJustifyH("LEFT")
    -- Call the function if description is a function, otherwise use as string
    local descText = type(achievement.description) == "function" and achievement.description(achievement) or achievement.description
    desc:SetText(descText)
    if achievement.unlocked then
        desc:SetTextColor(0.9, 0.9, 0.9)
    else
        desc:SetTextColor(0.4, 0.4, 0.4)
    end

    return title, desc
end

-- Helper: Create progress bar and text
local function CreateProgressBar(tile, targetValue, currentProgress, achievement, icon, title)
    local progressBar = CreateFrame("StatusBar", nil, tile, BackdropTemplateMixin and "BackdropTemplate")
    progressBar:SetSize(ACHIEVEMENT_WIDTH - 60, 10)
    progressBar:SetPoint("TOPLEFT", tile, "TOPLEFT", (ACHIEVEMENT_WIDTH - (ACHIEVEMENT_WIDTH - 60)) / 2, -65)
    progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    progressBar:SetStatusBarColor(0.0, 0.65, 0.0)

    local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)

    if achievement.unlocked then
        progressBar:SetMinMaxValues(0, targetValue)
        progressBar:SetValue(targetValue)
        progressText:SetText(targetValue.."/"..targetValue)
    else
        if currentProgress >= targetValue and targetValue > 0 then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M")
            progressBar:SetMinMaxValues(0, targetValue)
            progressBar:SetValue(targetValue)
            progressText:SetText(targetValue.."/"..targetValue)
            icon:SetDesaturated(false)
            title:SetTextColor(1, 0.82, 0)
        else
            progressBar:SetMinMaxValues(0, targetValue)
            progressBar:SetValue(currentProgress)
            progressText:SetText(currentProgress.."/"..targetValue)
        end
    end

    return progressBar, progressText
end

-- Helper: Add overlay for locked achievements
local function AddLockedOverlay(tile, achievement)
    if not achievement.unlocked then
        local overlay = tile:CreateTexture(nil, "OVERLAY")
        overlay:SetAllPoints()
        overlay:SetColorTexture(0, 0, 0, 0.5)
    end
end

-- Helper: Create a single achievement tile
local function CreateAchievementTile(i, achievement, classData, raceData, genderData, zoneData, levelData, guildStatusData, summaryStats, playerStats)
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

    SetTileBorderColor(tile, achievement.rarity or "common")
    AddLockedOverlay(tile, achievement)

    local icon = CreateAchievementIcon(tile, achievement)
    local pointsValue = achievement.achievementPoints or 10
    local pointsImage = CreatePointsImage(tile, pointsValue)
    local title, desc = CreateTitleAndDescription(tile, icon, pointsImage, achievement)

    local targetValue, currentProgress = GetAchievementProgress(achievement, classData, raceData, genderData, zoneData, levelData, guildStatusData, summaryStats, playerStats)
    CreateProgressBar(tile, targetValue, currentProgress, achievement, icon, title)

    tile:SetScript("OnEnter", function(self)
        GameTooltip:Show()
    end)
end

-- Main function: Update achievement layout
local function UpdateAchievementLayout()
    ClearAchievementTiles()

    local allAchievements = PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements or {}
    local achievements = FilterAchievements(allAchievements, currentCategory)
    if #achievements == 0 then return end

    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData = PSC_CalculateBarChartStatistics()
    local summaryStats = PSC_CalculateSummaryStatistics()
    local playerStats = GetPlayerStats()

    for i, achievement in ipairs(achievements) do
        CreateAchievementTile(
            i,
            achievement,
            classData,
            raceData,
            genderData,
            zoneData,
            levelData,
            guildStatusData,
            summaryStats,
            playerStats
        )
    end

    -- Optionally update scrollContent size here if needed
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
            tabSelectedSelectedMiddle:SetPoint("LEFT", tabSelectedLeft, "RIGHT", 0, 0)
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
