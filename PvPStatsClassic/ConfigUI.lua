local addonName, PVPSC = ...

local configFrame = nil

local PSC_CONFIG_HEADER_R = 1.0
local PSC_CONFIG_HEADER_G = 0.82
local PSC_CONFIG_HEADER_B = 0.0

local HEADER_ELEMENT_SPACING = 15
local CHECKBOX_SPACING = 5
local MESSAGE_TEXTFIELD_SPACING = 40

local function CreateAndShowStaticPopup(dialogName, text, onAcceptFunc)
    StaticPopupDialogs[dialogName] = {
        text = text,
        button1 = "Yes",
        button2 = "No",
        OnAccept = onAcceptFunc,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,

        OnShow = function(self)
            if configFrame then
                configFrame:EnableKeyboard(false)
            end
        end,

        OnHide = function()
            if configFrame and configFrame:IsVisible() then
                configFrame:EnableKeyboard(true)

                C_Timer.After(0.05, function()
                    if configFrame:IsVisible() then
                        PSC_FrameManager:BringToFront("ConfigUI")
                    end
                end)
            end
        end
    }

    local popup = StaticPopup_Show(dialogName)

    if popup then
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetFrameLevel(2000)
        popup:SetPoint("CENTER", UIParent, "CENTER")
        popup:Raise()

        popup:SetPropagateKeyboardInput(false)
        popup:EnableKeyboard(true)

        popup:SetScript("OnKeyDown", nil)
    end

    return popup
end

local function ShowResetStatsConfirmation()
    CreateAndShowStaticPopup("PSC_RESET_STATS",
        "Are you sure you want to reset all kill/death statistics? This cannot be undone.", function()
            ResetAllStatsToDefault()
        end)
end

local function ResetAllSettingsToDefault()
    PSC_LoadDefaultSettings()
    ReloadUI()
end

local function ShowResetDefaultsConfirmation()
    CreateAndShowStaticPopup("PSC_RESET_DEFAULTS",
        "Are you sure you want to reset all settings to defaults? This will not affect your kill/death statistics. Forces a UI reload!",
        function()
            ResetAllSettingsToDefault()
        end)
end

