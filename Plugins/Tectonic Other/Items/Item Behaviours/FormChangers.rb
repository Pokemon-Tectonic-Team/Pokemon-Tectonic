ItemHandlers::UseOnPokemon.add(:GRACIDEA,proc { |item,pkmn,scene|
    unless pkmn.isSpecies?(:SHAYMIN)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Shaymin."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    formToSet = pkmn.form == 0 ? 1 : 0
    pkmn.setForm(formToSet) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:REVEALGLASS,proc { |item,pkmn,scene|
    if !pkmn.isSpecies?(:TORNADUS) &&
        !pkmn.isSpecies?(:THUNDURUS) &&
        !pkmn.isSpecies?(:LANDORUS) &&
        !pkmn.isSpecies?(:ENAMORUS)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Tornadus, Thundurus, Landorus, or Enamorus."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    newForm = (pkmn.form==0) ? 1 : 0
    pkmn.setForm(newForm) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:PRISONBOTTLE,proc { |item,pkmn,scene|
    if !pkmn.isSpecies?(:HOOPA)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Hoopa."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
    end
    newForm = (pkmn.form==0) ? 1 : 0
    pkmn.setForm(newForm) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:DNASPLICERS,proc { |item,pkmn,scene|
    unless scene&.supportsFusion?
        pbSceneDefaultDisplay(_INTL("You cannot use this item in this menu."),scene)
        next false
    end
    if !pkmn.isSpecies?(:KYUREM)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Kyurem."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    # Fusing
    if pkmn.fused.nil?
        chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
        next false if chosen<0
        poke2 = $Trainer.party[chosen]
        if pkmn==poke2
            pbSceneDefaultDisplay(_INTL("It cannot be fused with itself."),scene)
            next false
        elsif poke2.egg?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with an Egg."),scene)
            next false
        elsif poke2.fainted?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that fainted Pokémon."),scene)
            next false
        elsif !poke2.isSpecies?(:RESHIRAM) &&
                !poke2.isSpecies?(:ZEKROM)
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that Pokémon."),scene)
            next false
        end
        newForm = 0
        newForm = 1 if poke2.isSpecies?(:RESHIRAM)
        newForm = 2 if poke2.isSpecies?(:ZEKROM)
        pkmn.setForm(newForm) {
            pkmn.fused = poke2
            $Trainer.remove_pokemon_at_index(chosen)
            scene&.pbHardRefresh
            pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
        }
        next true
    end
    # Unfusing
    if $Trainer.party_full?
        pbSceneDefaultDisplay(_INTL("You have no room to separate the Pokémon."),scene)
        next false
    end
    pkmn.setForm(0) {
        $Trainer.party[$Trainer.party.length] = pkmn.fused
        pkmn.fused = nil
        scene&.pbHardRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:NSOLARIZER,proc { |item,pkmn,scene|
    unless scene&.supportsFusion?
        pbSceneDefaultDisplay(_INTL("You cannot use this item in this menu."),scene)
        next false
    end
    if !pkmn.isSpecies?(:NECROZMA) || pkmn.form == 2
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Necrozma."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    # Fusing
    if pkmn.fused.nil?
        chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
        next false if chosen<0
        poke2 = $Trainer.party[chosen]
        if pkmn==poke2
            pbSceneDefaultDisplay(_INTL("It cannot be fused with itself."),scene)
            next false
        elsif poke2.egg?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with an Egg."),scene)
            next false
        elsif poke2.fainted?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that fainted Pokémon."),scene)
            next false
        elsif !poke2.isSpecies?(:SOLGALEO)
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that Pokémon."),scene)
            next false
        end
        pkmn.setForm(1) {
            pkmn.fused = poke2
            $Trainer.remove_pokemon_at_index(chosen)
            scene&.pbHardRefresh
            pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
        }
        next true
    end
    # Unfusing
    if $Trainer.party_full?
        pbSceneDefaultDisplay(_INTL("You have no room to separate the Pokémon."),scene)
        next false
    end
    pkmn.setForm(0) {
        $Trainer.party[$Trainer.party.length] = pkmn.fused
        pkmn.fused = nil
        scene&.pbHardRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:NLUNARIZER,proc { |item,pkmn,scene|
    unless scene&.supportsFusion?
        pbSceneDefaultDisplay(_INTL("You cannot use this item in this menu."))
        next false
    end
    if !pkmn.isSpecies?(:NECROZMA) || pkmn.form == 1
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Necrozma."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    # Fusing
    if pkmn.fused.nil?
        chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
        next false if chosen<0
        poke2 = $Trainer.party[chosen]
        if pkmn==poke2
            pbSceneDefaultDisplay(_INTL("It cannot be fused with itself."),scene)
            next false
        elsif poke2.egg?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with an Egg."),scene)
            next false
        elsif poke2.fainted?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that fainted Pokémon."),scene)
            next false
        elsif !poke2.isSpecies?(:LUNALA)
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that Pokémon."),scene)
            next false
        end
        pkmn.setForm(2) {
            pkmn.fused = poke2
            $Trainer.remove_pokemon_at_index(chosen)
            scene&.pbHardRefresh
            pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
        }
        next true
    end
    # Unfusing
    if $Trainer.party_full?
        pbSceneDefaultDisplay(_INTL("You have no room to separate the Pokémon."),scene)
        next false
    end
    pkmn.setForm(0) {
        $Trainer.party[$Trainer.party.length] = pkmn.fused
        pkmn.fused = nil
        scene&.pbHardRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:REINSOFUNITY, proc { |item, pkmn, scene|
    unless scene&.supportsFusion?
        pbSceneDefaultDisplay(_INTL("You cannot use this item in this menu."),scene)
        next false
    end

    unless pkmn.isSpecies?(:CALYREX)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Calyrex."),scene)
        next false
    end

    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end

    # Fusing
    if pkmn.fused.nil?
        chosen = scene.pbChoosePokemon(_INTL("Fuse with which Pokémon?"))
        next false if chosen < 0
        other_pkmn = $Trainer.party[chosen]
        if pkmn == other_pkmn
            pbSceneDefaultDisplay(_INTL("It cannot be fused with itself."),scene)
            next false
        elsif other_pkmn.egg?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with an Egg."),scene)
            next false
        elsif other_pkmn.fainted?
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that fainted Pokémon."),scene)
            next false
        elsif !other_pkmn.isSpecies?(:GLASTRIER) &&
                !other_pkmn.isSpecies?(:SPECTRIER)
            pbSceneDefaultDisplay(_INTL("It cannot be fused with that Pokémon."),scene)
            next false
        end
        newForm = 0
        newForm = 1 if other_pkmn.isSpecies?(:GLASTRIER)
        newForm = 2 if other_pkmn.isSpecies?(:SPECTRIER)
        pkmn.setForm(newForm) {
            pkmn.fused = other_pkmn
            $Trainer.remove_pokemon_at_index(chosen)
            scene.pbHardRefresh
            pbSceneDefaultDisplay(_INTL("{1} changed Forme!", pkmn.name),scene)
        }
        next true
    end

    # unfusing

    if $Trainer.party_full?
        pbSceneDefaultDisplay(_INTL("You have no room to separate the Pokémon."))
        next false
    end

    # Unfusing
    pkmn.setForm(0) {
        $Trainer.party[$Trainer.party.length] = pkmn.fused
        pkmn.fused = nil
        scene.pbHardRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!", pkmn.name))
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:GRISEOUSCORE,proc { |item,pkmn,scene|
    unless pkmn.isSpecies?(:GIRATINA)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Giratina."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    formToSet = pkmn.form == 0 ? 1 : 0
    pkmn.setForm(formToSet) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:LUSTROUSGLOBE,proc { |item,pkmn,scene|
    unless pkmn.isSpecies?(:PALKIA)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Palkia."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    formToSet = pkmn.form == 0 ? 1 : 0
    pkmn.setForm(formToSet) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})

ItemHandlers::UseOnPokemon.add(:ADAMANTCRYSTAL,proc { |item,pkmn,scene|
    unless pkmn.isSpecies?(:DIALGA)
        pbSceneDefaultDisplay(_INTL("It has no effect on Pokémon other than Dialga."),scene)
        next false
    end
    if pkmn.fainted?
        pbSceneDefaultDisplay(_INTL("This can't be used on the fainted Pokémon."),scene)
        next false
    end
    formToSet = pkmn.form == 0 ? 1 : 0
    pkmn.setForm(formToSet) {
        scene&.pbRefresh
        pbSceneDefaultDisplay(_INTL("{1} changed Forme!",pkmn.name),scene)
    }
    next true
})