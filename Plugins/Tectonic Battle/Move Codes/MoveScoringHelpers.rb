DOWNSIDE_ABILITIES = %i[SLOWSTART PRIMEVALSLOWSTART DEFEATIST TRUANT AUTUMNAL]

ALL_STATUS_SCORE_BONUS = 0
STATUS_UPSIDE_MALUS = 60
NON_ATTACKER_BONUS = 30
STATUS_PUNISHMENT_BONUS = 40

def getStatusSettingEffectScore(statusApplying, user, target, ignoreCheck: false)
    case statusApplying
    when :SLEEP
        return getSleepEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :POISON
        return getPoisonEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :BURN
        return getBurnEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :FROSTBITE
        return getFrostbiteEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :NUMB
        return getNumbEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :DIZZY
        return getDizzyEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :LEECHED
        return getLeechEffectScore(user, target, ignoreCheck: ignoreCheck)
    when :WATERLOG
        return getWaterlogEffectScore(user, target, ignoreCheck: ignoreCheck)
    end

    raise _INTL("Given status #{statusApplying} is not valid.")
end

def willHealStatus?(target)
    return true if target.hasActiveAbilityAI?(:SHEDSKIN)
    return true if target.hasActiveAbilityAI?(:HYDRATION) && target.battle.rainy?
    return true if target.hasActiveAbilityAI?(:OXYGENATION) && target.battle.sunny?
    return false
end

def getNaturalCureScore(user, target, score)
    return 0 unless target.battle.pbCanSwitch?(target.index)
    ncScore = score * 0.4
    ncScore -= getForceOutEffectScore(user, target) # Encouraging target to switch might be benefical
    return 0 if ncScore <= 0
    return ncScore
end

def getNumbEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    if target && (ignoreCheck || target.canNumb?(user, false))
        score = 0
        score += 60 if target.hasDamagingAttack?
        score += 60 if user && target.pbSpeed(true) > user.pbSpeed(true)
        score += STATUS_PUNISHMENT_BONUS if user && (user.hasStatusPunishMove? ||
                                            user.pbHasMoveFunction?("SmellingSalts", "NumbTargetOrCurseIfNumb")) # Smelling Salts, Spectral Tongue
        score += 60 if user&.hasActiveAbilityAI?(:TENDERIZE)
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getWaterlogEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    if target && (ignoreCheck || target.canWaterlog?(user, false))
        score = 0
        score += 60 if user.hasDamagingAttack?
        score += 60 if user && target.pbSpeed(true) > user.pbSpeed(true)
        score += STATUS_PUNISHMENT_BONUS if user && (user.hasStatusPunishMove? ||
        user.pbHasMoveFunction?("Drainage")) # Drainage
        score += 60 if user&.hasActiveAbilityAI?(:SINKINGFEELING)
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getPoisonEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    if target && (ignoreCheck || target.canPoison?(user, false))
        score = -10
        if target.takesIndirectDamage?
            score += 70
            score += 20 if target.hp >= target.totalhp * 0.95
            score += 40 if target.hp >= target.totalhp / 2 || target.hp <= target.totalhp / 10
            score += 30 if target.trapped?
			score += 60 if target.hasHealingMove?
            score += NON_ATTACKER_BONUS unless user&.hasDamagingAttack?
            if user
                score *= 1.5 if user.hasActiveAbilityAI?(:AGGRAVATE)
                score *= 2 if user.ownersPolicies.include?(:PRIORITIZEDOTS) && user.opposes?(target)
            end
        end
        score += STATUS_PUNISHMENT_BONUS if user && (user.hasStatusPunishMove? || user.pbHasMoveFunction?("DoubleDamageAgainstPoisoned","TripleDamageAgainstPoisoned")) # Venoshock/Vipershock
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getBurnEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    if target && (ignoreCheck || target.canBurn?(user, false))
        score = -10

        if target.takesIndirectDamage?
            score += 50
            score += 20 if target.hp >= target.totalhp / 2 || target.hp <= target.totalhp / 8
            score += NON_ATTACKER_BONUS unless user&.hasDamagingAttack?
            if user
                score *= 1.5 if user.hasActiveAbilityAI?(:AGGRAVATE)
                score *= 2 if user.ownersPolicies.include?(:PRIORITIZEDOTS) && user.opposes?(target)
            end
        end

        if target.hasPhysicalAttack?
            score += 30
            score += 30 unless target.hasSpecialAttack?
        end
        
        score += STATUS_PUNISHMENT_BONUS if user && (user.hasStatusPunishMove? || user.pbHasMoveFunction?("DoubleDamageAgainstBurned")) # Flare Up
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getFrostbiteEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    if target && (ignoreCheck || target.canFrostbite?(user, false))
        score = -10

        if target.takesIndirectDamage?
            score += 50
            score += 20 if target.hp >= target.totalhp / 2 || target.hp <= target.totalhp / 8
            score += NON_ATTACKER_BONUS unless user&.hasDamagingAttack?
            if user
                score *= 1.5 if user.hasActiveAbilityAI?(:AGGRAVATE)
                score *= 2 if user.ownersPolicies.include?(:PRIORITIZEDOTS) && user.opposes?(target)
            end
        end

        if target.hasSpecialAttack?
            score += 30
            score += 30 unless target.hasPhysicalAttack?
        end

        score += STATUS_PUNISHMENT_BONUS if user && (user.hasStatusPunishMove? || user.pbHasMoveFunction?("DoubleDamageAgainstFrostbitten")) # Ice Impact
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getDizzyEffectScore(user, target, ignoreCheck: false)
    canDizzy = target.canDizzy?(user, false) && !target.hasActiveAbility?(:MENTALBLOCK)
    if ignoreCheck || canDizzy
        score = 60 # TODO: Some sort of basic AI for rating abilities?
        score += 20 if target.hp >= target.totalhp / 2
        score += 20 if user&.hasDamagingAttack?
        score += STATUS_PUNISHMENT_BONUS if user&.hasStatusPunishMove?
    else
        return 0
    end
    return score
