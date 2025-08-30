PokeBattle_Battle::BattleStartApplyCurse.add(:CURSE_TYPE_WEAKENED,
    proc { |curse_policy, battle, curses_array|
        battle.amuletActivates(
            _INTL("Thy Inimitability, Incapable Imposture. My Immanence, Inconceivable Immaculacy."),
            _INTL("Your Super Effective attacks become Not Very Effective.")
        )
        curses_array.push(curse_policy)
        next curses_array
    }
)

PokeBattle_Battle::EffectivenessChangeCurseEffect.add(:CURSE_TYPE_WEAKENED,
    proc { |_curse_policy, _moveType, user, target, effectiveness|
        if user.pbOwnedByPlayer? &&
                !target.pbOwnedByPlayer? &&
                Effectiveness.super_effective?(effectiveness)
            next Effectiveness::NOT_VERY_EFFECTIVE
        end
    }
)
