local statsFrame = nil

-- UI Constants
local UI = {
    FRAME = { WIDTH = 850, HEIGHT = 680 },
    CHART = { WIDTH = 380, PADDING = 0 },
    BAR = { HEIGHT = 16, SPACING = 3, TEXT_OFFSET = 5 },
    GUILD_LIST = { WIDTH = 350, HEIGHT = 235 },
    TITLE_SPACING = 3,
    TOP_PADDING = 40
}

-- Color definitions
local raceColors = {
    ["Human"] = {r = 1.00, g = 0.82, b = 0.60},
    ["Dwarf"] = {r = 0.77, g = 0.12, b = 0.23},
    ["NightElf"] = {r = 0.47, g = 0.34, b = 0.80},
    ["Gnome"] = {r = 1.00, g = 0.57, b = 0.93},
    ["Orc"] = {r = 0.10, g = 0.67, b = 0.10},
    ["Troll"] = {r = 0.00, g = 0.76, b = 0.78},
    ["Tauren"] = {r = 0.87, g = 0.55, b = 0.20},
    ["Undead"] = {r = 0.33, g = 0.69, b = 0.33}
}

local genderColors = {
    ["Male"] = {r = 0.40, g = 0.60, b = 1.00},
    ["Female"] = {r = 1.00, g = 0.41, b = 0.71}
}

-- Helper functions
local function countOccurrences(items)
    local counts = {}
    for _, item in pairs(items) do
        counts[item] = (counts[item] or 0) + 1
    end
    return counts
end

local function sortByValue(tbl, descending)
    if not tbl then return {} end

    local sorted = {}
    for k, v in pairs(tbl) do
        local safeKey = k or "Unknown"
        local safeValue = v or 0
        table.insert(sorted, {key = safeKey, value = safeValue})
    end

    if #sorted == 0 then return {} end

    if descending then
        table.sort(sorted, function(a, b)
            if not a.value then return false end
            if not b.value then return true end
            return a.value > b.value
        end)
    else
        table.sort(sorted, function(a, b)
            if not a.value then return true end
            if not b.value then return false end
            return a.value < b.value
        end)
    end

    return sorted
end

local function properCase(str)
    if not str or str == "" then return "Unknown" end
    if str:len() <= 1 then return str:upper() end
    return str:sub(1,1):upper() .. str:sub(2):lower()
end

local function getClassColor(class)
    if not class or class == "Unknown" then
        return {r = 0.8, g = 0.8, b = 0.8}
    end

    local classUpper = string.upper(class)

    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classUpper] then
        return {
            r = RAID_CLASS_COLORS[classUpper].r,
            g = RAID_CLASS_COLORS[classUpper].g,
            b = RAID_CLASS_COLORS[classUpper].b
        }
    else
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

local function calculateChartHeight(data)
    local entries = 0
    for _ in pairs(data) do
        entries = entries + 1
    end
    return 30 + (entries * (UI.BAR.HEIGHT + UI.BAR.SPACING)) + 15
end

-- UI Creation functions
local function createContainerWithTitle(parent, title, x, y, width, height)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)
    container:SetPoint("TOPLEFT", x, y)

    local titleText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", 0, 0)
    titleText:SetText(title)

    local line = container:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", 0, -15)
    line:SetSize(width, 1)
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    return container
end

local function createBar(container, entry, index, maxValue, total, titleType)
    local barWidth = (entry.value / maxValue) * (UI.CHART.WIDTH - 160)
    local barY = -(index * (UI.BAR.HEIGHT + UI.BAR.SPACING) + UI.TITLE_SPACING)

    local displayName = entry.key
    if titleType == "class" then
        displayName = properCase(entry.key)
    end

    local itemLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLabel:SetPoint("TOPLEFT", 0, barY)
    itemLabel:SetText(displayName)
    itemLabel:SetWidth(80)
    itemLabel:SetJustifyH("LEFT")

    local bar = container:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", 90, barY)
    bar:SetSize(barWidth, UI.BAR.HEIGHT)

    local color
    if titleType == "class" then
        color = getClassColor(entry.key)
    else
        color = titleType and titleType[entry.key] or {r = 0.8, g = 0.8, b = 0.8}
    end

    bar:SetColorTexture(color.r, color.g, color.b, 0.9)

    local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueLabel:SetPoint("LEFT", bar, "RIGHT", UI.BAR.TEXT_OFFSET, 0)
    valueLabel:SetText(entry.value .. " (" .. string.format("%.1f", entry.value/total*100) .. "%)")
