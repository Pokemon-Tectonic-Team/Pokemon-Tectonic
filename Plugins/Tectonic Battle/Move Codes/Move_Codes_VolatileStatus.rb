#===============================================================================
# The target can no longer use the same move twice in a row. (Torment)
#===============================================================================
class PokeBattle_Move_DisableTargetUsingSameMoveConsecutively < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbFailsAgainstTarget?(user, target, show_message)
        return if damagingMove?
        if target.effectActive?(:Torment)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already tormented!", target.pbThis(true)))
            end
            return true
        end
        return true if pbMoveFailedAromaVeil?(user, target, show_message)
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Torment)
    end

    def getTargetAffectingEffectScore(_user, target)
        return 0 if target.hasActiveAbilityAI?(:MENTALBLOCK)
        score = 60
        score += 40 unless target.hasDamagingAttack?
        return score
    end
end

# Empowered Torment
class PokeBattle_Move_EmpoweredTorment < PokeBattle_Move_DisableTargetUsingSameMoveConsecutively
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        transformType(user, :DARK)
    end

    def pbEffectAgainstTarget(user, target)
        target.applyEffect(:Torment)
        target.pbLowerMultipleStatSteps(ATTACKING_STATS_1, user, move: self)
    end
end

#===============================================================================
# For 5 rounds, disables the last move the target used. (Disable)
#===============================================================================
class PokeBattle_Move_DisableTargetLastMoveUsed < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def initialize(battle, move)
        super
        @disableTurns = 4
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        return if damagingMove?
        unless target.canBeDisabled?(true, self)
            @battle.pbDisplay(_INTL("But it failed, since the target can't be disabled!")) if show_message
            return true
        end
        return false
    end

    def getDisableTurns(target)
        return target.boss? ? @disableTurns / 2 : @disableTurns
    end

    def pbEffectAgainstTarget(_user, target)
        return if damagingMove?
        target.applyEffect(:Disable, serene_boosted(getDisableTurns(target), _user))
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return unless target.canBeDisabled?(true, self)
        target.applyEffect(:Disable, serene_boosted(getDisableTurns(target), user))
    end

    def getTargetAffectingEffectScore(_user, target)
        return getDisableEffectScore(target, serene_boosted(@disableTurns), user)
    end
end

#===============================================================================
# For 4 rounds, disables the last move the target used. (Drown)
# Then debuffs a stat based on what was disabled.
#===============================================================================
class PokeBattle_Move_DisableTargetLastMoveUsedLowerTargetRelevantStat4 < PokeBattle_Move_DisableTargetLastMoveUsed
    def initialize(battle, move)
        super
        @disableTurns = 4
    end

    def pbEffectAgainstTarget(user, target)
        super
        statToLower = getDebuffingStat(target)
        target.pbLowerStatStep(statToLower, 4, user) if target.pbCanLowerStatStep?(statToLower,user,self,true)
    end

    def getDebuffingStat(battler)
        return :SPEED unless battler.lastMoveUsedCategory
        case battler.lastMoveUsedCategory
        when 0
            return :ATTACK
        when 1
            return :SPECIAL_ATTACK
        when 2
            return :SPEED
        end
    end

    def getEffectScore(user, target)
        score = super
        score += getMultiStatDownEffectScore([getDebuffingStat(target),4],user,target)
        return score
    end
end

#===============================================================================
# For 5 rounds, disables the last move the target used. Also, (Gem Seal)
# remove 5 PP from it.
#===============================================================================
class PokeBattle_Move_DisableTargetLastMoveUsedReduceItsPPBy5 < PokeBattle_Move_DisableTargetLastMoveUsed
    def pbEffectAgainstTarget(_user, target)
        super
        target.eachMove do |m|
            next if m.id != target.lastRegularMoveUsed
            reduction = [5, m.pp].min
            target.pbSetPP(m, m.pp - reduction)
            @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",
               target.pbThis(true), m.name, reduction))
            break
        end
    end

    def getEffectScore(_user, target)
        score = super
        score += 10
        return score
    end
end

