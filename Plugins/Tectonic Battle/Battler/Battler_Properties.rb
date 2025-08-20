class PokeBattle_Battler
    # Fundamental to this object
    attr_reader   :battle
    attr_accessor :index, :pokemonIndex, :species, :type1, :type2, :ability_ids, :moves, :turnCount
    attr_accessor  :gender, :iv, :steps, :captured, :effects

    # Trackers
    attr_accessor  :participants, :lastAttacker, :lastFoeAttacker, :lastHPLost, :lastHPLostFromFoe
    attr_accessor  :lastMoveUsed, :lastMoveUsedType, :lastMoveUsedCategory, :moveUsageHistory # All moves used, in order
    attr_accessor  :lastRoundMove, :lastRoundMoveType, :lastRoundMoveCategory
    attr_accessor  :lastRegularMoveUsed, :lastRegularMoveTarget, :usedDamagingMove
    attr_accessor  :lastRoundMoved, :lastMoveFailed, :lastRoundMoveFailed, :movesUsed, :currentMove
    attr_accessor  :tookDamage, :tookPhysicalHit, :tookSpecialHit, :tookPhysicalHitLastRound, :tookSpecialHitLastRound
    attr_accessor :damageState, :initialHP, :lastRoundHighestTypeModFromFoe

    # Avatar stuff
    attr_accessor  :boss, :avatarPhase
    attr_accessor  :indicesTargetedThisRound, :indicesTargetedLastRound, :indicesTargetedRoundBeforeLast
    attr_accessor  :empoweredTimer, :dmgMult, :dmgResist

    # The Pokémon and its properties
    attr_reader :pokemon
    attr_reader :fainted # Boolean to mark whether self has fainted properly
    attr_reader :totalhp, :dummy, :form, :hp, :status, :statusCount, :bossStatus, :bossStatusCount, :itemSlots, :addedAbilities
    attr_accessor :bossAI

    #=============================================================================
    # Complex accessors
    #=============================================================================
    attr_reader :level
    attr_writer :attack, :spatk, :speed, :defense, :spdef
    attr_writer :name

    def level=(value)
        @level = value
        @pokemon.level = value if @pokemon
    end

    def form=(value)
        @form = value
        @pokemon.form = value if @pokemon
        resetAbilities
    end

    def partyAbility
        return GameData::Ability.try_get(@pokemon.ability)
    end

    def partyItem
        return GameData::Item.try_get(@pokemon.item)
    end

    def hp=(value)
        @hp = value.to_i
        @pokemon.hp = value.to_i if @pokemon && !@fake
    end

    def fainted?
        return @hp <= 0 || afraid? || hasAbility?(:PACIFIST)
    end
    alias isFainted? fainted?

    def afraid?
        return false unless @pokemon
        return @pokemon.afraid?
    end

    def status=(value)
        disableEffect(:Truant) if @status == :SLEEP && value != :SLEEP
        @status = value
        @pokemon.status = value if @pokemon
        self.statusCount = 0 if value != :POISON && value != :SLEEP
        refreshDataBox
    end

    def statusCount=(value)
        @statusCount = value
        @pokemon.statusCount = value if @pokemon
        refreshDataBox
    end

    def bossStatus=(value)
        disableEffect(:Truant) if @bossStatus == :SLEEP && value != :SLEEP
        @bossStatus = value
        @bossStatusCount = 0 if value != :SLEEP
        refreshDataBox
    end

    def bossStatusCount=(value)
        @bossStatusCount = value
        refreshDataBox
    end

    def extraMovesPerTurn
        return 0 if @pokemon.nil?
        return 0 if effectActive?(:SwitchedIn)
        val = @pokemon.extraMovesPerTurn || 0
        val += @effects[:ExtraTurns]
        val += 1 if effectActive?(:GreaterGlories)
        val += 1 if effectActive?(:TemporalDistortion)
        return val
    end

    def extraMovesPerTurn=(val)
        @pokemon.extraMovesPerTurn = val
    end

    def getMoves
        movesArray = @moves.clone
        if hasActiveAbility?(:HIGHJUDGE)
            hasJudgmentAlready = false
            movesArray.each do |move|
                next unless move.id == :JUDGMENT
                hasJudgmentAlready = true
                break
            end
            unless hasJudgmentAlready
                judgment = @battle.getBattleMoveInstanceFromID(:JUDGMENT)
                movesArray.push(judgment)
            end
        end
        if @battle.field.effectActive?(:InsightRoom) && @pokemon
            speciesLearnSet = @pokemon.getMoveList
            speciesLearnSet.each do |learnSetEntry|
                moveLevel = learnSetEntry[0]
                break if moveLevel > @level
                next if moveLevel < 45
                moveAtThisLevel = learnSetEntry[1]
                
                hasMoveAlready = false
                movesArray.each do |existingMove|    
                    next unless existingMove.id == moveAtThisLevel
                    hasMoveAlready = true
                    break
                end
                next if hasMoveAlready

                insightMove = @battle.getBattleMoveInstanceFromID(moveAtThisLevel)
                movesArray.push(insightMove)
                break
            end
        end
        return movesArray
    end

    def getHighestLearnsetMoveID
        return nil if @pokemon.nil?
        speciesLearnSet = @pokemon.getMoveList.reverse
        speciesLearnSet.each do |learnSetEntry|
            moveLevel = learnSetEntry[0]
            next if moveLevel > @level
            move = learnSetEntry[1]
            return move
        end
        return nil
    end

    #=============================================================================
    # Properties from Pokémon
    #=============================================================================
    def happiness
        return @pokemon ? @pokemon.happiness : 0
    end

    def nature
        return @pokemon ? @pokemon.nature : 0
    end

    def boss?
        return boss
    end

    #=============================================================================
    # Display-only properties
    #=============================================================================
    def illusion?
        return effectActive?(:Illusion)
    end

    def disguisedAs
        return @effects[:Illusion]
    end

    def transformed?
        return effectActive?(:Transform)
    end

    def technicalSpecies
        if transformed?
            return @effects[:TransformSpecies]
        else
            return @pokemon&.species
        end
    end

    def countsAs?(speciesCheck)
        return isSpecies?(speciesCheck) || transformedInto?(speciesCheck)
    end

    def transformedInto?(transformSpecies)
        return @effects[:TransformSpecies] == transformSpecies
    end

    def name
        return disguisedAs.name if illusion?
        return @name
    end

    def displayPokemon
        return disguisedAs if illusion?
        return pokemon
    end

    def displaySpecies
        return disguisedAs.species if illusion?
        return species
    end

    def displayGender
        return disguisedAs.gender if illusion?
        return gender
    end

    def displayForm
        return disguisedAs.form if illusion?
        return form
    end

    def shiny?
        return false if boss?
        return disguisedAs.shiny? if illusion?
        return @pokemon&.shiny?
    end
    alias isShiny? shiny?

    def owned?
        return false unless @battle.wildBattle?
        return $Trainer.owned?(displaySpecies)
    end
    alias owned owned?

    def pbThis(lowerCase = false)
        if opposes?
            if @battle.trainerBattle?
                return lowerCase ? _INTL("the opposing {1}", name) : _INTL("The opposing {1}", name)
            elsif !boss?
                return lowerCase ? _INTL("the wild {1}", name) : _INTL("The wild {1}", name)
            else
                return lowerCase ? _INTL("the avatar of {1}", name) : _INTL("The avatar of {1}", name)
            end
        elsif !pbOwnedByPlayer?
            return lowerCase ? _INTL("the ally {1}", name) : _INTL("The ally {1}", name)
        end
        return name
    end

    def pbTeam(lowerCase = false)
        if opposes?
            return lowerCase ? _INTL("the opposing team") : _INTL("The opposing team")
        end
        return lowerCase ? _INTL("your team") : _INTL("Your team")
    end

    def pbOpposingTeam(lowerCase = false)
        if opposes?
            return lowerCase ? _INTL("your team") : _INTL("Your team")
        end
        return lowerCase ? _INTL("the opposing team") : _INTL("The opposing team")
    end

    def itemTypeChosen
        return @pokemon.itemTypeChosen
    end

    #=============================================================================
    # Calculated properties
    #=============================================================================
    def pbWeight
        ret = @pokemon ? @pokemon.weight : 500
        ret = GameData::Species.get(@effects[:TransformSpecies]).weight if effectActive?(:Transform)
        ret += @effects[:WeightChange]
        @effects[:Refurbished].times do
            ret /= 2.0
        end
        ret *= 2 if @battle.gravityIntensified?
        ret = ret.round
        ret = 1 if ret < 1
        unless @battle.moldBreaker
            eachActiveAbility do |ability|
                ret = BattleHandlers.triggerWeightCalcAbility(ability, self, ret)
            end
        end
        eachActiveItem do |item|
            ret = BattleHandlers.triggerWeightCalcItem(item, self, ret)
        end
        return [ret, 1].max
    end

    def pbHeight
        ret = @pokemon ? @pokemon.height : 2.0
        ret = GameData::Species.get(@effects[:TransformSpecies]).height if effectActive?(:Transform)
        ret = 1 if ret < 1
        return ret
    end
end
