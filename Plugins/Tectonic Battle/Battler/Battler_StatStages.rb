ALL_STATS_1 = [:ATTACK, 1, :SPECIAL_ATTACK, 1, :DEFENSE, 1, :SPECIAL_DEFENSE, 1, :SPEED, 1].freeze
ALL_STATS_2 = [:ATTACK, 2, :SPECIAL_ATTACK, 2, :DEFENSE, 2, :SPECIAL_DEFENSE, 2, :SPEED, 2].freeze
ALL_STATS_3 = [:ATTACK, 3, :SPECIAL_ATTACK, 3, :DEFENSE, 3, :SPECIAL_DEFENSE, 3, :SPEED, 3].freeze
ATTACKING_STATS_1 = [:ATTACK, 1, :SPECIAL_ATTACK, 1].freeze
ATTACKING_STATS_2 = [:ATTACK, 2, :SPECIAL_ATTACK, 2].freeze
ATTACKING_STATS_3 = [:ATTACK, 3, :SPECIAL_ATTACK, 3].freeze
DEFENDING_STATS_1 = [:DEFENSE, 1, :SPECIAL_DEFENSE, 1].freeze
DEFENDING_STATS_2 = [:DEFENSE, 2, :SPECIAL_DEFENSE, 2].freeze
DEFENDING_STATS_3 = [:DEFENSE, 3, :SPECIAL_DEFENSE, 3].freeze

