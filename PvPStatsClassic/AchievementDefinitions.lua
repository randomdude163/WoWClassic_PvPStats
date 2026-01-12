local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem


if PSC_GameVersion == PSC_GAME_VERSIONS.CLASSIC then
    AchievementSystem.achievements = AchievementSystem.achievementsClassic

elseif PSC_GameVersion == PSC_GAME_VERSIONS.TBC then
    AchievementSystem.achievements = AchievementSystem.achievementsClassic +
        AchievementSystem.achievementsTbc

elseif PSC_GameVersion == PSC_GAME_VERSIONS.WOTLK then
    AchievementSystem.achievements = AchievementSystem.achievementsClassic +
        AchievementSystem.achievementsTbc +
        AchievementSystem.achievementsWotlk
end
