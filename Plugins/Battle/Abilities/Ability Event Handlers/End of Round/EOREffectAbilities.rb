BattleHandlers::EOREffectAbility.add(:BADDREAMS,
  proc { |ability,battler,battle|
    battle.eachOtherSideBattler(battler.index) do |b|
      next if !b.near?(battler) || !b.asleep?
      battle.pbShowAbilitySplash(battler)
      next if !b.takesIndirectDamage?(true)
      battle.pbDisplay(_INTL("{1} is pained by its dreams!",b.pbThis))
      b.applyFractionalDamage(1.0/8.0,false)
      battle.pbHideAbilitySplash(battler)
    end
  }
)

BattleHandlers::EOREffectAbility.add(:MOODY,
  proc { |ability,battler,battle|
    randomUp = []
    randomDown = []
    GameData::Stat.each_battle do |s|
      next if s == :EVASION || s == :ACCURACY
      randomUp.push(s.id) if battler.pbCanRaiseStatStage?(s.id, battler)
      randomDown.push(s.id) if battler.pbCanLowerStatStage?(s.id, battler)
    end
    next if randomUp.length==0 && randomDown.length==0
    battle.pbShowAbilitySplash(battler)
    if randomUp.length>0
      r = battle.pbRandom(randomUp.length)
      battler.pbRaiseStatStageByAbility(randomUp[r],2,battler,false)
      randomDown.delete(randomUp[r])
    end
    if randomDown.length>0
      r = battle.pbRandom(randomDown.length)
      battler.pbLowerStatStageByAbility(randomDown[r],1,battler,false)
    end
    battle.pbHideAbilitySplash(battler)
    battler.pbItemStatRestoreCheck if randomDown.length>0
  }
)

BattleHandlers::EOREffectAbility.add(:SPEEDBOOST,
  proc { |ability,battler,battle|
    # A Pokémon's turnCount is 0 if it became active after the beginning of a
    # round
    if battler.turnCount>0 && battler.pbCanRaiseStatStage?(:SPEED,battler)
      battler.pbRaiseStatStageByAbility(:SPEED,1,battler)
    end
  }
)

BattleHandlers::EOREffectAbility.add(:BALLFETCH,
  proc { |ability,battler,battle|
    if battler.effectActive?(:BallFetch) && battler.item<=0
      ball=battler.effects[:BallFetch]
      battler.item=ball
      battler.setInitialItem(battler.item)
      PBDebug.log("[Ability triggered] #{battler.pbThis}'s Ball Fetch found #{PBItems.getName(ball)}")
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1} found a {2}!",battler.pbThis,PBItems.getName(ball)))
      battler.disableEffect(:BallFetch)
      battle.pbHideAbilitySplash(battler)
    end
  }
)

BattleHandlers::EOREffectAbility.add(:HUNGERSWITCH,
  proc { |ability,battler,battle|
    if battler.species == :MORPEKO
      battle.pbShowAbilitySplash(battler)
      battler.form=(battler.form==0) ? 1 : 0
      battler.pbUpdate(true)
      battle.scene.pbChangePokemon(battler,battler.pokemon)
      battle.pbDisplay(_INTL("{1} transformed!",battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    end
  }
)

BattleHandlers::EOREffectAbility.add(:ASTRALBODY,
  proc { |ability,battler,battle|
	next unless battle.field.terrain==:Misty
    next if !battler.canHeal?
	  battle.pbShowAbilitySplash(battler)
    healAmount = battler.totalhp / 16.0
    healAmount /= BOSS_HP_BASED_EFFECT_RESISTANCE.to_f if battler.boss?
    healingMessage = battle.pbDisplay(_INTL("{1} absorbs magic from the fae mist.",battler.pbThis))
    battler.pbRecoverHP(healAmount,true,true,true,healingMessage)
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EOREffectAbility.add(:LUXURYTASTE,
  proc { |ability,battler,battle|
    next unless battler.hasActiveItem?(CLOTHING_ITEMS)
    next unless battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    healAmount = battler.totalhp / 8.0
    healAmount /= BOSS_HP_BASED_EFFECT_RESISTANCE.to_f if battler.boss?
    healingMessage = battle.pbDisplay(_INTL("{1} luxuriated in its fine clothing.",battler.pbThis))
    battler.pbRecoverHP(healAmount,true,true,true,healingMessage)
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EOREffectAbility.add(:WARMTHCYCLE,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    if !battler.statStageAtMax?(:SPEED)
        if battler.pbCanRaiseStatStage?(:SPEED)
            battle.pbDisplay(_INTL("{1} warms up!",battler.pbThis))
            battler.pbRaiseStatStage(:SPEED,2,battler)
            battler.applyFractionalDamage(1.0/8.0,false)
        end
    else
        battle.pbDisplay(_INTL("{1} vents its accumulated heat!",battler.pbThis))
        battler.pbLowerStatStage(:SPEED,6,battler)
        battler.pbRecoverHP(battler.totalhp - battler.hp)
    end
    
    battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::EOREffectAbility.add(:EXTREMEHEAT,
  proc { |ability,battler,battle|
    battle.pbShowAbilitySplash(battler)
    battler.applyFractionalDamage(1.0/10.0,false)
    battle.pbHideAbilitySplash(battler)
  }
)