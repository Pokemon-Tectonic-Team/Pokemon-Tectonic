class PokeBattle_Battle
    def pbRandom(x); return rand(x); end

    #=============================================================================
    # Information about the type and size of the battle
    #=============================================================================
    def wildBattle?;    return @opponent.nil?;  end
    def trainerBattle?; return !@opponent.nil?; end

    # Sets the number of battler slots on each side of the field independently.
    # For "1v2" names, the first number is for the player's side and the second
    # number is for the opposing side.
    def setBattleMode(mode)
        @sideSizes =
            case mode
            when "triple", "3v3" then [3, 3]
            when "3v2"           then [3, 2]
            when "3v1"           then [3, 1]
            when "2v3"           then [2, 3]
            when "double", "2v2" then [2, 2]
            when "2v1"           then [2, 1]
            when "1v3"           then [1, 3]
            when "1v2"           then [1, 2]
            else                      [1, 1] # Single, 1v1 (default)
            end
    end

    def singleBattle?
        return pbSideSize(0) == 1 && pbSideSize(1) == 1
    end

    def pbSideSize(index)
        return @sideSizes[index % 2]
    end

    def maxBattlerIndex
        return (pbSideSize(0) > pbSideSize(1)) ? (pbSideSize(0) - 1) * 2 : pbSideSize(1) * 2 - 1
    end

    def bossBattle?
        return bossBattle
    end

    def roomActive?
        @field.eachEffect(true) do |effect, _value, effectData|
            return true if effectData.is_room?
        end
        return false
    end

    def curseActive?(curseID)
        return @curses.include?(curseID)
    end

    def stolenItemTurnsToDust?(item = nil)
        return true if curseActive?(:CURSE_SUPER_ITEMS)
        return true if curseActive?(:CURSE_RECYCLING)
        return true if item && GameData::Item.get(item).super
        return false
    end

    def pbCheckNeutralizingGas(battler = nil)
        # Battler = the battler to switch out.
        # Should be specified when called from pbAttackPhaseSwitch
        # Should be nil when called from pbEndOfRoundPhase
        return unless @field.effectActive?(:NeutralizingGas)
        return if battler && !battler.hasActiveNeutralizingGas?
        gasActive = false
        eachBattler do |b|
            next if !b || b.fainted?
            next if battler && b.index == battler.index
            # if specified, the battler will switch out, so don't consider it.
            # neutralizing gas can be blocked with gastro acid, ending the effect.
            if b.hasActiveNeutralizingGas?
                gasActive = true
                break
            end
        end
        unless gasActive
            @field.disableEffect(:NeutralizingGas)
            pbPriority(true).each do |b|
                next if battler && b.index == battler.index
                b.pbEffectsOnSwitchIn
            end
        end
    end

    def abilitiesNeutralized?
        return @field.effectActive?(:NeutralizingGas)
    end

    def pbCheckAlliedAbility(abil, idxBattler = 0, nearOnly = false)
        eachSameSideBattler(idxBattler) do |b|
            next if nearOnly && !b.near?(idxBattler)
            return b if b.hasActiveAbility?(abil)
        end
        return nil
    end

    def useEmpoweredStatusMoves
        # Have bosses use empowered moves if appropriate
        eachBattler do |b|
            next unless b.boss?
            next unless b.hasEmpoweredStatusMove?
            avatarData = GameData::Avatar.get(b.species.to_sym)
            next if b.avatarPhase == avatarData.num_phases
            next if b.hp > b.avatarPhaseLowerHealthBound
            usedEmpoweredMove = false

            # Begin the phase change
            b.bossAI.startPhaseChange(b,self)
            showMessages = $Options.avatar_mechanics_messages == 0

            # Reset debuffs
            if PRIMEVAL_MOVES_RESET_DEBUFFS
                pbAnimation(:REFRESH,b,b)
                pbDisplaySlower(_INTL("{1} wiped the slate clean.", b.pbThis)) if showMessages
                b.pbCureStatus
                b.pbCureStatus # Duplicated intentionally
                b.pbResetLoweredStatSteps(true)
                b.resetAbilities
                b.eachEffect(true) do |effect, _value, data|
                    next unless data.avatars_purge || data.is_mental?
                    b.disableEffect(effect)
                end
            end

            b.lastRoundMoved = 0
            b.pbCancelMoves # Cancels multi-turn moves

            # Use each empowered status move
            b.eachEmpoweredStatusMove do |move, index|               
                if showMessages
                  if usedEmpoweredMove
                    pbDisplaySlower(_INTL("What?! Even more energy rises up from inside {1}!!", b.pbThis(true)))
                  else
                    pbDisplaySlower(_INTL("A great energy rises up from inside {1}!", b.pbThis(true)))
                  end
                end
                
                b.pbUseMove([:UseMove, index, move, -1, 0])
                usedEmpoweredMove = true
            end
            
            next unless usedEmpoweredMove

            # Swap to post-empowerment moveset
            b.avatarPhase += 1
            movesetToAssign = avatarData.arrayOfMoveSets[b.avatarPhase - 1]
            echoln("ERROR: Unable to change moveset.") if movesetToAssign.nil?
            b.assignMoveset(movesetToAssign)
            b.empoweredTimer = 0
            @scene.pbRefresh

            # Reset fear
            pbParty(0).each_with_index do |pkmn, i|
                next unless pkmn
                pkmn.removeFear(self) if pkmn.afraid?
            end

            # Allow the player to swap to any pokemon that are no longer afraid
            pbEORSwitch
        end
    end

    # moveIDOrIndex is either the index of the move on the user's move list (Integer)
    # or it's the ID of the move to be used (Symbol)
    def forceUseMove(forcedMoveUser, moveIDOrIndex, target = -1, specialUsage = true, usageMessage = nil, moveUsageEffect: nil, ability: nil, aiCheck: false)
        if moveIDOrIndex.is_a?(Symbol)
            fakeMove = PokeBattle_Move.from_pokemon_move(self, Pokemon::Move.new(moveIDOrIndex))
        else
            fakeMove = forcedMoveUser.moves[moveIDOrIndex]
        end
        
        if aiCheck
            moveScore = 0
            if target >= 0
                moveScore = @battleAI.pbGetMoveScore(fakeMove, forcedMoveUser, @battlers[target], forcedMoveUser.ownersPolicies)
            else
                newChoice,killInfo = @battleAI.pbEvaluateMoveTrainer(forcedMoveUser, fakeMove, random: true)
                if newChoice
                    return newChoice[0]
                else
                    return 0 # No valid targets
                end
            end
        end

        oldLastRoundMoved = forcedMoveUser.lastRoundMoved
        if specialUsage
            @specialUsage = true
            # NOTE: Petal Dance being used shouldn't lock the
            #       battler into using that move, and shouldn't contribute to its
            #       turn counter if it's already locked into Petal Dance.
            oldCurrentMove = forcedMoveUser.currentMove
            oldOutrageTurns = forcedMoveUser.effects[:Outrage]
            forcedMoveUser.effects[:Outrage] += 1 if forcedMoveUser.effectActive?(:Outrage)
        end

        # Show explanatory information
        pbShowAbilitySplash(forcedMoveUser, ability, true) if ability
        pbDisplay(usageMessage) unless usageMessage.nil?
        pbHideAbilitySplash(forcedMoveUser) if ability

        moveID = moveIDOrIndex.is_a?(Symbol) ? moveIDOrIndex : nil
        moveIndex = moveIDOrIndex.is_a?(Integer) ? moveIDOrIndex : -1

        cantForceMove = false
        if forcedMoveUser.asleep?
            forcedMoveUser.pbContinueStatus(:SLEEP)
            unless fakeMove.usableWhenAsleep? # Snore/Sleep Talk
                forcedMoveUser.onMoveFailed(fakeMove,false)
                cantForceMove = true
            end
        end

        unless cantForceMove
            PBDebug.logonerr do
                forcedMoveUser.effects[moveUsageEffect] = true unless moveUsageEffect.nil?
                forcedMoveUser.pbUseMoveSimple(moveID, target, moveIndex, specialUsage)
                forcedMoveUser.effects[moveUsageEffect] = false unless moveUsageEffect.nil?
            end
        end

        forcedMoveUser.lastRoundMoved = oldLastRoundMoved
        if specialUsage
            forcedMoveUser.effects[:Outrage] = oldOutrageTurns
            forcedMoveUser.currentMove = oldCurrentMove
        end
        @specialUsage = false
        pbJudge
        return if @decision > 0
    end

    def getBattleMoveInstanceFromID(move_id)
        return PokeBattle_Move.from_pokemon_move(self, Pokemon::Move.new(move_id))
    end

    def allEffectHolders(&block)
        yield @field
        @sides.each(&block)
        @positions.each_with_index do |position, _index|
            yield position unless position.nil?
        end
        eachBattler do |b|
            yield b unless b.nil?
        end
    end

    def pbSetSeen(battler)
        return if !battler || !@internalBattle
        pbPlayer.pokedex.register(battler.displaySpecies, battler.displayGender, battler.displayForm)
    end

    def nextPickupUse
        @nextPickupUse += 1
        return @nextPickupUse
    end

    def firstTurnThisRound?
        return @commandPhasesThisRound.zero?
    end

    def aiLearnsAbility(battler, ability)
        return unless battler.pbOwnedByPlayer?
        return if @knownAbilities[battler.pokemon.personalID].include?(ability)
        @knownAbilities[battler.pokemon.personalID].push(ability)
        echoln("[AI LEARNING] The AI is now aware of #{battler.pbThis(true)}'s ability #{ability}")
    end

    # If given an array, returns true if the AI knows of ANY of the listed abilities
    def aiKnowsAbility?(pokemon,checkAbility)
        knownAbilitiesOfMon = @knownAbilities[pokemon.personalID]
        return false if knownAbilitiesOfMon.nil?
        if checkAbility.is_a?(Array)
            checkAbility.each do |specificAbility|
                return true if knownAbilitiesOfMon.include?(specificAbility)
            end
            return false
        else
            return knownAbilitiesOfMon.include?(checkAbility)
        end
    end

    def aiLearnsItem(battler, item)
        return unless battler.pbOwnedByPlayer?
        return if @knownItems[battler.pokemon.personalID].include?(item)
        @knownItems[battler.pokemon.personalID].push(item)
        echoln("[AI LEARNING] The AI is now aware of #{battler.pbThis(true)}'s item #{item}")
    end

    # If given an array, returns true if the AI knows of ANY of the listed abilities
    def aiKnowsItem?(pokemon,checkItem)
        knownItemsOfMon = @knownItems[pokemon.personalID]
        return false if knownItemsOfMon.nil?
        if checkItem.is_a?(Array)
            checkItem.each do |specificItem|
                return true if knownItemsOfMon.include?(specificItem)
            end
            return false
        else
            return knownItemsOfMon.include?(checkItem)
        end
    end

    def aiSeesMove(battler, moveID)
        return unless battler.pbOwnedByPlayer?
        return if battler.boss?
        moveID = moveID.id if moveID.is_a?(PokeBattle_Move)
        array = @knownMoves[battler.pokemon.personalID]
        array = [] if array.nil?
        array.push(moveID) unless array.include?(moveID)
    end

    def aiKnownMoves(pokemon)
        initializeKnownMoves(pokemon) unless @knownMoves.include?(pokemon.personalID)
        return @knownMoves[pokemon.personalID]
    end

    def actionTargets?(user,action,battler)
        return false if action[0] != :UseMove
        target_data = action[2].pbTarget(user)
        if target_data.num_targets > 1
            return pbMoveCanTarget?(user.index, battler.index, target_data)
        elsif target_data.num_targets == 0
            return false
        else
            return action[3] == battler.index
        end
    end

    def predictable?(predictor,idxBattler)
        return false unless predictor.ownersPolicies.include?(:PREDICTS_PLAYER)
        return false unless @battlers[idxBattler].pbOwnedByPlayer?
        return false unless @predictedActions[idxBattler]
        return true
    end

    def aiPredictsSwitch?(predictor,idxBattler,ignoreSwitchMoves = false)
        return false unless predictable?(predictor,idxBattler)
        predictedAction = @predictedActions[idxBattler]
        return true if predictedAction[0] == :SwitchOut
        return true if !ignoreSwitchMoves && predictedAction[0] == :UseMove && predictedAction[2].switchOutMove?
        return false
    end

    def aiPredictsAttack?(predictor,idxBattler,againstPredictor=false,categoryOnly = -1)
        return true unless predictable?(predictor,idxBattler)
        predictedAction = @predictedActions[idxBattler]
        return false unless predictedAction[0] == :UseMove
        return false unless predictedAction[2].damagingMove?(true)
        return false if againstPredictor && !actionTargets?(@battlers[idxBattler],predictedAction,predictor)
        return false if categoryOnly != -1 && predictedAction[2].category_override != categoryOnly
        return true
    end

    def aiPredictsStatus?(predictor,idxBattler,againstPredictor=false)
        return false unless predictable?(predictor,idxBattler)
        predictedAction = @predictedActions[idxBattler]
        return false unless predictedAction[0] == :UseMove
        return false if predictedAction[2].damagingMove?(true)
        return false if againstPredictor && !actionTargets?(@battlers[idxBattler],predictedAction,predictor)
        return true
    end

    def typeEffectivenessMult(typeMod)
        mult = typeMod / Effectiveness::NORMAL_EFFECTIVE.to_f
        if @field.effectActive?(:PolarizedRoom)
            if Effectiveness.super_effective?(typeMod)
                mult *= 1.25
            elsif Effectiveness.not_very_effective?(typeMod)
                mult *= 0.75
            end
        end
        return mult
    end
    
    def gravityIntensified?
        return true if @field.effectActive?(:Gravity)
        return true if @field.effectActive?(:WarpingCore)
        return false
    end
