class PokeBattle_Battle
    #=============================================================================
    # Attack phase actions
    #=============================================================================
    # Quick Claw, Custap Berry's "X let it move first!" message.
    def pbAttackPhasePriorityChangeMessages
        pbPriority.each do |b|
            if b.effectActive?(:PriorityAbility) && b.abilityActive?
                BattleHandlers.triggerPriorityBracketUseAbility(b.effects[:PriorityAbility], b, self)
            elsif b.effectActive?(:PriorityItem) && b.itemActive?
                BattleHandlers.triggerPriorityBracketUseItem(b.effects[:PriorityItem], b, self)
            end
        end
    end

    def pbAttackPhaseCall
        pbPriority.each do |b|
            next unless @choices[b.index][0] == :Call && !b.fainted?
            b.lastMoveFailed = false # Counts as a successful move for Stomping Tantrum
            pbCall(b.index)
        end
    end

    def pbPursuit(idxSwitcher)
        @switching = true
        pbPriority.each do |b|
            next if b.fainted? || !b.opposes?(idxSwitcher) # Shouldn't hit an ally
            next if b.movedThisRound? || !pbChoseMoveFunctionCode?(b.index, "PursueSwitchingFoe") # Pursuit
            # Check whether Pursuit can be used
            next unless pbMoveCanTarget?(b.index, idxSwitcher, @choices[b.index][2].pbTarget(b))
            next unless pbCanChooseMove?(b.index, @choices[b.index][1], false)
            next if b.asleep?
            next if b.effectActive?(:SkyDrop)
            next if b.hasActiveAbility?(:TRUANT) && !b.effectActive?(:Truant)
            # Use Pursuit
            @choices[b.index][3] = idxSwitcher # Change Pursuit's target
            b.applyEffect(:Pursuit) if b.pbProcessTurn(@choices[b.index], false)
            break if @decision > 0 || @battlers[idxSwitcher].fainted?
        end
        @switching = false
    end

    def pbAttackPhaseSwitch
        pbPriority.each do |b|
            next unless @choices[b.index][0] == :SwitchOut && !b.fainted?
            idxNewPkmn = @choices[b.index][1] # Party index of Pokémon to switch to
            b.lastMoveFailed = false # Counts as a successful move for Stomping Tantrum
            @lastMoveUser = b.index
            # Switching message
            pbMessageOnRecall(b)
            # Pursuit interrupts switching
            pbPursuit(b.index)
            return if @decision > 0
            # Neutralizing Gas
            pbCheckNeutralizingGas(b)
            # Switch Pokémon
            pbRecallAndReplace(b.index, idxNewPkmn)
            b.pbEffectsOnSwitchIn(true)
        end
    end

    def pbAttackPhaseItems
        pbPriority.each do |b|
            next unless @choices[b.index][0] == :UseItem && !b.fainted?
            b.lastMoveFailed = false # Counts as a successful move for Stomping Tantrum
            item = @choices[b.index][1]
            next unless item
            case GameData::Item.get(item).battle_use
            when 1, 2   # Use on Pokémon/Pokémon's move
                pbUseItemOnPokemon(item, @choices[b.index][2], b) if @choices[b.index][2] >= 0
            when 3         # Use on battler
                pbUseItemOnBattler(item, @choices[b.index][2], b)
            when 4         # Use Poké Ball
                pbUsePokeBallInBattle(item, @choices[b.index][2], b)
            when 5        # Use directly
                pbUseItemInBattle(item, @choices[b.index][2], b)
            else
                next
            end
            return if @decision > 0
        end
        pbCalculatePriority
    end

    def pbAttackPhaseCloaking
        pbPriority.each do |b|
            next unless @choices[b.index][0] == :UseMove && !b.fainted?
            next if b.movedThisRound?
            next unless b.hasActiveAbility?(:CLOAKING)
            move = @choices[b.index][2]
            next if move.callsAnotherMove?
            typeToFormHash = {
                :GRASS => 0,
                :GROUND => 1,
                :STEEL => 2,
            }
            newForm = typeToFormHash[move.pbCalcType(b)]
            next unless newForm
            next if b.form == newForm
            pbShowAbilitySplash(b, :CLOAKING)
            b.pbChangeForm(newForm,_INTL("{1} changes its cloak to fit its next move!",b.pbThis))
            pbHideAbilitySplash(b)
        end
    end

    def pbAttackPhaseMoves
        # Show charging messages (Focus Punch)
        pbPriority.each do |b|
            next unless @choices[b.index][0] == :UseMove && !b.fainted?
            next if b.movedThisRound?
            @choices[b.index][2].pbDisplayChargeMessage(b)
        end
        # Main move processing loop
        loop do
            priority = pbPriority
            # Forced to go next
            advance = false
            priority.each do |b|
                next unless b.effectActive?(:MoveNext) && !b.fainted?
                next unless @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
                next if b.movedThisRound?
                advance = b.pbProcessTurn(@choices[b.index])
                break if advance
            end
            return if @decision > 0
            next if advance
            # Regular priority order
            priority.each do |b|
                next if b.effectActive?(:Quash) || b.fainted?
                next unless @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
                next if b.movedThisRound?
                advance = b.pbProcessTurn(@choices[b.index])
                break if advance
            end
            return if @decision > 0
            next if advance
            # Quashed
            quashLevel = 0
            loop do
                quashLevel += 1
                moreQuash = false
                priority.each do |b|
                    moreQuash = true if b.effects[:Quash] > quashLevel
                    next unless b.effects[:Quash] == quashLevel && !b.fainted?
                    next unless @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
                    next if b.movedThisRound?
                    advance = b.pbProcessTurn(@choices[b.index])
                    break
                end
                break if advance || !moreQuash
            end
            return if @decision > 0
            next if advance
            # Check for all done
            priority.each do |b|
                if !b.fainted? && !b.movedThisRound? && (@choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift)
                    advance = true
                end
                break if advance
            end
            next if advance
            # All Pokémon have moved; end the loop
            break
        end
    end

    #=============================================================================
    # Attack phase
    #=============================================================================
    def pbAttackPhase
        @scene.pbBeginAttackPhase
        resetAttackPhaseEffects
        PBDebug.log("")
        # Calculate move order for this round
        pbCalculatePriority(true)
        # Perform actions
        return if attackPhaseNonMoveActions
        speedAffectingTriggers
        pbAttackPhaseMoves
        endOfAttackPhase
    end

    def speedAffectingTriggers
        eachBattler do |b|
            next unless @choices[b.index][0] == :UseMove
            move = b.getMoves[@choices[b.index][1]]

            b.applySpeedTriggers(move)
        end
        pbCalculatePriority
    end

    def resetAttackPhaseEffects
        @battlers.each_with_index do |b, i|
            next unless b
            b.turnCount += 1 unless b.fainted?
            @successStates[i].clear
            if @choices[i][0] != :UseMove && @choices[i][0] != :Shift && @choices[i][0] != :SwitchOut
                b.disableEffect(:DestinyBond)
            end
            b.disableEffect(:Rage) unless pbChoseMoveFunctionCode?(i, "093") # Rage
            b.applyEffect(:ChoseAttack) if b.usingAttackThisTurn?
            b.applyEffect(:ChoseStatus) if b.usingStatusThisTurn?
            b.lastRoundHighestTypeModFromFoe = -1
        end
    end

    # Returns whether or not the battle has ended
    def attackPhaseNonMoveActions
        pbAttackPhasePriorityChangeMessages
        pbAttackPhaseCall
        pbAttackPhaseSwitch
        return true if @decision > 0
        pbAttackPhaseItems
        return true if @decision > 0
        pbAttackPhaseCloaking
        return false
    end

    def pbExtraAttackPhase
        @scene.pbBeginAttackPhase
        resetAttackPhaseEffects
        PBDebug.log("")
        # Calculate move order for this round
        pbCalculatePriority(true)
        # Perform actions
        return if attackPhaseNonMoveActions
        speedAffectingTriggers
        pbPriority.each do |battler|
            next if battler.fainted?
            next unless @choices[battler.index][0] == :UseMove
            next if @commandPhasesThisRound - 1 > battler.extraMovesPerTurn
            battler.pbProcessTurn(@choices[battler.index])
        end
    end

    def endOfAttackPhase
        # Temporal Distortion
        eachBattler do |b|
            next unless b.hasActiveAbility?(:TEMPORALDISTORTION) && (b.turnCount % 3 == 0)
            pbShowAbilitySplash(b,:TEMPORALDISTORTION)
            pbDisplay(_INTL("{1} takes control of time itself!", b.pbThis))
            b.applyEffect(:TemporalDistortion)
            pbHideAbilitySplash(b)
        end  
    end
end
