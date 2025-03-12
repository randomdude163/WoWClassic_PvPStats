-- Player info cache to store data we collect from various sources
local PlayerInfoCache = {}

-- Function to update player info cache
function PKA_UpdatePlayerInfoCache(name, guid, level, class, race, gender, guild)
    if not name then return end

    PlayerInfoCache[name] = PlayerInfoCache[name] or {}
    local playerData = PlayerInfoCache[name]

    if guid and guid ~= "" then playerData.guid = guid end
    if level and level > 0 then playerData.level = level end
    if class and class ~= "" then playerData.class = class end
    if race and race ~= "" then playerData.race = race end
    if gender and gender ~= nil then playerData.gender = gender end
    if guild and guild ~= "" then playerData.guild = guild end
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
    local guildName = GetGuildInfo(unit)

    PKA_UpdatePlayerInfoCache(name, guid, level, englishClass, englishRace, gender, guildName)
end

function PKA_GetInfoFromCachedPlayer(name)
    if not PlayerInfoCache[name] then
        return 0, "Unknown", "Unknown", 0, ""
    end

    local data = PlayerInfoCache[name]
    return data.level or 0,
           data.class or "Unknown",
           data.race or "Unknown",
           data.gender or 0,
           data.guild or ""
end

function PKA_GetInfoFromActiveUnit(name, unitId)
    if not UnitExists(unitId) or UnitName(unitId) ~= name then
        return 0, "Unknown", "Unknown", 0, ""
    end

    local level = UnitLevel(unitId)
    local _, englishClass = UnitClass(unitId)
    local _, englishRace = UnitRace(unitId)
    local gender = UnitSex(unitId)
    local guildName = GetGuildInfo(unitId)

    return level, englishClass, englishRace, gender, guildName
end

function PKA_GetInfoFromGuid(guid)
    if not guid or guid == "" then
        return "Unknown"
    end

    local _, englishClass = GetPlayerInfoByGUID(guid)
    return englishClass or "Unknown"
end

function PKA_ConvertGenderToString(genderCode)
    if genderCode == 2 then return "Male"
    elseif genderCode == 3 then return "Female"
    else return "Unknown" end
end

-- Function to get best available player info
function PKA_GetPlayerInfo(name, guid)
    local level, class, race, gender, guild = PKA_GetInfoFromCachedPlayer(name)

    if level == 0 or class == "Unknown" or race == "Unknown" then
        -- Try target unit
        local targetLevel, targetClass, targetRace, targetGender, targetGuild =
            PKA_GetInfoFromActiveUnit(name, "target")

        level = (targetLevel > 0) and targetLevel or level
        class = (targetClass ~= "Unknown") and targetClass or class
        race = (targetRace ~= "Unknown") and targetRace or race
        gender = (targetGender > 0) and targetGender or gender
        guild = (targetGuild ~= "") and targetGuild or guild

        -- Try mouseover unit
        local mouseLevel, mouseClass, mouseRace, mouseGender, mouseGuild =
            PKA_GetInfoFromActiveUnit(name, "mouseover")

        level = (mouseLevel > 0) and mouseLevel or level
        class = (mouseClass ~= "Unknown") and mouseClass or class
        race = (mouseRace ~= "Unknown") and mouseRace or race
        gender = (mouseGender > 0) and mouseGender or gender
        guild = (mouseGuild ~= "") and mouseGuild or guild

        -- Try GUID as last resort for class info
        if class == "Unknown" then
            class = PKA_GetInfoFromGuid(guid)
        end
    end

    -- Set unknown level to -1 (will show as "??")
    if level == 0 then level = -1 end

    return level, class, race, PKA_ConvertGenderToString(gender), guild
end

