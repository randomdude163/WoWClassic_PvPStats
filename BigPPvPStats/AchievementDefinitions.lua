local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Helper function to merge achievement tables
local function MergeAchievementTables(...)
    local result = {}
    local tables = {...}

    for _, tbl in ipairs(tables) do
        if tbl then
            for _, achievement in ipairs(tbl) do
                table.insert(result, achievement)
            end
        end
    end

    return result
end

-- Function to build the achievements table based on game version
-- This needs to be called after BPP_GameVersion is determined
function AchievementSystem:InitializeAchievements()
    if BPP_GameVersion == BPP_GAME_VERSIONS.CLASSIC then
        self.achievements = self.achievementsClassic or {}

    elseif BPP_GameVersion == BPP_GAME_VERSIONS.TBC then
        self.achievements = MergeAchievementTables(
            self.achievementsClassic,
            self.achievementsTbc
        )

    elseif BPP_GameVersion == BPP_GAME_VERSIONS.WOTLK then
        self.achievements = MergeAchievementTables(
            self.achievementsClassic,
            self.achievementsTbc,
            self.achievementsWotlk
        )

    else
        -- Fallback to Classic if version is unknown
        self.achievements = self.achievementsClassic or {}
    end

    -- Assign rarity to all achievements after they're initialized
    self:AssignRarityToAchievements()

    if BPP_Debug then
        local count = self.achievements and #self.achievements or 0
        print("[PvPStats] Initialized " .. count .. " achievements for game version: " .. tostring(BPP_GameVersion))
    end
end
