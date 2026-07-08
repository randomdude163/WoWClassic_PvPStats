local addonName, PVPSC = ...

-- ============================================================
-- Kill On Sight: a player watchlist and a guild watchlist, alerted the
-- moment a match is detected. Reuses the detection this addon already has -
-- BPP_GetAndStorePlayerInfoFromUnit (DataStorage.lua) resolves name/guild
-- for every target/mouseover/nameplate event - instead of building a
-- separate scanning engine (the way the Spy addon does with its own
-- combat-log parsing and spell-based class inference).
-- ============================================================

local KOS_ALERT_COOLDOWN = 60 -- seconds; avoid re-alerting on every mouseover tick
local kosLastAlerted = {} -- [infoKey] = time() of last alert this session

local function EnsureKOSTables()
    BPP_DB.KOSPlayers = BPP_DB.KOSPlayers or {}
    BPP_DB.KOSGuilds = BPP_DB.KOSGuilds or {}
end

-- ============================================================
-- List management
-- ============================================================

-- input: "PlayerName" or "PlayerName some reason text"
function BPP_AddKOSPlayer(input)
    if not input or strtrim(input) == "" then
        return false, "No player name given."
    end
    EnsureKOSTables()

    local trimmed = strtrim(input)
    local rawName, reason = trimmed:match("^(%S+)%s+(.+)$")
    rawName = rawName or trimmed

    local infoKey = BPP_GetInfoKeyFromName(rawName)
    local displayName = infoKey:match("^([^-]+)") or rawName

    BPP_DB.KOSPlayers[infoKey] = {
        name = displayName,
        reason = reason and strtrim(reason) ~= "" and strtrim(reason) or nil,
        addedAt = time(),
    }
    return true, displayName
end

function BPP_RemoveKOSPlayer(name)
    if not name or strtrim(name) == "" then return false end
    EnsureKOSTables()
    local infoKey = BPP_GetInfoKeyFromName(strtrim(name))
    if not BPP_DB.KOSPlayers[infoKey] then return false end
    BPP_DB.KOSPlayers[infoKey] = nil
    return true
end

-- input: "Guild Name" or "Guild Name - some reason text"
function BPP_AddKOSGuild(input)
    if not input or strtrim(input) == "" then
        return false, "No guild name given."
    end
    EnsureKOSTables()

    local trimmed = strtrim(input)
    local guildName, reason = trimmed:match("^(.-)%s+%-%s+(.+)$")
    guildName = guildName and strtrim(guildName) ~= "" and strtrim(guildName) or trimmed

    BPP_DB.KOSGuilds[guildName] = {
        reason = reason and strtrim(reason) ~= "" and strtrim(reason) or nil,
        addedAt = time(),
    }
    return true, guildName
end

function BPP_RemoveKOSGuild(guildName)
    if not guildName or strtrim(guildName) == "" then return false end
    EnsureKOSTables()
    guildName = strtrim(guildName)
    if not BPP_DB.KOSGuilds[guildName] then return false end
    BPP_DB.KOSGuilds[guildName] = nil
    return true
end

-- ============================================================
-- Alert popup - same dynamic-height toast pattern as the rivalry popup in
-- GuildRivalry.lua, but red-themed and on its own timer/frame so a rivalry
-- milestone and a KOS sighting can't cut each other off.
-- ============================================================

local kosPopupFrame = nil
local kosPopupTimer = nil

local function CreateKOSPopupFrame()
    if kosPopupFrame then return kosPopupFrame end

    local frame = CreateFrame("Frame", "BPP_KOSPopupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(320, 90)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -250)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "KOSPopup", true)
    end

    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(0.9, 0.1, 0.1)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    frame.icon = icon

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -6)
    title:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1.0, 0.15, 0.15)
    frame.title = title

    local subText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    subText:SetJustifyH("LEFT")
    subText:SetJustifyV("TOP")
    subText:SetWordWrap(true)
    frame.subText = subText

    frame:Hide()
    kosPopupFrame = frame
    return frame
end

local KOS_POPUP_MIN_HEIGHT = 90
local KOS_POPUP_MAX_HEIGHT = 320

