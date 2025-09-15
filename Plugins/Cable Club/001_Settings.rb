module CableClub
  # Do not change
  PUBLIC_HOST = "34.61.122.15"
  LOCAL_HOST = "127.0.0.1"

  # Change if testing locally or connecting to 3rd party server
  HOST = PUBLIC_HOST
  PORT = 9999
  
  FOLDER_FOR_BATTLE_PRESETS = "LocalPresets"
  
  ONLINE_WIN_SPEECHES_LIST = [
    _INTL("I won!"),
    _INTL("It's all thanks to my team."),
    _INTL("We secured the victory!"),
    _INTL("This battle was fun, wasn't it?"),
    _INTL("All according to plan."),
    _INTL("Well fought, but it looks like I take this one."),
    _INTL("Seems I bested a formidable opponent. Again."),
    _INTL("Your Pokémon fought hard... but not as hard as mine."),
    _INTL("Looks like it's a win for me."),
    _INTL("Well played.")
  ]
  ONLINE_LOSE_SPEECHES_LIST = [
    _INTL("I lost..."),
    _INTL("I was confident in my team too."),
    _INTL("That was the one thing I wanted to avoid."),
    _INTL("This battle was fun, wasn't it?"),
    _INTL("That wasn't part of the plan..."),
    _INTL("Well that's a downer..."),
    _INTL("You truly are a strong opponent."),
    _INTL("Seems like my Pokémon weren't enough to defeat you."),
    _INTL("A loss... I've still got to get used to do that."),
    _INTL("Well played..." )
  ]
  
  ENABLE_RECORD_MIXER = false
  # If true, Sketch fails when used.
  # If false, Sketch is undone after battle
  DISABLE_SKETCH_ONLINE = true
end