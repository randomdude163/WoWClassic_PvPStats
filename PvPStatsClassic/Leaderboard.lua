local addonName, PVPSC = ...

-- Store remote player statistics
PSC_RemotePlayerStats = {}

-- Register communication handlers
function PSC_SetupLeaderboardHandlers()
    if not PSC_EventHandlers then PSC_EventHandlers = {} end

    PSC_EventHandlers["CHAT_MSG_ADDON"] = function(prefix, message, channel, sender)
        if prefix ~= PSC_MESSAGE_PREFIX then return end

        local senderName = sender:match("([^-]+)")
        if senderName == UnitName("player") then return end -- Ignore own messages

        local msgType, data = message:match("^(%d+):(.+)$")
        msgType = tonumber(msgType)

        if not msgType then return end

        if PSC_Debug then
            print("[PSC Debug] Received message type " .. msgType .. " from " .. sender)
        end

        -- Process the message based on type
        PSC_ProcessIncomingMessage(msgType, data, senderName)
    end

    -- Register for addon messages
    C_ChatInfo.RegisterAddonMessagePrefix(PSC_MESSAGE_PREFIX)
end

-- Process incoming messages from other players
function PSC_ProcessIncomingMessage(msgType, data, sender)
    if not PSC_RemotePlayerStats[sender] then
        PSC_RemotePlayerStats[sender] = {
            lastUpdate = time(),
            playerName = sender
        }
    end

    local stats = PSC_DecompressStatistics(data, msgType)

    -- Store the stats based on message type
    if msgType == 1 then  -- Basic stats
        PSC_RemotePlayerStats[sender].basicStats = stats
    elseif msgType == 2 then  -- Class data
        PSC_RemotePlayerStats[sender].classData = stats
    elseif msgType == 3 then  -- Race data
        PSC_RemotePlayerStats[sender].raceData = stats
    elseif msgType == 4 then  -- Level data
        PSC_RemotePlayerStats[sender].levelData = stats
    end

    PSC_RemotePlayerStats[sender].lastUpdate = time()

    -- Update UI if leaderboard is visible
    if PSC_LeaderboardFrame and PSC_LeaderboardFrame:IsVisible() then
        PSC_UpdateLeaderboardDisplay()
    end
end

-- Share player statistics with guild/party
function PSC_ShareAllStatistics()
    -- Don't share if disabled in settings
    if PSC_DB.DisableStatSharing then
        if PSC_Debug then
            print("[PSC Debug] Stat sharing is disabled in settings")
        end
        return
    end

    local currentCharacterKey = PSC_GetCharacterKey()
    local charactersToProcess = {}

    if PSC_DB.PlayerKillCounts.Characters[currentCharacterKey] then
        charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
    end

    -- Get statistics data
    local classData, raceData, genderData, zoneData, levelData, guildStatusData =
        PSC_CalculateBarChartStatistics(charactersToProcess)

    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)
    stats.classData = classData
    stats.raceData = raceData
    stats.levelData = levelData

    -- Compress the data
    local compressedStats = PSC_CompressStatistics(stats)

    -- Send to appropriate channels
    local channels = {}
    if IsInGuild() then table.insert(channels, "GUILD") end
    if IsInGroup() then
        if IsInRaid() then
            table.insert(channels, "RAID")
        else
            table.insert(channels, "PARTY")
        end
    end

    -- Queue messages for each channel
    for _, channel in ipairs(channels) do
        PSC_QueueMessage(1, compressedStats[1], channel, PRIORITY_HIGH)
        PSC_QueueMessage(2, compressedStats[2], channel, PRIORITY_NORMAL)
        PSC_QueueMessage(3, compressedStats[3], channel, PRIORITY_NORMAL)
        PSC_QueueMessage(4, compressedStats[4], channel, PRIORITY_LOW)
    end
end

-- Request stats from guild/party members
function PSC_RequestStatistics()
    if PSC_DB.DisableStatSharing then return end

    if PSC_Debug then
        print("[PSC Debug] Requesting statistics from guild/group members")
    end

    local channels = {}
    if IsInGuild() then table.insert(channels, "GUILD") end
    if IsInGroup() then
        if IsInRaid() then
            table.insert(channels, "RAID")
        else
            table.insert(channels, "PARTY")
        end
    end

    for _, channel in ipairs(channels) do
        PSC_QueueMessage(99, "req", channel, PRIORITY_HIGH)  -- Use type 99 for requests
    end
