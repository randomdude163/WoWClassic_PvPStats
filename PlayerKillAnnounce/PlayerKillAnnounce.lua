-- This AddOn counts the number of player kills since login and announces each kill
-- in the party chat. You can adjust the kill announce message to your liking.
-- "Enemyplayername" will be replaced with the name of the player that was killed.
PlayerKillMessageDefault = "Enemyplayername killed!"
------------------------------------------------------------------------

local playerKillAnnounceFrame = CreateFrame("Frame", "PlayerKillAnnounceFrame", UIParent)
local EnableKillAnnounce = true
local KillAnnounceMessage = PlayerKillMessageDefault
local KillCounts = {}
local killStatsFrame = nil
local KILLS_FRAME_WIDTH = 450  -- Increased from 400 to accommodate wider columns
local KILLS_FRAME_HEIGHT = 500
local searchText = ""
local searchBox = nil

-- Sorting variables
local sortBy = "kills"  -- Default sort by kills
local sortAscending = false  -- Default descending (highest kills first)

local CHAT_MESSAGE_R = 1.0
local CHAT_MESSAGE_G = 1.0
local CHAT_MESSAGE_B = 0.74

-- Player info cache to store data we collect from various sources
local PlayerInfoCache = {}

-- Function to update player info cache
local function UpdatePlayerInfoCache(name, guid, level, class)
    if not name then return end

    PlayerInfoCache[name] = PlayerInfoCache[name] or {}

    -- Only update fields if the new information is valid
    if guid and guid ~= "" then
        PlayerInfoCache[name].guid = guid
    end

    if level and level > 0 then
        PlayerInfoCache[name].level = level
    end

    if class and class ~= "" then
        PlayerInfoCache[name].class = class
    end

    -- For debugging
    -- print("Updated cache for " .. name .. ": Level " .. (PlayerInfoCache[name].level or "unknown") .. ", Class " .. (PlayerInfoCache[name].class or "unknown"))
end

