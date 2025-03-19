if not PSC_ActiveFrameLevel then
    PSC_ActiveFrameLevel = 100
end

PSC_KillsListFrame = nil
local searchText = ""
local levelSearchText = ""
local classSearchText = ""  -- New filter variable for class
local raceSearchText = ""   -- New filter variable for race
local genderSearchText = "" -- New filter variable for gender
local zoneSearchText = "" -- New filter variable for zone
local rankSearchText = "" -- Add this variable at the top with other search variables
local minLevelSearch = nil
local maxLevelSearch = nil
local minRankSearch = nil
local maxRankSearch = nil
local sortBy = "lastKill"
local sortAscending = false
local PSC_KILLS_FRAME_WIDTH = 1020  -- Increased from 900
local PSC_KILLS_FRAME_HEIGHT = 550  -- Increased from 500

local colWidths = {
    name = 100,
    class = 70,
    race = 70,
    gender = 80,
    level = 70,
    rank = 70,    -- New rank column
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
    -- Reset level search variables
    minLevelSearch = nil
    maxLevelSearch = nil

    if text == "" then
        return true
    end

    -- Special case for unknown level ("??")
    if text == "??" then
        minLevelSearch = -1
        maxLevelSearch = -1
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
        maxLevelSearch = level
        return true
    end

    return false
end

-- Add this function to parse rank range searches
local function ParseRankSearch(text)
    -- Reset rank search variables
    minRankSearch = nil
    maxRankSearch = nil

    if text == "" then
        return true
    end

    -- Check for rank range format: "min-max"
    local min, max = text:match("^(%d+)-(%d+)$")
    if min and max then
        min = tonumber(min)
        max = tonumber(max)
        -- Ensure min is less than or equal to max
        if min and max and min <= max and min >= 0 and max <= 14 then
            minRankSearch = min
            maxRankSearch = max
            return true
        end
        return false
    end

    -- Check for single rank format
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
    levelSearchBox:SetMaxLetters(5)  -- Max input like "60-60"
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


    for nameWithLevel, data in pairs(PSC_DB.PlayerKillCounts) do
        local searchMatch = true
        local levelMatch = true
        local classMatch = true
        local raceMatch = true
        local genderMatch = true
        local zoneMatch = true
        local rankMatch = true  -- Add rank match variable

        -- Player/Guild name search
        if searchText ~= "" then
            local name = string.gsub(nameWithLevel, ":[^:]*$", ""):lower()
            local guild = (data.guild or ""):lower()
            if not (string.find(name, searchText, 1, true) or string.find(guild, searchText, 1, true)) then
                searchMatch = false
            end
        end

        -- Level search
        if minLevelSearch or maxLevelSearch then
            local level = nameWithLevel:match(":(%S+)")
            local levelNum = tonumber(level or "0") or 0

            -- Special case for unknown level
            if minLevelSearch == -1 and maxLevelSearch == -1 then
                -- Check if this is an unknown level (level == -1 or data.unknownLevel is true)
                if levelNum ~= -1 and not (data.unknownLevel or false) then
                    levelMatch = false
                end
            else
                -- Normal level range checking
                if levelNum == -1 or (data.unknownLevel or false) then
                    levelMatch = false
                else
                    if minLevelSearch and levelNum < minLevelSearch then
                        levelMatch = false
                    end
                    if maxLevelSearch and levelNum > maxLevelSearch then
                        levelMatch = false
                    end
                end
            end
        end

        -- Class filter
        if classSearchText ~= "" then
            local class = (data.class or "Unknown"):lower()
            if not string.find(class:lower(), classSearchText:lower(), 1, true) then
                classMatch = false
            end
        end

        -- Race filter
        if raceSearchText ~= "" then
            local race = (data.race or "Unknown"):lower()
            if not string.find(race:lower(), raceSearchText:lower(), 1, true) then
                raceMatch = false
            end
        end

        -- Gender filter - Make this exact match case insensitive
        if genderSearchText ~= "" then
            local normalizedSearch = genderSearchText:lower():gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
            local normalizedGender = (data.gender or "Unknown"):lower():gsub("^%s*(.-)%s*$", "%1") -- trim whitespace

            -- Auto-complete for single-letter inputs
            if normalizedSearch == "m" then
                normalizedSearch = "male"
            elseif normalizedSearch == "f" then
                normalizedSearch = "female"
            elseif normalizedSearch == "u" then
                normalizedSearch = "unknown"
            end

            if normalizedGender ~= normalizedSearch then
                genderMatch = false
            end
        end

        -- Zone filter
        if zoneSearchText ~= "" then
            local zone = (data.zone or "Unknown"):lower()
            if not string.find(zone:lower(), zoneSearchText:lower(), 1, true) then
                zoneMatch = false
            end
        end

        -- Rank filter
        if rankSearchText ~= "" then
            local rank = data.rank or 0

            if minRankSearch ~= nil and maxRankSearch ~= nil then
                -- Use the parsed range values
                if rank < minRankSearch or rank > maxRankSearch then
                    rankMatch = false
                end
            else
                -- Fallback to text-based matching if range parsing failed
                local rankStr = tostring(rank)
                if not string.find(rankStr, rankSearchText, 1, true) then
                    rankMatch = false
                end
            end
        end

        if searchMatch and levelMatch and classMatch and raceMatch and genderMatch and zoneMatch and rankMatch then
            -- Convert level -1 to "??" for display
            local level = nameWithLevel:match(":(%S+)")
            local levelDisplay = level
            if level == "-1" or (data.unknownLevel or false) then
                levelDisplay = "??"
            end

            local entry = {
                name = nameWithLevel:gsub(":[^:]*$", ""),
                class = data.class or "Unknown",
                race = data.race or "Unknown",
                gender = data.gender or "Unknown",
                level = level, -- Keep the original numeric level
                levelDisplay = levelDisplay, -- Display level (shows ?? for unknown)
                guild = data.guild or "",
                kills = data.kills or 1,
                lastKill = data.lastKill or "",
                zone = data.zone or "Unknown",
                unknownLevel = data.unknownLevel or false,
                rank = data.rank or 0  -- Add the rank data
            }

            table.insert(sortedEntries, entry)
        end
    end

    -- Sort the entries based on the selected sort method
    table.sort(sortedEntries, function(a, b)
        -- Safety check - always return a consistent value for any comparison
        if not a or not b then
            return false
        end

        -- For level sorting, handle the special cases first before looking at values
        if sortBy == "level" then
            -- Handle nil values
            local aLevel = a.unknownLevel and -1 or tonumber(a.level) or -1
            local bLevel = b.unknownLevel and -1 or tonumber(b.level) or -1

            -- Unknown levels (-1) should appear at the end when ascending
            -- and at the beginning when descending
            if aLevel == -1 and bLevel ~= -1 then
                return not sortAscending
            elseif aLevel ~= -1 and bLevel == -1 then
                return sortAscending
            else
                -- Both are either unknown or known levels
                if sortAscending then
                    return aLevel < bLevel
                else
                    return aLevel > bLevel
                end
            end
        end

        -- For other fields, extract the values to compare
        local aVal, bVal

        if sortBy == "name" then
            aVal, bVal = a.name or "", b.name or ""
        elseif sortBy == "class" then
            aVal, bVal = a.class or "Unknown", b.class or "Unknown"
        elseif sortBy == "race" then
            aVal, bVal = a.race or "Unknown", b.race or "Unknown"
        elseif sortBy == "gender" then
            aVal, bVal = a.gender or "Unknown", b.gender or "Unknown"
        elseif sortBy == "rank" then  -- Add rank sorting option
            aVal, bVal = tonumber(a.rank) or 0, tonumber(b.rank) or 0
        elseif sortBy == "guild" then
            aVal, bVal = a.guild or "", b.guild or ""
        elseif sortBy == "zone" then
            aVal, bVal = a.zone or "Unknown", b.zone or "Unknown"
        elseif sortBy == "kills" then
            aVal, bVal = tonumber(a.kills) or 0, tonumber(b.kills) or 0
        elseif sortBy == "lastKill" then
            aVal, bVal = a.lastKill or "", b.lastKill or ""
        else
            -- Default to name if sort field is unrecognized
            aVal, bVal = a.name or "", b.name or ""
        end

        -- For numeric values like kills, use numeric comparison
        if type(aVal) == "number" and type(bVal) == "number" then
            if sortAscending then
                return aVal < bVal
            else
                return aVal > bVal
            end
        else
            -- For strings and other values, convert to string for consistent comparison
            if sortAscending then
                return tostring(aVal) < tostring(bVal)
            else
                return tostring(aVal) > tostring(bVal)
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
    local rankButton = CreateColumnHeader(content, "Rank", colWidths.rank, levelButton, 0, 0, "rank")  -- New rank column header
    local guildButton = CreateColumnHeader(content, "Guild", colWidths.guild, rankButton, 0, 0, "guild")  -- Changed anchor
    local zoneButton = CreateColumnHeader(content, "Zone", colWidths.zone, guildButton, 0, 0, "zone")
    local killsButton = CreateColumnHeader(content, "Kills", colWidths.kills, zoneButton, 0, 0, "kills")
    local lastKillButton = CreateColumnHeader(content, "Last Killed", colWidths.lastKill, killsButton, 0, 0, "lastKill")

    -- Set the position for the start of the entries
    return -30
end

local function CreateNameCell(content, xPos, yPos, name, width)
    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetPoint("LEFT", content, "LEFT", xPos + 10, 0)
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

local function FormatLastKillDate(dateString)
    -- Check if dateString is valid
    if not dateString or dateString == "" then
        return ""
    end

    -- Parse the full date format (YYYY-MM-DD HH:MM:SS)...
    local year, month, day, hour, min, sec = dateString:match("(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)")

    if not year then
        return dateString -- Return original if pattern doesn't match
    end

    -- ... to DD/MM/YY HH:MM:SS
    local shortYear = year:sub(-2)
    return string.format("%02d/%02d/%02s %02d:%02d:%02d",
        tonumber(day),
        tonumber(month),
        shortYear,
        tonumber(hour),
        tonumber(min),
        tonumber(sec))
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

    -- Format the rank display as a number instead of title
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
    -- Create the main highlight texture
    local highlight = parent:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(true)

    -- For gradient effects, we need to handle old and new API versions
    local useNewAPI = highlight.SetGradient and
                      type(highlight.SetGradient) == "function" and
                      pcall(function()
                          highlight:SetGradient("HORIZONTAL", {r=1,g=1,b=1,a=1}, {r=1,g=1,b=1,a=1})
                          return true
                      end)

    if useNewAPI then
        -- Use the newer API version with table parameters (WoW 10.0+)
        highlight:SetColorTexture(1, 0.82, 0, 0.6)  -- Significantly increased alpha from 0.35 to 0.6

        -- Try to set gradient in a safe way
        pcall(function()
            highlight:SetGradient("HORIZONTAL",
                {r=1, g=0.82, b=0, a=0.3},   -- Left side (more visible gold)
                {r=1, g=0.82, b=0, a=0.8}    -- Right side (very visible gold)
            )
        end)
    else
        -- For older clients, create two separate textures for the gradient
        -- First, make the main highlight a solid color with high opacity
        highlight:SetColorTexture(1, 0.82, 0, 0.5)  -- Increased from 0.25 to 0.5

        -- Create left half with gradient fade in
        local leftGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        leftGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        leftGradient:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        leftGradient:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        leftGradient:SetWidth(parent:GetWidth() / 2)
        leftGradient:SetHeight(height)

        -- Use pcall to safely handle method variations between API versions
        pcall(function()
            leftGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.3, 1, 0.82, 0, 0.7)  -- Increased values
        end)

        -- Fallback if SetGradientAlpha fails
        if leftGradient:GetVertexColor() == 1 and select(2, leftGradient:GetVertexColor()) == 1 then
            leftGradient:SetVertexColor(1, 0.82, 0, 0.6)  -- Increased from 0.3 to 0.6
        end

        -- Create right half with gradient fade out
        local rightGradient = parent:CreateTexture(nil, "HIGHLIGHT")
        rightGradient:SetTexture("Interface\\Buttons\\WHITE8x8")
        rightGradient:SetPoint("TOPLEFT", leftGradient, "TOPRIGHT", 0, 0)
        rightGradient:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

        -- Use pcall to safely handle method variations between API versions
        pcall(function()
            rightGradient:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0.3)  -- Increased values
        end)

        -- Fallback if SetGradientAlpha fails
        if rightGradient:GetVertexColor() == 1 and select(2, rightGradient:GetVertexColor()) == 1 then
            rightGradient:SetVertexColor(1, 0.82, 0, 0.6)  -- Increased from 0.3 to 0.6
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

