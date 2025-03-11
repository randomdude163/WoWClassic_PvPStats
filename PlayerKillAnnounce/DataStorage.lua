-- Player info cache to store data we collect from various sources
local PlayerInfoCache = {}

-- Function to update player info cache
function PKA_UpdatePlayerInfoCache(name, guid, level, class, race, gender, guild)
    if not name then return end

    PlayerInfoCache[name] = PlayerInfoCache[name] or {}

    -- Only update fields if the new information is valid
    if guid and guid ~= "" then
        PlayerInfoCache[name].guid = guid
    end

    if level and level > 0 then
        PlayerInfoCache[name].level = level
    end

    if class and class ~= "" then
        PlayerInfoCache[name].class = class
    end

    if race and race ~= "" then
        PlayerInfoCache[name].race = race
    end

    if gender and gender ~= nil then
        PlayerInfoCache[name].gender = gender
    end

    if guild and guild ~= "" then
        PlayerInfoCache[name].guild = guild
    end
end

-- Function to collect player info from unit
function PKA_CollectPlayerInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    local name = UnitName(unit)
    if not name then return end

    local guid = UnitGUID(unit)
    local level = UnitLevel(unit)
    local _, englishClass = UnitClass(unit)
    local _, englishRace = UnitRace(unit)
    local gender = UnitSex(unit)

    -- Get guild information
    local guildName, _, _ = GetGuildInfo(unit)

    PKA_UpdatePlayerInfoCache(name, guid, level, englishClass, englishRace, gender, guildName)
end

-- Function to get best available player info
function PKA_GetPlayerInfo(name, guid)
    local level = 0
    local class = "Unknown"
    local race = "Unknown"
    local gender = 0
    local guild = ""

    -- Check if we have cached info
    if PlayerInfoCache[name] then
        level = PlayerInfoCache[name].level or 0
        class = PlayerInfoCache[name].class or "Unknown"
        race = PlayerInfoCache[name].race or "Unknown"
        gender = PlayerInfoCache[name].gender or 0
        guild = PlayerInfoCache[name].guild or ""
    end

    -- If we still don't have valid info, try other methods
    if level == 0 or class == "Unknown" or race == "Unknown" then
        -- Check target and mouseover in case it's the same player
        if UnitExists("target") and UnitName("target") == name then
            level = UnitLevel("target") or level
            local _, englishClass = UnitClass("target")
            class = englishClass or class
            local _, englishRace = UnitRace("target")
            race = englishRace or race
            gender = UnitSex("target") or gender
            local guildName = GetGuildInfo("target")
            guild = guildName or guild
        elseif UnitExists("mouseover") and UnitName("mouseover") == name then
            level = UnitLevel("mouseover") or level
            local _, englishClass = UnitClass("mouseover")
            class = englishClass or class
            local _, englishRace = UnitRace("mouseover")
            race = englishRace or race
            gender = UnitSex("mouseover") or gender
            local guildName = GetGuildInfo("mouseover")
            guild = guildName or guild
        end

        -- Last resort - try to get from GUID
        if guid and guid ~= "" then
            local _, englishClass = GetPlayerInfoByGUID(guid)
            if englishClass then
                class = englishClass
            end
        end
    end

    -- Default to level 1 if we still couldn't detect it
    level = level > 0 and level or 1

    -- Convert gender number to string representation
    local genderStr = "Unknown"
    if gender == 1 then
        genderStr = "Unknown"
    elseif gender == 2 then
        genderStr = "Male"
    elseif gender == 3 then
        genderStr = "Female"
    end

    return level, class, race, genderStr, guild
end

function PKA_SaveSettings()
    PlayerKillAnnounceDB.PKA_EnableKillAnnounce = PKA_EnableKillAnnounce
    PlayerKillAnnounceDB.PKA_KillAnnounceMessage = PKA_KillAnnounceMessage
    PlayerKillAnnounceDB.PKA_KillCounts = PKA_KillCounts
    -- Store streak data
    PlayerKillAnnounceDB.PKA_CurrentKillStreak = PKA_CurrentKillStreak
    PlayerKillAnnounceDB.PKA_HighestKillStreak = PKA_HighestKillStreak
    PlayerKillAnnounceDB.PKA_HighestMultiKill = PKA_HighestMultiKill
    -- Store new record announce preference
    PlayerKillAnnounceDB.PKA_EnableRecordAnnounce = PKA_EnableRecordAnnounce
    -- Store custom messages
    PlayerKillAnnounceDB.PKA_KillStreakEndedMessage = PKA_KillStreakEndedMessage
    PlayerKillAnnounceDB.PKA_NewStreakRecordMessage = PKA_NewStreakRecordMessage
    PlayerKillAnnounceDB.PKA_NewMultiKillRecordMessage = PKA_NewMultiKillRecordMessage
