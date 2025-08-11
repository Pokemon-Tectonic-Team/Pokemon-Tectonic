BattleHandlers::DamageCalcUserAllyAbility.add(:POWERSPOT,
    proc { |ability, user, _target, _move, mults, _baseDmg, _type, aiCheck|
        mults[:final_damage_multiplier] *= 1.3
        user.aiLearnsAbility(ability) unless aiCheck
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:STEELYSPIRIT,
  proc { |ability, user, _target, _move, mults, _baseDmg, type, aiCheck|
        if type == :STEEL
            mults[:base_damage_multiplier] *= 1.5
            user.aiLearnsAbility(ability) unless aiCheck
        end
  }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:VERDANT,
    proc { |ability, user, _target, _move, mults, _baseDmg, type, aiCheck|
        if type == :GRASS
            mults[:base_damage_multiplier] *= 1.5
        end
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:TOXICATTITUDE,
    proc { |ability, user, _target, _move, mults, _baseDmg, type, aiCheck|
        if type == :POISON
            mults[:base_damage_multiplier] *= 1.5
            user.aiLearnsAbility(ability) unless aiCheck
        end
    }
)

BattleHandlers::DamageCalcUserAllyAbility.add(:HIVEMIND,
  proc { |ability, user, _target, _move, mults, _baseDmg, type, aiCheck|
        if type == :BUG
            mults[:base_damage_multiplier] *= 1.5
            user.aiLearnsAbility(ability) unless aiCheck
        end
  }
)