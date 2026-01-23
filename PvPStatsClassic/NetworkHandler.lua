local addonName, PVPSC = ...

PVPSC.Network = PVPSC.Network or {}
local Network = PVPSC.Network

-- Network configuration
local PREFIX = "PVPSC_LB"  -- PvP Stats Classic Leaderboard
local PREFIX_REQUEST = "PVPSC_REQ"  -- Detailed stats request
local PREFIX_RESPONSE = "PVPSC_RES"  -- Detailed stats response
local DEBUG = true  -- Enable debug to see what's happening

-- Shared data cache: stores other players' stats
Network.sharedData = Network.sharedData or {}
Network.detailedStatsCache = Network.detailedStatsCache or {}  -- Cache for detailed stats
Network.pendingRequests = Network.pendingRequests or {}  -- Track pending requests
Network.lastBroadcast = Network.lastBroadcast or 0
Network.BROADCAST_INTERVAL = 60  -- Broadcast every 60 seconds
Network.DATA_TTL = 600  -- Consider data stale after 10 minutes (600 seconds)
Network.REQUEST_TIMEOUT = 10  -- Request timeout in seconds
Network.CHUNK_SIZE = 200  -- Bytes per chunk (WoW limit is 255, leave room for overhead)

-- Deduplication cache to prevent processing the same message multiple times
local recentMessages = {}
local RECENT_TTL = 300  -- 5 minutes

local function D(...)
    if DEBUG then
        print("|cFFFFD700[PVPSC Network]|r", ...)
    end
end

-- Simple serialization for our data (using string concatenation)
local function SerializeData(data)
    if type(data) ~= "table" then return nil end
    
    -- Format: field1|field2|field3|...
    local parts = {
        data.playerName or "",
        tostring(data.level or 0),
        data.class or "",
        data.race or "",
        tostring(data.totalKills or 0),
        tostring(data.uniqueKills or 0),
        data.kdRatio or "0.00",
        tostring(data.bestStreak or 0),
        data.avgPerDay or "0.0",
        data.achievements or "0/0",
        tostring(data.achievementPoints or 0),
        data.addonVersion or "",
        tostring(data.timestamp or 0),
        data.realm or "",
        data.faction or ""
    }
    
    return table.concat(parts, "|")
end

local function DeserializeData(payload)
    if type(payload) ~= "string" then return nil end
    
    local parts = {}
    for part in string.gmatch(payload, "[^|]+") do
        table.insert(parts, part)
    end
    
    if #parts < 14 then
        D("Invalid payload, not enough fields:", #parts)
        return nil
    end
    
    return {
        playerName = parts[1],
        level = tonumber(parts[2]) or 0,
        class = parts[3],
        race = parts[4],
        totalKills = tonumber(parts[5]) or 0,
        uniqueKills = tonumber(parts[6]) or 0,
        kdRatio = parts[7],
        bestStreak = tonumber(parts[8]) or 0,
        avgPerDay = parts[9],
        achievements = parts[10],
        achievementPoints = tonumber(parts[11]) or 0,
        addonVersion = parts[12],
        timestamp = tonumber(parts[13]) or 0,
        realm = parts[14],
        faction = parts[15]
    }
end

-- Generate a unique key for deduplication
local function GetMessageKey(playerName, timestamp)
    return playerName .. "@" .. tostring(timestamp)
end

-- Check if we've recently processed this message
local function IsDuplicate(playerName, timestamp)
    local now = time()
    local key = GetMessageKey(playerName, timestamp)
    
    if recentMessages[key] and recentMessages[key] > now then
        return true
    end
    
    recentMessages[key] = now + RECENT_TTL
    
    -- Cleanup old entries occasionally
    if math.random(20) == 1 then
        for k, expireTime in pairs(recentMessages) do
            if expireTime <= now then
                recentMessages[k] = nil
            end
        end
    end
    
    return false
end

-- Build current player's stats for broadcasting
function Network:BuildPlayerStats()
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    local _, playerRace = UnitRace("player")
    local playerLevel = UnitLevel("player")
    
    -- Use the same statistics calculation function as LeaderboardFrame
    local charactersToProcess = GetCharactersToProcessForStatistics()
    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)
    
    -- Format K/D ratio
    local kdRatio
    if stats.totalDeaths and stats.totalDeaths > 0 then
        kdRatio = string.format("%.2f", stats.kdRatio)
    else
        if stats.totalKills and stats.totalKills > 0 then
            kdRatio = "∞"
        else
            kdRatio = "0.00"
        end
    end
    
    -- Format average kills per day
    local avgPerDay
    if stats.avgKillsPerDay > 0 then
        avgPerDay = string.format("%.1f", stats.avgKillsPerDay)
    else
        avgPerDay = "0.0"
    end
    
    -- Count achievements
    local currentCharacterKey = PSC_GetCharacterKey()
    local completedAchievements = 0
    local totalAchievements = 0
    
    if PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements then
        totalAchievements = #PVPSC.AchievementSystem.achievements
        
        if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[currentCharacterKey] then
            for _, achievementData in pairs(PSC_DB.CharacterAchievements[currentCharacterKey]) do
                if achievementData.unlocked then
                    completedAchievements = completedAchievements + 1
                end
            end
        end
    end
    
    local achievementText = completedAchievements .. "/" .. totalAchievements
    local achievementPoints = PSC_DB.CharacterAchievementPoints[currentCharacterKey] or 0
    local addonVersion = "v" .. PSC_GetAddonVersion()
    
    -- Format most killed player text
    local mostKilledText = stats.mostKilledPlayer or "None"
    if mostKilledText ~= "None" and stats.mostKilledCount and stats.mostKilledCount > 0 then
        mostKilledText = mostKilledText .. " (" .. stats.mostKilledCount .. ")"
    end
    
    return {
        playerName = playerName,
        level = playerLevel,
        class = playerClass,
        race = playerRace,
        totalKills = stats.totalKills,
        uniqueKills = stats.uniqueKills,
        kdRatio = kdRatio,
        currentStreak = stats.currentKillStreak,
        bestStreak = stats.highestKillStreak,
        mostKilled = mostKilledText,
        avgPerDay = avgPerDay,
        achievements = achievementText,
        achievementPoints = achievementPoints,
        addonVersion = addonVersion,
        timestamp = time(),
        realm = GetRealmName() or "",
        faction = UnitFactionGroup("player") or ""
    }
