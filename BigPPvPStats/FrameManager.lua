if not BPP_ActiveFrameLevel then
    BPP_ActiveFrameLevel = 100
end

BPP_FrameManager = {}
BPP_FrameManager.frames = {}
BPP_FrameManager.frameOrder = {}
BPP_FrameManager.baseLevel = 100
BPP_FrameManager.levelStep = 10
BPP_FrameManager.maxFrames = 10

function BPP_FrameManager:RegisterFrame(frame, frameName, isNotificationPopup)
    if not frame or not frameName then
        return
    end

    self.frames[frameName] = frame

    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(self.baseLevel)

    -- Only add mouse and keyboard handling for interactive frames, not notification popups
    if not isNotificationPopup then
        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                BPP_FrameManager:BringToFront(frameName)
            end
        end)

        if frame:IsMovable() then
            local originalOnDragStart = frame:GetScript("OnDragStart")
            frame:SetScript("OnDragStart", function(self)
                self:StartMoving()
                if originalOnDragStart then
                    originalOnDragStart(self)
                end
                BPP_FrameManager:BringToFront(frameName)
            end)

            local originalOnDragStop = frame:GetScript("OnDragStop")
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                if originalOnDragStop then
                    originalOnDragStop(self)
                end
            end)
        end

        frame:EnableKeyboard(true)

        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                if self:IsVisible() and BPP_FrameManager:IsTopMostVisibleFrame(frameName) then
                    self:SetPropagateKeyboardInput(false)
                    BPP_FrameManager:HideFrame(frameName)
                else
                    self:SetPropagateKeyboardInput(true)
                end
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)

        frame:SetScript("OnShow", function(self)
            BPP_FrameManager:BringToFront(frameName)
        end)
    else
        -- For notification popups, just ensure they stay on top without keyboard interference
        frame:SetScript("OnShow", function(self)
            BPP_FrameManager:BringToFront(frameName)
        end)
    end

    self:BringToFront(frameName)

    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == frame:GetName() then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    return frame
end

function BPP_FrameManager:IsTopMostVisibleFrame(frameName)
    if #self.frameOrder == 0 then
        return false
    end

    local topFrameName = self.frameOrder[#self.frameOrder]
    return frameName == topFrameName
end

function BPP_FrameManager:BringToFront(frameName)
    local frame = self.frames[frameName]
    if not frame then
        return
    end

    frame:Show()

    frame:Raise()

    for i, name in ipairs(self.frameOrder) do
        if name == frameName then
            table.remove(self.frameOrder, i)
            break
        end
    end

    table.insert(self.frameOrder, frameName)

    while #self.frameOrder > self.maxFrames do
        table.remove(self.frameOrder, 1)
    end

    self:ReassignFrameLevels()

    self:UpdateKeyboardFocus()

    return frame
end

function BPP_FrameManager:UpdateKeyboardFocus()
    if #self.frameOrder == 0 then
        return
    end

    local topFrameName = self.frameOrder[#self.frameOrder]
    local topFrame = self.frames[topFrameName]

    if not topFrame then
        return
    end

    for name, frame in pairs(self.frames) do
        if frame:IsShown() and frame:IsKeyboardEnabled() then -- Only manage keyboard for frames that have it enabled
            frame:SetPropagateKeyboardInput(false)

            if name == topFrameName then
                frame:EnableKeyboard(true)
                C_Timer.After(0.05, function()
                    if frame:IsShown() and self:IsTopMostVisibleFrame(name) and frame:IsKeyboardEnabled() then
                        frame:SetPropagateKeyboardInput(false)
                    end
                end)
            end
        end
    end
end

function BPP_FrameManager:ReassignFrameLevels()
    local baseLevel = self.baseLevel
    local step = self.levelStep

    for i, frameName in ipairs(self.frameOrder) do
        local frame = self.frames[frameName]
        if frame and frame:IsShown() then
            frame:SetFrameLevel(baseLevel + (i * step))
        end
    end
end

function BPP_FrameManager:ShowFrame(frameName)
    local frame = self.frames[frameName]
    if frame then
        self:BringToFront(frameName)
        return frame
    end
    return nil
end

function BPP_FrameManager:HideFrame(frameName)
    local frame = self.frames[frameName]
    if frame then
        frame:Hide()

        for i, name in ipairs(self.frameOrder) do
            if name == frameName then
                table.remove(self.frameOrder, i)
                break
            end
        end

        self:ReassignFrameLevels()
        self:UpdateKeyboardFocus()
    end
end
