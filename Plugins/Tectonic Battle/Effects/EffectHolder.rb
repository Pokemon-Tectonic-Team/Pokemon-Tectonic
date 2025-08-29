# This assumes that each user of the module has an instance variable called @effects
# and a reference to the battle called @battle, and a variable called @location
# You must also define procs called @apply_proc, @disable_proc, @expire_proc, @remain_proc, and @increment_proc
module EffectHolder
    #################################################
    # Modify effect values
    #################################################

    def applyEffect(effect, value = nil)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        if value.nil?
            if effectData.type == :Boolean
                value = true
            else
                raise _INTL("Value must be provided when applying effect #{effectData.name} (it's not a boolean)")
            end
        elsif !effectData.valid_value?(value)
            raise _INTL("Value #{value} provided to apply for effect #{effectData.name} is invalid")
        elsif value == effectData.default
            raise _INTL("Value #{value} provided to apply for effect #{effectData.name} is its default value")
        end
        if @effects[effect] == value
            echoln(_INTL("[EFFECT] Effect #{effectData.name} set to apply, but at existing value #{@effects[effect]}"))
        else
            @effects[effect] = value
            @apply_proc.call(effectData, value)
        end
    end

    def pointAt(effect, battler)
        validateCorrectLocation(effect)
        validatePosition(effect)
        applyEffect(effect, battler.index)
    end

    def incrementEffect(effect, incrementAmount = 1)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        validateInteger(effectData)
        oldValue = @effects[effect]
        newValue = oldValue + incrementAmount
        if effectData.maximum && newValue > effectData.maximum
            echoln("[EFFECT] Effect incremented while already at maximum: #{effectData.real_name}")
            return oldValue
        else
            @effects[effect] = newValue
            @increment_proc.call(effectData, incrementAmount)
            return newValue
        end
    end

    # Returns true if the value did not expire, false if it did
    def tickDownAndProc(effect)
        validateCorrectLocation(effect)
        data = getData(effect)
        if effectActive?(effect)
            if tickDown(effect)
                echoln("Effect #{data.real_name} expires after ticking down")
                @expire_proc.call(data)
                disableEffect(effect)
                return false
            else
                @remain_proc.call(data)
                return true
            end
        end
    end

    # Returns true if the value is either already at the goal or is at the goal after ticking down
    # otherwise false
    def tickDown(effect, goal = nil)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        validateInteger(effectData)
        goal = effectData.default if goal.nil?
        return true if @effects[effect] <= goal
        @effects[effect] = [@effects[effect] - 1, goal].max
        return true if @effects[effect] <= goal
    end

    def disableEffect(effect)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        if effectData.active_value?(@effects[effect])
            @effects[effect] = effectData.default
            @disable_proc.call(effectData)
        end
        effectData.each_sub_effect(true) do |otherEffect, otherData|
            next unless otherData.active_value?(@effects[otherEffect])
            @effects[otherEffect] = otherData.default
            @disable_proc.call(otherData)
        end
    end

    #################################################
    # Get information about effects
    #################################################

    def effectActive?(effect)
        if effect.is_a?(Array)
            effect.each do |individualEffect|
                return true if effectActive?(individualEffect)
            end
            return false
        else
            validateCorrectLocation(effect)
            effectData = GameData::BattleEffect.get(effect)

            unless @effects.has_key?(effect)
                echoln(@effects.to_s)
                raise _INTL("Cannot check if effect #{effectData.name} is active because it has no entry in the effect hash")
            end

            return effectData.active_value?(@effects[effect])
        end
    end

    def countEffect(effect)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        validateInteger(effectData)
        return @effects[effect]
    end

    def pointsAt?(effect, battler)
        validateCorrectLocation(effect)
        validatePosition(effect)
        return false unless effectActive?(effect)
        return @effects[effect] == battler.index
    end

    def eachEffectPointsAt(_onlyActive = false.battler)
        validateCorrectLocation(effect)
        eachEffect(true) do |effect, value, data|
            yield effect, value, data if pointsAt?(effect, battler)
        end
    end

    def getBattlerPointsTo(effect)
        validateCorrectLocation(effect)
        validatePosition(effect)
        return nil unless effectActive?(effect)
        return @battle.battlers[@effects[effect]]
    end

    def getMoveData(effect)
        validateCorrectLocation(effect)
        validateMove(effect)
        return GameData::Move.get(@effects[effect])
    end

    def getName(effect)
        validateCorrectLocation(effect)
        return getData(effect).name
    end

    def effectAtMax?(effect)
        validateCorrectLocation(effect)
        effectData = GameData::BattleEffect.get(effect)
        validateInteger(effectData)
        return false if effectData.maximum.nil?
        value = @effects[effect]
        raise _INTL("Effect above maximum: #{effectData.name}") if value > effectData.maximum
        return value == effectData.maximum
    end

    #################################################
    # Iterate through effects
    #################################################

    def eachEffect(onlyActive = false)
        @effects.each do |effect, value|
            next if onlyActive && !effectActive?(effect)
            effectData = GameData::BattleEffect.get(effect)
            yield effect, value, effectData
        end
    end

    def processEffectsEOR
        eachEffect(true) do |effect, value, data|
            # Active end of round effects
            @eor_proc.call(data)
            # Tick down active effects that tick down
            tickDownAndProc(effect) if data.ticks_down?(@battle, value)
            # Disable effects that reset end of round
            disableEffect(effect) if data.resets_eor
        end
    end

    #################################################
    # Validate data types
    #################################################
    def getData(dataOrEffect)
        return dataOrEffect if dataOrEffect.is_a?(GameData::BattleEffect)
        return GameData::BattleEffect.get(dataOrEffect)
    end

    def validateCorrectLocation(effect)
        if getData(effect).location != @location
            raise _INTL("Effect #{effect} is not appropriate for location #{@location}")
        end
    end

    def validateInteger(effect)
        raise _INTL("Invalid operation for non-integer effect #{effect}") if getData(effect).type != :Integer
    end

    def validatePosition(effect)
        raise _INTL("Invalid operation for non-position effect #{effect}") if getData(effect).type != :Position
    end

    def validateMove(effect)
        raise _INTL("Invalid operation for non-move effect #{effect}") if getData(effect).type != :Move
    end
end
