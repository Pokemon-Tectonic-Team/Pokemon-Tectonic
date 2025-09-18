#===============================================================================
# Item icon
#===============================================================================
class ItemIconSprite < SpriteWrapper
    attr_reader :item

    ANIM_ICON_SIZE   = 48
    FRAMES_PER_CYCLE = Graphics.frame_rate

    def initialize(x, y, item, viewport = nil)
        super(viewport)
        @animbitmap = nil
        @animframe = 0
        @numframes = 1
        @frame = 0
        self.x = x
        self.y = y
        @blankzero = false
        @forceitemchange = true
        self.item = item
        @forceitemchange = false
    end

    def dispose
        @animbitmap.dispose if @animbitmap
        super
    end

    def width
        return 0 if !bitmap || bitmap.disposed?
        return (@numframes == 1) ? bitmap.width : ANIM_ICON_SIZE
    end

    def height
        return (bitmap && !bitmap.disposed?) ? bitmap.height : 0
    end

    def blankzero=(val)
        @blankzero = val
        @forceitemchange = true
        self.item = @item
        @forceitemchange = false
    end

    def setOffset(offset = PictureOrigin::Center)
        @offset = offset
        changeOrigin
    end

    def changeOrigin
        @offset ||= PictureOrigin::Center
        case @offset
        when PictureOrigin::TopLeft, PictureOrigin::Top, PictureOrigin::TopRight
            self.oy = 0
        when PictureOrigin::Left, PictureOrigin::Center, PictureOrigin::Right
            self.oy = height / 2
        when PictureOrigin::BottomLeft, PictureOrigin::Bottom, PictureOrigin::BottomRight
            self.oy = height
        end
        case @offset
        when PictureOrigin::TopLeft, PictureOrigin::Left, PictureOrigin::BottomLeft
            self.ox = 0
        when PictureOrigin::Top, PictureOrigin::Center, PictureOrigin::Bottom
            self.ox = width / 2
        when PictureOrigin::TopRight, PictureOrigin::Right, PictureOrigin::BottomRight
            self.ox = width
        end
    end

    def item=(value)
        return if @item == value && !@forceitemchange && !ItemIconEvents::item_dynamic_icon?(item)
        @item = value
        @animbitmap.dispose if @animbitmap
        @animbitmap = nil
        if @item || !@blankzero
            @animbitmap = AnimatedBitmap.new(GameData::Item.icon_filename(@item))
            self.bitmap = @animbitmap.bitmap
            pbSetSystemFont(bitmap)
            ItemIconEvents.triggerModifyItemIconBitmap(@item, bitmap)
            establishNewBitmap
        else
            self.bitmap = nil
        end
        changeOrigin
    end

    # For Prismatic Plate / Memory Set
    def type=(value)
        return if @item.nil?
        return unless GameData::Item.get(@item).is_type_setting?

        # Dispose current graphic
        @animbitmap.dispose if @animbitmap
        @animbitmap = nil
        self.bitmap = nil

        # Find the proper pseudo bitmap
        pretendItem = nil
        typeData = GameData::Type.get(value)
        typeID = typeData.id_number

        if @item == :PRISMATICPLATE
            pretendItem = PLATES_BY_TYPE_ID[typeID]
        elsif @item == :MEMORYSET
            pretendItem = MEMORIES_BY_TYPE_ID[typeID]
        else
            pretendItem = (@item.to_s + typeData.real_name.upcase).to_sym
        end

        if pretendItem.nil?
            echoln("ERROR: Unable to find a proper pseudo item file for an item icon showing a #{@item}")
            return
        end
        @animbitmap = AnimatedBitmap.new(GameData::Item.icon_filename(pretendItem))
        self.bitmap = @animbitmap.bitmap
        establishNewBitmap
        changeOrigin
    end

    def establishNewBitmap
        if bitmap.height == ANIM_ICON_SIZE
            @numframes = [(bitmap.width / ANIM_ICON_SIZE).floor, 1].max
            self.src_rect = Rect.new(0, 0, ANIM_ICON_SIZE, ANIM_ICON_SIZE)
        else
            @numframes = 1
            self.src_rect = Rect.new(0, 0, bitmap.width, bitmap.height)
        end
        @animframe = 0
        @frame = 0
    end

    def update
        @updating = true
        super
        if @animbitmap
            @animbitmap.update
            self.bitmap = @animbitmap.bitmap
            if @numframes > 1
                frameskip = (FRAMES_PER_CYCLE / @numframes).floor
                @frame = (@frame + 1) % FRAMES_PER_CYCLE
                if @frame >= frameskip
                    @animframe = (@animframe + 1) % @numframes
                    src_rect.x = @animframe * ANIM_ICON_SIZE
                    @frame = 0
                end
            end
        end
        @updating = false
    end
end

MEMORIES_BY_TYPE_ID = {
  0  => :NORMALMEMORY,
  1  => :FIGHTINGMEMORY,
  2  => :FLYINGMEMORY,
  3  => :POISONMEMORY,
  4  => :GROUNDMEMORY,
  5  => :ROCKMEMORY,
  6  => :BUGMEMORY,
  7  => :GHOSTMEMORY,
  8  => :STEELMEMORY,
  10 => :FIREMEMORY,
  11 => :WATERMEMORY,
  12 => :GRASSMEMORY,
  13 => :ELECTRICMEMORY,
  14 => :PSYCHICMEMORY,
  15 => :ICEMEMORY,
  16 => :DRAGONMEMORY,
  17 => :DARKMEMORY,
  18 => :FAIRYMEMORY,
  }

PLATES_BY_TYPE_ID = {
  0  => :PRISMATICPLATE,
  1  => :FISTPLATE,
  2  => :SKYPLATE,
  3  => :TOXICPLATE,
  4  => :EARTHPLATE,
  5  => :STONEPLATE,
  6  => :INSECTPLATE,
  7  => :SPOOKYPLATE,
  8  => :IRONPLATE,
  10 => :FLAMEPLATE,
  11 => :SPLASHPLATE,
  12 => :MEADOWPLATE,
  13 => :ZAPPLATE,
  14 => :MINDPLATE,
  15 => :ICICLEPLATE,
  16 => :DRACOPLATE,
  17 => :DREADPLATE,
  18 => :PIXIEPLATE,
}
