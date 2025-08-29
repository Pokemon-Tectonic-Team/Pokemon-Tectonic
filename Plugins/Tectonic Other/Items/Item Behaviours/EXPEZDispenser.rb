EXP_PER_EXTRA_SMALL = 250
EXP_JAR_BASE_EFFICIENCY = 0.8

class PokemonGlobalMetadata
	attr_accessor :expJARUpgraded
end

ItemHandlers::UseFromBag.add(:EXPEZDISPENSER,proc { |item|
	next useEXPEZ
})


ItemHandlers::ConfirmUseInField.add(:EXPEZDISPENSER,proc { |item|
  next true
})

ItemHandlers::UseInField.add(:EXPEZDISPENSER,proc { |item|
	next useEXPEZ
})

def useEXPEZ()
	$PokemonGlobal.expJAR = 0 if $PokemonGlobal.expJAR.nil?
	$PokemonGlobal.expJARUpgraded = false if $PokemonGlobal.expJARUpgraded.nil?
	pbMessage(_INTL("\\i[EXPEZDISPENSER]You have {1} EXP stored in the EXP-EZ Dispenser.",separate_comma($PokemonGlobal.expJAR)))

	xsCandyTotal, sCandyTotal, mCandyTotal, lCandyTotal = calculateCandySplitForEXP($PokemonGlobal.expJAR,$PokemonGlobal.expJARUpgraded)

	# Prompt the player to make the candies
	if xsCandyTotal > 0 || sCandyTotal > 0 || mCandyTotal > 0 || lCandyTotal > 0
		if !$PokemonGlobal.expJARUpgraded
			if pbConfirmMessage(_INTL("\\i[EXPEZDISPENSER]You can make {1} Medium, {2} Small and {3} Extra-Small candies. Would you like to?",
					separate_comma(mCandyTotal), separate_comma(sCandyTotal), separate_comma(xsCandyTotal)))
				pbReceiveItem(:EXPCANDYM,mCandyTotal) if mCandyTotal > 0
				pbReceiveItem(:EXPCANDYS,sCandyTotal) if sCandyTotal > 0
				pbReceiveItem(:EXPCANDYXS,xsCandyTotal) if xsCandyTotal > 0
				$PokemonGlobal.expJAR = $PokemonGlobal.expJAR % EXP_PER_EXTRA_SMALL
			end
		else
			if pbConfirmMessage(_INTL("\\i[EXPEZDISPENSER]You can make {1} Large, {2} Medium and {3} Small candies. Would you like to?",
					separate_comma(lCandyTotal), separate_comma(mCandyTotal), separate_comma(sCandyTotal)))
				pbReceiveItem(:EXPCANDYL,lCandyTotal) if lCandyTotal > 0
				pbReceiveItem(:EXPCANDYM,mCandyTotal) if mCandyTotal > 0
				pbReceiveItem(:EXPCANDYS,sCandyTotal) if sCandyTotal > 0
				$PokemonGlobal.expJAR = $PokemonGlobal.expJAR % (EXP_PER_EXTRA_SMALL * 4)
			end
		end
	else
		pbMessage(_INTL("\\i[EXPEZDISPENSER]That's not enough to make any candies."))
		return 0
	end
	return 1
end


def calculateCandySplitForEXP(expAmount, biggerSized = false)
	# Calculate how many of each candy size could be given
	if !biggerSized
		xsCandyTotal = expAmount / EXP_PER_EXTRA_SMALL
		sCandyTotal = xsCandyTotal / 4
		xsCandyTotal = xsCandyTotal % 4
	else
		xsCandyTotal = 0
		sCandyTotal = expAmount / (EXP_PER_EXTRA_SMALL * 4)
	end
	mCandyTotal = sCandyTotal / 4
	sCandyTotal = sCandyTotal % 4
	if biggerSized
		lCandyTotal = mCandyTotal / 4
		mCandyTotal = mCandyTotal % 4
	else
		lCandyTotal = 0
	end
	return xsCandyTotal,sCandyTotal,mCandyTotal,lCandyTotal
end

def separate_comma(number)
	reverse_digits = number.to_s.chars.reverse
	reverse_digits.each_slice(3).map(&:join).join(",").reverse
end