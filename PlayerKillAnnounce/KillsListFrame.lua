if not PKA_ActiveFrameLevel then
    PKA_ActiveFrameLevel = 100
end

-- Get next frame level and increment the counter
local function PKA_GetNextFrameLevel()
    PKA_ActiveFrameLevel = PKA_ActiveFrameLevel + 10
    return PKA_ActiveFrameLevel
end

local killStatsFrame = nil
local searchText = ""
local levelSearchText = ""
local classSearchText = ""  -- New filter variable for class
local raceSearchText = ""   -- New filter variable for race
local genderSearchText = "" -- New filter variable for gender
local zoneSearchText = "" -- New filter variable for zone
local minLevelSearch = nil
local maxLevelSearch = nil
local sortBy = "lastKill"
local sortAscending = false

local PKA_KILLS_FRAME_WIDTH = 950  -- Increased from 900
local PKA_KILLS_FRAME_HEIGHT = 550  -- Increased from 500

local colWidths = {
    name = 100,
    class = 70,
    race = 70,
    gender = 80,   -- Increased from 70
    level = 70,    -- Increased from 50
    guild = 150,   -- Unchanged
    zone = 170,    -- Unchanged
    kills = 60,    -- Increased from 50
    lastKill = 130 -- Unchanged
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
    -- Reset level search variables
    minLevelSearch = nil
    maxLevelSearch = nil

    if text == "" then
        return true
    end

    -- Check for level range format: "min-max"
    local min, max = text:match("^(%d+)-(%d+)$")
    if min and max then
        min = tonumber(min)
        max = tonumber(max)
        -- Ensure min is less than or equal to max
        if min and max and min <= max and min >= 1 and max <= 60 then
            minLevelSearch = min
            maxLevelSearch = max
            return true
        end
        return false
    end

    -- Check for single level format
    local level = tonumber(text)
    if level and level >= 1 and level <= 60 then
        minLevelSearch = level
        return true
    end

    return false
end

local function CreateLevelSearchBox(parent, anchorTo)
    local levelSearchBox = CreateFrame("EditBox", nil, parent)
    levelSearchBox:SetSize(60, 20)
    levelSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 20, 0)
    levelSearchBox:SetAutoFocus(false)
    levelSearchBox:SetMaxLetters(5)  -- Max input like "60-60"
    levelSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = levelSearchBox:CreateTexture(nil, "BACKGROUND")
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
            RefreshKillList()
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
        RefreshKillList()
    end)

    -- Enter key handling
    levelSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Tooltip handling
    levelSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Level Filter")
        GameTooltip:AddLine("Enter a single level (e.g. 60)", 1, 1, 1, true)
        GameTooltip:AddLine("Or a range (e.g. 30-40)", 1, 1, 1, true)
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

    -- Create a background texture
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)

    button:SetScript("OnClick", function()
        if sortBy == columnId then
            sortAscending = not sortAscending
        else
            sortBy = columnId
            -- Set default sort direction based on column type
            if columnId == "level" or columnId == "kills" then
                sortAscending = false
            else
                sortAscending = true
            end
        end
        RefreshKillList()
    end)

    -- Create the header text first without the sort indicator
    local header = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("LEFT", 3, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetWidth(width - 6)
    header:SetJustifyH("LEFT")

    -- Set the base text first
    header:SetText(text)

    -- Add sort indicator separately if this is the sorted column
    if sortBy == columnId then
        local sortIndicator = sortAscending and " ^" or " v"
        header:SetText(text .. sortIndicator)
    end

    button:SetFontString(header)

    button:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    button:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    return button
end

local function FilterAndSortEntries()
    local sortedEntries = {}
    local count = 0
    local maxEntries = 100000

    for nameWithLevel, data in pairs(PKA_KillCounts) do
        if count >= maxEntries then break end

        local name, level = strsplit(":", nameWithLevel)
        local levelNum = tonumber(level) or 0
        local nameLower = name:lower()
        local guildLower = (data.guild or ""):lower()
        local className = (data.class or "Unknown"):lower()
        local raceName = (data.race or "Unknown"):lower()
        local genderName = (data.gender or "Unknown"):lower()
        local zoneName = (data.zone or "Unknown"):lower()

        -- Check if the entry matches all search criteria
        local matchesNameGuild = (searchText == "" or
                                nameLower:find(searchText, 1, true) or
                                guildLower:find(searchText, 1, true))

        -- Check level criteria
        local matchesLevel = true
        if levelSearchText ~= "" then
            if minLevelSearch and maxLevelSearch then
                matchesLevel = (levelNum >= minLevelSearch and levelNum <= maxLevelSearch)
            elseif minLevelSearch then
                matchesLevel = (levelNum == minLevelSearch)
            end
        end

        -- Check class criteria
        local matchesClass = true
        if classSearchText ~= "" then
            matchesClass = className:find(classSearchText:lower(), 1, true)
        end

        -- Check race criteria
        local matchesRace = true
        if raceSearchText ~= "" then
            matchesRace = raceName:find(raceSearchText:lower(), 1, true)
        end

        -- Check gender criteria
        local matchesGender = true
        if genderSearchText ~= "" then
            -- Handle gender matching more precisely
            local searchGender = genderSearchText:lower()
            if searchGender == "male" then
                matchesGender = (genderName == "male")
            elseif searchGender == "female" then
                matchesGender = (genderName == "female")
            else
                -- For partial searches that aren't exact "male" or "female"
                matchesGender = genderName:find(searchGender, 1, true)
            end
        end

        -- Check zone criteria
        local matchesZone = true
        if zoneSearchText ~= "" then
            matchesZone = zoneName:find(zoneSearchText:lower(), 1, true)
        end

        -- Add to results only if all criteria are matched
        if matchesNameGuild and matchesLevel and matchesClass and
           matchesRace and matchesGender and matchesZone then
            count = count + 1
            sortedEntries[count] = {
                nameWithLevel = nameWithLevel,
                name = name,
                class = data.class or "Unknown",
                race = data.race or "Unknown",
                gender = data.gender or "Unknown",
                level = levelNum,
                guild = data.guild or "",
                zone = data.zone or "Unknown",
                kills = data.kills or 0,
                lastKill = data.lastKill or "Unknown",
                unknownLevel = data.unknownLevel or (levelNum == -1)
            }
        end
    end

    if count > 0 then
        local stableCompare = function(a, b)
            if a == b then return false end
            if not a then return false end
            if not b then return true end

            -- Special handling for level column
            if sortBy == "level" then
                -- Handle unknown levels (displayed as ??)
                if a.level == -1 and b.level ~= -1 then
                    return not sortAscending  -- Unknown levels at bottom when ascending, top when descending
                elseif a.level ~= -1 and b.level == -1 then
                    return sortAscending     -- Known levels above unknown when ascending
                end

                -- Normal level comparison
                if a.level ~= b.level then
                    if sortAscending then
                        return a.level < b.level  -- Ascending: 1, 2, 3...
                    else
                        return a.level > b.level  -- Descending: 60, 59, 58...
                    end
                end

                -- If levels are equal, sort by name as secondary key
                return a.name:lower() < b.name:lower()
            end

            -- For other columns
            local aValue = a[sortBy]
            local bValue = b[sortBy]

            -- Equal values are sorted by name
            if aValue == bValue or (not aValue and not bValue) then
                return a.name:lower() < b.name:lower()
            end

            -- Handle nil values
            if not aValue then return false end
            if not bValue then return true end

            -- String or number comparison based on value type
            if type(aValue) == "string" and type(bValue) == "string" then
                if sortAscending then
                    return aValue:lower() < bValue:lower()  -- A to Z
                else
                    return aValue:lower() > bValue:lower()  -- Z to A
                end
            else
                if sortAscending then
                    return aValue < bValue  -- Low to high
                else
                    return aValue > bValue  -- High to low
                end
            end
        end

        pcall(function() table.sort(sortedEntries, stableCompare) end)
    end

    if count == maxEntries then
        print("|cFFFFFF00PlayerKillAnnounce: Displaying first " .. maxEntries .. " kills (use search to filter)|r")
    end

    return sortedEntries
end

local function CreateColumnHeaders(content)
    local nameButton = CreateColumnHeader(content, "Name", colWidths.name, nil, 10, 0, "name")
    local classButton = CreateColumnHeader(content, "Class", colWidths.class, nameButton, 0, 0, "class")
    local raceButton = CreateColumnHeader(content, "Race", colWidths.race, classButton, 0, 0, "race")
    local genderButton = CreateColumnHeader(content, "Gender", colWidths.gender, raceButton, 0, 0, "gender")
    local levelButton = CreateColumnHeader(content, "Level", colWidths.level, genderButton, 0, 0, "level")
    local guildButton = CreateColumnHeader(content, "Guild", colWidths.guild, levelButton, 0, 0, "guild")
    local zoneButton = CreateColumnHeader(content, "Zone", colWidths.zone, guildButton, 0, 0, "zone")
    local killsButton = CreateColumnHeader(content, "Kills", colWidths.kills, zoneButton, 0, 0, "kills")
    local lastKillButton = CreateColumnHeader(content, "Last Killed", colWidths.lastKill, killsButton, 0, 0, "lastKill")

    -- Set the position for the start of the entries
    return -30
end

local function CreateNameCell(content, xPos, yPos, name, width)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("TOPLEFT", xPos, yPos)
    nameText:SetText(name)
    nameText:SetWidth(width)
    nameText:SetJustifyH("LEFT")
    return nameText
end

local function CreateClassCell(content, anchorTo, className, width)
    local classText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    classText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

    if className and className ~= "Unknown" then
        className = className:sub(1, 1):upper() .. className:sub(2):lower()
    end

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
    raceText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)

    if raceName and raceName ~= "Unknown" then
        raceName = raceName:sub(1, 1):upper() .. raceName:sub(2):lower()
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

    -- Show ?? for unknown level
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

