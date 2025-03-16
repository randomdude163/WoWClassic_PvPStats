if not PKA_ActiveFrameLevel then
    PKA_ActiveFrameLevel = 100
end

-- Add this helper function at the top of StatisticsFrame.lua
local function CreateGoldHighlight(parent, height)
    local highlight = parent:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(true)

    -- Check if SetGradient with table parameters is available (newer API)
    local useNewAPI = highlight.SetGradient and
                      type(highlight.SetGradient) == "function" and
                      pcall(function()
                          highlight:SetGradient("HORIZONTAL", {r=1,g=1,b=1,a=1}, {r=1,g=1,b=1,a=1})
                          return true
                      end)

    if useNewAPI then
        -- Use the newer API version with table parameters (WoW 10.0+)
        highlight:SetColorTexture(1, 0.82, 0, 0.6)  -- Significantly increased alpha
        -- Try to set gradient in a safe way
        pcall(function()
            highlight:SetGradient("HORIZONTAL",
                {r=1, g=0.82, b=0, a=0.3},    -- Left side (more visible)
                {r=1, g=0.82, b=0, a=0.8}     -- Right side (very visible)
            )
        end)
    else
        -- For older clients, create two separate textures for the gradient
        -- First, clear the main highlight
        highlight:SetColorTexture(1, 0.82, 0, 0.5)  -- Increased from 0 to 0.5

        -- Create left half with gradient fade in
        local leftGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        leftGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        leftGradient:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        leftGradient:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        leftGradient:SetWidth(parent:GetWidth() / 2)
        leftGradient:SetHeight(height)

        -- Use pcall to safely handle method variations between API versions
        pcall(function()
            leftGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.3, 1, 0.82, 0, 0.7)
        end)

        -- Fallback if SetGradientAlpha fails
        if leftGradient:GetVertexColor() == 1 and select(2, leftGradient:GetVertexColor()) == 1 then
            leftGradient:SetVertexColor(1, 0.82, 0, 0.6)
        end

        -- Create right half with gradient fade out
        local rightGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        rightGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        rightGradient:SetPoint("TOPLEFT", leftGradient, "TOPRIGHT", 0, 0)
        rightGradient:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

        -- Use pcall to safely handle method variations between API versions
        pcall(function()
            rightGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0.3)
        end)

        -- Fallback if SetGradientAlpha fails
        if rightGradient:GetVertexColor() == 1 and select(2, rightGradient:GetVertexColor()) == 1 then
            rightGradient:SetVertexColor(1, 0.82, 0, 0.6)
        end
    end

    -- Add a semi-transparent border around the highlight for better visibility
    local topBorder = parent:CreateTexture(nil, "HIGHLIGHT")
    topBorder:SetHeight(1)
    topBorder:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    topBorder:SetColorTexture(1, 0.82, 0, 0.8)

    local bottomBorder = parent:CreateTexture(nil, "HIGHLIGHT")
    bottomBorder:SetHeight(1)
    bottomBorder:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetColorTexture(1, 0.82, 0, 0.8)

    return highlight
end

-- Get next frame level and increment the counter
local function PKA_GetNextFrameLevel()
    PKA_ActiveFrameLevel = PKA_ActiveFrameLevel + 10
    return PKA_ActiveFrameLevel
end

local statsFrame = nil

