-- ConfigUI.lua - Configuration interface for PlayerKillAnnounce
-- This adds a graphical user interface for all settings of the addon

local addonName = "PlayerKillAnnounce"
local configFrame = nil

-- Define default messages in case they're not available from EventHandlers.lua
local PlayerKillMessageDefault = PlayerKillMessageDefault or "Enemyplayername killed!"
local KillStreakEndedMessageDefault = KillStreakEndedMessageDefault or "My kill streak of STREAKCOUNT has ended!"
local NewStreakRecordMessageDefault = NewStreakRecordMessageDefault or "NEW PERSONAL BEST: Kill streak of STREAKCOUNT!"
local NewMultiKillRecordMessageDefault = NewMultiKillRecordMessageDefault or "NEW PERSONAL BEST: Multi-kill of MULTIKILLCOUNT!"

-- Colors matching the theme of the addon
local PKA_CONFIG_HEADER_R = 1.0
local PKA_CONFIG_HEADER_G = 0.82
local PKA_CONFIG_HEADER_B = 0.0

-- Helper function to create a section header
local function CreateSectionHeader(parent, text, xOffset, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    header:SetText(text)
    header:SetTextColor(PKA_CONFIG_HEADER_R, PKA_CONFIG_HEADER_G, PKA_CONFIG_HEADER_B)

    -- Add a horizontal line below the header
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetSize(parent:GetWidth() - (xOffset * 2), 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.7)

    return header, line
end

-- Helper function to create an input field with label
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
    editBox:SetText(initialValue or "")  -- Use empty string if initialValue is nil
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and onTextChangedFunc then
            onTextChangedFunc(self:GetText())
        end
    end)

    -- Add cancel on escape, accept on enter functionality
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(initialValue) -- Reset to initial value
        self:ClearFocus()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        if onTextChangedFunc then
            onTextChangedFunc(self:GetText())
        end
        self:ClearFocus()
    end)

    -- Add focus behavior
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

-- Helper function to create a checkbox with label
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

-- Helper function to create a slider with label
local function CreateSlider(parent, labelText, min, max, step, initialValue, valueFormat, onValueChangedFunc)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(260, 50)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", container, "TOP", 0, 0)
    label:SetText(labelText)

    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOP", label, "BOTTOM", 0, -5)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetValue(initialValue)
    slider:SetWidth(200)
    slider:SetObeyStepOnDrag(true)

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    valueText:SetText(valueFormat:format(initialValue))

    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(valueFormat:format(value))
        if onValueChangedFunc then
            onValueChangedFunc(value)
        end
    end)

    return container, slider, valueText
end

-- Helper function to create a button
local function CreateButton(parent, text, width, height, onClickFunc)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetScript("OnClick", onClickFunc)

    return button
end

