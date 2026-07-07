local addonName, PVPSC = ...

local function PrintSlashCommandUsage()
    BPP_Print("Usage: /bpp stats - Show PvP statistics")
    BPP_Print("Usage: /bpp history - Show PvP history")
    BPP_Print("Usage: /bpp achievements - Show PvP achievements")
    BPP_Print("Usage: /bpp leaderboard - Show PvP leaderboard")
    BPP_Print("Usage: /bpp sendstats <player name> - Send your stats to a player")
    BPP_Print("Usage: /bpp settings - Open addon settings")

    if BPP_Debug then
        BPP_Print("Debug Commands:")
        BPP_Print("Usage: /bpp registerstreakkill [days] [killsPerDay] [daysAgo] - Generate test streak data")
        BPP_Print("Usage: /bpp timezonetest - Test timezone detection")
        BPP_Print("Usage: /bpp status - Show current settings")
        BPP_Print("Usage: /bpp debug - Show current streak values")
        BPP_Print("Usage: /bpp registerkill [number] - Register test kill(s) for testing")
        BPP_Print("Usage: /bpp registerlevel1kill [number] - Register test level 1 kill(s) for testing")
        BPP_Print("Usage: /bpp registernpckill <NPC name> - Register NPC kill for testing")
        BPP_Print("Usage: /bpp simulatedeath [killers] [assists] - Simulate being killed")
        BPP_Print("Usage: /bpp bgmode - Toggle battleground mode manually")
        BPP_Print("Usage: /bpp toggledebug - Toggle debug messages")
        BPP_Print("Usage: /bpp debugevents - Enhanced combat log debugging for 30 seconds")
        BPP_Print("Usage: /bpp debugpet - Track all pet damage and kills for 60 seconds")
        BPP_Print("Usage: /bpp simulatedeath [killers] [assists] - Simulate being killed")
        BPP_Print("Usage: /bpp simcombatlog [killers] [assists] [damage] - Simulate combat log entries for death")
        BPP_Print("Usage: /bpp deathstats - Show death statistics")
        BPP_Print("Usage: /bpp snapshot [label] - Save stats + achievement progress snapshot to SavedVariables")
    end


end

