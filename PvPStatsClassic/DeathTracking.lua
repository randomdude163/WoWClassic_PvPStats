PSC_RecentDamageFromPlayers = {}
local PLAYER_DAMAGE_WINDOW = 30.0

function PSC_GetKillerInfoOnDeath()
    local now = GetTime()
    local killers = {}
    local mainKiller = nil
    local highestDamage = 0

    for sourceGUID, info in pairs(PSC_RecentDamageFromPlayers) do
        if (now - info.timestamp) <= PLAYER_DAMAGE_WINDOW then
            -- Skip players in our party/raid as they can't be enemies
            if not UnitInParty(info.name) and not UnitInRaid(info.name) then
                if info.totalDamage > highestDamage then
                    highestDamage = info.totalDamage
                    mainKiller = {
                        guid = sourceGUID,
                        name = info.name,
                        damage = info.totalDamage,
                        isPet = IsPetGUID(sourceGUID)
                    }
                end

                table.insert(killers, {
                    guid = sourceGUID,
                    name = info.name,
                    damage = info.totalDamage,
                    isPet = IsPetGUID(sourceGUID)
                })
            end
        end
    end

    if mainKiller then
        if mainKiller.isPet then
            local ownerGUID = GetPetOwnerGUID(mainKiller.guid)
            local ownerName = GetNameFromGUID(ownerGUID)

            if ownerName then
                mainKiller.name = ownerName
                mainKiller.guid = ownerGUID
                mainKiller.isPet = false
            end
        end

        local assists = {}
        for _, killer in ipairs(killers) do
            if killer.guid ~= mainKiller.guid and not (killer.isPet and GetPetOwnerGUID(killer.guid) == mainKiller.guid) then
                if killer.isPet then
                    local ownerGUID = GetPetOwnerGUID(killer.guid)
                    local ownerName = GetNameFromGUID(ownerGUID)
                    if ownerName and ownerGUID ~= mainKiller.guid then
                        table.insert(assists, {
                            name = ownerName
                        })
                    end
                else
                    table.insert(assists, {
                        name = killer.name
                    })
                end
            end
        end

        if PSC_Debug then
            print("Main Killer: " .. mainKiller.name)
            local assistNames = {}
            for _, assist in ipairs(assists) do
                table.insert(assistNames, assist.name)
            end
            print("Assists: " .. table.concat(assistNames, ", "))
        end
        return {
            killer = mainKiller,
            assists = assists
        }
    end

    return nil
end

function PSC_RegisterPlayerDeath(killerInfo)
    if PSC_CurrentlyInBattleground and not PSC_DB.CountDeathsInBattlegrounds then
        if PSC_Debug then print("BG Mode: Death tracking disabled in battlegrounds") end
        return
    end

    local characterKey = PSC_GetCharacterKey()

    local lossData = PSC_DB.PvPLossCounts[characterKey]
    local killerName = killerInfo.killer.name
    if not killerName then return end

    -- Get killer level from player info cache
    local killerLevel = -1
    if PSC_DB.PlayerInfoCache[killerName] then
        killerLevel = PSC_DB.PlayerInfoCache[killerName].level
    end

    -- Check if we have info for this killer
    if not lossData.Deaths[killerName] then
        lossData.Deaths[killerName] = {
            deaths = 0,
            lastDeath = 0, -- Store as number (time())
            zone = "",
            deathLocations = {},
            assistKills = 0,
            soloKills = 0
        }
    end

    local deathData = lossData.Deaths[killerName]
    deathData.deaths = deathData.deaths + 1
    deathData.lastDeath = time() -- Use time() instead of formatted string
    deathData.zone = GetRealZoneText() or GetSubZoneText() or "Unknown"

    -- Store the killer's level at time of death
    deathData.killerLevel = killerLevel

    -- Track whether it was a solo kill or assist
    if #killerInfo.assists > 0 then
        deathData.assistKills = deathData.assistKills + 1
    else
        deathData.soloKills = deathData.soloKills + 1
    end

    -- Save location data
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = nil
    if mapID then
        position = C_Map.GetPlayerMapPosition(mapID, "player")
    end

    if mapID and position and position.x and position.y then
        local x = position.x * 100
        local y = position.y * 100

        -- Prepare assist information with levels
        local assistsWithLevels = nil
        if #killerInfo.assists > 0 then
            assistsWithLevels = {}
            for _, assist in ipairs(killerInfo.assists) do
                table.insert(assistsWithLevels, {
                    name = assist.name
                })
            end
        end

        table.insert(deathData.deathLocations, {
            x = x,
            y = y,
            zone = deathData.zone,
            timestamp = time(), -- Use time() instead of formatted string
            deathNumber = deathData.deaths,
            killerLevel = killerLevel,
            assisters = assistsWithLevels
        })
    end

    if PSC_Debug then
        local assistText = ""
        if #killerInfo.assists > 0 then
            assistText = " with help from " .. #killerInfo.assists .. " players"
        else
            assistText = " (solo kill)"
        end
        print("Death recorded: killed by " .. killerName .. " (Level: " .. killerLevel .. ")" .. assistText)
    end
