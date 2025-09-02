class PokeBattle_Battle
    #=============================================================================
    # Clear commands
    #=============================================================================
    def pbClearChoice(idxBattler)
        @choices[idxBattler] = [] unless @choices[idxBattler]
        @choices[idxBattler][0] = :None
        @choices[idxBattler][1] = 0
        @choices[idxBattler][2] = nil
        @choices[idxBattler][3] = -1
    end

    def pbCancelChoice(idxBattler)
        # If idxBattler's choice was to use an item, return that item to the Bag
        if @choices[idxBattler][0] == :UseItem
            item = @choices[idxBattler][1]
            pbReturnUnusedItemToBag(item, idxBattler) if item
        end
        # Clear idxBattler's choice
        pbClearChoice(idxBattler)
    end

    #=============================================================================
    # Use main command menu (Fight/Pokémon/Bag/Run)
    #=============================================================================
    def pbCommandMenu(idxBattler, firstAction)
        return @scene.pbCommandMenu(idxBattler, firstAction)
    end

    #=============================================================================
    # Check whether actions can be taken
    #=============================================================================
    def pbCanShowCommands?(idxBattler)
        battler = @battlers[idxBattler]
        return false if !battler || battler.fainted?
        return false if battler.usingMultiTurnAttack?
        return true
    end

    def canChooseAnyMove?(idxBattler)
        battler = @battlers[idxBattler]
        battler.eachMoveWithIndex do |_m, i|
            next unless pbCanChooseMove?(idxBattler, i, false)
            return true
        end
        return false
    end

    def pbCanShowFightMenu?(idxBattler)
        battler = @battlers[idxBattler]
        # Encore
        return false if battler.effectActive?(:Encore)
        # No moves that can be chosen (will Struggle instead)
        usable = false
        battler.eachMoveWithIndex do |_m, i|
            next unless pbCanChooseMove?(idxBattler, i, false)
            usable = true
            break
        end
        return usable
    end

    #=============================================================================
    # Use sub-menus to choose an action, and register it if is allowed
    #=============================================================================
    # Returns true if a choice was made, false if cancelled.
    def pbFightMenu(idxBattler)
        battler = @battlers[idxBattler]
        unless canChooseAnyMove?(idxBattler)
            if pbDisplayConfirmSerious(_INTL("{1} cannot use any of its moves, and will Struggle if it fights. Go ahead?", battler.pbThis))
                return pbAutoChooseMove(idxBattler)
            else
                return false
            end
        end
        if battler.effectActive?(:Encore)
            encoreMove = battler.getMoves[battler.pbEncoredMoveIndex]
            if pbDisplayConfirm(_INTL("{1} must use {2} if it fights. Go ahead?", battler.pbThis, encoreMove.name))
                return pbAutoChooseMove(idxBattler)
            else
                return false
            end
        end
        # Battle Palace only
        return true if pbAutoFightMenu(idxBattler)
        # Regular move selection
        ret = false
        @scene.pbFightMenu(idxBattler) do |cmd|
            case cmd
            when -1   # Cancel
            when -3   # Shift
                pbRegisterShift(idxBattler)
                ret = true
            else      # Chose a move to use
                move = @battlers[idxBattler].getMoves[cmd]
                next false if cmd < 0 || move.nil? || move.id.nil?
                next false unless pbRegisterMove(idxBattler, cmd)
                target_data = move.pbTarget(battler)
                next false if (!singleBattle? || target_data.id == :UserOrNearOther) &&
                              !pbChooseTarget(@battlers[idxBattler], move)
                ret = true
            end
            next true
        end
        return ret
    end

    def pbAutoFightMenu(_idxBattler); return false; end

    def pbChooseTarget(battler, move)
        target_data = move.pbTarget(battler)
        idxTarget = @scene.pbChooseTarget(battler.index, target_data)
        return false if idxTarget < 0
        pbRegisterTarget(battler.index, idxTarget)
        return true
    end

    def pbItemMenu(idxBattler, firstAction)
        unless @internalBattle
            pbDisplay(_INTL("Items can't be used here."))
            return false
        end
        ret = false
        @scene.pbItemMenu(idxBattler, firstAction) do |item, useType, idxPkmn, idxMove, itemScene|
            next false unless item
            battler = pkmn = nil
            case useType
            when 1, 2 # Use on Pokémon/Pokémon's move
                next false unless ItemHandlers.hasBattleUseOnPokemon(item)
                battler = pbFindBattler(idxPkmn, idxBattler)
                pkmn    = pbParty(idxBattler)[idxPkmn]
                next false unless pbCanUseItemOnPokemon?(item, pkmn, battler, itemScene)
            when 3   # Use on battler
                next false unless ItemHandlers.hasBattleUseOnBattler(item)
                battler = pbFindBattler(idxPkmn, idxBattler)
                pkmn    = battler.pokemon if battler
                next false unless pbCanUseItemOnPokemon?(item, pkmn, battler, itemScene)
            when 4   # Poké Balls
                next false if idxPkmn < 0
                battler = @battlers[idxPkmn]
                pkmn    = battler.pokemon if battler
            when 5 # No target (Poké Doll, Guard Spec., Launcher items)
                battler = @battlers[idxBattler]
                pkmn    = battler.pokemon if battler
            else
                next false
            end
            next false unless pkmn
            next false unless ItemHandlers.triggerCanUseInBattle(item,
               pkmn, battler, idxMove, firstAction, self, itemScene)
            next false unless pbRegisterItem(idxBattler, item, idxPkmn, idxMove)
            ret = true
            next true
        end
        return ret
    end

    def pbPartyMenu(idxBattler)
        ret = -1
        if @debug
            ret = @battleAI.pbDefaultChooseNewEnemy(idxBattler)
        else
            ret = pbPartyScreen(idxBattler, false, true, true)
        end
        return ret >= 0
    end

    def pbRunMenu(idxBattler)
        # Regardless of succeeding or failing to run, stop choosing actions
        return pbRun(idxBattler) != 0
    end

    def pbCallMenu(idxBattler)
        return pbRegisterCall(idxBattler)
    end

    def pbDebugMenu
        # NOTE: This doesn't do anything yet. Maybe you can write your own debugging
        #       options!
    end

    #=============================================================================
    # Command phase
    #=============================================================================
    def describeAction(actor,action)
        case action[0]
        when :None
            return "do nothing"
        when :SwitchOut
            return "switch with #{actor.ownerParty[action[1]].name}"
        when :UseMove
            if action[3] == -1
                return "use #{action[2].name}"
            else
                return "use #{action[2].name} on #{@battlers[action[3]].pbThis(true)}"
            end
        end
    end

    def pbCommandPhase
        @scene.pbBeginCommandPhase

        # Reset choices if commands can be shown
        @battlers.each_with_index do |b, i|
            next unless b
            pbClearChoice(i) if pbCanShowCommands?(i)
        end

        # Reset choices to perform Mega Evolution if it wasn't done somehow
        for side in 0...2
            @megaEvolution[side].each_with_index do |megaEvo, i|
                @megaEvolution[side][i] = -1 if megaEvo >= 0
            end
        end

        preSelectionAlerts

        # Choose actions for the round (AI first, then player)

        # Turn skipped due to ambush
        if @turnCount == 0 && @playerAmbushing
            # Player ambushes successfully!
            pbDisplayBossNarration(_INTL("Your foe was <imp>ambushed</imp>! You get a free turn!"))
            eachOtherSideBattler do |b|
                b.extraMovesPerTurn = 0
            end
        else
            # AI chooses their actions
            pbCommandPhaseLoop(false)
        end

        return if @decision != 0 # Battle ended, stop choosing actions

        if pbCheckGlobalAbility(:INVESTIGATOR)
            # Each of the player's pokemon (or NPC allies)
            eachSameSideBattler do |b|
                next unless b.hasActiveAbility?(:INVESTIGATOR)
                possibleInvestigation = []
                b.eachOpposing do |bOpp|
                    next if bOpp.fainted?
                    possibleInvestigation.push(bOpp)
                end
                next if possibleInvestigation.length == 0
                investigating = possibleInvestigation.sample
                pbShowAbilitySplash(b, :INVESTIGATOR)
                choice = @choices[investigating.index]
                case choice[0]
                when :UseMove
                    moveUsing = choice[2]
                    if moveUsing.statusMove?
                        pbDisplay(_INTL("{1} predicts that {2} will use a status move!", b.pbThis, investigating.pbThis(true)))
                    else
                        pbDisplay(_INTL("{1} predicts that {2} will use an attack!", b.pbThis, investigating.pbThis(true)))
                    end
                when :SwitchOut
                    pbDisplay(_INTL("{1} predicts that {2} will switch out!", b.pbThis, investigating.pbThis(true)))
                end
                pbHideAbilitySplash(b)
            end
        end

        # Turn skipped due to ambush
        if @turnCount == 0 && @foeAmbushing
            # The player is ambushed by the foe!
            pbDisplayBossNarration(_INTL("You were <imp>ambushed</imp>! The foe gets a free turn!"))
            eachSameSideBattler do |b|
                b.extraMovesPerTurn = 0
            end
        else
            pbCommandPhaseLoop(true) # Player chooses their actions
        end

        triggerAllChoicesDialogue
    end

    def preSelectionAlerts
        # Soul Read alerts
        @battlers.each do |battler|
            next if battler.nil?
            next unless battler.hasActiveAbility?(:SOULREAD)
            battler.eachOpposing do |opponent|
                next if opponent.lastMoveUsedType.nil?
                next if opponent.pbTypes(true).include?(opponent.lastMoveUsedType)
                pbShowAbilitySplash(battler, :SOULREAD)
                pbDisplay(_INTL("{1} reads {2}'s guilty soul!", battler.pbThis, opponent.pbThis(true)))
                pbHideAbilitySplash(battler)
            end
        end
    end

    def triggerAllChoicesDialogue
        idxBattler = -1
        loop do
            idxBattler += 1
            break if idxBattler >= @battlers.length
            battler = @battlers[idxBattler]
            next if battler.nil?
            triggerBattlerChoiceDialogue(battler, @choices[idxBattler])
        end
    end

    def pbExtraCommandPhase
        @scene.pbBeginCommandPhase
        # Reset choices if commands can be shown
        @battlers.each_with_index do |b, i|
            next unless b
            pbClearChoice(i) if pbCanShowCommands?(i)
        end
        # Reset choices to perform Mega Evolution if it wasn't done somehow
        for side in 0...2
            @megaEvolution[side].each_with_index do |megaEvo, i|
                @megaEvolution[side][i] = -1 if megaEvo >= 0
            end
        end
        # Choose actions for the round (AI first, then player)
        pbCommandPhaseLoop(false) # AI chooses their actions
        return if @decision != 0 # Battle ended, stop choosing actions
        pbCommandPhaseLoop(true) # Player chooses their actions
    end

    def chooseAutoTesting(idxBattler)
        if @battlers[idxBattler].boss?
            @battleAI.pbChooseMovesBoss(idxBattler)
        else
            chooseAutoTestingTrainer(idxBattler)
        end
    end

    def chooseAutoTestingTrainer(idxBattler)
        moveData = nil
        while moveData.nil? || moveData.cut || moveData.zmove
            moveData = GameData::Move::DATA.values.sample
        end
        moveId = moveData.id

        user = @battlers[idxBattler]

        moveObject = PokeBattle_Move.from_pokemon_move(self, Pokemon::Move.new(moveId))

        PBDebug.logonerr do
            @battleAI.pbEvaluateMoveTrainer(user, moveObject)
        end

        user.getMoves[0] = moveObject

        @choices[idxBattler][0] = :UseMove # "Use move"
        @choices[idxBattler][1] = 0 # Index of move to be used
        @choices[idxBattler][2] = moveObject # PokeBattle_Move object
        @choices[idxBattler][3] = -1
    end

    def autoTestingBattlerSpeciesChange(b)
        b.pokemon.level = 1 + pbRandom(69).ceil
        b.pokemon.calc_stats
        b.pokemon.name = nil
        b.pbInitPokemon(b.pokemon, b.pokemonIndex)
        @scene.pbChangePokemon(b.index, b.pokemon)
    end

    def getRandomHeldItem
        heldItemData = nil
        while heldItemData.nil? || heldItemData.pocket != 5 || heldItemData.is_mega_stone?
            heldItemData = GameData::Item::DATA.values.sample
        end
        return heldItemData.id
    end

    def changesForAutoTesting
        # Change all party members
        unless @bossBattle
            [@party1, @party2].each_with_index do |party, partyIndex|
                party.each_with_index do |pokemon, i|
                    next unless pokemon&.able?
                    next if pbFindBattler(i, partyIndex) # Skip Pokémon in battle
                    pokemon.species = GameData::Species::DATA.keys.sample
                    pokemon.name = nil
                    pokemon.level = 1 + pbRandom(69).ceil
                    pokemon.calc_stats
                    pokemon.giveItem(getRandomHeldItem)
                end
            end
        end

        # Change all battlers
        @battlers.each do |b|
            next if b.nil? || b.pokemon.nil? || b.boss?
            b.pokemon.species = GameData::Species::DATA.keys.sample
            autoTestingBattlerSpeciesChange(b)
        end

        updateTribeCounts
    end

    def pbCommandPhaseLoop(isPlayer)
        # NOTE: Doing some things (e.g. running, throwing a Poké Ball) takes up all
        #       your actions in a round.

        changesForAutoTesting if @autoTesting && @turnCount == 0

        unless isPlayer
            @battleAI.resetPrecalculations

            # AI predicts the players actions
            @predictedActions = {}

            anyCanPredict = false
            if @opponent
                @opponent.each do |opposingTrainer|
                    next unless opposingTrainer.policies.include?(:PREDICTS_PLAYER)
                    anyCanPredict = true
                    break
                end

                # Each of the player's pokemon (or NPC allies)
                if anyCanPredict && !@autoTesting
                    echoln("[PLAYER PREDICTION]")
                    eachSameSideBattler do |b|
                        next unless b.pbOwnedByPlayer?
                        predictedPlayerAction = @battleAI.pbPredictChoiceByPlayer(b.index)
                        @predictedActions[b.index] = predictedPlayerAction
                    end

                    eachSameSideBattler do |b|
                        next unless b.pbOwnedByPlayer?
                        describedPlayerAction = describeAction(b,@predictedActions[b.index])
                        echoln("[PLAYER PREDICTION] The AI predicts that #{b.pbThis} will #{describedPlayerAction}!")
                    end
                end
            end
        end

        actioned = []
        idxBattler = -1
        loop do
            break if @decision != 0 # Battle ended, stop choosing actions
            idxBattler += 1
            break if idxBattler >= @battlers.length
            battler = @battlers[idxBattler]
            next if battler.nil?
            next if pbOwnedByPlayer?(idxBattler) != isPlayer
            # Allow command selection in multiplayer even during extra command phases
            skipBattlerBecauseExtraTurn = false
            if @commandPhasesThisRound > battler.extraMovesPerTurn
                skipBattlerBecauseExtraTurn = true
            end
            next if !is_online? && skipBattlerBecauseExtraTurn
            next if @choices[idxBattler][0] != :None # Action is forced, can't choose one
            next unless pbCanShowCommands?(idxBattler) # Action is forced, can't choose one
            # AI controls this battler
            if @controlPlayer || !pbOwnedByPlayer?(idxBattler) || battler.effectActive?(:AutoPilot)
                if @autoTesting
                    chooseAutoTesting(idxBattler)
                    next
                end

                # Debug testing thing
                @battleAI.beginAITester(battler) if debugControl && Input.press?(Input::SPECIAL)

                # Increment their choices taken
                if battler.choicesTaken.nil?
                    battler.choicesTaken = 1
                else
                    battler.choicesTaken += 1
                end

                # Have the AI choose an action
                # For Cable Club reasons, this happens even on an extra turn if the AI can't move
                # But it will make sure communication still happens and shouldn't have ill effects
                @battleAI.pbDefaultChooseEnemyCommand(idxBattler)

                # Go to the next battler
                next
            end

            # now that we've handled the AI/communication processing, even if online, skip if we can't take an action
            next if skipBattlerBecauseExtraTurn

            # Player chooses an action
            actioned.push(idxBattler)

            if @autoTesting
                chooseAutoTesting(idxBattler)
                next
            end

            commandsEnd = false # Whether to cancel choosing all other actions this round
            loop do
                cmd = pbCommandMenu(idxBattler, actioned.length == 1)
                case cmd
                when 0    # Fight
                    break if pbFightMenu(idxBattler)
                when 1    # Dex
                    chooseDexTarget(@battlers[idxBattler])
                when 2    # Ball
                    if trainerBattle?
                        pbDisplay(_INTL("You can't catch trainers' Pokemon!"))
                        next
                    end
                    if bossBattle?
                        pbDisplay(_INTL("You can't catch Avatars!"))
                        next
                    end
                    if pbItemMenu(idxBattler, actioned.length == 1)
                        commandsEnd = true if pbItemUsesAllActions?(@choices[idxBattler][1])
                        break
                    end
                when 3    # Pokémon
                    break if pbPartyMenu(idxBattler)
                when 4    # Battle info
                    pbBattleInfoMenu
                when 5    # Run
                    # NOTE: "Run" is only an available option for the first battler the
                    #       player chooses an action for in a round. Attempting to run
                    #       from battle prevents you from choosing any other actions in
                    #       that round.
                    if pbRunMenu(idxBattler)
                        commandsEnd = true
                        break
                    end
                when 6 # Documentation menu
                    showDocumentationMenu(self)
                when -2   # Debug
                    pbDebugMenu
                    next
                when -1   # Go back to previous battler's action choice
                    next if actioned.length <= 1
                    actioned.pop # Forget this battler was done
                    idxBattler = actioned.last - 1
                    pbCancelChoice(idxBattler + 1) # Clear the previous battler's choice
                    actioned.pop   # Forget the previous battler was done
                    break
                end
                pbCancelChoice(idxBattler)
            end
            break if commandsEnd
        end
    end

    def pbBattleInfoMenu
        @scene.pbBattleInfoMenu
    end
end