#===============================================================================
# For 4 rounds, disables the target's non-damaging moves. (Taunt)
#===============================================================================
class PokeBattle_Move_DisableTargetStatusMoves4 < PokeBattle_Move
    def ignoresSubstitute?(user); return statusMove?; end

    def initialize(battle, move)
        super
        @tauntTurns = 4
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Taunt)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already taunted!", target.pbThis(true))) if show_message
            return true
        end
        return true if pbMoveFailedAromaVeil?(user, target, show_message)
        return false
    end

    def getTauntTurns(target)
        return target.boss? ? @tauntTurns / 2 : @tauntTurns
    end

    def pbEffectAgainstTarget(_user, target)
        return if damagingMove?
        target.applyEffect(:Taunt, serene_boosted(getTauntTurns(target)))
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return if target.effectActive?(:Taunt)
        return true if pbMoveFailedAromaVeil?(user, target)
        target.applyEffect(:Taunt, serene_boosted(getTauntTurns(target)))
    end

    def getTargetAffectingEffectScore(user, target)
        return 0 if target.substituted? && statusMove? && !ignoresSubstitute?(user)
        return 0 if target.hasActiveAbilityAI?(:MENTALBLOCK)
        unkownHate = target.unknownMovesCountAI 
        return 0 unless target.hasStatusMove? || unkownHate == 4
        firstTurnScore = 0
        lastingScore = 0        

        
        # AI taunts if it has no idea what target is doing
        if unkownHate == 4
            firstTurnScore = 50
            lastingScore += 30
        end
        
        # Setup
        if target.hasSetupStatusMove?
           if target.lastRoundMoveCategory == -1 || target.lastRoundMoveCategory == 2 # No point stopping setup that already happened
                firstTurnScore = 50
                lastingScore += 30
            end
        end
        
        # Hazard
        if target.hasUseableStatusHazardMove?
            firstTurnScore = 50
            lastingScore += 30           
        end
        
        # Recovery
        if target.hasRecoveryMove?
            if target.hp <= target.totalhp * 0.7
                firstTurnScore = 50
                lastingScore += 30
            else
                lastingScore += 25
            end
        end

		if @battle.battleAI.userMovesFirst?(self, user, target)
            firstTurnScore *= 2
            firstTurnScore *= 1.3 if user.firstTurn? # Prevent hazards over setting them on lead
        end
        
        lastingScore *= (serene_boosted(getTauntTurns(target)) - 1)
        score = firstTurnScore + lastingScore
        score = 220 if score >= 220 # AI shouldnt taunt over kills
        return score
    end
end

#===============================================================================
# For 2 rounds, disables the target's non-damaging moves. (Docile Mask)
#===============================================================================
class PokeBattle_Move_DisableTargetStatusMoves2 < PokeBattle_Move_DisableTargetStatusMoves4
    def initialize(battle, move)
        super
        @tauntTurns = 2
    end
end

