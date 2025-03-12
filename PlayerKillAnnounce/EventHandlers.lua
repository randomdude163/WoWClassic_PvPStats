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

-- UI Constants
local PKA_CHAT_MESSAGE_R = 1.0
local PKA_CHAT_MESSAGE_G = 1.0
local PKA_CHAT_MESSAGE_B = 0.74

-- State tracking variables
local inCombat = false
local killStreakMilestoneFrame = nil

local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka config - Open configuration UI", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka stats - Show kills list", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status - Show current settings", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka debug - Show current streak values", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka registerkill [number] - Register test kill(s) for testing", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka death - Simulate player death (resets kill streak)", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
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
end

local function ShowDebugInfo()
    DEFAULT_CHAT_FRAME:AddMessage("Current Kill Streak: " .. PKA_CurrentKillStreak, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Highest Kill Streak: " .. PKA_HighestKillStreak, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current Multi-kill Count: " .. PKA_MultiKillCount, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Highest Multi-kill: " .. PKA_HighestMultiKill, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Multi-kill Announcement Threshold: " .. PKA_MultiKillThreshold, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)

    local currentTime = GetTime()
    local timeRemaining = math.max(0, (PKA_LastCombatTime + PKA_MULTI_KILL_WINDOW) - currentTime)
    if timeRemaining > 0 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Multi-kill window: %.1f seconds remaining", timeRemaining), PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Multi-kill window: expired", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    end
end

local function InitializeCacheForPlayer(nameWithLevel, englishClass, race, gender, guild, playerLevel)
    if not PKA_KillCounts[nameWithLevel] then
        PKA_KillCounts[nameWithLevel] = {
            kills = 0,
            class = englishClass or "Unknown",
            race = race or "Unknown",
            gender = gender or 1,
            guild = guild or "Unknown",
            lastKill = "",
            playerLevel = playerLevel or -1,
            unknownLevel = false
        }
    end
end

local function UpdateKillCacheEntry(nameWithLevel, race, gender, guild, playerLevel, isUnknownLevel)
    PKA_KillCounts[nameWithLevel].kills = PKA_KillCounts[nameWithLevel].kills + 1
    PKA_KillCounts[nameWithLevel].lastKill = date("%Y-%m-%d %H:%M:%S")
    PKA_KillCounts[nameWithLevel].playerLevel = playerLevel or -1

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
    if not PKA_EnableKillAnnounce or not IsInGroup() then return end

    local killMessage = PKA_KillAnnounceMessage and string.gsub(PKA_KillAnnounceMessage, "Enemyplayername", killedPlayer) or
                        string.gsub(PlayerKillMessageDefault, "Enemyplayername", killedPlayer)

    -- Add level info if unknown or significantly higher
    local playerLevel = UnitLevel("player")
    local levelDifference = level - playerLevel
    local levelDisplay = level == -1 and "??" or tostring(level)

    if level == -1 or (level > 0 and levelDifference >= 5) then
        killMessage = killMessage .. " (Level " .. levelDisplay .. ")"
    end

    -- Add kill count
    killMessage = killMessage .. " x" .. PKA_KillCounts[nameWithLevel].kills

    -- Add streak info for significant streaks
    if PKA_CurrentKillStreak >= 10 and PKA_CurrentKillStreak % 5 == 0 then
        killMessage = killMessage .. " - Kill Streak: " .. PKA_CurrentKillStreak
    end

    SendChatMessage(killMessage, "PARTY")

    -- Announce multi-kill if significant
    if PKA_MultiKillCount >= PKA_MultiKillThreshold then
        SendChatMessage(GetMultiKillText(PKA_MultiKillCount), "PARTY")
    end
end

local function CreateKillDebugMessage(playerName, level, englishClass, race, nameWithLevel)
    local debugMsg = "Killed: " .. playerName

    -- Add level info if unknown or significantly higher
    local playerLevel = UnitLevel("player")
    local levelDifference = level > 0 and (level - playerLevel) or 0
    if level == -1 or (level > 0 and levelDifference >= 5) then
        debugMsg = debugMsg .. " (Level " .. (level == -1 and "??" or level)
    else
        debugMsg = debugMsg .. " ("
    end

    debugMsg = debugMsg .. englishClass .. ", " .. race .. ") - Total kills: " .. PKA_KillCounts[nameWithLevel].kills
    debugMsg = debugMsg .. " - Current streak: " .. PKA_CurrentKillStreak

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
    DEFAULT_CHAT_FRAME:AddMessage("Registering " .. killCount .. " test kill(s)...", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)

    for i = 1, killCount do
        local testPlayerName = "TestDummy"
        local testPlayerLevel = 60
        RegisterPlayerKill(testPlayerName, testPlayerLevel, "WARRIOR", "Human", "Male", "Test Guild")
    end
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

    -- Skip kills with unknown attributes
    if race == "Unknown" or gender == "Unknown" or englishClass == "Unknown" then
        print("Kill of " .. destName .. " not counted (incomplete data: " ..
              (race == "Unknown" and "race" or "") ..
              (gender == "Unknown" and (race == "Unknown" and ", gender" or "gender") or "") ..
              (englishClass == "Unknown" and ((race == "Unknown" or gender == "Unknown") and ", class" or "class") or "") ..
              " unknown)")
        return
    end

    -- Check if we or party/raid members caused the kill
    local playerOrPartyKill = false
    if sourceGUID and (sourceGUID == UnitGUID("player") or UnitInParty(sourceName) or UnitInRaid(sourceName)) then
        playerOrPartyKill = true
    end

    -- Check if we're in combat - this means we're likely involved in the kill
    if UnitAffectingCombat("player") then
        playerOrPartyKill = true
    end

    if playerOrPartyKill then
        RegisterPlayerKill(destName, level, englishClass, race, gender, guild)
    end
