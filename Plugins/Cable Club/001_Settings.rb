module CableClub
  # Do not change
  PUBLIC_HOST = "34.61.122.15"
  LOCAL_HOST = "127.0.0.1"

  # Change if testing locally or connecting to 3rd party server
  HOST = PUBLIC_HOST
  PORT = 9999
  
  FOLDER_FOR_BATTLE_PRESETS = "OnlinePresets"
  
  ONLINE_TRAINER_TYPE_LIST = [
    :POKEMONTRAINER_Androgynous,:POKEMONTRAINER_Feminine,:POKEMONTRAINER_Masculine,
    :AROMALADY,:AROMALADY2,:AROMALADY3,
    :ARTIST,:ARTIST2,:ARTIST3,:ARTIST4,
    :BACKPACKER_F,:BACKPACKER_M
    # etc etc... not important to fill out right now
  ]
  
  ONLINE_WIN_SPEECHES_LIST = [
    _INTL("I won!"),
    _INTL("It's all thanks to my team."),
    _INTL("We secured the victory!"),
    _INTL("This battle was fun, wasn't it?")
  ]
  ONLINE_LOSE_SPEECHES_LIST = [
    _INTL("I lost..."),
    _INTL("I was confident in my team too."),
    _INTL("That was the one thing I wanted to avoid."),
    _INTL("This battle was fun, wasn't it?")
  ]
  
  ENABLE_RECORD_MIXER = false
  # If true, Sketch fails when used.
  # If false, Sketch is undone after battle
  DISABLE_SKETCH_ONLINE = true
end