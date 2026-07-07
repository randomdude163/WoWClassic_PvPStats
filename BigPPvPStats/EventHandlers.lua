local addonName, PVPSC = ...

local pvpStatsClassicFrame = CreateFrame("Frame", "BigPPvPStatsFrame", UIParent)

BPP_Debug = false
BPP_PlayerGUID = ""
BPP_CharacterName = ""
BPP_RealmName = ""

BPP_GAME_VERSIONS = {
    CLASSIC = 1,
    TBC = 2,
    WOTLK = 3,
}
BPP_GameVersion = nil

BPP_RecentPetDamage = {}
local PET_DAMAGE_WINDOW = 0.05

BPP_InCombat = false

BPP_LastDeathTime = 0
BPP_DEATH_EVENT_COOLDOWN = 2 -- seconds to ignore duplicate death events

BPP_CurrentlyInBattleground = false
BPP_lastInBattlegroundValue = false

BPP_PendingHunterKills = {}
local HUNTER_FEIGN_DEATH_CHECK_WINDOW = 3.0 -- Seconds to wait before confirming kill
local HUNTER_FEIGN_DEATH_MIN_LEVEL = 30

BPP_RecentlyCountedPriestKills = {}
local PRIEST_SPIRIT_OF_REDEMPTION_MIN_LEVEL = 30
local PRIEST_KILL_DEDUP_WINDOW = 20.0 -- 15s Spirit of Redemption + lag margin

local function OnPlayerTargetChanged()
    BPP_GetAndStorePlayerInfoFromUnit("target")
    BPP_GetAndStorePlayerInfoFromUnit("targettarget")
    BPP_UpdatePetOwnerFromUnit("target")
    BPP_UpdatePetOwnerFromUnit("targettarget")
end

local function OnUpdateMouseoverUnit()
    BPP_GetAndStorePlayerInfoFromUnit("mouseover")
    BPP_UpdatePetOwnerFromUnit("mouseover")
end

local function HandleCombatState(inCombatNow)
    if BPP_InCombat and not inCombatNow then
        BPP_MultiKillCount = 0
        BPP_InCombat = false
    elseif not BPP_InCombat and inCombatNow then
        BPP_MultiKillCount = 0
        BPP_InCombat = true
    end
end

local function SendWarningIfKilledByHighLevelPlayer(killerInfo)
    local killerName = killerInfo.killer.name

    local infoKey = BPP_GetInfoKeyFromName(killerName)

    if not BPP_DB.PlayerInfoCache[infoKey] then
        if BPP_Debug then
            print("Warning: Killer " .. killerName .. " not found in player info cache")
        end
        return
    end

    local killerLevel = BPP_DB.PlayerInfoCache[infoKey].level
    local killerClass = BPP_DB.PlayerInfoCache[infoKey].class

    if killerLevel ~= -1 then
        return
    end

    if not IsInGroup() then
        return
    end

    local playerX, playerY = BPP_GetPlayerCoordinates()
    local playerCoords = string.format("%.1f, %.1f", playerX, playerY)
    local subZoneText = GetSubZoneText()
    local playerPosition = ""
    if subZoneText ~= "" then
        playerPosition = subZoneText .. " (" .. playerCoords .. ")"
    else
        playerPosition = playerCoords
    end
    local warningMsg = "I got killed by " .. killerName .. " (Level ?? " .. killerClass .. ") at " .. playerPosition .. "!"
    SendChatMessage(warningMsg, "PARTY")
end

