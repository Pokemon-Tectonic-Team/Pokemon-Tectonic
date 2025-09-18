class PokeBattle_Move
    def shouldHighlight?(user, target)
        if damagingMove?(true)
            bpAgainstTarget = predictedBasePower(user, target)
            if @baseDamage == 1
                return bpAgainstTarget >= 100
            else
                return bpAgainstTarget > @baseDamage
            end
        end
        return false
    end

    def predictedBasePower(user, target)
        return pbBaseDamageAI(@baseDamage, user, target)
    end

    def shouldShade?(user, target)
        return true if @pp == 0
        return true if pbMoveFailed?(user, [target], false)
        return true if pbFailsAgainstTargetAI?(user, target)
        return false
    end

    def applyRainDebuff?(user, type, checkingForAI = false)
        return false unless @battle.rainy?
        return false unless RAIN_DEBUFF_ACTIVE
        return false if immuneToRainDebuff?
        return false if %i[WATER ELECTRIC].include?(type)
        return user.debuffedByRain?(checkingForAI)
    end

    def applySunDebuff?(user, type, checkingForAI = false)
        return false unless @battle.sunny?
        return false unless SUN_DEBUFF_ACTIVE
        return false if immuneToSunDebuff?
        return false if %i[FIRE GRASS].include?(type)
        return user.debuffedBySun?(checkingForAI)
    end

    def inherentImmunitiesPierced?(user, target)
        return (user.boss? || target.boss?) && damagingMove? && (empoweredMove? || AVATARS_REGULAR_ATTACKS_PIERCE_IMMUNITIES)
    end

    def canRemoveItem?(user, target, item, checkingForAI: false)
        return false unless canKnockOffItems?(user, target, checkingForAI)
        return !target.unlosableItem?(item)
    end

    def canKnockOffItems?(user, target, checkingForAI = false, ignoreTargetFainted = false)
        if @battle.wildBattle? && user.opposes? && !user.boss # Wild Pokémon can't knock off, but bosses can
            return false
        end
        return false if user.fainted?
        return false if target.fainted? && !ignoreTargetFainted
        if checkingForAI
            return false if target.substituted?
        elsif target.damageState.unaffected || target.damageState.substitute
            return false
        end
        return false unless target.hasAnyItem?
        return false if target.shouldAbilityApply?(:STICKYHOLD, checkingForAI) && !@battle.moldBreaker
        return true
    end

    def canStealItem?(user, target, item, checkingForAI: false)
        return false if item.nil?
        return false unless canKnockOffItems?(user, target, checkingForAI, true)
        return false if target.unlosableItem?(item, !checkingForAI)
        return false if !user.canAddItem?(item, true) && @battle.trainerBattle?
        return false if user.unlosableItem?(item)
        return true
    end

    # Returns whether the item was removed
    # Can pass a block to overwrite the removal message and do other effects at the same time
    def knockOffItems(remover, victim, ability: nil, firstItemOnly: false, validItemProc: nil)
        return false unless canKnockOffItems?(remover, victim)
        battle.pbShowAbilitySplash(remover, ability) if ability
        if victim.hasActiveAbility?(:STICKYHOLD)
            battle.pbShowAbilitySplash(victim, :STICKYHOLD) if remover.opposes?(victim)
            battle.pbDisplay(_INTL("{1}'s {2} cannot be removed!", victim.pbThis, user.itemCountD))
            battle.pbHideAbilitySplash(victim) if remover.opposes?(victim)
            battle.pbHideAbilitySplash(remover) if ability
            return false
        end
        victim.eachItemWithName do |item, itemName|
            next if victim.unlosableItem?(item)
            next unless validItemProc.nil? || validItemProc.call(item)
            victim.removeItem(item)
            if block_given?
                yield item, itemName
            else
                removeMessage = _INTL("{1} forced {2} to drop their {3}!", remover.pbThis,
                    victim.pbThis(true), itemName)
                battle.pbDisplay(removeMessage)
            end
            break if firstItemOnly
        end
        battle.pbHideAbilitySplash(remover) if ability
        return true
    end

    # Returns whether the item was removed
    def stealItem(stealer, victim, item, ability: nil)
        return false unless canStealItem?(stealer, victim, item)
        @battle.pbShowAbilitySplash(stealer, ability) if ability
        if victim.hasActiveAbility?(:STICKYHOLD)
            @battle.pbShowAbilitySplash(victim, :STICKYHOLD) if stealer.opposes?(victim)
            @battle.pbDisplay(_INTL("{1}'s item cannot be stolen!", victim.pbThis))
            @battle.pbHideAbilitySplash(victim) if stealer.opposes?(victim)
            @battle.pbHideAbilitySplash(stealer) if ability
            return false
        end
        oldVictimItemName = getItemName(item)
        victim.removeItem(item)
        if @battle.stolenItemTurnsToDust?(item)
            @battle.pbDisplay(_INTL("{1}'s {2} turned to dust.", victim.pbThis, oldVictimItemName))
            @battle.pbHideAbilitySplash(stealer) if ability
        else
            @battle.pbDisplay(_INTL("{1} stole {2}'s {3}!", stealer.pbThis,
              victim.pbThis(true), oldVictimItemName))
            # Permanently steal items from wild pokemon
            if victim.shouldStoreStolenItem?(item)
                victim.setInitialItems(nil)
                pbReceiveItem(item)
                @battle.pbHideAbilitySplash(stealer) if ability
            else
                stealer.giveItem(item,true)
                @battle.pbHideAbilitySplash(stealer) if ability
                stealer.pbHeldItemTriggerCheck
            end
        end
        return true
    end

    def healStatus(pokemonOrBattler)
        if pokemonOrBattler.is_a?(PokeBattle_Battler)
            pokemonOrBattler.pbCureStatus
        elsif pokemonOrBattler.status != :NONE
            oldStatus = pokemonOrBattler.status
            pokemonOrBattler.status      = :NONE
            pokemonOrBattler.statusCount = 0
            PokeBattle_Battler.showStatusCureMessage(oldStatus, pokemonOrBattler, @battle)
        end
    end

    def selectPartyMemberForEffect(idxBattler, selectableProc = nil)
        if @battle.pbOwnedByPlayer?(idxBattler)
            return playerChoosesPartyMemberForEffect(idxBattler, selectableProc)
        else
            return trainerChoosesPartyMemberForEffect(idxBattler, selectableProc)
        end
    end

    def playerChoosesPartyMemberForEffect(idxBattler, selectableProc = nil)
        # Get player's party
        party = @battle.pbParty(idxBattler)
        partyOrder = @battle.pbPartyOrder(idxBattler)
        partyStart = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)[0]
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        # Start party screen
        pkmnScene = PokemonParty_Scene.new
        pkmnScreen = PokemonPartyScreen.new(pkmnScene, modParty)
        displayPartyIndex = -1
        # Loop while in party screen
        loop do
            # Select a Pokémon by showing the screen
            displayPartyIndex = pkmnScreen.pbChooseAblePokemon(selectableProc)
            next if displayPartyIndex < 0

            # Find the real party index after accounting for shifting around from swaps
            partyIndex = -1
            partyOrder.each_with_index do |pos, i|
                next if pos != displayPartyIndex + partyStart
                partyIndex = i
                break
            end
            next if partyIndex < 0

            # Make sure the selected pokemon isn't an active battler
            next if @battle.pbFindBattler(partyIndex, idxBattler)

            # Get the actual pokemon selection
            pkmn = party[partyIndex]

            # Don't allow invalid choices
            next if !pkmn || pkmn.egg?

            pkmnScene.pbEndScene
            return pkmn
        end
        pkmnScene.pbEndScene
        return nil
    end

    def trainerChoosesPartyMemberForEffect(idxBattler, selectableProc = nil)
        # Get trainer's party
        party = @battle.pbParty(idxBattler)
        party.each_with_index do |pokemon, partyIndex|
            # Don't allow invalid choices
            next if !pokemon || pokemon.egg?

            # Make sure the selected pokemon isn't an active battler
            next if @battle.pbFindBattler(partyIndex, idxBattler)

            return pokemon if selectableProc.call(pokemon)
        end
        return nil
    end

    def removeProtections(target)
        GameData::BattleEffect.each do |effectData|
            next unless effectData.is_protection?
            case effectData.location
            when :Battler
                target.disableEffect(effectData.id)
            when :Side
                target.pbOwnSide.disableEffect(effectData.id)
            end
        end
    end

    # Chooses a move category based on which attacking stat is higher (if no target is provided)
    # Or which will deal more damage to the target
    def selectBestCategory(user, target = nil)
        if target && targetIsUnaware?(target)
            real_attack = user.getFinalStat(:ATTACK, false, 0)
            real_special_attack = user.getFinalStat(:SPECIAL_ATTACK, false, 0)
        else
            real_attack = user.getFinalStat(:ATTACK)
            real_special_attack = user.getFinalStat(:SPECIAL_ATTACK)
        end
        if target
            if userIsUnaware?(user)
                real_defense = target.getFinalStat(:DEFENSE, false, 0)
                real_special_defense = target.getFinalStat(:SPECIAL_DEFENSE, false, 0)
            else
                real_defense = target.getFinalStat(:DEFENSE)
                real_special_defense = target.getFinalStat(:SPECIAL_DEFENSE)
            end
            # Perform simple damage calculation
            physical_damage = real_attack.to_f / real_defense
            special_damage = real_special_attack.to_f / real_special_defense
            # Determine move's category based on likely damage dealt
            if physical_damage == special_damage
                return @battle.pbRandom(2)
            else
                return (physical_damage > special_damage) ? 0 : 1
            end
        elsif real_attack == real_special_attack
            # Determine move's category
            return 0
        else
            return (real_attack > real_special_attack) ? 0 : 1
        end
    end

    def switchOutUser(user,switchedBattlers=[],disableMoldBreaker=true,randomReplacement=false,batonPass=false)
        return unless @battle.pbCanSwitch?(user.index)
        return unless @battle.pbCanChooseNonActive?(user.index)
        @battle.pbDisplay(_INTL("{1} went back to {2}!", user.pbThis, @battle.pbGetOwnerName(user.index)))
        @battle.pbPursuit(user.index)
        return if user.fainted?
        newPkmn = @battle.pbGetReplacementPokemonIndex(user.index) # Owner chooses
        return if newPkmn < 0
        @battle.pbRecallAndReplace(user.index, newPkmn, randomReplacement, batonPass)
        @battle.pbClearChoice(user.index) # Replacement Pokémon does nothing this round
        @battle.moldBreaker = false if disableMoldBreaker
        switchedBattlers.push(user.index)
        user.pbEffectsOnSwitchIn(true)
    end

    def forceOutTargets(user, targets, switchedBattlers, substituteBlocks: false, random: true, ability: nil, invertMissCheck: false)
        return if user.fainted?
        roarSwitched = []
        targets.each do |b|
            next if @battle.wildBattle? && b.opposes? # Can't force out wild pokemon or boss pokemon
            next if b.fainted?
            if invertMissCheck
                next unless b.damageState.unaffected
            else
                next if b.damageState.unaffected
            end
            next if switchedBattlers.include?(b.index)
            next if b.effectActive?(:Ingrain) || b.effectActive?(:EvilRoots)
            next if substituteBlocks && b.damageState.substitute
            next unless @battle.pbCanChooseNonActive?(b.index)
            @battle.pbShowAbilitySplash(user, ability) if ability
            newPkmn = @battle.pbGetReplacementPokemonIndex(b.index, random)
            next if newPkmn < 0
            @battle.pbRecallAndReplace(b.index, newPkmn, true)
            if random
                @battle.pbDisplay(_INTL("{1} was dragged out!", b.pbThis))
            else
                @battle.pbDisplay(_INTL("{1} switches in!", b.pbThis))
            end
            @battle.pbClearChoice(b.index)   # Replacement Pokémon does nothing this round
            switchedBattlers.push(b.index)
            roarSwitched.push(b.index)
            @battle.pbHideAbilitySplash(user) if ability
        end
        if roarSwitched.length > 0
            @battle.moldBreaker = false if roarSwitched.include?(user.index)
            @battle.pbPriority(true).each do |b|
                b.pbEffectsOnSwitchIn(true) if roarSwitched.include?(b.index)
            end
        end
    end

    def canExchangeItems?(user, target, show_message = false)
        unless target.hasAnyItem?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} doesn't have an item!", target.pbThis(true)))
            end
            return false
        end
        unless user.hasAnyItem?
            @battle.pbDisplay(_INTL("But it failed, since {1} doesn't have an item!", user.pbThis(true))) if show_message
            return false
        end
        if target.unlosableItem?(target.firstItem) ||
           target.unlosableItem?(user.firstItem) ||
           user.unlosableItem?(user.firstItem) ||
           user.unlosableItem?(target.firstItem)
            @battle.pbDisplay(_INTL("But it failed!")) if show_message
            return false
        end
        if user.firstItem == :PEARLOFWISDOM
             @battle.pbDisplay(_INTL("But it failed, since the Pearl of Fate cannot be exchanged!")) if show_message
            return false
        end
        if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
            if show_message
                @battle.pbShowAbilitySplash(target, ability)
                @battle.pbDisplay(_INTL("But it failed to affect {1}!", target.pbThis(true)))
                @battle.pbHideAbilitySplash(target)
            end
            return false
        end
        return true
    end

    def exchangeItems(user, target)
        return unless canExchangeItems?(user, target, false)
        oldUserItem = user.firstItem
        oldUserItemName = getItemName(oldUserItem)
        oldTargetItem = target.firstItem
        oldTargetItemName = getItemName(target.firstItem)
        user.removeItem(oldUserItem)
        target.removeItem(oldTargetItem)
        if @battle.stolenItemTurnsToDust?
            @battle.pbDisplay(_INTL("{1}'s {2} turned to dust.", user.pbThis, oldUserItemName)) if oldUserItem
            @battle.pbDisplay(_INTL("{1}'s {2} turned to dust.", target.pbThis, oldTargetItemName)) if oldTargetItem
        elsif !user.opposes? && target.shouldStoreStolenItem?(oldTargetItem)
            @battle.pbDisplay(_INTL("{1} switched items with its opponent!", user.pbThis))
            target.setInitialItems(nil)
            pbReceiveItem(oldTargetItem)
            target.giveItem(oldUserItem)
            @battle.pbDisplay(_INTL("{1} obtained {2}.", target.pbThis, oldUserItemName)) if oldUserItem
            target.pbHeldItemTriggerCheck
        else
            user.giveItem(oldTargetItem)
            target.giveItem(oldUserItem)
            @battle.pbDisplay(_INTL("{1} switched items with its opponent!", user.pbThis))
            @battle.pbDisplay(_INTL("{1} obtained {2}.", user.pbThis, oldTargetItemName)) if oldTargetItem
            @battle.pbDisplay(_INTL("{1} obtained {2}.", target.pbThis, oldUserItemName)) if oldUserItem
            user.pbHeldItemTriggerCheck
            target.pbHeldItemTriggerCheck
        end  
    end  
end
