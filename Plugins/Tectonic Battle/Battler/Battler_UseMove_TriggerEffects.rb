class PokeBattle_Battler
    #=============================================================================
    # Effect per hit
    #=============================================================================
    def pbEffectsOnMakingHit(move, user, target)
        if target.damageState.calcDamage > 0 && !target.damageState.substitute
            # Target's ability
            if user.activatesTargetAbilities?
                target.eachActiveAbility(true) do |ability|
                    oldHP = user.hp
                    BattleHandlers.triggerTargetAbilityOnHit(ability, user, target, move, @battle)
                    user.pbItemHPHealCheck if user.hp < oldHP
                end
            end
            # User's ability
            user.eachActiveAbility(true) do |ability|
                BattleHandlers.triggerUserAbilityOnHit(ability, user, target, move, @battle)
                user.pbItemHPHealCheck
            end

            # Target's item
            if user.activatesTargetItem?
                target.eachActiveItem(true) do |item|
                    oldHP = user.hp
                    BattleHandlers.triggerTargetItemOnHit(item, user, target, move, @battle)
                    user.pbItemHPHealCheck if user.hp < oldHP
                end
            end

            # Ice Dungeon
            target.disableEffect(:IceDungeon)

            # Trackers
            if target.opposes?(user)
                target.tookPhysicalHit = true if move.physicalMove?
                target.tookSpecialHit = true if move.specialMove?
            end

            # Learn the target's damage affecting abilities
            target.eachActiveAbility do |abilityID|
                next unless BattleHandlers::DamageCalcTargetAbility.hasKey?(abilityID)
                target.aiLearnsAbility(abilityID)
            end
        end
        if target.opposes?(user) && user.activatesTargetEffects?
            # Primal Forest
            if target.pbOwnSide.effectActive?(:PrimalForest) && !target.fainted?
                @battle.pbDisplay(_INTL("{1} communes with the primal forest!", target.pbThis))
                target.pbRaiseMultipleStatSteps(ATTACKING_STATS_1, nil)
                target.pbLowerMultipleStatSteps(DEFENDING_STATS_1, nil)
            end
            # Beak Blast
            if target.effectActive?(:BeakBlast, true)
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Beak Blast")
                user.applyBurn(target) if move.physicalMove? && user.canBurn?(target, true, move)
            end
            # Cold Snap
            if target.effectActive?(:ColdSnap, true)
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Cold Snap")
                user.applyFrostbite(target) if move.specialMove? && user.canFrostbite?(target, true, move)
            end
            # Shard Surge
            if target.effectActive?(:ShardSurge, true)
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Shard Surge")
                if move.specialMove? && !user.pbOpposingSide.effectAtMax?(:Spikes)
                    target.pbOpposingSide.incrementEffect(:Spikes)
                end
            end
            # Are set to move, but haven't yet
            if @battle.choices[target.index][0] == :UseMove && !target.movedThisRound?
                # Shell Trap (make the trapper move next if the trap was triggered)
                if target.tookPhysicalHit && target.effectActive?(:ShellTrap)
                    target.applyEffect(:MoveNext)
                end
                # Masquerblade (make the trapper move next if the trap was triggered)
                if target.tookSpecialHit && target.effectActive?(:Masquerblade)
                    target.applyEffect(:MoveNext)
                end
            end
            # Destiny Bond (recording that it should apply)
            if target.effectActive?(:DestinyBond, true) && target.fainted? && !user.effectActive?(:DestinyBondTarget)
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Destiny Bond")
                user.applyEffect(:DestinyBondTarget, target.index)
            end
            # Stunning Curl
            if target.effectActive?(:StunningCurl, true) && !user.numbed?
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Stunning Curl")
                if user.canNumb?(target, false)
                    @battle.pbDisplay(_INTL("{1}'s stance made {2}'s attack bounce off akwardly!", target.pbThis,
user.pbThis(true)))
                    user.applyNumb(target)
                end
            end
            # Root Shelter
            if target.effectActive?(:RootShelter, true) && !user.leeched?
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Root Shelter")
                if user.canLeech?(target, false)
                    @battle.pbDisplay(_INTL("The roots guarding {1} dig into {2}!", target.pbThis(true),
user.pbThis(true)))
                    user.applyLeeched(target)
                end
            end
            # Venom Guard
            if target.effectActive?(:VenomGuard, true) && !user.poisoned?
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Venom Guard")
                if user.canPoison?(target, false)
                    @battle.pbDisplay(_INTL("{1} was stuck by {2}'s venom!", user.pbThis, target.pbThis(true)))
                    user.applyPoison(target)
                end
            end
            # Floodgate
            if target.effectActive?(:Floodgate, true) && !user.waterlogged?
                PBDebug.log("[Lingering effect] #{target.pbThis}'s Floodgate")
                if user.canWaterlog?(target, false)
                    @battle.pbDisplay(_INTL("{1} was flooded by {2}!", user.pbThis, target.pbThis(true)))
                    user.applyWaterlog(target)
                end
            end
            # Bubble Barrier
            if target.effectActive?(:BubbleBarrier, true) && target.damageState.bubbleBarrier > 0
                recoilMessage = _INTL("The bubble barrier bursts, harming {1}!", user.pbThis(true))
                user.applyRecoilDamage(target.damageState.bubbleBarrier, true, true, recoilMessage)
                target.disableEffect(:BubbleBarrier)
            end
        end
    end

    #=============================================================================
    # Effects after all hits (i.e. at end of move usage)
    #=============================================================================
    def pbEffectsAfterMove(user, targets, move, numHits)
        # Destiny Bond
        # NOTE: Although Destiny Bond is similar to Grudge, they don't apply at
        #       the same time (although Destiny Bond does check whether it's going
        #       to trigger at the same time as Grudge).
        if user.effectActive?(:DestinyBondTarget) && !user.fainted?
            dbName = @battle.battlers[user.effects[:DestinyBondTarget]].pbThis
            @battle.pbDisplay(_INTL("{1} took its attacker down with it!", dbName))
            user.pbReduceHP(user.hp, false)
            user.pbFaint
            @battle.pbJudgeCheckpoint(user)
        end
        # User's ability
        switchedBattlers = []
        user.eachActiveAbility do |ability|
            BattleHandlers.triggerUserAbilityEndOfMove(ability, user, targets, move, @battle, switchedBattlers)
            if user.effectActive?(:HyperBeam)
                BattleHandlers.triggerUserAbilityEndOfExhaustingMove(ability, user, targets, move, battle)
            end
        end

        # Consume gems, etc.
        consumeMoveTriggeredItems(user)
        # Consume Energy Charge
        if user.effectActive?(:EnergyChargeExpended)
            user.disableEffect(:EnergyCharge)
        end
        # Pokémon switching caused by Roar, Whirlwind, Discourage, Dragon Tail
        move.pbSwitchOutTargetsEffect(user, targets, numHits, switchedBattlers)
        # Target's item, user's item, target's ability (all negated by Sheer Force)
        if user.hasActiveAbility?(:SHEERFORCE) && move.randomEffect?
            # Skip other additional effects too if sheer force is being applied to the move
        else
            pbEffectsAfterMove2(user, targets, move, numHits, switchedBattlers)
        end
        # Ally Cushion
        if user.effectActive?(:KickbackSwap) && !switchedBattlers.include?(user.index)
            if @battle.triggeredSwitchOut(user.index)
                user.pbEffectsOnSwitchIn(true)
                switchedBattlers.push(user.index)
            else
                user.disableEffect(:KickbackSwap)
                user.position.disableEffect(:Kickback)
            end
        end
        # Some move effects that need to happen here, i.e. U-turn/Volt Switch
        # switching, Baton Pass switching, Parting Shot switching, Relic Song's form
        # changing, Fling/Natural Gift consuming item.
        unless switchedBattlers.include?(user.index)
            move.pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
        end
        # Misdirecting Fog
        unless switchedBattlers.include?(user.index)
            fogSending = false
            targets.each do |target|
                next unless target.pbOwnSide.effectActive?(:MisdirectingFog)
                next unless target.opposes?(user)
                fogSending = true
                break
            end

            trySwitchOutUser(user, targets, numHits, switchedBattlers) if fogSending
        end
        @battle.eachBattler { |b| b.pbItemEndOfMoveCheck } if numHits > 0
    end

    def consumeMoveTriggeredItems(user)
        # Consume user's agility herb
        if user.effectActive?(:AgilityHerb,true)
            user.consumeItem(:AGILITYHERB)
            user.disableEffect(:AgilityHerb,true)
        end
        # Consume user's Gem
        if user.effectActive?(:GemConsumed,true)
            # NOTE: The consume animation and message for Gems are shown immediately
            #       after the move's animation, but the item is only consumed now.
            user.consumeItem(user.effects[:GemConsumed])
            user.disableEffect(:GemConsumed,true)
        end

        # NOTE: The consume animation and message for Herbs are shown immediately
        # after the move's animation, but the item is only consumed now.

        # Consume user's empowering Herb
        if user.effectActive?(:EmpoweringHerbConsumed,true)
            user.consumeItem(user.effects[:EmpoweringHerbConsumed])
            user.disableEffect(:EmpoweringHerbConsumed,true)
        end
        # Consume user's skill Herb
        if user.effectActive?(:SkillHerbConsumed,true)
            user.consumeItem(:SKILLHERB)
            user.disableEffect(:SkillHerbConsumed,true)
        end
        # Consume user's luck Herb
        if user.effectActive?(:LuckHerbConsumed,true)
            user.consumeItem(:LUCKHERB)
            user.disableEffect(:LuckHerbConsumed,true)
        end

        # Herbs on opponents
        user.eachOpposing do |opp|
            # Consume opponent's mirror Herb
            if opp.pointsAt?(:MirrorHerbConsumed,user)
                @battle.pbCommonAnimation("UseItem", opp)
                @battle.pbDisplay(_INTL("{1} copies {2}'s stat increases with its {3}!", opp.pbThis, user.pbThis(false), getItemName(:MIRRORHERB)))
                statsHash = opp.effects[:MirrorHerbCopiedStats]
                statArray = []
                GameData::Stat.each_main_battle do |stat|
                    next unless statsHash.key?(stat.id)
                    increment = statsHash[stat.id]
                    statArray.push(stat.id)
                    statArray.push(increment)
                end
                opp.pbRaiseMultipleStatSteps(statArray, opp)
                opp.consumeItem(:MIRRORHERB)
                opp.disableEffect(:MirrorHerbConsumed)
            end
            # Consume opponent's paradox Herb
            if opp.pointsAt?(:ParadoxHerbConsumed,user)
                @battle.pbCommonAnimation("UseItem", opp)
                @battle.pbDisplay(_INTL("{1} resets {2}'s stats with its {3}!", opp.pbThis, user.pbThis(false), getItemName(:PARADOXHERB)))
                @battle.pbAnimation(:REFRESH, user, nil)
                user.resetStatSteps
                opp.consumeItem(:PARADOXHERB)
                opp.disableEffect(:ParadoxHerbConsumed)
            end
        end
    end

    def trySwitchOutUser(user, targets, numHits, switchedBattlers)
        return if user.fainted? || numHits == 0
        targetSwitched = true
        targets.each do |b|
            targetSwitched = false unless switchedBattlers.include?(b.index)
        end
        return if targetSwitched
        return unless @battle.pbCanChooseNonActive?(user.index)
        @battle.pbDisplay(_INTL("{1} went back to {2}!", user.pbThis,
            @battle.pbGetOwnerName(user.index)))
        @battle.pbPursuit(user.index)
        return if user.fainted?
        newPkmn = @battle.pbGetReplacementPokemonIndex(user.index) # Owner chooses
        return if newPkmn < 0
        @battle.pbRecallAndReplace(user.index, newPkmn)
        @battle.pbClearChoice(user.index) # Replacement Pokémon does nothing this round
        @battle.moldBreaker = false
        switchedBattlers.push(user.index)
        user.pbEffectsOnSwitchIn(true)
    end

    # Everything in this method is negated by Sheer Force.
    def pbEffectsAfterMove2(user, targets, move, numHits, switchedBattlers)
        hpNow = user.hp # Intentionally determined now, before Shell Bell
        # Target's held item (Eject Button, Red Card)
        switchByItem = []
        @battle.pbPriority(true).each do |b|
            next unless targets.any? { |targetB| targetB.index == b.index }
            next if b.damageState.unaffected || b.damageState.calcDamage == 0 ||
                    switchedBattlers.include?(b.index)
            b.eachActiveItem do |item|
                BattleHandlers.triggerTargetItemAfterMoveUse(item, b, user, move, switchByItem, @battle)
            end
            # Eject Pack
            if b.effectActive?(:StatsDropped)
                b.eachActiveItem do |item|
                    BattleHandlers.triggerItemOnStatLoss(item, b, user, move, switchByItem, @battle)
                end
            end
        end
        @battle.moldBreaker = false if switchByItem.include?(user.index)
        @battle.pbPriority(true).each do |b|
            b.pbEffectsOnSwitchIn(true) if switchByItem.include?(b.index)
        end
        switchByItem.each { |idxB| switchedBattlers.push(idxB) }
        # User's held item (Life Orb, Shell Bell)
        if !switchedBattlers.include?(user.index)
            user.eachActiveItem do |item|
                BattleHandlers.triggerUserItemAfterMoveUse(item, user, targets, move, numHits, @battle)
            end
        end
        # Target's ability (Berserk, Color Change, Emergency Exit, Pickpocket, Wimp Out)
        switchWimpOut = []
        @battle.pbPriority(true).each do |b|
            next unless targets.any? { |targetB| targetB.index == b.index }
            next if b.damageState.unaffected || switchedBattlers.include?(b.index)
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerTargetAbilityAfterMoveUse(ability, b, user, move, switchedBattlers, @battle)
                
                if move.damagingMove? && b.knockedBelowHalf? && user.activatesTargetAbilities?
                    BattleHandlers.triggerTargetAbilityKnockedBelowHalf(ability, b, user, move, switchedBattlers, @battle)
                end
            end
            next unless !switchedBattlers.include?(b.index) && move.damagingMove?
            if b.pbAbilitiesOnDamageTaken(b.damageState.initialHP)
                switchWimpOut.push(b.index)
            end # Emergency Exit, Wimp Out
        end
        @battle.moldBreaker = false if switchWimpOut.include?(user.index)
        @battle.pbPriority(true).each do |b|
            next if b.index == user.index
            b.pbEffectsOnSwitchIn(true) if switchWimpOut.include?(b.index)
        end
        switchWimpOut.each { |idxB| switchedBattlers.push(idxB) }
        # User's item (Eject Pack)
        if !switchedBattlers.include?(user.index) && effectActive?(:StatsDropped)
            ejectPacked = []
            user.eachActiveItem do |item|
                BattleHandlers.triggerItemOnStatLoss(item, self, user, move, ejectPacked, @battle)
            end
            if ejectPacked.include?(user.index)
                @battle.moldBreaker = false
                user.pbEffectsOnSwitchIn(true)
                switchedBattlers.push(user.index)
            end
        end
    end
end
