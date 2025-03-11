local statsFrame = nil
local STATS_FRAME_WIDTH = 850
local STATS_FRAME_HEIGHT = 680  -- Increased from 650 to 680
local CHART_WIDTH = 380    -- Reduced width to avoid overlapping
local BAR_HEIGHT = 16      -- Reduced height to fit more bars
local BAR_SPACING = 3      -- Reduced spacing to fit more bars
local TEXT_OFFSET = 5
local GUILD_LIST_WIDTH = 350  -- Narrower guild list
local CHART_PADDING = 40   -- Increased padding between charts
local GUILD_LIST_HEIGHT = 230  -- Reduced from 350 to 230 (roughly 1/3 smaller)

-- Use WoW's built-in class colors
-- This will be populated in createBarChart for class charts

-- More distinct race colors
local raceColors = {
    ["Human"] = {r = 1.00, g = 0.82, b = 0.60},    -- Warm beige
    ["Dwarf"] = {r = 0.77, g = 0.12, b = 0.23},    -- Deep red
    ["NightElf"] = {r = 0.47, g = 0.34, b = 0.80}, -- Purple
    ["Gnome"] = {r = 1.00, g = 0.57, b = 0.93},    -- Pink
    ["Orc"] = {r = 0.10, g = 0.67, b = 0.10},      -- Green
    ["Troll"] = {r = 0.00, g = 0.76, b = 0.78},    -- Teal
    ["Tauren"] = {r = 0.87, g = 0.55, b = 0.20},   -- Orange/Brown
    ["Undead"] = {r = 0.33, g = 0.69, b = 0.33}   -- Toxic green
}

local genderColors = {
    ["Male"] = {r = 0.40, g = 0.60, b = 1.00},
    ["Female"] = {r = 1.00, g = 0.41, b = 0.71}
}

-- Helper function to count occurrences
local function countOccurrences(items)
    local counts = {}
    for _, item in pairs(items) do
        counts[item] = (counts[item] or 0) + 1
    end
    return counts
end

-- Helper function to sort a table by value
local function sortByValue(tbl, descending)
    -- Return empty list if table is nil
    if not tbl then
        return {}
    end

    local sorted = {}
    for k, v in pairs(tbl) do
        -- Ensure key and value are not nil
        local safeKey = k or "Unknown"
        local safeValue = v or 0
        table.insert(sorted, {key = safeKey, value = safeValue})
    end

    -- Return empty list if we have no entries
    if #sorted == 0 then
        return {}
    end

    if descending then
        table.sort(sorted, function(a, b)
            -- Safely compare values that might be nil
            if not a.value then return false end
            if not b.value then return true end
            return a.value > b.value
        end)
    else
        table.sort(sorted, function(a, b)
            -- Safely compare values that might be nil
            if not a.value then return true end
            if not b.value then return false end
            return a.value < b.value
        end)
    end

    return sorted
end

-- Helper function to capitalize first letter (Title case)
local function properCase(str)
    if not str or str == "" then return "Unknown" end
    if str:len() <= 1 then return str:upper() end
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

-- Function to get class color from RAID_CLASS_COLORS
local function getClassColor(class)
    if not class or class == "Unknown" then
        return {r = 0.8, g = 0.8, b = 0.8}
    end

    -- RAID_CLASS_COLORS uses uppercase class names
    local classUpper = string.upper(class)

    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classUpper] then
        return {
            r = RAID_CLASS_COLORS[classUpper].r,
            g = RAID_CLASS_COLORS[classUpper].g,
            b = RAID_CLASS_COLORS[classUpper].b
        }
    else
        -- Fallback colors in case RAID_CLASS_COLORS isn't available
        local fallbackColors = {
            ["WARRIOR"] = {r = 0.78, g = 0.61, b = 0.43},
            ["PALADIN"] = {r = 0.96, g = 0.55, b = 0.73},
            ["HUNTER"] = {r = 0.67, g = 0.83, b = 0.45},
            ["ROGUE"] = {r = 1.00, g = 0.96, b = 0.41},
            ["PRIEST"] = {r = 1.00, g = 1.00, b = 1.00},
            ["SHAMAN"] = {r = 0.00, g = 0.44, b = 0.87},
            ["MAGE"] = {r = 0.25, g = 0.78, b = 0.92},
            ["WARLOCK"] = {r = 0.53, g = 0.53, b = 0.93},
            ["DRUID"] = {r = 1.00, g = 0.49, b = 0.04}
        }

        return fallbackColors[classUpper] or {r = 0.8, g = 0.8, b = 0.8}
    end
