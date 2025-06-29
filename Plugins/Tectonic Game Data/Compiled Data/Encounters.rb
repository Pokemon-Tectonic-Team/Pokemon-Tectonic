module GameData
    class Encounter
      attr_accessor :id
      attr_accessor :map
      attr_accessor :version
      attr_reader :step_chances
      attr_reader :available_levels
      attr_reader :types
      attr_reader :defined_in_extension
  
      DATA = {}
      DATA_FILENAME = "encounters.dat"
  
      extend ClassMethodsSymbols
      include InstanceMethods
  
      # @param map_id [Integer]
      # @param map_version [Integer, nil]
      # @return [Boolean] whether there is encounter data for the given map ID/version
      def self.exists?(map_id, map_version = 0)
        validate map_id => [Integer]
        validate map_version => [Integer]
        key = sprintf("%s_%d", map_id, map_version).to_sym
        return !self::DATA[key].nil?
      end
  
      # @param map_id [Integer]
      # @param map_version [Integer, nil]
      # @return [self, nil]
      def self.get(map_id, map_version = 0)
        validate map_id => Integer
        validate map_version => Integer
        trial_key = sprintf("%s_%d", map_id, map_version).to_sym
        key = (self::DATA.has_key?(trial_key)) ? trial_key : sprintf("%s_0", map_id).to_sym
        return Randomizer.getRandomizedData(self::DATA[key], :ENCOUNTERS, key)
      end
  
      # Yields all encounter data in order of their map and version numbers.
      def self.each
        keys = self::DATA.keys.sort do |a, b|
          if self::DATA[a].map == self::DATA[b].map
            self::DATA[a].version <=> self::DATA[b].version
          else
            self::DATA[a].map <=> self::DATA[b].map
          end
        end
        keys.each { |key| yield self::DATA[key] }
      end
  
      # Yields all encounter data for the given version. Also yields encounter
      # data for version 0 of a map if that map doesn't have encounter data for
      # the given version.
      def self.each_of_version(version = 0)
        self.each do |data|
          yield data if data.version == version
          if version > 0
            yield data if data.version == 0 && !self::DATA.has_key?([data.map, version])
          end
        end
      end
  
      def initialize(hash)
        @id           = hash[:id]
        @map          = hash[:map]
        @version      = hash[:version]      || 0
        @step_chances = hash[:step_chances]
        @available_levels = hash[:available_levels]
        @types        = hash[:types]        || {}
        @defined_in_extension = hash[:defined_in_extension] || false
      end
    end
end 