function BPP_HandlePlayerDeath()
    if not BPP_CharacterName or BPP_CharacterName == "" then
        return
    end

    local now = GetTime()
    if (now - BPP_LastDeathTime) < BPP_DEATH_EVENT_COOLDOWN then
        if BPP_Debug then
            print("Ignoring duplicate PLAYER_DEAD event")
        end
        return
    end

    BPP_LastDeathTime = now

    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters[characterKey]

    if characterData.CurrentKillStreak >= 10 and BPP_DB.EnableRecordAnnounceMessages and not BPP_CurrentlyInBattleground then
        local streakEndedMsg = string.gsub(BPP_DB.KillStreakEndedMessage, "STREAKCOUNT", characterData.CurrentKillStreak)
        BPP_SendAnnounceMessage(streakEndedMsg)
    end

    characterData.CurrentKillStreak = 0
    characterData.CurrentKillStreakPlayers = {} -- Clear kill streak players list
    BPP_MultiKillCount = 0
    BPP_InCombat = false

    -- Update kill streak popup if it's open
    if BPP_UpdateKillStreakPopup then
        BPP_UpdateKillStreakPopup()
    end

    -- Play death sound if enabled
    if BPP_DB.EnableDeathSounds then
        local soundPack = BPP_DB.SoundPack or "LoL"
        local soundFile
        if soundPack == "LoL" then
            local lolDeathSounds = {"you_have_been_slain.mp3", "defeat.mp3"}
            local randomIndex = math.random(1, #lolDeathSounds)
            soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\LoL\\" .. lolDeathSounds[randomIndex]
        else
            soundFile = "Interface\\AddOns\\BigPPvPStats\\sounds\\UT\\you-have-failed-to-proceed.mp3"
        end
        PlaySoundFile(soundFile, "Master")
    end

    print("[BigPPvP]: You died, kill streak reset.")

    if BPP_CurrentlyInBattleground and not BPP_DB.CountDeathsInBattlegrounds then
        if BPP_Debug then print("BG Mode: Death tracking disabled in battlegrounds") end
        return
    end

    local killerInfo = BPP_GetKillerInfoOnDeath()
    if killerInfo then
        if not BPP_CurrentlyInBattleground then
            SendWarningIfKilledByHighLevelPlayer(killerInfo)
        end
        BPP_RegisterPlayerDeath(killerInfo)
    end
end

local function CleanupRecentPetDamage()
    local now = GetTime()
    local cutoff = now - PET_DAMAGE_WINDOW

    for guid, info in pairs(BPP_RecentPetDamage) do
        if info.timestamp < cutoff then
            BPP_RecentPetDamage[guid] = nil
        end
    end
end

BPP_TrackedNPCs = {
    [349] = "Corporal Keeshan",
    [467] = "The Defias Traitor",
    [550] = "Defias Messenger"
}

function BPP_IsValidTarget(destFlags, destGUID)
    if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and
       bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 then
        return true
    end

    if destGUID then
        local npcID = BPP_GetNPCIDFromGUID(destGUID)
        if npcID and BPP_TrackedNPCs[npcID] then
            return true
        end
    end

    return false
end

local function HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, param1, param4)
    if sourceGUID ~= BPP_PlayerGUID then return end

    local damageAmount = param1 or param4 or 0
    if damageAmount <= 0 then return end

    BPP_RecordPlayerDamage(sourceGUID, sourceName, destGUID, destName, damageAmount)
end

local function HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)
    if sourceGUID ~= BPP_PlayerGUID then return end

    local damageAmount = 0
    local isUtilitySpell = false

    if combatEvent == "SWING_DAMAGE" then
        damageAmount = param1 or 0
    elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "RANGE_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "SPELL_DISPEL" or
        combatEvent == "SPELL_INTERRUPT" or
        combatEvent == "SPELL_AURA_APPLIED" or
        combatEvent == "SPELL_AURA_APPLIED_DOSE" or
        combatEvent == "SPELL_AURA_REFRESH" or
        combatEvent == "SPELL_AURA_REMOVED" then
        isUtilitySpell = true
        damageAmount = 1
    end

    if damageAmount > 0 or isUtilitySpell then
        HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, damageAmount, nil)
    end
end

function BPP_IsHunterAndCanFeignDeath(destName)
    local infoKey = BPP_GetInfoKeyFromName(destName)
    if not BPP_DB.PlayerInfoCache[infoKey] then
        return false
    end

    local isHunter = BPP_DB.PlayerInfoCache[infoKey].class == "Hunter"
    local level = BPP_DB.PlayerInfoCache[infoKey].level

    if not isHunter then
        return false
    end

    if level == -1 then
        return true
    end

    if level < HUNTER_FEIGN_DEATH_MIN_LEVEL then
        return false
    end

    return true
end

