local addonName, PVPSC = ...

-- ============================================================
-- Nearby Enemies panel - a small always-on-screen list of hostile players
-- detected via the same target/mouseover/nameplate hooks the rest of the
-- addon already uses (see BPP_GetAndStorePlayerInfoFromUnit in
-- DataStorage.lua). Modeled on the Spy addon's main window: right-click a
-- row to add/remove Kill On Sight or toggle Ignore.
-- ============================================================

local NEARBY_EXPIRY_DEFAULT = 600 -- entries drop off 10 minutes after last seen by default
local NEARBY_EXPIRY_NEVER = -1 -- matches Spy's "Never" RemoveUndetected option
local NEARBY_PRUNE_INTERVAL = 30

local function GetNearbyExpirySeconds()
    return (BPP_DB and BPP_DB.NearbyPanelExpirySeconds) or NEARBY_EXPIRY_DEFAULT
end

local nearbyPlayers = {} -- [infoKey] = { name, level, class, race, guild, lastSeen }
local nearbyPanelFrame = nil
local nearbyPruneTicker = nil

-- Panel cycles between these views with the title bar arrows, like Spy's
-- Nearby/Last Hour/Ignore/KOS list switcher.
local NEARBY_MODES = { "Nearby", "Last Hour", "Kill On Sight", "Ignored" }
local currentModeIndex = 1
local MAX_DISPLAYED_ROWS = 20

-- Entries are kept for a full hour regardless of the shorter "Nearby" view
-- filter below, so the Last Hour view has something to show.
local NEARBY_HARD_RETENTION_SECONDS = 3600

-- ============================================================
-- Recording + pruning
-- ============================================================

-- ============================================================
-- Live sighting sharing - when this client detects a genuinely new nearby
-- player, briefly tell online guild/party members running the addon so it
-- shows up in their Nearby panel too, not just via the periodic stats
-- broadcast. Throttled per-player so a flickering nameplate can't spam
-- chat, and one-directional (received sightings are merged locally but
-- never re-broadcast) so there's no echo loop between clients.
-- ============================================================

local SIGHTING_BROADCAST_COOLDOWN = 120
local lastSightingBroadcast = {}

local function BroadcastSighting(name, level, class, race, guildName, infoKey)
    if not BPP_DB or BPP_DB.NearbySharingEnabled == false then return end
    if not PVPSC.Network or not PVPSC.Network.SendCommMessageWithDebug then return end

    local now = time()
    if lastSightingBroadcast[infoKey] and now - lastSightingBroadcast[infoKey] < SIGHTING_BROADCAST_COOLDOWN then
        return
    end
    lastSightingBroadcast[infoKey] = now

    local payload = "SIGHT|" .. table.concat({
        name or "", tostring(level or ""), class or "", race or "", guildName or "",
    }, "\30")

    if IsInRaid() then
        PVPSC.Network:SendCommMessageWithDebug("BPP", payload, "RAID")
    elseif IsInGroup() then
        PVPSC.Network:SendCommMessageWithDebug("BPP", payload, "PARTY")
    end
    if IsInGuild() then
        PVPSC.Network:SendCommMessageWithDebug("BPP", payload, "GUILD")
    end
end

-- Called from NetworkHandler.lua when a SIGHT message is received - merges
-- it in like a local detection, but never re-broadcasts it.
function BPP_MergeSharedSighting(name, level, class, race, guildName)
    if not name or name == "" then return end
    if BPP_IsZoneDetectionDisabled and BPP_IsZoneDetectionDisabled() then return end
    local infoKey = BPP_GetInfoKeyFromName(name)

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
    elseif BPP_DB and BPP_DB.NearbyPanelAutoShow ~= false and BPP_ShowNearbyPanel then
        BPP_ShowNearbyPanel()
    end
end

