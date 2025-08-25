BattleHandlers::AbilityOnSwitchOut.add(:REGENERATOR,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battler.pbRecoverHP(battler.totalhp / 4.0, false, false, false)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:NATURALCURE,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      next unless battler.pbHasAnyStatus?
      battler.pbCureStatus(false)
      battler.aiLearnsAbility(ability)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:FLYBY,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battle.forceUseMove(battler, :GUST, ability: ability)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:REFUGE,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battler.position.applyEffect(:Refuge, battler.pokemonIndex)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:POORCONDUCT,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battle.pbShowAbilitySplash(battler, ability)
      battle.eachOtherSideBattler(battler.index) do |b|
          next unless b.near?(battler)
          b.pbLowerMultipleStatSteps([:ATTACK,1,:SPECIAL_ATTACK,1],battler,showFailMsg: true)
      end
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:STORMTRAIL,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battler.position.applyEffect(:StormTrail, battler.pokemonIndex)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:MISTTRAIL,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battler.position.applyEffect(:MistTrail, battler.pokemonIndex)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:MAGMATRAIL,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battler.position.applyEffect(:MagmaTrail, battler.pokemonIndex)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:MOTHBURGLAR,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      battle.forceUseMove(battler, :THIEF, ability: ability)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:CLUMSYKINESIS,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      next unless battler.losableItemCount > 0
      battle.pbShowAbilitySplash(battler,ability)
      if battler.losableItemCount == 1
          chosenItem = battler.loseableItems[0]
      elsif battler.losableItemCount > 1
          if battle.autoTesting
              chosenItem = battler.loseableItems.sample
          elsif !battler.pbOwnedByPlayer? # Trainer AI
              chosenItem = battler.loseableItems[0]
          else
              itemNames = []
              battler.loseableItems.each do |itemID|
                  itemNames.push(getItemName(itemID))
              end
              chosenIndex = battle.scene.pbShowCommands(_INTL("Which item should {1} drop?", battler.pbThis(true)),itemNames,0)
              chosenItem = battler.loseableItems[chosenIndex]
          end
      end
      battler.removeItem(chosenItem)
      battle.pbDisplay(_INTL("{1} dropped its {2}!",battler.pbThis,getItemName(chosenItem)))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchOut.add(:COSTUMECHANGE,
  proc { |ability, battler, battle, endOfBattle|
      next if endOfBattle
      next unless battler.species == :ORICORIO
      form0Name = GameData::Species.get_species_form(:ORICORIO,0).form_name 
      form1Name = GameData::Species.get_species_form(:ORICORIO,1).form_name
      form2Name = GameData::Species.get_species_form(:ORICORIO,2).form_name
      form3Name = GameData::Species.get_species_form(:ORICORIO,3).form_name
      choices = [form0Name,form1Name,form2Name,form3Name]
      if battle.autoTesting
        choice = rand(3)
      elsif !battler.pbOwnedByPlayer? # Trainer AI
        choice = 0
      else
        choice = battle.scene.pbShowCommands(_INTL("Which form should it take?"),choices,0)
      end
      battler.pbChangeForm(choice, _INTL("{1} takes on a new style!", battler.pbThis))
  }
)



