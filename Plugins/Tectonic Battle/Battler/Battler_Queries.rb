#=============================================================================
# Queries about what the battler has
#=============================================================================
class PokeBattle_Battler
    def isSpecies?(species)
        return @pokemon&.isSpecies?(species)
    end

    def species_data
        return @pokemon&.species_data
    end

    def personalID
        return @pokemon&.personalID || -1
    end

    # Returns the active types of this Pokémon. The array should not include the
    # same type more than once, and should not include any invalid type numbers
    # (e.g. -1).
    def pbTypes(withType3 = false, allowIllusions = false)
        # If the pokemon is disguised as another pokemon, fake its type bars
        if allowIllusions && illusion?
            ret = disguisedAs.types
        else
            ret = [@type1]
            ret.push(@type2) if @type2 != @type1
        end
        ret = [@pokemon.itemTypeChosen] if itemActive? && hasItem?(:CRYSTALVEIL)
        # Type changes from ability
        eachActiveAbility do |abilityID|
            ret = BattleHandlers.triggerTypeCalcAbility(abilityID, self, ret)
        end
        # Extra types (used for a curse)
        if @pokemon
            @pokemon.extraTypes.each do |extraPkmnType|
                next if ret.include?(extraPkmnType)
                ret.push(extraPkmnType)
            end
        end
        # Burn Up erases the Fire-type.
        ret.delete(:FIRE) if effectActive?(:BurnUp)
        # Cold Conversion erases the Ice-type.
        ret.delete(:ICE) if effectActive?(:Sublimate)
        # Dry Heat erases the Water-type.
        ret.delete(:WATER) if effectActive?(:DryHeat)
        # Roost erases the Flying-type. If there are no types left, adds the Normal-
        # type.
        if effectActive?(:Roost)
            ret.delete(:FLYING)
            ret.push(:NORMAL) if ret.length.zero?
        end
        # Add the third type specially.
        ret.push(@effects[:Type3]) if withType3 && effectActive?(:Type3) && !ret.include?(@effects[:Type3])
        ret.uniq!
        ret.compact!
        return ret
    end

    def pbHasType?(type)
        return false unless type
        activeTypes = pbTypes(true)
        return activeTypes.include?(GameData::Type.get(type).id)
    end
    alias hasType? pbHasType?

    def pbHasOtherType?(type)
        return false unless type
        activeTypes = pbTypes(true)
        activeTypes.delete(GameData::Type.get(type).id)
        return activeTypes.length.positive?
    end

    # NOTE: Do not create any held item which affects whether a Pokémon's ability
    #       is active. The ability Klutz affects whether a Pokémon's item is
    #       active, and the code for the two combined would cause an infinite loop
    #       (regardless of whether any Pokémon actualy has either the ability or
    #       the item - the code existing is enough to cause the loop).
    def abilityActive?(ignore_fainted = false, ignore_gas = false)
        return false if fainted? && !ignore_fainted
        return false if !ignore_gas && @battle.abilitiesNeutralized?
        return false if effectActive?(:AbilitySupressed)
        return false if dizzy?
        return true
    end

    def abilities
        return @ability_ids
    end

    def firstAbility
        return @ability_ids.empty? ? nil : @ability_ids[0]
    end

    def firstAbilityData
        return GameData::Ability.try_get(firstAbility)
    end

    def eachAbility
        abilities.each do |abilityID|
            yield abilityID
        end
    end

    def eachActiveAbility(ignore_fainted = false, ignoreGas: false)
        return unless abilityActive?(ignore_fainted, ignoreGas)
        abilities.each do |abilityID|
            yield abilityID
        end
    end

    def hasAbility?(checkable)
        abilities.each do |ability|
            if checkable.is_a?(Array)
                return ability if checkable.include?(ability)
            else
                return ability if checkable == ability
            end
        end
        return false
    end

    def hasActiveAbility?(checkable, ignore_fainted = false, checkingForAI = false, ignoreGas: false)
        return hasActiveAbilityAI?(checkable, ignore_fainted) if checkingForAI
        return false unless abilityActive?(ignore_fainted, ignoreGas)
        return hasAbility?(checkable)
    end
    alias hasWorkingAbility hasActiveAbility?

    def hasActiveNeutralizingGas?(ignore_fainted = false)
        return false unless abilities.include?(:NEUTRALIZINGGAS)
        return abilityActive?(ignore_fainted, true)
    end

    # Returns whether the user has an immutable ability or not
    # and, if so, which ability it is
    def immutableAbility?
        eachAbility do |ability|
            return ability if GameData::Ability.get(ability).is_immutable_ability?
        end
        return false
    end

    TESTING_DOUBLE_QUALITIES = false

    def canAddItem?(item = nil, stolen = false)
        return false if fainted?

        # Pokemon can always have a single item
        if itemCount == 0
            return true if item.nil?
            return !isIllegalItem?(item)
        end
        
        # Sticky fingers is weird and needs it own check here
        if hasActiveAbility?(:STICKYFINGERS)
            return itemCount <= 1 && stolen
        end

        # Check for multi-item legality
        if item
            newItemSet = items.clone
            newItemSet.push(item)

            return legalItemSet?(newItemSet)
        end

        return false
    end

    def legalItemSet?(itemSet, showMessages = false)
        return true if itemSet.empty?

        # No pokemon is allowed more than 2 items
        return false if itemSet.length > 2

        # If just 1 item, check for its individual legality
        return allItemsLegal?(itemSet) if itemSet.length == 1

        # Must have a multi item ability to have more than 1 item
        hasMultiItemAbility = false
        eachActiveAbility do |ability|
            next unless GameData::Ability.get(ability).is_multiple_item_ability?
            hasMultiItemAbility = true
            break
        end
        return false unless hasMultiItemAbility

        # Cannot have duplicates of the same item
        return false if itemSet.length != itemSet.uniq.length

        # Must have a base pokemon to check for item set legality
        return false if @pokemon.nil?

        # Check for abilities that restrict which items you're allowed to have in multi-sets
        itemSetIsAllowed = true
        eachActiveAbility do |ability|
            next unless BattleHandlers.triggerDisallowItemSetAbility(ability, @pokemon, itemSet, showMessages)
            itemSetIsAllowed = false
            break
        end
        return itemSetIsAllowed
    end

    def allItemsLegal?(itemSet)
        allItemsLegal = true
        itemSet.each do |item|
            next unless isIllegalItem?(item)
            allItemsLegal = false
            break
        end
        return allItemsLegal
    end

    def isIllegalItem?(itemCheck, showMessages = false)
        # TODO: replace this check with an event-subscription
        # also use that same event trigger in the Pokemon class
        if itemCheck == :CRYSTALVEIL && hasActiveAbility?(:WONDERGUARD)
            pbMessage(_INTL("{1} can't hold a {2}!", pbThis, getItemName(:CRYSTALVEIL))) if showMessages
            return true
        end
        return false
    end

    def items
        return @pokemon.items
    end

    def itemCount
        return items.length
    end

    def itemCountD(uppercase = false)
        return @pokemon.itemCountD(uppercase)
    end

    def loseableItems
        losableItems = []
        items.each do |item|
            next if unlosableItem?(item)
            losableItems.push(item)
        end
        return losableItems
    end

    def losableItemCount
        return loseableItems.length
    end

    def firstItem
        return items.empty? ? nil : items[0]
    end

    def firstItemData
        return GameData::Item.try_get(firstItem)
    end

    def activeItems(ignoreFainted = false)
        return [] unless itemActive?(ignoreFainted)
        return items
    end

    def eachItem
        items.each do |itemID|
            next unless itemID
            yield itemID
        end
    end

    def eachItemWithName
        eachItem do |itemID|
            yield itemID,getItemName(itemID)
        end
    end

    def eachActiveItem(ignoreFainted = false)
        return unless itemActive?(ignoreFainted)
        eachItem do |itemID|
            yield itemID
        end
    end

    def itemActive?(ignoreFainted = false)
        return false if fainted? && !ignoreFainted
        return false if effectActive?(:Embargo)
        return false if pbOwnSide.effectActive?(:EmpoweredEmbargo)
        return false if hasActiveAbility?(:KLUTZ, ignoreFainted)
        return false if @battle.pbCheckOpposingAbility(%i[STRESSFUL], @index)
        return true
    end

    def hasAnyItem?
        return !items.empty?
    end

    def hasAnyBerry?
        items.each do |item|
            return true if GameData::Item.get(item).is_berry?
        end
        return false
    end

    def hasAnyGem?
        items.each do |item|
            return true if GameData::Item.get(item).is_gem?
        end
        return false
    end

    def hasNonInitialItem?
        items.each do |item|
            next if hasInitialItem?(item)
            return true
        end
        return false
    end

    def hasItem?(checkitem)
        items.each do |item|
            if checkitem.is_a?(Array)
                return item if checkitem.include?(item)
            else
                return item if checkitem == item
            end
        end
        return false
    end

    def hasActiveItem?(checkitem, ignore_fainted = false)
        return false unless itemActive?(ignore_fainted)
        return hasItem?(checkitem)
    end
    alias hasWorkingItem hasActiveItem?

    # Returns whether the specified item will be unlosable for this Pokémon.
    def unlosableItem?(checkitem, showMessages = false)
        return false unless checkitem
        return false if effectActive?(:Transform)
        # Items that change a Pokémon's form
        if mega? # Check if item was needed for this Mega Evolution
            return true if @pokemon.species_data.mega_stone == checkitem
        else # Check if item could cause a Mega Evolution
            GameData::Species.each do |data|
                next if data.species != @species || data.unmega_form != @form
                return true if data.mega_stone == checkitem
            end
        end
        if %i[FRAGILELOCKET LUNCHBOX].include?(checkitem)
            @battle.pbDisplay(_INTL("But {1} hold's tightly onto its {2}!", pbThis(false), getItemName(checkitem))) if showMessages
            return true
        end
        # Other unlosable items
        eachAbility do |ability|
            return true if GameData::Item.get(checkitem).unlosable?(@species, ability)
        end
        return false
    end

    def eachMove(&block)
        @moves.each(&block)
    end

    def eachMoveWithIndex(&block)
        @moves.each_with_index(&block)
    end

    def pbHasMove?(move_id)
        return false unless move_id
        eachMove { |m| return true if m.id == move_id }
        return false
    end

    def pbHasMoveType?(check_type)
        return false unless check_type
        check_type = GameData::Type.get(check_type).id
        eachMove { |m| return true if m.type == check_type }
        return false
    end

    def pbHasMoveFunction?(*arg)
        return false unless arg
        eachMove do |m|
            arg.each { |code| return true if m.function == code }
        end
        return false
    end

    def hasMoldBreaker?
        return hasActiveAbility?(GameData::Ability.getByFlag("MoldBreaking"))
    end

    def activatesTargetAbilities?(aiCheck = false)
        return false if shouldItemApply?(:PROXYFIST,aiCheck)
        return false if shouldAbilityApply?(:AFROTECTION, aiCheck)
        return false if shouldAbilityApply?(:JUGGERNAUT, aiCheck)
        return true
    end

    def activatesTargetItem?(aiCheck = false)
        return false if shouldItemApply?(:PROXYFIST,aiCheck)
        return false if shouldAbilityApply?(:AFROTECTION, aiCheck)
        return true
    end

    def activatesTargetEffects?(aiCheck = false)
        return false if shouldItemApply?(:PROXYFIST,aiCheck)
        return false if shouldAbilityApply?(:AFROTECTION, aiCheck)
        return true
    end

    def canChangeType?
        return !hasActiveAbility?(%i[MULTITYPE RKSSYSTEM])
    end

    def canChangeTypeTo?(type, showMoveFailure = false)
        typeData = GameData::Type.try_get(type)
        if typeData.nil?
            if showMoveFailure
                yield _INTL("{1}-type doesn't exist!", type)
            end
            return false
        end
        if pbHasType?(type)
            if showMoveFailure
                yield _INTL("{1} is already {2}-type!", pbThis(true), typeData.name)
            end
            return false
        end
        unless canChangeType?
            if showMoveFailure
                yield _INTL("{1} can't have its type changed!", pbThis(true))
            end
            return false
        end
        return true
    end

    def airborne?(checkingForAI = false)
        return false if shouldItemApply?(:IRONBALL,checkingForAI)
        return false if effectActive?(:Ingrain)
        return false if effectActive?(:SmackDown)
        return false if @battle.gravityIntensified?
        return true if shouldTypeApply?(:FLYING, checkingForAI)
        return true if hasLevitate?(checkingForAI) && !@battle.moldBreaker
        return true if shouldItemApply?(GameData::Item.getByFlag("Levitation"),checkingForAI)
        return true if effectActive?(:MagnetRise)
        return true if effectActive?(:Telekinesis)
        return false
    end

    def hasLevitate?(checkingForAI = false)
        return shouldAbilityApply?(GameData::Ability.getByFlag("Levitation"), checkingForAI)
    end

    def takesIndirectDamage?(showMsg = false, aiCheck = false)
        return false if fainted?
        %i[MAGICGUARD LASTGASP].each do |indirectDamageBlockingAbility|
            next unless shouldAbilityApply?(indirectDamageBlockingAbility, aiCheck)
            if showMsg
                showMyAbilitySplash(indirectDamageBlockingAbility)
                @battle.pbDisplay(_INTL("{1} is unaffected!", pbThis))
                hideMyAbilitySplash
            end
            aiLearnsAbility(indirectDamageBlockingAbility) unless aiCheck
            return false
        end
        return true
    end

    def takesRecoilDamage?(aiCheck = false)
        return false if shouldAbilityApply?(%i[ROCKHEAD AFROTECTION], aiCheck)
        return false unless takesIndirectDamage?(false, aiCheck)
        return true
    end

    def canHeal?(overheal = false)
        return false if fainted?
        if overheal
            return false if @hp >= @totalhp * 2
        else
            return false if @hp >= @totalhp
        end
        return false if effectActive?(:HealBlock)
        return true
    end

    def movedThisRound?
        return @lastRoundMoved && @lastRoundMoved == @battle.turnCount
    end

    def usingMultiTurnAttack?
        @effects.each do |effect, value|
            effectData = GameData::BattleEffect.get(effect)
            next unless effectData.multi_turn_tracker?
            return true if effectData.active_value?(value)
        end
        return false
    end

    def usingAttackThisTurn?
        if usingMultiTurnAttack? && @currentMove
            return PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(@currentMove)).damagingMove?
        end
        return @battle.choices[@index][0] == :UseMove && @battle.choices[@index][2].damagingMove?
    end

    def usingStatusThisTurn?
        if usingMultiTurnAttack? && @currentMove
            return PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(@currentMove)).statusMove?
        end
        return @battle.choices[@index][0] == :UseMove && @battle.choices[@index][2].statusMove?
    end

    def inTwoTurnAttack?(*arg)
        return false unless effectActive?(:TwoTurnAttack)
        ttaFunction = GameData::Move.get(@effects[:TwoTurnAttack]).function_code
        arg.each { |a| return true if a == ttaFunction }
        return false
    end

    def inTwoTurnSkyAttack?
        return inTwoTurnAttack?(
                "TwoTurnAttackInvulnerableInSky",
                "TwoTurnAttackInvulnerableInSkyNumbTarget",
                "TwoTurnAttackInvulnerableInSkyRecoilQuarterOfDamageDealt",
                "TwoTurnAttackInvulnerableScalesFaster",
                "TwoTurnAttackInvulnerableJinxFrostbite"
            )
    end

    def semiInvulnerable?
        return inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
        "TwoTurnAttackInvulnerableUnderground",
        "TwoTurnAttackInvulnerableUnderwater",
        "TwoTurnAttackInvulnerableInSkyNumbTarget",
        "TwoTurnAttackInvulnerableRemoveProtections",
        "TwoTurnAttackInvulnerableInSkyRecoilQuarterOfDamageDealt",
        "TwoTurnAttackInvulnerableScalesFaster",
        "TwoTurnAttackInvulnerableJinxFrostbite")
    end

    def pbEncoredMoveIndex
        return -1 unless effectActive?(:Encore)
        ret = -1
        eachMoveWithIndex do |m, i|
            next if m.id != @effects[:EncoreMove]
            ret = i
            break
        end
        return ret
    end

    def initialItems
        return @battle.initialItems[@index & 1][@pokemonIndex] || []
    end

    def setInitialItems(newItem)
        if newItem.nil?
            @battle.initialItems[@index & 1][@pokemonIndex] = []
        elsif newItem.is_a?(Array)
            @battle.initialItems[@index & 1][@pokemonIndex] = newItem
        else
            @battle.initialItems[@index & 1][@pokemonIndex] = [newItem]
        end
    end

    def hasInitialItem?(item)
        return initialItems.include?(item)
    end

    def removeNonInitialItems
        prunedItems = items.delete_if { |item|
            next false if hasInitialItem?(item)
            echoln("Removing non-initial item #{item} from #{pbThis(true)}.")
            next true
        }
        setItems(prunedItems)
    end

    def shouldStoreStolenItem?(item)
        return @battle.wildBattle? && opposes? && !@battle.bossBattle? && hasInitialItem?(item)
    end

    def recyclableItem
        return @battle.recycleItems[@index & 1][@pokemonIndex]
    end

    def setRecycleItem(newItem)
        @battle.recycleItems[@index & 1][@pokemonIndex] = newItem
    end

    def belched?
        return @battle.belch[@index & 1][@pokemonIndex]
    end

    def setBelched
        @battle.belch[@index & 1][@pokemonIndex] = true
    end

    def lustered?
        return @battle.luster[@index & 1][@pokemonIndex]
    end

    def setLustered
        @battle.luster[@index & 1][@pokemonIndex] = true
    end

    def moveUsageCount(moveID)
        moveUsageCountHash = @battle.moveUsageCount[@index & 1][@pokemonIndex]
        if moveUsageCountHash.key?(moveID)
            return moveUsageCountHash[moveID]
        else
            return 0
        end
    end

    def increaseMoveUsageCount(moveID)
        # For battlers summoned partway through the battle
        if @battle.moveUsageCount[@index & 1][@pokemonIndex].nil?
            @battle.moveUsageCount[@index & 1][@pokemonIndex] = {}
        end

        moveUsageCountHash = @battle.moveUsageCount[@index & 1][@pokemonIndex]
        if moveUsageCountHash.key?(moveID)
            moveUsageCountHash[moveID] += 1
        else
            moveUsageCountHash[moveID] = 0
        end
    end

    def empowered?
        return @avatarPhase > 1
    end

    def resetExtraMovesPerTurn
        @pokemon.extraMovesPerTurn = GameData::Avatar.get(@species).num_turns - 1
    end

    def hpBasedEffectResistance
        return 1.0 unless boss?
        return 1.0 / (@pokemon.hpMult.to_f || DEFAULT_BOSS_HP_MULT.to_f)
    end

    def evenTurn?
        return @battle.turnCount.even?
    end

    def oddTurn?
        return @battle.turnCount.odd?
    end

    def lastTurnThisRound?
        return @battle.commandPhasesThisRound == extraMovesPerTurn
    end

    def firstTurnThisRound?
        return @battle.firstTurnThisRound?
    end

    # Turn check starts at 1
    def nthTurnThisRound?(turnCheck)
        raise _INTL("nthTurnThisRound checks for turns 1 or above!") if turnCheck <= 0
        return @battle.commandPhasesThisRound == (turnCheck - 1)
    end

    def isLastAlive?
        if @battle.wildBattle? && opposes?
            return !hasAlly?
        end
        return false if fainted?
        return @battle.pbGetOwnerFromBattlerIndex(@index).able_pokemon_count == 1
    end

    def protectedAgainst?(user, move)
        holdersToCheck = [self, pbOwnSide]
        holdersToCheck.each do |effectHolder|
            effectHolder.eachEffect(true) do |_effect, _value, data|
                next unless data.is_protection?
                if data.protection_info&.has_key?(:does_negate_proc)
                    return data.protection_info[:does_negate_proc].call(user, self, move, @battle)
                else
                    return true
                end
            end
        end
        return false
    end

    def canGulpMissile?
        return @species == :CRAMORANT && hasActiveAbility?(:GULPMISSILE) && @form.zero?
    end

    def bunkeringDown?(checkingForAI = false)
        return shouldAbilityApply?(:BUNKERDOWN, checkingForAI) && @hp == @totalhp
    end

    def getRoomDuration(baseDuration = 8, aiCheck: false)
        ret = baseDuration
        ret *= 2 if shouldItemApply?(:REINFORCINGROD,aiCheck)
        ret = (ret.to_f * 1.5).floor if hasTribeBonus?(:SERENE)
        return ret
    end

    def getScreenDuration(baseDuration = 5,aiCheck: false)
        ret = baseDuration
        ret += 3 if shouldItemApply?(:LIGHTCLAY,aiCheck)
        ret += 6 if shouldItemApply?(:BRIGHTCLAY,aiCheck)
        ret += 2 if shouldAbilityApply?(:PLANARVEIL,aiCheck)
        ret = (ret.to_f * 1.5).floor if hasTribeBonus?(:SERENE)
        return ret
    end

    def firstTurn?
        return @turnCount <= 1
    end

    def substituted?
        return effectActive?(:Substitute)
    end

    # Only to be called during hit or post-most-use triggers
    def knockedBelowHalf?
        return @damageState.initialHP >= @totalhp / 2 && @hp < @totalhp / 2
    end
    
    def avatarData
        return GameData::Avatar.get_from_pokemon(@pokemon)
    end

    def avatarPhaseLowerHealthBound
        raise _INTL("#{@name} isn't an avatar, but something is requesting its Phase Lower Health Bound!") unless boss?
        avatarHPFraction = 1 - (@avatarPhase / avatarData.num_phases.to_f)
        return (@totalhp * avatarHPFraction).floor
    end

    def avatarHealthPerPhase
        raise _INTL("#{@name} isn't an avatar, but something is requesting its Health Per Phase!") unless boss?
        return (@totalhp / avatarData.num_phases.to_f).ceil
    end

    #=============================================================================
    # Methods relating to this battler's position on the battlefield
    #=============================================================================
    # Returns whether the given position belongs to the opposing Pokémon's side.
    def opposes?(i = 0)
        i = i.index if i.respond_to?("index")
        return (@index & 1) != (i & 1)
    end

    # Returns whether the given position/battler is near to self.
    def near?(i)
        i = i.index if i.respond_to?("index")
        return @battle.nearBattlers?(@index, i)
    end

    # Returns whether self is owned by the player.
    def pbOwnedByPlayer?
        return @battle.pbOwnedByPlayer?(@index)
    end

    def wildParty?
        return owner&.wild?
    end

    # Returns 0 if self is on the player's side, or 1 if self is on the opposing
    # side.
    def idxOwnSide
        return @index & 1
    end

    # Returns 1 if self is on the player's side, or 0 if self is on the opposing
    # side.
    def idxOpposingSide
        return (@index & 1) ^ 1
    end

    # Returns the data structure for this battler's side.
    def pbOwnSide
        return @battle.sides[idxOwnSide]
    end

    # Returns the data structure for the opposing Pokémon's side.
    def pbOpposingSide
        return @battle.sides[idxOpposingSide]
    end

    def position
        return @battle.positions[@index]
    end

    # Yields each unfainted ally Pokémon.
    def eachAlly(nearOnly = false)
        eachOther(nearOnly) do |b|
            next if b.opposes?(@index)
            yield b
        end
    end

    # Yields each unfainted opposing Pokémon.
    def eachOpposing(nearOnly = false)
        eachOther(nearOnly) do |b|
            next unless b.opposes?(@index)
            yield b
        end
    end

    # Yields each other unfainted battler
    def eachOther(nearOnly = false)
        @battle.battlers.each do |b|
            next if b.nil?
            next if b.index == @index # Ignore the self
            next if nearOnly && !near?(b)
            next if b.fainted?
            yield b
        end
    end

    # Returns the battler that is most directly opposite to self. unfaintedOnly is
    # whether it should prefer to return a non-fainted battler.
    def pbDirectOpposing(unfaintedOnly = false)
        @battle.pbGetOpposingIndicesInOrder(@index).each do |i|
            next unless @battle.battlers[i]
            break if unfaintedOnly && @battle.battlers[i].fainted?
            return @battle.battlers[i]
        end
        # Wanted an unfainted battler but couldn't find one; make do with a fainted
        # battler
        @battle.pbGetOpposingIndicesInOrder(@index).each do |i|
            return @battle.battlers[i] if @battle.battlers[i]
        end
        return @battle.battlers[(@index ^ 1)]
    end

    def owner
        return nil if @battle.wildBattle? && @battle.opposes?(@index)
        return @battle.pbGetOwnerFromBattlerIndex(@index)
    end

    # Checks for trainer ID match, so won't return yes if e.g. the pokemon was traded for
    def ownedByPlayer?
        return false unless @pokemon
        return @pokemon.ownedByPlayer?
    end

    def ownerParty
        return @battle.pbParty(@index)
    end

    def ownerLevelCap
        if pbOwnedByPlayer?
            return getLevelCap
        else
            highestLevel = 0
            ownerParty.each do |pkmn|
                next unless pkmn
                next unless pkmn.level > highestLevel
                highestLevel = pkmn.level
            end
            return highestLevel
        end
    end

    def hasTribeBonus?(tribeID)
        return false unless owner
        return owner.tribalBonus.hasTribeBonus?(tribeID)
    end

    def partyIndex
        return @index % 2
    end

    def typeMod(type, target, move, aiCheck = false)
        if aiCheck
            return @battle.battleAI.pbCalcTypeModAI(type, self, target, move)
        else
            return @damageState.typeMod
        end
    end

    def hpFraction
        return @hp / @totalhp.to_f
    end

    def fullHealth?
        return @hp >= @totalhp
    end

    def aboveHalfHealth?
        return @hp > @totalhp / 2
    end

    def belowHalfHealth?
        return @hp <= @totalhp / 2
    end

    def maxOverhealingPossible
        return (@totalhp * 2) - @hp  
    end

    def overhealed?
        return @hp > @totalhp
    end

    def getWeatherSettingDuration(weatherType, baseDuration = 4, ignoreFainted = false)
        duration = baseDuration
        if duration > 0
            eachActiveItem(true) do |item|
                duration = BattleHandlers.triggerWeatherExtenderItem(item, weatherType, duration, self, @battle)
            end
        end
        duration = (duration.to_f * 1.5).floor if hasTribeBonus?(:SERENE)
        return duration
    end

    def ignoreScreens?(checkingForAI)
        return true if shouldAbilityApply?(GameData::Ability.getByFlag("IgnoreScreens"),checkingForAI)
        return false
    end

    def canBeDisabled?(show_messages = false, move = nil)
        return false if move&.empoweredMove? && boss?
        return false if move&.pbMoveFailedAromaVeil?(nil, self, show_messages)
        return false if fainted?
        return false if effectActive?(:Disable)
        regularMove = nil
        eachMove do |m|
            next if m.id != @lastRegularMoveUsed
            regularMove = m
            break
        end
        return false unless regularMove
        return false if regularMove.pp == 0 && regularMove.total_pp > 0
        return true
    end

    def immuneToHazards?(aiCheck = false)
        if shouldItemApply?(:HEAVYDUTYBOOTS,aiCheck)
            aiLearnsItem(:HEAVYDUTYBOOTS) unless aiCheck
            return true
        end
        return shouldAbilityApply?(GameData::Ability.getByFlag("HazardImmunity"), aiCheck)
    end

    def hasGem?
        eachActiveItem do |item|
            return true if GameData::Item.get(item).is_gem?
        end
        return false
    end

    def trapped?
        return @battle.pbIsTrapped?(@index)
    end

    def legalAbilities
        return @pokemon.species_data.legalAbilities
    end

    def eachLegalAbility
        @pokemon.species_data.legalAbilities.each do |abilityID|
            yield abilityID
        end
    end

    def protectedByScreen?
        pbOwnSide.eachEffect(true) do |effect, _value, data|
            next unless data.is_screen?
            return true
        end
        return false
    end

    def healingReversed?(showMessages = false)
        if effectActive?(:HealingReversed)
            @battle.pbDisplay(_INTL("{1}'s healing is reversed!", pbThis)) if showMessages
            return true
        end
        if hasActiveAbility?(:AUTUMNAL)
            if showMessages
                showMyAbilitySplash(:AUTUMNAL)
                @battle.pbDisplay(_INTL("{1}'s healing is reversed!", pbThis))
                hideMyAbilitySplash
            end
            return true
        end
        badInfluencer = @battle.pbCheckOpposingAbility(:BADINFLUENCE,@index)
        if badInfluencer
            if showMessages
                badInfluencer.showMyAbilitySplash(:BADINFLUENCE)
                @battle.pbDisplay(_INTL("{1}'s healing is reversed!", pbThis))
                badInfluencer.hideMyAbilitySplash
            end
            return true
        end
        return false
    end

    def moveOutcomePredictor
        return @battle.scene.sprites["move_outcome_#{@index}"]
    end

    def hasEmpoweredStatusMove?
        getMoves.each do |move|
            next unless move
            next if move.damagingMove?(true)
            next unless move.empoweredMove?
            return true
        end
        return false
    end

    def getEmpoweredStatusMoves
        empoweredStatusMoves = []
        getMoves.each do |move|
            next unless move
            next if move.damagingMove?(true)
            next unless move.empoweredMove?
            empoweredStatusMoves.push(move)
        end
        return empoweredStatusMoves
    end

    def eachEmpoweredStatusMove
        getMoves.each_with_index do |move, index|
            next unless move
            next if move.damagingMove?(true)
            next unless move.empoweredMove?
            yield move, index
        end
    end
end