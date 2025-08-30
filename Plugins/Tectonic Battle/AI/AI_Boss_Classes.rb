##################################################
# Legendary Beasts
##################################################
class PokeBattle_AI_ENTEI < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:INCINERATE, {
            :condition => proc { |_move, _user, target, _battle|
                next target.hasAnyBerry? || target.hasAnyGem?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} notices a flammable item amongst your Pokémon!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_SUICUNE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:ASCRYSTAL, {
            :condition => proc { |_move, user, _target, _battle|
                next user.pbHasAnyStatus?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} inspects its status conditions.",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_RAIKOU < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:FROMTHEBLUE, {
            :condition => proc { |_move, user, _target, _battle|
                next user.steps[:SPEED] < 2
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} opens its mouth up wide!",user.pbThis)
            },
        })
    end
end

##################################################
# Swords of Justice
##################################################
class PokeBattle_AI_KELDEO < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        rejectPoisonMovesIfBelched
    end
end

class PokeBattle_AI_COBALION < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:ALLFORONE, {
            :condition => proc { |_move, user, _target, battle|
                next user.hasAlly?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} begins leading the attack!",user.pbThis)
            },
        })
        @dangerMoves.push(:ALLFORONE)
    end
end

class PokeBattle_AI_TERRAKION < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:LATCHON, {
            :condition => proc { |_move, _user, target, battle|
                next target.fullHealth?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} notices how healthy {2} is!",user.pbThis,targets[0].pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_VIRIZION < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:STRENGTHSAP, {
            :condition => proc { |_move, _user, target, battle|
                next user.firstTurnThisRound? && battle.turnCount % 2 == 1
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is jealous of {2}'s strength!",user.pbThis,targets[0].pbThis(true))
            },
        })

        @warnedIFFMove.add(:MINDSAP, {
            :condition => proc { |_move, _user, target, battle|
                next user.firstTurnThisRound? && battle.turnCount % 2 == 1
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is jealous of {2}'s mind!",user.pbThis,targets[0].pbThis(true))
            },
        })

        @scoreMove[:BLADESOFGRASS] = proc { |move, user, target, battle|
            next 200
        }
    end
end