local function CreateEntryRow(content, entry, yOffset, colWidths, isAlternate)
    -- Create a row container to handle highlighting
    local rowContainer = CreateFrame("Button", nil, content)
    rowContainer:SetSize(content:GetWidth() - 20, 16)
    rowContainer:SetPoint("TOPLEFT", 10, yOffset)

    -- Add slight alternating row backgrounds for better readability
    if isAlternate then
        local bgTexture = rowContainer:CreateTexture(nil, "BACKGROUND")
        bgTexture:SetAllPoints()
        bgTexture:SetColorTexture(0.05, 0.05, 0.05, 0.3)
    end

    -- Create highlight with gradient fade effect
    local highlightTexture = CreateGoldHighlight(rowContainer, 16)

    local nameCell = CreateNameCell(rowContainer, 0, 0, entry.name, colWidths.name)
    local classCell = CreateClassCell(rowContainer, nameCell, entry.class, colWidths.class)
    local raceCell = CreateRaceCell(rowContainer, classCell, entry.race, colWidths.race)
    local genderCell = CreateGenderCell(rowContainer, raceCell, entry.gender, colWidths.gender)
    local levelCell = CreateLevelCell(rowContainer, genderCell, entry.levelDisplay, colWidths.level)
    local rankCell = CreateRankCell(rowContainer, levelCell, entry.rank, colWidths.rank)  -- Add rank cell
    local guildCell = CreateGuildCell(rowContainer, rankCell, entry.guild, colWidths.guild)  -- Change anchor
    local zoneCell = CreateZoneCell(rowContainer, guildCell, entry.zone, colWidths.zone)
    local killsCell = CreateKillsCell(rowContainer, zoneCell, entry.kills, colWidths.kills)
    local lastKillCell = CreateLastKillCell(rowContainer, killsCell, entry.lastKill, colWidths.lastKill)

    return yOffset - 16 -- Return the next row position
