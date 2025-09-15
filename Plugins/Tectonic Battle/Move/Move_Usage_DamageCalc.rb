DAMAGE_CALC_DEBUG = false

class PokeBattle_Move
    #=============================================================================
    # Final damage calculation
    #=============================================================================
    def pbCalcDamage(user,target,numTargets=1)
        return if statusMove?

        if target.damageState.disguise
            target.damageState.calcDamage = 1
            return
        end

        if target.damageState.thiefsDiversion
            target.damageState.calcDamage = 0
            return
        end

        # Get the move's type
        type = @calcType # nil is treated as physical
        
        # Calcuate base power of move
        baseDmg = pbBaseDamage(@baseDamage,user,target)

        # Calculate whether this hit deals critical damage
        target.damageState.critical,target.damageState.forced_critical = pbIsCritical?(user,target)
        
        # Calculate the actual damage dealt, and assign it to the damage state for tracking
        target.damageState.calcDamage = calculateDamageForHit(user,target,type,baseDmg,numTargets)
    end

    def calculateDamageForHitAI(user,target,type,baseDmg,numTargets)
        calculateDamageForHit(user,target,type,baseDmg,numTargets,true)
    end

    def calculateDamageForHit(user,target,type,baseDmg,numTargets,aiCheck=false)
        echoln("[DAMAGE CALC] Calcing damage based on given base power #{baseDmg} and type #{type}") if DAMAGE_CALC_DEBUG
        
        # Get the relevant attacking and defending stat values (after steps)
        attack, defense = damageCalcStats(user,target,aiCheck)

        # Calculate all multiplier effects
        multipliers = initializeMultipliers
        pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers,aiCheck)

        # Main damage calculation
        finalCalculatedDamage = calcDamageWithMultipliers(baseDmg,attack,defense,user.level,multipliers)
        finalCalculatedDamage  = [(finalCalculatedDamage * multipliers[:final_damage_multiplier]).round, 1].max
        finalCalculatedDamage = flatDamageModifiers(finalCalculatedDamage,user,target,type,aiCheck)

        # Delayed Reaction
        if !@battle.moldBreaker && target.shouldAbilityApply?(:DELAYEDREACTION,aiCheck)
            delayedDamage = (finalCalculatedDamage * 0.33).floor
            finalCalculatedDamage -=  delayedDamage
            if delayedDamage > 0 && !aiCheck
                target.effects[:DelayedReaction] = [] unless target.effectActive?(:DelayedReaction)
                target.effects[:DelayedReaction].push([2,delayedDamage])
            end
        end

        if target.boss?
            # All damage up to the phase lower health bound is unmodified
            unmodifiedDamage = [target.hp - target.avatarPhaseLowerHealthBound,finalCalculatedDamage].min
            unmodifiedDamage = 0 if unmodifiedDamage < 0

            # All further damage is reduced
            modifiedDamage = finalCalculatedDamage - unmodifiedDamage
            modifiedDamage = (modifiedDamage * (1 - AVATAR_OVERKILL_RESISTANCE)).floor

            finalCalculatedDamage = unmodifiedDamage + modifiedDamage
        end

        return finalCalculatedDamage
    end

    def initializeMultipliers
        return {
            :base_damage_multiplier  => 1.0,
            :attack_multiplier       => 1.0,
            :defense_multiplier      => 1.0,
            :final_damage_multiplier => 1.0
        }
    end

    def calcDamageWithMultipliers(baseDmg,attack,defense,userLevel,multipliers)
        baseDmg = [(baseDmg * multipliers[:base_damage_multiplier]).round, 1].max
        attack  = [(attack  * multipliers[:attack_multiplier]).round, 1].max
        defense = [(defense * multipliers[:defense_multiplier]).round, 1].max
        damage  = calcBasicDamage(baseDmg,userLevel,attack,defense)
        return damage
    end

    def printMultipliers(multipliers)
        echoln("The calculated base damage multiplier: #{multipliers[:base_damage_multiplier]}")
        echoln("The calculated attack and defense multipliers: #{multipliers[:attack_multiplier]},#{multipliers[:defense_multiplier]}")
        echoln("The calculated final damage multiplier: #{multipliers[:final_damage_multiplier]}")
    end

    def calcBasicDamage(base_damage,attacker_level,user_attacking_stat,target_defending_stat)
        pseudoLevel = 15.0 + (attacker_level.to_f / 2.0)
        levelMultiplier = 2.0 + (0.4 * pseudoLevel)
        damage  = 2.0 + ((levelMultiplier * base_damage.to_f * user_attacking_stat.to_f / target_defending_stat.to_f) / 50.0).floor
        return damage
    end

    def damageCalcStats(user,target,aiCheck=false)
        # Calculate user's attack stat
        attacking_stat_holder, attacking_stat = pbAttackingStat(user,target)

        if user.shouldAbilityApply?(:MALICIOUSGLOW,aiCheck) && @battle.moonGlowing?
            attacking_stat_holder = target
        end

        attack_step = attacking_stat_holder.steps[attacking_stat]
        critical = aiCheck ? pbIsCritical?(user,target,true) : target.damageState.critical
        attack_step = 0 if critical && attack_step < 0
        attack_step = 0 if targetIsUnaware?(target) && !@battle.moldBreaker
        attack = attacking_stat_holder.getFinalStat(attacking_stat, aiCheck, attack_step)
        # Calculate target's defense stat
        defending_stat_holder, defending_stat = pbDefendingStat(user,target)
        defense_step = defending_stat_holder.steps[defending_stat]
        if defense_step > 0 &&
                (ignoresDefensiveStepBoosts?(user,target) || user.hasActiveAbility?(:INFILTRATOR) || critical)
            defense_step = 0
        end
        defense_step = 0 if userIsUnaware?(user)
        defense = defending_stat_holder.getFinalStat(defending_stat, aiCheck, defense_step)
        echoln("[DAMAGE CALC] Calcing damage based on #{attacking_stat_holder.pbThis(true)}'s final #{attacking_stat} of #{attack} and #{defending_stat_holder.pbThis(true)}'s final #{defending_stat} of #{defense}") if DAMAGE_CALC_DEBUG
        return attack, defense
    end

    def userIsUnaware?(user, aiCheck: false)
        return true if user.shouldAbilityApply?(:UNAWARE, aiCheck)
        return true if user.shouldAbilityApply?(:BLADEBRAINED, aiCheck) && bladeMove?
        return true if user.shouldAbilityApply?(:TUNEDOUT, aiCheck) && soundMove?
        return true if empoweredMove?
        return false
    end

    def targetIsUnaware?(target, aiCheck: false)
        return true if target.shouldAbilityApply?(:UNAWARE, aiCheck)
        return false
    end
    
    def pbCalcAbilityDamageMultipliers(user,target,type,baseDmg,multipliers,aiCheck=false)
        # Global abilities
        if (@battle.pbCheckGlobalAbility(:DARKAURA) && type == :DARK) ||
            (@battle.pbCheckGlobalAbility(:FAIRYAURA) && type == :FAIRY)
            if @battle.pbCheckGlobalAbility(:AURABREAK)
                multipliers[:base_damage_multiplier] *= 2 / 3.0
            else
                multipliers[:base_damage_multiplier] *= 4 / 3.0
            end
        end
        if @battle.pbCheckGlobalAbility(:RUINOUS)
            multipliers[:base_damage_multiplier] *= 1.4
        end
        # User or user ally ability effects that alter damage
        user.eachAbilityShouldApply(aiCheck) do |ability|
            BattleHandlers.triggerDamageCalcUserAbility(ability,user,target,self,multipliers,baseDmg,type,aiCheck)
        end
        user.eachAlly do |b|
            b.eachAbilityShouldApply(aiCheck) do |ability|
                BattleHandlers.triggerDamageCalcUserAllyAbility(ability,user,target,self,multipliers,baseDmg,type,aiCheck)
            end
        end
        # Target or target ally ability effects that alter damage
        unless @battle.moldBreaker
            target.eachAbilityShouldApply(aiCheck) do |ability|
                BattleHandlers.triggerDamageCalcTargetAbility(ability,user,target,self,multipliers,baseDmg,type,aiCheck)
            end
            target.eachAlly do |b|
                b.eachAbilityShouldApply(aiCheck) do |ability|
                    BattleHandlers.triggerDamageCalcTargetAllyAbility(ability,user,target,self,multipliers,baseDmg,type,aiCheck)
                end
            end
        end
    end

    def pbCalcWeatherDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        weather = @battle.pbWeather
        case weather
        when :Sunshine, :HarshSun
            if type == :FIRE || (type == :GRASS && weather == :HarshSun)
                damageBonus = weather == :HarshSun ? 0.5 : 0.3
                damageBonus *= 2 if @battle.curseActive?(:CURSE_BOOSTED_SUN)
                multipliers[:final_damage_multiplier] *= (1 + damageBonus)
            elsif applySunDebuff?(user,type,checkingForAI)
                damageReduction = 0.15
                damageReduction *= 2 if @battle.pbCheckGlobalAbility(:BLINDINGLIGHT)
                damageReduction *= 2 if @battle.curseActive?(:CURSE_BOOSTED_SUN)
                multipliers[:final_damage_multiplier] *= (1 - damageReduction)
            end
        when :Rainstorm, :HeavyRain
            if type == :WATER || (type == :ELECTRIC && weather == :HeavyRain)
                damageBonus = weather == :HeavyRain ? 0.5 : 0.3
                damageBonus *= 2 if @battle.curseActive?(:CURSE_BOOSTED_RAIN)
                multipliers[:final_damage_multiplier] *= (1 + damageBonus)
            elsif applyRainDebuff?(user,type,checkingForAI)
                damageReduction = 0.15
                damageReduction *= 2 if @battle.pbCheckGlobalAbility(:DREARYCLOUDS)
                damageReduction *= 2 if @battle.curseActive?(:CURSE_BOOSTED_RAIN)
                multipliers[:final_damage_multiplier] *= (1 - damageReduction)
            end
        when :Eclipse,:RingEclipse
            if type == :PSYCHIC || (type == :DRAGON && weather == :RingEclipse)
                damageBonus = weather == :RingEclipse ? 0.5 : 0.3
                multipliers[:final_damage_multiplier] *= (1 + damageBonus)
            end

            if @battle.pbCheckOpposingAbility(:DISTRESSING,user.index)
                multipliers[:final_damage_multiplier] *= 0.8
            end
        when :Moonglow,:BloodMoon
            if type == :FAIRY || (type == :DARK && weather == :BloodMoon)
                damageBonus = weather == :BloodMoon ? 0.5 : 0.3
                multipliers[:final_damage_multiplier] *= (1 + damageBonus)
            end
        end
    end

    def pbCalcStatusesDamageMultipliers(user,target,multipliers,checkingForAI=false)
        toil = @battle.pbCheckOpposingAbility(:TOILANDTROUBLE, user.index)
        # Burn
        if user.burned? && physicalMove? && damageReducedByBurn? && !user.shouldAbilityApply?(:BURNHEAL,checkingForAI)
            damageReduction = (1.0/3.0)
            damageReduction = (1.0/5.0) if user.boss? && AVATAR_DILUTED_STATUS_CONDITIONS
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            damageReduction *= 1.5 if toil
            damageReduction *= 2 if user.hasActiveAbility?(:CLEANFREAK)
            damageReduction = 1 if damageReduction > 1
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Frostbite
        if user.frostbitten? && specialMove? && damageReducedByBurn? && !user.shouldAbilityApply?(:FROSTHEAL,checkingForAI)
            damageReduction = (1.0/3.0)
            damageReduction = (1.0/5.0) if user.boss? && AVATAR_DILUTED_STATUS_CONDITIONS
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            damageReduction *= 1.5 if toil
            damageReduction *= 2 if user.hasActiveAbility?(:CLEANFREAK)
            damageReduction = 1 if damageReduction > 1
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Numb
        if user.numbed?
            damageReduction = (1.0/4.0)
            damageReduction = (3.0/20.0) if user.boss? && AVATAR_DILUTED_STATUS_CONDITIONS
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            damageReduction *= 1.5 if toil
            damageReduction *= 2 if user.hasActiveAbility?(:CLEANFREAK)
            damageReduction = 1 if damageReduction > 1
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Dizzy
        if target.dizzy? && !target.shouldAbilityApply?([:MARVELSKIN,:MARVELSCALE],checkingForAI)
            damageIncrease = (1.0/4.0)
            damageIncrease = (3.0/20.0) if target.boss? && AVATAR_DILUTED_STATUS_CONDITIONS
            damageIncrease *= 2 if target.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            damageIncrease *= 2 if target.hasActiveAbility?(:CLEANFREAK)
            multipliers[:final_damage_multiplier] *= (1.0 + damageIncrease)
        end
        # Waterlog
        if target.waterlogged? && !target.shouldAbilityApply?([:MARVELSKIN,:MARVELSCALE],checkingForAI)
            damageIncrease = (1.0/4.0)
            damageIncrease = (3.0/20.0) if target.boss? && AVATAR_DILUTED_STATUS_CONDITIONS
            damageIncrease *= 2 if target.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            damageIncrease *= 2 if target.hasActiveAbility?(:CLEANFREAK)
            multipliers[:final_damage_multiplier] *= (1.0 + damageIncrease)
        end
        # Fracture
        if user.effectActive?(:Fracture)
            multipliers[:final_damage_multiplier] *= 0.66
        end
    end

    def pbCalcProtectionsDamageMultipliers(user,target,multipliers,checkingForAI=false)
        # Aurora Veil, Reflect, Light Screen
        if !ignoresReflect? && !target.damageState.critical && !user.ignoreScreens?(checkingForAI)
            if target.pbOwnSide.effectActive?(:AuroraVeil)
                if @battle.pbSideBattlerCount(target)>1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            elsif target.pbOwnSide.effectActive?(:Reflect) && physicalMove?
                if @battle.pbSideBattlerCount(target)>1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            elsif target.pbOwnSide.effectActive?(:LightScreen) && specialMove?
                if @battle.pbSideBattlerCount(target) > 1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            elsif target.pbOwnSide.effectActive?(:DiamondField)
                if @battle.pbSideBattlerCount(target) > 1
                    multipliers[:final_damage_multiplier] *= 3 / 4.0
                else
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                end
            end
        else
            if !checkingForAI &&  
                (target.pbOwnSide.effectActive?(:Reflect) ||
                target.pbOwnSide.effectActive?(:LightScreen) ||
                target.pbOwnSide.effectActive?(:AuroraVeil) ||
                target.pbOwnSide.effectActive?(:DiamondField))
                GameData::Ability.each do |ability_data|
                next unless ability_data.flags&.include?("IgnoreScreens")
                if user.hasAbility?(ability_data.id)
                user.aiLearnsAbility(ability_data.id)
                end
                end
            end

            # Repulsion Field
            if baseDamage >= 100 && target.pbOwnSide.effectActive?(:RepulsionField)
                if @battle.pbSideBattlerCount(target) > 1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            end
        end
        # Partial protection moves
        if target.effectActive?([:StunningCurl,:RootShelter,:VenomGuard,:Floodgate])
            multipliers[:final_damage_multiplier] *= 0.5
        end
        if target.effectActive?(:EmpoweredDetect)
            multipliers[:final_damage_multiplier] *= 0.5
        end
        if target.pbOwnSide.effectActive?(:Bulwark)
            multipliers[:final_damage_multiplier] *= 0.5
        end
        # For when bosses are partway piercing protection
        if target.damageState.partiallyProtected
            multipliers[:final_damage_multiplier] *= 0.5
        end
    end

    def pbCalcTypeBasedDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        stabActive = false
        if user.shouldAbilityApply?(:IMPRESSIONABLE,checkingForAI)
            anyPartyMemberHasType = false
            user.ownerParty.each do |partyMember|
                next unless partyMember
                next if partyMember.personalID == user.personalID
                next unless type && partyMember.hasType?(type)
                anyPartyMemberHasType = true
                break
            end
            stabActive = true if anyPartyMemberHasType
        else
            stabActive = true if type && user.pbHasType?(type)
            if checkingForAI
                stabActive = true if user.hasActiveAbilityAI?(%i[PROTEAN FREESTYLE])
                stabActive = true if user.hasActiveAbilityAI?(:MUTABLE) && !user.effectActive?(:Mutated)
                stabActive = true if user.hasActiveAbilityAI?(:SHAKYCODE) && @battle.eclipsed?
            end
        end
        stabActive = false if user.pbOwnedByPlayer? && @battle.curses.include?(:DULLED)
        stabActive = false if @battle.pbCheckGlobalAbility(:SIGNALJAM)

        # STAB
        if stabActive
            stab = 1.5
            if user.shouldAbilityApply?(:ADAPTED,checkingForAI)
                stab *= 4.0/3.0
            elsif user.shouldAbilityApply?(:ULTRAADAPTED,checkingForAI)
                stab *= 3.0/2.0
            end
            multipliers[:final_damage_multiplier] *= stab
        end

        # Type effectiveness
        typeMod = target.typeMod(type,target,self,checkingForAI)
        effectiveness = @battle.typeEffectivenessMult(typeMod)
        multipliers[:final_damage_multiplier] *= effectiveness

        echoln("[DAMAGE CALC] Calcing damage based on expected type effectiveness mult of #{effectiveness}") if DAMAGE_CALC_DEBUG

        # Charge
        if user.effectActive?(:EnergyCharge) && type == :ELECTRIC
            multipliers[:base_damage_multiplier] *= 2
            user.applyEffect(:EnergyChargeExpended) unless checkingForAI
        end

        # Turbulent Sky
        if user.pbOwnSide.effectActive?(:TurbulentSky)
            multipliers[:final_damage_multiplier] *= 1.3
        end

        # Empowered Tailwind
        if user.pbOwnSide.effectActive?(:EmpoweredTailwind)
            multipliers[:final_damage_multiplier] *= 1.3
        end
    end

    def pbCalcTribeBasedDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        # Bushwacker tribe
        if user.hasTribeBonus?(:BUSHWACKER)
            if checkingForAI
                expectedTypeMod = @battle.battleAI.pbCalcTypeModAI(type, user, target, self)
                multipliers[:final_damage_multiplier] *= 1.5 if Effectiveness.resistant?(expectedTypeMod)
            else
                multipliers[:final_damage_multiplier] *= 1.5 if Effectiveness.resistant?(target.damageState.typeMod)
            end
        end

        # Assassin tribe
        if user.hasTribeBonus?(:ASSASSIN) && user.firstTurn?
            multipliers[:final_damage_multiplier] *= 1.2
        end

        # Artillery tribe
        if user.hasTribeBonus?(:ARTILLERY) && !user.firstTurn?
            multipliers[:final_damage_multiplier] *= 1.2
        end

        # Mystic tribe
        if user.hasTribeBonus?(:MYSTIC) && user.lastRoundMoveCategory == 2 # Status
            multipliers[:final_damage_multiplier] *= 1.25
        end

        # Deceiver tribe
        if user.hasTribeBonus?(:DECEIVER) && user.species_data
            multipliers[:final_damage_multiplier] *= 1.15 unless user.species_data.hasType?(type)
        end

        # Scavenger tribe
        if user.hasTribeBonus?(:DECEIVER)
            if checkingForAI
                multipliers[:final_damage_multiplier] *= 1.25 if user.hasGem?
            else
                multipliers[:final_damage_multiplier] *= 1.25 if user.effectActive?(:GemConsumed)
            end
        end

        # Tactician tribe
        if user.hasTribeBonus?(:TACTICIAN)
            if checkingForAI
                multipliers[:final_damage_multiplier] *= 1.15 if @battle.battleAI.userMovesFirst?(self, user, target)
            elsif !target.movedThisRound?  
                echoln("TACTICIAN ACTIVATING!!!")
                multipliers[:final_damage_multiplier] *= 1.15
            end    
        end

        # Harmonic tribe
        if target.hasTribeBonus?(:HARMONIC)
            multipliers[:final_damage_multiplier] *= 0.9
        end

        # Charmer tribe
        if target.hasTribeBonus?(:CHARMER) && target.effectActive?(:SwitchedIn)
            multipliers[:final_damage_multiplier] *= 0.8
        end

        # Warrior tribe
        if target.hasTribeBonus?(:WARRIOR) && target.effectActive?(:ChoseAttack)
            multipliers[:final_damage_multiplier] *= 0.85
        end

        # Noble tribe
        if target.hasTribeBonus?(:NOBLE) && target.effectActive?(:ChoseStatus)
            multipliers[:final_damage_multiplier] *= 0.85
        end
    end
      
    def pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers,aiCheck=false)
        pbCalcAbilityDamageMultipliers(user,target,type,baseDmg,multipliers,aiCheck)
        pbCalcWeatherDamageMultipliers(user,target,type,multipliers,aiCheck)
        pbCalcStatusesDamageMultipliers(user,target,multipliers,aiCheck)
        pbCalcProtectionsDamageMultipliers(user,target,multipliers,aiCheck)
        pbCalcTypeBasedDamageMultipliers(user,target,type,multipliers,aiCheck)
        pbCalcTribeBasedDamageMultipliers(user,target,type,multipliers,aiCheck)

        # Item effects that alter damage
        user.eachItemShouldApply(aiCheck) do |item|
            BattleHandlers.triggerDamageCalcUserItem(item,user,target,self,multipliers,baseDmg,type,aiCheck)
        end
        target.eachItemShouldApply(aiCheck) do |item|
            BattleHandlers.triggerDamageCalcTargetItem(item,user,target,self,multipliers,baseDmg,type,aiCheck)
        end

        if target.effectActive?(:DeathMark)
            multipliers[:final_damage_multiplier] *= 1.5
        end
        
        if aiCheck
            # Parental Bond
            if user.hasActiveAbility?(:PARENTALBOND) || (user.hasActiveAbility?(:STRIKETWICE) && @battle.rainy?)
                multipliers[:base_damage_multiplier] *= 1.25
            end
        else
            # Parental Bond's second attack
            if user.effects[:ParentalBond] == 1
                multipliers[:base_damage_multiplier] *= 0.25
            end
            # Me First
            if user.effectActive?(:MeFirst)
                multipliers[:base_damage_multiplier] *= 1.5
            end
            # Helping Hand
            if user.effectActive?(:HelpingHand) && !self.is_a?(PokeBattle_SelfHit)
                multipliers[:base_damage_multiplier] *= 1.5
            end
            # Helping Hand
            if user.effectActive?(:Spotting) && !self.is_a?(PokeBattle_SelfHit)
                multipliers[:base_damage_multiplier] *= 1.5
            end
            # Shimmering Heat
            if target.effectActive?(:ShimmeringHeat)
                multipliers[:final_damage_multiplier] *= 0.67
            end
            # Echo
            if user.effectActive?(:Echo)
                multipliers[:final_damage_multiplier] *= 0.50
            end
            # Martial Discipline
            if user.effectActive?(:MartialDiscipline)
                multipliers[:final_damage_multiplier] *= 0.50
            end
            # Refuge
            if target.effectActive?(:RefugeDamageReduction)
                multipliers[:final_damage_multiplier] *= 0.7
            end
        end

        # Mass Attack
        if @battle.pbCheckGlobalAbility(:MASSATTACK)
            hpFraction = user.hp / user.totalhp.to_f
            multipliers[:final_damage_multiplier] *= hpFraction
        end

        # Multi-targeting attacks
        if numTargets > 1
            multipliers[:final_damage_multiplier] *= 0.75
            multipliers[:final_damage_multiplier] *= 1.5 if user.shouldAbilityApply?(:RESONANT,aiCheck)
        end

        multipliers[:final_damage_multiplier] *= 0.5 if !user.opposes?(target) && halfDamageToAllies?

        # Battler properites
        multipliers[:base_damage_multiplier] *= user.dmgMult
        multipliers[:base_damage_multiplier] *= [0,(1.0 - target.dmgResist.to_f)].max

        # Critical hits
        if (aiCheck && pbIsCritical?(user,target,true)) || (!aiCheck && target.damageState.critical)
            echoln("[CRITICAL CALC] #{user.pbThis}'s #{self.name} is predicted to critical hit against target #{target.pbThis(true)}") if aiCheck
            multipliers[:final_damage_multiplier] *= criticalHitMultiplier(user,target)
        end

        # Random variance (What used to be for that)
        if !self.is_a?(PokeBattle_SelfHit)
            multipliers[:final_damage_multiplier] *= 0.9
        end

        # Move-specific final damage modifiers
        multipliers[:final_damage_multiplier] = pbModifyDamage(multipliers[:final_damage_multiplier], user, target)
    end

    def flatDamageModifiers(finalCalculatedDamage,user,target,type,aiCheck = false)
        # Additive effects
        if user.shouldAbilityApply?(:PURERAGE,aiCheck) && type == :DRAGON
            finalCalculatedDamage += (user.level / 2).ceil
        end

        # Subtractive effects
        if target.shouldAbilityApply?(:DRAGONSBLOOD,aiCheck) && !@battle.moldBreaker
            finalCalculatedDamage -= target.level
            target.aiLearnsAbility(:DRAGONSBLOOD) unless aiCheck
        end

        if @battle.field.effectActive?(:WillfulRoom)
            finalCalculatedDamage -= 30
        end

        finalCalculatedDamage = 1 if finalCalculatedDamage < 1

        finalCalculatedDamage = 0 if user.hasActiveAbility?(:NOBLEBLADE) && target.effectActive?(:ChoseStatus)

        return finalCalculatedDamage
    end
end