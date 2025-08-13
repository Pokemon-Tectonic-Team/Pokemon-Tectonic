ItemHandlers::UseOnPokemon.add(:UNIVERSALFORMALIZER,proc { |item,pkmn,scene|
	species = pkmn.species
	species_data = GameData::Species.get_species_form(species,0) # get base form for the formalizer list
	valid_forms = species_data.formalizer.clone
	valid_forms.delete(pkmn.form)
	if valid_forms.length > 0
		possibleForms = valid_forms
		possibleFormNames = valid_forms.map { |form|
			form_data = GameData::Species.get_species_form(species,form)
			next form_data.form_name
		}
		possibleFormNames.push(_INTL("Cancel"))
		choice = pbMessage(_INTL("Which form shall the Pokemon take?"),possibleFormNames,possibleFormNames.length)
		if choice < possibleForms.length
			pbSceneDefaultDisplay(_INTL("{1} swapped to {2}!", pkmn.name, possibleFormNames[choice]),scene)
			
			showPokemonChanges(pkmn) {
				pkmn.form = possibleForms[choice]
			}
		end
		next true
	else
		pbSceneDefaultDisplay(_INTL("Cannot use this item on that Pokemon."),scene)
		next false
	end
})


def getFormSelectionChoices(species,currentForm=0)
	possibleForms = []
	possibleFormNames = []
	GameData::Species.each do |species_data|
		next unless species_data.species == species
		next if species_data.form == currentForm
		possibleForms.push(species_data)
		possibleFormNames.push(species_data.form_name)
	end
	possibleFormNames.push(_INTL("Cancel"))
	return possibleForms, possibleFormNames
end

ItemHandlers::UseOnPokemon.add(:ZYGARDECUBE,proc { |item,pkmn,scene|
	if pkmn.species == :ZYGARDE
		pkmn.form = pkmn.form == 0 ? 3 : 0
		scene&.pbRefresh
		pbSceneDefaultDisplay(_INTL("{1}'s Ability changed to {2}!",pkmn.name,GameData::Ability.get(pkmn.ability).name),scene)
		next true
	else
		pbSceneDefaultDisplay(_INTL("Cannot use this item on that Pokemon."),scene)
		next false
	end
})