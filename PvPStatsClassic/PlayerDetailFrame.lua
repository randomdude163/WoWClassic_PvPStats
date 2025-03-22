PSC_PlayerDetailFrame = nil
local DETAIL_FRAME_WIDTH = 800
local DETAIL_FRAME_HEIGHT = 550

local function FormatTimestamp(timestamp)
    if not timestamp then return "Unknown" end

    -- If timestamp is already a string, try to return it as-is
    if type(timestamp) == "string" then
        return timestamp
    end

    -- If timestamp is 0 or invalid
    if timestamp == 0 or type(timestamp) ~= "number" then
        return "Unknown"
    end

    -- Process numeric timestamp
    local dateInfo = date("*t", timestamp)
    if not dateInfo or not dateInfo.day then
        return "Invalid date"
    end

    return string.format("%02d/%02d/%02d %02d:%02d:%02d",
        dateInfo.day, dateInfo.month, dateInfo.year % 100,
        dateInfo.hour, dateInfo.min, dateInfo.sec)
end

local function CreateSection(parent, title, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 15, yOffset)
    header:SetText(title)
    header:SetTextColor(1, 0.82, 0)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, 0)
    line:SetColorTexture(1, 0.82, 0, 0.5)

    return yOffset - 25
end

local function CreateDetailRow(parent, leftText, rightText, yOffset)
    local leftLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftLabel:SetPoint("TOPLEFT", 25, yOffset)
    leftLabel:SetText(leftText)
    leftLabel:SetTextColor(1, 1, 1)

    local rightLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rightLabel:SetPoint("TOPLEFT", 200, yOffset)
    rightLabel:SetText(rightText)

    return yOffset - 20
end

local function CreateKillHistoryEntry(parent, killData, index, yOffset)
    local bgColor = index % 2 == 0 and {0.1, 0.1, 0.1, 0.3} or {0.15, 0.15, 0.15, 0.3}

    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 15, yOffset)
    bg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, 0)
    bg:SetHeight(20)
    bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    local levelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    levelText:SetPoint("TOPLEFT", 25, yOffset - 3)
    levelText:SetText(killData.level == -1 and "??" or tostring(killData.level))
    levelText:SetWidth(40)

    local rankText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rankText:SetPoint("TOPLEFT", 70, yOffset - 3)
    rankText:SetText(killData.rank and killData.rank > 0 and tostring(killData.rank) or "0")
    rankText:SetWidth(40)

    local zoneText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", 120, yOffset - 3)
    zoneText:SetText(killData.zone or "Unknown")
    zoneText:SetWidth(200)
    zoneText:SetJustifyH("LEFT") -- Explicitly set left alignment

    local killsText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killsText:SetPoint("TOPLEFT", 330, yOffset - 3)
    killsText:SetText(killData.kills and tostring(killData.kills) or "1")
    killsText:SetWidth(40)
    killsText:SetJustifyH("LEFT") -- Ensure left alignment for content

    local timeText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", 380, yOffset - 3)
    timeText:SetText(FormatTimestamp(killData.timestamp))

    return yOffset - 20
end

local function CreateDeathHistoryEntry(parent, deathData, index, yOffset)
    local bgColor = index % 2 == 0 and {0.1, 0.1, 0.1, 0.3} or {0.15, 0.15, 0.15, 0.3}

    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 15, yOffset)
    bg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, 0)
    bg:SetHeight(20)
    bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    local levelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    levelText:SetPoint("TOPLEFT", 25, yOffset - 3)
    levelText:SetText(deathData.killerLevel == -1 and "??" or tostring(deathData.killerLevel))
    levelText:SetWidth(40)

    local zoneText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", 70, yOffset - 3)
    zoneText:SetText(deathData.zone or "Unknown")
    zoneText:SetWidth(200)
    zoneText:SetJustifyH("LEFT") -- Explicitly set left alignment

    local assistText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    assistText:SetPoint("TOPLEFT", 280, yOffset - 3)

    local assistCount = deathData.assisters and #deathData.assisters or 0
    local assistDisplay = assistCount > 0 and tostring(assistCount) .. " players" or "Solo kill"
    assistText:SetText(assistDisplay)
    assistText:SetWidth(100)
    assistText:SetJustifyH("LEFT") -- Ensure left alignment for content

    local timeText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", 390, yOffset - 3)

    -- Handle different timestamp formats
    local displayTime = "Unknown"
    local timestamp = deathData.timestamp

    if type(timestamp) == "number" then
        displayTime = FormatTimestamp(timestamp)
    elseif type(timestamp) == "string" then
        -- If it's already a formatted string, just display it
        -- Check if it matches our format or convert it
        if timestamp:match("%d%d/%d%d/%d%d %d%d:%d%d:%d%d") then
            displayTime = timestamp
        else
            -- Try to extract date components if in YYYY-MM-DD HH:MM:SS format
            local year, month, day, hour, min, sec = timestamp:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
            if year and month and day and hour and min and sec then
                displayTime = string.format("%02d/%02d/%02d %02d:%02d:%02d",
                    tonumber(day), tonumber(month), tonumber(year) % 100,
                    tonumber(hour), tonumber(min), tonumber(sec))
            else
                displayTime = timestamp
            end
        end
    end

    timeText:SetText(displayTime)

    return yOffset - 20
