local addonName, PVPSC = ...

-- Load AceComm library
local AceComm = LibStub("AceComm-3.0")

PVPSC.Network = PVPSC.Network or {}
local Network = PVPSC.Network

-- Embed AceComm into Network object
AceComm:Embed(Network)

-- Network configuration
local PREFIX = "PVPSC"  -- Single prefix for all messages

-- Shared data cache: stores other players' stats
Network.sharedData = Network.sharedData or {}
Network.detailedStatsCache = Network.detailedStatsCache or {}  -- Cache for detailed stats
Network.DATA_TTL = 600  -- Consider data stale after 10 minutes (600 seconds)
Network.MIN_BROADCAST_INTERVAL = 5 -- Minimum seconds between broadcasts to prevent throttling

-- Deduplication cache to prevent processing the same message multiple times
local recentMessages = {}
local RECENT_TTL = 300  -- 5 minutes

local function D(...)
    if PSC_Debug then
        print("|cFFFFD700[PVPSC Network]|r", ...)
    end
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

-- Key mapping for compression
local KEY_MAP = {
    summary = "S",
    classData = "CD",
    raceData = "RD",
    genderData = "GD",
    zoneData = "ZD",
    levelData = "LD",
    hourlyData = "H",
    weekdayData = "W",
    monthlyData = "M",
    yearlyData = "Y",
    unknownLevelClassData = "UL",
    guildStatusData = "GS",
    npcKillsData = "NK",
    playerName = "pn",
    level = "l",
    class = "c",
    race = "r",
    faction = "f",
    timestamp = "t",
    addonVersion = "av",
    achievementsUnlocked = "au",
    totalAchievements = "ta",
    achievementPoints = "ap"
}
local REVERSE_KEY_MAP = {}
for k, v in pairs(KEY_MAP) do REVERSE_KEY_MAP[v] = k end

-- Serialize detailed stats with compression
local function SerializeDetailedStats(data)
    -- Simple JSON-like serialization with short keys
    local str = ""
    for k, v in pairs(data) do
        -- Use short key if available, otherwise original
        local key = KEY_MAP[k] or k

        if type(v) == "table" then
            str = str .. key .. ":"
            for k2, v2 in pairs(v) do
                str = str .. tostring(k2) .. "=" .. tostring(v2) .. ","
            end
            str = str .. ";"
        else
            str = str .. key .. ":" .. tostring(v) .. ";"
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
            -- Restore original long key if it was compressed
            key = REVERSE_KEY_MAP[key] or key

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

-- Check if the network is currently throttled (BULK queue has pending messages)
function Network:IsThrottled()
    -- ChatThrottleLib is used by AceComm
    if ChatThrottleLib and ChatThrottleLib.Prio and ChatThrottleLib.Prio["BULK"] and ChatThrottleLib.Prio["BULK"].Ring then
        -- If Ring.pos is not nil, there are items in the ring (queue not empty)
        if ChatThrottleLib.Prio["BULK"].Ring.pos then
            return true
        end
    end
    return false
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

    -- Calculate achievement stats
    local achievementsUnlocked = 0
    local totalAchievements = 0
    local achievementPoints = 0

    if PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements then
        totalAchievements = #PVPSC.AchievementSystem.achievements
        local currentCharacterKey = PSC_GetCharacterKey()

        if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[currentCharacterKey] then
            for _, achievementData in pairs(PSC_DB.CharacterAchievements[currentCharacterKey]) do
                if achievementData.unlocked then
                    achievementsUnlocked = achievementsUnlocked + 1
                end
            end
        end

        achievementPoints = PSC_DB.CharacterAchievementPoints[currentCharacterKey] or 0
    end

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
        unknownLevelClassData = unknownLevelClassData,
        guildStatusData = guildStatusData,
        npcKillsData = npcKillsData,
        -- Note: guildData intentionally excluded to reduce payload size
        playerName = UnitName("player"),
        level = UnitLevel("player"),
        class = select(2, UnitClass("player")),
        race = select(2, UnitRace("player")),
        faction = UnitFactionGroup("player") or "",
        timestamp = time(),
        addonVersion = "v" .. PSC_GetAddonVersion(),
        achievementsUnlocked = achievementsUnlocked,
        totalAchievements = totalAchievements,
        achievementPoints = achievementPoints
    }
end