end

def getLeechEffectScore(user, target, ignoreCheck: false)
    return 0 if willHealStatus?(target)
    return -10 unless target.takesIndirectDamage?
    canLeech = target.canLeech?(user, false)
    if ignoreCheck || canLeech
        score = -10
        if target.takesIndirectDamage?
            score += 60
            score += NON_ATTACKER_BONUS * 2 unless user&.hasDamagingAttack?			
            score += 20 if target.hp >= target.totalhp * 0.95
            score += 40 if target.hp >= target.totalhp / 2 || target.hp <= target.totalhp / 10
            score += 20 if target.totalhp > user&.totalhp * 1.5			
            score += 20 if target.totalhp > user&.totalhp * 2
            score -= 30 if target.totalhp < user&.totalhp / 2
			score += 50 if target.hasHealingMove?
            score *= 2 if user&.hasActiveAbilityAI?(:AGGRAVATE)
            score *= 1.5 if user&.hasActiveAbilityAI?(:ROOTED)
            score *= 1.3 if user&.hasActiveItemAI?(:BIGROOT)
            score *= 2 if user&.ownersPolicies.include?(:PRIORITIZEDOTS) && user&.opposes?(target)
        end

        score += STATUS_PUNISHMENT_BONUS if user&.hasStatusPunishMove?
        score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    else
        return 0
    end
    return score
end

def getSleepEffectScore(user, target, _policies = [])
    return 0 if target.hasActiveAbilityAI?(:HYDRATION) && target.battle.rainy?
    return 0 if target.hasActiveAbilityAI?(:OXYGENATION) && target.battle.sunny?
    score = 150
    score -= 100 if target.hasSleepAttack?
    score += STATUS_PUNISHMENT_BONUS if user&.hasStatusPunishMove?
    score -= 60 if target.hasActiveAbilityAI?(%i[LOUDSLEEPER SNOOZEFEST])
    if target.hasActiveAbilityAI?(:DREAMWEAVER)
        score -= getMultiStatUpEffectScore([:SPECIAL_ATTACK, 2],target,target)
    end
    score -= getNaturalCureScore(user, target, score) if target.hasActiveAbilityAI?(:NATURALCURE)
    return score
end

def getFlinchingEffectScore(baseScore, user, target, move)
    return 0 unless user.battle.battleAI.userMovesFirst?(move, user, target)
    return 0 if target.hasActiveAbilityAI?(GameData::Ability.getByFlag("FlinchImmunity"))
    return 0 if target.substituted? && !move.ignoresSubstitute?(user)
    return 0 if target.effectActive?(:FlinchImmunity)
    return 0 if target.battle.pbCheckSameSideAbility(:EFFLORESCENT,target.index)
    return 0 if target.hasActiveItemAI?(:COURAGEBADGE)

    score = baseScore
    score *= 2.0 if user.hasAlly?

    score /= 2.0 if user.battle.moonGlowing? && target.flinchedByMoonglow?(true)

    return score
end

def getWantsToBeFasterScore(user, other, magnitude = 1, move: nil)
    return getWantsToBeSlowerScore(user, other, -magnitude, move: move)
end

def getWantsToBeSlowerScore(user, other, magnitude = 1, move: nil)
    userSpeed = user.pbSpeed(true, move: move)
    otherSpeed = other.pbSpeed(true, move: move)
    if userSpeed < otherSpeed
        return 10 * magnitude
    else
        return -10 * magnitude
    end
end

def getHazardSettingEffectScore(user, _target, magnitude = 10)
    canChoose = false
    user.eachOpposing do |b|
        next unless user.battle.pbCanChooseNonActive?(b.index)
        canChoose = true
        return 0 if b.hasHazardRemovalMove?
        break
    end
    return 0 unless canChoose # Opponent can't switch in any Pokemon
    score = magnitude * 2
    score += magnitude * user.enemiesInReserveCount
    score += magnitude * user.alliesInReserveCount
    score *= 1.5
    user.eachOpposing do |b|
        score -= statStepsValueScore(b)
    end
    return score
end

def getSelfKOMoveScore(user, _target)
    reserves = user.battle.pbAbleNonActiveCount(user.idxOwnSide)
    return -200 if reserves == 0 # don't want to lose or draw
    return ((-user.hp / user.totalhp.to_f) * 100).round
end

def statusSpikesWeightOnSide(side, excludeEffects = [])
    hazardWeight = 0
    hazardWeight += [0,50,150][side.countEffect(:PoisonSpikes)] unless excludeEffects.include?(:PoisonSpikes)
    hazardWeight += [0,50,150][side.countEffect(:FlameSpikes)] unless excludeEffects.include?(:FlameSpikes)
    hazardWeight += [0,50,150][side.countEffect(:FrostSpikes)] unless excludeEffects.include?(:FrostSpikes)
    return hazardWeight
end