function BPP_RecordNearbyPlayer(name, level, class, race, guildName, infoKey, suppressSound)
    if not name or name == "" then return end
    if BPP_IsZoneDetectionDisabled and BPP_IsZoneDetectionDisabled() then return end
    if BPP_IsScopeDetectionDisabled and BPP_IsScopeDetectionDisabled() then return end
    infoKey = infoKey or BPP_GetInfoKeyFromName(name)

    local isNewSighting = nearbyPlayers[infoKey] == nil

    nearbyPlayers[infoKey] = {
        name = name,
        level = level,
        class = class,
        race = race,
        guild = guildName,
        lastSeen = time(),
    }

    if isNewSighting then
        BroadcastSighting(name, level, class, race, guildName, infoKey)

        -- Spy's own detected-nearby.mp3 (see sounds/Spy/), for a genuinely
        -- new hostile sighting. Skipped for Kill On Sight matches and
        -- Ignored players - Kill On Sight has its own distinct sound that's
        -- about to fire right after this (see DataStorage.lua), and playing
        -- both at once would overlap them. Also skipped when the caller
        -- (the Stealth alert) already has its own distinct sound covering
        -- this same detection.
        if not suppressSound and BPP_DB and BPP_DB.NearbySoundEnabled ~= false
           and not BPP_IsKOSIgnored(infoKey)
           and not (BPP_IsKOSMatch and BPP_IsKOSMatch(infoKey, guildName)) then
            PlaySoundFile("Interface\\AddOns\\BigPPvPStats\\sounds\\Spy\\detected-nearby.mp3", "Master")
        end
    end

    if nearbyPanelFrame and nearbyPanelFrame:IsShown() then
        BPP_RefreshNearbyPanel()
    elseif BPP_DB and BPP_DB.NearbyPanelAutoShow ~= false and BPP_ShowNearbyPanel then
        BPP_ShowNearbyPanel()
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

-- Compact two-line toast matching Spy's own AlertWindow (icon + title + name
-- over a translucent tooltip-style backdrop, ~42px tall, width fit to the
-- text) instead of a large opaque block that gets in the way of the view.
local STEALTH_ICON = "Interface\\Icons\\Ability_Stealth"
local PROWL_ICON = "Interface\\Icons\\Ability_Ambush"

local function CreateStealthPopupFrame()
    if stealthPopupFrame then return stealthPopupFrame end

    local frame = CreateFrame("Frame", "BPP_StealthPopupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(220, 42)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -340)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "StealthPopup", true)
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.45)
    frame:SetBackdropBorderColor(0.6, 0.2, 1.0, 0.6)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -5)
    icon:SetTexture(STEALTH_ICON)
    frame.icon = icon

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    title:SetJustifyH("LEFT")
    title:SetTextColor(0.6, 0.2, 1.0)
    title:SetText("Stealth player detected!")
    frame.title = title

    local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    name:SetJustifyH("LEFT")
    name:SetTextColor(1, 1, 1)
    frame.name = name

    frame:Hide()
    stealthPopupFrame = frame
    return frame
end

function BPP_CheckStealthAlert(name, spellName)
    if not BPP_DB or not name or name == "" then return end
    if BPP_IsZoneDetectionDisabled and BPP_IsZoneDetectionDisabled() then return end
    if BPP_IsScopeDetectionDisabled and BPP_IsScopeDetectionDisabled() then return end

    local infoKey = BPP_GetInfoKeyFromName(name)

    -- Stealth is detected purely from the combat log (no unit token to mouse
    -- over/target), so this is the only chance to add the sighting to the
    -- Nearby list - without it, a player seen going stealthy never showed up
    -- there at all, even though they triggered an alert. Uses whatever the
    -- addon already knows about them from past target/mouseover encounters.
    local cacheInfo = BPP_DB.PlayerInfoCache and BPP_DB.PlayerInfoCache[infoKey]
    BPP_RecordNearbyPlayer(name, cacheInfo and cacheInfo.level, cacheInfo and cacheInfo.class,
        cacheInfo and cacheInfo.race, cacheInfo and cacheInfo.guild, infoKey, true)

    if BPP_DB.StealthAlertsEnabled == false then return end
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

    frame.icon:SetTexture(spellName == "Prowl" and PROWL_ICON or STEALTH_ICON)
    frame.name:SetText(name)
    frame:SetWidth(math.max(frame.title:GetStringWidth(), frame.name:GetStringWidth()) + 46)
    frame:Show()
    frame:SetAlpha(1)

    if BPP_FrameManager then
        BPP_FrameManager:BringToFront("StealthPopup")
    end

    -- Spy's own detected-stealth.mp3, bundled directly (see sounds/Spy/) -
    -- distinct from the Kill On Sight alert sound, matching Spy's own design.
    PlaySoundFile("Interface\\AddOns\\BigPPvPStats\\sounds\\Spy\\detected-stealth.mp3", "Master")

    stealthPopupTimer = C_Timer.NewTimer(4, function()
        UIFrameFade(frame, { mode = "OUT", timeToFade = 1, finishedFunc = function() frame:Hide() end })
        stealthPopupTimer = nil
    end)