end

local function DisplayEntries(content, sortedEntries, startYOffset)
    local yOffset = startYOffset
    local count = 0
    local maxDisplayEntries = 500

    for i, entry in ipairs(sortedEntries) do
        if count >= maxDisplayEntries then break end

        -- Pass alternating row flag (true for odd rows, false for even rows)
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

        -- Auto-normalize when typing certain values
        local normalizedText = text:lower():gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
        if normalizedText == "m" then
            -- Keep as "m" for now - will be expanded in filter
        elseif normalizedText == "f" then
            -- Keep as "f" for now - will be expanded in filter
        end

        RefreshKillList()
    end)

    genderSearchBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    genderSearchBox:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)

        -- Normalize gender to Male/Female/Unknown
        local text = self:GetText():lower():gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
        if text == "m" or text == "male" then
            self:SetText("Male")
            genderSearchText = "Male"
            RefreshKillList()
        elseif text == "f" or text == "female" then
            self:SetText("Female")
            genderSearchText = "Female"
            RefreshKillList()
        elseif text == "u" or text == "unknown" or text == "?" or text == "??" then
            self:SetText("Unknown")
            genderSearchText = "Unknown"
            RefreshKillList()
        elseif text == "" then
            -- Clear filter
            genderSearchText = ""
            RefreshKillList()
        else
            -- If text doesn't match known genders, try to find closest match
            local lowerText = text:lower()
            if lowerText:find("^ma") or lowerText:find("^me") then
                self:SetText("Male")
                genderSearchText = "Male"
                RefreshKillList()
            elseif lowerText:find("^fe") or lowerText:find("^wo") then
                self:SetText("Female")
                genderSearchText = "Female"
                RefreshKillList()
            elseif lowerText:find("^un") then
                self:SetText("Unknown")
                genderSearchText = "Unknown"
                RefreshKillList()
            else
                -- Text doesn't match any known gender, clear to avoid confusion
                self:SetText("")
                genderSearchText = ""
                RefreshKillList()
            end
        end
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

