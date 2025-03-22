PSC_PlayerDetailFrame = nil
local DETAIL_FRAME_WIDTH = 600
local DETAIL_FRAME_HEIGHT = 600

-- Layout constants for column positioning
PSC_COLUMN_POSITIONS = {
    LEVEL = 25,     -- Level column
    ZONE = 70,      -- Zone column
    KILLS = 230,    -- Kills/Assisters column
    TIME = 330      -- Time column
}

PSC_COLUMN_WIDTHS = {
    LEVEL = 40,     -- Level column width
    ZONE = 140,     -- Zone column width
    KILLS = 100      -- Kills/Assisters column width
}

function PSC_FormatTimestamp(timestamp)
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


local function CreateKillHistoryHeaderRow(content, yOffset)
    local headerBg = content:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", 15, yOffset)
    headerBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
    headerBg:SetHeight(20)
    headerBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local levelHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    levelHeader:SetText("Level")
    levelHeader:SetTextColor(1, 0.82, 0)

    local zoneHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zoneHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    zoneHeader:SetText("Zone")
    zoneHeader:SetTextColor(1, 0.82, 0)
    zoneHeader:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    zoneHeader:SetJustifyH("LEFT")

    local killsHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killsHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    killsHeader:SetText("Kills")
    killsHeader:SetTextColor(1, 0.82, 0)
    killsHeader:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    killsHeader:SetJustifyH("LEFT")

    local timeHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    timeHeader:SetText("Time")
    timeHeader:SetTextColor(1, 0.82, 0)

    return yOffset - 20
end

local function SortKillHistoryByTimestamp(killHistory)
    table.sort(killHistory, function(a, b)
        local timestampA = a.timestamp or 0
        local timestampB = b.timestamp or 0

        -- Primary sort by timestamp (most recent first)
        return timestampA > timestampB
    end)

    return killHistory
end

local function SortDeathHistoryByTimestamp(deathHistory)
    table.sort(deathHistory, function(a, b)
        return a.timestamp > b.timestamp
    end)

    return deathHistory
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
    rightLabel:SetPoint("TOPLEFT", 120, yOffset)
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
    levelText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    levelText:SetText(killData.level == -1 and "??" or tostring(killData.level))
    levelText:SetWidth(PSC_COLUMN_WIDTHS.LEVEL)

    local zoneText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    zoneText:SetText(killData.zone or "Unknown")
    zoneText:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    zoneText:SetJustifyH("LEFT")

    local killsText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killsText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    killsText:SetText(killData.kills and tostring(killData.kills) or "1")
    killsText:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    killsText:SetJustifyH("LEFT")

    local timeText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    timeText:SetText(PSC_FormatTimestamp(killData.timestamp))

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
    levelText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    levelText:SetText(deathData.killerLevel == -1 and "??" or tostring(deathData.killerLevel))
    levelText:SetWidth(PSC_COLUMN_WIDTHS.LEVEL)

    local zoneText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    zoneText:SetText(deathData.zone or "Unknown")
    zoneText:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    zoneText:SetJustifyH("LEFT")

    -- Create a frame for the assisters column to handle tooltip
    local assistFrame = CreateFrame("Frame", nil, parent)
    assistFrame:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    assistFrame:SetSize(100, 20)

    local assistText = assistFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    assistText:SetPoint("LEFT", 0, 0)

    local assistCount = deathData.assisters and #deathData.assisters or 0
    local assistDisplay = assistCount > 0 and tostring(assistCount) .. " players" or "-"
    assistText:SetText(assistDisplay)
    assistText:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    assistText:SetJustifyH("LEFT")

    -- Add tooltip functionality if there are assisters
    if assistCount > 0 then
        -- Create tooltip when hovering
        assistFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Kill Assisters:", 1, 0.82, 0, 1)

            -- Sort assisters by level (highest first)
            local sortedAssisters = {}
            for i, assister in ipairs(deathData.assisters) do
                table.insert(sortedAssisters, assister)
            end

            table.sort(sortedAssisters, function(a, b)
                local levelA = tonumber(a.level) or -1
                local levelB = tonumber(b.level) or -1

                -- Treat unknown level (-1) as highest
                if levelA == -1 and levelB ~= -1 then
                    return true
                elseif levelA ~= -1 and levelB == -1 then
                    return false
                else
                    return levelA > levelB
                end
            end)

            -- Add assisters to tooltip
            for _, assister in ipairs(sortedAssisters) do
                local playerLevel
                local playerClass
                local displayText
                local color

                if PSC_DB.PlayerInfoCache[assister.name] ~= nil then
                    local playerInfo = PSC_DB.PlayerInfoCache[assister.name]
                    playerLevel = playerInfo.level
                    playerClass = playerInfo.class
                    local levelDisplay = playerLevel == -1 and "??" or tostring(playerLevel)
                    color = RAID_CLASS_COLORS[playerClass:upper()]
                    displayText = assister.name .. " (" .. levelDisplay .. " " .. playerClass .. ")"
                else
                    color = {r = 1, g = 1, b = 1} -- Default to white if class not found
                    displayText = assister.name
                end

                GameTooltip:AddLine(displayText, color.r, color.g, color.b)
            end

            GameTooltip:Show()
        end)

        assistFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end

    local timeText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    timeText:SetText(PSC_FormatTimestamp(deathData.timestamp))

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

