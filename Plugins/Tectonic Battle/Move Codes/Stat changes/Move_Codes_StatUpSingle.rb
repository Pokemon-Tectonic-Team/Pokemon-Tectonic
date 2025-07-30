#===============================================================================
# Increases the user's Attack by 1 step.
#===============================================================================
class PokeBattle_Move_RaiseUserAtk1 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 1]
    end
end

# Empowered Metal Claw
class PokeBattle_Move_EmpoweredMetalClaw < PokeBattle_Move_RaiseUserAtk1
    include EmpoweredMove

    def multiHitMove?; return true; end
    def pbNumHits(_user, _targets, _checkingForAI = false); return 2; end
end

#===============================================================================
# Increases the user's Attack by 2 step.
#===============================================================================
class PokeBattle_Move_RaiseUserAttack2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2]
    end
end

# Empowered Meteor Mash
class PokeBattle_Move_EmpoweredMeteorMash < PokeBattle_Move_RaiseUserAttack2
    include EmpoweredMove
end

#===============================================================================
# Summons Moonglow for 8 turns. Raises the Attack of itself by 2 steps. (Midnight Hunt)
#===============================================================================
class PokeBattle_Move_RaiseUserAndAlliesAtk2StartMoonglow8 < PokeBattle_Move_RaiseUserAttack2
    def pbMoveFailed?(user, _targets, show_message)
        return false unless @battle.primevalWeatherPresent?(false)
        super
    end

    def pbEffectGeneral(user)
        @battle.pbStartWeather(user, :Moonglow, 8, false) unless @battle.primevalWeatherPresent?
        super
    end

    def getEffectScore(user, _target)
        score = super
        score += getWeatherSettingEffectScore(:Moonglow, user, @battle, 8)
        return score
    end
end

#===============================================================================
# Increases the user's Attack by 3 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserAtk3 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 3]
    end
end

#===============================================================================
# Increases the user's Attack by 4 steps. (Swords Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserAtk4 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 4]
    end
end

# Empowered Swords Dance
class PokeBattle_Move_EmpoweredSwordsDance < PokeBattle_Move_RaiseUserAtk4
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        # TODO
        transformType(user, :STEEL)
    end
end

#===============================================================================
# Increases the user's Attack by 5 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserAtk5 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 5]
    end
end

#===============================================================================
# Increases the user's Defense by 1 step.
#===============================================================================
class PokeBattle_Move_RaiseUserDef1 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:DEFENSE, 1]
    end
end

#===============================================================================
# Increases the user's Defense by 2 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserDef2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:DEFENSE, 2]
    end
end

#===============================================================================
# Increases the user's Defense by 3 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserDef3 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:DEFENSE, 3]
    end
end

#===============================================================================
# Increases the user's Defense by 4 steps. (Barrier, Iron Defense)
#===============================================================================
class PokeBattle_Move_RaiseUserDef4 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:DEFENSE, 4]
    end
end

# Empowered Iron Defense
class PokeBattle_Move_EmpoweredIronDefense < PokeBattle_Move_RaiseUserDef4
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.addAbility(:FILTER,true)
        transformType(user, :STEEL)
    end
end

#===============================================================================
# Increases the user's Defense by 5 steps. (Cotton Guard)
#===============================================================================
class PokeBattle_Move_RaiseUserDefense5 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:DEFENSE, 5]
    end	
end

#===============================================================================
# Increases the user's Speed by 1 step.
#===============================================================================
class PokeBattle_Move_RaiseUserSpd1 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 1]
    end
end

#===============================================================================
# Increases the user's Speed by 2 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpd2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 2]
    end
end

class PokeBattle_Move_EmpoweredBulletTrain < PokeBattle_Move_RaiseUserSpd2  
    include EmpoweredMove  
end

#===============================================================================
# Increases the user's Speed by 3 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpd3 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 3]
    end
end

#===============================================================================
# Increases the user's Speed by 4 steps. (Agility, Rock Polish)
#===============================================================================
class PokeBattle_Move_RaiseUserSpd4 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 4]
    end

    def getEffectScore(user, target)
        score = super
        score += 40 if user.hasActiveAbilityAI?(:STAMPEDE)
        return score
    end
end

# Empowered Bullet Train

# Empowered Rock Polish
class PokeBattle_Move_EmpoweredRockPolish < PokeBattle_StatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:SPEED, 6]
    end

    def pbEffectGeneral(user)
        super
        craftItem(user,:ROCKGEM)
        transformType(user, :ROCK)
    end
end

#===============================================================================
# The user's Speed raises 4 steps, and it gains the Flying-type. (Mach Flight)
#===============================================================================
class PokeBattle_Move_RaiseUserSpd4GainFlyingType < PokeBattle_Move_RaiseUserSpd4
    def pbMoveFailed?(user, targets, show_message)
        return false if GameData::Type.exists?(:FLYING) && !user.pbHasType?(:FLYING) && user.canChangeType?
        super
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:Type3, :FLYING)
    end
end

#===============================================================================
# Increases the user's Speed by 5 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpd5 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 5]
    end

    def getEffectScore(user, target)
        score = super
        score += 50 if user.hasActiveAbilityAI?(:STAMPEDE)
        return score
    end
