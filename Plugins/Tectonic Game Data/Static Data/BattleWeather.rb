module GameData
    class BattleWeather
        attr_reader :id
        attr_reader :real_name
        attr_reader :animation

        DATA = {}

        extend ClassMethodsSymbols
        include InstanceMethods

        def self.load; end
        def self.save; end

        def initialize(hash)
            @id        = hash[:id]
            @real_name = hash[:name] || "Unnamed"
            @animation = hash[:animation]
        end

        # @return [String] the translated name of this battle weather
        def name
            return _INTL(@real_name)
        end
    end
end

#===============================================================================

GameData::BattleWeather.register({
  :id   => :None,
  :name => _INTL("None"),
})

GameData::BattleWeather.register({
  :id        => :Sunshine,
  :name      => _INTL("Sun"),
  :animation => "Sunny",
})

GameData::BattleWeather.register({
  :id        => :Rainstorm,
  :name      => _INTL("Rain"),
  :animation => "Rain",
})

GameData::BattleWeather.register({
  :id        => :Sandstorm,
  :name      => _INTL("Sandstorm"),
  :animation => "Sandstorm",
})

GameData::BattleWeather.register({
  :id        => :Hail,
  :name      => _INTL("Hail"),
  :animation => "Hail",
})

GameData::BattleWeather.register({
  :id        => :HarshSun,
  :name      => _INTL("Harsh Sun"),
  :animation => "HarshSun",
})

GameData::BattleWeather.register({
  :id        => :HeavyRain,
  :name      => _INTL("Heavy Rain"),
  :animation => "HeavyRain",
})

GameData::BattleWeather.register({
  :id        => :StrongWinds,
  :name      => _INTL("Strong Winds"),
  :animation => "StrongWinds",
})

GameData::BattleWeather.register({
    :id        => :Eclipse,
    :name      => _INTL("Eclipse"),
    :animation => "Eclipse",
})

GameData::BattleWeather.register({
  :id        => :Moonglow,
  :name      => _INTL("Moonglow"),
  :animation => "Moonglow",
})

GameData::BattleWeather.register({
  :id        => :RingEclipse,
  :name      => _INTL("Ring Eclipse"),
  :animation => "Eclipse",
})

GameData::BattleWeather.register({
  :id        => :BloodMoon,
  :name      => _INTL("Blood Moon"),
  :animation => "Moonlight",
})

GameData::BattleWeather.register({
  :id        => :StarStorm,
  :name      => _INTL("Star Storm"),
  :animation => "Sandstorm",
})

GameData::BattleWeather.register({
  :id        => :IceAge,
  :name      => _INTL("Ice Age"),
  :animation => "Hail",
})