end

local function createBarChart(parent, title, data, colorTable, x, y, width, height)
    local container = createContainerWithTitle(parent, title, x, y, width, height)

    local sortedData = sortByValue(data, true)
    local maxValue = sortedData[1] and sortedData[1].value or 0

    local total = 0
    for _, entry in ipairs(sortedData) do
        total = total + entry.value
    end

    local titleType
    if title == "Kills by Class" or title == "Level ?? Kills by Class" then
        titleType = "class"
    else
        titleType = colorTable
    end

    for i, entry in ipairs(sortedData) do
        createBar(container, entry, i, maxValue, total, titleType)
    end

    return container
end

local function createGuildTableRow(content, entry, index, firstRowSpacing)
    if not entry then return end

    local rowY = index == 1
        and -firstRowSpacing
        or -(firstRowSpacing + ((index-1) * 20))

    local guildName = entry.key or "Unknown"
    local killCount = entry.value or 0

    local guildText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guildText:SetPoint("TOPLEFT", 0, rowY)
    guildText:SetText(tostring(guildName))
    guildText:SetWidth(200)
    guildText:SetJustifyH("LEFT")

    local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killsText:SetPoint("TOPLEFT", 200 + 10, rowY)
    killsText:SetText(tostring(killCount))
    killsText:SetJustifyH("LEFT")
end

local function createScrollFrame(container, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -20)
    scrollFrame:SetSize(width + 5, height - 21)

    local scrollBarName = scrollFrame:GetName() and scrollFrame:GetName().."ScrollBar" or nil
    local scrollBar = scrollBarName and _G[scrollBarName] or nil

    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
    end

    return scrollFrame
end

