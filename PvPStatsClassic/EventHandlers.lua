local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
PSC_MultiKillCount = 0

PSC_KILLSTREAK_MILESTONES = {25, 50, 75, 100, 150, 200, 250, 300}
PSC_CurrentlyInBattleground = false       -- Current BG state
PSC_LastInBattlegroundValue = false

local inCombat = false
local killStreakMilestoneFrame = nil
PKA_Debug = true


local PKA_RecentPetDamage = {}
local PKA_PET_DAMAGE_WINDOW = 0.05

local PKA_RecentPlayerDamage = {}  -- Track recent damage from player to enemies
local PKA_ASSIST_DAMAGE_WINDOW = 30.0  -- 60 second window for assist credit

local PKA_RecentlyCountedKills = {}
local PKA_KILL_TRACKING_WINDOW = 1.0

local killMilestoneFrame = nil
local killMilestoneAutoHideTimer = nil


local function IsPetGUID(guid)
    if not guid then return false end

    -- Classic WoW GUID format: Pet-0-xxxx-xxxx-xxxx-xxxx
    return guid:match("^Pet%-") ~= nil
end

local function GetPetOwnerGUID(petGUID)
    if not petGUID or not IsPetGUID(petGUID) then return nil end

    if UnitExists("pet") and UnitGUID("pet") == petGUID then
        return PSC_PlayerGUID
    end

    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, numMembers do
        local unitID
        if prefix == "party" then
            unitID = (i == GetNumGroupMembers()) and "player" or (prefix..i)
        else
            unitID = prefix..i
        end

        local petID = unitID.."pet"

        if UnitExists(petID) and UnitGUID(petID) == petGUID then
            return UnitGUID(unitID)
        end
    end

    return nil
end

local function GetNameFromGUID(guid)
    if not guid then return nil end

    -- Try to find the name from the GUID
    local name = select(6, GetPlayerInfoByGUID(guid))
    if name then return name end

    -- If that fails, check if it's the player
    if guid == PSC_PlayerGUID then
        return UnitName("player")
    end

    -- Check party/raid members
    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumGroupMembers()
    local prefix = IsInRaid() and "raid" or "party"

    for i = 1, numMembers do
        local unitID
        if prefix == "party" then
            unitID = (i == GetNumGroupMembers()) and "player" or (prefix..i)
        else
            unitID = prefix..i
        end

        if UnitGUID(unitID) == guid then
            return UnitName(unitID)
        end
    end

    return nil
end

