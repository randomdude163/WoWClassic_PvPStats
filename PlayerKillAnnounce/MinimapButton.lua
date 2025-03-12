local addonName, PKA = ...

-- Create the minimap button frame
local minimapButton = CreateFrame("Button", "PKAMinimapButton", Minimap)
minimapButton:SetSize(31, 31)  -- Standard size for minimap buttons
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetMovable(false)

-- Minimap button positioning variables
local minimapShape = "ROUND"
local rad = math.rad
local cos = math.cos
local sin = math.sin
local position = 195 -- Default angle
local isDragging = false

-- Define UpdatePosition function first
local function UpdatePosition()
    local angle = rad(position)
    local x, y = cos(angle), sin(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * 76, y * 76)
end

-- Set up the button texture (icon)
minimapButton.texture = minimapButton:CreateTexture(nil, "ARTWORK")
minimapButton.texture:SetSize(20, 20)  -- Standard minimap icon size
minimapButton.texture:SetPoint("TOPLEFT", 6, -6) -- Blizzard's standard offset
minimapButton.texture:SetTexture("Interface\\AddOns\\PlayerKillAnnounce\\img\\minimap")

-- Add gold border (Wowhead style)
minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
minimapButton.border:SetSize(53, 53)  -- Standard Blizzard border size
minimapButton.border:SetPoint("TOPLEFT") -- Proper Blizzard alignment
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Add hover effect
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Button scripts
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    isDragging = true
end)

minimapButton:SetScript("OnDragStop", function(self)
    isDragging = false
    PKA_MinimapPosition = position
end)

minimapButton:SetScript("OnUpdate", function(self)
    if isDragging then
        local xpos, ypos = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local minimapCenterX, minimapCenterY = Minimap:GetCenter()
        minimapCenterX = minimapCenterX * scale
        minimapCenterY = minimapCenterY * scale
        
        position = math.deg(math.atan2(ypos - minimapCenterY, xpos - minimapCenterX))
        UpdatePosition()
    end
end)

-- Set up click handler
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsControlKeyDown() then
            PKA_CreateKillStatsFrame()  -- Ctrl + Left Click for kills
        else
            PKA_CreateStatisticsFrame() -- Left Click for statistics
        end
    elseif button == "RightButton" then
        PKA_CreateConfigFrame()         -- Right Click for config
    end
end)

-- Initialize
minimapButton:RegisterEvent("PLAYER_LOGIN")
minimapButton:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        position = PKA_MinimapPosition or position
        UpdatePosition()
    end
end)

-- Add tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Player Kill Announce")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-Click: Statistics")
    GameTooltip:AddLine("Ctrl + Left-Click: Kill List")
    GameTooltip:AddLine("Right-Click: Configuration")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)