BattleHandlers::DefenseCalcUserAbility.add(:FLUFFY,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:FURCOAT,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:MARVELSCALE,
    proc { |ability, user, _battle, defenseMult|
        defenseMult *= 1.5 if user.pbHasAnyStatus?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:DESERTARMOR,
    proc { |ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.sandy?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SOLONOCTURNE,
    proc { |ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.moonGlowing?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SAFEPASSAGE,
    proc { |ability, _user, battle, defenseMult|
        defenseMult *= 2 if battle.rainy?
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:STATIC,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:POISONPOINT,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:FLAMEBODY,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:CHILLEDBODY,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:DISORIENT,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:KELPLINK,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)

BattleHandlers::DefenseCalcUserAbility.add(:SOPPING,
    proc { |ability, _user, _battle, defenseMult|
        defenseMult *= 1.2
        next defenseMult
    }
)
