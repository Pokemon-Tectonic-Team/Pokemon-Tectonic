#===============================================================================
# These are used to define whether the follower should appear or disappear when
# refreshing it. "next true" will let it stay and "next false" will make it disappear
#===============================================================================
Events.FollowerRefresh += proc{|pokemon|
  # The Pokemon disappears if the player is cycling
  next false if $PokemonGlobal.bicycle
  # Pokeride Compatibility
  next false if $PokemonGlobal.mount if defined?($PokemonGlobal.mount)
  if $PokemonGlobal.surfing
    next true if swimmingSpecies?(pokemon.species,pokemon.form)
    next true if floatingPokemon?(pokemon)
    next false
  elsif $PokemonGlobal.diving
    next true if pokemon.hasType?(:WATER)
    next false
  end
}

def swimmingSpecies?(species,form=0)
	species_data = GameData::Species.get_species_form(species,form)
  return false if FollowerSettings::SURFING_FOLLOWERS_EXCEPTIONS.any?{|s| s == species || s.to_s == "#{species}_#{form}" }
	return true if species_data.type1 == :WATER || species_data.type2 == :WATER
	return false
end

def floatingPokemon?(pokemon)
  GameData::Item.getByFlag("Levitation").each do |levitationItem|
    return true if pokemon.hasItem?(levitationItem)
  end
  return floatingSpecies?(pokemon.species,pokemon.form)
end

def floatingSpecies?(species,form=0)
	species_data = GameData::Species.get_species_form(species,form)
	if species_data.type1 == :FLYING || species_data.type2 == :FLYING
		exception = FollowerSettings::SURFING_FOLLOWERS_EXCEPTIONS.any?{|s| s == species || s.to_s == "#{species}_#{form}" }
		return !exception
	end
  return true if species_data.abilities.include?(:LEVITATE)
	return true if species_data.abilities.include?(:DESERTSPIRIT)
  return true if FollowerSettings::SURFING_FOLLOWERS.any?{|s| s == species || s.to_s == "#{species}_#{form}" }
	return false
end

#-------------------------------------------------------------------------------
# These are used to define what the Follower will say when spoken to
#-------------------------------------------------------------------------------
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
# Special Dialogue when statused
  case pkmn.status
  when :POISON
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Poison, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1} is suffering the effects of being poisoned.",pkmn.name))
  when :BURN
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1}'s burn looks painful.",pkmn.name))
  when :FROSTBITE
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1}'s frostbite looks painful.",pkmn.name))
  when :SLEEP
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1} seems really tired.",pkmn.name))
  when :NUMB
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1} is standing still and twitching.",pkmn.name))
  when :DIZZY
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Confused, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1} looks dazed and confused.",pkmn.name))
  when :LEECHED
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1}'s energy is slowly being leeched away.",pkmn.name))
  when :WATERLOG
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal, event.x, event.y)
    pbWait(72)
    pbMessage(_INTL("{1} is soaked through.",pkmn.name))
  end
  next true if pkmn.status != :NONE
}

Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $PokemonGlobal.follower_hold_item
    items = %i[
      FULLRESTORE
      FULLRESTORE
      RARECANDY
      RARECANDY
      REPEL
      REPEL
      MAXREPEL
      TINYMUSHROOM
      TINYMUSHROOM
      PEARL
      NUGGET
      BIGMUSHROOM
      POKEBALL
      POKEBALL
      POKEBALL
      GREATBALL
      GREATBALL
      ULTRABALL
    ]
    # If no message or quantity is specified the default message is used and the quantity of item is 1
    next true if pbPokemonFound(items[rand(items.length)])
  end
}