local function CreateLastKillCell(content, anchorTo, lastKill, width)
    local lastKillText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastKillText:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 0, 0)
    lastKillText:SetText(lastKill)
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

local function CreateEntryRow(content, entry, yOffset, colWidths)
    local nameCell = CreateNameCell(content, 10, yOffset, entry.name, colWidths.name)
    local classCell = CreateClassCell(content, nameCell, entry.class, colWidths.class)
    local raceCell = CreateRaceCell(content, classCell, entry.race, colWidths.race)
    local genderCell = CreateGenderCell(content, raceCell, entry.gender, colWidths.gender)
    local levelCell = CreateLevelCell(content, genderCell, entry.level, colWidths.level)
    local guildCell = CreateGuildCell(content, levelCell, entry.guild, colWidths.guild)
    local zoneCell = CreateZoneCell(content, guildCell, entry.zone, colWidths.zone)
    local killsCell = CreateKillsCell(content, zoneCell, entry.kills, colWidths.kills)
    local lastKillCell = CreateLastKillCell(content, killsCell, entry.lastKill, colWidths.lastKill)

    return yOffset - 16 -- Return the next row position
end

local function DisplayEntries(content, sortedEntries, startYOffset)
    local yOffset = startYOffset
    local count = 0
    local maxDisplayEntries = 500

    for i, entry in ipairs(sortedEntries) do
        if count >= maxDisplayEntries then break end
        yOffset = CreateEntryRow(content, entry, yOffset, colWidths)
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
    searchBg:SetHeight(40) -- Increased height

    if searchBg.SetBackdrop then
        searchBg:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        searchBg:SetBackdropColor(0, 0, 0, 0.4)
    else
        local bg = searchBg:CreateTexture(nil, "BACKGROUND")
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
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(searchBox)

    searchBox:SetTextInsets(5, 5, 2, 2)

    return searchBox
