#===============================================================================
#
#===============================================================================
class PokemonEncounters
  attr_reader :step_count

  def initialize
		@step_chances       = {}
		@encounter_tables   = {}
		@chance_accumulator = 0
		@lastEncounter		= nil
	end

  def setup(map_ID)
    @step_count       = 0
    @step_chances     = {}
    @encounter_tables = {}
    encounter_data = GameData::Encounter.get(map_ID, $PokemonGlobal.encounter_version)
    if encounter_data
      encounter_data.step_chances.each { |type, value| @step_chances[type] = value }
      @encounter_tables = Marshal.load(Marshal.dump(encounter_data.types))
    end
  end

  def reset_step_count
    @step_count = 0
    @chance_accumulator = 0
  end

  #=============================================================================

  # Returns whether encounters for the given encounter type have been defined
  # for the current map.
  def has_encounter_type?(enc_type)
    return false if !enc_type
    return @encounter_tables[enc_type] && @encounter_tables[enc_type].length > 0
  end

  # Returns whether encounters for the given encounter type have been defined
  # for the given map. Only called by Bug Catching Contest to see if it can use
  # the map's BugContest encounter type to generate caught Pokémon for the other
  # contestants.
  def map_has_encounter_type?(map_ID, enc_type)
    return false if !enc_type
    encounter_data = GameData::Encounter.get(map_ID, $PokemonGlobal.encounter_version)
    return false if !encounter_data
    return encounter_data.types[enc_type] && encounter_data.types[enc_type].length > 0
  end

  # Returns whether land-like encounters have been defined for the current map.
  # Applies only to encounters triggered by moving around.
  def has_land_encounters?
    GameData::EncounterType.each do |enc_type|
      next if ![:land, :contest].include?(enc_type.type)
      return true if has_encounter_type?(enc_type.id)
    end
    return false
  end

  # Returns whether land-like encounters have been defined for the current map
  # (ignoring the Bug Catching Contest one).
  # Applies only to encounters triggered by moving around.
  def has_normal_land_encounters?
    GameData::EncounterType.each do |enc_type|
      return true if enc_type.type == :land && has_encounter_type?(enc_type.id)
    end
    return false
  end

  # Returns whether cave-like encounters have been defined for the current map.
  # Applies only to encounters triggered by moving around.
  def has_cave_encounters?
    GameData::EncounterType.each do |enc_type|
      return true if enc_type.type == :cave && has_encounter_type?(enc_type.id)
    end
    return false
  end

  # Returns whether water-like encounters have been defined for the current map.
  # Applies only to encounters triggered by moving around (i.e. not fishing).
  def has_water_encounters?
    GameData::EncounterType.each do |enc_type|
      return true if enc_type.type == :water && has_encounter_type?(enc_type.id)
    end
    return false
  end

  #=============================================================================

  # Returns whether the player's current location allows wild encounters to
  # trigger upon taking a step.
  def encounter_possible_here?
    return !$game_map.encounter_terrain_tag($game_player.x, $game_player.y).nil?
  end

  def encounters_blocked?(considerRepels = false)
    return true if !$Trainer
    return true if $Trainer.first_pokemon&.hasItem?(:CLEANSETAG)
    return true if $game_system.encounter_disabled
    return true if debugControl
    return true if $PokemonGlobal.noise_machine_state == 1
    return true if considerRepels && $PokemonGlobal.repel > 0
    return false
  end

  # Returns whether a wild encounter should happen, based on its encounter
  # chance. Called when taking a step and by Rock Smash.
  def encounter_triggered?(enc_type, repel_active = false, triggered_by_step = true)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    return false if encounters_blocked?
    # Check if enc_type has a defined step chance/encounter table
    return false if !@step_chances[enc_type] || @step_chances[enc_type] == 0
    return false if !has_encounter_type?(enc_type)
    encountersDrawnIn = $PokemonGlobal.noise_machine_state == 2
    # Get base encounter chance and minimum steps grace period
    encounter_chance = @step_chances[enc_type].to_f
    min_steps_needed = (8 - encounter_chance / 10).clamp(0, 8).to_f
    min_steps_needed /= 2 if encountersDrawnIn
    # Apply modifiers to the encounter chance and the minimum steps amount
    if triggered_by_step
      encounter_chance += @chance_accumulator / 200
      encounter_chance *= 0.8 if $PokemonGlobal.bicycle
      encounter_chance *= 2.0 if encountersDrawnIn
    end
    # Wild encounters are much less likely to happen for the first few steps
    # after a previous wild encounter
    if triggered_by_step && @step_count < min_steps_needed
      @step_count += 1
      return false if rand(100) >= encounter_chance * 5 / (@step_chances[enc_type] + @chance_accumulator / 200)
    end
    # Decide whether the wild encounter should actually happen
    return true if rand(100) < encounter_chance
    # If encounter didn't happen, make the next step more likely to produce one
    if triggered_by_step
      @chance_accumulator += @step_chances[enc_type]
      @chance_accumulator = 0 if repel_active
    end
    return false
  end

  # Returns whether an encounter with the given Pokémon should be allowed after
  # taking into account Repels and ability effects.
  def allow_encounter?(enc_data, repel_active = false)
    return false if !enc_data
    return false if $catching_minigame.active?
    # Repel
    if repel_active
		  @chance_accumulator = 0
		  return false
    end
    return true
  end

  # Returns whether a wild encounter should be turned into a double wild
  # encounter.
  def have_double_wild_battle?
    return false if $PokemonTemp.forceSingleBattle
    return false if pbInSafari?
    return true if $PokemonGlobal.partner
    return false if $Trainer.able_pokemon_count <= 1
    return false if $PokemonTemp.currentDexSearch
    return true if $game_player.pbTerrainTag.double_wild_encounters
    chance = Settings::DOUBLE_WILD_BATTLE_CHANCE
    chance *= 2 if herdingActive?
    return true if rand(100) < chance
    return false
  end

  # Checks the defined encounters for the current map and returns the encounter
  # type that the given time should produce. Only returns an encounter type if
  # it has been defined for the current map.
  def find_valid_encounter_type_for_time(base_type, time)
    ret = nil
    if PBDayNight.isDay?(time)
      try_type = nil
      if PBDayNight.isMorning?(time)
        try_type = (base_type.to_s + "Morning").to_sym
      elsif PBDayNight.isAfternoon?(time)
        try_type = (base_type.to_s + "Afternoon").to_sym
      elsif PBDayNight.isEvening?(time)
        try_type = (base_type.to_s + "Evening").to_sym
      end
      ret = try_type if try_type && has_encounter_type?(try_type)
      if !ret
        try_type = (base_type.to_s + "Day").to_sym
        ret = try_type if has_encounter_type?(try_type)
      end
    else
      try_type = (base_type.to_s + "Night").to_sym
      ret = try_type if has_encounter_type?(try_type)
    end
    return ret if ret
    return (has_encounter_type?(base_type)) ? base_type : nil
  end

  # Returns the encounter method that the current encounter should be generated
  # from, depending on the player's current location.
  def encounter_type
    ret = nil
	  current_terrain_id = $game_map.encounter_terrain_tag($game_player.x, $game_player.y).id
    if $PokemonGlobal.surfing
      # Active water encounters
      case current_terrain_id
      when :ActiveWater
        ret = :ActiveWater
      when :SewerWater
        ret = :SewerWater
      when :FishingContest
        ret = :FishingContest
      when :WaterGrass
        ret = :WaterGrass
      end
    else
      case current_terrain_id
      when :Mud
        ret = :Mud
      when :TallGrass
        ret = :LandTall
      when :SparseGrass
        ret = :LandSparse
      when :Puddle
        ret = :Puddle
      when :DarkCave
        ret = :DarkCave
      when :Grass
        ret = :Land
      when :FloweryGrass
        ret = :FloweryGrass
      when :FloweryGrass2
        ret = :FloweryGrass2
      when :TintedGrass
        ret = :LandTinted
      when :SewerGrate
        ret = :SewerWater
      when :SewerFloor
        ret = :SewerFloor
      when :DarkCloud
        ret = :Cloud
      end
    end
    return ret
  end

  #=============================================================================

  # For the current map, randomly chooses a species and level from the encounter
  # list for the given encounter type. Returns nil if there are none defined.
  # A higher chance_rolls makes this method prefer rarer encounter slots.
  def choose_wild_pokemon(enc_type, chance_rolls = 1)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    enc_list = @encounter_tables[enc_type].clone
    return nil if !enc_list || enc_list.length == 0
	
    # 25% chance to only roll on Pokemon not yet caught
    uncaught_enc_list = enc_list.clone.delete_if{|e| $Trainer.owned?(e[1])}
    uncaughtChance = herdingActive? ? 50 : 25
    if uncaught_enc_list.length > 0 && rand(100) < uncaughtChance
      echoln("Only rolling encounters for uncaught Pokemon!\n")
      enc_list = uncaught_enc_list
    end
    
    if @lastEncounter && enc_list.length >= 3
      echoln("Ensuring no encounters with #{@lastEncounter}")
      enc_list = enc_list.delete_if{|e| e[1] == @lastEncounter}
    end
	
    enc_list.sort! { |a, b| b[0] <=> a[0] }   # Highest probability first
	
	  echoln("Encounter list: #{enc_list.to_s}")
	
    # Calculate the total probability value
    chance_total = 0
    enc_list.each { |a| chance_total += a[0] }
    # Choose a random entry in the encounter table based on entry probabilities
    rnd = 0
    chance_rolls.times do
      r = rand(chance_total)
      rnd = r if r > rnd   # Prefer rarer entries if rolling repeatedly
    end
    encounter = nil
    enc_list.each do |enc|
      rnd -= enc[0]
      next if rnd >= 0
      encounter = enc
      break
    end
    # Get the chosen species and level
    level = rand(encounter[2]..encounter[3])
	
	  @lastEncounter = encounter[1]
    # Return [species, level]
    return [encounter[1], level]
  end

