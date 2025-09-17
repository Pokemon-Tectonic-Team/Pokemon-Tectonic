SUMMARY_MOVE_NAMES_X_INIT = 10
SUMMARY_MOVE_NAMES_X_OFFSET = 240
SUMMARY_MOVE_NAMES_Y_INIT = 69
SUMMARY_MOVE_NAMES_Y_OFFSET = 44
SUMMARY_LEARNING_MOVE_NAME_Y = 4
MOVE_SEL_Y_OFFSET = 4

#===============================================================================
#
#===============================================================================
class MoveSelectionSprite < SpriteWrapper
    attr_reader :preselected
    attr_reader :index

    def initialize(viewport = nil, fifthmove = false)
        super(viewport)
        @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_move")
        @frame = 0
        @index = 0
        @fifthmove = fifthmove
        @preselected = false
        @updating = false
        refresh
    end

    def dispose
        @movesel.dispose
        super
    end

    def index=(value)
        @index = value
        refresh
    end

    def preselected=(value)
        @preselected = value
        refresh
    end

    def refresh
        w = @movesel.width
        h = @movesel.height / 2
        if @fifthmove && index == Pokemon::MAX_MOVES
            self.x = SUMMARY_MOVE_NAMES_X_INIT + SUMMARY_MOVE_NAMES_X_OFFSET
            self.y = SUMMARY_LEARNING_MOVE_NAME_Y + MOVE_SEL_Y_OFFSET
        else
            self.x = SUMMARY_MOVE_NAMES_X_INIT + (index % 2) * SUMMARY_MOVE_NAMES_X_OFFSET
            self.y = SUMMARY_MOVE_NAMES_Y_INIT + (index / 2) * SUMMARY_MOVE_NAMES_Y_OFFSET + MOVE_SEL_Y_OFFSET
        end
        self.bitmap = @movesel.bitmap
        if preselected
            src_rect.set(0, h, w, h)
        else
            src_rect.set(0, 0, w, h)
        end
    end

    def update
        @updating = true
        super
        @movesel.update
        @updating = false
        refresh
    end
end

#===============================================================================
#
#===============================================================================
class RibbonSelectionSprite < MoveSelectionSprite
    def initialize(viewport = nil)
        super(viewport)
        @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_ribbon")
        @frame = 0
        @index = 0
        @preselected = false
        @updating = false
        @spriteVisible = true
        refresh
    end

    def visible=(value)
        super
        @spriteVisible = value unless @updating
    end

    def refresh
        w = @movesel.width
        h = @movesel.height / 2
        self.x = 228 + (index % 4) * 68
        self.y = 76 + ((index / 4).floor * 68)
        self.bitmap = @movesel.bitmap
        if preselected
            src_rect.set(0, h, w, h)
        else
            src_rect.set(0, 0, w, h)
        end
    end

    def update
        @updating = true
        super
        self.visible = @spriteVisible && @index >= 0 && @index < 12
        @movesel.update
        @updating = false
        refresh
    end
end