local function CreateSectionHeader(parent, text, xOffset, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    header:SetText(text)
    header:SetTextColor(PSC_CONFIG_HEADER_R, PSC_CONFIG_HEADER_G, PSC_CONFIG_HEADER_B)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetSize(parent:GetWidth() - (xOffset * 2), 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.7)

    return header
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

local function CreateAnnouncementSection(parent, yOffset)
    local announcementSettingsHeader = CreateSectionHeader(parent, "Party Chat Announcements", 20, yOffset)

    local enableKillAnnounceCheckbox, _ = CreateCheckbox(parent, "Announce kills", PSC_DB.EnableKillAnnounceMessages,
        function(checked)
            PSC_DB.EnableKillAnnounceMessages = checked
        end)
    enableKillAnnounceCheckbox:SetPoint("TOPLEFT", announcementSettingsHeader, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 10)
    parent.enableKillAnnounceCheckbox = enableKillAnnounceCheckbox
    enableKillAnnounceCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Announce kills in party chat")
        GameTooltip:AddLine("When checked, kills will be announced in party chat. You can customize these messages in the Messages tab. ", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    enableKillAnnounceCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local enableRecordAnnounceCheckbox, _ = CreateCheckbox(parent, "Announce personal bests",
        PSC_DB.EnableRecordAnnounceMessages, function(checked)
            PSC_DB.EnableRecordAnnounceMessages = checked
        end)
    enableRecordAnnounceCheckbox:SetPoint("TOPLEFT", enableKillAnnounceCheckbox, "BOTTOMLEFT", 0, -CHECKBOX_SPACING)
    parent.enableRecordAnnounceCheckbox = enableRecordAnnounceCheckbox
    enableRecordAnnounceCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Announce personal bests in party chat")
        GameTooltip:AddLine("When checked, a customizable party chat message will be sent when you achieve a new personal best for kill streak or multi-kill.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    enableRecordAnnounceCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local enableMultiKillAnnounceCheckbox, _ = CreateCheckbox(parent, "Announce multi-kills",
        PSC_DB.EnableMultiKillAnnounceMessages, function(checked)
            PSC_DB.EnableMultiKillAnnounceMessages = checked
        end)
    enableMultiKillAnnounceCheckbox:SetPoint("TOPLEFT", enableKillAnnounceCheckbox, "TOPLEFT", 300, 0)
    parent.enableMultiKillAnnounceCheckbox = enableMultiKillAnnounceCheckbox
    enableMultiKillAnnounceCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Announce personal bests in party chat")
        GameTooltip:AddLine("When checked, a customizable party chat message will be sent when you achieve a multi-kill.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    enableMultiKillAnnounceCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local slider = CreateFrame("Slider", "PSC_MultiKillThresholdSlider", parent, "OptionsSliderTemplate")
    slider:SetWidth(200)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", announcementSettingsHeader, "TOPLEFT", 305, -CHECKBOX_SPACING - 78)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(2, 10)
    slider:SetValueStep(1)
    slider:SetValue(PSC_DB.MultiKillThreshold or 3)
    getglobal(slider:GetName() .. "Low"):SetText("Double")
    getglobal(slider:GetName() .. "High"):SetText("Deca")
    getglobal(slider:GetName() .. "Text"):SetText("Multi-Kill announce threshold: " .. (PSC_DB.MultiKillThreshold or 3))
    parent.multiKillSlider = slider

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Multi-Kill announce threshold: " .. value)
        PSC_DB.MultiKillThreshold = value
    end)

    local battlegroundModeHeader = CreateSectionHeader(parent, "Battleground Mode", 20, -140)

    local autoBGModeCheckbox, _ = CreateCheckbox(parent, "Auto Battleground Mode", PSC_DB.AutoBattlegroundMode,
        function(checked)
            PSC_DB.AutoBattlegroundMode = checked
            PSC_CheckBattlegroundStatus()
        end)
    autoBGModeCheckbox:SetPoint("TOPLEFT", battlegroundModeHeader, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING)
    parent.autoBGModeCheckbox = autoBGModeCheckbox

    autoBGModeCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto Battleground Mode")
        GameTooltip:AddLine("When checked, BG mode will be automatically enabled if you enter a battleground. In BG Mode, kills are only counted if you get the killing blow and party chat announce messages are disabled.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    autoBGModeCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local assistsInBGCheckbox, _ = CreateCheckbox(parent, "Count assist kills",
        PSC_DB.CountAssistsInBattlegrounds, function(checked)
            PSC_DB.CountAssistsInBattlegrounds = checked
        end)
    assistsInBGCheckbox:SetPoint("TOPLEFT", autoBGModeCheckbox, "BOTTOMLEFT", 40, -CHECKBOX_SPACING + 5)
    parent.assistsInBGCheckbox = assistsInBGCheckbox

    assistsInBGCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Count assist kills in Battleground Mode")
        GameTooltip:AddLine(
            "Kills are counted count if you damage a player or cast harmful spells on them and someone else does the killing blow.",
            1, 1, 1, true)
        GameTooltip:Show()
    end)
    assistsInBGCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local forceEnableBGModeCheckbox, _ = CreateCheckbox(parent, "Force enable",
        PSC_DB.ForceBattlegroundMode, function(checked)
            PSC_DB.ForceBattlegroundMode = checked
            PSC_CheckBattlegroundStatus()
        end)
    forceEnableBGModeCheckbox:SetPoint("TOPLEFT", assistsInBGCheckbox, "BOTTOMLEFT", 0, -CHECKBOX_SPACING + 5)
    parent.manualBGModeCheckbox = forceEnableBGModeCheckbox

    forceEnableBGModeCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Force enable Battleground Mode")
        GameTooltip:AddLine("Enable BG mode until you turn it off again.", 1, 1, 1, false)
        GameTooltip:Show()
    end)
    forceEnableBGModeCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local trackBGKillsCheckbox, _ = CreateCheckbox(parent, "Count kills in battlegrounds",
        PSC_DB.CountKillsInBattlegrounds, function(checked)
            PSC_DB.CountKillsInBattlegrounds = checked
        end)
    trackBGKillsCheckbox:SetPoint("TOPLEFT", assistsInBGCheckbox, "TOPLEFT", 260, 0)
    parent.trackBGKillsCheckbox = trackBGKillsCheckbox

    trackBGKillsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Count kills in battlegrounds")
        GameTooltip:AddLine("When unchecked, kills in battlegrounds won't be counted at all.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    trackBGKillsCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local trackBGDeathsCheckbox, _ = CreateCheckbox(parent, "Count deaths in battlegrounds",
        PSC_DB.CountDeathsInBattlegrounds, function(checked)
            PSC_DB.CountDeathsInBattlegrounds = checked
        end)
    trackBGDeathsCheckbox:SetPoint("TOPLEFT", trackBGKillsCheckbox, "BOTTOMLEFT", 0, -CHECKBOX_SPACING + 2)
    parent.trackBGDeathsCheckbox = trackBGDeathsCheckbox

    trackBGDeathsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Count deaths in battlegrounds")
        GameTooltip:AddLine("When unchecked, deaths in battlegrounds won't be counted at all.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    trackBGDeathsCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local killMilestonesHeader = CreateSectionHeader(parent, "Kill Milestones", 20, -295)

    local showKillMilestonesCheckbox, _ = CreateCheckbox(parent, "Show kill milestones", PSC_DB.ShowKillMilestones,
        function(checked)
            PSC_DB.ShowKillMilestones = checked
        end)
    showKillMilestonesCheckbox:SetPoint("TOPLEFT", killMilestonesHeader, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 10)
    parent.showKillMilestonesCheckbox = showKillMilestonesCheckbox

    showKillMilestonesCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show kill milestones")
        GameTooltip:AddLine("Show a notification when you reach a certain number of kills for the same player.", 1, 1, 1, true)
        GameTooltip:AddLine("You can move the notificatin frame using drag and drop.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showKillMilestonesCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local killMilestoneSoundsCheckbox, _ = CreateCheckbox(parent, "Play milestone sound effect",
        PSC_DB.EnableKillMilestoneSound, function(checked)
            PSC_DB.EnableKillMilestoneSound = checked
        end)
    killMilestoneSoundsCheckbox:SetPoint("TOPLEFT", showKillMilestonesCheckbox, "BOTTOMLEFT", 40, -CHECKBOX_SPACING + 5)
    parent.killMilestoneSoundsCheckbox = killMilestoneSoundsCheckbox

    killMilestoneSoundsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Play milestone sound effect")
        GameTooltip:AddLine("Play a sound effect when a kill milestone notification is shown.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    killMilestoneSoundsCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local showMilestoneForFirstKillCheckbox, _ = CreateCheckbox(parent, "Show milestone for first kill",
        PSC_DB.ShowMilestoneForFirstKill, function(checked)
            PSC_DB.ShowMilestoneForFirstKill = checked
        end)
    showMilestoneForFirstKillCheckbox:SetPoint("TOPLEFT", killMilestoneSoundsCheckbox, "BOTTOMLEFT", 0,
        -CHECKBOX_SPACING + 5)
    parent.showMilestoneForFirstKillCheckbox = showMilestoneForFirstKillCheckbox

    showMilestoneForFirstKillCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show milestone for first kill")
        GameTooltip:AddLine("When checked, show a notification for your first kill of a player.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showMilestoneForFirstKillCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local milestoneIntervalSlider =
        CreateFrame("Slider", "PSC_MilestoneIntervalSlider", parent, "OptionsSliderTemplate")
    milestoneIntervalSlider:SetWidth(200)
    milestoneIntervalSlider:SetHeight(16)
    milestoneIntervalSlider:SetPoint("TOPLEFT", killMilestonesHeader, "BOTTOMLEFT", 310, -CHECKBOX_SPACING - 25)
    milestoneIntervalSlider:SetOrientation("HORIZONTAL")
    milestoneIntervalSlider:SetMinMaxValues(3, 10)
    milestoneIntervalSlider:SetValueStep(1)
    milestoneIntervalSlider:SetValue(PSC_DB.KillMilestoneInterval or 5)
    getglobal(milestoneIntervalSlider:GetName() .. "Low"):SetText("3")
    getglobal(milestoneIntervalSlider:GetName() .. "High"):SetText("10")
    getglobal(milestoneIntervalSlider:GetName() .. "Text"):SetText(
        "Milestone interval: Every " .. (PSC_DB.KillMilestoneInterval or 5) .. " kills")
    parent.milestoneIntervalSlider = milestoneIntervalSlider

    milestoneIntervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Milestone interval: Every " .. value .. " kills")
        PSC_DB.KillMilestoneInterval = value
    end)

    local milestoneAutoHideTimeSlider =
        CreateFrame("Slider", "PSC_MilestoneTimeSlider", parent, "OptionsSliderTemplate")
    milestoneAutoHideTimeSlider:SetWidth(200)
    milestoneAutoHideTimeSlider:SetHeight(16)
    milestoneAutoHideTimeSlider:SetPoint("TOPLEFT", milestoneIntervalSlider, "BOTTOMLEFT", 0, -30)
    milestoneAutoHideTimeSlider:SetOrientation("HORIZONTAL")
    milestoneAutoHideTimeSlider:SetMinMaxValues(1, 15)
    milestoneAutoHideTimeSlider:SetValueStep(1)
    milestoneAutoHideTimeSlider:SetValue(PSC_DB.KillMilestoneAutoHideTime or 5)
    getglobal(milestoneAutoHideTimeSlider:GetName() .. "Low"):SetText("1 sec")
    getglobal(milestoneAutoHideTimeSlider:GetName() .. "High"):SetText("15 sec")
    getglobal(milestoneAutoHideTimeSlider:GetName() .. "Text"):SetText(
        "Hide notification after: " .. (PSC_DB.KillMilestoneAutoHideTime or 5) .. " seconds")
    parent.milestoneAutoHideTimeSlider = milestoneAutoHideTimeSlider

    milestoneAutoHideTimeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)
        getglobal(self:GetName() .. "Text"):SetText("Hide notification after: " .. value .. " seconds")
        PSC_DB.KillMilestoneAutoHideTime = value
    end)

    local testButton = CreateButton(parent, "Show Kill Milestone", 160, 22, function()
        local testKillCounts = {1, PSC_DB.KillMilestoneInterval, PSC_DB.KillMilestoneInterval * 2}
        local index = math.random(1, 3)

        if not PSC_DB.ShowMilestoneForFirstKill and testKillCounts[index] == 1 then
            index = 2
        end

        local classes = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
        local randomClass = classes[math.random(1, #classes)]

        local useHorde = (math.random(1, 2) == 1)

        local rank
        if math.random(1, 10) <= 3 then
            rank = 0
        else
            local rankRoll = math.random(1, 100)
            if rankRoll <= 50 then
                rank = math.random(1, 4)
                rank = math.random(5, 8)
            elseif rankRoll <= 90 then
                rank = math.random(9, 11)
            else
                rank = math.random(12, 14)
            end
        end

        PSC_ShowKillMilestone("TestPlayer", 60, randomClass, rank, testKillCounts[index])
    end)
    testButton:SetPoint("TOPLEFT", milestoneAutoHideTimeSlider, "BOTTOMLEFT", -2, -20)
    parent.milestoneTestButton = testButton

    local generalSectionHeader = CreateSectionHeader(parent, "General", 20, -460)

    local enableMultiKillSoundsCheckbox, _ = CreateCheckbox(parent, "Enable multi-kill sound effects",
        PSC_DB.EnableMultiKillSounds, function(checked)
            PSC_DB.EnableMultiKillSounds = checked
        end)
    enableMultiKillSoundsCheckbox:SetPoint("TOPLEFT", generalSectionHeader, "BOTTOMLEFT", 0, -CHECKBOX_SPACING - 5)
    parent.enableKillSoundsCheckbox = enableMultiKillSoundsCheckbox

    enableMultiKillSoundsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Enable multi-kill sound effects")
        GameTooltip:AddLine("Play Leage of Legends multi-kill sounds when you achieve a multi-kill.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    enableMultiKillSoundsCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local tooltipKillInfoCheckbox, _ = CreateCheckbox(parent, "Show kills in mouseover tooltips",
        PSC_DB.ShowScoreInPlayerTooltip, function(checked)
            PSC_DB.ShowScoreInPlayerTooltip = checked
        end)
    tooltipKillInfoCheckbox:SetPoint("TOPLEFT", enableMultiKillSoundsCheckbox, "TOPLEFT", 300, 0)
    parent.tooltipKillInfoCheckbox = tooltipKillInfoCheckbox

    tooltipKillInfoCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show kills in mouseover tooltips")
        GameTooltip:AddLine("Show your kills of an enemy player in their mouseover tooltip.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tooltipKillInfoCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local tooltipExtendedInfoCheckbox, _ = CreateCheckbox(parent, "Show deaths and time since last kill",
        PSC_DB.ShowExtendedTooltipInfo or true, function(checked)
            PSC_DB.ShowExtendedTooltipInfo = checked
        end)
    tooltipExtendedInfoCheckbox:SetPoint("TOPLEFT", tooltipKillInfoCheckbox, "BOTTOMLEFT", 0, -CHECKBOX_SPACING + 2)
    parent.tooltipExtendedInfoCheckbox = tooltipExtendedInfoCheckbox

    tooltipExtendedInfoCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show deaths and time since last kill")
        GameTooltip:AddLine("When checked, tooltips will show your deaths against that player and time since your last kill. When unchecked, only the number of kills will be shown.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tooltipExtendedInfoCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local showAccountWideStatsCheckbox, _ = CreateCheckbox(parent, "Show account-wide statistics",
        PSC_DB.ShowAccountWideStats, function(checked)
            PSC_DB.ShowAccountWideStats = checked
        end)
    showAccountWideStatsCheckbox:SetPoint("TOPLEFT", enableMultiKillSoundsCheckbox, "BOTTOMLEFT", 0, -CHECKBOX_SPACING + 2)
    parent.showAccountWideStatsCheckbox = showAccountWideStatsCheckbox
    showAccountWideStatsCheckbox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show account-wide statistics")
        GameTooltip:AddLine("When checked, the addon will use data from all your characters for statistics calculation and in the kills list.", 1, 1, 1, true)
        GameTooltip:AddLine("When unchecked, only data from your current character will be used.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    showAccountWideStatsCheckbox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return 320
end

local function CreateMessageTemplatesSection(parent, yOffset)
    yOffset = yOffset

    local header, line = CreateSectionHeader(parent, "Party Announcement Messages", 20, yOffset)

    local killMsgContainer, killMsgEditBox = CreateInputField(parent, "Kill announcement message:", 560,
        PSC_DB.KillAnnounceMessage, function(text)
            PSC_DB.KillAnnounceMessage = text
        end)
    killMsgContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -HEADER_ELEMENT_SPACING - 10)

    local killAnnounceMessageDesc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    killAnnounceMessageDesc:SetPoint("TOPLEFT", killMsgEditBox, "BOTTOMLEFT", -4, -5)
    killAnnounceMessageDesc:SetText(
        "Placeholders: |cFFFFFFFFEnemyplayername|r for player name and |cFFFFFFFFx#|r for kill count (e.g. x3 for 3rd kill).")
    killAnnounceMessageDesc:SetJustifyH("LEFT")

    local streakEndedContainer, streakEndedEditBox = CreateInputField(parent, "Kill streak ended message:", 560,
        PSC_DB.KillStreakEndedMessage, function(text)
            PSC_DB.KillStreakEndedMessage = text
        end)
    streakEndedContainer:SetPoint("TOPLEFT", killMsgContainer, "BOTTOMLEFT", 0, -MESSAGE_TEXTFIELD_SPACING)

    local streakEndedMessageDesc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    streakEndedMessageDesc:SetPoint("TOPLEFT", streakEndedEditBox, "BOTTOMLEFT", -4, -5)
    streakEndedMessageDesc:SetText("Placeholder: |cFFFFFFFFSTREAKCOUNT|r for the number of kills in your streak.")
    streakEndedMessageDesc:SetJustifyH("LEFT")

    local newStreakContainer, newStreakEditBox = CreateInputField(parent, "New kill streak personal best message:", 560,
        PSC_DB.NewKillStreakRecordMessage, function(text)
            PSC_DB.NewKillStreakRecordMessage = text
        end)
    newStreakContainer:SetPoint("TOPLEFT", streakEndedContainer, "BOTTOMLEFT", 0, -MESSAGE_TEXTFIELD_SPACING)

    local newStreakMessageDesc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    newStreakMessageDesc:SetPoint("TOPLEFT", newStreakEditBox, "BOTTOMLEFT", -4, -5)
    newStreakMessageDesc:SetText("Placeholder: |cFFFFFFFFSTREAKCOUNT|r for the number of kills in your streak.")
    newStreakMessageDesc:SetJustifyH("LEFT")

    local multiKillContainer, multiKillEditBox = CreateInputField(parent, "New multi-kill personal best message:", 560,
        PSC_DB.NewMultiKillRecordMessage, function(text)
            PSC_DB.NewMultiKillRecordMessage = text
        end)
    multiKillContainer:SetPoint("TOPLEFT", newStreakContainer, "BOTTOMLEFT", 0, -MESSAGE_TEXTFIELD_SPACING)

    local multiKillMessageDesc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    multiKillMessageDesc:SetPoint("TOPLEFT", multiKillEditBox, "BOTTOMLEFT", -4, -5)
    multiKillMessageDesc:SetText(
        "Placeholder: |cFFFFFFFFMULTIKILLTEXT|r for the multi-kill description ('Double-Kill', 'Triple-Kill', etc).")
    multiKillMessageDesc:SetJustifyH("LEFT")

    return {
        killMsg = killMsgEditBox,
        streakEnded = streakEndedEditBox,
        newStreak = newStreakEditBox,
        multiKill = multiKillEditBox
    }
end

local function CreateActionButtons(parent)
    local buttonContainer = CreateFrame("Frame", nil, parent)
    buttonContainer:SetSize(200, 200)
    buttonContainer:SetPoint("CENTER")

    local buttonWidth = 160
    local buttonHeight = 25
    local buttonSpacing = 15

    local resetStatsBtn = CreateButton(buttonContainer, "Reset Statistics", buttonWidth, buttonHeight, function()
        ShowResetStatsConfirmation()
    end)

    local defaultsBtn = CreateButton(buttonContainer, "Reset to Defaults", buttonWidth, buttonHeight, function()
        ShowResetDefaultsConfirmation()
    end)

    resetStatsBtn:SetPoint("TOP", buttonContainer, "TOP", 0, 0)
    defaultsBtn:SetPoint("TOP", resetStatsBtn, "BOTTOM", 0, -buttonSpacing)

    return {
        resetBtn = resetStatsBtn,
        defaultsBtn = defaultsBtn
    }
end

local currentTestAchievement = 1

local function CreateTestAchievementButton(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(200, 22)
    button:SetText("Test Achievement Popup")
    button:SetPoint("TOPLEFT", 20, -240)

    button:SetScript("OnClick", function()
        -- Use our new test achievement function
        PVPSC.AchievementSystem:TestAchievementPopup()
    end)

    -- Create a simple explanation text
    local helpText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -5)
    helpText:SetText("Press to display a randomly styled test achievement popup")
    helpText:SetTextColor(0.8, 0.8, 0.8)

    return button
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PSC_ConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(600, 660)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    tinsert(UISpecialFrames, "PSC_ConfigFrame")

    frame.TitleText:SetText("PvP Stats Settings")

    return frame
end

function PSC_UpdateConfigUI()
    if not configFrame then
        return
    end

    configFrame.autoBGModeCheckbox:SetChecked(PSC_DB.AutoBattlegroundMode)
    configFrame.assistsInBGCheckbox:SetChecked(PSC_DB.CountAssistsInBattlegrounds)
    configFrame.manualBGModeCheckbox:SetChecked(PSC_DB.ForceBattlegroundMode)
    configFrame.tooltipKillInfoCheckbox:SetChecked(PSC_DB.ShowScoreInPlayerTooltip)
    configFrame.tooltipExtendedInfoCheckbox:SetChecked(PSC_DB.ShowExtendedTooltipInfo)
    configFrame.showKillMilestonesCheckbox:SetChecked(PSC_DB.ShowKillMilestones)
    configFrame.killMilestoneSoundsCheckbox:SetChecked(PSC_DB.EnableKillMilestoneSound)
    configFrame.showMilestoneForFirstKillCheckbox:SetChecked(PSC_DB.ShowMilestoneForFirstKill)
    configFrame.enableKillAnnounceCheckbox:SetChecked(PSC_DB.EnableKillAnnounceMessages)
    configFrame.enableRecordAnnounceCheckbox:SetChecked(PSC_DB.EnableRecordAnnounceMessages)
    configFrame.enableMultiKillAnnounceCheckbox:SetChecked(PSC_DB.EnableMultiKillAnnounceMessages)
    configFrame.enableKillSoundsCheckbox:SetChecked(PSC_DB.EnableMultiKillSounds)
    configFrame.showAccountWideStatsCheckbox:SetChecked(PSC_DB.ShowAccountWideStats)
    configFrame.trackBGKillsCheckbox:SetChecked(PSC_DB.CountKillsInBattlegrounds)
    configFrame.trackBGDeathsCheckbox:SetChecked(PSC_DB.CountDeathsInBattlegrounds)

    if configFrame.multiKillSlider and configFrame.multiKillSlider:GetName() then
        configFrame.multiKillSlider:SetValue(PSC_DB.MultiKillThreshold or 3)
        getglobal(configFrame.multiKillSlider:GetName() .. "Text"):SetText(
            "Multi-Kill announce threshold: " .. (PSC_DB.MultiKillThreshold or 3))
    end

    if configFrame.milestoneIntervalSlider and configFrame.milestoneIntervalSlider:GetName() then
        configFrame.milestoneIntervalSlider:SetValue(PSC_DB.KillMilestoneInterval or 5)
        getglobal(configFrame.milestoneIntervalSlider:GetName() .. "Text"):SetText(
            "Milestone interval: Every " .. (PSC_DB.KillMilestoneInterval or 5) .. " kills")
    end

    if configFrame.milestoneAutoHideTimeSlider and configFrame.milestoneAutoHideTimeSlider:GetName() then
        configFrame.milestoneAutoHideTimeSlider:SetValue(PSC_DB.KillMilestoneAutoHideTime or 5)
        getglobal(configFrame.milestoneAutoHideTimeSlider:GetName() .. "Text"):SetText(
            "Hide notification after: " .. (PSC_DB.KillMilestoneAutoHideTime or 5) .. " seconds")
    end

    configFrame.editBoxes.killMsg:SetText(PSC_DB.KillAnnounceMessage)
    configFrame.editBoxes.streakEnded:SetText(PSC_DB.KillStreakEndedMessage)
    configFrame.editBoxes.newStreak:SetText(PSC_DB.NewKillStreakRecordMessage)
    configFrame.editBoxes.multiKill:SetText(PSC_DB.NewMultiKillRecordMessage)
end

local function CreateTabSystem(parent)
    local tabWidth = 85
    local tabHeight = 32
    local tabs = {}
    local tabFrames = {}

    local tabContainer = CreateFrame("Frame", nil, parent)
    tabContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", 7, -25)
    tabContainer:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -7, 7)

    local tabNames = {"General", "Messages", "Reset", "About"}
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", parent:GetName() .. "Tab" .. i, parent, "CharacterFrameTabButtonTemplate")
        tab:SetText(name)
        tab:SetID(i)

        tab:SetSize(tabWidth, tabHeight)

        local tabMiddle = _G[tab:GetName() .. "Middle"]
        local tabLeft = _G[tab:GetName() .. "Left"]
        local tabRight = _G[tab:GetName() .. "Right"]
        local tabSelectedMiddle = _G[tab:GetName() .. "SelectedMiddle"]
        local tabSelectedLeft = _G[tab:GetName() .. "SelectedLeft"]
        local tabSelectedRight = _G[tab:GetName() .. "SelectedRight"]
        local tabText = _G[tab:GetName() .. "Text"]

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

        if i == 1 then
            tab:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 5, 0)
        else
            tab:SetPoint("LEFT", tabs[i - 1], "RIGHT", -8, 0)
        end

        if tabText then
            tabText:ClearAllPoints()
            tabText:SetPoint("CENTER", tab, "CENTER", 0, 2)
            tabText:SetJustifyH("CENTER")
            tabText:SetWidth(tabWidth - 40)
        end

        local contentFrame = CreateFrame("Frame", nil, tabContainer)
        contentFrame:SetPoint("TOPLEFT", tabContainer, "TOPLEFT", 0, -5)
        contentFrame:SetPoint("BOTTOMRIGHT", tabContainer, "BOTTOMRIGHT")
        contentFrame:Hide()

        tabFrames[i] = contentFrame
        table.insert(tabs, tab)

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

    for i, tab in ipairs(tabs) do
        PanelTemplates_TabResize(tab, 0)
    end

    return tabFrames