def hazardWeightOnSide(side, excludeEffects = []) # does not check for reserves, moves using this must do so
    hazardWeight = 0
    hazardWeight += [0,80,110,140][side.countEffect(:Spikes)] unless excludeEffects.include?(:Spikes)
    hazardWeight += 95 if side.effectActive?(:StealthRock) && !excludeEffects.include?(:StealthRock)
    hazardWeight += 95 if side.effectActive?(:FeatherWard) && !excludeEffects.include?(:FeatherWard)
    if side.effectActive?(:LiveWire) && !excludeEffects.include?(:LiveWire)
        if side.battle.rainy?
            hazardWeight += 110
        else
            hazardWeight += 55
        end
    end
    hazardWeight += 115 if side.effectActive?(:StickyWeb) && !excludeEffects.include?(:StickyWeb)
    hazardWeight += statusSpikesWeightOnSide(side, excludeEffects)
    return hazardWeight
end

def getSwitchOutEffectScore(switcher, scoreStatSteps = true)
    return 0 unless switcher.battle.pbCanChooseNonActive?(switcher.index)
    return 0 if switcher.trapped?
    score = 5 + switcher.alliesInReserveCount * 5
    score *= 1.5 if switcher.ownersPolicies.include?(:PRIORITIZEUTURN)
    score -= hazardWeightOnSide(switcher.pbOwnSide)
    score -= statStepsValueScore(switcher) if scoreStatSteps
    return score
end

def getForceOutEffectScore(_user, target, random = true)
    return 0 if !target.battle.pbCanChooseNonActive?(target.index)
    return 0 if target.effectActive?(:Ingrain)
    score = random ? 10 : -15
    score += 0.5 * hazardWeightOnSide(target.pbOwnSide,[:StickyWeb])
    score += statStepsValueScore(target)	
    return score
end

def statStepsValueScore(battler)
    score = 0
    GameData::Stat.each_battle do |s|
        statStep = battler.steps[s.id]
        if s.id == :ATTACK
            next unless battler.hasPhysicalAttack?
        elsif s.id == :SPECIAL_ATTACK
            next unless battler.hasSpecialAttack?
        end
        score += statStep * 30
        score = 180 if score > 180
    end
    echoln("\t\t[EFFECT SCORING] Scoring the total value of the stat steps on #{battler.pbThis(true)} as #{score}.")
    return score
end

def getExchangeItemEffectScore(user, target)
    if user.hasActiveItemAI?(%i[FLAMEORB FROSTORB POISONORB STICKYBARB IRONBALL])
        return 150
    elsif user.hasActiveItemAI?(GameData::Item.getByFlag("ChoiceLocking"))
        return 120
    end
    return 0
end