##################################################
# Weather Trio
##################################################
class PokeBattle_AI_GROUDON < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @wholeRound += %i[ERUPTION PRECIPICEBLADES WARPINGCORE]

        @warnedIFFMove.add(:ERUPTION, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is gathering energy for a massive attack!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:PRECIPICEBLADES, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount % 3 == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is gathering energy for an attack!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:WARPINGCORE, {
            :condition => proc { |_move, user, _target, _battle|
                next true
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("You feel the ground begin to bend towards {1}.",user.pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_KYOGRE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @wholeRound += %i[WATERSPOUT ORIGINPULSE SEVENSEASEDICT]

        @warnedIFFMove.add(:WATERSPOUT, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is gathering energy for a massive attack!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:ORIGINPULSE, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount % 3 == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is gathering energy for an attack!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:SEVENSEASEDICT, {
            :condition => proc { |_move, _user, _target, battle|
                next true
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("An air of authority surrounds {1}.",user.pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_RAYQUAZA < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @wholeRound += %i[STRATOSPHERESCREAM]

        @warnedIFFMove.add(:DRAGONASCENT, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} looks to the Ozone Layer above!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:STRATOSPHERESCREAM, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount > 0 && battle.turnCount % 3 == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1}'s rage is at its peak!",user.pbThis)
            },
        })

        @requiredMoves.push(:FLING)
    end
end

##################################################
# Chamber Avatars
##################################################
class PokeBattle_AI_MELOETTA < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @useMoveIFF.add(:RELICSONG, proc { |_move, user, _target, battle|
            next battle.turnCount % 2 == 1 && user.lastTurnThisRound?
        })
        @rejectMovesIf.push( proc { |move, user, _target, battle|
            if user.form == 0
                next true if %i[DOUBLEHIT CAPOEIRA].include?(move.id)
            else
                next true if %i[PSYBEAM ROUND].include?(move.id)
            end
            next false
        }
        )
    end
end

class PokeBattle_AI_XERNEAS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @useMoveIFF.add(:GEOMANCY, proc { |_move, user, _target, battle|
            next user.hasActiveItem?(:POWERHERB) && user.lastTurnThisRound?
        })
    end
end

class PokeBattle_AI_DEOXYS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @beforePhaseChange.push(proc { |user, _battle|
            if user.avatarPhase == 0
                formChangeMessage = _INTL("The avatar of Deoxys turns to Attack Form!")
                user.pbChangeForm(1, formChangeMessage)
            elsif user.avatarPhase == 1
                formChangeMessage = _INTL("The avatar of Deoxys turns to Defense Form!")
                    user.pbChangeForm(2, formChangeMessage)
            end
        })
    end
end

##################################################
# Calyrex and Mounts
##################################################
def calyrexArrives(user, battle, version = 0)
    battle.pbDisplayBossNarration(_INTL("Except, what's this!?"))
    battle.pbDisplayBossNarration(_INTL("The Avatar of Calyrex has arrived to save its steed!"))
    
    newAvatar = generateAvatarPokemon(:CALYREX,70,version)
    
    sideIndex = user.index % 2
    partyIndex = battle.pbParty(sideIndex).length
    battle.pbParty(sideIndex)[partyIndex] = newAvatar
    user.pbInitPokemon(newAvatar, sideIndex)
    battle.scene.pbChangePokemon(user, newAvatar)
    battle.scene.reviveBattler(user.index)
    battle.remakeDataBoxes

    user.pbEffectsOnSwitchIn(true)
end

class PokeBattle_AI_GLASTRIER < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:STAMPDOWN, {
            :condition => proc { |_move, user, target, _battle|
                next target.hasRaisedStatSteps?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} reers up its hooves above {2}!",user.pbThis,targets[0].pbThis)
            },
        })
        @requiredMoves.push(:CHILL)

        @onDestroyed.push( proc { |user, battle|
            calyrexArrives(user, battle, 0) unless user.hasAlly?
        })
    end
end

class PokeBattle_AI_SPECTRIER < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @requiredMoves.push(:DISABLE)

        @onDestroyed.push( proc { |user, battle|
            calyrexArrives(user, battle, 1) unless user.hasAlly?
        })
    end
end

class PokeBattle_AI_CALYREX < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:STORMDRIVE, {
            :condition => proc { |_move, user, _target, battle|
                next battle.rainy?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} raises a hand towards the thunderclouds.",user.pbThis(true))
            },
        })
        secondMoveEveryOtherTurn(:WORKUP)
    end
end

class PokeBattle_AI_CALYREX_1 < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:SOLARBEAM, {
            :condition => proc { |_move, user, _target, battle|
                next battle.sunny?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} opens its bulb towards the shining sun.",user.pbThis(true))
            },
        })
        secondMoveEveryOtherTurn(:SLACKOFF)
    end
end

##################################################
# Other Legends
##################################################
class PokeBattle_AI_GENESECT < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:FELLSTINGER, {
            :condition => proc { |move, user, target, _battle|
                damageDealt = user.battle.battleAI.pbTotalDamageAI(move, user, target, 1)
                
                next damageDealt[0] >= target.hp
            },
            :warning => proc { |_move, user, targets, _battle|
                target = targets[0]
                _INTL("{1} aims its stinger at {2}!",user.pbThis,target.pbThis(true))
            },
        })

        @beginBattle.push(proc { |user, battle|
            battle.pbDisplayBossNarration(_INTL("The avatar of Genesect is analyzing your whole team for weaknesses..."))
            weakToElectric	= 0
            weakToFire	= 0
            weakToIce	= 0
            weakToWater	= 0
            maxValue = 0

            $Trainer.party.each do |b|
                next unless b
                type1 = b.type1
                type2 = b.type2
                weakToElectric += 1 if Effectiveness.super_effective?(Effectiveness.calculate(:ELECTRIC, [type1, type2]))
                maxValue = weakToElectric if weakToElectric > maxValue
                weakToFire += 1 if Effectiveness.super_effective?(Effectiveness.calculate(:FIRE, [type1, type2]))
                maxValue = weakToFire if weakToFire > maxValue
                weakToIce += 1 if Effectiveness.super_effective?(Effectiveness.calculate(:ICE, [type1, type2]))
                maxValue = weakToIce if weakToIce > maxValue
                weakToWater += 1 if Effectiveness.super_effective?(Effectiveness.calculate(:WATER, [type1, type2]))
                maxValue = weakToWater if weakToWater > maxValue
            end

            chosenItem = nil
            if maxValue > 0
                results = { SHOCKDRIVE: weakToElectric, BURNDRIVE: weakToFire, CHILLDRIVE: weakToIce,
DOUSEDRIVE: weakToWater, }
                results = results.sort_by { |_k, v| v }.to_h
                results.delete_if { |_k, v| v < maxValue }
                chosenItem = results.keys.sample
            end

            if !chosenItem
                battle.pbDisplayBossNarration(_INTL("{1} can't find any!",user.pbThis))
            else
                battle.pbDisplayBossNarration(_INTL("{1} loads a {2}!",user.pbThis,GameData::Item.get(chosenItem).real_name))
                user.giveItem(chosenItem)
            end
        })
    end