end

def getAbilityName(ability)
    abilityData = GameData::Ability.try_get(ability)
    return "ERROR" if abilityData.nil?
    return abilityData.name
end

def getItemName(item)
    itemData = GameData::Item.try_get(item)
    return "ERROR" if itemData.nil?
    return itemData.name
end

def getMoveName(move)
    moveData = GameData::Move.try_get(move)
    return "ERROR" if moveData.nil?
    return moveData.name
end

def getBattleMoveInstanceFromID(move_id)
    return PokeBattle_Move.from_pokemon_move(nil, Pokemon::Move.new(move_id))
end

# Is it allowed to be called from other moves
def canInvokeMove?(move)
    if move.is_a?(PokeBattle_Move)
        battleMoveInstance = move
    elsif move.is_a?(Pokemon::Move)
        battleMoveInstance = getBattleMoveInstanceFromID(move.id)
    else
        battleMoveInstance = getBattleMoveInstanceFromID(move)
    end
    return false if battleMoveInstance.function == "Invalid"
    return false if battleMoveInstance.callsAnotherMove?
    return false if battleMoveInstance.forceSwitchMove?
    return false if battleMoveInstance.switchOutMove?
    return false if battleMoveInstance.is_a?(PokeBattle_TwoTurnMove)
    return false if battleMoveInstance.is_a?(PokeBattle_HelpingMove)
    return false if battleMoveInstance.is_a?(PokeBattle_ProtectMove)
    return false if GameData::Move.get(battleMoveInstance.id).uninvocable?
    return true
end