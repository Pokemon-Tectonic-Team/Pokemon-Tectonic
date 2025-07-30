def openSingleDexScreen(pokemon)
	if pokemon.respond_to?('species')
		$Trainer.pokedex.register_last_seen(pokemon)
		species = pokemon.species
	else
		speciesData = GameData::Species.get(pokemon)
		species = speciesData.species
		$Trainer.pokedex.set_last_form_seen(speciesData.species, 0, speciesData.form)
	end
	ret = nil
	pbFadeOutIn {
		scene = PokemonPokedexInfo_Scene.new
		screen = PokemonPokedexInfoScreen.new(scene)
		ret = screen.pbStartSceneSingle(species)
	}
	if ret.is_a?(Symbol)
		echoln("Opening single dex screen from hyperlink to: #{ret}")
		openSingleDexScreen(ret)
	end
end
alias speciesEntry openSingleDexScreen

def openPartyDexScreen(pokemon,index)
	if pokemon.respond_to?('species')
		$Trainer.pokedex.register_last_seen(pokemon)
		species = pokemon.species
	else
		speciesData = GameData::Species.get(pokemon)
		species = speciesData.species
		$Trainer.pokedex.set_last_form_seen(speciesData.species, 0, speciesData.form)
	end
	ret = nil
	pbFadeOutIn {
		scene = PokemonPokedexInfo_Scene.new
		screen = PokemonPokedexInfoScreen.new(scene)
		ret = screen.pbStartSceneParty(index)
	}
	if ret.is_a?(Symbol)
		echoln("Opening single dex screen from hyperlink to: #{ret}")
		openSingleDexScreen(ret)
	end
end
alias speciesPartyEntry openSingleDexScreen

def unlockDex(showMessage = false)
	$Trainer.has_pokedex = true
  	$Trainer.pokedex.unlock(-1)
  	$Trainer.pokedex.refresh_accessible_dexes()
	pbMessage(_INTL("\\PN received a MasterDex!")) if showMessage
end

def describeEvolutionMethod(method,parameter=0)
	case method
	when :Level,:Ninjask; return _INTL("at level {1}", parameter)
	when :LevelMale; return _INTL("at level {1} if it's male", parameter)
	when :LevelFemale; return _INTL("at level {1} if it's female", parameter)
	when :LevelDay; return _INTL("at level {1} during the day", parameter)
	when :LevelNight; return _INTL("at level {1} during nighttime", parameter)
	when :LevelRain; return _INTL("at level {1} while raining", parameter)
	when :LevelDarkInParty; return _INTL("at level {1} while a dark type is in the party", parameter)
	when :AttackGreater; return _INTL("at level {1} if it has more attack than defense", parameter)
	when :AtkDefEqual; return _INTL("at level {1} if it has attack equal to defense", parameter)
	when :DefenseGreater; return _INTL("at level {1} if it has more defense than attack", parameter)
	when :Silcoon; return _INTL("at level {1} half of the time", parameter)
	when :Cascoon; return _INTL("at level {1} the other half of the time", parameter)
	when :Ability0; return _INTL("at level {1} if it has the first of its possible abilities", parameter)
	when :Ability1; return _INTL("at level {1} if it has the second of its possible abilities", parameter)
	when :Happiness; return _INTL("when leveled up while it has high happiness")
	when :MaxHappiness; return _INTL("when leveled up while it has maximum happiness")
	when :Beauty; return _INTL("when leveled up while it has maximum beauty")
	when :HasMove; return _INTL("when leveled up while it knows the move {1}", GameData::Move.get(parameter).name)
	when :HasMoveType; return _INTL("when leveled up while it knows a move of the {1} type", GameData::Move.get(parameter).name)
	when :Location; return _INTL("when leveled up near a special location")
	when :Item; return _INTL("by using a {1}", GameData::Item.get(parameter).name)
	when :ItemMale; return _INTL("by using a {1} if it's male", GameData::Item.get(parameter).name)
	when :ItemFemale; return _INTL("by using a {1} if it's female", GameData::Item.get(parameter).name)
	when :Trade; return _INTL("when traded")
	when :TradeItem; return _INTL("when traded holding an {1}", GameData::Item.get(parameter).name)
	when :HasInParty; return _INTL("when leveled up while a {1} is also in the party", GameData::Species.get(parameter).name)
	when :Shedinja; return _INTL("also if you have an empty Poké Ball and party slot")
	when :Originize; return _INTL("at level {1} if you spend an {2}", parameter, GameData::Item.get(:ORIGINORE).name)
	end
	return _INTL("via a method the programmer was too lazy to describe")
