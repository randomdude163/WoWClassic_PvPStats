PSC_KillsListFrame = nil

PSC_SortKillsListBy = "lastKill"
PSC_SortKillsListAscending = false
local KILLS_FRAME_WIDTH = 1055
local KILLS_FRAME_HEIGHT = 550

PSC_KillsListFrameInitialSetup = true

local colWidths = {
    name = 95,
    class = 68,
    race = 65,
    gender = 80,
    level = 45,
    kills = 33,
    deaths = 33,
    assists = 33, -- New column for assists
    rank = 60,
    guild = 165,
    zone = 140,
    lastKill = 190
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

    collectgarbage("collect")
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
        if PSC_SortKillsListBy == columnId then
            PSC_SortKillsListAscending = not PSC_SortKillsListAscending
        else
            PSC_SortKillsListBy = columnId
            PSC_SortKillsListAscending = false
        end
        RefreshKillsListFrame()
    end)

    local header = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("LEFT", 3, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetWidth(width - 6)
    header:SetJustifyH("LEFT")

    header:SetText(text)

    if PSC_SortKillsListBy == columnId then
        local sortIndicator = PSC_SortKillsListAscending and " ^" or " v"
        header:SetText(text .. sortIndicator)
    end

    button:SetFontString(header)

    button:SetScript("OnEnter", function(self)
        SetHeaderButtonHighlight(self, true)

        -- Add tooltips for specific columns
        if columnId == "kills" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Kills", 1, 0.82, 0)
            GameTooltip:AddLine("The number of times you have killed this player", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "deaths" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Deaths", 1, 0.82, 0)
            GameTooltip:AddLine("The number of times this player has dealt a killing blow against you", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "assists" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Assists", 1, 0.82, 0)
            GameTooltip:AddLine("The number of times this player damaged you without dealing a killing blow when you died", 1, 1, 1, true)
            GameTooltip:Show()
        elseif columnId == "lastKill" then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Last Encounter", 1, 0.82, 0)
            GameTooltip:AddLine("The date and time of your most recent PvP interaction with this player (kill, death, or assist)", 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)

    button:SetScript("OnLeave", function(self)
        SetHeaderButtonHighlight(self, false)
        GameTooltip:Hide()
    end)

    return button
end

function GetCharactersToProcessForStatistics()
    local charactersToProcess = {}
    local currentCharacterKey = PSC_GetCharacterKey()

    if PSC_DB.ShowAccountWideStats then
        charactersToProcess = PSC_DB.PlayerKillCounts.Characters
    else
        charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
    end

    return charactersToProcess
end

local function CreateColumnHeaders(content)
    -- Add a background texture behind all the headers to create a unified header row
    local headerRowBg = content:CreateTexture(nil, "BACKGROUND")
    headerRowBg:SetPoint("TOPLEFT", 10, 0)
    headerRowBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, 0)
    headerRowBg:SetHeight(24)
    headerRowBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)  -- Match the PlayerDetailFrame header background

    local nameButton = CreateColumnHeader(content, "Name", colWidths.name, nil, 10, 0, "name")
    local classButton = CreateColumnHeader(content, "Class", colWidths.class, nameButton, 0, 0, "class")
    local levelButton = CreateColumnHeader(content, "Lvl", colWidths.level, classButton, 0, 0, "levelDisplay")
    local rankButton = CreateColumnHeader(content, "Rank", colWidths.rank, levelButton, 0, 0, "rank")
    local killsButton = CreateColumnHeader(content, "K", colWidths.kills, rankButton, 0, 0, "kills")
    local deathsButton = CreateColumnHeader(content, "D", colWidths.deaths, killsButton, 0, 0, "deaths")
    local assistsButton = CreateColumnHeader(content, "A", colWidths.assists, deathsButton, 0, 0, "assists")
    local guildButton = CreateColumnHeader(content, "Guild", colWidths.guild, assistsButton, 0, 0, "guild")
    local zoneButton = CreateColumnHeader(content, "Zone", colWidths.zone, guildButton, 0, 0, "zone")
    local raceButton = CreateColumnHeader(content, "Race", colWidths.race, zoneButton, 0, 0, "race")
    local genderButton = CreateColumnHeader(content, "Gender", colWidths.gender, raceButton, 0, 0, "gender")
    local lastKillButton = CreateColumnHeader(content, "Last Encounter", colWidths.lastKill, genderButton, 0, 0, "lastKill")

    return -30
end

local function CreateDeathsCell(content, anchorTo, deaths, width)
    local deathsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    deathsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    deathsText:SetText(tostring(deaths))
    deathsText:SetWidth(width)
    deathsText:SetJustifyH("LEFT")
    return deathsText
end

local function CreateNameCell(content, xPos, yPos, name, width)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", content, "LEFT", 4, 0)
    nameText:SetText(name)
    nameText:SetWidth(width)
    nameText:SetJustifyH("LEFT")
    return nameText
end

local function CreateClassCell(content, anchorTo, className, width)
    local classText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    classText:SetPoint("LEFT", anchorTo, "RIGHT", 0, 0)

    classText:SetText(className)
    classText:SetWidth(width)
    classText:SetJustifyH("LEFT")

    -- Don't color the class name text by class color - keep it white by default
    -- classText is already white by default with GameFontHighlight

    return classText
end

local function CreateRaceCell(content, anchorTo, raceName, width)
    local raceText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    raceText:SetPoint("LEFT", anchorTo, "RIGHT", 0, 0)

    if raceName and raceName ~= "Unknown" then
        raceName = raceName:gsub("(%w)(%w*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end

    raceText:SetText(raceName)
    raceText:SetWidth(width)
    raceText:SetJustifyH("LEFT")
    return raceText
end

local function CreateGenderCell(content, anchorTo, gender, width)
    local genderText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    genderText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    genderText:SetText(gender)
    genderText:SetWidth(width)
    genderText:SetJustifyH("LEFT")
    return genderText
end

local function CreateLevelCell(content, anchorTo, level, width)
    local levelText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    levelText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

        levelText:SetText(level == -1 and "??" or tostring(level))
    levelText:SetWidth(width)
    levelText:SetJustifyH("LEFT")
    return levelText
end

local function CreateGuildCell(content, anchorTo, guild, width)
    local guildText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    guildText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    guildText:SetText(guild)
    guildText:SetWidth(width)
    guildText:SetJustifyH("LEFT")
    return guildText
end

local function CreateKillsCell(content, anchorTo, kills, width)
    local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    killsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    killsText:SetText(tostring(kills))
    killsText:SetWidth(width)
    killsText:SetJustifyH("LEFT")
    return killsText
end

local function CreateAssistsCell(content, anchorTo, assists, width)
    local assistsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    assistsText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    assistsText:SetText(tostring(assists or 0))
    assistsText:SetWidth(width)
    assistsText:SetJustifyH("LEFT")
    return assistsText
end

local function FormatLastKillDate(timestamp)
    if not timestamp or timestamp == 0 then
        return "-"
    end

    -- Debug check - make sure timestamp is a valid number
    if type(timestamp) ~= "number" then
        return "-"
    end

    -- Make sure timestamp is recent enough to be valid
    local minTimestamp = 1000000000  -- Roughly year 2001
    if timestamp < minTimestamp then
        return "-"
    end

    local dateInfo = date("*t", timestamp)
    if not dateInfo then
        return "-"
    end

    return string.format("%02d/%02d/%02d %02d:%02d:%02d",
        dateInfo.day, dateInfo.month, dateInfo.year % 100,
        dateInfo.hour, dateInfo.min, dateInfo.sec)
end

local function CreateLastKillCell(content, anchorTo, lastKill, width)
    local lastKillContainer = CreateFrame("Frame", nil, content)
    lastKillContainer:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    lastKillContainer:SetSize(width, 16)

    local dateText = lastKillContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dateText:SetPoint("LEFT", 0, 0)
    dateText:SetJustifyH("LEFT")

    local timeSpanText = lastKillContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpanText:SetPoint("LEFT", dateText, "RIGHT", 0, 0)
    timeSpanText:SetJustifyH("LEFT")

    -- Use a soft blue color for the timespan text
    timeSpanText:SetTextColor(0.6, 0.8, 1.0)

    local dateString = FormatLastKillDate(lastKill)
    local timespan = ""

    -- Only add timespan if we have a valid lastKill timestamp
    if lastKill and lastKill > 0 then
        local timeSinceLastKill = PSC_FormatLastKillTimespan(lastKill)
        if timeSinceLastKill then
            timespan = "  (" .. timeSinceLastKill .. " ago)"
        end
    end

    dateText:SetText(dateString)
    timeSpanText:SetText(timespan)

    return lastKillContainer
end

local function CreateZoneCell(content, anchorTo, zone, width)
    local zoneText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zoneText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    zoneText:SetText(zone)
    zoneText:SetWidth(width)
    zoneText:SetJustifyH("LEFT")
    return zoneText
end

local function CreateRankCell(content, anchorTo, rank, width)
    local rankText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rankText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

    local rankDisplay = "0"
    if rank and rank > 0 then
        rankDisplay = tostring(rank)
    end

    rankText:SetText(rankDisplay)
    rankText:SetWidth(width)
    rankText:SetJustifyH("LEFT")
    return rankText
end

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

local function CreateEntryRow(content, entry, yOffset, colWidths, isAlternate)
    local rowContainer = CreateFrame("Button", nil, content)
    rowContainer:SetSize(content:GetWidth() - 20, 16)
    rowContainer:SetPoint("TOPLEFT", 10, yOffset)

    if isAlternate then
        local bgTexture = rowContainer:CreateTexture(nil, "BACKGROUND")
        bgTexture:SetAllPoints()
        bgTexture:SetColorTexture(0.05, 0.05, 0.05, 0.3)
    end

    local highlightTexture = CreateGoldHighlight(rowContainer, 16)

    local nameCell = CreateNameCell(rowContainer, 0, 0, entry.name, colWidths.name)
    local classCell = CreateClassCell(rowContainer, nameCell, entry.class, colWidths.class)
    local levelCell = CreateLevelCell(rowContainer, classCell, entry.levelDisplay, colWidths.level)
    local rankCell = CreateRankCell(rowContainer, levelCell, entry.rank, colWidths.rank)
    local killsCell = CreateKillsCell(rowContainer, rankCell, entry.kills, colWidths.kills)
    local deathsCell = CreateDeathsCell(rowContainer, killsCell, entry.deaths, colWidths.deaths)
    local assistsCell = CreateAssistsCell(rowContainer, deathsCell, entry.assists or 0, colWidths.assists)
    local guildCell = CreateGuildCell(rowContainer, assistsCell, entry.guild, colWidths.guild)
    local zoneCell = CreateZoneCell(rowContainer, guildCell, entry.zone, colWidths.zone)
    local raceCell = CreateRaceCell(rowContainer, zoneCell, entry.race, colWidths.race)
    local genderCell = CreateGenderCell(rowContainer, raceCell, entry.gender, colWidths.gender)
    local lastKillCell = CreateLastKillCell(rowContainer, genderCell, entry.lastKill, colWidths.lastKill)

    -- Add click handler to view detailed history
    rowContainer:SetScript("OnClick", function()
        PSC_ShowPlayerDetailFrame(entry.name)
    end)

    -- Check if entry has incomplete information
    -- Fix: Don't consider level -1 as incomplete if it's a "??" level since that's valid data
    local hasIncompleteInfo = (entry.class == "Unknown" or entry.race == "Unknown" or entry.gender == "Unknown")

    -- Apply class color to name but keep class text white
    if not hasIncompleteInfo and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class:upper()] then
        local color = RAID_CLASS_COLORS[entry.class:upper()]
        nameCell:SetTextColor(color.r, color.g, color.b)
        -- Don't modify class cell color here - it stays white
    end

    if hasIncompleteInfo then
        -- Gray out all cells for incomplete entries
        local grayColor = {r = 0.7, g = 0.7, b = 0.7}

        if nameCell and nameCell.SetTextColor then nameCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if classCell and classCell.SetTextColor then classCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if raceCell and raceCell.SetTextColor then raceCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if genderCell and genderCell.SetTextColor then genderCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if levelCell and levelCell.SetTextColor then levelCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if killsCell and killsCell.SetTextColor then killsCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if deathsCell and deathsCell.SetTextColor then deathsCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if assistsCell and assistsCell.SetTextColor then assistsCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if rankCell and rankCell.SetTextColor then rankCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if guildCell and guildCell.SetTextColor then guildCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end
        if zoneCell and zoneCell.SetTextColor then zoneCell:SetTextColor(grayColor.r, grayColor.g, grayColor.b) end

        -- Handle last kill cell which is a container frame with multiple text elements
        if lastKillCell then
            -- Get all text elements inside the container and set their color
            local regions = {lastKillCell:GetRegions()}
            for _, region in pairs(regions) do
---@diagnostic disable-next-line: undefined-field
                if region.SetTextColor then
---@diagnostic disable-next-line: undefined-field
                    region:SetTextColor(grayColor.r, grayColor.g, grayColor.b)
                end
            end
        end
    end

    rowContainer:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(entry.name)

        if hasIncompleteInfo then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Incomplete player information", 1, 0.5, 0)
            GameTooltip:AddLine("This player was detected in combat logs, but you never targeted or moused over them directly. Therefore, only the player's name is available.", 1, 1, 1, true)
            GameTooltip:AddLine("Complete information will be added if you mouseover or target this player again.", 1, 1, 1, true)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to view detailed history", 1, 1, 1)
        GameTooltip:Show()
    end)

    rowContainer:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return yOffset - 16
end

local function DisplayEntries(content, sortedEntries, startYOffset)
    local yOffset = startYOffset
    local count = 0
    local maxDisplayEntries = 500

    for i, entry in ipairs(sortedEntries) do
        if count >= maxDisplayEntries then
            break
        end

        yOffset = CreateEntryRow(content, entry, yOffset, colWidths, (count % 2 == 1))
        count = count + 1
    end

    if count == maxDisplayEntries and #sortedEntries > maxDisplayEntries then
        local moreText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        moreText:SetPoint("TOPLEFT", 10, yOffset - 10)
        moreText:SetText("Showing " .. count .. " of " .. #sortedEntries .. " entries. Use the filters to narrow results.")
        moreText:SetTextColor(1, 0.7, 0)
        yOffset = yOffset - 20
    end

    return yOffset, count
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(KILLS_FRAME_WIDTH - 40, KILLS_FRAME_HEIGHT * 2)
    scrollFrame:SetScrollChild(content)

    return content
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PSC_KillStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(KILLS_FRAME_WIDTH, KILLS_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    table.insert(UISpecialFrames, "PSC_KillStatsFrame")
    local titleText = GetFrameTitleTextWithCharacterText("PvP History")
    frame.TitleText:SetText(titleText)

    return frame
end

function RefreshKillsListFrame()
    if PSC_KillsListFrameInitialSetup then
        return
    end

    if PSC_KillsListFrame == nil then
        return
    end

    local content = PSC_KillsListFrame.content
    if not content then
        return
    end

    local titleText = GetFrameTitleTextWithCharacterText("PvP History")
    PSC_KillsListFrame.TitleText:SetText(titleText)

    CleanupFrameElements(content)
    collectgarbage("collect")

    local yOffset = CreateColumnHeaders(content)
    local sortedEntries = PSC_FilterAndSortEntries()
    local finalYOffset, entryCount = DisplayEntries(content, sortedEntries, yOffset)

    content:SetHeight(math.max((-finalYOffset + 20), KILLS_FRAME_HEIGHT - 50))
end

function PSC_CreateKillsListFrame()
    if (PSC_KillsListFrame) then
        PSC_FrameManager:ShowFrame("KillsList")
        RefreshKillsListFrame()
        return
    end

    PSC_KillsListFrame = CreateMainFrame()
    PSC_KillsListFrame.content = CreateScrollFrame(PSC_KillsListFrame)
    PSC_CreateSearchBar(PSC_KillsListFrame)

    PSC_FrameManager:RegisterFrame(PSC_KillsListFrame, "KillsList")

    local titleText = GetFrameTitleTextWithCharacterText("Player Kills List")
    PSC_KillsListFrame.TitleText:SetText(titleText)

    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PSC_KillStatsFrame") then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    C_Timer.After(0.01, function()
        PSC_KillsListFrameInitialSetup = false
        RefreshKillsListFrame()
    end)
end