local function CreateRankSearchBox(parent, anchorTo)
    local rankSearchBox = CreateFrame("EditBox", nil, parent)
    rankSearchBox:SetSize(50, 20)  -- Reduced width from 70 to 50
    rankSearchBox:SetPoint("LEFT", anchorTo, "RIGHT", 10, 0)
    rankSearchBox:SetAutoFocus(false)
    rankSearchBox:SetMaxLetters(5)  -- Enough for "14-14"
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
            RefreshKillList()
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
        RefreshKillList()
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

    -- Rank search
    local rankLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankLabel:SetPoint("LEFT", zoneSearchBox, "RIGHT", 15, 0)
    rankLabel:SetText("Rank:")
    rankLabel:SetTextColor(1, 0.82, 0)

    local rankSearchBox = CreateRankSearchBox(searchBg, rankLabel)
    rankSearchBox:SetSize(50, 20)  -- Reduced width
    rankSearchBox:SetPoint("LEFT", rankLabel, "RIGHT", 5, 0)
    SetupRankSearchBoxScripts(rankSearchBox)
    rankSearchBox:SetText("")
    rankSearchText = ""

    -- Store references in the frame for external access
    frame.searchBox = searchBox
    frame.levelSearchBox = levelSearchBox
    frame.classSearchBox = classSearchBox
    frame.raceSearchBox = raceSearchBox
    frame.genderSearchBox = genderSearchBox
    frame.zoneSearchBox = zoneSearchBox
    frame.rankSearchBox = rankSearchBox  -- Add this line

    return searchBox
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45) -- Increased bottom margin to make room for search bar

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

    -- No need for these anymore as they'll be handled by FrameManager
    -- frame:SetScript("OnDragStart", frame.StartMoving)
    -- frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    -- frame:SetScript("OnMouseDown", function(self) ... end)

    table.insert(UISpecialFrames, "PSC_KillStatsFrame")
    frame.TitleText:SetText("Player Kills List")

    return frame
