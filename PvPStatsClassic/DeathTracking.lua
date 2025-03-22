PSC_RecentDamageFromPlayers = {}
local PLAYER_DAMAGE_WINDOW = 30.0

function PSC_GetKillerInfoOnDeath()
    local now = GetTime()
    local killers = {}
    local mainKiller = nil
    local highestDamage = 0

    for sourceGUID, info in pairs(PSC_RecentDamageFromPlayers) do
        if (now - info.timestamp) <= PLAYER_DAMAGE_WINDOW then
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
            lastDeath = "",
            zone = "",
            deathLocations = {},
            assistKills = 0,
            soloKills = 0
        }
    end

    local deathData = lossData.Deaths[killerName]
    deathData.deaths = deathData.deaths + 1
    deathData.lastDeath = date("%Y-%m-%d %H:%M:%S")
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
                local assistLevel = -1
                if PSC_DB.PlayerInfoCache[assist.name] then
                    assistLevel = PSC_DB.PlayerInfoCache[assist.name].level
                end

                table.insert(assistsWithLevels, {
                    name = assist.name,
                    level = assistLevel
                })
            end
        end

        table.insert(deathData.deathLocations, {
            x = x,
            y = y,
            zone = deathData.zone,
            timestamp = deathData.lastDeath,
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

    local ownerGUID = GetPetOwnerGUID(petGUID)
    if not ownerGUID then
        -- If we can't find the owner, just track the pet damage directly
        TrackIncomingPlayerDamage(petGUID, petName, amount)
        return
    end

    local ownerName = GetNameFromGUID(ownerGUID) or "Unknown Owner"

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

function PSC_HandleReceivedPlayerDamage(combatEvent, sourceGUID, sourceName, param1, param4)
    local damageAmount = 0

    -- Handle damage events
    if combatEvent == "SWING_DAMAGE" then
        damageAmount = param1 or 0
    elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "RANGE_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent:find("SPELL_") then
        -- Count debuffs and other spell effects as minimal damage for assist credit
        damageAmount = 1
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
        local dateStr = death.lastDeath and death.lastDeath:match("(%d+%-%d+%-%d+)") or "Unknown"
        PSC_Print(i .. ". " .. death.name .. " - " .. death.total ..
                 " deaths (Solo: " .. death.solo ..
                 ", Group: " .. death.assists ..
                 ") - Last: " .. dateStr ..
                 " in " .. death.zone)
    end
end