def getMultiStatUpEffectScore(statUpArray, user, target, fakeStepModifier: 0, evaluateThreat: true)
    echoln("\t\t[EFFECT SCORING] Scoring the effect of raising stats #{statUpArray.to_s} on target #{target.pbThis(true)}")
    
    if user.battle.field.effectActive?(:GreyMist)
        echoln("\t\t[EFFECT SCORING] Grey Mist is active, scoring 0.")
        return 0
    end
	
	if user.effects[:PerishSong] > 0
		echoln("\t\t[EFFECT SCORING] #{user.pbThis} (#{user.index}) has heard the perish song, scoring 0")
		return 0
	end
	
    score = 0

    for i in 0...statUpArray.length / 2
        statSymbol = statUpArray[i * 2]
        statIncreaseAmount = statUpArray[i * 2 + 1]

        statIncreaseAmount = [PokeBattle_Battler::STAT_STEP_BOUND,statIncreaseAmount * 2].min if target.hasActiveAbilityAI?(:SIMPLE)

        # Give no extra points for stats you can't use
        if statSymbol == :ATTACK && !target.hasPhysicalAttack?
            echoln("\t\t[EFFECT SCORING] Ignoring Attack changes, target has no physical attacks")
            next
        end
        if statSymbol == :SPECIAL_ATTACK && !target.hasSpecialAttack?
            echoln("\t\t[EFFECT SCORING] Ignoring Sp. Atk changes, target has no special attacks")
            next
        end
        if statSymbol == :ACCURACY
            unless target.hasActiveAbilityAI?(:HUSTLE) || target.hasActiveAbilityAI?(:FREESTYLE) || target.hasInaccurateMove?
            echoln("\t\t[EFFECT SCORING] Ignoring Accuracy changes, target is already accurate")
            next
            end
        end
        
        # Increase the score more for boosting attacking stats
        if %i[ATTACK SPECIAL_ATTACK].include?(statSymbol)
            increase = 30
        elsif statSymbol == :DEFENSE
            increase = target.tookPhysicalHitLastRound ? 24 : 16
        elsif statSymbol == :SPECIAL_DEFENSE
            increase = target.tookSpecialHitLastRound ? 24 : 16
        elsif statSymbol == :SPEED
            increase = 23
        else # Currently only Accuracy
            increase = 16
        end
		
		# Increase the score more if getting offense and defense from same stat
		increase += 12 if statSymbol == :DEFENSE && target.pbHasMoveFunction?("AttacksWithDefense") # Body Press
		increase += 12 if statSymbol == :SPECIAL_DEFENSE && target.pbHasMoveFunction?("AttacksWithSpDef") # Aura Trick
		increase = 30 if %i[DEFENSE SPECIAL_DEFENSE].include?(statSymbol) && increase > 30 # Restrain the ai if it has defense move and took a hit

        # Different stat steps have different values
        stepTotal = target.steps[statSymbol] + fakeStepModifier
        debugStatIncreaseAmount = statIncreaseAmount # For debug reporting
        debugStep = stepTotal # For debug reporting
        totalIncrease = 0
        if %i[ATTACK SPECIAL_ATTACK].include?(statSymbol)
            while statIncreaseAmount >= 1
                stepTotal += 1
                stepTotal = 9 if stepTotal > 9
                statIncreaseAmount -= 1
                totalIncrease += increase.to_f * ([0,1,1,0.9,0.9,0.8,0.8,0.7,0.6,0.5][stepTotal] || 0)
            end
        end
        if %i[DEFENSE SPECIAL_DEFENSE].include?(statSymbol)
            while statIncreaseAmount >= 1
                stepTotal += 1
                stepTotal = 7 if stepTotal > 7
                statIncreaseAmount -= 1
                totalIncrease += increase.to_f * ([0,1,1,0.9,0.9,0.6,0.4,0.3][stepTotal] || 0)
            end
        end
        if statSymbol == :SPEED
            sTier = target.getSpeedTier
            while statIncreaseAmount >= 1
                stepTotal = 0 if stepTotal < 0
                stepTotal += 1
                stepTotal = 6 if stepTotal > 6
                statIncreaseAmount -= 1
                if sTier == 2
                    totalIncrease += increase.to_f * ([0,1.1,0.9,0.5,0.4,0.1,0.1][stepTotal] || 0) # FAST, first 2 enable outspeeding all, rest unnneeded
                elsif sTier == 1
                    totalIncrease += increase.to_f * ([0,1,1.1,1,1,0.5,0.2][stepTotal] || 0) # AVERAGE, first 2 are good, next 4 enable outspeeding all
                else
                    totalIncrease += increase.to_f * ([0,0.3,0.3,0.5,0.7,1,0.5][stepTotal] || 0) # SLOW, speed low value unless in large quantity
                end
            end
        end
        if statSymbol == :ACCURACY # This should probably have a complicated system behind it, but time is a finite resource
            stepTotal -= 1 if target.hasActiveAbilityAI?(:HUSTLE) || target.hasActiveAbilityAI?(:FREESTYLE)
            stepTotal += 1 if target.hasActiveItem?(:WIDELENS) # 35% instead of 25% but close enough
            while statIncreaseAmount >= 1
                stepTotal += 1
                stepTotal = 5 if stepTotal > 5
                statIncreaseAmount -= 1
                if target.hasLowAccuracyMove?
                    totalIncrease += increase.to_f * [1,1,1,1,1,0][stepTotal] # This assumes no moves below 50% accuracy exist           
                elsif target.hasMediumAccuracyMove?
                    totalIncrease += increase.to_f * [1,1,1,0,0,0][stepTotal]                  
                elsif target.hasInaccurateMove?
                    totalIncrease += increase.to_f * [1,1,0,0,0,0][stepTotal]                   
                elsif target.hasActiveAbilityAI?(:HUSTLE) || target.hasActiveAbilityAI?(:FREESTYLE)
                    totalIncrease += increase.to_f * [1,0,0,0,0,0][stepTotal]
                end
            end
        end
        
        # Stat ups are worse if you have a relevant status
        damageStatus = 0
        if target.pbHasAnyStatus? && !target.hasActiveAbilityAI?(:VICTORYMOLT)
            if target.burned?
                if statSymbol == :ATTACK
                    totalIncrease *= 0.66 unless target.pbHasMoveFunction?("DoubleDamageUserStatused") # Facade / Hard Feelings
                end
                damageStatus = 1
            elsif target.frostbitten?
                if statSymbol == :SPECIAL_ATTACK
                    totalIncrease *= 0.66 unless target.pbHasMoveFunction?("DoubleDamageUserStatused") # Facade / Hard Feelings
                end
                damageStatus = 1
            elsif target.numbed? || target.waterlogged?
                if statSymbol == :SPEED
                    totalIncrease *= 0.4
                elsif
                    if target.getSpeedTier > 0
                        totalIncrease *= 0.7
                    end
                else
                    totalIncrease *= 0.85
                end
            elsif target.dizzy? || target.waterlogged?
                totalIncrease *= 0.85 # There should probably be a system for evaluating abilities
            elsif target.leeched? or target.poisoned?
                damageStatus = 1
            end
            if damageStatus == 1 && !target.hasActiveAbilityAI?(:MAGICGUARD)
                if %i[DEFENSE SPECIAL_DEFENSE].include?(statSymbol)
                    totalIncrease *= 0.6
                else
                    totalIncrease *= 0.8
                end
            end
        end
        score += totalIncrease.round
        echoln("\t\t[EFFECT SCORING] The change to #{statSymbol} by #{debugStatIncreaseAmount} at step #{debugStep} increases the score by #{totalIncrease.round}")
    end

    # Stat ups tend to be stronger on the first turn
    score *= 1.2 if target.firstTurn?

    # Stat ups tend to be stronger when the target has HP to use
    score *= 1.2 if target.hp > target.totalhp / 2

    # Stat ups tend to be stronger when the target is protected by a substitute
    score *= 1.2 if target.substituted?

    # Stats ups are stronger the less threat the user is under this turn
    # And worse the more threat
    if evaluateThreat
        threatScore = (user.defensiveMatchupAI * 0.88 + 100.0) / 100.0
        if threatScore > 1.0
            threatScore -= 1.0
            unkownScore = 4
            target.eachOpposing do |opp|
                unkownScore -= opp.unknownMovesCountAI # It might not be bad to setup, but its only good to setup if AI really knows its safe.
            end
            unkownScore = 0 if unkownScore < 0
            threatScore *= unkownScore * 0.25
            threatScore += 1.0
        end
        score *= threatScore
    end

    if target.hasActiveAbilityAI?(:CONTRARY)
        score *= -1
        echoln("\t\t[EFFECT SCORING] The target has Contrary! Inverting the score.")
    elsif target.hasActiveAbilityAI?(:ECCENTRIC)
        score *= -0.5
        echoln("\t\t[EFFECT SCORING] The target has Eccentric! Inverting and halving the score.")
    end

    if user.opposes?(target)
        score *= -1
        echoln("\t\t[EFFECT SCORING] The target opposes the user! Inverting the score.")
    end

    enemiesCanSteal = false
    target.eachOpposing do |opp|
        next unless opp.hasStatBoostStealingMove?
        enemiesCanSteal = true
        echoln("\t\t[EFFECT SCORING] A foe of the target can steal the boost! Inverting the score.")
        break
    end

    score *= -1 if enemiesCanSteal
    
    score *= user.levelNerf(false,false,0.6) if user.level <= 30 && !user.pbOwnedByPlayer?
    
    return score.ceil
