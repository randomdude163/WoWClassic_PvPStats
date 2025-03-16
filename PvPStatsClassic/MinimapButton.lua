local minimapButton = CreateFrame("Button", "PKAMinimapButton", Minimap)
minimapButton:SetSize(31, 31) -- Standard size for minimap buttons
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetMovable(false)

local minimapShape = "ROUND"
local rad = math.rad
local cos = math.cos
local sin = math.sin
local position = 195 -- Default angle
local isDragging = false

local function UpdatePosition()
    local angle = rad(position)
    local x, y = cos(angle), sin(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * 76, y * 76)
end

minimapButton.texture = minimapButton:CreateTexture(nil, "ARTWORK")
minimapButton.texture:SetSize(20, 20)            -- Standard minimap icon size
minimapButton.texture:SetPoint("TOPLEFT", 6, -6) -- Blizzard's standard offset
minimapButton.texture:SetTexture("Interface\\AddOns\\PvPStatsClassic\\img\\minimap")

minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
minimapButton.border:SetSize(53, 53)     -- Standard Blizzard border size
minimapButton.border:SetPoint("TOPLEFT") -- Proper Blizzard alignment
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    isDragging = true
end)

minimapButton:SetScript("OnDragStop", function(self)
    isDragging = false
    PKA_MinimapPosition = position
    -- Save to database when position changes
    if PlayerKillAnnounceDB then
        PlayerKillAnnounceDB.PKA_MinimapPosition = position
    end
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

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsControlKeyDown() then
            PKA_CreateConfigFrame()
        else
            PKA_CreateStatisticsFrame()
        end
    elseif button == "RightButton" then
        PKA_CreateKillStatsFrame()
    end
end)

minimapButton:RegisterEvent("PLAYER_LOGIN")
minimapButton:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Load position from saved variables
        if PlayerKillAnnounceDB and PlayerKillAnnounceDB.PKA_MinimapPosition then
            position = PlayerKillAnnounceDB.PKA_MinimapPosition
        end
        UpdatePosition()
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Player Kill Announce")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-Click: Statistics")
    GameTooltip:AddLine("Right-Click: Kills List")
    GameTooltip:AddLine("Ctrl + Left-Click: Configuration")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
