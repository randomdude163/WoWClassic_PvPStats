local addonName, PVPSC = ...

-- Maximum message length allowed by WoW
local MAX_MESSAGE_LENGTH = 250 -- Leaving some margin for safety

-- Message part indicators
local CONTINUATION_MARKER = "+"  -- Indicates more parts coming
local END_MARKER = "."           -- Indicates final part

-- Create compressed statistics
function PSC_CompressStatistics(stats)
    -- Prepare data sections
    local basicStats = "BASIC;"
    local classStats = "CLASS;"
    local raceStats = "RACE;"
    local levelStats = "LEVEL;"

    -- Basic stats
    basicStats = basicStats ..
                "k:" .. (stats.totalKills or 0) .. "," ..
                "d:" .. (stats.deaths or 0) .. "," ..
                "s:" .. (stats.highestKillStreak or 0) .. "," ..
                "m:" .. (stats.highestMultiKill or 0) .. "," ..
                "cs:" .. (stats.currentKillStreak or 0) .. "," ..
                "u:" .. (stats.uniqueKills or 0) .. "," ..
                "ul:" .. (stats.unknownLevelKills or 0) .. "," ..
                "al:" .. (stats.avgLevel or 0) .. "," ..
                "ad:" .. (stats.avgLevelDiff or 0) .. "," ..
                "ap:" .. (stats.avgKillsPerPlayer or 0) .. "," ..
                "au:" .. (stats.achievementsUnlocked or 0) .. "," ..
                "ap:" .. (stats.achievementPoints or 0) .. "," ..
                -- Add most killed player information
                "mkp:" .. (stats.mostKilledPlayer or "None") .. "," ..
                "mkc:" .. (stats.mostKilledCount or 0) .. ";"

    -- Class data
    for class, count in pairs(stats.classData or {}) do
        if count > 0 then
            classStats = classStats .. class .. ":" .. count .. ","
        end
    end
    classStats = classStats:gsub(",$", ";") -- Replace last comma with semicolon

    -- Race data
    for race, count in pairs(stats.raceData or {}) do
        if count > 0 then
            raceStats = raceStats .. race .. ":" .. count .. ","
        end
    end
    raceStats = raceStats:gsub(",$", ";") -- Replace last comma with semicolon

    -- Level data (all individual levels)
    for level, count in pairs(stats.levelData or {}) do
        levelStats = levelStats .. level .. ":" .. count .. ","
    end
    levelStats = levelStats:gsub(",$", ";") -- Replace last comma with semicolon

    -- Combine all data
    local fullData = basicStats .. classStats .. raceStats .. levelStats

    -- Split into parts if necessary
    local parts = {}
    if #fullData <= MAX_MESSAGE_LENGTH then
        -- Can fit in one message
        parts[1] = fullData .. END_MARKER
    else
        -- Need to split into multiple parts
        local currentPos = 1
        local partNum = 1

        while currentPos <= #fullData do
            local endPos = math.min(currentPos + MAX_MESSAGE_LENGTH - 10, #fullData)

            -- Find a good break point (after a semicolon)
            if endPos < #fullData then
                local lastSemicolon = fullData:sub(currentPos, endPos):find(";[^;]*$")
                if lastSemicolon then
                    endPos = currentPos + lastSemicolon
                end
            end

            local marker = (endPos == #fullData) and END_MARKER or CONTINUATION_MARKER
            local partData = "p" .. partNum .. ":" .. fullData:sub(currentPos, endPos) .. marker

            table.insert(parts, partData)
            currentPos = endPos + 1
            partNum = partNum + 1
        end
    end

    return parts
end

-- Decompress statistics
function PSC_DecompressStatistics(data, sender)
    -- Initialize data accumulator for multi-part messages if needed
    if not PSC_MessageAccumulator then
        PSC_MessageAccumulator = {}
    end

    -- Make sure we have an accumulator for this sender
    if not PSC_MessageAccumulator[sender] then
        PSC_MessageAccumulator[sender] = {}
    end

    -- Get message part info
    local partInfo, content, marker

    if data:sub(1,1) == "p" then
        -- This is a multi-part message
        partInfo, content, marker = data:match("p(%d+):(.*)(.)")
        partInfo = tonumber(partInfo)

        if PSC_Debug then
            print("[PSC Debug] Processing part " .. partInfo .. " from " .. sender .. ", marker: " .. marker)
        end
    else
        -- Single message
        content = data:sub(1, -2) -- Remove marker
        marker = data:sub(-1)

        if PSC_Debug then
            print("[PSC Debug] Processing single message from " .. sender .. ", marker: " .. marker)
        end
    end

    -- If this is a continuation message, store it
    if marker == CONTINUATION_MARKER then
        if partInfo then
            PSC_MessageAccumulator[sender][partInfo] = content

            if PSC_Debug then
                print("[PSC Debug] Stored part " .. partInfo .. " for " .. sender)
            end
        end

        -- We don't have complete data yet
        return { incomplete = true }
    end

    -- If this is the end message, combine with previous parts if any
    local fullContent = content
    if partInfo and PSC_MessageAccumulator[sender] then
        -- Reconstruct full message
        local allParts = {}

        -- Check for missing parts
        local missingParts = false
        for i = 1, partInfo-1 do
            if not PSC_MessageAccumulator[sender][i] then
                if PSC_Debug then
                    print("[PSC Debug] Missing part " .. i .. " for " .. sender)
                end
                missingParts = true
                break
            end
        end

        if missingParts then
            return { incomplete = true }
        end

        -- Collect all parts
        for i = 1, partInfo-1 do
            table.insert(allParts, PSC_MessageAccumulator[sender][i])
        end

        -- Add the final part
        table.insert(allParts, content)
        fullContent = table.concat(allParts)

        if PSC_Debug then
            print("[PSC Debug] Reconstructed full message from " .. sender .. " with " .. partInfo .. " parts")
            -- Print the first 100 chars of the message for debugging
            print("[PSC Debug] Message starts with: " .. fullContent:sub(1, 100))
        end

        -- Clear accumulator for this sender
        PSC_MessageAccumulator[sender] = {}
    end

    -- Parse the full content
    local stats = {}

    -- Extract each section directly - more reliable than regex splitting
    local basicSection = fullContent:match("BASIC;([^;]+)")
    local classSection = fullContent:match("CLASS;([^;]+)")
    local raceSection = fullContent:match("RACE;([^;]+)")
    local levelSection = fullContent:match("LEVEL;([^;]+)")

    -- Debug the sections
    if PSC_Debug then
        print("[PSC Debug] Sections found:")
        print("BASIC: " .. (basicSection and "yes" or "no"))
        print("CLASS: " .. (classSection and "yes" or "no"))
        print("RACE: " .. (raceSection and "yes" or "no"))
        print("LEVEL: " .. (levelSection and "yes" or "no"))
    end

    -- Parse basic stats
    if basicSection then
        for key, value in basicSection:gmatch("(%w+):([^,]+),?") do
            if key == "k" then
                stats.totalKills = tonumber(value)
                if PSC_Debug then print("- Parsed totalKills: " .. value) end
            elseif key == "d" then
                stats.deaths = tonumber(value)
                if PSC_Debug then print("- Parsed deaths: " .. value) end
            elseif key == "s" then
                stats.highestKillStreak = tonumber(value)
                if PSC_Debug then print("- Parsed highestKillStreak: " .. value) end
            elseif key == "m" then
                stats.highestMultiKill = tonumber(value)
                if PSC_Debug then print("- Parsed highestMultiKill: " .. value) end
            elseif key == "cs" then
                stats.currentKillStreak = tonumber(value)
                if PSC_Debug then print("- Parsed currentKillStreak: " .. value) end
            elseif key == "u" then
                stats.uniqueKills = tonumber(value)
                if PSC_Debug then print("- Parsed uniqueKills: " .. value) end
            elseif key == "ul" then
                stats.unknownLevelKills = tonumber(value)
                if PSC_Debug then print("- Parsed unknownLevelKills: " .. value) end
            elseif key == "al" then
                stats.avgLevel = tonumber(value)
                if PSC_Debug then print("- Parsed avgLevel: " .. value) end
            elseif key == "ad" then
                stats.avgLevelDiff = tonumber(value)
                if PSC_Debug then print("- Parsed avgLevelDiff: " .. value) end
            elseif key == "ap" and not stats.avgKillsPerPlayer then
                stats.avgKillsPerPlayer = tonumber(value)
                if PSC_Debug then print("- Parsed avgKillsPerPlayer: " .. value) end
            elseif key == "au" then
                stats.achievementsUnlocked = tonumber(value)
                if PSC_Debug then print("- Parsed achievementsUnlocked: " .. value) end
            elseif key == "ap" and stats.avgKillsPerPlayer then
                stats.achievementPoints = tonumber(value)
                if PSC_Debug then print("- Parsed achievementPoints: " .. value) end
            elseif key == "mkp" then
                stats.mostKilledPlayer = value
                if PSC_Debug then print("- Parsed mostKilledPlayer: " .. value) end
            elseif key == "mkc" then
                stats.mostKilledCount = tonumber(value)
                if PSC_Debug then print("- Parsed mostKilledCount: " .. value) end
            end
        end
    end

    -- Parse class data
    if classSection then
        stats.classData = {}
        for class, count in classSection:gmatch("([^:]+):([^,]+),?") do
            stats.classData[class] = tonumber(count)
        end
    end

    -- Parse race data
    if raceSection then
        stats.raceData = {}
        for race, count in raceSection:gmatch("([^:]+):([^,]+),?") do
            stats.raceData[race] = tonumber(count)
        end
    end

    -- Parse level data
    if levelSection then
        stats.levelData = {}
        for level, count in levelSection:gmatch("([^:]+):([^,]+),?") do
            stats.levelData[level] = tonumber(count)
        end
    end

    return stats
end