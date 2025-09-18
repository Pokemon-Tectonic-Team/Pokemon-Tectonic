module GameData
    class Trainer
      attr_reader :id
      attr_reader :id_number
      attr_reader :trainer_type
      attr_reader :trainer_type_label
      attr_reader :real_name
      attr_reader :version
      attr_reader :items
      attr_reader :real_lose_text
      attr_reader :pokemon
      attr_reader :policies
      attr_reader :flags
      attr_reader :extendsClass
      attr_reader :extendsName
      attr_reader :extendsVersion
      attr_reader :removedPokemon
      attr_reader :name_for_hashing
      attr_reader :monumentTrainer
  
      DATA = {}
      DATA_FILENAME = "trainers.dat"
  
      SCHEMA = {
        "Items"        		  => [:items,             "*e",   :Item],
        "LoseText"     		  => [:lose_text,         "s"],
        "Policies"	 		    => [:policies,		    "*e",   :Policy],
        "Flags"             => [:flags,             "*s"],
        "Pokemon"      		  => [:pokemon,           "ev",   :Species],   # Species, level
        "RemovePokemon"		  => [:removed_pokemon,   "ev",   :Species],   # Species, level
        "Form"         		  => [:form,              "u"],
        "Name"         		  => [:name,              "s"],
        "NameForHashing"    => [:name_for_hashing,  "s"],
        "TrainerTypeLabel"  => [:trainer_type_label,"e",    :TrainerType],
        "Moves"        		  => [:moves,             "*e",   :Move],
        "Ability"      		  => [:ability,           "s"],
        "AbilityIndex" 		  => [:ability_index,     "u"],
        "ExtraAbilities" 	  => [:extra_abilities,   "*s"],
        "Item"         		  => [:item,              "*e",   :Item],
        "ItemType"          => [:item_type,         "e",    :Type],
        "ExtraItems" 	      => [:extra_items,       "*e",   :Item],
        "Gender"       		  => [:gender,            "e", { "M" => 0, "m" => 0, "Male" => 0, "male" => 0, "0" => 0,
                                                      "F" => 1, "f" => 1, "Female" => 1, "female" => 1, "1" => 1 }],
        "Nature"       		  => [:nature,            "e",    :Nature],
        "EV"           		  => [:ev,                "uUUUUU"],
        "Happiness"   		  => [:happiness,         "u"],
        "Shiny"        		  => [:shininess,         "b"],
        "Shadow"       		  => [:shadowness,        "b"],
        "Ball"         		  => [:poke_ball,         "s"],
        "ExtendsVersion"  	=> [:extends_version,   "u"],
        "Extends"		        => [:extends,		    "esu",  :TrainerType],
        "Position"	 		    => [:assigned_position, "u"],
        "ExtraTypes"        => [:extra_types,       "*e",   :Type]
      }
  
      extend ClassMethods
      include InstanceMethods
  
      # @param tr_type [Symbol, String]
      # @param tr_name [String]
      # @param tr_version [Integer, nil]
      # @return [Boolean] whether the given other is defined as a self
      def self.exists?(tr_type, tr_name, tr_version = 0)
        validate tr_type => [Symbol, String]
        validate tr_name => [String]
        key = [tr_type.to_sym, tr_name, tr_version]
        return !self::DATA[key].nil?
      end
  
      # @param tr_type [Symbol, String]
      # @param tr_name [String]
      # @param tr_version [Integer, nil]
      # @return [self]
      def self.get(tr_type, tr_name, tr_version = 0)
        validate tr_type => [Symbol, String]
        validate tr_name => [String]
        key = [tr_type.to_sym, tr_name, tr_version]
        raise "Unknown trainer #{tr_type} #{tr_name} #{tr_version}." unless self::DATA.has_key?(key)
        return self::DATA[key]
      end
  
      # @param tr_type [Symbol, String]
      # @param tr_name [String]
      # @param tr_version [Integer, nil]
      # @return [self, nil]
      def self.try_get(tr_type, tr_name, tr_version = 0)
        validate tr_type => [Symbol, String]
        validate tr_name => [String]
        key = [tr_type.to_sym, tr_name, tr_version]
        return (self::DATA.has_key?(key)) ? self::DATA[key] : nil
      end

      @@monumentTrainers = []

      def self.getMonumentTrainers
        if @@monumentTrainers.empty?
          each do |trainerData|
            next unless trainerData.monumentTrainer
            @@monumentTrainers.push(trainerData)
          end
        end
        return @@monumentTrainers
      end

      def self.randomMonumentTrainer
        return getMonumentTrainers.sample
      end

      def initialize(hash)
        @id                     = hash[:id]
        @id_number              = hash[:id_number]
        @trainer_type           = hash[:trainer_type]
        @real_name              = hash[:name]               || "Unnamed"
        @name_for_hashing       = hash[:name_for_hashing]
        @trainer_type_label     = hash[:trainer_type_label]
        @version                = hash[:version]            || 0
        @items                  = hash[:items]              || []
        @real_lose_text         = hash[:lose_text]          || "..."
        @pokemon                = hash[:pokemon]            || []
        @pokemon.each do |pkmn|
            GameData::Stat.each_main do |s|
              pkmn[:ev][s.id] ||= 0 if pkmn[:ev]
            end
        end
        @removedPokemon 	    = hash[:removed_pokemon]    || []
        @policies		  	    = hash[:policies]		    || []
        @flags		  	        = hash[:flags]		        || []
        @extendsClass	  	    = hash[:extends_class]
        @extendsName	  	    = hash[:extends_name]
        @extendsVersion 	    = hash[:extends_version]    || -1
        @monumentTrainer        = hash[:monument_trainer]   || false
        @defined_in_extension   = hash[:defined_in_extension] || false

        @@monumentTrainers.push(self) if @monumentTrainer

        @pokemon.each do |partyEntry|
            next if partyEntry[:species] == :SMEARGLE
            trainerName = "#{@trainer_type} #{@real_name}"
            speciesData = GameData::Species.get_species_form(partyEntry[:species],partyEntry[:form] || 0)
            hasStatusMove = false
            partyEntry[:moves]&.each do |moveID|
                moveData = GameData::Move.get(moveID)
                unless moveData.learnable?
                  raise _INTL("Illegal move #{moveID} learnable by a party member of trainer #{trainerName}!")
                end

                unless speciesData.learnable_moves.include?(moveID)
                  raise _INTL("Trainer #{trainerName}'s #{speciesData.species} can't learn the move #{moveID} assigned to it!")
                end

                hasStatusMove = true if moveData.status?
            end

            statusBlockItem = false
            partyEntry[:item]&.each do |itemID|
                itemData = GameData::Item.get(itemID)
                next if itemData.legal?(true)
                statusBlockItem = true if itemData.is_no_status_use?
                raise _INTL("Illegal item #{itemID} assigned to a party member of trainer #{trainerName}!")
            end

            if hasStatusMove && statusBlockItem
              echoln(_INTL("WARNING: Trainer #{trainerName}'s #{speciesData.species} knows a status move despite holding a status move blocking item."))
            end
        end
      end
  
      # @return [String] the translated name of this trainer
      def name
        return pbGetMessageFromHash(MessageTypes::TrainerNames, @real_name)
      end
  
      # @return [String] the translated in-battle lose message of this trainer
      def lose_text
        return pbGetMessageFromHash(MessageTypes::TrainerLoseText, @real_lose_text)
      end
  
      def getParentTrainer(justData = false)
        if @extendsVersion > -1
            parentTrainerData = GameData::Trainer.get(@extendsClass || @trainer_type, @extendsName || @real_name, @extendsVersion)
            return parentTrainerData if justData
            parentTrainer = pbLoadTrainer(parentTrainerData.trainer_type,parentTrainerData.real_name,parentTrainerData.version)
            return parentTrainer
        end
        return nil
      end

      # Creates a battle-ready version of a trainer's data.
      # @return [Array] all information about a trainer in a usable form
      def to_trainer	
        # Determine trainer's name
        tr_name = self.name
        Settings::RIVAL_NAMES.each do |rival|
            next if rival[0] != @trainer_type || !$game_variables[rival[1]].is_a?(String)
            tr_name = $game_variables[rival[1]]
            break
        end
        
        # Create trainer object
        trainer = NPCTrainer.new(tr_name, @trainer_type, @name_for_hashing)
        trainer.id                  = $Trainer.make_foreign_ID
        trainer.items               = @items.clone
        trainer.lose_text           = @lose_text
        trainer.policies            = @policies.clone
        trainer.policies.concat(GameData::TrainerType.get(@trainer_type).policies)
        trainer.flags               = @flags.clone
        trainer.trainer_type_label  = @trainer_type_label

        parentTrainer = getParentTrainer
        if parentTrainer
            trainer.items.concat(parentTrainer.items.clone)
            trainer.lose_text = parentTrainer.lose_text if @lose_text.nil? || @lose_text == "..."
            trainer.policies.concat(parentTrainer.policies.clone)
            trainer.flags.concat(parentTrainer.flags.clone)
        end

        trainer.policies.uniq!

        # Add pokemon from a parent trainer entry's party, if inheriting
        if parentTrainer
            parentTrainer.party.each do |parentPartyMember|
                # Determine if this pokemon was marked for removal in the child trainer entry
                hasRemoveMatch = false
                @removedPokemon.each do |removed_member|
                    removedSpecies = GameData::Species.get(removed_member[:species]).species
                    next if parentPartyMember.species != removedSpecies
                    removedLevel = removed_member[:level]
                    removedName = removed_member[:name] || removedSpecies.name
                    if parentPartyMember.level == removedLevel
                        hasRemoveMatch = true
                        break
                    elsif removedName == parentPartyMember.name
                        hasRemoveMatch = true
                        break
                    end
                end

                next if hasRemoveMatch
                
                clonedMember = parentPartyMember.clone
                trainer.party.push(clonedMember)
            end
        end

        # Create each Pokémon owned by the trainer
        @pokemon.each do |pkmn_data|
            species = GameData::Species.get(pkmn_data[:species]).species
            level = pkmn_data[:level]

            nickname = nil
            nickname = pkmn_data[:name] if pkmn_data[:name] && !pkmn_data[:name].empty?

            pkmn = nil
            if parentTrainer
                trainer.party.each do |existingPokemon|
                    next if existingPokemon.species != species
                    if existingPokemon.level == level
                        pkmn = existingPokemon
                        break
                    elsif !nickname.nil? && nickname == existingPokemon.name
                        pkmn = existingPokemon
                        pkmn.level = level
                        break
                    end
                end
            end

            # No base pkmn to inherit from found
            if pkmn.nil?
                pkmn = Pokemon.new(species, level, trainer, false)

                if pkmn_data[:assigned_position]
                    trainer.party.insert(pkmn_data[:assigned_position],pkmn)
                else
                    firstEmptySpot = false
                    trainer.party.each_with_index do |partySlot,index|
                        next unless partySlot.nil?
                        firstEmptySpot = index
                    end
                    if firstEmptySpot
                        trainer.party[firstEmptySpot] = pkmn
                    else
                        trainer.party.push(pkmn)
                    end
                end
            end

            # Set level from policy
            if trainer.policies.include?(:MATCH_LEVEL_CAP)
              pkmn.level = getLevelCap
            end

            # Set Pokémon's properties if defined
            pkmn.name = nickname if !nickname.nil?

            if !pkmn_data[:form].nil?
                pkmn.forced_form = pkmn_data[:form] if MultipleForms.hasFunction?(species, "getForm")
                pkmn.form_simple = pkmn_data[:form]
            end

            if !pkmn_data[:ability_index].nil?
              pkmn.ability_index = pkmn_data[:ability_index]
            elsif !pkmn_data[:ability].nil?
              pkmn.ability = pkmn_data[:ability]
            end

            if pkmn_data[:extra_abilities]
              pkmn_data[:extra_abilities].each do |extraAbilityID|
                pkmn.addExtraAbility(extraAbilityID)
              end
            end

            if pkmn_data[:extra_types]
              pkmn_data[:extra_types].each do |extraTypeID|
                pkmn.addExtraType(extraTypeID)
              end
            end

            itemInfo = pkmn_data[:item]
            if !itemInfo.nil?
              if itemInfo.is_a?(Array)
                unless itemInfo.empty?
                  if pkmn.legalItems?(itemInfo,true)
                    pkmn.setItems(itemInfo)
                  else
                    echoln("Trainer pokemon #{pkmn.name} is not allowed to hold the assigned item set of #{itemInfo.to_s}!")
                  end
                end
              else
                pkmn.setItems([itemInfo])
              end
            end

            if pkmn_data[:extra_items]
              pkmn_data[:extra_items].each do |extraItemID|
                pkmn.giveItem(extraItemID)
              end
            end

            pkmn.itemTypeChosen = pkmn_data[:item_type] if pkmn_data[:item_type]

            if pkmn_data[:moves] && pkmn_data[:moves].length > 0
                pkmn.forget_all_moves
                pkmn_data[:moves].each { |move| pkmn.learn_move(move) }
            end

            if pkmn.moves.length == 0
                pkmn.reset_moves([pkmn.level,50].min,true)
            end
            
            pkmn.gender = pkmn_data[:gender] unless pkmn_data[:gender].nil?
            
            unless pkmn_data[:shininess].nil?
              pkmn.shiny = (pkmn_data[:shininess]) ? true : false
            end

            pkmn.personalID

            pkmn.nature = 0

            if pkmn_data[:ev]
              GameData::Stat.each_main do |s|
                pkmn.ev[s.id] = pkmn_data[:ev][s.id]
              end
            end

            pkmn.happiness = pkmn_data[:happiness] if !pkmn_data[:happiness].nil?

            pkmn.poke_ball = pkmn_data[:poke_ball] if !pkmn_data[:poke_ball].nil?

            pkmn.calc_stats
        end

        if parentTrainer && trainer.party.length > Settings::MAX_PARTY_SIZE
            echoln _INTL("WARNING: When trying to contruct trainer #{@id.to_s} as an extension of trainer #{parentTrainer.id.to_s}, the resultant party is larger than the maximum party size!")
        end

        trainer.party.compact!

        return trainer
      end
    end
