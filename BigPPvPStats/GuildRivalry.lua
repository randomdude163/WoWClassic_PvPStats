local addonName, PVPSC = ...

-- ============================================================
-- Guild rivalry: personal highlight popups + a guild-wide aggregate view,
-- tracking kills against every guild you've fought without treating any of
-- it as a formal achievement (no Achievement Frame tiles, no per-tier saved
-- records - just a lightweight highlight, the same pattern BPP_ShowKillMilestone
-- in KillMilestones.lua already uses for overall kill counts).
-- ============================================================

local GUILD_MILESTONE_TIERS = {10, 25, 50, 75, 100, 200, 300, 400, 500}
-- Tier index (into GUILD_MILESTONE_TIERS) at which a milestone also gets
-- called out in guild chat, not just a personal popup. 5 = 100 kills.
local GUILD_CALLOUT_MIN_TIER_INDEX = 5

local GUILD_MILESTONE_SUBTEXTS = {
    [10] = function(g, n) return ("First blood against %s! %d down, and word is already spreading through their guild chat."):format(g, n) end,
    [25] = function(g, n) return ("%d members of %s sent packing! Their officers are updating the roster faster than you can say 'wipe.'"):format(n, g) end,
    [50] = function(g, n) return ("%d kills against %s and counting! Their guild bank is basically a memorial fund at this point."):format(n, g) end,
    [75] = function(g, n) return ("%d members of %s eliminated! Recruitment ads now include 'must enjoy respawning.'"):format(n, g) end,
    [100] = function(g, n) return ("Triple digits! %d players from %s put down. Their guild master is considering a merger just to survive."):format(n, g) end,
    [200] = function(g, n) return ("%d members of %s dispatched! You've killed more of them than their raid team ever logged in."):format(n, g) end,
    [300] = function(g, n) return ("%d down! %s's officer chat is 90%% just your name and a skull emoji at this point."):format(n, g) end,
    [400] = function(g, n) return ("%d kills deep into %s! Their guild charter is basically a casualty list now."):format(n, g) end,
    [500] = function(g, n) return ("%d players from %s eliminated! History will remember this as the day %s stopped recruiting and started grieving."):format(n, g, g) end,
}

-- ============================================================
-- Personal highlight popup - a lightweight toast, not an achievement.
-- ============================================================

local rivalryPopupFrame = nil
local rivalryPopupTimer = nil

local function CreateRivalryPopupFrame()
    if rivalryPopupFrame then return rivalryPopupFrame end

    local frame = CreateFrame("Frame", "BPP_RivalryPopupFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetSize(320, 90)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetClampedToScreen(true)

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "RivalryPopup", true)
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
    frame:SetBackdropBorderColor(1.0, 0.5, 0.0)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48)
    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    icon:SetTexture("Interface\\AddOns\\BigPPvPStats\\img\\BigPPvPLogo.blp")
    frame.icon = icon

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -6)
    title:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    title:SetJustifyH("LEFT")
    title:SetTextColor(1.0, 0.5, 0.0)
    frame.title = title

    local subText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subText:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
    subText:SetJustifyH("LEFT")
    subText:SetJustifyV("TOP")
    subText:SetWordWrap(true)
    frame.subText = subText

    frame:Hide()
    rivalryPopupFrame = frame
    return frame
end

local POPUP_MIN_HEIGHT = 90
local POPUP_MAX_HEIGHT = 320

local function ShowRivalryPopup(title, subText)
    local frame = CreateRivalryPopupFrame()

    if rivalryPopupTimer then
        rivalryPopupTimer:Cancel()
        rivalryPopupTimer = nil
    end

    frame.title:SetText(title)
    frame.subText:SetText(subText)

    -- The digest can be several lines long, the single-milestone popup is
    -- usually one short line - resize the backdrop to fit whichever it is,
    -- instead of a fixed height that clips or leaves the text spilling
    -- outside the border.
    local contentHeight = 12 + frame.title:GetStringHeight() + 6 + frame.subText:GetStringHeight() + 16
    frame:SetHeight(math.max(POPUP_MIN_HEIGHT, math.min(contentHeight, POPUP_MAX_HEIGHT)))

    frame:Show()
    frame:SetAlpha(1)

    if BPP_FrameManager then
        BPP_FrameManager:BringToFront("RivalryPopup")
    end

    PlaySound(8473) -- "achievement gained" fanfare - distinct from the kill-streak sound packs

    rivalryPopupTimer = C_Timer.NewTimer(8, function()
        UIFrameFade(frame, { mode = "OUT", timeToFade = 1, finishedFunc = function() frame:Hide() end })
        rivalryPopupTimer = nil
    end)
end

-- ============================================================
-- Threshold tracking + guild-chat callout
-- ============================================================

