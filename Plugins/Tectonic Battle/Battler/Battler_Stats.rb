class PokeBattle_Battler
    def getPlainStat(stat)
        case stat
        when :ATTACK
            return attack
        when :DEFENSE
            return defense
        when :SPECIAL_ATTACK
            return spatk
        when :SPECIAL_DEFENSE
            return spdef
        when :SPEED
            return speed
        end
        return -1
    end

    def plainStats
        ret = {}
        ret[:ATTACK]          = attack
        ret[:DEFENSE]         = defense
        ret[:SPECIAL_ATTACK]  = spatk
        ret[:SPECIAL_DEFENSE] = spdef
        ret[:SPEED]           = speed
        return ret
    end

    def tribalBonusForStat(stat)
        return 0 unless owner
        return owner.tribalBonus.getTribeBonusStats(self)[stat]
    end

    def allStatBonus
        return 0
    end

    def puzzleRoom?
        return @battle.field.effectActive?(:PuzzleRoom)
    end

    def oddRoom?
        return @battle.field.effectActive?(:OddRoom)
    end

    def wonderRoom?
        return false
    end

    def attack
        if puzzleRoom? && oddRoom?
            return base_special_defense
        elsif puzzleRoom? && !oddRoom?
            return base_special_attack
        elsif oddRoom? && !puzzleRoom?
            return base_defense
        else
            return base_attack
        end
    end

    def defense
        if wonderRoom? && oddRoom?
            return base_special_attack
        elsif wonderRoom? && !oddRoom?
            return base_special_defense
        elsif oddRoom? && !wonderRoom?
            return base_attack
        else
            return base_defense
        end
    end

    def spatk
        if puzzleRoom? && oddRoom?
            return base_defense
        elsif puzzleRoom? && !oddRoom?
            return base_attack
        elsif oddRoom? && !puzzleRoom?
            return base_special_defense
        else
            return base_special_attack
        end
    end

    def spdef
        if wonderRoom? && oddRoom?
            return base_attack
        elsif wonderRoom? && !oddRoom?
            return base_defense
        elsif oddRoom? && !wonderRoom?
            return base_special_attack
        else
            return base_special_defense
        end
    end

    OFFENSIVE_LOCK_STAT = 120

    DEFENSIVE_LOCK_STAT = 95

    def speed
        return base_speed
    end

    # Don't use for HP
    def recalcStat(stat, base)
        return calcStatGlobal(base, @level, @pokemon.ev[stat], stylish: hasActiveAbility?(:STYLISH), accumulation: hasActiveAbility?(:ACCUMULATION))
    end

    def base_attack
        return @effects[:BaseAttack] if effectActive?(:BaseAttack)
        attack_bonus = tribalBonusForStat(:ATTACK)
        attack_bonus += allStatBonus
        if hasActiveItem?(%i[POWERLOCK POWERKEY])
            return recalcStat(:ATTACK, OFFENSIVE_LOCK_STAT) + attack_bonus
        else
            return @attack + attack_bonus
        end
    end

    def base_defense
        return @effects[:BaseDefense] if effectActive?(:BaseDefense)
        defense_bonus = tribalBonusForStat(:DEFENSE)
        defense_bonus += allStatBonus
        if hasActiveItem?(:GUARDLOCK)
            return recalcStat(:DEFENSE, DEFENSIVE_LOCK_STAT) + defense_bonus
        elsif hasActiveItem?(:POWERKEY)
            return recalcStat(:DEFENSE, OFFENSIVE_LOCK_STAT) + defense_bonus
        else
            return @defense + defense_bonus
        end
    end

    def base_special_attack
        return @effects[:BaseSpecialAttack] if effectActive?(:BaseSpecialAttack)
        spatk_bonus = tribalBonusForStat(:SPECIAL_ATTACK)
        spatk_bonus += allStatBonus
        if hasActiveItem?(%i[ENERGYLOCK ENERGYKEY])
            return recalcStat(:SPECIAL_ATTACK, OFFENSIVE_LOCK_STAT) + spatk_bonus
        else
            return @spatk + spatk_bonus
        end
    end

    def base_special_defense
        return @effects[:BaseSpecialDefense] if effectActive?(:BaseSpecialDefense)
        spdef_bonus = tribalBonusForStat(:SPECIAL_DEFENSE)
        spdef_bonus += allStatBonus
        if hasActiveItem?(:WILLLOCK)
            return recalcStat(:SPECIAL_DEFENSE, DEFENSIVE_LOCK_STAT) + spdef_bonus
        elsif hasActiveItem?(:ENERGYKEY)
            return recalcStat(:SPECIAL_DEFENSE, OFFENSIVE_LOCK_STAT) + spdef_bonus
        else
            return @spdef + spdef_bonus
        end
    end

    def base_speed
        return @effects[:BaseSpeed] if effectActive?(:BaseSpeed)
        speed_bonus = tribalBonusForStat(:SPEED)
        speed_bonus += allStatBonus
        return @speed + speed_bonus
    end

    #=============================================================================
    # Query about stats after room modification, steps, abilities and item modifiers.
    #=============================================================================
    AI_CHEATS_FOR_STAT_ABILITIES = true

    def pbAttack(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        attack = statAfterStep(:ATTACK, step)
        attackMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            attackMult = BattleHandlers.triggerAttackCalcUserAbility(ability, self, @battle, attackMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                attackMult = BattleHandlers.triggerAttackCalcAllyAbility(ability, self, @battle, attackMult)
            end
        end

        eachActiveItem do |item|
            attackMult = BattleHandlers.triggerAttackCalcUserItem(item, self, battle, attackMult)
        end

        # Dragon Ride
        attackMult *= 2.0 if effectActive?(:OnDragonRide)

        # Calculation
        return [(attack * attackMult).round, 1].max
    end

    def pbSpAtk(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        special_attack = statAfterStep(:SPECIAL_ATTACK, step)
        spAtkMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            spAtkMult = BattleHandlers.triggerSpecialAttackCalcUserAbility(ability, self, @battle, spAtkMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                spAtkMult = BattleHandlers.triggerSpecialAttackCalcAllyAbility(ability, self, @battle, spAtkMult)
            end
        end

        eachActiveItem do |item|
            spAtkMult = BattleHandlers.triggerSpecialAttackCalcUserItem(item, self, battle, spAtkMult)
        end

        # Calculation
        return [(special_attack * spAtkMult).round, 1].max
    end

    def pbDefense(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        defense = statAfterStep(:DEFENSE, step)
        defenseMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            defenseMult = BattleHandlers.triggerDefenseCalcUserAbility(ability, self, @battle, defenseMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                next if ally.ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
                defenseMult = BattleHandlers.triggerDefenseCalcAllyAbility(ability, self, @battle, defenseMult)
            end
        end

        eachActiveItem do |item|
            defenseMult = BattleHandlers.triggerDefenseCalcUserItem(item, self, battle, defenseMult)
        end
        
        defenseMult *= 1.3 if hasTribeBonus?(:SCRAPPER)

        # Hail and Ice Age
        if @battle.icy? && (pbHasType?(:ICE) || (pbHasType?(:GHOST) && @battle.pbWeather == :IceAge))
            hailAddition = 0.5
            hailAddition *= 2 if @battle.pbCheckGlobalAbility(:BITTERCOLD)
            hailAddition *= 2 if @battle.curseActive?(:CURSE_BOOSTED_HAIL)
            defenseMult *= (1 + hailAddition)
        end

        # Calculation
        return [(defense * defenseMult).round, 1].max
    end

    def pbSpDef(aiCheck = false, step = nil)
        return 1 if fainted? && !dummy?
        special_defense = statAfterStep(:SPECIAL_DEFENSE, step)
        spDefMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            spDefMult = BattleHandlers.triggerSpecialDefenseCalcUserAbility(ability, self, @battle, spDefMult)
        end
        eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                spDefMult = BattleHandlers.triggerSpecialDefenseCalcAllyAbility(ability, self, @battle, spDefMult)
            end
        end

        eachActiveItem do |item|
            spDefMult = BattleHandlers.triggerSpecialDefenseCalcUserItem(item, self, battle, spDefMult)
        end
        
        spDefMult *= 1.3 if hasTribeBonus?(:RADIANT)

        # Sandstorm and Star Storm
        if @battle.sandy? && (pbHasType?(:ROCK) || (pbHasType?(:GROUND) && @battle.pbWeather == :StarStorm))
            sandAddition = 0.5
            sandAddition *= 2 if @battle.pbCheckGlobalAbility(:IRONSTORM)
            sandAddition *= 2 if @battle.curseActive?(:CURSE_BOOSTED_SAND)
            spDefMult *= (1 + sandAddition)
        end

        # Calculation
        return [(special_defense * spDefMult).round, 1].max
    end

    def pbSpeed(aiCheck = false, step = nil, afterSwitching: false, move: nil)
        return 1 if fainted? && !dummy?
        speed = statAfterStep(:SPEED, step)
        speedMult = 1.0

        eachActiveAbility do |ability|
            next if ignoreAbilityInAI?(ability,aiCheck) && !AI_CHEATS_FOR_STAT_ABILITIES
            speedMult = BattleHandlers.triggerSpeedCalcAbility(ability, self, speedMult)
        end

        # Item effects that alter calculated Speed
        eachActiveItem do |item|
            speedMult = BattleHandlers.triggerSpeedCalcItem(item, self, speedMult)
        end
        
        # Other effects
        unless afterSwitching
            speedMult *= 2.0 if pbOwnSide.effectActive?(:Tailwind) || pbOwnSide.effectActive?(:EmpoweredTailwind)
            speedMult /= 2.0 if pbOwnSide.effectActive?(:Swamp)
            speedMult *= 2.0 if effectActive?(:OnDragonRide)
        end
        
        # Numb
        numbRelevant = numbed?
        numbRelevant = false if afterSwitching && hasActiveAbilityAI?(:NATURALCURE)
        if numbRelevant
            speedMult /= 2.0
            speedMult /= 2.0 if pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            speedMult /= 2.0 if shouldAbilityApply?(:CLEANFREAK, aiCheck)
        end

        # Waterlog
        waterlogRelevant = waterlogged?
        waterlogRelevant = false if afterSwitching && hasActiveAbilityAI?(:NATURALCURE)
        if waterlogRelevant
            speedMult /= 2.0
            speedMult /= 2.0 if pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            speedMult /= 2.0 if shouldAbilityApply?(:CLEANFREAK, aiCheck)
        end

        speedMult *= applySpeedTriggers(move,true) if aiCheck

        # Stampede tribe
        speedMult *= 1.15 if hasTribeBonus?(:STAMPEDE)

        # Calculation
        return [(speed * speedMult).round, 1].max
    end

    def applySpeedTriggers(move = nil,aiCheck = false)
        aiSpeedMult = 1.0

        if shouldItemApply?(:AGILITYHERB,aiCheck)
            if aiCheck
                aiSpeedMult *= 2.0
            else
                applyEffect(:AgilityHerb)
                @battle.pbCommonAnimation("UseItem",self)
                @battle.pbDisplay(_INTL("{1} moves at doubled speed thanks to its {2}!", pbThis, getItemName(:AGILITYHERB)))
            end
        end

        eachAbilityShouldApply(aiCheck) do |ability|
            aiSpeedMult = BattleHandlers.triggerMoveSpeedModifierAbility(ability, self, move, @battle, aiSpeedMult, aiCheck)
        end

        return aiSpeedMult
    end

    def getFinalStat(stat, aiCheck = false, step = nil)
        case stat
        when :ATTACK
            return pbAttack(aiCheck, step)
        when :DEFENSE
            return pbDefense(aiCheck, step)
        when :SPECIAL_ATTACK
            return pbSpAtk(aiCheck, step)
        when :SPECIAL_DEFENSE
            return pbSpDef(aiCheck, step)
        when :SPEED
            return pbSpeed(aiCheck, step)
        end
        return -1
    end
end