end

#===============================================================================
# Increases the user's Sp. Atk by 1 step.
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk1 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 1]
    end
end

#===============================================================================
# Increases the user's Sp. Atk by 2 step.
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2]
    end
end

#===============================================================================
# Increases the user's Sp. Atk by 3 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk3 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 3]
    end
end

#===============================================================================
# Increases the user's Special Attack by 4 steps. (Dream Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk4 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 4]
    end
end

# Empowered Dream Dance
class PokeBattle_Move_EmpoweredDreamDance < PokeBattle_Move_RaiseUserSpAtk4
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        # TODO
        transformType(user, :FAIRY)
    end
end

#===============================================================================
# Increases the user's Special Attack by 5 steps. (Tail Glow)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk5 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 5]
    end
end

#===============================================================================
# Increases the user's Sp. Def by 1 step.
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef1 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_DEFENSE, 1]
    end
end

#===============================================================================
# Increases the user's Sp. Def by 2 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_DEFENSE, 2]
    end
end

#===============================================================================
# Increases the user's Sp. Def by 3 steps.
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef3 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_DEFENSE, 3]
    end
end

#===============================================================================
# Increases the user's Special Defense by 4 steps. (Amnesia)
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef4 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_DEFENSE, 4]
    end
end

# Empowered Amnesia
class PokeBattle_Move_EmpoweredAmnesia < PokeBattle_Move_RaiseUserSpDef4
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.addAbility(:UNAWARE,true)
        transformType(user, :PSYCHIC)
    end
end

#===============================================================================
# Increases the user's Sp. Def by 5 steps. (Mucus Armor)
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef5 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_DEFENSE, 5]
    end	
end

#===============================================================================
# Increases the user's critical hit rate by one increment.
#===============================================================================
class PokeBattle_Move_RaiseCriticalHitRate1 < PokeBattle_Move_RaiseCriticalHitRate
    def initialize(battle, move)
        super
        @critStages = 1
    end	
end

#===============================================================================
# Increases the user's critical hit rate by two increments.
#===============================================================================
class PokeBattle_Move_RaiseCriticalHitRate2 < PokeBattle_Move_RaiseCriticalHitRate
    def initialize(battle, move)
        super
        @critStages = 2
    end	
end

#===============================================================================
# Increases the user's critical hit rate by three increments.
#===============================================================================
class PokeBattle_Move_RaiseCriticalHitRate3 < PokeBattle_Move_RaiseCriticalHitRate
    def initialize(battle, move)
        super
        @critStages = 3
    end	
end

#===============================================================================
# Increases the user's critical hit rate by four increments.
#===============================================================================
class PokeBattle_Move_RaiseCriticalHitRate4 < PokeBattle_Move_RaiseCriticalHitRate
    def initialize(battle, move)
        super
        @critStages = 4
    end	
end

#===============================================================================
# Maximizes accuracy. (Aim True)
#===============================================================================
class PokeBattle_Move_MaxUserAcc < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        return !user.pbCanRaiseStatStep?(:ACCURACY, user, self, show_message)
    end

    def pbEffectGeneral(user)
        user.pbMaximizeStatStep(:ACCURACY, user, self)
    end

    def getEffectScore(user, _target)
        score = 60
        score -= (user.steps[:ACCURACY] - 6) * 10
        score += 20 if user.hasInaccurateMove?
        score += 40 if user.hasLowAccuracyMove?
        return score
    end
end

#===============================================================================
# If the move misses, the user gains Accuracy. (Rockapult)
#===============================================================================
class PokeBattle_Move_RaiseUserAccIfMisses < PokeBattle_Move
    # This method is called if a move fails to hit all of its targets
    def pbCrashDamage(user)
        return unless user.tryRaiseStat(:ACCURACY, user, move: self)
        @battle.pbDisplay(_INTL("{1} adjusted its aim!", user.pbThis))
    end

    def getEffectScore(user, _target)
        return getMultiStatUpEffectScore([:ACCURACY, 1], user, user) * 0.5
    end
end

#===============================================================================
# Changes Category based on which will deal more damage. (Everhone)
# Raises the stat that wasn't selected to be used.
#===============================================================================
class PokeBattle_Move_CategoryDependsOnHigherDamageRaisesUserOtherAttackingStat < PokeBattle_Move
    def initialize(battle, move)
        super
        @category_override = 1
    end

    def calculateCategoryOverride(user, targets)
        return selectBestCategory(user, targets[0])
    end

    def pbAdditionalEffect(user, _target)
        if @category_override == 0
            return user.tryRaiseStat(:SPECIAL_ATTACK, user, increment: 1, move: self)
        else
            return user.tryRaiseStat(:ATTACK, user, increment: 1, move: self)
        end
    end

    def getEffectScore(user, target)
        expectedCategory = selectBestCategory(user, target)
        if expectedCategory == 0
            return getMultiStatUpEffectScore([:SPECIAL_ATTACK, 1], user, user)
        else
            return getMultiStatUpEffectScore([:ATTACK, 1], user, user)
        end
    end
end