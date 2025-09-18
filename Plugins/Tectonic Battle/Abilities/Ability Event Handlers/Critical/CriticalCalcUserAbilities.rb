BattleHandlers::CriticalCalcUserAbility.add(:SUPERLUCK,
  proc { |ability, _user, _target, _move, c|
      next c + 2
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SNIPER,
  proc { |ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SHARPSHOOTER,
  proc { |ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:STAMPEDE,
  proc { |ability, user, _target, _move, c|
      next 0 if user.steps[:SPEED] <= 0
      next c + user.steps[:SPEED]
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RAZORSEDGE,
  proc { |ability, _user, _target, move, c|
      next c + 1 if move.bladeMove?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:NIGHTVISION,
  proc { |ability, user, _target, _move, c|
      next c + 1 if user.battle.moonGlowing?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SANDWORNAUGER,
  proc { |ability, user, _target, _move, c|
      next c + 1 if user.battle.sandy?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SPECTRUMVISION,
  proc { |ability, user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SILVERSENSE,
  proc { |ability, _user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:VICTORYSTAR,
  proc { |ability, user, _target, _move, c|
      next c + 1
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:CAFFEINERUSH,
  proc { |ability, user, _target, _move, c|
      next c + 1 if user.battle.icy?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RELUCTANTWARRIOR,
  proc { |ability, user, _target, _move, c|
      next c + 1 if user.belowHalfHealth?
      next c
  }
)