#===============================================================================
# Heals user by 1/2 of its max HP.
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHP < PokeBattle_HalfHealingMove
end

#===============================================================================
# Heals user by 1/2 of its max HP. (Roost)
# User roosts, and its Flying type is ignored for attacks used against it.
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPLoseFlyingTypeThisTurn < PokeBattle_HalfHealingMove
    def pbEffectGeneral(user)
        super
        user.applyEffect(:Roost)
    end
end

#===============================================================================
# Battler in user's position is healed by 1/2 of its max HP, at the end of the
# next round. (Wish)
#===============================================================================
class PokeBattle_Move_HealUserPositionNextTurn < PokeBattle_Move
    def healingMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if user.position.effectActive?(:Wish)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since a Wish is already about to come true for {1}!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def wishAmount(user)
        return (user.totalhp / 2.0).round
    end

    def pbEffectGeneral(user)
        user.position.applyEffect(:Wish, 2)
        user.position.applyEffect(:WishAmount, wishAmount(user))
        user.position.applyEffect(:WishMaker, user.pokemonIndex)
    end

    def getEffectScore(user, _target)
        score = (user.totalhp / user.level) * 30
        score *= user.levelNerf(false,false,0.5) if user.level <= 30 && !user.pbOwnedByPlayer? # AI nerf
        return score
    end
end

#===============================================================================
# Heals user by 1/2 of its max HP, or 2/3 of its max HP in sunshine. (Synthesis)
#===============================================================================
class PokeBattle_Move_HealUserDependingOnSunshine < PokeBattle_HealingMove
    def healRatio(_user)
        if @battle.sunny?
            return 2.0 / 3.0
        else
            return 1.0 / 2.0
        end
    end

    def shouldHighlight?(_user, _target)
        return @battle.sunny?
    end
end

#===============================================================================
# Heals user by 1/2 of its max HP, or 2/3 of its max HP in moonglow. (Sweet Selene)
#===============================================================================
class PokeBattle_Move_HealUserDependingOnMoonglow < PokeBattle_HealingMove
    def healRatio(_user)
        if @battle.moonGlowing?
            return 2.0 / 3.0
        else
            return 1.0 / 2.0
        end
    end

    def shouldHighlight?(_user, _target)
        return @battle.moonGlowing?
    end
end

#===============================================================================
# Heals user by 1/2 of its max HP, or 2/3 of its max HP in a sandstorm. (Shore Up)
#===============================================================================
class PokeBattle_Move_HealUserDependingOnSandstorm < PokeBattle_HealingMove
    def healRatio(_user)
        return 2.0 / 3.0 if @battle.sandy?
        return 1.0 / 2.0
    end

    def shouldHighlight?(_user, _target)
        return @battle.sandy?
    end
end

# Empowered Shore Up
class PokeBattle_Move_EmpoweredShoreUp < PokeBattle_HalfHealingMove
    include EmpoweredMove

    def pbEffectGeneral(user)
        super

        user.applyEffect(:EmpoweredShoreUp)

        transformType(user, :GROUND)
    end
end

#===============================================================================
# Heals user by 2/3 of its max HP.
#===============================================================================
class PokeBattle_Move_HealUserTwoThirdsOfTotalHP < PokeBattle_HealingMove
    def healRatio(_user)
        return 2.0 / 3.0
    end
end

#===============================================================================
# Heals user by 1/2 of their HP.
# In any weather, increases the duration of the weather by 1. (Take Shelter)
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPExtendWeather1 < PokeBattle_HalfHealingMove
    def pbEffectGeneral(user)
        super
        @battle.extendWeather(1) unless @battle.pbWeather == :None
    end
end

#===============================================================================
# Heals user to full HP. User falls asleep for 2 more rounds. (Rest)
#===============================================================================
class PokeBattle_Move_HealUserFullyAndFallAsleep < PokeBattle_HealingMove
    def healRatio(_user); return 1.0; end

    def pbMoveFailed?(user, targets, show_message)
        if user.asleep?
            @battle.pbDisplay(_INTL("But it failed, since {1} is already asleep!", user.pbThis(true))) if show_message
            return true
        end
        return true unless user.canSleep?(user, show_message, self, true)
        return true if super
        return false
    end

    def pbMoveFailedAI?(user, targets)
        return true if user.willStayAsleepAI?
        return true unless user.canSleep?(user, false, self, true)
        return true if super
        return false
    end

    def pbEffectGeneral(user)
        user.applySleepSelf(_INTL("{1} slept and became healthy!", user.pbThis), 3)
        super
    end

    def getEffectScore(user, target)
        score = super
        score -= getSleepEffectScore(nil, target) * 0.45
        score += 45 if user.hasStatusNoSleep?
        return score
    end
