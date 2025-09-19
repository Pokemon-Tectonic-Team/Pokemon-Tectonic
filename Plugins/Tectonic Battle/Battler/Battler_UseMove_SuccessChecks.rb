class PokeBattle_Battler
    #=============================================================================
    # Decide whether the trainer is allowed to tell the Pokémon to use the given
    # move. Called when choosing a command for the round.
    # Also called when processing the Pokémon's action, because these effects also
    # prevent Pokémon action. Relevant because these effects can become active
    # earlier in the same round (after choosing the command but before using the
    # move) or an unusable move may be called by another move such as Metronome.
    #=============================================================================
    def pbCanChooseMove?(move, commandPhase, showMessages = true, specialUsage = false)
        return true if move.empoweredMove? && boss?
        # Disable
        if @effects[:DisableMove] == move.id && !specialUsage
            msg = _INTL("{1}'s {2} is disabled!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Heal Block
        if effectActive?(:HealBlock) && move.healingMove?
            msg = _INTL("{1} can't use {2} because of Heal Block!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Gravity
        if @battle.gravityIntensified? && move.unusableInGravity?
            msg = _INTL("{1} can't use {2} because of gravity!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Throat Chop
        if effectActive?(:ThroatChop) && move.soundMove?
            if showMessages
                msg = _INTL("{1} can't use {2} because of Throat Chop!", pbThis, move.name)
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Disarming Shot
        if effectActive?(:DisarmingShot) && move.bladeMove?
            if showMessages
                msg = _INTL("{1} can't use {2} because of Disarming Shot!", pbThis, move.name)
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Choice Items
        if effectActive?(:ChoiceBand)
            choiceItem = nil
            GameData::Item.getByFlag("ChoiceLocking").each do |choiceLockItem|
                next unless hasActiveItem?(choiceLockItem)
                choiceItem = choiceLockItem
                break
            end
            if choiceItem && pbHasMove?(@effects[:ChoiceBand])
                if move.id != @effects[:ChoiceBand] && move.id != :STRUGGLE
                    msg = _INTL("{1} allows the use of only {2}!", getItemName(choiceItem), GameData::Move.get(@effects[:ChoiceBand]).name)
                    if showMessages
                        commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
                    end
                    echoln(msg)
                    return false
                end
            else
                disableEffect(:ChoiceBand)
            end
        end
        # Gorilla Tactics
        if effectActive?(:GorillaTactics)
            choiceLockingAbility = hasActiveAbility?(GameData::Ability.getByFlag("ChoiceLocking"))
            if choiceLockingAbility
                if move.id != @effects[:GorillaTactics] && move.id != :STRUGGLE
                    msg = _INTL("{1} allows the use of only {2}!", getAbilityName(choiceLockingAbility), GameData::Move.get(@effects[:GorillaTactics]).name)
                    if showMessages
                        commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
                    end
                    echoln(msg)
                    return false
                end
            else
                disableEffect(:GorillaTactics)
            end
        end
        # Taunt
        if effectActive?(:Taunt) && move.statusMove?
            msg = _INTL("{1} can't use {2} after the taunt!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Torment
        if effectActive?(:Torment) && !effectActive?(:Instructed) &&
           @lastMoveUsed && move.id == @lastMoveUsed && move.id != @battle.struggle.id
            msg = _INTL("{1} can't use the same move twice in a row due to the torment!", pbThis)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Imprison
        @battle.eachOtherSideBattler(@index) do |b|
            next if !b.effectActive?(:Imprison) || !b.pbHasMove?(move.id)
            msg = _INTL("{1} can't use its sealed {2}!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Barred
        if effectActive?(:Barred) && move.id != :STRUGGLE && !pbHasType?(move.pbCalcType(self))
            msg = _INTL("{1} can't use {2} after being barred!", pbThis, move.name)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        #Type-Restricted
        if effectActive?(:TypeRestricted) && move.id != :STRUGGLE && move.pbCalcType(self) != @effects[:TypeRestricted]
            effect_type = @effects[:TypeRestricted]
            msg = _INTL("{1} can only use {2}-type moves!", pbThis, effect_type.name.capitalize)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Assault Vest and Strike Vest (prevents choosing status moves but doesn't prevent
        # executing them)
        if move.statusMove? && commandPhase
            statusPreventingItem = hasActiveItem?(GameData::Item.getByFlag("NoStatusUse"))
            if statusPreventingItem
                msg = _INTL("The effects of the {1} prevent status moves from being used!", getItemName(statusPreventingItem))
                if showMessages
                    commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
                end
                echoln(msg)
                return false
            end
            statusPreventingAbility = hasActiveAbility?(%i[ASSAULTSPINES])
            if statusPreventingAbility
                msg = _INTL("The effects of the {1} prevent status moves from being used!", getAbilityName(statusPreventingAbility))
                if showMessages
                    commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
                end
                echoln(msg)
                return false
            end
        end
        if hasActiveAbility?(:AURORAPRISM) && (move.damagingMove? && (pbHasType?(move.type) || move.type == :FLEX))
            msg = _INTL("{1} cannot use moves of their own types!", pbThis)
            if showMessages
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            echoln(msg)
            return false
        end
        # Belch
        return false unless move.pbCanChooseMove?(self, commandPhase, showMessages)
        # Turbulent Sky
        if pbOwnSide.effectActive?(:TurbulentSky) && !effectActive?(:Instructed) &&
                @lastMoveUsedType && move.pbCalcType(self) == @lastMoveUsedType && move.id != @battle.struggle.id
             msg = _INTL("{1} can't use the same type twice in a row due to the turbulent sky!", pbThis)
             if showMessages
                 commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
             end
             echoln(msg)
             return false
         end
        return true
    end

    #=============================================================================
    # Check whether the user (self) is able to take action at all.
    # If this returns true, and if PP isn't a problem, the move will be considered
    # to have been used (even if it then fails for whatever reason).
    #=============================================================================
    def pbTryUseMove(move, specialUsage, skipAccuracyCheck, aiCheck = false)
        return true if move.empoweredMove? && boss? && move.statusMove?
        
        # Check whether it's possible for self to use the given move
        # NOTE: Encore has already changed the move being used, no need to have a
        #       check for it here.
        if !aiCheck && !pbCanChooseMove?(move, false, true, specialUsage)
            onMoveFailed(move)
            return false
        end

        if effectActive?(:IceSculpture)
            if aiCheck
                echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to being an ice sculpture.")  
            else
                @battle.pbDisplay(_INTL("{1} is an ice sculpture! It can't move!", pbThis))
            end
            return false
        end

        if effectActive?(:HyperBeam) # Intentionally before Truant
            if aiCheck
                echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to exhaustion failure (Hyperbeam, etc.)")
            else
                @battle.pbDisplay(_INTL("{1} must recharge!", pbThis))
            end
            return false
        end
        if effectActive?(:AttachedTo)
            if aiCheck
                echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to attachment failure")
            else
                @battle.pbDisplay(_INTL("{1} is still attached to {2}!", pbThis, getBattlerPointsTo(:AttachedTo).pbThis(true)))
            end
            return false
        end

        # Skip checking all applied effects that could make self fail doing something
        return true if skipAccuracyCheck

        # Check status problems and continue their effects/cure them
        if asleep?
            if aiCheck
                if willStayAsleepAI? && !move.usableWhenAsleep?
                    echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to it being predicted to stay asleep this turn")
                    return false
                end
            else
                reduceStatusCount(:SLEEP)
                if getStatusCount(:SLEEP) <= 0
                    pbCureStatus(true, :SLEEP)
                else
                    pbContinueStatus(:SLEEP)
                    unless move.usableWhenAsleep? # Snore/Sleep Talk
                        onMoveFailed(move)
                        return false
                    end
                end
            end
        end

        # Pacifist
        if hasActiveAbility?(:PACIFIST)
            if aiCheck
                echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to it being predicted to refuse to move (Pacifist)")
                return false
            else
                showMyAbilitySplash(:PACIFIST)
                @battle.pbDisplay(_INTL("{1} refuses to battle!", pbThis))
                onMoveFailed(move)
                hideMyAbilitySplash
                return false
            end
        end

        # Truant
        if hasActiveAbility?(:TRUANT)
            if aiCheck
                if effectActive?(:Truant) && move.id != :SLACKOFF
                    echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to it being predicted to loaf around (Truant)")
                    return false
                end
            else
                if effectActive?(:Truant)
                    disableEffect(:Truant)
                else
                    applyEffect(:Truant)
                end
                if !effectActive?(:Truant) && move.id != :SLACKOFF # True means loafing, but was just inverted
                    showMyAbilitySplash(:TRUANT)
                    @battle.pbDisplay(_INTL("{1} is loafing around!", pbThis))
                    onMoveFailed(move)
                    hideMyAbilitySplash
                    return false
                end
            end
        end

        # Flinching
        if effectActive?(:Flinch)
            if aiCheck
                unless effectActive?(:FlinchImmunity)
                    echoln("\t\t[AI FAILURE CHECK] #{pbThis} rejects the move #{move.id} due to it being predicted to flinch (Moonglow?)")
                    return false
                end
            else
                if effectActive?(:FlinchImmunity)
                    @battle.pbDisplay(_INTL("{1} would have flinched, but it's immune now!", pbThis))
                    disableEffect(:Flinch)
                elsif hasTribeBonus?(:TYRANNICAL) && !pbOwnSide.effectActive?(:TyrannicalImmunity)
                    @battle.pbShowTribeSplash(self,:TYRANNICAL)
                    @battle.pbDisplay(_INTL("{1} refuses to flinch!", pbThis))
                    @battle.pbHideTribeSplash(self)
                    pbOwnSide.applyEffect(:TyrannicalImmunity)
                elsif hasActiveItem?(:COURAGEBADGE)
                    @battle.pbDisplay(_INTL("{1} would have flinched, but it holds a Courage Badge!", pbThis))
                    aiLearnsItem(:COURAGEBADGE)
                else
                    @battle.pbDisplay(_INTL("{1} flinched and couldn't move!", pbThis))
                    eachActiveAbility do |ability|
                        BattleHandlers.triggerAbilityOnFlinch(ability, self, @battle)
                    end
                    onMoveFailed(move)
                    applyEffect(:FlinchImmunity,4)
                    return false
                end
            end
        end
        return true
    end

    def doesProtectionEffectNegateThisMove?(effectDisplayName, move, user, target, protectionIgnoredByAbility, animationName = nil, showMessages = true)
        if target.effectActive?(:Jinxed)
            if showMessages
                @battle.pbDisplay(_INTL("{1} is jinxed! {2} failed to protect it!", target.pbThis(true), effectDisplayName))
            end
            return false
        elsif move.canProtectAgainst? && !protectionIgnoredByAbility
            @battle.pbCommonAnimation(animationName, target) unless animationName.nil?
            @battle.pbDisplay(_INTL("{1} protected {2}!", effectDisplayName, target.pbThis(true))) if showMessages
            if user.boss? && (move.empoweredMove? || AVATARS_REGULAR_ATTACKS_PIERCE_PROTECT)
                target.damageState.partiallyProtected = true
                yield if block_given?
                if showMessages
                    if move.empoweredMove? && !AVATARS_REGULAR_ATTACKS_PIERCE_PROTECT
                        @battle.pbDisplay(_INTL("But the empowered attack pierces through!", user.pbThis(true)))
                    else
                        @battle.pbDisplay(_INTL("Actually, {1} partially pierces through!", user.pbThis(true)))
                    end
                end
            else
                target.damageState.protected = true
                @battle.successStates[user.index].protected = true
                yield if block_given?
                return true
            end
        elsif move.pbTarget(user).targets_foe
            if showMessages
                @battle.pbDisplay(_INTL("{1} was ignored, and failed to protect {2}!", effectDisplayName,
target.pbThis(true)))
            end
            return false
        end
    end

    #=============================================================================
    # Initial success check against the target. Done once before the first hit.
    # Includes move-specific failure conditions, protections and type immunities.
    #=============================================================================
    def pbSuccessCheckAgainstTarget(move, user, target, typeMod, show_message = true, aiCheck = false)
        # Two-turn attacks can't fail here in the charging turn
        return true if user.effectActive?(:TwoTurnAttack)

        # Move-specific failures

        if aiCheck
            return false if move.pbFailsAgainstTargetAI?(user, target)
        elsif move.pbFailsAgainstTarget?(user, target, show_message)
            return false
        end

        ###	Protect Style Moves
        # Ability effects that ignore protection
        protectionIgnoredByAbility = false
        protectionIgnoredByAbility = true if user.shouldAbilityApply?(:UNSEENFIST, aiCheck) && move.physicalMove?

        # Only check the target's side if the target is not the self
        holdersToCheck = [target]
        holdersToCheck.push(target.pbOwnSide) if target.index != user.index
        holdersToCheck.each do |effectHolder|
            effectHolder.eachEffect(true) do |effect, _value, data|
                next unless data.is_protection?
                if data.protection_info&.has_key?(:does_negate_proc) && !data.protection_info[:does_negate_proc].call(
                    user, target, move, @battle)
                    next
                end
                effectName = data.name
                animationName = data.protection_info ? data.protection_info[:animation_name] : effect.to_s
                negated = doesProtectionEffectNegateThisMove?(effectName, move, user, target, protectionIgnoredByAbility,
animationName, show_message) do
                    if data.protection_info&.has_key?(:hit_proc) && !aiCheck
                        data.protection_info[:hit_proc].call(user, target, move, @battle)
                    end
                end
                return false if negated
            end
        end

        # Magic Coat/Magic Bounce/Magic Shield
        if move.canMagicCoat? && !target.semiInvulnerable? && target.opposes?(user)
            if aiCheck
                if target.canChooseMagicCoat? || target.effectActive?(:EmpoweredMagicCoat)
                    return false              
                end
            else
                if target.effectActive?(:EmpoweredMagicCoat)
                    target.damageState.magicCoat = true
                    return false
                end
                if target.effectActive?(:MagicCoat)
                    target.damageState.magicCoat = true
                    target.disableEffect(:MagicCoat)
                    return false
                end
            end
            if target.hasActiveAbility?(:MAGICBOUNCE) && !@battle.moldBreaker
                unless aiCheck
                    target.damageState.magicBounce = true
                    target.applyEffect(:MagicBounce)
                end
                return false
            end
            if target.hasActiveAbility?(:WARDING) && !@battle.moldBreaker
                unless aiCheck
                    target.damageState.protected = true
                    if show_message
                        @battle.pbShowAbilitySplash(target, :WARDING)
                        @battle.pbDisplay(_INTL("{1} shielded itself from the {2}!", target.pbThis, move.name))
                        @battle.pbHideAbilitySplash(target)
                    end
                end
                return false
            end
        end

        # Move fails due to type immunity ability
        # Skipped for bosses using damaging moves so that it can be calculated properly later
        if move.inherentImmunitiesPierced?(user, target)
            # Do nothing
        elsif targetInherentlyImmune?(user, target, move, show_message, aiCheck)
            return false
        elsif targetTypeModImmune?(user, target, move, typeMod, show_message, aiCheck)
            if !aiCheck && target.effectActive?(:Illusion)
                target.aiLearnsAbility(:ILLUSION) if target.hasActiveAbility?(:ILLUSION)
                target.aiLearnsAbility(:INCOGNITO) if target.hasActiveAbility?(:INCOGNITO)
            end
            return false
        end

        # Substitute immunity to status moves
        if target.substituted? && move.statusMove? &&
           !move.ignoresSubstitute?(user) && user.index != target.index
            PBDebug.log("[Target immune] #{target.pbThis} is protected by its Substitute")
            @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis(true))) if show_message
            return false
        end
        return true
    end

    def targetTypeModImmune?(user, target, move, typeMod, showMessages = true, aiCheck = false)
        # Type immunity
        if move.damagingMove?(aiCheck) && Effectiveness.ineffective?(typeMod)
            PBDebug.log("[Target immune] #{target.pbThis}'s type immunity") unless aiCheck
            if showMessages
                @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
                @battle.triggerImmunityDialogue(user, target, false)
            end
            return true
        end
        return false
    end

    def targetInherentlyImmune?(user, target, move, showMessages = true, aiCheck = false)
        if move.pbImmunityByAbility(user, target, showMessages, aiCheck)
            @battle.triggerImmunityDialogue(user, target, true) if showMessages
            return true
        end
        if airborneImmunity?(user, target, move, showMessages, aiCheck)
            PBDebug.log("[Target immune] #{target.pbThis}'s immunity due to being airborne")
            return true
        end
        # Dark-type immunity to moves made faster by Prankster
        pranksterInEffect = false
        if aiCheck
            pranksterInEffect = true if user.hasActiveAbilityAI?(:PRANKSTER) && move.statusMove?
        else
            pranksterInEffect = true if user.effectActive?(:Prankster)
        end
        if pranksterInEffect && target.pbHasType?(:DARK) && target.opposes?(user)
            PBDebug.log("[Target immune] #{target.pbThis} is Dark-type and immune to Prankster-boosted moves")
            if showMessages
                @battle.pbDisplay(_INTL("It doesn't affect {1} since Dark-types are immune to pranks...",
target.pbThis(true)))
                @battle.triggerImmunityDialogue(user, target, false)
            end
            return true
        end
        return false
    end

    def airborneImmunity?(user, target, move, showMessages = true, aiCheck = false)
        # Airborne-based immunity to Ground moves
        if move.damagingMove?(aiCheck) && move.calcType == :GROUND && target.airborne? && !move.hitsFlyingTargets?
            levitationAbility = target.hasLevitate?
            if levitationAbility && !@battle.moldBreaker
                if showMessages
                    @battle.pbShowAbilitySplash(target, levitationAbility)
                    @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis))
                    @battle.pbHideAbilitySplash(target)
                    @battle.triggerImmunityDialogue(user, target, true)
                end
                return true
            end
            GameData::Item.getByFlag("Levitation").each do |levitationItem|
                if target.hasActiveItem?(levitationItem)
                    if showMessages
                        @battle.pbDisplay(_INTL("{1}'s {2} makes Ground moves miss!", target.pbThis, getItemName(levitationItem)))
                        @battle.triggerImmunityDialogue(user, target, false)
                    end
                    return true
                end
            end
            if target.effectActive?(:MagnetRise)
                if showMessages
                    @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Magnet Rise!", target.pbThis))
                    @battle.triggerImmunityDialogue(user, target, false)
                end
                return true
            end
            if target.effectActive?(:Telekinesis)
                if showMessages
                    @battle.pbDisplay(_INTL("{1} makes Ground moves miss with Telekinesis!", target.pbThis))
                    @battle.triggerImmunityDialogue(user, target, false)
                end
                return true
            end
        end
        return false
    end

    #=============================================================================
    # Per-hit success check against the target.
    # Includes semi-invulnerable move use and accuracy calculation.
    #=============================================================================
    def pbSuccessCheckPerHit(move, user, target, aiCheck = false)
        # Two-turn attacks can't fail here in the charging turn
        if aiCheck
            return true if move.is_a?(PokeBattle_TwoTurnMove)
        else
            return true if user.effectActive?(:TwoTurnAttack)
        end
        # Lock-On
        return true if user.effectActive?(:LockOn) && user.effects[:LockOnPos] == target.index
        # Move-specific success checks
        return true if move.pbOverrideSuccessCheckPerHit(user, target)
        # Semi-invulnerability
        return false if moveFailsSemiInvulnerability?(move, user, target, aiCheck)
        # Accuracy check
        return true if aiCheck || move.pbAccuracyCheck(user, target) # Includes Counter/Mirror Coat
        # Missed
        PBDebug.log("[Move failed] Failed pbAccuracyCheck or target is semi-invulnerable")
        return false
    end

    #=============================================================================
    # Message shown when a move fails the per-hit success check above.
    #=============================================================================
    def pbMissMessage(move, user, target)
        if move.pbTarget(user).num_targets > 1
            @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis))
        elsif target.effectActive?(:TwoTurnAttack)
            @battle.pbDisplay(_INTL("{1} avoided the attack!", target.pbThis))
        elsif !move.pbMissMessage(user, target)
            @battle.pbDisplay(_INTL("{1}'s attack missed!", user.pbThis))
        end
    end

    def onMoveFailed(move, affectsTrackers = true)
        @lastMoveFailed = true if affectsTrackers
        # Slap stick
        eachOpposing do |b|
            next unless b.hasActiveAbility?(:SLAPSTICK)
            @battle.pbShowAbilitySplash(b, :SLAPSTICK)
            @battle.pbDisplay(_INTL("{1} worsens {2}'s failure!", b.pbThis, pbThis(true)))
            applyFractionalDamage(1.0 / 8.0) if takesIndirectDamage?(true)
            @battle.pbHideAbilitySplash(b)
        end
    end
end
