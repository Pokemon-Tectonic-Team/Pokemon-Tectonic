BattleHandlers::SpecialAttackCalcUserAbility.add(:FLAREBOOST,
    proc { |ability, user, _battle, spAtkMult|
        spAtkMult *= 1.5 if user.burned?
        next spAtkMult
    }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SOLARPOWER,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.5 if battle.sunny?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:HEADACHE,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 2.0
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:PUREENERGY,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.5
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:CLOUDBURST,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.rainy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:DEBRISFIELD,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.sandy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SOLARCELL,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.25 if battle.sunny?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:ARCANE,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.3
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:OVERTHINKING,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.3
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:MIDDLEWAY,
  proc { |ability, user, _battle, spAtkMult|
      spAtkMult *= 1.5 if user.lastRoundMoveCategory == 0
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:FELLOMEN,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.eclipsed?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:ILLUMINANCE,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.moonGlowing?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SANDPOWER,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.sandy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:OVERWHELM,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.rainy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:SUMMITSPIRIT,
  proc { |ability, _user, battle, spAtkMult|
      spAtkMult *= 1.3 if battle.icy?
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:COLDCALCULATION,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.75
      next spAtkMult
  }
)

BattleHandlers::SpecialAttackCalcUserAbility.add(:EXTREMEVOLTAGE,
  proc { |ability, _user, _battle, spAtkMult|
      spAtkMult *= 1.5
      next spAtkMult
  }
)