end

function RefreshKillList()
    if PSC_KillsListFrame == nil then return end
    local content = PSC_KillsListFrame.content
    if not content then return end

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
        RefreshKillList()
        return
    end

    PSC_KillsListFrame = CreateMainFrame()
    PSC_KillsListFrame.content = CreateScrollFrame(PSC_KillsListFrame)
    CreateSearchBar(PSC_KillsListFrame)

    -- Register with frame manager
    PSC_FrameManager:RegisterFrame(PSC_KillsListFrame, "KillsList")

    -- Remove from UISpecialFrames since FrameManager handles ESC key
    for i = #UISpecialFrames, 1, -1 do
        if (UISpecialFrames[i] == "PSC_KillStatsFrame") then
            table.remove(UISpecialFrames, i)
            break
        end
    end

    RefreshKillList()
end

-- Make the searchText variable accessible to external functions
function PSC_SetKillListSearch(text, levelText, classText, raceText, genderText, zoneText, resetOtherFilters)
    if PSC_KillsListFrame then
        -- Reset all filters first if requested (when clicking on bars in statistics)
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

        RefreshKillList()
    end
end

-- New function to set level range filter
function PSC_SetKillListLevelRange(minLevel, maxLevel, resetOtherFilters)
    if PSC_KillsListFrame then
        -- Reset all filters first if requested
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

        -- Set the level range directly to the internal variables
        minLevelSearch = minLevel
        maxLevelSearch = maxLevel

        -- Update the level search box text
        if PSC_KillsListFrame.levelSearchBox then
            if minLevel == -1 and maxLevel == -1 then
                -- Special case for unknown level
                PSC_KillsListFrame.levelSearchBox:SetText("??")
                levelSearchText = "??"
            elseif minLevel and maxLevel and minLevel == maxLevel then
                -- Single level
                PSC_KillsListFrame.levelSearchBox:SetText(tostring(minLevel))
                levelSearchText = tostring(minLevel)
            elseif minLevel and maxLevel then
                -- Level range
                local rangeText = minLevel .. "-" .. maxLevel
                PSC_KillsListFrame.levelSearchBox:SetText(rangeText)
                levelSearchText = rangeText
            else
                -- Clear the filter if something went wrong
                PSC_KillsListFrame.levelSearchBox:SetText("")
                levelSearchText = ""
                minLevelSearch = nil
                maxLevelSearch = nil
            end
        end

        -- Highlight the text with the proper color
        if PSC_KillsListFrame.levelSearchBox then
            -- Always set to white - we've already validated the input
            PSC_KillsListFrame.levelSearchBox:SetTextColor(1, 1, 1)
        end

        -- Refresh the kill list to apply the filter
        RefreshKillList()

        -- Bring the kills list frame to front if it's not already
        PSC_FrameManager:BringToFront("KillsList")
    end
end

-- Add a new function to set rank range filter (similar to level range)
function PSC_SetKillListRankRange(minRank, maxRank, resetOtherFilters)
    if PSC_KillsListFrame then
        -- Reset all filters first if requested
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

        -- Set the rank range directly to the internal variables
        minRankSearch = minRank
        maxRankSearch = maxRank

        -- Update the rank search box text
        if PSC_KillsListFrame.rankSearchBox then
            if minRank and maxRank and minRank == maxRank then
                -- Single rank
                PSC_KillsListFrame.rankSearchBox:SetText(tostring(minRank))
                rankSearchText = tostring(minRank)
            elseif minRank and maxRank then
                -- Rank range
                local rangeText = minRank .. "-" .. maxRank
                PSC_KillsListFrame.rankSearchBox:SetText(rangeText)
                rankSearchText = rangeText
            else
                -- Clear the filter if something went wrong
                PSC_KillsListFrame.rankSearchBox:SetText("")
                rankSearchText = ""
                minRankSearch = nil
                maxRankSearch = nil
            end
        end

        -- Highlight the text with the proper color
        if PSC_KillsListFrame.rankSearchBox then
            -- Always set to white - we've already validated the input
            PSC_KillsListFrame.rankSearchBox:SetTextColor(1, 1, 1)
        end

        -- Refresh the kill list to apply the filter
        RefreshKillList()

        -- Bring the kills list frame to front if it's not already
        PSC_FrameManager:BringToFront("KillsList")
    end
end
