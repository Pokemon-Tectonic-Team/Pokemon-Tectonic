######################################################
# Mart vendors
######################################################
BASIC_MART_STOCK = %i[POKEBALL ABILITYCAPSULE REPEL]

VIP_CARD_EXTRA_STOCK = %i[REPEATBALL ROYALBALL LUXURYBALL SITRUSBERRY EXPCANDYXS]

def vipCardActive?
    return false unless $PokemonBag
    return pbHasItem?(:VIPCARD)
end

def martStock
    stock = BASIC_MART_STOCK.clone
    stock += VIP_CARD_EXTRA_STOCK.clone if vipCardActive?
    return stock
end

def basicPokeMart
    setPrice(:SITRUSBERRY,2000)
    pbPokemonMart(martStock)
end

def rangerMart
    setPrice(:SITRUSBERRY,2000)
    if vipCardActive?
        message = _INTL("You a big shot, huh? Well, we're here to supply you.")
    else
        message = _INTL("Get your supplies here!")
    end
    pbPokemonMart(martStock,message)
end

######################################################
# Pokemon vendors
######################################################

def purchaseStarters(type,price=0)
	return unless %i[GRASS FIRE WATER].include?(type)
	typeName = GameData::Type.get(type).name
	
	token = (type.to_s + "TOKEN").to_sym
	tokenName = GameData::Item.get(token).name
	
	pbMessage(_INTL("Hello, and welcome to the Starters Store!",typeName))
	pbMessage(_INTL("I'm the {1}-type starters salesperson!",typeName))
	if price > 0
		pbMessage(_INTL("You can buy a {1}-type starter Pokemon from me if you have ${2} and a {3}.",typeName,price,tokenName))
	else
		pbMessage(_INTL("You can buy a {1}-type starter Pokemon from me if you have a {2}.",typeName,tokenName))
	end
	if $Trainer.money < price
		pbMessage(_INTL("I'm sorry, but it seems as though you don't have that much money."))
		return
	end
	if !$PlayerBag.pbHasItem?(token)
		pbMessage(_INTL("I'm sorry, but it seems as though you don't have a {1}.",tokenName))
		return
	end
	pbMessage(_INTL("Which {1}-type starter Pokemon would you like to look at?",typeName))
	
	starterArray = []
	case type
	when :GRASS
		starterArray = ["None","Bulbasaur","Chikorita","Treecko","Turtwig","Snivy","Chespin","Rowlet","Grookey"]
	when :FIRE
		starterArray = ["None","Charmander","Cyndaquil","Torchic","Chimchar","Tepig","Fennekin","Litten","Scorbunny"]
	when :WATER
		starterArray = ["None","Squirtle","Totodile","Mudkip","Piplup","Oshawott","Froakie","Popplio","Sobble"]
	else
		return
	end
	
	while true
		result = pbShowCommands(nil,starterArray,0)

		if result == 0
			pbMessage(_INTL("Understood, please come back if there's a {1}-type starter Pokemon you'd like to purchase!",typeName))
			break
		else
			starterChosenName = starterArray[result]
			starterSpecies = starterChosenName.upcase.to_sym

			choicesArray = [_INTL("View MasterDex"), _INTL("Buy Pokemon"), _INTL("Cancel")]
			secondResult = pbShowCommands(nil,choicesArray,3)
			case secondResult
			when 1
				pbAddPokemon(starterSpecies,10)
				if price > 0
					pbMessage(_INTL("\\PN handed over ${1} and a {2} in exchange.",price,tokenName))
				else
					pbMessage(_INTL("\\PN handed over a {1} in exchange.",tokenName))
				end
				$Trainer.money -= price
				$PlayerBag.pbDeleteItem(token)
				pbMessage(_INTL("Thank you for shopping here at the Starters Store!"))
				break
			when 0
				openSingleDexScreen(starterSpecies)
			end
			next
		end
	end
end

def isMixFossil?(item_symbol)
	%i[FOSSILIZEDBIRD FOSSILIZEDDRAKE FOSSILIZEDFISH FOSSILIZEDDINO].include?(item_symbol)
end

