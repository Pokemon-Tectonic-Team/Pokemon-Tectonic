BattleHandlers::FullMoonAbility.add(:LYCANTHROPE,
    proc { |ability, battler, battle|
        next unless battler.species == :LYCANROC
        next unless battler.form == 0
        battle.pbShowAbilitySplash(battler, ability)
        battler.pbChangeForm(1, _INTL("{1}'s transforms with exposure to the Full Moon!", battler.pbThis))
        battle.pbHideAbilitySplash(battler)
    }
)

BattleHandlers::FullMoonAbility.add(:WANINGWILLPOWER,
    proc { |ability, battler, battle|
        battle.pbShowAbilitySplash(battler, ability)
        battle.pbDisplay(_INTL("{1} steals the energy from its moonstruck enemies!", battler.pbThis))
        battle.eachOtherSideBattler(battler) do |b|
            b.applyLeeched if b.canLeech?(battler, true) && b.flinchedByMoonglow?
        end
        battle.pbHideAbilitySplash(battler)
    }
)