end

-- Initialize the communication module
function PSC_InitLeaderboard()
    PSC_SetupLeaderboardHandlers()

    -- Setup event to share stats when they change
    if not PSC_StatisticsUpdateEvent then
        PSC_StatisticsUpdateEvent = CreateFrame("Frame")
        PSC_StatisticsUpdateEvent:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
        PSC_StatisticsUpdateEvent:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_PVP_KILLS_CHANGED" then
                C_Timer.After(1, PSC_ShareAllStatistics)
            end
        end)
    end
end

-- UI Constants for Leaderboard
local LEADERBOARD_UI = {
    FRAME = {
        WIDTH = 850,
        HEIGHT = 600
    },
    TABLE = {
        HEADER_HEIGHT = 25,
        ROW_HEIGHT = 20,
        COLUMN_WIDTH = 120,
        FIRST_COLUMN_WIDTH = 180,
        MAX_COLUMNS = 6  -- Maximum players to display (including self)
    },
    COLORS = {
        HEADER = {r = 0.2, g = 0.2, b = 0.8},
        ROW_EVEN = {r = 0.15, g = 0.15, b = 0.15, a = 0.5},
        ROW_ODD = {r = 0.3, g = 0.3, b = 0.3, a = 0.5},
        HIGHLIGHT = {r = 0.4, g = 0.4, b = 0.6, a = 0.5}
    }
}

-- Create the frame skeleton for the leaderboard
function PSC_CreateLeaderboardFrame()
    -- Only create if it doesn't already exist
    if PSC_LeaderboardFrame then
        PSC_LeaderboardFrame:Show()
        return
    end

    -- Main frame
    local frame = CreateFrame("Frame", "PSC_LeaderboardFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(LEADERBOARD_UI.FRAME.WIDTH, LEADERBOARD_UI.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Add to special frames so ESC closes it
    tinsert(UISpecialFrames, "PSC_LeaderboardFrame")

    -- Title text
    frame.TitleText:SetText("PvP Leaderboard")

    -- Setup the content area with scrolling
    local scrollFrame = CreateFrame("ScrollFrame", "PSC_LeaderboardScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", "PSC_LeaderboardScrollChild", scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)

    -- Store the scroll frame and content references
    frame.scrollFrame = scrollFrame
    frame.scrollChild = scrollChild

    -- Setup filters and refresh button
    local refreshButton = CreateFrame("Button", "PSC_LeaderboardRefreshButton", frame, "UIPanelButtonTemplate")
    refreshButton:SetSize(80, 22)
    refreshButton:SetPoint("TOPRIGHT", -30, -8)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        PSC_RequestStatistics()
        PSC_UpdateLeaderboardDisplay()
    end)

    -- Access the scrollbar
    local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -32)
        scrollBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 10)
    end

    -- Store as global
    PSC_LeaderboardFrame = frame

    -- Initial update and request data
    PSC_UpdateLeaderboardDisplay()
    PSC_RequestStatistics()
end

-- Toggle leaderboard visibility
function PSC_ToggleLeaderboardFrame()
    if not PSC_LeaderboardFrame then
        PSC_CreateLeaderboardFrame()
    elseif PSC_LeaderboardFrame:IsVisible() then
        PSC_LeaderboardFrame:Hide()
    else
        PSC_LeaderboardFrame:Show()
        PSC_UpdateLeaderboardDisplay()
    end
end

