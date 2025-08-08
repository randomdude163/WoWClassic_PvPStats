local addonName, PVPSC = ...

PSC_RecentPlayerDamage = {}
PSC_ASSIST_DAMAGE_WINDOW = 60.0  -- 45 second window for kill assist credit

PSC_RecentlyCountedKills = {}
PSC_KILL_TRACKING_WINDOW = 1.0

PSC_MultiKillCount = 0

local function InitializeKillCountEntryForPlayer(nameWithLevel, playerLevel)
    local characterKey = PSC_GetCharacterKey()

    if not PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] then
        PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] = {
            kills = 0,
            lastKill = 0,
            killLocations = {},
            rank = 0
            -- Removed playerLevel and zone, will be stored only in killLocations
        }
    end
end

local function UpdateKillCountEntry(nameWithLevel, playerLevel)
    local characterKey = PSC_GetCharacterKey()
    local killData = PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel]

    killData.kills = killData.kills + 1
    killData.lastKill = time()

    local currentZone = GetRealZoneText() or GetSubZoneText() or "Unknown"

    local newKillLocation = {
        zone = currentZone,
        timestamp = killData.lastKill,
        killNumber = killData.kills,
        playerLevel = playerLevel
    }

    newKillLocation.x, newKillLocation.y = PSC_GetPlayerCoordinates()

    table.insert(killData.killLocations, newKillLocation)

    -- Invalidate time-based statistics cache when new kill is recorded
    if PSC_GetTimeBasedStats then
        PSC_GetTimeBasedStats(true) -- Force refresh
    end

    -- Invalidate streak statistics cache when new kill is recorded
    if PSC_GetStreakStats then
        PSC_GetStreakStats(true) -- Force refresh
    end
end

local function UpdateMultiKill()
    if not PSC_InCombat then
        PSC_MultiKillCount = 0
        return
    end

    PSC_MultiKillCount = PSC_MultiKillCount + 1

    if PSC_DB.EnableMultiKillSounds then
        local soundFile
        if PSC_MultiKillCount == 2 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\double_kill.mp3"
        elseif PSC_MultiKillCount == 3 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\triple_kill.mp3"
        elseif PSC_MultiKillCount == 4 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\quadra_kill.mp3"
        elseif PSC_MultiKillCount == 5 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\penta_kill.mp3"
        end

        if soundFile then
            PlaySoundFile(soundFile, "Master")
        end
    end

    local characterKey = PSC_GetCharacterKey()
    local highestMultiKillAlias = PSC_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill

    if PSC_MultiKillCount > highestMultiKillAlias then
        PSC_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill = PSC_MultiKillCount

        if highestMultiKillAlias >= 3 and PSC_DB.EnableRecordAnnounceMessages then
            local newMultiKillRecordMsg = string.gsub(PSC_DB.NewMultiKillRecordMessage, "MULTIKILLTEXT", GetMultiKillText(PSC_MultiKillCount))
            if IsInGroup() then
                SendChatMessage(newMultiKillRecordMsg, "PARTY")
            else
                print("[PvPStats]: " .. newMultiKillRecordMsg)
            end
        end
    end
end

local function AnnounceKill(killedPlayer, level, nameWithLevel, playerLevel)
    if PSC_CurrentlyInBattleground or not PSC_DB.EnableKillAnnounceMessages then return end

    local characterKey = PSC_GetCharacterKey()
    local killMessage = string.gsub(PSC_DB.KillAnnounceMessage, "Enemyplayername", killedPlayer)
    local killData = PSC_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel]

    if string.find(killMessage, "x#") then
        local totalKills = PSC_GetTotalsKillsForPlayer(killedPlayer)
        killMessage = string.gsub(killMessage, "x#", "x" .. totalKills)
    end

    local levelDifference = level - playerLevel
    local levelDisplay = level == -1 and "??" or tostring(level)

    if level == -1 or (level > 0 and levelDifference >= 6) then
        killMessage = killMessage .. " (Level " .. levelDisplay .. ")"
    end

    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]
    if characterData.CurrentKillStreak >= 10 and characterData.CurrentKillStreak % 5 == 0 then
        killMessage = killMessage .. " - Kill Streak: " .. characterData.CurrentKillStreak
        if not IsInGroup() then
            print("[PvPStats]: " .. killMessage)
        end
    end

    if IsInGroup() then
        SendChatMessage(killMessage, "PARTY")
    end


    if PSC_MultiKillCount >= PSC_DB.MultiKillThreshold then
        local multiKillText = GetMultiKillText(PSC_MultiKillCount)
        if PSC_DB.EnableMultiKillAnnounceMessages and IsInGroup() then
            SendChatMessage(multiKillText, "PARTY")
        else
            print("[PvPStats]: " .. multiKillText)
        end
    end
