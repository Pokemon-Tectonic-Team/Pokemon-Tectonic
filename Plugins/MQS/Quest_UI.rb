SHOW_FAILED_QUESTS = true

#===============================================================================
# Class that creates the scrolling list of quest names
#===============================================================================
class Window_Quest < Window_DrawableCommand

  def initialize(x,y,width,height,viewport)
    @quests = []
    super(x,y,width,height,viewport)
    self.windowskin = nil
    @selarrow = AnimatedBitmap.new("Graphics/Pictures/selarrow")
    RPG::Cache.retain("Graphics/Pictures/selarrow")
  end
  
  def quests=(value)
    @quests = value
    refresh
  end
  
  def itemCount
    return @quests.length
  end
  
  def drawItem(index,_count,rect)
    return if index>=self.top_row+self.page_item_max
    rect = Rect.new(rect.x+16,rect.y,rect.width-16,rect.height)
    name = $quest_data.getName(@quests[index].id)
    name = "<u>" + "#{name}" + "</u>" if @quests[index].story
    base = self.baseColor
    shadow = self.shadowColor
    # This doesn't work and I don't know why
    # if @quests[index].colorID
    #   questNameColors = getTextColorsFromIDNumber(@quests[index].colorID)
    #   base = Rgb16ToColor(questNameColors[0])
    #   shadow = Rgb16ToColor(questNameColors[1])
    # end    
    drawFormattedTextEx(self.contents,rect.x,rect.y+4, 436,name,base,shadow)
    pbDrawImagePositions(self.contents,[[sprintf("Graphics/Pictures/QuestUI/new"),rect.width-16,rect.y+4]]) if @quests[index].new
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    if itemCount >0
      for i in 0...@item_max
        next if i<self.top_item || i>self.top_item+self.page_item_max
        drawItem(i,@item_max,itemRect(i))
      end
      drawCursor(self.index,itemRect(self.index))
    else
      drawFormattedTextEx(self.contents,Graphics.width/2-64,36,436,_INTL("None"),self.baseColor,self.shadowColor)
    end
  end
  
  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
