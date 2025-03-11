-- This AddOn counts the number of player kills since login and announces each kill
-- in the party chat. You can adjust the kill announce message to your liking.
-- "Enemyplayername" will be replaced with the name of the player that was killed.
local PlayerKillMessageDefault = "Enemyplayername killed!"
local KillStreakEndedMessageDefault = "My kill streak of STREAKCOUNT has ended!"
local NewStreakRecordMessageDefault = "NEW PERSONAL BEST: Kill streak of STREAKCOUNT!"
local NewMultiKillRecordMessageDefault = "NEW PERSONAL BEST: Multi-kill of MULTIKILLCOUNT!"

------------------------------------------------------------------------
local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
PKA_EnableKillAnnounce = true
PKA_KillAnnounceMessage = PlayerKillMessageDefault
PKA_KillCounts = {}

-- Add new variables for custom messages
PKA_KillStreakEndedMessage = KillStreakEndedMessageDefault
PKA_NewStreakRecordMessage = NewStreakRecordMessageDefault
PKA_NewMultiKillRecordMessage = NewMultiKillRecordMessageDefault

-- Add new variables for tracking streaks and multi-kills
PKA_CurrentKillStreak = 0
PKA_HighestKillStreak = 0
PKA_MultiKillCount = 0
PKA_HighestMultiKill = 0
PKA_LastCombatTime = 0

-- Add combat state tracking variable
local inCombat = false

-- Add at the top with other variables
PKA_EnableRecordAnnounce = true  -- Enable announcing new records to party by default

local PKA_CHAT_MESSAGE_R = 1.0
local PKA_CHAT_MESSAGE_G = 1.0
local PKA_CHAT_MESSAGE_B = 0.74


