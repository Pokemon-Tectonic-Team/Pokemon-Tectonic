class PokeBattle_Battle
    #=============================================================================
    # Store caught Pokémon
    #=============================================================================
    def pbStorePokemon(pkmn)
        # Store the Pokémon
        currentBox = @peer.pbCurrentBox
        storedBox = @peer.pbStorePokemon(pbPlayer, pkmn)
        if storedBox < 0
            pbDisplayPaused(_INTL("{1} has been added to your party.", pkmn.name))
            @initialItems[0][pbPlayer.party.length - 1] = pkmn.items.clone if @initialItems
            return
        end
        promptToTakeItems(pkmn)
        # Messages saying the Pokémon was stored in a PC box
        curBoxName = @peer.pbBoxName(currentBox)
        boxName    = @peer.pbBoxName(storedBox)
        if $PokemonStorage[currentBox].isDonationBox?
            pbDisplayPaused(_INTL("Box \"{1}\" on the Pokémon Storage PC is a donation box.", curBoxName))
            pbDisplayPaused(_INTL("{1} was transferred to box \"{2}\".", pkmn.name, boxName))
        elsif storedBox != currentBox
            pbDisplayPaused(_INTL("Box \"{1}\" on the Pokémon Storage PC was full.", curBoxName))
            pbDisplayPaused(_INTL("{1} was transferred to box \"{2}\".", pkmn.name, boxName))
        else
            pbDisplayPaused(_INTL("{1} was transferred to the Pokémon Storage PC.", pkmn.name))
            pbDisplayPaused(_INTL("It was stored in box \"{1}\".", boxName))
        end
    end

    # Register all caught Pokémon in the Pokédex, and store them.
    def pbRecordAndStoreCaughtPokemon
        @caughtPokemon.each do |pkmn|
            pbPlayer.pokedex.register(pkmn) # In case the form changed upon leaving battle

            # Let the player know info about the individual pokemon they caught
            pbDisplayWithFormatting(_INTL("You check {1}, and discover that its ability is <imp>{2}</imp>!", pkmn.name, pkmn.ability.name))

            itemsToRemove = []
            pkmn.items.each do |item|
                if GameData::Item.get(item).super
                    itemsToRemove.push(item)
                else
                    pbDisplayWithFormatting(_INTL("The {1} is holding an <imp>{2}</imp>!", pkmn.name, getItemName(item)))
                end
            end

            itemsToRemove.each do |itemToRemove|
                pbDisplayPaused(_INTL("The {1} is holding an {2}!", pkmn.name, getItemName(itemToRemove)))
                pbDisplayPaused(_INTL("But it mysteriously crumbled to ash..."))
                pkmn.removeItem(itemToRemove)
            end

            # Record the Pokémon's species as owned in the Pokédex
            unless pbPlayer.owned?(pkmn.species)
                pbPlayer.pokedex.set_owned(pkmn.species)
                if $Trainer.has_pokedex
                    pbPlayer.pokedex.register_last_seen(pkmn)
                    if $Options.dex_shown_register == 0
                        pbDisplayPaused(_INTL("You register {1} as caught in the MasterDex.", pkmn.name))
                        @scene.pbShowPokedex(pkmn.species)
                    end
                end
            end

            # Increase the caught count for the global metadata
            incrementDexNavCounts(true)

            # Nickname the Pokémon
            showPrompt = (!defined?($Options.nicknaming_prompt) || $Options.nicknaming_prompt == 0)
            if showPrompt && pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?", pkmn.name))
                nickname = @scene.pbNameEntry(_INTL("{1}'s nickname?", pkmn.speciesName), pkmn)
                pkmn.name = nickname
            end

            # Check Party Size
            if $Trainer.party_full?
                # Y/N option to store newly caught
                if pbDisplayConfirmSerious(_INTL("Would you like to add {1} to your party?", pkmn.name))
                    pbDisplay(_INTL("Choose which Pokemon will be sent back to the PC."))
                    # if Y, select pokemon to store instead
                    pbChoosePokemon(1, 3)
                    chosenIndex = $game_variables[1]
                    # Didn't cancel
                    if chosenIndex != -1
                        chosenPokemon = $Trainer.party[chosenIndex]
                        @peer.pbOnLeavingBattle(self, chosenPokemon, @usedInBattle[0][chosenIndex], true) # Reset form

                        # Find the battler which matches with the chosen pokemon
                        chosenBattler = nil
                        eachSameSideBattler do |battler|
                            next unless battler.pokemon == chosenPokemon
                            chosenBattler = battler
                            break
                        end

                        # Handle the chosen pokemon leaving battle, if it was in battle
                        if !chosenBattler.nil?
                            chosenBattler.eachActiveAbility do |ability|
                                BattleHandlers.triggerAbilityOnSwitchOut(ability, chosenBattler, self, true)
                            end
                        end

                        chosenPokemon.setItems(@initialItems[0][chosenIndex])
                        @initialItems[0][chosenIndex] = pkmn.items

                        promptToTakeItems(chosenPokemon)

                        pbStorePokemon(chosenPokemon)
                        $Trainer.party[chosenIndex] = pkmn
                    else
                        # Store caught Pokémon if cancelled
                        pbStorePokemon(pkmn)
                    end
                else
                    # Store caught Pokémon
                    pbStorePokemon(pkmn)
                end
            else
                # Store caught Pokémon
                pbStorePokemon(pkmn)
            end

            evolutionButtonCheck(pkmn)
        end

        # Mentor moves tutorial
        if !@caughtPokemon.empty? && $Trainer.pokedex.owned_count >= 4 && !$PokemonGlobal.mentorMovesTutorialized
            playMentorshipTutorial
        end

        # Enable the PokEstate with a phonecall
        if getGlobalSwitch(ESTATE_DISABLED_SWITCH) && !getGlobalSwitch(ESTATE_PHONECALL_GLOBAL) && $Trainer.pokedex.owned_count >= 12
            $PokemonGlobal.shouldProcEstateCall = true
        end

        @caughtPokemon.clear
    end

    #=============================================================================
    # Throw a Poké Ball
    #=============================================================================
    def pbThrowPokeBall(idxBattler, ball, catch_rate = nil, showPlayer = false)
        # Determine which Pokémon you're throwing the Poké Ball at
        battler = nil
        if opposes?(idxBattler)
            battler = @battlers[idxBattler]
        else
            battler = @battlers[idxBattler].pbDirectOpposing(true)
        end
        if battler.fainted?
            battler.eachAlly do |b|
                battler = b
                break
            end
        end
        launching = ball == :BALLLAUNCHER
        # Messages
        itemName = GameData::Item.get(ball).name
        if launching
            pbDisplayBrief(_INTL("{1} used the {2}!", pbPlayer.name, itemName))
        elsif itemName.starts_with_vowel?
            pbDisplayBrief(_INTL("{1} threw an {2}!", pbPlayer.name, itemName))
        else
            pbDisplayBrief(_INTL("{1} threw a {2}!", pbPlayer.name, itemName))
        end
        if battler.fainted?
            pbDisplay(_INTL("But there was no target..."))
            return
        end
        # Animation of opposing trainer blocking Poké Balls
        if trainerBattle?
            @scene.pbThrowAndDeflect(ball, 1)
            pbDisplay(_INTL("The Trainer blocked your Poké Ball! Don't be a thief!"))
            return
        end
        # Calculate the number of shakes (4=capture)
        pkmn = battler.pokemon
        @criticalCapture = false
        numShakes = pbCaptureCalc(pkmn, battler, catch_rate, ball)
        # PBDebug.log("[Threw Poké Ball] #{itemName}, #{numShakes} shakes (4=capture)")
        # Animation of Ball throw, absorb, shake and capture/burst out
        velocityMult = launching ? 2.0 : 1.0
        @scene.pbThrow(ball, numShakes, @criticalCapture, battler.index, showPlayer, velocityMult)
        # Outcome message
        case numShakes
        when 0
            pbDisplay(_INTL("Oh no! The Pokémon broke free!"))
            BallHandlers.onFailCatch(ball, self, battler)
        when 1
            pbDisplay(_INTL("Aww! It appeared to be caught!"))
            BallHandlers.onFailCatch(ball, self, battler)
        when 2
            pbDisplay(_INTL("Aargh! Almost had it!"))
            BallHandlers.onFailCatch(ball, self, battler)
        when 3
            pbDisplay(_INTL("Gah! It was so close, too!"))
            BallHandlers.onFailCatch(ball, self, battler)
        when 4
            pbDisplayBrief(_INTL("Gotcha! {1} was caught!", pkmn.name))
            @scene.pbThrowSuccess # Play capture success jingle
            pbRemoveFromParty(battler.index, battler.pokemonIndex)
            # Gain Exp
            if Settings::GAIN_EXP_FOR_CAPTURE
                battler.captured = true
                pbGainExp
                battler.captured = false
            end
            battler.removeNonInitialItems
            battler.pbReset
            if pbAllFainted?(battler.index)
                @decision = trainerBattle? ? 1 : 4 # Battle ended by win/capture
            end
            # Modify the Pokémon's properties because of the capture
            BallHandlers.onCatch(ball, self, pkmn)
            pkmn.poke_ball = ball
            pkmn.makeUnmega if pkmn.mega?
            pkmn.makeUnprimal
            pkmn.record_first_moves
            # Reset form
            pkmn.forced_form = nil if MultipleForms.hasFunction?(pkmn.species, "getForm")
            @peer.pbOnLeavingBattle(self, pkmn, true, true)
            # Make the Poké Ball and data box disappear
            @scene.pbHideCaptureBall(idxBattler)
            # Save the Pokémon for storage at the end of battle
            @caughtPokemon.push(pkmn)
        end
        
        if numShakes < 4 && !launching && pbHasItem?(:MAGNETICGAUNTLET) && @magneticGauntletBallsRecovered == 0
            pbDisplayWithFormatting(_INTL("\\i[MAGNETICGAUNTLET]You recovered the lost {1} with the {2}!", getItemName(ball), getItemName(:MAGNETICGAUNTLET)))
            @magneticGauntletBallsRecovered += 1
            return false
        else
            return true
        end
    end

    #=============================================================================
    # Calculate how many shakes a thrown Poké Ball will make (4 = capture)
    #=============================================================================
    CATCH_BASE_CHANCE = 65_536

    def pbCaptureCalc(pkmn, battler, catch_rate, ball)
        return 4 if debugControl
        return 4 if BallHandlers.isUnconditional?(ball, self, battler)
        y = captureThresholdCalc(pkmn, battler, catch_rate, ball)
        # Critical capture check
        if Settings::ENABLE_CRITICAL_CAPTURES
            c = criticalCaptureChance
            # Calculate the number of shakes
            if c > 0 && pbRandom(100) < c && (pbRandom(CATCH_BASE_CHANCE) < y)
                @criticalCapture = true
                return 4
            end
        end
        # Calculate the number of shakes
        numShakes = 0
        for i in 0...4
            break if numShakes < i
            numShakes += 1 if pbRandom(CATCH_BASE_CHANCE) < y
        end
        return numShakes
    end

    def criticalCaptureChance
        c = 0
        numOwned = $Trainer.pokedex.owned_count
        if numOwned > 600
            c = 20
        elsif numOwned > 450
            c = 16
        elsif numOwned > 300
            c = 12
        elsif numOwned > 150
            c = 8
        elsif numOwned > 50
            c = 4
        end
        $PokemonBag.pbQuantity(:CATCHINGCHARM).times do
            c *= 2
        end
        return c
    end

    def captureThresholdCalc(pkmn, battler, catch_rate, ball)
        # Get a catch rate if one wasn't provided
        catch_rate ||= pkmn.species_data.catch_rate
        catch_rate = BallHandlers.modifyCatchRate(ball, catch_rate, self, battler)
        catch_rate = (catch_rate * 1.5).floor if ballMimicActive?
        return PokeBattle_Battle.captureThresholdCalcInternals(battler.status, battler.statusCount, battler.hp, battler.totalhp, catch_rate)
    end

    def captureChanceCalc(pkmn, battler, catch_rate, ball)
        return 1 if BallHandlers.isUnconditional?(ball, self, battler)
        y = captureThresholdCalc(pkmn, battler, catch_rate, ball)
        chancePerShake = y.to_f / CATCH_BASE_CHANCE.to_f
        overallChance = chancePerShake**4
        return overallChance
    end

    def self.captureThresholdCalcInternals(status, statusCount, current_hp, total_hp, catch_rate)
        # First half of the shakes calculation
        x = (((5 * total_hp) - (4 * current_hp)) * catch_rate.to_f) / (5 * total_hp) * 1.2

        # Calculation modifiers
        if status == :SLEEP
            x *= 2.0
        elsif status == :POISON
            x *= 1.25 + 0.5 * (statusCount / 2)
        elsif status != :NONE
            x *= 1.25
        end
        x = x.floor
        x = 1 if x < 1

        # Second half of the shakes calculation
        y = (CATCH_BASE_CHANCE / ((255.0 / x)**0.1875)).floor
        return y
    end
