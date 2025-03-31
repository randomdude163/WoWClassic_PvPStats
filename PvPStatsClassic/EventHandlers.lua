local pvpStatsClassicFrame = CreateFrame("Frame", "PvpStatsClassicFrame", UIParent)

PSC_Debug = true
PSC_PlayerGUID = ""
PSC_CharacterName = ""
PSC_RealmName = ""

RecentPetDamage = {}
local PET_DAMAGE_WINDOW = 0.05

PSC_InCombat = false

PSC_LastDeathTime = 0
PSC_DEATH_EVENT_COOLDOWN = 2 -- seconds to ignore duplicate death events

PSC_CurrentlyInBattleground = false
PSC_lastInBattlegroundValue = false

PSC_PendingHunterEvents = {}
local HUNTER_VERIFICATION_WINDOW = 3.0 -- Seconds to wait before confirming
local HUNTER_ABILITY_MIN_LEVEL = 30 -- Hunters learn this ability at level 30

local function OnPlayerTargetChanged()
    PSC_GetAndStorePlayerInfoFromUnit("target")
    PSC_GetAndStorePlayerInfoFromUnit("targettarget")
    PSC_UpdatePetOwnerFromUnit("target")

    if UnitExists("targettarget") then
        PSC_UpdatePetOwnerFromUnit("targettarget")
    end
end

local function OnUpdateMouseoverUnit()
    PSC_GetAndStorePlayerInfoFromUnit("mouseover")
    PSC_UpdatePetOwnerFromUnit("mouseover")
end

local function HandleCombatState(inCombatNow)
    if PSC_InCombat and not inCombatNow then
        PSC_MultiKillCount = 0
        PSC_InCombat = false
    elseif not PSC_InCombat and inCombatNow then
        PSC_MultiKillCount = 0
        PSC_InCombat = true
    end
end

local function SendWarningIfKilledByHighLevelPlayer(killerInfo)
    local killerName = killerInfo.killer.name

    local infoKey = PSC_GetInfoKeyFromName(killerName)

    if not PSC_DB.PlayerInfoCache[infoKey] then
        if PSC_Debug then
            print("Warning: Killer " .. killerName .. " not found in player info cache")
        end
        return
    end

    local killerLevel = PSC_DB.PlayerInfoCache[infoKey].level
    local killerClass = PSC_DB.PlayerInfoCache[infoKey].class

    if killerLevel ~= -1 then
        return
    end

    if not IsInGroup() then
        return
    end

    local playerX, playerY = PSC_GetPlayerCoordinates()
    local playerCoords = string.format("%.1f, %.1f", playerX, playerY)
    local subZoneText = GetSubZoneText()
    local playerPosition = ""
    if subZoneText ~= "" then
        playerPosition =  subZoneText .. " (" .. playerCoords .. ")"
    else
        playerPosition =  playerCoords
    end
    local warningMsg = "I got killed by " .. killerName .. " (Level ?? " .. killerClass .. ") at " .. playerPosition .. "!"
    SendChatMessage(warningMsg, "PARTY")
end

