local function PrintSlashCommandUsage()
    -- PSC_Print("Usage: /psc settings - Open settings UI")
    -- PSC_Print("Usage: /psc stats - Show PvP history")
    -- PSC_Print("Usage: /psc status - Show current settings")
    -- PSC_Print("Usage: /psc debug - Show current streak values")
    -- PSC_Print("Usage: /psc registerkill [number] - Register test kill(s) for testing")
    -- PSC_Print("Usage: /psc simulatedeath [killers] [assists] - Simulate being killed")
    -- PSC_Print("Usage: /psc bgmode - Toggle battleground mode manually")
    -- PSC_Print("Usage: /psc toggledebug - Toggle debug messages")
    -- PSC_Print("Usage: /psc debugevents - Enhanced combat log debugging for 30 seconds")
    -- PSC_Print("Usage: /psc debugpet - Track all pet damage and kills for 60 seconds")
    -- PSC_Print("Usage: /psc simulatedeath [killers] [assists] - Simulate being killed")
    -- PSC_Print("Usage: /psc simcombatlog [killers] [assists] [damage] - Simulate combat log entries for death")
    -- PSC_Print("Usage: /psc deathstats - Show death statistics")
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (PSC_DB.EnableKillAnnounceMessages and "ENABLED" or "DISABLED") .. "."
    PSC_Print(statusMessage)
    PSC_Print("Current kill announce message: " .. PSC_DB.KillAnnounceMessage)
    PSC_Print("Streak ended message: " .. PSC_DB.KillStreakEndedMessage)
    PSC_Print("New streak record message: " .. PSC_DB.NewKillStreakRecordMessage)
    PSC_Print("New multi-kill record message: " .. PSC_DB.NewMultiKillRecordMessage)
    PSC_Print("Multi-kill announcement threshold: " .. PSC_DB.MultiKillThreshold)
    PSC_Print("Record announcements: " .. (PSC_DB.EnableRecordAnnounceMessages and "ENABLED" or "DISABLED"))
    PSC_Print("Battleground Mode: " .. (PSC_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    PSC_Print("Auto BG Detection: " .. (PSC_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    PSC_Print("Manual BG Mode: " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

function PSC_SlashCommandHandler(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" then
        PrintSlashCommandUsage()
    elseif command == "simulatedeath" then
        local killerCount = 1
        local assistCount = 0

        if rest and rest ~= "" then
            local counts = {rest:match("(%d+)%s*(%d*)")}
---@diagnostic disable-next-line: cast-local-type
            if counts[1] then killerCount = tonumber(counts[1]) end
---@diagnostic disable-next-line: cast-local-type
            if counts[2] then assistCount = tonumber(counts[2]) end
        end

        PSC_SimulatePlayerDeathByEnemy(killerCount, assistCount)
    elseif command == "simcombatlog" then
        local killerCount = 1
        local assistCount = 0
        local damageType = "direct"  -- Options: direct, dot, mixed

        if rest and rest ~= "" then
            local parts = {strsplit(" ", rest)}
            if parts[1] then killerCount = tonumber(parts[1]) or 1 end
            if parts[2] then assistCount = tonumber(parts[2]) or 0 end
            if parts[3] then damageType = parts[3] end
        end

        PSC_SimulateCombatLogEvent(killerCount, assistCount, damageType)
    elseif command == "testtrackers" or command == "testdeath" then
        PSC_RunDeathTrackingTests()
    elseif command == "deathstats" then
        PSC_ShowDeathStats()
    elseif command == "status" then
        PrintStatus()
    elseif command == "kills" or command == "stats" then
        PSC_CreateKillsListFrame()
    elseif command == "debug" then
        PSC_ShowDebugInfo()
    elseif command == "toggledebug" then
        PSC_Debug = not PSC_Debug
        PSC_Print("Debug mode " .. (PSC_Debug and "enabled" or "disabled"))
    elseif command == "registerkill" then
        local testKillCount = 1
        if rest and rest ~= "" then
            local count = tonumber(rest)
            if count and count > 0 then
                testKillCount = count
            end
        end
        PSC_SimulatePlayerKills(testKillCount)
    elseif command == "bgmode" then
        PSC_DB.ForceBattlegroundMode = not PSC_DB.ForceBattlegroundMode
        PSC_CheckBattlegroundStatus()
        PSC_Print("Manual Battleground Mode " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
    elseif command == "debugevents" then
        PSC_DebugCombatLogEvents()
    elseif command == "debugpet" then
        PSC_DebugPetKills()
    elseif command == "options" or command == "settings" then
            PSC_CreateConfigUI()
    elseif command == "roleplayer" then
        PSC_CreateRoleplayer()
    else
        PrintSlashCommandUsage()
    end
end