end

function TrackIncomingPlayerDamage(sourceGUID, sourceName, amount)
    if not sourceGUID or not sourceName then return end

    -- Get or create the damage record
    local existingRecord = PSC_RecentDamageFromPlayers[sourceGUID] or {
        name = sourceName,
        class = select(2, GetPlayerInfoByGUID(sourceGUID)) or "Unknown",
        totalDamage = 0,
        timestamp = 0
    }

    -- Update with new damage info
    existingRecord.totalDamage = existingRecord.totalDamage + amount
    existingRecord.timestamp = GetTime()

    -- Store updated record
    PSC_RecentDamageFromPlayers[sourceGUID] = existingRecord

    -- if PSC_Debug then
    --     print("Incoming damage from " .. sourceName .. ": " .. amount)
    -- end
end

function TrackIncomingPetDamage(petGUID, petName, amount)
    if not petGUID or not petName then return end

    -- This doesn't work properly, yet.
    local ownerGUID = GetPetOwnerGUID(petGUID)

    print("Pet owner GUID: " .. ownerGUID)
    if not ownerGUID then
        -- If we can't find the owner, just track the pet damage directly
        TrackIncomingPlayerDamage(petGUID, petName, amount)
        return
    end

    local ownerName = GetNameFromGUID(ownerGUID) or "Unknown Owner"
    print("Owner Name: " .. ownerName)
    -- Create a merged record with the owner's information
    local existingRecord = PSC_RecentDamageFromPlayers[ownerGUID] or {
        name = ownerName,
        class = select(2, GetPlayerInfoByGUID(ownerGUID)) or "Unknown",
        totalDamage = 0,
        timestamp = 0
    }

    -- Update with new damage info
    existingRecord.totalDamage = existingRecord.totalDamage + amount
    existingRecord.timestamp = GetTime()

    -- Store updated record
    PSC_RecentDamageFromPlayers[ownerGUID] = existingRecord

    if PSC_Debug then
        print("Incoming damage from " .. ownerName .. "'s pet (" .. petName .. "): " .. amount)
    end
end

