PP_INCREASE_REPEAT_MOVES = false

class PokeBattle_Battler
    #=============================================================================
    # Change HP
    #=============================================================================
    def pbReduceHP(amt, anim = true, registerDamage = true, anyAnim = true)
        amt = amt.round
        amt = @hp if amt > @hp
        amt = 1 if amt < 1 && !fainted?
        oldHP = @hp
        self.hp -= amt
        PBDebug.log("[HP change] #{pbThis} lost #{amt} HP (#{oldHP}=>#{@hp})") if amt.positive?
        raise _INTL("HP less than 0") if @hp.negative?
        raise _INTL("HP greater than total HP") if @hp > @totalhp && oldHP <= @totalhp
        @battle.scene.pbHPChanged(self, oldHP, anim) if anyAnim && amt.positive? && !@battle.autoTesting
        @tookDamage = true if amt.positive? && registerDamage
        return amt
    end

    # Helper method for performing the two checks that are supposed to occur whenever the battler loses HP
    # From a special effect. E.g. sandstorm DOT, ability triggers
    # Returns whether or not the pokemon faints
    def pbHealthLossChecks(oldHP = -1)
        pbItemHPHealCheck
        if fainted?
            pbFaint
            return true
        elsif oldHP > -1
            pbAbilitiesOnDamageTaken(oldHP)
        end
        return false
    end

    # Helper method for performing the checks that are supposed to occur whenever the battler loses HP
    # From a special effect that occurs when entering the field (i.e. Stealth Rock)
    # Returns whether or not the pokemon was swapped out due to a damage taking ability
    def pbEntryHealthLossChecks(oldHP = -1)
        pbItemHPHealCheck
        if fainted?
            pbFaint
        elsif oldHP > -1
            return pbAbilitiesOnDamageTaken(oldHP)
        end
        return false
    end

    # Applies damage effects that are based on a fraction of the battler's total HP
    # Returns how much damage ended up dealt
    # Accounts for bosses taking reduced fractional damage
    def applyFractionalDamage(fraction, showDamageAnimation = true, basedOnCurrentHP = false, entryCheck = false, struggle: false, aiCheck: false)
        return 0 unless takesIndirectDamage? || struggle

        aggravate = @battle.pbCheckOpposingAbility(:AGGRAVATE, @index) && !struggle
        damageAmount = getFractionalDamageAmount(fraction,basedOnCurrentHP,aggravate: aggravate,struggle: struggle)
        
        if showDamageAnimation && !aiCheck && !@dummy
            @damageState.displayedDamage = damageAmount
            @battle.scene.pbDamageAnimation(self,0,true)
        end
        damageAmount = @hp if damageAmount > @hp
        if aiCheck
            return damageAmount
        else
            oldHP = @hp
            pbReduceHP(damageAmount, false)
            if @dummy
                return damageAmount
            else
                if entryCheck
                    swapped = pbEntryHealthLossChecks(oldHP)
                    return swapped
                else
                    pbHealthLossChecks(oldHP)
                    return damageAmount
                end
            end
        end
    end

    def getFractionalDamageAmount(fraction,basedOnCurrentHP=false,aggravate: false,struggle: false)
        return 0 unless takesIndirectDamage? || struggle
        fraction *= hpBasedEffectResistance if boss?
        fraction *= 1.5 if aggravate
        if basedOnCurrentHP
            damageAmount = @hp * fraction
        else
            damageAmount = @totalhp * fraction
        end
        unless struggle
            damageAmount *= 0.66 if hasTribeBonus?(:ANIMATED)
            damageAmount *= 0.5 if pbOwnSide.effectActive?(:NaturalProtection)
        end
        damageAmount = damageAmount.ceil
        return damageAmount
    end

    def recoilDamageMult(checkingForAI = false)
        multiplier = 1.0
        multiplier *= 0.66 if hasTribeBonus?(:ANIMATED)
        multiplier *= 0.5 if pbOwnSide.effectActive?(:NaturalProtection)
        multiplier /= 2 if shouldAbilityApply?(:UNBREAKABLE, checkingForAI)
        multiplier /= 2 if shouldAbilityApply?(:STONEMANE, checkingForAI)
        multiplier *= 2 if shouldAbilityApply?(:LINEBACKER, checkingForAI)
        return multiplier
    end

    def applyRecoilDamage(damage, showDamageAnimation = true, showMessage = true, recoilMessage = nil, cushionRecoil = false)
        return unless takesRecoilDamage?
        # return if @battle.pbAllFainted?(@idxOpposingSide)
        damage = (damage * recoilDamageMult).round
        damage = 1 if damage < 1
        if !cushionRecoil && hasActiveAbility?(:KICKBACK)
            showMyAbilitySplash(:KICKBACK)
            @battle.pbDisplay(_INTL("{1} is trying to use an ally to absorb the recoil!", pbThis))

            # Can be replaced
            if @battle.pbCanSwitch?(@index) && @battle.pbCanChooseNonActive?(@index)
                applyEffect(:KickbackSwap)
                position.applyEffect(:Kickback, @pokemonIndex)
                position.applyEffect(:KickbackAmount, damage)
                hideMyAbilitySplash
                return
            else
                @battle.pbDisplay(_INTL("But it couldn't swap into anybody!"))
                hideMyAbilitySplash
            end
        end

        oldHP = @hp
        recoilMessage = _INTL("{1} is damaged by recoil!", pbThis) if recoilMessage.nil?
        @battle.pbDisplay(recoilMessage) if showMessage
        pbReduceHP(damage, showDamageAnimation)

        if !cushionRecoil
            pbHealthLossChecks(oldHP)
        elsif pbEntryHealthLossChecks(oldHP)
            @battle.pbOnActiveOne(self)
        end
    end

    def pbRecoverHP(amt, anim = true, anyAnim = true, showMessage = true, customMessage = nil, canOverheal: false, items_to_skip: [], aiCheck: false)
        if @battle.autoTesting
            anim = false
            anyAnim = false
        end
        raise _INTL("Told to recover a negative amount") if amt.negative?

        # Apply healing modifiers
        amt *= 1.5 if hasActiveAbility?(:ROOTED)
        amt *= 2.0 if hasActiveAbilityAI?(:GLOWSHROOM) && @battle.moonGlowing?
        amt *= 0.5 if effectActive?(:IcyInjection)
        amt = amt.round

        # Cap the healing
        healthCap = @totalhp
        healthCap *= 2 if canOverheal
        maxHeal = healthCap - @hp
        amt = maxHeal if amt > maxHeal
        amt = 1 if amt < 1 && @hp < @totalhp

        # Nerve Break, Bad Influence
        if healingReversed?(showMessage && !aiCheck)
            amt *= -1
        elsif boss?
            if @hp <= avatarPhaseLowerHealthBound && @hp + amt > avatarPhaseLowerHealthBound # Cap boss healing at the next health boundary
                amt = avatarPhaseLowerHealthBound - @hp
            end
        end

        # Actually perform the HP change
        unless aiCheck
            oldHP = @hp
            self.hp += amt
            self.hp = 0 if self.hp.negative?
            PBDebug.log("[HP change] #{pbThis} gained #{amt} HP (#{oldHP}=>#{@hp})") if amt.positive?
            raise _INTL("HP greater than total HP") if @hp > @totalhp unless canOverheal
            anyAnim = false if @autoTesting
            @battle.scene.pbHPChanged(self, oldHP, anim) if anyAnim
            if showMessage
                if amt.positive?
                    message = customMessage.nil? ? _INTL("{1}'s HP was restored.", pbThis) : customMessage
                    @battle.pbDisplay(message)
                elsif amt.negative?
                    @battle.pbDisplay(_INTL("{1}'s lost HP.", pbThis))
                end
            end

            if amt.negative?
                pbItemHPHealCheck(items_to_skip: items_to_skip)
                pbAbilitiesOnDamageTaken(oldHP)
                pbFaint if fainted?
            end
        end
        return amt
    end

    def pbRecoverHPFromDrain(drainAmount, target, canOverheal: false)
        if target.hasActiveAbility?(:LIQUIDOOZE)
            @battle.pbShowAbilitySplash(target, :LIQUIDOOZE)
            oldHP = @hp
            pbReduceHP(drainAmount)
            @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!", pbThis))
            @battle.pbHideAbilitySplash(target)
            pbItemHPHealCheck
            pbAbilitiesOnDamageTaken(oldHP)
            pbFaint if fainted?
        elsif canHeal?(canOverheal || hasActiveAbility?(:GORGING))
            if hasActiveItem?(:BIGROOT)
                drainAmount = (drainAmount * 1.3).floor
                aiLearnsItem(:BIGROOT)
            end
            pbRecoverHP(drainAmount, true, true, false, canOverheal: canOverheal || hasActiveAbility?(:GORGING))
            if overhealed? && hasActiveAbility?(:GORGING) && !canOverheal
                showMyAbilitySplash(:GORGING)
                @battle.pbDisplay(_INTL("{1} is loaded up with fluids!", pbThis))
                hideMyAbilitySplash
            end
        end
    end

    def pbRecoverHPFromMultiDrain(targets, ratio, ability: nil, onlyCriticalDamage: false)
        totalDamageDealt = 0
        targets.each do |target|
            next if target.damageState.unaffected
            damage = onlyCriticalDamage ? target.damageState.totalHPLostCritical : target.damageState.totalHPLost
            if target.hasActiveAbility?(:LIQUIDOOZE)
                @battle.pbShowAbilitySplash(target, :LIQUIDOOZE)
                lossAmount = (damage * ratio).round
                pbReduceHP(lossAmount)
                @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!", pbThis))
                @battle.pbHideAbilitySplash(target)
                pbItemHPHealCheck
            else
                totalDamageDealt += damage
            end
        end
        return if totalDamageDealt <= 0 || !canHeal?(hasActiveAbility?(:GORGING))
        showMyAbilitySplash(ability) if ability
        drainAmount = (totalDamageDealt * ratio).round
        drainAmount = 1 if drainAmount < 1
        if hasActiveItem?(:BIGROOT)
            drainAmount = (drainAmount * 1.3).floor
            aiLearnsItem(:BIGROOT)
        end
        pbRecoverHP(drainAmount, true, true, false)
        hideMyAbilitySplash if ability
    end

    def applyFractionalHealing(fraction, ability: nil, anim: true, anyAnim: true, showMessage: true, customMessage: nil, item: nil, canOverheal: false, items_to_skip: [], aiCheck: false)
        return 0 unless canHeal?(canOverheal)
        if item && !aiCheck
            @battle.pbCommonAnimation("UseItem", self) unless @battle.autoTesting
            unless customMessage
                if fraction <= 1.0 / 8.0
                    customMessage = _INTL("{1} restored a little HP using its {2}!", pbThis, getItemName(item))
                else
                    customMessage = _INTL("{1} restored its health using its {2}!", pbThis, getItemName(item))
                end
            end
        end
        battle.pbShowAbilitySplash(self, ability) if ability && !aiCheck
        healAmount = getFractionalHealingAmount(fraction, canOverheal)
        actuallyHealed = pbRecoverHP(healAmount, anim, anyAnim, showMessage, customMessage, canOverheal: canOverheal, items_to_skip: items_to_skip, aiCheck: aiCheck)
        battle.pbHideAbilitySplash(self) if ability && !aiCheck
        if aiCheck
            return getHealingEffectScore(actuallyHealed)
        else
            return actuallyHealed
        end
    end

    def getFractionalHealingAmount(fraction, canOverheal = false)
        return 0 unless canHeal?(canOverheal)
        healAmount = @totalhp * fraction
        healAmount *= hpBasedEffectResistance if boss?
        return healAmount
    end

    def pbFaint(showMessage = true)
        unless fainted?
            PBDebug.log("!!!***Can't faint with HP greater than 0")
            return
        end
        return if @fainted # Has already fainted properly

        # In case the user is fainting from their own move
        # And consumed a gem, etc. in the use of that move
        consumeMoveTriggeredItems(self)

        if showMessage
            if boss?
                if isSpecies?(:PHIONE)
                    @battle.pbDisplayBrief(_INTL("{1} was defeated!", pbThis))
                else
                    @battle.pbDisplayBrief(_INTL("{1} was destroyed!", pbThis))
                end
            elsif afraid?
                @battle.pbDisplayBrief(_INTL("{1} flees in fear!", pbThis))
            else
                @battle.pbDisplayBrief(_INTL("{1} fainted!", pbThis))
            end
        end
        
        unless @dummy
            PBDebug.log("[Pokémon fainted] #{pbThis} (#{@index})") unless showMessage
            @battle.scene.pbFaintBattler(self) unless @battle.autoTesting

            # Trigger battler faint curses
            @battle.curses.each do |curse_policy|
                @battle.triggerBattlerFaintedCurseEffect(curse_policy, self, @battle)
            end

            @battle.triggerBattlerFaintedDialogue(self)

            if effectActive?(:GivingDragonRideTo, true)
                otherBattler = @battle.battlers[@effects[:GivingDragonRideTo]] # Do not switch to the helper method
                damageDealt = otherBattler.hp
                otherBattler.damageState.displayedDamage = damageDealt
                @battle.scene.pbDamageAnimation(otherBattler)
                otherBattler.pbReduceHP(damageDealt, false)
                @battle.pbDisplay(_INTL("{1} fell to the ground!", otherBattler.pbThis))
                otherBattler.pbFaint
            end

            # On-faint effect items
            if hasActiveItem?(:HOOHSASHES)
                faintedPartyMembers = []
                ownerParty.each do |partyPokemon|
                    next unless partyPokemon
                    next if @battle.pbFindBattler(partyIndex, @index)
                    next unless partyPokemon.fainted?
                    faintedPartyMembers.push(partyPokemon)
                end
                pbDisplay(_INTL("{1}'s scattered its {2} when fainting.", pbThis, getItemName(:HOOHSASHES)))
                if faintedPartyMembers.length == 0
                    pbDisplay(_INTL("But there was no one to revive!"))
                else
                    reviver = faintedPartyMembers.sample
                    reviver.heal_HP
                    reviver.heal_status
                    pbDisplay(_INTL("Its allied {1} was revived to full health!", reviver.name))
                end
            end

            pbInitEffects(false)
        end

        # # Reset status on the underlying pokemon
        @pokemon&.status = :NONE
        @pokemon&.statusCount = 0

        # Reset form
        @battle.peer.pbOnLeavingBattle(@battle, @pokemon, @battle.usedInBattle[idxOwnSide][@index / 2])
        @pokemon.makeUnmega if mega?
        @pokemon.makeUnprimal if primal?

        # Reset avatar phase progress
        @avatarPhase = 1
        self.bossType = nil # To trigger sprite refresh

        unless @dummy
            # Do other things
            @battle.pbClearChoice(@index) # Reset choice
            pbOwnSide.effects[:LastRoundFainted] = @battle.turnCount

            # Check other battlers' abilities that trigger upon a battler fainting
            pbAbilitiesOnFainting

            # Check for end of primordial weather
            @battle.pbEndPrimordialWeather

            # Trigger avatar AI
            @bossAI.onDestroyed(self, battle) if boss?
        end
    end

    #=============================================================================
    # Move PP
    #=============================================================================
    def pbSetPP(move, pp)
        move.pp = pp
        # Mimic
        move.realMove.pp = pp if move.realMove && move.id == move.realMove.id && !@effects[:Transform]
    end

    def pbReducePP(move)
        return true if boss? && move.empoweredMove?
        return true if usingMultiTurnAttack?
        return true if move.pp.negative? # Don't reduce PP for special calls of moves
        return true if move.total_pp <= 0 # Infinite PP, can always be used
        return false if move.pp.zero? # Ran out of PP, couldn't reduce
        reductionAmount = 1
        if PP_INCREASE_REPEAT_MOVES && (!boss? && @lastMoveUsed && @lastMoveUsed == move.id && !@lastMoveFailed)
            reductionAmount = 3
        end
        newPPAmount = [move.pp - reductionAmount, 0].max
        pbSetPP(move, newPPAmount)
        return true
    end

    def pbReducePPOther(move)
        pbSetPP(move, move.pp - 1) if move.pp.positive?
    end

    #=============================================================================
    # Change type
    #=============================================================================
    def pbChangeTypes(newType)
        if newType.is_a?(PokeBattle_Battler)
            typeCopyTarget = newType
            newTypes = typeCopyTarget.pbTypes
            newTypes.push(:NORMAL) if newTypes.length.zero?
            newType3 = typeCopyTarget.effects[:Type3]
            newType3 = nil if newTypes.include?(newType3)
            @type1 = newTypes[0]
            @type2 = (newTypes.length == 1) ? newTypes[0] : newTypes[1]
            if newType3
                applyEffect(:Type3, newType3)
            else
                disableEffect(:Type3)
            end
        elsif newType.is_a?(Array)
            @type1 = newType[0]
            @type2 = newType[1] if newType.length > 1
            applyEffect(:Type3, newType[2]) if newType.length > 2
        elsif GameData::Species.exists?(newType)
            speciesData = GameData::Species.get(newType)
            @type1 = speciesData.type1
            @type2 = speciesData.type2
            disableEffect(:Type3)
        else
            newType = GameData::Type.get(newType).id
            @type1 = newType
            @type2 = newType
            disableEffect(:Type3)
        end
        disableEffect(:BurnUp)
        disableEffect(:Sublimate)
        disableEffect(:Roost)
        refreshDataBox
    end

    #=============================================================================
    # Forms
    #=============================================================================
    def pbChangeForm(newForm, msg)
        return if fainted? || effectActive?(:Transform) || @form == newForm
        oldForm = @form
        oldDmg = @totalhp - @hp
        self.form = newForm
        pokemon.forced_form = newForm if boss?
        disableBaseStatEffects
        pbUpdate(true)
        @hp = @totalhp - oldDmg
        @hp = 1 if @hp < 1
        disableEffect(:WeightChange)
        @battle.scene.pbChangePokemon(self, @pokemon)
        refreshDataBox
        @battle.pbDisplay(msg) if msg && msg != ""
        PBDebug.log("[Form changed] #{pbThis} changed from form #{oldForm} to form #{newForm}")
        @battle.pbSetSeen(self)
    end

    def pbCheckFormOnStatusChange
        return if fainted? || effectActive?(:Transform)
    end

    def pbCheckFormOnMovesetChange
        return if fainted? || effectActive?(:Transform)
        # Keldeo - knowing Secret Sword
        if isSpecies?(:KELDEO)
            newForm = 0
            newForm = 1 if pbHasMove?(:SECRETSWORD)
            pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
        end
    end

    def pbCheckFormOnWeatherChange(abilityLossCheck = false)
        return if fainted? || effectActive?(:Transform)
        # Castform - Forecast
        if isSpecies?(:CASTFORM)
            if hasActiveAbility?(:FORECAST)
                newForm = 0
                case @battle.pbWeather
                when :Sunshine, :HarshSun   then newForm = 1
                when :Rainstorm, :HeavyRain then newForm = 2
                when :Hail             then newForm = 3
                when :Sandstorm        then newForm = 4
                when :Moonglow, :BloodMoon  then newForm = 5
                when :Eclipse, :RingEclipse then newForm = 6    
                end
                if @form != newForm
                    showMyAbilitySplash(:FORECAST, true)
                    hideMyAbilitySplash
                    pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
                end
            else
                pbChangeForm(0, _INTL("{1} transformed!", pbThis))
            end
        end
        # Cherrim - Flower Gift
        if isSpecies?(:CHERRIM)
            if hasActiveAbility?(:FLOWERGIFT)
                newForm = 0
                newForm = 1 if @battle.sunny?
                if @form != newForm
                    showMyAbilitySplash(:FLOWERGIFT, true)
                    hideMyAbilitySplash
                    pbChangeForm(newForm, _INTL("{1} transformed!", pbThis))
                end
            else
                pbChangeForm(0, _INTL("{1} transformed!", pbThis))
            end
        end
    end

    # Checks the Pokémon's form and updates it if necessary. Used for when a
    # Pokémon enters battle (endOfRound=false) and at the end of each round
    # (endOfRound=true).
    def pbCheckForm(endOfRound = false)
        return if fainted? || effectActive?(:Transform)
        # Form changes upon entering battle and when the weather changes
        pbCheckFormOnWeatherChange unless endOfRound
        # Darmanitan - Zen Mode
        if isSpecies?(:DARMANITAN) && hasAbility?(:ZENMODE)
            if @hp <= @totalhp / 2
                if @form != 1
                    showMyAbilitySplash(:ZENMODE, true)
                    hideMyAbilitySplash
                    pbChangeForm(1, _INTL("{1} triggered!", getAbilityName(:ZENMODE)))
                end
            elsif @form != 0
                showMyAbilitySplash(:ZENMODE, true)
                hideMyAbilitySplash
                pbChangeForm(0, _INTL("{1} triggered!", getAbilityName(:ZENMODE)))
            end
        end
        # Minior - Shields Down
        if isSpecies?(:MINIOR) && hasAbility?(:SHIELDSDOWN)
            if aboveHalfHealth? # Turn into Meteor form
                if form >= 7
                    newForm = @form - 7
                    showMyAbilitySplash(:SHIELDSDOWN, true)
                    pbChangeForm(newForm, _INTL("{1} deactivated!", getAbilityName(:SHIELDSDOWN)))
                    hideMyAbilitySplash
                end
            else # Turn into Core form
                if form < 7
                    showMyAbilitySplash(:SHIELDSDOWN, true)
                    hideMyAbilitySplash
                    pbChangeForm(@form + 7, _INTL("{1} activated!", getAbilityName(:SHIELDSDOWN)))
                end
            end
        end
        # Wishiwashi - Schooling
        if isSpecies?(:WISHIWASHI) && hasAbility?(:SCHOOLING)
            if @level >= 20 && @hp > @totalhp / 4
                if @form != 1
                    showMyAbilitySplash(:SCHOOLING, true)
                    hideMyAbilitySplash
                    pbChangeForm(1, _INTL("{1} formed a school!", pbThis))
                end
            elsif @form != 0
                showMyAbilitySplash(:SCHOOLING, true)
                hideMyAbilitySplash
                pbChangeForm(0, _INTL("{1} stopped schooling!", pbThis))
            end
        end
        # Zygarde - Power Construct
        if isSpecies?(:ZYGARDE) && hasAbility?(:POWERCONSTRUCT) && endOfRound && (@hp <= @totalhp / 2 && @form < 2) # Turn into Complete Forme
            newForm = @form + 2
            @battle.pbDisplay(_INTL("You sense the presence of many!"))
            showMyAbilitySplash(:POWERCONSTRUCT, true)
            hideMyAbilitySplash
            pbChangeForm(newForm, _INTL("{1} transformed into its Complete Forme!", pbThis))
        end
    end

    def disableBaseStatEffects
        disableEffect(:BaseAttack)
        disableEffect(:BaseSpecialAttack)
        disableEffect(:BaseDefense)
        disableEffect(:BaseSpecialDefense)
        disableEffect(:BaseSpeed)
    end

    def pbTransform(target)
        @battle.scene.pbChangePokemon(self, target.pokemon)

        oldAbilities = abilities.clone
        applyEffect(:Transform)
        applyEffect(:TransformSpecies, target.species)
        pbChangeTypes(target)
        if hasActiveItem?(:FRAGILELOCKET)
            setAbility(target.abilities)
        else
            setAbility(target.firstAbility)
        end
        @attack = target.attack
        @defense = target.defense
        @spatk = target.spatk
        @spdef = target.spdef
        @speed = target.speed
        GameData::Stat.each_battle { |s| @steps[s.id] = target.steps[s.id] }

        # Copy critical hit chance raising effects
        target.eachEffect do |effect, value, data|
            @effects[effect] = value if data.critical_rate_buff?
        end
        @moves.clear
        target.moves.each_with_index do |m, i|
            @moves[i] = PokeBattle_Move.from_pokemon_move(@battle, Pokemon::Move.new(m.id))
            aiSeesMove(@moves[i])
        end

        disableEffect(:Disable)
        disableBaseStatEffects
        @effects[:WeightChange] = target.effects[:WeightChange]
        refreshDataBox
        @battle.pbDisplay(_INTL("{1} transformed into {2}!", pbThis, target.pbThis(true)))
        pbOnAbilitiesLost(oldAbilities)

        # Trigger abilities
        pbEffectsOnSwitchIn
    end

    def transformSpecies(newSpecies)
        @battle.scene.pbChangePokemon(self, @pokemon, newSpecies)

        newSpeciesData = GameData::Species.get(newSpecies)
        applyEffect(:Transform)
        applyEffect(:TransformSpecies, newSpecies)
        pbChangeTypes(newSpecies)
        refreshDataBox
        @battle.pbDisplay(_INTL("{1} transformed into a {2}!", pbThis, newSpeciesData.name))
        legalAbilities = newSpeciesData.legalAbilities
        newAbility = legalAbilities[@pokemon.ability_index] || legalAbilities[0]
        replaceAbility(newAbility) unless hasAbility?(newAbility)

        newStats = @pokemon.getCalculatedStats(newSpecies)
        @attack  = newStats[:ATTACK]
        @defense = newStats[:DEFENSE]
        @spatk   = newStats[:SPECIAL_ATTACK]
        @spdef   = newStats[:SPECIAL_DEFENSE]
        @speed   = newStats[:SPEED]
        disableBaseStatEffects
    end

    def pbHyperMode; end

    def getSubLife(subFraction = 0.25)
        subLife = @totalhp * subFraction
        subLife *= hpBasedEffectResistance
        subLife = 1 if subLife < 1
        return subLife.floor
    end

    def createSubstitute(subFraction = 0.25)
        subLife = getSubLife(subFraction)
        pbReduceHP(subLife, false, false)
        pbItemHPHealCheck
        disableEffect(:Trapping)
        applyEffect(:Substitute, subLife)
    end

    #=============================================================================
    # Changing ability
    #=============================================================================

    def resetAbilities(initialization = false)
        prevAbilities = @ability_ids
        @ability_ids  = []
        @ability_ids.push(@pokemon.ability_id) if @pokemon.ability_id
        
        # Pokemon extra abilities (from curses and avatar shenanigans)
        @ability_ids.concat(@pokemon.extraAbilities)
        @addedAbilities.clear
        @addedAbilities.concat(@pokemon.extraAbilities)

        # Check for "has all legal ability" effects
        if initialization
            # Nothing can be disabling the item on initialization
            # And checking if the item is inactive leads to a crash
            # since the Embargo effect isn't initialized yet
            hasLocket = hasItem?(:FRAGILELOCKET)
        else
            hasLocket = hasActiveItem?(:FRAGILELOCKET)
        end
        if hasLocket || (@battle.curseActive?(:CURSE_DOUBLE_ABILITIES) && index.odd?)
            eachLegalAbility do |legalAbility|
                next if @ability_ids.include?(legalAbility)
                next if GameData::Ability.get(legalAbility).is_immutable_ability?
                @ability_ids.push(legalAbility)
                @addedAbilities.push(legalAbility)
            end
        end

        if !initialization && illusion? && hasActiveAbility?(:INCOGNITO)
            addIllusionAbilities
        end

        unless initialization
            pbOnAbilitiesLost(prevAbilities)
        end
    end

    def addIllusionAbilities
        return unless disguisedAs.ability 
        return if GameData::Ability.get(disguisedAs.ability_id).is_uncopyable_ability?
        @ability_ids.push(disguisedAs.ability_id)
        @addedAbilities.push(disguisedAs.ability_id)  
    end

    def setAbility(value)
        if value.is_a?(Array)
            validAbilities = []
            value.each do |newAbility|
                validAbilities.push(GameData::Ability.try_get(newAbility).id)
            end
            if validAbilities.length > 0
                @ability_ids = validAbilities
                @addedAbilities = @ability_ids.clone
            end
        else
            newability = GameData::Ability.try_get(value)
            @ability_ids = newability ? [newability.id] : []
            @addedAbilities = @ability_ids.clone
        end
    end

    def addAbility(newAbility,showcase = false)
        return if @ability_ids.include?(newAbility)
        newAbility = GameData::Ability.try_get(newAbility).id
        @ability_ids.push(newAbility)
        @addedAbilities.push(newAbility)
        if showcase
            showMyAbilitySplash(newAbility)
            @battle.pbDisplay(_INTL("{1} gained the Ability {2}!", pbThis, getAbilityName(newAbility)))
            hideMyAbilitySplash
        end
    end

    def replaceAbility(newAbility, showSplashes = true, swapper = nil, replacementMsg: nil)
        return if hasAbility?(newAbility)
        @battle.pbShowAbilitySplash(swapper, newAbility) if showSplashes && swapper
        oldAbil = firstAbility
        oldAbilities = abilities.clone
        oldAbilities.delete(newAbility)
        showMyAbilitySplash(oldAbil, true) if showSplashes
        setAbility(newAbility)
        @battle.pbReplaceAbilitySplash(self, newAbility) if showSplashes
        replacementMsg ||= _INTL("{1}'s Ability became {2}!", pbThis, getAbilityName(newAbility))
        @battle.pbDisplay(replacementMsg)
        hideMyAbilitySplash if showSplashes
        @battle.pbHideAbilitySplash(swapper) if showSplashes && swapper
        pbOnAbilitiesLost(oldAbilities) unless oldAbil.nil?
        pbEffectsOnSwitchIn
    end
end
