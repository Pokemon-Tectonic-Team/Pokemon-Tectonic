#===============================================================================
# Fight menu (choose a move)
#===============================================================================
class FightMenuDisplay < BattleMenuBase
    include MoveInfoDisplay

    attr_reader :battler
    attr_reader :shiftMode
    attr_reader :extraInfoToggled
  
    # If true, displays graphics from Graphics/Pictures/Battle/overlay_fight.png
    #     and Graphics/Pictures/Battle/cursor_fight.png.
    # If false, just displays text and the command window over the graphic
    #     Graphics/Pictures/Battle/overlay_message.png. You will need to edit def
    #     pbShowWindow to make the graphic appear while the command menu is being
    #     displayed.
    USE_GRAPHICS     = true
    TYPE_ICON_HEIGHT = 28
  
    def initialize(viewport,z)
        super(viewport)
        @viewport = viewport
        self.x = 0
        self.y = Graphics.height-96
        @battler   = nil
        @shiftMode = 0
        @extraInfoToggled = false
        # NOTE: @mode is for the display of the Mega Evolution button.
        #       0=don't show, 1=show unpressed, 2=show pressed
        if USE_GRAPHICS
          # Create bitmaps
          @buttonBitmap  			    = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Battle/cursor_fight")))
          @typeBitmap    			    = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/types")))
          @megaEvoBitmap 			    = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Battle/cursor_mega")))
          @shiftBitmap   			    = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Battle/cursor_shift")))
          moveInfoDisplayFileName = addLanguageSuffix(("Graphics/Pictures/move_info_display_3x3"))
          moveInfoDisplayFileName += "_dark" if darkMode?
          @moveInfoDisplayBitmap  = AnimatedBitmap.new(moveInfoDisplayFileName)
          @ppUsageUpBitmap        = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Battle/pp_usage_up")))
          @cursorShadeBitmap      = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Battle/cursor_fight_shade")))
          # Create background graphic
          background = IconSprite.new(0,Graphics.height-96,viewport)
          background.setBitmap("Graphics/Pictures/Battle/overlay_fight")
          addSprite("background",background)
          # Create move buttons and highlighters
          @buttons = []
          @highlights = []
          @shaders = []
          for i in 0...Pokemon::MAX_MOVES do
            buttonX = self.x + 4 + (((i%2)==0) ? 0 : @buttonBitmap.width/2-4)
            buttonY = self.y + 6 + (((i/2)==0) ? 0 : BUTTON_HEIGHT-4)
            createButton(buttonX,buttonY,i)
          end
          # Create the extra two buttons for extra moves
          createButton(self.x + 4,self.y - BUTTON_HEIGHT,Pokemon::MAX_MOVES)
          createButton(self.x + @buttonBitmap.width/2,self.y - BUTTON_HEIGHT,Pokemon::MAX_MOVES+1)
          
          # Create overlay for buttons (shows move names)
          @overlay = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
          pbSetNarrowFont(@overlay.bitmap)
          addSprite("overlay",@overlay)
          # Create overlay for selected move's info (shows move's PP)
          @infoOverlay = BitmapSprite.new(Graphics.width,Graphics.height-self.y,viewport)
          @infoOverlay.x = self.x
          @infoOverlay.y = self.y
          pbSetNarrowFont(@infoOverlay.bitmap)
          addSprite("infoOverlay",@infoOverlay)
          # Create Shift button
          @shiftButton = SpriteWrapper.new(viewport)
          @shiftButton.bitmap = @shiftBitmap.bitmap
          @shiftButton.x      = self.x+4
          @shiftButton.y      = self.y-@shiftBitmap.height
          addSprite("shiftButton",@shiftButton)
          # Create extra info reminder button
          # @extraReminder = SpriteWrapper.new(viewport)
          # @extraReminder.bitmap = @extraReminderBitmap.bitmap
          # @extraReminder.x = self.x+4
          # @extraReminder.y = self.y + 6 - @extraReminderBitmap.height
          # addSprite("extraReminder",@extraReminder)
          # Create the move extra info display
          moveInfoDisplayY = self.y-@moveInfoDisplayBitmap.height
          @moveInfoDisplay = SpriteWrapper.new(viewport)
          @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
          @moveInfoDisplay.x      = self.x
          @moveInfoDisplay.y      = moveInfoDisplayY
          addSprite("moveInfoDisplay",@moveInfoDisplay)
            # Create overlay for selected move's extra info (shows move's BP, description)
          @extraInfoOverlay = BitmapSprite.new(@moveInfoDisplayBitmap.bitmap.width,@moveInfoDisplayBitmap.height,viewport)
          @extraInfoOverlay.x = self.x
          @extraInfoOverlay.y = moveInfoDisplayY
          pbSetNarrowFont(@extraInfoOverlay.bitmap)
          addSprite("extraInfoOverlay",@extraInfoOverlay)
        else
          # Create message box (shows type and PP of selected move)
          @msgBox = Window_AdvancedTextPokemon.newWithSize("",
             self.x+320,self.y,Graphics.width-320,Graphics.height-self.y,viewport)
          @msgBox.baseColor   = TEXT_BASE_COLOR
          @msgBox.shadowColor = TEXT_SHADOW_COLOR
          pbSetNarrowFont(@msgBox.contents)
          addSprite("msgBox",@msgBox)
          # Create command window (shows moves)
          @cmdWindow = Window_CommandPokemon.newWithSize([],
             self.x,self.y,320,Graphics.height-self.y,viewport)
          @cmdWindow.columns       = 2
          @cmdWindow.columnSpacing = 4
          @cmdWindow.ignore_input  = true
          pbSetNarrowFont(@cmdWindow.contents)
          addSprite("cmdWindow",@cmdWindow)
        end
        self.z = z
    end

    def createButton(buttonX,buttonY,index)
      newButton = SpriteWrapper.new(@viewport)
      newButton.bitmap = @buttonBitmap.bitmap
      newButton.x      = buttonX
      newButton.y      = buttonY
      newButton.src_rect.width  = @buttonBitmap.width/2
      newButton.src_rect.height = BUTTON_HEIGHT
      addSprite("button_#{index}",newButton)
      @buttons.push(newButton)
      
      newHighlighter = AnimatedSprite.new(["Graphics/Pictures/Battle/cursor_fight_highlight",37,0.5])
      newHighlighter.viewport = @viewport
      newHighlighter.x = buttonX + 20
      newHighlighter.y = buttonY + 8
      newHighlighter.opacity = 80
      newHighlighter.blend_type = 1
      addSprite("highlight_#{index}",newHighlighter)
      @highlights.push(newHighlighter)

      newShader = SpriteWrapper.new(@viewport)
      newShader.bitmap = @cursorShadeBitmap.bitmap
      newShader.x = buttonX + 20
      newShader.y = buttonY + 8
      newShader.opacity = 80
      addSprite("shader_#{index}",newShader)
      @shaders.push(newShader)
    end
  
    def dispose
        super
        @buttonBitmap.dispose if @buttonBitmap
        @typeBitmap.dispose if @typeBitmap
        @megaEvoBitmap.dispose if @megaEvoBitmap
        @shiftBitmap.dispose if @shiftBitmap
        @moveInfoDisplayBitmap.dispose if @moveInfoDisplayBitmap
        @ppUsageUpBitmap.dispose if @ppUsageUpBitmap
    end
  
    def z=(value)
        super
        @msgBox.z      += 1 if @msgBox
        @cmdWindow.z   += 2 if @cmdWindow
        @overlay.z     += 5 if @overlay
        @infoOverlay.z += 6 if @infoOverlay
        @highlights.each do |highlight|
          highlight.z += 6
        end
        @shaders.each do |highlight|
          highlight.z += 7
        end
    end

    def visible=(value)
        super(value)
        @sprites["moveInfoDisplay"].visible = @extraInfoToggled && @visible if @sprites["moveInfoDisplay"]
        @sprites["extraInfoOverlay"].visible = @extraInfoToggled && @visible if @sprites["moveInfoDisplay"]
    end
  
    def battler=(value)
      @battler = value
      refresh
      refreshButtonNames
    end
  
    def shiftMode=(value)
      oldValue = @shiftMode
      @shiftMode = value
      refreshShiftButton if @shiftMode!=oldValue
    end

    def toggleExtraInfo
        @extraInfoToggled = !@extraInfoToggled
        @sprites["moveInfoDisplay"].visible = @extraInfoToggled && @visible if @sprites["moveInfoDisplay"]
        @sprites["extraInfoOverlay"].visible = @extraInfoToggled && @visible if @sprites["moveInfoDisplay"]
        if extraInfoToggled && @battler&.getMoves[@index]&.adaptiveMove? && !$PokemonGlobal.adaptiveMovesTutorialized
          playAdaptiveMovesTutorial
        end
    end
  
    def refreshButtonNames
        moves = (@battler) ? @battler.getMoves : []
        if !USE_GRAPHICS
          # Fill in command window
          commands = []
          for i in 0...[4, moves.length].max
            commands.push((moves[i]) ? moves[i].name : "-")
          end
          @cmdWindow.commands = commands
          return
        end
        # Draw move names onto overlay
        @overlay.bitmap.clear
        textPos = []
        @buttons.each_with_index do |button,i|
          @visibility["highlight_#{i}"] = false
          @visibility["shader_#{i}"] = false
          next if !@visibility["button_#{i}"]
          move = moves[i]
          x = button.x + button.src_rect.width / 2
          y = button.y + 2
          moveNameBase = TEXT_BASE_COLOR
          if move.type
            # NOTE: This takes a colour from a particular pixel in the button
            #       graphic and makes the move name's base colour that same colour.
           move #       The pixel is at coordinates 10,34 in the button box. If you
            #       change the graphic, you may want to change/remove the below line
            #       of code to ensure the font is an appropriate colour.
            moveNameBase = button.bitmap.get_pixel(10,button.src_rect.y+34)
          end
          textPos.push([move.name,x,y,2,moveNameBase,TEXT_SHADOW_COLOR])
          begin
            # Determine whether to shade the move
            targetingData = move.pbTarget(@battler)
            @battler.turnCount += 1 # Fake the turn count
            if targetingData.num_targets == 0 || move.worksWithNoTargets?
              shouldShade = move.shouldShade?(@battler,nil)
            else
              shouldShade = true
              @battler.battle.eachBattler do |otherBattler|
                next unless @battler.battle.pbMoveCanTarget?(@battler.index,otherBattler.index,targetingData)
                next if move.shouldShade?(@battler,otherBattler)
                shouldShade = false
                break
              end
            end
            @battler.turnCount -= 1 # Fake the turn count
    
            if shouldShade
              @visibility["shader_#{i}"] = true
            # Determine whether to highlight the move
            elsif move.damagingMove?(true)
              shouldHighlight = false
    
              if targetingData.num_targets == 0
                shouldHighlight = move.shouldHighlight?(@battler,nil)
              else
                @battler.eachOpposing do |opposingBattler|
                  next unless @battler.battle.pbMoveCanTarget?(@battler.index,opposingBattler.index,targetingData)
                  next unless move.shouldHighlight?(@battler,opposingBattler)
                  shouldHighlight = true
                  break
                end
              end
      
              if shouldHighlight
                @visibility["highlight_#{i}"] = true
                @sprites["highlight_#{i}"].start
              end
            end
          rescue
            echoln("Error computing shading and highlighting for move #{move.name}")
          end
        end
        pbDrawTextPositions(@overlay.bitmap,textPos)
        @buttons.each_with_index do |button,i|
          next if !@visibility["button_#{i}"]
          if PP_INCREASE_REPEAT_MOVES
            if @battler && @battler.lastMoveUsed && @battler.lastMoveUsed == moves[i].id && !@battler.lastMoveFailed
              x = button.x-self.x+button.src_rect.width - 32
              y = button.y-self.y+4
              @overlay.bitmap.blt(x,y+2,@ppUsageUpBitmap.bitmap,Rect.new(0,0,@ppUsageUpBitmap.width,@ppUsageUpBitmap.height))
            end
          end
        end
    end
  
    def refreshSelection
      moves = (@battler) ? @battler.getMoves : []
      if USE_GRAPHICS
        # Choose appropriate button graphics and z positions
        @buttons.each_with_index do |button,i|
          if !moves[i]
            @visibility["button_#{i}"] = false
            next
          end
          @visibility["button_#{i}"] = true
          button.src_rect.x = (i==@index) ? @buttonBitmap.width/2 : 0
          button.src_rect.y = GameData::Type.get(moves[i].type).id_number * BUTTON_HEIGHT
          button.z          = self.z + ((i==@index) ? 4 : 3)
        end
      end
      refreshMoveData(moves[@index])
    end
  
    def refreshMoveData(move)
        @infoOverlay.bitmap.clear
        return unless move

        base   = Color.new(248,248,248)
        faded_base = MessageConfig.pbDefaultFadedTextColor
        shadow = Color.new(104,104,104)

        pbSetNarrowFont(@infoOverlay.bitmap)
        moveInfoToggleReminderBase = PokeBattle_SceneConstants::MESSAGE_BASE_COLOR
        moveInfoToggleReminderShadow = PokeBattle_SceneConstants::MESSAGE_SHADOW_COLOR
        moveInfoToggleReminderText = []
        moveInfoToggleReminderText.push([_INTL("Toggle Info:"),448,14,2,moveInfoToggleReminderBase,moveInfoToggleReminderShadow])
        moveInfoToggleReminderText.push([_INTL("ACTION/Z"),448,42,2,moveInfoToggleReminderBase,moveInfoToggleReminderShadow])
        pbDrawTextPositions(@infoOverlay.bitmap,moveInfoToggleReminderText)
        pbSetSystemFont(@infoOverlay.bitmap)
        
        # Send info to the move outcome predictor displays
        if move.damagingMove?(true)
          targetingData = move.pbTarget(@battler)
          @battler.eachOpposing do |opposingBattler|
            next unless @battler.battle.pbMoveCanTarget?(@battler.index,opposingBattler.index,targetingData)
            setMoveOutcomePredictor(move,opposingBattler)
          end
        else
          @battler.eachOpposing do |opposingBattler|
            opposingBattler.moveOutcomePredictor&.clear
          end
        end
        
        # Extra move info display
        @extraInfoOverlay.bitmap.clear
        writeMoveInfoToInfoOverlay3x3(@extraInfoOverlay.bitmap,move,true)
    end

    def setMoveOutcomePredictor(move,opposingBattler)
      begin
        typeOfMove = move.pbCalcType(@battler)
        effectiveness = move.pbCalcTypeMod(typeOfMove,@battler,opposingBattler,true)

        if move.is_a?(PokeBattle_FixedDamageMove)
            if effectiveness == 0
                effectivenessCategory = 0
            else
                effectivenessCategory = 3
            end
        else
            ration = effectiveness/Effectiveness::NORMAL_EFFECTIVE.to_f
            case ration
                when 0                  then effectivenessCategory = 0
                when 0.00001..0.25      then effectivenessCategory = 1
                when 0.5 	            then effectivenessCategory = 2
                when 1 		    	    then effectivenessCategory = 3
                when 2 			        then effectivenessCategory = 4
                when 4.. 			    then effectivenessCategory = 5
            end
        end

        moveOutcomeText = [_INTL("No Effect"),_INTL("Barely"),_INTL("Not Very"),_INTL("Neutral"),_INTL("Super"),_INTL("Hyper"),_INTL("Hyper")][effectivenessCategory]
        effectivenessColor = EFFECTIVENESS_COLORS[effectivenessCategory]
      rescue
        moveOutcomeText = _INTL("ERROR")
      end

      opposingBattler.moveOutcomePredictor.setEffectiveness(moveOutcomeText,effectivenessColor)
      if move.baseDamage == 1 && !move.is_a?(PokeBattle_FixedDamageMove)
        opposingBattler.moveOutcomePredictor.basePower = move.predictedBasePower(@battler, opposingBattler).to_s
      else
        opposingBattler.moveOutcomePredictor.basePower = nil
      end
    end
  
    def refreshShiftButton
      return if !USE_GRAPHICS
      @shiftButton.src_rect.y    = (@shiftMode - 1) * @shiftBitmap.height
      @shiftButton.z             = self.z - 1
      @visibility["shiftButton"] = (@shiftMode > 0)
    end
  
    def refresh
      return if !@battler
      refreshSelection
      refreshShiftButton
    end
end