class PokeBattle_Battler
    def validateStat(stat)
        raise "Given #{stat} is not a symbol!" unless stat.is_a?(Symbol)
        statData = GameData::Stat.try_get(stat)
        raise "Symbol #{stat} is not a valid stat ID!" unless statData
        raise "Symbol #{stat} is not a battle stat!" unless %i[main_battle battle].include?(statData.type)
    end

    #=============================================================================
    # Calculate stats based on stat steps.
    #=============================================================================
    STAT_STEP_BOUND = 8
    STEP_MULTIPLIERS = [2, 2,   2, 2,   2, 2,   2, 2,   2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6].freeze
    STEP_DIVISORS    = [6, 5.5, 5, 4.5, 4, 3.5, 3, 2.5, 2, 2,   2, 2,   2, 2,   2, 2,   2].freeze

    def statMultiplierAtStep(step)
        if step < -STAT_STEP_BOUND || step > STAT_STEP_BOUND
            raise "Given stat step value #{step} is not valid! Must be between -#{STAT_STEP_BOUND} and #{STAT_STEP_BOUND}, inclusive."
        end
        shiftedStep = step + STAT_STEP_BOUND
        mult = STEP_MULTIPLIERS[shiftedStep].to_f / STEP_DIVISORS[shiftedStep].to_f
        mult = (mult + 1.0) / 2.0 if boss? && AVATAR_DILUTED_STAT_STEPS
        return mult
    end

    def statAfterStep(stat, step = nil)
        step = @steps[stat] if step.nil?
        return (getPlainStat(stat) * statMultiplierAtStep(step)).floor
    end

    def finalStats
        ret = {}
        ret[:ATTACK]          = pbAttack
        ret[:DEFENSE]         = pbDefense
        ret[:SPECIAL_ATTACK]  = pbSpAtk
        ret[:SPECIAL_DEFENSE] = pbSpDef
        ret[:SPEED]           = pbSpeed
        return ret
    end

    # Returns an array of [stat, value]
    def highestStatAndValue
        return finalStats.max_by { |_k, v| v }
    end

    def highestStat
        return highestStatAndValue[0]
    end

    def highestStatValue
        return highestStatAndValue[1]
    end

    #=============================================================================
    # Increase stat steps
    #=============================================================================
    def statStepAtMax?(stat)
        return @steps[stat] >= STAT_STEP_BOUND
    end

    def pbCanRaiseStatStep?(stat, user = nil, move = nil, showFailMsg = false, ignoreContrary = false, ignoreAbilities: false)
        validateStat(stat)
        return false if fainted?
        killjoy = @battle.pbCheckGlobalAbility(:KILLJOY)
        if killjoy
            if showFailMsg
                @battle.pbDisplay(_INTL("{1}'s {2} prevents {3} from raising its {4}!", killjoy.pbThis, getAbilityName(:KILLJOY), pbThis(true), GameData::Stat.get(stat).name))
            end
            return false
        end
        # Contrary
        if hasActiveAbility?(%i[CONTRARY INVERSION]) && !ignoreContrary && !@battle.moldBreaker && !ignoreAbilities
            return pbCanLowerStatStep?(stat, user, move, showFailMsg, true, ignoreAbilities: ignoreAbilities)
        end
        # Check the stat step
        if statStepAtMax?(stat)
            if showFailMsg
                @battle.pbDisplay(_INTL("{1}'s {2} won't go any higher!", pbThis, GameData::Stat.get(stat).name))
            end
            return false
        end
        return true
    end

    # Fails silently
    def tryRaiseStat(stat, user, move: nil, increment: 1, showFailMsg: false, showAnim: true, ability: nil, cause: nil, item: nil, ignoreContrary: false)
        return false if increment <= 0
        lowered = false
        if pbCanRaiseStatStep?(stat, user, move, showFailMsg, ignoreContrary)
            @battle.pbShowAbilitySplash(user, ability) if ability
            if item
                cause = GameData::Item.get(item).name
                @battle.pbCommonAnimation("UseItem", user)
                lowered = true if pbRaiseStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: ignoreContrary)
            elsif cause
                lowered = true if pbRaiseStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: ignoreContrary)
            elsif pbRaiseStatStep(stat, increment, user, showAnim, ignoreContrary)
                lowered = true
            end
        end
        @battle.pbHideAbilitySplash(user) if ability
        return lowered
    end

    def pbRaiseStatStepBasic(stat, increment)
        increment *= 2 if hasActiveAbility?(:SIMPLE) && !@battle.moldBreaker
        # Change the stat step
        increment = [increment, STAT_STEP_BOUND - @steps[stat]].min
        if increment.positive?
            stat_name = GameData::Stat.get(stat).name
            new = @steps[stat] + increment
            PBDebug.log("[Stat change] #{pbThis}'s #{stat_name}: #{@steps[stat]} -> #{new} (+#{increment})")
            @steps[stat] += increment
        end
        return increment
    end

    def pbRaiseStatStep(stat, increment, user = nil, showAnim = true, ignoreContrary = false)
        # Contrary
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:CONTRARY)
            return pbLowerStatStep(stat, increment, user, showAnim, true)
        end
        # INVERSION
        if hasActiveAbility?(:INVERSION) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:INVERSION)
            increment = (increment / 2.0).ceil
            return pbLowerStatStep(stat, increment, user, showAnim, true)
        end
        increment = raiseStatStepEX(stat, increment, user: user, showAnim: showAnim)
        return true
    end

    def raiseStatStepEX(stat, increment, user: nil, showMessages: true, showAnim: true)
        # Perform the stat step change
        increment = pbRaiseStatStepBasic(stat, increment)
        return false if increment <= 0
        # Stat up animation and message
        @battle.pbCommonAnimation("StatUp", self) if showAnim
        increment /= 2.0 if boss? && AVATAR_DILUTED_STAT_STEPS

        showStatChangeMessage(stat, increment, lowering: false) if showMessages

        triggersOnStatGain(stat, increment, user: user)

        return increment
    end

    def pbRaiseStatStepByCause(stat, increment, user, cause, showAnim: true, ignoreContrary: false)
        # Contrary
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:CONTRARY)
            return pbLowerStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: true)
        end
        # INVERSION
        if hasActiveAbility?(:INVERSION) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:INVERSION)
            increment = (increment / 2.0).ceil
            return pbLowerStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: true)
        end
        # Perform the stat step change
        increment = pbRaiseStatStepBasic(stat, increment)
        return false if increment <= 0
        # Stat up animation and message
        @battle.pbCommonAnimation("StatUp", self) if showAnim
        increment /= 2.0 if boss? && AVATAR_DILUTED_STAT_STEPS
        if user.index == @index
            if increment == 1
                raiseMessage = _INTL("{1}'s {2} raised its {3}!", pbThis, cause, GameData::Stat.get(stat).name)
            else
                raiseMessage = _INTL("{1}'s {2} raised its {3} by {4} steps!", pbThis, cause, GameData::Stat.get(stat).name, increment)
            end
        else
            if increment == 1
                raiseMessage = _INTL("{1}'s {2} raised {3}'s {4}!", pbThis, cause, pbThis(true), GameData::Stat.get(stat).name)
            else
                raiseMessage = _INTL("{1}'s {2} raised {3}'s {4} by {5} steps!", pbThis, cause, pbThis(true), GameData::Stat.get(stat).name, increment)
            end
        end
        @battle.pbDisplay(raiseMessage)
        triggersOnStatGain(stat, increment, user: user)
        return true
    end

    def pbRaiseStatStepByAbility(stat, increment, user, ability: nil)
        return false if fainted?
        return false if statStepAtMax?(stat)
        ret = false
        @battle.pbShowAbilitySplash(user, ability) if ability
        ret = pbRaiseStatStep(stat, increment, user) if pbCanRaiseStatStep?(stat, user, nil, true)
        @battle.pbHideAbilitySplash(user) if ability
        return ret
    end

    def pbMaximizeStatStep(stat, user = nil, move = nil, ignoreContrary = false, ability: nil)
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary
            aiLearnsAbility(:CONTRARY)
            pbMinimizeStatStep(stat, user, move, true, ability: ability)
        elsif hasActiveAbility?(:INVERSION) && !ignoreContrary
            aiLearnsAbility(:INVERSION)
            increment = ((STAT_STEP_BOUND + @steps[stat]) / 2.0).ceil
            tryLowerStat(stat, user, move: move, increment: increment, ability: ability)
        elsif pbCanRaiseStatStep?(stat, user, move, true, ignoreContrary)
            @battle.pbShowAbilitySplash(user, ability) if ability
            increment = STAT_STEP_BOUND - @steps[stat]
            @steps[stat] = STAT_STEP_BOUND
            @battle.pbCommonAnimation("StatUp", self)
            statName = GameData::Stat.get(stat).name
            @battle.pbDisplay(_INTL("{1} maximizes its {2}!", pbThis, statName))

            triggersOnStatGain(stat, increment, user: user)

            @battle.pbHideAbilitySplash(user) if ability
        end
    end

    def triggersOnStatGain(stat, increment, user: nil)
        playStatStepsTutorial unless $PokemonGlobal.statStepsTutorialized

        applyEffect(:StatsRaised)

        # Trigger abilities upon stat gain
        eachActiveAbility do |ability|
            BattleHandlers.triggerAbilityOnStatGain(ability, self, stat, user)
        end
        eachOpposing do |b|
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityOnEnemyStatGain(ability, b, stat, increment, user, @battle, self)
            end
            b.eachActiveItem do |item|
                BattleHandlers.triggerItemOnEnemyStatGain(item, b, stat, increment, user, @battle, self)
            end
        end
    end

    #=============================================================================
    # Decrease stat steps
    #=============================================================================
    def statStepAtMin?(stat)
        return @steps[stat] <= -STAT_STEP_BOUND
    end

    def pbCanLowerStatStep?(stat, user = nil, move = nil, showFailMsg = false, ignoreContrary = false, ignoreAbilities: false)
        validateStat(stat)
        return false if fainted?
        # Contrary
        if hasActiveAbility?(%i[CONTRARY INVERSION]) && !ignoreContrary && !@battle.moldBreaker && !ignoreAbilities
            return pbCanRaiseStatStep?(stat, user, move, showFailMsg, true, ignoreAbilities: ignoreAbilities)
        end
        if !user || user.index != @index # Not self-inflicted
            if substituted? && !(move && move.ignoresSubstitute?(user))
                @battle.pbDisplay(_INTL("{1} is protected by its substitute!", pbThis)) if showFailMsg
                return false
            end
            if pbOwnSide.effectActive?(:Mist) && !(user && user.hasActiveAbility?(:INFILTRATOR))
                @battle.pbDisplay(_INTL("{1} is protected by Mist!", pbThis)) if showFailMsg
                return false
            end
            unless ignoreAbilities
                eachActiveAbility do |ability|
                    return false if BattleHandlers.triggerStatLossImmunityAbilityNonIgnorable(ability, self, stat, @battle, showFailMsg)
                end
                unless @battle.moldBreaker
                    eachActiveAbility do |ability|
                        return false if BattleHandlers.triggerStatLossImmunityAbility(ability, self, stat, @battle, showFailMsg)
                    end

                    eachAlly do |b|
                        b.eachActiveAbility do |ability|
                            return false if BattleHandlers.triggerStatLossImmunityAllyAbility(ability, b, self, stat, @battle, showFailMsg)
                        end
                    end
                end
            end
            if hasTribeBonus?(:SCRAPPER) && stat == :DEFENSE
                if showFailMsg
                    @battle.pbShowTribeSplash(self,:SCRAPPER)
                    @battle.pbDisplay(_INTL("{1}'s attitude prevents its Defense from lowering!", pbThis))
                    @battle.pbHideTribeSplash(self)
                end
                return false
            end
            if hasTribeBonus?(:RADIANT) && stat == :SPECIAL_DEFENSE
                if showFailMsg
                    @battle.pbShowTribeSplash(self,:RADIANT)
                    @battle.pbDisplay(_INTL("{1}'s sheen prevents its Sp. Def from lowering!", pbThis))
                    @battle.pbHideTribeSplash(self)
                end
                return false
            end
            if hasActiveItem?(:CLEARAMULET)
                if showFailMsg
                    @battle.pbDisplay(_INTL("{1} is protected by its Clear Amulet!", pbThis))
                end
                return false
            end
        elsif effectActive?(:EmpoweredFlowState)
            @battle.pbDisplay(_INTL("{1} is in a state of total focus!", pbThis)) if showFailMsg
            return false
        else # Block self-inflicted drops
            eachActiveAbility do |ability|
                return false if BattleHandlers.triggerStatLossImmunitySelfAbility(ability, self, stat, @battle, showFailMsg)
            end
        end
        # Check the stat step
        if statStepAtMin?(stat)
            if showFailMsg
                @battle.pbDisplay(_INTL("{1}'s {2} won't go any lower!", pbThis, GameData::Stat.get(stat).name))
            end
            return false
        end
        return true
    end

    # Fails silently
    def tryLowerStat(stat, user, move: nil, increment: 1, showFailMsg: false, showAnim: true, ability: nil, cause: nil, item: nil, ignoreContrary: false, ignoreStubborn: false)
        return false if increment <= 0
        lowered = false
        if pbCanLowerStatStep?(stat, user, move, showFailMsg, ignoreContrary)
            @battle.pbShowAbilitySplash(user, ability) if ability
            if item
                cause = GameData::Item.get(item).name
                @battle.pbCommonAnimation("UseItem", user)
                lowered = true if pbLowerStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: ignoreContrary, ignoreStubborn: ignoreStubborn)
            elsif cause
                lowered = true if pbLowerStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: ignoreContrary, ignoreStubborn: ignoreStubborn)
            elsif pbLowerStatStep(stat, increment, user, showAnim, ignoreContrary, false, ignoreStubborn)
                lowered = true
            end
        end
        @battle.pbHideAbilitySplash(user) if ability
        return lowered
    end

    def pbLowerStatStepBasic(stat, increment)
        increment *= 2 if hasActiveAbility?(:SIMPLE) && !@battle.moldBreaker
        # Change the stat step
        increment = [increment, STAT_STEP_BOUND + @steps[stat]].min
        if increment.positive?
            stat_name = GameData::Stat.get(stat).name
            new = @steps[stat] - increment
            PBDebug.log("[Stat change] #{pbThis}'s #{stat_name}: #{@steps[stat]} -> #{new} (-#{increment})")
            @steps[stat] -= increment
        end
        return increment
    end

    def pbLowerStatStep(stat, increment, user = nil, showAnim = true, ignoreContrary = false, ignoreMirrorArmor = false, ignoreStubborn = false)
        # Mirror Armor, only if not self inflicted
        if !ignoreMirrorArmor && hasActiveAbility?(:MIRRORARMOR) && (!user || user.index != @index) &&
           !@battle.moldBreaker && pbCanLowerStatStep?(stat)
            battle.pbShowAbilitySplash(self, :MIRRORARMOR)
            @battle.pbDisplay(_INTL("{1}'s Mirror Armor activated!", pbThis))
            unless user
                battle.pbHideAbilitySplash(self)
                return false
            end
            if user.pbCanLowerStatStep?(stat, nil, nil, true)
                user.pbLowerStatStepByAbility(stat, increment, user)
            end
            battle.pbHideAbilitySplash(self)
            return false
        end
        # Contrary
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:CONTRARY)
            return pbRaiseStatStep(stat, increment, user, showAnim, true)
        end
        # INVERSION
        if hasActiveAbility?(:INVERSION) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:INVERSION)
            increment = (increment / 2.0).ceil
            return pbRaiseStatStep(stat, increment, user, showAnim, true)
        end
        # Total Focus
        return false if effectActive?(:EmpoweredFlowState)
        # Stubborn
        if hasActiveAbility?(:STUBBORN) && !ignoreStubborn && !@battle.moldBreaker && increment > 1
            showMyAbilitySplash(:STUBBORN)
            @battle.pbDisplay(_INTL("{1} resists the large stat drop!", pbThis))
            hideMyAbilitySplash
            increment = 1
        end
        return lowerStatStepEX(stat, increment, user: user, showAnim: showAnim)
    end

    def lowerStatStepEX(stat, increment, user: nil, showMessages: true, showAnim: true)
        # Perform the stat step change
        increment = pbLowerStatStepBasic(stat, increment)
        return false if increment <= 0
        # Stat down animation and message
        trauma = user&.hasActiveAbility?(:TRAUMATIZING) && opposes?(user)
        @battle.pbShowAbilitySplash(user, :TRAUMATIZING) if trauma && showMessages
        @battle.pbCommonAnimation("StatDown", self) if showAnim
        increment /= 2.0 if boss? && AVATAR_DILUTED_STAT_STEPS
        
        showStatChangeMessage(stat, increment, lowering: true) if showMessages
        
        # Traumatizing
        if trauma
            @battle.pbDisplay(_INTL("It'll last the whole battle!")) if showMessages

            # Initialize entire hash if needed
            pbOwnSide.applyEffect(:Traumatized, {}) unless pbOwnSide.effectActive?(:Traumatized)

            # Initialize individual pokemon array if needed
            unless pbOwnSide.effects[:Traumatized].key?(@pokemonIndex)
                newStatHash = {}
                pbOwnSide.effects[:Traumatized][@pokemonIndex] = newStatHash
                GameData::Stat.each_battle do |statData|
                    newStatHash[statData.id] = 0
                end
            end

            # Increment relevant array element
            existingValue = pbOwnSide.effects[:Traumatized][@pokemonIndex][stat]
            newValue = [STAT_STEP_BOUND,existingValue+increment].min
            pbOwnSide.effects[:Traumatized][@pokemonIndex][stat] = newValue

            @battle.pbHideAbilitySplash(user) if showMessages
        end

        triggersOnStatLoss(stat, increment, user: user)

        return increment
    end

    def pbLowerStatStepByCause(stat, increment, user, cause, showAnim: true, showMessages: true, ignoreContrary: false, ignoreMirrorArmor: false, ignoreStubborn: false)
        # Mirror Armor
        if !ignoreMirrorArmor && hasActiveAbility?(:MIRRORARMOR) && (!user || user.index != @index) &&
                !@battle.moldBreaker && pbCanLowerStatStep?(stat)
            battle.pbShowAbilitySplash(self, :MIRRORARMOR)
            @battle.pbDisplay(_INTL("{1}'s Mirror Armor activated!", pbThis))
            unless user
                battle.pbHideAbilitySplash(self)
                return false
            end
            if user.pbCanLowerStatStep?(stat, nil, nil, true)
                user.pbLowerStatStepByAbility(stat, increment, user)
            end
            battle.pbHideAbilitySplash(self)
            return false
        end
        # Contrary
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:CONTRARY)
            return pbRaiseStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: true)
        end
        # INVERSION
        if hasActiveAbility?(:INVERSION) && !ignoreContrary && !@battle.moldBreaker
            aiLearnsAbility(:INVERSION)
            increment = (increment / 2.0).ceil
            return pbRaiseStatStepByCause(stat, increment, user, cause, showAnim: showAnim, ignoreContrary: true)
        end
        # Total Focus
        return false if effectActive?(:EmpoweredFlowState)
        # Stubborn
        if hasActiveAbility?(:STUBBORN) && !@battle.moldBreaker && increment > 1
            showMyAbilitySplash(:STUBBORN)
            @battle.pbDisplay(_INTL("{1} resists the large stat drop!", pbThis))
            hideMyAbilitySplash
            increment = 1
        end
        # Perform the stat step change
        increment = pbLowerStatStepBasic(stat, increment)
        return false if increment <= 0
        # Stat down animation and message
        @battle.pbCommonAnimation("StatDown", self) if showAnim
        increment /= 2.0 if boss? && AVATAR_DILUTED_STAT_STEPS
        if user.index == @index
            if increment == 1
                lowerMessage = _INTL("{1}'s {2} lowered its {3}!", pbThis, cause, GameData::Stat.get(stat).name)
            else
                lowerMessage = _INTL("{1}'s {2} lowered its {3} by {4} steps!", pbThis, cause, GameData::Stat.get(stat).name, increment)
            end
        else
            if increment == 1
                lowerMessage = _INTL("{1}'s {2} lowered {3}'s {4}!", pbThis, cause, pbThis(true), GameData::Stat.get(stat).name)
            else
                lowerMessage = _INTL("{1}'s {2} lowered {3}'s {4} by {5} steps!", pbThis, cause, pbThis(true), GameData::Stat.get(stat).name, increment)
            end
        end
        @battle.pbDisplay(lowerMessage)

        triggersOnStatLoss(stat, increment, user: user)

        return true
    end

    def pbLowerStatStepByAbility(stat, increment, user, ability: nil)
        return false if fainted?
        return false if statStepAtMin?(stat)
        ret = false
        @battle.pbShowAbilitySplash(user, ability) if ability
        ret = pbLowerStatStep(stat, increment, user) if pbCanLowerStatStep?(stat, user, nil, true)
        @battle.pbHideAbilitySplash(user) if ability
        return ret
    end

    def blockAteAbilities(user,ability,showMessages = true)
        return true if fainted?
        # NOTE: Substitute intentially blocks Intimidate even if self has Contrary or INVERSION
        if substituted?
            @battle.pbDisplay(_INTL("{1} is protected by its substitute!", pbThis)) if showMessages
            return true
        end
        if hasActiveAbility?(:INNERFOCUS)
            if showMessages
                showMyAbilitySplash(:INNERFOCUS, true)
                @battle.pbDisplay(_INTL("{1}'s {2} prevented {3}'s {4} from working!",
                        pbThis, getAbilityName(:INNERFOCUS), user.pbThis(true), getAbilityName(ability)))
                hideMyAbilitySplash
            end
            return true
        elsif @battle.pbCheckSameSideAbility(:EFFLORESCENT, @index)
            if showMessages
                aromaHolder = @battle.pbCheckSameSideAbility(:EFFLORESCENT, @index)
                @battle.pbShowAbilitySplash(aromaHolder, :EFFLORESCENT, true)
                @battle.pbDisplay(_INTL("{1}'s {2} prevented {3}'s {4} from working!",
                    aromaHolder.pbThis, getAbilityName(:EFFLORESCENT), user.pbThis(true), getAbilityName(ability)))
                @battle.pbHideAbilitySplash(aromaHolder)
            end
            return true
        end
        return false
    end

    def pbMinimizeStatStep(stat, user = nil, move = nil, ignoreContrary = false, ability: nil)
        if hasActiveAbility?(:CONTRARY) && !ignoreContrary
            aiLearnsAbility(:CONTRARY)
            pbMaximizeStatStep(stat, user, move, true, ability: ability)
        elsif hasActiveAbility?(:INVERSION) && !ignoreContrary
            aiLearnsAbility(:INVERSION)
            increment = ((STAT_STEP_BOUND + @steps[stat]) / 2.0).ceil
            tryRaiseStat(stat, user, move: move, increment: increment, ability: ability)
        elsif pbCanLowerStatStep?(stat, user, move, true, ignoreContrary)
            @battle.pbShowAbilitySplash(user, ability) if ability
            increment = @steps[stat] + STAT_STEP_BOUND
            @steps[stat] = -STAT_STEP_BOUND
            @battle.pbCommonAnimation("StatDown", self)
            statName = GameData::Stat.get(stat).name
            @battle.pbDisplay(_INTL("{1} minimized its {2}!", pbThis, statName))
            @battle.pbHideAbilitySplash(user) if ability

            triggersOnStatLoss(stat, increment, user: user, move: move)
        end
    end

    def triggersOnStatLoss(stat, increment, user: nil, move: nil)
        playStatStepsTutorial unless $PokemonGlobal.statStepsTutorialized

        applyEffect(:StatsDropped)

        # Trigger abilities upon stat loss
        eachActiveAbility do |ability|
            BattleHandlers.triggerAbilityOnStatLoss(ability, self, stat, user)
        end

        # Trigger items upon stat loss
        eachActiveItem do |item|
            BattleHandlers.triggerItemOnStatLoss(item, self, user, move, [], @battle)
        end
    end

    #=============================================================================
    # Multiple stat steps
    #=============================================================================

    def pbCanRaiseAnyOfStats?(statArray, user, move: nil, showFailMsg: false)
        for i in 0...statArray.length / 2
            return true if pbCanRaiseStatStep?(statArray[i * 2], user, move, showFailMsg)
        end
        return false
    end

    def pbCanLowerAnyOfStats?(statArray, user, move: nil, showFailMsg: false)
        for i in 0...statArray.length / 2
            canLowerThisStat = pbCanLowerStatStep?(statArray[i * 2], user, move, showFailMsg)
            return true if canLowerThisStat
            showFailMsg = false
        end
        return false
    end

    # Pass in array of form
    # [statToRaise, stepsToRaise, statToRaise2, stepsToRaise2, ...]
    def pbRaiseMultipleStatSteps(statArray, user, move: nil, showFailMsg: false, showAnim: true, ability: nil, item: nil, ignoreContrary: false, statStepCaps: {})
        return unless pbCanRaiseAnyOfStats?(statArray, user, move: move, showFailMsg: showFailMsg)
        @battle.pbShowAbilitySplash(user, ability) if ability

        cause = nil
        if item
            @battle.pbCommonAnimation("UseItem", user)
            cause = GameData::Item.get(item).name
        end

        # Contrary
        unless ignoreContrary || @battle.moldBreaker
            # Contrary
            if hasActiveAbility?(:CONTRARY)
                aiLearnsAbility(:CONTRARY)
                return pbLowerMultipleStatSteps(statArray, user, move: move, showFailMsg: showFailMsg, showAnim: showAnim, ability: ability, item: item, ignoreContrary: true)
            end
            # INVERSION
            if hasActiveAbility?(:INVERSION)
                aiLearnsAbility(:INVERSION)
                statArray = statArray.map { |statArrayElement|
                    if statArrayElement.is_a?(Integer)
                        next (statArrayElement / 2.0).ceil
                    else
                        next statArrayElement
                    end
                }
                return pbLowerMultipleStatSteps(statArray, user, move: move, showFailMsg: showFailMsg, showAnim: showAnim, ability: ability, item: item, ignoreContrary: true)
            end
        end

        raisedAnySteps = false
        endResult = {}
        for i in 0...statArray.length / 2
            stat = statArray[i * 2]
            increment = statArray[i * 2 + 1]
            if statStepCaps && statStepCaps[stat]
                increment = [increment,statStepCaps[stat]-@steps[stat]].min
            end
            next unless pbCanRaiseStatStep?(stat, user, move, false, false)
            increment = raiseStatStepEX(stat, increment, user: user, showMessages: false, showAnim: false)
            next if increment == false
            if endResult.key?(increment)
                endResult[increment].push(stat)
            else
                endResult[increment] = [stat]
            end
            raisedAnySteps = true
        end

        @battle.pbCommonAnimation("StatUp", self) if showAnim && raisedAnySteps
        endResult.each do |increment, statIDList|
            showStatChangeMessage(statIDList, increment, lowering: false)
        end

        @battle.pbHideAbilitySplash(user) if ability
        return raisedAnySteps
    end

    # Pass in array of form
    # [statToRaise, stepsToRaise, statToRaise2, stepsToRaise2, ...]
    def pbLowerMultipleStatSteps(statArray, user = nil, move: nil, showFailMsg: false, showAnim: true, ability: nil, item: nil, ignoreContrary: false, ignoreMirrorArmor: false)
        return unless pbCanLowerAnyOfStats?(statArray, user, move: move, showFailMsg: showFailMsg)
        @battle.pbShowAbilitySplash(user, ability) if ability

        cause = nil
        if item
            @battle.pbCommonAnimation("UseItem", user)
            cause = GameData::Item.get(item).name
        end

        unless @battle.moldBreaker
            # Mirror Armor, only if not self inflicted
            if hasActiveAbility?(:MIRRORARMOR) && !ignoreMirrorArmor && (!user || user.index != @index)
                battle.pbShowAbilitySplash(self, :MIRRORARMOR)
                @battle.pbDisplay(_INTL("{1}'s Mirror Armor activated!", pbThis))
                unless user
                    battle.pbHideAbilitySplash(self)
                    return false    
                end
                if user.pbCanLowerAnyOfStats?(statArray, nil, move: move, showFailMsg: showFailMsg)
                    user.pbLowerMultipleStatSteps(statArray, user, showFailMsg: showFailMsg, showAnim: showAnim, ignoreContrary: ignoreContrary, ignoreMirrorArmor: true)
                end
                battle.pbHideAbilitySplash(self)
                return false
            end
            unless ignoreContrary
                # Contrary
                if hasActiveAbility?(:CONTRARY)
                    aiLearnsAbility(:CONTRARY)
                    return pbRaiseMultipleStatSteps(statArray, user, move: move, showFailMsg: showFailMsg, showAnim: showAnim, ability: ability, item: item, ignoreContrary: true)
                end
                # INVERSION
                if hasActiveAbility?(:INVERSION)
                    aiLearnsAbility(:INVERSION)
                    statArray = statArray.map { |statArrayElement|
                        if statArrayElement.is_a?(Integer)
                            next (statArrayElement / 2.0).ceil
                        else
                            next statArrayElement
                        end
                    }
                    return pbRaiseMultipleStatSteps(statArray, user, move: move, showFailMsg: showFailMsg, showAnim: showAnim, ability: ability, item: item, ignoreContrary: true)
                end
            end
        end
        
         # Check if showing stubborn is needed
        anyLargeDrops = false
        for i in 0...statArray.length / 2
            stat = statArray[i * 2]
            increment = statArray[i * 2 + 1]
            anyLargeDrops = true if increment > 1
        end

        # Stubborn
        if hasActiveAbility?(:STUBBORN) && !@battle.moldBreaker && anyLargeDrops
            showMyAbilitySplash(:STUBBORN)
            @battle.pbDisplay(_INTL("{1} resists the large stat drop!", pbThis))
            hideMyAbilitySplash

            statArray = statArray.map { |statArrayElement|
                if statArrayElement.is_a?(Integer)
                    next [statArrayElement,1].min
                else
                    next statArrayElement
                end
            }
        end

        loweredAnySteps = false
        endResult = {}
        for i in 0...statArray.length / 2
            stat = statArray[i * 2]
            increment = statArray[i * 2 + 1]
            next unless pbCanLowerStatStep?(stat, user, move, false, false)
            increment = lowerStatStepEX(stat, increment, user: user, showMessages: false, showAnim: false)
            next if increment <= 0
            if endResult.key?(increment)
                endResult[increment].push(stat)
            else
                endResult[increment] = [stat]
            end
            loweredAnySteps = true
        end

        @battle.pbCommonAnimation("StatDown", self) if showAnim && loweredAnySteps
        endResult.each do |increment, statIDList|
            showStatChangeMessage(statIDList, increment, lowering: true)
        end

        @battle.pbHideAbilitySplash(user) if ability
        return loweredAnySteps
    end

    #=============================================================================
    # Helper methods
    #=============================================================================
    def showStatChangeMessage(stat, increment, lowering: false)
        stat = stat[0] if stat.is_a?(Array) && stat.length == 1
        if stat.is_a?(Array)
            messageFormat = "{1}'s "
            statNameArgs = []
            stat.each_with_index do |individualStatID, index|
                messageFormatNumber = index + 2
                messageFormatNumber += 1 if increment > 1
                if index == stat.length - 1
                    if stat.length > 2
                        messageFormat += ", and {#{messageFormatNumber}}"
                    else
                        messageFormat += " and {#{messageFormatNumber}}"
                    end
                elsif index == 0
                    messageFormat += "{#{messageFormatNumber}}"
                else
                    messageFormat += ", {#{messageFormatNumber}}"
                end
                statNameArgs.push(GameData::Stat.get(individualStatID).name)
            end
            if lowering
                if increment == 1
                    messageFormat += " fell!"
                    lowerMessage = _INTL(messageFormat, pbThis, *statNameArgs)
                else
                    messageFormat += " fell by {2} steps!"
                    lowerMessage = _INTL(messageFormat, pbThis, increment, *statNameArgs)
                end
            else
                if increment == 1
                    messageFormat += " rose!"
                    lowerMessage = _INTL(messageFormat, pbThis, *statNameArgs)
                else
                    messageFormat += " rose by {2} steps!"
                    lowerMessage = _INTL(messageFormat, pbThis, increment, *statNameArgs)
                end
            end
        else
            if lowering
                if increment == 1
                    lowerMessage = _INTL("{1}'s {2} fell!", pbThis, GameData::Stat.get(stat).name)
                else
                    lowerMessage = _INTL("{1}'s {2} fell by {3} steps!", pbThis, GameData::Stat.get(stat).name, increment)
                end
            else
                if increment == 1
                    lowerMessage = _INTL("{1}'s {2} rose!", pbThis, GameData::Stat.get(stat).name)
                else
                    lowerMessage = _INTL("{1}'s {2} rose by {3} steps!", pbThis, GameData::Stat.get(stat).name, increment)
                end
            end
        end
        @battle.pbDisplay(lowerMessage)
    end

    #=============================================================================
    # Reset stat steps
    #=============================================================================
    def hasAlteredStatSteps?
        GameData::Stat.each_battle { |s| return true if @steps[s.id] != 0 }
        return false
    end

    def hasRaisedStatSteps?
        GameData::Stat.each_battle { |s| return true if (@steps[s.id]).positive? }
        return false
    end

    def hasRaisedDefenseSteps?
        return true if (@steps[:DEFENSE]).positive?
        return true if (@steps[:SPECIAL_DEFENSE]).positive?
        return true if (@steps[:EVASION]).positive?
        return false
    end

    def hasLoweredStatSteps?
        GameData::Stat.each_battle { |s| return true if (@steps[s.id]).negative? }
        return false
    end

    def pbResetStatSteps
        GameData::Stat.each_battle { |s| @steps[s.id] = 0 }
    end
    
    def pbResetLoweredStatSteps(showMessage = false)
        anyReset = false
        GameData::Stat.each_battle { |s|
            next unless @steps[s.id] < 0
            @steps[s.id] = 0
            anyReset = true
        }
        @battle.pbDisplay(_INTL("{1}'s negative stat changes were eliminated!", pbThis)) if showMessage && anyReset
    end
    
    def pbResetRaisedStatSteps(showMessage = false)
        anyReset = false
        GameData::Stat.each_battle { |s|
            next unless @steps[s.id] > 0
            @steps[s.id] = 0
            anyReset = true
        }
        @battle.pbDisplay(_INTL("{1}'s positive stat changes were eliminated!", pbThis)) if showMessage && anyReset
    end
end
