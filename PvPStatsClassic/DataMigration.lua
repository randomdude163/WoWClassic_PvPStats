local addonName, PVPSC = ...

-- Data Migration Module
-- Handles importing data from older addons or manual file copies (PSC_DB_IMPORT)

local function MergeKillData(destKills, sourceKills)
    local importedKills = 0

    for unitName, sourceEntry in pairs(sourceKills) do
        if not destKills[unitName] then
            -- If entry doesn't exist, just deep copy it
            destKills[unitName] = CopyTable(sourceEntry)
            importedKills = importedKills + (sourceEntry.kills or 0)
        else
            -- Entry exists, need to merge killLocations to avoid duplicates
            local destEntry = destKills[unitName]
            local existingTimestamps = {}

            if destEntry.killLocations then
                for _, loc in ipairs(destEntry.killLocations) do
                    if loc.timestamp then
                        existingTimestamps[loc.timestamp] = true
                    end
                end
            else
                destEntry.killLocations = {}
            end

            if sourceEntry.killLocations then
                for _, sourceLoc in ipairs(sourceEntry.killLocations) do
                    if sourceLoc.timestamp and not existingTimestamps[sourceLoc.timestamp] then
                        table.insert(destEntry.killLocations, CopyTable(sourceLoc))
                        existingTimestamps[sourceLoc.timestamp] = true
                    end
                end
            end

            -- Recalculate totals
            destEntry.kills = #destEntry.killLocations

            -- Sort kill locations by timestamp (ascending) to keep history clean
            table.sort(destEntry.killLocations, function(a, b)
                return (a.timestamp or 0) < (b.timestamp or 0)
            end)

            -- Update lastKill timestamp
            local maxProp = 0
            for _, loc in ipairs(destEntry.killLocations) do
                if loc.timestamp and loc.timestamp > maxProp then
                    maxProp = loc.timestamp
                end
            end
            destEntry.lastKill = maxProp
        end
    end

    return importedKills
end

local function MergeLossData(destLosses, sourceLosses)
    if not sourceLosses then return 0 end

    local importedDeaths = 0

    for unitName, sourceEntry in pairs(sourceLosses) do
        if not destLosses[unitName] then
            destLosses[unitName] = CopyTable(sourceEntry)
            importedDeaths = importedDeaths + (sourceEntry.deaths or 0)
        else
            local destEntry = destLosses[unitName]
            local existingTimestamps = {}

            if destEntry.deathLocations then
                for _, loc in ipairs(destEntry.deathLocations) do
                    if loc.timestamp then
                        existingTimestamps[loc.timestamp] = true
                    end
                end
            else
                destEntry.deathLocations = {}
            end

            if sourceEntry.deathLocations then
                for _, sourceLoc in ipairs(sourceEntry.deathLocations) do
                    if sourceLoc.timestamp and not existingTimestamps[sourceLoc.timestamp] then
                        table.insert(destEntry.deathLocations, CopyTable(sourceLoc))
                        existingTimestamps[sourceLoc.timestamp] = true
                    end
                end
            end

            destEntry.deaths = #destEntry.deathLocations

            -- Sort death locations by timestamp
            table.sort(destEntry.deathLocations, function(a, b)
                return (a.timestamp or 0) < (b.timestamp or 0)
            end)
        end
    end

    return importedDeaths
end

local function MergeAchievements(destItems, sourceItems)
    local count = 0
    for id, data in pairs(sourceItems) do
        if data.unlocked then
            if not destItems[id] or not destItems[id].unlocked then
                destItems[id] = CopyTable(data)
                count = count + 1
            end
        end
    end
    return count
end

local function MergePlayerInfoCache(destCache, sourceCache)
    if not sourceCache then return 0 end

    local count = 0
    for key, info in pairs(sourceCache) do
        if not destCache[key] then
            destCache[key] = CopyTable(info)
            count = count + 1
        else
            -- Check if we should copy the note (if exists in source but not in dest)
            if info.note and not destCache[key].note then
                destCache[key].note = info.note
                -- We don't increment count here as it's not a full entry import, but an enhancement
            end
        end
    end
    return count
