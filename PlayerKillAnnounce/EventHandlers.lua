-- This AddOn counts the number of player kills since login and announces each kill
-- in the party chat. You can adjust the kill announce message to your liking.
-- "Enemyplayername" will be replaced with the name of the player that was killed.
local PlayerKillMessageDefault = "Enemyplayername killed!"
------------------------------------------------------------------------
local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
PKA_EnableKillAnnounce = true
PKA_KillAnnounceMessage = PlayerKillMessageDefault
PKA_KillCounts = {}

local PKA_CHAT_MESSAGE_R = 1.0
local PKA_CHAT_MESSAGE_G = 1.0
local PKA_CHAT_MESSAGE_B = 0.74


local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka toggle", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka killmessage <message>", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("The word Enemyplayername will be replaced with the name of the player " ..
        "that was killed. For example: Enemyplayername killed!", PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka stats", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status", PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (PKA_EnableKillAnnounce and "ENABLED" or "DISABLED") .. "."
    DEFAULT_CHAT_FRAME:AddMessage(statusMessage, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current kill announce message: " .. PKA_KillAnnounceMessage, PKA_CHAT_MESSAGE_R,
        PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
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
    elseif command == "status" then
        PrintStatus()
    elseif command == "stats" then
        -- Open the kill stats window
        PKA_CreateKillStatsFrame()
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

-- Enhanced combat log event handler
local function HandleCombatLogEvent()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags =
    CombatLogGetCurrentEventInfo()

    -- Collect info about all players we see in the combat log
    if sourceName and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        -- Try to update our cache with source player info
        PKA_UpdatePlayerInfoCache(sourceName, sourceGUID, nil, nil, nil, nil, nil)
    end

    if destName and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        -- Try to update our cache with destination player info
        PKA_UpdatePlayerInfoCache(destName, destGUID, nil, nil, nil, nil, nil)
    end

    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
            bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
            -- Get the best available player info using our cache and other methods
            local level, englishClass, race, gender, guild = PKA_GetPlayerInfo(destName, destGUID)

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
                    lastKill = ""
                }
            end

            -- Update kill count and timestamp
            PKA_KillCounts[nameWithLevel].kills = PKA_KillCounts[nameWithLevel].kills + 1
            PKA_KillCounts[nameWithLevel].lastKill = date("%Y-%m-%d %H:%M:%S")
            -- Make sure we always have the latest info for race, gender and guild
            if race ~= "Unknown" then PKA_KillCounts[nameWithLevel].race = race end
            if gender ~= "Unknown" then PKA_KillCounts[nameWithLevel].gender = gender end
            if guild ~= "" then PKA_KillCounts[nameWithLevel].guild = guild end

            -- Announce the kill to party chat
            if PKA_EnableKillAnnounce and IsInGroup() then
                local killMessage = string.gsub(PKA_KillAnnounceMessage, "Enemyplayername", destName)
                killMessage = killMessage .. " (Level " .. level .. ") x" .. PKA_KillCounts[nameWithLevel].kills
                SendChatMessage(killMessage, "PARTY")
            end

            PKA_SaveSettings()

            -- Debug message for local confirmation
            print("Killed: " ..
            destName ..
            " (Level " ..
            level .. ", " .. englishClass .. ", " .. race .. ") - Total kills: " .. PKA_KillCounts[nameWithLevel].kills)
        end
    end
end

-- Enhanced event registration to include new events for player info collection
function RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGIN")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    playerKillAnnounceFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            PKA_LoadSettings()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        end
    end)
end