local UI = {
    FRAME = { WIDTH = 850, HEIGHT = 680 },
    CHART = { WIDTH = 360,  -- Reduced from 380 to allow more space for scroll bar
              PADDING = 10 }, -- Increased from 2
    BAR = { HEIGHT = 16,
            SPACING = 3,
            TEXT_OFFSET = 5 },
    GUILD_LIST = { WIDTH = 350, HEIGHT = 235 },
    TITLE_SPACING = 3,
    TOP_PADDING = 40,
    LEFT_SCROLL_PADDING = 20,
    ZONE_NAME_WIDTH = 150,  -- Increased from 140
    STANDARD_NAME_WIDTH = 80  -- Increased from 70
}

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
    local barWidth
    local nameWidth
    local barX
    local maxBarWidth

    if titleType == "zone" then
        nameWidth = UI.ZONE_NAME_WIDTH
        barX = nameWidth + 10
        maxBarWidth = UI.CHART.WIDTH - nameWidth - 110
    else
        nameWidth = UI.STANDARD_NAME_WIDTH
        barX = 90
        maxBarWidth = UI.CHART.WIDTH - 190
    end

    barWidth = (entry.value / maxValue) * maxBarWidth

    local barY = -(index * (UI.BAR.HEIGHT + UI.BAR.SPACING) + UI.TITLE_SPACING)

    local displayName = entry.key
    if titleType == "class" then
        displayName = properCase(entry.key)
    end

    -- Create a clickable button for the entire bar row
    local barButton = CreateFrame("Button", nil, container)
    barButton:SetSize(UI.CHART.WIDTH, UI.BAR.HEIGHT)
    barButton:SetPoint("TOPLEFT", 0, barY)

    -- Create highlight with gradient fade effect
    local highlightTexture = CreateGoldHighlight(barButton, UI.BAR.HEIGHT)

    -- Add tooltip
    barButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(displayName)

        if titleType == "class" or titleType == "unknownLevelClass" then
            GameTooltip:AddLine("Click to show all kills from this class", 1, 1, 1, true)
        elseif titleType == "zone" then
            GameTooltip:AddLine("Click to show all kills from this zone", 1, 1, 1, true)
        elseif titleType == "level" then
            if entry.key == "??" then
                GameTooltip:AddLine("Click to show all unknown level kills", 1, 1, 1, true)
            else
                GameTooltip:AddLine("Click to show all kills with this level", 1, 1, 1, true)
            end
        elseif titleType == raceColors then
            GameTooltip:AddLine("Click to show all kills from this race", 1, 1, 1, true)
        elseif titleType == genderColors then
            GameTooltip:AddLine("Click to show all kills from this gender", 1, 1, 1, true)
        end

        GameTooltip:Show()
    end)

    barButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Add click handler
    barButton:SetScript("OnClick", function()
        -- First open the kills list frame
        PKA_CreateKillStatsFrame()

        -- Wait a short time to ensure the frame is created and registered
        C_Timer.After(0.05, function()
            -- Set appropriate search text based on bar type
            if titleType == "class" or titleType == "unknownLevelClass" then
                PKA_SetKillListSearch("", nil, entry.key, nil, nil, nil, true)
            elseif titleType == "zone" then
                PKA_SetKillListSearch("", nil, nil, nil, nil, entry.key, true)
            elseif titleType == "level" then
                if entry.key == "??" then
                    -- Special handling for unknown level - explicitly set to -1
                    PKA_SetKillListLevelRange(-1, -1, true)
                else
                    -- Individual level filter
                    local level = tonumber(entry.key)
                    if level then
                        PKA_SetKillListLevelRange(level, level, true)
                    end
                end
            elseif titleType == raceColors then
                PKA_SetKillListSearch("", nil, nil, entry.key, nil, nil, true)
            elseif titleType == genderColors then
                PKA_SetKillListSearch("", nil, nil, nil, entry.key, nil, true)
            end

            -- Ensure the kills list frame is in front
            PKA_FrameManager:BringToFront("KillsList")
        end)
    end)

    -- Label with the name
    local itemLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLabel:SetPoint("TOPLEFT", 0, barY)
    itemLabel:SetText(displayName)
    itemLabel:SetWidth(nameWidth)
    itemLabel:SetJustifyH("LEFT")

    -- Use a gradient color for level bars (blue to red)
    local color
    if titleType == "level" and entry.key ~= "??" then
        local level = tonumber(entry.key) or 0
        local maxLevel = 60

        -- Calculate color gradient from blue (low level) to red (high level)
        local ratio = level / maxLevel
        color = {
            r = math.min(1.0, ratio * 2),             -- Red increases with level
            g = 0.1 + math.max(0, 0.7 - ratio * 0.7), -- Green decreases with level
            b = math.max(0, 1.0 - ratio * 1.5)        -- Blue decreases with level
        }
    elseif titleType == "level" and entry.key == "??" then
        -- Purple for unknown level
        color = {r = 0.8, g = 0.3, b = 0.9}
    elseif titleType == "class" or titleType == "unknownLevelClass" then
        color = getClassColor(entry.key)
    else
        color = titleType and titleType[entry.key] or {r = 0.8, g = 0.8, b = 0.8}
    end

    -- Bar visualization
    local bar = container:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", barX, barY)
    bar:SetSize(barWidth, UI.BAR.HEIGHT)
    bar:SetColorTexture(color.r, color.g, color.b, 0.9)

    local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueLabel:SetPoint("LEFT", bar, "RIGHT", UI.BAR.TEXT_OFFSET, 0)
    valueLabel:SetText(entry.value .. " (" .. string.format("%.1f", entry.value/total*100) .. "%)")

    -- Calculate text width and adjust if needed
    local valueText = entry.value .. " (" .. string.format("%.1f", entry.value/total*100) .. "%)"
    local estimatedTextWidth = string.len(valueText) * 6  -- rough estimate of text width

    -- If we're going to overlap the scrollbar, truncate the percentage
    if barX + barWidth + estimatedTextWidth > (UI.CHART.WIDTH - 25) then
        valueLabel:SetText(entry.value)
    end
