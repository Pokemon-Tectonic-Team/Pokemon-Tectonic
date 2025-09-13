module GameData
    class Move
      attr_reader :id
      attr_reader :id_number
      attr_reader :real_name
      attr_reader :function_code
      attr_reader :base_damage
      attr_reader :type
      attr_reader :category
      attr_reader :accuracy
      attr_reader :total_pp
      attr_reader :effect_chance
      attr_reader :target
      attr_reader :priority
      attr_reader :flags
      attr_reader :real_description
      attr_reader :animation_move
      
      attr_reader :primeval
      attr_reader :zmove
      attr_reader :cut
      attr_reader :tectonic_new

      # Metadata
      attr_accessor :signature_of
      attr_accessor :level_up_learners
      attr_accessor :other_learners
  
      DATA = {}
      DATA_FILENAME = "moves.dat"
      ALL_MOVES_LIST = [] # Filled out later to wait for Species compilation

      SCHEMA = {
      "Name"         => [:name,           "s"],
      "Type"         => [:type,           "e", :Type],
      "Category"     => [:category,       "e", ["Physical", "Special", "Status", "Adaptive"]],
      "Power"        => [:base_damage,    "u"],
      "Accuracy"     => [:accuracy,       "u"],
      "TotalPP"      => [:total_pp,       "u"],
      "Target"       => [:target,         "e", :Target],
      "Priority"     => [:priority,       "i"],
      "FunctionCode" => [:function_code,  "s"],
      "Flags"        => [:flags,          "*s"],
      "EffectChance" => [:effect_chance,  "u"],
      "Description"  => [:description,    "q"],
      "Animation"    => [:animation_move, "q"],
    }
  
      extend ClassMethods
      include InstanceMethods
  
      def initialize(hash)
        @id                 = hash[:id]
        @id_number          = hash[:id_number]   || -1
        @real_name          = hash[:name]        || "Unnamed"
        @function_code      = hash[:function_code]
        @base_damage        = hash[:base_damage] || 0
        @type               = hash[:type]
        @category           = hash[:category]
        @accuracy           = hash[:accuracy]
        @total_pp           = hash[:total_pp]
        @effect_chance      = hash[:effect_chance] || 0
        @target             = hash[:target]
        @priority           = hash[:priority] || 0
        @flags              = hash[:flags] || []
        @real_description   = hash[:description] || "???"
        @animation_move     = hash[:animation_move]
        @signature_of       = nil
        @primeval           = hash[:primeval] || false
        @zmove              = hash[:zmove] || false
        @cut                = hash[:cut] || false
        @tectonic_new       = hash[:tectonic_new] || false
        @defined_in_extension  = hash[:defined_in_extension]  || false

        @function_code = "Invalid" if @cut
      end
  
      # @return [String] the translated name of this move
      def name
        return pbGetMessageFromHash(MessageTypes::Moves, @real_name)
      end
  
      # @return [String] the translated description of this move
      def description
        return pbGetMessageFromHash(MessageTypes::MoveDescriptions, @real_description)
      end
  
      def physical?
        return false if @base_damage == 0
        return @category == 0
      end
  
      def special?
        return false if @base_damage == 0
        return @category == 1
      end

      def adaptive?
        return false if @base_damage == 0
        return @category == 3
      end
  
      def hidden_move?
        GameData::Item.each do |i|
          return true if i.is_HM? && i.move == @id
        end
        return false
      end

      def damaging?
        return physical? || special? || adaptive?
      end

      def status?
        return !damaging?
      end

      def is_signature?
        return !@signature_of.nil? || avatarSignature? || @flags.include?("ForceSignature")
      end

      def empoweredMove?
        return @flags.include?("Empowered")
      end

      def testMove?
        return @flags.include?("Test")
      end

      def categoryLabel
        return _INTL("Physical") if physical?
        return _INTL("Special") if special?
        return _INTL("Adaptive") if adaptive?
        return _INTL("Status")
      end

      def priorityLabel
        priorityLabel = @priority.to_s
                  priorityLabel = "+" + priorityLabel if @priority > 0
        return priorityLabel
      end

      def self.moveTags
        return {
            "Biting"    => _INTL("Bite"),
            "Punch"     => _INTL("Punch"),
            "Sound"     => _INTL("Sound"),
            "Pulse"     => _INTL("Pulse"),
            "Dance"     => _INTL("Dance"),
            "Blade"     => _INTL("Blade"),
            "Wind"      => _INTL("Wind"),
            "Kick"      => _INTL("Kick"),
            "Light"     => _INTL("Light"),
        }
      end

      def tagLabel
        label = nil
        @flags.each do |flag|
          next unless GameData::Move.moveTags.key?(flag)
          if label
            label = _INTL("Multi")
          else
            label = GameData::Move.moveTags[flag]
          end
        end
        return label
      end

      def uninvocable?
        return @flags.include?("Uninvocable")
      end

      def avatarSignature?
        return @flags.include?("AvatarSignature")
      end

      def learnable?
        return false if @cut
        return false if @primeval
        return false if @zmove
        return false if avatarSignature?
        return false if @id == :STRUGGLE
        return true
      end

      def canon_move?
        return false if @cut
        return false if @primeval
        return false if @zmove
        return false if @tectonic_new
        return true
      end

      def staple_move?
        return @flags.include?("Staple")
      end

      # Yields all data in order of their id_number.
      def self.each
        keys = self::DATA.keys.sort { |a, b|
            moveDataA = self::DATA[a]
            moveDataB = self::DATA[b]
            if moveDataA.type == moveDataB.type
                moveDataA.id <=> self::DATA[b].id
            else
                GameData::Type.get(moveDataA.type).id_number <=> GameData::Type.get(moveDataB.type).id_number
            end
        }
        keys.each { |key| yield self::DATA[key] if !key.is_a?(Integer) }
      end

      def self.calculate_all_non_signature_list
        self.each do |moveData|
          next unless moveData.learnable?
          next if moveData.testMove?
          next if moveData.is_signature?
          self::ALL_MOVES_LIST.push(moveData.id)
        end
      end

      def self.all_non_signature_moves
        return self::ALL_MOVES_LIST
      end

      def self.staple_moves
        return self::DATA.values.filter { |move| move.staple_move? }.map { |move| move.id }
      end
    end
