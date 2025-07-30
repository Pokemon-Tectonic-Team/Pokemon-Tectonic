PokeBattle_Battle::BattleStartApplyCurse.add(:CURSE_RECYCLING,
    proc { |curse_policy, battle, curses_array|
        battle.amuletActivates(
            _INTL("Eternity in our clutches. Ouroboros ever-yearning."),
            _INTL("Enemy Pokemon recycle consumed items at end of turn. Stolen items turn to dust."),
        )
        curses_array.push(curse_policy)
        next curses_array
    }
)

PokeBattle_Battle::EndOfTurnCurseEffect.add(:CURSE_RECYCLING,
    proc { |curse_policy, battle|
        battle.eachOtherSideBattler do |b|
            b.recycleItem
        end
    }
)