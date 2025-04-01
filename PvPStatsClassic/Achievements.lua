local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

-- Define all achievements here
AchievementSystem.achievements = { -- Paladin Achievements
{
    id = "paladin_1",
    title = "Holy Moly",
    description = "Slay 100 Paladins",
    iconID = 135971, -- spell-holy-sealofwrath
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Paladins can be tough opponents with their healing abilities and plate armor. Take down 100 of these holy warriors to earn this achievement."
}, {
    id = "paladin_2",
    title = "Holy Moly Epic",
    description = "Slay 500 Paladins",
    iconID = 135971, -- spell-holy-sealofwrath
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Your reputation as a Paladin hunter grows. Defeat 500 Paladins to truly establish yourself as their nemesis."
}, {
    id = "paladin_3",
    title = "Holy Moly Legendary",
    description = "Slay 1000 Paladins",
    iconID = 135971, -- spell-holy-sealofwrath
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PALADIN"] or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The ultimate achievement for Paladin slayers. With 1000 Paladin eliminations, you've become a walking nightmare for anyone wielding the Light."
}, -- Priest Achievements
{
    id = "priest_1",
    title = "Shadow Hunter",
    description = "Defeat 100 Priests",
    iconID = 136207, -- spell-shadow-shadowwordpain
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Priests may be healers, but they're no match for your combat skills. Eliminate 100 Priests to earn this achievement."
}, {
    id = "priest_2",
    title = "Shadow Hunter Epic",
    description = "Defeat 300 Priests",
    iconID = 136207, -- spell-shadow-shadowwordpain
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Your hatred for the cloth-wearing healers burns with intensity. Take down 300 Priests to prove your dedication."
}, {
    id = "priest_3",
    title = "Shadow Hunter Legendary",
    description = "Defeat 600 Priests",
    iconID = 136207, -- spell-shadow-shadowwordpain
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["PRIEST"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Neither Light nor Shadow can save them from you. With 600 Priest kills, you've become the ultimate Priest hunter."
}, -- Druid Achievements
{
    id = "druid_1",
    title = "Bear Necessities",
    description = "Take down 100 Druids",
    iconID = 132276, -- ability_druid_maul
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Druids always think they can run away. 100 of them learned the hard way."
}, {
    id = "druid_2",
    title = "Feral Menace",
    description = "Take down 300 Druids",
    iconID = 132276,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Tree-huggers, cat-dashers, bear-soakers – 300 less to deal with."
}, {
    id = "druid_3",
    title = "Druid Destroyer",
    description = "Take down 600 Druids",
    iconID = 132276,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["DRUID"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Druids realized Nature isn't always kind."
}, -- Shaman Achievements
{
    id = "shaman_1",
    title = "Totem Smasher",
    description = "Defeat 100 Shamans",
    iconID = 136097, -- spell_nature_bloodlust
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Windfury doesn’t help when you're already dead. 100 Shamans learned that."
}, {
    id = "shaman_2",
    title = "Elemental Reckoning",
    description = "Defeat 300 Shamans",
    iconID = 136097,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "300 Shamans down, yet they never saw it coming. Their ancestors are disappointed."
}, {
    id = "shaman_3",
    title = "Shamanic Exorcism",
    description = "Defeat 600 Shamans",
    iconID = 136097,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["SHAMAN"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Shamans sent back to their Spirit World express delivery."
}, -- Hunter Achievements
{
    id = "hunter_1",
    title = "Pet Collector",
    description = "Take down 100 Hunters",
    iconID = 132213, -- ability_marksmanship
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Hunters, 100 confused pets still looking for their master."
}, {
    id = "hunter_2",
    title = "Deadeye Nemesis",
    description = "Take down 300 Hunters",
    iconID = 132213,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 300
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You dodged 300 Scatter Shots and still won. Respect."
}, {
    id = "hunter_3",
    title = "Hunter Becomes the Hunted",
    description = "Take down 600 Hunters",
    iconID = 132213,
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["HUNTER"] or 0) >= 600
    end,
    unlocked = false,
    completedDate = nil,
    subText = "600 Hunters thought they were the apex predator. They were wrong."
}, -- Warrior Achievements
{
    id = "warrior_1",
    title = "Warrior Slayer",
    description = "Eliminate 200 Warriors",
    iconID = 132355, -- ability-warrior-charge
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Warriors are everywhere on the battlefield. Show them who's boss by taking down 200 of these plate-wearers."
}, {
    id = "warrior_2",
    title = "Warrior Slayer Epic",
    description = "Eliminate 500 Warriors",
    iconID = 132355, -- ability-warrior-charge
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The battlefield is littered with the armor of Warriors you've defeated. Add 500 more to your tally."
}, {
    id = "warrior_3",
    title = "Warrior Slayer Legendary",
    description = "Eliminate 1000 Warriors",
    iconID = 132355, -- ability-warrior-charge
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARRIOR"] or 0) >= 1000
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 1000 Warrior kills, you've become a legend. Even the mightiest Warriors tremble at the mention of your name."
}, -- Mage Achievements
{
    id = "mage_1",
    title = "Mage Hunter",
    description = "Defeat 100 Mages",
    iconID = 135846, -- spell-frost-frostbolt02
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Mages may control the elements, but they can't control you. Defeat 100 of these spell-slingers."
}, {
    id = "mage_2",
    title = "Mage Crusher Epic",
    description = "Defeat 400 Mages",
    iconID = 135846, -- spell-frost-frostbolt02
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 400
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Fire, Frost, or Arcane - it doesn't matter to you. Take down 400 Mages to show your mastery."
}, {
    id = "mage_3",
    title = "Mage Crusher Legendary",
    description = "Defeat 800 Mages",
    iconID = 135846, -- spell-frost-frostbolt02
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["MAGE"] or 0) >= 800
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 800 Mage kills, you've become immune to their spells through sheer experience. The arcane arts hold no mystery for you."
}, -- Rogue Achievements
{
    id = "rogue_1",
    title = "Rogue Spotter",
    description = "Uncover and defeat 100 Rogues",
    iconID = 132320, -- ability-rogue-sinisterstrike
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Stealth won't save them from your keen senses. Find and eliminate 100 Rogues."
}, {
    id = "rogue_2",
    title = "Rogue Hunter Epic",
    description = "Uncover and defeat 250 Rogues",
    iconID = 132320, -- ability-rogue-sinisterstrike
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The shadows can't hide them from you anymore. Take down 250 Rogues to prove your vigilance."
}, {
    id = "rogue_3",
    title = "Rogue Hunter Legendary",
    description = "Uncover and defeat 500 Rogues",
    iconID = 132320, -- ability-rogue-sinisterstrike
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["ROGUE"] or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 500 Rogue eliminations, you've become the nightmare that haunts their dreams. No place to hide, no tricks left to play."
}, -- Warlock Achievements
{
    id = "warlock_1",
    title = "Warlock Banisher",
    description = "Banish 100 Warlocks",
    iconID = 136197, -- spell-shadow-shadowbolt
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Those who dabble in dark magic must face justice. Eliminate 100 Warlocks to begin your crusade."
}, {
    id = "warlock_2",
    title = "Warlock Nemesis Epic",
    description = "Banish 350 Warlocks",
    iconID = 136197, -- spell-shadow-shadowbolt
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 350
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The demons they summon cannot save them from your wrath. Defeat 350 Warlocks to continue your mission."
}, {
    id = "warlock_3",
    title = "Warlock Nemesis Legendary",
    description = "Banish 700 Warlocks",
    iconID = 136197, -- spell-shadow-shadowbolt
    condition = function(playerStats)
        return (playerStats.classKills and playerStats.classKills["WARLOCK"] or 0) >= 700
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 700 Warlock kills, you've become a cleansing flame against the darkness. Your legend strikes fear into the hearts of fel-wielders everywhere."
}, -- Female Gender Achievement
{
    id = "gender_female_1",
    title = "Ladies' Bane",
    description = "Defeat 50 female characters",
    iconID = 132938, -- spell-holy-powerwordshield
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "On the battlefield, you show no favoritism. Defeat 50 female characters to earn this achievement."
}, {
    id = "gender_female_2",
    title = "Ladies' Bane Epic",
    description = "Defeat 100 female characters",
    iconID = 132938, -- spell-holy-powerwordshield
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Your reputation for dispatching female opponents has grown. Eliminate 100 to prove your equal-opportunity approach to combat."
}, {
    id = "gender_female_3",
    title = "Ladies' Bane Legendary",
    description = "Defeat 200 female characters",
    iconID = 132938, -- spell-holy-powerwordshield
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["FEMALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 200 female character defeats, you've shown that chivalry has no place on the battlefield. Victory knows no gender."
}, -- Male Gender Achievement
{
    id = "gender_male_1",
    title = "Gentleman's Bane",
    description = "Defeat 50 male characters",
    iconID = 132333, -- ability-warrior-bladestorm
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Male characters often dominate the battlefields. Take down 50 of them to start making your mark."
}, {
    id = "gender_male_2",
    title = "Gentleman's Bane Epic",
    description = "Defeat 100 male characters",
    iconID = 132333, -- ability-warrior-bladestorm
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Continue your campaign against male opponents by defeating 100 of them in battle."
}, {
    id = "gender_male_3",
    title = "Gentleman's Bane Legendary",
    description = "Defeat 200 male characters",
    iconID = 132333, -- ability-warrior-bladestorm
    condition = function(playerStats)
        return (playerStats.genderKills and playerStats.genderKills["MALE"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "With 200 male character defeats, you've carved out a fearsome reputation. The battlefields echo with tales of your prowess."
},
{
    id = "race_human_1",
    title = "Extinction Event: Humanity",
    description = "Slay 50 Humans",
    iconID = 236456, -- ability_warrior_cleav
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["HUMAN"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They built cities, wrote history, and thought they were special. You’re here to prove them wrong."
}, {
    id = "race_human_2",
    title = "The Human Purge",
    description = "Slay 100 Humans",
    iconID = 236456,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["HUMAN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Tired of hearing about ‘the Alliance’? Send 100 of them to their precious Light."
}, {
    id = "race_human_3",
    title = "No More Kings",
    description = "Slay 200 Humans",
    iconID = 236456,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["HUMAN"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Stormwind calls for aid, but no one is left to answer. You are the reckoning."
},
-- Dwarf Achievements
{
    id = "race_dwarf_1",
    title = "Short-Lived",
    description = "Slay 50 Dwarves",
    iconID = 132333, -- ability_warrior_decisivestrike
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["DWARF"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You’d think centuries of drinking would prepare them for this. Guess not."
}, {
    id = "race_dwarf_2",
    title = "Drunken Massacre",
    description = "Slay 100 Dwarves",
    iconID = 132333,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["DWARF"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Sober or smashed, they all fall the same way."
}, {
    id = "race_dwarf_3",
    title = "Stone Meets Steel",
    description = "Slay 200 Dwarves",
    iconID = 132333,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["DWARF"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Legends say Dwarves are tough as mountains. You just turned 200 of them into gravel."
},
-- Night Elf Achievements
{
    id = "race_nightelf_1",
    title = "Treehugger Takedown",
    description = "Slay 50 Night Elves",
    iconID = 136074, -- spell_nature_starfall
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["NIGHTELF"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Nature won’t save you now, hippie."
}, {
    id = "race_nightelf_2",
    title = "Forest Fire",
    description = "Slay 100 Night Elves",
    iconID = 136074,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["NIGHTELF"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 centuries of wisdom—undone in seconds."
}, {
    id = "race_nightelf_3",
    title = "Teldrassil’s Second Burning",
    description = "Slay 200 Night Elves",
    iconID = 136074,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["NIGHTELF"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Ashes to ashes. And more ashes."
},
-- Gnome Achievements
{
    id = "race_gnome_1",
    title = "Small Victories",
    description = "Slay 50 Gnomes",
    iconID = 132484, -- inv_misc_gear_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["GNOME"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 Gnomes eliminated. One stomp at a time."
}, {
    id = "race_gnome_2",
    title = "Pint-Sized Peril",
    description = "Slay 100 Gnomes",
    iconID = 132484,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["GNOME"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Gnomes crushed. Their machines couldn't save them."
}, {
    id = "race_gnome_3",
    title = "Gnomeslayer Supreme",
    description = "Slay 200 Gnomes",
    iconID = 132484,
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["GNOME"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 Gnomes sent back to the scrap heap. Leper Gnomes might actually outnumber them now."
},
-- Orc Achievements
{
    id = "race_orc_1",
    title = "Green Menace",
    description = "Slay 50 Orc players",
    iconID = 236456, -- inv_axe_1h_orcwarrior_c_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["ORC"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "Orcs live for battle. Send 50 of them to the afterlife to prove who's boss."
},
{
    id = "race_orc_2",
    title = "Orcslayer",
    description = "Slay 100 Orc players",
    iconID = 236457, -- inv_axe_2h_orcwarrior_c_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["ORC"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They said the Horde would never fall. Prove them wrong—one corpse at a time."
},
{
    id = "race_orc_3",
    title = "Extinction Event",
    description = "Slay 200 Orc players",
    iconID = 236458, -- inv_axe_2h_orcwarrior_d_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["ORC"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You've cut down 200 Orcs. Their ancestors are weeping in Orgrimmar."
},

-- Undead Achievements
{
    id = "race_undead_1",
    title = "Corpse Collector",
    description = "Slay 50 Undead players",
    iconID = 135789, -- spell_shadow_deathanddecay
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["UNDEAD"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They’ve died once already. Send them back to the grave 50 more times."
},
{
    id = "race_undead_2",
    title = "Second Death",
    description = "Slay 100 Undead players",
    iconID = 135788, -- spell_shadow_requiem
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["UNDEAD"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Forsaken down. Maybe they’ll stay buried this time."
},
{
    id = "race_undead_3",
    title = "Necromancer's Nightmare",
    description = "Slay 200 Undead players",
    iconID = 135787, -- spell_shadow_haunting
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["UNDEAD"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 Undead eliminated. Sylvanas is running out of soldiers."
},

-- Tauren Achievements
{
    id = "race_tauren_1",
    title = "Steak Dinner",
    description = "Slay 50 Tauren players",
    iconID = 133974, -- inv_misc_food_meat_raw_04
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TAUREN"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 Tauren down. Time to fire up the grill."
},
{
    id = "race_tauren_2",
    title = "Bullfighter Extraordinaire",
    description = "Slay 100 Tauren players",
    iconID = 236189, -- inv_misc_food_meat_cooked_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TAUREN"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Tauren have fallen to your blade. Who’s the real beast now?"
},
{
    id = "race_tauren_3",
    title = "Bovine Genocide",
    description = "Slay 200 Tauren players",
    iconID = 133975, -- inv_misc_food_meat_raw_03
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TAUREN"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 Tauren down. The fields of Mulgore are empty."
},

-- Troll Achievements
{
    id = "race_troll_1",
    title = "No More Voodoo",
    description = "Slay 50 Troll players",
    iconID = 236471, -- inv_wand_1h_troll_d_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TROLL"] or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "50 Trolls down. Their gods didn’t help them."
},
{
    id = "race_troll_2",
    title = "Darkspear Extinction",
    description = "Slay 100 Troll players",
    iconID = 236472, -- inv_wand_1h_troll_b_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TROLL"] or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "100 Trolls have fallen. Soon, there’ll be no more left to dance."
},
{
    id = "race_troll_3",
    title = "Blood Ritual",
    description = "Slay 200 Troll players",
    iconID = 236473, -- inv_wand_1h_troll_c_01
    condition = function(playerStats)
        return (playerStats.raceKills and playerStats.raceKills["TROLL"] or 0) >= 200
    end,
    unlocked = false,
    completedDate = nil,
    subText = "200 Trolls sacrificed. Their spirits whisper your name in fear."
},
-- Killing Guilded Players Achievements
{
    id = "guild_prey_kills_1",
    title = "Shatter the Brotherhood",
    description = "Defeat 250 enemies who are in a guild",
    iconID = 132485, -- inv_bannerpvp_01
    condition = function(playerStats)
        return (playerStats.guildedKills or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "No oath can protect them. Tear down 250 guilded enemies and leave their allies to mourn."
}, {
    id = "guild_prey_kills_2",
    title = "Executioner of Legacies",
    description = "Defeat 500 enemies who are in a guild",
    iconID = 132485, -- inv_bannerpvp_01
    condition = function(playerStats)
        return (playerStats.guildedKills or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They thought their banners made them untouchable. 500 of their corpses now rot in the mud."
}, {
    id = "guild_prey_kills_3",
    title = "Ender of Bloodlines",
    description = "Defeat 700 enemies who are in a guild",
    iconID = 132485, -- inv_bannerpvp_01
    condition = function(playerStats)
        return (playerStats.guildedKills or 0) >= 700
    end,
    unlocked = false,
    completedDate = nil,
    subText = "700 guilded warriors silenced. Their comrades whisper your name, knowing they are next."
},

-- Killing Lone Wolves Achievements
{
    id = "lone_prey_kills_1",
    title = "Hunting the Stray",
    description = "Defeat 250 enemies who are not in a guild",
    iconID = 236687, -- ability_rogue_shadowdance
    condition = function(playerStats)
        return (playerStats.loneWolfKills or 0) >= 250
    end,
    unlocked = false,
    completedDate = nil,
    subText = "No allies, no safety, no mercy. Slaughter 250 lone wolves who thought they could survive alone."
}, {
    id = "lone_prey_kills_2",
    title = "Extinction of the Lone",
    description = "Defeat 500 enemies who are not in a guild",
    iconID = 236687, -- ability_rogue_shadowdance
    condition = function(playerStats)
        return (playerStats.loneWolfKills or 0) >= 500
    end,
    unlocked = false,
    completedDate = nil,
    subText = "They wander the battlefield, believing they are predators. 500 have learned otherwise."
}, {
    id = "lone_prey_kills_3",
    title = "Death Stalks the Drifter",
    description = "Defeat 700 enemies who are not in a guild",
    iconID = 236687, -- ability_rogue_shadowdance
    condition = function(playerStats)
        return (playerStats.loneWolfKills or 0) >= 700
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The loners, the outcasts, the rogues—all meet the same fate at your hands. 700 fallen, and still you hunger."
},
-- Killing Spree Achievements
{
    id = "killing_spree_1",
    title = "Unstoppable Force",
    description = "Defeat 25 players in a row without dying",
    iconID = 236310, -- ability_warrior_endlessrage
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 25
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You're picking up speed. 25 kills, no deaths. The battlefield is starting to notice."
}, {
    id = "killing_spree_2",
    title = "Warlord’s Momentum",
    description = "Defeat 50 players in a row without dying",
    iconID = 132344, -- ability_dualwield
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 50
    end,
    unlocked = false,
    completedDate = nil,
    subText = "The weak have fled, the brave have fallen. 50 kills, and nothing can stop you now."
}, {
    id = "killing_spree_3",
    title = "The Untouchable",
    description = "Defeat 75 players in a row without dying",
    iconID = 236273, -- spell_shadow_demonicpact
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 75
    end,
    unlocked = false,
    completedDate = nil,
    subText = "You don’t just fight—you dominate. 75 kills without falling? That’s legendary."
}, {
    id = "killing_spree_4",
    title = "Immortal Onslaught",
    description = "Defeat 100 players in a row without dying",
    iconID = 132275, -- inv_sword_48
    condition = function(playerStats)
        return (playerStats.highestKillStreak or 0) >= 100
    end,
    unlocked = false,
    completedDate = nil,
    subText = "A hundred enemies have tried. A hundred enemies have failed. You are the storm, the legend, the nightmare they whisper about."
}}

-- Function to check achievements and show popup if newly unlocked
function AchievementSystem:CheckAchievements()
    local playerStats = PVPSC.playerStats or {}

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(playerStats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M") -- Set completion date
            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = achievement.title,
                description = achievement.description
            })
        end
    end
end
