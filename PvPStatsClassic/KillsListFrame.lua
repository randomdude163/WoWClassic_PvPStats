PSC_KillsListFrame = nil

PSC_SortKillsListBy = "lastKill"
PSC_SortKillsListAscending = false
local KILLS_FRAME_WIDTH = 1020
local KILLS_FRAME_HEIGHT = 550

local colWidths = {
    name = 100,
    class = 70,
    race = 70,
    gender = 80,
    level = 70,
    rank = 70,
    guild = 150,
    zone = 150,
    kills = 50,
    lastKill = 160
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
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)

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
    end)
    button:SetScript("OnLeave", function(self)
        SetHeaderButtonHighlight(self, false)
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
    local nameButton = CreateColumnHeader(content, "Name", colWidths.name, nil, 10, 0, "name")
    local classButton = CreateColumnHeader(content, "Class", colWidths.class, nameButton, 0, 0, "class")
    local raceButton = CreateColumnHeader(content, "Race", colWidths.race, classButton, 0, 0, "race")
    local genderButton = CreateColumnHeader(content, "Gender", colWidths.gender, raceButton, 0, 0, "gender")
    local levelButton = CreateColumnHeader(content, "Level", colWidths.level, genderButton, 0, 0, "level")
    local rankButton = CreateColumnHeader(content, "Rank", colWidths.rank, levelButton, 0, 0, "rank") -- New rank column header
    local guildButton = CreateColumnHeader(content, "Guild", colWidths.guild, rankButton, 0, 0, "guild") -- Changed anchor
    local zoneButton = CreateColumnHeader(content, "Zone", colWidths.zone, guildButton, 0, 0, "zone")
    local killsButton = CreateColumnHeader(content, "Kills", colWidths.kills, zoneButton, 0, 0, "kills")
    local lastKillButton = CreateColumnHeader(content, "Last Killed", colWidths.lastKill, killsButton, 0, 0, "lastKill")

    return -30
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

    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[className:upper()] then
        local color = RAID_CLASS_COLORS[className:upper()]
        classText:SetTextColor(color.r, color.g, color.b)
    end

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

local function FormatLastKillDate(timestamp)
    if not timestamp or timestamp == 0 then
        return ""
    end

    local dateInfo = date("*t", timestamp)
    return string.format("%02d/%02d/%02d %02d:%02d:%02d",
        dateInfo.day, dateInfo.month, dateInfo.year % 100,
        dateInfo.hour, dateInfo.min, dateInfo.sec)
end

local function CreateLastKillCell(content, anchorTo, lastKill, width)
    local lastKillText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastKillText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    lastKillText:SetText(FormatLastKillDate(lastKill))
    lastKillText:SetWidth(width)
    lastKillText:SetJustifyH("LEFT")
    return lastKillText
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
    local raceCell = CreateRaceCell(rowContainer, classCell, entry.race, colWidths.race)
    local genderCell = CreateGenderCell(rowContainer, raceCell, entry.gender, colWidths.gender)
    local levelCell = CreateLevelCell(rowContainer, genderCell, entry.levelDisplay, colWidths.level)
    local rankCell = CreateRankCell(rowContainer, levelCell, entry.rank, colWidths.rank)
    local guildCell = CreateGuildCell(rowContainer, rankCell, entry.guild, colWidths.guild)
    local zoneCell = CreateZoneCell(rowContainer, guildCell, entry.zone, colWidths.zone)
    local killsCell = CreateKillsCell(rowContainer, zoneCell, entry.kills, colWidths.kills)
    local lastKillCell = CreateLastKillCell(rowContainer, killsCell, entry.lastKill, colWidths.lastKill)

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
    local titleText = GetFrameTitleTextWithCharacterText("Player Kills")
    frame.TitleText:SetText(titleText)

    return frame
end

function RefreshKillsListFrame()
    if PSC_KillsListFrame == nil then
        return
    end
    local content = PSC_KillsListFrame.content
    if not content then
        return
    end

    local titleText = GetFrameTitleTextWithCharacterText("Player Kills")
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

    RefreshKillsListFrame()
end
