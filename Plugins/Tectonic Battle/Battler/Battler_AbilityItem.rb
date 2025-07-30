class PokeBattle_Battler
    #=============================================================================
    # Called when a Pokémon (self) is sent into battle or its ability changes.
    #=============================================================================
    def pbEffectsOnSwitchIn(switchIn = false)
        # Healing Wish/Lunar Dance/entry hazards
        @battle.pbOnActiveOne(self) if switchIn
        # Primal Revert upon entering battle
        @battle.pbPrimalReversion(@index) unless fainted?
        # Ending primordial weather, checking Trace
        pbContinualAbilityChecks(true)
        # Abilities that trigger upon switching in
        eachAbility do |ability|
            next unless (!fainted? && GameData::Ability.get(ability).is_immutable_ability?) || abilityActive?
            BattleHandlers.triggerAbilityOnSwitchIn(ability, self, @battle)
        end
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
        # Items that trigger upon switching in (Air Balloon message)
        if switchIn
            eachActiveItem do |item|
                BattleHandlers.triggerItemOnSwitchIn(item, self, @battle)

                if @battle.statItemsAreMetagameRevealed
                    # Auto reveal vests and choice items
                    itemData = GameData::Item.get(item)
                    if itemData.is_no_status_use? || itemData.is_choice_locking?
                        aiLearnsItem(item)
                    end 
                end
            end
        end
        # Berry check, status-curing ability check
        pbHeldItemTriggerCheck if switchIn
        pbAbilityStatusCureCheck
    end

    #=============================================================================
    # Ability effects
    #=============================================================================
    def pbAbilitiesOnSwitchOut
        eachActiveAbility do |ability|
            BattleHandlers.triggerAbilityOnSwitchOut(ability, self, @battle, false)
        end
        position.applyEffect(:PassingAbility, @pokemonIndex) if abilityActive?
        position.applyEffect(:PassingStats, @pokemonIndex)
        # Caretaker bonus
        pbRecoverHP(@totalhp / 10.0, false, false, false) if hasTribeBonus?(:CARETAKER) && !fainted?
        # Reset form
        @battle.peer.pbOnLeavingBattle(@battle, @pokemon, @battle.usedInBattle[idxOwnSide][@index / 2])
        # Treat self as fainted
        @hp = 0
        @fainted = true
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
    end

    def pbAbilitiesOnFainting
        # Self fainted; check all other battlers to see if their abilities trigger
        @battle.pbPriority(true).each do |b|
            next unless b
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityChangeOnBattlerFainting(ability, b, self, @battle)
            end
        end
        @battle.pbPriority(true).each do |b|
            next unless b
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityOnBattlerFainting(ability, b, self, @battle)
            end
        end

        # Scoure tribal bonus
        opposingIndex = (@index + 1) % 2
        opposingSide = @battle.sides[opposingIndex]
        trainerGroup = opposingIndex == 0 ? @battle.player : @battle.opponent

        trainerGroup&.each do |trainer|
            trainerName = trainer.name
            if trainer.tribalBonus.hasTribeBonus?(:SCOURGE)
                healingMessage = _INTL("{1}'s team takes joy in {2}'s pain!", trainerName, pbThis(true))
                healingMessage = _INTL("The opposing {1}", healingMessage) if opposingIndex == 1
                @battle.pbShowTribeSplash(opposingSide, :SCOURGE, trainerName: trainerName)
                @battle.pbDisplay(healingMessage)
                trainer.party.each_with_index do |partyMember, index|
                    next if partyMember.fainted?
                    next if partyMember.hp == partyMember.totalhp
                    battler = @battle.pbFindBattler(index, opposingIndex)
                    if battler
                        battler.applyFractionalHealing(1/10.0)
                    else
                        partyMember.healByFraction(1/10.0)
                    end
                end
                @battle.pbHideTribeSplash(opposingSide)
            end
        end
    end

    # Used for Emergency Exit/Wimp Out.
    def pbAbilitiesOnDamageTaken(oldHP, newHP = -1)
        newHP = @hp if newHP < 0
        return false if oldHP < @totalhp / 2 || newHP >= @totalhp / 2 # Didn't drop below half
        ret = false
        eachActiveAbility(true) do |ability|
            ret = true if BattleHandlers.triggerAbilityOnHPDroppedBelowHalf(ability, self, @battle)
        end
        return ret # Whether self has switched out
    end

    # Called when a Pokémon (self) enters battle, at the end of each move used,
    # and at the end of each round.
    def pbContinualAbilityChecks(onSwitchIn = false)
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather

        # Trace
        if hasActiveAbility?(:TRACE)
            choices = []
            @battle.eachOtherSideBattler(@index) do |b|
                next if GameData::Ability.get(b.firstAbility).is_uncopyable_ability?
                choices.push(b)
            end
            unless choices.empty?
                choice = choices.sample
                showMyAbilitySplash(:TRACE)
                stolenAbility = choice.ability
                setAbility(stolenAbility)
                @battle.pbDisplay(_INTL("{1} traced {2}'s {3}!", pbThis, choice.pbThis(true), getAbilityName(stolenAbility)))
                hideMyAbilitySplash
                if !onSwitchIn && abilityActive?
                    BattleHandlers.triggerAbilityOnSwitchIn(stolenAbility, self, @battle)
                end
                return
            end
        end
        # Pluripotence
        if hasActiveAbility?(:PLURIPOTENCE)
            choices = {}
            @battle.eachOtherSideBattler(@index) do |b|
                copiableAbilities = []
                b.eachLegalAbility do |abilityID|
                    next if GameData::Ability.get(abilityID).is_uncopyable_ability?
                    copiableAbilities.push(abilityID)
                end
                next if copiableAbilities.empty?
                choices[b] = copiableAbilities
            end
            unless choices.empty?
                battlerCopying = choices.keys.sample
                abilitiesCopying = choices[battlerCopying]
                showMyAbilitySplash(:PLURIPOTENCE)
                @battle.pbDisplay(_INTL("{2}? {1} can be that, if it wishes.", pbThis, GameData::Species.get(battlerCopying.species).name))
                echoln("Abilities that Pluripotence is copying: #{abilitiesCopying.to_s}")
                setAbility(abilitiesCopying)
                abilitiesCopying.each do |legalAbility|
                    @battle.pbDisplay(_INTL("{1} imitated the Ability {2}!", pbThis, getAbilityName(legalAbility)))
                end
                hideMyAbilitySplash
                if !onSwitchIn && (immutableAbility? || abilityActive?)
                    eachAbility do |ability|
                        BattleHandlers.triggerAbilityOnSwitchIn(ability, self, @battle)
                    end
                end
            end
        end
    end

    #=============================================================================
    # Ability curing
    #=============================================================================
    # Cures status conditions, confusion and infatuation.
    #=============================================================================
    def pbAbilityStatusCureCheck
        eachActiveAbility do |ability|
            BattleHandlers.triggerStatusCureAbility(ability, self)
        end
    end

    #=============================================================================
    # Ability removed
    #=============================================================================
    def pbOnAbilitiesLost(oldAbilities)
        if illusion? && oldAbilities.include?(:ILLUSION) && !hasAbility?(:ILLUSION)
            disableEffect(:Illusion)
            unless effectActive?(:Transform)
                @battle.scene.pbChangePokemon(self, @pokemon)
                @battle.pbDisplay(_INTL("{1}'s {2} wore off!", pbThis, getAbilityName(:ILLUSION)))
                @battle.pbSetSeen(self)
            end
        end
        if illusion? && oldAbilities.include?(:INCOGNITO) && !hasAbility?(:INCOGNITO)
            disableEffect(:Illusion)
            unless effectActive?(:Transform)
                @battle.scene.pbChangePokemon(self, @pokemon)
                @battle.pbDisplay(_INTL("{1}'s {2} wore off!", pbThis, getAbilityName(:INCOGNITO)))
                @battle.pbSetSeen(self)
            end
        end
        disableEffect(:AbilitySupressed) if immutableAbility?
        disableEffect(:SlowStart) unless hasAbility?(:SLOWSTART)
        
        # Revert form if Flower Gift/Forecast was lost
        pbCheckFormOnWeatherChange(true)

        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
        
        if items.length > 1
            droppedItems = false
            GameData::Ability.getByFlag("MultipleItems").each do |doubleItemAbility|
                next unless oldAbilities.include?(doubleItemAbility) && !hasAbility?(doubleItemAbility)
                itemKept = items[0]
                setItems(itemKept)
                @battle.pbDisplay(_INTL("{1} dropped all of its items except {2}!", pbThis, getItemName(itemKept)))
                aiLearnsItem(itemKept)
                droppedItems = true
                break
            end
        end
    end

    #=============================================================================
    # Held item adding or gifting
    #=============================================================================
    def giveItem(item,stolen = false)
        return if item.nil?
        return unless canAddItem?(item, stolen)
        item = GameData::Item.get(item).id
        disableEffect(:ItemLost)
        @pokemon.giveItem(item)
        refreshDataBox

        @addedItems.push(item)

        @battle.updateTribeCounts
    end
    
    def setItems(value)
        @pokemon.setItems(value)

        @battle.updateTribeCounts
    end

    def recycleItem(recyclingMsg: nil, ability: nil)
        return unless recyclableItem
        itemToRecycle = recyclableItem
        return unless canAddItem?(itemToRecycle)
        showMyAbilitySplash(ability) if ability
        @battle.pbAnimation(:RECYCLE, self, nil)
        giveItem(itemToRecycle)
        setRecycleItem(nil)
        recyclingMsg ||= _INTL("{1} recycled one {2}!", pbThis, getItemName(itemToRecycle))
        @battle.pbDisplay(recyclingMsg)
        hideMyAbilitySplash if ability
        pbHeldItemTriggerCheck

        @battle.updateTribeCounts
    end

    #=============================================================================
    # Held item consuming/removing
    #=============================================================================
    def canConsumeBerry?
        return false if @battle.pbCheckOpposingAbility(%i[UNNERVE ASONEICE ASONEGHOST], @index)
        return true
    end

    def canLeftovers?
        return false if @battle.pbCheckOpposingAbility(%i[UNNERVE ASONEICE ASONEGHOST], @index)
        return true
    end

    def canConsumeGem?
        return true
    end

    def canConsumePinchBerry?(check_gluttony = true)
        return false unless canConsumeBerry?
        return true if @hp <= @totalhp / 4
        return true if @hp <= @totalhp / 2 && (!check_gluttony || hasActiveAbility?(%i[GLUTTONY GOURMAND]))
        return false
    end

    def removeItem(item)
        itemIndex = items.index(item)
        unless itemIndex
            raise _INTL("Error: Asked to remove item #{item} from #{pbThis(true)}, but it doesn't have that item")
        end
        disableEffect(:ChoiceBand) if GameData::Item.get(item).is_choice_locking?
        items.delete_at(itemIndex)
        applyEffect(:ItemLost) if items.length == 0
        refreshDataBox
        
        @battle.updateTribeCounts
    end

    #=========================================
    # Also handles SCAVENGE
    #=========================================
    def consumeItem(item, recoverable: true, belch: true)
        if item.nil?
            PBDebug.log("[Item not consumed] #{pbThis} could not consume a #{item} because it was already missing")
            return
        end
        unless hasItem?(item)
            PBDebug.log("[Item not consumed] #{pbThis} could not consume a #{item} because it didn't have one")
            return
        end
        itemData = GameData::Item.get(item)
        itemName = itemData.name
        PBDebug.log("[Item consumed] #{pbThis} consumed its held #{itemName}")
        @battle.triggerBattlerConsumedItemDialogue(self, item)
        if recoverable
            setRecycleItem(item)
            if itemData.is_berry? && hasActiveAbility?(:CUDCHEW)
                applyEffect(:CudChew, 2)
                applyEffect(:CudChewItem, item)
            end
        end
        setBelched if belch && itemData.is_berry?
        setLustered if belch && itemData.is_gem?
        removeItem(item)
    end

    # item_to_use is an item ID or GameData::Item object. ownitem is whether the
    # item is held by self. fling is for Fling only.
    def pbHeldItemTriggered(item_to_use, ownitem = true, fling = false)
        # Cheek Pouch and similar abilities
        if GameData::Item.get(item_to_use).is_berry?
            eachActiveAbility do |ability|
                BattleHandlers.triggerOnBerryConsumedAbility(ability, self, item_to_use, ownitem, @battle)
            end
        end
        if ownitem
            consumeItem(item_to_use)
            aiLearnsItem(item_to_use)
        end
    end

    #=============================================================================
    # Held item trigger checks
    #=============================================================================
    # NOTE: A Pokémon using Bug Bite/Pluck, and a Pokémon having an item thrown at
    #       it via Fling, will gain the effect of the item even if the Pokémon is
    #       affected by item-negating effects.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbHeldItemTriggerCheck(item_to_use = nil, fling = false)
        return if fainted?
        pbItemHPHealCheck(item_to_use, fling)
        pbItemStatusCureCheck(item_to_use, fling)
        pbItemEndOfMoveCheck(item_to_use, fling)
        # For Enigma Berry, Kee Berry and Maranga Berry, which have their effects
        # when forcibly consumed by Pluck/Fling.
        if item_to_use
            if BattleHandlers.triggerTargetItemOnHitPositiveBerry(item_to_use, self, @battle, true)
                pbHeldItemTriggered(item_to_use, false, fling)
            end
        end
    end

    def pbItemHPHealCheck(item_to_use = nil, fling = false, items_to_skip: [])
        return if afraid?

        # Check for berry filching
        unless item_to_use
            eachActiveItem do |item|
                next if items_to_skip.include?(item)
                next unless GameData::Item.get(item).is_berry?
                filcher = nil

                @battle.eachBattler { |b|
                    next if b.index == @index
                    next unless b.hasActiveAbility?(:EXTORTER)
                    filcher = b
                    break
                }
    
                # If the berry is being filched
                if filcher && BattleHandlers.triggerHPHealItem(item, filcher, @battle, false, self, :EXTORTER, items_to_skip)
                    filcher.pbHeldItemTriggered(item, false)
                    consumeItem(item)
                end
            end
        end

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems.clone

        itemsToCheck.each do |item|
            next if items_to_skip.include?(item)
            # Check for user
            next unless BattleHandlers.triggerHPHealItem(item, self, @battle, forced, nil, nil, items_to_skip)
            pbHeldItemTriggered(item, !forced, fling)
        end

        unless forced
            pbItemFieldEffectCheck
        end
    end

    # Cures status conditions, confusion, infatuation and the other effects cured
    # by Mental Herb.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemStatusCureCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems.clone
        itemsToCheck.each do |item|
            if BattleHandlers.triggerStatusCureItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
            end
        end
    end

    # Called at the end of using a move.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemEndOfMoveCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems.clone
        itemsToCheck.each do |item|
            if BattleHandlers.triggerEndOfMoveItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
            elsif BattleHandlers.triggerEndOfMoveStatRestoreItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
            end
        end
    end

    # Used for White Herb / Black Herb. Only called by Moody and Sticky
    # Web, as all other stat reduction happens because of/during move usage and
    # this handler is also called at the end of each move's usage.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemStatRestoreCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems.clone

        itemsToCheck.each do |item|
            if BattleHandlers.triggerEndOfMoveStatRestoreItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
            end
        end
    end

    def pbItemFieldEffectCheck
        itemsToCheck = activeItems.clone
        itemsToCheck.each do |item|
            pbHeldItemTriggered(item) if BattleHandlers.triggerFieldEffectItem(item, self, @battle)
        end
    end

    # Used for Adrenaline Orb. Called when Intimidate is triggered (even if
    # Intimidate has no effect on the Pokémon).
    def pbItemOnIntimidatedCheck
        itemsToCheck = activeItems.clone
        itemsToCheck.each do |item|
            pbHeldItemTriggered(item) if BattleHandlers.triggerItemOnIntimidated(item, self, @battle)
        end
    end
end