end

-- Broadcast player stats to guild
function Network:BroadcastStats()
    local now = time()
    
    -- Rate limiting: don't broadcast too frequently
    if now - self.lastBroadcast < self.BROADCAST_INTERVAL then
        D("Broadcast skipped (cooldown)")
        return
    end
    
    self.lastBroadcast = now
    
    local stats = self:BuildPlayerStats()
    if not stats then
        D("Failed to build player stats")
        return
    end
    
    local payload = SerializeData(stats)
    if not payload then
        D("Failed to serialize stats")
        return
    end
    
    -- Send to guild channel
    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "GUILD")
        D("Broadcasted stats to GUILD:", stats.playerName)
    end
    
    -- Send to raid/party if in a group
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "RAID")
        D("Broadcasted stats to RAID:", stats.playerName)
    elseif IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX, payload, "PARTY")
        D("Broadcasted stats to PARTY:", stats.playerName)
    end
    
    -- YELL channel broadcasts to nearby players (anyone in render distance)
    -- This allows non-guild/party members on the same server to see your stats
    C_ChatInfo.SendAddonMessage(PREFIX, payload, "YELL")
    D("Broadcasted stats to YELL (nearby players):", stats.playerName)
    
    -- Refresh leaderboard if it's open
    if PSC_LeaderboardFrame and PSC_LeaderboardFrame:IsShown() then
        RefreshLeaderboardFrame()
    end
end

-- Handle incoming stats from other players
function Network:OnMessageReceived(prefix, payload, channel, sender)
    if prefix ~= PREFIX then return end
    
    local data = DeserializeData(payload)
    if not data then
        D("Failed to deserialize message from", sender)
        return
    end
    
    -- Validate data
    if not data.playerName or data.playerName == "" then
        D("Invalid data: missing player name")
        return
    end
    
    -- Skip our own messages
    local playerName = UnitName("player")
    if data.playerName == playerName then
        return
    end
    
    -- Check for duplicates
    if IsDuplicate(data.playerName, data.timestamp) then
        D("Duplicate message from", data.playerName)
        return
    end
    
    -- Store the data
    self.sharedData[data.playerName] = data
    D("Received stats from", data.playerName, "- Kills:", data.totalKills)
    
    -- Refresh leaderboard if it's open
    if PSC_LeaderboardFrame and PSC_LeaderboardFrame:IsShown() then
        RefreshLeaderboardFrame()
    end
end