end

class PokeBattle_AI_CRESSELIA < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @beginTurn.push(proc { |user, battle, turnsunt|
            if turnCount == 4
                battle.pbDisplayBossNarration(_INTL("A Shadow creeps into the dream..."))
                battle.summonAvatarBattler(:DARKRAI, user.level)
            end
        })
    end
end

class PokeBattle_AI_DARKRAI < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:CALLOFTHEVOID, {
            :condition => proc { |_move, user, _target, battle|
                next battle.turnCount % 3 == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("The air around {1} turns dark and distorted.",user.pbThis(true))
            },
        })
        @requiredMoves.push(:LULLABY)
    end
end

##################################################
# Route Avatars
##################################################

class PokeBattle_AI_DONSTER < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        rejectPoisonMovesIfBelched
        secondMoveEveryTurn(:TRASHTREASURE)
    end
end

class PokeBattle_AI_DECEAT < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        prioritizeFling
    end
end

class PokeBattle_AI_GOURGEIST < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:TRICKORTREAT)
        secondMoveEveryTurn(:YAWN)
    end
end

class PokeBattle_AI_ZOROARK < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:VENOMDRENCH)
    end
end

class PokeBattle_AI_ELECTRODE < PokeBattle_AI_Boss
    TURNS_TO_EXPLODE = 3

    def initialize(user, battle)
        super
        @warnedIFFMove.add(:EXPLOSION, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount >= TURNS_TO_EXPLODE
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is fully charged. Its about to explode!",user.pbThis)
            },
        })

        @beginTurn.push(proc { |user, battle, _turnCount|
            turnsRemaining = TURNS_TO_EXPLODE - battle.turnCount
            if turnsRemaining > 0
                battle.pbDisplayBossNarration(_INTL("{1} is charging up.",user.pbThis))
                battle.pbDisplayBossNarration(_INTL("{1} turns remain!",turnsRemaining))
            end
        })

        @dangerMoves.push(:EXPLOSION)
        @wholeRound.push(:EXPLOSION)
    end
end

class PokeBattle_AI_LINOONE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:COVET, {
            :condition => proc { |_move, user, target, _battle|
                next target.hasAnyItem?
            },
            :warning => proc { |_move, user, targets, _battle|
                target = targets[0]
                _INTL("{1} eyes {2}'s {3} with jealousy!",user.pbThis,target.pbThis(true),target.itemCountD)
            },
        })
    end
end

class PokeBattle_AI_PARASECT < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:SPORE, {
            :condition => proc { |_move, user, _target, _battle|
                anyAsleep = false
                user.battle.battlers.each do |b|
                    next if !b || !user.opposes?(b)
                    anyAsleep = true if b.asleep?
                end
                next !anyAsleep
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1}'s shroom stalks perk up!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_PORYGONZ < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @firstTurnOnly += %i[CONVERSION CONVERSION2]
    end
end

class PokeBattle_AI_GREEDENT < PokeBattle_AI_Boss
    def useUniversalBehaviours?; return false; end