function HandlePlayerDeath()
    local now = GetTime()
    if (now - PSC_LastDeathTime) < PSC_DEATH_EVENT_COOLDOWN then
        if PSC_Debug then
            print("Ignoring duplicate PLAYER_DEAD event")
        end
        return
    end

    PSC_LastDeathTime = now

    local characterKey = PSC_GetCharacterKey()
    local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]

    if characterData.CurrentKillStreak >= 10 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
        local streakEndedMsg = string.gsub(PSC_DB.KillStreakEndedMessage, "STREAKCOUNT", characterData.CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    characterData.CurrentKillStreak = 0
    PSC_MultiKillCount = 0
    PSC_InCombat = false

    print("[PvPStats]: You died, kill streak reset.")

    if PSC_CurrentlyInBattleground and not PSC_DB.CountDeathsInBattlegrounds then
        if PSC_Debug then print("BG Mode: Death tracking disabled in battlegrounds") end
        return
    end

    local killerInfo = PSC_GetKillerInfoOnDeath()
    if killerInfo then
        if not PSC_CurrentlyInBattleground then
            SendWarningIfKilledByHighLevelPlayer(killerInfo)
        end
        PSC_RegisterPlayerDeath(killerInfo)
    end
end

local function CleanupRecentPetDamage()
    local now = GetTime()
    local cutoff = now - PET_DAMAGE_WINDOW

    for guid, info in pairs(RecentPetDamage) do
        if info.timestamp < cutoff then
            RecentPetDamage[guid] = nil
        end
    end
end

function CombatLogDestFlagsEnemyPlayer(destFlags)
    return bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and
           bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end

local function HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, param1, param4)
    if sourceGUID ~= PSC_PlayerGUID then return end

    local damageAmount = param1 or param4 or 0
    if damageAmount <= 0 then return end

     PSC_RecordPlayerDamage(sourceGUID, sourceName, destGUID, destName, damageAmount)
end

local function HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)
    if sourceGUID ~= PSC_PlayerGUID then return end

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

function PSC_IsSpecialHunterCase(destName)
    local infoKey = PSC_GetInfoKeyFromName(destName)
    if not PSC_DB.PlayerInfoCache[infoKey] then
        return false
    end

    local isHunter = PSC_DB.PlayerInfoCache[infoKey].class == "Hunter"
    local level = PSC_DB.PlayerInfoCache[infoKey].level

    if not isHunter or level < HUNTER_ABILITY_MIN_LEVEL then
        return false
    end

    return true
end

function PSC_ScheduleHunterValidation(destGUID, destName, eventType, validationData)
    if not PSC_IsSpecialHunterCase(destName) then
        return false
    end

    if PSC_Debug then
        print("Hunter " .. destName .. " might be using their special ability - validating...")
    end

    PSC_PendingHunterEvents[destGUID] = {
        name = destName,
        timestamp = GetTime(),
        eventType = eventType,
        gotDamagedAfter = false,
        validationData = validationData
    }

    C_Timer.After(HUNTER_VERIFICATION_WINDOW, function()
        PSC_ValidateHunterEvent(destGUID)
    end)

    return true
end

local function HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    if PSC_CurrentlyInBattleground and not PSC_DB.CountKillsInBattlegrounds then
        if PSC_Debug then print("BG Mode: Kill tracking disabled in battlegrounds") end
        return
    end

    local countKill = false

    if PSC_CurrentlyInBattleground then
        if sourceGUID == PSC_PlayerGUID then
            countKill = true
            if PSC_Debug then print("BG Mode: Player killing blow") end
        else
            if PSC_Debug then print("BG Mode: Party/Raid member killing blow ignored") end
        end
    else
        if sourceGUID == PSC_PlayerGUID then
            countKill = true
            if PSC_Debug then print("Normal Mode: Player killing blow") end
        elseif UnitInParty(sourceName) or UnitInRaid(sourceName) then
            countKill = true
            if PSC_Debug then print("Normal Mode: Party/Raid member killing blow") end
        end
    end

    if countKill then
        PSC_RecentlyCountedKills[destGUID] = GetTime()
        PSC_RegisterPlayerKill(destName, sourceName, sourceGUID)
    end
end

