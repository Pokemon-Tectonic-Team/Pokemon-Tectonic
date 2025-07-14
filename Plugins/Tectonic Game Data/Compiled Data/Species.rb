module GameData
    class Species
        DEFAULT_GROWTH_RATE = :Medium
        DEFAULT_GENDER_RATIO = :Female50Percent
        DEFAULT_BASE_HAPPINESS = 70

        attr_reader :id
        attr_reader :id_number
        attr_reader :species
        attr_reader :form
        attr_reader :real_name
        attr_reader :real_form_name
        attr_reader :real_category
        attr_reader :real_pokedex_entry
        attr_reader :pokedex_form
        attr_reader :type1
        attr_reader :type2
        attr_reader :base_stats
        attr_reader :base_exp
        attr_reader :growth_rate
        attr_reader :gender_ratio
        attr_reader :catch_rate
        attr_reader :happiness
        attr_reader :moves
        attr_reader :tutor_moves
        attr_reader :egg_moves # To maintain some backwards compatibility
        attr_reader :line_moves
        attr_reader :abilities
        attr_reader :hidden_abilities
        attr_reader :wild_item_common
        attr_reader :wild_item_uncommon
        attr_reader :wild_item_rare
        attr_reader :hatch_steps
        attr_reader :evolutions
        attr_reader :height
        attr_reader :weight
        attr_reader :generation
        attr_reader :mega_stone
        attr_reader :mega_move
        attr_reader :unmega_form
        attr_reader :mega_message
        attr_reader :notes
        attr_accessor :earliest_available
        attr_reader :flags

        DATA = {}
        DATA_FILENAME = "species.dat"

        BASE_DATA = {} # Data that hasn't been extended

        extend ClassMethods
        include InstanceMethods

        # @param species [Symbol, self, String, Integer]
        # @param form [Integer]
        # @return [self, nil]
        def self.get_species_form(species, form)
            return nil if !species || !form
            validate species => [Symbol, self, String, Integer]
            validate form => Integer
            species = species.species if species.is_a?(self)
            species = DATA[species].species if species.is_a?(Integer)
            species = species.to_sym if species.is_a?(String)
            trial = format("%s_%d", species, form).to_sym
            species_form = DATA[trial].nil? ? species : trial
            return DATA.has_key?(species_form) ? DATA[species_form] : nil
        end

        def self.schema(compiling_forms = false)
            ret = {
              "FormName"          => [0, "q"],
              "Kind"              => [0, "s"],
              "Pokedex"           => [0, "q"],
              "Type1"             => [0, "e", :Type],
              "Type2"             => [0, "e", :Type],
              "BaseStats"         => [0, "vvvvvv"],
              "BaseEXP"           => [0, "v"],
              "Rareness"          => [0, "u"],
              "Happiness"         => [0, "u"],
              "Moves"             => [0, "*ue", nil, :Move],
              "TutorMoves"        => [0, "*e", :Move],
              "EggMoves"          => [0, "*e", :Move],
              "LineMoves"         => [0, "*e", :Move],
              "Abilities"         => [0, "*e", :Ability],
              "HiddenAbility"     => [0, "*e", :Ability],
              "WildItemCommon"    => [0, "e", :Item],
              "WildItemUncommon"  => [0, "e", :Item],
              "WildItemRare"      => [0, "e", :Item],
              "StepsToHatch"      => [0, "v"],
              "Height"            => [0, "f"],
              "Weight"            => [0, "f"],
              "Generation"        => [0, "i"],
              "Flags"             => [0, "*s"],
              "BattlerPlayerX"    => [0, "i"],
              "BattlerPlayerY"    => [0, "i"],
              "BattlerEnemyX"     => [0, "i"],
              "BattlerEnemyY"     => [0, "i"],
              "BattlerAltitude"   => [0, "i"],
              "BattlerShadowX"    => [0, "i"],
              "BattlerShadowSize" => [0, "u"],
              "Notes"             => [0, "q"],
              "Tribes"            => [0, "*e", :Tribe],
            }
            if compiling_forms
                ret["PokedexForm"]  = [0, "u"]
                ret["Evolutions"]   = [0, "*ees", :Species, :Evolution, nil]
                ret["MegaStone"]    = [0, "e", :Item]
                ret["MegaMove"]     = [0, "e", :Move]
                ret["UnmegaForm"]   = [0, "u"]
                ret["MegaMessage"]  = [0, "u"]
            else
                ret["InternalName"] = [0, "n"]
                ret["Name"]         = [0, "s"]
                ret["GrowthRate"]   = [0, "e", :GrowthRate]
                ret["GenderRate"]   = [0, "e", :GenderRatio]
                ret["Evolutions"]   = [0, "*ses", nil, :Evolution, nil]
            end
            return ret
        end

        def initialize(hash)
            @id                    = hash[:id]
            @id_number             = hash[:id_number]             || -1
            @species               = hash[:species]               || @id
            @form                  = hash[:form]                  || 0
            @real_name             = hash[:name]                  || "Unnamed"
            @real_form_name        = hash[:form_name]
            @real_category         = hash[:category]              || "???"
            @real_pokedex_entry    = hash[:pokedex_entry]         || "???"
            @pokedex_form          = hash[:pokedex_form]          || @form
            @type1                 = hash[:type1]                 || :NORMAL
            @type2                 = hash[:type2]                 || @type1
            @base_stats            = hash[:base_stats]            || {}
            oldBST = 0
            newBST = 0
            GameData::Stat.each_main do |s|
                @base_stats[s.id] = 1 if !@base_stats[s.id] || @base_stats[s.id] <= 0
                next if @base_stats[s.id] % 5 == 0 || @base_stats[s.id] == 1
                oldValue = @base_stats[s.id]
                newValue = (oldValue / 5.0).round(0) * 5

                @base_stats[s.id] = newValue

                oldBST += oldValue
                newBST += newValue
            end
            if newBST > oldBST + 5
                echoln("[STAT ROUNDING] #{@id} BST increased by #{newBST - oldBST} due to base stats rounding to nearest 5")  
            end
            if newBST < oldBST - 5
                echoln("[STAT ROUNDING] #{@id} BST decreased by #{newBST - oldBST} due to base stats rounding to nearest 5")
            end
            @base_exp              = hash[:base_exp]              || 100
            @growth_rate           = hash[:growth_rate]           || DEFAULT_GROWTH_RATE
            @gender_ratio          = hash[:gender_ratio]          || DEFAULT_GENDER_RATIO
            @catch_rate            = hash[:catch_rate]            || 255
            @happiness             = hash[:happiness]             || DEFAULT_BASE_HAPPINESS
            @moves                 = hash[:moves]                 || []
            @tutor_moves           = hash[:tutor_moves]           || []
            @tutor_moves.uniq!
            @tutor_moves.sort_by! { |a| a.to_s }
            @line_moves            = hash[:line_moves] || []
            @line_moves.uniq!
            @line_moves.sort_by! { |a| a.to_s }
            @abilities             = hash[:abilities]             || []
            @hidden_abilities      = hash[:hidden_abilities]      || []
            @wild_item_common      = hash[:wild_item_common]
            @wild_item_uncommon    = hash[:wild_item_uncommon]
            @wild_item_rare        = hash[:wild_item_rare]
            @hatch_steps           = hash[:hatch_steps]           || 1
            @evolutions            = hash[:evolutions]            || []
            @height                = hash[:height]                || 1
            @weight                = hash[:weight]                || 1
            @generation            = hash[:generation]            || 0
            @mega_stone            = hash[:mega_stone]
            @mega_move             = hash[:mega_move]
            @unmega_form           = hash[:unmega_form]           || 0
            @mega_message          = hash[:mega_message]          || 0
            @notes                 = hash[:notes]                 || ""
            @earliest_available    = nil
            @tribes                = hash[:tribes]                || []
            @defined_in_extension  = hash[:defined_in_extension]  || false
            @flags                 = hash[:flags]                 || []

            legalityChecks
        end

        def legalityChecks
            @moves.each do |entry|
                moveID = entry[1]
                moveData = GameData::Move.get(moveID)
                next if moveData.learnable?
                raise _INTL("Illegal move #{moveID} is learnable by species #{@id}!")
            end

            @line_moves.each do |moveID|
                moveData = GameData::Move.get(moveID)
                next if moveData.learnable?
                raise _INTL("Illegal move #{moveID} is learnable by species #{@id}!")
            end

            @tutor_moves.each do |moveID|
                moveData = GameData::Move.get(moveID)
                next if moveData.learnable?
                raise _INTL("Illegal move #{moveID} is learnable by species #{@id}!")
            end

            [@wild_item_common, @wild_item_uncommon, @wild_item_rare].each do |itemID|
                next unless itemID
                next if GameData::Item.get(itemID).legal?
                raise _INTL("Illegal item #{itemID} is a wild item of species #{@id}!")
            end

            @abilities.each do |abilityID|
                next unless abilityID
                next if GameData::Ability.get(abilityID).legal?
                raise _INTL("Illegal ability #{abilityID} is a defined ability of species #{@id}!")
            end

            @hidden_abilities.each do |abilityID|
                next unless abilityID
                next if GameData::Ability.get(abilityID).legal?
                raise _INTL("Illegal ability #{abilityID} is a defined hidden ability of species #{@id}!")
            end
        end

        # @return [String] the translated name of this species
        def name
            return pbGetMessageFromHash(MessageTypes::Species, @real_name)
        end

        # @return [String] the translated name of this form of this species
        def form_name
            return pbGetMessageFromHash(MessageTypes::FormNames, @real_form_name) || ""
        end

        # Adds the form if not form 0
        def full_name
            if form == 0
                return name
            else
                return _INTL("{1} ({2})", name, form_name)
            end
        end

        # @return [String] the translated Pokédex category of this species
        def category
            return pbGetMessageFromHash(MessageTypes::Kinds, @real_category)
        end

        # @return [String] the translated Pokédex entry of this species
        def pokedex_entry
            return pbGetMessageFromHash(MessageTypes::Entries, @real_pokedex_entry)
        end

        def apply_metrics_to_sprite(sprite, index, shadow = false)
            metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
            metrics_data.apply_metrics_to_sprite(sprite, index, shadow)
        end

        def shows_shadow?
            metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
            return metrics_data.shows_shadow?
        end

        def get_evolutions(exclude_invalid = false)
            ret = []
            @evolutions.each do |evo|
                next if evo[3] # Is the prevolution
                next if evo[1] == :None && exclude_invalid
                ret.push([evo[0], evo[1], evo[2]]) # [Species, method, parameter]
            end
            return ret
        end

        def get_family_evolutions(exclude_invalid = true)
            evos = get_evolutions(exclude_invalid)
            evos = evos.sort { |a, b| GameData::Species.get(a[0]).id_number <=> GameData::Species.get(b[0]).id_number }
            ret = []
            evos.each do |evo|
                ret.push([@species].concat(evo)) # [Prevo species, evo species, method, parameter]
                evo_array = GameData::Species.get(evo[0]).get_family_evolutions(exclude_invalid)
                ret.concat(evo_array) if evo_array && evo_array.length > 0
            end
            return ret
        end

        def get_previous_species
            return @species if @evolutions.length == 0
            @evolutions.each { |evo| return evo[0] if evo[3] } # Is the prevolution
            return @species
        end

        def get_previous_species_data
            return nil unless has_previous_species?
            sameFormData = GameData::Species.get_species_form(get_previous_species,@form)
            return sameFormData if sameFormData
            form0Data = GameData::Species.get(get_previous_species)
            return form0Data
        end

        def has_previous_species?
            return false if @evolutions.length == 0
            @evolutions.each { |evo| return true if evo[3] } # Is the prevolution
            return false
        end

        def get_line_start
            prevoSpecies = self
            while prevoSpecies.has_previous_species?
                prevoSpecies = prevoSpecies.get_previous_species_data
            end
            return prevoSpecies
        end

        def is_solitary?
            return @evolutions.empty?
        end

        def get_baby_species(check_items = false, item1 = nil, item2 = nil)
            ret = @species
            return ret if @evolutions.length == 0
            @evolutions.each do |evo|
                next unless evo[3] # Not the prevolution
                ret = evo[0] # Species of prevolution
                break
            end
            ret = GameData::Species.get(ret).get_baby_species(check_items, item1, item2) if ret != @species
            return ret
        end

        def get_related_species
            sp = get_baby_species
            evos = GameData::Species.get(sp).get_family_evolutions(false)
            return [sp] if evos.length == 0
            return [sp].concat(evos.map { |e| e[1] }).uniq
        end

        def family_evolutions_have_method?(check_method, check_param = nil)
            sp = get_baby_species
            evos = GameData::Species.get(sp).get_family_evolutions
            return false if evos.length == 0
            evos.each do |evo|
                if check_method.is_a?(Array)
                    next unless check_method.include?(evo[2])
                elsif evo[2] != check_method
                    next
                end
                return true if check_param.nil? || evo[3] == check_param
            end
            return false
        end

        # Used by the Moon Ball when checking if a Pokémon's evolution family
        # includes an evolution that uses the Moon Stone.
        def family_item_evolutions_use_item?(check_item = nil)
            sp = get_baby_species
            evos = GameData::Species.get(sp).get_family_evolutions
            return false if !evos || evos.length == 0
            evos.each do |evo|
                next if GameData::Evolution.get(evo[2]).use_item_proc.nil?
                return true if check_item.nil? || evo[3] == check_item
            end
            return false
        end

        def minimum_level
            return 1 if @evolutions.length == 0
            @evolutions.each do |evo|
                next unless evo[3] # Not the prevolution
                evo_method_data = GameData::Evolution.get(evo[1])
                next if evo_method_data.level_up_proc.nil?
                min_level = evo_method_data.minimum_level
                return (min_level == 0) ? evo[2] : min_level + 1
            end
            return 1
        end

        def tribes(ignoreInheritance = false)
            allTribes = @tribes.clone
            unless ignoreInheritance
                get_prevolutions.each do |prevo_entry|
                    allTribes.concat(GameData::Species.get_species_form(prevo_entry[0], @form).tribes)
                end
                allTribes.uniq!
                allTribes.compact!
            end
            return allTribes
        end

        def inherited_level_moves
            return get_previous_species_data.level_moves if has_previous_species?
            return []
        end

        def level_moves
            if @levelMoves.nil?
                @levelMoves = []
                @levelMoves.concat(inherited_level_moves)
                @moves.each do |learnsetEntry|
                    matchingInheritedMove = false
                    @levelMoves.each do |inheritedLearnsetEntry|
                        next unless inheritedLearnsetEntry[0] == learnsetEntry[0] && inheritedLearnsetEntry[1] == learnsetEntry[1]
                        matchingInheritedMove = true
                    end
                    if matchingInheritedMove
                        echoln("Species #{@id} learns move #{learnsetEntry[1]} at level #{learnsetEntry[0]} despite inheriting that move at that same level")
                    else
                        @levelMoves.push(learnsetEntry.clone)
                    end
                end

                @levelMoves.sort! { |learnsetEntryA, learnsetEntryB|
                    if learnsetEntryA[0] == learnsetEntryB[0]
                        if learnsetEntryA[1] == learnsetEntryB[1]
                            next 1
                        else
                            next learnsetEntryA[1] <=> learnsetEntryB[1]
                        end
                    else
                        next learnsetEntryA[0] <=> learnsetEntryB[0]
                    end
                }
            end
            return @levelMoves
        end

        def inherited_tutor_moves
            inheritedTutorMoves = []

            prevoSpecies = self
            while prevoSpecies.has_previous_species?
                prevoSpecies = prevoSpecies.get_previous_species_data

                inheritedTutorMoves.concat(prevoSpecies.line_moves || prevoSpecies.egg_moves)
                if prevoSpecies.canTutorAny?
                    inheritedTutorMoves.concat(GameData::Move.all_non_signature_moves)
                end
            end

            inheritedTutorMoves.uniq!
            inheritedTutorMoves.compact!
            return inheritedTutorMoves
        end

        def inherited_moves
            inheritedMoves = inherited_tutor_moves
            inherited_level_moves.each do |learnset_entry|
                moveID = learnset_entry[1]
                inheritedMoves.push(moveID)
            end
            inheritedMoves.uniq!
            inheritedMoves.compact!
            return inheritedMoves
        end

        def non_inherited_tutor_moves
            nonInheritedTutorMoves = @tutor_moves.clone
            inherited_moves.each do |moveID|
                nonInheritedTutorMoves.delete(moveID)
            end
            return nonInheritedTutorMoves
        end

        def non_inherited_line_moves
            nonInheritedLineMoves = (@line_moves || @egg_moves).clone
            inherited_moves.each do |moveID|
                nonInheritedLineMoves.delete(moveID)
            end
            return nonInheritedLineMoves
        end

        def non_inherited_level_moves
            nonInheritedLevelMoves = level_moves.clone
            inherited_level_moves.each do |learnset_entry|
                nonInheritedLevelMoves.reject! { |learnset_entry2|
                    learnset_entry[0] == learnset_entry2[0] && learnset_entry[1] == learnset_entry2[1]
                }
            end
            return nonInheritedLevelMoves
        end

        def recalculate_learnable_moves
            @learnableMoves = []

            @learnableMoves.concat(inherited_tutor_moves)
            @learnableMoves.concat(@tutor_moves)
            @learnableMoves.concat(@line_moves || @egg_moves)
            @learnableMoves.concat(form_specific_moves)
            level_moves.each do |learnset_entry|
                m = learnset_entry[1]
                @learnableMoves.push(m)
            end

            @learnableMoves.concat(GameData::Move.all_non_signature_moves) if canTutorAny?

            @learnableMoves.uniq!
            @learnableMoves.compact!
        end

        def learnable_moves
            recalculate_learnable_moves if @learnableMoves.nil?
            return @learnableMoves 
        end

        def non_level_moves
            learnableMoves = learnable_moves
            level_moves.each do |learnset_entry|
                m = learnset_entry[1]
                learnableMoves.delete(m)
            end
            return learnableMoves
        end

        def get_form_specific_move
            formMoves = form_specific_moves
            return nil if formMoves.empty?
            return formMoves[@form] || nil
        end

        def form_specific_moves
            if @species == :ROTOM
                return [
                    nil,
                    :OVERHEAT,    # Heat, Microwave
                    :HYDROPUMP,   # Wash, Washing Machine
                    :BLIZZARD,    # Frost, Refrigerator
                    :AIRSLASH,    # Fan
                    :LEAFSTORM, # Mow, Lawnmower
                ]
            elsif @species == :URSHIFU
                return %i[
                    WICKEDBLOW
                    SURGINGSTRIKES
                ]
            elsif @species == :NECROZMA
                return [
                    nil,
                    :SUNSTEELSTRIKE, # Dusk Mane (with Solgaleo) (form 1)
                    :MOONGEISTBEAM, # Dawn Wings (with Lunala) (form 2)
                ]
            elsif @species == :ZAMAZENTA
                return [
                    nil,
                    :BEHEMOTHBASH
                ]
            elsif @species == :ZACIAN
                return [
                    nil,
                    :BEHEMOTHBLADE
                ]
            end
            return []
        end

        def available_by?(level)
            return false unless earliest_available
            return level >= earliest_available
        end

        def get_prevolutions(exclude_invalid = false)
            ret = []
            @evolutions.each do |evo|
                next unless evo[3] # Is an evolution
                next if evo[1] == :None && exclude_invalid
                ret.push([evo[0], evo[1], evo[2]]) # [Species, method, parameter]
            end
            return ret
        end

        def physical_ehp
            hpCalc = calcStatGlobal(base_stats[:HP], EHP_LEVEL, DEFAULT_STYLE_VALUE, hp: true)
            defenseCalc = calcStatGlobal(base_stats[:DEFENSE], EHP_LEVEL, DEFAULT_STYLE_VALUE)
            return [(hpCalc * defenseCalc / 100), 1].max
        end

        def special_ehp
            hpCalc = calcStatGlobal(base_stats[:HP], EHP_LEVEL, DEFAULT_STYLE_VALUE, hp: true)
            spDefenseCalc = calcStatGlobal(base_stats[:SPECIAL_DEFENSE], EHP_LEVEL, DEFAULT_STYLE_VALUE)
            return [(hpCalc * spDefenseCalc / 100), 1].max
        end

        def generationNumber
            return @generation unless @generation == 0
            [0, 151, 251, 386, 493, 649, 721, 809, 898].each_with_index do |generationEndID, index|
                return index if @id_number <= generationEndID
            end
            return -1
        end

        def legalAbilities
            legalAbilities = []
            legalAbilities.concat(@abilities)
            legalAbilities.concat(@hidden_abilities)
            legalAbilities.uniq!
            legalAbilities.compact!
            return legalAbilities
        end

        def wildHeldItemsWithRarities
            itemsAndRarities = {}
            itemsAndRarities[@wild_item_common] = WILD_ITEM_CHANCE_COMMON if @wild_item_common

            if @wild_item_uncommon
                if itemsAndRarities.key?(@wild_item_uncommon)
                    itemsAndRarities[@wild_item_uncommon] += WILD_ITEM_CHANCE_UNCOMMON
                else
                    itemsAndRarities[@wild_item_uncommon] = WILD_ITEM_CHANCE_UNCOMMON
                end
            end

            if @wild_item_rare
                if itemsAndRarities.key?(@wild_item_rare)
                    itemsAndRarities[@wild_item_rare] += WILD_ITEM_CHANCE_RARE
                else
                    itemsAndRarities[@wild_item_rare] = WILD_ITEM_CHANCE_RARE
                end
            end
            return itemsAndRarities
        end

        def isLegendary?
            return @flags.include?("Legendary")
        end

        def isTest?
            return @flags.include?("Test")
        end

        def canTutorAny?
            return @flags.include?("TutorAny")
        end
    end
