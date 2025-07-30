PokeBattle_Battle::BattleStartApplyCurse.add(:CURSE_FOG_TOTEM,
    proc { |curse_policy, battle, curses_array|
        battle.amuletActivates(
            _INTL("TODO"),
            _INTL("Misdirecting Fog is continually active on the opposing side."),
        )
        curses_array.push(curse_policy)
        next curses_array
    }
)

PokeBattle_Battle::BattlerEnterCurseEffect.add(:CURSE_FOG_TOTEM,
    proc { |_curse_policy, battler, _battle|
        next unless battler.opposes?
        battler.pbOwnSide.applyEffect(:MisdirectingFog, 1000)
    }
)