-- Function to collect player info from unit
local function CollectPlayerInfo(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end

    local name = UnitName(unit)
    if not name then return end

    local guid = UnitGUID(unit)
    local level = UnitLevel(unit)
    local _, englishClass = UnitClass(unit)

    UpdatePlayerInfoCache(name, guid, level, englishClass)
end

-- Event handlers for updating player info cache
local function OnPlayerTargetChanged()
    CollectPlayerInfo("target")
    CollectPlayerInfo("targettarget")
end

local function OnUpdateMouseoverUnit()
    CollectPlayerInfo("mouseover")
end

-- Function to get best available player info
local function GetBestPlayerInfo(name, guid)
    local level = 0
    local class = "Unknown"

    -- Check if we have cached info
    if PlayerInfoCache[name] then
        level = PlayerInfoCache[name].level or 0
        class = PlayerInfoCache[name].class or "Unknown"
    end

    -- If we still don't have valid info, try other methods
    if level == 0 or class == "Unknown" then
        -- Check target and mouseover in case it's the same player
        if UnitExists("target") and UnitName("target") == name then
            level = UnitLevel("target") or level
            local _, englishClass = UnitClass("target")
            class = englishClass or class
        elseif UnitExists("mouseover") and UnitName("mouseover") == name then
            level = UnitLevel("mouseover") or level
            local _, englishClass = UnitClass("mouseover")
            class = englishClass or class
        end

        -- Last resort - try to get from GUID
        if guid and guid ~= "" then
            local _, englishClass = GetPlayerInfoByGUID(guid)
            if englishClass then
                class = englishClass
            end
        end
    end

    -- Default to level 1 if we still couldn't detect it
    level = level > 0 and level or 1

    return level, class
end

local function SaveSettings()
    PlayerKillAnnounceDB.EnableKillAnnounce = EnableKillAnnounce
    PlayerKillAnnounceDB.KillAnnounceMessage = KillAnnounceMessage
    PlayerKillAnnounceDB.KillCounts = KillCounts
end

local function LoadSettings()
    if PlayerKillAnnounceDB then
        EnableKillAnnounce = PlayerKillAnnounceDB.EnableKillAnnounce or true
        KillAnnounceMessage = PlayerKillAnnounceDB.KillAnnounceMessage or PlayerKillMessageDefault

        -- Handle upgrade path for older versions without level tracking
        if PlayerKillAnnounceDB.KillCounts then
            local needsUpgrade = false
            for name, data in pairs(PlayerKillAnnounceDB.KillCounts) do
                if not string.find(name, ":") then
                    needsUpgrade = true
                    break
                end
            end

            if needsUpgrade then
                local upgradedKills = {}
                for name, data in pairs(PlayerKillAnnounceDB.KillCounts) do
                    -- Add with level 0 (unknown) for older entries
                    local nameWithLevel = name .. ":0"
                    upgradedKills[nameWithLevel] = data
                end
                PlayerKillAnnounceDB.KillCounts = upgradedKills
            end
        end

        KillCounts = PlayerKillAnnounceDB.KillCounts or {}

        -- If kill stats frame exists, refresh it
        if killStatsFrame then
            RefreshKillList()
        end
    else
        PlayerKillAnnounceDB = {
            EnableKillAnnounce = true,
            KillAnnounceMessage = PlayerKillMessageDefault,
            KillCounts = {}
        }
        KillCounts = PlayerKillAnnounceDB.KillCounts
    end
end

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

    -- Column widths - adjusted to include level
    local colWidths = {
        name = 85,      -- Player names (max 12 chars)
        class = 80,     -- Class name
        level = 40,     -- New column for level
        kills = 60,     -- Kill count
        lastKill = 155  -- Slightly reduced to make room for level column
    }

    -- Create clickable header buttons
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

    -- Level Column Header
    local levelHeaderBtn = CreateFrame("Button", nil, content)
    levelHeaderBtn:SetSize(colWidths.level, 24)
    levelHeaderBtn:SetPoint("TOPLEFT", classHeaderBtn, "TOPRIGHT", 0, 0)
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

    -- Kills Column Header
    local killsHeaderBtn = CreateFrame("Button", nil, content)
    killsHeaderBtn:SetSize(colWidths.kills, 24)
    killsHeaderBtn:SetPoint("TOPLEFT", levelHeaderBtn, "TOPRIGHT", 0, 0)
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

    levelHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    levelHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    killsHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    killsHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    lastKillHeaderBtn:SetScript("OnEnter", function(self) SetHeaderButtonHighlight(self, true) end)
    lastKillHeaderBtn:SetScript("OnLeave", function(self) SetHeaderButtonHighlight(self, false) end)

    local yOffset = -30
    local count = 0

    -- Sort and filter entries
    local sortedEntries = {}
    for nameWithLevel, data in pairs(KillCounts) do
        -- Extract the player name and level from the composite key
        local name, level = strsplit(":", nameWithLevel)
        local nameLower = name:lower()

        -- Only add entries that match the search text
        if searchText == "" or nameLower:find(searchText, 1, true) then
            table.insert(sortedEntries, {
                nameWithLevel = nameWithLevel, -- Store composite key for reference
                name = name,
                class = data.class or "Unknown",
                level = tonumber(level) or 0,
                kills = data.kills or 0,
                lastKill = data.lastKill or "Unknown"
            })
        end
    end

    -- Sort according to selected column and direction
    table.sort(sortedEntries, function(a, b)
        -- Handle different sorting columns
        if sortBy == "name" then
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
        elseif sortBy == "level" then
            if sortAscending then
                return a.level < b.level
            else
                return a.level > b.level
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

        -- Level column
        local levelText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        levelText:SetPoint("TOPLEFT", classText, "TOPRIGHT", 0, 0)
        levelText:SetText(tostring(entry.level))
        levelText:SetWidth(colWidths.level)
        levelText:SetJustifyH("LEFT")

        -- Kills column
        local killsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        killsText:SetPoint("TOPLEFT", levelText, "TOPRIGHT", 0, 0)
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
    content:SetHeight(math.max((-yOffset + 20), KILLS_FRAME_HEIGHT - 50))
end

local function CreateKillStatsFrame()
    if killStatsFrame then
        killStatsFrame:Show()
        RefreshKillList()
        return
    end

    -- Create main frame
    killStatsFrame = CreateFrame("Frame", "PKAKillStatsFrame", UIParent, "BasicFrameTemplateWithInset")
    killStatsFrame:SetSize(KILLS_FRAME_WIDTH, KILLS_FRAME_HEIGHT)
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
    content:SetSize(KILLS_FRAME_WIDTH - 40, KILLS_FRAME_HEIGHT * 2)
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

-- Enhanced combat log event handler
local function HandleCombatLogEvent()
    local timestamp, combatEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo()

    -- Collect info about all players we see in the combat log
    if sourceName and bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        -- Try to update our cache with source player info
        -- (won't set level/class unless we already know it)
        UpdatePlayerInfoCache(sourceName, sourceGUID, nil, nil)
    end

    if destName and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER then
        -- Try to update our cache with destination player info
        -- (won't set level/class unless we already know it)
        UpdatePlayerInfoCache(destName, destGUID, nil, nil)
    end

    if combatEvent == "UNIT_DIED" then
        if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER and
           bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE then

            -- Get the best available player info using our cache and other methods
            local level, englishClass = GetBestPlayerInfo(destName, destGUID)

            -- Create composite key with name and level
            local nameWithLevel = destName .. ":" .. level

            -- Initialize or update kill data
            if not KillCounts[nameWithLevel] then
                KillCounts[nameWithLevel] = {
                    kills = 0,
                    class = englishClass,
                    lastKill = ""
                }
            end

            -- Update kill count and timestamp
            KillCounts[nameWithLevel].kills = KillCounts[nameWithLevel].kills + 1
            KillCounts[nameWithLevel].lastKill = date("%Y-%m-%d %H:%M:%S")

            -- Announce the kill to party chat
            if EnableKillAnnounce and IsInGroup() then
                local killMessage = string.gsub(KillAnnounceMessage, "Enemyplayername", destName)
                killMessage = killMessage .. " (Level " .. level .. ") x" .. KillCounts[nameWithLevel].kills
                SendChatMessage(killMessage, "PARTY")
            end

            SaveSettings()

            -- Debug message for local confirmation
            print("Killed: " .. destName .. " (Level " .. level .. ", " .. englishClass .. ") - Total kills: " .. KillCounts[nameWithLevel].kills)
        end
    end
end

-- Enhanced event registration to include new events for player info collection
local function RegisterEvents()
    playerKillAnnounceFrame:RegisterEvent("PLAYER_LOGIN")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    playerKillAnnounceFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    playerKillAnnounceFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    playerKillAnnounceFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

    playerKillAnnounceFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            LoadSettings()
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            HandleCombatLogEvent()
        elseif event == "PLAYER_TARGET_CHANGED" then
            OnPlayerTargetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            OnUpdateMouseoverUnit()
        end
    end)
end

local function PrintSlashCommandUsage()
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka toggle", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka killmessage <message>", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("The word Enemyplayername will be replaced with the name of the player " ..
                                      "that was killed. For example: Enemyplayername killed!", CHAT_MESSAGE_R,
        CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka stats", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /pka status", CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    -- Remove the kills command from help
end

local function PrintStatus()
    local statusMessage = "Kill announce messages are " .. (EnableKillAnnounce and "ENABLED" or "DISABLED") .. "."
    DEFAULT_CHAT_FRAME:AddMessage(statusMessage, CHAT_MESSAGE_R, CHAT_MESSAGE_G, CHAT_MESSAGE_B)
    DEFAULT_CHAT_FRAME:AddMessage("Current kill announce message: " .. KillAnnounceMessage, CHAT_MESSAGE_R,
        CHAT_MESSAGE_G, CHAT_MESSAGE_B)
end

local function HandleToggleCommand()
    EnableKillAnnounce = not EnableKillAnnounce
    SaveSettings()
    if EnableKillAnnounce then
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now ENABLED.", CHAT_MESSAGE_R, CHAT_MESSAGE_G,
            CHAT_MESSAGE_B)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Kill announce messages are now DISABLED.", CHAT_MESSAGE_R, CHAT_MESSAGE_G,
            CHAT_MESSAGE_B)
    end
end

local function HandleSetMessageCommand(message)
    KillAnnounceMessage = message
    -- print("Setting KillAnnounceMessage to:", KillAnnounceMessage)
    SaveSettings()
    DEFAULT_CHAT_FRAME:AddMessage("Kill announce message set to: " .. KillAnnounceMessage, CHAT_MESSAGE_R,
        CHAT_MESSAGE_G, CHAT_MESSAGE_B)
end

local function RegisterSlashCommands()
    SLASH_PLAYERKILLANNOUNCE1 = "/playerkillannounce"
    SLASH_PLAYERKILLANNOUNCE2 = "/pka"
    SlashCmdList["PLAYERKILLANNOUNCE"] = function(msg)
        local command, rest = msg:match("^(%S*)%s*(.-)$")
        command = string.lower(command or "")

        if command == "" then
            PrintSlashCommandUsage()
        elseif command == "toggle" then
            HandleToggleCommand()
        elseif command == "killmessage" and rest and rest ~= "" then
            HandleSetMessageCommand(rest)
        elseif command == "status" then
            PrintStatus()
        elseif command == "stats" then
            -- Open the kill stats window
            CreateKillStatsFrame()
        else
            PrintSlashCommandUsage()
        end
    end
end

local function Main()
    RegisterEvents()
    RegisterSlashCommands()
end

Main()