def reviveFossil(fossil)
	if isMixFossil?(fossil)
		pbMessage(_INTL("My apologies, I don't know what to do with this type of fossil."))
		return
	end

	fossilsToSpecies = {
		:HELIXFOSSIL => :OMANYTE,
		:DOMEFOSSIL => :KABUTO,
		:OLDAMBER => :AERODACTYL,
		:ROOTFOSSIL => :LILEEP,
		:CLAWFOSSIL => :ANORITH,
		:SKULLFOSSIL => :CRANIDOS,
		:ARMORFOSSIL => :SHIELDON,
		:COVERFOSSIL => :TIRTOUGA,
		:PLUMEFOSSIL => :ARCHEN,
		:JAWFOSSIL => :TYRUNT,
		:SAILFOSSIL => :AMAURA
	}

	species = fossilsToSpecies[fossil] || nil
	
	if species.nil?
		pbMessage(_INTL("Error! Could not determine how to revive the given fossil."))
		return
	end
	item_data = GameData::Item.get(fossil)
	
	pbMessage(_INTL("\\PN hands over the {1} and $3000.",item_data.name))
	
	pbMessage(_INTL("The procedure has started, now just to wait..."))
	
	blackFadeOutIn(30) {
		$Trainer.money = $Trainer.money - 3000
		$PokemonBag.pbDeleteItem(fossil)
	}
	
	pbMessage(_INTL("It's done! Here is your newly revived Pokemon!"))
	
	pbAddPokemon(species,15)
end

def reviveMixFossils(fossil1,fossil2)
	if fossil1 == fossil2
		pbMessage(_INTL("The fossils can't be the same!"))
		return
	end

	fossilsToSpecies = {
		%i[FOSSILIZEDBIRD FOSSILIZEDDRAKE] => :DRACOZOLT,
		%i[FOSSILIZEDBIRD FOSSILIZEDDINO] => :ARCTOZOLT,
		%i[FOSSILIZEDFISH FOSSILIZEDDRAKE] => :DRACOVISH,
		%i[FOSSILIZEDFISH FOSSILIZEDDINO] => :ARCTOVISH
	}

	chosenSpecies = nil
	fossilsToSpecies.each do |key,value|
		if key.include?(fossil1) && key.include?(fossil2)
			chosenSpecies = value
			break
		end
	end

	if chosenSpecies.nil?
		pbMessage(_INTL("Error! Could not determine how to revive the given fossils."))
		return
	end

	pbMessage(_INTL("The procedure has started, now just to wait..."))
	
	blackFadeOutIn(30) {
		$PokemonBag.pbDeleteItem(fossil1)
		$PokemonBag.pbDeleteItem(fossil2)
	}
	
	pbMessage(_INTL("It's done! Here is your newly revived Pokemon!"))
	
	pbAddPokemon(chosenSpecies,15)
end

def pbChooseMixFossilHead(var = 0)
	ret = nil
	pbFadeOutIn {
	  scene = PokemonBag_Scene.new
	  screen = PokemonBagScreen.new(scene,$PokemonBag)
	  ret = screen.pbChooseItemScreen(Proc.new { |item| %i[FOSSILIZEDBIRD FOSSILIZEDFISH].include?(item) })
	}
	$game_variables[var] = ret || :NONE if var > 0
	return ret
end

def pbChooseMixFossilBody(var = 0)
	ret = nil
	pbFadeOutIn {
	  scene = PokemonBag_Scene.new
	  screen = PokemonBagScreen.new(scene,$PokemonBag)
	  ret = screen.pbChooseItemScreen(Proc.new { |item| %i[FOSSILIZEDDRAKE FOSSILIZEDDINO].include?(item) })
	}
	$game_variables[var] = ret || :NONE if var > 0
	return ret
end

def styleFurfrou
	pbChoosePokemon(1,3,
		proc { |poke|
			!poke.egg? && poke.species == :FURFROU
		}
	)
	return false if pbGet(1) < 0
	pkmn = $Trainer.party[pbGet(1)]
	possibleForms, possibleFormNames = getFormSelectionChoices(:FURFROU,pkmn.form)
	pbMessage(_INTL("What style would you like me to give it?"))
	choice = pbShowCommands(nil,possibleFormNames,possibleFormNames.length+1)
	if choice < possibleForms.length
		pbMessage(_INTL("{1} swapped to {2}!", pkmn.name, possibleFormNames[choice]))
		
		pkmn.form = possibleForms[choice].form
		pkmn.changeHappiness("groom")
		refreshFollow(false)
		return true
	end
	return false