# For the given map, randomly chooses a species and level from the encounter
  # list for the given encounter type. Returns nil if there are none defined.
  # Used by the Bug Catching Contest to choose what the other participants
  # caught.
  def choose_wild_pokemon_for_map(map_ID, enc_type)
    if !enc_type || !GameData::EncounterType.exists?(enc_type)
      raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
    end
    # Get the encounter table
    encounter_data = GameData::Encounter.get(map_ID, $PokemonGlobal.encounter_version)
    return nil if !encounter_data
    enc_list = encounter_data.types[enc_type]
    return nil if !enc_list || enc_list.length == 0
	
    # 25% chance to only roll on Pokemon not yet caught
    uncaught_enc_list = enc_list.delete_if{|e| $Trainer.owned?(e[1])}
    if uncaught_enc_list.length > 0 && rand(100) < 25
      echoln("Only rolling encounters for uncaught Pokemon!\n")
      enc_list = uncaught_enc_list
    end
	
    # Calculate the total probability value
    chance_total = 0
    enc_list.each { |a| chance_total += a[0] }
    # Choose a random entry in the encounter table based on entry probabilities
    rnd = 0
    chance_rolls.times do
      r = rand(chance_total)
      rnd = r if r > rnd   # Prefer rarer entries if rolling repeatedly
    end
    encounter = nil
    enc_list.each do |enc|
      rnd -= enc[0]
      next if rnd >= 0
      encounter = enc
      break
    end
    # Return [species, level]
    level = rand(encounter[2]..encounter[3])
    return [encounter[1], level]
  end

	# Returns whether the given species can be encountered in the given encounter list
	# of the current map
	def speciesEncounterableInType(species,enc_type)
		if !enc_type || !GameData::EncounterType.exists?(enc_type)
		  raise ArgumentError.new(_INTL("Encounter type {1} does not exist", enc_type))
		end
		enc_list = @encounter_tables[enc_type]
		return false if !enc_list || enc_list.length == 0
		enc_list.each do |e|
			return true if species == e[1]
		end
		return false
	end
end