-- Create the configuration frame
function PKA_CreateConfigFrame()
    -- If the frame already exists, just show it and update stats
    if configFrame then
        PKA_UpdateConfigStats() -- Update the stats when showing the frame
        configFrame:Show()
        return
    end

    -- Create the main frame
    configFrame = CreateFrame("Frame", "PKAConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(600, 650)  -- Reduced height since we removed the slider
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    -- Make closeable with Escape
    tinsert(UISpecialFrames, "PKAConfigFrame")

    -- Set title
    configFrame.TitleText:SetText("PlayerKillAnnounce Configuration")

    -- Ensure default values if any are missing
    if not PKA_KillAnnounceMessage then PKA_KillAnnounceMessage = PlayerKillMessageDefault end
    if not PKA_KillStreakEndedMessage then PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault end
    if not PKA_NewStreakRecordMessage then PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault end
    if not PKA_NewMultiKillRecordMessage then PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault end
    if PKA_EnableKillAnnounce == nil then PKA_EnableKillAnnounce = true end
    if PKA_EnableRecordAnnounce == nil then PKA_EnableRecordAnnounce = true end

    -- Define our spacing constants
    local SECTION_TOP_MARGIN = 30       -- Space from top of frame to first section
    local SECTION_SPACING = 100         -- Space between sections
    local HEADER_ELEMENT_SPACING = 10    -- Space between header and first element
    local CHECKBOX_SPACING = 0          -- Space between checkboxes
    local FIELD_SPACING = 10            -- Space between input fields
    local BUTTON_BOTTOM_MARGIN = 10     -- Space from bottom buttons to frame edge

    -- Track our current Y position for relative positioning
    local currentY = -SECTION_TOP_MARGIN

    -- SECTION 1: Announcement Settings
    local announcementHeader, announcementLine = CreateSectionHeader(configFrame, "Announcement Settings", 20, currentY)
    currentY = currentY - HEADER_ELEMENT_SPACING

    -- Enable kill announcements checkbox
    local enableKillAnnounce, enableKillAnnounceLabel = CreateCheckbox(configFrame, "Enable kill announcements", PKA_EnableKillAnnounce, function(checked)
        PKA_EnableKillAnnounce = checked
        PKA_SaveSettings()
    end)
    enableKillAnnounce:SetPoint("TOPLEFT", announcementHeader, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)

    -- Enable record announcements checkbox
    local enableRecordAnnounce, enableRecordAnnounceLabel = CreateCheckbox(configFrame, "Announce new records to party chat", PKA_EnableRecordAnnounce, function(checked)
        PKA_EnableRecordAnnounce = checked
        PKA_SaveSettings()
    end)
    enableRecordAnnounce:SetPoint("TOPLEFT", enableKillAnnounce, "BOTTOMLEFT", 0, -CHECKBOX_SPACING)

    -- Calculate position for next section (from top of frame)
    currentY = currentY - SECTION_SPACING

    -- SECTION 2: Message Templates
    local templatesHeader, templatesLine = CreateSectionHeader(configFrame, "Message Templates", 20, currentY)
    currentY = currentY - HEADER_ELEMENT_SPACING

    -- Kill announcement message
    local killMsgContainer, killMsgEditBox = CreateInputField(
        configFrame,
        "Kill announcement message (\"Enemyplayername\" will be replaced with the player's name):",
        560,
        PKA_KillAnnounceMessage,
        function(text)
            PKA_KillAnnounceMessage = text
            PKA_SaveSettings()
        end
    )
    killMsgContainer:SetPoint("TOPLEFT", templatesHeader, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)

    -- Streak ended message
    local streakEndedContainer, streakEndedEditBox = CreateInputField(
        configFrame,
        "Kill streak ended message (\"STREAKCOUNT\" will be replaced with the streak count):",
        560,
        PKA_KillStreakEndedMessage or KillStreakEndedMessageDefault,
        function(text)
            PKA_KillStreakEndedMessage = text
            PKA_SaveSettings()
        end
    )
    streakEndedContainer:SetPoint("TOPLEFT", killMsgContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    -- New streak record message
    local newStreakContainer, newStreakEditBox = CreateInputField(
        configFrame,
        "New streak record message (\"STREAKCOUNT\" will be replaced with the streak count):",
        560,
        PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault,
        function(text)
            PKA_NewStreakRecordMessage = text
            PKA_SaveSettings()
        end
    )
    newStreakContainer:SetPoint("TOPLEFT", streakEndedContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    -- New multi-kill record message
    local multiKillContainer, multiKillEditBox = CreateInputField(
        configFrame,
        "New multi-kill record message (\"MULTIKILLCOUNT\" will be replaced with the count):",
        560,
        PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault,
        function(text)
            PKA_NewMultiKillRecordMessage = text
            PKA_SaveSettings()
        end
    )
    multiKillContainer:SetPoint("TOPLEFT", newStreakContainer, "BOTTOMLEFT", 0, -FIELD_SPACING)

    -- Calculate position for next section (from top of frame) - Skipping the Multi-kill settings section
    currentY = currentY - SECTION_SPACING - 180  -- Extra space needed for the input fields

    -- SECTION 3: Statistics (previously SECTION 4)
    local statsHeader, statsLine = CreateSectionHeader(configFrame, "Statistics", 20, currentY)

    -- Current stats display
    configFrame.statsText = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    configFrame.statsText:SetPoint("TOPLEFT", statsHeader, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)

    -- Initialize with current values
    PKA_UpdateConfigStats()

    -- Add buttons to open statistics windows
    local showKillsBtn = CreateButton(configFrame, "Show Kills List", 150, 22, function()
        PKA_CreateKillStatsFrame()
    end)
    showKillsBtn:SetPoint("TOPLEFT", configFrame.statsText, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)

    local showStatsBtn = CreateButton(configFrame, "Show Statistics", 150, 22, function()
        PKA_CreateStatisticsFrame()
    end)
    showStatsBtn:SetPoint("LEFT", showKillsBtn, "RIGHT", 5, 0)

    -- Button row at bottom of frame
    local resetBtn = CreateButton(configFrame, "Reset Statistics", 150, 22, function()
        StaticPopupDialogs["PKA_RESET_STATS"] = {
            text = "Are you sure you want to reset all kill statistics? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                PKA_CurrentKillStreak = 0
                PKA_HighestKillStreak = 0
                PKA_MultiKillCount = 0
                PKA_HighestMultiKill = 0
                PKA_KillCounts = {}
                PKA_SaveSettings()
                PKA_UpdateConfigStats()  -- Update the statistics display
                print("All kill statistics have been reset!")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("PKA_RESET_STATS")
    end)
    resetBtn:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 20, BUTTON_BOTTOM_MARGIN)

    -- Default settings button
    local defaultsBtn = CreateButton(configFrame, "Reset to Defaults", 150, 22, function()
        StaticPopupDialogs["PKA_RESET_DEFAULTS"] = {
            text = "Are you sure you want to reset all settings to defaults? This will not affect your kill statistics.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                PKA_KillAnnounceMessage = PlayerKillMessageDefault
                PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault
                PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault
                PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault
                PKA_EnableKillAnnounce = true
                PKA_EnableRecordAnnounce = true

                -- Update UI elements
                killMsgEditBox:SetText(PKA_KillAnnounceMessage)
                streakEndedEditBox:SetText(PKA_KillStreakEndedMessage)
                newStreakEditBox:SetText(PKA_NewStreakRecordMessage)
                multiKillEditBox:SetText(PKA_NewMultiKillRecordMessage)
                enableKillAnnounce:SetChecked(PKA_EnableKillAnnounce)
                enableRecordAnnounce:SetChecked(PKA_EnableRecordAnnounce)

                PKA_SaveSettings()
                print("All settings have been reset to default values!")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("PKA_RESET_DEFAULTS")
    end)
    defaultsBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)

    -- Close button
    local closeBtn = CreateButton(configFrame, "Close", 80, 22, function()
        configFrame:Hide()
    end)
    closeBtn:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -20, BUTTON_BOTTOM_MARGIN)
end

-- Add a function to update the statistics text in the config UI
function PKA_UpdateConfigStats()
    if configFrame and configFrame.statsText then
        configFrame.statsText:SetText(string.format(
            "Current Kill Streak: %d\nHighest Kill Streak: %d\nHighest Multi-Kill: %d",
            PKA_CurrentKillStreak or 0,
            PKA_HighestKillStreak or 0,
            PKA_HighestMultiKill or 0
        ))
    end
end

-- Add command to slash handler to open config UI
local originalSlashHandler = PKA_SlashCommandHandler
function PKA_SlashCommandHandler(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "config" or command == "options" or command == "opt" or command == "setup" then
        PKA_CreateConfigFrame()
    else
        originalSlashHandler(msg)
    end
end

-- Update help text to include config UI option
local originalPrintUsage = PrintSlashCommandUsage
if originalPrintUsage then
    PrintSlashCommandUsage = function()
        originalPrintUsage()
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka config - Open configuration interface",
            PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    end
end