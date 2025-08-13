def pbBigAvatarBattle(*args)
    rule = "3v#{args.length}"
    setBattleRule(rule)
    victorious = pbAvatarBattleCore(*args)
    return victorious
end

def pbSmallAvatarBattle(*args)
    rule = "2v#{args.length}"
    setBattleRule(rule)
    victorious = pbAvatarBattleCore(*args)
    return victorious
end

def avatarBattleAutoTest(*args)
    loop do
        setBattleRule("autotesting")
        $game_variables[LEVEL_CAP_VAR] = 70
        pbSmallAvatarBattle(*args)
        $Trainer.heal_party
        break if debugControl
    end
end

def pbAvatarBattleCore(*args)
    outcomeVar = $PokemonTemp.battleRules["outcomeVar"] || 1
    canLose = $PokemonTemp.battleRules["canLose"] || false
    # Skip battle if the player has no able Pokémon, or if holding Ctrl in Debug mode
    if $Trainer.able_pokemon_count == 0 || debugControl
        pbMessage(_INTL("SKIPPING BATTLE...")) if $Trainer.pokemon_count > 0
        pbSet(outcomeVar, 1) # Treat it as a win
        $PokemonTemp.clearBattleRules
        $PokemonGlobal.nextBattleBGM       = nil
        $PokemonGlobal.nextBattleME        = nil
        $PokemonGlobal.nextBattleCaptureME = nil
        $PokemonGlobal.nextBattleBack      = nil
        pbMEStop
        return 1 # Treat it as a win
    end
    # Record information about party Pokémon to be used at the end of battle (e.g.
    # comparing levels for an evolution check)
    Events.onStartBattle.trigger(nil)
    # Generate wild Pokémon based on the species and level
    foeParty = []
    respawnFollower = false
    for arg in args
        next unless arg.is_a?(Array)
        species = arg[0]
        level = arg[1]
        version = arg[2] || 0
        avatarPokemon = generateAvatarPokemon(species, level, version)
        foeParty.push(avatarPokemon)
    end
    # Calculate who the trainers and their party are
    playerTrainers    = [$Trainer]
    playerParty       = $Trainer.party
    playerPartyStarts = [0]
    room_for_partner = (foeParty.length > 1)
    if !room_for_partner && $PokemonTemp.battleRules["size"] &&
       !%w[single 1v1 1v2 1v3].include?($PokemonTemp.battleRules["size"])
        room_for_partner = true
    end
    playerParty = loadPartnerTrainer(playerTrainers,playerParty,playerPartyStarts) if room_for_partner if room_for_partner
    # Create the battle scene (the visual side of it)
    scene = pbNewBattleScene
    # Create the battle class (the mechanics side of it)
    battle = PokeBattle_Battle.new(scene, playerParty, foeParty, playerTrainers, nil)
    battle.party1starts = playerPartyStarts
    battle.bossBattle = true
    # Set various other properties in the battle class
    pbPrepareBattle(battle)
    $PokemonTemp.clearBattleRules
    # Perform the battle itself
    decision = 0
    if battle.autoTesting
        decision = battle.pbStartBattle
    else
        pbBattleAnimation(pbGetAvatarBattleBGM(foeParty), (foeParty.length == 1) ? 0 : 2, foeParty) do
            pbSceneStandby do
                decision = battle.pbStartBattle
            end
            pbPokemonFollow(1) if decision != 1 && $game_switches[59] # In cave with Yezera
            pbAfterBattle(decision, canLose)
        end
    end
    Input.update
    # Save the result of the battle in a Game Variable (1 by default)
    #    0 - Undecided or aborted
    #    1 - Player won
    #    2 - Player lost
    #    3 - Player or wild Pokémon ran from battle, or player forfeited the match
    #    4 - Wild Pokémon was caught
    #    5 - Draw
    pbSet(outcomeVar, decision)

    victorious = (decision == 1)

    if victorious
        anyLegendariesDefeated = false
        for arg in args
            next unless arg.is_a?(Array)
            species = arg[0]
            next unless GameData::Species.get(species).isLegendary?
            anyLegendariesDefeated = true
            break
        end
        unlockAchievement(:DEFEAT_ANY_LEGENDARY_AVATAR) if anyLegendariesDefeated
    end

    return victorious
