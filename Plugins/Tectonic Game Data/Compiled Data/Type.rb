module GameData
    class Type
      attr_reader :id
      attr_reader :id_number
      attr_reader :real_name
      attr_reader :special_type
      attr_reader :pseudo_type
      attr_reader :weaknesses
      attr_reader :resistances
      attr_reader :immunities
      attr_reader :color
      attr_reader :dark_color
  
      DATA = {}
      DATA_FILENAME = "types.dat"
  
      SCHEMA = {
        "Name"          => [1, "s"],
        "InternalName"  => [2, "s"],
        "Color"         => [3, "uuu"],
        "DarkColor"     => [4, "uuu"],
        "IsPseudoType"  => [5, "b"],
        "IsSpecialType" => [6, "b"],
        "Weaknesses"    => [7, "*s"],
        "Resistances"   => [8, "*s"],
        "Immunities"    => [9, "*s"],
    }
  
      extend ClassMethods
      include InstanceMethods
  
      def initialize(hash)
        @id           = hash[:id]
        @id_number    = hash[:id_number]    || -1
        @real_name    = hash[:name]         || "Unnamed"
        @pseudo_type  = hash[:pseudo_type]  || false
        @special_type = hash[:special_type] || false
        @weaknesses   = hash[:weaknesses]   || []
        @weaknesses   = [@weaknesses] unless @weaknesses.is_a?(Array)
        @resistances  = hash[:resistances]  || []
        @resistances  = [@resistances] unless @resistances.is_a?(Array)
        @immunities   = hash[:immunities]   || []
        @immunities   = [@immunities] unless @immunities.is_a?(Array)

        rgb = hash[:color]
        @color        = Color.new(rgb[0],rgb[1],rgb[2]) if rgb
        dark_rgb = hash[:dark_color]
        @dark_color   = Color.new(dark_rgb[0],dark_rgb[1],dark_rgb[2]) if dark_rgb
      end
  
      # @return [String] the translated name of this item
      def name
        return pbGetMessage(MessageTypes::Types, @id_number)
      end
  
      def physical?; return !@special_type; end
      def special?;  return @special_type; end
  
      def effectiveness(other_type)
        return Effectiveness::NORMAL_EFFECTIVE if !other_type
        return Effectiveness::SUPER_EFFECTIVE if @weaknesses.include?(other_type)
        return Effectiveness::NOT_VERY_EFFECTIVE if @resistances.include?(other_type)
        return Effectiveness::INEFFECTIVE if @immunities.include?(other_type)
        return Effectiveness::NORMAL_EFFECTIVE
      end
    end
  end
  
  #===============================================================================
  
  module Effectiveness
    INEFFECTIVE            = 0
    NOT_VERY_EFFECTIVE = 0.5
    NORMAL_EFFECTIVE   = 1.0
    SUPER_EFFECTIVE    = 2.0
    HYPER_EFFECTIVE    = 4.0
  
    module_function
  
    def ineffective?(value)
      return value == INEFFECTIVE
    end
  
    def not_very_effective?(value)
      return value > INEFFECTIVE && value < NORMAL_EFFECTIVE
    end

    def barely_effective?(value)
      return value < NORMAL_EFFECTIVE / 2 && value > INEFFECTIVE
    end
  
    def resistant?(value)
      return value < NORMAL_EFFECTIVE && value > INEFFECTIVE
    end
  
    def normal?(value)
      return value == NORMAL_EFFECTIVE
    end
  
    def super_effective?(value)
      return value > NORMAL_EFFECTIVE
    end

    def hyper_effective?(value)
      return value > NORMAL_EFFECTIVE * 2
    end
  
    def ineffective_type?(attack_type, defend_type)
      value = calculate_one(attack_type, defend_type)
      return ineffective?(value)
    end
  
    def not_very_effective_type?(attack_type, defend_type)
      value = calculate_one(attack_type, defend_type)
      return not_very_effective?(value)
    end
  
    def resistant_type?(attack_type, defend_type)
      value = calculate_one(attack_type, defend_type)
      return resistant?(value)
    end
  
    def normal_type?(attack_type, defend_type)
      value = calculate_one(attack_type, defend_type)
      return normal?(value)
    end
  
    def super_effective_type?(attack_type, defend_type)
      value = calculate_one(attack_type, defend_type)
      return super_effective?(value)
    end
  
    def barely_effective_type?(attack_type, types = [])
      return attack_type < NORMAL_EFFECTIVE / 2 && attack_type > INEFFECTIVE if !defend_type1
      value = calculate(attack_type, types = [])
      return barely_effective?(value)
    end
  
    def modify_boss_effectiveness(effectiveness, user, target)
      if AVATAR_DILUTED_EFFECTIVENESS && (target.boss? || user.boss?) && effectiveness != 0
        return (1.0 + effectiveness) / 2.0
      end
      return effectiveness
    end
  
    def calculate_one(attack_type, defend_type)
      return GameData::Type.get(defend_type).effectiveness(attack_type)
    end
  
    def calculate(attack_type, types = [])
      modifier = 1.0
      types.compact.uniq.each do |type|
        modifier *= calculate_one(attack_type, type)
      end
      return modifier
    end
