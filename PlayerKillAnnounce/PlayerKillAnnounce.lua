-- This AddOn counts the number of player kills since login and announces each kill
-- in the party chat. You can adjust the kill announce message to your liking.
-- "Enemyplayername" will be replaced with the name of the player that was killed.
PlayerKillMessageDefault = "Enemyplayername killed!"
------------------------------------------------------------------------

local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
local EnableKillAnnounce = true
local KillAnnounceMessage = PlayerKillMessageDefault

local CHAT_MESSAGE_R = 1.0
local CHAT_MESSAGE_G = 1.0
local CHAT_MESSAGE_B = 0.74


local function SaveSettings()
    PlayerKillAnnounceDB.EnableKillAnnounce = EnableKillAnnounce
    PlayerKillAnnounceDB.KillAnnounceMessage = KillAnnounceMessage
    -- print("Settings saved: EnableKillAnnounce =", EnableKillAnnounce, "KillAnnounceMessage =", KillAnnounceMessage)
end


local function LoadSettings()
    if PlayerKillAnnounceDB then
        if PlayerKillAnnounceDB.EnableKillAnnounce ~= nil then
            EnableKillAnnounce = PlayerKillAnnounceDB.EnableKillAnnounce
        end
        if PlayerKillAnnounceDB.KillAnnounceMessage ~= nil then
            KillAnnounceMessage = PlayerKillAnnounceDB.KillAnnounceMessage
        end
        -- print("Settings loaded: EnableKillAnnounce =", EnableKillAnnounce, "KillAnnounceMessage =", KillAnnounceMessage)
    else
        -- print("PlayerKillAnnounceDB is nil")
    end
end


local function HandleCombatLogEvent()
    local _, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags =
        CombatLogGetCurrentEventInfo()
    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
            bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then
            -- Announce the kill to party chat
            if EnableKillAnnounce then
                local killMessage = string.gsub(KillAnnounceMessage, "Enemyplayername", destName)
                SendChatMessage(killMessage, "PARTY")
                -- SendChatMessage(killMessage, "WHISPER", nil, "Severussnipe")
            end
        end
    end
end


local function OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        LoadSettings()
    elseif event == "PLAYER_LOGOUT" then
        SaveSettings()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLogEvent()
    end
end


local function RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGOUT")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:SetScript("OnEvent", OnEvent)
end


local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka toggle", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka killmessage <message>", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("The word Enemyplayername will be replaced with the name of the player " ..
        "that was killed. For example: Enemyplayername killed!",
        CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
end


local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (EnableKillAnnounce and "ENABLED" or "DISABLED") .. "."
    DEFAULT_CHAT_FRAME:AddMessage(statusMessage, CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current kill announce message: " .. KillAnnounceMessage, CHAT_MESSAGE_R,
        CHAT_MESSAGE_G, CHAT_MESSAGE_B)
end


local function HandleToggleCommand()
    EnableKillAnnounce = not EnableKillAnnounce
    SaveSettings()
    if EnableKillAnnounce then
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now ENABLED.", CHAT_MESSAGE_R, CHAT_MESSAGE_G,
            CHAT_MESSAGE_B)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now DISABLED.", CHAT_MESSAGE_R, CHAT_MESSAGE_G,
            CHAT_MESSAGE_B)
    end
end


local function HandleSetMessageCommand(message)
    KillAnnounceMessage = message
    -- print("Setting KillAnnounceMessage to:", KillAnnounceMessage)
    SaveSettings()
    DEFAULT_CHAT_FRAME:AddMessage("Kill announce message set to: " .. KillAnnounceMessage, CHAT_MESSAGE_R, CHAT_MESSAGE_G,
        CHAT_MESSAGE_B)
end


local function RegisterSlashCommands()
    SLASH_PLAYERKILLANNOUNCE1 = "/playerkillannounce"
    SLASH_PLAYERKILLANNOUNCE2 = "/pka"
    SlashCmdList["PLAYERKILLANNOUNCE"] = function(msg)
        local command, rest = msg:match("^(%S*)%s*(.-)$")
        if command == "toggle" then
            HandleToggleCommand()
        elseif command == "killmessage" and rest and rest ~= "" then
            HandleSetMessageCommand(rest)
        elseif command == "status" then
            PrintStatus()
        else
            PrintSlashCommandUsage()
        end
    end
end


local function Main()
    RegisterEvents()
    RegisterSlashCommands()
end


Main()
