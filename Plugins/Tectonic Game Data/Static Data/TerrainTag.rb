module GameData
    class TerrainTag
      attr_reader :id
      attr_reader :id_number
      attr_reader :real_name
      attr_reader :can_surf
      attr_reader :waterfall   # The main part only, not the crest
      attr_reader :waterfall_crest
      attr_reader :can_fish
      attr_reader :can_dive
      attr_reader :deep_bush
      attr_reader :shows_grass_rustle
      attr_reader :land_wild_encounters
      attr_reader :double_wild_encounters
      attr_reader :battle_environment
      attr_reader :ledge
      attr_reader :ice
      attr_reader :bridge
      attr_reader :shows_reflections
      attr_reader :must_walk
      attr_reader :ignore_passability
      attr_reader :slows
      attr_reader :rock_climbable
      attr_reader :push_direction
      attr_reader :encounter_tile
      attr_reader :pinning_wind
  
      DATA = {}
  
      extend ClassMethods
      include InstanceMethods
  
      # @param other [Symbol, self, String, Integer]
      # @return [self]
      def self.try_get(other)
        return self.get(:None) if other.nil?
        validate other => [Symbol, self, String, Integer]
        return other if other.is_a?(self)
        other = other.to_sym if other.is_a?(String)
        return (self::DATA.has_key?(other)) ? self::DATA[other] : self.get(:None)
      end
  
      def self.load; end
      def self.save; end
  
      def initialize(hash)
        @id                     = hash[:id]
        @id_number              = hash[:id_number]
        @real_name              = hash[:id].to_s                || "Unnamed"
        @can_surf               = hash[:can_surf]               || false
        @waterfall              = hash[:waterfall]              || false
        @waterfall_crest        = hash[:waterfall_crest]        || false
        @can_fish               = hash[:can_fish]               || false
        @can_dive               = hash[:can_dive]               || false
        @deep_bush              = hash[:deep_bush]              || false
        @shows_grass_rustle     = hash[:shows_grass_rustle]     || false
        @land_wild_encounters   = hash[:land_wild_encounters]   || false
        @double_wild_encounters = hash[:double_wild_encounters] || false
        @battle_environment     = hash[:battle_environment]
        @ledge                  = hash[:ledge]                  || false
        @ice                    = hash[:ice]                    || false
        @bridge                 = hash[:bridge]                 || false
        @shows_reflections      = hash[:shows_reflections]      || false
        @must_walk              = hash[:must_walk]              || false
        @ignore_passability     = hash[:ignore_passability]     || false
        @slows     			        = hash[:slows]     			        || false
        @rock_climbable		      = hash[:rock_climbable]		      || false
        @push_direction         = hash[:push_direction]
        @encounter_tile         = hash[:encounter_tile]         || false
        @pinning_wind           = hash[:pinning_wind]           || false
      end
  
      def can_surf_freely?
        return @can_surf && !@waterfall && !@waterfall_crest
      end

      def walkingForced?
        return true if @must_walk
        return true if @pinning_wind && pinningWindActive?
        return false
      end

      def can_bicycle?
        return false if walkingForced?
        return false if @pinning_wind
        return true
      end
    end
  end
  
  #===============================================================================
  
  GameData::TerrainTag.register({
    :id                     => :None,
    :id_number              => 0,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Ledge,
    :id_number              => 1,
    :ledge                  => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Grass,
    :id_number              => 2,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Sand,
    :id_number              => 3,
    :battle_environment     => :Sand,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Rock,
    :id_number              => 4,
    :battle_environment     => :Rock,
  })
  
  GameData::TerrainTag.register({
    :id                     => :DeepWater,
    :id_number              => 5,
    :can_surf               => true,
    :can_fish               => true,
    :can_dive               => true,
    :battle_environment     => :MovingWater,
  })
  
  GameData::TerrainTag.register({
    :id                     => :StillWater,
    :id_number              => 6,
    :can_surf               => true,
    :can_fish               => true,
    :battle_environment     => :StillWater,
    :shows_reflections      => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Water,
    :id_number              => 7,
    :can_surf               => true,
    :can_fish               => true,
    :battle_environment     => :MovingWater,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Waterfall,
    :id_number              => 8,
    :can_surf               => true,
    :waterfall              => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :WaterfallCrest,
    :id_number              => 9,
    :can_surf               => true,
    :can_fish               => true,
    :waterfall_crest        => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :TallGrass,
    :id_number              => 10,
    :deep_bush              => true,
    :land_wild_encounters   => true,
    :battle_environment     => :TallGrass,
    :must_walk              => true,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :UnderwaterGrass,
    :id_number              => 11,
    :land_wild_encounters   => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Ice,
    :id_number              => 12,
    :battle_environment     => :Ice,
    :ice                    => true,
    :must_walk              => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Neutral,
    :id_number              => 13,
    :ignore_passability     => true,
  })
  
  # NOTE: This is referenced by ID in an Events.onStepTakenFieldMovement proc that
  #       adds soot to the Soot Sack if the player walks over one of these tiles.
  GameData::TerrainTag.register({
    :id                     => :SootGrass,
    :id_number              => 14,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Bridge,
    :id_number              => 15,
    :bridge                 => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :Puddle,
    :id_number              => 16,
    :battle_environment     => :Puddle,
    :shows_reflections      => true,
  })
  
  # Mud
  GameData::TerrainTag.register({
    :id                     => :Mud,
    :id_number              => 17,
    :battle_environment     => :Mud,
    :land_wild_encounters	  => true,
    :must_walk              => true,
    :slows				          => true,
    :encounter_tile         => true,
  })
  
  # Puddle
  GameData::TerrainTag.register({
    :id                     => :Puddle,
    :id_number              => 18,
    :battle_environment     => :Puddle,
    :land_wild_encounters	  => true,
    :encounter_tile         => true,
  })
  
  # Sparse Grass
  GameData::TerrainTag.register({
    :id                     => :SparseGrass,
    :id_number              => 19,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
    :encounter_tile         => true,
  })
  
  # Dark Cave
  GameData::TerrainTag.register({
    :id                     => :DarkCave,
    :id_number              => 20,
    :battle_environment     => :Cave,
    :land_wild_encounters	  => true,
    :encounter_tile         => true,
  })
  
  # Flowery Grass
  GameData::TerrainTag.register({
    :id                     => :FloweryGrass,
    :id_number              => 21,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
    :encounter_tile         => true,
  })
  
  # Flowery Grass 2
  GameData::TerrainTag.register({
    :id                     => :FloweryGrass2,
    :id_number              => 22,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
    :encounter_tile         => true,
  })
  
  # Tinted grass
  GameData::TerrainTag.register({
    :id                     => :TintedGrass,
    :id_number              => 23,
    :shows_grass_rustle     => true,
    :land_wild_encounters   => true,
    :battle_environment     => :Grass,
    :encounter_tile         => true,
  })
  
  # Sewer Floor
  GameData::TerrainTag.register({
    :id                     => :SewerFloor,
    :id_number              => 24,
    :land_wild_encounters   => true,
    :battle_environment     => :Puddle,
    :encounter_tile         => true,
  })
  
  # Sewer Water
  GameData::TerrainTag.register({
    :id                     => :SewerWater,
    :id_number              => 25,
    :land_wild_encounters   => true,
    :battle_environment     => :MovingWater,
    :can_surf				        => true,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :SewerGrate,
    :id_number              => 27,
    :land_wild_encounters   => true,
    :battle_environment     => :MovingWater,
  })
  
  # Climbable Rocks
  GameData::TerrainTag.register({
    :id                     => :RockClimb,
    :id_number              => 26,
    :must_walk              => true,
    :slows              	  => true,
    :rock_climbable		      => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :FishingContest,
    :type                   => :contest,
    :id_number              => 28,
    :can_surf               => true,
    :battle_environment     => :MovingWater,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :SurfBlock,
    :id_number              => 29,
    :can_surf               => false,
  })
  
  GameData::TerrainTag.register({
    :id                     => :SouthConveyor,
    :id_number              => 30,
  })
  
  GameData::TerrainTag.register({
    :id                     => :WallReplaceConcave,
    :id_number              => 31,
  })
  
  GameData::TerrainTag.register({
    :id                     => :WallReplaceConvex,
    :id_number              => 32,
  })
  
  GameData::TerrainTag.register({
    :id                     => :ActiveWater,
    :id_number              => 33,
    :battle_environment     => :Water,
    :can_surf               => true,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :DarkCloud,
    :id_number              => 34,
    :ignore_passability     => true,
    :encounter_tile         => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :NorthWater,
    :id_number              => 35,
    :push_direction         => 8,
    :battle_environment     => :Water,
    :can_surf               => true,
    :must_walk              => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :SouthWater,
    :id_number              => 36,
    :push_direction         => 2,
    :battle_environment     => :Water,
    :can_surf               => true,
    :must_walk              => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :EastWater,
    :id_number              => 37,
    :push_direction         => 6,
    :battle_environment     => :Water,
    :can_surf               => true,
    :must_walk              => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :WestWater,
    :id_number              => 38,
    :push_direction         => 4,
    :battle_environment     => :Water,
    :can_surf               => true,
    :must_walk              => true,
  })

  GameData::TerrainTag.register({
    :id                     => :TripWire,
    :id_number              => 39,
  })

  GameData::TerrainTag.register({
    :id                     => :NorthWind,
    :id_number              => 40,
    :push_direction         => 8,
    :pinning_wind           => true,
    :ignore_passability     => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :SouthWind,
    :id_number              => 41,
    :push_direction         => 2,
    :pinning_wind           => true,
    :ignore_passability     => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :EastWind,
    :id_number              => 42,
    :push_direction         => 6,
    :pinning_wind           => true,
    :ignore_passability     => true,
  })
  
  GameData::TerrainTag.register({
    :id                     => :WestWind,
    :id_number              => 43,
    :push_direction         => 4,
    :pinning_wind           => true,
    :ignore_passability     => true,
  })

  GameData::TerrainTag.register({
    :id                     => :WaterGrass,
    :id_number              => 44,
    :battle_environment     => :Water,
    :can_surf               => true,
    :encounter_tile         => true,
  })