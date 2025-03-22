function PSC_DebugPetKills()
    print("Enabling pet kill debugging for 120 seconds...")

    local originalHandler = HandleCombatLogEvent

    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4 = CombatLogGetCurrentEventInfo()

        originalHandler()

        if IsPetGUID(sourceGUID) then
            local ownerGUID = GetPetOwnerGUID(sourceGUID)

            if ownerGUID == PSC_PlayerGUID then
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
            local petDamage = RecentPetDamage[destGUID]
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

function PSC_DebugCombatLogEvents()
    print("Enabling enhanced combat log debugging for 30 seconds...")

    local originalHandler = HandleCombatLogEvent

    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
        destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        -- Print out kill-related events
        if (combatEvent == "UNIT_DIED" or combatEvent == "PARTY_KILL") and
            bit.band(destFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER or 0) > 0 then
            print("EVENT: " .. combatEvent)
            print("SOURCE: " .. (sourceName or "nil") .. " (" .. (sourceGUID or "nil") .. ")")
            print("TARGET: " .. (destName or "nil") .. " (" .. (destGUID or "nil") .. ")")
            print("FLAGS: source=" .. (sourceFlags or 0) .. ", dest=" .. (destFlags or 0))
            print("-----------------------------------")
        end

        originalHandler()
    end

    C_Timer.After(30, function()
        print("Combat log debugging ended.")
        HandleCombatLogEvent = originalHandler
    end)
end