function PKA_Print(message)
    local PKA_CHAT_MESSAGE_R = 1.0
    local PKA_CHAT_MESSAGE_G = 1.0
    local PKA_CHAT_MESSAGE_B = 0.74
    DEFAULT_CHAT_FRAME:AddMessage(message, PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
end

local function PrintSlashCommandUsage()
    PKA_Print("Usage: /pka settings - Open settings UI")
    PKA_Print("Usage: /pka stats - Show kills list")
    PKA_Print("Usage: /pka status - Show current settings")
    PKA_Print("Usage: /pka debug - Show current streak values")
    PKA_Print("Usage: /pka registerkill [number] - Register test kill(s) for testing")
    PKA_Print("Usage: /pka bgmode - Toggle battleground mode manually")
    PKA_Print("Usage: /pka toggledebug - Toggle debug messages")
    PKA_Print("Usage: /pka debugevents - Enhanced combat log debugging for 30 seconds")
    PKA_Print("Usage: /pka debugpet - Track all pet damage and kills for 60 seconds")
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (PSC_DB.EnableKillAnnounceMessages and "ENABLED" or "DISABLED") .. "."
    PKA_Print(statusMessage)
    PKA_Print("Current kill announce message: " .. PSC_DB.KillAnnounceMessage)
    PKA_Print("Streak ended message: " .. PSC_DB.KillStreakEndedMessage)
    PKA_Print("New streak record message: " .. PSC_DB.NewKillStreakRecordMessage)
    PKA_Print("New multi-kill record message: " .. PSC_DB.NewMultiKillRecordMessage)
    PKA_Print("Multi-kill announcement threshold: " .. PSC_DB.MultiKillThreshold)
    PKA_Print("Record announcements: " .. (PSC_DB.EnableRecordAnnounceMessages and "ENABLED" or "DISABLED"))
    PKA_Print("Battleground Mode: " .. (PSC_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    PKA_Print("Auto BG Detection: " .. (PSC_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    PKA_Print("Manual BG Mode: " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

local function ShowDebugInfo()
    PKA_Print("Current Kill Streak: " .. PSC_DB.CurrentKillStreak)
    PKA_Print("Highest Kill Streak: " .. PSC_DB.HighestKillStreak)
    PKA_Print("Current Multi-kill Count: " .. PSC_MultiKillCount)
    PKA_Print("Highest Multi-kill: " .. PSC_DB.HighestMultiKill)
    PKA_Print("Multi-kill Announcement Threshold: " .. PSC_DB.MultiKillThreshold)
    PKA_Print("Battleground Mode: " .. (PSC_CurrentlyInBattleground and "ACTIVE" or "INACTIVE"))
    PKA_Print("Auto BG Detection: " .. (PSC_DB.AutoBattlegroundMode and "ENABLED" or "DISABLED"))
    PKA_Print("Manual BG Mode: " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
end

local function InitializeCacheForPlayer(nameWithLevel, englishClass, race, gender, guild, playerLevel)
    if not PSC_DB.PlayerKillCounts[nameWithLevel] then
        local currentZone = GetRealZoneText() or GetSubZoneText() or "Unknown"

        PSC_DB.PlayerKillCounts[nameWithLevel] = {
            kills = 0,
            class = englishClass or "Unknown",
            race = race or "Unknown",
            gender = gender or 1,
            guild = guild or "Unknown",
            lastKill = "",
            playerLevel = playerLevel or -1,
            unknownLevel = false,
            zone = currentZone,
            killLocations = {}, -- Initialize empty array for kill locations
            rank = 0 -- Initialize rank
        }
    end
end

-- Update UpdateKillCacheEntry to include rank
local function UpdateKillCacheEntry(nameWithLevel, race, gender, guild, playerLevel, rank)
    PSC_DB.PlayerKillCounts[nameWithLevel].kills = PSC_DB.PlayerKillCounts[nameWithLevel].kills + 1
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    PSC_DB.PlayerKillCounts[nameWithLevel].lastKill = timestamp
    PSC_DB.PlayerKillCounts[nameWithLevel].playerLevel = playerLevel or -1

    -- Always update rank if provided (even if 0)
    if rank ~= nil then
        PSC_DB.PlayerKillCounts[nameWithLevel].rank = rank
    end

    -- Rest of the function remains the same...
    -- Ensure zone is captured correctly
    local currentZone = GetRealZoneText() or GetSubZoneText() or "Unknown"
    PSC_DB.PlayerKillCounts[nameWithLevel].zone = currentZone

    -- Get current map position
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = nil
    if mapID then
        position = C_Map.GetPlayerMapPosition(mapID, "player")
    end

    -- Create a location record with coordinates
    if mapID and position and position.x and position.y then
        local x = position.x * 100
        local y = position.y * 100

        -- Ensure the killLocations array exists
        PSC_DB.PlayerKillCounts[nameWithLevel].killLocations = PSC_DB.PlayerKillCounts[nameWithLevel].killLocations or {}

        -- Add new location record
        table.insert(PSC_DB.PlayerKillCounts[nameWithLevel].killLocations, {
            timestamp = timestamp,
            zone = currentZone,
            mapID = mapID,
            x = x,
            y = y,
            killNumber = PSC_DB.PlayerKillCounts[nameWithLevel].kills
        })

        -- Debug info
        if PKA_Debug then
            print(string.format("Kill recorded at %s (%.4f, %.4f) in %s",
                timestamp, x, y, currentZone))
        end
    else
        -- Log error if we couldn't get position
        if PKA_Debug then
            print("Failed to get player position for kill location")
        end
    end

    -- Update other player information if available
    if race and race ~= "Unknown" then PSC_DB.PlayerKillCounts[nameWithLevel].race = race end
    if gender and gender ~= "Unknown" then PSC_DB.PlayerKillCounts[nameWithLevel].gender = gender end
    if guild and guild ~= "" then PSC_DB.PlayerKillCounts[nameWithLevel].guild = guild end
end

local function UpdateKillStreak()
    PSC_DB.CurrentKillStreak = PSC_DB.CurrentKillStreak + 1

    if PSC_DB.CurrentKillStreak > PSC_DB.HighestKillStreak then
        PSC_DB.HighestKillStreak = PSC_DB.CurrentKillStreak

        if PSC_DB.HighestKillStreak > 1 then
            print("New kill streak personal best: " .. PSC_DB.HighestKillStreak .. "!")

            if PSC_DB.HighestKillStreak >= 10 and PSC_DB.HighestKillStreak % 5 == 0 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
                local newRecordMsg = string.gsub(PSC_DB.NewKillStreakRecordMessage , "STREAKCOUNT", PSC_DB.HighestKillStreak)
                SendChatMessage(newRecordMsg, "PARTY")
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
        "PENTA KILL!"
    }

    if count <= 5 then
        return killTexts[count - 1]
    end

    return "Multi-kill of " .. count
end

local function UpdateMultiKill()
    if UnitAffectingCombat("player") then
        if not inCombat then
            inCombat = true
        end

        PSC_MultiKillCount = PSC_MultiKillCount + 1
    else
        PSC_MultiKillCount = 1
        inCombat = false
    end

    -- Play sound based on kill count if enabled
    if PSC_DB.EnableMultiKillSounds then
        local soundFile
        if PSC_MultiKillCount == 2 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\double_kill.mp3"
        elseif PSC_MultiKillCount == 3 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\triple_kill.mp3"
        elseif PSC_MultiKillCount == 4 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\quadra_kill.mp3"
        elseif PSC_MultiKillCount == 5 then
            soundFile = "Interface\\AddOns\\PvPStatsClassic\\sounds\\penta_kill.mp3"
        end

        if soundFile then
            PlaySoundFile(soundFile, "Master")
        end
    end

    if PSC_MultiKillCount > PSC_DB.HighestMultiKill then
        PSC_DB.HighestMultiKill = PSC_MultiKillCount

        if PSC_DB.HighestMultiKill > 1 then
            print("NEW MULTI-KILL RECORD: " .. PSC_DB.HighestMultiKill .. "!")

            if PSC_DB.HighestMultiKill >= 3 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
                local newMultiKillMsg = string.gsub(PSC_DB.NewMultiKillRecordMessage, "MULTIKILLTEXT", GetMultiKillText(PSC_DB.HighestMultiKill))
                SendChatMessage(newMultiKillMsg, "PARTY")
            end
        end
    end
end

local function AnnounceKill(killedPlayer, level, nameWithLevel)
    -- Don't announce in battleground mode or if announcements are disabled
    if PSC_CurrentlyInBattleground or not PSC_DB.EnableKillAnnounceMessages or not IsInGroup() then return end

    local killMessage = string.gsub(PSC_DB.KillAnnounceMessage, "Enemyplayername", killedPlayer)

    local playerLevel = UnitLevel("player")
    local levelDifference = level - playerLevel
    local levelDisplay = level == -1 and "??" or tostring(level)

    if level == -1 or (level > 0 and levelDifference >= 6) then
        killMessage = killMessage .. " (Level " .. levelDisplay .. ")"
    end

    if PSC_DB.PlayerKillCounts[nameWithLevel].kills >= 2 then
        killMessage = killMessage .. " x" .. PSC_DB.PlayerKillCounts[nameWithLevel].kills
    end

    if PSC_DB.CurrentKillStreak >= 10 and PSC_DB.CurrentKillStreak % 5 == 0 then
        killMessage = killMessage .. " - Kill Streak: " .. PSC_DB.CurrentKillStreak
    end

    SendChatMessage(killMessage, "PARTY")

    if PSC_MultiKillCount >= PSC_DB.MultiKillThreshold then
        SendChatMessage(GetMultiKillText(PSC_MultiKillCount), "PARTY")
    end
end

local function CreateKillDebugMessage(playerName, level, englishClass, race, nameWithLevel, killerGUID, killerName)
    local debugMsg = "Killed: " .. playerName

    local playerLevel = UnitLevel("player")
    local levelDifference = level > 0 and (level - playerLevel) or 0
    if level == -1 or (level > 0 and levelDifference >= 5) then
        debugMsg = debugMsg .. " (Level " .. (level == -1 and "??" or level)
    else
        debugMsg = debugMsg .. " ("
    end

    debugMsg = debugMsg .. englishClass .. ", " .. race .. ")"

    -- Add rank info to debug message
    local rank = PSC_DB.PlayerKillCounts[nameWithLevel].rank or 0
    if rank > 0 then
        debugMsg = debugMsg .. " [Rank: " .. rank .. "]"
    end

    debugMsg = debugMsg .. " - Total kills: " .. PSC_DB.PlayerKillCounts[nameWithLevel].kills
    debugMsg = debugMsg .. " - Current streak: " .. PSC_DB.CurrentKillStreak
    debugMsg = debugMsg .. " - Zone: " .. (PSC_DB.PlayerKillCounts[nameWithLevel].zone or "Unknown")

    -- Check what kind of kill this was
    if killerGUID and IsPetGUID(killerGUID) then
        debugMsg = debugMsg .. " - Kill by: Your Pet (" .. (killerName or "Unknown") .. ")"
    elseif killerName == "Assist" then
        debugMsg = debugMsg .. " - Assist Kill (mob/environment finished target)"
    end

    if PSC_MultiKillCount >= 2 then
        debugMsg = debugMsg .. " - " .. GetMultiKillText(PSC_MultiKillCount)
    end

    return debugMsg
end

local function IsKillStreakMilestone(count)
    for _, milestone in ipairs(PSC_KILLSTREAK_MILESTONES) do
        if count == milestone then
            return true
        end
    end
    return false
end

local function SetupKillstreakMilestoneAnimation(frame, duration)
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
    fadeIn:SetDuration(0.01)
    fadeIn:SetOrder(1)

    local hold = animGroup:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(duration)
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

local function CreateKillstreakMilestoneFrameIfNeeded()
    if killStreakMilestoneFrame then return killStreakMilestoneFrame end

    local frame = CreateFrame("Frame", "PKA_MilestoneFrame", UIParent)
    frame:SetSize(400, 200)
    frame:SetPoint("TOP", 0, -60)
    frame:SetFrameStrata("HIGH")

    local icon = frame:CreateTexture("PKA_MilestoneIcon", "ARTWORK")
    icon:SetSize(200, 200)
    icon:SetPoint("TOP", 0, 0)
    icon:SetTexture("Interface\\AddOns\\PvPStatsClassic\\img\\RedridgePoliceLogo.blp")
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

local function PlayKillstreakMilestoneSound()
    PlaySound(8454) -- Warsong horde win sound
    PlaySound(8574) -- Cheer sound
end

local function ShowKillStreakMilestone(killCount)
    if not IsKillStreakMilestone(killCount) then
        return
    end

    local frame = CreateKillstreakMilestoneFrameIfNeeded()

    frame.text:SetText(killCount .. " KILL STREAK")

    frame:Show()
    frame:SetAlpha(0)

    local animGroup = SetupKillstreakMilestoneAnimation(frame, 9.0)
    PlayKillstreakMilestoneSound()
    DoEmote("CHEER")
    animGroup:Play()
end

local function RegisterPlayerKill(playerName, level, englishClass, race, gender, guild, killerGUID, killerName, rank)
    local playerLevel = UnitLevel("player")
    local nameWithLevel = playerName .. ":" .. level

    UpdateKillStreak()
    ShowKillStreakMilestone(PSC_DB.CurrentKillStreak)
    InitializeCacheForPlayer(nameWithLevel, englishClass, race, gender, guild, playerLevel)
    UpdateKillCacheEntry(nameWithLevel, race, gender, guild, playerLevel, rank)
    UpdateMultiKill()
    AnnounceKill(playerName, level, nameWithLevel)

    -- Print debug message using the new function
    if PKA_Debug then
        local debugMsg = CreateKillDebugMessage(playerName, level, englishClass, race, nameWithLevel, killerGUID, killerName)
        print(debugMsg)
    end

    -- Get the kill count before showing milestone
    local killCount = PSC_DB.PlayerKillCounts[nameWithLevel].kills

    -- Only show milestone if it's not the first kill or if first kill milestones are enabled
    if not (killCount == 1 and PSC_DB.ShowMilestoneForFirstKill) then
        PKA_ShowKillMilestone(playerName, level, englishClass, race, gender, guild, rank, killCount)
    end
end

local function SimulatePlayerDeath()
    PKA_Print("Simulating player death...")

    if PSC_DB.CurrentKillStreak >= 10 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
        local streakEndedMsg = string.gsub(PSC_DB.KillStreakEndedMessage, "STREAKCOUNT", PSC_DB.CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    PSC_DB.CurrentKillStreak = 0
    PSC_MultiKillCount = 0
    inCombat = false
    PKA_Print("Death simulated! Kill streak reset.")
end

local function SimulatePlayerKills(killCount)
    PKA_Print("Registering " .. killCount .. " random test kill(s)...")

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

        -- Generate random rank (0-14)
        -- Higher chance for lower ranks, lower chance for high ranks
        local rankChance = math.random(100)
        local randomRank = 0

        if rankChance <= 40 then
            -- 40% chance for rank 0 (no rank)
            randomRank = 0
        elseif rankChance <= 70 then
            -- 30% chance for ranks 1-4 (Private to Master Sergeant)
            randomRank = math.random(1, 4)
        elseif rankChance <= 90 then
            -- 20% chance for ranks 5-8 (Sergeant Major to Knight-Captain)
            randomRank = math.random(5, 8)
        elseif rankChance <= 98 then
            -- 8% chance for ranks 9-12 (Knight-Champion to Marshal)
            randomRank = math.random(9, 12)
        else
            -- 2% chance for ranks 13-14 (Field Marshal and Grand Marshal)
            randomRank = math.random(13, 14)
        end

        -- Temporarily override GetRealZoneText to return our random zone
        local originalGetRealZoneText = GetRealZoneText
        GetRealZoneText = function() return randomZone end

        local randomX = 10.0 + (90.0 - 10.0) * math.random()
        local randomY = 10.0 + (90.0 - 10.0) * math.random()

        -- Override C_Map.GetPlayerMapPosition for this simulation
        local originalGetPlayerMapPosition = C_Map.GetPlayerMapPosition
---@diagnostic disable-next-line: duplicate-set-field
        C_Map.GetPlayerMapPosition = function(mapID, unit)
            return {x = randomX/100, y = randomY/100}
        end

        -- Register the kill with random data including rank
        RegisterPlayerKill(randomName, randomLevel, randomClass, randomRace, randomGender, randomGuild, nil, nil, randomRank)

        -- Restore the original functions
        C_Map.GetPlayerMapPosition = originalGetPlayerMapPosition
        GetRealZoneText = originalGetRealZoneText
    end

    PKA_Print("Successfully registered " .. killCount .. " random test kill(s).")
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
        PKA_Print("Debug mode " .. (PKA_Debug and "enabled" or "disabled"))
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
        PSC_DB.ForceBattlegroundMode = not PSC_DB.ForceBattlegroundMode
        PKA_CheckBattlegroundStatus()
        PKA_Print("Manual Battleground Mode " .. (PSC_DB.ForceBattlegroundMode and "ENABLED" or "DISABLED"))
    elseif command == "debugevents" then
        PKA_DebugCombatLogEvents()
    elseif command == "debugpet" then
        PKA_DebugPetKills()
    elseif command == "options" or command == "settings" then
            PKA_CreateConfigUI()
    else
        PrintSlashCommandUsage()
    end
end

local function OnPlayerTargetChanged()
    PKA_StorePlayerInfo("target")
    PKA_StorePlayerInfo("targettarget")
end

local function OnUpdateMouseoverUnit()
    PKA_StorePlayerInfo("mouseover")
end

local function HandleCombatState(inCombatNow)
    if inCombat and not inCombatNow then
        PSC_MultiKillCount = 0
        inCombat = false
    elseif not inCombat and inCombatNow then
        PSC_MultiKillCount = 0
        inCombat = true
    end
end

local function HandlePlayerDeath()
    if PSC_DB.CurrentKillStreak >= 10 and PSC_DB.EnableRecordAnnounceMessages and IsInGroup() then
        local streakEndedMsg = string.gsub(PSC_DB.KillStreakEndedMessage, "STREAKCOUNT", PSC_DB.CurrentKillStreak)
        SendChatMessage(streakEndedMsg, "PARTY")
    end

    PSC_DB.CurrentKillStreak = 0
    PSC_MultiKillCount = 0
    inCombat = false
    print("You died! Kill streak reset.")
end

local function ProcessEnemyPlayerDeath(destName, sourceGUID, sourceName)
    local level, englishClass, race, gender, guild, rank = PSC_GetPlayerInfoFromCache(destName)

    if race == "Unknown" or gender == "Unknown" or englishClass == "Unknown" then
        if PKA_Debug then
            print("Kill of " .. destName .. " not counted (incomplete data: " ..
                (race == "Unknown" and "race" or "") ..
                (gender == "Unknown" and (race == "Unknown" and ", gender" or "gender") or "") ..
                (englishClass == "Unknown" and ((race == "Unknown" or gender == "Unknown") and ", class" or "class") or "") ..
                " unknown)")
        end
        return
    end

    RegisterPlayerKill(destName, level, englishClass, race, gender, guild, sourceGUID, sourceName, rank)
end

local function CleanupRecentPetDamage()
    local now = GetTime()
    local cutoff = now - PKA_PET_DAMAGE_WINDOW

    for guid, info in pairs(PKA_RecentPetDamage) do
        if info.timestamp < cutoff then
            PKA_RecentPetDamage[guid] = nil
        end
    end
end

-- Add this function to record pet damage
local function RecordPetDamage(petGUID, petName, targetGUID, amount)
    if not petGUID or not targetGUID then return end

    local ownerGUID = GetPetOwnerGUID(petGUID)
    if not ownerGUID then return end

    PKA_RecentPetDamage[targetGUID] = {
        timestamp = GetTime(),
        petGUID = petGUID,
        petName = petName,
        ownerGUID = ownerGUID,
        amount = amount or 0
    }

    -- if PKA_Debug then
    --     local playerGUID = PlayerGUID
    --     if ownerGUID == playerGUID then
    --         print("Recorded damage from your pet to: " .. targetName)
    --     end
    -- end
end


local function CombatLogDestFlagsEnemyPlayer(destFlags)
    return true
    -- return bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 and
    --        bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
end


local function CleanupRecentlyCountedKillsDict()
    local now = GetTime()
    local cutoff = now - PKA_KILL_TRACKING_WINDOW
    for guid, timestamp in pairs(PKA_RecentlyCountedKills) do
        if timestamp < cutoff then
            PKA_RecentlyCountedKills[guid] = nil
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

        -- Only record if there was actual damage
        if damageAmount > 0 then
            RecordPetDamage(sourceGUID, sourceName, destGUID, damageAmount)
        end
    end
end

local function RecordPlayerDamage(sourceGUID, sourceName, targetGUID, targetName, amount)
    if not sourceGUID or not targetGUID then return end

    -- Only track the player's own damage
    if sourceGUID ~= PSC_PlayerGUID then return end

    -- Get existing record or create new one
    local existingRecord = PKA_RecentPlayerDamage[targetGUID] or {
        timestamp = 0,
        totalDamage = 0
    }

    -- Update with new damage information
    existingRecord.timestamp = GetTime()
    existingRecord.totalDamage = existingRecord.totalDamage + amount

    -- Store the updated record
    PKA_RecentPlayerDamage[targetGUID] = existingRecord

    if PKA_Debug then
        print(string.format("You dealt %d damage to %s", amount, targetName))
    end
end

local function HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, param1, param4)
    -- Only track player damage to enemy players
    if sourceGUID ~= PSC_PlayerGUID then return end

    local damageAmount = param1 or param4 or 0
    if damageAmount <= 0 then return end

     RecordPlayerDamage(sourceGUID, sourceName, destGUID, destName, damageAmount)
end

local function HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)
    if sourceGUID ~= PSC_PlayerGUID then return end

    local damageAmount = 0

    if combatEvent == "SWING_DAMAGE" then
        damageAmount = param1 or 0
    elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_PERIODIC_DAMAGE" then
        damageAmount = param4 or 0
    elseif combatEvent == "RANGE_DAMAGE" then
        damageAmount = param4 or 0
    end

    -- Only process damage to enemy players
    if damageAmount > 0 then
        HandlePlayerDamageEvent(sourceGUID, sourceName, destGUID, destName, damageAmount, nil)
    end
end

-- Add this function to clean up old damage records
local function CleanupRecentPlayerDamage()
    local now = GetTime()
    local cutoff = now - PKA_ASSIST_DAMAGE_WINDOW

    for guid, info in pairs(PKA_RecentPlayerDamage) do
        if info.timestamp < cutoff then
            PKA_RecentPlayerDamage[guid] = nil
        end
    end
end

local function HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    local countKill = false

    -- print("Party Kill Event: " .. sourceName .. " (" .. sourceGUID .. ") killed " .. destName .. " (" .. destGUID .. ")")
    if PSC_CurrentlyInBattleground then
        if sourceGUID == PSC_PlayerGUID then
            countKill = true
            if PKA_Debug then print("BG Mode: Player killing blow") end
        else
            if PKA_Debug then print("BG Mode: Party/Raid member killing blow ignored") end
        end
    else
        if sourceGUID == PSC_PlayerGUID then
            countKill = true
            if PKA_Debug then print("Normal Mode: Player killing blow") end
        elseif UnitInParty(sourceName) or UnitInRaid(sourceName) then
            countKill = true
            if PKA_Debug then print("Normal Mode: Party/Raid member killing blow") end
        end
    end

    if countKill then
        PKA_RecentlyCountedKills[destGUID] = GetTime()
        ProcessEnemyPlayerDeath(destName, sourceGUID, sourceName)
    end
end

local function HandleUnitDiedEvent(destGUID, destName)
    if PKA_RecentlyCountedKills[destGUID] then
        if PKA_Debug then
            print("Skipping duplicate kill for: " .. destName)
        end
        return
    end

    local countKill = false

    -- Check if this player was recently damaged by a pet
    local petDamage = PKA_RecentPetDamage[destGUID]

    if petDamage and (GetTime() - petDamage.timestamp) <= PKA_PET_DAMAGE_WINDOW then
        -- In BG mode, only count the player's own pet kills
        if PSC_CurrentlyInBattleground then
            if petDamage.ownerGUID == PSC_PlayerGUID then
                countKill = true
                if PKA_Debug then
                    print("BG Mode: Pet killing blow detected (via recent damage)")
                    print("Pet: " .. (petDamage.petName or "Unknown"))
                end
            else
                if PKA_Debug then print("BG Mode: Pet killing blow ignored (not your pet)") end
            end
        -- In normal mode, also accept party/raid member pets
        else
            if petDamage.ownerGUID == PSC_PlayerGUID then
                countKill = true
                if PKA_Debug then
                    print("Normal Mode: Your pet killing blow detected")
                end
            else
                -- Check if owner is in party/raid
                local ownerName = GetNameFromGUID(petDamage.ownerGUID)
                if ownerName and (UnitInParty(ownerName) or UnitInRaid(ownerName)) then
                    countKill = true
                    if PKA_Debug then
                        print("Normal Mode: Party/raid member's pet kill detected")
                    end
                end
            end
        end

        if countKill then
            PKA_RecentlyCountedKills[destGUID] = GetTime()
            ProcessEnemyPlayerDeath(destName, petDamage.petGUID, petDamage.petName)
            PKA_RecentPetDamage[destGUID] = nil  -- Clear the record after processing
        end
    end

    if countKill then return end

    -- If not a pet kill, check for assist kill
    local playerDamage = PKA_RecentPlayerDamage[destGUID]
    if playerDamage and (GetTime() - playerDamage.timestamp) <= PKA_ASSIST_DAMAGE_WINDOW then
        -- Check if enough damage was done for assist credit
        if playerDamage.totalDamage > 0 then
            if PKA_Debug then
                print("Assist kill detected for: " .. destName)
            end

            PKA_RecentlyCountedKills[destGUID] = GetTime()
            ProcessEnemyPlayerDeath(destName, nil, "Assist")
            PKA_RecentPlayerDamage[destGUID] = nil  -- Clear the record after processing
        end
    end
end

-- Replace the HandleCombatLogEvent function with this updated version
local function HandleCombatLogEvent()
    local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4 = CombatLogGetCurrentEventInfo()

    if CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandleComatLogEventPetDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, param1, param4)
        HandleCombatLogPlayerDamage(combatEvent, sourceGUID, sourceName, destGUID, destName, destFlags, param1, param4)  -- Add this line
    end

    if combatEvent == "PARTY_KILL" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandlePartyKillEvent(sourceGUID, sourceName, destGUID, destName)
    end

    if combatEvent == "UNIT_DIED" and CombatLogDestFlagsEnemyPlayer(destFlags) then
        HandleUnitDiedEvent(destGUID, destName)
    end
end


function PSC_RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    playerKillAnnounceFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_DEAD")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGOUT")
    playerKillAnnounceFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            print("PSC_DB: " .. tostring(PSC_DB == nil))
            if not PSC_DB then
                PSC_InitializeDefaults()
            end
            PSC_UpdateMinimapButtonPosition()
            PKA_SetupTooltip() -- Add this line to call the tooltip setup
            inCombat = UnitAffectingCombat("player")
            PKA_CheckBattlegroundStatus()  -- Check BG status on login/reload
            if UnitIsDeadOrGhost("player") then
                HandlePlayerDeath()
            end
            PSC_PlayerGUID = UnitGUID("player")
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
            CleanupRecentlyCountedKillsDict()
            CleanupRecentPlayerDamage()
        elseif event == "PLAYER_LOGOUT" then
            PKA_CleanupDatabase()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            PKA_CheckBattlegroundStatus()  -- Check BG status on zone change
        end
    end)
end

-- Add after the RegisterEvents function
function PKA_CheckBattlegroundStatus()
    if PSC_DB.ForceBattlegroundMode then
        PSC_CurrentlyInBattleground = true
    end

    local currentZone = GetRealZoneText() or ""
    local battlegroundZones = {
        "Warsong Gulch",
        "Arathi Basin",
        "Alterac Valley",
        "Elwynn Forest",
        "Duskwood"
    }

    for _, bgName in ipairs(battlegroundZones) do
        if (currentZone == bgName) then
            if PKA_Debug and not PSC_LastInBattlegroundValue then
                print("PvPStatsClassic: Entered battleground. Only your own killing blows will be tracked.")
            end
            PSC_CurrentlyInBattleground = true
            PSC_LastInBattlegroundValue = true
            return
        end
    end

    if PKA_Debug and PSC_LastInBattlegroundValue then
        print("PvPStatsClassic: Left battleground. Normal kill tracking active.")
    end
    PSC_LastInBattlegroundValue = false
    PSC_CurrentlyInBattleground = false
end


-- Add this function near your other debug functions
function PKA_DebugCombatLogEvents()
    print("Enabling enhanced combat log debugging for 30 seconds...")

    -- Store the original combat log handler
    local originalHandler = HandleCombatLogEvent

    -- Replace with our debug version temporarily
    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()

        -- Print out kill-related events
        if (combatEvent == "UNIT_DIED" or combatEvent == "PARTY_KILL") and
           bit.band(destFlags or 0, COMBATLOG_OBJECT_TYPE_PLAYER or 0) > 0 then
            print("EVENT: " .. combatEvent)
            print("SOURCE: " .. (sourceName or "nil") .. " (" .. (sourceGUID or "nil") .. ")")
            print("TARGET: " .. (destName or "nil") .. " (" .. (destGUID or "nil") .. ")")
            print("FLAGS: source=" .. (sourceFlags or 0) .. ", dest=" .. (destFlags or 0))
            print("-----------------------------------")
        end

        -- Still call the original handler
        originalHandler()
    end

    -- Reset after 30 seconds
    C_Timer.After(30, function()
        print("Combat log debugging ended.")
        HandleCombatLogEvent = originalHandler
    end)
end

-- Add this function and command to detect all pet damage and kills
function PKA_DebugPetKills()
    print("Enabling pet kill debugging for 120 seconds...")

    -- Store the original combat log handler
    local originalHandler = HandleCombatLogEvent

    -- Replace with our debug version temporarily
    HandleCombatLogEvent = function()
        local timestamp, combatEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
              destGUID, destName, destFlags, destRaidFlags, param1, param2, param3, param4 = CombatLogGetCurrentEventInfo()

        -- Call the original handler first
        originalHandler()

        -- Track all pet damage events
        if IsPetGUID(sourceGUID) then
            local ownerGUID = GetPetOwnerGUID(sourceGUID)

            if ownerGUID == PSC_PlayerGUID then
                -- Log all pet damage events
                if combatEvent:find("_DAMAGE") or combatEvent == "SWING_DAMAGE" then
                    local amount = combatEvent == "SWING_DAMAGE" and param1 or (combatEvent == "SPELL_DAMAGE" and param4 or 0)

                    print("Pet damage to " .. destName .. ": " .. amount .. " damage")

                    -- Check current health if it's your target
                    if UnitExists("target") and UnitGUID("target") == destGUID then
                        print("Target health: " .. UnitHealth("target") .. "/" .. UnitHealthMax("target"))
                        if UnitHealth("target") <= 0 then
                            print("Target appears to be DEAD!")
                        end
                    end
                end
            end
        end

        -- Track UNIT_DIED events for any mob your pet damaged
        if combatEvent == "UNIT_DIED" then
            local petDamage = PKA_RecentPetDamage[destGUID]
            if petDamage then
                print("*** DEATH DETECTED - " .. destName .. " ***")
                print("This target was damaged by your pet " .. (petDamage.petName or "Unknown") ..
                      " " .. string.format("%.6f", GetTime() - petDamage.timestamp) .. " seconds ago")

                if CombatLogDestFlagsEnemyPlayer(destFlags) then
                    print("This was an enemy player kill!")
                else
                    print("This was NOT an enemy player")
                end
            end
        end
    end

    -- Reset after 120 seconds
    C_Timer.After(120, function()
        print("Pet kill debugging ended.")
        HandleCombatLogEvent = originalHandler
    end)
end

-- Add this function after PKA_LoadSettings but before RegisterEvents

function PKA_SetupTooltip()
    -- Helper function to check if a kills line already exists in the tooltip
    local function HasKillsLineInTooltip(tooltip)
        for i = 1, tooltip:NumLines() do
            local line = _G[tooltip:GetName() .. "TextLeft" .. i]
            if line and line:GetText() and line:GetText():find("^Kills: ") then
                return true
            end
        end
        return false
    end

    -- Helper function to add kills to tooltip if not already present
    local function AddKillsToTooltip(tooltip, kills)
        if not HasKillsLineInTooltip(tooltip) then
            tooltip:AddLine("Kills: " .. kills, 1, 1, 1)
            tooltip:Show() -- Force refresh to show the new line
        end
    end

    -- Helper function to get kills for a player by name (checking all level entries)
    local function GetKillsByPlayerName(playerName)
        for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
            local storedName = nameWithLevel:match("^(.+):")
            if storedName == playerName then
                return data.kills
            end
        end
        return 0
    end

    -- Handle live player tooltips
    local function OnTooltipSetUnit(tooltip)
        -- Check if tooltip info is enabled
        if not PSC_DB.ShowTooltipKillInfo then return end

        -- Get unit from tooltip
        local name, unit = tooltip:GetUnit()
        if not unit then return end

        -- Only continue for enemy players
        if not UnitIsPlayer(unit) or UnitIsFriend("player", unit) then return end

        -- Get the player's name and level for lookup
        local playerName = UnitName(unit)
        local playerLevel = UnitLevel(unit)
        local nameWithLevel = playerName .. ":" .. playerLevel

        -- Find kill count in our database
        local kills = 0
        if PSC_DB.PlayerKillCounts[nameWithLevel] then
            kills = PSC_DB.PlayerKillCounts[nameWithLevel].kills
        end

        AddKillsToTooltip(tooltip, kills)
    end

    -- Handle corpse tooltips
    local function OnTooltipShow(tooltip)
        if not tooltip:IsShown() then return end

        local line1 = _G[tooltip:GetName().."TextLeft1"]
        if not line1 then return end

        local text = line1:GetText()
        if not text or not text:find("^Corpse of ") then return end

        -- Extract player name
        local playerName = text:match("^Corpse of (.+)$")
        if not playerName then return end

        -- Look up player in our database (check at all levels)
        local kills = GetKillsByPlayerName(playerName)

        if kills > 0 then
            AddKillsToTooltip(tooltip, kills)
        end
    end

    -- Hook into various tooltip events for better coverage
    GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)
    GameTooltip:HookScript("OnShow", OnTooltipShow)

    -- The OnTooltipCleared event might fire too early, so we also use a small timer
    GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
        C_Timer.After(0.01, function()
            if tooltip:IsShown() then
                OnTooltipShow(tooltip)
            end
        end)
    end)
