PSC_KillsListFrame = nil
local searchText = ""
local levelSearchText = ""
local classSearchText = ""
local raceSearchText = ""
local genderSearchText = ""
local zoneSearchText = ""
local rankSearchText = ""
local minLevelSearch = nil
local maxLevelSearch = nil
local minRankSearch = nil
local maxRankSearch = nil
local sortBy = "lastKill"
local sortAscending = false
local PSC_KILLS_FRAME_WIDTH = 1020
local PSC_KILLS_FRAME_HEIGHT = 550

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

local function CreateBoxBorder(box)
    local border = {}

    border.top = box:CreateTexture(nil, "BACKGROUND")
    border.top:SetHeight(1)
    border.top:SetPoint("TOPLEFT", box, "TOPLEFT", -1, 1)
    border.top:SetPoint("TOPRIGHT", box, "TOPRIGHT", 1, 1)
    border.top:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.bottom = box:CreateTexture(nil, "BACKGROUND")
    border.bottom:SetHeight(1)
    border.bottom:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", -1, -1)
    border.bottom:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 1, -1)
    border.bottom:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.left = box:CreateTexture(nil, "BACKGROUND")
    border.left:SetWidth(1)
    border.left:SetPoint("TOPLEFT", border.top, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", border.bottom, "BOTTOMLEFT", 0, 0)
    border.left:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.right = box:CreateTexture(nil, "BACKGROUND")
    border.right:SetWidth(1)
    border.right:SetPoint("TOPRIGHT", border.top, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", border.bottom, "BOTTOMRIGHT", 0, 0)
    border.right:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    return border
end

local function ParseLevelSearch(text)
    minLevelSearch = nil
    maxLevelSearch = nil

    if text == "" then
        return true
    end

    if text == "??" then
        minLevelSearch = -1
        maxLevelSearch = -1
        return true
    end

    local min, max = text:match("^(%d+)-(%d+)$")
    if min and max then
        min = tonumber(min)
        max = tonumber(max)
        if min and max and min <= max and min >= 1 and max <= 60 then
            minLevelSearch = min
            maxLevelSearch = max
            return true
        end
        return false
    end

    local level = tonumber(text)
    if level and level >= 1 and level <= 60 then
        minLevelSearch = level
        maxLevelSearch = level
        return true
    end

    return false
end

local function ParseRankSearch(text)
    minRankSearch = nil
    maxRankSearch = nil

    if text == "" then
        return true
    end

    local min, max = text:match("^(%d+)-(%d+)$")
    if min and max then
        min = tonumber(min)
        max = tonumber(max)
        if min and max and min <= max and min >= 0 and max <= 14 then
            minRankSearch = min
            maxRankSearch = max
            return true
        end
        return false
    end

    local rank = tonumber(text)
    if rank and rank >= 0 and rank <= 14 then
        minRankSearch = rank
        maxRankSearch = rank
        return true
    end

    return false
end

local function CreateLevelSearchBox(parent, anchorTo)
    local levelSearchBox = CreateFrame("EditBox", nil, parent)
    levelSearchBox:SetSize(60, 20)
    levelSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 20, 0)
    levelSearchBox:SetAutoFocus(false)
    levelSearchBox:SetMaxLetters(5)
    levelSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = levelSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(levelSearchBox)
    levelSearchBox:SetTextInsets(5, 5, 2, 2)

    return levelSearchBox
end

local function SetupLevelSearchBoxScripts(levelSearchBox)
    levelSearchBox:SetScript("OnTextChanged", function(self)
        levelSearchText = self:GetText()
        if ParseLevelSearch(levelSearchText) then
            self:SetTextColor(1, 1, 1)
            RefreshKillsListFrame()
        else
            self:SetTextColor(1, 0.3, 0.3)
        end
    end)

    levelSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    levelSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    levelSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        levelSearchText = ""
        minLevelSearch = nil
        maxLevelSearch = nil
        RefreshKillsListFrame()
    end)

    levelSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    levelSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Level Filter")
        GameTooltip:AddLine("Enter a single level (e.g. 60)", 1, 1, 1, true)
        GameTooltip:AddLine("Or a range (e.g. 30-40)", 1, 1, 1, true)
        GameTooltip:AddLine("Or ?? for unknown levels", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    levelSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateLevelSearchLabel(parent, anchorTo)
    local levelLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("LEFT", anchorTo, "RIGHT", 8, 0)
    levelLabel:SetText("Level:")
    levelLabel:SetTextColor(1, 0.82, 0)
    return levelLabel
end

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
        if sortBy == columnId then
            sortAscending = not sortAscending
        else
            sortBy = columnId
            sortAscending = false
        end
        RefreshKillsListFrame()
    end)

    local header = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("LEFT", 3, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetWidth(width - 6)
    header:SetJustifyH("LEFT")

    header:SetText(text)

    if sortBy == columnId then
        local sortIndicator = sortAscending and " ^" or " v"
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

local function FilterAndSortEntries()
    local sortedEntries = {}
    local currentCharacterKey = PSC_GetCharacterKey()

    local charactersToProcess = GetCharactersToProcessForStatistics()

    for characterKey, characterData in pairs(charactersToProcess) do
        for nameWithLevel, data in pairs(characterData.Kills) do
            if data then
                local nameWithoutLevel = nameWithLevel:match("([^:]+)")

                local level = nameWithLevel:match(":(%S+)")
                local levelNum = tonumber(level or "0") or 0

                local playerInfo = PSC_DB.PlayerInfoCache[nameWithoutLevel] or {}
                local class = playerInfo.class
                local race = playerInfo.race
                local gender = playerInfo.gender
                local guild = playerInfo.guild
                local rank = playerInfo.rank

                local entry = {
                    name = nameWithoutLevel,
                    nameWithLevel = nameWithLevel,
                    class = class,
                    race = race,
                    gender = gender,
                    guild = guild,
                    zone = data.zone or "Unknown",
                    kills = data.kills or 1,
                    lastKill = data.lastKill or "",
                    levelNum = levelNum,
                    levelDisplay = levelNum,
                    rank = rank
                }

                if levelNum == -1 then
                    entry.levelDisplay = -1
                end

                local searchMatch = true
                local levelMatch = true
                local classMatch = true
                local raceMatch = true
                local genderMatch = true
                local zoneMatch = true
                local rankMatch = true

                if searchText ~= "" then
                    local nameLower = nameWithoutLevel:lower()
                    local guildLower = guild:lower()

                    ---@diagnostic disable-next-line: cast-local-type
                    searchMatch = nameLower:find(searchText, 1, true) or
                                      (guild ~= "" and guildLower:find(searchText, 1, true))
                end

                if minLevelSearch or maxLevelSearch then
                    if minLevelSearch == -1 and maxLevelSearch == -1 then
                        levelMatch = (levelNum == -1)
                    elseif minLevelSearch and maxLevelSearch then
                        levelMatch = (levelNum >= minLevelSearch and levelNum <= maxLevelSearch)
                    end
                end

                if classSearchText ~= "" then
                    ---@diagnostic disable-next-line: cast-local-type
                    classMatch = class:lower():find(classSearchText:lower(), 1, true)
                end

                if raceSearchText ~= "" then
                    ---@diagnostic disable-next-line: cast-local-type
                    raceMatch = race:lower():find(raceSearchText:lower(), 1, true)
                end

                if genderSearchText ~= "" then
                    local compareText = genderSearchText:lower()
                    local genderLower = gender:lower()

                    if compareText == "m" or compareText == "male" then
                        genderMatch = (genderLower == "male")
                    elseif compareText == "f" or compareText == "female" then
                        genderMatch = (genderLower == "female")
                    elseif compareText == "u" or compareText == "unknown" or compareText == "?" then
                        genderMatch = (genderLower == "unknown")
                    else
                        ---@diagnostic disable-next-line: cast-local-type
                        genderMatch = genderLower:find(compareText, 1, true)
                    end
                end

                if zoneSearchText ~= "" then
                    ---@diagnostic disable-next-line: cast-local-type
                    zoneMatch = (data.zone or "Unknown"):lower():find(zoneSearchText:lower(), 1, true)
                end

                if minRankSearch or maxRankSearch then
                    if minRankSearch and maxRankSearch then
                        rankMatch = (rank >= minRankSearch and rank <= maxRankSearch)
                    end
                end

                if searchMatch and levelMatch and classMatch and raceMatch and genderMatch and zoneMatch and rankMatch then
                    table.insert(sortedEntries, entry)
                end
            end
        end
    end

    table.sort(sortedEntries, function(a, b)
        if not a then
            return false
        end
        if not b then
            return true
        end
        if a == b then
            return false
        end

        if sortBy == "level" then
            if a.levelNum == -1 and b.levelNum ~= -1 then
                return not sortAscending
            elseif a.levelNum ~= -1 and b.levelNum == -1 then
                return sortAscending
            elseif a.levelNum == -1 and b.levelNum == -1 then
                if sortAscending then
                    return a.name < b.name
                else
                    return a.name > b.name
                end
            end
        end

        local aVal, bVal

        if sortBy == "name" then
            aVal, bVal = a.name or "", b.name or ""
        elseif sortBy == "class" then
            aVal, bVal = a.class or "Unknown", b.class or "Unknown"
        elseif sortBy == "race" then
            aVal, bVal = a.race or "Unknown", b.race or "Unknown"
        elseif sortBy == "gender" then
            aVal, bVal = a.gender or "Unknown", b.gender or "Unknown"
        elseif sortBy == "rank" then
            aVal, bVal = tonumber(a.rank or 0), tonumber(b.rank or 0)
        elseif sortBy == "guild" then
            aVal, bVal = a.guild or "", b.guild or ""
        elseif sortBy == "zone" then
            aVal, bVal = a.zone or "Unknown", b.zone or "Unknown"
        elseif sortBy == "kills" then
            aVal, bVal = tonumber(a.kills or 0), tonumber(b.kills or 0)
        elseif sortBy == "lastKill" then
            aVal, bVal = a.lastKill or "", b.lastKill or ""
        elseif sortBy == "level" then
            aVal, bVal = tonumber(a.levelNum or 0), tonumber(b.levelNum or 0)
        else
            aVal, bVal = a.name or "", b.name or ""
        end

        if aVal == nil then
            aVal = ""
        end
        if bVal == nil then
            bVal = ""
        end

        if type(aVal) == "number" and type(bVal) == "number" then
            if aVal == bVal then
                if sortAscending then
                    return a.name < b.name
                else
                    return a.name > b.name
                end
            else
                if sortAscending then
                    return aVal < bVal
                else
                    return aVal > bVal
                end
            end
        else
            if aVal == bVal then
                if sortAscending then
                    return a.name < b.name
                else
                    return a.name > b.name
                end
            else
                if sortAscending then
                    return aVal < bVal
                else
                    return aVal > bVal
                end
            end
        end
    end)

    return sortedEntries
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

local function FormatLastKillDate(dateString)
    if not dateString or dateString == "" then
        return ""
    end

    local year, month, day, hour, min, sec = dateString:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")

    if not year then
        return dateString
    end

    local shortYear = year:sub(-2)
    return string.format("%02d/%02d/%02s %02d:%02d:%02d", tonumber(day), tonumber(month), shortYear, tonumber(hour),
        tonumber(min), tonumber(sec))
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
        moreText:SetPoint("TOPLEFT", 10, yOffset)
        moreText:SetText("Showing " .. count .. " of " .. #sortedEntries .. " entries. Use search to narrow results.")
        moreText:SetTextColor(1, 0.7, 0)
        yOffset = yOffset - 20
    end

    return yOffset, count
end

local function CreateSearchBackground(parent)
    local searchBg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    searchBg:SetPoint("BOTTOMLEFT", 1, 1)
    searchBg:SetPoint("BOTTOMRIGHT", -1, 1)
    searchBg:SetHeight(40)

    if searchBg.SetBackdrop then
        searchBg:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = {
                left = 4,
                right = 4,
                top = 4,
                bottom = 4
            }
        })
        searchBg:SetBackdropColor(0, 0, 0, 0.4)
    else
        local bg = searchBg:CreateTexture(nil, "BACKGROUND")
        ---@diagnostic disable-next-line: param-type-mismatch
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.4)
    end

    return searchBg
