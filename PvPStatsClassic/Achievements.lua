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
        achievementPoints = 75,
        targetValue = 750,
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
        title = "Scripture Shreader",
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        achievementPoints = 75,
        targetValue = 750,
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
        id = "general_gender_female_1",
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
            return stats.genderData["FEMALE"] or 0
        end,
    },
    {
        id = "general_gender_female_2",
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
            return stats.genderData["FEMALE"] or 0
        end,
    },
    {
        id = "general_gender_female_3",
        title = "She/Her/Dead",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 135906,
        achievementPoints = 50,
        targetValue = 750,
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
            return stats.genderData["FEMALE"] or 0
        end,
    },
    {
        id = "general_gender_female_4",
        title = "Wife Beater",
        description = function(a) return ("Defeat %d female characters"):format(a.targetValue) end,
        iconID = 135908,
        achievementPoints = 75,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d female avatars deleted—and not a single real woman in the bunch. You've dismantled more online personas than a Tinder exposé thread. Next stop: catching streamers playing with voice changers.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["FEMALE"] or 0
        end,
    },

    {
        id = "general_gender_male_1",
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
            return stats.genderData["MALE"] or 0
        end,
    },
    {
        id = "general_gender_male_2",
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
            return stats.genderData["MALE"] or 0
        end,
    },
    {
        id = "general_gender_male_3",
        title = "Masculinity Challenger",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 134166,
        achievementPoints = 50,
        targetValue = 750,
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
            return stats.genderData["MALE"] or 0
        end,
    },
    {
        id = "general_gender_male_4",
        title = "Professional Man-Slayer",
        description = function(a) return ("Defeat %d male characters"):format(a.targetValue) end,
        iconID = 134006,
        achievementPoints = 75,
        targetValue = 1000,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d male characters vanquished! The average lifespan of men in Azeroth has plummeted. Blizzard is considering a 'protective bubble' feature that activates whenever you enter the zone. Support groups have formed for your victims - they meet every Tuesday at the graveyard.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.genderData["MALE"] or 0
        end,
    },
    {
        id = "general_zone_redridge",
        title = "Redridge Renovation",
        description = function(a) return ("Eliminate %d players in Redridge Mountains"):format(a.targetValue) end,
        iconID = 236814,
        achievementPoints = 500,
        targetValue = 500,
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
        id = "general_zone_elwynn",
        title = "Elwynn Exterminator",
        description = function(a) return ("Eliminate %d players in Elwynn Forest"):format(a.targetValue) end,
        iconID = 236761,
        achievementPoints = 250,
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
        id = "general_zone_westfall",
        title = "[YOUR NAME] x Defias Traitor",
        description = function(a) return ("Eliminate %d players in Westfall"):format(a.targetValue) end,
        iconID = 236852,
        achievementPoints = 250,
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
        id = "general_zone_duskwood",
        title = "Darkshire Destroyer",
        description = function(a) return ("Eliminate %d players in Duskwood"):format(a.targetValue) end,
        iconID = 236757,
        achievementPoints = 250,
        targetValue = 250,
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
        id = "kills_total_1",
        title = "Body Count Rising",
        description = function(a) return ("Slay %d players in total"):format(a.targetValue) end,
        iconID = 236399, -- spell_shadow_shadowfury
        achievementPoints = 50,
        targetValue = 500,
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
        description = function(a) return ("Slay %d players in total"):format(a.targetValue) end,
        iconID = 237542,
        achievementPoints = 100,
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
        description = function(a) return ("Slay %d players in total"):format(a.targetValue) end,
        iconID = 132205,
        achievementPoints = 500,
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
        id = "kills_unique_1",
        title = "Variety Slayer",
        description = function(a) return ("Defeat %d unique players"):format(a.targetValue) end,
        iconID = 133789,
        achievementPoints = 50,
        targetValue = 500,
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
        description = function(a) return ("Defeat %d unique players"):format(a.targetValue) end,
        iconID = 133787,
        achievementPoints = 100,
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
        description = function(a) return ("Defeat %d unique players"):format(a.targetValue) end,
        iconID = 133785,
        achievementPoints = 500,
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
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
        title = "Moonlight Massacre",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 236449,
        achievementPoints = 10,
        targetValue = 100,
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
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Night Elves eliminated! They thought they disappeared… but all you saw was a free honor kill waiting to happen.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },
    {
        id = "race_nightelf_2",
        title = "One with Nature, Now One with the Dirt",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 236450,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Night Elf hippies permanently recycled back to nature! These Whole Foods shopping, kombucha brewing, crystal-healing enthusiasts thought their organic armor and free-range weapons would save them. They were too busy forming drum circles and protesting Goblin deforestation to notice your approach. Their last words were 'Namaste... in the graveyard.' Turns out their carbon footprint is now zero - just like their kill/death ratio.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Night Elf"] or 0
        end,
    },
    {
        id = "race_nightelf_3",
        title = "Eternal No More",
        description = function(a) return ("Eliminate %d Night Elves"):format(a.targetValue) end,
        iconID = 134161,
        achievementPoints = 75,
        targetValue = 750,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Night Elves in the dirt! All that jumping around didn't save them from [YOUR NAME]. Each one was still typing 'shadows meld me!' when you ended them. Most died while taking screenshots of sunsets or AFKing in character-select poses. Their precious 'front flip' jumping animation is much less impressive from a corpse.")
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("The graveyard is using %d gnome corpses as speed bumps! Their families are demanding refunds on those expensive Engineering degrees.")
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
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
        achievementPoints = 75,
        targetValue = 750,
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
        targetValue = 100,
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
        targetValue = 250,
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
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d Tauren players got exactly what they deserved for picking the 'gentle giant' stereotype! Their 5% bonus health just meant they died 3 seconds slower while panic-pressing War Stomp. The real stampede was them rushing to the forums to complain about 'unfair pvp balance.'")
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
        achievementPoints = 75,
        targetValue = 750,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've slaughtered %d Tauren! Thunder Bluff elevator accidents are now the SECOND leading cause of Tauren death. These gentle giants had 5% more health than other races, which gave them exactly 3 extra seconds to contemplate their life choices before you ended them. Mulgore's milk industry has collapsed, and the Grimtotem are sending you fan mail. The Earth Mother has filed a restraining order against you.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.raceData["Tauren"] or 0
        end,
    },
    {
        id = "kills_guild",
        title = "Guild Drama Generator",
        description = function(a) return ("Eliminate %d guild members"):format(a.targetValue) end,
        iconID = 134473,
        achievementPoints = 50,
        targetValue = 500,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d so-called 'guildmates' slaughtered! Turns out, that guild tag above their heads didn’t make them any less squishy. Maybe they should try a PvE guild—less world PvP, more coping in raid chat.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.guildStatusData["In Guild"] or 0
        end,
    },
    {
        id = "kills_guildless",
        title = "Lone Wolf Hunter",
        description = function(a) return ("Eliminate %d guildless players"):format(a.targetValue) end,
        iconID = 132203,
        achievementPoints = 50,
        targetValue = 500,
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
        id = "kills_grey_level",
        title = "Teach them young",
        description = function(a) return ("Eliminate %d grey-level players"):format(a.targetValue) end,
        iconID = 134435,
        achievementPoints = 250,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a) return ("It ain't much but it's honest work!"):format(a.targetValue) end,
        progress = function(achievement, stats)
            return PSC_CalculateGreyKills() or 0
        end,
    }, -- Kill Streak Achievements
    {
        id = "kills_streak_25",
        title = "Serial Killer",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 133728,
        achievementPoints = 25,
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
        achievementPoints = 50,
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
        achievementPoints = 100,
        targetValue = 100,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("You've killed more players than some indie games have sales. Enemy raid leaders reference you like you're Voldemort — 'He-Who-Wipes-Raid-Groups.'' Even your local WiFi provider flagged you as a DDoS threat.")
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
        achievementPoints = 125,
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
        achievementPoints = 250,
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
        achievementPoints = 500,
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
        title = "Flex contests",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 136101,
        achievementPoints = 500,
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
        achievementPoints = 500,
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
        id = "kills_streak_225",
        title = "/flex",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236370,
        achievementPoints = 500,
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
        id = "kills_streak_225",
        title = "/flex",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236370,
        achievementPoints = 500,
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
        title = "Certified Problem",
        description = function(a) return ("Achieve a %d-player kill streak"):format(a.targetValue) end,
        iconID = 236370,
        achievementPoints = 500,
        targetValue = 250,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("Half the server called for help. The other half ragequit.")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.highestKillStreak or 0
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
        achievementPoints = 75,
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
        id = "kills_favorite_target",
        title = "Personal Vendetta",
        description = function(a) return ("Kill the same player %d times"):format(a.targetValue) end,
        iconID = 136168,
        achievementPoints = 25,
        targetValue = 10,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            local stats = PSC_CalculateSummaryStatistics()
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
        id = "kills_big_game",
        title = "Big Game Hunter",
        description = function(a) return ("Eliminate %d level ?? players"):format(a.targetValue) end,
        iconID = 135614,
        achievementPoints = 250,
        targetValue = 50,
        condition = function(achievement, stats)
            return achievement.progress(achievement, stats) >= achievement.targetValue
        end,
        unlocked = false,
        completedDate = nil,
        subText = function(a)
            return ("%d level ?? enemies deleted! While lesser mortals flee at the sight of a ?? mark, you hunt them for sport. These walking raid bosses thought their level advantage made them untouchable and overconfident — until they met [YOUR NAME].")
                :format(a.targetValue)
        end,
        progress = function(achievement, stats)
            return stats.levelData["??"] or 0
        end,
    },
}

