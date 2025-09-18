BattleHandlers::TargetAbilityKnockedBelowHalf.add(:VENGEANCE,
    proc { |ability, target, user, move, _switched, battle|
        battle.pbShowAbilitySplash(target, ability)
        user.applyFractionalDamage(1.0 / 4.0) if user.takesIndirectDamage?(true)
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:BRILLIANTFLURRY,
    proc { |ability, target, user, move, _switched, _battle|
        user.pbLowerMultipleStatSteps(ALL_STATS_1, target, ability: ability)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:STICKYMOLD,
    proc { |ability, target, user, move, _switched, battle|
        next if user.leeched?
        battle.pbShowAbilitySplash(target, ability)
        user.applyLeeched(target) if user.canLeech?(target, true)
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:MOISTSKIN,
    proc { |ability, target, user, move, _switched, battle|
        next if user.waterlogged?
        battle.pbShowAbilitySplash(target, ability)
        user.applyWaterlog(target) if user.canWaterlog?(target, true)
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:WRATHINSTINCT,
    proc { |ability, target, user, move, _switched, battle|
        battle.forceUseMove(target, :DRAGONDANCE, ability: ability)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:EMERGENCYPOWER,
    proc { |ability, target, user, move, _switched, battle|
        battle.forceUseMove(target, :LIGHTNINGDANCE, ability: ability)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:MALICE,
    proc { |ability, target, user, move, _switched, battle|
        next if user.effectActive?(:Curse)
        battle.pbShowAbilitySplash(target, ability)
        user.applyEffect(:Curse)
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:HARDAS,
    proc { |ability, target, user, move, _switched, battle|
        next if user.effectActive?(:Fracture)
        battle.pbShowAbilitySplash(target, ability)
        user.applyEffect(:Fracture, applyEffectDurationModifiers(DEFAULT_FRACTURE_DURATION, battler))
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:KARMA,
    proc { |ability, target, user, move, _switched, battle|
        next if user.effectActive?(:Jinxed)
        battle.pbShowAbilitySplash(target, ability)
        user.applyEffect(:Jinxed, applyEffectDurationModifiers(DEFAULT_JINX_DURATION, battler))
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:DREAMYHAZE,
    proc { |ability, target, user, move, _switched, battle|
        next unless user.canSleep?(target, true)
        next if user.effectActive?(:Yawn)
        battle.pbShowAbilitySplash(target, ability)
        user.applyEffect(:Yawn, 2)
        battle.pbHideAbilitySplash(target)
    }
)

BattleHandlers::TargetAbilityKnockedBelowHalf.add(:SUDDENTURN,
    proc { |ability, target, user, move, _switched, battle|
        battle.forceUseMove(target, :RAPIDSPIN, ability: ability)
    }
)