-- Regular saving function without cleanup operations
function PKA_SaveSettings()
    -- Make sure we have a saved variables table
    PlayerKillAnnounceDB = PlayerKillAnnounceDB or {}
    local db = PlayerKillAnnounceDB

    db.PKA_EnableKillAnnounce = PKA_EnableKillAnnounce
    db.PKA_KillAnnounceMessage = PKA_KillAnnounceMessage
    db.PKA_KillCounts = PKA_KillCounts
    db.PKA_CurrentKillStreak = PKA_CurrentKillStreak
    db.PKA_HighestKillStreak = PKA_HighestKillStreak
    db.PKA_HighestMultiKill = PKA_HighestMultiKill
    db.PKA_KillStreakEndedMessage = PKA_KillStreakEndedMessage
    db.PKA_NewStreakRecordMessage = PKA_NewStreakRecordMessage
    db.PKA_NewMultiKillRecordMessage = PKA_NewMultiKillRecordMessage
    db.PKA_EnableRecordAnnounce = PKA_EnableRecordAnnounce
    db.PKA_MultiKillThreshold = PKA_MultiKillThreshold
    db.PlayerInfoCache = PlayerInfoCache
end

function PKA_IsValidPlayerData(data)
    return data.kills and data.kills > 0 and
           data.race and data.race ~= "Unknown" and
           data.gender and data.gender ~= "Unknown" and
           data.class and data.class ~= "Unknown"
end

function PKA_IsUsefulCacheEntry(data)
    return (data.race and data.race ~= "") or
           (data.gender and data.gender > 0) or
           (data.class and data.class ~= "")
end

-- Separate cleanup function to be called only on logout
function PKA_CleanupKillCounts()
    local cleanedKillCounts = {}

    for nameWithLevel, data in pairs(PKA_KillCounts) do
        if PKA_IsValidPlayerData(data) then
            cleanedKillCounts[nameWithLevel] = data
        end
    end

    PlayerKillAnnounceDB.PKA_KillCounts = cleanedKillCounts
    PKA_KillCounts = cleanedKillCounts
end

function PKA_CleanupPlayerInfoCache()
    local cleanedInfoCache = {}

    for name, data in pairs(PlayerInfoCache) do
        if PKA_IsUsefulCacheEntry(data) then
            cleanedInfoCache[name] = data
        end
    end

    PlayerKillAnnounceDB.PlayerInfoCache = cleanedInfoCache
    PlayerInfoCache = cleanedInfoCache
end

function PKA_CleanupDatabase()
    PKA_CleanupKillCounts()
    PKA_CleanupPlayerInfoCache()
    print("PlayerKillAnnounce: Database cleaned up.")
end

function PKA_InitializeDefaults()
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
    PKA_MultiKillThreshold = 3
    PlayerInfoCache = {}
end

function PKA_LoadSettingsFromDB()
    local db = PlayerKillAnnounceDB

    PKA_EnableKillAnnounce = db.PKA_EnableKillAnnounce ~= nil and db.PKA_EnableKillAnnounce or true
    PKA_KillAnnounceMessage = db.PKA_KillAnnounceMessage or PlayerKillMessageDefault
    PKA_KillCounts = db.PKA_KillCounts or {}
    PKA_CurrentKillStreak = db.PKA_CurrentKillStreak or 0
    PKA_HighestKillStreak = db.PKA_HighestKillStreak or 0
    PKA_HighestMultiKill = db.PKA_HighestMultiKill or 0
    PKA_KillStreakEndedMessage = db.PKA_KillStreakEndedMessage or KillStreakEndedMessageDefault
    PKA_NewStreakRecordMessage = db.PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault
    PKA_NewMultiKillRecordMessage = db.PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault
    PKA_EnableRecordAnnounce = db.PKA_EnableRecordAnnounce ~= nil and db.PKA_EnableRecordAnnounce or true
    PKA_MultiKillThreshold = db.PKA_MultiKillThreshold or 3
    PlayerInfoCache = db.PlayerInfoCache or {}
end

function PKA_LoadSettings()
    if PlayerKillAnnounceDB then
        PKA_LoadSettingsFromDB()
    else
        PKA_InitializeDefaults()
    end

    -- Reset temporary values
    PKA_MultiKillCount = 0
    PKA_LastCombatTime = 0
end
