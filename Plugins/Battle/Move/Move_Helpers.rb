class PokeBattle_Move
  def applyRainDebuff?(user,type,checkingForAI=false)
    return false if ![:Rain, :HeavyRain].include?(@battle.field.weather)
    return false if !RAIN_DEBUFF_ACTIVE
    return false if immuneToRainDebuff?()
    return false if [:Water,:Electric].include?(type)
    return user.debuffedByRain?(checkingForAI)
  end

  def applySunDebuff?(user,type,checkingForAI=false)
    return false if ![:Sun, :HarshSun].include?(@battle.field.weather)
    return false if !SUN_DEBUFF_ACTIVE
    return false if immuneToSunDebuff?()
    return false if [:Fire,:Grass].include?(type)
    return user.debuffedBySun?(checkingForAI)
  end
  
  def inherentImmunitiesPierced?(user,target)
    return (user.boss? || target.boss?) && damagingMove?
  end

  def canRemoveItem?(user,target,checkingForAI=false)
      return false if @battle.wildBattle? && user.opposes? && !user.boss   # Wild Pokémon can't knock off, but bosses can
      return false if user.fainted?
      if checkingForAI
          return false if target.substituted?
      else
          return false if target.damageState.unaffected || target.damageState.substitute
      end
      return false if !target.item || target.unlosableItem?(target.item)
      return false if target.shouldAbilityApply?(:STICKYHOLD,checkingForAI) && !@battle.moldBreaker
      return true
  end

  def canStealItem?(user,target,checkingForAI=false)
      return false if !canRemoveItem?(user,target)
      return false if user.item && @battle.trainerBattle?
      return false if user.unlosableItem?(target.item)
      return true
  end

  def healStatus(pokemonOrBattler)
    if pokemonOrBattler.is_a?(PokeBattle_Battler)
      pokemonOrBattler.pbCureStatus
    elsif pokemonOrBattler.status != :NONE
      oldStatus = pokemonOrBattler.status
      pokemonOrBattler.status      = :NONE
      pokemonOrBattler.statusCount = 0
      PokeBattle_Battler.showStatusCureMessage(oldStatus,pokemonOrBattler,@battle)
    end
  end

  def selectPartyMemberForEffect(idxBattler,selectableProc=nil)
    if @battle.pbOwnedByPlayer?(idxBattler)
      return playerChoosesPartyMemberForEffect(idxBattler,selectableProc)
    else
      return trainerChoosesPartyMemberForEffect(idxBattler,selectableProc)
    end
  end

  def playerChoosesPartyMemberForEffect(idxBattler,selectableProc=nil)
    # Get player's party
    party    = @battle.pbParty(idxBattler)
    partyOrder = @battle.pbPartyOrder(idxBattler)
    partyStart = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)[0]
    modParty = @battle.pbPlayerDisplayParty(idxBattler)
    # Start party screen
    pkmnScene = PokemonParty_Scene.new
    pkmnScreen = PokemonPartyScreen.new(pkmnScene,modParty)
    displayPartyIndex = -1
    # Loop while in party screen
    loop do
      # Select a Pokémon by showing the screen
      displayPartyIndex = pkmnScreen.pbChooseAblePokemon(selectableProc)
      next if displayPartyIndex < 0

      # Find the real party index after accounting for shifting around from swaps
      partyIndex = -1
      partyOrder.each_with_index do |pos,i|
        next if pos != displayPartyIndex + partyStart
        partyIndex = i
        break
      end
      next if partyIndex < 0

      # Make sure the selected pokemon isn't an active battler
      next if @battle.pbFindBattler(partyIndex,idxBattler)

      # Get the actual pokemon selection
      pkmn = party[partyIndex]

      # Don't allow invalid choices
      next if !pkmn || pkmn.egg?

      pkmnScene.pbEndScene
      return pkmn
    end
    pkmnScene.pbEndScene
    return nil
  end

  def trainerChoosesPartyMemberForEffect(idxBattler,selectableProc=nil)
    # Get trainer's party
    party = @battle.pbParty(idxBattler)
    party.each_with_index do |pokemon,partyIndex|
      # Don't allow invalid choices
      next if !pokemon || pokemon.egg?

      # Make sure the selected pokemon isn't an active battler
      next if @battle.pbFindBattler(partyIndex,idxBattler)

      return pokemon if selectableProc.call(pokemon)
    end
    return nil
  end

  def removeProtections(target)	
    GameData::BattleEffect.each do |effectData|
      next if !effectData.is_protection?
      case effectData.location
      when :Battler
        target.disableEffect(effectData.id)
      when :Side
        target.pbOwnSide.disableEffect(effectData.id)
      end
    end
  end 
end