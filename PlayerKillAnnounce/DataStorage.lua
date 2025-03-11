-- Player info cache to store data we collect from various sources
local PlayerInfoCache = {}

-- Function to update player info cache
function PKA_UpdatePlayerInfoCache(name, guid, level, class, race, gender, guild)
    if not name then return end

    PlayerInfoCache[name] = PlayerInfoCache[name] or {}

    -- Only update fields if the new information is valid
    if guid and guid ~= "" then
        PlayerInfoCache[name].guid = guid
    end

    if level and level > 0 then
        PlayerInfoCache[name].level = level
    end

    if class and class ~= "" then
        PlayerInfoCache[name].class = class
    end

    if race and race ~= "" then
        PlayerInfoCache[name].race = race
    end

    if gender and gender ~= nil then
        PlayerInfoCache[name].gender = gender
    end

    if guild and guild ~= "" then
        PlayerInfoCache[name].guild = guild
    end
end

-- Function to collect player info from unit
function PKA_CollectPlayerInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    local name = UnitName(unit)
    if not name then return end

    local guid = UnitGUID(unit)
    local level = UnitLevel(unit)
    local _, englishClass = UnitClass(unit)
    local _, englishRace = UnitRace(unit)
    local gender = UnitSex(unit)

    -- Get guild information
    local guildName, _, _ = GetGuildInfo(unit)

    PKA_UpdatePlayerInfoCache(name, guid, level, englishClass, englishRace, gender, guildName)
end

-- Function to get best available player info
function PKA_GetPlayerInfo(name, guid)
    local level = 0
    local class = "Unknown"
    local race = "Unknown"
    local gender = 0
    local guild = ""

    -- Check if we have cached info
    if PlayerInfoCache[name] then
        level = PlayerInfoCache[name].level or 0
        class = PlayerInfoCache[name].class or "Unknown"
        race = PlayerInfoCache[name].race or "Unknown"
        gender = PlayerInfoCache[name].gender or 0
        guild = PlayerInfoCache[name].guild or ""
    end

    -- If we still don't have valid info, try other methods
    if level == 0 or class == "Unknown" or race == "Unknown" then
        -- Check target and mouseover in case it's the same player
        if UnitExists("target") and UnitName("target") == name then
            level = UnitLevel("target") or level
            local _, englishClass = UnitClass("target")
            class = englishClass or class
            local _, englishRace = UnitRace("target")
            race = englishRace or race
            gender = UnitSex("target") or gender
            local guildName = GetGuildInfo("target")
            guild = guildName or guild
        elseif UnitExists("mouseover") and UnitName("mouseover") == name then
            level = UnitLevel("mouseover") or level
            local _, englishClass = UnitClass("mouseover")
            class = englishClass or class
            local _, englishRace = UnitRace("mouseover")
            race = englishRace or race
            gender = UnitSex("mouseover") or gender
            local guildName = GetGuildInfo("mouseover")
            guild = guildName or guild
        end

        -- Last resort - try to get from GUID
        if guid and guid ~= "" then
            local _, englishClass = GetPlayerInfoByGUID(guid)
            if englishClass then
                class = englishClass
            end
        end
    end

    -- Default to level 1 if we still couldn't detect it
    level = level > 0 and level or 1

    -- Convert gender number to string representation
    local genderStr = "Unknown"
    if gender == 1 then
        genderStr = "Unknown"
    elseif gender == 2 then
        genderStr = "Male"
    elseif gender == 3 then
        genderStr = "Female"
    end

    return level, class, race, genderStr, guild
end

function PKA_SaveSettings()
    PlayerKillAnnounceDB.PKA_EnableKillAnnounce = PKA_EnableKillAnnounce
    PlayerKillAnnounceDB.PKA_KillAnnounceMessage = PKA_KillAnnounceMessage
    PlayerKillAnnounceDB.PKA_KillCounts = PKA_KillCounts
end

function PKA_LoadSettings()
    if PlayerKillAnnounceDB then
        PKA_EnableKillAnnounce = PlayerKillAnnounceDB.PKA_EnableKillAnnounce or true
        PKA_KillAnnounceMessage = PlayerKillAnnounceDB.PKA_KillAnnounceMessage or PlayerKillMessageDefault

        -- Handle upgrade path for older versions without level tracking
        if PlayerKillAnnounceDB.PKA_KillCounts then
            local needsUpgrade = false
            for name, data in pairs(PlayerKillAnnounceDB.PKA_KillCounts) do
                if not string.find(name, ":") then
                    needsUpgrade = true
                    break
                end
            end

            if needsUpgrade then
                local upgradedKills = {}
                for name, data in pairs(PlayerKillAnnounceDB.PKA_KillCounts) do
                    -- Add with level 0 (unknown) for older entries
                    local nameWithLevel = name .. ":0"
                    upgradedKills[nameWithLevel] = data
                end
                PlayerKillAnnounceDB.KillCounts = upgradedKills
            end
        end

        PKA_KillCounts = PlayerKillAnnounceDB.PKA_KillCounts or {}
    else
        PlayerKillAnnounceDB = {
            EnableKillAnnounce = true,
            KillAnnounceMessage = PlayerKillMessageDefault,
            KillCounts = {}
        }
        PKA_KillCounts = PlayerKillAnnounceDB.KillCounts
    end
end
