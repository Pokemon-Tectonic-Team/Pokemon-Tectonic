def battleGuideMainDirectory
    return {
        _INTL("Basic Strategy")    => [_INTL("How do I win battles?"),:battleGuideBasicsHash],
        _INTL("Acquiring Pokémon") => [_INTL("How do I get more Pokémon?"),:battleGuideAquiringPokemonHash],
        _INTL("Moves")             => [_INTL("What are moves and what are the differences between them?"),:battleGuideMovesHash],
        _INTL("Type Matchups")     => [_INTL("When and how are types better or worse against one another?"),:battleGuideTypeMatchupsHash],
        _INTL("Type Chart")        => [_INTL("How were type matchups changes compared to canon?"),:battleGuideTypeChartHash],
        _INTL("Stats")             => [_INTL("What are stats, and how do they affect battles?"),:battleGuideStatsHash],
        _INTL("Abilities")         => [_INTL("How do abilities work?"),:battleGuideAbilitiesHash],
        _INTL("Held Items")        => [_INTL("What are held items and how to use them?"),:battleGuideHeldItemsHash],
        _INTL("Status Conditions") => [_INTL("What are the Conditions a Pokémon can be afflicted with?"),:battleGuideStatusConditionsHash],
        _INTL("Volatile Statuses") => [_INTL("What are the Volatile Statuses a Pokémon can be afflicted with?"),:battleGuideVolatileStatusesHash],
        _INTL("Critical Hits")     => [_INTL("What are critical hits and when do they happen?"),:battleGuideCriticalHitsHash],
        _INTL("Trainers")          => [_INTL("How do enemy Trainers work?"),:battleGuideTrainersHash],
        _INTL("Avatars")           => [_INTL("What are avatars and what do they do?"),:battleGuideAvatarsHash],
        _INTL("MasterDex")         => [_INTL("What does the MasterDex do and how should I use it?"),:battleGuideMasterdexHash],
        _INTL("Weathers")          => [_INTL("What are weathers, and what does each do?"),:battleGuideWeathersHash],
        _INTL("Tribes")            => [_INTL("What are Tribes and what do they do?"),:battleGuideTribesHash],
}
end

def battleGuideMainHash
    mainHash = {}
    battleGuideMainDirectory.each do |key, value|
        mainHash[key] = value[0]
    end
    return mainHash
end

def battleGuideBasicsHash
    return {
        _INTL("Winning Battles") => _INTL("You win a battle when all enemy Pokémon faint: reach 0 health points. You lose a battle if that happens to your Pokémon."),
        _INTL("Basic Strategy") => _INTL("1. Have as many Pokémon as you can. 2. Level up your Pokémon as much as you can. 3. Abuse type matchups. 4. Start battles with healthy Pokémon."),
        _INTL("Team Size") => _INTL("You can have a maximum of 6 Pokémon with you at any time. This is known as your 'Team'. You can store extra Pokémon using the PC in any PokéCenter."),
        _INTL("Levels") => _INTL("Each Pokémon has a level from 1 to 70. A Pokémon's level determines its stats as well as what moves it could learn. Reaching high enough levels also unlocks Evolution."),
        _INTL("Type Matchups") => _INTL("Types are strong or weak against other types. Having a variety of different types on your team helps you take advantage of these relationships."),
        _INTL("Healing your Pokémon") => _INTL("Heal your Pokémon at PokéCenters between battles. You can often use the Aid Kit instead to save on traveling time."),
        _INTL("Who goes first?") => _INTL("In battle, the Pokémon with the higher speed stat gets to use their move first. Some moves modify this. Speed ties are decided randomly."),
    }
end