local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka toggle", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka killmessage <message>", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("The word Enemyplayername will be replaced with the name of the player " ..
        "that was killed. For example: Enemyplayername killed!", PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka streakendedsay <message>", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka newstreakmessage <message>", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka multikillmessage <message>", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("For streak messages, STREAKCOUNT or MULTIKILLCOUNT will be replaced with the actual count.",
        PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka stats", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka debug - Show current streak values", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka records - Toggle announcing new records to party chat", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (PKA_EnableKillAnnounce and "ENABLED" or "DISABLED") .. "."
    DEFAULT_CHAT_FRAME:AddMessage(statusMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current kill announce message: " .. PKA_KillAnnounceMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Streak ended message: " .. PKA_KillStreakEndedMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("New streak record message: " .. PKA_NewStreakRecordMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("New multi-kill record message: " .. PKA_NewMultiKillRecordMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Record announcements: " .. (PKA_EnableRecordAnnounce and "ENABLED" or "DISABLED"),
        PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function HandleToggleCommand()
    PKA_EnableKillAnnounce = not PKA_EnableKillAnnounce
    PKA_SaveSettings()
    if PKA_EnableKillAnnounce then
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now ENABLED.", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G,
            PKA_CHAT_MESSAGE_B)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now DISABLED.", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G,
            PKA_CHAT_MESSAGE_B)
    end
end

local function HandleSetMessageCommand(message)
    PKA_KillAnnounceMessage = message
    -- print("Setting KillAnnounceMessage to:", KillAnnounceMessage)
    PKA_SaveSettings()
    DEFAULT_CHAT_FRAME:AddMessage("Kill announce message set to: " .. PKA_KillAnnounceMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

function PKA_SlashCommandHandler(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" then
        PrintSlashCommandUsage()
    elseif command == "toggle" then
        HandleToggleCommand()
    elseif command == "killmessage" and rest and rest ~= "" then
        HandleSetMessageCommand(rest)
    elseif command == "streakendedsay" and rest and rest ~= "" then
        PKA_KillStreakEndedMessage = rest
        PKA_SaveSettings()
        DEFAULT_CHAT_FRAME:AddMessage("Streak ended message set to: " .. PKA_KillStreakEndedMessage, PKA_CHAT_MESSAGE_R,
            PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    elseif command == "newstreakmessage" and rest and rest ~= "" then
        PKA_NewStreakRecordMessage = rest
        PKA_SaveSettings()
        DEFAULT_CHAT_FRAME:AddMessage("New streak record message set to: " .. PKA_NewStreakRecordMessage, PKA_CHAT_MESSAGE_R,
            PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    elseif command == "multikillmessage" and rest and rest ~= "" then
        PKA_NewMultiKillRecordMessage = rest
        PKA_SaveSettings()
        DEFAULT_CHAT_FRAME:AddMessage("New multi-kill record message set to: " .. PKA_NewMultiKillRecordMessage, PKA_CHAT_MESSAGE_R,
            PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    elseif command == "status" then
        PrintStatus()
    elseif command == "kills" or command == "stats" then
        -- Open the kill stats window
        PKA_CreateKillStatsFrame()
    elseif command == "debug" then
        -- Add a debug command to show streak values
        DEFAULT_CHAT_FRAME:AddMessage("Current Kill Streak: " .. PKA_CurrentKillStreak,
                                      PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        DEFAULT_CHAT_FRAME:AddMessage("Highest Kill Streak: " .. PKA_HighestKillStreak,
                                      PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        DEFAULT_CHAT_FRAME:AddMessage("Current Multi-kill Count: " .. PKA_MultiKillCount,
                                      PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        DEFAULT_CHAT_FRAME:AddMessage("Highest Multi-kill: " .. PKA_HighestMultiKill,
                                      PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)

        -- Add time window info for multi-kills
        local currentTime = GetTime()
        local timeRemaining = math.max(0, (PKA_LastCombatTime + PKA_MULTI_KILL_WINDOW) - currentTime)
        if timeRemaining > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Multi-kill window: %.1f seconds remaining", timeRemaining),
                                         PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Multi-kill window: expired",
                                         PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
        end
    elseif command == "records" or command == "announce" then
        -- Toggle record announcements
        PKA_EnableRecordAnnounce = not PKA_EnableRecordAnnounce
        PKA_SaveSettings()
        local status = PKA_EnableRecordAnnounce and "ENABLED" or "DISABLED"
        DEFAULT_CHAT_FRAME:AddMessage("Record announcements are now " .. status, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    else
        PrintSlashCommandUsage()
    end
end

-- Event handlers for updating player info cache
local function OnPlayerTargetChanged()
    PKA_CollectPlayerInfo("target")
    PKA_CollectPlayerInfo("targettarget")
end

local function OnUpdateMouseoverUnit()
    PKA_CollectPlayerInfo("mouseover")
end

-- Function to handle player entering/leaving combat
local function HandleCombatState(inCombatNow)
    -- If we were in combat and now we're not, reset multi-kill count
    if inCombat and not inCombatNow then
        PKA_MultiKillCount = 0
        inCombat = false
    elseif not inCombat and inCombatNow then
        -- Reset multi-kill count when entering combat
        PKA_MultiKillCount = 0
        inCombat = true
    end
end

-- Enhanced combat log event handler
local function HandleCombatLogEvent()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags =
    CombatLogGetCurrentEventInfo()

    -- Check if the player died (for tracking kill streaks)
    if combatEvent == "UNIT_DIED" and destGUID == UnitGUID("player") then
        -- Player died, reset current kill streak
        PKA_CurrentKillStreak = 0
        PKA_MultiKillCount = 0
        PKA_SaveSettings()
        print("You died! Kill streak reset.")
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

            -- Ensure we track enemy players only
            -- Update kill streak counter - only if we're nearby or our party/raid members caused the kill
            local playerOrPartyKill = false

            -- Check if we or our party/raid members caused the kill
            if sourceGUID and (sourceGUID == UnitGUID("player") or
              (UnitInParty(sourceName) or UnitInRaid(sourceName))) then
                playerOrPartyKill = true
            end

            -- Check if we're in combat - this means we're likely involved in the kill
            if UnitAffectingCombat("player") then
                playerOrPartyKill = true
            end

            if playerOrPartyKill then
                PKA_CurrentKillStreak = PKA_CurrentKillStreak + 1

                -- Check if this is a new highest streak
                if PKA_CurrentKillStreak > PKA_HighestKillStreak then
                    PKA_HighestKillStreak = PKA_CurrentKillStreak

                    -- Only announce new records if they're greater than 1
                    if PKA_HighestKillStreak > 1 then
                        -- Local announcement
                        print("NEW KILL STREAK RECORD: " .. PKA_HighestKillStreak .. "!")

                        -- Party announcement for significant records (3+)
                        if PKA_HighestKillStreak >= 3 and PKA_EnableRecordAnnounce and IsInGroup() then
                            local newRecordMsg = string.gsub(PKA_NewStreakRecordMessage or NewStreakRecordMessageDefault, "STREAKCOUNT", PKA_HighestKillStreak)
                            SendChatMessage(newRecordMsg, "PARTY")
                        end

                        -- Update config UI if it's open
                        if PKA_UpdateConfigStats then
                            PKA_UpdateConfigStats()
                        end
                    end
                end

                -- Check for multi-kill (kills while in combat)
                if UnitAffectingCombat("player") then
                    -- Make sure we're tracking combat state
                    if not inCombat then
                        inCombat = true
                    end

                    -- Increment multi-kill counter
                    PKA_MultiKillCount = PKA_MultiKillCount + 1
                else
                    -- Not in combat, reset counter
                    PKA_MultiKillCount = 1
                    inCombat = false
                end

                -- Update highest multi-kill if needed
                if PKA_MultiKillCount > PKA_HighestMultiKill then
                    PKA_HighestMultiKill = PKA_MultiKillCount

                    -- Only announce new records if they're greater than 1
                    if PKA_HighestMultiKill > 1 then
                        -- Local announcement
                        print("NEW MULTI-KILL RECORD: " .. PKA_HighestMultiKill .. "!")

                        -- Party announcement for significant records (3+)
                        if PKA_HighestMultiKill >= 3 and PKA_EnableRecordAnnounce and IsInGroup() then
                            local newMultiKillMsg = string.gsub(PKA_NewMultiKillRecordMessage or NewMultiKillRecordMessageDefault, "MULTIKILLCOUNT", PKA_HighestMultiKill)
                            SendChatMessage(newMultiKillMsg, "PARTY")
                        end

                        -- Update config UI if it's open
                        if PKA_UpdateConfigStats then
                            PKA_UpdateConfigStats()
                        end
                    end
                end

                -- Save settings to persist streak data
                PKA_SaveSettings()
            end

            -- Get the best available player info using our cache and other methods
            local level, englishClass, race, gender, guild = PKA_GetPlayerInfo(destName, destGUID)

            -- Get current player level at time of kill
            local playerLevel = UnitLevel("player")

            -- Create composite key with name and level
            local nameWithLevel = destName .. ":" .. level

            -- Initialize or update kill data
            if not PKA_KillCounts[nameWithLevel] then
                PKA_KillCounts[nameWithLevel] = {
                    kills = 0,
                    class = englishClass,
                    race = race,
                    gender = gender,
                    guild = guild,
                    lastKill = "",
                    playerLevel = playerLevel  -- Store our level at time of kill
                }
            end

            -- Update kill count and timestamp
            PKA_KillCounts[nameWithLevel].kills = PKA_KillCounts[nameWithLevel].kills + 1
            PKA_KillCounts[nameWithLevel].lastKill = date("%Y-%m-%d %H:%M:%S")
            -- Update the player level with current level when getting a kill
            PKA_KillCounts[nameWithLevel].playerLevel = playerLevel
            -- Make sure we always have the latest info for race, gender and guild
            if race ~= "Unknown" then PKA_KillCounts[nameWithLevel].race = race end
            if gender ~= "Unknown" then PKA_KillCounts[nameWithLevel].gender = gender end
            if guild ~= "" then PKA_KillCounts[nameWithLevel].guild = guild end

            -- Announce the kill to party chat with streak info if significant
            if PKA_EnableKillAnnounce and IsInGroup() then
                local killMessage = ""

                -- Make sure PKA_KillAnnounceMessage is valid before using gsub
                if PKA_KillAnnounceMessage then
                    killMessage = string.gsub(PKA_KillAnnounceMessage, "Enemyplayername", destName)
                else
                    -- Fallback to default message if PKA_KillAnnounceMessage is nil
                    killMessage = string.gsub(PlayerKillMessageDefault, "Enemyplayername", destName)
                    -- Restore the message variable
                    PKA_KillAnnounceMessage = PlayerKillMessageDefault
                    PKA_SaveSettings()
                end

                killMessage = killMessage .. " (Level " .. level .. ") x" .. PKA_KillCounts[nameWithLevel].kills

                -- Add kill streak message if impressive
                if PKA_CurrentKillStreak >= 5 then
                    killMessage = killMessage .. " - Kill Streak: " .. PKA_CurrentKillStreak
                end

                -- Send the main kill message
                SendChatMessage(killMessage, "PARTY")

                -- Add multi-kill message as a separate message in all caps
                if PKA_MultiKillCount >= 2 then
                    local multiKillText = ""
                    if PKA_MultiKillCount == 2 then
                        multiKillText = "DOUBLE KILL!"
                    elseif PKA_MultiKillCount == 3 then
                        multiKillText = "TRIPLE KILL!"
                    elseif PKA_MultiKillCount == 4 then
                        multiKillText = "QUADRA KILL!"
                    elseif PKA_MultiKillCount >= 5 then
                        multiKillText = "PENTA KILL!"
                    end

                    -- Send multi-kill message as a separate message
                    SendChatMessage(multiKillText, "PARTY")
                end
            end

            PKA_SaveSettings()

            -- Debug message for local confirmation
            local debugMsg = "Killed: " ..
                destName ..
                " (Level " ..
                level .. ", " .. englishClass .. ", " .. race .. ") - Total kills: " .. PKA_KillCounts[nameWithLevel].kills

            -- Add streak info to debug message
            debugMsg = debugMsg .. " - Current streak: " .. PKA_CurrentKillStreak

            -- Add multi-kill info to debug message if applicable
            if PKA_MultiKillCount >= 2 then
                local multiKillText = ""
                if PKA_MultiKillCount == 2 then
                    multiKillText = "DOUBLE KILL!"
                elseif PKA_MultiKillCount == 3 then
                    multiKillText = "TRIPLE KILL!"
                elseif PKA_MultiKillCount == 4 then
                    multiKillText = "QUADRA KILL!"
                elseif PKA_MultiKillCount >= 5 then
                    multiKillText = "PENTA KILL!"
                end
                debugMsg = debugMsg .. " - " .. multiKillText
            end

            print(debugMsg)
        end
    end
end

-- Enhanced event registration to include combat tracking
function RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGIN")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    playerKillAnnounceFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_DEAD")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Player enters combat
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Player leaves combat

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            PKA_LoadSettings()
            -- Update combat state
            inCombat = UnitAffectingCombat("player")
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        elseif event == "PLAYER_DEAD" then
            -- Only announce if the streak was noteworthy and announcements are enabled
            if PKA_CurrentKillStreak >= 3 and PKA_EnableRecordAnnounce and IsInGroup() then
                -- Announce the end of your streak to party chat
                local streakEndedMsg = string.gsub(PKA_KillStreakEndedMessage, "STREAKCOUNT", PKA_CurrentKillStreak)
                SendChatMessage(streakEndedMsg, "PARTY")
            end

            -- Player died, reset current kill streak and multi-kill
            PKA_CurrentKillStreak = 0
            PKA_MultiKillCount = 0
            inCombat = false
            PKA_SaveSettings()
            print("You died! Kill streak reset.")
        elseif event == "PLAYER_REGEN_DISABLED" then
            -- Player entered combat
            HandleCombatState(true)
        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Player left combat
            HandleCombatState(false)
        end
    end)
end
