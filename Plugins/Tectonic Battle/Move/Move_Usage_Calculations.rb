CRITICAL_HIT_RATIOS = [16, 8, 4, 2, 1]

class PokeBattle_Move
    #=============================================================================
    # Move's type calculation
    #=============================================================================
    def pbBaseType(user)
        ret = @type
        if ret
            user.eachActiveAbility do |ability|
                ret = BattleHandlers.triggerMoveBaseTypeModifierAbility(ability, user, self, ret)
            end
        end
        if ret == :FLEX
            userTypes = user.pbTypes(true)
            if userTypes.empty?
                ret = :NORMAL
            else
                ret = userTypes[0]
            end
        end
        return ret
    end

    def pbCalcType(user)
        @powerBoost = false
        ret = pbBaseType(user)
        if ret && GameData::Type.exists?(:ELECTRIC)
            if @battle.field.effectActive?(:IonDeluge) && ret == :NORMAL
                ret = :ELECTRIC
                @powerBoost = false
            end
            if user.effectActive?(:Electrify)
                ret = :ELECTRIC
                @powerBoost = false
            end
        end
        return ret
    end

    #=============================================================================
    # Type effectiveness calculation
    #=============================================================================
    def pbCalcTypeModSingle(moveType, defType, user = nil, target = nil)
        ret = Effectiveness.calculate_one(moveType, defType)
        # Ring Target
        if target&.hasActiveItem?(:RINGTARGET) && Effectiveness.ineffective_type?(moveType, defType)
            ret = Effectiveness::NORMAL_EFFECTIVE
        end
        # Delta Stream's weather
        if @battle&.pbWeather == :StrongWinds && (defType == :FLYING && Effectiveness.super_effective_type?(moveType, defType))
            ret = Effectiveness::NORMAL_EFFECTIVE
        end
        # Grounded Flying-type Pokémon become susceptible to Ground moves
        ret = Effectiveness::NORMAL_EFFECTIVE if !target&.airborne? && (defType == :FLYING && moveType == :GROUND)
        # Inured
        ret /= 2 if target&.effectActive?(:Inured) && Effectiveness.super_effective_type?(moveType, defType)
        # Break Through
        if user&.hasActiveAbility?(:BREAKTHROUGH) && Effectiveness.ineffective_type?(moveType, defType)
            ret = Effectiveness::NORMAL_EFFECTIVE
        end
        return ret
    end

    def pbCalcTypeMod(moveType, user, target, uiOnlyCheck = false)
        return Effectiveness::NORMAL_EFFECTIVE unless moveType

        # Determine types
        tTypes = target.pbTypes(true, uiOnlyCheck)

        immunityPierced = false

        # Get effectivenesses
        ret = 1
        tTypes.each do |type|
            next if moveType == :GROUND && type == :FLYING && target.hasActiveItem?(:IRONBALL)
            ret *= pbCalcTypeModSingle(moveType, type, user, target)
        end

        # Partially pierce immunities
        if inherentImmunitiesPierced?(user, target)
            # This is done here because its skipped in pbSuccessCheckAgainstTarget
            if !uiOnlyCheck && user.targetInherentlyImmune?(user, target, self)
                immunityPierced = true
                ret /= 2
            elsif user.targetTypeModImmune?(user, target, self, ret, !uiOnlyCheck)
                ret = 4.0 # Weird effectiveness stuff present here
                immunityPierced = true
            end
        end

        # Explain to the player what is happening
        if immunityPierced && !uiOnlyCheck && $Options.avatar_mechanics_messages == 0
            if AVATARS_REGULAR_ATTACKS_PIERCE_IMMUNITIES
                @battle.pbDisplay(_INTL("Near the avatar, immunities are resistances!"))
            else
                @battle.pbDisplay(_INTL("The Empowered attack pierced the immunity!"))
            end
        end

        # Creep Out
        ret *= 2 if target.effectActive?(:CreepOut) && moveType == :BUG

        # Tar Shot
        ret *= 2 if target.effectActive?(:TarShot) && moveType == :FIRE

        # Modify effectiveness for bosses
        ret = Effectiveness.modify_boss_effectiveness(ret, user, target)

        # Type effectiveness changing curses
        @battle.curses.each do |curse|
            ret = @battle.triggerEffectivenessChangeCurseEffect(curse, moveType, user, target, ret)
        end

        return ret
    end

    #=============================================================================
    # Accuracy check
    #=============================================================================
    def pbBaseAccuracy(_user, _target); return @accuracy; end

    # Accuracy calculations for one-hit KO moves and "always hit" moves are
    # handled elsewhere.
    def pbAccuracyCheck(user, target)
        # "Always hit" effects and "always hit" accuracy
        return true if target.effectActive?(:Telekinesis)
        baseAcc = pbBaseAccuracy(user, target)
        return true if baseAcc == 0
        # Calculate all multiplier effects
        modifiers = {}
        modifiers[:base_accuracy] = baseAcc
        modifiers[:accuracy_step] = user.steps[:ACCURACY]
        modifiers[:evasion_step]  = target.steps[:EVASION]
        modifiers[:accuracy_multiplier] = 1.0
        modifiers[:evasion_multiplier]  = 1.0
        pbCalcAccuracyModifiers(user, target, modifiers)
        # Check if move can't miss
        return true if modifiers[:base_accuracy] == 0
        # Calculation
        statBoundary = PokeBattle_Battler::STAT_STEP_BOUND
        accStep = modifiers[:accuracy_step].clamp(-statBoundary, statBoundary)
        evaStep = modifiers[:evasion_step].clamp(-statBoundary, statBoundary)
        accuracy = 100.0 * user.statMultiplierAtStep(accStep)
        evasion  = 100.0 * user.statMultiplierAtStep(evaStep)
        accuracy = (accuracy.to_f * modifiers[:accuracy_multiplier].to_f).round
        evasion  = (evasion.to_f  * modifiers[:evasion_multiplier].to_f).round
        accuracy = (accuracy.to_f + 100.0) / 2.0 if user.boss? && AVATAR_DILUTED_STAT_STEPS
        evasion = (evasion.to_f + 100.0) / 2.0 if target.boss? && AVATAR_DILUTED_STAT_STEPS
        evasion = 1 if evasion < 1
        # Calculation
        calc = accuracy.to_f / evasion.to_f
        return @battle.pbRandom(100) < modifiers[:base_accuracy] * calc
    end

    def pbCalcAccuracyModifiers(user, target, modifiers, aiCheck = false, aiType = nil)
        typeToUse = aiCheck ? aiType : @calcType
        # Ability effects that alter accuracy calculation
        user.eachAbilityShouldApply(aiCheck) do |ability|
            BattleHandlers.triggerAccuracyCalcUserAbility(ability, modifiers, user, target, self, typeToUse)
        end
        user.eachAlly do |ally|
            ally.eachAbilityShouldApply(aiCheck) do |ability|
                BattleHandlers.triggerAccuracyCalcUserAllyAbility(ability, modifiers, user, target, self, typeToUse)
            end
        end
        unless @battle.moldBreaker
            target.eachAbilityShouldApply(aiCheck) do |ability|
                BattleHandlers.triggerAccuracyCalcTargetAbility(ability, modifiers, user, target, self, typeToUse)
            end
        end
        # Item effects that alter accuracy calculation
        user.eachActiveItem do |item|
            BattleHandlers.triggerAccuracyCalcUserItem(item, modifiers, user, target, self, typeToUse, aiCheck)
        end
        target.eachActiveItem do |item|
            BattleHandlers.triggerAccuracyCalcTargetItem(item, modifiers, user, target, self, typeToUse)
        end
        # Other effects, inc. ones that set accuracy_multiplier or evasion_step to
        # specific values
        modifiers[:accuracy_multiplier] *= 2.0 if @battle.gravityIntensified?
        modifiers[:accuracy_multiplier] *= 1.5 if user.effectActive?(:Spotting)

        if aiCheck
            modifiers[:evasion_step] = 0 if @function == "IgnoreTargetDefSpDefEvaStatStages" # Chip Away
            if %w[AlwaysHits RemoveProtectionsBypassSubstituteAlwaysHits HyperspaceFury].include?(@name)
                modifiers[:base_accuracy] = 0
            end # "Always hit"
            modifiers[:base_accuracy] = 0 if user.effectActive?(:LockOn) && user.pointsAt?(:LockOnPos, target)
        end
    end

    #=============================================================================
    # Critical hit check
    #=============================================================================
    # Return values:
    #   -1: Never a critical hit.
    #    0: Calculate normally.
    #    1: Always a critical hit.
    def pbCriticalOverride(_user, _target); return 0; end

    # Returns whether the attack is critical, and whether it was forced to be so
    def pbIsCritical?(user, target, checkingForAI = false)
        allowedToRandomCrit = allowedToRandomCrit?(user, target)

        crit = false
        forced = false

        if guaranteedCrit?(user, target)
            crit = true
            forced = true
        elsif allowedToRandomCrit
            rate = criticalHitRate(user, target)
            if isRandomCrit?(user, target, rate)
                crit = true
            end
        end

        if crit && critsPrevented?(user, target, checkingForAI)
            crit = false
            forced = true
        end

        if checkingForAI
            if forced
                return crit
            elsif allowedToRandomCrit
                # If the rate is high enough,
                # A "random" crit is actually guaranteed
                return rate >= CRITICAL_HIT_RATIOS.length - 1
            else
                return false
            end
        else
            return crit, forced
        end
    end

    def isRandomCrit?(user, target, rate)
        # Calculation
        rate = CRITICAL_HIT_RATIOS.length - 1 if rate >= CRITICAL_HIT_RATIOS.length
        denom = CRITICAL_HIT_RATIOS[rate]
        echoln("[CRITICAL HIT RATE] Critical hit rate for #{user.pbThis(true)}'s #{@id} against target #{target.pbThis(true)} is 1 in #{denom}")
        return @battle.pbRandom(denom) == 0
    end

    def criticalHitRate(user, target)
        c = 0

        c += 1 if canRandomCrit?

        # Ability effects that alter critical hit rate
        user.eachActiveAbility do |ability|
            c = BattleHandlers.triggerCriticalCalcUserAbility(ability, user, target, self, c)
        end
        user.eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                c = BattleHandlers.triggerCriticalCalcUserAllyAbility(ability, user, target, self, c)
            end
        end
        unless @battle.moldBreaker
            target.eachActiveAbility do |ability|
                c = BattleHandlers.triggerCriticalCalcTargetAbility(ability, user, target, c)
            end
        end
        # Item effects that alter critical hit rate
        user.eachActiveItem do |item|
            c = BattleHandlers.triggerCriticalCalcUserItem(item, user, target, c)
        end
        target.eachActiveItem do |item|
            c = BattleHandlers.triggerCriticalCalcTargetItem(item, user, target, c)
        end

        c += 1 if doubleCritChance?
        c += user.effects[:RaisedCritChance]

        return c
    end

    def critsPrevented?(user, target, checkingForAI = false)
        # Critical prevention abilities
        unless @battle.moldBreaker
            target.eachActiveAbility do |ability|
                next unless BattleHandlers.triggerCriticalPreventTargetAbility(ability, user, target, @battle)
                unless checkingForAI
                    battle.pbShowAbilitySplash(target, ability)
                    battle.pbDisplay(_INTL("{1} prevents the hit from being critical!", target.pbThis))
                    battle.pbHideAbilitySplash(target)
                end
                return true
            end
        end

        # Hearsh Sunlight
        if @battle.pbWeather == :HarshSun && applySunDebuff?(user, @calcType, checkingForAI)
            unless checkingForAI
                battle.pbDisplay(_INTL("The harsh sunlight prevents the hit from being critical!", target.pbThis))
            end
            return true
        end

        # Lucky Chant
        if target.pbOwnSide.effectActive?(:LuckyChant)
            unless checkingForAI
                battle.pbDisplay(_INTL("The blessing around {1} prevented the hit from being critical!", target.pbTeam(true)))
            end
            return true
        end

        # Diamond Field
        if target.pbOwnSide.effectActive?(:DiamondField) && !(user && user.hasActiveAbility?(:INFILTRATOR))
            unless checkingForAI
                battle.pbDisplay(_INTL("The sheen around {1} prevented the hit from being critical!", target.pbTeam(true)))
            end
            return true
        end

        return true if pbCriticalOverride(user, target) < 0
        return false
    end

    def guaranteedCrit?(user, target)
        return true if target.effectActive?(:Jinxed)
        return true if user.effectActive?(:LaserFocus) || user.effectActive?(:EmpoweredLaserFocus)
        return true if user.effectActive?(:LuckyCheer)
        return true if pbCriticalOverride(user, target) > 0
        user.eachActiveAbility do |ability|
            return true if BattleHandlers.triggerGuaranteedCriticalUserAbility(ability, user, target, @battle)
        end
        return false
    end

    def allowedToRandomCrit?(user, target)
        return true if canRandomCrit?  
        return true if user.effectActive?(:RaisedCritChance)
        return true if user.hasActiveAbility?(GameData::Ability.getByFlag("EnablesRandomCrits")) 
        return false
    end

    #=============================================================================
    # Antecedents for damage calculation
    #=============================================================================
    def pbBaseDamage(baseDmg, _user, _target);              return baseDmg;    end

    # For when the damage boost must be applied after the move usage has progressed
    # Or the damage mult is ugly and will result in weird display BP
    def pbModifyDamage(damageMult, _user, _target);         return damageMult; end

    def ignoresDefensiveStepBoosts?(_user, _target); return false; end

    def pbAttackingStat(user, target, checkingForAI = false)
        return user, :SPECIAL_ATTACK if specialMove?
        return user, :ATTACK
    end

    def pbDefendingStat(user, target, checkingForAI = false)
        return target, :SPECIAL_DEFENSE if specialMove?
        return target, :DEFENSE
    end

    #=============================================================================
    # Additional effect chance
    #=============================================================================
    def canApplyRandomAddedEffects?(user, target, showMessages = false, aiCheck = false)
        unless @battle.moldBreaker
            target.eachAbilityShouldApply(aiCheck) do |ability|
                next unless BattleHandlers.triggerPreventAddedEffectTargetAbility(ability, @battle, user, target, self,
showMessages)
                return false
            end
        end
        if @battle.pbWeather == :HeavyRain && applyRainDebuff?(user, @calcType, aiCheck)
            if showMessages
                battle.pbDisplay(_INTL("The heavy rain prevents a random added effect!"))
            end
            return false
        end
        if target.pbOwnSide.effectActive?(:WishingWell)
            if showMessages
                battle.pbDisplay(_INTL("The Wishing Well protects {1} from a random added effect!", target.pbThis))
            end
            return false
        end
        if target.shouldItemApply?(:COVERTCLOAK, aiCheck) && user.opposes?(target)
            if showMessages
                battle.pbDisplay(_INTL("{1}'s {2} protects it from a random added effect!", target.pbThis, getItemName(:COVERTCLOAK)))
                target.aiLearnsItem(:COVERTCLOAK)
            end
            return false
        end
        return true
    end

    def pbAdditionalEffectChance(user, target, type, effectChance = 0, aiCheck = false)
        return 100 if @battle.pbCheckGlobalAbility(:WISHMAKER)
        # Abilities ensure effect chance
        user.eachAbilityShouldApply(aiCheck) do |ability|
            return 100 if BattleHandlers.triggerCertainAddedEffectUserAbility(ability, @battle, user, target, self)
        end
        return 100 if !user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_PERFECT_LUCK)
        ret = effectChance > 0 ? effectChance : @effectChance
        return 100 if ret >= 100 || debugControl
        ret += 30 if user.hasTribeBonus?(:FORTUNE)

        # User's abilities modify effect chance
        user.eachAbilityShouldApply(aiCheck) do |ability|
            ret = BattleHandlers.triggerAddedEffectChanceModifierUserAbility(ability, user, target, self, ret)
        end

        # User's ally's abilities modify effect chance
        user.eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                ret = BattleHandlers.triggerAddedEffectChanceModifierUserAllyAbility(ability, user, target, self, ret)
            end
        end

        # Target's abilities modify effect chance
        unless @battle.moldBreaker
            target.eachAbilityShouldApply(aiCheck) do |ability|
                ret = BattleHandlers.triggerAddedEffectChanceModifierTargetAbility(ability, user, target, self, ret)
            end
        end

        ret *= 2 if user.pbOwnSide.effectActive?(:Rainbow)
        if ret < 100 && user.shouldItemApply?(:LUCKHERB, aiCheck)
            ret = 100
            user.applyEffect(:LuckHerbConsumed) unless aiCheck
        end
        return ret
    end

    # NOTE: Flinching caused by a move's effect is applied in that move's code,
    #       not here.
    def pbFlinchChance(user, _target)
        return 0 if flinchingMove?
        ret = 0
        ret = 50 if user.hasActiveAbility?(:STENCH, true)
        ret *= 2 if user.hasActiveAbility?(:SERENEGRACE) ||
                    user.pbOwnSide.effectActive?(:Rainbow)
        return ret
    end
end