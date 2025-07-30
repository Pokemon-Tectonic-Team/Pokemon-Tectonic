class PokeBattle_Battler
    #=============================================================================
    # Turn processing
    #=============================================================================
    def pbProcessTurn(choice, tryFlee = true)
        return false if fainted?
        # Wild roaming Pokémon always flee if possible
        if tryFlee && @battle.wildBattle? && opposes? &&
           @battle.rules["alwaysflee"] && @battle.pbCanRun?(@index)
            pbBeginTurn(choice)
            pbSEPlay("Battle flee")
            @battle.pbDisplay(_INTL("{1} fled from battle!", pbThis))
            @battle.decision = 3
            pbEndTurn(choice)
            return true
        end
        # Shift with the battler next to this one
        if choice[0] == :Shift
            idxOther = -1
            case @battle.pbSideSize(@index)
            when 2
                idxOther = (@index + 2) % 4
            when 3
                if @index != 2 && @index != 3 # If not in middle spot already
                    idxOther = @index.even? ? 2 : 3
                end
            end
            if idxOther >= 0
                @battle.pbSwapBattlers(@index, idxOther)
                case @battle.pbSideSize(@index)
                when 2
                    @battle.pbDisplay(_INTL("{1} moved across!", pbThis))
                when 3
                    @battle.pbDisplay(_INTL("{1} moved to the center!", pbThis))
                end
            end
            pbBeginTurn(choice)
            pbCancelMoves
            @lastRoundMoved = @battle.turnCount # Done something this round
            return true
        end
        # If this battler's action for this round wasn't "use a move"
        if choice[0] != :UseMove
            # Clean up effects that end at battler's turn
            pbBeginTurn(choice)
            pbEndTurn(choice)
            return false
        end
        # Turn is skipped if Pursuit was used during switch
        if effectActive?(:Pursuit)
            disableEffect(:Pursuit)
            pbCancelMoves
            pbEndTurn(choice)
            @battle.pbJudge
            return false
        end
        # Use the move
        PBDebug.log("[Move usage] #{pbThis} started using #{choice[2].name}")
        unless PBDebug.logonerr do
                   pbUseMove(choice, choice[2] == @battle.struggle)
               end
            PBDebug.log("[Move usage] Cancelling move usage due to an error.")
            pbCancelMoves
            pbEndTurn(choice)
            @battle.pbJudge
            return false
        end
        @battle.pbJudge
        # Update priority order
        @battle.pbCalculatePriority
        return true
    end

    #=============================================================================
    # The battler begins their turn.
    #=============================================================================
    def pbBeginTurn(_choice)
        @effects[:DestinyBondPrevious] = @effects[:DestinyBond]

        eachEffect do |effect, _value, effectData|
            disableEffect(effect) if effectData.resets_battlers_sot
        end

        # Encore's effect ends if the encored move is no longer available
        disableEffect(:Encore) if effectActive?(:Encore) && pbEncoredMoveIndex < 0
    end

    # Called when the usage of various multi-turn moves is disrupted due to
    # failing pbTryUseMove, being ineffective against all targets, or because
    # Pursuit was used specially to intercept a switching foe.
    # Cancels the use of multi-turn moves and counters thereof. Note that Hyper
    # Beam's effect is NOT cancelled.
    def pbCancelMoves
        echoln("[EFFECTS] Effects are being disabled due to moves being cancelled on #{pbThis(true)}")
        eachEffect do |effect, _value, effectData|
            disableEffect(effect) if effectData.resets_on_cancel
        end
        @currentMove = nil
    end

    def pbEndTurn(_choice)
        @lastRoundMoved = @battle.turnCount # Done something this round
        # Gorilla Tactics
        if !effectActive?(:GorillaTactics) && hasActiveAbility?(GameData::Ability.getByFlag("ChoiceLocking"))
            if !@lastMoveUsed.nil? && pbHasMove?(@lastMoveUsed)
                applyEffect(:GorillaTactics, @lastMoveUsed)
            elsif !@lastRegularMoveUsed.nil? && pbHasMove?(@lastRegularMoveUsed)
                applyEffect(:GorillaTactics, @lastRegularMoveUsed)
            end
        end
        # Choice Items
        if !effectActive?(:ChoiceBand) && hasActiveItem?(GameData::Item.getByFlag("ChoiceLocking"))
            if !@lastMoveUsed.nil? && pbHasMove?(@lastMoveUsed)
                applyEffect(:ChoiceBand, @lastMoveUsed)
            elsif !@lastRegularMoveUsed.nil? && pbHasMove?(@lastRegularMoveUsed)
                applyEffect(:ChoiceBand, @lastRegularMoveUsed)
            end
        end

        eachEffect do |effect, _value, effectData|
            disableEffect(effect) if effectData.resets_battlers_eot
        end

        @battle.eachBattler { |b| b.pbContinualAbilityChecks } # Trace, end primordial weathers
    end

    def pbConfusionDamage(msg, superEff = false, basePower = 50, category: 3)
        @damageState.reset
        @damageState.initialHP = @hp
        confusionMove = case category
        when 0
            PokeBattle_SelfHitPhysical.new(@battle, nil, basePower)
        when 1
            PokeBattle_SelfHitSpecial.new(@battle, nil, basePower)
        when 3
            PokeBattle_SelfHit.new(@battle, nil, basePower)
        end
        confusionMove.calcType = confusionMove.pbCalcType(self) # nil
        confusionMove.calculateUsageOverrides(self, [self])
        @damageState.typeMod = confusionMove.pbCalcTypeMod(confusionMove.calcType, self, self) # 8
        @damageState.typeMod *= 2.0 if superEff
        confusionMove.pbCheckDamageAbsorption(self, self)
        confusionMove.pbCalcDamage(self, self)
        confusionMove.pbReduceDamage(self, self)
        oldHP = hp
        self.hp -= @damageState.hpLost
        confusionMove.pbAnimateHitAndHPLost(self, [self])
        @battle.pbDisplay(msg) unless msg.nil? # "It hurt itself in its confusion!"
        @battle.pbDisplay("It was super effective!") if superEff
        confusionMove.pbRecordDamageLost(self, self)
        confusionMove.pbEndureKOMessage(self)
        pbHealthLossChecks(oldHP)
    end

    # If there's an effect that causes damage before a move is used
    # This deals with the possible ramifications of that
    def cleanupPreMoveDamage(user, oldHP)
        user.pbFaint if user.fainted?
        @battle.pbGainExp # In case user is KO'd by this
        user.pbItemHPHealCheck
        user.pbEffectsOnSwitchIn(true) if user.pbAbilitiesOnDamageTaken(oldHP)
    end

    #=============================================================================
    # Simple "use move" method, used when a move calls another move and for Future
    # Sight's attack
    #=============================================================================
    def pbUseMoveSimple(moveID, target = -1, idxMove = -1, specialUsage = true)
        choice = []
        choice[0] = :UseMove   # "Use move"
        choice[1] = idxMove    # Index of move to be used in user's moveset
        if idxMove >= 0
            choice[2] = @moves[idxMove]
        else
            choice[2] = PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(moveID))
            choice[2].pp = -1
            if @battle.futureSight && target >= 0 && @battle.positions[target].effectActive?(:FutureSightType)
                choice[2].type = @battle.positions[target].effects[:FutureSightType]
            end
        end
        choice[3] = target     # Target (-1 means no target yet)
        choice[4] = 0
        PBDebug.log("[Move usage] #{pbThis} started using the called/simple move #{choice[2].name}")
        pbUseMove(choice, specialUsage)
    end

    #=============================================================================
    # Master "use move" method
    #=============================================================================
    def pbUseMove(choice, specialUsage = false)
        # NOTE: This is intentionally determined before a multi-turn attack can
        #       set specialUsage to true.
        skipAccuracyCheck = (specialUsage && choice[2] != @battle.struggle)

        # Start using the move
        pbBeginTurn(choice)

        # Force the use of certain moves if they're already being used
        unless specialUsage || @battle.futureSight || (choice[2]&.empoweredMove? && boss?)
            if usingMultiTurnAttack? && !@currentMove.nil?
                choice[2] = PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(@currentMove))
                specialUsage = true
            elsif effectActive?(:Encore) && choice[1] >= 0 && @battle.pbCanShowCommands?(@index)
                idxEncoredMove = pbEncoredMoveIndex
                if idxEncoredMove >= 0 && @battle.pbCanChooseMove?(@index, idxEncoredMove, false) && (choice[1] != idxEncoredMove) # Change move if battler was Encored mid-round
                    choice[1] = idxEncoredMove
                    choice[2] = @moves[idxEncoredMove]
                    choice[3] = -1 # No target chosen
                end
            end
        end

        # Labels the move being used as "move"
        move = choice[2]

        # if move was not chosen somehow
        return unless move

        # Try to use the move (inc. disobedience)
        @lastMoveFailed = false
        unless pbTryUseMove(move, specialUsage, skipAccuracyCheck)
            trackMoveUsage
            @battle.pbGainExp # In case self is KO'd due to confusion
            pbCancelMoves
            pbEndTurn(choice)
            return
        end
        move = choice[2] # In case disobedience changed the move to be used

        return unless move # if move was not chosen somehow

        # Make extra move choices
        move.resolutionChoice(self)

        # Subtract PP
        if !specialUsage && !pbReducePP(move)
            @battle.pbDisplay(_INTL("{1} used {2}!", pbThis, move.name))
            @battle.pbDisplay(_INTL("But there was no PP left for the move!"))
            trackMoveUsage
            pbCancelMoves
            pbEndTurn(choice)
            return
        end

        # Stance Change
        if isSpecies?(:AEGISLASH) && hasAbility?(:STANCECHANGE)
            if move.damagingMove?
                if @form != 1
                    @battle.pbCommonAnimation("StanceAttack", self)
                    pbChangeForm(1, _INTL("{1} changed to Blade Forme!", pbThis))
                end
            elsif move.id == :KINGSSHIELD
                if @form != 0
                    @battle.pbCommonAnimation("StanceProtect", self)
                    pbChangeForm(0, _INTL("{1} changed to Shield Forme!", pbThis))
                end
            end
        end

        # Calculate usage overrides
        presumedUser = pbFindUser(choice, move)
        presumedTargets = pbFindTargets(choice[3], move, presumedUser)
        move.calculateUsageOverrides(presumedUser,presumedTargets)

        # Start effect of Mold Breaker
        @battle.moldBreaker = hasMoldBreaker?

        # Remember that user chose a two-turn move
        if move.pbIsChargingTurn?(self)
            # Beginning the use of a two-turn attack
            applyEffect(:TwoTurnAttack, move.id)
            @currentMove = move.id
        else
            # Cancel use of two-turn attack
            disableEffect(:TwoTurnAttack)
        end

        # Add to counters for moves which increase them when used in succession
        move.pbChangeUsageCounters(self, specialUsage)
        # Charge up Metronome item
        if hasActiveItem?(:METRONOME) && !move.callsAnotherMove?
            if @lastMoveUsed && @lastMoveUsed == move.id && !@lastMoveFailed
                incrementEffect(:Metronome)
            else
                disableEffect(:Metronome)
            end
        end

        # Record move as having been used
        aiSeesMove(move) if pbOwnedByPlayer? && !boss? # Enemy trainers now know of this move's existence
        aiLearnsAbility(:ILLUSION) if hasActiveAbility?(:ILLUSION) && effectActive?(:Illusion)
        aiLearnsAbility(:INCOGNITO) if hasActiveAbility?(:INCOGNITO) && effectActive?(:Illusion)
        increaseMoveUsageCount(move.id)

        trackMoveUsage(move: move,specialUsage: specialUsage, target: choice[3])

        # For Cross Examine and such
        if opposes?
            @battle.allMovesUsedSide1.push(move.id)
        else
            @battle.allMovesUsedSide0.push(move.id)
        end
        @battle.successStates[@index].useState = 1 # Battle Arena - assume failure
        @empoweredTimer = 0 if move.empoweredMove?

        # Find the default user (self or Snatcher) and target(s)
        user = pbFindUser(choice, move)
        user = pbChangeUser(choice, move, user)
        targets = pbFindTargets(choice[3], move, user)
        targets = pbChangeTargets(move, user, targets)

        # Global move disruption effects
        unless move.empoweredMove? && boss?
            # Pressure
            unless specialUsage
                targets.each do |b|
                    next unless b.opposes?(user) && b.hasActiveAbility?(:PRESSURE)
                    user.pbReducePP(move)
                end
                if move.pbTarget(user).affects_foe_side
                    @battle.eachOtherSideBattler(user) do |b|
                        next unless b.hasActiveAbility?(:PRESSURE)
                        user.pbReducePP(move)
                    end
                end
            end
            # Move blocking abilities make the move fail here
            @battle.pbPriority(true).each do |b|
                next unless b
                b.eachActiveAbility do |ability|
                    next unless BattleHandlers.triggerMoveBlockingAbility(ability, b, user, targets, move, @battle, false)
                    @battle.pbDisplayBrief(_INTL("{1} tried to use {2}!", user.pbThis, move.name))
                    @battle.pbShowAbilitySplash(b, ability)
                    @battle.pbDisplay(_INTL("But, {1} cannot use {2}!", user.pbThis, move.name))
                    @battle.pbHideAbilitySplash(b)
                    user.onMoveFailed(move)
                    pbCancelMoves
                    pbEndTurn(choice)
                    return
                end
            end
        end
        
        # "X used Y!" message
        # Can be different for Bide, Fling, Focus Punch and Future Sight
        # NOTE: This intentionally passes self rather than user. The user is always
        #       self except if Snatched, but this message should state the original
        #       user (self) even if the move is Snatched.
        @battle.triggerBattlerIsUsingMoveDialogue(user, targets, move)
        move.pbDisplayUseMessage(self, targets)
        # Snatch's message (user is the new user, self is the original user)
        if move.snatched
            onMoveFailed(move) # Intentionally applies to self, not user
            @battle.pbDisplay(_INTL("{1} snatched {2}'s move!", user.pbThis, pbThis(true)))
        end
        # "But it failed!" checks
        if move.pbMoveFailed?(user, targets, true)
            PBDebug.log(format("[Move failed] In function code %s's def pbMoveFailed?", move.function))
            user.onMoveFailed(move)
            move.moveFailed(user, targets)
            pbCancelMoves
            pbEndTurn(choice)
            return
        end
        # "But it failed!" checks, when the move is not a special usage
        if !specialUsage && move.pbMoveFailedNoSpecial?(user, targets)
            PBDebug.log(format("[Move failed] In function code %s's def pbMoveFailedNoSpecial?", move.function))
            user.onMoveFailed(move)
            pbCancelMoves
            pbEndTurn(choice)
            return
        end

        # Perform set-up actions
        move.pbOnStartUse(user, targets)

        # Display messages about BP adjustment and weather debuffing
        move.displayDamagingMoveMessages(self, move, targets) if move.damagingMove?
        
        # Primordial Sea, Desolate Land
        if move.damagingMove?
            case @battle.pbWeather
            when :HeavyRain
                if move.calcType == :FIRE
                    @battle.pbDisplay(_INTL("The Fire-type attack fizzled out in the heavy rain!"))
                    user.onMoveFailed(move)
                    pbCancelMoves
                    pbEndTurn(choice)
                    return
                end
            when :HarshSun
                if move.calcType == :WATER
                    @battle.pbDisplay(_INTL("The Water-type attack evaporated in the harsh sunlight!"))
                    user.onMoveFailed(move)
                    pbCancelMoves
                    pbEndTurn(choice)
                    return
                end
            end
        end
        
        # Abilities that trigger before a move starts
        # E.g. Protean
        user.eachActiveAbility do |ability|
            BattleHandlers.triggerUserAbilityStartOfMove(ability, user, targets, move, @battle)
        end

        #---------------------------------------------------------------------------
        magicCoater  = -1
        magicBouncer = -1
        magicShielder = -1
        if targets.length == 0 && move.pbTarget(user).num_targets > 0 && !move.worksWithNoTargets?
            # def pbFindTargets should have found a target(s), but it didn't because
            # they were all fainted
            # All target types except: None, User, UserSide, FoeSide, BothSides
            @battle.pbDisplay(_INTL("But there was no target..."))
            user.onMoveFailed(move)
        else # We have targets, or move doesn't use targets
            # Reset whole damage state, perform various success checks (not accuracy)
            user.initialHP = user.hp
            targets.each do |b|
                b.damageState.reset
                b.damageState.initialHP = b.hp

                typeMod = move.pbCalcTypeMod(move.calcType, user, b)
                b.damageState.typeMod = typeMod

                showFailMessages = move.pbShowFailMessages?(targets)
                unless pbSuccessCheckAgainstTarget(move, user, b, typeMod, showFailMessages)
                    b.damageState.unaffected = true
                    user.onMoveFailed(move)
                end
            end
            # Magic Coat/Magic Bounce/Magic Shield checks (for moves which don't target Pokémon)
            if targets.empty? && move.canMagicCoat?
                @battle.pbPriority(true).each do |b|
                    next if b.fainted? || !b.opposes?(user)
                    next if b.semiInvulnerable?
                    if b.effectActive?(:MagicCoat)
                        magicCoater = b.index
                        b.disableEffect(:MagicCoat)
                        break
                    elsif b.effectActive?(:EmpoweredMagicCoat)
                        magicCoater = b.index
                        break
                    elsif b.hasActiveAbility?(:MAGICBOUNCE) && !@battle.moldBreaker
                        magicBouncer = b.index
                        b.applyEffect(:MagicBounce)
                        break
                    elsif b.hasActiveAbility?(:MAGICSHIELD) && !@battle.moldBreaker
                        magicShielder = b.index
                        @battle.pbShowAbilitySplash(b, :MAGICSHIELD)
                        @battle.pbDisplay(_INTL("{1} shielded its side from the {2}!", b.pbThis, move.name))
                        @battle.pbHideAbilitySplash(b)
                        user.onMoveFailed(move)
                        break
                    end
                end
            end
            # Quarantine (for moves which target the whole side)
            quarantined = false
            if targets.empty? && user.pbOpposingSide.effectActive?(:Quarantine)
                @battle.pbDisplay(_INTL("{1} was blocked by the quarantine!", move.name))
                user.onMoveFailed(move)
                user.applyEffect(:Disable,3) if user.canBeDisabled?(true,move)
                quarantined = true
            end
            # The target's abilities that trigger on the start of the move
            targets.each do |target|
                next if target.damageState.unaffected
                target.eachActiveAbility do |ability|
                    BattleHandlers.triggerTargetAbilityStartOfMove(ability, user, target, move, @battle)
                end
            end
            # Get the number of hits
            numHits = move.numberOfHits(user, targets)
            # Mark each target with whether its being targeted by a multihit move
            multiHitAesthetics = numHits > 1 || move.pbRepeatHit?
            targets.each do |target|
                target.damageState.messagesPerHit = !multiHitAesthetics
            end
            # Record that Parental Bond applies, to weaken the second attack
            user.applyEffect(:ParentalBond, 3) if move.canParentalBond?(user, targets)
            # Process each hit in turn
            # Skip all hits if the move is being magic coated, magic bounced, or magic shielded
            realNumHits = 0
            moveIsBlocked = magicCoater >= 0 || magicBouncer >= 0 || magicShielder >= 0 || quarantined
            unless moveIsBlocked
                for i in 0...numHits
                    success = pbProcessMoveHit(move, user, targets, i, skipAccuracyCheck, multiHitAesthetics)
                    unless success
                        if i == 0 && targets.length > 0
                            hasFailed = false
                            targets.each do |t|
                                next if t.damageState.protected
                                hasFailed = t.damageState.unaffected
                                break unless t.damageState.unaffected
                            end
                            user.lastMoveFailed = hasFailed
                        end
                        break
                    end
                    realNumHits += 1
                    break if user.fainted?
                    break if user.asleep?
                    # NOTE: If a multi-hit move becomes disabled partway through doing those
                    #       hits (e.g. by Cursed Body), the rest of the hits continue as
                    #       normal.
                    break unless targets.any? { |t| !t.fainted? } # All targets are fainted
                end
            end
            # Battle Arena only - attack is successful
            @battle.successStates[user.index].useState = 2
            if targets.length > 0
                @battle.successStates[user.index].typeMod = 0
                targets.each do |b|
                    next if b.damageState.unaffected
                    @battle.successStates[user.index].typeMod += b.damageState.typeMod
                end
            end
            # Effectiveness message for multi-hit moves
            if multiHitAesthetics
                if move.damagingMove?
                    targets.each do |b|
                        next if b.damageState.unaffected || b.damageState.substitute
                        move.pbEffectivenessMessage(user, b, targets.length)
                    end
                end
                if numHits > 1
                    if targets.length > 1
                        if realNumHits == 1
                            @battle.pbDisplay(_INTL("Hit each 1 time!"))
                        elsif realNumHits > 1
                            @battle.pbDisplay(_INTL("Hit each {1} times!", realNumHits))
                        end
                    elsif realNumHits == 1
                        @battle.pbDisplay(_INTL("Hit 1 time!"))
                    elsif realNumHits > 1
                        @battle.pbDisplay(_INTL("Hit {1} times!", realNumHits))
                    end
                end
            end
            # Fear save message
            if move.damagingMove?
                targets.each do |b|
                    next unless b.damageState.fear
                    @battle.pbDisplay(_INTL("{1} showed mercy on {2}!", user.pbThis, b.pbThis(true))) if $Options.avatar_mechanics_messages == 0
                    b.pokemon.becomeAfraid
                end
            end
            # Magic Coat/Magic Bounce's bouncing back (move has targets)
            targets.each do |b|
                next if b.fainted?
                next if !b.damageState.magicCoat && !b.damageState.magicBounce
                @battle.pbShowAbilitySplash(b, :MAGICBOUNCE) if b.damageState.magicBounce
                @battle.pbDisplay(_INTL("{1} bounced the {2} back!", b.pbThis, move.name))
                @battle.pbHideAbilitySplash(b) if b.damageState.magicBounce
                newTargets = pbFindTargets(user.index, move, b)
                newTargets = pbChangeTargets(move, b, newTargets)

                # Check to see if the bounced move should fail
                success = false
                unless move.pbMoveFailed?(b, newTargets, true)
                    newTargets.each_with_index do |newTarget, idx|
                        typeMod = move.pbCalcTypeMod(move.calcType, user, b)
                        b.damageState.typeMod = typeMod

                        showFailMessages = move.pbShowFailMessages?(targets)
                        if pbSuccessCheckAgainstTarget(move, b, newTarget, typeMod, showFailMessages)
                            success = true
                            next
                        end
                        newTargets[idx] = nil
                    end
                    newTargets.compact!
                end
                pbProcessMoveHit(move, b, newTargets, 0, false, multiHitAesthetics) if success

                b.onMoveFailed(move) unless success
                targets.each { |otherB| otherB.pbFaint if otherB && otherB.fainted? }
                user.pbFaint if user.fainted?
            end
            # Magic Coat/Magic Bounce's bouncing back (move has no targets)
            if magicCoater >= 0 || magicBouncer >= 0
                mc = @battle.battlers[(magicCoater >= 0) ? magicCoater : magicBouncer]
                unless mc.fainted?
                    user.onMoveFailed(move)
                    @battle.pbShowAbilitySplash(mc, :MAGICBOUNCE) if magicBouncer >= 0
                    @battle.pbDisplay(_INTL("{1} bounced the {2} back!", mc.pbThis, move.name))
                    @battle.pbHideAbilitySplash(mc) if magicBouncer >= 0
                    success = false
                    unless move.pbMoveFailed?(mc, [], true)
                        success = pbProcessMoveHit(move, mc, [], 0, false, multiHitAesthetics)
                    end
                    mc.onMoveFailed(move) unless success
                    targets.each { |b| b.pbFaint if b && b.fainted? }
                    user.pbFaint if user.fainted?
                end
            end
            # Move-specific effects after all hits
            targets.each do |targetBattler|
                move.pbEffectAfterAllHits(user, targetBattler)
                move.pbEffectOnNumHits(user, targetBattler, realNumHits)

                # Empowered Destiny Bond
                if targetBattler.effectActive?(:EmpoweredDestinyBond) && targetBattler.damageState.totalHPLost > 0 
                    recoilDamage = targetBattler.damageState.totalHPLost / 3.0
                    recoilMessage = _INTL("{1}'s destiny is bonded with {2}!", user.pbThis, targetBattler.pbThis(true))
                    user.applyRecoilDamage(recoilDamage, false, true, recoilMessage)
                end
            end

            # Curses about move usage
            @battle.curses.each do |curse_policy|
                @battle.triggerMoveUsedCurseEffect(curse_policy, self, choice[3], move)
            end

            # Triggers dialogue for each target hit
            targets.each do |t|
                next unless t.damageState.totalHPLost > 0
                @battle.triggerBattlerTookMoveDamageDialogue(user, t, move)
            end

            # Faint if 0 HP
            targets.each { |b| b.pbFaint if b && b.fainted? }
            user.pbFaint if user.fainted?

            # External/general effects after all hits. Eject Button, Shell Bell, etc.
            pbEffectsAfterMove(user, targets, move, realNumHits)
        end

        # End effect of Mold Breaker
        @battle.moldBreaker = false
        # Gain Exp
        @battle.pbGainExp
        # Battle Arena only - update skills
        @battle.eachBattler { |b| @battle.successStates[b.index].updateSkill }
        # Refresh the scene to account for changes to pokemon status
        @battle.scene.pbRefresh
        # End of move usage
        pbEndTurn(choice)

        moveSucceeded = !user.lastMoveFailed && realNumHits > 0 && !move.snatched && magicCoater < 0
        postMoveUseTriggers(user, move, targets, choice, moveSucceeded)
    end

    # If move is nil, move usage was failed
    def trackMoveUsage(move: nil, specialUsage: false, target: nil)
        if move.nil?
            @lastMoveUsed = nil
            @lastMoveUsedType = nil
            @lastMoveUsedCategory = -1

            unless specialUsage
                @lastRegularMoveUsed   = nil
                @lastRegularMoveTarget = -1
                @lastMoveFailed        = true
            end
        else
            @lastMoveUsed     = move.id
            @lastMoveUsedType = move.calcType # For Conversion 2
            @lastMoveUsedCategory = move.calculatedCategory
            
            @usedDamagingMove = true if move.damagingMove?
            unless specialUsage
                @lastRegularMoveUsed = move.id # For Disable, Encore, Instruct, Mimic, Mirror Move, Sketch, Spite
                @lastRegularMoveTarget = target # For Instruct (remembering original target is fine)
                @movesUsed.push(move.id) unless @movesUsed.include?(move.id) # For Last Resort
            end
            @battle.lastMoveUsed = move.id # For Copycat
            @battle.lastMoveUser = @index # For "self KO" battle clause to avoid draws
        end

        @moveUsageHistory.unshift(move.nil? ? nil : move.id) # Push to front of array
    end

    def postMoveUseTriggers(user, move, targets, choice, moveSucceeded)
        # Abilities that trigger from being in the presence of a successful move
        @battle.pbPriority(true).each do |b|
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAnyoneAbilityEndOfMove(ability, b, user, targets, move, @battle)
            end
        end
        # Instruct
        @battle.eachBattler do |b|
            next if !b.effectActive?(:Instruct) || !b.lastMoveUsed
            b.disableEffect(:Instruct)
            # Don't force the move if the pokemon somehow no longer has that move
            moveIndex = -1
            b.eachMoveWithIndex do |m, i|
                moveIndex = i if m.id == b.lastMoveUsed
            end
            next if moveIndex < 0
            moveID = b.lastMoveUsed
            usageMessage = _INTL("{1} used the move instructed by {2}!", b.pbThis, user.pbThis(true))
            preTarget = b.lastRegularMoveTarget
            @battle.forceUseMove(b, moveID, preTarget, false, usageMessage, moveUsageEffect: :Instructed)
        end
        if moveSucceeded
            # Dancer
            if !effectActive?(:Dancer) && move.danceMove?
                dancers = []
                @battle.pbPriority(true).each do |b|
                    dancers.push(b) if b.index != user.index && b.hasActiveAbility?(:DANCER)
                end
                while dancers.length > 0
                    nextUser = dancers.pop
                    preTarget = choice[3]
                    preTarget = user.index if nextUser.opposes?(user) || !nextUser.opposes?(preTarget)
                    @battle.forceUseMove(nextUser, move.id, preTarget, moveUsageEffect: :Dancer, ability: :DANCER)
                end
            end
            # Echo
            if !effectActive?(:Echo) && (move.soundMove? || move.pulseMove?)
                echoers = []
                @battle.pbPriority(true).each do |b|
                    echoers.push(b) if b.index != user.index && b.hasActiveAbility?(:ECHO)
                end
                while echoers.length > 0
                    nextUser = echoers.pop
                    preTarget = choice[3]
                    preTarget = user.index if nextUser.opposes?(user) || !nextUser.opposes?(preTarget)
                    @battle.forceUseMove(nextUser, move.id, preTarget, moveUsageEffect: :Echo, ability: :ECHO)
                end
            end
            # Martial Discipline
            if !effectActive?(:MartialDiscipline) && (move.punchingMove? || move.kickingMove?)
                discipliners = []
                @battle.pbPriority(true).each do |b|
                    discipliners.push(b) if b.index != user.index && b.hasActiveAbility?(:MARTIALDISCIPLINE)
                end
                while discipliners.length > 0
                    nextUser = discipliners.pop
                    preTarget = choice[3]
                    preTarget = user.index if nextUser.opposes?(user) || !nextUser.opposes?(preTarget)
                    @battle.forceUseMove(nextUser, move.id, preTarget, moveUsageEffect: :MartialDiscipline, ability: :MARTIALDISCIPLINE)
                end
            end
        end
    end

    #=============================================================================
    # Attack a single target
    #=============================================================================
    def pbProcessMoveHit(move, user, targets, hitNum, skipAccuracyCheck, fastHitAnimation = false)
        return false if user.fainted? && !user.dummy?
        # For two-turn attacks being used in a single turn
        move.pbInitialEffect(user, targets, hitNum)
        numTargets = 0 # Number of targets that are affected by this hit
        # Count a hit for Parental Bond (if it applies)
        user.tickDownAndProc(:ParentalBond)
        # Accuracy check (accuracy/evasion calc)
        if hitNum == 0 || move.successCheckPerHit?
            targets.each do |b|
                b.damageState.missed = false
                next if b.damageState.unaffected
                if skipAccuracyCheck || pbSuccessCheckPerHit(move, user, b)
                    numTargets += 1
                else
                    b.damageState.missed = true
                    b.damageState.unaffected = true
                end
            end
            # If failed against all targets
            if targets.length > 0 && numTargets == 0 && !move.worksWithNoTargets?
                targets.each do |b|
                    next if !b.damageState.missed || b.damageState.magicCoat
                    pbMissMessage(move, user, b)
                    break if move.pbRepeatHit? # Dragon Darts only shows one failure message
                end
                move.pbCrashDamage(user)
                move.pbAllMissed(user, targets)
                user.pbItemHPHealCheck
                pbCancelMoves
                return false
            end
        end
        # If we get here, this hit will happen and do something
        all_targets = targets
        targets = move.pbDesignateTargetsForHit(targets, hitNum) # For Dragon Darts
        targets.each { |b| b.damageState.resetPerHit }
        # Tracked whether the Pokemon is trapped
        targets.each { |b|
            next unless b.trapped?
            b.damageState.trapped = true
        }
        #---------------------------------------------------------------------------
        # Pre effects
        if move.damagingMove?
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbEffectBeforeDealingDamage(user, b)
            end
        end
        #---------------------------------------------------------------------------
        # Calculate damage to deal
        if move.damagingMove?
            targets.each do |b|
                next if b.damageState.unaffected
                # Check whether Substitute/Disguise will absorb the damage
                move.pbCheckDamageAbsorption(user, b)
                # Calculate the damage against b
                # pbCalcDamage shows the "eat berry" animation for SE-weakening
                # berries, although the message about it comes after the additional
                # effect below
                move.pbCalcDamage(user, b, targets.length) # Stored in damageState.calcDamage
                # Lessen damage dealt because of False Swipe/Endure/etc.
                move.pbReduceDamage(user, b) # Stored in damageState.hpLost
                # Track the total damage calculated
                b.damageState.totalCalcedDamage += b.damageState.displayedDamage
            end
        end
        # Show move animation (for this hit)
        move.pbShowAnimation(move.id, user, targets, hitNum) if hitNum == 0
        # Type-boosting Gem consume animation/message
        if effectActive?(:GemConsumed) && hitNum == 0
            # NOTE: The consume animation and message for Gems are shown now, but the
            #       actual removal of the item happens in def pbEffectsAfterMove.
            @battle.pbCommonAnimation("UseItem", user)
            if user.hasTribeBonus?(:SCAVENGER)
                @battle.pbShowTribeSplash(user,:SCAVENGER)
                @battle.pbDisplay(_INTL("The {1} majorly strengthened {2}'s power!", getItemName(user.effects[:GemConsumed]), move.name))
                @battle.pbHideTribeSplash(user)
            else
                @battle.pbDisplay(_INTL("The {1} strengthened {2}'s power!", getItemName(user.effects[:GemConsumed]), move.name))
            end
            aiLearnsItem(user.effects[:GemConsumed])
        end
        # Attack/Sp. Atk boosting Herb consume animation/message
        if effectActive?(:EmpoweringHerbConsumed) && hitNum == 0
            # NOTE: The consume animation and message for Herbs are shown now, but the
            #       actual removal of the item happens in def pbEffectsAfterMove.
            @battle.pbCommonAnimation("UseItem", user)
            @battle.pbDisplay(_INTL("The {1} supplemented {2}'s power!", getItemName(user.effects[:EmpoweringHerbConsumed]), move.name))
            aiLearnsItem(user.effects[:EmpoweringHerbConsumed])
        end
        # Accuracy ensuring Herb consume animation/message
        if effectActive?(:SkillHerbConsumed) && hitNum == 0
            # NOTE: The consume animation and message for Herbs are shown now, but the
            #       actual removal of the item happens in def pbEffectsAfterMove.
            @battle.pbCommonAnimation("UseItem", user)
            @battle.pbDisplay(_INTL("The {1} ensured {2} would hit!", getItemName(:SKILLHERB), move.name))
            aiLearnsItem(:SKILLHERB)
        end
        # Mystic tribe
        if hasTribeBonus?(:MYSTIC) && user.lastRoundMoveCategory == 2 && move.damagingMove? # Status
            @battle.pbShowTribeSplash(user,:MYSTIC)
            @battle.pbDisplay(_INTL("{1}'s patience pays off!", user.pbThis))
            @battle.pbHideTribeSplash(user)
        end
        # Energy Charge expended message
        if user.effectActive?(:EnergyChargeExpended) && hitNum == 0
            @battle.pbDisplay(_INTL("{1} used its energy to empower {2}!", user.pbThis, move.name))
        end
        # Bubble Barrier proc message
        targets.each do |b|
            next unless b.damageState.bubbleBarrier > 0
            @battle.pbDisplay(_INTL("The bubble surrounding {1} reduced the damage!", b.pbThis))
        end
        # Messages about missed target(s) (relevant for multi-target moves only)
        unless move.pbRepeatHit?
            targets.each do |b|
                next unless b.damageState.missed
                pbMissMessage(move, user, b)
            end
        end
        # Deal the damage (to all allies first simultaneously, then all foes
        # simultaneously)
        if move.damagingMove?
            # This just changes the HP amounts and does nothing else
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbInflictHPDamage(b)
            end

            # Deal X damage achievements
            maxDamageOnTargets = 0
            targets.each do |b|
                damageDisplayed = b.damageState.displayedDamage.round
                maxDamageOnTargets = damageDisplayed if damageDisplayed > maxDamageOnTargets
            end

            # Animate the hit flashing and HP bar changes
            move.pbAnimateHitAndHPLost(user, targets, fastHitAnimation)

            if pbOwnedByPlayer?
                unlockAchievement(:DEAL_LARGE_DAMAGE_1) if maxDamageOnTargets >= 1000
                unlockAchievement(:DEAL_LARGE_DAMAGE_2) if maxDamageOnTargets >= 10_000
            end
        end
        # Self-Destruct/Explosion's damaging and fainting of user
        move.pbSelfKO(user) if hitNum == 0 && !@battle.autoTesting
        user.pbFaint if user.fainted?
        if move.damagingMove?
            targets.each do |b|
                next if b.damageState.unaffected
                # NOTE: This method is also used for the OKHO special message.
                move.pbHitEffectivenessMessages(user, b, targets.length)
                # Record data about the hit for various effects' purposes
                move.pbRecordDamageLost(user, b)
            end
            # Close Combat/Superpower's stat-lowering, Flame Burst's splash damage,
            # and Incinerate's berry destruction
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbEffectWhenDealingDamage(user, b)
            end
            # Ability/item effects such as Static/Rocky Helmet, and Grudge, etc.
            targets.each do |b|
                next if b.damageState.unaffected
                pbEffectsOnMakingHit(move, user, b)
            end
            # Disguise/Endure/Sturdy/Focus Sash/Focus Band messages
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbEndureKOMessage(b)
            end
            # Endure-style move activations
            targets.each do |b|
                next unless b.damageState.fightforever
                b.tryRaiseStat(:ATTACK, user, increment: 2)
            end

            # HP-healing held items (checks all battlers rather than just targets
            # because Flame Burst's splash damage affects non-targets)
            @battle.pbPriority(true).each { |b| b.pbItemHPHealCheck }

            # Animate battlers fainting (checks all battlers rather than just targets
            # because Flame Burst's splash damage affects non-targets)
            @battle.pbPriority(true).each { |b| b.pbFaint if b && b.fainted? }
        else
            if !user.poisoned?
                # Secretion Secret
                targets.each do |target|
                    next if target.damageState.unaffected
                    next unless target.hasActiveAbility?(:SECRETIONSECRET) && user.opposes?(target)
                    battle.pbShowAbilitySplash(target, :SECRETIONSECRET)
                    user.applyPoison(target, nil) if user.canPoison?(target, true)
                    battle.pbHideAbilitySplash(target)
                end
            end

            # Single targeted status move
            if targets.length == 1 && user.opposes?(targets[0]) && !targets[0].damageState.unaffected
                target = targets[0]

                # Unassuming
                if user.hasActiveAbility?(:UNASSUMING)
                    target.tryLowerStat(:DEFENSE, user, move: move, showFailMsg: true, ability: :UNASSUMING, increment: 2)
                end

                # Recon
                if user.hasActiveAbility?(:RECON)
                    target.tryLowerStat(:SPECIAL_DEFENSE, user, move: move, showFailMsg: true, ability: :RECON, increment: 2)
                end
            end
        end
        @battle.pbJudgeCheckpoint(user, move)
        # Main effect (recoil/drain, etc.)
        targets.each do |b|
            next if b.damageState.unaffected
            move.pbEffectAgainstTarget(user, b)
        end
        move.pbEffectGeneral(user)
        # use this until the field change method applies to all field changes
        @battle.eachBattler do |b|
            b.pbItemFieldEffectCheck
        end
        targets.each { |b| b.pbFaint if b && b.fainted? }
        user.pbFaint if user.fainted?
        # Guarenteed added effects
        if move.guaranteedEffect?
            targets.each do |b|
                next if b.damageState.calcDamage == 0
                move.pbAdditionalEffect(user, b)
            end
        elsif move.randomEffect? && !user.hasActiveAbility?(:SHEERFORCE) # Random added effects
            targets.each do |b|
                next if b.damageState.calcDamage == 0
                chance = move.pbAdditionalEffectChance(user, b, move.calcType)
                next if chance <= 0
                if @battle.pbRandom(100) < chance && move.canApplyRandomAddedEffects?(user,b,true)
                    if b.hasActiveAbility?(:UNCANNYLUCK)
                        b.showMyAbilitySplash(:UNCANNYLUCK)
                        @battle.pbDisplay(_INTL("{1}'s additional effect was bounced back!", move.name))
                        move.pbAdditionalEffect(user, user)
                        b.hideMyAbilitySplash
                    else
                        move.pbAdditionalEffect(user, b)
                    end
                end
            end
            # Additional effect ensuring Herb consume animation/message
            if effectActive?(:LuckHerbConsumed) && hitNum == 0
                # NOTE: The consume animation and message for Herbs are shown now, but the
                #       actual removal of the item happens in def pbEffectsAfterMove.
                @battle.pbCommonAnimation("UseItem", user)
                @battle.pbDisplay(_INTL("The {1} ensured {2}'s additional effect!", getItemName(:LUCKHERB), move.name))
                aiLearnsItem(:LUCKHERB)
            end
        end
        # Make the target flinch (because of an item/ability)
        targets.each do |b|
            next if b.fainted?
            next if b.damageState.calcDamage == 0 || b.damageState.substitute
            chance = move.pbFlinchChance(user, b)
            next if chance <= 0
            next unless @battle.pbRandom(100) < chance
            PBDebug.log("[Item/ability triggered] #{user.pbThis}'s King's Rock/Razor Fang or Stench")
            next unless move.canApplyRandomAddedEffects?(user, b, true)
            b.pbFlinch
        end
        # Message for and consuming of type-weakening berries
        # NOTE: The "consume held item" animation for type-weakening berries occurs
        #       during pbCalcDamage above (before the move's animation), but the
        #       message about it only shows here.
        targets.each do |b|
            next if b.damageState.unaffected
            itemTriggered = b.damageState.berryWeakened || b.damageState.feastWeakened
            next unless itemTriggered
            name = GameData::Item.get(itemTriggered).name
            @battle.pbDisplay(_INTL("The {1} weakened the damage to {2}!", name, b.pbThis(true)))
            b.pbHeldItemTriggered(itemTriggered) if b.hasItem?(itemTriggered) && b.damageState.berryWeakened
        end
        targets.each { |b| b.pbFaint if b && b.fainted? }
        user.pbFaint if user.fainted?
        # Dragon Darts' second half of attack
        if move.pbRepeatHit?(hitNum) && all_targets.any? { |b| !b.fainted? && !b.damageState.unaffected }
            pbProcessMoveHit(move, user, all_targets, hitNum + 1, skipAccuracyCheck, fastHitAnimation)
        end
        return true
    end
end