local function ShouldSuppressPriestKillForSpiritOfRedemption(destName)
    if not destName or destName == "" then
        return false
    end

    local infoKey = BPP_GetInfoKeyFromName(destName)
    local playerInfo = BPP_DB.PlayerInfoCache[infoKey]
    if not playerInfo or playerInfo.class ~= "Priest" then
        return false
    end

    local level = playerInfo.level
    if level ~= -1 and level < PRIEST_SPIRIT_OF_REDEMPTION_MIN_LEVEL then
        return false
    end

    local now = GetTime()
    local lastKillTimestamp = BPP_RecentlyCountedPriestKills[infoKey]
    if lastKillTimestamp and (now - lastKillTimestamp) < PRIEST_KILL_DEDUP_WINDOW then
        if BPP_Debug then
            print("Suppressing duplicate priest kill during Spirit of Redemption window for " .. destName)
        end
        return true
    end

    BPP_RecentlyCountedPriestKills[infoKey] = now
    return false
end

function BPP_ScheduleHunterKillValidation(destGUID, destName, eventType, validationData)
    if not BPP_IsHunterAndCanFeignDeath(destName) then
        return false
    end

    if BPP_Debug then
        print("Hunter " .. destName .. " might be using feign death- validating...")
    end

    BPP_PendingHunterKills[destGUID] = {
        name = destName,
        timestamp = GetTime(),
        eventType = eventType,
        gotDamagedAfter = false,
        validationData = validationData
    }

    C_Timer.After(HUNTER_FEIGN_DEATH_CHECK_WINDOW, function()
        BPP_ValidateHunterKill(destGUID)
    end)

    return true
end

local function HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    if BPP_CurrentlyInBattleground and not BPP_DB.CountKillsInBattlegrounds then
        if BPP_Debug then print("BG Mode: Kill tracking disabled in battlegrounds") end
        return
    end

    local countKill = false

    if BPP_CurrentlyInBattleground then
        if sourceGUID == BPP_PlayerGUID then
            countKill = true
            if BPP_Debug then print("BG Mode: Player killing blow") end
        else
            if BPP_Debug then print("BG Mode: Party/Raid member killing blow ignored") end
        end
    else
        if sourceGUID == BPP_PlayerGUID then
            countKill = true
            if BPP_Debug then print("Normal Mode: Player killing blow") end
        elseif UnitInParty(sourceName) or UnitInRaid(sourceName) then
            countKill = true
            if BPP_Debug then print("Normal Mode: Party/Raid member killing blow") end
        end
    end

    if countKill then
        local npcID = BPP_GetNPCIDFromGUID(destGUID)
        if npcID and BPP_TrackedNPCs[npcID] then
             -- Mobs tracked by ID are handled exclusively in UnitDied to ensure player participation
        else
            local unitType = strsplit("-", destGUID)
            if unitType == "Player" then
                if ShouldSuppressPriestKillForSpiritOfRedemption(destName) then
                    return
                end
                BPP_RecentlyCountedKills[destGUID] = GetTime()
                BPP_RegisterPlayerKill(destName, sourceName, sourceGUID)
            end
        end
    end
end

