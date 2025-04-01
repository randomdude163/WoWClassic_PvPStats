local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

PVPSC.AchievementPopup = {}

local POPUP_DISPLAY_TIME = 5 -- Display for 5 seconds
local POPUP_FADE_TIME = 1 -- Fade out over 1 second

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

    frame:Hide()
    return frame
end

local popupFrame = CreateAchievementPopupFrame()

-- Show the popup
function PVPSC.AchievementPopup:ShowPopup(achievementData)
    if not achievementData then return end

    popupFrame.icon:SetTexture(achievementData.icon)
    popupFrame.achievementName:SetText(achievementData.title)
    popupFrame.description:SetText(achievementData.description)

    popupFrame:Show()
    popupFrame:SetAlpha(1)

    PlaySound(8173)

    -- Fade out after 5 seconds
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
    {
        id = "id_1",
        title = "HOLY MOLY!",
        description = "Slay 500 Paladins",
        iconID = 135971, -- spell-holy-sealofwrath
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
        end,
        unlocked = false,
        completedDate = nil -- Add completion date field
    },
    {
        id = "id_2",
        title = "Shadow Hunter",
        description = "Defeat 300 Priests",
        iconID = 136207, -- spell-shadow-shadowwordpain
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 300
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_3",
        title = "Warrior Slayer",
        description = "Eliminate 1000 Warriors",
        iconID = 132355, -- ability-warrior-charge
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 1000
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_4",
        title = "Mage Crusher",
        description = "Defeat 400 Mages",
        iconID = 135846, -- spell-frost-frostbolt02
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 400
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_5",
        title = "Rogue Hunter",
        description = "Uncover and defeat 250 Rogues",
        iconID = 132320, -- ability-rogue-sinisterstrike
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_6",
        title = "Warlock Nemesis",
        description = "Banish 350 Warlocks",
        iconID = 136197, -- spell-shadow-shadowbolt
        condition = function(playerStats)
            return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 350
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_7",
        title = "Wife Beater",
        description = "Defeat 100 female characters",
        iconID = 132938, -- spell-holy-powerwordshield, a protective shield icon
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil
    },
    {
        id = "id_8",
        title = "Gentleman's Bane",
        description = "Defeat 100 male characters",
        iconID = 132333, -- ability-warrior-bladestorm, a spinning blades icon
        condition = function(playerStats)
            return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
        end,
        unlocked = false,
        completedDate = nil
    }
}

-- Function to check achievements and show popup if newly unlocked
function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M") -- Set completion date
            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = achievement.description
            })
        end
    end
end

-- Test function to show the achievement popup
function AchievementSystem:TestAchievementPopup(achievementID)
    -- Find the achievement
    local achievement
    for _, ach in ipairs(self.achievements) do
        if ach.id == achievementID then
            achievement = ach
            break
        end
    end

    if achievement then
        -- Set the achievement as unlocked and store completion date
        achievement.unlocked = true
        achievement.completedDate = date("%d/%m/%Y %H:%M")

        -- Update progress data to show as completed
        local characterKey = PSC_GetCharacterKey()
        if not PSC_DB.PlayerKillCounts.Characters[characterKey].classKills then
            PSC_DB.PlayerKillCounts.Characters[characterKey].classKills = {}
        end
        if not PSC_DB.PlayerKillCounts.Characters[characterKey].genderKills then
            PSC_DB.PlayerKillCounts.Characters[characterKey].genderKills = {}
        end

        -- Set the appropriate kill count based on achievement type
        if achievement.id:match("^id_%d$") then
            local class = achievement.title:match("(%u%w+)")
            if class then
                PSC_DB.PlayerKillCounts.Characters[characterKey].classKills[class:upper()] = achievement.targetValue
            end
        elseif achievement.id == "id_7" then
            PSC_DB.PlayerKillCounts.Characters[characterKey].genderKills["FEMALE"] = 100
        elseif achievement.id == "id_8" then
            PSC_DB.PlayerKillCounts.Characters[characterKey].genderKills["MALE"] = 100
        end

        -- Show the popup
        PVPSC.AchievementPopup:ShowPopup({
            icon = achievement.iconID,
            title = achievement.title,
            description = achievement.description
        })

        -- Update achievement frame if it's visible
        if AchievementFrame and AchievementFrame:IsShown() then
            PVPSC.UpdateAchievementLayout()
        end
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