-- Scans stats.guildData for newly-crossed tier thresholds and highlights
-- them (popup always, guild-chat callout for tier 100+). Persists only the
-- highest tier already announced per guild (a single number), not a full
-- achievement record. Call after every stats recalculation.
--
-- The very first time this runs for a character, any tiers already passed
-- (from kill history predating this feature) are recorded silently instead
-- of bursting out a popup/chat message per guild per tier all at once.
function BPP_CheckGuildRivalryMilestones(stats)
    if not stats or not stats.guildData or not BPP_DB or not BPP_DB.PlayerKillCounts then
        return
    end

    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]
    if not characterData then return end

    local isFirstRunForCharacter = characterData.GuildMilestoneTierAnnounced == nil
    characterData.GuildMilestoneTierAnnounced = characterData.GuildMilestoneTierAnnounced or {}
    local announced = characterData.GuildMilestoneTierAnnounced

    for guildName, kills in pairs(stats.guildData) do
        if guildName and guildName ~= "" and kills and kills > 0 then
            local announcedIndex = announced[guildName] or 0

            for i = announcedIndex + 1, #GUILD_MILESTONE_TIERS do
                local tier = GUILD_MILESTONE_TIERS[i]
                if kills < tier then
                    break
                end

                announced[guildName] = i

                if not isFirstRunForCharacter then
                    local subText = GUILD_MILESTONE_SUBTEXTS[tier](guildName, tier)
                    ShowRivalryPopup(("%d kills vs %s!"):format(tier, guildName), subText)

                    if i >= GUILD_CALLOUT_MIN_TIER_INDEX and IsInGuild() and not BPP_CurrentlyInBattleground then
                        SendChatMessage(("[BigPPvP] %s just hit %d kills against %s!"):format(UnitName("player"), tier, guildName), "GUILD")
                    end
                end
            end
        end
    end
end

-- ============================================================
-- Top-N helper + guild-wide aggregation
-- ============================================================

-- Returns a new table with only the top `limit` entries from guildData (by
-- kill count descending). Keeps broadcast payloads and the "Most Hated
-- Guilds" board bounded regardless of how many guilds a player has fought -
-- a full per-guild breakdown is never broadcast (see NetworkHandler.lua).
function BPP_GetTopGuildKills(guildData, limit)
    local entries = {}
    for guildName, kills in pairs(guildData or {}) do
        if guildName and guildName ~= "" and kills and kills > 0 then
            table.insert(entries, { name = guildName, kills = kills })
        end
    end

    table.sort(entries, function(a, b) return a.kills > b.kills end)

    local result = {}
    for i = 1, math.min(limit, #entries) do
        result[entries[i].name] = entries[i].kills
    end
    return result
end

-- Merges topGuildKills across the local player, own alts, and every
-- guildmate/group member we've received a broadcast from (live this session
-- or cached from a previous one) into "who has BIGPPvP collectively hurt the
-- most." Bounded by construction: each contributor only ever reports their
-- own top 10, so this never grows past (10 x number of known contributors)
-- regardless of how many total rival guilds exist.
function BPP_GetAggregatedGuildRivalryData()
    local totals = {}
    local contributorCount = 0

    if PVPSC.Network then
        local leaderboardData = PVPSC.Network:GetAllLeaderboardData(true)
        for _, entry in ipairs(leaderboardData) do
            if entry.topGuildKills and next(entry.topGuildKills) then
                contributorCount = contributorCount + 1
                for guildName, kills in pairs(entry.topGuildKills) do
                    totals[guildName] = (totals[guildName] or 0) + kills
                end
            end
        end
    end

    return totals, contributorCount
end

-- ============================================================
-- "Most Hated Guilds" board
-- ============================================================

local mostHatedFrame = nil

local function CreateMostHatedFrame()
    if mostHatedFrame then return mostHatedFrame end

    local frame = CreateFrame("Frame", "BPP_MostHatedFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(360, 420)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame.TitleText:SetText("Most Hated Guilds")
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    tinsert(UISpecialFrames, "BPP_MostHatedFrame")

    if BPP_FrameManager then
        BPP_FrameManager:RegisterFrame(frame, "MostHatedGuilds")
    end

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -30)
    hint:SetPoint("RIGHT", frame, "RIGHT", -85, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)
    hint:SetText("Combined kills across every online guild/group member running the addon. Each contributes their own top 10 rival guilds.")

    local digestButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    digestButton:SetSize(90, 22)
    digestButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -28)
    digestButton:SetText("This Week")
    digestButton:SetScript("OnClick", function()
        BPP_ShowRivalryDigest()
    end)
    digestButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Weekly Digest", 1, 0.82, 0)
        GameTooltip:AddLine("Show your own rival guild kills from the past 7 days.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    digestButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local scrollFrame = CreateFrame("ScrollFrame", "BPP_MostHatedScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 15)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)

    frame.content = content
    mostHatedFrame = frame
    return frame
end