def battleGuideMovesHash
    return {
        _INTL("Attacking vs Status") => _INTL("Attacking moves deal damage. Status moves do not. Status moves are notated by a Yin/Yang symbol (White and Black intermixing)."),
        _INTL("Physical vs Special") => _INTL("Attacking moves are split into Physical moves, and Special moves. Each of these categories uses different stats to determine how much damage is dealt to the target."),
        _INTL("Physical Moves") => _INTL("Physical moves are notated by the symbol of a smashing fist. Their damage is based on the Attack (Atk) stat of the attacker and the Defense (Def) stat of the target."),
        _INTL("Special Moves") => _INTL("Special moves are notated by the symbol of a splash. Their damage is based on the Special Attack (Sp. Atk) of the attacker and the Special Defense (Sp. Def) of the target."),
        _INTL("Targeting") => _INTL("Most moves target only a single Pokémon, but many can target multiple Pokémon at once. Some moves differ in how far they can target in the bigger battle styles (doubles, triples)."),
        _INTL("Move Types") => _INTL("Every move has a type. Attacking moves deal different amounts of damage to different Pokémon based on those Pokémon's types. This is called 'type effectiveness'."),
        _INTL("Same-Type Bonus") => _INTL("Pokémon deal 50% more damage with moves the share a type with them. For example, a Raichu deals 50% more damage with an Electric move than a Normal move."),
        _INTL("Learning Moves") => _INTL("Pokémon learn new moves as they level up. They can also learn moves from the 'Move Tutors' who sit in the left side of every PokéCenter."),
        _INTL("Base Power") => _INTL("Moves with higher Base Power deal more damage. Some moves deal variable Base Power depending on the situation. Status moves have no base power."),
        _INTL("Accuracy") => _INTL("Accuracy is a move's chance of hitting. Most moves have 100% accuracy. Some effects can raise accuracy to let you use low-accuracy moves consistently."),
        _INTL("Power Points") => _INTL("Power Points, or PP, is a number which limits how many times a move can be used. Healing at a PokéCenter or with the Aid Kit restores PP."),
    }
end

def battleGuideTypeMatchupsHash
    return {
        _INTL("Type Matchups") => _INTL("Each Pokémon has type weakness and type resistances based on its own type. eg. Water deals double damage to Fire, and Fire deals half damage to Water."),
        _INTL("Type Combinations") => _INTL("When a Pokémon has two types, its type weaknesses and resistances multiply. A Pokémon can be double weak or double resistant, or immune even though one of their types is weak."),
        _INTL("Normal Effective") => _INTL("Normal Effective is the default effectiveness of all moves against a Pokémon."),
        _INTL("Super Effective") => _INTL("Super Effective moves deal double the damage compared to normal effective moves."),
        _INTL("Hyper Effective") => _INTL("Hyper Effective moves deal quadruple the damage compared to normal effective moves. This happens when a Pokémon is double weak to a type."),
        _INTL("Not Very Effective") => _INTL("Not Very Effective moves deal half the damage compared to normal effective moves."),
        _INTL("Barely Effective") => _INTL("Barely Effective moves deal one quarter the damage compared to normal effective moves. This happens when a Pokémon is double resistant to a type."),
        _INTL("Ineffective") => _INTL("Ineffective moves deal no damage at all. This can happen if one of a Pokémon's types has an immunity to the attacking move type, even if the other is neutral (or even weak!)."),
        _INTL("Looking Up Matchups") => _INTL("The 5th and 6th pages of a MasterDex entry show that Pokémon's type matchups. Open the MasterDex in battle to check matchups if you're not sure."),
    }
end

def battleGuideTypeChartHash
    return {
        _INTL("Psychic vs Steel") => _INTL("Psychic is now Super-Effective vs Steel. Think of magicians bending spoons."),
        _INTL("Poison vs Water") => _INTL("Poison is now Super-Effective vs Water. Think of chemicals polluting a river."),
        _INTL("Bug vs Fairy") => _INTL("Bug is now Super-Effective vs Fairy. Think of insects scaring children."),
        _INTL("Grass resistances") => _INTL("Grass now resists Fairy and Ghost. Think of incense warding off magic."),
        _INTL("Ice resistances") => _INTL("Ice now resists Flying and Ground. Ice is Super-Effective against those types, so it's only natural!"),
        _INTL("Other changes") => _INTL("Rock resists Ice. Fairy resists Dragon. Fairy is neutral against Fire. Bug resists Psychic."),
    }
