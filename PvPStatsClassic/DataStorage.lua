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
    if not UnitExists(unit) or UnitIsFriend("player", unit) then
        return
    end

    local name = nil
    local level = nil
    local class = nil
    local race = nil
    local gender = nil
    local guildName = nil
    local rank = nil

    if UnitIsPlayer(unit) then
        name = UnitName(unit)
        level = UnitLevel(unit)
        class, _ = UnitClass(unit)
        class = class:sub(1, 1):upper() .. class:sub(2):lower()
        race, _ = UnitRace(unit)
        gender = ConvertGenderToString(UnitSex(unit))
        guildName = GetGuildInfo(unit)
        if not guildName then guildName = "" end
        rank = GetHonorRank(unit)
    elseif not UnitIsPlayer(unit) then
        -- Mob for testing purposes
        name = UnitName(unit)
        level = UnitLevel(unit)
        class = "Unknown"
        race = "Unknown"
        gender = "Unknown"
        guildName = ""
        rank = GetHonorRank(unit)
    end

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

function PSC_CleanupPlayerInfoCache()
    if not PSC_DB.PlayerKillCounts.Characters then return end

    local cleanedInfoCache = {}
    local playersWithKills = {}

    -- Collect names of all players who have been killed
    for _, characterData in pairs(PSC_DB.PlayerKillCounts.Characters) do
        for nameWithLevel, killData in pairs(characterData.Kills) do
            if killData.kills and killData.kills > 0 then
                local name = nameWithLevel:match("([^:]+)")
                if name then
                    playersWithKills[name] = true
                end
            end
        end
    end

    -- Only keep info for players who have been killed
    for name, data in pairs(PSC_DB.PlayerInfoCache) do
        if playersWithKills[name] then
            cleanedInfoCache[name] = data
        end
    end

    PSC_DB.PlayerInfoCache = cleanedInfoCache
end

function PSC_LoadDefaultSettings()
    PSC_DB.ShowAccountWideStats = true

    PSC_DB.AutoBattlegroundMode = true
    PSC_DB.CountAssistsInBattlegrounds = true
    PSC_DB.ForceBattlegroundMode = false
    PSC_DB.TrackKillsInBattlegrounds = true
    PSC_DB.TrackDeathsInBattlegrounds = true

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
    PSC_DB.EnableMultiKillAnnounceMessages = true
    PSC_DB.EnableMultiKillSounds = true

    PSC_DB.KillAnnounceMessage = "Enemyplayername x# killed!"
    PSC_DB.KillStreakEndedMessage = "My kill streak of STREAKCOUNT has ended!"
    PSC_DB.NewKillStreakRecordMessage = "New personal best: Kill streak of STREAKCOUNT!"
    PSC_DB.NewMultiKillRecordMessage = "New personal best: MULTIKILLTEXT!"
    PSC_DB.MultiKillThreshold = 3

    PSC_DB.MinimapButtonPosition = 195
end

local function initializePlayerKillCounts()
    PSC_DB.PlayerKillCounts.Characters = {}

    local characterKey = PSC_GetCharacterKey()
    if not PSC_DB.PlayerKillCounts.Characters[characterKey] then
        PSC_DB.PlayerKillCounts.Characters[characterKey] = {
            Kills = {},
            CurrentKillStreak = 0,
            HighestKillStreak = 0,
            HighestMultiKill = 0
        }
    end
end

function PSC_InitializePlayerLossCounts()
    if not PSC_DB.PvPLossCounts then
        PSC_DB.PvPLossCounts = {}
    end

    local characterKey = PSC_GetCharacterKey()
    if not PSC_DB.PvPLossCounts[characterKey] then
        PSC_DB.PvPLossCounts[characterKey] = {
            Deaths = {}
        }
    end
end

function ResetAllStatsToDefault()
    PSC_DB.PlayerInfoCache = {}
    PSC_DB.PlayerKillCounts = {}
    PSC_DB.PvPLossCounts = {}

    initializePlayerKillCounts()
    PSC_InitializePlayerLossCounts()

    print("All kill statistics have been reset!")
end