end

def styleVivillon
	pbChoosePokemon(1,3,
		proc { |poke|
			!poke.egg? && poke.species == :VIVILLON
		}
	)
	return false if pbGet(1) < 0
	pkmn = $Trainer.party[pbGet(1)]
	possibleForms, possibleFormNames = getFormSelectionChoices(:VIVILLON,pkmn.form)
	pbMessage(_INTL("What pattern would you like me to give it?"))
	choice = pbShowCommands(nil,possibleFormNames,possibleFormNames.length+1)
	if choice < possibleForms.length
		pbMessage(_INTL("{1} swapped to {2}!", pkmn.name, possibleFormNames[choice]))
		
		pkmn.form = possibleForms[choice].form
		#pkmn.changeHappiness("groom")
		refreshFollow(false)
		return true
	end
	return false
end

def createHisuian
	unless pbHasItem?(:ORIGINORE)
		setSpeaker(HISUIAN_WITCH)
		pbMessage(_INTL("I do not spy any Origin Ore among your possessions."))
		return
	end

	actualSpecies = [:HGROWLITHE,:HVOLTORB,:HQWILFISH,:HSNEASEL,:HZORUA,:BASCULIN_2]
	speciesArray = []
	actualSpecies.each do |speciesID|
		speciesArray.push(GameData::Species.get(speciesID).full_name)
	end
	actualSpecies.unshift(nil)
	speciesArray.unshift(_INTL("None"))
	
	while true
		result = pbShowCommands(nil,speciesArray,0)

		if result == 0
			setSpeaker(HISUIAN_WITCH)
			pbMessage(_INTL("Ah, I was looking forward to flexing my skills today."))
			break
		else
			chosenSpecies = actualSpecies[result]

			choicesArray = [_INTL("View MasterDex"), _INTL("Buy Pokemon"), _INTL("Cancel")]
			secondResult = pbShowCommands(nil,choicesArray,3)
			case secondResult
			when 1
				item_data = GameData::Item.get(:ORIGINORE)
				removeSpeaker
				pbMessage(_INTL("\\PN hands over the {1}.",item_data.name))
				setSpeaker(HISUIAN_WITCH)
				pbMessage(_INTL("Now just to work my magicks..."))
				blackFadeOutIn(30) {
					$PokemonBag.pbDeleteItem(:ORIGINORE)
				}
				pbMessage(_INTL("Poof! And so the impossible has been made possible!"))
				pbAddPokemon(chosenSpecies,10)
				setSpeaker(HISUIAN_WITCH)
				pbMessage(_INTL("My hopes go with you. Be respectful of this relic which you now posess."))
				break
			when 0
				openSingleDexScreen(chosenSpecies)
			end
			next
		end
	end
end

def shinifyPokemonVendor
	unless pbHasItem?(:GLEAMPOWDER)
		pbMessage(_INTL("Don't try to trick me with some knock-off, you don't have any Gleam Powder!"))
		return
	end

	pbChoosePokemon(1,3,
		proc { |poke|
			!poke.egg? && !poke.shiny?
		}
	)
	if pbGet(1) < 0
		pbMessage(_INTL("No suitable canvases?"))
		return
	end

	pkmn = $Trainer.party[pbGet(1)]

	unless payMoney(30_000, false)
		pbMessage(_INTL("I'm surprised, you look like you'd have more money, but you can't afford me."))
		return
	end

	gleamPowderRealName = GameData::Item.get(:GLEAMPOWDER).name
	pbMessage(_INTL("\\PN hands over the {1}, $30,000, and {2}.", gleamPowderRealName, pkmn.name))

	pbMessage(_INTL("And so my work begins!"))
	blackFadeOutIn(30) {
		$PokemonBag.pbDeleteItem(:GLEAMPOWDER)
		pkmn.shiny = true
	}
	pbMessage(_INTL("Now, bask in the beautiful glow of your shiny {1}!", pkmn.speciesName))
	pbMessage(_INTL("No need to thank me, its beauty is reward enough."))
	pbMessage(_INTL("The money isn't bad either..."))

	return false