local function ShowKOSAlert(title, subText)
    local frame = CreateKOSPopupFrame()

    if kosPopupTimer then
        kosPopupTimer:Cancel()
        kosPopupTimer = nil
    end

    frame.title:SetText(title)
    frame.subText:SetText(subText)

    local contentHeight = 12 + frame.title:GetStringHeight() + 6 + frame.subText:GetStringHeight() + 16
    frame:SetHeight(math.max(KOS_POPUP_MIN_HEIGHT, math.min(contentHeight, KOS_POPUP_MAX_HEIGHT)))

    frame:Show()
    frame:SetAlpha(1)

    if BPP_FrameManager then
        BPP_FrameManager:BringToFront("KOSPopup")
    end

    PlaySound(8959) -- "RaidWarning" - distinct from the rivalry milestone fanfare

    kosPopupTimer = C_Timer.NewTimer(8, function()
        UIFrameFade(frame, { mode = "OUT", timeToFade = 1, finishedFunc = function() frame:Hide() end })
        kosPopupTimer = nil
    end)
end

-- ============================================================
-- Detection
--
-- Called from BPP_GetAndStorePlayerInfoFromUnit (DataStorage.lua) for every
-- hostile player it resolves name/guild for via target, mouseover, or
-- nameplate. A named match takes priority over a guild match. Cooldown is
-- per detected player so lingering on a mouseover doesn't spam the alert.
-- ============================================================

function BPP_CheckKillOnSight(name, guildName)
    if not BPP_DB or not name or name == "" then return end
    EnsureKOSTables()

    local infoKey = BPP_GetInfoKeyFromName(name)
    local now = time()
    if kosLastAlerted[infoKey] and now - kosLastAlerted[infoKey] < KOS_ALERT_COOLDOWN then
        return
    end

    local playerEntry = BPP_DB.KOSPlayers[infoKey]
    if playerEntry then
        kosLastAlerted[infoKey] = now
        ShowKOSAlert("KOS: " .. playerEntry.name, playerEntry.reason or "No reason logged. Kill on sight.")
        return
    end

    if guildName and guildName ~= "" then
        local guildEntry = BPP_DB.KOSGuilds[guildName]
        if guildEntry then
            kosLastAlerted[infoKey] = now
            local displayName = infoKey:match("^([^-]+)") or name
            local subText = "Member of KOS guild " .. guildName .. "."
            if guildEntry.reason then
                subText = subText .. " " .. guildEntry.reason
            end
            ShowKOSAlert("KOS Guild: " .. displayName, subText)
        end
    end
end

-- ============================================================
-- Kill On Sight list window
-- ============================================================

local kosListFrame = nil

local function CreateKOSAddRow(parent, labelText, placeholderHint, onSubmit)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(300, 25)

    local editBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    editBox:SetSize(220, 25)
    editBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextInsets(5, 5, 5, 5)

    local addButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    addButton:SetSize(60, 22)
    addButton:SetPoint("LEFT", editBox, "RIGHT", 8, 0)
    addButton:SetText(labelText)

    local function Submit()
        local text = editBox:GetText()
        if text and strtrim(text) ~= "" then
            onSubmit(text)
            editBox:SetText("")
            editBox:ClearFocus()
        end
    end

    addButton:SetScript("OnClick", Submit)
    editBox:SetScript("OnEnterPressed", Submit)

    editBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(placeholderHint, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    editBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return row
end

local function CreateKOSListFrame()
    if kosListFrame then return kosListFrame end

    local frame = CreateFrame("Frame", "BPP_KOSListFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(380, 480)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Kill On Sight")
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    tinsert(UISpecialFrames, "BPP_KOSListFrame")

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "KOSList")
    end

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -30)
    hint:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText("Get a loud alert the moment a watchlisted player, or anyone from a watchlisted guild, is targeted, moused over, or shows up on a nameplate.")

    local playerAddRow = CreateKOSAddRow(frame, "Add", "Player name, optionally followed by a reason.\nExample: Somename ganked me at the lake", function(text)
        local ok, nameOrErr = BPP_AddKOSPlayer(text)
        if ok then
            BPP_Print("[BigPPvP] Added " .. nameOrErr .. " to your Kill On Sight list.")
            BPP_RefreshKOSListFrame()
        else
            BPP_Print("[BigPPvP] " .. nameOrErr)
        end
    end)
    playerAddRow:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", -5, -12)

    local playerAddLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    playerAddLabel:SetPoint("TOPLEFT", playerAddRow, "TOPLEFT", 5, 12)
    playerAddLabel:SetText("Add Player")

    local guildAddRow = CreateKOSAddRow(frame, "Add", "Guild name, optionally followed by ' - ' and a reason.\nExample: The Red Empire - wiped our raid", function(text)
        local ok, guildOrErr = BPP_AddKOSGuild(text)
        if ok then
            BPP_Print("[BigPPvP] Added guild " .. guildOrErr .. " to your Kill On Sight list.")
            BPP_RefreshKOSListFrame()
        else
            BPP_Print("[BigPPvP] " .. guildOrErr)
        end
    end)
    guildAddRow:SetPoint("TOPLEFT", playerAddRow, "BOTTOMLEFT", 0, -22)

    local guildAddLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    guildAddLabel:SetPoint("TOPLEFT", guildAddRow, "TOPLEFT", 5, 12)
    guildAddLabel:SetText("Add Guild")

    local scrollFrame = CreateFrame("ScrollFrame", "BPP_KOSListScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", guildAddRow, "BOTTOMLEFT", 5, -14)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)

    frame.content = content
    kosListFrame = frame
    return frame