end

SUMMON_MIN_HEALTH_LEVEL = 10
SUMMON_MAX_HEALTH_LEVEL = 50

def generateAvatarPokemon(species, level, version = 0, summon = false)
    newPokemon = pbGenerateWildPokemon(species, level, true, true)
    newPokemon.boss = true
    newPokemon.bossVersion = version
    setAvatarProperties(newPokemon)

    # Add the form name to the end of their name
    # If the avatar's form was specified in its species id
    speciesForm = GameData::Species.get(species)
    newPokemon.name += " " + speciesForm.form_name if speciesForm.form != 0

    # Set the pokemon's starting health if its a low-level summon
    if summon
        if level >= SUMMON_MAX_HEALTH_LEVEL
            healthPercent = 1.0
        elsif level <= SUMMON_MIN_HEALTH_LEVEL
            healthPercent = 0.4
        else
            healthPercent = 0.4 + 0.6 * (level - SUMMON_MIN_HEALTH_LEVEL) / (SUMMON_MAX_HEALTH_LEVEL - SUMMON_MIN_HEALTH_LEVEL).to_f
            echoln("Summoning #{species} avatar at health fraction #{healthPercent}")
        end
        newPokemon.hp = (newPokemon.totalhp * healthPercent).ceil
    end

    return newPokemon
end

def setAvatarProperties(pkmn)
    avatar_data = GameData::Avatar.get_from_pokemon(pkmn)

    pkmn.owner = Pokemon::Owner.new_foreign
    pkmn.forced_form = avatar_data.form if avatar_data.form != 0

    setDefaultAvatarMoveset(pkmn)

    pkmn.ability = avatar_data.abilities[0]
    avatar_data.abilities.each_with_index do |ability, index|
        next if index == 0
        pkmn.addExtraAbility(ability)
    end
    pkmn.setItems(avatar_data.items)
    pkmn.hpMult = avatar_data.hp_mult
    pkmn.dmgMult = avatar_data.dmg_mult
    pkmn.dmgResist = avatar_data.dmg_resist
    pkmn.extraMovesPerTurn = avatar_data.num_turns - 1

    pkmn.calc_stats
end

def setDefaultAvatarMoveset(pkmn)
    avatar_data = GameData::Avatar.get_from_pokemon(pkmn)
    pkmn.forget_all_moves
    avatar_data.moves1.each do |move|
        pkmn.learn_move(move, true)
    end
end

def pbPlayCrySpecies(species, form = 0, volume = 90, pitch = nil)
    GameData::Species.play_cry_from_species(species, form, volume, pitch)
end

def pbPlayerPartyMaxLevel(countFainted = false)
    maxPlayerLevel = -100
    $Trainer.party.each do |pkmn|
        maxPlayerLevel = pkmn.level if pkmn.level > maxPlayerLevel && (!pkmn.fainted? || countFainted)
    end
    return maxPlayerLevel
end

def pbGetAvatarBattleBGM(_wildParty) # wildParty is an array of Pokémon objects
    return $PokemonGlobal.nextBattleBGM.clone if $PokemonGlobal.nextBattleBGM
    ret = nil

    legend = false
    _wildParty.each do |p|
        legend = true if p.species_data.isLegendary?
    end

    # Check global metadata
    music = legend ? GameData::Metadata.get.legendary_avatar_battle_BGM : GameData::Metadata.get.avatar_battle_BGM
    ret = pbStringToAudioFile(music) unless music&.blank?
    ret = pbStringToAudioFile("Battle wild") if ret.nil?
    return ret
end

def CBSASP(overwriteExisting = true)
    createBossSpritesAllSpeciesForms(overwriteExisting)
end