end

local function createBarChart(parent, title, data, colorTable, x, y, width, height)
    local container = createContainerWithTitle(parent, title, x, y, width, height)

    local sortedData = sortByValue(data, true)
    local maxValue = sortedData[1] and sortedData[1].value or 0

    local total = 0
    for _, entry in ipairs(sortedData) do
        total = total + entry.value
    end

    -- Sort level data numerically instead of by value
    if (title == "Kills by Level") then
        local sortedLevelData = {}
        -- First handle the "??" level specially
        local unknownLevelEntry
        for i, entry in ipairs(sortedData) do
            if entry.key == "??" then
                unknownLevelEntry = entry
                table.remove(sortedData, i)
                break
            end
        end

        -- Sort known levels numerically
        table.sort(sortedData, function(a, b)
            -- Convert keys to numbers for comparison
            local aNum = tonumber(a.key) or 0
            local bNum = tonumber(b.key) or 0
            return aNum < bNum  -- Sort in ascending order by level
        end)

        -- Add unknown level entry at the end if it exists
        if unknownLevelEntry then
            table.insert(sortedData, unknownLevelEntry)
        end
    end

    local titleType
    if title == "Kills by Class" then
        titleType = "class"
    elseif title == "Level ?? Kills by Class" then
        titleType = "unknownLevelClass"  -- New type for unknown level class chart
    elseif title == "Kills by Zone" then
        titleType = "zone"
    elseif title == "Kills by Level" then
        titleType = "level"
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

    -- Create a clickable button for the row
    local rowButton = CreateFrame("Button", nil, content)
    rowButton:SetSize(260, 20)  -- Wide enough to cover guild name and kill count
    rowButton:SetPoint("TOPLEFT", 0, rowY)

    -- Create highlight with gradient fade effect
    local highlightTexture = CreateGoldHighlight(rowButton, 20)

    -- Add tooltip
    rowButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(guildName)
        GameTooltip:AddLine("Click to show all kills from this guild", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    rowButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Add click handler for guild rows
    rowButton:SetScript("OnClick", function()
        -- First open the kills list frame
        PKA_CreateKillStatsFrame()

        -- Ensure it's on top
        if killStatsFrame then
            -- Keep DIALOG strata but ensure higher frame level
            killStatsFrame:SetFrameLevel(statsFrame:GetFrameLevel() + 10)
        end

        -- Then use our function to set the search text, reset other filters
        PKA_SetKillListSearch(guildName, nil, nil, nil, nil, nil, true)
    end)

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
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 16)
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
                -- Only count players who are in a guild
                if guild ~= "" then
                    guildKills[guild] = (guildKills[guild] or 0) + (data.kills or 0)
                end
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

local function addSummaryStatLine(container, label, value, yPosition, tooltipText)
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, yPosition)
    labelText:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPLEFT", 200, yPosition)
    valueText:SetText(tostring(value))

    -- If tooltip text is provided, create a tooltip trigger frame
    if tooltipText then
        local tooltipFrame = CreateFrame("Frame", nil, container)
        tooltipFrame:SetPoint("TOPLEFT", labelText, "TOPLEFT", 0, 0)
        tooltipFrame:SetPoint("BOTTOMRIGHT", valueText, "BOTTOMRIGHT", 0, 0)

        tooltipFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end)

        tooltipFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        -- Check if this is the most killed player line and make it visually clickable
        if label == "Most Killed Player:" then
            -- Create a button-like appearance
            local button = CreateFrame("Button", nil, tooltipFrame)
            button:SetAllPoints(true)

            -- Create gold highlight with gradient fade effect
            CreateGoldHighlight(button, 20)

            -- Add the click handler directly to the button
            button:SetScript("OnMouseUp", function()
                if value ~= "None (0)" then
                    local playerName = value:match("([^%(]+)"):trim()
                    PKA_CreateKillStatsFrame()
                    C_Timer.After(0.05, function()
                        PKA_SetKillListSearch(playerName, nil, nil, nil, nil, nil, true)
                        PKA_FrameManager:BringToFront("KillsList")
                    end)
                end
            end)
        end
    end

    return yPosition - 20