# Class that controls the UI
#===============================================================================
class QuestList_Scene
  
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @base = MessageConfig::pbDefaultTextMainColor
    @shadow = MessageConfig::pbDefaultTextShadowColor
    addBackgroundPlane(@sprites,"bg","QuestUI/bg_1",@viewport)
    @sprites["base"] = IconSprite.new(0,0,@viewport)
    setMainScreenBG
    @sprites["page_icon1"] = IconSprite.new(0,4,@viewport)
    if SHOW_FAILED_QUESTS
      @sprites["page_icon1"].setBitmap("Graphics/Pictures/QuestUI/page_icon1a")
    else
      @sprites["page_icon1"].setBitmap("Graphics/Pictures/QuestUI/page_icon1b")
    end
    @sprites["page_icon1"].x = Graphics.width - @sprites["page_icon1"].bitmap.width - 10
    @sprites["page_icon2"] = IconSprite.new(0,4,@viewport)
    @sprites["page_icon2"].setBitmap("Graphics/Pictures/QuestUI/page_icon2")
    @sprites["page_icon2"].x = Graphics.width - @sprites["page_icon2"].bitmap.width - 10
    @sprites["page_icon2"].opacity = 0
    @sprites["pageIcon"] = IconSprite.new(@sprites["page_icon1"].x,4,@viewport)
    @sprites["pageIcon"].setBitmap("Graphics/Pictures/QuestUI/pageIcon")
    @quests = [
      $PokemonGlobal.quests.active_quests,
      $PokemonGlobal.quests.completed_quests
    ]
    @quests_text = [_INTL("Active Quests"), _INTL("Completed Quests")]
    if SHOW_FAILED_QUESTS
      @quests.push($PokemonGlobal.quests.failed_quests)
      @quests_text.push(_INTL("Failed Quests"))
    end
    @quest_list_type = 0
    @sprites["itemlist"] = Window_Quest.new(22,26,Graphics.width-22,Graphics.height-20,@viewport)
    @sprites["itemlist"].index = 0
    @sprites["itemlist"].baseColor = @base
    @sprites["itemlist"].shadowColor = @shadow
    @sprites["itemlist"].quests = @quests[@quest_list_type]
    @sprites["overlay1"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay1"].bitmap)
    @sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay2"].opacity = 0
    pbSetSystemFont(@sprites["overlay2"].bitmap)
    @sprites["overlay3"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay3"].opacity = 0
    pbSetSystemFont(@sprites["overlay3"].bitmap)
    @sprites["overlay_control"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay_control"].bitmap)
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [@quests_text[@quest_list_type],6,-2,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    @questSelectionIndex = 0
    loop do
      @questSelectionIndex = @sprites["itemlist"].index
      @sprites["itemlist"].active = true
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @quests[@quest_list_type].length==0
          pbPlayBuzzerSE
        else
          pbPlayDecisionSE
          pbQuestDetailsScreen
        end
      elsif Input.trigger?(Input::RIGHT)
        pbPlayCursorSE
        @quest_list_type +=1
        @quest_list_type = 0 if @quest_list_type > @quests.length-1
        swapQuestType
      elsif Input.trigger?(Input::LEFT)
        pbPlayCursorSE
        @quest_list_type -=1
        @quest_list_type = @quests.length-1 if @quest_list_type < 0
        swapQuestType
      end
    end
  end

  def setMainScreenBG
    bgFileName = "Graphics/Pictures/QuestUI/bg_2"
    bgFileName += "_dark" if darkMode?
    @sprites["base"].setBitmap(bgFileName)
  end

  def setQuestScreenBG
    bgFileName = "Graphics/Pictures/QuestUI/bg_3"
    bgFileName += "_dark" if darkMode?
    @sprites["base"].setBitmap(bgFileName)
  end
  
  def swapQuestType
    @sprites["itemlist"].index = 0 # Resets cursor position
    @sprites["itemlist"].quests = @quests[@quest_list_type]
    @sprites["pageIcon"].x = @sprites["page_icon1"].x + 32 * @quest_list_type
    pbRefreshMainScreen
  end

  def pbRefreshMainScreen
    @sprites["overlay1"].bitmap.clear
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [_INTL(@quests_text[@quest_list_type]),6,-2,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    @sprites["itemlist"].refresh
  end

  def swapToMainScreen
    @sprites["itemlist"].contents_opacity = 255
    @sprites["overlay1"].opacity = 255
    @sprites["overlay_control"].opacity = 255
    @sprites["page_icon1"].opacity = 255
    @sprites["pageIcon"].opacity = 255

    @sprites["overlay2"].opacity = 0
    @sprites["overlay3"].opacity = 0
    @sprites["page_icon2"].opacity = 0
    setMainScreenBG
    pbRefreshMainScreen
  end

  def swapToQuestDetailsScreen
    @sprites["itemlist"].contents_opacity = 0
    @sprites["overlay1"].opacity = 0
    @sprites["overlay_control"].opacity = 0
    @sprites["page_icon1"].opacity = 0
    @sprites["pageIcon"].opacity = 0

    @sprites["overlay2"].opacity = 255
    @sprites["overlay3"].opacity = 255
    @sprites["page_icon2"].opacity = 255
    @sprites["page_icon2"].mirror = false
    setQuestScreenBG
  end
  
  def pbQuestDetailsScreen
    oldsprites = pbFadeOutAndHide(@sprites)
    quest = @quests[@quest_list_type][@questSelectionIndex]
    quest.new = false
    drawQuestDesc(quest)
    swapToQuestDetailsScreen
    pbFadeInAndShow(@sprites, oldsprites)

    refreshNeeded = false
    page = 0
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::RIGHT)
        if page == 0
          pbPlayCursorSE
          page += 1
          @sprites["page_icon2"].mirror = true
          drawOtherInfo(quest)
        else
          pbPlayBuzzerSE
        end
      elsif Input.trigger?(Input::LEFT)
        if page == 1
          pbPlayCursorSE
          page -= 1
          @sprites["page_icon2"].mirror = false
          drawQuestDesc(quest)
        else
          pbPlayBuzzerSE
        end
      elsif Input.trigger?(Input::UP) || Input.repeat?(Input::UP)
        if @questSelectionIndex > 0
          @questSelectionIndex -= 1
          refreshNeeded = true
        else
          pbPlayBuzzerSE
        end
      elsif Input.trigger?(Input::DOWN) || Input.repeat?(Input::DOWN)
        if @questSelectionIndex < @quests[@quest_list_type].length - 1
          @questSelectionIndex += 1
          refreshNeeded = true
        else
          pbPlayBuzzerSE
        end
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end

      if refreshNeeded
        quest = @quests[@quest_list_type][@questSelectionIndex]
        quest.new = false
        if page == 0
          drawQuestDesc(quest)
        elsif page == 1
          drawOtherInfo(quest)
        end
        refreshNeeded = false
      end
    end
    pbFadeOutAndHide(@sprites)
    swapToMainScreen
    pbFadeInAndShow(@sprites, oldsprites)
  end
  
  def drawQuestDesc(quest)
    @sprites["overlay2"].bitmap.clear
    @sprites["overlay3"].bitmap.clear
    # Quest name
    questName = $quest_data.getName(quest.id)
    pbDrawTextPositions(@sprites["overlay2"].bitmap,[
      ["#{questName}",Graphics.width/2 - 12,-2,2,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    # Quest description
    questDesc = _INTL("<u>Overview</u>: {1}",$quest_data.getQuestDescription(quest.id,quest.stage))
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,48,
      436,questDesc,@base,@shadow)
    # Stage description
    questStageDesc = $quest_data.getStageDescription(quest.id,quest.stage)
    # Stage location
    questStageLocation = $quest_data.getStageLocation(quest.id,quest.stage)
    # If 'nil' or missing, set to '???'
    if questStageLocation == "nil" || questStageLocation == ""
      questStageLocation = "???"
    end
    detailsStartingY = Graphics.height-70
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,detailsStartingY,
      436,_INTL("<u>Task</u>: {1}",questStageDesc),@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,detailsStartingY + 32,
      436,_INTL("<u>Location</u>: {1}",questStageLocation),@base,@shadow)
  end

  def drawOtherInfo(quest)
    @sprites["overlay3"].bitmap.clear
    # Guest giver
    questGiver = $quest_data.getQuestGiver(quest.id)
    # If 'nil' or missing, set to '???'
    if questGiver == "nil" || questGiver == ""
      questGiver = _INTL("???")
    end
    # Map quest was originally started
    originalMap = quest.location
    # Vary text according to map name
    loc = originalMap.include?("Route") ? "on" : "in"
    # Format time
    time = quest.time.strftime("%B %d %Y %H:%M")
    if getActiveQuests.include?(quest.id)
      time_text = _INTL("start")
    elsif getCompletedQuests.include?(quest.id)
      time_text = _INTL("completion")
    else
      time_text = _INTL("failure")
    end
    # Quest reward
    questReward = $quest_data.getQuestReward(quest.id)
    if questReward == "nil" || questReward == ""
      questReward = _INTL("???")
    end
    yStartingPos = 48
    yGap = 72
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,yStartingPos,
      436,_INTL("<u>Quest received from</u>:"),@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,yStartingPos+yGap*1,
      436,_INTL("<u>Quest discovered {1}</u>:",loc),@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,yStartingPos+yGap*2,
      436,_INTL("<u>Quest {1} time</u>:",time_text),@base,@shadow)
    detailsStartingY = Graphics.height-70
    drawFormattedTextEx(@sprites["overlay3"].bitmap,38,detailsStartingY,
      436,_INTL("<u>Reward</u>: {1}",questReward),@base,@shadow)
    yStartingPos += 24
    textpos = [
        ["#{questGiver}",38,yStartingPos,0,@base,@shadow],
        ["#{originalMap}",38,yStartingPos+yGap*1,0,@base,@shadow],
        ["#{time}",38,yStartingPos+yGap*2,0,@base,@shadow]
      ]
    pbDrawTextPositions(@sprites["overlay3"].bitmap,textpos)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Class to call UI
#===============================================================================
class QuestList_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbScene
    @scene.pbEndScene
  end
end

# Utility method for calling UI
def pbViewQuests
  scene = QuestList_Scene.new
  screen = QuestList_Screen.new(scene)
  screen.pbStartScreen
end