end

function PSC_RegisterPlayerKill(playerName, killerName, killerGUID)
    local playerLevel = UnitLevel("player")

    local infoKey = PSC_GetInfoKeyFromName(playerName)

    if not PSC_DB.PlayerInfoCache[infoKey] then
        if PSC_Debug then
            print("Player not found in cache: " .. playerName .. ", ignoring kill.")
        end
        return
    end

    local level = PSC_DB.PlayerInfoCache[infoKey].level
    local nameWithLevel = playerName .. ":" .. level
    local characterKey = PSC_GetCharacterKey()

    if not PSC_DB.PlayerKillCounts.Characters[characterKey] then
        PSC_DB.PlayerKillCounts.Characters[characterKey] = {
            Kills = {},
            CurrentKillStreak = 0,
            HighestKillStreak = 0,
            HighestMultiKill = 0,
            GrayKillsCount = 0
        }
    end

    -- Check if this is a gray level kill and increment counter if it is
    if PSC_IsGrayLevelKill(playerLevel, level) then
        PSC_DB.PlayerKillCounts.Characters[characterKey].GrayKillsCount =
            PSC_DB.PlayerKillCounts.Characters[characterKey].GrayKillsCount + 1

        if PSC_Debug then
            print("[PvPStats]: Gray kill registered against " .. playerName .. " (Level " .. level .. ")")
        end
    end

    UpdateKillStreak()
    ShowKillStreakMilestone(PSC_DB.PlayerKillCounts.Characters[characterKey].CurrentKillStreak)
    InitializeKillCountEntryForPlayer(nameWithLevel, playerLevel)
    UpdateKillCountEntry(nameWithLevel, playerLevel)
    UpdateMultiKill()

    local playerRank = PSC_DB.PlayerInfoCache[infoKey].rank or 0

    AnnounceKill(playerName, level, nameWithLevel, playerLevel)

    local totalKills = PSC_GetTotalsKillsForPlayer(playerName)
    if (totalKills == 1 and PSC_DB.ShowMilestoneForFirstKill) or totalKills >= 2 then
        PSC_ShowKillMilestone(playerName, level, PSC_DB.PlayerInfoCache[infoKey].class, playerRank, totalKills)
    end

    PVPSC.AchievementSystem:CheckAchievements()
end

function PSC_RecordPetDamage(petGUID, petName, targetGUID, amount)
    if not petGUID or not targetGUID then return end

    local ownerGUID = GetPetOwnerGUID(petGUID)
    if not ownerGUID then return end

    RecentPetDamage[targetGUID] = {
        timestamp = GetTime(),
        petGUID = petGUID,
        petName = petName,
        ownerGUID = ownerGUID,
        amount = amount or 0
    }

    -- if PSC_Debug then
    --     local playerGUID = PlayerGUID
    --     if ownerGUID == playerGUID then
    --         print("Recorded damage from your pet to: " .. targetName)
    --     end
    -- end
end

function PSC_CleanupRecentlyCountedKillsDict()
    local now = GetTime()
    local cutoff = now - PSC_KILL_TRACKING_WINDOW
    for guid, timestamp in pairs(PSC_RecentlyCountedKills) do
        if timestamp < cutoff then
            PSC_RecentlyCountedKills[guid] = nil
        end
    end
end

function PSC_RecordPlayerDamage(sourceGUID, sourceName, targetGUID, targetName, amount)
    if not sourceGUID or not targetGUID then return end

    if sourceGUID ~= PSC_PlayerGUID then return end

    local existingRecord = PSC_RecentPlayerDamage[targetGUID] or {
        timestamp = 0,
        totalDamage = 0
    }

    existingRecord.timestamp = GetTime()
    existingRecord.totalDamage = existingRecord.totalDamage + amount

    PSC_RecentPlayerDamage[targetGUID] = existingRecord

    -- if PSC_Debug then
    --     print(string.format("You dealt %d damage to %s", amount, targetName))
    -- end
end

function PSC_CleanupRecentPlayerDamage()
    PSC_RecentPlayerDamage = {}
end

