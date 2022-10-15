class TribalBonusScene
	PAGE_TITLES = ["TRIBES", "TRIBE INFO"]

    def drawPage()
        # Draw page title
        overlay = @sprites["overlay"].bitmap
        overlay.clear


        base = Color.new(219, 240, 240)
        shadow   = Color.new(88, 88, 80)
        pageTitle = PAGE_TITLES[@page-1]
        drawFormattedTextEx(overlay, 50, 2, Graphics.width, "<outln2>#{pageTitle}</outln2>", base, shadow, 18)
        xPos = 240
        drawFormattedTextEx(overlay, xPos, 2, Graphics.width, "<outln2>[#{@page}/#{PAGE_TITLES.length()}]</outln2>", base, shadow, 18)

        # Draw page-specific information
        case @page
        when 1; displayTribalBonuses()
        when 2; displayTribalInfo()
        end
    end

    def displayTribalBonuses()
        overlay = @sprites["overlay"].bitmap
        base = Color.new(88,88,88)
        shadow = Color.new(168,184,184)
        xLeft = 36
        coordinateY = 34
    
        # Make sure arrows are hidden
        @sprites["scroll_arrow_up"].visible = false
        @sprites["scroll_arrow_down"].visible = false

        drewAny = false
        $Tribal_Bonuses.tribeCounts.each {|tribe, count|
            if count > 0
                tribeName = $Tribal_Bonuses.getTribeName(tribe)
                coordinateY += 30
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("{1}: {2}", tribeName, count), base, shadow)
                drewAny = true
            end
        }
        if !drewAny
            drawTextEx(overlay, xLeft, coordinateY + 30, 450, 1, _INTL("None"), base, shadow)
        end
    end

    def displayTribalInfo()
        @sprites["scroll_arrow_up"].visible = @offset > 0
        @sprites["scroll_arrow_down"].visible = @offset < @displayText.length - @linesToShow
        
        overlay = @sprites["overlay"].bitmap
        base = Color.new(88,88,88)
        shadow = Color.new(168,184,184)
        xLeft = 36
        coordinateY = 64

        @displayText[@offset..@offset+@linesToShow].each {|line|
            drawTextEx(overlay, xLeft, coordinateY += 30, 450, 1, line, base, shadow)
        }
    end

    def break_string(str, n)
        arr = []
        pos = 0     
        loop do
            break arr if pos == str.size
            if str[pos] == ' '
                pos += 1
            end
            m = str.match(/.{1,#{n}}(?=[ ]|\z)|.{,#{n-1}}[ ]/, pos)
            return nil if m.nil?
            arr << m[0]
            pos += m[0].size
        end
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbStartScene
        $Tribal_Bonuses.updateTribeCount()
        @page = 1

        # Set up the two viewports to hold UI elements
        @viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport1.z = 99999
        @sprites = {}

        # Set up all the sprites
        @sprites["background"] = IconSprite.new(0,0,@viewport1)
        @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/Rework/bg_evolution"))

        @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport1)
        pbSetSystemFont(@sprites["overlay"].bitmap)

        # Used for Tribal Info page
        @displayText = []
        @offset = 0
        @linesToShow = 7
        @sprites["scroll_arrow_up"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport1)
        @sprites["scroll_arrow_up"].x = (Graphics.width - 28) / 2
        @sprites["scroll_arrow_up"].y = 64
        @sprites["scroll_arrow_up"].visible = false
        @sprites["scroll_arrow_up"].play
        @sprites["scroll_arrow_down"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport1)
        @sprites["scroll_arrow_down"].x = (Graphics.width - 28) / 2
        @sprites["scroll_arrow_down"].y = (Graphics.height - 64)
        @sprites["scroll_arrow_down"].visible = false
        @sprites["scroll_arrow_down"].play

        TRIBAL_DEFINITIONS.each {|tribe, tribeDefinition|
            tribeName = tribeDefinition[0]
            tribalThresholdEntries = tribeDefinition[1]

            @displayText << tribeName + ":"

            tribalThresholdEntries.each do |tribalThresholdEntry|
                threshold = tribalThresholdEntry[0]
                statBonusesHash = tribalThresholdEntry[1]
                statBonusesDescription = tribalThresholdEntry[2]
                bonusDescription = "#{threshold} battlers in this category will get #{statBonusesDescription}"

                break_string(bonusDescription, 40).each {|line|
                    @displayText << line
                }
            end
            @displayText << "" # Blank line
        }

        pbFadeInAndShow(@sprites) { pbUpdate }
        drawPage()
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @viewport1.dispose
    end

    def pbScene
        returnIndex = -1

        Graphics.update
        Input.update
        pbUpdate
        dorefresh = false
        
        if Input.repeat?(Input::LEFT)
            # Go to previous page if not already on the first page
            if @page > 1
                @page -= 1
                dorefresh = true
            end
            returnIndex = @page
        elsif Input.repeat?(Input::RIGHT)
            # Go to next page if not already on the last page
            if @page < PAGE_TITLES.length()
                @page += 1
                dorefresh = true
            end
            returnIndex = @page
        elsif Input.repeat?(Input::UP)
            # Scroll up on the Tribal Info page if not already at the top
            if @offset > 0
                @offset = @offset - 1
                dorefresh = true
            end
            returnIndex = @page + @offset
        elsif Input.repeat?(Input::DOWN)
            # Scroll down on the Tribal Info page if not already at the bottom
            if @offset < @displayText.length - @linesToShow
                @offset = @offset + 1
                dorefresh = true
            end
            returnIndex = @page + @offset
        elsif Input.repeat?(Input::BACK)
            returnIndex = -1
        else
            returnIndex = @page
        end
        
        # If the page has changed, redraw the page
        if dorefresh
            pbPlayCursorSE
            drawPage()
        end
        
        return returnIndex
    end
end

########################################################################################################################
########################################################################################################################
########################################################################################################################
class TribalBonusScreen
    def initialize(scene)
      @scene = scene
    end
  
    def pbStartScreen
        @scene.pbStartScene()
        loop do
            cmd = @scene.pbScene
            break if cmd<0   # Cancel/Exit
        end
        @scene.pbEndScene
    end
  end
