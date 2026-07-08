local addonName, PVPSC = ...

-- Create LibDataBroker data object
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("BigPPvPStats", {
    type = "data source",
    text = "BigPPvP Stats",
    icon = "Interface\\AddOns\\BigPPvPStats\\img\\minimap",
    OnClick = function(self, button)
        if button == "LeftButton" then
            if IsControlKeyDown() then
                BPP_CreateConfigFrame()
            elseif IsShiftKeyDown() then
                BPP_CreateLeaderboardFrame()
            else
                BPP_CreateStatisticsFrame()
            end
        elseif button == "RightButton" then
            if IsControlKeyDown() then
                BPP_ToggleAchievementFrame()
            elseif IsShiftKeyDown() then
                if BPP_ShowKOSListFrame then BPP_ShowKOSListFrame() end
            elseif IsAltKeyDown() then
                if BPP_ToggleNearbyPanel then BPP_ToggleNearbyPanel() end
            else
                BPP_CreateKillsListFrame()
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("BigPPvP Stats")
        tooltip:AddLine(" ")
        tooltip:AddLine("|cff87ceebLeft-Click:|r Statistics", 1, 1, 1)
        tooltip:AddLine("|cff87ceebRight-Click:|r History", 1, 1, 1)
        tooltip:AddLine("|cff87ceebShift+Left-Click:|r Leaderboard", 1, 1, 1)
        tooltip:AddLine("|cff87ceebCtrl+Left-Click:|r Settings", 1, 1, 1)
        tooltip:AddLine("|cff87ceebCtrl+Right-Click:|r Achievements", 1, 1, 1)
        tooltip:AddLine("|cff87ceebShift+Right-Click:|r Kill On Sight List", 1, 1, 1)
        tooltip:AddLine("|cff87ceebAlt+Right-Click:|r Toggle Nearby Panel", 1, 1, 1)
    end,
})

local icon = LibStub("LibDBIcon-1.0")
local isRegistered = false

function BPP_UpdateMinimapButtonPosition()
    -- Initialize the minimap button if it hasn't been initialized yet
    if not BPP_DB.minimapButton then
        BPP_DB.minimapButton = {
            hide = false,
        }
    end

    -- If we have an old position setting, convert it
    if BPP_DB.MinimapButtonPosition and not BPP_DB.minimapButton.minimapPos then
        BPP_DB.minimapButton.minimapPos = BPP_DB.MinimapButtonPosition
    end

    -- Only register once
    if not isRegistered then
        icon:Register("BigPPvPStats", LDB, BPP_DB.minimapButton)
        isRegistered = true
    end

    -- Show or hide based on settings
    if BPP_DB.minimapButton.hide then
        icon:Hide("BigPPvPStats")
    else
        icon:Show("BigPPvPStats")
    end
end