def createBossSpritesAllSpeciesForms(overwriteExisting = true)
    # Find all genders/forms of all species that have an avatar
    GameData::Avatar.each do |avatarData|
        createBossGraphics(avatarData, overwriteExisting: overwriteExisting)
    end
end

def createBossGraphics(avatarData, overworldMult = 1.5, battleMult = 1.5, overwriteExisting: true)
    avatarData = GameData::Avatar.get(avatarData) if avatarData.is_a?(Symbol)

    # Create the overworld sprite for the base form
    PBDebug.logonerr do
        bossOWFilePath = GameData::Avatar.ow_sprite_filename(avatarData.species, avatarData.version, avatarData.form)
        existingFile = pbResolveBitmap(bossOWFilePath)

        if overwriteExisting || existingFile.nil?
            echoln("Creating overworld sprite for Avatar #{avatarData.species}")
            speciesOverworldBitmap = GameData::Species.ow_sprite_bitmap(avatarData.species, avatarData.form)
            copiedOverworldBitmap = speciesOverworldBitmap.copy
            bossifiedOverworld = bossify(copiedOverworldBitmap.bitmap, overworldMult, opacity: BASE_OPACITY_OVERWORLD)
            bossifiedOverworld.to_file(bossOWFilePath)
        elsif SHOW_BOSSIFICATION_DEBUG
            echoln("Overworld sprite already exists for Avatar #{avatarData.species}")
        end
    end

    # Create all in-battle sprites
    for form in 0..99
        dataKey = form > 0 ? sprintf("%s_%d", avatarData.species.to_s, form).to_sym : avatarData.species
        break unless GameData::Species::DATA.key?(dataKey)

        echoln("Checking the boss graphics for Avatar #{avatarData.species} (form #{form})") if SHOW_BOSSIFICATION_DEBUG

        # Create the in battle sprites
        PBDebug.logonerr do
            baseSpeciesFrontFilePath = GameData::Species.front_sprite_filename(avatarData.species, form)
            baseSpeciesBackFilePath = GameData::Species.back_sprite_filename(avatarData.species, form)
            
            avatarData.getListOfPhaseTypes.each_with_index do |type, index|
                if type.is_a?(Array)
                    bossifyBattleSprites(avatarData, form, baseSpeciesFrontFilePath, baseSpeciesBackFilePath, type[0], battleMult, overwriteExisting: overwriteExisting)
                    bossifyBattleSprites(avatarData, form, baseSpeciesFrontFilePath, baseSpeciesBackFilePath, type, battleMult, overwriteExisting: overwriteExisting)
                else
                    bossifyBattleSprites(avatarData, form, baseSpeciesFrontFilePath, baseSpeciesBackFilePath, type, battleMult, overwriteExisting: overwriteExisting)  
                end
            end
        end
    end
end

SHOW_BOSSIFICATION_DEBUG = false

def bossifyBattleSprites(avatarData, form, baseSpeciesFrontFilePath, baseSpeciesBackFilePath, type, sizeMult, overwriteExisting: true)
    identifier = "Avatar #{avatarData.species} (form #{form})"
    identifier = "#{identifier} -- #{type.to_s}" if type

    # Front sprites
    bossFrontFilePath = GameData::Avatar.front_sprite_filename(avatarData.species, avatarData.version, form, type)

    if overwriteExisting || !pbResolveBitmap(bossFrontFilePath)
        echoln("Creating front sprite for #{identifier}")
        battlebitmap = AnimatedBitmap.new(baseSpeciesFrontFilePath)
        copiedBattleBitmap = battlebitmap.copy
        bossifiedBattle = bossify(copiedBattleBitmap.bitmap, sizeMult, type)
        bossifiedBattle.to_file(bossFrontFilePath)
    elsif SHOW_BOSSIFICATION_DEBUG
        echoln("Front sprite already exists for #{identifier}")
    end

    # Back sprites
    bossBackFilePath = GameData::Avatar.back_sprite_filename(avatarData.species, avatarData.version, form, type)

    if overwriteExisting || !pbResolveBitmap(bossBackFilePath)
        echoln("Creating back sprite for #{identifier}")
        battlebitmap = AnimatedBitmap.new(baseSpeciesBackFilePath)
        copiedBattleBitmap = battlebitmap.copy
        bossifiedBattle = bossify(copiedBattleBitmap.bitmap, sizeMult, type)
        bossifiedBattle.to_file(bossBackFilePath)
    elsif SHOW_BOSSIFICATION_DEBUG
        echoln("Back sprite already exists for #{identifier}")
    end  