-- Get all leaderboard data (local + shared)
function Network:GetAllLeaderboardData()
    local leaderboardData = {}
    local now = time()
    local playerName = UnitName("player")
    
    -- Add local player's data first
    local localStats = self:BuildPlayerStats()
    if localStats then
        table.insert(leaderboardData, localStats)
    end
    
    -- Add other players' data (filter out stale data)
    for name, data in pairs(self.sharedData) do
        if name ~= playerName then
            local age = now - (data.timestamp or 0)
            if age < self.DATA_TTL then
                table.insert(leaderboardData, data)
            else
                -- Remove stale data
                self.sharedData[name] = nil
                D("Removed stale data for", name)
            end
        end
    end
    
    return leaderboardData
end

-- Clean up stale data periodically
function Network:CleanupStaleData()
    local now = time()
    local removed = 0
    
    for name, data in pairs(self.sharedData) do
        local age = now - (data.timestamp or 0)
        if age >= self.DATA_TTL then
            self.sharedData[name] = nil
            removed = removed + 1
        end
    end
    
    if removed > 0 then
        D("Cleaned up", removed, "stale entries")
    end
end

-- Initialize network handler
function Network:Initialize()
    -- Register addon message prefixes
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX_REQUEST)
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX_RESPONSE)
    
    -- Set up message handler
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(self, event, prefix, payload, channel, sender)
        if event == "CHAT_MSG_ADDON" then
            Network:OnMessageReceivedEnhanced(prefix, payload, channel, sender)
        end
    end)
    
    -- Set up periodic broadcast ticker (every 60 seconds)
    C_Timer.NewTicker(60, function()
        Network:BroadcastStats()
    end)
    
    -- Set up cleanup ticker (every 5 minutes)
    C_Timer.NewTicker(300, function()
        Network:CleanupStaleData()
    end)
    
    self.initialized = true
    
    D("Network handler initialized - Addon v" .. PSC_GetAddonVersion())
    
    -- Send initial broadcast after a short delay
    C_Timer.After(5, function()
        Network:BroadcastStats()
        
        -- Show helpful message on first initialization
        if not PSC_DB.NetworkInitialized then
            PSC_DB.NetworkInitialized = true
            print("|cFFFFD700[PvP Stats Classic]|r Network sharing enabled!")
            print("|cFFFFD700[PvP Stats Classic]|r Your stats will be shared with nearby players, guild members, and group members who have the addon.")
            print("|cFFFFD700[PvP Stats Classic]|r Use |cFFFFFFFF/psc leaderboard|r to see the leaderboard with other players' stats.")
        end
    end)
end

-- Enable/disable debug mode
function Network:SetDebug(enabled)
    DEBUG = enabled
    if enabled then
        print("|cFFFFD700[PVPSC Network]|r Debug mode enabled")
    end
end

-- Build detailed statistics for a player (all kill data)
function Network:BuildDetailedStats()
    local charactersToProcess = GetCharactersToProcessForStatistics()
    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData, npcKillsData = 
        PSC_CalculateBarChartStatistics(charactersToProcess)
    local hourlyData = PSC_CalculateHourlyStatistics(charactersToProcess)
    local weekdayData = PSC_CalculateWeekdayStatistics(charactersToProcess)
    local monthlyData = PSC_CalculateMonthlyStatistics(charactersToProcess)
    local yearlyData = PSC_CalculateYearlyStatistics(charactersToProcess)
    
    D("Building detailed stats - currentKillStreak:", stats.currentKillStreak, "mostKilledPlayer:", stats.mostKilledPlayer)
    
    return {
        summary = stats,
        classData = classData,
        raceData = raceData,
        genderData = genderData,
        zoneData = zoneData,
        levelData = levelData,
        hourlyData = hourlyData,
        weekdayData = weekdayData,
        monthlyData = monthlyData,
        yearlyData = yearlyData,
        playerName = UnitName("player"),
        level = UnitLevel("player"),
        class = select(2, UnitClass("player")),
        race = select(2, UnitRace("player")),
        timestamp = time()
    }
end

-- Serialize detailed stats with compression
local function SerializeDetailedStats(data)
    -- Simple JSON-like serialization
    local str = ""
    for k, v in pairs(data) do
        if type(v) == "table" then
            str = str .. k .. ":"
            for k2, v2 in pairs(v) do
                str = str .. tostring(k2) .. "=" .. tostring(v2) .. ","
            end
            str = str .. ";"
        else
            str = str .. k .. ":" .. tostring(v) .. ";"
        end
    end
    return str
end

