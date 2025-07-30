#===============================================================================
# Uses a random move the user knows. Fails if user is not asleep. (Sleep Talk)
#===============================================================================
class PokeBattle_Move_UseRandomUserMoveIfAsleep < PokeBattle_Move
    def usableWhenAsleep?; return true; end
    def callsAnotherMove?; return true; end

    def getSleepTalkMoves(user)
        sleepTalkMoves = []
        user.eachMoveWithIndex do |m, i|
            next unless @battle.canInvokeMove?(m)
            next unless @battle.pbCanChooseMove?(user.index, i, false, true)
            sleepTalkMoves.push(i)
        end
        return sleepTalkMoves
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.asleep?
            @battle.pbDisplay(_INTL("But it failed, since {1} isn't asleep!", user.pbThis(true))) if show_message
            return true
        end
        if getSleepTalkMoves(user).length == 0
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since none of {1}'s moves can be used from Sleep Talk!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        choice = getSleepTalkMoves(user).sample
        user.pbUseMoveSimple(user.getMoves[choice].id, user.pbDirectOpposing.index)
    end

    def getEffectScore(user, _target)
        return randomMovesEffectScore(user, self)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Can't call focusing moves, moves that call other moves, " +
        "Two Turn moves, Mimic, or Sketch.")
    end
end

#===============================================================================
# Uses a random move known by any non-user Pokémon in the user's party. (Assist)
#===============================================================================
class PokeBattle_Move_UseRandomMoveFromUserParty < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def getAssistMoves(user)
        assistMoves = []
        @battle.pbParty(user.index).each_with_index do |pkmn, i|
            next if !pkmn || i == user.pokemonIndex
            next if pkmn.egg?
            pkmn.moves.each do |move|
                next unless @battle.canInvokeMove?(move)
                assistMoves.push(move.id)
            end
        end
        return assistMoves
    end

    def pbMoveFailed?(user, _targets, show_message)
        if getAssistMoves(user).length == 0
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since there are no moves {1} can use!", user.pbThis(true)))
            end
            return true
        end
        
        return false
    end

    def pbEffectGeneral(user)
        move = getAssistMoves(user).sample
        user.pbUseMoveSimple(move)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Can't call moves that alter the moveset, moves that counter, moves that " +
            "redirect or steal moves, moves that steal items, Focusing moves, moves that force switches, " +
            "two turn moves, Protect moves, Helping Hand moves, moves that call other moves, or Destiny Bond.")
    end
end

#===============================================================================
# Uses a random move that exists. (Metronome)
#===============================================================================
class PokeBattle_Move_UseRandomNonSignatureMove < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def initialize(battle, move)
        super
        @metronomeMoves = []
        GameData::Move::DATA.keys.each do |move_id|
            move_data = GameData::Move.get(move_id)
            next unless move_data.learnable?
            next if move_data.uninvocable?
            next if move_data.is_signature?
            next if move_data.empoweredMove?
            if battle
                next unless battle.canInvokeMove?(move_id)
            else
                next if move_data.uninvocable?
            end
            @metronomeMoves.push(move_data.id)
        end
    end

    def pbMoveFailed?(_user, _targets, show_message)
        if @metronomeMoves.empty?
            @battle.pbDisplay(_INTL("But it failed, since there are no moves to use!")) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        choice = @metronomeMoves.sample
        user.pbUseMoveSimple(choice)
    end

    def getEffectScore(user, _target)
        return randomMovesEffectScore(user, self)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Can't call moves that affect the moveset, moves that redirect or steal moves, " +
            "moves that steal items, Recharge moves, moves that counter, Focus moves, " +
            "Protect moves, Helping Hand moves, Snore, After You, or Quash.")
    end
end

