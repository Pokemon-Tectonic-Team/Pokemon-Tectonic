class PokemonPokedex_Scene
    def searchBySpeciesName
        nameInput = pbEnterText(_INTL("Search species..."), 0, 12)
        if nameInput && nameInput != ""
            reversed = nameInput[0] == "-"
            nameInput = nameInput[1..-1] if reversed
            dexlist = searchStartingList
            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])
                searchPokeName = dex_item[:data].name
                value = searchPokeName.downcase.include?(nameInput.downcase) ^ reversed # Boolean XOR
                next value
            end
            return dexlist
        end
        return nil
    end

    def searchByAbility
        abilitySearchTypeSelection = pbMessage(_INTL("Which search?"), [_INTL("Name"), _INTL("Description"), _INTL("Cancel")],
3)
        return if abilitySearchTypeSelection == 2

        if abilitySearchTypeSelection == 0
            while true
                abilityNameInput = pbEnterText(_INTL("Search abilities..."), 0, 20)
                if abilityNameInput && abilityNameInput != ""
                    reversed = abilityNameInput[0] == "-"
                    abilityNameInput = abilityNameInput[1..-1] if reversed

                    actualAbility = nil
                    GameData::Ability.each do |abilityData|
                        if abilityData.name.downcase == abilityNameInput.downcase
                            actualAbility = abilityData.id
                            break
                        end
                    end
                    if actualAbility.nil?
                        pbMessage(_INTL("Invalid input: {1}", abilityNameInput))
                        next
                    end

                    dexlist = searchStartingList
                    dexlist = dexlist.find_all do |dex_item|
                        next false if autoDisqualifyFromSearch(dex_item[:species])
                        searchPokeAbilities = dex_item[:data].abilities
                        value = false
                        value = true if searchPokeAbilities.include?(actualAbility)
                        value = value ^ reversed # Boolean XOR
                        next value
                    end
                    return dexlist
                else
                    return nil
                end
            end
        elsif abilitySearchTypeSelection == 1
            abilityDescriptionInput = pbEnterText(_INTL("Search ability desc..."), 0, 20)
            if abilityDescriptionInput && abilityDescriptionInput != ""
                reversed = abilityDescriptionInput[0] == "-"
                abilityDescriptionInput = abilityDescriptionInput[1..-1] if reversed

                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])
                    searchPokeAbilities = dex_item[:data].abilities
                    value = false
                    if searchPokeAbilities[0] && GameData::Ability.get(searchPokeAbilities[0]).description.downcase.include?(abilityDescriptionInput.downcase)
                        value = true
                    end
                    if searchPokeAbilities[1] && GameData::Ability.get(searchPokeAbilities[1]).description.downcase.include?(abilityDescriptionInput.downcase)
                        value = true
                    end
                    value = value ^ reversed # Boolean XOR
                    next value
                end
                return dexlist
            else
                return nil
            end
        end
        return nil
    end

    def searchByMoveLearned
        learningMethodSelection = pbMessage(_INTL("Which method?"),[_INTL("Any"), _INTL("Level Up"), _INTL("By Specific Level"), _INTL("Other"), _INTL("Coverage Type"), _INTL("Cancel")], 6)
        return if learningMethodSelection == 5

        if learningMethodSelection == 2
            while true
                levelTextInput = pbEnterText(_INTL("Enter level..."), 0, 3)
                return nil if levelTextInput.blank?
                reversed = levelTextInput[0] == "-"
                levelTextInput = levelTextInput[1..-1] if reversed

                levelIntAttempt = levelTextInput.to_i
                if levelIntAttempt == 0
                    pbMessage(_INTL("Invalid level input."))
                    next
                end
                break
            end
        end

        # Search by coverage type
        if learningMethodSelection == 4
            while true
                typeTextInput = pbEnterText(_INTL("Enter type..."), 0, 100)
                return nil if typeTextInput.blank?
                reversed = typeTextInput[0] == "-"
                typeTextInput = typeTextInput[1..-1] if reversed

                typeTextInput.downcase!

                coverageType = nil
                GameData::Type.each do |type_data|
                    next unless type_data.name.downcase == typeTextInput
                    coverageType = type_data.id
                    break
                end

                if coverageType.nil?
                    pbMessage(_INTL("Invalid input: {1}", typeTextInput))
                    next
                end

                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])

                    speciesData = dex_item[:data]
                    contains = false
                    speciesData.learnable_moves.each do |moveID|
                        moveData = GameData::Move.get(moveID)
                        next unless moveData.damaging?
                        next unless moveData.type == coverageType
                        contains = true
                        break
                    end
                    next contains ^ reversed # Boolean XOR
                end
                return dexlist

                break
            end
        end

        # All other move searches
        while true
            moveNameInput = pbEnterText(_INTL("Move name..."), 0, 20)
            if moveNameInput && moveNameInput != ""
                reversed = moveNameInput[0] == "-"
                moveNameInput = moveNameInput[1..-1] if reversed

                actualMove = nil
                GameData::Move.each do |moveData|
                    if moveData.name.downcase == moveNameInput.downcase
                        actualMove = moveData.id
                        break
                    end
                end
                if actualMove.nil? || !GameData::Move.get(actualMove).learnable?
                    pbMessage(_INTL("Invalid input: {1}", moveNameInput))
                    next
                end

                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])
                    contains = false

                    species_data = dex_item[:data]

                    # By level up
                    if [0, 1].include?(learningMethodSelection)
                        species_data.level_moves.each do |learnset_entry|
                            if learnset_entry[1] == actualMove
                                contains = true
                                break
                            end
                        end
                    end

                    # By specific level
                    if learningMethodSelection == 2
                        species_data.level_moves.each do |learnset_entry|
                            break if learnset_entry[0] > levelIntAttempt
                            if learnset_entry[1] == actualMove
                                contains = true
                                break
                            end
                        end
                    end

                    # Learns it by tutor or anything
                    if [0, 3].include?(learningMethodSelection)
                        species_data.learnable_moves.each do |move|
                            if move == actualMove
                                contains = true
                                break
                            end
                        end
                    end

                    next contains ^ reversed # Boolean XOR
                end
                return dexlist
            end
            break
        end
        return nil
    end

    def searchByType
        selections = [_INTL("Either"), _INTL("Full"), _INTL("Cancel")]
        learningMethodSelection = pbMessage(_INTL("Either type or full typing?"), selections, selections.length)
        return if learningMethodSelection == selections.length - 1

        full = learningMethodSelection == 1

        while true
            typesInput = pbEnterText(full ? _INTL("Search full typing...") : _INTL("Search type..."), 0, 100)
            typesInput.downcase!
            if typesInput && typesInput != ""
                reversed = typesInput[0] == "-"
                typesInput = typesInput[1..-1] if reversed
                typesInputArray = typesInput.split(" ")

                # Throw out improper input
                if typesInputArray.length > 1 && !full
                    pbMessage(_INTL("Don't input more than one type for \"Either\" type search. "))
                    next
                end

                # Don't do the search if one of the input type names isn't an actual type
                invalid = false
                typesInputArray.each do |type_input_entry|
                    typeIsReal = false
                    GameData::Type.each do |type_data|
                        typeIsReal = true if type_data.name.downcase == type_input_entry
                        break if typeIsReal
                    end
                    next if typeIsReal
                    pbMessage(_INTL("Invalid input: {1}", type_input_entry))
                    invalid = true
                    break
                end
                next if invalid

                typesInputArray = [typesInputArray[0], typesInputArray[0]] if typesInputArray.length == 1

                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])
                    searchPokeType1 = dex_item[:data].type1
                    searchPokeType1Name = GameData::Type.get(searchPokeType1).name.downcase if searchPokeType1
                    searchPokeType2 = dex_item[:data].type2 || dex_item[:data].type1
                    searchPokeType2Name = GameData::Type.get(searchPokeType2).name.downcase if searchPokeType2

                    pokeTypeNames = [searchPokeType1Name, searchPokeType2Name]

                    if full
                        survivesSearch = pokeTypeNames.eql?(typesInputArray) || pokeTypeNames.reverse.eql?(typesInputArray)
                    else
                        survivesSearch = pokeTypeNames.include?(typesInputArray[0])
                    end

                    next survivesSearch ^ reversed # Boolean XOR
                end
                return dexlist
            end
            return nil
        end
    end

    def searchByEvolutionMethod
        selections = [_INTL("Can Evolve by Method"), _INTL("Evolved From Method"), _INTL("No Evolutions"), _INTL("No Prevolutions"), _INTL("Split Evo"), _INTL("Cancel")]
        relationSelection = pbMessage(_INTL("Which search?"), selections, selections.length)
        return if relationSelection == 5

        if [0,1].include?(relationSelection)
            evoMethodTextInput = pbEnterText(_INTL("Search method..."), 0, 12)
            if evoMethodTextInput && evoMethodTextInput != ""
                reversed = evoMethodTextInput[0] == "-"
                evoMethodTextInput = evoMethodTextInput[1..-1] if reversed
                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])
                    anyContain = false

                    entries = relationSelection == 0 ? dex_item[:data].get_evolutions : dex_item[:data].get_prevolutions

                    # Evolutions
                    entries.each do |evomethod|
                        strippedActualDescription = describeEvolutionMethod(evomethod[1], evomethod[2]).downcase.delete(" ")
                        strippedInputString = evoMethodTextInput.downcase.delete(" ")
                        anyContain = true if strippedActualDescription.include?(strippedInputString)
                    end
                    value = anyContain ^ reversed # Boolean XOR
                    next value
                end
                return dexlist
            end
        else
            dexlist = searchStartingList
            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                case relationSelection
                when 2
                    next dex_item[:data].get_evolutions.empty?
                when 3
                    next dex_item[:data].get_prevolutions.empty?
                when 4
                    next dex_item[:data].get_evolutions.length > 1
                end

                next true
            end
            return dexlist
        end

        
        return nil
    end

    def searchByAvailableLevel
        levelTextInput = pbEnterText(_INTL("Search available by level..."), 0, 3)
        if levelTextInput && levelTextInput != ""
            reversed = levelTextInput[0] == "-"
            levelTextInput = levelTextInput[1..-1] if reversed

            levelIntAttempt = levelTextInput.to_i
            return nil if levelIntAttempt == 0

            levelCheck = roundUpToNextCap(levelIntAttempt)

            dexlist = searchStartingList
            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])
                available = dex_item[:data].available_by?(levelCheck)
                next available ^ reversed # Boolean XOR
            end
            return dexlist
        end
        return nil
    end

    def searchByCollecting
        selection = pbMessage(_INTL("Which search?"),[_INTL("Starred"), _INTL("Owned"), _INTL("Not Starred"), _INTL("Not Owned"), _INTL("Cancel")], 5)
        if selection != 4
            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                species = dex_item[:species]
                next false if autoDisqualifyFromSearch(species)

                case selection
                when 0
                    next $PokemonGlobal.speciesStarred?(species)
                when 1
                    next $Trainer.owned?(species)
                when 2
                    next !$PokemonGlobal.speciesStarred?(species)
                when 3
                    next !$Trainer.owned?(species)
                end
            end

            return dexlist
        end
        return nil
    end

    def searchByStatComparison
        statSelection = pbMessage(_INTL("Which stat?"), [_INTL("HP"), _INTL("Attack"), _INTL("Defense"), _INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("Speed"), _INTL("Total"), _INTL("Phys. EHP"), _INTL("Spec. EHP"), _INTL("Cancel"),], 10)
        return if statSelection == 9
        comparisonSelection = pbMessage(_INTL("Which comparison?"), [_INTL("Equal to number"),_INTL("Greater than number"), _INTL("Less than number"), _INTL("Equal to stat"),_INTL("Greater than stat"), _INTL("Less than stat"), _INTL("Cancel"),], 7)
        return if comparisonSelection == 6

        stats = %i[HP ATTACK DEFENSE SPECIAL_ATTACK SPECIAL_DEFENSE SPEED PEHP SEPH]
        if comparisonSelection <= 2
            statTextInput = pbEnterText(_INTL("Input value..."), 0, 3)
            if statTextInput && statTextInput != ""
                statIntAttempt = statTextInput.to_i

                return nil if statIntAttempt == 0

                comparitorB = statIntAttempt
            else
                return nil
            end
        elsif statSelectionComparison = pbMessage(_INTL("Compare to which stat?"), [_INTL("HP"), _INTL("Attack"), _INTL("Defense"),_INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("Speed"), _INTL("Phys. EHP"), _INTL("Spec. EHP"), _INTL("Cancel"),], 9)
            return if statSelectionComparison == 8

            comparitorB = stats[statSelectionComparison]
        end

        comparitorA = stats[statSelection]

        dexlist = searchStartingList
        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])

            species_data = dex_item[:data]

            statToCompareA = 0
            case statSelection
            when 0..5
                statToCompareA = species_data.base_stats[comparitorA]
            when 6
                species_data.base_stats.each do |statName, statValue|
                    statToCompareA += statValue
                end
            when 7
                statToCompareA = species_data.physical_ehp
            when 8
                statToCompareA = species_data.special_ehp
            end

            statToCompareB = 0
            if comparitorB.is_a?(Symbol)
                calced_stats = species_data.base_stats.clone
                calced_stats[:PEHP] = species_data.physical_ehp
                calced_stats[:SEHP] = species_data.special_ehp
                statToCompareB = calced_stats[comparitorB]
            else
                statToCompareB = comparitorB
            end

            result = false
            case comparisonSelection % 3
            when 0
                result = statToCompareA == statToCompareB
            when 1
                result =  statToCompareA > statToCompareB
            when 2
                result =  statToCompareA < statToCompareB
            end

            next result
        end

        return dexlist
    end

    def searchByMisc
        miscSearches = []
        cmdCollecting	= -1
        cmdMapFound = -1
        cmdZooSection	= -1
        cmdWildItem 			    = -1
        cmdIsLegendary	= -1
        cmdMovesetConformance	= -1
        cmdNoMonumentUses = -1
        cmdOneAbility	= -1
        cmdHasSignatureMove = -1
        cmdHasSignatureAbility	= -1
        cmdHasSignature = -1
        cmdAvatarData = -1
        cmdOneAbility	= -1
        cmdHasCoverageType	= -1
        cmdMultipleForms = -1
        cmdInvertList = -1
        miscSearches[cmdCollecting = miscSearches.length] = _INTL("Collecting")
        miscSearches[cmdMapFound = miscSearches.length] = _INTL("Map Found")
        miscSearches[cmdWildItem = miscSearches.length] = _INTL("Wild Items")
        miscSearches[cmdIsLegendary = miscSearches.length] = _INTL("Legendary")
        miscSearches[cmdMovesetConformance = miscSearches.length] = _INTL("Moveset Noncomfority (D)") if $DEBUG
        miscSearches[cmdNoMonumentUses = miscSearches.length] = _INTL("No Monument Uses (D)") if $DEBUG
        miscSearches[cmdOneAbility = miscSearches.length] = _INTL("One Ability (D)") if $DEBUG
        miscSearches[cmdHasSignatureMove = miscSearches.length] = _INTL("Signature Move")
        miscSearches[cmdHasSignatureAbility = miscSearches.length] = _INTL("Signature Ability")
        miscSearches[cmdHasSignature = miscSearches.length] = _INTL("Signature (D)") if $DEBUG
        miscSearches[cmdAvatarData = miscSearches.length] = _INTL("Avatar Data (D)") if $DEBUG
        miscSearches[cmdGeneration = miscSearches.length] = _INTL("Generation")
        miscSearches[cmdMultipleForms = miscSearches.length] = _INTL("Multiple Forms")
        miscSearches[cmdInvertList = miscSearches.length] = _INTL("Invert Current")
        miscSearches.push(_INTL("Cancel"))
        searchSelection = pbMessage(_INTL("Which search?"), miscSearches, miscSearches.length + 1)
        if cmdCollecting > -1 && searchSelection == cmdCollecting
            return searchByCollecting
        elsif cmdMapFound > -1 && searchSelection == cmdMapFound
            return searchByMapFound
        elsif cmdZooSection > -1 && searchSelection == cmdZooSection
            return searchByZooSection
        elsif cmdIsLegendary > -1 && searchSelection == cmdIsLegendary
            return searchByLegendary
        elsif cmdWildItem > -1 && searchSelection == cmdWildItem
            return searchByWildItem
        elsif cmdGeneration > -1 && searchSelection == cmdGeneration
            return searchByGeneration
        elsif cmdMovesetConformance > -1 && searchSelection == cmdMovesetConformance
            return searchByMovesetConformance
        elsif cmdNoMonumentUses > -1 && searchSelection == cmdNoMonumentUses
            return searchByNoMonumentUses
        elsif cmdOneAbility > -1 && searchSelection == cmdOneAbility
            return searchByOneAbility
        elsif cmdHasSignatureMove > -1 && searchSelection == cmdHasSignatureMove
            return searchBySignatureMove
        elsif cmdHasSignatureAbility > -1 && searchSelection == cmdHasSignatureAbility
            return searchBySignatureAbility
        elsif cmdAvatarData > -1 && searchSelection == cmdAvatarData
            return searchByHasAvatarData
        elsif cmdHasSignature > -1 && searchSelection == cmdHasSignature
            return searchBySignature
        elsif cmdMultipleForms > -1 && searchSelection == cmdMultipleForms
            return searchByMultipleForms
        elsif cmdInvertList > -1 && searchSelection == cmdInvertList
            return invertSearchList
        end
    end

    def searchByMultipleForms
        dexlist = searchStartingList

        hasMultipleForms = {}

        GameData::Species.each do |sp|
            hasMultipleForms[sp.species] = false unless hasMultipleForms.has_key?(sp.species)
            next if sp.form == 0
            hasMultipleForms[sp.species] = true
        end

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])

            next hasMultipleForms[dex_item[:species]]
        end
        return dexlist
    end

    def searchByTribe
        dexlist = searchStartingList

        commands = []
        tribes = []
        GameData::Tribe.each do |tribe|
            next if tribe.id == :DEBUG_TESTTRIBE && !$DEBUG
            tribes.push(tribe.id)
            commands.push(getTribeName(tribe.id))
        end
        commands.push(_INTL("Cancel"))
        command = pbMessage(_INTL("Which tribe?"), commands, commands.length)
        return if command == commands.length - 1

        chosenTribe = tribes[command]

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])
            next dex_item[:data].tribes.include?(chosenTribe)
        end
        return dexlist
    end

    def searchByHasCoverageType
        while true
            typeInput = pbEnterText(_INTL("Search type..."), 0, 100)
            typeInput.downcase!
            next unless typeInput && typeInput != ""
            reversed = typeInput[0] == "-"
            typeInput = typeInput[1..-1] if reversed

            # Don't do the search if one of the input type names isn't an actual type
            realTypeSymbol = nil
            GameData::Type.each do |type_data|
                if type_data.name.downcase == typeInput
                    realTypeSymbol = type_data.id
                    break
                end
            end
            if realTypeSymbol.nil?
                pbMessage(_INTL("Invalid input: {1}", typeInput))
                next
            end

            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                typesOfCoverage = get_bnb_coverage(dex_item[:data])

                next typesOfCoverage.include?(realTypeSymbol) ^ reversed # Boolean XOR
            end
            return dexlist
        end
    end

    def searchByOneAbility
        dexlist = searchStartingList

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])

            next dex_item[:data].abilities.length == 1
        end
        return dexlist
    end

    def searchBySignatureMove
        selection = pbMessage(_INTL("Which search?"), [_INTL("Has Signature Move"), _INTL("Doesn't"), _INTL("Cancel")], 3)
        if selection != 2
            reversed = selection == 1

            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                hasSignatureMove = false
                autoDisqualifyFromSearch(dex_item[:species])

                # All moves
                dex_item[:data].learnable_moves.each do |move|
                    if GameData::Move.get(move).is_signature?
                        hasSignatureMove = true
                        break
                    end
                end

                next hasSignatureMove ^ reversed
            end
        end
        return dexlist
    end

    def searchBySignatureAbility
        selection = pbMessage(_INTL("Which search?"), [_INTL("Has Signature Ability"), _INTL("Doesn't"), _INTL("Cancel")], 3)
        if selection != 2
            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                hasSignatureAbility = false
                dex_item[:data].abilities.each do |ability|
                    hasSignatureAbility = true if GameData::Ability.get(ability).is_signature?
                end
                
                if selection == 0
                    next hasSignatureAbility
                else
                    next !hasSignatureAbility
                end
            end
        end
        return dexlist
    end

    def searchByHasAvatarData
        dexlist = searchStartingList

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])
            next GameData::Avatar.exists?(dex_item[:data].species)
        end
        return dexlist
    end

    def searchBySignature
        selection = pbMessage(_INTL("Which search?"), [_INTL("Has Signature"), _INTL("Doesn't"), _INTL("Cancel")], 3)
        if selection != 2
            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                if selection == 0
                    next @signatureMoves.has_value?(dex_item[:data].id) || @signatureAbilities.has_value?(dex_item[:data].id)
                else
                    next !@signatureMoves.has_value?(dex_item[:data].id) && !@signatureAbilities.has_value?(dex_item[:data].id)
                end
            end
            return dexlist
        end
        return nil
    end

    def searchByWildItem
        dexlist = searchStartingList

        wildItemNameTextInput = pbEnterText(_INTL("Search item name..."), 0, 20)
        return if wildItemNameTextInput.blank?
        reversed = wildItemNameTextInput[0] == "-"
        wildItemNameTextInput = wildItemNameTextInput[1..-1] if reversed

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])

            items = []
            items.push(dex_item[:data].wild_item_common) if dex_item[:data].wild_item_common
            items.push(dex_item[:data].wild_item_uncommon) if dex_item[:data].wild_item_uncommon
            items.push(dex_item[:data].wild_item_rare) if dex_item[:data].wild_item_rare
            items.uniq!
            items.compact!

            containsText = false
            items.each_with_index do |item, _index|
                name = GameData::Item.get(item).name.downcase
                containsText = true if name.include?(wildItemNameTextInput.downcase)
            end

            next containsText ^ reversed # Boolean XOR
        end
        return dexlist
    end

    def searchByMapFound
        dexlist = searchStartingList

        mapNameTextInput = pbEnterText(_INTL("Search map name..."), 0, 20)
        return if mapNameTextInput.blank?
        reversed = mapNameTextInput[0] == "-"
        mapNameTextInput = mapNameTextInput[1..-1] if reversed

        speciesPresent = []
        GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
            mapName = pbGetMapNameFromId(enc_data.map)
            next unless mapName.downcase.include?(mapNameTextInput.downcase)
            enc_data.types.each do |_key, slots|
                next unless slots
                slots.each do |slot|
                    speciesPresent.push(slot[1])
                end
            end
        end

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])

            next speciesPresent.include?(dex_item[:species]) ^ reversed # Boolean XOR
        end
        return dexlist
    end

    def searchByMovesetConformance
        dexlist = searchStartingList

        commandAny = -1
        command4Tempo = -1
        commandMaxLevelUp = -1
        commandExcessiveLevel1s = -1
        commandAbove70 = -1
        commandNoEarlyStab = -1
        commandNoProgressStab = -1
        commandNoBBStab = -1
        commandDuplicateMoves = -1
        commands = [_INTL("Cancel")]
        commands[commandAny = commands.length] = _INTL("Any")
        commands[command4Tempo = commands.length] = _INTL("Non-4-Tempo")
        commands[commandMaxLevelUp = commands.length] = _INTL("Ends before value")
        commands[commandExcessiveLevel1s = commands.length] = _INTL("Too Many 1s")
        commands[commandAbove70 = commands.length] = _INTL("Above 70")
        commands[commandNoEarlyStab = commands.length] = _INTL("No Pre-16 Stab")
        commands[commandNoProgressStab = commands.length] = _INTL("No 16-31 Stab")
        commands[commandNoBBStab = commands.length] = _INTL("No 32-44 Stab")
        commands[commandDuplicateMoves = commands.length] = _INTL("Duplicate Moves")
        selection = pbMessage(_INTL("Which rulebreakers?"), commands, 3)
        unless selection == 0
            checkedMaxLevel = 70
            if commandMaxLevelUp > -1 && selection == commandMaxLevelUp
                levelTextInput = pbEnterText(_INTL("Pick final intended moveset level..."), 0, 3)
                if levelTextInput && levelTextInput != ""
                    checkedMaxLevel = levelTextInput.to_i
                    return nil if checkedMaxLevel == 0
                else
                    return nil
                end
            end

            dexlist = dexlist.find_all do |dex_item|
                lvlmoves = dex_item[:data].level_moves
                types = [dex_item[:data].type1, dex_item[:data].type2 || dex_item[:data].type1]
                types.uniq!
                types.compact!
                typeCount = types.length

                anyNon4s = false
                anyDuplicates = false
                countOf1s = 0
                maxLevel = 0
                earlyStabDebt = typeCount
                progressStabDebt = typeCount
                bbStabDebt = typeCount

                allMoves = []

                lvlmoves.each do |learnset_entry|
                    learnLevel = learnset_entry[0]
                    moveSym = learnset_entry[1]

                    maxLevel = learnLevel if learnLevel > maxLevel
                    if learnLevel == 1
                        countOf1s += 1
                    elsif learnLevel % 4 != 0
                        anyNon4s = true
                    end

                    if learnLevel != 0
                        if allMoves.include?(moveSym)
                            anyDuplicates = true
                        else
                            allMoves.push(moveSym)
                        end
                    end

                    moveData = GameData::Move.get(moveSym)
                    if types.include?(moveData.type) && moveData.category != 2 # Damaging move
                        if learnLevel < 16
                            earlyStabDebt -= 1
                        elsif learnLevel < 32
                            progressStabDebt -= 1
                        elsif learnLevel < 45
                            bbStabDebt -= 1
                        end
                    end
                end

                breaks4s = false
                next true if anyNon4s && (selection == command4Tempo || selection == commandAny)

                next true if maxLevel < checkedMaxLevel && (selection == commandMaxLevelUp || selection == commandAny)

                next true if countOf1s > 3 && (selection == commandExcessiveLevel1s || selection == commandAny)

                next true if maxLevel > 70 && (selection == commandAbove70 || selection == commandAny)

                next true if earlyStabDebt > 0 && (selection == commandNoEarlyStab || selection == commandAny)

                next true if progressStabDebt > 0 && (selection == commandNoProgressStab || selection == commandAny)

                next true if bbStabDebt > 0 && (selection == commandNoBBStab || selection == commandAny)

                if anyDuplicates && (selection = commandDuplicateMoves || selection == commandAny)
                    next true
                end

                next false
            end
            return dexlist
        end
        return nil
    end

    def searchByNoMonumentUses
        dexlist = searchStartingList
        dexlist = dexlist.find_all do |dex_item|
            monumentTrainerUseCount = @speciesUseData[entry[:species]][1]
            next monumentTrainerUseCount == 0
        end
        return dexlist
    end

    def searchByLegendary
        selection = pbMessage(_INTL("Which search?"), [_INTL("Legendary"), _INTL("Not Legendary"), _INTL("Cancel")], 3)
        if selection != 2
            dexlist = searchStartingList

            dexlist = dexlist.find_all do |dex_item|
                if selection == 1
                    next !dex_item[:data].isLegendary?
                else
                    next dex_item[:data].isLegendary?
                end
            end
            return dexlist
        end
        return nil
    end

    def searchByGeneration
        dexlist = searchStartingList

        generationNumber = 0
        while true
            generationNumberTextInput = pbEnterText(_INTL("Search generation number..."), 0, 20)
            return if generationNumberTextInput.blank?
            reversed = generationNumberTextInput[0] == "-"
            generationNumberTextInput = generationNumberTextInput[1..-1] if reversed

            generationNumber = generationNumberTextInput.to_i
            if generationNumber < 0
                pbMessage(_INTL("Negative generation numbers are invalid."))
            else
                break
            end
        end

        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])
            next (dex_item[:data].generation == generationNumber) ^ reversed # Boolean XOR
        end
        return dexlist
    end

    def invertSearchList
        dexlist = pbGetDexList
        dexlist = dexlist.find_all do |dex_item|
            next false if autoDisqualifyFromSearch(dex_item[:species])
            next !@dexlist.any? { |current_item| current_item[:species] == dex_item[:species] }
        end
        return dexlist
    end

    def searchByTypeMatchup
        sectionSelection = pbMessage(_INTL("Which interaction?"), [_INTL("Weak To"), _INTL("Resists"),_INTL("Immune To"), _INTL("Neutral To"), _INTL("Has Immunity"), _INTL("Has Hyper Weakness"), _INTL("Cancel"),], 7)
        return if sectionSelection == 6

        if sectionSelection <= 3
            return searchByTypeEffectiveness(sectionSelection)
        else
            dexlist = searchStartingList
            dexlist = dexlist.find_all do |dex_item|
                next false if autoDisqualifyFromSearch(dex_item[:species])

                hasThingOfInterest = false
                GameData::Type.each do |type|
                    next if type.pseudo_type

                    effectiveness = Effectiveness.calculate(type.id, [dex_item[:data].type1, dex_item[:data].type2])

                    if sectionSelection == 4 && Effectiveness.ineffective?(effectiveness)
                        hasThingOfInterest = true
                        break
                    end

                    if sectionSelection == 5 && Effectiveness.hyper_effective?(effectiveness)
                        hasThingOfInterest = true
                        break
                    end
                end

                next hasThingOfInterest
            end
            return dexlist
        end
    end

    def searchByTypeEffectiveness(effectivenessSelection)
        while true
            typesInput = pbEnterText(_INTL("Which type(s)?"), 0, 100)
            typesInput.downcase!
            if typesInput && typesInput != ""
                typesInputArray = typesInput.split(" ")

                # Don't do the search if one of the input type names isn't an actual type
                invalid = false
                typesSearchInfo = {}
                typesInputArray.each do |type_input_entry|
                    reversed = type_input_entry[0] == "-"
                    type_input_entry = type_input_entry[1..-1] if reversed
                    typeIsReal = false
                    type_symbol = nil
                    GameData::Type.each do |type_data|
                        next unless type_data.name.downcase == type_input_entry
                        typeIsReal = true
                        type_symbol = type_data.id
                        break
                    end
                    unless typeIsReal
                        pbMessage(_INTL("Invalid input: {1}", type_input_entry))
                        invalid = true
                        break
                    end
                    typesSearchInfo[type_symbol] = reversed
                end
                next if invalid

                dexlist = searchStartingList
                dexlist = dexlist.find_all do |dex_item|
                    next false if autoDisqualifyFromSearch(dex_item[:species])

                    survivesSearch = true
                    typesSearchInfo.each do |type, reversed|
                        effect = Effectiveness.calculate(type, [dex_item[:data].type1, dex_item[:data].type2])

                        case effectivenessSelection
                        when 0
                            survivesSearch = false if !Effectiveness.super_effective?(effect) ^ reversed
                        when 1
                            survivesSearch = false if !Effectiveness.not_very_effective?(effect) ^ reversed
                        when 2
                            survivesSearch = false if !Effectiveness.ineffective?(effect) ^ reversed
                        when 3
                            survivesSearch = false if !Effectiveness.normal?(effect) ^ reversed
                        end
                    end
                    next survivesSearch
                end
                return dexlist
            end
            return nil
        end
    end

    def sortByStat
        statSelection = pbMessage(_INTL("Which stat?"), [_INTL("HP"), _INTL("Attack"), _INTL("Defense"),
                                                  _INTL("Sp. Atk"), _INTL("Sp. Def"), _INTL("Speed"), _INTL("Total"), _INTL("Phys. EHP"), _INTL("Spec. EHP"), _INTL("Cancel"),], 10)
        return if statSelection == 9
        sortDirection = pbMessage(_INTL("Which direction?"), [_INTL("Descending"), _INTL("Ascending"), _INTL("Cancel")], 3)
        return if sortDirection == 2
        dexlist = @dexlist
        dexlist.sort_by! do |dex_item|
            value = 0
            case statSelection
            when 0
                value = dex_item[:data].base_stats[:HP]
            when 1
                value = dex_item[:data].base_stats[:ATTACK]
            when 2
                value = dex_item[:data].base_stats[:DEFENSE]
            when 3
                value = dex_item[:data].base_stats[:SPECIAL_ATTACK]
            when 4
                value = dex_item[:data].base_stats[:SPECIAL_DEFENSE]
            when 5
                value = dex_item[:data].base_stats[:SPEED]
            when 6
                dex_item[:data].base_stats.each do |s|
                    value += s[1]
                end
            when 7
                value = dex_item[:data].physical_ehp
            when 8
                value = dex_item[:data].special_ehp
            end

            value *= -1 if sortDirection == 0
            next value
        end

        return dexlist
    end

    def sortByOther
        cmdSortByType = -1
        cmdSortByGenderRate = -1
        cmdSortByHeight = -1
        cmdSortByWeight = -1
        cmdSortByCatchDifficulty = -1
        cmdSortByExperienceGrant = -1
        cmdSortByTrainerCount = -1
        cmdSortByNormalTrainerCount = -1
        cmdSortByMonumentTrainerCount = -1
        cmdSortByCoverageTypesCount = -1
        selections = []
        selections[cmdSortByType = selections.length] = _INTL("Type")
        selections[cmdSortByGenderRate = selections.length] = _INTL("Gender Rate")
        selections[cmdSortByHeight = selections.length] = _INTL("Height")
        selections[cmdSortByWeight = selections.length] = _INTL("Weight")
        selections[cmdSortByCatchDifficulty = selections.length] = _INTL("Catch Difficulty")
        selections[cmdSortByExperienceGrant = selections.length] = _INTL("Experience Grant")
        selections[cmdSortByTrainerCount = selections.length] = _INTL("Total Using (D)") if $DEBUG
        selections[cmdSortByNormalTrainerCount = selections.length] = _INTL("Normal Using (D)") if $DEBUG
        selections[cmdSortByMonumentTrainerCount = selections.length] = _INTL("Monument Using (D)") if $DEBUG
        selections[cmdSortByCoverageTypesCount = selections.length] = _INTL("Coverage Count (D)") if $DEBUG
        selections.push(_INTL("Cancel"))
        selection = pbMessage(_INTL("Sort by what?"), selections, selections.length + 1)
        return if selection >= selections.length - 1
        dexlist = @dexlist

        typesCount = 0
        GameData::Type.each { |t| typesCount += 1 if !t.pseudo_type }

        dexlist.sort_by! do |dex_item|
            speciesData = dex_item[:data]

            if cmdSortByType > -1 && selection == cmdSortByType
                types = [speciesData.type1, speciesData.type2]
                types.sort_by! do |type|
                    GameData::Type.get(type).id_number
                end
                value = 0
                types.each_with_index do |type, index|
                    value += GameData::Type.get(type).id_number * (typesCount**index)
                end

                next value
            elsif cmdSortByGenderRate > -1 && selection == cmdSortByGenderRate
                case speciesData.gender_ratio
                when :Genderless
                    next 300
                when :AlwaysMale
                    next 0
                when :AlwaysFemale
                    next 255
                end
                genderRatioData = GameData::GenderRatio.get(speciesData.gender_ratio)
                next genderRatioData.female_chance
            elsif cmdSortByHeight > -1 && selection == cmdSortByHeight
                next -speciesData.height
            elsif cmdSortByWeight > -1 && selection == cmdSortByWeight
                next -speciesData.weight
            elsif cmdSortByCatchDifficulty > -1 && selection == cmdSortByCatchDifficulty
                next -speciesData.catch_rate
            elsif cmdSortByExperienceGrant > -1 && selection == cmdSortByExperienceGrant
                next speciesData.base_exp
            elsif cmdSortByTrainerCount > -1 && selection == cmdSortByTrainerCount
                useCounts = @speciesUseData[dex_item[:species]]
                next (useCounts[0] + useCounts[1]) || 0
            elsif cmdSortByNormalTrainerCount > -1 && selection == cmdSortByNormalTrainerCount
                useCounts = @speciesUseData[dex_item[:species]]
                next useCounts[0]
            elsif cmdSortByMonumentTrainerCount > -1 && selection == cmdSortByMonumentTrainerCount
                useCounts = @speciesUseData[dex_item[:species]]
                next useCounts[1]
            elsif cmdSortByCoverageTypesCount > -1 && selection == cmdSortByCoverageTypesCount
                next get_bnb_coverage(speciesData).size
            end
        end
        return dexlist
    end
end
