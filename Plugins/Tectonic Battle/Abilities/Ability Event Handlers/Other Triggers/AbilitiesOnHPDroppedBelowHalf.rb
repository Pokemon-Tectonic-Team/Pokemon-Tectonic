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
      form0Name = GameData::Species.get_species_form(:ROTOM,0).form_name 
      form1Name = GameData::Species.get_species_form(:ROTOM,1).form_name
      form2Name = GameData::Species.get_species_form(:ROTOM,2).form_name
      form3Name = GameData::Species.get_species_form(:ROTOM,3).form_name
      form4Name = GameData::Species.get_species_form(:ROTOM,4).form_name
      form5Name = GameData::Species.get_species_form(:ROTOM,5).form_name
      choices = [form0Name,form1Name,form2Name,form3Name,form4Name,form5Name]
      if battle.autoTesting
        choice = rand(5)
      elsif !battler.pbOwnedByPlayer? # Trainer AI
        choice = 0
      else
        choice = battle.scene.pbShowCommands(_INTL("Which form should it take?"),choices,0)
      end
      battler.pbChangeForm(choice, _INTL("{1} takes on a new machine!", battler.pbThis))
  }
)