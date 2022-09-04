FIFTY_PERCENT_MOVESET = [:LANDSWRATH,:FLASHCANNON]
ONE_HUNDRED_PERCENT_MOVESET = [:THOUSANDARROWS,:THOUSANDWAVES,:COREENFORCER]

PokeBattle_AI::BossBeginTurn.add(:ZYGARDE,
	proc { |species,battler|
		battle = battler.battle
		turnCount = battle.turnCount

    turnCount = battler.battle.turnCount
    if turnCount != 0 && turnCount <= 9
        battle.pbDisplay(_INTL("{1} gathers a cell!",battler.pbThis))
        percentStrength = (1 + turnCount) * 10 
        battle.pbDisplay(_INTL("{1} is now at at {2} percent cell strength!",battler.pbThis,percentStrength.to_s))

        if percentStrength == 50
            formChangeMessage = _INTL("{1} transforms into its 50 percent form!",battler.pbThis)
            battler.pbChangeFormBoss(0,formChangeMessage)
            battler.ability = :AURABREAK
            battler.assignMoveset(FIFTY_PERCENT_MOVESET)
        elsif percentStrength == 100
            formChangeMessage = _INTL("{1} transforms into its 100 percent form!",battler.pbThis)
            battler.pbChangeFormBoss(2,formChangeMessage)
            battler.ability = :AURABREAK
            battle.pbDisplay(_INTL("{1} completely regenerates!",battler.pbThis))
            battler.pbRecoverHP(battler.totalhp - battler.hp)
            battler.assignMoveset(ONE_HUNDRED_PERCENT_MOVESET)
        end
    else
      battle.pbDisplay(_INTL("{1} is at 10 percent cell strength!",battler.pbThis))
    end
	}
)

PokeBattle_AI::BossSpeciesUseMoveIDIfAndOnlyIf.add([:ZYGARDE,:INFERNOCHARGE],
  proc { |speciesAndMove,user,target,move|
	next user.battle.commandPhasesThisRound == 0
  }
)

PokeBattle_AI::BossSpeciesUseMoveIDIfAndOnlyIf.add([:ZYGARDE,:RECOVER],
	 proc { |speciesAndMove,user,target,move|
	next user.lastMoveThisTurn?
  }
)