BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:EMERGENCYEXIT,
    proc { |ability, battler, battle|
        next false if battler.fainted?
        next false if battle.pbAllFainted?(battler.idxOpposingSide)
        next battle.triggeredSwitchOut(battler.index, ability: ability)
    }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.copy(:EMERGENCYEXIT, :WIMPOUT)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:BERSERK,
  proc { |ability, battler, _battle|
      battler.pbRaiseMultipleStatSteps(ATTACKING_STATS_2, battler, ability: ability)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:ADRENALINERUSH,
  proc { |ability, battler, _battle|
      battler.tryRaiseStat(:SPEED, battler, increment: 4, ability: ability)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:BOULDERNEST,
  proc { |ability, battler, battle|
      battle.pbShowAbilitySplash(battler, ability)
      if battler.pbOpposingSide.effectActive?(:StealthRock)
          battle.pbDisplay(_INTL("But there were already pointed stones floating around {1}!",
                battler.pbOpposingTeam(true)))
      else
          battler.pbOpposingSide.applyEffect(:StealthRock)
      end
      battle.pbHideAbilitySplash(battler)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:REAWAKENEDPOWER,
  proc { |ability, battler, _battle|
      battler.pbMaximizeStatStep(:SPECIAL_ATTACK, battler, self, ability: ability)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:PRIMEVALDISGUISE,
    proc { |ability, battler, battle|
        next unless battler.illusion?
        battle.pbShowAbilitySplash(battler,ability)
        battler.disableEffect(:Illusion)
        battle.scene.pbChangePokemon(battler, battler.pokemon)
        battle.pbSetSeen(battler)
        battle.pbHideAbilitySplash(battler)
        next false
    }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:BATTLEHARDENED,
  proc { |ability, battler, _battle|
      battler.pbRaiseMultipleStatSteps([:DEFENSE, 3, :SPECIAL_DEFENSE, 3], battler, ability: ability)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:WIRECUTTER,
  proc { |ability, battler, battle|
      battle.pbShowAbilitySplash(battler, ability)
      if battler.pbOpposingSide.effectActive?(:LiveWire)
          battle.pbDisplay(_INTL("But a live wire already sits near {1}!",
                battler.pbOpposingTeam(true)))
      else
          battler.pbOpposingSide.applyEffect(:LiveWire)
      end
      battle.pbHideAbilitySplash(battler)
      next false
  }
)

BattleHandlers::AbilityOnHPDroppedBelowHalf.add(:VOIDWARRANTY,
  proc { |ability, battler, battle, endOfBattle|
      next if battler.fainted?
      next unless battler.species == :ROTOM
      
      formChoices = []
      choiceNames = []

      formIndex = -1
      loop do
        formIndex += 1
        data = GameData::Species.get_species_form(:ROTOM,formIndex)
        break if data.nil? || data.form != formIndex
        next if formIndex == battler.form
        formChoices.push(formIndex)
        choiceNames.push(data.form_name)
        echoln("Adding form #{formIndex}")
      end

      next unless formChoices.length > 0
      
      battle.pbShowAbilitySplash(battler, ability)
      if battle.autoTesting
        choiceIndex = rand(formChoices.length)
      elsif !battler.pbOwnedByPlayer? # Trainer AI
        choiceIndex = 0
      else
        choiceIndex = battle.scene.pbShowCommands(_INTL("Which form should {1} take?",battler.name),choiceNames,0)
      end
      battler.pbChangeForm(formChoices[choiceIndex], _INTL("{1} takes on a new machine!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)