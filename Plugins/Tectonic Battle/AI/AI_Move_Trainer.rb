class PokeBattle_AI
    def pbChooseMovesTrainer(idxBattler, choices)
        user = @battle.battlers[idxBattler]
        owner = @battle.pbGetOwnerFromBattlerIndex(user.index)
        policies = owner.policies || []

        # Log the available choices
        logMoveChoices(user, choices)

        # If there are valid choices, pick among them
        if choices.length > 0
            # Determine the most preferred move
            sortedChoices = choices.sort_by { |choice| -choice[1] }
            preferredChoice = sortedChoices[0]
            PBDebug.log("[AI] #{user.pbThis} (#{user.index}) thinks #{user.getMoves[preferredChoice[0]].name} is the highest rated choice")
            unless preferredChoice.nil?
                @battle.pbRegisterMove(idxBattler, preferredChoice[0], false)
                @battle.pbRegisterTarget(idxBattler, preferredChoice[2]) if preferredChoice[2] >= 0
            end
        else # If there are no calculated choices, create a list of the choices all scored the same, to be chosen between randomly later on
            PBDebug.log("[AI] #{user.pbThis} (#{user.index}) scored no moves above a zero, resetting all choices to default")
            user.eachMoveWithIndex do |m, i|
                next unless @battle.pbCanChooseMove?(user, i, false)
                next if m.empoweredMove?
                choices.push([i, 100, -1]) # Move index, score, target
            end
            if choices.length == 0 # No moves are physically possible to use; use Struggle
                @battle.pbAutoChooseMove(user.index)
            end
        end

        # if there is somehow still no choice, randomly choose a move from the choices and register it
        if @battle.choices[idxBattler][2].nil?
            echoln("All AI protocols have failed or fallen through, picking at random.")
            randomChoice = choices.sample
            @battle.pbRegisterMove(idxBattler, randomChoice[0], false)
            @battle.pbRegisterTarget(idxBattler, randomChoice[2]) if randomChoice[2] >= 0
        end

        # Log the result
        if @battle.choices[idxBattler][2]
            user.lastMoveChosen = @battle.choices[idxBattler][2].id
            PBDebug.log("[AI] #{user.pbThis} (#{user.index}) will use #{@battle.choices[idxBattler][2].name}")
        end
    end

    # Returns an array filled with each move that has a target worth using against
    # Giving also the best target to use the move against and the score of doing so
    def pbGetBestTrainerMoveChoices(user, opposingBattler: nil, killInfoArray: [])
        choices = []
        bestKillInfo = nil
        urgency = 0
        urgency = user.getUrgency if !user.pbOwnedByPlayer?
        slowerDead = false
        fasterDead = false
        user.eachAIKnownMoveWithIndex do |move, i|
            next unless @battle.pbCanChooseMove?(user, i, false)
            targets = []
            targets.push(opposingBattler) if opposingBattler
            newChoice,killInfo,isSlowerDead,isFasterDead = pbEvaluateMoveTrainer(user, move, targets: targets, killInfoArray: killInfoArray)
            
            # If the move would kill the opposing battler, mark as such
            # But only if its better than any kill seen thus far
            if killInfo && opposingBattler
                if bestKillInfo
                    if killInfo.priority > bestKillInfo.priority
                        bestKillInfo = killInfo
                    elsif killInfo.priority == bestKillInfo.priority && killInfo.speed > bestKillInfo.speed
                        bestKillInfo = killInfo
                    elsif killInfo.score == bestKillInfo.score
                        bestKillInfo = killInfo
                    end
                else
                    bestKillInfo = killInfo
                end
            end
            slowerDead = true if isSlowerDead
            fasterDead = true if isFasterDead
            
            # Push a new array of [moveIndex,moveScore,targetIndex]
            # where targetIndex could be -1 for anything thats not single target
            choices.push([i].concat(newChoice)) if newChoice
        end
        # Undo the 70 percent drop if urgency is required
        # TODO: Make this not a garbage system, 2nd round of moves is -70% still but this shouldn't matter
        if urgency >= 10 && slowerDead && !fasterDead
            choices.each do |c|
                c[1] = ((c[1].to_f / 30) * 100).round
            end
            echoln("\t[MOVE SCORING] Undoing move cut because Urgency (#{urgency}) might require sacrificing the battler")
        end
        return choices,bestKillInfo
    end

    def pbEvaluateMoveTrainer(user, move, targets: [], killInfoArray: [], random: false)
        policies = user.ownersPolicies
        target_data = move.pbTarget(user)
        newChoice = nil
        ignoreGeneralEffectScores = !targets.empty?
        killInfo = nil
        if target_data.num_targets > 1
            # If move affects multiple battlers and you don't choose a particular one
            totalScore = 0
            if targets.empty?
                @battle.eachBattler do |b|
                    next unless @battle.pbMoveCanTarget?(user.index, b.index, target_data)
                    targets.push(b)
                end
            end
            targets.each do |b|
                score,targetKillInfo,isSlowerDead2,isFasterDead2 = pbGetMoveScore(move, user, b, policies, targets.length, ignoreGeneralEffectScores, killInfoArray)
                if target_data.targets_foe
                    if user.opposes?(b)
                        totalScore += score
                        killInfo = targetKillInfo
                    else
                        next if policies.include?(:EQ_PROTECT) && b.canChooseProtect?
                        totalScore -= score
                    end
                else
                    totalScore += score
                end
            end
            newChoice = [totalScore, -1] if totalScore > 0
        elsif target_data.num_targets == 0
            if targets.empty?
                # If move has no targets, affects the user, a side or the whole field
                score,targetKillInfo,isSlowerDead2,isFasterDead2 = pbGetMoveScore(move, user, user, policies, 0, ignoreGeneralEffectScores, killInfoArray)
                newChoice = [score, -1] if score > 0
            end
        else
            # If move affects one battler and you have to choose which one
            scoresAndTargets = []
            if targets.empty?
                @battle.eachBattler do |b|
                    next unless @battle.pbMoveCanTarget?(user.index, b.index, target_data)
                    next if target_data.targets_foe && !user.opposes?(b)
                    score,targetKillInfo,isSlowerDead2,isFasterDead2 = pbGetMoveScore(move, user, b, policies, 1, ignoreGeneralEffectScores, killInfoArray)
                    if user.opposes?(b)
                        totalScore = score
                        battlerCount = 1
                        b.eachRedirectingAlly do |ally|
                            allyScore,allyKillInfo = pbGetMoveScore(move, user, b, policies, 1, ignoreGeneralEffectScores, killInfoArray)
                            totalScore += allyScore
                            battlerCount += 1
                        end
                        score = totalScore / battlerCount
                    end
                    scoresAndTargets.push([score, b.index, nil]) if score > 0
                end
            else
                targets.each do |b|
                    next unless @battle.pbMoveCanTarget?(user.index, b.index, target_data)
                    next if target_data.targets_foe && !user.opposes?(b)
                    score,targetKillInfo,isSlowerDead2,isFasterDead2 = pbGetMoveScore(move, user, b, policies, 1, ignoreGeneralEffectScores, killInfoArray)
                    scoresAndTargets.push([score, b.index, targetKillInfo]) if score > 0
                end
            end
            if scoresAndTargets.length > 0
                if random
                    totalScore = 0
                    scoresAndTargets.each do |scoreAndTargetEntry|
                        totalScore += scoreAndTargetEntry[0]
                    end
                    totalScore /= scoresAndTargets.length.to_f
                    newChoice = [totalScore, -1]
                else
                    # Get the one best target for the move
                    scoresAndTargets.sort! { |a, b| b[0] <=> a[0] }
                    bestTargetChoice = scoresAndTargets[0]
                    newChoice = [bestTargetChoice[0], bestTargetChoice[1]]
                    killInfo = bestTargetChoice[2]
                end
            end
        end
        return newChoice,killInfo,isSlowerDead2,isFasterDead2
    end

    #=============================================================================
    # Get a score for the given move being used against the given target
    # Threat array is an array of entries like so: [Foe that can kill, move that kills, their speed, priority of the killing move]
    #=============================================================================
    def pbGetMoveScore(move, user, target, policies = [], numTargets = 1, ignoreGeneralEffectScores = false, killInfoArray = [])
        scoringKey = [move.id, user.personalID, target.personalID, numTargets, ignoreGeneralEffectScores, killInfoArray]
        isSlowerDead3 = false
        isFasterDead3 = false
        if @precalculatedChoices.key?(scoringKey)
            precalcedScore,precalcedKillInfo = @precalculatedChoices[scoringKey]
            if precalcedKillInfo
                echoln("[MOVE SCORING] Score for #{user.pbThis(true)}'s #{move.id} against target #{target.pbThis(true)} already calced this round: #{precalcedScore} (will faint the target)")
            else
                echoln("[MOVE SCORING] Score for #{user.pbThis(true)}'s #{move.id} against target #{target.pbThis(true)} already calced this round: #{precalcedScore}")
            end
            return precalcedScore,precalcedKillInfo
        end

        echoln("[MOVE SCORING] Scoring #{user.pbThis(true)}'s #{move.id} against target #{target.pbThis(true)}:")
        
        move.calculateUsageOverrides(user, [target])

        if aiPredictsFailure?(move, user, target, false)
            @precalculatedChoices[scoringKey] = 0
            return 0,nil
        end
        
        switchPredicted = @battle.aiPredictsSwitch?(user,target.index,true)

        # DAMAGE SCORE AND HIT TRIGGERS SCORE
        damageDealt = 0
        damageScore = 0
        triggersScore = 0
        willFaint = false
        damagingMove = move.damagingMove?(true)
        if damagingMove
            # Adjust the score based on the move dealing damage
            # and perhaps a percent chance to actually benefit from its effect score
            begin
                damageScore,damageDealt,willFaint = pbGetMoveScoreDamage(move, user, target, numTargets)
            rescue StandardError => exception
                pbPrintException($!) if $DEBUG
            end

            numHits = move.numberOfHits(user, [target], true).ceil

            # Account for triggered abilities of the user
            begin
                scoreModifierUserAbility = 0
                user.eachAIKnownActiveAbility do |ability|
                    scoreModifierUserAbility += 
                        BattleHandlers.triggerUserAbilityOnHitAI(ability, user, target, move, @battle, numHits)
                end
                triggersScore += scoreModifierUserAbility
                echoln("\t[MOVE SCORING] #{user.pbThis}'s #{numHits} hits adjusts the score by #{scoreModifierUserAbility} due to the user's abilities") if scoreModifierUserAbility != 0
            rescue StandardError => exception
                pbPrintException($!) if $DEBUG
            end

            # Account for the triggered abilities of the target
            if user.activatesTargetAbilities?(true)
                begin
                    scoreModifierTargetAbility = 0
                    target.eachAIKnownActiveAbility do |ability|
                        scoreModifierTargetAbility += 
                            BattleHandlers.triggerTargetAbilityOnHitAI(ability, user, target, move, @battle, numHits)
                    end
                    triggersScore += scoreModifierTargetAbility
                    echoln("\t[MOVE SCORING] #{numHits} hits adjusts the score by #{scoreModifierTargetAbility} due to the target's abilities") if scoreModifierTargetAbility != 0
                rescue StandardError => exception
                    pbPrintException($!) if $DEBUG
                end
            end

            # Account for the items of the target
            if user.activatesTargetItem?(true)
                begin
                    scoreModifierTargetItem = 0
                    target.eachAIKnownActiveItem do |item|
                        scoreModifierTargetItem += 
                            BattleHandlers.triggerTargetItemOnHitAI(item, user, target, move, @battle, numHits)
                    end
                    triggersScore += scoreModifierTargetItem
                    echoln("\t[MOVE SCORING] #{numHits} hits adjusts the score by #{scoreModifierTargetItem} due to the target's items") if scoreModifierTargetItem != 0
                rescue StandardError => exception
                    pbPrintException($!) if $DEBUG
                end
            end
            triggersScore = triggersScore.floor
        end

        # EFFECT SCORING
        effectScore = 0
        begin
            regularEffectScore = 0
            regularEffectScore += move.getEffectScore(user, target) unless ignoreGeneralEffectScores
            faintEffectScore = 0
            targetAffectingEffectScore = 0
            if willFaint
                faintEffectScore = move.getFaintEffectScore(user, target)
            elsif !target.substituted? || move.ignoresSubstitute?(user)
                targetAffectingEffectScore = move.getTargetAffectingEffectScore(user, target)
            end
            damageBasedEffectScore = move.getDamageBasedEffectScore(user, target, damageDealt)
            effectScore += regularEffectScore
            effectScore += faintEffectScore
            effectScore += targetAffectingEffectScore
            effectScore += damageBasedEffectScore
        rescue StandardError => e
            echoln("FAILURE IN THE SCORING SYSTEM FOR MOVE #{move.id} #{move.function}")
            effectScore = 0
            raise e if @battle.autoTesting
        end

        # Modify the effect score by the move's additional effect chance if it has one
        if move.randomEffect?
            type = pbRoughType(move, user)
            realProcChance = move.pbAdditionalEffectChance(user, target, type, 0, true)
            realProcChance = 0 unless move.canApplyRandomAddedEffects?(user,target,false,true)
            factor = (realProcChance / 100.0)
            echoln("\t[MOVE SCORING] #{user.pbThis} multiplies #{move.id}'s effect score of #{effectScore} by #{factor} based on effect chance")
            effectScore *= factor
        end
        effectScore = effectScore.floor

        # Combine
        score = damageScore + triggersScore + effectScore
        if damagingMove
            echoln("\t[MOVE SCORING] Main total score #{score} from a damage score of #{damageScore}, an effect score of #{effectScore}, and a triggers score of #{triggersScore}")
        else
            echoln("\t[MOVE SCORING] Main total score #{score} from an effect score of #{effectScore}, and a triggers score of #{triggersScore}")
        end

        # ! All score changes from this point forward must be multiplicative !

        # Pick a good move for the Choice items
        if !damagingMove && (user.hasActiveItemAI?(GameData::Item.getByFlag("ChoiceLocking")) || user.hasActiveAbilityAI?(GameData::Ability.getByFlag("ChoiceLocking")))
            echoln("\t[MOVE SCORING] Score is halved: Don't choice-lock into a status move.")
            score /= 2
        end

        # Account for accuracy of move
        accuracy = pbRoughAccuracy(move, user, target)
        score *= accuracy / 100.0

        if accuracy < 100
            echoln("\t[MOVE SCORING] Predicted accuracy: #{accuracy}")
        end

        # If they might kill us this turn, rate this move much less unless it will go before the target
        if !switchPredicted && !killInfoArray.empty?
            killInfoArray.each do |killInfo|
                if userMovesFirst?(move, user, target, killInfo: killInfo)
                    isFasterDead3 = true
                    next
                end
                echoln("\t[MOVE SCORING] Cutting score by 70 percent since #{killInfo.user.pbThis(true)} may kill it this turn with #{killInfo.move.id} beforehand")
                score *= 0.3
                isSlowerDead3 = true
            end
        end

        # Account for some abilities
        score = getMultiplicativeAbilityScore(score, move, user, target)

        # Final adjustments t score
        score = score.to_i
        score = 0 if score < 0
        echoln("\t[MOVE SCORING] Final score for #{user.pbThis}'s #{move.id} against target #{target.pbThis(true)}: #{score}")
        
        # Create kill info
        if willFaint
            killInfo = KillInfo.new(user,move,user.pbSpeed(true, move: move),@battle.getMovePriority(move, user, [target], true), score)
        else
            killInfo = nil
        end
        
        @precalculatedChoices[scoringKey] = [score,killInfo]
        return score,killInfo,isSlowerDead3,isFasterDead3
    end

    def getMultiplicativeAbilityScore(score, move, user, target)
        if move.danceMove?
            dancerBonus = 1.0
            user.eachOther do |b|
                next unless b.hasActiveAbilityAI?(:DANCER)
                if b.opposes?(user)
                    dancerBonus -= 0.8
                else
                    dancerBonus += 0.8
                end
            end
            score *= dancerBonus
        end

        if move.soundMove?
            dancerBonus = 1.0
            user.eachOther do |b|
                next unless b.hasActiveAbilityAI?(:ECHO)
                if b.opposes?(user)
                    dancerBonus -= 0.8
                else
                    dancerBonus += 0.8
                end
            end
            score *= dancerBonus
        end

        return score
    end

    #=============================================================================
    # Add to a move's score based on how much damage it will deal (as a percentage
    # of the target's current HP)
    #=============================================================================
    def pbGetMoveScoreDamage(move, user, target, numTargets = 1)
        realDamage,damagePercentage,subDestroyed = getDamageAnalysisAI(move, user, target, numTargets)

        # Adjust score
        willFaint = false
        if realDamage >= target.hp
            realDamage = target.hp
            damageScore = 250
            willFaint = true
        else
            # Only care about KO thresholds
            if damagePercentage >= 50 || subDestroyed == true # Breaking a sub is as good as doing 50%
                damageScore = 150 + (damagePercentage - 50)
                damageScore *= user.levelNerf(false,true,0.5) if user.level <= 30 && !user.pbOwnedByPlayer? # AI nerf
            elsif damagePercentage >= 33
                damageScore = 100 + (damagePercentage - 33)
                damageScore *= user.levelNerf(false,true,1.1) if user.level <= 30 && !user.pbOwnedByPlayer? # AI nerf
            else
                damageScore = 50 + damagePercentage
                damageScore *= user.levelNerf(false,true,2) if user.level <= 30 && !user.pbOwnedByPlayer? # AI nerf
            end
        end
        damageScore = damageScore.floor

        return damageScore,realDamage,willFaint
    end

    def getDamageAnalysisAI(move, user, target, numTargets = 1)
        # Calculate how much damage the move will do (roughly)
        realDamage,subDestroyed = pbTotalDamageAI(move, user, target, numTargets)

        # Convert damage to percentage of target's remaining HP
        damagePercentage = realDamage * 100.0 / target.totalhp

        if realDamage >= target.hp
            echoln("\t[MOVE SCORING] #{user.pbThis} thinks that move #{move.id} will deal #{realDamage} damage to #{target.pbThis(true)}, fainting it")
        else
            # TODO: Enable and rework EoR damage system, > DISABLED < 
            #healthChange,eotDamagePercent = passingTurnBattlerHealthChange(target,@battle)
            #realDamage += healthChange
            #damagePercentage += eotDamagePercent
            echoln("\t[MOVE SCORING] #{user.pbThis} thinks that move #{move.id} will deal #{realDamage} damage -- #{damagePercentage.round(1)} percent of #{target.pbThis(true)}'s HP.")
            #echoln("\t[MOVE SCORING] Additionally, target's HP will change #{eotDamagePercent} percent EOT.") unless eotDamagePercent == 0
            echoln("\t[MOVE SCORING] Additionally, target's Substitute will break") if subDestroyed == true
        end

        return realDamage,damagePercentage,subDestroyed
    end
end