function PSC_HandleReceivedPlayerDamage(combatEvent, sourceGUID, sourceName, spellId, spellName, spellSchool, param1, param4)
    local damageAmount = 0

    -- Only track if sourceName exists and isn't in our party/raid
    if not sourceName or UnitInParty(sourceName) or UnitInRaid(sourceName) then
        return
    end

    -- Handle damage events - these already count properly
    if combatEvent == "SWING_DAMAGE" then
        damageAmount = param1 or 0
    elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "RANGE_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_CAST_SUCCESS" then
        -- Only track spells that:
        -- 1. Are PvP relevant
        -- 2. Don't already deal damage (which would be caught by damage events)
        -- 3. Are cast by enemies against you

        -- PvP relevant spell IDs that don't cause damage
        local pvpRelevantSpellIds = {
            -- Pure CC without damage components
            118, 12826, 12825, 12824, 12825, 12826, -- Polymorph and ranks
            6770, 2070, 11297,               -- Sap and ranks
            2094,                            -- Blind
            3355, 14308, 14309,              -- Freezing Trap and ranks
            19503,                           -- Scatter Shot
            1776, 1777, 8629, 11285, 11286,  -- Gouge and ranks
            20549,                           -- War Stomp
            5782, 6213, 6215,                -- Fear and ranks
            8122, 8124, 10888, 10890,        -- Psychic Scream and ranks
            5246,                            -- Intimidating Shout

            -- Disarms and movement impairing effects without damage
            676,                             -- Disarm
            3409, 11201,                     -- Crippling Poison and ranks
            18223,                           -- Curse of Exhaustion
            12494,                           -- Frostbite

            -- Pure dispels and utility
            370, 8012, 8017,                 -- Purge and ranks
            19801,                           -- Tranquilizing Shot

            -- Silences without damage components
            15487,                           -- Silence

            -- Counterspells without damage
            2139,                            -- Counterspell
            19244, 19647,                    -- Spell Lock and rank

            -- Debuffs without direct damage
            1714, 11719,                     -- Curse of Tongues and rank
            702, 1108, 6205, 7646, 11707, 11708,  -- Curse of Weakness and ranks
            704, 7658, 7659, 11717,          -- Curse of Recklessness and ranks
        }

        -- Check if this is a PvP-relevant spell by ID
        local isRelevantSpell = false
        if spellId and spellId > 0 then
            for _, relevantSpellId in ipairs(pvpRelevantSpellIds) do
                if spellId == relevantSpellId then
                    isRelevantSpell = true
                    if PSC_Debug then
                        print("PvP relevant spell detected from " .. sourceName .. ": " .. spellName .. " (ID: " .. spellId .. ")")
                    end
                    break
                end
            end
        end

        if isRelevantSpell then
            damageAmount = 1  -- Just award minimal "contribution" for tracking purposes
        end
    end

    if damageAmount > 0 then
        TrackIncomingPlayerDamage(sourceGUID, sourceName, damageAmount)
    end
end

function PSC_HandleReceivedPlayerDamageByEnemyPets(combatEvent, sourceGUID, sourceName, param1, param4)
    local damageAmount = 0

    if combatEvent == "SWING_DAMAGE" then
        damageAmount = param1 or 0
    elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "RANGE_DAMAGE" then
        damageAmount = param4 or 0
    end

    print("Damage amount: " .. damageAmount)

    if damageAmount > 0 then
        TrackIncomingPetDamage(sourceGUID, sourceName, damageAmount)
    end
end

function PSC_CleanupRecentDamageFromPlayers()
    local now = GetTime()
    local cutoff = now - PLAYER_DAMAGE_WINDOW

    for guid, info in pairs(PSC_RecentDamageFromPlayers) do
        if info.timestamp < cutoff then
            PSC_RecentDamageFromPlayers[guid] = nil
        end
    end
end

function PSC_ShowDeathStats()
    local characterKey = PSC_GetCharacterKey()
    if not PSC_DB.PvPLossCounts or not PSC_DB.PvPLossCounts[characterKey] then
        PSC_Print("No death data available")
        return
    end

    local lossData = PSC_DB.PvPLossCounts[characterKey]
    PSC_Print("Death Stats for " .. PSC_CharacterName)
    PSC_Print("\nDeaths by player:")

    local deaths = {}
    for killerName, data in pairs(lossData.Deaths) do
        table.insert(deaths, {
            name = killerName,
            total = data.deaths,
            solo = data.soloKills or 0,
            assists = data.assistKills or 0,
            lastDeath = data.lastDeath,
            zone = data.zone
        })
    end

    -- Sort by total deaths
    table.sort(deaths, function(a, b) return a.total > b.total end)

    for i, death in ipairs(deaths) do
        local dateStr = PSC_FormatTimestamp(death.lastDeath)
        PSC_Print(i .. ". " .. death.name .. " - " .. death.total ..
                 " deaths (Solo: " .. death.solo ..
                 ", Group: " .. death.assists ..
                 ") - Last: " .. dateStr ..
                 " in " .. death.zone)
    end
end
