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
                "ap:" .. (stats.achievementPoints or 0) .. ";"

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
function PSC_DecompressStatistics(data, msgType)
    -- Initialize data accumulator for multi-part messages if needed
    if not PSC_MessageAccumulator then
        PSC_MessageAccumulator = {}
    end

    -- Get sender and message part info
    local partInfo, content, marker

    if data:sub(1,1) == "p" then
        -- This is a multi-part message
        partInfo, content, marker = data:match("p(%d+):(.*)(.)")
        partInfo = tonumber(partInfo)
    else
        -- Single message
        content = data:sub(1, -2) -- Remove marker
        marker = data:sub(-1)
    end

    -- If this is a continuation message, store it
    if marker == CONTINUATION_MARKER then
        -- We need to reconstruct this later
        if not PSC_MessageAccumulator[msgType] then
            PSC_MessageAccumulator[msgType] = {}
        end

        if partInfo then
            PSC_MessageAccumulator[msgType][partInfo] = content
        else
            table.insert(PSC_MessageAccumulator[msgType], content)
        end

        -- We don't have complete data yet
        return { incomplete = true }
    end

    -- If this is the end message, combine with previous parts if any
    local fullContent = content
    if partInfo and PSC_MessageAccumulator[msgType] then
        -- Reconstruct full message
        local allParts = {}
        for i = 1, partInfo do
            if PSC_MessageAccumulator[msgType][i] then
                table.insert(allParts, PSC_MessageAccumulator[msgType][i])
            else
                -- Missing part, can't reconstruct
                if PSC_Debug then
                    print("[PSC Debug] Missing part " .. i .. " for message type " .. msgType)
                end
                return { incomplete = true }
            end
        end

        -- Add the final part
        table.insert(allParts, content)
        fullContent = table.concat(allParts)

        -- Clear accumulator for this message type
        PSC_MessageAccumulator[msgType] = nil
    end

    -- Parse the full content
    local stats = {}

    -- Split by sections
    local sections = {}
    for section in fullContent:gmatch("([^;]+);") do
        local sectionType, sectionData = section:match("(%w+);?(.*)")
        sections[sectionType] = sectionData
    end

    -- Parse basic stats
    if sections["BASIC"] then
        for key, value in sections["BASIC"]:gmatch("(%w+):([^,]+),?") do
            if key == "k" then stats.totalKills = tonumber(value)
            elseif key == "d" then stats.deaths = tonumber(value)
            elseif key == "s" then stats.highestKillStreak = tonumber(value)
            elseif key == "m" then stats.highestMultiKill = tonumber(value)
            elseif key == "cs" then stats.currentKillStreak = tonumber(value)
            elseif key == "u" then stats.uniqueKills = tonumber(value)
            elseif key == "ul" then stats.unknownLevelKills = tonumber(value)
            elseif key == "al" then stats.avgLevel = tonumber(value)
            elseif key == "ad" then stats.avgLevelDiff = tonumber(value)
            elseif key == "ap" and not stats.avgKillsPerPlayer then stats.avgKillsPerPlayer = tonumber(value)
            elseif key == "au" then stats.achievementsUnlocked = tonumber(value)
            elseif key == "ap" and not stats.achievementPoints then stats.achievementPoints = tonumber(value)
            end
        end
    end

    -- Parse class data
    if sections["CLASS"] then
        stats.classData = {}
        for class, count in sections["CLASS"]:gmatch("([^:]+):([^,]+),?") do
            stats.classData[class] = tonumber(count)
        end
    end

    -- Parse race data
    if sections["RACE"] then
        stats.raceData = {}
        for race, count in sections["RACE"]:gmatch("([^:]+):([^,]+),?") do
            stats.raceData[race] = tonumber(count)
        end
    end

    -- Parse level data
    if sections["LEVEL"] then
        stats.levelData = {}
        for level, count in sections["LEVEL"]:gmatch("([^:]+):([^,]+),?") do
            stats.levelData[level] = tonumber(count)
        end
    end

    -- Safe check for values
    for key, value in pairs(stats) do
        if type(value) == "number" and (value > 1000000 or value < -1000000) then
            stats[key] = value > 0 and 1000000 or -1000000
            if PSC_Debug then
                print("[PSC Debug] Capped unrealistic value for " .. key)
            end
        end
    end

    return stats
end