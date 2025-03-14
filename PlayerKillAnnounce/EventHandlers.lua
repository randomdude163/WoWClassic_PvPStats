-- PlayerKillAnnounce EventHandlers.lua
-- Tracks and announces player kills with streak tracking and statistics
local PlayerKillMessageDefault = "Enemyplayername killed!"
local KillStreakEndedMessageDefault = "My kill streak of STREAKCOUNT has ended!"
local NewStreakRecordMessageDefault = "NEW PERSONAL BEST: Kill streak of STREAKCOUNT!"
local NewMultiKillRecordMessageDefault = "NEW PERSONAL BEST: Multi-kill of MULTIKILLCOUNT!"
------------------------------------------------------------------------

local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
PKA_EnableKillAnnounce = true
PKA_KillAnnounceMessage = PlayerKillMessageDefault
PKA_KillCounts = {}
PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault
PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault
PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault
PKA_CurrentKillStreak = 0
PKA_HighestKillStreak = 0
PKA_MultiKillCount = 0
PKA_HighestMultiKill = 0
PKA_LastCombatTime = 0
PKA_EnableRecordAnnounce = true
PKA_MultiKillThreshold = 3
PKA_MILESTONE_STREAKS = {25, 50, 75, 100, 150, 200, 250, 300}
PKA_AutoBattlegroundMode = true  -- Auto-detect BGs
PKA_BattlegroundMode = false     -- Manual override for BG mode
PKA_InBattleground = false       -- Current BG state

local PKA_CHAT_MESSAGE_R = 1.0
local PKA_CHAT_MESSAGE_G = 1.0
local PKA_CHAT_MESSAGE_B = 0.74

-- State tracking variables
local inCombat = false
local killStreakMilestoneFrame = nil
PKA_Debug = false  -- Debug mode for extra messages

