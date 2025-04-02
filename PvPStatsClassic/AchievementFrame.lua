local addonName, PVPSC = ...

-- Create Achievement Overview Frame
local AchievementFrame = CreateFrame("Frame", "PVPSCAchievementFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
AchievementFrame:SetSize(800, 500)  -- Width and height
AchievementFrame:SetPoint("CENTER")
AchievementFrame:SetFrameStrata("HIGH")
AchievementFrame:SetMovable(true)
AchievementFrame:EnableMouse(true)
AchievementFrame:RegisterForDrag("LeftButton")
AchievementFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
AchievementFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
AchievementFrame:SetClampedToScreen(true)
AchievementFrame:Hide()

-- Add to special frames so it closes with Escape key
tinsert(UISpecialFrames, "PVPSCAchievementFrame")

-- Style the frame with a completely solid dark background
AchievementFrame:SetBackdrop({
    bgFile = "Interface\\BUTTONS\\WHITE8X8",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 11, top = 12, bottom = 11 }
})

-- Set the background color to pure black with no transparency
AchievementFrame:SetBackdropColor(0, 0, 0, 1) -- Fully opaque black

-- Add title
local titleText = AchievementFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -20)
titleText:SetText("PvP Achievements")
titleText:SetTextColor(1, 0.82, 0)

-- Add close button
local closeButton = CreateFrame("Button", nil, AchievementFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() AchievementFrame:Hide() end)

-- Create content area
local contentFrame = CreateFrame("Frame", nil, AchievementFrame)
contentFrame:SetPoint("TOPLEFT", AchievementFrame, "TOPLEFT", 20, -50)
contentFrame:SetPoint("BOTTOMRIGHT", AchievementFrame, "BOTTOMRIGHT", -20, 20)

-- Create scroll frame for achievements
local scrollFrame = CreateFrame("ScrollFrame", "PVPSCAchievementScrollFrame", contentFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, 0)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 0)

-- Create content for the scroll frame
local scrollContent = CreateFrame("Frame", "PVPSCAchievementContent", scrollFrame)
scrollContent:SetSize(scrollFrame:GetWidth(), 1) -- Height will be adjusted dynamically
scrollFrame:SetScrollChild(scrollContent)

-- Debug function to help identify issues with data
local function DebugPrint(message)
    if PSC_Debug then
        print("[PvPStats Debug]: " .. message)
    end
end