local function HandleUnitDiedEvent(destGUID, destName)
    if PSC_RecentlyCountedKills[destGUID] then
        return
    end

    if PSC_CurrentlyInBattleground and not PSC_DB.CountKillsInBattlegrounds then
        return
    end

    local countKill = false
    local petDamage = RecentPetDamage[destGUID]

    if petDamage and (GetTime() - petDamage.timestamp) <= PET_DAMAGE_WINDOW then
        if PSC_CurrentlyInBattleground then
            if petDamage.ownerGUID == PSC_PlayerGUID then
                countKill = true
                if PSC_Debug then
                    print("BG Mode: Pet killing blow detected (via recent damage)")
                    print("Pet: " .. (petDamage.petName or "Unknown"))
                end
            else
                if PSC_Debug then print("BG Mode: Pet killing blow ignored (not your pet)") end
            end
        else
            if petDamage.ownerGUID == PSC_PlayerGUID then
                countKill = true
                if PSC_Debug then
                    print("Normal Mode: Your pet killing blow detected")
                end
            else
                local ownerName = GetNameFromGUID(petDamage.ownerGUID)
                if ownerName and (UnitInParty(ownerName) or UnitInRaid(ownerName)) then
                    countKill = true
                    if PSC_Debug then
                        print("Normal Mode: Party/raid member's pet kill detected")
                    end
                end
            end
        end

        if countKill then
            PSC_RecentlyCountedKills[destGUID] = GetTime()
            PSC_RegisterPlayerKill(destName, petDamage.petName, petDamage.petGUID)
            RecentPetDamage[destGUID] = nil
            return
        end
    end

    local playerDamage = PSC_RecentPlayerDamage[destGUID]
    if playerDamage and (GetTime() - playerDamage.timestamp) <= PSC_ASSIST_DAMAGE_WINDOW then
        if playerDamage.totalDamage > 0 then
            if PSC_CurrentlyInBattleground and not PSC_DB.CountAssistsInBattlegrounds then
                if PSC_Debug then
                    print("BG Mode: Assist kill ignored (assists disabled in BGs)")
                end
                return
            end

            if PSC_Debug then
                print("Assist kill detected for: " .. destName)
            end

            PSC_RecentlyCountedKills[destGUID] = GetTime()
            PSC_RegisterPlayerKill(destName, "Assist", nil)
            PSC_RecentPlayerDamage[destGUID] = nil
        end
    end
end

local function HandleComatLogEventPetDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, param1, param4)
    if IsPetGUID(sourceGUID) and destGUID then
        local damageAmount = 0

        if combatEvent == "SWING_DAMAGE" then
            damageAmount = param1 or 0
        elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
            damageAmount = param4 or 0
        elseif combatEvent == "RANGE_DAMAGE" then
            damageAmount = param4 or 0
        end

        if damageAmount > 0 then
            PSC_RecordPetDamage(sourceGUID, sourceName, destGUID, damageAmount)
        end
    end
end

function PSC_ValidateHunterEvent(destGUID)
    local eventData = PSC_PendingHunterEvents[destGUID]
    if not eventData then return end

    -- If hunter received damage after the "pretend" event, ignore it
    if eventData.gotDamagedAfter then
        if PSC_Debug then
            print("Validation: Hunter " .. eventData.name ..
                  " received damage after event - ignoring as likely special ability")
        end

        PSC_PendingHunterEvents[destGUID] = nil
        return
    end

    -- No damage received during validation window, process as a real event
    if PSC_Debug then
        print("Validation: Hunter " .. eventData.name ..
              " received no damage after event - processing as normal")
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
    PSC_PendingHunterEvents[destGUID] = nil
end