local function BPP_RegisterNPCKillCommand(arguments)
    if arguments and arguments ~= "" then
        local npcName = strtrim(arguments)
        -- Find matching NPC by name
        local npcID = nil
        for id, name in pairs(BPP_TrackedNPCs) do
            if name == npcName then
                npcID = id
                break
            end
        end

        if npcID then
            BPP_RegisterNPCKill(npcName, npcID)
        else
            BPP_Print("Error: NPC '" .. npcName .. "' not found in tracked NPCs list.")
            BPP_Print("Available NPCs:")
            for id, name in pairs(BPP_TrackedNPCs) do
                BPP_Print("  - " .. name .. " (ID: " .. id .. ")")
            end
        end
    else
        BPP_Print("Usage: /bpp registernpckill <NPC name>")
        BPP_Print("Available NPCs:")
        for id, name in pairs(BPP_TrackedNPCs) do
            BPP_Print("  - " .. name .. " (ID: " .. id .. ")")
        end
    end
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (BPP_DB.EnableKillAnnounceMessages and "ENABLED" or "DISABLED") .. "."
    BPP_Print(statusMessage)
    BPP_Print("Current kill announce message: " .. BPP_DB.KillAnnounceMessage)
    BPP_Print("Streak ended message: " .. BPP_DB.KillStreakEndedMessage)
    BPP_Print("New streak record message: " .. BPP_DB.NewKillStreakRecordMessage)
    BPP_Print("New multi-kill record message: " .. BPP_DB.NewMultiKillRecordMessage)
    BPP_Print("Multi-kill announcement threshold: " .. BPP_DB.MultiKillThreshold)
    BPP_Print("Record announcements: " .. (BPP_DB.EnableRecordAnnounceMessages and "ENABLED" or "DISABLED"))
    BPP_Print("Battleground Mode: " .. (BPP_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    BPP_Print("Auto BG Detection: " .. (BPP_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    BPP_Print("Manual BG Mode: " .. (BPP_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

function BPP_SlashCommandHandler(msg)
    local command, arguments = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "stats" then
        BPP_CreateStatisticsFrame()

    elseif command == "history" then
        BPP_CreateKillsListFrame()

    elseif command == "achievements" then
        BPP_ToggleAchievementFrame()

    elseif command == "leaderboard" or command == "lb" then
        BPP_CreateLeaderboardFrame()

    elseif command == "sendstats" then
        if not arguments or arguments == "" then
            BPP_Print("Usage: /bpp sendstats <player name>")
            return
        end

        local normalized = PVPSC.Network.NormalizeTargetName and PVPSC.Network:NormalizeTargetName(arguments) or strtrim(arguments)
        if not normalized or normalized == "" then
            BPP_Print("Usage: /bpp sendstats <player name>")
            return
        end

        local sent, _, reason = PVPSC.Network:SendStatsToPlayer(normalized)
        if not sent then
            BPP_Print("[PvPStats]: " .. (reason or "Unable to send statistics."))
            return
        end

        BPP_Print("[PvPStats]: Sent stats to " .. normalized .. ". They will only be able to receive them if they have addon version 4.2 or higher.")

    elseif command == "options" or command == "settings" then
        BPP_CreateConfigUI()

    elseif command == "migrate_international_data" then
        BPP_MigratePlayerInfoToEnglish(true)
        -- reload UI
        ReloadUI()

    elseif BPP_Debug then
        if command == "simulatedeath" then
            local killerCount = 1
            local assistCount = 0
            if arguments and arguments ~= "" then
                local counts = {arguments:match("(%d+)%s*(%d*)")}
                if counts[1] then killerCount = tonumber(counts[1]) end
                if counts[2] then assistCount = tonumber(counts[2]) end
            end
            BPP_SimulatePlayerDeathByEnemy(killerCount, assistCount)

        elseif command == "simcombatlog" then
            local killerCount = 1
            local assistCount = 0
            local damageType = "direct"  -- Options: direct, dot, mixed
            if arguments and arguments ~= "" then
                local parts = {strsplit(" ", arguments)}
                if parts[1] then killerCount = tonumber(parts[1]) or 1 end
                if parts[2] then assistCount = tonumber(parts[2]) or 0 end
                if parts[3] then damageType = parts[3] end
            end
            BPP_SimulateCombatLogEvent(killerCount, assistCount, damageType)

        elseif command == "testtrackers" or command == "testdeath" then
            BPP_RunDeathTrackingTests()

        elseif command == "deathstats" then
            BPP_ShowDeathStats()

        elseif command == "status" then
            PrintStatus()

        elseif command == "debug" then
            BPP_ShowDebugInfo()

        elseif command == "registerkill" then
            local testKillCount = 1
            if arguments and arguments ~= "" then
                local count = tonumber(arguments)
                if count and count > 0 then
                    testKillCount = count
                end
            end
            BPP_SimulatePlayerKills(testKillCount)

        elseif command == "registerlevel1kill" then
            local testKillCount = 1
            if arguments and arguments ~= "" then
                local count = tonumber(arguments)
                if count and count > 0 then
                    testKillCount = count
                end
            end
            BPP_SimulateLevel1Kills(testKillCount)

        elseif command == "registernpckill" then
            BPP_RegisterNPCKillCommand(arguments)

        elseif command == "registerstreakkill" then
            local days, killsPerDay, daysAgo = arguments:match("(%d+)%s+(%d+)%s*(%d*)")
            days = tonumber(days) or 7
            killsPerDay = tonumber(killsPerDay) or 10
            daysAgo = tonumber(daysAgo) or nil
            BPP_GenerateStreakTestData(days, killsPerDay, daysAgo)

        elseif command == "bgmode" then
            BPP_DB.ForceBattlegroundMode = not BPP_DB.ForceBattlegroundMode
            BPP_CheckBattlegroundStatus()
            BPP_Print("Manual Battleground Mode " .. (BPP_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))

        elseif command == "debugevents" then
            BPP_DebugCombatLogEvents()

        elseif command == "debugpet" then
            BPP_DebugPetKills()

        elseif command == "timezonetest" then
            BPP_TestTimeZoneOffsetCalculation()

        elseif command == "roleplayer" then
            BPP_CreateRoleplayer()

        elseif command == "snapshot" then
            BPP_CreateDebugSnapshot(arguments ~= "" and arguments or nil)

        elseif command == "testdatamigration" then
            BPP_RunMigrationTests()

        else
            PrintSlashCommandUsage()
        end
    else
        PrintSlashCommandUsage()
    end
end
