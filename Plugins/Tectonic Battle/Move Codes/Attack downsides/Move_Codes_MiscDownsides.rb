#===============================================================================
# User loses their Fire type. Fails if user is not Fire-type. (Burn Up)
#===============================================================================
class PokeBattle_Move_UserLosesFireType < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.pbHasType?(:FIRE)
            @battle.pbDisplay(_INTL("But it failed, since {1} isn't Fire-type!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAfterAllHits(user, _target)
        user.applyEffect(:BurnUp)
    end

    def getEffectScore(_user, _target)
        return -20
    end
end

#===============================================================================
# User loses their Ice type. Fails if user is not Ice-type. (Sublimate)
#===============================================================================
class PokeBattle_Move_UserLosesIceType < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.pbHasType?(:ICE)
            @battle.pbDisplay(_INTL("But it failed, since {1} is not Ice-type!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAfterAllHits(user, _target)
        user.applyEffect(:Sublimate)
    end

    def getEffectScore(_user, _target)
        return -20
    end
end

#===============================================================================
# Poison's the user, even if normally immune to poison. (Grime Grapple)
#===============================================================================
class PokeBattle_Move_UserIsPoisoned < PokeBattle_Move
    def pbEffectAfterAllHits(user, target)
        return if target.damageState.unaffected
        return if user.poisoned?
        user.applyPoison(nil, _INTL("{1} is poisoned by the grime! {2}",
           user.pbThis, getPoisonExplanation), false)
    end

    def getEffectScore(user, _target)
        return 0 if user.poisoned?
        return -getPoisonEffectScore(user, user, ignoreCheck: true)
    end
end

#===============================================================================
# Move disables self. (Six Feet Under)
#===============================================================================
class PokeBattle_Move_MoveDisablesSelf < PokeBattle_Move
    def pbEffectAfterAllHits(user, _target)
        user.applyEffect(:Disable, 5)
    end

    def getEffectScore(_user, _target)
        return -30
    end
end

#===============================================================================
# Target's speed is raised. (Propellant)
#===============================================================================
class PokeBattle_Move_RaisesTargetSpd1 < PokeBattle_Move
    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.tryRaiseStat(:SPEED, user, move: self)
    end

    def getTargetAffectingEffectScore(user, target)
        return -getMultiStatUpEffectScore([:SPEED, 1], user, target, evaluateThreat: false)
    end
end

#===============================================================================
# Fractures the user, and always critical hits. (Flechettes)
#===============================================================================
class PokeBattle_Move_MoveFracturesSelfCriticalHits < PokeBattle_Move
    def pbEffectAfterAllHits(user, target)
        return if target.damageState.unaffected
        user.applyEffect(:Fracture, DEFAULT_FRACTURE_DURATION)
    end

    def getEffectScore(_user, _target)
        return -30
    end

    def pbCriticalOverride(_user, _target); return 1; end
end

#===============================================================================
# Jinxes the user, and always critical hits. (Divining Talon)
#===============================================================================
class PokeBattle_Move_MoveJinxesSelfCriticalHits < PokeBattle_Move
    def pbEffectAfterAllHits(user, target)
        return if target.damageState.unaffected
        user.applyEffect(:Jinxed, DEFAULT_JINX_DURATION)
    end

    def getEffectScore(_user, _target)
        return -30
    end

    def pbCriticalOverride(_user, _target); return 1; end
end