local killStatsFrame = nil
local searchText = ""
local levelSearchText = ""  -- New variable for level search
local minLevelSearch = nil  -- For level range search
local maxLevelSearch = nil  -- For level range search
local sortBy = "lastKill"
local sortAscending = false

local PKA_KILLS_FRAME_WIDTH = 800
local PKA_KILLS_FRAME_HEIGHT = 500

local colWidths = {
    name = 100,
    class = 80,
    race = 80,
    gender = 95,
    level = 40,
    guild = 150,
    kills = 50,
    lastKill = 145
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
    if fontString then
        fontString:SetTextColor(enter and 1 or 1, enter and 1 or 0.82, enter and 0.5 or 0)
    end
end

local function CreateColumnHeader(parent, text, width, anchor, xOffset, yOffset, columnId)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 24)

    if type(anchor) == "string" then
        button:SetPoint("TOPLEFT", xOffset, yOffset)
    else
        button:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
    end

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

    local header = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("LEFT", 0, 0)
    header:SetTextColor(1, 0.82, 0)
    header:SetText(text .. (sortBy == columnId and (sortAscending and " ^" or " v") or ""))
    header:SetWidth(width)
    header:SetJustifyH("LEFT")

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

        -- Check if the entry matches the name/guild search
        local matchesNameGuild = (searchText == "" or
                                nameLower:find(searchText, 1, true) or
                                guildLower:find(searchText, 1, true))

        -- Check if the entry matches the level search criteria
        local matchesLevel = true
        if levelSearchText ~= "" then
            if minLevelSearch and maxLevelSearch then
                -- Level range: check if level is within range
                matchesLevel = (levelNum >= minLevelSearch and levelNum <= maxLevelSearch)
            elseif minLevelSearch then
                -- Single level: check if level matches exactly
                matchesLevel = (levelNum == minLevelSearch)
            end
        end

        -- Add to results only if both criteria are matched
        if matchesNameGuild and matchesLevel then
            count = count + 1
            sortedEntries[count] = {
                nameWithLevel = nameWithLevel,
                name = name,
                class = data.class or "Unknown",
                race = data.race or "Unknown",
                gender = data.gender or "Unknown",
                level = levelNum,
                guild = data.guild or "",
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

            if sortBy == "level" then
                if a.level == -1 and b.level ~= -1 then
                    return not sortAscending
                elseif a.level ~= -1 and b.level == -1 then
                    return sortAscending
                end

                if a.level == b.level then
                    return a.name:lower() < b.name:lower()
                end

                return sortAscending and (a.level < b.level) or (a.level > b.level)
            end

            local aValue = a[sortBy]
            local bValue = b[sortBy]

            if aValue == bValue or (not aValue and not bValue) then
                return a.name:lower() < b.name:lower()
            end

            if not aValue then return false end
            if not bValue then return true end

            if type(aValue) == "string" and type(bValue) == "string" then
                return sortAscending and (aValue:lower() < bValue:lower()) or (aValue:lower() > bValue:lower())
            else
                return sortAscending and (aValue < bValue) or (aValue > bValue)
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
    local nameHeader = CreateColumnHeader(content, "Name", colWidths.name, "TOPLEFT", 10, -5, "name")
    local classHeader = CreateColumnHeader(content, "Class", colWidths.class, nameHeader, 0, 0, "class")
    local raceHeader = CreateColumnHeader(content, "Race", colWidths.race, classHeader, 0, 0, "race")
    local genderHeader = CreateColumnHeader(content, "Gender", colWidths.gender, raceHeader, 0, 0, "gender")
    local levelHeader = CreateColumnHeader(content, "Lvl", colWidths.level, genderHeader, 0, 0, "level")
    local guildHeader = CreateColumnHeader(content, "Guild", colWidths.guild, levelHeader, 0, 0, "guild")
    local killsHeader = CreateColumnHeader(content, "Kills", colWidths.kills, guildHeader, 0, 0, "kills")
    local lastKillHeader = CreateColumnHeader(content, "Last Kill", colWidths.lastKill, killsHeader, 0, 0, "lastKill")

    return -30 -- Return the next Y position after headers
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

local function CreateEntryRow(content, entry, yOffset, colWidths)
    local nameCell = CreateNameCell(content, 10, yOffset, entry.name, colWidths.name)
    local classCell = CreateClassCell(content, nameCell, entry.class, colWidths.class)
    local raceCell = CreateRaceCell(content, classCell, entry.race, colWidths.race)
    local genderCell = CreateGenderCell(content, raceCell, entry.gender, colWidths.gender)
    local levelCell = CreateLevelCell(content, genderCell, entry.level, colWidths.level)
    local guildCell = CreateGuildCell(content, levelCell, entry.guild, colWidths.guild)
    local killsCell = CreateKillsCell(content, guildCell, entry.kills, colWidths.kills)
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
    searchBg:SetHeight(30)

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

local function CreateSearchBar(frame)
    local searchBg = CreateSearchBackground(frame)
    local searchLabel = CreateSearchLabel(searchBg)
    local searchBox = CreateEditBox(searchBg, searchLabel)
    SetupSearchBoxScripts(searchBox)
    searchBox:SetText("")
    searchText = ""

    -- Add level search components
    local levelLabel = CreateLevelSearchLabel(searchBg, searchBox)
    local levelSearchBox = CreateLevelSearchBox(searchBg, levelLabel)
    SetupLevelSearchBoxScripts(levelSearchBox)
    levelSearchBox:SetText("")
    levelSearchText = ""

    -- Store references in the frame for external access
    frame.searchBox = searchBox
    frame.levelSearchBox = levelSearchBox

    return searchBox, levelSearchBox
end

local function CreateScrollFrame(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 35)

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
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Set frame strata to DIALOG to match the statistics frame
    frame:SetFrameStrata("DIALOG")
    -- Set frame level to be higher than statistics frame
    frame:SetFrameLevel(20)

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
        killStatsFrame:Show()
        killStatsFrame:Raise()
        killStatsFrame:SetFrameStrata("MEDIUM")
        RefreshKillList()
        return
    end

    killStatsFrame = CreateMainFrame()
    killStatsFrame.content = CreateScrollFrame(killStatsFrame)
    CreateSearchBar(killStatsFrame)
    RefreshKillList()
end

-- Make the searchText variable accessible to external functions
function PKA_SetKillListSearch(text, levelText)
    if killStatsFrame then
        if killStatsFrame.searchBox and text then
            killStatsFrame.searchBox:SetText(text)
            searchText = text:lower()
        end

        if killStatsFrame.levelSearchBox and levelText then
            killStatsFrame.levelSearchBox:SetText(levelText)
            levelSearchText = levelText
            ParseLevelSearch(levelText)
        end

        RefreshKillList()
    end
end