end

-- Replace this function to remove the credits section
local function addCreditsSection(container, yPosition)
    -- Credits have been moved to the Config UI About tab
    -- This function remains as a stub to avoid breaking references
end

local function createSummaryStats(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Summary Statistics", x, y, width, height)

    -- Call the global calculateStatistics function
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

    -- Add the line for most killed player
    local mostKilledText = stats.mostKilledPlayer .. " (" .. stats.mostKilledCount .. ")"
    statY = addSummaryStatLine(container, "Most Killed Player:", mostKilledText, statY,
        "Click to filter kill list to show only kills of this player")

    -- Add click handler to the most killed player stat line
    if stats.mostKilledPlayer ~= "None" then
        local tooltipFrame = container:GetChildren()
        for _, child in pairs({container:GetChildren()}) do
            if child:IsObjectType("Frame") and child:GetScript("OnEnter") then
                -- This is likely our tooltip frame for the most killed player
                child:SetScript("OnMouseUp", function()
                    PKA_CreateKillStatsFrame()
                    C_Timer.After(0.05, function()
                        PKA_SetKillListSearch(stats.mostKilledPlayer, nil, nil, nil, nil, nil, true)
                        PKA_FrameManager:BringToFront("KillsList")
                    end)
                end)
                break
            end
        end
    end

    statY = addSummaryStatLine(container, "Current Kill Streak:", PKA_CurrentKillStreak or 0, statY,
        "Kill streak will persist through logouts and will only reset when you die in PvP or manually reset your statistics in the Addon Settings.")
    statY = addSummaryStatLine(container, "Highest Kill Streak:", PKA_HighestKillStreak or 0, statY,
        "This record persists through logouts and can only be reset manually through the Reset tab in the Addon Settings.")
    statY = addSummaryStatLine(container, "Highest Multi-Kill:", PKA_HighestMultiKill or 0, statY)

    return container
end

-- Move calculateStatistics to the top as a global function
function calculateStatistics()
    local totalKills = 0
    local uniqueKills = 0
    local totalLevels = 0
    local totalPlayerLevels = 0
    local killsWithLevelData = 0
    local unknownLevelKills = 0
    local mostKilledPlayer = nil
    local mostKilledCount = 0

    if PKA_KillCounts then
        for nameWithLevel, data in pairs(PKA_KillCounts) do
            if data then
                uniqueKills = uniqueKills + 1
                local kills = data.kills or 0
                totalKills = totalKills + kills

                -- Track most killed player
                if kills > mostKilledCount then
                    local playerName = nameWithLevel:match("([^:]+)")
                    mostKilledPlayer = playerName
                    mostKilledCount = kills
                end

                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                if levelNum == -1 then
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
        avgKillsPerPlayer = avgKillsPerPlayer,
        mostKilledPlayer = mostKilledPlayer or "None",
        mostKilledCount = mostKilledCount
    }
end

-- Update the calculateStatistics function to include most killed player
local function calculateStatistics()
    local totalKills = 0
    local uniqueKills = 0
    local totalLevels = 0
    local totalPlayerLevels = 0
    local killsWithLevelData = 0
    local unknownLevelKills = 0
    local mostKilledPlayer = nil
    local mostKilledCount = 0

    if PKA_KillCounts then
        for nameWithLevel, data in pairs(PKA_KillCounts) do
            if data then
                uniqueKills = uniqueKills + 1
                local kills = data.kills or 0
                totalKills = totalKills + kills

                -- Track most killed player
                if kills > mostKilledCount then
                    local playerName = nameWithLevel:match("([^:]+)")
                    mostKilledPlayer = playerName
                    mostKilledCount = kills
                end

                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                if levelNum == -1 then
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
        avgKillsPerPlayer = avgKillsPerPlayer,
        mostKilledPlayer = mostKilledPlayer or "None",
        mostKilledCount = mostKilledCount
    }