end

local function SetupSearchBoxScripts(searchBox)
    searchBox:SetScript("OnTextChanged", function(self)
        searchText = self:GetText():lower()
        RefreshKillList()
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
        RefreshKillList()
    end)

    -- Enter key handling
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Tooltip handling
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
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(classSearchBox)
    classSearchBox:SetTextInsets(5, 5, 2, 2)

    return classSearchBox
end

local function SetupClassSearchBoxScripts(classSearchBox)
    classSearchBox:SetScript("OnTextChanged", function(self)
        classSearchText = self:GetText()
        RefreshKillList()
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
        RefreshKillList()
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

local function CreateClassSearchLabel(parent, anchorTo)
    local classLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(1, 0.82, 0)
    return classLabel
end

local function CreateRaceSearchBox(parent, anchorTo)
    local raceSearchBox = CreateFrame("EditBox", nil, parent)
    raceSearchBox:SetSize(60, 20)
    raceSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    raceSearchBox:SetAutoFocus(false)
    raceSearchBox:SetMaxLetters(10)
    raceSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = raceSearchBox:CreateTexture(nil, "BACKGROUND")
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(raceSearchBox)
    raceSearchBox:SetTextInsets(5, 5, 2, 2)

    return raceSearchBox
end

local function SetupRaceSearchBoxScripts(raceSearchBox)
    raceSearchBox:SetScript("OnTextChanged", function(self)
        raceSearchText = self:GetText()
        RefreshKillList()
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
        RefreshKillList()
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
    genderSearchBox:SetMaxLetters(6)  -- "Female" is 6 chars
    genderSearchBox:SetFontObject("ChatFontNormal")

    local searchBoxBg = genderSearchBox:CreateTexture(nil, "BACKGROUND")
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(genderSearchBox)
    genderSearchBox:SetTextInsets(5, 5, 2, 2)

    return genderSearchBox
end

local function SetupGenderSearchBoxScripts(genderSearchBox)
    genderSearchBox:SetScript("OnTextChanged", function(self)
        genderSearchText = self:GetText()
        RefreshKillList()
    end)

    genderSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    genderSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
    end)

    genderSearchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        genderSearchText = ""
        RefreshKillList()
    end)

    genderSearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    genderSearchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Gender Filter")
        GameTooltip:AddLine("Enter Male or Female", 1, 1, 1, true)
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
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    CreateBoxBorder(zoneSearchBox)
    zoneSearchBox:SetTextInsets(5, 5, 2, 2)

    return zoneSearchBox