end

local function CreateCopyableField(parent, label, text, anchorTo, xOffset, yOffset)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset, yOffset)
    labelText:SetText(label)

    local editBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetSize(285, 20)
    editBox:SetPoint("TOPLEFT", labelText, "TOPLEFT", labelText:GetStringWidth() + 10, 5)
    editBox:SetText(text)
    editBox:SetTextColor(0.3, 0.6, 1.0)

    editBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(text)
            self:HighlightText()
        end
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return labelText, editBox
end

local function CreateAboutTab(parent)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", parent, "TOP", 0, -20)
    header:SetText("PvP Stats (Classic)")
    header:SetTextColor(PSC_CONFIG_HEADER_R, PSC_CONFIG_HEADER_G, PSC_CONFIG_HEADER_B)

    local versionText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOP", header, "BOTTOM", 0, -5)
    versionText:SetText("Version: 2.1")
    versionText:SetTextColor(1, 1, 1)

    local creditsHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    creditsHeader:SetPoint("TOP", header, "BOTTOM", 0, -60)
    creditsHeader:SetText("Credits")
    creditsHeader:SetTextColor(PSC_CONFIG_HEADER_R, PSC_CONFIG_HEADER_G, PSC_CONFIG_HEADER_B)

    local logo = parent:CreateTexture(nil, "ARTWORK")
    logo:SetSize(240, 240)
    logo:SetPoint("TOP", creditsHeader, "BOTTOM", 0, -10)
    logo:SetTexture("Interface\\AddOns\\PvPStatsClassic\\img\\RedridgePoliceLogo.blp")

    local hunterColor = RAID_CLASS_COLORS["HUNTER"] or {
        r = 0.67,
        g = 0.83,
        b = 0.45
    }

    local contentWidth = 300
    local creditsContainer = CreateFrame("Frame", nil, parent)
    creditsContainer:SetSize(contentWidth, 200)
    creditsContainer:SetPoint("TOP", logo, "BOTTOM", 29, -10)

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
    andText:SetTextColor(1, 1, 1) -- Set color to white

    local secondAuthorText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    secondAuthorText:SetPoint("TOPLEFT", andText, "TOPRIGHT", 5, 0)
    secondAuthorText:SetText("Hkfarmer")
    secondAuthorText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    local guildText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildText:SetPoint("TOPLEFT", devsLabel, "BOTTOMLEFT", 0, -10)
    guildText:SetText("Guild: ")
    guildText:SetTextColor(PSC_CONFIG_HEADER_R, PSC_CONFIG_HEADER_G, PSC_CONFIG_HEADER_B)

    local guildNameText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildNameText:SetPoint("TOPLEFT", guildText, "TOPRIGHT", 0, 0)
    guildNameText:SetText("<Redridge Police>")
    guildNameText:SetTextColor(1, 1, 1) -- Set color to white

    local realmText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    realmText:SetPoint("TOPLEFT", guildText, "BOTTOMLEFT", 0, -10)
    realmText:SetText("Realm: ")
    realmText:SetTextColor(PSC_CONFIG_HEADER_R, PSC_CONFIG_HEADER_G, PSC_CONFIG_HEADER_B)

    local realmNameText = creditsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    realmNameText:SetPoint("TOPLEFT", realmText, "TOPRIGHT", 0, 0)
    realmNameText:SetText("Spineshatter (EU)")
    realmNameText:SetTextColor(1, 1, 1) -- Set color to white

    local discordLabel, discordField = CreateCopyableField(creditsContainer, "Discord:", "https://discord.gg/ZBaN2xk5h3",
        realmText, -60, -50)
    local githubLabel, githubField = CreateCopyableField(creditsContainer, "GitHub: ",
        "github.com/randomdude163/WoWClassic_PvPStats", discordLabel, 0, -20)
    local contactLabel, contactField = CreateCopyableField(creditsContainer, "Contact:", "redridgepolice@outlook.com",
        githubLabel, 0, -20)

    return parent
