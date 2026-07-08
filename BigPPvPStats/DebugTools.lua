---@diagnostic disable: duplicate-set-field

local addonName, PVPSC = ...

local DEBUG_REALM_NAMES = {
    "Thunderstrike",
    "Hydraxian Waterlords",
}


local function BPP_DebugPickRealmName()
    local currentRealm = BPP_RealmName
    if math.random() <= 0.5 then
        local candidates = {}
        for _, realm in ipairs(DEBUG_REALM_NAMES) do
            if realm ~= currentRealm then
                candidates[#candidates + 1] = realm
            end
        end
        if #candidates > 0 then
            return candidates[math.random(#candidates)], true
        end
    end
    return currentRealm, false
end

local function BPP_DebugApplyRandomRealm(playerName)
    if not playerName or playerName == "" then
        return playerName
    end
    if string.find(playerName, "%-") then
        return playerName
    end
    local realm, isDifferent = BPP_DebugPickRealmName()
    if isDifferent then
        return playerName .. "-" .. realm
    end
    return playerName
end

function BPP_DebugPetKills()
    print("Enabling pet kill debugging for 120 seconds...")

    local originalHandler = HandleCombatLogEvent

    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4 = CombatLogGetCurrentEventInfo()

        originalHandler()

        if BPP_IsPetGUID(sourceGUID) then
            local ownerGUID = BPP_GetPetOwnerGUID(sourceGUID)

            if ownerGUID == BPP_PlayerGUID then
                if combatEvent:find("_DAMAGE") or combatEvent == "SWING_DAMAGE" then
                    local amount = combatEvent == "SWING_DAMAGE" and param1 or
                        (combatEvent == "SPELL_DAMAGE" and param4 or 0)

                    print("Pet damage to " .. destName .. ": " .. amount .. " damage")

                    -- Check current health if it's your target
                    if UnitExists("target") and UnitGUID("target") == destGUID then
                        print("Target health: " .. UnitHealth("target") .. "/" .. UnitHealthMax("target"))
                        if UnitHealth("target") <= 0 then
                            print("Target appears to be DEAD!")
                        end
                    end
                end
            end
        end

        if combatEvent == "UNIT_DIED" then
            local petDamage = BPP_RecentPetDamage[destGUID]
            if petDamage then
                print("*** DEATH DETECTED - " .. destName .. " ***")
                print("This target was damaged by your pet " .. (petDamage.petName or "Unknown") ..
                    " " .. string.format("%.6f", GetTime() - petDamage.timestamp) .. " seconds ago")

                if CombatLogDestFlagsEnemyPlayer(destFlags) then
                    print("This was an enemy player kill!")
                else
                    print("This was NOT an enemy player")
                end
            end
        end
    end

    C_Timer.After(120, function()
        print("Pet kill debugging ended.")
        HandleCombatLogEvent = originalHandler
    end)
end

function BPP_DebugCombatLogEvents()
    print("Enabling enhanced combat log debugging for 60 seconds...")

    local originalHandler = HandleCombatLogEvent

    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        -- Print out kill-related events
        print("EVENT: " .. combatEvent)
        print("SOURCE: " .. (sourceName or "nil") .. " (" .. (sourceGUID or "nil") .. ")")
        print("TARGET: " .. (destName or "nil") .. " (" .. (destGUID or "nil") .. ")")
        print("FLAGS: source=" .. (sourceFlags or 0) .. ", dest=" .. (destFlags or 0))
        print("-----------------------------------")

        originalHandler()
    end

    C_Timer.After(60, function()
        print("Combat log debugging ended.")
        HandleCombatLogEvent = originalHandler
    end)
end

function BPP_SimulateCombatLogEvent(killerCount, assistCount, damageType)
    BPP_Print("Simulating combat log events for a death with " ..
        killerCount .. " killer(s) and " .. assistCount .. " assists...")

    local randomPlayer = BPP_GetRandomTestPlayer()

    local mainKillerBaseName = randomPlayer.name
    local mainKillerName = BPP_DebugApplyRandomRealm(mainKillerBaseName)
    local mainKillerGUID = "Player-0-" .. math.random(1000000)
    local mainKillerClass = randomPlayer.class
    local mainKillerLevel = randomPlayer.level
    BPP_RecentDamageFromPlayers = {}

    -- Store killer level in PlayerInfoCache
    BPP_StorePlayerInfo(mainKillerName, mainKillerLevel, mainKillerClass,
        randomPlayer.race, randomPlayer.gender, randomPlayer.guildName, randomPlayer.guildRankName, randomPlayer.rank)

    local now = GetTime()

    BPP_TrackIncomingPlayerDamage(mainKillerGUID, mainKillerName, 1000)

    local assistList = {}
    for i = 1, assistCount do
        local randomPlayer = BPP_GetRandomTestPlayer()
        local assistBaseName = randomPlayer.name
        while assistBaseName == mainKillerBaseName or tContains(assistList, assistBaseName) do
            randomPlayer = BPP_GetRandomTestPlayer()
            assistBaseName = randomPlayer.name
        end

        local assistName = BPP_DebugApplyRandomRealm(assistBaseName)

        -- Store assist player level in PlayerInfoCache
        BPP_StorePlayerInfo(assistName, randomPlayer.level, randomPlayer.class,
            randomPlayer.race, randomPlayer.gender, randomPlayer.guildName, randomPlayer.guildRankName, randomPlayer.rank)

        local assistGUID = "Player-0-" .. math.random(1000000)
        BPP_TrackIncomingPlayerDamage(assistGUID, assistName, 500)
        table.insert(assistList, assistBaseName)
    end

    BPP_HandlePlayerDeath()

    -- Print a summary of what happened
    local characterKey = BPP_GetCharacterKey()
    if BPP_DB.PvPLossCounts and BPP_DB.PvPLossCounts[characterKey] then
        local deathCount = 0
        local killerLevel = "unknown"

        if BPP_DB.PvPLossCounts[characterKey].Deaths[mainKillerName] then
            local deathData = BPP_DB.PvPLossCounts[characterKey].Deaths[mainKillerName]
            deathCount = deathData.deaths
            killerLevel = deathData.killerLevel
        end

        BPP_Print("Death simulation complete! Killed by " .. mainKillerName ..
            " (Level " .. killerLevel .. " " .. mainKillerClass .. ") - Total deaths to them: " .. deathCount)

        -- Show assist information if applicable
        if assistCount > 0 and BPP_DB.PvPLossCounts[characterKey].Deaths[mainKillerName] then
            local lastDeath = BPP_DB.PvPLossCounts[characterKey].Deaths[mainKillerName].deathLocations[#BPP_DB.PvPLossCounts[characterKey].Deaths[mainKillerName].deathLocations]
            if lastDeath and lastDeath.assisters then
                local assistInfo = "Assisters: "
                for i, assist in ipairs(lastDeath.assisters) do
                    assistInfo = assistInfo .. assist.name .. " (Level " .. assist.level .. ")"
                    if i < #lastDeath.assisters then
                        assistInfo = assistInfo .. ", "
                    end
                end
                BPP_Print(assistInfo)
            end
        end
    end
end

function BPP_RunDeathTrackingTests()
    BPP_Print("Running comprehensive death tracking tests...")

    BPP_Print("\nTest 1: Solo kill")
    BPP_SimulateCombatLogEvent(1, 0, "direct")

    BPP_Print("\nTest 2: Kill with assists")
    BPP_SimulateCombatLogEvent(1, 2, "direct")

    BPP_Print("\nTest 3: Kill with multiple damage types")
    BPP_SimulateCombatLogEvent(1, 1, "mixed")

    BPP_Print("Death tracking tests complete!")
end

function BPP_ShowDebugInfo()
    BPP_Print("Current Kill Streak: " .. BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()].CurrentKillStreak)
    BPP_Print("Highest Kill Streak: " .. BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()].HighestKillStreak)
    BPP_Print("Current Multi-kill Count: " .. BPP_MultiKillCount)
    BPP_Print("Highest Multi-kill: " .. BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()].HighestMultiKill)

    local characterKey = BPP_GetCharacterKey()
    if BPP_DB.PvPLossCounts and BPP_DB.PvPLossCounts[characterKey] then
        local totalDeaths = 0
        local totalSoloDeaths = 0
        local totalAssistDeaths = 0

        for _, deathData in pairs(BPP_DB.PvPLossCounts[characterKey].Deaths) do
            totalDeaths = totalDeaths + deathData.deaths
            totalSoloDeaths = totalSoloDeaths + (deathData.soloKills or 0)
            totalAssistDeaths = totalAssistDeaths + (deathData.assistKills or 0)
        end

        BPP_Print("Total Deaths: " .. totalDeaths ..
            " (Solo: " .. totalSoloDeaths ..
            ", Group: " .. totalAssistDeaths .. ")")
    else
        BPP_Print("Total Deaths: 0")
    end

    BPP_Print("Multi-kill Announcement Threshold: " .. BPP_DB.MultiKillThreshold)
    BPP_Print("Battleground Mode: " .. (BPP_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    BPP_Print("Auto BG Detection: " .. (BPP_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    BPP_Print("Manual BG Mode: " .. (BPP_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

local function CreateKillDebugMessage(playerName, nameWithLevel, killerName, killerGUID)
    local debugMsg = "Killed: " .. playerName

    local infoKey = BPP_GetInfoKeyFromName(playerName)

    local level = BPP_DB.PlayerInfoCache[infoKey].level
    local class = BPP_DB.PlayerInfoCache[infoKey].class
    local race = BPP_DB.PlayerInfoCache[infoKey].race

    local playerLevel = UnitLevel("player")
    local levelDifference = level > 0 and (level - playerLevel) or 0
    if level == -1 or (level > 0 and levelDifference >= 5) then
        debugMsg = debugMsg .. " (Level " .. (level == -1 and "??" or level)
    else
        debugMsg = debugMsg .. " ("
    end

    debugMsg = debugMsg .. class .. ", " .. race .. ")"

    local rank = BPP_DB.PlayerKillCounts[nameWithLevel].rank or 0
    if rank > 0 then
        debugMsg = debugMsg .. " [Rank: " .. rank .. "]"
    end

    debugMsg = debugMsg .. " - Total kills: " .. BPP_DB.PlayerKillCounts[nameWithLevel].kills
    debugMsg = debugMsg .. " - Current streak: " .. BPP_DB.CurrentKillStreak
    debugMsg = debugMsg .. " - Zone: " .. (BPP_DB.PlayerKillCounts[nameWithLevel].zone or "Unknown")

    -- Check what kind of kill this was
    if killerGUID and BPP_IsPetGUID(killerGUID) then
        debugMsg = debugMsg .. " - Kill by: Your Pet (" .. (killerName or "Unknown") .. ")"
    elseif killerName == "Assist" then
        debugMsg = debugMsg .. " - Assist Kill (mob/environment finished target)"
    end

    if BPP_MultiKillCount >= 2 then
        debugMsg = debugMsg .. " - " .. BPP_GetMultiKillText(BPP_MultiKillCount)
    end

    return debugMsg
end

local zones = {
    "Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Darnassus", "Undercity",
    "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Tirisfal Glades", "Westfall",
    "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "The Barrens", "Ashenvale",
    "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
    "Desolace", "Dustwallow Marsh", "Eastern Plaguelands", "Felwood", "Feralas",
    "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
    "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley",
    --- TBC zones
    "Hellfire Peninsula", "Zangarmarsh", "Nagrand", "Terokkar Forest", "Blade's Edge Mountains",
    "Netherstorm", "Shadowmoon Valley", "Isle of Quel'Danas", "Eye of the Storm", "Azuremyst Isle",
    "Bloodmyst Isle", "Eversong Woods", "Ghostlands", "Exodar", "Silvermoon City"
}

function BPP_SimulatePlayerKills(killCount)
    for i = 1, killCount do
        local testPlayer = BPP_GetRandomTestPlayer()
        local killName = BPP_DebugApplyRandomRealm(testPlayer.name)

        -- Temporarily override GetRealZoneText to return our random zone
        local randomZone = zones[math.random(#zones)]
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        local randomX = 10.0 + (90.0 - 10.0) * math.random()
        local randomY = 10.0 + (90.0 - 10.0) * math.random()

        -- Override C_Map.GetPlayerMapPosition for this simulation
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
        ---@diagnostic disable-next-line: duplicate-set-field
        C_Map.GetPlayerMapPosition = function(mapID, unit)
            return { x = randomX / 100, y = randomY / 100 }
        end

        -- Register the kill with random data including rank
        BPP_StorePlayerInfo(killName, testPlayer.level, testPlayer.class,
            testPlayer.race, testPlayer.gender, testPlayer.guildName, testPlayer.guildRankName,
            testPlayer.rank)
        BPP_RegisterPlayerKill(killName)

        -- Restore the original functions
        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    BPP_Print("Registered " .. killCount .. " random test kill(s).")
end

-- Same as BPP_SimulatePlayerKills but forces a specific guild name, so the
-- guild trash milestones (see GuildRivalry.lua) can be tested without
-- waiting to actually fight that guild.
function BPP_SimulateGuildKills(guildName, killCount)
    if not guildName or guildName == "" then
        BPP_Print("Usage: /bpp registerguildkill <guild name> [count]")
        return
    end

    for i = 1, killCount do
        local testPlayer = BPP_GetRandomTestPlayer()
        testPlayer.guildName = guildName
        testPlayer.guildRankName = BPP_guildRanks[math.random(1, #BPP_guildRanks)]
        local killName = BPP_DebugApplyRandomRealm(testPlayer.name)

        local randomZone = zones[math.random(#zones)]
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        local randomX = 10.0 + (90.0 - 10.0) * math.random()
        local randomY = 10.0 + (90.0 - 10.0) * math.random()
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
        ---@diagnostic disable-next-line: duplicate-set-field
        C_Map.GetPlayerMapPosition = function(mapID, unit)
            return { x = randomX / 100, y = randomY / 100 }
        end

        BPP_StorePlayerInfo(killName, testPlayer.level, testPlayer.class,
            testPlayer.race, testPlayer.gender, testPlayer.guildName, testPlayer.guildRankName,
            testPlayer.rank)
        BPP_RegisterPlayerKill(killName)

        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    BPP_Print("Registered " .. killCount .. " test kill(s) against guild '" .. guildName .. "'.")
end


local function BPP_DebugSnapshotNowKey(label)
    local ts = time and time() or 0
    local safeLabel = tostring(label or "")
    safeLabel = safeLabel:gsub("[^%w_%-%s]", "")
    safeLabel = safeLabel:gsub("%s+", " ")
    safeLabel = safeLabel:match("^%s*(.-)%s*$")

    local prefix = date and date("%Y-%m-%d_%H-%M-%S", ts) or tostring(ts)
    if safeLabel ~= "" then
        return prefix .. "__" .. safeLabel
    end
    return prefix
end

local function BPP_SnapshotKeySort(a, b)
    local ta, tb = type(a), type(b)
    if ta ~= tb then
        return ta < tb
    end
    if ta == "number" then
        return a < b
    end
    return tostring(a) < tostring(b)
end

-- Serializes any plain data value (tables/strings/numbers/etc.) into valid Lua
-- literal syntax. Made global (not local) so BackupTools.lua can reuse it for
-- the /bpp export feature instead of duplicating this logic.
function BPP_SerializeSnapshotValue(value, indent, visited)
    local t = type(value)
    if t == "nil" then
        return "nil"
    elseif t == "number" or t == "boolean" then
        return tostring(value)
    elseif t == "string" then
        return string.format("%q", value)
    elseif t == "function" then
        return "<function>"
    elseif t == "userdata" then
        return "<userdata>"
    elseif t == "thread" then
        return "<thread>"
    elseif t ~= "table" then
        return "<" .. t .. ">"
    end

    if visited[value] then
        return "<cycle>"
    end
    visited[value] = true

    indent = indent or ""
    local nextIndent = indent .. "  "

    local keys = {}
    for k in pairs(value) do
        keys[#keys + 1] = k
    end
    table.sort(keys, BPP_SnapshotKeySort)

    local out = {"{"}
    for _, k in ipairs(keys) do
        local v = value[k]
        local keyRepr
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            keyRepr = k
        else
            keyRepr = "[" .. BPP_SerializeSnapshotValue(k, nextIndent, visited) .. "]"
        end
        out[#out + 1] = "\n" .. nextIndent .. keyRepr .. " = " .. BPP_SerializeSnapshotValue(v, nextIndent, visited) .. ","
    end
    out[#out + 1] = "\n" .. indent .. "}"

    visited[value] = nil
    return table.concat(out)
end

local function BPP_BuildAchievementProgressSnapshot(stats)
    local system = PVPSC and PVPSC.AchievementSystem or nil
    local achievements = system and system.achievements or nil
    if type(achievements) ~= "table" then
        return {}
    end

    local playerName = UnitName and UnitName("player") or nil

    local entries = {}
    for _, achievement in ipairs(achievements) do
        if achievement then
            local progressValue = nil
            if type(achievement.progress) == "function" then
                local ok, result = pcall(achievement.progress, achievement, stats)
                if ok then
                    progressValue = result
                else
                    progressValue = "<error>"
                end
            end

            local title = achievement.title
            if type(title) == "function" then
                local ok, result = pcall(title, achievement)
                title = ok and result or "<error>"
            end
            if type(title) == "string" and BPP_ReplacePlayerNamePlaceholder then
                title = BPP_ReplacePlayerNamePlaceholder(title, playerName, achievement)
            end

            entries[#entries + 1] = {
                id = achievement.id,
                title = title,
                unlocked = achievement.unlocked or false,
                completedDate = achievement.completedDate or "",
                points = achievement.achievementPoints or 0,
                targetValue = achievement.targetValue,
                progress = progressValue,
                rarity = achievement.rarity,
            }
        end
    end

    table.sort(entries, function(a, b)
        return (a.id or 0) < (b.id or 0)
    end)

    return entries
end

function BPP_CreateDebugSnapshot(label)
    if not BPP_DB then
        BPP_Print("ERROR: BPP_DB not initialized")
        return nil
    end

    BPP_DB.DebugSnapshots = BPP_DB.DebugSnapshots or {}

    local charactersToProcess = BPP_GetCharactersToProcessForStatistics and BPP_GetCharactersToProcessForStatistics() or nil
    if not charactersToProcess then
        local key = BPP_GetCharacterKey and BPP_GetCharacterKey() or nil
        charactersToProcess = {}
        if key and BPP_DB.PlayerKillCounts and BPP_DB.PlayerKillCounts.Characters and BPP_DB.PlayerKillCounts.Characters[key] then
            charactersToProcess[key] = BPP_DB.PlayerKillCounts.Characters[key]
        end
    end

    local summaryStats = BPP_CalculateSummaryStatistics and BPP_CalculateSummaryStatistics(charactersToProcess) or nil
    local achievementStats = nil
    if BPP_GetStatsForAchievements then
        achievementStats = select(1, BPP_GetStatsForAchievements())
    end

    local snapshot = {
        meta = {
            addon = "BigPPvPStats",
---@diagnostic disable-next-line: undefined-global
            version = (GetAddOnMetadata and GetAddOnMetadata("BigPPvPStats", "Version")) or nil,
            characterKey = BPP_GetCharacterKey and BPP_GetCharacterKey() or nil,
            accountWide = BPP_DB.ShowAccountWideStats or false,
            realm = (GetRealmName and GetRealmName()) or nil,
            player = (UnitName and UnitName("player")) or nil,
        },
        summaryStats = summaryStats,
        achievementStats = achievementStats,
        achievements = achievementStats and BPP_BuildAchievementProgressSnapshot(achievementStats) or {},
    }

    local serialized = BPP_SerializeSnapshotValue(snapshot, "", {})
    local lines = {"-- BigPPvPStats snapshot"}
    for line in tostring(serialized):gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    local key = BPP_DebugSnapshotNowKey(label)
    BPP_DB.DebugSnapshots[key] = lines

    BPP_Print("Snapshot saved: BPP_DB.DebugSnapshots['" .. key .. "'] (" .. tostring(#lines) .. " lines)")

    return key, lines
end

function BPP_SimulateLevel1Kills(killCount)
    for i = 1, killCount do
        local testPlayer = BPP_GetRandomTestPlayer()
        testPlayer.level = 1 -- Force level 1
        local killName = BPP_DebugApplyRandomRealm(testPlayer.name)

        -- Temporarily override GetRealZoneText to return our random zone
        local randomZone = zones[math.random(#zones)]
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        local randomX = 10.0 + (90.0 - 10.0) * math.random()
        local randomY = 10.0 + (90.0 - 10.0) * math.random()

        -- Override C_Map.GetPlayerMapPosition for this simulation
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
        ---@diagnostic disable-next-line: duplicate-set-field
        C_Map.GetPlayerMapPosition = function(mapID, unit)
            return { x = randomX / 100, y = randomY / 100 }
        end

        -- Register the kill with random data including rank
        BPP_StorePlayerInfo(killName, testPlayer.level, testPlayer.class,
            testPlayer.race, testPlayer.gender, testPlayer.guildName, testPlayer.guildRankName,
            testPlayer.rank)
        BPP_RegisterPlayerKill(killName)

        -- Restore the original functions
        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    BPP_Print("Registered " .. killCount .. " random level 1 test kill(s).")
end

function BPP_SimulatePlayerDeathByEnemy(killerCount, assistCount)
    BPP_Print("Simulating death by " .. killerCount .. " enemy player(s) with " .. assistCount .. " assists...")

    local zone = zones[math.random(#zones)]

    -- Override GetRealZoneText for this simulation
    local originalGetRealZoneText = GetRealZoneText
    GetRealZoneText = function() return zone end

    -- Override map position
    local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
    local randomX = 10.0 + (90.0 - 10.0) * math.random()
    local randomY = 10.0 + (90.0 - 10.0) * math.random()

    ---@diagnostic disable-next-line: duplicate-set-field
    C_Map.GetPlayerMapPosition = function(mapID, unit)
        return { x = randomX / 100, y = randomY / 100 }
    end

    -- Generate a killer using BPP_GetRandomTestPlayer
    local killerPlayer = BPP_GetRandomTestPlayer()
    local killerBaseName = killerPlayer.name
    local killerName = BPP_DebugApplyRandomRealm(killerBaseName)
    local killerClass = killerPlayer.class
    local killerLevel = killerPlayer.level
    local killerRace = killerPlayer.race
    local killerGender = killerPlayer.gender
    local killerGuild = killerPlayer.guildName
    local killerGuildRank = killerPlayer.guildRankName
    local killerRank = killerPlayer.rank

    -- Store killer info in cache
    BPP_StorePlayerInfo(killerName, killerLevel, killerClass, killerRace, killerGender, killerGuild, killerGuildRank, killerRank)

    -- Create a simulated killer info structure
    local killerInfo = {
        killer = {
            name = killerName,
            guid = "Simulated-Killer-GUID-" .. math.random(1000000),
            damage = 1000,
            isPet = false
        },
        assists = {}
    }

    local usedNames = {killerBaseName}
    for i = 1, assistCount do
        local assistPlayer = BPP_GetRandomTestPlayer()
        -- Ensure unique names
        while tContains(usedNames, assistPlayer.name) do
            assistPlayer = BPP_GetRandomTestPlayer()
        end

        table.insert(usedNames, assistPlayer.name)

        local assistName = BPP_DebugApplyRandomRealm(assistPlayer.name)

        -- Always store assist info in debug simulation
        print("Storing assist info for " .. assistName)
        BPP_StorePlayerInfo(assistName, assistPlayer.level, assistPlayer.class,
                        assistPlayer.race, assistPlayer.gender, assistPlayer.guildName, assistPlayer.guildRankName, assistPlayer.rank)
        -- Add assist without guid
        table.insert(killerInfo.assists, {
            name = assistName
        })
    end

    local characterKey = BPP_GetCharacterKey()

    -- Reset kill streak
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]
    characterData.CurrentKillStreak = 0

    -- Register the death with our handler
    BPP_RegisterPlayerDeath(killerInfo)

    -- Restore original functions
    GetRealZoneText = originalGetRealZoneText
    C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition

    BPP_Print("Death simulation complete!")

    -- Print summary of death data
    local killerLevelDisplay = killerLevel == -1 and "??" or killerLevel
    BPP_Print("Killed by: " .. killerName .. " (Level " .. killerLevelDisplay .. " " .. killerClass .. ")")

    if assistCount > 0 then
        local assistNames = {}
        for _, assist in ipairs(killerInfo.assists) do
            local assistInfoKey = BPP_GetInfoKeyFromName(assist.name)

            if BPP_DB.PlayerInfoCache[assistInfoKey] ~= nil then
                local assistLevel = BPP_DB.PlayerInfoCache[assistInfoKey].level
                local assistLevelDisplay = assistLevel == -1 and "??" or assistLevel
                local assistClass = BPP_DB.PlayerInfoCache[assistInfoKey].class
                table.insert(assistNames, assist.name .. " (Level " .. assistLevelDisplay .. " " .. assistClass .. ")")
            else
                table.insert(assistNames, assist.name .. " (Unknown level and class)")
            end
        end
        BPP_Print("Assists: " .. table.concat(assistNames, ", "))
    end
end


function BPP_CreateRoleplayer()
    -- Store original functions that we'll override
    local originalGetRealZoneText = GetRealZoneText
    local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
    local originalTime = time

    -- Use pcall to ensure we can restore the functions even if there's an error
    local success, errorMsg = pcall(function()
        BPP_Print("Creating a realistic enemy roleplayer with detailed PvP history...")

        local validCombos = {
            -- Alliance
            {class = "Warrior", race = "Human", gender = 0, faction = "Alliance"},
            {class = "Paladin", race = "Human", gender = 1, faction = "Alliance"},
            {class = "Rogue", race = "Gnome", gender = 0, faction = "Alliance"},
            {class = "Hunter", race = "Dwarf", gender = 1, faction = "Alliance"},
            {class = "Mage", race = "Human", gender = 0, faction = "Alliance"},
            {class = "Warlock", race = "Gnome", gender = 1, faction = "Alliance"},
            {class = "Priest", race = "Dwarf", gender = 0, faction = "Alliance"},
            {class = "Druid", race = "NightElf", gender = 1, faction = "Alliance"},
            -- Horde
            {class = "Warrior", race = "Orc", gender = 0, faction = "Horde"},
            {class = "Hunter", race = "Troll", gender = 1, faction = "Horde"},
            {class = "Rogue", race = "Undead", gender = 0, faction = "Horde"},
            {class = "Shaman", race = "Tauren", gender = 1, faction = "Horde"},
            {class = "Mage", race = "Undead", gender = 0, faction = "Horde"},
            {class = "Warlock", race = "Orc", gender = 1, faction = "Horde"},
            {class = "Priest", race = "Troll", gender = 0, faction = "Horde"},
            {class = "Druid", race = "Tauren", gender = 1, faction = "Horde"},
        }

        local combo = validCombos[math.random(#validCombos)]

        -- Create the enemy player
        local enemyName = "Roleplayer"
        local enemyGender = combo.gender -- 0 for male, 1 for female
        local enemyRace = combo.race
        local enemyClass = combo.class
        local enemyGuild = "Sodapoppin Fanclub"
        local enemyRank = 4

        -- Start at a low level - will increase over time
        local startingEnemyLevel = math.random(10, 20)
        local startingPlayerLevel = math.random(10, 20)

        -- Filter out capital cities for more realistic leveling zones
        local levelingZones = {
            "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Tirisfal Glades", "Westfall",
            "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "The Barrens", "Ashenvale",
            "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
            "Desolace", "Dustwallow Marsh", "Eastern Plaguelands", "Felwood", "Feralas",
            "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
            "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley"
        }

        -- Generate history over the past three months
        local now = time()
        local threeMonthsAgo = now - (90 * 24 * 60 * 60) -- 90 days in seconds

        -- Create local tracking for summary report only
        local killHistory = {}
        local deathHistory = {}
        local assistHistory = {}

        -- Override GetRealZoneText and map position temporarily
        local originalGetRealZoneText = GetRealZoneText
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition

        -- Define number of encounters and progression
        local numEncounters = 8  -- Total encounters

        -- Calculate time between encounters
        local timeStep = (now - threeMonthsAgo) / numEncounters

        -- Define more realistic leveling progression with plateaus
        local enemyLevels = {}
        local playerLevels = {}

        -- Create a realistic leveling curve with staggered progression
        -- Start with random starting levels
        local enemyStartLevel = math.random(10, 20)
        local playerStartLevel = math.random(10, 20)

        -- Determine if enemy or player levels faster (50/50 chance)
        local enemyLevelsFaster = (math.random(1, 2) == 1)

        -- Generate level progression with some randomness and plateaus
        local function generateLevelProgression(startLevel, levelsFaster)
            local levels = {}
            local currentLevel = startLevel
            local levelingRate = levelsFaster and 1.2 or 0.9  -- Faster or slower rate

            for i = 1, numEncounters do
                if i > 1 then
                    -- Sometimes player stays same level (plateau in leveling)
                    if math.random(1, 10) <= 3 then  -- 30% chance to stay same level
                        currentLevel = levels[i-1]
                    else
                        -- Normal leveling with some variance
                        local levelGain = math.floor(5 * levelingRate * math.random(80, 120) / 100)
                        currentLevel = levels[i-1] + levelGain
                    end
                end

                -- Cap at level 60
                levels[i] = math.min(60, currentLevel)
            end
            return levels
        end

        enemyLevels = generateLevelProgression(enemyStartLevel, enemyLevelsFaster)
        playerLevels = generateLevelProgression(playerStartLevel, not enemyLevelsFaster)

        -- Match zone progression to level progression
        local zoneByLevelRange = {
            -- 10-20
            { min = 10, max = 20, zones = {"Westfall", "Loch Modan", "Redridge Mountains", "Silverpine Forest", "The Barrens"} },
            -- 20-30
            { min = 20, max = 30, zones = {"Duskwood", "Ashenvale", "Hillsbrad Foothills", "Wetlands", "Stonetalon Mountains"} },
            -- 30-40
            { min = 30, max = 40, zones = {"Desolace", "Arathi Highlands", "Stranglethorn Vale", "Thousand Needles", "Alterac Mountains"} },
            -- 40-50
            { min = 40, max = 50, zones = {"Tanaris", "Feralas", "Hinterlands", "Searing Gorge", "Felwood", "Azshara"} },
            -- 50-60
            { min = 50, max = 60, zones = {"Un'Goro Crater", "Burning Steppes", "Western Plaguelands", "Eastern Plaguelands", "Winterspring", "Silithus", "Blackrock Mountain"} },
        }

        -- Get appropriate zone for a level
        local function getZoneForLevel(level)
            for _, range in ipairs(zoneByLevelRange) do
                if level >= range.min and level <= range.max then
                    return range.zones[math.random(#range.zones)]
                end
            end
            return "Elwynn Forest"  -- Fallback
        end

        local lastEncounterName = nil

        -- For each encounter, create a realistic interaction
        for i = 1, numEncounters do
            local encounterTime = threeMonthsAgo + (i * timeStep)

            local encounterEnemyName = BPP_DebugApplyRandomRealm(enemyName)
            lastEncounterName = encounterEnemyName

            -- Get pre-determined levels for this encounter
            local currentEnemyLevel = enemyLevels[i]
            local currentPlayerLevel = playerLevels[i]

            -- Choose a zone appropriate for current levels (use average level to determine zone)
            local avgLevel = math.floor((currentEnemyLevel + currentPlayerLevel) / 2)
            local encounterZone = getZoneForLevel(avgLevel)

            -- Update player info for this encounter
            local enemyGuildRank = enemyGuild == "" and "" or BPP_guildRanks[math.random(1, #BPP_guildRanks)]
            BPP_StorePlayerInfo(encounterEnemyName, currentEnemyLevel, enemyClass, enemyRace, enemyGender, enemyGuild, enemyGuildRank, enemyRank)

            -- Set up time and zone overrides
            GetRealZoneText = function() return encounterZone end
            local randomX = 10.0 + (90.0 - 10.0) * math.random()
            local randomY = 10.0 + (90.0 - 10.0) * math.random()
            C_Map.GetPlayerMapPosition = function(mapID, unit)
                return { x = randomX / 100, y = randomY / 100 }
            end

            -- Set up timestamp override using our custom time
            -- Use a local wrapper function instead of directly replacing the global
            local savedTime = time
            time = function() return encounterTime end

            -- Determine outcome of encounter (alternating wins and losses with some randomness)
            local rand = math.random(100)

            if (i % 3 == 0) or (rand < 30) then
                -- SIMULATE DEATH: Roleplayer killed you
                local killerInfo = {
                    killer = {
                        name = encounterEnemyName,
                        guid = "Simulated-Killer-GUID-" .. math.random(1000000),
                        damage = 1000,
                        isPet = false
                    },
                    assists = {}
                }

                -- Add assist if it's a higher-level area (more likely to encounter groups)
                if i > numEncounters/2 and rand > 50 then
                    local otherAssist = BPP_GetRandomTestPlayer()
                    local assistLevel = currentEnemyLevel + math.random(-2, 2) -- Similar level to enemy
                    assistLevel = math.min(60, math.max(1, assistLevel))

                    local otherAssistName = BPP_DebugApplyRandomRealm(otherAssist.name)
                    BPP_StorePlayerInfo(otherAssistName, assistLevel, otherAssist.class,
                                       otherAssist.race, otherAssist.gender, otherAssist.guildName, otherAssist.guildRankName, otherAssist.rank)

                    table.insert(killerInfo.assists, {
                        name = otherAssistName,
                        level = assistLevel,
                        class = otherAssist.class
                    })
                end

                -- Register the death
                BPP_RegisterPlayerDeath(killerInfo)

                -- Save for summary report
                table.insert(deathHistory, {
                    killer = encounterEnemyName,
                    timestamp = encounterTime,
                    zone = encounterZone,
                    killerLevel = currentEnemyLevel,
                    playerLevel = currentPlayerLevel
                })
            elseif (i % 3 == 1) or (rand >= 30 and rand < 70) then
                -- SIMULATE KILL: You killed Roleplayer
                BPP_RegisterPlayerKill(encounterEnemyName)

                -- Save for summary report
                table.insert(killHistory, {
                    victim = encounterEnemyName,
                    timestamp = encounterTime,
                    zone = encounterZone,
                    level = currentEnemyLevel,
                    playerLevel = currentPlayerLevel
                })
            else
                -- SIMULATE ASSIST: Roleplayer assisted in killing you
                local mainKiller = BPP_GetRandomTestPlayer()
                local mainKillerName = BPP_DebugApplyRandomRealm(mainKiller.name)
                local killerLevel = currentEnemyLevel + math.random(-2, 2) -- Similar level to enemy
                killerLevel = math.min(60, math.max(1, killerLevel))

                BPP_StorePlayerInfo(mainKillerName, killerLevel, mainKiller.class,
                                   mainKiller.race, mainKiller.gender, mainKiller.guildName, mainKiller.guildRankName, mainKiller.rank)

                -- Create killer info structure with Roleplayer as an assister
                local killerInfo = {
                    killer = {
                        name = mainKillerName,
                        guid = "Simulated-Killer-GUID-" .. math.random(1000000),
                        damage = 1000,
                        isPet = false
                    },
                    assists = {
                        {
                            name = encounterEnemyName,
                            level = currentEnemyLevel,
                            class = enemyClass
                        }
                    }
                }

                -- Add another assister sometimes (more likely in higher level zones)
                if i > numEncounters/2 and rand > 50 then
                    local otherAssist = BPP_GetRandomTestPlayer()
                    local assistLevel = currentEnemyLevel + math.random(-2, 2)
                    assistLevel = math.min(60, math.max(1, assistLevel))

                    local otherAssistName = BPP_DebugApplyRandomRealm(otherAssist.name)
                    BPP_StorePlayerInfo(otherAssistName, assistLevel, otherAssist.class,
                                       otherAssist.race, otherAssist.gender, otherAssist.guildName, otherAssist.guildRankName, otherAssist.rank)

                    table.insert(killerInfo.assists, {
                        name = otherAssistName,
                        level = assistLevel,
                        class = otherAssist.class
                    })
                end

                -- Register the death
                BPP_RegisterPlayerDeath(killerInfo)

                -- Track for summary report
                local assistEntryMembers = {
                    encounterEnemyName .. " (Level " .. currentEnemyLevel .. " " .. enemyClass .. ")"
                }

                -- Add other assister to report if exists
                if #killerInfo.assists > 1 then
                    local otherAssistEntry = killerInfo.assists[2]
                    table.insert(assistEntryMembers,
                        otherAssistEntry.name .. " (Level " .. otherAssistEntry.level .. " " .. otherAssistEntry.class .. ")")
                end

                table.insert(assistHistory, {
                    victim = "You",
                    timestamp = encounterTime,
                    zone = encounterZone,
                    mainKiller = mainKillerName,
                    groupMembers = assistEntryMembers,
                    playerLevel = currentPlayerLevel
                })
            end

            -- Restore time function immediately after each encounter
            time = savedTime
        end

        -- Generate a summary report
        local summaryName = lastEncounterName or enemyName
        BPP_Print("\n== " .. summaryName .. "'s PvP History with You ==")
        -- Fix: Calculate final level without using enemyLevelStep
        local finalEnemyLevel = enemyLevels[#enemyLevels]
        BPP_Print("Currently Level " .. finalEnemyLevel .. " " .. enemyRace .. " " .. enemyClass .. " <" .. enemyGuild .. ">")
        BPP_Print("First encountered at level " .. enemyStartLevel .. " when you were level " .. playerStartLevel)

        -- Format your kills against Roleplayer
        BPP_Print("\nTimes You Killed " .. summaryName .. ":")
        for i, kill in ipairs(killHistory) do
            local dateStr = date("%m/%d/%y %H:%M", kill.timestamp)
            BPP_Print(" - " .. dateStr .. " - Level " .. kill.level .. " in " .. kill.zone ..
                      " (You were level " .. kill.playerLevel .. ")")
        end

        -- Format times Roleplayer killed you
        BPP_Print("\nTimes " .. summaryName .. " Killed You:")
        for i, death in ipairs(deathHistory) do
            local dateStr = date("%m/%d/%y %H:%M", death.timestamp)
            BPP_Print(" - " .. dateStr .. " - Level " .. death.killerLevel .. " in " .. death.zone ..
                      " (You were level " .. death.playerLevel .. ")")
        end

        -- Format assists
        BPP_Print("\nGroup Activity:")
        for i, assist in ipairs(assistHistory) do
            local dateStr = date("%m/%d/%y %H:%M", assist.timestamp)
            BPP_Print(" - " .. dateStr .. " - " .. summaryName .. " assisted " .. assist.mainKiller ..
                      " in killing you in " .. assist.zone .. " (You were level " .. assist.playerLevel .. ")")
            BPP_Print("   Group: " .. assist.mainKiller .. ", " .. table.concat(assist.groupMembers, ", "))
        end

        -- Add the character to a special list so we can find them later
        if not BPP_DB.RolePlayers then
            BPP_DB.RolePlayers = {}
        end
        table.insert(BPP_DB.RolePlayers, {
            name = summaryName,
            level = finalEnemyLevel,
            class = enemyClass,
            race = enemyRace,
            gender = enemyGender,
            guild = enemyGuild,
            rank = enemyRank,
            created = now
        })
    end)

    -- Always restore the original functions, even if there was an error
    GetRealZoneText = originalGetRealZoneText
    C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
    time = originalTime

    -- Report any error that occurred
    if not success then
        BPP_Print("Error creating roleplayer: " .. (errorMsg or "Unknown error"))
    else
        BPP_Print("\nCreated roleplayer character with complete leveling history!")
        BPP_Print("You can find this character in your main kill and death statistics.")
    end
end

-- Function to generate test streak data for testing BPP_CountConsecutiveDaysWithMinKills
function BPP_GenerateStreakTestData(days, killsPerDay, daysAgo)
    -- If daysAgo is not specified, calculate it so the streak ends yesterday (no future timestamps)
    if not daysAgo then
        daysAgo = days  -- Start 'days' days ago so the streak ends yesterday
    end

    local currentTime = time()
    local startTime = currentTime - (daysAgo * 24 * 60 * 60) -- Start daysAgo days in the past
    local endTime = startTime + ((days - 1) * 24 * 60 * 60) -- Calculate end time for validation

    BPP_Print(string.format("Generating %d days of test data with %d kills per day, starting %d days ago...",
        days, killsPerDay, daysAgo))

    -- Show the date range for clarity
    local startDateStr = date("%Y-%m-%d", startTime)
    local endDateStr = date("%Y-%m-%d", endTime)
    BPP_Print(string.format("Date range: %s to %s (streak ends yesterday)", startDateStr, endDateStr))

    local totalKillsAdded = 0

    -- Store original time function
    local originalTime = time

    for day = 0, days - 1 do
        local dayTime = startTime + (day * 24 * 60 * 60)
        local dateStr = date("%Y-%m-%d", dayTime)

        BPP_Print(string.format("Generating %d kills for %s...", killsPerDay, dateStr))

        -- Generate one test player for this entire day
        local testPlayer = BPP_GetRandomTestPlayer()
        local dailyVictimName = "StreakTest_Day" .. day .. "_" .. testPlayer.name
        local dailyVictimNameWithRealm = BPP_DebugApplyRandomRealm(dailyVictimName)

        for kill = 1, killsPerDay do
            -- Create timestamps starting at noon and add one second per kill (ensures all kills stay within the same day)
            local killTime = dayTime + (12 * 60 * 60) + kill -- Start at noon (12:00) and add one second per kill

            -- Override time() function temporarily for this kill
            time = function() return killTime end

            -- Use existing zone selection from BPP_SimulatePlayerKills
            local zones = {
                "Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Darnassus", "Undercity",
                "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Tirisfal Glades", "Westfall",
                "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "The Barrens", "Ashenvale",
                "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
                "Desolace", "Dustwallow Marsh", "Eastern Plaguelands", "Felwood", "Feralas",
                "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
                "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley"
            }

            -- Temporarily override GetRealZoneText to return a random zone (same for the day)
            local randomZone = zones[math.random(#zones)]
            local originalGetRealZoneText = GetRealZoneText
            GetRealZoneText = function() return randomZone end

            -- Generate random coordinates like BPP_SimulatePlayerKills does
            local randomX = 10.0 + (90.0 - 10.0) * math.random()
            local randomY = 10.0 + (90.0 - 10.0) * math.random()

            -- Override C_Map.GetPlayerMapPosition for this simulation
            local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
            C_Map.GetPlayerMapPosition = function(mapID, unit)
                return { x = randomX / 100, y = randomY / 100 }
            end

            -- Store player info in cache using our daily victim name
            BPP_StorePlayerInfo(dailyVictimNameWithRealm, testPlayer.level, testPlayer.class,
                testPlayer.race, testPlayer.gender, testPlayer.guildName, testPlayer.guildRankName,
                testPlayer.rank)
            BPP_RegisterPlayerKill(dailyVictimNameWithRealm)

            -- Restore the original functions immediately
            C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
            GetRealZoneText = originalGetRealZoneText

            totalKillsAdded = totalKillsAdded + 1
        end

        BPP_Print(string.format("  -> Killed %s %d times on %s", dailyVictimNameWithRealm, killsPerDay, dateStr))
    end

    -- Restore original time function
    time = originalTime

    BPP_Print(string.format("Test data generation complete! Total kills added: %d", totalKillsAdded))
    BPP_Print("You can now test the streak function with various commands:")
    BPP_Print("- View achievements to see current streaks")
    BPP_Print("- Use '/bpp debug' to see total kill counts")
end
