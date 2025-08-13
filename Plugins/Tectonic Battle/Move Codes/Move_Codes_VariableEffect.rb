#===============================================================================
# Effect depends on the environment. (Secret Power)
#===============================================================================
class PokeBattle_Move_EffectDependsOnEnvironment < PokeBattle_Move
    def flinchingMove?; return [6, 10, 12].include?(@secretPower); end

    def pbOnStartUse(_user, _targets)
        @secretPower = 0 # Body Slam, numb
        case @battle.environment
        when :Grass, :TallGrass, :Forest, :ForestGrass
            @secretPower = 2    # (Same as Grassy Terrain)
        when :MovingWater, :StillWater, :Underwater
            @secretPower = 5    # Water Pulse, waterlog
        when :Puddle
            @secretPower = 6    # Mud Shot, lower Speed by 1
        when :Cave
            @secretPower = 7    # Rock Throw, flinch
        when :Rock, :Sand
            @secretPower = 8    # Dust Devil, burn
        when :Snow, :Ice
            @secretPower = 9    # Ice Shard, frostbite
        when :Volcano
            @secretPower = 10   # Incinerate, burn
        when :Graveyard
            @secretPower = 11   # Shadow Sneak, flinch
        when :Sky
            @secretPower = 12   # Gust, lower Speed by 1
        when :Space, :UltraSpace
            @secretPower = 13   # Swift, flinch
        end
    end

    # NOTE: This intentionally doesn't use def pbAdditionalEffect, because that
    #       method is called per hit and this move's additional effect only occurs
    #       once per use, after all the hits have happened (two hits are possible
    #       via Parental Bond).
    def pbEffectAfterAllHits(user, target)
        return if target.fainted?
        return if target.damageState.unaffected || target.damageState.substitute
        chance = pbAdditionalEffectChance(user, target, @calcType)
        return if @battle.pbRandom(100) >= chance
        return unless canApplyRandomAddedEffects?(user,target,true)
        case @secretPower
        when 2
            target.applySleep if target.canSleep?(user, false, self)
        when 8, 10
            target.applyBurn(user) if target.canBurn?(user, false, self)
        when 0, 1
            target.applyNumb(user) if target.canNumb?(user, false, self)
        when 9
            target.applyFrostbite(user) if target.canFrostbite?(user, false, self)
        when 5
            target.applyWaterlog(user) if target.canFrostbite?(user, false, self)
        when 4, 6, 12
            target.tryLowerStat(:SPEED, user, move: self, increment: 2)
        when 7, 11, 13
            target.pbFlinch
        end
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        id = :BODYSLAM # Environment-specific anim
        case @secretPower
        when 1  then id = :THUNDERSHOCK if GameData::Move.exists?(:THUNDERSHOCK)
        when 2  then id = :VINEWHIP if GameData::Move.exists?(:VINEWHIP)
        when 3  then id = :FAIRYWIND if GameData::Move.exists?(:FAIRYWIND)
        when 4  then id = :MINDWAVES if GameData::Move.exists?(:MINDWAVES)
        when 5  then id = :WATERPULSE if GameData::Move.exists?(:WATERPULSE)
        when 6  then id = :MUDSHOT if GameData::Move.exists?(:MUDSHOT)
        when 7  then id = :ROCKTHROW if GameData::Move.exists?(:ROCKTHROW)
        when 8  then id = :MUDSLAP if GameData::Move.exists?(:MUDSLAP)
        when 9  then id = :ICESHARD if GameData::Move.exists?(:ICESHARD)
        when 10 then id = :INCINERATE if GameData::Move.exists?(:INCINERATE)
        when 11 then id = :SHADOWSNEAK if GameData::Move.exists?(:SHADOWSNEAK)
        when 12 then id = :GUST if GameData::Move.exists?(:GUST)
        when 13 then id = :SWIFT if GameData::Move.exists?(:SWIFT)
        when 14 then id = :PSYWAVE if GameData::Move.exists?(:PSYWAVE)
        end
        super
    end

    def getTargetAffectingEffectScore(_user, target)
        return 20
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("The secondary effect of this move will change depending on the environment")
        detailsList << _INTL("<u>Rocky, Sandy, Volcanos</u>: Burn")
        detailsList << _INTL("<u>Grassy</u>: Sleep")
        detailsList << _INTL("<u>Snowy</u>: Frostbite")
        detailsList << _INTL("<u>Moving and Still Water</u>: Waterlog")
        detailsList << _INTL("<u>Caves, Graveyards, and Space</u>: Flinch")
        detailsList << _INTL("<u>Puddles</u>: Lower Speed by 2 steps")
        detailsList << _INTL("<u>In The Sky</u>: Lower Speed by 1 step")
        detailsList << _INTL("<u>Everywhere Else</u>: Numb")
    end