end

def cloneMinorLegend
	unless pbHasItem?(:ORIGINORE)
		setSpeaker(HISUIAN_WITCH)
		pbMessage(_INTL("I do not spy any Origin Ore among your possessions."))
		return	
	end

	possibleSpecies = [:PHIONE,:TYPENULL,:COSMOG,:MELTAN,:KUBFU]

	pbChooseBoxPokemon(1,3,
		proc { |poke|
			possibleSpecies.include?(GameData::Species.get(poke.species).get_line_start.id)
		})

	unless boxPokemonChosen?
		setSpeaker(HISUIAN_WITCH)
		pbMessage(_INTL("Ah, no suitable Pokemon exists within your collection?"))
		pbMessage(_INTL("Return to me if you encounter any in your travels."))
		return
	end
	
	item_data = GameData::Item.get(:ORIGINORE)
	removeSpeaker
	pbMessage(_INTL("\\PN hands over the {1}.", item_data.name))
	setSpeaker(HISUIAN_WITCH)
	pbMessage(_INTL("Now just to work my magicks..."))
	blackFadeOutIn(30) {
		$PokemonBag.pbDeleteItem(:ORIGINORE)
	}
	pbMessage(_INTL("Poof! And so the impossible has been made possible!"))
	chosenSpecies = GameData::Species.get(pbGet(1).species).get_line_start.id
	pbAddPokemon(chosenSpecies,10)
	setSpeaker(HISUIAN_WITCH)
	pbMessage(_INTL("My hopes go with you. Live the legend!"))
end

######################################################
# Useful item vendors
######################################################

CAN_SELL_IN_VENDORS = true

def weatherTMSell()
	weatherTMStock = %i[
		TMSUNSHINE
		TMRAINSTORM
		TMSANDSTORM
		TMHAIL
		TMMOONGLOW
		TMECLIPSE
	]
	pbPokemonMart(
		weatherTMStock,
		_INTL("Care to buy some?"),
		!CAN_SELL_IN_VENDORS
	)
end

def spikesTMSell()
	spikeTMStock = %i[
		TMSPIKES
		TMFLAMESPIKES
		TMFROSTSPIKES
		TMPOISONSPIKES
	]
	pbPokemonMart(
		spikeTMStock,
		_INTL("You see their value, don't you?"),
		!CAN_SELL_IN_VENDORS
	)
end

def fossilSell()
	fossilStock = %i[
		HELIXFOSSIL
		DOMEFOSSIL
		OLDAMBER
		ROOTFOSSIL
		CLAWFOSSIL
		SKULLFOSSIL
		ARMORFOSSIL
		COVERFOSSIL
		PLUMEFOSSIL
		JAWFOSSIL
		SAILFOSSIL
		FOSSILIZEDBIRD
		FOSSILIZEDFISH
		FOSSILIZEDDRAKE
		FOSSILIZEDDINO
	]
	pbPokemonMart(
		fossilStock,
		_INTL("Do you like anything you see?"),
		!CAN_SELL_IN_VENDORS
	)
end

def eastEndExclusives
	exclusiveItemsStock = %i[
		DYNAMITESTICK
		ORIGINORE
		GRASSTOKEN WATERTOKEN FIRETOKEN
		DIAMONDTIARA
		RUSTEDSHIELD RUSTEDSWORD
	]

	setPrice(:RUSTEDSWORD,20_000)
	setPrice(:RUSTEDSHIELD,20_000)
	setPrice(:DYNAMITESTICK,5_000)
	
	pbPokemonMart(
		exclusiveItemsStock,
		_INTL("Ohoh! I'm honored that you would pay my store a visit, champion."),
		!CAN_SELL_IN_VENDORS
	)
end

