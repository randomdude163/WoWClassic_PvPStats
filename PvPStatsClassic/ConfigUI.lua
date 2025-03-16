-- ConfigUI.lua - Configuration interface for PvPStatsClassic
-- This adds a graphical user interface for all settings of the addon
local configFrame = nil

-- Add this near other default settings
PKA_ShowTooltipKillInfo = true -- New default setting

-- Default messages as fallbacks
local PlayerKillMessageDefault = PlayerKillMessageDefault or "Enemyplayername killed!"
local KillStreakEndedMessageDefault = KillStreakEndedMessageDefault or "My kill streak of STREAKCOUNT has ended!"
local NewStreakRecordMessageDefault = NewStreakRecordMessageDefault or "NEW PERSONAL BEST: Kill streak of STREAKCOUNT!"
local NewMultiKillRecordMessageDefault = NewMultiKillRecordMessageDefault or
    "NEW PERSONAL BEST: Multi-kill of MULTIKILLCOUNT!"

local PKA_CONFIG_HEADER_R = 1.0
local PKA_CONFIG_HEADER_G = 0.82
local PKA_CONFIG_HEADER_B = 0.0

local SECTION_TOP_MARGIN = 30
local SECTION_SPACING = 40
local HEADER_ELEMENT_SPACING = 15
local CHECKBOX_SPACING = 5
local FIELD_SPACING = 5
local BUTTON_BOTTOM_MARGIN = 20

PKA_EnableKillSounds = true


local function ResetAllStatsToDefault()
    PKA_CurrentKillStreak = 0
    PKA_HighestKillStreak = 0
    PKA_MultiKillCount = 0
    PKA_HighestMultiKill = 0
    PKA_KillCounts = {}
    PKA_SaveSettings()
    print("All kill statistics have been reset!")
end

local function ShowResetStatsConfirmation()
    StaticPopupDialogs["PKA_RESET_STATS"] = {
        text = "Are you sure you want to reset all kill statistics? This cannot be undone.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            ResetAllStatsToDefault()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("PKA_RESET_STATS")
end

local function ResetAllSettingsToDefault()
    PKA_KillAnnounceMessage = PlayerKillMessageDefault
    PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault
    PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault
    PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault
    PKA_EnableKillAnnounce = true
    PKA_EnableRecordAnnounce = true
    PKA_MultiKillThreshold = 3
    PKA_ShowTooltipKillInfo = true

    -- Reset Kill Milestone settings
    PKA_KillMilestoneNotificationsEnabled = true
    PKA_MilestoneAutoHideTime = 5
    PKA_MilestoneInterval = 5

    -- Update UI with reset values
    if configFrame then
        PKA_UpdateConfigUI()
    end

    PKA_SaveSettings()
    print("All settings have been reset to default values!")
end

local function ShowResetDefaultsConfirmation()
    StaticPopupDialogs["PKA_RESET_DEFAULTS"] = {
        text = "Are you sure you want to reset all settings to defaults? This will not affect your kill statistics.",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            ResetAllSettingsToDefault()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("PKA_RESET_DEFAULTS")
end

local function CreateSectionHeader(parent, text, xOffset, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    header:SetText(text)
    header:SetTextColor(PKA_CONFIG_HEADER_R, PKA_CONFIG_HEADER_G, PKA_CONFIG_HEADER_B)


    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetSize(parent:GetWidth() - (xOffset * 2), 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.7)

    return header, line
end

local function CreateInputField(parent, labelText, width, initialValue, onTextChangedFunc)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, 50)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editBox:SetSize(width - 20, 20)
    editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 5, -5)
    editBox:SetAutoFocus(false)
    editBox:SetText(initialValue or "")

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and onTextChangedFunc then
            onTextChangedFunc(self:GetText())
        end
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(initialValue)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        if onTextChangedFunc then
            onTextChangedFunc(self:GetText())
        end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    editBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        if onTextChangedFunc then
            onTextChangedFunc(self:GetText())
        end
    end)

    return container, editBox
end

local function CreateCheckbox(parent, labelText, initialValue, onClickFunc)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    checkbox:SetChecked(initialValue)
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        onClickFunc(checked)
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    end)

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(labelText)

    return checkbox, label
end

