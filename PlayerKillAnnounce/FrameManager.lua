-- FrameManager.lua - Handles frame level management across the addon

-- Global frame stack management
PKA_FrameManager = PKA_FrameManager or {}
PKA_FrameManager.frames = PKA_FrameManager.frames or {}
PKA_FrameManager.frameOrder = PKA_FrameManager.frameOrder or {}
PKA_FrameManager.baseLevel = 100
PKA_FrameManager.levelStep = 10
PKA_FrameManager.maxFrames = 10  -- Maximum number of frames to track (more than we'll ever need)

-- Register a frame with the manager
function PKA_FrameManager:RegisterFrame(frame, frameName)
    if not frame or not frameName then return end

    -- Store the frame reference
    self.frames[frameName] = frame

    -- Set initial frame properties
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(self.baseLevel)

    -- Replace the frame's OnMouseDown handler
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            PKA_FrameManager:BringToFront(frameName)
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

    -- Add to frame order and bring to front
    self:BringToFront(frameName)

    return frame
end

-- Bring a specific frame to the front
function PKA_FrameManager:BringToFront(frameName)
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
function PKA_FrameManager:ReassignFrameLevels()
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
function PKA_FrameManager:ShowFrame(frameName)
    local frame = self.frames[frameName]
    if frame then
        self:BringToFront(frameName)
        return frame
    end
    return nil
end

-- Hide a frame and remove from ordering
function PKA_FrameManager:HideFrame(frameName)
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