local addonName, PVPSC = ...

-- Create Achievement Overview Frame
local AchievementFrame = CreateFrame("Frame", "PVPSCAchievementFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
AchievementFrame:SetSize(650, 500)
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

-- Style the frame with a darker background to match the Statistics window
AchievementFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 11, top = 12, bottom = 11 }
})

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
local ACHIEVEMENT_WIDTH = 180
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

    local rowCount = math.ceil(#achievements / ACHIEVEMENTS_PER_ROW)
    local totalWidth = ACHIEVEMENTS_PER_ROW * ACHIEVEMENT_WIDTH + (ACHIEVEMENTS_PER_ROW - 1) * ACHIEVEMENT_SPACING_H
    local totalHeight = rowCount * ACHIEVEMENT_HEIGHT + (rowCount - 1) * ACHIEVEMENT_SPACING_V

    contentFrame:SetSize(totalWidth, totalHeight)

    for i, achievement in ipairs(achievements) do
        local column = (i - 1) % ACHIEVEMENTS_PER_ROW
        local row = math.floor((i - 1) / ACHIEVEMENTS_PER_ROW)

        local xPos = column * (ACHIEVEMENT_WIDTH + ACHIEVEMENT_SPACING_H)
        local yPos = -row * (ACHIEVEMENT_HEIGHT + ACHIEVEMENT_SPACING_V)

        -- Create achievement tile
        local tile = CreateFrame("Button", nil, contentFrame, BackdropTemplateMixin and "BackdropTemplate")
        tile:SetSize(ACHIEVEMENT_WIDTH, ACHIEVEMENT_HEIGHT)
        tile:SetPoint("TOPLEFT", xPos, yPos)

        -- Style the tile with a better contrast for the dark background
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

        -- Add tooltip
        tile:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(achievement.title, 1, 0.82, 0, 1)
            GameTooltip:AddLine(achievement.description, 1, 1, 1, true)

            if not achievement.unlocked then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Not yet unlocked", 0.6, 0.6, 0.6)
            else
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Achievement Unlocked!", 0, 1, 0)
            end

            GameTooltip:Show()
        end)
        tile:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
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