end

local function SetupZoneSearchBoxScripts(zoneSearchBox)
    zoneSearchBox:SetScript("OnTextChanged", function(self)
        zoneSearchText = self:GetText()
        RefreshKillList()
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
        RefreshKillList()
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



local function CreateSearchBar(frame)
    local searchBg = CreateSearchBackground(frame)

    -- Make the background taller to accommodate the search fields
    searchBg:SetHeight(40)

    -- Create a container for the first row of search fields
    local row1 = CreateFrame("Frame", nil, searchBg)
    row1:SetSize(searchBg:GetWidth(), 20)
    row1:SetPoint("TOP", searchBg, "TOP", 0, -10)

    -- Player/Guild search
    local searchLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", row1, "LEFT", 10, 0)
    searchLabel:SetText("Player/Guild:")
    searchLabel:SetTextColor(1, 0.82, 0)

    local searchBox = CreateEditBox(searchBg, searchLabel)
    searchBox:SetSize(120, 20) -- Smaller to fit all elements
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    SetupSearchBoxScripts(searchBox)
    searchBox:SetText("")
    searchText = ""

    -- Level search
    local levelLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("LEFT", searchBox, "RIGHT", 15, 0)
    levelLabel:SetText("Level:")
    levelLabel:SetTextColor(1, 0.82, 0)

    local levelSearchBox = CreateLevelSearchBox(searchBg, levelLabel)
    levelSearchBox:SetSize(50, 20)
    levelSearchBox:SetPoint("LEFT", levelLabel, "RIGHT", 5, 0)
    SetupLevelSearchBoxScripts(levelSearchBox)
    levelSearchBox:SetText("")
    levelSearchText = ""

    -- Class search
    local classLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("LEFT", levelSearchBox, "RIGHT", 15, 0)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(1, 0.82, 0)

    -- Create the search fields with adjusted widths
    local classSearchBox = CreateClassSearchBox(searchBg, classLabel)
    classSearchBox:SetSize(80, 20)  -- Increased from 60
    classSearchBox:SetPoint("LEFT", classLabel, "RIGHT", 5, 0)
    SetupClassSearchBoxScripts(classSearchBox)
    classSearchBox:SetText("")
    classSearchText = ""

    -- Race search
    local raceLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raceLabel:SetPoint("LEFT", classSearchBox, "RIGHT", 15, 0)
    raceLabel:SetText("Race:")
    raceLabel:SetTextColor(1, 0.82, 0)

    local raceSearchBox = CreateRaceSearchBox(searchBg, raceLabel)
    raceSearchBox:SetSize(80, 20)  -- Increased from 60
    raceSearchBox:SetPoint("LEFT", raceLabel, "RIGHT", 5, 0)
    SetupRaceSearchBoxScripts(raceSearchBox)
    raceSearchBox:SetText("")
    raceSearchText = ""

    -- Gender search
    local genderLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genderLabel:SetPoint("LEFT", raceSearchBox, "RIGHT", 15, 0)
    genderLabel:SetText("Gender:")
    genderLabel:SetTextColor(1, 0.82, 0)

    local genderSearchBox = CreateGenderSearchBox(searchBg, genderLabel)
    genderSearchBox:SetSize(55, 20)  -- Unchanged
    genderSearchBox:SetPoint("LEFT", genderLabel, "RIGHT", 5, 0)
    SetupGenderSearchBoxScripts(genderSearchBox)
    genderSearchBox:SetText("")
    genderSearchText = ""

    -- Zone search
    local zoneLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("LEFT", genderSearchBox, "RIGHT", 15, 0)
    zoneLabel:SetText("Zone:")
    zoneLabel:SetTextColor(1, 0.82, 0)

    local zoneSearchBox = CreateZoneSearchBox(searchBg, zoneLabel)
    zoneSearchBox:SetSize(130, 20)  -- Significantly increased from 60
    zoneSearchBox:SetPoint("LEFT", zoneLabel, "RIGHT", 5, 0)
    SetupZoneSearchBoxScripts(zoneSearchBox)
    zoneSearchBox:SetText("")
    zoneSearchText = ""

    -- Store references in the frame for external access
    frame.searchBox = searchBox
    frame.levelSearchBox = levelSearchBox
    frame.classSearchBox = classSearchBox
    frame.raceSearchBox = raceSearchBox
    frame.genderSearchBox = genderSearchBox
    frame.zoneSearchBox = zoneSearchBox

    return searchBox
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45) -- Increased bottom margin to make room for search bar

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(PKA_KILLS_FRAME_WIDTH - 40, PKA_KILLS_FRAME_HEIGHT * 2)
    scrollFrame:SetScrollChild(content)

    return content
