local addonName, PVPSC = ...

PVPSC.AchievementSystem = PVPSC.AchievementSystem or {}
local AchievementSystem = PVPSC.AchievementSystem

AchievementSystem.achievements = {
    {
        id = "class_paladin_0",
        title = "White Knight Down",
        description = function(a) return ("Slay %d Paladins"):format(a.targetValue) end,
        iconID = 626003,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        progress = function(achievement, stats)
            return stats.classData["Paladin"] or 0
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("They say 'I just want everyone to get along' while reporting half the BG for language. You’ve defeated %d Paladins who unironically post minion memes and call every woman “m’lady” in raid chat.")
                :format(a.targetValue)
        end,
    },
    {
        id = "class_paladin_1",
        title = "Bubble Popper",
        description = function(a) return ("Slay %d Paladins"):format(a.targetValue) end,
        iconID = 135896,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Divine Shield bubbles popped! Turns out, the Light doesn't save them when [YOUR NAME] is around.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Paladin"] or 0
        end,
    },
    {
        id = "class_paladin_2",
        title = "It's on cooldown...",
        description = function(a) return ("Slay %d Paladins"):format(a.targetValue) end,
        iconID = 134414,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Paladins discovered their Hearthstone was on cooldown. The Light abandoned them faster than their guild after a wipe.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Paladin"] or 0
        end,
    },
    {
        id = "class_paladin_3",
        title = "Divine Retirement Plan",
        description = function(a) return ("Slay %d Paladins"):format(a.targetValue) end,
        iconID = 133176,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Paladins judged and executed. Every one of them still lives in their childhood bedroom, gives unsolicited advice about honor, and thinks 'simp' is the ultimate insult. Their Tinder bios all include 'protector of women.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Paladin"] or 0
        end,
    },
    {
        id = "class_priest_0",
        title = "Therapy Session Over",
        description = function(a) return ("Defeat %d Priests"):format(a.targetValue) end,
        iconID = 626004,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Priests exorcised—and not just from the battlefield. These armchair therapists are one failed psych degree away from charging guildmates hourly. Every time you crit them, they ask if you're projecting.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Priest"] or 0
        end,
    },
    {
        id = "class_priest_1",
        title = "Holy Word: Death",
        description = function(a) return ("Defeat %d Priests"):format(a.targetValue) end,
        iconID = 135944,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Priests discovered that healing can't fix death! Their last confession? 'I should have rolled a Warlock.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Priest"] or 0
        end,
    },
    {
        id = "class_priest_2",
        title = "Scripture Shredder",
        description = function(a) return ("Defeat %d Priests"):format(a.targetValue) end,
        iconID = 135898,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Priests found out prayer cooldowns are longer than death timers! The Light's HR department is swamped with resignation letters.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Priest"] or 0
        end,
    },
    {
        id = "class_priest_3",
        title = "Religious Persecution",
        description = function(a) return ("Defeat %d Priests"):format(a.targetValue) end,
        iconID = 135922,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Priests discovered their Power Word: Shield was just plot armor! Churches now offer combat training instead of Sunday service.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Priest"] or 0
        end,
    },
    {
        id = "class_druid_0",
        title = "I'm VEGAN, bro!",
        description = function(a) return ("Take down %d Druids"):format(a.targetValue) end,
        iconID = 625999,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Druids sent back to their crystal shops! They're 'jack of all trades, master of none' incarnate but will still lecture you about your rotation. Their /yell macro includes the words 'spirit animal,' 'vibes,' and 'energy alignment,' and they've definitely tried to sell essential oils to their guildmates. Each one has explained they're vegan within 30 seconds of joining your party.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Druid"] or 0
        end,
    },
    {
        id = "class_druid_1",
        title = "Roadkill Royale",
        description = function(a) return ("Take down %d Druids"):format(a.targetValue) end,
        iconID = 132117,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Feral Druids brag about their movement speed—until they realize they’ve sprinted straight into %d unavoidable deaths. Some say Travel Form is fast. You know what’s faster? A corpse run.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Druid"] or 0
        end,
    },
    {
        id = "class_druid_2",
        title = "Animal Control",
        description = function(a) return ("Take down %d Druids"):format(a.targetValue) end,
        iconID = 236167,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Druids exterminated! Cat form, bear form, dead form – you've seen them all. PETA has issued a statement.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Druid"] or 0
        end,
    },
    {
        id = "class_druid_3",
        title = "Master of None",
        description = function(a) return ("Take down %d Druids"):format(a.targetValue) end,
        iconID = 132138,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Druids claim they can do it all—tank, heal, DPS. %d of them just proved they can also die in every imaginable way. At this point, even their Innervate couldn't restore their dignity.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Druid"] or 0
        end,
    },
    {
        id = "class_shaman_0",
        title = "Avatar State Deactivated",
        description = function(a) return ("Defeat %d Shamans"):format(a.targetValue) end,
        iconID = 626006,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Shamans eliminated! These wannabe Avatars binge-watched too many cartoons and thought they'd be bending all four elements in-game. Reality hit harder than your weapon when they discovered their totems don't actually shoot fire or create tsunamis. They spend most raids frantically alt-tabbing to YouTube tutorials trying to figure out what their class actually does. When asked about their role, they reply 'Yes' and then fail at all of them.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Shaman"] or 0
        end,
    },
    {
        id = "class_shaman_1",
        title = "Totem Kicker",
        description = function(a) return ("Defeat %d Shamans"):format(a.targetValue) end,
        iconID = 136052,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Shamans flattened — mostly Enhancement mains who picked the spec because someone told them Windfury makes big numbers. They’re now back in retail, crying about how Classic 'isn't fair'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Shaman"] or 0
        end,
    },
    {
        id = "class_shaman_2",
        title = "Spirit Walking Dead",
        description = function(a) return ("Defeat %d Shamans"):format(a.targetValue) end,
        iconID = 237589,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Shamans deleted their characters after realizing casting Lightning Bolt in melee range isn’t actually a good strategy. Their ancestors are embarrassed.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Shaman"] or 0
        end,
    },
    {
        id = "class_shaman_3",
        title = "Windfury Wipeout",
        description = function(a) return ("Defeat %d Shamans"):format(a.targetValue) end,
        iconID = 136088,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The world is down %d Shamans, and yet not a single one landed that mythical 3x Windfury crit. Meanwhile, Warriors are still laughing.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Shaman"] or 0
        end,
    },
    {
        id = "class_hunter_0",
        title = "Bear Grylls Roleplayers",
        description = function(a) return ("Take down %d Hunters"):format(a.targetValue) end,
        iconID = 626000,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You’ve taken out %d Hunters who say “trust your instincts” but can’t trust themselves to park straight. They bring up Bear Grylls in Discord like it's a personality trait and probably drink their own piss “ironically.”")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Hunter"] or 0
        end,
    },
    {
        id = "class_hunter_1",
        title = "I'm so special",
        description = function(a) return ("Take down %d Hunters"):format(a.targetValue) end,
        iconID = 132212,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Hunters down. All of them thought naming their pet 'Arthas' made them deep, and that spelling 'Légolâs' with special characters made them original. Congratulations — you just wiped out the world's largest unpaid cosplay convention.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Hunter"] or 0
        end,
    },
    {
        id = "class_hunter_2",
        title = "No More AFK Farmers and Backpedalers",
        description = function(a) return ("Take down %d Hunters"):format(a.targetValue) end,
        iconID = 132208,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Hunters eliminated—most didn’t even notice. Their corpses still have Auto Shot toggled on. And the other half are still backpedaling to the graveyard.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Hunter"] or 0
        end,
    },
    {
        id = "class_hunter_3",
        title = "Click… No Ammo",
        description = function(a) return ("Take down %d Hunters"):format(a.targetValue) end,
        iconID = 135618,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You’ve ended the WoW careers of %d Hunters — that’s %d dudes who think  they’re ‘PvP Gods’ because they once kited Bellygrub 40 yards to the Guards. Their last words? 'I swear I had ammo!'")
                :format(a.targetValue, a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Hunter"] or 0
        end,
    },
    {
        id = "class_warrior_0",
        title = "Protein Power Shortage",
        description = function(a) return ("Eliminate %d Warriors"):format(a.targetValue) end,
        iconID = 626008,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warriors down! These gym bros spent more time flexing in Ironforge than learning their rotation. Their emotional range is limited to 'mad,' 'hangry,' and 'where heals?' They consider counting to 10 as advanced mathematics and think reading quest text is for roleplayers. They also believe that 'PvP' stands for 'Protein vs. Pre-workout.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warrior"] or 0
        end,
    },
    {
        id = "class_warrior_1",
        title = "Rage Against The Machine",
        description = function(a) return ("Eliminate %d Warriors"):format(a.targetValue) end,
        iconID = 132333,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warriors deleted! These walking protein shakers with keyboards think smashing random buttons is a 'rotation.' Their Discord profile pics are all gym selfies, and their vocabulary consists exclusively of 'bro,' 'gains,' and 'where heals?' The anger management clinic just closed after losing all %d of their best customers to your weapon. The only thing they rage-quit faster than the battlefield is their cutting diet.")
                :format(a.targetValue, a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warrior"] or 0
        end,
    },
    {
        id = "class_warrior_2",
        title = "Execute.exe Has Failed",
        description = function(a) return ("Eliminate %d Warriors"):format(a.targetValue) end,
        iconID = 132355,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warriors deleted! These mouth-breathing keyboard smashers think strategy means hitting whatever isn't on cooldown. Their collective IQ is lower than their average item level, and that's saying something after you've repeatedly ganked them naked. The warrior's guild is hiring anyone with a pulse now—previous candidates eliminated by natural selection and your weapon.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warrior"] or 0
        end,
    },
    {
        id = "class_warrior_3",
        title = "Big Numbers, Small Brain",
        description = function(a) return ("Eliminate %d Warriors"):format(a.targetValue) end,
        iconID = 132346,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warriors down! Turns out, rolling the most played class doesn’t guarantee you rolled the smartest players.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warrior"] or 0
        end,
    },
    {
        id = "class_mage_0",
        title = "Actually, ...",
        description = function(a) return ("Defeat %d Mages"):format(a.targetValue) end,
        iconID = 626001,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,

        subText = function(a)
            return ("%d Mages deleted! Each one was three credits short of a philosophy degree but will lecture you about existentialism anyway. These self-proclaimed intellectuals memorized all their 'actually' rebuttals from Reddit posts and believe their IQ is 'too high to measure.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Mage"] or 0
        end,
    },
    {
        id = "class_mage_1",
        title = "Frost Nova'd Forever",
        description = function(a) return ("Defeat %d Mages"):format(a.targetValue) end,
        iconID = 135848,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Local inn reports %d frozen mage corpses! Their Ice Block and your Frostnova melted faster than their hopes of survival. At least they're well preserved.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Mage"] or 0
        end,
    },
    {
        id = "class_mage_2",
        title = "Cast Time Cancelled",
        description = function(a) return ("Defeat %d Mages"):format(a.targetValue) end,
        iconID = 135808,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("These %d mages learned that Pyroblast's cast time is longer than their life expectancy! Their last words were 'Just one more second...'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Mage"] or 0
        end,
    },
    {
        id = "class_mage_3",
        title = "Arcane Accident",
        description = function(a) return ("Defeat %d Mages"):format(a.targetValue) end,
        iconID = 135736,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("After %d failed Blink escapes, local mages are petitioning to make Blink work properly. So far, no response from their corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Mage"] or 0
        end,
    },
    {
        id = "class_rogue_0",
        title = "Energy Drink Depleted",
        description = function(a) return ("Uncover and defeat %d Rogues"):format(a.targetValue) end,
        iconID = 626005,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Rogues eliminated! You can smell the Monster Energy and Doritos from here. These walking red flags all type 'ez' after winning 5v1s against level 20s. They've got fingerless gloves IRL, a 'Damaged' tattoo somewhere visible, and spend their free time making TikToks about their 'sigma male grindset.' Every one of them has a mechanical keyboard with blue switches specifically to annoy their roommates.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Rogue"] or 0
        end,
    },
    {
        id = "class_rogue_1",
        title = "Cheap Shot Champion",
        description = function(a) return ("Uncover and defeat %d Rogues"):format(a.targetValue) end,
        iconID = 132092,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Found %d rogues the hard way! Their stealth wasn't as good as they thought - maybe they should've spent more time practicing and less time ganking lowbies?")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Rogue"] or 0
        end,
    },
    {
        id = "class_rogue_2",
        title = "Swept Off Their Feet",
        description = function(a) return ("Uncover and defeat %d Rogues"):format(a.targetValue) end,
        iconID = 132292,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Rogues got outplayed so hard, even Vanish couldn’t save them. The poison vendor is now offering a ‘No Refunds’ policy.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Rogue"] or 0
        end,
    },
    {
        id = "class_rogue_3",
        title = "xXShadowLegendXx Slayer",
        description = function(a) return ("Uncover and defeat %d Rogues"):format(a.targetValue) end,
        iconID = 132299,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d rogues with names like 'Stábbyou' and 'Shadowkilla' won't be making any more YouTube 'EPIC 1V5 WORLD PVP' videos! Their Discord status is now permanently set to 'offline'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Rogue"] or 0
        end,
    },
    {
        id = "class_warlock_0",
        title = "Wand Wielding Weirdo Wipeout",
        description = function(a) return ("Banish %d Warlocks"):format(a.targetValue) end,
        iconID = 626007,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d goths nuked! These misunderstood 'dark intellectuals' have black nail polish, a concerning collection of skeleton merchandise, and definitely own a katana. They've misquoted Nietzsche so many times that even their demons are rolling their eyes. Every guild message begins with 'I'm not trying to be negative, but...' before they proceed to be exactly that. ")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warlock"] or 0
        end,
    },
    {
        id = "class_warlock_1",
        title = "Demon't",
        description = function(a) return ("Banish %d Warlocks"):format(a.targetValue) end,
        iconID = 136218,
        achievementPoints = 25,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warlocks sent their demons back to HR! Soul Shards now come with a money-back guarantee.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warlock"] or 0
        end,
    },
    {
        id = "class_warlock_2",
        title = "Forgot the Stone, Didn’t You?",
        description = function(a) return ("Banish %d Warlocks"):format(a.targetValue) end,
        iconID = 134336,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warlocks perished, and not a single Soulstone in sight. Their last words? 'Bro, I thought you had one on me.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warlock"] or 0
        end,
    },
    {
        id = "class_warlock_3",
        title = "Curse you!",
        description = function(a) return ("Banish %d Warlocks"):format(a.targetValue) end,
        iconID = 135818,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Warlocks cursed you with everything they had—bad posture, social anxiety, and a Steam library full of games they'll never finish. Joke's on them: you were already cursed with exposure to their forum posts.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.classData["Warlock"] or 0
        end,
    },
    {
        id = "gender_gender_female_1",
        title = "Equal Rights, Equal Fights",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 134167,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d female characters slain! Equal opportunity combat at its finest. You've sent these ladies to respawn and didn't even hold the graveyard gate open for them.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Female"] or 0
        end,
    },
    {
        id = "gender_gender_female_2",
        title = "Premium Women's Rights Activist",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 132356,
        achievementPoints = 25,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d female characters deleted with extreme prejudice. The Ironforge 'Women's Protection Society' has placed a bounty on your head. Prepare for the shitstorm.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Female"] or 0
        end,
    },
    {
        id = "gender_gender_female_3",
        title = "She/Her/Dead",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 135906,
        achievementPoints = 50,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d female characters obliterated! Your battle cry 'Equal rights means equal fights!' echoes across Azeroth. You've been banned from every tavern in Stormwind.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Female"] or 0
        end,
    },
    {
        id = "gender_gender_female_4",
        title = "Wife Beater",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 135908,
        achievementPoints = 100,
        targetValue = 5000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d dead girls—yet somehow not a single woman touched grass in the process.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Female"] or 0
        end,
    },

    {
        id = "gender_gender_male_1",
        title = "Widowmaker",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 236557,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d husbands never made it home for dinner! Their wives are spending the Goblin Life Insurance payouts at the Auction House.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Male"] or 0
        end,
    },
    {
        id = "gender_gender_male_2",
        title = "Husband Hunter",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 132352,
        achievementPoints = 25,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d male characters destroyed! You're single-handedly responsible for a dating app boom in Azeroth. Lonely hearts everywhere.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Male"] or 0
        end,
    },
    {
        id = "gender_gender_male_3",
        title = "Masculinity Challenger",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 134166,
        achievementPoints = 50,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d males sent to their maker! The orphanages are overflowing and the wedding ring market has crashed. Economics, baby!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Male"] or 0
        end,
    },
    {
        id = "gender_gender_male_4",
        title = "Professional Man-Slayer",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 134006,
        achievementPoints = 100,
        targetValue = 5000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d men deleted — your kill feed looks like a gender reveal gone horribly wrong.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["Male"] or 0
        end,
    },
    {
        id = "bonus_horde",
        title = "Redridge Renovation",
        description = function(a) return ("Eliminate %d players in Redridge Mountains"):format(a.targetValue) end,
        iconID = 236814,
        achievementPoints = 0,
        targetValue = 10000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Redridge! At this point, the Horde is considering annexing the territory and renaming it 'Corpseridge.' Real estate agents are advertising it as 'Lordaeron South - Now with 100%% more corpses!' The Forsaken already filing paperwork to make it their summer vacation resort.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Redridge Mountains"] or 0
        end,
    },
    {
        id = "kills_total_0",
        title = "Death Distributor",
        description = function(a) return ("Get %d player kills"):format(a.targetValue) end,
        iconID = 236399, -- spell_shadow_shadowfury
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d player kills! The graveyard has a special registration line just for your victims. Spirit healers are filing for overtime pay and considering unionizing. The local coffin maker just bought a second home.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.totalKills or 0
        end,
    },
    {
        id = "kills_total_1",
        title = "Body Count Rising",
        description = function(a) return ("Get %d player kills"):format(a.targetValue) end,
        iconID = 236399, -- spell_shadow_shadowfury
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d bodies dropped! Barrens chat has already moved on to debating whether you're a bot, a multiboxer, or just deeply unhinged.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.totalKills or 0
        end,
    },
    {
        id = "kills_total_2",
        title = "Graveyard Entrepreneur",
        description = function(a) return ("Get %d player kills"):format(a.targetValue) end,
        iconID = 237542,
        achievementPoints = 50,
        targetValue = 5000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills! Spirit Healers are now offering you a commission for each body you send their way. The local gravediggers have named their shovels after you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.totalKills or 0
        end,
    },
    {
        id = "kills_total_3",
        title = "Death Incorporated",
        description = function(a) return ("Get %d player kills"):format(a.targetValue) end,
        iconID = 132205,
        achievementPoints = 100,
        targetValue = 10000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d confirmed kills! Even Mankrik’s wife had better odds of survival."):format(a
                .targetValue)
        end,
        progress = function(achievement, stats)
            return stats.totalKills or 0
        end,
    },
    {
        id = "kills_unique_0",
        title = "Face Collector",
        description = function(a) return ("Kill %d unique players"):format(a.targetValue) end,
        iconID = 133789,
        achievementPoints = 10,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d unique players have felt your wrath! Your kill list is longer than the server queue on launch day. You don't need a friends list—you have a victims catalog organized alphabetically for easy reference.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.uniqueKills or 0
        end,
    },
    {
        id = "kills_unique_1",
        title = "Variety Slayer",
        description = function(a) return ("Kill %d unique players"):format(a.targetValue) end,
        iconID = 133789,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d different players have fallen to you. At this point, you’re less of a PvPer and more of an extinction event. Azeroth is running out of fresh faces, and you’re the reason why.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.uniqueKills or 0
        end,
    },
    {
        id = "kills_unique_2",
        title = "Equal Opportunity Executioner",
        description = function(a) return ("Kill %d unique players"):format(a.targetValue) end,
        iconID = 133787,
        achievementPoints = 50,
        targetValue = 5000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d unique victims and counting! Players are now selling 'I Survived [YOUR NAME]' t-shirts - except none of them actually survived.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.uniqueKills or 0
        end,
    },
    {
        id = "kills_unique_3",
        title = "Celebrity Stalker",
        description = function(a) return ("Kill %d unique players"):format(a.targetValue) end,
        iconID = 133785,
        achievementPoints = 250,
        targetValue = 10000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d unique souls claimed! At this point, it's easier to list who you HAVEN'T killed. How’s that kill addiction treating you? ")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.uniqueKills or 0
        end,
    },

    {
        id = "race_human_0",
        title = "Human Error",
        description = function(a) return ("Eliminate %d Humans"):format(a.targetValue) end,
        iconID = 236447,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Humans dispatched! Their racial ability 'Every Man for Himself' should really be called 'Every Man for the Graveyard.' So much for human ingenuity.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Human"] or 0
        end,
    },
    {
        id = "race_human_1",
        title = "Human Resources",
        description = function(a) return ("Eliminate %d Humans"):format(a.targetValue) end,
        iconID = 134167,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Humans deleted! The most basic race in Azeroth, chosen by people who couldn’t be bothered to click twice. They died as they lived—completely unremarkable.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Human"] or 0
        end,
    },
    {
        id = "race_human_2",
        title = "Peak Meta, Peak Failure",
        description = function(a) return ("Eliminate %d Humans"):format(a.targetValue) end,
        iconID = 236448,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Humans down! They picked the ‘best PvP race’ for the racial bonuses but forgot to read the part about positioning and cooldowns.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Human"] or 0
        end,
    },
    {
        id = "race_human_3",
        title = "Uniqueness",
        description = function(a) return ("Eliminate %d Humans"):format(a.targetValue) end,
        iconID = 133730,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Humans permanently retired from Azeroth! The most basic, uninspired race choice in gaming history. These generic NPCs rolled Human because the character creation screen was 'too overwhelming' and they couldn't be bothered to scroll down. Half of them are definitely bots farming gold, the other half might as well be with their keyboard-turning skills. They all picked the 'optimal PvE race' based on some min-max guide and they thought they were 'playing the meta' but ended up being the punchline.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Human"] or 0
        end,
    },


    {
        id = "race_nightelf_0",
        title = "Nightlight Off",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 236449,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Night Elves slain! Half were dudes with 'Illidan' in their names trying to dual-wield everything, the other half were female characters made by players who just discovered hormones. Their deaths were as dramatic as their /dance animations. Time to let go of that purple dream, boys—Tyrande's not checking your DMs.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },
    {
        id = "race_nightelf_1",
        title = "Shadowmeld Won't Save You",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 134162,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You’ve deleted more Elves than bad Tolkien fanfics.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },
    {
        id = "race_nightelf_2",
        title = "Recycled by Force",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 236450,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Night Elf eco-warriors tried saving the trees, but couldn't save themselves. Composting at its finest. Your kill count just went carbon neutral.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },
    {
        id = "race_nightelf_3",
        title = "Plant-Based and Player-Slayed",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 134161,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Vegan diets, spirit guides, and herbal teas couldn't boost their stamina. Turns out positive vibes don't stop crits to the face. Now they're part of the soil — gluten-free, non-GMO, and 100%% biodegradable.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },


    {
        id = "race_dwarf_0",
        title = "Mumble rap",
        description = function(a) return ("Eliminate %d Dwarves"):format(a.targetValue) end,
        iconID = 236443,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Dwarves hammered down! These walking Scottish stereotypes died mumbling something that might have been a battle cry or just ordering another ale—nobody could understand a word through that accent. Next time they'll think twice before typing 'AYE LADDIE!' in every chat channel.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Dwarf"] or 0
        end,
    },
    {
        id = "race_dwarf_1",
        title = "Short Term Solution",
        description = function(a) return ("Eliminate %d Dwarves"):format(a.targetValue) end,
        iconID = 134160,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Dwarves crushed! Short, stout, and now six feet under. Their ‘legendary resilience’ apparently doesn’t apply when getting farmed for honor.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Dwarf"] or 0
        end,
    },
    {
        id = "race_dwarf_2",
        title = "Beard Trimmer",
        description = function(a) return ("Eliminate %d Dwarves"):format(a.targetValue) end,
        iconID = 236444,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Snow White and the %d Dead Dwarfs! Not even Disney magic could save this tragic tale. The remaining dwarfs changed their names to 'Corpsey,' 'Deady,' 'Respawny,' 'Campy,' 'Ganky,' 'Ragey,' and 'Doc' (who rerolled a Priest). Mining productivity has dropped 70%%, but beard wax sales plummeted 100%%.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Dwarf"] or 0
        end,
    },
    {
        id = "race_dwarf_3",
        title = "Height Disadvantage",
        description = function(a) return ("Eliminate %d Dwarves"):format(a.targetValue) end,
        iconID = 134159,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Ironforge engineers are designing smaller coffins after %d 'height-challenged' casualties! Their spirits are now discovering that the Great Forge isn't so great.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Dwarf"] or 0
        end,
    },


    {
        id = "race_gnome_0",
        title = "Lawn Ornament Collector",
        description = function(a) return ("Eliminate %d Gnomes"):format(a.targetValue) end,
        iconID = 236445,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Gnomes stepped on! All their engineering gadgets failed when they needed them most. At least they make cute decorations for your kill count.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Gnome"] or 0
        end,
    },
    {
        id = "race_gnome_1",
        title = "Pest Control",
        description = function(a) return ("Eliminate %d Gnomes"):format(a.targetValue) end,
        iconID = 134165,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Gnomes punted out of existence! Their last words? 'Size doesn’t matter!' Their respawn timer says otherwise. So do their wifes.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Gnome"] or 0
        end,
    },
    {
        id = "race_gnome_2",
        title = "Garden Gnome Collection",
        description = function(a) return ("Eliminate %d Gnomes"):format(a.targetValue) end,
        iconID = 236446,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Gnomes deleted. You’ve wiped more STEM majors than a Silicon Valley hiring freeze. Their gadgets couldn’t save them, and their last words were all keyboard macros no one understood")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Gnome"] or 0
        end,
    },
    {
        id = "race_gnome_3",
        title = "Small Problems Solved",
        description = function(a) return ("Eliminate %d Gnomes"):format(a.targetValue) end,
        iconID = 134164,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Gnomes down, and every single one had 'server admin' in their Twitter bio. You didn’t just kill characters—you killed the dream of moderating a Minecraft server empire.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Gnome"] or 0
        end,
    },


    {
        id = "race_orc_0",
        title = "Orc Slayer",
        description = function(a) return ("Eliminate %d Orcs"):format(a.targetValue) end,
        iconID = 236451,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Orcs sent to meet their ancestors! Their blood fury only made your attacks hurt more. So much for orcish resilience when faced with your wrath.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Orc"] or 0
        end,
    },
    {
        id = "race_orc_1",
        title = "Green Peace",
        description = function(a) return ("Eliminate %d Orcs"):format(a.targetValue) end,
        iconID = 134171,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Zug zug? More like zug zugged into the grave. %d Orcs charged in, expecting an easy win—turns out, yelling ‘Lok’tar Ogar!’ doesn’t make you invincible.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Orc"] or 0
        end,
    },
    {
        id = "race_orc_2",
        title = "Anger Management Expert",
        description = function(a) return ("Eliminate %d Orcs"):format(a.targetValue) end,
        iconID = 236452,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Orcs have rage-quit after meeting you! These keyboard smashers with names like 'Gorégut' and 'Axemastr' spent more time perfecting their /flex macro than learning to dodge. Greenpeace has formally requested you stop this endangered species extinction event. Their Blood Fury racial activated IRL as they typed angry whispers to you from the graveyard.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Orc"] or 0
        end,
    },
    {
        id = "race_orc_3",
        title = "Green Graveyard",
        description = function(a) return ("Eliminate %d Orcs"):format(a.targetValue) end,
        iconID = 134170,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d min-maxing Orc players just discovered their PvP racial doesn't help when they keyboard turn! These meta-chasers who rolled the 'optimal race' couldn't optimize their way out of a [YOUR NAME] beatdown. All those forum guides didn't prepare them for someone who actually knows how to play. Should've practiced instead of bragging about stun resistance in trade chat!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Orc"] or 0
        end,
    },


    {
        id = "race_undead_0",
        title = "Re-dead",
        description = function(a) return ("Eliminate %d Undead"):format(a.targetValue) end,
        iconID = 236457,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Undead returned to their graves! Turns out being already dead doesn't make you immune to a second death. Will of the Forsaken? More like Will to Respawn.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Undead"] or 0
        end,
    },
    {
        id = "race_undead_1",
        title = "Double Dead",
        description = function(a) return ("Eliminate %d Undead"):format(a.targetValue) end,
        iconID = 134180,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Forsaken sent back to the character creation screen. Turns out, playing ‘the most hardcore race’ doesn’t make you any less of a free HK. Sylvanas won’t miss them—she doesn’t even miss her own people.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Undead"] or 0
        end,
    },
    {
        id = "race_undead_2",
        title = "Zombies't",
        description = function(a) return ("Eliminate %d Undead"):format(a.targetValue) end,
        iconID = 236458,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Forsaken ganked! They picked Undead to look cool and ended up looking clueless. No, ‘Will of the Forsaken’ doesn’t make you invincible—if it did, they wouldn’t all be face-down in the dirt")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Undead"] or 0
        end,
    },
    {
        id = "race_undead_3",
        title = "Permanent Death Status",
        description = function(a) return ("Eliminate %d Undead"):format(a.targetValue) end,
        iconID = 136187,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Forsaken now even more dead than before! The Dark Lady's weekly newsletter now includes a [YOUR NAME] survival guide. These edgelords thought being already-dead made them cool until you showed them what 'dead-dead' feels like. Now Brill is a ghost town (even more than usual), and Tirisfal Glades real estate is free for the taking. Even the Scarlet Crusade thinks you're taking this whole 'purging the undead' thing too far.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Undead"] or 0
        end,
    },


    {
        id = "race_troll_0",
        title = "Troll Hunter",
        description = function(a) return ("Eliminate %d Trolls"):format(a.targetValue) end,
        iconID = 236455,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Trolls made to stay dead! Their regeneration couldn't keep up with your damage output. The Darkspear tribe is sending angry letters about their population decline.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Troll"] or 0
        end,
    },
    {
        id = "race_troll_1",
        title = "Voodoo Venue Closed",
        description = function(a) return ("Eliminate %d Trolls"):format(a.targetValue) end,
        iconID = 134178,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Da spirits be VERY angry wit' you mon, after %d trolls found out their regeneration can't outpace your damage output. Their hunched backs didn't help them dodge your attacks—just made it easier for you to spot them from a distance. Zul'jin is considering therapy after watching your killing spree. Stay away from da voodoo!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Troll"] or 0
        end,
    },
    {
        id = "race_troll_2",
        title = "Berserking Backfire",
        description = function(a) return ("Eliminate %d Trolls"):format(a.targetValue) end,
        iconID = 236456,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d trolls slain! Just like the keyboard warriors who play them—they talked big in forums but fell silent in actual combat. These Reddit moderators and Twitter reply-guys picked Trolls because they thought it was their spirit animal. They spammed 'git gud' to newbies while getting absolutely destroyed by you. The irony of trolls getting trolled is not lost on the rest of the server. Their abandoned forum accounts are now collecting dust just like their corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Troll"] or 0
        end,
    },
    {
        id = "race_troll_3",
        title = "Hunched Back, Hunched Over in Defeat",
        description = function(a) return ("Eliminate %d Trolls"):format(a.targetValue) end,
        iconID = 134177,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Trolls down! Their posture wasn’t the only thing broken today. Maybe they should’ve berserked their way to a real strategy instead of just hoping their racial would carry them.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Troll"] or 0
        end,
    },


    {
        id = "race_tauren_0",
        title = "Sacred Cow",
        description = function(a) return ("Eliminate %d Tauren"):format(a.targetValue) end,
        iconID = 236453,
        achievementPoints = 10,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Tauren sent to the great plains in the sky! Those war stomps were no match for your superior combat skills. The Earth Mother has filed a complaint about your treatment of her children.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Tauren"] or 0
        end,
    },
    {
        id = "race_tauren_1",
        title = "Biggest Hitbox, Biggest Target",
        description = function(a) return ("Eliminate %d Tauren"):format(a.targetValue) end,
        iconID = 134175,
        achievementPoints = 25,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Tauren down! These walking steaks chose the biggest hitbox in the game then complained when your attacks connected. McDonald's just offered you a sponsorship deal after your record-breaking beef production. The 'got milk?' campaign is suing you for destroying their mascots. Next time they'll think twice before picking a race that can be seen from the other continent.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Tauren"] or 0
        end,
    },
    {
        id = "race_tauren_2",
        title = "No More Bull",
        description = function(a) return ("Eliminate %d Tauren"):format(a.targetValue) end,
        iconID = 236454,
        achievementPoints = 50,
        targetValue = 2000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Tauren players got exactly what they deserved for picking the 'gentle giant' stereotype! Their 5%% bonus health just meant they died 3 seconds slower while panic-pressing War Stomp. The real stampede was them rushing to the forums to complain about 'unfair pvp balance.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Tauren"] or 0
        end,
    },
    {
        id = "race_tauren_3",
        title = "Cattle Depopulation",
        description = function(a) return ("Eliminate %d Tauren"):format(a.targetValue) end,
        iconID = 134174,
        achievementPoints = 100,
        targetValue = 4000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've slaughtered %d Tauren! Thunder Bluff elevator accidents are now the SECOND leading cause of Tauren death. These gentle giants had 5%% more health than other races, which gave them exactly 3 extra seconds to contemplate their life choices before you ended them. Mulgore's milk industry has collapsed, and the Grimtotem are sending you fan mail. The Earth Mother has filed a restraining order against you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Tauren"] or 0
        end,
    },
    {
        id = "race_alliance_mixed_human_nightelf_dwarf_gnome_100",
        title = "Alliance Sampler Platter",
        description = function(a) return ("Eliminate %d of each Alliance race (400 total)"):format(a.targetValue) end,
        iconID = 133784,
        achievementPoints = 75,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've achieved perfect Alliance genocide balance! %d Humans, %d Gnomes, %d Dwarves, and %d Night Elves - that's equality in death! Stormwind's diversity committee is impressed by your non-discriminatory killing approach. You're like a serial killer with OCD, but for racial statistics.")
                :format(a.targetValue, a.targetValue, a.targetValue, a.targetValue)
        end,
        progress = function(achievement, stats)
            local humans = stats.raceData["Human"] or 0
            local gnomes = stats.raceData["Gnome"] or 0
            local dwarves = stats.raceData["Dwarf"] or 0
            local nightElves = stats.raceData["Night Elf"] or 0
            return math.min(humans, gnomes, dwarves, nightElves)
        end,
    },
    {
        id = "race_alliance_mixed_human_nightelf_dwarf_gnome_250",
        title = "Alliance Census Corrector",
        description = function(a) return ("Eliminate %d of each Alliance race (1000 total)"):format(a.targetValue) end,
        iconID = 133785,
        achievementPoints = 125,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Perfect Alliance extermination ratios achieved! %d kills per race shows your commitment to fair and balanced genocide. The Alliance leadership is considering renaming their faction to 'The Survivors of [YOUR NAME].' Even King Varian is impressed by your mathematical precision in mass murder.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local humans = stats.raceData["Human"] or 0
            local gnomes = stats.raceData["Gnome"] or 0
            local dwarves = stats.raceData["Dwarf"] or 0
            local nightElves = stats.raceData["Night Elf"] or 0
            return math.min(humans, gnomes, dwarves, nightElves)
        end,
    },
    {
        id = "race_alliance_mixed_human_nightelf_dwarf_gnome_500",
        title = "Alliance Demographic Disaster",
        description = function(a) return ("Eliminate %d of each Alliance race (2000 total)"):format(a.targetValue) end,
        iconID = 133786,
        achievementPoints = 200,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've single-handedly caused an Alliance population crisis! %d deaths per race means their birth rates can't keep up with your kill rate. Stormwind's Bureau of Statistics has classified you as a 'natural disaster.' The remaining Alliance players are considering a class action lawsuit against Blizzard for allowing you to exist.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local humans = stats.raceData["Human"] or 0
            local gnomes = stats.raceData["Gnome"] or 0
            local dwarves = stats.raceData["Dwarf"] or 0
            local nightElves = stats.raceData["Night Elf"] or 0
            return math.min(humans, gnomes, dwarves, nightElves)
        end,
    },
    {
        id = "race_alliance_mixed_human_nightelf_dwarf_gnome_1000",
        title = "Alliance Extinction Protocol",
        description = function(a) return ("Eliminate %d of each Alliance race (4000 total)"):format(a.targetValue) end,
        iconID = 133787,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("LEGENDARY GENOCIDE ACHIEVEMENT! You've eliminated %d of each Alliance race with surgical precision. This level of systematic extermination would make even the Burning Legion jealous. The Alliance has officially petitioned the UN (United NPCs) to classify you as a war criminal. Congratulations, you've achieved what Arthas, Illidan, and Deathwing combined couldn't: perfect racial balance through annihilation!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local humans = stats.raceData["Human"] or 0
            local gnomes = stats.raceData["Gnome"] or 0
            local dwarves = stats.raceData["Dwarf"] or 0
            local nightElves = stats.raceData["Night Elf"] or 0
            return math.min(humans, gnomes, dwarves, nightElves)
        end,
    },
    {
        id = "class_mixed_warrior_paladin_hunter_rogue_priest_shaman_mage_warlock_druid_100",
        title = "Class Warfare Initiate",
        description = function(a) return ("Execute %d of each class"):format(a.targetValue) end,
        iconID = 132147,
        achievementPoints = 75,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Perfect class extermination achieved. %d deaths per class - no favorites, no mercy. Equal opportunity murder across all professions.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local playerFaction = UnitFactionGroup("player")
            if playerFaction == "Horde" then
                local warrior = stats.classData["Warrior"] or 0
                local paladin = stats.classData["Paladin"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, paladin, hunter, rogue, priest, mage, warlock, druid)
            else
                local warrior = stats.classData["Warrior"] or 0
                local shaman = stats.classData["Shaman"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, shaman, hunter, rogue, priest, mage, warlock, druid)
            end
        end,
    },
    {
        id = "class_mixed_warrior_paladin_hunter_rogue_priest_shaman_mage_warlock_druid_250",
        title = "Professional Exterminator",
        description = function(a) return ("Execute %d of each class"):format(a.targetValue) end,
        iconID = 132349,
        achievementPoints = 125,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("All classes equally decimated. %d corpses per profession. Your methodical approach to mass murder shows disturbing efficiency.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local playerFaction = UnitFactionGroup("player")
            if playerFaction == "Horde" then
                local warrior = stats.classData["Warrior"] or 0
                local paladin = stats.classData["Paladin"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, paladin, hunter, rogue, priest, mage, warlock, druid)
            else
                local warrior = stats.classData["Warrior"] or 0
                local shaman = stats.classData["Shaman"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, shaman, hunter, rogue, priest, mage, warlock, druid)
            end
        end,
    },
    {
        id = "class_mixed_warrior_paladin_hunter_rogue_priest_shaman_mage_warlock_druid_500",
        title = "Class Genocide Specialist",
        description = function(a) return ("Execute %d of each class"):format(a.targetValue) end,
        iconID = 135999,
        achievementPoints = 125,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Systematic class annihilation complete. %d deaths per class. Your kill count reads like a perfectly balanced apocalypse.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local playerFaction = UnitFactionGroup("player")
            if playerFaction == "Horde" then
                local warrior = stats.classData["Warrior"] or 0
                local paladin = stats.classData["Paladin"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, paladin, hunter, rogue, priest, mage, warlock, druid)
            else
                local warrior = stats.classData["Warrior"] or 0
                local shaman = stats.classData["Shaman"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, shaman, hunter, rogue, priest, mage, warlock, druid)
            end
        end,
    },
    {
        id = "class_mixed_warrior_paladin_hunter_rogue_priest_shaman_mage_warlock_druid_1000",
        title = "The Great Leveler",
        description = function(a) return ("Execute %d of each class"):format(a.targetValue) end,
        iconID = 136149,
        achievementPoints = 250,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Ultimate class extinction achieved. %d corpses per class. You've reduced all professions to statistical equality through systematic slaughter.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local playerFaction = UnitFactionGroup("player")
            if playerFaction == "Horde" then
                local warrior = stats.classData["Warrior"] or 0
                local paladin = stats.classData["Paladin"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, paladin, hunter, rogue, priest, mage, warlock, druid)
            else
                local warrior = stats.classData["Warrior"] or 0
                local shaman = stats.classData["Shaman"] or 0
                local hunter = stats.classData["Hunter"] or 0
                local rogue = stats.classData["Rogue"] or 0
                local priest = stats.classData["Priest"] or 0
                local mage = stats.classData["Mage"] or 0
                local warlock = stats.classData["Warlock"] or 0
                local druid = stats.classData["Druid"] or 0
                return math.min(warrior, shaman, hunter, rogue, priest, mage, warlock, druid)
            end
        end,
    },
    -- {
    --     id = "kills_guild",
    --     title = "Guild Drama Generator",
    --     description = function(a) return ("Eliminate %d guild members"):format(a.targetValue) end,
    --     iconID = 134473,
    --     achievementPoints = 50,
    --     targetValue = 500,
    --     condition = function(achievement, stats)
    --         return achievement.progress(achievement, stats) >= achievement.targetValue
    --     end,
    --     unlocked = false,
    --     completedDate = nil,
    --     subText = function(a)
    --         return ("%d so-called 'guildmates' slaughtered! Turns out, that guild tag above their heads didn’t make them any less squishy. Maybe they should try a PvE guild—less world PvP, more coping in raid chat.")
    --             :format(a.targetValue)
    --     end,
    --     progress = function(achievement, stats)
    --         return stats.guildStatusData["In Guild"] or 0
    --     end,
    -- },
    {-- Kill Streak Achievements
        id = "kills_streak_25",
        title = "Serial Killer",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 133728,
        achievementPoints = 10,
        targetValue = 25,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players deleted in a row! The graveyard is installing a '[YOUR NAME] Express Lane' with a self-checkout option.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_50",
        title = "Crime Scene",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236566,
        achievementPoints = 25,
        targetValue = 50,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d consecutive kills! Azeroth's investigators are gathering evidence, but all the witnesses keep mysteriously disappearing.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_75",
        title = "Mass Extinction",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236358,
        achievementPoints = 50,
        targetValue = 75,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills without dying? Players are filing tickets claiming you're hacking. Blizzard responded: 'No, they're just that good.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_100",
        title = "TRIPLE D!!!",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236682,
        achievementPoints = 75,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Triple digits! Damage, Devastation, Depression — the enemy faction unlocked all three achievements at once.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_125",
        title = "PvP Plague",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 136123,
        achievementPoints = 75,
        targetValue = 125,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You're not a player anymore—you're a server-wide debuff. Whole zones avoid you like it's patch day. %d kills and not a single scratch? That’s not PvP. That’s population control.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_150",
        title = "Fine Wine",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 132789,
        achievementPoints = 100,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d uninterrupted kills! You're not just killing players—you're killing server populations. Like a fine wine, your murder spree only improves with time.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_175",
        title = "Unstoppable Force",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 133050,
        achievementPoints = 100,
        targetValue = 175,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d bodies and counting! Like the legendary Alterac Valley weapon, you've become a force of nature—slow, powerful, and absolutely devastating. The Immovable Object has finally met its match, and it's your kill streak. Players have started putting 'killed by [YOUR NAME]' in their forum signatures as a badge of honor.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_200",
        title = "Top 0.01%",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 136101,
        achievementPoints = 100,
        targetValue = 200,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("200 players down! If this were Hearthstone, you'd be Top 0.01%%—instead, you're out here making real card backs out of enemy corpses. Stay legendary.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_225",
        title = "/flex",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236370,
        achievementPoints = 250,
        targetValue = 225,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d unbroken kills! Your /flex emote now causes a 10-yard fear. Even raid bosses check their aggro tables when you log in. Blizzard added a new GM macro: /who [YOUR NAME] – for threat assessment.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_250",
        title = "Thumbs up!",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236375,
        achievementPoints = 250,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("https://knowyourmeme.com/memes/brent-rambo")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_275",
        title = "Faction Change Approved",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 1126583,
        achievementPoints = 250,
        targetValue = 275,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d victims later, half your enemies swapped factions. The rest swapped hobbies.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_300",
        title = "Main Character Syndrome",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 1126585,
        achievementPoints = 500,
        targetValue = 300,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d corpses. They logged onto their 'real' mains... and you killed those too. Dreams crushed.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_325",
        title = "Delete or Be Deleted",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 442272,
        achievementPoints = 500,
        targetValue = 325,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You didn't just defeat %d players — you defeated their entire friends list too.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_streak_350",
        title = "Unsubbed and Unloved",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236671,
        achievementPoints = 500,
        targetValue = 350,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d unsubbed. Blizzard sent them a 'we miss you' email — and you a trophy. SICK!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
        end,
    },
    {
        id = "kills_guildless",
        title = "Lone Wolf Hunter",
        description = function(a) return ("Eliminate %d guildless players"):format(a.targetValue) end,
        iconID = 132203,
        achievementPoints = 50,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Sent %d 'social anxiety' players back to retail! Their 'I don't need a guild to play' attitude didn't help against your killing spree. At least they didn't have to explain their deaths in guild chat.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.guildStatusData["No Guild"] or 0
        end,
    },
    {
        id = "kills_guild_25_same",
        title = "Guild Crasher",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134473,
        achievementPoints = 25,
        targetValue = 25,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d guild members eliminated! Their Discord server now has more 'F' reactions than actual messages. Guild recruitment posts updated to include 'PTSD counseling available.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_50_same",
        title = "Guild Extinction Event",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134471,
        achievementPoints = 50,
        targetValue = 50,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d members of the same guild sent packing! You've caused more guild drama than a ninja-looted rare mount. Their group therapy sessions are booked solid.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_75_same",
        title = "Guild Disbander",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134472,
        achievementPoints = 75,
        targetValue = 75,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d guild members deleted! The guild bank is now just a memorial to better times. Their Discord renamed to 'Survivors Anonymous' with declining membership.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_100_same",
        title = "Guild Genocide",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134470,
        achievementPoints = 100,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d members obliterated! You've achieved complete guild annihilation. Their recruitment posts now specify 'emotional stability required' as a hard requirement.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_25_different",
        title = "Guild Hopper",
        description = function(a) return ("Eliminate players from %d different guilds"):format(a.targetValue) end,
        iconID = 134328,
        achievementPoints = 25,
        targetValue = 25,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Killed members from %d different guilds! You're like a traveling door-to-door salesman, except you're selling death and business is booming.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local uniqueGuilds = 0
            for guildName, count in pairs(stats.guildData) do
                if count > 0 then
                    uniqueGuilds = uniqueGuilds + 1
                end
            end
            return uniqueGuilds
        end,
    },
    {
        id = "kills_guild_50_different",
        title = "Inter-Guild Warfare",
        description = function(a) return ("Eliminate players from %d different guilds"):format(a.targetValue) end,
        iconID = 134327,
        achievementPoints = 50,
        targetValue = 50,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Assassinated members from %d different guilds! You've united the server in one common goal: avoiding you. Monthly guild meetings now include trauma counseling.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local uniqueGuilds = 0
            for guildName, count in pairs(stats.guildData) do
                if count > 0 then
                    uniqueGuilds = uniqueGuilds + 1
                end
            end
            return uniqueGuilds
        end,
    },
    {
        id = "kills_guild_125_same",
        title = "Guild Annihilation Protocol",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134468,
        achievementPoints = 125,
        targetValue = 125,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d members eliminated! Their guild charter changed to a death certificate. The remaining members hired lawyers, but they keep mysteriously dying too.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_150_same",
        title = "Guild Extinction Protocol",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134467,
        achievementPoints = 125,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d guild members sent to the afterlife! Their Discord requires therapy credentials to join. Recruitment updated to 'fast respawn times preferred.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_200_same",
        title = "Guild Apocalypse",
        description = function(a) return ("Eliminate %d players from the same guild"):format(a.targetValue) end,
        iconID = 134466,
        achievementPoints = 250,
        targetValue = 200,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d members absolutely destroyed! The guild name added to the endangered species list. Archaeological teams studying their guild hall remains.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local maxSameGuild = 0
            for guildName, count in pairs(stats.guildData) do
                if count > maxSameGuild then
                    maxSameGuild = count
                end
            end
            return maxSameGuild
        end,
    },
    {
        id = "kills_guild_75_different",
        title = "Guild Network Destroyer",
        description = function(a) return ("Eliminate players from %d different guilds"):format(a.targetValue) end,
        iconID = 134326,
        achievementPoints = 125,
        targetValue = 75,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Eliminated members from %d different guilds! Guild leaders formed a 'Stop the Madness' coalition. Meeting attendance: 10%% (everyone's too scared to leave town).")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local uniqueGuilds = 0
            for guildName, count in pairs(stats.guildData) do
                if count > 0 then
                    uniqueGuilds = uniqueGuilds + 1
                end
            end
            return uniqueGuilds
        end,
    },
    {
        id = "kills_guild_100_different",
        title = "Server-Wide Guild Pandemic",
        description = function(a) return ("Eliminate players from %d different guilds"):format(a.targetValue) end,
        iconID = 134325,
        achievementPoints = 250,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Devastated members from %d different guilds! You've united every guild in shared trauma. The server forums have a support group sticky with more posts than trading.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            if not stats.guildData then return 0 end
            local uniqueGuilds = 0
            for guildName, count in pairs(stats.guildData) do
                if count > 0 then
                    uniqueGuilds = uniqueGuilds + 1
                end
            end
            return uniqueGuilds
        end,
    },
    {
        id = "kills_favorite_target",
        title = "Personal Vendetta",
        description = function(a) return ("Kill the same player %d times"):format(a.targetValue) end,
        iconID = 136168,
        achievementPoints = 100,
        targetValue = 10,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            local charactersToProcess = {}
            local currentCharacterKey = PSC_GetCharacterKey()
            charactersToProcess[currentCharacterKey] = PSC_DB.PlayerKillCounts.Characters[currentCharacterKey]
            local stats = PSC_CalculateSummaryStatistics(charactersToProcess)
            local playerName = stats.mostKilledPlayer or "Unknown"
            local killCount = stats.mostKilledCount or 0

            if playerName == "None" or killCount < 10 then
                return "You have developed an unhealthy obsession with " .. playerName
            end
            return playerName ..
                " has died to you " ..
                killCount ..
                " times! They've added your name to their '/who' macro and log off the moment you appear online. Their guild required them to change their hearthstone to a new continent just to avoid you. Every night, they check under their bed for [YOUR NAME] before going to sleep."
        end,
        progress = function(achievement, stats)
            return stats.mostKilledCount or 0
        end,
    },
    {
        id = "kills_multi_3",
        title = "Triple Kill!",
        description = function(a) return ("Get %d kills in a single combat"):format(a.targetValue) end,
        iconID = 236330,
        achievementPoints = 25,
        targetValue = 3,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("ACE! Three champions... er, players... fell to your blade in quick succession. The enemy team is crying 'nerf [YOUR NAME]' in all chat. Your Summoner Score is rising!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestMultiKill or 0
        end,
    },
    {
        id = "kills_multi_4",
        title = "QUADRA KILL!",
        description = function(a) return ("Get %d kills in a single combat"):format(a.targetValue) end,
        iconID = 236341,
        achievementPoints = 50,
        targetValue = 4,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The crowd goes wild as you secure your fourth elimination! 'GG [YOUR NAME] diff' echoes across Azeroth. The enemy team is calling for a surrender vote while spamming 'Report jungler no ganks' in chat.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestMultiKill or 0
        end,
    },
    {
        id = "kills_multi_5",
        title = "PENTAKILL!!",
        description = function(a) return ("Get %d kills in a single combat"):format(a.targetValue) end,
        iconID = 236383,
        achievementPoints = 100,
        targetValue = 5,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("LEGENDARY! You just went full Faker on these noobs! 'GG EZ' has never been more appropriate. The enemy team pressed Alt + F4 simultaneously and uninstalled the game. Your MVP status is unrivaled, and Riot Games is sending you a cease and desist letter for being too OP.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestMultiKill or 0
        end,
    },
    {
        id = "kills_multi_10",
        title = "DECA-STRUCTION!",
        description = function(a) return ("Get %d kills in a single combat"):format(a.targetValue) end,
        iconID = 236383,
        achievementPoints = 250,
        targetValue = 10,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("TEN PLAYERS IN ONE GO! This isn't PvP anymore—it's a mass extinction event! League of Legends players are accusing you of 'killstealing,' Blizzard devs are analyzing your combat logs for exploits, and forum moderators had to create a special thread just for the salt. The enemy faction has officially added 'Avoid [YOUR NAME] at all costs' to their leveling guides. Your name now triggers PTSD in half the server population.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestMultiKill or 0
        end,
    },
    {
        id = "kills_grey_level",
        title = "Teach them young",
        description = function(a) return ("Eliminate %d grey-level players"):format(a.targetValue) end,
        iconID = 134435,
        achievementPoints = 100,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a) return ("It ain't much but it's honest work!"):format(a.targetValue) end,
        progress = function(achievement, stats)
            local characterKey = PSC_GetCharacterKey()
            local characterData = PSC_DB.PlayerKillCounts.Characters[characterKey]
            return characterData.GrayKillsCount or 0
        end,
    },
    {
        id = "bonus_big_game_1",
        title = "High Level, High Cope",
        description = function(a) return ("Eliminate %d level ?? players"):format(a.targetValue) end,
        iconID = 135614,
        achievementPoints = 0,
        targetValue = 50,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("They thought your grey level meant free kill. Their damage numbers were bigger, their egos were even bigger. Too bad your killshot is the only number that mattered.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.levelData["??"] or 0
        end,
    },
    {
        id = "bonus_big_game_2",
        title = "Big Game Hunter",
        description = function(a) return ("Eliminate %d level ?? players"):format(a.targetValue) end,
        iconID = 135614,
        achievementPoints = 0,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("No mains to switch to. No excuses left. Just one sad loading screen and the crushing realization: this was their peak.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.levelData["??"] or 0
        end,
    },
    {
        id = "zone_horde_redridge",
        title = "Redridge Population Control",
        description = function(a) return ("Eliminate %d players in Redridge Mountains"):format(a.targetValue) end,
        iconID = 236814,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Congratulations. You made an entire zone regret installing the game.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Redridge Mountains"] or 0
        end,
    },
    {
        id = "zone_horde_elwynn",
        title = "Elwynn Exterminator",
        description = function(a) return ("Eliminate %d players in Elwynn Forest"):format(a.targetValue) end,
        iconID = 236761,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("After %d deaths in Elwynn, local humans are painting themselves green and practicing their 'zug zug'! Goldshire Inn's new special: 'Reroll Horde, Get Free Hearthstone to Durotar.' Even Marshal Dughan is considering a career in Orgrimmar.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Elwynn Forest"] or 0
        end,
    },
    {
        id = "zone_horde_westfall",
        title = "[YOUR NAME] x Defias Traitor",
        description = function(a) return ("Eliminate %d players in Westfall"):format(a.targetValue) end,
        iconID = 236852,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("[YOUR NAME] x Defias Traitor vs. Westfall - the crossover nobody wanted, but %d players paid the price anyway, making Westfall unplayable.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local westfallKills = stats.zoneData["Westfall"]
            if westfallKills == nil then
                return 0
            end
            return westfallKills
        end,
    },
    {
        id = "zone_horde_duskwood",
        title = "Darkshire Destroyer",
        description = function(a) return ("Eliminate %d players in Duskwood"):format(a.targetValue) end,
        iconID = 236757,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The Night Watch counted %d fresh corpses and decided to rename Darkshire to 'Deadshire'! Mor'Ladim is feeling professionally threatened, and Stiches filed for unemployment.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Duskwood"] or 0
        end,
    },
    {
        id = "zone_alliance_durotar",
        title = "Durotar Dominator",
        description = function(a) return ("Eliminate %d players in Durotar"):format(a.targetValue) end,
        iconID = 236756,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You turned Durotar into a no-fly zone for Alliance. Razor Hill guards are asking for YOUR autograph. %d kills and counting!")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Durotar"] or 0
        end,
    },
    {
        id = "zone_alliance_barrens",
        title = "Barrens Butcher",
        description = function(a) return ("Eliminate %d players in The Barrens"):format(a.targetValue) end,
        iconID = 236717,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in The Barrens! You made Barrens chat go silent. Even Mankrik’s wife is impressed.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["The Barrens"] or 0
        end,
    },
    {
        id = "zone_alliance_tirisfal",
        title = "Tirisfal Terror",
        description = function(a) return ("Eliminate %d players in Tirisfal Glades"):format(a.targetValue) end,
        iconID = 236849,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d bodies dropped in Tirisfal! Even the Forsaken are considering a second death.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Tirisfal Glades"] or 0
        end,
    },
    {
        id = "zone_alliance_stonetalon",
        title = "Stonetalon Slaughterer",
        description = function(a) return ("Eliminate %d players in Stonetalon Mountains"):format(a.targetValue) end,
        iconID = 236831,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d kills in Stonetalon! The only thing more toxic than the air here is your kill streak.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.zoneData["Stonetalon Mountains"] or 0
        end,
    },
    {
        id = "time_night_shift",
        title = "Night Shift Nightmare",
        description = function(a) return ("Eliminate %d players between 10 PM - 6 AM"):format(a.targetValue) end,
        iconID = 136057,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Ruined %d late-night gaming sessions! Parents worldwide grateful for your 'mandatory bedtime enforcement.' Energy drink sales in your region mysteriously plummeted.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByTimeRangeName("night_shift") -- 10 PM to 6 AM, optimized
        end,
    },
    {
        id = "time_lunch_hour",
        title = "Lunch Break Liquidator",
        description = function(a) return ("Eliminate %d players during lunch hour (12 PM - 2 PM, Mon-Fri)"):format(a.targetValue) end,
        iconID = 134062,
        achievementPoints = 75,
        targetValue = 300,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've ruined %d corporate lunch breaks. These players tried to squeeze in a quick gank between spreadsheets and got absolutely deleted. Their bosses are thrilled with the productivity spike, but the local deli is filing for bankruptcy. Hope the cold sandwich was worth the corpse run."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByCombination("lunch_weekdays") -- 12-2 PM on weekdays, optimized
        end,
    },
    {
        id = "time_after_work",
        title = "After Work Assassin",
        description = function(a) return ("Eliminate %d players during after work hours (5 PM - 9 PM, Mon-Fri)"):format(a.targetValue) end,
        iconID = 132303,
        achievementPoints = 125,
        targetValue = 750,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players tried to de-stress after a long day at the office and you sent them straight to bed angry. Their spouses thank you for the extra family time, but their therapists are booking extra sessions to deal with the sudden surge in rage-quitting-related trauma."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByCombination("afterwork_weekdays") -- 5-9 PM on weekdays, optimized
        end,
    },
    {
        id = "time_work_hours",
        title = "Work Hours Warrior",
        description = function(a) return ("Eliminate %d players during work hours (9 AM - 5 PM, Mon-Fri)"):format(a.targetValue) end,
        iconID = 136248,
        achievementPoints = 125,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've terminated %d employees who were definitely not working from home. Their bosses are sending you gift baskets for boosting company-wide productivity. You're not just a player; you're a corporate asset."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByCombination("workhours_weekdays") -- 9 AM-5 PM on weekdays, optimized
        end,
    },
    {
        id = "time_weekend_ganker",
        title = "Weekend Ganker",
        description = function(a) return ("Kill %d players during the weekend (Sat-Sun)"):format(a.targetValue) end,
        iconID = 132162,
        achievementPoints = 125,
        targetValue = 2500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d players had their weekend plans canceled permanently. You're the definition of a casual weekend warrior - can't play during the week because of 'responsibilities,' so you log in Saturday morning with your coffee, still figuring out your keybinds, and somehow manage to kill people through sheer luck and questionable decision-making. Your victims respect the dedication of someone who ganks between grocery runs and family dinners.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByWeekdayGroup("weekend") -- Saturday and Sunday, optimized
        end,
    },
    {
        id = "time_weekday_killer",
        title = "Weekday Killer",
        description = function(a) return ("Kill %d players during the week (Mon-Fri)"):format(a.targetValue) end,
        iconID = 132212, -- Achievement_Character_Human_Male
        achievementPoints = 125,
        targetValue = 2500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've caught and executed %d players who were clearly skipping out on their responsibilities. Their managers might not know where they are, but the Spirit Healer has them on speed dial. You're the ultimate truant officer."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByWeekdayGroup("weekdays") -- Monday-Friday, optimized
        end,
    },
    {
        id = "time_monday_mayhem",
        title = "Monday Mayhem",
        description = function(a) return ("Kill %d players on a Monday"):format(a.targetValue) end,
        iconID = 236577,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've given %d players a case of the Mondays they'll never recover from. They were already dreading the start of the week, and you just sent them straight to the spirit healer. Their boss is probably wondering why they're late for the raid."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.monday or 0 -- Monday, optimized
        end,
    },
    {
        id = "time_tuesday_terror",
        title = "Tuesday Terror",
        description = function(a) return ("Kill %d players on a Tuesday"):format(a.targetValue) end,
        iconID = 236578,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("For %d players, Tuesday was just another day. Then you showed up. Now it's the day they learned that the only thing worse than a Monday is a Tuesday spent being repeatedly sent to the graveyard by you."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.tuesday or 0 -- Tuesday, optimized
        end,
    },
    {
        id = "time_wednesday_woe",
        title = "Wednesday Woe",
        description = function(a) return ("Kill %d players on a Wednesday"):format(a.targetValue) end,
        iconID = 236579,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've turned Hump Day into 'Get Over This Corpse' Day for %d players. They were halfway through the week, dreaming of the weekend, and you just gave them a permanent vacation. To the spirit healer."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.wednesday or 0 -- Wednesday, optimized
        end,
    },
    {
        id = "time_thursday_thrashing",
        title = "Thursday Thrashing",
        description = function(a) return ("Kill %d players on a Thursday"):format(a.targetValue) end,
        iconID = 236580,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("It's Thirsty Thursday, and you've served up %d mugs of whoop-ass. These players were just trying to get a head start on the weekend, but you put them on a permanent timeout."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.thursday or 0 -- Thursday, optimized
        end,
    },
    {
        id = "time_friday_frenzy",
        title = "Friday Frenzy",
        description = function(a) return ("Kill %d players on a Friday"):format(a.targetValue) end,
        iconID = 236581,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("TGIF? More like 'Thank God It's Over' for the %d players you just slaughtered. Their weekend plans are cancelled. Permanently. You're the reason they'll be spending Saturday morning complaining on the forums."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.friday or 0 -- Friday, optimized
        end,
    },
    {
        id = "time_saturday_slaughter",
        title = "Saturday Slaughter",
        description = function(a) return ("Kill %d players on a Saturday"):format(a.targetValue) end,
        iconID = 236582,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The boys are NOT for the boys. You've ruined %d weekends. They were supposed to be raiding, questing, or just chilling. Instead, they got a front-row seat to their own demise. Repeatedly."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.saturday or 0 -- Saturday, optimized
        end,
    },
    {
        id = "time_sunday_suffering",
        title = "Sunday Suffering",
        description = function(a) return ("Kill %d players on a Sunday"):format(a.targetValue) end,
        iconID = 236583,
        achievementPoints = 100,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("A day of rest? Not on your watch. You've sent %d players to meet their maker... or at least the spirit healer. They'll be starting their week with repair bills and a deep-seated fear of you."):format(a.targetValue)
        end,
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.weekdays.sunday or 0 -- Sunday, optimized
        end,
    },
    {
        id = "time_christmas_eve",
        title = "Holiday Spirit...Crusher",
        description = "Kill 1 player on Christmas Eve (Dec 24th)",
        iconID = 132641,
        achievementPoints = 500,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Someone was trying to spread holiday cheer. You spread their entrails on the snow. Bah, humbug.",
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.specialDates["24_12"] or 0 -- Christmas Eve, optimized
        end,
    },
    {
        id = "time_christmas_day",
        title = "A Very Bloody Christmas",
        description = "Kill 1 player on Christmas Day (Dec 25th)",
        iconID = 133202,
        achievementPoints = 500,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
unlocked = false,
        completedDate = nil,
        subText = "You gave someone the gift of a corpse run. They'll remember this Christmas forever... with rage.",
        progress = function(achievement, stats)
            return PSC_CountKillsBySpecialDate("christmas") -- Christmas Day, optimized
        end,
    },
    {
        id = "time_new_years_eve",
        title = "Dropping The Ball",
        description = "Kill 1 player on New Year's Eve (Dec 31st)",
        iconID = 134273,
        achievementPoints = 500,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
unlocked = false,
        completedDate = nil,
        subText = "While everyone else was counting down, you were counting down some poor soul's health bar. Their new year's resolution is to avoid you.",
        progress = function(achievement, stats)
            return PSC_CountKillsBySpecialDate("new_years_eve") -- New Year's Eve, optimized
        end,
    },
    {
        id = "time_new_years_day",
        title = "Starting the Year with a Bang",
        description = "Kill 1 player on New Year's Day (Jan 1st)",
        iconID = 134270,
        achievementPoints = 500,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
unlocked = false,
        completedDate = nil,
        subText = "New year, new victim. You've already ruined someone's 1st of January. At this rate, you'll be the server's most feared player by February.",
        progress = function(achievement, stats)
            return PSC_CountKillsBySpecialDate("new_years_day") -- New Year's Day, optimized
        end,
    },
    {
        id = "time_friday_13th",
        title = "Friday the 13th Menace",
        description = "Kill 13 players on any Friday the 13th.",
        iconID = 132299,
        achievementPoints = 250,
        targetValue = 13,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You're the reason people are superstitious. You've made Friday the 13th a living nightmare for 13 unlucky souls. Jason Voorhees would be proud.",
        progress = function(achievement, stats)
            return PSC_CountKillsBySpecialCondition("friday13th") -- Friday 13th, optimized
        end,
    },
    {
        id = "time_april_fools",
        title = "April Fool's Punchline",
        description = "Kill a player on April 1st.",
        iconID = 236281,
        achievementPoints = 100,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "They thought that gank was a joke. It wasn't. You've delivered the punchline to one player's very short-lived comedy routine. April Fools!",
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.specialDates["1_4"] or 0 -- April 1st, optimized
        end,
    },
    {
        id = "time_monthly_january",
        title = "January Juggernaut",
        description = "Kill 100 players in January.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You started the year with a massacre. New Year's resolutions are for mortals.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("january") -- January, optimized
        end,
    },
    {
        id = "time_monthly_february",
        title = "February Frenzy",
        description = "Kill 100 players in February.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Love is in the air, and so are the corpses. You've been busy.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("february") -- February, optimized
        end,
    },
    {
        id = "time_monthly_march",
        title = "March Madness",
        description = "Kill 100 players in March.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The Ides of March were nothing compared to your killing spree.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("march") -- March, optimized
        end,
    },
    {
        id = "time_monthly_april",
        title = "April Annihilator",
        description = "Kill 100 players in April.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "April showers bring May flowers, but you just brought pain.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("april") -- April, optimized
        end,
    },
    {
        id = "time_monthly_may",
        title = "May Mayhem",
        description = "Kill 100 players in May.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You turned May into a month of mourning for 100 players.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("may") -- May, optimized
        end,
    },
    {
        id = "time_monthly_june",
        title = "June Juggernaut",
        description = "Kill 100 players in June.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "School's out, and you've been schooling the competition.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("june") -- June, optimized
        end,
    },
    {
        id = "time_monthly_july",
        title = "July Jubilee",
        description = "Kill 100 players in July.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You celebrated summer with a hundred funerals.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("july") -- July, optimized
        end,
    },
    {
        id = "time_monthly_august",
        title = "August Assault",
        description = "Kill 100 players in August.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "The dog days of summer were deadly for your opponents.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("august") -- August, optimized
        end,
    },
    {
        id = "time_monthly_september",
        title = "September Slaughter",
        description = "Kill 100 players in September.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Back to school, back to the graveyard.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("september") -- September, optimized
        end,
    },
    {
        id = "time_monthly_october",
        title = "October Overlord",
        description = "Kill 100 players in October.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "Trick or treat? They got tricked, you got a treat.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("october") -- October, optimized
        end,
    },
    {
        id = "time_monthly_november",
        title = "November Nightmare",
        description = "Kill 100 players in November.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You're the reason they're thankful for spirit healers.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("november") -- November, optimized
        end,
    },
    {
        id = "time_monthly_december",
        title = "December Destroyer",
        description = "Kill 100 players in December.",
        iconID = 132857,
        achievementPoints = 50,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You put 100 names on the naughty list, permanently.",
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("december") -- December, optimized
        end,
    },
    {
        id = "name_letter_a",
        title = "A-Team Annihilator",
        description = function(a) return ("Eliminate %d players whose names start with 'A'"):format(a.targetValue) end,
        iconID = 134939,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've alphabetized %d players starting with 'A' into the graveyard! From Aaron to Ass... these A-listers are now A-corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("A")
        end,
    },
    {
        id = "name_letter_b",
        title = "B-List Butcher",
        description = function(a) return ("Eliminate %d players whose names start with 'B'"):format(a.targetValue) end,
        iconID = 134939,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've brutalized %d B-named players! From Bob to Broly, they all got the same treatment: a brutal beatdown.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("B")
        end,
    },
    {
        id = "name_letter_c",
        title = "C-Grade Crusher",
        description = function(a) return ("Eliminate %d players whose names start with 'C'"):format(a.targetValue) end,
        iconID = 134939,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've crushed %d C-named champions! From Cedric to Cheesewheels, they all learned that C stands for 'Corpse'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("C")
        end,
    },
    {
        id = "name_letter_d",
        title = "Dust to Dust",
        description = function(a) return ("Eliminate %d players whose names start with 'D'"):format(a.targetValue) end,
        iconID = 134939,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've delivered devastation to %d D-named players! From Dave to Dragonslayer, they all got the same D: Death.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("D")
        end,
    },
    {
        id = "name_letter_e",
        title = "E-List Eliminator",
        description = function(a) return ("Eliminate %d players whose names start with 'E'"):format(a.targetValue) end,
        iconID = 134942,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've exterminated %d E-named enemies! From Eric to Ethereal, they all got an E for 'Eliminated'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("E")
        end,
    },
    {
        id = "name_letter_f",
        title = "F-Tier Finisher",
        description = function(a) return ("Eliminate %d players whose names start with 'F'"):format(a.targetValue) end,
        iconID = 134942,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've finished %d F-named fools! From Felix to Faggiodriver, they all got an F in staying alive.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("F")
        end,
    },
    {
        id = "name_letter_g",
        title = "G-Force Graveyard",
        description = function(a) return ("Eliminate %d players whose names start with 'G'"):format(a.targetValue) end,
        iconID = 134942,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've graveyarded %d G-named gamers! From Gary to Godslayer, they all got G'd up... in the graveyard.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("G")
        end,
    },
    {
        id = "name_letter_h",
        title = "H-Bomb Handler",
        description = function(a) return ("Eliminate %d players whose names start with 'H'"):format(a.targetValue) end,
        iconID = 134942,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've handled %d H-named heroes! From Howaito to Hkfarmer, they all got H-bombed into oblivion.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("H")
        end,
    },
    {
        id = "name_letter_i",
        title = "I-Con Iceman",
        description = function(a) return ("Eliminate %d players whose names start with 'I'"):format(a.targetValue) end,
        iconID = 134940,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've iced %d I-named individuals! From Ian to Icecrown, they all learned that I stands for 'Instant death'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("I")
        end,
    },
    {
        id = "name_letter_j",
        title = "J-Walking Judge",
        description = function(a) return ("Eliminate %d players whose names start with 'J'"):format(a.targetValue) end,
        iconID = 134940,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've judged %d J-named jockeys! From Jan to Jokester, they all got J-walked straight to the afterlife.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("J")
        end,
    },
    {
        id = "name_letter_k",
        title = "K-Pop Killer",
        description = function(a) return ("Eliminate %d players whose names start with 'K'"):format(a.targetValue) end,
        iconID = 134940,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've killed %d K-named keyboard warriors! From Kenny to Kingslayer, they all got K.O.'d permanently.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("K")
        end,
    },
    {
        id = "name_letter_l",
        title = "L-Train Liquidator",
        description = function(a) return ("Eliminate %d players whose names start with 'L'"):format(a.targetValue) end,
        iconID = 134940,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've liquidated %d L-named losers! From Larry to Lordmaster, they all took the L train to the graveyard.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("L")
        end,
    },
    {
        id = "name_letter_m",
        title = "M-Class Murderer",
        description = function(a) return ("Eliminate %d players whose names start with 'M'"):format(a.targetValue) end,
        iconID = 237448,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've murdered %d M-named maniacs! From Mike to Mobman, they all got M for 'Murdered'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("M")
        end,
    },
    {
        id = "name_letter_n",
        title = "N-Word Neutralizer",
        description = function(a) return ("Eliminate %d players whose names start with 'N'"):format(a.targetValue) end,
        iconID = 237448,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've neutralized %d N-named noobs! From Nick to Nightbringer, they all got the big N: 'No more life'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("N")
        end,
    },
    {
        id = "name_letter_o",
        title = "O-Zone Obliterator",
        description = function(a) return ("Eliminate %d players whose names start with 'O'"):format(a.targetValue) end,
        iconID = 237448,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've obliterated %d O-named opponents! From Oscar to Oathbreaker, they all got O for 'Over and out'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("O")
        end,
    },
    {
        id = "name_letter_p",
        title = "P-Rated Pulverizer",
        description = function(a) return ("Eliminate %d players whose names start with 'P'"):format(a.targetValue) end,
        iconID = 237448,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've pulverized %d P-named players! From Paul to Phohp, they all got P'd on... permanently.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("P")
        end,
    },
    {
        id = "name_letter_q",
        title = "Q-Anon Queller",
        description = function(a) return ("Eliminate %d players whose names start with 'Q'"):format(a.targetValue) end,
        iconID = 134943,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've quelled %d Q-named questers! From Quinn to Questbreaker, they all got Q'd into the afterlife.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("Q")
        end,
    },
    {
        id = "name_letter_r",
        title = "R-Rated Reaper",
        description = function(a) return ("Eliminate %d players whose names start with 'R'"):format(a.targetValue) end,
        iconID = 134943,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've reaped %d R-named raiders! From Rick to Raidkiller, they all got R.I.P.'d by your blade.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("R")
        end,
    },
    {
        id = "name_letter_s",
        title = "S-Tier Slaughterer",
        description = function(a) return ("Eliminate %d players whose names start with 'S'"):format(a.targetValue) end,
        iconID = 134943,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've slaughtered %d S-named scrubs! From Simon to Severussnipe, they all got S for 'Slain'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("S")
        end,
    },
    {
        id = "name_letter_t",
        title = "T-Pose Terminator",
        description = function(a) return ("Eliminate %d players whose names start with 'T'"):format(a.targetValue) end,
        iconID = 134943,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've terminated %d T-named targets! From Tametimo to Titanslayer, they all got T-bagged by death itself.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("T")
        end,
    },
    {
        id = "name_letter_u",
        title = "U-Turn Undertaker",
        description = function(a) return ("Eliminate %d players whose names start with 'U'"):format(a.targetValue) end,
        iconID = 134937,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've undertaken %d U-named users! From Ulrich to Uselessidiot, they all took a U-turn straight to the grave.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("U")
        end,
    },
    {
        id = "name_letter_v",
        title = "V-Day Vanquisher",
        description = function(a) return ("Eliminate %d players whose names start with 'V'"):format(a.targetValue) end,
        iconID = 134937,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've vanquished %d V-named villains! From Victoria to Voidbringer, they all got V for 'Vanquished'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("V")
        end,
    },
    {
        id = "name_letter_w",
        title = "W-Key Warrior",
        description = function(a) return ("Eliminate %d players whose names start with 'W'"):format(a.targetValue) end,
        iconID = 134937,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've wasted %d W-named warriors! From Will to Worldbreaker, they all got W for 'Wrecked'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("W")
        end,
    },
    {
        id = "name_letter_x",
        title = "X-Factor Executioner",
        description = function(a) return ("Eliminate %d players whose names start with 'X'"):format(a.targetValue) end,
        iconID = 134937,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've X'd out %d X-named xenophobes! From Xavier to Xanathos, they all got marked with an X for 'eXterminated'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("X")
        end,
    },
    {
        id = "name_letter_y",
        title = "Y-Generation Yielder",
        description = function(a) return ("Eliminate %d players whose names start with 'Y'"):format(a.targetValue) end,
        iconID = 134938,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've yielded %d Y-named youngsters! From Yuri to Yggdrasil, they all got Y for 'Yesterday's news'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("Y")
        end,
    },
    {
        id = "name_letter_z",
        title = "Z-List Zombie",
        description = function(a) return ("Eliminate %d players whose names start with 'Z'"):format(a.targetValue) end,
        iconID = 134938,
        achievementPoints = 25,
        targetValue = 150,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've zombified %d Z-named zealots! From Zack to Zzzzrakthul, they all got Z for 'Zzzzz... permanently'.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameStartingWith("Z")
        end,
    },
    {
        id = "name_length_3",
        title = "Tri-Letter Terminator",
        description = function(a) return ("Eliminate %d players with exactly 3-letter names"):format(a.targetValue) end,
        iconID = 134938,
        achievementPoints = 15,
        targetValue = 10,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've terminated %d players with 3-letter names! Bob, Jim, Sue - all gone. Short names, shorter lives. These minimalists took their name philosophy too far and ended up with the shortest lifespan possible.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameLength(3)
        end,
    },
    {
        id = "name_length_12",
        title = "Dozen-Letter Destroyer",
        description = function(a) return ("Eliminate %d players with exactly 12-letter names"):format(a.targetValue) end,
        iconID = 134938,
        achievementPoints = 75,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've destroyed %d players with 12-letter names! These verbose victims thought longer names meant longer lives. Shadowknight, Dragonslayer, Deathbringer - all equally dead. Turns out, character count doesn't count when you're counting corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsWithNameLength(12)
        end,
    },
    {
        id = "time_early_bird",
        title = "Early Bird Hunter",
        description = function(a) return ("Kill %d players between 5 AM - 8 AM"):format(a.targetValue) end,
        iconID = 136245,
        achievementPoints = 100,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Sometimes the early bird does not get the worm! You've caught %d early risers who thought they'd get some peaceful morning gaming. They were up with the sunrise, coffee in hand, ready to start their day with some light PvP. Instead, they got a wake-up call they'll never recover from. Their morning routine now includes a mandatory graveyard sprint.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByTimeRangeName("early_bird")
        end,
    },
    {
        id = "time_month_january",
        title = "January Jester",
        description = function(a) return ("Kill %d players during January"):format(a.targetValue) end,
        iconID = 236372,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've turned %d New Year's resolutions into permanent resting positions! These players resolved to 'get better at PvP' and 'play more WoW.' Mission accomplished... from the wrong perspective.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("january")
        end,
    },
    {
        id = "time_month_february",
        title = "February Fiend",
        description = function(a) return ("Kill %d players during February"):format(a.targetValue) end,
        iconID = 236373,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've sent %d players straight to the graveyard this February! While others were celebrating love, you were spreading death. Cupid's got nothing on your kill count. These players thought February was about hearts and flowers - you showed them it's about corpses and tombstones.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("february")
        end,
    },
    {
        id = "time_month_march",
        title = "March Madness",
        description = function(a) return ("Kill %d players during March"):format(a.targetValue) end,
        iconID = 236374,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("March Madness? More like March Massacre! You've eliminated %d players who came in like lions and went out like... well, corpses. Spring forward? These players sprung backwards to the spirit healer. The only bracket that matters is your kill bracket.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("march")
        end,
    },
    {
        id = "time_month_april",
        title = "April Annihilator",
        description = function(a) return ("Kill %d players during April"):format(a.targetValue) end,
        iconID = 236375,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("April showers bring May flowers, but your April brought %d corpses! These players thought spring meant renewal and growth. You taught them it means respawn timers and graveyard runs. The only thing blooming this April was your kill count.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("april")
        end,
    },
    {
        id = "time_month_may",
        title = "May Mayhem",
        description = function(a) return ("Kill %d players during May"):format(a.targetValue) end,
        iconID = 236376,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("May the Fourth be with you? More like 'May the corpse be with the spirit healer!' You've terminated %d players this May. While others celebrated spring festivals, you created a festival of death. These players brought flowers for Mother's Day - you sent them to meet their maker.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("may")
        end,
    },
    {
        id = "time_month_june",
        title = "June Juggernaut",
        description = function(a) return ("Kill %d players during June"):format(a.targetValue) end,
        iconID = 236377,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("June bugs got nothing on your June kills! You've squashed %d players this month. Summer vacation started early for these players - permanent vacation at the graveyard. They wanted to enjoy the longest days of the year, but you gave them the shortest lives instead.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("june")
        end,
    },
    {
        id = "time_month_july",
        title = "July Jackhammer",
        description = function(a) return ("Kill %d players during July"):format(a.targetValue) end,
        iconID = 236378,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Fourth of July fireworks? You provided the real fireworks with %d explosive kills! These players wanted to celebrate independence - you gave them independence from the mortal coil. The only red, white, and blue they saw was the colors of their death screen.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("july")
        end,
    },
    {
        id = "time_month_august",
        title = "August Assassin",
        description = function(a) return ("Kill %d players during August"):format(a.targetValue) end,
        iconID = 236379,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Dog days of summer? More like 'Dead days of summer!' You've put %d players to eternal rest this August. They wanted to enjoy their last weeks of summer vacation - you gave them their last weeks of being alive. The heat wasn't the only thing that was deadly this month.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("august")
        end,
    },
    {
        id = "time_month_september",
        title = "September Slayer",
        description = function(a) return ("Kill %d players during September"):format(a.targetValue) end,
        iconID = 236380,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Back to school? More like back to the graveyard! You've educated %d players in the art of dying this September. They thought they were learning new skills and meeting new people. Turns out, the only skill they learned was how to quickly release their spirits.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("september")
        end,
    },
    {
        id = "time_month_october",
        title = "October Obliterator",
        description = function(a) return ("Kill %d players during October"):format(a.targetValue) end,
        iconID = 236381,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Halloween came early with %d spooky kills! These players dressed up for October 31st, but you made sure they looked like corpses all month long. The only trick-or-treating they did was treating the spirit healer to repeat business. You turned October into 'Scare-tober.'")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("october")
        end,
    },
    {
        id = "time_month_november",
        title = "November Nightmare",
        description = function(a) return ("Kill %d players during November"):format(a.targetValue) end,
        iconID = 236382,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Thanksgiving feast? You provided the main course with %d fresh kills! These players were thankful for many things - until they met you. Now the only thing they're thankful for is the spirit healer's quick service. You carved them up better than any turkey.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("november")
        end,
    },
    {
        id = "time_month_december",
        title = "December Destroyer",
        description = function(a) return ("Kill %d players during December"):format(a.targetValue) end,
        iconID = 236383,
        achievementPoints = 75,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("'Tis the season to be deadly! You've gifted %d players a one-way ticket to the afterlife this December. They hung their stockings by the chimney with care, but you hung their corpses everywhere. Santa's naughty list has nothing on your kill list. The only white Christmas they got was the color of the graveyard snow.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("december")
        end,
    },
    {
        id = "time_january_massacre",
        title = "New Year's Carnage",
        description = function(a) return ("Kill %d players during January"):format(a.targetValue) end,
        iconID = 135614,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You started the year with %d kills! While everyone else was making resolutions to be better people, you resolved to be a better killer. Mission accomplished. The champagne wasn't the only thing popping - so were their heads.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("january")
        end,
    },
    {
        id = "time_february_bloodbath",
        title = "Valentine's Day Massacre",
        description = function(a) return ("Kill %d players during February"):format(a.targetValue) end,
        iconID = 135453,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Love was definitely NOT in the air - just the smell of %d corpses! You've redefined 'Be My Valentine' to 'Be My Victim.' Cupid's arrows got nothing on your killing spree. Romance is dead, and so are they.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("february")
        end,
    },
    {
        id = "time_march_slaughter",
        title = "Spring Break Breakdown",
        description = function(a) return ("Kill %d players during March"):format(a.targetValue) end,
        iconID = 135861,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Spring cleaning took on a whole new meaning with %d bodies to dispose of! These players thought March meant fresh starts and new beginnings. You gave them the freshest possible start - at the graveyard. The only thing sprouting this spring was your kill count.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("march")
        end,
    },
    {
        id = "time_april_carnage",
        title = "Easter Egg Hunt Champion",
        description = function(a) return ("Kill %d players during April"):format(a.targetValue) end,
        iconID = 135617,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You found %d Easter eggs - all shaped like corpses! While others hunted for chocolate, you hunted for kills. The Easter Bunny is filing a restraining order. These players thought April meant rebirth and renewal - you showed them it means death and funeral.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("april")
        end,
    },
    {
        id = "time_may_genocide",
        title = "Mother's Day Special",
        description = function(a) return ("Kill %d players during May"):format(a.targetValue) end,
        iconID = 135450,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You sent %d players home to their mommies... permanently! Mother's Day got really awkward when their kids had to explain why daddy won't be coming to dinner. Ever. You've created more orphans than a Disney movie.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("may")
        end,
    },
    {
        id = "time_june_extermination",
        title = "Summer Solstice Slayer",
        description = function(a) return ("Kill %d players during June"):format(a.targetValue) end,
        iconID = 135619,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The longest day of the year was also the last day for %d players! Summer vacation plans got permanently cancelled. They wanted to enjoy the sunshine - you gave them eternal darkness. The only thing hot this summer was your killing streak.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("june")
        end,
    },
    {
        id = "time_july_liberation",
        title = "Independence Day Liberator",
        description = function(a) return ("Kill %d players during July"):format(a.targetValue) end,
        iconID = 135620,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You liberated %d players from the burden of living! While others celebrated freedom with fireworks, you celebrated with firepower. The Declaration of Independence got nothing on your declaration of war. Red, white, and blue? More like red blood, white bones, and blue corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("july")
        end,
    },
    {
        id = "time_august_apocalypse",
        title = "Dog Days Executioner",
        description = function(a) return ("Kill %d players during August"):format(a.targetValue) end,
        iconID = 132190,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The dog days of summer turned into the 'dead days' of summer with %d kills! These players thought August heat was unbearable - you showed them what real heat feels like. The only thing lazier than summer afternoons were their corpses.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("august")
        end,
    },
    {
        id = "time_september_genocide",
        title = "Back-to-School Bully",
        description = function(a) return ("Kill %d players during September"):format(a.targetValue) end,
        iconID = 134330,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("School's in session and you taught %d players the final lesson! They came back from summer vacation relaxed and refreshed - you sent them back to the graveyard stressed and dead. The only homework they're doing now is decomposition.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("september")
        end,
    },
    {
        id = "time_october_butchery",
        title = "Trick-or-Treat Tyrant",
        description = function(a) return ("Kill %d players during October"):format(a.targetValue) end,
        iconID = 133982,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Trick or treat? They got the ultimate trick - %d permanent treats for the graveyard! You turned Halloween into 'Hell-o-ween.' Their costumes were scary, but not as scary as your kill count. The real horror show was your PvP performance.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("october")
        end,
    },
    {
        id = "time_november_bloodlust",
        title = "Turkey Day Terminator",
        description = function(a) return ("Kill %d players during November"):format(a.targetValue) end,
        iconID = 250626,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You carved up %d players better than any Thanksgiving turkey! They were thankful for family, friends, and good health - until you showed up. Now their families are thankful for life insurance policies. The only stuffing happening was corpses into graveyards.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("november")
        end,
    },
    {
        id = "time_december_armageddon",
        title = "Christmas Carol Killer",
        description = function(a) return ("Kill %d players during December"):format(a.targetValue) end,
        iconID = 134140,
        achievementPoints = 250,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Silent night, deadly night! You've composed a Christmas carol with %d death screams. They dreamed of a white Christmas - you gave them red snow. Santa's workshop has nothing on your kill factory. The only thing jingling was the sound of their gear dropping.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return PSC_CountKillsByMonthName("december")
        end,
    },
    {
        id = "time_wow_anniversary",
        title = "World of Warcraft Anniversary",
        description = "Kill 1 player on November 23rd (WoW Vanilla Release Date)",
        iconID = 135724,
        achievementPoints = 500,
        targetValue = 1,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = "You celebrated the birth of World of Warcraft by sending someone back to the character creation screen! November 23rd, 2004 - the day millions of lives changed forever. Today, you made sure one player's life ended forever. Happy Anniversary!",
        progress = function(achievement, stats)
            local timeStats = PSC_GetTimeBasedStats()
            return timeStats.specialDates["23_11"] or 0 -- November 23rd, WoW release date
        end,
    },
}
