local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

local statisticsFrame = nil

local function CreateGoldHighlight(parent, height)
    local highlight = parent:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(true)

    local useNewAPI = highlight.SetGradient and type(highlight.SetGradient) == "function" and pcall(function()
        highlight:SetGradient("HORIZONTAL", {
            r = 1,
            g = 1,
            b = 1,
            a = 1
        }, {
            r = 1,
            g = 1,
            b = 1,
            a = 1
        })
        return true
    end)

    if useNewAPI then
        highlight:SetColorTexture(1, 0.82, 0, 0.6)
        pcall(function()
            highlight:SetGradient("HORIZONTAL", {
                r = 1,
                g = 0.82,
                b = 0,
                a = 0.3
            }, {
                r = 1,
                g = 0.82,
                b = 0,
                a = 0.8
            })
        end)
    else
        highlight:SetColorTexture(1, 0.82, 0, 0.5)

        local leftGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        leftGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        leftGradient:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        leftGradient:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        leftGradient:SetWidth(parent:GetWidth() / 2)
        leftGradient:SetHeight(height)

        pcall(function()
            leftGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.3, 1, 0.82, 0, 0.7)
        end)

        if leftGradient:GetVertexColor() == 1 and select(2, leftGradient:GetVertexColor()) == 1 then
            leftGradient:SetVertexColor(1, 0.82, 0, 0.6)
        end

        local rightGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        rightGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        rightGradient:SetPoint("TOPLEFT", leftGradient, "TOPRIGHT", 0, 0)
        rightGradient:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

        pcall(function()
            rightGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0.3)
        end)

        if rightGradient:GetVertexColor() == 1 and select(2, rightGradient:GetVertexColor()) == 1 then
            rightGradient:SetVertexColor(1, 0.82, 0, 0.6)
        end
    end

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

local UI = {
    FRAME = {
        WIDTH = 850,
        HEIGHT = 700
    },
    CHART = {
        WIDTH = 360,
        PADDING = 1
    },
    BAR = {
        HEIGHT = 16,
        SPACING = 3,
        TEXT_OFFSET = 5
    },
    GUILD_LIST = {
        WIDTH = 375,
        HEIGHT = 240
    },
    TITLE_SPACING = 3,
    TOP_PADDING = 40,
    LEFT_SCROLL_PADDING = 20,
    ZONE_NAME_WIDTH = 150,
    STANDARD_NAME_WIDTH = 80
}

local raceColors = {
    ["Human"] = {
        r = 1.00,
        g = 0.82,
        b = 0.60
    },
    ["Dwarf"] = {
        r = 0.77,
        g = 0.12,
        b = 0.23
    },
    ["NightElf"] = {
        r = 0.47,
        g = 0.34,
        b = 0.80
    },
    ["Gnome"] = {
        r = 1.00,
        g = 0.57,
        b = 0.93
    },
    ["Orc"] = {
        r = 0.10,
        g = 0.67,
        b = 0.10
    },
    ["Troll"] = {
        r = 0.00,
        g = 0.76,
        b = 0.78
    },
    ["Tauren"] = {
        r = 0.87,
        g = 0.55,
        b = 0.20
    },
    ["Undead"] = {
        r = 0.33,
        g = 0.69,
        b = 0.33
    }
}

local genderColors = {
    ["Male"] = {
        r = 0.40,
        g = 0.60,
        b = 1.00
    },
    ["Female"] = {
        r = 1.00,
        g = 0.41,
        b = 0.71
    }
}

local function countOccurrences(items)
    local counts = {}
    for _, item in pairs(items) do
        counts[item] = (counts[item] or 0) + 1
    end
    return counts
end

local function sortByValue(tbl, descending)
    if not tbl then
        return {}
    end

    local sorted = {}
    for k, v in pairs(tbl) do
        local safeKey = k or "Unknown"
        local safeValue = v or 0
        table.insert(sorted, {
            key = safeKey,
            value = safeValue
        })
    end

    if #sorted == 0 then
        return {}
    end

    if descending then
        table.sort(sorted, function(a, b)
            if not a.value then
                return false
            end
            if not b.value then
                return true
            end
            return a.value > b.value
        end)
    else
        table.sort(sorted, function(a, b)
            if not a.value then
                return true
            end
            if not b.value then
                return false
            end
            return a.value < b.value
        end)
    end

    return sorted
end

local function properCase(str)
    if not str or str == "" then
        return "Unknown"
    end
    if str:len() <= 1 then
        return str:upper()
    end
    return str:sub(1, 1):upper() .. str:sub(2):lower()
end

local function getClassColor(class)
    if not class or class == "Unknown" then
        return {
            r = 0.8,
            g = 0.8,
            b = 0.8
        }
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
            ["WARRIOR"] = {
                r = 0.78,
                g = 0.61,
                b = 0.43
            },
            ["PALADIN"] = {
                r = 0.96,
                g = 0.55,
                b = 0.73
            },
            ["HUNTER"] = {
                r = 0.67,
                g = 0.83,
                b = 0.45
            },
            ["ROGUE"] = {
                r = 1.00,
                g = 0.96,
                b = 0.41
            },
            ["PRIEST"] = {
                r = 1.00,
                g = 1.00,
                b = 1.00
            },
            ["SHAMAN"] = {
                r = 0.00,
                g = 0.44,
                b = 0.87
            },
            ["MAGE"] = {
                r = 0.25,
                g = 0.78,
                b = 0.92
            },
            ["WARLOCK"] = {
                r = 0.53,
                g = 0.53,
                b = 0.93
            },
            ["DRUID"] = {
                r = 1.00,
                g = 0.49,
                b = 0.04
            }
        }

        return fallbackColors[classUpper] or {
            r = 0.8,
            g = 0.8,
            b = 0.8
        }
    end