    def initialize(user, battle)
        super
        # Will only use Body Slam if no other moves are available
        @fallback.push(:BODYSLAM)
        @rejectedMoves.push(:BODYSLAM)

        @lastUsedStockpileMove = :SWALLOW
        @decidedOnMove[:SWALLOW] = proc { |_move, _user, _targets, _battle|
            @lastUsedStockpileMove = :SWALLOW
        }
        @decidedOnMove[:SPITUP] = proc { |_move, _user, _targets, _battle|
            @lastUsedStockpileMove = :SPITUP
        }

        @useMoveIFF.add(:SPITUP, proc { |_move, user, _target, _battle|
            next @lastUsedStockpileMove == :SWALLOW && user.firstTurnThisRound? &&
                user.countEffect(:Stockpile) >= 2 && user.empoweredTimer < 3
        })

        @useMoveIFF.add(:SWALLOW, proc { |_move, user, _target, _battle|
            next @lastUsedStockpileMove == :SPITUP && user.firstTurnThisRound? &&
                user.countEffect(:Stockpile) >= 2 && user.empoweredTimer < 3
        })

        @useMoveIFF.add(:STOCKPILE, proc { |_move, user, _target, _battle|
            next !user.effectAtMax?(:Stockpile)
        })
    end
end

class PokeBattle_AI_WAILORD < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:SELFDESTRUCT, {
            :condition => proc { |_move, _user, _target, _battle|
                next true
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is flying erratically. It looks unstable!",user.pbThis)
            },
        })

        @wholeRound.push(:SELFDESTRUCT)
        @dangerMoves.push(:SELFDESTRUCT)
    end
end

class PokeBattle_AI_SAWSBUCK < PokeBattle_AI_Boss
    FORM_0_MOVESET = %i[PLAYROUGH SEASONSEND]
    FORM_1_MOVESET = %i[WHIPKICK SEASONSEND]
    FORM_2_MOVESET = %i[TRAMPLE SEASONSEND]
    FORM_3_MOVESET = %i[GLACIALRAM SEASONSEND]
    MOVESETS = [FORM_0_MOVESET,FORM_1_MOVESET,FORM_2_MOVESET,FORM_3_MOVESET]

    def initialize(user, battle)
        super
        secondMoveEveryOtherTurn(:SEASONSEND)
        @beginTurn.push(proc { |user, _battle, turnCount|
            # Make sure it has the right moveset for its form
            newMoveset = MOVESETS[user.form].clone
            newMoveset.push(:PRIMEVALGROWL) if user.avatarPhase == 1
            user.assignMoveset(newMoveset)
        })
    end
end

class PokeBattle_AI_ROTOM < PokeBattle_AI_Boss
    FORM_1_MOVESET = %i[HEATWAVE DISCHARGE]
    FORM_2_MOVESET = %i[SURF DISCHARGE]
    FORM_3_MOVESET = %i[FROSTBREATH THUNDERBOLT]
    FORM_4_MOVESET = %i[AIRSLASH THUNDERBOLT]
    FORM_5_MOVESET = %i[PETALTEMPEST DISCHARGE]
    MOVESETS = [FORM_1_MOVESET,FORM_2_MOVESET,FORM_3_MOVESET,FORM_4_MOVESET,FORM_5_MOVESET]

    def initialize(user, battle)
        super
        @beginTurn.push(proc { |user, _battle, turnCount|
            if turnCount != 0 && turnCount % 2 == 1
                newForm = user.form + 1
                newForm = 1 if newForm > 5
                formChangeMessage = _INTL("The avatar swaps machines!")
                user.pbChangeForm(newForm, formChangeMessage)
                newMoveset = MOVESETS[newForm-1].clone
                newMoveset.push(:PRIMEVALDAZZLE) if user.avatarPhase == 1
                user.assignMoveset(newMoveset)
            end
        })
    end
end

class PokeBattle_AI_SUNFLORA < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryOtherTurn(:GROWTH)
        secondMoveEveryOtherTurn(:SUMMERDAZE)
    end
end

class PokeBattle_AI_HONCHKROW < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:SCHEME)
    end
end

class PokeBattle_AI_TOGEKISS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryOtherTurn(:TAKESHELTER)
    end