end
  
#===============================================================================
# Deprecated methods
#===============================================================================
# @deprecated This alias is slated to be removed in v20.
def pbGetMoveData(move_id, move_data_type = -1)
    Deprecation.warn_method('pbGetMoveData', 'v20', 'GameData::Move.get(move_id)')
    return GameData::Move.get(move_id)
end

# @deprecated This alias is slated to be removed in v20.
def pbIsHiddenMove?(move)
    Deprecation.warn_method('pbIsHiddenMove?', 'v20', 'GameData::Move.get(move).hidden_move?')
    return GameData::Move.get(move).hidden_move?
end

module Compiler
    module_function
  #=============================================================================
  # Compile move data
  #=============================================================================
  def compile_moves
    GameData::Move::DATA.clear
    schema = GameData::Move::SCHEMA
    move_names        = []
    move_descriptions = []
    move_hash         = nil
    idx = 0
    baseFiles = ["PBS/moves.txt","PBS/moves_new.txt","PBS/moves_primeval.txt","PBS/moves_z.txt","PBS/moves_cut.txt"]
    moveTextFiles = []
    moveTextFiles.concat(baseFiles)
    moveExtensions = Compiler.get_extensions("moves")
    moveTextFiles.concat(moveExtensions)
    moveTextFiles.each do |path|
      primeval = path == "PBS/moves_primeval.txt"
      cut = path == "PBS/moves_cut.txt"
      tectonic_new = (path == "PBS/moves_new.txt") || moveExtensions.include?(path)
      zmove = path == "PBS/moves_z.txt"
      baseFile = baseFiles.include?(path)

      pbCompilerEachPreppedLine(path) { |line, line_no|
        idx += 1
        if line[/^\s*\[\s*(.+)\s*\]\s*$/]   # New section [move_id]
          # Add previous move's data to records
          if move_hash
            # Sanitise data
            if (move_hash[:category] || 2) == 2 && (move_hash[:base_damage] || 0) != 0
              raise _INTL("Move {1} is defined as a Status move with a non-zero base damage.\r\n{2}",
                          move_hash[:name], FileLineData.linereport)
            elsif (move_hash[:category] || 2) != 2 && (move_hash[:base_damage] || 0) == 0
              print _INTL("Warning: Move {1} was defined as a Damaging move but had a base damage of 0. Changing it to a Status move.\r\n{2}",
                          move_hash[:name], FileLineData.linereport)
              move_hash[:category] = 2
            end
            GameData::Move.register(move_hash)
          end
          # Parse move ID
          move_id = $~[1].to_sym
          if GameData::Move.exists?(move_id)
            raise _INTL("Move ID '{1}' is used twice.\r\n{2}", move_id, FileLineData.linereport)
          end
          # Construct move hash
          move_hash = {
            :id_number            => idx,
            :id                   => move_id,
            :primeval             => primeval,
            :cut                  => cut,
            :tectonic_new         => tectonic_new,
            :zmove                => zmove,
            :defined_in_extension => !baseFile,
          }
        elsif line[/^\s*(\w+)\s*=\s*(.*)\s*$/]   # XXX=YYY lines
          if !move_hash
            raise _INTL("Expected a section at the beginning of the file.\r\n{1}", FileLineData.linereport)
          end
          # Parse property and value
          property_name = $~[1]
          line_schema = schema[property_name]
          next if !line_schema
          property_value = pbGetCsvRecord($~[2], line_no, line_schema)
          # Record XXX=YYY setting
          move_hash[line_schema[0]] = property_value
          next if cut || zmove
          case property_name
            when "Name"
              move_names.push(move_hash[:name])
            when "Description"
              move_descriptions.push(move_hash[:description])
            when "FunctionCode"
              moveFunction = move_hash[:function_code]
              className = sprintf("PokeBattle_Move_%s", moveFunction)
              unless Object.const_defined?(className)
                raise _INTL("A class for the move function code #{moveFunction} given for move #{move_hash[:id]}
                  does not exist!\r\n{1}",FileLineData.linereport)
              end
          end
        end
      }
    end

    # Add last move's data to records
    if move_hash
      # Sanitise data
      if (move_hash[:category] || 2) == 2 && (move_hash[:base_damage] || 0) != 0
        raise _INTL("Move {1} is defined as a Status move with a non-zero base damage.\r\n{2}", line[2], FileLineData.linereport)
      elsif (move_hash[:category] || 2) != 2 && (move_hash[:base_damage] || 0) == 0
        print _INTL("Warning: Move {1} was defined as a Damaging move but had a base damage of 0. Changing it to a Status move.\r\n{2}", line[2], FileLineData.linereport)
        move_hash[:category] = 2
      end
      GameData::Move.register(move_hash)
    end

    # Save all data
    GameData::Move.save
    MessageTypes.setMessagesAsHash(MessageTypes::Moves, move_names)
    MessageTypes.setMessagesAsHash(MessageTypes::MoveDescriptions, move_descriptions)
    Graphics.update

    GameData::Move.each do |move_data|
      next if move_data.animation_move.nil?
      next if GameData::Move.exists?(move_data.animation_move)
      raise _INTL("Move ID '{1}' was assigned an Animation Move property {2} that doesn't match with any other move.\r\n", move_data.id, move_data.animation_move)
    end
  end

  #=============================================================================
  # Save move data to PBS file
  #=============================================================================
  def write_moves
    File.open("PBS/moves_new.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      currentType = nil
      GameData::Move.each_base do |m|
        next unless m.tectonic_new
        if currentType != m.type
            currentType = m.type
            f.write("\#-------------------------------\r\n")
            f.write("\#\t\t#{currentType} MOVES\r\n")
        end
        write_move(f,m)
      end
    }
    File.open("PBS/moves_cut.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      currentType = nil
      GameData::Move.each_base do |m|
        next unless m.cut
        if currentType != m.type
            currentType = m.type
            f.write("\#-------------------------------\r\n")
            f.write("\#\t\t#{currentType} MOVES\r\n")
        end
        write_move(f,m)
      end
    }
    File.open("PBS/moves_z.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      currentType = nil
      GameData::Move.each_base do |m|
        next unless m.zmove
        if currentType != m.type
            currentType = m.type
            f.write("\#-------------------------------\r\n")
            f.write("\#\t\t#{currentType} MOVES\r\n")
        end
        write_move(f,m)
      end
    }
    File.open("PBS/moves_primeval.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      currentType = nil
      GameData::Move.each_base do |m|
        next unless m.primeval
        if currentType != m.type
            currentType = m.type
            f.write("\#-------------------------------\r\n")
            f.write("\#\t\t#{currentType} MOVES\r\n")
        end
        write_move(f,m)
      end
    }
    File.open("PBS/moves.txt", "wb") { |f|
      add_PBS_header_to_file(f)
      currentType = nil
      GameData::Move.each_base do |m|
        next unless m.canon_move?
        if currentType != m.type
            currentType = m.type
            f.write("\#-------------------------------\r\n")
            f.write("\#\t\t#{currentType} MOVES\r\n")
        end
        write_move(f,m)
      end
    }
    Graphics.update
  end

  def write_move(f, move)    
    f.write("\#-------------------------------\r\n")
    f.write("[#{move.id}]\r\n")
    f.write("Name = #{move.real_name}\r\n")
    f.write("Type = #{move.type.to_s}\r\n")
    category = ["Physical", "Special", "Status", "Adaptive"][move.category]
    f.write("Category = #{category}\r\n")
    f.write("Power = #{move.base_damage}\r\n") if move.base_damage > 0
    f.write("Accuracy = #{move.accuracy}\r\n")
    f.write("TotalPP = #{move.total_pp}\r\n")
    f.write("Target = #{move.target}\r\n")
    f.write("Priority = #{move.priority}\r\n") if move.priority != 0
    f.write("FunctionCode = #{move.function_code}\r\n")
    f.write("Flags = #{move.flags.join(',')}\r\n") if move.flags.length > 0
    f.write("EffectChance = #{move.effect_chance}\r\n") if move.effect_chance > 0
    f.write("Description = #{move.real_description}\r\n")
    f.write("Animation = #{move.animation_move.to_s}\r\n") if move.animation_move
  end
end