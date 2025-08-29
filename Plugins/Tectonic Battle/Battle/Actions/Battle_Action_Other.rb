class PokeBattle_Battle
    #=============================================================================
    # Shifting a battler to another position in a battle larger than double
    #=============================================================================
    def pbCanShift?(idxBattler)
        return false if !@doubleShift && pbSideSize(0) <= 2 && pbSideSize(1) <= 2 # Double battle or smaller
        idxOther = -1
        case pbSideSize(idxBattler)
        when 1
            return false # Only one battler on that side
        when 2
            idxOther = (idxBattler + 2) % 4
        when 3
            return false if [2, 3].include?(idxBattler) # In middle spot already
            idxOther = idxBattler.even? ? 2 : 3
        end
        return false if pbGetOwnerIndexFromBattlerIndex(idxBattler) != pbGetOwnerIndexFromBattlerIndex(idxOther)
        return true
    end

    def pbRegisterShift(idxBattler)
        @choices[idxBattler][0] = :Shift
        @choices[idxBattler][1] = 0
        @choices[idxBattler][2] = nil
        return true
    end

    #=============================================================================
    # Mega evolving a battler
    #=============================================================================
    def pbMegaEvolve(idxBattler)
        battler = @battlers[idxBattler]
        return if !battler || !battler.pokemon
        return if !battler.hasMega? || battler.mega?
        # Break Illusion
        %i[ILLUSION INCOGNITO].each do |illusionAbility|
            if battler.hasActiveAbility?(illusionAbility)
                BattleHandlers.triggerTargetAbilityOnHit(illusionAbility, nil, battler, nil, self)
            end     
        end
        # Mega Evolve
        if !battler.boss
            trainerName = pbGetOwnerName(idxBattler)
            pbDisplay(_INTL("{1}'s fervent wish has reached {2}!", trainerName, battler.pbThis))
        else
            case battler.pokemon.megaMessage
            when 1 # Rayquaza
                pbDisplay(_INTL("{1}'s is inspired by the echo of an ancient wish!", battler.pbThis))
            else
                pbDisplay(_INTL("{1}'s reacts to an unknown power!", battler.pbThis))
            end
        end
        pbCommonAnimation("MegaEvolution", battler)
        battler.pokemon.makeMega
        battler.form = battler.pokemon.form
        battler.pbUpdate(true)
        @scene.pbChangePokemon(battler, battler.pokemon)
        @scene.pbRefreshOne(idxBattler)
        pbCommonAnimation("MegaEvolution2", battler)
        megaName = battler.pokemon.megaName
        megaName = _INTL("Mega {1}", battler.pokemon.speciesName) if !megaName || megaName == ""
        pbDisplay(_INTL("{1} has transformed into {2}!", battler.pbThis, megaName))
        side  = battler.idxOwnSide
        owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
        @megaEvolution[side][owner] = -2
        pbCalculatePriority(false, [idxBattler])
        # Trigger ability
        battler.pbEffectsOnSwitchIn
    end

    #=============================================================================
    # Primal Reverting a battler
    #=============================================================================
    def pbPrimalReversion(idxBattler)
        battler = @battlers[idxBattler]
        return if !battler || !battler.pokemon
        return if !battler.hasPrimal? || battler.primal?
        if battler.isSpecies?(:KYOGRE)
            pbCommonAnimation("PrimalKyogre", battler)
        elsif battler.isSpecies?(:GROUDON)
            pbCommonAnimation("PrimalGroudon", battler)
        end
        battler.pokemon.makePrimal
        battler.form = battler.pokemon.form
        battler.pbUpdate(true)
        @scene.pbChangePokemon(battler, battler.pokemon)
        @scene.pbRefreshOne(idxBattler)
        if battler.isSpecies?(:KYOGRE)
            pbCommonAnimation("PrimalReversionKyogre", battler)
        elsif battler.isSpecies?(:GROUDON)
            pbCommonAnimation("PrimalReversionGroudon", battler)
        elsif battler.isSpecies?(:RAYQUAZA)
            pbCommonAnimation("MegaEvolutionRayquaza", battler)
        end
        if battler.isSpecies?(:RAYQUAZA)
            pbDisplay(_INTL("{1} is inspired by the echo of an ancient wish!", battler.pbThis))
        else 
            pbDisplay(_INTL("{1}'s Primal Reversion!\nIt reverted to its primal form!", battler.pbThis))
        end 
        # Trigger ability
        battler.pbEffectsOnSwitchIn
    end
end