end

local function PruneNearbyPlayers()
    -- "Never" means entries stick around until removed by hand, matching
    -- Spy's InactiveTimeout=-1 behavior - skip the hard 1-hour cap too.
    if GetNearbyExpirySeconds() == NEARBY_EXPIRY_NEVER then return end

    local now = time()
    local changed = false
    for infoKey, data in pairs(nearbyPlayers) do
        if now - data.lastSeen > NEARBY_HARD_RETENTION_SECONDS then
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

local TITLE_BAR_HEIGHT = 18

local function SaveNearbyPanelPosition(frame)
    local point, _, relPoint, x, y = frame:GetPoint()
    BPP_DB.NearbyPanelPosition = { point = point, relPoint = relPoint, x = x, y = y }
end

local function SaveNearbyPanelSize(frame)
    BPP_DB.NearbyPanelSize = { width = frame:GetWidth(), height = frame:GetHeight() }
end

local function CreateNearbyPanelFrame()
    if nearbyPanelFrame then return nearbyPanelFrame end

    local frame = CreateFrame("Frame", "BPP_NearbyPanelFrame", UIParent)
    local savedSize = BPP_DB and BPP_DB.NearbyPanelSize
    frame:SetSize(savedSize and savedSize.width or 200, TITLE_BAR_HEIGHT + 6)
    frame:SetResizable(true)
    if frame.SetMinResize then frame:SetMinResize(150, TITLE_BAR_HEIGHT + 6) end
    if frame.SetMaxResize then frame:SetMaxResize(450, TITLE_BAR_HEIGHT + 6 + MAX_DISPLAYED_ROWS * 17) end

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

    -- Only the title strip has a background, for text legibility - the rest
    -- of the window stays fully transparent so it doesn't block the view.
    local titleBar = frame:CreateTexture(nil, "BACKGROUND")
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(TITLE_BAR_HEIGHT)
    titleBar:SetColorTexture(0, 0, 0, 0.55)

    local leftArrow = CreateFrame("Button", nil, frame)
    leftArrow:SetSize(14, 14)
    leftArrow:SetPoint("LEFT", titleBar, "LEFT", 3, 0)
    leftArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    leftArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    leftArrow:SetScript("OnClick", function() BPP_CycleNearbyPanelMode(-1) end)

    local rightArrow = CreateFrame("Button", nil, frame)
    rightArrow:SetSize(14, 14)
    rightArrow:SetPoint("RIGHT", titleBar, "RIGHT", -20, 0)
    rightArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    rightArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    rightArrow:SetScript("OnClick", function() BPP_CycleNearbyPanelMode(1) end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    frame.title = title

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetSize(16, 16)
    closeButton:SetPoint("RIGHT", titleBar, "RIGHT", 3, 0)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        BPP_DB.NearbyPanelShown = false
    end)

    -- No scroll frame - the window itself grows/shrinks vertically to fit
    -- its rows (capped at MAX_DISPLAYED_ROWS), so nothing ever needs to
    -- scroll.
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -(TITLE_BAR_HEIGHT + 2))
    content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -(TITLE_BAR_HEIGHT + 2))
    content:SetHeight(1)
    frame.content = content

    -- Resize grip only adjusts width (useful for long names) - height is
    -- always driven by the current row count on refresh. Anchored to the
    -- frame's bottom-right corner, which is always right below the last
    -- row (not the frame's vertical middle - that put it halfway up a
    -- tall list, nowhere near the actual bottom edge).
    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(12, 12)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        frame:StartSizing("RIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveNearbyPanelSize(frame)
        BPP_RefreshNearbyPanel()
    end)

    nearbyPanelFrame = frame
    return frame
end