end

-- Update the gatherStatistics function to remove unknownLevel check
local function gatherStatistics()
    local classData = {}
    local raceData = {}
    local genderData = {}
    local unknownLevelClassData = {}
    local zoneData = {}
    local levelData = {} -- Changed to store individual levels
    local guildStatusData = {    -- Add this new table
        ["In Guild"] = 0,
        ["No Guild"] = 0
    }

    if not PKA_KillCounts then
        return {}, {}, {}, {}, {}, {}, {}  -- Add an extra return value
    end

    for nameWithLevel, data in pairs(PKA_KillCounts) do
        if data then
            local class = data.class or "Unknown"
            classData[class] = (classData[class] or 0) + 1

            local level = nameWithLevel:match(":(%S+)")
            local levelNum = tonumber(level or "0") or 0
            local kills = data.kills or 1

            if levelNum == -1 then
                unknownLevelClassData[class] = (unknownLevelClassData[class] or 0) + kills
                -- Add unknown levels to levelData for proper display in the level chart
                levelData["??"] = (levelData["??"] or 0) + kills
            else
                -- Track individual levels
                if levelNum > 0 and levelNum <= 60 then
                    levelData[tostring(levelNum)] = (levelData[tostring(levelNum)] or 0) + kills
                end
            end

            local race = data.race or "Unknown"
            raceData[race] = (raceData[race] or 0) + 1

            local gender = data.gender or "Unknown"
            genderData[gender] = (genderData[gender] or 0) + 1

            -- Track zone data
            local zone = data.zone or "Unknown"
            zoneData[zone] = (zoneData[zone] or 0) + kills

            -- Track guild status
            local guild = data.guild or ""
            if guild ~= "" then
                guildStatusData["In Guild"] = guildStatusData["In Guild"] + kills
            else
                guildStatusData["No Guild"] = guildStatusData["No Guild"] + kills
            end
        end
    end

    return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData
end

local function createScrollableLeftPanel(parent)
    local leftPanel = CreateFrame("Frame", nil, parent)
    leftPanel:SetPoint("TOPLEFT", 0, 0)
    leftPanel:SetPoint("BOTTOMLEFT", 0, 0)
    leftPanel:SetWidth(430)

    local containerFrame = CreateFrame("Frame", nil, parent)
    containerFrame:SetPoint("TOPLEFT", UI.LEFT_SCROLL_PADDING, -UI.TOP_PADDING)
    containerFrame:SetPoint("BOTTOMLEFT", UI.LEFT_SCROLL_PADDING, 20)
    containerFrame:SetWidth(400 - UI.LEFT_SCROLL_PADDING)

    local scrollFrame = CreateFrame("ScrollFrame", nil, containerFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(375 - UI.LEFT_SCROLL_PADDING)

    scrollFrame:SetScrollChild(content)

    local scrollBarName = scrollFrame:GetName() and scrollFrame:GetName().."ScrollBar" or nil
    local scrollBar = scrollBarName and _G[scrollBarName] or nil

    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -18, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -18, 16)
    end

    return content, scrollFrame
end