# Specific message if the map name is Pokemon Lab
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?(_INTL("lab"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} is touching some kind of switch."),
      _INTL("{1} has a cord in its mouth!"),
      _INTL("{1} seems to want to touch the machinery.")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has the players name in it ie the Player's Hpuse
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?($Trainer.name.downcase + _INTL("'s"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} is sniffing around the room."),
      _INTL("{1} noticed {2}'s mom is nearby."),
      _INTL("{1} seems to want to settle down at home.")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Pokecenter or Pokemon Center
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?(_INTL("center"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} looks happy to see the nurse."),
      _INTL("{1} looks a little better just being in the Pokémon Center."),
      _INTL("{1} seems fascinated by the healing machinery."),
      _INTL("{1} looks like it wants to take a nap."),
      _INTL("{1} chirped a greeting at the nurse."),
      _INTL("{1} is watching {2} with a playful gaze."),
      _INTL("{1} seems to be completely at ease."),
      _INTL("{1} is making itself comfortable."),
      _INTL("There's a content expression on {1}'s face.")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Forest
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?(_INTL("forest"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Sing,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} seems highly interested in the trees."),
      _INTL("{1} seems to enjoy the buzzing of the bug Pokémon."),
      _INTL("{1} is jumping around restlessly in the forest."),
      _INTL("{1} is wandering around and listening to the different sounds."),
      _INTL("{1} is munching at the grass."),
      _INTL("{1} is wandering around and enjoying the forest scenery."),
      _INTL("{1} is playing around, plucking bits of grass."),
      _INTL("{1} is staring at the light coming through the trees."),
      _INTL("{1} is playing around with a leaf!"),
      _INTL("{1} seems to be listening to the sound of rustling leaves."),
      _INTL("{1} is standing perfectly still and might be imitating a tree..."),
      _INTL("{1} got tangled in the branches and almost fell down!"),
      _INTL("{1} was surprised when it got hit by a branch!"),
      _INTL("{1} seems highly interested in the trees."),
      _INTL("{1} seems to enjoy the buzzing of the bug Pokémon."),
      _INTL("{1} is jumping around restlessly in the forest.")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Gym in it
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?(_INTL("gym"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} looks eager to battle!"),
      _INTL("{1} is looking at {2} with a determined gleam in its eye."),
      _INTL("{1} is trying to intimidate the other trainers."),
      _INTL("{1} trusts {2} to come up with a winning strategy."),
      _INTL("{1} is keeping an eye on the gym leader."),
      _INTL("{1} is ready to pick a fight with someone."),
      _INTL("{1} looks like it might be preparing for a big showdown!"),
      _INTL("{1} wants to show off how strong it is!"),
      _INTL("{1} is...doing warm-up exercises?"),
      _INTL("{1} is growling quietly in contemplation...")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Specific message if the map name has Beach in it
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if $game_map.name.downcase.include?(_INTL("beach"))
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} seems to be enjoying the scenery."),
      _INTL("{1} seems to enjoy the sound of the waves moving the sand."),
      _INTL("{1} looks like it wants to swim!"),
      _INTL("{1} can barely look away from the ocean."),
      _INTL("{1} is staring longingly at the water."),
      _INTL("{1} keeps trying to shove {2} towards the water."),
      _INTL("{1} is excited to be looking at the sea!"),
      _INTL("{1} is happily watching the waves!"),
      _INTL("{1} is playing on the sand!"),
      _INTL("{1} is staring at {2}'s footprints in the sand."),
      _INTL("{1} is rolling around in the sand.")
    ]
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Rain specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if [:Rain,:HeavyRain].include?($game_screen.weather_type)
    if pkmn.hasType?(:WATER) || pkmn.hasType?(:ELECTRIC)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} seems to be enjoying the weather."),
        _INTL("{1} seems to be happy about the rain!"),
        _INTL("{1} seems to be very surprised that it’s raining!"),
        _INTL("{1} beamed happily at {2}!"),
        _INTL("{1} is gazing up at the rainclouds."),
        _INTL("Raindrops keep falling on {1}."),
        _INTL("{1} is looking up with its mouth gaping open.")
      ]
    elsif (pkmn.hasType?(:FIRE) || pkmn.hasType?(:GROUND) || pkmn.hasType?(:ROCK)) && !pkmn.immuneToWeatherDownsides?
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} seems very upset by the weather."),
        _INTL("{1} is shivering..."),
        _INTL("{1} doesn’t seem to like being all wet..."),
        _INTL("{1} keeps trying to shake itself dry..."),
        _INTL("{1} moved closer to {2} for comfort."),
        _INTL("{1} is looking up at the sky and scowling."),
        _INTL("{1} seems to be having difficulty moving its body.")
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is staring up at the sky."),
        _INTL("{1} looks a bit surprised to see rain."),
        _INTL("{1} keeps trying to shake itself dry."),
        _INTL("The rain doesn't seem to bother {1} much."),
        _INTL("{1} is playing in a puddle!"),
        _INTL("{1} is slipping in the water and almost fell over!")
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Storm Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if :Storm == $game_screen.weather_type
    if pkmn.hasType?(:WATER) || pkmn.hasType?(:ELECTRIC)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is staring up at the sky."),
        _INTL("The storm seems to be making {1} excited."),
        _INTL("{1} looked up at the sky and shouted loudly!"),
        _INTL("The storm only seems to be energizing {1}!"),
        _INTL("{1} is happily zapping and jumping in circles!"),
        _INTL("The lightning doesn't bother {1} at all.")
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is staring up at the sky."),
        _INTL("The storm seems to be making {1} a bit nervous."),
        _INTL("The lightning startled {1}!"),
        _INTL("The rain doesn't seem to bother {1} much."),
        _INTL("The weather seems to be putting {1} on edge."),
        _INTL("{1} was startled by the lightning and snuggled up to {2}!")
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Snow Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if :Snow == $game_screen.weather_type
    if pkmn.hasType?(:ICE) || pkmn.hasType?(:GHOST)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is watching the snow fall."),
        _INTL("{1} is thrilled by the snow!"),
        _INTL("{1} is staring up at the sky with a smile."),
        _INTL("The snow seems to have put {1} in a good mood."),
        _INTL("{1} is cheerful because of the cold!")
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is watching the snow fall."),
        _INTL("{1} is nipping at the falling snowflakes."),
        _INTL("{1} wants to catch a snowflake in its mouth."),
        _INTL("{1} is fascinated by the snow."),
        _INTL("{1}'s teeth are chattering!"),
        _INTL("{1} made its body slightly smaller because of the cold...")
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Blizzard Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if :Blizzard == $game_screen.weather_type
    if pkmn.hasType?(:ICE) || pkmn.hasType?(:GHOST)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is watching the hail fall."),
        _INTL("{1} isn't bothered at all by the hail."),
        _INTL("{1} is staring up at the sky with a smile."),
        _INTL("The hail seems to have put {1} in a good mood."),
        _INTL("{1} is gnawing on a piece of hailstone.")
      ]
    elsif pkmn.immuneToWeatherDownsides?
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is coated in ice, but doesn't seem to mind."),
        _INTL("{1} seems unbothered by the frost."),
        _INTL("The hail doesn't slow {1} down."),
        _INTL("{1} doesn't seem to mind the weather.")
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is getting pelted by hail!"),
        _INTL("{1} wants to avoid the hail."),
        _INTL("The hail is hitting {1} painfully."),
        _INTL("{1} looks unhappy."),
        _INTL("{1} is shaking like a leaf!")
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Sandstorm Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if :Sandstorm == $game_screen.weather_type
    if pkmn.hasType?(:ROCK) || pkmn.hasType?(:GROUND)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is coated in sand."),
        _INTL("The weather doesn't seem to bother {1} at all!"),
        _INTL("The sand can't slow {1} down!"),
        _INTL("{1} is enjoying the weather.")
      ]
    elsif pkmn.immuneToWeatherDownsides?
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is coated in sand, but doesn't seem to mind."),
        _INTL("{1} seems unbothered by the sandstorm."),
        _INTL("The sand doesn't slow {1} down."),
        _INTL("{1} doesn't seem to mind the weather.")
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is covered in sand..."),
        _INTL("{1} spat out a mouthful of sand!"),
        _INTL("{1} is squinting through the sandstorm."),
        _INTL("The sand seems to be bothering {1}.")
      ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# Sunny Weather specific message for multiple types
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if :Sun == $game_screen.weather_type
    if pkmn.hasType?(:GRASS)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} seems pleased to be out in the sunshine."),
        _INTL("{1} is soaking up the sunshine."),
        _INTL("The bright sunlight doesn't seem to bother {1} at all."),
        _INTL("{1} sent a ring-shaped cloud of spores into the air!"),
        _INTL("{1} is stretched out its body and is relaxing in the sunshine."),
        _INTL("{1} is giving off a floral scent.")
      ]
    elsif pkmn.hasType?(:FIRE)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} seems to be happy about the great weather!"),
        _INTL("The bright sunlight doesn't seem to bother {1} at all."),
        _INTL("{1} looks thrilled by the sunshine!"),
        _INTL("{1} blew out a fireball."),
        _INTL("{1} is breathing out fire!"),
        _INTL("{1} is hot and cheerful!")
      ]
    elsif pkmn.hasType?(:WATER) || pkmn.hasType?(:GHOST)
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is glaring up at the sky."),
        _INTL("{1} seems personally offended by the sunshine."),
        _INTL("The bright sunshine seems to bothering {1}."),
        _INTL("{1} looks upset for some reason."),
        _INTL("{1} is trying to stay in {2}'s shadow."),
        _INTL("{1} keeps looking for shelter from the sunlight."),
      ]
    else
      $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
      pbWait(72)
      messages = [
        _INTL("{1} is squinting in the bright sunshine."),
        _INTL("{1} is starting to sweat."),
        _INTL("{1} seems a little uncomfortable in this weather."),
        _INTL("{1} looks a little overheated."),
        _INTL("{1} seems very hot..."),
        _INTL("{1} shielded its vision against the sparkling light!"),
       ]
    end
    pbMessage(_INTL(messages[rand(messages.length)],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Music Note animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 0
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Sing,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} seems to want to play with {2}."),
      _INTL("{1} is singing and humming."),
      _INTL("{1} is looking up at {2} with a happy expression."),
      _INTL("{1} swayed and danced around as it pleased."),
      _INTL("{1} is jumping around in a carefree way!"),
      _INTL("{1} is showing off its agility!"),
      _INTL("{1} is moving around happily!"),
      _INTL("Whoa! {1} suddenly started dancing in happiness!"),
      _INTL("{1} is steadily keeping up with {2}!"),
      _INTL("{1} is happy skipping about."),
      _INTL("{1} is playfully nibbling at the ground."),
      _INTL("{1} is playfully nipping at {2}'s feet!"),
      _INTL("{1} is following {2} very closely!"),
      _INTL("{1} turns around and looks at {2}."),
      _INTL("{1} is working hard to show off its mighty power!"),
      _INTL("{1} looks like it wants to run around!"),
      _INTL("{1} is wandering around enjoying the scenery."),
      _INTL("{1} seems to be enjoying this a little bit!"),
      _INTL("{1} is cheerful!"),
      _INTL("{1} seems to be singing something?"),
      _INTL("{1} is dancing around happily!"),
      _INTL("{1} is having fun dancing a lively jig!"),
      _INTL("{1} is so happy, it started singing!"),
      _INTL("{1} looked up and howled!"),
      _INTL("{1} seems to be feeling optimistic."),
      _INTL("It looks like {1} feels like dancing!"),
      _INTL("{1} suddenly started to sing! It seems to be feeling great."),
      _INTL("It looks like {1} wants to dance with {2}!")
    ]
    value = rand(messages.length)
    case value
    # Special move route to go along with some of the dialogue
    when 3, 9
        pbMoveRoute($game_player,[PBMoveRoute::Wait,65])
        pbMoveRoute(event,  [
          PBMoveRoute::TurnRight,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::TurnUp,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::TurnLeft,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::TurnDown,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0
        ])
    when 4, 5
        pbMoveRoute($game_player,[PBMoveRoute::Wait,40])
        pbMoveRoute(event,  [
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::Jump,0,0
        ])
    when 6, 17
        pbMoveRoute($game_player,[PBMoveRoute::Wait,20])
        pbMoveRoute(event,  [
          PBMoveRoute::TurnRight,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp
        ])
    when 7, 28
        pbMoveRoute($game_player,[PBMoveRoute::Wait,60])
        pbMoveRoute(event,  [
          PBMoveRoute::TurnRight,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnRight,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::Jump,0,0
        ])
    when 21, 22
        pbMoveRoute($game_player,[PBMoveRoute::Wait,50])
        pbMoveRoute(event,  [
          PBMoveRoute::TurnRight,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnUp,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnLeft,
          PBMoveRoute::Wait,4,
          PBMoveRoute::TurnDown,
          PBMoveRoute::Wait,4,
          PBMoveRoute::Jump,0,0,
          PBMoveRoute::Wait,10,
          PBMoveRoute::Jump,0,0
        ])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Angry animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 1
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Hate,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} let out a roar!"),
      _INTL("{1} is making a face like it's angry!"),
      _INTL("{1} seems to be angry for some reason."),
      _INTL("{1} chewed on {2}'s feet."),
      _INTL("{1} turned to face the other way, showing a defiant expression."),
      _INTL("{1} is trying to intimidate {2}'s foes!"),
      _INTL("{1} wants to pick a fight!"),
      _INTL("{1} is ready to fight!"),
      _INTL("It looks like {1} will fight just about anyone right now!"),
      _INTL("{1} is growling in a way that sounds almost like speech...")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 6, 7, 8
      pbMoveRoute($game_player,[PBMoveRoute::Wait,25])
      pbMoveRoute(event,  [
        PBMoveRoute::Jump,0,0,
        PBMoveRoute::Wait,10,
        PBMoveRoute::Jump,0,0
      ])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Neutral Animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 2
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Normal,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} is looking down steadily."),
      _INTL("{1} is sniffing around."),
      _INTL("{1} is concentrating deeply."),
      _INTL("{1} faced {2} and nodded."),
      _INTL("{1} is glaring straight into {2}'s eyes."),
      _INTL("{1} is surveying the area."),
      _INTL("{1} focused with a sharp gaze!"),
      _INTL("{1} is looking around absentmindedly."),
      _INTL("{1} yawned very loudly!"),
      _INTL("{1} is relaxing comfortably."),
      _INTL("{1} is focusing its attention on {2}."),
      _INTL("{1} is staring intently at nothing."),
      _INTL("{1} is concentrating."),
      _INTL("{1} faced {2} and nodded."),
      _INTL("{1} is looking at {2}'s footprints."),
      _INTL("{1} seems to want to play and is gazing at {2} expectedly."),
      _INTL("{1} seems to be thinking deeply about something."),
      _INTL("{1} isn't paying attention to {2}...Seems it's thinking about something else."),
      _INTL("{1} seems to be feeling serious."),
      _INTL("{1} seems disinterested."),
      _INTL("{1}'s mind seems to be elsewhere."),
      _INTL("{1} seems to be observing the surroundings instead of watching {2}."),
      _INTL("{1} looks a bit bored."),
      _INTL("{1} has an intense look on its face."),
      _INTL("{1} is staring off into the distance."),
      _INTL("{1} seems to be carefully examining {2}'s face."),
      _INTL("{1} seems to be trying to communicate with its eye(s)."),
      _INTL("...{1} seems to have sneezed!"),
      _INTL("...{1} noticed that {2}'s shoes are a bit dirty."),
      _INTL("Seems {1} ate something strange, it's making an odd face... "),
      _INTL("{1} seems to be smelling something good."),
      _INTL("{1} noticed that {2}' Bag has a little dirt on it..."),
      _INTL("...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... {1} silently nodded!")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when  1, 5, 7, 20, 21
      pbMoveRoute($game_player,[PBMoveRoute::Wait,35])
      pbMoveRoute(event,  [
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnDown
      ])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Happy animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 3
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Happy,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} began poking {2}."),
      _INTL("{1} looks very happy."),
      _INTL("{1} happily cuddled up to {2}."),
      _INTL("{1} is so happy that it can't stand still."),
      _INTL("{1} looks like it wants to lead!"),
      _INTL("{1} is coming along happily."),
      _INTL("{1} seems to be feeling great about walking with {2}!"),
      _INTL("{1} is glowing with health."),
      _INTL("{1} looks very happy."),
      _INTL("{1} put in extra effort just for {2}!"),
      _INTL("{1} is smelling the scents of the surrounding air."),
      _INTL("{1} is jumping with joy!"),
      _INTL("{1} is still feeling great!"),
      _INTL("{1} stretched out its body and is relaxing."),
      _INTL("{1} is doing its best to keep up with {2}."),
      _INTL("{1} is happily cuddling up to {2}!"),
      _INTL("{1} is full of energy!"),
      _INTL("{1} is so happy that it can't stand still!"),
      _INTL("{1} is wandering around and listening to the different sounds."),
      _INTL("{1} gives {2} a happy look and a smile."),
      _INTL("{1} started breathing roughly through its nose in excitement!"),
      _INTL("{1} is trembling with eagerness!"),
      _INTL("{1} is so happy, it started rolling around."),
      _INTL("{1} looks thrilled at getting attention from {2}."),
      _INTL("{1} seems very pleased that {2} is noticing it!"),
      _INTL("{1} started wriggling its entire body with excitement!"),
      _INTL("It seems like {1} can barely keep itself from hugging {2}!"),
      _INTL("{1} is keeping close to {2}'s feet.")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 3
      pbMoveRoute($game_player,[PBMoveRoute::Wait,45])
      pbMoveRoute(event,  [
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,
        PBMoveRoute::Wait,4,
        PBMoveRoute::Jump,0,0,
        PBMoveRoute::Wait,10,
        PBMoveRoute::Jump,0,0
      ])
    when 11, 16, 17, 24
      pbMoveRoute($game_player,[PBMoveRoute::Wait,40])
      pbMoveRoute(event,  [
        PBMoveRoute::Jump,0,0,
        PBMoveRoute::Wait,10,
        PBMoveRoute::Jump,0,0,
        PBMoveRoute::Wait,10,
        PBMoveRoute::Jump,0,0
      ])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with the Heart animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 4
    $scene.spriteset.addUserAnimation(FollowerSettings::Emo_Love,event.x,event.y)
    pbWait(72)
    messages = [
      _INTL("{1} suddenly started walking closer to {2}."),
      _INTL("Woah! {1} suddenly hugged {2}."),
      _INTL("{1} is rubbing up against {2}."),
      _INTL("{1} is keeping close to {2}."),
      _INTL("{1} blushed."),
      _INTL("{1} loves spending time with {2}!"),
      _INTL("{1} is suddenly playful!"),
      _INTL("{1} is rubbing against {2}'s legs!"),
      _INTL("{1} is regarding {2} with adoration!"),
      _INTL("{1} seems to want some affection from {2}."),
      _INTL("{1} seems to want some attention from {2}."),
      _INTL("{1} seems happy travelling with {2}."),
      _INTL("{1} seems to be feeling affectionate towards {2}."),
      _INTL("{1} is looking at {2} with loving eyes."),
      _INTL("{1} looks like it wants a treat from {2}."),
      _INTL("{1} looks like it wants {2} to pet it!"),
      _INTL("{1} is rubbing itself against {2} affectionately."),
      _INTL("{1} bumps its head gently against {2}'s hand."),
      _INTL("{1} rolls over and looks at {2} expectantly."),
      _INTL("{1} is looking at {2} with trusting eyes."),
      _INTL("{1} seems to be begging {2} for some affection!"),
      _INTL("{1} mimicked {2}!")
    ]
    value = rand(messages.length)
    case value
    when 1, 6,
      pbMoveRoute($game_player,[PBMoveRoute::Wait,10])
      pbMoveRoute(event, [PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}

# All dialogues with no animation
Events.OnTalkToFollower += proc {|pkmn,event,random_val|
  if random_val == 5
    messages = [
      _INTL("{1} spun around in a circle!"),
      _INTL("{1} let out a battle cry."),
      _INTL("{1} is on the lookout!"),
      _INTL("{1} is standing patiently."),
      _INTL("{1} is looking around restlessly."),
      _INTL("{1} is wandering around."),
      _INTL("{1} yawned loudly!"),
      _INTL("{1} is steadily poking at the ground around {2}'s feet."),
      _INTL("{1} is looking at {2} and smiling."),
      _INTL("{1} is staring intently into the distance."),
      _INTL("{1} is keeping up with {2}."),
      _INTL("{1} looks pleased with itself."),
      _INTL("{1} is still going strong!"),
      _INTL("{1} is walking in sync with {2}."),
      _INTL("{1} started spinning around in circles."),
      _INTL("{1} looks at {2} with anticipation."),
      _INTL("{1} fell down and looks a little embarrassed."),
      _INTL("{1} is waiting to see what {2} will do."),
      _INTL("{1} is calmly watching {2}."),
      _INTL("{1} is looking to {2} for some kind of cue."),
      _INTL("{1} is staying in place, waiting for {2} to make a move."),
      _INTL("{1} obediently sat down at {2}'s feet."),
      _INTL("{1} jumped in surprise!"),
      _INTL("{1} jumped a little!")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 0
      pbMoveRoute($game_player,[PBMoveRoute::Wait,15])
      pbMoveRoute(event,  [
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown
      ])
    when 2,4
      pbMoveRoute($game_player,[PBMoveRoute::Wait,35])
      pbMoveRoute(event,  [
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,10,
        PBMoveRoute::TurnDown
      ])
    when 14
      pbMoveRoute($game_player,[PBMoveRoute::Wait,50])
      pbMoveRoute(event,  [
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnRight,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnUp,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnLeft,
        PBMoveRoute::Wait,4,
        PBMoveRoute::TurnDown
      ])
    when 22, 23
      pbMoveRoute($game_player,[PBMoveRoute::Wait,10])
      pbMoveRoute(event,[PBMoveRoute::Jump,0,0])
    end
    pbMessage(_INTL(messages[value],pkmn.name,$Trainer.name))
    next true
  end
}
