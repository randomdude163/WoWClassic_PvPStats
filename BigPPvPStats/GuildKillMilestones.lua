local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- ============================================================
-- Dynamic per-guild kill milestones
--
-- Unlike the addon's other achievements (a fixed list declared up front),
-- these are synthesized at runtime: the first time stats.guildData shows
-- kills against a guild we haven't seen before, we generate a 9-tier ladder
-- of achievements for that guild and insert them into the live achievements
-- list. There's no way to know in advance which guilds a player will fight,
-- so there's nothing to declare statically.
--
-- Persistence still works through the normal mechanism (BPP_DB.CharacterAchievements
-- keyed by achievement id) because the id is deterministic from the guild
-- name + tier - regenerating the same guild's achievements on a later login
-- reproduces the same ids, so LoadAchievementCompletedData() finds and
-- restores their unlocked state same as any other achievement.
-- ============================================================

local GUILD_MILESTONE_TIERS = {
    { kills = 10, points = 10, icon = 134473, roman = "I" },
    { kills = 25, points = 25, icon = 134471, roman = "II" },
    { kills = 50, points = 50, icon = 134472, roman = "III" },
    { kills = 75, points = 75, icon = 134470, roman = "IV" },
    { kills = 100, points = 100, icon = 134468, roman = "V" },
    { kills = 200, points = 200, icon = 134467, roman = "VI" },
    { kills = 300, points = 300, icon = 134466, roman = "VII" },
    { kills = 400, points = 400, icon = 134328, roman = "VIII" },
    { kills = 500, points = 500, icon = 134327, roman = "IX" },
}

-- One shared joke per tier, reused for every guild.
local GUILD_MILESTONE_SUBTEXTS = {
    [10] = function(g, n) return ("First blood against %s! %d down, and word is already spreading through their guild chat."):format(g, n) end,
    [25] = function(g, n) return ("%d members of %s sent packing! Their officers are updating the roster faster than you can say 'wipe.'"):format(n, g) end,
    [50] = function(g, n) return ("%d kills against %s and counting! Their guild bank is basically a memorial fund at this point."):format(n, g) end,
    [75] = function(g, n) return ("%d members of %s eliminated! Recruitment ads now include 'must enjoy respawning.'"):format(n, g) end,
    [100] = function(g, n) return ("Triple digits! %d players from %s put down. Their guild master is considering a merger just to survive."):format(n, g) end,
    [200] = function(g, n) return ("%d members of %s dispatched! You've killed more of them than their raid team ever logged in."):format(n, g) end,
    [300] = function(g, n) return ("%d down! %s's officer chat is 90%% just your name and a skull emoji at this point."):format(n, g) end,
    [400] = function(g, n) return ("%d kills deep into %s! Their guild charter is basically a casualty list now."):format(n, g) end,
    [500] = function(g, n) return ("%d players from %s eliminated! History will remember this as the day %s stopped recruiting and started grieving."):format(n, g, g) end,
}

local function SlugifyGuildName(guildName)
    return guildName:lower():gsub("[^%a%d]+", "")
end

-- Guild names we've already synthesized achievement entries for this session,
-- so repeated calls (every stats recalculation) don't create duplicates.
AchievementSystem.knownGuildMilestoneNames = AchievementSystem.knownGuildMilestoneNames or {}

local function CreateGuildMilestoneAchievements(guildName)
    local slug = SlugifyGuildName(guildName)
    if slug == "" then return end

    for _, tier in ipairs(GUILD_MILESTONE_TIERS) do
        local achievement = {
            id = "kills_anyguild_" .. slug .. "_" .. tier.kills,
            guildName = guildName,
            title = guildName .. " Menace " .. tier.roman,
            description = function(a) return ("Eliminate %d players from %s"):format(a.targetValue, a.guildName) end,
            iconID = tier.icon,
            achievementPoints = tier.points,
            targetValue = tier.kills,
            condition = function(achievement, stats)
                return achievement.progress(achievement, stats) >= achievement.targetValue
            end,
            unlocked = false,
            completedDate = nil,
            subText = function(a)
                return GUILD_MILESTONE_SUBTEXTS[a.targetValue](a.guildName, a.targetValue)
            end,
            progress = function(achievement, stats)
                return (stats.guildData and stats.guildData[achievement.guildName]) or 0
            end,
        }
        table.insert(AchievementSystem.achievements, achievement)
    end
end

-- Scans stats.guildData (kills per guild - already tracked for every guild
-- ever fought, not a curated list) and creates the 9-tier ladder for any
-- guild seen for the first time. Safe to call every recalculation; already-
-- known guilds are skipped instantly via knownGuildMilestoneNames.
function BPP_SyncDynamicGuildAchievements(stats)
    if not stats or not stats.guildData or not AchievementSystem.achievements then
        return
    end

    local addedAny = false
    for guildName, kills in pairs(stats.guildData) do
        if guildName and guildName ~= "" and kills and kills > 0
            and not AchievementSystem.knownGuildMilestoneNames[guildName] then
            AchievementSystem.knownGuildMilestoneNames[guildName] = true
            CreateGuildMilestoneAchievements(guildName)
            addedAny = true
        end
    end

    if addedAny then
        AchievementSystem:AssignRarityToAchievements()
    end
end
