local pvpStatsClassicFrame = CreateFrame("Frame", "PvpStatsClassicFrame", UIParent)

PSC_Debug = true
PSC_PlayerGUID = ""
PSC_CharacterName = ""
PSC_RealmName = ""

RecentPetDamage = {}
local PET_DAMAGE_WINDOW = 0.05

PSC_InCombat = false

-- Add this variable to track the last death time
PSC_LastDeathTime = 0
PSC_DEATH_EVENT_COOLDOWN = 2 -- seconds to ignore duplicate death events

PSC_CurrentlyInBattleground = false
PSC_lastInBattlegroundValue = false


local function OnPlayerTargetChanged()
    PSC_GetAndStorePlayerInfoFromUnit("target")
    PSC_GetAndStorePlayerInfoFromUnit("targettarget")

    -- Check for pet owner information
    PSC_UpdatePetOwnerFromUnit("target")

    -- Also check targettarget for pet owner info
    if UnitExists("targettarget") then
        PSC_UpdatePetOwnerFromUnit("targettarget")
    end
end

local function OnUpdateMouseoverUnit()
    PSC_GetAndStorePlayerInfoFromUnit("mouseover")

    -- Check for pet owner information
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

    if not PSC_DB.PlayerInfoCache[killerName] then
        if PSC_Debug then
            print("Warning: Killer " .. killerName .. " not found in player info cache")
        end
        return
    end

    local killerLevel = PSC_DB.PlayerInfoCache[killerName].level
    local killerClass = PSC_DB.PlayerInfoCache[killerName].class

    if killerLevel ~= -1 then
        if PSC_Debug then
            print("Not sending warning for " .. killerName .. ", level " .. killerLevel .. " (not ??)")
        end
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
    -- Check if this is a duplicate death event within the cooldown period
    local now = GetTime()
    if (now - PSC_LastDeathTime) < PSC_DEATH_EVENT_COOLDOWN then
        if PSC_Debug then
            print("Ignoring duplicate PLAYER_DEAD event")
        end
        return
    end

    -- Update the last death time
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
    -- return true
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
        damageAmount = 1  -- Treat utility spells as minimal damage for assist tracking
    end

    if damageAmount > 0 or isUtilitySpell then
        HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, damageAmount, nil)

        -- if isUtilitySpell and PSC_Debug then
        --     print("Utility spell (" .. combatEvent .. ") on " .. destName .. " counted for assist credit")
        -- end
    end
end

local function HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    local countKill = false

    if PSC_CurrentlyInBattleground and not PSC_DB.CountKillsInBattlegrounds then
        if PSC_Debug then print("BG Mode: Kill tracking disabled in battlegrounds") end
        return
    end

    -- print("Party Kill Event: " .. sourceName .. " (" .. sourceGUID .. ") killed " .. destName .. " (" .. destGUID .. ")")
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
        -- if PSC_Debug then
        --     print("Skipping duplicate kill for: " .. destName)
        -- end
        return
    end

    if PSC_CurrentlyInBattleground and not PSC_DB.CountKillsInBattlegrounds then
        return
    end

    local countKill = false

    local petDamage = RecentPetDamage[destGUID]

    if petDamage and (GetTime() - petDamage.timestamp) <= PET_DAMAGE_WINDOW then
        -- In BG mode, only count the player's own pet kills
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
        -- In normal mode, also accept party/raid member pets
        else
            if petDamage.ownerGUID == PSC_PlayerGUID then
                countKill = true
                if PSC_Debug then
                    print("Normal Mode: Your pet killing blow detected")
                end
            else
                -- Check if owner is in party/raid
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

    -- If not a pet kill, check for assist kill
    local playerDamage = PSC_RecentPlayerDamage[destGUID]
    if playerDamage and (GetTime() - playerDamage.timestamp) <= PSC_ASSIST_DAMAGE_WINDOW then
        if playerDamage.totalDamage > 0 then
            -- In BG mode, only count assists if the setting is enabled
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

