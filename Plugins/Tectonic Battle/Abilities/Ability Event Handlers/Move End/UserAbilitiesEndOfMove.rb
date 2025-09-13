########################################################################
# Foe faint abilities
########################################################################

BattleHandlers::UserAbilityEndOfMove.add(:MOXIE,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.tryRaiseStat(:ATTACK, user, increment: numFainted, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:HUBRIS,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.tryRaiseStat(:SPECIAL_ATTACK, user, increment: numFainted, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.copy(:MOXIE, :CHILLINGNEIGH)

BattleHandlers::UserAbilityEndOfMove.copy(:HUBRIS, :GRIMNEIGH)

BattleHandlers::UserAbilityEndOfMove.add(:FOLLOWTHROUGH,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.tryRaiseStat(:SPEED, user, increment: numFainted * 2, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:OUTRIDER,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.pbRaiseMultipleStatSteps([:ATTACK, numFainted, :SPEED, numFainted], user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:OVERCHARGE,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.pbRaiseMultipleStatSteps([:SPECIAL_ATTACK, numFainted, :SPEED, numFainted], user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:DOMINATING,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.pbRaiseMultipleStatSteps([:ATTACK, numFainted, :DEFENSE, numFainted], user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:WISEHUNTER,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.pbRaiseMultipleStatSteps([:SPECIAL_ATTACK, numFainted, :SPECIAL_DEFENSE, numFainted], user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:CITYRAZER,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next unless user.species == :GYARADOS
      next unless user.form == 0
      next unless move.id == :WATERFALL
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      battle.pbShowAbilitySplash(user, ability)
      user.pbChangeForm(1, _INTL("{1}'s anger cannot be sated! It enters its Rampage form!", user.pbThis))
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:VICTORYMOLT,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      next unless user.pbHasAnyStatus? || user.hasAlteredStatSteps?
      battle.pbShowAbilitySplash(user, ability)
      user.pbChangeForm(1, _INTL("{1} molts into a new shell!", user.pbThis))
      battle.pbAnimation(:REFRESH, user, nil)
      user.pbCureStatus(true)
      if user.hasAlteredStatSteps?
          battle.pbDisplay(_INTL("{1}'s stat changes were removed!", user.pbThis))
          user.pbResetStatSteps
      end
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:JOYOUSSORROW,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      battle.forceUseMove(user, :WISH, user.index, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:BEASTBOOST,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      userStats = user.plainStats
      highestStatValue = 0
      userStats.each_value { |value| highestStatValue = value if highestStatValue < value }
      GameData::Stat.each_main_battle do |s|
          next if userStats[s.id] < highestStatValue
          stat = s.id
          user.tryRaiseStat(stat, user, increment: numFainted, ability: ability)
          break
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:ASONEICE,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0 || !user.pbCanRaiseStatStep?(:ATTACK, user) || user.fainted?
      battle.pbShowAbilitySplash(user, :CHILLINGNEIGH)
      user.pbRaiseStatStep(:ATTACK, numFainted, user)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:ASONEGHOST,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0 || !user.pbCanRaiseStatStep?(:ATTACK, user) || user.fainted?
      battle.pbShowAbilitySplash(user, :GRIMNEIGH)
      user.pbRaiseStatStep(:SPECIAL_ATTACK, numFainted, user)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:RECLAMATION,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      next unless user.recyclableItem
      next if user.hasItem?(user.recyclableItem)
      recyclingMsg = _INTL("{1} reclaims its {2}!", user.pbThis, getItemName(user.recyclableItem))
      user.recycleItem(recyclingMsg: recyclingMsg, ability: ability)
  }
)

########################################################################
# Other abilities
########################################################################

BattleHandlers::UserAbilityEndOfMove.add(:MAGICIAN,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      targets.each do |b|
          b.eachItem do |item|
            move.stealItem(user, b, item)
          end
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:DEEPSTING,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next unless user.takesIndirectDamage?
      totalDamageDealt = 0
      targets.each do |target|
          next if target.damageState.unaffected
          totalDamageDealt = target.damageState.totalHPLost
      end
      next if totalDamageDealt <= 0
      amt = (totalDamageDealt / 4.0).round
      amt = 1 if amt < 1
      battle.pbShowAbilitySplash(user, ability)
      user.pbReduceHP(amt, false)
      battle.pbDisplay(_INTL("{1} is damaged by recoil!", user.pbThis))
      battle.pbHideAbilitySplash(user)
      user.pbItemHPHealCheck
      user.pbFaint if user.fainted?
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:GILD,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      targets.each do |b|
          next unless b.hasAnyItem?
          next unless move.knockOffItems(user, b, ability: ability) do |itemRemoved, itemName|
            battle.pbDisplay(_INTL("{1} turned {2}'s {3} into gold!", user.pbThis, b.pbThis(true), itemName))
            user.generateMoney(8)
          end
          break
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:SPACEINTERLOPER,
  proc { |ability, user, targets, _move, _battle|
    user.pbRecoverHPFromMultiDrain(targets, 0.25, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:SPARESCALES,
  proc { |ability, user, _targets, move, _battle, _switchedBattlers|
      next unless %i[GRASS GROUND STEEL].include?(move.calcType)
      healingMessage = _INTL("{1} gathered up material.", battler.pbThis)
      battler.applyFractionalHealing(1.0 / 5.0, ability: ability, customMessage: healingMessage, canOverheal: true)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:DAUNTLESS,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      user.pbRaiseMultipleStatSteps([:ATTACK, numFainted, :SPECIAL_ATTACK, numFainted], user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:POWERLIFTER,
  proc { |ability, user, targets, move, battle, switchedBattlers|
      next if battle.futureSight
      next unless move.physicalMove?
      move.forceOutTargets(user, targets, switchedBattlers, substituteBlocks: true, random: false, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:FLUSTERFLOCK,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      battle.pbShowAbilitySplash(user, ability)
      user.applyDizzy(user)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.copy(:FLUSTERFLOCK, :HEADACHE)

BattleHandlers::UserAbilityEndOfMove.add(:DYNAMO,
  proc { |ability, user, _targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next if move.damagingMove?
      next if user.effectActive?(:EnergyCharge)
      battle.pbShowAbilitySplash(user, ability)
      battle.pbAnimation(:CHARGE, user, nil, 0)
      user.applyEffect(:EnergyCharge)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:MIDNIGHTOIL,
  proc { |ability, user, _targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next if move.damagingMove?
      next unless battle.moonGlowing?
      battle.pbShowAbilitySplash(user, ability)
      battle.extendWeather(1)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:ICEQUEEN,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      next unless battle.icy?
      user.pbRecoverHPFromMultiDrain(targets, 0.50, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:ASTRALHARVEST,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      next unless battle.eclipsed?
      user.pbRecoverHPFromMultiDrain(targets, 0.50, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:SILVERSENSE,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      user.pbRecoverHPFromMultiDrain(targets, 0.50, ability: ability, onlyCriticalDamage: true)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:TORPORSAP,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      asleepTargets = []
      targets.each do |target|
        next unless target.asleep?
        asleepTargets.push(target)
      end
      next if asleepTargets.length == 0
      user.pbRecoverHPFromMultiDrain(asleepTargets, 0.50, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:VICIOUSCYCLE,
  proc { |ability, user, targets, move, battle, _switchedBattlers, aiCheck|
      next if battle.futureSight
      next unless move.damagingMove?
      next unless move.calcType == :DRAGON
      # AI learns ability if move spreads or drain happens
      user.aiLearnsAbility(ability) if ( !aiCheck && ( targets.size() > 1 || user.hp != user.totalhp) )
      user.pbRecoverHPFromMultiDrain(targets, 0.33, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:HORDETACTICS,
  proc { |ability, user, targets, move, battle, _switchedBattlers, aiCheck|
      next if battle.futureSight
      next unless move.damagingMove?
      next unless move.calcType == :NORMAL
      # AI learns ability if move spreads or drain happens
      user.aiLearnsAbility(ability) if ( !aiCheck && ( targets.size() > 1 || user.hp != user.totalhp) )
      user.pbRecoverHPFromMultiDrain(targets, 0.33, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:ETERNALWINTER,
  proc { |ability, user, targets, _move, battle, _switchedBattlers|
      next if battle.pbAllFainted?(user.idxOpposingSide)
      next unless battle.icy?
      numFainted = 0
      targets.each { |b| numFainted += 1 if b.damageState.fainted }
      next if numFainted == 0
      battle.pbShowAbilitySplash(user, ability)
      battle.extendWeather(numFainted * 2)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:COREPROVENANCE,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if move.damagingMove?
      next unless user.pbOwnSide.effectActive?(:ErodedRock)
      rockCount = user.pbOwnSide.countEffect(:ErodedRock)
      battle.pbShowAbilitySplash(user, ability)
      user.pbOwnSide.disableEffect(:ErodedRock)
      user.applyFractionalHealing(rockCount.to_f / 4.0)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:FEELTHEBURN,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      next if user.burned?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      battle.pbShowAbilitySplash(user, ability)
      user.applyBurn(user)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:COLDCALCULATION,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      next if user.frostbitten?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      battle.pbShowAbilitySplash(user, ability)
      user.applyFrostbite(user)
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:IRREFUTABLE,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      nveHits = 0
      targets.each do |b|
        next if b.damageState.unaffected
        next unless Effectiveness.not_very_effective?(b.damageState.typeMod)
        nveHits += 1
      end
      next unless nveHits > 0
      user.tryRaiseStat(:ATTACK, user, increment: nveHits * 2, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:OVERTHINKING,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.specialMove?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      user.tryLowerStat(:SPECIAL_ATTACK, user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:FUELHUNGRY,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.physicalMove?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      user.tryLowerStat(:ATTACK, user, ability: ability)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:SIRENSONG,
  proc { |ability, user, _targets, move, battle, _switchedBattlers|
      next unless move.soundMove?
      battle.pbShowAbilitySplash(user, ability)
      user.eachOpposing do |b|
        if b.pbAttack > b.pbSpAtk
          b.tryLowerStat(:ATTACK, user, increment: 1, showFailMsg: true)
        else
          b.tryLowerStat(:SPECIAL_ATTACK, user, increment: 1, showFailMsg: true)
        end
      end
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:BELLOWER,
  proc { |ability, user, _targets, move, battle, _switchedBattlers|
      next unless move.soundMove?
      battle.pbShowAbilitySplash(user, ability)
      user.eachOpposing do |b|
        b.applyEffect(:Torment)
      end
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:VANDAL,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      clothingItemProc = proc do |item|
        GameData::Item.get(item).is_clothing?
      end
      targets.each do |b|
        move.knockOffItems(user, b, ability: ability, validItemProc: clothingItemProc)
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:STUPEFYING,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      targets.each do |target|
        next unless target.knockedBelowHalf?
        target.applyDizzy(user) if target.canDizzy?(user, true)
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:FATIGUED,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      battle.forceUseMove(user, :REST)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:HYBRIDFIGHTER,
  proc { |ability, user, targets, move, battle, switchedBattlers|
      next if battle.futureSight
      next unless move.damagingMove?
      hitAnything = false
      targets.each do |b|
        next if b.damageState.unaffected
        hitAnything = true
        break
      end
      next unless hitAnything
      
      previousMoveID = user.moveUsageHistory[1] || nil
      currentMoveID = user.moveUsageHistory[0] || nil

      next if currentMoveID.nil?
      next if previousMoveID.nil?
      
      previousMoveData = battle.getBattleMoveInstanceFromID(previousMoveID)
      currentMoveData = battle.getBattleMoveInstanceFromID(currentMoveID)

      if previousMoveData.kickingMove? && currentMoveData.bitingMove?
        user.showMyAbilitySplash(ability)
        if user.fullHealth?
          battle.pbDisplay(_INTL("{1}'s HP is full!", user.pbThis))
        else
          user.applyFractionalHealing(1.0/4.0)
        end
        user.hideMyAbilitySplash
      elsif previousMoveData.punchingMove? && currentMoveData.kickingMove?
        user.showMyAbilitySplash(ability)
        move.switchOutUser(user,switchedBattlers)
        user.hideMyAbilitySplash
      elsif previousMoveData.bitingMove? && currentMoveData.punchingMove?
        targets.each do |target|
          target.pbLowerMultipleStatSteps(ATTACKING_STATS_2, user, ability: ability)
        end
      elsif previousMoveData.bitingMove? && currentMoveData.kickingMove?
        user.tryRaiseStat(:SPEED, user, increment: 2, ability: ability)
      elsif previousMoveData.kickingMove? && currentMoveData.punchingMove?
        user.showMyAbilitySplash(ability)
        targets.each do |target|
          target.applyNumb if target.canNumb?(user, true)
        end
        user.hideMyAbilitySplash
      elsif previousMoveData.punchingMove? && currentMoveData.bitingMove?
        user.showMyAbilitySplash(ability)
        if user.effectActive?(:EnergyCharge)
          battle.pbDisplay(_INTL("But {1} is already energized...", user.pbThis(true)))
        else
          battle.pbAnimation(:CHARGE, user, nil)
          user.applyEffect(:EnergyCharge)
        end
        user.hideMyAbilitySplash
      end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:OFFENSIVE,
  proc { |ability, user, targets, move, battle, switchedBattlers|
    next if battle.futureSight
    next unless move.damagingMove?
    next unless user.firstTurn?
    targets.each do |b|
      next if b.fainted?
      next if b.damageState.calcDamage == 0 || b.damageState.substitute
      b.pbFlinch
    end
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:BLINDING,
  proc { |ability, user, _targets, move, battle, _switchedBattlers|
      next unless move.lightMove?
      battle.pbShowAbilitySplash(user, ability)
      user.eachOpposing do |b|
        b.tryLowerStat(:SPECIAL_DEFENSE, user, increment: 1, showFailMsg: true)
      end
      battle.pbHideAbilitySplash(user)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:TANGLINGVINES,
  proc { |ability, user, targets, move, battle, _switchedBattlers|
    next unless move.damagingMove?
    targets.each do |b|
      next if b.fainted?
      if b.pointsAt?(:TanglingVines, user)
        b.disableEffect(:TanglingVines)
      end
    end
  }
)