end

def getMultiStatDownEffectScore(statDownArray, user, target, fakeStepModifier: 0)
    echoln("\t\t[EFFECT SCORING] Scoring the effect of lowering stats #{statDownArray.to_s} on target #{target.pbThis(true)}")
    
    if user.battle.field.effectActive?(:GreyMist)
        echoln("\t\t[EFFECT SCORING] Grey Mist is active, scoring 0.")
        return 0
    end

    score = 0

    for i in 0...statDownArray.length / 2
        statSymbol = statDownArray[i * 2]
        statDecreaseAmount = statDownArray[i * 2 + 1]

        statDecreaseAmount = [PokeBattle_Battler::STAT_STEP_BOUND,statDecreaseAmount * 2].min if target.hasActiveAbilityAI?(:SIMPLE)

        if statSymbol == :ACCURACY
            echoln("The AI will never use a move that reduces accuracy.")
            return -100
        end

        # Give no extra points for attacking stats you can't use
        if statSymbol == :ATTACK && !target.hasPhysicalAttack?
            echoln("\t\t[EFFECT SCORING] Ignoring Attack changes, the target has no physical attacks")
            next
        end
        if statSymbol == :SPECIAL_ATTACK && !target.hasSpecialAttack?
            echoln("\t\t[EFFECT SCORING] Ignoring Sp. Atk changes, the target has no special attacks")
            next
        end

        # Increase the score more for boosting attacking stats
        if %i[ATTACK SPECIAL_ATTACK].include?(statSymbol)
            scoreIncrease = 20
        else
            scoreIncrease = 15
        end

        # Decreasing attacks matters less for hybrids
        scoreIncrease /= 2 if statSymbol == :ATTACK && target.hasSpecialAttack?
        scoreIncrease /= 2 if statSymbol == :SPECIAL_ATTACK && target.hasPhysicalAttack?

        scoreIncrease *= statDecreaseAmount
        step = target.steps[statSymbol] + fakeStepModifier
        scoreIncrease += step * 5 # Increase the score for each existing step
        scoreIncrease = 0 if scoreIncrease < 0

        score += scoreIncrease
        
        echoln("\t\t[EFFECT SCORING] The change to #{statSymbol} by #{statDecreaseAmount} at step #{step} increases the score by #{scoreIncrease}")
    end

    # Stat downs tend to be stronger when the target has HP to use
    score *= 1.2 if target.firstTurn?

    # Stat downs tend to be stronger when the target has HP to use
    score *= 1.2 if target.hp > target.totalhp / 2

    # Stat downs tend to be weaker when the target is able to swap out
    score /= 2 if user.battle.pbCanSwitch?(target.index)

    if target.hasActiveAbilityAI?(:CONTRARY)
        score *= -1
        echoln("\t\t[EFFECT SCORING] The target has Contrary! Inverting the score.")
    elsif target.hasActiveAbilityAI?(:ECCENTRIC)
        score *= -0.5
    end

    unless user.opposes?(target)
        score *= -1
        echoln("\t\t[EFFECT SCORING] The target is an ally of the user! Inverting the score.")
    end
    
    score *= 1.7 if user.ownersPolicies.include?(:PRIORITIZESTATDOWN) && user.opposes?(target)
    
    return score.ceil
end

