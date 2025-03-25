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

function PSC_GetPlayerInfoKey(name, realm)
    if not realm then
        -- For backward compatibility or same realm players
        realm = PSC_RealmName
    end
    return name .. "-" .. realm
end

function PSC_GetPlayerNameFromInfoKey(infoKey)
    if not infoKey or not string.find(infoKey, "-") then
        return infoKey
    end
    return string.match(infoKey, "^(.+)%-")
end

function PSC_GetRealmFromInfoKey(infoKey)
    if not infoKey or not string.find(infoKey, "-") then
        return PSC_RealmName
    end
    return string.match(infoKey, "%-(.+)$")
end

function PSC_GetInfoKeyFromName(playerName)
    -- Extract realm name if present in player name
    local name, realm = playerName:match("^(.+)%-(.+)$")

    if name then
        -- Player name already includes realm
        return PSC_GetPlayerInfoKey(name, realm)
    else
        -- No realm in name, use default realm
        return PSC_GetPlayerInfoKey(playerName)
    end
end

function PSC_MigratePlayerInfoCache()
    if not PSC_DB.PlayerInfoCacheMigrated then
        print("[PvPStats]: Migrating player cache to support cross-realm players...")

        local oldCache = PSC_DB.PlayerInfoCache
        local newCache = {}

        -- Migrate existing entries to the new format with realm names
        for name, data in pairs(oldCache) do
            -- Only process entries that don't already have realm name format
            if not string.find(name, "-") then
                local infoKey = PSC_GetPlayerInfoKey(name)
                newCache[infoKey] = data
            else
                -- If it already has a dash, keep it as is (shouldn't happen in current data)
                newCache[name] = data
            end
        end

        -- Replace the old cache with the new one
        PSC_DB.PlayerInfoCache = newCache
        PSC_DB.PlayerInfoCacheMigrated = true

        print("[PvPStats]: Player cache migration complete!")
    end
end

function PSC_StorePlayerInfo(name, level, class, race, gender, guildName, rank)
    local playerName, playerRealm = name:match("^(.+)%-(.+)$")

    local realm
    if playerName then
        name = playerName
        realm = playerRealm
    else
        -- Otherwise use current realm
        realm = PSC_RealmName
    end

    local infoKey = PSC_GetPlayerInfoKey(name, realm)

    if not PSC_DB.PlayerInfoCache[infoKey] then
        PSC_DB.PlayerInfoCache[infoKey] = {}
    end

    PSC_DB.PlayerInfoCache[infoKey].level = level
    PSC_DB.PlayerInfoCache[infoKey].class = class
    PSC_DB.PlayerInfoCache[infoKey].race = race
    PSC_DB.PlayerInfoCache[infoKey].gender = gender
    PSC_DB.PlayerInfoCache[infoKey].guild = guildName
    PSC_DB.PlayerInfoCache[infoKey].rank = rank

    -- if PSC_Debug then
    --     print("Stored player info: " .. name .. " (" .. level .. " " .. race .. " " .. gender .. " " .. class .. ") in guild " .. guildName .. " rank " .. rank)
    -- end
end

function PSC_GetAndStorePlayerInfoFromUnit(unit)
    if not UnitIsPlayer(unit) or UnitIsFriend("player", unit) then
        return
    end
    local name, level, class, race, gender, guildName, rank = GetPlayerInfoFromUnit(unit)
    if not name or not level or not class or not race or not gender or not guildName or not rank then
        if PSC_Debug then
            print("Incomplete player info for unit: " .. unit)
        end
        return
    end
    PSC_StorePlayerInfo(name, level, class, race, gender, guildName, rank)
end

function PSC_CleanupPlayerInfoCache()
    if not PSC_DB.PlayerKillCounts.Characters then return end

    local cleanedInfoCache = {}
    local playersToKeep = {}

    -- Collect names of all players who have been killed by us
    for _, characterData in pairs(PSC_DB.PlayerKillCounts.Characters) do
        for nameWithLevel, killData in pairs(characterData.Kills) do
            if killData.kills and killData.kills > 0 then
                local name = nameWithLevel:match("([^:]+)")
                if name then
                    playersToKeep[PSC_GetInfoKeyFromName(name)] = true
                end
            end
        end
    end

    -- Also collect names of all players who have killed us
    for characterKey, lossData in pairs(PSC_DB.PvPLossCounts) do
        if lossData.Deaths then
            for killerName, deathData in pairs(lossData.Deaths) do
                if deathData.deaths and deathData.deaths > 0 then
                    playersToKeep[PSC_GetInfoKeyFromName(killerName)] = true

                    -- Also keep info for players who have assisted in killing us
                    if deathData.deathLocations then
                        for _, location in ipairs(deathData.deathLocations) do
                            if location.assisters then
                                for _, assister in ipairs(location.assisters) do
                                    if assister.name then
                                        playersToKeep[PSC_GetInfoKeyFromName(assister.name)] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Only keep info for relevant players
    for infoKey, data in pairs(PSC_DB.PlayerInfoCache) do
        if playersToKeep[infoKey] then
            cleanedInfoCache[infoKey] = data
        end
    end

    PSC_DB.PlayerInfoCache = cleanedInfoCache
end

function PSC_LoadDefaultSettings()
    PSC_DB.EnableKillAnnounceMessages = true
    PSC_DB.EnableRecordAnnounceMessages = true
    PSC_DB.EnableMultiKillAnnounceMessages = true
    PSC_DB.MultiKillThreshold = 3

    PSC_DB.AutoBattlegroundMode = true
    PSC_DB.CountAssistsInBattlegrounds = true
    PSC_DB.ForceBattlegroundMode = false
    PSC_DB.CountKillsInBattlegrounds = true
    PSC_DB.CountDeathsInBattlegrounds = true

    PSC_DB.ShowKillMilestones = true
    PSC_DB.EnableKillMilestoneSound = true
    PSC_DB.ShowMilestoneForFirstKill = true
    PSC_DB.KillMilestoneInterval = 5
    PSC_DB.KillMilestoneAutoHideTime = 5
    PSC_DB.MilestoneFramePosition = {
        point="TOP",
        relativePoint="TOP",
        xOfs=0,
        yOfs=-100
    }

    -- Add default position for kill streak milestone frame
    PSC_DB.KillStreakMilestoneFramePosition = {
        point="TOP",
        relativePoint="TOP",
        xOfs=0,
        yOfs=-10
    }

    PSC_DB.EnableMultiKillSounds = true
    PSC_DB.ShowScoreInPlayerTooltip = true
    PSC_DB.ShowExtendedTooltipInfo = true
    PSC_DB.ShowAccountWideStats = true

    PSC_DB.KillAnnounceMessage = "Enemyplayername killed! x#"
    PSC_DB.KillStreakEndedMessage = "My kill streak of STREAKCOUNT has ended!"
    PSC_DB.NewKillStreakRecordMessage = "New personal best: Kill streak of STREAKCOUNT!"
    PSC_DB.NewMultiKillRecordMessage = "New personal best: MULTIKILLTEXT!"

    PSC_DB.MinimapButtonPosition = 195
end

function PSC_InitializePlayerKillCounts()
    if not PSC_DB.PlayerKillCounts.Characters then
        PSC_DB.PlayerKillCounts.Characters = {}
    end

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

    PSC_InitializePlayerKillCounts()
    PSC_InitializePlayerLossCounts()

    print("[PvPStats]: All statistics have been reset!")
end
