BattleHandlers::GuaranteedCriticalUserAbility.add(:MERCILESS,
    proc { |ability, _user, target, _battle|
        next true if target.poisoned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:HARSH,
    proc { |ability, _user, target, _battle|
        next true if target.burned?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:BITTER,
    proc { |ability, _user, target, _battle|
        next true if target.frostbitten?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:SEVERE,
    proc { |ability, _user, target, _battle|
        next true if target.numbed?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:WALLNINJA,
    proc { |ability, user, _target, _battle|
        next true if user.battle.roomActive?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:BREAKINGWAVE,
    proc { |ability, user, _target, _battle|
        next true if user.turnCount <= 1
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:LURING,
    proc { |ability, _user, target, _battle|
        next true if target.dizzy?
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:PERFECTLUCK,
    proc { |ability, _user, target, _battle|
        next true
    }
)

BattleHandlers::GuaranteedCriticalUserAbility.add(:COLDBLOODED,
    proc { |ability, _user, target, _battle|
        next true if target.waterlogged?
    }
)