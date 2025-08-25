$globalEffectIDCounter = 0

module GameData
    class BattleEffect
        attr_reader :id, :id_number, :real_name, :resets_eor, :tick_amount, :baton_passed

        # The locations are :Battler, :Side, :Field, :Position
        attr_reader :location

        # The types are :Boolean, :Integer, :Position, :Type, :Pokemon, :Move, :Item,
        # :Species, :PartyPosition, :Ability, :Hash, :String, :Array
        # If the type isn't included in an effect definition, its assumed to be a boolean
        attr_reader :type

        # Don't set the default to nil, will be overwritten
        attr_reader :default

        # The maximum value attainable by the effect before moves and abilities dont increment it anymore
        # Only used for Integers
        attr_reader :maximum

        # Whether or not the effect should be displayed on the battle info menu
        attr_reader :info_displayed

        # An array of other effects to disable at the same time as it
        # Be careful not to create loops with this
        attr_reader :sub_effects

        # Resets to default value when a battler starts their turn (sot = "start of turn")
        attr_reader :resets_battlers_sot

        # Resets to default value when a battler has no ability to continue acting this turn
        # Either when the move ends naturally or is interupted by various effects
        # (eot = "end of turn")
        attr_reader :resets_battlers_eot

        # Resets to default value if the battler's move is cancelled
        attr_reader :resets_on_cancel

        # Resets to default value when the move begins being used
        # This is generally used for effects that track usage counters
        attr_reader :resets_on_move_start

        # Resets to default value when the move begins being used
        # But only if the move is not a special usage
        attr_reader :resets_on_move_start_no_special

        # Avatars purge it from themselves when they transition phases
        # Only used for Battler effects
        attr_reader :avatars_purge

        # If it ticks down at end of round. Only used for integers
        attr_reader :ticks_down

        # When battlers swap position, the effect changes value to point to the correct battler
        # Only used for :Position type effects
        attr_reader :swaps_with_battlers

        # When a new battler is initialized, other battlers effects which point to its index
        # Are reset to their default position
        # Only used for :Position type effects
        attr_reader :others_lose_track

        # When a battler has this effect, and this effect points at another battler
        # and that battler leaves the battlefield, disable the effects in the array stored in disable_effecs_on_exit
        # Only used for :Position type effects
        attr_reader :disable_effects_on_other_exit
        attr_reader :deep_teeth # However, don't do the above if the user has the ability Deep Teeth

        attr_reader :protection_info

        # Bespoke information for type applying spikes
        attr_reader :status_applying_hazard

        # Whether the effect marks the move as being copied
        attr_reader :copied_move_marker

        # Effects an AI battlers willingness to stay in
        attr_reader :stay_in_rating_proc

        # Whether its swapped by the move Court Change
        # Defaults to true
        def court_changed?
            return @court_changed
        end

        ### Queries about if the effect is a category
        # Outrage, etc.
        def multi_turn_tracker?
            return @multi_turn_tracker
        end

        # Mean Look, etc.
        def trapping?
            return @trapping
        end

        # The effects that track the applyer of trapping
        def deep_teeth?
            return @deep_teeth
        end

        # Focus Energy, etc.
        def critical_rate_buff?
            return @critical_rate_buff
        end

        # Fury Cutter, etc.
        def snowballing_move_counter?
            return @snowballing_move_counter
        end

        # For Dancer, etc.
        def copied_move_marker?
            return @copied_move_marker
        end

        # Reflect, etc.
        def is_screen?
            return @is_screen
        end

        # Trick Room, etc
        def is_room?
            return @is_room
        end

        # Spikes, etc.
        def is_hazard?
            return @is_hazard || is_status_hazard?
        end

        # Spikes, etc.
        def is_spike?
            return @is_spike
        end

        # Cured by Mental Herb or similar
        def is_mental?
            return @is_mental
        end

        # Protect, Mat Block, etc.
        def is_protection?
            return !@protection_info.nil? || @protection_effect
        end

        # Poison Spikes, etc.
        def is_status_hazard?
            return !@status_applying_hazard.nil?
        end

        ### Has defined procs

        def has_apply_proc?
            return !@apply_proc.nil?
        end

        def has_disable_proc?
            return !@disable_proc.nil?
        end

        def has_eor_proc?
            return !@eor_proc.nil?
        end

        def has_remain_proc?
            return !@remain_proc.nil?
        end

        def has_expire_proc?
            return !@expire_proc.nil?
        end

        def has_entry_proc?
            return !@entry_proc.nil?
        end

        DATA = {}

        extend ClassMethods
        include InstanceMethods

        def self.load; end
        def self.save; end

        def self.register_effect(location, hash)
            hash[:location] = location
            register(hash)
        end

        def initialize(hash)
            @id = hash[:id]
            @id_number              = $globalEffectIDCounter
            $globalEffectIDCounter += 1
            @real_name              = hash[:real_name]
            @location               = hash[:location]
            @type                   = hash[:type] || :Boolean
            @default                = hash[:default]
            @maximum	= hash[:maximum]
            @info_displayed	= hash.has_key?(:info_displayed) ? hash[:info_displayed] : true
            if @default.nil?
                case @type
                when :Boolean
                    @default = false
                when :Integer
                    @default = 0
                when :Position, :PartyPosition
                    @default = -1
                end
            end
            @resets_eor             = hash[:resets_eor] || false
            @resets_battlers_sot    = hash[:resets_battlers_sot] || false
            @resets_battlers_eot    = hash[:resets_battlers_eot] || false
            @resets_on_cancel       = hash[:resets_on_cancel] || false
            @resets_on_move_start	= hash[:resets_on_move_start] || false
            @resets_on_move_start_no_special = hash[:resets_on_move_start_no_special] || false

            @ticks_down             = hash[:ticks_down] || false
            @tick_amount            = hash[:tick_amount] || 1

            # Called when the battler is initialized
            @initialize_proc        = hash[:initialize_proc]

            # Called when the effect is applied by an action
            @apply_proc             = hash[:apply_proc]

            # Called every round if active.
            @eor_proc               = hash[:eor_proc]

            # Called when the effect is disabled
            @disable_proc			= hash[:disable_proc]

            # Called when the effect is ticks down to its final value
            @expire_proc 			= hash[:expire_proc]

            # Called every end of round, only when ticked down with still turns remaining
            @remain_proc = hash[:remain_proc]

            # Called whenever the event value is incremented (for integers)
            @increment_proc	= hash[:increment_proc]

            # Called whenever a battler enters the position or the side
            @entry_proc	= hash[:entry_proc]

            # If the effect needs custom logic to determing if it should be active or not
            # Instead of using the default values (i.e. Integers active above 0)
            @active_value_proc      = hash[:active_value_proc]

            @baton_passed           = hash[:baton_passed] || false
            @swaps_with_battlers    = hash[:swaps_with_battlers] || false
            # For when the value has to be transformed when baton passed
            @pass_value_proc	= hash[:pass_value_proc]

            @multi_turn_tracker = hash[:multi_turn_tracker] || false
            @trapping	= hash[:trapping] || false
            @critical_rate_buff	= hash[:critical_rate_buff] || false
            @snowballing_move_counter = hash[:snowballing_move_counter] || false

            @others_lose_track = hash[:others_lose_track] || false

            @disable_effects_on_other_exit = hash[:disable_effects_on_other_exit] || []
            @deep_teeth     = hash[:deep_teeth] || false
            @sub_effects	= hash[:sub_effects] || []

            @protection_effect	= hash[:protection_effect] || false
            @protection_info	= hash[:protection_info]
            @court_changed	= hash[:court_changed] || true

            @status_applying_hazard = hash[:status_applying_hazard]

            @is_room	            = hash[:is_room] || false
            @is_screen				= hash[:is_screen] || false
            @is_hazard				= hash[:is_hazard] || false
            @is_mental				= hash[:is_mental] || false
            @is_spike				= hash[:is_spike] || false

            @copied_move_marker     = hash[:copied_move_marker] || false

            @avatars_purge = hash[:avatars_purge] || false

            @stay_in_rating_proc = hash[:stay_in_rating_proc]

            checkForInvalidDefinitions
        end

        def name
            return pbGetMessageFromHash(MessageTypes::BattleEffects, @real_name)
        end

        def checkForInvalidDefinitions
            if @type != :Integer
                raise _INTL("Battle effect #{@id} defines increment proc when its not an integer.") if @increment_proc
                raise _INTL("Battle effect #{@id} defines expire proc when its not an integer.") if @expire_proc
                raise _INTL("Battle effect #{@id} is set to down down, but its not an integer.") if @ticks_down
                raise _INTL("Battle effect #{@id} was given a maximum, but its not an integer.") unless @maximum.nil?
            end
            if @entry_proc && @location != :Position && @location != :Side
                raise _INTL("Battle effect #{@id} defines an entry proc when its not a position or side effect.")
            end
        end

        # Method for determining if the effect is considered active
        def active_value?(value)
            active = false

            unless valid_value?(value)
                raise _INTL("Value #{name} cannot check if the value #{value} is active because its value #{value} is invalid}")
            end

            if @active_value_proc
                active = @active_value_proc.call(value)
            else
                case @type
                when :Boolean
                    active = value
                when :Integer
                    active = value > 0
                when :Position, :PartyPosition
                    active = value >= 0
                when :String
                    active = !value.nil? && !value.blank?
                when :Type, :Pokemon, :Move, :Item, :Ability, :Hash
                    active = !value.nil?
                when :Array
                    active = !value.nil? && !value.empty?
                end
            end
            return active
        end

        def valid_value?(value)
            case @type
            when :Boolean
                return [true, false].include?(value)
            when :Integer
                return value.is_a?(Integer)
            when :Species
                return value.nil? || GameData::Species.exists?(value)
            when :Position
                return true # TODO
            when :PartyPosition
                return value >= -1
            when :Type
                return value.nil? || GameData::Type.exists?(value)
            when :Pokemon
                return value.nil? || value.is_a?(Pokemon)
            when :Move
                return value.nil? || GameData::Move.exists?(value)
            when :Item
                return value.nil? || GameData::Item.exists?(value)
            when :Ability
                return value.nil? || GameData::Ability.exists?(value)
            when :Hash
                return value.nil? || value.is_a?(Hash)
            when :String
                return value.nil? || value.is_a?(String)
            when :Array
                return value.nil? || value.is_a?(Array)
            end
            return false
        end

        def value_to_string(value, battle)
            begin
                case @type
                when :Boolean, :Integer
                    return value.to_s
                when :Species
                    return GameData::Species.get(value).name
                when :Position
                    return battle.battlers[value].name
                when :Type
                    return GameData::Type.get(value).name
                when :Pokemon
                    return value.name
                when :Move
                    return GameData::Move.get(value).name
                when :Item
                    return GameData::Item.get(value).name
                when :Ability
                    return GameData::Ability.get(value).name
                when :String
                    return value
                end
            rescue StandardError
                return "ERROR"
            end
            return ""
        end

        ### Methods dealing with the effect when a battler is initialized
        def initialize_battler(battle, battler)
            @initialize_proc.call(battle, battler) if @initialize_proc
        end

        ### Methods dealing with the effect being newly applied
        def apply_battler(battle, battler)
            value = battler.effects[@id]
            @apply_proc.call(battle, battler, value) if @apply_proc
        end

        def apply_position(battle, index)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            value = position.effects[@id]
            @apply_proc.call(battle, index, position, battler, value) if @apply_proc
        end

        def apply_side(battle, side)
            teamName = battle.battlers[side.index].pbTeam
            value = side.effects[@id]
            @apply_proc.call(battle, side, teamName, value) if @apply_proc
        end

        def apply_field(battle)
            value = battle.field.effects[@id]
            @apply_proc.call(battle, value) if @apply_proc
        end

        ### Methods dealing with the effect going away
        def disable_battler(battle, battler)
            @disable_proc.call(battle, battler) if @disable_proc
        end

        def disable_position(battle, index)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            @disable_proc.call(battle, index, position, battler) if @disable_proc
        end

        def disable_side(battle, side)
            teamName = battle.battlers[side.index].pbTeam
            @disable_proc.call(battle, side, teamName) if @disable_proc
        end

        def disable_field(battle)
            @disable_proc.call(battle) if @disable_proc
        end

        ### Methods dealing with the effect remaining EOT
        def remain_battler(battle, battler)
            value = battler.effects[@id]
            @remain_proc.call(battle, battler, value) if @remain_proc
        end

        def remain_position(battle, index)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            @remain_proc.call(battle, index, position, battler) if @remain_proc
        end

        def remain_side(battle, side)
            teamName = battle.battlers[side.index].pbTeam
            @remain_proc.call(battle, side, teamName) if @remain_proc
        end

        def remain_field(battle)
            @remain_proc.call(battle) if @remain_proc
        end

        ### Methods dealing with the effect going away after ticking down
        def expire_battler(battle, battler)
            @expire_proc.call(battle, battler) if @expire_proc
        end

        def expire_position(battle, index)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            @expire_proc.call(battle, index, position, battler) if @expire_proc
        end

        def expire_side(battle, side)
            teamName = battle.battlers[side.index].pbTeam
            @expire_proc.call(battle, side, teamName) if @expire_proc
        end

        def expire_field(battle)
            @expire_proc.call(battle) if @expire_proc
        end

        ### Methods dealing with effects at the end of each round
        def eor_battler(battle, battler)
            value = battler.effects[@id]
            @eor_proc.call(battle, battler, value) if @eor_proc
        end

        def eor_position(battle, index)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            value = position.effects[@id]
            @eor_proc.call(battle, index, position, battler, value) if @eor_proc
        end

        def eor_side(battle, side)
            teamName = battle.battlers[side.index].pbTeam
            value = side.effects[@id]
            @eor_proc.call(battle, side, teamName, value) if @eor_proc
        end

        def eor_field(battle)
            value = battle.field.effects[@id]
            @eor_proc.call(battle, value) if @eor_proc
        end

        ### Methods dealing with the effect being incremented (call afterwards)
        def increment_battler(battle, battler, increment)
            newValue = battler.effects[@id]
            @increment_proc.call(battle, battler, newValue, increment) if @increment_proc
        end

        def increment_position(battle, index, increment)
            position = battle.positions[index]
            battler = battle.battlers[index]
            return if battler.nil? || battler.fainted?
            newValue = position.effects[@id]
            @increment_proc.call(battle, index, position, battler, newValue, increment) if @increment_proc
        end

        def increment_side(battle, side, increment)
            teamName = battle.battlers[side.index].pbTeam
            newValue = side.effects[@id]
            @increment_proc.call(battle, side, teamName, newValue, increment) if @increment_proc
        end

        def increment_field(battle, increment)
            newValue = battle.field.effects[@id]
            @increment_proc.call(battle, newValue, increment) if @increment_proc
        end

        ### Battler entering
        def entry_position(battle, battlerIndex)
            return unless @entry_proc
            position = battle.positions[battlerIndex]
            battler = battle.battlers[battlerIndex]
            return if battler.nil? || battler.fainted?
            value = battler.effects[@id]
            @entry_proc.call(battle, battlerIndex, position, battler, value)
        end

        def entry_side(battle, battlerIndex, sideIndex)
            return unless @entry_proc
            side = battle.sides[sideIndex]
            battler = battle.battlers[battlerIndex]
            return if battler.nil? || battler.fainted?
            value = side.effects[@id]
            @entry_proc.call(battle, battlerIndex, side, battler, value)
        end

        ### Baton passing
        def baton_pass_value(battler, value)
            if @pass_value_proc
                return @pass_value_proc.call(battler, value)
            else
                return value
            end
        end

        def each_sub_effect(yield_data = false)
            @sub_effects.each do |otherEffect|
                otherEffectData = GameData::BattleEffect.get(otherEffect)
                if yield_data
                    yield otherEffect, otherEffectData
                else
                    yield otherEffect
                end
            end
        end

        ### Iteration methods
        def self.each_battler_effect
            each do |data|
                next if data.location != :Battler
                yield data
            end
        end

        def self.each_position_effect
            each do |data|
                next if data.location != :Position
                yield data
            end
        end

        def self.each_side_effect
            each do |data|
                next if data.location != :Side
                yield data
            end
        end

        def self.each_field_effect
            each do |data|
                next if data.location != :Field
                yield data
            end
        end

        def self.each_effect
            each do |data|
                yield data
            end
        end

        # For translation
        def self.set_effect_names_hash
            effect_names = []
            each_effect do |data|
                effect_names.push(data.real_name)
            end
            MessageTypes.setMessagesAsHash(MessageTypes::BattleEffects, effect_names)
        end
    end
end
