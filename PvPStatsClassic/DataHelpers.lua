-- Common data helper functions for PvPStatsClassic
-- These functions centralize common data operations used throughout the addon

-- Get the list of characters to process based on account-wide setting
function PSC_GetCharactersToProcessForStatistics()
    local charactersToProcess = {}

    if PSC_DB.ShowAccountWideStats then
        -- Process all characters
        for charKey, charData in pairs(PSC_DB.PlayerKillCounts.Characters) do
            charactersToProcess[charKey] = charData
        end
    else
        -- Process only the current character
        local characterKey = PSC_GetCharacterKey()
        if PSC_DB.PlayerKillCounts.Characters[characterKey] then
            charactersToProcess[characterKey] = PSC_DB.PlayerKillCounts.Characters[characterKey]
        end
    end

    return charactersToProcess
end

-- Get death data from all relevant characters
function PSC_GetDeathDataFromAllCharacters()
    local deathDataByPlayer = {}

    -- Get characters to process based on account-wide setting
    local charactersToProcess = {}
    if PSC_DB.ShowAccountWideStats then
        for charKey, _ in pairs(PSC_DB.PvPLossCounts) do
            charactersToProcess[charKey] = true
        end
    else
        local characterKey = PSC_GetCharacterKey()
        charactersToProcess[characterKey] = true
    end

    -- Collect death data from all relevant characters
    for charKey, _ in pairs(charactersToProcess) do
        local lossData = PSC_DB.PvPLossCounts[charKey]
        if lossData and lossData.Deaths then
            for killerName, deathData in pairs(lossData.Deaths) do
                if not deathDataByPlayer[killerName] then
                    deathDataByPlayer[killerName] = {
                        deaths = 0,
                        deathLocations = {}
                    }
                end

                -- Add death count
                deathDataByPlayer[killerName].deaths = deathDataByPlayer[killerName].deaths + (deathData.deaths or 0)

                -- Add death locations
                if deathData.deathLocations then
                    for _, location in ipairs(deathData.deathLocations) do
                        table.insert(deathDataByPlayer[killerName].deathLocations, location)
                    end
                end
            end
        end
    end

    return deathDataByPlayer
end

-- Find a player's most recent death location in deathData
function PSC_GetPlayerMostRecentDeathInfo(deathData)
    local zone = "Unknown"
    local lastKill = 0

    if deathData.deathLocations and #deathData.deathLocations > 0 then
        -- Sort death locations by timestamp descending (most recent first)
        table.sort(deathData.deathLocations, function(a, b)
            return (a.timestamp or 0) > (b.timestamp or 0)
        end)

        -- Get zone from most recent death location
        zone = deathData.deathLocations[1].zone or zone
        lastKill = deathData.deathLocations[1].timestamp or lastKill
    end

    return zone, lastKill
end

-- Count assists from a player
function PSC_CountPlayerAssists(playerName, deathDataByPlayer)
    local assistCount = 0
    local assistData = {
        assists = 0,
        lastAssist = 0,
        zone = "Unknown"
    }

    for _, deathData in pairs(deathDataByPlayer) do
        if deathData.deathLocations then
            for _, location in ipairs(deathData.deathLocations) do
                if location.assisters then
                    for _, assister in ipairs(location.assisters) do
                        if assister.name == playerName then
                            assistCount = assistCount + 1
                            assistData.assists = assistData.assists + 1

                            -- Update latest assist timestamp and zone if more recent
                            if (location.timestamp or 0) > assistData.lastAssist then
                                assistData.lastAssist = location.timestamp or 0
                                assistData.zone = location.zone or "Unknown"
                            end
                        end
                    end
                end
            end
        end
    end

    return assistCount, assistData
end

-- Function to sort player entries by a given column/field
function PSC_SortPlayerEntries(entries, sortBy, ascending)
    if sortBy then
        table.sort(entries, function(a, b)
            local aValue = a[sortBy]
            local bValue = b[sortBy]

            -- Special handling for level sorting - convert to numbers for proper comparison
            if sortBy == "levelDisplay" then
                local aLevel = tonumber(aValue) or -1
                local bLevel = tonumber(bValue) or -1

                if ascending then
                    return aLevel < bLevel
                else
                    return aLevel > bLevel
                end
            end

            -- Special case for numeric values vs nil
            if type(aValue) == "number" and type(bValue) == "number" then
                if ascending then
                    return aValue < bValue
                else
                    return aValue > bValue
                end
            end

            -- Handle string comparison
            if ascending then
                return tostring(aValue or "") < tostring(bValue or "")
            else
                return tostring(aValue or "") > tostring(bValue or "")
            end
        end)
    end

    return entries
end