-- Broadcast player stats
function Network:BroadcastStats()
    local now = GetTime()

    -- Check if we are broadcasting too frequently (time-based throttling)
    if self.lastBroadcastTime and (now - self.lastBroadcastTime < self.MIN_BROADCAST_INTERVAL) then
        -- We are too early. Queue a Deferred broadcast if one isn't already scheduled.
        if not self.deferredBroadcastTimer then
            local delay = self.MIN_BROADCAST_INTERVAL - (now - self.lastBroadcastTime)
            -- Ensure delay is positive and reasonable
            if delay < 0.1 then delay = 0.1 end

            if PSC_Debug then
                print("|cFFFFD700[PVPSC Network]|r Too many updates. Deferring broadcast by " .. string.format("%.1f", delay) .. "s")
            end

            self.deferredBroadcastTimer = C_Timer.NewTimer(delay, function()
                self.deferredBroadcastTimer = nil
                self:BroadcastStats()
            end)
        end
        return
    end

    -- If we are throttled by the game client/library (bandwidth limit), defer this update
    if self:IsThrottled() then
        if PSC_Debug then
            print("|cFFFFD700[PVPSC Network]|r Network throttled (BULK queue full), deferring broadcast...")
        end

        -- Schedule a retry if not already scheduled
        if not self.retryTimer then
            self.retryTimer = C_Timer.NewTimer(2.0, function()
                self.retryTimer = nil
                self:BroadcastStats()
            end)
        end
        return
    end

    self.lastBroadcastTime = now

    -- Always build full detailed stats
    local detailedStats = self:BuildDetailedStats()

    -- Serialize
    local payload = SerializeDetailedStats(detailedStats)
    payload = "FULL|" .. payload

    D("Broadcasting FULL stats via AceComm (Size: " .. #payload .. " bytes)")

    -- Priority BULK for large data
    local priority = "BULK"

    -- Send to appropriate channels
    if IsInGuild() then
        self:SendCommMessage(PREFIX, payload, "GUILD", nil, priority)
    end

    if IsInRaid() then
        self:SendCommMessage(PREFIX, payload, "RAID", nil, priority)
    elseif IsInGroup() then
        self:SendCommMessage(PREFIX, payload, "PARTY", nil, priority)
    end

    -- Send to interactions in instance
    local inInstance, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        self:SendCommMessage(PREFIX, payload, "INSTANCE_CHAT", nil, priority)
    end

    -- Also yell if not in group/guild to share with others nearby
    if not IsInGroup() and not IsInGuild() then
         self:SendCommMessage(PREFIX, payload, "YELL", nil, priority)
    end

    -- Refresh local leaderboard if open (since we updated our own stats which triggered this broadcast)
    if RefreshLeaderboardFrame and PSC_LeaderboardFrame and PSC_LeaderboardFrame:IsShown() then
        RefreshLeaderboardFrame()
    end
end

-- Handle received communications
function Network:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end
    if sender == UnitName("player") then return end

    local msgType, data = message:match("^([^|]+)|(.*)$")

    -- Handle different message types
    if msgType == "FULL" then
        -- New Full Stats broadcast
        local statsData = DeserializeDetailedStats(data)

        if not statsData then
            D("Failed to deserialize message (" .. msgType .. ") from", sender)
            return
        end

        -- Flatten summary for backward compatibility with leaderboard code
        -- The leaderboard expects fields like 'totalKills' at the root
        if statsData.summary then
            for k, v in pairs(statsData.summary) do
                statsData[k] = v
            end
        end

        -- Validate data
        if not statsData.playerName or statsData.playerName == "" then
            D("Invalid data: missing player name")
            return
        end

        -- Check for duplicates
        if IsDuplicate(statsData.playerName, statsData.timestamp) then
            D("Duplicate message from", statsData.playerName)
            return
        end

        -- Update caches
        self.detailedStatsCache[statsData.playerName] = statsData
        self.sharedData[statsData.playerName] = statsData

        D("Received detailed stats from", statsData.playerName, "via", distribution, "- Kills:", statsData.totalKills)

        -- Refresh leaderboard if it's open
        if PSC_LeaderboardFrame and PSC_LeaderboardFrame:IsShown() then
            RefreshLeaderboardFrame()
        end

    elseif msgType == "SYNC" then
        -- Sync request - broadcast our stats immediately
        D("Received sync request from", sender, "via", distribution)

        -- Prevent multiple responses to the same sync event (e.g. receiving via GUILD and PARTY)
        if self.syncResponsePending then
            D("Ignoring duplicate SYNC request from", sender, "via", distribution, "- response already pending")
            return
        end

        self.syncResponsePending = true

        -- Broadcast after a short random delay to avoid network spam if many players respond at once
        C_Timer.After(math.random() * 2, function()
            self.syncResponsePending = false
            self:BroadcastStats()
        end)
    end
end

-- Get cached detailed stats for a player
function Network:GetDetailedStatsForPlayer(playerName)
    if self.detailedStatsCache and self.detailedStatsCache[playerName] then
        return self.detailedStatsCache[playerName]
    end
    -- Fallback to shared data if available
    if self.sharedData and self.sharedData[playerName] then
        return self.sharedData[playerName]
    end
    return nil
end

-- Get all leaderboard data (local + shared)
function Network:GetAllLeaderboardData()
    local leaderboardData = {}
    local now = time()
    local playerName = UnitName("player")

    -- Add local player's data first
    local localStats = self:BuildDetailedStats()
    if localStats then
        -- Flatten summary for display compatibility
        if localStats.summary then
            for k, v in pairs(localStats.summary) do
                localStats[k] = v
            end
        end
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
    -- Register AceComm prefix and callback
    self:RegisterComm(PREFIX, "OnCommReceived")

    -- Periodic broadcast ticker removed in favor of event-based updates

    -- Set up cleanup ticker (every 5 minutes)
    C_Timer.NewTicker(300, function()
        Network:CleanupStaleData()
    end)

    self.initialized = true

    D("Network handler initialized with AceComm - Addon v" .. PSC_GetAddonVersion())

    -- Send sync request and immediate broadcast on login
    C_Timer.After(2, function()
        -- Request all other players to broadcast their stats
        local syncRequest = "SYNC|" .. UnitName("player")
        if IsInGuild() then
            self:SendCommMessage(PREFIX, syncRequest, "GUILD", nil, "NORMAL")
        end
        if IsInRaid() then
            self:SendCommMessage(PREFIX, syncRequest, "RAID", nil, "NORMAL")
        elseif IsInGroup() then
            self:SendCommMessage(PREFIX, syncRequest, "PARTY", nil, "NORMAL")
        end

        -- Try to yell to nearby players
        self:SendCommMessage(PREFIX, syncRequest, "YELL", nil, "NORMAL")

        D("Sent sync request to all channels")

        -- Also broadcast our own stats immediately
        Network:BroadcastStats()
        D("Sent initial broadcast on login")

        -- Show helpful message on first initialization
        if not PSC_DB.NetworkInitialized then
            PSC_DB.NetworkInitialized = true
            print("|cFFFFD700[PvP Stats Classic]|r Network sharing enabled! Stats will be broadcast automatically.")
        end
    end)
end