-- Helper functions for creating and manipulating the player detail frame
local function FindPlayerEntryByName(playerName)
    -- Create a basic entry even if we don't have complete info
    local entry = {
        name = playerName,
        class = "Unknown",
        race = "Unknown",
        gender = "Unknown",
        levelDisplay = -1,
        guild = "",
        rank = 0,
        kills = 0,
        deaths = 0,
        assists = 0,
        lastKill = 0,
        killHistory = {},
        deathHistory = {},
        assistHistory = {}
    }

    -- Try to get player info from the database cache
    local playerInfo = PSC_DB.PlayerInfoCache[playerName]
    if playerInfo then
        -- Update with available information
        entry.class = playerInfo.class or "Unknown"
        entry.race = playerInfo.race or "Unknown"
        entry.gender = playerInfo.gender or "Unknown"
        entry.levelDisplay = playerInfo.level or -1
        entry.guild = playerInfo.guild or ""
        entry.rank = playerInfo.rank or 0
    end

    -- Collect kill history across all characters
    local charactersToProcess = GetCharactersToProcessForStatistics()
    for charKey, charData in pairs(charactersToProcess) do
        for nameWithLevel, killData in pairs(charData.Kills or {}) do
            local name = string.match(nameWithLevel, "(.-)%:")
            if name and name == playerName then
                local level = tonumber(string.match(nameWithLevel, ":(%d+)") or "-1") or -1

                -- Update total kills
                entry.kills = entry.kills + (killData.kills or 0)

                -- Keep track of the most recent kill timestamp
                if (killData.lastKill or 0) > entry.lastKill then
                    entry.lastKill = killData.lastKill
                    entry.zone = killData.zone or "Unknown"
                end

                -- Add to kill history
                table.insert(entry.killHistory, {
                    level = level,
                    zone = killData.zone or "Unknown",
                    timestamp = killData.lastKill or 0,
                    rank = killData.rank or 0,
                    kills = killData.kills or 0
                })
            end
        end
    end

    -- Collect death history and assists from all characters that match this player name
    local currentCharacterKey = PSC_GetCharacterKey()
    local lossData = PSC_DB.PvPLossCounts[currentCharacterKey]

    if lossData and lossData.Deaths then
        -- Count direct deaths
        if lossData.Deaths[playerName] then
            local deathData = lossData.Deaths[playerName]
            entry.deaths = deathData.deaths or 0

            -- Add all death locations to history
            if deathData.deathLocations then
                for _, location in ipairs(deathData.deathLocations) do
                    table.insert(entry.deathHistory, location)
                end
            end
        end

        -- Count assists and build assist history
        for killerName, deathData in pairs(lossData.Deaths) do
            if deathData.deathLocations then
                for _, location in ipairs(deathData.deathLocations) do
                    if location.assisters then
                        for _, assister in ipairs(location.assisters) do
                            if assister.name == playerName then
                                entry.assists = entry.assists + 1

                                -- Create assist history entry
                                local assistData = {
                                    killerName = killerName,
                                    killerLevel = location.killerLevel or -1,
                                    victimLevel = entry.levelDisplay, -- Use the entry level (which might be -1)
                                    zone = location.zone or "Unknown",
                                    timestamp = location.timestamp or 0,
                                    otherAssisters = {}
                                }

                                -- Add other assisters (excluding the current player)
                                for _, otherAssister in ipairs(location.assisters) do
                                    if otherAssister.name ~= playerName then
                                        table.insert(assistData.otherAssisters, otherAssister)
                                    end
                                end

                                table.insert(entry.assistHistory, assistData)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Always return an entry even if incomplete
    return entry
