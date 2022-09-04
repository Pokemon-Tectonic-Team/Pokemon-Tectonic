ItemHandlers::UseOnPokemon.add(:RARECANDY,proc { |item,pkmn,scene|
  if pkmn.level>=GameData::GrowthRate.max_level || pkmn.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  elsif LEVEL_CAPS_USED && (pkmn.level + 1) > $game_variables[26]
      scene.pbDisplay(_INTL("It won't have any effect due to the level cap at #{$game_variables[26]}."))
      next false
  end
  pbChangeLevel(pkmn,pkmn.level+1,scene)
  scene.pbHardRefresh
  next true
})


def pbBattleConfusionBerry(battler,battle,item,forced,flavor,confuseMsg)
  return false if !forced && !battler.canHeal?
  return false if !forced && !battler.canConsumePinchBerry?(Settings::MECHANICS_GENERATION >= 7)
  itemName = GameData::Item.get(item).name
  battle.pbCommonAnimation("EatBerry",battler) if !forced
  fraction_to_heal = 8   # Gens 6 and lower
  if Settings::MECHANICS_GENERATION == 7;    fraction_to_heal = 2
  elsif Settings::MECHANICS_GENERATION >= 8; fraction_to_heal = 3
  end
  intendedHealAmount = (battler.totalhp / fraction_to_heal)
  intendedHealAmount *= 2 if battler.hasActiveAbility?(:RIPEN)
  amt = battler.pbRecoverHP(intendedHealAmount)
  if amt>0
    if forced
      PBDebug.log("[Item triggered] Forced consuming of #{itemName}")
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1} restored its health using its {2}!",battler.pbThis,itemName))
    end
  end
  flavor_stat = [:ATTACK, :DEFENSE, :SPEED, :SPECIAL_ATTACK, :SPECIAL_DEFENSE][flavor]
  battler.nature.stat_changes.each do |change|
    next if change[1] > 0 || change[0] != flavor_stat
    battle.pbDisplay(confuseMsg)
    battler.pbConfuse if battler.pbCanConfuseSelf?(false)
    break
  end
  return true
end

def pbBattleStatIncreasingBerry(battler,battle,item,forced,stat,increment=1)
  return false if !forced && !battler.canConsumePinchBerry?
  return false if !battler.pbCanRaiseStatStage?(stat,battler)
  itemName = GameData::Item.get(item).name
  if battler.hasActiveAbility?(:RIPEN)
    increment *=2
  end
  if forced
    PBDebug.log("[Item triggered] Forced consuming of #{itemName}")
    return battler.pbRaiseStatStage(stat,increment,battler)
  end
  battle.pbCommonAnimation("EatBerry",battler)
  return battler.pbRaiseStatStageByCause(stat,increment,battler,itemName)
end

def pbBattleTypeWeakingBerry(type,moveType,target,mults)
  return if moveType != type
  return if Effectiveness.resistant?(target.damageState.typeMod) && moveType != :NORMAL
  if target.hasActiveAbility?(:RIPEN)
    mults[:final_damage_multiplier] = (mults[:final_damage_multiplier]/4).round
  else
	mults[:final_damage_multiplier] /= 2
  end
  target.damageState.berryWeakened = true
  target.battle.pbCommonAnimation("EatBerry",target)
end


BattleHandlers::HPHealItem.add(:ORANBERRY,
  proc { |item,battler,battle,forced|
    next false if !battler.canHeal?
    next false if !forced && !battler.canConsumePinchBerry?(true)
    battle.pbCommonAnimation("EatBerry",battler) if !forced
	hpRestore = battler.totalhp.to_f / 3.0
	hpRestore *= 2 if battler.hasActiveAbility?(:RIPEN)
	battler.pbRecoverHP(hpRestore)
    itemName = GameData::Item.get(item).name
    if forced
      PBDebug.log("[Item triggered] Forced consuming of #{itemName}")
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1} restored its health using its {2}!",battler.pbThis,itemName))
    end
    next true
  }
)

BattleHandlers::HPHealItem.add(:SITRUSBERRY,
  proc { |item,battler,battle,forced|
    next false if !battler.canHeal?
    next false if !forced && !battler.canConsumePinchBerry?(false)
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    hpRestore = battler.totalhp.to_f / 4.0
	hpRestore *= 2 if battler.hasActiveAbility?(:RIPEN)
	battler.pbRecoverHP(hpRestore)
    itemName = GameData::Item.get(item).name
    if forced
      PBDebug.log("[Item triggered] Forced consuming of #{itemName}")
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1} restored its health using its {2}!",battler.pbThis,itemName))
    end
    next true
  }
)

