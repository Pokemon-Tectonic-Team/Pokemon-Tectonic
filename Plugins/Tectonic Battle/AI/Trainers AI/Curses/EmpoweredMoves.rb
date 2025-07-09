PokeBattle_Battle::BattleStartApplyCurse.add(:CURSE_EMPOWERED_MOVES,
    proc { |curse_policy, battle, curses_array|
        battle.amuletActivates(
            _INTL("TO DO: Ask waka to write this"),
            _INTL("Opposing Pokemon may Avatar moves!"),
        )

        curses_array.push(curse_policy)
        next curses_array
    }
)