end

local function calculateChartHeight(data)
    local entries = 0
    for _, numKills in pairs(data) do
        if numKills > 0 then
            entries = entries + 1
        end
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
    elseif titleType == "hour" then
        local hour = tonumber(entry.key)
        if hour then
            local endHour = (hour + 1) % 24
            displayName = string.format("%02d - %02d", hour, endHour)
        end
    elseif titleType == "weekday" then
        local weekdayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
        local weekday = tonumber(entry.key)
        if weekday and weekdayNames[weekday] then
            displayName = weekdayNames[weekday]
        end
    elseif titleType == "month" then
        local monthNames = {"January", "February", "March", "April", "May", "June",
                           "July", "August", "September", "October", "November", "December"}
        local month = tonumber(entry.key)
        if month and monthNames[month] then
            displayName = monthNames[month]
        end
    end

    local barButton = CreateFrame("Button", nil, container)
    barButton:SetSize(UI.CHART.WIDTH, UI.BAR.HEIGHT)
    barButton:SetPoint("TOPLEFT", 0, barY)

    -- Only add highlight and click functionality for clickable chart types
    local isClickable = titleType ~= "hour" and titleType ~= "weekday" and titleType ~= "month"

    if isClickable then
        local highlightTexture = CreateGoldHighlight(barButton, UI.BAR.HEIGHT)
    end

    barButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(displayName)

        if titleType == "class" or titleType == "unknownLevelClass" then
            GameTooltip:AddLine("Click to show all kills for this class", 1, 1, 1, true)
        elseif titleType == "zone" then
            GameTooltip:AddLine("Click to show all kills for this zone", 1, 1, 1, true)
        elseif titleType == "level" then
            if entry.key == "??" then
                GameTooltip:AddLine("Click to show all kill for level ??", 1, 1, 1, true)
            else
                GameTooltip:AddLine("Click to show all kills for this level", 1, 1, 1, true)
            end
        elseif titleType == "hour" then
            local hour = tonumber(entry.key)
            if hour then
                local startTime = string.format("%02d:00", hour)
                local endTime = string.format("%02d:00", (hour + 1) % 24)
                GameTooltip:AddLine("Kills between " .. startTime .. " and " .. endTime, 1, 1, 1, true)
            end
        elseif titleType == "weekday" then
            GameTooltip:AddLine("Kills on " .. displayName, 1, 1, 1, true)
        elseif titleType == "month" then
            GameTooltip:AddLine("Kills in " .. displayName, 1, 1, 1, true)
        elseif titleType == raceColors then
            GameTooltip:AddLine("Click to show all kills for this race", 1, 1, 1, true)
        elseif titleType == genderColors then
            GameTooltip:AddLine("Click to show all kills for this gender", 1, 1, 1, true)
        end

        GameTooltip:Show()
    end)

    barButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Only add click functionality for clickable chart types
    if isClickable then
        barButton:SetScript("OnClick", function()
            PSC_CreateKillsListFrame()
            C_Timer.After(0.05, function()
                if titleType == "class" or titleType == "unknownLevelClass" then
                    PSC_SetKillListSearch("", nil, entry.key, nil, nil, nil, true)
                elseif titleType == "zone" then
                    PSC_SetKillListSearch("", nil, nil, nil, nil, entry.key, true)
                elseif titleType == "level" then
                    if entry.key == "??" then
                        PSC_SetKillListLevelRange(-1, -1, true)
                    else
                        local level = tonumber(entry.key)
                        if level then
                            PSC_SetKillListLevelRange(level, level, true)
                        end
                    end
                elseif titleType == raceColors then
                    PSC_SetKillListSearch("", nil, nil, entry.key, nil, nil, true)
                elseif titleType == genderColors then
                    PSC_SetKillListSearch("", nil, nil, nil, entry.key, nil, true)
                end

                PSC_FrameManager:BringToFront("KillsList")
            end)
        end)
    end

    local itemLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLabel:SetPoint("TOPLEFT", 0, barY)
    itemLabel:SetText(displayName)
    itemLabel:SetWidth(nameWidth)
    itemLabel:SetJustifyH("LEFT")

    local color
    if titleType == "level" and entry.key ~= "??" then
        local level = tonumber(entry.key) or 0
        local maxLevel = 60

        local ratio = level / maxLevel
        color = {
            r = math.min(1.0, ratio * 2),
            g = 0.1 + math.max(0, 0.7 - ratio * 0.7),
            b = math.max(0, 1.0 - ratio * 1.5)
        }
    elseif titleType == "level" and entry.key == "??" then
        color = {
            r = 0.8,
            g = 0.3,
            b = 0.9
        }
    elseif titleType == "class" or titleType == "unknownLevelClass" then
        color = getClassColor(entry.key)
    elseif titleType == "hour" then
        -- Light red for hour charts
        color = {
            r = 1.0,
            g = 0.6,
            b = 0.6
        }
    elseif titleType == "weekday" then
        -- Light blue for weekday charts
        color = {
            r = 0.6,
            g = 0.8,
            b = 1.0
        }
    elseif titleType == "month" then
        -- Light yellow for month charts
        color = {
            r = 1.0,
            g = 1.0,
            b = 0.6
        }
    else
        color = titleType and titleType[entry.key] or {
            r = 0.8,
            g = 0.8,
            b = 0.8
        }
    end

    local bar = container:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", barX, barY)
    bar:SetSize(barWidth, UI.BAR.HEIGHT)
    bar:SetColorTexture(color.r, color.g, color.b, 0.9)

    local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueLabel:SetPoint("LEFT", bar, "RIGHT", UI.BAR.TEXT_OFFSET, 0)
    valueLabel:SetText(entry.value .. " (" .. string.format("%.1f", entry.value / total * 100) .. "%)")

    local valueText = entry.value .. " (" .. string.format("%.1f", entry.value / total * 100) .. "%)"
    local estimatedTextWidth = string.len(valueText) * 6

    if barX + barWidth + estimatedTextWidth > (UI.CHART.WIDTH - 25) then
        valueLabel:SetText(entry.value)
    end
