local minimapButton = CreateFrame("Button", "PSC_MinimapButton", Minimap)
minimapButton:SetSize(31, 31) -- Standard size for minimap buttons
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetMovable(false)

minimapButton.texture = minimapButton:CreateTexture(nil, "ARTWORK")
minimapButton.texture:SetSize(20, 20)            -- Standard minimap icon size
minimapButton.texture:SetPoint("TOPLEFT", 6, -6) -- Blizzard's standard offset
minimapButton.texture:SetTexture("Interface\\AddOns\\PvPStatsClassic\\img\\minimap")

minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
minimapButton.border:SetSize(53, 53)     -- Standard Blizzard border size
minimapButton.border:SetPoint("TOPLEFT") -- Proper Blizzard alignment
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

function PSC_UpdateMinimapButtonPosition()
    local angle = math.rad(PSC_DB.MinimapButtonPosition)
    local x, y = math.cos(angle), math.sin(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * 76, y * 76)
end

local minimapButtonBeingDragged = false

minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    minimapButtonBeingDragged = true
end)

minimapButton:SetScript("OnDragStop", function(self)
    minimapButtonBeingDragged = false
end)

minimapButton:SetScript("OnUpdate", function(self)
    if minimapButtonBeingDragged then
        local xpos, ypos = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        local minimapCenterX, minimapCenterY = Minimap:GetCenter()
        minimapCenterX = minimapCenterX * scale
        minimapCenterY = minimapCenterY * scale

        PSC_DB.MinimapButtonPosition = math.deg(math.atan2(ypos - minimapCenterY, xpos - minimapCenterX))
        PSC_UpdateMinimapButtonPosition()
    end
end)

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsControlKeyDown() then
            PSC_CreateConfigFrame()
        else
            PSC_CreateStatisticsFrame()
        end
    elseif button == "RightButton" then
        PSC_CreateKillStatsFrame()
    end
end)


minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("PvP Stats Classic")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-Click: Statistics")
    GameTooltip:AddLine("Right-Click: Kills List")
    GameTooltip:AddLine("Ctrl + Left-Click: Settings")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
