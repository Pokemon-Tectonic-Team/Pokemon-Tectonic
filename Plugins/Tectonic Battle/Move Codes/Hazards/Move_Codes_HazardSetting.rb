#===============================================================================
# Entry hazard. Lays spikes on the opposing side. (Spikes)
#===============================================================================
class PokeBattle_Move_Spikes < PokeBattle_Move
    def hazardMove?; return true; end
    def aiAutoKnows?(pokemon); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.pbOpposingSide.effectAtMax?(:Spikes)
            @battle.pbDisplay(_INTL("But it failed, since there is no room for more Spikes!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        user.pbOpposingSide.incrementEffect(:Spikes)
    end

    def pbEffectAgainstTarget(_user, target)
        return unless damagingMove?
        return if target.pbOwnSide.effectAtMax?(:Spikes)
        target.pbOwnSide.incrementEffect(:Spikes)
    end

    def getEffectScore(user, target)
        return 0 if damagingMove? && target.pbOwnSide.effectAtMax?(:Spikes)
        return getHazardSettingEffectScore(user, target)
    end
end

#===============================================================================
# Sets spikes, but only if none are present. (Ceaseless Edge)
#===============================================================================
class PokeBattle_Move_SpikesFirstLayerOnly < PokeBattle_Move_Spikes
    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.pbOpposingSide.effectAtMax?(:Spikes)
            @battle.pbDisplay(_INTL("But it failed, since there's already one layer of Spikes!")) if show_message
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(_user, target)
        return unless damagingMove?
        return if target.pbOwnSide.countEffect(:Spikes) > 0
        target.pbOwnSide.incrementEffect(:Spikes)
    end

    def getEffectScore(user, target)
        return 0 if damagingMove? && target.pbOwnSide.countEffect(:Spikes) > 0
        return getHazardSettingEffectScore(user, target)
    end
end

#===============================================================================
# If it faints the target, you set Spikes on the their side of the field. (Impaling Spike)
#===============================================================================
class PokeBattle_Move_SpikesIfTargetFaints < PokeBattle_Move
    def pbEffectAfterAllHits(_user, target)
        return unless target.damageState.fainted
        target.pbOwnSide.incrementEffect(:Spikes)
    end
end

#===============================================================================
# Only usable by Morpeko. Sets Spikes if Full Belly. (Gut Check)
# If Hangry, doubles in damage and deals Dark-type damage.
#===============================================================================
class PokeBattle_Move_GutCheck < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.countsAs?(:MORPEKO)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbBaseDamage(baseDmg, user, _target)
        if user.form == 1
            baseDmg *= 2
        end
        return baseDmg
    end

    def pbBaseType(user)
        ret = :ELECTRIC
        ret = :DARK if user.form == 1
        return ret
    end

    def pbAdditionalEffect(user, _target)
        return unless user.form == 0
        return if user.pbOpposingSide.effectAtMax?(:Spikes)
        user.pbOpposingSide.incrementEffect(:Spikes)
    end

    def getEffectScore(user, target)
        return 0 unless user.form == 0
        return 0 if damagingMove? && target.pbOwnSide.effectAtMax?(:Spikes)
        return getHazardSettingEffectScore(user, target)
    end
end

# Empowered Spikes
class PokeBattle_Move_EmpoweredSpikes < PokeBattle_Move_Spikes
    include EmpoweredMove

    def pbEffectGeneral(user)
        # Apply up to the maximum number of layers
        increment = GameData::BattleEffect.get(:Spikes).maximum - user.pbOpposingSide.countEffect(:Spikes)
        user.pbOpposingSide.incrementEffect(:Spikes, increment) if increment > 0
        transformType(user, :GROUND)
    end
end

# Empowered Poison Spikes
class PokeBattle_Move_EmpoweredPoisonSpikes < PokeBattle_Move_Spikes
    include EmpoweredMove

    def pbEffectGeneral(user)
        # Apply up to the maximum number of layers
        increment = GameData::BattleEffect.get(:PoisonSpikes).maximum - user.pbOpposingSide.countEffect(:PoisonSpikes)
        user.pbOpposingSide.incrementEffect(:PoisonSpikes, increment) if increment > 0
        transformType(user, :POISON)
    end
end

# Empowered Frost Spikes
class PokeBattle_Move_EmpoweredFrostSpikes < PokeBattle_Move_Spikes
    include EmpoweredMove

    def pbEffectGeneral(user)
        # Apply up to the maximum number of layers
        increment = GameData::BattleEffect.get(:FrostSpikes).maximum - user.pbOpposingSide.countEffect(:FrostSpikes)
        user.pbOpposingSide.incrementEffect(:FrostSpikes, increment) if increment > 0
        transformType(user, :ICE)
    end
end

# Empowered Flame Spikes
class PokeBattle_Move_EmpoweredFlameSpikes < PokeBattle_Move_Spikes
    include EmpoweredMove

    def pbEffectGeneral(user)
        # Apply up to the maximum number of layers
        increment = GameData::BattleEffect.get(:FlameSpikes).maximum - user.pbOpposingSide.countEffect(:FlameSpikes)
        user.pbOpposingSide.incrementEffect(:FlameSpikes, increment) if increment > 0
        transformType(user, :FIRE)
    end
end
#===============================================================================
# Entry hazard. Lays poison spikes on the opposing side (max. 2 layers).
# (Poison Spikes)
#===============================================================================
class PokeBattle_Move_PoisonSpikes < PokeBattle_StatusSpikeMove
    def hazardMove?; return true; end
    def initialize(battle, move)
        @spikeEffect = :PoisonSpikes
        super
    end
end

#===============================================================================
# Entry hazard. Lays burn spikes on the opposing side.
# (Flame Spikes)
#===============================================================================
class PokeBattle_Move_FlameSpikes < PokeBattle_StatusSpikeMove
    def hazardMove?; return true; end
    def initialize(battle, move)
        @spikeEffect = :FlameSpikes
        super
    end
end

#===============================================================================
# Entry hazard. Lays frostbite spikes on the opposing side.
# (Frost Spikes)
#===============================================================================
class PokeBattle_Move_FrostSpikes < PokeBattle_StatusSpikeMove
    def hazardMove?; return true; end
    def initialize(battle, move)
        @spikeEffect = :FrostSpikes
        super
    end
end

#===============================================================================
# Entry hazard. Lays stealth rocks on the opposing side. (Stealth Rock)
#===============================================================================
class PokeBattle_Move_StealthRock < PokeBattle_Move
    def hazardMove?; return true; end
    def aiAutoKnows?(pokemon); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.pbOpposingSide.effectActive?(:StealthRock)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since pointed stones already float around the opponent!"))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        user.pbOpposingSide.applyEffect(:StealthRock)
    end

    def pbEffectAgainstTarget(_user, target)
        return unless damagingMove?
        return if target.pbOwnSide.effectActive?(:StealthRock)
        target.pbOwnSide.applyEffect(:StealthRock)
    end

    def getEffectScore(user, target)
        return 0 if damagingMove? && target.pbOwnSide.effectActive?(:StealthRock)
        return getHazardSettingEffectScore(user, target, 12)
    end
end

#===============================================================================
# Sets stealth rock and sandstorm for 5 turns. (Megalith Rite)
#===============================================================================
class PokeBattle_Move_StealthRockStartSandstorm5 < PokeBattle_Move_StealthRock
    def pbMoveFailed?(user, _targets, show_message)
        return false
    end

    def pbEffectGeneral(user)
        super
        @battle.pbStartWeather(user, :Sandstorm, 5, false) unless @battle.primevalWeatherPresent?
    end
end

#===============================================================================
# Entry hazard. Lays Feather Ward on the opposing side. (Feather Ward)
#===============================================================================
class PokeBattle_Move_FeatherWard < PokeBattle_Move
    def hazardMove?; return true; end
    def aiAutoKnows?(pokemon); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if user.pbOpposingSide.effectActive?(:FeatherWard)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since sharp feathers already float around the opponent!"))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.pbOpposingSide.applyEffect(:FeatherWard)
    end

    def getEffectScore(user, target)
        return getHazardSettingEffectScore(user, target, 12)
    end
end

#===============================================================================
# Entry hazard. Lays a Speed reducing web on the opposing side. (Sticky Web)
#===============================================================================
class PokeBattle_Move_StickyWeb < PokeBattle_Move
    def hazardMove?; return true; end
    def aiAutoKnows?(pokemon); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if user.pbOpposingSide.effectActive?(:StickyWeb)
            @battle.pbDisplay(_INTL("But it failed, since a Sticky Web is already laid out!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.pbOpposingSide.applyEffect(:StickyWeb)
    end

    def getEffectScore(user, target)
        return getHazardSettingEffectScore(user, target, 15)
    end
end

#===============================================================================
# Entry hazard. Lays live wire on the opposing side. (Live Wire)
#===============================================================================
class PokeBattle_Move_LiveWire < PokeBattle_Move
    def hazardMove?; return true; end
    def aiAutoKnows?(pokemon); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if user.pbOpposingSide.effectActive?(:LiveWire)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since a live wire already sits near the opponent!"))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        return if damagingMove?
        user.pbOpposingSide.applyEffect(:LiveWire)
    end

    def pbEffectAgainstTarget(_user, target)
        return unless damagingMove?
        return if target.pbOwnSide.effectActive?(:LiveWire)
        target.pbOwnSide.applyEffect(:LiveWire)
    end

    def getEffectScore(user, target)
        return 0 if damagingMove? && target.pbOwnSide.effectActive?(:LiveWire)
        if @battle.rainy? || user.ownersPolicies.include?(:RAIN_TEAM)
            scoringWeight = 16
        else
            scoringWeight = 8
        end
        return getHazardSettingEffectScore(user, target, scoringWeight)
    end
end

#===============================================================================
# If a Pokémon attacks the user with a special move before it uses this move, set up Spikes (Shard Surge)
#===============================================================================
class PokeBattle_Move_SetupSpikesBeforeUserActs < PokeBattle_Move
    def pbDisplayChargeMessage(user)
        user.applyEffect(:ShardSurge)
    end

    def getEffectScore(user, target)
        return 0 if damagingMove? && target.pbOwnSide.effectAtMax?(:Spikes)
        return getHazardSettingEffectScore(user, target)
    end
end