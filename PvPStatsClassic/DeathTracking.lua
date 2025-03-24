PSC_RecentDamageFromPlayers = {}
local PLAYER_DAMAGE_WINDOW = 30.0
-- Add pet owner tracking dictionary
PSC_PetOwnerCache = {}
-- Track unattributed pet damage until we discover its owner
PSC_UnattributedPetDamage = {}

-- This function extracts pet owner information from tooltip for any unit
function PSC_UpdatePetOwnerFromUnit(unitID)
    if not unitID or not UnitExists(unitID) then return end

    -- Skip if this isn't a pet (skip players and non-creatures)
    if UnitIsPlayer(unitID) then return end

    if UnitIsFriend("player", unitID) then
        return
    end

    local petName = UnitName(unitID)
    if not petName then return end

    -- Skip if we already know this pet's owner
    if PSC_PetOwnerCache[petName] then
        return PSC_PetOwnerCache[petName]
    end

    -- Create a hidden tooltip to scan pet information
    local scanTooltip = CreateFrame("GameTooltip", "PSCScanTooltip", nil, "GameTooltipTemplate")
    scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

    -- Set the tooltip to examine the specified unit
    scanTooltip:SetUnit(unitID)

    -- Scan tooltip lines for pet owner formats
    for i = 1, scanTooltip:NumLines() do
        local line = _G["PSCScanTooltipTextLeft" .. i]:GetText()
        if line then
            -- Check for regular pets: "<Owner name>'s Pet"
            local owner = line:match("(.+)'s [Pp]et")

            -- Check for warlock minions: "<Owner name>'s Minion"
            if not owner then
                owner = line:match("(.+)'s [Mm]inion")
            end

            if owner then
                if PSC_Debug then
                    print("Pet " .. petName .. " -> Owner: " .. owner)
                end

                PSC_PetOwnerCache[petName] = owner

                -- Check if we have unattributed damage from this pet
                if PSC_UnattributedPetDamage[petName] then
                    local petInfo = PSC_UnattributedPetDamage[petName]

                    -- Create a name-based key for the owner
                    local ownerName = owner

                    -- Get or create owner record
                    local existingRecord = PSC_RecentDamageFromPlayers[ownerName] or {
                        name = owner,
                        class = "Unknown",
                        totalDamage = 0,
                        timestamp = 0
                    }

                    -- Update with pet damage
                    existingRecord.totalDamage = existingRecord.totalDamage + petInfo.totalDamage
                    existingRecord.timestamp = GetTime()

                    -- Store updated record
                    PSC_RecentDamageFromPlayers[ownerName] = existingRecord

                    if PSC_Debug then
                        print("Retroactively attributed " .. petInfo.totalDamage ..
                              " damage from " .. petName .. " to owner " .. owner)
                    end
                    -- Clear the unattributed damage
                    PSC_UnattributedPetDamage[petName] = nil
                end

                return owner
            end
        end
    end

    return nil
end

