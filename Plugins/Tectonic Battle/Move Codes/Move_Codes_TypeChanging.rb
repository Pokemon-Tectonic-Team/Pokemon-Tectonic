#===============================================================================
# Changes user's type to that of a random user's move, except a type the user
# already has (even partially), OR changes to the user's first move's type.
# (Conversion)
#===============================================================================
class PokeBattle_Move_SetUserTypesToUserMoveType < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.canChangeType?
            @battle.pbDisplay(_INTL("But it failed, since {1} can't have its type changed!", user.pbThis(true)))
            return true
        end
        userTypes = user.pbTypes(true)
        @newTypes = []
        user.eachMoveWithIndex do |m, i|
            break if i > 0
            next if GameData::Type.get(m.type).pseudo_type
            next if userTypes.include?(m.type)
            @newTypes.push(m.type) unless @newTypes.include?(m.type)
        end
        if @newTypes.length == 0
            @battle.pbDisplay(_INTL("But it failed, since there are no valid types for it to choose!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        newType = @newTypes[@battle.pbRandom(@newTypes.length)]
        user.pbChangeTypes(newType)
        typeName = GameData::Type.get(newType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", user.pbThis, typeName))
    end
end

#===============================================================================
# Changes user's type to a random one that resists/is immune to the last move
# used by the target. (Conversion 2)
#===============================================================================
class PokeBattle_Move_SetUserTypesToResistLastAttack < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.canChangeType?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} can't have its types changed!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        if !target.lastMoveUsed || !target.lastMoveUsedType ||
           GameData::Type.get(target.lastMoveUsedType).pseudo_type
            @battle.pbDisplay(_INTL("But it failed!")) if show_message
            return true
        end
        @newTypes = []
        GameData::Type.each do |t|
            next if t.pseudo_type || user.pbHasType?(t.id) ||
                    !Effectiveness.resistant_type?(target.lastMoveUsedType, t.id)
            @newTypes.push(t.id)
        end
        if @newTypes.length == 0
            @battle.pbDisplay(_INTL("But it failed!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        newType = @newTypes[@battle.pbRandom(@newTypes.length)]
        user.pbChangeTypes(newType)
        typeName = GameData::Type.get(newType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", user.pbThis, typeName))
    end
end

#===============================================================================
# Changes user's type depending on the environment. (Camouflage)
#===============================================================================
class PokeBattle_Move_SetUserTypesBasedOnEnvironment < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.canChangeType?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} can't have its types changed!", user.pbThis(true)))
            end
            return true
        end
        camouflageType = getCamouflageType
        unless GameData::Type.exists?(camouflageType)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since the type {1} is supposed to become doesn't exist!", user.pbThis(true)))
            end
            return true
        end
        if user.pbHasOtherType?(camouflageType)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already {2}-type!", user.pbThis(true), GameData::Type.get(camouflageType).name))
            end
            return true
        end
        return false
    end

    def getCamouflageType
        newType = :NORMAL
        case @battle.environment
        when :Grass, :TallGrass
            newType = :GRASS
        when :MovingWater, :StillWater, :Puddle, :Underwater
            newType = :WATER
        when :Cave
            newType = :ROCK
        when :Rock, :Sand
            newType = :GROUND
        when :Forest, :ForestGrass
            newType = :BUG
        when :Snow, :Ice
            newType = :ICE
        when :Volcano
            newType = :FIRE
        when :Graveyard
            newType = :GHOST
        when :Sky
            newType = :FLYING
        when :Space
            newType = :DRAGON
        when :UltraSpace
            newType = :PSYCHIC
        end
        newType = :NORMAL unless GameData::Type.exists?(newType)
        return newType
    end

    def pbEffectGeneral(user)
        newType = getCamouflageType
        user.pbChangeTypes(newType)
        typeName = GameData::Type.get(newType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", user.pbThis, typeName))
    end
end

#===============================================================================
# Target becomes Water type. (Soak)
#===============================================================================
class PokeBattle_Move_SetTargetTypesToWater < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless GameData::Type.exists?(:WATER)
            @battle.pbDisplay(_INTL("But it failed, since the Water-type doesn't exist!")) if show_message
            return true
        end
        unless target.canChangeType?
            @battle.pbDisplay(_INTL("But it failed, since {1} can't change their type!", target.pbThis(true))) if show_message
            return true
        end
        unless target.pbHasOtherType?(:WATER)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already only Water-type!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.pbChangeTypes(:WATER)
        typeName = GameData::Type.get(:WATER).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", target.pbThis, typeName))
    end

    def getEffectScore(_user, _target)
        return 80
    end
end

#===============================================================================
# User copes target's types. (Reflect Type)
#===============================================================================
class PokeBattle_Move_SetUserTypesToTargetTypes < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.canChangeType?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} can't have its types changed!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        newTypes = target.pbTypes(true)
        if newTypes.length == 0 # Target has no type to copy
            @battle.pbDisplay(_INTL("But it failed, since {1} has no types!", target.pbThis(true))) if show_message
            return true
        end
        if user.pbTypes == target.pbTypes && user.effects[:Type3] == target.effects[:Type3]
            @battle.pbDisplay(_INTL("But it failed, since {1} && {2} share the exact same types!", user.pbThis(true), target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        user.pbChangeTypes(target)
        @battle.pbDisplay(_INTL("{1}'s type changed to match {2}'s!",
           user.pbThis, target.pbThis(true)))
    end
end

#===============================================================================
# Target becomes Bug type. (Scale Scatter)
#===============================================================================
class PokeBattle_Move_SetTargetTypesToBug < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless GameData::Type.exists?(:BUG)
            @battle.pbDisplay(_INTL("But it failed, since the Bug-type doesn't exist!")) if show_message
            return true
        end
        unless target.canChangeType?
            @battle.pbDisplay(_INTL("But it failed, since {1} can't change their type!", target.pbThis(true))) if show_message
            return true
        end
        unless target.pbHasOtherType?(:BUG)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already only Bug-type!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.pbChangeTypes(:BUG)
        typeName = GameData::Type.get(:BUG).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", target.pbThis, typeName))
    end

    def getEffectScore(_user, _target)
        return 80
    end
end

#===============================================================================
# The target loses their Water-type before the move strikes. (Dry Heat)
#===============================================================================
class PokeBattle_Move_RemoveTargetWaterType < PokeBattle_Move
    def pbEffectBeforeDealingDamage(user, target)
        if target.pbHasType?(:WATER)
            target.applyEffect(:DryHeat)
            target.damageState.typeMod = pbCalcTypeMod(@calcType, user, target)
        end
    end
end

#===============================================================================
# Gives target the Ghost type. (Trick-or-Treat)
#===============================================================================
class PokeBattle_Move_AddGhostTypeToTarget < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless GameData::Type.exists?(:GHOST)
            @battle.pbDisplay(_INTL("But it failed, since the Ghost-type doesn't exist!")) if show_message
            return true
        end
        if target.pbHasType?(:GHOST)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already Ghost-type!", target.pbThis(true)))
            end
            return true
        end
        unless target.canChangeType?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} can't have its type changed!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Type3, :GHOST)
    end

    def getTargetAffectingEffectScore(_user, _target)
        return 60
    end
end

#===============================================================================
# Gives target the Grass type. (Forest's Curse)
#===============================================================================
class PokeBattle_Move_AddGrassTypeToTarget < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless GameData::Type.exists?(:GRASS)
            @battle.pbDisplay(_INTL("But it failed, since the Grass-type doesn't exist!")) if show_message
            return true
        end
        if target.pbHasType?(:GRASS)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is already Grass-type!", target.pbThis(true)))
            end
            return true
        end
        unless target.canChangeType?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} can't have its type changed!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Type3, :GRASS)
    end

    def getTargetAffectingEffectScore(_user, _target)
        return 60
    end
end

#===============================================================================
# Gives the target the Steel type and reduces its Speed by 4 steps. (Weld)
#===============================================================================
class PokeBattle_Move_AddSteelTypeToTargetLowerTargetSpd4 < PokeBattle_Move
    def pbFailsAgainstTarget?(user, target, show_message)
        unless target.pbCanLowerStatStep?(:SPEED, user, self)
            unless GameData::Type.exists?(:STEEL)
                @battle.pbDisplay(_INTL("But it failed, since the Steel-type doesn't exist and {1}'s Speed can't be lowered!", target.pbThis(true))) if show_message
                return true
            end
            if target.pbHasType?(:STEEL)
                if show_message
                    @battle.pbDisplay(_INTL("But it failed, since {1} is already Steel-type and its Speed can't be lowered!", target.pbThis(true)))
                end
                return true
            end
            unless target.canChangeType?
                if show_message
                    @battle.pbDisplay(_INTL("But it failed, since {1} can't have its type changed and its Speed can't be lowered!", target.pbThis(true)))
                end
                return true
            end
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        target.applyEffect(:Type3, :STEEL)
        target.tryLowerStat(:SPEED, user, move: self, increment: 4, showFailMsg: true)
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        score += 60 unless target.pbHasTypeAI?(:STEEL)
        score += getMultiStatDownEffectScore([:SPEED,4],user,target)
        return score
    end
end

#===============================================================================
# Type changes depending on rotom's form. (Machinate)
# Additional effect changes depending on rotom's form. Only usable by rotom.
#===============================================================================
class PokeBattle_Move_TypeAndEffectDependsOnUserRotomForm < PokeBattle_Move
    def aiAutoKnows?(pokemon); return true; end
    def pbMoveFailed?(user, _targets, show_message)
        unless user.countsAs?(:ROTOM)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbBaseType(user)
        ret = :GHOST
        case user.form
        when 0
            ret = :ELECTRIC if GameData::Type.exists?(:ELECTRIC)
        when 1
            ret = :FIRE if GameData::Type.exists?(:FIRE)
        when 2
            ret = :WATER if GameData::Type.exists?(:WATER)
        when 3
            ret = :ICE if GameData::Type.exists?(:ICE)
        when 4
            ret = :FLYING if GameData::Type.exists?(:FLYING)
        when 5
            ret = :GRASS if GameData::Type.exists?(:GRASS)
        end
        return ret
    end

    def pbAdditionalEffect(user, target)
        return if target.damageState.substitute
        case user.form
        when 0
            target.applyNumb(user) if target.canNumb?(user, true, self)
        when 1
            target.applyBurn(user) if target.canBurn?(user, true, self)
        when 2
            target.applyWaterlog(user) if target.canWaterlog?(user, true, self)
        when 3
            target.applyFrostbite(user) if target.canFrostbite?(user, true, self)
        when 4
            target.applyDizzy(user) if target.canDizzy?(user, true, self)
        when 5
            target.applyLeeched(user) if target.canLeech?(user, true, self)
        end
    end

    def getTargetAffectingEffectScore(user, target)
        case user.form
        when 0
            return getNumbEffectScore(user, target)
        when 1
            return getBurnEffectScore(user, target)
        when 2
            return getWaterlogEffectScore(user, target)
        when 3
            return getFrostbiteEffectScore(user, target)
        when 4
            return getDizzyEffectScore(user, target)
        when 5
            return getLeechEffectScore(user, target)
        end
        return 0
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Form effects:")
        detailsList << _INTL("<u>No Machine</u>: Numb")
        detailsList << _INTL("<u>Heat</u>: Burn")
        detailsList << _INTL("<u>Wash</u>: Waterlog")
        detailsList << _INTL("<u>Frost</u>: Frostbite")
        detailsList << _INTL("<u>Fan</u>: Dizzy")
        detailsList << _INTL("<u>Mow</u>: Leech")
    end
end

#===============================================================================
# Target becomes your choice of Dragon, Fairy, or Steel type. (Regalia)
#===============================================================================
class PokeBattle_Move_SetTargetTypesToChoiceOfDragonFairySteel < PokeBattle_Move
    def resolutionChoice(user)
        validTypes = %i[DRAGON FAIRY STEEL]
        validTypeNames = []
        validTypes.each do |typeID|
            validTypeNames.push(GameData::Type.get(typeID).name)
        end
        if validTypes.length == 1
            @chosenType = validTypes[0]
        elsif validTypes.length > 1
            if @battle.autoTesting
                @chosenType = validTypes.sample
            elsif !user.pbOwnedByPlayer? # Trainer AI
                @chosenType = validTypes[0]
            else
                chosenIndex = @battle.scene.pbShowCommands(_INTL("Which type should {1} gift?", user.pbThis(true)),validTypeNames,0)
                @chosenType = validTypes[chosenIndex]
            end
        end
    end

    def pbFailsAgainstTarget?(_user, target, show_message)
        unless GameData::Type.exists?(@chosenType)
            @battle.pbDisplay(_INTL("But it failed, since the chosen type doesn't exist!")) if show_message
            return true
        end
        unless target.canChangeType?
            @battle.pbDisplay(_INTL("But it failed, since {1} can't change their type!", target.pbThis(true))) if show_message
            return true
        end
        unless target.pbHasOtherType?(@chosenType)
            @battle.pbDisplay(_INTL("But it failed, since {1} is already only the chosen type!", target.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbFailsAgainstTargetAI?(_user, target)
        @chosenType = :DRAGON
        return pbFailsAgainstTarget?(_user, target, false)
    end

    def pbEffectAgainstTarget(_user, target)
        target.pbChangeTypes(@chosenType)
        typeName = GameData::Type.get(@chosenType).name
        @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", target.pbThis, typeName))
    end

    def resetMoveUsageState
        @chosenType = nil
    end

    def getEffectScore(_user, _target)
        return 80
    end
end