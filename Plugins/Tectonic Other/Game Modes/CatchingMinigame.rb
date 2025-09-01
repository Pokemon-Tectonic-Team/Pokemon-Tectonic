HAZARD_POKEMON_GLOBAL_SWITCH = 255

SaveData.register(:catching_minigame) do
	ensure_class :CatchingMinigame
	save_value { $catching_minigame }
	load_value { |value| $catching_minigame = value }
	new_game_value { CatchingMinigame.new }
end

class CatchingMinigame
    attr_reader :turnsLeft
    attr_reader :baseLevelForScoring

    attr_reader :currentMaxScore
    attr_reader :currentMaxScorePokemon

    attr_reader :highScore
    attr_reader :highScorePokemonLevel
    attr_reader :highScorePokemonSpeciesName

    def initialize
        @highScore = 0
        @highScorePokemonLevel = 0
        @highScorePokemonSpeciesName = nil
        @active = false
    end

    def begin(cutSceneLocation,returnLocation,turnsGiven=20,baseLevelForScoring=30)
        @turnsLeft = turnsGiven
        @baseLevelForScoring = baseLevelForScoring
        @currentMaxScore = 0
        @currentMaxScorePokemon = nil
        @cutSceneLocation = cutSceneLocation
        @returnLocation = returnLocation
        @active = true
        blackFadeOutIn {
            enableHazardPokemon
            transferPlayerToEvent(@cutSceneLocation[0],@cutSceneLocation[1],@cutSceneLocation[2])
        }
        pbMessage(_INTL("Catch the best Pokemon you can in {1} turns of battle!",turnsGiven))
    end

    def active?
        return @active
    end

    def submitForScoring(pokemon)
        score = scorePokemon(pokemon,@baseLevelForScoring)
        pbMessage(_INTL("Your {1} is rated at {2}.",pokemon.name,score))
        if score > @currentMaxScore
            @currentMaxScore = score
            @currentMaxScorePokemon = pokemon
        end
        if score > @highScore
            @highScore = score
            @highScorePokemonSpeciesName = GameData::Species.get(pokemon.species).name
            @highScorePokemonLevel = pokemon.level
            pbMessage(_INTL("That's a new high score!"))
        end
    end

    def scorePokemon(pokemon,baseLevelForScoring)
        rarity = GameData::Species.get(pokemon.species).catch_rate
        level = pokemon.level
        score = [((255-rarity)/4.0 + (level - baseLevelForScoring) * 4).floor,0].max
        score += 20 if pokemon.shiny?
        return score
    end

    def spendTurn()
      if @turnsLeft > 0
        @turnsLeft -= 1
      end
      echoln("Turns Left in the Catching Minigame: #{@turnsLeft}")
    end

    def endIfNeeded()
      endMinigame() if @turnsLeft == 0
    end

    def endMinigame()
        blackFadeOutIn {
            disableHazardPokemon
            transferPlayerToEvent(@cutSceneLocation[0],@cutSceneLocation[1],@cutSceneLocation[2])
        }
        pbWait(20)
        if @currentMaxScorePokemon.nil?
            pbMessage(_INTL("You caught no Pokemon worth any points."))
        else
            speciesName = GameData::Species.get(@currentMaxScorePokemon.species).name
            if @currentMaxScorePokemon.shiny?
              pbMessage(_INTL("Your best catch was a shiny level {1} {2}.",@currentMaxScorePokemon.level,speciesName))
            else
              pbMessage(_INTL("Your best catch was a level {1} {2}.",@currentMaxScorePokemon.level,speciesName))
            end
            pbMessage(_INTL("Your final score is {1}.",@currentMaxScore))
            giveReward(@currentMaxScore)
        end
        @currentMaxScore = 0
        @turnsLeft = 0
        pbWait(10)
        mapName = pbGetMessage(MessageTypes::MapNames,@returnLocation[2])
        pbMessage(_INTL("Returning to {1}.",mapName))
        pbWait(20)
        transferPlayerToEvent(@returnLocation[0],@returnLocation[1],@returnLocation[2])
        @active = false
    end

    def giveReward(score)
        item = nil
        itemCount = 1
        case score
        when 0..9
            item = nil
        when 10..19
            item = :POKEBALL
            itemCount = 2
        when 20..29
            item = :GREATBALL
            itemCount = 2
        when 30..39
            item = :ABILITYCAPSULE
        when 40..49
            item = :ULTRABALL
            itemCount = 2
        when 50..59
            item = :EXPCANDYL
        when 60..69
            item = :RELICCOPPER
            itemCount = 2
        when 70..79
            item = :EXPCANDYL
            itemCount = 2
        when 80..89
            item = :RELICSILVER
        when 90..999
            item = :RELICGOLD
            unlockAchievement(:WIN_FISHING_CONTEST)
        end
        if !item.nil?
            pbMessage(_INTL("You've earned a reward!"))
            pbReceiveItem(item,itemCount)
        else
            pbMessage(_INTL("Unfortunately, that's not enough to earn a reward."))
        end
    end

    def enableHazardPokemon
        setGlobalSwitch(HAZARD_POKEMON_GLOBAL_SWITCH,false)
    end

    def disableHazardPokemon
        setGlobalSwitch(HAZARD_POKEMON_GLOBAL_SWITCH,true)
    end
