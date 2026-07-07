local addonName, PVPSC = ...

BPP_RecentPlayerDamage = {}
BPP_ASSIST_DAMAGE_WINDOW = 60.0  -- 45 second window for kill assist credit

BPP_RecentlyCountedKills = {}
BPP_KILL_TRACKING_WINDOW = 1.0

BPP_MultiKillCount = 0

-- Helper function to update spawn camper max kills after a new level 1 kill
local function UpdateSpawnCamperCounter(newKillTimestamp)
    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]

    -- Add the new timestamp to the cached list
    table.insert(characterData.Level1KillTimestamps, newKillTimestamp)

    -- Get the timestamp list (already sorted by insertion order since timestamps are chronological)
    local timestamps = characterData.Level1KillTimestamps
    local numTimestamps = #timestamps

    if numTimestamps == 0 then return end

    -- Optimization: Only check the sliding window around recent timestamps
    -- Start from the end and work backwards since the new kill is most likely to create a new max
    local maxKillsInWindow = characterData.SpawnCamperMaxKills or 0
    local windowStart = math.max(1, numTimestamps - 100) -- Only check last 100 kills for efficiency

    local left = windowStart
    for right = windowStart, numTimestamps do
        -- Move left pointer forward while window exceeds 60 seconds
        while left < right and timestamps[right] - timestamps[left] > 60 do
            left = left + 1
        end
        local count = right - left + 1
        if count > maxKillsInWindow then
            maxKillsInWindow = count
        end
    end

    characterData.SpawnCamperMaxKills = maxKillsInWindow

    -- Cleanup: Remove very old timestamps (older than 1 hour) to prevent unbounded growth
    local cutoffTime = newKillTimestamp - 3600
    local firstValidIndex = 1
    for i = 1, numTimestamps do
        if timestamps[i] >= cutoffTime then
            firstValidIndex = i
            break
        end
    end

    -- If we found old timestamps to remove, create a new array without them
    if firstValidIndex > 1 then
        local newTimestamps = {}
        for i = firstValidIndex, numTimestamps do
            table.insert(newTimestamps, timestamps[i])
        end
        characterData.Level1KillTimestamps = newTimestamps
    end
end

local function InitializeKillCountEntryForPlayer(nameWithLevel, playerLevel)
    local characterKey = BPP_GetCharacterKey()

    if not BPP_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] then
        BPP_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel] = {
            kills = 0,
            lastKill = 0,
            killLocations = {},
            rank = 0
            -- Removed playerLevel and zone, will be stored only in killLocations
        }
    end
end

local function UpdateKillCountEntry(nameWithLevel, playerLevel)
    local characterKey = BPP_GetCharacterKey()
    local killData = BPP_DB.PlayerKillCounts.Characters[characterKey].Kills[nameWithLevel]

    killData.kills = killData.kills + 1
    killData.lastKill = time()

    local currentZone = BPP_GetCurrentZoneName()

    local newKillLocation = {
        zone = currentZone,
        timestamp = killData.lastKill,
        killNumber = killData.kills,
        playerLevel = playerLevel
    }

    newKillLocation.x, newKillLocation.y = BPP_GetPlayerCoordinates()

    table.insert(killData.killLocations, newKillLocation)
end