local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka config - Open configuration UI", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka stats - Show kills list", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status - Show current settings", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka debug - Show current streak values", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka registerkill [number] - Register test kill(s) for testing", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka death - Simulate player death (resets kill streak)", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka bgmode - Toggle battleground mode manually", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka toggledebug - Toggle debug messages", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (PKA_EnableKillAnnounce and "ENABLED" or "DISABLED") .. "."
    DEFAULT_CHAT_FRAME:AddMessage(statusMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current kill announce message: " .. PKA_KillAnnounceMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Streak ended message: " .. PKA_KillStreakEndedMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("New streak record message: " .. PKA_NewStreakRecordMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("New multi-kill record message: " .. PKA_NewMultiKillRecordMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Multi-kill announcement threshold: " .. PKA_MultiKillThreshold, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Record announcements: " .. (PKA_EnableRecordAnnounce and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Battleground Mode: " .. (PKA_InBattleground and "ACTIVE" or "INACTIVE"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Auto BG Detection: " .. (PKA_AutoBattlegroundMode and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Manual BG Mode: " .. (PKA_BattlegroundMode and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function ShowDebugInfo()
    DEFAULT_CHAT_FRAME:AddMessage("Current Kill Streak: " .. PKA_CurrentKillStreak, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Highest Kill Streak: " .. PKA_HighestKillStreak, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current Multi-kill Count: " .. PKA_MultiKillCount, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Highest Multi-kill: " .. PKA_HighestMultiKill, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Multi-kill Announcement Threshold: " .. PKA_MultiKillThreshold, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Battleground Mode: " .. (PKA_InBattleground and "ACTIVE" or "INACTIVE"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Auto BG Detection: " .. (PKA_AutoBattlegroundMode and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Manual BG Mode: " .. (PKA_BattlegroundMode and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function InitializeCacheForPlayer(nameWithLevel, englishClass, race, gender, guild, playerLevel)
    if not PKA_KillCounts[nameWithLevel] then
        local currentZone = GetRealZoneText() or GetSubZoneText() or "Unknown"

        PKA_KillCounts[nameWithLevel] = {
            kills = 0,
            class = englishClass or "Unknown",
            race = race or "Unknown",
            gender = gender or 1,
            guild = guild or "Unknown",
            lastKill = "",
            playerLevel = playerLevel or -1,
            unknownLevel = false,
            zone = currentZone
        }
    end
end

local function UpdateKillCacheEntry(nameWithLevel, race, gender, guild, playerLevel, isUnknownLevel)
    PKA_KillCounts[nameWithLevel].kills = PKA_KillCounts[nameWithLevel].kills + 1
    PKA_KillCounts[nameWithLevel].lastKill = date("%Y-%m-%d %H:%M:%S")
    PKA_KillCounts[nameWithLevel].playerLevel = playerLevel or -1

    local currentZone = GetRealZoneText() or GetSubZoneText() or "Unknown"
    PKA_KillCounts[nameWithLevel].zone = currentZone

    -- Update additional info if available
    if race and race ~= "Unknown" then PKA_KillCounts[nameWithLevel].race = race end
    if gender and gender ~= "Unknown" then PKA_KillCounts[nameWithLevel].gender = gender end
    if guild and guild ~= "" then PKA_KillCounts[nameWithLevel].guild = guild end
    PKA_KillCounts[nameWithLevel].unknownLevel = isUnknownLevel or false
end

local function UpdateKillStreak()
    PKA_CurrentKillStreak = PKA_CurrentKillStreak + 1

    if PKA_CurrentKillStreak > PKA_HighestKillStreak then
        PKA_HighestKillStreak = PKA_CurrentKillStreak

        if PKA_HighestKillStreak > 1 then
            print("NEW KILL STREAK RECORD: " .. PKA_HighestKillStreak .. "!")

            if PKA_HighestKillStreak >= 10 and PKA_HighestKillStreak % 5 == 0 and PKA_EnableRecordAnnounce and IsInGroup() then
                local newRecordMsg = string.gsub(PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault, "STREAKCOUNT", PKA_HighestKillStreak)
                SendChatMessage(newRecordMsg, "PARTY")
            end

            if PKA_UpdateConfigStats then
                PKA_UpdateConfigStats()
            end
        end
    end
end

local function UpdateMultiKill()
    if UnitAffectingCombat("player") then
        if not inCombat then
            inCombat = true
        end

        PKA_MultiKillCount = PKA_MultiKillCount + 1
    else
        PKA_MultiKillCount = 1
        inCombat = false
    end

    if PKA_MultiKillCount > PKA_HighestMultiKill then
        PKA_HighestMultiKill = PKA_MultiKillCount

        if PKA_HighestMultiKill > 1 then
            print("NEW MULTI-KILL RECORD: " .. PKA_HighestMultiKill .. "!")

            if PKA_HighestMultiKill >= 3 and PKA_EnableRecordAnnounce and IsInGroup() then
                local newMultiKillMsg = string.gsub(PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault, "MULTIKILLCOUNT", PKA_HighestMultiKill)
                SendChatMessage(newMultiKillMsg, "PARTY")
            end

            if PKA_UpdateConfigStats then
                PKA_UpdateConfigStats()
            end
        end
    end
end

local function GetMultiKillText(count)
    if count < 2 then return "" end

    local killTexts = {
        "DOUBLE KILL!",
        "TRIPLE KILL!",
        "QUADRA KILL!",
        "PENTA KILL!",
        "HEXA KILL!",
        "HEPTA KILL!",
        "OCTA KILL!",
        "NONA KILL!"
    }

    if count <= 9 then
        return killTexts[count - 1]
    else
        return "DECA KILL!"
    end
end

local function AnnounceKill(killedPlayer, level, nameWithLevel)
    -- Don't announce in battleground mode or if announcements are disabled
    if PKA_InBattleground or not PKA_EnableKillAnnounce or not IsInGroup() then return end

    local killMessage = PKA_KillAnnounceMessage and string.gsub(PKA_KillAnnounceMessage, "Enemyplayername", killedPlayer) or
                        string.gsub(PlayerKillMessageDefault, "Enemyplayername", killedPlayer)

    local playerLevel = UnitLevel("player")
    local levelDifference = level - playerLevel
    local levelDisplay = level == -1 and "??" or tostring(level)

    if level == -1 or (level > 0 and levelDifference >= 5) then
        killMessage = killMessage .. " (Level " .. levelDisplay .. ")"
    end

    killMessage = killMessage .. " x" .. PKA_KillCounts[nameWithLevel].kills

    if PKA_CurrentKillStreak >= 10 and PKA_CurrentKillStreak % 5 == 0 then
        killMessage = killMessage .. " - Kill Streak: " .. PKA_CurrentKillStreak
    end

    SendChatMessage(killMessage, "PARTY")

    if PKA_MultiKillCount >= PKA_MultiKillThreshold then
        SendChatMessage(GetMultiKillText(PKA_MultiKillCount), "PARTY")
    end
end

local function CreateKillDebugMessage(playerName, level, englishClass, race, nameWithLevel)
    local debugMsg = "Killed: " .. playerName

    local playerLevel = UnitLevel("player")
    local levelDifference = level > 0 and (level - playerLevel) or 0
    if level == -1 or (level > 0 and levelDifference >= 5) then
        debugMsg = debugMsg .. " (Level " .. (level == -1 and "??" or level)
    else
        debugMsg = debugMsg .. " ("
    end

    debugMsg = debugMsg .. englishClass .. ", " .. race .. ") - Total kills: " .. PKA_KillCounts[nameWithLevel].kills
    debugMsg = debugMsg .. " - Current streak: " .. PKA_CurrentKillStreak
    debugMsg = debugMsg .. " - Zone: " .. (PKA_KillCounts[nameWithLevel].zone or "Unknown")

    if PKA_MultiKillCount >= 2 then
        debugMsg = debugMsg .. " - " .. GetMultiKillText(PKA_MultiKillCount)
    end

    return debugMsg
end

local function RegisterPlayerKill(playerName, level, englishClass, race, gender, guild)
    local playerLevel = UnitLevel("player")
    local nameWithLevel = playerName .. ":" .. level

    UpdateKillStreak()
    PKA_ShowKillStreakMilestone(PKA_CurrentKillStreak)

    UpdateMultiKill()

    InitializeCacheForPlayer(nameWithLevel, englishClass, race, gender, guild, playerLevel)
    UpdateKillCacheEntry(nameWithLevel, race, gender, guild, playerLevel, (level == -1))

    AnnounceKill(playerName, level, nameWithLevel)

    -- Print debug message using the new function
    local debugMsg = CreateKillDebugMessage(playerName, level, englishClass, race, nameWithLevel)
    print(debugMsg)

    PKA_SaveSettings()
end

local function SimulatePlayerDeath()
    DEFAULT_CHAT_FRAME:AddMessage("Simulating player death...", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)

    if PKA_CurrentKillStreak >= 10 and PKA_EnableRecordAnnounce and IsInGroup() then
        local streakEndedMsg = string.gsub(PKA_KillStreakEndedMessage, "STREAKCOUNT", PKA_CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    PKA_CurrentKillStreak = 0
    PKA_MultiKillCount = 0
    inCombat = false
    PKA_SaveSettings()
    DEFAULT_CHAT_FRAME:AddMessage("Death simulated! Kill streak reset.", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function SimulatePlayerKills(killCount)
    DEFAULT_CHAT_FRAME:AddMessage("Registering " .. killCount .. " random test kill(s)...", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)

    local randomNames = {
        "Gankalicious", "Pwnyou", "Backstabber", "Shadowmelter", "Campmaster",
        "Roguenstein", "Sneakattack", "Huntard", "Faceroller", "Dotspammer",
        "Moonbender", "Healnoob", "Ragequitter", "Imbalanced", "Critmaster",
        "Zerglord", "Epicfail", "Oneshot", "Griefer", "Farmville",
        "Stunlock", "Procmaster", "Noobslayer", "Bodycamper", "Flagrunner"
    }

    local randomGuilds = {
        "Gank Squad", "PvP Masters", "Corpse Campers", "World Slayers", "Honor Farmers",
        "Rank Grinders", "Blood Knights", "Deadly Alliance", "Battleground Heroes", "Warsong Outlaws",
        "Death and Taxes", "Tactical Retreat", "Shadow Dancers", "First Strike", "Elite Few",
        "Kill on Sight", "No Mercy", "Rogues Do It", "Battlefield Legends", ""  -- Empty guild possible
    }

    local classes = {
        "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
        "SHAMAN", "MAGE", "WARLOCK", "DRUID"
    }

    local races = {
        "Human", "Dwarf", "NightElf", "Gnome",
    }

    local genders = {"Male", "Female"}

    -- Add random zones for testing
    local randomZones = {
        "Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Darnassus", "Undercity",
        "Elwynn Forest", "Durotar", "Mulgore", "Teldrassil", "Tirisfal Glades", "Westfall",
        "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "The Barrens", "Ashenvale",
        "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands", "Burning Steppes",
        "Desolace", "Dustwallow Marsh", "Eastern Plaguelands", "Felwood", "Feralas",
        "Hillsbrad Foothills", "Tanaris", "The Hinterlands", "Un'Goro Crater", "Western Plaguelands",
        "Winterspring", "Silithus", "Warsong Gulch", "Arathi Basin", "Alterac Valley"
    }

    -- Save the original zone for restoration after simulation
    local originalZone = GetRealZoneText() or "Unknown"

    for i = 1, killCount do
        local randomName = randomNames[math.random(#randomNames)]
        local randomGuild = randomGuilds[math.random(#randomGuilds)]
        local randomClass = classes[math.random(#classes)]
        local randomRace = races[math.random(#races)]
        local randomGender = genders[math.random(#genders)]
        local randomZone = randomZones[math.random(#randomZones)]

        local randomLevel = math.min(60, math.floor(math.random() * math.random() * 60) + 1)
        if math.random(100) <= 15 then  -- 15% chance for unknown level
            randomLevel = -1
        end

        -- Temporarily override GetRealZoneText to return our random zone
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        -- Register the kill with random data
        RegisterPlayerKill(randomName, randomLevel, randomClass, randomRace, randomGender, randomGuild)

        -- Restore the original function
        GetRealZoneText = originalGetRealZoneText
    end

    DEFAULT_CHAT_FRAME:AddMessage("Successfully registered " .. killCount .. " random test kill(s).", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

function PKA_SlashCommandHandler(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" then
        PrintSlashCommandUsage()
    elseif command == "status" then
        PrintStatus()
    elseif command == "kills" or command == "stats" then
        PKA_CreateKillStatsFrame()
    elseif command == "debug" then
        ShowDebugInfo()
    elseif command == "toggledebug" then
        PKA_Debug = not PKA_Debug
        DEFAULT_CHAT_FRAME:AddMessage("Debug mode " .. (PKA_Debug and "enabled" or "disabled"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    elseif command == "registerkill" then
        local testKillCount = 1

        if rest and rest ~= "" then
            local count = tonumber(rest)
            if count and count > 0 then
                testKillCount = count
            end
        end

        SimulatePlayerKills(testKillCount)
    elseif command == "death" then
        SimulatePlayerDeath()
    elseif command == "bgmode" then
        PKA_BattlegroundMode = not PKA_BattlegroundMode
        PKA_CheckBattlegroundStatus()
        DEFAULT_CHAT_FRAME:AddMessage("Manual Battleground Mode " .. (PKA_BattlegroundMode and "ENABLED" or "DISABLED"), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        PKA_SaveSettings()
    else
        PrintSlashCommandUsage()
    end
end

local function OnPlayerTargetChanged()
    PKA_CollectPlayerInfo("target")
    PKA_CollectPlayerInfo("targettarget")
end

local function OnUpdateMouseoverUnit()
    PKA_CollectPlayerInfo("mouseover")
end

local function HandleCombatState(inCombatNow)
    if inCombat and not inCombatNow then
        PKA_MultiKillCount = 0
        inCombat = false
    elseif not inCombat and inCombatNow then
        PKA_MultiKillCount = 0
        inCombat = true
    end
end

local function HandlePlayerDeath()
    if PKA_CurrentKillStreak >= 10 and PKA_EnableRecordAnnounce and IsInGroup() then
        local streakEndedMsg = string.gsub(PKA_KillStreakEndedMessage, "STREAKCOUNT", PKA_CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    PKA_CurrentKillStreak = 0
    PKA_MultiKillCount = 0
    inCombat = false
    PKA_SaveSettings()
    print("You died! Kill streak reset.")
end

local function ProcessEnemyPlayerDeath(destName, destGUID, sourceGUID, sourceName)
    local level, englishClass, race, gender, guild = PKA_GetPlayerInfo(destName, destGUID)

    if race == "Unknown" or gender == "Unknown" or englishClass == "Unknown" then
        print("Kill of " .. destName .. " not counted (incomplete data: " ..
              (race == "Unknown" and "race" or "") ..
              (gender == "Unknown" and (race == "Unknown" and ", gender" or "gender") or "") ..
              (englishClass == "Unknown" and ((race == "Unknown" or gender == "Unknown") and ", class" or "class") or "") ..
              " unknown)")
        return
    end

    local playerKill = false

    -- In battleground mode, only count direct player kills
    if PKA_InBattleground then
        if sourceGUID and sourceGUID == UnitGUID("player") then
            playerKill = true
            -- Note: not counting pet kills yet as requested
        end
    else
        -- Normal mode: count player, party or nearby combat kills
        if sourceGUID and (sourceGUID == UnitGUID("player") or UnitInParty(sourceName) or UnitInRaid(sourceName)) then
            playerKill = true
        end

        if UnitAffectingCombat("player") then
            playerKill = true
        end
    end

    if playerKill then
        RegisterPlayerKill(destName, level, englishClass, race, gender, guild)
    end
end

local function HandleCombatLogEvent()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

    if combatEvent == "UNIT_DIED" and destGUID == UnitGUID("player") then
        HandlePlayerDeath()
        return
    end

    if sourceName and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        PKA_UpdatePlayerInfoCache(sourceName, sourceGUID, nil, nil, nil, nil, nil)
    end

    if destName and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        PKA_UpdatePlayerInfoCache(destName, destGUID, nil, nil, nil, nil, nil)
    end

    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
           bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then

            ProcessEnemyPlayerDeath(destName, destGUID, sourceGUID, sourceName)
        end
    end
end

local function IsKillStreakMilestone(count)
    for _, milestone in ipairs(PKA_MILESTONE_STREAKS) do
        if count == milestone then
            return true
        end
    end
    return false
end

local function CreateMilestoneFrameIfNeeded()
    if killStreakMilestoneFrame then return killStreakMilestoneFrame end

    local frame = CreateFrame("Frame", "PKA_MilestoneFrame", UIParent)
    frame:SetSize(400, 200)
    frame:SetPoint("TOP", 0, -60)
    frame:SetFrameStrata("HIGH")

    local icon = frame:CreateTexture("PKA_MilestoneIcon", "ARTWORK")
    icon:SetSize(200, 200)
    icon:SetPoint("TOP", 0, 0)
    icon:SetTexture("Interface\\AddOns\\PlayerKillAnnounce\\img\\RedridgePoliceLogo.blp")
    frame.icon = icon

    local text = frame:CreateFontString("PKA_MilestoneText", "OVERLAY", "SystemFont_Huge1")
    text:SetPoint("TOP", icon, "BOTTOM", 0, -10)
    text:SetTextColor(1, 0, 0)
    text:SetTextHeight(30)
    frame.text = text

    frame:Hide()
    killStreakMilestoneFrame = frame
    return frame
end

local function SetupMilestoneAnimation(frame)
    if frame.animGroup then
        frame.animGroup:Stop()
        frame.animGroup:SetScript("OnPlay", nil)
        frame.animGroup:SetScript("OnFinished", nil)
        frame.animGroup:SetScript("OnStop", nil)
    end

    local animGroup = frame:CreateAnimationGroup()
    animGroup:SetLooping("NONE")

    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(1)

    local hold = animGroup:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(9.0)
    hold:SetOrder(2)

    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(3)

    animGroup:SetScript("OnFinished", function()
        frame:Hide()
    end)

    frame.animGroup = animGroup
    return animGroup
end

local function PlayMilestoneSound()
    PlaySound(8454) -- Warsong horde win sound
    PlaySound(8574) -- Cheer sound
end

function PKA_ShowKillStreakMilestone(killCount)
    if not IsKillStreakMilestone(killCount) then
        return
    end

    local frame = CreateMilestoneFrameIfNeeded()

    frame.text:SetText(killCount .. " KILL STREAK")

    frame:Show()
    frame:SetAlpha(0)

    local animGroup = SetupMilestoneAnimation(frame)

    PlayMilestoneSound()

    DoEmote("CHEER")

    animGroup:Play()
end

function RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGIN")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    playerKillAnnounceFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_DEAD")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGOUT")
    playerKillAnnounceFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- Add zone change event

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            PKA_LoadSettings()
            inCombat = UnitAffectingCombat("player")
            PKA_CheckBattlegroundStatus()  -- Check BG status on login/reload
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
        elseif event == "PLAYER_LOGOUT" then
            PKA_CleanupDatabase()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            PKA_CheckBattlegroundStatus()  -- Check BG status on zone change
        end
    end)
end

-- Add after the RegisterEvents function
function PKA_CheckBattlegroundStatus()
    if not PKA_AutoBattlegroundMode then
        PKA_InBattleground = PKA_BattlegroundMode
        return PKA_InBattleground
    end

    -- Get current zone
    local currentZone = GetRealZoneText() or ""

    -- List of battleground zones
    local battlegroundZones = {
        "Warsong Gulch",
        "Arathi Basin",
        "Alterac Valley",
        -- Add other BGs if needed
    }

    -- Check if current zone is a battleground
    for _, bgName in ipairs(battlegroundZones) do
        if currentZone == bgName then
            PKA_InBattleground = true
            if PKA_Debug and not PKA_LastBattlegroundState then
                print("PlayerKillAnnounce: Entered battleground. Only direct kills will be counted.")
            end
            PKA_LastBattlegroundState = true
            return true
        end
    end

    -- Not in a battleground
    if PKA_Debug and PKA_LastBattlegroundState then
        print("PlayerKillAnnounce: Left battleground. Normal kill tracking active.")
    end
    PKA_LastBattlegroundState = false
    PKA_InBattleground = PKA_BattlegroundMode
    return PKA_InBattleground
end

function PKA_SaveSettings()
    -- Save existing settings
    PlayerKillAnnounceDB = PlayerKillAnnounceDB or {}
    PlayerKillAnnounceDB.KillAnnounceMessage = PKA_KillAnnounceMessage
    PlayerKillAnnounceDB.KillCounts = PKA_KillCounts
    PlayerKillAnnounceDB.CurrentKillStreak = PKA_CurrentKillStreak
    PlayerKillAnnounceDB.HighestKillStreak = PKA_HighestKillStreak
    PlayerKillAnnounceDB.EnableKillAnnounce = PKA_EnableKillAnnounce
    PlayerKillAnnounceDB.KillStreakEndedMessage = PKA_KillStreakEndedMessage
    PlayerKillAnnounceDB.NewStreakRecordMessage = PKA_NewStreakRecordMessage
    PlayerKillAnnounceDB.NewMultiKillRecordMessage = PKA_NewMultiKillRecordMessage
    PlayerKillAnnounceDB.EnableRecordAnnounce = PKA_EnableRecordAnnounce
    PlayerKillAnnounceDB.MultiKillThreshold = PKA_MultiKillThreshold
    PlayerKillAnnounceDB.MultiKillCount = PKA_MultiKillCount
    PlayerKillAnnounceDB.HighestMultiKill = PKA_HighestMultiKill

    -- Save new battleground settings
    PlayerKillAnnounceDB.AutoBattlegroundMode = PKA_AutoBattlegroundMode
    PlayerKillAnnounceDB.BattlegroundMode = PKA_BattlegroundMode
end