local function HandleCombatLogEvent()
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4, param5, param6, param7, param8 = CombatLogGetCurrentEventInfo()

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
            -- Handle pet damage
            if PSC_Debug then
                print("Pet damage event from " .. (sourceName) .. ": " .. combatEvent)
            end
            PSC_HandleReceivedPlayerDamageByEnemyPets(combatEvent, sourceGUID, sourceName, param1, param4)
        end
    end

    if combatEvent == "PARTY_KILL" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    end

    if combatEvent == "UNIT_DIED" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandleUnitDiedEvent(destGUID, destName)
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
            PSC_InitializePlayerKillCounts()
            PSC_InitializePlayerLossCounts()
            PSC_UpdateMinimapButtonPosition()
            PSC_SetupMouseoverTooltip()
            PSC_InCombat = UnitAffectingCombat("player")
            PSC_CheckBattlegroundStatus()  -- Check BG status on login/reload
            if UnitIsDeadOrGhost("player") then
                HandlePlayerDeath()
            end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        elseif event == "PLAYER_DEAD" then
            if PSC_Debug then
                print("PLAYER_DEAD event received")
            end
            HandlePlayerDeath()
        elseif event == "PLAYER_REGEN_DISABLED" then
            HandleCombatState(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            HandleCombatState(false)
            CleanupRecentPetDamage()
            PSC_CleanupRecentlyCountedKillsDict()
            PSC_CleanupRecentPlayerDamage()
            PSC_CleanupRecentDamageFromPlayers()
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

    local currentZone = GetRealZoneText() or ""
    local battlegroundZones = {
        "Warsong Gulch",
        "Arathi Basin",
        "Alterac Valley",
        -- "Elwynn Forest",
        -- "Duskwood"
    }

    for _, bgName in ipairs(battlegroundZones) do
        if (currentZone == bgName) then
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

        -- Find the most recent kill timestamp for this player (across different level entries)
        for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts.Characters[characterKey].Kills) do
            local storedName = nameWithLevel:match("^(.+):")
            if storedName == playerName and data.lastKill and data.lastKill > lastKill then
                lastKill = data.lastKill
            end
        end

        return lastKill > 0 and lastKill or nil
    end

    local function FormatLastKillTimespan(lastKillTimestamp)
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

    local function GetDeathsByPlayerName(playerName)
        local characterKey = PSC_GetCharacterKey()
        if not PSC_DB.PvPLossCounts or not PSC_DB.PvPLossCounts[characterKey] or
           not PSC_DB.PvPLossCounts[characterKey].Deaths or not PSC_DB.PvPLossCounts[characterKey].Deaths[playerName] then
            return 0
        end

        return PSC_DB.PvPLossCounts[characterKey].Deaths[playerName].deaths or 0
    end

    local function AddPvPInfoToTooltip(tooltip, playerName, kills, deaths)
        -- Check if we've already added PvP info to this tooltip
        if tooltip.pvpStatsAdded then return end

        local lastKill = GetLastKillTimestamp(playerName)
        local scoreText = ""

        -- Basic format just shows kills
        if not PSC_DB.ShowExtendedTooltipInfo then
            scoreText = "Kills: " .. kills
        else
            -- Extended format shows kills:deaths ratio and time since last kill
            scoreText = "Score " .. kills .. ":" .. deaths

            if kills > 0 then
                local lastKillTimespan = FormatLastKillTimespan(lastKill)
                if lastKillTimespan then
                    scoreText = scoreText .. " - Last kill " .. lastKillTimespan .. " ago"
                end
            end
        end

        tooltip:AddLine(scoreText, 1, 1, 1)
        tooltip.pvpStatsAdded = true
        tooltip:Show() -- Force refresh to show the new line
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

    -- The OnTooltipCleared event might fire too early, so we also use a small timer
    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        tooltip.pvpStatsAdded = nil  -- Reset the flag when tooltip is cleared
        C_Timer.After(0.01, function()
            if tooltip:IsShown() then
                OnTooltipShow(tooltip)
            end
        end)
    end)
end