end

function PKA_LoadSettings()
    if PlayerKillAnnounceDB then
        PKA_EnableKillAnnounce = PlayerKillAnnounceDB.PKA_EnableKillAnnounce or true
        PKA_KillAnnounceMessage = PlayerKillAnnounceDB.PKA_KillAnnounceMessage or PlayerKillMessageDefault

        -- Load streak data
        PKA_CurrentKillStreak = PlayerKillAnnounceDB.PKA_CurrentKillStreak or 0
        PKA_HighestKillStreak = PlayerKillAnnounceDB.PKA_HighestKillStreak or 0
        PKA_HighestMultiKill = PlayerKillAnnounceDB.PKA_HighestMultiKill or 0

        -- Load record announcement setting
        PKA_EnableRecordAnnounce = PlayerKillAnnounceDB.PKA_EnableRecordAnnounce
        if PKA_EnableRecordAnnounce == nil then PKA_EnableRecordAnnounce = true end

        -- Load custom messages
        PKA_KillStreakEndedMessage = PlayerKillAnnounceDB.PKA_KillStreakEndedMessage or KillStreakEndedMessageDefault
        PKA_NewStreakRecordMessage = PlayerKillAnnounceDB.PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault
        PKA_NewMultiKillRecordMessage = PlayerKillAnnounceDB.PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault

        -- Reset temporary counters
        PKA_MultiKillCount = 0
        PKA_LastCombatTime = 0

        -- Debug message to verify values are loading correctly
        print("Loaded kill statistics - Current streak: " .. PKA_CurrentKillStreak ..
              ", Highest streak: " .. PKA_HighestKillStreak ..
              ", Highest multi-kill: " .. PKA_HighestMultiKill)

        PKA_MultiKillCount = 0 -- Always reset multi-kill count on login
        PKA_LastCombatTime = 0 -- Track the last combat time for multi-kills

        -- Handle upgrade path for older versions without level tracking
        if PlayerKillAnnounceDB.PKA_KillCounts then
            local needsUpgrade = false
            for name, data in pairs(PlayerKillAnnounceDB.PKA_KillCounts) do
                if not string.find(name, ":") then
                    needsUpgrade = true
                    break
                end
            end

            if needsUpgrade then
                local upgradedKills = {}
                for name, data in pairs(PlayerKillAnnounceDB.PKA_KillCounts) do
                    -- Add with level 0 (unknown) for older entries
                    local nameWithLevel = name .. ":0"
                    upgradedKills[nameWithLevel] = data
                end
                PlayerKillAnnounceDB.PKA_KillCounts = upgradedKills
            end
        end

        PKA_KillCounts = PlayerKillAnnounceDB.PKA_KillCounts or {}

        -- Load record announcement setting
        PKA_EnableRecordAnnounce = PlayerKillAnnounceDB.PKA_EnableRecordAnnounce
        if PKA_EnableRecordAnnounce == nil then PKA_EnableRecordAnnounce = true end
    else
        PlayerKillAnnounceDB = {
            PKA_EnableKillAnnounce = true,
            PKA_KillAnnounceMessage = PlayerKillMessageDefault,
            PKA_KillCounts = {},
            PKA_CurrentKillStreak = 0,
            PKA_HighestKillStreak = 0,
            PKA_HighestMultiKill = 0
        }
        PKA_KillCounts = PlayerKillAnnounceDB.PKA_KillCounts
        PKA_CurrentKillStreak = 0
        PKA_HighestKillStreak = 0
        PKA_HighestMultiKill = 0
        PKA_MultiKillCount = 0
        PKA_LastCombatTime = 0
    end
end