def getWeatherSettingEffectScore(weatherType, user, battle, finalDuration = 4, checkExtensions = true)
    if battle.primevalWeatherPresent? || battle.pbCheckGlobalAbility(:AIRLOCK)
        echoln("\t\t[EFFECT SCORING] Score for setting weather #{weatherType} is 0 due to presence of weather-disabling ability")
        return 0
    end

    finalDuration = user.getWeatherSettingDuration(weatherType, finalDuration, true) if checkExtensions
    currentDuration = battle.field.weather == weatherType ? battle.field.weatherDuration : 0

    if currentDuration >= finalDuration
        echoln("\t\t[EFFECT SCORING] Score for setting weather #{weatherType} is 0 due to final duration #{finalDuration} being less than the current duration #{currentDuration}")
        return 0
    end

    finalScore = (10 * finalDuration**0.7).ceil
    currentScore = (10 * currentDuration**0.7).ceil
    score = finalScore - currentScore

    echoln("\t\t[EFFECT SCORING] Base score for setting weather #{weatherType} calculated as #{score} from difference of #{finalDuration}-turn final duration score (#{finalScore}) and #{currentDuration}-turn current duration score (#{currentScore})")

    weatherMatchesPolicy = false
    hasSynergyAbility = false
    hasSynergisticType = false
    case weatherType
    when :Sunshine
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:SUN_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("SunshineSynergy"))
        hasSynergisticType = true if user.pbHasAttackingType?(:FIRE)
    when :Rainstorm
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:RAIN_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("RainstormSynergy"))
        hasSynergisticType = true if user.pbHasAttackingType?(:WATER)
    when :Sandstorm
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:SANDSTORM_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("SandstormSynergy"))
        hasSynergisticType = true if user.pbHasTypeAI?(:ROCK)
    when :Hail
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:HAIL_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("HailSynergy"))
        hasSynergisticType = true if user.pbHasTypeAI?(:ICE)
    when :Moonglow
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:MOONGLOW_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("MoonglowSynergy"))
        hasSynergisticType = true if user.pbHasAttackingType?(:FAIRY)
    when :Eclipse
        weatherMatchesPolicy = true if user.ownersPolicies.include?(:ECLIPSE_TEAM)
        hasSynergyAbility = true if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("EclipseSynergy"))
        hasSynergisticType = true if user.pbHasAttackingType?(:PSYCHIC)
    end
    
    if weatherMatchesPolicy
        echoln("\t\t[EFFECT SCORING] Base score for setting weather #{weatherType} quadrupled due to relevant policy")
        score *= 4
    elsif user.aboveHalfHealth?
        score *= 1.5 if hasSynergisticType
        score *= 1.5 if user.hasActiveAbilityAI?(GameData::Ability.getByFlag("AllWeatherSynergy"))
    end
   
    return score
end

def getCriticalRateBuffEffectScore(user, steps = 1)
    return 0 if user.effectAtMax?(:RaisedCritChance)
    return 0 unless user.hasRandomCritAttack?
    score = 20
    score += 15 if user.firstTurn?
    score += 30 if user.hasActiveAbilityAI?(%i[SUPERLUCK SNIPER])
    score += 15 if user.hasHighCritAttack?
    score *= steps
    return score
end

def getHPLossEffectScore(user, fraction)
    score = -80 * fraction
    if user.hp <= user.totalhp * fraction
        return -300 unless user.alliesInReserve?
        score *= 2
    end
    return score
end

def getSuppressAbilityEffectScore(user, target)
    score = 0
    if target.hasActiveAbilityAI?(DOWNSIDE_ABILITIES)
        score = -70
    else
        score = 70
    end

    score *= -1 unless user.opposes?(target)

    return score
end

def getCurseEffectScore(user, target)
    score = 50
    score += 50 if target.aboveHalfHealth?
	if user.battle.pbCanSwitch?(target.index)
	    score += getForceOutEffectScore(user, target) # Encouraging target to switch might be benefical
        score = score * 0.70
    else
        score += statStepsValueScore(target)
	end
    score *= 1.5 if user.hasActiveAbilityAI?(:AGGRAVATE)
    return score
end

def getFractureEffectScore(user, target)
    return 0 unless target.hasDamagingAttack?
    score = 100
    if user.battle.pbCanSwitch?(target.index)
	    score += getForceOutEffectScore(user, target) # Encouraging target to switch might be benefical
        score = score * 0.70
    else
        score += statStepsValueScore(target)
	end
    return score
end

def getJinxEffectScore(user, target)
    score = 50
    score += 30 if user.hasDamagingAttack?
    score += 30 if user.canChooseProtect?
    if user.battle.pbCanSwitch?(target.index)
	    score += getForceOutEffectScore(user, target) # Encouraging target to switch might be benefical
        score = score * 0.70
    else
        score += statStepsValueScore(target)
	end
    return score
end

def passingTurnSideEffectScore(battle,sideIndex = 1)
    score = 0
    battle.eachBattler do |b|
        battlerScore = passingTurnBattlerEffectScore(b,battle)
        battlerScore *= -1 if b.index % 2 != sideIndex
        score += battlerScore
    end
    return score
end

def passingTurnBattlerEffectScore(battler,battle)
    healthChange,healthPercentageChange = passingTurnBattlerHealthChange(battler,battle)
    return healthPercentageChange * 2
end

def passingTurnBattlerHealthChange(battler,battle)
	healthChange = predictedEOTDamage(battle,battler)
    healthChange -= predictedEOTHealing(battle,battler)

    healthPercentageChange = healthChange * 100 / battler.totalhp
    return healthChange,healthPercentageChange
end