end

#===============================================================================
# Heals user to 100%. Only usable on first turn. (Fresh Start)
#===============================================================================
class PokeBattle_Move_HealUserFullHPFailsIfNotUserFirstTurn < PokeBattle_HealingMove
    def healRatio(_user)
        return 1.0
    end

    def pbMoveFailed?(user, targets, show_message)
        unless user.firstTurn?
            @battle.pbDisplay(_INTL("But it failed, since it's not {1}'s first turn!", user.pbThis(true))) if show_message
            return true
        end
        return super
    end
end

#===============================================================================
# Rings the user. Ringed Pokémon gain 1/16 of max HP at the end of each round.
# (Aqua Ring)
#===============================================================================
class PokeBattle_Move_StartHealUserEachTurn < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.effectActive?(:AquaRing)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already veiled with water!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        user.applyEffect(:AquaRing)
    end

    def pbEffectAfterAllHits(user, target)
        return unless damagingMove?
        return if target.damageState.unaffected
        user.applyEffect(:AquaRing)
    end

    def getEffectScore(user, _target)
        return getAquaRingEffectScore(user)
    end
end

#===============================================================================
# Ingrains the user. Ingrained Pokémon gain 1/16 of max HP at the end of each
# round, and cannot flee or switch out. (Ingrain)
#===============================================================================
class PokeBattle_Move_StartHealUserEachTurnTrapUser < PokeBattle_Move
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
        user.applyEffect(:Ingrain)
    end

    def getEffectScore(user, _target)
		return 0 if user.effects[:PerishSong] > 0
        score = 50
        score += 30 if user.trapped?
        score += 20 if user.firstTurn?
        score += 20 if user.aboveHalfHealth?
        return score
    end
end

# Empowered Ingrain
class PokeBattle_Move_PrimevalIngrain < PokeBattle_Move_StartHealUserEachTurnTrapUser
    include EmpoweredMove

    def pbMoveFailed?(user, _targets, show_message)
        if user.effectActive?(:EmpoweredIngrain)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1}'s roots are already planted!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.applyEffect(:EmpoweredIngrain,4)
        transformType(user, :GRASS)
    end

    def getEffectScore(user, target)
        score = super
        score *= 2
        return score
    end
end

#===============================================================================
# Heals target by 1/2 of its max HP. (Heal Pulse)
#===============================================================================
class PokeBattle_Move_HealTargetHalfOfTotalHP < PokeBattle_Move
    def healingMove?; return true; end

    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.hp == target.totalhp
            @battle.pbDisplay(_INTL("{1}'s HP is full!", target.pbThis)) if show_message
            return true
        elsif !target.canHeal?
            @battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis)) if show_message
            return true
        end
        return false
    end

    def healingRatio(user)
        ratio = 1.0 / 2.0
        ratio *= 1.5 if pulseMove? && user.hasActiveAbility?(:MEGALAUNCHER)
        ratio *= 1.3 if pulseMove? && user.hasActiveAbility?(:EMANATION)
        return ratio
    end

    def pbEffectAgainstTarget(user, target)
        target.applyFractionalHealing(healingRatio(user))
    end

    def getEffectScore(user, target)
        return target.applyFractionalHealing(healingRatio(user),aiCheck: true)
    end
end

