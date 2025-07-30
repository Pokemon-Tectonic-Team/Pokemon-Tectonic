BattleHandlers::MoveSpeedModifierAbility.add(:MAESTRO,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.soundMove?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:GALEWINGS,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.type == :FLYING
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:TRENCHCARVER,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.recoilMove?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:SWIFTSTOMPS,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.kickingMove?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:SHARPSHOOTER,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.canRandomCrit?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:HOPPINGMAD,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.rampagingMove?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

BattleHandlers::MoveSpeedModifierAbility.add(:CELERITAS,
    proc { |ability, battler, move, battle, mult, aiCheck|
        next unless (aiCheck && move.nil?) || move.lightMove?
        if aiCheck
            next mult * 2.0
        else
            battler.applyEffect(:MoveSpeedDoubled,ability)
        end
    }
)

# Create the 2nd half of every ability above
# Actually incorporate the doubled speed in the speed calculations
BattleHandlers::MoveSpeedModifierAbility.eachKey do |abilityID|
    BattleHandlers::SpeedCalcAbility.add(abilityID,
        proc { |ability, battler, mult|
            next unless battler.effectActive?(:MoveSpeedDoubled)
            next mult * 2 if battler.effects[:MoveSpeedDoubled] == ability
        }
    )
end