end

BASE_RGB_ADD = [0, 0, 0]
BASE_AVATAR_HUE = 300.0 # Fuchsia
BASE_AVATAR_HUE_WEIGHTING = 0.0
BASE_AVATAR_SATURATION_SHIFT = 0
BASE_AVATAR_LIGHTNESS_SHIFT = 0

BASE_TYPE_HUE_WEIGHTING = 0.7
TYPE_SATURATION_WEIGHTING = 0.8
TYPE_LUMINOSITY_WEIGHTING = 0.3

BASE_OPACITY_OVERWORLD = 120
BASE_OPACITY_BATTLE = 140

def bossify(bitmap, scaleFactor = 1.5, type = nil, opacity: BASE_OPACITY_BATTLE)
    # Figure out the color info that should be used for the given type, if any
    applyType = false
    if type
        typeHueWeight = BASE_TYPE_HUE_WEIGHTING
        applyType = true if typeHueWeight > 0 
        if type.is_a?(Array)
            type1Color = GameData::Type.get(type[0]).color
            type1H, type1S, type1L = rgb_to_hsl(type1Color.red, type1Color.green, type1Color.blue)

            type2Color = GameData::Type.get(type[1]).color
            type2H, type2S, type2L = rgb_to_hsl(type2Color.red, type2Color.green, type2Color.blue)
        else
            typeColor = GameData::Type.get(type).color
            typeH, typeS, typeL = rgb_to_hsl(typeColor.red, typeColor.green, typeColor.blue)
        end
    end

    # Create the new bitmap
    copiedBitmap = Bitmap.new(bitmap.width * scaleFactor, bitmap.height * scaleFactor)
    width = copiedBitmap.width
    height = copiedBitmap.height
    for x in 0..width
        for y in 0..height
            color = bitmap.get_pixel(x / scaleFactor, y / scaleFactor)

            h, s, l = rgb_to_hsl(color.red, color.green, color.blue)

            # Base HSL shifts
            h = averageOfHues(h, BASE_AVATAR_HUE, BASE_AVATAR_HUE_WEIGHTING)
            s -= BASE_AVATAR_SATURATION_SHIFT
            l += BASE_AVATAR_LIGHTNESS_SHIFT

            # HSL shifts from typing coloration
            if applyType
                if type2Color
                    type1WeightAtPixel = 1.5 - (x + width / 2.0) / width.to_f
                    type1WeightAtPixel.clamp(0, 1)
                    type2WeightatPixel = 1 - type1WeightAtPixel

                    # Hue
                    h = averageOfHues(h, type1H, type1WeightAtPixel * 0.9)
                    h = averageOfHues(h, type2H, type2WeightatPixel * 1.1)

                    # Saturation
                    s = s * (1.0 - TYPE_SATURATION_WEIGHTING)
                    s += type1S * TYPE_SATURATION_WEIGHTING * type1WeightAtPixel * 0.75
                    s += type2S * TYPE_SATURATION_WEIGHTING * type2WeightatPixel * 0.75

                    # Luminance
                    l = l * (1.0 - TYPE_LUMINOSITY_WEIGHTING)
                    l += type1L * TYPE_LUMINOSITY_WEIGHTING * type1WeightAtPixel * 0.75
                    l += type2L * TYPE_LUMINOSITY_WEIGHTING * type2WeightatPixel * 0.75
                else
                    h = averageOfHues(h, typeH, typeHueWeight)
                    s = s * (1.0 - TYPE_SATURATION_WEIGHTING) + typeS * TYPE_SATURATION_WEIGHTING 
                    l = l * (1.0 - TYPE_LUMINOSITY_WEIGHTING) + typeL * TYPE_LUMINOSITY_WEIGHTING 
                end  
            end
            
            # Clamp values
            h += 360 if h < 0
            s = s.clamp(0, 100)
            l = l.clamp(0, 100)

            color.red, color.green, color.blue = hsl_to_rgb(h, s, l)

            # Add a base level of a certain color
            color.red += BASE_RGB_ADD[0]
            color.green += BASE_RGB_ADD[1]
            color.blue += BASE_RGB_ADD[2]

            # Add the transparency
            color.alpha = [color.alpha, opacity].min

            # Round and clamp
            color.red	= color.red.round.clamp(0, 255)
            color.green = color.green.round.clamp(0, 255)
            color.blue 	= color.blue.round.clamp(0, 255)

            copiedBitmap.set_pixel(x, y, color)
        end
    end
    return copiedBitmap