def tmShop
	# Megapunch, Hypervoice
	# Inferno Charge, Flame Thrower
	# Liquidation, Bubble Blast

	# Leaf Blade, Thriving Force
	# Electroslash, Thunderbolt
	# Crystal Crush, Ice Beam

	# Brick Break, Aura Sphere
	# Poison Jab, Miasma
	# Trample, Earth Power

	# Strafe, Cold Front
	# Prediction Strike, Psychic
	# X-Scissor, Bug Buzz

	# Adamantine Press, Power Gem
	# Wailing Blow, Shadow Ball
	# Rend, Dragon Pulse

	# Crunch, Dark Allure
	# Bullet Train, Flash Cannon
	# Play Rough, Moon Blast

	tmsStock = %i[
		TMMEGAPUNCH TMHYPERVOICE
		TMINFERNOIMPACT TMFLAMETHROWER
		TMLIQUIDATION TMBUBBLEBLASTER

		TMLEAFBLADE TMENERGYBALL
		TMELECTROSLASH TMTHUNDERBOLT
		TMGLACIALRAM TMICEBEAM

		TMBRICKBREAK TMAURASPHERE
		TMPOISONJAB TMMIASMA
		TMTRAMPLE TMEARTHPOWER

		TMSTRAFE TMCOLDFRONT
		TMSEERSTRIKE TMPSYCHIC
		TMXSCISSOR TMBUGBUZZ

		TMADAMANTINEPRESS TMPOWERGEM
		TMWAILINGBLOW TMSHADOWBALL
		TMREND TMDRAGONPULSE

		TMCRUNCH TMDARKALLURE
		TMBULLETTRAIN TMFLASHCANNON
		TMPLAYROUGH TMMOONBLAST
	]

	pbPokemonMart(
		tmsStock,
		_INTL("One-Stop Tech Shop, for all your electronic need."),
		!CAN_SELL_IN_VENDORS
	)
end

def hackedTMShop
	tmsStock = %i[
		TMFRENZYPLANT
		TMBLASTBURN
		TMHYDROCANNON
		TMROCKWRECKER
		TMMETEORASSAULT
		TMRAILCANNON
		TMEXPLOSION
		TMMEMENTO
		TMRAPIDSPIN
		TMFINALGAMBIT
		TMAIMTRUE
		TMSTEALTHROCK
	]

	pbPokemonMart(
		tmsStock,
		_INTL("Hurry and buy some."),
		!CAN_SELL_IN_VENDORS
	)
end

def switchOutTMShop
	tmsStock = %i[
		TMVOLTSWITCH
		TMUTURN
		TMFLIPTURN
		TMPARTINGSHOT
	]

	pbPokemonMart(
		tmsStock,
		_INTL("I'm sure you'll appreciate one of these."),
		!CAN_SELL_IN_VENDORS
	)
end

def naturesGallery
	stock = %i[
		HEATROCK DAMPROCK SMOOTHROCK ICYROCK MIRROREDROCK PINPOINTROCK
		LIGHTCLAY
		FLOATSTONE
		BIGROOT
		LUCKYEGG
		GALARICAWREATH
		ALOLANWREATH
	]

	pbPokemonMart(
		stock,
		_INTL("Nature's Gallery, your gateway to nature's beauty."),
		!CAN_SELL_IN_VENDORS
	)
end

def heldItemShop
	stock = %i[
		POWERLOCK ENERGYLOCK
		UTILITYUMBRELLA 
		BLACKSLUDGE
		GRIPCLAW BINDINGBAND
		REDCARD EJECTBUTTON EJECTPACK
		AIRBALLOON EXPERTBELT
		EVIOLITE
		METRONOME
		MUSCLEBAND WISEGLASSES
		SCOPELENS WIDELENS
		LAGGINGTAIL SEVENLEAGUEBOOTS
		HEAVYDUTYBOOTS
		FOCUSSASH
		SHEDSHELL
		STICKYBARB
		IRONBALL
		ADRENALINEORB
		WEAKNESSPOLICY
		REINFORCINGROD
		LOADEDDICE
		PROXYFIST COVERTCLOAK
		COURAGEBADGE CLEARAMULET
	]	

	pbPokemonMart(
		stock,
		_INTL("Welcome to Emma's Empolorium! What're you looking for today?"),
		!CAN_SELL_IN_VENDORS
	)
end

