BattleHandlers::AnyoneAbilityEndOfMove.add(:CELEBRATION,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.applyFractionalHealing(1.0 / 5.0, ability: ability, canOverheal: true)
    }
)

BattleHandlers::AnyoneAbilityEndOfMove.add(:CHOREOGRAPHY,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.pbRaiseMultipleStatSteps([:SPEED, 1], user, ability: ability)
    }
)

BattleHandlers::AnyoneAbilityEndOfMove.add(:GROOVY,
    proc { |ability, battler, user, targets, move, battle|
        next unless move.danceMove?
        battler.pbRaiseMultipleStatSteps(ATTACKING_STATS_1, user, ability: ability)
    }
)