end

local function createBarChart(parent, title, data, colorTable, x, y, width, height)
    local container = createContainerWithTitle(parent, title, x, y, width, height)

    local sortedData = sortByValue(data, true)
    local filteredData = {}
    for _, entry in ipairs(sortedData) do
        if entry.value > 0 then
            table.insert(filteredData, entry)
        end
    end

    local maxValue = filteredData[1] and filteredData[1].value or 0

    local total = 0
    for _, entry in ipairs(filteredData) do
        total = total + entry.value
    end

    if (title == "Kills by Level") then
        local sortedLevelData = {}
        local unknownLevelEntry
        for i, entry in ipairs(filteredData) do
            if entry.key == "??" then
                unknownLevelEntry = entry
                table.remove(filteredData, i)
                break
            end
        end

        table.sort(filteredData, function(a, b)
            local aNum = tonumber(a.key) or 0
            local bNum = tonumber(b.key) or 0
            return aNum < bNum
        end)

        if unknownLevelEntry then
            table.insert(filteredData, unknownLevelEntry)
        end
    elseif (title == "Kills by Hour of Day") then
        -- Sort hours numerically from 0 to 23
        table.sort(filteredData, function(a, b)
            local aNum = tonumber(a.key) or 0
            local bNum = tonumber(b.key) or 0
            return aNum < bNum
        end)
    elseif (title == "Kills by Weekday") then
        -- Sort weekdays from Sunday (1) to Saturday (7)
        table.sort(filteredData, function(a, b)
            local aNum = tonumber(a.key) or 0
            local bNum = tonumber(b.key) or 0
            return aNum < bNum
        end)
    elseif (title == "Kills by Month") then
        -- Sort months from January (1) to December (12)
        table.sort(filteredData, function(a, b)
            local aNum = tonumber(a.key) or 0
            local bNum = tonumber(b.key) or 0
            return aNum < bNum
        end)
    end

    local titleType
    if title == "Kills by Class" then
        titleType = "class"
    elseif title == "Level ?? Kills by Class" then
        titleType = "unknownLevelClass"
    elseif title == "Kills by Zone" then
        titleType = "zone"
    elseif title == "Kills by Level" then
        titleType = "level"
    elseif title == "Kills by Hour of Day" then
        titleType = "hour"
    elseif title == "Kills by Weekday" then
        titleType = "weekday"
    elseif title == "Kills by Month" then
        titleType = "month"
    else
        titleType = colorTable
    end

    for i, entry in ipairs(filteredData) do
        createBar(container, entry, i, maxValue, total, titleType)
    end

    return container
end

local function createGuildTableRow(content, entry, index, firstRowSpacing)
    if not entry then
        return
    end

    local rowY = index == 1 and -firstRowSpacing or -(firstRowSpacing + ((index - 1) * 20))

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

    -- Create the button with proper height to not overlap the next row
    local rowButton = CreateFrame("Button", nil, content)
    rowButton:SetPoint("TOPLEFT", guildText, "TOPLEFT", 0, 0)
    rowButton:SetPoint("BOTTOMRIGHT", killsText, "BOTTOMRIGHT", 10, 0) -- Remove the -15 offset

    -- Use a smaller height value for the highlight (16 matches the font height better)
    local highlightTexture = CreateGoldHighlight(rowButton, 16)

    rowButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(guildName)
        GameTooltip:AddLine("Click to show all kills for this guild", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    rowButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    rowButton:SetScript("OnClick", function()
        PSC_CreateKillsListFrame()

        if PSC_KillsListFrame then
            ---@diagnostic disable-next-line: need-check-nil, undefined-field
            PSC_KillsListFrame:SetFrameLevel(statisticsFrame:GetFrameLevel() + 10)
        end

        PSC_SetKillListSearch(guildName, nil, nil, nil, nil, nil, true)
    end)
end

local function createScrollFrame(container, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, -20)
    scrollFrame:SetSize(width + 5, height - 21)

    local scrollBarName = scrollFrame:GetName() and scrollFrame:GetName() .. "ScrollBar" or nil
    local scrollBar = scrollBarName and _G[scrollBarName] or nil

    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 16)
    end

    return scrollFrame
end

function PSC_CalculateGuildKills()
    local guildKills = {}

    for _, characterData in pairs(PSC_DB.PlayerKillCounts.Characters) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                local playerNameWithoutLevel = nameWithLevel:match("([^:]+)")
                local kills = killData.kills or 0

                local infoKey = PSC_GetInfoKeyFromName(playerNameWithoutLevel)

                if PSC_DB.PlayerInfoCache[infoKey] then
                    local guild = PSC_DB.PlayerInfoCache[infoKey].guild
                    if guild ~= "" then
                        guildKills[guild] = (guildKills[guild] or 0) + kills
                    end
                end
            end
        end
    end

    return guildKills
end

