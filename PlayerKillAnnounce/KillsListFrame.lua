local killStatsFrame = nil
local searchText = ""
-- Sorting variables
local sortBy = "lastKill"  -- Changed default sort from "kills" to "lastKill"
local sortAscending = false  -- Default descending (most recent kills first)

local PKA_KILLS_FRAME_WIDTH = 800  -- Increased from 700 to 800 for better column display
local PKA_KILLS_FRAME_HEIGHT = 500


local function cleanupFontStrings(content)
    local children = {content:GetChildren()}
    for _, child in pairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    -- Also clean up font strings directly attached to content
    for _, region in pairs({content:GetRegions()}) do
        if region:GetObjectType() == "FontString" then
            region:Hide()
            region:SetParent(nil)
        end
    end
end

local function RefreshKillList()
    local content = killStatsFrame.content
    if not content then return end

    -- Clean up all existing entries
    cleanupFontStrings(content)

    -- Column widths - increased for better readability
    local colWidths = {
        name = 100,     -- Player names (increased from 80)
        class = 80,     -- Class name (increased from 65)
        race = 80,      -- Race column (increased from 65)
        gender = 95,    -- Gender column (increased from 55)
        level = 40,     -- Level column (increased from 30)
        guild = 150,    -- Guild column (increased from 120)
        kills = 50,     -- Kill count column (increased from 40)
        lastKill = 145  -- Last kill time (adjusted to fit in frame)
    }

    -- Setup headers code
    -- Name Column Header
    local nameHeaderBtn = CreateFrame("Button", nil, content)
    nameHeaderBtn:SetSize(colWidths.name, 24)
    nameHeaderBtn:SetPoint("TOPLEFT", 10, -5)
    nameHeaderBtn:SetScript("OnClick", function()
        if sortBy == "name" then
            sortAscending = not sortAscending
        else
            sortBy = "name"
            sortAscending = true -- Default to alphabetical A-Z when first clicking
        end
        RefreshKillList()
    end)

    local nameHeader = nameHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameHeader:SetPoint("LEFT", 0, 0)
    nameHeader:SetTextColor(1, 0.82, 0)
    nameHeader:SetText("Name" .. (sortBy == "name" and (sortAscending and " ^" or " v") or ""))
    nameHeader:SetWidth(colWidths.name)
    nameHeader:SetJustifyH("LEFT")

    -- Class Column Header
    local classHeaderBtn = CreateFrame("Button", nil, content)
    classHeaderBtn:SetSize(colWidths.class, 24)
    classHeaderBtn:SetPoint("TOPLEFT", nameHeaderBtn, "TOPRIGHT", 0, 0)
    classHeaderBtn:SetScript("OnClick", function()
        if sortBy == "class" then
            sortAscending = not sortAscending
        else
            sortBy = "class"
            sortAscending = true -- Default to alphabetical A-Z when first clicking
        end
        RefreshKillList()
    end)

    local classHeader = classHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    classHeader:SetPoint("LEFT", 0, 0)
    classHeader:SetTextColor(1, 0.82, 0)
    classHeader:SetText("Class" .. (sortBy == "class" and (sortAscending and " ^" or " v") or ""))
    classHeader:SetWidth(colWidths.class)
    classHeader:SetJustifyH("LEFT")

    -- Race Column Header
    local raceHeaderBtn = CreateFrame("Button", nil, content)
    raceHeaderBtn:SetSize(colWidths.race, 24)
    raceHeaderBtn:SetPoint("TOPLEFT", classHeaderBtn, "TOPRIGHT", 0, 0)
    raceHeaderBtn:SetScript("OnClick", function()
        if sortBy == "race" then
            sortAscending = not sortAscending
        else
            sortBy = "race"
            sortAscending = true -- Default to alphabetical A-Z when first clicking
        end
        RefreshKillList()
    end)

    local raceHeader = raceHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    raceHeader:SetPoint("LEFT", 0, 0)
    raceHeader:SetTextColor(1, 0.82, 0)
    raceHeader:SetText("Race" .. (sortBy == "race" and (sortAscending and " ^" or " v") or ""))
    raceHeader:SetWidth(colWidths.race)
    raceHeader:SetJustifyH("LEFT")

    -- Gender Column Header
    local genderHeaderBtn = CreateFrame("Button", nil, content)
    genderHeaderBtn:SetSize(colWidths.gender, 24)
    genderHeaderBtn:SetPoint("TOPLEFT", raceHeaderBtn, "TOPRIGHT", 0, 0)
    genderHeaderBtn:SetScript("OnClick", function()
        if sortBy == "gender" then
            sortAscending = not sortAscending
        else
            sortBy = "gender"
            sortAscending = true -- Default to alphabetical A-Z when first clicking
        end
        RefreshKillList()
    end)

    local genderHeader = genderHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    genderHeader:SetPoint("LEFT", 0, 0)
    genderHeader:SetTextColor(1, 0.82, 0)
    genderHeader:SetText("Gender" .. (sortBy == "gender" and (sortAscending and " ^" or " v") or ""))
    genderHeader:SetWidth(colWidths.gender)
    genderHeader:SetJustifyH("LEFT")

    -- Level Column Header
    local levelHeaderBtn = CreateFrame("Button", nil, content)
    levelHeaderBtn:SetSize(colWidths.level, 24)
    levelHeaderBtn:SetPoint("TOPLEFT", genderHeaderBtn, "TOPRIGHT", 0, 0)
    levelHeaderBtn:SetScript("OnClick", function()
        if sortBy == "level" then
            sortAscending = not sortAscending
        else
            sortBy = "level"
            sortAscending = false -- Default to highest level first when clicking
        end
        RefreshKillList()
    end)

    local levelHeader = levelHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    levelHeader:SetPoint("LEFT", 0, 0)
    levelHeader:SetTextColor(1, 0.82, 0)
    levelHeader:SetText("Lvl" .. (sortBy == "level" and (sortAscending and " ^" or " v") or ""))
    levelHeader:SetWidth(colWidths.level)
    levelHeader:SetJustifyH("LEFT")

    -- Guild Column Header
    local guildHeaderBtn = CreateFrame("Button", nil, content)
    guildHeaderBtn:SetSize(colWidths.guild, 24)
    guildHeaderBtn:SetPoint("TOPLEFT", levelHeaderBtn, "TOPRIGHT", 0, 0)
    guildHeaderBtn:SetScript("OnClick", function()
        if sortBy == "guild" then
            sortAscending = not sortAscending
        else
            sortBy = "guild"
            sortAscending = true -- Default to alphabetical A-Z when first clicking
        end
        RefreshKillList()
    end)

    local guildHeader = guildHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    guildHeader:SetPoint("LEFT", 0, 0)
    guildHeader:SetTextColor(1, 0.82, 0)
    guildHeader:SetText("Guild" .. (sortBy == "guild" and (sortAscending and " ^" or " v") or ""))
    guildHeader:SetWidth(colWidths.guild)
    guildHeader:SetJustifyH("LEFT")

    -- Kills Column Header
    local killsHeaderBtn = CreateFrame("Button", nil, content)
    killsHeaderBtn:SetSize(colWidths.kills, 24)
    killsHeaderBtn:SetPoint("TOPLEFT", guildHeaderBtn, "TOPRIGHT", 0, 0)
    killsHeaderBtn:SetScript("OnClick", function()
        if sortBy == "kills" then
            sortAscending = not sortAscending
        else
            sortBy = "kills"
            sortAscending = false -- Default to highest kills first when clicking
        end
        RefreshKillList()
    end)

    local killsHeader = killsHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    killsHeader:SetPoint("LEFT", 0, 0)
    killsHeader:SetTextColor(1, 0.82, 0)
    killsHeader:SetText("Kills" .. (sortBy == "kills" and (sortAscending and " ^" or " v") or ""))
    killsHeader:SetWidth(colWidths.kills)
    killsHeader:SetJustifyH("LEFT")

    -- Last Kill Column Header
    local lastKillHeaderBtn = CreateFrame("Button", nil, content)
    lastKillHeaderBtn:SetSize(colWidths.lastKill, 24)
    lastKillHeaderBtn:SetPoint("TOPLEFT", killsHeaderBtn, "TOPRIGHT", 0, 0)
    lastKillHeaderBtn:SetScript("OnClick", function()
        if sortBy == "lastKill" then
            sortAscending = not sortAscending
        else
            sortBy = "lastKill"
            sortAscending = false -- Default to most recent first when clicking
        end
        RefreshKillList()
    end)

    local lastKillHeader = lastKillHeaderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    lastKillHeader:SetPoint("LEFT", 0, 0)
    lastKillHeader:SetTextColor(1, 0.82, 0)
    lastKillHeader:SetText("Last Kill" .. (sortBy == "lastKill" and (sortAscending and " ^" or " v") or ""))
    lastKillHeader:SetWidth(colWidths.lastKill)
    lastKillHeader:SetJustifyH("LEFT")

    -- Add header hover effects
    local function SetHeaderButtonHighlight(button, enter)
        local fontString = button:GetFontString()
        if fontString then
            fontString:SetTextColor(enter and 1 or 1, enter and 1 or 0.82, enter and 0.5 or 0)
        end
    end

    nameHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    nameHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    classHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    classHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    raceHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    raceHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    genderHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    genderHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    levelHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    levelHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    guildHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    guildHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    killsHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    killsHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    lastKillHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    lastKillHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    local yOffset = -30
    local count = 0

    -- Sort and filter entries
    local sortedEntries = {}
    for nameWithLevel, data in pairs(PKA_KillCounts) do
        -- Extract the player name and level from the composite key
        local name, level = strsplit(":", nameWithLevel)
        local levelNum = tonumber(level) or 0
        local nameLower = name:lower()

        -- Only add entries that match the search text
        if searchText == "" or nameLower:find(searchText, 1, true) then
            table.insert(sortedEntries, {
                nameWithLevel = nameWithLevel, -- Store composite key for reference
                name = name,
                class = data.class or "Unknown",
                race = data.race or "Unknown",
                gender = data.gender or "Unknown",
                level = levelNum,  -- This could be -1 for unknown levels
                guild = data.guild or "",
                kills = data.kills or 0,
                lastKill = data.lastKill or "Unknown",
                unknownLevel = data.unknownLevel or (levelNum == -1)  -- Flag for unknown level
            })
        end
    end

    -- Sort according to selected column and direction
    table.sort(sortedEntries, function(a, b)
        -- Handle different sorting columns
        if sortBy == "level" then
            -- When sorting by level, treat -1 (unknown level) as a high level value
            if a.level == -1 and b.level ~= -1 then
                -- Unknown level should be considered higher than any known level
                return not sortAscending
            elseif a.level ~= -1 and b.level == -1 then
                -- Known levels are lower than unknown levels
                return sortAscending
            else
                -- Regular comparison (both known or both unknown)
                if sortAscending then
                    return a.level < b.level
                else
                    return a.level > b.level
                end
            end
        elseif sortBy == "name" then
            if sortAscending then
                return a.name < b.name
            else
                return a.name > b.name
            end
        elseif sortBy == "class" then
            if sortAscending then
                return a.class < b.class
            else
                return a.class > b.class
            end
        elseif sortBy == "race" then
            if sortAscending then
                return a.race < b.race
            else
                return a.race > b.race
            end
        elseif sortBy == "gender" then
            if sortAscending then
                return a.gender < b.gender
            else
                return a.gender > b.gender
            end
        elseif sortBy == "guild" then
            if sortAscending then
                return a.guild < b.guild
            else
                return a.guild > b.guild
            end
        elseif sortBy == "kills" then
            if sortAscending then
                return a.kills < b.kills
            else
                return a.kills > b.kills
            end
        elseif sortBy == "lastKill" then
            if sortAscending then
                return a.lastKill < b.lastKill
            else
                return a.lastKill > b.lastKill
            end
        end

        -- Default to kills descending if no match
        return a.kills > b.kills
    end)

    -- Display entries
    for _, entry in ipairs(sortedEntries) do
        -- Name column
        local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        nameText:SetPoint("TOPLEFT", 10, yOffset)
        nameText:SetText(entry.name)
        nameText:SetWidth(colWidths.name)
        nameText:SetJustifyH("LEFT")

        -- Class column
        local classText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        classText:SetPoint("TOPLEFT", nameText, "TOPRIGHT", 0, 0)

        -- Convert class to title case (first letter capitalized, rest lowercase)
        local className = entry.class
        if className and className ~= "Unknown" then
            className = className:sub(1,1):upper() .. className:sub(2):lower()
        end

        classText:SetText(className)
        classText:SetWidth(colWidths.class)
        classText:SetJustifyH("LEFT")

        -- Set class color if available
        if RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class:upper()] then
            local color = RAID_CLASS_COLORS[entry.class:upper()]
            classText:SetTextColor(color.r, color.g, color.b)
        end

        -- Race column
        local raceText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        raceText:SetPoint("TOPLEFT", classText, "TOPRIGHT", 0, 0)

        -- Convert race to title case
        local raceName = entry.race
        if raceName and raceName ~= "Unknown" then
            raceName = raceName:sub(1,1):upper() .. raceName:sub(2):lower()
        end

        raceText:SetText(raceName)
        raceText:SetWidth(colWidths.race)
        raceText:SetJustifyH("LEFT")

        -- Gender column
        local genderText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        genderText:SetPoint("TOPLEFT", raceText, "TOPRIGHT", 0, 0)
        genderText:SetText(entry.gender)
        genderText:SetWidth(colWidths.gender)
        genderText:SetJustifyH("LEFT")

        -- Level column
        local levelText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        levelText:SetPoint("TOPLEFT", genderText, "TOPRIGHT", 0, 0)
        -- Show ?? for unknown level (-1)
        levelText:SetText(entry.level == -1 and "??" or tostring(entry.level))
        levelText:SetWidth(colWidths.level)
        levelText:SetJustifyH("LEFT")

        -- Guild column
        local guildText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        guildText:SetPoint("TOPLEFT", levelText, "TOPRIGHT", 0, 0)
        guildText:SetText(entry.guild)
        guildText:SetWidth(colWidths.guild)
        guildText:SetJustifyH("LEFT")

        -- Kills column
        local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        killsText:SetPoint("TOPLEFT", guildText, "TOPRIGHT", 0, 0)
        killsText:SetText(tostring(entry.kills))
        killsText:SetWidth(colWidths.kills)
        killsText:SetJustifyH("LEFT")

        -- Last kill column
        local lastKillText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lastKillText:SetPoint("TOPLEFT", killsText, "TOPRIGHT", 0, 0)
        lastKillText:SetText(entry.lastKill)
        lastKillText:SetWidth(colWidths.lastKill)
        lastKillText:SetJustifyH("LEFT")

        yOffset = yOffset - 16
        count = count + 1
    end

    -- Adjust content height based on number of entries
    content:SetHeight(math.max((-yOffset + 20), PKA_KILLS_FRAME_HEIGHT - 50))
