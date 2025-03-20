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
                    local amount = combatEvent == "SWING_DAMAGE" and param1 or (combatEvent == "SPELL_DAMAGE" and param4 or 0)

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

local function GetRandomTestData()
    local randomNames = {
        "Testplayer", "Gankalicious", "Pwnyou", "Backstabber", "Shadowmelter",
        "Campmaster", "Roguenstein", "Sneakattack", "Huntard", "Faceroller"
    }

    local randomClass = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
                         "SHAMAN", "MAGE", "WARLOCK", "DRUID"}

    return randomNames, randomClass
end

function PSC_SimulateCombatLogEvent(killerCount, assistCount, damageType)
    PSC_Print("Simulating combat log events for a death with " ..
              killerCount .. " killer(s) and " .. assistCount .. " assists...")

    local randomNames, randomClass = GetRandomTestData()

    local mainKillerName = randomNames[math.random(#randomNames)]
    local mainKillerGUID = "Player-0-" .. math.random(1000000)
    local mainKillerClass = randomClass[math.random(#randomClass)]

    PSC_RecentDamageFromPlayers = {}

    local now = GetTime()

    TrackIncomingPlayerDamage(mainKillerGUID, mainKillerName, 1000)

    local assistList = {}
    for i = 1, assistCount do
        local assistName = randomNames[math.random(#randomNames)]
        while assistName == mainKillerName or tContains(assistList, assistName) do
            assistName = randomNames[math.random(#randomNames)]
        end

        local assistGUID = "Player-0-" .. math.random(1000000)
        TrackIncomingPlayerDamage(assistGUID, assistName, 500)
        table.insert(assistList, assistName)
    end

    HandlePlayerDeath()

    -- Print a summary of what happened
    local characterKey = PSC_GetCharacterKey()
    if PSC_DB.PvPLossCounts and PSC_DB.PvPLossCounts[characterKey] then
        local deathCount = 0
        if PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName] then
            deathCount = PSC_DB.PvPLossCounts[characterKey].Deaths[mainKillerName].deaths
        end

        PSC_Print("Death simulation complete! Killed by " .. mainKillerName ..
                 " (" .. mainKillerClass .. ") - Total deaths to them: " .. deathCount)

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

function PSC_SimulatePlayerDeath()
    PSC_Print("Simulating player death...")

    if PSC_DB.CurrentKillStreak >= 10 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
        local streakEndedMsg = string.gsub(PSC_DB.KillStreakEndedMessage, "STREAKCOUNT", PSC_DB.CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    PSC_DB.CurrentKillStreak = 0
    PSC_MultiKillCount = 0
    PSC_InCombat = false
    PSC_Print("Death simulated! Kill streak reset.")
end

function PSC_SimulatePlayerKills(killCount)
    PSC_Print("Registering " .. killCount .. " random test kill(s)...")

    local randomNames = {
        "Testplayer",
        "Gankalicious", "Pwnyou", "Backstabber", "Shadowmelter", "Campmaster",
        "Roguenstein", "Sneakattack", "Huntard", "Faceroller", "Dotspammer",
        "Moonbender", "Healnoob", "Ragequitter", "Imbalanced", "Critmaster",
        "Zerglord", "Epicfail", "Oneshot", "Griefer", "Farmville",
        "Stunlock", "Procmaster", "Noobslayer", "Bodycamper", "Flagrunner"
    }

    local randomGuilds = {
        "Gank Squad", "PvP Masters", "Corpse Campers", "World Slayers", "Honor Farmers",
        "Rank Grinders", "Blood Knights", "Deadly Alliance", "Battleground Heroes", "Warsong Outlaws",
        "Death and Taxes", "Tactical Retreat", "Shadow Dancers", "First Strike", "Elite Few",
        "Kill on Sight", "No Mercy", "Rogues Do It", "Battlefield Legends", ""  -- Empty guild possible
    }

    local classes = {
        "Warrior", "Paladin", "Hunter", "Rogue", "Priest",
        "Shaman", "Mage", "Warlock", "Druid"
    }

    local races = {
        "Human", "Dwarf", "Night Elf", "Gnome",
    }

    local genders = {"Male", "Female"}

    -- Add random zones for testing
    local randomZones = {
        "Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Darnassus", "Undercity",
        "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Tirisfal Glades", "Westfall",
        "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "The Barrens", "Ashenvale",
        "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
        "Desolace", "Dustwallow Marsh", "Eastern Plaguelands", "Felwood", "Feralas",
        "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
        "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley"
    }

    for i = 1, killCount do
        local randomName = randomNames[math.random(#randomNames)]
        local randomGuild = randomGuilds[math.random(#randomGuilds)]
        local randomClass = classes[math.random(#classes)]
        local randomRace = races[math.random(#races)]
        local randomGender = genders[math.random(#genders)]
        local randomZone = randomZones[math.random(#randomZones)]

        local randomLevel = math.min(60, math.floor(math.random() * math.random() * 60) + 1)
        if math.random(100) <= 15 then  -- 15% chance for unknown level
            randomLevel = -1
        end

        -- Generate random rank (0-14)
        -- Higher chance for lower ranks, lower chance for high ranks
        local rankChance = math.random(100)
        local randomRank = 0

        if rankChance <= 40 then
            -- 40% chance for rank 0 (no rank)
            randomRank = 0
        elseif rankChance <= 70 then
            -- 30% chance for ranks 1-4 (Private to Master Sergeant)
            randomRank = math.random(1, 4)
        elseif rankChance <= 90 then
            -- 20% chance for ranks 5-8 (Sergeant Major to Knight-Captain)
            randomRank = math.random(5, 8)
        elseif rankChance <= 98 then
            -- 8% chance for ranks 9-12 (Knight-Champion to Marshal)
            randomRank = math.random(9, 12)
        else
            -- 2% chance for ranks 13-14 (Field Marshal and Grand Marshal)
            randomRank = math.random(13, 14)
        end

        -- Temporarily override GetRealZoneText to return our random zone
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        local randomX = 10.0 + (90.0 - 10.0) * math.random()
        local randomY = 10.0 + (90.0 - 10.0) * math.random()

        -- Override C_Map.GetPlayerMapPosition for this simulation
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
---@diagnostic disable-next-line: duplicate-set-field
        C_Map.GetPlayerMapPosition = function(mapID, unit)
            return {x = randomX/100, y = randomY/100}
        end

        -- Register the kill with random data including rank
        randomLevel = 60
        PSC_StorePlayerInfo(randomName, randomLevel, randomClass, randomRace, randomGender, randomGuild, randomRank)
        PSC_RegisterPlayerKill(randomName)

        -- Restore the original functions
        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    PSC_Print("Successfully registered " .. killCount .. " random test kill(s).")
end

function PSC_SimulatePlayerDeathByEnemy(killerCount, assistCount)
    PSC_Print("Simulating death by " .. killerCount .. " enemy player(s) with " .. assistCount .. " assists...")

    -- Use the same random names pool as in your kill simulation
    local randomNames = {
        "Testplayer", "Gankalicious", "Pwnyou", "Backstabber", "Shadowmelter",
        "Campmaster", "Roguenstein", "Sneakattack", "Huntard", "Faceroller",
        "Dotspammer", "Moonbender", "Healnoob", "Ragequitter", "Imbalanced",
        "Critmaster", "Zerglord", "Epicfail", "Oneshot", "Griefer",
        "Farmville", "Stunlock", "Procmaster", "Noobslayer", "Bodycamper"
    }

    -- Generate random zone
    local randomZones = {
        "Stormwind City", "Ironforge", "Darnassus", "Westfall",
        "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "Ashenvale",
        "Alterac Mountains", "Arathi Highlands", "Badlands", "Burning Steppes",
        "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
        "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin"
    }

    local zone = randomZones[math.random(#randomZones)]

    -- Override GetRealZoneText for this simulation
    local originalGetRealZoneText = GetRealZoneText
    GetRealZoneText = function() return zone end

    -- Override map position
    local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
    local randomX = 10.0 + (90.0 - 10.0) * math.random()
    local randomY = 10.0 + (90.0 - 10.0) * math.random()

---@diagnostic disable-next-line: duplicate-set-field
    C_Map.GetPlayerMapPosition = function(mapID, unit)
        return {x = randomX/100, y = randomY/100}
    end

    -- Create a simulated killer info structure
    local killerInfo = {
        killer = {
            name = randomNames[math.random(#randomNames)],
            guid = "Simulated-Killer-GUID-" .. math.random(1000000),
            damage = 1000,
            isPet = false
        },
        assists = {}
    }

    -- Add assists
    for i = 1, assistCount do
        local assistName = randomNames[math.random(#randomNames)]
        while assistName == killerInfo.killer.name do
            assistName = randomNames[math.random(#randomNames)]
        end

        table.insert(killerInfo.assists, {
            name = assistName,
            guid = "Simulated-Assist-GUID-" .. math.random(1000000)
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
end