end

local function CleanupPlayerDetailFrame(content)
    local children = {content:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
        child:SetParent(nil)
    end

    local regions = {content:GetRegions()}
    for _, region in pairs(regions) do
        region:Hide()
        region:ClearAllPoints()
        region:SetParent(nil)
    end

    collectgarbage("collect")
end

function PSC_ShowPlayerDetailFrame(playerName)
    if not playerName then return end

    -- Find player entry
    local entries = PSC_FilterAndSortEntries()
    local playerEntry = nil

    for _, entry in ipairs(entries) do
        if entry.name == playerName then
            playerEntry = entry
            break
        end
    end

    if not playerEntry then
        print("Could not find detailed information for player:", playerName)
        return
    end

    -- Create or reuse frame
    if PSC_PlayerDetailFrame then
        CleanupPlayerDetailFrame(PSC_PlayerDetailFrame.content)
    else
        PSC_PlayerDetailFrame = CreateFrame("Frame", "PSC_PlayerDetailFrame", UIParent, "BasicFrameTemplateWithInset")
        PSC_PlayerDetailFrame:SetSize(DETAIL_FRAME_WIDTH, DETAIL_FRAME_HEIGHT)
        PSC_PlayerDetailFrame:SetPoint("CENTER")
        PSC_PlayerDetailFrame:SetMovable(true)
        PSC_PlayerDetailFrame:EnableMouse(true)
        PSC_PlayerDetailFrame:RegisterForDrag("LeftButton")
        PSC_PlayerDetailFrame:SetScript("OnDragStart", PSC_PlayerDetailFrame.StartMoving)
        PSC_PlayerDetailFrame:SetScript("OnDragStop", PSC_PlayerDetailFrame.StopMovingOrSizing)

        -- Create scrollable content frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, PSC_PlayerDetailFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 12, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(DETAIL_FRAME_WIDTH - 40, DETAIL_FRAME_HEIGHT * 3)
        scrollFrame:SetScrollChild(content)

        PSC_PlayerDetailFrame.content = content
        table.insert(UISpecialFrames, "PSC_PlayerDetailFrame")
    end

    local content = PSC_PlayerDetailFrame.content
    local titleText = playerName .. " - Player Details"
    PSC_PlayerDetailFrame.TitleText:SetText(titleText)
    PSC_PlayerDetailFrame:Show()

    -- Get player info from cache
    local playerInfo = PSC_DB.PlayerInfoCache[playerName] or {}

    -- Player summary section
    local yOffset = 0
    yOffset = CreateSection(content, "Player Information", yOffset)

    -- Replace individual info rows with a single clean line
    local playerClass = playerEntry.class or "Unknown"
    local playerRace = playerEntry.race or "Unknown"
    local playerGender = playerEntry.gender or "Unknown"
    local playerLevel = playerEntry.levelDisplay == -1 and "??" or tostring(playerEntry.levelDisplay)
    local playerGuild = playerEntry.guild or ""

    local guildInfo = playerGuild ~= "" and " <" .. playerGuild .. ">" or ""

    -- Create left-aligned player info that matches the other detail rows
    local playerLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", 25, yOffset)
    playerLabel:SetText("Player:")
    playerLabel:SetTextColor(1, 1, 1) -- White color

    -- Create player info with class color
    local infoText = string.format("%s Level %s %s %s %s%s",
        playerName, playerLevel, playerGender, playerRace, playerClass, guildInfo)

    local playerInfoLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerInfoLabel:SetPoint("TOPLEFT", 200, yOffset) -- Match the alignment of other detail rows
    playerInfoLabel:SetText(infoText)

    -- Apply class color to the player info text
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass:upper()] then
        local color = RAID_CLASS_COLORS[playerClass:upper()]
        playerInfoLabel:SetTextColor(color.r, color.g, color.b)
    end

    yOffset = yOffset - 25

    -- Continue with other player stats
    yOffset = CreateDetailRow(content, "Rank:", playerEntry.rank and playerEntry.rank > 0 and tostring(playerEntry.rank) or "0", yOffset)
    yOffset = CreateDetailRow(content, "Total Kills:", tostring(playerEntry.kills), yOffset)
    yOffset = CreateDetailRow(content, "Deaths by player:", tostring(playerEntry.deaths), yOffset)
    yOffset = CreateDetailRow(content, "K/D Ratio:", string.format("%.2f", playerEntry.deaths > 0 and playerEntry.kills / playerEntry.deaths or playerEntry.kills), yOffset)

    -- Kill history
    yOffset = yOffset - 20
    yOffset = CreateSection(content, "Kill History", yOffset)

    -- Kill history header
    local headerBg = content:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", 15, yOffset)
    headerBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
    headerBg:SetHeight(20)
    headerBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local levelHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelHeader:SetPoint("TOPLEFT", 25, yOffset - 3)
    levelHeader:SetText("Level")
    levelHeader:SetTextColor(1, 0.82, 0)

    local rankHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rankHeader:SetPoint("TOPLEFT", 70, yOffset - 3)
    rankHeader:SetText("Rank")
    rankHeader:SetTextColor(1, 0.82, 0)

    local zoneHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneHeader:SetPoint("TOPLEFT", 120, yOffset - 3)
    zoneHeader:SetText("Zone")
    zoneHeader:SetTextColor(1, 0.82, 0)
    zoneHeader:SetWidth(200)
    zoneHeader:SetJustifyH("LEFT") -- Explicitly set left alignment

    local killsHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killsHeader:SetPoint("TOPLEFT", 330, yOffset - 3)
    killsHeader:SetText("Kills")
    killsHeader:SetTextColor(1, 0.82, 0)
    killsHeader:SetWidth(40)
    killsHeader:SetJustifyH("LEFT") -- Set left alignment for header

    local timeHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeHeader:SetPoint("TOPLEFT", 380, yOffset - 3)
    timeHeader:SetText("Time")
    timeHeader:SetTextColor(1, 0.82, 0)

    yOffset = yOffset - 20

    -- Kill history entries
    if playerEntry.killHistory and #playerEntry.killHistory > 0 then
        -- Sort by level descending, then by timestamp descending as a secondary sort
        table.sort(playerEntry.killHistory, function(a, b)
            local levelA = tonumber(a.level) or -1
            local levelB = tonumber(b.level) or -1

            if levelA == levelB then
                -- If levels are the same, sort by timestamp (most recent first)
                return (a.timestamp or 0) > (b.timestamp or 0)
            else
                -- Otherwise sort by level descending
                return levelA > levelB
            end
        end)

        for i, killData in ipairs(playerEntry.killHistory) do
            yOffset = CreateKillHistoryEntry(content, killData, i, yOffset)
        end
    else
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("TOPLEFT", 25, yOffset - 10)
        noDataText:SetText("No detailed kill history available")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 30
    end

    -- Death history
    yOffset = yOffset - 20
    yOffset = CreateSection(content, "Death History", yOffset)

    -- Death history header
    local deathHeaderBg = content:CreateTexture(nil, "BACKGROUND")
    deathHeaderBg:SetPoint("TOPLEFT", 15, yOffset)
    deathHeaderBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
    deathHeaderBg:SetHeight(20)
    deathHeaderBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local killerLevelHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killerLevelHeader:SetPoint("TOPLEFT", 25, yOffset - 3)
    killerLevelHeader:SetText("Level")
    killerLevelHeader:SetTextColor(1, 0.82, 0)

    local deathZoneHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathZoneHeader:SetPoint("TOPLEFT", 70, yOffset - 3)
    deathZoneHeader:SetText("Zone")
    deathZoneHeader:SetTextColor(1, 0.82, 0)
    deathZoneHeader:SetWidth(200)
    deathZoneHeader:SetJustifyH("LEFT") -- Explicitly set left alignment

    local assistHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    assistHeader:SetPoint("TOPLEFT", 280, yOffset - 3)
    assistHeader:SetText("Assisters")
    assistHeader:SetTextColor(1, 0.82, 0)
    assistHeader:SetWidth(100)
    assistHeader:SetJustifyH("LEFT") -- Set left alignment for header

    local deathTimeHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathTimeHeader:SetPoint("TOPLEFT", 390, yOffset - 3)
    deathTimeHeader:SetText("Time")
    deathTimeHeader:SetTextColor(1, 0.82, 0)

    yOffset = yOffset - 20

    -- Death history entries
    if playerEntry.deathHistory and #playerEntry.deathHistory > 0 then
        -- Sort by killer level descending, then by timestamp descending as secondary sort
        table.sort(playerEntry.deathHistory, function(a, b)
            local levelA = tonumber(a.killerLevel) or -1
            local levelB = tonumber(b.killerLevel) or -1

            if levelA == levelB then
                -- If levels are the same, sort by timestamp (most recent first)
                local timestampA = type(a.timestamp) == "number" and a.timestamp or 0
                local timestampB = type(b.timestamp) == "number" and b.timestamp or 0
                return timestampA > timestampB
            else
                -- Otherwise sort by level descending
                return levelA > levelB
            end
        end)

        for i, deathData in ipairs(playerEntry.deathHistory) do
            yOffset = CreateDeathHistoryEntry(content, deathData, i, yOffset)
        end
    else
        local noDeathDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDeathDataText:SetPoint("TOPLEFT", 25, yOffset - 10)
        noDeathDataText:SetText("No death history available for this player")
        noDeathDataText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 30
    end

    -- Set final content height
    content:SetHeight(math.abs(yOffset) + 30)
end