def predictedEOTDamage(battle,battler)
    return 0 unless battler.takesIndirectDamage?
    damage = 0
    
    # Weather DOTs
    damage += battle.applySandstormDamage(battler, aiCheck: true) if battle.sandy?
    damage += battle.applyHailDamage(battler, aiCheck: true) if battle.icy?

    # Status DOTs
    damage += battle.damageFromDOTStatus(battler, :POISON, true) if battler.poisoned?
    damage += battle.damageFromDOTStatus(battler, :LEECHED, true) if battler.leeched?
    damage += battle.damageFromDOTStatus(battler, :BURN, true) if battler.burned?
    damage += battle.damageFromDOTStatus(battler, :FROSTBITE, true) if battler.frostbitten?

    # Check for aggravate
    aggravate = battle.pbCheckOpposingAbility(:AGGRAVATE, battler.index)

    # Curse
    damage += battler.getFractionalDamageAmount(CURSE_DAMAGE_FRACTION, aggravate: aggravate) if battler.effectActive?(:Curse)

    # Trapping DOT
    damage += battler.getFractionalDamageAmount(trappingDamageFraction(battler), aggravate: aggravate) if battler.effectActive?(:Trapping)

    # Bad Dreams
    if battler.asleep? && battle.pbCheckOpposingAbility(:BADDREAMS, battler.index)
        damage += battler.getFractionalDamageAmount(BAD_DREAMS_DAMAGE_FRACTION, aggravate: aggravate)
    end
    
    # Pain Presence
    damage += battler.getFractionalDamageAmount(NOXIOUS_DAMAGE_FRACTION, aggravate: aggravate) if battle.pbCheckOtherAbility(:NOXIOUS, battler.index)

    # Extreme Energy, Extreme Power, Solar Power, Night Stalker
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:EXTREMEVOLTAGE)
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:EXTREMEPOWER)
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:SOLARPOWER) && battle.sunny?
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:NIGHTSTALKER) && battle.moonGlowing?
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:BURDENED)
    damage += battler.getFractionalDamageAmount(EOR_SELF_HARM_ABILITY_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveAbilityAI?(:LIVEFAST)

    # Sticky Barb
    damage += battler.getFractionalDamageAmount(STICKY_BARB_DAMAGE_FRACTION, aggravate: aggravate) if battler.hasActiveItemAI?(:STICKYBARB)

    # Black Sludge
    if battler.hasActiveItemAI?(:BLACKSLUDGE) && !battler.pbHasType?(:POISON)
        damage += battler.getFractionalDamageAmount(LEFTOVERS_HEALING_FRACTION)
    end

    return damage
end

def predictedEOTHealing(battle,battler)
    healing = 0

    # Aqua Ring, Ingrain
    healing += battler.getFractionalHealingAmount(aquaRingHealingFraction(battler)) if battler.effectActive?(:AquaRing)
    healing += battler.getFractionalHealingAmount(ingrainHealingFraction(battler)) if battler.effectActive?(:Ingrain) || battler.effectActive?(:EvilRoots)
    
    # Wish
    if battler.position.effectActive?(:Wish) && battler.position.effects[:Wish] == 1
        healing += battler.position.effects[:WishAmount]
    end

    # Grotesque Vitals, Fighting Vigor, Well Supplied, Living Armor
    healing += battler.getFractionalHealingAmount(EOT_ABILITY_HEALING_FRACTION) if battler.hasActiveAbilityAI?(:GROTESQUEVITALS)
    healing += battler.getFractionalHealingAmount(EOT_ABILITY_HEALING_FRACTION) if battler.hasActiveAbilityAI?(:FIGHTINGVIGOR)
    healing += battler.getFractionalHealingAmount(EOT_ABILITY_HEALING_FRACTION) if battler.hasActiveAbilityAI?(:SELFSUFFICIENT)
    healing += battler.getFractionalHealingAmount(EOT_ABILITY_HEALING_FRACTION) if battler.hasActiveAbilityAI?(:LIVINGARMOR)

    # Weather healing abilities
    if battler.hasActiveAbilityAI?(:RAINDISH) && battler.battle.rainy?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:DRYSKIN) && battler.battle.rainy?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:HEATSAVOR) && battler.battle.sunny?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:FINESUGAR) && battler.battle.sunny?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:ROCKBODY) && battler.battle.sandy?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:ICEBODY) && battler.battle.icy?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:MOONBASKING) && battler.battle.moonGlowing?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end
    if battler.hasActiveAbilityAI?(:EXTREMOPHILE) && battler.battle.eclipsed?
        healing += battler.getFractionalHealingAmount(WEATHER_ABILITY_HEALING_FRACTION)
    end

    # Lifeline
    if battler.hasActiveAbilityAI?(:LIFELINE)
        healing += battler.getFractionalHealingAmount(LIFELINE_HEALING_FRACTION)
    end
    
    # Vital Rhythm
    if battle.pbCheckSameSideAbility(:VITALRHYTHM)
        healing += battler.getFractionalHealingAmount(1.0/16.0, aiCheck: true)
    end

    # Leftovers
    GameData::Item.getByFlag("Leftovers").each do |leftoversItem|
        next unless battler.hasActiveItemAI?(leftoversItem)
        healing += battler.getFractionalHealingAmount(LEFTOVERS_HEALING_FRACTION)
    end

    # Black Sludge
    if battler.hasActiveItemAI?(:BLACKSLUDGE) && battler.pbHasType?(:POISON)
        healing += battler.getFractionalHealingAmount(LEFTOVERS_HEALING_FRACTION)
    end

    # Harvest, Larder

    return healing
end

def getAquaRingEffectScore(user)
    return 0 if user.effectActive?(:AquaRing)
	return 0 if user.effects[:PerishSong] > 0

    score = 40
    score += 20 if user.hp > user.totalhp * 0.5
	score += 20 if user.hp > user.totalhp * 0.75
    return score
end