-- Function to add or update a player entry in the entries table
function PSC_AddOrUpdatePlayerEntry(playerNameMap, entries, name, entry)
    if not playerNameMap[name] then
        playerNameMap[name] = entry
        table.insert(entries, entry)
    else
        local existingEntry = playerNameMap[name]
        existingEntry.kills = existingEntry.kills + entry.kills

        -- Keep the most recent kill timestamp and data
        if entry.lastKill > (existingEntry.lastKill or 0) then
            existingEntry.lastKill = entry.lastKill
            existingEntry.zone = entry.zone
            existingEntry.levelDisplay = entry.levelDisplay
            existingEntry.rank = entry.rank
        end

        -- Store details of all kills for the detail view
        if not existingEntry.killHistory then
            existingEntry.killHistory = {}
        end

        if not entry.includedInHistory then
            table.insert(existingEntry.killHistory, {
                level = entry.levelDisplay,
                zone = entry.zone,
                timestamp = entry.lastKill,
                rank = entry.rank,
                kills = entry.kills
            })
            entry.includedInHistory = true
        end
    end
end

-- Utility function to calculate grey level kills with detailed debugging
function PSC_CalculateGreyKills()
    local greyKills = 0
    local debugDetails = {}
    local currentCharacterKey = PSC_GetCharacterKey()
    local charactersToProcess = {}

    -- Print debug header if debug mode is on
    if PSC_Debug then
        print("----------------------------------------------")
        print("CALCULATING GREY KILLS - DETAILED BREAKDOWN")
        print("----------------------------------------------")
    end

    if PSC_DB.ShowAccountWideStats then
        charactersToProcess = PSC_DB.PlayerKillCounts.Characters
    else
        if PSC_DB.PlayerKillCounts.Characters[currentCharacterKey] then
            charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
        end
    end

    -- Grey level formula: For Classic WoW, targets are grey when (playerLevel - targetLevel) >= 10 OR targetLevel <= 9
    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            -- Debug output for character being processed
            if PSC_Debug then
                print("Processing character: " .. characterKey)
            end

            for nameWithLevel, killData in pairs(characterData.Kills) do
                local nameOnly = nameWithLevel:match("([^:]+)")
                local level = nameWithLevel:match(":(%S+)")
                local targetLevel = tonumber(level or "0") or 0
                local totalKills = killData.kills or 0

                if PSC_Debug then
                    print("  Target: " .. nameOnly .. " (Level " .. targetLevel .. ") - Total kills: " .. totalKills)
                end

                -- Skip targets without level info or with 0 kills
                if targetLevel > 0 and totalKills > 0 then
                    local isGreyKill = false
                    local maxPlayerLevel = 0
                    local greyKillsForTarget = 0

                    -- Try to determine player level from killLocations
                    if killData.killLocations and #killData.killLocations > 0 then
                        for _, location in ipairs(killData.killLocations) do
                            local playerLevel = location.playerLevel or 0
                            if playerLevel > maxPlayerLevel then
                                maxPlayerLevel = playerLevel
                            end

                            -- Check if this specific kill was a grey kill
                            if playerLevel > 0 and targetLevel > 0 then
                                local levelDiff = playerLevel - targetLevel
                                local isThisKillGrey = (levelDiff >= 10) or (targetLevel <= 9)

                                if isThisKillGrey then
                                    greyKillsForTarget = greyKillsForTarget + 1
                                    isGreyKill = true
                                end

                                if PSC_Debug then
                                    print("    Kill at " .. (location.zone or "Unknown") .. ": Player level " ..
                                          playerLevel .. ", Level diff: " .. levelDiff ..
                                          (isThisKillGrey and " (GREY)" or " (not grey)"))
                                end
                            end
                        end
                    else
                        -- No location data, fall back to current player level
                        maxPlayerLevel = PSC_GetPlayerLevel()

                        local levelDiff = maxPlayerLevel - targetLevel
                        isGreyKill = (levelDiff >= 10) or (targetLevel <= 9)

                        if isGreyKill then
                            greyKillsForTarget = totalKills
                        end

                        if PSC_Debug then
                            print("    No location data. Using current player level: " .. maxPlayerLevel ..
                                 ", Level diff: " .. levelDiff ..
                                 (isGreyKill and " (GREY)" or " (not grey)"))
                        end
                    end

                    -- If any kill for this target was grey, count all kills as grey kills
                    if isGreyKill then
                        -- If we have specific grey kills counted, use that, otherwise use total kills
                        local killsToAdd = (greyKillsForTarget > 0) and greyKillsForTarget or totalKills
                        greyKills = greyKills + killsToAdd

                        -- Add to debug details
                        if PSC_Debug then
                            print("  => ADDING " .. killsToAdd .. " grey kills for " .. nameOnly)
                        end
                    end
                end
            end
        end
    end

    if PSC_Debug then
        print("----------------------------------------------")
        print("TOTAL GREY KILLS: " .. greyKills)
        print("----------------------------------------------")
    end

    return greyKills
end

-- Get the player's current level
function PSC_GetPlayerLevel()
    return UnitLevel("player") or 0
end