end

module Compiler
    module_function

    #=============================================================================
    # Compile Pokémon data
    #=============================================================================
    def compile_pokemon
        GameData::Species::DATA.clear
        species_names           = []
        species_form_names      = []
        species_categories      = []
        species_pokedex_entries = []

        # Read from PBS file
        baseFiles = ["PBS/pokemon.txt"]
        pokemonTextFiles = []
        pokemonTextFiles.concat(baseFiles)
        pokemonTextFiles.concat(Compiler.get_extensions("pokemon"))

        species_number = 0

        pokemonTextFiles.each do |path|
            baseFile = baseFiles.include?(path)
            File.open(path, "rb") do |f|
                FileLineData.file = path # For error reporting
                # Read a whole section's lines at once, then run through this code.
                # contents is a hash containing all the XXX=YYY lines in that section, where
                # the keys are the XXX and the values are the YYY (as unprocessed strings).
                schema = GameData::Species.schema
                pbEachFileSection3(f) do |contents, species_symbol|
                    species_number += 1
                    FileLineData.setSection(species_symbol, "header", nil) # For error reporting
                    # Raise an error if a species number is used twice
                    if GameData::Species::DATA[species_symbol]
                        raise _INTL("Species ID '{1}' is used twice.\r\n{2}", species_symbol, FileLineData.linereport)
                    end
                    # Go through schema hash of compilable data and compile this section
                    for key in schema.keys
                        # Skip empty properties, or raise an error if a required property is
                        # empty
                        if contents[key].nil? || contents[key] == ""
                            contents[key] = nil
                            next
                        end
                        # Raise an error if a species internal name is used twice
                        FileLineData.setSection(species_symbol, key, contents[key]) # For error reporting
                        # Compile value for key
                        value = pbGetCsvRecord(contents[key], key, schema[key])
                        value = nil if value.is_a?(Array) && value.length == 0
                        contents[key] = value
                        # Sanitise data
                        case key
                        when "BaseStats"
                            value_hash = {}
                            GameData::Stat.each_main do |s|
                                value_hash[s.id] = value[s.pbs_order] if s.pbs_order >= 0
                            end
                            contents[key] = value_hash
                        when "Height", "Weight"
                            # Convert height/weight to 1 decimal place and multiply by 10
                            value = (value * 10).round
                            if value <= 0
                                raise _INTL("Value for '{1}' can't be less than or close to 0 (section {2}, PBS/pokemon.txt)", key, species_symbol)
                            end
                            contents[key] = value
                        when "Moves"
                            move_array = []
                            for i in 0...value.length / 2
                                move_array.push([value[i * 2], value[i * 2 + 1], i])
                            end
                            move_array.sort! { |a, b| (a[0] == b[0]) ? a[2] <=> b[2] : a[0] <=> b [0] }
                            move_array.each { |arr| arr.pop }
                            contents[key] = move_array
                        when "TutorMoves", "EggMoves", "LineMoves", "Abilities", "HiddenAbility"
                            contents[key] = [contents[key]] unless contents[key].is_a?(Array)
                            contents[key].compact!
                        when "Evolutions"
                            evo_array = []
                            for i in 0...value.length / 3
                                evo_array.push([value[i * 3], value[i * 3 + 1], value[i * 3 + 2], false])
                            end
                            contents[key] = evo_array
                        end
                    end
                    # Construct species hash
                    species_hash = {
                      :id                    => species_symbol.to_sym,
                      :id_number             => species_number,
                      :name                  => contents["Name"],
                      :form_name             => contents["FormName"],
                      :category              => contents["Kind"],
                      :pokedex_entry         => contents["Pokedex"],
                      :type1                 => contents["Type1"],
                      :type2                 => contents["Type2"],
                      :base_stats            => contents["BaseStats"],
                      :base_exp              => contents["BaseEXP"],
                      :growth_rate           => contents["GrowthRate"],
                      :gender_ratio          => contents["GenderRate"],
                      :catch_rate            => contents["Rareness"],
                      :happiness             => contents["Happiness"],
                      :moves                 => contents["Moves"],
                      :tutor_moves           => contents["TutorMoves"],
                      :line_moves            => contents["LineMoves"],
                      :abilities             => contents["Abilities"],
                      :hidden_abilities      => contents["HiddenAbility"],
                      :wild_item_common      => contents["WildItemCommon"],
                      :wild_item_uncommon    => contents["WildItemUncommon"],
                      :wild_item_rare        => contents["WildItemRare"],
                      :hatch_steps           => contents["StepsToHatch"],
                      :evolutions            => contents["Evolutions"],
                      :height                => contents["Height"],
                      :weight                => contents["Weight"],
                      :generation            => contents["Generation"],
                      :flags                 => contents["Flags"],
                      :notes                 => contents["Notes"],
                      :tribes                => contents["Tribes"],
                      :defined_in_extension  => !baseFile,
                    }
                    # Add species' data to records
                    GameData::Species.register(species_hash)
                    species_names.push(species_hash[:name])
                    species_form_names.push(species_hash[:form_name])
                    species_categories.push(species_hash[:category])
                    species_pokedex_entries.push(species_hash[:pokedex_entry])
                end
            end
        end

        # Enumerate all evolution species and parameters (this couldn't be done earlier)
        GameData::Species.each do |species|
            FileLineData.setSection(species.species, "Evolutions", nil) # For error reporting
            Graphics.update if species.id_number % 200 == 0
            if species.id_number % 50 == 0
                pbSetWindowText(_INTL("Processing {1} evolution line {2}", FileLineData.file, species.species))
            end
            species.evolutions.each do |evo|
                evo[0] = csvEnumField!(evo[0], :Species, "Evolutions", species.species)
                param_type = GameData::Evolution.get(evo[1]).parameter
                if param_type.nil?
                    evo[2] = nil
                elsif param_type == Integer
                    evo[2] = csvPosInt!(evo[2])
                else
                    evo[2] = csvEnumField!(evo[2], param_type, "Evolutions", species.species)
                end
            end
        end
        # Add prevolution "evolution" entry for all evolved species
        all_evos = {}
        GameData::Species.each do |species| # Build a hash of prevolutions for each species
            # next if all_evos[species.species]
            species.evolutions.each do |evo|
                all_evos[evo[0]] = [species.species, evo[1], evo[2], true] # if !all_evos[evo[0]]
            end
        end
        GameData::Species.each do |species| # Distribute prevolutions
            species.evolutions.push(all_evos[species.species].clone) if all_evos[species.species]
        end

        # Save all data
        GameData::Species.save
        MessageTypes.setMessagesAsHash(MessageTypes::Species, species_names)
        MessageTypes.setMessagesAsHash(MessageTypes::FormNames, species_form_names)
        MessageTypes.setMessagesAsHash(MessageTypes::Kinds, species_categories)
        MessageTypes.setMessagesAsHash(MessageTypes::Entries, species_pokedex_entries)
        Graphics.update
    end

    #=============================================================================
    # Compile Pokémon forms data
    #=============================================================================
    def compile_pokemon_forms(path = "PBS/pokemonforms.txt")
        species_names           = []
        species_form_names      = []
        species_categories      = []
        species_pokedex_entries = []
        used_forms = {}
        # Get maximum species ID number
        form_number = 0
        GameData::Species.each do |species|
            form_number = species.id_number if form_number < species.id_number
        end
        baseFiles = [path]
        formTextFiles = []
		formTextFiles.concat(baseFiles)
		formExtensions = Compiler.get_extensions("pokemonforms")
		formTextFiles.concat(formExtensions)
		formTextFiles.each do |path|
            baseFile = baseFiles.include?(path)
            # Read from PBS file
            File.open(path, "rb") do |f|
                FileLineData.file = path # For error reporting
                # Read a whole section's lines at once, then run through this code.
                # contents is a hash containing all the XXX=YYY lines in that section, where
                # the keys are the XXX and the values are the YYY (as unprocessed strings).
                schema = GameData::Species.schema(true)
                pbEachFileSection2(f) do |contents, section_name|
                    FileLineData.setSection(section_name, "header", nil) # For error reporting
                    # Split section_name into a species number and form number
                    split_section_name = section_name.split(/[-,\s]/)
                    if split_section_name.length != 2
                        raise _INTL(
                            "Section name {1} is invalid ({2}). Expected syntax like [XXX,Y] (XXX=internal name, Y=form number).", sectionName, path)
                    end
                    species_symbol = csvEnumField!(split_section_name[0], :Species, nil, nil)
                    form           = csvPosInt!(split_section_name[1])
                    # Raise an error if a species is undefined, the form number is invalid or
                    # a species/form combo is used twice
                    if !GameData::Species.exists?(species_symbol)
                        raise _INTL("Species ID '{1}' is not defined in {2}.\r\n{3}", species_symbol, path,
        FileLineData.linereport)
                    elsif form == 0
                        raise _INTL("A form cannot be defined with a form number of 0.\r\n{1}", FileLineData.linereport)
                    elsif used_forms[species_symbol] && used_forms[species_symbol].include?(form)
                        raise _INTL("Form {1} for species ID {2} is defined twice.\r\n{3}", form, species_symbol,
            FileLineData.linereport)
                    end
                    used_forms[species_symbol] = [] unless used_forms[species_symbol]
                    used_forms[species_symbol].push(form)
                    form_number += 1
                    base_data = GameData::Species.get(species_symbol)
                    # Go through schema hash of compilable data and compile this section
                    for key in schema.keys
                        # Skip empty properties (none are required)
                        if nil_or_empty?(contents[key])
                            contents[key] = nil
                            next
                        end
                        FileLineData.setSection(section_name, key, contents[key]) # For error reporting
                        # Compile value for key
                        value = pbGetCsvRecord(contents[key], key, schema[key])
                        value = nil if value.is_a?(Array) && value.length == 0
                        contents[key] = value
                        # Sanitise data
                        case key
                        when "BaseStats"
                            value_hash = {}
                            GameData::Stat.each_main do |s|
                                value_hash[s.id] = value[s.pbs_order] if s.pbs_order >= 0
                            end
                            contents[key] = value_hash
                        when "Height", "Weight"
                            # Convert height/weight to 1 decimal place and multiply by 10
                            value = (value * 10).round
                            if value <= 0
                                raise _INTL("Value for '{1}' can't be less than or close to 0 (section {2}, {3})", key, section_name,
                path)
                            end
                            contents[key] = value
                        when "Moves"
                            move_array = []
                            for i in 0...value.length / 2
                                move_array.push([value[i * 2], value[i * 2 + 1], i])
                            end
                            move_array.sort! { |a, b| (a[0] == b[0]) ? a[2] <=> b[2] : a[0] <=> b [0] }
                            move_array.each { |arr| arr.pop }
                            contents[key] = move_array
                        when "TutorMoves", "EggMoves", "LineMoves", "Abilities", "HiddenAbility"
                            contents[key] = [contents[key]] unless contents[key].is_a?(Array)
                            contents[key].compact!
                        when "Evolutions"
                            evo_array = []
                            for i in 0...value.length / 3
                                param_type = GameData::Evolution.get(value[i * 3 + 1]).parameter
                                param = value[i * 3 + 2]
                                if param_type.nil?
                                    param = nil
                                elsif param_type == Integer
                                    param = csvPosInt!(param)
                                else
                                    param = csvEnumField!(param, param_type, "Evolutions", section_name)
                                end
                                evo_array.push([value[i * 3], value[i * 3 + 1], param, false])
                            end
                            contents[key] = evo_array
                        end
                    end
                    # Construct species hash
                    form_symbol = format("%s_%d", species_symbol.to_s, form).to_sym
                    moves = contents["Moves"]
                    unless moves
                        moves = []
                        base_data.moves.each { |m| moves.push(m.clone) }
                    end
                    evolutions = contents["Evolutions"]
                    unless evolutions
                        evolutions = []
                        base_data.evolutions.each { |e| evolutions.push(e.clone) }
                    end
                    species_hash = {
                    :id                    => form_symbol,
                    :id_number             => form_number,
                    :species               => species_symbol,
                    :form                  => form,
                    :name                  => base_data.real_name,
                    :form_name             => contents["FormName"],
                    :category              => contents["Kind"] || base_data.real_category,
                    :pokedex_entry         => contents["Pokedex"] || base_data.real_pokedex_entry,
                    :pokedex_form          => contents["PokedexForm"],
                    :type1                 => contents["Type1"] || base_data.type1,
                    :type2                 => contents["Type2"] || base_data.type2,
                    :base_stats            => contents["BaseStats"] || base_data.base_stats,
                    :base_exp              => contents["BaseEXP"] || base_data.base_exp,
                    :growth_rate           => base_data.growth_rate,
                    :gender_ratio          => base_data.gender_ratio,
                    :catch_rate            => contents["Rareness"] || base_data.catch_rate,
                    :happiness             => contents["Happiness"] || base_data.happiness,
                    :moves                 => moves,
                    :tutor_moves           => contents["TutorMoves"] || base_data.tutor_moves.clone,
                    :line_moves            => contents["LineMoves"] || base_data.line_moves.clone,
                    :abilities             => contents["Abilities"] || base_data.abilities.clone,
                    :hidden_abilities      => contents["HiddenAbility"] || base_data.hidden_abilities.clone,
                    :wild_item_common      => contents["WildItemCommon"] || base_data.wild_item_common,
                    :wild_item_uncommon    => contents["WildItemUncommon"] || base_data.wild_item_uncommon,
                    :wild_item_rare        => contents["WildItemRare"] || base_data.wild_item_rare,
                    :hatch_steps           => contents["StepsToHatch"] || base_data.hatch_steps,
                    :evolutions            => evolutions,
                    :height                => contents["Height"] || base_data.height,
                    :weight                => contents["Weight"] || base_data.weight,
                    :generation            => contents["Generation"] || base_data.generation,
                    :flags                 => contents["Flags"] || base_data.flags,
                    :mega_stone            => contents["MegaStone"],
                    :mega_move             => contents["MegaMove"],
                    :unmega_form           => contents["UnmegaForm"],
                    :mega_message          => contents["MegaMessage"],
                    :notes                 => contents["Notes"],
                    :tribes                => contents["Tribes"] || base_data.tribes,
                    :defined_in_extension  => !baseFile
                    }
                    # If form is single-typed, ensure it remains so if base species is dual-typed
                    species_hash[:type2] = contents["Type1"] if contents["Type1"] && !contents["Type2"]
                    # If form has any wild items, ensure none are inherited from base species
                    if contents["WildItemCommon"] || contents["WildItemUncommon"] || contents["WildItemRare"]
                        species_hash[:wild_item_common] = contents["WildItemCommon"]
                        species_hash[:wild_item_uncommon] = contents["WildItemUncommon"]
                        species_hash[:wild_item_rare]     = contents["WildItemRare"]
                    end
                    # Add form's data to records
                    GameData::Species.register(species_hash)
                    species_names.push(species_hash[:name])
                    species_form_names.push(species_hash[:form_name])
                    species_categories.push(species_hash[:category])
                    species_pokedex_entries.push(species_hash[:pokedex_entry])
                end
            end
        end
        # Add prevolution "evolution" entry for all evolved forms that define their
        # own evolution methods (and thus won't have a prevolution listed already)
        all_evos = {}
        GameData::Species.each do |species|   # Build a hash of prevolutions for each species
            species.evolutions.each do |evo|
                all_evos[evo[0]] = [species.species, evo[1], evo[2], true] if !evo[3] && !all_evos[evo[0]]
            end
        end
        GameData::Species.each do |species|   # Distribute prevolutions
            next if species.form == 0 # Looking at alternate forms only
            next if species.evolutions.any? { |evo| evo[3] } # Already has prevo listed
            species.evolutions.push(all_evos[species.species].clone) if all_evos[species.species]
        end
        # Save all data
        GameData::Species.save
        MessageTypes.addMessagesAsHash(MessageTypes::Species, species_names)
        MessageTypes.addMessagesAsHash(MessageTypes::FormNames, species_form_names)
        MessageTypes.addMessagesAsHash(MessageTypes::Kinds, species_categories)
        MessageTypes.addMessagesAsHash(MessageTypes::Entries, species_pokedex_entries)
        Graphics.update
    end

    #=============================================================================
    # Determine the earliest you can aquire each species in the game
    #=============================================================================
    def compile_species_earliest_levels
        # A hash of all species in the game that can be aquired directly
        # where the key is the species ID and the value is the earliest level they can be directly aquired
        earliestWildEncounters = {}

        # Checking every single map in the game for encounters
        GameData::Encounter.each_of_version do |enc_data|
            # For each slot in that encounters data listing
            enc_data.types.each do |key, slots|
                next unless slots
                earliestLevelForSlot = enc_data.available_levels[key] || 100
                slots.each do |slot|
                    species = GameData::Species.get(slot[1]).species # get base form
                    if !earliestWildEncounters.has_key?(species) || earliestWildEncounters[species] > earliestLevelForSlot
                        earliestWildEncounters[species] = earliestLevelForSlot
                    end
                end
            end
        end

        # A hash where the key is a species
        # and the value is a hash that describes different ways of aquiring it
        earliestAquisition = earliestWildEncounters.clone

        iterationCount = 0
        loop do
            madeAnyChanges = false
            iterationCount += 1
            GameData::Species.each do |speciesData|
                species = speciesData.id
                next unless earliestAquisition.has_key?(species)
                earliestLevelForBase = earliestAquisition[species]

                evolutions = speciesData.get_evolutions

                # Determine the earliest possible aquisiton level for each of its evolutions
                evolutions.each do |evolutionEntry|
                    evoSpecies = evolutionEntry[0]
                    evoMethod = evolutionEntry[1]
                    param = evolutionEntry[2]
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
                        evoLevelThreshold = getEarliestLevelForItem(param)
                    end

                    earliestLevelForEvolved = [earliestLevelForBase, evoLevelThreshold].max

                    if !earliestAquisition.has_key?(evoSpecies) || earliestAquisition[evoSpecies] > earliestLevelForEvolved
                        earliestAquisition[evoSpecies] = earliestLevelForEvolved
                        madeAnyChanges = true
                    end
                end
            end
            break unless madeAnyChanges
        end

        earliestAquisition.each do |species, level|
            GameData::Species.get(species).earliest_available = level
        end

        GameData::Species.save
        Graphics.update
    end

    def getEarliestLevelForItem(item_id)
        ITEMS_AVAILABLE_BY_CAP.each do |levelCapBracket, itemArray|
            next unless itemArray.include?(item_id)
            return levelCapBracket
        end
        return 100
    end

    #=============================================================================
    # Save Pokémon data to PBS file
    #=============================================================================
    def write_pokemon
        form_map = Hash.new # used for pokemon_server generation
        File.open("PBS/pokemon.txt", "wb") do |f|
            add_PBS_header_to_file(f)
            GameData::Species.each_base do |species|
                next if species.defined_in_extension
                if (!form_map.key?(species.species))
                    form_map[species.species] = [0]
                end
                if species.form != 0
                    form_map[species.species].push(species.form)
                    next   
                end
                pbSetWindowText(_INTL("Writing species {1}...", species.id_number))
                Graphics.update if species.id_number % 50 == 0
                write_species(f, species)
            end
        end
        # load server banlist
        banlist = File.readlines("PBS/pokemon_server_banlist.txt", encoding: "bom|utf-8").map(&:chomp)
        File.open("PBS/pokemon_server.txt", "wb") do |f|
            GameData::Species.each_base do |species|
                if (species.species == :REGIGIGAS)
                end
                next if banlist.include?(species.species.to_s)
                next if species.form != 0
                next if species.defined_in_extension
                pbSetWindowText(_INTL("Writing species {1} for server...", species.id_number))
                Graphics.update if species.id_number % 50 == 0
                write_species_server(f, species, form_map[species.species])
            end
        end
        pbSetWindowText(nil)
        Graphics.update
    end

    def write_species(f, species)
        f.write("\#-------------------------------\r\n")
        f.write(format("[%s]\r\n", species.species))
        f.write(format("Name = %s\r\n", species.real_name))
        f.write(format("Notes = %s\r\n", species.notes)) if !species.notes.nil? && !species.notes.blank?
        f.write(format("Type1 = %s\r\n", species.type1))
        f.write(format("Type2 = %s\r\n", species.type2)) if species.type2 != species.type1
        stats_array = []
        total = 0
        GameData::Stat.each_main do |s|
            next if s.pbs_order < 0
            stats_array[s.pbs_order] = species.base_stats[s.id]
            total += species.base_stats[s.id]
        end
        f.write(format("# HP, Attack, Defense, Speed, Sp. Atk, Sp. Def\r\n", total))
        f.write(format("BaseStats = %s\r\n", stats_array.join(",")))
        f.write(format("# Total = %s\r\n", total))
        f.write(format("GenderRate = %s\r\n", species.gender_ratio)) unless species.gender_ratio == GameData::Species::DEFAULT_GENDER_RATIO
        f.write(format("GrowthRate = %s\r\n", species.growth_rate)) unless species.growth_rate == GameData::Species::DEFAULT_GROWTH_RATE
        f.write(format("BaseEXP = %d\r\n", species.base_exp))
        f.write(format("Rareness = %d\r\n", species.catch_rate))
        f.write(format("Happiness = %d\r\n", species.happiness)) unless species.happiness == GameData::Species::DEFAULT_BASE_HAPPINESS
        f.write(format("Abilities = %s\r\n", species.abilities.join(","))) if species.abilities.length > 0
        f.write(format("Moves = %s\r\n", species.non_inherited_level_moves.join(","))) if species.non_inherited_level_moves.length > 0
        f.write(format("TutorMoves = %s\r\n", species.non_inherited_tutor_moves.join(","))) if species.non_inherited_tutor_moves.length > 0
        f.write(format("LineMoves = %s\r\n", species.non_inherited_line_moves.join(","))) if species.non_inherited_line_moves.length > 0
        f.write(format("Tribes = %s\r\n", species.tribes(true).join(","))) if species.tribes(true).length > 0
        f.write(format("StepsToHatch = %d\r\n", species.hatch_steps))
        f.write(format("Height = %.1f\r\n", species.height / 10.0))
        f.write(format("Weight = %.1f\r\n", species.weight / 10.0))
        f.write(format("Kind = %s\r\n", species.real_category))
        f.write(format("Pokedex = %s\r\n", species.real_pokedex_entry))
        if species.real_form_name && !species.real_form_name.empty?
            f.write(format("FormName = %s\r\n",species.real_form_name))
        end
        f.write(format("Generation = %d\r\n", species.generation)) if species.generation != 0
        f.write(format("Flags = %s\r\n", species.flags.join(","))) if !species.flags.empty?
        f.write(format("WildItemCommon = %s\r\n", species.wild_item_common)) if species.wild_item_common
        f.write(format("WildItemUncommon = %s\r\n", species.wild_item_uncommon)) if species.wild_item_uncommon
        f.write(format("WildItemRare = %s\r\n", species.wild_item_rare)) if species.wild_item_rare
        if species.evolutions.any? { |evo| !evo[3] }
            f.write("Evolutions = ")
            need_comma = false
            species.evolutions.each do |evo|
                next if evo[3] # Skip prevolution entries
                f.write(",") if need_comma
                need_comma = true
                evo_type_data = GameData::Evolution.get(evo[1])
                param_type = evo_type_data.parameter
                f.write(format("%s,%s,", evo[0], evo_type_data.id.to_s))
                unless param_type.nil?
                    if !GameData.const_defined?(param_type.to_sym) && param_type.is_a?(Symbol)
                        f.write(getConstantName(param_type, evo[2]))
                    else
                        f.write(evo[2].to_s)
                    end
                end
            end
            f.write("\r\n")
        end
    end

    def write_species_server(f, species, form_list)
        f.write(format("[%s]\r\n", species.species))
        f.write(format("forms = %s\r\n", form_list.join(",")))
        f.write(format("gender_ratio = %s\r\n", species.gender_ratio))
        f.write(format("abilities = %s\r\n", species.abilities.join(","))) if species.abilities.length > 0
        f.write(format("moves = %s\r\n\r\n", species.learnable_moves.join(",")))
    end
    #=============================================================================
    # Save Pokémon forms data to PBS file
    #=============================================================================
    def write_pokemon_forms
        File.open("PBS/pokemonforms.txt", "wb") do |f|
            add_PBS_header_to_file(f)
            GameData::Species.each_base do |species|
                next if species.defined_in_extension
                next if species.form == 0
                pbSetWindowText(_INTL("Writing species {1}...", species.id_number))
                Graphics.update if species.id_number % 50 == 0
                write_species_form(f, species)
            end
        end
        pbSetWindowText(nil)
        Graphics.update
    end

    def write_species_form(f, species)
        base_species = GameData::Species.get(species.species)
        f.write("\#-------------------------------\r\n")
        f.write(format("[%s,%d]\r\n", species.species, species.form))
        if species.real_form_name && !species.real_form_name.empty?
            f.write(format("FormName = %s\r\n", species.real_form_name))
        end
        f.write(format("Notes = %s\r\n", species.notes)) if !species.notes.nil? && !species.notes.blank?
        f.write(format("PokedexForm = %d\r\n", species.pokedex_form)) if species.pokedex_form != species.form
        f.write(format("MegaStone = %s\r\n", species.mega_stone)) if species.mega_stone
        f.write(format("MegaMove = %s\r\n", species.mega_move)) if species.mega_move
        f.write(format("UnmegaForm = %d\r\n", species.unmega_form)) if species.unmega_form != 0
        f.write(format("MegaMessage = %d\r\n", species.mega_message)) if species.mega_message != 0
        if species.type1 != base_species.type1 || species.type2 != base_species.type2
            f.write(format("Type1 = %s\r\n", species.type1))
            f.write(format("Type2 = %s\r\n", species.type2)) if species.type2 != species.type1
        end
        stats_array = []
        GameData::Stat.each_main do |s|
            next if s.pbs_order < 0
            stats_array[s.pbs_order] = species.base_stats[s.id]
        end
        f.write(format("BaseStats = %s\r\n", stats_array.join(","))) if species.base_stats != base_species.base_stats
        f.write(format("BaseEXP = %d\r\n", species.base_exp)) if species.base_exp != base_species.base_exp
        f.write(format("Rareness = %d\r\n", species.catch_rate)) if species.catch_rate != base_species.catch_rate
        f.write(format("Happiness = %d\r\n", species.happiness)) if species.happiness != base_species.happiness
        if species.abilities.length > 0 && species.abilities != base_species.abilities
            f.write(format("Abilities = %s\r\n", species.abilities.join(",")))
        end
        if species.non_inherited_level_moves.length > 0 && species.non_inherited_level_moves != base_species.non_inherited_level_moves
            f.write(format("Moves = %s\r\n", species.non_inherited_level_moves.join(",")))
        end
        f.write(format("StepsToHatch = %d\r\n", species.hatch_steps)) if species.hatch_steps != base_species.hatch_steps
        f.write(format("Height = %.1f\r\n", species.height / 10.0)) if species.height != base_species.height
        f.write(format("Weight = %.1f\r\n", species.weight / 10.0)) if species.weight != base_species.weight
        f.write(format("Kind = %s\r\n", species.real_category)) if species.real_category != base_species.real_category
        if species.real_pokedex_entry != base_species.real_pokedex_entry
            f.write(format("Pokedex = %s\r\n",
  species.real_pokedex_entry))
        end
        f.write(format("Generation = %d\r\n", species.generation)) if species.generation != base_species.generation
        f.write(format("Flags = %s\r\n", species.flags.join(","))) if species.flags != base_species.flags
        if species.wild_item_common != base_species.wild_item_common ||
           species.wild_item_uncommon != base_species.wild_item_uncommon ||
           species.wild_item_rare != base_species.wild_item_rare
            f.write(format("WildItemCommon = %s\r\n", species.wild_item_common)) if species.wild_item_common
            f.write(format("WildItemUncommon = %s\r\n", species.wild_item_uncommon)) if species.wild_item_uncommon
            f.write(format("WildItemRare = %s\r\n", species.wild_item_rare)) if species.wild_item_rare
        end
        if species.evolutions != base_species.evolutions && species.evolutions.any? { |evo| !evo[3] }
            f.write("Evolutions = ")
            need_comma = false
            species.evolutions.each do |evo|
                next if evo[3] # Skip prevolution entries
                f.write(",") if need_comma
                need_comma = true
                evo_type_data = GameData::Evolution.get(evo[1])
                param_type = evo_type_data.parameter
                f.write(format("%s,%s,", evo[0], evo_type_data.id.to_s))
                unless param_type.nil?
                    if !GameData.const_defined?(param_type.to_sym) && param_type.is_a?(Symbol)
                        f.write(getConstantName(param_type, evo[2]))
                    else
                        f.write(evo[2].to_s)
                    end
                end
            end
            f.write("\r\n")
        end
    end
end