local CLASS_ROW_COLORS = {
    Warrior = { 0.78, 0.61, 0.43 }, Paladin = { 0.96, 0.55, 0.73 }, Hunter = { 0.67, 0.83, 0.45 },
    Rogue = { 1.0, 0.96, 0.41 }, Priest = { 1.0, 1.0, 1.0 }, Shaman = { 0.0, 0.44, 0.87 },
    Mage = { 0.41, 0.8, 0.94 }, Warlock = { 0.58, 0.51, 0.79 }, Druid = { 1.0, 0.49, 0.04 },
}

local ROW_HEIGHT = 16

-- Each row is its own small class-colored bar with the name drawn on top of
-- it (level/class on the right), rather than one big solid panel behind
-- everything - keeps the window itself fully transparent.
local function CreateNearbyRow(content, rowY, rowWidth, infoKey, data)
    local isKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[infoKey] ~= nil
    local isIgnored = BPP_IsKOSIgnored(infoKey)

    -- SecureActionButtonTemplate so left-click can target the player
    -- directly (matches Spy). Setting the secure "macrotext1" attribute is
    -- itself a protected action - skip it while in combat lockdown (the
    -- row still displays fine, it just won't target until the panel
    -- refreshes again out of combat, the same limitation Spy's own
    -- documentation calls out).
    local row = CreateFrame("Button", nil, content, "SecureActionButtonTemplate")
    row:SetSize(rowWidth, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 1, rowY)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if not InCombatLockdown() then
        row:SetAttribute("type1", "macro")
        row:SetAttribute("macrotext1", "/targetexact " .. data.name)
    end
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ShowRowContextMenu(infoKey, data.name, row)
        end
    end)

    local bar = row:CreateTexture(nil, "BACKGROUND")
    bar:SetAllPoints(row)
    bar:SetTexture("Interface\\Buttons\\WHITE8X8")

    if isKOS then
        bar:SetVertexColor(0.55, 0.1, 0.1, 0.75)
    elseif isIgnored then
        bar:SetVertexColor(0.2, 0.2, 0.2, 0.55)
    else
        local classColor = (BPP_DB.NearbyPanelClassColors ~= false) and data.class and CLASS_ROW_COLORS[data.class]
        if classColor then
            bar:SetVertexColor(classColor[1] * 0.5, classColor[2] * 0.5, classColor[3] * 0.5, 0.7)
        else
            bar:SetVertexColor(0.15, 0.15, 0.15, 0.6)
        end
    end

    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", row, "LEFT", 4, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetTextColor(1, 1, 1)
    nameText:SetText(data.name)

    local infoText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    infoText:SetJustifyH("RIGHT")
    infoText:SetTextColor(0.85, 0.85, 0.85)
    local infoLabel = data.level and tostring(data.level) or ""
    if data.class then
        infoLabel = infoLabel .. (infoLabel ~= "" and " " or "") .. data.class
    end
    infoText:SetText(infoLabel)

    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.name, 1, 1, 1)
        if data.guild and data.guild ~= "" then
            GameTooltip:AddLine("<" .. data.guild .. ">", 1, 0.82, 0)
        end
        if data.class then
            GameTooltip:AddLine((data.race or "") .. " " .. data.class, 0.8, 0.8, 0.8)
        end
        if data.reason then
            GameTooltip:AddLine(data.reason, 1, 1, 1, true)
        end
        if data.lastSeen and data.lastSeen > 0 then
            GameTooltip:AddLine((data.timeLabel or "Last seen") .. ": " .. date("%H:%M:%S", data.lastSeen), 0.6, 0.6, 0.6)
        end
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