local function HandleCombatLogEvent()
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5, param6, param7, param8 = CombatLogGetCurrentEventInfo()

    if destGUID and PSC_PendingHunterEvents[destGUID] and
       (combatEvent == "SWING_DAMAGE" or
        combatEvent == "SPELL_DAMAGE" or
        combatEvent == "SPELL_PERIODIC_DAMAGE" or
        combatEvent == "RANGE_DAMAGE") then
        PSC_PendingHunterEvents[destGUID].gotDamagedAfter = true

        if PSC_Debug then
            print("Hunter " .. destName .. " received damage after event - likely using special ability")
        end
    end

    if CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandleComatLogEventPetDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, param1, param4)
        HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)
    end

    if destGUID == PSC_PlayerGUID then
        if sourceGUID == PSC_PlayerGUID then return end

        if bit.band(sourceFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
            local spellId, spellName
            if combatEvent == "SWING_DAMAGE" then
                spellId = 0
                spellName = "Melee"
            else
                spellId = param1
                spellName = param2
            end

            PSC_HandleReceivedPlayerDamage(combatEvent, sourceGUID, sourceName, spellId, spellName, param1, param4)
        elseif IsPetGUID(sourceGUID) then
            PSC_HandleReceivedPlayerDamageByEnemyPets(combatEvent, sourceGUID, sourceName, param1, param4)
        end
    end

    if combatEvent == "PARTY_KILL" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        local isScheduled = PSC_ScheduleHunterValidation(destGUID, destName, "PARTY_KILL", {
            sourceGUID = sourceGUID,
            sourceName = sourceName
        })

        if not isScheduled then
            HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
        end
    end

    if combatEvent == "UNIT_DIED" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        local isScheduled = PSC_ScheduleHunterValidation(destGUID, destName, "UNIT_EVENT", {})

        if not isScheduled then
            HandleUnitDiedEvent(destGUID, destName)
        end
    end
end

function PSC_CleanupPendingHunterEvents()
    local now = GetTime()
    local cutoff = now - (HUNTER_VERIFICATION_WINDOW * 2)

    for guid, data in pairs(PSC_PendingHunterEvents) do
        if data.timestamp < cutoff then
            PSC_PendingHunterEvents[guid] = nil
        end
    end
end

function PSC_RegisterEvents()
    pvpStatsClassicFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    pvpStatsClassicFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    pvpStatsClassicFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_DEAD")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    pvpStatsClassicFrame:RegisterEvent("PLAYER_LOGOUT")
    pvpStatsClassicFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    pvpStatsClassicFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            PSC_PlayerGUID = UnitGUID("player")
            PSC_CharacterName = UnitName("player")
            PSC_RealmName = GetRealmName()

            if not PSC_DB then
                PSC_DB = {}
                PSC_LoadDefaultSettings()
                ResetAllStatsToDefault()
            end

            PSC_MigratePlayerInfoCache()

            PSC_InitializePlayerKillCounts()
            PSC_InitializePlayerLossCounts()
            PSC_UpdateMinimapButtonPosition()
            PSC_SetupMouseoverTooltip()
            PSC_InCombat = UnitAffectingCombat("player")
            PSC_CheckBattlegroundStatus()
            if UnitIsDeadOrGhost("player") then
                HandlePlayerDeath()
            end
            if PSC_Debug then
                print("[PvPStats]: Debug mode enabled.")
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        elseif event == "PLAYER_DEAD" then
            HandlePlayerDeath()
        elseif event == "PLAYER_REGEN_DISABLED" then
            HandleCombatState(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            HandleCombatState(false)
            CleanupRecentPetDamage()
            PSC_CleanupRecentlyCountedKillsDict()
            PSC_CleanupRecentPlayerDamage()
            PSC_CleanupRecentDamageFromPlayers()
            PSC_CleanupPendingHunterEvents()
        elseif event == "PLAYER_LOGOUT" then
            PSC_CleanupPlayerInfoCache()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            PSC_CheckBattlegroundStatus()
        end
    end)
end

function PSC_CheckBattlegroundStatus()
    if PSC_DB.ForceBattlegroundMode then
        if not PSC_lastInBattlegroundValue then
            print("[PvPStats]: Forced battleground mode enabled.")
        end
        PSC_CurrentlyInBattleground = true
        PSC_lastInBattlegroundValue = true
        return
    end

    local currentMapId = C_Map.GetBestMapForUnit("player")

    local battlegroundZoneIds = {
        -- Correct IDs from here (all marked with patch 1.13.2:
        -- https://wowpedia.fandom.com/wiki/UiMapID
        1459, -- "Alterac Valley"
        1460, -- "Warsong Gulch"
        1461 -- "Arathi Basin"
    }

    for _, bgMapId in ipairs(battlegroundZoneIds) do
        if (currentMapId == bgMapId) then
            if not PSC_lastInBattlegroundValue then
                local msg = "[PvPStats]: Entered battleground. "
                -- if PSC_DB.CountKillsInBattlegrounds then
                --     msg = msg .. "Only your own killing blows "
                --     if PSC_DB.CountAssistsInBattlegrounds then
                --         msg = msg .. "and assists "
                --     end
                --     msg = msg .. "will be counted, "
                -- else
                --     msg = msg .. "No kills will be counted, "
                -- end
                -- if PSC_DB.CountDeathsInBattlegrounds then
                --     msg = msg .. "deaths will be counted."
                -- else
                --     msg = msg .. "no deaths will be counted."
                -- end
                print(msg)
            end
            PSC_CurrentlyInBattleground = true
            PSC_lastInBattlegroundValue = true
            return
        end
    end

    if PSC_lastInBattlegroundValue then
        print("[PvPStats]: Left battleground.")
    end
    PSC_lastInBattlegroundValue = false
    PSC_CurrentlyInBattleground = false
end

function PSC_GetTotalsKillsForPlayer(playerName)
    local total_kills = 0
    for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts.Characters[PSC_GetCharacterKey()].Kills) do
        local storedName = nameWithLevel:match("^(.+):")
        if storedName == playerName then
            total_kills = total_kills + data.kills
        end
    end
    return total_kills
end

function PSC_SetupMouseoverTooltip()
    local function GetLastKillTimestamp(playerName)
        local characterKey = PSC_GetCharacterKey()
        local lastKill = 0

        for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts.Characters[characterKey].Kills) do
            local storedName = nameWithLevel:match("^(.+):")
            if storedName == playerName and data.lastKill and data.lastKill > lastKill then
                lastKill = data.lastKill
            end
        end

        return lastKill > 0 and lastKill or nil
    end

    local function GetDeathsByPlayerName(playerName)
        local characterKey = PSC_GetCharacterKey()
        if not PSC_DB.PvPLossCounts or not PSC_DB.PvPLossCounts[characterKey] or
           not PSC_DB.PvPLossCounts[characterKey].Deaths or not PSC_DB.PvPLossCounts[characterKey].Deaths[playerName] then
            return 0
        end

        return PSC_DB.PvPLossCounts[characterKey].Deaths[playerName].deaths or 0
    end

    local function AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
        if tooltip.pvpStatsAdded then return end

        local lastKill = GetLastKillTimestamp(playerName)
        local scoreText = ""

        if not PSC_DB.ShowExtendedTooltipInfo then
            scoreText = "Kills: " .. kills
        else
            scoreText = "Score " .. kills .. ":" .. deaths

            if kills > 0 then
                local lastKillTimespan = PSC_FormatLastKillTimespan(lastKill)
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
        if not PSC_DB.ShowScoreInPlayerTooltip then return end

        local _, unit = tooltip:GetUnit()
        if not unit then return end

        if not UnitIsPlayer(unit) or UnitIsFriend("player", unit) then return end

        local playerName = UnitName(unit)
        local kills = PSC_GetTotalsKillsForPlayer(playerName)
        local deaths = GetDeathsByPlayerName(playerName)
        AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
    end

    local function OnTooltipShow(tooltip)
        if not PSC_DB.ShowScoreInPlayerTooltip then return end
        if not tooltip:IsShown() then return end

        local line1 = _G[tooltip:GetName().."TextLeft1"]
        if not line1 then return end

        local text = line1:GetText()
        if not text or not text:find("^Corpse of ") then return end

        local playerName = text:match("^Corpse of (.+)$")
        if not playerName then return end

        local kills = PSC_GetTotalsKillsForPlayer(playerName)
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
