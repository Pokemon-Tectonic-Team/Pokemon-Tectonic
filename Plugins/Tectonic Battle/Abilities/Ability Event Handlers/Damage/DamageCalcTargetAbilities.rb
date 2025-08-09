BattleHandlers::DamageCalcTargetAbility.add(:FILTER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.super_effective?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 0.75
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.copy(:FILTER, :SOLIDROCK, :PRISMARMOR)

BattleHandlers::DamageCalcTargetAbility.add(:SHIELDWALL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.hyper_effective?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 0.5
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:UNFAZED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.normal?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 0.8
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WELLSUITED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.not_very_effective?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 0.5
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DRYSKIN,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :FIRE
      mults[:base_damage_multiplier] *= 1.25
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FINESUGAR,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :WATER
      mults[:base_damage_multiplier] *= 1.25
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FLUFFY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FIRE
      mults[:final_damage_multiplier] *= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PARANOID,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :PSYCHIC
      mults[:final_damage_multiplier] *= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MULTISCALE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.hp == target.totalhp
      mults[:final_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.copy(:MULTISCALE,:DOMINEERING,:SHADOWSHIELD)

BattleHandlers::DamageCalcTargetAbility.add(:THICKFAT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[FIRE ICE].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:UNAFRAID,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[BUG DARK].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:EXORCIST,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[GHOST PSYCHIC].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FEATHERCOAT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[ICE FLYING].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:REALIST,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[DRAGON FAIRY GHOST].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TOUGH,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if %i[FIGHTING ROCK].include?(type)
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WATERBUBBLE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :FIRE
      mults[:final_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:STEAMPOWER,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if type == :WATER
      mults[:final_damage_multiplier] /= 2.0
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WEATHERED,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.pbWeather != :None
      mults[:final_damage_multiplier] *= 0.80
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SENTRY,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:ChoseStatus)
      mults[:final_damage_multiplier] *= 0.75
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:VIGILANT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:ChoseStatus)
      mults[:final_damage_multiplier] *= 0.6
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:TRAPPER,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.trapped?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BOTTOMFEEDER,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.trapped?
      mults[:final_damage_multiplier] *= 0.75
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FORTIFIED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if aiCheck
      mults[:final_damage_multiplier] *= 0.7 unless user.pbSpeed(true) > target.pbSpeed(true, move: move)
    elsif !target.movedThisRound?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability)
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SANDSHROUD,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.sandy?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DESERTSPIRIT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.sandy?
      mults[:final_damage_multiplier] *= 0.8
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SNOWSHROUD,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.icy?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:FERROFLUID,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.rainy?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MISTBLANKET,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.moonGlowing?
      mults[:final_damage_multiplier] *= 0.75
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:APPREHENSIVE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if user.battle.partialEclipse?
      mults[:final_damage_multiplier] *= 0.65
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BULLY,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.pbHeight < user.pbHeight
      mults[:base_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:LIMINAL,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:SwitchedIn)
      mults[:final_damage_multiplier] *= 0.5
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:MISTFORM,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:SwitchedIn)
      mults[:final_damage_multiplier] *= 0.33
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PLASMAGLOBE,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
      mults[:final_damage_multiplier] *= 1.5
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:INTROVERT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    unless target.usedDamagingMove
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:QUARRELSOME,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.firstTurn?
      mults[:final_damage_multiplier] *= 2
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:RUSTWRACK,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
      mults[:final_damage_multiplier] *= 1.15
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:APRICORNARMOR,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.pbHasAnyStatus?
      mults[:final_damage_multiplier] *= 0.6
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:RUGGEDSCALES,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.randomEffect?
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:DARTER,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
    if target.pbOwnSide.effectActive?(:Tailwind)
      mults[:final_damage_multiplier] *= 0.7
      target.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:WHITEKNIGHT,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
      mults[:final_damage_multiplier] *= 0.85
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:BURDENED,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
      mults[:final_damage_multiplier] *= 0.5
      target.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:PALACEGUARD,
  proc { |ability, user, target, _move, mults, _baseDmg, type, aiCheck|
      if target.battle.roomActive?
        mults[:final_damage_multiplier] *= 0.66
        target.aiLearnsAbility(ability) unless aiCheck
      end
  }
)