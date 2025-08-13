#===============================================================================
# This attack is always a critical hit. (Frost Breath, Storm Throw)
#===============================================================================
class PokeBattle_Move_AlwaysCriticalHit < PokeBattle_Move
    def pbCriticalOverride(_user, _target); return 1; end
end

# Empowered Slash
class PokeBattle_Move_EmpoweredSlash < PokeBattle_Move_AlwaysCriticalHit
    include EmpoweredMove
end

#===============================================================================
# Always hits.
#===============================================================================
class PokeBattle_Move_AlwaysHits < PokeBattle_Move
    def pbAccuracyCheck(_user, _target); return true; end
end

#===============================================================================
# This move ignores target's Defense, Special Defense and evasion stat changes.
# (Chip Away, Darkest Lariat, Sacred Sword)
#===============================================================================
class PokeBattle_Move_IgnoreTargetDefSpDefEvaStatStages < PokeBattle_Move
    def pbCalcAccuracyMultipliers(user, target, multipliers)
        super
        modifiers[:evasion_step] = 0
    end

    def ignoresDefensiveStepBoosts?(_user, _target); return true; end

    def shouldHighlight?(_user, target)
        return target.hasRaisedDefenseSteps?
    end
end

#===============================================================================
# Ends target's protections immediately. (Feint)
#===============================================================================
class PokeBattle_Move_RemoveProtections < PokeBattle_Move
    def pbEffectAgainstTarget(_user, target)
        removeProtections(target)
    end
end

#===============================================================================
# Always hits. Ends target's protections immediately. (Hyperspace Hole)
#===============================================================================
class PokeBattle_Move_RemoveProtectionsBypassSubstituteAlwaysHits < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end
    def pbAccuracyCheck(_user, _target); return true; end

    def pbEffectAgainstTarget(_user, target)
        removeProtections(target)
    end
end

#===============================================================================
# Decreases the user's Defense by 1 step. Always hits. Ends target's
# protections immediately. (Hyperspace Fury)
#===============================================================================
class PokeBattle_Move_HyperspaceFury < PokeBattle_StatDownMove
    def ignoresSubstitute?(_user); return true; end

    def initialize(battle, move)
        super
        @statDown = [:DEFENSE, 2]
    end

    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:HOOPA)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        elsif user.form != 1
            @battle.pbDisplay(_INTL("But {1} can't use it the way it is now!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbAccuracyCheck(_user, _target); return true; end

    def pbEffectAgainstTarget(_user, target)
        removeProtections(target)
    end
end

#===============================================================================
# Ends the opposing side's screen effects. (Brick Break, Psychic Fangs)
#===============================================================================
class PokeBattle_Move_RemoveScreens < PokeBattle_Move
    def ignoresReflect?; return true; end
    def screenRemovalMove?; return true; end

    def pbEffectWhenDealingDamage(_user, target)
        side = target.pbOwnSide
        side.eachEffect(true) do |effect, _value, data|
            side.disableEffect(effect) if data.is_screen?
        end
    end

    def sideHasScreens?(side)
        side.eachEffect(true) do |_effect, _value, data|
            return true if data.is_screen?
        end
        return false
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        targets.each do |b|
            next unless sideHasScreens?(b.pbOwnSide)
            hitNum = 1 # Wall-breaking anim
            break
        end
        super
    end

    def getEffectScore(_user, target)
        score = 0
        target.pbOwnSide.eachEffect(true) do |effect, value, data|
            next unless data.is_screen?
			case value
				when 2
					score += 30
				when 3
					score += 50
				when 4..999
					score += 130
            end	
        end
        return score
    end

    def shouldHighlight?(_user, target)
        return sideHasScreens?(target.pbOwnSide)
    end
end

# Empowered Brick Break
class PokeBattle_Move_EmpoweredBrickBreak < PokeBattle_TargetStatDownMove
    include EmpoweredMove

    def ignoresReflect?; return true; end

    def pbEffectGeneral(user)
        user.pbOpposingSide.eachEffect(true) do |effect, _value, data|
            user.pbOpposingSide.disableEffect(effect) if data.is_screen?
        end
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        user.pbOpposingSide.eachEffect(true) do |_effect, _value, data|
            # Wall-breaking anim
            hitNum = 1 if data.is_screen?
        end
        super
    end

    def initialize(battle, move)
        super
        @statDown = [:DEFENSE, 5]
    end
end

#===============================================================================
# Ends target's protections, screens, and substitute immediately. (Siege Breaker)
#===============================================================================
class PokeBattle_Move_RemoveScreensSubstituteProtections < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end
    def ignoresReflect?; return true; end
    def screenRemovalMove?; return true; end
    
    def pbEffectAgainstTarget(_user, target)
        removeProtections(target)
        target.disableEffect(:Substitute)
    end

    def pbEffectWhenDealingDamage(_user, target)
        side = target.pbOwnSide
        side.eachEffect(true) do |effect, _value, data|
            side.disableEffect(effect) if data.is_screen?
        end
    end

    def sideHasScreens?(side)
        side.eachEffect(true) do |_effect, _value, data|
            return true if data.is_screen?
        end
        return false
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        targets.each do |b|
            next unless sideHasScreens?(b.pbOwnSide)
            hitNum = 1 # Wall-breaking anim
            break
        end
        super
    end

    def getEffectScore(_user, target)
        score = 0
        target.pbOwnSide.eachEffect(true) do |effect, value, data|
            next unless data.is_screen?
			case value
				when 2
					score += 30
				when 3
					score += 50
				when 4..999
					score += 130
            end	
        end
        score += 20 if target.substituted?
        return score
    end

    def shouldHighlight?(_user, target)
        return true if sideHasScreens?(target.pbOwnSide)
        return true if target.substituted?
        return false
    end
end

#===============================================================================
# Ignores all abilities that alter this move's success or damage.
# (Moongeist Beam, Sunsteel Strike)
#===============================================================================
class PokeBattle_Move_IgnoreTargetAbility < PokeBattle_Move
    def pbChangeUsageCounters(user, specialUsage)
        super
        @battle.moldBreaker = true unless specialUsage
    end
end

#===============================================================================
# This move ignores target's Defense, Special Defense and evasion stat changes.
# It also ignores their abilities. (Rend)
#===============================================================================
class PokeBattle_Move_IgnoreTargetDefSpDefEvaStatStagesAndTargetAbility < PokeBattle_Move
    def pbChangeUsageCounters(user, specialUsage)
        super
        @battle.moldBreaker = true unless specialUsage
    end

    def pbCalcAccuracyMultipliers(user, target, multipliers)
        super
        modifiers[EVA_STEP] = 0 # Accuracy stat step
    end

    def ignoresDefensiveStepBoosts?(_user, _target); return true; end

    def getEffectScore(_user, _target)
        return 10
    end

    def shouldHighlight?(_user, target)
        return target.hasRaisedDefenseSteps?
    end
end

#===============================================================================
# Ignores move redirection from abilities and moves. (Snipe Shot)
#===============================================================================
class PokeBattle_Move_CannotBeRedirected < PokeBattle_Move
    def cannotRedirect?; return true; end
end