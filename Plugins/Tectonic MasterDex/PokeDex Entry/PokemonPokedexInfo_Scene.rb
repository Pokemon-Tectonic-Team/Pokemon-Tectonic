class PokemonPokedexInfo_Scene
    include MoveInfoDisplay

    SIGNATURE_COLOR = Color.new(211, 175, 44)
    SIGNATURE_COLOR_LIGHTER = Color.new(228, 207, 128)

    LEVEL_MOVES_PAGE_ID = 6
    OTHER_MOVES_PAGE_ID = 7
    FORMS_PAGE_ID = 10

    def pageTitles
        return [_INTL("INFO"), _INTL("ABILITIES"), _INTL("STATS"), _INTL("DEF. MATCHUPS"),
                _INTL("ATK. MATCHUPS"), _INTL("LEVEL UP MOVES"), _INTL("OTHER MOVES"),
                _INTL("EVOLUTIONS"), _INTL("AREA"), _INTL("FORMS"), _INTL("ANALYSIS")]
    end

    def pbStartScene(dexlist, index, region, battle = false, linksEnabled = false)
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @dexlist = dexlist
        @index   = index
        @region  = region
        @page = battle ? 2 : 1
        @linksEnabled = linksEnabled
        @evolutionIndex = -1
        @typebitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Pokedex/icon_types")))
        @types_emphasized_bitmap = AnimatedBitmap.new(addLanguageSuffix(("Graphics/Pictures/Pokedex/icon_types_emphasized")))
        move_path = "Graphics/Pictures/move_info_display_backwards_l"
        move_path += "_dark" if darkMode?
        @moveInfoDisplayBitmap = AnimatedBitmap.new(_INTL(move_path))
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["infosprite"] = PokemonSprite.new(@viewport)
        @sprites["infosprite"].setOffset(PictureOrigin::Center)
        @sprites["infosprite"].x = 104
        @sprites["infosprite"].y = 136
        @mapdata = pbLoadTownMapData
        map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
        mappos = map_metadata ? map_metadata.town_map_position : nil
        if @region < 0                                 # Use player's current region
            @region = mappos ? mappos[0] : 0 # Region 0 default
        end
        @sprites["areamap"] = IconSprite.new(0, 0, @viewport)
        @sprites["areamap"].setBitmap("Graphics/Pictures/Town Map/Region Maps/#{@mapdata[@region][1]}")
        @sprites["areamap"].x += (Graphics.width - @sprites["areamap"].bitmap.width) / 2
        @sprites["areamap"].y += (Graphics.height + 32 - @sprites["areamap"].bitmap.height) / 2
        for hidden in Settings.getRegionMapExtras
            next unless hidden[0] == @region && hidden[1] > 0 && $game_switches[hidden[1]]
            pbDrawImagePositions(@sprites["areamap"].bitmap, [
                                     ["Graphics/Pictures/Town Map/Map Extras/#{hidden[4]}",
                                      hidden[2] * PokemonRegionMap_Scene::SQUAREWIDTH,
                                      hidden[3] * PokemonRegionMap_Scene::SQUAREHEIGHT,],
                                 ])
        end
        @sprites["areahighlight"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["areaoverlay"] = IconSprite.new(0, 0, @viewport)
        @sprites["areaoverlay"].setBitmap("Graphics/Pictures/Pokedex/overlay_area")
        @sprites["formfront"] = PokemonSprite.new(@viewport)
        @sprites["formfront"].setOffset(PictureOrigin::Center)
        @sprites["formfront"].x = 130
        @sprites["formfront"].y = 158
        @sprites["formback"] = PokemonSprite.new(@viewport)
        @sprites["formback"].setOffset(PictureOrigin::Bottom)
        @sprites["formback"].x = 382 # y is set below as it depends on metrics
        @sprites["formicon"] = PokemonSpeciesIconSprite.new(nil, @viewport)
        @sprites["formicon"].setOffset(PictureOrigin::Center)
        @sprites["formicon"].x = 82
        @sprites["formicon"].y = 328
        @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow", 8, 28, 40, 2, @viewport)
        @sprites["uparrow"].x = 242
        @sprites["uparrow"].y = 268
        @sprites["uparrow"].play
        @sprites["uparrow"].visible = false
        @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow", 8, 28, 40, 2, @viewport)
        @sprites["downarrow"].x = 242
        @sprites["downarrow"].y = 348
        @sprites["downarrow"].play
        @sprites["downarrow"].visible = false
        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x = 32
        @sprites["leftarrow"].y = 52
        @sprites["leftarrow"].play
        @sprites["leftarrow"].visible = false
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x = 184
        @sprites["rightarrow"].y = 52
        @sprites["rightarrow"].play
        @sprites["rightarrow"].visible = false
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["selectionarrow"] = IconSprite.new(0, 0, @viewport)
        @sprites["selectionarrow"].setBitmap("Graphics/Pictures/selarrow")
        @sprites["selectionarrow"].visible = false
        @sprites["selectionarrow"].x = 6
        # Create the move extra info display
        @moveInfoDisplay = SpriteWrapper.new(@viewport)
        @moveInfoDisplay.bitmap = @moveInfoDisplayBitmap.bitmap
        @sprites["moveInfoDisplay"] = @moveInfoDisplay
        # Create overlay for selected move's extra info (shows move's BP, description)
        @extraInfoOverlay = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetNarrowFont(@extraInfoOverlay.bitmap)
        @sprites["extraInfoOverlay"] = @extraInfoOverlay

        @scroll = -1
        @horizontalScroll = 0
        $PokemonGlobal.dex_tutor_list_sort_mode = 0 if $PokemonGlobal.dex_tutor_list_sort_mode.nil?

        @tutorMovesSorting = nil
        calculate_other_moves_sorting_proc

        @showShinyForms = $PokemonGlobal.dex_forms_shows_shinies || false

        @speciesCalcedFor = nil
        @formCalcedFor = nil
        recalculate_other_moves_lists if @page == OTHER_MOVES_PAGE_ID

        @title = "Undefined"
        pbSetSystemFont(@sprites["overlay"].bitmap)
        pbUpdateDummyPokemon
        @available = pbGetAvailableForms
        drawPage(@page)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @typebitmap.dispose
        @viewport.dispose
        @types_emphasized_bitmap.dispose
        @moveInfoDisplayBitmap.dispose
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbUpdateDummyPokemon
        @species = @dexlist[@index][:species]
        @gender, @form = $Trainer.pokedex.last_form_seen(@species)
        species_data = GameData::Species.get_species_form(@species, @form)
        metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
        if species_data.form != 0 && species_data.form_name.blank?
            @title = species_data.form_name
        else
            @title = species_data.name
        end
        @sprites["infosprite"].setSpeciesBitmap(@species, @gender, @form)
        @sprites["formfront"].setSpeciesBitmap(@species, @gender, @form, @showShinyForms) if @sprites["formfront"]
        if @sprites["formback"]
            @sprites["formback"].setSpeciesBitmap(@species, @gender, @form, @showShinyForms, false, true)
            @sprites["formback"].y = 256
            @sprites["formback"].y += metrics_data.back_sprite[1] * 2
        end
        @sprites["formicon"].pbSetParams(@species, @gender, @form, @showShinyForms) if @sprites["formicon"]
    end

    def pbGetAvailableForms
        ret = []
        @multiple_forms = false
        # Find all genders/forms of @species that have been seen
        GameData::Species.each do |sp|
            next if sp.species != @species
            next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
            next if sp.pokedex_form != sp.form
            @multiple_forms = true if sp.form > 0
            case sp.gender_ratio
            when :AlwaysMale, :AlwaysFemale, :Genderless
                real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
                next if !$Trainer.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
                real_gender = 2 if sp.gender_ratio == :Genderless
                ret.push([sp.form_name, real_gender, sp.form])
            else # Both male and female
                for real_gender in 0...2
                    next if !$Trainer.pokedex.seen_form?(@species, real_gender,
sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
                    ret.push([sp.form_name, real_gender, sp.form])
                    break if sp.form_name && !sp.form_name.empty? # Only show 1 entry for each non-0 form
                end
            end
        end
        # Sort all entries
        ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
        # Create form names for entries if they don't already exist
        ret.each do |entry|
            if !entry[0] || entry[0].empty? # Necessarily applies only to form 0
                case entry[1]
                when 0 then entry[0] = _INTL("Male")
                when 1 then entry[0] = _INTL("Female")
                else
                    entry[0] = @multiple_forms ? _INTL("One Form") : _INTL("Genderless")
                end
            end
            entry[1] = 0 if entry[1] == 2 # Genderless entries are treated as male
        end
        return ret
    end

    def drawPage(page)
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        # Make certain sprites visible or invisible
        @sprites["infosprite"].visible = (@page == 1)
        @sprites["areamap"].visible       = false if @sprites["areamap"] # (@page==7) if @sprites["areamap"]
        @sprites["areahighlight"].visible = false if @sprites["areahighlight"] # (@page==7) if @sprites["areahighlight"]
        @sprites["areaoverlay"].visible   = false if @sprites["areaoverlay"] # (@page==7) if @sprites["areaoverlay"]
        @sprites["formfront"].visible     = (@page == FORMS_PAGE_ID) if @sprites["formfront"]
        @sprites["formback"].visible      = (@page == FORMS_PAGE_ID) if @sprites["formback"]
        @sprites["formicon"].visible      = (@page == FORMS_PAGE_ID) if @sprites["formicon"]
        @sprites["moveInfoDisplay"].visible = @page == LEVEL_MOVES_PAGE_ID || @page == OTHER_MOVES_PAGE_ID  if @sprites["moveInfoDisplay"]
        @sprites["extraInfoOverlay"].visible = @page == LEVEL_MOVES_PAGE_ID || @page == OTHER_MOVES_PAGE_ID if @sprites["extraInfoOverlay"]
        @sprites["extraInfoOverlay"].bitmap.clear if @sprites["extraInfoOverlay"]
        @sprites["selectionarrow"].visible = false
        # Draw page title
        overlay = @sprites["overlay"].bitmap
        base = Color.new(219, 240, 240)
        shadow = Color.new(88, 88, 80)
        # remove tribes page if not using tribes plugin
        pageTitle = pageTitles[page - 1]
        drawFormattedTextEx(overlay, 50, 2, Graphics.width, "<outln2>#{pageTitle}</outln2>", base, shadow, 18)
        xPos = 240
        # shift x position so that double digit page number does not overlap with the right facing arrow
        xPos -= 14 if @page >= 10
        drawFormattedTextEx(overlay, xPos, 2, Graphics.width, "<outln2>[#{page}/#{pageTitles.length - 1}]</outln2>", base, shadow, 18)
        # Draw species name on top right	
        speciesName = GameData::Species.get(@species).name
		speciesName = "#{speciesName} #{@form + 1}" if @multiple_forms
        # shift x position so that species name does not overlap with the right facing arrow
        xPos += 14 if @page >= 10
        drawFormattedTextEx(overlay, xPos + 104, 2, Graphics.width, "<outln2>#{speciesName}</outln2>", base, shadow, 18)
        # Draw page-specific information
        case page
        when 1 then drawPageInfo
        when 2 then drawPageAbilities
        when 3 then drawPageStats
        when 4 then drawPageMatchups
        when 5 then drawPageMatchups2
        when 6 then drawPageLevelUpMoves
        when 7 then drawPageOtherMoves
        when 8 then drawPageEvolution
        when 9 then drawPageArea
        when 10 then drawPageForms
        when 11 then drawPageDEBUG
        end
    end

    def drawPageInfo
        bg_path = "Graphics/Pictures/Pokedex/bg_info"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        imagepos = []
        imagepos.push([addLanguageSuffix(("Graphics/Pictures/Pokedex/overlay_info")), 0, 0]) if @brief
        species_data = GameData::Species.get_species_form(@species, @form)
        # Write various bits of text
        indexText = "???"
        if @dexlist[@index][:index] > 0
            indexNumber = @dexlist[@index][:index]
            indexNumber -= 1 if @dexlist[@index][:shift]
            indexText = format("%03d", indexNumber)
        end
        textpos = [
            [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
             246, 36, 0, Color.new(248, 248, 248), Color.new(0, 0, 0),],
        ]
        if $Trainer.owned?(@species)
            # Show the owned icon
            imagepos.push(["Graphics/Pictures/Pokedex/icon_own", 212, 44])
        end
        # Write the category
        textpos.push([_INTL("{1} Pokémon", species_data.category), 246, 68, 0, base, shadow])
        # Draw the Pokédex entry text
        drawTextEx(overlay, 40, 244, Graphics.width - (40 * 2), 4, # overlay, x, y, width, num lines
                 species_data.pokedex_entry, base, shadow)
        # Draw the type icon(s)
        type1 = species_data.type1
        type2 = species_data.type2
        type1_number = GameData::Type.get(type1).id_number
        type2_number = GameData::Type.get(type2).id_number
        type1rect = Rect.new(0, type1_number * 32, 96, 32)
        type2rect = Rect.new(0, type2_number * 32, 96, 32)
        overlay.blt(232, 120, @typebitmap.bitmap, type1rect)
        overlay.blt(332, 120, @typebitmap.bitmap, type2rect) if type1 != type2
        # Write the tribes
        if species_data.tribes.length == 0
            tribesDescription = _INTL("None")
        else
            tribes = []
            species_data.tribes.each do |tribe|
                tribes.push(getTribeName(tribe))
            end
            tribesDescription = tribes.join(", ")
        end
        drawTextEx(overlay, 266, 166, 224, 2, tribesDescription, base, shadow)
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw all images
        pbDrawImagePositions(overlay, imagepos)
    end

    def drawPageAbilities
        bg_path = "Graphics/Pictures/Pokedex/bg_abilities"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor

        mutabilityLabelsX = Graphics.width/2 - 60

        for i in @available
            next unless i[2] == @form
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            abilities = fSpecies.abilities
            # ability 1
            abilityTextX = 30
            abilityIDLabelX = 380
            ability1Y = 52
            drawTextEx(overlay, abilityIDLabelX, ability1Y, 450, 1, _INTL("Ability 1"), base, shadow)
            if abilities[0]
                ability1 = GameData::Ability.get(abilities[0])
                abilityNameColor = base
                abilityNameShadow = shadow
                abilityNameText = ability1.name
                if ability1.is_signature?
                    abilityNameText = "<outln2>" + abilityNameText + "</outln2>"
                    abilityNameColor = SIGNATURE_COLOR_LIGHTER
                    abilityNameShadow = darkMode? ? shadow : base
                end
                drawFormattedTextEx(overlay, abilityTextX, ability1Y, 450, abilityNameText, abilityNameColor,
              abilityNameShadow)

                ability1Description = addBattleKeywordHighlighting(ability1.description)
                drawFormattedTextEx(overlay, abilityTextX, ability1Y + 34, 450, ability1Description, base, shadow)
                
                # add mutability labels
                if ability1.is_immutable_ability?
                    drawFormattedTextEx(overlay, mutabilityLabelsX, ability1Y + 134, 450, "Immutable", base, shadow)
                elsif ability1.is_uncopyable_ability?
                    drawFormattedTextEx(overlay, mutabilityLabelsX, ability1Y + 134, 450, "Uncopyable", base, shadow)
                end
            else
                drawTextEx(overlay, abilityTextX, 128, 450, 1, _INTL("None"), base, shadow)
            end
            # ability 2
            ability2Y = 219
            drawTextEx(overlay, abilityIDLabelX, ability2Y, 450, 1, _INTL("Ability 2"), base, shadow)
            if abilities[1]
                ability2 = GameData::Ability.get(abilities[1])
                abilityNameColor = base
                abilityNameShadow = shadow
                abilityNameText = ability2.name
                if ability2.is_signature?
                    abilityNameText = "<outln2>" + abilityNameText + "</outln2>"
                    abilityNameColor = SIGNATURE_COLOR_LIGHTER
                    abilityNameShadow = darkMode? ? shadow : base
                end
                drawFormattedTextEx(overlay, abilityTextX, ability2Y, 450, abilityNameText, abilityNameColor,
              abilityNameShadow)

                ability2Description = addBattleKeywordHighlighting(ability2.description)
                drawFormattedTextEx(overlay, abilityTextX, ability2Y + 34, 450, ability2Description, base, shadow)
                
                # add mutability labels
                if ability2.is_immutable_ability?
                    drawFormattedTextEx(overlay, mutabilityLabelsX, ability2Y + 134, 450, "Immutable", base, shadow)
                elsif ability2.is_uncopyable_ability?
                    drawFormattedTextEx(overlay, mutabilityLabelsX, ability2Y + 134, 450, "Uncopyable", base, shadow)
                end
            else
                drawTextEx(overlay, abilityTextX, ability2Y, 450, 1, _INTL("None"), base, shadow)
            end
        end
    end

    def genderRateToString(gender)
        case gender
        when :AlwaysMale            then    return _INTL("Male")
        when :FemaleOneEighth       then    return _INTL("7/8 Male")
        when :Female25Percent       then    return _INTL("3/4 Male")
        when :Female50Percent       then    return _INTL("50/50")
        when :Female75Percent       then    return _INTL("3/4 Fem.")
        when :FemaleSevenEighths    then    return _INTL("7/8 Fem.")
        when :AlwaysFemale          then    return _INTL("Female")
        when :Genderless            then    return _INTL("None")
        end
        return "No data"
    end

    def growthRateToString(growthRate)
        case growthRate
        when :Medium        then    return _INTL("Medium")
        when :Erratic       then    return _INTL("Erratic")
        when :Fluctuating   then    return _INTL("Flux")
        when :Parabolic     then    return _INTL("Med. Slow")
        when :Fast          then    return _INTL("Fast")
        when :Slow          then    return _INTL("Slow")
        end
    end

    def drawPageStats
        bg_path = "Graphics/Pictures/Pokedex/bg_stats"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base   = MessageConfig.pbDefaultTextMainColor
        faded  = MessageConfig.pbDefaultFadedTextColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        baseStatNames = [_INTL("HP"), _INTL("Attack"), _INTL("Defense"),  _INTL("PEHP"), _INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("SEHP"), _INTL("Speed")]
        otherStatNames = [_INTL("Height"), _INTL("Weight"), _INTL("Gender Rate"), _INTL("Catch Dif."), _INTL("Exp. Grant")]

        # Everything else

		# Only give me 1 element in the case where the 2 forms are only gender.
        if @available.length >= 2 && @available[0][0] == "Male" && @available[1][0] == "Female"
            available = [@available[0]]
        else
            available = @available
        end

        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            yBase = 62

            # Base stats
            baseStatHash = fSpecies.base_stats
            baseStats = []
            total = 0

            baseStatHash.each_with_index do |stat, index|
                next unless stat
                statValue = stat[1]
                total += statValue
                baseStats.push(statValue)
            end

            baseStats.insert(3, fSpecies.physical_ehp)
            baseStats.insert(6, fSpecies.special_ehp)

            baseStats.each_with_index do |statValue, index|
                color = base
                color = faded if [3, 6].include?(index)

                # Draw stat line
                statNameX = 30
                statNameX += 24 if [3, 6].include?(index)
                drawTextEx(overlay, statNameX, yBase + 32 * index, 450, 1, baseStatNames[index], color, shadow)
                drawTextEx(overlay, 136, yBase + 32 * index, 450, 1, statValue.to_s, color, shadow)
            end
            drawTextEx(overlay, 30, yBase + 32 * 8 + 16, 450, 1, _INTL("Total"), base, shadow)
            drawTextEx(overlay, 136, yBase + 32 * 8 + 16, 450, 1, total.to_s, base, shadow)

            # Other stats
            otherStats = []

            height = fSpecies.height
            weight = fSpecies.weight
            if System.user_language[3..4] == "US" # If the user is in the United States
                inches = (height / 0.254).round
                pounds = (weight / 0.45359).round
                otherStats.push(_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12))
                otherStats.push(_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0))
            else
                otherStats.push(_ISPRINTF("{1:.1f} m", height / 10.0))
                otherStats.push(_ISPRINTF("{1:.1f} kg", weight / 10.0))
            end

            genderRate = fSpecies.gender_ratio
            genderRateString = genderRateToString(genderRate)
            otherStats.push(genderRateString)

            otherStats.push(catchDifficultyFromRareness(fSpecies.catch_rate))

            otherStats.push(fSpecies.base_exp)

            otherStats.each_with_index do |stat, index|
                next unless stat
                # Draw stat line
                drawTextEx(overlay, 230, yBase + 32 * index, 450, 1, otherStatNames[index], base, shadow)
                drawTextEx(overlay, 378, yBase + 32 * index, 450, 1, stat.to_s, base, shadow)
            end
            
            # Calculate wild item rarities
            itemsAndRarities = fSpecies.wildHeldItemsWithRarities
            
            unless itemsAndRarities.empty?
                itemsString = ""
                itemsAndRarities.each_with_index do |(item, chance), index|
                    name = GameData::Item.get(item).name
                    itemsString += _INTL("{1}: {2}%\n",name, chance)
                    # itemsString += ", " if index < itemsAndRarities.keys.length - 1
                end
            else
                itemsString = _INTL("None")
            end
            wildItemsY = yBase + 142 + 32
            drawTextEx(overlay, 230, wildItemsY, 250, 1, _INTL("Wild Items"), base, shadow)
            drawTextEx(overlay, 230, wildItemsY + 36, 250, 3, itemsString, base, shadow)
        end
    end

    def drawPageMatchups
        bg_path = "Graphics/Pictures/Pokedex/bg_matchups"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        xLeft = 36
        yBase = 60
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            # type1 = GameData::Type.get(fSpecies.type1)
            # type2 = GameData::Type.get(fSpecies.type2)

            immuneTypes = []
            barelyEffectiveTypes = []
            resistentTypes = []
            weakTypes = []
            hyperWeakTypes = []

            GameData::Type.each do |t|
                next if t.pseudo_type

                effect = Effectiveness.calculate(t.id, [fSpecies.type1, fSpecies.type2])

                if Effectiveness.ineffective?(effect)
                    immuneTypes.push(t)
                elsif Effectiveness.barely_effective?(effect)
                    barelyEffectiveTypes.push(t)
                elsif Effectiveness.not_very_effective?(effect)
                    resistentTypes.push(t)
                elsif Effectiveness.hyper_effective?(effect)
                    hyperWeakTypes.push(t)
                elsif Effectiveness.super_effective?(effect)
                    weakTypes.push(t)
                end
            end
            weakTypes = [].concat(hyperWeakTypes, weakTypes)
            resistentTypes = [].concat(barelyEffectiveTypes, resistentTypes)

            # Draw the types the pokemon is weak to
            drawTextEx(overlay, xLeft, yBase, 450, 1, _INTL("Weak:"), base, shadow)
            if weakTypes.length == 0
                drawTextEx(overlay, xLeft, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                weakTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    bitmapUsed = hyperWeakTypes.include?(t) ? @types_emphasized_bitmap.bitmap : @typebitmap.bitmap
                    overlay.blt(xLeft, yBase + 30 + 36 * index, bitmapUsed, typerect)
                end
            end

            # Draw the types the pokemon resists
            resistOffset = 112
            drawTextEx(overlay, xLeft + resistOffset, yBase, 450, 1, _INTL("Resist:"), base, shadow)
            if resistentTypes.length == 0
                drawTextEx(overlay, xLeft + resistOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                resistentTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    bitmapUsed = barelyEffectiveTypes.include?(t) ? @types_emphasized_bitmap.bitmap : @typebitmap.bitmap
                    overlay.blt(xLeft + resistOffset + (index >= 7 ? 100 : 0), yBase + 30 + 36 * (index % 7),
              bitmapUsed, typerect)
                end
            end

            # Draw the types the pokemon is immune to
            immuneOffset = 324
            drawTextEx(overlay, xLeft + immuneOffset, yBase, 450, 1, _INTL("Immune:"), base, shadow)
            if immuneTypes.length == 0
                drawTextEx(overlay, xLeft + immuneOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                immuneTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + immuneOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end
        end
    end

    def drawPageMatchups2
        bg_path = "Graphics/Pictures/Pokedex/bg_matchups"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        xLeft = 36
        yBase = 60
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            immuneTypes = []
            resistentTypes = []
            weakTypes = []

            GameData::Type.each do |t|
                next if t.pseudo_type

                effect1 = Effectiveness.calculate_one(fSpecies.type1, t.id)
                effect2 = Effectiveness.calculate_one(fSpecies.type2, t.id)
                effect = [effect1, effect2].max

                if Effectiveness.ineffective?(effect)
                    immuneTypes.push(t)
                elsif Effectiveness.not_very_effective?(effect)
                    resistentTypes.push(t)
                elsif Effectiveness.super_effective?(effect)
                    weakTypes.push(t)
                end
            end

            # Draw the types the pokemon is super effective against
            drawTextEx(overlay, xLeft, yBase, 450, 1, _INTL("Super:"), base, shadow)
            if weakTypes.length == 0
                drawTextEx(overlay, xLeft, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                weakTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + (index >= 7 ? 100 : 0), yBase + 30 + 36 * (index % 7), @typebitmap.bitmap,
              typerect)
                end
            end

            # Draw the types the pokemon can't deal but NVE damage to
            resistOffset = 212
            drawTextEx(overlay, xLeft + resistOffset, yBase, 450, 1, _INTL("Not Very:"), base, shadow)
            if resistentTypes.length == 0
                drawTextEx(overlay, xLeft + resistOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                resistentTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + resistOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end

            # Draw the types the pokemon can't deal but immune damage to
            immuneOffset = 324
            drawTextEx(overlay, xLeft + immuneOffset, yBase, 450, 1, _INTL("No Effect:"), base, shadow)
            if immuneTypes.length == 0
                drawTextEx(overlay, xLeft + immuneOffset, yBase + 30, 450, 1, _INTL("None"), base, shadow)
            else
                immuneTypes.each_with_index do |t, index|
                    type_number = GameData::Type.get(t).id_number
                    typerect = Rect.new(0, type_number * 32, 96, 32)
                    overlay.blt(xLeft + immuneOffset, yBase + 30 + 36 * index, @typebitmap.bitmap, typerect)
                end
            end
        end
    end

    def getFormattedMoveName(move, maxWidth = 99_999)
        fSpecies = GameData::Species.get_species_form(@species, @form)
        move_data = GameData::Move.get(move)
        moveName = move_data.name

        isSTAB = move_data.category != 2 && [fSpecies.type1, fSpecies.type2].include?(move_data.type)

        # Chop letters off of excessively long names to make them fit into the maximum width
        overlay = @sprites["overlay"].bitmap
        expectedMoveNameWidth = overlay.text_size(moveName).width
        expectedMoveNameWidth *= 1.2 if isSTAB
        expectedMoveNameWidth *= 1.2 if move_data.is_signature?
        if expectedMoveNameWidth > maxWidth
            charactersToShave = 3
            loop do
                testString = moveName[0..-charactersToShave] + "..."
                expectedTestStringWidth = overlay.text_size(testString).width
                expectedTestStringWidth *= 1.2 if isSTAB
                expectedTestStringWidth *= 1.2 if move_data.is_signature?
                excessWidth = expectedTestStringWidth - maxWidth
                break if excessWidth <= 0
                charactersToShave += 1
            end
            shavedName = moveName[0..-charactersToShave]
            shavedName = shavedName[0..-1] if shavedName[shavedName.length-1] == " "
            moveName = shavedName + "..."
        end

        # Add formatting based on if the move is the same type as the user
        # Or of any of its evolutions
        if isSTAB
            moveName = "<b>#{moveName}</b>"
        elsif move_data.category < 2 && isAnyEvolutionOfType(fSpecies, move_data.type)
            moveName = "<i>#{moveName}</i>"
        end

        color = MessageConfig.pbDefaultTextMainColor
        if move_data.is_signature?
            if isSTAB
                moveName = "<outln2>" + moveName + "</outln2>"
            else
                moveName = "<outln>" + moveName + "</outln>"
            end
            shadow = SIGNATURE_COLOR
        else
            shadow = MessageConfig.pbDefaultTextShadowColor
        end
        return moveName, color, shadow
    end

    def isAnyEvolutionOfType(species_data, type)
        ret = false
        species_data.get_evolutions.each do |evolution_data|
            evoSpecies_data = GameData::Species.get_species_form(evolution_data[0], @form)
            ret = true if [evoSpecies_data.type1, evoSpecies_data.type2].include?(type)
            ret = true if isAnyEvolutionOfType(evoSpecies_data, type) # Recursion!!
        end
        return ret
    end

    MAX_LENGTH_MOVE_LIST = 6
    MOVE_LIST_SUMMARY_MOVE_NAMES_Y_INIT = 56
    MOVE_LIST_X_LEFT = 32

    def drawPageLevelUpMoves
        bg_path = "Graphics/Pictures/Pokedex/bg_moves_level"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        selected_move = nil
        for i in @available
            next unless i[2] == @form
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            learnset = fSpecies.level_moves
            displayIndex = 0
            @scrollableLists = [learnset]
            learnset.each_with_index do |learnsetEntry, listIndex|
                next if listIndex < @scroll
                level = learnsetEntry[0]
                move = learnsetEntry[1]
                return if !move || !level
                levelLabel = level.to_s
                levelLabel = _INTL("E") if level == 0
                # Draw stat line
                offsetX = 0
                maxWidth = 160
                moveName, moveColor, moveShadow = getFormattedMoveName(move, maxWidth)
                selected_move = move if listIndex == @scroll
                moveDrawY = MOVE_LIST_SUMMARY_MOVE_NAMES_Y_INIT + 32 * displayIndex
                drawTextEx(overlay, MOVE_LIST_X_LEFT + offsetX, moveDrawY, 450, 1, levelLabel, moveColor, moveShadow)
                drawFormattedTextEx(overlay, MOVE_LIST_X_LEFT + 40 + offsetX, moveDrawY, 450, moveName, moveColor, moveShadow)
                if listIndex == @scroll
                    @sprites["selectionarrow"].y = moveDrawY - 4
                    @sprites["selectionarrow"].visible = true
                end
                displayIndex += 1
                break if displayIndex > MAX_LENGTH_MOVE_LIST
            end
        end

        drawMoveInfo(selected_move)
    end

    def drawPageOtherMoves
        bg_path = "Graphics/Pictures/Pokedex/bg_moves_tutor"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor

        if @speciesCalcedFor != @species || @formCalcedFor != @form
            recalculate_other_moves_lists
            @speciesCalcedFor = @species
            @formCalcedFor = @form
        end

        selected_move = nil
        for i in @available
            next unless i[2] == @form
            
            # render the moves lists
            @scrollableLists = [@compatiblePhysMoves, @compatibleSpecMoves, @compatibleStatusMoves]
            categoryName = [_INTL("Physical"),_INTL("Special"),_INTL("Status")][@horizontalScroll]
            drawFormattedTextEx(overlay, MOVE_LIST_X_LEFT, 54, 192, "<ac><b>#{categoryName}</b></ac>", base, shadow)
            displayIndex = 0
            listIndex = -1
            if @scrollableLists[@horizontalScroll].length > 0
                @scrollableLists[@horizontalScroll].each_with_index do |move, _index|
                    listIndex += 1
                    next if listIndex < @scroll
                    maxWidth = displayIndex == 0 ? 200 : 212
                    moveName, moveColor, moveShadow = getFormattedMoveName(move, 200)
                    offsetX = 0
                    selected_move = move if listIndex == @scroll
                    moveDrawY = MOVE_LIST_SUMMARY_MOVE_NAMES_Y_INIT + 34 + 32 * displayIndex
                    drawFormattedTextEx(overlay, MOVE_LIST_X_LEFT + offsetX, moveDrawY, 450, moveName, moveColor, moveShadow)
                    if listIndex == @scroll
                        @sprites["selectionarrow"].y = moveDrawY - 4
                        @sprites["selectionarrow"].visible = true
                    end
                    displayIndex += 1
                    break if displayIndex > MAX_LENGTH_MOVE_LIST
                end
            else
                drawFormattedTextEx(overlay, MOVE_LIST_X_LEFT + 60, 90, 450, _INTL("None"), base, shadow)
            end
        end

        drawMoveInfo(selected_move)
    end

    def drawMoveInfo(selected_move)
        writeMoveInfoToInfoOverlayBackwardsL(@extraInfoOverlay.bitmap,selected_move) unless selected_move.nil?
    end

    def drawPageEvolution
        bg_path = "Graphics/Pictures/Pokedex/bg_evolution"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        formname = ""
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            formname = i[0]
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            prevolutions = fSpecies.get_prevolutions
            allEvolutions = getEvolutionsRecursive(fSpecies)

            coordinateY = 54
            index = 0
            @evolutionsArray = []

            # Show pre-volutions
            unless prevolutions.empty?
                prevoTitle = _INTL("<u>Pre-Evolutions</u>")
                drawFormattedTextEx(overlay, xLeft, coordinateY, 450, prevoTitle, base, shadow)
                coordinateY += 34

                prevolutions.each do |evolution|
                    method = evolution[1]
                    parameter = evolution[2]
                    species = evolution[0]
                    return if !method || !species
                    @evolutionsArray.push(evolution)
                    evolutionName = GameData::Species.get_species_form(species, i[2]).name
                    methodDescription = describeEvolutionMethod(method, parameter)
                    # Draw preevolution description
                    color = index == @evolutionIndex ? Color.new(255, 100, 80) : base
                    evolutionLineText = _INTL("<b>{1}</b> {2}",evolutionName,methodDescription)
                    drawFormattedTextEx(overlay, xLeft, coordinateY, 450, evolutionLineText, color, shadow)
                    coordinateY += 30
                    coordinateY += 30 if overlay.text_size(evolutionLineText).width > 450
                    index += 1
                end

                coordinateY += 30
            end

            # Show evolutions
            unless allEvolutions.empty?
                evoTitle = _INTL("<u>Evolutions</u>")
                drawFormattedTextEx(overlay, xLeft, coordinateY, 450, evoTitle, base, shadow)
                coordinateY += 34

                allEvolutions.each do |fromSpecies, evolutions|
                    evolutions.each do |evolution|
                        species = evolution[0]
                        method = evolution[1]
                        parameter = evolution[2]
                        next if method.nil? || species.nil?
                        speciesData = GameData::Species.get_species_form(species, i[2])
                        next if speciesData.nil?
                        @evolutionsArray.push(evolution)
                        evolutionName = speciesData.name
                        methodDescription = describeEvolutionMethod(method, parameter)
                        # Draw evolution description
                        color = index == @evolutionIndex ? Color.new(255, 100, 80) : base
                        fromSpeciesName = GameData::Species.get(fromSpecies).name
                        evolutionTextLine = _INTL("<b>{1}</b> {2}",evolutionName,methodDescription)
                        if fromSpecies != fSpecies.species
                            evolutionTextLine = evolutionTextLine + " " +  _INTL("(through {1})",fromSpeciesName)
                        end
                        drawFormattedTextEx(overlay, xLeft, coordinateY, 450, evolutionTextLine, color, shadow)
                        coordinateY += 30
                        coordinateY += 30 if overlay.text_size(evolutionTextLine).width > 450
                        index += 1
                    end
                end
            end

            if @evolutionsArray.empty?
                noneLabel = _INTL("None")
                noneLabelWidth = @sprites["overlay"].bitmap.text_size(noneLabel).width
                drawTextEx(overlay, Graphics.width / 2 - noneLabelWidth / 2, coordinateY + 30, 450, 1, noneLabel, base, shadow)
            end
        end
    end

    def getEncounterableAreas(species)
        areas = []
        GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
            map_is_hidden = false
            if hidden_map_encounter_switch_hash.key?(enc_data.map)
                switchID = hidden_map_encounter_switch_hash[enc_data.map]
                if !$game_switches[switchID] then
                    map_is_hidden = true
                end
            end

            enc_data.types.each do |type, slots|
                next unless slots

                totalEncounterWeight = 0
                slots.each	do |slot|
                    totalEncounterWeight += slot[0]
                end

                slots.each	do |slot|
                    next unless GameData::Species.get(slot[1]).species == species
                    mapName = begin
                        pbGetMessage(MessageTypes::MapNames, enc_data.map)
                    rescue StandardError
                        nil
                    end || "???" # This line doesn't seem to work as intended but I don't want to mess with it unnecessarily
                    # Handle errors with missing maps
                    if mapName == nil || mapName == "" then
                        mapName = _INTL("Unknown Map")
                    end
                    # Obscure map name if secret map is undiscovered
                    if map_is_hidden then
                        mapName = "???"
                    end
                    encounterTypeName = getNameForEncounterType(type)

                    encounterChance = "%g" % (100 * (slot[0] / totalEncounterWeight.to_f)).round(1)

                    if type == :Special
                        name = mapName
                    else
                        name = _INTL("{1}: {2} ({3}\%)",mapName,encounterTypeName,encounterChance)
                    end

                    areas.push(name)
                    break
                end
            end
        end
        areas.uniq!
        return areas
    end

    def drawPageArea
        bg_path = "Graphics/Pictures/Pokedex/bg_area"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            # Determine which areas the pokemon can be encountered in
            areas = getEncounterableAreas(@species)

            # Draw the areas the pokemon can be encountered in
            coordinateY = 54
            mainAreaLabel = _INTL("<u>Encounterable Areas for {1}</u>", @title)
            drawFormattedTextEx(overlay, xLeft, coordinateY, 450, mainAreaLabel, base, shadow)
            coordinateY += 34
            if areas.length == 0
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
            else
                areas.each do |area_name|
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, area_name, base, shadow)
                    coordinateY += 30
                end
            end

            # Determine which areas the pokemon's pre-evos can be encountered in
            prevo_areas = []
            fSpecies = GameData::Species.get_species_form(@species, i[2])
            prevolutions = fSpecies.get_prevolutions
            currentPrevo = prevolutions.length > 0 ? prevolutions[0] : nil
            until currentPrevo.nil?
                currentPrevoSpecies = currentPrevo[0]
                currentPrevoSpeciesName = GameData::Species.get(currentPrevoSpecies).name
                prevosAreas = getEncounterableAreas(currentPrevoSpecies)
                prevosAreas.each do |area_name|
                    prevo_areas.push([area_name, currentPrevoSpeciesName])
                end

                # Find the prevo of the prevo
                prevosfSpecies = GameData::Species.get_species_form(currentPrevoSpecies, 0)
                prevolutions = prevosfSpecies.get_prevolutions
                currentPrevo = prevolutions.length > 0 ? prevolutions[0] : nil
            end
            prevo_areas.uniq!

            next unless prevo_areas.length != 0
            # Draw the areas the pokemon's pre-evos can be encountered in
            coordinateY += 60
            prevoAreaLabel = _INTL("<u>Encounter Areas for Pre-Evolutions</u>")
            drawFormattedTextEx(overlay, xLeft, coordinateY, 450, prevoAreaLabel, base, shadow)
            coordinateY += 34
            if prevo_areas.length == 0
                drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("None"), base, shadow)
            else
                prevo_areas.each do |area_name, prevo_name|
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, area_name, base, shadow)
                    coordinateY += 30
                end
            end
        end
    end

    def drawPageForms
        bg_path = "Graphics/Pictures/Pokedex/bg_forms"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        base   = MessageConfig.pbDefaultTextMainColor
        shadow = MessageConfig.pbDefaultTextShadowColor
        # Write species and form name
        formname = ""
        for i in @available
            if i[1] == @gender && i[2] == @form
                formname = i[0]
                break
            end
        end
        shinyFormTextLeftOffset = 160
        textpos = [
            [GameData::Species.get(@species).name, Graphics.width / 2 - 68, Graphics.height - 94, 2, base, shadow],
            [formname, Graphics.width / 2 - 68, Graphics.height - 62, 2, base, shadow],
        ]
        if @showShinyForms
            textpos.push([_INTL("SPECIAL/D to"), Graphics.width - shinyFormTextLeftOffset, Graphics.height - 94, 0, base, shadow])
            textpos.push([_INTL("hide shinies"), Graphics.width - shinyFormTextLeftOffset, Graphics.height - 62, 0, base, shadow])
        else
            textpos.push([_INTL("SPECIAL/D to"), Graphics.width - shinyFormTextLeftOffset, Graphics.height - 94, 0, base, shadow])
            textpos.push([_INTL("show shinies"), Graphics.width - shinyFormTextLeftOffset, Graphics.height - 62, 0, base, shadow])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
    end

    def pbGoToPrevious
        newindex = @index
        while newindex > 0
            newindex -= 1
            newSpecies = @dexlist[newindex][:species]
            if speciesInfoViewable?(newSpecies)
                @index = newindex
                break
            end
        end
    end

    def pbGoToNext
        newindex = @index
        while newindex < @dexlist.length - 1
            newindex += 1
            newSpecies = @dexlist[newindex][:species]
            if speciesInfoViewable?(newSpecies)
                @index = newindex
                break
            end
        end
    end

    def pbChooseForm
        index = 0
        for i in 0...@available.length
            if @available[i][1] == @gender && @available[i][2] == @form
                index = i
                break
            end
        end
        oldindex = -1
        loop do
            if oldindex != index
                $Trainer.pokedex.set_last_form_seen(@species, @available[index][1], @available[index][2])
                pbUpdateDummyPokemon
                drawPage(@page)
                @sprites["uparrow"].visible   = (index > 0)
                @sprites["downarrow"].visible = (index < @available.length - 1)
                oldindex = index
            end
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::UP)
                pbPlayCursorSE
                index = (index + @available.length - 1) % @available.length
            elsif Input.trigger?(Input::DOWN)
                pbPlayCursorSE
                index = (index + 1) % @available.length
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                break
            end
        end
        @sprites["uparrow"].visible   = false
        @sprites["downarrow"].visible = false
    end

    def pbScroll
        @scroll = 0
        @sprites["leftarrow"].visible = @page == OTHER_MOVES_PAGE_ID
        @sprites["rightarrow"].visible = @page == OTHER_MOVES_PAGE_ID
        drawPage(@page)

        linesShown = @page == LEVEL_MOVES_PAGE_ID ? 7 : 6

        loop do
            Graphics.update
            Input.update
            pbUpdate
            doRefresh = false
            if Input.repeat?(Input::UP)
                if @scroll > 0
                    pbPlayCursorSE
                    @scroll -= 1
                    doRefresh = true
                elsif Input.trigger?(Input::UP)
                    pbPlayCursorSE
                    @scroll = @scrollableLists[@horizontalScroll].length - 1
                    doRefresh = true
                end
            elsif Input.repeat?(Input::DOWN)
                if @scroll < @scrollableLists[@horizontalScroll].length - 1
                    pbPlayCursorSE
                    @scroll += 1
                    doRefresh = true
                elsif Input.trigger?(Input::DOWN)
                    pbPlayCursorSE
                    @scroll = 0
                    doRefresh = true
                end
            elsif Input.repeat?(Input::LEFT)
                if @page == OTHER_MOVES_PAGE_ID
                    if @horizontalScroll > 0
                        pbPlayCursorSE
                        @horizontalScroll -= 1
                        @scroll = 0
                        doRefresh = true
                    elsif Input.trigger?(Input::LEFT)
                        pbPlayCursorSE
                        @horizontalScroll = @scrollableLists.length - 1
                        @scroll = 0
                        doRefresh = true
                    end
                end
            elsif Input.repeat?(Input::RIGHT)
                if @page == OTHER_MOVES_PAGE_ID
                    if @horizontalScroll < @scrollableLists.length - 1
                        pbPlayCursorSE
                        @horizontalScroll += 1
                        @scroll = 0
                        doRefresh = true
                    elsif Input.trigger?(Input::RIGHT)
                        pbPlayCursorSE
                        @horizontalScroll = 0
                        @scroll = 0
                        doRefresh = true
                    end
                end
            elsif Input.repeat?(Input::JUMPUP) # Jump multiple lines
                if @scroll > 0
                    pbPlayCursorSE
                    @scroll -= linesShown
                    @scroll = 0 if @scroll < 0
                    doRefresh = true
                else
                    pbPlayBuzzerSE
                end
            elsif Input.repeat?(Input::JUMPDOWN)
                offsetMax = @scrollableLists[@horizontalScroll].length - 1
                if @scroll < offsetMax
                    pbPlayCursorSE
                    @scroll += linesShown
                    @scroll = offsetMax if @scroll > offsetMax
                    doRefresh = true
                else
                    pbPlayBuzzerSE
                end
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                @scroll = -1
                drawPage(@page)
                break
            elsif Input.trigger?(Input::SPECIAL)
                if @page == OTHER_MOVES_PAGE_ID
                    toggle_other_moves_list_sort_mode
                    @scroll = 0
                    doRefresh = true
                end
            end
            drawPage(@page) if doRefresh
        end
        @sprites["leftarrow"].visible = false
        @sprites["rightarrow"].visible = false
    end

    def toggle_other_moves_list_sort_mode
        pbPlayDecisionSE
        if $PokemonGlobal.dex_tutor_list_sort_mode >= 2
            $PokemonGlobal.dex_tutor_list_sort_mode = 0
        else
            $PokemonGlobal.dex_tutor_list_sort_mode += 1
        end

        calculate_other_moves_sorting_proc

        recalculate_other_moves_lists

        alertToDexTutorListSortMode
    end

    def calculate_other_moves_sorting_proc
        case $PokemonGlobal.dex_tutor_list_sort_mode
        when 0
            @tutorMovesSorting = Proc.new { |moveA, moveB|
                moveAData = GameData::Move.get(moveA)
                moveBData = GameData::Move.get(moveB)
                next moveAData.name <=> moveBData.name
            }
        when 1
            @tutorMovesSorting = Proc.new { |moveA, moveB|
                moveAData = GameData::Move.get(moveA)
                moveBData = GameData::Move.get(moveB)
                if moveAData.base_damage == moveBData.base_damage
                    next moveAData.name <=> moveBData.name
                else
                    next moveBData.base_damage <=> moveAData.base_damage # reversed
                end
            }
        when 2
            @tutorMovesSorting = Proc.new { |moveA, moveB|
                moveAData = GameData::Move.get(moveA)
                moveBData = GameData::Move.get(moveB)
                if moveAData.type == moveBData.type
                    next moveAData.name <=> moveBData.name
                else
                    next GameData::Type.get(moveAData.type).id_number <=> GameData::Type.get(moveBData.type).id_number
                end
            }
        end
    end

    def recalculate_other_moves_lists
        species_data = GameData::Species.get_species_form(@species, @form)

        # Create the seperate moves list
        compatibleMoves = species_data.learnable_moves
        @compatiblePhysMoves = compatibleMoves.select do |move|
            movaData = GameData::Move.get(move)
            next movaData.category == 0 || movaData.category == 3
        end
        @compatibleSpecMoves = compatibleMoves.select do |move|
            movaData = GameData::Move.get(move)
            next movaData.category == 1 || movaData.category == 3
        end
        @compatibleStatusMoves = compatibleMoves.select do |move|
            movaData = GameData::Move.get(move)
            next movaData.category == 2
        end

        # sort the moves lists
        @compatiblePhysMoves.sort!{ |moveA, moveB|
            @tutorMovesSorting.call(moveA, moveB)
        }
        @compatibleSpecMoves.sort!{ |moveA, moveB|
            @tutorMovesSorting.call(moveA, moveB)
        }
        @compatibleStatusMoves.sort!{ |moveA, moveB|
            @tutorMovesSorting.call(moveA, moveB)
        }
    end

    def alertToDexTutorListSortMode
        case $PokemonGlobal.dex_tutor_list_sort_mode
        when 0
            pbMessage(_INTL("Moves now sorted by name."))
        when 1
            pbMessage(_INTL("Moves now sorted by base power."))
        when 2
            pbMessage(_INTL("Moves now sorted by type."))
        end
    end

    def pbScrollEvolutions
        @evolutionIndex = 0
        drawPage(@page)
        loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.repeat?(Input::UP) && @evolutionIndex > 0
                pbPlayCursorSE
                @evolutionIndex -= 1
                dorefresh = true
            elsif Input.repeat?(Input::DOWN) && @evolutionIndex < @evolutionsArray.length - 1
                pbPlayCursorSE
                @evolutionIndex += 1
                dorefresh = true
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                otherSpecies = @evolutionsArray[@evolutionIndex][0]
                return otherSpecies
            end
            drawPage(@page) if dorefresh
        end
        return nil
    end

    def drawPageDEBUG
        @bg_path = "Graphics/Pictures/Pokedex/bg_evolution"
        bg_path += "_dark" if darkMode?
        @sprites["background"].setBitmap(_INTL(bg_path))
        overlay = @sprites["overlay"].bitmap
        base = MessageConfig::DARK_TEXT_MAIN_COLOR
        shadow = MessageConfig::DARK_TEXT_SHADOW_COLOR
        xLeft = 36
        for i in @available
            next unless i[2] == @form
            fSpecies = GameData::Species.get_species_form(@species, i[2])

            coordinateY = 54

            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Analysis of {1}", @title), base, shadow)
            coordinateY += 34

            # Use count
            useCount = @speciesUseData[entry[:species]]
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Use count: {1}, {2}", useCount[0], useCount[1]), base, shadow)
            coordinateY += 32

            # Earliest level accessible
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Earliest level: {1}", fSpecies.earliest_available), base, shadow)
            coordinateY += 32

            # Speed tier

            numberFaster = 0
            total = 0
            mySpeed = fSpecies.base_stats[:SPEED]
            GameData::Species.each do |otherSpeciesData|
                next if otherSpeciesData.form != 0
                next if otherSpeciesData.get_evolutions.length > 0
                next if otherSpeciesData.isLegendary?
                numberFaster += 1 if mySpeed > otherSpeciesData.base_stats[:SPEED]
                total += 1
            end

            fasterThanPercentOfMetaGame = numberFaster.to_f / total.to_f
            fasterThanPercentOfMetaGame = (fasterThanPercentOfMetaGame * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Faster than {1}% of final evos", fasterThanPercentOfMetaGame), base,
              shadow)
            coordinateY += 32

            # Pokeball catch chance
            totalHP = calcStatGlobal(fSpecies.base_stats[:HP], 40, 8, hp: true)
            currentHP = (totalHP * 0.15).floor
            chanceToCatch = theoreticalCaptureChance(:NONE, currentHP, totalHP, fSpecies.catch_rate)
            chanceToCatch = (chanceToCatch * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("{1}% chance to catch at level 40, %15 health", chanceToCatch), base,
              shadow)
            coordinateY += 32

            # Coverage types

            typesOfCoverage = get_bnb_coverage(fSpecies)

            drawTextEx(overlay, xLeft, coordinateY, 450, 1,
                _INTL("BnB coverage {1}: {2}", typesOfCoverage.length, typesOfCoverage[0..[2, typesOfCoverage.length].min]), base, shadow)
            coordinateY += 32
            if typesOfCoverage.length > 2
                for index in 1..10
                    rangeStart = (5 * index) - 2
                    rangeEnd = [rangeStart + 5, typesOfCoverage.length].min
                    drawTextEx(overlay, xLeft, coordinateY, 450, 1, typesOfCoverage[rangeStart..rangeEnd].to_s, base,
                shadow)
                    coordinateY += 32
                    break if rangeEnd == typesOfCoverage.length
                end
            end

            # Metagame coverage
            numberCovered = 0
            GameData::Species.each do |otherSpeciesData|
                next if otherSpeciesData.form != 0
                next if otherSpeciesData.get_evolutions.length > 0
                next if otherSpeciesData.isLegendary?

                typesOfCoverage.each do |coverageType|
                    effect = Effectiveness.calculate(coverageType, [otherSpeciesData.type1, otherSpeciesData.type2])

                    if Effectiveness.super_effective?(effect)
                        numberCovered += 1
                        break
                    end
                end
            end

            coversPercentOfMetaGame = numberCovered.to_f / total.to_f
            coversPercentOfMetaGame = (coversPercentOfMetaGame * 10_000).floor / 100.0
            drawTextEx(overlay, xLeft, coordinateY, 450, 1, _INTL("Covers {1}% of final evos", coversPercentOfMetaGame), base,
              shadow)
            coordinateY += 32

            drawTextEx(overlay, xLeft, coordinateY, 450, 6, _INTL("Notes: {1}", fSpecies.notes), base, shadow)
            coordinateY += 32
        end
    end

    def pbScene
		formIndex = 0
		for i in 0...@available.length
			if @available[i][1] == @gender && @available[i][2] == @form
				formIndex = i
				break
			end
		end
		oldFormIndex = formIndex

        GameData::Species.play_cry_from_species(@species, @form)
        highestLeftRepeat = 0
        highestRightRepeat = 0
        loop do
			if oldFormIndex != formIndex
				$Trainer.pokedex.set_last_form_seen(@species, @available[formIndex][1], @available[formIndex][2])
				pbUpdateDummyPokemon
				drawPage(@page)
				oldFormIndex = formIndex
			end
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
                GameData::Species.play_cry_from_species(@species, @form) if @page == 1
            elsif Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)
                if @page == 1
                    pbPlayCloseMenuSE
                    break
                elsif @page == LEVEL_MOVES_PAGE_ID || @page == OTHER_MOVES_PAGE_ID
                    pbPlayDecisionSE
                    pbScroll
                    dorefresh = true
                elsif @page == 8 && @evolutionsArray.length > 0   # Evolutions
                    if @linksEnabled
                        pbPlayDecisionSE
                        newSpecies = pbScrollEvolutions
                        return newSpecies if newSpecies
                        @evolutionIndex = -1
                        dorefresh = true
                    else
                        pbPlayBuzzerSE
                    end
                elsif @page == FORMS_PAGE_ID # Forms
                    if @available.length > 1
                        pbPlayDecisionSE
                        pbChooseForm
                        dorefresh = true
                    end
                end
            elsif Input.repeat?(Input::UP)
				if Input.press?(Input::ACTION)
        			formIndex = (formIndex + @available.length-1) % @available.length
					if formIndex != oldFormIndex
						pbPlayCursorSE
					else
						pbPlayBuzzerSE
					end
				else
					oldindex = @index
					pbGoToPrevious
					if @index != oldindex
						@scroll = -1
						pbUpdateDummyPokemon
						@available = pbGetAvailableForms
						pbSEStop
						(@page == 1) ? GameData::Species.play_cry_from_species(@species, @form) : pbPlayCursorSE
						dorefresh = true
					end
				end
            elsif Input.repeat?(Input::DOWN)
				if Input.press?(Input::ACTION)
        			formIndex = (formIndex + 1) % @available.length
					if formIndex != oldFormIndex
						pbPlayCursorSE
					else
						pbPlayBuzzerSE
					end
				else
					oldindex = @index
					pbGoToNext
					if @index != oldindex
						@scroll = -1
						pbUpdateDummyPokemon
						@available = pbGetAvailableForms
						pbSEStop
						(@page == 1) ? GameData::Species.play_cry_from_species(@species, @form) : pbPlayCursorSE
						dorefresh = true
					end
				end
            elsif Input.repeat?(Input::LEFT)
                highestRightRepeat = 0
                repeats = 1 + Input.time?(Input::LEFT) / 100_000
                if repeats > highestLeftRepeat
                    highestLeftRepeat = repeats
                    oldpage = @page
                    @page -= 1
                    @page = pageTitles.length - 1 if @page < 1 # Wrap around
                    if @page != oldpage
                        @scroll = -1
                        @horizontalScroll = 0
                        pbPlayCursorSE
                        dorefresh = true
                    end
                end
            elsif Input.repeat?(Input::RIGHT)
                highestLeftRepeat = 0
                repeats = 1 + Input.time?(Input::RIGHT) / 100_000
                if repeats > highestRightRepeat
                    highestRightRepeat = repeats
                    oldpage = @page
                    @page += 1
                    @page = 1 if @page > pageTitles.length - 1 # Wrap around
                    if @page != oldpage
                        @scroll = -1
                        @horizontalScroll = 0
                        pbPlayCursorSE
                        dorefresh = true
                    end
                end
            elsif Input.pressex?(:NUMBER_1)
                dorefresh = true if moveToPage(1)
            elsif Input.pressex?(:NUMBER_2)
                dorefresh = true if moveToPage(2)
            elsif Input.pressex?(:NUMBER_3)
                dorefresh = true if moveToPage(3)
            elsif Input.pressex?(:NUMBER_4)
                dorefresh = true if moveToPage(4)
            elsif Input.pressex?(:NUMBER_5)
                dorefresh = true if moveToPage(5)
            elsif Input.pressex?(:NUMBER_6)
                dorefresh = true if moveToPage(6)
            elsif Input.pressex?(:NUMBER_7)
                dorefresh = true if moveToPage(7)
            elsif Input.pressex?(:NUMBER_8)
                dorefresh = true if moveToPage(8)
            elsif Input.pressex?(:NUMBER_9)
                dorefresh = true if moveToPage(9)
            elsif Input.pressex?(:NUMBER_0)
                dorefresh = true if moveToPage(10)
            elsif Input.trigger?(Input::SPECIAL)
                if @page == OTHER_MOVES_PAGE_ID
                    toggle_other_moves_list_sort_mode
                    dorefresh = true
                elsif @page == FORMS_PAGE_ID
                    pbPlayDecisionSE
                    @showShinyForms = !@showShinyForms
                    $PokemonGlobal.dex_forms_shows_shinies = @showShinyForms
                    pbUpdateDummyPokemon
                    dorefresh = true
                end
            elsif Input.press?(Input::ACTION) && debugControl
                @scroll = -1
                pbPlayCursorSE
                @page = pageTitles.length
                dorefresh = true
            else
                highestLeftRepeat = 0
                highestRightRepeat = 0
            end
            drawPage(@page) if dorefresh
        end
        return @index
    end

    def moveToPage(pageNum)
        oldpage = @page
        @page = pageNum
        @page = 1 if @page < 1
        @page = 10 if @page > 10
        if @page != oldpage
            @scroll = -1
            pbPlayCursorSE
            return true
        end
        return false
    end
end