function PSC_GetKillerInfoOnDeath()
    local now = GetTime()
    local killers = {}
    local mainKiller = nil
    local highestDamage = 0

    for sourceID, info in pairs(PSC_RecentDamageFromPlayers) do
        -- Make sure the damage is recent enough
        if (now - info.timestamp) <= PLAYER_DAMAGE_WINDOW then
            -- Skip players in our party/raid as they can't be enemies
            if not UnitInParty(info.name) and not UnitInRaid(info.name) then
                if info.totalDamage > highestDamage then
                    highestDamage = info.totalDamage
                    mainKiller = {
                        guid = sourceID,  -- This could be either a GUID or player name now
                        name = info.name,
                        damage = info.totalDamage
                    }
                end

                table.insert(killers, {
                    guid = sourceID,  -- This could be either a GUID or player name now
                    name = info.name,
                    damage = info.totalDamage
                })
            end
        end
    end

    -- Return early if no killers found
    if not mainKiller then
        if PSC_Debug then
            print("No killers found!")
        end
        return nil
    end

    -- Process assists, checking for duplicates
    local assists = {}
    local addedPlayers = {}

    for _, killer in ipairs(killers) do
        -- Skip if this is the main killer
        if killer.name ~= mainKiller.name then
            -- We're now using name-based tracking, so check by name
            if not addedPlayers[killer.name] then
                table.insert(assists, {
                    name = killer.name
                })
                addedPlayers[killer.name] = true

                if PSC_Debug then
                    print("Added assist: " .. killer.name .. " with damage: " .. killer.damage)
                end
            end
        end
    end

    if PSC_Debug then
        print("Main Killer: " .. mainKiller.name .. " with damage: " .. mainKiller.damage)
        local assistNames = {}
        for _, assist in ipairs(assists) do
            table.insert(assistNames, assist.name)
        end
        if #assistNames > 0 then
            print("Assists: " .. table.concat(assistNames, ", "))
        else
            print("No assists")
        end
    end

    return {
        killer = mainKiller,
        assists = assists
    }
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

    local killerLevel = -1
    if PSC_DB.PlayerInfoCache[killerName] then
        killerLevel = PSC_DB.PlayerInfoCache[killerName].level
    end

    if not lossData.Deaths[killerName] then
        lossData.Deaths[killerName] = {
            deaths = 0,
            lastDeath = 0,
            zone = "",
            deathLocations = {},
            assistKills = 0,
            soloKills = 0
        }
    end

    local deathData = lossData.Deaths[killerName]
    deathData.deaths = deathData.deaths + 1
    deathData.lastDeath = time()
    deathData.zone = GetRealZoneText() or GetSubZoneText() or "Unknown"

    deathData.killerLevel = killerLevel

    if #killerInfo.assists > 0 then
        deathData.assistKills = deathData.assistKills + 1
    else
        deathData.soloKills = deathData.soloKills + 1
    end

    local x, y = PSC_GetPlayerCoordinates()

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
        timestamp = time(),
        deathNumber = deathData.deaths,
        killerLevel = killerLevel,
        assisters = assistsWithLevels
    })

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

    -- Always use player name as the key for consistency
    local playerKey = sourceName

    -- Get or create the damage record
    local existingRecord = PSC_RecentDamageFromPlayers[playerKey] or {
        name = sourceName,
        class = select(2, GetPlayerInfoByGUID(sourceGUID)) or "Unknown",
        totalDamage = 0,
        timestamp = 0
    }

    -- Update with new damage info
    existingRecord.totalDamage = existingRecord.totalDamage + amount
    existingRecord.timestamp = GetTime()

    -- Store updated record using player name as key
    PSC_RecentDamageFromPlayers[playerKey] = existingRecord

    if PSC_Debug then
        -- print("Incoming damage from " .. sourceName .. ": " .. amount)
    end
end

-- Fix for the TrackIncomingPetDamage function
function TrackIncomingPetDamage(petGUID, petName, amount)
    if not petGUID or not petName then return end

    -- First check our cache for the pet owner
    local ownerName = PSC_PetOwnerCache[petName]

    -- If we couldn't find the owner in our cache
    if not ownerName then
        -- Store the damage with the pet temporarily
        PSC_UnattributedPetDamage[petName] = PSC_UnattributedPetDamage[petName] or {
            totalDamage = 0,
            timestamp = GetTime()
        }

        -- Update unattributed damage
        PSC_UnattributedPetDamage[petName].totalDamage = PSC_UnattributedPetDamage[petName].totalDamage + amount
        PSC_UnattributedPetDamage[petName].timestamp = GetTime()

        if PSC_Debug then
            print("Storing unattributed pet damage from " .. petName .. ": " .. amount)
        end
        return
    end

    -- If we know the owner, attribute damage directly to them
    -- Use the owner's name directly as the key for consistency with TrackIncomingPlayerDamage

    -- Get or create owner record
    local existingRecord = PSC_RecentDamageFromPlayers[ownerName] or {
        name = ownerName,
        class = "Unknown", -- We may not be able to get the class reliably
        totalDamage = 0,
        timestamp = 0
    }

    -- Update with new damage info
    existingRecord.totalDamage = existingRecord.totalDamage + amount
    existingRecord.timestamp = GetTime()

    -- Store updated record
    PSC_RecentDamageFromPlayers[ownerName] = existingRecord

    if PSC_Debug then
        print("Incoming damage from " .. ownerName .. "'s pet (" .. petName .. "): " .. amount)
    end
end

function PSC_HandleReceivedPlayerDamage(combatEvent, sourceGUID, sourceName, spellId, spellName, param1, param4)
    local damageAmount = 0

    if not sourceName or UnitInParty(sourceName) or UnitInRaid(sourceName) then
        return
    end

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
            damageAmount = 1
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

    if damageAmount > 0 then
        TrackIncomingPetDamage(sourceGUID, sourceName, damageAmount)
    end
end

function PSC_CleanupUnattributedPetDamage()
    local now = GetTime()
    local cutoff = now - PLAYER_DAMAGE_WINDOW

    for petName, info in pairs(PSC_UnattributedPetDamage) do
        if info.timestamp < cutoff then
            PSC_UnattributedPetDamage[petName] = nil
        end
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

    PSC_CleanupUnattributedPetDamage()
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