def getSubstituteEffectScore(user)
    score = 0
    user.eachOpposing(true) do |b|
        if !b.canActThisTurn?
            score += 80
        elsif !b.hasDamagingAttack?
            score += 60
        elsif !b.hasSoundMove?
            score += 40
        end
    end
    score += user.getHealingEffectScore(predictedEOTHealing(user.battle,user)) / 2
    score += 20 if user.hasSetupMove?
    score += 20 if user.firstTurn?
    return score
end

def getWeatherResetEffectScore(user)
    if user.inWeatherTeam
        return -80
    else
        return 80
    end
end

def getGreyMistSettingEffectScore(user,duration)
    score = 0
    user.battle.eachBattler do |b|
        if b.opposes?(user)
            score += statStepsValueScore(b)
            score += 15 * duration if b.hasSetupMove? && score = 0
        else
            score -= statStepsValueScore(b)
        end
    end
    return score
end

def getReflectEffectScore(user, baseDuration = nil, move = nil)
    return getScreenEffectScore(user, :Reflect, baseDuration, move)
end

def getLightScreenEffectScore(user, baseDuration = nil, move = nil)
    return getScreenEffectScore(user, :LightScreen, baseDuration, move)
end

def getDiamondFieldEffectScore(user, baseDuration = nil, move = nil)
    return getScreenEffectScore(user, :DiamondField, baseDuration, move)
end

def getScreenEffectScore(user, effect, baseDuration = nil, move = nil)
    score = 0
    # Current turn value
    unless user.pbOwnSide.effectActive?(effect)
        user.eachOpposing do |b|
            next if b.ignoreScreens?(true)
            next if effect == :Reflect && !b.hasSpecialAttack?
            next if effect == :LightScreen && !b.hasSpecialAttack?
            next if effect == :AuroraVeil && !b.hasDamagingAttack?
            next if effect == :DiamondField && !b.hasDamagingAttack?

            score += 60 if !move || user.battle.battleAI.userMovesFirst?(move, user, b)
        end
    end
    foeCanBreak = false
    user.eachOpposing do |opp|
        next unless opp.hasScreenRemovalMove?
        foeCanBreak = true
        score /= 2
        break  
    end
    foeIgnoresScreens = false
    user.eachOpposing do |opp|
        next unless opp.ignoreScreens?(true)
        foeIgnoresScreens = true
        break
    end
    unless foeCanBreak
        duration = baseDuration ? user.getScreenDuration(baseDuration,aiCheck: true) : user.getScreenDuration(aiCheck: true)
        duration -= user.pbOwnSide.countEffect(effect) if user.pbOwnSide.effectActive?(effect)
        if effect == :AuroraVeil
            score += 15 * duration
        else
            score += 10 * duration  
        end
        score = (score * 1.3).ceil if user.fullHealth?
    end
    if foeIgnoresScreens
        score = (score * 0.7).floor
    end
    return score  
end

def getSafeguardEffectScore(user, duration)
    score = 0
    duration -= user.pbOwnSide.countEffect(:Safeguard) if user.pbOwnSide.effectActive?(:Safeguard)
    user.battle.eachSameSideBattler(user.index) do |b|
        score += duration * 5
        score += 10 if b.hasSpotsForStatus?
    end
    
    return score
end

def getNaturalProtectionEffectScore(user, duration)
    score = 0
    duration -= user.pbOwnSide.countEffect(:NaturalProtection) if user.pbOwnSide.effectActive?(:NaturalProtection)
    user.battle.eachSameSideBattler(user.index) do |b|
        score += duration * 5
        score += 20 if b.burned? || b.frostbitten? || b.poisoned? || b.leeched?
        score += 40 if b.hasRecoilMove?
    end
    score += 30 if user.battle.sandy? || user.battle.icy?
    
    return score
end

def getLuckyChantEffectScore(user, duration)
    score = 0
    duration -= user.pbOwnSide.countEffect(:LuckyChant) if user.pbOwnSide.effectActive?(:LuckyChant)
    user.battle.eachSameSideBattler(user.index) do |b|
        score += duration * 5
    end

    return score
end

def getTailwindEffectScore(user, duration, move = nil)
    score = 0

    # Current turn value
    unless user.pbOwnSide.effectActive?(:Tailwind)
        user.eachAlly do |b|
            score += 10
            score += 40 if !move || user.battle.battleAI.userMovesFirst?(move, user, b)
        end
    end

    # Lingering Value
    duration -= user.pbOwnSide.countEffect(:Tailwind) if user.pbOwnSide.effectActive?(:Tailwind)
    user.battle.eachSameSideBattler(user.index) do |b|
        score += duration * 20
    end

    return score
end

def getGravityEffectScore(user, duration)
    score = 0
    duration -= user.battle.field.countEffect(:Gravity) if user.battle.gravityIntensified?
    user.battle.eachBattler do |b|
        bScore = 0
        bScore -= 4 if b.airborne?(true)
        bScore += 4 if b.hasInaccurateMove?
        bScore += 10 if b.hasLowAccuracyMove?
        bScore *= duration
        bScore *= -1 if b.opposes?(user)

        score += bScore
    end
    return score
end

def getDisableEffectScore(target, duration)
    return 0 if target.hasActiveAbilityAI?(:MENTALBLOCK)
    return 0 unless target.canBeDisabled?
    score = 15 * duration
    score *= 1.5 if target.trapped?
    return score
end

def randomMovesEffectScore(user,move)
    if user.ownersPolicies.include?(:ALLOW_RANDOM_MOVES)
        return 100
    else
        echoln("The AI will never use #{move.name}")
        return -1000  
    end  
end