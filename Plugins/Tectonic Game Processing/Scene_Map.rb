#===============================================================================
# ** Modified Scene_Map class for Pokémon.
#-------------------------------------------------------------------------------
#
#===============================================================================
class Scene_Map
    attr_reader :spritesetGlobal
    attr_reader :map_renderer

    def spriteset
        for i in @spritesets.values
            return i if i.map == $game_map
        end
        return @spritesets.values[0]
    end

    def createSpritesets
        @map_renderer = TilemapRenderer.new(Spriteset_Map.viewport) if !@map_renderer || @map_renderer.disposed?
        @spritesetGlobal ||= Spriteset_Global.new
        @spritesets = {}
        for map in $MapFactory.maps
            @spritesets[map.map_id] = Spriteset_Map.new(map)
        end
        $MapFactory.setSceneStarted(self)
        updateSpritesets(true)
    end

    def createSingleSpriteset(map)
        temp = $scene.spriteset.getAnimations
        @spritesets[map] = Spriteset_Map.new($MapFactory.maps[map])
        $scene.spriteset.restoreAnimations(temp)
        $MapFactory.setSceneStarted(self)
        updateSpritesets
    end

    def disposeSpritesets
        return unless @spritesets
        for i in @spritesets.keys
            next unless @spritesets[i]
            @spritesets[i].dispose
            @spritesets[i] = nil
        end
        @spritesets.clear
        @spritesets = {}
        @spritesetGlobal.dispose if @spritesetGlobal
        @spritesetGlobal = nil
    end

    def recreateSpritesets
		disposeSpritesets
		RPG::Cache.clear
		createSpritesets
	end

    def force_update_characters
        for map in $MapFactory.maps
            @spritesets[map.map_id].force_update_characters
        end
    end

    def autofade(mapid)
        playingBGM = $game_system.playing_bgm
        playingBGS = $game_system.playing_bgs
        return if !playingBGM && !playingBGS
        map = load_data(format("Data/Map%03d.rxdata", mapid))
        if playingBGM && map.autoplay_bgm
            if begin
                PBDayNight.isNight?
            rescue StandardError
                false
            end
                pbBGMFade(0.8) if playingBGM.name != map.bgm.name && playingBGM.name != map.bgm.name + "_n"
            elsif playingBGM.name != map.bgm.name
                pbBGMFade(0.8)
            end
        end
        if playingBGS && playingBGS.name != map.bgs.name
            pbBGSFade(0.8)
        end
        Graphics.frame_reset
    end

    def transfer_player(cancelVehicles = true)
        $game_temp.transfer_loaded_in = false
        $game_temp.player_transferring = false
        pbCancelVehicles($game_temp.player_new_map_id) if cancelVehicles
        autofade($game_temp.player_new_map_id)
        pbBridgeOff
        @spritesetGlobal.playersprite.clearShadows if @spritesetGlobal
        if $game_map.map_id != $game_temp.player_new_map_id
            $game_switches[35] = false # Enable Auto Clouds, if it was disabled
            $MapFactory.setup($game_temp.player_new_map_id) 
        end
        $game_player.moveto($game_temp.player_new_x, $game_temp.player_new_y)
        case $game_temp.player_new_direction
        when 2 then $game_player.turn_down
        when 4 then $game_player.turn_left
        when 6 then $game_player.turn_right
        when 8 then $game_player.turn_up
        end
        $game_player.straighten
        $game_map.update

        # The player surfs if they were transferred to a surfable tile
        terrainID = $game_map.terrain_tag($game_player.x, $game_player.y).id
        terrain = GameData::TerrainTag.try_get(terrainID)
        if terrain && terrain.can_surf
            $PokemonGlobal.surfing = true
            pbUpdateVehicle
        end

        processTimeTravel if defined?(processTimeTravel)
        PBDayNight.sheduleToneRefresh

        recreateSpritesets

        if $game_temp.transition_processing
            $game_temp.transition_processing = false
            Graphics.transition(20)
        end
        $game_map.autoplay
        Graphics.frame_reset
        Input.update

        # Follower events
        events = $PokemonGlobal.dependentEvents
        $PokemonTemp.dependentEvents.updateDependentEvents
        leader = $game_player
        for i in 0...events.length
            event = $PokemonTemp.dependentEvents.realEvents[i]
            $PokemonTemp.dependentEvents.refresh_sprite(false)
            $PokemonTemp.dependentEvents.pbFollowEventAcrossMaps(leader, event, false, i == 0)
        end
    end

    def call_menu
        $game_temp.menu_calling = false
        $game_temp.in_menu = true
        $game_player.straighten
        $game_map.update
        sscene = TilingCardsPauseMenu_Scene.new
        sscreen = TilingCardsPauseMenu.new(sscene)
        sscreen.pbStartPokemonMenu
        $game_temp.in_menu = false
    end

    def call_debug
        $game_temp.debug_calling = false
        pbPlayDecisionSE
        $game_player.straighten
        pbFadeOutIn { pbDebugMenu }
    end

    def call_save
      $game_temp.save_calling = false
      pbSEPlay("GUI save choice")
      if properlySave()
        pbMessage(_INTL("\\se[]{1} saved the game.\\me[GUI save game]",$Trainer.name))
      else
        pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
      end
    end

    def call_bike
      $PokemonTemp.bicycleCalling = false
      return unless $PokemonBag.pbHasItem?(:BICYCLE)
      pbUseKeyItemInField(:BICYCLE)
    end

    def miniupdate
        $PokemonGlobal.addNewFrameCount if UnrealTime::ENABLED && UnrealTime::TALK_PASS && UnrealTime::TIME_STOPS
        $PokemonTemp.miniupdate = true
        loop do
            updateMaps
            $game_player.update
            $game_system.update
            $game_screen.update
            break unless $game_temp.player_transferring
            transfer_player
            break if $game_temp.transition_processing
        end
        updateSpritesets
        $PokemonTemp.miniupdate = false
    end

    def updateMaps
        for map in $MapFactory.maps
            map.update
        end
        $MapFactory.updateMaps(self)
    end

    def updateSpritesets(refresh = false)
      @spritesets ||= {}
      $MapFactory.maps.each do |map|
          @spritesets[map.map_id] = Spriteset_Map.new(map) unless @spritesets[map.map_id]
      end
      keys = @spritesets.keys.clone
      for i in keys
          if !$MapFactory.hasMap?(i)
              @spritesets[i].dispose if @spritesets[i]
              @spritesets[i] = nil
              @spritesets.delete(i)
          else
              @spritesets[i].update
          end
      end
      @spritesetGlobal.update
      for map in $MapFactory.maps
          @spritesets[map.map_id] = Spriteset_Map.new(map) unless @spritesets[map.map_id]
      end
      @map_renderer.refresh if refresh
      @map_renderer.update
      Events.onMapUpdate.trigger(self)
    end

    def update
        $PokemonGlobal.addNewFrameCount if UnrealTime::ENABLED && UnrealTime::TIME_STOPS
        loop do
            updateMaps
            pbMapInterpreter.update
            $game_player.update
            $game_system.update
            $game_screen.update
            break unless $game_temp.player_transferring
            transfer_player
            break if $game_temp.transition_processing
        end
        updateSpritesets
        if $game_temp.to_title
            $scene = pbCallTitle
            return
        end
        if $game_temp.transition_processing
            $game_temp.transition_processing = false
            if $game_temp.transition_name == ""
                Graphics.transition(20)
            else
                Graphics.transition(40, "Graphics/Transitions/" + $game_temp.transition_name)
            end
        end
        return if $game_temp.message_window_showing
        unless pbMapInterpreterRunning?
            unless $game_temp.transfer_loaded_in
                $game_temp.transfer_loaded_in = true
                Events.onMapLoadIn.trigger
            end

            if Input.trigger?(Input::USE)
                $PokemonTemp.hiddenMoveEventCalling = true
            elsif Input.trigger?(Input::BACK)
                unless $game_system.menu_disabled || $game_player.moving?
                    $game_temp.menu_calling = true
                    $game_temp.menu_beep = true
                end
            elsif Input.trigger?(Input::SPECIAL)
                unless $game_system.menu_disabled || $game_player.moving?
                    $PokemonTemp.keyItemCalling = true
                end
            elsif Input.trigger?(Input::AUX2)
                unless $game_player.lock?
                    $PokemonTemp.bicycleCalling = true
                end
            elsif Input.trigger?(Input::AUX1)
                unless $game_system.menu_disabled or $game_player.moving?
                    if savingAllowed?
                        $game_temp.save_calling = true
                        $game_temp.menu_beep = true
                    else
                        showSaveBlockMessage
                    end
                end
            elsif Input.press?(Input::F9)
                $game_temp.debug_calling = true if $DEBUG
            end
        end
        unless $game_player.moving?
            if $game_temp.menu_calling
                call_menu
            elsif $game_temp.debug_calling
                call_debug
            elsif $game_temp.save_calling
                call_save
            elsif $PokemonTemp.keyItemCalling
                $PokemonTemp.keyItemCalling = false
                $game_player.straighten
                pbUseKeyItem
            elsif $PokemonTemp.hiddenMoveEventCalling
                $PokemonTemp.hiddenMoveEventCalling = false
                $game_player.straighten
                Events.onAction.trigger(self)
            end
        end
        call_bike if $PokemonTemp.bicycleCalling
        # Follower events
        for i in 0...$PokemonGlobal.dependentEvents.length
            event = $PokemonTemp.dependentEvents.realEvents[i]
            return if event.move_route_forcing
            event.move_speed = $game_player.move_speed
        end
        if $PokemonGlobal.follower_toggled
            # Stop stepping animation if on Ice
            if $game_player.pbTerrainTag.ice
                $PokemonTemp.dependentEvents.stop_stepping
            else
                $PokemonTemp.dependentEvents.start_stepping
            end
        end
    end

    def updatemini
        oldmws = $game_temp.message_window_showing
        $game_temp.message_window_showing = true
        loop do
            $game_map.update
            $game_player.update
            $game_system.update
            if $game_screen
                $game_screen.update
            else
                $game_map.screen.update
            end
            break unless $game_temp.player_transferring
            transfer_player
            break if $game_temp.transition_processing
        end
        $game_temp.message_window_showing = oldmws
        @spriteset.update if @spriteset
        @message_window.update if @message_window
    end

    def main
        createSpritesets
        Graphics.transition(20)
        loop do
            Graphics.update
            Input.update
            update
            break if $scene != self
        end
        Graphics.freeze
        disposeSpritesets
        if $game_temp.to_title
            Graphics.transition(20)
            Graphics.freeze
        end
    end
end
