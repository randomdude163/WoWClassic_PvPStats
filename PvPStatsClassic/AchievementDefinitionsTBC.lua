local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Zone name translations (English, German, French, Spanish)
local ZONE_TRANSLATIONS_TBC = {
    ["Eversong Woods"] = {"Eversong Woods", "Immersangwald", "Bois des Chants éternels", "Bosque Canción Eterna"},
    ["Ghostlands"] = {"Ghostlands", "Geisterlande", "Terres fantômes", "Tierras Fantasma"},
    ["Hellfire Peninsula"] = {"Hellfire Peninsula", "Höllenfeuerhalbinsel", "Péninsule des Flammes infernales", "Península del Fuego Infernal"},
    ["Zangarmarsh"] = {"Zangarmarsh", "Zangarmarschen", "Marécage de Zangar", "Marisma de Zangar"},
    ["Terokkar Forest"] = {"Terokkar Forest", "Wälder von Terokkar", "Forêt de Terokkar", "Bosque de Terokkar"},
    ["Nagrand"] = {"Nagrand", "Nagrand", "Nagrand", "Nagrand"},
    ["Blade's Edge Mountains"] = {"Blade's Edge Mountains", "Schergrat", "Les Tranchantes", "Montañas Filospada"},
    ["Netherstorm"] = {"Netherstorm", "Nethersturm", "Raz-de-Néant", "Tormenta Abisal"},
    ["Shadowmoon Valley"] = {"Shadowmoon Valley", "Schattenmondtal", "Vallée d'Ombrelune", "Valle Sombraluna"},
    ["Silvermoon City"] = {"Silvermoon City", "Silbermond", "Lune-d'Argent", "Ciudad de Lunargenta"},
    ["Azuremyst Isle"] = {"Azuremyst Isle", "Azurmythosinsel", "Île de Brume-azur", "Isla Bruma Azur"},
    ["Bloodmyst Isle"] = {"Bloodmyst Isle", "Blutmythosinsel", "Île de Brume-sang", "Isla Bruma de Sangre"},
    ["Exodar"] = {"Exodar", "Exodar", "Exodar", "Exodar"}
}


