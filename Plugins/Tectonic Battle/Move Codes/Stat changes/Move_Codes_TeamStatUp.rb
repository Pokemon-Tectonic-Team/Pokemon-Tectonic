#===============================================================================
# Raises Attack of user by 3 steps and allies by 1 step. (Howl)
#===============================================================================
class PokeBattle_Move_RaiseUserAtk3AlliesAtk1 < PokeBattle_TeamStatBuffMove
    def initialize(battle, move)
        super
        @statToRaise = :ATTACK
    end
end

# Empowered Howl
class PokeBattle_Move_EmpoweredHowl < PokeBattle_Move_RaiseUserAtk3AlliesAtk1
    include EmpoweredMove

    def pbEffectGeneral(user)
        summonAvatar(user, :POOCHYENA, _INTL("{1} calls out to the pack!", user.pbThis))
        super
        transformType(user, :DARK)
    end
end

#===============================================================================
# Raises Defense of user by 3 steps and allies by 1 step. (Stand Together)
#===============================================================================
class PokeBattle_Move_RaiseUserDef3AlliesAtk1 < PokeBattle_TeamStatBuffMove
    def initialize(battle, move)
        super
        @statToRaise = :DEFENSE
    end
end

# Empowered Stand Together
class PokeBattle_Move_EmpoweredStandTogether < PokeBattle_Move_RaiseUserDef3AlliesAtk1
    include EmpoweredMove

    def pbEffectGeneral(user)
        summonAvatar(user, :TYROGUE, _INTL("{1} joins with an ally!", user.pbThis))
        super
        transformType(user, :FIGHTING)
    end
end

#===============================================================================
# Raises Sp. Atk of user by 3 steps and allies by 1 step. (Mind Link)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk3AlliesSpAtk1 < PokeBattle_TeamStatBuffMove
    def initialize(battle, move)
        super
        @statToRaise = :SPECIAL_ATTACK
    end
end

# Empowered Mind Link
class PokeBattle_Move_EmpoweredMindLink < PokeBattle_Move_RaiseUserSpAtk3AlliesSpAtk1
    include EmpoweredMove

    def pbEffectGeneral(user)
        summonAvatar(user, :ABRA, _INTL("{1} gathers a new mind!", user.pbThis))
        super
        transformType(user, :PSYCHIC)
    end
end

#===============================================================================
# Raises Sp. Def of user and allies by 2 steps. (Symbiosis)
#===============================================================================
class PokeBattle_Move_RaiseUserSpDef3AlliesSpDef1 < PokeBattle_TeamStatBuffMove
    def initialize(battle, move)
        super
        @statToRaise = :SPECIAL_DEFENSE
    end
end

# Empowered Symbiosis
class PokeBattle_Move_EmpoweredSymbiosis < PokeBattle_Move_RaiseUserSpDef3AlliesSpDef1
    include EmpoweredMove

    def pbEffectGeneral(user)
        summonAvatar(user, :GOSSIFLEUR, _INTL("{1} connects with their friend!", user.pbThis))
        super
        transformType(user, :GRASS)
    end
end

#===============================================================================
# Raises the Speed and Accuracy of the user and allies. (Kick Drum)
#===============================================================================
class PokeBattle_Move_RaiseUserAndAlliesSpdAcc1 < PokeBattle_Move
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 1, :ACCURACY, 1]
    end
    
    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        failed = true
        @battle.eachSameSideBattler(user) do |b|
            next unless b.pbCanRaiseAnyOfStats?(@statUp, user, self)
            failed = false
        end
        if failed
            @battle.pbDisplay(_INTL("But it failed, since neither {1} nor any of its allies can receive the stat improvements!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        buffUserAndAllies(user)
    end

    def pbEffectAfterAllHits(user, target)
        return unless damagingMove?
        buffUserAndAllies(user)
    end

    def buffUserAndAllies(user)
        user.pbRaiseMultipleStatSteps(@statUp, user, move: self, showFailMsg: true)
        @battle.eachSameSideBattler(user) do |b|
            next if b.index == user.index
            b.pbRaiseMultipleStatSteps(@statUp, user, move: self, showFailMsg: true)
        end  
    end

    def getEffectScore(user, _target)
        score = 0
        @battle.eachSameSideBattler(user) do |b|
            score += getMultiStatUpEffectScore(@statUp, user, b)
        end
        return score
    end
end