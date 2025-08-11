BattleHandlers::SpeedCalcAbility.add(:CHLOROPHYLL,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.sunny?
  }
)

BattleHandlers::SpeedCalcAbility.add(:QUICKFEET,
  proc { |ability, battler, mult|
      next mult * 2.0 if battler.pbHasAnyStatus?
  }
)

BattleHandlers::SpeedCalcAbility.add(:HYPERSPEED,
  proc { |ability, battler, mult|
      next mult * 2.0
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDRUSH,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLOWSTART,
  proc { |ability, battler, mult|
      next mult / 2 if battler.effectActive?(:SlowStart)
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUSHRUSH,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SWIFTSWIM,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:CLOUDBURST,
  proc { |ability, battler, mult|
      next mult * 1.3 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:DEBRISFIELD,
  proc { |ability, battler, mult|
      next mult * 1.3 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:UNBURDEN,
  proc { |ability, battler, mult|
      next mult * 2 if battler.effectActive?(:ItemLost) && !battler.hasAnyItem?
  }
)

BattleHandlers::SpeedCalcAbility.add(:FEROCIOUS,
  proc { |ability, battler, mult|
      active = false
      battler.eachOpposing do |b|
          next unless b.belowHalfHealth?
          active = true
          break
      end
      mult *= 2 if active
      next mult
  }
)

BattleHandlers::SpeedCalcAbility.add(:PRIMEVALSLOWSTART,
  proc { |ability, _battler, mult|
      next mult / 2
  }
)

BattleHandlers::SpeedCalcAbility.add(:EXOTHERMENGINE,
  proc { |ability, _battler, mult|
      next mult * 1.5
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIGHTTRICK,
  proc { |ability, battler, mult|
      active = false
      battler.eachOpposing do |b|
          next unless b.pbHasAnyStatus?
          active = true
          break
      end
      mult *= 2 if active
      next mult
  }
)

BattleHandlers::SpeedCalcAbility.add(:ANARCHIC,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.eclipsed?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTLIFE,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTVISION,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDWORNAUGER,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:NIGHTOWL,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.moonGlowing?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SANDSNIPER,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.sandy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:TAIGATREKKER,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:FROSTFANGED,
  proc { |ability, battler, mult|
      next mult * 1.3 if battler.battle.icy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIGHTNINGRIDE,
  proc { |ability, battler, mult|
      next mult * 2.0 if battler.effectActive?(:EnergyCharge)
  }
)

BattleHandlers::SpeedCalcAbility.add(:METEORIC,
  proc { |ability, battler, mult|
      next mult * 1.5 if %i[Sandstorm Hail].include?(battler.battle.pbWeather)
  }
)

BattleHandlers::SpeedCalcAbility.add(:SLUGGISH,
  proc { |ability, battler, mult|
      next mult / 2.0
  }
)

BattleHandlers::SpeedCalcAbility.add(:LIVEFAST,
  proc { |ability, battler, mult|
      next mult * 1.5
  }
)

BattleHandlers::SpeedCalcAbility.add(:WATERFALLCONDITIONING,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:SILVERLINING,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.rainy?
  }
)

BattleHandlers::SpeedCalcAbility.add(:DYNAMICENTRANCE,
  proc { |ability, battler, mult|
      next mult * 2.0 if battler.firstTurn?
  }
)

BattleHandlers::SpeedCalcAbility.add(:FOREMAN,
  proc { |ability, battler, mult|
      next mult * 2 if battler.battle.roomActive?
  }
)

BattleHandlers::SpeedCalcAbility.add(:TEATIME,
  proc { |ability, battler, mult|
      next mult * 1.5 if battler.battle.icy?
  }
)