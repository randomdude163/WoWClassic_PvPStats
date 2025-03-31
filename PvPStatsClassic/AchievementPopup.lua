local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

local POPUP_DISPLAY_TIME = 4
local POPUP_FADE_TIME = 1

local function CreateAchievementPopupFrame()
    local frame = CreateFrame("Frame", "PVPStatsClassicAchievementPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(200, 82)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Set up the backdrop similar to KillMilestone
    local backdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    }

    if frame.SetBackdrop then
        frame:SetBackdrop(backdrop)
    else
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(backdrop.bgFile)
        bg:SetAllPoints(frame)
        bg:SetTexCoord(0, 1, 0, 1)

        local border = frame:CreateTexture(nil, "BORDER")
        border:SetTexture(backdrop.edgeFile)
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", -backdrop.edgeSize/2, backdrop.edgeSize/2)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", backdrop.edgeSize/2, -backdrop.edgeSize/2)
    end

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    title:SetText("Achievement Unlocked!")
    title:SetTextColor(1, 0.82, 0)
    frame.title = title

    local leftMargin = 20

    -- Achievement Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftMargin, -30)
    frame.icon = icon

    -- Achievement Name
    local achievementName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    achievementName:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 0)
    achievementName:SetJustifyH("LEFT")
    achievementName:SetTextColor(1, 0.82, 0)
    frame.achievementName = achievementName

    -- Description
    local description = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", achievementName, "BOTTOMLEFT", 0, -5)
    description:SetTextColor(0.8, 0.8, 0.8)
    description:SetJustifyH("LEFT")
    frame.description = description

    -- Close Button
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    close:SetSize(20, 20)
    close:SetScript("OnClick", function() frame:Hide() end)

    frame:Hide()
    return frame
end

local popupFrame = CreateAchievementPopupFrame()

function PVPStatsClassic_ShowAchievementPopup(achievementData)
    if not achievementData then return end

    popupFrame.icon:SetTexture(achievementData.icon)
    popupFrame.achievementName:SetText(achievementData.title)
    popupFrame.description:SetText(achievementData.description)

    -- Adjust frame width based on text
    local nameWidth = popupFrame.achievementName:GetStringWidth()
    local descWidth = popupFrame.description:GetStringWidth()
    local requiredWidth = math.max(nameWidth, descWidth)
    local frameWidth = math.max(200, math.min(300, requiredWidth + 70)) -- 70 for margins and icon

    popupFrame:SetWidth(frameWidth)
    popupFrame.achievementName:SetWidth(frameWidth - 70)
    popupFrame.description:SetWidth(frameWidth - 70)

    -- Show popup with animation
    popupFrame:Show()
    popupFrame:SetAlpha(1)

    -- Play sound
    PlaySound(8213) -- Same sound as kill milestone

    -- Set up fade out
    C_Timer.After(POPUP_DISPLAY_TIME, function()
        local fadeInfo = {
            mode = "OUT",
            timeToFade = POPUP_FADE_TIME,
            finishedFunc = function() popupFrame:Hide() end,
        }
        UIFrameFade(popupFrame, fadeInfo)
    end)
end

-- Achievement data structure
AchievementSystem.achievements = {
    -- Example achievement
    {
        id = "HOLY_MOLY",
        title = "HOLY MOLY!",
        description = "Slay 500 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
        end,
        unlocked = false
    },
    -- Add more achievements here following the same structure
}

-- Function to check achievements and show popup if newly unlocked
function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            PVPStatsClassic_ShowAchievementPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = achievement.description
            })
        end
    end
end

-- Test function to show the achievement popup
function AchievementSystem:TestAchievementPopup(achievementID)
    local achievement

    if achievementID then
        for _, ach in ipairs(self.achievements) do
            if ach.id == achievementID then
                achievement = ach
                break
            end
        end
    else
        achievement = self.achievements[1] -- Default to first achievement if none specified
    end

    if achievement then
        PVPStatsClassic_ShowAchievementPopup({
            icon = achievement.iconID,
            title = achievement.title,
            description = achievement.description
        })
    end
end

-- Register events for checking achievements
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialize achievement system
        C_Timer.After(2, function()
            AchievementSystem:CheckAchievements()
        end)
    elseif event == "PVPSC_KILL_ADDED" then
        -- Check achievements when a new kill is recorded
        AchievementSystem:CheckAchievements()
    end
end)

-- Function to make the custom event work
-- This needs to be called from your main addon file whenever a kill is recorded
function AchievementSystem:NotifyKillAdded()
    -- This is a workaround for custom events
    eventFrame:GetScript("OnEvent")(eventFrame, "PVPSC_KILL_ADDED")
end

-- Make functions available in the addon namespace
PVPSC.AchievementSystem = AchievementSystem