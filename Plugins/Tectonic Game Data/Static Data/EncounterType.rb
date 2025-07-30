module GameData
    class EncounterType
      attr_reader :id
      attr_reader :real_name
      attr_reader :type   # :land, :cave, :water, :fishing, :contest, :none
      attr_reader :trigger_chance
      attr_reader :old_slots
  
      DATA = {}
  
      extend ClassMethodsSymbols
      include InstanceMethods
  
      def self.load; end
      def self.save; end
  
      def initialize(hash)
        @id             = hash[:id]
        @real_name      = hash[:id].to_s        || "Unnamed"
        @type           = hash[:type]           || :none
        @trigger_chance = hash[:trigger_chance] || 0
        @old_slots      = hash[:old_slots]
      end
    end
  end
  
  #===============================================================================
  
  GameData::EncounterType.register({
    :id             => :Land,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :LandDay,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :LandNight,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :LandMorning,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :LandAfternoon,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :LandEvening,
    :type           => :land,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :Cave,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :CaveDay,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :CaveNight,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :CaveMorning,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :CaveAfternoon,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :CaveEvening,
    :type           => :cave,
    :trigger_chance => 5,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :Water,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :WaterDay,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :WaterNight,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :WaterMorning,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :WaterAfternoon,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :WaterEvening,
    :type           => :water,
    :trigger_chance => 2,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :OldRod,
    :type           => :fishing,
    :old_slots      => [70, 30]
  })
  
  GameData::EncounterType.register({
    :id             => :GoodRod,
    :type           => :fishing,
    :old_slots      => [60, 20, 20]
  })
  
  GameData::EncounterType.register({
    :id             => :SuperRod,
    :type           => :fishing,
    :old_slots      => [40, 40, 15, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :RockSmash,
    :type           => :none,
    :trigger_chance => 50,
    :old_slots      => [60, 30, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :HeadbuttLow,
    :type           => :none,
    :old_slots      => [30, 25, 20, 10, 5, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :HeadbuttHigh,
    :type           => :none,
    :old_slots      => [30, 25, 20, 10, 5, 5, 4, 1]
  })
  
  GameData::EncounterType.register({
    :id             => :BugContest,
    :type           => :contest,
    :trigger_chance => 21,
    :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
  })
  

  # Tall Grass
GameData::EncounterType.register({
  :id             => :LandTall,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :LandSparse,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :Mud,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Active Water
GameData::EncounterType.register({
  :id             => :ActiveWater,
  :type           => :water,
  :trigger_chance => 15,
  :old_slots      => [60, 30, 5, 4, 1]
})

GameData::EncounterType.register({
  :id             => :Puddle,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :DarkCave,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :FloweryGrass,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :FloweryGrass2,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :LandTinted,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :SewerFloor,
  :type           => :land,
  :trigger_chance => 21,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

GameData::EncounterType.register({
  :id             => :SewerWater,
  :type           => :land,
  :trigger_chance => 1,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# A special encounter type only used to mark other items
GameData::EncounterType.register({
  :id             => :Special,
  :type           => :none,
  :trigger_chance => 0,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Fishing Contest Water
GameData::EncounterType.register({
  :id             => :FishingContest,
  :type           => :water,
  :trigger_chance => 30,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Dangerous Clouds
GameData::EncounterType.register({
  :id             => :Cloud,
  :type           => :land,
  :trigger_chance => 1,
  :old_slots      => [20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1]
})

# Grass in water
GameData::EncounterType.register({
  :id             => :WaterGrass,
  :type           => :water,
  :trigger_chance => 15,
  :old_slots      => [60, 30, 5, 4, 1]
})