#===============================================================================
# The user dances to restore an ally by 50% max HP. They're cured of any status conditions. (Healthy Cheer)
#===============================================================================
class PokeBattle_Move_HealTargetHalfOfTotalHPAndCureStatus < PokeBattle_Move_HealTargetHalfOfTotalHP
    def pbFailsAgainstTarget?(_user, target, show_message)
       if !target.canHeal? && !target.pbHasAnyStatus?
            @battle.pbDisplay(_INTL("{1} can't be healed and it has no status conditions!", target.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        super
        healStatus(target)
    end

    def getEffectScore(user, target)
        score = super
        score += 40 if target.pbHasAnyStatus?
        return score
    end
end

#===============================================================================
# Restore HP and heals any status conditions of itself and its allies
# (Jungle Healing)
#===============================================================================
class PokeBattle_Move_HealUserAndAlliesQuarterOfTotalHPCureStatus < PokeBattle_Move
    def healingMove?; return true; end

    def pbMoveFailed?(user, targets, show_message)
        jglheal = 0
        for i in 0...targets.length
            jglheal += 1 if (targets[i].hp == targets[i].totalhp || !targets[i].canHeal?) && targets[i].status == :NONE
        end
        if jglheal == targets.length
            @battle.pbDisplay(_INTL("But it failed, since none of {1} or its allies can be healed or have their status conditions removed!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        target.pbCureStatus
        if target.hp != target.totalhp && target.canHeal?
            hpGain = (target.totalhp / 4.0).round
            target.pbRecoverHP(hpGain)
        end
        super
    end
end

#===============================================================================
# The user restores 1/4 of its maximum HP, rounded half up. If there is and
# adjacent ally, the user restores 1/4 of both its and its ally's maximum HP,
# rounded up. (Life Dew)
#===============================================================================
class PokeBattle_Move_HealUserAndAlliesQuarterOfTotalHP < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def healingMove?; return true; end

    def healRatio(_user)
        return 1.0 / 4.0
    end

    def pbMoveFailed?(user, _targets, show_message)
        failed = true
        @battle.eachSameSideBattler(user) do |b|
            next if b.hp == b.totalhp
            failed = false
            break
        end
        if failed
            @battle.pbDisplay(_INTL("But it failed, since there was no one to heal!")) if show_message
            return true
        end
        return false
    end

    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.hp == target.totalhp
            @battle.pbDisplay(_INTL("{1}'s HP is full!", target.pbThis)) if show_message
            return true
        elsif !target.canHeal?
            @battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        target.applyFractionalHealing(healRatio(user))
    end

    def getEffectScore(_user, target)
        score = 0
        if target.canHeal?
            score += 20
            score += 40 if target.belowHalfHealth?
        end
        return score
    end
end

#===============================================================================
# Heals target by 1/2 of its max HP, or 2/3 of its max HP in moonglow.
# (Floral Healing)
#===============================================================================
class PokeBattle_Move_HealTargetDependingOnMoonglow < PokeBattle_Move
    def healingMove?; return true; end

    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.hp == target.totalhp
            @battle.pbDisplay(_INTL("{1}'s HP is full!", target.pbThis)) if show_message
            return true
        elsif !target.canHeal?
            @battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis)) if show_message
            return true
        end
        return false
    end

    def healingRatio(user,target)
        if @battle.moonGlowing?
            return 2.0 / 3.0
        else
            return 1.0 / 2.0
        end
    end

    def pbEffectAgainstTarget(user, target)
        target.applyFractionalHealing(healingRatio(user,target))
    end

    def getEffectScore(user, target)
        return target.applyFractionalHealing(healingRatio(user,target),aiCheck: true)
    end

    def shouldHighlight?(_user, _target)
        return @battle.moonGlowing?
    end
end

#===============================================================================
# Damages target if target is a foe, or heals target by 1/2 of its max HP if
# target is an ally. (Pollen Puff, Package, Water Spiral)
#===============================================================================
class PokeBattle_Move_HealAllyOrDamageFoe < PokeBattle_Move
    def pbTarget(user)
        return GameData::Target.get(:NearFoe) if user.effectActive?(:HealBlock)
        return super
    end

    def pbOnStartUse(user, targets)
        @healing = false
        @healing = !user.opposes?(targets[0]) if targets.length > 0
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        return false unless @healing
        if target.substituted? && !ignoresSubstitute?(user)
            @battle.pbDisplay(_INTL("{1} is protected behind its substitute!", target.pbThis)) if show_message
            return true
        end
        unless target.canHeal?
            @battle.pbDisplay(_INTL("But it failed, since {1} can't be healed!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def damagingMove?(aiCheck = false)
        if aiCheck
            return super
        else
            return false if @healing
            return super
        end
    end

    def pbEffectAgainstTarget(_user, target)
        return unless @healing
        target.applyFractionalHealing(1.0 / 2.0)
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        hitNum = 1 if @healing # Healing anim
        super
    end

    def getEffectScore(user, target)
        return target.applyFractionalHealing(1.0 / 2.0, aiCheck: true) unless user.opposes?(target)
        return 0
    end

    def resetMoveUsageState
        @healing = false
    end
end

#===============================================================================
# User faints. The Pokémon that replaces the user is fully healed (HP and
# status). Fails if user won't be replaced. (Healing Wish)
#===============================================================================
class PokeBattle_Move_UserFaintsHealAndCureReplacement < PokeBattle_Move
    def healingMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless @battle.pbCanChooseNonActive?(user.index)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no party allies to replace it!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbSelfKO(user)
        return if user.fainted?
        user.pbReduceHP(user.hp, false)
        user.pbItemHPHealCheck
        user.position.applyEffect(:HealingWish)
    end

    def getEffectScore(user, target)
        score = 80
        score += getSelfKOMoveScore(user, target)
        return score
    end
end

#===============================================================================
# User faints. The Pokémon that replaces the user is fully healed (HP, PP and
# status). Fails if user won't be replaced. (Lunar Dance)
#===============================================================================
class PokeBattle_Move_UserFaintsHealAndCureReplacementRestorePP < PokeBattle_Move
    def healingMove?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless @battle.pbCanChooseNonActive?(user.index)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no party allies to replace it!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbSelfKO(user)
        return if user.fainted?
        user.pbReduceHP(user.hp, false)
        user.pbItemHPHealCheck
        user.position.applyEffect(:LunarDance)
    end

    def getEffectScore(user, target)
        score = 90
        score += getSelfKOMoveScore(user, target)
        return score
    end
end

#===============================================================================
# Heals user by 1/3 of their max health, but does not fail at full health. (Ebb & Flow)
#===============================================================================
class PokeBattle_Move_HealUserThirdOfTotalHPDamagingMove < PokeBattle_HealingMove
    def healRatio(_user)
        return 1.0 / 3.0
    end

    def pbMoveFailed?(_user, _targets, _show_message)
        return false
    end
end

#===============================================================================
# Heals user to full, but traps them with Infestation (Honey Slather)
#===============================================================================
class PokeBattle_Move_HealUserFullHPBindsTarget < PokeBattle_HealingMove
    def healRatio(_user); return 1.0; end

    def pbMoveFailed?(user, _targets, show_message)
        if user.effectActive?(:Trapping)
            @battle.pbDisplay(_INTL("{1}'s HP is unable to gather any honey!", user.pbThis)) if show_message
            return true
        end
        return super
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:Trapping, 3)
        user.applyEffect(:TrappingMove, :INFESTATION)
        user.pointAt(:TrappingUser, user)

        battle.pbDisplay(_INTL("{1} has been afflicted with an infestation!", user.pbThis))
    end
end

#===============================================================================
# Decreases the target's Attack by 1 step. Heals user by an amount equal to the
# target's Attack stat. (Strength Sap)
#===============================================================================
class PokeBattle_Move_HealUserByTargetAtkLowerTargetAtk1 < PokeBattle_StatDrainHealingMove
    def initialize(battle, move)
        super
        @statToReduce = :ATTACK
    end
end

#===============================================================================
# Decreases the target's Sp. Atk by 1 step. Heals user by an amount equal to the
# target's Sp. Atk stat. (Mind Sap)
#===============================================================================
class PokeBattle_Move_HealUserByTargetSpAtkLowerTargetSpAtk1 < PokeBattle_StatDrainHealingMove
    def initialize(battle, move)
        super
        @statToReduce = :SPECIAL_ATTACK
    end
end

#===============================================================================
# Heals the user by 2/3 health. Move disables self. (Stitch Up)
#===============================================================================
class PokeBattle_Move_HealUserByTwoThirdsOfTotalHPDisableSelf < PokeBattle_HealingMove
    def healRatio(_user)
        return 2.0 / 3.0
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:Disable, 5)
    end

    def getEffectScore(user, _target)
        score = super
        score -= 30
        return score
    end
end

#===============================================================================
# Uses rest on both self and target. (Bedfellows)
#===============================================================================
class PokeBattle_Move_ForceUserAndTargetToRest < PokeBattle_Move
    def pbEffectAgainstTarget(user, target)
        @battle.forceUseMove(user, :REST)
        @battle.forceUseMove(target, :REST)
    end

    def getEffectScore(user, target)
        score = 0

        unless user.fullHealth?
            score += user.applyFractionalHealing(1.0, aiCheck: true)
            score -= getSleepEffectScore(nil, user) * 0.45
            score += 45 if user.hasStatusNoSleep?
        end
        unless target.fullHealth?
            score -= target.applyFractionalHealing(1.0, aiCheck: true)
            score += getSleepEffectScore(nil, target)
            score -= 45 if target.hasStatusNoSleep?
        end
        return score
    end
end

#===============================================================================
# Restores health by 50% and raises Speed by one step. (Mulch Meal)
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPRaiseSpd1 < PokeBattle_HalfHealingMove
    def pbMoveFailed?(user, _targets, show_message)
        if !user.canHeal? && !user.pbCanRaiseStatStep?(:SPEED, user, self, true)
            @battle.pbDisplay(_INTL("But it failed, since {1} can't heal or raise its Speed!", user.pbThis(true))) if show_message
            return true
        end
    end

    def pbEffectGeneral(user)
        super
        user.tryRaiseStat(:SPEED, user, move: self)
    end

    def getEffectScore(user, target)
        score = super
        score += 20
        score -= user.steps[:SPEED] * 20
        return score
    end
end

#===============================================================================
# User heals itself based on current weight. (Refurbish)
# Then, its current weigtht is cut in half.
#===============================================================================
class PokeBattle_Move_HealUserBasedOnWeightHalvesWeight < PokeBattle_HealingMove
    def healRatio(user)
        weight = user.pbWeight / 10
        case weight
        when 1024..999_999
            return 1.0
        when 512..1023
            return 0.75
        when 256..511
            return 0.5
        when 128..255
            return 0.25
        when 64..127
            return 0.125
        else
            return 0.0625
        end
    end

    def pbEffectGeneral(user)
        super
        user.incrementEffect(:Refurbished)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Heals more the heavier the user is.")
        detailsList << _INTL("<u>1024 kg and more:</u> 100%")
        detailsList << _INTL("<u>512 - 1023 kg:</u> 75%")
        detailsList << _INTL("<u>256 - 511 kg:</u> 50%")
        detailsList << _INTL("<u>128 - 255 kg:</u> 25%")
        detailsList << _INTL("<u>64 - 127 kg:</u> 12.5%")
        detailsList << _INTL("<u>63 kg and less:</u> 6.25%")
    end
end

#===============================================================================
# Heals user by 1/2, raises Defense, Sp. Defense, Crit Chance. (Divination)
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPRaiseDefSpDefCriticalHitRate1 < PokeBattle_HalfHealingMove
    def pbMoveFailed?(user, _targets, show_message)
        if user.effectAtMax?(:RaisedCritChance) && !user.pbCanRaiseStatStep?(:DEFENSE, user, self) && 
                !user.pbCanRaiseStatStep?(:SPECIAL_DEFENSE, user, self)
            return super
        end
        return false
    end

    def pbEffectGeneral(user)
        super
        user.pbRaiseMultipleStatSteps(DEFENDING_STATS_2, user, move: self)
        user.incrementEffect(:RaisedCritChance, 2) unless user.effectAtMax?(:RaisedCritChance)
    end

    def getEffectScore(user, target)
        score = super
        score += getMultiStatUpEffectScore(DEFENDING_STATS_2, user, target)
        score += getCriticalRateBuffEffectScore(user, 2)
        return score
    end
end

#===============================================================================
# The user puts all their effort into attacking their opponent
# causing them to rest on their next turn. (Extreme Effort)
#===============================================================================
class PokeBattle_Move_UserMustUseRestNextTurn < PokeBattle_Move
    def pbEffectGeneral(user)
	    user.applyEffect(:ExtremeEffort, 2)
    end

    def getEffectScore(user, _target)
        return -getSleepEffectScore(nil, user) / 2
    end
end

#===============================================================================
# Restores health by half and gains an Aqua Ring. (River Rest)
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPStartHealUserEachTurn < PokeBattle_HalfHealingMove
    def pbMoveFailed?(user, _targets, show_message)
        if super(user, _targets, false) && user.effectActive?(:AquaRing)
            @battle.pbDisplay(_INTL("But it failed, since {1} can't heal and already has a veil of water!", user.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:AquaRing)
    end

    def getEffectScore(user, target)
        score = super
        score += getAquaRingEffectScore(user)
        return score
    end
end

#===============================================================================
# User heals for 3/5ths of their HP. (Heal Order)
#===============================================================================
class PokeBattle_Move_HealUserThreeFifthsOfTotalHP < PokeBattle_HealingMove
    def healRatio(_user)
        return 3.0 / 5.0
    end
end

#===============================================================================
# Heals user by 1/2 of their HP.
# Extends the duration of any screens affecting the user's side by 1. (Stabilize)
#===============================================================================
class PokeBattle_Move_HealUserHalfOfTotalHPExtendScreens1 < PokeBattle_HalfHealingMove
    def pbEffectGeneral(user)
        super
        pbOwnSide.eachEffect(true) do |effect, value, data|
            next unless data.is_screen?
            pbOwnSide.effects[effect] += 1
            @battle.pbDisplay(_INTL("{1}'s {2} was extended 1 turn!", pbTeam, data.name))
        end
    end

    def getEffectScore(user, target)
        score = super
        pbOwnSide.eachEffect(true) do |effect, value, data|
            next unless data.is_screen?
            score += 30
        end
        return score
    end
end

# Empowered Heal Order
class PokeBattle_Move_EmpoweredHealOrder < PokeBattle_HalfHealingMove
    include EmpoweredMove

    def healingMove?; return true; end

    def pbEffectGeneral(user)
        super

        summonAvatar(user, :COMBEE, _INTL("{1} summons a helper!", user.pbThis))

        transformType(user, :BUG)
    end
end