end

def battleGuideAquiringPokemonHash
    return {
        _INTL("Why Get More?") => _INTL("Having choices of Pokémon is important when facing challenges. A team of six is a bare minimum--it's best to catch more and pull them from the PC as needed."),
        _INTL("Methods of Aquiring") => _INTL("The two main methods of acquiring Pokémon are catching them from the wild, and receiving them from other Trainers through gifts or trades."),
        _INTL("Catching Basics") => _INTL("Wild Pokémon will attack you if you walk through patches of grass, dark ground in caves, or other wild terrain. You can catch these Pokémon by throwing Poké Balls at them."),
        _INTL("Increase Catch Chance pt. 1") => _INTL("Catching a Pokémon isn't guaranteed. It's easier to catch Pokémon when their health has been lowered by your attacks, or when they have a status ailment."),
        _INTL("Increase Catch Chance pt. 2") => _INTL("Every time a Pokémon breaks out of a ball, it'll be slightly easier to catch for the rest of the battle. You can check what your current catch chance is in the Poké Ball menu."),
        _INTL("Finding Wild Pokémon") => _INTL("Use the DexNav to get information on which Pokémon are available where you are. You can also use it to find more Pokémon of a species that you've already caught one of."),
        _INTL("Trades") => _INTL("Throughout the world there will be people offering trades for Pokémon. Usually they want a different Pokémon, but sometimes they want money."),
    }
end

def battleGuideStatsHash
    return {
        _INTL("What are Stats?") => _INTL("Stats, short for Statistics, are the numbers which determine how your Pokémon performs in battle."),
        _INTL("Checking Stats") => _INTL("Check your Pokémon's stats by looking at the second page of their summary screen, accessible through the Pokémon menu in the pause menu."),
        _INTL("Stat Factors") => _INTL("Your Pokémon's stats are calculated from a combination of their species' 'Base Stats', their own 'Style Points', and extra modifications during battle."),
        _INTL("Base Stats") => _INTL("Every species of Pokémon have base stats, which affect every Pokémon of that species. e.g. Every Raichu will be fast because the Raichu species has a high Speed base stat."),
        _INTL("Style Points") => _INTL("Style Points are numbers which you can customize to change your Pokémon's stats. Style Points show as blue numbers on the stat page of the summary."),
        _INTL("Leveling and Evolution") => _INTL("Your Pokémon's stats will increase every time they level up. When Pokémon evolve, their stats change (almost always they increase)."),
        _INTL("Accuracy and Evasion") => _INTL("Accuracy and Evasion are two stats which are only active in battle, starting at 100% each. They are only modified by in-battle changing effects."),
        _INTL("Stat Steps") => _INTL("Effects can modify a Pokémon's stats during battle. These are called 'stat steps'. Stat steps multiply or divide the Pokémon's listed stat value."),
        _INTL("Bounds of Stat Steps") => _INTL("Stat steps start at 0, and can increase up to +12 (4x) and down to -12 (.25x). Stat steps are reset if you swap the Pokémon out or it faints."),
        _INTL("Checking Stat Steps") => _INTL("You can check the current stat steps of each Pokémon on the battlefield using the Info button. It lists the numerical step as well as resultant multiplier."),
    }
end