def advancedHeldItemsShop
	advancedHeldItemStock = %i[
		CHOICEBAND CHOICESPECS CHOICESCARF
		LUMBERAXE
		LEFTOVERS WATERBALLOON SHELLBELL
		ASSAULTVEST STRIKEVEST
		LIFEORB
		THROATSPRAY WHETSTONE
		PROTEINSHAKE STRESSBALL
		PINWHEEL INSOLES
		ROCKYHELMET HIVISJACKET
	]

	pbPokemonMart(
		advancedHeldItemStock,
		_INTL("I've got the lion's share of powerful items. Buy now!"),
		!CAN_SELL_IN_VENDORS
	)
end

def diegosWares
	castleStock = %i[
		KNIGHTHELMET NINJASCARF
	]

	pbPokemonMart(
		castleStock,
		_INTL("Welcome to Diego's Wares! Please, come look through our goods."),
		!CAN_SELL_IN_VENDORS
	)
end

def gemVendor
	gemStock = %i[
		FIREGEM WATERGEM ELECTRICGEM GRASSGEM ICEGEM FIGHTINGGEM POISONGEM GROUNDGEM FLYINGGEM
		PSYCHICGEM BUGGEM ROCKGEM GHOSTGEM DRAGONGEM DARKGEM STEELGEM NORMALGEM FAIRYGEM
	]

	pbPokemonMart(
		gemStock,
		_INTL("Yo, I'm Adam, the gem guy. Gonna buy some gems, or what?"),
		!CAN_SELL_IN_VENDORS
	)
end

def earlyBallVendor
	basicBallStock = %i[
		SLICEBALL
		LEECHBALL
		DISABLEBALL
		POTIONBALL
		HEALBALL
	]
	pbPokemonMart(
		basicBallStock,
		_INTL("Poké Balls of all sorts stocked here. Take a look!"),
		!CAN_SELL_IN_VENDORS
	)
end

def basicBallVendor
	basicBallStock = %i[
		GREATBALL
		REPEATBALL
		NESTBALL
		TIMERBALL
		QUICKBALL
		FRIENDBALL
	]
	pbPokemonMart(
		basicBallStock,
		_INTL("Welcome to the Poké Ball Depot! How may I serve you?"),
		!CAN_SELL_IN_VENDORS
	)
end

def weirdBallsVendor
	weirdBallStock = %i[
		ULTRABALL
		DREAMBALL
		FASTBALL
		HEAVYBALL
		LUXURYBALL
		ROYALBALL
		BEASTBALL
	]
	pbPokemonMart(
		weirdBallStock,
		_INTL("Custom Pokéballs, made to order! You won't find these in a mart!"),
		!CAN_SELL_IN_VENDORS
	)
end

def evoStoneVendor
	stock = %i[
		FIRESTONE
		THUNDERSTONE
		WATERSTONE
		LEAFSTONE
		ICESTONE
		DAWNSTONE
		DUSKSTONE
		SHINYSTONE
		SUNSTONE
		MOONSTONE
	]

	message = _INTL("How can we help to empower your Pokemon?")

	pbPokemonMart(
		stock,
		message,
		!CAN_SELL_IN_VENDORS
	)
end

def berryVendor
	setPrice(:CADOBERRY,1000)
	setPrice(:SITRUSBERRY,1000)
	setPrice(:LUMBERRY,1000)
	setPrice(:LEPPABERRY,500)
	
	setPrice(:RAWSTBERRY,500)
	setPrice(:ASPEARBERRY,500)
	setPrice(:PECHABERRY,500)
	setPrice(:PERSIMBERRY,500)
	setPrice(:CHERIBERRY,500)
	setPrice(:BELUEBERRY,500)
	setPrice(:CHESTOBERRY,500)
	setPrice(:SPELONBERRY,500)

	berryStock = %i[
		CADOBERRY SITRUSBERRY
		LUMBERRY
		LEPPABERRY
		RAWSTBERRY ASPEARBERRY
		PECHABERRY
		PERSIMBERRY
		CHERIBERRY BELUEBERRY
		CHESTOBERRY
		SPELONBERRY
	]

	pbPokemonMart(
		berryStock,
		_INTL("Care to buy some of our extra berry harvest?"),
		!CAN_SELL_IN_VENDORS
	)
end

