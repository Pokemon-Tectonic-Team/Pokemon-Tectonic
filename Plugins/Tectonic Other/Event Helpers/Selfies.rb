SELFIE_ZOOM_FACTOR = 0.5

def takeSelfie
    caption = ""
    blackFadeOutIn {
      # move follower mon
      $PokemonTemp.dependentEvents.refresh_sprite(true)
      followerEvent = pbGetFollowerDependentEvent
      followerEvent.moveto($game_player.x - 1,$game_player.y)

      pbMapInterpreter.get_player.turn_down
      followerEvent.turn_down

      # Set the text
      caption = pbEnterText(_INTL("Enter caption."),0,50,"",0,nil,true)

      Graphics.resize_screen((Settings::SCREEN_WIDTH * SELFIE_ZOOM_FACTOR).floor, (Settings::SCREEN_HEIGHT * SELFIE_ZOOM_FACTOR).floor)
      pbSetResizeFactor($Options.screensize)
      $game_map.centerCameraOnPlayer(0,-0.5)
    }

    pbWait(10)

    if caption.length > 0
      base   = MessageConfig.pbDefaultTextMainColor
      shadow = MessageConfig.pbDefaultTextShadowColor
      viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      viewport.z = 99999
      selfieShaderBitmap = AnimatedBitmap.new(pbResolveBitmap("Graphics/Pictures/selfie_shader"))
      overlay = BitmapSprite.new(Graphics.width, Graphics.height, viewport)

      overlay.bitmap.blt(0,0,selfieShaderBitmap.bitmap,Rect.new(0,0,Graphics.width,Graphics.height))
      overlay.bitmap.font.size = 18
      overlay.z = 1
      
      # Draw the text
      pbDrawTextPositions(overlay.bitmap,[
        [caption,Graphics.width / 2, Graphics.height * 2/3, 2, base, shadow, false]
      ])
    end

    pbWait(30)

    # Take the screenshot
    timeLabel = Time.now.strftime("[%Y-%m-%d] %H_%M_%S.%L")
    pbScreenCapture(_INTL("Selfie_{1}_{2}",$game_map.name,timeLabel))

    pbWait(80)

    blackFadeOutIn {
      Graphics.resize_screen(Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)
      pbSetResizeFactor($Options.screensize)
      $game_map.centerCameraOnPlayer

      # Dispose of elements
      if caption.length > 0
        overlay.dispose
        viewport.dispose
      end
    }
end