def battleGuideAbilitiesHash
    return {
        _INTL("What are abilities?") => _INTL("Abilities are special powers that Pokémon can have based on their species. Most Pokémon can have one of 2 possible abilities."),
        _INTL("Ability Effects") => _INTL("Abilities do a wide variety of different things. Understanding your team's abilities, and choosing the right ones, is important to winning."),
        _INTL("Checking Abilities") => _INTL("Check your Pokémon's summary to see what ability they have. Use the MasterDex to read about the abilities of enemy Pokémon during battle."),
        _INTL("Choosing Abilities") => _INTL("A Pokémon's ability is one of the two its species can have, randomly chosen when you get it. You can use Ability Capsules to swap to the other."),
        _INTL("Conditional Abilities") => _INTL("Many abilities only do things under certain circumstances. Building around Weather and Room-synergy abilities is a common strategy."),
        _INTL("Effect Of Evolution") => _INTL("A Pokémon's ability tends to stay the same when evolving, but can change. When this happens, the game will alert you."),
        _INTL("Defeating Abilities") => _INTL("An enemy Trainer's ability too much? Abilities like Neutralizing Gas, and moves like Gastro Acid, can suppress abilities in battle."),
        _INTL("Swapping Abilities") => _INTL("Moves like Skill Swap can be used to give a new ability to Pokémon during battle, enabling unique and creative team synergies."),
    }
end

def battleGuideHeldItemsHash
    return {
        _INTL("What are Held Items?") => _INTL("Held items are items which you can give your Pokémon to benefit them during battle. They can increase their damage, heal them, or other things."),
        _INTL("Equipping an item") => _INTL("You can give a Pokémon an item from your bag, or through the summary screen. Not all items do an effect when held, so read carefully."),
        _INTL("Berries") => _INTL("Berries are a common held item. During battles, Pokémon will eat the berry to get a benefit. Get berries by picking from Berry Trees."),
        _INTL("Sitrus and Cado Berry") => _INTL("Sitrus Berry and Cado Berry are common berries which heal your Pokémon when at low health. If in doubt about what item to give a Pokémon, give them one of these."),
        _INTL("Rematerializer") => _INTL("In Pokémon Tectonic, the Rematerializer regenerates held items which are consumed in battle. You'll never run out of berries!"),
        _INTL("Wild Held Items") => _INTL("Wild Pokémon can be found holding items. These items sometimes have held effects, but often don't."),
        _INTL("Getting More") => _INTL("You will find more held items on the ground when traveling, or as gifts from people, or as the reward for defeating Avatars, or as purchasable items in shops."),
    }
end

def battleGuideStatusConditionsHash
    return {
        _INTL("What are Status Conditions?") => _INTL("Status Conditions are ailments a Pokémon can have which hurt or restrict them. They remain after swapping out, and even between battles."),
        _INTL("Healing Status Conditions") => _INTL("Status Conditions are removed when you heal at the PokéCenter or when you use the Aid Kit."),
        _INTL("Status Immunity") => _INTL("Type immunities do not prevent status moves. However, some types give immunities to certain status conditions. Don't confuse these two!"),
        _INTL("Burn") => _INTL("When burned, a Pokémon's Attack is reduced by 33%, and loses 1/8th HP every turn. Fire- and Ghost-types do the most burning. Fire is immune."),
        _INTL("Frostbite") => _INTL("When frostbitten, a Pokémon's Sp. Atk is reduced by 33%, and loses 1/8th HP every turn. Ice- and Flying-types do the most frostbiting. Ice is immune."),
        _INTL("Poison") => _INTL("When poisoned, a Pokémon loses 1/12th HP every turn. This doubles every 2 turns. Poison- and Grass-types do the most poisoning. Poison/Steel are immune."),
        _INTL("Numb") => _INTL("When numbed, a Pokémon's Speed is halved, and it deals 25% less damage. Electric- and Fighting-types do the most numbing. Electric is immune."),
        _INTL("Waterlog") => _INTL("When waterlogged, a Pokémon's Speed is halved, and it takes 25% more attack damage. Water- and Dark-types do the most waterlogging. Water is immune."),
        _INTL("Dizzy") => _INTL("When dizzied, a Pokémon takes 25% more attack damage, and its ability doesn't function. Psychic- and Fairy-types do the most dizzying."),
        _INTL("Leeched") => _INTL("When leeched, a Pokémon loses 1/12th HP every turn, and its opponent(s) split that health. Bug- and Dark-types do the most leeching. Grass is immune."),
        _INTL("Sleep") => _INTL("A rarer status that causes a Pokémon to be unable to do anything for 2 turns. Psychic- and Grass-types put Pokémon to sleep the most often."),
    }
