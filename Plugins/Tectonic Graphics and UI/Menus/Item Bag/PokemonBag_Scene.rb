#===============================================================================
# Bag visuals
#===============================================================================
class PokemonBag_Scene
    ITEMSVISIBLE          = 7
  
    def pbUpdate
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbStartScene(bag,choosing=false,filterproc=nil,resetpocket=true,startingPocket=nil)
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @bag        = bag
      @choosing   = choosing
      @filterproc = filterproc
      pbRefreshFilter
      lastpocket = startingPocket || @bag.lastpocket
      @numfilledpockets = @bag.pockets.length-1
      if @choosing
        @numfilledpockets = 0
        if @filterlist != nil
          for i in 1...@bag.pockets.length
            @numfilledpockets += 1 if @filterlist[i].length>0
          end
        else
          for i in 1...@bag.pockets.length
            @numfilledpockets += 1 if @bag.pockets[i].length>0
          end
        end
        lastpocket = (resetpocket) ? 1 : (startingPocket || @bag.lastpocket)
        if (@filterlist && @filterlist[lastpocket].length==0) ||
           (!@filterlist && @bag.pockets[lastpocket].length==0)
          for i in 1...@bag.pockets.length
            if @filterlist && @filterlist[i].length>0
              lastpocket = i; break
            elsif !@filterlist && @bag.pockets[i].length>0
              lastpocket = i; break
            end
          end
        end
      end
      @bag.lastpocket = lastpocket
      @sliderbitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Bag/icon_slider")))
      @slider_inactive_bitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Bag/slider_inactive")))
      @pocketbitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Bag/icon_pocket")))
      @pocket_unselected_bitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Bag/icon_pocket_unselected")))
      @pocket_unused_bitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Bag/icon_pocket_empty")))
      @sprites = {}
      @sprites["background"] = IconSprite.new(0,0,@viewport)
      @sprites["background_color"] = IconSprite.new(0,0,@viewport)
      @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["pocketicon"] = BitmapSprite.new(186,52,@viewport)
      @sprites["pocketicon"].x = 0
      @sprites["pocketicon"].y = 202
      @sprites["itemlist"] = Window_PokemonBag.new(@bag,@filterlist,lastpocket,168,-8,314,40+32+ITEMSVISIBLE*32)
      @sprites["itemlist"].viewport    = @viewport
      @sprites["itemlist"].pocket      = lastpocket
      @sprites["itemlist"].index       = @bag.getChoice(lastpocket)
      @sprites["itemlist"].baseColor   = MessageConfig.pbDefaultTextMainColor
      @sprites["itemlist"].shadowColor = MessageConfig.pbDefaultTextShadowColor
      @sprites["itemicon"] = ItemIconSprite.new(48,Graphics.height-48,nil,@viewport)
      @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize("",
         72, 270, Graphics.width - 72 - 24, 128, @viewport)
      @sprites["itemtext"].baseColor   = MessageConfig::LIGHT_TEXT_MAIN_COLOR
      @sprites["itemtext"].shadowColor = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
      @sprites["itemtext"].visible     = true
      @sprites["itemtext"].windowskin  = nil
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
      @sprites["helpwindow"].visible  = false
      @sprites["helpwindow"].viewport = @viewport
      @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
      @sprites["msgwindow"].visible  = false
      @sprites["msgwindow"].viewport = @viewport
      pbBottomLeftLines(@sprites["helpwindow"],1)
      pbDeactivateWindows(@sprites)
      pbRefresh
      pbFadeInAndShow(@sprites)
    end
  
    def pbFadeOutScene
      @oldsprites = pbFadeOutAndHide(@sprites)
    end
  
    def pbFadeInScene
      pbFadeInAndShow(@sprites,@oldsprites)
      @oldsprites = nil
    end
  
    def pbEndScene
      pbFadeOutAndHide(@sprites) if !@oldsprites
      @oldsprites = nil
      pbDisposeSpriteHash(@sprites)
      @sliderbitmap.dispose
      @slider_inactive_bitmap.dispose
      @pocketbitmap.dispose
      @pocket_unselected_bitmap.dispose
      @pocket_unused_bitmap.dispose
      @viewport.dispose
    end
  
    def pbDisplay(msg,brief=false)
      UIHelper.pbDisplay(@sprites["msgwindow"],msg,brief) { pbUpdate }
    end
  
    def pbConfirm(msg)
      UIHelper.pbConfirm(@sprites["msgwindow"],msg) { pbUpdate }
    end
  
    def pbChooseNumber(helptext,maximum,initnum=1)
      return UIHelper.pbChooseNumber(@sprites["helpwindow"],helptext,maximum,initnum) { pbUpdate }
    end
  
    def pbShowCommands(helptext,commands,index=0)
      return UIHelper.pbShowCommands(@sprites["helpwindow"],helptext,commands,index) { pbUpdate }
    end
  
    def pbRefresh
      # Set the background image
      bg_path = sprintf("Graphics/Pictures/Bag/bg_main")
      bg_path += "_dark" if darkMode?
      @sprites["background"].setBitmap(bg_path)
      # Set the background color
      bg_color_path = sprintf("Graphics/Pictures/Bag/bg_color_#{@bag.lastpocket % 8 + 1}")
      @sprites["background_color"].setBitmap(bg_color_path)
      # Draw the pocket icons
      @sprites["pocketicon"].bitmap.clear
      bitmapWidth = @pocket_unselected_bitmap.bitmap.width
      bitmapHeight = @pocket_unselected_bitmap.bitmap.height
      @sprites["pocketicon"].bitmap.blt(6,6,@pocket_unselected_bitmap.bitmap,Rect.new(0,0,bitmapWidth/2,bitmapHeight))
      @sprites["pocketicon"].bitmap.blt(6,6+bitmapHeight+2,@pocket_unselected_bitmap.bitmap,Rect.new(bitmapWidth/2,0,bitmapWidth/2,bitmapHeight))
      if @choosing && @filterlist
        for i in 1...@bag.pockets.length
          if @filterlist[i].length == 0
            rect = Rect.new((i-1)*20,0,20,20)
            @sprites["pocketicon"].bitmap.blt(6+((i-1) % 8)*22, 6+((i-1) / 8) * 20, @pocket_unused_bitmap.bitmap, rect)
          end
        end
      end
      # Draw the selected pocket icon
      pocketGraphicIndex = (@sprites["itemlist"].pocket-1)
      @sprites["pocketicon"].bitmap.blt(2+(pocketGraphicIndex % 8)*22,2 + (pocketGraphicIndex / 8) * 22,
         @pocketbitmap.bitmap,Rect.new(pocketGraphicIndex*28,0,28,28))
      # Refresh the item window
      @sprites["itemlist"].refresh
      # Refresh more things
      pbRefreshIndexChanged
    end
  
    def pbRefreshIndexChanged
      itemlist = @sprites["itemlist"]
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      # Draw the pocket name
      pbDrawTextPositions(overlay,[
         [PokemonBag.pocketNames[@bag.lastpocket],94,150,2,MessageConfig::DARK_TEXT_MAIN_COLOR,MessageConfig::DARK_TEXT_SHADOW_COLOR]
      ])
      if itemlist.active
        overlay.blt(470,16,@slider_inactive_bitmap.bitmap,Rect.new(0,0,36,250))

        # Draw slider arrows
        showslider = false
        if itemlist.top_row>0
          overlay.blt(470,16,@sliderbitmap.bitmap,Rect.new(0,0,36,38))
          showslider = true
        end
        if itemlist.top_item+itemlist.page_item_max<itemlist.itemCount
          overlay.blt(470,228,@sliderbitmap.bitmap,Rect.new(0,38,36,38))
          showslider = true
        end
        # Draw slider box
        if showslider
          sliderheight = 174
          boxheight = (sliderheight*itemlist.page_row_max/itemlist.row_max).floor
          boxheight += [(sliderheight-boxheight)/2,sliderheight/6].min
          boxheight = [boxheight.floor,38].max
          y = 54
          y += ((sliderheight-boxheight)*itemlist.top_row/(itemlist.row_max-itemlist.page_row_max)).floor
          overlay.blt(470,y,@sliderbitmap.bitmap,Rect.new(36,0,36,4))
          i = 0
          while i*16<boxheight-4-18
            height = [boxheight-4-18-i*16,16].min
            overlay.blt(470,y+4+i*16,@sliderbitmap.bitmap,Rect.new(36,4,36,height))
            i += 1
          end
          overlay.blt(470,y+boxheight-18,@sliderbitmap.bitmap,Rect.new(36,20,36,18))
        end
      end
      # Set the selected item's icon
      @sprites["itemicon"].item = itemlist.item
      # Set the selected item's description
      @sprites["itemtext"].text =
         (itemlist.item) ? GameData::Item.get(itemlist.item).description : _INTL("Close bag.")
    end
  
    def pbRefreshFilter
      @filterlist = nil
      return if !@choosing
      return if @filterproc==nil
      @filterlist = []
      for i in 1...@bag.pockets.length
        @filterlist[i] = []
        for j in 0...@bag.pockets[i].length
          @filterlist[i].push(j) if @filterproc.call(@bag.pockets[i][j][0])
        end
      end
    end
  
    # Called when the item screen wants an item to be chosen from the screen
    def pbChooseItem(openPocketImmediately = false)
        openPocketImmediately = true if @filterlist && @numfilledpockets == 1

        @sprites["helpwindow"].visible = false
        itemwindow = @sprites["itemlist"]
        

        newpocket = itemwindow.pocket

        # Select pocket
        loop do
          Graphics.update unless openPocketImmediately
          Input.update

          if Input.trigger?(Input::LEFT)
            loop do
              newpocket = (newpocket==1) ? PokemonBag.numPockets : newpocket-1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              else
                break if @bag.pockets[newpocket].length > 0
              end
            end
          elsif Input.trigger?(Input::RIGHT)
            loop do
              newpocket = (newpocket==PokemonBag.numPockets) ? 1 : newpocket+1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length > 0
              else
                break if @bag.pockets[newpocket].length > 0
              end
            end
          elsif Input.trigger?(Input::UP)
            pocketCandidate = newpocket >= 9 ? newpocket - 8 : newpocket + 8
            if @filterlist
              newpocket = pocketCandidate if @filterlist[pocketCandidate].length > 0
            else
              newpocket = pocketCandidate
            end
          elsif Input.trigger?(Input::DOWN)
            pocketCandidate = newpocket < 9 ? newpocket + 8 : newpocket - 8
            if @filterlist
              newpocket = pocketCandidate if @filterlist[pocketCandidate].length > 0
            else
              newpocket = pocketCandidate
            end
          elsif Input.trigger?(Input::BACK)   # Cancel the item screen
            pbPlayCloseMenuSE
            return nil
          elsif Input.trigger?(Input::USE) || openPocketImmediately   # Choose item from pocket
            if @filterlist
              valid = @filterlist[newpocket].length > 0
            else
              valid = @bag.pockets[newpocket].length > 0
            end
            if valid
              pbPlayDecisionSE unless openPocketImmediately
              openPocketImmediately = false
              selection = pbChooseItemEx
              if selection
                return selection
              elsif @filterlist && @numfilledpockets == 1
                return nil
              end
              pbRefresh
            else
              pbPlayBuzzerSE
            end
          end

          # Update bag selection
          if itemwindow.pocket != newpocket
            itemwindow.pocket = newpocket
            @bag.lastpocket   = itemwindow.pocket
            pbPlayCursorSE
            pbRefresh
          end
        end
      end

      def pbChooseItemEx
        itemwindow = @sprites["itemlist"]
        thispocket = @bag.pockets[itemwindow.pocket]
        swapinitialpos = -1

        pbActivateWindow(@sprites,"itemlist") {
          pbRefresh
          loop do
            oldindex = itemwindow.index
            Graphics.update
            Input.update
            pbUpdate
            if itemwindow.sorting && itemwindow.index>=thispocket.length
              itemwindow.index = (oldindex==thispocket.length-1) ? 0 : thispocket.length-1
            end
            if itemwindow.index!=oldindex
              # Move the item being switched
              if itemwindow.sorting
                thispocket.insert(itemwindow.index,thispocket.delete_at(oldindex))
              end
              # Update selected item for current pocket
              @bag.setChoice(itemwindow.pocket,itemwindow.index)
              pbRefresh
            end
            if itemwindow.sorting
              if Input.trigger?(Input::ACTION) ||
                 Input.trigger?(Input::USE)
                itemwindow.sorting = false
                pbPlayDecisionSE
                pbRefresh
              elsif Input.trigger?(Input::BACK)
                thispocket.insert(swapinitialpos,thispocket.delete_at(itemwindow.index))
                itemwindow.index = swapinitialpos
                itemwindow.sorting = false
                pbPlayCancelSE
                pbRefresh
              end
            elsif Input.trigger?(Input::ACTION)   # Start switching the selected item
              if !@choosing
                if thispocket.length>1 && itemwindow.index < thispocket.length &&
                    $Options.bag_sorting == 0
                  itemwindow.sorting = true
                  swapinitialpos = itemwindow.index
                  pbPlayDecisionSE
                  pbRefresh
                else
                  pbPlayBuzzerSE
                end
              end
            elsif Input.trigger?(Input::BACK)   # Cancel the item screen
              pbPlayCloseMenuSE
              return nil
            elsif Input.trigger?(Input::USE)   # Choose selected item
              (itemwindow.item) ? pbPlayDecisionSE : pbPlayCloseMenuSE
              return itemwindow.item
            end
          end
        }
      end

      def supportsFusion?; return true; end
  end