function PSC_SimulateCombatLogEvent(killerCount, assistCount, damageType)
    PSC_Print("Simulating combat log events for a death with " ..
        killerCount .. " killer(s) and " .. assistCount .. " assists...")

    local randomPlayer = PSC_GetRandomTestPlayer()

    local mainKillerName = randomPlayer.name
    local mainKillerGUID = "Player-0-" .. math.random(1000000)
    local mainKillerClass = randomPlayer.class
    local mainKillerLevel = randomPlayer.level
    PSC_RecentDamageFromPlayers = {}

    -- Store killer level in PlayerInfoCache
    PSC_StorePlayerInfo(mainKillerName, mainKillerLevel, mainKillerClass,
        randomPlayer.race, randomPlayer.gender, randomPlayer.guildName, randomPlayer.rank)

    local now = GetTime()

    TrackIncomingPlayerDamage(mainKillerGUID, mainKillerName, 1000)

    local assistList = {}
    for i = 1, assistCount do
        local randomPlayer = PSC_GetRandomTestPlayer()
        local assistName = randomPlayer.name
        while assistName == mainKillerName or tContains(assistList, assistName) do
            randomPlayer = PSC_GetRandomTestPlayer()
            assistName = randomPlayer.name
        end

        -- Store assist player level in PlayerInfoCache
        PSC_StorePlayerInfo(assistName, randomPlayer.level, randomPlayer.class,
            randomPlayer.race, randomPlayer.gender, randomPlayer.guildName, randomPlayer.rank)

        local assistGUID = "Player-0-" .. math.random(1000000)
        TrackIncomingPlayerDamage(assistGUID, assistName, 500)
        table.insert(assistList, assistName)
    end

    HandlePlayerDeath()

    -- Print a summary of what happened
    local characterKey = PSC_GetCharacterKey()
    if PSC_DB.PvPLossCounts and PSC_DB.PvPLossCounts[characterKey] then
        local deathCount = 0
        local killerLevel = "unknown"

        if PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName] then
            local deathData = PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName]
            deathCount = deathData.deaths
            killerLevel = deathData.killerLevel
        end

        PSC_Print("Death simulation complete! Killed by " .. mainKillerName ..
            " (Level " .. killerLevel .. " " .. mainKillerClass .. ") - Total deaths to them: " .. deathCount)

        -- Show assist information if applicable
        if assistCount > 0 and PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName] then
            local lastDeath = PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName].deathLocations[#PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName].deathLocations]
            if lastDeath and lastDeath.assisters then
                local assistInfo = "Assisters: "
                for i, assist in ipairs(lastDeath.assisters) do
                    assistInfo = assistInfo .. assist.name .. " (Level " .. assist.level .. ")"
                    if i < #lastDeath.assisters then
                        assistInfo = assistInfo .. ", "
                    end
                end
                PSC_Print(assistInfo)
            end
        end
    end
end

function PSC_RunDeathTrackingTests()
    PSC_Print("Running comprehensive death tracking tests...")

    PSC_Print("\nTest 1: Solo kill")
    PSC_SimulateCombatLogEvent(1, 0, "direct")

    PSC_Print("\nTest 2: Kill with assists")
    PSC_SimulateCombatLogEvent(1, 2, "direct")

    PSC_Print("\nTest 3: Kill with multiple damage types")
    PSC_SimulateCombatLogEvent(1, 1, "mixed")

    PSC_Print("Death tracking tests complete!")
end

function PSC_ShowDebugInfo()
    PSC_Print("Current Kill Streak: " .. PSC_DB.PlayerKillCounts.Characters[PSC_GetCharacterKey()].CurrentKillStreak)
    PSC_Print("Highest Kill Streak: " .. PSC_DB.PlayerKillCounts.Characters[PSC_GetCharacterKey()].HighestKillStreak)
    PSC_Print("Current Multi-kill Count: " .. PSC_MultiKillCount)
    PSC_Print("Highest Multi-kill: " .. PSC_DB.PlayerKillCounts.Characters[PSC_GetCharacterKey()].HighestMultiKill)

    local characterKey = PSC_GetCharacterKey()
    if PSC_DB.PvPLossCounts and PSC_DB.PvPLossCounts[characterKey] then
        local totalDeaths = 0
        local totalSoloDeaths = 0
        local totalAssistDeaths = 0

        for _, deathData in pairs(PSC_DB.PvPLossCounts[characterKey].Deaths) do
            totalDeaths = totalDeaths + deathData.deaths
            totalSoloDeaths = totalSoloDeaths + (deathData.soloKills or 0)
            totalAssistDeaths = totalAssistDeaths + (deathData.assistKills or 0)
        end

        PSC_Print("Total Deaths: " .. totalDeaths ..
            " (Solo: " .. totalSoloDeaths ..
            ", Group: " .. totalAssistDeaths .. ")")
    else
        PSC_Print("Total Deaths: 0")
    end

    PSC_Print("Multi-kill Announcement Threshold: " .. PSC_DB.MultiKillThreshold)
    PSC_Print("Battleground Mode: " .. (PSC_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    PSC_Print("Auto BG Detection: " .. (PSC_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    PSC_Print("Manual BG Mode: " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

local function CreateKillDebugMessage(playerName, nameWithLevel, killerName, killerGUID)
    local debugMsg = "Killed: " .. playerName

    local level = PSC_DB.PlayerInfoCache[playerName].level
    local class = PSC_DB.PlayerInfoCache[playerName].class
    local race = PSC_DB.PlayerInfoCache[playerName].race

    local playerLevel = UnitLevel("player")
    local levelDifference = level > 0 and (level - playerLevel) or 0
    if level == -1 or (level > 0 and levelDifference >= 5) then
        debugMsg = debugMsg .. " (Level " .. (level == -1 and "??" or level)
    else
        debugMsg = debugMsg .. " ("
    end

    debugMsg = debugMsg .. class .. ", " .. race .. ")"

    local rank = PSC_DB.PlayerKillCounts[nameWithLevel].rank or 0
    if rank > 0 then
        debugMsg = debugMsg .. " [Rank: " .. rank .. "]"
    end

    debugMsg = debugMsg .. " - Total kills: " .. PSC_DB.PlayerKillCounts[nameWithLevel].kills
    debugMsg = debugMsg .. " - Current streak: " .. PSC_DB.CurrentKillStreak
    debugMsg = debugMsg .. " - Zone: " .. (PSC_DB.PlayerKillCounts[nameWithLevel].zone or "Unknown")

    -- Check what kind of kill this was
    if killerGUID and IsPetGUID(killerGUID) then
        debugMsg = debugMsg .. " - Kill by: Your Pet (" .. (killerName or "Unknown") .. ")"
    elseif killerName == "Assist" then
        debugMsg = debugMsg .. " - Assist Kill (mob/environment finished target)"
    end

    if PSC_MultiKillCount >= 2 then
        debugMsg = debugMsg .. " - " .. GetMultiKillText(PSC_MultiKillCount)
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
    "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley"
}

function PSC_SimulatePlayerKills(killCount)
    for i = 1, killCount do
        local testPlayer = PSC_GetRandomTestPlayer()

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
        PSC_StorePlayerInfo(testPlayer.name, testPlayer.level, testPlayer.class,
            testPlayer.race, testPlayer.gender, testPlayer.guildName,
            testPlayer.rank)
        PSC_RegisterPlayerKill(testPlayer.name)

        -- Restore the original functions
        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    PSC_Print("Registered " .. killCount .. " random test kill(s).")
end

function PSC_SimulatePlayerDeathByEnemy(killerCount, assistCount)
    PSC_Print("Simulating death by " .. killerCount .. " enemy player(s) with " .. assistCount .. " assists...")

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

    -- Generate a killer using PSC_GetRandomTestPlayer
    local killerPlayer = PSC_GetRandomTestPlayer()
    local killerName = killerPlayer.name
    local killerClass = killerPlayer.class
    local killerLevel = killerPlayer.level
    local killerRace = killerPlayer.race
    local killerGender = killerPlayer.gender
    local killerGuild = killerPlayer.guildName
    local killerRank = killerPlayer.rank

    -- Store killer info in cache
    PSC_StorePlayerInfo(killerName, killerLevel, killerClass, killerRace, killerGender, killerGuild, killerRank)

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

    local usedNames = {killerName}
    for i = 1, assistCount do
        local assistPlayer = PSC_GetRandomTestPlayer()
        -- Ensure unique names
        while tContains(usedNames, assistPlayer.name) do
            assistPlayer = PSC_GetRandomTestPlayer()
        end

        table.insert(usedNames, assistPlayer.name)

        local rndNumber = math.random(100)
        if rndNumber <= 50 then
            -- Sometimes don't store assist info because it might happen that we don't mouseover or target a player that assists in a kill
            print("Storing assist info for " .. assistPlayer.name)
            PSC_StorePlayerInfo(assistPlayer.name, assistPlayer.level, assistPlayer.class,
                            assistPlayer.race, assistPlayer.gender, assistPlayer.guildName, assistPlayer.rank)
        end
        -- Add assist without guid
        table.insert(killerInfo.assists, {
            name = assistPlayer.name
        })
    end

    local characterKey = PSC_GetCharacterKey()

    -- Reset kill streak
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]
    characterData.CurrentKillStreak = 0

    -- Register the death with our handler
    PSC_RegisterPlayerDeath(killerInfo)

    -- Restore original functions
    GetRealZoneText = originalGetRealZoneText
    C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition

    PSC_Print("Death simulation complete!")

    -- Print summary of death data
    local killerLevelDisplay = killerLevel == -1 and "??" or killerLevel
    PSC_Print("Killed by: " .. killerName .. " (Level " .. killerLevelDisplay .. " " .. killerClass .. ")")

    if assistCount > 0 then
        local assistNames = {}
        for _, assist in ipairs(killerInfo.assists) do
            if PSC_DB.PlayerInfoCache[assist.name] ~= nil then
                local assistLevel = PSC_DB.PlayerInfoCache[assist.name].level
                local assistLevelDisplay = assistLevel == -1 and "??" or assistLevel
                local assistClass = PSC_DB.PlayerInfoCache[assist.name].class
                table.insert(assistNames, assist.name .. " (Level " .. assistLevelDisplay .. " " .. assistClass .. ")")
            else
                table.insert(assistNames, assist.name .. " (Unknown level and class)")
            end
        end
        PSC_Print("Assists: " .. table.concat(assistNames, ", "))
    end
end