module Compiler
    module_function
  
    #=============================================================================
    # Compile wild encounter data
    #=============================================================================
    def compile_encounters(path = "PBS/encounters.txt")
      new_format        = nil
      encounter_hash    = nil
      step_chances      = nil
      available_levels  = nil
      need_step_chances = false   # Not needed for new format only
      probabilities     = nil     # Not needed for new format only
      current_type      = nil
      expected_lines    = 0
      max_level = GameData::GrowthRate.max_level
      baseFiles = [path]
		  encounterTextFiles = []
		  encounterTextFiles.concat(baseFiles)
		  encounterExtensions = Compiler.get_extensions("encounters")
		  encounterTextFiles.concat(encounterExtensions)
      encounterTextFiles.each do |path|
        baseFile = baseFiles.include?(path)
        pbCompilerEachPreppedLine(path) { |line, line_no|
          next if line.length == 0
          if expected_lines > 0 && line[/^\d+,/] && new_format   # Species line (new format)
            values = line.split(',').collect! { |v| v.strip }
            if !values || values.length < 3
              raise _INTL("Expected a species entry line for encounter type {1} for map '{2}', got \"{3}\" instead.\r\n{4}",
                GameData::EncounterType.get(current_type).real_name, encounter_hash[:map], line, FileLineData.linereport)
            end
            values = pbGetCsvRecord(line, line_no, [0, "vevV", nil, :Species])
            values[3] = values[2] if !values[3]
            if values[2] > max_level
              raise _INTL("Level number {1} is not valid (max. {2}).\r\n{3}", values[2], max_level, FileLineData.linereport)
            elsif values[3] > max_level
              raise _INTL("Level number {1} is not valid (max. {2}).\r\n{3}", values[3], max_level, FileLineData.linereport)
            elsif values[2] > values[3]
              raise _INTL("Minimum level is greater than maximum level: {1}\r\n{2}", line, FileLineData.linereport)
            end
            encounter_hash[:types][current_type].push(values)
          elsif expected_lines > 0 && !new_format   # Expect a species line and nothing else (old format)
            values = line.split(',').collect! { |v| v.strip }
            if !values || values.length < 2
              raise _INTL("Expected a species entry line for encounter type {1} for map '{2}', got \"{3}\" instead.\r\n{4}",
                GameData::EncounterType.get(current_type).real_name, encounter_hash[:map], line, FileLineData.linereport)
            end
            values = pbGetCsvRecord(line, line_no, [0, "evV", :Species])
            values[2] = values[1] if !values[2]
            if values[1] > max_level
              raise _INTL("Level number {1} is not valid (max. {2}).\r\n{3}", values[1], max_level, FileLineData.linereport)
            elsif values[2] > max_level
              raise _INTL("Level number {1} is not valid (max. {2}).\r\n{3}", values[2], max_level, FileLineData.linereport)
            elsif values[1] > values[2]
              raise _INTL("Minimum level is greater than maximum level: {1}\r\n{2}", line, FileLineData.linereport)
            end
            probability = probabilities[probabilities.length - expected_lines]
            encounter_hash[:types][current_type].push([probability] + values)
            expected_lines -= 1
          elsif line[/^\[\s*(.+)\s*\]$/]   # Map ID line (new format)
            if new_format == false
              raise _INTL("Can't mix old and new formats.\r\n{1}", FileLineData.linereport)
            end
            new_format = true
            values = $~[1].split(',').collect! { |v| v.strip.to_i }
            values[1] = 0 if !values[1]
            map_number = values[0]
            map_version = values[1]
            # Add map encounter's data to records
            if encounter_hash
              encounter_hash[:types].each_value do |slots|
                next if !slots || slots.length == 0
                slots.each_with_index do |slot, i|
                  next if !slot
                  slots.each_with_index do |other_slot, j|
                    next if i == j || !other_slot
                    next if slot[1] != other_slot[1] || slot[2] != other_slot[2] || slot[3] != other_slot[3]
                    slot[0] += other_slot[0]
                    slots[j] = nil
                  end
                end
                slots.compact!
                slots.sort! { |a, b| (a[0] == b[0]) ? a[1].to_s <=> b[1].to_s : b[0] <=> a[0] }
              end
              GameData::Encounter.register(encounter_hash)
            end
            # Raise an error if a map/version combo is used twice
            key = sprintf("%s_%d", map_number, map_version).to_sym
            if GameData::Encounter::DATA[key]
              raise _INTL("Encounters for map '{1}' are defined twice.\r\n{2}", map_number, FileLineData.linereport)
            end
            step_chances = {}
            available_levels = {}
            # Construct encounter hash
            encounter_hash = {
              :id           => key,
              :map          => map_number,
              :version      => map_version,
              :step_chances => step_chances,
              :available_levels => available_levels,
              :types        => {},
              :defined_in_extension => !baseFile
            }
            current_type = nil
            need_step_chances = true
            expected_lines = 0
          elsif line[/^(\d+)$/]   # Map ID line (old format)
            if new_format == true
              raise _INTL("Can't mix old and new formats.\r\n{1}", FileLineData.linereport)
            end
            new_format = false
            map_number = $~[1].to_i
            # Add map encounter's data to records
            if encounter_hash
              encounter_hash[:types].each_value do |slots|
                next if !slots || slots.length == 0
                slots.each_with_index do |slot, i|
                  next if !slot
                  slots.each_with_index do |other_slot, j|
                    next if i == j || !other_slot
                    next if slot[1] != other_slot[1] || slot[2] != other_slot[2] || slot[3] != other_slot[3]
                    slot[0] += other_slot[0]
                    slots[j] = nil
                  end
                end
                slots.compact!
                slots.sort! { |a, b| (a[0] == b[0]) ? a[1].to_s <=> b[1].to_s : b[0] <=> a[0] }
              end
              GameData::Encounter.register(encounter_hash)
            end
            # Raise an error if a map/version combo is used twice
            key = sprintf("%s_0", map_number).to_sym
            if GameData::Encounter::DATA[key]
              raise _INTL("Encounters for map '{1}' are defined twice.\r\n{2}", map_number, FileLineData.linereport)
            end
            step_chances = {}
            available_levels = {}
            # Construct encounter hash
            encounter_hash = {
              :id           => key,
              :map          => map_number,
              :version      => 0,
              :step_chances => step_chances,
              :available_levels => available_levels,
              :types        => {},
              :defined_in_extension => !baseFile
            }
            current_type = nil
            need_step_chances = true
          elsif !encounter_hash   # File began with something other than a map ID line
            raise _INTL("Expected a map number, got \"{1}\" instead.\r\n{2}", line, FileLineData.linereport)
          elsif line[/^(\d+)\s*,/] && !new_format   # Step chances line
            if !need_step_chances
              raise _INTL("Encounter densities are defined twice or\r\nnot immediately for map '{1}'.\r\n{2}",
                encounter_hash[:map], FileLineData.linereport)
            end
            need_step_chances = false
            values = pbGetCsvRecord(line, line_no, [0, "vvv"])
            GameData::EncounterType.each do |enc_type|
              case enc_type.id
              when :land, :contest then step_chances[enc_type.id] = values[0]
              when :cave           then step_chances[enc_type.id] = values[1]
              when :water          then step_chances[enc_type.id] = values[2]
              end
            end
          else
            # Check if line is an encounter method name or not
            values = line.split(',').collect! { |v| v.strip }
            current_type = (values[0] && !values[0].empty?) ? values[0].to_sym : nil
            if current_type && GameData::EncounterType.exists?(current_type)   # Start of a new encounter method
              need_step_chances = false
              if current_type == :Special
                # Special encounters skip step chances and have available level as their only parameter
                available_levels[current_type] = values[1].to_i if values[1] && !values[1].empty?
              else
                step_chances[current_type] = values[1].to_i if values[1] && !values[1].empty?
                step_chances[current_type] ||= GameData::EncounterType.get(current_type).trigger_chance
              end
              probabilities = GameData::EncounterType.get(current_type).old_slots
              expected_lines = probabilities.length
              available_levels[current_type] = values[2].to_i if values[2] && !values[2].empty?
              encounter_hash[:types][current_type] = []
            else
              raise _INTL("Undefined encounter type \"{1}\" for map '{2}'.\r\n{3}",
                line, encounter_hash[:map], FileLineData.linereport)
            end
          end
        }
        if expected_lines > 0 && !new_format
          raise _INTL("Not enough encounter lines given for encounter type {1} for map '{2}' (expected {3}).\r\n{4}",
            GameData::EncounterType.get(current_type).real_name, encounter_hash[:map], probabilities.length, FileLineData.linereport)
        end
        # Add last map's encounter data to records
        if encounter_hash
          encounter_hash[:types].each_value do |slots|
            next if !slots || slots.length == 0
            slots.each_with_index do |slot, i|
              next if !slot
              slots.each_with_index do |other_slot, j|
                next if i == j || !other_slot
                next if slot[1] != other_slot[1] || slot[2] != other_slot[2] || slot[3] != other_slot[3]
                slot[0] += other_slot[0]
                slots[j] = nil
              end
            end
            slots.compact!
            slots.sort! { |a, b| (a[0] == b[0]) ? a[1].to_s <=> b[1].to_s : b[0] <=> a[0] }
          end
          GameData::Encounter.register(encounter_hash)
        end
      end
      # Save all data
      GameData::Encounter.save
      Graphics.update
    end

  #=============================================================================
  # Save wild encounter data to PBS file
  #=============================================================================
  def write_encounters
    map_infos = pbLoadMapInfos
    File.open("PBS/encounters.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      GameData::Encounter.each do |encounter_data|
        next if encounter_data.defined_in_extension
        f.write("\#-------------------------------\r\n")
        map_name = (map_infos[encounter_data.map]) ? " # #{map_infos[encounter_data.map].name}" : ""
        if encounter_data.version > 0
          f.write(sprintf("[%03d,%d]%s\r\n", encounter_data.map, encounter_data.version, map_name))
        else
          f.write(sprintf("[%03d]%s\r\n", encounter_data.map, map_name))
        end
        encounter_data.types.each do |type, slots|
          next if !slots || slots.length == 0
          if encounter_data.step_chances[type] && encounter_data.step_chances[type] > 0
            if encounter_data.available_levels[type] && encounter_data.available_levels[type] > 0
              f.write(sprintf("%s,%d,%d\r\n", type.to_s, encounter_data.step_chances[type], encounter_data.available_levels[type]))
            else 
              f.write(sprintf("%s,%d\r\n", type.to_s, encounter_data.step_chances[type]))
            end
          else
            if encounter_data.available_levels[type] && encounter_data.available_levels[type] > 0
              f.write(sprintf("%s,%d\r\n", type.to_s, encounter_data.available_levels[type]))
            else
              f.write(sprintf("%s\r\n", type.to_s))
            end
          end
          slots.each do |slot|
            if slot[2] == slot[3]
              f.write(sprintf("    %d,%s,%d\r\n", slot[0], slot[1], slot[2]))
            else
              f.write(sprintf("    %d,%s,%d,%d\r\n", slot[0], slot[1], slot[2], slot[3]))
            end
          end
        end
      end
    }
    Graphics.update
  end
end