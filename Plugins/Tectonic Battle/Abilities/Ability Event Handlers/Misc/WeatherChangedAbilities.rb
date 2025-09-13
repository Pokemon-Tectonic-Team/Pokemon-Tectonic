BattleHandlers::WeatherChangedAbility.add(:IONIZEDALLOY,
  proc { |ability, oldWeather, battler, battle| 
    if battle.rainy?
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("Ions in the atmosphere react to {1} (Weather)!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
      battle.scene.pbRefresh
    elsif %i[Rainstorm HeavyRain].include?(oldWeather) #If changed from rain to something else
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("The ions around {1} settled down.", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
      battle.scene.pbRefresh
    end
  }
)