end

local function HandleCombatLogEvent()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

    -- Check if the player died
    if combatEvent == "UNIT_DIED" and destGUID == UnitGUID("player") then
        HandlePlayerDeath()
        return
    end

    -- Collect info about all players we see in the combat log
    if sourceName and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        PKA_UpdatePlayerInfoCache(sourceName, sourceGUID, nil, nil, nil, nil, nil)
    end

    if destName and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        PKA_UpdatePlayerInfoCache(destName, destGUID, nil, nil, nil, nil, nil)
    end

    -- Track enemy player deaths
    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
           bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then

            ProcessEnemyPlayerDeath(destName, destGUID, sourceGUID, sourceName)
        end
    end
end

-- Helper function to check if a kill streak count is a milestone
local function IsKillStreakMilestone(count)
    for _, milestone in ipairs(PKA_MILESTONE_STREAKS) do
        if count == milestone then
            return true
        end
    end
    return false
end

-- Creates the milestone frame if it doesn't exist yet
local function CreateMilestoneFrameIfNeeded()
    if killStreakMilestoneFrame then return killStreakMilestoneFrame end

    -- Create main frame
    local frame = CreateFrame("Frame", "PKA_MilestoneFrame", UIParent)
    frame:SetSize(400, 200)
    frame:SetPoint("TOP", 0, -60)
    frame:SetFrameStrata("HIGH")

    -- Create icon texture
    local icon = frame:CreateTexture("PKA_MilestoneIcon", "ARTWORK")
    icon:SetSize(200, 200)
    icon:SetPoint("TOP", 0, 0)
    icon:SetTexture("Interface\\AddOns\\PlayerKillAnnounce\\img\\RedridgePoliceLogo.blp")
    frame.icon = icon

    -- Create text display
    local text = frame:CreateFontString("PKA_MilestoneText", "OVERLAY", "SystemFont_Huge1")
    text:SetPoint("TOP", icon, "BOTTOM", 0, -10)
    text:SetTextColor(1, 0, 0)
    text:SetTextHeight(30)
    frame.text = text

    frame:Hide()
    killStreakMilestoneFrame = frame
    return frame
end

-- Setup animation group for the milestone frame
local function SetupMilestoneAnimation(frame)
    -- Clean up any existing animation
    if frame.animGroup then
        frame.animGroup:Stop()
        frame.animGroup:SetScript("OnPlay", nil)
        frame.animGroup:SetScript("OnFinished", nil)
        frame.animGroup:SetScript("OnStop", nil)
    end

    -- Create new animation group
    local animGroup = frame:CreateAnimationGroup()
    animGroup:SetLooping("NONE")

    -- Fade in animation
    local fadeIn = animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(1)

    -- Hold animation (display duration)
    local hold = animGroup:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(9.0)
    hold:SetOrder(2)

    -- Fade out animation
    local fadeOut = animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(3)

    -- Hide the frame when finished
    animGroup:SetScript("OnFinished", function()
        frame:Hide()
    end)

    frame.animGroup = animGroup
    return animGroup
end

-- Play the milestone achievement sound
local function PlayMilestoneSound()
    PlaySound(8454) -- First sound effect
    PlaySound(8574) -- Second sound effect
end

-- Display the milestone animation with text
function PKA_ShowKillStreakMilestone(killCount)
    -- Only proceed if this is a milestone kill streak
    if not IsKillStreakMilestone(killCount) then
        return
    end

    -- Create or get the milestone frame
    local frame = CreateMilestoneFrameIfNeeded()

    -- Update the text for this milestone
    frame.text:SetText(killCount .. " KILL STREAK")

    -- Show the frame but start with zero opacity
    frame:Show()
    frame:SetAlpha(0)

    -- Setup the animation sequence
    local animGroup = SetupMilestoneAnimation(frame)

    -- Play milestone sounds
    PlayMilestoneSound()

    -- Start the animation
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

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            PKA_LoadSettings()
            inCombat = UnitAffectingCombat("player")
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
        end
    end)
end