end

-- Function to create a bar chart (without scrollbars)
local function createBarChart(parent, title, data, colorTable, x, y, width, height)
    -- Create container
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetPoint("TOPLEFT", x, y)

    -- Create title with more spacing below it
    local titleText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(title)

    -- Add horizontal line under title
    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 0, -20)
    line:SetSize(width, 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    -- Sort data by value (descending)
    local sortedData = sortByValue(data, true)
    local maxValue = sortedData[1] and sortedData[1].value or 0

    -- Calculate total
    local total = 0
    for _, entry in ipairs(sortedData) do
        total = total + entry.value
    end

    -- Create bars directly in the container (no scrollframe)
    -- Adjust starting position to account for the line
    local titleSpacing = 25  -- Increased from 20 to account for line

    for i = 1, #sortedData do
        local entry = sortedData[i]
        local barWidth = (entry.value / maxValue) * (width - 160) -- Allow space for labels
        local barY = -(i * (BAR_HEIGHT + BAR_SPACING) + titleSpacing)  -- Position below the title with more spacing

        -- Properly format display name (Title case for classes)
        local displayName = entry.key
        if title == "Kills by Class" then
            displayName = properCase(entry.key)
        end

        -- Label for the item
        local itemLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        itemLabel:SetPoint("TOPLEFT", 0, barY)
        itemLabel:SetText(displayName)
        itemLabel:SetWidth(80)
        itemLabel:SetJustifyH("LEFT")

        -- Value bar
        local bar = container:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT", 90, barY)
        bar:SetSize(barWidth, BAR_HEIGHT)

        -- Use the appropriate color based on chart type
        local color
        if title == "Kills by Class" then
            color = getClassColor(entry.key)
        else
            color = colorTable[entry.key] or {r = 0.8, g = 0.8, b = 0.8}
        end

        bar:SetColorTexture(color.r, color.g, color.b, 0.9)  -- Increased alpha for more vibrancy

        -- Value label
        local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueLabel:SetPoint("LEFT", bar, "RIGHT", TEXT_OFFSET, 0)
        valueLabel:SetText(entry.value .. " (" .. string.format("%.1f", entry.value/total*100) .. "%)")
    end

    return container
end

-- Function to create guild kills table (with scrollbar)
local function createGuildTable(parent, x, y, width, height)
    -- Create container
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetPoint("TOPLEFT", x, y)

    -- Create title
    local titleText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText("Guild Kills")

    -- Extract guild data with safety checks
    local guildKills = {}
    if PKA_KillCounts then
        for nameWithLevel, data in pairs(PKA_KillCounts) do
            if data then
                local guild = data.guild or ""
                if guild == "" then
                    guild = "No Guild"
                end
                guildKills[guild] = (guildKills[guild] or 0) + (data.kills or 0)
            end
        end
    end

    -- Sort guilds by kill count
    local sortedGuilds = sortByValue(guildKills, true)

    -- Create horizontal line
    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 0, -20)
    line:SetSize(width, 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    -- Define column widths
    local guildColWidth = 200  -- Match the label width in summary stats
    local killsColWidth = 60   -- Width for the kill count column
    local totalContentWidth = guildColWidth + killsColWidth + 10  -- 10px for spacing

    -- Create a ScrollFrame for the guild list
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -25)
    scrollFrame:SetSize(totalContentWidth + 5, height - 30)  -- +5 to account for scroll bar overlap

    -- Reposition scrollbar
    local scrollBarName = scrollFrame:GetName() and scrollFrame:GetName().."ScrollBar" or nil
    local scrollBar = scrollBarName and _G[scrollBarName] or nil

    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
    end

    -- Create content frame to hold guild entries
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(totalContentWidth, math.max(#sortedGuilds * 20 + 10, 10))
    scrollFrame:SetScrollChild(content)

    -- Create table rows for ALL guilds (with safety checks)
    for i = 1, #sortedGuilds do
        local entry = sortedGuilds[i]
        if entry then
            local rowY = -(i * 20)

            -- Ensure key and value exist before using them
            local guildName = entry.key or "Unknown"
            local killCount = entry.value or 0

            local guildText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            guildText:SetPoint("TOPLEFT", 0, rowY)
            guildText:SetText(tostring(guildName))
            guildText:SetWidth(guildColWidth)
            guildText:SetJustifyH("LEFT")

            local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            killsText:SetPoint("TOPLEFT", guildColWidth + 10, rowY)
            killsText:SetText(tostring(killCount))  -- Convert to string to be safe
            killsText:SetJustifyH("LEFT")
        end
    end

    return container
end

-- Function to create summary statistics area
local function createSummaryStats(parent, x, y, width, height)
    -- Create container
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetPoint("TOPLEFT", x, y)

    -- Create title
    local titleText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText("Summary Statistics")

    -- Add horizontal line under title
    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 0, -20)
    line:SetSize(width, 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    -- Calculate statistics
    local totalKills = 0
    local uniqueKills = 0
    local totalLevels = 0
    local totalPlayerLevels = 0
    local killsWithLevelData = 0
    local unknownLevelKills = 0

    -- Safety check for nil PKA_KillCounts
    if PKA_KillCounts then
        -- Count unique players killed and their total kill count
        for nameWithLevel, data in pairs(PKA_KillCounts) do
            -- Skip if data is nil
            if data then
                uniqueKills = uniqueKills + 1
                local kills = data.kills or 0
                totalKills = totalKills + kills

                -- Check if this is an unknown level player (-1)
                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                if levelNum == -1 or (data.unknownLevel or false) then
                    unknownLevelKills = unknownLevelKills + kills
                else
                    -- Only add to level calculations if it's a known level
                    totalLevels = totalLevels + levelNum * kills
                end

                -- Sum player levels for each kill (weighted by number of kills)
                if data.playerLevel then
                    totalPlayerLevels = totalPlayerLevels + (data.playerLevel * kills)
                    killsWithLevelData = killsWithLevelData + kills
                end
            end
        end
    end

    -- Calculate average level (weighted by number of kills) - exclude unknown levels
    local knownLevelKills = totalKills - unknownLevelKills
    local avgLevel = knownLevelKills > 0 and (totalLevels / knownLevelKills) or 0

    -- Calculate average player level at time of kills
    local avgPlayerLevel = killsWithLevelData > 0 and (totalPlayerLevels / killsWithLevelData) or UnitLevel("player")

    -- Average level difference calculation using stored player levels
    local avgLevelDiff = avgPlayerLevel - avgLevel

    -- Average kills per unique player
    local avgKillsPerPlayer = uniqueKills > 0 and (totalKills / uniqueKills) or 0

    -- Create stat lines - adjusted Y position to account for the line
    local statY = -35
    local function addStat(label, value)
        local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelText:SetPoint("TOPLEFT", 0, statY)
        labelText:SetText(label)

        local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        valueText:SetPoint("TOPLEFT", 200, statY)
        valueText:SetText(tostring(value))  -- Ensure value is a string

        statY = statY - 23
    end

    addStat("Total Player Kills:", totalKills)
    addStat("Unique Players Killed:", uniqueKills)
    addStat("Level ?? Kills:", unknownLevelKills)
    addStat("Average Kill Level:", string.format("%.1f", avgLevel))
    addStat("Your Average Level:", string.format("%.1f", avgPlayerLevel))
    addStat("Avg. Level Difference:", string.format("%.1f", avgLevelDiff) ..
        (avgLevelDiff > 0 and " (you're higher)" or " (you're lower)"))
    addStat("Avg. Kills Per Player:", string.format("%.2f", avgKillsPerPlayer))

    -- Add streak statistics with nil checks
    addStat("Current Kill Streak:", PKA_CurrentKillStreak or 0)
    addStat("Highest Kill Streak:", PKA_HighestKillStreak or 0)
    addStat("Highest Multi-Kill:", PKA_HighestMultiKill or 0)

    -- Add credits section with slightly more space above it
    statY = statY - 30  -- Extra spacing before credits

    -- Credits header in gold color
    local creditsHeader = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    creditsHeader:SetPoint("TOPLEFT", 0, statY)
    creditsHeader:SetText("Credits:")
    creditsHeader:SetTextColor(1.0, 0.82, 0.0)

    -- Get hunter class color
    local hunterColor = getClassColor("HUNTER")

    -- Add developers credit with hunter class color
    local devsText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    devsText:SetPoint("TOPLEFT", 0, statY - 20)
    devsText:SetText("Developed by: ")

    local namesText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    namesText:SetPoint("TOPLEFT", devsText, "TOPRIGHT", 0, 0)
    namesText:SetText("Severussnipe & Hkfarmer")
    namesText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    -- Add realm info
    local realmText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    realmText:SetPoint("TOPLEFT", 0, statY - 35)
    realmText:SetText("Realm: Spineshatter")

    -- Add guild info
    local guildText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guildText:SetPoint("TOPLEFT", 0, statY - 50)
    guildText:SetText("Guild: Redridge Police")

    -- Add GitHub link with even smaller font and reduced font height
    local githubText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    githubText:SetPoint("TOPLEFT", 0, statY - 70)
    githubText:SetText("https://github.com/randomdude163/WoWClassic_PlayerKillAnnounce")
    githubText:SetTextHeight(11)

    return container
end

-- Function to gather statistics from kill data
local function gatherStatistics()
    local classData = {}
    local raceData = {}
    local genderData = {}
    local unknownLevelClassData = {}  -- New table for ?? level kills by class

    -- Safety check if PKA_KillCounts is nil
    if not PKA_KillCounts then
        return {}, {}, {}, {}
    end

    for nameWithLevel, data in pairs(PKA_KillCounts) do
        if data then
            -- Existing statistics gathering...
            local class = data.class or "Unknown"
            classData[class] = (classData[class] or 0) + 1

            -- Check if this is a ?? level player
            local level = nameWithLevel:match(":(%S+)")
            local levelNum = tonumber(level or "0") or 0
            local kills = data.kills or 1

            if levelNum == -1 or (data.unknownLevel or false) then
                unknownLevelClassData[class] = (unknownLevelClassData[class] or 0) + kills
            end

            -- Rest of existing code...
            -- Count race occurrences
            local race = data.race or "Unknown"
            raceData[race] = (raceData[race] or 0) + 1

            -- Count gender occurrences
            local gender = data.gender or "Unknown"
            genderData[gender] = (genderData[gender] or 0) + 1
        end
    end

    return classData, raceData, genderData, unknownLevelClassData
end

-- Function to calculate the height needed for a chart based on the data
local function calculateChartHeight(data)
    local entries = 0
    for _ in pairs(data) do
        entries = entries + 1
    end

    -- Calculate required height: title (25px) + entries * (height + spacing) + padding
    return 35 + (entries * (BAR_HEIGHT + BAR_SPACING)) + 25  -- Slight adjustment for better spacing
end

-- Creates or refreshes the stats frame
function PKA_CreateStatisticsFrame()
    -- Close existing frame if it's open
    if statsFrame then
        statsFrame:Hide()
        statsFrame = nil
    end

    -- Remove existing entry from UISpecialFrames if it exists
    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PKAStatisticsFrame") then
            tremove(UISpecialFrames, i)
            break
        end
    end

    -- Gather statistics first so we can adjust heights
    local classData, raceData, genderData, unknownLevelClassData = gatherStatistics()

    -- Create main frame
    statsFrame = CreateFrame("Frame", "PKAStatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    statsFrame:SetSize(STATS_FRAME_WIDTH, STATS_FRAME_HEIGHT)
    statsFrame:SetPoint("CENTER")
    statsFrame:SetMovable(true)
    statsFrame:EnableMouse(true)
    statsFrame:RegisterForDrag("LeftButton")
    statsFrame:SetScript("OnDragStart", statsFrame.StartMoving)
    statsFrame:SetScript("OnDragStop", statsFrame.StopMovingOrSizing)

    -- Make frame closeable with ESC
    tinsert(UISpecialFrames, "PKAStatisticsFrame")

    -- Add explicit keyboard handling for ESC as a backup method
    statsFrame:EnableKeyboard(true)
    statsFrame:SetPropagateKeyboardInput(true)
    statsFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Add close button functionality
    statsFrame.CloseButton:SetScript("OnClick", function()
        statsFrame:Hide()
    end)

    -- Set title
    statsFrame.TitleText:SetText("Player Kill Statistics")

    -- Calculate chart heights based on data
    local classChartHeight = calculateChartHeight(classData)
    local raceChartHeight = calculateChartHeight(raceData)
    local genderChartHeight = calculateChartHeight(genderData)

    -- Create class chart with dynamic height
    createBarChart(statsFrame, "Kills by Class", classData, nil, 20, -30, CHART_WIDTH, classChartHeight)

    -- Position race chart below class chart with increased padding
    local raceChartY = -30 - classChartHeight - CHART_PADDING
    createBarChart(statsFrame, "Kills by Race", raceData, raceColors, 20, raceChartY, CHART_WIDTH, raceChartHeight)

    -- Position gender chart below race chart with increased padding
    local genderChartY = raceChartY - raceChartHeight - CHART_PADDING
    createBarChart(statsFrame, "Kills by Gender", genderData, genderColors, 20, genderChartY, CHART_WIDTH, genderChartHeight)

    -- Position ?? level class chart below gender chart with increased padding
    local unknownLevelClassY = genderChartY - genderChartHeight - CHART_PADDING
    createBarChart(statsFrame, "Level ?? Kills by Class", unknownLevelClassData, nil, 20, unknownLevelClassY, CHART_WIDTH, calculateChartHeight(unknownLevelClassData))

    -- Create guild table with reduced height and updated width
    local summaryStatsWidth = 380  -- Width of summary stats section
    createGuildTable(statsFrame, 440, -30, summaryStatsWidth, GUILD_LIST_HEIGHT)

    -- Create summary stats (moved up due to shorter guild list)
    createSummaryStats(statsFrame, 440, -280, summaryStatsWidth, 250)  -- Using same width for consistency

    -- Calculate total frame height needed to fit everything
    local totalChartHeight = 30 + classChartHeight + CHART_PADDING + raceChartHeight + CHART_PADDING + genderChartHeight + CHART_PADDING + calculateChartHeight(unknownLevelClassData) + 30
    local frameHeight = math.max(totalChartHeight, STATS_FRAME_HEIGHT)

    -- Calculate minimum frame height needed based on both left and right columns
    local leftColumnHeight = 30 + classChartHeight + CHART_PADDING + raceChartHeight + CHART_PADDING + genderChartHeight + 30
    local rightColumnHeight = 30 + GUILD_LIST_HEIGHT + 30 + 250 + 30  -- Header + guild list + spacing + summary stats + footer
    local minFrameHeight = math.max(leftColumnHeight, rightColumnHeight)

    -- Set the frame height to the larger of the calculated minimum or the default height
    statsFrame:SetHeight(math.max(minFrameHeight, STATS_FRAME_HEIGHT))
end

-- Hook into existing slash command handler
local originalSlashHandler = PKA_SlashCommandHandler
function PKA_SlashCommandHandler(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command or "")

    if command == "statistics" or command == "stat" or command == "stats" then
        PKA_CreateStatisticsFrame()
    else
        originalSlashHandler(msg)
    end
end

-- Update the slash command usage to include the new command
local originalPrintUsage = PrintSlashCommandUsage
if originalPrintUsage then
    PrintSlashCommandUsage = function()
        originalPrintUsage()
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka statistics (or stat/stats) - Show kill statistics",
            PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    end
end