function PSC_ReplacePlayerNamePlaceholder(text, playerName, achievement)
    if not text then return "" end

    if type(text) == "function" then
        text = text(achievement)
    end

    local name = playerName or UnitName("player")
    text = text:gsub("%[YOUR NAME%]", name)
    return text
end


function PSC_GetAllStatsForAchievements()
    local classData, raceData, genderData, unknownLevelClassData, zoneData, levelData, guildStatusData =
        PSC_CalculateBarChartStatistics()
    local summaryStats = PSC_CalculateSummaryStatistics()
    local stats = {
        classData = classData,
        raceData = raceData,
        genderData = genderData,
        unknownLevelClassData = unknownLevelClassData,
        zoneData = zoneData,
        levelData = levelData,
        guildStatusData = guildStatusData,
        totalKills = summaryStats.totalKills,
        uniqueKills = summaryStats.uniqueKills,
        highestKillStreak = summaryStats.highestKillStreak,
        highestMultiKill = summaryStats.highestMultiKill,
        mostKilledPlayer = summaryStats.mostKilledPlayer,
        mostKilledCount = summaryStats.mostKilledCount
    }

    return stats
end


function AchievementSystem:CheckAchievements()
    local playerName = UnitName("player")
    local achievementsUnlocked = 0
    local stats = PSC_GetAllStatsForAchievements()

    for _, achievement in ipairs(self.achievements) do
        if not achievement.unlocked and achievement.condition(achievement, stats) then
            achievement.unlocked = true
            achievement.completedDate = date("%d/%m/%Y %H:%M")

            PSC_SaveAchievement(achievement.id, achievement.completedDate, achievement.achievementPoints)

            local personalizedDescription = PSC_ReplacePlayerNamePlaceholder(achievement.description, playerName,
                achievement)
            local personalizedTitle = PSC_ReplacePlayerNamePlaceholder(achievement.title, playerName, achievement)
            local personalizedSubText = PSC_ReplacePlayerNamePlaceholder(achievement.subText, playerName, achievement)

            PVPSC.AchievementPopup:ShowPopup({
                icon = achievement.iconID,
                title = personalizedTitle,
                description = personalizedDescription,
                subText = personalizedSubText,
                rarity = achievement.rarity
            })

            achievementsUnlocked = achievementsUnlocked + 1
        end
    end

    self:SaveAchievementPoints()

    return achievementsUnlocked
