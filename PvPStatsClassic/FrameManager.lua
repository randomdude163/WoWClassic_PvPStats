-- FrameManager.lua - Handles frame level management across the addon

if not PSC_ActiveFrameLevel then
    PSC_ActiveFrameLevel = 100
end

PSC_FrameManager = {}
PSC_FrameManager.frames = {}
PSC_FrameManager.frameOrder = {}
PSC_FrameManager.baseLevel = 100
PSC_FrameManager.levelStep = 10
PSC_FrameManager.maxFrames = 10  -- Maximum number of frames to track (more than we'll ever need)

-- Improved RegisterFrame function to improve stacking and keyboard handling
function PSC_FrameManager:RegisterFrame(frame, frameName)
    if not frame or not frameName then return end

    -- Store the frame reference
    self.frames[frameName] = frame

    -- Set initial frame properties - using FULLSCREEN_DIALOG for highest priority
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(self.baseLevel)

    -- Replace the frame's OnMouseDown handler for better stacking control
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            PSC_FrameManager:BringToFront(frameName)
        end
    end)

    -- If the frame is draggable, manage that separately
    if frame:IsMovable() then
        local originalOnDragStart = frame:GetScript("OnDragStart")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
            if originalOnDragStart then
                originalOnDragStart(self)
            end
            -- Ensure this frame is on top when dragging
            PSC_FrameManager:BringToFront(frameName)
        end)

        local originalOnDragStop = frame:GetScript("OnDragStop")
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            if originalOnDragStop then
                originalOnDragStop(self)
            end
        end)
    end

    -- Enable keyboard input for all managed frames
    frame:EnableKeyboard(true)

    -- Ensure consistent capture of the Escape key
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            -- Only handle Escape if this is the topmost visible frame
            if self:IsVisible() and PSC_FrameManager:IsTopMostVisibleFrame(frameName) then
                -- Don't propagate the escape key
                self:SetPropagateKeyboardInput(false)
                PSC_FrameManager:HideFrame(frameName)
            else
                -- Let the escape key propagate to other handlers
                self:SetPropagateKeyboardInput(true)
            end
        else
            -- Let other keys propagate
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Make sure the frame captures focus when shown
    frame:SetScript("OnShow", function(self)
        -- Ensure this frame is brought to front when shown
        PSC_FrameManager:BringToFront(frameName)
    end)

    -- Add to frame order and bring to front
    self:BringToFront(frameName)

    -- Handle UISpecialFrames cleanup
    for i = #UISpecialFrames, 1, -1 do
        if UISpecialFrames[i] == frame:GetName() then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    return frame
end

-- Checks if the frame is the top-most visible frame
function PSC_FrameManager:IsTopMostVisibleFrame(frameName)
    if #self.frameOrder == 0 then return false end

    -- Check if this frame is the last (top-most) in our visible stack
    local topFrameName = self.frameOrder[#self.frameOrder]
    return frameName == topFrameName
end

-- Improved BringToFront function to ensure proper stacking
function PSC_FrameManager:BringToFront(frameName)
    local frame = self.frames[frameName]
    if not frame then return end

    -- Ensure the frame is shown
    frame:Show()

    -- This call is critical - it properly raises the frame in the UI hierarchy
    frame:Raise()

    -- Remove from current position in order array if present
    for i, name in ipairs(self.frameOrder) do
        if name == frameName then
            table.remove(self.frameOrder, i)
            break
        end
    end

    -- Add to top of order
    table.insert(self.frameOrder, frameName)

    -- Trim order to max size if needed
    while #self.frameOrder > self.maxFrames do
        table.remove(self.frameOrder, 1) -- Remove oldest frame
    end

    -- Reassign all frame levels based on order
    self:ReassignFrameLevels()

    -- Immediately update keyboard focus for the top frame
    self:UpdateKeyboardFocus()

    return frame
end

-- Add this new function to properly manage keyboard focus
function PSC_FrameManager:UpdateKeyboardFocus()
    -- Get the top-most frame
    if #self.frameOrder == 0 then return end

    local topFrameName = self.frameOrder[#self.frameOrder]
    local topFrame = self.frames[topFrameName]

    if not topFrame then return end

    -- Make sure all frames have keyboard focus disabled except the top one
    for name, frame in pairs(self.frames) do
        if frame:IsShown() then
            -- For all visible frames, ensure Escape propagation is off initially
            frame:SetPropagateKeyboardInput(false)

            -- Only the top frame should actively capture escape
            if name == topFrameName then
                frame:EnableKeyboard(true)
                -- Top frame gets keyboard focus
                C_Timer.After(0.05, function()
                    if frame:IsShown() and self:IsTopMostVisibleFrame(name) then
                        frame:SetPropagateKeyboardInput(false)
                    end
                end)
            end
        end
    end
end

-- Improved ReassignFrameLevels to ensure proper visual stacking
function PSC_FrameManager:ReassignFrameLevels()
    local baseLevel = self.baseLevel
    local step = self.levelStep

    -- Assign levels to all frames in order (oldest to newest)
    for i, frameName in ipairs(self.frameOrder) do
        local frame = self.frames[frameName]
        if frame and frame:IsShown() then
            -- Set increasing frame levels with bigger gaps
            frame:SetFrameLevel(baseLevel + (i * step))
        end
    end
end

-- Show a frame and bring it to front
function PSC_FrameManager:ShowFrame(frameName)
    local frame = self.frames[frameName]
    if frame then
        self:BringToFront(frameName)
        return frame
    end
    return nil
end

-- Improved HideFrame function to update keyboard focus
function PSC_FrameManager:HideFrame(frameName)
    local frame = self.frames[frameName]
    if frame then
        frame:Hide()

        -- Remove from order
        for i, name in ipairs(self.frameOrder) do
            if name == frameName then
                table.remove(self.frameOrder, i)
                break
            end
        end

        self:ReassignFrameLevels()
        -- Update keyboard focus after hiding a frame
        self:UpdateKeyboardFocus()
    end
end