-- Function to dump table contents for debugging
local function DumpTable(tbl, indent)
    if not tbl then return "nil" end
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. DumpTable(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

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

-- Constants for achievement layout
local ACHIEVEMENT_WIDTH = 230
local ACHIEVEMENT_HEIGHT = 80
local ACHIEVEMENT_SPACING_H = 20
local ACHIEVEMENT_SPACING_V = 15
local ACHIEVEMENTS_PER_ROW = 3

-- Helper function to get player stats from PSC_DB
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

        -- Debug data
        if PSC_Debug then
            DebugPrint("Class data from PSC_CalculateBarChartStatistics:")
            for k, v in pairs(classData) do
                DebugPrint("  " .. k .. ": " .. v)
            end

            DebugPrint("Zone data from PSC_CalculateBarChartStatistics:")
            for k, v in pairs(zoneData) do
                DebugPrint("  " .. k .. ": " .. v)
            end
        end
    end

    -- Get summary statistics which include kill streak data
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

    -- Log for debugging
    if PSC_Debug then
        DebugPrint("Statistics Summary:")
        if playerStats.highestKillStreak then
            DebugPrint("Highest Kill Streak: " .. playerStats.highestKillStreak)
        end

        if playerStats.totalKills then
            DebugPrint("Total Kills: " .. playerStats.totalKills)
        end

        if playerStats.uniqueKills then
            DebugPrint("Unique Kills: " .. playerStats.uniqueKills)
        end

        if guildStatusData and guildStatusData["In Guild"] then
            DebugPrint("Guild Kills: " .. guildStatusData["In Guild"])
        end

        if guildStatusData and guildStatusData["No Guild"] then
            DebugPrint("Lone Wolf Kills: " .. guildStatusData["No Guild"])
        end
    end

    return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, summaryStats, playerStats
end

-- Function to update achievement layout
local function UpdateAchievementLayout()
    -- Clear existing achievement frames first
    for _, child in pairs({scrollContent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local achievements = PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements or {}
    if #achievements == 0 then
        DebugPrint("No achievements found")
        return
    end

    -- Get statistics and player stats
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, summaryStats, playerStats =
        GetStatistics()

    -- Log for debugging
    DebugPrint("Highest Kill Streak: " .. (playerStats.highestKillStreak or 0))
    DebugPrint("Guild Kills: " .. (playerStats.guildedKills or 0))
    DebugPrint("Lone Wolf Kills: " .. (playerStats.loneWolfKills or 0))

    -- Update the layout for each achievement
    for i, achievement in ipairs(achievements) do
        -- Calculate column and row positions
        local column = (i - 1) % ACHIEVEMENTS_PER_ROW
        local row = math.floor((i - 1) / ACHIEVEMENTS_PER_ROW)

        local xPos = column * (ACHIEVEMENT_WIDTH + ACHIEVEMENT_SPACING_H)
        local yPos = -row * (ACHIEVEMENT_HEIGHT + ACHIEVEMENT_SPACING_V)

        -- Create achievement tile
        local tile = CreateFrame("Button", nil, scrollContent, BackdropTemplateMixin and "BackdropTemplate")
        tile:SetSize(ACHIEVEMENT_WIDTH, ACHIEVEMENT_HEIGHT + 5) -- Increased height by 5 pixels
        tile:SetPoint("TOPLEFT", xPos, yPos)

        -- Style the tile
        tile:SetBackdrop({
            bgFile = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })

        if not achievement.unlocked then
            -- Gray out locked achievements
            local overlay = tile:CreateTexture(nil, "OVERLAY")
            overlay:SetAllPoints()
            overlay:SetColorTexture(0, 0, 0, 0.5)
        end

        -- Add achievement icon
        local icon = tile:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("TOPLEFT", 10, -10)
        icon:SetTexture(achievement.iconID)
        if not achievement.unlocked then
            icon:SetDesaturated(true)
        end

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
            DebugPrint("Paladin kills: " .. currentProgress)
        elseif achievement.id == "paladin_2" then
            targetValue = 500
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "paladin_3" then
            targetValue = 750
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "priest_1" then
            targetValue = 250
            currentProgress = classData["Priest"] or 0
            DebugPrint("Priest kills: " .. currentProgress)
        elseif achievement.id == "priest_2" then
            targetValue = 500
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "priest_3" then
            targetValue = 750
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "warrior_1" then
            targetValue = 250
            currentProgress = classData["Warrior"] or 0
            DebugPrint("Warrior kills: " .. currentProgress)
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
        elseif achievement.id:match("^race_") then
            local race = achievement.id:match("^race_([^_]+)")
            local level = achievement.id:match("_(%d+)$")

            if race and level then
                if level == "1" then
                    targetValue = 50
                elseif level == "2" then
                    targetValue = 100
                elseif level == "3" then
                    targetValue = 200
                end

                -- Handle different race name formats with proper casing
                if race:lower() == "nightelf" then
                    currentProgress = raceData["Night Elf"] or 0
                    DebugPrint("Night Elf kills: " .. currentProgress)
                elseif race:lower() == "gnome" then
                    currentProgress = raceData["Gnome"] or 0
                    DebugPrint("Gnome kills: " .. currentProgress)
                elseif race:lower() == "human" then
                    currentProgress = raceData["Human"] or 0
                    DebugPrint("Human kills: " .. currentProgress)
                elseif race:lower() == "dwarf" then
                    currentProgress = raceData["Dwarf"] or 0
                    DebugPrint("Dwarf kills: " .. (raceData["Dwarf"] or 0))
                elseif race:lower() == "orc" then
                    currentProgress = raceData["Orc"] or 0
                    DebugPrint("Orc kills: " .. (raceData["Orc"] or 0))
                elseif race:lower() == "troll" then
                    currentProgress = raceData["Troll"] or 0
                    DebugPrint("Troll kills: " .. (raceData["Troll"] or 0))
                elseif race:lower() == "tauren" then
                    currentProgress = raceData["Tauren"] or 0
                    DebugPrint("Tauren kills: " .. (raceData["Tauren"] or 0))
                elseif race:lower() == "undead" then
                    currentProgress = raceData["Undead"] or raceData["Scourge"] or 0
                    DebugPrint("Undead kills: " .. (raceData["Undead"] or raceData["Scourge"] or 0))
                else
                    -- Properly capitalize the race name for lookup
                    local properRace = race:sub(1,1):upper() .. race:sub(2):lower()
                    currentProgress = raceData[properRace] or 0
                    DebugPrint(properRace .. " kills: " .. (raceData[properRace] or 0))
                end
            end
        elseif achievement.id == "guild_prey_kills_1" then
            targetValue = 250
            currentProgress = guildStatusData["In Guild"] or playerStats.guildedKills or 0
            DebugPrint("Guild prey kills: " .. currentProgress)
        elseif achievement.id == "guild_prey_kills_2" then
            targetValue = 500
            currentProgress = guildStatusData["In Guild"] or playerStats.guildedKills or 0
        elseif achievement.id == "guild_prey_kills_3" then
            targetValue = 700
            currentProgress = guildStatusData["In Guild"] or playerStats.guildedKills or 0
        elseif achievement.id == "lone_prey_kills_1" then
            targetValue = 250
            currentProgress = guildStatusData["No Guild"] or playerStats.loneWolfKills or 0
            DebugPrint("Lone wolf kills: " .. currentProgress)
        elseif achievement.id == "lone_prey_kills_2" then
            targetValue = 500
            currentProgress = guildStatusData["No Guild"] or playerStats.loneWolfKills or 0
        elseif achievement.id == "lone_prey_kills_3" then
            targetValue = 700
            currentProgress = guildStatusData["No Guild"] or playerStats.loneWolfKills or 0
        elseif achievement.id == "killing_spree_1" then
            targetValue = 25
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
            DebugPrint("Kill Streak for achievement killing_spree_1: " .. currentProgress)
        elseif achievement.id == "killing_spree_2" then
            targetValue = 50
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
            DebugPrint("Kill Streak for achievement killing_spree_2: " .. currentProgress)
        elseif achievement.id == "killing_spree_3" then
            targetValue = 75
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
            DebugPrint("Kill Streak for achievement killing_spree_3: " .. currentProgress)
        elseif achievement.id == "killing_spree_4" then
            targetValue = 100
            currentProgress = summaryStats.highestKillStreak or playerStats.highestKillStreak or 0
            DebugPrint("Kill Streak for achievement killing_spree_4: " .. currentProgress)
        elseif achievement.id == "zone_redridge" then
            targetValue = 500
            currentProgress = zoneData["Redridge Mountains"] or 0
            DebugPrint("Redridge Mountains kills: " .. (currentProgress or 0))
        elseif achievement.id == "zone_elwynn" then
            targetValue = 100
            currentProgress = zoneData["Elwynn Forest"] or 0
            DebugPrint("Elwynn Forest kills: " .. (currentProgress or 0))
        elseif achievement.id == "zone_duskwood" then
            targetValue = 100
            currentProgress = zoneData["Duskwood"] or 0
            DebugPrint("Duskwood kills: " .. (currentProgress or 0))
        elseif achievement.id == "total_kills_1" then
            targetValue = 500
            currentProgress = summaryStats.totalKills or 0
            DebugPrint("Total kills progress for achievement total_kills_1: " .. (currentProgress or 0))
        elseif achievement.id == "total_kills_2" then
            targetValue = 1000
            currentProgress = summaryStats.totalKills or 0
            DebugPrint("Total kills progress for achievement total_kills_2: " .. (currentProgress or 0))
        elseif achievement.id == "total_kills_3" then
            targetValue = 3000
            currentProgress = summaryStats.totalKills or 0
            DebugPrint("Total kills progress for achievement total_kills_3: " .. (currentProgress or 0))
        elseif achievement.id == "unique_kills_1" then
            targetValue = 400
            currentProgress = summaryStats.uniqueKills or 0
            DebugPrint("Unique kills progress for achievement unique_kills_1: " .. (currentProgress or 0))
        elseif achievement.id == "unique_kills_2" then
            targetValue = 800
            currentProgress = summaryStats.uniqueKills or 0
            DebugPrint("Unique kills progress for achievement unique_kills_2: " .. (currentProgress or 0))
        elseif achievement.id == "unique_kills_3" then
            targetValue = 2400
            currentProgress = summaryStats.uniqueKills or 0
            DebugPrint("Unique kills progress for achievement unique_kills_3: " .. (currentProgress or 0))
        end

        -- Add achievement title first (before we try to reference it)
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
                -- Still working on this achievement
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
            GameTooltip:SetText(achievement.title, 1, 0.82, 0)
            GameTooltip:AddLine(achievement.description, 1, 1, 1, true)
            if achievement.subText then
                GameTooltip:AddLine(" ")
                -- Personalize the subtext by replacing [YOUR NAME] with actual player name
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