-- Deserialize detailed stats
local function DeserializeDetailedStats(payload)
    -- Parse the serialized format back into a table
    local data = {}
    for field in string.gmatch(payload, "([^;]+)") do
        local key, values = string.match(field, "([^:]+):(.*)")
        if key and values then
            if string.find(values, "=") then
                -- It's a table
                data[key] = {}
                for pair in string.gmatch(values, "([^,]+)") do
                    local k, v = string.match(pair, "([^=]+)=([^=]+)")
                    if k and v then
                        -- Try to convert to number
                        local num = tonumber(v)
                        data[key][k] = num or v
                    end
                end
            else
                -- Simple value
                local num = tonumber(values)
                data[key] = num or values
            end
        end
    end
    return data
end

-- Request detailed stats from a player
function Network:RequestDetailedStats(playerName, callback)
    if not playerName or playerName == "" then
        D("Invalid player name for request")
        return false
    end
    
    D("=== RequestDetailedStats called for:", playerName)
    
    -- Check if we already have cached data
    if self.detailedStatsCache[playerName] then
        local age = time() - (self.detailedStatsCache[playerName].timestamp or 0)
        if age < 300 then  -- Cache for 5 minutes
            D("Using cached detailed stats for", playerName)
            if callback then
                callback(self.detailedStatsCache[playerName])
            end
            return true
        end
    end
    
    -- Check if there's already a pending request
    if self.pendingRequests[playerName] then
        D("Request already pending for", playerName)
        -- Add callback to existing request
        if callback then
            table.insert(self.pendingRequests[playerName].callbacks, callback)
        end
        return true
    end
    
    D("Creating new request for", playerName)
    
    -- Create new request
    self.pendingRequests[playerName] = {
        timestamp = time(),
        callbacks = callback and {callback} or {},
        chunks = {},
        expectedChunks = 0
    }
    
    -- Send request
    local requestData = UnitName("player") .. "|" .. playerName
    
    -- Try multiple channels
    if IsInGuild() then
        C_ChatInfo.SendAddonMessage(PREFIX_REQUEST, requestData, "GUILD")
        D("Sent detailed stats request to GUILD for", playerName)
    end
    
    if IsInRaid() then
        C_ChatInfo.SendAddonMessage(PREFIX_REQUEST, requestData, "RAID")
        D("Sent detailed stats request to RAID for", playerName)
    elseif IsInGroup() then
        C_ChatInfo.SendAddonMessage(PREFIX_REQUEST, requestData, "PARTY")
        D("Sent detailed stats request to PARTY for", playerName)
    end
    
    C_ChatInfo.SendAddonMessage(PREFIX_REQUEST, requestData, "YELL")
    D("Sent detailed stats request to YELL for", playerName)
    
    -- Set timeout
    C_Timer.After(self.REQUEST_TIMEOUT, function()
        if self.pendingRequests[playerName] then
            D("Request timeout for", playerName)
            -- Call callbacks with nil to indicate failure
            for _, cb in ipairs(self.pendingRequests[playerName].callbacks) do
                cb(nil)
            end
            self.pendingRequests[playerName] = nil
        end
    end)
    
    return true
end

