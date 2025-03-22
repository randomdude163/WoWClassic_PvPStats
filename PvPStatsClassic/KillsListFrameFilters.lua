PSC_SearchText = ""
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
        GameTooltip:SetText("Level filter")
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

local function PSC_CreateEditBox(parent, anchorTo)
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

local function PSC_SetupSearchBoxScripts(searchBox)
    searchBox:SetScript("OnTextChanged", function(self)
        PSC_SearchText = self:GetText():lower()
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
        PSC_SearchText = ""
        RefreshKillsListFrame()
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Player/Guild filter")
        GameTooltip:AddLine("Type to filter by player name or guild", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    searchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateClassSearchBox(parent, anchorTo)
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

local function PSC_SetupClassSearchBoxScripts(classSearchBox)
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
        GameTooltip:SetText("Class filter")
        GameTooltip:AddLine("Type to filter by class name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    classSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateRaceSearchBox(parent, anchorTo)
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

local function PSC_SetupRaceSearchBoxScripts(raceSearchBox)
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
        GameTooltip:SetText("Race filter")
        GameTooltip:AddLine("Type to filter by race name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    raceSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateGenderSearchBox(parent, anchorTo)
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

local function PSC_SetupGenderSearchBoxScripts(genderSearchBox)
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
        GameTooltip:SetText("Gender filter")
        GameTooltip:AddLine("Type to filter by gender", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    genderSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateZoneSearchBox(parent, anchorTo)
    local zoneSearchBox = CreateFrame("EditBox", nil, parent)
    zoneSearchBox:SetSize(140, 20)
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

local function PSC_SetupZoneSearchBoxScripts(zoneSearchBox)
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
        GameTooltip:SetText("Zone filter")
        GameTooltip:AddLine("Type to filter by zone name", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    zoneSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateRankSearchBox(parent, anchorTo)
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

local function PSC_SetupRankSearchBoxScripts(rankSearchBox)
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
        GameTooltip:SetText("Rank filter")
        GameTooltip:AddLine("Enter a single rank (e.g. 8)", 1, 1, 1, true)
        GameTooltip:AddLine("Or a range (e.g. 5-10)", 1, 1, 1, true)
        GameTooltip:AddLine("Press ESC to clear filter", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)

    rankSearchBox:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function PSC_CreateSearchBackground(parent)
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

-- Helper function to add or update a player entry in the entries table
local function AddOrUpdatePlayerEntry(playerNameMap, entries, name, entry)
    if not playerNameMap[name] then
        playerNameMap[name] = entry
        table.insert(entries, entry)
    else
        local existingEntry = playerNameMap[name]
        existingEntry.kills = existingEntry.kills + entry.kills

        -- Keep the most recent kill timestamp and data
        if entry.lastKill > (existingEntry.lastKill or 0) then
            existingEntry.lastKill = entry.lastKill
            existingEntry.zone = entry.zone
            existingEntry.levelDisplay = entry.levelDisplay
            existingEntry.rank = entry.rank
        end

        -- Store details of all kills for the detail view
        if not existingEntry.killHistory then
            existingEntry.killHistory = {}
        end

        if not entry.includedInHistory then
            table.insert(existingEntry.killHistory, {
                level = entry.levelDisplay,
                zone = entry.zone,
                timestamp = entry.lastKill,
                rank = entry.rank,
                kills = entry.kills
            })
            entry.includedInHistory = true
        end
    end
end

-- Collect death data for the current character
local function CollectDeathData()
    local deathDataByPlayer = {}
    local characterKey = PSC_GetCharacterKey()

    if PSC_DB.PvPLossCounts and PSC_DB.PvPLossCounts[characterKey] then
        local lossData = PSC_DB.PvPLossCounts[characterKey]

        for killerName, deathData in pairs(lossData.Deaths or {}) do
            deathDataByPlayer[killerName] = deathData
        end
    end

    return deathDataByPlayer
end

-- Process and collect all players you have killed
local function ProcessKilledPlayers(searchText, playerNameMap, entries)
    local charactersToProcess = GetCharactersToProcessForStatistics()

    for charKey, charData in pairs(charactersToProcess) do
        for nameWithLevel, killData in pairs(charData.Kills or {}) do
            local name = string.match(nameWithLevel, "(.-)%:")
            if name then
                local level = tonumber(string.match(nameWithLevel, ":(%d+)") or "-1") or -1

                -- Get player info from cache if available
                local playerInfo = PSC_DB.PlayerInfoCache[name] or {}
                local playerClass = playerInfo.class or "Unknown"
                local playerRace = playerInfo.race or "Unknown"
                local playerGender = playerInfo.gender or "Unknown"
                local playerGuild = playerInfo.guild or ""
                local playerRank = playerInfo.rank or 0

                -- Only add if matches search criteria
                if searchText == "" or
                   name:lower():find(searchText, 1, true) or
                   playerClass:lower():find(searchText, 1, true) or
                   playerRace:lower():find(searchText, 1, true) or
                   playerGuild:lower():find(searchText, 1, true) then

                    -- Convert lastKill to number to ensure it's properly handled
                    local lastKillTimestamp = tonumber(killData.lastKill) or 0

                    local entry = {
                        name = name,
                        class = playerClass,
                        race = playerRace,
                        gender = playerGender,
                        levelDisplay = playerInfo.level or level,
                        rank = playerRank,
                        guild = playerGuild,
                        zone = killData.zone or "Unknown",
                        kills = killData.kills or 0,
                        lastKill = lastKillTimestamp, -- Make sure it's a number
                        levelAtKill = level,
                        originalKillData = killData
                    }

                    AddOrUpdatePlayerEntry(playerNameMap, entries, name, entry)
                end
            end
        end
    end
end

-- Process players who have killed you but you haven't killed
local function ProcessEnemyKillers(searchText, playerNameMap, entries, deathDataByPlayer)
    for killerName, deathData in pairs(deathDataByPlayer) do
        if not playerNameMap[killerName] then
            local playerInfo = PSC_DB.PlayerInfoCache[killerName] or {}
            local playerClass = playerInfo.class or "Unknown"
            local playerRace = playerInfo.race or "Unknown"
            local playerGender = playerInfo.gender or "Unknown"
            local playerGuild = playerInfo.guild or ""
            local playerLevel = tonumber(playerInfo.level) or -1  -- Ensure it's a number
            local playerRank = playerInfo.rank or 0

            -- Find the most recent zone from death locations
            local zone = "Unknown"
            local lastKill = 0

            if deathData.deathLocations and #deathData.deathLocations > 0 then
                -- Sort death locations by timestamp descending (most recent first)
                table.sort(deathData.deathLocations, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)

                -- Get zone from most recent death location
                zone = deathData.deathLocations[1].zone or zone
                lastKill = deathData.deathLocations[1].timestamp or lastKill
            end

            -- Only add if matches search criteria
            if searchText == "" or
               killerName:lower():find(searchText, 1, true) or
               playerClass:lower():find(searchText, 1, true) or
               playerRace:lower():find(searchText, 1, true) or
               playerGuild:lower():find(searchText, 1, true) then

                local entry = {
                    name = killerName,
                    class = playerClass,
                    race = playerRace,
                    gender = playerGender,
                    levelDisplay = playerLevel,  -- Store as number for consistent sorting
                    rank = playerRank,
                    guild = playerGuild,
                    zone = zone,
                    kills = 0,
                    lastKill = lastKill,
                    deaths = deathData.deaths or 0,
                    deathHistory = deathData.deathLocations or {}
                }

                playerNameMap[killerName] = entry
                table.insert(entries, entry)
            end
        end
    end
end

-- Function to count assists from a player
local function CountPlayerAssists(playerName, deathDataByPlayer)
    local assistCount = 0

    for _, deathData in pairs(deathDataByPlayer) do
        if deathData.deathLocations then
            for _, location in ipairs(deathData.deathLocations) do
                if location.assisters then
                    for _, assister in ipairs(location.assisters) do
                        if assister.name == playerName then
                            assistCount = assistCount + 1
                        end
                    end
                end
            end
        end
    end

    return assistCount
end

-- Process players who have only assisted in kills but never directly killed you
local function ProcessAssistOnlyPlayers(searchText, playerNameMap, entries, deathDataByPlayer)
    -- Build a list of players who have assisted in kills
    local assistPlayerData = {}

    for _, deathData in pairs(deathDataByPlayer) do
        if deathData.deathLocations then
            for _, location in ipairs(deathData.deathLocations) do
                if location.assisters then
                    for _, assister in ipairs(location.assisters) do
                        local assisterName = assister.name

                        -- Skip if already processed
                        if not playerNameMap[assisterName] then
                            if not assistPlayerData[assisterName] then
                                assistPlayerData[assisterName] = {
                                    assists = 0,
                                    lastAssist = 0,
                                    zone = "Unknown"
                                }
                            end

                            assistPlayerData[assisterName].assists = assistPlayerData[assisterName].assists + 1

                            -- Update latest assist timestamp and zone if more recent
                            if (location.timestamp or 0) > assistPlayerData[assisterName].lastAssist then
                                assistPlayerData[assisterName].lastAssist = location.timestamp or 0
                                assistPlayerData[assisterName].zone = location.zone or "Unknown"
                            end
                        end
                    end
                end
            end
        end
    end

    -- Create entries for assist-only players
    for assisterName, assistData in pairs(assistPlayerData) do
        -- Skip if already added from kills or deaths
        if not playerNameMap[assisterName] then
            local playerInfo = PSC_DB.PlayerInfoCache[assisterName] or {}
            local playerClass = playerInfo.class or "Unknown"
            local playerRace = playerInfo.race or "Unknown"
            local playerGender = playerInfo.gender or "Unknown"
            local playerGuild = playerInfo.guild or ""
            local playerLevel = tonumber(playerInfo.level) or -1
            local playerRank = playerInfo.rank or 0

            -- Only add if matches search criteria
            if searchText == "" or
               assisterName:lower():find(searchText, 1, true) or
               playerClass:lower():find(searchText, 1, true) or
               playerRace:lower():find(searchText, 1, true) or
               playerGuild:lower():find(searchText, 1, true) then

                local entry = {
                    name = assisterName,
                    class = playerClass,
                    race = playerRace,
                    gender = playerGender,
                    levelDisplay = playerLevel,
                    rank = playerRank,
                    guild = playerGuild,
                    zone = assistData.zone,
                    kills = 0,
                    deaths = 0,
                    assists = assistData.assists,
                    lastKill = assistData.lastAssist  -- Use assist timestamp for sorting
                }

                playerNameMap[assisterName] = entry
                table.insert(entries, entry)
            end
        end
    end
end

-- Sort entries based on current sort settings
local function SortPlayerEntries(entries)
    if PSC_SortKillsListBy then
        table.sort(entries, function(a, b)
            local aValue = a[PSC_SortKillsListBy]
            local bValue = b[PSC_SortKillsListBy]

            -- Special handling for level sorting - convert to numbers for proper comparison
            if PSC_SortKillsListBy == "levelDisplay" then
                local aLevel = tonumber(aValue) or -1
                local bLevel = tonumber(bValue) or -1

                if PSC_SortKillsListAscending then
                    return aLevel < bLevel
                else
                    return aLevel > bLevel
                end
            end

            -- Special case for numeric values vs nil
            if type(aValue) == "number" and type(bValue) == "number" then
                if PSC_SortKillsListAscending then
                    return aValue < bValue
                else
                    return aValue > bValue
                end
            end

            -- Handle string comparison
            if PSC_SortKillsListAscending then
                return tostring(aValue or "") < tostring(bValue or "")
            else
                return tostring(aValue or "") > tostring(bValue or "")
            end
        end)
    end

    return entries
end

-- Main function to filter and sort entries
function PSC_FilterAndSortEntries()
    local entries = {}
    local playerNameMap = {}
    local searchText = PSC_SearchText or ""
    searchText = searchText:lower()

    -- Step 1: Collect death data
    local deathDataByPlayer = CollectDeathData()

    -- Step 2: Process players you've killed
    ProcessKilledPlayers(searchText, playerNameMap, entries)

    -- Step 3: Process players who killed you but you haven't killed
    ProcessEnemyKillers(searchText, playerNameMap, entries, deathDataByPlayer)

    -- Step 4: Process players who have only assisted in kills but never directly killed you
    ProcessAssistOnlyPlayers(searchText, playerNameMap, entries, deathDataByPlayer)

    -- Step 5: Add death counts and assists counts to all entries
    for i, entry in ipairs(entries) do
        -- Add death data
        local deathData = deathDataByPlayer[entry.name]
        entry.deaths = deathData and deathData.deaths or 0
        entry.deathHistory = deathData and deathData.deathLocations or {}

        -- Add assists data
        entry.assists = CountPlayerAssists(entry.name, deathDataByPlayer)
    end

    -- Step 6: Sort entries
    return SortPlayerEntries(entries)
end

function PSC_CreateSearchBar(frame)
    local searchBg = PSC_CreateSearchBackground(frame)

    searchBg:SetHeight(40)

    local row1 = CreateFrame("Frame", nil, searchBg)
    row1:SetSize(searchBg:GetWidth(), 20)
    row1:SetPoint("TOP", searchBg, "TOP", 0, -10)

    local searchLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("LEFT", row1, "LEFT", 10, 0)
    searchLabel:SetText("Player/Guild:")
    searchLabel:SetTextColor(1, 0.82, 0)

    local searchBox = PSC_CreateEditBox(searchBg, searchLabel)
    searchBox:SetSize(120, 20)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 5, 0)
    PSC_SetupSearchBoxScripts(searchBox)
    searchBox:SetText("")
    PSC_SearchText = ""

    local classLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    classLabel:SetPoint("LEFT", searchBox, "RIGHT", 15, 0)
    classLabel:SetText("Class:")
    classLabel:SetTextColor(1, 0.82, 0)

    local classSearchBox = PSC_CreateClassSearchBox(searchBg, classLabel)
    classSearchBox:SetSize(80, 20)
    classSearchBox:SetPoint("LEFT", classLabel, "RIGHT", 5, 0)
    PSC_SetupClassSearchBoxScripts(classSearchBox)
    classSearchBox:SetText("")
    classSearchText = ""

    local raceLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    raceLabel:SetPoint("LEFT", classSearchBox, "RIGHT", 15, 0)
    raceLabel:SetText("Race:")
    raceLabel:SetTextColor(1, 0.82, 0)

    local raceSearchBox = PSC_CreateRaceSearchBox(searchBg, raceLabel)
    raceSearchBox:SetSize(80, 20)
    raceSearchBox:SetPoint("LEFT", raceLabel, "RIGHT", 5, 0)
    PSC_SetupRaceSearchBoxScripts(raceSearchBox)
    raceSearchBox:SetText("")
    raceSearchText = ""

    local genderLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genderLabel:SetPoint("LEFT", raceSearchBox, "RIGHT", 15, 0)
    genderLabel:SetText("Gender:")
    genderLabel:SetTextColor(1, 0.82, 0)

    local genderSearchBox = PSC_CreateGenderSearchBox(searchBg, genderLabel)
    genderSearchBox:SetSize(55, 20)
    genderSearchBox:SetPoint("LEFT", genderLabel, "RIGHT", 5, 0)
    PSC_SetupGenderSearchBoxScripts(genderSearchBox)
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

    local rankSearchBox = PSC_CreateRankSearchBox(searchBg, rankLabel)
    rankSearchBox:SetSize(50, 20)
    rankSearchBox:SetPoint("LEFT", rankLabel, "RIGHT", 5, 0)
    PSC_SetupRankSearchBoxScripts(rankSearchBox)
    rankSearchBox:SetText("")
    rankSearchText = ""

    local zoneLabel = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zoneLabel:SetPoint("LEFT", rankSearchBox, "RIGHT", 15, 0)
    zoneLabel:SetText("Zone:")
    zoneLabel:SetTextColor(1, 0.82, 0)

    local zoneSearchBox = PSC_CreateZoneSearchBox(searchBg, zoneLabel)
    zoneSearchBox:SetSize(130, 20)
    zoneSearchBox:SetPoint("LEFT", zoneLabel, "RIGHT", 5, 0)
    PSC_SetupZoneSearchBoxScripts(zoneSearchBox)
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

function PSC_SetKillListSearch(text, levelText, classText, raceText, genderText, zoneText, resetOtherFilters)
    if PSC_KillsListFrame then
        if resetOtherFilters then
            PSC_KillsListFrame.searchBox:SetText("")
            PSC_SearchText = ""
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
            PSC_SearchText = text:lower()
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
            PSC_SearchText = ""
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
            PSC_SearchText = ""
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