end

local function CreateSearchLabel(parent)
    local searchLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", parent, "LEFT", 8, 0)
    searchLabel:SetText("Search Player/Guild:")
    searchLabel:SetTextColor(1, 0.82, 0)
    return searchLabel
end

local function CreateEditBox(parent, anchorTo)
    local searchBox = CreateFrame("EditBox", nil, parent)
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("LEFT", anchorTo, "RIGHT", 8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = searchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(searchBox)

    searchBox:SetTextInsets(5, 5, 2, 2)

    return searchBox
end

local function SetupSearchBoxScripts(searchBox)
    searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText():lower()
        RefreshKillsListFrame()
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        searchText = ""
        RefreshKillsListFrame()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Search")
        GameTooltip:AddLine("Type to filter by player name or guild name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear search", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    searchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateClassSearchBox(parent, anchorTo)
    local classSearchBox = CreateFrame("EditBox", nil, parent)
    classSearchBox:SetSize(60, 20)
    classSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    classSearchBox:SetAutoFocus(false)
    classSearchBox:SetMaxLetters(10)
    classSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = classSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(classSearchBox)
    classSearchBox:SetTextInsets(5, 5, 2, 2)

    return classSearchBox
end

local function SetupClassSearchBoxScripts(classSearchBox)
    classSearchBox:SetScript("OnTextChanged", function(self)
        classSearchText = self:GetText()
        RefreshKillsListFrame()
    end)

    classSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    classSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    classSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        classSearchText = ""
        RefreshKillsListFrame()
    end)

    classSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    classSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Class Filter")
        GameTooltip:AddLine("Enter a class name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    classSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateRaceSearchBox(parent, anchorTo)
    local raceSearchBox = CreateFrame("EditBox", nil, parent)
    raceSearchBox:SetSize(60, 20)
    raceSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    raceSearchBox:SetAutoFocus(false)
    raceSearchBox:SetMaxLetters(10)
    raceSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = raceSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(raceSearchBox)
    raceSearchBox:SetTextInsets(5, 5, 2, 2)

    return raceSearchBox
end

local function SetupRaceSearchBoxScripts(raceSearchBox)
    raceSearchBox:SetScript("OnTextChanged", function(self)
        raceSearchText = self:GetText()
        RefreshKillsListFrame()
    end)

    raceSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    raceSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    raceSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        raceSearchText = ""
        RefreshKillsListFrame()
    end)

    raceSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    raceSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Race Filter")
        GameTooltip:AddLine("Enter a race name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    raceSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateRaceSearchLabel(parent, anchorTo)
    local raceLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raceLabel:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    raceLabel:SetText("Race:")
    raceLabel:SetTextColor(1, 0.82, 0)
    return raceLabel
end

local function CreateGenderSearchBox(parent, anchorTo)
    local genderSearchBox = CreateFrame("EditBox", nil, parent)
    genderSearchBox:SetSize(60, 20)
    genderSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    genderSearchBox:SetAutoFocus(false)
    genderSearchBox:SetMaxLetters(6)
    genderSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = genderSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(genderSearchBox)
    genderSearchBox:SetTextInsets(5, 5, 2, 2)

    return genderSearchBox
end

local function SetupGenderSearchBoxScripts(genderSearchBox)
    genderSearchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        genderSearchText = text

        local normalizedText = text:lower():gsub("^%s*(.-)%s*$", "%1")
        if normalizedText == "m" then
        elseif normalizedText == "f" then
        end

        RefreshKillsListFrame()
    end)

    genderSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    genderSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)

        local text = self:GetText():lower():gsub("^%s*(.-)%s*$", "%1")
        if text == "m" or text == "male" then
            self:SetText("Male")
            genderSearchText = "Male"
            RefreshKillsListFrame()
        elseif text == "f" or text == "female" then
            self:SetText("Female")
            genderSearchText = "Female"
            RefreshKillsListFrame()
        elseif text == "u" or text == "unknown" or text == "?" or text == "??" then
            self:SetText("Unknown")
            genderSearchText = "Unknown"
            RefreshKillsListFrame()
        elseif text == "" then
            genderSearchText = ""
            RefreshKillsListFrame()
        else
            local lowerText = text:lower()
            if lowerText:find("^ma") or lowerText:find("^me") then
                self:SetText("Male")
                genderSearchText = "Male"
                RefreshKillsListFrame()
            elseif lowerText:find("^fe") or lowerText:find("^wo") then
                self:SetText("Female")
                genderSearchText = "Female"
                RefreshKillsListFrame()
            elseif lowerText:find("^un") then
                self:SetText("Unknown")
                genderSearchText = "Unknown"
                RefreshKillsListFrame()
            else
                self:SetText("")
                genderSearchText = ""
                RefreshKillsListFrame()
            end
        end
    end)

    genderSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        genderSearchText = ""
        RefreshKillsListFrame()
    end)

    genderSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    genderSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Gender Filter")
        GameTooltip:AddLine("Type Male, Female, or Unknown", 1, 1, 1, true)
        GameTooltip:AddLine("Short forms: m, f, u are also accepted", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    genderSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateGenderSearchLabel(parent, anchorTo)
    local genderLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genderLabel:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    genderLabel:SetText("Gender:")
    genderLabel:SetTextColor(1, 0.82, 0)
    return genderLabel
end

local function CreateZoneSearchBox(parent, anchorTo)
    local zoneSearchBox = CreateFrame("EditBox", nil, parent)
    zoneSearchBox:SetSize(130, 20)
    zoneSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    zoneSearchBox:SetAutoFocus(false)
    zoneSearchBox:SetMaxLetters(25)
    zoneSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = zoneSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(zoneSearchBox)
    zoneSearchBox:SetTextInsets(5, 5, 2, 2)

    return zoneSearchBox
end

local function SetupZoneSearchBoxScripts(zoneSearchBox)
    zoneSearchBox:SetScript("OnTextChanged", function(self)
        zoneSearchText = self:GetText()
        RefreshKillsListFrame()
    end)

    zoneSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    zoneSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    zoneSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        zoneSearchText = ""
        RefreshKillsListFrame()
    end)

    zoneSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    zoneSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Zone Filter")
        GameTooltip:AddLine("Enter a zone name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    zoneSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateZoneSearchLabel(parent, anchorTo)
    local zoneLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    zoneLabel:SetText("Zone:")
    zoneLabel:SetTextColor(1, 0.82, 0)
    return zoneLabel
end

local function CreateRankSearchBox(parent, anchorTo)
    local rankSearchBox = CreateFrame("EditBox", nil, parent)
    rankSearchBox:SetSize(50, 20)
    rankSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    rankSearchBox:SetAutoFocus(false)
    rankSearchBox:SetMaxLetters(5)
    rankSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = rankSearchBox:CreateTexture(nil, "BACKGROUND")
    ---@diagnostic disable-next-line: param-type-mismatch
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(rankSearchBox)
    rankSearchBox:SetTextInsets(5, 5, 2, 2)

    return rankSearchBox
end

local function SetupRankSearchBoxScripts(rankSearchBox)
    rankSearchBox:SetScript("OnTextChanged", function(self)
        rankSearchText = self:GetText()
        if ParseRankSearch(rankSearchText) then
            self:SetTextColor(1, 1, 1)
            RefreshKillsListFrame()
        else
            self:SetTextColor(1, 0.3, 0.3)
        end
    end)

    rankSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    rankSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    rankSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        rankSearchText = ""
        minRankSearch = nil
        maxRankSearch = nil
        RefreshKillsListFrame()
    end)

    rankSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    rankSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Rank Filter")
        GameTooltip:AddLine("Enter a single rank (e.g. 8)", 1, 1, 1, true)
        GameTooltip:AddLine("Or a range (e.g. 5-10)", 1, 1, 1, true)
        GameTooltip:AddLine("Valid ranks: 0-14", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    rankSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function CreateRankSearchLabel(parent, anchorTo)
    local rankLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankLabel:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    rankLabel:SetText("Rank:")
    rankLabel:SetTextColor(1, 0.82, 0)
    return rankLabel
end

local function CreateSearchBar(frame)
    local searchBg = CreateSearchBackground(frame)

    searchBg:SetHeight(40)

    local row1 = CreateFrame("Frame", nil, searchBg)
    row1:SetSize(searchBg:GetWidth(), 20)
    row1:SetPoint("TOP", searchBg, "TOP", 0, -10)

    local searchLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", row1, "LEFT", 10, 0)
    searchLabel:SetText("Player/Guild:")
    searchLabel:SetTextColor(1, 0.82, 0)

    local searchBox = CreateEditBox(searchBg, searchLabel)
    searchBox:SetSize(120, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    SetupSearchBoxScripts(searchBox)
    searchBox:SetText("")
    searchText = ""

    local classLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("LEFT", searchBox, "RIGHT", 15, 0)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(1, 0.82, 0)

    local classSearchBox = CreateClassSearchBox(searchBg, classLabel)
    classSearchBox:SetSize(80, 20)
    classSearchBox:SetPoint("LEFT", classLabel, "RIGHT", 5, 0)
    SetupClassSearchBoxScripts(classSearchBox)
    classSearchBox:SetText("")
    classSearchText = ""

    local raceLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raceLabel:SetPoint("LEFT", classSearchBox, "RIGHT", 15, 0)
    raceLabel:SetText("Race:")
    raceLabel:SetTextColor(1, 0.82, 0)

    local raceSearchBox = CreateRaceSearchBox(searchBg, raceLabel)
    raceSearchBox:SetSize(80, 20)
    raceSearchBox:SetPoint("LEFT", raceLabel, "RIGHT", 5, 0)
    SetupRaceSearchBoxScripts(raceSearchBox)
    raceSearchBox:SetText("")
    raceSearchText = ""

    local genderLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genderLabel:SetPoint("LEFT", raceSearchBox, "RIGHT", 15, 0)
    genderLabel:SetText("Gender:")
    genderLabel:SetTextColor(1, 0.82, 0)

    local genderSearchBox = CreateGenderSearchBox(searchBg, genderLabel)
    genderSearchBox:SetSize(55, 20)
    genderSearchBox:SetPoint("LEFT", genderLabel, "RIGHT", 5, 0)
    SetupGenderSearchBoxScripts(genderSearchBox)
    genderSearchBox:SetText("")
    genderSearchText = ""

    local levelLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("LEFT", genderSearchBox, "RIGHT", 15, 0)
    levelLabel:SetText("Level:")
    levelLabel:SetTextColor(1, 0.82, 0)

    local levelSearchBox = CreateLevelSearchBox(searchBg, levelLabel)
    levelSearchBox:SetSize(50, 20)
    levelSearchBox:SetPoint("LEFT", levelLabel, "RIGHT", 5, 0)
    SetupLevelSearchBoxScripts(levelSearchBox)
    levelSearchBox:SetText("")
    levelSearchText = ""

    local rankLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankLabel:SetPoint("LEFT", levelSearchBox, "RIGHT", 15, 0)
    rankLabel:SetText("Rank:")
    rankLabel:SetTextColor(1, 0.82, 0)

    local rankSearchBox = CreateRankSearchBox(searchBg, rankLabel)
    rankSearchBox:SetSize(50, 20)
    rankSearchBox:SetPoint("LEFT", rankLabel, "RIGHT", 5, 0)
    SetupRankSearchBoxScripts(rankSearchBox)
    rankSearchBox:SetText("")
    rankSearchText = ""

    local zoneLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("LEFT", rankSearchBox, "RIGHT", 15, 0)
    zoneLabel:SetText("Zone:")
    zoneLabel:SetTextColor(1, 0.82, 0)

    local zoneSearchBox = CreateZoneSearchBox(searchBg, zoneLabel)
    zoneSearchBox:SetSize(130, 20)
    zoneSearchBox:SetPoint("LEFT", zoneLabel, "RIGHT", 5, 0)
    SetupZoneSearchBoxScripts(zoneSearchBox)
    zoneSearchBox:SetText("")
    zoneSearchText = ""

    frame.searchBox = searchBox
    frame.levelSearchBox = levelSearchBox
    frame.classSearchBox = classSearchBox
    frame.raceSearchBox = raceSearchBox
    frame.genderSearchBox = genderSearchBox
    frame.zoneSearchBox = zoneSearchBox
    frame.rankSearchBox = rankSearchBox

    return searchBox
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(PSC_KILLS_FRAME_WIDTH - 40, PSC_KILLS_FRAME_HEIGHT * 2)
    scrollFrame:SetScrollChild(content)

    return content
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PSC_KillStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(PSC_KILLS_FRAME_WIDTH, PSC_KILLS_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    table.insert(UISpecialFrames, "PSC_KillStatsFrame")
    local titleText = GetFrameTitleTextWithCharacterText("Player Kills List")
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

    local titleText = GetFrameTitleTextWithCharacterText("Player Kills List")
    PSC_KillsListFrame.TitleText:SetText(titleText)

    CleanupFrameElements(content)
    collectgarbage("collect")

    local yOffset = CreateColumnHeaders(content)
    local sortedEntries = FilterAndSortEntries()
    local finalYOffset, entryCount = DisplayEntries(content, sortedEntries, yOffset)

    content:SetHeight(math.max((-finalYOffset + 20), PSC_KILLS_FRAME_HEIGHT - 50))
end

function PSC_CreateKillStatsFrame()
    if (PSC_KillsListFrame) then
        PSC_FrameManager:ShowFrame("KillsList")
        RefreshKillsListFrame()
        return
    end

    PSC_KillsListFrame = CreateMainFrame()
    PSC_KillsListFrame.content = CreateScrollFrame(PSC_KillsListFrame)
    CreateSearchBar(PSC_KillsListFrame)

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

function PSC_SetKillListSearch(text, levelText, classText, raceText, genderText, zoneText, resetOtherFilters)
    if PSC_KillsListFrame then
        if resetOtherFilters then
            PSC_KillsListFrame.searchBox:SetText("")
            searchText = ""
            PSC_KillsListFrame.levelSearchBox:SetText("")
            levelSearchText = ""
            PSC_KillsListFrame.classSearchBox:SetText("")
            classSearchText = ""
            PSC_KillsListFrame.raceSearchBox:SetText("")
            raceSearchText = ""
            PSC_KillsListFrame.genderSearchBox:SetText("")
            genderSearchText = ""
            PSC_KillsListFrame.zoneSearchBox:SetText("")
            zoneSearchText = ""
            minLevelSearch = nil
            maxLevelSearch = nil
        end

        if PSC_KillsListFrame.searchBox and text then
            PSC_KillsListFrame.searchBox:SetText(text)
            searchText = text:lower()
        end

        if PSC_KillsListFrame.levelSearchBox and levelText then
            PSC_KillsListFrame.levelSearchBox:SetText(levelText)
            levelSearchText = levelText
            ParseLevelSearch(levelText)
        end

        if PSC_KillsListFrame.classSearchBox and classText then
            PSC_KillsListFrame.classSearchBox:SetText(classText)
            classSearchText = classText
        end

        if PSC_KillsListFrame.raceSearchBox and raceText then
            PSC_KillsListFrame.raceSearchBox:SetText(raceText)
            raceSearchText = raceText
        end

        if PSC_KillsListFrame.genderSearchBox and genderText then
            PSC_KillsListFrame.genderSearchBox:SetText(genderText)
            genderSearchText = genderText
        end

        if PSC_KillsListFrame.zoneSearchBox and zoneText then
            PSC_KillsListFrame.zoneSearchBox:SetText(zoneText)
            zoneSearchText = zoneText
        end

        RefreshKillsListFrame()
    end
end

function PSC_SetKillListLevelRange(minLevel, maxLevel, resetOtherFilters)
    if PSC_KillsListFrame then
        if resetOtherFilters then
            PSC_KillsListFrame.searchBox:SetText("")
            searchText = ""
            PSC_KillsListFrame.classSearchBox:SetText("")
            classSearchText = ""
            PSC_KillsListFrame.raceSearchBox:SetText("")
            raceSearchText = ""
            PSC_KillsListFrame.genderSearchBox:SetText("")
            genderSearchText = ""
            PSC_KillsListFrame.zoneSearchBox:SetText("")
            zoneSearchText = ""
        end

        minLevelSearch = minLevel
        maxLevelSearch = maxLevel

        if PSC_KillsListFrame.levelSearchBox then
            if minLevel == -1 and maxLevel == -1 then
                PSC_KillsListFrame.levelSearchBox:SetText("??")
                levelSearchText = "??"
            elseif minLevel and maxLevel and minLevel == maxLevel then
                PSC_KillsListFrame.levelSearchBox:SetText(tostring(minLevel))
                levelSearchText = tostring(minLevel)
            elseif minLevel and maxLevel then
                local rangeText = minLevel .. "-" .. maxLevel
                PSC_KillsListFrame.levelSearchBox:SetText(rangeText)
                levelSearchText = rangeText
            else
                PSC_KillsListFrame.levelSearchBox:SetText("")
                levelSearchText = ""
                minLevelSearch = nil
                maxLevelSearch = nil
            end
        end

        if PSC_KillsListFrame.levelSearchBox then
            PSC_KillsListFrame.levelSearchBox:SetTextColor(1, 1, 1)
        end

        RefreshKillsListFrame()

        PSC_FrameManager:BringToFront("KillsList")
    end
end

function PSC_SetKillListRankRange(minRank, maxRank, resetOtherFilters)
    if PSC_KillsListFrame then
        if resetOtherFilters then
            PSC_KillsListFrame.searchBox:SetText("")
            searchText = ""
            PSC_KillsListFrame.levelSearchBox:SetText("")
            levelSearchText = ""
            minLevelSearch = nil
            maxLevelSearch = nil
            PSC_KillsListFrame.classSearchBox:SetText("")
            classSearchText = ""
            PSC_KillsListFrame.raceSearchBox:SetText("")
            raceSearchText = ""
            PSC_KillsListFrame.genderSearchBox:SetText("")
            genderSearchText = ""
            PSC_KillsListFrame.zoneSearchBox:SetText("")
            zoneSearchText = ""
        end

        minRankSearch = minRank
        maxRankSearch = maxRank

        if PSC_KillsListFrame.rankSearchBox then
            if minRank and maxRank and minRank == maxRank then
                PSC_KillsListFrame.rankSearchBox:SetText(tostring(minRank))
                rankSearchText = tostring(minRank)
            elseif minRank and maxRank then
                local rangeText = minRank .. "-" .. maxRank
                PSC_KillsListFrame.rankSearchBox:SetText(rangeText)
                rankSearchText = rangeText
            else
                PSC_KillsListFrame.rankSearchBox:SetText("")
                rankSearchText = ""
                minRankSearch = nil
                maxRankSearch = nil
            end
        end

        if PSC_KillsListFrame.rankSearchBox then
            PSC_KillsListFrame.rankSearchBox:SetTextColor(1, 1, 1)
        end

        RefreshKillsListFrame()

        PSC_FrameManager:BringToFront("KillsList")
    end
end
