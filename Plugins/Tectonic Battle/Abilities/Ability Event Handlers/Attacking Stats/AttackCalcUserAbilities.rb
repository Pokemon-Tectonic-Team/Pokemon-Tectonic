BattleHandlers::AttackCalcUserAbility.add(:FLOWERGIFT,
    proc { |ability, user, _battle, attackMult|
        attackMult *= 1.5 if user.battle.sunny?
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:SLOWSTART,
    proc { |ability, user, _battle, attackMult|
        attackMult /= 2 if user.effectActive?(:SlowStart)
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:PRIMEVALSLOWSTART,
  proc { |ability, _user, _battle, attackMult|
      attackMult /= 2
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:GORILLATACTICS,
    proc { |ability, _user, _battle, attackMult|
        attackMult *= 1.5
        next attackMult
    }
)

BattleHandlers::AttackCalcUserAbility.add(:TOUGHCLAWS,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.3
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:TOXICBOOST,
  proc { |ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.poisoned?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:HUGEPOWER,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.copy(:HUGEPOWER, :PUREPOWER)

BattleHandlers::AttackCalcUserAbility.add(:FLUSTERFLOCK,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 2.0
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:PUREFORCE,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:ARCHVILLAIN,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:DEEPSTING,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:BIGTHORNS,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sunny?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SUNCHASER,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sunny?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SLEETSHAKER,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.icy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:LUNATIC,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.moonGlowing?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:NIGHTSTALKER,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.5 if battle.moonGlowing?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FULLMOONBLADE,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 2.0 if battle.fullMoon?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:EARTHSHAKER,
  proc { |ability, _user, battle, attackMult|
      attackMult *= 1.3 if battle.sandy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SLIPSTREAM,
  proc { |ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.pbOwnSide.effectActive?(:Tailwind)
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:ROBUST,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.2
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:MIDDLEWAY,
  proc { |ability, user, _battle, attackMult|
      attackMult *= 1.5 if user.lastRoundMoveCategory == 1
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:SERVEDCOLD,
  proc { |ability, user, battle, attackMult|
      if battle.icy?
        if user.belowHalfHealth?
          attackMult *= 1.4
        else
          attackMult *= 1.2
        end
      end
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FROSTFANGED,
  proc { |ability, user, battle, attackMult|
      attackMult *= 1.3 if battle.icy?
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FEELTHEBURN,
  proc { |ability, user, battle, attackMult|
      attackMult *= 1.75
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:EXTREMEPOWER,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.5
      next attackMult
  }
)

BattleHandlers::AttackCalcUserAbility.add(:FUELHUNGRY,
  proc { |ability, _user, _battle, attackMult|
      attackMult *= 1.3
      next attackMult
  }
)

BattleHandlers::AttackCalcAllyAbility.add(:CASTELLAN,
  proc { |ability, _user, battle, spAtkMult|
      attackMult *= 1.3 if battle.sunny?
      next spAtkMult
  }
)