#===============================================================================
# For 4 rounds, the target must use the same move each round. (Encore)
#===============================================================================
class PokeBattle_Move_DisableTargetUsingDifferentMove4 < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end


    def pbFailsAgainstTarget?(user, target, show_message)
        if target.effectActive?(:Encore)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already locked into an encore!", target.pbThis(true))) if show_message
            return true
        end
        unless target.lastRegularMoveUsed
            @battle.pbDisplay(_INTL("But it failed, since {1} hasn't used a move yet!", target.pbThis(true))) if show_message
            return true
        end
        unless @battle.canInvokeMove?(target.lastRegularMoveUsed)
            @battle.pbDisplay(_INTL("But it failed, since {1} can't be locked into {2}!",
                  target.pbThis(true), GameData::Move.get(target.lastRegularMoveUsed).name)) if show_message
            return true
        end
        if target.effectActive?(:ShellTrap)
            @battle.pbDisplay(_INTL("But it failed, since {1} is setting a Shell Trap!", target.pbThis(true))) if show_message
            return true
        end
        if target.effectActive?(:Masquerblade)
            @battle.pbDisplay(_INTL("But it failed, since {1} is hiding a Masquerblade!", target.pbThis(true))) if show_message
            return true
        end
        return true if pbMoveFailedAromaVeil?(user, target, show_message)
        canEncore = false
        target.eachMove do |m|
            next if m.id != target.lastRegularMoveUsed
            next if m.pp == 0 && m.total_pp > 0
            canEncore = true
            break
        end
        unless canEncore
            @battle.pbDisplay(_INTL("But it failed, since {1} last used move has no more PP!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Encore, serene_boosted(4, user))
    end

    def getTargetAffectingEffectScore(user, target)
        return 0 if target.hasActiveAbilityAI?(:MENTALBLOCK)
        score = 60
        score += 40 if target.trapped?
        userSpeed = user.pbSpeed(true, move: self)
        targetSpeed = target.pbSpeed(true)
        if userSpeed > targetSpeed
            return 0 if target.lastRegularMoveUsed.nil?
            moveData = GameData::Move.get(target.lastRegularMoveUsed)
            if moveData.category == 2 && %i[User BothSides].include?(moveData.target)
                score += 100
            elsif moveData.category != 2 && moveData.target == :NearOther &&
                  Effectiveness.ineffective?(pbCalcTypeMod(moveData.type, target, user))
                score += 100
            end
        end
        return score
    end
end

#===============================================================================
# For 4 rounds, disables the target's off-type moves. (Bar)
#===============================================================================
class PokeBattle_Move_DisableTargetUsingOffTypeMove4 < PokeBattle_Move
    def ignoresSubstitute?(_user); return statusMove?; end

    def initialize(battle, move)
        super
        @barredTurns = 4
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Barred)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already barred!", target.pbThis(true))) if show_message
            return true
        end
        return true if pbMoveFailedAromaVeil?(user, target, show_message)
        return false
    end

    def getBarTurns(target)
        return target.boss? ? @barredTurns / 2 : @barredTurns
    end

    def pbEffectAgainstTarget(_user, target)
        return if damagingMove?
        target.applyEffect(:Barred, serene_boosted(getBarTurns(target)))
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return if target.effectActive?(:Barred)
        return true if pbMoveFailedAromaVeil?(user, target)
        target.applyEffect(:Barred, serene_boosted(getBarTurns(target)))
    end

    def getTargetAffectingEffectScore(_user, target)
        return 0 if target.substituted? && statusMove?
        return 0 if target.hasActiveAbilityAI?(:MENTALBLOCK)
        return 0 unless target.hasOffTypeMove?
        return 40 + serene_boosted(getBarTurns(target)) * 20
    end
end

#===============================================================================
# Target will lose 1/4 of max HP at end of each round, while asleep. (Nightmare)
#===============================================================================
class PokeBattle_Move_StartDamageTargetEachTurnIfTargetAsleep < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless target.asleep?
            @battle.pbDisplay(_INTL("But it failed, since {1} isn't asleep!", target.pbThis(true))) if show_message
            return true
        end
        if target.effectActive?(:Nightmare)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already afflicted by a Nightmare!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Nightmare)
    end

    def getTargetAffectingEffectScore(_user, target)
        score = 100
        score += 50 if target.aboveHalfHealth?
        return score
    end
end

#===============================================================================
# Decrease 6 steps of speed and weakens target to fire moves. (Tar Shot)
#===============================================================================
class PokeBattle_Move_LowerTargetSpeed6MakeTargetWeakerToFire < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        if !target.pbCanLowerStatStep?(:SPEED, target, self) && target.effectActive?(:TarShot)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already covered in tar and can't have their Speed lowered!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        return if target.damageState.substitute
        target.tryLowerStat(:SPEED, user, move: self, increment: 6)
        target.applyEffect(:TarShot)
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        score += getMultiStatDownEffectScore([:SPEED, 6], user, target)
        score += 50 unless target.effectActive?(:TarShot)
        return score
    end
end

#===============================================================================
# User curses the target.
#===============================================================================
class PokeBattle_Move_CurseTarget < PokeBattle_Move
    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Curse)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already cursed!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        return if damagingMove?
        target.applyEffect(:Curse)
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return if target.effectActive?(:Curse)
        target.applyEffect(:Curse)
    end

    def getEffectScore(user, target)
        return getCurseEffectScore(user, target)
    end
end

#===============================================================================
# Curses the targey. Money is gained from curse damage. (Pharaoh's Curse)
#===============================================================================
class PokeBattle_Move_CurseTargetEarnMoneyFromCurse < PokeBattle_Move_CurseTarget
    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Curse) && target.effectActive?(:PharaohsCurse)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already cursed by the Pharoh!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        return if damagingMove?
        target.applyEffect(:Curse) unless target.effectActive?(:Curse)
        target.applyEffect(:PharaohsCurse) unless target.effectActive?(:PharaohsCurse)
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        target.applyEffect(:Curse) unless target.effectActive?(:Curse)
        target.applyEffect(:PharaohsCurse) unless target.effectActive?(:PharaohsCurse)
    end
