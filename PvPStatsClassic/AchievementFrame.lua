local addonName, PVPSC = ...

local AchievementFrame = CreateFrame("Frame", "PVPSCAchievementFrame", UIParent, "BasicFrameTemplateWithInset")
AchievementFrame:SetSize(800, 520)
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
local ACHIEVEMENT_WIDTH = 230
local ACHIEVEMENT_HEIGHT = 80
local ACHIEVEMENT_SPACING_H = 20
local ACHIEVEMENT_SPACING_V = 15
local ACHIEVEMENTS_PER_ROW = 3


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
    for _, achievement in ipairs(achievements) do
        if category == "Class" then
            if string.find(achievement.id, "paladin") or string.find(achievement.id, "priest") or
               string.find(achievement.id, "warrior") or string.find(achievement.id, "mage") or
               string.find(achievement.id, "rogue") or string.find(achievement.id, "warlock") or
               string.find(achievement.id, "druid") or string.find(achievement.id, "shaman") or
               string.find(achievement.id, "hunter") then
                table.insert(filtered, achievement)
            end
        elseif category == "Race" then
            if string.find(achievement.id, "race_") then
                table.insert(filtered, achievement)
            end
        elseif category == "Kills" then
            if achievement.id == "guild_kills" or achievement.id == "guildless_kills" or
               achievement.id == "grey_level_kills" or achievement.id == "big_game_huntard" or
               string.find(achievement.id, "kill_streak") or
               string.find(achievement.id, "total_kills") or
               string.find(achievement.id, "unique_kills") or
               string.find(achievement.id, "multi_kill") then
                table.insert(filtered, achievement)
            end
        elseif category == "General" then
            -- Include gender kills and other general achievements
            if achievement.id == "favorite_target" or string.find(achievement.id, "zone_") or
               string.find(achievement.id, "gender_") then
                table.insert(filtered, achievement)
            end
        end
    end
    return filtered
end

-- Find the function that creates achievement tiles
local function CreateAchievementTile(parent, achievement, index)
    local tile = CreateFrame("Button", nil, parent)
    tile:SetSize(parent:GetWidth() - 30, 60)
    tile:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, -((index - 1) * 65) - 70)

    -- Create icon container to hold both icon and border
    local iconContainer = CreateFrame("Frame", nil, tile)
    iconContainer:SetSize(40, 40)
    iconContainer:SetPoint("LEFT", 10, 0)

    -- Add a background for the icon first (lowest layer)
    local background = iconContainer:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
    background:SetSize(38, 38)
    background:SetTexture("Interface\\Buttons\\UI-EmptySlot")
    background:SetVertexColor(0.3, 0.3, 0.3, 0.8)

    -- Create icon on top of background
    local icon = iconContainer:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)

    -- Get the achievement icon
    local iconID = achievement.iconID
    if type(iconID) == "number" then
        icon:SetTexture(iconID)
    else
        icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Get the achievement rarity
    local rarity = achievement.rarity or "common"

    -- Rest of your tile code...
    local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", iconContainer, "TOPRIGHT", 10, -2)
    title:SetText(achievement.title)

    return tile
end