end

local function CreatePlayerDetailFrame()
    local frame = CreateFrame("Frame", "PSC_PlayerDetailFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(DETAIL_FRAME_WIDTH, DETAIL_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Create scrollable content frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(DETAIL_FRAME_WIDTH - 40, DETAIL_FRAME_HEIGHT * 3)
    scrollFrame:SetScrollChild(content)

    frame.content = content

    -- Don't add to UISpecialFrames as FrameManager will handle this
    -- Remove this line: table.insert(UISpecialFrames, "PSC_PlayerDetailFrame")

    return frame
end

local function DisplayPlayerSummarySection(content, playerEntry, yOffset)
    yOffset = CreateSection(content, "Player Information", yOffset)

    -- Setup player info directly from database
    local playerName = playerEntry.name
    local playerClass = playerEntry.class
    local playerRace = playerEntry.race
    local playerGender = playerEntry.gender
    local playerLevel = playerEntry.levelDisplay == -1 and "??" or tostring(playerEntry.levelDisplay)
    local playerGuild = playerEntry.guild
    local guildInfo = playerGuild ~= "" and " <" .. playerGuild .. ">" or ""

    -- Create left-aligned player info that matches the other detail rows
    local playerLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", 25, yOffset)
    playerLabel:SetText("Player:")
    playerLabel:SetTextColor(1, 1, 1) -- White color

    -- Create player info with class color
    local infoText = string.format("%s - Level %s %s %s",
        playerName, playerLevel, playerRace, playerClass)

    local playerInfoLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    playerInfoLabel:SetPoint("TOPLEFT", 120, yOffset) -- Match the alignment of other detail rows
    playerInfoLabel:SetText(infoText)

    -- Apply class color to the player info text
    if playerClass ~= "Unknown" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[playerClass:upper()] then
        local color = RAID_CLASS_COLORS[playerClass:upper()]
        playerInfoLabel:SetTextColor(color.r, color.g, color.b)
    else
        -- Gray out text for incomplete player info
        playerInfoLabel:SetTextColor(0.7, 0.7, 0.7)
    end

    yOffset = yOffset - 20

    -- Add other player stats
    yOffset = CreateDetailRow(content, "Rank:", playerEntry.rank and playerEntry.rank > 0 and tostring(playerEntry.rank) or "0", yOffset)
    yOffset = CreateDetailRow(content, "Total kills:", tostring(playerEntry.kills), yOffset)
    yOffset = CreateDetailRow(content, "Total deaths:", tostring(playerEntry.deaths), yOffset)
    yOffset = CreateDetailRow(content, "Total assists:", tostring(playerEntry.assists), yOffset) -- Add assists to summary
    yOffset = CreateDetailRow(content, "K/D Ratio:", string.format("%.2f", playerEntry.deaths > 0 and playerEntry.kills / playerEntry.deaths or playerEntry.kills), yOffset)

    return yOffset - 20
end

local function DisplayKillHistorySection(content, playerEntry, yOffset)
    yOffset = CreateSection(content, "Kill History", yOffset)
    yOffset = CreateKillHistoryHeaderRow(content, yOffset)

    -- Kill history entries
    if playerEntry.killHistory and #playerEntry.killHistory > 0 then
        -- Sort by timestamp descending (most recent first)
        local sortedKillHistory = SortKillHistoryByTimestamp(playerEntry.killHistory)

        for i, killData in ipairs(sortedKillHistory) do
            yOffset = CreateKillHistoryEntry(content, killData, i, yOffset)
        end
    else
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("TOPLEFT", 25, yOffset - 10)
        noDataText:SetText("No kills for this player have been recorded.")
        noDataText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 30
    end

    return yOffset - 20
end

local function CreateDeathHistoryHeaderRow(content, yOffset)
    local deathHeaderBg = content:CreateTexture(nil, "BACKGROUND")
    deathHeaderBg:SetPoint("TOPLEFT", 15, yOffset)
    deathHeaderBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
    deathHeaderBg:SetHeight(20)
    deathHeaderBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local killerLevelHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killerLevelHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    killerLevelHeader:SetText("Level")
    killerLevelHeader:SetTextColor(1, 0.82, 0)

    local deathZoneHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathZoneHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    deathZoneHeader:SetText("Zone")
    deathZoneHeader:SetTextColor(1, 0.82, 0)
    deathZoneHeader:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    deathZoneHeader:SetJustifyH("LEFT")

    local assistHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    assistHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    assistHeader:SetText("Assisters")
    assistHeader:SetTextColor(1, 0.82, 0)
    assistHeader:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    assistHeader:SetJustifyH("LEFT")

    local deathTimeHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathTimeHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    deathTimeHeader:SetText("Time")
    deathTimeHeader:SetTextColor(1, 0.82, 0)

    return yOffset - 20
end

local function DisplayDeathHistorySection(content, playerEntry, yOffset)
    yOffset = CreateSection(content, "Death History", yOffset)
    yOffset = CreateDeathHistoryHeaderRow(content, yOffset)

    -- Death history entries
    if playerEntry.deathHistory and #playerEntry.deathHistory > 0 then
        -- Sort by timestamp descending (most recent first)
        local sortedDeathHistory = SortDeathHistoryByTimestamp(playerEntry.deathHistory)

        for i, deathData in ipairs(sortedDeathHistory) do
            yOffset = CreateDeathHistoryEntry(content, deathData, i, yOffset)
        end
    else
        local noDeathDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDeathDataText:SetPoint("TOPLEFT", 25, yOffset - 10)
        noDeathDataText:SetText("No deaths by this player have been recorded.")
        noDeathDataText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 30
    end

    return yOffset - 20
end

-- Create a header row for assist history
local function CreateAssistHistoryHeaderRow(content, yOffset)
    local assistHeaderBg = content:CreateTexture(nil, "BACKGROUND")
    assistHeaderBg:SetPoint("TOPLEFT", 15, yOffset)
    assistHeaderBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -15, 0)
    assistHeaderBg:SetHeight(20)
    assistHeaderBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local victimLevelHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    victimLevelHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    victimLevelHeader:SetText("Level")
    victimLevelHeader:SetTextColor(1, 0.82, 0)

    local assistZoneHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    assistZoneHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    assistZoneHeader:SetText("Zone")
    assistZoneHeader:SetTextColor(1, 0.82, 0)
    assistZoneHeader:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    assistZoneHeader:SetJustifyH("LEFT")

    local killerHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killerHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    killerHeader:SetText("Killer")
    killerHeader:SetTextColor(1, 0.82, 0)
    killerHeader:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    killerHeader:SetJustifyH("LEFT")

    local assistTimeHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    assistTimeHeader:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    assistTimeHeader:SetText("Time")
    assistTimeHeader:SetTextColor(1, 0.82, 0)

    return yOffset - 20