end

def averageOfHues(valueA, valueB, weightingTowardsB = 0.5)
    radA = (valueA - 180) / 180.0 * Math::PI
    radB = (valueB - 180) / 180.0 * Math::PI

    ax = Math.cos(radA)
    ay = Math.sin(radA)
    bx = Math.cos(radB)
    by = Math.sin(radB)

    cx = (ax * (1 - weightingTowardsB) + bx * weightingTowardsB)
    cy = (ay * (1 - weightingTowardsB) + by * weightingTowardsB)

    radC = Math.atan2(cy, cx)

    degC = radC / Math::PI * 180.0 + 180.0

    return degC
end

def rgb_to_hsl(r, g, b)
    r /= 255.0
    g /= 255.0
    b /= 255.0
    max = [r, g, b].max
    min = [r, g, b].min
    h = (max + min) / 2.0
    s = (max + min) / 2.0
    l = (max + min) / 2.0

    if max == min
        h = 0
        s = 0 # achromatic
    else
        d = max - min
        s = l >= 0.5 ? d / (2.0 - max - min) : d / (max + min)
        case max
        when r
            h = (g - b) / d + (g < b ? 6.0 : 0)
        when g
            h = (b - r) / d + 2.0
        when b
            h = (r - g) / d + 4.0
        end
        h /= 6.0
    end
    return [(h * 360), (s * 100), (l * 100)]
end

def hsl_to_rgb(h, s, l)
    h /= 360.0
    s /= 100.0
    l /= 100.0

    r = 0.0
    g = 0.0
    b = 0.0

    if s == 0.0
        r = l.to_f
        g = l.to_f
        b = l.to_f # achromatic
    else
        q = l < 0.5 ? l * (1 + s) : l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1 / 3.0)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3.0)
    end

    return [(r * 255), (g * 255), (b * 255)]
end

def hue_to_rgb(p, q, t)
    t += 1 if t < 0
    t -= 1                                  if t > 1
    return (p + (q - p) * 6 * t)            if t < 1 / 6.0
    return q                                if t < 1 / 2.0
    return (p + (q - p) * (2 / 3.0 - t) * 6) if t < 2 / 3.0
    return p
end

