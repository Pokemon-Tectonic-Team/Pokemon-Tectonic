#===============================================================================
# IsUnconditional
#===============================================================================
BallHandlers::IsUnconditional.add(:MASTERBALL, proc { |_ball, _battle, _battler|
    next true
})

BallHandlers::IsUnconditional.copy(:MASTERBALL,:RADIANTBALL)

#===============================================================================
# ModifyCatchRate
# NOTE: This code is not called if the battler is an Ultra Beast (except if the
#       Ball is a Beast Ball). In this case, all Balls' catch rates are set
#       elsewhere to 0.1x.
#===============================================================================
BallHandlers::ModifyCatchRate.add(:GREATBALL, proc { |_ball, catchRate, _battle, _battler|
    next catchRate * 1.5
})

BallHandlers::ModifyCatchRate.add(:ULTRABALL, proc { |_ball, catchRate, _battle, _battler|
    next catchRate * 2
})

BallHandlers::ModifyCatchRate.add(:SAFARIBALL, proc { |_ball, catchRate, _battle, _battler|
    next catchRate * 1.5
})

BallHandlers::ModifyCatchRate.add(:NETBALL, proc { |_ball, catchRate, _battle, battler|
    multiplier = 3.5
    catchRate *= multiplier if battler.pbHasType?(:BUG) || battler.pbHasType?(:WATER)
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:DIVEBALL, proc { |_ball, catchRate, battle, _battler|
    catchRate *= 3.5 if battle.environment == :Underwater
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:REPEATBALL, proc { |_ball, catchRate, battle, battler|
    multiplier = 3.5
    catchRate *= multiplier if battle.pbPlayer.owned?(battler.species)
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:TIMERBALL, proc { |_ball, catchRate, battle, _battler|
    multiplier = [1 + (0.3 * battle.turnCount), 4].min
    catchRate *= multiplier
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:DUSKBALL, proc { |_ball, catchRate, battle, _battler|
    multiplier = 3
    catchRate *= multiplier if battle.time == 2
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:QUICKBALL, proc { |_ball, catchRate, battle, _battler|
    catchRate *= 3 if battle.turnCount == 0
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:FASTBALL, proc { |_ball, catchRate, _battle, battler|
    baseStats = battler.pokemon.baseStats
    baseSpeed = baseStats[:SPEED]
    catchRate *= 4 if baseSpeed >= 100
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:LEVELBALL, proc { |_ball, catchRate, battle, battler|
    maxlevel = 0
    battle.eachSameSideBattler do |b|
        maxlevel = b.level if b.level > maxlevel
    end
    if maxlevel >= battler.level * 4
        catchRate *= 8
    elsif maxlevel >= battler.level * 2
        catchRate *= 4
    elsif maxlevel > battler.level
        catchRate *= 2
    end
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:LUREBALL, proc { |_ball, catchRate, _battle, _battler|
    multiplier = 5
    catchRate *= multiplier if GameData::EncounterType.get($PokemonTemp.encounterType).type == :fishing
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:HEAVYBALL, proc { |_ball, catchRate, _battle, battler|
    next 0 if catchRate == 0
    weight = battler.pbWeight
    if weight >= 3000;    catchRate += 30
    elsif weight >= 2000; catchRate += 20
    elsif weight < 1000;  catchRate -= 20
    end
    catchRate = [catchRate, 1].max
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:LOVEBALL, proc { |_ball, catchRate, battle, battler|
    battle.eachSameSideBattler do |b|
        next if b.species != battler.species
        next if b.gender == battler.gender || b.gender == 2 || battler.gender == 2
        catchRate *= 8
        break
    end
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:MOONBALL, proc { |_ball, catchRate, _battle, battler|
    # NOTE: Moon Ball cares about whether any species in the target's evolutionary
    #       family can evolve with the Moon Stone, not whether the target itself
    #       can immediately evolve with the Moon Stone.
    moon_stone = GameData::Item.try_get(:MOONSTONE)
    catchRate *= 4 if moon_stone && battler.pokemon.species_data.family_item_evolutions_use_item?(moon_stone.id)
    next [catchRate, 255].min
})

BallHandlers::ModifyCatchRate.add(:SPORTBALL, proc { |_ball, catchRate, _battle, _battler|
    next catchRate * 1.5
})

BallHandlers::ModifyCatchRate.add(:DREAMBALL, proc { |_ball, catchRate, _battle, battler|
    catchRate *= 4 if battler.status == :SLEEP
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:BEASTBALL, proc { |_ball, catchRate, _battle, battler|
    catchRate *= 5 if battler.pokemon.species_data.isUltraBeast?
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:NESTBALL, proc { |_ball, catchRate, _battle, battler|
    if LEVEL_CAPS_USED
        baseLevel = getLevelCap - 5
        if battler.level <= baseLevel
            catchRate *= [(11 + baseLevel - battler.level) / 10.0, 1].max
        end
    elsif battler.level <= 30
        catchRate *= [(41 - battler.level) / 10.0, 1].max
    end
    next catchRate
})

BallHandlers::ModifyCatchRate.add(:ROYALBALL, proc { |_ball, catchRate, _battle, _battler|
    next catchRate * 0.5
})