ItemHandlers::UseOnPokemon.add(:ICEHEAL,proc { |item,pkmn,scene|
  if pkmn.fainted? || pkmn.status != :FROZEN
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was unchilled out.",pkmn.name))
  next true
})

BattleHandlers::EOREffectItem.add(:TOXICORB,
  proc { |item,battler,battle|
    next if !battler.pbCanPoison?(nil,false)
    battler.pbPoison(nil,_INTL("{1} was toxified by the {2}!",
       battler.pbThis,battler.itemName),true)
  }
)

ItemHandlers::UseOnPokemon.copy(:FULLHEAL,:STATUSHEAL)

ItemHandlers::UseOnPokemon.add(:POTION,proc { |item,pkmn,scene|
  next pbHPItem(pkmn,40,scene)
})

ItemHandlers::UseOnPokemon.add(:SUPERPOTION,proc { |item,pkmn,scene|
  next pbHPItem(pkmn,80,scene)
})

ItemHandlers::UseOnPokemon.add(:HYPERPOTION,proc { |item,pkmn,scene|
  next pbHPItem(pkmn,120,scene)
})

BattleHandlers::TargetItemOnHit.add(:JABOCABERRY,
  proc { |item,user,target,move,battle|
    next if !target.canConsumeBerry?
    next if !move.physicalMove?
    next if !user.takesIndirectDamage?
    battle.pbCommonAnimation("EatBerry",target)
	reduction = user.totalhp/8
	if target.hasActiveAbility?(:RIPEN)
		reduction *= 2
	end
	user.damageState.displayedDamage = reduction
	battle.scene.pbDamageAnimation(user)
	user.pbReduceHP(reduction,false)
    battle.pbDisplay(_INTL("{1} consumed its {2} and hurt {3}!",target.pbThis,
       target.itemName,user.pbThis(true)))
    target.pbHeldItemTriggered(item)
  }
)

BattleHandlers::TargetItemOnHit.add(:ROWAPBERRY,
  proc { |item,user,target,move,battle|
    next if !target.canConsumeBerry?
    next if !move.specialMove?
    next if !user.takesIndirectDamage?
    battle.pbCommonAnimation("EatBerry",target)
    reduction = user.totalhp/8
	if target.hasActiveAbility?(:RIPEN)
		reduction *= 2
	end
	user.damageState.displayedDamage = reduction
	battle.scene.pbDamageAnimation(user)
	user.pbReduceHP(reduction,false)
    battle.pbDisplay(_INTL("{1} consumed its {2} and hurt {3}!",target.pbThis,
       target.itemName,user.pbThis(true)))
    target.pbHeldItemTriggered(item)
  }
)

BattleHandlers::DamageCalcUserItem.add(:THICKCLUB,
  proc { |item,user,target,move,mults,baseDmg,type|
    if (user.isSpecies?(:CUBONE) || user.isSpecies?(:MAROWAK)) && move.physicalMove?
      mults[:attack_multiplier] *= 1.5
    end
  }
)

BattleHandlers::TargetItemOnHit.add(:ENIGMABERRY,
  proc { |item,user,target,move,battle|
    next if target.damageState.substitute || target.damageState.disguise || target.damageState.iceface
    next if !Effectiveness.super_effective?(target.damageState.typeMod)
    if BattleHandlers.triggerTargetItemOnHitPositiveBerry(item,target,battle,false)
      target.pbHeldItemTriggered(item)
    end
  }
)

BattleHandlers::TargetItemOnHit.add(:WEAKNESSPOLICY,
  proc { |item,user,target,move,battle|
    next if target.damageState.disguise  || target.damageState.iceface
    next if !Effectiveness.super_effective?(target.damageState.typeMod)
    next if !target.pbCanRaiseStatStage?(:ATTACK,target) &&
            !target.pbCanRaiseStatStage?(:SPECIAL_ATTACK,target)
    battle.pbCommonAnimation("UseItem",target)
    showAnim = true
    if target.pbCanRaiseStatStage?(:ATTACK,target)
      target.pbRaiseStatStageByCause(:ATTACK,2,target,target.itemName,showAnim)
      showAnim = false
    end
    if target.pbCanRaiseStatStage?(:SPECIAL_ATTACK,target)
      target.pbRaiseStatStageByCause(:SPECIAL_ATTACK,2,target,target.itemName,showAnim)
    end
    target.pbHeldItemTriggered(item)
  }
)

