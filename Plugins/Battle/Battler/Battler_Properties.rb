class PokeBattle_Battler
	# Fundamental to this object
	attr_reader   :battle
	attr_accessor :index, :pokemonIndex, :species, :type1, :type2, :ability_id, :item_id, :moves,
															:gender, :iv, :attack, :spatk, :speed, :stages, :captured, :effects, :boss, :avatarPhase, :extraMovesPerTurn, :primevalTimer, :indexesTargetedThisTurn, :dmgMult, :dmgResist, :participants, :lastAttacker, :lastFoeAttacker, :lastHPLost, :lastHPLostFromFoe, :lastMoveUsed, :lastMoveUsedType, :lastRegularMoveUsed, :lastRegularMoveTarget, :lastRoundMoved, :lastMoveFailed, :lastRoundMoveFailed, :movesUsed, :currentMove, :tookDamage, :tookPhysicalHit, :damageState, :initialHP, :lastRoundHighestTypeModFromFoe
	# The Pokémon and its properties
	attr_reader   :pokemon
	attr_reader :totalhp, :fainted, :dummy, :form, :hp, :status, :statusCount, :bossStatus, :bossStatusCount # Boolean to mark whether self has fainted properly   # Boolean to mark whether self was captured
	# Things the battler has done in battle
	attr_accessor :turnCount # For Instruct        # For Stomping Tantrum   # For Stomping Tantrum   # ID of multi-turn move currently being used    # Boolean for whether self took damage this round     # Set at the start of each move's usage

	#=============================================================================
	# Complex accessors
	#=============================================================================
	attr_reader :level
	attr_writer :defense, :spdef, :name

	def level=(value)
		@level = value
		@pokemon.level = value if @pokemon
	end

	def form=(value)
		@form = value
		@pokemon.form = value if @pokemon
	end

	def ability
		return GameData::Ability.try_get(@ability_id)
	end

	def ability=(value)
		new_ability = GameData::Ability.try_get(value)
		@ability_id = new_ability ? new_ability.id : nil
	end

	def item
		return GameData::Item.try_get(@item_id)
	end

	def item=(value)
		new_item = GameData::Item.try_get(value)
		@item_id = new_item ? new_item.id : nil
		@pokemon.item = @item_id if @pokemon
	end

	def hp=(value)
		@hp = value.to_i
		@pokemon.hp = value.to_i if @pokemon
	end

	def fainted?
		return @hp <= 0
	end
	alias isFainted? fainted?

	def status=(value)
		disableEffect(:Truant) if @status == :SLEEP && value != :SLEEP
		disableEffect(:Toxic) if value != :POISON
		@status = value
		@pokemon.status = value if @pokemon
		self.statusCount = 0 if value != :POISON && value != :SLEEP
		@battle.scene.pbRefreshOne(@index)
	end

	def statusCount=(value)
		@statusCount = value
		@pokemon.statusCount = value if @pokemon
		@battle.scene.pbRefreshOne(@index)
	end

	def bossStatus=(value)
		disableEffect(:Truant) if @bossStatus == :SLEEP && value != :SLEEP
		@bossStatus = value
		@bossStatusCount = 0 if value != :SLEEP
		@battle.scene.pbRefreshOne(@index)
	end

	def bossStatusCount=(value)
		@bossStatusCount = value
		@battle.scene.pbRefreshOne(@index)
	end

	def extraMovesPerTurn
		return 0 if @pokemon.nil?
		val = @pokemon.extraMovesPerTurn || 0
		val += @effects[:ExtraTurns]
		return val
	end

	def extraMovesPerTurn=(val)
		@pokemon.extraMovesPerTurn = val
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

	def pokerusStage
		return @pokemon ? @pokemon.pokerusStage : 0
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

	def abilityName
		abil = ability
		return abil ? abil.name : ''
	end

	def itemName
		itm = item
		return itm ? itm.name : ''
	end

	def pbThis(lowerCase = false)
		if opposes?
			if @battle.trainerBattle?
				return lowerCase ? _INTL('the opposing {1}', name) : _INTL('The opposing {1}', name)
			elsif !boss?
				return lowerCase ? _INTL('the wild {1}', name) : _INTL('The wild {1}', name)
			else
				return lowerCase ? _INTL('the avatar of {1}', name) : _INTL('The avatar of {1}', name)
			end
		elsif !pbOwnedByPlayer?
			return lowerCase ? _INTL('the ally {1}', name) : _INTL('The ally {1}', name)
		end
		return name
	end

	def pbTeam(lowerCase = false)
		if opposes?
			return lowerCase ? _INTL('the opposing team') : _INTL('The opposing team')
		end
		return lowerCase ? _INTL('your team') : _INTL('Your team')
	end

	def pbOpposingTeam(lowerCase = false)
		if opposes?
			return lowerCase ? _INTL('your team') : _INTL('Your team')
		end
		return lowerCase ? _INTL('the opposing team') : _INTL('The opposing team')
	end

	#=============================================================================
	# Calculated properties
	#=============================================================================
	def pbWeight
		ret = @pokemon ? @pokemon.weight : 500
		ret += @effects[:WeightChange]
		ret = 1 if ret < 1
		ret = BattleHandlers.triggerWeightCalcAbility(ability, self, ret) if abilityActive? && !@battle.moldBreaker
		ret = BattleHandlers.triggerWeightCalcItem(item, self, ret) if itemActive?
		return [ret, 1].max
	end

	def pbHeight
		ret = @pokemon ? @pokemon.height : 2.0
		ret = 1 if ret < 1
		return ret
	end
end