end

def ballMimicActive?
    $Trainer.party.each do |partyMember|
      next unless partyMember
      return true if partyMember.hasAbility?(:BALLMIMIC)
    end
    return false
end

def runCaptureTest(species = :MEWTWO,level = 50,hpPercentile = 0.2,status = :SLEEP,ball=:ULTRABALL,trialCount = 500)
    scene = pbNewBattleScene
    enemyTrainer = pbLoadTrainer(:BATTLEGIRL,"Tester")
    fakeBattle = PokeBattle_Battle.new(scene, $Trainer.party, enemyTrainer.party, [$Trainer], [enemyTrainer])
    fakeBattler = PokeBattle_Battler.new(fakeBattle, 0, true)
    pokemon = Pokemon.new(species,level)
    fakeBattler.pbInitializeFake(pokemon, 0)
    fakeBattler.status = status
    fakeBattler.hp = (fakeBattler.totalhp * hpPercentile).ceil

    echoln("\r\n")
    echoln("=========================================================================")
    echoln("Running capture test on species #{species} at level #{level}")
    echoln("with status #{status} at #{hpPercentile} HP fraction.")
    echoln("Ball mimic active? #{ballMimicActive?}")
    echoln("Critical capture chance? #{fakeBattle.criticalCaptureChance} percent with #{$PokemonBag.pbQuantity(:CATCHINGCHARM)} capture charms.")

    successes = 0
    trialCount.times do
        next if fakeBattle.pbCaptureCalc(pokemon, fakeBattler, nil, :ULTRABALL) < 4
        successes += 1
    end

    percentile = ((successes.to_f / trialCount.to_f) * 100).truncate(1)
    echoln("The pokemon was captured #{percentile} percent of the time in #{trialCount} trials.")
    echoln("=========================================================================")
end