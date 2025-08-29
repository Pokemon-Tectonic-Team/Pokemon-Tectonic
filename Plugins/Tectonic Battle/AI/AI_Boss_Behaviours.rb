class PokeBattle_AI_Boss
    def setUniversalBehaviours
        spaceOutProtecting
        rejectExtraSetUp
    end

    def rejectPoisonMovesIfBelched
        @rejectMovesIf.push(proc { |move, user, _battle|
            next true if user.belched? && move.type == :POISON && move.id != :BELCH
        })
    end

    def prioritizeFling
        @requiredMoves.push(:FLING)
    end

    def spaceOutProtecting
        @useMovesIFF.push(proc { |move, user, battle|
            if move.is_a?(PokeBattle_ProtectMove)
                if battle.turnCount % 3 == 0 && user.firstTurnThisRound?
                    next 1
                else
                    next -1
                end
            end
        })
    end

    def rejectExtraSetUp
        @rejectMovesIf.push(proc { |move, user, _battle|
            next false if move.statUp.empty?
            next false if move.damagingMove?(true)
            anyPositive = false
            for i in 0...move.statUp.length / 2
                statSym = move.statUp[i * 2]
                anyPositive = true if user.steps[statSym].positive?
            end
            next true if anyPositive
        })
    end

    def scoreSetUp
        @scoreMoves.push(proc { |move, user, target, _battle|
            next nil if move.statUp.empty?
            next 50
        })
    end

    # Have the avatar use the move as its 2nd move every turn if possible
    # And otherwise never
    def secondMoveEveryTurn(moveID)
        @useMoveIFF.add(moveID, proc { |_move, user, _target, _battle|
            next !user.firstTurnThisRound?
        })
    end

    # Have the avatar use the move every other turn if possible
    # and otherwise never
    def everyOtherTurn(moveID)
        @useMoveIFF.add(moveID, proc { |_move, user, _target, battle|
            next battle.turnCount % 2 == 1
        })
    end

    # Have the avatar use the move as its 1st move every turn if possible
    # And otherwise never
    def firstMoveEveryOtherTurn(moveID)
        @useMoveIFF.add(moveID, proc { |_move, user, _target, battle|
            next user.firstTurnThisRound? && battle.turnCount % 2 == 1
        })
    end

    # Have the avatar use the move as its 2nd move every other turn if possible
    # And otherwise never
    def secondMoveEveryOtherTurn(moveID)
        @useMoveIFF.add(moveID, proc { |_move, user, _target, battle|
            next !user.firstTurnThisRound? && battle.turnCount % 2 == 1
        })
    end

    # Have the avatar use the move every three turns if possible
    # and otherwise never
    def everyThreeTurns(moveID)
        @useMoveIFF.add(moveID, proc { |_move, user, _target, battle|
            next battle.turnCount % 3 == 1
        })
    end
end