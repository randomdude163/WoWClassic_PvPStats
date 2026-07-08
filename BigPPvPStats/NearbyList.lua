local addonName, PVPSC = ...

-- ============================================================
-- Nearby Enemies panel - a small always-on-screen list of hostile players
-- detected via the same target/mouseover/nameplate hooks the rest of the
-- addon already uses (see BPP_GetAndStorePlayerInfoFromUnit in
-- DataStorage.lua). Modeled on the Spy addon's main window: right-click a
-- row to add/remove Kill On Sight or toggle Ignore.
-- ============================================================

local NEARBY_EXPIRY_DEFAULT = 600 -- entries drop off 10 minutes after last seen by default
local NEARBY_PRUNE_INTERVAL = 30

local function GetNearbyExpirySeconds()
    return (BPP_DB and BPP_DB.NearbyPanelExpirySeconds) or NEARBY_EXPIRY_DEFAULT
end

local nearbyPlayers = {} -- [infoKey] = { name, level, class, race, guild, lastSeen }
local nearbyPanelFrame = nil
local nearbyPruneTicker = nil

-- ============================================================
-- Recording + pruning
-- ============================================================

function BPP_RecordNearbyPlayer(name, level, class, race, guildName, infoKey)
    if not name or name == "" then return end
    infoKey = infoKey or BPP_GetInfoKeyFromName(name)

    nearbyPlayers[infoKey] = {
        name = name,
        level = level,
        class = class,
        race = race,
        guild = guildName,
        lastSeen = time(),
    }

    if nearbyPanelFrame and nearbyPanelFrame:IsShown() then
        BPP_RefreshNearbyPanel()
    end
end

-- Win/loss vs a specific enemy, derived from data this addon already
-- tracks (kill history + death-by-killer records) rather than a new counter.
local function GetWinLossAgainstPlayer(infoKey)
    local wins, losses = 0, 0
    if not BPP_DB then return wins, losses end

    local characterKey = BPP_GetCharacterKey()
    local shortName = infoKey:match("^([^-]+)") or infoKey

    local characterData = BPP_DB.PlayerKillCounts and BPP_DB.PlayerKillCounts.Characters
        and BPP_DB.PlayerKillCounts.Characters[characterKey]
    if characterData and characterData.Kills then
        for nameWithLevel, killData in pairs(characterData.Kills) do
            local name = nameWithLevel:match("^([^:]+)")
            if name and BPP_IsSamePlayerName(name, shortName) then
                wins = wins + (killData.kills or 0)
            end
        end
    end

    local lossData = BPP_DB.PvPLossCounts and BPP_DB.PvPLossCounts[characterKey]
    if lossData and lossData.Deaths and lossData.Deaths[infoKey] then
        losses = lossData.Deaths[infoKey].deaths or 0
    end

    return wins, losses
end

