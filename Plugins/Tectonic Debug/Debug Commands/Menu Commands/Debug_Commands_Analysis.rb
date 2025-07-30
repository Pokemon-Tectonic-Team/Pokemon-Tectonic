if $DEBUG
    if !safeIsDirectory?("Analysis")
		Dir.mkdir("Analysis") rescue nil
	end
end

DebugMenuCommands.register("findtextinevents", {
    "parent"      => "analysis",
    "name"        => _INTL("Find Text In Events"),
    "description" => _INTL("Find events which have a peice of text in the params of their command list."),
    "effect"      => proc { |sprites, viewport|
        textEntered = pbEnterText("Enter text...", 0, 32)

        mapData = Compiler::MapData.new
        for id in mapData.mapinfos.keys.sort
            map = mapData.getMap(id)
            next if !map || !mapData.mapinfos[id]
            mapName = mapData.mapinfos[id].name
            for key in map.events.keys
                find_text_in_event(id,mapName,map.events[key],textEntered)
            end
        end

        pbMessage(_INTL("Results printed to console."))
    }}
)

def find_text_in_event(map_id,map_name,event,text_entered)
    return if !event || event.pages.length==0
    event.pages.each do |page|
        page.list.each do |eventCommand|
            eventCommand.parameters.each do |parameter|
                next unless parameter.is_a?(String)
                match = parameter.downcase.match(/#{text_entered.downcase}/)
                if match
                    eventName = event.name.gsub(",","")
                    echoln "Event \"#{eventName}\" (#{event.id}) on map #{map_name} (#{map_id})"
                    echoln "\"#{parameter}\"\r\n"
                end
            end
        end
    end
end

DebugMenuCommands.register("replacetextinevents", {
    "parent"      => "analysis",
    "name"        => _INTL("Replace Text In Events"),
    "description" => _INTL("Find events which have a peice of text in the params of their command list, and replace them with a new string."),
    "effect"      => proc { |sprites, viewport|
        textEntered = pbEnterText("Enter text to replace...", 0, 32)

        next if textEntered.blank?

        replacementText = pbEnterText("Enter new text...", 0, 32)

        next if replacementText.blank?

        replace_text_in_events(textEntered, replacementText)

        pbMessage(_INTL("Results printed to console."))
    }}
)

def replace_text_in_events(text_to_find,replacement_text)
    mapData = Compiler::MapData.new
    for id in mapData.mapinfos.keys.sort
        changed = false
        map = mapData.getMap(id)
        next if !map || !mapData.mapinfos[id]
        mapName = mapData.mapinfos[id].name
        for key in map.events.keys
            changed = true if replace_text_in_event(id,mapName,map.events[key],text_to_find,replacement_text)
        end
        if changed
            mapData.saveMap(id)
            mapData.saveTilesets
        end
    end
end

def replace_text_in_event(map_id,map_name,event,text_to_find,replacement_text)
    return false if !event || event.pages.length==0
    changed = false
    event.pages.each do |page|
        page.list.each do |eventCommand|
            changedParameters = {}
            eventCommand.parameters.each_with_index do |parameter, index|
                next unless parameter.is_a?(String)
                changedParameter = parameter.clone
                changedParameter.gsub!(text_to_find, replacement_text)
                changedParameter.gsub!(text_to_find.downcase, replacement_text)
                next if changedParameter == parameter
                eventName = event.name.gsub(",","")
                echoln "Event \"#{eventName}\" (#{event.id}) on map #{map_name} (#{map_id})"
                echoln "\"#{parameter}\"\r\n"
                changed = true

                changedParameters[index] = changedParameter
            end
            changedParameters.each do |key, value|
                eventCommand.parameters[key] = value
            end
        end
    end
    return changed
end

DebugMenuCommands.register("analyzeitemdistribution", {
    "parent"      => "analysis",
    "name"        => _INTL("Analyze item distribution"),
    "description" => _INTL("Find the locations of all item distributions."),
    "effect"      => proc { |sprites, viewport|
      mapData = Compiler::MapData.new
      allItemsGiven = []
      File.open("Analysis/item_distribution.txt","wb") { |file|
          for id in mapData.mapinfos.keys.sort
              map = mapData.getMap(id)
              next if !map || !mapData.mapinfos[id]
              mapName = mapData.mapinfos[id].name
              for key in map.events.keys
                  itemsGiven = analyze_items(id,mapName,map.events[key],file)
                  allItemsGiven.concat(itemsGiven)
              end
          end
  
          file.write("\r\nAll the items which have not a single distribution:\r\n")
          writeIndex = 0
          GameData::Item.each do |itemData|
              next if allItemsGiven.include?(itemData.id)
              next if itemData.cut
              str = itemData.id.to_s + (writeIndex % 6 == 5 ? "\r\n" : ", ")
              writeIndex += 1
              file.write(str) 
          end

          file.write("\r\nAll the machines, and which are distributed:\r\n")
          GameData::Item.each do |itemData|
            next unless itemData.is_machine?
            used = allItemsGiven.include?(itemData.id)
            str = "#{itemData.real_name},#{itemData.move},#{used}\r\n"
            file.write(str) 
        end
      }
  
      pbMessage(_INTL("Item distribution analysis written to Analysis/item_distribution.txt"))
    }}
  )
  
  def analyze_items(map_id,map_name,event,file)
      return [] if !event || event.pages.length==0
      itemsGiven = []
      event.pages.each do |page|
          page.list.each do |eventCommand|
              eventCommand.parameters.each do |parameter|
                  next unless parameter.is_a?(String)
                  match = parameter.match(/(?:(?:pbReceiveItem)|(?:defeatBoss)|(?:pbPickBerry)|(?:pbItemBall))\((:[A-Z0-9]+)(?:,([0-9]+))?(?:,?.+)?\)/)
                  if match
                      itemName = match[1][1..-1]
                      eventName = event.name.gsub(",","")
                      itemCount = match[2] ? match[2] : 1
                      string = "#{map_id},#{map_name},#{event.id},#{eventName},#{itemName},#{itemCount}\r\n"
                      
                      itemsGiven.push(itemName.to_sym)
                      
                      file.write(string)
                  end
              end
          end
      end
      return itemsGiven
  end
  

  DebugMenuCommands.register("analyzesmashables", {
    "parent"      => "analysis",
    "name"        => _INTL("Count smashable rocks"),
    "description" => _INTL("Find the locations of all smashable rocks."),
    "effect"      => proc { |sprites, viewport|
      mapData = Compiler::MapData.new
      echoln("Listing all smashable rocks")
      for id in mapData.mapinfos.keys.sort
          map = mapData.getMap(id)
          next if !map || !mapData.mapinfos[id]
          mapName = mapData.mapinfos[id].name
          for key in map.events.keys
              event = map.events[key]
              next if !event || event.pages.length==0
              event.pages.each do |page|
                  page.list.each do |eventCommand|
                      eventCommand.parameters.each do |parameter|
                          next unless parameter.is_a?(String)
                          match = parameter.match(/pbRockSmash/)
                          if match
                              eventName = event.name.gsub(",","")
                              string = "#{id},#{mapName},#{event.id},#{eventName}"
                              echoln(string)
                          end
                      end
                  end
              end
          end
      end
  
    }}
  )

  DebugMenuCommands.register("analyzecrossmapswitching", {
    "parent"      => "analysis",
    "name"        => _INTL("Analyze Cross-Map Switching"),
    "description" => _INTL("Find the events which affect events on other maps through pbSetSelfSwitch"),
    "effect"      => proc { |sprites, viewport|
      writeAllCodeInstances(/pbSetSelfSwitch\(([0-9]+),('[A,B,C,D,a,b,c,d]'),((?:true)|(?:false)),([0-9]+)\)/, "Analysis/switching_analysis.txt") { |event, page, eventcommand, parameter, match|
        "\tSetting switch #{match[1]} of event ID #{match[0]} on map ID #{match[3]} to #{match[2]}\r\n"
      }
    }}
  )
  
  def WACI(regex, fileName = "Analysis/code_instances.txt")
      writeAllCodeInstances(regex, fileName)
  end
  
  def writeAllCodeInstances(regex, fileName, &block)
      mapData = Compiler::MapData.new
      File.open(fileName,"wb") { |file|
          for id in mapData.mapinfos.keys.sort
              map = mapData.getMap(id)
              next if !map || !mapData.mapinfos[id]
              mapName = mapData.mapinfos[id].name
              for key in map.events.keys
                  describeCodeInstances(id,mapName,map.events[key],file,regex) { |event, page, eventcommand, parameter, match|
                    block.call(event, page, eventcommand, parameter, match) if block_given?
                  }
              end
          end
      }
  
      pbMessage(_INTL("Code instance analysis written to #{fileName}"))
  end
  
  def describeCodeInstances(map_id,map_name,event,file,regex,&block)
      return [] if !event || event.pages.length==0
      event.pages.each do |page|
          page.list.each do |eventCommand|
              eventCommand.parameters.each do |parameter|
                  next unless parameter.is_a?(String)
                  match = parameter.match(regex)
                  if match
                      eventName = event.name.gsub(",","")
  
                      string = "Map \"#{map_name}\" (#{map_id}), event \"#{eventName}\" (#{event.id})\r\n"
                      file.write(string)
                      file.write("\t#{parameter}\r\n")
                      file.write(block.call(event, page, eventCommand, parameter, match)) if block_given?
                                          
                      
                  end
              end
          end
      end
  end

  def RACI(regex, newText)
    replaceAllCodeInstances(regex, newText)
  end

def replaceAllCodeInstances(regex, newText)
    mapData = Compiler::MapData.new
    for id in mapData.mapinfos.keys.sort
        map = mapData.getMap(id)
        next if !map || !mapData.mapinfos[id]
        mapName = mapData.mapinfos[id].name
        changed = false
        for key in map.events.keys
            changed = true if replaceCodeInstances(id,mapName,map.events[key],regex,newText)
        end
        mapData.saveMap(id) if changed
    end
end

def replaceCodeInstances(map_id,map_name,event,regex,newText)
    return [] if !event || event.pages.length==0
    changed = false
    event.pages.each do |page|
        page.list.each do |eventCommand|
            eventCommand.parameters.map! { |parameter|
                next parameter unless parameter.is_a?(String)
                oldParam = parameter.clone
                newParam = parameter.gsub!(regex,newText)
                if newParam
                    eventName = event.name.gsub(",","")

                    echoln "Map #{map_name} (#{map_id}), event #{eventName} (#{event.id}):\r\n"
                    echoln("\tParameter #{oldParam} changed to #{newParam}")

                    changed = true
                    
                    next newParam
                end
                next parameter
            }
        end
    end
    return changed
end
  

  DebugMenuCommands.register("analyzedistribution", {
    "parent"      => "analysis",
    "name"        => _INTL("Analyze move distribution"),
    "description" => _INTL("See the total distribution of each move."),
    "effect"      => proc { |sprites, viewport|
      move_counts = {}
      GameData::Move.each do |move|
          next if move.primeval
          next if move.cut
          next if move.zmove
          move_counts[move.id] = [0,0,0,0]
          # 0 = Species learn by level up
          # 1 = Species learn by Tutor
          # 2 = Species learn as same-type
          # 3 = Species learn as off-type
      end
          
      GameData::Species.each do |species_data|
          # Don't check the species if its an alt form
          if species_data.form != 0
              formName = species_data.real_form_name
              formName.gsub!("%","") if formName
              next
          end
  
          # Don't check the species if its not a final evo
          next if species_data.get_evolutions.length > 0
  
          echoln("Checking the moves of #{species_data.real_name}")
          
          learnSet = []
          species_data.level_moves.each do |learnset_entry|
              move_id = learnset_entry[1]
              next if learnSet.include?(move_id)
              move_counts[move_id][0] += 1
              learnSet.push(move_id)
          end
          
          # Gather tutor moves
          tutorSet = []
          species_data.tutor_moves.each do |move_id|
              move_counts[move_id][1] += 1
              learnSet.push(move_id)
              tutorSet.push(move_id)
          end
  
          # Gather line moves
          firstSpecies = species_data
          while GameData::Species.get(firstSpecies.get_previous_species()) != firstSpecies do
              firstSpecies = GameData::Species.get(firstSpecies.get_previous_species())
          end
          
          firstSpecies.line_moves.each do |move_id| 
              next if tutorSet.include?(move_id)
              move_counts[move_id][1] += 1
              learnSet.push(move_id)
              tutorSet.push(move_id)
          end
          
          species_types = [species_data.type1,species_data.type2]
          
          learnSet.uniq!
          learnSet.compact!
          learnSet.each do |move_id|
              moveData = GameData::Move.get(move_id)
              if species_types.include?(moveData.type)
                  move_counts[move_id][2] += 1
              else
                  move_counts[move_id][3] += 1
              end
          end
      end
      
      move_counts = move_counts.sort_by{|move_id,counts| move_id}
      
      File.open("Analysis/move_distribution.txt","wb") { |file|
          file.write("Move, Type, Category, Level Up Count, Tutor Count, Same-Type Count, Off-type Count\r\n")
          move_counts.each do |move_id,counts|
              moveData = GameData::Move.get(move_id)
              categoryLabel = ["PHYSICAL","SPECIAL","STATUS"][moveData.category]
              file.write("#{move_id},#{moveData.type},#{categoryLabel},#{counts[0]},#{counts[1]},#{counts[2]},#{counts[3]}\r\n")
          end
      }
      pbMessage(_INTL("Move distribution analysis written to Analysis/move_distribution.txt"))
    }
  })

  DebugMenuCommands.register("countabilityuse", {
    "parent"      => "analysis",
    "name"        => _INTL("Count ability use"),
    "description" => _INTL("Count the number of uses of each ability by fully evolved base forms."),
    "effect"      => proc { |sprites, viewport|
        echoln("AbilityName,Non-legend Count,Legend Count")
        abilityCounts = getAbilityCounts()
        abilityCounts.each do |ability,count|
          echoln("#{ability},#{count[0]},#{count[1]}")
      end
  
      pbMessage(_INTL("Printed out ability counts to the console."))
    }
  })
  
  DebugMenuCommands.register("getsignatureabilities", {
    "parent"      => "analysis",
    "name"        => _INTL("List signature abilities"),
    "description" => _INTL("List each ability that is only used by one fully evolved base form."),
    "effect"      => proc { |sprites, viewport|
        echoln("Ability Name, Weilder")
        abilities = getSignatureAbilities()
      abilities = abilities.sort_by {|ability,weilder| GameData::Species.get(weilder).id_number}
      File.open("Analysis/signature_abilities.txt","wb") { |file|
          abilities.each do |ability,weilder|
              abilityLine = describeAbility(ability)
              abilityLine += "\r\n"
              file.write(abilityLine)
          end
      }
  
      pbMessage(_INTL("Printed out signature abilities to Analysis/signature_abilities.txt"))
    }
  })

  DebugMenuCommands.register("listcanonabilities", {
    "parent"      => "analysis",
    "name"        => _INTL("List canon abilities"),
    "description" => _INTL("List all abilities maintained from canon."),
    "effect"      => proc { |sprites, viewport|
      
      abilityDataSorted = []
      GameData::Ability.each do |abilityData|
          next if abilityData.cut
          next if abilityData.tectonic_new
          next if abilityData.primeval
          abilityDataSorted.push(abilityData)
      end
  
      abilityDataSorted.sort_by! { |data|
          data.real_name
      }
  
      File.open("Analysis/canon_abilities.txt","wb") { |file|
          abilityDataSorted.each do |abilityData|
              abilityLine = describeAbility(abilityData.id)
              abilityLine += "\r\n"
              file.write(abilityLine)
          end
      }
      pbMessage(_INTL("Canon ability information written to Analysis/canon_abilities.txt"))
    }
  })

  DebugMenuCommands.register("listnewabilities", {
    "parent"      => "analysis",
    "name"        => _INTL("List new abilities"),
    "description" => _INTL("List all new abilities added to the game."),
    "effect"      => proc { |sprites, viewport|
      
      abilityDataSorted = []
      GameData::Ability.each do |abilityData|
          next unless abilityData.tectonic_new
          abilityDataSorted.push(abilityData)
      end
  
      abilityDataSorted.sort_by! { |data|
          data.real_name
      }
  
      File.open("Analysis/new_abilities.txt","wb") { |file|
          abilityDataSorted.each do |abilityData|
              abilityLine = describeAbility(abilityData.id)
              abilityLine += "\r\n"
              file.write(abilityLine)
          end
      }
      pbMessage(_INTL("New ability information written to Analysis/new_abilities.txt"))
    }
  })
  
  def describeAbility(abilityID)
      abilityData = GameData::Ability.get(abilityID)
      abilityLine = "#{abilityData.real_name},\"#{abilityData.description}\""
      if abilityData.is_signature?
          weilderName = GameData::Species.get(abilityData.signature_of).real_name 
          abilityLine += "," + weilderName
      end
  
      return abilityLine
  end
  
  DebugMenuCommands.register("countmoveuse", {
    "parent"      => "analysis",
    "name"        => _INTL("Count move use"),
    "description" => _INTL("Count the number of uses of each move by fully evolved base forms."),
    "effect"      => proc { |sprites, viewport|
    echoln("MoveName,Non-legend Count,Legend Count")
        moveCounts = getMoveLearnableGroups()
      moveCounts.each do |move,groups|
          echoln("#{move},#{groups[0].length},#{groups[1].length}")
      end
  
      pbMessage(_INTL("Printed out move counts to the console."))
    }
  })
  
  DebugMenuCommands.register("getsignaturemoves", {
    "parent"      => "analysis",
    "name"        => _INTL("List signature moves"),
    "description" => _INTL("List each move that is only used by one fully evolved base form."),
    "effect"      => proc { |sprites, viewport|
        moves = getSignatureMoves()
      moves = moves.sort_by {|move,weilder| GameData::Species.get(weilder).id_number}
      File.open("Analysis/signature_moves.txt","wb") { |file|
          moves.each do |move,weilder|
              moveLine = describeMove(move)
              moveLine += "\r\n"
              file.write(moveLine)
          end
      }
  
      pbMessage(_INTL("Printed out signature moves to Analysis/signature_moves.txt."))
    }
  })
  
  def describeMove(move)
      moveData = GameData::Move.get(move)
      typeName = GameData::Type.get(moveData.type).real_name
      accuracyLabel = moveData.accuracy == 0 ? "-" : moveData.accuracy.to_s
      weilderName = ""
      if moveData.is_signature?
          weilderName = GameData::Species.get(moveData.signature_of).real_name
      end
      procChanceLabel = (moveData.effect_chance == 0 || moveData.effect_chance == 100) ? "-" : moveData.effect_chance.to_s
      moveLine = "#{moveData.real_name},#{weilderName},#{typeName},\"#{moveData.description}\",#{moveData.base_damage},#{moveData.categoryLabel},"
      moveLine += "#{accuracyLabel},#{moveData.total_pp},#{moveData.target},#{moveData.priorityLabel},#{procChanceLabel},#{moveData.tagLabel}"
      return moveLine
  end

  DebugMenuCommands.register("listcanonmoves", {
    "parent"      => "analysis",
    "name"        => _INTL("List canon moves"),
    "description" => _INTL("List all moves maintained from canon."),
    "effect"      => proc { |sprites, viewport|
      
      moveDataSorted = []
      GameData::Move.each do |moveData|
          next unless moveData.canon_move?
          moveDataSorted.push(moveData)
      end
  
      moveDataSorted.sort_by! { |data|
          GameData::Type.get(data.type).id_number * 10_000 + data.category * 1000 + data.base_damage
      }
  
      File.open("Analysis/canon_moves.txt","wb") { |file|
          moveDataSorted.each do |moveData|
              moveLine = describeMove(moveData.id)
              moveLine += "\r\n"
              file.write(moveLine)
          end
      }
      pbMessage(_INTL("Canon moves information written to Analysis/canon_moves.txt"))
    }
  })

  DebugMenuCommands.register("listnewmoves", {
    "parent"      => "analysis",
    "name"        => _INTL("List new moves"),
    "description" => _INTL("List all new moves added to the game."),
    "effect"      => proc { |sprites, viewport|
      
      moveDataSorted = []
      GameData::Move.each do |moveData|
          next unless moveData.tectonic_new
          moveDataSorted.push(moveData)
      end
  
      moveDataSorted.sort_by! { |data|
          GameData::Type.get(data.type).id_number * 10_000 + data.category * 1000 + data.base_damage
      }
  
      File.open("Analysis/new_moves.txt","wb") { |file|
          moveDataSorted.each do |moveData|
              moveLine = describeMove(moveData.id)
              moveLine += "\r\n"
              file.write(moveLine)
          end
      }
      pbMessage(_INTL("New moves information written to Analysis/new_moves.txt"))
    }
  })

  DebugMenuCommands.register("listcutmoves", {
    "parent"      => "analysis",
    "name"        => _INTL("List cut moves"),
    "description" => _INTL("List all moves cut from canon."),
    "effect"      => proc { |sprites, viewport|
      
      moveDataSorted = []
      GameData::Move.each do |moveData|
          next unless moveData.tectonic_new
          moveDataSorted.push(moveData)
      end
  
      moveDataSorted.sort_by! { |data|
          GameData::Type.get(data.type).id_number * 10_000 + data.category * 1000 + data.base_damage
      }
  
      File.open("Analysis/new_moves.txt","wb") { |file|
          moveDataSorted.each do |moveData|
              moveLine = moveData.real_name
              moveLine += "\r\n"
              file.write(moveLine)
          end
      }
      pbMessage(_INTL("Cut moves information written to Analysis/cut_moves.txt"))
    }
  })

  DebugMenuCommands.register("listprimevalmoves", {
    "parent"      => "analysis",
    "name"        => _INTL("List primeval moves"),
    "description" => _INTL("List all primeval moves."),
    "effect"      => proc { |sprites, viewport|
      
      moveDataSorted = []
      GameData::Move.each do |moveData|
          next unless moveData.primeval
          moveDataSorted.push(moveData)
      end
  
      moveDataSorted.sort_by! { |data|
          GameData::Type.get(data.type).id_number * 10_000 + data.category * 1000 + data.base_damage
      }
  
      File.open("Analysis/primeval_moves.txt","wb") { |file|
          moveDataSorted.each do |moveData|
              moveLine = describeMove(moveData.id)
              moveLine += "\r\n"
              file.write(moveLine)
          end
      }
      pbMessage(_INTL("Primeval moves information written to Analysis/primeval_moves.txt"))
    }
  })

  DebugMenuCommands.register("listhelditems", {
    "parent"      => "analysis",
    "name"        => _INTL("List held items"),
    "description" => _INTL("List all items that the player's Pokemon can hold for use in battle."),
    "effect"      => proc { |sprites, viewport|
      
      itemDataSorted = []
      GameData::Item.each do |itemData|
          next if itemData.super
          next if itemData.cut
          next unless itemData.pocket == 5
          itemDataSorted.push(itemData)
      end
  
      itemDataSorted.sort_by! { |data|
          data.real_name
      }
  
      File.open("Analysis/held_items.txt","wb") { |file|
        itemDataSorted.each do |itemData|
              itemLine = describeItem(itemData.id)
              itemLine += "\r\n"
              file.write(itemLine)
          end
      }
      pbMessage(_INTL("Held item information written to Analysis/held_items.txt"))
    }
  })

  DebugMenuCommands.register("listsuperitems", {
    "parent"      => "analysis",
    "name"        => _INTL("List super items"),
    "description" => _INTL("List all super items used in curses."),
    "effect"      => proc { |sprites, viewport|
      
        itemDataSorted = []
        GameData::Item.each do |itemData|
            next unless itemData.super
            next if itemData.cut
            next unless itemData.pocket == 5
            itemDataSorted.push(itemData)
        end

        itemDataSorted.sort_by! { |data|
            data.real_name
        }

        File.open("Analysis/held_items_super.txt","wb") { |file|
            itemDataSorted.each do |itemData|
                itemLine = describeItem(itemData.id)
                itemLine += "\r\n"
                file.write(itemLine)
            end
        }
        pbMessage(_INTL("Held item information written to Analysis/held_items_super.txt"))
    }
  })
  
  def describeItem(itemID)
      itemData = GameData::Item.get(itemID)
      itemLine = "#{itemData.real_name},\"#{itemData.description}\""
      return itemLine
  end

  DebugMenuCommands.register("counttribes", {
    "parent"      => "analysis",
    "name"        => _INTL("Count tribes"),
    "description" => _INTL("Count how many pokemon are in each tribe."),
    "effect"      => proc { |sprites, viewport|
      tribeCount = {}
      GameData::Tribe.each do |tribe|
          tribeCount[tribe.id] = 0
      end
  
      GameData::Species.each do |species|
          next if species.form != 0
          next if species.get_evolutions().length > 0
          species.tribes.each do |tribe|
              tribeCount[tribe] += 1
          end
      end
  
      echoln("Tribes count")
      tribeCount.each do |tribe, count|
          echoln("#{tribe},#{count}")
      end
  
      pbMessage(_INTL("Output the tribes count to the console."))
    }
  })

  DebugMenuCommands.register("checkbattlecontentlegality", {
    "parent"      => "analysis",
    "name"        => _INTL("Check Battle Legality"),
    "description" => _INTL("Check all trainer and avatar battles to find illegal elements."),
    "effect"      => proc { |sprites, viewport|
      GameData::Trainer.each do |trainerData|
          name = trainerData.real_name
          trainer = trainerData.to_trainer
          trainerInfo = trainerData.trainer_type.to_s + "," + trainerData.real_name + "," + trainerData.version.to_s
          trainer.party.each do |pokemon|
              checkTrainerPokemonLegality(pokemon,trainerInfo)
          end
      end
  
      GameData::Avatar.each do |avatarData|
          speciesData = GameData::Species.get(avatarData.id)
          if !speciesData.abilities.include?(avatarData.ability.to_sym)
              echoln("ERROR: #{avatarData.ability} not a legal ability on the avatar of #{speciesData.real_name}")
          end
      end
  
      pbMessage(_INTL("Any legality errors written into the console."))
    }}
  )
  
  def checkTrainerPokemonLegality(pkmn,trainerInfo)
      species_data = GameData::Species.get_species_form(pkmn.species,pkmn.form)
      if pkmn.species != :SMEARGLE
          pkmn.moves.each do |move|
              next unless move
              next if pkmn.species_data.learnable_moves.include?(move.id)
              echoln("ERROR: #{move.id} learned illegaly on #{pkmn.name} on #{trainerInfo}")
          end
      end
      
      # TO DO: check for illegal per evolution
      prevolutions = species_data.get_prevolutions()
      return if prevolutions.length == 0
      prevo_info =  prevolutions[0] # Assume only one possible prevo
      name = species_data.real_name
      name += "(#{species_data.real_form_name})" if species_data.form != 0
      if [:Level,:LevelDay,:LevelNight,:LevelMale,:LevelFemale,:LevelRain,:LevelDarkInParty].include?(prevo_info[1])
          if prevo_info[2] > pkmn.level
              echoln("ERROR: Level #{pkmn.level} is too low to be able to aquire a #{name} on #{trainerInfo}")
          end
      elsif [:Item,:ItemMale,:ItemFemale,:ItemDay,:ItemNight,:ItemHappiness].include?(prevo_info[1])
          if pkmn.level < 32
              echoln("WARNING: Level #{pkmn.level} may be too low to reasonably aquire a #{name} on #{trainerInfo}")
          end
      end
  end

DebugMenuCommands.register("earliestlevels", {
    "parent"      => "analysis",
    "name"        => _INTL("Analyze move availability"),
    "description" => _INTL("See the earliest available level of each move."),
    "effect"      => proc { |sprites, viewport|
        move_levels = {}
        GameData::Move.each do |move|
            next if move.primeval
            next if move.cut
            next if move.zmove
            move_levels[move.id] = [70, false, []]
        end

        GameData::Species.each do |species_data|
            # Don't check the species if its an alt form
            if species_data.form != 0
                formName = species_data.real_form_name
                formName.gsub!("%","") if formName
                next
            end

            echoln("Checking the moves of #{species_data.real_name}")
            species_data.level_moves.each do |learnset_entry|
                learn_level = learnset_entry[0]
                move_id = learnset_entry[1]
                is_evo_move = false
                # handle evolution moves
                if learn_level == 0 
                    is_evo_move = true # set evolution flag
                    species_data.evolutions.each do |evolutionEntry|
                        evoMethod = evolutionEntry[1]
                        param = evolutionEntry[2]
                        is_prevo = evolutionEntry[3]
                        next if !is_prevo # checking prevos for evolution methods into this mon
                        evoLevelThreshold = 0
                        case evoMethod
                            # All method based on leveling up to a certain level
                            when :Level, :LevelDay, :LevelNight, :LevelMale, :LevelFemale, :LevelRain,
                            :AttackGreater, :AtkDefEqual, :DefenseGreater, :LevelDarkInParty,
                            :Silcoon, :Cascoon, :Ninjask, :Shedinja, :Originize, :Ability0, :Ability1

                                evoLevelThreshold = param
                            # All methods based on holding a certain item or using a certain item on the pokemon
                            when :HoldItem, :HoldItemMale, :HoldItemFemale, :DayHoldItem, :NightHoldItem,
                            :Item, :ItemMale, :ItemFemale, :ItemDay, :ItemNight, :ItemHappiness

                                # Push this prevo if the evolution from it is gated by an item which is available by this point
                                evoLevelThreshold = Compiler::getEarliestLevelForItem(param)
                        end
                        learn_level = evoLevelThreshold
                    end
                end
                # if multiple pokemon learn at the lowest level, push to the list of learners
                if move_levels[move_id][0] == learn_level
                    move_levels[move_id][2].push(species_data.species)
                end
                if move_levels[move_id][0] > learn_level
                    move_levels[move_id][0] = learn_level
                    move_levels[move_id][1] = is_evo_move
                    move_levels[move_id][2] = [species_data.species]
                end
            end
        end

        File.open("Analysis/move_levels.txt","wb") { |file|
            file.write("Move,Level,Evolution,Learners\r\n")
            move_levels.each do |move_id,levels|
                level = levels[0]
                evo = levels[1]
                learners = levels[2].join(",")
                file.write("#{move_id},#{level},#{evo},#{learners}\r\n")
            end
        }
        pbMessage(_INTL("Move learn level analysis written to Analysis/move_levels.txt"))
    }
})