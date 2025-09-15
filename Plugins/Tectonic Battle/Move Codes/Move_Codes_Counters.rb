#===============================================================================
# Counters a physical move used against the user this round, with 2x the power.
# (Counter)
#===============================================================================
class PokeBattle_Move_CounterPhysicalDamage < PokeBattle_FixedDamageMove
    def pbAddTarget(targets, user)
        target = user.getBattlerPointsTo(:CounterTarget)
        return if target.nil? || !user.opposes?(target)
        user.pbAddTarget(targets, user, target, self, false)
    end

    def pbMoveFailed?(_user, targets, show_message)
        if targets.length == 0
            @battle.pbDisplay(_INTL("But there was no target...")) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(_user, _targets); return false; end

    def pbFixedDamage(user, _target)
        dmg = user.effects[:Counter] * 2
        dmg = 1 if dmg == 0
        return dmg
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Counter.")
        return -1000
    end
end

#===============================================================================
# Counters a specical move used against the user this round, with 2x the power.
# (Mirror Coat)
#===============================================================================
class PokeBattle_Move_CounterSpecialDamage < PokeBattle_FixedDamageMove
    def pbAddTarget(targets, user)
        target = user.getBattlerPointsTo(:MirrorCoatTarget)
        return if target.nil? || !user.opposes?(target)
        user.pbAddTarget(targets, user, target, self, false)
    end

    def pbMoveFailed?(_user, targets, show_message)
        if targets.length == 0
            @battle.pbDisplay(_INTL("But there was no target...")) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(_user, _targets); return false; end

    def pbFixedDamage(user, _target)
        dmg = user.effects[:MirrorCoat] * 2
        dmg = 1 if dmg == 0
        return dmg
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Mirror Coat.")
        return -1000
    end
end

#===============================================================================
# Counters the last damaging move used against the user this round, with 1.5x
# the power. (Metal Burst)
#===============================================================================
class PokeBattle_Move_CounterDamagePlusHalf < PokeBattle_FixedDamageMove
    def pbAddTarget(targets, user)
        return if user.lastFoeAttacker.length == 0
        lastAttacker = user.lastFoeAttacker.last
        return if lastAttacker < 0 || !user.opposes?(lastAttacker)
        user.pbAddTarget(targets, user, @battle.battlers[lastAttacker], self, false)
    end

    def pbMoveFailed?(_user, targets, show_message)
        if targets.length == 0
            @battle.pbDisplay(_INTL("But there was no target...")) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(_user, _targets); return false; end

    def pbFixedDamage(user, _target)
        dmg = (user.lastHPLostFromFoe * 1.5).floor
        dmg = 1 if dmg == 0
        return dmg
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Metal Burst.")
        return -1000
    end
end

#===============================================================================
# This round, reflects all moves with the "C" flag targeting the user back at
# their origin. (Magic Coat)
#===============================================================================
class PokeBattle_Move_BounceBackProblemCausingStatusMoves < PokeBattle_Move
    def pbEffectGeneral(user)
        user.applyEffect(:MagicCoat)
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Magic Coat.")
        return -1000
    end
end

#===============================================================================
# For the next 3 rounds, reflects all moves with the "C" flag targeting the user back at
# their origin. (Primeval Magic Coat)
#===============================================================================
class PokeBattle_Move_EmpoweredMagicCoat < PokeBattle_Move
    include EmpoweredMove

    def pbEffectGeneral(user)
        user.applyEffect(:EmpoweredMagicCoat,4)

        transformType(user, :PSYCHIC)
    end
end

#===============================================================================
# This round, snatches all used moves with the "D" flag. (Snatch)
#===============================================================================
class PokeBattle_Move_StealAndUseBeneficialStatusMove < PokeBattle_Move
    def pbEffectGeneral(user)
        maxSnatch = 0
        @battle.eachBattler do |b|
            next if b.effects[:Snatch] <= maxSnatch
            maxSnatch = b.effects[:Snatch]
        end
        user.applyEffect(:Snatch, maxSnatch + 1)
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Snatch.")
        return -1000
    end
end

