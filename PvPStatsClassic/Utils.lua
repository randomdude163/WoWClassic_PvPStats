function IsPetGUID(guid)
    if not guid then return false end

    -- Classic WoW GUID format: Pet-0-xxxx-xxxx-xxxx-xxxx
    return guid:match("^Pet%-") ~= nil
end

function GetPetOwnerGUID(petGUID)
    if not petGUID or not IsPetGUID(petGUID) then return nil end

    if UnitExists("pet") and UnitGUID("pet") == petGUID then
        return PSC_PlayerGUID
    end

    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, numMembers do
        local unitID
        if prefix == "party" then
            unitID = (i == GetNumGroupMembers()) and "player" or (prefix..i)
        else
            unitID = prefix..i
        end

        local petID = unitID.."pet"

        if UnitExists(petID) and UnitGUID(petID) == petGUID then
            return UnitGUID(unitID)
        end
    end

    return nil
end

function GetNameFromGUID(guid)
    if not guid then return nil end

    -- Try to find the name from the GUID
    local name = select(6, GetPlayerInfoByGUID(guid))
    if name then return name end

    -- If that fails, check if it's the player
    if guid == PSC_PlayerGUID then
        return PSC_CharacterName
    end

    -- Check party/raid members
    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, numMembers do
        local unitID
        if prefix == "party" then
            unitID = (i == GetNumGroupMembers()) and "player" or (prefix..i)
        else
            unitID = prefix..i
        end

        if UnitGUID(unitID) == guid then
            return UnitName(unitID)
        end
    end

    return nil
end

function PSC_GetRankName(rank)
    if not rank or rank <= 0 then
        return nil
    end

    local rankNames = {
        Alliance = {
            [1] = "Private",
            [2] = "Corporal",
            [3] = "Sergeant",
            [4] = "Master Sergeant",
            [5] = "Sergeant Major",
            [6] = "Knight",
            [7] = "Knight-Lieutenant",
            [8] = "Knight-Captain",
            [9] = "Knight-Champion",
            [10] = "Lieutenant Commander",
            [11] = "Commander",
            [12] = "Marshal",
            [13] = "Field Marshal",
            [14] = "Grand Marshal"
        },
        Horde = {
            [1] = "Scout",
            [2] = "Grunt",
            [3] = "Sergeant",
            [4] = "Senior Sergeant",
            [5] = "First Sergeant",
            [6] = "Stone Guard",
            [7] = "Blood Guard",
            [8] = "Legionnaire",
            [9] = "Centurion",
            [10] = "Champion",
            [11] = "Lieutenant General",
            [12] = "General",
            [13] = "Warlord",
            [14] = "High Warlord"
        }
    }

    local player_faction = UnitFactionGroup("player")
    local factionTable = nil
    if player_faction == "Horde" then
        factionTable = rankNames["Alliance"]
    else
        factionTable = rankNames["Horde"]
    end
    return factionTable[rank] or ("Rank " .. rank)
end

function PSC_Print(message)
    local PSC_CHAT_MESSAGE_R = 1.0
    local PSC_CHAT_MESSAGE_G = 1.0
    local PSC_CHAT_MESSAGE_B = 0.74
    DEFAULT_CHAT_FRAME:AddMessage(message, PSC_CHAT_MESSAGE_R, PSC_CHAT_MESSAGE_G, PSC_CHAT_MESSAGE_B)
end

function PSC_GetCharacterKey()
    return PSC_CharacterName .. "-" .. PSC_RealmName
end

function GetMultiKillText(count)
    if count < 2 then return "" end

    local killTexts = {
        "DOUBLE KILL!",
        "TRIPLE KILL!",
        "QUADRA KILL!",
        "PENTA KILL!"
    }

    if count <= 5 then
        return killTexts[count - 1]
    end

    return "Multi-kill of " .. count
end

function PSC_GetPlayerCoordinates()
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(mapID, "player")
    local x = position.x * 100
    local y = position.y * 100
    return x, y
end

function PSC_FormatLastKillTimespan(lastKillTimestamp)
    if not lastKillTimestamp then
        return nil
    end

    local currentTime = time()
    local timeDiff = currentTime - lastKillTimestamp

    if timeDiff < 60 then
        return format("%ds", timeDiff)
    elseif timeDiff < 3600 then
        return format("%dm", math.floor(timeDiff/60))
    elseif timeDiff < 86400 then
        return format("%dh", math.floor(timeDiff/3600))
    else
        return format("%dd", math.floor(timeDiff/86400))
    end
end