end

class CatchingMinigameBattle < PokeBattle_Battle
  def pbRecordAndStoreCaughtPokemon
    caughtPokemon = @caughtPokemon.clone
    super
    caughtPokemon.each do |pkmn|
      $catching_minigame.submitForScoring(pkmn)
    end
  end

  def pbCommandPhaseLoop(isPlayer)
    @scene.updateTurnCountReminder($catching_minigame.turnsLeft)
    $catching_minigame.spendTurn() if isPlayer
    super(isPlayer)
  end

  def pbEndOfRoundPhase
    super
    if $catching_minigame.turnsLeft == 0
      @decision = 3
    else
      @scene.updateTurnCountReminder($catching_minigame.turnsLeft)
    end
  end

  def pbEndOfBattle
    @scene.updateTurnCountReminder($catching_minigame.turnsLeft)
    super
    if $catching_minigame.turnsLeft == 0
      pbMessage(_INTL("You've run out of turns!"))
      @decision = 3
    else
      #pbMessage(_INTL("You have #{$catching_minigame.turnsLeft} turns left in the contest."))
    end
  end
end

def pbCatchingMinigameWildBattle(species, level, outcomeVar=1, canRun=true, canLose=false)
    species = GameData::Species.get(species).id
    # Potentially call a different pbWildBattle-type method instead (for roaming
    # Pokémon, Safari battles, Bug Contest battles)
    handled = [nil]
    Events.onWildBattleOverride.trigger(nil,species,level,handled)
    return handled[0] if handled[0]!=nil
    # Set some battle rules
    setBattleRule("outcomeVar",outcomeVar) if outcomeVar!=1
    setBattleRule("cannotRun") if !canRun
    setBattleRule("canLose") if canLose
    # Perform the battle
    decision = pbCatchingMinigameWildBattleCore(species, level)
    # Used by the Poké Radar to update/break the chain
    Events.onWildBattleEnd.trigger(nil,species,level,decision)
    $catching_minigame.endIfNeeded()
    # Return false if the player lost or drew the battle, and true if any other result
    return (decision!=2 && decision!=5)
  end
  
  def pbCatchingMinigameDoubleWildBattle(species1, level1, species2, level2,
                         outcomeVar=1, canRun=true, canLose=false)
    # Set some battle rules
    setBattleRule("outcomeVar",outcomeVar) if outcomeVar!=1
    setBattleRule("cannotRun") if !canRun
    setBattleRule("canLose") if canLose
    setBattleRule("double")
    # Perform the battle
    decision = pbCatchingMinigameWildBattleCore(species1, level1, species2, level2)
    $catching_minigame.endIfNeeded()
    # Return false if the player lost or drew the battle, and true if any other result
    return (decision!=2 && decision!=5)
  end