local function CreateButton(parent, text, width, height, onClickFunc)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript("OnClick", onClickFunc)

    return button
end

local function EnsureDefaultValues()
    if not PKA_KillAnnounceMessage then PKA_KillAnnounceMessage = PlayerKillMessageDefault end
    if not PKA_KillStreakEndedMessage then PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault end
    if not PKA_NewStreakRecordMessage then PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault end
    if not PKA_NewMultiKillRecordMessage then PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault end
    if PKA_EnableKillAnnounce == nil then PKA_EnableKillAnnounce = true end
    if PKA_EnableRecordAnnounce == nil then PKA_EnableRecordAnnounce = true end
    if PKA_MultiKillThreshold == nil then PKA_MultiKillThreshold = 3 end
    if PKA_ShowTooltipKillInfo == nil then PKA_ShowTooltipKillInfo = true end
end

-- Update the config UI to use the new name and add the milestone interval slider
local function CreateAnnouncementSection(parent, yOffset)
    local header, line = CreateSectionHeader(parent, "Announcement Settings", 20, yOffset)
    local currentY = yOffset

    -- Auto BG Mode checkbox with tooltip
    local autoBGMode, autoBGModeLabel = CreateCheckbox(parent, "Auto Battleground Mode (No announcements, only your own killing blows are tracked)",
        PKA_AutoBattlegroundMode, function(checked)
            PKA_AutoBattlegroundMode = checked
            PKA_SaveSettings()
            PKA_CheckBattlegroundStatus()
        end)
    autoBGMode:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)
    parent.autoBGMode = autoBGMode

    -- Add tooltip for Auto BG Mode
    autoBGMode:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto Battleground Mode")
        GameTooltip:AddLine("Automatically detects when you enter battlegrounds.", 1, 1, 1, true)
        GameTooltip:AddLine("In battlegrounds:", 1, 1, 1, true)
        GameTooltip:AddLine("• Only your or your pet's killing blows count", 1, 1, 1, true)
        GameTooltip:AddLine("• No messages are posted to group chat", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoBGMode:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local manualBGMode, manualBGModeLabel = CreateCheckbox(parent, "Force Enable Battleground Mode",
        PKA_BattlegroundMode, function(checked)
            PKA_BattlegroundMode = checked
            PKA_SaveSettings()
            PKA_CheckBattlegroundStatus()
        end)
    manualBGMode:SetPoint("TOPLEFT", autoBGMode, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.manualBGMode = manualBGMode

    -- Add tooltip for manual BG Mode
    manualBGMode:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Force Battleground Mode")
        GameTooltip:AddLine("Enable battleground conditions anywhere in the world.", 1, 1, 1, true)
        GameTooltip:AddLine("When enabled:", 1, 1, 1, true)
        GameTooltip:AddLine("• Only your or your pet's killing blows are counted", 1, 1, 1, true)
        GameTooltip:AddLine("• Prevents chat spam in crowded PvP situations", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    manualBGMode:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Add tooltip checkbox right after battleground mode
    local tooltipKillInfo, tooltipKillInfoLabel = CreateCheckbox(parent,
        "Show kill statistics in enemy player tooltips",
        PKA_ShowTooltipKillInfo,
        function(checked)
            PKA_ShowTooltipKillInfo = checked
            PKA_SaveSettings()
        end)
    tooltipKillInfo:SetPoint("TOPLEFT", manualBGMode, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.tooltipKillInfo = tooltipKillInfo

    -- Add tooltip explanation
    tooltipKillInfo:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Enemy Player Tooltips")
        GameTooltip:AddLine("Shows how often you killed players while you mouseover them.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tooltipKillInfo:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Add Kill Milestone checkbox (renamed from Last Kill Preview)
    local killMilestone, killMilestoneLabel = CreateCheckbox(parent,
        "Show Kill Milestones",
        PKA_KillMilestoneNotificationsEnabled,
        function(checked)
            PKA_KillMilestoneNotificationsEnabled = checked
            PKA_SaveSettings()
        end)
    killMilestone:SetPoint("TOPLEFT", tooltipKillInfo, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.killMilestone = killMilestone

    -- Add tooltip explanation for Kill Milestone
    killMilestone:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Kill Milestone")
        GameTooltip:AddLine("Shows movable notification for kill milestones.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    killMilestone:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Add Milestone Interval slider (new)
    local intervalSlider = CreateFrame("Slider", "PKA_MilestoneIntervalSlider", parent, "OptionsSliderTemplate")
    intervalSlider:SetWidth(200)
    intervalSlider:SetHeight(16)
    intervalSlider:SetPoint("TOPLEFT", killMilestone, "BOTTOMLEFT", 40, -20)
    intervalSlider:SetOrientation("HORIZONTAL")
    intervalSlider:SetMinMaxValues(3, 10)
    intervalSlider:SetValueStep(1)
    intervalSlider:SetValue(PKA_MilestoneInterval or 5)
    getglobal(intervalSlider:GetName() .. "Low"):SetText("3")
    getglobal(intervalSlider:GetName() .. "High"):SetText("10")
    getglobal(intervalSlider:GetName() .. "Text"):SetText("Milestone Interval: Every " .. (PKA_MilestoneInterval or 5) .. " kills")
    parent.intervalSlider = intervalSlider

    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Milestone Interval: Every " .. value .. " kills")
        PKA_MilestoneInterval = value
        PKA_SaveSettings()
    end)

    -- Add Kill Milestone auto-hide time slider (renamed from Last Kill Preview)
    local milestoneSlider = CreateFrame("Slider", "PKA_MilestoneTimeSlider", parent, "OptionsSliderTemplate")
    milestoneSlider:SetWidth(200)
    milestoneSlider:SetHeight(16)
    milestoneSlider:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -20)
    milestoneSlider:SetOrientation("HORIZONTAL")
    milestoneSlider:SetMinMaxValues(1, 15)
    milestoneSlider:SetValueStep(1)
    milestoneSlider:SetValue(PKA_MilestoneAutoHideTime or 5)
    getglobal(milestoneSlider:GetName() .. "Low"):SetText("1 sec")
    getglobal(milestoneSlider:GetName() .. "High"):SetText("15 sec")
    getglobal(milestoneSlider:GetName() .. "Text"):SetText("Hide notification after: " .. (PKA_MilestoneAutoHideTime or 5) .. " seconds")
    parent.milestoneSlider = milestoneSlider

    milestoneSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Hide notification after: " .. value .. " seconds")
        PKA_MilestoneAutoHideTime = value
        PKA_SaveSettings()
    end)

    -- Add a test button
    local testButton = CreateButton(parent, "Show Kill Milestone", 160, 22, function()
        -- Test with sample data for milestone kill counts
        local testKillCounts = {1, PKA_MilestoneInterval, PKA_MilestoneInterval * 2}
        local index = math.random(1, 3)

        -- Create a sample kill event with random class
        local classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
        local randomClass = classes[math.random(1, #classes)]

        -- 50% chance to show Horde ranks instead of Alliance
        local useHorde = (math.random(1, 2) == 1)
        local faction = useHorde and "Horde" or "Alliance"

        -- 30% chance of no rank
        local rank
        if math.random(1, 10) <= 3 then
            rank = 0
        else
            -- Otherwise random rank 1-14 (higher ranks less common)
            local rankRoll = math.random(1, 100)
            if rankRoll <= 50 then
                rank = math.random(1, 4) -- 50% chance for ranks 1-4
            elseif rankRoll <= 75 then
                rank = math.random(5, 8) -- 25% chance for ranks 5-8
            elseif rankRoll <= 90 then
                rank = math.random(9, 11) -- 15% chance for ranks 9-11
            else
                rank = math.random(12, 14) -- 10% chance for ranks 12-14
            end
        end

        local prefix = useHorde and "Horde" or "Alliance"
        PKA_ShowKillMilestone(prefix .. "TestPlayer", 60, randomClass, "Human", 1, "Test Guild", rank, testKillCounts[index], faction)
    end)
    testButton:SetPoint("TOPLEFT", milestoneSlider, "BOTTOMLEFT", -20, -10)
    parent.milestoneTestButton = testButton

    -- Now continue with the original checkboxes
    local enableKillAnnounce, enableKillAnnounceLabel = CreateCheckbox(parent, "Enable kill announcements to party chat",
        PKA_EnableKillAnnounce, function(checked)
            PKA_EnableKillAnnounce = checked
            PKA_SaveSettings()
        end)
    enableKillAnnounce:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", -20, -10)
    parent.enableKillAnnounce = enableKillAnnounce

    local enableRecordAnnounce, enableRecordAnnounceLabel = CreateCheckbox(parent, "Announce new personal bests to party chat",
        PKA_EnableRecordAnnounce, function(checked)
            PKA_EnableRecordAnnounce = checked
            PKA_SaveSettings()
        end)
    enableRecordAnnounce:SetPoint("TOPLEFT", enableKillAnnounce, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.enableRecordAnnounce = enableRecordAnnounce

    local enableKillSounds, enableKillSoundsLabel = CreateCheckbox(parent, "Enable multi-kill sound effects",
        PKA_EnableKillSounds, function(checked)
            PKA_EnableKillSounds = checked
            PKA_SaveSettings()
        end)
    enableKillSounds:SetPoint("TOPLEFT", enableRecordAnnounce, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.enableKillSounds = enableKillSounds

    -- Return a slightly increased height to accommodate the new elements
    return 320
end

local function CreateMessageTemplatesSection(parent, yOffset)
    -- Add extra spacing before the Party Messages section
    yOffset = yOffset - 35

    local header, line = CreateSectionHeader(parent, "Party Messages", 20, yOffset)

    local killMsgContainer, killMsgEditBox = CreateInputField(
        parent,
        "Kill announcement message (\"Enemyplayername\" will be replaced with the player's name):",
        560,
        PKA_KillAnnounceMessage,
        function(text)
            PKA_KillAnnounceMessage = text
            PKA_SaveSettings()
        end
    )
    killMsgContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)

    local streakEndedContainer, streakEndedEditBox = CreateInputField(
        parent,
        "Kill streak ended message (\"STREAKCOUNT\" will be replaced with the streak count):",
        560,
        PKA_KillStreakEndedMessage,
        function(text)
            PKA_KillStreakEndedMessage = text
            PKA_SaveSettings()
        end
    )
    streakEndedContainer:SetPoint("TOPLEFT", killMsgContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    local newStreakContainer, newStreakEditBox = CreateInputField(
        parent,
        "New streak record message (\"STREAKCOUNT\" will be replaced with the streak count):",
        560,
        PKA_NewStreakRecordMessage,
        function(text)
            PKA_NewStreakRecordMessage = text
            PKA_SaveSettings()
        end
    )
    newStreakContainer:SetPoint("TOPLEFT", streakEndedContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    local multiKillContainer, multiKillEditBox = CreateInputField(
        parent,
        "New multi-kill record message (\"MULTIKILLCOUNT\" will be replaced with the count):",
        560,
        PKA_NewMultiKillRecordMessage,
        function(text)
            PKA_NewMultiKillRecordMessage = text
            PKA_SaveSettings()
        end
    )
    multiKillContainer:SetPoint("TOPLEFT", newStreakContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    -- Add section header for Multi-Kill settings
    local multiKillHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    multiKillHeader:SetPoint("TOPLEFT", multiKillContainer, "BOTTOMLEFT", 0, -20)
    multiKillHeader:SetText("Multi-Kill Announce")

    -- Add the threshold slider and description
    local slider = CreateFrame("Slider", "PKA_MultiKillThresholdSlider", parent, "OptionsSliderTemplate")
    slider:SetWidth(200)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", multiKillHeader, "BOTTOMLEFT", 40, -20)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(2, 10)
    slider:SetValueStep(1)
    slider:SetValue(PKA_MultiKillThreshold or 3)
    getglobal(slider:GetName() .. "Low"):SetText("Double")
    getglobal(slider:GetName() .. "High"):SetText("Deca")
    getglobal(slider:GetName() .. "Text"):SetText("Multi-Kill Announce Threshold: " .. (PKA_MultiKillThreshold or 3))
    parent.multiKillSlider = slider

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Multi-Kill Announce Threshold: " .. value)
        PKA_MultiKillThreshold = value
        PKA_SaveSettings()
    end)

    -- Slider description
    local desc = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -5)
    desc:SetText("Set the minimum multi-kill count to announce in party chat")
    desc:SetJustifyH("LEFT")
    desc:SetWidth(350)

    -- Return UI elements for potential updates
    return {
        killMsg = killMsgEditBox,
        streakEnded = streakEndedEditBox,
        newStreak = newStreakEditBox,
        multiKill = multiKillEditBox,
        multiKillSlider = slider,
        multiKillDesc = desc
    }
end

local function CreateActionButtons(parent)
    -- Create a centered container for buttons
    local buttonContainer = CreateFrame("Frame", nil, parent)
    buttonContainer:SetSize(200, 200)  -- Fixed width container
    buttonContainer:SetPoint("CENTER")

    -- Consistent button sizes and spacing
    local buttonWidth = 160  -- Fixed width for all buttons
    local buttonHeight = 25  -- Fixed height for all buttons
    local buttonSpacing = 15 -- Space between buttons

    -- Create buttons with consistent sizing
    local showStatsBtn = CreateButton(buttonContainer, "Show Statistics", buttonWidth, buttonHeight, function()
        PKA_CreateStatisticsFrame()
    end)

    local killsListBtn = CreateButton(buttonContainer, "Show Kills List", buttonWidth, buttonHeight, function()
        PKA_CreateKillStatsFrame()
    end)

    local resetStatsBtn = CreateButton(buttonContainer, "Reset Statistics", buttonWidth, buttonHeight, function()
        ShowResetStatsConfirmation()
    end)

    local defaultsBtn = CreateButton(buttonContainer, "Reset to Defaults", buttonWidth, buttonHeight, function()
        ShowResetDefaultsConfirmation()
    end)

    -- Stack buttons vertically with even spacing
    showStatsBtn:SetPoint("TOP", buttonContainer, "TOP", 0, 0)
    killsListBtn:SetPoint("TOP", showStatsBtn, "BOTTOM", 0, -buttonSpacing)
    resetStatsBtn:SetPoint("TOP", killsListBtn, "BOTTOM", 0, -buttonSpacing)
    defaultsBtn:SetPoint("TOP", resetStatsBtn, "BOTTOM", 0, -buttonSpacing)

    return {
        showStatsBtn = showStatsBtn,
        killsListBtn = killsListBtn,
        resetBtn = resetStatsBtn,
        defaultsBtn = defaultsBtn
    }
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PKAConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 600) -- Reduced from 650 to 600
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Add a close button handler
    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    tinsert(UISpecialFrames, "PKAConfigFrame")

    frame.TitleText:SetText("PvP Stats Classic Configuration")

    return frame
end

function PKA_UpdateConfigUI()
    if not configFrame then return end

    if configFrame.enableKillAnnounce then
        configFrame.enableKillAnnounce:SetChecked(PKA_EnableKillAnnounce)
    end

    if configFrame.enableRecordAnnounce then
        configFrame.enableRecordAnnounce:SetChecked(PKA_EnableRecordAnnounce)
    end

    if configFrame.multiKillSlider then
        configFrame.multiKillSlider:SetValue(PKA_MultiKillThreshold)
        -- Also update the slider text
        local sliderName = configFrame.multiKillSlider:GetName()
        if sliderName then
            getglobal(sliderName .. "Text"):SetText("Multi-Kill Announce Threshold: " .. PKA_MultiKillThreshold)
        end
    end

    if configFrame.editBoxes then
        configFrame.editBoxes.killMsg:SetText(PKA_KillAnnounceMessage)
        configFrame.editBoxes.streakEnded:SetText(PKA_KillStreakEndedMessage)
        configFrame.editBoxes.newStreak:SetText(PKA_NewStreakRecordMessage)
        configFrame.editBoxes.multiKill:SetText(PKA_NewMultiKillRecordMessage)
    end

    if configFrame.tooltipKillInfo then
        configFrame.tooltipKillInfo:SetChecked(PKA_ShowTooltipKillInfo)
    end

    if configFrame.killMilestone then
        configFrame.killMilestone:SetChecked(PKA_KillMilestoneNotificationsEnabled)
    end

    if configFrame.milestoneSlider then
        configFrame.milestoneSlider:SetValue(PKA_MilestoneAutoHideTime)
        local sliderName = configFrame.milestoneSlider:GetName()
        if sliderName then
            getglobal(sliderName .. "Text"):SetText("Auto-Hide Time: " .. PKA_MilestoneAutoHideTime .. " seconds")
        end
    end

    if configFrame.intervalSlider then
        configFrame.intervalSlider:SetValue(PKA_MilestoneInterval)
        local sliderName = configFrame.intervalSlider:GetName()
        if sliderName then
            getglobal(sliderName .. "Text"):SetText("Milestone Interval: Every " .. PKA_MilestoneInterval .. " kills")
        end
    end
end

local function CreateTabSystem(parent)
    local tabWidth = 85
    local tabHeight = 32
    local tabs = {}
    local tabFrames = {}

    local tabContainer = CreateFrame("Frame", nil, parent)
    tabContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -25)
    tabContainer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -7, 7)

    -- Create tab buttons
    local tabNames = {"General", "Messages", "Reset", "About"}
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", parent:GetName().."Tab"..i, parent, "CharacterFrameTabButtonTemplate")
        tab:SetText(name)
        tab:SetID(i)

        -- Set initial size
        tab:SetSize(tabWidth, tabHeight)

        -- Get references to all tab textures
        local tabMiddle = _G[tab:GetName().."Middle"]
        local tabLeft = _G[tab:GetName().."Left"]
        local tabRight = _G[tab:GetName().."Right"]
        local tabSelectedMiddle = _G[tab:GetName().."SelectedMiddle"]
        local tabSelectedLeft = _G[tab:GetName().."SelectedLeft"]
        local tabSelectedRight = _G[tab:GetName().."SelectedRight"]
        local tabText = _G[tab:GetName().."Text"]

        -- Fix texture sizes immediately
        if tabMiddle then
            tabMiddle:ClearAllPoints()
            tabMiddle:SetPoint("LEFT", tabLeft, "RIGHT", 0, 0)
            tabMiddle:SetWidth(tabWidth - 31)
        end
        if tabSelectedMiddle then
            tabSelectedMiddle:ClearAllPoints()
            tabSelectedMiddle:SetPoint("LEFT", tabSelectedLeft, "RIGHT", 0, 0)
            tabSelectedMiddle:SetWidth(tabWidth - 31)
        end

        -- Position tabs with proper spacing
        if i == 1 then
            tab:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, 0)
        else
            tab:SetPoint("LEFT", tabs[i-1], "RIGHT", -8, 0)
        end

        -- Force proper text positioning
        if tabText then
            tabText:ClearAllPoints()
            tabText:SetPoint("CENTER", tab, "CENTER", 0, 2)
            tabText:SetJustifyH("CENTER")
            tabText:SetWidth(tabWidth - 40)
        end

        -- Create content frame for this tab
        local contentFrame = CreateFrame("Frame", nil, tabContainer)
        contentFrame:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 0, -5)
        contentFrame:SetPoint("BOTTOMRIGHT", tabContainer, "BOTTOMRIGHT")
        contentFrame:Hide()

        tabFrames[i] = contentFrame
        table.insert(tabs, tab)

        -- Set up click handler
        tab:SetScript("OnClick", function()
            PanelTemplates_SetTab(parent, i)
            for index, frame in ipairs(tabFrames) do
                if index == i then
                    frame:Show()
                    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
                else
                    frame:Hide()
                end
            end
        end)
    end

    parent.tabs = tabs
    parent.numTabs = #tabs
    PanelTemplates_SetNumTabs(parent, #tabs)
    PanelTemplates_SetTab(parent, 1)
    tabFrames[1]:Show()

    -- Force resize and texture setup
    for i, tab in ipairs(tabs) do
        PanelTemplates_TabResize(tab, 0)
    end

    return tabFrames
end

-- Create About Tab with Credits
local function CreateAboutTab(parent)
    -- Create a header
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", parent, "TOP", 0, -20)
    header:SetText("PvP Stats Classic")
    header:SetTextColor(PKA_CONFIG_HEADER_R, PKA_CONFIG_HEADER_G, PKA_CONFIG_HEADER_B)

    -- Create version text
    local versionText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOP", header, "BOTTOM", 0, -5)
    versionText:SetText("Version: 0.9.0")
    versionText:SetTextColor(1, 1, 1)

    -- Create credits section
    local creditsHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    creditsHeader:SetPoint("TOP", header, "BOTTOM", 0, -40)
    creditsHeader:SetText("Credits")
    creditsHeader:SetTextColor(PKA_CONFIG_HEADER_R, PKA_CONFIG_HEADER_G, PKA_CONFIG_HEADER_B)

    -- Create logo/icon - increased size by 25%
    local logo = parent:CreateTexture(nil, "ARTWORK")
    logo:SetSize(220, 220)
    logo:SetPoint("TOP", creditsHeader, "BOTTOM", 0, -10)
    logo:SetTexture("Interface\\AddOns\\PvPStatsClassic\\img\\RedridgePoliceLogo.blp")

    -- Get hunter class color for developers' names
    local hunterColor = RAID_CLASS_COLORS["HUNTER"] or {r = 0.67, g = 0.83, b = 0.45}

    -- Create a better formatted credits section with left alignment
    local contentWidth = 300
    local creditsContainer = CreateFrame("Frame", nil, parent)
    creditsContainer:SetSize(contentWidth, 200)
    creditsContainer:SetPoint("TOP", logo, "BOTTOM", 0, -10)

    -- Use a consistent left margin for all text
    local leftMargin = (parent:GetWidth() - contentWidth) / 2

    -- Developers - all left aligned
    local devsLabel = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    devsLabel:SetPoint("TOPLEFT", creditsContainer, "TOPLEFT", 0, 0)
    devsLabel:SetText("Developed by:")

    local firstAuthorText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    firstAuthorText:SetPoint("TOPLEFT", devsLabel, "TOPRIGHT", 5, 0)
    firstAuthorText:SetText("Severussnipe")
    firstAuthorText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    local andText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    andText:SetPoint("TOPLEFT", firstAuthorText, "TOPRIGHT", 5, 0)
    andText:SetText("&")

    local secondAuthorText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secondAuthorText:SetPoint("TOPLEFT", andText, "TOPRIGHT", 5, 0)
    secondAuthorText:SetText("Hkfarmer")
    secondAuthorText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    -- Realm - left aligned
    local realmText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    realmText:SetPoint("TOPLEFT", devsLabel, "BOTTOMLEFT", 0, -15)
    realmText:SetText("Realm: Spineshatter")

    -- Guild - left aligned
    local guildText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildText:SetPoint("TOPLEFT", realmText, "BOTTOMLEFT", 0, -10)
    guildText:SetText("Guild: <Redridge Police>")

    -- Email - left aligned (NEW)
    local emailText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emailText:SetPoint("TOPLEFT", guildText, "BOTTOMLEFT", 0, -20)
    emailText:SetText("Contact: redridgepolice@outlook.com")

    -- GitHub link - left aligned
    local githubText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    githubText:SetPoint("TOPLEFT", emailText, "BOTTOMLEFT", 0, -10)
    githubText:SetText("GitHub: github.com/randomdude163/WoWClassic_PlayerKillAnnounce")
    githubText:SetTextColor(0.3, 0.6, 1.0)

    return parent
end

function PKA_CreateConfigFrame()
    if configFrame then
        configFrame:Show()
        return
    end

    EnsureDefaultValues()
    configFrame = CreateMainFrame()
    PKA_FrameManager:RegisterFrame(configFrame, "ConfigUI")

    -- Create tab system
    local tabFrames = CreateTabSystem(configFrame)

    -- General Tab (Tab 1)
    local currentY = -10
    local announcementHeight = CreateAnnouncementSection(tabFrames[1], currentY)

    -- Messages Tab (Tab 2)
    configFrame.editBoxes = CreateMessageTemplatesSection(tabFrames[2], -10)

    -- Reset Tab (Tab 3) - Add this section
    local resetButtons = CreateActionButtons(tabFrames[3])
    configFrame.resetButtons = resetButtons

    -- About Tab (Tab 4) - Add new tab
    CreateAboutTab(tabFrames[4])

    -- Initialize first tab
    PanelTemplates_SetTab(configFrame, 1)
    tabFrames[1]:Show()

    return configFrame
end

function PKA_CreateConfigUI()
    if configFrame then
        PKA_FrameManager:ShowFrame("Config")
        return
    end

    PKA_CreateConfigFrame()
end