local function setupMainFrame()
    local frame = CreateFrame("Frame", "PKAStatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.FRAME.WIDTH, UI.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

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

    -- Add a vertical separator line
    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", 430, -5)
    separator:SetPoint("BOTTOMLEFT", 430, 5)
    separator:SetWidth(1)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    return frame
end

local function hasEnoughData()
    local totalKills = 0
    local uniqueKills = 0

    if PKA_KillCounts then
        for _, data in pairs(PKA_KillCounts) do
            if data then
                uniqueKills = uniqueKills + 1
                totalKills = totalKills + (data.kills or 1)
            end
        end
    end

    return totalKills >= 10 or uniqueKills >= 5
end

local function createEmptyStatsFrame()
    local frame = CreateFrame("Frame", "PKAStatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.FRAME.WIDTH, 200)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Remove this as it's handled by the frame manager now
    -- tinsert(UISpecialFrames, "PKAStatisticsFrame")

    frame.TitleText:SetText("Player Kill Statistics")

    -- Create message text
    local messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    messageText:SetPoint("CENTER", 0, 0)
    messageText:SetText("You need at least 10 kills or 5 unique kills\nto view detailed statistics.")
    messageText:SetJustifyH("CENTER")

    return frame
end

-- Modify the createStatisticsFrame function to include the new chart
function PKA_CreateStatisticsFrame()
    -- Check if we should destroy and recreate the frame based on data status
    local hasData = hasEnoughData()

    -- Always recreate the frame when it's reopened to prevent crashes
    if statsFrame then
        statsFrame:Hide()
        PKA_FrameManager:HideFrame("Statistics")
        statsFrame = nil
    end

    -- Remove from UISpecialFrames if present
    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PKAStatisticsFrame") then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    if not hasData then
        statsFrame = createEmptyStatsFrame()
        PKA_FrameManager:RegisterFrame(statsFrame, "Statistics")
        return
    end

    -- Create the main statistics frame
    statsFrame = setupMainFrame()
    statsFrame:SetScript("OnKeyDown", nil) -- Remove ESC key handling from setupMainFrame
    PKA_FrameManager:RegisterFrame(statsFrame, "Statistics")

    -- Fill the frame with content
    PKA_UpdateStatisticsFrame(statsFrame)
end

-- New function to update statistics frame content
function PKA_UpdateStatisticsFrame(frame)
    if not frame then return end

    -- Clear existing content if any
    if frame.leftScrollContent then
        frame.leftScrollContent:SetParent(nil)
        frame.leftScrollContent = nil
    end

    if frame.guildTable then
        frame.guildTable:SetParent(nil)
        frame.guildTable = nil
    end

    if frame.summaryStats then
        frame.summaryStats:SetParent(nil)
        frame.summaryStats = nil
    end

    -- If this is the empty frame, nothing more to do
    if frame:GetHeight() < 400 then return end

    -- Get fresh statistics
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData = gatherStatistics()

    -- Create new content
    local leftScrollContent, leftScrollFrame = createScrollableLeftPanel(frame)
    frame.leftScrollContent = leftScrollContent
    frame.leftScrollFrame = leftScrollFrame

    local classChartHeight = calculateChartHeight(classData)
    local raceChartHeight = calculateChartHeight(raceData)
    local genderChartHeight = calculateChartHeight(genderData)
    local levelChartHeight = calculateChartHeight(levelData)
    local zoneChartHeight = calculateChartHeight(zoneData)

    local yOffset = 0
    createBarChart(leftScrollContent, "Kills by Class", classData, nil, 0, yOffset, UI.CHART.WIDTH, classChartHeight)

    yOffset = yOffset - classChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Race", raceData, raceColors, 0, yOffset, UI.CHART.WIDTH, raceChartHeight)

    yOffset = yOffset - raceChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Gender", genderData, genderColors, 0, yOffset, UI.CHART.WIDTH, genderChartHeight)

    yOffset = yOffset - genderChartHeight - UI.CHART.PADDING

    -- Add the new Guild Status chart
    local guildStatusChartHeight = calculateChartHeight(guildStatusData)
    local guildStatusColors = {
        ["In Guild"] = {r = 0.2, g = 0.8, b = 0.2},    -- Green for guild members
        ["No Guild"] = {r = 0.8, g = 0.2, b = 0.2}     -- Red for guildless
    }
    createBarChart(leftScrollContent, "Kills by Guild Status", guildStatusData, guildStatusColors, 0, yOffset, UI.CHART.WIDTH, guildStatusChartHeight)

    yOffset = yOffset - guildStatusChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Level", levelData, nil, 0, yOffset, UI.CHART.WIDTH, levelChartHeight)

    yOffset = yOffset - levelChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Zone", zoneData, nil, 0, yOffset, UI.CHART.WIDTH, zoneChartHeight)

    local totalHeight = -(yOffset) + 25
    leftScrollContent:SetHeight(totalHeight)

    local summaryStatsWidth = 380
    frame.guildTable = createGuildTable(frame, 440, -UI.TOP_PADDING, summaryStatsWidth, UI.GUILD_LIST.HEIGHT)
    frame.summaryStats = createSummaryStats(frame, 440, -UI.GUILD_LIST.HEIGHT - UI.TOP_PADDING - 20, summaryStatsWidth, 250)
end
