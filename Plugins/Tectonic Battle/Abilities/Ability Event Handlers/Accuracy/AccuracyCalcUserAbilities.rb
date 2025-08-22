BattleHandlers::AccuracyCalcUserAbility.add(:COMPOUNDEYES,
    proc { |ability, mults, _user, _target, _move, _type|
        mults[:accuracy_multiplier] *= 1.3
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:HUSTLE,
  proc { |ability, mults, _user, _target, move, _type|
      mults[:accuracy_multiplier] *= 0.8
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:KEENEYE,
  proc { |ability, mults, _user, _target, _move, _type|
      mults[:evasion_step] = 0 if mults[:evasion_step] > 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NOGUARD,
  proc { |ability, mults, _user, _target, _move, _type|
      mults[:base_accuracy] = 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:VICTORYSTAR,
  proc { |ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 2.0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:OCULAR,
  proc { |ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 1.5
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:SANDSNIPER,
    proc { |ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.battle.sandy?
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NIGHTOWL,
  proc { |ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.moonGlowing?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:STARSALIGN,
  proc { |ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.eclipsed?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:FREESTYLE,
  proc { |ability, mults, _user, _target, move, _type|
      mults[:accuracy_multiplier] *= 0.8
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:WATERFALLCONDITIONING,
    proc { |ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.battle.rainy?
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:PINDOWN,
    proc { |ability, mults, user, target, _move, _type|
        mults[:base_accuracy] = 0 if target.trapped?
    }
)