end

class PokeBattle_AI_CROBAT < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:ECHOLOCATE)
    end
end

class PokeBattle_AI_SLURPUFF < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:AROMATICMIST)
    end
end

class PokeBattle_AI_RUBARIOR < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:CURSE, {
            :condition => proc { |_move, user, target, _battle|
                next target.hasRaisedStatSteps?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is jealous of {2}'s good fortune!",user.pbThis, targets[0])
            },
        })
    end
end

class PokeBattle_AI_BOLDORE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:SUNSHINE, {
            :condition => proc { |_move, _user, _target, battle|
                next !battle.sunny?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} shuns the cave's darkness!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_MARACTUS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:SANDSTORM, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.pbWeather != :Sandstorm
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is feeling exposed!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_WATCHOG < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:GLARE)

        @warnedIFFMove.add(:FLATTER, {
            :condition => proc { |_move, _user, target, battle|
                next target.fullHealth?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is looking to butter up {2}!",user.pbThis,targets[0].pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_GRIMMSNARL < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:TEARFULLOOK)

        @warnedIFFMove.add(:BACKHAND, {
            :condition => proc { |_move, _user, target, battle|
                next target.fullHealth?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is studying {2}'s personality!",user.pbThis,targets[0].pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_SKARMORY < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:FEATHERWARD)

        @warnedIFFMove.add(:WHIRLWIND, {
            :condition => proc { |_move, user, target, battle|
                next target.aboveHalfHealth? && user.turnCount % 2 == 1
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1}'s wind whips in {2}'s direction!",user.pbThis,targets[0].pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_ARIADOS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:TOXICTHREAD)
    end
end

class PokeBattle_AI_ARCHEOPS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:METALSOUND)
    end
end

class PokeBattle_AI_STONJOURNER < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:PRANK)
    end
end

class PokeBattle_AI_GSTUNFISK < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:SHELLTER)
    end
end

class PokeBattle_AI_KLANG < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:METALSOUND)

        @useMovesIFF.push(proc { |move, user, battle|
            if move.type == :ELECTRIC
                if user.effectActive?(:EnergyCharge)
                    next 1
                else
                    next -1
                end
            end
        })

        @wholeRound.push(:DISCHARGE)
        @wholeRound.push(:VOLTTACKLE)
    end
end

class PokeBattle_AI_ABSOLUS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:NOBLEROAR)
    end
end

class PokeBattle_AI_ELDEGOSS < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @useMoveIFF.add(:BACKHAND, proc { |_move, user, target, _battle|
            next true if target.pbAttack(true) > target.pbDefense(true)
            next true if target.pbSpAtk(true) > target.pbSpDef(true)
            next false
        })
    end
end

class PokeBattle_AI_DUBWOOL < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @firstTurnOnly.push(:SKULLBASH)
    end
end

class PokeBattle_AI_CLAYDOL < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:REFLECT, {
            :condition => proc { |_move, user, _target, _battle|
                physicalAttacker = false
                user.lastFoeAttacker.each do |attacker|
                    next unless attacker.lastRoundMoveCategory == 0
                    physicalAttacker = true
                    break
                end
                next physicalAttacker
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is molding its clay for physical defense!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:LIGHTSCREEN, {
            :condition => proc { |_move, user, _target, _battle|
                physicalAttacker = false
                user.lastFoeAttacker.each do |attacker|
                    next unless attacker.lastRoundMoveCategory == 1
                    physicalAttacker = true
                    break
                end
                next physicalAttacker
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is molding its clay for special defense!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_SENSIBELLE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:HEALPULSE)
    end
end

class PokeBattle_AI_BRONZONG < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        
        @warnedIFFMove.add(:PACIFY, {
            :condition => proc { |_move, user, _target, _battle|
                next true
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} detects weakened mental defenses!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:CONFUSERAY, {
            :condition => proc { |_move, user, target, _battle|
                next !target.pbCanLowerStatStep?(:SPECIAL_DEFENSE,user)
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} aims to eliminate sound protection!",user.pbThis)
            },
        })

        @warnedIFFMove.add(:METALSOUND, {
            :condition => proc { |_move, user, target, _battle|
                next target.steps[:SPECIAL_DEFENSE] >= 0
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} positions itself to make a terrible noise!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_Mimikyu < PokeBattle_AI_Boss
    def initialize(user, battle)
        super

        @warnedIFFMove.add(:SPOOKYSNUGGLING, {
            :condition => proc { |_move, user, target, _battle|
                next target.hasHealingMove?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} wants a hug from someone healthy!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_REAVOR < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:BUGBITE, {
            :condition => proc { |_move, _user, target, _battle|
                next target.hasAnyBerry? || target.hasAnyGem?
            },
            :warning => proc { |_move, user, targets, _battle|
                target = targets[0]
                _INTL("{1} locks onto {2}'s item!",user.pbThis,target.pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_SUDOWOODO < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:BUGBITE, {
            :condition => proc { |_move, _user, target, _battle|
                next target.lastRoundMoveCategory == 2
            },
            :warning => proc { |_move, user, targets, _battle|
                target = targets[0]
                _INTL("{1} is a big fan of {2}'s last used move!",user.pbThis,target.pbThis(true))
            },
        })

        @warnedIFFMove.add(:STRENGTHSAP, {
            :condition => proc { |_move, _user, target, _battle|
                next target.steps[:ATTACK] > 1
            },
            :warning => proc { |_move, user, targets, _battle|
                target = targets[0]
                _INTL("{1} envies {2}'s Attack!",user.pbThis,target.pbThis(true))
            },
        })
    end
end

class PokeBattle_AI_SLOWKING < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:COSMICPOWER)
        secondMoveEveryTurn(:WORKUP)
    end
end

class PokeBattle_AI_MRMIME < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryOtherTurn(:ROLEPLAY)
    end
end

class PokeBattle_AI_MAGNEZONE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:MAGNETRISE, {
            :condition => proc { |_move, _user, target, battle|
                facingGroundType = false
                user.eachOpposing do |opp|
                    next unless opp.hasType?(:GROUND)
                    facingGroundType = true
                    break
                end
                next facingGroundType
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is wary of the ground!", user.pbThis)
            },
        })

        @requiredMoves.push(:REPULSIONFIELD)
    end
end

class PokeBattle_AI_DRIFBLIM < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:POISONGAS, {
            :condition => proc { |_move, _user, target, battle|
                next target.fullHealth?
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} gathers toxic gas!", user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_MAROMATISSE < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:PERISHSONG, {
            :condition => proc { |_move, user, target, _battle|
                next user.form == 0
            },
            :warning => proc { |_move, user, _targets, _battle|
                _INTL("{1} is warming up its haunting voice!", user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_GARDEVOIR < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:LIFEDEW)
    end
end

class PokeBattle_AI_DRUDDIGON < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @wholeRound.push(:OCCULTATION)

        @warnedIFFMove.add(:OCCULTATION, {
            :condition => proc { |_move, _user, _target, battle|
                next battle.turnCount % 2 == 0
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is haloed in Dragon Energy!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_BELLOSSOM < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @firstTurnOnly.push(:HELPINGHAND)
        @requiredMoves.push(:HELPINGHAND)
    end
end

class PokeBattle_AI_ASANDSLASH < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:INURE, {
            :condition => proc { |_move, _user, _target, battle|
                next true
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is getting used to the harsh conditions!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_TOXTRICITY < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        @warnedIFFMove.add(:WALLOFSOUND, {
            :condition => proc { |_move, _user, _target, battle|
                next true
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} is gearing up for a big release!",user.pbThis)
            },
        })
    end
end

class PokeBattle_AI_SIGILYPH < PokeBattle_AI_Boss
    def initialize(user, battle)
        super
        secondMoveEveryTurn(:DISCOURAGE)
        everyThreeTurns(:EMPOWEREDFUTURESIGHT)

        @warnedIFFMove.add(:POLARIZEDROOM, {
            :condition => proc { |_move, _user, _target, battle|
                next !battle.roomActive?
            },
            :warning => proc { |_move, user, targets, _battle|
                _INTL("{1} yearns for a high-quality room!",user.pbThis)
            },
        })
    end
end