end

function PSC_PerformDataMigration()
    if not PSC_DB_IMPORT then return end

    print("[PvPStats]: Starting data migration...")

    -- 1. Merge Player Info Cache (Global)
    local infoImported = MergePlayerInfoCache(PSC_DB.PlayerInfoCache, PSC_DB_IMPORT.PlayerInfoCache)
    print(string.format("[PvPStats]: Imported %d player info cache entries.", infoImported))

    -- 2. Merge Kill Counts (Per Character)
    if PSC_DB_IMPORT.PlayerKillCounts and PSC_DB_IMPORT.PlayerKillCounts.Characters then
        if not PSC_DB.PlayerKillCounts then PSC_DB.PlayerKillCounts = {} end
        if not PSC_DB.PlayerKillCounts.Characters then PSC_DB.PlayerKillCounts.Characters = {} end

        for charKey, charData in pairs(PSC_DB_IMPORT.PlayerKillCounts.Characters) do
            if not PSC_DB.PlayerKillCounts.Characters[charKey] then
                PSC_DB.PlayerKillCounts.Characters[charKey] = {
                    Kills = {},
                    Level1KillTimestamps = {},
                    SpawnCamperMaxKills = 0
                }
            end

            if charData.Kills then
                 MergeKillData(PSC_DB.PlayerKillCounts.Characters[charKey].Kills, charData.Kills)
                 -- Clear derived caches to force rebuild from new complete data
                 PSC_DB.PlayerKillCounts.Characters[charKey].Level1KillTimestamps = nil
            end

            -- Merge simple counters
            local destChar = PSC_DB.PlayerKillCounts.Characters[charKey]

            if charData.HighestKillStreak and (charData.HighestKillStreak > (destChar.HighestKillStreak or 0)) then
                destChar.HighestKillStreak = charData.HighestKillStreak
            end

            if charData.HighestMultiKill and (charData.HighestMultiKill > (destChar.HighestMultiKill or 0)) then
                destChar.HighestMultiKill = charData.HighestMultiKill
            end

            if charData.SpawnCamperMaxKills and (charData.SpawnCamperMaxKills > (destChar.SpawnCamperMaxKills or 0)) then
                destChar.SpawnCamperMaxKills = charData.SpawnCamperMaxKills
            end

            if charData.GrayKillsCount and (charData.GrayKillsCount > (destChar.GrayKillsCount or 0)) then
                destChar.GrayKillsCount = charData.GrayKillsCount
            end
        end
    end

    -- 3. Merge Loss Counts (Per Character)
    if PSC_DB_IMPORT.PvPLossCounts then
        if not PSC_DB.PvPLossCounts then PSC_DB.PvPLossCounts = {} end

        for charKey, charData in pairs(PSC_DB_IMPORT.PvPLossCounts) do
            if not PSC_DB.PvPLossCounts[charKey] then
                PSC_DB.PvPLossCounts[charKey] = { Deaths = {} }
            end

            if charData.Deaths then
                MergeLossData(PSC_DB.PvPLossCounts[charKey].Deaths, charData.Deaths)
            end
        end
    end

    -- 4. Merge Achievements
    if PSC_DB_IMPORT.CharacterAchievements then
        if not PSC_DB.CharacterAchievements then PSC_DB.CharacterAchievements = {} end

        for charKey, achievements in pairs(PSC_DB_IMPORT.CharacterAchievements) do
            if not PSC_DB.CharacterAchievements[charKey] then
                PSC_DB.CharacterAchievements[charKey] = {}
            end
            MergeAchievements(PSC_DB.CharacterAchievements[charKey], achievements)

            -- Recalculate points
            if PSC_UpdateTotalAchievementPoints then
                -- Temporarily mock GetCharacterKey if needed, but the function uses the global one.
                -- However, PSC_UpdateTotalAchievementPoints only updates CURRENT character.
                -- We might need to handle this if we support alt import,
                -- but recalculation happens on load anyway.
            end
        end
    end

    print("[PvPStats]: Data migration complete!")
    print("[PvPStats]: Reloading UI to finalize changes...")

    -- Clear the import variable so it doesn't run again or save to disk
    PSC_DB_IMPORT = nil

    -- Reload UI to ensure separate caches (like Leaderboards/Achievements) are rebuilt with the new data
    ReloadUI()
