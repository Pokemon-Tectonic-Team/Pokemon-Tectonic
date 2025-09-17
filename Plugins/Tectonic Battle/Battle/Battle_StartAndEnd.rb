class PokeBattle_Battle
    class BattleAbortedException < Exception; end

    def pbAbort
        raise BattleAbortedException, "Battle aborted"
    end

    #=============================================================================
    # Makes sure all Pokémon exist that need to. Alter the type of battle if
    # necessary. Will never try to create battler positions, only delete them
    # (except for wild Pokémon whose number of positions are fixed). Reduces the
    # size of each side by 1 and tries again. If the side sizes are uneven, only
    # the larger side's size will be reduced by 1 each time, until both sides are
    # an equal size (then both sides will be reduced equally).
    #=============================================================================
    def pbEnsureParticipants
        # Prevent battles larger than 2v2 if both sides have multiple trainers
        # NOTE: This is necessary to ensure that battlers can never become unable to
        #       hit each other due to being too far away. In such situations,
        #       battlers will move to the centre position at the end of a round, but
        #       because they cannot move into a position owned by a different
        #       trainer, it's possible that battlers will be unable to move close
        #       enough to hit each other if there are multiple trainers on each
        #       side.
        if trainerBattle? && (@sideSizes[0] > 2 || @sideSizes[1] > 2) &&
           @player.length > 1 && @opponent.length > 1
            raise _INTL("Can't have battles larger than 2v2 where both sides have multiple trainers")
        end
        # Find out how many Pokémon each trainer has
        side1counts = pbAbleTeamCounts(0)
        side2counts = pbAbleTeamCounts(1)
        # Change the size of the battle depending on how many wild Pokémon there are
        if wildBattle? && side2counts[0] != @sideSizes[1]
            if @sideSizes[0] == @sideSizes[1]
                # Even number of battlers per side, change both equally
                @sideSizes = [side2counts[0], side2counts[0]]
            else
                # Uneven number of battlers per side, just change wild side's size
                @sideSizes[1] = side2counts[0]
            end
        end
        # Check if battle is possible, including changing the number of battlers per
        # side if necessary
        loop do
            needsChanging = false
            for side in 0...2 # Each side in turn
                next if side == 1 && wildBattle? # Wild side's size already checked above
                sideCounts = (side == 0) ? side1counts : side2counts
                requireds = []
                # Find out how many Pokémon each trainer on side needs to have
                for i in 0...@sideSizes[side]
                    idxTrainer = pbGetOwnerIndexFromBattlerIndex(i * 2 + side)
                    requireds[idxTrainer] = 0 if requireds[idxTrainer].nil?
                    requireds[idxTrainer] += 1
                end
                # Compare the have values with the need values
                if requireds.length > sideCounts.length
                    raise _INTL("Error: def pbGetOwnerIndexFromBattlerIndex gives invalid owner index ({1} for battle type {2}v{3}, trainers {4}v{5})",
                       requireds.length - 1, @sideSizes[0], @sideSizes[1], side1counts.length, side2counts.length)
                end
                sideCounts.each_with_index do |_count, i|
                    if !requireds[i] || requireds[i] == 0
                        if side == 0
                            raise _INTL("Player-side trainer {1} has no battler position for their Pokémon to go (trying {2}v{3} battle)",
                               i + 1, @sideSizes[0], @sideSizes[1])
                        end
                        if side == 1
                            raise _INTL("Opposing trainer {1} has no battler position for their Pokémon to go (trying {2}v{3} battle)",
                               i + 1, @sideSizes[0], @sideSizes[1])
                        end
                    end
                    next if requireds[i] <= sideCounts[i] # Trainer has enough Pokémon to fill their positions
                    if requireds[i] == 1
                        raise _INTL("Player-side trainer {1} has no able Pokémon", i + 1) if side == 0
                        raise _INTL("Opposing trainer {1} has no able Pokémon", i + 1) if side == 1
                    end
                    # Not enough Pokémon, try lowering the number of battler positions
                    needsChanging = true
                    break
                end
                break if needsChanging
            end
            break unless needsChanging
            # Reduce one or both side's sizes by 1 and try again
            if wildBattle?
                PBDebug.log("#{@sideSizes[0]}v#{@sideSizes[1]} battle isn't possible " +
                            "(#{side1counts} player-side teams versus #{side2counts[0]} wild Pokémon)")
                newSize = @sideSizes[0] - 1
            else
                PBDebug.log("#{@sideSizes[0]}v#{@sideSizes[1]} battle isn't possible " +
                            "(#{side1counts} player-side teams versus #{side2counts} opposing teams)")
                newSize = @sideSizes.max - 1
            end
            raise _INTL("Couldn't lower either side's size any further, battle isn't possible") if newSize == 0
            for side in 0...2
                next if side == 1 && wildBattle? # Wild Pokémon's side size is fixed
                next if @sideSizes[side] == 1 || newSize > @sideSizes[side]
                @sideSizes[side] = newSize
            end
            PBDebug.log("Trying #{@sideSizes[0]}v#{@sideSizes[1]} battle instead")
        end
    end

    #=============================================================================
    # Set up all battlers
    #=============================================================================
    def pbCreateBattler(idxBattler, pkmn = nil, idxParty = -1)
        raise _INTL("Battler index {1} already exists", idxBattler) unless @battlers[idxBattler].nil?
        @battlers[idxBattler] = PokeBattle_Battler.new(self, idxBattler)
        @positions[idxBattler] = PokeBattle_ActivePosition.new(self, idxBattler)
        pbClearChoice(idxBattler)
        @successStates[idxBattler] = PokeBattle_SuccessState.new
        @battlers[idxBattler].pbInitialize(pkmn, idxParty) if pkmn
    end

    def pbSetUpSides
        ret = [[], []]
        for side in 0...2
            # Set up wild Pokémon
            if side == 1 && wildBattle?
                pbParty(1).each_with_index do |pkmn, idxPkmn|
                    pbCreateBattler(2 * idxPkmn + side, pkmn, idxPkmn)
                    # Changes the Pokémon's form upon entering battle (if it should)
                    @peer.pbOnEnteringBattle(self, pkmn, true)
                    pbSetSeen(@battlers[2 * idxPkmn + side])
                    @usedInBattle[side][idxPkmn] = true
                end
                next
            end
            # Set up player's Pokémon and trainers' Pokémon
            trainer = (side == 0) ? @player : @opponent
            requireds = []
            # Find out how many Pokémon each trainer on side needs to have
            for i in 0...@sideSizes[side]
                idxTrainer = pbGetOwnerIndexFromBattlerIndex(i * 2 + side)
                requireds[idxTrainer] = 0 if requireds[idxTrainer].nil?
                requireds[idxTrainer] += 1
            end
            # For each trainer in turn, find the needed number of Pokémon for them to
            # send out, and initialize them
            battlerNumber = 0
            trainer.each_with_index do |_t, idxTrainer|
                ret[side][idxTrainer] = []
                eachInTeam(side, idxTrainer) do |pkmn, idxPkmn|
                    next unless pkmn.able?
                    idxBattler = 2 * battlerNumber + side
                    pbCreateBattler(idxBattler, pkmn, idxPkmn)
                    ret[side][idxTrainer].push(idxBattler)
                    battlerNumber += 1
                    break if ret[side][idxTrainer].length >= requireds[idxTrainer]
                end
            end
        end
        return ret
    end

    #=============================================================================
    # Send out all battlers at the start of battle
    #=============================================================================
    def pbStartBattleSendOut(sendOuts)
        # "Want to battle" messages
        if wildBattle?
            foeParty = pbParty(1)
            case foeParty.length
            when 1
                foeName = foeParty[0].name
                foeName = "Pikachu" if foeParty[0].hasAbility?(:PRIMEVALDISGUISE)
                if bossBattle?
                    pbDisplayPaused(_INTL("Oh no! The avatar of {1} appeared!", foeName))
                else
                    pbDisplayPaused(_INTL("Oh! A wild {1} appeared!", foeName))
                end
            when 2
                if bossBattle?
                    pbDisplayPaused(_INTL("Oh no! The avatars of {1} and {2} appeared!", foeParty[0].name,
                        foeParty[1].name))
                else
                    pbDisplayPaused(_INTL("Oh! A wild {1} and {2} appeared!", foeParty[0].name,
                        foeParty[1].name))
                end
            when 3
                if bossBattle?
                    pbDisplayPaused(_INTL("Oh no! The avatars of {1}, {2} and {3} appeared!", foeParty[0].name,
                        foeParty[1].name, foeParty[2].name))
                else
                    pbDisplayPaused(_INTL("Oh! A wild {1}, {2} and {3} appeared!", foeParty[0].name,
                        foeParty[1].name, foeParty[2].name))
                end
            end
        else # Trainer battle
            case @opponent.length
            when 1
                pbDisplayPaused(_INTL("You are challenged by {1}!", @opponent[0].full_name))
            when 2
                pbDisplayPaused(_INTL("You are challenged by {1} and {2}!", @opponent[0].full_name,
                   @opponent[1].full_name))
            when 3
                pbDisplayPaused(_INTL("You are challenged by {1}, {2} and {3}!",
                   @opponent[0].full_name, @opponent[1].full_name, @opponent[2].full_name))
            end
        end
        # Send out Pokémon (opposing trainers first)
        for side in [1, 0]
            next if side == 1 && wildBattle?
            msg = ""
            toSendOut = []
            trainers = (side == 0) ? @player : @opponent
            # Opposing trainers and partner trainers's messages about sending out Pokémon
            trainers.each_with_index do |t, i|
                next if side == 0 && i == 0 # The player's message is shown last
                msg += "\r\n" if msg.length > 0
                sent = sendOuts[side][i]
                if !t.wild?
                    case sent.length
                    when 1
                        msg += _INTL("{1} sent out {2}!", t.full_name, @battlers[sent[0]].name)
                    when 2
                        msg += _INTL("{1} sent out {2} and {3}!", t.full_name,
                          @battlers[sent[0]].name, @battlers[sent[1]].name)
                    when 3
                        msg += _INTL("{1} sent out {2}, {3} and {4}!", t.full_name,
                          @battlers[sent[0]].name, @battlers[sent[1]].name, @battlers[sent[2]].name)
                    end
                else
                    case sent.length
                    when 1
                        msg += _INTL("The {1} joined the battle!", @battlers[sent[0]].name)
                    when 2
                        msg += _INTL("{1} and {2} joined the battle!", @battlers[sent[0]].name, @battlers[sent[1]].name)
                    when 3
                        msg += _INTL("{1}, {2} and {3} joined the battle!",@battlers[sent[0]].name, @battlers[sent[1]].name, @battlers[sent[2]].name)
                    end
                end
                toSendOut.concat(sent)
            end
            # The player's message about sending out Pokémon
            if side == 0
                msg += "\r\n" if msg.length > 0
                sent = sendOuts[side][0]
                case sent.length
                when 1
                    msg += _INTL("Go! {1}!", @battlers[sent[0]].name)
                when 2
                    msg += _INTL("Go! {1} and {2}!", @battlers[sent[0]].name, @battlers[sent[1]].name)
                when 3
                    msg += _INTL("Go! {1}, {2} and {3}!", @battlers[sent[0]].name,
                       @battlers[sent[1]].name, @battlers[sent[2]].name)
                end
                toSendOut.concat(sent)
            end
            pbDisplayBrief(msg) if msg.length > 0
            # The actual sending out of Pokémon
            animSendOuts = []
            toSendOut.each do |idxBattler|
                animSendOuts.push([idxBattler, @battlers[idxBattler].pokemon])
            end
            pbSendOut(animSendOuts, true)
        end
    end

    #=============================================================================
    # Start a battle
    #=============================================================================
    def pbStartBattle
        $battle = self

        # Spit out lots of debug information
        PBDebug.log("")
        PBDebug.log("******************************************")
        logMsg = "[Started battle] "
        if @sideSizes[0] == 1 && @sideSizes[1] == 1
            logMsg += "Single "
        elsif @sideSizes[0] == 2 && @sideSizes[1] == 2
            logMsg += "Double "
        elsif @sideSizes[0] == 3 && @sideSizes[1] == 3
            logMsg += "Triple "
        else
            logMsg += "#{@sideSizes[0]}v#{@sideSizes[1]} "
        end
        logMsg += "wild " if wildBattle?
        logMsg += "trainer " if trainerBattle?
        logMsg += "battle (#{@player.length} trainer(s) vs. "
        logMsg += "#{pbParty(1).length} wild Pokémon)" if wildBattle?
        logMsg += "#{@opponent.length} trainer(s))" if trainerBattle?
        PBDebug.log(logMsg)

        # Hide any dialogue speaker box
        reshowSpeakerWindow = false
        if speakerNameWindowVisible?
            hideSpeaker
            reshowSpeakerWindow = true
        end

        # Track information for perfecting
        trackPerfectBattle(false)
        ableBeforeFight = $Trainer.able_pokemon_count # Record the number of able party members, for perfecting
        skipPerfecting = false
        @opponent&.each do |opp|
            skipPerfecting = true if opp.is_no_perfect?
        end

        # Update tribe counts
        updateTribeCounts

        # Ensure the player's pokemon have up to date stats (e.g. due to balance changes between updates)
        updatePlayerStats

        pbEnsureParticipants
        begin
            pbStartBattleCore
        rescue BattleAbortedException
            @decision = 0
            @scene.pbEndBattle(@decision)
        rescue StandardError
            pbMessage(_INTL("\\wmA major error has occured! Please screen-shot the following error message and share it in our bug channel."))
            pbPrintException($!)
            pbMessage(_INTL("\\wmRather than crashing, we will give the victory to you."))
            pbMessage(_INTL("\\wmPlease don't abuse this functionality."))
            @decision = 1
            @scene.pbEndBattle(@decision)
        end

        # End the effect of all curses
        curses.each do |curse_policy|
            triggerBattleEndCurse(curse_policy, self)
        end
        unless @autoTesting
            # Record if the fight was perfected
            if $Trainer.able_pokemon_count >= ableBeforeFight
                trackPerfectBattle(true)
                if trainerBattle? && @decision == 1 && !skipPerfecting
                    pbMessage(_INTL("\\me[Battle perfected]You perfected the fight!"))
                end
            end
            # Update each of the player's pokemon's battling streak
            if (trainerBattle? || bossBattle?) && HOT_STREAKS_ACTIVE
                pbParty(0).each_with_index do |pkmn, i|
                    next unless pkmn
                    wasOnStreak = pkmn.onHotStreak?
                    if pkmn.fainted? || [2, 3].include?(@decision)
                        pkmn.battlingStreak = 0
                        pbMessage(_INTL("{1}'s Hot Streak is now over.", pkmn.name)) if wasOnStreak
                    elsif @usedInBattle[0][i]
                        pkmn.battlingStreak += 1
                        pbMessage(_INTL("{1} is on a Hot Streak!", pkmn.name)) if pkmn.onHotStreak? && !wasOnStreak
                    end
                end
            end
        end

        # Return the speaker box to being visible if it was hidden by the battle
        showSpeaker if reshowSpeakerWindow

        $battle = nil
        return @decision
    end

    def updateTribeCounts
        playerTribalBonus().updateTribeCount
        @opponent&.each do |opponentTrainer|
            opponentTrainer.tribalBonus.updateTribeCount
        end
    end

    def updatePlayerStats
        $Trainer.party.each do |partyMember|
            partyMember.calc_stats
        end  
    end

    def pbStartBattleCore
        # Set up the battlers on each side
        sendOuts = pbSetUpSides
        # Create all the sprites and play the battle intro animation
        @scene.pbStartBattle(self)
        # Show trainers on both sides sending out Pokémon
        pbStartBattleSendOut(sendOuts) unless @autoTesting
        # Coloration differences tutorial
        if $Options.color_shifts == 0 && !$PokemonGlobal.colorationDifferencesTutorialized
            eachOtherSideBattler do |b|
                totalColorationDiff = b.pokemon.hueShift.abs + (b.pokemon.shadeShift.abs) / 4
                next unless totalColorationDiff >= 16
                playColorationDifferencesTutorial
                break
            end
        end
        # Curses apply if at all
        if @opponent && $PokemonGlobal.tarot_amulet_active
            @statItemsAreMetagameRevealed = false
            @opponent.each do |opponent|
                opponent.policies.each do |policy|
                    cursesToAdd = triggerBattleStartApplyCurse(policy, self, [])
                    curses.concat(cursesToAdd)

                    @metaGamingStatItems = true if policy == :METAGAMES_STAT_ITEMS
                end
            end
        end
        # Weather announcement
        weather_data = GameData::BattleWeather.try_get(@field.weather)
        pbCommonAnimation(weather_data.animation) if weather_data
        case @field.weather
        when :Sunshine    then pbDisplay(_INTL("The sunlight is strong."))
        when :Rainstorm   then pbDisplay(_INTL("It is storming."))
        when :Sandstorm   then pbDisplay(_INTL("A sandstorm is raging."))
        when :Hail        then pbDisplay(_INTL("Hail is falling."))
        when :HarshSun    then pbDisplay(_INTL("The sunlight is extremely harsh."))
        when :HeavyRain   then pbDisplay(_INTL("It is raining heavily."))
        when :StrongWinds then pbDisplay(_INTL("The wind is strong."))
        when :RingEclipse then pbDisplay(_INTL("A planetary ring dominates the skyline."))
        when :Bloodmoon   then pbDisplay(_INTL("The moon is taken by a nightmare."))
        when :StarStorm   then pbDisplay(_INTL("Stardust churns all around."))
        when :IceAge      then pbDisplay(_INTL("An ice age is here."))
        end
        # Change avatars for auto-testing
        if @autoTesting
            eachBattler do |b|
                next unless b.boss?
                loop do
                    b.pokemon.species = GameData::Avatar::DATA.values.sample.id[0]
                    break if GameData::Avatar::DATA.has_key?(b.pokemon.species)
                end
                setAvatarProperties(b.pokemon)
                b.bossAI = PokeBattle_AI_Boss.from_boss_battler(b)
                autoTestingBattlerSpeciesChange(b)
            end
        end
        # Abilities upon entering battle
        pbOnActiveAll
        # Exit the pre-battle phase
        @preBattle = false
        # Main battle loop
        pbBattleLoop
    end

    #=============================================================================
    # Main battle loop
    #=============================================================================
    def pbBattleLoop
        @turnCount = 0
        loop do # Now begin the battle loop
            PBDebug.log("")
            PBDebug.log("***Round #{@turnCount + 1}***")
            if (@debug || @autoTesting) && @turnCount >= 100
                @decision = pbDecisionOnTime
                PBDebug.log("")
                PBDebug.log("***Undecided after 100 rounds, aborting***")
                pbAbort
                break
            end
            PBDebug.log("")

            # Start of round phase
            PBDebug.logonerr { pbStartOfRoundPhase }
            break if @decision > 0

            @commandPhasesThisRound = 0

            resetMoveUsageState

            # Command phase
            PBDebug.logonerr { pbCommandPhase }
            break if @decision > 0

            @commandPhasesThisRound = 1

            # Attack phase
            PBDebug.logonerr { pbAttackPhase }
            break if @decision > 0

            numExtraPhasesThisTurn = 0

            # Calculate how many extra phases to add
            eachBattler do |b|
                echoln("#{b.pbThis} gets #{b.extraMovesPerTurn} extra moves this turn.")
                numExtraPhasesThisTurn = b.extraMovesPerTurn if b.extraMovesPerTurn > numExtraPhasesThisTurn
            end

            # Extra phases after main phases
            if numExtraPhasesThisTurn > 0
                for i in 1..numExtraPhasesThisTurn do
                    echoln("Extra phase begins")
                    @battlers.each do |b|
                        next unless b
                        @lastRoundMoved = 0
                    end

                    resetMoveUsageState
                    
                    # Command phase
                    PBDebug.logonerr { pbExtraCommandPhase }
                    break if @decision > 0

                    @commandPhasesThisRound += 1

                    # Attack phase
                    PBDebug.logonerr { pbExtraAttackPhase }
                    break if @decision > 0
                end
            end

            # End of round phase
            PBDebug.logonerr { pbEndOfRoundPhase }
            break if @decision > 0

            @commandPhasesThisRound = 0

            useEmpoweredStatusMoves

            @turnCount += 1

            # Extra fake turn
            stretchers = []
            eachBattler { |b| stretchers.append(b) if b.hasActiveAbility?(:TIMESKIP) }

            timeStretcher = nil
            if stretchers.length > 0
                stretchers.each do |stretcher|
                    unless stretcher.effectActive?(:NoTimeSkip)
                        timeStretcher = stretcher
                        stretcher.applyEffect(:NoTimeSkip)
                    else
                        stretcher.disableEffect(:NoTimeSkip)
                    end
                end
            end

            unless timeStretcher.nil?
                pbShowAbilitySplash(timeStretcher, :TIMESKIP)
                pbDisplay(_INTL("Time is dancing to {1}'s tune! This turn is being skipped!", timeStretcher.pbThis))
                pbHideAbilitySplash(timeStretcher)
                # Start of round phase
                PBDebug.logonerr { pbStartOfRoundPhase }
                break if @decision > 0
                # End of round phase
                PBDebug.logonerr { pbEndOfRoundPhase }
                break if @decision > 0
                @turnCount += 1
            end

        end
        pbEndOfBattle
    end

    def pbStartOfRoundPhase
        # The battle is a draw if the player survives a certain number of turns
        # In survival battles
        if @turnsToSurvive > 0
            @scene.updateTurnCountReminder(@turnsToSurvive - @turnCount + 1)
            if @turnCount > @turnsToSurvive
                triggerBattleSurvivedDialogue
                @decision = 6
                return
            end
        end

        # Bosses begin the battle
        if @turnCount == 0
            @battlers.each do |b|
                next if !b || b.fainted || !b.boss?
                b.bossAI.startBattle(b, self)
            end
        end

        # Bosses begin their turn
        @battlers.each do |b|
            next if !b || b.fainted || !b.boss?
            b.bossAI.startTurn(b, self, @turnCount)
        end

        # Curses effects here
        @curses.each do |curse_policy|
            triggerBeginningOfTurnCurseEffect(curse_policy, self)
        end

        # Auto-pilot
        if @turnCount != 0
            autoPilots = []
            [0,1].each do |sideIndex|
                pbParty(sideIndex).each_with_index do |partyMember,partyIndex|
                    next unless partyMember
                    next if partyMember.fainted?
                    next unless partyMember.hasAbility?(:AUTOPILOT)
                    next if partyMember.status == :DIZZY
                    next if pokemonIsActiveBattler?(partyMember)
                    if @turnCount % 5 == 0
                        autoPilots.push(partyIndex)
                    elsif @turnCount % 5 == 4
                        pbDisplayPaused(_INTL("{1} will arrive next turn!",pbThisEx(sideIndex,partyIndex)))
                    end
                end

                eachSameSideBattler(sideIndex) do |activeBattler|
                    break if autoPilots.length == 0
                    autoPilotPartyIndex = autoPilots.pop

                    pbDisplayPaused(_INTL("{1} pilots into battle!",pbThisEx(sideIndex,autoPilotPartyIndex)))
                    pbRecallAndReplace(activeBattler.index, autoPilotPartyIndex)
                    activeBattler.applyEffect(:AutoPilot)
                end
            end
        end

        pbCalculatePriority           # recalculate speeds
        priority = pbPriority(true)   # in order of fastest -> slowest speeds only
        
        pbSORWeather(priority) unless @turnCount == 0

        # Switch Pokémon in if possible
        pbEORSwitch
    end

    #=============================================================================
    # End of battle
    #=============================================================================
    def moneyMult
        moneyMult = 1
        moneyMult *= 1.5 if @field.effectActive?(:AmuletCoin)
        moneyMult *= 1.5 if @field.effectActive?(:HardWorker)
        moneyMult *= 1.1 if playerTribalBonus.hasTribeBonus?(:INDUSTRIOUS)
        return moneyMult
    end

    def pbGainMoney
        return if !@internalBattle || !@moneyGain
        # Money rewarded from opposing trainers
        if trainerBattle?
            tMoney = 0
            @opponent.each_with_index do |t, i|
                baseMoney = t.base_money
                baseMoney = 10 + baseMoney / 2
                tMoney += pbMaxLevelInTeam(1, i) * baseMoney
            end
            tMoney = (tMoney * moneyMult).floor
            oldMoney = pbPlayer.money
            pbPlayer.money += tMoney
            moneyGained = pbPlayer.money - oldMoney
            pbDisplayPaused(_INTL("You got ${1} for winning!", moneyGained.to_s_formatted)) if moneyGained > 0
        end
        # Pick up money scattered by Pay Day
        if @sides[0].effectActive?(:PayDay)
            paydayMoney = @sides[0].effects[:PayDay]
            oldMoney = pbPlayer.money
            pbPlayer.money += paydayMoney
            moneyGained = pbPlayer.money - oldMoney
            pbDisplayPaused(_INTL("You picked up ${1}!", paydayMoney.to_s_formatted)) if moneyGained > 0
        end
    end

    def pbLoseMoney
        return if !@internalBattle || !@moneyGain
        return if $game_switches[Settings::NO_MONEY_LOSS]
        maxLevel = pbMaxLevelInTeam(0, 0) # Player's Pokémon only, not partner's
        multiplier = [8, 16, 24, 36, 48, 64, 80, 100, 120]
        idxMultiplier = [pbPlayer.badge_count, multiplier.length - 1].min
        tMoney = maxLevel * multiplier[idxMultiplier]
        tMoney = pbPlayer.money if tMoney > pbPlayer.money
        oldMoney = pbPlayer.money
        pbPlayer.money -= tMoney
        moneyLost = oldMoney - pbPlayer.money
        if moneyLost > 0
            if trainerBattle?
                pbDisplayPaused(_INTL("You gave ${1} to the winner...", moneyLost.to_s_formatted))
            else
                pbDisplayPaused(_INTL("You panicked and dropped ${1}...", moneyLost.to_s_formatted))
            end
        end
    end

    def pbEndOfBattle
        oldDecision = @decision
        @decision = 4 if @decision == 1 && wildBattle? && @caughtPokemon.length > 0
        case oldDecision
        ##### WIN #####
        when 1
            PBDebug.log("")
            PBDebug.log("***Player won***")
            if trainerBattle?
                @scene.pbTrainerBattleSuccess
                case @opponent.length
                when 1
                    pbDisplayPaused(_INTL("You defeated {1}!", @opponent[0].full_name))
                when 2
                    pbDisplayPaused(_INTL("You defeated {1} and {2}!", @opponent[0].full_name,
                    @opponent[1].full_name))
                when 3
                    pbDisplayPaused(_INTL("You defeated {1}, {2} and {3}!", @opponent[0].full_name,
                    @opponent[1].full_name, @opponent[2].full_name))
                end
                @opponent.each_with_index do |_t, i|
                    if @endSpeeches[i] && @endSpeeches[i] != "" && @endSpeeches[i] != "..."
                        @scene.pbShowOpponent(i)
                        pbDisplayPaused(@endSpeeches[i].gsub(/\\[Pp][Nn]/, pbPlayer.name))
                    end
                end
            end
            # Gain money from winning a trainer battle, and from Pay Day
            pbGainMoney if @decision != 4
            # Hide remaining trainer
            @scene.pbShowOpponent(@opponent.length) if trainerBattle? && @caughtPokemon.length > 0
        #### WIN FROM TIMEOUT ####
        when 6
            PBDebug.log("")
            PBDebug.log("***Player won from time***")
            if trainerBattle?
                @scene.pbTrainerBattleSuccess
                case @opponent.length
                when 1
                    pbDisplayPaused(_INTL("You outlasted {1}.", @opponent[0].full_name))
                when 2
                    pbDisplayPaused(_INTL("You outlasted {1} and {2}.", @opponent[0].full_name,
                    @opponent[1].full_name))
                when 3
                    pbDisplayPaused(_INTL("You outlasted {1}, {2} and {3}.", @opponent[0].full_name,
                    @opponent[1].full_name, @opponent[2].full_name))
                end
                @opponent.each_with_index do |_t, i|
                    next unless @endSpeeches[i] && @endSpeeches[i] != "" && @endSpeeches[i] != "..."
                    @scene.pbShowOpponent(i)
                    pbDisplayPaused(@endSpeeches[i].gsub(/\\[Pp][Nn]/, pbPlayer.name))
                end
            end
            # Hide remaining trainer
            @scene.pbShowOpponent(@opponent.length) if trainerBattle? && @caughtPokemon.length > 0
        ##### LOSE, DRAW #####
        when 2, 5
            PBDebug.log("")
            PBDebug.log("***Player lost***") if @decision == 2
            PBDebug.log("***Player drew with opponent***") if @decision == 5
            if @internalBattle
                if trainerBattle?
                    case @opponent.length
                    when 1
                        pbDisplayPaused(_INTL("You lost against {1}!", @opponent[0].full_name))
                    when 2
                        pbDisplayPaused(_INTL("You lost against {1} and {2}!",
                          @opponent[0].full_name, @opponent[1].full_name))
                    when 3
                        pbDisplayPaused(_INTL("You lost against {1}, {2} and {3}!",
                          @opponent[0].full_name, @opponent[1].full_name, @opponent[2].full_name))
                    end
                end
            elsif @decision == 2
                if @opponent
                    @opponent.each_with_index do |_t, i|
                        next unless (@endSpeechesWin[i] && @endSpeechesWin[i] != "" && @endSpeechesWin[i] != "...")
                        @scene.pbShowOpponent(i)
                        pbDisplayPaused(@endSpeechesWin[i].gsub(/\\[Pp][Nn]/, pbPlayer.name))
                    end
                end
            end
        ##### CAUGHT WILD POKÉMON #####
        when 4
            @scene.pbWildBattleSuccess unless Settings::GAIN_EXP_FOR_CAPTURE
        end
        
        # Register captured Pokémon in the Pokédex, and store them
        pbRecordAndStoreCaughtPokemon

        # Collect Pay Day money in a wild battle that ended in a capture
        pbGainMoney if @decision == 4
        pbDisplayWithFormatting(_INTL("\\i[EXPEZDISPENSER]{1} exp was stored in the EXP-EZ Dispenser this battle.", separate_comma(@expStored))) if @expStored > 0
        
        # Clean up battle stuff
        @scene.pbEndBattle(@decision)
        eachBattler do |b|
            pbCancelChoice(b.index) # Restore unused items to Bag
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityOnSwitchOut(ability, b, self, true)
            end
        end

        # Reset some aspects of party pokemon
        pbParty(0).each_with_index do |pkmn, i|
            next unless pkmn
            pkmn.removeFear if pkmn.afraid? unless @autoTesting
            @peer.pbOnLeavingBattle(self, pkmn, @usedInBattle[0][i], true) # Reset form
        end

        restoreInitialItems

        # Remove avatars from the trainer's party
        pbParty(0).reject! { |pkmn|
            pkmn.boss?
        }
        pbParty(0).compact!

        # Reset max PPs
        setMaxPPs(false)

        return @decision
    end

    def restoreInitialItems
        pbParty(0).each_with_index do |pkmn, i|
            next unless pkmn
            pkmn.setItems(@initialItems[0][i])
        end
    end

    #=============================================================================
    # Judging
    #=============================================================================
    def pbJudgeCheckpoint(user, move = nil); end

    def pbDecisionOnTime
        counts   = [0, 0]
        hpTotals = [0, 0]
        for side in 0...2
            pbParty(side).each do |pkmn|
                next if !pkmn || !pkmn.able?
                counts[side]   += 1
                hpTotals[side] += pkmn.hp
            end
        end
        return 1 if counts[0] > counts[1]       # Win (player has more able Pokémon)
        return 2 if counts[0] < counts[1]       # Loss (foe has more able Pokémon)
        return 1 if hpTotals[0] > hpTotals[1]   # Win (player has more HP in total)
        return 2 if hpTotals[0] < hpTotals[1]   # Loss (foe has more HP in total)
        return 5 # Draw
    end

    # Unused
    def pbDecisionOnTime2
        counts   = [0, 0]
        hpTotals = [0, 0]
        for side in 0...2
            pbParty(side).each do |pkmn|
                next if !pkmn || !pkmn.able?
                counts[side]   += 1
                hpTotals[side] += 100 * pkmn.hp / pkmn.totalhp
            end
            hpTotals[side] /= counts[side] if counts[side] > 1
        end
        return 1 if counts[0] > counts[1]       # Win (player has more able Pokémon)
        return 2 if counts[0] < counts[1]       # Loss (foe has more able Pokémon)
        return 1 if hpTotals[0] > hpTotals[1]   # Win (player has a bigger average HP %)
        return 2 if hpTotals[0] < hpTotals[1]   # Loss (foe has a bigger average HP %)
        return 5 # Draw
    end

    def pbDecisionOnDraw; return 5; end     # Draw

    def pbJudge
        fainted1 = pbAllFainted?(0)
        fainted2 = pbAllFainted?(1)
        if fainted1 && fainted2
            @decision = pbDecisionOnDraw
        elsif fainted1
            @decision = 2
        elsif fainted2
            @decision = 1
        end
    end

    def resetMoveUsageState
        # Reset the state of all moves
        pbPriority.each do |b|
            b.getMoves.each do |move|
                move.resetMoveUsageState
            end
        end
    end
end