#===============================================================================
# The user is given the choice of using one of 3 randomly chosen status moves. (Discovered Power)
#===============================================================================
class PokeBattle_Move_UseChoiceOf3RandomNonSignatureStatusMoves < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def initialize(battle, move)
        super
        @discoverableMoves = []
        GameData::Move::DATA.keys.each do |move_id|
            move_data = GameData::Move.get(move_id)
            next unless move_data.category == 2 # Status moves only
            next if move_data.function_code == "Invalid"
            next if move_data.is_signature?
            next unless move_data.learnable?
            if battle
                next unless battle.canInvokeMove?(move_id)
            else
                next if move_data.uninvocable?
            end
            @discoverableMoves.push(move_data.id)
        end
    end

    def resolutionChoice(user)
        validMoves = []
        validMoveNames = []
        until validMoves.length == 3
            movePossibility = @discoverableMoves.sample
            unless validMoves.include?(movePossibility)
                validMoves.push(movePossibility)
                validMoveNames.push(getMoveName(movePossibility))
            end
        end

        if @battle.autoTesting
            @chosenMove = validMoves.sample
        elsif !user.pbOwnedByPlayer? # Trainer AI
            @chosenMove = validMoves[0]
        else
            chosenIndex = @battle.scene.pbShowCommands(_INTL("Which move should {1} use?", user.pbThis(true)),validMoveNames,0)
            @chosenMove = validMoves[chosenIndex]
        end
    end

    def pbEffectGeneral(user)
        user.pbUseMoveSimple(@chosenMove) if @chosenMove
    end

    def resetMoveUsageState
        @chosenMove = nil
    end

    def getEffectScore(user, _target)
        return randomMovesEffectScore(user, self)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Can't call Signature moves, moves that affect the moveset, " + 
            "Recharge moves, moves that counter, Focus moves, Protect moves, Helping Hand moves, " +
            "or moves that call another move.")
    end
end

#===============================================================================
# Uses a random special Dragon-themed move, then a random physical Dragon-themed move. (Dragon Invocation)
#===============================================================================
class PokeBattle_Move_UseTwoRandomDragonThemedMoves < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def initialize(battle, move)
        super
        @invocationMovesPhysical = [
            :DRAGONCLAW,
            :DRAGONCLAW,
            :CRUNCH,
            :EARTHQUAKE,
            :DUALWINGBEAT,
        ]

        @invocationMovesSpecial = [
            :DRAGONBREATH,
            :DRAGONBREATH,
            :FLAMETHROWER,
            :MIASMA,
            :FROSTBREATH,
        ]
    end

    def pbEffectGeneral(user)
        user.pbUseMoveSimple(@invocationMovesSpecial.sample)
        user.pbUseMoveSimple(@invocationMovesPhysical.sample)
    end

    def getEffectScore(user, _target)
        return randomMovesEffectScore(user, self)
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Physical moves that can be called:")
        @invocationMovesPhysical.uniq.each do |moveID|
            detailsList << GameData::Move.get(moveID).name
        end

        detailsList << _INTL("Special moves that can be called:")
        @invocationMovesSpecial.uniq.each do |moveID|
            detailsList << GameData::Move.get(moveID).name
        end
    end
end

#===============================================================================
# The user is given the choice of using one of 3 randomly chosen moves (Selective Memory)
# in a predetermined list of non-Psychic attacks.
#===============================================================================
class PokeBattle_Move_UseChoiceOf3RandomNonSignatureNonPsychicDamagingMoves < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def initialize(battle, move)
        super
        @selectableMoves = %i[
            HYPERVOICE
            FLAMETHROWER
            BUBBLEBLASTER
            ENERGYBALL
            THUNDERBOLT
            ICEBEAM
            AURASPHERE
            MIASMA
            EARTHPOWER
            COLDFRONT
            BUGBUZZ
            POWERGEM
            SHADOWBALL
            DRAGONPULSE
            DARKALLURE
            FLASHCANNON
            MOONBLAST
            CLEARSMOG
            HEX
            SHORTCIRCUIT
            CHARGEBEAM
            BLUSTER
            BLOSSOM
            HYPERBEAM
        ]
    end

    def resolutionChoice(user)
        validMoves = []
        validMoveNames = []
        until validMoves.length == 3
            movePossibility = @selectableMoves.sample
            unless validMoves.include?(movePossibility)
                validMoves.push(movePossibility)
                validMoveNames.push(getMoveName(movePossibility))
            end
        end

        if @battle.autoTesting
            @chosenMove = validMoves.sample
        elsif !user.pbOwnedByPlayer? # Trainer AI
            @chosenMove = validMoves[0]
        else
            chosenIndex = @battle.scene.pbShowCommands(_INTL("Which move should {1} use?", user.pbThis(true)),validMoveNames,0)
            @chosenMove = validMoves[chosenIndex]
        end
    end

    def pbEffectGeneral(user)
        user.pbUseMoveSimple(@chosenMove) if @chosenMove
    end

    def resetMoveUsageState
        @chosenMove = nil
    end

    def getEffectScore(user, _target)
        return randomMovesEffectScore(user, self)
    end
    
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Moves that can be rolled:")
        @selectableMoves.each do |moveID|
            detailsList << GameData::Move.get(moveID).name
        end
    end
end
