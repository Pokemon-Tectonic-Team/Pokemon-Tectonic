class PokeBattle_Battle
    attr_reader   :scene            # Scene object for this battle
    attr_reader   :peer
    attr_reader   :field            # Effects common to the whole of a battle
    attr_reader   :sides            # Effects common to each side of a battle
    attr_reader   :positions        # Effects that apply to a battler position
    attr_reader   :battlers         # Currently active Pokémon
    attr_reader   :sideSizes        # Array of number of battlers per side
    attr_accessor :backdrop         # Filename fragment used for background graphics
    attr_accessor :backdropBase     # Filename fragment used for base graphics
    attr_accessor :time             # Time of day (0=day, 1=eve, 2=night)
    attr_accessor :environment      # Battle surroundings (for mechanics purposes)
    attr_reader   :turnCount
    attr_accessor :decision         # Decision: 0=undecided; 1=win; 2=loss; 3=escaped; 4=caught
    attr_reader   :player           # Player trainer (or array of trainers)
    attr_accessor   :opponent         # Opponent trainer (or array of trainers)
    attr_accessor :items            # Items held by opponents
    attr_accessor :endSpeeches
    attr_accessor :endSpeechesWin
    attr_accessor :party1starts     # Array of start indexes for each player-side trainer's party
    attr_accessor :party2starts     # Array of start indexes for each opponent-side trainer's party
    attr_accessor :internalBattle   # Internal battle flag
    attr_accessor :debug            # Debug flag
    attr_accessor :canRun           # True if player can run from battle
    attr_accessor :canLose          # True if player won't black out if they lose
    attr_accessor :switchStyle      # Switch/Set "battle style" option
    attr_accessor :showAnims        # "Battle Effects" option
    attr_accessor :controlPlayer    # Whether player's Pokémon are AI controlled
    attr_accessor :expGain          # Whether Pokémon can gain Exp/EVs
    attr_accessor :moneyGain        # Whether the player can gain/lose money
    attr_accessor :rules
    attr_accessor :choices          # Choices made by each Pokémon this round
    attr_accessor :megaEvolution    # Battle index of each trainer's Pokémon to Mega Evolve
    attr_reader   :initialItems
    attr_reader   :recycleItems
    attr_reader   :belch
    attr_reader   :luster
    attr_reader   :moveUsageCount
    attr_reader   :usedInBattle     # Whether each Pokémon was used in battle (for Burmy)
    attr_reader   :successStates    # Success states
    attr_accessor :lastMoveUsed     # Last move used
    attr_accessor :lastMoveUser     # Last move user
    attr_accessor :allMovesUsedSide0     # The list of all moves used by side 0, in order
    attr_accessor :allMovesUsedSide1     # The list of all moves used by side 1, in order
    attr_reader   :switching        # True if during the switching phase of the round
    attr_accessor :futureSight      # True if Future Sight is hitting
    attr_accessor :specialUsage     # True if a special usage is happening
    attr_reader   :endOfRound       # True during the end of round
    attr_accessor :moldBreaker      # True if Mold Breaker applies
    attr_reader   :struggle         # The Struggle move
    attr_accessor :ballsUsed # Number of balls thrown without capture
    attr_accessor :messagesBlocked
    attr_accessor :commandPhasesThisRound
    attr_accessor :battleAI
    attr_accessor :bossBattle
    attr_accessor :autoTesting
    attr_accessor :autoTestingIndex
    attr_accessor :honorAura
    attr_accessor :expStored
    attr_reader	  :curses
    attr_accessor :expCapped
    attr_accessor :turnsToSurvive
    attr_accessor :playerAmbushing
    attr_accessor :foeAmbushing
    attr_reader   :statItemsAreMetagameRevealed
    attr_reader   :magneticGauntletBallsRecovered
    attr_accessor :laneTargeting # Whether or not pokemon can only target foes across from them
    attr_accessor :shiftEnabled # Whether a Pokemon can use an action to switch spots with their ally
    attr_accessor :doubleShift # Whether shifting is allowed in double battles

    #=============================================================================
    # Creating the battle class
    #=============================================================================
    def initialize(scene, p1, p2, player, opponent)
        if p1.length == 0
            raise ArgumentError, _INTL("Party 1 has no Pokémon.")
        elsif p2.length == 0
            raise ArgumentError, _INTL("Party 2 has no Pokémon.")
        end
        @scene             = scene
        @peer              = PokeBattle_BattlePeer.create
        @battleAI          = PokeBattle_AI.new(self)
        @field             = PokeBattle_ActiveField.new(self) # Whole field (gravity/rooms)
        @sides             = [PokeBattle_ActiveSide.new(self, 0), # Player's side
                              PokeBattle_ActiveSide.new(self, 1),] # Foe's side
        @positions         = [] # Battler positions
        @battlers          = []
        @sideSizes         = [1, 1] # Single battle, 1v1
        @backdrop          = ""
        @backdropBase      = nil
        @time              = 0
        @environment       = :None # e.g. Tall grass, cave, still water
        @turnCount         = 0
        @preBattle         = true
        @decision          = 0
        @caughtPokemon     = []
        player   = [player] if !player.nil? && !player.is_a?(Array)
        opponent = [opponent] if !opponent.nil? && !opponent.is_a?(Array)
        @player            = player     # Array of Player/NPCTrainer objects, or nil
        @opponent          = opponent   # Array of NPCTrainer objects, or nil
        @items             = nil
        @endSpeeches       = []
        @endSpeechesWin    = []
        @party1            = p1
        @party2            = p2
        @party1order       = Array.new(@party1.length) { |i| i }
        @party2order       = Array.new(@party2.length) { |i| i }
        @party1starts      = [0]
        @party2starts      = [0]
        @internalBattle    = true
        @debug             = false
        @canRun            = true
        @canLose           = false
        @switchStyle       = true
        @showAnims         = true
        @controlPlayer     = false
        @expGain           = true
        @moneyGain         = true
        @rules             = {}
        @priority          = []
        @priorityTrickRoom = false
        @choices           = []
        @megaEvolution     = [
            [-1] * (@player ? @player.length : 1),
            [-1] * (@opponent ? @opponent.length : 1),
        ]
        @initialItems = [
            Array.new(@party1.length) { |i| (@party1[i]) ? @party1[i].items.clone : nil },
            Array.new(@party2.length) { |i| (@party2[i]) ? @party2[i].items.clone : nil },
        ]
        @recycleItems      = [Array.new(@party1.length, nil),   Array.new(@party2.length, nil)]
        @belch             = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
        @luster            = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
        @moveUsageCount    = [Array.new(@party1.length, {}),   Array.new(@party2.length, {})]
        @usedInBattle      = [Array.new(@party1.length, false), Array.new(@party2.length, false)]
        @successStates     = []
        @lastMoveUsed      = nil
        @lastMoveUser      = -1
        @allMovesUsedSide0 = []
        @allMovesUsedSide1 = []
        @switching         = false
        @futureSight       = false
        @specialUsage      = false
        @endOfRound        = false
        @moldBreaker       = false
        @runCommand        = 0
        @nextPickupUse     = 0
        @ballsUsed = 0
        @messagesBlocked = false
        @bossBattle		   = false
        @autoTesting	   = false
        @autoTestingIndex = 1
        @commandPhasesThisRound = 0
        @honorAura = false
        @curses = []
        @expStored		   = 0
        @expCapped		   = false
        @turnsToSurvive = -1
        @playerAmbushing = false
        @foeAmbushing = false
        @magneticGauntletBallsRecovered = 0
        @laneTargeting = false
        @shiftEnabled = false
        @doubleShift = false
        if GameData::Move.exists?(:STRUGGLE)
            @struggle = PokeBattle_Move.from_pokemon_move(self, Pokemon::Move.new(:STRUGGLE))
        else
            @struggle = PokeBattle_Struggle.new(self, nil)
        end

        BattleHandlers.loadDataDependentHandlers
        
        # System for learning the player's abilities
        @knownAbilities = {}
        @party1.each do |pokemon|
            @knownAbilities[pokemon.personalID] = []

            next unless pokemon.getAbilityList.length == 1
            abilityToKnow = pokemon.getAbilityList[0][0]
            @knownAbilities[pokemon.personalID].push(abilityToKnow)
            echoln("Player's side pokemon #{pokemon.name}'s ability #{abilityToKnow} is known by the AI, since species only has one legal ability.")
        end

        # System for learning the player's moves
        @knownMoves = {}
        echoln("===PARTY 1 KNOWN MOVES===")
        @party1.each do |pokemon|
            initializeKnownMoves(pokemon)
        end
        echoln("===PARTY 2 KNOWN MOVES===")
        @party2.each do |pokemon|
            initializeKnownMoves(pokemon)
        end

        @knownItems = {}
        echoln("===PARTY 1 KNOWN ITEMS===")
        @party1.each do |pokemon|
            initializeKnownItems(pokemon)
        end
        echoln("===PARTY 2 KNOWN ITEMS===")
        @party2.each do |pokemon|
            initializeKnownItems(pokemon)
        end

        # Set all moves to their max PP
        # and apply tribal bonuses to max PP
        setMaxPPs(true)
    end

    def initializeKnownMoves(pokemon)
        return if is_online? # known moves system not necessary for cable club battles and leaks teams
        knownMovesArray = []
        @knownMoves[pokemon.personalID] = knownMovesArray
        pokemon.moves.each do |move|
            next unless pokemon.boss? || aiAutoKnowsMove?(move,pokemon)
            knownMovesArray.push(move.id)
            echoln("Pokemon #{pokemon.name}'s move #{move.name} is known by the AI")
        end
    end

    def initializeKnownItems(pokemon)
        knownItemsArray = []
        @knownItems[pokemon.personalID] = knownItemsArray
        pokemon.items.each do |item|
            next # TO DO
            knownItemsArray.push(item)
            echoln("Pokemon #{pokemon.name}'s item #{getItemName(item)} is known by the AI")
        end
    end

    def aiAutoKnowsMove?(move,pokemon)
        autoKnow = getBattleMoveInstanceFromID(move.id).aiAutoKnows?(pokemon)
        return true if !autoKnow.nil? && autoKnow
        return false if !autoKnow.nil? && !autoKnow
        return false unless pokemon.likelyHasSTAB?(move.type) # Don't know off-type moves
        return false if move.category == 2 # Don't know status moves
        return true
    end

    def setMaxPPs(includeMults)
        @player&.each do |trainer|
            setMaxPPsForTrainer(trainer,includeMults)
        end

        @opponent&.each do |trainer|
            setMaxPPsForTrainer(trainer,includeMults)
        end
    end

    def setMaxPPsForTrainer(trainer,includeMults)
        pp_mult = 1
        if includeMults
            pp_mult *= 2.0 if trainer.tribalBonus.hasTribeBonus?(:TACTICIAN)
        end

        trainer.party.each do |pokemon|
            pokemon.moves.each do |move|
                move.pp_mult = pp_mult
                move.restore_pp
            end
        end
    end
end
