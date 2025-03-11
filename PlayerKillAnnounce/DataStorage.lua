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

    -- Handle unknown level players - use -1 instead of defaulting to level 1
    if level == 0 then
        level = -1  -- Use -1 to represent unknown level (will show as "??")
    end

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
    -- Make sure we have a saved variables table
    PlayerKillAnnounceDB = PlayerKillAnnounceDB or {}

    PlayerKillAnnounceDB.PKA_EnableKillAnnounce = PKA_EnableKillAnnounce
    PlayerKillAnnounceDB.PKA_KillAnnounceMessage = PKA_KillAnnounceMessage
    PlayerKillAnnounceDB.PKA_KillCounts = PKA_KillCounts

    -- Store streak data
    PlayerKillAnnounceDB.PKA_CurrentKillStreak = PKA_CurrentKillStreak
    PlayerKillAnnounceDB.PKA_HighestKillStreak = PKA_HighestKillStreak
    PlayerKillAnnounceDB.PKA_HighestMultiKill = PKA_HighestMultiKill

    -- Store custom messages
    PlayerKillAnnounceDB.PKA_KillStreakEndedMessage = PKA_KillStreakEndedMessage
    PlayerKillAnnounceDB.PKA_NewStreakRecordMessage = PKA_NewStreakRecordMessage
    PlayerKillAnnounceDB.PKA_NewMultiKillRecordMessage = PKA_NewMultiKillRecordMessage

    -- Store new record announce preference
    PlayerKillAnnounceDB.PKA_EnableRecordAnnounce = PKA_EnableRecordAnnounce

    -- Store multi-kill threshold setting
    PlayerKillAnnounceDB.PKA_MultiKillThreshold = PKA_MultiKillThreshold

    -- Store player info cache
    PlayerKillAnnounceDB.PlayerInfoCache = PlayerInfoCache
end

function PKA_LoadSettings()
    if PlayerKillAnnounceDB then
        -- Load existing kill announcement settings
        if PlayerKillAnnounceDB.PKA_EnableKillAnnounce ~= nil then
            PKA_EnableKillAnnounce = PlayerKillAnnounceDB.PKA_EnableKillAnnounce
        else
            PKA_EnableKillAnnounce = true
        end

        PKA_KillAnnounceMessage = PlayerKillAnnounceDB.PKA_KillAnnounceMessage or PlayerKillMessageDefault
        PKA_KillCounts = PlayerKillAnnounceDB.PKA_KillCounts or {}

        -- Load streak data
        PKA_CurrentKillStreak = PlayerKillAnnounceDB.PKA_CurrentKillStreak or 0
        PKA_HighestKillStreak = PlayerKillAnnounceDB.PKA_HighestKillStreak or 0
        PKA_HighestMultiKill = PlayerKillAnnounceDB.PKA_HighestMultiKill or 0

        -- Load custom messages with defaults if not set
        PKA_KillStreakEndedMessage = PlayerKillAnnounceDB.PKA_KillStreakEndedMessage or KillStreakEndedMessageDefault
        PKA_NewStreakRecordMessage = PlayerKillAnnounceDB.PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault
        PKA_NewMultiKillRecordMessage = PlayerKillAnnounceDB.PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault

        -- Load record announcement setting
        if PlayerKillAnnounceDB.PKA_EnableRecordAnnounce ~= nil then
            PKA_EnableRecordAnnounce = PlayerKillAnnounceDB.PKA_EnableRecordAnnounce
        else
            PKA_EnableRecordAnnounce = true
        end

        -- Load multi-kill threshold setting
        if PlayerKillAnnounceDB.PKA_MultiKillThreshold ~= nil then
            PKA_MultiKillThreshold = PlayerKillAnnounceDB.PKA_MultiKillThreshold
        else
            PKA_MultiKillThreshold = 3  -- Default to Triple Kill if not set
        end

        -- Load player info cache
        PlayerInfoCache = PlayerKillAnnounceDB.PlayerInfoCache or {}
    else
        -- Initialize with defaults if no saved variables exist
        PKA_EnableKillAnnounce = true
        PKA_KillAnnounceMessage = PlayerKillMessageDefault
        PKA_KillCounts = {}
        PKA_CurrentKillStreak = 0
        PKA_HighestKillStreak = 0
        PKA_HighestMultiKill = 0
        PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault
        PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault
        PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault
        PKA_EnableRecordAnnounce = true
        PKA_MultiKillThreshold = 3  -- Default to Triple Kill
        PlayerInfoCache = {}
    end

    -- Reset temporary values
    PKA_MultiKillCount = 0
    PKA_LastCombatTime = 0
end