#===============================================================================
# TargetItemOnHitPositiveBerry handlers
# NOTE: This is for berries that have an effect when Pluck/Bug Bite/Fling
#       forces their use.
#===============================================================================

BattleHandlers::TargetItemOnHitPositiveBerry.add(:ENIGMABERRY,
  proc { |item,battler,battle,forced|
    next false if !battler.canHeal?
    next false if !forced && !battler.canConsumeBerry?
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    if battler.hasActiveAbility?(:RIPEN)
      battler.pbRecoverHP(battler.totalhp/2)
    else
      battler.pbRecoverHP(battler.totalhp/4)
    end
    if forced
      battle.pbDisplay(_INTL("{1}'s HP was restored.",battler.pbThis))
    else
      battle.pbDisplay(_INTL("{1} restored its health using its {2}!",battler.pbThis,
         itemName))
    end
    next true
  }
)

BattleHandlers::TargetItemOnHitPositiveBerry.add(:KEEBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.pbCanRaiseStatStage?(:DEFENSE,battler)
    itemName = GameData::Item.get(item).name
	increment = 1
	if battler.hasActiveAbility?(:RIPEN)
      increment *=2
    end
    if !forced
      battle.pbCommonAnimation("EatBerry",battler)
      next battler.pbRaiseStatStageByCause(:DEFENSE,increment,battler,itemName)
    end
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}")
    next battler.pbRaiseStatStage(:DEFENSE,increment,battler)
  }
)

BattleHandlers::TargetItemOnHitPositiveBerry.add(:MARANGABERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.pbCanRaiseStatStage?(:SPECIAL_DEFENSE,battler)
    itemName = GameData::Item.get(item).name
	increment = 1
	if battler.hasActiveAbility?(:RIPEN)
      increment *=2
    end
    if !forced
      battle.pbCommonAnimation("EatBerry",battler)
      next battler.pbRaiseStatStageByCause(:SPECIAL_DEFENSE,increment,battler,itemName)
    end
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}")
    next battler.pbRaiseStatStage(:SPECIAL_DEFENSE,increment,battler)
  }
)


BattleHandlers::TargetItemOnHit.add(:JABOCABERRY,
  proc { |item,user,target,move,battle|
    next if !target.canConsumeBerry?
    next if !move.physicalMove?
    next if !user.takesIndirectDamage?
    battle.pbCommonAnimation("EatBerry",target)
    battle.scene.pbDamageAnimation(user)
	reduce = user.totalhp/8
	reduce /= 4 if user.boss
    user.pbReduceHP(reduce,false)
    battle.pbDisplay(_INTL("{1} consumed its {2} and hurt {3}!",target.pbThis,
       target.itemName,user.pbThis(true)))
    target.pbHeldItemTriggered(item)
  }
)

BattleHandlers::TargetItemOnHit.add(:ROWAPBERRY,
  proc { |item,user,target,move,battle|
    next if !target.canConsumeBerry?
    next if !move.specialMove?
    next if !user.takesIndirectDamage?
    battle.pbCommonAnimation("EatBerry",target)
    battle.scene.pbDamageAnimation(user)
    reduce = user.totalhp/8
	reduce /= 4 if user.boss
    user.pbReduceHP(reduce,false)
    battle.pbDisplay(_INTL("{1} consumed its {2} and hurt {3}!",target.pbThis,
       target.itemName,user.pbThis(true)))
    target.pbHeldItemTriggered(item)
  }
)

BattleHandlers::TargetItemOnHit.add(:ROCKYHELMET,
  proc { |item,user,target,move,battle|
    next if !move.pbContactMove?(user) || !user.affectedByContactEffect?
    next if !user.takesIndirectDamage?
	  reduction = user.totalhp/6
	  reduction /= 4 if user.boss
	  user.damageState.displayedDamage = reduction
    battle.scene.pbDamageAnimation(user)
    user.pbReduceHP(reduction,false)
    battle.pbDisplay(_INTL("{1} was hurt by the {2}!",user.pbThis,target.itemName))
  }
)

