#===============================================================================
# Effectiveness against Dragon-type is 2x. (Slay)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstDragon < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :DRAGON
    end
end

#===============================================================================
# Effectiveness against Electric-type is 2x. (Blackout)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstElectric < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :ELECTRIC
    end
end

#===============================================================================
# Effectiveness against Ghost-type is 2x. (Holly Charm)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstGhost < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :GHOST
    end
end

#===============================================================================
# Effectiveness against Fighting-type is 2x. (Honorless Sting)
#===============================================================================
class PokeBattle_Move_SuperEffectiveAgainstFighting < PokeBattle_TypeSuperMove
    def initialize(battle, move)
        super
        @typeHated = :FIGHTING
    end
end

#===============================================================================
# Type effectiveness is multiplied by the Flying-type's effectiveness against
# the target. (Flying Press)
#===============================================================================
class PokeBattle_Move_EffectivenessIncludesFlyingType < PokeBattle_Move
    def pbCalcTypeModSingle(moveType, defType, user=nil, target=nil)
        ret = super
        if GameData::Type.exists?(:FLYING)
            ret *= Effectiveness.calculate_one(:FLYING, defType)
        end
        return ret
    end
end

#===============================================================================
# Type effectiveness is multiplied by the Psychic-type's effectiveness against
# the target. (Leyline Burst)
#===============================================================================
class PokeBattle_Move_EffectivenessIncludesPsychicType < PokeBattle_Move
    def pbCalcTypeModSingle(moveType, defType, user=nil, target=nil)
        ret = super
        if GameData::Type.exists?(:PSYCHIC)
            ret *= Effectiveness.calculate_one(:PSYCHIC, defType)
        end
        return ret
    end
end