AID_KIT_BASE_HEALING = 25
AID_KIT_BASE_CHARGES = 3
HEALING_UPGRADE_AMOUNT = 10
# Equal to the number of Kit Expansions in the game
MAX_AID_KIT_CHARGES = 8
# Equal the number of Medical Upgrades in the game
MAX_AID_KIT_UPGRADES = 8

def initializeAidKit()
	$PokemonGlobal.teamHealerUpgrades 		= 0
	$PokemonGlobal.teamHealerMaxUses 		= AID_KIT_BASE_CHARGES
	$PokemonGlobal.teamHealerCurrentUses 	= AID_KIT_BASE_CHARGES
end

def getAidKitMaxCharges
	return [$PokemonGlobal.teamHealerMaxUses,AID_KIT_BASE_CHARGES + MAX_AID_KIT_CHARGES].min
end

def refillAidKit(boostAmount = 0)
	refillCharges = getAidKitMaxCharges
	refillCharges += boostAmount
	if $PokemonBag.pbHasItem?(:AIDKIT)
		$PokemonGlobal.teamHealerCurrentUses = refillCharges
		pbMessage(_INTL("\\i[AIDKIT]Your Aid Kit was refreshed to {1} charges.",$PokemonGlobal.teamHealerCurrentUses))
	end
	resetEXPBonus
    checkForAidKitAchievement
end

def getAidKitHealingAmount
	return AID_KIT_BASE_HEALING + HEALING_UPGRADE_AMOUNT * [$PokemonGlobal.teamHealerUpgrades,MAX_AID_KIT_UPGRADES].min
end

def maxAidKit
	$PokemonGlobal.teamHealerUpgrades 		= MAX_AID_KIT_UPGRADES
	$PokemonGlobal.teamHealerMaxUses 		= AID_KIT_BASE_CHARGES + MAX_AID_KIT_CHARGES
	$PokemonGlobal.teamHealerCurrentUses 	= AID_KIT_BASE_CHARGES + MAX_AID_KIT_CHARGES
end

def useAidKit()
	alreadyHealthy = true
	$Trainer.party.each do |p|
		next if p.egg?
		alreadyHealthy = false if p.hp < p.totalhp
		alreadyHealthy = false if p.status != :NONE
		p.moves.each do |move|
			alreadyHealthy = false if move.pp != move.total_pp
		end
	end
	if $PokemonGlobal.teamHealerCurrentUses <= 0
		pbMessage(_INTL("You are out of charges."))
		return 0
	elsif alreadyHealthy
		pbMessage(_INTL("Your entire team is already fully healed!"))
		return 0
	else
		$PokemonGlobal.teamHealerCurrentUses -= 1
		healAmount = getAidKitHealingAmount
		playerTribalBonus.updateTribeCount
		healAmount = (healAmount * 1.25).ceil if playerTribalBonus.hasTribeBonus?(:CARETAKER)
		previousHealthValues = []
		previousStatusIndices = []
		$Trainer.party.each do |p|
			next if p.egg?
			previousHealthValues.push(p.hp)
			previousStatusIndices.push(getStatusIndexForPokemon(p))
			pbItemRestoreHP(p,healAmount)
			p.heal_status
			p.heal_PP
		end
		if $Options.aid_kit_animation == 1
			pbMessage(_INTL("Healing your entire team by {1}.",healAmount))
		else
			showPartyHealing($Trainer.party,previousHealthValues,previousStatusIndices)
		end
		refreshFollow(false)
		return 1
	end
end

ItemHandlers::UseFromBag.add(:AIDKIT,proc { |item|
	next useAidKit()
})

ItemHandlers::ConfirmUseInField.add(:AIDKIT,proc { |item|
  next true
})

ItemHandlers::UseInField.add(:AIDKIT,proc { |item|
	next useAidKit()
})

ItemHandlers::UseFromBag.add(:KITEXPANSION,proc { |item|
	if !$PokemonBag.pbHasItem?(:AIDKIT)
		pbMessage(_INTL("You don't have a Aid Kit to upgrade."))
		next 0
	end
	if $PokemonGlobal.teamHealerMaxUses >= AID_KIT_BASE_CHARGES + MAX_AID_KIT_CHARGES
		pbMessage(_INTL("Your Aid Kit already has the maximum number of charges."))
		next 0
	else
		charges = $PokemonGlobal.teamHealerMaxUses
		pbMessage(_INTL("Your Aid Kit has been increased to {1} charges.", charges + 1))
		$PokemonGlobal.teamHealerMaxUses	 	+= 1
		$PokemonGlobal.teamHealerCurrentUses 	+= 1

        checkForAidKitAchievement
	end
	next 3
})

ItemHandlers::UseFromBag.add(:MEDICALUPGRADE,proc { |item|
	if !$PokemonBag.pbHasItem?(:AIDKIT)
		pbMessage(_INTL("You don't have a Aid Kit to upgrade."))
		next 0
	end
	if $PokemonGlobal.teamHealerUpgrades >= MAX_AID_KIT_UPGRADES
		pbMessage(_INTL("Your Aid Kit already has the maximum healing amount."))
		next 0
	else
		pbMessage(_INTL("Your Aid Kit now heals an additional {1} HP per charge.", HEALING_UPGRADE_AMOUNT))
		$PokemonGlobal.teamHealerUpgrades	 	+= 1
        checkForAidKitAchievement
	end
	next 3
})

def getAidKitCharges()
	return $PokemonGlobal.teamHealerCurrentUses
end

def setAidKitCharges(num)
	$PokemonGlobal.teamHealerCurrentUses = num
end

def checkForAidKitAchievement
    return unless $PokemonGlobal.teamHealerMaxUses >= AID_KIT_BASE_CHARGES + MAX_AID_KIT_CHARGES
    return unless $PokemonGlobal.teamHealerUpgrades >= MAX_AID_KIT_UPGRADES
    unlockAchievement(:FULLY_UPGRADE_AID_KIT)
end