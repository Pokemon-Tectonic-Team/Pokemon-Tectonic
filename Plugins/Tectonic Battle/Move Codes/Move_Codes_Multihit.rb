#===============================================================================
# Hits twice.
#===============================================================================
class PokeBattle_Move_HitTwoTimes < PokeBattle_Move
    def multiHitMove?; return true; end
    def pbNumHits(_user, _targets, _checkingForAI = false); return 2; end
end

#===============================================================================
# Hits thrice.
#===============================================================================
class PokeBattle_Move_HitThreeTimes < PokeBattle_Move
    def multiHitMove?; return true; end
    def pbNumHits(_user, _targets, _checkingForAI = false); return 3; end
end

# Empowered Bullet Punch
class PokeBattle_Move_EmpoweredBulletPunch < PokeBattle_Move_HitThreeTimes
    include EmpoweredMove
end

#===============================================================================
# Hits 3 times and always critical. (Surging Strikes)
#===============================================================================
class PokeBattle_Move_HitThreeTimesAlwaysCriticalHit < PokeBattle_Move_AlwaysCriticalHit
    def multiHitMove?; return true; end
    def pbNumHits(_user, _targets, _checkingForAI = false); return 3; end
end

#===============================================================================
# Hits three times as Beedrill and five times as Wornet. (Multi-Needle)
#===============================================================================
class PokeBattle_Move_HitsThreeTimesAsBeedrillFiveTimesAsWornet < PokeBattle_Move
    def multiHitMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:BEEDRILL) && !user.countsAs?(:WORNET)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no stingers!", user.pbThis(true)))
            end
            return true
        end
        return false
    end
    
    def pbNumHits(user, _targets, _checkingForAI = false)
        if user.countsAs?(:WORNET)
            return 5
        elsif user.countsAs?(:BEEDRILL)
            return 3
        end
    end
end

#===============================================================================
# Hits 2-5 times.
#===============================================================================
module RandomHitable
    def multiHitMove?; return true; end

    def pbNumHits(user, _targets, _checkingForAI = false)
        if user.hasActiveItem?(:LOADEDDICE)
            hitChances = [4, 5]
        else
            hitChances = [2, 2, 3, 3, 4, 5]
        end
        if user.hasActiveAbility?(%i[SKILLLINK PERFECTLUCK])
            numHits = hitChances.last
        else
            numHits = hitChances.sample
        end
        numHits += 1 if user.hasActiveAbility?(:REPETITION)
        return numHits
    end

    def pbNumHitsAI(user, _targets)
        if user.hasActiveAbilityAI?(%i[SKILLLINK PERFECTLUCK])
            score = 5 
        elsif user.hasActiveItemAI?(:LOADEDDICE)
            score = 4.5
        else
            score = 19.0 / 6.0 # Average
        end
        score += 1 if user.hasActiveAbilityAI?(:REPETITION)
        return score
    end
end

class PokeBattle_Move_HitTwoToFiveTimes < PokeBattle_Move
    include RandomHitable
end

#===============================================================================
# Attacks two to five times. Gains money for each hit. (Sacred Lots)
#===============================================================================
class PokeBattle_Move_HitTwoToFiveTimesAddMoneyGainedFromBattleEachHit < PokeBattle_Move_HitTwoToFiveTimes
    def pbEffectOnNumHits(user, _target, numHits)
        user.generateMoney(2 * numHits)
        if numHits == 10
            @battle.pbDisplay(_INTL("How fortunate!"))
        elsif numHits == 0
            @battle.pbDisplay(_INTL("How unfortunate! Better luck next time."))
        end
    end
end

#===============================================================================
# Hits 2-5 times, for three turns in a row. (Pattern Release)
#===============================================================================
class PokeBattle_Move_Rampage3HitTwoToFiveTimes < PokeBattle_Move_HitTwoToFiveTimes
    def pbEffectAfterAllHits(user, target)
        user.applyEffect(:Outrage, 2) if !target.damageState.unaffected && !user.effectActive?(:Outrage)
        user.tickDownAndProc(:Outrage)
    end
end