AchievementSystem.achievementsTbc = {
    -- =====================================================
    -- HELLFIRE PENINSULA ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_hellfire_100",
        title = "Hellfire Initiate",
        description = function(a) return ("Eliminate %d players in Hellfire Peninsula"):format(a.targetValue) end,
        iconID = 236842,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Hellfire Peninsula! You've turned the gateway to Outland into a proper slaughterhouse. The Dark Portal's loading screen should include a warning about you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Hellfire Peninsula")
        end,
    },
    {
        id = "zone_hellfire_250",
        title = "Hellfire Harbinger",
        description = function(a) return ("Eliminate %d players in Hellfire Peninsula"):format(a.targetValue) end,
        iconID = 236842,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses littering the shattered landscape, Hellfire Peninsula lives up to its name. Both Honor Hold and Thrallmar are considering hiring you as their new defense system.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Hellfire Peninsula")
        end,
    },
    {
        id = "zone_hellfire_500",
        title = "Hellfire Devastator",
        description = function(a) return ("Eliminate %d players in Hellfire Peninsula"):format(a.targetValue) end,
        iconID = 236842,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players learned the hard way that Hellfire Peninsula wasn't the worst thing about Outland—you were. The fel reavers are taking notes on your hunting techniques.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Hellfire Peninsula")
        end,
    },
    {
        id = "zone_hellfire_1000",
        title = "Hellfire Legend",
        description = function(a) return ("Eliminate %d players in Hellfire Peninsula"):format(a.targetValue) end,
        iconID = 236842,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Hellfire Peninsula! You are the true terror of Outland's gateway. Freshly arrived players see your name and consider unsubscribing. Even Illidan is impressed.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Hellfire Peninsula")
        end,
    },

    -- =====================================================
    -- ZANGARMARSH ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_zangarmarsh_100",
        title = "Marsh Menace",
        description = function(a) return ("Eliminate %d players in Zangarmarsh"):format(a.targetValue) end,
        iconID = 236850,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Zangarmarsh! The sporelings are starting a support group for traumatized players. The mushrooms have seen things they can't unsee.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Zangarmarsh")
        end,
    },
    {
        id = "zone_zangarmarsh_250",
        title = "Swamp Slayer",
        description = function(a) return ("Eliminate %d players in Zangarmarsh"):format(a.targetValue) end,
        iconID = 236850,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d bodies sinking into the marsh, the Cenarion Expedition is concerned about the local ecosystem. Turns out, corpses make terrible compost.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Zangarmarsh")
        end,
    },
    {
        id = "zone_zangarmarsh_500",
        title = "Fungal Fury",
        description = function(a) return ("Eliminate %d players in Zangarmarsh"):format(a.targetValue) end,
        iconID = 236850,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players discovered that Zangarmarsh's biggest threat isn't the naga—it's you. The marsh gas has nothing on your toxic presence.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Zangarmarsh")
        end,
    },
    {
        id = "zone_zangarmarsh_1000",
        title = "Lord of the Marsh",
        description = function(a) return ("Eliminate %d players in Zangarmarsh"):format(a.targetValue) end,
        iconID = 236850,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Zangarmarsh! You've claimed this swamp as your personal hunting ground. Lady Vashj watches your kill count with professional jealousy.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Zangarmarsh")
        end,
    },

    -- =====================================================
    -- TEROKKAR FOREST ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_terokkar_100",
        title = "Terokkar Terror",
        description = function(a) return ("Eliminate %d players in Terokkar Forest"):format(a.targetValue) end,
        iconID = 236849,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Terokkar Forest! The arakkoa consider you more dangerous than the Shadow Council. Shattrath is putting up wanted posters.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Terokkar Forest")
        end,
    },
    {
        id = "zone_terokkar_250",
        title = "Forest Fiend",
        description = function(a) return ("Eliminate %d players in Terokkar Forest"):format(a.targetValue) end,
        iconID = 236849,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses beneath the bone wastes, Terokkar Forest has a new apex predator. Auchindoun's death toll is now split between the undead and you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Terokkar Forest")
        end,
    },
    {
        id = "zone_terokkar_500",
        title = "Shadow Sovereign",
        description = function(a) return ("Eliminate %d players in Terokkar Forest"):format(a.targetValue) end,
        iconID = 236849,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players fell in Terokkar Forest. The bone wastes are living up to their name, and you're the reason why. Even the spirits of Auchindoun fear you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Terokkar Forest")
        end,
    },
    {
        id = "zone_terokkar_1000",
        title = "Terokkar Tyrant",
        description = function(a) return ("Eliminate %d players in Terokkar Forest"):format(a.targetValue) end,
        iconID = 236849,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Terokkar Forest! You've made this zone your personal killing field. Players avoid Terokkar like the plague—because you ARE the plague.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Terokkar Forest")
        end,
    },

    -- =====================================================
    -- NAGRAND ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_nagrand_100",
        title = "Nagrand Nomad",
        description = function(a) return ("Eliminate %d players in Nagrand"):format(a.targetValue) end,
        iconID = 236847,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Nagrand! The floating islands aren't the only thing that's breathtaking—so is your body count. Halaa has declared you persona non grata.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Nagrand")
        end,
    },
    {
        id = "zone_nagrand_250",
        title = "Plains Predator",
        description = function(a) return ("Eliminate %d players in Nagrand"):format(a.targetValue) end,
        iconID = 236847,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses scattered across the pristine plains, Nagrand's beauty is marred only by your kill count. The local wildlife considers you competition.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Nagrand")
        end,
    },
    {
        id = "zone_nagrand_500",
        title = "Warlord of Nagrand",
        description = function(a) return ("Eliminate %d players in Nagrand"):format(a.targetValue) end,
        iconID = 236847,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players discovered that Nagrand's Ring of Blood is child's play compared to facing you. Even the clefthoofs are impressed by your brutality.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Nagrand")
        end,
    },
    {
        id = "zone_nagrand_1000",
        title = "Scourge of Nagrand",
        description = function(a) return ("Eliminate %d players in Nagrand"):format(a.targetValue) end,
        iconID = 236847,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Nagrand! You've turned paradise into a personal warzone. The Mag'har are considering adding you to their ancestral legends—as a cautionary tale.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Nagrand")
        end,
    },

    -- =====================================================
    -- BLADE'S EDGE MOUNTAINS ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_bladesedge_100",
        title = "Mountain Marauder",
        description = function(a) return ("Eliminate %d players in Blade's Edge Mountains"):format(a.targetValue) end,
        iconID = 236841,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Blade's Edge Mountains! The ogres are taking notes on your combat techniques. Gruul's sons think you'd make a great addition to the family.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Blade's Edge Mountains")
        end,
    },
    {
        id = "zone_bladesedge_250",
        title = "Craggy Killer",
        description = function(a) return ("Eliminate %d players in Blade's Edge Mountains"):format(a.targetValue) end,
        iconID = 236841,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses tumbling down the cliffs, Blade's Edge Mountains lives up to its name. Players are more afraid of you than falling off the edge.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Blade's Edge Mountains")
        end,
    },
    {
        id = "zone_bladesedge_500",
        title = "Peak Predator",
        description = function(a) return ("Eliminate %d players in Blade's Edge Mountains"):format(a.targetValue) end,
        iconID = 236841,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players learned that the mountains aren't the deadliest thing with an edge—you are. The Fel Reavers are jealous of your kill efficiency.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Blade's Edge Mountains")
        end,
    },
    {
        id = "zone_bladesedge_1000",
        title = "King of the Crags",
        description = function(a) return ("Eliminate %d players in Blade's Edge Mountains"):format(a.targetValue) end,
        iconID = 236841,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Blade's Edge Mountains! You've conquered the peaks with blood and bodies. Even Gruul bows to your supremacy. Players whisper your name in fear.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Blade's Edge Mountains")
        end,
    },

    -- =====================================================
    -- NETHERSTORM ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_netherstorm_100",
        title = "Storm Stalker",
        description = function(a) return ("Eliminate %d players in Netherstorm"):format(a.targetValue) end,
        iconID = 236848,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Netherstorm! The ethereals are fascinated by your efficiency. Kael'thas is taking notes on your world-domination techniques.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Netherstorm")
        end,
    },
    {
        id = "zone_netherstorm_250",
        title = "Mana Forge Menace",
        description = function(a) return ("Eliminate %d players in Netherstorm"):format(a.targetValue) end,
        iconID = 236848,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses floating in the Nether, Netherstorm's energy crisis pales compared to your killing spree. Area 52's goblins want to weaponize you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Netherstorm")
        end,
    },
    {
        id = "zone_netherstorm_500",
        title = "Tempest Tyrant",
        description = function(a) return ("Eliminate %d players in Netherstorm"):format(a.targetValue) end,
        iconID = 236848,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players discovered that Netherstorm's arcane anomalies are nothing compared to the anomaly that is your kill count. Even the voidwalkers are impressed.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Netherstorm")
        end,
    },
    {
        id = "zone_netherstorm_1000",
        title = "Ethereal Executioner",
        description = function(a) return ("Eliminate %d players in Netherstorm"):format(a.targetValue) end,
        iconID = 236848,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Netherstorm! You've become the zone's greatest threat. The Burning Legion wants to recruit you. Tempest Keep was merely a setback—you're the real endgame.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Netherstorm")
        end,
    },

    -- =====================================================
    -- SHADOWMOON VALLEY ACHIEVEMENTS
    -- =====================================================
    {
        id = "zone_shadowmoon_100",
        title = "Shadowmoon Slayer",
        description = function(a) return ("Eliminate %d players in Shadowmoon Valley"):format(a.targetValue) end,
        iconID = 236843,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Shadowmoon Valley! Even the Black Temple's demons are impressed. Illidan looks out from his throne and nods in approval.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Shadowmoon Valley")
        end,
    },
    {
        id = "zone_shadowmoon_250",
        title = "Dark Reaper",
        description = function(a) return ("Eliminate %d players in Shadowmoon Valley"):format(a.targetValue) end,
        iconID = 236843,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses in the shadow of the Black Temple, you've become the valley's true terror. Illidan's forces offer you a job application.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Shadowmoon Valley")
        end,
    },
    {
        id = "zone_shadowmoon_500",
        title = "Valley Vanquisher",
        description = function(a) return ("Eliminate %d players in Shadowmoon Valley"):format(a.targetValue) end,
        iconID = 236843,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players fell in Shadowmoon Valley. The Burning Legion considers you an honorary member. You are NOT prepared—but they certainly weren't either.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Shadowmoon Valley")
        end,
    },
    {
        id = "zone_shadowmoon_1000",
        title = "Betrayer's Heir",
        description = function(a) return ("Eliminate %d players in Shadowmoon Valley"):format(a.targetValue) end,
        iconID = 236843,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Shadowmoon Valley! Illidan himself is jealous of your body count. You've proven that you ARE prepared—prepared to slaughter everyone. The Black Temple should be renamed after you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Shadowmoon Valley")
        end,
    },

    -- =====================================================
    -- EVERSONG WOODS (Blood Elf Starting Zone)
    -- =====================================================
    {
        id = "zone_alliance_eversong_100",
        title = "Eversong Eliminator",
        description = function(a) return ("Eliminate %d Blood Elves in Eversong Woods"):format(a.targetValue) end,
        iconID = 236844,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Blood Elves discovered that their pristine forests aren't so safe. Silvermoon's recruitment office is working overtime replacing the losses you've caused.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Eversong Woods")
        end,
    },
    {
        id = "zone_alliance_eversong_250",
        title = "Springtime Slaughter",
        description = function(a) return ("Eliminate %d Blood Elves in Eversong Woods"):format(a.targetValue) end,
        iconID = 236844,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses among the golden leaves, Eversong Woods is losing its luster. The Sunwell might have been restored, but Blood Elf morale is at an all-time low.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Eversong Woods")
        end,
    },
    {
        id = "zone_alliance_eversong_500",
        title = "Eternal Autumn",
        description = function(a) return ("Eliminate %d Blood Elves in Eversong Woods"):format(a.targetValue) end,
        iconID = 236844,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Blood Elves learned that addiction to magic isn't their biggest problem—you are. Silvermoon's guards post your wanted poster right next to the Scourge threat warnings.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Eversong Woods")
        end,
    },
    {
        id = "zone_alliance_eversong_1000",
        title = "Scourge of Silvermoon",
        description = function(a) return ("Eliminate %d Blood Elves in Eversong Woods"):format(a.targetValue) end,
        iconID = 236844,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Eversong Woods! You've become a legend whispered among Blood Elf children to make them behave. The Sunwell's light dims in your presence. Kael'thas's betrayal is now the SECOND worst thing to happen to Silvermoon.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Eversong Woods")
        end,
    },

    -- =====================================================
    -- GHOSTLANDS (Blood Elf Zone)
    -- =====================================================
    {
        id = "zone_alliance_ghostlands_100",
        title = "Ghostlands Ghoul",
        description = function(a) return ("Eliminate %d Blood Elves in Ghostlands"):format(a.targetValue) end,
        iconID = 236845,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Ghostlands! The undead Scourge have competition. Players are starting to think YOU'RE the real threat to Tranquillien.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Ghostlands")
        end,
    },
    {
        id = "zone_alliance_ghostlands_250",
        title = "Phantom Menace",
        description = function(a) return ("Eliminate %d Blood Elves in Ghostlands"):format(a.targetValue) end,
        iconID = 236845,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses in Ghostlands, you're adding to the zone's undead population. Dar'Khan Drathir is taking notes on your killing techniques.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Ghostlands")
        end,
    },
    {
        id = "zone_alliance_ghostlands_500",
        title = "Specter of Death",
        description = function(a) return ("Eliminate %d Blood Elves in Ghostlands"):format(a.targetValue) end,
        iconID = 236845,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Blood Elves joined the Ghostlands permanently. The zone's name is now literal thanks to you. Even the actual ghosts are filing complaints about overcrowding.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Ghostlands")
        end,
    },
    {
        id = "zone_alliance_ghostlands_1000",
        title = "Wraith of the Ghostlands",
        description = function(a) return ("Eliminate %d Blood Elves in Ghostlands"):format(a.targetValue) end,
        iconID = 236845,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Ghostlands! You've surpassed the Scourge as the zone's greatest threat. Children's ghost stories about you are scarier than tales of Dar'Khan. The Dead Scar is renamed 'The Dead [YOUR NAME] Was Here'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Ghostlands")
        end,
    },

    -- =====================================================
    -- AZUREMYST ISLE (Draenei Starting Zone)
    -- =====================================================
    {
        id = "zone_horde_azuremyst_100",
        title = "Azure Assassin",
        description = function(a) return ("Eliminate %d Draenei in Azuremyst Isle"):format(a.targetValue) end,
        iconID = 236839,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Draenei discovered that crashing their ship was only the beginning of their problems. You've made them regret ever finding Azeroth.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Azuremyst Isle")
        end,
    },
    {
        id = "zone_horde_azuremyst_250",
        title = "Crashed Party",
        description = function(a) return ("Eliminate %d Draenei in Azuremyst Isle"):format(a.targetValue) end,
        iconID = 236839,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses among the wreckage, Azuremyst Isle's recovery efforts are hampered more by you than the actual crash. The Exodar's priests work overtime on resurrections.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Azuremyst Isle")
        end,
    },
    {
        id = "zone_horde_azuremyst_500",
        title = "Island Invader",
        description = function(a) return ("Eliminate %d Draenei in Azuremyst Isle"):format(a.targetValue) end,
        iconID = 236839,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Draenei learned that the Light can't save them from you. The Exodar is considering emergency evacuation protocols. Players joke that you're worse than the Burning Legion.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Azuremyst Isle")
        end,
    },
    {
        id = "zone_horde_azuremyst_1000",
        title = "Exodar's Nightmare",
        description = function(a) return ("Eliminate %d Draenei in Azuremyst Isle"):format(a.targetValue) end,
        iconID = 236839,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills on Azuremyst Isle! You've made the Draenei wish they'd crashed somewhere else. The Burning Legion's pursuit seems merciful compared to your rampage. Prophet Velen has visions of you in his nightmares.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Azuremyst Isle")
        end,
    },

    -- =====================================================
    -- BLOODMYST ISLE (Draenei Zone)
    -- =====================================================
    {
        id = "zone_horde_bloodmyst_100",
        title = "Bloodmyst Butcher",
        description = function(a) return ("Eliminate %d Draenei in Bloodmyst Isle"):format(a.targetValue) end,
        iconID = 236840,
        achievementPoints = 25,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Bloodmyst Isle! The zone's name was prophetic. The Draenei thought the blood myst was bad—then they met you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Bloodmyst Isle")
        end,
    },
    {
        id = "zone_horde_bloodmyst_250",
        title = "Crimson Killer",
        description = function(a) return ("Eliminate %d Draenei in Bloodmyst Isle"):format(a.targetValue) end,
        iconID = 236840,
        achievementPoints = 50,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("With %d corpses on Bloodmyst Isle, you're living up to the zone's name better than the pollution. The satyr and naga are taking notes on your efficiency.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Bloodmyst Isle")
        end,
    },
    {
        id = "zone_horde_bloodmyst_500",
        title = "Mist of Death",
        description = function(a) return ("Eliminate %d Draenei in Bloodmyst Isle"):format(a.targetValue) end,
        iconID = 236840,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Draenei fell on Bloodmyst Isle. The pollution from the crashed ship is now the second most toxic thing on the island. You've claimed first place.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Bloodmyst Isle")
        end,
    },
    {
        id = "zone_horde_bloodmyst_1000",
        title = "Prophet of Doom",
        description = function(a) return ("Eliminate %d Draenei in Bloodmyst Isle"):format(a.targetValue) end,
        iconID = 236840,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills on Bloodmyst Isle! The Draenei fled the Burning Legion across the cosmos, only to find you waiting for them. Velen's prophecies never mentioned THIS. The Blood Watch is considering changing its name to 'Blood and [YOUR NAME] Watch'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_GetZoneKills(stats, ZONE_TRANSLATIONS_TBC, "Bloodmyst Isle")
        end,
    },
}