-- Generate the stat rows definitions that will appear in the table
function PSC_GetLeaderboardRowDefinitions()
    return {
        { name = "Total Kills", dataKey = "totalKills", format = "%d" },
        { name = "Unique Players Killed", dataKey = "uniqueKills", format = "%d" },
        { name = "Level ?? Kills", dataKey = "unknownLevelKills", format = "%d" },
        { name = "Most Killed Player", dataKey = "mostKilledPlayer", format = "%s", tooltip = "Player you've killed the most times" },
        { name = "Average Victim Level", dataKey = "avgLevel", format = "%.1f" },
        { name = "Average Kills Per Player", dataKey = "avgKillsPerPlayer", format = "%.2f" },
        { name = "Average Level Difference", dataKey = "avgLevelDiff", format = "%.1f",
          getColorFunc = function(val)
            return val > 0 and {r=0.2, g=0.8, b=0.2} or {r=0.8, g=0.2, b=0.2}
          end,
          formatFunc = function(val) return string.format("%.1f", val) .. (val > 0 and " (higher)" or " (lower)") end
        },
        { name = "Current Kill Streak", dataKey = "currentKillStreak", format = "%d" },
        { name = "Highest Kill Streak", dataKey = "highestKillStreak", format = "%d" },
        { name = "Highest Multi-Kill", dataKey = "highestMultiKill", format = "%d" },
        { name = "Deaths", dataKey = "deaths", format = "%d" },
        { name = "Kill/Death Ratio", dataKey = "killDeathRatio", format = "%.2f" },
        { name = "Achievements Unlocked", dataKey = "achievementsUnlocked", format = "%d" },
        { name = "Achievement Points", dataKey = "achievementPoints", format = "%d" },
    }
end

