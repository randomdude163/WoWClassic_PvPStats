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

    -- Use local time directly (date("*t") automatically handles timezone conversion)
    local dateInfo = date("*t", timestamp)
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

-- Weekday constants (matches Lua's date("*t").wday values)
-- IMPORTANT: Lua's date system uses 1-based indexing where:
--   Sunday = 1, Monday = 2, Tuesday = 3, Wednesday = 4,
--   Thursday = 5, Friday = 6, Saturday = 7
-- This is different from many programming languages that start with Monday = 0 or 1
local WEEKDAY = {
    SUNDAY = 1,
    MONDAY = 2,
    TUESDAY = 3,
    WEDNESDAY = 4,
    THURSDAY = 5,
    FRIDAY = 6,
    SATURDAY = 7
}

-- Helper function to get weekday name from number (for debugging)
local function GetWeekdayName(weekdayNumber)
    local names = {
        [WEEKDAY.SUNDAY] = "Sunday",
        [WEEKDAY.MONDAY] = "Monday",
        [WEEKDAY.TUESDAY] = "Tuesday",
        [WEEKDAY.WEDNESDAY] = "Wednesday",
        [WEEKDAY.THURSDAY] = "Thursday",
        [WEEKDAY.FRIDAY] = "Friday",
        [WEEKDAY.SATURDAY] = "Saturday"
    }
    return names[weekdayNumber] or "Unknown"
end

--[[
    TIME-BASED ACHIEVEMENTS SYSTEM DOCUMENTATION
    ============================================

    TIMEZONE HANDLING:
    - All time-based achievements automatically use the player's local system timezone
    - Kill timestamps are stored as UTC, but converted to local time for calculations
    - This ensures achievements work correctly regardless of server location or player timezone
    - Players in different timezones will see achievements based on their local time

    WEEKDAY SYSTEM EXPLANATION:
    - Lua's date("*t").wday returns weekday numbers where Sunday = 1
    - This is DIFFERENT from ISO standard (Monday = 1) and many programming languages
    - Use the WEEKDAY constants instead of magic numbers for clarity

    EXAMPLES OF ADDING NEW TIME-BASED ACHIEVEMENTS:

    1. Simple Time Range:
       Add to timeRanges: {6, 9, "early_morning"}
       In achievement: PSC_CountKillsByTimeRangeName("early_morning")

    2. Specific Weekday:
       Add to weekdayGroups: {"tuesday_only", {WEEKDAY.TUESDAY}}
       In achievement: PSC_CountKillsByWeekdayGroup("tuesday_only")

    3. Weekend Nights:
       Add to combinations: {22, 6, {WEEKDAY.SATURDAY, WEEKDAY.SUNDAY}, "weekend_nights"}
       In achievement: PSC_CountKillsByCombination("weekend_nights")

    4. Complex Condition:
       Add to specialConditions: {
           name = "summer_evenings",
           check = function(dateInfo)
               local isSummer = dateInfo.month >= 6 and dateInfo.month <= 8
               local isEvening = dateInfo.hour >= 18 and dateInfo.hour < 22
               return isSummer and isEvening
           end
       }
       In achievement: PSC_CountKillsBySpecialCondition("summer_evenings")
--]]

-- Configuration for time-based achievements - easy to extend!
local TimeBasedAchievementConfig = {
    -- Time ranges (startHour, endHour, optional_name)
    timeRanges = {
        {22, 6, "night_shift"},        -- Night shift: 10 PM - 6 AM
        {12, 14, "lunch_hour"},        -- Lunch hour: 12 PM - 2 PM
        {17, 21, "after_work"},        -- After work: 5 PM - 9 PM
        {9, 17, "work_hours"},         -- Work hours: 9 AM - 5 PM
        {0, 6, "midnight_to_dawn"},    -- Midnight to dawn: 12 AM - 6 AM
        {6, 12, "morning"},            -- Morning: 6 AM - 12 PM
        {18, 24, "evening"},           -- Evening: 6 PM - 12 AM
        {5, 8, "early_bird"},          -- Early bird: 5 AM - 8 AM
        -- Add more time ranges here as needed
    },

    -- Individual weekdays (weekday_number, name)
    weekdays = {
        {WEEKDAY.SUNDAY, "sunday"},
        {WEEKDAY.MONDAY, "monday"},
        {WEEKDAY.TUESDAY, "tuesday"},
        {WEEKDAY.WEDNESDAY, "wednesday"},
        {WEEKDAY.THURSDAY, "thursday"},
        {WEEKDAY.FRIDAY, "friday"},
        {WEEKDAY.SATURDAY, "saturday"},
    },

    -- Weekday groups (group_name, {weekday_numbers})
    weekdayGroups = {
        {"weekend", {WEEKDAY.SUNDAY, WEEKDAY.SATURDAY}},                                -- Weekend
        {"weekdays", {WEEKDAY.MONDAY, WEEKDAY.TUESDAY, WEEKDAY.WEDNESDAY, WEEKDAY.THURSDAY, WEEKDAY.FRIDAY}}, -- Monday-Friday
        {"weekends_extended", {WEEKDAY.FRIDAY, WEEKDAY.SATURDAY, WEEKDAY.SUNDAY}},      -- Friday night through Sunday
        -- Add more weekday groups here as needed
    },

    -- Months (month_number, name)
    months = {
        {1, "january"}, {2, "february"}, {3, "march"}, {4, "april"},
        {5, "may"}, {6, "june"}, {7, "july"}, {8, "august"},
        {9, "september"}, {10, "october"}, {11, "november"}, {12, "december"},
        -- Add seasonal groups if needed
        -- {[12,1,2], "winter"}, -- Would require different structure
    },

    -- Special dates (day, month, name)
    specialDates = {
        {25, 12, "christmas"},
        {24, 12, "christmas_eve"}, -- Christmas Eve
        {31, 12, "new_years_eve"},
        {1, 1, "new_years_day"},
        {14, 2, "valentines_day"},
        {1, 4, "april_fools"}, -- April Fool's Day
        {31, 10, "halloween"},
        {4, 7, "independence_day"}, -- US
        {22, 7, "july_22_test"}, -- July 22nd Test Date
        {1, 5, "may_day"},
        {23, 11, "wow_anniversary"}, -- WoW Vanilla Release Date
        -- Add more special dates here as needed
    },

    -- Time range + weekday combinations (startHour, endHour, {weekdays}, name)
    combinations = {
        {12, 14, {WEEKDAY.MONDAY, WEEKDAY.TUESDAY, WEEKDAY.WEDNESDAY, WEEKDAY.THURSDAY, WEEKDAY.FRIDAY}, "lunch_weekdays"},      -- Lunch on weekdays
        {17, 22, {WEEKDAY.MONDAY, WEEKDAY.TUESDAY, WEEKDAY.WEDNESDAY, WEEKDAY.THURSDAY, WEEKDAY.FRIDAY}, "afterwork_weekdays"},  -- After work on weekdays
        {9, 17, {WEEKDAY.MONDAY, WEEKDAY.TUESDAY, WEEKDAY.WEDNESDAY, WEEKDAY.THURSDAY, WEEKDAY.FRIDAY}, "workhours_weekdays"},   -- Work hours on weekdays
        {22, 6, {WEEKDAY.SATURDAY, WEEKDAY.SUNDAY}, "night_shift_weekend"},           -- Night shift on weekends
        {18, 24, {WEEKDAY.FRIDAY}, "friday_evening"},                  -- Friday evening
        -- Add more combinations here as needed
    },

    -- Special complex conditions
    specialConditions = {
        {
            name = "friday13th",
            check = function(dateInfo)
                return dateInfo.day == 13 and dateInfo.wday == WEEKDAY.FRIDAY -- Friday the 13th
            end
        },
        {
            name = "weekend_nights",
            check = function(dateInfo)
                local isWeekend = dateInfo.wday == WEEKDAY.SUNDAY or dateInfo.wday == WEEKDAY.SATURDAY
                local isNight = dateInfo.hour >= 22 or dateInfo.hour < 6
                return isWeekend and isNight
            end
        },
        -- Add more complex conditions here as needed
    }
}

-- Optimized function to calculate ALL time-based statistics in a single pass
-- Function to get the local timezone offset in hours
-- This ensures that time-based achievements always use the player's local time
function PSC_GetLocalTimezoneOffset()
    -- Use current time to properly account for daylight saving time
    local currentTime = time()

    local utc_date = date("!*t", currentTime)  -- UTC time
    local local_date = date("*t", currentTime) -- Local time

    -- Calculate hour difference (this handles DST and timezone automatically)
    local hour_diff = local_date.hour - utc_date.hour

    -- Handle day boundary crossings
    if hour_diff > 12 then
        hour_diff = hour_diff - 24
    elseif hour_diff < -12 then
        hour_diff = hour_diff + 24
    end

    return hour_diff
end

function PSC_CalculateAllTimeBasedStats()
    -- No timezone parameter needed - date("*t") automatically uses local time

    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return {}
    end

    local stats = {
        timeRanges = {},
        weekdays = {},
        weekdayGroups = {},
        months = {},
        specialDates = {},
        combinations = {},
        specialConditions = {}
    }

    -- Initialize all counters based on configuration
    for _, range in ipairs(TimeBasedAchievementConfig.timeRanges) do
        local key = range[1] .. "_" .. range[2]
        stats.timeRanges[key] = 0
        if range[3] then
            stats.timeRanges[range[3]] = 0
        end
    end

    for _, weekday in ipairs(TimeBasedAchievementConfig.weekdays) do
        stats.weekdays[weekday[2]] = 0
    end

    for _, group in ipairs(TimeBasedAchievementConfig.weekdayGroups) do
        stats.weekdayGroups[group[1]] = 0
    end

    for _, month in ipairs(TimeBasedAchievementConfig.months) do
        stats.months[month[1]] = 0
        stats.months[month[2]] = 0
    end

    for _, date in ipairs(TimeBasedAchievementConfig.specialDates) do
        local key = date[1] .. "_" .. date[2]
        stats.specialDates[key] = 0
        stats.specialDates[date[3]] = 0
    end

    for _, combo in ipairs(TimeBasedAchievementConfig.combinations) do
        stats.combinations[combo[4]] = 0
    end

    for _, condition in ipairs(TimeBasedAchievementConfig.specialConditions) do
        stats.specialConditions[condition.name] = 0
    end

    -- Single pass through all kills
    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp then
                    -- Use local time directly (date("*t") already handles timezone conversion)
                    local dateInfo = date("*t", killLocation.timestamp)

                    if dateInfo then
                        local hour = dateInfo.hour
                        local weekday = dateInfo.wday
                        local month = dateInfo.month
                        local day = dateInfo.day

                        -- Count time ranges
                        for _, range in ipairs(TimeBasedAchievementConfig.timeRanges) do
                            local startHour, endHour = range[1], range[2]
                            local inRange = false

                            if startHour > endHour then
                                inRange = hour >= startHour or hour < endHour
                            else
                                inRange = hour >= startHour and hour < endHour
                            end

                            if inRange then
                                local key = startHour .. "_" .. endHour
                                stats.timeRanges[key] = stats.timeRanges[key] + 1
                                if range[3] then
                                    stats.timeRanges[range[3]] = stats.timeRanges[range[3]] + 1
                                end
                            end
                        end

                        -- Count individual weekdays
                        for _, wd in ipairs(TimeBasedAchievementConfig.weekdays) do
                            if weekday == wd[1] then
                                stats.weekdays[wd[2]] = stats.weekdays[wd[2]] + 1
                            end
                        end

                        -- Count weekday groups
                        for _, group in ipairs(TimeBasedAchievementConfig.weekdayGroups) do
                            for _, targetDay in ipairs(group[2]) do
                                if weekday == targetDay then
                                    stats.weekdayGroups[group[1]] = stats.weekdayGroups[group[1]] + 1
                                    break
                                end
                            end
                        end

                        -- Count months
                        for _, m in ipairs(TimeBasedAchievementConfig.months) do
                            if month == m[1] then
                                stats.months[m[1]] = stats.months[m[1]] + 1
                                stats.months[m[2]] = stats.months[m[2]] + 1
                            end
                        end

                        -- Count special dates
                        for _, date in ipairs(TimeBasedAchievementConfig.specialDates) do
                            if day == date[1] and month == date[2] then
                                local key = date[1] .. "_" .. date[2]
                                stats.specialDates[key] = stats.specialDates[key] + 1
                                stats.specialDates[date[3]] = stats.specialDates[date[3]] + 1
                            end
                        end

                        -- Count combinations
                        for _, combo in ipairs(TimeBasedAchievementConfig.combinations) do
                            local startHour, endHour, weekdays, name = combo[1], combo[2], combo[3], combo[4]

                            -- Check if time is in range
                            local inTimeRange = false
                            if startHour > endHour then
                                inTimeRange = hour >= startHour or hour < endHour
                            else
                                inTimeRange = hour >= startHour and hour < endHour
                            end

                            -- Check if weekday matches
                            local inWeekdayRange = false
                            for _, targetDay in ipairs(weekdays) do
                                if weekday == targetDay then
                                    inWeekdayRange = true
                                    break
                                end
                            end

                            if inTimeRange and inWeekdayRange then
                                stats.combinations[name] = stats.combinations[name] + 1
                            end
                        end

                        -- Count special conditions
                        for _, condition in ipairs(TimeBasedAchievementConfig.specialConditions) do
                            if condition.check(dateInfo) then
                                stats.specialConditions[condition.name] = stats.specialConditions[condition.name] + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return stats
end

-- Cache for time-based stats - cached indefinitely until invalidated by new kills or timezone changes
local timeStatsCache = nil
local timeStatsCacheTimestamp = 0
local timeStatsCacheTimezone = nil

function PSC_GetTimeBasedStats(forceRefresh)
    local currentTimezone = PSC_GetLocalTimezoneOffset()

    -- Cache indefinitely, only refresh when forced (on new kills), if cache doesn't exist, or if timezone changed
    if not timeStatsCache or forceRefresh or timeStatsCacheTimezone ~= currentTimezone then
        timeStatsCache = PSC_CalculateAllTimeBasedStats() -- Use automatic local timezone detection
        timeStatsCacheTimestamp = time() -- Update timestamp for debugging/info purposes
        timeStatsCacheTimezone = currentTimezone -- Remember timezone used for this cache
    end

    return timeStatsCache
end

-- Function to manually clear the cache (useful for debugging, data imports, or addon reloads)
function PSC_ClearTimeStatsCache()
    timeStatsCache = nil
    timeStatsCacheTimestamp = 0
end

function PSC_CountKillsInTimeRange(startHour, endHour, timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()
    local key = startHour .. "_" .. endHour
    return stats.timeRanges[key] or 0
end

function PSC_CountKillsOnWeekdays(weekdays, timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()
    local count = 0

    for _, day in ipairs(weekdays) do
        if day == WEEKDAY.SUNDAY then
            count = count + (stats.weekdays.sunday or 0)
        elseif day == WEEKDAY.MONDAY then
            count = count + (stats.weekdays.monday or 0)
        elseif day == WEEKDAY.TUESDAY then
            count = count + (stats.weekdays.tuesday or 0)
        elseif day == WEEKDAY.WEDNESDAY then
            count = count + (stats.weekdays.wednesday or 0)
        elseif day == WEEKDAY.THURSDAY then
            count = count + (stats.weekdays.thursday or 0)
        elseif day == WEEKDAY.FRIDAY then
            count = count + (stats.weekdays.friday or 0)
        elseif day == WEEKDAY.SATURDAY then
            count = count + (stats.weekdays.saturday or 0)
        end
    end

    return count
end

function PSC_CountKillsInTimeRangeOnWeekdays(startHour, endHour, weekdays, timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()

    -- Use pre-calculated combinations for common cases
    if startHour == 12 and endHour == 14 then
        return stats.combinations.lunch_weekdays or 0
    elseif startHour == 17 and endHour == 21 then
        return stats.combinations.afterwork_weekdays or 0
    elseif startHour == 9 and endHour == 17 then
        return stats.combinations.workhours_weekdays or 0
    end

    -- Fallback to original calculation for other cases
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

function PSC_CountKillsOnDate(day, month, timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()
    local key = day .. "_" .. month
    return stats.specialDates[key] or 0
end

function PSC_CountKillsOnFridayThe13th(timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()
    return stats.specialConditions.friday13th or 0
end

function PSC_CountKillsInMonth(month, timezoneOffsetHours)
    local stats = PSC_GetTimeBasedStats()
    return stats.months[month] or 0
end

-- New helper functions for easy access to time-based stats

-- Get kills by time range name (from config)
function PSC_CountKillsByTimeRangeName(rangeName)
    local stats = PSC_GetTimeBasedStats()
    return stats.timeRanges[rangeName] or 0
end

-- Get kills by weekday group name (from config)
function PSC_CountKillsByWeekdayGroup(groupName)
    local stats = PSC_GetTimeBasedStats()
    return stats.weekdayGroups[groupName] or 0
end

-- Get kills by special date name (from config)
function PSC_CountKillsBySpecialDate(dateName)
    local stats = PSC_GetTimeBasedStats()
    return stats.specialDates[dateName] or 0
end

-- Get kills by combination name (from config)
function PSC_CountKillsByCombination(combinationName)
    local stats = PSC_GetTimeBasedStats()
    return stats.combinations[combinationName] or 0
end

-- Get kills by special condition name (from config)
function PSC_CountKillsBySpecialCondition(conditionName)
    local stats = PSC_GetTimeBasedStats()
    return stats.specialConditions[conditionName] or 0
end

-- Get kills by month name
function PSC_CountKillsByMonthName(monthName)
    local stats = PSC_GetTimeBasedStats()
    return stats.months[monthName] or 0
end

function PSC_TestTimeZoneOffsetCalculation()
    local characterKey = PSC_GetCharacterKey()
    if not PSC_DB or not PSC_DB.PlayerKillCounts or not PSC_DB.PlayerKillCounts.Characters then
        PSC_Print("ERROR: No character data found")
        return
    end
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]
    if not characterData or not characterData.Kills then
        PSC_Print("ERROR: No kills data found")
        return
    end
    local totalKills = 0
    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            totalKills = totalKills + #playerData.killLocations
        end
    end

    local localOffset = PSC_GetLocalTimezoneOffset()
    PSC_Print("SUCCESS: Found " .. totalKills .. " total kills")
    PSC_Print("Local timezone offset: UTC" .. (localOffset >= 0 and "+" or "") .. localOffset)

    -- Debug timezone calculation
    local currentTime = time()
    local utc_date = date("!*t", currentTime)
    local local_date = date("*t", currentTime)
    PSC_Print("DEBUG: UTC time: " .. utc_date.hour .. ":" .. string.format("%02d", utc_date.min))
    PSC_Print("DEBUG: System local time: " .. local_date.hour .. ":" .. string.format("%02d", local_date.min))
    PSC_Print("DEBUG: Raw hour difference: " .. (local_date.hour - utc_date.hour))

    -- Test work hours calculation
    local stats = PSC_GetTimeBasedStats()
    local workHoursKills = stats.combinations.workhours_weekdays or 0
    PSC_Print("Work hours weekdays kills: " .. workHoursKills)

    -- Test current time WITHOUT manual timezone adjustment (date("*t") already handles local time)
    local dateInfo = date("*t", currentTime)
    PSC_Print("Current calculated local time: " .. dateInfo.hour .. ":" .. string.format("%02d", dateInfo.min))
    PSC_Print("Current weekday: " .. dateInfo.wday .. " (1=Sunday, 2=Monday, etc.)")
    PSC_Print("Is work hours? " .. (dateInfo.hour >= 9 and dateInfo.hour < 17 and dateInfo.wday >= 2 and dateInfo.wday <= 6 and "YES" or "NO"))

    PSC_Print("=== TIMEZONE FIX APPLIED ===")
    PSC_Print("Fixed: All time functions now use date('*t') without manual timezone offset")
    PSC_Print("This prevents double-applying timezone conversion")
    PSC_Print("=== End Test ===")
end

function PSC_IsTimestampOnWeekday(timestamp, weekdays, timezoneOffsetHours)
    if not timestamp or not weekdays then
        return false
    end

    -- Use local time directly (date("*t") automatically handles timezone conversion)
    local dateInfo = date("*t", timestamp)
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

    -- Use local time directly (date("*t") automatically handles timezone conversion)
    local dateInfo = date("*t", timestamp)
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

    -- Use local time directly (date("*t") automatically handles timezone conversion)
    local dateInfo = date("*t", timestamp)
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

    -- Use local time directly (date("*t") automatically handles timezone conversion)
    local dateInfo = date("*t", timestamp)
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

function PSC_CountKillsStartingWithLetter(letter)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    letter = string.upper(letter)

    for playerKey, playerData in pairs(characterData.Kills) do
        local playerName = string.match(playerKey, "^([^:]+)")
        if playerName and string.upper(string.sub(playerName, 1, 1)) == letter then
            count = count + (playerData.killCount or #playerData.killLocations)
        end
    end

    return count
end

function PSC_CountKillsByLength(length)
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    for playerKey, playerData in pairs(characterData.Kills) do
        local playerName = string.match(playerKey, "^([^:]+)")
        if playerName and #playerName == length then
            count = count + (playerData.killCount or #playerData.killLocations)
        end
    end

    return count
end

function PSC_CountKillsWithAnyClassNameInName()
    local count = 0
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    local classNames = {"warrior", "paladin", "hunter", "rogue", "priest", "shaman", "mage", "warlock", "druid"}

    for playerKey, playerData in pairs(characterData.Kills) do
        local playerName = string.match(playerKey, "^([^:]+)")
        if playerName then
            local lowerPlayerName = string.lower(playerName)

            for _, className in ipairs(classNames) do
                if string.find(lowerPlayerName, className) then
                    count = count + (playerData.killCount or #playerData.killLocations)
                    break
                end
            end
        end
    end

    return count
end

function PSC_CountKillsWithNameStartingWith(letter)
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    local count = 0
    letter = string.upper(letter)

    for playerKey, playerData in pairs(characterData.Kills) do
        local playerName = string.match(playerKey, "^([^:]+)")
        if playerName and string.len(playerName) > 0 then
            local firstLetter = string.upper(string.sub(playerName, 1, 1))
            if firstLetter == letter then
                count = count + (playerData.killCount or #playerData.killLocations)
            end
        end
    end

    return count
end

function PSC_CountKillsWithNameLength(length)
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills then
        return 0
    end

    local count = 0

    for playerKey, playerData in pairs(characterData.Kills) do
        local playerName = string.match(playerKey, "^([^:]+)")
        if playerName and string.len(playerName) == length then
            count = count + (playerData.killCount or #playerData.killLocations)
        end
    end

    return count
end

function PSC_GetCurrentAchievementPoints()
    local characterKey = PSC_GetCharacterKey()
    return PSC_DB.CharacterAchievementPoints and PSC_DB.CharacterAchievementPoints[characterKey] or 0
end

function PSC_GetUnlockedAchievementCount()
    local characterKey = PSC_GetCharacterKey()
    local count = 0

    if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[characterKey] then
        for _, achievementData in pairs(PSC_DB.CharacterAchievements[characterKey]) do
            if achievementData.unlocked then
                count = count + 1
            end
        end
    end

    return count
end

function PSC_CountConsecutiveDaysWithMinKills(minKills)
    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts and PSC_DB.PlayerKillCounts.Characters and PSC_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData or not characterData.Kills or not minKills or minKills <= 0 then
        return 0
    end

    -- Collect all kill timestamps and group them by date
    local killsByDate = {}

    for playerKey, playerData in pairs(characterData.Kills) do
        if playerData.killLocations then
            for _, killLocation in ipairs(playerData.killLocations) do
                if killLocation.timestamp then
                    -- Convert timestamp to date string (YYYY-MM-DD format)
                    local dateInfo = date("*t", killLocation.timestamp)
                    if dateInfo then
                        local dateKey = string.format("%04d-%02d-%02d", dateInfo.year, dateInfo.month, dateInfo.day)
                        killsByDate[dateKey] = (killsByDate[dateKey] or 0) + 1
                    end
                end
            end
        end
    end

    -- Convert date strings to sorted array of dates that meet minimum kills requirement
    local validDates = {}
    for dateKey, killCount in pairs(killsByDate) do
        if killCount >= minKills then
            table.insert(validDates, dateKey)
        end
    end

    -- Sort dates chronologically
    table.sort(validDates)

    if #validDates == 0 then
        return 0
    end

    -- Helper function to convert date string to timestamp for day comparison
    local function dateStringToTimestamp(dateStr)
        local year, month, day = dateStr:match("(%d+)-(%d+)-(%d+)")
        year, month, day = tonumber(year), tonumber(month), tonumber(day)

        -- Calculate approximate days since epoch for comparison
        -- This is a simple approximation that works for consecutive day checking
        local days = year * 365 + month * 30 + day
        return days
    end

    -- Find the longest consecutive streak
    local maxStreak = 1  -- At least one valid day exists
    local currentStreak = 1

    -- Check consecutive days from first to last
    for i = 2, #validDates do
        local prevTimestamp = dateStringToTimestamp(validDates[i - 1])
        local currTimestamp = dateStringToTimestamp(validDates[i])

        -- Check if current date is exactly one day after previous date
        -- Allow for some flexibility in calculation due to month/year boundaries
        local dayDiff = currTimestamp - prevTimestamp
        if dayDiff >= 1 and dayDiff <= 2 then  -- Allow 1-2 day difference to handle month boundaries
            currentStreak = currentStreak + 1
            if currentStreak > maxStreak then
                maxStreak = currentStreak
            end
        else
            currentStreak = 1
        end
    end

    return maxStreak
end

-- Function to generate test streak data for testing PSC_CountConsecutiveDaysWithMinKills
function PSC_GenerateStreakTestData(days, killsPerDay, daysAgo)
    local characterKey = PSC_GetCharacterKey()

    if not PSC_DB or not PSC_DB.PlayerKillCounts or not PSC_DB.PlayerKillCounts.Characters then
        PSC_Print("Error: Database not initialized")
        return
    end

    if not PSC_DB.PlayerKillCounts.Characters[characterKey] then
        PSC_DB.PlayerKillCounts.Characters[characterKey] = {
            Kills = {},
            CurrentKillStreak = 0,
            HighestKillStreak = 0,
            HighestMultiKill = 0,
            GrayKillsCount = 0
        }
    end

    daysAgo = daysAgo or 0
    local currentTime = time()
    local startTime = currentTime - (daysAgo * 24 * 60 * 60) -- Start daysAgo days in the past

    PSC_Print(string.format("Generating %d days of test data with %d kills per day, starting %d days ago...",
        days, killsPerDay, daysAgo))

    local testNames = {
        "TestVictim", "TestTarget", "TestEnemy", "TestPlayer", "TestFoe",
        "DummyPlayer", "TestSubject", "MockVictim", "SampleTarget", "FakeEnemy"
    }

    local totalKillsAdded = 0

    for day = 0, days - 1 do
        local dayTime = startTime + (day * 24 * 60 * 60)
        local dateStr = date("%Y-%m-%d", dayTime)

        for kill = 1, killsPerDay do
            -- Create a realistic time within the day (spread kills throughout the day)
            local killTime = dayTime + (kill * (24 * 60 * 60) / killsPerDay) + math.random(-3600, 3600)

            local victimName = testNames[((kill - 1) % #testNames) + 1] .. day .. "_" .. kill
            local victimLevel = math.random(10, 60)
            local nameWithLevel = victimName .. ":" .. victimLevel

            -- Initialize kill entry if it doesn't exist
            if not PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] then
                PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] = {
                    kills = 0,
                    lastKill = 0,
                    killLocations = {},
                    rank = 0
                }
            end

            -- Add the kill
            local killData = PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel]
            killData.kills = killData.kills + 1
            killData.lastKill = killTime

            local killLocation = {
                zone = "Test Zone",
                timestamp = killTime,
                killNumber = killData.kills,
                playerLevel = UnitLevel("player") or 60,
                x = math.random(0, 100) / 100,
                y = math.random(0, 100) / 100
            }

            table.insert(killData.killLocations, killLocation)
            totalKillsAdded = totalKillsAdded + 1
        end

        PSC_Print(string.format("Generated %d kills for %s", killsPerDay, dateStr))
    end

    PSC_Print(string.format("Test data generation complete! Total kills added: %d", totalKillsAdded))
    PSC_Print("You can now test the streak function with various commands:")
    PSC_Print("- View achievements to see current streaks")
    PSC_Print("- Use '/psc debug' to see total kill counts")
end