#===============================================================================
#
#===============================================================================
class PokemonSummary_Scene
    include MoveInfoDisplay

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene(party, partyindex, battle = nil)
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @party      = party
        @partyindex = partyindex
        @pokemon    = @party[@partyindex]
        @battle     = battle
        @page = 1
        @forget = false
        @typebitmap    = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/types")))
        @markingbitmap = AnimatedBitmap.new("Graphics/Pictures/Summary/markings")
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["pokemon"] = PokemonSprite.new(@viewport)
        @sprites["pokemon"].setOffset(PictureOrigin::Center)
        @sprites["pokemon"].x = 104
        @sprites["pokemon"].y = 206
        @sprites["pokemon"].setPokemonBitmap(@pokemon)
        @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
        @sprites["pokeicon"].setOffset(PictureOrigin::Center)
        @sprites["pokeicon"].x       = 46
        @sprites["pokeicon"].y       = 92
        @sprites["pokeicon"].visible = false
        createItemIcons
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
        @sprites["movepresel"].visible     = false
        @sprites["movepresel"].preselected = true
        @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
        @sprites["movesel"].visible = false
        @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
        @sprites["ribbonpresel"].visible     = false
        @sprites["ribbonpresel"].preselected = true
        @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
        @sprites["ribbonsel"].visible = false
        @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow", 8, 28, 40, 2, @viewport)
        @sprites["uparrow"].x = 350
        @sprites["uparrow"].y = 56
        @sprites["uparrow"].play
        @sprites["uparrow"].visible = false
        @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow", 8, 28, 40, 2, @viewport)
        @sprites["downarrow"].x = 350
        @sprites["downarrow"].y = 260
        @sprites["downarrow"].play
        @sprites["downarrow"].visible = false
        @sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
        @sprites["markingbg"].setBitmap("Graphics/Pictures/Summary/overlay_marking")
        @sprites["markingbg"].visible = false
        @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["markingoverlay"].visible = false
        pbSetSystemFont(@sprites["markingoverlay"].bitmap)
        @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
        @sprites["markingsel"].setBitmap("Graphics/Pictures/Summary/cursor_marking")
        @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
        @sprites["markingsel"].visible = false
        @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
        @sprites["messagebox"].viewport       = @viewport
        @sprites["messagebox"].visible        = false
        @sprites["messagebox"].letterbyletter = true
        pbBottomLeftLines(@sprites["messagebox"], 2)
        createMoveInfoDisplay
        
        drawPage(@page)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def createMoveInfoDisplay
        info_path = "Graphics/Pictures/move_info_display_3x3"
        info_path += "_dark" if darkMode?
        @moveInfoDisplayBitmap = AnimatedBitmap.new(_INTL(info_path))

        # Create the move extra info display
        moveInfoDisplayY = Graphics.height - @moveInfoDisplayBitmap.height
        @moveInfoDisplay = SpriteWrapper.new(@viewport)
        @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        @moveInfoDisplay.y = moveInfoDisplayY
        @sprites["moveInfoDisplay"] = @moveInfoDisplay
        # Create overlay for selected move's extra info (shows move's BP, description)
        @extraInfoOverlay = BitmapSprite.new(Graphics.width, Graphics.height,  @viewport)
        pbSetNarrowFont(@extraInfoOverlay.bitmap)
        @sprites["extraInfoOverlay"] = @extraInfoOverlay
        @extraInfoOverlay.y = moveInfoDisplayY
    end

    def pbStartForgetScene(party, partyindex, move_to_learn)
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @party      = party
        @partyindex = partyindex
        @pokemon    = @party[@partyindex]
        @page = 4
        @forget = true
        @typebitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/types")))
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        @sprites["pokemon"] = PokemonSprite.new(@viewport)
        @sprites["pokemon"].setOffset(PictureOrigin::Center)
        @sprites["pokemon"].x = 104
        @sprites["pokemon"].y = 206
        @sprites["pokemon"].setPokemonBitmap(@pokemon)
        @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
        @sprites["pokeicon"].setOffset(PictureOrigin::Center)
        @sprites["pokeicon"].x       = 46
        @sprites["pokeicon"].y       = 92
        @sprites["pokeicon"].visible = false
        createItemIcons
        @sprites["movesel"] = MoveSelectionSprite.new(@viewport, !move_to_learn.nil?)
        @sprites["movesel"].visible = false
        @sprites["movesel"].visible = true

        if move_to_learn
            @sprites["movesel"].index = Pokemon::MAX_MOVES
            new_move = Pokemon::Move.new(move_to_learn)
            move_selected = new_move
        else # Move deleter screen
            @sprites["movesel"].index = 0
            new_move = nil
            move_selected = @pokemon.moves[0]
        end

        createMoveInfoDisplay

        drawSelectedMove(new_move, move_selected)
        pbFadeInAndShow(@sprites)
    end

    def pbStartSingleScene(pokemon)
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @party      = nil
        @partyindex = -1
        @pokemon    = pokemon
        @battle     = nil
        @page = 1
        @typebitmap    = AnimatedBitmap.new(addLanguageSuffix("Graphics/Pictures/types"))
        @markingbitmap = AnimatedBitmap.new("Graphics/Pictures/Summary/markings")
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["pokemon"] = PokemonSprite.new(@viewport)
        @sprites["pokemon"].setOffset(PictureOrigin::Center)
        @sprites["pokemon"].x = 104
        @sprites["pokemon"].y = 206
        @sprites["pokemon"].setPokemonBitmap(@pokemon)

        @sprites["pokemon"].visible = false
        
        @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
        @sprites["pokeicon"].setOffset(PictureOrigin::Center)
        @sprites["pokeicon"].x       = 46
        @sprites["pokeicon"].y       = 92
        @sprites["pokeicon"].visible = false
        createItemIcons
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
        @sprites["movepresel"].visible     = false
        @sprites["movepresel"].preselected = true
        @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
        @sprites["movesel"].visible = false
        @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
        @sprites["ribbonpresel"].visible     = false
        @sprites["ribbonpresel"].preselected = true
        @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
        @sprites["ribbonsel"].visible = false
        @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow", 8, 28, 40, 2, @viewport)
        @sprites["uparrow"].x = 350
        @sprites["uparrow"].y = 56
        @sprites["uparrow"].play
        @sprites["uparrow"].visible = false
        @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow", 8, 28, 40, 2, @viewport)
        @sprites["downarrow"].x = 350
        @sprites["downarrow"].y = 260
        @sprites["downarrow"].play
        @sprites["downarrow"].visible = false
        @sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
        @sprites["markingbg"].setBitmap("Graphics/Pictures/Summary/overlay_marking")
        @sprites["markingbg"].visible = false
        @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["markingoverlay"].visible = false
        pbSetSystemFont(@sprites["markingoverlay"].bitmap)
        @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
        @sprites["markingsel"].setBitmap("Graphics/Pictures/Summary/cursor_marking")
        @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
        @sprites["markingsel"].visible = false
        @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
        @sprites["messagebox"].viewport       = @viewport
        @sprites["messagebox"].visible        = false
        @sprites["messagebox"].letterbyletter = true
        pbBottomLeftLines(@sprites["messagebox"], 2)

        createMoveInfoDisplay

        drawPage(@page)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def createItemIcons
        path_1 = "Graphics/Pictures/Summary/item_bg"
        path_1 += "_dark" if darkMode?
        path_2 = "Graphics/Pictures/Summary/item_bg2"
        path_2 += "_dark" if darkMode?
        @itemBackground = AnimatedBitmap.new(path_1)
        @itemBackground2 = AnimatedBitmap.new(path_2)
        @sprites["itembackground"] = IconSprite.new(0, 0, @viewport)
        @sprites["itembackground"].bitmap = @itemBackground.bitmap
        @sprites["itembackground"].y = Graphics.height - @itemBackground.bitmap.height
        @sprites["itembackground"].visible = true
        @sprites["itemicon"] = ItemIconSprite.new(30, 320, @pokemon.items[0], @viewport)
        @sprites["itemicon"].type = @pokemon.itemTypeChosen
        @sprites["itemicon"].blankzero = true
        @sprites["itemicon2"] = ItemIconSprite.new(166, 320, @pokemon.items[1], @viewport)
        @sprites["itemicon2"].type = @pokemon.itemTypeChosen
        @sprites["itemicon2"].blankzero = true
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @typebitmap.dispose
        @markingbitmap.dispose if @markingbitmap
        @viewport.dispose
        @itemBackground.dispose if @itemBackground
        @itemBackground2.dispose if @itemBackground2
    end

    def pbDisplay(text)
        @sprites["messagebox"].text = text
        @sprites["messagebox"].visible = true
        pbPlayDecisionSE
        loop do
            Graphics.update
            Input.update
            pbUpdate
            if @sprites["messagebox"].busy?
                if Input.trigger?(Input::USE)
                    pbPlayDecisionSE if @sprites["messagebox"].pausing?
                    @sprites["messagebox"].resume
                end
            elsif Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
                break
            end
        end
        @sprites["messagebox"].visible = false
    end

    def pbConfirm(text)
        ret = -1
        @sprites["messagebox"].text    = text
        @sprites["messagebox"].visible = true
        using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"), _INTL("No")])) do
            cmdwindow.z = @viewport.z + 1
            cmdwindow.visible = false
            pbBottomRight(cmdwindow)
            cmdwindow.y -= @sprites["messagebox"].height
            loop do
                Graphics.update
                Input.update
                cmdwindow.visible = true unless @sprites["messagebox"].busy?
                cmdwindow.update
                pbUpdate
                unless @sprites["messagebox"].busy?
                    if Input.trigger?(Input::BACK)
                        ret = false
                        break
                    elsif Input.trigger?(Input::USE) && @sprites["messagebox"].resume
                        ret = (cmdwindow.index == 0)
                        break
                    end
                end
            end
        end
        @sprites["messagebox"].visible = false
        return ret
    end

    def pbShowCommands(commands, index = 0)
        ret = -1
        using(cmdwindow = Window_CommandPokemon.new(commands)) do
            cmdwindow.z = @viewport.z + 1
            cmdwindow.index = index
            pbBottomRight(cmdwindow)
            loop do
                Graphics.update
                Input.update
                cmdwindow.update
                pbUpdate
                if Input.trigger?(Input::BACK)
                    pbPlayCancelSE
                    ret = -1
                    break
                elsif Input.trigger?(Input::USE)
                    pbPlayDecisionSE
                    ret = cmdwindow.index
                    break
                end
            end
        end
        return ret
    end

    def drawMarkings(bitmap, x, y)
        markings = @pokemon.markings
        markrect = Rect.new(0, 0, 16, 16)
        for i in 0...6
            markrect.x = i * 16
            markrect.y = (markings & (1 << i) != 0) ? 16 : 0
            bitmap.blt(x + i * 16, y, @markingbitmap.bitmap, markrect)
        end
    end

    def refreshItemIcons(setVisible = true)
        @sprites["itemicon"].visible = true if setVisible
        @sprites["itemicon"].item = @pokemon.items[0]
        @sprites["itemicon"].type = @pokemon.itemTypeChosen

        @sprites["itemicon2"].visible = true if setVisible
        @sprites["itemicon2"].item = @pokemon.items[1]
        @sprites["itemicon2"].type = @pokemon.itemTypeChosen

        @sprites["itembackground"].visible = true if setVisible
        if @pokemon.hasMultipleItems?
            @sprites["itembackground"].bitmap = @itemBackground2.bitmap
        else
            @sprites["itembackground"].bitmap = @itemBackground.bitmap
        end
    end

    def showItems
        @sprites["itemicon"]&.visible = true
        @sprites["itemicon2"]&.visible = true
        @sprites["itembackground"]&.visible = true
    end

    def hideItems
        @sprites["itemicon"]&.visible = false
        @sprites["itemicon2"]&.visible = false
        @sprites["itembackground"]&.visible = false
    end

    def drawPage(page)
        if @pokemon.egg?
            drawPageOneEgg
            return
        end
        refreshItemIcons
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        base   = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        shadow = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        # Set background image
        bg_path = "Graphics/Pictures/Summary/bg_#{page}"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(bg_path)
        imagepos = []
        # Show the Poké Ball containing the Pokémon
        ballimage = format("Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball)
        unless pbResolveBitmap(ballimage)
            ballimage = format("Graphics/Pictures/Summary/icon_ball_%02d", pbGetBallType(@pokemon.poke_ball))
        end
        imagepos.push([ballimage, 14, 60])
        # Show status/fainted/Pokérus infected icon
        statusImageIndex = @pokemon.getStatusImageIndex
        imagepos.push([addLanguageSuffix("Graphics/Pictures/statuses"), 124, 100, 0, 16 * statusImageIndex, 44, 16]) if statusImageIndex >= 0
        # Show hot streak icon
        imagepos.push([sprintf("Graphics/Pictures/Summary/hot_streak"), 176, 100]) if @pokemon.onHotStreak?
        # Show shininess star
        if @pokemon.shiny?
            shinyIconFileName = @pokemon.shiny_variant? ? "Graphics/Pictures/shiny_variant" : "Graphics/Pictures/shiny"
            imagepos.push([sprintf(shinyIconFileName), 2, 134])
        end
        # Draw all images
        pbDrawImagePositions(overlay, imagepos)
        # Write various bits of text
        pagename = [_INTL("INFO"),
                    _INTL("PERSONALITY"),
                    _INTL("SKILLS"),
                    _INTL("MOVES"),
                    _INTL("RIBBONS"),][page - 1]
        # text colour for things like level and held item
        misc_base = MessageConfig.pbDefaultTextMainColor
        misc_shadow = MessageConfig.pbDefaultTextShadowColor
        textpos = [
            [pagename, 26, 10, 0, base, shadow],
            [@pokemon.name, 46, 56, 0, base, shadow],
            [@pokemon.level.to_s, 46, 86, 0, misc_base, misc_shadow],
        ]
        itemLabel = @pokemon.hasMultipleItems? ? _INTL("Items") : _INTL("Item")
        textpos.push([itemLabel, 66, 312, 0, base, shadow]) if page != 3
        # Write the gender symbol
        if @pokemon.male?
            textpos.push([_INTL("♂"), 178, 56, 0, Color.new(24, 112, 216), Color.new(136, 168, 208)])
        elsif @pokemon.female?
            textpos.push([_INTL("♀"), 178, 56, 0, Color.new(248, 56, 32), Color.new(224, 152, 144)])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
		# Write the held item's name
        unless page == 3
			itemText = []
            if @pokemon.hasItem?  
                itemName = @pokemon.itemsName
                itemNameX = 16
				itemNameY = 346
                if @pokemon.hasMultipleItems?
				    itemNameY += 2
                    itemNameX -= 8
                end
                itemText.push([itemName, itemNameX, itemNameY, 0, misc_base, misc_shadow])
            else
                no_item_base = darkMode? ? Color.new(208, 208, 208) : Color.new(192, 200, 208)
                no_item_shadow = darkMode? ? Color.new(104, 104, 104) : Color.new(208, 216, 224)
                itemText.push([_INTL("None"), 16, 346, 0, no_item_base, no_item_shadow])
            end
			overlay.font.name = MessageConfig.pbGetNarrowFontName
			overlay.font.size = 20 if @pokemon.hasMultipleItems?
			pbDrawTextPositions(overlay, itemText)
			pbSetSystemFont(overlay)
        end
        # Make move info invisible
        @moveInfoDisplay.visible = false
        @extraInfoOverlay.visible = false
        # Assume pokemon is visible
        @sprites["pokemon"].visible = true
        # Draw page-specific information
        case page
        when 1 then drawPageOne
        when 2 then drawPageTwo
        when 3 then drawPageThree
        when 4 then drawPageFour
        end
    end

    def drawPageOne
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        shadow = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        blackBase = MessageConfig.pbDefaultTextMainColor
        blackShadow = MessageConfig.pbDefaultTextShadowColor
        # Write various bits of text
        infoTextLabelX = 238
        infoTextInsertedX = 435
        infoLabelBaseY = 74
        textpos = [
            [_INTL("Species"), infoTextLabelX, infoLabelBaseY, 0, base, shadow],
            [@pokemon.speciesName, infoTextInsertedX, infoLabelBaseY, 2, blackBase, blackShadow],
            [_INTL("Type"), infoTextLabelX, infoLabelBaseY + 32, 0, base, shadow],
            [_INTL("OT"), infoTextLabelX, infoLabelBaseY + 32 * 2, 0, base, shadow],
            [_INTL("ID No."), infoTextLabelX, infoLabelBaseY + 32 * 3, 0, base, shadow],
            [_INTL("Marks"), infoTextLabelX, infoLabelBaseY + 32 * 4, 0, base, shadow],
        ]
        # Write Original Trainer's name and ID number
        if @pokemon.owner.name.empty?
            textpos.push([_INTL("RENTAL"), infoTextInsertedX, infoLabelBaseY + 32 * 2, 2, blackBase, blackShadow])
            textpos.push(["?????", infoTextInsertedX, infoLabelBaseY + 32 * 3, 2, blackBase, blackShadow])
        else
            textpos.push([@pokemon.owner.name, infoTextInsertedX, infoLabelBaseY + 32 * 2, 2, blackBase, blackShadow])
            textpos.push([format("%05d", @pokemon.owner.public_id), infoTextInsertedX, infoLabelBaseY + 32 * 3, 2, blackBase,
                          blackShadow,])
        end
        # Draw the Pokémon's markings
        drawMarkings(overlay,infoTextInsertedX - 48,infoLabelBaseY + 32 * 4 + 12)
        # Write the Pokemon's original map and level of obtaining
        obtainText = _INTL("Obtained at level {1} in", @pokemon.obtain_level)
        textpos.push([obtainText, infoTextLabelX, infoLabelBaseY + 32 * 5 + 2, 0, blackBase, blackShadow])
        mapname = pbGetMapNameFromId(@pokemon.obtain_map)
        mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
        mapname = _INTL("a faraway place") if nil_or_empty?(mapname)
        met_base = darkMode? ? Color.new(136, 168, 208) : Color.new(24, 112, 216)
        met_shadow = darkMode? ? Color.new(24, 112, 216) : Color.new(136, 168, 208)
        textpos.push([mapname, infoTextLabelX, infoLabelBaseY + 32 * 6 - 2, 0, met_base, met_shadow])
        # Write experience point info
        endexp = @pokemon.growth_rate.minimum_exp_for_level(@pokemon.level + 1)
        textpos.push([_INTL("Exp. Points"), 238, infoLabelBaseY + 32 * 7, 0, base, shadow])
        textpos.push([@pokemon.exp.to_s_formatted, 488, infoLabelBaseY + 32 * 7, 1, blackBase, blackShadow])
        textpos.push([_INTL("To Next Lv."), 238, infoLabelBaseY + 32 * 8, 0, base, shadow])
        textpos.push([(endexp - @pokemon.exp).to_s_formatted, 488, infoLabelBaseY + 32 * 8, 1, blackBase,
                      blackShadow,])
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw Pokémon type(s)
        type1_number = GameData::Type.get(@pokemon.type1).id_number
        type2_number = GameData::Type.get(@pokemon.type2).id_number
        type1rect = Rect.new(0, type1_number * 28, 64, 28)
        type2rect = Rect.new(0, type2_number * 28, 64, 28)
        if @pokemon.type1 == @pokemon.type2
            overlay.blt(402, infoLabelBaseY + 32 + 8, @typebitmap.bitmap, type1rect)
        else
            overlay.blt(370, infoLabelBaseY + 32 + 8, @typebitmap.bitmap, type1rect)
            overlay.blt(436, infoLabelBaseY + 32 + 8, @typebitmap.bitmap, type2rect)
        end
        # Draw Exp bar
        if @pokemon.level < GameData::GrowthRate.max_level
            w = @pokemon.exp_fraction * 128
            w = (w / 2).round * 2
            pbDrawImagePositions(overlay, [
                                     ["Graphics/Pictures/Summary/overlay_exp", 362, 372, 0, 0, w, 6],
                                 ])
        end
    end

    def drawPageOneEgg
        refreshItemIcons
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        base   = Color.new(248, 248, 248)
        shadow = Color.new(104, 104, 104)
        # Set background image
        @sprites["background"].setBitmap("Graphics/Pictures/Summary/bg_egg")
        imagepos = []
        # Show the Poké Ball containing the Pokémon
        ballimage = format("Graphics/Pictures/Summary/icon_ball_%s", @pokemon.poke_ball)
        unless pbResolveBitmap(ballimage)
            ballimage = format("Graphics/Pictures/Summary/icon_ball_%02d", pbGetBallType(@pokemon.poke_ball))
        end
        imagepos.push([ballimage, 14, 60])
        # Draw all images
        pbDrawImagePositions(overlay, imagepos)
        # Write various bits of text
        textpos = [
            [_INTL("STORY"), 26, 10, 0, base, shadow],
            [@pokemon.name, 46, 56, 0, base, shadow],
            [_INTL("Item"), 66, 312, 0, base, shadow],
        ]
        # Write the held item's name
        if @pokemon.hasItem?
            textpos.push([@pokemon.item.name, 16, 346, 0, MessageConfig::DARK_TEXT_MAIN_COLOR, MessageConfig::DARK_TEXT_SHADOW_COLOR])
        else
            textpos.push([_INTL("None"), 16, 346, 0, Color.new(192, 200, 208), Color.new(208, 216, 224)])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        memo = ""
        # Write date received
        if @pokemon.timeReceived
            date  = @pokemon.timeReceived.day
            month = pbGetMonthName(@pokemon.timeReceived.mon)
            year  = @pokemon.timeReceived.year
            memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n", date, month, year)
        end
        # Write map name egg was received on
        mapname = pbGetMapNameFromId(@pokemon.obtain_map)
        mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
        if mapname && mapname != ""
            memo += _INTL(
                "<c3=404040,B0B0B0>A mysterious Pokémon Egg received from <c3=F83820,E09890>{1}<c3=404040,B0B0B0>.\n", mapname)
        else
            memo += _INTL("<c3=404040,B0B0B0>A mysterious Pokémon Egg.\n", mapname)
        end
        memo += "\n" # Empty line
        # Write Egg Watch blurb
        memo += _INTL("<c3=404040,B0B0B0>\"The Egg Watch\"\n")
        eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
        if @pokemon.steps_to_hatch < 10_200
            eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.")
        end
        if @pokemon.steps_to_hatch < 2550
            eggstate = _INTL("It appears to move occasionally. It may be close to hatching.")
        end
        if @pokemon.steps_to_hatch < 1275
            eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!")
        end
        memo += format("<c3=404040,B0B0B0>%s\n", eggstate)
        # Draw all text
        drawFormattedTextEx(overlay, 232, 82, 268, memo)
        # Draw the Pokémon's markings
        drawMarkings(overlay, 84, 292)
    end

    def drawPageTwo
        overlay = @sprites["overlay"].bitmap
        memo = ""

        # Traits
        if darkMode?
            # repeating this is a bit ugly but not as ugly as iffing in the middle of all of these strings
            memo += _INTL("<c3=E09890,F83820>Traits:<c3=F8F8F8,686868>")
            memo += "\n"
            memo += _INTL("<c3=F8F8F8{2},686868>{1}", @pokemon.displayTrait1, @pokemon.trait1 ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=F8F8F8{2},686868>{1}", @pokemon.displayTrait2, @pokemon.trait2 ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=F8F8F8{2},686868>{1}", @pokemon.displayTrait3, @pokemon.trait3 ? "FF" : "77")
            memo += "\n"
            memo += "\n"
            memo += _INTL("<c3=E09890,F83820>Likes:<c3=F8F8F8,686868>")
            memo += "\n"
            memo += _INTL("<c3=F8F8F8{2},686868>{1}", @pokemon.displayLike, @pokemon.like ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=E09890,F83820>Dislikes:<c3=F8F8F8,686868>")
            memo += "\n"
            memo += _INTL("<c3=F8F8F8{2},686868>{1}", @pokemon.displayDislike, @pokemon.dislike ? "FF" : "77")
            memo += "\n"
        else
            memo += _INTL("<c3=F83820,E09890>Traits:<c3=404040,B0B0B0>")
            memo += "\n"
            memo += _INTL("<c3=404040{2},B0B0B0>{1}", @pokemon.displayTrait1, @pokemon.trait1 ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=404040{2},B0B0B0>{1}", @pokemon.displayTrait2, @pokemon.trait2 ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=404040{2},B0B0B0>{1}", @pokemon.displayTrait3, @pokemon.trait3 ? "FF" : "77")
            memo += "\n"
            memo += "\n"
            memo += _INTL("<c3=F83820,E09890>Likes:<c3=404040,B0B0B0>")
            memo += "\n"
            memo += _INTL("<c3=404040{2},B0B0B0>{1}", @pokemon.displayLike, @pokemon.like ? "FF" : "77")
            memo += "\n"
            memo += _INTL("<c3=F83820,E09890>Dislikes:<c3=404040,B0B0B0>")
            memo += "\n"
            memo += _INTL("<c3=404040{2},B0B0B0>{1}", @pokemon.displayDislike, @pokemon.dislike ? "FF" : "77")
            memo += "\n"
        end

        # # Write date received
        # if @pokemon.timeReceived
        #     date  = @pokemon.timeReceived.day
        #     month = pbGetMonthName(@pokemon.timeReceived.mon)
        #     year  = @pokemon.timeReceived.year
        #     memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n", date, month, year)
        # end

        # Write map name Pokémon was received on
        # mapname = pbGetMapNameFromId(@pokemon.obtain_map)
        # mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
        # mapname = _INTL("Faraway place") if !mapname || mapname == ""
        # memo += format("<c3=F83820,E09890>%s\n", mapname)

        # Write how Pokémon was obtained
        # mettext = [_INTL("Met at Lv. {1}.", @pokemon.obtain_level),
        #            _INTL("Egg received."),
        #            _INTL("Traded at Lv. {1}.", @pokemon.obtain_level),
        #            "",
        #            _INTL("Had a fateful encounter at Lv. {1}.", @pokemon.obtain_level),][@pokemon.obtain_method]
        # memo += format("<c3=404040,B0B0B0>%s\n", mettext) if mettext && mettext != ""

        # # If Pokémon was hatched, write when and where it hatched
        # if @pokemon.obtain_method == 1
        #     if @pokemon.timeEggHatched
        #         date  = @pokemon.timeEggHatched.day
        #         month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        #         year  = @pokemon.timeEggHatched.year
        #         memo += _INTL("<c3=404040,B0B0B0>{1} {2}, {3}\n", date, month, year)
        #     end
        #     mapname = pbGetMapNameFromId(@pokemon.hatched_map)
        #     mapname = _INTL("Faraway place") if !mapname || mapname == ""
        #     memo += format("<c3=F83820,E09890>%s\n", mapname)
        #     memo += _INTL("<c3=404040,B0B0B0>Egg hatched.\n")
        # else
        #     memo += "\n" # Empty line
        # end

        # Write all text
        drawFormattedTextEx(overlay, 232, 82, 268, memo)

        playTraitsTutorial unless $PokemonGlobal.traitsTutorialized
    end

    def drawPageThree
        hideItems
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        shadow = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        # Determine which stats are boosted and lowered by the Pokémon's nature
        statshadows = {}
        GameData::Stat.each_main { |s| statshadows[s.id] = shadow }
        # Write various bits of text
        statNameX = 248 + 12
        statTotalX = 492
        evAmountX  = 372 + 12
        stat_value_color_base   = MessageConfig.pbDefaultTextMainColor
        stat_value_color_shadow = MessageConfig.pbDefaultTextShadowColor
        ev_color_base   = darkMode? ? Color.new(200, 200, 248) : Color.new(128, 128, 200)
        ev_color_shadow = darkMode? ? Color.new(104, 104, 104) : Color.new(220, 220, 220)
        textpos = [
            [_INTL("HP"), statNameX + 44, 70, 2, base, statshadows[:HP]],
            [format("%d/%d", @pokemon.hp, @pokemon.totalhp), statTotalX, 70, 1, stat_value_color_base],
            [_INTL("Attack"), statNameX, 114, 0, base, statshadows[:ATTACK]],
            [format("%d", @pokemon.attack), statTotalX, 114, 1, stat_value_color_base, stat_value_color_shadow],
            [_INTL("Defense"), statNameX, 146, 0, base, statshadows[:DEFENSE]],
            [format("%d", @pokemon.defense), statTotalX, 146, 1, stat_value_color_base, stat_value_color_shadow],
            [_INTL("Sp. Atk"), statNameX, 178, 0, base, statshadows[:SPECIAL_ATTACK]],
            [format("%d", @pokemon.spatk), statTotalX, 178, 1, stat_value_color_base, stat_value_color_shadow],
            [_INTL("Sp. Def"), statNameX, 210, 0, base, statshadows[:SPECIAL_DEFENSE]],
            [format("%d", @pokemon.spdef), statTotalX, 210, 1, stat_value_color_base, stat_value_color_shadow],
            [_INTL("Speed"), statNameX, 242, 0, base, statshadows[:SPEED]],
            [format("%d", @pokemon.speed), statTotalX, 242, 1, stat_value_color_base, stat_value_color_shadow],
        ]
        if @pokemon.ev[:HP] != 0
            textpos.push([format("%d", @pokemon.ev[:HP]), evAmountX, 70, 2, ev_color_base,
                          ev_color_shadow,])
        end
        if @pokemon.ev[:ATTACK] != 0
            textpos.push([format("%d", @pokemon.ev[:ATTACK]), evAmountX, 114, 2, ev_color_base,
                          ev_color_shadow,])
        end
        if @pokemon.ev[:DEFENSE] != 0
            textpos.push([format("%d", @pokemon.ev[:DEFENSE]), evAmountX, 146, 2, ev_color_base,
                          ev_color_shadow,])
        end
        if @pokemon.ev[:SPECIAL_ATTACK] != 0
            textpos.push([format("%d", @pokemon.ev[:SPECIAL_ATTACK]), evAmountX, 178, 2, ev_color_base,
                          ev_color_shadow,])
        end
        if @pokemon.ev[:SPECIAL_DEFENSE] != 0
            textpos.push([format("%d", @pokemon.ev[:SPECIAL_DEFENSE]), evAmountX, 210, 2, ev_color_base,
                          ev_color_shadow,])
        end
        if @pokemon.ev[:SPEED] != 0
            textpos.push([format("%d", @pokemon.ev[:SPEED]), evAmountX, 242, 2, ev_color_base,
                          ev_color_shadow,])
        end

        # Draw ability name and description
        ability = @pokemon.ability 
        @sprites["pokemon"].visible = false if @sprites["pokemon"]
        @sprites["pokeicon"].visible = false
        ability_base   = MessageConfig.pbDefaultTextMainColor
        ability_shadow = MessageConfig.pbDefaultTextShadowColor
        if ability
            drawFormattedTextEx(overlay, 8, 250, 480, ability.name, base, shadow)
            abilityDescription = addBattleKeywordHighlighting(ability.description)
            drawFormattedTextEx(overlay, 12, 286, 450, abilityDescription, ability_base, ability_shadow)
        end

        # Draw all text
        pbDrawTextPositions(overlay, textpos)

        # Draw HP bar
        if @pokemon.hp > 0
            w = @pokemon.hp * 96 * 1.0 / @pokemon.totalhp
            w = 1 if w < 1
            w = (w / 2).round * 2
            hpzone = 0
            hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
            hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
            imagepos = [
                ["Graphics/Pictures/Summary/overlay_hp", statNameX + 112, 110, 0, hpzone * 6, w, 6],
            ]
            pbDrawImagePositions(overlay, imagepos)
        end
    end

    def drawPageFour
        @moveInfoDisplay.visible = true
        @extraInfoOverlay.visible = true
        hideItems

        overlay = @sprites["overlay"].bitmap
        overlay.clear
        base   = Color.new(248, 248, 248)
        shadow = Color.new(104, 104, 104)
        @sprites["pokemon"].visible = false
        @sprites["pokeicon"].visible = false
        textpos  = [[_INTL("MOVES"), 26, 10, 0, base, shadow]]
        imagepos = []
        drawMoveNames(textpos)
        # Draw all text and images
        pbDrawTextPositions(overlay, textpos)
        pbDrawImagePositions(overlay, imagepos)
    end

    def drawMoveNames(textpos,extra_move = nil)
        moveBase   = MessageConfig::pbDefaultTextMainColor
        fadedBase  = MessageConfig.pbDefaultFadedTextColor
        moveShadow = MessageConfig::pbDefaultTextShadowColor
        # Write move names
        for i in 0...Pokemon::MAX_MOVES
            move = @pokemon.moves[i]
            xPos = SUMMARY_MOVE_NAMES_X_INIT + 126 + (i % 2) * SUMMARY_MOVE_NAMES_X_OFFSET
            yPos = SUMMARY_MOVE_NAMES_Y_INIT + 10 + (i/2) * SUMMARY_MOVE_NAMES_Y_OFFSET
            if move
                individualMoveBaseColor = moveBase
                if move.type
                    move_type = GameData::Type.get(move.type)
                    individualMoveBaseColor = darkMode? ? move_type.color : move_type.dark_color
                end
                textpos.push([move.name, xPos, yPos, 2, individualMoveBaseColor, moveShadow])
            else
                textpos.push(["---", xPos, yPos, 2, fadedBase, moveShadow])
            end
        end

        if extra_move
            xPos = SUMMARY_MOVE_NAMES_X_INIT + 126 + SUMMARY_MOVE_NAMES_X_OFFSET
            yPos = SUMMARY_LEARNING_MOVE_NAME_Y + 10
            extraMoveBaseColor = moveBase
            if extra_move.type
                move_type = GameData::Type.get(extra_move.type)
                extraMoveBaseColor = darkMode? ? move_type.color : move_type.dark_color
            end
            textpos.push([extra_move.name, xPos, yPos, 2, extraMoveBaseColor, moveShadow])
        end
    end

    def drawPageFourSelecting(move_to_learn)
        @moveInfoDisplay.visible = true
        @extraInfoOverlay.visible = true
        hideItems

        overlay = @sprites["overlay"].bitmap
        overlay.clear
        base   = Color.new(248, 248, 248)
        shadow = Color.new(104, 104, 104)
        # Set background image
        if move_to_learn
            path = "Graphics/Pictures/Summary/bg_learnmove"
            path += "_dark" if darkMode?
            @sprites["background"].setBitmap(path)
        else
            path = "Graphics/Pictures/Summary/bg_movedetail"
            path += "_dark" if darkMode?
            @sprites["background"].setBitmap(path)
        end
        # Write various bits of text
        textpos  = [[_INTL("MOVES"), 26, 10, 0, base, shadow]]
        imagepos = []

        drawMoveNames(textpos,move_to_learn)

        # Draw all text and images
        pbDrawTextPositions(overlay, textpos)
        pbDrawImagePositions(overlay, imagepos)
    end    

    def drawSelectedMove(move_to_learn, selected_move)
        # Draw all of page four, except selected move's details
        drawPageFourSelecting(move_to_learn)

        hideItems
        @sprites["pokemon"].visible = false if @sprites["pokemon"]
        @sprites["pokeicon"].visible = false

        writeMoveInfoToInfoOverlay3x3(@extraInfoOverlay.bitmap,selected_move)

        if @battle&.pokemonIsActiveBattler?(@pokemon) && !$PokemonGlobal.moveInfoPanelTutorialized
            playMoveInfoPanelTutorial
        end
    end

    def pbGoToPrevious
        newindex = @partyindex
        while newindex > 0
            newindex -= 1
            if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
                @partyindex = newindex
                break
            end
        end
    end

    def pbGoToNext
        newindex = @partyindex
        while newindex < @party.length - 1
            newindex += 1
            if @party[newindex] && (@page == 1 || !@party[newindex].egg?)
                @partyindex = newindex
                break
            end
        end
    end

    def pbChangePokemon
        @pokemon = @party[@partyindex]
        @sprites["pokemon"].setPokemonBitmap(@pokemon)
        refreshItemIcons(false)
        pbSEStop
        @pokemon.play_cry
    end

    def pbMoveSelection
        @sprites["movesel"].visible = true
        @sprites["movesel"].index = 0
        selmove    = 0
        oldselmove = 0
        switching = false
        drawSelectedMove(nil, @pokemon.moves[selmove])
        loop do
            Graphics.update
            Input.update
            pbUpdate
            selmove_prev = selmove
            if @sprites["movepresel"].index == @sprites["movesel"].index
                @sprites["movepresel"].z = @sprites["movesel"].z + 1
            else
                @sprites["movepresel"].z = @sprites["movesel"].z
            end
            if Input.trigger?(Input::BACK)
                switching ? pbPlayCancelSE : pbPlayCloseMenuSE
                unless switching
                    @extraInfoOverlay.bitmap.clear
                    break
                end
                @sprites["movepresel"].visible = false
                switching = false
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                if selmove == Pokemon::MAX_MOVES
                    break unless switching
                    @sprites["movepresel"].visible = false
                    switching = false
                elsif !switching
                    @sprites["movepresel"].index = selmove
                    @sprites["movepresel"].visible = true
                    oldselmove = selmove
                    switching = true
                else
                    tmpmove = @pokemon.moves[oldselmove]
                    @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
                    @pokemon.moves[selmove]    = tmpmove
                    @sprites["movepresel"].visible = false
                    switching = false
                    drawSelectedMove(nil, @pokemon.moves[selmove])
                end
            elsif Input.trigger?(Input::UP)
                selmove -= 2 if selmove >= 2
            elsif Input.trigger?(Input::DOWN)
                selmove += 2 if selmove < Pokemon::MAX_MOVES - 2
            elsif Input.trigger?(Input::LEFT)
                selmove -= 1 if selmove % 2 == 1
            elsif Input.trigger?(Input::RIGHT)
                selmove += 1 if selmove % 2 == 0
            end

            if selmove != selmove_prev
                selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
                if selected_move
                    @sprites["movesel"].index = selmove
                    pbPlayCursorSE
                    drawSelectedMove(nil, selected_move)
                else
                    selmove = selmove_prev
                    pbPlayBuzzerSE
                end
            end
        end
        @sprites["movesel"].visible = false
    end

    def pbRibbonSelection
        @sprites["ribbonsel"].visible = true
        @sprites["ribbonsel"].index = 0
        selribbon    = @ribbonOffset * 4
        oldselribbon = selribbon
        switching = false
        numRibbons = @pokemon.ribbons.length
        numRows    = [((numRibbons + 3) / 4).floor, 3].max
        drawSelectedRibbon(@pokemon.ribbons[selribbon])
        loop do
            @sprites["uparrow"].visible = (@ribbonOffset > 0)
            @sprites["downarrow"].visible = (@ribbonOffset < numRows - 3)
            Graphics.update
            Input.update
            pbUpdate
            if @sprites["ribbonpresel"].index == @sprites["ribbonsel"].index
                @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z + 1
            else
                @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
            end
            hasMovedCursor = false
            if Input.trigger?(Input::BACK)
                switching ? pbPlayCancelSE : pbPlayCloseMenuSE
                break unless switching
                @sprites["ribbonpresel"].visible = false
                switching = false
            elsif Input.trigger?(Input::USE)
                if !switching
                    if @pokemon.ribbons[selribbon]
                        pbPlayDecisionSE
                        @sprites["ribbonpresel"].index = selribbon - @ribbonOffset * 4
                        oldselribbon = selribbon
                        @sprites["ribbonpresel"].visible = true
                        switching = true
                    end
                else
                    pbPlayDecisionSE
                    tmpribbon                      = @pokemon.ribbons[oldselribbon]
                    @pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
                    @pokemon.ribbons[selribbon]    = tmpribbon
                    if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
                        @pokemon.ribbons.compact!
                        if selribbon >= numRibbons
                            selribbon = numRibbons - 1
                            hasMovedCursor = true
                        end
                    end
                    @sprites["ribbonpresel"].visible = false
                    switching = false
                    drawSelectedRibbon(@pokemon.ribbons[selribbon])
                end
            elsif Input.trigger?(Input::UP)
                selribbon -= 4
                selribbon += numRows * 4 if selribbon < 0
                hasMovedCursor = true
                pbPlayCursorSE
            elsif Input.trigger?(Input::DOWN)
                selribbon += 4
                selribbon -= numRows * 4 if selribbon >= numRows * 4
                hasMovedCursor = true
                pbPlayCursorSE
            elsif Input.trigger?(Input::LEFT)
                selribbon -= 1
                selribbon += 4 if selribbon % 4 == 3
                hasMovedCursor = true
                pbPlayCursorSE
            elsif Input.trigger?(Input::RIGHT)
                selribbon += 1
                selribbon -= 4 if selribbon % 4 == 0
                hasMovedCursor = true
                pbPlayCursorSE
            end
            next unless hasMovedCursor
            @ribbonOffset = (selribbon / 4).floor if selribbon < @ribbonOffset * 4
            @ribbonOffset = (selribbon / 4).floor - 2 if selribbon >= (@ribbonOffset + 3) * 4
            @ribbonOffset = 0 if @ribbonOffset < 0
            @ribbonOffset = numRows - 3 if @ribbonOffset > numRows - 3
            @sprites["ribbonsel"].index    = selribbon - @ribbonOffset * 4
            @sprites["ribbonpresel"].index = oldselribbon - @ribbonOffset * 4
            drawSelectedRibbon(@pokemon.ribbons[selribbon])
        end
        @sprites["ribbonsel"].visible = false
    end

    def pbMarking(pokemon)
        @sprites["markingbg"].visible = true
        @sprites["markingoverlay"].visible = true
        @sprites["markingsel"].visible     = true
        base   = Color.new(248, 248, 248)
        shadow = Color.new(104, 104, 104)
        ret = pokemon.markings
        markings = pokemon.markings
        index = 0
        redraw = true
        markrect = Rect.new(0, 0, 16, 16)
        loop do
            # Redraw the markings and text
            if redraw
                @sprites["markingoverlay"].bitmap.clear
                for i in 0...6
                    markrect.x = i * 16
                    markrect.y = (markings & (1 << i) != 0) ? 16 : 0
                    @sprites["markingoverlay"].bitmap.blt(300 + 58 * (i % 3), 154 + 50 * (i / 3), @markingbitmap.bitmap,
    markrect)
                end
                textpos = [
                    [_INTL("Mark {1}", pokemon.name), 366, 90, 2, base, shadow],
                    [_INTL("OK"), 366, 242, 2, base, shadow],
                    [_INTL("Cancel"), 366, 292, 2, base, shadow],
                ]
                pbDrawTextPositions(@sprites["markingoverlay"].bitmap, textpos)
                redraw = false
            end
            # Reposition the cursor
            @sprites["markingsel"].x = 284 + 58 * (index % 3)
            @sprites["markingsel"].y = 144 + 50 * (index / 3)
            if index == 6 # OK
                @sprites["markingsel"].x = 284
                @sprites["markingsel"].y = 244
                @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
            elsif index == 7 # Cancel
                @sprites["markingsel"].x = 284
                @sprites["markingsel"].y = 294
                @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height / 2
            else
                @sprites["markingsel"].src_rect.y = 0
            end
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                if index == 6 # OK
                    ret = markings
                    break
                elsif index == 7 # Cancel
                    break
                else
                    mask = (1 << index)
                    if (markings & mask) == 0
                        markings |= mask
                    else
                        markings &= ~mask
                    end
                    redraw = true
                end
            elsif Input.trigger?(Input::UP)
                if index == 7
                    index = 6
                elsif index == 6
                    index = 4
                elsif index < 3
                    index = 7
                else
                    index -= 3
                end
                pbPlayCursorSE
            elsif Input.trigger?(Input::DOWN)
                if index == 7
                    index = 1
                elsif index == 6
                    index = 7
                elsif index >= 3
                    index = 6
                else
                    index += 3
                end
                pbPlayCursorSE
            elsif Input.trigger?(Input::LEFT)
                if index < 6
                    index -= 1
                    index += 3 if index % 3 == 2
                    pbPlayCursorSE
                end
            elsif Input.trigger?(Input::RIGHT)
                if index < 6
                    index += 1
                    index -= 3 if index % 3 == 0
                    pbPlayCursorSE
                end
            end
        end
        @sprites["markingbg"].visible      = false
        @sprites["markingoverlay"].visible = false
        @sprites["markingsel"].visible     = false
        if pokemon.markings != ret
            pokemon.markings = ret
            return true
        end
        return false
    end

    def pbOptions
        return pbMarking(@pokemon)
    end

    def pbChooseMoveToForget(move_to_learn)
        new_move = move_to_learn ? Pokemon::Move.new(move_to_learn) : nil
        selmove = move_to_learn ? Pokemon::MAX_MOVES : 0
        @sprites["pokemon"].visible = true unless @forget
        hideItems
        loop do
            Graphics.update
            Input.update
            pbUpdate
            selmove_prev = selmove
            if Input.trigger?(Input::BACK)
                selmove = Pokemon::MAX_MOVES
                pbPlayCloseMenuSE if new_move
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                break
            elsif Input.trigger?(Input::UP)
                if selmove >= 2 && selmove < Pokemon::MAX_MOVES
                    selmove -= 2
                elsif selmove == 1 && move_to_learn
                    selmove = Pokemon::MAX_MOVES # New move
                end
            elsif Input.trigger?(Input::DOWN)
                if selmove < 2
                    selmove += 2
                elsif selmove == Pokemon::MAX_MOVES
                    selmove = 1
                end
            elsif Input.trigger?(Input::LEFT)
                selmove -= 1 if selmove % 2 == 1 && selmove != Pokemon::MAX_MOVES
            elsif Input.trigger?(Input::RIGHT)
                selmove += 1 if selmove % 2 == 0 && selmove != Pokemon::MAX_MOVES
            end

            if selmove != selmove_prev
                selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
                if selected_move
                    @sprites["movesel"].index = selmove
                    pbPlayCursorSE
                    drawSelectedMove(new_move, selected_move)
                else
                    selmove = selmove_prev
                    pbPlayBuzzerSE
                end
            end
        end
        return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
    end

    def pbScene
        @pokemon.play_cry
        loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
                pbSEStop
                @pokemon.play_cry
            elsif Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)
                if @page == 4
                    pbPlayDecisionSE
                    pbMoveSelection
                    dorefresh = true
                elsif @page == 5
                    pbPlayDecisionSE
                    pbRibbonSelection
                    dorefresh = true
                elsif @battle.nil?
                    pbPlayDecisionSE
                    dorefresh = pbOptions
                end
            elsif Input.trigger?(Input::UP) && !@party.nil? && @partyindex > 0
                oldindex = @partyindex
                pbGoToPrevious
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.trigger?(Input::DOWN) && !@party.nil? && @partyindex < @party.length - 1
                oldindex = @partyindex
                pbGoToNext
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
                oldpage = @page
                @page -= 1
                @page = 1 if @page < 1
                @page = 4 if @page > 4
                if @page != oldpage   # Move to next page
                    pbSEPlay("GUI summary change page")
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
                oldpage = @page
                @page += 1
                @page = 1 if @page < 1
                @page = 4 if @page > 4
                if @page != oldpage   # Move to next page
                    pbSEPlay("GUI summary change page")
                    @ribbonOffset = 0
                    dorefresh = true
                end
            end
            drawPage(@page) if dorefresh
        end
        return @partyindex
    end
end

#===============================================================================
#
#===============================================================================
class PokemonSummaryScreen
    def initialize(scene, battle = nil)
        @scene = scene
        @battle = battle
    end

    def pbStartScreen(party, partyindex)
        @scene.pbStartScene(party, partyindex, @battle)
        ret = @scene.pbScene
        @scene.pbEndScene
        return ret
    end

    def pbStartForgetScreen(party, partyindex, move_to_learn)
        ret = -1
        @scene.pbStartForgetScene(party, partyindex, move_to_learn)
        loop do
            ret = @scene.pbChooseMoveToForget(move_to_learn)
            break if ret < 0 || !move_to_learn
            break if $DEBUG || !party[partyindex].moves[ret].hidden_move?
            pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
        end
        @scene.pbEndScene
        return ret
    end

    def pbStartChooseMoveScreen(party, partyindex, message)
        ret = -1
        @scene.pbStartForgetScene(party, partyindex, nil)
        pbMessage(message) { @scene.pbUpdate }
        loop do
            ret = @scene.pbChooseMoveToForget(nil)
            break if ret >= 0
            pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
        end
        @scene.pbEndScene
        return ret
    end

    def pbStartSingleScreen(pokemon)
        @scene.pbStartSingleScene(pokemon)
        ret = @scene.pbScene
        @scene.pbEndScene
        return ret
    end
end

#===============================================================================
#
#===============================================================================
def pbChooseMove(pokemon, variableNumber, nameVarNumber)
    return unless pokemon
    ret = -1
    pbFadeOutIn do
        scene = PokemonSummary_Scene.new
        screen = PokemonSummaryScreen.new(scene)
        ret = screen.pbStartForgetScreen([pokemon], 0, nil)
    end
    $game_variables[variableNumber] = ret
    if ret >= 0
        $game_variables[nameVarNumber] = pokemon.moves[ret].name
    else
        $game_variables[nameVarNumber] = ""
    end
    $game_map.need_refresh = true if $game_map
end