end

def battleGuideVolatileStatusesHash
    return {
        _INTL("What are Volatile Statuses?") => _INTL("Volatile Status Conditions are similar to Status Conditions, except they will go away if the Pokémon switches out."),
        _INTL("Jinx") => _INTL("When jinxed, a Pokémon cannot Protect itself, and all attacks against it are guaranteed critical hits. Jinx wears off after 3 turns. Fairy-types do the most jinxing."),
        _INTL("Fractured") => _INTL("When fractured, a Pokémon deals 33% less damage with its moves. Fracture wears off after 3 turns. Rock-types do the most fracturing."),
        _INTL("Curse") => _INTL("When cursed, a Pokémon loses 25% of its HP every turn. Ghost-types do the most cursing."),
        _INTL("Torment") => _INTL("When tormented, a Pokémon cannot use the same move twice in a row. If something prevents it from moving for a turn, it can choose the same move the following turn."),
        _INTL("Taunt") => _INTL("When taunted, a Pokémon is prevented from using status moves."),
        _INTL("Disable") => _INTL("When disabled, a Pokémon cannot use the move it last selected."),
        _INTL("Bar") => _INTL("When barred, a Pokémon cannot use moves that don't share a type with themselves."),
        _INTL("Trapping") => _INTL("When trapped, a  Pokémon cannot switch out of battle. Includes manually switching, being forced out, or using a move like U-Turn."),
        _INTL("Substitute") => _INTL("A substitute blocks attacks and status effects. It has HP equal to the amount of HP it took to create it. Sound tag moves ignore substitute."),
        _INTL("Transformed") => _INTL("A transformed Pokémon becomes a copy of another. It gains their ability, moves, stats (except HP), and step boosts."),
        _INTL("Perish Song") => _INTL("A Pokémon affected by Perish Song will faint when the timer ends. Avatars will be damaged for half of an HP bar."),
        _INTL("Grounded") => _INTL("A grounded Pokémon loses their immunity to ground moves (from being Flying-type or having a Levitate ability)."),
    }
end

def battleGuideCriticalHitsHash
    return {
        _INTL("What are Critical Hits?") => _INTL("A critical hit deals 50% more damage than a regular hit. Certain moves are able to randomly critical hit."),
        _INTL("How common are Critical Hits?") => _INTL("For moves that can random crit, the chance is 1/8. This chance can be raised by abilities, items, or special effects."),
        _INTL("Other Effects") => _INTL("Critical hits ignore stat steps (on the user or the target) that would lower their damage. They also ignore protective screens like Reflect and Light Screen."),
        _INTL("Preventing Criticals") => _INTL("Certain abilities prevent critical hits against that Pokemon. The Lucky Chant effect protects their side from critical hits."),
        _INTL("Guaranteed Criticals") => _INTL("Some moves or abilities are not random, but guarantee a critical hit under certain conditions. Otherwise, these act the same as random critical hits."),
    }
end

def battleGuideTribesHash
    return {
        _INTL("What are Tribes?") => _INTL("Every Pokémon has 1-3 Tribes, decided by their species. Have 5 Pokémon of a shared Tribe on your team, and your entire team will receive that Tribe's bonus in battle!"),
        _INTL("Tribal Bonus") => _INTL("Tribal Bonuses are not identical: each Tribe provides a unique boon. With careful team composition, you can have 2 or even 3 Tribal Bonuses active at once!"),
        _INTL("Are they important?") => _INTL("Tribes are not required in any way to complete the game. They are simply an alternative team-building challenge to play with, like Single Type runs."),
    }
