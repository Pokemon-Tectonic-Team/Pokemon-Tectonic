# SaveData.register_conversion(:fix_pokemon_illegalities) do
#     game_version Settings::GAME_VERSION
#     display_title 'Finding and fixing illegal elements on all owned Pokemon.'
#     to_all do |save_data|
#       removeIllegalElementsFromAllPokemon(save_data)
#     end
# end

def skipLegalityMessages?
  return $DEBUG
end

  def moveLegalOnPokemon?(moveID, pokemon, location = nil)
    moveData = GameData::Move.get(moveID)
    name = pokemon.name
    name = "#{name} (#{pokemon.species_data.name})" if pokemon.nicknamed?
    if pokemon.species == :SMEARGLE
        if moveData.cut
            pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has move {3} in its move list. That move has been cut from the game or is not legal to learn. Removing now.", name, location, moveData.name)) if location && !skipLegalityMessages?
            return false
        end
    else
        if !moveData.learnable?
            pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has move {3} in its move list. That move has been cut from the game or is not legal to learn. Removing now.", name, location, moveData.name)) if location && !skipLegalityMessages?
            return false
        end
      
        if !pokemon.learnable_moves(false).include?(moveID)
            pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has move {3} in its move list. That move is not legal for its species. Removing now.", name, location, moveData.name)) if location && !skipLegalityMessages?
            return false
        end
    end
    return true
  end

  def removeIllegalElementsFromAllPokemon(save_data)
    anyPokemonChanged = false
    eachPokemonInSave(save_data) do |pokemon, location|  
      name = pokemon.name
      name = "#{name} (#{pokemon.species_data.name})" if pokemon.nicknamed?
  
      # Find and remove illegal moves from movesets
      movesToRemoveFromMoveset = []
      pokemon.moves.each do |move|
        next if move.nil?
        moveID = move.id
        next if moveLegalOnPokemon?(moveID,pokemon,location)
        movesToRemoveFromMoveset.push(moveID)
      end
      movesToRemoveFromMoveset.each do |moveID|
        pokemon.forget_move(moveID)
        anyPokemonChanged = true
      end

      # Find and remove illegal moves from the "first moves" list
      movesToRemoveFromFirst = []
      pokemon.first_moves.each do |moveID|
        next if moveID.nil?
        next if moveLegalOnPokemon?(moveID,pokemon)
        movesToRemoveFromFirst.push(moveID)
      end
      movesToRemoveFromFirst.each do |moveID|
        pokemon.remove_first_move(moveID)
        anyPokemonChanged = true
      end
  
      # Find and fix illegal abilities
      unless pokemon.species_data.legalAbilities.include?(pokemon.ability_id)
        if pokemon.ability.nil?
          pokemon.recalculateAbilityFromIndex
          newAbilityName = pokemon.ability.name
          pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has no ability. Switching to {3}.", name, location, newAbilityName)) unless skipLegalityMessages?
        else
          oldAbilityName = pokemon.ability.name
          pokemon.recalculateAbilityFromIndex
          newAbilityName = pokemon.ability.name
          pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has ability {3}. That ability is not legal for its species. Switching to {4}.", name, location, oldAbilityName, newAbilityName)) unless skipLegalityMessages?
        end
        anyPokemonChanged = true
      end
  
      # Check and remove illegal items
      pokemon.items.clone.each do |item|
        itemData = GameData::Item.get(item)
        next if itemData.legal?
        pbMessage(_INTL("\\l[4]Pokemon {1} in {2} has item {3}. That item has been cut from the game or is not legal to own. Removing now.", name, location, itemData.name)) unless skipLegalityMessages?
        pokemon.removeItem(item)
        anyPokemonChanged = true
      end
      
      # Check and swap illegal balls
      ball = GameData::Item.get(pokemon.poke_ball)
      if !ball.legal?
        pbMessage(_INTL("\\l[4]Pokemon {1} in {2} is in a {3}. That ball has been cut from the game or is not legal to own. Swapping now.", name, location, ball.name)) unless skipLegalityMessages?
        pokemon.poke_ball = :POKEBALL
        anyPokemonChanged = true
      end
      
    end
    return anyPokemonChanged
  rescue StandardError
    pbMessage(_INTL("An error occured while checking for the legality of your party."))
    pbPrintException($!)
    return false
  end
  