local function createGuildTable(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Guild Kills", x, y, width, height)

    local guildKills = {}
    if PKA_KillCounts then
        for _, data in pairs(PKA_KillCounts) do
            if data then
                local guild = data.guild or ""
                if guild == "" then guild = "No Guild" end
                guildKills[guild] = (guildKills[guild] or 0) + (data.kills or 0)
            end
        end
    end

    local sortedGuilds = sortByValue(guildKills, true)

    local totalContentWidth = 200 + 60 + 10
    local scrollFrame = createScrollFrame(container, totalContentWidth, height)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(totalContentWidth, math.max(#sortedGuilds * 20 + 10, 10))
    scrollFrame:SetScrollChild(content)

    local firstRowSpacing = 0

    for i, entry in ipairs(sortedGuilds) do
        createGuildTableRow(content, entry, i, firstRowSpacing)
    end

    return container
end

local function addSummaryStatLine(container, label, value, yPosition)
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, yPosition)
    labelText:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPLEFT", 200, yPosition)
    valueText:SetText(tostring(value))

    return yPosition - 20
end

local function addCreditsSection(container, yPosition)
    local creditsHeader = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    creditsHeader:SetPoint("TOPLEFT", 0, yPosition)
    creditsHeader:SetText("Credits:")
    creditsHeader:SetTextColor(1.0, 0.82, 0.0)

    local hunterColor = getClassColor("HUNTER")

    local devsText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    devsText:SetPoint("TOPLEFT", 0, yPosition - 20)
    devsText:SetText("Developed by: ")

    local firstAuthorText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    firstAuthorText:SetPoint("TOPLEFT", devsText, "TOPRIGHT", 0, 0)
    firstAuthorText:SetText("Severussnipe")
    firstAuthorText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    local andText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    andText:SetPoint("TOPLEFT", firstAuthorText, "TOPRIGHT", 0, 0)
    andText:SetText(" & ")

    local secondAuthorText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    secondAuthorText:SetPoint("TOPLEFT", andText, "TOPRIGHT", 0, 0)
    secondAuthorText:SetText("Hkfarmer")
    secondAuthorText:SetTextColor(hunterColor.r, hunterColor.g, hunterColor.b)

    local realmText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    realmText:SetPoint("TOPLEFT", 0, yPosition - 35)
    realmText:SetText("Realm: Spineshatter")

    local guildText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guildText:SetPoint("TOPLEFT", 0, yPosition - 50)
    guildText:SetText("Guild: <Redridge Police>")

    local githubText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    githubText:SetPoint("TOPLEFT", 0, yPosition - 70)
    githubText:SetText("https://github.com/randomdude163/WoWClassic_PlayerKillAnnounce")
    githubText:SetTextHeight(11)
end

local function calculateStatistics()
    local totalKills = 0
    local uniqueKills = 0
    local totalLevels = 0
    local totalPlayerLevels = 0
    local killsWithLevelData = 0
    local unknownLevelKills = 0

    if PKA_KillCounts then
        for nameWithLevel, data in pairs(PKA_KillCounts) do
            if data then
                uniqueKills = uniqueKills + 1
                local kills = data.kills or 0
                totalKills = totalKills + kills

                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                if levelNum == -1 or (data.unknownLevel or false) then
                    unknownLevelKills = unknownLevelKills + kills
                else
                    totalLevels = totalLevels + levelNum * kills
                end

                if data.playerLevel then
                    totalPlayerLevels = totalPlayerLevels + (data.playerLevel * kills)
                    killsWithLevelData = killsWithLevelData + kills
                end
            end
        end
    end

    local knownLevelKills = totalKills - unknownLevelKills
    local avgLevel = knownLevelKills > 0 and (totalLevels / knownLevelKills) or 0
    local avgPlayerLevel = killsWithLevelData > 0 and (totalPlayerLevels / killsWithLevelData) or UnitLevel("player")
    local avgLevelDiff = avgPlayerLevel - avgLevel
    local avgKillsPerPlayer = uniqueKills > 0 and (totalKills / uniqueKills) or 0

    return {
        totalKills = totalKills,
        uniqueKills = uniqueKills,
        unknownLevelKills = unknownLevelKills,
        avgLevel = avgLevel,
        avgPlayerLevel = avgPlayerLevel,
        avgLevelDiff = avgLevelDiff,
        avgKillsPerPlayer = avgKillsPerPlayer
    }
end

local function createSummaryStats(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Summary Statistics", x, y, width, height)

    local stats = calculateStatistics()
    local statY = -30

    statY = addSummaryStatLine(container, "Total Player Kills:", stats.totalKills, statY)
    statY = addSummaryStatLine(container, "Unique Players Killed:", stats.uniqueKills, statY)
    statY = addSummaryStatLine(container, "Level ?? Kills:", stats.unknownLevelKills, statY)
    statY = addSummaryStatLine(container, "Average Kill Level:", string.format("%.1f", stats.avgLevel), statY)
    statY = addSummaryStatLine(container, "Your Average Level:", string.format("%.1f", stats.avgPlayerLevel), statY)

    local levelDiffText = string.format("%.1f", stats.avgLevelDiff) ..
        (stats.avgLevelDiff > 0 and " (you're higher)" or " (you're lower)")
    statY = addSummaryStatLine(container, "Avg. Level Difference:", levelDiffText, statY)

    statY = addSummaryStatLine(container, "Avg. Kills Per Player:", string.format("%.2f", stats.avgKillsPerPlayer), statY)
    statY = addSummaryStatLine(container, "Current Kill Streak:", PKA_CurrentKillStreak or 0, statY)
    statY = addSummaryStatLine(container, "Highest Kill Streak:", PKA_HighestKillStreak or 0, statY)
    statY = addSummaryStatLine(container, "Highest Multi-Kill:", PKA_HighestMultiKill or 0, statY)

    statY = statY - 5
    addCreditsSection(container, statY)

    return container
end

local function gatherStatistics()
    local classData = {}
    local raceData = {}
    local genderData = {}
    local unknownLevelClassData = {}

    if not PKA_KillCounts then
        return {}, {}, {}, {}
    end

    for nameWithLevel, data in pairs(PKA_KillCounts) do
        if data then
            local class = data.class or "Unknown"
            classData[class] = (classData[class] or 0) + 1

            local level = nameWithLevel:match(":(%S+)")
            local levelNum = tonumber(level or "0") or 0
            local kills = data.kills or 1

            if levelNum == -1 or (data.unknownLevel or false) then
                unknownLevelClassData[class] = (unknownLevelClassData[class] or 0) + kills
            end

            local race = data.race or "Unknown"
            raceData[race] = (raceData[race] or 0) + 1

            local gender = data.gender or "Unknown"
            genderData[gender] = (genderData[gender] or 0) + 1
        end
    end

    return classData, raceData, genderData, unknownLevelClassData
end

local function setupMainFrame()
    local frame = CreateFrame("Frame", "PKAStatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.FRAME.WIDTH, UI.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    tinsert(UISpecialFrames, "PKAStatisticsFrame")

    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    frame.CloseButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    frame.TitleText:SetText("Player Kill Statistics")

    return frame
end

local function calculateFrameHeight(leftColumnHeight, rightColumnHeight)
    return math.max(leftColumnHeight, rightColumnHeight, 550)
end

function PKA_CreateStatisticsFrame()
    if statsFrame then
        statsFrame:Hide()
        statsFrame = nil
    end

    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PKAStatisticsFrame") then
            tremove(UISpecialFrames, i)
            break
        end
    end

    local classData, raceData, genderData, unknownLevelClassData = gatherStatistics()

    statsFrame = setupMainFrame()

    local classChartHeight = calculateChartHeight(classData)
    local raceChartHeight = calculateChartHeight(raceData)
    local genderChartHeight = calculateChartHeight(genderData)
    local unknownLevelClassHeight = calculateChartHeight(unknownLevelClassData)

    createBarChart(statsFrame, "Kills by Class", classData, nil, 20, -UI.TOP_PADDING, UI.CHART.WIDTH, classChartHeight)

    local raceChartY = -UI.TOP_PADDING - classChartHeight - UI.CHART.PADDING
    createBarChart(statsFrame, "Kills by Race", raceData, raceColors, 20, raceChartY, UI.CHART.WIDTH, raceChartHeight)

    local genderChartY = raceChartY - raceChartHeight - UI.CHART.PADDING
    createBarChart(statsFrame, "Kills by Gender", genderData, genderColors, 20, genderChartY, UI.CHART.WIDTH, genderChartHeight)

    local unknownLevelClassY = genderChartY - genderChartHeight - UI.CHART.PADDING
    createBarChart(statsFrame, "Level ?? Kills by Class", unknownLevelClassData, nil, 20, unknownLevelClassY, UI.CHART.WIDTH, unknownLevelClassHeight)

    local summaryStatsWidth = 380
    createGuildTable(statsFrame, 440, -UI.TOP_PADDING, summaryStatsWidth, UI.GUILD_LIST.HEIGHT)
    createSummaryStats(statsFrame, 440, -UI.GUILD_LIST.HEIGHT - UI.TOP_PADDING - 20, summaryStatsWidth, 250)

    local leftColumnHeight = UI.TOP_PADDING + classChartHeight + UI.CHART.PADDING +
                             raceChartHeight + UI.CHART.PADDING +
                             genderChartHeight + UI.CHART.PADDING +
                             unknownLevelClassHeight + 25

    local rightColumnHeight = UI.TOP_PADDING + UI.GUILD_LIST.HEIGHT + 20 + 250 + 25

    statsFrame:SetHeight(calculateFrameHeight(leftColumnHeight, rightColumnHeight))
end

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

local originalPrintUsage = PrintSlashCommandUsage
if originalPrintUsage then
    PrintSlashCommandUsage = function()
        originalPrintUsage()
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka statistics (or stat/stats) - Show kill statistics",
            PKA_CHAT_MESSAGE_R, PKA_CHAT_MESSAGE_G, PKA_CHAT_MESSAGE_B)
    end
end