PSC_DB = nil

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

local function ConvertGenderToString(genderCode)
    if genderCode == 2 then
        return "Male"
    elseif genderCode == 3 then
        return "Female"
    else
        return "Unknown"
    end
end

local function GetPlayerInfoFromUnit(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsFriend("player", unit) then
        return
    end

    local name = UnitName(unit)
    local level = UnitLevel(unit)
    local class, englishClass = UnitClass(unit)
    class = class:sub(1, 1):upper() .. class:sub(2):lower()
    local race, englishRace = UnitRace(unit)
    local gender = ConvertGenderToString(UnitSex(unit))
    local guildName = GetGuildInfo(unit)
    if not guildName then guildName = "" end
    local rank = GetHonorRank(unit)

    -- if PSC_Debug then
    --     print("Player info for " .. name)
    --     print("Level: " .. tostring(level))
    --     print("Class: " .. tostring(class))
    --     print("Race: " .. tostring(race))
    --     print("Gender: " .. tostring(gender))
    --     print("Guild: " .. tostring(guildName))
    --     print("Rank: " .. tostring(rank))
    -- end

    if not name or not level or not class or not race or not gender or not guildName or not rank then
        return nil, nil, nil, nil, nil, nil, nil
    end

    return name, level, class, race, gender, guildName, rank
end

function PSC_StorePlayerInfo(name, level, class, race, gender, guildName, rank)
    if not PSC_DB.PlayerInfoCache[name] then
        PSC_DB.PlayerInfoCache[name] = {}
    end
    PSC_DB.PlayerInfoCache[name].level = level
    PSC_DB.PlayerInfoCache[name].class = class
    PSC_DB.PlayerInfoCache[name].race = race
    PSC_DB.PlayerInfoCache[name].gender = gender
    PSC_DB.PlayerInfoCache[name].guild = guildName
    PSC_DB.PlayerInfoCache[name].rank = rank
end

function PSC_GetAndStorePlayerInfoFromUnit(unit)
    local name, level, class, race, gender, guildName, rank = GetPlayerInfoFromUnit(unit)
    if not name or not level or not class or not race or not gender or not guildName or not rank then
        return
    end
    PSC_StorePlayerInfo(name, level, class, race, gender, guildName, rank)
end

function PSC_GetPlayerInfoFromCache(name)
    if not PSC_DB.PlayerInfoCache[name] then
        if PSC_Debug then
            print("Player info not found in cache for " .. name)
        end
        return 0, "Unknown", "Unknown", 0, "", 0
    end

    return PSC_DB.PlayerInfoCache[name].level,
        PSC_DB.PlayerInfoCache[name].class,
        PSC_DB.PlayerInfoCache[name].race,
        PSC_DB.PlayerInfoCache[name].gender,
        PSC_DB.PlayerInfoCache[name].guild,
        PSC_DB.PlayerInfoCache[name].rank
end

function PSC_GetInfoFromActiveUnit(name, unitId)
    if not UnitExists(unitId) or UnitName(unitId) ~= name then
        return 0, "Unknown", "Unknown", 0, "", 0
    end

    local level = UnitLevel(unitId)
    local class, _ = UnitClass(unitId)
    local race, _ = UnitRace(unitId)
    local gender = UnitSex(unitId)
    local guildName = GetGuildInfo(unitId)

    -- Get the PvP rank if this is the target
    local rank = 0
    if unitId == "target" then
        rank = GetTargetHonorRank()
    end

    return level, class, race, gender, guildName, rank
end

function PSC_GetInfoFromGuid(guid)
    if not guid or guid == "" then
        return "Unknown"
    end

    local _, englishClass = GetPlayerInfoByGUID(guid)
    return englishClass or "Unknown"
end

function PSC_CleanupKillCounts()
    local cleanedKillCounts = {}

    for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
        if data.kills and data.kills > 0 then
            cleanedKillCounts[nameWithLevel] = data
        end
    end

    PSC_DB.PlayerKillCounts = cleanedKillCounts
end

function PSC_CleanupPlayerInfoCache()
    local cleanedInfoCache = {}
    local playersWithKills = {}

    if not PSC_DB.PlayerKillCounts then return end

    for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
        if data.kills and data.kills > 0 then
            local name = string.match(nameWithLevel, "([^:]+)")
            if name then
                playersWithKills[name] = true
            end
        end
    end

    for name, data in pairs(PSC_DB.PlayerInfoCache) do
        if playersWithKills[name] then
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
