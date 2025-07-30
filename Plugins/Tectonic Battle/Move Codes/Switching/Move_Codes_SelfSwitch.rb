#===============================================================================
# Switches out. (Teleport)
#===============================================================================
class PokeBattle_Move_SwitchOutUserStatusMove < PokeBattle_Move
    def switchOutMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless @battle.pbCanChooseNonActive?(user.index)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no party members to replace it!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if user.fainted?
        switchOutUser(user)
    end

    def getEffectScore(user, target)
        score = getSwitchOutEffectScore(user)
        score += 20
        return score
    end
end

#===============================================================================
# User switches out. Various effects affecting the user are passed to the
# replacement. (Baton Pass)
#===============================================================================
class PokeBattle_Move_SwitchOutUserPassOnEffects < PokeBattle_Move
    def switchOutMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless @battle.pbCanChooseNonActive?(user.index)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no party allies to replace it!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEndOfMoveUsageEffect(user, _targets, numHits, switchedBattlers)
        return if user.fainted? || numHits == 0
        switchOutUser(user, switchedBattlers, true, false, true)
    end

    def getEffectScore(user, target)
        total = 0
        GameData::Stat.each_battle { |s| total += user.steps[s.id] }
        return 0 if total <= 0 || user.firstTurn?
        score = total * 10
        score += 30 unless user.hasDamagingAttack?
        score += getSwitchOutEffectScore(user, false)
        return score
    end
end

#===============================================================================
# After inflicting damage, user switches out.
# (U-turn, Volt Switch, Flip Turn)
#===============================================================================
class PokeBattle_Move_SwitchOutUserDamagingMove < PokeBattle_Move
    def switchOutMove?; return true; end

    def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
        return if user.fainted? || numHits == 0
        switchOutUser(user,switchedBattlers)
    end

    def getEffectScore(user, target)
        return getSwitchOutEffectScore(user)
    end
end

#===============================================================================
# Decreases the target's Attack and Special Attack by 1 step each. Then, user
# switches out. (Parting Shot)
#===============================================================================
class PokeBattle_Move_LowerTargetAtkSpAtk1SwitchOutUser < PokeBattle_TargetMultiStatDownMove
    def switchOutMove?; return true; end

    def initialize(battle, move)
        super
        @statDown = ATTACKING_STATS_2
    end

    def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
        switcher = user
        targets.each do |b|
            next if switchedBattlers.include?(b.index)
            switcher = b if b.effectActive?(:MagicCoat) || b.effectActive?(:EmpoweredMagicCoat) || b.effectActive?(:MagicBounce)
        end
        return if switcher.fainted? || numHits == 0
        switchOutUser(switcher,switchedBattlers,switcher.index == user.index)
    end

    def getEffectScore(user, target)
        return getSwitchOutEffectScore(user)
    end
end

#===============================================================================
# Forces both the user and the target to switch out. (Stink Cover)
#===============================================================================
class PokeBattle_Move_SwitchOutTargetAndUserStatusMove < PokeBattle_Move_SwitchOutTargetStatusMove
    def pbSwitchOutTargetsEffect(user, targets, numHits, switchedBattlers)
        return if numHits == 0
        targets.push(user)
        forceOutTargets(user, targets, switchedBattlers, substituteBlocks: true, random: false)
    end

    def getTargetAffectingEffectScore(user, target)
        score = super
        score += getSwitchOutEffectScore(user)
        return score
    end
end

#===============================================================================
# Returns user to party for swap, deals more damage the lower HP the user has. (Hare Heroics)
#===============================================================================
class PokeBattle_Move_SwitchOutUserDamagingMoveScalesWithLostHP < PokeBattle_Move_SwitchOutUserDamagingMove
    def pbBaseDamage(_baseDmg, user, _target)
        ratio = user.hp.to_f / user.totalhp.to_f
        return flailBasePowerFormula(ratio)
    end
	
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the lower the user's HP is. Range 25-200")
        detailsList << _INTL("<u>100% HP:</u> 25 BP")
        detailsList << _INTL("<u>50% HP:</u> 50 BP")
        detailsList << _INTL("<u>30% HP:</u> 70 BP")
        detailsList << _INTL("<u>20% HP:</u> 100 BP")
        detailsList << _INTL("<u>15% HP:</u> 120 BP")
        detailsList << _INTL("<u>10% HP:</u> 165 BP")
        detailsList << _INTL("<u>7.5% HP:</u> 200 BP")
    end
	
end

#===============================================================================
# Reduces the target's defense by two steps.
# After inflicting damage, user switches out. (Rip Turn)
#===============================================================================
class PokeBattle_Move_SwitchOutUserDamagingMoveLowerTargetDef2 < PokeBattle_Move_SwitchOutUserDamagingMove
    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.tryLowerStat(:DEFENSE, user, move: self, increment: 2)
    end

    def getTargetAffectingEffectScore(user, target)
        score = super
        score += getMultiStatDownEffectScore([:DEFENSE, 2], user, target)
        return score
    end
end

#===============================================================================
# Reduces the target's Sp. Def by two steps.
# After inflicting damage, user switches out.
#===============================================================================
class PokeBattle_Move_SwitchOutUserDamagingMoveLowerTargetSpDef2 < PokeBattle_Move_SwitchOutUserDamagingMove
    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.tryLowerStat(:SPECIAL_DEFENSE, user, move: self, increment: 2)
    end

    def getTargetAffectingEffectScore(user, target)
        score = super
        score += getMultiStatDownEffectScore([:SPECIAL_DEFENSE, 2], user, target)
        return score
    end
end

#===============================================================================
# Returns user to party for swap and lays a layer of spikes. (Caltrop Arts)
#===============================================================================
class PokeBattle_Move_SwitchOutUserSetSpikes < PokeBattle_Move_SwitchOutUserDamagingMove
    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.pbOpposingSide.effectAtMax?(:Spikes)
            @battle.pbDisplay(_INTL("But it failed, since there is no room for more Spikes!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        user.pbOpposingSide.incrementEffect(:Spikes)
    end

    def pbAdditionalEffect(user, _target)
        return unless damagingMove?
        return if user.pbOpposingSide.effectAtMax?(:Spikes)
        user.pbOpposingSide.incrementEffect(:Spikes)
    end

    def getTargetAffectingEffectScore(user, target)
        return getHazardSettingEffectScore(user, target) unless user.pbOpposingSide.effectAtMax?(:Spikes)
    end
end

#===============================================================================
# If the move misses, user switches out. (Cavalry Charge)
#===============================================================================
class PokeBattle_Move_SwitchOutUserIfMissesDamagingMove < PokeBattle_Move
    def switchOutMove?; return true; end

    def initialize(battle, move)
        super
        @switchThisTurn = false
    end

    def pbAllMissed(user, targets)
        @battle.pbDisplay(_INTL("{1} charges away!",user.pbThis))
        @switchThisTurn = true
    end

    def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
        return if user.fainted?
        return unless @switchThisTurn
        switchOutUser(user,switchedBattlers)
    end

    def getEffectScore(user, target)
        return getSwitchOutEffectScore(user) * 0.5
    end

    def resetMoveUsageState
        @switchThisTurn = false
    end
end