class PokeBattle_Battler
  #=============================================================================
  # Decide whether the trainer is allowed to tell the Pokémon to use the given
  # move. Called when choosing a command for the round.
  # Also called when processing the Pokémon's action, because these effects also
  # prevent Pokémon action. Relevant because these effects can become active
  # earlier in the same round (after choosing the command but before using the
  # move) or an unusable move may be called by another move such as Metronome.
  #=============================================================================
  def pbCanChooseMove?(move,commandPhase,showMessages=true,specialUsage=false)
    # Disable
    if @effects[PBEffects::DisableMove]==move.id && !specialUsage
      if showMessages
        msg = _INTL("{1}'s {2} is disabled!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Heal Block
    if @effects[PBEffects::HealBlock]>0 && move.healingMove?
      if showMessages
        msg = _INTL("{1} can't use {2} because of Heal Block!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Gravity
    if @battle.field.effects[PBEffects::Gravity]>0 && move.unusableInGravity?
      if showMessages
        msg = _INTL("{1} can't use {2} because of gravity!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Throat Chop
    if @effects[PBEffects::ThroatChop]>0 && move.soundMove?
      if showMessages
        msg = _INTL("{1} can't use {2} because of Throat Chop!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Choice Items
    if @effects[PBEffects::ChoiceBand]
      if hasActiveItem?([:CHOICEBAND,:CHOICESPECS,:CHOICESCARF]) &&
         pbHasMove?(@effects[PBEffects::ChoiceBand])
        if move.id != @effects[PBEffects::ChoiceBand] && move.id != :STRUGGLE
          if showMessages
            msg = _INTL("{1} allows the use of only {2}!",itemName,
               GameData::Move.get(@effects[PBEffects::ChoiceBand]).name)
            (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
          end
          return false
        end
      else
        @effects[PBEffects::ChoiceBand] = nil
      end
    end
	  # Gorilla Tactics
    if @effects[PBEffects::GorillaTactics]
      if hasActiveAbility?(:GORILLATACTICS)
        if move.id != @effects[PBEffects::GorillaTactics]
          if showMessages
            msg = _INTL("{1} allows the use of only {2}!",abilityName,GameData::Move.get(@effects[PBEffects::GorillaTactics]).name)
            (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
          end
          return false
        end
      else
        @effects[PBEffects::GorillaTactics] = nil
      end
    end
    # Taunt
    if @effects[PBEffects::Taunt]>0 && move.statusMove?
      if showMessages
        msg = _INTL("{1} can't use {2} after the taunt!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Torment
    if @effects[PBEffects::Torment] && !@effects[PBEffects::Instructed] &&
       @lastMoveUsed && move.id==@lastMoveUsed && move.id!=@battle.struggle.id
      if showMessages
        msg = _INTL("{1} can't use the same move twice in a row due to the torment!",pbThis)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Imprison
    @battle.eachOtherSideBattler(@index) do |b|
      next if !b.effects[PBEffects::Imprison] || !b.pbHasMove?(move.id)
      if showMessages
        msg = _INTL("{1} can't use its sealed {2}!",pbThis,move.name)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Assault Vest and Strike Vest (prevents choosing status moves but doesn't prevent
    # executing them)
    if (hasActiveItem?(:ASSAULTVEST) || hasActiveItem?(:STRIKEVEST)) && move.statusMove? && commandPhase
      if showMessages
        msg = _INTL("The effects of the {1} prevent status moves from being used!",
           itemName)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    # Belch
    return false if !move.pbCanChooseMove?(self,commandPhase,showMessages)
    return true
  end
  
  #=============================================================================
  # Obedience check
  #=============================================================================
  # Return true if Pokémon continues attacking (although it may have chosen to
  # use a different move in disobedience), or false if attack stops.
  def pbObedienceCheck?(choice)
    return true
  end

  #=============================================================================
  # Check whether the user (self) is able to take action at all.
  # If this returns true, and if PP isn't a problem, the move will be considered
  # to have been used (even if it then fails for whatever reason).
  #=============================================================================
  def pbTryUseMove(choice,move,specialUsage,skipAccuracyCheck)
	  return true if move.isEmpowered?
    # Check whether it's possible for self to use the given move
    # NOTE: Encore has already changed the move being used, no need to have a
    #       check for it here.
    if !pbCanChooseMove?(move,false,true,specialUsage)
      @lastMoveFailed = true
      return false
    end
    # Check whether it's possible for self to do anything at all
    if @effects[PBEffects::SkyDrop]>=0   # Intentionally no message here
      PBDebug.log("[Move failed] #{pbThis} can't use #{move.name} because of being Sky Dropped")
      return false
    end
    if @effects[PBEffects::HyperBeam]>0   # Intentionally before Truant
      @battle.pbDisplay(_INTL("{1} must recharge!",pbThis))
      return false
    end
    if choice[1]==-2   # Battle Palace
      @battle.pbDisplay(_INTL("{1} appears incapable of using its power!",pbThis))
      return false
    end
    # Skip checking all applied effects that could make self fail doing something
    return true if skipAccuracyCheck
    # Check status problems and continue their effects/cure them
    if pbHasStatus?(:SLEEP)
      reduceStatusCount(:SLEEP)
      if getStatusCount(:SLEEP)<=0
        pbCureStatus(true,:SLEEP)
      else
        pbContinueStatus(:SLEEP)
        if !move.usableWhenAsleep?   # Snore/Sleep Talk
          @lastMoveFailed = true
          return false
        end
      end
	  end
    # Obedience check
    return false if !pbObedienceCheck?(choice)
    # Truant
    if hasActiveAbility?(:TRUANT)
      @effects[PBEffects::Truant] = !@effects[PBEffects::Truant]
      if !@effects[PBEffects::Truant] && move.id != :SLACKOFF   # True means loafing, but was just inverted
        @battle.pbShowAbilitySplash(self)
        @battle.pbDisplay(_INTL("{1} is loafing around!",pbThis))
        @lastMoveFailed = true
        @battle.pbHideAbilitySplash(self)
        return false
      end
    end
    # Flinching
    if @effects[PBEffects::Flinch]
      if @effects[PBEffects::FlinchedAlready]
        @battle.pbDisplay("#{pbThis} shrugged off their fear and didn't flinch!")
        @effects[PBEffects::Flinch] = false
      else
        @battle.pbDisplay(_INTL("{1} flinched and couldn't move!",pbThis))
        if abilityActive?
          BattleHandlers.triggerAbilityOnFlinch(@ability,self,@battle)
        end
        @lastMoveFailed = true
        @effects[PBEffects::FlinchedAlready] = true
        return false
      end
    end
    # Confusion
    if @effects[PBEffects::Confusion]>0
      @effects[PBEffects::Confusion] -= 1
      if @effects[PBEffects::Confusion]<=0
        pbCureConfusion
        @battle.pbDisplay(_INTL("{1} snapped out of its confusion.",pbThis))
      else
        @battle.pbCommonAnimation("Confusion",self)
        @battle.pbDisplay(_INTL("{1} is confused!",pbThis))
        threshold = 50 + 50 * @effects[PBEffects::ConfusionChance]
        if (@battle.pbRandom(100)<threshold && !hasActiveAbility?([:HEADACHE,:TANGLEDFEET])) || ($DEBUG && Input.press?(Input::CTRL))
          @effects[PBEffects::ConfusionChance] = 0
          superEff = @battle.pbCheckOpposingAbility(:BRAINSCRAMBLE,@index)
          pbConfusionDamage(_INTL("It hurt itself in its confusion!"),false,superEff)
		      @effects[PBEffects::ConfusionChance] = -999
          @lastMoveFailed = true
          return false
        else
          @effects[PBEffects::ConfusionChance] += 1
        end
      end
    end
	  # Charm
    if @effects[PBEffects::Charm]>0
      @effects[PBEffects::Charm] -= 1
      if @effects[PBEffects::Charm]<=0
        pbCureCharm
        @battle.pbDisplay(_INTL("{1} was released from the charm.",pbThis))
      else
        @battle.pbAnimation(:LUCKYCHANT,self,nil)
        @battle.pbDisplay(_INTL("{1} is charmed!",pbThis))
        threshold = 50 + 50 * @effects[PBEffects::CharmChance]
        if (@battle.pbRandom(100)<threshold && !hasActiveAbility?([:HEADACHE,:TANGLEDFEET])) || ($DEBUG && Input.press?(Input::CTRL))
          @effects[PBEffects::CharmChance] = 0
          superEff = @battle.pbCheckOpposingAbility(:BRAINSCRAMBLE,@index)
          pbConfusionDamage(_INTL("It's energy went wild due to the charm!"),true,superEff)
		      @effects[PBEffects::CharmChance] = -999
          @lastMoveFailed = true
          return false
        else
          @effects[PBEffects::CharmChance] += 1
        end
      end
    end
=begin
    # Paralysis
    if pbHasStatus?(:PARALYSIS) && (!boss || @battle.commandPhasesThisRound == 0)
      if @battle.pbRandom(100)<25
        pbContinueStatus(:PARALYSIS)
        @lastMoveFailed = true
        return false
      end
    end
=end
    # Infatuation
    if @effects[PBEffects::Attract]>=0
      @battle.pbCommonAnimation("Attract",self)
      @battle.pbDisplay(_INTL("{1} is in love with {2}!",pbThis,
         @battle.battlers[@effects[PBEffects::Attract]].pbThis(true)))
      if @battle.pbRandom(100)<50
        @battle.pbDisplay(_INTL("{1} is immobilized by love!",pbThis))
        @lastMoveFailed = true
        return false
      end
    end
    return true
  end
  
  #=============================================================================
  # Initial success check against the target. Done once before the first hit.
  # Includes move-specific failure conditions, protections and type immunities.
  #=============================================================================
  def pbSuccessCheckAgainstTarget(move,user,target)
	  # Unseen Fist
    protectionIgnoredByAbility = false
    protectionIgnoredByAbility = true if user.ability == :UNSEENFIST && move.contactMove?
    protectionIgnoredByAbility = true if user.ability == :AQUASNEAK && user.turnCount <= 1
    typeMod = move.pbCalcTypeMod(move.calcType,user,target)
    target.damageState.typeMod = typeMod
    # Two-turn attacks can't fail here in the charging turn
    return true if user.effects[PBEffects::TwoTurnAttack]
    # Move-specific failures
    return false if move.pbFailsAgainstTarget?(user,target)
    # Immunity to priority moves because of Psychic Terrain
    if @battle.field.terrain == :Psychic && target.affectedByTerrain? && target.opposes?(user) &&
       @battle.choices[user.index][4] > 0   # Move priority saved from pbCalculatePriority
      @battle.pbDisplay(_INTL("{1} surrounds itself with psychic terrain!",target.pbThis))
      return false
    end
    # Crafty Shield
    if target.pbOwnSide.effects[PBEffects::CraftyShield] && user.index != target.index && 
        move.statusMove? && !move.pbTarget(user).targets_all && !protectionIgnoredByAbility
      @battle.pbCommonAnimation("CraftyShield",target)
      @battle.pbDisplay(_INTL("Crafty Shield protected {1}!",target.pbThis(true)))
      target.damageState.protected = true
      @battle.successStates[user.index].protected = true
      return false
    end
    # Wide Guard
    if target.pbOwnSide.effects[PBEffects::WideGuard] && user.index!=target.index &&
       move.pbTarget(user).num_targets > 1 && !move.smartSpreadsTargets? &&
       (Settings::MECHANICS_GENERATION >= 7 || move.damagingMove?) && !protectionIgnoredByAbility
      @battle.pbCommonAnimation("WideGuard",target)
      @battle.pbDisplay(_INTL("Wide Guard protected {1}!",target.pbThis(true)))
      target.damageState.protected = true
      @battle.successStates[user.index].protected = true
      return false
    end	
    ######################################################
    #	Protect Style Moves
    ######################################################
    # Quick Guard
    if target.pbOwnSide.effects[PBEffects::QuickGuard] && @battle.choices[user.index][4]>0   # Move priority saved from pbCalculatePriority
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("QuickGuard",target)
        @battle.pbDisplay(_INTL("Quick Guard protected {1}!",target.pbThis(true)))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("Quick Guard was ignored, and failed to protect {1}!",target.pbThis(true)))
      end
    end
    # Protect
    if target.effects[PBEffects::Protect]
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("Protect",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s Protect was ignored!",target.pbThis))
      end
    end
    # Obstruct
    if target.effects[PBEffects::Obstruct]
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("Obstruct",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          if user.pbCanLowerStatStage?(:DEFENSE)
          user.pbLowerStatStage(:DEFENSE,2,nil)
          end
        end
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s Obstruct was ignored!",target.pbThis))
      end
    end
    # King's Shield
    if target.effects[PBEffects::KingsShield] && move.damagingMove?
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("KingsShield",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          if user.pbCanLowerStatStage?(:ATTACK)
          user.pbLowerStatStage(:ATTACK,1,nil)
          end
        end
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s King's Shield was ignored!",target.pbThis))
      end
    end
    # Spiky Shield
    if target.effects[PBEffects::SpikyShield]
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("SpikyShield",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.pbContactMove?(user) && user.affectedByContactEffect?
          reduction = user.totalhp/8
          reduction /= 4 if user.boss?
          reduction = reduction.floor
          user.damageState.displayedDamage = reduction
          @battle.scene.pbDamageAnimation(user)
          user.pbReduceHP(reduction,false)
          @battle.pbDisplay(_INTL("{1} was hurt!",user.pbThis))
          user.pbItemHPHealCheck
        end
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s Spiky Shield was ignored!",target.pbThis))
      end
    end
    # Baneful Bunker
    if target.effects[PBEffects::BanefulBunker]
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("BanefulBunker",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.physicalMove?
          user.pbPoison(target) if user.pbCanPoison?(target,false)
        end
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s Baneful Bunker was ignored!",target.pbThis))
      end
    end
    # Baneful Bunker
    if target.effects[PBEffects::RedHotRetreat]
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        @battle.pbCommonAnimation("RedHotRetreat",target)
        @battle.pbDisplay(_INTL("{1} protected itself!",target.pbThis))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        if move.specialMove?
          user.pbBurn(target) if user.pbCanBurn?(target,false)
        end
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("{1}'s Red Hot Retreat was ignored!",target.pbThis))
      end
    end
    # Mat Block
    if target.pbOwnSide.effects[PBEffects::MatBlock] && move.damagingMove?
      if move.canProtectAgainst? && !protectionIgnoredByAbility
        # NOTE: Confirmed no common animation for this effect.
        @battle.pbDisplay(_INTL("{1} was blocked by the kicked-up mat!",move.name))
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      elsif move.pbTarget(user).targets_foe
        @battle.pbDisplay(_INTL("Mat Block was ignored, and failed to protect {1}!",target.pbThis(true)))
      end
    end
    # Magic Coat/Magic Bounce/Magic Shield
    if move.canMagicCoat? && !target.semiInvulnerable? && target.opposes?(user)
      if target.effects[PBEffects::MagicCoat]
        target.damageState.magicCoat = true
        target.effects[PBEffects::MagicCoat] = false
        return false
      end
      if target.hasActiveAbility?(:MAGICBOUNCE) && !@battle.moldBreaker #&& !target.effects[PBEffects::MagicBounce]
        target.damageState.magicBounce = true
        target.effects[PBEffects::MagicBounce] = true
        return false
      end
      if target.hasActiveAbility?(:MAGICSHIELD) && !@battle.moldBreaker
        @battle.pbShowAbilitySplash(target)
        target.damageState.protected = true
        @battle.pbDisplay(_INTL("{1} shielded itself from the {2}!",target.pbThis,move.name))
        @battle.pbHideAbilitySplash(target)
       return false
     end
    end
    # Move fails due to type immunity ability (Except against or by a boss)
    if !user.boss? && !target.boss
      if move.pbImmunityByAbility(user,target) 
        triggerImmunityDialogue(target,true)
        return false
      end
    end
    # Type immunity
    if move.damagingMove? && Effectiveness.ineffective?(typeMod)
      PBDebug.log("[Target immune] #{target.pbThis}'s type immunity")
      if !@battle.bossBattle?
        @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
        triggerImmunityDialogue(target,false)
        return false
      else
        @battle.pbDisplay(_INTL("Within the avatar's aura, immunities are resistances!"))
      end
    end
    # Dark-type immunity to moves made faster by Prankster
    if Settings::MECHANICS_GENERATION >= 7 && user.effects[PBEffects::Prankster] &&
       target.pbHasType?(:DARK) && target.opposes?(user)
      PBDebug.log("[Target immune] #{target.pbThis} is Dark-type and immune to Prankster-boosted moves")
      @battle.pbDisplay(_INTL("The Prankster-boosted move doesn't affect {1} due to its Dark typing...",target.pbThis(true)))
      triggerImmunityDialogue(target,false)
      return false
    end
    # Airborne-based immunity to Ground moves
    if move.damagingMove? && move.calcType == :GROUND && target.airborne? && !move.hitsFlyingTargets?
      if target.hasLevitate? && !@battle.moldBreaker
        @battle.pbShowAbilitySplash(target)
        if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis))
        else
          @battle.pbDisplay(_INTL("{1} avoided the attack with {2}!",target.pbThis,target.abilityName))
        end
        @battle.pbHideAbilitySplash(target)
        triggerImmunityDialogue(target,true)
        return false unless @battle.bossBattle? # In boss battles, it just reduced damage by half (calced later)
      end
      if target.hasActiveItem?(:AIRBALLOON)
        @battle.pbDisplay(_INTL("{1}'s {2} makes Ground moves miss!",target.pbThis,target.itemName))
        triggerImmunityDialogue(target,false)
        return false
      end
      if target.effects[PBEffects::MagnetRise]>0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Magnet Rise!",target.pbThis))
        triggerImmunityDialogue(target,false)
        return false
      end
      if target.effects[PBEffects::Telekinesis]>0
        @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Telekinesis!",target.pbThis))
        triggerImmunityDialogue(target,false)
        return false
      end
    end
    # Immunity to powder-based moves
    if move.powderMove?
      if target.pbHasType?(:GRASS) && Settings::MORE_TYPE_EFFECTS
        PBDebug.log("[Target immune] #{target.pbThis} is Grass-type and immune to powder-based moves")
        @battle.pbDisplay(_INTL("It doesn't affect {1} because of its Grass typing...",target.pbThis(true)))
        triggerImmunityDialogue(target,false)
        return false
      end
      if Settings::MECHANICS_GENERATION >= 6
        if target.hasActiveAbility?(:OVERCOAT) && !@battle.moldBreaker
          @battle.pbShowAbilitySplash(target)
          if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
          else
            @battle.pbDisplay(_INTL("It doesn't affect {1} because of its {2}.",target.pbThis(true),target.abilityName))
          end
          @battle.pbHideAbilitySplash(target)
          triggerImmunityDialogue(target,false)
          return false
        end
        if target.hasActiveItem?(:SAFETYGOGGLES)
          PBDebug.log("[Item triggered] #{target.pbThis} has Safety Goggles and is immune to powder-based moves")
          @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
          triggerImmunityDialogue(target,false)
          return false
        end
      end
    end
    # Substitute
    if target.effects[PBEffects::Substitute]>0 && move.statusMove? &&
       !move.ignoresSubstitute?(user) && user.index!=target.index
      PBDebug.log("[Target immune] #{target.pbThis} is protected by its Substitute")
      @battle.pbDisplay(_INTL("{1} avoided the attack!",target.pbThis(true)))
      return false
    end
    return true
  end

  def triggerImmunityDialogue(target,isImmunityAbility)
    if !battle.wildBattle?
      if @battle.pbOwnedByPlayer?(target.index)
        # Trigger each opponent's dialogue
        @battle.opponent.each_with_index do |trainer_speaking,idxTrainer|
          @battle.scene.showTrainerDialogue(idxTrainer) { |policy,dialogue|
            trainer = @battle.opponent[idxTrainer]
            PokeBattle_AI.triggerPlayerPokemonImmuneDialogue(policy,self,target,isImmunityAbility,trainer_speaking,dialogue)
          }
        end
      else
        # Trigger just this pokemon's trainer's dialogue
        idxTrainer = @battle.pbGetOwnerIndexFromBattlerIndex(index)
        trainer_speaking = @battle.opponent[idxTrainer]
        @battle.scene.showTrainerDialogue(idxTrainer) { |policy,dialogue|
          PokeBattle_AI.triggerTrainerPokemonImmuneDialogue(policy,self,target,isImmunityAbility,trainer_speaking,dialogue)
        }
      end
    end
  end
end