-- ============================================================
-- Stealth/Prowl alert - a small distinct toast when a hostile player is
-- seen going into Stealth or Prowl nearby, from the combat log (works even
-- if they're never targeted/moused-over). Independent of the Kill On Sight
-- popup so the two can't cut each other off.
-- ============================================================

local STEALTH_ALERT_COOLDOWN = 30
local stealthLastAlerted = {}
local stealthPopupFrame = nil
local stealthPopupTimer = nil

local function CreateStealthPopupFrame()
    if stealthPopupFrame then return stealthPopupFrame end

    local frame = CreateFrame("Frame", "BPP_StealthPopupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(260, 50)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -340)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "StealthPopup", true)
    end

    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.85)
    frame:SetBackdropBorderColor(0.6, 0.2, 0.9)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetTextColor(0.75, 0.4, 1.0)
    frame.text = text

    frame:Hide()
    stealthPopupFrame = frame
    return frame
end

function BPP_CheckStealthAlert(name)
    if not BPP_DB or BPP_DB.StealthAlertsEnabled == false or not name or name == "" then return end

    local infoKey = BPP_GetInfoKeyFromName(name)
    if BPP_IsKOSIgnored(infoKey) then return end

    local now = time()
    if stealthLastAlerted[infoKey] and now - stealthLastAlerted[infoKey] < STEALTH_ALERT_COOLDOWN then
        return
    end
    stealthLastAlerted[infoKey] = now

    local frame = CreateStealthPopupFrame()
    if stealthPopupTimer then
        stealthPopupTimer:Cancel()
        stealthPopupTimer = nil
    end

    frame.text:SetText(name .. " went into stealth nearby!")
    frame:Show()
    frame:SetAlpha(1)

    if BPP_FrameManager then
        BPP_FrameManager:BringToFront("StealthPopup")
    end

    PlaySound(11466) -- short, distinct from the KOS raid-warning sound

    stealthPopupTimer = C_Timer.NewTimer(4, function()
        UIFrameFade(frame, { mode = "OUT", timeToFade = 1, finishedFunc = function() frame:Hide() end })
        stealthPopupTimer = nil
    end)
end

local function PruneNearbyPlayers()
    local now = time()
    local changed = false
    local expirySeconds = GetNearbyExpirySeconds()
    for infoKey, data in pairs(nearbyPlayers) do
        if now - data.lastSeen > expirySeconds then
            nearbyPlayers[infoKey] = nil
            changed = true
        end
    end
    if changed and nearbyPanelFrame and nearbyPanelFrame:IsShown() then
        BPP_RefreshNearbyPanel()
    end
end

-- ============================================================
-- Right-click context menu
-- ============================================================

local rowContextMenu = CreateFrame("Frame", "BPP_NearbyRowContextMenu", UIParent, "UIDropDownMenuTemplate")

local function InitRowContextMenu(self, level)
    local infoKey = rowContextMenu.targetInfoKey
    local displayName = rowContextMenu.targetName
    if not infoKey then return end

    local info = UIDropDownMenu_CreateInfo()
    info.isTitle = true
    info.text = displayName
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    local isKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[infoKey] ~= nil
    info = UIDropDownMenu_CreateInfo()
    info.text = isKOS and "Remove from Kill On Sight" or "Add to Kill On Sight"
    info.notCheckable = true
    info.func = function()
        if isKOS then
            BPP_RemoveKOSPlayer(displayName)
        else
            BPP_AddKOSPlayer(displayName)
        end
        BPP_RefreshNearbyPanel()
        if BPP_RefreshKOSListFrame then BPP_RefreshKOSListFrame() end
    end
    UIDropDownMenu_AddButton(info, level)

    local isIgnored = BPP_IsKOSIgnored(infoKey)
    info = UIDropDownMenu_CreateInfo()
    info.text = isIgnored and "Un-ignore" or "Ignore"
    info.notCheckable = true
    info.func = function()
        if isIgnored then
            BPP_RemoveKOSIgnore(displayName)
        else
            BPP_AddKOSIgnore(displayName)
        end
        BPP_RefreshNearbyPanel()
        if BPP_RefreshKOSListFrame then BPP_RefreshKOSListFrame() end
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Remove from Nearby List"
    info.notCheckable = true
    info.func = function()
        nearbyPlayers[infoKey] = nil
        BPP_RefreshNearbyPanel()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Cancel"
    info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
end

UIDropDownMenu_Initialize(rowContextMenu, InitRowContextMenu, "MENU")

local function ShowRowContextMenu(infoKey, displayName, anchor)
    rowContextMenu.targetInfoKey = infoKey
    rowContextMenu.targetName = displayName
    ToggleDropDownMenu(1, nil, rowContextMenu, anchor, 0, 0)
end

-- ============================================================
-- Panel UI
-- ============================================================

local function SaveNearbyPanelPosition(frame)
    local point, _, relPoint, x, y = frame:GetPoint()
    BPP_DB.NearbyPanelPosition = { point = point, relPoint = relPoint, x = x, y = y }
end

local function CreateNearbyPanelFrame()
    if nearbyPanelFrame then return nearbyPanelFrame end

    local frame = CreateFrame("Frame", "BPP_NearbyPanelFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(190, 260)

    local pos = BPP_DB and BPP_DB.NearbyPanelPosition
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -230)
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveNearbyPanelPosition(self)
    end)
    frame:SetClampedToScreen(true)

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "NearbyPanel")
    end

    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.75)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -6)
    title:SetText("Nearby Enemies")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(18, 18)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        BPP_DB.NearbyPanelShown = false
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "BPP_NearbyPanelScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -24)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 6)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)
    frame.content = content

    nearbyPanelFrame = frame
    return frame
end

