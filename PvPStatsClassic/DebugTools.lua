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

    local infoKey = PSC_GetInfoKeyFromName(playerName)

    local level = PSC_DB.PlayerInfoCache[infoKey].level
    local class = PSC_DB.PlayerInfoCache[infoKey].class
    local race = PSC_DB.PlayerInfoCache[infoKey].race

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
            local assistInfoKey = PSC_GetInfoKeyFromName(assist.name)

            if PSC_DB.PlayerInfoCache[assistInfoKey] ~= nil then
                local assistLevel = PSC_DB.PlayerInfoCache[assistInfoKey].level
                local assistLevelDisplay = assistLevel == -1 and "??" or assistLevel
                local assistClass = PSC_DB.PlayerInfoCache[assistInfoKey].class
                table.insert(assistNames, assist.name .. " (Level " .. assistLevelDisplay .. " " .. assistClass .. ")")
            else
                table.insert(assistNames, assist.name .. " (Unknown level and class)")
            end
        end
        PSC_Print("Assists: " .. table.concat(assistNames, ", "))
    end
end


function PSC_CreateRoleplayer()
    -- Store original functions that we'll override
    local originalGetRealZoneText = GetRealZoneText
    local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
    local originalTime = time

    -- Use pcall to ensure we can restore the functions even if there's an error
    local success, errorMsg = pcall(function()
        PSC_Print("Creating a realistic enemy roleplayer with detailed PvP history...")

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

        -- For each encounter, create a realistic interaction
        for i = 1, numEncounters do
            local encounterTime = threeMonthsAgo + (i * timeStep)

            -- Get pre-determined levels for this encounter
            local currentEnemyLevel = enemyLevels[i]
            local currentPlayerLevel = playerLevels[i]

            -- Choose a zone appropriate for current levels (use average level to determine zone)
            local avgLevel = math.floor((currentEnemyLevel + currentPlayerLevel) / 2)
            local encounterZone = getZoneForLevel(avgLevel)

            -- Update player info for this encounter
            PSC_StorePlayerInfo(enemyName, currentEnemyLevel, enemyClass, enemyRace, enemyGender, enemyGuild, enemyRank)

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
                        name = enemyName,
                        guid = "Simulated-Killer-GUID-" .. math.random(1000000),
                        damage = 1000,
                        isPet = false
                    },
                    assists = {}
                }

                -- Add assist if it's a higher-level area (more likely to encounter groups)
                if i > numEncounters/2 and rand > 50 then
                    local otherAssist = PSC_GetRandomTestPlayer()
                    local assistLevel = currentEnemyLevel + math.random(-2, 2) -- Similar level to enemy
                    assistLevel = math.min(60, math.max(1, assistLevel))

                    PSC_StorePlayerInfo(otherAssist.name, assistLevel, otherAssist.class,
                                       otherAssist.race, otherAssist.gender, otherAssist.guildName, otherAssist.rank)

                    table.insert(killerInfo.assists, {
                        name = otherAssist.name,
                        level = assistLevel,
                        class = otherAssist.class
                    })
                end

                -- Register the death
                PSC_RegisterPlayerDeath(killerInfo)

                -- Save for summary report
                table.insert(deathHistory, {
                    killer = enemyName,
                    timestamp = encounterTime,
                    zone = encounterZone,
                    killerLevel = currentEnemyLevel,
                    playerLevel = currentPlayerLevel
                })
            elseif (i % 3 == 1) or (rand >= 30 and rand < 70) then
                -- SIMULATE KILL: You killed Roleplayer
                PSC_RegisterPlayerKill(enemyName)

                -- Save for summary report
                table.insert(killHistory, {
                    victim = enemyName,
                    timestamp = encounterTime,
                    zone = encounterZone,
                    level = currentEnemyLevel,
                    playerLevel = currentPlayerLevel
                })
            else
                -- SIMULATE ASSIST: Roleplayer assisted in killing you
                local mainKiller = PSC_GetRandomTestPlayer()
                local killerLevel = currentEnemyLevel + math.random(-2, 2) -- Similar level to enemy
                killerLevel = math.min(60, math.max(1, killerLevel))

                PSC_StorePlayerInfo(mainKiller.name, killerLevel, mainKiller.class,
                                   mainKiller.race, mainKiller.gender, mainKiller.guildName, mainKiller.rank)

                -- Create killer info structure with Roleplayer as an assister
                local killerInfo = {
                    killer = {
                        name = mainKiller.name,
                        guid = "Simulated-Killer-GUID-" .. math.random(1000000),
                        damage = 1000,
                        isPet = false
                    },
                    assists = {
                        {
                            name = enemyName,
                            level = currentEnemyLevel,
                            class = enemyClass
                        }
                    }
                }

                -- Add another assister sometimes (more likely in higher level zones)
                if i > numEncounters/2 and rand > 50 then
                    local otherAssist = PSC_GetRandomTestPlayer()
                    local assistLevel = currentEnemyLevel + math.random(-2, 2)
                    assistLevel = math.min(60, math.max(1, assistLevel))

                    PSC_StorePlayerInfo(otherAssist.name, assistLevel, otherAssist.class,
                                       otherAssist.race, otherAssist.gender, otherAssist.guildName, otherAssist.rank)

                    table.insert(killerInfo.assists, {
                        name = otherAssist.name,
                        level = assistLevel,
                        class = otherAssist.class
                    })
                end

                -- Register the death
                PSC_RegisterPlayerDeath(killerInfo)

                -- Track for summary report
                local assistEntryMembers = {
                    enemyName .. " (Level " .. currentEnemyLevel .. " " .. enemyClass .. ")"
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
                    mainKiller = mainKiller.name,
                    groupMembers = assistEntryMembers,
                    playerLevel = currentPlayerLevel
                })
            end

            -- Restore time function immediately after each encounter
            time = savedTime
        end

        -- Generate a summary report
        PSC_Print("\n== " .. enemyName .. "'s PvP History with You ==")
        -- Fix: Calculate final level without using enemyLevelStep
        local finalEnemyLevel = enemyLevels[#enemyLevels]
        PSC_Print("Currently Level " .. finalEnemyLevel .. " " .. enemyRace .. " " .. enemyClass .. " <" .. enemyGuild .. ">")
        PSC_Print("First encountered at level " .. enemyStartLevel .. " when you were level " .. playerStartLevel)

        -- Format your kills against Roleplayer
        PSC_Print("\nTimes You Killed " .. enemyName .. ":")
        for i, kill in ipairs(killHistory) do
            local dateStr = date("%m/%d/%y %H:%M", kill.timestamp)
            PSC_Print(" - " .. dateStr .. " - Level " .. kill.level .. " in " .. kill.zone ..
                      " (You were level " .. kill.playerLevel .. ")")
        end

        -- Format times Roleplayer killed you
        PSC_Print("\nTimes " .. enemyName .. " Killed You:")
        for i, death in ipairs(deathHistory) do
            local dateStr = date("%m/%d/%y %H:%M", death.timestamp)
            PSC_Print(" - " .. dateStr .. " - Level " .. death.killerLevel .. " in " .. death.zone ..
                      " (You were level " .. death.playerLevel .. ")")
        end

        -- Format assists
        PSC_Print("\nGroup Activity:")
        for i, assist in ipairs(assistHistory) do
            local dateStr = date("%m/%d/%y %H:%M", assist.timestamp)
            PSC_Print(" - " .. dateStr .. " - " .. enemyName .. " assisted " .. assist.mainKiller ..
                      " in killing you in " .. assist.zone .. " (You were level " .. assist.playerLevel .. ")")
            PSC_Print("   Group: " .. assist.mainKiller .. ", " .. table.concat(assist.groupMembers, ", "))
        end

        -- Add the character to a special list so we can find them later
        if not PSC_DB.RolePlayers then
            PSC_DB.RolePlayers = {}
        end
        table.insert(PSC_DB.RolePlayers, {
            name = enemyName,
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
        PSC_Print("Error creating roleplayer: " .. (errorMsg or "Unknown error"))
    else
        PSC_Print("\nCreated roleplayer character with complete leveling history!")
        PSC_Print("You can find this character in your main kill and death statistics.")
    end
end
