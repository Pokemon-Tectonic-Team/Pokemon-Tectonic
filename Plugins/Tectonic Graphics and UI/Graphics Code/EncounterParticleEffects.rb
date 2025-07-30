
# Show grass rustle animation, and similar animations for other encounter tiles
Events.onStepTakenFieldMovement += proc { |_sender, e|
  event = e[0]   # Get the event affected by field movement
  if $scene.is_a?(Scene_Map)
    if $Options.particle_effects == 0 && !event.floats
		$globalParticleCounter = 0 if $globalParticleCounter.nil?
		$globalParticleCounter += 1
		if $globalParticleCounter >= 4
			$globalParticleCounter = 0
			event.each_occupied_tile do |x, y|
				tag = $MapFactory.getTerrainTag(event.map.map_id, x, y, true)
				if tag.shows_grass_rustle
					$scene.spriteset.addUserAnimation(Settings::GRASS_ANIMATION_ID, x, y, true, 1)
				elsif tag == :Puddle || tag == :ActiveWater || tag == :WaterGrass
					$scene.spriteset.addUserAnimation(8, x, y, true, 1)
				elsif tag == :FishingContest
					$scene.spriteset.addUserAnimation(8, x, y, true, 1)
				elsif tag == :SewerFloor
					$scene.spriteset.addUserAnimation(18, x, y, true, 1)
				elsif tag == :DarkCave
					$scene.spriteset.addUserAnimation(2, x, y, true, 1)
				end
			end
		end
	end
  end
}