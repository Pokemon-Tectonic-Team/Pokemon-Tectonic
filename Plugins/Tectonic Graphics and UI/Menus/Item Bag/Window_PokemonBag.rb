#===============================================================================
#
#===============================================================================
class Window_PokemonBag < Window_DrawableCommand
    attr_reader :pocket
    attr_accessor :sorting
  
    def initialize(bag,filterlist,pocket,x,y,width,height)
      @bag        = bag
      @filterlist = filterlist
      @pocket     = pocket
      @sorting = false
      @adapter = PokemonMartAdapter.new
      super(x,y,width,height)
      @selarrow  = AnimatedBitmap.new("Graphics/Pictures/Bag/cursor")
      @swaparrow = AnimatedBitmap.new("Graphics/Pictures/Bag/cursor_swap")
      self.windowskin = nil
    end
  
    def dispose
      @swaparrow.dispose
      super
    end
  
    def pocket=(value)
      @pocket = value
      @item_max = (@filterlist) ? @filterlist[@pocket].length+1 : @bag.pockets[@pocket].length+1
      self.index = @bag.getChoice(@pocket)
    end
  
    def page_row_max; return PokemonBag_Scene::ITEMSVISIBLE; end
    def page_item_max; return PokemonBag_Scene::ITEMSVISIBLE; end
  
    def item
      return nil if @filterlist && !@filterlist[@pocket][self.index]
      thispocket = @bag.pockets[@pocket]
      item = (@filterlist) ? thispocket[@filterlist[@pocket][self.index]] : thispocket[self.index]
      return (item) ? item[0] : nil
    end
  
    def itemCount
      return (@filterlist) ? @filterlist[@pocket].length+1 : @bag.pockets[@pocket].length+1
    end
  
    def itemRect(item)
      if item<0 || item>=@item_max || item<self.top_item-1 ||
         item>self.top_item+self.page_item_max
        return Rect.new(0,0,0,0)
      else
        cursor_width = (self.width-self.borderX-(@column_max-1)*@column_spacing) / @column_max
        x = item % @column_max * (cursor_width + @column_spacing)
        y = item / @column_max * @row_height - @virtualOy
        return Rect.new(x, y, cursor_width, @row_height)
      end
    end
  
    def drawCursor(index,rect)
      if self.index==index
        bmp = (@sorting) ? @swaparrow.bitmap : @selarrow.bitmap
        pbCopyBitmap(self.contents,bmp,rect.x,rect.y+2)
      end
    end
  
    def drawItem(index,_count,rect)
          textpos = []
          rect = Rect.new(rect.x+16,rect.y+16,rect.width-16,rect.height)
          thispocket = @bag.pockets[@pocket]
          if index==self.itemCount-1
            textpos.push([_INTL("CLOSE POCKET"),rect.x,rect.y-2,false,self.baseColor,self.shadowColor])
          else
            item = (@filterlist) ? thispocket[@filterlist[@pocket][index]][0] : thispocket[index][0]
            baseColor   = self.baseColor
            shadowColor = self.shadowColor
            if @sorting && index==self.index
              baseColor   = Color.new(224,0,0)
              shadowColor = Color.new(248,144,144)
            end
            textpos.push(
               [@adapter.getDisplayName(item),rect.x,rect.y-2,false,baseColor,shadowColor]
            )
            itemData = GameData::Item.get(item)
            if itemData.is_important? && !itemData.is_consumable_key_item?
              if @bag.pbIsRegistered?(item)
                pbDrawImagePositions(self.contents,[
                   [addLanguageSuffix("Graphics/Pictures/Bag/icon_register"),rect.x+rect.width-72,rect.y+8,0,0,-1,24]
                ])
              elsif pbCanRegisterItem?(item)
                pbDrawImagePositions(self.contents,[
                   [addLanguageSuffix("Graphics/Pictures/Bag/icon_register"),rect.x+rect.width-72,rect.y+8,0,24,-1,24]
                ])
              end
            else
              qty = (@filterlist) ? thispocket[@filterlist[@pocket][index]][1] : thispocket[index][1]
              qtytext = _ISPRINTF("x{1: 3d}",qty)
              xQty    = rect.x+rect.width-self.contents.text_size(qtytext).width-16
              textpos.push([qtytext,xQty,rect.y-2,false,baseColor,shadowColor])
            end
          end
          pbDrawTextPositions(self.contents,textpos)
        end
  
    def refresh
      @item_max = itemCount()
      self.update_cursor_rect
      dwidth  = self.width-self.borderX
      dheight = self.height-self.borderY
      self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
      self.contents.clear
      for i in 0...@item_max
        next if i<self.top_item-1 || i>self.top_item+self.page_item_max
        drawItem(i,@item_max,itemRect(i))
      end
      drawCursor(self.index,itemRect(self.index)) if @active
    end
  
    def update
      super
      @uparrow.visible   = false
      @downarrow.visible = false
    end
  end