local function HandleUnitDiedEvent(destGUID, destName)
    if BPP_RecentlyCountedKills[destGUID] then
        if (GetTime() - BPP_RecentlyCountedKills[destGUID]) < BPP_KILL_TRACKING_WINDOW then
            return
        end
    end

    if BPP_CurrentlyInBattleground and not BPP_DB.CountKillsInBattlegrounds then
        return
    end

    local countKill = false
    local petDamage = BPP_RecentPetDamage[destGUID]

    if petDamage and (GetTime() - petDamage.timestamp) <= PET_DAMAGE_WINDOW then
        if BPP_CurrentlyInBattleground then
            if petDamage.ownerGUID == BPP_PlayerGUID then
                countKill = true
                if BPP_Debug then
                    print("BG Mode: Pet killing blow detected (via recent damage)")
                    print("Pet: " .. (petDamage.petName or "Unknown"))
                end
            else
                if BPP_Debug then print("BG Mode: Pet killing blow ignored (not your pet)") end
            end
        else
            if petDamage.ownerGUID == BPP_PlayerGUID then
                countKill = true
                if BPP_Debug then
                    print("Normal Mode: Your pet killing blow detected")
                end
            else
                local ownerName = BPP_GetNameFromGUID(petDamage.ownerGUID)
                if ownerName and (UnitInParty(ownerName) or UnitInRaid(ownerName)) then
                    countKill = true
                    if BPP_Debug then
                        print("Normal Mode: Party/raid member's pet kill detected")
                    end
                end
            end
        end

        if countKill then
            local npcID = BPP_GetNPCIDFromGUID(destGUID)
            if npcID and BPP_TrackedNPCs[npcID] then
                -- For tracked NPCs, only player's own pet counts as a Killing Blow here.
                -- Party pet kills are ignored here and fall through to the assist check to verify participation.
                if petDamage.ownerGUID == BPP_PlayerGUID then
                    BPP_RecentlyCountedKills[destGUID] = GetTime()
                    BPP_RegisterNPCKill(BPP_TrackedNPCs[npcID], npcID)
                end
            else
                local unitType = strsplit("-", destGUID)
                if unitType == "Player" then
                    if ShouldSuppressPriestKillForSpiritOfRedemption(destName) then
                        return
                    end
                    BPP_RecentlyCountedKills[destGUID] = GetTime()
                    BPP_RegisterPlayerKill(destName, petDamage.petName, petDamage.petGUID)
                end
            end

            -- If we registered a kill (NPC or Player), we return.
            -- If we skipped (Party Pet NPC KB), we continue to allow assist check.
            if (npcID and BPP_TrackedNPCs[npcID] and petDamage.ownerGUID == BPP_PlayerGUID) or
               (npcID == nil and strsplit("-", destGUID) == "Player") then
                BPP_RecentPetDamage[destGUID] = nil
                return
            end
        end
    end

    local playerDamage = BPP_RecentPlayerDamage[destGUID]
    if playerDamage and (GetTime() - playerDamage.timestamp) <= BPP_ASSIST_DAMAGE_WINDOW then
        if playerDamage.totalDamage > 0 then
            if BPP_CurrentlyInBattleground and not BPP_DB.CountAssistsInBattlegrounds then
                if BPP_Debug then
                    print("BG Mode: Assist kill ignored (assists disabled in BGs)")
                end
                return
            end

            if BPP_Debug then
                print("Assist kill detected for: " .. destName)
            end

            BPP_RecentlyCountedKills[destGUID] = GetTime()
            local npcID = BPP_GetNPCIDFromGUID(destGUID)
            if npcID and BPP_TrackedNPCs[npcID] then
                BPP_RegisterNPCKill(BPP_TrackedNPCs[npcID], npcID)
            else
                local unitType = strsplit("-", destGUID)
                if unitType == "Player" then
                    if ShouldSuppressPriestKillForSpiritOfRedemption(destName) then
                        return
                    end
                    BPP_RegisterPlayerKill(destName, "Assist", nil)
                end
            end
            BPP_RecentPlayerDamage[destGUID] = nil
        end
    end
end

local function HandleCombatLogEventPetDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, param1, param4)
    if BPP_IsPetGUID(sourceGUID) and destGUID then
        local damageAmount = 0

        if combatEvent == "SWING_DAMAGE" then
            damageAmount = param1 or 0
        elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
            damageAmount = param4 or 0
        elseif combatEvent == "RANGE_DAMAGE" then
            damageAmount = param4 or 0
        end

        if damageAmount > 0 then
            BPP_RecordPetDamage(sourceGUID, sourceName, destGUID, damageAmount)
        end
    end
end

function BPP_ValidateHunterKill(destGUID)
    local eventData = BPP_PendingHunterKills[destGUID]
    if not eventData then return end

    if eventData.gotDamagedAfter then
        if BPP_Debug then
            print("Validation: Hunter " .. eventData.name ..
                  " received damage after event - ignoring as likely feign death")
        end

        BPP_PendingHunterKills[destGUID] = nil
        return
    end

    -- No damage received during validation window, process as a real event
    if BPP_Debug then
        print("Validation: Hunter " .. eventData.name ..
              " received no damage after death - processing as normal kill")
    end

    -- Simply call the appropriate handler based on event type
    if eventData.eventType == "PARTY_KILL" then
        local sourceGUID = eventData.validationData.sourceGUID
        local sourceName = eventData.validationData.sourceName

        -- Call the existing party kill handler
        HandlePartyKillEvent(sourceGUID, sourceName, destGUID, eventData.name)
    elseif eventData.eventType == "UNIT_EVENT" then
        -- Call the existing unit died handler
        HandleUnitDiedEvent(destGUID, eventData.name)
    end

    -- Clean up the pending event
    BPP_PendingHunterKills[destGUID] = nil