end

function PSC_CheckForDataMigration()
    if not PSC_DB_IMPORT then return end

    -- Analyze import data for the popup summary
    local charSummaries = {}
    local totalChars = 0

    if PSC_DB_IMPORT.PlayerKillCounts and PSC_DB_IMPORT.PlayerKillCounts.Characters then
        for charKey, charData in pairs(PSC_DB_IMPORT.PlayerKillCounts.Characters) do
            totalChars = totalChars + 1
            local killCount = 0
            if charData.Kills then
                for _, kData in pairs(charData.Kills) do
                    killCount = killCount + (kData.kills or 0)
                end
            end

            local achCount = 0
            if PSC_DB_IMPORT.CharacterAchievements and PSC_DB_IMPORT.CharacterAchievements[charKey] then
                for _, aData in pairs(PSC_DB_IMPORT.CharacterAchievements[charKey]) do
                    if aData.unlocked then achCount = achCount + 1 end
                end
            end

            table.insert(charSummaries, {
                name = charKey,
                kills = killCount,
                achievements = achCount
            })
        end
    end

    if totalChars == 0 then
        -- No valid character data found
        PSC_DB_IMPORT = nil
        return
    end

    -- Build the summary text
    local text = "PvPStatsClassic: Data ready for import!\n\n"
    text = text .. "Data from a previous installation found. Do you want to merge it with your current data?\n\n"
    text = text .. "Found " .. totalChars .. " character(s):\n"

    for _, summary in ipairs(charSummaries) do
        -- Only show first 3 characters to avoid overflowing popup
        if _ <= 3 then
            text = text .. string.format("- %s: %d Kills, %d Achievements\n", summary.name, summary.kills, summary.achievements)
        end
    end

    if totalChars > 3 then
        text = text .. "...and " .. (totalChars - 3) .. " more.\n"
    end

    text = text .. "\n\nIMPORTANT: Confirming will automatically Reload UI to apply changes!"

    StaticPopupDialogs["PSC_IMPORT_CONFIRM"] = {
        text = text,
        button1 = "Yes, Import",
        button2 = "No, Discard data",
        OnAccept = function()
            PSC_PerformDataMigration()
        end,
        OnCancel = function()
            PSC_DB_IMPORT = nil
            print("[PvPStats]: Import cancelled. Data discarded.")
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("PSC_IMPORT_CONFIRM")
end

-- Test suite for Data Migration
function PSC_RunMigrationTests()
    if not PSC_Debug then
        print("[PvPStats - Test] Debug mode required.")
        return
    end
    print("[PvPStats - Test] Starting Data Migration Tests...")

    -- Mocks
    local mock_DB = {
        PlayerInfoCache = {},
        PlayerKillCounts = { Characters = {} },
        PvPLossCounts = {},
        CharacterAchievements = {}
    }

    local mock_Import = {
        PlayerInfoCache = {},
        PlayerKillCounts = { Characters = {} },
        PvPLossCounts = {},
        CharacterAchievements = {}
    }

    -- 1. Setup Data
    local charKey = "TestChar-TestRealm"

    -- PlayerInfoCache: Test overriding
    -- Case A: Entry only in Import -> Should Import
    mock_Import.PlayerInfoCache["Old-Realm"] = { class = "Warrior", level = 10 }
    -- Case B: Entry only in DB -> Should Keep
    mock_DB.PlayerInfoCache["Current-Realm"] = { class = "Priest", level = 60 }
    -- Case C: Entry in Both -> Should Keep DB (simulating newer data in DB)
    mock_Import.PlayerInfoCache["Twink-Realm"] = { class = "Mage", level = 19 }
    mock_DB.PlayerInfoCache["Twink-Realm"] = { class = "Mage", level = 29 }

    -- Case D: Entry in Both, but Import has note and DB does not -> Should Copy Note
    mock_Import.PlayerInfoCache["Note-Target"] = { class = "Rogue", level = 60, note = "Imported Note" }
    mock_DB.PlayerInfoCache["Note-Target"] = { class = "Rogue", level = 60 } -- No note

    -- Kills: Test dupes and merging
    -- Setup: DB has VictimA with 1 kill
    mock_DB.PlayerKillCounts.Characters[charKey] = {
        Kills = {
            ["VictimA"] = { kills = 1, lastKill = 100, killLocations = { { timestamp=100, zone="ZoneA" } }}
        },
        Level1KillTimestamps = { 100 }, -- Sould be cleared on import
        -- Stat merging tests (DB has lower values)
        HighestKillStreak = 5,
        HighestMultiKill = 2,
        SpawnCamperMaxKills = 10,
        GrayKillsCount = 50,
        -- Excluded fields tests
        CurrentKillStreak = 3
    }

    -- Setup: Import has VictimA (duplicate timestamp), VictimA (new timestamp), and VictimB (new victim)
    mock_Import.PlayerKillCounts.Characters[charKey] = {
        Kills = {
            ["VictimA"] = {
                kills = 2,
                lastKill = 150,
                killLocations = {
                    { timestamp=100, zone="ZoneA" }, -- Duplicate
                    { timestamp=150, zone="ZoneA" }  -- New Kill
                }
            },
            ["VictimB"] = {
                kills = 1,
                lastKill = 200,
                killLocations = { { timestamp=200, zone="ZoneB" } }  -- New Victim
            }
        },
        -- Stat merging tests (Import has higher values)
        HighestKillStreak = 10,
        HighestMultiKill = 4,
        SpawnCamperMaxKills = 20,
        GrayKillsCount = 100,
        -- Excluded fields tests
        CurrentKillStreak = 50 -- Should be ignored
    }

    -- Leaderboard Cache Test (Should be ignored)
    mock_Import.LeaderboardCache = { ["SomeEntry"] = true }
    mock_DB.LeaderboardCache = {}


    -- Loss: Test merging
    -- Setup: DB has KillerA (Time 100)
    mock_DB.PvPLossCounts[charKey] = {
        Deaths = {
            ["KillerA"] = { deaths = 1, deathLocations = { { timestamp = 100 } } }
        }
    }

    mock_Import.PvPLossCounts[charKey] = {
        Deaths = {
            -- Case: New Killer
            ["KillerB"] = { deaths = 1, deathLocations = { { timestamp = 200 } } },
            -- Case: Merge existing killer (Start with duplicate timestamp 100, add new timestamp 300)
            ["KillerA"] = { deaths = 2, deathLocations = {
                { timestamp = 100 }, -- Duplicate
                { timestamp = 300 }  -- New
            }}
        }
    }

    -- Achievements: Test merging
    mock_DB.CharacterAchievements[charKey] = {
        [1] = { unlocked = true, completedDate = "CurrentDate" }, -- Case: Both Unlocked (Keep Current)
        [3] = { unlocked = false } -- Case: DB Locked, Import Unlocked
    }

    mock_Import.CharacterAchievements[charKey] = {
        [1] = { unlocked = true, completedDate = "OldDate" },
        [2] = { unlocked = true },  -- Case: New Achievement
        [3] = { unlocked = true }   -- Case: Upgrade to Unlocked
    }

    -- 2. Swap Globals
    local real_DB = PSC_DB
    local real_Import = PSC_DB_IMPORT
    local real_ReloadUI = ReloadUI

    PSC_DB = mock_DB
    PSC_DB_IMPORT = mock_Import

    local reloadCalled = false
    ReloadUI = function() reloadCalled = true end

    -- 3. Run Migration
    -- Note: We do NOT use PSC_CheckForDataMigration because that creates a popup.
    -- We call PSC_PerformDataMigration directly.
    PSC_PerformDataMigration()

    -- 4. Verify Results
    local failed = false
    local function Assert(condition, msg)
        if not condition then
            print("[PvPStats - Test] FAIL: " .. msg)
            failed = true
        end
    end

    -- InfoCache
    Assert(PSC_DB.PlayerInfoCache["Old-Realm"], "Case A: Imported InfoCache missing")
    Assert(PSC_DB.PlayerInfoCache["Current-Realm"], "Case B: Existing InfoCache missing")
    Assert(PSC_DB.PlayerInfoCache["Twink-Realm"].level == 29, "Case C: Existing InfoCache overwritten (level mismatch)")
    Assert(PSC_DB.PlayerInfoCache["Note-Target"].note == "Imported Note", "Case D: Note not merged")

    -- Kills
    local charStats = PSC_DB.PlayerKillCounts.Characters[charKey]
    local kills = charStats.Kills
    -- VictimA: 1 existing + 1 new - 1 duplicate = 2 total
    local vA = kills["VictimA"]
    Assert(vA and vA.kills == 2, "VictimA count wrong (Expected 2, got " .. (vA and vA.kills or "nil") .. ")")
    Assert(vA and #vA.killLocations == 2, "VictimA location count wrong")
    -- Verify sorting (timestamp 100 < 150)
    Assert(vA.killLocations[1].timestamp == 100, "VictimA history not sorted (1)")
    Assert(vA.killLocations[2].timestamp == 150, "VictimA history not sorted (2)")

    -- VictimB: 1 new
    local vB = kills["VictimB"]
    Assert(vB and vB.kills == 1, "VictimB count wrong")

    -- Summary Stats
    Assert(charStats.HighestKillStreak == 10, "HighestKillStreak not upgraded")
    Assert(charStats.HighestMultiKill == 4, "HighestMultiKill not upgraded")
    Assert(charStats.SpawnCamperMaxKills == 20, "SpawnCamperMaxKills not upgraded")
    Assert(charStats.GrayKillsCount == 100, "GrayKillsCount not upgraded")

    -- Excluded Fields (Should NOT change)
    Assert(charStats.CurrentKillStreak == 3, "CurrentKillStreak was overwritten (should be ignored)")
    Assert(next(PSC_DB.LeaderboardCache) == nil, "LeaderboardCache was imported (should be ignored)")
    Assert(charStats.Level1KillTimestamps == nil, "Level1KillTimestamps should be cleared for rebuild")

    -- Assertions: Losses
    print("[PvPStats - Test] Checking Losses...")
    Assert(PSC_DB.PvPLossCounts[charKey].Deaths["KillerA"], "Existing killer should persist")
    Assert(PSC_DB.PvPLossCounts[charKey].Deaths["KillerA"].deaths == 2, "Merged killer should have 2 deaths (1 existing + 1 new - 1 duplicate)")
    Assert(PSC_DB.PvPLossCounts[charKey].Deaths["KillerB"], "New killer should be added")

    -- Assertions: Achievements
    print("[PvPStats - Test] Checking Achievements...")
    Assert(PSC_DB.CharacterAchievements[charKey][2], "New achievement should be added")
    Assert(PSC_DB.CharacterAchievements[charKey][1].completedDate == "CurrentDate", "Existing achievement should not be overwritten by older import")
    Assert(PSC_DB.CharacterAchievements[charKey][3].unlocked == true, "Achievement should upgrade from Locked to Unlocked")

    -- Reload & Cleanup
    Assert(reloadCalled, "ReloadUI not triggered")
    Assert(PSC_DB_IMPORT == nil, "PSC_DB_IMPORT not cleared")

    -- 5. Restore Globals
    PSC_DB = real_DB
    PSC_DB_IMPORT = real_Import
    ReloadUI = real_ReloadUI

    if not failed then
        print("[PvPStats - Test] ALL TESTS PASSED.")
    end
end