-- Update the leaderboard display with current data
function PSC_UpdateLeaderboardDisplay()
    local frame = PSC_LeaderboardFrame
    if not frame or not frame:IsVisible() then return end

    -- Clear existing content
    local scrollChild = frame.scrollChild
    scrollChild:SetSize(LEADERBOARD_UI.FRAME.WIDTH - 40, 800)  -- Initial height, will adjust later

    for i = scrollChild:GetNumChildren(), 1, -1 do
        local child = select(i, scrollChild:GetChildren())
        child:Hide()
        child:SetParent(nil)
    end

    -- Get player's own data
    local playerName = UnitName("player")
    local playerData = PSC_GetLocalPlayerLeaderboardData()

    -- Get other players' data from PSC_RemotePlayerStats
    local allPlayers = { { name = playerName, data = playerData } }
    for name, data in pairs(PSC_RemotePlayerStats) do
        if data.basicStats and time() - data.lastUpdate < 3600 then -- Data less than 1 hour old
            table.insert(allPlayers, {
                name = name,
                data = PSC_FormatRemotePlayerData(data)
            })
        end
    end

    -- Sort players by kills descending
    table.sort(allPlayers, function(a, b)
        return (a.data.totalKills or 0) > (b.data.totalKills or 0)
    end)

    -- Limit to max columns
    if #allPlayers > LEADERBOARD_UI.TABLE.MAX_COLUMNS then
        allPlayers = {unpack(allPlayers, 1, LEADERBOARD_UI.TABLE.MAX_COLUMNS)}
    end

    -- Create header row
    local headerRow = CreateFrame("Frame", nil, scrollChild)
    headerRow:SetSize(scrollChild:GetWidth(), LEADERBOARD_UI.TABLE.HEADER_HEIGHT)
    headerRow:SetPoint("TOPLEFT", 0, 0)

    -- Label column
    local labelHeader = CreateFrame("Frame", nil, headerRow)
    labelHeader:SetSize(LEADERBOARD_UI.TABLE.FIRST_COLUMN_WIDTH, LEADERBOARD_UI.TABLE.HEADER_HEIGHT)
    labelHeader:SetPoint("TOPLEFT", 0, 0)

    local labelText = labelHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    labelText:SetPoint("LEFT", 10, 0)
    labelText:SetText("Statistic")

    -- Create player columns
    local columnWidth = LEADERBOARD_UI.TABLE.COLUMN_WIDTH
    local playerColumns = {}

    for i, playerInfo in ipairs(allPlayers) do
        local xOffset = LEADERBOARD_UI.TABLE.FIRST_COLUMN_WIDTH + (i-1) * columnWidth
        local playerHeader = CreateFrame("Button", nil, headerRow)
        playerHeader:SetSize(columnWidth, LEADERBOARD_UI.TABLE.HEADER_HEIGHT)
        playerHeader:SetPoint("TOPLEFT", xOffset, 0)

        local bgTexture = playerHeader:CreateTexture(nil, "BACKGROUND")
        bgTexture:SetAllPoints()
        bgTexture:SetColorTexture(LEADERBOARD_UI.COLORS.HEADER.r, LEADERBOARD_UI.COLORS.HEADER.g, LEADERBOARD_UI.COLORS.HEADER.b, 0.7)

        local playerNameText = playerHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        playerNameText:SetPoint("CENTER", 0, 0)
        playerNameText:SetText(playerInfo.name)

        -- Make the column header clickable to view full statistics
        playerHeader:SetScript("OnClick", function()
            if playerInfo.name == playerName then
                PSC_CreateStatisticsFrame()
            else
                -- Future: Show remote player statistics if implemented
                PSC_CreateStatisticsFrame()
                print("Detailed statistics for other players not yet implemented")
            end
        end)

        -- Highlight on mouseover
        playerHeader:SetScript("OnEnter", function(self)
            bgTexture:SetColorTexture(
                LEADERBOARD_UI.COLORS.HEADER.r + 0.2,
                LEADERBOARD_UI.COLORS.HEADER.g + 0.2,
                LEADERBOARD_UI.COLORS.HEADER.b + 0.2,
                0.8
            )
        end)

        playerHeader:SetScript("OnLeave", function(self)
            bgTexture:SetColorTexture(
                LEADERBOARD_UI.COLORS.HEADER.r,
                LEADERBOARD_UI.COLORS.HEADER.g,
                LEADERBOARD_UI.COLORS.HEADER.b,
                0.7
            )
        end)

        playerColumns[i] = playerHeader
    end

    -- Create data rows
    local rows = PSC_GetLeaderboardRowDefinitions()
    local totalHeight = LEADERBOARD_UI.TABLE.HEADER_HEIGHT

    for rowIndex, rowDef in ipairs(rows) do
        local rowY = -(rowIndex * LEADERBOARD_UI.TABLE.ROW_HEIGHT)
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(scrollChild:GetWidth(), LEADERBOARD_UI.TABLE.ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, rowY)

        -- Row background (alternating)
        local bgColor = (rowIndex % 2 == 0) and LEADERBOARD_UI.COLORS.ROW_EVEN or LEADERBOARD_UI.COLORS.ROW_ODD
        local rowBg = row:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints()
        rowBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a)

        -- Row label
        local labelCol = CreateFrame("Frame", nil, row)
        labelCol:SetSize(LEADERBOARD_UI.TABLE.FIRST_COLUMN_WIDTH, LEADERBOARD_UI.TABLE.ROW_HEIGHT)
        labelCol:SetPoint("LEFT", 0, 0)

        local labelText = labelCol:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("LEFT", 10, 0)
        labelText:SetText(rowDef.name)

        -- Add tooltip if provided
        if rowDef.tooltip then
            labelCol:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(rowDef.name)
                GameTooltip:AddLine(rowDef.tooltip, 1, 1, 1, true)
                GameTooltip:Show()
            end)

            labelCol:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end

        -- Player data cells
        for i, playerInfo in ipairs(allPlayers) do
            local xOffset = LEADERBOARD_UI.TABLE.FIRST_COLUMN_WIDTH + (i-1) * columnWidth
            local cell = CreateFrame("Frame", nil, row)
            cell:SetSize(columnWidth, LEADERBOARD_UI.TABLE.ROW_HEIGHT)
            cell:SetPoint("LEFT", xOffset, 0)

            local textValue = "--"
            local value = playerInfo.data[rowDef.dataKey]

            if value ~= nil then
                if rowDef.formatFunc then
                    textValue = rowDef.formatFunc(value)
                else
                    textValue = string.format(rowDef.format, value)
                end
            end

            local cellText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            cellText:SetPoint("CENTER", 0, 0)
            cellText:SetText(textValue)

            -- Apply color if specified
            if rowDef.getColorFunc and value then
                local color = rowDef.getColorFunc(value)
                if color then
                    cellText:SetTextColor(color.r, color.g, color.b)
                end
            end
        end

        totalHeight = totalHeight + LEADERBOARD_UI.TABLE.ROW_HEIGHT
    end

    -- Adjust scroll child height
    scrollChild:SetHeight(totalHeight + 20)
end