end

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "PKAKillStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(PKA_KILLS_FRAME_WIDTH, PKA_KILLS_FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    -- No need for these anymore as they'll be handled by FrameManager
    -- frame:SetScript("OnDragStart", frame.StartMoving)
    -- frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    -- frame:SetScript("OnMouseDown", function(self) ... end)

    table.insert(UISpecialFrames, "PKAKillStatsFrame")
    frame.TitleText:SetText("Player Kill List")

    return frame
end

function RefreshKillList()
    local content = killStatsFrame.content
    if not content then return end

    CleanupFrameElements(content)
    collectgarbage("collect")

    local yOffset = CreateColumnHeaders(content)
    local sortedEntries = FilterAndSortEntries()
    local finalYOffset, entryCount = DisplayEntries(content, sortedEntries, yOffset)

    content:SetHeight(math.max((-finalYOffset + 20), PKA_KILLS_FRAME_HEIGHT - 50))
end

function PKA_CreateKillStatsFrame()
    if killStatsFrame then
        PKA_FrameManager:ShowFrame("KillsList")
        RefreshKillList()
        return
    end

    killStatsFrame = CreateMainFrame()
    killStatsFrame.content = CreateScrollFrame(killStatsFrame)
    CreateSearchBar(killStatsFrame)

    -- Register with frame manager
    PKA_FrameManager:RegisterFrame(killStatsFrame, "KillsList")

    RefreshKillList()
