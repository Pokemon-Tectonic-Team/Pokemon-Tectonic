def useOmniTutor()
    if !teamEditingAllowed?()
		showNoTeamEditingMessage()
		return
	end

    while true do
        pbChoosePokemon(1,3,proc{|p|
            p.can_omni_tutor?
        },false)
        if $game_variables[1] < 0
            break
        else
            omniTutorScreen(pbMapInterpreter.pbGetPokemon(1))
        end
    end
end

def getTMLearnableMoves
    moves = []
    $PokemonBag.pockets.each do |pocket|
        pocket.each do |itemEntry|
            itemID = itemEntry[0]
            itemData = GameData::Item.get(itemID)
            next unless itemData.is_machine?
            moves.push(itemData.move)
        end
    end

    moves.uniq!
    moves.compact!

    return moves
end

def getOmniMoves(pkmn)
    relearnableMoves = getRelearnableMoves(pkmn)
    mentorableMoves = getMentorableMoves(pkmn)
    tmLearnableMoves = getTMLearnableMoves

    omniMoves = [relearnableMoves, mentorableMoves, tmLearnableMoves].reduce([], :concat)
    omniMoves = omniMoves & pkmn.learnable_moves

    return omniMoves
end

def omniTutorScreen(pkmn)
    return moveLearningScreen(pkmn,getOmniMoves(pkmn),true)
end

class Pokemon
	def can_omni_tutor?
		return false if egg?
		return !getOmniMoves(self).empty?
	end
end