class PokeBattle_Battle
    def remakeDataBoxes
        # Remake all the battle boxes
        scene.deleteDataBoxes
        scene.createDataBoxes
        eachBattler do |b|
            databox = scene.sprites["dataBox_#{b.index}"]
            databox.visible = true
        end
    end

    def remakeBattleSpritesOnSide(sideIndex)
        eachBattler do |b|
            next unless b.index % 2 == sideIndex
            battleSprite = scene.sprites["pokemon_#{b.index}"]
            battleSprite.dispose
            battleSprite.initialize(@scene.viewport, @sideSizes[sideIndex], b.index, @scene.animations)
            scene.pbChangePokemon(b.index, b.pokemon)
            battleSprite.visible = true
        end
    end

    def roomToSummon?(sideIndex)
        sideIndex = sideIndex % 2
        if sideIndex == 0
            return getLowestSummonableIndex(sideIndex) <= 4
        else
            return getLowestSummonableIndex(sideIndex) <= 5
        end
    end

    def getLowestSummonableIndex(sideIndex)
        sideIndex = sideIndex % 2
        indexOnSide = @sideSizes[sideIndex]
        maxNewBattlerIndex = indexOnSide * 2 + sideIndex
        battlerIndexNew = maxNewBattlerIndex
        0.upto(maxNewBattlerIndex) do |idxBattler|
            next unless idxBattler % 2 == sideIndex # Only check same side
            battlerSlotAtIndex = @battlers[idxBattler]
            next unless battlerSlotAtIndex.nil? || battlerSlotAtIndex.pokemon.nil? || battlerSlotAtIndex.fainted?
            battlerIndexNew = idxBattler
            break
        end
        return battlerIndexNew
    end

    def addBattlerSlot(newPokemon,sideIndex,partyIndex)
        sideIndex = sideIndex % 2
        
        # Put the battler into the battle
        battlerIndexNew = getLowestSummonableIndex(sideIndex)
        if @battlers[battlerIndexNew].nil?
            pbCreateBattler(battlerIndexNew, newPokemon, partyIndex)
            sideSizes[sideIndex] += 1
        else
            @battlers[battlerIndexNew].pbInitialize(newPokemon, partyIndex)
        end
        newBattler = @battlers[battlerIndexNew]
        @scene.lastMove[battlerIndexNew] = 0
        @scene.lastCmd[battlerIndexNew] = 0

        # Create any missing battler slots
        0.upto(battlerIndexNew) do |idxBattler|
            next unless @battlers[idxBattler].nil?
            pbCreateBattler(idxBattler)
            scene.pbCreatePokemonSprite(idxBattler)
            scene.createMoveOutcomePredictor(@battlers[idxBattler],idxBattler) if idxBattler.odd?
        end

        remakeDataBoxes

        # Create a dummy sprite for the avatar
        scene.pbCreatePokemonSprite(battlerIndexNew)
        scene.createMoveOutcomePredictor(newBattler,battlerIndexNew) if battlerIndexNew.odd?

        # Recreate all the battle sprites on that side of the field
        remakeBattleSpritesOnSide(sideIndex)

        # Set the new pokemon's tone to be appropriate for entering the field
        pkmnSprite = @scene.sprites["pokemon_#{battlerIndexNew}"]
        pkmnSprite.tone = Tone.new(-80, -80, -80)

        # Remake the targeting menu
        @scene.sprites["targetWindow"] = TargetMenuDisplay.new(@scene.viewport, 200, @sideSizes)
        @scene.sprites["targetWindow"].visible = false

        # Send it out into the battle
        @scene.animateIntroNewAvatar(battlerIndexNew)
        pbOnActiveOne(newBattler)
        pbCalculatePriority
    end

    def summonAvatarBattler(species, level, version = 0, sideIndex = 1)
        unless roomToSummon?(sideIndex)
            echoln("Cannot create new avatar battler on side #{sideIndex} since the side is already full!")
            return false
        end

        # Create the new pokemon
        newPokemon = generateAvatarPokemon(species, level, version, true)

        # Put the pokemon into the party
        partyIndex = pbParty(sideIndex).length
        pbParty(sideIndex)[partyIndex] = newPokemon

        addBattlerSlot(newPokemon,sideIndex,partyIndex)

        return true
    end
end

class PokeBattle_Battler
    attr_accessor :choicesTaken
    attr_accessor :lastMoveChosen

    def assignMoveset(moves)
        @moves = []
        @pokemon.moves = []
        moves.each do |m|
            pokeMove = Pokemon::Move.new(m)
            moveObject = PokeBattle_Move.from_pokemon_move(@battle, pokeMove)
            @moves.push(moveObject)
            @pokemon.moves.push(pokeMove)
        end
        @lastMoveChosen = nil
    end
end