end

def battleGuideTrainersHash
    return {
        _INTL("What are Enemy Trainers?") => _INTL("Enemy Trainers are the Pokémon Trainers you will battle throughout the game. Some block your path forwards (like Gym Leaders), others are optional."),
        _INTL("Detecting Trainers") => _INTL("Trainers are people who have a companion Pokémon next to them. If a person doesn't have that, they either aren't a Trainer, or are an inactive one."),
        _INTL("Avoiding Trainers") => _INTL("Trainers will challenge you if they see you within 4 tiles of them. Avoid them by going out of that distance, sneaking around them, or waiting until they move."),
        _INTL("Trainer Inactivity") => _INTL("When you defeat a Trainer, they will become inactive until the next time you heal at a PokéCenter. This is indicated by them returning their companion Pokémon to its Poké Ball."),
        _INTL("Perfecting Fights") => _INTL("If you defeat a Trainer without any of your Pokémon fainting, you've 'perfected' the fight. They will leave forever and drop experience candy as a reward."),
        _INTL("Enemy Teams") => _INTL("Enemy Trainers have their own teams of Pokémon with their own moves and held items. It's important to pay attention to these possibilities to win battles."),
        _INTL("Differences") => _INTL("The typical trainer has 3 Pokémon, but Gym Leaders will have more. Trainers with more Pokémon also have more move variety and more items on their Pokémon."),
        _INTL("Pro Trainers") => _INTL("Pro Trainers are special Trainers, noted by their grey hair and black clothes. Their teams are always 6 Pokémon, all with items, and built around a Tribal Bonus. They're hard!"),
        _INTL("Trainer Behaviour") => _INTL("Individual Trainers will always react to the same in-battle circumstances the same way. You can learn how to beat or even perfect a Trainer through trial and error."),
    }
end

def battleGuideAvatarsHash
    return {
        _INTL("What are Avatars?") => _INTL("Avatars are powerful enemy Pokémon with unique properties that you will fight and destroy during your adventure. They cannot be caught."),
        _INTL("Avatars are Healthy") => _INTL("Avatars have two health bars, which means they have a lot of health. Much more than double the normal amount!"),
        _INTL("Multi-Move") => _INTL("Avatars can move twice each turn. Their second move will happen after every battler has used their regular move for the turn."),
        _INTL("Two Statuses") => _INTL("Avatars are large, and have room for up to two status conditions at a time. They can't have two of the same condition."),
        _INTL("HP-Based Effects") => _INTL("Effects that damage based on a fraction of total HP are only one-sixth as powerful against avatars, compared to normal Pokémon."),
        _INTL("Primeval Moves") => _INTL("When a health bar is depleted, avatars will use a Primeval Move! Primeval Moves are powered-up versions of status moves, which also change the Avatar's type."),
        _INTL("Clean Slate") => _INTL("Before an Avatar uses a Primeval Move, they will also heal from any status conditions and reset any of their stat steps that have been lowered."),
        _INTL("Shields") => _INTL("The top of Avatars health bars starts Shielded. Shielded bars take 75% less damage. A shield is removed when the Avatar uses a Primeval Move."),
        _INTL("Attack Choice") => _INTL("Avatars usually only have a few moves to choose from. They usually alternate between their moves on successive attacks."),
        _INTL("Target Choice") => _INTL("A targeting reticle shows which of your battles the Avatar wants to attack. It will switch to another battler, however, if their attack is made impossible."),
        _INTL("Empowered Moves") => _INTL("Some Avatars have Empowered attacks, which are powered-up versions of other attacks. They take up both of an Avatar's moves on that turn."),
        _INTL("Experience Reward") => _INTL("When an Avatar is destroyed, every Pokémon on your team is given experience, even those that are fainted."),
        _INTL("Legendary Avatars") => _INTL("Legendary Avatars are unique. You fight them with 3 Pokémon, they have 3 HP bars, and they have more moves with more smarts about how to use them."),
    }
