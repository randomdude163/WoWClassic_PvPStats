local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

PVPSC.AchievementPopup = {}
local AchievementPopup = PVPSC.AchievementPopup

-- Settings
local POPUP_DISPLAY_TIME = 5 -- Display for 5 seconds
local POPUP_FADE_TIME = 1 -- Fade out over 1 second

-- Queue system for sequential achievement display
AchievementPopup.queue = {}
AchievementPopup.isDisplaying = false
AchievementPopup.currentTimer = nil -- Track the current fade timer

-- Create the popup frame
local function CreateAchievementPopupFrame()
    local frame = CreateFrame("Frame", "PVPStatsClassicAchievementPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(300, 100)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)

    -- Match the AchievementFrame background design
    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 11, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0, 0, 0, 1) -- Fully opaque black background

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("Achievement Unlocked!")
    title:SetTextColor(1, 0.82, 0) -- Gold text
    title:SetJustifyH("CENTER") -- Center horizontally
    frame.title = title

    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -40)
    frame.icon = icon

    -- Achievement Name
    local achievementName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    achievementName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    achievementName:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    achievementName:SetTextColor(1, 0.82, 0) -- Gold text
    achievementName:SetJustifyH("LEFT") -- Align left
    frame.achievementName = achievementName

    -- Description
    local description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", achievementName, "BOTTOMLEFT", 0, -5)
    description:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    description:SetTextColor(0.9, 0.9, 0.9) -- Light gray text
    description:SetJustifyH("LEFT") -- Align left
    frame.description = description

    -- Create Close Button in top-right corner
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeButton:SetSize(24, 24)
    closeButton:SetScript("OnClick", function()
        -- Cancel the fade timer if it exists
        if AchievementPopup.currentTimer then
            AchievementPopup.currentTimer:Cancel()
            AchievementPopup.currentTimer = nil
        end

        -- Hide the current popup immediately
        frame:Hide()

        -- Process the next achievement in the queue after a short delay
        C_Timer.After(0.1, function()
            AchievementPopup:ProcessQueue()
        end)
    end)
    frame.closeButton = closeButton

    frame:Hide()
    return frame
end

local popupFrame = CreateAchievementPopupFrame()

-- Function to add an achievement to the queue
function AchievementPopup:QueuePopup(achievementData)
    if not achievementData then return end

    table.insert(self.queue, achievementData)

    -- Start processing the queue if not already displaying
    if not self.isDisplaying then
        self:ProcessQueue()
    end
end

-- Function to process the achievement queue
function AchievementPopup:ProcessQueue()
    if #self.queue == 0 then
        self.isDisplaying = false
        return
    end

    self.isDisplaying = true
    local nextAchievement = table.remove(self.queue, 1)
    self:DisplayPopup(nextAchievement)
end

-- Function to display a single achievement popup
function AchievementPopup:DisplayPopup(achievementData)
    -- Cancel any existing timer
    if self.currentTimer then
        self.currentTimer:Cancel()
        self.currentTimer = nil
    end

    -- Set up icon and text
    popupFrame.icon:SetTexture(achievementData.icon)
    popupFrame.achievementName:SetText(achievementData.title)
    popupFrame.description:SetText(achievementData.description)

    -- Apply rarity-based coloring to the border
    local rarity = achievementData.rarity or "common"
    if rarity == "uncommon" then
        popupFrame:SetBackdropBorderColor(0.1, 1.0, 0.1) -- Green
    elseif rarity == "rare" then
        popupFrame:SetBackdropBorderColor(0.0, 0.4, 1.0) -- Blue
    elseif rarity == "epic" then
        popupFrame:SetBackdropBorderColor(0.8, 0.3, 0.9) -- Purple
    elseif rarity == "legendary" then
        popupFrame:SetBackdropBorderColor(1.0, 0.5, 0.0) -- Orange
    else
        popupFrame:SetBackdropBorderColor(0.7, 0.7, 0.7) -- Light gray for common
    end

    -- Set title color based on rarity
    if rarity == "legendary" then
        popupFrame.achievementName:SetTextColor(1.0, 0.5, 0.0) -- Orange for legendary
    elseif rarity == "epic" then
        popupFrame.achievementName:SetTextColor(0.8, 0.3, 0.9) -- Purple for epic
    elseif rarity == "rare" then
        popupFrame.achievementName:SetTextColor(0.0, 0.4, 1.0) -- Blue for rare
    elseif rarity == "uncommon" then
        popupFrame.achievementName:SetTextColor(0.1, 1.0, 0.1) -- Green for uncommon
    else
        popupFrame.achievementName:SetTextColor(1.0, 0.82, 0) -- Default gold color
    end

    popupFrame:Show()
    popupFrame:SetAlpha(1)

    -- Play sound based on rarity
    local soundID = 8173  -- Default achievement sound
    PlaySound(soundID)

    -- Set up the fade timer and store it so we can cancel if needed
    self.currentTimer = C_Timer.NewTimer(POPUP_DISPLAY_TIME, function()
        local fadeInfo = {
            mode = "OUT",
            timeToFade = POPUP_FADE_TIME,
            finishedFunc = function()
                popupFrame:Hide()
                self.currentTimer = nil
                -- Process next achievement after this one has fully faded out
                C_Timer.After(0.1, function()
                    self:ProcessQueue()
                end)
            end,
        }
        UIFrameFade(popupFrame, fadeInfo)
    end)
end

-- Replace the old ShowPopup function to use our queue system
function PVPSC.AchievementPopup:ShowPopup(achievementData)
    self:QueuePopup(achievementData)
end


function AchievementSystem:TestAchievementPopup()
    -- Show multiple test achievements to demonstrate the queue
    for i = 1, 3 do
        -- Create a special test achievement with different rarity each time
        local rarities = {"common", "uncommon", "rare", "epic", "legendary"}
        -- Use a different rarity for each test achievement
        local rarityIndex = (math.floor(GetTime()) % 5) + 1
        local currentRarity = rarities[((rarityIndex + i - 1) % 5) + 1]

        -- Use a different icon for each test achievement
        local testIcons = {
            132127, -- Ability_Hunter_SniperShot
            134400, -- INV_Sword_04
            133078, -- Spell_Shadow_SoulLeech_2
            136105, -- Spell_Holy_PowerInfusion
            135770, -- Spell_Frost_FrostBolt02
            236444  -- Achievement_Character_Dwarf_Male
        }
        local iconIndex = ((math.floor(GetTime()) + i) % #testIcons) + 1
        local iconID = testIcons[iconIndex]

        -- Queue the test achievement popup
        PVPSC.AchievementPopup:QueuePopup({
            icon = iconID,
            title = "Test Achievement " .. i .. " (" .. currentRarity .. ")",
            description = "This is test achievement #" .. i .. " with " .. currentRarity .. " rarity!",
            rarity = currentRarity
        })
    end
end


-- Make functions available in the addon namespace
PVPSC.AchievementSystem = AchievementSystem