-- Get player's own leaderboard data
function PSC_GetLocalPlayerLeaderboardData()
    local currentCharacterKey = PSC_GetCharacterKey()
    local charactersToProcess = {}

    if PSC_DB.PlayerKillCounts.Characters[currentCharacterKey] then
        charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
    end

    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)

    -- Calculate K/D ratio
    local kd = 0
    if (stats.deaths or 0) > 0 then
        kd = (stats.totalKills or 0) / stats.deaths
    elseif (stats.totalKills or 0) > 0 then
        kd = stats.totalKills -- No deaths = infinity, show kills instead
    end

    -- Format most killed player with count
    local mostKilledDisplay = "None (0)"
    if stats.mostKilledPlayer and stats.mostKilledPlayer ~= "None" then
        mostKilledDisplay = stats.mostKilledPlayer .. " (" .. stats.mostKilledCount .. ")"
    end

    return {
        totalKills = stats.totalKills or 0,
        uniqueKills = stats.uniqueKills or 0,
        unknownLevelKills = stats.unknownLevelKills or 0,
        mostKilledPlayer = mostKilledDisplay,
        avgLevel = stats.avgLevel or 0,
        avgKillsPerPlayer = stats.avgKillsPerPlayer or 0,
        avgLevelDiff = stats.avgLevelDiff or 0,
        currentKillStreak = stats.currentKillStreak or 0,
        highestKillStreak = stats.highestKillStreak or 0,
        highestMultiKill = stats.highestMultiKill or 0,
        deaths = stats.deaths or 0,
        killDeathRatio = kd,
        achievementsUnlocked = stats.achievementsUnlocked or 0,
        achievementPoints = stats.achievementPoints or 0
    }
end

-- Format remote player data for the leaderboard
function PSC_FormatRemotePlayerData(remoteData)
    if not remoteData or not remoteData.basicStats then
        return {}
    end

    local result = {
        totalKills = remoteData.basicStats.totalKills or 0,
        uniqueKills = remoteData.basicStats.uniqueKills or 0,
        unknownLevelKills = remoteData.basicStats.unknownLevelKills or 0,
        mostKilledPlayer = remoteData.basicStats.mostKilledPlayer or "None (0)",
        avgLevel = remoteData.basicStats.avgLevel or 0,
        avgKillsPerPlayer = remoteData.basicStats.avgKillsPerPlayer or 0,
        avgLevelDiff = remoteData.basicStats.avgLevelDiff or 0,
        currentKillStreak = remoteData.basicStats.currentKillStreak or 0,
        highestKillStreak = remoteData.basicStats.highestKillStreak or 0,
        highestMultiKill = remoteData.basicStats.highestMultiKill or 0,
        deaths = remoteData.basicStats.deaths or 0,
        achievementsUnlocked = remoteData.basicStats.achievementsUnlocked or 0,
        achievementPoints = remoteData.basicStats.achievementPoints or 0
    }

    -- Calculate K/D ratio
    local kd = 0
    if (result.deaths or 0) > 0 then
        kd = result.totalKills / result.deaths
    elseif result.totalKills > 0 then
        kd = result.totalKills -- No deaths = infinity, show kills instead
    end
    result.killDeathRatio = kd

    return result
end

-- Get class color for display
function GetClassColor(className)
    if not className or className == "None" then
        return {r=1, g=1, b=1}
    end

    local classUpper = string.upper(className)
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classUpper] then
        local color = RAID_CLASS_COLORS[classUpper]
        return {r=color.r, g=color.g, b=color.b}
    end

    -- Fallback to white if class not found
    return {r=1, g=1, b=1}
end

-- Add a slash command to show the leaderboard
SLASH_PSCLEADERBOARD1 = "/pscleaderboard"
SLASH_PSCLEADERBOARD2 = "/pvpleaderboard"
SlashCmdList["PSCLEADERBOARD"] = function(msg)
    PSC_ToggleLeaderboardFrame()
end

-- Register a menu option to show the leaderboard
if PSC_RegistrationCallbacks and not PSC_RegistrationCallbacks.leaderboard then
    PSC_RegistrationCallbacks.leaderboard = function()
        PSC_FrameManager:RegisterButton({
            text = "Leaderboard",
            func = function() PSC_ToggleLeaderboardFrame() end
        })
    end

    PSC_RegistrationCallbacks.leaderboard()
end

-- Make sure to initialize when the addon loads
if PSC_OnInitialize and not PSC_OnInitialize.leaderboard then
    PSC_OnInitialize.leaderboard = PSC_InitLeaderboard
end