end

-- Helper function to get PvP rank name based on rank number and faction
function PKA_GetRankName(rank, faction)
    if not rank or rank <= 0 then
        return nil
    end

    faction = faction or UnitFactionGroup("player") or "Alliance"

    local rankNames = {
        Alliance = {
            [1] = "Private",
            [2] = "Corporal",
            [3] = "Sergeant",
            [4] = "Master Sergeant",
            [5] = "Sergeant Major",
            [6] = "Knight",
            [7] = "Knight-Lieutenant",
            [8] = "Knight-Captain",
            [9] = "Knight-Champion",
            [10] = "Lieutenant Commander",
            [11] = "Commander",
            [12] = "Marshal",
            [13] = "Field Marshal",
            [14] = "Grand Marshal"
        },
        Horde = {
            [1] = "Scout",
            [2] = "Grunt",
            [3] = "Sergeant",
            [4] = "Senior Sergeant",
            [5] = "First Sergeant",
            [6] = "Stone Guard",
            [7] = "Blood Guard",
            [8] = "Legionnaire",
            [9] = "Centurion",
            [10] = "Champion",
            [11] = "Lieutenant General",
            [12] = "General",
            [13] = "Warlord",
            [14] = "High Warlord"
        }
    }

    local factionTable = rankNames[faction] or rankNames["Alliance"]
    return factionTable[rank] or ("Rank " .. rank)