def pbCatchingMinigameWildBattleCore(*args)
    outcomeVar = $PokemonTemp.battleRules["outcomeVar"] || 1
    canLose    = $PokemonTemp.battleRules["canLose"] || false
    # Skip battle if the player has no able Pokémon, or if holding Ctrl in Debug mode
    if $Trainer.able_pokemon_count == 0 || debugControl
      pbMessage(_INTL("SKIPPING BATTLE...")) if $Trainer.pokemon_count > 0
      pbSet(outcomeVar,1)   # Treat it as a win
      $PokemonTemp.clearBattleRules
      $PokemonGlobal.nextBattleBGM       = nil
      $PokemonGlobal.nextBattleME        = nil
      $PokemonGlobal.nextBattleCaptureME = nil
      $PokemonGlobal.nextBattleBack      = nil
      pbMEStop
      return 1   # Treat it as a win
    end
    # Record information about party Pokémon to be used at the end of battle (e.g.
    # comparing levels for an evolution check)
    Events.onStartBattle.trigger(nil)
    # Generate wild Pokémon based on the species and level
    foeParty = []
    sp = nil
    for arg in args
      if arg.is_a?(Pokemon)
        foeParty.push(arg)
      elsif arg.is_a?(Array)
        species = GameData::Species.get(arg[0]).id
        pkmn = pbGenerateWildPokemon(species,arg[1])
        foeParty.push(pkmn)
      elsif sp
        species = GameData::Species.get(sp).id
        pkmn = pbGenerateWildPokemon(species,arg)
        foeParty.push(pkmn)
        sp = nil
      else
        sp = arg
      end
    end
    raise _INTL("Expected a level after being given {1}, but one wasn't found.",sp) if sp
    # Calculate who the trainers and their party are
    playerTrainers    = [$Trainer]
    playerParty       = $Trainer.party
    playerPartyStarts = [0]
    room_for_partner = (foeParty.length > 1)
    if !room_for_partner && $PokemonTemp.battleRules["size"] &&
       !["single", "1v1", "1v2", "1v3"].include?($PokemonTemp.battleRules["size"])
      room_for_partner = true
    end
    loadPartnerTrainer(playerTrainers, playerParty, playerPartyStarts)
    # Create the battle scene (the visual side of it)
    scene = pbNewBattleScene
    # Create the battle class (the mechanics side of it)
    echoln("Starting a catching minigame battle!")
    battle = CatchingMinigameBattle.new(scene,playerParty,foeParty,playerTrainers,nil)
    battle.party1starts = playerPartyStarts
    # Set various other properties in the battle class
    pbPrepareBattle(battle)
    $PokemonTemp.clearBattleRules
    # Perform the battle itself
    decision = 0
    pbBattleAnimation(pbGetWildBattleBGM(foeParty),(foeParty.length==1) ? 0 : 2,foeParty) {
      pbSceneStandby {
        decision = battle.pbStartBattle
      }
      pbAfterBattle(decision,canLose)
    }
    Input.update
    # Save the result of the battle in a Game Variable (1 by default)
    #    0 - Undecided or aborted
    #    1 - Player won
    #    2 - Player lost
    #    3 - Player or wild Pokémon ran from battle, or player forfeited the match
    #    4 - Wild Pokémon was caught
    #    5 - Draw
    pbSet(outcomeVar,decision)
    return decision
end

Events.onStepTaken += proc {
    next unless $catching_minigame.active?
    pbStepTakenCatchingContest($PokemonGlobal.repel > 0)
}

def pbStepTakenCatchingContest(repel_active)
    return if $Trainer.able_pokemon_count == 0
    return if !$PokemonEncounters.encounter_possible_here?
    encounter_type = $PokemonEncounters.encounter_type
    return if !encounter_type
    return if !$PokemonEncounters.encounter_triggered?(encounter_type, repel_active)
    $PokemonTemp.encounterType = encounter_type
    encounter = $PokemonEncounters.choose_wild_pokemon(encounter_type)
    encounter = EncounterModifier.trigger(encounter)
    if $PokemonEncounters.have_double_wild_battle?
        encounter2 = $PokemonEncounters.choose_wild_pokemon(encounter_type)
        encounter2 = EncounterModifier.trigger(encounter2)
        pbCatchingMinigameDoubleWildBattle(encounter[0], encounter[1], encounter2[0], encounter2[1])
    else
        pbCatchingMinigameWildBattle(encounter[0], encounter[1])
    end
    $PokemonTemp.encounterType = nil
    $PokemonTemp.encounterTriggered = true
    $PokemonTemp.forceSingleBattle = false
    EncounterModifier.triggerEncounterEnd
end

def hearAboutCatchingMinigameHighScore
  pbMessage(_INTL("It was a {1}, right? At level {2}?",$catching_minigame.highScorePokemonSpeciesName,$catching_minigame.highScorePokemonLevel))
  score = $catching_minigame.highScore
  if score > 60
    pbMessage(_INTL("That one earned you a whoppin' {1} points.",score))
  else
    pbMessage(_INTL("That one earned you {1} points.",score))
  end
  if $catching_minigame.highScorePokemonSpeciesName == "Lugia"
    pbMessage(_INTL("..."))
    pbMessage(_INTL("What?! You reeled in the legendary king of the ocean?!"))
    pbMessage(_INTL("I don't know what t'say..."))
  else
    if score < 40
      pbMessage(_INTL("I'm sure you can do better if ya give it another shot!"))
    elsif score > 70
      pbMessage(_INTL("That's rather well done, there!"))
    end
  end
end

def hazardPokemonTrigger
    get_self.move_to_original
    $PokemonTemp.forceSingleBattle
    pbCatchingMinigameWildBattle(:WINGULL,10)
end