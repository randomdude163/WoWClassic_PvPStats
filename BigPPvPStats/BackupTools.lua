local addonName, PVPSC = ...

-- ============================================================
-- Deep copy
-- ============================================================

-- Recursively copies a plain data table (kill counts, achievement progress, etc).
-- Not safe for tables containing functions/frames - only use on SavedVariables data.
function BPP_DeepCopyValue(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do
        copy[BPP_DeepCopyValue(k, seen)] = BPP_DeepCopyValue(v, seen)
    end
    return copy
end

-- ============================================================
-- Rolling in-DB snapshots
--
-- Keeps up to BPP_MAX_ROLLING_BACKUPS copies of this character's kill and
-- achievement data inside BPP_DB itself, taken at most once per real day
-- (checked on logout). This is a safety net against an addon bug, a bad
-- update, or test commands (/bpp registerkill etc.) corrupting your live
-- stats - restorable in-game with /bpp restore.
--
-- It is NOT a substitute for a real backup: the snapshot lives inside the
-- same SavedVariables file it's protecting, so it won't survive that file
-- being deleted or corrupted outright. For an off-file copy, use /bpp export.
-- ============================================================

BPP_MAX_ROLLING_BACKUPS = 3

function BPP_CreateRollingBackupSnapshot()
    if not BPP_DB or not BPP_DB.PlayerKillCounts then
        return
    end

    local characterKey = BPP_GetCharacterKey()
    local characterData = BPP_DB.PlayerKillCounts.Characters and BPP_DB.PlayerKillCounts.Characters[characterKey]
    if not characterData then
        return
    end

    BPP_DB.RollingBackups = BPP_DB.RollingBackups or {}
    local backups = BPP_DB.RollingBackups[characterKey] or {}
    BPP_DB.RollingBackups[characterKey] = backups

    local today = date("%Y-%m-%d")
    if backups[1] and backups[1].date == today then
        return
    end

    table.insert(backups, 1, {
        date = today,
        timestamp = time(),
        characterData = BPP_DeepCopyValue(characterData),
        characterAchievements = BPP_DB.CharacterAchievements and BPP_DeepCopyValue(BPP_DB.CharacterAchievements[characterKey]) or nil,
    })

    while #backups > BPP_MAX_ROLLING_BACKUPS do
        table.remove(backups)
    end
end

function BPP_ListRollingBackups()
    local characterKey = BPP_GetCharacterKey()
    local backups = BPP_DB.RollingBackups and BPP_DB.RollingBackups[characterKey]
    if not backups or #backups == 0 then
        BPP_Print("No backups saved yet. One is taken automatically on logout (at most once per day).")
        return
    end

    BPP_Print("Available backups for " .. characterKey .. " (most recent first):")
    for i, snapshot in ipairs(backups) do
        BPP_Print("  [" .. i .. "] " .. snapshot.date)
    end
    BPP_Print("Restore one with /bpp restore <number>")
end

-- index 1 = most recent snapshot, 2 = the one before that, etc.
function BPP_RestoreRollingBackupSnapshot(index)
    index = tonumber(index) or 1
    local characterKey = BPP_GetCharacterKey()
    local backups = BPP_DB.RollingBackups and BPP_DB.RollingBackups[characterKey]
    local snapshot = backups and backups[index]
    if not snapshot then
        BPP_Print("No backup found at index " .. index .. ". Use /bpp backups to list available snapshots.")
        return false
    end

    BPP_DB.PlayerKillCounts.Characters[characterKey] = BPP_DeepCopyValue(snapshot.characterData)
    if snapshot.characterAchievements then
        BPP_DB.CharacterAchievements = BPP_DB.CharacterAchievements or {}
        BPP_DB.CharacterAchievements[characterKey] = BPP_DeepCopyValue(snapshot.characterAchievements)
    end

    BPP_Print("Restored backup from " .. snapshot.date .. ". Type /reload to refresh any open windows.")
    return true
end

-- ============================================================
-- Export / Import (copy-paste text, lives outside the SavedVariables file
-- once you paste it somewhere else - the only backup that survives losing
-- the file itself)
-- ============================================================

function BPP_BuildExportText()
    local characterKey = BPP_GetCharacterKey()
    local payload = {
        bppExportVersion = 1,
        characterKey = characterKey,
        characterData = BPP_DB.PlayerKillCounts.Characters[characterKey],
        characterAchievements = BPP_DB.CharacterAchievements and BPP_DB.CharacterAchievements[characterKey] or nil,
    }
    return "return " .. BPP_SerializeSnapshotValue(payload, "", {})
end

-- Parses and applies a previously exported blob to the CURRENT character,
-- overwriting its kill/achievement data. Returns true/false, message.
function BPP_ImportStatsFromText(text)
    if not text or text:match("^%s*$") then
        return false, "Nothing to import."
    end

    local chunk, loadErr = loadstring(text)
    if not chunk then
        return false, "Could not parse import text: " .. tostring(loadErr)
    end

    local ok, payload = pcall(chunk)
    if not ok then
        return false, "Import text failed to evaluate: " .. tostring(payload)
    end

    if type(payload) ~= "table" or type(payload.characterData) ~= "table" then
        return false, "That doesn't look like a BigPPvPStats export."
    end

    local characterKey = BPP_GetCharacterKey()
    BPP_DB.PlayerKillCounts.Characters[characterKey] = payload.characterData
    if payload.characterAchievements then
        BPP_DB.CharacterAchievements = BPP_DB.CharacterAchievements or {}
        BPP_DB.CharacterAchievements[characterKey] = payload.characterAchievements
    end

    return true, "Import complete for " .. characterKey .. ". Type /reload to refresh any open windows."
end

-- ============================================================
-- Export / Import UI - a copyable/pasteable multi-line text box
-- ============================================================

local exportFrame, exportEditBox
local importFrame, importEditBox

local function BPP_CreateTextBoxFrame(frameGlobalName, scrollGlobalName, titleText, isImport)
    local frame = CreateFrame("Frame", frameGlobalName, UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(560, 420)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.TitleText:SetText(titleText)
    frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -30)
    hint:SetPoint("RIGHT", frame, "RIGHT", -15, 0)
    hint:SetJustifyH("LEFT")
    hint:SetText(isImport
        and "Paste a previously exported blob below, then click Import. This overwrites this character's current stats/achievements."
        or "Select all (Ctrl+A) and copy (Ctrl+C), then paste it somewhere safe outside the game.")

    local scrollFrame = CreateFrame("ScrollFrame", scrollGlobalName, frame, "InputScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 5, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, isImport and 50 or 15)

    local editBox = scrollFrame.EditBox
    editBox:SetMaxLetters(0)
    editBox:SetAutoFocus(false)

    if isImport then
        local importButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
        importButton:SetSize(120, 25)
        importButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
        importButton:SetText("Import")
        importButton:SetScript("OnClick", function()
            local ok, message = BPP_ImportStatsFromText(editBox:GetText())
            BPP_Print(message)
            if ok then
                frame:Hide()
            end
        end)
    end

    return frame, editBox
end

function BPP_ShowExportFrame()
    if not exportFrame then
        exportFrame, exportEditBox = BPP_CreateTextBoxFrame("BPP_ExportFrame", "BPP_ExportScrollFrame", "Export BigPPvPStats Data", false)
        tinsert(UISpecialFrames, "BPP_ExportFrame")
    end
    exportEditBox:SetText(BPP_BuildExportText())
    exportFrame:Show()
    exportEditBox:HighlightText()
    exportEditBox:SetFocus()
end

function BPP_ShowImportFrame()
    if not importFrame then
        importFrame, importEditBox = BPP_CreateTextBoxFrame("BPP_ImportFrame", "BPP_ImportScrollFrame", "Import BigPPvPStats Data", true)
        tinsert(UISpecialFrames, "BPP_ImportFrame")
    end
    importEditBox:SetText("")
    importFrame:Show()
    importEditBox:SetFocus()
end
