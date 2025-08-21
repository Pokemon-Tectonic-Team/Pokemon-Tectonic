BattleHandlers::AbilityOnEnemySwitchIn.add(:DETERRENT,
    proc { |ability, switcher, bearer, battle|
        battle.pbShowAbilitySplash(bearer, ability)
        if switcher.takesIndirectDamage?(true)
            battle.pbDisplay(_INTL("{1} was attacked on sight!", switcher.pbThis))
            switcher.applyFractionalDamage(1.0 / 8.0)
        end
        battle.pbHideAbilitySplash(bearer)
    }
)

BattleHandlers::AbilityOnEnemySwitchIn.add(:CLAUSTROPHOBIA,
    proc { |ability, switcher, bearer, battle|
        next unless battle.roomActive?
        battle.pbShowAbilitySplash(bearer, ability)
        if switcher.takesIndirectDamage?(true)
            battle.pbDisplay(_INTL("The walls close in on {1}!", switcher.pbThis))
            bTypes = switcher.pbTypes(true)
            getTypedHazardHPRatio = battle.getTypedHazardHPRatio(:PSYCHIC, bTypes[0], bTypes[1], bTypes[2], ratio: 1.0/6.0)
            switcher.applyFractionalDamage(getTypedHazardHPRatio)
        end
        battle.pbHideAbilitySplash(bearer)
    }
)
