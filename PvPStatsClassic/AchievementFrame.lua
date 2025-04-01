local addonName, PVPSC = ...

-- Create Achievement Overview Frame
local AchievementFrame = CreateFrame("Frame", "PVPSCAchievementFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
AchievementFrame:SetSize(800, 500)  -- Increased width from 650 to 800
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

-- Create scroll frame for achievements
local scrollFrame = CreateFrame("ScrollFrame", "PVPSCAchievementScrollFrame", AchievementFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 20, -50)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)

-- Create content frame for the scroll frame
local contentFrame = CreateFrame("Frame", "PVPSCAchievementContentFrame", scrollFrame)
contentFrame:SetSize(scrollFrame:GetWidth(), 1) -- Height will be adjusted dynamically
scrollFrame:SetScrollChild(contentFrame)

-- Constants for achievement layout
local ACHIEVEMENT_WIDTH = 230  -- Increased width from 180 to 230
local ACHIEVEMENT_HEIGHT = 80
local ACHIEVEMENT_SPACING_H = 20
local ACHIEVEMENT_SPACING_V = 15
local ACHIEVEMENTS_PER_ROW = 3

-- Function to update achievement layout
local function UpdateAchievementLayout()
    -- Clear existing achievement frames first
    for _, child in pairs({contentFrame:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local achievements = PVPSC.AchievementSystem.achievements
    if not achievements or #achievements == 0 then
        return
    end

    -- Update the layout for each achievement
    for i, achievement in ipairs(achievements) do
        -- Calculate column and row positions
        local column = (i - 1) % ACHIEVEMENTS_PER_ROW
        local row = math.floor((i - 1) / ACHIEVEMENTS_PER_ROW)

        local xPos = column * (ACHIEVEMENT_WIDTH + ACHIEVEMENT_SPACING_H)
        local yPos = -row * (ACHIEVEMENT_HEIGHT + ACHIEVEMENT_SPACING_V)

        -- Create achievement tile
        local tile = CreateFrame("Button", nil, contentFrame, BackdropTemplateMixin and "BackdropTemplate")
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

        local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData =
            PSC_CalculateBarChartStatistics()

        local function countTableEntries(t)
            local count = 0
            for _ in pairs(t) do count = count + 1 end
            return count
        end

        -- Debug print using the correct counting method
        print("Entries in tables:",
            countTableEntries(classData),
            countTableEntries(raceData),
            countTableEntries(genderData),
            countTableEntries(unknownLevelClassData),
            countTableEntries(zoneData),
            countTableEntries(levelData),
            countTableEntries(guildStatusData))

        for className, kills in pairs(classData) do
            print("Class " .. className .. " - " .. kills .. " kills")
        end

        local summaryStatistics = PSC_CalculateSummaryStatistics()
        local totalKills = summaryStatistics.totalKills
        print("Total Kills: ", totalKills)

        local guildKills = PSC_CalculateGuildKills()
        for guildName, kills in pairs(guildKills) do
            print("Guild " .. guildName .. " - " .. kills .. " kills")
        end

        -- print("Using account-wide stats:", PSC_DB.ShowAccountWideStats and "Yes" or "No")

        if achievement.id == "id_1" then -- HOLY MOLY (Paladins)
            targetValue = 500
            currentProgress = classData["Paladin"] or 0
        elseif achievement.id == "id_2" then -- Shadow Hunter (Priests)
            targetValue = 300
            currentProgress = classData["Priest"] or 0
        elseif achievement.id == "id_3" then -- Warrior Slayer
            targetValue = 1000
            currentProgress = classData["Warrior"] or 0
        elseif achievement.id == "id_4" then -- Mage Crusher
            targetValue = 400
            currentProgress = classData["Mage"] or 0
        elseif achievement.id == "id_5" then -- Rogue Hunter
            targetValue = 250
            currentProgress = classData["Rogue"] or 0
        elseif achievement.id == "id_6" then -- Warlock Nemesis
            targetValue = 350
            currentProgress = classData["Warlock"] or 0
        elseif achievement.id == "id_7" then -- Wife Beater
            targetValue = 100
            currentProgress = genderData["Female"] or 0
        elseif achievement.id == "id_8" then -- Gentleman's Bane
            targetValue = 100
            currentProgress = genderData["Male"] or 0
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
            progressBar:SetMinMaxValues(0, targetValue)
            progressBar:SetValue(currentProgress)
            progressText:SetText(currentProgress.."/"..targetValue)
        end

        -- Add "Completed" label under the progress bar only if unlocked
        if achievement.unlocked and achievement.completedDate then
            local completionDate = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            completionDate:SetPoint("TOP", progressBar, "BOTTOM", 0, -5)  -- Center the completion date
            completionDate:SetText("Completed: " .. achievement.completedDate)
            completionDate:SetTextColor(0.7, 0.7, 0.7)
        end

        -- Add achievement title
        local title = tile:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
        title:SetPoint("RIGHT", tile, "RIGHT", -10, 0)
        title:SetJustifyH("LEFT")
        title:SetText(achievement.title)
        if not achievement.unlocked then
            title:SetTextColor(0.5, 0.5, 0.5)
        else
            title:SetTextColor(1, 0.82, 0) -- Gold color for unlocked achievements
        end

        -- Add achievement description
        local desc = tile:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
        desc:SetPoint("RIGHT", tile, "RIGHT", -10, 0)
        desc:SetJustifyH("LEFT")
        desc:SetText(achievement.description)
        if not achievement.unlocked then
            desc:SetTextColor(0.4, 0.4, 0.4)
        else
            desc:SetTextColor(0.9, 0.9, 0.9)
        end
    end

    -- Adjust the content frame size to include vertical spacing
    local rowCount = math.ceil(#achievements / ACHIEVEMENTS_PER_ROW)
    local totalHeight = rowCount * (ACHIEVEMENT_HEIGHT + 5 + ACHIEVEMENT_SPACING_V) -- Include the increased height
    contentFrame:SetSize(contentFrame:GetWidth(), totalHeight)
end

-- Show the achievement frame
function PVPSC:ToggleAchievementFrame()
    if AchievementFrame:IsShown() then
        AchievementFrame:Hide()
    else
        UpdateAchievementLayout()
        AchievementFrame:Show()
    end
end

-- If no minimap button exists, provide another way to open it
SLASH_PVPSCACHIEVEMENTS1 = "/pvpachievements"
SlashCmdList["PVPSCACHIEVEMENTS"] = function()
    PVPSC:ToggleAchievementFrame()
end

-- Make sure achievement frames are updated when achievements change
if PVPSC.AchievementSystem then
    local oldShowPopup = PVPSC.AchievementSystem.ShowAchievementPopup
    PVPSC.AchievementSystem.ShowAchievementPopup = function(self, achievement)
        oldShowPopup(self, achievement)
        -- Update layout if frame is visible
        if AchievementFrame:IsShown() then
            UpdateAchievementLayout()
        end
    end
end

-- Initialize when addon is fully loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterAllEvents()
    end
end)

-- Export functions
PVPSC.AchievementFrame = AchievementFrame
PVPSC.UpdateAchievementLayout = UpdateAchievementLayout
PVPSC.ToggleAchievementFrame = function()
    if AchievementFrame:IsShown() then
        AchievementFrame:Hide()
    else
        UpdateAchievementLayout()
        AchievementFrame:Show()
    end
end

-- Also add a slash command
SLASH_PVPSCACHIEVEMENTS1 = "/pvpachievements"
SlashCmdList["PVPSCACHIEVEMENTS"] = function()
    PVPSC:ToggleAchievementFrame()
end