end

#===============================================================================
# Curses the target by spending 1/4th of the user's HP. (Cursed Oath)
#===============================================================================
class PokeBattle_Move_CurseTargetUserPaysQuarterOfTotalHP < PokeBattle_Move_CurseTarget
    def pbEffectAgainstTarget(user, target)
        @battle.pbDisplay(_INTL("{1} cut its own HP!", user.pbThis))
        user.applyFractionalDamage(1.0 / 4.0, false)
        super
    end

    def getEffectScore(user, target)
        score = super
        score += getHPLossEffectScore(user, 0.25)
        return score
    end
end

# Empowered Cursed Oath
class PokeBattle_Move_EmpoweredCursedOath < PokeBattle_Move
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        @battle.eachOtherSideBattler(user) do |b|
            b.applyEffect(:Curse)
        end
        transformType(user, :GHOST)
    end
end

#===============================================================================
# Numb's the target. If they are already numbed, curses them instead. (Spectral Tongue)
#===============================================================================
class PokeBattle_Move_NumbTargetOrCurseIfNumb < PokeBattle_Move
    def pbFailsAgainstTarget?(user, target, show_message)
        if target.numbed?
            if target.effectActive?(:Curse) && show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already cursed!", target.pbThis(true)))
            end
        else
            return !target.canNumb?(user, show_message, self)
        end
    end

    def pbEffectAgainstTarget(user, target)
        if target.numbed?
            target.applyEffect(:Curse)
        else
            target.applyNumb(user)
        end
    end

    def shouldHighlight?(_user, target)
        return target.numbed?
    end

    def getScore(user, target)
        if target.numbed?
            return getNumbEffectScore(user, target)
        else
            return getCurseEffectScore(user, target)
        end
    end
end

#===============================================================================
# User applies a evil version of Ingrain. (Evil Roots)
#===============================================================================
class PokeBattle_Move_StartsCursedIngrain < PokeBattle_Move_StartHealUserEachTurnTrapUser
    def pbMoveFailed?(user, _targets, show_message)
        if user.effectActive?(:Ingrain) || user.effectActive?(:EvilRoots)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1}'s roots are already planted!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.applyEffect(:EvilRoots)
    end

    def getEffectScore(user, _target)
        score = super
        score += 60
        return score
    end
end

#===============================================================================
# Target cannot use sound-based moves for 2 more rounds. (Throat Chop)
#===============================================================================
class PokeBattle_Move_DisableTargetSoundMoves3 < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        target.applyEffect(:ThroatChop, serene_boosted(3, _user))
    end

    def getTargetAffectingEffectScore(_user, target)
        return 30 if !target.effectActive?(:ThroatChop) && target.hasSoundMove? && !target.substituted?
        return 0
    end
end

#===============================================================================
# Target cannot use blade-based moves for 2 more rounds. (Disarming Shot)
#===============================================================================
class PokeBattle_Move_DisableTargetBladeMoves3 < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        target.applyEffect(:DisarmingShot, serene_boosted(3, _user))
    end

    def getTargetAffectingEffectScore(_user, target)
        return 30 if !target.effectActive?(:DisarmingShot) && target.hasBladeMove? && !target.substituted?
        return 0
    end
end

#===============================================================================
# Target gains a weakness to Bug-type attacks. (Creep Out)
#===============================================================================
class PokeBattle_Move_MakeTargetWeakerToBug < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:CreepOut)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already afraid of Bug-type moves!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        return if target.damageState.substitute
        target.applyEffect(:CreepOut)
    end

    def getTargetAffectingEffectScore(_user, target)
        return 0 if target.effectActive?(:CreepOut)
        score = 40
        score += 40 if target.aboveHalfHealth?
        return score
    end
end