end

module Compiler
    module_function

  #=============================================================================
  # Compile individual trainer data
  #=============================================================================
  def compile_trainers
    schema = GameData::Trainer::SCHEMA
    max_level = GameData::GrowthRate.max_level
    trainer_names             = []
    trainer_lose_texts        = []
    trainer_hash              = nil
    trainer_id                = -1
    current_pkmn              = nil
    isExtending               = false
    baseFiles = ["PBS/trainers.txt", "PBS/trainers_monument.txt"]
    trainerTextFiles = []
    trainerTextFiles.concat(baseFiles)
    trainerExtensions = Compiler.get_extensions("trainers")
    trainerTextFiles.concat(trainerExtensions)
    trainerTextFiles.each do |path|
      isMonument = path == "PBS/trainers_monument.txt"
      baseFile = baseFiles.include?(path)
      # Read each line of trainers.txt at a time and compile it as a trainer property
      pbCompilerEachPreppedLine(path) { |line, line_no|
        if line[/^\s*\[\s*(.+)\s*\]\s*$/]
          # New section [trainer_type, name] or [trainer_type, name, version]
          if trainer_hash
            if !current_pkmn && !isExtending
              raise _INTL("Started new trainer while previous trainer has no Pokémon.\r\n{1}", FileLineData.linereport)
            end
            # Add trainer's data to records
            trainer_hash[:id] = [trainer_hash[:trainer_type], trainer_hash[:name], trainer_hash[:version]]
            GameData::Trainer.register(trainer_hash)
          end
          trainer_id += 1
          line_data = pbGetCsvRecord($~[1], line_no, [0, "esU", :TrainerType])
          # Construct trainer hash
          trainer_hash = {
            :id_number          => trainer_id,
            :trainer_type       => line_data[0],
            :name               => line_data[1],
            :version            => line_data[2] || 0,
            :pokemon            => [],
            :policies		    => [],
            :flags		        => [],
            :extends            => -1,
            :removed_pokemon    => [],
            :monument_trainer   => isMonument,
            :defined_in_extension   => !baseFile,
          }
          isExtending = false
          current_pkmn = nil
          trainer_names[trainer_id] = trainer_hash[:name]
        elsif line[/^\s*(\w+)\s*=\s*(.*)$/]
          # XXX=YYY lines
          if !trainer_hash
            raise _INTL("Expected a section at the beginning of the file.\r\n{1}", FileLineData.linereport)
          end
          property_name = $~[1]
          line_schema = schema[property_name]
          next if !line_schema
          property_value = pbGetCsvRecord($~[2], line_no, line_schema)
          # Error checking in XXX=YYY lines
          case property_name
          when "Items"
            property_value = [property_value] if !property_value.is_a?(Array)
            property_value.compact!
          when "Pokemon","RemovePokemon"
            if property_value[1] > max_level
              raise _INTL("Bad level: {1} (must be 1-{2}).\r\n{3}", property_value[1], max_level, FileLineData.linereport)
            end
          when "Name"
            if property_value.length > Pokemon::MAX_NAME_SIZE
              raise _INTL("Bad nickname: {1} (must be 1-{2} characters).\r\n{3}", property_value, Pokemon::MAX_NAME_SIZE, FileLineData.linereport)
            end
          when "Moves"
            property_value = [property_value] if !property_value.is_a?(Array)
            property_value.uniq!
            property_value.compact!
          when "Item"
            property_value = [property_value] if !property_value.is_a?(Array)
            property_value.uniq!
            property_value.compact!
          when "EV"
            property_value = [property_value] if !property_value.is_a?(Array)
            property_value.compact!
            property_value.each do |ev|
              next if ev <= Pokemon::EV_STAT_LIMIT
              raise _INTL("Bad EV: {1} (must be 0-{2}).\r\n{3}", ev, Pokemon::EV_STAT_LIMIT, FileLineData.linereport)
            end
            if COMBINE_ATTACKING_STATS
              atkIndex = GameData::Stat.get(:ATTACK).pbs_order
              spAtkIndex = GameData::Stat.get(:SPECIAL_ATTACK).pbs_order

              if property_value[atkIndex] != property_value[spAtkIndex]
                attackingStatsValue = [property_value[atkIndex],property_value[spAtkIndex]].max
                property_value[atkIndex] = attackingStatsValue
                property_value[spAtkIndex] = attackingStatsValue
              end
            end
            ev_total = 0
            GameData::Stat.each_main do |s|
              next if s.pbs_order < 0
              next if s == :SPECIAL_ATTACK && COMBINE_ATTACKING_STATS
              ev_total += (property_value[s.pbs_order] || property_value[0])
            end
            if ev_total > Pokemon::EV_LIMIT
              raise _INTL("Total EVs are greater than allowed ({1}).\r\n{2}", Pokemon::EV_LIMIT, FileLineData.linereport)
            end
            if ev_total < Pokemon::EV_LIMIT
              raise _INTL("Total EVs are less than required ({1}).\r\n{2}", Pokemon::EV_LIMIT, FileLineData.linereport)
            end
          when "Happiness"
            if property_value > 255
              raise _INTL("Bad happiness: {1} (must be 0-255).\r\n{2}", property_value, FileLineData.linereport)
            end
          when "Position"
            if property_value < 0 || property_value >= Settings::MAX_PARTY_SIZE
              raise _INTL("Bad party position: {1} (must be 0-{2}).\r\n{3}", property_value, Settings::MAX_PARTY_SIZE-1, FileLineData.linereport)
            end
          end
          # Record XXX=YYY setting
          case property_name
          when "Items", "LoseText","Policies","NameForHashing","Flags","TrainerTypeLabel"
            trainer_hash[line_schema[0]] = property_value
            trainer_lose_texts[trainer_id] = property_value if property_name == "LoseText"
          when "Extends"
            trainer_hash[:extends_class] = property_value[0]
            trainer_hash[:extends_name] = property_value[1]
            trainer_hash[:extends_version] = property_value[2]
            isExtending = true
          when "ExtendsVersion"
            trainer_hash[:extends_version] = property_value
            if trainer_hash[:extends_version] == trainer_hash[:version]
              raise _INTL("A trainer definition cannot extend itself: {1}", FileLineData.linereport)
            end
            isExtending = true
          when "Pokemon","RemovePokemon"
            current_pkmn = {
              :species => property_value[0],
              :level   => property_value[1],
            }
            if !isExtending
              # The default ability index for a given species of a given trainer should be chaotic, but not random
              current_pkmn[:ability_index] = (trainer_hash[:name] + current_pkmn[:species].to_s).hash % 2
            end
            trainer_hash[line_schema[0]].push(current_pkmn)
          else
            if !current_pkmn
              raise _INTL("Pokémon hasn't been defined yet!\r\n{1}", FileLineData.linereport)
            end
            case property_name
            when "Ability"
              if property_value[/^\d+$/]
                current_pkmn[:ability_index] = property_value.to_i
              elsif !GameData::Ability.exists?(property_value.to_sym)
                raise _INTL("Value {1} isn't a defined Ability.\r\n{2}", property_value, FileLineData.linereport)
              else
                current_pkmn[line_schema[0]] = property_value.to_sym
              end
            when "ExtraAbilities"
              extraAbilityArray = []
              property_value.each do |extraAbilityText|
                extraAbilitySymbol = extraAbilityText.to_sym
                if !GameData::Ability.exists?(extraAbilitySymbol)
                  raise _INTL("Value {1} isn't a defined Ability.\r\n{2}", extraAbilitySymbol, FileLineData.linereport)
                else
                  extraAbilityArray.push(extraAbilitySymbol)
                end
              end
              current_pkmn[line_schema[0]] = extraAbilityArray
            when "EV"
              value_hash = {}
              GameData::Stat.each_main do |s|
                next if s.pbs_order < 0
                value_hash[s.id] = property_value[s.pbs_order] || property_value[0]
              end
              current_pkmn[line_schema[0]] = value_hash
            when "Ball"
              if property_value[/^\d+$/]
                current_pkmn[line_schema[0]] = pbBallTypeToItem(property_value.to_i).id
              elsif !GameData::Item.exists?(property_value.to_sym) ||
                !GameData::Item.get(property_value.to_sym).is_poke_ball?
                raise _INTL("Value {1} isn't a defined Poké Ball.\r\n{2}", property_value, FileLineData.linereport)
              else
                current_pkmn[line_schema[0]] = property_value.to_sym
              end
            else
              current_pkmn[line_schema[0]] = property_value
            end
          end
        end
      }
      # Add last trainer's data to records
      if trainer_hash
        trainer_hash[:id] = [trainer_hash[:trainer_type], trainer_hash[:name], trainer_hash[:version]]
        GameData::Trainer.register(trainer_hash)
      end
    end
    # Save all data
    GameData::Trainer.save
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerNames, trainer_names)
    MessageTypes.setMessagesAsHash(MessageTypes::TrainerLoseText, trainer_lose_texts)
    hologramizeAllBattleSprites(false)
    Graphics.update
  end

  #=============================================================================
  # Save individual trainer data to PBS file
  #=============================================================================
  def write_trainers
    File.open("PBS/trainers.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      GameData::Trainer.each_base do |trainer|
        next if trainer.monumentTrainer
        write_trainer_to_file(trainer, f)
      end
    }
    File.open("PBS/trainers_monument.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      GameData::Trainer.each_base do |trainer|
        next unless trainer.monumentTrainer
        write_trainer_to_file(trainer, f)
      end
    }
    pbSetWindowText(nil)
    Graphics.update
  end

  def write_trainer_to_file(trainer, f)
    pbSetWindowText(_INTL("Writing trainer {1}...", trainer.id_number))
    Graphics.update if trainer.id_number % 50 == 0
    f.write("\#-------------------------------\r\n")
    if trainer.version > 0
      f.write(sprintf("[%s,%s,%d]\r\n", trainer.trainer_type, trainer.real_name, trainer.version))
    else
      f.write(sprintf("[%s,%s]\r\n", trainer.trainer_type, trainer.real_name))
    end
    parentTrainer = trainer.getParentTrainer(true)
    if trainer.extendsVersion >= 0
      if !trainer.extendsClass.nil? && !trainer.extendsName.nil?
        f.write(sprintf("Extends = %s,%s,%s\r\n", trainer.extendsClass.to_s, trainer.extendsName.to_s, trainer.extendsVersion.to_s))
      else
        f.write(sprintf("ExtendsVersion = %s\r\n", trainer.extendsVersion.to_s))
      end
    end
    if !trainer.name_for_hashing.nil?
      f.write(sprintf("NameForHashing = %s\r\n", trainer.name_for_hashing.to_s))
    end
    if !trainer.trainer_type_label.nil?
        f.write(sprintf("TrainerTypeLabel = %s\r\n", trainer.trainer_type_label.to_s))
    end
    if trainer.policies && trainer.policies.length > 0
      uniquePolicies = trainer.policies
      uniquePolicies -= parentTrainer.policies if parentTrainer
      f.write(sprintf("Policies = %s\r\n", uniquePolicies.join(",")))
    end
    if trainer.flags && trainer.flags.length > 0
      uniqueFlags = trainer.flags
      uniqueFlags -= parentTrainer.flags if parentTrainer
      f.write(sprintf("Flags = %s\r\n", uniqueFlags.join(",")))
    end
    f.write(sprintf("Items = %s\r\n", trainer.items.join(","))) if trainer.items.length > 0

    trainer.pokemon.each do |pkmn|
      f.write(sprintf("Pokemon = %s,%d\r\n", pkmn[:species], pkmn[:level]))

      inheritingPkmn = nil
      if parentTrainer
        parentTrainer.pokemon.each do |existingPokemon|
          next if existingPokemon[:species] != pkmn[:species]
          if existingPokemon[:level] == pkmn[:level]
            inheritingPkmn = existingPokemon
              break
          elsif pkmn[:name] && pkmn[:name] == existingPokemon[:name]
              inheritingPkmn = existingPokemon
              break
          end
        end
      end

      writePartyMember(f,pkmn,inheritingPkmn)
    end
    trainer.removedPokemon.each do |pkmn|
      f.write(sprintf("RemovePokemon = %s,%d\r\n", pkmn[:species], pkmn[:level]))
      writePartyMember(f,pkmn)
    end
  end

  def writePartyMember(f,pkmn,inheritingPkmn = nil)
    f.write(sprintf("    Position = %s\r\n", pkmn[:assigned_position])) if !pkmn[:assigned_position].nil?
    f.write(sprintf("    Name = %s\r\n", pkmn[:name])) if pkmn[:name] && !pkmn[:name].empty?
    if pkmn[:form] && pkmn[:form] > 0 && (inheritingPkmn.nil? || pkmn[:form] != inheritingPkmn[:form])
      formName = GameData::Species.get_species_form(pkmn[:species],pkmn[:form]).form_name
      formName += " Form"
      f.write(sprintf("    Form = %d # %s\r\n", pkmn[:form], formName))
    end
    if pkmn[:gender] && (inheritingPkmn.nil? || pkmn[:gender] != inheritingPkmn[:gender])
      f.write(sprintf("    Gender = %s\r\n", (pkmn[:gender] == 1) ? "female" : "male"))
    end
    if pkmn[:shininess] && (inheritingPkmn.nil? || pkmn[:shininess] != inheritingPkmn[:shininess])
      f.write("    Shiny = yes\r\n")
    end
    if pkmn[:extra_types] && pkmn[:extra_types].length > 0 && (inheritingPkmn.nil? || pkmn[:extra_types] != inheritingPkmn[:extra_types])
      f.write(sprintf("    ExtraTypes = %s\r\n", pkmn[:extra_types].join(",")))
    end
    if pkmn[:moves] && pkmn[:moves].length > 0 && (inheritingPkmn.nil? || pkmn[:moves] != inheritingPkmn[:moves])
      f.write(sprintf("    Moves = %s\r\n", pkmn[:moves].join(",")))
    end
    if pkmn[:ability] && (inheritingPkmn.nil? || pkmn[:ability] != inheritingPkmn[:ability])
      f.write(sprintf("    Ability = %s\r\n", pkmn[:ability]))
    end
    if pkmn[:ability_index] && (inheritingPkmn.nil? || pkmn[:ability_index] != inheritingPkmn[:ability_index])
      form = pkmn[:form] || 0
      sp_data = GameData::Species.get_species_form(pkmn[:species],form)
      abilityID = sp_data.abilities[pkmn[:ability_index]] || sp_data.abilities[0]
      abilityName = GameData::Ability.get(abilityID).real_name
      f.write(sprintf("    AbilityIndex = %d # %s\r\n", pkmn[:ability_index], abilityName))
    end
    if pkmn[:extra_abilities] && pkmn[:extra_abilities].length > 0 && (inheritingPkmn.nil? || pkmn[:extra_abilities] != inheritingPkmn[:extra_abilities])
      f.write(sprintf("    ExtraAbilities = %s\r\n", pkmn[:extra_abilities].join(",")))
    end 
    if pkmn[:item] && (inheritingPkmn.nil? || pkmn[:item] != inheritingPkmn[:item])
      if pkmn[:item].is_a?(Array)
        f.write(sprintf("    Item = %s\r\n", pkmn[:item].join(","))) 
      else
        f.write(sprintf("    Item = %s\r\n", pkmn[:item])) 
      end
    end
    if pkmn[:extra_items] && pkmn[:extra_items].length > 0 && (inheritingPkmn.nil? || pkmn[:extra_items] != inheritingPkmn[:extra_items])
      f.write(sprintf("    ExtraItems = %s\r\n", pkmn[:extra_items].join(",")))
    end 
    if pkmn[:item_type] && (inheritingPkmn.nil? || pkmn[:item_type] != inheritingPkmn[:item_type])
      f.write(sprintf("    ItemType = %s\r\n", pkmn[:item_type]))
    end
    if pkmn[:nature] && (inheritingPkmn.nil? || pkmn[:nature] != inheritingPkmn[:nature])
      f.write(sprintf("    Nature = %s\r\n", pkmn[:nature]))
    end
    if pkmn[:ev] && (inheritingPkmn.nil? || pkmn[:ev] != inheritingPkmn[:ev])
      evs_array = []
      GameData::Stat.each_main do |s|
        next if s.pbs_order < 0
        evs_array[s.pbs_order] = pkmn[:ev][s.id]
      end
      f.write("    # HP, Attack, Defense, Speed, Sp. Atk, Sp. Def\r\n")
      f.write(sprintf("    EV = %s\r\n", evs_array.join(",")))
    end
    if pkmn[:happiness] && (inheritingPkmn.nil? || pkmn[:happiness] != inheritingPkmn[:happiness])
      f.write(sprintf("    Happiness = %d\r\n", pkmn[:happiness]))
    end
    if pkmn[:poke_ball] && (inheritingPkmn.nil? || pkmn[:poke_ball] != inheritingPkmn[:poke_ball])
      f.write(sprintf("    Ball = %s\r\n", pkmn[:poke_ball]))
    end
  end
end