-- Function to update achievement layout
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

    -- Get statistics and player stats
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, summaryStats, playerStats =
        GetStatistics()

    for i, achievement in ipairs(achievements) do
        -- Calculate column and row positions
        local column = (i - 1) % ACHIEVEMENTS_PER_ROW
        local row = math.floor((i - 1) / ACHIEVEMENTS_PER_ROW)

        local xPos = column * (ACHIEVEMENT_WIDTH + ACHIEVEMENT_SPACING_H)
        local yPos = -row * (ACHIEVEMENT_HEIGHT + ACHIEVEMENT_SPACING_V)

        -- Create achievement tile
        local tile = CreateFrame("Button", nil, scrollContent, BackdropTemplateMixin and "BackdropTemplate")
        tile:SetSize(ACHIEVEMENT_WIDTH, ACHIEVEMENT_HEIGHT + 5)
        tile:SetPoint("TOPLEFT", xPos, yPos)

        -- Style the tile
        tile:SetBackdrop({
            bgFile = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 22,
            edgeSize = 22,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })

        -- Apply rarity color to the frame's border
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
            -- Gray out locked achievements
            local overlay = tile:CreateTexture(nil, "OVERLAY")
            overlay:SetAllPoints()
            overlay:SetColorTexture(0, 0, 0, 0.5)
        end

        -- Add achievement icon with container
        local iconContainer = CreateFrame("Frame", nil, tile)
        iconContainer:SetSize(40, 40)
        iconContainer:SetPoint("TOPLEFT", tile, "TOPLEFT", 10, -10)

        -- Add a background for the icon
        local background = iconContainer:CreateTexture(nil, "BACKGROUND")
        background:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
        background:SetSize(38, 38)
        background:SetTexture("Interface\\Buttons\\UI-EmptySlot")
        background:SetVertexColor(0.3, 0.3, 0.3, 0.8)

        -- Create the icon
        local icon = iconContainer:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
        icon:SetTexture(achievement.iconID or "Interface\\Icons\\INV_Misc_QuestionMark")
        if not achievement.unlocked then
            icon:SetDesaturated(true)
        end

        -- Get the achievement rarity and create border
        local rarity = achievement.rarity or "common"


        -- Add status bar for progress under the icon
        local progressBar = CreateFrame("StatusBar", nil, tile, BackdropTemplateMixin and "BackdropTemplate")
        progressBar:SetSize(ACHIEVEMENT_WIDTH - 60, 10)
        progressBar:SetPoint("TOPLEFT", tile, "TOPLEFT", (ACHIEVEMENT_WIDTH - (ACHIEVEMENT_WIDTH - 60)) / 2, -55)  -- Center horizontally
        progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        progressBar:SetStatusBarColor(0.0, 0.65, 0.0)

        -- Get the target value and current progress based on achievement type
        local targetValue = 0
        local currentProgress = 0

        -- Determine targetValue and currentProgress based on achievement ID
        if achievement.id == "paladin_1" then
            targetValue = 250
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "paladin_2" then
            targetValue = 500
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "paladin_3" then
            targetValue = 750
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "priest_1" then
            targetValue = 250
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "priest_2" then
            targetValue = 500
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "priest_3" then
            targetValue = 750
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "warrior_1" then
            targetValue = 250
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "warrior_2" then
            targetValue = 500
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "warrior_3" then
            targetValue = 750
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "mage_1" then
            targetValue = 250
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "mage_2" then
            targetValue = 500
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "mage_3" then
            targetValue = 750
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "rogue_1" then
            targetValue = 250
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "rogue_2" then
            targetValue = 500
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "rogue_3" then
            targetValue = 750
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "warlock_1" then
            targetValue = 250
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "warlock_2" then
            targetValue = 500
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "warlock_3" then
            targetValue = 750
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "druid_1" then
            targetValue = 250
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "druid_2" then
            targetValue = 500
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "druid_3" then
            targetValue = 750
            currentProgress = classData["Druid"] or 0
        elseif achievement.id == "shaman_1" then
            targetValue = 250
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "shaman_2" then
            targetValue = 500
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "shaman_3" then
            targetValue = 750
            currentProgress = classData["Shaman"] or 0
        elseif achievement.id == "hunter_1" then
            targetValue = 250
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "hunter_2" then
            targetValue = 500
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "hunter_3" then
            targetValue = 750
            currentProgress = classData["Hunter"] or 0
        elseif achievement.id == "gender_female_1" then
            targetValue = 50
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "gender_female_2" then
            targetValue = 100
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "gender_female_3" then
            targetValue = 200
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "gender_male_1" then
            targetValue = 50
            currentProgress = genderData["Male"] or 0
        elseif achievement.id == "gender_male_2" then
            targetValue = 100
            currentProgress = genderData["Male"] or 0
        elseif achievement.id == "gender_male_3" then
            targetValue = 200
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
        elseif achievement.id == "guild_kills" then
            targetValue = 500
            currentProgress = guildStatusData["In Guild"] or 0
        elseif achievement.id == "guildless_kills" then
            targetValue = 500
            currentProgress = guildStatusData["No Guild"] or 0
        elseif achievement.id == "grey_level_kills" then
            targetValue = 100
            currentProgress = PSC_CalculateGreyKills()
        elseif achievement.id == "kill_streak_25" then
            targetValue = 25
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_50" then
            targetValue = 50
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_75" then
            targetValue = 75
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_100" then
            targetValue = 100
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_125" then
            targetValue = 125
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_150" then
            targetValue = 150
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_175" then
            targetValue = 175
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "kill_streak_200" then
            targetValue = 200
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
        elseif achievement.id == "zone_redridge" then
            targetValue = 500
            currentProgress = zoneData["Redridge Mountains"] or 0
        elseif achievement.id == "zone_elwynn" then
            targetValue = 100
            currentProgress = zoneData["Elwynn Forest"] or 0
        elseif achievement.id == "zone_duskwood" then
            targetValue = 100
            currentProgress = zoneData["Duskwood"] or 0
        elseif achievement.id == "total_kills_1" then
            targetValue = 500
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "total_kills_2" then
            targetValue = 1000
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "total_kills_3" then
            targetValue = 3000
            currentProgress = summaryStats.totalKills or 0
        elseif achievement.id == "unique_kills_1" then
            targetValue = 400
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "unique_kills_2" then
            targetValue = 800
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "unique_kills_3" then
            targetValue = 2400
            currentProgress = summaryStats.uniqueKills or 0
        elseif achievement.id == "multi_kill_3" then
            targetValue = 3
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "multi_kill_4" then
            targetValue = 4
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "multi_kill_5" then
            targetValue = 5
            currentProgress = summaryStats.highestMultiKill or playerStats.highestMultiKill or 0
        elseif achievement.id == "big_game_huntard" then
            targetValue = 30
            local _, _, _, _, _, levelData = PSC_CalculateBarChartStatistics()
            currentProgress = levelData["??"] or 0
        elseif achievement.id == "favorite_target" then
            targetValue = 10

            -- Calculate most killed player count
            local stats = PSC_CalculateSummaryStatistics()
            local mostKilledPlayer = stats.mostKilledPlayer or "None"
            local mostKilledCount = stats.mostKilledCount or 0

            currentProgress = mostKilledCount
            -- Handle dynamic subText for this achievement
            if achievement.subText and type(achievement.subText) == "function" then
                -- Replace the function with its actual result for display
                local dynamicText = achievement.subText()
                achievement.displayText = dynamicText
            end
        end

        local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
        title:SetPoint("RIGHT", tile, "RIGHT", -10, 0)
        title:SetJustifyH("LEFT")
        title:SetText(achievement.title)
        if achievement.unlocked then
            title:SetTextColor(1, 0.82, 0)  -- Gold color for unlocked
        else
            title:SetTextColor(0.5, 0.5, 0.5)  -- Gray color for locked
        end

        -- Add achievement description
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

        -- First create the progress text FontString
        local progressText = progressBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        progressText:SetPoint("CENTER", progressBar, "CENTER", 0, 0)

        -- Then set the progress bar and text values
        if achievement.unlocked then
            progressBar:SetMinMaxValues(0, targetValue)
            progressBar:SetValue(targetValue)
            progressText:SetText(targetValue.."/"..targetValue)
        else
            -- Check if the achievement should be unlocked based on current progress
            if currentProgress >= targetValue then
                -- Achievement should be unlocked
                achievement.unlocked = true
                achievement.completedDate = date("%d/%m/%Y %H:%M")

                -- Update the UI for newly unlocked achievement
                progressBar:SetMinMaxValues(0, targetValue)
                progressBar:SetValue(targetValue)
                progressText:SetText(targetValue.."/"..targetValue)

                -- Update icon to show as unlocked
                icon:SetDesaturated(false)

                -- Remove the gray overlay if it exists
                for _, child in pairs({tile:GetChildren()}) do
                    if child:IsObjectType("Texture") and child:GetObjectType() == "Texture" then
                        if child:GetAlpha() == 0.5 then
                            child:Hide()
                        end
                    end
                end

                -- Update title text color to gold
                title:SetTextColor(1, 0.82, 0)

                -- Update description text color to normal
                desc:SetTextColor(0.9, 0.9, 0.9)

                -- Add completion date text
                local completionDate = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                completionDate:SetPoint("TOP", progressBar, "BOTTOM", 0, -5)
                completionDate:SetText("Completed: " .. achievement.completedDate)
                completionDate:SetTextColor(0.7, 0.7, 0.7)

                -- Show achievement unlock popup
                if PVPSC.AchievementPopup then
                    PVPSC.AchievementPopup:ShowPopup({
                        icon = achievement.iconID,
                        title = achievement.title,
                        description = achievement.description
                    })
                end

                -- Store achievement completion in PSC_DB
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

        -- Add "Completed" label under the progress bar only if unlocked
        if achievement.unlocked and achievement.completedDate then
            local completionDate = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            completionDate:SetPoint("TOP", progressBar, "BOTTOM", 0, -5)  -- Center the completion date
            completionDate:SetText("Completed: " .. achievement.completedDate)
            completionDate:SetTextColor(0.7, 0.7, 0.7)
        end

        -- Add mouse interaction to show tooltips with subText
        tile:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            -- Get achievement rarity color
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

            -- Add achievement points in light blue next to the title
            local pointsText = achievement.achievementPoints or 10
            GameTooltip:SetText(achievement.title .. " |cFF66CCFF(" .. pointsText .. ")|r", r, g, b)

            GameTooltip:AddLine(achievement.description, 1, 1, 1, true)
            if achievement.subText then
                GameTooltip:AddLine(" ")
                local personalizedSubText = PersonalizeText(achievement.subText)
                GameTooltip:AddLine(personalizedSubText, 0.7, 0.7, 1, true)
            end
            GameTooltip:Show()
        end)

        tile:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- Adjust the content frame size to include vertical spacing
    local rowCount = math.ceil(#achievements / ACHIEVEMENTS_PER_ROW)
    local totalHeight = rowCount * (ACHIEVEMENT_HEIGHT + 5 + ACHIEVEMENT_SPACING_V)
    scrollContent:SetSize(scrollContent:GetWidth(), math.max(totalHeight, 1))
end

-- Update the CreateAchievementTabSystem function with fixed tab handling
local function CreateAchievementTabSystem(parent)
    local tabNames = {"Class", "Race", "Kills", "General"}
    local tabs = {}
    local tabWidth, tabHeight = 85, 32

    -- Create tab container
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

        -- Add click handler directly when creating the tab
        tab:SetScript("OnClick", function()
            currentCategory = name
            UpdateAchievementLayout()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            PanelTemplates_SetTab(parent, i)

            -- Apply tab resizing after selection
            for j = 1, #tabs do
                PanelTemplates_TabResize(tabs[j], 0)
            end
        end)

        tabs[i] = tab
    end

    -- Explicitly assign tabs and numTabs to parent frame
    parent.tabs = tabs
    parent.numTabs = #tabs

    -- Initialize tab system in correct order
    PanelTemplates_SetNumTabs(parent, #tabs)

    -- Apply tab resizing before selection
    for i = 1, #tabs do
        PanelTemplates_TabResize(tabs[i], 0)
    end

    -- Select first tab
    PanelTemplates_SetTab(parent, 1)

    return tabs
end

-- Call CreateAchievementTabSystem after the achievement frame is built:
CreateAchievementTabSystem(AchievementFrame)

-- Function to check if achievements are already completed from PSC_DB
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

-- Show the achievement frame
local function ToggleAchievementFrame()
    if AchievementFrame:IsShown() then
        AchievementFrame:Hide()
    else
        -- Load achievement completion status
        LoadAchievementCompletionStatus()

        -- Update achievement layout
        UpdateAchievementLayout()
        AchievementFrame:Show()
    end
end

-- Export functions to the PVPSC namespace
PVPSC.AchievementFrame = AchievementFrame
PVPSC.ToggleAchievementFrame = ToggleAchievementFrame
PVPSC.UpdateAchievementLayout = UpdateAchievementLayout

-- If no minimap button exists, provide another way to open it
SLASH_PVPSCACHIEVEMENTS1 = "/pvpachievements"
SlashCmdList["PVPSCACHIEVEMENTS"] = function()
    ToggleAchievementFrame()
end

local function GetCorrectKillStreakValue()
    local characterKey = PSC_GetCharacterKey()
    local highestStreak = 0

    -- Get value from summaryStats if available
    if summaryStats and summaryStats.highestKillStreak then
        highestStreak = summaryStats.highestKillStreak
    end

    -- Try playerStats if higher
    if playerStats and playerStats.highestKillStreak and playerStats.highestKillStreak > highestStreak then
        highestStreak = playerStats.highestKillStreak
    end

    -- Check direct DB as fallback if higher
    if PSC_DB and PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and
       PSC_DB.PlayerKillCounts.Characters[characterKey] and PSC_DB.PlayerKillCounts.Characters[characterKey].HighestKillStreak and
       PSC_DB.PlayerKillCounts.Characters[characterKey].HighestKillStreak > highestStreak then
        highestStreak = PSC_DB.PlayerKillCounts.Characters[characterKey].HighestKillStreak
    end

    return highestStreak
end

local itemQualityColors = {
    common = { r = 0.65, g = 0.65, b = 0.65 }, -- Gray
    uncommon = { r = 0.1, g = 1.0, b = 0.1 }, -- Green
    rare = { r = 0.0, g = 0.4, b = 1.0 }, -- Blue
    epic = { r = 0.8, g = 0.3, b = 0.9 }, -- Purple
    legendary = { r = 1.0, g = 0.5, b = 0.0 }, -- Orange
}