def weirdBerryVendor
	setPrice(:LIECHIBERRY,1000)
	setPrice(:GANLONBERRY,1000)
	setPrice(:SALACBERRY,1000)
	setPrice(:PETAYABERRY,1000)
	setPrice(:APICOTBERRY,1000)
	setPrice(:LANSATBERRY,1000)
	setPrice(:STARFBERRY,1000)
	setPrice(:MICLEBERRY,1000)

	setPrice(:MICLEBERRY,1000)
	setPrice(:CUSTAPBERRY,1000)
	setPrice(:JABOCABERRY,1000)
	setPrice(:ROWAPBERRY,1000)
	setPrice(:KEEBERRY,1000)
	setPrice(:MARANGABERRY,1000)

	berryStock = %i[
		LIECHIBERRY
		GANLONBERRY
		SALACBERRY
		PETAYABERRY
		APICOTBERRY
		LANSATBERRY
		STARFBERRY
		MICLEBERRY
		CUSTAPBERRY
		JABOCABERRY
		ROWAPBERRY
		KEEBERRY
		MARANGABERRY
	]

	pbPokemonMart(
		berryStock,
		_INTL("Some of these are illegal to import. Don't get me caught."),
		!CAN_SELL_IN_VENDORS
	)
end

def expCandyVendor
	expCandyStock = %i[
		EXPCANDYXS
		EXPCANDYS
		EXPCANDYM
		EXPCANDYL
		EXPCANDYXL
	]
	pbPokemonMart(
		expCandyStock,
		_INTL("Welcome to Sweetrock Candy Outlet! How may I serve you?"),
		!CAN_SELL_IN_VENDORS
	)
end

def herbVendor
	herbStock = %i[
		AGILITYHERB STRENGTHHERB INTELLECTHERB
		WHITEHERB BLACKHERB
		POWERHERB ENERGYHERB
		SKILLHERB LUCKHERB
		MIRRORHERB PARADOXHERB
		MENTALHERB
	]
	pbPokemonMart(
		herbStock,
		_INTL("Name's Herbert. Care for any herbs?"),
		!CAN_SELL_IN_VENDORS
	)
end

def typeBoostingVendor
	herbStock = %i[
		SILKSCARF
		BLACKBELT
		SHARPBEAK
		POISONBARB
		SOFTSAND
		HARDSTONE
		SILVERPOWDER
		SPELLTAG
		METALCOAT
		CHARCOAL
		MYSTICWATER
		MIRACLESEED
		MAGNET
		TWISTEDSPOON
		NEVERMELTICE
		DRAGONFANG
		BLACKGLASSES
		FAIRYFEATHER
	]
	pbPokemonMart(
		herbStock,
		_INTL("What're ya buyin'?"),
		!CAN_SELL_IN_VENDORS
	)
end

def statusTMVendor()
	spikeTMStock = %i[
		TMPOISONGAS
		TMIGNITE
		TMCHILL
		TMNUMB
		TMWATERLOG
		TMLEECHSEED
		TMCONFUSERAY
	]
	pbPokemonMart(
		spikeTMStock,
		_INTL("Any interest in buying?"),
		!CAN_SELL_IN_VENDORS
	)
end

######################################################
# Minor food vendors
######################################################

def malasadaVendor()
	pbPokemonMart(
		%i[BIGMALASADA BERRYJUICE],
		_INTL("Take a look, it's all delicious!"),
		true
	)
end

def pubVendor
	pubStock = %i[
		EEVEETICKET
		SWEETHEART
	]
	pbPokemonMart(pubStock,_INTL("What can I get you?"),true)
end

def farmVendor
	pubStock = %i[
		SWEETAPPLE
		TARTAPPLE
		SYRUPYAPPLE
		MOOMOOMILK
	]
	setPrice(:MOOMOOMILK,800)
	pbPokemonMart(pubStock,_INTL("Farm food, fresh for feastin'."),true)
end

def arenaVendor()
	pbPokemonMart(
		[:VANILLATULUMBA],
		_INTL("Grab a Tulumba, a Makyan specialty!"),
		true
	)
end

def vendingMachine
	return unless playerFacingNorth?
	pbPokemonMart(
		%i[FRESHWATER SODAPOP LEMONADE MOOMOOMILK],
		_INTL("It's a vending machine."),
		true,
		false,
	)
end