end

-- Make the searchText variable accessible to external functions
function PKA_SetKillListSearch(text, levelText, classText, raceText, genderText, zoneText, resetOtherFilters)
    if killStatsFrame then
        -- Reset all filters first if requested (when clicking on bars in statistics)
        if resetOtherFilters then
            killStatsFrame.searchBox:SetText("")
            searchText = ""
            killStatsFrame.levelSearchBox:SetText("")
            levelSearchText = ""
            killStatsFrame.classSearchBox:SetText("")
            classSearchText = ""
            killStatsFrame.raceSearchBox:SetText("")
            raceSearchText = ""
            killStatsFrame.genderSearchBox:SetText("")
            genderSearchText = ""
            killStatsFrame.zoneSearchBox:SetText("")
            zoneSearchText = ""
            minLevelSearch = nil
            maxLevelSearch = nil
        end

        if killStatsFrame.searchBox and text then
            killStatsFrame.searchBox:SetText(text)
            searchText = text:lower()
        end

        if killStatsFrame.levelSearchBox and levelText then
            killStatsFrame.levelSearchBox:SetText(levelText)
            levelSearchText = levelText
            ParseLevelSearch(levelText)
        end

        if killStatsFrame.classSearchBox and classText then
            killStatsFrame.classSearchBox:SetText(classText)
            classSearchText = classText
        end

        if killStatsFrame.raceSearchBox and raceText then
            killStatsFrame.raceSearchBox:SetText(raceText)
            raceSearchText = raceText
        end

        if killStatsFrame.genderSearchBox and genderText then
            killStatsFrame.genderSearchBox:SetText(genderText)
            genderSearchText = genderText
        end

        if killStatsFrame.zoneSearchBox and zoneText then
            killStatsFrame.zoneSearchBox:SetText(zoneText)
            zoneSearchText = zoneText
        end

        RefreshKillList()
    end
end

-- New function to set level range filter
function PKA_SetKillListLevelRange(minLevel, maxLevel, resetOtherFilters)
    if killStatsFrame then
        -- Reset all filters first if requested
        if resetOtherFilters then
            killStatsFrame.searchBox:SetText("")
            searchText = ""
            killStatsFrame.classSearchBox:SetText("")
            classSearchText = ""
            killStatsFrame.raceSearchBox:SetText("")
            raceSearchText = ""
            killStatsFrame.genderSearchBox:SetText("")
            genderSearchText = ""
            killStatsFrame.zoneSearchBox:SetText("")
            zoneSearchText = ""
        end

        -- Set the level range directly to the internal variables
        minLevelSearch = minLevel
        maxLevelSearch = maxLevel

        -- Update the level search box text
        if killStatsFrame.levelSearchBox then
            if minLevel and maxLevel and minLevel == maxLevel then
                -- Single level
                killStatsFrame.levelSearchBox:SetText(tostring(minLevel))
                levelSearchText = tostring(minLevel)
            elseif minLevel and maxLevel then
                -- Level range
                local rangeText = minLevel .. "-" .. maxLevel
                killStatsFrame.levelSearchBox:SetText(rangeText)
                levelSearchText = rangeText
            elseif minLevel == -1 then
                -- Special case for unknown level
                killStatsFrame.levelSearchBox:SetText("??")
                levelSearchText = "??"
            else
                -- Clear the filter if something went wrong
                killStatsFrame.levelSearchBox:SetText("")
                levelSearchText = ""
                minLevelSearch = nil
                maxLevelSearch = nil
            end
        end

        -- Highlight the text with the proper color
        if killStatsFrame.levelSearchBox then
            if ParseLevelSearch(levelSearchText) then
                killStatsFrame.levelSearchBox:SetTextColor(1, 1, 1)
            else
                killStatsFrame.levelSearchBox:SetTextColor(1, 0.3, 0.3)
            end
        end

        -- Refresh the kill list to apply the filter
        RefreshKillList()

        -- Bring the kills list frame to front if it's not already
        PKA_FrameManager:BringToFront("KillsList")
    end
end
