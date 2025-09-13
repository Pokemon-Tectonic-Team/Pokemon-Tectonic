module GameData
    class TrainerType
      attr_reader :id
      attr_reader :id_number
      attr_reader :real_name
      attr_reader :base_money
      attr_reader :battle_BGM
      attr_reader :victory_ME
      attr_reader :intro_ME
      attr_reader :gender
      attr_reader :skill_level
      attr_reader :skill_code
      attr_reader :policies
      attr_reader :cable_club
  
      DATA = {}
      DATA_FILENAME = "trainer_types.dat"

      SCHEMA = {
      "Name"       => [:name,        "s"],
      "Gender"     => [:gender,      "e", { "Male" => 0, "male" => 0, "M" => 0, "m" => 0, "0" => 0,
                                           "Female" => 1, "female" => 1, "F" => 1, "f" => 1, "1" => 1,
                                           "Unknown" => 2, "unknown" => 2, "Other" => 2, "other" => 2,
                                           "Mixed" => 2, "mixed" => 2, "X" => 2, "x" => 2, "2" => 2,
                                           "Wild" => 2, "wild" => 3, "W" => 3, "w" => 3, "3" => 3 }],
      "BaseMoney"  => [:base_money,  "u"],
      "SkillLevel" => [:skill_level, "u"],
      "Policies"   => [:policies,    "*s"],
      "IntroBGM"   => [:intro_ME,   "s"],
      "BattleBGM"  => [:battle_BGM,  "s"],
      "VictoryBGM" => [:victory_ME, "s"],
      "CableClub" => [:cable_club, "b"]
    }
  
      extend ClassMethodsSymbols
      include InstanceMethods
  
      def self.check_file(tr_type, path, optional_suffix = "", suffix = "")
        tr_type_data = self.try_get(tr_type)
        return nil if tr_type_data.nil?
        # Check for files
        if optional_suffix && !optional_suffix.empty?
          ret = path + tr_type_data.id.to_s + optional_suffix + suffix
          return ret if pbResolveBitmap(ret)
          ret = path + sprintf("%03d", tr_type_data.id_number) + optional_suffix + suffix
          return ret if pbResolveBitmap(ret)
        end
        ret = path + tr_type_data.id.to_s + suffix
        return ret if pbResolveBitmap(ret)
        ret = path + sprintf("%03d", tr_type_data.id_number) + suffix
        return (pbResolveBitmap(ret)) ? ret : nil
      end
  
      def self.charset_filename(tr_type)
        return self.check_file(tr_type, "Graphics/Characters/trainer_")
      end
  
      def self.charset_filename_brief(tr_type)
        ret = self.charset_filename(tr_type)
        ret.slice!("Graphics/Characters/") if ret
        return ret
      end
  
      def self.front_sprite_filename(tr_type)
        return self.check_file(tr_type, "Graphics/Trainers/")
      end
  
      def self.player_front_sprite_filename(tr_type)
        outfit = ($Trainer) ? $Trainer.outfit : 0
        return self.check_file(tr_type, "Graphics/Trainers/", sprintf("_%d", outfit))
      end
  
      def self.back_sprite_filename(tr_type)
        return self.check_file(tr_type, "Graphics/Trainers/", "", "_back")
      end
  
      def self.player_back_sprite_filename(tr_type)
        outfit = ($Trainer) ? $Trainer.outfit : 0
        return self.check_file(tr_type, "Graphics/Trainers/", sprintf("_%d", outfit), "_back")
      end
  
      def self.map_icon_filename(tr_type)
        return self.check_file(tr_type, "Graphics/Pictures/Town Map/Player Icons/mapPlayer")
      end
  
      def self.player_map_icon_filename(tr_type)
        outfit = ($Trainer) ? $Trainer.outfit : 0
        return self.check_file(tr_type, "Graphics/Pictures/Town Map/Player Icons/mapPlayer", sprintf("_%d", outfit))
      end

      def self.cableClubClasses
          return self::DATA.values.select { |t| t.cable_club }
      end
  
      def initialize(hash)
        @id          = hash[:id]
        @id_number   = hash[:id_number]   || -1
        @real_name   = hash[:name]        || "Unnamed"
        @base_money  = hash[:base_money]  || 30
        @battle_BGM  = hash[:battle_BGM]
        @victory_ME  = hash[:victory_ME]
        @victory_ME  = hash[:victory_ME]
        @intro_ME    = hash[:intro_ME]
        @gender      = hash[:gender]      || 2
        @skill_level = hash[:skill_level] || @base_money
        @skill_code  = hash[:skill_code]
        @policies	   = hash[:policies]	|| []
        @cable_club  = hash[:cable_club] || false
        @defined_in_extension   = hash[:defined_in_extension] || false
      end
  
      # @return [String] the translated name of this trainer type
      def name
        return pbGetMessageFromHash(MessageTypes::TrainerTypes, @real_name)
      end
  
      def male?;   return @gender == 0; end
      def female?; return @gender == 1; end
      def wild?; return @gender == 3; end
    end