end

-- Create an entry row for assist history
local function CreateAssistHistoryEntry(parent, assistData, index, yOffset)
    local bgColor = index % 2 == 0 and {0.1, 0.1, 0.1, 0.3} or {0.15, 0.15, 0.15, 0.3}

    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", 15, yOffset)
    bg:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, 0)
    bg:SetHeight(20)
    bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    -- Your level when you died (the victim)
    local levelText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    levelText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.LEVEL, yOffset - 3)
    levelText:SetText(assistData.victimLevel == -1 and "??" or tostring(assistData.victimLevel))
    levelText:SetWidth(PSC_COLUMN_WIDTHS.LEVEL)

    -- Zone where the assist occurred
    local zoneText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.ZONE, yOffset - 3)
    zoneText:SetText(assistData.zone or "Unknown")
    zoneText:SetWidth(PSC_COLUMN_WIDTHS.ZONE)
    zoneText:SetJustifyH("LEFT")

    -- Create a frame for the killer info with tooltip
    local killerFrame = CreateFrame("Frame", nil, parent)
    killerFrame:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.KILLS, yOffset - 3)
    killerFrame:SetSize(100, 20)

    local killerText = killerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killerText:SetPoint("LEFT", 0, 0)
    killerText:SetText(assistData.killerName or "Unknown")
    killerText:SetWidth(PSC_COLUMN_WIDTHS.KILLS)
    killerText:SetJustifyH("LEFT")

    -- Color the killer name based on class if known
    local killerInfo = PSC_DB.PlayerInfoCache[assistData.killerName]
    if killerInfo and killerInfo.class and RAID_CLASS_COLORS[killerInfo.class:upper()] then
        local color = RAID_CLASS_COLORS[killerInfo.class:upper()]
        killerText:SetTextColor(color.r, color.g, color.b)
    else
        -- Use default white color for unknown players
        killerText:SetTextColor(1, 1, 1)
    end

    -- Add tooltip with killer info
    killerFrame:SetScript("OnEnter", function(self)
        if not assistData.killerName then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Main Killer:", 1, 0.82, 0, 1)

        -- Format killer info with class color if available
local killerInfo = PSC_DB.PlayerInfoCache[assistData.killerName]
        if killerInfo then
            local killerLevel = killerInfo.level == -1 and "??" or tostring(killerInfo.level)
            local killerClass = killerInfo.class or "Unknown"
            local color = RAID_CLASS_COLORS[killerClass:upper()] or {r=1, g=1, b=1}
            local displayText = string.format("%s (Level %s %s)", assistData.killerName, killerLevel, killerClass)
            GameTooltip:AddLine(displayText, color.r, color.g, color.b)
        else
            -- Use white color for unknown players
            GameTooltip:AddLine(assistData.killerName, 1, 1, 1)
        end

        -- Add other assisters if any
        if assistData.otherAssisters and #assistData.otherAssisters > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Other Assisters:", 1, 0.82, 0)

            for _, assister in ipairs(assistData.otherAssisters) do
                local assisterInfo = PSC_DB.PlayerInfoCache[assister.name]
                if assisterInfo then
                    local assisterLevel = assisterInfo.level == -1 and "??" or tostring(assisterInfo.level)
                    local assisterClass = assisterInfo.class or "Unknown"
                    local color = RAID_CLASS_COLORS[assisterClass:upper()] or {r=1, g=1, b=1}
                    local displayText = string.format("%s (Level %s %s)", assister.name, assisterLevel, assisterClass)
                    GameTooltip:AddLine(displayText, color.r, color.g, color.b)
                else
                    -- Use white color for unknown players
                    GameTooltip:AddLine(assister.name, 1, 1, 1)
                end
            end
        end

        GameTooltip:Show()
    end)

    killerFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Timestamp
    local timeText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", PSC_COLUMN_POSITIONS.TIME, yOffset - 3)
    timeText:SetText(PSC_FormatTimestamp(assistData.timestamp))

    return yOffset - 20