end

def catchDifficultyFromRareness(rareness)
	if rareness>= 250
		return "F"
	elsif rareness>= 230
		return "D-"
	elsif rareness>= 210
		return "D"
	elsif rareness>= 190
		return "D+"
	elsif rareness>= 170
		return "C-"
	elsif rareness>= 150
		return "C"
	elsif rareness>= 130
		return "C+"
	elsif rareness>= 110
		return "B-"
	elsif rareness>= 90
		return "B"
	elsif rareness >= 70
		return "B+"
	elsif rareness >= 50
		return "A-"
	elsif rareness >= 30
		return "A"
	elsif rareness >= 10
		return "A+"
	else
		return "S"
	end
	return "-"
end

def get_bnb_coverage(species_data)	
	typesOfCoverage = []
	species_data.learnable_moves.each do |move|
		moveData = GameData::Move.get(move)
		next if moveData.category == 2
		next unless moveData.base_damage >= 75
		typesOfCoverage.push(moveData.type)
	end
	typesOfCoverage.uniq!
	typesOfCoverage.compact!
	typesOfCoverage.sort_by!{|type_id| GameData::Type.get(type_id).id_number}

	return typesOfCoverage
end

def theoreticalCaptureChance(status,current_hp,total_hp,catch_rate)
	return 0 if !defined?(PokeBattle_Battle.captureThresholdCalcInternals)
	y = PokeBattle_Battle.captureThresholdCalcInternals(status,0,current_hp,total_hp,catch_rate)
	chancePerShake = y.to_f/PokeBattle_Battle::CATCH_BASE_CHANCE.to_f
	overallChance = chancePerShake ** 4
	return overallChance
end

def roundUpToNextCap(level)
	minCap = 70
	LEVEL_CAPS.each do |capLevel|
		if capLevel >= level
			minCap = capLevel
			break
		end
	end
	return minCap
end

def speciesInfoViewable?(speciesID)
    return true if $DEBUG
    speciesData = GameData::Species.get(speciesID)
    return false if speciesData.isTest?
    return true if $Trainer.seen?(speciesID)
    return false if speciesData.isLegendary?
    return true
end

def getNameForEncounterType(encounterType)
	case encounterType
	when :Land
		return _INTL("Grass")
	when :LandSparse
		return _INTL("Sparse Grass")
	when :LandTall
		return _INTL("Tall Grass")
	when :Special
		return _INTL("Other")
	when :FloweryGrass
		return _INTL("Yellow Flowers")
	when :FloweryGrass2
		return _INTL("Blue Flowers")
	when :SewerWater
		return _INTL("Sewage")
	when :SewerFloor
		return _INTL("Dirty Floor")
	when :DarkCave
		return _INTL("Dark Ground")
	when :Mud
		return _INTL("Mud")
	when :Puddle
		return _INTL("Puddle")
	when :LandTinted
		return _INTL("Secret Grass")
	when :Cloud
		return _INTL("Dark Clouds")
	when :ActiveWater
		return _INTL("Deep Water")
	when :FishingContest
		return _INTL("Surfing")
	when :WaterGrass
		return _INTL("Water Grass")
	end
	return _INTL("Unknown")
end