end

function PKA_CreateKillStatsFrame()
    if killStatsFrame then
        killStatsFrame:Show()
        RefreshKillList()
        return
    end

    -- Create main frame
    killStatsFrame = CreateFrame("Frame", "PKAKillStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    killStatsFrame:SetSize(PKA_KILLS_FRAME_WIDTH, PKA_KILLS_FRAME_HEIGHT)
    killStatsFrame:SetPoint("CENTER")
    killStatsFrame:SetMovable(true)
    killStatsFrame:EnableMouse(true)
    killStatsFrame:RegisterForDrag("LeftButton")
    killStatsFrame:SetScript("OnDragStart", killStatsFrame.StartMoving)
    killStatsFrame:SetScript("OnDragStop", killStatsFrame.StopMovingOrSizing)

    -- Make frame closeable with ESC
    table.insert(UISpecialFrames, "PKAKillStatsFrame")

    -- Title
    killStatsFrame.TitleText:SetText("Player Kill Statistics")

    -- Create scroll frame with adjusted bottom padding for search bar
    local scrollFrame = CreateFrame("ScrollFrame", nil, killStatsFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 35)  -- Increased bottom padding for search bar

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(PKA_KILLS_FRAME_WIDTH - 40, PKA_KILLS_FRAME_HEIGHT * 2)
    scrollFrame:SetScrollChild(content)
    killStatsFrame.content = content

    -- Create search bar background
    local searchBg = CreateFrame("Frame", nil, killStatsFrame, "BackdropTemplate")
    searchBg:SetPoint("BOTTOMLEFT", 1, 1)
    searchBg:SetPoint("BOTTOMRIGHT", -1, 1)
    searchBg:SetHeight(30)

    -- Use the correct backdrop method for Classic
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
        -- For very old clients that lack backdroptemplate
        local bg = searchBg:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.4)
    end

    -- Add search label
    local searchLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", searchBg, "LEFT", 8, 0)
    searchLabel:SetText("Search Player:")
    searchLabel:SetTextColor(1, 0.82, 0)  -- Gold color

    -- Create a simple EditBox instead of SearchBoxTemplate
    local searchBox = CreateFrame("EditBox", nil, searchBg)
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetFontObject("ChatFontNormal")

    -- Create a background and border for the search box
    local searchBoxBg = searchBox:CreateTexture(nil, "BACKGROUND")
    searchBoxBg:SetAllPoints(true)
    searchBoxBg:SetColorTexture(0, 0, 0, 0.5)

    -- Create border elements
    local border = {}
    border.top = searchBox:CreateTexture(nil, "BACKGROUND")
    border.top:SetHeight(1)
    border.top:SetPoint("TOPLEFT", searchBox, "TOPLEFT", -1, 1)
    border.top:SetPoint("TOPRIGHT", searchBox, "TOPRIGHT", 1, 1)
    border.top:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.bottom = searchBox:CreateTexture(nil, "BACKGROUND")
    border.bottom:SetHeight(1)
    border.bottom:SetPoint("BOTTOMLEFT", searchBox, "BOTTOMLEFT", -1, -1)
    border.bottom:SetPoint("BOTTOMRIGHT", searchBox, "BOTTOMRIGHT", 1, -1)
    border.bottom:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.left = searchBox:CreateTexture(nil, "BACKGROUND")
    border.left:SetWidth(1)
    border.left:SetPoint("TOPLEFT", border.top, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", border.bottom, "BOTTOMLEFT", 0, 0)
    border.left:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    border.right = searchBox:CreateTexture(nil, "BACKGROUND")
    border.right:SetWidth(1)
    border.right:SetPoint("TOPRIGHT", border.top, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", border.bottom, "BOTTOMRIGHT", 0, 0)
    border.right:SetColorTexture(0.3, 0.3, 0.3, 0.8)

    -- Add padding
    searchBox:SetTextInsets(5, 5, 2, 2)

    -- Update search functionality
    local function updateSearch()
        searchText = searchBox:GetText():lower()
        RefreshKillList()
    end

    searchBox:SetScript("OnTextChanged", function(self)
        -- This will trigger for any text change (typing or deleting)
        updateSearch()
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        -- Highlight text when gaining focus
        self:HighlightText()
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        -- Remove highlight when losing focus
        self:HighlightText(0, 0)
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        searchText = ""
        RefreshKillList()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Initialize with empty search
    searchBox:SetText("")
    searchText = ""

    -- Initial refresh to show all entries
    RefreshKillList()
end
