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
    BPP_DB.KOSIgnored = BPP_DB.KOSIgnored or {}
    BPP_DB.DisabledZones = BPP_DB.DisabledZones or {}
end

-- ============================================================
-- Zone exclusions - suppresses all detection (Kill On Sight, Stealth
-- alerts, and the Nearby panel) while in a listed zone. Mirrors the Spy
-- addon's per-zone disable list, which targets neutral hub towns where
-- both factions mingle constantly (not faction-exclusive capitals, which
-- are sanctuaries the opposing faction can't normally even enter).
-- ============================================================

-- Exposed for ConfigUI.lua to build one checkbox per preset zone against.
BPP_PRESET_DISABLE_ZONES = {
    "Booty Bay", "Everlook", "Gadgetzan", "Ratchet",
    "The Salty Sailor Tavern", "Cenarion Hold", "Shattrath City", "Area 52",
}

function BPP_AddDisabledZone(zoneName)
    if not zoneName or strtrim(zoneName) == "" then return false end
    EnsureKOSTables()
    BPP_DB.DisabledZones[strtrim(zoneName)] = true
    return true
end

function BPP_RemoveDisabledZone(zoneName)
    if not zoneName or strtrim(zoneName) == "" then return false end
    EnsureKOSTables()
    zoneName = strtrim(zoneName)
    if not BPP_DB.DisabledZones[zoneName] then return false end
    BPP_DB.DisabledZones[zoneName] = nil
    return true
end

function BPP_GetDisabledZoneList()
    EnsureKOSTables()
    local zones = {}
    for zoneName in pairs(BPP_DB.DisabledZones) do
        table.insert(zones, zoneName)
    end
    table.sort(zones)
    return zones
end

-- True if detection should be suppressed in the player's current zone.
-- Preset zones (the checkboxes in Settings) and custom zones (/bpp zone
-- disable) both just live as entries in the same DisabledZones table.
function BPP_IsZoneDetectionDisabled()
    if not BPP_DB then return false end
    local zone = BPP_GetCurrentZoneName and BPP_GetCurrentZoneName()
    if not zone then return false end

    if BPP_DB.DisabledZones and BPP_DB.DisabledZones[zone] then
        return true
    end

    return false
end

-- True if detection should be suppressed given the player's current
-- instance/zone-PvP-type/PvP-flag status. Mirrors Spy's ZoneChanged branching
-- exactly: dungeons/raids are always excluded (unconditionally, same as
-- Spy - there's nothing to detect there), battlegrounds/arenas are
-- conditional on their own toggles, and outside any instance sanctuary/
-- world-PvP-zone/unflagged are each conditional on their own toggle, checked
-- in that priority order so being in a forced-PvP zone never also trips the
-- "unflagged" check.
function BPP_IsScopeDetectionDisabled()
    if not BPP_DB then return false end

    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "party" or instanceType == "raid" then
            return true
        end
        if BPP_DB.DisableInBattlegrounds and instanceType == "pvp" then
            return true
        end
        if BPP_DB.DisableInArenas and instanceType == "arena" then
            return true
        end
        return false
    end

    local pvpType = GetZonePVPInfo()
    if pvpType == "sanctuary" then
        return BPP_DB.DisableInSanctuaries == true
    elseif pvpType == "combat" then
        return BPP_DB.DisableInWorldPvPZones == true
    elseif BPP_DB.DisableWhenPvPUnflagged and not UnitIsPVP("player") then
        return true
    end

    return false
end

-- Removes Kill On Sight / Ignore entries not seen in BPP_DB.KOSPurgeDays
-- days (0 = never purge, the default). Call once per login.
function BPP_PurgeStaleKOSEntries()
    if not BPP_DB or not BPP_DB.KOSPurgeDays or BPP_DB.KOSPurgeDays <= 0 then
        return 0
    end
    EnsureKOSTables()

    local cutoff = time() - (BPP_DB.KOSPurgeDays * 86400)
    local purged = 0

    for infoKey, entry in pairs(BPP_DB.KOSPlayers) do
        local lastSeen = entry.lastSeen or entry.addedAt or 0
        if lastSeen < cutoff then
            BPP_DB.KOSPlayers[infoKey] = nil
            purged = purged + 1
        end
    end

    for infoKey, entry in pairs(BPP_DB.KOSIgnored) do
        local addedAt = entry.addedAt or 0
        if addedAt < cutoff then
            BPP_DB.KOSIgnored[infoKey] = nil
            purged = purged + 1
        end
    end

    return purged
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
        lastSeen = time(),
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
-- Ignore list - suppresses KOS alerts (personal and guild-aggregated) for a
-- specific player, without touching the Nearby panel listing itself. Mirrors
-- the Spy addon's Ignore List.
-- ============================================================

function BPP_AddKOSIgnore(name)
    if not name or strtrim(name) == "" then return false end
    EnsureKOSTables()
    local infoKey = BPP_GetInfoKeyFromName(strtrim(name))
    BPP_DB.KOSIgnored[infoKey] = { addedAt = time() }
    return true, infoKey
end

function BPP_RemoveKOSIgnore(name)
    if not name or strtrim(name) == "" then return false end
    EnsureKOSTables()
    local infoKey = BPP_GetInfoKeyFromName(strtrim(name))
    if not BPP_DB.KOSIgnored[infoKey] then return false end
    BPP_DB.KOSIgnored[infoKey] = nil
    return true
end

function BPP_IsKOSIgnored(infoKey)
    if not BPP_DB or not BPP_DB.KOSIgnored or not infoKey then return false end
    return BPP_DB.KOSIgnored[infoKey] ~= nil
end

-- ============================================================
-- Import from Spy - Spy and this addon can run side by side (see
-- TESTING.md), so if Spy is currently loaded on this character its
-- SavedVariables tables (SpyPerCharDB.KOSData/IgnoreData, both realm-less
-- player-name sets) are already sitting in memory as globals. Reads them
-- directly instead of asking the player to copy/paste anything.
-- ============================================================

function BPP_ImportFromSpy()
    if not SpyPerCharDB or not SpyPerCharDB.KOSData then
        return false, "Spy isn't installed and loaded on this character - couldn't find its saved data."
    end
    EnsureKOSTables()

    local importedPlayers, skippedPlayers = 0, 0
    for name, addedAt in pairs(SpyPerCharDB.KOSData) do
        if type(name) == "string" and name ~= "" then
            local infoKey = BPP_GetInfoKeyFromName(name)
            if BPP_DB.KOSPlayers[infoKey] then
                skippedPlayers = skippedPlayers + 1
            else
                local spyPlayerData = SpyPerCharDB.PlayerData and SpyPerCharDB.PlayerData[name]
                BPP_DB.KOSPlayers[infoKey] = {
                    name = name,
                    reason = spyPlayerData and spyPlayerData.reason or nil,
                    addedAt = type(addedAt) == "number" and addedAt or time(),
                    lastSeen = time(),
                }
                importedPlayers = importedPlayers + 1
            end
        end
    end

    local importedIgnores, skippedIgnores = 0, 0
    if SpyPerCharDB.IgnoreData then
        for name in pairs(SpyPerCharDB.IgnoreData) do
            if type(name) == "string" and name ~= "" then
                local infoKey = BPP_GetInfoKeyFromName(name)
                if BPP_DB.KOSIgnored[infoKey] then
                    skippedIgnores = skippedIgnores + 1
                else
                    BPP_DB.KOSIgnored[infoKey] = { addedAt = time() }
                    importedIgnores = importedIgnores + 1
                end
            end
        end
    end

    return true, importedPlayers, skippedPlayers, importedIgnores, skippedIgnores
end

-- ============================================================
-- Guild-wide aggregation - every online guildmate/group member running the
-- addon broadcasts their own personal KOS watchlists (bounded to the most
-- recently added entries, see BPP_GetKOSBroadcastData) alongside their other
-- stats. Detection checks this aggregate too, so a guildmate marking someone
-- KOS alerts the whole roster - without a shared, mutually-editable list.
-- Recomputed at most once every 10 seconds; this is called from the hot
-- target/mouseover detection path, so it must stay cheap.
-- ============================================================

local KOS_BROADCAST_LIMIT = 25
local AGGREGATE_KOS_CACHE_TTL = 10
local aggregatedKOSCache = { players = {}, guilds = {}, computedAt = 0 }

-- Returns (kosPlayers, kosGuilds): name/guild -> addedAt (numeric, so it fits
-- the existing compact broadcast serializer), capped to the most recent N.
function BPP_GetKOSBroadcastData()
    EnsureKOSTables()

    local function BoundedByRecency(source)
        local entries = {}
        for key, entry in pairs(source) do
            table.insert(entries, { key = key, addedAt = entry.addedAt or 0 })
        end
        table.sort(entries, function(a, b) return a.addedAt > b.addedAt end)

        local result = {}
        for i = 1, math.min(KOS_BROADCAST_LIMIT, #entries) do
            result[entries[i].key] = entries[i].addedAt
        end
        return result
    end

    if BPP_DB.KOSShareEnabled == false then
        return {}, {}
    end

    return BoundedByRecency(BPP_DB.KOSPlayers), BoundedByRecency(BPP_DB.KOSGuilds)
end

local function GetAggregatedKOSData()
    local now = time()
    if now - aggregatedKOSCache.computedAt < AGGREGATE_KOS_CACHE_TTL then
        return aggregatedKOSCache.players, aggregatedKOSCache.guilds
    end

    local players, guilds = {}, {}
    if PVPSC.Network then
        local leaderboardData = PVPSC.Network:GetAllLeaderboardData(true)
        for _, entry in ipairs(leaderboardData) do
            local reporter = entry.playerName
            if entry.kosPlayers then
                for infoKey in pairs(entry.kosPlayers) do
                    players[infoKey] = players[infoKey] or {}
                    table.insert(players[infoKey], reporter)
                end
            end
            if entry.kosGuilds then
                for guildName in pairs(entry.kosGuilds) do
                    guilds[guildName] = guilds[guildName] or {}
                    table.insert(guilds[guildName], reporter)
                end
            end
        end
    end

    aggregatedKOSCache = { players = players, guilds = guilds, computedAt = now }
    return players, guilds
end

-- Exposed for NearbyList.lua: whether a detection is a Kill On Sight match
-- (personal or guild-wide aggregated), so the generic "new nearby sighting"
-- sound can stay quiet when the KOS alert (with its own distinct sound) is
-- about to fire for the very same detection instead of overlapping it.
function BPP_IsKOSMatch(infoKey, guildName)
    if not BPP_DB or not infoKey then return false end
    EnsureKOSTables()

    if BPP_DB.KOSPlayers[infoKey] then return true end
    if guildName and guildName ~= "" and BPP_DB.KOSGuilds[guildName] then return true end

    if BPP_DB.KOSReceiveShared ~= false then
        local aggPlayers, aggGuilds = GetAggregatedKOSData()
        if aggPlayers[infoKey] then return true end
        if guildName and guildName ~= "" and aggGuilds[guildName] then return true end
    end

    return false
end

-- ============================================================
-- Alert popup - same dynamic-height toast pattern as the trash popup in
-- GuildRivalry.lua, but red-themed and on its own timer/frame so a trash
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

-- Kill On Sight alert sound - Spy's own detected-kos.mp3, bundled directly
-- (see sounds/Spy/), not a Blizzard stock sound standing in for it.
function BPP_PlayThreatAlertSound()
    PlaySoundFile("Interface\\AddOns\\BigPPvPStats\\sounds\\Spy\\detected-kos.mp3", "Master")
end

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

    if BPP_DB.KOSAlertSoundEnabled ~= false then
        BPP_PlayThreatAlertSound()
    end

    -- Matches Spy's KOS alert timing exactly (3s held + 1s fade = 4s total
    -- on screen), not a slow linger.
    kosPopupTimer = C_Timer.NewTimer(3, function()
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

-- Joins up to 2 reporter names for a subtext line, e.g. "Reported by Foo and Bar."
local function DescribeReporters(reporters)
    if not reporters or #reporters == 0 then return nil end
    if #reporters == 1 then
        return "Reported by " .. reporters[1] .. "."
    end
    return "Reported by " .. reporters[1] .. " and " .. (#reporters - 1) .. " other(s)."
end

function BPP_CheckKillOnSight(name, guildName)
    if not BPP_DB or not name or name == "" then return end
    if BPP_DB.KOSAlertsEnabled == false then return end
    if BPP_IsZoneDetectionDisabled() then return end
    if BPP_IsScopeDetectionDisabled() then return end
    EnsureKOSTables()

    local infoKey = BPP_GetInfoKeyFromName(name)
    if BPP_IsKOSIgnored(infoKey) then return end

    local now = time()
    if kosLastAlerted[infoKey] and now - kosLastAlerted[infoKey] < KOS_ALERT_COOLDOWN then
        return
    end

    local aggPlayers, aggGuilds = {}, {}
    if BPP_DB.KOSReceiveShared ~= false then
        aggPlayers, aggGuilds = GetAggregatedKOSData()
    end

    local playerEntry = BPP_DB.KOSPlayers[infoKey]
    local displayName = infoKey:match("^([^-]+)") or name
    if playerEntry then
        playerEntry.lastSeen = now
    end
    if playerEntry or aggPlayers[infoKey] then
        kosLastAlerted[infoKey] = now
        local subText = (playerEntry and playerEntry.reason)
            or DescribeReporters(aggPlayers[infoKey])
            or "No reason logged. Kill on sight."
        ShowKOSAlert("KOS: " .. (playerEntry and playerEntry.name or displayName), subText)
        return
    end

    if guildName and guildName ~= "" then
        local guildEntry = BPP_DB.KOSGuilds[guildName]
        if guildEntry or aggGuilds[guildName] then
            kosLastAlerted[infoKey] = now
            local subText = "Member of KOS guild " .. guildName .. "."
            local extra = (guildEntry and guildEntry.reason) or DescribeReporters(aggGuilds[guildName])
            if extra then
                subText = subText .. " " .. extra
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
    hint:SetText("Get a loud alert the moment a watchlisted player, or anyone from a watchlisted guild, is targeted, moused over, or shows up on a nameplate. Right-click any name in the Nearby Enemies panel (/bpp nearby) to add/remove it here directly.")

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
    frame:Hide()
    kosListFrame = frame
    return frame
end

-- buttonConfig: { template = "remove" | "add", tooltip, onClick } or nil for no button
local function CreateKOSListRow(content, rowY, displayText, tooltipLines, buttonConfig)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", 5, rowY)
    nameText:SetWidth(220)
    nameText:SetJustifyH("LEFT")
    nameText:SetText(displayText)

    if buttonConfig then
        local button
        if buttonConfig.template == "add" then
            button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            button:SetSize(40, 20)
            button:SetText("Add")
            button:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, rowY + 2)
        else
            button = CreateFrame("Button", nil, content, "UIPanelCloseButton")
            button:SetSize(20, 20)
            button:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, rowY + 3)
        end
        button:SetScript("OnClick", buttonConfig.onClick)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(buttonConfig.tooltip or "Remove", 1, 1, 1)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    if tooltipLines and #tooltipLines > 0 then
        local hitbox = CreateFrame("Frame", nil, content)
        hitbox:SetPoint("TOPLEFT", nameText, "TOPLEFT", 0, 0)
        hitbox:SetSize(220, 18)
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

-- Renders a titled block of rows, returns the next free rowY beneath it.
local function RenderKOSSection(content, rowY, title, entries, emptyText, buttonConfigFn)
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 5, rowY)
    header:SetText(title)
    header:SetTextColor(1.0, 0.5, 0.5)
    rowY = rowY - 20

    if #entries == 0 then
        local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        empty:SetPoint("TOPLEFT", 10, rowY)
        empty:SetText(emptyText)
        rowY = rowY - 20
    else
        for _, item in ipairs(entries) do
            CreateKOSListRow(content, rowY, item.displayText, item.tooltipLines, buttonConfigFn(item))
            rowY = rowY - 22
        end
    end

    return rowY - 10
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

    local playerEntries = {}
    for infoKey, entry in pairs(BPP_DB.KOSPlayers) do
        table.insert(playerEntries, { key = infoKey, displayText = entry.name, tooltipLines = { entry.reason or "No reason logged." } })
    end
    table.sort(playerEntries, function(a, b) return a.displayText < b.displayText end)
    rowY = RenderKOSSection(content, rowY, "Players", playerEntries, "No players added yet.", function(item)
        return { template = "remove", tooltip = "Remove", onClick = function()
            BPP_RemoveKOSPlayer(item.key)
            BPP_RefreshKOSListFrame()
        end }
    end)

    local guildEntries = {}
    for guildName, entry in pairs(BPP_DB.KOSGuilds) do
        table.insert(guildEntries, { key = guildName, displayText = guildName, tooltipLines = { entry.reason or "No reason logged." } })
    end
    table.sort(guildEntries, function(a, b) return a.displayText < b.displayText end)
    rowY = RenderKOSSection(content, rowY, "Guilds", guildEntries, "No guilds added yet.", function(item)
        return { template = "remove", tooltip = "Remove", onClick = function()
            BPP_RemoveKOSGuild(item.key)
            BPP_RefreshKOSListFrame()
        end }
    end)

    local ignoredEntries = {}
    for infoKey in pairs(BPP_DB.KOSIgnored) do
        table.insert(ignoredEntries, { key = infoKey, displayText = infoKey:match("^([^-]+)") or infoKey, tooltipLines = { "Alerts are suppressed for this player." } })
    end
    table.sort(ignoredEntries, function(a, b) return a.displayText < b.displayText end)
    rowY = RenderKOSSection(content, rowY, "Ignored", ignoredEntries, "No players ignored.", function(item)
        return { template = "remove", tooltip = "Un-ignore", onClick = function()
            BPP_RemoveKOSIgnore(item.key)
            BPP_RefreshKOSListFrame()
        end }
    end)

    -- Guild-wide: players/guilds guildmates have reported, that you haven't
    -- added yourself. "Add" copies it into your own personal list; either
    -- way it already contributes to your alerts via GetAggregatedKOSData.
    local aggPlayers, aggGuilds = GetAggregatedKOSData()

    local aggPlayerEntries = {}
    for infoKey, reporters in pairs(aggPlayers) do
        if not BPP_DB.KOSPlayers[infoKey] then
            local displayName = infoKey:match("^([^-]+)") or infoKey
            table.insert(aggPlayerEntries, { key = infoKey, displayText = displayName, tooltipLines = { DescribeReporters(reporters) or "Reported by a guildmate." } })
        end
    end
    table.sort(aggPlayerEntries, function(a, b) return a.displayText < b.displayText end)
    rowY = RenderKOSSection(content, rowY, "Guild KOS - Players", aggPlayerEntries, "No guildmate-reported players.", function(item)
        return { template = "add", tooltip = "Add to my list", onClick = function()
            BPP_AddKOSPlayer(item.displayText)
            BPP_RefreshKOSListFrame()
        end }
    end)

    local aggGuildEntries = {}
    for guildName, reporters in pairs(aggGuilds) do
        if not BPP_DB.KOSGuilds[guildName] then
            table.insert(aggGuildEntries, { key = guildName, displayText = guildName, tooltipLines = { DescribeReporters(reporters) or "Reported by a guildmate." } })
        end
    end
    table.sort(aggGuildEntries, function(a, b) return a.displayText < b.displayText end)
    rowY = RenderKOSSection(content, rowY, "Guild KOS - Guilds", aggGuildEntries, "No guildmate-reported guilds.", function(item)
        return { template = "add", tooltip = "Add to my list", onClick = function()
            BPP_AddKOSGuild(item.displayText)
            BPP_RefreshKOSListFrame()
        end }
    end)

    content:SetHeight(math.max(-rowY + 10, 10))
end

function BPP_ShowKOSListFrame()
    BPP_RefreshKOSListFrame()
    kosListFrame:Show()
end

-- Fires the popup + sound directly, bypassing detection/cooldown/zone
-- checks entirely - isolates "is the alert sound broken" from "is
-- detection ever triggering it" when troubleshooting.
function BPP_TestKOSAlert()
    ShowKOSAlert("KOS: Test Alert", "This is a test of the Kill On Sight alert popup and sound.")
    BPP_Print("[BigPPvP] Test alert fired. If you saw the popup but heard nothing, it's a sound issue, not a detection issue.")
end