end

-- Collect and display assist history
local function DisplayAssistHistorySection(content, playerEntry, yOffset)
    yOffset = CreateSection(content, "Assist History", yOffset)
    yOffset = CreateAssistHistoryHeaderRow(content, yOffset)

    -- Display assist history entries
    if playerEntry.assistHistory and #playerEntry.assistHistory > 0 then
        -- Sort by timestamp descending (most recent first)
        table.sort(playerEntry.assistHistory, function(a, b)
            return (a.timestamp or 0) > (b.timestamp or 0)
        end)

        for i, assistData in ipairs(playerEntry.assistHistory) do
            yOffset = CreateAssistHistoryEntry(content, assistData, i, yOffset)
        end
    else
        local noAssistDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noAssistDataText:SetPoint("TOPLEFT", 25, yOffset - 10)
        noAssistDataText:SetText("No assists by this player have been recorded.")
        noAssistDataText:SetTextColor(0.7, 0.7, 0.7)
        yOffset = yOffset - 30
    end

    return yOffset - 20
end

-- Main function to display the player detail frame
function PSC_ShowPlayerDetailFrame(playerName)
    if not playerName then return end

    -- Find player entry
    local playerEntry = FindPlayerEntryByName(playerName)
    if not playerEntry then
        print("Could not find detailed information for player:", playerName)
        return
    end

    -- Create or reuse frame
    if not PSC_PlayerDetailFrame then
        PSC_PlayerDetailFrame = CreatePlayerDetailFrame()
        -- Register with frame manager
        PSC_FrameManager:RegisterFrame(PSC_PlayerDetailFrame, "PlayerDetail")
    else
        CleanupPlayerDetailFrame(PSC_PlayerDetailFrame.content)
    end

    local content = PSC_PlayerDetailFrame.content
    local titleText = playerName .. " - Player Details"
    PSC_PlayerDetailFrame.TitleText:SetText(titleText)

    -- Use frame manager to show and bring to front
    PSC_FrameManager:ShowFrame("PlayerDetail")

    -- Setup each section
    local yOffset = 0

    -- Player summary section
    yOffset = DisplayPlayerSummarySection(content, playerEntry, yOffset)

    -- Kill history section
    yOffset = DisplayKillHistorySection(content, playerEntry, yOffset)

    -- Death history section
    yOffset = DisplayDeathHistorySection(content, playerEntry, yOffset)

    -- Assist history section
    yOffset = DisplayAssistHistorySection(content, playerEntry, yOffset)

    -- Set final content height
    content:SetHeight(math.abs(yOffset) + 30)
end
