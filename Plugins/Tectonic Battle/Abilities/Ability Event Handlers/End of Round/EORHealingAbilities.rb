BattleHandlers::EORHealingAbility.add(:SHEDSKIN,
    proc { |ability, battler, battle|
        hasAnyRelevantStatus = false
        GameData::Status.each do |s|
            next if s.id == :NONE
            next if s.id == :SLEEP
            next unless battler.hasStatusNoTrigger(s.id)
            hasAnyRelevantStatus = true
            break
        end
        next unless hasAnyRelevantStatus
        battle.pbShowAbilitySplash(battler, ability)
        GameData::Status.each do |s|
            next if s.id == :NONE
            next if s.id == :SLEEP
            battler.pbCureStatus(true, s.id)
        end
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::EORHealingAbility.add(:HYDRATION,
    proc { |ability, battler, battle|
        next unless battler.hasAnyStatusNoTrigger
        next unless battle.rainy?
        battle.pbShowAbilitySplash(battler, ability)
        battler.pbCureStatus
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::EORHealingAbility.add(:HEALER,
    proc { |ability, battler, battle|
        battler.eachAlly do |b|
            next unless b.hasAnyStatusNoTrigger
            battle.pbShowAbilitySplash(battler, ability)
            b.pbCureStatus
            battle.pbHideAbilitySplash(battler)
        end
    }
)

BattleHandlers::EORHealingAbility.add(:OXYGENATION,
    proc { |ability, battler, battle|
        next unless battler.hasAnyStatusNoTrigger
        next unless battle.sunny?
        battle.pbShowAbilitySplash(battler, ability)
        battler.pbCureStatus
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::EORHealingAbility.add(:VITALRHYTHM,
  proc { |ability, battler, battle|
      canHealAny = false
      battler.eachAlly do |b|
        canHealAny = true if b.canHeal?
      end
      canHealAny = true if battler.canHeal?
      next unless canHealAny
      battle.pbShowAbilitySplash(battler, ability)
      battler.applyFractionalHealing(1.0 / 16.0)
      battler.eachAlly do |b|
        b.applyFractionalHealing(1.0 / 16.0)
      end
      battle.pbHideAbilitySplash(battler)
    }
)

EOT_ABILITY_HEALING_FRACTION = 1.0 / 16.0

BattleHandlers::EORHealingAbility.add(:FIGHTINGVIGOR,
  proc { |ability, battler, _battle|
      battler.applyFractionalHealing(EOT_ABILITY_HEALING_FRACTION, ability: ability)
  }
)

BattleHandlers::EORHealingAbility.add(:GROTESQUEVITALS,
  proc { |ability, battler, _battle|
      battler.applyFractionalHealing(EOT_ABILITY_HEALING_FRACTION, ability: ability)
  }
)

BattleHandlers::EORHealingAbility.add(:LIVINGARMOR,
  proc { |ability, battler, battle|
      battler.applyFractionalHealing(1.0 / 12.0, ability: ability) unless battler.lastAttacker.empty?
  }
)

BattleHandlers::EORHealingAbility.add(:PRIMEVALREGENERATOR,
  proc { |ability, battler, _battle|
      battler.applyFractionalHealing(1.0 / 4.0, ability: ability)
  }
)

LIFELINE_HEALING_FRACTION = 1.0 / 20.0

BattleHandlers::EORHealingAbility.add(:LIFELINE,
  proc { |ability, battler, battle|
    healingAmount = battler.applyFractionalHealing(LIFELINE_HEALING_FRACTION, ability: ability)

    if healingAmount > 0
        potentialHeals = []
        battle.pbParty(battler.index).each_with_index do |pkmn,partyIndex|
            next unless pkmn
            next if pkmn.fainted?
            next if pkmn.hp == pkmn.totalhp
            next if battle.pbFindBattler(partyIndex, battler.index)
            potentialHeals.push(pkmn)
        end
        unless potentialHeals.empty?
            healTarget = potentialHeals.sample
            battle.pbDisplay(_INTL("{1} also heals {2}!", battler.pbThis, healTarget.name))
            healTarget.healBy(healingAmount)
        end
    end
  }
)

BattleHandlers::EORHealingAbility.add(:LUXURYTASTE,
  proc { |ability, battler, battle|
      next unless battler.hasActiveItem?(GameData::Item.getByFlag("Clothing"))
      healingMessage = _INTL("{1} luxuriated in its fine clothing.", battler.pbThis)
      battler.applyFractionalHealing(1.0 / 12.0, ability: ability, customMessage: healingMessage)
  }
)

DIRECT_CURRENT_HEALING_FRACTION = 1.0/5.0

BattleHandlers::EORHealingAbility.add(:DIRECTCURRENT,
  proc { |ability, battler, battle|
    if battler.pbCanLowerStatStep?(:SPECIAL_ATTACK, battler)
      battler.showMyAbilitySplash(ability)
      battler.tryLowerStat(:SPECIAL_ATTACK, battler)
      choices = [_INTL("Speed"),_INTL("Healing")]
      if battle.autoTesting
        choice = rand(1)
      elsif !battler.pbOwnedByPlayer? # Trainer AI
        choice = 0
      else
        choice = battle.scene.pbShowCommands(_INTL("Where to direct power?"),choices,0)
      end
      if choice == 0
        battler.tryRaiseStat(:SPEED, battler)
      else
        battler.applyFractionalHealing(DIRECT_CURRENT_HEALING_FRACTION)
      end
      battler.hideMyAbilitySplash
    end
  }
)