#===============================================================================
# User bides its time this round and next round. The round after, deals 2x the
# total direct damage it took while biding to the last battler that damaged it.
# (Bide)
#===============================================================================
class PokeBattle_Move_MultiTurnAttackBideThenReturnDoubleDamage < PokeBattle_FixedDamageMove
    def pbAddTarget(targets, user)
        return if user.effects[:Bide] != 1 # Not the attack turn
        target = user.getBattlerPointsTo(:BideTarget)
        unless user.pbAddTarget(targets, user, target, self, false)
            user.pbAddTargetRandomFoe(targets, user, self, false)
        end
    end

    def pbMoveFailed?(user, targets, show_message)
        return false if user.effects[:Bide] != 1 # Not the attack turn
        if user.effects[:BideDamage] == 0
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} hasn't absorbed any energy!", user.pbThis(true)))
            end
            user.disableEffect(:Bide)
            return true
        end
        if targets.length == 0
            @battle.pbDisplay(_INTL("But there was no target...")) if show_message
            user.disableEffect(:Bide)
            return true
        end
        return false
    end

    def pbOnStartUse(user, _targets)
        @damagingTurn = (user.effects[:Bide] == 1) # If attack turn
    end

    def pbDisplayUseMessage(user, targets)
        if user.effects[:Bide] == 1 # Attack turn
            @battle.pbDisplayBrief(_INTL("{1} unleashed energy!", user.pbThis))
        elsif user.effectActive?(:Bide)
            @battle.pbDisplayBrief(_INTL("{1} is storing energy!", user.pbThis))
        else
            super # Start using Bide
        end
    end

    def damagingMove?(aiCheck = false)
        if aiCheck
            return super
        else
            return false unless @damagingTurn
            return super
        end
    end

    def pbFixedDamage(user, _target)
        return user.effects[:BideDamage]
    end

    def pbEffectGeneral(user)
        unless user.effectActive?(:Bide)
            user.applyEffect(:Bide, 3)
            user.currentMove = @id
        end
        user.effects[:Bide] -= 1
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        hitNum = 1 unless @damagingTurn # Charging anim
        super
    end

    def getEffectScore(user, _target)
        user.eachOpposing do |b|
            return 0 if b.pbTypes.include? :GHOST # Bandaid fix, should have complicated score but its bide
        end
        if user.belowHalfHealth?
            return 0
        else
            return 100
        end
    end
end

#===============================================================================
# If user is KO'd before it next moves, the battler that caused it also faints.
# (Destiny Bond)
#===============================================================================
class PokeBattle_Move_AttackerFaintsIfUserFaints < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        if user.effectActive?(:DestinyBondPrevious)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} was already waiting to take down others with it!", user.pbThis(true)))
            end
            return true
        end
        if @battle.bossBattle?
            @battle.pbDisplay(_INTL("But it failed in the presence of an Avatar!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.applyEffect(:DestinyBond)
        @battle.pbDisplay(_INTL("{1} is hoping to take its attacker down with it!", user.pbThis))
    end

    def getEffectScore(user, _target)
        score = 40
        score += 40 if user.belowHalfHealth?
        score += 40 unless user.hasDamagingAttack?
        return score
    end
end

# Empowered Destiny Bond
class PokeBattle_Move_EmpoweredDestinyBond < PokeBattle_Move
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.applyEffect(:EmpoweredDestinyBond)
        transformType(user, :GHOST)
    end
end

#===============================================================================
# Fails if user has not been hit by an opponent's physical move this round.
# (Shell Trap)
#===============================================================================
class PokeBattle_Move_UsedAfterUserTakesPhysicalDamage < PokeBattle_Move
    def pbDisplayChargeMessage(user)
        user.applyEffect(:ShellTrap)
    end

    def pbDisplayUseMessage(user, targets)
        super if user.tookPhysicalHit
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.effectActive?(:ShellTrap)
            @battle.pbDisplay(_INTL("But it failed, since the effect wore off somehow!")) if show_message
            return true
        end
        unless user.tookPhysicalHit
            @battle.pbDisplay(_INTL("{1}'s shell trap didn't work!", user.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(_user, targets)
        targets.each do |target|
            return false if target.hasPhysicalAttack?
        end
        return true
    end
end

#===============================================================================
# Fails if user has not been hit by an opponent's special move this round.
# (Masquerblade)
#===============================================================================
class PokeBattle_Move_UsedAfterUserTakesSpecialDamage < PokeBattle_Move
    def pbDisplayChargeMessage(user)
        user.applyEffect(:Masquerblade)
    end

    def pbDisplayUseMessage(user, targets)
        super if user.tookSpecialHit
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.effectActive?(:Masquerblade)
            @battle.pbDisplay(_INTL("But it failed, since the effect wore off somehow!")) if show_message
            return true
        end
        unless user.tookSpecialHit
            @battle.pbDisplay(_INTL("{1}'s hidden blade trap didn't work!", user.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(_user, targets)
        targets.each do |target|
            return false if target.hasSpecialAttack?
        end
        return true
    end
end