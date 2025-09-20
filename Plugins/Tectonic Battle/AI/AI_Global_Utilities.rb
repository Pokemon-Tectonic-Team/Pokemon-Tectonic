#=============================================================================
# Get approximate properties for a battler
#=============================================================================
def pbRoughType(move, user)
    ret = move.pbCalcType(user)
    return ret
end

#=============================================================================
# Nerf the AI at lower levels, to maintain the same playstyle as endgame
# Used in Wish, Switching, and Damage
#=============================================================================
def levelNerf(switch,damage,intensity)
    levelBracket = (level / 5.0).ceil
    levelPenalty = [0,15.0,15.0,13.0,10.0,8.0,5.0][levelBracket]
    levelPenalty *= intensity
    if switch == true
        PBDebug.log("[STAY-IN RATING][LEVEL NERF] #{pbThis} (#{index}) is penalizing switching (+#{levelPenalty.round})")
    elsif damage == true
        levelPenalty = levelPenalty / 5 / 10 + 1.0
        PBDebug.log"[LEVEL NERF] Adjusted score by (+#{((levelPenalty - 1) * 100).round})%"
    else
        levelPenalty = -levelPenalty / 5 / 10 + 1.0
        PBDebug.log"[LEVEL NERF] Adjusted score by (-#{100 - (levelPenalty * 100).round})%"
    end
    
    return levelPenalty
end

#=============================================================================
# Figure out if the AI should play more aggressively
# because the situation allows/requires it
#=============================================================================
def getUrgency
    urgency = 0
    eachOpposing do |b|
        urgency += 1 if !b.canActThisTurn? # pressure sleeping mons
        urgency += 2 if b.hasSetupMove?
        urgency += 2 if b.hasSetupMove? && b.lastRoundMoveCategory == 2 # Actively setting up
        urgency += 2 if b.hasUseableHazardMove?
        urgency += 1 if b.hasUseableHazardMove? && b.lastRoundMoveCategory == 2 # Actively hazard stacking
        urgency += 2 if b.hasActiveAbilityAI?(:CONTRARY) || b.hasActiveAbilityAI?(:INVERSION) || b.hasActiveAbilityAI?(:PERSISTENTGROWTH)
    end
    if inWeatherTeam && urgency = 0
        weatherInfo = [
            [:SUN_TEAM, @battle.sunny?, :DROUGHT, :HEATROCK],
            [:RAIN_TEAM, @battle.rainy?, :DRIZZLE, :DAMPROCK],
            [:SANDSTORM_TEAM, @battle.sandy?, :SANDSTREAM, :SMOOTHROCK],
            [:HAIL_TEAM, @battle.icy?, :SNOWWARNING, :ICYROCK],
            [:MOONGLOW_TEAM, @battle.moonGlowing?, :MOONGAZE, :MIRROREDROCK],
            [:ECLIPSE_TEAM, @battle.eclipsed?, :HARBINGER, :PINPOINTROCK],
        ]    
        weatherInfo.each do |weatherEntry|
            weatherPolicy = weatherEntry[0]
            weatherActive = weatherEntry[1]
            urgency += 1 if weatherActive && weatherPolicy # Weather teams play more aggressively
        end
    end
    urgency = 5 * urgency
    return urgency
end