end
  

module Compiler
    module_function
  
    #=============================================================================
    # Compile trainer type data
    #=============================================================================
    def compile_trainer_types(path="PBS/trainertypes.txt")
        GameData::TrainerType::DATA.clear
        schema = GameData::TrainerType::SCHEMA
        tr_type_names = []
        tr_type_hash  = nil
        baseFiles = [path]
        trainerTypeTextFiles = []
        trainerTypeTextFiles.concat(baseFiles)
        trainerTypeExtensions = Compiler.get_extensions("trainertypes")
        trainerTypeTextFiles.concat(trainerTypeExtensions)
        trainerTypeTextFiles.each do |path|
          baseFile = baseFiles.include?(path)
          # Read each line of trainer_types.txt at a time and compile it into a trainer type
          pbCompilerEachPreppedLine(path) { |line, line_no|
            if line[/^\s*\[\s*(.+)\s*\]\s*$/]   # New section [tr_type_id]
              # Add previous trainer type's data to records
              GameData::TrainerType.register(tr_type_hash) if tr_type_hash
              # Parse trainer type ID
              tr_type_id = $~[1].to_sym
              if GameData::TrainerType.exists?(tr_type_id)
                raise _INTL("Trainer Type ID '{1}' is used twice.\r\n{2}", tr_type_id, FileLineData.linereport)
              end
              # Construct trainer type hash
              tr_type_hash = {
                :id => tr_type_id,
                :defined_in_extension => !baseFile,
              }
            elsif line[/^\s*(\w+)\s*=\s*(.*)\s*$/]   # XXX=YYY lines
              if !tr_type_hash
                raise _INTL("Expected a section at the beginning of the file.\r\n{1}", FileLineData.linereport)
              end
              # Parse property and value
              property_name = $~[1]
              line_schema = schema[property_name]
              next if !line_schema
              property_value = pbGetCsvRecord($~[2], line_no, line_schema)
              # Record XXX=YYY setting
              tr_type_hash[line_schema[0]] = property_value
              tr_type_names.push(tr_type_hash[:name]) if property_name == "Name"
            end
          }
          # Add last trainer type's data to records
          GameData::TrainerType.register(tr_type_hash) if tr_type_hash
        end
        # Save all data
        GameData::TrainerType.save
        MessageTypes.setMessages(MessageTypes::TrainerTypes, tr_type_names)
        Graphics.update
    end

    #=============================================================================
    # Save trainer type data to PBS file
    #=============================================================================
    def write_trainer_types
        File.open("PBS/trainertypes.txt", "wb") { |f|
          add_PBS_header_to_file(f)
          GameData::TrainerType.each_base do |t|
            f.write("\#-------------------------------\r\n")
            f.write(sprintf("[%s]\r\n", t.id))
            f.write(sprintf("Name = %s\r\n", t.real_name))
            gender = GameData::TrainerType::SCHEMA["Gender"][2].key(t.gender)
            f.write(sprintf("Gender = %s\r\n", gender))
            f.write(sprintf("BaseMoney = %d\r\n", t.base_money))
            f.write(sprintf("SkillLevel = %d\r\n", t.skill_level)) if t.skill_level != t.base_money
            f.write(sprintf("Policies = %s\r\n", t.policies.join(","))) if t.policies.length > 0
            f.write(sprintf("IntroBGM = %s\r\n", t.intro_ME)) if !nil_or_empty?(t.intro_ME)
            f.write(sprintf("BattleBGM = %s\r\n", t.battle_BGM)) if !nil_or_empty?(t.battle_BGM)
            f.write(sprintf("VictoryME = %s\r\n", t.victory_ME)) if !nil_or_empty?(t.victory_ME)
            f.write(sprintf("CableClub = true\r\n")) if t.cable_club
          end
        }
        Graphics.update
    end
end