end

module Compiler
    module_function
  
  #=============================================================================
  # Compile type data
  #=============================================================================
  def compile_types(path = "PBS/types.txt")
    GameData::Type::DATA.clear
    type_names = []
    # Read from PBS file
    File.open(path, "rb") { |f|
      FileLineData.file = path   # For error reporting
      # Read a whole section's lines at once, then run through this code.
      # contents is a hash containing all the XXX=YYY lines in that section, where
      # the keys are the XXX and the values are the YYY (as unprocessed strings).
      schema = GameData::Type::SCHEMA
      pbEachFileSection(f) { |contents, type_number|
        # Go through schema hash of compilable data and compile this section
        for key in schema.keys
          FileLineData.setSection(type_number, key, contents[key])   # For error reporting
          # Skip empty properties, or raise an error if a required property is
          # empty
          if contents[key].nil?
            if ["Name", "InternalName"].include?(key)
              raise _INTL("The entry {1} is required in {2} section {3}.", key, path, type_id)
            end
            next
          end
          # Compile value for key
          value = pbGetCsvRecord(contents[key], key, schema[key])
          value = nil if value.is_a?(Array) && value.length == 0
          contents[key] = value
          # Ensure weaknesses/resistances/immunities are in arrays and are symbols
          if value && ["Weaknesses", "Resistances", "Immunities"].include?(key)
            contents[key] = [contents[key]] if !contents[key].is_a?(Array)
            contents[key].map! { |x| x.to_sym }
            contents[key].uniq!
          end
        end
        # Construct type hash
        type_symbol = contents["InternalName"].to_sym
        type_hash = {
          :id           => type_symbol,
          :id_number    => type_number,
          :name         => contents["Name"],
          :pseudo_type  => contents["IsPseudoType"],
          :special_type => contents["IsSpecialType"],
          :weaknesses   => contents["Weaknesses"],
          :resistances  => contents["Resistances"],
          :immunities   => contents["Immunities"],
          :color        => contents["Color"],
          :dark_color   => contents["DarkColor"],
        }
        # Add type's data to records
        GameData::Type.register(type_hash)
        type_names[type_number] = type_hash[:name]
      }
    }
    # Ensure all weaknesses/resistances/immunities are valid types
    GameData::Type.each do |type|
      type.weaknesses.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' is not a defined type ({2}, section {3}, Weaknesses).", other_type.to_s, path, type.id_number)
      end
      type.resistances.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' is not a defined type ({2}, section {3}, Resistances).", other_type.to_s, path, type.id_number)
      end
      type.immunities.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' is not a defined type ({2}, section {3}, Immunities).", other_type.to_s, path, type.id_number)
      end
    end
    # Save all data
    GameData::Type.save
    MessageTypes.setMessages(MessageTypes::Types, type_names)
    Graphics.update
  end

  #=============================================================================
  # Save type data to PBS file
  #=============================================================================
  def write_types
    File.open("PBS/types.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      # Write each type in turn
      GameData::Type.each do |type|
        f.write("\#-------------------------------\r\n")
        f.write("[#{type.id_number}]\r\n")
        f.write("Name = #{type.real_name}\r\n")
        f.write("InternalName = #{type.id}\r\n")
        if type.color
          rgb = [type.color.red.to_i,type.color.green.to_i,type.color.blue.to_i]
          f.write("Color = #{rgb.join(",")}\r\n")
        end
        if type.dark_color
          dark_rgb = [type.dark_color.red.to_i,type.dark_color.green.to_i,type.dark_color.blue.to_i]
          f.write("DarkColor = #{dark_rgb.join(",")}\r\n")
        end
        f.write("IsPseudoType = true\r\n") if type.pseudo_type
        f.write("IsSpecialType = true\r\n") if type.special?
        f.write("Weaknesses = #{type.weaknesses.join(",")}\r\n") if type.weaknesses.length > 0
        f.write("Resistances = #{type.resistances.join(",")}\r\n") if type.resistances.length > 0
        f.write("Immunities = #{type.immunities.join(",")}\r\n") if type.immunities.length > 0
      end
    }
    Graphics.update
  end
end