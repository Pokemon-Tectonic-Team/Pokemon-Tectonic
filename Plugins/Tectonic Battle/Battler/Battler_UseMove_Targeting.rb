
class PokeBattle_Battler
    #=============================================================================
    # Get move's user
    #=============================================================================
    def pbFindUser(_choice, _move)
        return self
    end

    def pbChangeUser(choice, move, user)
        # Snatch
        move.snatched = false
        if move.canSnatch?
            newUser = nil
            strength = 100
            @battle.eachBattler do |b|
                next if b.effects[:Snatch] == 0 || b.effects[:Snatch] >= strength
                next if b.effectActive?(:SkyDrop)
                newUser = b
                strength = b.effects[:Snatch]
            end
            if newUser
                user = newUser
                user.effects[:Snatch] = 0
                move.snatched = true
                @battle.moldBreaker = user.hasMoldBreaker?
                choice[3] = -1 # Clear pre-chosen target
            end
        end
        return user
    end

    #=============================================================================
    # Get move's default target(s)
    #=============================================================================
    def pbFindTargets(preTarget, move, user)
        targets = []
        # Get list of targets
        case move.pbTarget(user).id # Curse can change its target type
        when :NearAlly
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            pbAddTargetRandomAlly(targets, user, move) unless pbAddTarget(targets, user, targetBattler, move)
        when :Ally
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            pbAddTargetRandomAlly(targets, user, move, false) unless pbAddTarget(targets, user, targetBattler, move)
        when :UserOrNearAlly
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            pbAddTarget(targets, user, user, move, true, true) unless pbAddTarget(targets, user, targetBattler,
move, true, true)
        when :UserAndAllies
            pbAddTarget(targets, user, user, move, true, true)
            @battle.eachSameSideBattler(user.index) { |b| pbAddTarget(targets, user, b, move, false, true) }
        when :UserOrNearOther
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            pbAddTarget(targets, user, user, move, false, true) unless pbAddTarget(targets, user, targetBattler,
move, false, true)
        when :NearFoe, :NearOther
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            unless pbAddTarget(targets, user, targetBattler, move)
                if preTarget >= 0 && !user.opposes?(preTarget)
                    pbAddTargetRandomAlly(targets, user, move)
                else
                    pbAddTargetRandomFoe(targets, user, move)
                end
            end
        when :RandomNearFoe
            pbAddTargetRandomFoe(targets, user, move)
        when :ClosestNearFoe
            pbAddTargetClosestFoe(targets, user, move)
        when :AllNearFoes
            @battle.eachOtherSideBattler(user.index) { |b| pbAddTarget(targets, user, b, move) }
        when :Foe, :Other
            targetBattler = (preTarget >= 0) ? @battle.battlers[preTarget] : nil
            unless pbAddTarget(targets, user, targetBattler, move, false)
                if preTarget >= 0 && !user.opposes?(preTarget)
                    pbAddTargetRandomAlly(targets, user, move, false)
                else
                    pbAddTargetRandomFoe(targets, user, move, false)
                end
            end
        when :AllFoes
            @battle.eachOtherSideBattler(user.index) { |b| pbAddTarget(targets, user, b, move, false) }
        when :AllNearOthers
            @battle.eachBattler { |b| pbAddTarget(targets, user, b, move) }
        when :AllBattlers
            @battle.eachBattler { |b| pbAddTarget(targets, user, b, move, false, true) }
        else
            # Used by Counter/Mirror Coat/Metal Burst/Bide
            move.pbAddTarget(targets, user) # Move-specific pbAddTarget, not the def below
        end
        return targets
    end

    def moveFailsSemiInvulnerability?(move, user, target, aiCheck = false)
        return false if user.shouldAbilityApply?(:NOGUARD, aiCheck) || target.shouldAbilityApply?(:NOGUARD, aiCheck)
        return false if @battle.futureSight
        return false if move.hitsInvulnerable?

        return false if aiCheck && !user.boss? && !@battle.battleAI.userMovesFirst?(move, user, target)

        if target.inTwoTurnSkyAttack?
            return true unless move.hitsFlyingTargets?
        elsif target.inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderground")            # Dig
            return true unless move.hitsDiggingTargets?
        elsif target.inTwoTurnAttack?("TwoTurnAttackInvulnerableUnderwater")            # Dive
            return true unless move.hitsDivingTargets?
        elsif target.inTwoTurnAttack?("TwoTurnAttackInvulnerableRemoveProtections")	# PHANTOMFORCE/SHADOWFORCE in case we have a move that hits them
            return true
        end
        
        # Sky Drop
        return true if target.effectActive?(:SkyDrop) && target.effects[:SkyDrop] != user.index && !move.hitsFlyingTargets?
        
        return false
    end

    #=============================================================================
    # Redirect attack to another target
    #=============================================================================
    def pbChangeTargets(move, user, targets, _smartSpread = -1)
        target_data = move.pbTarget(user)
        return targets if @battle.switching # For Pursuit interrupting a switch
        return targets if move.cannotRedirect?
        return targets if !target_data.can_target_one_foe? || targets.length != 1
        move.pbModifyTargets(targets, user) # For Dragon Darts, etc.
        return targets if user.hasActiveAbility?(GameData::Ability.getByFlag("RedirectionImmunity"))
        priority = @battle.pbPriority(true)
        nearOnly = !target_data.can_choose_distant_target?
        # Spotlight (takes priority over Follow Me/Rage Powder or redirection abilities)
        newTarget = nil
        strength = 100 # Lower strength takes priority
        priority.each do |b|
            next if b.fainted?
            next if b.effects[:Spotlight] == 0 || b.effects[:Spotlight] >= strength
            next unless b.opposes?(user)
            next if nearOnly && !b.near?(user)
            newTarget = b
            strength = b.effects[:Spotlight]
        end
        if newTarget
            PBDebug.log("[Move target changed] #{newTarget.pbThis}'s Spotlight made it the target")
            targets = []
            pbAddTarget(targets, user, newTarget, move, nearOnly)
            return targets
        end
        # Follow Me/Rage Powder (takes priority over Lightning Rod/Storm Drain)
        newTarget = nil
        strength = 100 # Lower strength takes priority
        priority.each do |b|
            next if b.fainted?
            next if b.effects[:FollowMe] == 0 || b.effects[:FollowMe] >= strength
            next unless b.opposes?(user)
            next if nearOnly && !b.near?(user)
            newTarget = b
            strength = b.effects[:FollowMe]
        end
        if newTarget
            PBDebug.log("[Move target changed] #{newTarget.pbThis}'s Follow Me/Rage Powder made it the target")
            targets = []
            pbAddTarget(targets, user, newTarget, move, nearOnly)
            return targets
        end
        # Bad Luck
        if move.statusMove? && !user.pbHasAnyStatus?
            targets = pbChangeTargetByAbility(:BADLUCK, move, user, targets, priority, nearOnly)
        end
        # White Knight
        if move.damagingMove? && move.baseDamage >= 100
            targets = pbChangeTargetByAbility(:WHITEKNIGHT, move, user, targets, priority, nearOnly)
        end
        # Tantalizing
        if move.damagingMove? && user.belowHalfHealth?
            targets = pbChangeTargetByAbility(:TANTALIZING, move, user, targets, priority, nearOnly)
        end
        return targets
    end

    def pbChangeTargetByAbility(drawingAbility, move, user, targets, priority, nearOnly)
        return targets if targets[0].hasActiveAbility?(drawingAbility)
        priority.each do |b|
            next if b.index == user.index || b.index == targets[0].index
            next unless b.hasActiveAbility?(drawingAbility)
            next if nearOnly && !b.near?(user)
            next unless b.opposes?(user)
            @battle.pbShowAbilitySplash(b, drawingAbility)
            targets.clear
            pbAddTarget(targets, user, b, move, nearOnly)
            @battle.pbDisplay(_INTL("{1} took the attack!", b.pbThis))
            @battle.pbHideAbilitySplash(b)
            break
        end
        return targets
    end

    #=============================================================================
    # Register target
    #=============================================================================
    def pbAddTarget(targets, user, target, move, nearOnly = true, allowUser = false)
        return false if !target || (target.fainted? && !move.cannotRedirect?)
        return false if !(allowUser && user == target) && nearOnly && !user.near?(target)
        targets.each { |b| return true if b.index == target.index }   # Already added
        targets.push(target)
        return true
    end

    def pbAddTargetRandomAlly(targets, user, _move, nearOnly = true)
        choices = []
        user.eachAlly do |b|
            next if nearOnly && !user.near?(b)
            pbAddTarget(choices, user, b, nearOnly)
        end
        choice = choices[0]
        if choices.length > 1
            # only call random if necessary to prevent online desyncs
            choice = @battle.pbRandom(choices.length)
        end
        pbAddTarget(targets, user, choice, nearOnly) if choices.length > 0
    end

    def pbAddTargetRandomFoe(targets, user, _move, nearOnly = true)
        choices = []
        user.eachOpposing do |b|
            next if nearOnly && !user.near?(b)
            pbAddTarget(choices, user, b, nearOnly)
        end
        choice = choices[0]
        if choices.length > 1
            choice = @battle.pbRandom(choices.length)
        end
        pbAddTarget(targets, user, choice, nearOnly) if choices.length > 0
    end

    def pbAddTargetClosestFoe(targets, user, _move, nearOnly = true)
        choices = []
        user.eachOpposing do |b|
            next if nearOnly && !user.near?(b)
            pbAddTarget(choices, user, b, nearOnly)
        end
        return if choices.empty?

        opposingIndices = @battle.pbGetOpposingIndicesInOrder(user.index)
        choices.sort_by! do |choice|
            next opposingIndices.find_index(choice.index) * 100 - choice.index
        end
        pbAddTarget(targets, user, choices[0], nearOnly)
    end
end
