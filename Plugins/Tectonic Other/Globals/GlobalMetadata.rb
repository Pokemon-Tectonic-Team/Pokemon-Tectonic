class PokemonGlobalMetadata
    # Movement
    attr_accessor :bicycle
    attr_accessor :surfing
    attr_accessor :diving
    attr_accessor :sliding
    attr_accessor :fishing
    # Player data
    attr_accessor :startTime
    attr_accessor :stepcount
    attr_accessor :pcItemStorage
    attr_accessor :mailbox
    attr_accessor :phoneNumbers
    attr_accessor :phoneTime
    attr_accessor :partner
    attr_accessor :creditsPlayed
    # Pokédex
    attr_accessor :pokedexUnlocked # Deprecated, replaced with Player::Pokedex#unlocked_dexes
    attr_accessor :pokedexDex      # Dex currently looking at (-1 is National Dex)
    attr_accessor :pokedexIndex    # Last species viewed per Dex
    attr_accessor :pokedexMode     # Search mode
    attr_accessor :stored_search
    attr_accessor :dex_forms_shows_shinies
    attr_accessor :dex_tutor_list_sort_mode
    # Day Care
    attr_accessor :daycare
    attr_accessor :daycareEgg
    attr_accessor :daycareEggSteps
    # Special battle modes
    attr_accessor :safariState
    attr_accessor :bugContestState
    attr_accessor :challenge
    attr_accessor :lastbattle      # Saved recording of a battle
    # Events
    attr_accessor :eventvars
    # Affecting the map
    attr_accessor :bridge
    attr_accessor :repel
    attr_accessor :flashUsed
    attr_accessor :encounter_version
    # Map transfers
    attr_accessor :healingSpot
    attr_accessor :escapePoint
    attr_accessor :pokecenterMapId
    attr_accessor :pokecenterX
    attr_accessor :pokecenterY
    attr_accessor :pokecenterDirection
    # Movement history
    attr_accessor :visitedMaps
    attr_accessor :mapTrail
    # Counters
    attr_accessor :happinessSteps
    # Save file
    attr_accessor :safesave
    # Dexnav
    attr_accessor :dexNavEggMovesUnlocked
    attr_accessor :caughtCountsPerMap
    # Exp-EZ Dispenser
    attr_reader :expJAR
    # Aid kit
    attr_accessor :teamHealerCurrentUses
    attr_accessor :teamHealerMaxUses
    attr_accessor :teamHealerUpgrades
    # Tarot amulet
    attr_accessor :tarot_amulet_active
    # Ominous Egg stage
    attr_accessor :ominous_egg_stage
    # Chroma Clarion
    attr_accessor :chroma_clarion_recharge_steps
    # Cell booster
    attr_accessor :cell_booster_inactive
    # Ragged journal
    attr_accessor :ragged_journal_pages_collected
    # Randomizer
    attr_accessor :randomizedData
    attr_accessor :isRandomizer
    attr_accessor :randomizerRules
    # Omnitutor
    attr_accessor :omnitutor_active
    # Noise Machine
    attr_accessor :noise_machine_state # 0 = off, 1 = stopping encounters, 2 = increasing encounter rate
    # Punching bag in player house
    attr_accessor :exp_multiplier
    # Town map
    attr_accessor :town_map_waypoints_showing
    # Achievements
    attr_accessor :capture_counts_per_ball
    # Blacking out
    attr_accessor :respawnPoint
    # Battle starting
    attr_accessor :nextBattleBGM
    attr_accessor :nextBattleME
    attr_accessor :nextBattleCaptureME
    attr_accessor :nextBattleBack
    # Progression phone calls
    attr_accessor :shouldProc2BadgesZainCall
    attr_accessor :shouldProc3BadgesZainCall
    attr_accessor :shouldProcGrouzAvatarCall
    attr_accessor :shouldProcCatacombsCall
    attr_accessor :shouldProcWhitebloomCall
    attr_accessor :shouldProcEstateCall
    attr_accessor :shouldProcJovanCall
    # Tournament
    attr_accessor :tournament
    # Dragon flames
    attr_writer :dragonFlamesCount
    # Circuit puzzles
    attr_writer :puzzlesCompleted
    # Time travel
    attr_writer :timeModifiedEvents
    attr_writer :futureFilledHoles
    # Online connection data
    attr_accessor :last_partner_id
	
	def initialize
        # Movement
        @bicycle              = false
        @surfing              = false
        @diving               = false
        @sliding              = false
        @fishing              = false
        # Player data
        @startTime            = Time.now
        @stepcount            = 0
        @pcItemStorage        = nil
        @phoneNumbers         = []
        @phoneTime            = 0
        @partner              = nil
        @creditsPlayed        = false
        # Pokédex
        numRegions            = pbLoadRegionalDexes.length
        @pokedexDex           = (numRegions==0) ? -1 : 0
        @pokedexIndex         = []
        @pokedexMode          = 0
        for i in 0...numRegions+1     # National Dex isn't a region, but is included
            @pokedexIndex[i]    = 0
        end
        # Day Care
        @daycare              = [[nil,0],[nil,0]]
        @daycareEgg           = false
        @daycareEggSteps      = 0
        # Special battle modes
        @safariState          = nil
        @bugContestState      = nil
        @challenge            = nil
        @lastbattle           = nil
        # Events
        @eventvars            = {}
        # Affecting the map
        @bridge               = 0
        @repel                = 0
        @flashused            = false
        @encounter_version    = 0
        # Map transfers
        @healingSpot          = nil
        @escapePoint          = []
        @pokecenterMapId      = -1
        @pokecenterX          = -1
        @pokecenterY          = -1
        @pokecenterDirection  = -1
        # Movement history
        @visitedMaps          = []
        @mapTrail             = []
        # Counters
        @happinessSteps       = 0
        # Save file
        @safesave             = false
        # EXP-EZ Dispenser
        @expJAR				  = 0
        # DexNav
        @caughtCountsPerMap	  = {}
        # Aid Kit
        @teamHealerUpgrades   = 0
        @teamHealerMaxUses	  = 1
        @teamHealerCurrentUses= 1
        # Tarot Amulet
        @tarot_amulet_active  = false
        # Cell Booster
        @cell_booster_inactive = false
        # Ragged Journal
        @ragged_journal_pages_collected  = []
        # Ominous egg
        @ominous_egg_stage = 0
        # Chroma Clarion
        @chroma_clarion_recharge_steps = 0
        # Masterdex
        @stored_search		  = nil
        @dex_forms_shows_shinies = false
        @dex_tutor_list_sort_mode = 0

        @omnitutor_active     = false
        @noise_machine_state  = 0
        @exp_multiplier       = 1.0
        @town_map_waypoints_showing = false

        # Achievements
        @capture_counts_per_ball = {}

        @tournament = RandomTournament.new

        # Regi dungeon puzzles
        @dragonFlamesCount = 0
        @puzzlesCompleted = []
        @timeModifiedEvents = []

        @last_partner_id = ""
    end

    ####################################################
    # MasterDex starring
    ####################################################

    def pokedexStars
        @pokedexStars = {} if @pokedexStars.nil?
        return @pokedexStars
	end

	def speciesStarred?(species)
		if !pokedexStars.has_key?(species)
			pokedexStars[species] = false
		end
		return pokedexStars[species]
	end

	def toggleStarred(species)
		if !pokedexStars.has_key?(species)
			pokedexStars[species] = true
		else
			pokedexStars[species] = !pokedexStars[species]
		end
	end

    ####################################################
    # Tutorials
    ####################################################

    attr_writer :noWildEXPTutorialized

    def noWildEXPTutorialized
        @noWildEXPTutorialized = false if @noWildEXPTutorialized.nil?
        return @noWildEXPTutorialized
    end

    attr_writer :traitsTutorialized

    def traitsTutorialized
        @traitsTutorialized = false if @traitsTutorialized.nil?
        return @traitsTutorialized
    end
    
    attr_writer :statStepsTutorialized

    def statStepsTutorialized
        @statStepsTutorialized = false if @statStepsTutorialized.nil?
        return @statStepsTutorialized
    end

    attr_writer :customSpeedTutorialized

    def customSpeedTutorialized
        @customSpeedTutorialized = false if @customSpeedTutorialized.nil?
        return @customSpeedTutorialized
    end

    attr_writer :moveInfoPanelTutorialized

    def moveInfoPanelTutorialized
        @moveInfoPanelTutorialized = false if @moveInfoPanelTutorialized.nil?
        return @moveInfoPanelTutorialized
    end
    
    attr_writer :typeChartChangesTutorialized
    def typeChartChangesTutorialized
        @typeChartChangesTutorialized = false if @daycareEggSteps.nil?
        return @typeChartChangesTutorialized
    end

    attr_writer :evolutionButtonTutorialized
    def evolutionButtonTutorialized
        @evolutionButtonTutorialized = false if @evolutionButtonTutorialized.nil?
        return @evolutionButtonTutorialized
    end

    attr_writer :mentorMovesTutorialized
    def mentorMovesTutorialized
        @mentorMovesTutorialized = false if @mentorMovesTutorialized.nil?
        return @mentorMovesTutorialized
    end

    attr_writer :adaptiveMovesTutorialized
    def adaptiveMovesTutorialized
        @adaptiveMovesTutorialized = false if @adaptiveMovesTutorialized.nil?
        return @adaptiveMovesTutorialized
    end

    attr_writer :donationBoxesTutorialized
    def donationBoxesTutorialized
        @donationBoxesTutorialized = false if @donationBoxesTutorialized.nil?
        return @donationBoxesTutorialized
    end

    attr_writer :colorationDifferencesTutorialized
    def colorationDifferencesTutorialized
        @colorationDifferencesTutorialized = false if @colorationDifferencesTutorialized.nil?
        return @colorationDifferencesTutorialized
    end

    ####################################################
    # Misc.
    ####################################################
    
    def expJAR=(value)
        @expJAR = value
        unlockAchievement(:STORE_LOTS_OF_EXP) if @expJAR >= 1_000_000
    end

    def circuitPuzzleStateTracker
        @circuitPuzzleStateTracker = CircuitPuzzleStateTracker.new if @circuitPuzzleStateTracker.nil?
        return @circuitPuzzleStateTracker
    end

    def tilePuzzleStateTracker
        @tilePuzzleStateTracker = TilePuzzleStateTracker.new if @tilePuzzleStateTracker.nil?
        return @tilePuzzleStateTracker
    end

    def dragonFlamesCount
        @dragonFlamesCount = 0 if @dragonFlamesCount.nil?
        return @dragonFlamesCount
    end

    def puzzlesCompleted
        @puzzlesCompleted = [] if @puzzlesCompleted.nil?
        return @puzzlesCompleted
    end

    def timeModifiedEvents
        @timeModifiedEvents = [] if @timeModifiedEvents.nil?
        return @timeModifiedEvents
    end

    def futureFilledHoles
        @futureFilledHoles = {} if @futureFilledHoles.nil?
        return @futureFilledHoles
    end
end