-- Handle detailed stats request
function Network:OnDetailedStatsRequest(requester, targetPlayer)
    local playerName = UnitName("player")
    
    -- Check if this request is for us
    if targetPlayer ~= playerName then
        return
    end
    
    D("Received detailed stats request from", requester)
    
    -- Build detailed stats
    local detailedStats = self:BuildDetailedStats()
    local payload = SerializeDetailedStats(detailedStats)
    
    D("Payload size:", #payload, "bytes")
    
    -- Split into chunks if needed
    local chunks = {}
    local chunkSize = self.CHUNK_SIZE
    for i = 1, #payload, chunkSize do
        table.insert(chunks, string.sub(payload, i, i + chunkSize - 1))
    end
    
    D("Sending", #chunks, "chunks")
    
    -- Send chunks with delays to avoid flooding
    local function sendChunk(index)
        if index > #chunks then
            D("All chunks sent")
            return
        end
        
        local chunk = chunks[index]
        local response = playerName .. "|" .. index .. "|" .. #chunks .. "|" .. chunk
        
        -- Try to send via available channels
        if IsInGuild() then
            C_ChatInfo.SendAddonMessage(PREFIX_RESPONSE, response, "GUILD")
        end
        if IsInRaid() then
            C_ChatInfo.SendAddonMessage(PREFIX_RESPONSE, response, "RAID")
        elseif IsInGroup() then
            C_ChatInfo.SendAddonMessage(PREFIX_RESPONSE, response, "PARTY")
        end
        C_ChatInfo.SendAddonMessage(PREFIX_RESPONSE, response, "YELL")
        
        D("Sent chunk", index, "of", #chunks)
        
        -- Schedule next chunk
        if index < #chunks then
            C_Timer.After(0.1, function()
                sendChunk(index + 1)
            end)
        end
    end
    
    -- Start sending chunks
    sendChunk(1)
    
    D("Sent detailed stats response in", #chunks, "chunks to", requester)
end

-- Handle detailed stats response chunk
function Network:OnDetailedStatsResponse(playerName, chunkIndex, totalChunks, chunkData)
    if not self.pendingRequests[playerName] then
        -- Not expecting data from this player
        return
    end
    
    local request = self.pendingRequests[playerName]
    
    -- Store chunk
    request.chunks[chunkIndex] = chunkData
    request.expectedChunks = totalChunks
    
    D("Received chunk", chunkIndex, "of", totalChunks, "from", playerName)
    
    -- Check if we have all chunks
    local complete = true
    for i = 1, totalChunks do
        if not request.chunks[i] then
            complete = false
            break
        end
    end
    
    if complete then
        -- Reassemble payload
        local fullPayload = ""
        for i = 1, totalChunks do
            fullPayload = fullPayload .. request.chunks[i]
        end
        
        -- Deserialize
        local detailedStats = DeserializeDetailedStats(fullPayload)
        detailedStats.timestamp = time()
        
        -- Debug: Check what we received
        if detailedStats.summary then
            D("Received stats - currentKillStreak:", detailedStats.summary.currentKillStreak, "mostKilledPlayer:", detailedStats.summary.mostKilledPlayer)
        else
            D("WARNING: No summary in received stats!")
        end
        
        -- Cache the data
        self.detailedStatsCache[playerName] = detailedStats
        
        D("Received complete detailed stats from", playerName)
        
        -- Call all callbacks
        for _, callback in ipairs(request.callbacks) do
            callback(detailedStats)
        end
        
        -- Clear pending request
        self.pendingRequests[playerName] = nil
    end
end

-- Enhanced message handler
function Network:OnMessageReceivedEnhanced(prefix, payload, channel, sender)
    if prefix == PREFIX then
        -- Regular stats broadcast
        self:OnMessageReceived(prefix, payload, channel, sender)
    elseif prefix == PREFIX_REQUEST then
        -- Detailed stats request
        local requester, targetPlayer = string.match(payload, "([^|]+)|([^|]+)")
        if requester and targetPlayer then
            self:OnDetailedStatsRequest(requester, targetPlayer)
        end
    elseif prefix == PREFIX_RESPONSE then
        -- Detailed stats response
        local playerName, chunkIndex, totalChunks, chunkData = string.match(payload, "([^|]+)|(%d+)|(%d+)|(.*)")
        if playerName and chunkIndex and totalChunks and chunkData then
            self:OnDetailedStatsResponse(playerName, tonumber(chunkIndex), tonumber(totalChunks), chunkData)
        end
    end
end

-- Get network status information
function Network:GetNetworkStatus()
    local status = {
        isInitialized = self.initialized or false,
        lastBroadcast = self.lastBroadcast,
        timeSinceLastBroadcast = time() - self.lastBroadcast,
        nextBroadcastIn = math.max(0, self.BROADCAST_INTERVAL - (time() - self.lastBroadcast)),
        playersTracked = 0,
        addonVersion = PSC_GetAddonVersion(),
        inGuild = IsInGuild(),
        inRaid = IsInRaid(),
        inParty = IsInGroup()
    }
    
    -- Count active players
    for name, data in pairs(self.sharedData) do
        local age = time() - (data.timestamp or 0)
        if age < self.DATA_TTL then
            status.playersTracked = status.playersTracked + 1
        end
    end
    
    return status
end

-- Print network status to chat
function Network:PrintStatus()
    local status = self:GetNetworkStatus()
    
    print("|cFFFFD700[PVPSC Network Status]|r")
    print("Addon Version: v" .. status.addonVersion)
    print("Players Tracked: " .. status.playersTracked)
    print("Next Broadcast: " .. status.nextBroadcastIn .. " seconds")
    print("In Guild: " .. (status.inGuild and "Yes" or "No"))
    print("In Raid: " .. (status.inRaid and "Yes" or "No"))
    print("In Party: " .. (status.inParty and "Yes" or "No"))
    
    if status.playersTracked == 0 then
        print("|cFFFF6B6BNote:|r No other players detected yet.")
        print("Other players need to:")
        print("  1. Have PvP Stats Classic addon installed")
        print("  2. Be nearby, in your guild, or in your group")
    end
end