local function createGuildTable(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Guild Kills", x, y, width, height)

    local guildKills = PSC_CalculateGuildKills()
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
    valueText:SetPoint("TOPLEFT", 150, yPosition)
    valueText:SetText(tostring(value))

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

        if label == "Most killed player:" then
            local button = CreateFrame("Button", nil, tooltipFrame)
            ---@diagnostic disable-next-line: param-type-mismatch
            button:SetAllPoints(true)

            CreateGoldHighlight(button, 20)

            button:SetScript("OnMouseUp", function()
                if value ~= "None (0)" then
                    local playerName = value:match("([^%(]+)"):trim()
                    PSC_CreateKillsListFrame()
                    C_Timer.After(0.05, function()
                        PSC_SetKillListSearch(playerName, nil, nil, nil, nil, nil, true)
                        PSC_FrameManager:BringToFront("KillsList")
                    end)
                end
            end)
        end
    end

    return yPosition - 20
end

function PSC_CalculateSummaryStatistics(charactersToProcess)
    local totalKills = 0
    local uniqueKills = 0
    local totalLevels = 0  -- Target levels
    local totalPlayerLevelSum = 0  -- Sum of player levels at time of kills
    local killsWithLevelData = 0
    local levelDiffSum = 0  -- For direct level difference calculation
    local unknownLevelKills = 0

    -- For improved unique player level calculation
    local uniquePlayerLevels = {}

    local mostKilledPlayer = nil
    local mostKilledCount = 0
    local highestKillStreak = 0
    local highestKillStreakCharacter = ""
    local currentKillStreak = 0
    local highestMultiKill = 0
    local highestMultiKillCharacter = ""

    local killsPerPlayer = {}

    -- New statistics tracking
    local weekdayKills = {0, 0, 0, 0, 0, 0, 0} -- Sunday=1, Monday=2, etc.
    local hourlyKills = {}
    for i = 0, 23 do
        hourlyKills[i] = 0
    end
    local monthlyKills = {}
    for i = 1, 12 do
        monthlyKills[i] = 0
    end
    local firstKillTimestamp = nil
    local lastKillTimestamp = nil

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterKey == PSC_GetCharacterKey() then
            currentKillStreak = characterData.CurrentKillStreak
        end

        if PSC_DB.ShowAccountWideStats then
            if characterData.HighestKillStreak > highestKillStreak then
                highestKillStreak = characterData.HighestKillStreak
                highestKillStreakCharacter = characterKey
            end

            if characterData.HighestMultiKill > highestMultiKill then
                highestMultiKill = characterData.HighestMultiKill
                highestMultiKillCharacter = characterKey
            end
        else
            highestMultiKill = characterData.HighestMultiKill
            highestKillStreak = characterData.HighestKillStreak
        end

        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                local kills = killData.kills or 0
                local playerName = nameWithLevel:match("([^:]+)")

                killsPerPlayer[playerName] = (killsPerPlayer[playerName] or 0) + kills

                uniqueKills = uniqueKills + 1
                totalKills = totalKills + kills

                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                if levelNum > 0 then
                    if not uniquePlayerLevels[playerName] then
                        uniquePlayerLevels[playerName] = {
                            sum = 0,
                            count = 0
                        }
                    end

                    -- Add this level instance to the player's running total
                    uniquePlayerLevels[playerName].sum = uniquePlayerLevels[playerName].sum + levelNum
                    uniquePlayerLevels[playerName].count = uniquePlayerLevels[playerName].count + 1
                end

                -- Count unknown level kills
                if levelNum == -1 then
                    unknownLevelKills = unknownLevelKills + kills
                end

                -- Process kill locations for more accurate level difference data
                if killData.killLocations and #killData.killLocations > 0 then
                    for _, location in ipairs(killData.killLocations) do
                        local targetLevel = levelNum
                        local playerLevel = location.playerLevel or 0
                        local timestamp = location.timestamp

                        -- Track timestamps for time-based statistics
                        if timestamp then
                            if not firstKillTimestamp or timestamp < firstKillTimestamp then
                                firstKillTimestamp = timestamp
                            end
                            if not lastKillTimestamp or timestamp > lastKillTimestamp then
                                lastKillTimestamp = timestamp
                            end

                            -- Calculate weekday, hour, and month statistics
                            local dateInfo = date("*t", timestamp)
                            if dateInfo then
                                weekdayKills[dateInfo.wday] = weekdayKills[dateInfo.wday] + 1
                                hourlyKills[dateInfo.hour] = hourlyKills[dateInfo.hour] + 1
                                monthlyKills[dateInfo.month] = monthlyKills[dateInfo.month] + 1
                            end
                        end

                        if targetLevel > 0 and playerLevel > 0 then
                            levelDiffSum = levelDiffSum + (playerLevel - targetLevel)
                            killsWithLevelData = killsWithLevelData + 1
                        end

                        if playerLevel > 0 then
                            totalPlayerLevelSum = totalPlayerLevelSum + playerLevel
                        end
                    end
                else
                    -- Fall back to the old method if no detailed locations
                    if levelNum > 0 and killData.playerLevel and killData.playerLevel > 0 then
                        levelDiffSum = levelDiffSum + (killData.playerLevel - levelNum) * kills
                        killsWithLevelData = killsWithLevelData + kills
                    end

                    if killData.playerLevel and killData.playerLevel > 0 then
                        totalPlayerLevelSum = totalPlayerLevelSum + killData.playerLevel * kills
                    end
                end

                -- Calculate target level sum for average
                if levelNum > 0 then
                    totalLevels = totalLevels + levelNum * kills
                end
            end
        end
    end

    for playerName, kills in pairs(killsPerPlayer) do
        if kills > mostKilledCount then
            mostKilledPlayer = playerName
            mostKilledCount = kills
        end
    end

    -- Calculate average of unique victim levels (first average each player's levels, then average those)
    local uniqueLevelSum = 0
    local uniquePlayersWithLevel = 0

    for _, playerLevelData in pairs(uniquePlayerLevels) do
        if playerLevelData.count > 0 then
            -- Add this player's average level to the sum
            uniqueLevelSum = uniqueLevelSum + (playerLevelData.sum / playerLevelData.count)
            uniquePlayersWithLevel = uniquePlayersWithLevel + 1
        end
    end

    -- Find busiest weekday
    local busiestWeekday = "None"
    local maxWeekdayKills = 0
    local weekdayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    for i, kills in ipairs(weekdayKills) do
        if kills > maxWeekdayKills then
            maxWeekdayKills = kills
            busiestWeekday = weekdayNames[i]
        end
    end

    -- Find busiest hour
    local busiestHour = "None"
    local maxHourlyKills = 0
    for hour, kills in pairs(hourlyKills) do
        if kills > maxHourlyKills then
            maxHourlyKills = kills
            busiestHour = string.format("%02d:00 - %02d:00", hour, (hour + 1) % 24)
        end
    end

    -- Find busiest month
    local busiestMonth = "None"
    local maxMonthlyKills = 0
    local monthNames = {"January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"}
    for i, kills in ipairs(monthlyKills) do
        if kills > maxMonthlyKills then
            maxMonthlyKills = kills
            busiestMonth = monthNames[i]
        end
    end

    -- Calculate average kills per day
    local avgKillsPerDay = 0
    if firstKillTimestamp and lastKillTimestamp then
        local activitySpanDays = math.floor((lastKillTimestamp - firstKillTimestamp) / 86400) + 1
        if activitySpanDays > 0 then
            avgKillsPerDay = totalKills / activitySpanDays
        end
    end

    local knownLevelKills = totalKills - unknownLevelKills
    local avgLevel = knownLevelKills > 0 and (totalLevels / knownLevelKills) or 0
    local avgUniqueLevel = uniquePlayersWithLevel > 0 and (uniqueLevelSum / uniquePlayersWithLevel) or 0
    local avgPlayerLevel = totalKills > 0 and (totalPlayerLevelSum / totalKills) or 0
    local avgLevelDiff = killsWithLevelData > 0 and (levelDiffSum / killsWithLevelData) or 0
    local avgKillsPerPlayer = uniqueKills > 0 and (totalKills / uniqueKills) or 0

    return {
        totalKills = totalKills,
        uniqueKills = uniqueKills,
        unknownLevelKills = unknownLevelKills,
        avgLevel = avgUniqueLevel, -- Using the improved unique player average
        avgLevelDiff = avgLevelDiff,
        avgKillsPerPlayer = avgKillsPerPlayer,
        mostKilledPlayer = mostKilledPlayer or "None",
        mostKilledCount = mostKilledCount,
        currentKillStreak = currentKillStreak,
        highestKillStreak = highestKillStreak,
        highestMultiKill = highestMultiKill,
        highestKillStreakCharacter = highestKillStreakCharacter,
        highestMultiKillCharacter = highestMultiKillCharacter,
        -- Only the 4 requested time-based statistics
        busiestWeekday = busiestWeekday,
        busiestWeekdayKills = maxWeekdayKills,
        busiestHour = busiestHour,
        busiestHourKills = maxHourlyKills,
        busiestMonth = busiestMonth,
        busiestMonthKills = maxMonthlyKills,
        avgKillsPerDay = avgKillsPerDay
    }
end

local function createSummaryStats(parent, x, y, width, height)
    local spacing_between_sections = 10
    local container = createContainerWithTitle(parent, "Summary Statistics", x, y, width, height)

    local charactersToProcess = GetCharactersToProcessForStatistics()
    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)
    local statY = -22

    statY = addSummaryStatLine(container, "Total player kills:", stats.totalKills, statY,
        "Total number of players you have killed.")
    statY = addSummaryStatLine(container, "Unique players killed:", stats.uniqueKills, statY,
        "Total number of unique players you have killed. Mlitple kills of the same player are counted only once.")
    statY = addSummaryStatLine(container, "Level ?? kills:", stats.unknownLevelKills, statY,
        "Total number of times you have killed a level ?? player.")
    local mostKilledText = stats.mostKilledPlayer .. " (" .. stats.mostKilledCount .. ")"
    statY = addSummaryStatLine(container, "Most killed player:", mostKilledText, statY - spacing_between_sections,
        "Click to show all kills of this player")

    if stats.mostKilledPlayer ~= "None" then
        local tooltipFrame = container:GetChildren()
        for _, child in pairs({container:GetChildren()}) do
---@diagnostic disable-next-line: undefined-field
            if child:IsObjectType("Frame") and child:GetScript("OnEnter") then
---@diagnostic disable-next-line: undefined-field
                child:SetScript("OnMouseUp", function()
                    PSC_CreateKillsListFrame()
                    C_Timer.After(0.05, function()
                        PSC_SetKillListSearch(stats.mostKilledPlayer, nil, nil, nil, nil, nil, true)
                        PSC_FrameManager:BringToFront("KillsList")
                    end)
                end)
                break
            end
        end
    end

    statY = addSummaryStatLine(container, "Avg. victim level:", string.format("%.1f", stats.avgLevel), statY - spacing_between_sections,
        "Average level of players you have killed.")
    statY = addSummaryStatLine(container, "Avg. kills per player:", string.format("%.2f", stats.avgKillsPerPlayer), statY,
        "Average number of kills per unique player.")
    local levelDiffText = string.format("%.1f", stats.avgLevelDiff) ..
                              (stats.avgLevelDiff > 0 and " (you're higher)" or " (you're lower)")
    statY = addSummaryStatLine(container, "Avg. level difference:", levelDiffText, statY,
        "Average level difference between you and the players you have killed.")


    statY = addSummaryStatLine(container, "Current kill streak:", stats.currentKillStreak, statY - spacing_between_sections,
        "Your current kill streak on this character. Streaks persist through logouts and only end when you die or manually reset your statistics in the addon settings.")

    local highestKillStreakTooltip = "The highest kill streak you ever achieved across all characters."
    local highestMultiKillTooltip = "The highest number of kills you achieved while staying in combat across all characters."
    local highestKillStreakValueText = tostring(stats.highestKillStreak)
    if stats.highestKillStreak > 0 then
        highestKillStreakValueText = highestKillStreakValueText .. " (" .. stats.highestKillStreakCharacter .. ")"
    end
    local highestMultiKillValueText = tostring(stats.highestMultiKill)
    if stats.highestMultiKill > 0 then
        highestMultiKillValueText = highestMultiKillValueText .. " (" .. stats.highestMultiKillCharacter .. ")"
    end
    if not PSC_DB.ShowAccountWideStats then
        highestKillStreakTooltip = "The highest kill streak you achieved on this character."
        highestKillStreakValueText = tostring(stats.highestKillStreak)
        highestMultiKillTooltip = "The highest number of kills you achieved while staying in combat on this character."
        highestMultiKillValueText = tostring(stats.highestMultiKill)
    end
    statY = addSummaryStatLine(container, "Highest kill streak:", highestKillStreakValueText, statY, highestKillStreakTooltip)
    statY = addSummaryStatLine(container, "Highest multi-kill:", highestMultiKillValueText, statY, highestMultiKillTooltip)

    statY = statY - spacing_between_sections  -- Add some spacing before the achievement section

    if stats.busiestWeekday ~= "None" then
        statY = addSummaryStatLine(container, "Busiest weekday:", stats.busiestWeekday .. " (" .. stats.busiestWeekdayKills .. ")", statY,
            "Your most active day of the week for PvP kills.")
    end

    if stats.busiestHour ~= "None" then
        statY = addSummaryStatLine(container, "Busiest hour:", stats.busiestHour .. " (" .. stats.busiestHourKills .. ")", statY,
            "Your most active hour of the day for PvP kills.")
    end

    if stats.busiestMonth ~= "None" then
        statY = addSummaryStatLine(container, "Busiest month:", stats.busiestMonth .. " (" .. stats.busiestMonthKills .. ")", statY,
            "Your most active month for PvP kills.")
    end

    if stats.avgKillsPerDay > 0 then
        statY = addSummaryStatLine(container, "Average kills per day:", string.format("%.1f", stats.avgKillsPerDay), statY,
            "Your average kills per day from your first recorded kill to your most recent kill. This includes all days in that time period, even days when you didn't play.")
    end

    -- Count total and completed achievements
    statY = statY - spacing_between_sections  -- Extra spacing before new section
    local currentCharacterKey = PSC_GetCharacterKey()
    local completedCount = 0
    local totalCount = 0

    if PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements then
        totalCount = #PVPSC.AchievementSystem.achievements

        if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[currentCharacterKey] then
            for _, achievementData in pairs(PSC_DB.CharacterAchievements[currentCharacterKey]) do
                if achievementData.unlocked then
                    completedCount = completedCount + 1
                end
            end
        end
    end

    -- Find the achievement stats section
    local achievementText = completedCount .. " / " .. totalCount
    local achievementTooltip = "Click to view your achievements (" .. completedCount .. " out of " .. totalCount .. " completed)"

    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, statY)
    labelText:SetText("Achievements unlocked:")

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPLEFT", 150, statY)
    valueText:SetText(achievementText)

    local openAchievementsButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    openAchievementsButton:SetSize(130, 22)
    openAchievementsButton:SetPoint("LEFT", valueText, "RIGHT", 10, 0)
    openAchievementsButton:SetText("Open Achievements")
    openAchievementsButton:SetScript("OnClick", function()
        PSC_ToggleAchievementFrame()
    end)

    -- Create a clickable button for the achievements line
    local achievementButton = CreateFrame("Button", nil, container)
    achievementButton:SetPoint("TOPLEFT", labelText, "TOPLEFT", 0, 0)
    achievementButton:SetPoint("BOTTOMRIGHT", valueText, "BOTTOMRIGHT", 0, 0)

    -- Add gold highlight
    CreateGoldHighlight(achievementButton, 20)

    -- Add tooltip and click handlers
    achievementButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:AddLine(achievementTooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    achievementButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Open achievement frame on click
    achievementButton:SetScript("OnClick", function()
        PSC_ToggleAchievementFrame()
    end)

    statY = statY - 20  -- Standard line height

    -- Add the achievement points line:
    local achievementPoints = PSC_DB.CharacterAchievementPoints[currentCharacterKey] or 0
    local totalPossiblePoints = PVPSC.AchievementSystem:GetTotalPossiblePoints()
    statY = addSummaryStatLine(container, "Achievement points:", achievementPoints .. " / " .. totalPossiblePoints, statY,
        "Progress toward total possible achievement points (" .. achievementPoints .. " out of " .. totalPossiblePoints .. "). Earn more by completing achievements!")

    return container
end

function PSC_CalculateBarChartStatistics(charactersToProcess)
    local classData = {}
    local raceData = {}
    local genderData = {}
    local unknownLevelClassData = {}
    local zoneData = {}
    local levelData = {}
    local guildStatusData = {
        ["In Guild"] = 0,
        ["No Guild"] = 0
    }
    local guildData = {}

    -- Ensure all classes, races, genders are present with at least 0
    local allClasses = {"Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid"}
    local allRaces = {"Human", "Dwarf", "Night Elf", "Gnome", "Orc", "Undead", "Troll", "Tauren"}
    local allGenders = {"MALE", "FEMALE"}

    for _, class in ipairs(allClasses) do
        classData[class] = 0
        unknownLevelClassData[class] = 0
    end
    for _, race in ipairs(allRaces) do
        raceData[race] = 0
    end
    for _, gender in ipairs(allGenders) do
        genderData[gender] = 0
    end

    if not PSC_DB.PlayerKillCounts.Characters then
        return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData
    end

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 then
                    local nameWithoutLevel = nameWithLevel:match("([^:]+)")
                    local kills = killData.kills

                    local infoKey = PSC_GetInfoKeyFromName(nameWithoutLevel)

                    if PSC_DB.PlayerInfoCache[infoKey] then
                        local class = PSC_DB.PlayerInfoCache[infoKey].class
                        if class then
                            classData[class] = (classData[class] or 0) + kills
                        end

                        local level = nameWithLevel:match(":(%S+)")
                        local levelNum = tonumber(level or "0") or 0

                        if levelNum == -1 then
                            unknownLevelClassData[class] = (unknownLevelClassData[class] or 0) + kills
                            levelData["??"] = (levelData["??"] or 0) + kills
                        else
                            if levelNum > 0 and levelNum <= 60 then
                                levelData[tostring(levelNum)] = (levelData[tostring(levelNum)] or 0) + kills
                            end
                        end

                        local race = PSC_DB.PlayerInfoCache[infoKey].race
                        if race then
                            raceData[race] = (raceData[race] or 0) + kills
                        end

                        local gender = PSC_DB.PlayerInfoCache[infoKey].gender
                        if gender then
                            genderData[gender] = (genderData[gender] or 0) + kills
                        end

                        if killData.killLocations and #killData.killLocations > 0 then
                            for _, location in ipairs(killData.killLocations) do
                                local zone = location.zone or "Unknown"
                                zoneData[zone] = (zoneData[zone] or 0) + 1
                            end
                        end

                        local guild = PSC_DB.PlayerInfoCache[infoKey].guild
                        if guild ~= "" then
                            guildStatusData["In Guild"] = guildStatusData["In Guild"] + kills
                            guildData[guild] = (guildData[guild] or 0) + kills
                        else
                            guildStatusData["No Guild"] = guildStatusData["No Guild"] + kills
                        end
                    end
                end
            end
        end
    end

    return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData
end

function PSC_CalculateHourlyStatistics(charactersToProcess)
    local hourlyData = {}

    -- Initialize all hours (0-23) with 0 kills
    for hour = 0, 23 do
        hourlyData[hour] = 0
    end

    if not PSC_DB.PlayerKillCounts.Characters then
        return hourlyData
    end

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 and killData.killLocations then
                    for _, location in ipairs(killData.killLocations) do
                        if location.timestamp then
                            local dateInfo = date("*t", location.timestamp)
                            if dateInfo and dateInfo.hour then
                                hourlyData[dateInfo.hour] = hourlyData[dateInfo.hour] + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return hourlyData
end

function PSC_CalculateWeekdayStatistics(charactersToProcess)
    local weekdayData = {}

    -- Initialize all weekdays (1-7, Sunday=1) with 0 kills
    for weekday = 1, 7 do
        weekdayData[weekday] = 0
    end

    if not PSC_DB.PlayerKillCounts.Characters then
        return weekdayData
    end

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 and killData.killLocations then
                    for _, location in ipairs(killData.killLocations) do
                        if location.timestamp then
                            local dateInfo = date("*t", location.timestamp)
                            if dateInfo and dateInfo.wday then
                                weekdayData[dateInfo.wday] = weekdayData[dateInfo.wday] + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return weekdayData
end

function PSC_CalculateMonthlyStatistics(charactersToProcess)
    local monthlyData = {}

    -- Initialize all months (1-12) with 0 kills
    for month = 1, 12 do
        monthlyData[month] = 0
    end

    if not PSC_DB.PlayerKillCounts.Characters then
        return monthlyData
    end

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 and killData.killLocations then
                    for _, location in ipairs(killData.killLocations) do
                        if location.timestamp then
                            local dateInfo = date("*t", location.timestamp)
                            if dateInfo and dateInfo.month then
                                monthlyData[dateInfo.month] = monthlyData[dateInfo.month] + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return monthlyData
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

    local scrollBarName = scrollFrame:GetName() and scrollFrame:GetName() .. "ScrollBar" or nil
    local scrollBar = scrollBarName and _G[scrollBarName] or nil

    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -18, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -18, 16)
    end

    return content, scrollFrame
