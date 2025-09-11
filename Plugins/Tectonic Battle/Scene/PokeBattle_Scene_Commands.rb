class PokeBattle_Scene
    #=============================================================================
    # The player chooses a main command for a Pokémon
    # Return values: -1=Cancel, 0=Fight, 1=Bag, 2=Pokémon, 3=Run, 4=Call
    #=============================================================================
    def pbCommandMenu(idxBattler,firstAction)
      cmds = [
        _INTL("",@battle.battlers[idxBattler].name),
        _INTL("Fight"),
        _INTL("Dex"),
        _INTL("Ball"),
        _INTL("Pokémon"),
        _INTL("Info"),
        firstAction ? _INTL("Run") : _INTL("Cancel"),
      ]
      wildBattle = !@battle.trainerBattle? && !@battle.bossBattle?
      mode = 0
      if firstAction
        if !wildBattle
          mode = 5
        else
          mode = 0
        end
      else
        mode = 1
      end
      ret = pbCommandMenuEx(idxBattler,cmds,mode)
      ret = -1 if ret == 5 && !firstAction   # Convert "Run" to "Cancel"
      ret = 6 if ret == 2 && !wildBattle
      return ret
    end
  

    # Mode: 0 = regular battle with "Run" (first choosable action in the round only)
    #       1 = regular battle with "Cancel"
    #       2 = regular battle with "Call" (for Shadow Pokémon battles)
    #       3 = Safari Zone
    #       4 = Bug Catching Contest
    #       5 = regular battle with "Forfeit" and "Info"
    def pbCommandMenuEx(idxBattler,texts,mode=0)
      pbShowWindow(COMMAND_BOX)
      cw = @sprites["commandWindow"]
      cw.setTexts(texts)
      initIndex = @lastCmd[idxBattler]
      initIndex = 0 if @lastCmd[idxBattler] == 3
      cw.setIndexAndMode(initIndex,mode)
      pbSelectBattler(idxBattler)
      ret = -1
      loop do
        oldIndex = cw.index
        pbUpdate(cw)
        # Update selected command
        if Input.trigger?(Input::LEFT)
          cw.index -= 1 if cw.index > 0
        elsif Input.trigger?(Input::RIGHT)
          cw.index += 1 if cw.index < 5
        elsif Input.trigger?(Input::UP)
          cw.index -= 3 if cw.index >= 3
        elsif Input.trigger?(Input::DOWN)
          cw.index += 3 if cw.index < 3
        end
        pbPlayCursorSE if cw.index!=oldIndex
        # Actions
        if Input.trigger?(Input::C)                 # Confirm choice
          pbPlayDecisionSE
          ret = cw.index
          @lastCmd[idxBattler] = ret
          break
        elsif Input.trigger?(Input::B)
          if mode == 1   # Cancel
            pbPlayCancelSE
            break
          elsif mode == 0 # Wild battles
            if cw.index == 5 # Run from battle
              pbPlayDecisionSE
              ret = 5
              @lastCmd[idxBattler] = 5
              break
            else # Move cursor to run button
              cw.index = 5
              pbPlayCursorSE if cw.index!=oldIndex
            end
          end
        elsif Input.trigger?(Input::F9) && $DEBUG    # Debug menu
          pbPlayDecisionSE
          ret = -2
          break
        elsif Input.pressex?(:NUMBER_1)
          pbPlayDecisionSE
          ret = 0
          @lastCmd[idxBattler] = 0
          break
        elsif Input.pressex?(:NUMBER_2)
          pbPlayDecisionSE
          ret = 1
          @lastCmd[idxBattler] = 1
          break
        elsif Input.pressex?(:NUMBER_3)
          pbPlayDecisionSE
          ret = 2
          @lastCmd[idxBattler] = 2
          break
        elsif Input.pressex?(:NUMBER_4)
          pbPlayDecisionSE
          ret = 3
          @lastCmd[idxBattler] = 3
          break
        elsif Input.pressex?(:NUMBER_5)
          pbPlayDecisionSE
          ret = 4
          @lastCmd[idxBattler] = 4
          break
        elsif Input.pressex?(:NUMBER_6)
          pbPlayDecisionSE
          ret = 5
          @lastCmd[idxBattler] = 5
          break
        end
      end
      return ret
    end
  
    #=============================================================================
    # The player chooses a move for a Pokémon to use
    #=============================================================================
    def pbFightMenu(idxBattler)
      battler = @battle.battlers[idxBattler]
      cw = @sprites["fightWindow"]
      cw.battler = battler
      moveIndex = 0
      if battler.getMoves[@lastMove[idxBattler]] && battler.getMoves[@lastMove[idxBattler]].id
        moveIndex = @lastMove[idxBattler]
      end
      cw.shiftMode = (@battle.pbCanShift?(idxBattler) && @battle.shiftEnabled) ? 1 : 0
      cw.setIndexAndMode(moveIndex,0)
      needFullRefresh = true
      needRefresh = false
      loop do
        # Refresh view if necessary
        if needFullRefresh
          pbShowWindow(FIGHT_BOX)
          pbSelectBattler(idxBattler)
          needFullRefresh = false
        end
        if needRefresh
          needRefresh = false
        end
        oldIndex = cw.index
        # General update
        pbUpdate(cw)
        # Update selected command
        if Input.trigger?(Input::LEFT)
          cw.index -= 1 if (cw.index&1)==1
        elsif Input.trigger?(Input::RIGHT)
          if battler.getMoves[cw.index+1] && battler.getMoves[cw.index+1].id
            cw.index += 1 if (cw.index&1)==0
          end
        elsif Input.trigger?(Input::UP)
          if (cw.index&2) == 2
            cw.index -= 2
          elsif battler.getMoves.length > Pokemon::MAX_MOVES && cw.index < 2
            cw.index += 4
          end
        elsif Input.trigger?(Input::DOWN)
          if battler.getMoves[cw.index+2] && battler.getMoves[cw.index+2].id
            cw.index += 2 if (cw.index&2)==0
          elsif cw.index >= Pokemon::MAX_MOVES
            cw.index -= 4
          end
        end
        pbPlayCursorSE if cw.index!=oldIndex
        # Actions
        if Input.trigger?(Input::USE)      # Confirm choice
          pbPlayDecisionSE
          break if yield cw.index
          needFullRefresh = true
          needRefresh = true
        elsif Input.trigger?(Input::BACK)   # Cancel fight menu
          pbPlayCancelSE
          break if yield -1
          needRefresh = true
        elsif Input.trigger?(Input::ACTION)   # Toggle Extra Move Info
          pbPlayDecisionSE
          cw.toggleExtraInfo()
          needRefresh = true
        elsif Input.trigger?(Input::SPECIAL)   # Shift
          if cw.shiftMode > 0 && @battle.doubleShift
            pbPlayDecisionSE
            break if yield -3
            needRefresh = true
          end
        end
      end
      @lastMove[idxBattler] = cw.index

      # Clear the move outcome predictor displays
      battler.eachOpposing do |opposingBattler|
        opposingBattler.moveOutcomePredictor&.clear
      end
    end
  
    #=============================================================================
    # Opens the party screen to choose a Pokémon to switch in (or just view its
    # summary screens)
    #=============================================================================
    def pbPartyScreen(idxBattler,canCancel=false)
      # Fade out and hide all sprites
      visibleSprites = pbFadeOutAndHide(@sprites)
      # Get player's party
      partyPos = @battle.pbPartyOrder(idxBattler)
      partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
      modParty = @battle.pbPlayerDisplayParty(idxBattler)
      # Start party screen
      scene = PokemonParty_Scene.new
      switchScreen = PokemonPartyScreen.new(scene,modParty)
      switchScreen.pbStartScene(_INTL("Choose a Pokémon."),@battle.pbNumPositions(0,0))
      # Loop while in party screen
      loop do
        # Select a Pokémon
        scene.pbSetHelpText(_INTL("Choose a Pokémon."))
        idxParty = switchScreen.pbChoosePokemon
        if idxParty<0
          next if !canCancel
          break
        end
        # Choose a command for the selected Pokémon
        cmdSwitch  = -1
        cmdSummary = -1
        cmdPokedex = -1
        commands = []
        commands[cmdSwitch  = commands.length] = _INTL("Switch In") if modParty[idxParty].able?(true)
        commands[cmdSummary = commands.length] = _INTL("Summary")
        commands[cmdPokedex = commands.length] = _INTL("MasterDex") if !modParty[idxParty].egg? && $Trainer.has_pokedex
        commands[commands.length]              = _INTL("Cancel")
        command = scene.pbShowCommands(_INTL("Do what with {1}?",modParty[idxParty].name),commands)
        if cmdSwitch >= 0 && command==cmdSwitch        # Switch In
          if modParty[idxParty].hasAbility?(:PACIFIST)
            pbMessage(_INTL("{1} refuses to join the battle. It's a pacifist!", modParty[idxParty].name))
          else
            idxPartyRet = -1
            partyPos.each_with_index do |pos,i|
              next if pos!=idxParty+partyStart
              idxPartyRet = i
              break
            end
            break if yield idxPartyRet, switchScreen
          end
        elsif cmdSummary >= 0 && command==cmdSummary   # Summary
          scene.pbSummary(idxParty,@battle)
        elsif cmdPokedex >= 0 && command==cmdPokedex
          openSingleDexScreen(modParty[idxParty])
        end
      end
      # Close party screen
      switchScreen.pbEndScene
      # Fade back into battle screen
      pbFadeInAndShow(@sprites,visibleSprites)
    end
  
    #=============================================================================
    # Opens the Bag screen and chooses an item to use
    #=============================================================================
    def pbItemMenu(idxBattler,_firstAction)
      # Fade out and hide all sprites
      visibleSprites = pbFadeOutAndHide(@sprites)
      # Set Bag starting positions
      oldLastPocket = $PokemonBag.lastpocket
      oldChoices    = $PokemonBag.getAllChoices
      $PokemonBag.lastpocket = @bagLastPocket if @bagLastPocket!=nil
      $PokemonBag.setAllChoices(@bagChoices) if @bagChoices!=nil
      # Start Bag screen
      itemScene = PokemonBag_Scene.new
      itemScene.pbStartScene($PokemonBag,true,Proc.new { |item|
          useType = GameData::Item.get(item).battle_use
          next useType && useType > 0
        },false)
      # Loop while in Bag screen
      wasTargeting = false
      loop do
        # Select an item
        itemSym = itemScene.pbChooseItem
        break if !itemSym
        # Choose a command for the selected item
        item = GameData::Item.get(itemSym)
        itemName = item.name
        useType = item.battle_use
        cmdUse = -1
        cmdChance = -1
        cmdCancel = -1
        commands = []
        commands[cmdUse = commands.length] = _INTL("Use") if useType && useType != 0
        commands[cmdChance = commands.length] = _INTL("Chance") if item.is_poke_ball?
        commands[cmdCancel = commands.length] = _INTL("Cancel")
        command = itemScene.pbShowCommands(_INTL("{1} is selected.",itemName),commands)
        if cmdChance > -1 && command == cmdChance # Show the chance of the selected Pokeball catching
          opposingBattlers = []
          opposingNames = []
          @battle.battlers[0].eachOpposing do |b|
            opposingBattlers.push(b)
            opposingNames.push(b.name)
          end

          if opposingBattlers.length == 1
            ballTargetIndex = 0
          else
            ballTargetIndex = itemScene.pbShowCommands(_INTL("Check chance against which?"),opposingNames) || -1
          end

          next if ballTargetIndex == -1

          ballTarget = opposingBattlers[ballTargetIndex]
          
          trueChance = @battle.captureChanceCalc(ballTarget.pokemon,ballTarget,nil,itemSym)
          chance = (trueChance*100/5).floor * 5
          chance = 100 if chance > 100
          chance = 0 if chance < 0
          case chance
          when 0
            pbMessage(_INTL("This ball has a very low chance to capture {1}.",ballTarget.pbThis(true)))
          when 100
            pbMessage(_INTL("This ball is guaranteed to capture {1}!",ballTarget.pbThis(true)))
          else
            pbMessage(_INTL("This ball has a close to {1}% chance of capturing {2}.",chance,ballTarget.pbThis(true)))
          end
          next
        end
        next unless cmdUse > -1 && command == cmdUse
        # Use types:
        # 0 = not usable in battle
        # 1 = use on Pokémon (lots of items)
        # 2 = use on Pokémon's move (Ethers)
        # 3 = use on battler (X items, Persim Berry)
        # 4 = use on opposing battler (Poké Balls)
        # 5 = use no target (Poké Doll, Guard Spec., Launcher items)
        case useType
        when 1, 2, 3   # Use on Pokémon/Pokémon's move/battler
          # Auto-choose the Pokémon/battler whose action is being decided if they
          # are the only available Pokémon/battler to use the item on
          case useType
          when 1   # Use on Pokémon
            if @battle.pbTeamLengthFromBattlerIndex(idxBattler) == 1
              break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
            end
          when 3   # Use on battler
            if @battle.pbPlayerBattlerCount == 1
              break if yield item.id, useType, @battle.battlers[idxBattler].pokemonIndex, -1, itemScene
            end
          end
          # Fade out and hide Bag screen
          itemScene.pbFadeOutScene
          # Get player's party
          party    = @battle.pbParty(idxBattler)
          partyPos = @battle.pbPartyOrder(idxBattler)
          partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
          modParty = @battle.pbPlayerDisplayParty(idxBattler)
          # Start party screen
          pkmnScene = PokemonParty_Scene.new
          pkmnScreen = PokemonPartyScreen.new(pkmnScene,modParty)
          pkmnScreen.pbStartScene(_INTL("Use on which Pokémon?"),@battle.pbNumPositions(0,0))
          idxParty = -1
          # Loop while in party screen
          loop do
            # Select a Pokémon
            pkmnScene.pbSetHelpText(_INTL("Use on which Pokémon?"))
            idxParty = pkmnScreen.pbChoosePokemon
            break if idxParty < 0
            idxPartyRet = -1
            partyPos.each_with_index do |pos,i|
              next if pos != idxParty + partyStart
              idxPartyRet = i
              break
            end
            next if idxPartyRet < 0
            pkmn = party[idxPartyRet]
            next if !pkmn || pkmn.egg?
            idxMove = -1
            if useType == 2   # Use on Pokémon's move
              idxMove = pkmnScreen.pbChooseMove(pkmn,_INTL("Restore which move?"))
              next if idxMove<0
            end
            break if yield item.id, useType, idxPartyRet, idxMove, pkmnScene
          end
          pkmnScene.pbEndScene
          break if idxParty >= 0
          # Cancelled choosing a Pokémon; show the Bag screen again
          itemScene.pbFadeInScene
        when 4   # Use on opposing battler (Poké Balls)
          idxTarget = -1
          if @battle.pbOpposingBattlerCount(idxBattler)==1
            @battle.eachOtherSideBattler(idxBattler) { |b| idxTarget = b.index }
            break if yield item.id, useType, idxTarget, -1, itemScene
          else
            wasTargeting = true
            # Fade out and hide Bag screen
            itemScene.pbFadeOutScene
            # Fade in and show the battle screen, choosing a target
            tempVisibleSprites = visibleSprites.clone
            tempVisibleSprites["commandWindow"] = false
            tempVisibleSprites["targetWindow"]  = true
            idxTarget = pbChooseTarget(idxBattler,GameData::Target.get(:Foe),tempVisibleSprites)
            if idxTarget >= 0
              break if yield item.id, useType, idxTarget, -1, self
            end
            # Target invalid/cancelled choosing a target; show the Bag screen again
            wasTargeting = false
            pbFadeOutAndHide(@sprites)
            itemScene.pbFadeInScene
          end
        when 5   # Use with no target
          break if yield item.id, useType, idxBattler, -1, itemScene
        end
      end
      @bagLastPocket = $PokemonBag.lastpocket
      @bagChoices    = $PokemonBag.getAllChoices
      $PokemonBag.lastpocket = oldLastPocket
      $PokemonBag.setAllChoices(oldChoices)
      # Close Bag screen
      itemScene.pbEndScene
      # Fade back into battle screen (if not already showing it)
      pbFadeInAndShow(@sprites,visibleSprites) if !wasTargeting
    end

    def pbBattleInfoMenu
      # Create targeting window
      cw = BattleInfoDisplay.new(@viewport,300,@battle)
      totalBattlers = @battle.pbSideBattlerCount + @battle.pbOpposingBattlerCount
      doRefresh = false
      loop do
        pbUpdate(cw)
        cw.refresh
        Graphics.update
        if Input.trigger?(Input::B)
          pbPlayCancelSE
          break
        elsif Input.trigger?(Input::UP) && cw.individual.nil?
          cw.selected -= 1
          if (cw.selected < 0)
            cw.selected = totalBattlers - 1
          end
          pbPlayCursorSE
        elsif Input.trigger?(Input::DOWN) && cw.individual.nil?
          cw.selected += 1
          if (cw.selected >= totalBattlers)
            cw.selected = 0
          end
          pbPlayCursorSE
        elsif Input.trigger?(Input::SPECIAL) && cw.individual.nil? && $DEBUG
          #truthifyAllEffects()
          @battle.battlers[0].disableEffect(:Illusion)
          @battle.battlers[0].disableEffect(:ProtectFailure)
          pbPlayDecisionSE
        elsif Input.trigger?(Input::USE)
          battler = nil
          index = 0
          selectedBattler = nil
          @battle.eachSameSideBattler do |b|
            if index == cw.selected
              selectedBattler = b
              pbPlayDecisionSE
              break;
            end
            index += 1
          end
          if !selectedBattler
            @battle.eachOtherSideBattler do |b|
              if index == cw.selected
                selectedBattler = b
                pbPlayDecisionSE
                break;
              end
              index += 1
            end
          end
          if selectedBattler
            cw.individual = selectedBattler
            pbIndividualBattlerInfoMenu(cw)
          end
        end
      end
      cw.dispose
    end

    def truthifyAllEffects
      for effect in 0..30 do
        @battle.positions[0].effects[effect] = true
      end
      for effect in 0..150 do
        @battle.battlers[0].effects[effect] = true
      end
    end
    
    def pbIndividualBattlerInfoMenu(display)
      display.refresh
      loop do
        pbUpdate(display)
        display.refresh
        Graphics.update
          if Input.trigger?(Input::B)
            display.individual = nil
        break
        end
      end
    end
  
    #=============================================================================
    # The player chooses a target battler for a move/item (non-single battles only)
    #=============================================================================
    # Returns an array containing battler names to display when choosing a move's
    # target.
    # nil means can't select that position, "" means can select that position but
    # there is no battler there, otherwise is a battler's name.
    def pbCreateTargetTexts(idxBattler,target_data)
      texts = Array.new(@battle.battlers.length) do |i|
        next nil if !@battle.battlers[i]
        showName = false
        # NOTE: Targets listed here are ones with num_targets of 0, plus
        #       RandomNearFoe which should look like it targets the user. All
        #       other targets are handled by the "else" part.
        case target_data.id
        when :None, :User, :RandomNearFoe
          showName = (i==idxBattler)
        when :UserSide
          showName = !@battle.opposes?(i,idxBattler)
        when :FoeSide
          showName = @battle.opposes?(i,idxBattler)
        when :BothSides
          showName = true
        else
          showName = @battle.pbMoveCanTarget?(i,idxBattler,target_data)
        end
        next nil if !showName
        next (@battle.battlers[i].fainted?) ? "" : @battle.battlers[i].name
      end
      return texts
    end
  
    # Returns the initial position of the cursor when choosing a target for a move
    # in a non-single battle.
    def pbFirstTarget(idxBattler,target_data)
      case target_data.id
      when :NearAlly
        @battle.eachSameSideBattler(idxBattler) do |b|
          next if b.index==idxBattler || !@battle.nearBattlers?(b,idxBattler)
          next if b.fainted?
          return b.index
        end
        @battle.eachSameSideBattler(idxBattler) do |b|
          next if b.index==idxBattler || !@battle.nearBattlers?(b,idxBattler)
          return b.index
        end
      when :Ally
        @battle.eachSameSideBattler(idxBattler) do |b|
          next if b.index==idxBattler
          next if b.fainted?
          return b.index
        end
        @battle.eachSameSideBattler(idxBattler) do |b|
          next if b.index==idxBattler
          return b.index
        end
      when :NearFoe, :NearOther
        indices = @battle.pbGetOpposingIndicesInOrder(idxBattler)
        indices.each { |i| return i if @battle.nearEnoughForMoveTargeting?(i,idxBattler) && !@battle.battlers[i].fainted? }
        indices.each { |i| return i if @battle.nearEnoughForMoveTargeting?(i,idxBattler) }
      when :Foe, :Other, :UserOrOther, :UserOrNearOther
        indices = @battle.pbGetOpposingIndicesInOrder(idxBattler)
        indices.each { |i| return i if !@battle.battlers[i].fainted? }
        indices.each { |i| return i }
      end
      return idxBattler # Target the user initially
    end
  
    def pbChooseTarget(idxBattler,target_data,visibleSprites=nil,dexSelect=false)
      pbShowWindow(TARGET_BOX)
      cw = @sprites["targetWindow"]
      cw.dexSelect = dexSelect
      # Create an array of battler names (only valid targets are named)
      texts = pbCreateTargetTexts(idxBattler,target_data)
      # Determine mode based on target_data
      mode = (target_data.num_targets == 1) ? 0 : 1
      cw.setDetails(texts,mode)
      cw.index = pbFirstTarget(idxBattler,target_data)
      pbSelectBattler((mode==0) ? cw.index : texts,2)   # Select initial battler/data box
      pbFadeInAndShow(@sprites,visibleSprites) if visibleSprites
      ret = -1
      loop do
        oldIndex = cw.index
        pbUpdate(cw)
        # Update selected command
        if mode==0   # Choosing just one target, can change index
          if Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)
            inc = ((cw.index%2)==0) ? -2 : 2
            inc *= -1 if Input.trigger?(Input::RIGHT)
            indexLength = @battle.sideSizes[cw.index%2]*2
            newIndex = cw.index
            loop do
              newIndex += inc
              break if newIndex<0 || newIndex>=indexLength
              next if texts[newIndex].nil?
              cw.index = newIndex
              break
            end
          elsif (Input.trigger?(Input::UP) && (cw.index%2)==0) ||
                (Input.trigger?(Input::DOWN) && (cw.index%2)==1)
            tryIndex = @battle.pbGetOpposingIndicesInOrder(cw.index)
            tryIndex.each do |idxBattlerTry|
              next if texts[idxBattlerTry].nil?
              cw.index = idxBattlerTry
              break
            end
          end
          if cw.index!=oldIndex
            pbPlayCursorSE
            pbSelectBattler(cw.index,2)   # Select the new battler/data box
          end
        end
        if Input.trigger?(Input::USE)   # Confirm
          ret = cw.index
          pbPlayDecisionSE
          break
        elsif Input.trigger?(Input::BACK)   # Cancel
          ret = -1
          pbPlayCancelSE
          break
        end
      end
      pbSelectBattler(-1)   # Deselect all battlers/data boxes
      return ret
    end

    #=============================================================================
    # Enable the cursors which display where an avatar is targeting
    #=============================================================================
    def setAvatarTargetReticlesOff
      @battle.battlers.each_with_index do |b,i|
        next if b.nil?
        if @sprites["aggro_cursor_#{i}"].nil?
          createAvatarTargetReticle(b,i)
        end
        @sprites["aggro_cursor_#{i}"].visible = false
      end
    end
  
    def setAvatarTargetReticleOnIndex(index,extraAggro = false)
      @sprites["aggro_cursor_#{index}"].visible = true
      @sprites["aggro_cursor_#{index}"].extraAggro = extraAggro
    end
  
    #=============================================================================
    # Opens a Pokémon's summary screen to try to learn a new move
    #=============================================================================
    # Called whenever a Pokémon should forget a move. It should return -1 if the
    # selection is canceled, or 0 to 3 to indicate the move to forget. It should
    # not allow HM moves to be forgotten.
    def pbForgetMove(pkmn,moveToLearn)
      ret = -1
      pbFadeOutIn {
        scene = PokemonSummary_Scene.new
        screen = PokemonSummaryScreen.new(scene)
        ret = screen.pbStartForgetScreen([pkmn],0,moveToLearn)
      }
      return ret
    end
  
    #=============================================================================
    # Opens the nicknaming screen for a newly caught Pokémon
    #=============================================================================
    def pbNameEntry(helpText,pkmn)
      return pbEnterPokemonName(helpText, 0, Pokemon::MAX_NAME_SIZE, "", pkmn)
    end
  
    #=============================================================================
    # Shows the Pokédex entry screen for a newly caught Pokémon
    #=============================================================================
    def pbShowPokedex(species)
      openSingleDexScreen(species)
    end

    #=============================================================================
    # Animates an opposing trainer sliding off from from on-screen.
    #=============================================================================
    def pbUnshowOpponent(idxTrainer)
      # Set up trainer appearing animation
      appearAnim = TrainerDisappearAnimation.new(@sprites, @viewport, idxTrainer)
      @animations.push(appearAnim)
      # Play the animation
      pbUpdate while inPartyAnimation?
    end

    def trainerMovesInOut(trainerIndex, &block)
        pbShowOpponent(trainerIndex)
        block.call if block
        pbUnshowOpponent(trainerIndex)
    end

    def showTrainerDialogue(idxTrainer, &block)
        # Gather dialogue from event calls through the trainer's policies
        dialogue = []
        policies = @battle.opponent[idxTrainer].policies
        policies.each do |policy|
            dialogue = block.call(policy, dialogue)
        rescue StandardError
            pbMessage(_INTL("An error was encountered while trying to check for trainer dialogue."))
        end

        # Error state
        unless dialogue
            echoln("Dialogue array somehow became null while trying to show trainer dialogue!")
            return
        end

        # If there's some dialogue schedule, move the trainer on screen,
        # display all the dialogue, then move the trainer off screen
        if dialogue.length != 0
            trainerMovesInOut(idxTrainer) do
                dialogue.each do |line|
                    line = globalMessageReplacements(line)
                    pbDisplayPausedMessage(line)
                end
            end
        end
    end

    #=============================================================================
    # Shows the large turn count readout at the top of the screen
    #=============================================================================
    def pbShowTurnCountReminder
      @sprites["turnCountReminder"].visible = true
    end

    def pbHideTurnCountReminder
      @sprites["turnCountReminder"].visible = false
    end

    def updateTurnCountReminder(turnCount)
      @sprites["turnCountReminder"].turnCount = turnCount
      pbShowTurnCountReminder
    end
end
  