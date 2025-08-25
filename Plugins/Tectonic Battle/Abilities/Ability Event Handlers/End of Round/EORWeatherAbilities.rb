WEATHER_ABILITY_HEALING_FRACTION = 0.125 # 1/8

BattleHandlers::EORWeatherAbility.add(:ICEBODY,
  proc { |ability, weather, battler, battle|
    next unless battle.icy?
      healingMessage = _INTL("{1} incorporates hail into its body.", battler.pbThis)
      battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
  }
)

BattleHandlers::EORWeatherAbility.add(:RAINDISH,
  proc { |ability, _weather, battler, battle|
      next unless battle.rainy?
      healingMessage = _INTL("{1} soaks up the rain.", battler.pbThis)
      battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
  }
)

BattleHandlers::EORWeatherAbility.add(:ROCKBODY,
    proc { |ability, weather, battler, battle|
        next unless battle.sandy?
        healingMessage = _INTL("{1} incorporates sand into its body.", battler.pbThis)
        battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
    }
)

BattleHandlers::EORWeatherAbility.add(:HEATSAVOR,
    proc { |ability, _weather, battler, battle|
        next unless battle.sunny?
        healingMessage = _INTL("{1} soaks up the heat.", battler.pbThis)
        battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
    }
)

BattleHandlers::EORWeatherAbility.add(:EXTREMOPHILE,
    proc { |ability, _weather, battler, battle|
        next unless battle.eclipsed?
        healingMessage = _INTL("{1} revels in the unusual conditions.", battler.pbThis)
        battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
    }
)

BattleHandlers::EORWeatherAbility.add(:NESTING,
    proc { |ability, _weather, battler, battle|
        next if battle.pbWeather == :None
        healingMessage = _INTL("{1} rests in safety.", battler.pbThis)
        battler.applyFractionalHealing(1.0 / 12.0, ability: ability, customMessage: healingMessage)
    }
)

BattleHandlers::EORWeatherAbility.add(:MOONBASKING,
    proc { |ability, _weather, battler, battle|
        next unless battle.moonGlowing?
        healingMessage = _INTL("{1} absorbs the moonlight.", battler.pbThis)
        battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
    }
)

BattleHandlers::EORWeatherAbility.add(:DRYSKIN,
    proc { |ability, _weather, battler, battle|
        if battle.sunny?
            battle.pbShowAbilitySplash(battler, ability)
            battle.pbDisplay(_INTL("{1} was hurt by the sunlight!", battler.pbThis))
            battler.applyFractionalDamage(WEATHER_ABILITY_HEALING_FRACTION)
            battle.pbHideAbilitySplash(battler)
        end
  
        if battle.rainy?
            healingMessage = _INTL("{1} soaks up the rain.", battler.pbThis)
            battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
        end
    }
)
  
BattleHandlers::EORWeatherAbility.add(:FINESUGAR,
    proc { |ability, _weather, battler, battle|
        if battle.rainy?
            battle.pbShowAbilitySplash(battler, ability)
            battle.pbDisplay(_INTL("{1} was hurt by the rain!", battler.pbThis))
            battler.applyFractionalDamage(WEATHER_ABILITY_HEALING_FRACTION)
            battle.pbHideAbilitySplash(battler)
        end
        if battle.sunny?
            healingMessage = _INTL("{1} caramelizes slightly in the heat.", battler.pbThis)
            battler.applyFractionalHealing(WEATHER_ABILITY_HEALING_FRACTION, ability: ability, customMessage: healingMessage)
        end
    }
)

EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION = 0.1 # 1/10

BattleHandlers::EORWeatherAbility.add(:SOLARPOWER,
    proc { |ability, _weather, battler, battle|
        next unless battle.sunny?
        battle.pbShowAbilitySplash(battler, ability)
        battle.pbDisplay(_INTL("{1} was hurt by the sunlight!", battler.pbThis))
        battler.applyFractionalDamage(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION)
        battle.pbHideAbilitySplash(battler)
    }
)
  
BattleHandlers::EORWeatherAbility.add(:NIGHTSTALKER,
    proc { |ability, _weather, battler, battle|
        next unless battle.moonGlowing?
        battle.pbShowAbilitySplash(battler, ability)
        battle.pbDisplay(_INTL("{1} was hurt by the moonlight!", battler.pbThis))
        battler.applyFractionalDamage(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION)
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::EORWeatherAbility.add(:ACIDRAIN,
  proc { |ability, _weather, battler, battle|
        next unless battle.rainy?
        battler.eachOther do |b|
            next unless b.debuffedByRain?
            b.pbLowerMultipleStatSteps(DEFENDING_STATS_1, battler, ability: ability)
        end
  }
)

BattleHandlers::EORWeatherAbility.add(:SUNBURNING,
  proc { |ability, _weather, battler, battle|
        next unless battle.sunny?
        battler.eachOther do |b|
            next unless b.debuffedBySun?
            b.pbLowerMultipleStatSteps(DEFENDING_STATS_1, battler, ability: ability)
        end
  }
)