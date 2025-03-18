PSC_DB = nil

function PSC_UpdatePlayerInfoCache(name, guid, level, class, race, gender, guild, rank)
    if not name then return end

    PSC_DB.PlayerInfoCache[name] = PSC_DB.PlayerInfoCache[name] or {}
    local playerData = PSC_DB.PlayerInfoCache[name]

    if guid and guid ~= "" then playerData.guid = guid end
    if level and level > 0 then playerData.level = level end
    if class and class ~= "" then playerData.class = class end
    if race and race ~= "" then playerData.race = race end
    if gender and gender ~= nil then playerData.gender = gender end
    if guild and guild ~= "" then playerData.guild = guild end
    if rank then playerData.rank = rank end
    -- if PSC_Debug then
    --     print("Player info updated for " .. name)
    --     print("GUID: " .. (playerData.guid or "N/A"))
    --     print("Level: " .. (playerData.level or "N/A"))
    --     print("Class: " .. (playerData.class or "N/A"))
    --     print("Race: " .. (playerData.race or "N/A"))
    --     print("Guild: " .. (playerData.guild or "N/A"))
    --     print("Rank: " .. (playerData.rank or "N/A"))
    -- end
end

local function GetHonorRank(unit)
    if not UnitPVPRank then return 0 end

    local pvpRank = UnitPVPRank(unit)

    if not pvpRank then
        return 0
    end

    if pvpRank >= 5 then
        return pvpRank - 4
    end

    return 0
end

function PSC_StorePlayerInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    if UnitIsFriend("player", unit) then return end

    local name = UnitName(unit)
    if not name then return end

    local guid = UnitGUID(unit)
    local level = UnitLevel(unit)
    local _, englishClass = UnitClass(unit)
    local _, englishRace = UnitRace(unit)
    local gender = UnitSex(unit)
    local guildName = GetGuildInfo(unit)
    local rank = GetHonorRank(unit)

    PSC_UpdatePlayerInfoCache(name, guid, level, englishClass, englishRace, gender, guildName, rank)
end

function PSC_GetInfoFromCachedPlayer(name)
    if not PSC_DB.PlayerInfoCache[name] then
        print("Player info not found in cache for " .. name)
        return 0, "Unknown", "Unknown", 0, "", 0
    end

    local data = PSC_DB.PlayerInfoCache[name]
    return data.level or 0,
        data.class or "Unknown",
        data.race or "Unknown",
        data.gender or 0,
        data.guild or "",
        data.rank or 0
end

function PSC_GetInfoFromActiveUnit(name, unitId)
    if not UnitExists(unitId) or UnitName(unitId) ~= name then
        return 0, "Unknown", "Unknown", 0, "", 0
    end

    local level = UnitLevel(unitId)
    local _, englishClass = UnitClass(unitId)
    local _, englishRace = UnitRace(unitId)
    local gender = UnitSex(unitId)
    local guildName = GetGuildInfo(unitId)

    -- Get the PvP rank if this is the target
    local rank = 0
    if unitId == "target" then
        rank = GetTargetHonorRank()
    end

    return level, englishClass, englishRace, gender, guildName, rank
end

function PSC_GetInfoFromGuid(guid)
    if not guid or guid == "" then
        return "Unknown"
    end

    local _, englishClass = GetPlayerInfoByGUID(guid)
    return englishClass or "Unknown"
end

function PSC_ConvertGenderToString(genderCode)
    if genderCode == 2 then
        return "Male"
    elseif genderCode == 3 then
        return "Female"
    else
        return "Unknown"
    end
end

function PSC_GetPlayerInfoFromCache(name)
    local level, class, race, gender, guild, rank = PSC_GetInfoFromCachedPlayer(name)
    if level == 0 then level = -1 end
    return level, class, race, PSC_ConvertGenderToString(gender), guild, rank
end


function PSC_IsValidPlayerData(data)
    return data.kills and data.kills > 0 and
        data.race and data.race ~= "Unknown" and
        data.gender and data.gender ~= "Unknown" and
        data.class and data.class ~= "Unknown"
end

function PSC_IsUsefulCacheEntry(data)
    return (data.race and data.race ~= "") and
        (data.gender and data.gender > 0) and
        (data.class and data.class ~= "")
end

function PSC_CleanupKillCounts()
    local cleanedKillCounts = {}

    for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
        -- Only keep entries that have valid player data AND have kills
        if PSC_IsValidPlayerData(data) and data.kills and data.kills > 0 then
            cleanedKillCounts[nameWithLevel] = data
        end
    end

    PSC_DB.PlayerKillCounts = cleanedKillCounts
end

function PSC_CleanupPlayerInfoCache()
    local cleanedInfoCache = {}
    local playersWithKills = {}

    if PSC_DB.PlayerKillCounts then
        for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
            if data.kills and data.kills > 0 then
                local name = string.match(nameWithLevel, "([^:]+)")
                if name then
                    playersWithKills[name] = true
                end
            end
        end
    end

    -- Now only keep players who either have kills or have useful data
    for name, data in pairs(PSC_DB.PlayerInfoCache) do
        if playersWithKills[name] or PSC_IsUsefulCacheEntry(data) then
            cleanedInfoCache[name] = data
        end
    end

    PSC_DB.PlayerInfoCache = cleanedInfoCache
end

function PSC_CleanupDatabase()
    PSC_CleanupKillCounts()
    PSC_CleanupPlayerInfoCache()

    if PSC_Debug then
        print("PvPStatsClassic: Database cleaned up.")
    end
end

function PSC_LoadDefaultSettings()
    PSC_DB.AutoBattlegroundMode = true
    PSC_DB.ForceBattlegroundMode = false

    PSC_DB.ShowTooltipKillInfo = true

    PSC_DB.ShowKillMilestones = true
    PSC_DB.EnableKillMilestoneSounds = true
    PSC_DB.ShowMilestoneForFirstKill = true
    PSC_DB.KillMilestoneInterval = 5
    PSC_DB.KillMilestoneAutoHideTime = 5
    PSC_DB.MilestoneFramePosition = {
        point="TOP",
        relativePoint="TOP",
        xOfs=0,
        yOfs=-100
    }


    PSC_DB.EnableKillAnnounceMessages = true
    PSC_DB.EnableRecordAnnounceMessages = true
    PSC_DB.EnableMultiKillSounds = true

    PSC_DB.KillAnnounceMessage = "Enemyplayername killed!"
    PSC_DB.KillStreakEndedMessage = "My kill streak of STREAKCOUNT has ended!"
    PSC_DB.NewKillStreakRecordMessage = "NEW PERSONAL BEST: Kill streak of STREAKCOUNT!"
    PSC_DB.NewMultiKillRecordMessage = "NEW PERSONAL BEST: MULTIKILLTEXT!"
    PSC_DB.MultiKillThreshold = 3

    PSC_DB.MinimapButtonPosition = 195
end


function ResetAllStatsToDefault()
    PSC_DB.PlayerInfoCache = {}
    PSC_DB.PlayerKillCounts = {}
    PSC_DB.CurrentKillStreak = 0
    PSC_DB.HighestKillStreak = 0
    PSC_DB.HighestMultiKill = 0

    print("All kill statistics have been reset!")
end
