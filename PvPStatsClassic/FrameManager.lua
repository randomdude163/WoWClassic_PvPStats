-- FrameManager.lua - Handles frame level management across the addon

-- Global frame stack management
PSC_FrameManager = {}
PSC_FrameManager.frames = {}
PSC_FrameManager.frameOrder = {}
PSC_FrameManager.baseLevel = 100
PSC_FrameManager.levelStep = 10
PSC_FrameManager.maxFrames = 10  -- Maximum number of frames to track (more than we'll ever need)

-- Register a frame with the manager
function PSC_FrameManager:RegisterFrame(frame, frameName)
    if not frame or not frameName then return end

    -- Store the frame reference
    self.frames[frameName] = frame

    -- Set initial frame properties
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(self.baseLevel)

    -- Replace the frame's OnMouseDown handler
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            PSC_FrameManager:BringToFront(frameName)
        end
    end)

    -- If the frame is draggable, manage that separately
    if frame:IsMovable() then
        -- Keep original OnDragStart if it exists
        local originalOnDragStart = frame:GetScript("OnDragStart")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
            if originalOnDragStart then
                originalOnDragStart(self)
            end
        end)

        -- Keep original OnDragStop if it exists
        local originalOnDragStop = frame:GetScript("OnDragStop")
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            if originalOnDragStop then
                originalOnDragStop(self)
            end
        end)
    end

    -- Enable keyboard handling for Escape key
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)

    -- Set up Escape key handling
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            -- Don't propagate ESC key if this is the top-most frame
            if PSC_FrameManager:IsTopMostVisibleFrame(frameName) then
                self:SetPropagateKeyboardInput(false)
                PSC_FrameManager:HideFrame(frameName)
                return
            end
        end
        -- Propagate all other keys and ESC if not top-most
        self:SetPropagateKeyboardInput(true)
    end)

    -- Add to frame order and bring to front
    self:BringToFront(frameName)

    -- Remove from UISpecialFrames to prevent default ESC handling
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

-- Bring a specific frame to the front
function PSC_FrameManager:BringToFront(frameName)
    local frame = self.frames[frameName]
    if not frame then return end

    -- Ensure the frame is shown
    frame:Show()
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

    return frame
end

-- Reassign frame levels based on current order
function PSC_FrameManager:ReassignFrameLevels()
    local level = self.baseLevel

    -- Assign levels to all frames in order (oldest to newest)
    for _, frameName in ipairs(self.frameOrder) do
        local frame = self.frames[frameName]
        if frame and frame:IsShown() then
            frame:SetFrameLevel(level)
            level = level + self.levelStep
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

-- Hide a frame and remove from ordering
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
    end
end