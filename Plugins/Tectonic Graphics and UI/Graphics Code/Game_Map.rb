def tile_ID_from_coordinates(x, y)
    return x * PokemonTilesetScene::TILES_PER_AUTOTILE if y == 0   # Autotile
    return PokemonTilesetScene::TILESET_START_ID + (y - 1) * PokemonTilesetScene::TILES_PER_ROW + x
end

def coordinates_from_tild_ID(tileID)
    return [tileID / PokemonTilesetScene::TILES_PER_AUTOTILE, 0] if tileID < PokemonTilesetScene::TILESET_START_ID
    x = (tileID - PokemonTilesetScene::TILESET_START_ID) % PokemonTilesetScene::TILES_PER_ROW
    y = (tileID - PokemonTilesetScene::TILESET_START_ID) / PokemonTilesetScene::TILES_PER_ROW + 1
    return [x, y]
end

#==============================================================================
# ** Game_Map
#------------------------------------------------------------------------------
#  This class handles the map. It includes scrolling and passable determining
#  functions. Refer to "$game_map" for the instance of this class.
#==============================================================================
class Game_Map
    attr_accessor :map_id
    attr_accessor :tileset_name             # tileset file name
    attr_accessor :autotile_names           # autotile file name
    attr_reader   :passages                 # passage table
    attr_reader   :priorities               # priority table
    attr_reader   :terrain_tags             # terrain tag table
    attr_reader   :events                   # events
    attr_accessor :panorama_name            # panorama file name
    attr_accessor :panorama_hue             # panorama hue
    attr_accessor :fog_name                 # fog file name
    attr_accessor :fog_hue                  # fog hue
    attr_accessor :fog_opacity              # fog opacity level
    attr_accessor :fog_blend_type           # fog blending method
    attr_accessor :fog_zoom                 # fog zoom rate
    attr_accessor :fog_sx                   # fog sx
    attr_accessor :fog_sy                   # fog sy
    attr_reader   :fog_ox                   # fog x-coordinate starting point
    attr_reader   :fog_oy                   # fog y-coordinate starting point
    attr_reader   :fog_tone                 # fog color tone
    attr_accessor :battleback_name          # battleback file name
    attr_reader   :display_x                # display x-coordinate * 128
    attr_reader   :display_y                # display y-coordinate * 128
    attr_accessor :need_refresh             # refresh request flag

    TILE_WIDTH  = 32
    TILE_HEIGHT = 32
    X_SUBPIXELS = 4
    Y_SUBPIXELS = 4
    REAL_RES_X  = TILE_WIDTH * X_SUBPIXELS
    REAL_RES_Y  = TILE_HEIGHT * Y_SUBPIXELS

    def initialize
        @map_id = 0
        @display_x = 0
        @display_y = 0
    end

    def setup(map_id)
        @map_id = map_id
        @map = load_data(format("Data/Map%03d.rxdata", map_id))
        tileset = $data_tilesets[@map.tileset_id]
        updateTileset
        @fog_ox               = 0
        @fog_oy               = 0
        @fog_tone             = Tone.new(0, 0, 0, 0)
        @fog_tone_target      = Tone.new(0, 0, 0, 0)
        @fog_tone_duration    = 0
        @fog_opacity_duration = 0
        @fog_opacity_target   = 0
        self.display_x        = 0
        self.display_y        = 0
        @need_refresh         = false
        Events.onMapCreate.trigger(self, map_id, @map, tileset)
        @events = {}
        for i in @map.events.keys
            @events[i]          = Game_Event.new(@map_id, @map.events[i], self)
        end
        @common_events = {}
        for i in 1...$data_common_events.size
            @common_events[i]   = Game_CommonEvent.new(i)
        end
        @scroll_direction     = 2
        @scroll_rest          = 0
        @scroll_speed         = 4
    end

    def updateTileset
        tileset = $data_tilesets[@map.tileset_id]
        @tileset_name    = tileset.tileset_name
        @autotile_names  = tileset.autotile_names
        @panorama_name   = tileset.panorama_name
        @panorama_hue    = tileset.panorama_hue
        @fog_name        = tileset.fog_name
        @fog_hue         = tileset.fog_hue
        @fog_opacity     = tileset.fog_opacity
        @fog_blend_type  = tileset.fog_blend_type
        @fog_zoom        = tileset.fog_zoom
        @fog_sx          = tileset.fog_sx
        @fog_sy          = tileset.fog_sy
        @battleback_name = tileset.battleback_name
        @passages        = tileset.passages
        @priorities      = tileset.priorities
        @terrain_tags    = tileset.terrain_tags
    end

    def width;          return @map.width;          end
    def height;         return @map.height;         end
    def encounter_list; return @map.encounter_list; end
    def encounter_step; return @map.encounter_step; end
    def data;           return @map.data;           end

    def name
        ret = pbGetMessage(MessageTypes::MapNames, @map_id)
        ret.gsub!(/\\PN/, $Trainer.name) if $Trainer
        return ret
    end

    #-----------------------------------------------------------------------------
    # * Autoplays background music
    #   Plays music called "[normal BGM]_n" if it's night time and it exists
    #-----------------------------------------------------------------------------
    def autoplayAsCue
        if mapAutoplayBGM
            newBGM = mapBGM
            if PBDayNight.isNight? && FileTest.audio_exist?("Audio/BGM/" + newBGM.name + "_n")
                pbCueBGM(newBGM.name + "_n", 1.0, newBGM.volume, newBGM.pitch)
            else
                pbCueBGM(newBGM, 1.0)
            end
        end
        pbBGSPlay(mapBGS) if mapAutoplayBGS
    end

    #-----------------------------------------------------------------------------
    # * Plays background music
    #   Plays music called "[normal BGM]_n" if it's night time and it exists
    #-----------------------------------------------------------------------------
    def autoplay
        if mapAutoplayBGM
            newBGM = mapBGM
            if PBDayNight.isNight? && FileTest.audio_exist?("Audio/BGM/" + newBGM.name + "_n")
                pbBGMPlay(newBGM.name + "_n", newBGM.volume, newBGM.pitch)
            else
                pbBGMPlay(newBGM)
            end
        end
        pbBGSPlay(mapBGS) if mapAutoplayBGS
    end

    def valid?(x, y)
        return x >= 0 && x < width && y >= 0 && y < height
    end

    def validLax?(x, y)
        return x >= -10 && x <= width + 10 && y >= -10 && y <= height + 10
    end

    def passable?(x, y, d, self_event = nil)
        if !$game_temp.player_transferring && pbGetFollowerDependentEvent && self_event != $game_player
            dependent = pbGetFollowerDependentEvent
            return false if self_event != dependent && dependent.x == x && dependent.y == y
        end
        return false unless valid?(x, y)
        bit = (1 << (d / 2 - 1)) & 0x0f
        for event in events.values
            next if event.tile_id <= 0
            next if event == self_event
            next unless event.at_coordinate?(x, y)
            next if event.through
            tileID = getTileIDForEventAtCoordinate(event, x, y)
            terrainTag = GameData::TerrainTag.try_get(@terrain_tags[tileID])
            next if terrainTag.ignore_passability
            return true if terrainTag.ignore_passability
            return false if self_event && self_event != $game_player &&
                            self_event.name[/trippable/] && terrainTag.id == :TripWire
            return true if terrainTag.ice
            return true if terrainTag.ledge
            return true if terrainTag.can_surf
            return true if terrainTag.rock_climbable
            return true if terrainTag.bridge
            passage = @passages[tileID]
            return false if passage & bit != 0
            return false if passage & 0x0f == 0x0f
            return true if @priorities[tileID] == 0 && !event.name[/passablemult/]
        end
        return playerPassable?(x, y, d, self_event) if self_event == $game_player
        # All other events
        newx = x
        newy = y
        case d
        when 1
            newx -= 1
            newy += 1
        when 2
            newy += 1
        when 3
            newx += 1
            newy += 1
        when 4
            newx -= 1
        when 6
            newx += 1
        when 7
            newx -= 1
            newy -= 1
        when 8
            newy -= 1
        when 9
            newx += 1
            newy -= 1
        end
        return false unless valid?(newx, newy)
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
            # If already on water, only allow movement to another water tile
            if !self_event.nil? && terrain.can_surf_freely?
                for j in [2, 1, 0]
                    facing_tile_id = data[newx, newy, j]
                    return false if facing_tile_id.nil?
                    facing_terrain = GameData::TerrainTag.try_get(@terrain_tags[facing_tile_id])
                    if facing_terrain.id != :None && !facing_terrain.ignore_passability
                        return facing_terrain.can_surf_freely?
                    end
                end
                return false
            # Can't walk onto ice
            elsif terrain.ice
                return false
            elsif !self_event.nil? && self_event.x == x && self_event.y == y
                # Can't walk onto ledges
                for j in [2, 1, 0]
                    facing_tile_id = data[newx, newy, j]
                    return false if facing_tile_id.nil?
                    facing_terrain = GameData::TerrainTag.try_get(@terrain_tags[facing_tile_id])
                    return false if facing_terrain.ledge
                    break if facing_terrain.id != :None && !facing_terrain.ignore_passability
                end
            end
            # Regular passability checks
            next unless !terrain || !terrain.ignore_passability
            passage = @passages[tile_id]
            return false if passage & bit != 0 || passage & 0x0f == 0x0f
            return true if @priorities[tile_id] == 0
        end
        return true
    end

    def passableStrict?(x, y, _d, self_event = nil)
        return false unless valid?(x, y)
        for event in events.values
            next if event == self_event || event.tile_id <= 0 || event.through
            next unless event.at_coordinate?(x, y)
            tileID = getTileIDForEventAtCoordinate(event, x, y)
            terrainTag = GameData::TerrainTag.try_get(@terrain_tags[tileID])
            return true if terrainTag.ignore_passability
            return true if terrainTag.ice
            return true if terrainTag.ledge
            return true if terrainTag.can_surf
            return true if terrainTag.rock_climbable
            return true if terrainTag.bridge
            return false if @passages[tileID] & 0x0f != 0
            return true if @priorities[tileID] == 0
        end
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            terrainTag = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
            return true if terrainTag.ignore_passability
            return true if terrainTag.ice
            return true if terrainTag.ledge
            return true if terrainTag.can_surf
            return true if terrainTag.rock_climbable
            return true if terrainTag.bridge
            return false if @passages[tile_id] & 0x0f != 0
            return true if @priorities[tile_id] == 0
        end
        return true
    end

    def playerPassable?(x, y, d, _self_event = nil)
        bit = (1 << (d / 2 - 1)) & 0x0f
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
            passage = @passages[tile_id]
            if terrain
                # Ignore bridge tiles if not on a bridge
                next if terrain.bridge && $PokemonGlobal.bridge == 0
                # Make water tiles passable if player is surfing or has the surfboard
                return true if terrain.can_surf && !terrain.waterfall && ($PokemonGlobal.surfing || playerCanSurf?)
                return true if terrain.rock_climbable && $PokemonBag.pbHasItem?(:CLIMBINGGEAR)
                # Prevent cycling in really tall grass/on ice
                return false if $PokemonGlobal.bicycle && !terrain.can_bicycle?
                # Depend on passability of bridge tile if on bridge
                return (passage & bit == 0 && passage & 0x0f != 0x0f) if terrain.bridge && $PokemonGlobal.bridge > 0
            end
            # Regular passability checks
            if !terrain || !terrain.ignore_passability
                return false if passage & bit != 0 || passage & 0x0f == 0x0f
                return true if @priorities[tile_id] == 0
            end
        end
        return true
    end

    def bush?(x, y)
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            return false if GameData::TerrainTag.try_get(@terrain_tags[tile_id]).bridge &&
                            $PokemonGlobal.bridge > 0
            return true if @passages[tile_id] & 0x40 == 0x40
        end
        return false
    end

    def deepBush?(x, y)
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
            return false if terrain.bridge && $PokemonGlobal.bridge > 0
            return true if terrain.deep_bush && @passages[tile_id] & 0x40 == 0x40
        end
        return false
    end

    def counter?(x, y)
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            passage = @passages[tile_id]
            return true if passage & 0x80 == 0x80
        end
        return false
    end

    def terrain_tag(x, y, countBridge = false, checkEvents = false, self_event = nil)
        if valid?(x, y)
            for event in events.values
                next if event == self_event || event.tile_id <= 0 || event.through
                next unless event.at_coordinate?(x, y)
                tileID = getTileIDForEventAtCoordinate(event, x, y)
                terrainTag = GameData::TerrainTag.try_get(@terrain_tags[tileID])
                return terrainTag
            end
            for i in [2, 1, 0]
                tile_id = data[x, y, i]
                terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
                next if terrain.id == :None || terrain.ignore_passability
                next if !countBridge && terrain.bridge && $PokemonGlobal.bridge == 0
                return terrain
            end
        end
        return GameData::TerrainTag.get(:None)
    end

    # Unused.
    def check_event(x, y)
        for event in events.values
            return event.id if event.at_coordinate?(x, y)
        end
    end

    def display_x=(value)
        return if @display_x == value
        @display_x = value
        if GameData::MapMetadata.exists?(map_id) && GameData::MapMetadata.get(map_id).snap_edges
            max_x = (width - Graphics.width * 1.0 / TILE_WIDTH) * REAL_RES_X
            @display_x = [0, [@display_x, max_x].min].max
        end
        $MapFactory.setMapsInRange if $MapFactory
    end

    def display_y=(value)
        return if @display_y == value
        @display_y = value
        if GameData::MapMetadata.exists?(map_id) && GameData::MapMetadata.get(map_id).snap_edges
            max_y = (height - Graphics.height * 1.0 / TILE_HEIGHT) * REAL_RES_Y
            @display_y = [0, [@display_y, max_y].min].max
        end
        $MapFactory.setMapsInRange if $MapFactory
    end

    def scroll_up(distance)
        self.display_y -= distance
    end

    def scroll_down(distance)
        self.display_y += distance
    end

    def scroll_left(distance)
        self.display_x -= distance
    end

    def scroll_right(distance)
        self.display_x += distance
    end

    def scroll_downright(distance)
        @display_x = [@display_x + distance,
           (self.width - Graphics.width*1.0/TILE_WIDTH) * REAL_RES_X].min
        @display_y = [@display_y + distance,
           (self.height - Graphics.height*1.0/TILE_HEIGHT) * REAL_RES_Y].min
      end
    
      def scroll_downleft(distance)
        @display_x = [@display_x - distance, 0].max
        @display_y = [@display_y + distance,
           (self.height - Graphics.height*1.0/TILE_HEIGHT) * REAL_RES_Y].min
      end
    
      def scroll_upright(distance)
        @display_x = [@display_x + distance,
           (self.width - Graphics.width*1.0/TILE_WIDTH) * REAL_RES_X].min
        @display_y = [@display_y - distance, 0].max
      end
    
      def scroll_upleft(distance)
        @display_x = [@display_x - distance, 0].max
        @display_y = [@display_y - distance, 0].max
      end

    def start_scroll(direction, distance, speed)
        @scroll_direction = direction
        if [2, 8].include?(direction) # down or up
            @scroll_rest = distance * REAL_RES_Y
        else
            @scroll_rest = distance * REAL_RES_X
        end
        @scroll_speed = speed
    end

    def scrolling?
        return @scroll_rest > 0
    end

    def start_fog_tone_change(tone, duration)
        @fog_tone_target = tone.clone
        @fog_tone_duration = duration
        @fog_tone = @fog_tone_target.clone if @fog_tone_duration == 0
    end

    def start_fog_opacity_change(opacity, duration)
        @fog_opacity_target = opacity * 1.0
        @fog_opacity_duration = duration
        @fog_opacity = @fog_opacity_target if @fog_opacity_duration == 0
    end

    def refresh
        for event in @events.values
            event.refresh
        end
        for common_event in @common_events.values
            common_event.refresh
        end
        @need_refresh = false
    end

    def update
        # refresh maps if necessary
        if $MapFactory
            for i in $MapFactory.maps
                i.refresh if i.need_refresh
            end
            $MapFactory.setCurrentMap
        end
        # If scrolling
        if @scroll_rest > 0
            distance = (1 << @scroll_speed) * 40.0 / Graphics.frame_rate
            distance = @scroll_rest if distance > @scroll_rest
            case @scroll_direction
            when 2 then scroll_down(distance)
            when 4 then scroll_left(distance)
            when 6 then scroll_right(distance)
            when 8 then scroll_up(distance)
            end
            @scroll_rest -= distance
        end
        # Only update events that are on-screen
        for event in @events.values
            event.update
        end
        # Update common events
        for common_event in @common_events.values
            common_event.update
        end
        # Update fog
        @fog_ox -= @fog_sx / 8.0
        @fog_oy -= @fog_sy / 8.0
        if @fog_tone_duration >= 1
            d = @fog_tone_duration
            target = @fog_tone_target
            @fog_tone.red   = (@fog_tone.red * (d - 1) + target.red) / d
            @fog_tone.green = (@fog_tone.green * (d - 1) + target.green) / d
            @fog_tone.blue  = (@fog_tone.blue * (d - 1) + target.blue) / d
            @fog_tone.gray  = (@fog_tone.gray * (d - 1) + target.gray) / d
            @fog_tone_duration -= 1
        end
        if @fog_opacity_duration >= 1
            d = @fog_opacity_duration
            @fog_opacity = (@fog_opacity * (d - 1) + @fog_opacity_target) / d
            @fog_opacity_duration -= 1
        end
    end

    def update_scrolling
        # If scrolling
        if @scroll_rest > 0
          # Change from scroll speed to distance in map coordinates
          distance = (1<<@scroll_speed)*40/Graphics.frame_rate
          distance = @scroll_rest if distance>@scroll_rest
          # Execute scrolling
          case @scroll_direction
          when 1 then scroll_downleft(distance)
          when 2 then scroll_down(distance)
          when 3 then scroll_downright(distance)
          when 4 then scroll_left(distance)
          when 6 then scroll_right(distance)
          when 7 then scroll_upleft(distance)
          when 8 then scroll_up(distance)
          when 9 then scroll_upright(distance)
          end
          # Subtract distance scrolled
          @scroll_rest -= distance
        end
      end

    def tileset_id;     return @map.tileset_id;     end
    def bgm;            return @map.bgm;            end

    def getTileIDForEventAtCoordinate(event, x, y)
        coordinateX, coordinateY = coordinates_from_tild_ID(event.tile_id)
        newCoordinateX = coordinateX + (x - event.x)
        newCoordinateY = coordinateY + (y - event.y)
        return tile_ID_from_coordinates(newCoordinateX, newCoordinateY)
    end

    def terrainHasProperty?(x, y, self_event = nil, &block)
        # Events
        for event in events.values
            next if event.tile_id <= 0
            next if event == self_event
            next unless event.at_coordinate?(x, y)
            next if event.through
            tileID = getTileIDForEventAtCoordinate(event, x, y)
            terrainTagData = GameData::TerrainTag.try_get(@terrain_tags[tileID])
            next if terrainTagData.ignore_passability
            return true if block.call(terrainTagData)
        end

        # Tiles
        for i in [2, 1, 0]
            tile_id = data[x, y, i]
            next unless tile_id
            terrainTagData = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
            return true if block.call(terrainTagData)
        end

        return false
    end

    def slowingTerrain?(x, y, self_event = nil)
        return terrainHasProperty?(x, y, self_event) { |terrainTagData|
            terrainTagData.slows
        }
    end

    def noRunTerrain?(x, y, self_event = nil)
        return terrainHasProperty?(x, y, self_event) { |terrainTagData|
            terrainTagData.walkingForced?
        }
    end

    def noBikingTerrain?(x, y, self_event = nil)
        return terrainHasProperty?(x, y, self_event) { |terrainTagData|
            !terrainTagData.can_bicycle?
        }
    end

    def pushing_tag(x, y, countBridge = false, self_event = nil)
        if valid?(x, y)
            # Events
            for event in events.values
                next if event.tile_id <= 0
                next if event == self_event
                next unless event.at_coordinate?(x, y)
                next if event.through
                tileID = getTileIDForEventAtCoordinate(event, x, y)
                tag = @terrain_tags[tileID]
                terrainTagData = GameData::TerrainTag.try_get(tag)
                next unless terrainTagData.push_direction
                return terrainTagData
            end

            for i in [2, 1, 0]
                tile_id = data[x, y, i]
                next unless tile_id
                terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
                next unless terrain.push_direction
                next if !countBridge && terrain.bridge && $PokemonGlobal.bridge == 0
                return terrain
            end
        end
        return GameData::TerrainTag.get(:None)
    end

    def encounter_terrain_tag(x, y, countBridge = false)
        if valid?(x, y)
            for i in [2, 1, 0]
                tile_id = data[x, y, i]
                next unless tile_id
                terrain = GameData::TerrainTag.try_get(@terrain_tags[tile_id])
                next unless terrain.encounter_tile
                next if !countBridge && terrain.bridge && $PokemonGlobal.bridge == 0
                return terrain
            end
        end
        return GameData::TerrainTag.get(:None)
    end

    def musicSettingMap(id = -1)
        id = @map_id if id == -1
        mapWithRightSettingsID = getMusicSettingPseudoParentIDOfGameMap(id)
        deferredMap = load_data(format("Data/Map%03d.rxdata", mapWithRightSettingsID))
        return deferredMap
    end

    def mapAutoplayBGM(id = -1)
        return true if $PokemonGlobal.mapHasForcedBGM?(id)
        return musicSettingMap(id).autoplay_bgm
    end

    def mapAutoplayBGS(id = -1)
        return musicSettingMap(id).autoplay_bgs
    end

    def mapBGM(id = -1)
        return $PokemonGlobal.mapForcedBGM(id) if $PokemonGlobal.mapHasForcedBGM?(id)
        return musicSettingMap(id).bgm
    end

    def mapBGS(id = -1)
        return musicSettingMap(id).bgs
    end

    def playingDefaultBGM?
        return mapAutoplayBGM(mapid) == $game_system.playing_bgm
    end

    #-----------------------------------------------------------------------------
    # Camera operations
    #-----------------------------------------------------------------------------
    def slideCameraToSpot(centerX, centerY, speed = 3)
        distX = (centerX - 8) - (self.display_x / 128)
        xDirection = distX > 0 ? 6 : 4
        distY = (centerY - 6) - (self.display_y / 128)
        yDirection = distY > 0 ? 2 : 8
        distXAbs = distX.abs
        distYAbs = distY.abs
        if distXAbs > distYAbs
            pbScrollMap(xDirection, distXAbs, speed) if distXAbs > 0
            pbScrollMap(yDirection, distYAbs, speed) if distYAbs > 0
        else
            pbScrollMap(yDirection, distYAbs, speed) if distYAbs > 0
            pbScrollMap(xDirection, distXAbs, speed) if distXAbs > 0
        end
    end

    def timedCameraPreview(centerX, centerY, seconds = 5)
        prevCameraX = self.display_x
        prevCameraY = self.display_y
        blackFadeOutIn do
            centerCameraOnSpot(centerX, centerY)
            $scene.updateSpritesets
        end
        frame = 0
        currentCenterX = centerX
        currentCenterY = centerY
        until frame >= Graphics.frame_rate * seconds
            Graphics.update
            Input.update
            pbUpdateSceneMap
            frame += 1
        end
        blackFadeOutIn do
            self.display_x = prevCameraX
            self.display_y = prevCameraY
            $scene.updateSpritesets
        end
    end

    def controlledCameraPreview(centerX, centerY, maxXOffset = 6, maxYOffset = 3, cameraSpeed = 0.15)
        prevCameraX = self.display_x
        prevCameraY = self.display_y
        blackFadeOutIn do
            centerCameraOnSpot(centerX, centerY)
            $scene.updateSpritesets
        end

        @sprites = {}

        controlArrowsViewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        controlArrowsViewport.z = 99999
        @sprites["scroll_arrow_up"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,controlArrowsViewport)
        @sprites["scroll_arrow_up"].x = (Graphics.width - 28) / 2
        @sprites["scroll_arrow_up"].y = 4
        @sprites["scroll_arrow_up"].visible = true
        @sprites["scroll_arrow_up"].play

        @sprites["scroll_arrow_down"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,controlArrowsViewport)
        @sprites["scroll_arrow_down"].x = (Graphics.width - 28) / 2
        @sprites["scroll_arrow_down"].y = Graphics.height - 44
        @sprites["scroll_arrow_down"].visible = true
        @sprites["scroll_arrow_down"].play

        @sprites["scroll_arrow_left"] = AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,2,controlArrowsViewport)
        @sprites["scroll_arrow_left"].x = 4
        @sprites["scroll_arrow_left"].y = (Graphics.height - 28) / 2
        @sprites["scroll_arrow_left"].visible = true
        @sprites["scroll_arrow_left"].play

        @sprites["scroll_arrow_right"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,controlArrowsViewport)
        @sprites["scroll_arrow_right"].x = Graphics.width - 44
        @sprites["scroll_arrow_right"].y = (Graphics.height - 28) / 2
        @sprites["scroll_arrow_right"].visible = true
        @sprites["scroll_arrow_right"].play

        currentCenterX = centerX
        currentCenterY = centerY
        loop do
            Graphics.update
            Input.update
            pbUpdateSpriteHash(@sprites)
            pbUpdateSceneMap
            break if Input.trigger?(Input::BACK)
            
            xDir = 0
            yDir = 0

            if Input.press?(Input::LEFT)
                if currentCenterX > centerX - maxXOffset
                    xDir = -1
                elsif Input.trigger?(Input::LEFT)
                    pbSEPlay("Player bump")
                end
            elsif Input.press?(Input::RIGHT)
                if currentCenterX < centerX + maxXOffset
                    xDir = 1
                elsif Input.trigger?(Input::RIGHT)
                    pbSEPlay("Player bump")
                end
            end

            if Input.press?(Input::UP)
                if currentCenterY > centerY - maxYOffset
                    yDir = -1
                elsif Input.trigger?(Input::UP)
                    pbSEPlay("Player bump")
                end
            elsif Input.press?(Input::DOWN)
                if currentCenterY < centerY + maxYOffset
                    yDir = 1
                elsif Input.trigger?(Input::DOWN)
                    pbSEPlay("Player bump")
                end
            end

            # Nerf the speed if moving diagonally
            if xDir != 0 && yDir != 0
                xDir *= 0.7
                yDir *= 0.7
            end

            # Update the position and move the camera
            currentCenterX += cameraSpeed * xDir
            currentCenterY += cameraSpeed * yDir
            centerCameraOnSpot(currentCenterX, currentCenterY)

            # Update the scroll arrows
            @sprites["scroll_arrow_up"].visible = currentCenterY > centerY - maxYOffset
            @sprites["scroll_arrow_down"].visible = currentCenterY < centerY + maxYOffset
            @sprites["scroll_arrow_left"].visible = currentCenterX > centerX - maxXOffset
            @sprites["scroll_arrow_right"].visible = currentCenterX < centerX + maxXOffset
        end
        blackFadeOutIn do
            pbDisposeSpriteHash(@sprites)
            controlArrowsViewport.dispose

            self.display_x = prevCameraX
            self.display_y = prevCameraY
            $scene.updateSpritesets
        end
    end

    def centerCameraOnSpot(centerX, centerY)
        centerOffsetX = (Graphics.width / TILE_WIDTH) / 2 - 1
        self.display_x = (centerX - centerOffsetX) * 128
        centerOffsetY = (Graphics.height / TILE_HEIGHT) / 2 + 1
        self.display_y = (centerY - centerOffsetY) * 128
    end

    def centerCameraOnPlayer(xPixelsOffset = 0, yPixelsOffset = 0)
        centerOffsetX = (Graphics.width / TILE_WIDTH) / 2 - 0.5
        self.display_x = ($game_player.x - centerOffsetX + xPixelsOffset) * 128
        centerOffsetY = (Graphics.height / TILE_HEIGHT) / 2 - 0.5
        self.display_y = ($game_player.y - centerOffsetY + yPixelsOffset) * 128
    end

    def slideCameraToPlayer(speed = 3)
        slideCameraToSpot($game_player.x, $game_player.y, speed)
    end
end

#===============================================================================
#
#===============================================================================
def pbScrollMap(direction,distance,speed)
  if speed==0
    case direction
    when 2 then $game_map.scroll_down(distance * Game_Map::REAL_RES_Y)
    when 4 then $game_map.scroll_left(distance * Game_Map::REAL_RES_X)
    when 6 then $game_map.scroll_right(distance * Game_Map::REAL_RES_X)
    when 8 then $game_map.scroll_up(distance * Game_Map::REAL_RES_Y)
    end
  else
    $game_map.start_scroll(direction, distance, speed)
    oldx = $game_map.display_x
    oldy = $game_map.display_y
    loop do
      Graphics.update
      Input.update
      break if !$game_map.scrolling?
      pbUpdateSceneMap
      break if $game_map.display_x==oldx && $game_map.display_y==oldy
      oldx = $game_map.display_x
      oldy = $game_map.display_y
    end
  end
end