#===============================================================================
# Hits X times, where X is the number of non-user unfainted status-free Pokémon
# in the user's party (not including partner trainers). Fails if X is 0.
# Base power of each hit depends on the base Attack stat for the species of that
# hit's participant. (Winter Ops)
#===============================================================================
class PokeBattle_Move_HitOncePerUserTeamMemberPhysical < PokeBattle_PartyAttackMove
    def initialize(battle, move)
        super
        @statUsed = :ATTACK
    end
end

#===============================================================================
# Hits X times, where X is the number of non-user unfainted status-free Pokémon
# in the user's party (not including partner trainers). Fails if X is 0.
# Base power of each hit depends on the base Sp. Atk stat for the species of that
# hit's participant. (Volley)
#===============================================================================
class PokeBattle_Move_HitOncePerUserTeamMemberSpecial < PokeBattle_PartyAttackMove
    def initialize(battle, move)
        super
        @statUsed = :SPECIAL_ATTACK
    end
end

#===============================================================================
# Hits in 2 volleys. The second volley targets the original target's ally if it
# has one (that can be targeted), or the original target if not. A battler
# cannot be targeted if it is is immune to or protected from this move somehow,
# or if this move will miss it. (Dragon Darts)
# NOTE: This move sometimes shows a different failure message compared to the
#       official games. This is because of the order in which failure checks are
#       done (all checks for each target in turn, versus all targets for each
#       check in turn). This is considered unimportant, and since correcting it
#       would involve extensive code rewrites, it is being ignored.
#===============================================================================
class PokeBattle_Move_HitTwoTimesTargetThenTargetAlly < PokeBattle_Move_HitTwoTimes
    def pbNumHits(_user, _targets, checkingForAI = false)
        if checkingForAI
            return 2
        else
            return 1
        end
    end

    # Hit again if only at the 0th hit
    def pbRepeatHit?(hitNum = 0)
        return hitNum < 1
    end

    def pbModifyTargets(targets, user)
        return if targets.length != 1
        choices = []
        targets[0].eachAlly do |b|
            user.pbAddTarget(choices, user, b, self)
        end
        return if choices.empty?
        idxChoice = (choices.length > 1) ? @battle.pbRandom(choices.length) : 0
        user.pbAddTarget(targets, user, choices[idxChoice], self, !pbTarget(user).can_choose_distant_target?)
    end

    def pbShowFailMessages?(targets)
        if targets.length > 1
            valid_targets = targets.select { |b| !b.fainted? && !b.damageState.unaffected }
            return valid_targets.length <= 1
        end
        return super
    end

    def pbDesignateTargetsForHit(targets, hitNum)
        valid_targets = []
        targets.each do |b|
            next if b.damageState.unaffected || b.damageState.fainted
            valid_targets.push(b)
        end
        indexThisHit = hitNum % targets.length
        if indexThisHit == 2
            if valid_targets[2]
                return [valid_targets[2]]
            else
                indexThisHit = 1
            end
        end
        return [valid_targets[1]] if indexThisHit == 1 && valid_targets[1]
        return [valid_targets[0]]
    end
end

#===============================================================================
# Does Dragon-Darts style hit redirection, plus
# each target hit loses 1 step of Speed. (Tar Volley)
#===============================================================================
class PokeBattle_Move_HitTwoTimesTargetThenTargetAllyLowerTargetSpd1 < PokeBattle_Move_HitTwoTimesTargetThenTargetAlly
    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.tryLowerStat(:SPEED, user, move: self)
    end
end

# Empowered Dragon Darts
class PokeBattle_Move_EmpoweredDragonDarts < PokeBattle_Move_HitTwoTimesTargetThenTargetAlly
    include EmpoweredMove
end

# Empowered Bullet Seed
class PokeBattle_Move_EmpoweredBulletSeed < PokeBattle_Move_HitTwoTimesTargetThenTargetAlly
    include EmpoweredMove

    def pbRepeatHit?(hitNum = 0)
        return hitNum < 5
    end

    def turnsBetweenUses(); return 3; end
end

class PokeBattle_Move_HitTwoToFiveTimesAlwaysHits < PokeBattle_Move
    include RandomHitable

    def pbAccuracyCheck(_user, _target); return true; end
end