end

def battleGuideMasterdexHash
    return {
        _INTL("What is the MasterDex?") => _INTL("The MasterDex is an advanced encyclopedia about the 900+ Pokémon available in this game."),
        _INTL("Single MasterDex") => _INTL("Access the MasterDex entry of a single Pokémon when looking at a Pokémon in the summary or the PC, or by using the Dex button in battles."),
        _INTL("Full MasterDex") => _INTL("Access the full MasterDex from your pause menu, or by pressing D when using the Dex button in battles (while it's waiting for you to select a battler)."),
        _INTL("Searching") => _INTL("When in the MasterDex, you can press your Special keybind (default Shift or Z) to open the first search page. There's dozens of searches to experiment with!"),
        _INTL("Combining Searches") => _INTL("You can begin a search while you're already looking at the results of a search. This will narrow down from what you were already looking at."),
        _INTL("Storing Searches") => _INTL("When you hold CTRL while closing out of a search, it will close the MasterDex and store the search for the next time you open it."),
        _INTL("Quick Navigation") => _INTL("Press A to go up a page at a time, or S to go down a page. Use the number keys (1-9) to quickly go to one of the tab's of a Pokémon's MasterDex entry."),
        _INTL("Move Details") => _INTL("Press the Use key (defaults to C) on the level up learnset or tutor moves tabs to begin scrolling the lists, and viewing details about individual moves."),
        _INTL("Checking Evolutions") => _INTL("Press the Use key (defaults to C) on the evolutions tab to choose a Pokémon in the same evolutionary tree, and to warp to that Pokémon's MasterDex entry."),
    }
end

def battleGuideWeathersHash
    return {
        _INTL("What are weathers?") => _INTL("Weathers are special states that effect the entire battlefield and help or hinder the Pokémon battling. Only one weather can be active at once."),
        _INTL("Weather Duration") => _INTL("Weathers last a certain number of turns. The length differs depending on what move or ability summoned the weather. The duration can be extended by certain items."),
        _INTL("Sunshine") => _INTL("Sunshine lowers attack damage by 15%. Fire and Grass-type moves/Pokémon are immune to this. Fire-type attacks are boosted by 30%."),
        _INTL("Rain") => _INTL("Rainstorm lowers attack damage by 15%. Water and Electric-type moves/Pokémon are immune to this. Water-type attacks are boosted by 30%."),
        _INTL("Sandstorm") => _INTL("Sandstorm deals damage to all Pokémon at the end of each turn. Rock and Ground-types are immune to this. Additionally, Rock-types get +50% Special Defense."),
        _INTL("Hail") => _INTL("Hail deals damage to all Pokémon at the end of each turn. Ice and Ghost-types are immune to this. Additionally, Ice-types get +50% Defense."),
        _INTL("Eclipse") => _INTL("Eclipse lowers all stats of all Pokémon every 4 turns (by 2 steps). Psychic and Dragon-types are immune to this. Additionally, Psychic-type attacks are boosted by 30%."),
        _INTL("Moonglow") => _INTL("Moonglow flinches all Pokémon every 4 turns. Fairy and Dark-types are immune to this. Additionally, Fairy-type attacks are boosted by 30%."),
        _INTL("Weather Downsides") => _INTL("Each weather has both an upside and a downside. There are items and abilities that make your Pokémon immune to these downsides regardless of type."),
        _INTL("Weather Areas") => _INTL("Certain areas in the game experience intense weather. That weather will also be present in the battles of that area. Simple daily weather will not do this."),
        _INTL("Weather Synergies") => _INTL("Each weather has dozens of moves and abilities that benefit from that weather. Pokémon using these moves/abilities ignore the downsides of their favored weather!"),
    }
end