end

local function HandleCombatLogEvent()
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5, param6, param7, param8 = CombatLogGetCurrentEventInfo()

    if destGUID and BPP_PendingHunterKills[destGUID] and
       (combatEvent == "SWING_DAMAGE" or
        combatEvent == "SPELL_DAMAGE" or
        combatEvent == "SPELL_PERIODIC_DAMAGE" or
        combatEvent == "RANGE_DAMAGE") then
        BPP_PendingHunterKills[destGUID].gotDamagedAfter = true

        if BPP_Debug then
            print("Hunter " .. destName .. " received damage after event - likely using feign death")
        end
    end

    local isValidTarget = BPP_IsValidTarget(destFlags, destGUID)

    if isValidTarget then
        HandleCombatLogEventPetDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, param1, param4)
        HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)
    end

    if destGUID == BPP_PlayerGUID then
        if sourceGUID == BPP_PlayerGUID then
            -- Ignore self-damage events
            return
        end

        if bit.band(sourceFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
            local spellId, spellName
            if combatEvent == "SWING_DAMAGE" then
                spellId = 0
                spellName = "Melee"
            else
                spellId = param1
                spellName = param2
            end

            BPP_HandleReceivedPlayerDamage(combatEvent, sourceGUID, sourceName, spellId, spellName, param1, param4)
        elseif BPP_IsPetGUID(sourceGUID) then
            BPP_HandleReceivedPlayerDamageByEnemyPets(combatEvent, sourceGUID, sourceName, param1, param4)
        end
    end

    if combatEvent == "PARTY_KILL" and isValidTarget then
        local isScheduled = BPP_ScheduleHunterKillValidation(destGUID, destName, "PARTY_KILL", {
            sourceGUID = sourceGUID,
            sourceName = sourceName
        })

        if not isScheduled then
            HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
        end
    end

    if combatEvent == "UNIT_DIED" and isValidTarget then
        local isScheduled = BPP_ScheduleHunterKillValidation(destGUID, destName, "UNIT_EVENT", {})

        if not isScheduled then
            HandleUnitDiedEvent(destGUID, destName)
        end
    end
end

function BPP_CleanupPendingHunterKills()
    local now = GetTime()
    local cutoff = now - (HUNTER_FEIGN_DEATH_CHECK_WINDOW * 2)

    for guid, data in pairs(BPP_PendingHunterKills) do
        if data.timestamp < cutoff then
            BPP_PendingHunterKills[guid] = nil
        end
    end
end

function BPP_CleanupRecentlyCountedPriestKills()
    local now = GetTime()
    local cutoff = now - (PRIEST_KILL_DEDUP_WINDOW * 2)

    for infoKey, timestamp in pairs(BPP_RecentlyCountedPriestKills) do
        if timestamp < cutoff then
            BPP_RecentlyCountedPriestKills[infoKey] = nil
        end
    end
end

local function DetermineGameVersion()
    -- Example output of GetBuildInfo()
    -- 1.15.8 64858 Dec  9 2025 11508  Release  11508
    local versionString = GetBuildInfo()
    local major, minor, patch = versionString:match("^(%d+)%.(%d+)%.(%d+)")

    major = tonumber(major)
    minor = tonumber(minor)
    patch = tonumber(patch)
    local game_version = nil

    if major == 1 then
        game_version = BPP_GAME_VERSIONS.CLASSIC
    elseif major == 2 then
        game_version =  BPP_GAME_VERSIONS.TBC
    elseif major == 3 then
        game_version =  BPP_GAME_VERSIONS.WOTLK
    end

    if BPP_Debug then
        print("Detected game version: " .. tostring(game_version))
    end

    return game_version
end

local addonWelcomeMessageShown = false

local function HandlePlayerEnteringWorld()
    BPP_PlayerGUID = UnitGUID("player")
    BPP_CharacterName = UnitName("player")
    BPP_RealmName = GetRealmName()
    BPP_GameVersion = DetermineGameVersion()

    PVPSC.AchievementSystem:InitializeAchievements()

    if not BPP_DB then
        BPP_DB = {}
        BPP_LoadDefaultSettings()
        BPP_ResetAllStatsToDefault()
    end

    -- Initialize minimap button settings if not present
    if not BPP_DB.minimapButton then
        BPP_DB.minimapButton = {
            hide = false,
        }
        -- Migrate old position if it exists
        if BPP_DB.MinimapButtonPosition then
            BPP_DB.minimapButton.minimapPos = BPP_DB.MinimapButtonPosition
        end
    end

    -- Initialize announce channel setting if not present (migration for existing users)
    if not BPP_DB.AnnounceChannel then
        BPP_DB.AnnounceChannel = "GROUP"
    end

    -- Initialize what's-new popup tracking
    if BPP_DB.WhatsNewPopupShown == nil then
        BPP_DB.WhatsNewPopupShown = false
    end

    if BPP_DB.WhatsNewPopupVersion == nil then
        BPP_DB.WhatsNewPopupVersion = "v1.0"
    end

    if BPP_DB.PlayerInfoCache == nil then
        BPP_DB.PlayerInfoCache = {}
    end
    BPP_GetAndStorePlayerInfoFromUnit("player", true)

    BPP_MigratePlayerInfoCache()
    BPP_MigratePlayerInfoToEnglish()
    BPP_MigrateKillKeys()
    BPP_MigrateLossKeys()
    BPP_MigrateArenaZones()
    BPP_InitializePlayerKillCounts()
    BPP_InitializeLeaderboardCache()
    BPP_InitializePlayerLossCounts()

    PVPSC.AchievementSystem:LoadAchievementCompletedData()
    BPP_ShowWeeklyRivalryDigestIfDue()

    BPP_UpdateMinimapButtonPosition()
    BPP_SetupMouseoverTooltip()
    BPP_InCombat = UnitAffectingCombat("player")
    BPP_CheckBattlegroundStatus()
    BPP_InitializeGrayKillsCounter()
    BPP_InitializeSpawnCamperCounter()

    if UnitIsDeadOrGhost("player") then
        BPP_HandlePlayerDeath()
    end

    if BPP_Debug then
        print("[BigPPvP]: Debug mode enabled.")
    end

    if not addonWelcomeMessageShown then
        addonWelcomeMessageShown = true
        print("[BigPPvP]: Click the minimap button or type /bpp to use the addon.")
    end

    local currentVersion = BPP_GetAddonVersion()
    if BPP_DB.WhatsNewPopupVersion ~= currentVersion then
        local title = "BigPPvP Stats v" .. currentVersion .. " - What's new:"
        local message = "-Fixed bug where the K/D of other players was incorrect when you view their detailed stats in the leaderboard\n\nEnjoy!"
        local dataImportGuideUrl = "https://github.com/randomdude163/WoWClassic_PvPStats/wiki/How-to-import-data-from-other-WoW-clients-(like-Classic-Era)"
        BPP_ShowWhatsNewPopup(title, message, function()
            BPP_DB.WhatsNewPopupShown = true
            BPP_DB.WhatsNewPopupVersion = currentVersion
        end, dataImportGuideUrl)
        -- Force migration of international data on first run after update
        BPP_MigratePlayerInfoToEnglish(true)
    end

    BPP_StartIncrementalAchievementsCalculation()

    -- Check for data import from legacy clients
    if BPP_CheckForDataMigration then
        C_Timer.After(2, function() BPP_CheckForDataMigration() end)
    end

    if BPP_ShowImportSummaryPopup then
        C_Timer.After(1.0, function() BPP_ShowImportSummaryPopup() end)
    end
end

local function HandlePlayerRegenEnabled()
    HandleCombatState(false)
    CleanupRecentPetDamage()
    BPP_CleanupRecentlyCountedKillsDict()
    BPP_CleanupRecentPlayerDamage()
    BPP_CleanupRecentDamageFromPlayers()
    BPP_CleanupPendingHunterKills()
    BPP_CleanupRecentlyCountedPriestKills()
    BPP_ClearGUIDCache()

    if PVPSC.Network and PVPSC.Network.pendingCombatBroadcast then
        PVPSC.Network:BroadcastStats()
    end
end

local function HandleNamePlateEvent(unit)
    BPP_GetAndStorePlayerInfoFromUnit(unit)
    BPP_UpdatePetOwnerFromUnit(unit)
end

function BPP_RegisterEvents()
    pvpStatsClassicFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    pvpStatsClassicFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    pvpStatsClassicFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    pvpStatsClassicFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_DEAD")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_LOGOUT")
    pvpStatsClassicFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    pvpStatsClassicFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_GUILD_UPDATE")

    pvpStatsClassicFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            HandlePlayerEnteringWorld()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unit = ...
            if unit then
                HandleNamePlateEvent(unit)
            end
        elseif event == "PLAYER_DEAD" then
            BPP_HandlePlayerDeath()
        elseif event == "PLAYER_REGEN_DISABLED" then
            HandleCombatState(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            HandlePlayerRegenEnabled()
        elseif event == "PLAYER_LOGOUT" then
            BPP_GetAndStorePlayerInfoFromUnit("player", true)
            BPP_CleanupPlayerInfoCache()
            BPP_CreateRollingBackupSnapshot()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            BPP_CheckBattlegroundStatus()
        elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
            -- Only broadcast stats on group/guild change if Network is initialized
            if PVPSC.Network and PVPSC.Network.initialized then
                PVPSC.Network:BroadcastStats()
            end
        end
    end)
