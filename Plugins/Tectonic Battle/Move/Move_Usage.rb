class PokeBattle_Move
    #=============================================================================
    # Effect methods per move usage
    #=============================================================================
    def pbCanChooseMove?(_user, _commandPhase, _showMessages); return true; end # For Belch
    def pbDisplayChargeMessage(user); end # For Focus Punch/shell Trap/Beak Blast
    def pbOnStartUse(user, targets); end
    def pbAddTarget(targets, user); end # For Counter, etc. and Bide
    def pbModifyTargets(targets, user); end # For Dragon Darts, etc.
    def pbAllMissed(user, targets); end # Move effects that occur after all hits if all of them missed

    def pbEffectOnNumHits(user, target, numHits); end # Move effects that occur after all hits, which base themselves on how many hits landed

    def pbMoveFailedNoSpecial?(_user, _targets)
        return false
    end # Check if the move should fail, specifically if its not being specifically used (e.g. Dancer)

    def priorityModification(_user, _target); return 0; end # Checks whether the move should have modified priority
    def moveFailed(user, targets); end

    def resetMoveUsageState; end

    # Reset move usage counters (child classes can increment them).
    def pbChangeUsageCounters(user, specialUsage)
        [user, @battle.field].each do |effectHolder|
            effectHolder.eachEffect(true) do |effect, _value, data|
                if data.resets_on_move_start || (data.resets_on_move_start_no_special && !specialUsage)
                    effectHolder.disableEffect(effect)
                end
            end
        end
    end

    def calculateUsageOverrides(user, targets)
        # Calculate the move's category during this usage
        @category_override = calculateCategoryOverride(user, targets)
        # Calculate the move's type during this usage
        @calcType = pbCalcType(user)
    end

    def calculateCategoryOverride(user, targets)
        return selectBestCategory(user, targets[0]) if punchingMove? && user.hasActiveAbility?(:MYSTICFIST)
        return selectBestCategory(user, targets[0]) if rampagingMove? && user.hasActiveAbility?(:WREAKHAVOC)
        return 0 if (physicalMove? or specialMove?) && user.hasActiveItem?(:STRENGTHHERB)
        return 1 if (physicalMove? or specialMove?) && user.hasActiveItem?(:INTELLECTHERB)
        return selectBestCategory(user) if adaptiveMove?
        return 0 if @category == 1 && user.hasActiveAbility?(:BRUTEFORCE)
        return 1 if @category == 0 && user.hasActiveAbility?(%i[TIMEINTERLOPER SPACEINTERLOPER])
        return nil
    end

    def resolutionChoice(user); end

    #=============================================================================
    # Methods for displaying stuff when the move is used
    #=============================================================================
    def pbDisplayUseMessage(user, _targets = [])
        if empoweredMove?
            unless @battle.autoTesting
                @battle.pbDisplayWithFormatting(_INTL("\\ss{1} used <c2=06644bd2>{2}</c2>!", user.pbThis, @name))
                if user.pbOwnedByPlayer?
                    unlockAchievement(:USE_PRIMEVAL_MOVE)
                end
            end
        else
            @battle.pbDisplayBrief(_INTL("{1} used {2}!", user.pbThis, @name))
        end
    end

    def displayZMoveUseMessage(user)
        @battle.pbCommonAnimation("ZPower", user, nil) if @battle.scene.pbCommonAnimationExists?("ZPower")
        PokeBattle_ZMove.from_status_move(@battle, @id, user) if statusMove?
        @battle.pbDisplay(_INTL("{1} surrounded itself with its Z-Power!", user.pbThis)) unless statusMove?
        @battle.pbDisplay(_INTL("{1} unleashed its full force Z-Move!", user.pbThis))
    end

    def displayDamagingMoveMessages(user, move, targets = [])
        if $Options.move_clarifying_messages == 0
            displayBPAdjustmentMessage(user, targets) unless multiHitMove?
            displayCategoryChangeMessage(move.category_override) if move.category_override
        end
        # Display messages letting the player know that weather is debuffing a move (if it is)
        displayWeatherDebuffMessages(user, move.calcType) if $Options.weather_messages == 0
    end

    def displayBPAdjustmentMessage(user, targets)
        targets.each do |target|
            bp = pbBaseDamage(@baseDamage, user, target).floor
            if bp != @baseDamage
                if targets.length == 1
                    @battle.pbDisplayBrief(_INTL("Its base power was adjusted to {1}!", bp))
                else
                    @battle.pbDisplayBrief(_INTL("Its base power was adjusted to {1} against {2}!", bp,
target.pbThis(true)))
                end
            end
        end
    end

    def displayCategoryChangeMessage(calcCategory)
        if calcCategory == 0
            @battle.pbDisplayBrief(_INTL("It became physical!"))
        elsif calcCategory == 1
            @battle.pbDisplayBrief(_INTL("It became special!"))
        end
    end

    def displayWeatherDebuffMessages(user, type)
        if applyRainDebuff?(user, type)
            if @battle.pbCheckGlobalAbility(:DREARYCLOUDS)
                @battle.pbDisplay(_INTL("{1}'s attack is dampened a lot by the dreary rain.", user.pbThis))
            else
                @battle.pbDisplay(_INTL("{1}'s attack is dampened by the rain.", user.pbThis))
            end
        end
        if applySunDebuff?(user, type)
            if @battle.pbCheckGlobalAbility(:BLINDINGLIGHT)
                @battle.pbDisplay(_INTL("{1} is blinded by the bright light of the sun.", user.pbThis))
            else
                @battle.pbDisplay(_INTL("{1} is distracted by the shining sun.", user.pbThis))
            end
        end
    end

    def pbMissMessage(_user, _target); return false; end
    def pbShowFailMessages?(_targets); return true; end

    #=============================================================================
    #
    #=============================================================================
    # Whether the move is currently in the "charging" turn of a two turn attack.
    # Is false if Power Herb or another effect lets a two turn move charge and
    # attack in the same turn.
    # user.effects[:TwoTurnAttack] is set to the move's ID during the
    # charging turn, and is nil during the attack turn.
    def pbIsChargingTurn?(_user); return false; end

    def canParentalBond?(user, targets, checkingForAI = false)
        return false unless damagingMove?
        return false if chargingTurnMove?
        return false unless targets.length == 1
        return true if user.shouldAbilityApply?(:PARENTALBOND,checkingForAI)
        return true if user.shouldAbilityApply?(:STRIKETWICE,checkingForAI) && @battle.rainy?
        return false
    end

    def numberOfHits(user, targets, checkingForAI = false)
        calcedHits = calcNumHits(user, targets, checkingForAI)

        if user.shouldAbilityApply?(:LONGODDS, checkingForAI) && multiHitMove? && damagingMove?
            calcedHits2 = calcNumHits(user, targets, checkingForAI)
            if checkingForAI
                calcedHits += calcedHits2
            else
                calcedHits += @battle.pbRandom(calcedHits2 + 1)
            end
        end

        return calcedHits
    end

    def calcNumHits(user, targets, checkingForAI = false)
        if checkingForAI
            return pbNumHitsAI(user, targets)
        else
            return pbNumHits(user, targets, checkingForAI)
        end
    end

    # The maximum number of hits in a round this move will actually perform. This
    # can be 1 for Beat Up, and can be 2 for any moves affected by Parental Bond.
    def pbNumHits(user, targets, checkingForAI = false)
        return 2 if canParentalBond?(user, targets, checkingForAI)
        numHits = 1
        numHits += 1 if user.shouldAbilityApply?(:SPACEINTERLOPER, checkingForAI) && damagingMove?
        numHits += 1 if user.effectActive?(:VolleyStance) && specialMove?
        return numHits
    end

    #=============================================================================
    # Effect methods per hit
    #=============================================================================
    def pbOverrideSuccessCheckPerHit(_user, _target); return false; end
    def pbCrashDamage(user); end
    def pbInitialEffect(user, targets, hitNum); end
    def pbDesignateTargetsForHit(targets, _hitNum); return targets; end # For Dragon Darts
    def pbRepeatHit?(_hitNum = 0); return false; end # For Dragon Darts

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        return if @autoTesting
        return unless showAnimation
        if user.effects[:ParentalBond] == 1
            @battle.pbCommonAnimation("ParentalBond", user, targets)
        else
            @battle.pbAnimation(id, user, targets, hitNum)
        end
    end

    def pbSelfKO(user); end
    def pbEffectBeforeDealingDamage(user, target); end
    def pbEffectWhenDealingDamage(user, target); end
    def pbEffectAgainstTarget(user, target); end
    def pbEffectGeneral(user); end
    def pbAdditionalEffect(user, target); end
    def pbEffectAfterAllHits(user, target); end # Move effects that occur after all hits
    def pbSwitchOutTargetsEffect(user, targets, numHits, switchedBattlers); end
    def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers); end

    #=============================================================================
    # Check if target is immune to the move because of its ability
    #=============================================================================
    def pbImmunityByAbility(user, target, showMessages = true, aiCheck = false)
        return false if @battle.moldBreaker
        target.eachAbilityShouldApply(aiCheck) do |ability|
            return true if BattleHandlers.triggerMoveImmunityTargetAbility(ability, user, target, self, @calcType, @battle, showMessages, aiCheck)
        end
        target.eachAlly do |b|
            b.eachAbilityShouldApply(aiCheck) do |ability|
                return true if BattleHandlers.triggerMoveImmunityAllyAbility(ability, user, target, self, @calcType, @battle, b, showMessages)
            end
        end
        return false
    end

    #=============================================================================
    # Move failure checks
    #=============================================================================
    # Check whether the move fails completely due to move-specific requirements.
    def pbMoveFailed?(_user, _targets, _show_message); return false; end

    # Checks whether the move will be ineffective against the target.
    def pbFailsAgainstTarget?(_user, _target, _show_message); return false; end

    def pbMoveFailedAI?(user, targets)
        return pbMoveFailed?(user, targets, false)
    end

    def pbFailsAgainstTargetAI?(user, target)
        return pbFailsAgainstTarget?(user, target, false)
    end

    def pbMoveFailedLastInRound?(user, showMessage = true)
        unmoved = false
        @battle.eachBattler do |b|
            next if b.index == user.index
            next if @battle.choices[b.index][0] != :UseMove && @battle.choices[b.index][0] != :Shift
            next if b.movedThisRound?
            unmoved = true
            break
        end
        unless unmoved
            @battle.pbDisplay(_INTL("But it failed, since everyone else already acted this turn!")) if showMessage
            return true
        end
        return false
    end

    def pbMoveFailedTargetAlreadyMoved?(target, showMessage = true)
        if (@battle.choices[target.index][0] != :UseMove &&
           @battle.choices[target.index][0] != :Shift)
            @battle.pbDisplay(_INTL("But it failed, since {1} didn't choose to use a move!", target.pbThis(true))) if showMessage
            return true
        end
        if target.movedThisRound?
             @battle.pbDisplay(_INTL("But it failed, since {1} already move this turn!", target.pbThis(true))) if showMessage
             return true
        end
        return false
    end

    def pbMoveFailedAromaVeil?(_user, target, showMessage = true)
        return false if @battle.moldBreaker
        if target.hasActiveAbility?(:AROMAVEIL)
            if showMessage
                @battle.pbShowAbilitySplash(target, ability)
                @battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis))
                @battle.pbHideAbilitySplash(target)
            end
            return true
        end
        target.eachAlly do |b|
            next unless b.hasActiveAbility?(:AROMAVEIL)
            if showMessage
                @battle.pbShowAbilitySplash(target, ability)
                @battle.pbDisplay(_INTL("{1} is unaffected!", target.pbThis))
                @battle.pbHideAbilitySplash(target)
            end
            return true
        end
        return false
    end

    #=============================================================================
    # Weaken the damage dealt (doesn't actually change a battler's HP)
    #=============================================================================
    def pbCheckDamageAbsorption(user, target)
        # Substitute will take the damage
        if target.substituted? && !ignoresSubstitute?(user) && (!user || user.index != target.index)
            target.damageState.substitute = true
            return
        end
        # Disguise will take the damage
        if !@battle.moldBreaker && target.isSpecies?(:MIMIKYU) && target.form == 0 && target.hasActiveAbility?(:DISGUISE)
            target.damageState.disguise = true
            return
        end
        # Thief's Diversion will take the damage
        if target.hasActiveAbility?(:THIEFSDIVERSION) && target.hasAnyItem? && target.itemActive? && target.hasNonInitialItem? && !@battle.moldBreaker
            target.damageState.thiefsDiversion = true
            return
        end 
    end

    def damageNegated?(user, target, aiCheck = false)
        return true if target.effectActive?(:LastGasp)
        return false if aiCheck
        return true if target.damageState.disguise
        return true if target.damageState.thiefsDiversion
    end

    def pbReduceDamage(user, target)
        damage = target.damageState.calcDamage

        target.damageState.displayedDamage = damage

        if damageNegated?(user, target)
            target.damageState.displayedDamage = 0
            return
        end

        # Substitute takes the damage
        if target.damageState.substitute
            damage = target.effects[:Substitute] if damage > target.effects[:Substitute]
            target.damageState.hpLost       = damage
            target.damageState.totalHPLost += damage
            target.damageState.totalHPLostCritical += damage if target.damageState.critical
            target.damageState.displayedDamage = damage
            return
        end

        # Target takes the damage
        damageAdjusted = false

        # Bubble Barrier
        if target.effectActive?(:BubbleBarrier)
            damage /= 2
            target.damageState.bubbleBarrier = damage
            damageAdjusted = true
        end

        if damage >= target.hp
            damage = target.hp

            # Survive a lethal hit with 1 HP effects
            if nonLethal?(user, target)
                damage -= 1
                damageAdjusted = true
            elsif target.effectActive?(:Endure)
                target.damageState.endured = true
                damage -= 1
                damageAdjusted = true
            elsif target.effectActive?(:FightForever)
                target.damageState.fightforever = true
                damage -= 1
                damageAdjusted = true
            elsif target.effectActive?(:EmpoweredEndure)
                target.damageState.endured = true
                damage -= 1
                damageAdjusted = true
                target.tickDownAndProc(:EmpoweredEndure)
            elsif target.hasActiveAbility?(:DIREDIVERSION) && target.hasAnyItem? && target.itemActive? && !@battle.moldBreaker
                target.damageState.direDiversion = true
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveAbility?(:STURDY) && target.fullHealth? && !@battle.moldBreaker
                target.damageState.sturdy = true
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveAbility?(:SURVIVALIST) && target.fullHealth? && !@battle.moldBreaker
                target.damageState.survivalist = true
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveItem?(GameData::Item.getByFlag("Endure")) && target.fullHealth?
                target.damageState.focusSash = target.hasActiveItem?(GameData::Item.getByFlag("Endure"))
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveItem?(:CLARITYSASH)
                target.damageState.focusSash = :CLARITYSASH
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveItem?(:CASSBERRY) && target.fullHealth?
                target.damageState.endureBerry = true
                damage -= 1
                damageAdjusted = true
            elsif user.hasActiveAbility?(:ARCHVILLAIN)
                target.damageState.archVillain = user
                damage -= 1
                damageAdjusted = true
            elsif target.hasActiveAbility?(:ICEBLOCK) && target.form == 0 && !@battle.moldBreaker
                target.damageState.iceBlock = true
                damage -= 1
                damageAdjusted = true
            end

            # Bosses show mercy
            if AVATARS_FEAR_NOT_FAINT && !damageAdjusted && user.boss? && !target.boss?
                target.damageState.fear = true
                damage -= 1
                damageAdjusted = true
            end
        end

        target.damageState.displayedDamage = damage if damageAdjusted
        damage = 0 if damage < 0
        target.damageState.displayedDamage = 0 if target.damageState.displayedDamage < 0
        target.damageState.hpLost       = damage
        target.damageState.totalHPLost += damage
        target.damageState.totalHPLostCritical += damage if target.damageState.critical
    end

    #=============================================================================
    # Change the target's HP by the amount calculated above
    #=============================================================================
    def pbInflictHPDamage(target)
        if target.damageState.substitute
            target.effects[:Substitute] -= target.damageState.hpLost
        else
            target.hp -= target.damageState.hpLost
        end
    end

    #=============================================================================
    # Animate the damage dealt, including lowering the HP
    #=============================================================================
    # Animate being damaged and losing HP (by a move)
    def pbAnimateHitAndHPLost(user, targets, fastHitAnimation = false)
        return if @battle.autoTesting
        # Animate allies first, then foes
        animArray = []
        for side in 0...2 # side here means "allies first, then foes"
            targets.each do |b|
                next if b.damageState.unaffected || b.damageState.hpLost == 0
                next if (side == 0 && b.opposes?(user)) || (side == 1 && !b.opposes?(user))
                if b.damageState.substitute
                    oldHP = b.hp
                else
                    oldHP = b.hp + b.damageState.hpLost
                end
                PBDebug.log("[Move damage] #{b.pbThis} lost #{b.damageState.hpLost} HP (#{oldHP}=>#{b.hp})")
                effectiveness = b.damageState.typeMod
                animArray.push([b, oldHP, effectiveness])
            end
            if animArray.length > 0
                @battle.scene.pbHitAndHPLossAnimation(animArray, fastHitAnimation)
                animArray.clear
            end
        end
    end

    #=============================================================================
    # Messages upon being hit
    #=============================================================================
    def pbEffectivenessMessage(_user, target, numTargets = 1)
        return if target.damageState.disguise
        return if target.damageState.thiefsDiversion
        return if target.effectActive?(:LastGasp)
        return if defined?($Options.effectiveness_messages) && $Options.effectiveness_messages == 1
        if Effectiveness.hyper_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's hyper effective on {1}!", target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's hyper effective!"))
            end
        elsif Effectiveness.super_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's super effective on {1}!", target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's super effective!"))
            end
        elsif Effectiveness.barely_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's barely effective on {1}...", target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's barely effective..."))
            end
        elsif Effectiveness.not_very_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's not very effective on {1}...", target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's not very effective..."))
            end
        end

        if Effectiveness.super_effective?(target.damageState.typeMod) && target.pbOwnedByPlayer? &&
                !$PokemonGlobal.typeChartChangesTutorialized
            newWeakness = false
            newWeakness = true if @calcType == :POISON && target.pbHasType?(:WATER)
            newWeakness = true if @calcType == :BUG && target.pbHasType?(:FAIRY)
            newWeakness = true if @calcType == :PSYCHIC && target.pbHasType?(:STEEL)
            playTypeChartChangesTutorial if newWeakness
        end
    end

    def pbHitEffectivenessMessages(user, target, numTargets = 1)
        return if target.damageState.disguise
        return if target.damageState.thiefsDiversion
        if target.damageState.substitute
            @battle.pbDisplay(_INTL("The substitute took damage for {1}!", target.pbThis(true)))
        end
        if target.damageState.critical
            onAddendum = numTargets > 1 ? _INTL(" on {1}", target.pbThis(true)) : ""
            if target.damageState.forced_critical
                @battle.pbDisplay(_INTL("It was a guaranteed critical hit{1}!", onAddendum))
            else
                @battle.pbDisplay(_INTL("A critical hit{1}!", onAddendum))
            end
        end
        # Effectiveness message, for moves with 1 hit
        pbEffectivenessMessage(user, target, numTargets) if target.damageState.messagesPerHit
        if target.damageState.substitute && !target.substituted? # Substitute ran out of HP
            target.disableEffect(:Substitute)
            @battle.pbDisplay(_INTL("{1}'s substitute faded!", target.pbThis))
        end
    end

    def pbEndureKOMessage(target)
        if target.damageState.disguise
            @battle.pbShowAbilitySplash(target, :DISGUISE)
            @battle.pbDisplay(_INTL("Its disguise served it as a decoy!"))
            @battle.pbHideAbilitySplash(target)
            target.pbChangeForm(1, _INTL("{1}'s disguise was busted!", target.pbThis))
        elsif target.damageState.iceBlock
            @battle.pbShowAbilitySplash(target, :ICEBLOCK)
            @battle.pbDisplay(_INTL("{1} endured the hit!", target.pbThis))
            target.pbChangeForm(1, _INTL("{1} transformed!", target.pbThis))
            @battle.pbHideAbilitySplash(target)
        elsif target.damageState.endured
            @battle.pbDisplay(_INTL("{1} endured the hit!", target.pbThis))
        elsif target.damageState.sturdy
            @battle.pbShowAbilitySplash(target, :STURDY)
            @battle.pbDisplay(_INTL("{1} endured the hit!", target.pbThis))
            @battle.pbHideAbilitySplash(target)
        elsif target.damageState.survivalist
            @battle.pbShowAbilitySplash(target, :SURVIVALIST)
            @battle.pbDisplay(_INTL("{1} survived the hit!", target.pbThis))
            @battle.pbHideAbilitySplash(target)
        elsif target.damageState.focusSash
            @battle.pbCommonAnimation("UseItem", target)
            @battle.pbDisplay(_INTL("{1} hung on using its {2}!", target.pbThis, getItemName(target.damageState.focusSash)))
            target.consumeItem(target.damageState.focusSash)
        elsif target.damageState.focusBand
            @battle.pbCommonAnimation("UseItem", target)
            @battle.pbDisplay(_INTL("{1} hung on using its Focus Band!", target.pbThis))
        elsif target.damageState.direDiversion
            @battle.pbDisplay(_INTL("{1} blocked the hit with its item! It barely hung on!", target.pbThis))
            target.consumeItem(target.items[0], belch: false)
        elsif target.damageState.endureBerry
            @battle.pbDisplay(_INTL("{1} hung on by consuming its {2}!", target.pbThis, getItemName(:CASSBERRY)))
            target.consumeItem(:CASSBERRY) if target.hasItem?(:CASSBERRY)
        elsif target.damageState.archVillain
            user = target.damageState.archVillain
            @battle.pbShowAbilitySplash(user,:ARCHVILLAIN)
            @battle.pbDisplay(_INTL("{1} lets out an arrogant laugh!", user.pbThis))
            @battle.pbHideAbilitySplash(user)
        elsif target.damageState.thiefsDiversion
            @battle.pbShowAbilitySplash(target, :THIEFSDIVERSION)
            @battle.pbDisplay(_INTL("{1} blocked the hit with its item!", target.pbThis))
            target.removeNonInitialItems
            @battle.pbHideAbilitySplash(target)
        end        
    end

    # Used by Counter/Mirror Coat/Metal Burst/Revenge/Focus Punch/Bide/Assurance.
    def pbRecordDamageLost(user, target)
        damage = target.damageState.hpLost
        # NOTE: In Gen 3 where a move's category depends on its type, Hidden Power
        #       is for some reason countered by Counter rather than Mirror Coat,
        #       regardless of its calculated type. Hence the following two lines of
        #       code.
        moveType = nil
        moveType = :NORMAL if @function == "090" # Hidden Power
        if physicalMove?(moveType)
            target.applyEffect(:Counter, damage)
            target.pointAt(:CounterTarget, user)
        elsif specialMove?(moveType)
            target.applyEffect(:MirrorCoat, damage)
            target.pointAt(:MirrorCoatTarget, user)
        end
        if target.effectActive?(:Bide)
            target.effects[:BideDamage] += damage * 2
            target.pointAt(:BideTarget, user) if user.index != target.index
        end
        target.damageState.fainted = true if target.fainted? || target.damageState.fear
        target.lastHPLost = damage # For Focus Punch
        target.tookDamage = true if damage > 0 # For Assurance
        target.lastAttacker.push(user.index) # For Revenge
        if target.opposes?(user)
            target.lastHPLostFromFoe = damage # For Metal Burst
            target.lastFoeAttacker.push(user.index) unless target.lastFoeAttacker.include?(user.index) # For Metal Burst
            if target.damageState.typeMod > target.lastRoundHighestTypeModFromFoe
                target.lastRoundHighestTypeModFromFoe = target.damageState.typeMod
            end
        end
    end
end