local CLASS_ROW_COLORS = {
    Warrior = { 0.78, 0.61, 0.43 }, Paladin = { 0.96, 0.55, 0.73 }, Hunter = { 0.67, 0.83, 0.45 },
    Rogue = { 1.0, 0.96, 0.41 }, Priest = { 1.0, 1.0, 1.0 }, Shaman = { 0.0, 0.44, 0.87 },
    Mage = { 0.41, 0.8, 0.94 }, Warlock = { 0.58, 0.51, 0.79 }, Druid = { 1.0, 0.49, 0.04 },
}

local function CreateNearbyRow(content, rowY, infoKey, data)
    local isKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[infoKey] ~= nil
    local isIgnored = BPP_IsKOSIgnored(infoKey)

    local row = CreateFrame("Button", nil, content)
    row:SetSize(160, 16)
    row:SetPoint("TOPLEFT", 2, rowY)
    row:RegisterForClicks("RightButtonUp")
    row:SetScript("OnClick", function()
        ShowRowContextMenu(infoKey, data.name, row)
    end)

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", row, "LEFT", 2, 0)
    text:SetWidth(158)
    text:SetJustifyH("LEFT")
    local label = data.name .. (data.level and (" (" .. data.level .. ")") or "")
    text:SetText(label)

    if isKOS then
        text:SetTextColor(1, 0.2, 0.2)
    elseif isIgnored then
        text:SetTextColor(0.5, 0.5, 0.5)
    else
        local color = (BPP_DB.NearbyPanelClassColors ~= false) and data.class and CLASS_ROW_COLORS[data.class]
        if color then
            text:SetTextColor(color[1], color[2], color[3])
        else
            text:SetTextColor(1, 1, 1)
        end
    end

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.name, 1, 1, 1)
        if data.guild and data.guild ~= "" then
            GameTooltip:AddLine("<" .. data.guild .. ">", 1, 0.82, 0)
        end
        if data.class then
            GameTooltip:AddLine((data.race or "") .. " " .. data.class, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine("Last seen: " .. date("%H:%M:%S", data.lastSeen), 0.6, 0.6, 0.6)
        local wins, losses = GetWinLossAgainstPlayer(infoKey)
        if wins > 0 or losses > 0 then
            GameTooltip:AddLine("Wins: " .. wins .. "  Losses: " .. losses, 0.6, 0.9, 0.6)
        end
        if isKOS then GameTooltip:AddLine("Kill On Sight", 1, 0.2, 0.2) end
        if isIgnored then GameTooltip:AddLine("Ignored", 0.6, 0.6, 0.6) end
        GameTooltip:AddLine("Right-click for options", 0.4, 0.7, 1)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function BPP_RefreshNearbyPanel()
    local frame = CreateNearbyPanelFrame()
    local content = frame.content

    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local entries = {}
    for infoKey, data in pairs(nearbyPlayers) do
        table.insert(entries, { key = infoKey, data = data })
    end

    table.sort(entries, function(a, b)
        local aKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[a.key] ~= nil
        local bKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[b.key] ~= nil
        if aKOS ~= bKOS then return aKOS end
        return a.data.lastSeen > b.data.lastSeen
    end)

    if #entries == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        emptyText:SetPoint("TOPLEFT", 4, -4)
        emptyText:SetWidth(158)
        emptyText:SetJustifyH("LEFT")
        emptyText:SetWordWrap(true)
        emptyText:SetText("No enemies detected yet.")
        content:SetHeight(40)
        return
    end

    local rowY = -4
    for _, entry in ipairs(entries) do
        CreateNearbyRow(content, rowY, entry.key, entry.data)
        rowY = rowY - 16
    end

    content:SetHeight(math.max(-rowY + 10, 10))
end

function BPP_ShowNearbyPanel()
    local frame = CreateNearbyPanelFrame()
    BPP_RefreshNearbyPanel()
    frame:Show()
    BPP_DB.NearbyPanelShown = true

    if not nearbyPruneTicker then
        nearbyPruneTicker = C_Timer.NewTicker(NEARBY_PRUNE_INTERVAL, PruneNearbyPlayers)
    end
end

function BPP_HideNearbyPanel()
    if nearbyPanelFrame then
        nearbyPanelFrame:Hide()
    end
    BPP_DB.NearbyPanelShown = false
end

function BPP_ToggleNearbyPanel()
    if nearbyPanelFrame and nearbyPanelFrame:IsShown() then
        BPP_HideNearbyPanel()
    else
        BPP_ShowNearbyPanel()
    end
end