local function UpdateMultiKill()
    if not BPP_InCombat then
        BPP_MultiKillCount = 0
        return
    end

    BPP_MultiKillCount = BPP_MultiKillCount + 1

    -- Play single kill sound for first kill if enabled and not playing multi-kill sounds
    if BPP_MultiKillCount == 1 and BPP_DB.EnableSingleKillSounds then
        local soundFile
        local soundPack = BPP_DB.SoundPack or "LoL"

        if soundPack == "LoL" then
            local lolSounds = {"an_enemy_has_been_slain.mp3", "first_blood.mp3", "shut-down.mp3", "dominating.mp3"}
            local randomIndex = math.random(1, #lolSounds)
            soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\" .. lolSounds[randomIndex]
        else
            local utSounds = {"first-blood.mp3", "head-hunter.mp3", "dominating.mp3"}
            local randomIndex = math.random(1, #utSounds)
            soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\UT\\" .. utSounds[randomIndex]
        end

        if soundFile then
            PlaySoundFile(soundFile, "Master")
        end
    elseif BPP_MultiKillCount > 1 and BPP_DB.EnableMultiKillSounds then
        -- Play multi-kill sounds for 2+ kills
        local soundFile
        local soundPack = BPP_DB.SoundPack or "LoL"

        if soundPack == "LoL" then
            if BPP_MultiKillCount == 2 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\double_kill.mp3"
            elseif BPP_MultiKillCount == 3 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\triple_kill.mp3"
            elseif BPP_MultiKillCount == 4 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\quadra_kill.mp3"
            elseif BPP_MultiKillCount == 5 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\penta_kill.mp3"
            elseif BPP_MultiKillCount == 6 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\hexa-kill.mp3"
            elseif BPP_MultiKillCount == 7 then
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\legendary-kill.mp3"
            end
        else -- UT sounds
            local utSounds = {}
            if BPP_MultiKillCount == 2 then
                utSounds = {"double-kill.mp3", "multi-kill.mp3", "killing-spree.mp3", "combowhore.mp3", "head-hunter.mp3"}
            elseif BPP_MultiKillCount == 3 then
                utSounds = {"triple-kill.mp3", "multi-kill.mp3", "killing-spree.mp3", "unstoppable.mp3", "holy-shit.mp3", "unreal.mp3"}
            elseif BPP_MultiKillCount == 4 then
                utSounds = {"ultra-kill.mp3", "mega-kill.mp3", "god-like.mp3"}
            elseif BPP_MultiKillCount >= 5 then
                utSounds = {"ludicrous-kill.mp3", "monster-kill.mp3"}
            end

            if #utSounds > 0 then
                local randomIndex = math.random(1, #utSounds)
                soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\UT\\" .. utSounds[randomIndex]
            end
        end

        if soundFile then
            PlaySoundFile(soundFile, "Master")
        end
    end

    local characterKey = BPP_GetCharacterKey()
    local highestMultiKillAlias = BPP_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill

    if BPP_MultiKillCount > highestMultiKillAlias then
        BPP_DB.PlayerKillCounts.Characters[characterKey].HighestMultiKill = BPP_MultiKillCount

        if highestMultiKillAlias >= 3 and BPP_DB.EnableRecordAnnounceMessages and not BPP_CurrentlyInBattleground then
            local newMultiKillRecordMsg = string.gsub(BPP_DB.NewMultiKillRecordMessage, "MULTIKILLTEXT", BPP_GetMultiKillText(BPP_MultiKillCount))
            BPP_SendAnnounceMessage(newMultiKillRecordMsg)
        end
    end
end

local function AnnounceKill(killedPlayer, level, nameWithLevel, playerLevel)
    if BPP_CurrentlyInBattleground or not BPP_DB.EnableKillAnnounceMessages then return end

    local characterKey = BPP_GetCharacterKey()
    local killMessage = string.gsub(BPP_DB.KillAnnounceMessage, "Enemyplayername", killedPlayer)

    if string.find(killMessage, "x#") then
        local totalKills = BPP_GetTotalsKillsForPlayer(killedPlayer)
        killMessage = string.gsub(killMessage, "x#", "x" .. totalKills)
    end

    local levelDifference = level - playerLevel
    local levelDisplay = level == -1 and "??" or tostring(level)

    -- Build details string to include player and/or guild information
    local detailsString = ""
    local infoKey = BPP_GetInfoKeyFromName(killedPlayer)
    local playerInfo = BPP_DB.PlayerInfoCache[infoKey]

    -- Include player details if option is enabled
    if BPP_DB.IncludePlayerDetailsInAnnounce then
        if playerInfo then
            local classDisplay = playerInfo.class or "Unknown"
            local raceDisplay = playerInfo.race or "Unknown"
            detailsString = "Level " .. levelDisplay .. " " .. raceDisplay .. " " .. classDisplay
        else
            detailsString = "Level " .. levelDisplay
        end
    elseif level == -1 or (level > 0 and levelDifference >= 6) then
        detailsString = "Level " .. levelDisplay
    end

    -- Include guild details if option is enabled
    if BPP_DB.IncludeGuildDetailsInAnnounce then
        if playerInfo and playerInfo.guild and playerInfo.guild ~= "" then
            local guildRankDisplay = playerInfo.guildRank or "Member"
            local guildString = guildRankDisplay .. " of <" .. playerInfo.guild .. ">"
            if detailsString ~= "" then
                detailsString = detailsString .. ", " .. guildString
            else
                detailsString = guildString
            end
        end
    end

    -- Add details to message if any details were included
    if detailsString ~= "" then
        killMessage = killMessage .. " (" .. detailsString .. ")"
    end

    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]
    if characterData.CurrentKillStreak >= 10 and characterData.CurrentKillStreak % 5 == 0 then
        killMessage = killMessage .. " - Kill Streak: " .. characterData.CurrentKillStreak
    end

    BPP_SendAnnounceMessage(killMessage)

    if BPP_MultiKillCount >= BPP_DB.MultiKillThreshold then
        local multiKillText = BPP_GetMultiKillText(BPP_MultiKillCount)
        if BPP_DB.EnableMultiKillAnnounceMessages then
            BPP_SendAnnounceMessage(multiKillText)
        end
    end
end

function BPP_RegisterPlayerKill(playerName, killerName, killerGUID)
    local playerLevel = UnitLevel("player")
    local infoKey = BPP_GetInfoKeyFromName(playerName)

    if not BPP_DB.PlayerInfoCache[infoKey] then
        if BPP_Debug then
            print("Player not found in cache: " .. playerName .. ", ignoring kill.")
        end
        return
    end

    local level = BPP_DB.PlayerInfoCache[infoKey].level
    -- infoKey already includes the realm (Name-Realm)
    -- This ensures distinct keys for same-named players on different realms
    local nameWithLevel = infoKey .. ":" .. level
    local characterKey = BPP_GetCharacterKey()

    if not BPP_DB.PlayerKillCounts.Characters[characterKey] then
        BPP_DB.PlayerKillCounts.Characters[characterKey] = {
            Kills = {},
            CurrentKillStreak = 0,
            HighestKillStreak = 0,
            HighestMultiKill = 0,
            GrayKillsCount = 0
        }
    end

    -- Check if this is a gray level kill and increment counter if it is
    if BPP_IsGrayLevelKill(playerLevel, level) then
        BPP_DB.PlayerKillCounts.Characters[characterKey].GrayKillsCount =
            BPP_DB.PlayerKillCounts.Characters[characterKey].GrayKillsCount + 1

        if BPP_Debug then
            print("[BigPPvP]: Gray kill registered against " .. playerName .. " (Level " .. level .. ")")
        end
    end

    -- Update spawn camper counter if this is a level 1 kill
    if level == 1 then
        UpdateSpawnCamperCounter(time())
    end

    BPP_UpdateKillStreak(playerName, level, BPP_DB.PlayerInfoCache[infoKey].class)
    BPP_ShowKillStreakMilestone(BPP_DB.PlayerKillCounts.Characters[characterKey].CurrentKillStreak)
    InitializeKillCountEntryForPlayer(nameWithLevel, playerLevel)
    UpdateKillCountEntry(nameWithLevel, playerLevel)
    UpdateMultiKill()
    AnnounceKill(playerName, level, nameWithLevel, playerLevel)

    local totalKills = BPP_GetTotalsKillsForPlayer(playerName)
    local playerRank = BPP_DB.PlayerInfoCache[infoKey].rank or 0
    if (totalKills == 1 and BPP_DB.ShowMilestoneForFirstKill) or totalKills >= 2 then
        BPP_ShowKillMilestone(playerName, level, BPP_DB.PlayerInfoCache[infoKey].class, playerRank, totalKills)
    end

    BPP_StartIncrementalAchievementsCalculation()
end

function BPP_RecordPetDamage(petGUID, petName, targetGUID, amount)
    if not petGUID or not targetGUID then return end

    local ownerGUID = BPP_GetPetOwnerGUID(petGUID)
    if not ownerGUID then return end

    BPP_RecentPetDamage[targetGUID] = {
        timestamp = GetTime(),
        petGUID = petGUID,
        petName = petName,
        ownerGUID = ownerGUID,
        amount = amount or 0
    }
    if ownerGUID == BPP_PlayerGUID then
        BPP_RecordPlayerDamage(ownerGUID, BPP_CharacterName, targetGUID, "Unknown", amount)
        if BPP_Debug then
            print("Recorded damage from your pet to: " .. targetGUID .. " Amount: " .. amount)
        end
    end
end

function BPP_CleanupRecentlyCountedKillsDict()
    local now = GetTime()
    local cutoff = now - BPP_KILL_TRACKING_WINDOW
    for guid, timestamp in pairs(BPP_RecentlyCountedKills) do
        if timestamp < cutoff then
            BPP_RecentlyCountedKills[guid] = nil
        end
    end
end

function BPP_RecordPlayerDamage(sourceGUID, sourceName, targetGUID, targetName, amount)
    if not sourceGUID or not targetGUID then return end

    if sourceGUID ~= BPP_PlayerGUID then return end

    local existingRecord = BPP_RecentPlayerDamage[targetGUID] or {
        timestamp = 0,
        totalDamage = 0
    }

    existingRecord.timestamp = GetTime()
    existingRecord.totalDamage = existingRecord.totalDamage + amount

    BPP_RecentPlayerDamage[targetGUID] = existingRecord

    -- if BPP_Debug then
    --     print(string.format("You dealt %d damage to %s", amount, targetName))
    -- end
end

function BPP_CleanupRecentPlayerDamage()
    BPP_RecentPlayerDamage = {}
end

function BPP_RegisterNPCKill(npcName, npcID)
    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]

    if not characterData.NPCKills then
        characterData.NPCKills = {}
    end

    characterData.NPCKills[npcName] = (characterData.NPCKills[npcName] or 0) + 1

    if BPP_Debug then
        print("[BigPPvP]: Recorded kill for NPC: " .. npcName .. " (ID: " .. npcID .. ")")
    end

    BPP_StartIncrementalAchievementsCalculation()
end

