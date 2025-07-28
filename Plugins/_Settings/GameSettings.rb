module Settings
    # The version of your game. It has to adhere to the MAJOR.MINOR.PATCH format.
    GAME_VERSION = "3.3.3"
    DEV_VERSION  = false
  
    #=============================================================================
  
    # The default screen width (at a scale of 1.0).
    SCREEN_WIDTH  = 512
    # The default screen height (at a scale of 1.0).
    SCREEN_HEIGHT = 384
    # The default screen scale factor. Possible values are 0.5, 1.0, 1.5 and 2.0.
    SCREEN_SCALE  = 1.0
  
    #=============================================================================
  
    # The maximum level Pokémon can reach.
    MAXIMUM_LEVEL        = 70
    # The level of newly hatched Pokémon.
    EGG_LEVEL            = 1
    # The odds of a newly generated Pokémon being shiny (out of 65536).
    SHINY_POKEMON_CHANCE = 16
    # The chance that a wild battle will be a double battle (out of 100)
    DOUBLE_WILD_BATTLE_CHANCE = 20
  
    #=============================================================================
  
    # The amount of money the player starts the game with.
    INITIAL_MONEY        = 3000
    # The maximum amount of money the player can have.
    MAX_MONEY            = 999_999_999
    # The maximum number of Game Corner coins the player can have.
    MAX_COINS            = 99_999
    # The maximum number of Battle Points the player can have.
    MAX_BATTLE_POINTS    = 9_999
    # The maximum amount of soot the player can have.
    MAX_SOOT             = 9_999
    # The maximum length, in characters, that the player's name can be.
    MAX_PLAYER_NAME_SIZE = 10
    # The maximum number of Pokémon that can be in the party.
    MAX_PARTY_SIZE       = 6
  
    #=============================================================================
  
    # A set of arrays each containing a trainer type followed by a Global Variable
    # number. If the variable isn't set to 0, then all trainers with the
    # associated trainer type will be named as whatever is in that variable.
    RIVAL_NAMES = []
  
    #=============================================================================
  
    # Whether outdoor maps should be shaded according to the time of day.
    TIME_SHADING = true
  
    #=============================================================================
  
    # Whether poisoned Pokémon will lose HP while walking around in the field.
    POISON_IN_FIELD       = true
    # Whether poisoned Pokémon will faint while walking around in the field
    # (true), or survive the poisoning with 1 HP (false).
    POISON_FAINT_IN_FIELD = false
    # Whether planted berries grow according to Gen 4 mechanics (true) or Gen 3
    # mechanics (false).
    NEW_BERRY_PLANTS      = true
    # Whether fishing automatically hooks the Pokémon (true), or whether there is
    # a reaction test first (false).
    FISHING_AUTO_HOOK     = false
    # The ID of the common event that runs when the player starts fishing (runs
    # instead of showing the casting animation).
    FISHING_BEGIN_COMMON_EVENT = -1
    # The ID of the common event that runs when the player stops fishing (runs
    # instead of showing the reeling in animation).
    FISHING_END_COMMON_EVENT   = -1
  
    #=============================================================================
  
    # The number of steps allowed before a Safari Zone game is over (0=infinite).
    SAFARI_STEPS     = 600
    # The number of seconds a Bug Catching Contest lasts for (0=infinite).
    BUG_CONTEST_TIME = 20 * 60   # 20 minutes
  
    #=============================================================================
  
    # Pairs of map IDs, where the location signpost isn't shown when moving from
    # one of the maps in a pair to the other (and vice versa). Useful for single
    # long routes/towns that are spread over multiple maps.
    #   e.g. [4,5,16,17,42,43] will be map pairs 4,5 and 16,17 and 42,43.
    # Moving between two maps that have the exact same name won't show the
    # location signpost anyway, so you don't need to list those maps here.
    NO_SIGNPOSTS = []
  
    #=============================================================================
  
    # Whether you need at least a certain number of badges to use some hidden
    # moves in the field (true), or whether you need one specific badge to use
    # them (false). The amounts/specific badges are defined below.
    FIELD_MOVES_COUNT_BADGES = true
    # Depending on FIELD_MOVES_COUNT_BADGES, either the number of badges required
    # to use each hidden move in the field, or the specific badge number required
    # to use each move. Remember that badge 0 is the first badge, badge 1 is the
    # second badge, etc.
    #   e.g. To require the second badge, put false and 1.
    #        To require at least 2 badges, put true and 2.
    BADGE_FOR_CUT       = 1
    BADGE_FOR_FLASH     = 2
    BADGE_FOR_ROCKSMASH = 3
    BADGE_FOR_SURF      = 4
    BADGE_FOR_FLY       = 5
    BADGE_FOR_STRENGTH  = 6
    BADGE_FOR_DIVE      = 7
    BADGE_FOR_WATERFALL = 8
  
    #=============================================================================
  
    # If a move taught by a TM/HM/TR replaces another move, this setting is
    # whether the machine's move retains the replaced move's PP (true), or whether
    # the machine's move has full PP (false).
    TAUGHT_MACHINES_KEEP_OLD_PP          = false
    # Whether the Black/White Flutes will raise/lower the levels of wild Pokémon
    # respectively (true), or will lower/raise the wild encounter rate
    # respectively (false).
    FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS  = true
    # Whether Repel uses the level of the first Pokémon in the party regardless of
    # its HP (true), or it uses the level of the first unfainted Pokémon (false).
    REPEL_COUNTS_FAINTED_POKEMON         = true
    # Whether Rage Candy Bar acts as a Full Heal (true) or a Potion (false).
    RAGE_CANDY_BAR_CURES_STATUS_PROBLEMS = true
  
    #=============================================================================
  
    # The name of the person who created the Pokémon storage system.
    def self.storage_creator_name
      return _INTL("Bill")
    end
    # The number of boxes in Pokémon storage.
    NUM_STORAGE_BOXES = 40
    NUM_DONATION_BOXES = 5
  
    #=============================================================================
  
    # The names of each pocket of the Bag. Ignore the first entry ("").
    def self.bag_pocket_names
      return ["",
        _INTL("Items"),
        _INTL("Medicine"),
        _INTL("Poké Balls"),
        _INTL("TMs"),
        _INTL("Held Items"),
        _INTL("Sell Items"),
        _INTL("Keys"),
        _INTL("Tools")
      ]
    end
    # The maximum number of slots per pocket (-1 means infinite number). Ignore
    # the first number (0).
    BAG_MAX_POCKET_SIZE  = [0, -1, -1, -1, -1, -1, -1, -1, -1]
    # The maximum number of items each slot in the Bag can hold.
    BAG_MAX_PER_SLOT     = 999
    # Whether each pocket in turn auto-sorts itself by item ID number. Ignore the
    # first entry (the 0).
    BAG_POCKET_AUTO_SORT = [0, false, false, false, true, true, false, false, false]
  
    #=============================================================================
  
    # Whether the Pokédex list shown is the one for the player's current region
    # (true), or whether a menu pops up for the player to manually choose which
    # Dex list to view if more than one is available (false).
    USE_CURRENT_REGION_DEX = true
    
    # The names of the Pokédex lists, in the order they are defined in the PBS
    # file "regionaldexes.txt". The last name is for the National Dex and is added
    # onto the end of this array (remember that you don't need to use it). This
    # array's order is also the order of $Trainer.pokedex.unlocked_dexes, which
    # records which Dexes have been unlocked (the first is unlocked by default).
    # If an entry is just a name, then the region map shown in the Area page while
    # viewing that Dex list will be the region map of the region the player is
    # currently in. The National Dex entry should always behave like this.
    # If an entry is of the form [name, number], then the number is a region
    # number. That region's map will appear in the Area page while viewing that
    # Dex list, no matter which region the player is currently in.
    def self.pokedex_names
      return [
        _INTL("National Pokédex")
      ]
    end
    
    # Whether all forms of a given species will be immediately available to view
    # in the Pokédex so long as that species has been seen at all (true), or
    # whether each form needs to be seen specifically before that form appears in
    # the Pokédex (false).
    DEX_SHOWS_ALL_FORMS = true
    
    # An array of numbers, where each number is that of a Dex list (in the same
    # order as above, except the National Dex is -1). All Dex lists included here
    # will begin their numbering at 0 rather than 1 (e.g. Victini in Unova's Dex).
    DEXES_WITH_OFFSETS  = []
  
    #=============================================================================
  
    # A set of arrays, each containing details of a graphic to be shown on the
    # region map if appropriate. The values for each array are as follows:
    #   * Region number.
    #   * Game Switch; the graphic is shown if this is ON (non-wall maps only).
    #   * X coordinate of the graphic on the map, in squares.
    #   * Y coordinate of the graphic on the map, in squares.
    #   * Name of the graphic, found in the Graphics/Pictures folder.
    #   * The graphic will always (true) or never (false) be shown on a wall map.
    def self.getRegionMapExtras
        return [
            [0, UNDERGROUND_RIVER_VISITED_SWITCH, 0, 0, "Underground River", false],
            [0, VOLCANIC_SHORE_VISITED_SWITCH, 0, 0, "Volcanic Shore", false],
            [0, TEMPEST_REALM_VISITED_SWITCH, 0, 0, "Tempest Realm", false],
            [0, GUARDIAN_ISLAND_VISITED_SWITCH, 0, 0, "Guardian Island", false],
            [0, EVENTIDE_ISLE_VISITED_SWITCH, 0, 0, "Eventide Isle", false],
            [0, ISLE_OF_DRAGONS_VISITED_SWITCH, 0, 0, "Isle of Dragons", false],
            [0, TRI_ISLAND_VISITED_SWITCH, 0, 0, "Tri Island", false],
            [0, BATTLE_MONUMENT_VISITED_SWITCH, 0, 0, "Battle Monument", false],
            [0, SPIRIT_ATOLL_VISITED_SWITCH, 0, 0, "Spirit Atoll", false],
            [0, BARREN_ISLAND_VISITED_SWITCH, 0, 0, "Barren Island", false],
            [0, WINDBORN_ISLAND_VISITED_SWITCH, 0, 0, "Windborn Island", false],
        ]
    end
  
    #=============================================================================
  
    # A list of maps used by roaming Pokémon. Each map has an array of other maps
    # it can lead to.
    ROAMING_AREAS = {
      5  => [   21, 28, 31, 39, 41, 44, 47, 66, 69],
      21 => [5,     28, 31, 39, 41, 44, 47, 66, 69],
      28 => [5, 21,     31, 39, 41, 44, 47, 66, 69],
      31 => [5, 21, 28,     39, 41, 44, 47, 66, 69],
      39 => [5, 21, 28, 31,     41, 44, 47, 66, 69],
      41 => [5, 21, 28, 31, 39,     44, 47, 66, 69],
      44 => [5, 21, 28, 31, 39, 41,     47, 66, 69],
      47 => [5, 21, 28, 31, 39, 41, 44,     66, 69],
      66 => [5, 21, 28, 31, 39, 41, 44, 47,     69],
      69 => [5, 21, 28, 31, 39, 41, 44, 47, 66    ]
    }
    # A set of arrays, each containing the details of a roaming Pokémon. The
    # information within each array is as follows:
    #   * Species.
    #   * Level.
    #   * Game Switch; the Pokémon roams while this is ON.
    #   * Encounter type (0=any, 1=grass/walking in cave, 2=surfing, 3=fishing,
    #     4=surfing/fishing). See the bottom of PField_RoamingPokemon for lists.
    #   * Name of BGM to play for that encounter (optional).
    #   * Roaming areas specifically for this Pokémon (optional).
    ROAMING_SPECIES = []
  
    #=============================================================================
  
    # A set of arrays, each containing the details of a wild encounter that can
    # only occur via using the Poké Radar. The information within each array is as
    # follows:
    #   * Map ID on which this encounter can occur.
    #   * Probability that this encounter will occur (as a percentage).
    #   * Species.
    #   * Minimum possible level.
    #   * Maximum possible level (optional).
    POKE_RADAR_ENCOUNTERS = []
  
    #=============================================================================
  
    # The Game Switch that is set to ON when the player blacks out.
    STARTING_OVER_SWITCH      = 1
    # The Game Switch which, while ON, makes all wild Pokémon created be shiny.
    SHINY_WILD_POKEMON_SWITCH = 31
    # The Game Switch which, while ON, makes all Pokémon created considered to be
    # met via a fateful encounter.
    FATEFUL_ENCOUNTER_SWITCH  = 32
  
    #=============================================================================
  
    # ID of the animation played when the player steps on grass (grass rustling).
    GRASS_ANIMATION_ID           = 1
    # ID of the animation played when the player lands on the ground after hopping
    # over a ledge (shows a dust impact).
    DUST_ANIMATION_ID            = 2
    # ID of the animation played when a trainer notices the player (an exclamation
    # bubble).
    EXCLAMATION_ANIMATION_ID     = 3
    # ID of the animation played when a patch of grass rustles due to using the
    # Poké Radar.
    RUSTLE_NORMAL_ANIMATION_ID   = 1
    # ID of the animation played when a patch of grass rustles vigorously due to
    # using the Poké Radar. (Rarer species)
    RUSTLE_VIGOROUS_ANIMATION_ID = 5
    # ID of the animation played when a patch of grass rustles and shines due to
    # using the Poké Radar. (Shiny encounter)
    RUSTLE_SHINY_ANIMATION_ID    = 6
    # ID of the animation played when a berry tree grows a stage while the player
    # is on the map (for new plant growth mechanics only).
    PLANT_SPARKLE_ANIMATION_ID   = 7
  
    #=============================================================================
  
    # An array of available languages in the game, and their corresponding message
    # file in the Data folder. Edit only if you have 2 or more languages to choose
    # from.
    LANGUAGES = [
      ["English", "english.dat"],
      ["Español", "spanish.dat"],
      ["Simplified Chinese", "chinese_simplified.dat"],
      ["Traditional Chinese", "chinese_traditional.dat"],
    ]
  
    #=============================================================================
  
    # Available speech frames. These are graphic files in "Graphics/Windowskins/".
    SPEECH_WINDOWSKINS = [
      "speech1",
      "speech2",
      "speech3",
      "speech4",
      "speech5",
      "speech6",
      "speech7",
      "speech8",
      "speech9",
      "speech10",
      "speech11",
      "speech12",
      "speech13",
      "speech14",
      "speech15",
      "speech16",
      "speech17",
      "speech18",
      "speech19",
      "speech20",
      "speech21"
    ]
    
    # Available menu frames. These are graphic files in "Graphics/Windowskins/".
    MENU_WINDOWSKINS = [
      "choice1",
      "choice2",
      "choice3",
      "choice4",
      "choice5",
      "choice6",
      "choice7",
      "choice8",
      "choice9",
      "choice10",
      "choice11",
      "choice12",
      "choice13",
      "choice14",
      "choice15",
      "choice16",
      "choice17",
      "choice18",
      "choice19",
      "choice20",
      "choice21",
      "choice22",
      "choice23",
      "choice24",
      "choice5",
      "choice26",
      "choice27",
      "choice28"
    ]

    #=============================================================================

    # Whether the Exp gained from beating a Pokémon should be scaled depending on
    # the gainer's level.
    SCALED_EXP_FORMULA        = false
    # Whether the Exp gained from beating a Pokémon should be divided equally
    # between each participant (true), or whether each participant should gain
    # that much Exp (false). This also applies to Exp gained via the Exp Share
    # (held item version) being distributed to all Exp Share holders.
    SPLIT_EXP_BETWEEN_GAINERS = true
    # Whether fainted Pokemon can still earn experience from participating in battle
    FAINTED_POKEMON_EARN_EXP = true
    # Whether the critical capture mechanic applies. Note that its calculation is
    # based on a total of 600+ species (i.e. that many species need to be caught
    # to provide the greatest critical capture chance of 2.5x), and there may be
    # fewer species in your game.
    ENABLE_CRITICAL_CAPTURES  = true
    # Whether Pokémon gain Exp for capturing a Pokémon.
    GAIN_EXP_FOR_CAPTURE      = false
    # The Game Switch which, whie ON, prevents the player from losing money if
    # they lose a battle (they can still gain money from trainers for winning).
    NO_MONEY_LOSS             = 33
    # Whether party Pokémon check whether they can evolve after all battles
    # regardless of the outcome (true), or only after battles the player won (false).
    CHECK_EVOLUTION_AFTER_ALL_BATTLES   = true
    # Whether fainted Pokémon can try to evolve after a battle.
    CHECK_EVOLUTION_FOR_FAINTED_POKEMON = true

    #=============================================================================

    def self.achievement_page_names
        return ["",
            _INTL("Main Story"),
            _INTL("Gyms"),
            _INTL("Avatars"),
            _INTL("Collection"),
            _INTL("Exploration"),
            _INTL("Sidequests"),
            _INTL("Battle Monument"),
            _INTL("Battle"),
            _INTL("Other"),
        ]
    end

    def self.collection_reward_page_names
        return ["",
            _INTL("Area"),
            _INTL("Type"),
            _INTL("Tribe"),
            _INTL("Total"),
        ]
    end
end