end

function PSC_CreateConfigFrame()
    if configFrame then
        configFrame:Show()
        return
    end

    configFrame = CreateMainFrame()
    PSC_FrameManager:RegisterFrame(configFrame, "ConfigUI")

    local tabFrames = CreateTabSystem(configFrame)

    local currentY = -10
    local announcementHeight = CreateAnnouncementSection(tabFrames[1], currentY)

    configFrame.autoBGModeCheckbox = tabFrames[1].autoBGModeCheckbox
    configFrame.assistsInBGCheckbox = tabFrames[1].assistsInBGCheckbox
    configFrame.manualBGModeCheckbox = tabFrames[1].manualBGModeCheckbox
    configFrame.tooltipKillInfoCheckbox = tabFrames[1].tooltipKillInfoCheckbox
    configFrame.showKillMilestonesCheckbox = tabFrames[1].showKillMilestonesCheckbox
    configFrame.killMilestoneSoundsCheckbox = tabFrames[1].killMilestoneSoundsCheckbox
    configFrame.showMilestoneForFirstKillCheckbox = tabFrames[1].showMilestoneForFirstKillCheckbox
    configFrame.enableKillAnnounceCheckbox = tabFrames[1].enableKillAnnounceCheckbox
    configFrame.enableRecordAnnounceCheckbox = tabFrames[1].enableRecordAnnounceCheckbox
    configFrame.enableMultiKillAnnounceCheckbox = tabFrames[1].enableMultiKillAnnounceCheckbox
    configFrame.enableKillSoundsCheckbox = tabFrames[1].enableKillSoundsCheckbox
    configFrame.showAccountWideStatsCheckbox = tabFrames[1].showAccountWideStatsCheckbox
    configFrame.trackBGKillsCheckbox = tabFrames[1].trackBGKillsCheckbox
    configFrame.trackBGDeathsCheckbox = tabFrames[1].trackBGDeathsCheckbox
    configFrame.milestoneIntervalSlider = tabFrames[1].milestoneIntervalSlider
    configFrame.milestoneAutoHideTimeSlider = tabFrames[1].milestoneAutoHideTimeSlider
    configFrame.multiKillSlider = tabFrames[1].multiKillSlider
    configFrame.tooltipExtendedInfoCheckbox = tabFrames[1].tooltipExtendedInfoCheckbox

    configFrame.editBoxes = CreateMessageTemplatesSection(tabFrames[2], -10)

    local resetButtons = CreateActionButtons(tabFrames[3])
    configFrame.resetButtons = resetButtons

    -- local testAchievementButton = CreateTestAchievementButton(tabFrames[3])

    CreateAboutTab(tabFrames[4])

    PanelTemplates_SetTab(configFrame, 1)
    tabFrames[1]:Show()

    PSC_UpdateConfigUI()

    return configFrame
end

function PSC_CreateConfigUI()
    if configFrame then
        PSC_FrameManager:ShowFrame("Config")
        return
    end

    PSC_CreateConfigFrame()
end