end

function GetFrameTitleTextWithCharacterText(titleText)
    if PSC_DB.ShowAccountWideStats then
        titleText = titleText .. " (All characters)"
    else
        titleText = titleText .. " (" .. PSC_GetCharacterKey() .. ")"
    end
    return titleText
end

local function setupMainFrame()
    local frame = CreateFrame("Frame", "PSC_StatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.FRAME.WIDTH, UI.FRAME.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    tinsert(UISpecialFrames, "PSC_StatisticsFrame")

    local titleText = GetFrameTitleTextWithCharacterText("PvP Statistics")
    frame.TitleText:SetText(titleText)

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

    frame.TitleText:SetText("PvP Statistics")

    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("TOPLEFT", 430, -5)
    separator:SetPoint("BOTTOMLEFT", 430, 5)
    separator:SetWidth(1)
    separator:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    return frame
end

local function enoughPlayerKillsRecorded()
    local totalKills = 0
    local uniqueKills = 0

    local charactersToProcess = GetCharactersToProcessForStatistics()

    for characterKey, characterData in pairs(charactersToProcess) do
        for nameWithLevel, killData in pairs(characterData.Kills) do
            if killData.kills and killData.kills > 0 then
                uniqueKills = uniqueKills + 1
                totalKills = totalKills + killData.kills
            end
        end
    end

    return totalKills >= 10 or uniqueKills >= 5
end

local function createEmptyStatsFrame()
    local frame = CreateFrame("Frame", "PSC_StatisticsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(UI.FRAME.WIDTH, 200)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local titleText = GetFrameTitleTextWithCharacterText("Player Kill Statistics")
    frame.TitleText:SetText(titleText)

    local messageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    messageText:SetPoint("CENTER", 0, 0)
    messageText:SetText("You need at least 10 kills or 5 unique kills\nto view detailed statistics.")
    messageText:SetJustifyH("CENTER")

    return frame
end

function PSC_CreateStatisticsFrame()
    if statisticsFrame then
        statisticsFrame:Hide()
        PSC_FrameManager:HideFrame("Statistics")
        statisticsFrame = nil
    end

    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PSC_StatisticsFrame") then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    if not enoughPlayerKillsRecorded() then
        statisticsFrame = createEmptyStatsFrame()
        PSC_FrameManager:RegisterFrame(statisticsFrame, "Statistics")
        return
    end

    statisticsFrame = setupMainFrame()
    statisticsFrame:SetScript("OnKeyDown", nil)
    PSC_FrameManager:RegisterFrame(statisticsFrame, "Statistics")

    PSC_UpdateStatisticsFrame(statisticsFrame)
end

function PSC_UpdateStatisticsFrame(frame)
    if not frame then
        return
    end

    local titleText = GetFrameTitleTextWithCharacterText("PvP Statistics")
    frame.TitleText:SetText(titleText)

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

    if frame:GetHeight() < 400 then
        return
    end

    local currentCharacterKey = PSC_GetCharacterKey()
    local charactersToProcess = {}
    if PSC_DB.ShowAccountWideStats then
        charactersToProcess = PSC_DB.PlayerKillCounts.Characters
    else
        if PSC_DB.PlayerKillCounts.Characters[currentCharacterKey] then
            charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
        end
    end

    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData =
        PSC_CalculateBarChartStatistics(charactersToProcess)

    local hourlyData = PSC_CalculateHourlyStatistics(charactersToProcess)
    local weekdayData = PSC_CalculateWeekdayStatistics(charactersToProcess)
    local monthlyData = PSC_CalculateMonthlyStatistics(charactersToProcess)

    local leftScrollContent, leftScrollFrame = createScrollableLeftPanel(frame)
    frame.leftScrollContent = leftScrollContent
    frame.leftScrollFrame = leftScrollFrame

    local classChartHeight = calculateChartHeight(classData)
    local raceChartHeight = calculateChartHeight(raceData)
    local genderChartHeight = calculateChartHeight(genderData)
    local hourlyChartHeight = calculateChartHeight(hourlyData)
    local weekdayChartHeight = calculateChartHeight(weekdayData)
    local monthlyChartHeight = calculateChartHeight(monthlyData)
    local levelChartHeight = calculateChartHeight(levelData)
    local zoneChartHeight = calculateChartHeight(zoneData)

    local yOffset = 0
    createBarChart(leftScrollContent, "Kills by Class", classData, nil, 0, yOffset, UI.CHART.WIDTH, classChartHeight)

    yOffset = yOffset - classChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Race", raceData, raceColors, 0, yOffset, UI.CHART.WIDTH, raceChartHeight)

    yOffset = yOffset - raceChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Gender", genderData, genderColors, 0, yOffset, UI.CHART.WIDTH,
        genderChartHeight)

    yOffset = yOffset - genderChartHeight - UI.CHART.PADDING

    local guildStatusChartHeight = calculateChartHeight(guildStatusData)
    local guildStatusColors = {
        ["In Guild"] = {
            r = 0.2,
            g = 0.8,
            b = 0.2
        },
        ["No Guild"] = {
            r = 0.8,
            g = 0.2,
            b = 0.2
        }
    }
    createBarChart(leftScrollContent, "Kills by Guild Status", guildStatusData, guildStatusColors, 0, yOffset,
        UI.CHART.WIDTH, guildStatusChartHeight)

    yOffset = yOffset - guildStatusChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Hour of Day", hourlyData, nil, 0, yOffset, UI.CHART.WIDTH, hourlyChartHeight)

    yOffset = yOffset - hourlyChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Weekday", weekdayData, nil, 0, yOffset, UI.CHART.WIDTH, weekdayChartHeight)

    yOffset = yOffset - weekdayChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Month", monthlyData, nil, 0, yOffset, UI.CHART.WIDTH, monthlyChartHeight)

    yOffset = yOffset - monthlyChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Level", levelData, nil, 0, yOffset, UI.CHART.WIDTH, levelChartHeight)

    yOffset = yOffset - levelChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Zone", zoneData, nil, 0, yOffset, UI.CHART.WIDTH, zoneChartHeight)

    local totalHeight = -(yOffset) + 25
    leftScrollContent:SetHeight(totalHeight)

    local summaryStatsWidth = 380
    frame.guildTable = createGuildTable(frame, 440, -UI.TOP_PADDING, summaryStatsWidth, UI.GUILD_LIST.HEIGHT)
    frame.summaryStats = createSummaryStats(frame, 440, -UI.GUILD_LIST.HEIGHT - UI.TOP_PADDING - 20, summaryStatsWidth,
        250)
end