local function RefreshMostHatedFrame()
    local frame = CreateMostHatedFrame()
    local content = frame.content

    for _, child in ipairs({ content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local totals, contributorCount = BPP_GetAggregatedGuildRivalryData()

    local entries = {}
    for guildName, kills in pairs(totals) do
        table.insert(entries, { name = guildName, kills = kills })
    end
    table.sort(entries, function(a, b) return a.kills > b.kills end)

    if #entries == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        emptyText:SetPoint("TOPLEFT", 5, -5)
        emptyText:SetWidth(280)
        emptyText:SetJustifyH("LEFT")
        emptyText:SetWordWrap(true)
        emptyText:SetText("No rival guild data yet. Get some kills, or try /bpp sync to pull data from nearby guild/group members.")
        content:SetHeight(60)
        return
    end

    for i, entry in ipairs(entries) do
        local rowY = -5 - ((i - 1) * 22)

        local rankText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rankText:SetPoint("TOPLEFT", 5, rowY)
        rankText:SetWidth(25)
        rankText:SetJustifyH("LEFT")
        rankText:SetText("#" .. i)
        if i == 1 then
            rankText:SetTextColor(1.0, 0.82, 0)
        elseif i <= 3 then
            rankText:SetTextColor(0.9, 0.5, 0.2)
        end

        local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("TOPLEFT", 35, rowY)
        nameText:SetWidth(200)
        nameText:SetJustifyH("LEFT")
        nameText:SetText(entry.name)

        local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        killsText:SetPoint("TOPLEFT", 240, rowY)
        killsText:SetWidth(70)
        killsText:SetJustifyH("RIGHT")
        killsText:SetText(tostring(entry.kills))
    end

    local footerY = -5 - (#entries * 22) - 10
    local footerText = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    footerText:SetPoint("TOPLEFT", 5, footerY)
    footerText:SetText("Based on data from " .. contributorCount .. " known contributor(s).")

    content:SetHeight(math.max(-footerY + 20, 10))
end

function BPP_ShowMostHatedGuildsFrame()
    RefreshMostHatedFrame()
    mostHatedFrame:Show()
end

-- ============================================================
-- Weekly rivalry digest
-- ============================================================

local function CalculateGuildKillsSince(characterData, sinceTimestamp)
    local result = {}
    if not characterData or not characterData.Kills then return result end

    for nameWithLevel, killData in pairs(characterData.Kills) do
        if killData.killLocations then
            local colonIndex = string.find(nameWithLevel, ":", 1, true)
            local nameWithoutLevel = colonIndex and string.sub(nameWithLevel, 1, colonIndex - 1) or nameWithLevel

            local infoKey = BPP_NormalizePlayerName(nameWithoutLevel)
            local info = infoKey and BPP_DB.PlayerInfoCache[infoKey]
            local guild = info and info.guild

            if guild and guild ~= "" then
                local countInWindow = 0
                for _, loc in ipairs(killData.killLocations) do
                    if loc.timestamp and loc.timestamp >= sinceTimestamp then
                        countInWindow = countInWindow + 1
                    end
                end
                if countInWindow > 0 then
                    result[guild] = (result[guild] or 0) + countInWindow
                end
            end
        end
    end

    return result
end

-- Shows a summary of rival-guild kills in the given window (default: the
-- last 7 days) as a rivalry popup. Available on-demand via /bpp rivals digest.
function BPP_ShowRivalryDigest(sinceTimestamp)
    if not BPP_DB or not BPP_DB.PlayerKillCounts then return end
    local characterData = BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()]
    if not characterData then return end

    sinceTimestamp = sinceTimestamp or (time() - 7 * 24 * 3600)
    local guildKills = CalculateGuildKillsSince(characterData, sinceTimestamp)

    local entries = {}
    for guildName, kills in pairs(guildKills) do
        table.insert(entries, { name = guildName, kills = kills })
    end
    table.sort(entries, function(a, b) return a.kills > b.kills end)

    if #entries == 0 then
        BPP_Print("[BigPPvP] No rival guild kills to report for the past week.")
        return
    end

    local lines = {}
    for i = 1, math.min(#entries, 5) do
        table.insert(lines, entries[i].kills .. " vs " .. entries[i].name)
    end

    ShowRivalryPopup("Weekly Rivalry Report", table.concat(lines, "\n"))
end

-- Shows the digest automatically at most once per real week. Call at login.
function BPP_ShowWeeklyRivalryDigestIfDue()
    if not BPP_DB or not BPP_DB.PlayerKillCounts then return end
    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]
    if not characterData then return end

    local now = time()
    local lastShown = characterData.LastRivalryDigestShown or 0
    if now - lastShown < 7 * 24 * 3600 then
        return
    end

    characterData.LastRivalryDigestShown = now
    BPP_ShowRivalryDigest(now - 7 * 24 * 3600)
end
