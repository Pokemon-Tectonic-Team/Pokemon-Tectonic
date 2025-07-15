MAX_HAPPINESS = 255

#===============================================================================
# Instances of this class are individual Pokémon.
# The player's party Pokémon are stored in the array $Trainer.party.
#===============================================================================
class Pokemon
    # @return [Symbol] this Pokémon's species
    attr_reader   :species
    # If defined, this Pokémon's form will be this value even if a MultipleForms
    # handler tries to say otherwise.
    # @return [Integer, nil] this Pokémon's form
    attr_accessor :forced_form
    # If defined, is the time (in Integer form) when this Pokémon's form was set.
    # @return [Integer, nil] the time this Pokémon's form was set
    attr_accessor :time_form_set
    # @return [Integer] the current experience points
    attr_reader   :exp
    # @return [Integer] the number of steps until this Pokémon hatches, 0 if this Pokémon is not an egg
    attr_accessor :steps_to_hatch
    # @return [Integer] the current HP
    attr_reader   :hp
    # @return [Symbol] this Pokémon's current status (see GameData::Status)
    attr_reader   :status
    # @return [Integer] sleep count / toxic flag / 0:
    #   sleep (number of rounds before waking up), toxic (0 = regular poison, 1 = toxic)
    attr_accessor :statusCount
    # This Pokémon's shininess (true, false, nil). Is recalculated if made nil.
    # @param value [Boolean, nil] whether this Pokémon is shiny
    attr_writer   :shiny
    # @return [Array<Pokemon::Move>] the moves known by this Pokémon
    attr_accessor :moves
    # @return [Array<Integer>] the IDs of moves known by this Pokémon when it was obtained
    attr_accessor :first_moves
    # @return [Array<Symbol>] an array of ribbons owned by this Pokémon
    attr_accessor :ribbons
    # @return [Integer] contest stats
    attr_accessor :cool, :beauty, :cute, :smart, :tough, :sheen
    # @return [Integer] this Pokémon's current happiness (an integer between 0 and 255)
    attr_accessor :happiness
    # @return [Symbol] the item ID of the Poké Ball this Pokémon is in
    attr_writer :poke_ball
    # @return [Integer] this Pokémon's markings, one bit per marking
    attr_accessor :markings
    # @return [Hash<Integer>] this Pokémon's effort values
    attr_accessor :ev
    # @return [Integer] calculated stats
    attr_reader   :totalhp, :attack, :defense, :spatk, :spdef, :speed
    # @return [Owner] this Pokémon's owner
    attr_reader   :owner
    # @return [Integer] the manner this Pokémon was obtained:
    #   0 (met), 1 (as egg), 2 (traded), 4 (fateful encounter)
    attr_accessor :obtain_method
    # @return [Integer] the ID of the map this Pokémon was obtained in
    attr_accessor :obtain_map
    # Describes the manner this Pokémon was obtained. If left undefined,
    # the obtain map's name is used.
    # @return [String] the obtain text
    attr_accessor :obtain_text
    # @return [Integer] the level of this Pokémon when it was obtained
    attr_accessor :obtain_level
    # If this Pokémon hatched from an egg, returns the map ID where the hatching happened.
    # Otherwise returns 0.
    # @return [Integer] the map ID where egg was hatched (0 by default)
    attr_accessor :hatched_map
    # Another Pokémon which has been fused with this Pokémon (or nil if there is none).
    # Currently only used by Kyurem, to record a fused Reshiram or Zekrom.
    # @return [Pokemon, nil] the Pokémon fused into this one (nil if there is none)
    attr_accessor :fused
    # @return [Integer] this Pokémon's personal ID
    attr_accessor :personalID

    attr_accessor :assignedPosition

    # For avatars
    attr_accessor :boss
    attr_accessor :hpMult
    attr_accessor :dmgMult
    attr_accessor :dmgResist
    attr_accessor :bossVersion
    attr_accessor :bossType
    attr_accessor :extraMovesPerTurn

    attr_writer   :itemTypeChosen

    attr_accessor :shinyRolls

    attr_accessor :shiny_variant
    attr_accessor :manual_hue_shift
    attr_accessor :manual_shade_shift

    attr_reader   :afraid
    attr_accessor :battlingStreak

    # Max total IVs
    IV_STAT_LIMIT = 31
    # Max total EVs
    EV_LIMIT      = 50
    # Max EVs that a single stat can have
    EV_STAT_LIMIT = 20
    # Maximum length a Pokémon's nickname can be
    MAX_NAME_SIZE = 10
    # Maximum number of moves a Pokémon can know at once
    MAX_MOVES     = 4
    # How much the pokemon's hue can vary (+/- half of this value)
    HUE_SHIFT_RANGE = 20
    # How much the pokemon's shade can vary (+/- half of this value)
    SHADE_SHIFT_RANGE = 80

    def self.play_cry(species, form = 0, volume = 90, pitch = 100)
        GameData::Species.play_cry_from_species(species, form, volume, pitch)
    end

    def play_cry(volume = 90, pitch = nil)
        GameData::Species.play_cry_from_pokemon(self, volume, pitch)
    end

    def species_data
        return GameData::Species.get_species_form(@species, form_simple)
    end

    #=============================================================================
    # Species and form
    #=============================================================================

    # Changes the Pokémon's species and re-calculates its statistics.
    # @param species_id [Integer] id of the species to change this Pokémon to
    def species=(species_id)
        new_species_data = GameData::Species.get(species_id)
        return if @species == new_species_data.species
        @species     = new_species_data.species
        @form        = new_species_data.form if new_species_data.form != 0
        @forced_form = nil
        @level       = nil # In case growth rate is different for the new species
        @ability     = nil
        calc_stats
    end

    # @param check_species [Integer, Symbol, String] id of the species to check for
    # @return [Boolean] whether this Pokémon is of the specified species
    def isSpecies?(check_species)
        return @species == check_species || (GameData::Species.exists?(check_species) &&
                                            @species == GameData::Species.get(check_species).species)
    end

    def form
        return @forced_form unless @forced_form.nil?
        return @form if $game_temp.in_battle
        calc_form = MultipleForms.call("getForm", self)
        self.form = calc_form if !calc_form.nil? && calc_form != @form
        return @form
    end

    def form_simple
        return @forced_form || @form
    end

    def form=(value)
        oldForm = @form
        @form = value
        @ability = nil
        MultipleForms.call("onSetForm", self, value, oldForm)
        calc_stats
        $Trainer.pokedex.register(self) if $Trainer
    end

    # The same as def form=, but yields to a given block in the middle so that a
    # message about the form changing can be shown before calling "onSetForm"
    # which may have its own messages, e.g. learning a move.
    def setForm(value)
        oldForm = @form
        @form = value
        @ability = nil
        yield if block_given?
        MultipleForms.call("onSetForm", self, value, oldForm)
        calc_stats
        $Trainer.pokedex.register(self)
    end

    def form_simple=(value)
        @form = value
        calc_stats
    end

    #=============================================================================
    # Level
    #=============================================================================

    # @return [Integer] this Pokémon's level
    def level
        @level ||= growth_rate.level_from_exp(@exp)
        return @level
    end

    # Sets this Pokémon's level. The given level must be between 1 and the
    # maximum level (defined in {GameData::GrowthRate}).
    # @param value [Integer] new level (between 1 and the maximum level)
    def level=(value)
        if value < 1 || value > GameData::GrowthRate.max_level
            raise ArgumentError, _INTL("The level number ({1}) is invalid.", value)
        end
        @exp = growth_rate.minimum_exp_for_level(value)
        @level = value
    end

    def set_starting_level(value)
        self.level = value
        @obtain_level = value
        calc_stats
    end

    # Sets this Pokémon's Exp. Points.
    # @param value [Integer] new experience points
    def exp=(value)
        @exp = value
        @level = nil
    end

    # @return [Boolean] whether this Pokémon is an egg
    def egg?
        return @steps_to_hatch > 0
    end

    # @return [GameData::GrowthRate] this Pokémon's growth rate
    def growth_rate
        return GameData::GrowthRate.get(species_data.growth_rate)
    end

    # @return [Integer] this Pokémon's base Experience value
    def base_exp
        return species_data.base_exp
    end

    # @return [Float] a number between 0 and 1 indicating how much of the current level's
    #   Exp this Pokémon has
    def exp_fraction
        lvl = level
        return 0.0 if lvl >= GameData::GrowthRate.max_level
        g_rate = growth_rate
        start_exp = g_rate.minimum_exp_for_level(lvl)
        end_exp   = g_rate.minimum_exp_for_level(lvl + 1)
        return (@exp - start_exp).to_f / (end_exp - start_exp)
    end

    def onHotStreak?
        return false unless HOT_STREAKS_ACTIVE
        return @battlingStreak >= 2
    end

    #=============================================================================
    # Status
    #=============================================================================

    # Sets the Pokémon's health.
    # @param value [Integer] new HP value
    def hp=(value)
        @hp = value.clamp(0, @totalhp)
        heal_status if @hp == 0
    end

    # Sets this Pokémon's status. See {GameData::Status} for all possible status effects.
    # @param value [Integer, Symbol, String] status to set
    def status=(value)
        return unless able?
        new_status = GameData::Status.try_get(value)
        raise ArgumentError, _INTL("Attempted to set {1} as Pokémon status", value.class.name) unless new_status
        @status = new_status.id
    end

    def getStatusImageIndex
        if afraid?
            statusIndex = GameData::Status::DATA.keys.length / 2
        elsif fainted?
            statusIndex = GameData::Status::DATA.keys.length / 2 - 1
        elsif status != :NONE
            statusIndex = GameData::Status.get(status).id_number - 1
        else
            statusIndex = -1
        end
        return statusIndex
    end

    # @return [Boolean] whether the Pokémon is not fainted and not an egg
    def able?(ignorePacifist = false)
        return false if hasAbility?(:PACIFIST) && !ignorePacifist
        return !egg? && @hp > 0 && !@afraid
    end

    # @return [Boolean] whether the Pokémon is fainted
    def fainted?
        return !egg? && @hp <= 0 || @afraid
    end

    # Heals all HP of this Pokémon.
    def heal_HP
        return if egg?
        @hp = @totalhp
    end

    # Heals this Pokemon's HP by an amount
    # Heals this Pokemon's HP by an amount
    def healBy(amount)
        return if egg?
        @hp += amount
        @hp = @totalhp if @hp > @totalhp
    end

    # Heals this Pokemon's HP by a fraction of its maximum
    def healByFraction(fraction)
        healBy((@totalhp * fraction).ceil)
    end

    # Heals the status problem of this Pokémon.
    def heal_status
        return if egg?
        @status      = :NONE
        @statusCount = 0
    end

    # Restores all PP of this Pokémon. If a move index is given, restores the PP
    # of the move in that index.
    # @param move_index [Integer] index of the move to heal (-1 if all moves
    #   should be healed)
    def heal_PP(move_index = -1)
        return if egg?
        if move_index >= 0
            @moves[move_index].pp = @moves[move_index].total_pp
        else
            @moves.each { |m| m.pp = m.total_pp }
        end
    end

    # Heals all HP, PP, and status problems of this Pokémon.
    def heal
        return if egg?
        heal_HP
        heal_status
        heal_PP
        @afraid = false
    end

    def afraid?
        return @afraid
    end

    def becomeAfraid
        @afraid = true
        @status = :NONE
        @statusCount = 0
    end

    def removeFear(battle = nil)
        @afraid = false
        if HEALING_RATIO_ON_FEAR_REMOVED > 0
            @hp = (@totalhp * HEALING_RATIO_ON_FEAR_REMOVED).floor
            message = _INTL("{1} is no longer Afraid. It was restored to half health!", name)
        else
            @hp = 1
            message = _INTL("{1} is no longer Afraid!", name)
        end
        if battle
            battle.pbDisplay(message)
        else
            pbMessage(message)
        end
    end

    #=============================================================================
    # Types
    #=============================================================================

    # @return [Symbol] this Pokémon's first type
    def type1
        return species_data.type1
    end

    # @return [Symbol] this Pokémon's second type, or the first type if none is defined
    def type2
        sp_data = species_data
        return sp_data.type2 || sp_data.type1
    end

    # @return [Array<Symbol>] an array of this Pokémon's types
    def types
        sp_data = species_data
        ret = [sp_data.type1]
        ret.push(sp_data.type2) if sp_data.type2 && sp_data.type2 != sp_data.type1
        extraTypes.each do |extraType|
            next if ret.include?(extraType)
            ret.push(extraType)
        end
        return ret
    end

    # @param type [Symbol, String, Integer] type to check
    # @return [Boolean] whether this Pokémon has the specified type
    def hasType?(type)
        type = GameData::Type.get(type).id
        return types.include?(type)
    end

    # Used by the AI
    def likelyHasSTAB?(type)
        likelySTABTypes = types
        likelySTABTypes.push(@itemTypeChosen) if hasItem?(:CRYSTALVEIL)
        return likelySTABTypes.include?(type)
    end

    def addExtraType(extraType)
        extraTypes.push(extraType) unless extraTypes.include?(extraType)
    end

    def extraTypes
        @extraTypes = [] if @extraTypes.nil?
        return @extraTypes
    end

    #=============================================================================
    # Gender
    #=============================================================================

    # @return [0, 1, 2] this Pokémon's gender (0 = male, 1 = female, 2 = genderless)
    def gender
        return 2 if boss?
        unless @gender
            gender_ratio = species_data.gender_ratio
            case gender_ratio
            when :AlwaysMale   then @gender = 0
            when :AlwaysFemale then @gender = 1
            when :Genderless   then @gender = 2
            else
                female_chance = GameData::GenderRatio.get(gender_ratio).female_chance
                genderID = ownedByPlayer? ? @personalID : aestheticsID
                @gender = ((genderID & 0xFF) < female_chance) ? 1 : 0
            end
        end
        return @gender
    end

    # Sets this Pokémon's gender to a particular gender (if possible).
    # @param value [0, 1] new gender (0 = male, 1 = female)
    def gender=(value)
        return if singleGendered?
        @gender = value if value.nil? || value == 0 || value == 1
    end

    # Makes this Pokémon male.
    def makeMale; self.gender = 0; end

    # Makes this Pokémon female.
    def makeFemale; self.gender = 1; end

    # @return [Boolean] whether this Pokémon is male
    def male?; return gender == 0; end

    # @return [Boolean] whether this Pokémon is female
    def female?; return gender == 1; end

    # @return [Boolean] whether this Pokémon is genderless
    def genderless?; return gender == 2; end

    # @return [Boolean] whether this Pokémon species is restricted to only ever being one
    #   gender (or genderless)
    def singleGendered?
        gender_ratio = species_data.gender_ratio
        return %i[AlwaysMale AlwaysFemale Genderless].include?(gender_ratio)
    end

    #=============================================================================
    # Shininess
    #=============================================================================

    # @return [Boolean] whether this Pokémon is shiny (differently colored)
    def shiny?
        if @shiny.nil?
            a = aestheticsID
            b = a & 0xFFFF
            c = (a >> 16) & 0xFFFF
            d = b ^ c
            @shiny = d < Settings::SHINY_POKEMON_CHANCE
        end
        return @shiny
    end

    #=============================================================================
    # Ability
    #=============================================================================

    # @return [Integer] the index of this Pokémon's ability
    def ability_index
        @ability_index ||= (@personalID & 1)
        return @ability_index
    end

    # The index of this Pokémon's ability (0, 1 are natural abilities, 2+ are
    # hidden abilities)as defined for its species/form. An ability may not be
    # defined at this index. Is recalculated (as 0 or 1) if made nil.
    # @param value [Integer, nil] forced ability index (nil if none is set)
    def ability_index=(value)
        @ability_index = value
        recalculateAbilityFromIndex
        removeInvalidItems
    end

    # @return [GameData::Ability, nil] an Ability object corresponding to this Pokémon's ability
    def ability
        return GameData::Ability.try_get(ability_id)
    end

    # @return [Symbol, nil] the ability symbol of this Pokémon's ability
    def ability_id
        recalculateAbilityFromIndex if @ability.nil?
        return @ability
    end

    def recalculateAbilityFromIndex
        sp_data = species_data
        abil_index = ability_index
        if abil_index >= 2 # Hidden ability
            @ability = sp_data.hidden_abilities[abil_index - 2]
        else
            @ability = sp_data.abilities[abil_index] || sp_data.abilities[0]
        end
    end

    def ability=(value)
        return if value && !GameData::Ability.exists?(value)
        if value.nil?
            recalculateAbilityFromIndex
            removeInvalidItems
        else
            @ability = GameData::Ability.get(value).id
            removeInvalidItems
        end
    end

    # Returns whether this Pokémon has a particular ability. If no value
    # is given, returns whether this Pokémon has an ability set.
    # @param check_ability [Symbol, GameData::Ability, Integer, nil] ability ID to check
    # @return [Boolean] whether this Pokémon has a particular ability or
    #   an ability at all
    def hasAbility?(check_ability = nil)
        return !ability.nil? if check_ability.nil?
        if check_ability.is_a?(Symbol)
            return ability_id == check_ability
        elsif check_ability.is_a?(Array)
            check_ability.each do |abilityToCheck|
                  return true if ability_id == abilityToCheck
            end
            return false
        else
            return ability == check_ability
        end
    end

    # @return [Boolean] whether this Pokémon has a hidden ability
    def hasHiddenAbility?
        return ability_index >= 2
    end

    # @return [Array<Array<Symbol,Integer>>] the abilities this Pokémon's species can have,
    #   where every element is [ability ID, ability index]
    def getAbilityList
        ret = []
        sp_data = species_data
        sp_data.abilities.each_with_index { |a, i| ret.push([a, i]) if a }
        sp_data.hidden_abilities.each_with_index { |a, i| ret.push([a, i + 2]) if a }
        return ret
    end

    def addExtraAbility(ability)
        extraAbilities.push(ability) unless extraAbilities.include?(ability)
    end

    def hasExtraAbilities?
        return extraAbilities.length > 0
    end

    def extraAbilities
        @extraAbilities = [] if @extraAbilities.nil?
        return @extraAbilities
    end

    def immuneToWeatherDownsides?
        return true if hasItem?(:UTILITYUMBRELLA)
        GameData::Ability.getByFlag("AllWeatherSynergy").each do |weatherAbilityID|
            return true if hasAbility?(weatherAbilityID)
        end
        return false
    end

    #=============================================================================
    # Nature
    #=============================================================================
    def tribes
        if hasAbility?(:FRIENDTOALL) || hasItem?(:WILDCARD)
            list = []
            GameData::Tribe.each do |tribeData|
                list.push(tribeData.id)
            end
            return list
        end
        fSpecies = GameData::Species.get_species_form(@species, @form)
        return fSpecies.tribes
    end

    def hasTribe?(tribeCheck)
        if tribeCheck.is_a?(Array)
            tribeCheck.each do |tribeToCheck|
                return true if tribes.include?(tribeToCheck)
            end
            return false
        else
            return tribes.include?(tribeCheck)
        end
    end

    #=============================================================================
    # Nature
    #=============================================================================
    # @return [GameData::Nature, nil] a Nature object corresponding to this Pokémon's nature
    def nature
        @nature = GameData::Nature.get(0).id # ALWAYS RETURN NEUTRAL
        return GameData::Nature.try_get(@nature)
    end

    def nature_id
        return @nature
    end

    # Sets this Pokémon's nature to a particular nature.
    # @param value [Symbol, String, Integer, nil] nature to change to
    def nature=(value)
        return if value && !GameData::Nature.exists?(value)
        @nature = value ? GameData::Nature.get(value).id : value
        calc_stats unless @nature_for_stats
    end

    # Returns the calculated nature, taking into account things that change its
    # stat-altering effect (i.e. Gen 8 mints). Only used for calculating stats.
    # @return [GameData::Nature, nil] this Pokémon's calculated nature
    def nature_for_stats
        return GameData::Nature.try_get(@nature_for_stats) if @nature_for_stats
        return nature
    end

    def nature_for_stats_id
        return @nature_for_stats
    end

    # If defined, this Pokémon's nature is considered to be this when calculating stats.
    # @param value [Integer, nil] ID of the nature to use for calculating stats
    def nature_for_stats=(value)
        return if value && !GameData::Nature.exists?(value)
        @nature_for_stats = value ? GameData::Nature.get(value).id : value
        calc_stats
    end

    # Returns whether this Pokémon has a particular nature. If no value is given,
    # returns whether this Pokémon has a nature set.
    # @param check_nature [Integer] nature ID to check
    # @return [Boolean] whether this Pokémon has a particular nature or a nature
    #   at all
    def hasNature?(check_nature = nil)
        return !@nature_id.nil? if check_nature.nil?
        return nature == check_nature
    end

    #=============================================================================
    # Items
    #============================================================================
    def items
        if @items.nil?
            @items = []
            @items.push(@item) if @item
        end
        @items.compact!
        return @items
    end

    def itemCount
        return items.length
    end

    def itemCountD(uppercase = false)
        if items.length <= 1
            return uppercase ? _INTL("Item") : _INTL("item")
        else
            return uppercase ? _INTL("Items") : _INTL("items")
        end
    end

    def itemsName
        itemName = ""
        items.each_with_index do |item, index|
            itemName += ", " unless index == 0
            itemName += getItemName(item)
        end
        return itemName
    end

    def firstItem
        return nil if items.empty?
        return items[0]
    end

    def firstItemData
        return GameData::Item.try_get(firstItem)
    end

    # Gives an item to this Pokémon to hold.
    # @param value [Symbol, GameData::Item, Integer, nil] ID of the item to give
    #   to this Pokémon
    def setItems(value)
        if value.nil?
            @items = []
        elsif value.is_a?(Array)
            @items = value.clone
        else
            @items = [value]
        end
    end

    def giveItem(value)
        items.push(value)
    end

    def removeItem(item)
        itemIndex = items.index(item)
        unless itemIndex
            raise _INTL("Error: Asked to remove item #{item} from Pokemon #{name}, but it doesn't have that item")
        end
        items.delete_at(itemIndex)
    end

    def removeItems
        @items = []
    end

    # Returns whether this Pokémon is holding an item. If an item id is passed,
    # returns whether the Pokémon is holding that item.
    # @param check_item [Symbol, GameData::Item, Integer] item ID to check
    # @return [Boolean] whether the Pokémon is holding the specified item or
    #   an item at all
    def hasItem?(check_item = nil)
        return !@items.empty? if check_item.nil?
        return items.include?(check_item)
    end

    # @return [Array<Symbol>] the items this species can be found holding in the wild
    def wildHoldItems
        sp_data = species_data
        return [sp_data.wild_item_common, sp_data.wild_item_uncommon, sp_data.wild_item_rare]
    end

    def wildHeldItemsWithRarities
        return species_data.wildHeldItemsWithRarities
    end

    # The type chosen for items like Memory Set or Prismatic Plate which can be
    # customized depending on the pokemon
    def itemTypeChosen
        @itemTypeChosen = :NORMAL if @itemTypeChosen.nil?
        return @itemTypeChosen
    end

    def hasTypeSetterItem?
        items.each do |itemID|
            return itemID if GameData::Item.get(itemID).is_type_setting?
        end
        return nil
    end

    def canHaveMultipleItems?
        return GameData::Ability.get(@ability).is_multiple_item_ability?
    end

    def canHaveItem?(itemCheck, showMessages = false)
        if itemCheck == :CRYSTALVEIL && hasAbility?(:WONDERGUARD)
            pbMessage(_INTL("{1} can't hold a {2}!", name, getItemName(:CRYSTALVEIL))) if showMessages
            return false
        end
        return true
    end

    def canHaveSecondItem?(itemCheck = nil, showMessages = false)
        return false unless canHaveItem?(itemCheck, showMessages)
        return true if firstItem.nil?
        return false unless canHaveMultipleItems?
        return true if itemCheck.nil?
        theoreticalItems = items.clone.push(itemCheck)
        return legalItems?(theoreticalItems, showMessages)
    end

    def legalItems?(itemSet, showMessages = false)
        itemSet.each do |item|
            return false unless canHaveItem?(item, showMessages)
        end

        # Pokemon can always hold 1 item
        return true unless itemSet.length > 1

        # Only pokemon with multiple item abilities can hold more than 1 item
        return false unless GameData::Ability.get(@ability).is_multiple_item_ability?

        # Item sets cannot contain duplicates
        if itemSet.length != itemSet.uniq.length
            pbMessage(_INTL("{1} can't hold two of the same item!", getItemName(:CRYSTALVEIL))) if showMessages
            return false
        end

        # No multiple item abilities allow holding more than 2 items
        if itemSet.length > 2
            pbMessage(_INTL("{1} can't hold more than two items!", name)) if showMessages
            return false
        end

        # Some abilities restrict which specific items you can have when the Pokemon has 2
        return false if BattleHandlers.triggerDisallowItemSetAbility(ability, self, itemSet, showMessages)

        return true
    end

    def removeInvalidItems
        return unless items
        return if legalItems?(items, ownedByPlayer?)
        if ownedByPlayer?
            pbMessage(_INTL("{1} is no longer allowed to hold its current items.", name))
            if boss?
                removeItems
            else
                pbTakeItemsFromPokemon(self)
            end
        else
            echoln(_INTL("#{name} is not allowed to hold its current items."))
            removeItems
        end
    end

    def hasMultipleItems?
        return items.length > 1
    end

    #=============================================================================
    # Moves
    #=============================================================================

    # @return [Integer] the number of moves known by the Pokémon
    def numMoves
        return @moves.length
    end

    # @param move_id [Symbol, String, Integer] ID of the move to check
    # @return [Boolean] whether the Pokémon knows the given move
    def hasMove?(move_id)
        move_data = GameData::Move.try_get(move_id)
        return false unless move_data
        return @moves.any? { |m| m.id == move_data.id }
    end

    # Returns the list of moves this Pokémon can learn by levelling up.
    # @return [Array<Array<Integer,Symbol>>] this Pokémon's move list, where every element is [level, move ID]
    def getMoveList
        return species_data.level_moves
    end

    # Reset the pokemon's moveset to what a wild pokemon would have at the given level
    def reset_moves(assignedLevel = -1, forceSignatures = false)
        assignedLevel = level if assignedLevel == -1
        # Find all level-up moves that self could have learned
        moveset = getMoveList
        knowable_moves = []
        signature_moves = []
        moveset.each do |m|
            moveID = m[1]
            moveData = GameData::Move.get(moveID)
            # Forces signature moves if they're learnable by the pokemon's level
            if moveData.is_signature? && forceSignatures && m[0] <= level
                signature_moves.push(moveID)
            # Allows other moves only if they're learnable by the given level (which is still usually the pokemon's level)
            elsif m[0] <= assignedLevel
                knowable_moves.push(moveID)
            end
        end
        # Remove duplicates (retaining the latest copy of each move)
        knowable_moves = knowable_moves.concat(signature_moves)
        knowable_moves = knowable_moves.reverse
        knowable_moves |= []
        knowable_moves = knowable_moves.reverse
        # Add all moves
        @moves.clear
        first_move_index = knowable_moves.length - MAX_MOVES
        first_move_index = 0 if first_move_index < 0
        for i in first_move_index...knowable_moves.length
            @moves.push(Pokemon::Move.new(knowable_moves[i]))
        end
    end

    # Silently learns the given move. Will erase the first known move if it has to.
    # @param move_id [Symbol, String, Integer] ID of the move to learn
    def learn_move(move_id, ignoreMax = false)
        move_data = GameData::Move.try_get(move_id)
        return unless move_data
        # Check if self already knows the move; if so, move it to the end of the array
        @moves.each_with_index do |m, i|
            next if m.id != move_data.id
            @moves.push(m)
            @moves.delete_at(i)
            return
        end
        # Move is not already known; learn it
        @moves.push(Pokemon::Move.new(move_data.id))
        # Delete the first known move if self now knows more moves than it should
        @moves.shift if numMoves > MAX_MOVES && !ignoreMax
    end

    # Deletes the given move from the Pokémon.
    # @param move_id [Symbol, String, Integer] ID of the move to delete
    def forget_move(move_id)
        move_data = GameData::Move.try_get(move_id)
        return unless move_data
        @moves.delete_if { |m| m.id == move_data.id }
    end

    # Deletes the move at the given index from the Pokémon.
    # @param index [Integer] index of the move to be deleted
    def forget_move_at_index(index)
        @moves.delete_at(index)
    end

    # Deletes all moves from the Pokémon.
    def forget_all_moves
        @moves.clear
    end

    # Copies currently known moves into a separate array, for Move Relearner.
    def record_first_moves
        clear_first_moves
        @moves.each { |m| @first_moves.push(m.id) }
    end

    # Adds a move to this Pokémon's first moves.
    # @param move_id [Symbol, String, Integer] ID of the move to add
    def add_first_move(move_id)
        move_data = GameData::Move.try_get(move_id)
        @first_moves.push(move_data.id) if move_data && !@first_moves.include?(move_data.id)
    end

    # Removes a move from this Pokémon's first moves.
    # @param move_id [Symbol, String, Integer] ID of the move to remove
    def remove_first_move(move_id)
        move_data = GameData::Move.try_get(move_id)
        @first_moves.delete(move_data.id) if move_data
    end

    # Clears this Pokémon's first moves.
    def clear_first_moves
        @first_moves.clear
    end

    def learnable_moves(skipAlreadyLearned = true)
        species_data = GameData::Species.get(@species)

        pokemonLearnables = []
        species_data.learnable_moves.each do |move|
            next if hasMove?(move) && skipAlreadyLearned
            pokemonLearnables.push(move)
        end

        return pokemonLearnables
    end

    # @param move_id [Symbol, String, Integer] ID of the move to check
    # @return [Boolean] whether the Pokémon is compatible with the given move
    def compatible_with_move?(move_id)
        move_data = GameData::Move.try_get(move_id)
        return false if move_data.nil?
        return learnable_moves.include?(move_data.id)
    end

    # def can_relearn_move?
    #   return false if egg?
    #   this_level = self.level
    #   getMoveList.each { |m| return true if m[0] <= this_level && !hasMove?(m[1]) }
    #   @first_moves.each { |m| return true if !pkmn.hasMove?(m) }
    #   return false
    # end

    #=============================================================================
    # Ribbons
    #=============================================================================

    # @return [Integer] the number of ribbons this Pokémon has
    def numRibbons
        return @ribbons.length
    end

    # @param ribbon [Symbol, String, GameData::Ribbon, Integer] ribbon ID to check for
    # @return [Boolean] whether this Pokémon has the specified ribbon
    def hasRibbon?(ribbon)
        ribbon_data = GameData::Ribbon.try_get(ribbon)
        return ribbon_data && @ribbons.include?(ribbon_data.id)
    end

    # Gives a ribbon to this Pokémon.
    # @param ribbon [Symbol, String, GameData::Ribbon, Integer] ID of the ribbon to give
    def giveRibbon(ribbon)
        ribbon_data = GameData::Ribbon.try_get(ribbon)
        return if !ribbon_data || @ribbons.include?(ribbon_data.id)
        @ribbons.push(ribbon_data.id)
    end

    # Replaces one ribbon with the next one along, if possible. If none of the
    # given ribbons are owned, give the first one.
    # @return [Symbol, nil] ID of the ribbon that was gained
    def upgradeRibbon(*arg)
        for i in 0...arg.length - 1
            this_ribbon_data = GameData::Ribbon.try_get(i)
            next unless this_ribbon_data
            for j in 0...@ribbons.length
                next if @ribbons[j] != this_ribbon_data.id
                next_ribbon_data = GameData::Ribbon.try_get(arg[i + 1])
                next unless next_ribbon_data
                @ribbons[j] = next_ribbon_data.id
                return @ribbons[j]
            end
        end
        first_ribbon_data = GameData::Ribbon.try_get(arg[0])
        last_ribbon_data = GameData::Ribbon.try_get(arg[arg.length - 1])
        if first_ribbon_data && last_ribbon_data && !hasRibbon?(last_ribbon_data.id)
            giveRibbon(first_ribbon_data.id)
            return first_ribbon_data.id
        end
        return nil
    end

    # Removes the specified ribbon from this Pokémon.
    # @param ribbon [Symbol, String, GameData::Ribbon, Integer] ID of the ribbon to remove
    def takeRibbon(ribbon)
        ribbon_data = GameData::Ribbon.try_get(ribbon)
        return unless ribbon_data
        for i in 0...@ribbons.length
            next if @ribbons[i] != ribbon_data.id
            @ribbons[i] = nil
            @ribbons.compact!
            break
        end
    end

    # Removes all ribbons from this Pokémon.
    def clearAllRibbons
        @ribbons.clear
    end

    #=============================================================================
    # Ownership, obtained information
    #=============================================================================

    # Changes this Pokémon's owner.
    # @param new_owner [Owner] the owner to change to
    def owner=(new_owner)
        validate new_owner => Owner
        @owner = new_owner
    end

    # @param trainer [Player, NPCTrainer] the trainer to compare to the original trainer
    # @return [Boolean] whether the given trainer is not this Pokémon's original trainer
    def foreign?(trainer)
        return @owner.id != trainer.id || @owner.name != trainer.name
    end

    # @return [Time] the time when this Pokémon was obtained
    def timeReceived
        return Time.at(@timeReceived)
    end

    # Sets the time when this Pokémon was obtained.
    # @param value [Integer, Time, #to_i] time in seconds since Unix epoch
    def timeReceived=(value)
        @timeReceived = value.to_i
    end

    # @return [Time] the time when this Pokémon hatched
    def timeEggHatched
        return (obtain_method == 1) ? Time.at(@timeEggHatched) : nil
    end

    # Sets the time when this Pokémon hatched.
    # @param value [Integer, Time, #to_i] time in seconds since Unix epoch
    def timeEggHatched=(value)
        @timeEggHatched = value.to_i
    end

    #=============================================================================
    # Other
    #=============================================================================

    # @return [String] the name of this Pokémon
    def name
        return nicknamed? ? @name : speciesName
    end

    # avoid problematic characters for online communication
    def safe_name
      if !name.include?("\\")
        return name
      end
      return speciesName
    end

    # @param value [String] the nickname of this Pokémon
    def name=(value)
        if !value || value.empty? || value == speciesName
            value = nil
        else
            value.gsub!("\%","")
        end
        @name = value
    end

    # @return [Boolean] whether this Pokémon has been nicknamed
    def nicknamed?
        return @name && !@name.empty?
    end

    # @return [String] the species name of this Pokémon
    def speciesName
        return species_data.name
    end

    # @return [Integer] the height of this Pokémon in decimetres (0.1 metres)
    def height
        return species_data.height
    end

    # @return [Integer] the weight of this Pokémon in hectograms (0.1 kilograms)
    def weight
        return species_data.weight
    end

    #=============================================================================
    # Happiness, traits, and likes/dislikes
    #=============================================================================

    PERSONALITY_THRESHOLD_ONE = 50
    PERSONALITY_THRESHOLD_TWO = 150
    PERSONALITY_THRESHOLD_THREE = 200
    PERSONALITY_THRESHOLD_FOUR = 255

    attr_writer :Trait1
    attr_writer :Trait2
    attr_writer :Trait3
    attr_writer :Like
    attr_writer :Dislike

    def trait1
        return nil if @happiness < PERSONALITY_THRESHOLD_ONE
        @Trait1 = GameData::Trait.getRandomTrait while @Trait1.nil? || @Trait1 == @Trait2 || @Trait1 == @Trait3
        return @Trait1
    end

    def displayTrait1
        return _INTL("Unknown") unless trait1
        return trait1.name if trait1.respond_to?("name")
        return trait1
    end

    def trait2
        return nil if @happiness < PERSONALITY_THRESHOLD_TWO
        @Trait2 = GameData::Trait.getRandomTrait while @Trait2.nil? || @Trait2 == @Trait1 || @Trait2 == @Trait3
        return @Trait2
    end

    def displayTrait2
        return _INTL("Unknown") unless trait2
        return trait2.name if trait2.respond_to?("name")
        return trait2
    end

    def trait3
        return nil if @happiness < PERSONALITY_THRESHOLD_THREE
        @Trait3 = GameData::Trait.getRandomTrait while @Trait3.nil? || @Trait3 == @Trait1 || @Trait3 == @Trait2
        return @Trait3
    end

    def displayTrait3
        return _INTL("Unknown") unless trait3
        return trait3.name if trait3.respond_to?("name")
        return trait3
    end

    def like
        return nil if @happiness < PERSONALITY_THRESHOLD_FOUR
        @Like = GameData::Like.getRandomLike while @Like.nil? || @Like == @Dislike
        return @Like
    end

    def displayLike
        return _INTL("Unknown") unless like
        return like.name if like.respond_to?("name")
        return like
    end

    def dislike
        return nil if happiness < PERSONALITY_THRESHOLD_FOUR
        @Dislike = GameData::Dislike.getRandomDislike while @Dislike.nil? || @Dislike == @Like
        return @Dislike
    end

    def displayDislike
        return _INTL("Unknown") unless dislike
        return dislike.name if dislike.respond_to?("name")
        return dislike
    end

    def resetPersonality
        @Trait1 = nil
        @Trait2 = nil
        @Trait3 = nil
        @Like = nil
        @Dislike = nil
    end

    # Changes the happiness of this Pokémon depending on what happened to change it.
    # @param method [String] the happiness changing method (e.g. 'walking')
    def changeHappiness(method)
        @happiness = @happiness.clamp(0, MAX_HAPPINESS)

        closenessModifier = 1 + pbQuantity(:SOOTHECHARM)

        gain = 0
        case method
        when "walking"
            gain = 1 * closenessModifier
        when "candylevelup"
            gain = 2
        when "levelup"
            gain = 4 * closenessModifier
        when "evolution"
            gain = 15
        when "groom"
            gain = 8 * closenessModifier
        when "sweetheart"
            gain = 5
        when "interaction"
            gain = 3 * closenessModifier
        end

        if gain > 0
            gain *= 2 if @poke_ball == :LUXURYBALL
            gain *= 2 if hasItem?(:SOOTHEBELL)
        end

        prevHappiness = @happiness
        @happiness = (@happiness + gain).clamp(0, MAX_HAPPINESS)
        actualGain = @happiness - prevHappiness

        # echoln("Changing #{name}'s happiness by #{actualGain}") if actualGain != 0

        return if $Options.show_trait_unlocks == 1

        traitUnlocked = nil
        likeUnlocked = nil
        dislikeUnlocked = nil
        ordinal = ""
        if prevHappiness < PERSONALITY_THRESHOLD_ONE && @happiness >= PERSONALITY_THRESHOLD_ONE
            traitUnlocked = trait1
            ordinal = "first"
        elsif prevHappiness < PERSONALITY_THRESHOLD_TWO && @happiness >= PERSONALITY_THRESHOLD_TWO
            traitUnlocked = trait2
            ordinal = "second"
        elsif prevHappiness < PERSONALITY_THRESHOLD_THREE && @happiness >= PERSONALITY_THRESHOLD_THREE
            traitUnlocked = trait3
            ordinal = "final"
        elsif prevHappiness < PERSONALITY_THRESHOLD_FOUR && @happiness >= PERSONALITY_THRESHOLD_FOUR
            likeUnlocked = like
            dislikeUnlocked = dislike
        end

        if !traitUnlocked.nil?
            msgwindow = pbCreateMessageWindow
            traitName = traitUnlocked.is_a?(String) ? traitUnlocked : traitUnlocked.name
            pbMessageDisplay(msgwindow,
    _INTL("\\wm{1} is happy enough to show off its {2} trait: {3}!\\me[Egg get]\\wtnp[80]\1", name, ordinal, traitName))
            pbDisposeMessageWindow(msgwindow)
        elsif !likeUnlocked.nil? && !dislikeUnlocked.nil?
            msgwindow = pbCreateMessageWindow
            pbMessageDisplay(msgwindow, _INTL("\\wm{1} is at maximum happiness! It loves you so much!\1", name))
            likeName = likeUnlocked.is_a?(String) ? likeUnlocked : likeUnlocked.name
            dislikeName = dislikeUnlocked.is_a?(String) ? dislikeUnlocked : dislikeUnlocked.name
            pbMessageDisplay(msgwindow,
    _INTL("\\wm{1} reveals that it likes {2} and that it dislikes {3}!\\me[Egg get]\\wtnp[100]\1", name, likeName,
  dislikeName))
            pbDisposeMessageWindow(msgwindow)
        end
    end

    #=============================================================================
    # Evolution checks
    #=============================================================================
    # Checks whether this Pokemon can evolve because of levelling up.
    # @return [Symbol, nil] the ID of the species to evolve into
    def check_evolution_on_level_up(finalCheck = true)
        return check_evolution_internal do |pkmn, new_species, method, parameter|
            success = GameData::Evolution.get(method).call_level_up(pkmn, parameter, finalCheck)
            next success ? new_species : nil
        end
    end

    # Checks whether this Pokemon can evolve because of using an item on it.
    # @param item_used [Symbol, GameData::Item, nil] the item being used
    # @return [Symbol, nil] the ID of the species to evolve into
    def check_evolution_on_use_item(item_used,finalCheck = true)
        return check_evolution_internal do |pkmn, new_species, method, parameter|
            success = GameData::Evolution.get(method).call_use_item(pkmn, parameter, item_used, finalCheck)
            next success ? new_species : nil
        end
    end

    # Checks whether this Pokemon can evolve because of being traded.
    # @param other_pkmn [Pokemon] the other Pokémon involved in the trade
    # @return [Symbol, nil] the ID of the species to evolve into
    def check_evolution_on_trade(other_pkmn)
        return check_evolution_internal do |pkmn, new_species, method, parameter|
            success = GameData::Evolution.get(method).call_on_trade(pkmn, parameter, other_pkmn)
            next success ? new_species : nil
        end
    end

    # Called after this Pokémon evolves, to remove its held item (if the evolution
    # required it to have a held item) or duplicate this Pokémon (Shedinja only).
    # @param new_species [Pokemon] the species that this Pokémon evolved into
    def action_after_evolution(new_species)
        species_data.get_evolutions(true).each do |evo| # [new_species, method, parameter]
            break if GameData::Evolution.get(evo[1]).call_after_evolution(self, evo[0], evo[2], new_species)
        end
    end

    # The core method that performs evolution checks. Needs a block given to it,
    # which will provide either a GameData::Species ID (the species to evolve
    # into) or nil (keep checking).
    # @return [Symbol, nil] the ID of the species to evolve into
    def check_evolution_internal
        return nil if egg?
        return nil if hasItem?(:EVERSTONE)
        return nil if hasItem?(:EVIOLITE)
        species_data.get_evolutions(true).each do |evo| # [new_species, method, parameter, boolean]
            next if evo[3] # Prevolution
            ret = yield self, evo[0], evo[1], evo[2] # pkmn, new_species, method, parameter
            return ret if ret
        end
        return nil
    end

    #=============================================================================
    # Stat calculations
    #=============================================================================

    # @return [Hash<Integer>] this Pokémon's base stats, a hash with six key/value pairs
    def baseStats(overloadingSpecies = nil)
        speciesData = overloadingSpecies.nil? ? species_data : GameData::Species.get(overloadingSpecies)
        this_base_stats = speciesData.base_stats
        ret = {}
        GameData::Stat.each_main { |s| ret[s.id] = this_base_stats[s.id] }
        return ret
    end

    # @return [Integer] the maximum HP of this Pokémon
    def calcHP(base, level, iv, ev)
        return 1 if base == 1 # For Shedinja
        return ((base * 2 + iv + (ev / 4)) * level / 100).floor + level + 10
    end

    # @return [Integer] the specified stat of this Pokémon (not used for total HP)
    def calcStat(base, level, iv, ev, nat)
        return ((((base * 2 + iv + (ev / 4)) * level / 100).floor + 5) * nat / 100).floor
    end

    # Recalculates this Pokémon's stats.
    def calc_stats
        stats = getCalculatedStats
        hpDiff = @totalhp - @hp
        @totalhp = stats[:HP]
        @hp      = (fainted? ? 0 : (@totalhp - hpDiff))
        @attack  = stats[:ATTACK]
        @defense = stats[:DEFENSE]
        @spatk   = stats[:SPECIAL_ATTACK]
        @spdef   = stats[:SPECIAL_DEFENSE]
        @speed   = stats[:SPEED]
    end

    def getCalculatedStats(overloadingSpecies = nil)
        base_stats = baseStats(overloadingSpecies)
        this_level = level
        # Calculate stats
        stats = {}
        stylish = hasAbility?(:STYLISH)
        accumulation = hasAbility?(:ACCUMULATION)
        GameData::Stat.each_main do |s|
            isHP = s.id == :HP
            statValue = calcStatGlobal(base_stats[s.id], this_level, @ev[s.id], hp: isHP, stylish: stylish, accumulation: accumulation)
            statValue = (statValue * hpMult).ceil if isHP
            stats[s.id] = statValue
        end
        return stats
    end

    #=============================================================================
    # Boss pokemon
    #=============================================================================
    def boss?
        return boss
    end

    #=============================================================================
    # Color shifting
    #=============================================================================
    def shiny_variant?
        return shiny_variant
    end

    def hueShift
        return @manual_hue_shift if @manual_hue_shift
        id = aestheticsID
        shift = 0
        shift = (-(HUE_SHIFT_RANGE / 2.0) + (id % HUE_SHIFT_RANGE)).round if HUE_SHIFT_RANGE > 0 && id != 0
        return shift
    end

    def shadeShift
        return @manual_shade_shift if @manual_shade_shift
        id = aestheticsID
        shift = 0
        if SHADE_SHIFT_RANGE > 0 && id != 0
            shift = (-(SHADE_SHIFT_RANGE / 2.0) + ((id ^ 65_970_697) % SHADE_SHIFT_RANGE)).round
        end
        return shift
    end

    #=============================================================================
    # Pokémon creation
    #=============================================================================

    # Creates a copy of this Pokémon and returns it.
    # @return [Pokemon] a copy of this Pokémon
    def clone
        ret = super
        ret.ev = {}
        GameData::Stat.each_main do |s|
            ret.ev[s.id] = @ev[s.id]
        end
        ret.moves = []
        @moves.each_with_index { |m, i| ret.moves[i] = m.clone }
        ret.first_moves = @first_moves.clone
        ret.owner       = @owner.clone
        ret.ribbons     = @ribbons.clone
        return ret
    end

    # Creates a new Pokémon object.
    # @param species [Symbol, String, Integer] Pokémon species
    # @param level [Integer] Pokémon level
    # @param owner [Owner, Player, NPCTrainer] Pokémon owner (the player by default)
    # @param withMoves [TrueClass, FalseClass] whether the Pokémon should have moves
    # @param rechech_form [TrueClass, FalseClass] whether to auto-check the form
    def initialize(species, level, owner = $Trainer, withMoves = true, recheck_form = true)
        species_data = GameData::Species.get(species)
        @species          = species_data.species
        @form             = species_data.form
        @forced_form      = nil
        @time_form_set    = nil
        self.level        = level
        @steps_to_hatch   = 0
        heal_status
        @gender           = nil
        @shiny            = nil
        @ability_index    = nil
        @ability          = nil
        @extraAbilities   = []
        @nature           = nil
        @nature_for_stats = nil
        @items            = []
        @moves            = []
        reset_moves if withMoves
        @first_moves      = []
        @ribbons          = []
        @cool             = 0
        @beauty           = 0
        @cute             = 0
        @smart            = 0
        @tough            = 0
        @sheen            = 0
        @name             = nil
        @happiness        = species_data.happiness
        @poke_ball        = :POKEBALL
        @markings         = 0
        @ev               = {}
        GameData::Stat.each_main do |s|
            @ev[s.id] = DEFAULT_STYLE_VALUE
        end
        if owner.is_a?(Owner)
            @owner = owner
        elsif owner.is_a?(Player) || owner.is_a?(NPCTrainer)
            @owner = Owner.new_from_trainer(owner)
        else
            @owner = Owner.new(0, "", 2, 2)
        end
        @obtain_method    = 0 # Met
        @obtain_method    = 4 if $game_switches && $game_switches[Settings::FATEFUL_ENCOUNTER_SWITCH]
        @obtain_map       = $game_map ? $game_map.map_id : 0
        @obtain_text      = nil
        @obtain_level     = level
        @hatched_map      = 0
        @timeReceived     = Time.now.to_i
        @timeEggHatched   = nil
        @fused            = nil
        regeneratePersonalID
        @hp               = 1
        @totalhp          = 1
        @hpMult = 1
        @dmgMult = 1
        @dmgResist = 0
        @extraMovesPerTurn = 0
        @battlingStreak = 0
        @bossType = nil
        @bossVersion = 0
        calc_stats
        if @form == 0 && recheck_form
            f = MultipleForms.call("getFormOnCreation", self)
            if f
                self.form = f
                reset_moves if withMoves
            end
        end
        @extraTypes = []

        @manual_hue_shift = nil
        @manual_shade_shift = nil

        # Set the number of shiny rolls
        @shinyRolls = 1
        $PokemonBag.pbQuantity(:SHINYCHARM).times do
            @shinyRolls *= 2
        end

        # Give it however many chances to be shiny
        (@shinyRolls - 1).times do
            break if shiny?
            regeneratePersonalID
            @shiny = nil
        end
    end

    def aestheticsID
        if ownedByPlayer?
            return @personalID ^ @owner.id
        else
            return hash32Bit(@owner.name + name)
        end
    end

    def regeneratePersonalID
        @personalID = rand(2**16) | rand(2**16) << 16
    end

    def poke_ball
        if @poke_ball == :BALLLAUNCHER
            return :POKEBALL
        else
            return @poke_ball
        end
    end

    def switchBall
        currentBallData = GameData::Item.get(@poke_ball)  
        if currentBallData.no_ball_swap?
            pbMessage(_INTL("If you switch {1}'s ball, its current {2} will be thrown away.",name,currentBallData.name))
            return unless pbConfirmMessageSerious(_INTL("Are you okay with throwing away the {1}?",currentBallData.name))
        end
        pbMessage(_INTL("Choose the Poké Ball to put {1} into.",name))
        pbChoosePokeball(1)
        itemID = pbGet(1)
        currentBallName = getItemName(poke_ball)
        unless itemID == :NONE
            newBallData = GameData::Item.get(itemID)  
            newBallName = newBallData.name
            if itemID == @poke_ball
                pbMessage(_INTL("{1} is already inside of a {2}!",name,newBallName))
                return
            elsif newBallData.no_ball_swap?
                pbMessage(_INTL("A {1} is too special to swap {2} into.",newBallName,name))
            else
                pbMessage(_INTL("You remove {1} from the {2}, and throw it away.",name,currentBallName))
                if itemID == :BALLLAUNCHER
                    pbMessage(_INTL("You bring out the {1}, and launch a ball at {2}!",newBallName,name))
                else
                    pbMessage(_INTL("You bring out a {1}, and put {2} into it!",newBallName,name))
                    pbDeleteItem(itemID)
                end
                pbSEPlay("Battle catch click")
                @poke_ball = itemID
            end
        else
            pbMessage(_INTL("You decide to keep {1} in its {2}.",name,currentBallName))
        end
    end
end

def hash32Bit(item)
    offset_basis = 0x811c9dc5
    prime = 16_777_619

    hash = offset_basis
    item.to_s.each_byte do |byte|
        hash *= prime
        hash &= 4_294_967_295
        hash ^= byte
    end

    return hash
end