-- Builds a uniform { key, data = { name, level, class, race, guild,
-- lastSeen, timeLabel, reason } } list for whichever mode is active, so
-- CreateNearbyRow doesn't need to know which underlying table it came from.
local function GetModeEntries(modeName)
    local entries = {}

    if modeName == "Nearby" or modeName == "Last Hour" then
        local now = time()
        -- Nearby only shows entries seen within the (configurable) short
        -- window; Last Hour shows everything still in the hour-long store.
        -- "Never" (-1) means don't filter by time at all in the Nearby view.
        local cutoff
        if modeName == "Nearby" then
            local expiry = GetNearbyExpirySeconds()
            cutoff = (expiry == NEARBY_EXPIRY_NEVER) and math.huge or expiry
        else
            cutoff = NEARBY_HARD_RETENTION_SECONDS
        end
        for infoKey, data in pairs(nearbyPlayers) do
            if now - data.lastSeen <= cutoff then
                table.insert(entries, { key = infoKey, data = data })
            end
        end
        table.sort(entries, function(a, b)
            local aKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[a.key] ~= nil
            local bKOS = BPP_DB.KOSPlayers and BPP_DB.KOSPlayers[b.key] ~= nil
            if aKOS ~= bKOS then return aKOS end
            return a.data.lastSeen > b.data.lastSeen
        end)
    elseif modeName == "Kill On Sight" then
        for infoKey, entry in pairs(BPP_DB.KOSPlayers or {}) do
            local cacheInfo = BPP_DB.PlayerInfoCache and BPP_DB.PlayerInfoCache[infoKey]
            table.insert(entries, { key = infoKey, data = {
                name = entry.name,
                level = cacheInfo and cacheInfo.level,
                class = cacheInfo and cacheInfo.class,
                race = cacheInfo and cacheInfo.race,
                guild = cacheInfo and cacheInfo.guild,
                lastSeen = entry.addedAt or 0,
                timeLabel = "Added",
                reason = entry.reason,
            } })
        end
        table.sort(entries, function(a, b) return a.data.name < b.data.name end)
    elseif modeName == "Ignored" then
        for infoKey, entry in pairs(BPP_DB.KOSIgnored or {}) do
            local cacheInfo = BPP_DB.PlayerInfoCache and BPP_DB.PlayerInfoCache[infoKey]
            table.insert(entries, { key = infoKey, data = {
                name = infoKey:match("^([^-]+)") or infoKey,
                level = cacheInfo and cacheInfo.level,
                class = cacheInfo and cacheInfo.class,
                race = cacheInfo and cacheInfo.race,
                guild = cacheInfo and cacheInfo.guild,
                lastSeen = entry.addedAt or 0,
                timeLabel = "Added",
            } })
        end
        table.sort(entries, function(a, b) return a.data.name < b.data.name end)
    end

    return entries
end

local MODE_EMPTY_TEXT = {
    ["Nearby"] = "No enemies detected yet.",
    ["Last Hour"] = "No enemies detected in the last hour.",
    ["Kill On Sight"] = "No players added yet.",
    ["Ignored"] = "No players ignored.",
}

function BPP_RefreshNearbyPanel()
    local frame = CreateNearbyPanelFrame()
    local content = frame.content

    local modeName = NEARBY_MODES[currentModeIndex]
    frame.title:SetText(modeName)

    -- GetChildren() only enumerates child FRAMES (the row buttons), not
    -- loose regions - the empty-state text is a FontString created directly
    -- on content, so it's tracked and hidden explicitly instead, or it would
    -- never get cleared and would sit behind newly-added rows forever.
    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    if content.emptyText then
        content.emptyText:Hide()
    end

    local rowWidth = math.max(content:GetWidth(), 60)

    local allEntries = GetModeEntries(modeName)
    local entries = {}
    for i = 1, math.min(#allEntries, MAX_DISPLAYED_ROWS) do
        entries[i] = allEntries[i]
    end

    if #entries == 0 then
        if not content.emptyText then
            content.emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            content.emptyText:SetPoint("TOPLEFT", 4, -4)
            content.emptyText:SetJustifyH("LEFT")
            content.emptyText:SetWordWrap(true)
        end
        content.emptyText:SetWidth(rowWidth - 8)
        content.emptyText:SetText(MODE_EMPTY_TEXT[modeName] or "Nothing here yet.")
        content.emptyText:Show()
        frame:SetHeight(TITLE_BAR_HEIGHT + 6 + 30)
        return
    end

    local rowY = -2
    for _, entry in ipairs(entries) do
        CreateNearbyRow(content, rowY, rowWidth - 2, entry.key, entry.data)
        rowY = rowY - (ROW_HEIGHT + 1)
    end

    local contentHeight = -rowY + 4
    content:SetHeight(contentHeight)
    frame:SetHeight(TITLE_BAR_HEIGHT + 2 + contentHeight + 4)
end

function BPP_CycleNearbyPanelMode(direction)
    currentModeIndex = ((currentModeIndex - 1 + direction) % #NEARBY_MODES) + 1
    BPP_RefreshNearbyPanel()
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
