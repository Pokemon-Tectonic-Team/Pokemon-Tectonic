DebugMenuCommands.register("addpokemon", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Add Pokémon"),
    "description" => _INTL("Give yourself a Pokémon of a chosen species/level. Goes to PC if party is full."),
    "effect"      => proc {
      species = pbChooseSpeciesList
      if species
        params = ChooseNumberParams.new
        params.setRange(1, GameData::GrowthRate.max_level)
        params.setInitialValue(5)
        params.setCancelValue(0)
        level = pbMessageChooseNumber(_INTL("Set the Pokémon's level."), params)
        pbAddPokemon(species, level) if level > 0
      end
    }
  })
  
  DebugMenuCommands.register("copyparty", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Copy Trainer Party"),
    "description" => _INTL("Give yourself the same party as a given trainer."),
    "effect"      => proc {
        trainerdata = pbListScreen(_INTL("SINGLE TRAINER"), TrainerBattleLister.new(0, false))
        if trainerdata
            trainer = pbLoadTrainer(*trainerdata)
            $Trainer.party = trainer.party.clone
            pbMessage(_INTL("Copied the party of {1}.", trainer.full_name))
        end
        next false
    }
  })
  
  DebugMenuCommands.register("healparty", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Heal Party"),
    "description" => _INTL("Fully heal the HP/status/PP of all Pokémon in the party."),
    "effect"      => proc {
      $Trainer.party.each { |pkmn| pkmn.heal }
      pbMessage(_INTL("Your Pokémon were fully healed."))
    }
  })

  DebugMenuCommands.register("deleteteam", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Delete Team"),
    "description" => _INTL("Delete the entirety of the player's team."),
    "effect"      => proc {
      $Trainer.party = []
      pbMessage(_INTL("Deleted your entire team."))
    }
  })
  
  DebugMenuCommands.register("quickhatch", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Quick Hatch"),
    "description" => _INTL("Make all eggs in the party require just one more step to hatch."),
    "effect"      => proc {
      $Trainer.party.each { |pkmn| pkmn.steps_to_hatch = 1 if pkmn.egg? }
      pbMessage(_INTL("All eggs in your party now require one step to hatch."))
    }
  })
  
  DebugMenuCommands.register("fillboxes", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Fill Storage Boxes"),
    "description" => _INTL("Add one Pokémon of each species (at Level 50) to storage."),
    "effect"      => proc {
      added = 0
      box_qty = $PokemonStorage.maxPokemon(0)
      completed = true
      GameData::Species.each do |species_data|
        sp = species_data.species
        f = species_data.form
        # Record each form of each species as seen and owned
        if f == 0
          if [:AlwaysMale, :AlwaysFemale, :Genderless].include?(species_data.gender_ratio)
            g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
            $Trainer.pokedex.register(sp, g, f, false)
          else   # Both male and female
            $Trainer.pokedex.register(sp, 0, f, false)
            $Trainer.pokedex.register(sp, 1, f, false)
          end
          $Trainer.pokedex.set_owned(sp, false)
        elsif species_data.real_form_name && !species_data.real_form_name.empty?
          g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
          $Trainer.pokedex.register(sp, g, f, false)
        end
        # Add Pokémon (if form 0, i.e. one of each species)
        next if f != 0
        if added >= Settings::NUM_STORAGE_BOXES * box_qty
          completed = false
          next
        end
        added += 1
        $PokemonStorage[(added - 1) / box_qty, (added - 1) % box_qty] = Pokemon.new(sp, 50)
      end
      $Trainer.pokedex.refresh_accessible_dexes
      pbMessage(_INTL("Storage boxes were filled with one Pokémon of each species."))
      if !completed
        pbMessage(_INTL("Note: The number of storage spaces ({1} boxes of {2}) is less than the number of species.",
           Settings::NUM_STORAGE_BOXES, box_qty))
      end
    }
  })
  
  DebugMenuCommands.register("clearboxes", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Clear Storage Boxes"),
    "description" => _INTL("Remove all Pokémon in storage."),
    "effect"      => proc {
      for i in 0...$PokemonStorage.maxBoxes
        for j in 0...$PokemonStorage.maxPokemon(i)
          $PokemonStorage[i, j] = nil
        end
      end
      pbMessage(_INTL("The storage boxes were cleared."))
    }
  })
  
  DebugMenuCommands.register("openstorage", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Access Pokémon Storage"),
    "description" => _INTL("Opens the Pokémon storage boxes in Organize Boxes mode."),
    "effect"      => proc {
      pbFadeOutIn {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
    }
  })

  DebugMenuCommands.register("dumpboxes", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Dump Storage Boxes to Text"),
    "description" => _INTL("Create a text file listing all Pokémon in storage."),
    "effect"      => proc {
      text = "name,dex,nick,box,type1,type2,ability,move1,move2,move3,move4\r\n"
      for i in 0...$PokemonStorage.maxBoxes
        for j in 0...$PokemonStorage.maxPokemon(i)
          mon = $PokemonStorage[i, j]
          next if mon.nil?
          spec_id = mon.species
          spec = GameData::Species.get(spec_id)
          moves = mon.moves
          move1 = moves[0].id
          move2 = moves.length > 1 ? moves[1].id : nil
          move3 = moves.length > 2 ? moves[2].id : nil
          move4 = moves.length > 3 ? moves[3].id : nil
          # mon name in quotes because nickname could have comma, escape for csv spec
          text += "#{spec.id},#{spec.id_number},\"#{mon.name}\",#{j+1},#{spec.type1},#{spec.type2},#{mon.ability_id},#{move1},#{move2},#{move3},#{move4}\r\n"
        end
      end
      filename = "Analysis/boxes_#{$Trainer.name}.csv"
      File.open(filename,"wb") { |file|
        file.write(text)
      }
      pbMessage(_INTL("Pokémon in storage written to {1}",filename))
    }
  })

  DebugMenuCommands.register("exportcode", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Export Current Team to Code"),
    "description" => _INTL("Create a shareable team code for the current party."),
    "effect"      => proc {
      load_team_code()
    }
  })

  DebugMenuCommands.register("importcode", {
    "parent"      => "pokemonmenu",
    "name"        => _INTL("Import Team Code from File"),
    "description" => _INTL("Load a tectonic-tools team code from Analysis/teamcode.txt into your current party."),
    "effect"      => proc {
      read_team_code()
    }
  })