#===============================================================================
# Grounds the target while it remains active. Hits some semi-invulnerable
# targets. (Smack Down, Thousand Arrows, Weigh Anchor)
#===============================================================================
class PokeBattle_Move_HitsTargetInSkyGroundsTarget < PokeBattle_Move
    def hitsFlyingTargets?; return true; end

    def pbCalcTypeModSingle(moveType, defType, user=nil, target=nil)
        return Effectiveness::NORMAL_EFFECTIVE if moveType == :GROUND && defType == :FLYING
        return super
    end

    def canSmackDown?(target, checkingForAI = false)
        return false if target.fainted?
        if checkingForAI
            return false if target.substituted?
        elsif target.damageState.unaffected || target.damageState.substitute
            return false
        end
        return false if !target.airborne? &&
            !target.inTwoTurnSkyAttack?
        return true
    end

    def pbEffectAfterAllHits(_user, target)
        return unless canSmackDown?(target)
        target.applyEffect(:SmackDown)
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        if canSmackDown?(target)
            score += 30
                if user.pbHasAttackingType?(:GROUND) && !target.effectActive?(:SmackDown)
                    tTypes = target.pbTypes(true, true)
                    tTypes.each do |t|
                        score += 30 if t == :FIRE || t == :POISON || t == :STEEL || t == :ROCK || t == :ELECTRIC
                        score -= 30 if t == :BUG || t == :GRASS || t == :ICE
                    end
                end
            score += 70 if @battle.battleAI.userMovesFirst?(self, user, target) &&
                target.inTwoTurnSkyAttack?
        end
        score = 5 if score <= 5 # Constant score so AI uses on "kills"
        return score
    end

    def shouldHighlight?(_user, target)
        return canSmackDown?(target)
    end
end

#===============================================================================
# Negates the target's ability while it remains on the field, if it has already
# performed its action this round. (Core Enforcer)
#===============================================================================
class PokeBattle_Move_NegateTargetAbilityIfTargetActed < PokeBattle_Move
    def pbEffectAgainstTarget(_user, target)
        return if target.damageState.substitute || target.effectActive?(:AbilitySupressed)
        return if target.immutableAbility?
        return if @battle.choices[target.index][0] != :UseItem &&
                  !((@battle.choices[target.index][0] == :UseMove ||
                  @battle.choices[target.index][0] == :Shift) && target.movedThisRound?)
        target.applyEffect(:AbilitySupressed)
    end

    def getEffectScore(user, target)
        score = getWantsToBeSlowerScore(user, target, 3, move: self) if !target.substituted? && !target.effectActive?(:AbilitySupressed)
        return score
    end
end

#===============================================================================
# If the target would heal until end of turn, instead they take that much life loss.
# (Hypothermiate, Heartstopper, Bad Ending)
#===============================================================================
class PokeBattle_Move_ReverseTargetHealingThisTurn < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        target.applyEffect(:HealingReversed)
    end

    def getEffectScore(_user, target)
        if target.hasHealingMove?
            if target.belowHalfHealth?
                return 50
            else
                return 20
            end
        end
        return 0
    end
end

#===============================================================================
# The target's healing is cut in half until they switch out (Icy Injection)
#===============================================================================
class PokeBattle_Move_TargetHasHalvedHealing < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        target.applyEffect(:IcyInjection)
    end

    def getEffectScore(_user, target)
        if target.hasHealingMove?
            if target.belowHalfHealth?
                return 45
            else
                return 30
            end
        end
        return 0
    end
end

#===============================================================================
# User fractures the target.
#===============================================================================
class PokeBattle_Move_FractureTarget < PokeBattle_Move
    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Fracture)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already fractured!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        return if damagingMove?
        target.applyEffect(:Fracture, serene_boosted(DEFAULT_FRACTURE_DURATION, user))
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return if target.effectActive?(:Fracture)
        target.applyEffect(:Fracture, serene_boosted(DEFAULT_FRACTURE_DURATION, user))
    end

    def getEffectScore(user, target)
        return getFractureEffectScore(user, target)
    end
end

#===============================================================================
# User jinxes the target for 4 turns.
#===============================================================================
class PokeBattle_Move_JinxTarget < PokeBattle_Move
    def pbFailsAgainstTarget?(user, target, show_message)
        return false if damagingMove?
        if target.effectActive?(:Jinxed)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already jinxed!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        return if damagingMove?
        target.applyEffect(:Jinxed, serene_boosted(DEFAULT_JINX_DURATION, user))
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        return if target.effectActive?(:Jinxed)
        target.applyEffect(:Jinxed, serene_boosted(DEFAULT_JINX_DURATION, user))
    end

    def getEffectScore(user, target)
        return getJinxEffectScore(user, target)
    end
end