end

#===============================================================================
# Uses a different move depending on the environment. (Nature Power)
# NOTE: This code does not support the Gen 5 and older definition of the move
#       where it targets the user. It makes more sense for it to target another
#       Pokémon.
#===============================================================================
class PokeBattle_Move_UseMoveDependingOnEnvironment < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def calculateNaturePower
        npMove = :RUIN
        case @battle.environment
        when :Grass, :TallGrass, :Forest, :ForestGrass
            npMove = :ENERGYBALL if GameData::Move.exists?(:ENERGYBALL)
        when :MovingWater, :StillWater, :Underwater, :Puddle
            npMove = :BUBBLEBLASTER if GameData::Move.exists?(:BUBBLEBLASTER)
        when :Cave
            npMove = :POWERGEM if GameData::Move.exists?(:POWERGEM)
        when :Rock, :Sand
            npMove = :EARTHPOWER if GameData::Move.exists?(:EARTHPOWER)
        when :Snow, :Ice
            npMove = :ICEBEAM if GameData::Move.exists?(:ICEBEAM)
        when :Volcano
            npMove = :FLAMETHROWER if GameData::Move.exists?(:FLAMETHROWER)
        when :Graveyard
            npMove = :SHADOWBALL if GameData::Move.exists?(:SHADOWBALL)
        when :Sky
            npMove = :AIRSLASH if GameData::Move.exists?(:AIRSLASH)
        when :Space
            npMove = :DRACOMETEOR if GameData::Move.exists?(:DRACOMETEOR)
        when :UltraSpace
            npMove = :PSYCHOBOOST if GameData::Move.exists?(:PSYCHOBOOST)
        end
        return npMove
    end

    def pbEffectAgainstTarget(user, target)
        moveToUse = calculateNaturePower
        @battle.pbDisplay(_INTL("{1} turned into {2}!", @name, GameData::Move.get(moveToUse).name))
        user.pbUseMoveSimple(moveToUse, target.index)
    end

    def getEffectScore(user, target)
        pseudoMove = calculateNaturePower
        return @battle.getBattleMoveInstanceFromID(pseudoMove).getEffectScore(user, target)
    end

    def getTargetAffectingEffectScore(user, target)
        pseudoMove = calculateNaturePower
        return @battle.getBattleMoveInstanceFromID(pseudoMove).getTargetAffectingEffectScore(user, target)
    end
	
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Turns into a different move depending on the environment.")
        detailsList << _INTL("<u>Grassy</u>: Energy Ball")
        detailsList << _INTL("<u>Water</u>: Bubble Blaster")
        detailsList << _INTL("<u>Caves</u>: Power Gem")
        detailsList << _INTL("<u>Rocky, Sandy</u>: Earth Power")
        detailsList << _INTL("<u>Snowy, Icy</u>: Ice Beam")
        detailsList << _INTL("<u>Volcanos</u>: Flamethrower")
        detailsList << _INTL("<u>Graveyards</u>: Shadow Ball")
        detailsList << _INTL("<u>In The Sky</u>: Air Slash")
        detailsList << _INTL("<u>Space</u>: Draco Meteor")
        detailsList << _INTL("<u>Ultraspace</u>: Psycho Boost")
        detailsList << _INTL("<u>Everywhere Else</u>: Ruin")
    end

end