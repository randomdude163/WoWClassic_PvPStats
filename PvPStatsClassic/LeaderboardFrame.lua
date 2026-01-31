local addonName, PVPSC = ...

PSC_LeaderboardFrame = nil

PSC_SortLeaderboardBy = "totalKills"
PSC_SortLeaderboardAscending = false
local LEADERBOARD_FRAME_WIDTH = 1150
local LEADERBOARD_FRAME_HEIGHT = 400

PSC_LeaderboardFrameInitialSetup = true

local colWidths = {
    playerName = 95,
    realm = 100,
    level = 30,
    class = 65,
    race = 75,
    totalKills = 55,
    uniqueKills = 55,
    kdRatio = 50,
    currentStreak = 55,
    bestStreak = 55,
    mostKilled = 115,
    avgPerDay = 50,
    achievements = 70,
    achievementPoints = 55,
    addonVersion = 60,
    -- Add column width for Last Seen
    lastSeen = 130
}

local function CleanupFrameElements(content)
    local children = {content:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
        child:SetParent(nil)
        child = nil
    end

    local regions = {content:GetRegions()}
    for _, region in pairs(regions) do
        region:Hide()
        region:ClearAllPoints()
        region:SetParent(nil)
        region = nil
    end
end

local function SetHeaderButtonHighlight(button, enter)
    local fontString = button:GetFontString()
    if (fontString) then
        fontString:SetTextColor(enter and 1 or 1, enter and 1 or 0.82, enter and 0.5 or 0)
    end
end

local function CreateColumnHeader(parent, text, width, anchor, xOffset, yOffset, columnId)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 24)

    if anchor == nil then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    else
        button:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
    end

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()

    button:SetScript("OnClick", function()
        if PSC_SortLeaderboardBy == columnId then
            PSC_SortLeaderboardAscending = not PSC_SortLeaderboardAscending
        else
            PSC_SortLeaderboardBy = columnId
            PSC_SortLeaderboardAscending = false
        end
        RefreshLeaderboardFrame(true)
    end)

    local header = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("LEFT", 3, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetWidth(width - 6)
    header:SetJustifyH("LEFT")

    header:SetText(text)

    if PSC_SortLeaderboardBy == columnId then
        local sortIndicator = PSC_SortLeaderboardAscending and " ^" or " v"
        header:SetText(text .. sortIndicator)
    end

    button:SetFontString(header)

    button:SetScript("OnEnter", function(self)
        SetHeaderButtonHighlight(self, true)

        -- Add tooltips for specific columns
        if columnId == "totalKills" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Total Kills", 1, 0.82, 0)
            GameTooltip:AddLine("The total number of PvP kills this player has recorded", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "uniqueKills" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Unique Players Killed", 1, 0.82, 0)
            GameTooltip:AddLine("The number of unique players killed", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "kdRatio" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Kill/Death Ratio", 1, 0.82, 0)
            GameTooltip:AddLine("Total kills divided by total deaths", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "currentStreak" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Current Streak", 1, 0.82, 0)
            GameTooltip:AddLine("The player's current active kill streak", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "bestStreak" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Best Streak", 1, 0.82, 0)
            GameTooltip:AddLine("The highest kill streak this player has achieved", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "mostKilled" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Most Killed", 1, 0.82, 0)
            GameTooltip:AddLine("The player this person has killed the most", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "avgPerDay" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Average Kills Per Day", 1, 0.82, 0)
            GameTooltip:AddLine("Average kills per day since first recorded kill", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "achievements" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Achievements Unlocked", 1, 0.82, 0)
            GameTooltip:AddLine("The number of PvP achievements this player has unlocked", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "achievementPoints" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Achievement Points", 1, 0.82, 0)
            GameTooltip:AddLine("Total achievement points earned by this player", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "addonVersion" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Addon Version", 1, 0.82, 0)
            GameTooltip:AddLine("The version of PvP Stats Classic this player is using", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "lastSeen" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Last Seen", 1, 0.82, 0)
            GameTooltip:AddLine("Time passed since this player last updated their stats.", 1, 1, 1, true)
            GameTooltip:AddLine("Note: This timestamp only updates when the player records a new kill/event, not continuously.", 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        elseif columnId == "realm" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Realm", 1, 0.82, 0)
            GameTooltip:AddLine("The realm this character belongs to.", 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        SetHeaderButtonHighlight(self, false)
        GameTooltip:Hide()
    end)

    return button
end

local function CreateColumnHeaders(content)
    -- Add a background texture behind all the headers to create a unified header row
    local headerRowBg = content:CreateTexture(nil, "BACKGROUND")
    headerRowBg:SetPoint("TOPLEFT", 10, 0)
    headerRowBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, 0)
    headerRowBg:SetHeight(24)
    headerRowBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local playerNameButton = CreateColumnHeader(content, "Name", colWidths.playerName, nil, 10, 0, "playerName")
    local realmButton = CreateColumnHeader(content, "Realm", colWidths.realm, playerNameButton, 0, 0, "realm")
    local levelButton = CreateColumnHeader(content, "Lvl", colWidths.level, realmButton, 0, 0, "level")
    local classButton = CreateColumnHeader(content, "Class", colWidths.class, levelButton, 0, 0, "class")
    local raceButton = CreateColumnHeader(content, "Race", colWidths.race, classButton, 0, 0, "race")
    local totalKillsButton = CreateColumnHeader(content, "Kills", colWidths.totalKills, raceButton, 0, 0, "totalKills")
    local uniqueKillsButton = CreateColumnHeader(content, "Unique", colWidths.uniqueKills, totalKillsButton, 0, 0, "uniqueKills")
    local kdRatioButton = CreateColumnHeader(content, "K/D", colWidths.kdRatio, uniqueKillsButton, 0, 0, "kdRatio")
    local currentStreakButton = CreateColumnHeader(content, "Streak", colWidths.currentStreak, kdRatioButton, 0, 0, "currentStreak")
    local bestStreakButton = CreateColumnHeader(content, "Best Streak", colWidths.bestStreak, currentStreakButton, 0, 0, "bestStreak")
    local mostKilledButton = CreateColumnHeader(content, "Most Killed", colWidths.mostKilled, bestStreakButton, 0, 0, "mostKilled")
    local avgPerDayButton = CreateColumnHeader(content, "Avg/Day", colWidths.avgPerDay, mostKilledButton, 0, 0, "avgPerDay")
    local achievementsButton = CreateColumnHeader(content, "Achiev.", colWidths.achievements, avgPerDayButton, 0, 0, "achievements")
    local achievementPointsButton = CreateColumnHeader(content, "Achiev. Points", colWidths.achievementPoints, achievementsButton, 0, 0, "achievementPoints")
    local addonVersionButton = CreateColumnHeader(content, "Version", colWidths.addonVersion, achievementPointsButton, 0, 0, "addonVersion")
    local lastSeenButton = CreateColumnHeader(content, "Last Seen", colWidths.lastSeen, addonVersionButton, 0, 0, "lastSeen")

    return -30
end

local function CreatePlayerNameCell(content, playerName, width)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", content, "LEFT", 4, 0)

    -- Strip realm if present
    local cleanName = strsplit("-", playerName or "")
    if not cleanName or cleanName == "" then cleanName = "Unknown" end

    nameText:SetText(cleanName)
    nameText:SetWidth(width)
    nameText:SetJustifyH("LEFT")
    return nameText
end

local function CreateRealmCell(content, anchorTo, realmName, width)
    local realmText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    realmText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

    realmText:SetText(realmName or "")
    realmText:SetWidth(width)
    realmText:SetJustifyH("LEFT")

    -- Truncate if too long (no word wrap + fixed width)
    realmText:SetWordWrap(false)

    return realmText
end

local function CreateLevelCell(content, anchorTo, level, width)
    local levelText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    levelText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    levelText:SetText(tostring(level or "??"))
    levelText:SetWidth(width)
    levelText:SetJustifyH("LEFT")
    return levelText
end

local function CreateClassCell(content, anchorTo, className, width)
    local classText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    classText:SetPoint("LEFT", anchorTo, "RIGHT", 0, 0)

    classText:SetText(className or "Unknown")
    classText:SetWidth(width)
    classText:SetJustifyH("LEFT")
    return classText
end

local function CreateRaceCell(content, anchorTo, raceName, width)
    local raceText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    raceText:SetPoint("LEFT", anchorTo, "RIGHT", 0, 0)

    raceText:SetText(raceName or "Unknown")
    raceText:SetWidth(width)
    raceText:SetJustifyH("LEFT")
    return raceText
end

local function CreateTotalKillsCell(content, anchorTo, totalKills, width)
    local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    killsText:SetText(tostring(totalKills or 0))
    killsText:SetWidth(width)
    killsText:SetJustifyH("LEFT")
    return killsText
end

local function CreateUniqueKillsCell(content, anchorTo, uniqueKills, width)
    local uniqueText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    uniqueText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    uniqueText:SetText(tostring(uniqueKills or 0))
    uniqueText:SetWidth(width)
    uniqueText:SetJustifyH("LEFT")
    return uniqueText
end

local function CreateKDRatioCell(content, anchorTo, kdRatio, width)
    local kdText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    kdText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    kdText:SetText(kdRatio or "0.00")
    kdText:SetWidth(width)
    kdText:SetJustifyH("LEFT")
    return kdText
end

local function CreateCurrentStreakCell(content, anchorTo, currentStreak, width)
    local streakText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    streakText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    streakText:SetText(tostring(currentStreak or 0))
    streakText:SetWidth(width)
    streakText:SetJustifyH("LEFT")
    return streakText
end

local function CreateBestStreakCell(content, anchorTo, bestStreak, width)
    local streakText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    streakText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    streakText:SetText(tostring(bestStreak or 0))
    streakText:SetWidth(width)
    streakText:SetJustifyH("LEFT")
    return streakText
end

local function CreateMostKilledCell(content, anchorTo, mostKilled, width)
    local mostKilledText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mostKilledText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    mostKilledText:SetText(mostKilled or "None")
    mostKilledText:SetWidth(width)
    mostKilledText:SetJustifyH("LEFT")
    return mostKilledText
end

local function CreateAvgPerDayCell(content, anchorTo, avgPerDay, width)
    local avgText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    avgText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    avgText:SetText(avgPerDay or "0.0")
    avgText:SetWidth(width)
    avgText:SetJustifyH("LEFT")
    return avgText
end

local function CreateAchievementsCell(content, anchorTo, achievements, width)
    local achievementsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    achievementsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    achievementsText:SetText(tostring(achievements or 0))
    achievementsText:SetWidth(width)
    achievementsText:SetJustifyH("LEFT")
    return achievementsText
end

local function CreateAchievementPointsCell(content, anchorTo, achievementPoints, width)
    local pointsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pointsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    pointsText:SetText(tostring(achievementPoints or 0))
    pointsText:SetWidth(width)
    pointsText:SetJustifyH("LEFT")
    return pointsText
end

local function CreateAddonVersionCell(content, anchorTo, addonVersion, width)
    local versionText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    versionText:SetText(addonVersion or "Unknown")
    versionText:SetWidth(width)
    versionText:SetJustifyH("LEFT")
    return versionText
end

local function CreateLastSeenCell(content, anchorTo, timestamp, width)
    local lastSeenText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastSeenText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

    -- Use server time for relative comparison since the timestamp comes from the network
    local timeString = PSC_GetTimeAgo(timestamp, true)

    lastSeenText:SetText(timeString)
    lastSeenText:SetWidth(width)
    lastSeenText:SetJustifyH("LEFT")
    lastSeenText:SetTextColor(0.6, 0.8, 1.0) -- Soft blue color like KillsListFrame

    return lastSeenText
end

local function CreateEntryRow(content, entry, yOffset, colWidths, isAlternate)
    local rowContainer = CreateFrame("Button", nil, content)
    rowContainer:SetSize(content:GetWidth() - 20, 16)
    rowContainer:SetPoint("TOPLEFT", 10, yOffset)

    if isAlternate then
        local bgTexture = rowContainer:CreateTexture(nil, "BACKGROUND")
        bgTexture:SetAllPoints()
        bgTexture:SetColorTexture(0.05, 0.05, 0.05, 0.3)
    end

    local highlightTexture = PSC_CreateGoldHighlight(rowContainer, 16)

    local playerNameCell = CreatePlayerNameCell(rowContainer, entry.playerName, colWidths.playerName)
    local realmCell = CreateRealmCell(rowContainer, playerNameCell, entry.realm, colWidths.realm)
    local levelCell = CreateLevelCell(rowContainer, realmCell, entry.level, colWidths.level)
    local classCell = CreateClassCell(rowContainer, levelCell, entry.class, colWidths.class)
    local raceCell = CreateRaceCell(rowContainer, classCell, entry.race, colWidths.race)
    local totalKillsCell = CreateTotalKillsCell(rowContainer, raceCell, entry.totalKills, colWidths.totalKills)
    local uniqueKillsCell = CreateUniqueKillsCell(rowContainer, totalKillsCell, entry.uniqueKills, colWidths.uniqueKills)
    local kdRatioCell = CreateKDRatioCell(rowContainer, uniqueKillsCell, entry.kdRatio, colWidths.kdRatio)
    local currentStreakCell = CreateCurrentStreakCell(rowContainer, kdRatioCell, entry.currentStreak, colWidths.currentStreak)
    local bestStreakCell = CreateBestStreakCell(rowContainer, currentStreakCell, entry.bestStreak, colWidths.bestStreak)
    local mostKilledCell = CreateMostKilledCell(rowContainer, bestStreakCell, entry.mostKilled, colWidths.mostKilled)
    local avgPerDayCell = CreateAvgPerDayCell(rowContainer, mostKilledCell, entry.avgPerDay, colWidths.avgPerDay)
    local achievementsCell = CreateAchievementsCell(rowContainer, avgPerDayCell, entry.achievements, colWidths.achievements)
    local achievementPointsCell = CreateAchievementPointsCell(rowContainer, achievementsCell, entry.achievementPoints, colWidths.achievementPoints)
    local addonVersionCell = CreateAddonVersionCell(rowContainer, achievementPointsCell, entry.addonVersion, colWidths.addonVersion)
    local lastSeenCell = CreateLastSeenCell(rowContainer, addonVersionCell, entry.lastSeen, colWidths.lastSeen)

    -- Apply class color to name like in KillsListFrame
    if entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class:upper()] then
        local color = RAID_CLASS_COLORS[entry.class:upper()]
        playerNameCell:SetTextColor(color.r, color.g, color.b)
    end

    -- If cross-realm, maybe add a subtle hint if not explicitly distinguishing via text?
    -- The playerName already contains "-Realm" if it was set in NetworkHandler.
    -- We can verify this and perhaps color the realm part differently if we wanted to get fancy,
    -- but for now the text modification in NetworkHandler handles the display requirement.

    -- If no detailed stats available (cached only), gray out the text
    if not entry.hasDetailedStats and entry.playerName ~= UnitName("player") then
        local gray = 0.6
        playerNameCell:SetTextColor(gray, gray, gray)
        realmCell:SetTextColor(gray, gray, gray)
        levelCell:SetTextColor(gray, gray, gray)
        classCell:SetTextColor(gray, gray, gray)
        raceCell:SetTextColor(gray, gray, gray)
        totalKillsCell:SetTextColor(gray, gray, gray)
        uniqueKillsCell:SetTextColor(gray, gray, gray)
        kdRatioCell:SetTextColor(gray, gray, gray)
        currentStreakCell:SetTextColor(gray, gray, gray)
        bestStreakCell:SetTextColor(gray, gray, gray)
        mostKilledCell:SetTextColor(gray, gray, gray)
        avgPerDayCell:SetTextColor(gray, gray, gray)
        achievementsCell:SetTextColor(gray, gray, gray)
        achievementPointsCell:SetTextColor(gray, gray, gray)
        addonVersionCell:SetTextColor(gray, gray, gray)
        lastSeenCell:SetTextColor(gray, gray, gray)
    end

    -- Add click handler to view player's detailed stats
    rowContainer:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            local playerName = entry.playerName
            if not playerName or playerName == "" then
                return
            end

            -- Check if it's the local player
            if playerName == UnitName("player") then
                -- Just open our own statistics frame
                PSC_CreateStatisticsFrame()
                return
            end

            -- Only attempt to open if we have detailed stats
            if entry.hasDetailedStats then
                -- Retrieve detailed stats from cache
                if PVPSC.Network and PVPSC.Network.GetDetailedStatsForPlayer then
                    local detailedStats = PVPSC.Network:GetDetailedStatsForPlayer(playerName)
                    if detailedStats then
                        -- Display the detailed stats
                        PSC_ShowPlayerDetailedStats(playerName, detailedStats)
                    end
                end
            end
        end
    end)

    -- Grey out row to indicate reduced functionality if no details available
    -- Actually, don't grey out the whole row as the data is still valid,
    -- just maybe don't highlight as strongly on hover or handle tooltip.
    -- But since we use Gold Highlight, maybe we just leave visual as is and rely on tooltip.

    -- Add tooltip to indicate clickability
    rowContainer:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(entry.playerName or "Unknown", 1, 0.82, 0)

        if entry.playerName == UnitName("player") then
            GameTooltip:AddLine("Click to view your detailed statistics", 1, 1, 1, true)
        elseif entry.hasDetailedStats then
            GameTooltip:AddLine("Click to view this player's detailed statistics", 1, 1, 1, true)
        else
             GameTooltip:AddLine("Detailed statistics currently unavailable.", 1, 0.5, 0.5, true)
             GameTooltip:AddLine("This player is currently not near you, or in your party/raid/guild.", 0.8, 0.8, 0.8, true)
        end
        GameTooltip:Show()
    end)

    rowContainer:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    rowContainer:RegisterForClicks("LeftButtonUp")

    return rowContainer
end

local function GetLeaderboardData()
    -- Use network handler to get all leaderboard data (local + shared)
    -- This function was refactored to prioritize unified logic via Network:GetAllLeaderboardData()
    -- The fallback logic was merged into the main block to avoid duplication
    local leaderboardData = {}

    -- Attempt to get data from Network handler
    local netData = nil
    if PVPSC.Network and PVPSC.Network.GetAllLeaderboardData then
        netData = PVPSC.Network:GetAllLeaderboardData()
    end

    -- If network didn't return data (or empty), simulate a local-only result
    -- by calling the same BuildDetailedStats function the Network handler uses for local stats.
    if not netData or #netData == 0 then
        if PVPSC.Network and PVPSC.Network.BuildDetailedStats then
            local localStats = PVPSC.Network:BuildDetailedStats()
            if localStats then
                 netData = { localStats }
            end
        end
    end

    if netData and #netData > 0 then
         -- Transform network data into display format
         for _, data in ipairs(netData) do
             -- Data coming from network might have nested summary or flattened fields
             -- If keys are missing at root, check if they exist in summary table
             local statsTarget = data
             if data.summary then
                 statsTarget = data.summary
             end

             local currentStreak = data.currentKillStreak or statsTarget.currentKillStreak
             local bestStreak = data.highestKillStreak or statsTarget.highestKillStreak
             local avgPerDayVal = data.avgKillsPerDay or statsTarget.avgKillsPerDay

             local mostKilledVal = data.mostKilledPlayer or statsTarget.mostKilledPlayer or "None"
             local mostKilledCount = data.mostKilledCount or statsTarget.mostKilledCount or 0

             if mostKilledVal ~= "None" and mostKilledCount > 0 then
                 mostKilledVal = mostKilledVal .. " (" .. mostKilledCount .. ")"
             else
                 mostKilledVal = "None"
             end

             local avgPerDayStr = "0.0"
             if avgPerDayVal and tonumber(avgPerDayVal) then
                 avgPerDayStr = string.format("%.1f", tonumber(avgPerDayVal))
             end

             local kills = data.totalKills or statsTarget.totalKills or 0
             local deaths = data.totalDeaths or statsTarget.totalDeaths or 0
             local kdRatioVal = PSC_FormatKDRatio(kills, deaths)

             local acUnlocked = data.achievementsUnlocked or 0
             local acTotal = data.totalAchievements or (PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements and #PVPSC.AchievementSystem.achievements) or 0
             local achievementText = acUnlocked .. "/" .. acTotal

             -- Check if we have detailed stats for this player
             -- We can use Network handler to verify if this player is in cache/live or just summary cache
             local isDetailedAvailable = false
             if data.playerName == UnitName("player") then
                 isDetailedAvailable = true
             elseif PVPSC.Network and PVPSC.Network.GetDetailedStatsForPlayer then
                 -- GetDetailedStatsForPlayer should support lookup by the unique name (Name-Realm)
                 if PVPSC.Network:GetDetailedStatsForPlayer(data.playerName) then
                     isDetailedAvailable = true
                 end
             end

             table.insert(leaderboardData, {
                 playerName = data.playerName or "Unknown",
                 -- We now store the true realm in the data object if available, though playerName might be "Name-Realm"
                 realm = data.realm or PSC_RealmName,
                 level = data.level or 0,
                 class = data.class or "Unknown",
                 race = data.race or "Unknown",
                 totalKills = kills,
                 uniqueKills = data.uniqueKills or statsTarget.uniqueKills or 0,
                 kdRatio = kdRatioVal,
                 currentStreak = currentStreak or 0,
                 bestStreak = bestStreak or 0,
                 mostKilled = mostKilledVal,
                 _mostKilledCount = mostKilledCount,
                 avgPerDay = avgPerDayStr,
                 achievements = achievementText,
                 achievementPoints = data.achievementPoints or 0,
                 addonVersion = data.addonVersion or "Unknown",
                 lastSeen = data.timestamp or 0,
                 hasDetailedStats = isDetailedAvailable
             })
         end
    end

    return leaderboardData
end

local function CompareVersions(v1, v2)
    if v1 == v2 then return 0 end
    -- Handle nil values
    if not v1 then return -1 end
    if not v2 then return 1 end

    -- Convert to string and strip 'v' prefix (e.g. "v3.0" -> "3.0")
    v1 = tostring(v1):gsub("^v", "")
    v2 = tostring(v2):gsub("^v", "")

    -- Split by dot
    local parts1 = { strsplit(".", v1) }
    local parts2 = { strsplit(".", v2) }
    local maxParts = math.max(#parts1, #parts2)

    for i = 1, maxParts do
        local p1 = tonumber(parts1[i]) or 0
        local p2 = tonumber(parts2[i]) or 0

        if p1 ~= p2 then
            if p1 < p2 then return -1 else return 1 end
        end
    end

    return 0
end

local function SortLeaderboardData(data)
    local sortedData = {}
    for _, entry in pairs(data) do
        table.insert(sortedData, entry)
    end

    table.sort(sortedData, function(a, b)
        -- Special handling for Most Killed column to sort by count
        if PSC_SortLeaderboardBy == "mostKilled" then
            local aCount = a._mostKilledCount or 0
            local bCount = b._mostKilledCount or 0
            if aCount ~= bCount then
                if PSC_SortLeaderboardAscending then
                    return aCount < bCount
                else
                    return aCount > bCount
                end
            end
        end

        -- Special handling for Addon Version (Semantic Versioning)
        if PSC_SortLeaderboardBy == "addonVersion" then
            local cmp = CompareVersions(a.addonVersion, b.addonVersion)
            if cmp ~= 0 then
                if PSC_SortLeaderboardAscending then
                    return cmp < 0
                else
                    return cmp > 0
                end
            end
        end

        local aVal = a[PSC_SortLeaderboardBy]
        local bVal = b[PSC_SortLeaderboardBy]

        if aVal == nil then aVal = "" end
        if bVal == nil then bVal = "" end

        -- Enhanced comparison: Try to treat strings as numbers if possible (fixes "28.0" > "207.0")
        local aNum = tonumber(aVal)
        local bNum = tonumber(bVal)

        if aNum and bNum then
            aVal = aNum
            bVal = bNum
        else
            -- Fallback for non-numeric or mixed types: convert to string
            if type(aVal) ~= type(bVal) then
                aVal = tostring(aVal)
                bVal = tostring(bVal)
            end
        end

        if PSC_SortLeaderboardAscending then
            return aVal < bVal
        else
            return aVal > bVal
        end
    end)

    return sortedData
end

local function DisplayEntries(content, sortedEntries, yOffset)
    local count = 0
    local maxEntries = 100

    if #sortedEntries == 0 then
        local noDataText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noDataText:SetPoint("TOPLEFT", 10, yOffset - 20)
        noDataText:SetText("No leaderboard data available yet.")
        noDataText:SetTextColor(1, 1, 1)
        return yOffset - 40, count
    end

    for i, entry in ipairs(sortedEntries) do
        if count >= maxEntries then
            break
        end

        local isAlternate = (i % 2 == 0)
        CreateEntryRow(content, entry, yOffset, colWidths, isAlternate)
        yOffset = yOffset - 18
        count = count + 1
    end

    if count < #sortedEntries then
        local moreText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        moreText:SetPoint("TOPLEFT", 10, yOffset - 10)
        moreText:SetText("Showing " .. count .. " of " .. #sortedEntries .. " entries.")
        moreText:SetTextColor(1, 0.7, 0)
        yOffset = yOffset - 20
    end

    return yOffset, count
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(LEADERBOARD_FRAME_WIDTH - 40, LEADERBOARD_FRAME_HEIGHT * 2)
    scrollFrame:SetScrollChild(content)

    return content
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PSC_LeaderboardStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(LEADERBOARD_FRAME_WIDTH, LEADERBOARD_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    table.insert(UISpecialFrames, "PSC_LeaderboardStatsFrame")
    frame.TitleText:SetText("PvP Stats Leaderboard")

    -- Override close button to work in combat
    if frame.CloseButton then
        frame.CloseButton:SetScript("OnClick", function()
            PSC_FrameManager:HideFrame("Leaderboard")
        end)
    end

    return frame
end

local PSC_LeaderboardDataCache = nil

function RefreshLeaderboardFrame(useCache)
    if PSC_LeaderboardFrameInitialSetup then
        return
    end

    if PSC_LeaderboardFrame == nil then
        return
    end

    local content = PSC_LeaderboardFrame.content
    if not content then
        return
    end

    CleanupFrameElements(content)

    local yOffset = CreateColumnHeaders(content)

    local leaderboardData
    if useCache and PSC_LeaderboardDataCache then
        leaderboardData = PSC_LeaderboardDataCache
    else
        leaderboardData = GetLeaderboardData()
        PSC_LeaderboardDataCache = leaderboardData
    end

    local sortedEntries = SortLeaderboardData(leaderboardData)
    local finalYOffset, entryCount = DisplayEntries(content, sortedEntries, yOffset)

    content:SetHeight(math.max((-finalYOffset + 20), LEADERBOARD_FRAME_HEIGHT - 50))
end

function PSC_CreateLeaderboardFrame()
    if (PSC_LeaderboardFrame) then
        PSC_FrameManager:ShowFrame("Leaderboard")
        RefreshLeaderboardFrame()
        return
    end

    PSC_LeaderboardFrame = CreateMainFrame()
    PSC_LeaderboardFrame.content = CreateScrollFrame(PSC_LeaderboardFrame)

    local infoText = PSC_LeaderboardFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("BOTTOM", PSC_LeaderboardFrame, "BOTTOM", 0, 12)
    infoText:SetText("Leaderboard syncs with nearby players and guild/party/raid members who have this addon installed")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    infoText:SetJustifyH("CENTER")
    PSC_LeaderboardFrame.infoText = infoText

    PSC_FrameManager:RegisterFrame(PSC_LeaderboardFrame, "Leaderboard")

    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PSC_LeaderboardStatsFrame") then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    C_Timer.After(0.01, function()
        PSC_LeaderboardFrameInitialSetup = false
        RefreshLeaderboardFrame()
    end)
end
