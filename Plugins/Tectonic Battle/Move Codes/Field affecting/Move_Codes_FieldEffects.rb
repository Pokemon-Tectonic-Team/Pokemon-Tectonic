#===============================================================================
# For 4 rounds, doubles the Speed of all battlers on the user's side. (Tailwind)
#===============================================================================
class PokeBattle_Move_StartUserSideDoubleSpeed4 < PokeBattle_Move
    def initialize(battle, move)
        super
        @tailwindDuration = 4
    end

    def pbEffectGeneral(user)
        user.pbOwnSide.applyEffect(:Tailwind, @tailwindDuration)
    end

    def getEffectScore(user, _target)
        return getTailwindEffectScore(user, @tailwindDuration, self)
    end
end

# Empowered Tailwind
class PokeBattle_Move_EmpoweredTailwind < PokeBattle_Move_StartUserSideDoubleSpeed4
    include EmpoweredMove

    def initialize(battle, move)
        super
        @tailwindDuration = 6
    end

    def pbEffectGeneral(user)
        user.pbOwnSide.applyEffect(:EmpoweredTailwind, @tailwindDuration)
        transformType(user, :FLYING)
    end

    def getEffectScore(user, _target)
        score = getTailwindEffectScore(user, @tailwindDuration, self)
        score *= 1.5
        return score
    end
end

#===============================================================================
# For 6 rounds, doubles the Speed of all battlers on the user's side. (Sustained Wind)
#===============================================================================
class PokeBattle_Move_StartUserSideDoubleSpeed6 < PokeBattle_Move_StartUserSideDoubleSpeed4
    def initialize(battle, move)
        super
        @tailwindDuration = 6
    end
end

#===============================================================================
# For 5 rounds, increases gravity on the field. Pokémon cannot become airborne.
# (Gravity)
#===============================================================================
class PokeBattle_Move_StartGravity5 < PokeBattle_Move
    def initialize(battle, move)
        super
        @gravityDuration = 5
    end

    def pbEffectGeneral(_user)
        @battle.field.applyEffect(:Gravity, @gravityDuration)
    end

    def getEffectScore(user, _target)
        return getGravityEffectScore(user, @gravityDuration)
    end
end

# Empowered Gravity
class PokeBattle_Move_EmpoweredGravity < PokeBattle_Move_StartGravity5
    def pbEffectGeneral(user)
        super
        user.eachOpposing do |b|
            battle.pbDisplay(_INTL("{1} was slammed into the ground!", user.pbThis))
            b.applyFractionalDamage(1.0/4.0)
        end
    end
end

#===============================================================================
# Heals every active battler by 1/8th of their HP for the next 5 turns. (Floral Gramarye)
#===============================================================================
class PokeBattle_Move_StartAllBattlersHealEightOfMaxHPEachTurn5 < PokeBattle_Move
    def pbEffectGeneral(_user)
        @battle.field.applyEffect(:FloralGramarye, 5) unless @battle.field.effectActive?(:FloralGramarye)
    end

    def pbMoveFailed?(_user, _targets, show_message)
        return false if damagingMove?
        if @battle.field.effectActive?(:FloralGramarye)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since the field is already covered in flowers!"))
            end
            return true
        end
        return false
    end

    def getEffectScore(user, _target)
        return 100
    end
end



#===============================================================================
# Resets all stat steps at end of turn and at the end of the next four turns. (Grey Mist)
#===============================================================================
class PokeBattle_Move_StartGreyMist5 < PokeBattle_Move
    def initialize(battle, move)
        super
        @greyMistDuration = 5
    end

    def pbEffectGeneral(_user)
        @battle.field.applyEffect(:GreyMist, @greyMistDuration) unless @battle.field.effectActive?(:GreyMist)
    end

    def pbMoveFailed?(_user, _targets, show_message)
        return false if damagingMove?
        if @battle.field.effectActive?(:GreyMist)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since the field is already shrouded in Grey Mist!"))
            end
            return true
        end
        return false
    end

    def getEffectScore(user, _target)
        return getGreyMistSettingEffectScore(user,@greyMistDuration)
    end
end

# Empowered Grey Mist
class PokeBattle_Move_EmpoweredGreyMist < PokeBattle_Move_StartGreyMist5
    include EmpoweredMove

    def initialize(battle, move)
        super
        @greyMistDuration = 8
    end

    def pbEffectGeneral(user)
        super
        craftItem(user,:BLACKSLUDGE)
        transformType(user, :POISON)
    end
end

#===============================================================================
# Summons both hail and grey mist for 5 turns. (Diamond Dust)
#===============================================================================
class PokeBattle_Move_StartGreyMist5StartHail5 < PokeBattle_Move_StartGreyMist5
    def pbMoveFailed?(user, _targets, show_message)
        return false
    end

    def pbEffectGeneral(user)
        super
        @battle.pbStartWeather(user, :Hail, 5, false) unless @battle.primevalWeatherPresent?
    end
end

#===============================================================================
# Reduces the damage the user's side takes from non-attack sources of damage
# for 8 turns.
# (Natural Protection)
#===============================================================================
class PokeBattle_Move_StartUserSideLessDamageFromNonAttackDamage < PokeBattle_Move
    def initialize(battle, move)
        super
        @enchantmentDuration = 8
    end

    def pbEffectGeneral(user)
        user.pbOwnSide.applyEffect(:NaturalProtection, @enchantmentDuration)
    end

    def getEffectScore(user, _target)
        return getNaturalProtectionEffectScore(user, @enchantmentDuration)
    end
end