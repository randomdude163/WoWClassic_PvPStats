local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

local statisticsFrame = nil

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
        WIDTH = 400,
        HEIGHT = 300
    },
    TITLE_SPACING = 3,
    TOP_PADDING = 40,
    LEFT_SCROLL_PADDING = 20,
    ZONE_NAME_WIDTH = 160,
    NPC_NAME_WIDTH = 130,
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

local function calculateChartHeight(data, includeZeroKeys)
    if not data then return 30 + 15 end -- Minimum height for title + padding

    local entries = 0
    for key, numKills in pairs(data) do
        if numKills > 0 then
            entries = entries + 1
        elseif includeZeroKeys and includeZeroKeys[key] then
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

local function NormalizeMonthKey(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 12 then return num end

    local keyLower = string.lower(tostring(key))
    local months = {
        january = 1, february = 2, march = 3, april = 4, may = 5, june = 6,
        july = 7, august = 8, september = 9, october = 10, november = 11, december = 12,
        jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12
    }
    if months[keyLower] then return months[keyLower] end
    return nil
end

local function NormalizeWeekdayKey(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 7 then return num end

    local keyLower = string.lower(tostring(key))
    local days = {
        sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7,
        sun = 1, mon = 2, tue = 3, wed = 4, thu = 5, fri = 6, sat = 7
    }
    if days[keyLower] then return days[keyLower] end
    return nil
end

local function createBar(container, entry, index, maxValue, total, titleType, disableClicks)
    local barWidth
    local nameWidth
    local barX
    local maxBarWidth

    if titleType == "zone" then
        nameWidth = UI.ZONE_NAME_WIDTH
        barX = nameWidth + 10
        maxBarWidth = UI.CHART.WIDTH - nameWidth - 110
    elseif titleType == "npc" then
        nameWidth = UI.NPC_NAME_WIDTH
        barX = nameWidth + 10
        maxBarWidth = UI.CHART.WIDTH - nameWidth - 110
    else
        nameWidth = UI.STANDARD_NAME_WIDTH
        barX = 90
        maxBarWidth = UI.CHART.WIDTH - 190
    end

    if maxValue > 0 then
        barWidth = (entry.value / maxValue) * maxBarWidth
    else
        barWidth = 0.5 -- Very thin line if no kills at all (shouldn't really happen with filter, but for safety)
    end

    if titleType == "npc" and barWidth < 1 then
         barWidth = 1 -- Minimum visibility
    end

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
    elseif titleType == "year" then
        displayName = tostring(entry.key)
    end

    local barButton = CreateFrame("Button", nil, container)
    barButton:SetSize(UI.CHART.WIDTH, UI.BAR.HEIGHT)
    barButton:SetPoint("TOPLEFT", 0, barY)

    -- Only add highlight and click functionality for clickable chart types
    local isClickable = titleType ~= "hour" and titleType ~= "weekday" and titleType ~= "month" and titleType ~= "year" and titleType ~= "npc"

    if disableClicks then
        isClickable = false
    end

    if isClickable then
        local highlightTexture = PSC_CreateGoldHighlight(barButton, UI.BAR.HEIGHT)
    end

    barButton:SetScript("OnEnter", function(self)
        if disableClicks then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(displayName)

        if titleType == "class" or titleType == "unknownLevelClass" then
            if isClickable then
                GameTooltip:AddLine("Click to show all kills for this class", 1, 1, 1, true)
            end
        elseif titleType == "zone" then
            if isClickable then
                GameTooltip:AddLine("Click to show all kills for this zone", 1, 1, 1, true)
            end
        elseif titleType == "level" then
            if isClickable then
                if entry.key == "??" then
                    GameTooltip:AddLine("Click to show all kill for level ??", 1, 1, 1, true)
                else
                    GameTooltip:AddLine("Click to show all kills for this level", 1, 1, 1, true)
                end
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
        elseif titleType == "year" then
            GameTooltip:AddLine("Kills in " .. displayName, 1, 1, 1, true)
        elseif titleType == raceColors then
            if isClickable then
                GameTooltip:AddLine("Click to show all kills for this race", 1, 1, 1, true)
            end
        elseif titleType == genderColors then
            if isClickable then
                GameTooltip:AddLine("Click to show all kills for this gender", 1, 1, 1, true)
            end
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
    elseif titleType == "year" then
        -- Medium green for year charts
        color = {
            r = 0.4,
            g = 0.8,
            b = 0.4
        }
    elseif titleType == "npc" then
        if entry.key == "Corporal Keeshan" then
            -- Redridge Mountains orange
            color = {
                r = 0.85,
                g = 0.35,
                b = 0.10
            }
        elseif entry.key == "The Defias Traitor" then
            -- Westfall yellowish/tan
            color = {
                r = 0.90,
                g = 0.75,
                b = 0.40
            }
        elseif entry.key == "Defias Messenger" then
            -- Defias Red
            color = {
                r = 0.80,
                g = 0.20,
                b = 0.20
            }
        else
            color = {
                r = 0.8,
                g = 0.8,
                b = 0.8
            }
        end
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

    local percentage = (total > 0) and (entry.value / total * 100) or 0
    local valueText = entry.value .. " (" .. string.format("%.1f", percentage) .. "%)"
    valueLabel:SetText(valueText)

    local estimatedTextWidth = string.len(valueText) * 6

    if barX + barWidth + estimatedTextWidth > (UI.CHART.WIDTH - 25) then
        valueLabel:SetText(entry.value)
    end
end

local function createBarChart(parent, title, data, colorTable, x, y, width, height, disableClicks)
    local container = createContainerWithTitle(parent, title, x, y, width, height)

    -- Pre-process data to handle numeric/string key duplication and normalization
    local processedData = {}
    if data then
        for k, v in pairs(data) do
            local finalKey = k

            if title == "Kills by Month" then
                local norm = NormalizeMonthKey(k)
                if norm then finalKey = norm end
            elseif title == "Kills by Weekday" then
                local norm = NormalizeWeekdayKey(k)
                if norm then finalKey = norm end
            elseif title == "Kills by Hour of Day" or title == "Kills by Year" then
                local num = tonumber(k)
                if num then finalKey = num end
            elseif title == "Kills by Level" then
                if k ~= "??" then
                    local num = tonumber(k)
                    if num then finalKey = num end
                end
            end

            -- Ensure we don't valid keys
            if finalKey then
                 processedData[finalKey] = (processedData[finalKey] or 0) + v
            end
        end
    end

    local sortedData = sortByValue(processedData, true)
    local filteredData = {}
    for _, entry in ipairs(sortedData) do
        if entry.value > 0 or title == "NPC Kills" then
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
    elseif (title == "Kills by Year") then
        -- Sort years chronologically
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
    elseif title == "NPC Kills" then
        titleType = "npc"
    elseif title == "Kills by Level" then
        titleType = "level"
    elseif title == "Kills by Hour of Day" then
        titleType = "hour"
    elseif title == "Kills by Weekday" then
        titleType = "weekday"
    elseif title == "Kills by Month" then
        titleType = "month"
    elseif title == "Kills by Year" then
        titleType = "year"
    else
        titleType = colorTable
    end

    for i, entry in ipairs(filteredData) do
        createBar(container, entry, i, maxValue, total, titleType, disableClicks)
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
    local highlightTexture = PSC_CreateGoldHighlight(rowButton, 16)

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

                local infoKey = PSC_NormalizePlayerName(playerNameWithoutLevel)

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

local function PSC_SummaryStats_CreateState(charactersToProcess)
    local PSC_DB = PSC_DB
---@diagnostic disable-next-line: undefined-global
    local PSC_CalculateTimePeriodBoundaries = PSC_CalculateTimePeriodBoundaries

    local state = {
        totalKills = 0,
        uniqueKills = 0,
        totalLevels = 0,
        totalPlayerLevelSum = 0,
        killsWithLevelData = 0,
        levelDiffSum = 0,
        unknownLevelKills = 0,
        uniquePlayerLevels = {},
        killsPerPlayer = {},
        mostKilledPlayer = nil,
        mostKilledCount = 0,
        highestKillStreak = 0,
        highestKillStreakCharacter = "",
        currentKillStreak = 0,
        highestMultiKill = 0,
        highestMultiKillCharacter = "",
        weekdayKills = {0, 0, 0, 0, 0, 0, 0},
        hourlyKills = {},
        monthlyKills = {},
        firstKillTimestamp = nil,
        lastKillTimestamp = nil,
        timeBoundaries = nil,
        killsToday = 0,
        killsThisWeek = 0,
        killsThisMonth = 0,
        killsThisYear = 0,
        busiestWeekday = "None",
        busiestWeekdayKills = 0,
        busiestHour = "None",
        busiestHourKills = 0,
        busiestMonth = "None",
        busiestMonthKills = 0,
        avgKillsPerDay = 0,
        nemesisName = "None",
        nemesisScore = 0,
        totalDeaths = 0,
        kdRatio = 0,
        charactersToProcess = charactersToProcess
    }

    for i = 0, 23 do
        state.hourlyKills[i] = 0
    end
    for i = 1, 12 do
        state.monthlyKills[i] = 0
    end

    state.timeBoundaries = PSC_CalculateTimePeriodBoundaries()

    return state
end

local function PSC_SummaryStats_ProcessCharacterHeader(state, characterKey, characterData)
    local PSC_GetCharacterKey = PSC_GetCharacterKey
    local PSC_DB = PSC_DB

    if characterKey == PSC_GetCharacterKey() then
        state.currentKillStreak = characterData.CurrentKillStreak
    end

    if PSC_DB.ShowAccountWideStats then
        if (characterData.HighestKillStreak or 0) > state.highestKillStreak then
            state.highestKillStreak = characterData.HighestKillStreak or 0
            state.highestKillStreakCharacter = characterKey
        end

        if (characterData.HighestMultiKill or 0) > state.highestMultiKill then
            state.highestMultiKill = characterData.HighestMultiKill or 0
            state.highestMultiKillCharacter = characterKey
        end
    else
        state.highestMultiKill = characterData.HighestMultiKill or 0
        state.highestKillStreak = characterData.HighestKillStreak or 0
    end
end

local function PSC_SummaryStats_ProcessKillEntryBase(state, nameWithLevel, killData)
    local tonumber = tonumber
    local strfind = string.find
    local strsub = string.sub

    local kills = killData.kills or 0

    local colonIndex = strfind(nameWithLevel, ":", 1, true)
    local playerName
    local levelPart
    if colonIndex then
        playerName = strsub(nameWithLevel, 1, colonIndex - 1)
        levelPart = strsub(nameWithLevel, colonIndex + 1)
    else
        playerName = nameWithLevel
        levelPart = nil
    end

    playerName = PSC_NormalizePlayerName(playerName)

    if not state.killsPerPlayer[playerName] then
        state.uniqueKills = state.uniqueKills + 1
        state.killsPerPlayer[playerName] = kills
    else
        state.killsPerPlayer[playerName] = state.killsPerPlayer[playerName] + kills
    end

    state.totalKills = state.totalKills + kills

    local levelNum = tonumber(levelPart or "0") or 0

    if levelNum > 0 then
        if not state.uniquePlayerLevels[playerName] then
            state.uniquePlayerLevels[playerName] = {
                sum = 0,
                count = 0
            }
        end

        state.uniquePlayerLevels[playerName].sum = state.uniquePlayerLevels[playerName].sum + levelNum
        state.uniquePlayerLevels[playerName].count = state.uniquePlayerLevels[playerName].count + 1
    end

    if levelNum == -1 then
        state.unknownLevelKills = state.unknownLevelKills + kills
    end

    if levelNum > 0 then
        state.totalLevels = state.totalLevels + levelNum * kills
    end

    return kills, playerName, levelNum
end

local function PSC_SummaryStats_ProcessKillLocation(state, location, levelNum)
    local tonumber = tonumber
    local date = date

    local targetLevel = levelNum
    local playerLevel = location.playerLevel or 0
    local timestamp = location.timestamp

    if timestamp then
        if not state.firstKillTimestamp or timestamp < state.firstKillTimestamp then
            state.firstKillTimestamp = timestamp
        end
        if not state.lastKillTimestamp or timestamp > state.lastKillTimestamp then
            state.lastKillTimestamp = timestamp
        end

        if state.timeBoundaries then
            if timestamp >= state.timeBoundaries.todayStart then
                state.killsToday = state.killsToday + 1
            end
            if timestamp >= state.timeBoundaries.weekStart then
                state.killsThisWeek = state.killsThisWeek + 1
            end
            if timestamp >= state.timeBoundaries.monthStart then
                state.killsThisMonth = state.killsThisMonth + 1
            end
            if timestamp >= state.timeBoundaries.yearStart then
                state.killsThisYear = state.killsThisYear + 1
            end
        end

        local wday0 = tonumber(date("%w", timestamp))
        if wday0 then
            state.weekdayKills[wday0 + 1] = state.weekdayKills[wday0 + 1] + 1
        end

        local hour = tonumber(date("%H", timestamp))
        if hour then
            state.hourlyKills[hour] = state.hourlyKills[hour] + 1
        end

        local month = tonumber(date("%m", timestamp))
        if month then
            state.monthlyKills[month] = state.monthlyKills[month] + 1
        end
    end

    if targetLevel > 0 and playerLevel > 0 then
        state.levelDiffSum = state.levelDiffSum + (playerLevel - targetLevel)
        state.killsWithLevelData = state.killsWithLevelData + 1
    end

    if playerLevel > 0 then
        state.totalPlayerLevelSum = state.totalPlayerLevelSum + playerLevel
    end
end

local function PSC_SummaryStats_ProcessKillEntryFallback(state, killData, kills, levelNum)
    if levelNum > 0 and killData.playerLevel and killData.playerLevel > 0 then
        state.levelDiffSum = state.levelDiffSum + (killData.playerLevel - levelNum) * kills
        state.killsWithLevelData = state.killsWithLevelData + kills
    end

    if killData.playerLevel and killData.playerLevel > 0 then
        state.totalPlayerLevelSum = state.totalPlayerLevelSum + killData.playerLevel * kills
    end
end

local function PSC_SummaryStats_FinalizeKillDerivedFields(state)
    local pairs = pairs
    local ipairs = ipairs
    local math_floor = math.floor
    local string_format = string.format

    for playerName, kills in pairs(state.killsPerPlayer) do
        if kills > state.mostKilledCount then
            state.mostKilledPlayer = playerName
            state.mostKilledCount = kills
        end
    end

    local uniqueLevelSum = 0
    local uniquePlayersWithLevel = 0

    for _, playerLevelData in pairs(state.uniquePlayerLevels) do
        if playerLevelData.count > 0 then
            uniqueLevelSum = uniqueLevelSum + (playerLevelData.sum / playerLevelData.count)
            uniquePlayersWithLevel = uniquePlayersWithLevel + 1
        end
    end

    local weekdayNames = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
    state.busiestWeekday = "None"
    state.busiestWeekdayKills = 0
    for i, kills in ipairs(state.weekdayKills) do
        if kills > state.busiestWeekdayKills then
            state.busiestWeekdayKills = kills
            state.busiestWeekday = weekdayNames[i]
        end
    end

    state.busiestHour = "None"
    state.busiestHourKills = 0
    for hour, kills in pairs(state.hourlyKills) do
        if kills > state.busiestHourKills then
            state.busiestHourKills = kills
            state.busiestHour = string_format("%02d:00 - %02d:00", hour, (hour + 1) % 24)
        end
    end

    local monthNames = {"January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December"}
    state.busiestMonth = "None"
    state.busiestMonthKills = 0
    for i, kills in ipairs(state.monthlyKills) do
        if kills > state.busiestMonthKills then
            state.busiestMonthKills = kills
            state.busiestMonth = monthNames[i]
        end
    end

    state.avgKillsPerDay = 0
    if state.firstKillTimestamp and state.lastKillTimestamp then
        local activitySpanDays = math_floor((state.lastKillTimestamp - state.firstKillTimestamp) / 86400) + 1
        if activitySpanDays > 0 then
            state.avgKillsPerDay = state.totalKills / activitySpanDays
        end
    end

    local knownLevelKills = state.totalKills - state.unknownLevelKills
    local avgUniqueLevel = uniquePlayersWithLevel > 0 and (uniqueLevelSum / uniquePlayersWithLevel) or 0
    state.avgLevel = avgUniqueLevel
    state.avgPlayerLevel = state.totalKills > 0 and (state.totalPlayerLevelSum / state.totalKills) or 0
    state.avgLevelDiff = state.killsWithLevelData > 0 and (state.levelDiffSum / state.killsWithLevelData) or 0
    state.avgKillsPerPlayer = state.uniqueKills > 0 and (state.totalKills / state.uniqueKills) or 0

    if knownLevelKills <= 0 then
        state._unusedAvgLevel = 0
    else
        state._unusedAvgLevel = state.totalLevels / knownLevelKills
    end
end

local function PSC_SummaryStats_FinalizeNemesisAndDeaths(state)
    local pairs = pairs
    local ipairs = ipairs
    local math_huge = math.huge
    local PSC_GetDeathDataFromAllCharacters = PSC_GetDeathDataFromAllCharacters

    local nemesisName = "None"
    local nemesisScore = 0
    local nemesisAssists = 0
    local deathDataByPlayer = PSC_GetDeathDataFromAllCharacters()

    local assistsByPlayer = {}
    local deathsByPlayer = {}

    for killerName, deathData in pairs(deathDataByPlayer) do
        local normalizedKiller = PSC_NormalizePlayerName(killerName)
        deathsByPlayer[normalizedKiller] = (deathsByPlayer[normalizedKiller] or 0) + (deathData.deaths or 0)

        if deathData.deathLocations then
            for _, location in ipairs(deathData.deathLocations) do
                if location.assisters then
                    for _, assister in ipairs(location.assisters) do
                        if assister and assister.name then
                            local normalizedAssister = PSC_NormalizePlayerName(assister.name)
                            assistsByPlayer[normalizedAssister] = (assistsByPlayer[normalizedAssister] or 0) + 1
                        end
                    end
                end
            end
        end
    end

    local totalDeaths = 0
    for _, deaths in pairs(deathsByPlayer) do
        totalDeaths = totalDeaths + (deaths or 0)
    end

    for killerName, deaths in pairs(deathsByPlayer) do
        local assists = assistsByPlayer[killerName] or 0

        if deaths > nemesisScore or (deaths == nemesisScore and assists > nemesisAssists) then
            nemesisScore = deaths
            nemesisAssists = assists
            nemesisName = killerName
        end
    end

    state.nemesisName = nemesisName
    state.nemesisScore = nemesisScore
    state.totalDeaths = totalDeaths

    if totalDeaths > 0 then
        state.kdRatio = state.totalKills / totalDeaths
    elseif state.totalKills > 0 then
        state.kdRatio = math_huge
    else
        state.kdRatio = 0
    end
end

local function PSC_SummaryStats_BuildResult(state)
    return {
        totalKills = state.totalKills,
        uniqueKills = state.uniqueKills,
        unknownLevelKills = state.unknownLevelKills,
        totalDeaths = state.totalDeaths,
        kdRatio = state.kdRatio,
        avgLevel = state.avgLevel,
        avgLevelDiff = state.avgLevelDiff,
        avgKillsPerPlayer = state.avgKillsPerPlayer,
        mostKilledPlayer = state.mostKilledPlayer or "None",
        mostKilledCount = state.mostKilledCount,
        currentKillStreak = state.currentKillStreak,
        highestKillStreak = state.highestKillStreak,
        highestMultiKill = state.highestMultiKill,
        highestKillStreakCharacter = state.highestKillStreakCharacter,
        highestMultiKillCharacter = state.highestMultiKillCharacter,
        busiestWeekday = state.busiestWeekday,
        busiestWeekdayKills = state.busiestWeekdayKills,
        busiestHour = state.busiestHour,
        busiestHourKills = state.busiestHourKills,
        busiestMonth = state.busiestMonth,
        busiestMonthKills = state.busiestMonthKills,
        avgKillsPerDay = state.avgKillsPerDay,
        killsToday = state.killsToday,
        killsThisWeek = state.killsThisWeek,
        killsThisMonth = state.killsThisMonth,
        killsThisYear = state.killsThisYear,
        nemesisName = state.nemesisName,
        nemesisScore = state.nemesisScore
    }
end

local function createGuildTable(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Kills by Guild", x, y, width, height)

    local guildKills = PSC_CalculateGuildKills()
    local sortedGuilds = sortByValue(guildKills, true)

    local totalContentWidth = 240
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

local function addSummaryStatLine(container, label, value, yPosition, tooltipText, isKillStreak, isLocalPlayer)
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, yPosition)
    labelText:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPLEFT", 150, yPosition)
    valueText:SetText(tostring(value))

    -- Make kill streak value text gold
    if isKillStreak then
        valueText:SetTextColor(1.0, 0.82, 0.0) -- WoW gold color
    end

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

        if label == "Most killed player:" and isLocalPlayer then
            local button = CreateFrame("Button", nil, tooltipFrame)
            ---@diagnostic disable-next-line: param-type-mismatch
            button:SetAllPoints(true)

            PSC_CreateGoldHighlight(button, 20)

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
        elseif label == "Nemesis:" and isLocalPlayer then
            local button = CreateFrame("Button", nil, tooltipFrame)
            ---@diagnostic disable-next-line: param-type-mismatch
            button:SetAllPoints(true)

            PSC_CreateGoldHighlight(button, 20)

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
        elseif isKillStreak and isLocalPlayer then
            local button = CreateFrame("Button", nil, tooltipFrame)
            ---@diagnostic disable-next-line: param-type-mismatch
            button:SetAllPoints(true)

            PSC_CreateGoldHighlight(button, 20)

            button:SetScript("OnMouseUp", function()
                PSC_CreateKillStreakPopup()
            end)

            -- Add tooltip to the button itself
            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
    end

    return yPosition - 20
end

function PSC_CalculateSummaryStatistics(charactersToProcess)
    local state = PSC_SummaryStats_CreateState(charactersToProcess)

    for characterKey, characterData in pairs(charactersToProcess) do
        PSC_SummaryStats_ProcessCharacterHeader(state, characterKey, characterData)

        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                local kills, _, levelNum = PSC_SummaryStats_ProcessKillEntryBase(state, nameWithLevel, killData)

                if killData.killLocations and #killData.killLocations > 0 then
                    for _, location in ipairs(killData.killLocations) do
                        PSC_SummaryStats_ProcessKillLocation(state, location, levelNum)
                    end
                else
                    PSC_SummaryStats_ProcessKillEntryFallback(state, killData, kills, levelNum)
                end
            end
        end
    end

    PSC_SummaryStats_FinalizeKillDerivedFields(state)
    PSC_SummaryStats_FinalizeNemesisAndDeaths(state)
    return PSC_SummaryStats_BuildResult(state)
end

function PSC_CreateIncrementalSummaryStatisticsTask(charactersToProcess, maxKillLocationsPerFrame, onComplete)
    if type(onComplete) ~= "function" then
        return function()
            return true
        end
    end

    local sliceBudget = tonumber(maxKillLocationsPerFrame) or 0
    sliceBudget = math.floor(sliceBudget)
    if sliceBudget < 50 then
        sliceBudget = 50
    end

    local state = PSC_SummaryStats_CreateState(charactersToProcess)

    local characterKeys = {}
    for characterKey in pairs(charactersToProcess) do
        table.insert(characterKeys, characterKey)
    end

    local characterIndex = 1
    local killKeys = nil
    local killIndex = 1
    local locationIndex = 1
    local currentKillData = nil
    local currentKillLevelNum = 0
    local currentKillKills = 0
    local characterHeaderDone = false
    local finished = false

    local function advanceToNextKill()
        currentKillData = nil
        locationIndex = 1
        killIndex = killIndex + 1
    end

    return function()
        if finished then
            return true
        end

        local processed = 0
        while processed < sliceBudget do
            if characterIndex > #characterKeys then
                PSC_SummaryStats_FinalizeKillDerivedFields(state)
                PSC_SummaryStats_FinalizeNemesisAndDeaths(state)
                finished = true
                onComplete(PSC_SummaryStats_BuildResult(state))
                return true
            end

            local characterKey = characterKeys[characterIndex]
            local characterData = charactersToProcess[characterKey]
            if not characterData then
                characterIndex = characterIndex + 1
                killKeys = nil
                killIndex = 1
                locationIndex = 1
                currentKillData = nil
                characterHeaderDone = false
            else
                if not characterHeaderDone then
                    PSC_SummaryStats_ProcessCharacterHeader(state, characterKey, characterData)
                    characterHeaderDone = true
                end

                if not characterData.Kills then
                    characterIndex = characterIndex + 1
                    killKeys = nil
                    killIndex = 1
                    locationIndex = 1
                    currentKillData = nil
                    characterHeaderDone = false
                else
                    if not killKeys then
                        killKeys = {}
                        for nameWithLevel in pairs(characterData.Kills) do
                            table.insert(killKeys, nameWithLevel)
                        end
                        killIndex = 1
                        locationIndex = 1
                        currentKillData = nil
                    end

                    if killIndex > #killKeys then
                        characterIndex = characterIndex + 1
                        killKeys = nil
                        killIndex = 1
                        locationIndex = 1
                        currentKillData = nil
                        characterHeaderDone = false
                    else
                        local nameWithLevel = killKeys[killIndex]
                        local killData = characterData.Kills[nameWithLevel]
                        if not killData then
                            advanceToNextKill()
                        else
                            if not currentKillData then
                                currentKillData = killData
                                local kills, _, levelNum = PSC_SummaryStats_ProcessKillEntryBase(state, nameWithLevel, killData)
                                currentKillLevelNum = levelNum
                                currentKillKills = kills
                                locationIndex = 1
                            end

                            if currentKillData.killLocations and #currentKillData.killLocations > 0 then
                                local locations = currentKillData.killLocations
                                if locationIndex > #locations then
                                    advanceToNextKill()
                                else
                                    local location = locations[locationIndex]
                                    if location then
                                        PSC_SummaryStats_ProcessKillLocation(state, location, currentKillLevelNum)
                                    end
                                    locationIndex = locationIndex + 1
                                    processed = processed + 1
                                end
                            else
                                PSC_SummaryStats_ProcessKillEntryFallback(state, currentKillData, currentKillKills, currentKillLevelNum)
                                advanceToNextKill()
                                processed = processed + 1
                            end
                        end
                    end
                end
            end
        end

        return false
    end
end

local function PSC_PopulateSummaryStatsContainer(container, stats, isLocalPlayer, extraData, playerName)
    local spacing_between_sections = 10
    local statY = -22

    -- 1. Totals
    local totalKillsTooltip = isLocalPlayer and "Total number of players you have killed." or "Total number of players killed."
    statY = addSummaryStatLine(container, "Total player kills:", stats.totalKills or 0, statY, totalKillsTooltip, false, isLocalPlayer)

    local uniqueKillsTooltip = isLocalPlayer and "Total number of unique players you have killed. Multiple kills of the same player are counted only once." or "Total number of unique players killed."
    statY = addSummaryStatLine(container, "Unique players killed:", stats.uniqueKills or 0, statY, uniqueKillsTooltip, false, isLocalPlayer)

    local totalDeathsTooltip = isLocalPlayer and "Total number of times you have died to players." or "Total number of deaths to players."
    statY = addSummaryStatLine(container, "Total player deaths:", stats.totalDeaths or 0, statY, totalDeathsTooltip, false, isLocalPlayer)

    local kdRatio = PSC_FormatKDRatio(stats.totalKills, stats.totalDeaths, stats.kdRatio)
    local kdText = kdRatio .. " (" .. (stats.totalKills or 0) .. "/" .. (stats.totalDeaths or 0) .. ")"
    local kdTooltip = isLocalPlayer and "Overall kill/death ratio (total player kills divided by total PvP deaths)." or "Overall kill/death ratio."
    statY = addSummaryStatLine(container, "K/D ratio:", kdText, statY, kdTooltip, false, isLocalPlayer)

    if (stats.unknownLevelKills and stats.unknownLevelKills > 0) or isLocalPlayer then
        local unknownTooltip = "Total number of times you have killed a level ?? player."
        statY = addSummaryStatLine(container, "Level ?? kills:", stats.unknownLevelKills or 0, statY, unknownTooltip, false, isLocalPlayer)
    end

    -- 2. Most Killed & Nemesis
    if stats.mostKilledPlayer and (stats.mostKilledCount or 0) > 0 and stats.mostKilledPlayer ~= "None" then
        local mostKilledText = stats.mostKilledPlayer .. " (" .. (stats.mostKilledCount or 0) .. ")"
        local mkTooltip = isLocalPlayer and "Click to show all kills of this player" or "The player killed most often."
        statY = addSummaryStatLine(container, "Most killed player:", mostKilledText, statY - spacing_between_sections, mkTooltip, false, isLocalPlayer)
    end

    if stats.nemesisName and stats.nemesisName ~= "None" and (stats.nemesisScore or 0) > 0 then
        local nemesisText = stats.nemesisName .. " (" .. (stats.nemesisScore or 0) .. ")"
        local nemesisTooltip = isLocalPlayer and "The player who has killed you the most (kills + assists). Click to view details." or "The player who has killed this player the most."
        statY = addSummaryStatLine(container, "Nemesis:", nemesisText, statY, nemesisTooltip, false, isLocalPlayer)
    end

    -- 3. Averages
    if stats.avgLevel and stats.avgLevel > 0 then
        statY = addSummaryStatLine(container, "Avg. victim level:", string.format("%.1f", stats.avgLevel), statY - spacing_between_sections,
            isLocalPlayer and "Average level of players you have killed." or "Average level of players killed.", false, isLocalPlayer)
    end

    if stats.avgKillsPerPlayer and stats.avgKillsPerPlayer > 0 then
        statY = addSummaryStatLine(container, "Avg. kills per player:", string.format("%.2f", stats.avgKillsPerPlayer), statY,
            isLocalPlayer and "Average number of kills per unique player." or "Average number of kills per unique player.", false, isLocalPlayer)
    end

    if stats.avgLevelDiff and stats.avgLevelDiff ~= 0 then
        local levelDiffText = string.format("%.1f", stats.avgLevelDiff) ..
                              (stats.avgLevelDiff > 0 and " (you're higher)" or " (you're lower)")
        statY = addSummaryStatLine(container, "Avg. level difference:", levelDiffText, statY,
            isLocalPlayer and "Average level difference between you and the players you have killed." or "Average level difference.", false, isLocalPlayer)
    end

    -- 4. Streaks
    local killStreakY = statY - spacing_between_sections
    local csTooltip = isLocalPlayer
        and "Your current kill streak on this character. Streaks persist through logouts and only end when you die or manually reset your statistics in the addon settings."
        or "Current active kill streak."

    statY = addSummaryStatLine(container, "Current kill streak:", tostring(stats.currentKillStreak or 0), killStreakY, csTooltip, true, isLocalPlayer)

    local hkTooltip = "The highest kill streak achieved."
    local mkTooltip = "The highest number of kills achieved while staying in combat."
    local hkValue = tostring(stats.highestKillStreak or 0)
    local mkValue = tostring(stats.highestMultiKill or 0)

    if isLocalPlayer then
        if PSC_DB.ShowAccountWideStats then
            hkTooltip = "The highest kill streak you ever achieved across all characters."
            if (stats.highestKillStreak or 0) > 0 then
                hkValue = hkValue .. " (" .. (stats.highestKillStreakCharacter or "") .. ")"
            end

            mkTooltip = "The highest number of kills you achieved while staying in combat across all characters."
            if (stats.highestMultiKill or 0) > 0 then
                mkValue = mkValue .. " (" .. (stats.highestMultiKillCharacter or "") .. ")"
            end
        else
            hkTooltip = "The highest kill streak you achieved on this character."
            mkTooltip = "The highest number of kills you achieved while staying in combat on this character."
        end
    end

    -- Note: Passing 'true' for isKillStreak (6th arg) to make it gold
    statY = addSummaryStatLine(container, "Highest kill streak:", hkValue, statY, hkTooltip, true, isLocalPlayer)
    statY = addSummaryStatLine(container, "Highest multi-kill:", mkValue, statY, mkTooltip, true, isLocalPlayer)

    -- 5. Time Periods
    if stats.killsToday or (isLocalPlayer and stats.killsToday ~= nil) then
        statY = addSummaryStatLine(container, "Kills today:", tostring(stats.killsToday or 0), statY, "Total player kills today.", false, isLocalPlayer)
    end
    if stats.killsThisWeek or (isLocalPlayer and stats.killsThisWeek ~= nil) then
        statY = addSummaryStatLine(container, "Kills this week:", tostring(stats.killsThisWeek or 0), statY, "Total player kills this week.", false, isLocalPlayer)
    end
    if stats.killsThisMonth or (isLocalPlayer and stats.killsThisMonth ~= nil) then
        statY = addSummaryStatLine(container, "Kills this month:", tostring(stats.killsThisMonth or 0), statY, "Total player kills this month.", false, isLocalPlayer)
    end
    if stats.killsThisYear or (isLocalPlayer and stats.killsThisYear ~= nil) then
        statY = addSummaryStatLine(container, "Kills this year:", tostring(stats.killsThisYear or 0), statY, "Total player kills this year.", false, isLocalPlayer)
    end

    statY = statY - spacing_between_sections

    -- 6. Busiest & Activity
    if stats.busiestWeekday and stats.busiestWeekday ~= "None" then
        local tip = isLocalPlayer and "Your most active day of the week for PvP kills." or "Most active day of the week."
        statY = addSummaryStatLine(container, "Busiest weekday:", stats.busiestWeekday .. " (" .. (stats.busiestWeekdayKills or 0) .. ")", statY, tip, false, isLocalPlayer)
    end

    if stats.busiestHour and stats.busiestHour ~= "None" then
        local tip = isLocalPlayer and "Your most active hour of the day for PvP kills." or "Most active hour of the day."
        statY = addSummaryStatLine(container, "Busiest hour:", stats.busiestHour .. " (" .. (stats.busiestHourKills or 0) .. ")", statY, tip, false, isLocalPlayer)
    end

    if stats.busiestMonth and stats.busiestMonth ~= "None" then
        local tip = isLocalPlayer and "Your most active month for PvP kills." or "Most active month."
        statY = addSummaryStatLine(container, "Busiest month:", stats.busiestMonth .. " (" .. (stats.busiestMonthKills or 0) .. ")", statY, tip, false, isLocalPlayer)
    end

    if stats.avgKillsPerDay and stats.avgKillsPerDay > 0 then
        local tip = isLocalPlayer and "Your average kills per day from your first recorded kill to your most recent kill. This includes all days in that time period, even days when you didn't play." or "Average kills per day."
        statY = addSummaryStatLine(container, "Average kills per day:", string.format("%.1f", stats.avgKillsPerDay), statY, tip, false, isLocalPlayer)
    end

    -- 7. Achievements
    if extraData and extraData.achievementsUnlocked and extraData.totalAchievements then
        statY = statY - spacing_between_sections
        local percentage = 0
        if extraData.totalAchievements > 0 then
            percentage = (extraData.achievementsUnlocked / extraData.totalAchievements) * 100
        end

        local achieveText = extraData.achievementsUnlocked .. " / " .. extraData.totalAchievements .. " (" .. string.format("%.1f%%", percentage) .. ")"

        if isLocalPlayer then
            local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            labelText:SetPoint("TOPLEFT", 0, statY)
            labelText:SetText("Achievements unlocked:")

            local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            valueText:SetPoint("TOPLEFT", 150, statY)
            valueText:SetText(achieveText)

            local achievementButton = CreateFrame("Button", nil, container)
            achievementButton:SetPoint("TOPLEFT", labelText, "TOPLEFT", 0, 0)
            achievementButton:SetPoint("BOTTOMRIGHT", valueText, "BOTTOMRIGHT", 0, 0)
            PSC_CreateGoldHighlight(achievementButton, 20)

            achievementButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:AddLine("Click to view your achievements", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            achievementButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
            achievementButton:SetScript("OnClick", function() PSC_ToggleAchievementFrame() end)
        else
            addSummaryStatLine(container, "Achievements:", achieveText, statY, "Total achievements completed.", false, isLocalPlayer)
        end

        statY = statY - 20

        if extraData.achievementPoints then
             local ptText = tostring(extraData.achievementPoints)
             if extraData.totalPossiblePoints then
                 ptText = ptText .. " / " .. extraData.totalPossiblePoints
             end
             statY = addSummaryStatLine(container, "Achievement points:", ptText, statY, "Total achievement points earned.", false, isLocalPlayer)
        end
    end

    -- 8. Footer Note
    if not isLocalPlayer then
        local noteText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noteText:SetPoint("BOTTOM", container, "BOTTOM", 0, -47)
        noteText:SetText("Viewing " .. (playerName or "Unknown") .. "'s statistics")
        noteText:SetTextColor(0.7, 0.7, 0.7)
    end
end

local function createSummaryStatsForExternalPlayer(parent, x, y, width, height, stats, playerName, extraData)
    local container = createContainerWithTitle(parent, "Summary Statistics", x, y, width, height)
    PSC_PopulateSummaryStatsContainer(container, stats, false, extraData, playerName)
    return container
end

local function createSummaryStats(parent, x, y, width, height)
    local container = createContainerWithTitle(parent, "Summary Statistics", x, y, width, height)

    local charactersToProcess = GetCharactersToProcessForStatistics()
    local stats = PSC_CalculateSummaryStatistics(charactersToProcess)

    local extraData = {}
    if PVPSC.AchievementSystem and PVPSC.AchievementSystem.achievements then
        local currentCharacterKey = PSC_GetCharacterKey()
        local totalCount = #PVPSC.AchievementSystem.achievements
        local completedCount = 0

        if PSC_DB.CharacterAchievements and PSC_DB.CharacterAchievements[currentCharacterKey] then
            for _, achievementData in pairs(PSC_DB.CharacterAchievements[currentCharacterKey]) do
                if achievementData.unlocked then
                    completedCount = completedCount + 1
                end
            end
        end

        extraData.achievementsUnlocked = completedCount
        extraData.totalAchievements = totalCount
        extraData.achievementPoints = PSC_DB.CharacterAchievementPoints[currentCharacterKey] or 0
        extraData.totalPossiblePoints = PVPSC.AchievementSystem:GetTotalPossiblePoints()
    end

    PSC_PopulateSummaryStatsContainer(container, stats, true, extraData)
    return container
end

function PSC_CalculateBarChartStatistics(charactersToProcess)
    local db = PSC_DB
    local playerInfoCache = db.PlayerInfoCache
    local getInfoKeyFromName = PSC_GetInfoKeyFromName
    local strfind = string.find
    local strsub = string.sub
    local tonumber = tonumber
    local ipairs = ipairs
    local pairs = pairs

    local infoKeyCache = {}

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
    local npcKillsData = {
        ["Corporal Keeshan"] = 0,
        ["The Defias Traitor"] = 0,
        ["Defias Messenger"] = 0
    }

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

    if not db.PlayerKillCounts.Characters then
        return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData
    end

    for _, characterData in pairs(charactersToProcess) do
        if characterData.NPCKills then
            for npcName, kills in pairs(characterData.NPCKills) do
                npcKillsData[npcName] = (npcKillsData[npcName] or 0) + kills
            end
        end

        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 then
                    local colonIndex = strfind(nameWithLevel, ":", 1, true)
                    local nameWithoutLevel
                    local levelPart
                    if colonIndex then
                        nameWithoutLevel = strsub(nameWithLevel, 1, colonIndex - 1)
                        levelPart = strsub(nameWithLevel, colonIndex + 1)
                    else
                        nameWithoutLevel = nameWithLevel
                        levelPart = nil
                    end

                    local kills = killData.kills

                    local infoKey = infoKeyCache[nameWithoutLevel]
                    if not infoKey then
                        infoKey = PSC_NormalizePlayerName(nameWithoutLevel)
                        infoKeyCache[nameWithoutLevel] = infoKey
                    end

                    local info = infoKey and playerInfoCache[infoKey] or nil
                    if info then
                        local class = info.class
                        if class then
                            classData[class] = (classData[class] or 0) + kills
                        end

                        local levelNum = tonumber(levelPart or "0") or 0
                        if levelNum == -1 then
                            if class then
                                unknownLevelClassData[class] = (unknownLevelClassData[class] or 0) + kills
                            end
                            levelData["??"] = (levelData["??"] or 0) + kills
                        else
                            if levelNum > 0 and levelNum <= 60 then
                                local levelKey = levelPart
                                if not levelKey or levelKey == "" then
                                    levelKey = tostring(levelNum)
                                end
                                levelData[levelKey] = (levelData[levelKey] or 0) + kills
                            end
                        end

                        local race = info.race
                        if race then
                            raceData[race] = (raceData[race] or 0) + kills
                        end

                        local gender = info.gender
                        if gender then
                            genderData[gender] = (genderData[gender] or 0) + kills
                        end

                        if killData.killLocations and #killData.killLocations > 0 then
                            for _, location in ipairs(killData.killLocations) do
                                local zone = location.zone or "Unknown"
                                zoneData[zone] = (zoneData[zone] or 0) + 1
                            end
                        end

                        local guild = info.guild
                        if guild and guild ~= "" then
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

    return classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData, npcKillsData
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

function PSC_CalculateYearlyStatistics(charactersToProcess)
    local yearlyData = {}

    if not PSC_DB.PlayerKillCounts.Characters then
        return yearlyData
    end

    for characterKey, characterData in pairs(charactersToProcess) do
        if characterData.Kills then
            for nameWithLevel, killData in pairs(characterData.Kills) do
                if killData.kills and killData.kills > 0 and killData.killLocations then
                    for _, location in ipairs(killData.killLocations) do
                        if location.timestamp then
                            local dateInfo = date("*t", location.timestamp)
                            if dateInfo and dateInfo.year then
                                yearlyData[dateInfo.year] = (yearlyData[dateInfo.year] or 0) + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return yearlyData
end

local function createScrollableLeftPanel(parent)
    local leftPanel = CreateFrame("Frame", nil, parent)
    leftPanel:SetPoint("TOPLEFT", 0, 0)
    leftPanel:SetPoint("BOTTOMLEFT", 0, 0)
    leftPanel:SetWidth(430)

    local containerFrame = CreateFrame("Frame", nil, parent)
    containerFrame:SetPoint("TOPLEFT", UI.LEFT_SCROLL_PADDING, -UI.TOP_PADDING)
    containerFrame:SetPoint("BOTTOMLEFT", UI.LEFT_SCROLL_PADDING, 10)
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
        PSC_FrameManager:HideFrame("Statistics")
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

function PSC_UpdateStatisticsFrame(frame, externalPlayerData)
    if not frame then
        return
    end

    -- Determine if we're viewing external player data or local data
    local isExternalPlayer = (externalPlayerData ~= nil)
    local playerDisplayName = isExternalPlayer and externalPlayerData.playerName or nil

    -- Set title based on whether it's external or local data
    local titleText
    if isExternalPlayer and playerDisplayName then
        titleText = playerDisplayName .. "'s PvP Statistics"
        if externalPlayerData.level and externalPlayerData.class then
            titleText = titleText .. " (Lvl " .. externalPlayerData.level .. " " .. externalPlayerData.class .. ")"
        end
    else
        titleText = GetFrameTitleTextWithCharacterText("PvP Statistics")
    end
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

    if frame.buttonContainer then
        frame.buttonContainer:SetParent(nil)
        frame.buttonContainer = nil
    end

    if frame:GetHeight() < 400 then
        return
    end

    -- Get data based on whether we're viewing external or local player
    local classData, raceData, genderData, zoneData, levelData, hourlyData, weekdayData, monthlyData, yearlyData, stats
    local unknownLevelClassData, guildStatusData, guildData, npcKillsData

    if isExternalPlayer then
        -- Use data from external player
        classData = externalPlayerData.classData or {}
        raceData = externalPlayerData.raceData or {}
        genderData = externalPlayerData.genderData or {}
        zoneData = externalPlayerData.zoneData or {}
        levelData = externalPlayerData.levelData or {}
        hourlyData = externalPlayerData.hourlyData or {}
        weekdayData = externalPlayerData.weekdayData or {}
        monthlyData = externalPlayerData.monthlyData or {}
        yearlyData = externalPlayerData.yearlyData or {}
        stats = externalPlayerData.summary or {}
        -- Set defaults for data not available from external players
        unknownLevelClassData = externalPlayerData.unknownLevelClassData or {}
        guildStatusData = externalPlayerData.guildStatusData or {}
        guildData = {}
        npcKillsData = externalPlayerData.npcKillsData or {}
    else
        -- Calculate local player data
        local currentCharacterKey = PSC_GetCharacterKey()
        local charactersToProcess = {}
        if PSC_DB.ShowAccountWideStats then
            charactersToProcess = PSC_DB.PlayerKillCounts.Characters
        else
            if PSC_DB.PlayerKillCounts.Characters[currentCharacterKey] then
                charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
            end
        end

        classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData, guildData, npcKillsData =
            PSC_CalculateBarChartStatistics(charactersToProcess)

        hourlyData = PSC_CalculateHourlyStatistics(charactersToProcess)
        weekdayData = PSC_CalculateWeekdayStatistics(charactersToProcess)
        monthlyData = PSC_CalculateMonthlyStatistics(charactersToProcess)
        yearlyData = PSC_CalculateYearlyStatistics(charactersToProcess)
        stats = PSC_CalculateSummaryStatistics(charactersToProcess)
    end

    local leftScrollContent, leftScrollFrame = createScrollableLeftPanel(frame)
    frame.leftScrollContent = leftScrollContent
    frame.leftScrollFrame = leftScrollFrame

    local classChartHeight = calculateChartHeight(classData)
    local raceChartHeight = calculateChartHeight(raceData)
    local genderChartHeight = calculateChartHeight(genderData)
    local hourlyChartHeight = calculateChartHeight(hourlyData)
    local weekdayChartHeight = calculateChartHeight(weekdayData)
    local monthlyChartHeight = calculateChartHeight(monthlyData)
    local yearlyChartHeight = calculateChartHeight(yearlyData)
    local levelChartHeight = calculateChartHeight(levelData)
    local zoneChartHeight = calculateChartHeight(zoneData)
    local fixedNPCs = {}
    if UnitFactionGroup("player") == "Horde" then
        fixedNPCs["Corporal Keeshan"] = true
        fixedNPCs["The Defias Traitor"] = true
        fixedNPCs["Defias Messenger"] = true
        -- Ensure keys exist for display even if 0 (due to network compression skipping them)
        if npcKillsData then
            npcKillsData["Corporal Keeshan"] = npcKillsData["Corporal Keeshan"] or 0
            npcKillsData["The Defias Traitor"] = npcKillsData["The Defias Traitor"] or 0
            npcKillsData["Defias Messenger"] = npcKillsData["Defias Messenger"] or 0
        end
    end
    local npcChartHeight = calculateChartHeight(npcKillsData, fixedNPCs)

    local yOffset = 0
    createBarChart(leftScrollContent, "Kills by Class", classData, nil, 0, yOffset, UI.CHART.WIDTH, classChartHeight, isExternalPlayer)
    yOffset = yOffset - classChartHeight - UI.CHART.PADDING

    createBarChart(leftScrollContent, "Kills by Race", raceData, raceColors, 0, yOffset, UI.CHART.WIDTH, raceChartHeight, isExternalPlayer)
    yOffset = yOffset - raceChartHeight - UI.CHART.PADDING

    if npcChartHeight > 45 then
        createBarChart(leftScrollContent, "NPC Kills", npcKillsData, nil, 0, yOffset, UI.CHART.WIDTH, npcChartHeight, isExternalPlayer)
    end
    yOffset = yOffset - npcChartHeight - UI.CHART.PADDING

    createBarChart(leftScrollContent, "Kills by Gender", genderData, genderColors, 0, yOffset, UI.CHART.WIDTH,
        genderChartHeight, isExternalPlayer)
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
        UI.CHART.WIDTH, guildStatusChartHeight, isExternalPlayer)

    yOffset = yOffset - guildStatusChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Hour of Day", hourlyData, nil, 0, yOffset, UI.CHART.WIDTH, hourlyChartHeight, isExternalPlayer)

    yOffset = yOffset - hourlyChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Weekday", weekdayData, nil, 0, yOffset, UI.CHART.WIDTH, weekdayChartHeight, isExternalPlayer)

    yOffset = yOffset - weekdayChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Month", monthlyData, nil, 0, yOffset, UI.CHART.WIDTH, monthlyChartHeight, isExternalPlayer)

    yOffset = yOffset - monthlyChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Year", yearlyData, nil, 0, yOffset, UI.CHART.WIDTH, yearlyChartHeight, isExternalPlayer)

    yOffset = yOffset - yearlyChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Level", levelData, nil, 0, yOffset, UI.CHART.WIDTH, levelChartHeight, isExternalPlayer)

    yOffset = yOffset - levelChartHeight - UI.CHART.PADDING
    createBarChart(leftScrollContent, "Kills by Zone", zoneData, nil, 0, yOffset, UI.CHART.WIDTH, zoneChartHeight, isExternalPlayer)

    -- Add Guild Kills table in left panel after Kills by Zone (only for local player)
    if not isExternalPlayer then
        yOffset = yOffset - zoneChartHeight - UI.CHART.PADDING
        frame.guildTable = createGuildTable(leftScrollContent, 0, yOffset, UI.CHART.WIDTH, UI.GUILD_LIST.HEIGHT)
        local totalHeight = -(yOffset) + UI.GUILD_LIST.HEIGHT + 25
        leftScrollContent:SetHeight(totalHeight)
    else
        -- For external players, no guild table
        local totalHeight = -(yOffset - zoneChartHeight) + 25
        leftScrollContent:SetHeight(totalHeight)

        -- Extra charts for external players (unknown level / class) if data exists
        if calculateChartHeight(unknownLevelClassData) > 50 then
            -- We don't display this specifically in separate charts usually,
            -- but the 'Kills by Class' chart usually covers it if 'Unknown' is a valid key.
            -- However, 'Level ??' kills often come from 'unknownLevelClassData' processing in standard flow.
            -- The standard 'Kills by Class' chart function uses 'classData'.
            -- 'unknownLevelClassData' is separate, often tracking kills where level/class was missing
            -- but standard logic merges them into main counts usually.

            -- If the user wants to see "Level ?? kills" specifically,
            -- usually that's just part of "Kills by Level" where key is "-1".
        end
    end

    local summaryStatsWidth = 380
    local summaryStatsHeight = 500

    -- Summary Statistics at top right (pass stats if external player)
    if isExternalPlayer then
        frame.summaryStats = createSummaryStatsForExternalPlayer(frame, 440, -UI.TOP_PADDING, summaryStatsWidth, summaryStatsHeight, stats, playerDisplayName, externalPlayerData)
    else
        frame.summaryStats = createSummaryStats(frame, 440, -UI.TOP_PADDING, summaryStatsWidth, summaryStatsHeight)
    end

    -- Separator line above buttons
    local buttonSeparatorLine = frame:CreateTexture(nil, "ARTWORK")
    buttonSeparatorLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 430, 105)
    buttonSeparatorLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 105)
    buttonSeparatorLine:SetHeight(1)
    buttonSeparatorLine:SetColorTexture(0.5, 0.5, 0.5, 0.5)

    -- Button container at bottom right in 3 rows with 2 columns
    local buttonContainer = CreateFrame("Frame", nil, frame)
    local buttonWidth = 140
    local buttonHeight = 25
    local buttonSpacing = 5
    buttonContainer:SetSize((buttonWidth * 2) + buttonSpacing, (buttonHeight * 3) + (buttonSpacing * 2))
    buttonContainer:SetPoint("BOTTOM", frame, "BOTTOM", 210, 13)
    frame.buttonContainer = buttonContainer

    -- Top left button: Settings
    local settingsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    settingsButton:SetSize(buttonWidth, buttonHeight)
    settingsButton:SetPoint("TOPLEFT", buttonContainer, "TOPLEFT", 0, 0)
    settingsButton:SetText("Show Settings")
    settingsButton:SetScript("OnClick", function()
        PSC_CreateConfigUI()
    end)

    -- Top right button: Achievements
    local achievementsButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    achievementsButton:SetSize(buttonWidth, buttonHeight)
    achievementsButton:SetPoint("TOPRIGHT", buttonContainer, "TOPRIGHT", 0, 0)
    achievementsButton:SetText("Show Achievements")
    achievementsButton:SetScript("OnClick", function()
        PSC_ToggleAchievementFrame()
    end)

    -- Middle left button: Kill History
    local killHistoryButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    killHistoryButton:SetSize(buttonWidth, buttonHeight)
    killHistoryButton:SetPoint("TOPLEFT", settingsButton, "BOTTOMLEFT", 0, -buttonSpacing)
    killHistoryButton:SetText("Show Kill History")
    killHistoryButton:SetScript("OnClick", function()
        PSC_CreateKillsListFrame()
    end)

    -- Middle right button: Kill Streak
    local killstreakButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    killstreakButton:SetSize(buttonWidth, buttonHeight)
    killstreakButton:SetPoint("TOPRIGHT", achievementsButton, "BOTTOMRIGHT", 0, -buttonSpacing)
    killstreakButton:SetText("Show Kill Streak")
    killstreakButton:SetScript("OnClick", function()
        PSC_CreateKillStreakPopup()
    end)

    -- Bottom button: Leaderboard (Full width)
    local leaderboardButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
    leaderboardButton:SetSize((buttonWidth * 2) + buttonSpacing, buttonHeight)
    leaderboardButton:SetPoint("TOPLEFT", killHistoryButton, "BOTTOMLEFT", 0, -buttonSpacing)
    leaderboardButton:SetText("Show Leaderboard")
    leaderboardButton:SetScript("OnClick", function()
        PSC_CreateLeaderboardFrame()
    end)
end

-- Display another player's detailed statistics
function PSC_ShowPlayerDetailedStats(playerName, detailedStats)
    -- Create a separate frame for viewing other players' stats
    local viewerFrame = CreateFrame("Frame", "PSC_PlayerStatsViewer_" .. playerName, UIParent, "BasicFrameTemplateWithInset")
    viewerFrame:SetSize(UI.FRAME.WIDTH, UI.FRAME.HEIGHT)
    viewerFrame:SetPoint("CENTER")
    viewerFrame:SetMovable(true)
    viewerFrame:EnableMouse(true)
    viewerFrame:RegisterForDrag("LeftButton")
    viewerFrame:SetScript("OnDragStart", viewerFrame.StartMoving)
    viewerFrame:SetScript("OnDragStop", viewerFrame.StopMovingOrSizing)

    -- Add close button
    viewerFrame.CloseButton:SetScript("OnClick", function()
        viewerFrame:Hide()
        -- Frame manager will handle cleanup automatically when frame is hidden
    end)

    -- Register with frame manager
    if PSC_FrameManager then
        PSC_FrameManager:RegisterFrame(viewerFrame, "PlayerStatsViewer_" .. playerName)
    end

    -- Reuse the existing update function with external player data
    PSC_UpdateStatisticsFrame(viewerFrame, detailedStats)

    viewerFrame:Show()
end