end


-- Function to create and set up the Kill Milestone frame
local function PKA_CreateKillMilestoneFrame()
    if killMilestoneFrame then return killMilestoneFrame end

    -- Create the main frame
    local milestoneFrame = CreateFrame("Frame", "PKA_KillMilestoneFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    milestoneFrame:SetSize(200, 82)  -- Base size - will be adjusted dynamically
    milestoneFrame:SetPoint("TOP", UIParent, "TOP", 0, -100)  -- Initial position
    milestoneFrame:SetFrameStrata("MEDIUM")
    milestoneFrame:SetMovable(true)
    milestoneFrame:EnableMouse(true)
    milestoneFrame:SetClampedToScreen(true)

    -- Create backdrop for Classic compatibility
    local backdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    }

    -- Apply backdrop using the appropriate method for the client version
    if milestoneFrame.SetBackdrop then
        milestoneFrame:SetBackdrop(backdrop)
    else
        -- Create background texture
        local bg = milestoneFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture(backdrop.bgFile)
---@diagnostic disable-next-line: param-type-mismatch
        bg:SetAllPoints(milestoneFrame)
        bg:SetTexCoord(0, 1, 0, 1)

        -- Create border textures (simplified approach)
        local border = milestoneFrame:CreateTexture(nil, "BORDER")
        border:SetTexture(backdrop.edgeFile)
        border:SetPoint("TOPLEFT", milestoneFrame, "TOPLEFT", -backdrop.edgeSize/2, backdrop.edgeSize/2)
        border:SetPoint("BOTTOMRIGHT", milestoneFrame, "BOTTOMRIGHT", backdrop.edgeSize/2, -backdrop.edgeSize/2)
    end

    -- Make it draggable
    milestoneFrame:RegisterForDrag("LeftButton")
    milestoneFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    milestoneFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position for future sessions
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        PlayerKillAnnounceDB.MilestoneFramePosition = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    -- Title
    local title = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", milestoneFrame, "TOP", 0, -15)
    title:SetText("Kill Milestone")
    title:SetTextColor(1, 0.82, 0)
    milestoneFrame.title = title

    -- Define left margin for consistent spacing
    local leftMargin = 20

    -- Class icon
    local classIcon = milestoneFrame:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(24, 24)
    classIcon:SetPoint("TOPLEFT", milestoneFrame, "TOPLEFT", leftMargin, -30)
    milestoneFrame.classIcon = classIcon

    -- Player name
    local nameText = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", 5, 0)
    nameText:SetJustifyH("LEFT")
    milestoneFrame.nameText = nameText

    -- Level and rank - aligned left like the player name
    local levelText = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    levelText:SetTextColor(0.8, 0.8, 0.8)
    levelText:SetJustifyH("LEFT")  -- Explicit left justification
    milestoneFrame.levelText = levelText

    -- Kill count - aligned left like the others
    local killText = milestoneFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killText:SetPoint("TOPLEFT", levelText, "BOTTOMLEFT", 0, -2)
    killText:SetTextColor(1, 0.82, 0) -- Gold color
    killText:SetJustifyH("LEFT")
    milestoneFrame.killText = killText

    -- Close button
    local close = CreateFrame("Button", nil, milestoneFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", milestoneFrame, "TOPRIGHT", -5, -5)
    close:SetSize(20, 20)
    close:SetScript("OnClick", function()
        milestoneFrame:Hide()
        if killMilestoneAutoHideTimer then
            killMilestoneAutoHideTimer:Cancel()
            killMilestoneAutoHideTimer = nil
        end
    end)

    milestoneFrame:Hide()
    killMilestoneFrame = milestoneFrame
    return milestoneFrame
end

-- Function to update and show the milestone frame
function PKA_ShowKillMilestone(playerName, level, englishClass, race, gender, guild, rank, killCount, faction)
    if not PSC_DB.ShowKillMilestones then return end

    if not PSC_DB.ShowMilestoneForFirstKill and killCount == 1 then return end

    local milestoneFrame = PKA_CreateKillMilestoneFrame()

    -- Update position if saved
    if PlayerKillAnnounceDB and PlayerKillAnnounceDB.MilestoneFramePosition then
        local pos = PlayerKillAnnounceDB.MilestoneFramePosition
        milestoneFrame:ClearAllPoints()
        milestoneFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    end

    -- Only show for milestone kills (1st, or every X kills based on interval)
    if killCount ~= 1 and killCount % PSC_DB.KillMilestoneInterval ~= 0 then
        return
    end

    -- Set class icon
    local classIconCoords = CLASS_ICON_TCOORDS[englishClass or "WARRIOR"]
    if classIconCoords then
        milestoneFrame.classIcon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        milestoneFrame.classIcon:SetTexCoord(unpack(classIconCoords))
    else
        milestoneFrame.classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Set name with color by class
    local classColor = RAID_CLASS_COLORS[englishClass] or RAID_CLASS_COLORS["WARRIOR"]
    milestoneFrame.nameText:SetText(playerName)
    milestoneFrame.nameText:SetTextColor(classColor.r, classColor.g, classColor.b)

    -- Get rank name if applicable
    local rankName = nil
    if rank and rank > 0 then
        rankName = PKA_GetRankName(rank, faction)
    end

    -- Set level and rank if applicable
    local levelString = "Level " .. (level > 0 and level or "??")
    if rankName then
        levelString = levelString .. " - " .. rankName
    end
    milestoneFrame.levelText:SetText(levelString)

    -- Set kill message
    local killMessage
    if killCount == 1 then
        killMessage = "1st kill!"
    else
        killMessage = killCount .. "th kill!"
    end
    milestoneFrame.killText:SetText(killMessage)

    -- Calculate required width for content
    -- 1. Get the text width of the level string (most likely to be longest)
    milestoneFrame.levelText:SetWidth(0) -- Reset width constraint to get natural width
    local levelTextWidth = milestoneFrame.levelText:GetStringWidth()

    -- 2. Get the text width of the player name
    milestoneFrame.nameText:SetWidth(0) -- Reset width constraint to get natural width
    local nameTextWidth = milestoneFrame.nameText:GetStringWidth()

    -- 3. Get width of kill message
    milestoneFrame.killText:SetWidth(0)
    local killTextWidth = milestoneFrame.killText:GetStringWidth()

    -- 4. Calculate the needed width (add padding for icon and margins)
    local requiredContentWidth = math.max(levelTextWidth, nameTextWidth, killTextWidth)

    -- Add consistent margins on both left and right sides
    -- 20px left margin + 24px icon + 5px icon-to-text + content width + 20px right margin
    local frameWidth = 20 + 24 + 5 + requiredContentWidth + 20

    -- Apply minimum and maximum width constraints
    local minWidth = 140   -- Minimum width
    local maxWidth = 300   -- Maximum width cap
    frameWidth = math.min(maxWidth, math.max(minWidth, frameWidth))

    -- Apply the calculated width to the frame
    milestoneFrame:SetWidth(frameWidth)

    -- Set text element widths to match the frame with proper margins
    local textWidth = frameWidth - (20 + 24 + 5 + 20) -- Left margin + icon + spacing + right margin
    milestoneFrame.nameText:SetWidth(textWidth)
    milestoneFrame.levelText:SetWidth(textWidth)
    milestoneFrame.killText:SetWidth(textWidth)

    milestoneFrame:Show()
    local animGroup = SetupKillstreakMilestoneAnimation(milestoneFrame, PSC_DB.KillMilestoneAutoHideTime)
    animGroup:Play()

    -- Only play sound if milestone sounds are enabled
    if PSC_DB.EnableKillMilestoneSounds then
        PlaySound(8213) -- PVPFlagCapturedHorde
    end

    -- Cancel existing timer if any
    if killMilestoneAutoHideTimer then
        killMilestoneAutoHideTimer:Cancel()
    end

    -- Set auto-hide timer
    killMilestoneAutoHideTimer = C_Timer.NewTimer(PSC_DB.KillMilestoneAutoHideTime + 1.0, function()
        milestoneFrame:Hide()
        killMilestoneAutoHideTimer = nil
    end)
end
