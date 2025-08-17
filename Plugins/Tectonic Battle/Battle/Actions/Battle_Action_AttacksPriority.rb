class PokeBattle_Battle
    #=============================================================================
    # Choosing a move/target
    #=============================================================================
    def pbCanChooseMove?(battler, idxMove, showMessages, sleepTalk = false)
        battler = @battlers[battler] if battler.is_a?(Integer)
        move = battler.getMoves[idxMove]
        return false unless move
        return true if move.empoweredMove? && battler.boss?
        if move.pp == 0 && move.total_pp > 0 && !sleepTalk
            pbDisplayPaused(_INTL("There's no PP left for this move!")) if showMessages
            echoln("The move #{move.name} has no PP, so it cannot be chosen.")
            return false
        end
        if battler.effectActive?(:Encore)
            idxEncoredMove = battler.pbEncoredMoveIndex
            if idxEncoredMove >= 0 && idxMove != idxEncoredMove
                echoln("The move #{move.name} is not the encored move, so it cannot be chosen.")
                return false
            end
        end
        return battler.pbCanChooseMove?(move, true, showMessages, sleepTalk)
    end

    def pbCanChooseAnyMove?(idxBattler, sleepTalk = false)
        battler = @battlers[idxBattler]
        battler.eachMoveWithIndex do |m, i|
            return true if m.empoweredMove? && battler.boss?
            next if m.pp == 0 && m.total_pp > 0 && !sleepTalk
            if battler.effectActive?(:Encore)
                idxEncoredMove = battler.pbEncoredMoveIndex
                next if idxEncoredMove >= 0 && i != idxEncoredMove
            end
            next unless battler.pbCanChooseMove?(m, true, false, sleepTalk)
            return true
        end
        return false
    end

    # Called when the Pokémon is Encored, or if it can't use any of its moves.
    # Makes the Pokémon use the Encored move (if Encored), or Struggle.
    def pbAutoChooseMove(idxBattler, showMessages = true)
        battler = @battlers[idxBattler]
        if battler.fainted?
            pbClearChoice(idxBattler)
            return true
        end
        # Encore
        idxEncoredMove = battler.pbEncoredMoveIndex
        if idxEncoredMove >= 0 && pbCanChooseMove?(idxBattler, idxEncoredMove, false)
            encoreMove = battler.getMoves[idxEncoredMove]
            @choices[idxBattler][0] = :UseMove         # "Use move"
            @choices[idxBattler][1] = idxEncoredMove   # Index of move to be used
            @choices[idxBattler][2] = encoreMove       # PokeBattle_Move object
            @choices[idxBattler][3] = -1               # No target chosen yet
            return true if singleBattle?
            if pbOwnedByPlayer?(idxBattler)
                pbDisplayPaused(_INTL("{1} has to use {2}!", battler.name, encoreMove.name)) if showMessages
                return pbChooseTarget(battler, encoreMove)
            end
            return true
        end
        # Struggle
        pbDisplayPaused(_INTL("{1} has no moves left!", battler.name)) if pbOwnedByPlayer?(idxBattler) && showMessages
        @choices[idxBattler][0] = :UseMove    # "Use move"
        @choices[idxBattler][1] = -1          # Index of move to be used
        @choices[idxBattler][2] = @struggle   # Struggle PokeBattle_Move object
        @choices[idxBattler][3] = -1          # No target chosen yet
        return true
    end

    def pbRegisterMove(idxBattler, idxMove, showMessages = true)
        battler = @battlers[idxBattler]
        move = battler.getMoves[idxMove]
        return false unless pbCanChooseMove?(idxBattler, idxMove, showMessages)
        @choices[idxBattler][0] = :UseMove   # "Use move"
        @choices[idxBattler][1] = idxMove    # Index of move to be used
        @choices[idxBattler][2] = move       # PokeBattle_Move object
        @choices[idxBattler][3] = -1         # No target chosen yet
        return true
    end

    def pbChoseMove?(idxBattler, moveID)
        return false if !@battlers[idxBattler] || @battlers[idxBattler].fainted?
        return @choices[idxBattler][2].id == moveID if @choices[idxBattler][0] == :UseMove && @choices[idxBattler][1]
        return false
    end

    def pbChoseMoveFunctionCode?(idxBattler, code)
        return false if @battlers[idxBattler].fainted?
        if @choices[idxBattler][0] == :UseMove && @choices[idxBattler][1]
            return @choices[idxBattler][2].function == code
        end
        return false
    end

    def pbRegisterTarget(idxBattler, idxTarget)
        @choices[idxBattler][3] = idxTarget # Set target of move
    end

    # Returns whether the idxTarget will be targeted by a move with target_data
    # used by a battler in idxUser.
    def pbMoveCanTarget?(idxUser, idxTarget, target_data)
        return false if target_data.num_targets == 0
        case target_data.id
        when :NearAlly
            return false if opposes?(idxUser, idxTarget)
            return false unless nearEnoughForMoveTargeting?(idxUser, idxTarget)
        when :Ally
            return false if idxUser == idxTarget
            return false if opposes?(idxUser, idxTarget)
        when :UserOrNearAlly
            return true if idxUser == idxTarget
            return false if opposes?(idxUser, idxTarget)
            return false unless nearEnoughForMoveTargeting?(idxUser, idxTarget)
        when :UserAndAllies
            return false if opposes?(idxUser, idxTarget)
        when :UserOrNearOther
            return true if idxUser == idxTarget
            return false unless nearEnoughForMoveTargeting?(idxUser, idxTarget)
        when :NearFoe, :RandomNearFoe, :ClosestNearFoe
            return false unless opposes?(idxUser, idxTarget)
            return false unless nearEnoughForMoveTargeting?(idxUser, idxTarget)
        when :AllNearFoes
            return false unless opposes?(idxUser, idxTarget)
            return false unless nearBattlers?(idxUser, idxTarget)
        when :Foe
            return false unless opposes?(idxUser, idxTarget)
        when :AllFoes
            return false unless opposes?(idxUser, idxTarget)
        when :NearOther
            return false unless nearEnoughForMoveTargeting?(idxUser, idxTarget)
        when :AllNearOthers
            return false unless nearBattlers?(idxUser, idxTarget)
        when :Other
            return false if idxUser == idxTarget
        end
        return true
    end

    def nearEnoughForMoveTargeting?(idxBattler1, idxBattler2)
        return false if idxBattler1 == idxBattler2
        if @laneTargeting && pbSideSize(idxBattler2 % 2) > 1
            closestIndex = pbGetOpposingIndicesInOrder(idxBattler1)[0]
            return idxBattler2 == closestIndex
        else
            return nearBattlers?(idxBattler1, idxBattler2)
        end
    end

    #=============================================================================
    # Turn order calculation (priority)
    #=============================================================================
    def pbCalculatePriority(fullCalc = false, indexArray = nil, randomizeOrder = true)
        needRearranging = false
        if fullCalc
            @priorityTrickRoom = @field.effectActive?(:TrickRoom)
            # Recalculate everything from scratch
            randomOrder = Array.new(maxBattlerIndex + 1) { |i| i }
            # don't do extra random calls if recalculating for info screen, to ensure cable club sync
            if randomizeOrder
                (randomOrder.length - 1).times do |i| # Can't use shuffle! here
                    r = i + pbRandom(randomOrder.length - i)
                    randomOrder[i], randomOrder[r] = randomOrder[r], randomOrder[i]
                end
            end
            @priority.clear
            for i in 0..maxBattlerIndex
                b = @battlers[i]
                next unless b
            end
            for i in 0..maxBattlerIndex
                b = @battlers[i]
                next unless b
                # [battler, speed, sub-priority, priority, tie-breaker order]
                bArray = [b, b.pbSpeed, 0, 0, randomOrder[i]]
                if @choices[b.index][0] == :UseMove || @choices[b.index][0] == :Shift
                    # Calculate move's priority
                    if @choices[b.index][0] == :UseMove
                        move = @choices[b.index][2]
                        target_index = @choices[b.index][3]
                        if @client_id == 1
                            target_index = CableClub::pokemon_target_order(@client_id)[target_index]                          
                        end
                        targets = b.pbFindTargets(target_index, move, b)
                        pri = getMovePriority(move, b, targets)
                        bArray[3] = pri
                        @choices[b.index][4] = pri
                    end
                    # Calculate sub-priority (first/last within priority bracket)
                    # NOTE: Going fast beats going slow. A Pokémon with Stall and Quick
                    #       Claw will go first in its priority bracket if Quick Claw
                    #       triggers, regardless of Stall.
                    subPri = 0
                    # Abilities (Stall)
                    b.eachActiveAbility do |ability|
                        newSubPri = BattleHandlers.triggerPriorityBracketChangeAbility(ability,
                            b, subPri, self)
                        if subPri != newSubPri
                            subPri = newSubPri
                            b.applyEffect(:PriorityAbility, ability)
                            b.disableEffect(:PriorityItem)
                            break
                        end
                    end
                    # Items (Quick Claw, Custap Berry, Lagging Tail, Full Incense)
                    b.eachActiveItem do |item|
                        newSubPri = BattleHandlers.triggerPriorityBracketChangeItem(item, b, subPri, self)
                        if subPri != newSubPri
                            subPri = newSubPri
                            b.disableEffect(:PriorityAbility)
                            b.applyEffect(:PriorityItem, item)
                            break
                        end
                    end
                    bArray[2] = subPri
                end
                @priority.push(bArray)
            end
            needRearranging = true
        else
            if @field.effectActive?(:TrickRoom) != @priorityTrickRoom
                needRearranging = true
                @priorityTrickRoom = @field.effectActive?(:TrickRoom)
            end
            # Just recheck all battler speeds
            @priority.each do |orderArray|
                next unless orderArray
                next if indexArray && !indexArray.include?(orderArray[0].index)
                oldSpeed = orderArray[1]
                orderArray[1] = orderArray[0].pbSpeed
                needRearranging = true if orderArray[1] != oldSpeed
            end
        end
        # Reorder the priority array
        if needRearranging
            @priority.sort! do |a, b|
                if a[3] != b[3]
                    # Sort by priority (highest value first)
                    b[3] <=> a[3]
                elsif a[2] != b[2]
                    # Sort by sub-priority (highest value first)
                    b[2] <=> a[2]
                elsif @priorityTrickRoom
                    # Sort by speed (lowest first), and use tie-breaker if necessary
                    (a[1] == b[1]) ? b[4] <=> a[4] : a[1] <=> b[1]
                else
                    # Sort by speed (highest first), and use tie-breaker if necessary
                    (a[1] == b[1]) ? b[4] <=> a[4] : b[1] <=> a[1]
                end
            end
            # Write the priority order to the debug log
            logMsg = fullCalc ? "[Round order] " : "[Round order recalculated] "
            comma = false
            @priority.each do |orderArray|
                logMsg += ", " if comma
                logMsg += "#{orderArray[0].pbThis(comma)} (#{orderArray[0].index})"
                comma = true
            end
            PBDebug.log(logMsg)
        end
    end

    def getMovePriority(move, user, targets, aiCheck = false)
        priority = move.priority
        priority -= 1 if pbCheckGlobalAbility(:HONORABLE) && move.statusMove?
        user.eachAbilityShouldApply(aiCheck) do |ability|
            abilityPriorityChange = BattleHandlers.triggerPriorityChangeAbility(ability, user, move, 0, targets, aiCheck)
            priority += abilityPriorityChange
        end
        priority += move.priorityModification(user, targets)
        return priority
    end

    def pbPriority(onlySpeedSort = false)
        ret = []
        if onlySpeedSort
            # Sort battlers by their speed stats and tie-breaker order only.
            tempArray = []
            @priority.each { |pArray| tempArray.push([pArray[0], pArray[1], pArray[4]]) }
            tempArray.sort! { |a, b| (a[1] == b[1]) ? b[2] <=> a[2] : b[1] <=> a[1] }
            tempArray.each { |tArray| ret.push(tArray[0]) }
        else
            # Sort battlers by priority, sub-priority and their speed. Ties are
            # resolved in the same way each time this method is called in a round.
            @priority.each { |pArray| ret.push(pArray[0]) unless pArray[0].fainted? }
        end
        return ret
    end

    # Returns a hash assigning each unfainted battler a number which explains in what order the battlers
    # are expected to move this turn, accounting for only speed and trick room
    # Pokemon with speed ties are assigned the same number
    def pbTurnOrderDisplayed
        # don't do extra random calls if recalculating for info screen, to ensure cable club sync
        pbCalculatePriority(true,nil,false)
        
        speedHash = {}

        @priority.each do |pArray|
            battler = pArray[0]
            next if battler.fainted?
            speed = pArray[1]
            if speedHash.key?(speed)
                speedHash[speed].push(battler)
            else
                speedHash[speed] = [battler]
            end
        end

        trickRoom = @field.effectActive?(:TrickRoom)

        sortedSpeedKeys = speedHash.keys.sort do |speedA, speedB|
            val = speedB <=> speedA
            val *= -1 if trickRoom
            next val
        end

        battlerTurnOrderHash = {}
        speedHash.each_pair do |key, value|
            value.each do |battlerWithSpeed|
                battlerTurnOrderHash[battlerWithSpeed.index] = sortedSpeedKeys.index(key) + 1
            end
        end

        return battlerTurnOrderHash
    end
end