ItemHandlers::UseOnPokemon.add(:ABILITYCAPSULE,proc { |item,pkmn,scene|
  abils = pkmn.getAbilityList
  abil1 = nil; abil2 = nil
  for i in abils
    abil1 = i[0] if i[1]==0
    abil2 = i[0] if i[1]==1
  end
  if abil1.nil? || abil2.nil? || pkmn.hasHiddenAbility? || pkmn.isSpecies?(:ZYGARDE)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  newabilindex = (pkmn.ability_index + 1) % 2
  newabil = GameData::Ability.get((newabilindex==0) ? abil1 : abil2)
  newabilname = newabil.name
  if scene.pbConfirm(_INTL("Would you like to change {1}'s Ability to {2}?",
     pkmn.name,newabilname))
    pkmn.ability_index = newabilindex
	pkmn.ability = newabil
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1}'s Ability changed to {2}!",pkmn.name,newabilname))
    next true
  end
  next false
})

BattleHandlers::UserItemAfterMoveUse.add(:SHELLBELL,
  proc { |item,user,targets,move,numHits,battle|
    next if !user.canHeal?
    totalDamage = 0
    targets.each { |b| totalDamage += b.damageState.totalHPLost }
    next if totalDamage<=0
	amt = (totalDamage/6.0).round
	amt = 1 if amt<1
    user.pbRecoverHP(amt)
    battle.pbDisplay(_INTL("{1} restored a little HP using its {2}!",
       user.pbThis,user.itemName))
  }
)

BattleHandlers::EOREffectItem.add(:STICKYBARB,
  proc { |item,battler,battle|
    next if !battler.takesIndirectDamage?
    oldHP = battler.hp
	reduction = battler.totalhp/8
	reduction /= 4 if battler.boss?
	battler.damageState.displayedDamage = reduction
    battle.scene.pbDamageAnimation(battler)
    battler.pbReduceHP(reduction,false)
    battle.pbDisplay(_INTL("{1} is hurt by its {2}!",battler.pbThis,battler.itemName))
    battler.pbItemHPHealCheck
    battler.pbAbilitiesOnDamageTaken(oldHP)
    battler.pbFaint if battler.fainted?
  }
)

GameData::Evolution.register({
  :id            => :TradeSpecies,
  :parameter     => :Species,
  :on_trade_proc => proc { |pkmn, parameter, other_pkmn|
    next pkmn.species == parameter && !other_pkmn.hasItem?(:EVERSTONE) && !other_pkmn.hasItem?(:EVIOLITE)
  }
})

BattleHandlers::DamageCalcUserItem.add(:CHOICEBAND,
  proc { |item,user,target,move,mults,baseDmg,type|
    mults[:base_damage_multiplier] *= 1.33 if move.physicalMove?
  }
)

BattleHandlers::DamageCalcUserItem.add(:CHOICESPECS,
  proc { |item,user,target,move,mults,baseDmg,type|
    mults[:base_damage_multiplier] *= 1.33 if move.specialMove?
  }
)

BattleHandlers::SpeedCalcItem.add(:CHOICESCARF,
  proc { |item,battler,mult|
    next mult * 1.33
  }
)

BattleHandlers::AccuracyCalcUserItem.add(:WIDELENS,
  proc { |item,mods,user,target,move,type|
    mods[:accuracy_multiplier] *= 1.35
  }
)

BallHandlers::ModifyCatchRate.add(:NESTBALL,proc { |ball,catchRate,battle,battler,ultraBeast|
  if LEVEL_CAPS_USED
    baseLevel = $game_variables[26] - 5
    if battler.level <= baseLevel
      catchRate *= [(11 + baseLevel - battler.level) / 10.0, 1].max
    end
  else
    if battler.level <= 30
      catchRate *= [(41 - battler.level) / 10.0, 1].max
    end
  end
  next catchRate
})

ItemHandlers::UseOnPokemon.add(:FLAMEORB,proc { |item,pkmn,scene|
  if pkmn.fainted? || pkmn.status != :NONE || [:STABILITY,:FAEVEIL].include?(pkmn.ability_id)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  pkmn.status      = :BURN
  pkmn.statusCount = 0
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was burned.",pkmn.name))
})

ItemHandlers::UseOnPokemon.add(:FROSTORB,proc { |item,pkmn,scene|
  if pkmn.fainted? || pkmn.status != :NONE || [:STABILITY,:FAEVEIL].include?(pkmn.ability_id)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  pkmn.status      = :FROSTBITE
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was frostbitten.",pkmn.name))
})

ItemHandlers::UseOnPokemon.add(:POISONORB,proc { |item,pkmn,scene|
  if pkmn.fainted? || pkmn.status != :NONE || [:STABILITY,:ENERGETIC].include?(pkmn.ability_id)
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  pkmn.status      = :POISON
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was poisoned.",pkmn.name))
})
