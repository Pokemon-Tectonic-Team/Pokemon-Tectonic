class PokeBattle_Battler
	#=============================================================================
	# Creating a battler
	#=============================================================================
	def initialize(btl, idxBattler)
		@battle = btl
		@index       = idxBattler
		@captured    = false
		@dummy       = false
		@stages      = {}
		@effects     = {}
		@damageState = PokeBattle_DamageState.new
		pbInitBlank
		pbInitProcs()
		pbInitEffects(false)
	end

	def pbInitProcs()
		@location = :Battler
		@apply_proc = Proc.new { |effectData|
			effectData.apply_battler(@battle, self)
		}
		@disable_proc = Proc.new { |effectData|
			effectData.disable_battler(@battle, self)
		}
		@eor_proc = Proc.new { |effectData|
			effectData.eor_battler(@battle, self)
		}
		@remain_proc = Proc.new { |effectData|
			effectData.remain_battler(@battle, self)
		}
		@expire_proc = Proc.new { |effectData|
			effectData.expire_battler(@battle, self)
		}
		@increment_proc = Proc.new { |effectData,increment|
			effectData.increment_battler(@battle, self,increment)
		}
	end

	def pbInitBlank
		@name           = ''
		@species        = 0
		@form           = 0
		@level          = 0
		@hp = @totalhp  = 0
		@type1 = @type2 = nil
		@ability_id     = nil
		@item_id        = nil
		@gender         = 0
		@attack = @defense = @spatk = @spdef = @speed = 0
		@status         = :NONE
		@statusCount    = 0
		@pokemon        = nil
		@pokemonIndex   = -1
		@participants   = []
		@moves          = []
		@iv             = {}
		GameData::Stat.each_main { |s| @iv[s.id] = 0 }
		@boss	= false
		@bossStatus	= :NONE
		@bossStatusCount = 0
		@empowered	= false
		@primevalTimer	= 0
		@extraMovesPerTurn	= 0
		@indexesTargetedThisTurn	= []
		@dmgMult = 1
		@dmgResist = 0
	end

	# Used by Future Sight only, when Future Sight's user is no longer in battle.
	def pbInitDummyPokemon(pkmn, idxParty)
		raise _INTL("An egg can't be an active Pokémon.") if pkmn.egg?
		@name         = pkmn.name
		@species      = pkmn.species
		@form         = pkmn.form
		@level        = pkmn.level
		@totalhp      = pkmn.totalhp
		@hp           = pkmn.hp
		@type1        = pkmn.type1
		@type2        = pkmn.type2
		# ability and item intentionally not copied across here
		@gender       = pkmn.gender
		@attack       = pkmn.attack
		@defense      = pkmn.defense
		@spatk        = pkmn.spatk
		@spdef        = pkmn.spdef
		@speed        = pkmn.speed
		@status       = pkmn.status
		@statusCount  = pkmn.statusCount
		@boss = pkmn.boss
		@pokemon      = pkmn
		@pokemonIndex = idxParty
		@participants = []
		# moves intentionally not copied across here
		@iv           = {}
		GameData::Stat.each_main { |s| @iv[s.id] = pkmn.iv[s.id] }
		@dummy = true
		@dmgMult   = 1
		@dmgResist = 0
	end

	def pbInitPokemon(pkmn, idxParty)
		raise _INTL("An egg can't be an active Pokémon.") if pkmn.egg?
		@name         = pkmn.name
		@species      = pkmn.species
		@form         = pkmn.form
		@level        = pkmn.level
		@totalhp      = pkmn.totalhp
		@hp           = pkmn.hp
		@type1        = pkmn.type1
		@type2        = pkmn.type2
		@ability_id   = pkmn.ability_id
		@item_id      = pkmn.item_id
		@gender       = pkmn.gender
		@attack       = pkmn.attack
		@defense      = pkmn.defense
		@spatk        = pkmn.spatk
		@spdef        = pkmn.spdef
		@speed        = pkmn.speed
		@status       = pkmn.status
		@statusCount  = pkmn.statusCount
		@dmgMult = pkmn.dmgMult
		@dmgResist = pkmn.dmgResist
		@boss = pkmn.boss
		@pokemon      = pkmn
		@pokemonIndex = idxParty
		@participants = [] # Participants earn Exp. if this battler is defeated
		@moves        = []
		pkmn.moves.each_with_index do |m, i|
			@moves[i] = PokeBattle_Move.from_pokemon_move(@battle, m)
		end
		@iv = {}
		GameData::Stat.each_main { |s| @iv[s.id] = pkmn.iv[s.id] }
	end

	def pbInitialize(pkmn, idxParty, batonPass = false)
		pbInitPokemon(pkmn, idxParty)
		pbInitEffects(batonPass)
		@damageState.reset
	end

	def pbInitEffects(batonPass)
		# Reset values, accounting for baton pass
		GameData::BattleEffect.each_battler_effect do |effectData|
			effectID = effectData.id
			# Reset the value to its default
			# Unless its a baton passable value and we are baton passing
			if batonPass && effectData.baton_passed
				currentValue = @effects[effectID]
				newValue = effectData.baton_pass_value(self, currentValue)
				@effects[effectID] = newValue
			else
				@effects[effectID] = effectData.default
			end
			effectData.initialize_battler(@battle, self)
		end

		# All battlers effects stop pointing at this battler index if appropriate
		@battle.eachBattler do |b|
			next if b.index == @index
			newEffects = {}
			b.effects.each do |effect, value|
				effectData = GameData::BattleEffect.get(effect)
				next if effectData.type != :Position
				next unless effectData.others_lose_track
				next if value != @index
				echoln("[BATTLER EFFECT] Effect #{effect} stops pointing from #{b.name} to #{name} (#{@index}) due to it exiting")
				newEffects[effect] = effectData.default
			end
			b.effects.update(newEffects)
		end

		# Cause other battlers to reset effects that were contingent on this battler
		# Remaining on the battlefield (e.g. trapping)
		@battle.eachBattler do |b|
			next if b.index == @index
			b.eachEffect(true) do |effect, value, data|
				next if data.type != :Position
				next if value != @index
				data.disable_effecs_on_other_exit.each do |effectToDisable|
					echoln("[BATTLER EFFECT] Effect #{effectToDisable} is disabled on #{b.name} due to #{name} (#{@index}) exiting")
					b.disableEffect(effectToDisable)
				end
			end
		end

		if batonPass
			# Don't reset stats
		else
			@stages[:ATTACK] = 0
			@stages[:DEFENSE]         = 0
			@stages[:SPEED]           = 0
			@stages[:SPECIAL_ATTACK]  = 0
			@stages[:SPECIAL_DEFENSE] = 0
			@stages[:ACCURACY]        = 0
			@stages[:EVASION]         = 0
		end

		@fainted               = @hp.zero?
		@initialHP             = 0
		@lastAttacker          = []
		@lastFoeAttacker       = []
		@lastHPLost            = 0
		@lastHPLostFromFoe     = 0
		@lastRoundHighestTypeModFromFoe = -1
		@tookDamage            = false
		@tookPhysicalHit       = false
		@lastMoveUsed          = nil
		@lastMoveUsedType      = nil
		@lastRegularMoveUsed   = nil
		@lastRegularMoveTarget = -1
		@lastRoundMoved        = -1
		@lastMoveFailed        = false
		@lastRoundMoveFailed   = false
		@movesUsed             = []
		@turnCount             = 0
		@avatarPhase = 1
		@primevalTimer		   = 0
		@extraMovesPerTurn = 0
		@indexesTargetedThisTurn = []
	end

	#=============================================================================
	# Refreshing a battler's properties
	#=============================================================================
	def pbUpdate(fullChange = false)
		return unless @pokemon
		@pokemon.calc_stats
		@level          = @pokemon.level
		@hp             = @pokemon.hp
		@totalhp        = @pokemon.totalhp
		unless effectActive?(:Transform)
			@attack = @pokemon.attack
			@defense      = @pokemon.defense
			@spatk        = @pokemon.spatk
			@spdef        = @pokemon.spdef
			@speed        = @pokemon.speed
			if fullChange
				@type1 = @pokemon.type1
				@type2      = @pokemon.type2
				@ability_id = @pokemon.ability_id
			end
		end
	end

	# Used to erase the battler of a Pokémon that has been caught.
	def pbReset
		@pokemon      = nil
		@pokemonIndex = -1
		@hp           = 0
		pbInitEffects(false)
		@participants = []
		# Reset status
		@status       = :NONE
		@statusCount  = 0
		# Reset choice
		@battle.pbClearChoice(@index)
	end

	# Update which Pokémon will gain Exp if this battler is defeated.
	def pbUpdateParticipants
		return if fainted? || !@battle.opposes?(@index)
		eachOpposing do |b|
			@participants.push(b.pokemonIndex) unless @participants.include?(b.pokemonIndex)
		end
	end
end