end

function BPP_CheckBattlegroundStatus()
    if BPP_DB.ForceBattlegroundMode then
        if not BPP_lastInBattlegroundValue then
            print("[BigPPvP]: Forced battleground mode enabled.")
        end
        BPP_CurrentlyInBattleground = true
        BPP_lastInBattlegroundValue = true
        return
    end

    local currentMapId = C_Map.GetBestMapForUnit("player")

    local battlegroundZoneIds = {
        -- Correct IDs from here (all marked with patch 1.13.2:
        -- https://wowpedia.fandom.com/wiki/UiMapID
        -- "Alterac Valley"
        91,
        1537,
        2162,
        1459,

        -- "Warsong Gulch"
        1460,

        -- "Arathi Basin"
        1461,

        -- Eye of the Storm
        1956,

        -- 1433 -- Redridge Mountains
    }

    for _, bgMapId in ipairs(battlegroundZoneIds) do
        if (currentMapId == bgMapId) then
            if not BPP_lastInBattlegroundValue then
                local msg = "[BigPPvP]: Entered battleground. "
                if BPP_DB.CountKillsInBattlegrounds then
                    msg = msg .. "Only your own killing blows "
                    if BPP_DB.CountAssistsInBattlegrounds then
                        msg = msg .. "and assists "
                    end
                    msg = msg .. "will be counted, "
                else
                    msg = msg .. "No kills will be counted, "
                end
                if BPP_DB.CountDeathsInBattlegrounds then
                    msg = msg .. "deaths will be counted."
                else
                    msg = msg .. "no deaths will be counted."
                end
                print(msg)
            end
            BPP_CurrentlyInBattleground = true
            BPP_lastInBattlegroundValue = true
            return
        end
    end

    if BPP_lastInBattlegroundValue then
        print("[BigPPvP]: Left battleground.")
    end
    BPP_lastInBattlegroundValue = false
    BPP_CurrentlyInBattleground = false
end

function BPP_GetTotalsKillsForPlayer(playerName)
    if not playerName or playerName == "" then
        return 0
    end

    local normalizedName = BPP_GetInfoKeyFromName(playerName)
    local total_kills = 0
    for nameWithLevel, data in pairs(BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()].Kills) do
        local storedName = nameWithLevel:match("^(.+):")
        if storedName == normalizedName then
            total_kills = total_kills + data.kills
        end
    end

    if total_kills == 0 and not string.find(playerName, "%-") then
        local prefix = playerName .. "-"
        for nameWithLevel, data in pairs(BPP_DB.PlayerKillCounts.Characters[BPP_GetCharacterKey()].Kills) do
            local storedName = nameWithLevel:match("^(.+):")
            if storedName and string.sub(storedName, 1, #prefix) == prefix then
                total_kills = total_kills + data.kills
            end
        end
    end
    return total_kills
end

local tooltipHooksRegistered = false

function BPP_SetupMouseoverTooltip()
    if tooltipHooksRegistered then return end
    tooltipHooksRegistered = true

    local function GetLastKillTimestamp(playerName)
        local characterKey = BPP_GetCharacterKey()
        local lastKill = 0

        local normalizedName = BPP_GetInfoKeyFromName(playerName)
        local allowPrefixSearch = not string.find(playerName, "%-")
        local prefix = allowPrefixSearch and (playerName .. "-") or nil

        for nameWithLevel, data in pairs(BPP_DB.PlayerKillCounts.Characters[characterKey].Kills) do
            local storedName = nameWithLevel:match("^(.+):")
            if storedName then
                if storedName == normalizedName then
                    if data.lastKill and data.lastKill > lastKill then
                        lastKill = data.lastKill
                    end
                elseif allowPrefixSearch and string.sub(storedName, 1, #prefix) == prefix then
                    if data.lastKill and data.lastKill > lastKill then
                        lastKill = data.lastKill
                    end
                end
            end
        end

        return lastKill > 0 and lastKill or nil
    end

    local function GetDeathsByPlayerName(playerName)
        local characterKey = BPP_GetCharacterKey()
        if not BPP_DB.PvPLossCounts or not BPP_DB.PvPLossCounts[characterKey] or
           not BPP_DB.PvPLossCounts[characterKey].Deaths then
            return 0
        end

        local deathsTable = BPP_DB.PvPLossCounts[characterKey].Deaths
        local normalizedName = BPP_GetInfoKeyFromName(playerName)
        local totalDeaths = 0
        local found = false

        if deathsTable[normalizedName] then
            totalDeaths = totalDeaths + (deathsTable[normalizedName].deaths or 0)
            found = true
        end

        -- Check the raw name as well (for same realm players where realm is omitted in storage)
        -- Only add if it's different from normalized name (e.g. "Bob" vs "Bob-MyRealm")
        if playerName ~= normalizedName and deathsTable[playerName] then
            totalDeaths = totalDeaths + (deathsTable[playerName].deaths or 0)
            found = true
        end

        if found then
            return totalDeaths
        end

        if not string.find(playerName, "%-") then
            local prefix = playerName .. "-"
            local totalDeaths = 0
            for storedName, deathData in pairs(deathsTable) do
                if storedName and string.sub(storedName, 1, #prefix) == prefix then
                    totalDeaths = totalDeaths + (deathData.deaths or 0)
                end
            end
            return totalDeaths
        end

        return 0
    end

    local function AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
        if tooltip.pvpStatsAdded then return end

        local lastKill = GetLastKillTimestamp(playerName)
        local scoreText = ""

        if not BPP_DB.ShowExtendedTooltipInfo then
            scoreText = "Kills: " .. kills
        else
            scoreText = "Score " .. kills .. ":" .. deaths

            if kills > 0 then
                local lastKillTimespan = BPP_FormatLastKillTimespan(lastKill)
                if lastKillTimespan then
                    scoreText = scoreText .. " - Last kill " .. lastKillTimespan .. " ago"
                end
            end
        end

        tooltip:AddLine(scoreText, 1, 1, 1)
        tooltip.pvpStatsAdded = true
        tooltip:Show()
    end

    local function OnTooltipSetUnit(tooltip)
        if not BPP_DB.ShowScoreInPlayerTooltip then return end

        local _, unit = tooltip:GetUnit()
        if not unit then return end

        if not UnitIsPlayer(unit) or UnitIsFriend("player", unit) then return end

        local name, realm = UnitName(unit)
        local playerName = name
        if realm then
            playerName = name .. "-" .. realm
        end

        local kills = BPP_GetTotalsKillsForPlayer(playerName)
        local deaths = GetDeathsByPlayerName(playerName)
        AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
    end

    local function OnTooltipShow(tooltip)
        if not BPP_DB.ShowScoreInPlayerTooltip then return end
        if not tooltip:IsShown() then return end

        local line1 = _G[tooltip:GetName() .. "TextLeft1"]
        if not line1 then return end

        local text = line1:GetText()
        if not text or not text:find("^Corpse of ") then return end

        local playerName = text:match("^Corpse of (.+)$")
        if not playerName then return end

        local kills = BPP_GetTotalsKillsForPlayer(playerName)
        local deaths = GetDeathsByPlayerName(playerName)
        if kills == nil or deaths == nil then return end
        if kills == 0 and deaths == 0 then return end
        AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
    end

    GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    GameTooltip:HookScript("OnShow", OnTooltipShow)

    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip.pvpStatsAdded = nil
        C_Timer.After(0.01, function()
            if tooltip:IsShown() then
                OnTooltipShow(tooltip)
            end
        end)
    end)
end