function PSC_TimestampToHour(timestamp, timezoneOffsetHours)
    if not timestamp then
        return nil
    end

    -- Default timezone offset to 0 if not provided
    timezoneOffsetHours = timezoneOffsetHours or 0

    -- Apply timezone offset
    local adjustedTimestamp = timestamp + (timezoneOffsetHours * 3600)

    -- Use WoW's date function (same as KillsListFrame uses)
    local dateInfo = date("*t", adjustedTimestamp)
    if not dateInfo then
        return nil
    end

    return dateInfo.hour
end

function PSC_IsTimestampInHourRange(timestamp, startHour, endHour, timezoneOffsetHours)
    local hour = PSC_TimestampToHour(timestamp, timezoneOffsetHours)
    if not hour then
        return false
    end

    -- Handle ranges that cross midnight (e.g., 22-6 means 22:00-05:59)
    if startHour > endHour then
        return hour >= startHour or hour < endHour
    else
        return hour >= startHour and hour < endHour
    end
end

function PSC_CountKillsInTimeRange(startHour, endHour, timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and PSC_IsTimestampInHourRange(killLocation.timestamp, startHour, endHour, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function PSC_TestDataAccess()
    local characterKey = PSC_GetCharacterKey()
    if not PSC_DB or not PSC_DB.PlayerKillCounts or not PSC_DB.PlayerKillCounts.Characters then
        return
    end
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]
    if not characterData or not characterData.Kills then
        return
    end
    local totalKills = 0
    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            totalKills = totalKills + #playerData.killLocations
        end
    end

    print("SUCCESS: Found", totalKills, "total kills")
    print("=== End Test ===")
end

function PSC_IsTimestampOnWeekday(timestamp, weekdays, timezoneOffsetHours)
    if not timestamp or not weekdays then
        return false
    end

    timezoneOffsetHours = timezoneOffsetHours or 0
    local adjustedTimestamp = timestamp + (timezoneOffsetHours * 3600)
    local dateInfo = date("*t", adjustedTimestamp)
    if not dateInfo then
        return false
    end

    for _, day in ipairs(weekdays) do
        if dateInfo.wday == day then
            return true
        end
    end

    return false
end

function PSC_CountKillsOnWeekdays(weekdays, timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and PSC_IsTimestampOnWeekday(killLocation.timestamp, weekdays, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function PSC_CountKillsInTimeRangeOnWeekdays(startHour, endHour, weekdays, timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and
                   PSC_IsTimestampInHourRange(killLocation.timestamp, startHour, endHour, timezoneOffsetHours) and
                   PSC_IsTimestampOnWeekday(killLocation.timestamp, weekdays, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function PSC_IsTimestampOnDate(timestamp, day, month, timezoneOffsetHours)
    if not timestamp or not day or not month then
        return false
    end

    timezoneOffsetHours = timezoneOffsetHours or 0
    local adjustedTimestamp = timestamp + (timezoneOffsetHours * 3600)
    local dateInfo = date("*t", adjustedTimestamp)
    if not dateInfo then
        return false
    end

    return dateInfo.day == day and dateInfo.month == month
end

function PSC_CountKillsOnDate(day, month, timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and PSC_IsTimestampOnDate(killLocation.timestamp, day, month, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function PSC_IsTimestampOnFridayThe13th(timestamp, timezoneOffsetHours)
    if not timestamp then
        return false
    end

    timezoneOffsetHours = timezoneOffsetHours or 0
    local adjustedTimestamp = timestamp + (timezoneOffsetHours * 3600)
    local dateInfo = date("*t", adjustedTimestamp)
    if not dateInfo then
        return false
    end

    return dateInfo.day == 13 and dateInfo.wday == 6
end

function PSC_CountKillsOnFridayThe13th(timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and PSC_IsTimestampOnFridayThe13th(killLocation.timestamp, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

function PSC_IsTimestampInMonth(timestamp, month, timezoneOffsetHours)
    if not timestamp or not month then
        return false
    end

    timezoneOffsetHours = timezoneOffsetHours or 0
    local adjustedTimestamp = timestamp + (timezoneOffsetHours * 3600)
    local dateInfo = date("*t", adjustedTimestamp)
    if not dateInfo then
        return false
    end

    return dateInfo.month == month
end

function PSC_CountKillsInMonth(month, timezoneOffsetHours)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp and PSC_IsTimestampInMonth(killLocation.timestamp, month, timezoneOffsetHours) then
                    count = count + 1
                end
            end
        end
    end

    return count
end