end

local function CreateKOSListRow(content, rowY, displayText, tooltipLines, onRemove)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", 5, rowY)
    nameText:SetWidth(250)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(displayText)

    local removeButton = CreateFrame("Button", nil, content, "UIPanelCloseButton")
    removeButton:SetSize(20, 20)
    removeButton:SetPoint("TOPRIGHT", 15, rowY + 3)
    removeButton:SetScript("OnClick", onRemove)
    removeButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Remove", 1, 1, 1)
        GameTooltip:Show()
    end)
    removeButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    if tooltipLines and #tooltipLines > 0 then
        local hitbox = CreateFrame("Frame", nil, content)
        hitbox:SetPoint("TOPLEFT", nameText, "TOPLEFT", 0, 0)
        hitbox:SetSize(250, 18)
        hitbox:EnableMouse(true)
        hitbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            for _, line in ipairs(tooltipLines) do
                GameTooltip:AddLine(line, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        hitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

function BPP_RefreshKOSListFrame()
    local frame = CreateKOSListFrame()
    local content = frame.content
    EnsureKOSTables()

    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local rowY = -5

    local playerHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerHeader:SetPoint("TOPLEFT", 5, rowY)
    playerHeader:SetText("Players")
    playerHeader:SetTextColor(1.0, 0.5, 0.5)
    rowY = rowY - 20

    local playerEntries = {}
    for infoKey, entry in pairs(BPP_DB.KOSPlayers) do
        table.insert(playerEntries, { key = infoKey, entry = entry })
    end
    table.sort(playerEntries, function(a, b) return a.entry.name < b.entry.name end)

    if #playerEntries == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        emptyText:SetPoint("TOPLEFT", 10, rowY)
        emptyText:SetText("No players added yet.")
        rowY = rowY - 20
    else
        for _, item in ipairs(playerEntries) do
            local tooltipLines = { item.entry.reason or "No reason logged." }
            CreateKOSListRow(content, rowY, item.entry.name, tooltipLines, function()
                BPP_RemoveKOSPlayer(item.key)
                BPP_RefreshKOSListFrame()
            end)
            rowY = rowY - 22
        end
    end

    rowY = rowY - 10
    local guildHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    guildHeader:SetPoint("TOPLEFT", 5, rowY)
    guildHeader:SetText("Guilds")
    guildHeader:SetTextColor(1.0, 0.5, 0.5)
    rowY = rowY - 20

    local guildEntries = {}
    for guildName, entry in pairs(BPP_DB.KOSGuilds) do
        table.insert(guildEntries, { name = guildName, entry = entry })
    end
    table.sort(guildEntries, function(a, b) return a.name < b.name end)

    if #guildEntries == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        emptyText:SetPoint("TOPLEFT", 10, rowY)
        emptyText:SetText("No guilds added yet.")
        rowY = rowY - 20
    else
        for _, item in ipairs(guildEntries) do
            local tooltipLines = { item.entry.reason or "No reason logged." }
            CreateKOSListRow(content, rowY, item.name, tooltipLines, function()
                BPP_RemoveKOSGuild(item.name)
                BPP_RefreshKOSListFrame()
            end)
            rowY = rowY - 22
        end
    end

    content:SetHeight(math.max(-rowY + 10, 10))
end

function BPP_ShowKOSListFrame()
    BPP_RefreshKOSListFrame()
    kosListFrame:Show()
end