end

local function GetRarityFromPoints(points)
    if points >= 250 then
        return "legendary"
    elseif points >= 75 then
        return "epic"
    elseif points >= 50 then
        return "rare"
    elseif points >= 25 then
        return "uncommon"
    else
        return "common"
    end
end

for _, achievement in ipairs(AchievementSystem.achievements) do
    if not achievement.rarity then
        achievement.rarity = GetRarityFromPoints(achievement.achievementPoints)
    end
end

function AchievementSystem:SaveAchievementPoints()
    local totalPoints = 0

    if not PSC_DB.Achievements then
        PSC_DB.Achievements = {}
    end

    for _, achievement in ipairs(self.achievements) do
        local achievementID = achievement.id

        if PSC_DB.Achievements[achievementID] and PSC_DB.Achievements[achievementID].unlocked then
            totalPoints = totalPoints + achievement.achievementPoints
            PSC_DB.Achievements[achievementID].points = achievement.achievementPoints
        end
    end

    PSC_DB.TotalAchievementPoints = totalPoints

    return totalPoints
end

function AchievementSystem:Initialize()
    if PSC_DB.Achievements then
        for achievementID, achievementData in pairs(PSC_DB.Achievements) do
            for i, achievement in ipairs(self.achievements) do
                if achievement.id == achievementID and achievementData.unlocked then
                    self.achievements[i].unlocked = true
                    self.achievements[i].completedDate = achievementData.completedDate
                end
            end
        end
    end

    self:SaveAchievementPoints()
end

C_Timer.After(1, function()
    if PVPSC and PVPSC.AchievementSystem then
        PVPSC.AchievementSystem:Initialize()
    end
end)
