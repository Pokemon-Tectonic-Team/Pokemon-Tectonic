#########################################
# Poison abilities
#########################################

BattleHandlers::UserAbilityOnHit.add(:POISONTOUCH,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :POISON, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:INTOXICATE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :POISON, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:DARKSCALECLOUD,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.belowHalfHealth?
    randomStatusProcUserAbility(ability, :POISON, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Burn abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:ROARINGFLAME,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :BURN, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:BURNOUT,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :BURN, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:DAWNFALL,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.firstTurn?
    randomStatusProcUserAbility(ability, :BURN, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:FLAMEWINGS,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.calcType == :FLYING
    randomStatusProcUserAbility(ability, :BURN, 40, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Frostbite abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:CHRONICCOLD,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :FROSTBITE, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:CHILLOUT,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :FROSTBITE, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:FLASHFREEZE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.firstTurn?
    randomStatusProcUserAbility(ability, :FROSTBITE, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:FROSTWINGS,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.calcType == :FLYING
    randomStatusProcUserAbility(ability, :FROSTBITE, 40, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Numb abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:NUMBINGTOUCH,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :NUMB, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:NERVENUMBER,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :NUMB, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:SHOCKWINGS,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.calcType == :FLYING  
    randomStatusProcUserAbility(ability, :NUMB, 40, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:DISCONNECTION,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.firstTurn?
    randomStatusProcUserAbility(ability, :NUMB, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Waterlog abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:MARINE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :WATERLOG, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:SATURATER,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :WATERLOG, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Dizzy abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:STAGGERINGSLAPS,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :DIZZY, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:BRAINSCRAMBLE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :DIZZY, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Leech abilities
#########################################
BattleHandlers::UserAbilityOnHit.add(:DEADBEAT,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    randomStatusProcUserAbility(ability, :LEECHED, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:SEEDSOWING,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    randomStatusProcUserAbility(ability, :LEECHED, 30, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:SIPHONSNIPER,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.firstTurn?
    randomStatusProcUserAbility(ability, :LEECHED, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

BattleHandlers::UserAbilityOnHit.add(:PESTILENT,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless user.belowHalfHealth?
    randomStatusProcUserAbility(ability, :LEECHED, 100, user, target, move, battle, aiCheck, aiNumHits)
  }
)

#########################################
# Other status abilities
#########################################

BattleHandlers::UserAbilityOnHit.add(:MENTALDAMAGE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next if target.fainted?
    next if target.effectActive?(:Disable)
    next if target.lastRegularMoveUsed.nil?
    if aiCheck
      next 15
    else
      battle.pbShowAbilitySplash(user, ability)
      target.applyEffect(:Disable,2) if target.canBeDisabled?(true, move)
      battle.pbHideAbilitySplash(user)
    end
  }
)

#########################################
# Stat change abilities
#########################################

BattleHandlers::UserAbilityOnHit.add(:SHELLCRACKER,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    if aiCheck
      ret = 0
      aiNumHits.times do |i|
          ret += getMultiStatDownEffectScore([:DEFENSE,1], target, user, fakeStepModifier: i)
      end
      next ret
    end
    target.tryLowerStat(:DEFENSE, user, ability: ability)
  }
)

BattleHandlers::UserAbilityOnHit.add(:BIZARRE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.specialMove?
    if aiCheck
      ret = 0
      aiNumHits.times do |i|
          ret += getMultiStatDownEffectScore([:SPECIAL_DEFENSE,1], target, user, fakeStepModifier: i)
      end
      next ret
    end
    target.tryLowerStat(:SPECIAL_DEFENSE, user, ability: ability)
  }
)

BattleHandlers::UserAbilityOnHit.add(:RENDINGCLAWS,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless target.damageState.critical
    if aiCheck
      ret = 0
      aiNumHits.times do |i|
          ret += getMultiStatDownEffectScore(ALL_STATS_1, target, user, fakeStepModifier: i)
      end
      next ret
    end
    target.pbLowerMultipleStatSteps(ALL_STATS_1, user, ability: ability)
  }
)

BattleHandlers::UserAbilityOnHit.add(:FATCHANCE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless target.damageState.critical
    if aiCheck
      next unless target.belowHalfHealth?
      ret = 0
      aiNumHits.times do |i|
          ret += getMultiStatUpEffectScore(ALL_STATS_1, user, user, fakeStepModifier: i)
      end
      next ret
    end
    next unless target.fainted?
    user.pbRaiseMultipleStatSteps(ALL_STATS_1, user, ability: ability)
  }
)

#########################################
# Other Abilities
#########################################


BattleHandlers::UserAbilityOnHit.add(:COREPROVENANCE,
  proc { |ability, user, target, move, battle, aiCheck, aiNumHits|
    next unless move.physicalMove?
    next if user.pbOwnSide.effectAtMax?(:ErodedRock)
    if aiCheck
        next (user.aboveHalfHealth? ? 10 : 5) * aiNumHits
    end
    user.pbOwnSide.incrementEffect(:ErodedRock)
  }
)