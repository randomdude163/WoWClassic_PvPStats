local addonName, PVPSC = ...

-- Character table for baseN encoding (a more efficient way to encode numbers)
local encodeChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"

-- Compress a number to a shorter string representation
function PSC_CompressNumber(num)
    if num < 0 then return "N" .. PSC_CompressNumber(-num) end
    if num == 0 then return "0" end

    local result = ""
    while num > 0 do
        local remainder = num % 64
        result = string.sub(encodeChars, remainder + 1, remainder + 1) .. result
        num = math.floor(num / 64)
    end
    return result
end

-- Decompress a string back to a number
function PSC_DecompressNumber(str)
    if str == "0" then return 0 end
    if str:sub(1,1) == "N" then return -PSC_DecompressNumber(str:sub(2)) end

    local num = 0
    for i = 1, #str do
        local char = str:sub(i, i)
        num = num * 64 + string.find(encodeChars, char) - 1
    end
    return num
end

-- Create compressed statistics
function PSC_CompressStatistics(stats)
    local result = {}

    -- Basic stats (k=kills, d=deaths, s=streak, m=multikill)
    result[1] = "k" .. PSC_CompressNumber(stats.totalKills or 0) ..
               "d" .. PSC_CompressNumber(stats.deaths or 0) ..
               "s" .. PSC_CompressNumber(stats.highestKillStreak or 0) ..
               "m" .. PSC_CompressNumber(stats.highestMultiKill or 0)

    -- Class data
    local classData = ""
    for class, count in pairs(stats.classData or {}) do
        if count > 0 then
            -- Use first letter of class + count
            classData = classData .. string.sub(class, 1, 1) .. PSC_CompressNumber(count)
        end
    end
    result[2] = classData

    -- Race data condensed similarly
    local raceData = ""
    for race, count in pairs(stats.raceData or {}) do
        if count > 0 then
            -- First character of race + count
            raceData = raceData .. string.sub(race, 1, 1) .. PSC_CompressNumber(count)
        end
    end
    result[3] = raceData

    -- Level data (grouped in ranges to save space)
    local levelData = {}
    for level, count in pairs(stats.levelData or {}) do
        if level == "??" then
            levelData["U"] = count  -- Unknown level
        else
            local lvl = tonumber(level)
            if lvl then
                -- Group levels: 1-10, 11-20, etc.
                local range = math.floor((lvl-1) / 10)
                levelData[range] = (levelData[range] or 0) + count
            end
        end
    end

    local levelStr = ""
    for range, count in pairs(levelData) do
        levelStr = levelStr .. range .. PSC_CompressNumber(count)
    end
    result[4] = levelStr

    return result
end

-- Decompress statistics
function PSC_DecompressStatistics(data, msgType)
    if msgType == 1 then  -- Basic stats
        local stats = {}

        -- Extract killed, deaths, etc by pattern matching
        for key, val in data:gmatch("(%a)([%w+/]+)") do
            local value = PSC_DecompressNumber(val)

            if key == "k" then stats.totalKills = value
            elseif key == "d" then stats.deaths = value
            elseif key == "s" then stats.highestKillStreak = value
            elseif key == "m" then stats.highestMultiKill = value
            end
        end

        return stats
    elseif msgType == 2 then  -- Class data
        local classMap = {W="Warrior",P="Paladin",H="Hunter",R="Rogue",
                         I="Priest",S="Shaman",M="Mage",L="Warlock",D="Druid"}
        local stats = {}

        for key, val in data:gmatch("(%a)([%w+/]+)") do
            local class = classMap[key] or "Unknown"
            stats[class] = PSC_DecompressNumber(val)
        end

        return stats
    elseif msgType == 3 then  -- Race data
        local raceMap = {H="Human",D="Dwarf",N="Night Elf",G="Gnome",
                        O="Orc",U="Undead",T="Troll",A="Tauren"}
        local stats = {}

        for key, val in data:gmatch("(%a)([%w+/]+)") do
            local race = raceMap[key] or "Unknown"
            stats[race] = PSC_DecompressNumber(val)
        end

        return stats
    elseif msgType == 4 then  -- Level data
        local stats = {}
        local rangeStart = {[0]=1, [1]=11, [2]=21, [3]=31, [4]=41, [5]=51, ["U"]="??"}

        for key, val in data:gmatch("(%w)([%w+/]+)") do
            local level = rangeStart[key] or "Unknown"
            stats[tostring(level)] = PSC_DecompressNumber(val)
        end

        return stats
    end

    return {}
end