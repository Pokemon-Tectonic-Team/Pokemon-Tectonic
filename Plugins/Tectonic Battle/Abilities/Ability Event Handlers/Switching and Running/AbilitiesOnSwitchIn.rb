#######################################################
# Weather setting abilities
#######################################################

BattleHandlers::AbilityOnSwitchIn.add(:DRIZZLE,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Rainstorm, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DROUGHT,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Sunshine, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SANDSTREAM,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Sandstorm, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SNOWWARNING,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Hail, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HARBINGER,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Eclipse, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MOONGAZE,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :Moonglow, battler, battle, false, true, aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:PRIMORDIALSEA,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :HeavyRain, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DESOLATELAND,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :HarshSun, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DELTASTREAM,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :StrongWinds, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SATURNALSKY,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :RingEclipse, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:STYGIANNIGHT,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :BloodMoon, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EVENTHORIZON,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :StarStorm, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HEATDEATH,
  proc { |ability, battler, battle, aiCheck|
      pbBattleWeatherAbility(ability, :IceAge, battler, battle, true, true, aiCheck, baseDuration: -1)
  }
)

#######################################################
# Entry debuff abilities
#######################################################
BattleHandlers::AbilityOnSwitchIn.add(:INTIMIDATE,
  proc { |ability, battler, battle, aiCheck|
      next entryDebuffAbility(ability, battler, battle, [:ATTACK, 2], aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FASCINATE,
  proc { |ability, battler, battle, aiCheck|
      next entryDebuffAbility(ability, battler, battle, [:SPECIAL_ATTACK, 2], aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FRUSTRATE,
  proc { |ability, battler, battle, aiCheck|
      next entryDebuffAbility(ability, battler, battle, [:SPEED, 2], aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DRAMATICLIGHTING,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battle.eclipsed?
      next entryDebuffAbility(ability, battler, battle, ATTACKING_STATS_2, aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SCOUREDSILHOUETTE,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battle.sandy?
      next entryDebuffAbility(ability, battler, battle, ATTACKING_STATS_2, aiCheck: aiCheck)
  }
)

#######################################################
# Ability warnings on entry
#######################################################

BattleHandlers::LoadDataDependentAbilityHandlers += proc {
  GameData::Ability.getByFlag("MoldBreaking").each do |abilityID|
      BattleHandlers::AbilityOnSwitchIn.add(abilityID,
          proc { |ability, battler, battle, aiCheck|
              next 0 if aiCheck
              battle.pbShowAbilitySplash(battler, ability)
              if ability == :UNBOUND
                battle.pbDisplay(_INTL("{1} breaks the mold and overpowers type immunities!", battler.pbThis))
              else
                battle.pbDisplay(_INTL("{1} breaks the mold!", battler.pbThis))
              end
              battle.pbHideAbilitySplash(battler)
          }
      )
  end
}

BattleHandlers::AbilityOnSwitchIn.add(:PRESSURE,
proc { |ability, battler, battle, aiCheck|
    next 0 if aiCheck
    battle.pbShowAbilitySplash(battler, ability)
    battle.pbDisplay(_INTL("{1} is exerting its pressure!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
}
)

BattleHandlers::AbilityOnSwitchIn.add(:UNNERVE,
proc { |ability, battler, battle, aiCheck|
    next 0 if aiCheck
    battle.pbShowAbilitySplash(battler, ability)
    battle.pbDisplay(_INTL("{1} is too nervous to eat Berries or Leftovers!", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
}
)

BattleHandlers::AbilityOnSwitchIn.add(:STRESSFUL,
proc { |ability, battler, battle, aiCheck|
    next 0 if aiCheck
    battle.pbShowAbilitySplash(battler, ability)
    battle.pbDisplay(_INTL("{1} is too stressed to use their items!", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
}
)

BattleHandlers::AbilityOnSwitchIn.add(:ASONEICE,
proc { |ability, battler, battle, aiCheck|
    next 0 if aiCheck
    battle.pbShowAbilitySplash(battler, ability)
    battle.pbDisplay(_INTL("{1} has 2 Abilities!", battler.name))
    battle.pbShowAbilitySplash(battler, :UNNERVE)
    battle.pbDisplay(_INTL("{1} is too nervous to eat Berries or Leftovers!", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
}
)

BattleHandlers::AbilityOnSwitchIn.copy(:ASONEICE, :ASONEGHOST)

BattleHandlers::AbilityOnSwitchIn.add(:AURABREAK,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} reversed all other Pokémon's auras!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:COMATOSE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is drowsing!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DARKAURA,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is radiating a dark aura!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FAIRYAURA,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is radiating a fairy aura!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:RUINOUS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is ruinous! Everyone deals 40 percent more damage!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CITYRAZER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is hungry for destruction!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HONORABLE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is honorable! Status moves lose priority!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:KILLJOY,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is a killjoy! Stats can't be raised!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:BADINFLUENCE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is a bad influence! Healing is reversed!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SIGNALJAM,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is interfering! No one gets same-type damage bonus!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:BREAKINGWAVE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} arrived on a breaking wave!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:LEVITATE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is floating in mid-air!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:MAESTRO,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} speeds up the music!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:PRANKSTER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is up to no good!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GALEWINGS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is flying quickly!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TRENCHCARVER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is barging through!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EGOIST,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} has a huge ego!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TRIAGE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} prioritizes healing!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SWIFTSTOMPS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is ready to stomp the opposition!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:BREAKTHROUGH,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} overpowers type immunities!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:PACIFIST,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} refuses to fight!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HOPPINGMAD,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is hopping mad!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CELERITAS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is shining with light speed!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FEROCIOUS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is ferocious!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:LIGHTTRICK,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} tricks the eye!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

##########################################
# Screen setting abilities
##########################################
BattleHandlers::AbilityOnSwitchIn.add(:BARRIERMAKER,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getReflectEffectScore(battler, 4)
      else
          battle.pbShowAbilitySplash(battler, ability)
          duration = battler.getScreenDuration(4)
          battle.pbAnimation(:REFLECT, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:Reflect, duration)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:STARGUARDIAN,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getLightScreenEffectScore(battler, 4)
      else
          battle.pbShowAbilitySplash(battler, ability)
          duration = battler.getScreenDuration(4)
          battle.pbAnimation(:LIGHTSCREEN, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:LightScreen, duration)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

##########################################
# Room setting abilities
##########################################

BattleHandlers::AbilityOnSwitchIn.add(:PUZZLING,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:PuzzleRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ODDITY,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:OddRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SUBSPACESCHISM,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:TrickRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:POLARIZING,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:PolarizedRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:INSIGHTAURA,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:InsightRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EMOTIONAURA,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:EmotionRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:WILLAURA,
  proc { |ability, battler, battle, aiCheck|
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.pbAnimation(:TRICKROOM, battler, nil, 0) unless aiCheck
      score = battle.pbStartRoom(:WillfulRoom, battler, ability, aiCheck)
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

##########################################
# Totem abilities
##########################################
BattleHandlers::AbilityOnSwitchIn.add(:STORMTOTEM,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          scoringDuration = 6
          if battler.pbOwnSide.effectActive?(:TurbulentSky)
              scoringDuration -= battler.pbOwnSide.countEffect(:TurbulentSky)
          end
          next 20 * scoringDuration
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.pbOwnSide.applyEffect(:TurbulentSky, 6)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FOGTOTEM,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          scoringDuration = 6
          if battler.pbOwnSide.effectActive?(:MisdirectingFog)
              scoringDuration -= battler.pbOwnSide.countEffect(:MisdirectingFog)
          end
          next 20 * scoringDuration
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.pbOwnSide.applyEffect(:MisdirectingFog, 6)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:WILDTOTEM,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          scoringDuration = 6
          if battler.pbOwnSide.effectActive?(:PrimalForest)
              scoringDuration -= battler.pbOwnSide.countEffect(:PrimalForest)
          end
          next 20 * scoringDuration
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.pbOwnSide.applyEffect(:PrimalForest, 6)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FLUTTERTOTEM,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          scoringDuration = 6
          if battler.pbOwnSide.effectActive?(:CruelCocoon)
              scoringDuration -= battler.pbOwnSide.countEffect(:CruelCocoon)
          end
          next 20 * scoringDuration
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.pbOwnSide.applyEffect(:CruelCocoon, 6)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

##########################################
# Other effect setting
##########################################
BattleHandlers::AbilityOnSwitchIn.add(:GARLANDGUARDIAN,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getSafeguardEffectScore(battler, 10)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:SAFEGUARD, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:Safeguard, 10)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CLOVERSONG,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getLuckyChantEffectScore(battler, 10)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:LUCKYCHANT, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:LuckyChant, 10)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ONTHEWIND,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getTailwindEffectScore(battler, 4)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:TAILWIND, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:Tailwind, 4)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GRAVITAS,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getGravityEffectScore(battler, 4)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:GRAVITY, battler, nil, 0)
          battle.field.applyEffect(:Gravity, 4)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DRIFTINGMIST,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getGreyMistSettingEffectScore(battler, 3)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:GREYMIST, battler, nil, 0)
          battle.field.applyEffect(:GreyMist, 3)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FITTOSURVIVE,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getGravityEffectScore(battler, 4)
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbAnimation(:NATURALPROTECTION, battler, nil, 0)
          battler.pbOwnSide.applyEffect(:NaturalProtection, 4)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

##########################################
# Free move use
##########################################

BattleHandlers::AbilityOnSwitchIn.add(:KLEPTOMANIAC,
  proc { |ability, battler, battle, aiCheck|
      next battle.forceUseMove(battler, :SNATCH, ability: ability, aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ASSISTANT,
  proc { |ability, battler, battle, aiCheck|
      next battle.forceUseMove(battler, :ASSIST, ability: ability, aiCheck: aiCheck)
  }
)

# Only used to force the AI to use Sudden Turn somewhat properly
BattleHandlers::AbilityOnSwitchIn.add(:SUDDENTURN,
  proc { |ability, battler, battle, aiCheck|
    if aiCheck
      next battle.forceUseMove(battler, :RAPIDSPIN, ability: ability, aiCheck: true) / 2
    else
      next 0
    end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:WIBBLEWOBBLE,
  proc { |ability, battler, battle, aiCheck|
      next battle.forceUseMove(battler, :POWERSPLIT, ability: ability, aiCheck: aiCheck)
  }
)

##########################################
# Self buffing
##########################################
BattleHandlers::AbilityOnSwitchIn.add(:INTREPIDSWORD,
  proc { |ability, battler, _battle, aiCheck|
      if aiCheck
          next getMultiStatUpEffectScore([:ATTACK, 1], battler, battler)
      else
          battler.tryRaiseStat(:ATTACK, battler, ability: ability)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DAUNTLESSSHIELD,
  proc { |ability, battler, _battle, aiCheck|
      if aiCheck
          next getMultiStatUpEffectScore([:DEFENSE, 1], battler, battler)
      else
          battler.tryRaiseStat(:DEFENSE, battler, ability: ability)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:DOWNLOAD,
  proc { |ability, battler, battle, aiCheck|
      oppTotalDef = oppTotalSpDef = 0
      anyFoes = false
      battler.eachOpposing do |b|
        anyFoes = true
        oppTotalDef += b.pbDefense
        oppTotalSpDef += b.pbSpDef
      end
      next 0 unless anyFoes
      stat = (oppTotalDef < oppTotalSpDef) ? :ATTACK : :SPECIAL_ATTACK
      if aiCheck
          next getMultiStatUpEffectScore([stat, 2], battler, battler)
      else
          battler.tryRaiseStat(stat, battler, ability: ability, increment: 2)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SELECTIVESCUTES,
  proc { |ability, battler, battle, aiCheck|
      oppTotalAttack = oppTotalSpAtk = 0
      anyFoes = false
      battler.eachOpposing do |b|
        anyFoes = true
        oppTotalAttack += b.pbAttack
        oppTotalSpAtk += b.pbSpAtk
      end
      next 0 unless anyFoes
      stat = (oppTotalAttack > oppTotalSpAtk) ? :DEFENSE : :SPECIAL_DEFENSE
      if aiCheck
          next getMultiStatUpEffectScore([stat, 2], battler, battler)
      else
          battler.tryRaiseStat(stat, battler, ability: ability, increment: 2)
      end
  }
)

##########################################
# Misc
##########################################
BattleHandlers::AbilityOnSwitchIn.add(:FREERIDE,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battler.hasAlly?
      score = 0
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battler.eachAlly do |b|
          if aiCheck
              score += getMultiStatUpEffectScore([:SPEED, 2], battler, b)
          else
              b.tryRaiseStat(:SPEED, battler, increment: 2)
          end
      end
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:ARCANEFINALE,
  proc { |ability, battler, battle, aiCheck|
      next -100 unless battler.isLastAlive?
      next 0 unless battler.form == 0
      next 100 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battler.pbChangeForm(1, _INTL("{1} is the team's finale!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.copy(:ARCANEFINALE, :HEROICFINALE)

BattleHandlers::AbilityOnSwitchIn.add(:PRIMEVALSLOWSTART,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability, true)
      battle.pbDisplay(_INTL("{1} is burdened!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:PRIMEVALIMPOSTER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability, true)
      battle.pbDisplay(_INTL("{1} transforms into a stronger version of your entire team!", battler.pbThis))
      battler.boss = false
      battle.bossBattle = false

      trainerClone = NPCTrainer.cloneFromPlayer($Trainer,true)
      battle.opponent = [trainerClone]

      party = battle.pbParty(battler.index)
      party.clear

      # Give each cloned pokemon a stat boost to each stat
      trainerClone.party.each do |partyMember|
        next unless partyMember
        next if partyMember.fainted?
        party.push(partyMember)
        partyMember.ev = partyMember.ev.each_with_object({}) do |(statID, evValue), evArray|
            evArray[statID] = evValue + 10
        end
        partyMember.calc_stats
      end

      partyOrder = battle.pbPartyOrder(battler.index)
      partyOrder.clear
      party.each do |_partyMember, index|
          partyOrder.push(index)
      end

      battler.pbInitialize(party[0], 0)
      if party.length > 1
          battle.addBattlerSlot(party[1], 1, 0)
      else
          battle.remakeDataBoxes
          battle.remakeBattleSpritesOnSide(battler.index % 2)
      end

      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:REFRESHMENTS,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battle.sunny?
      next entryLowestHealingAbility(ability, battler, battle, aiCheck: aiCheck) do |served|
          _INTL("{1} served {2} some refreshments!", battler.pbThis, served)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TOLLTHEBELLS,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battle.eclipsed?
      next entryLowestHealingAbility(ability, battler, battle, aiCheck: aiCheck) do |served|
          _INTL("{1} mended {2} with soothing sounds!", battler.pbThis, served)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:GYRESPINNER,
  proc { |ability, battler, battle, aiCheck|
      next entryTrappingAbility(ability, battler, battle, :WHIRLPOOL, aiCheck: aiCheck) { |trappedFoe|
        _INTL("{1} became trapped in the vortex!", trappedFoe.pbThis)
      }
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SUSTAINABLE,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battler.recyclableItem
      next 0 unless GameData::Item.get(battler.recyclableItem).is_berry?
      next 0 if battler.hasItem?(battler.recyclableItem)
      next 0 unless battle.sunny?
      next 80 if aiCheck
      recyclingMsg = _INTL("{1} regrew one {2}!", battler.pbThis, getItemName(battler.recyclableItem))
      battler.recycleItem(recyclingMsg: recyclingMsg, ability: ability)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:COTTONDECOY,
  proc { |ability, battler, battle, aiCheck|
      next 0 if battler.substituted?
      next 0 unless battler.hp > battler.totalhp / 4
      if aiCheck
          score = 0
          score += getSubstituteEffectScore(battler)
          score += getHPLossEffectScore(battler, 0.25)
          next score
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.createSubstitute
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TESLACOILS,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          if battler.pbHasAttackingType?(:ELECTRIC)
              next 40
          else
              next 0
          end
      end
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbAnimation(:CHARGE, battler, nil)
      battler.applyEffect(:EnergyCharge)
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:UNIDENTIFIED,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is Mutant-type!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:INFECTED,
  proc { |ability, battler, battle, aiCheck|
      next 10 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is infected!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:RUSTWRACK,
  proc { |ability, battler, battle, aiCheck|
      next 10 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is rusty!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SLUGGISH,
  proc { |ability, battler, battle, aiCheck|
      next 10 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is sluggish!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HAUNTED,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is haunted!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:BRUTEFORCE,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} forces its moves to be physical!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:TIMEINTERLOPER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} is an interloper! All its moves are special!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.copy(:TIMEINTERLOPER, :SPACEINTERLOPER)

BattleHandlers::AbilityOnSwitchIn.add(:SLUMBERINGDRAKE,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battler.canSleep?(battler, !aiCheck)
      if aiCheck
          score = 0
          score -= getSleepEffectScore(nil, battler)
          score += getMultiStatUpEffectScore(ALL_STATS_2, battler, battler)
          next score
      else
          battle.pbShowAbilitySplash(battler, ability)
          battler.applySleep
          battler.pbRaiseMultipleStatSteps(ALL_STATS_2, battler)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SLOWSTART,
  proc { |ability, battler, battle, aiCheck|
      next -50 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battler.applyEffect(:SlowStart, 3)
      battle.pbDisplay(_INTL("{1} can't get it going!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:AIRLOCK,
  proc { |ability, battler, battle, aiCheck|
      if aiCheck
          next getWeatherResetEffectScore(battler) / 2
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbDisplay(_INTL("The effects of the weather disappeared."))
          battle.pbHideAbilitySplash(battler)
          battle.field.specialTimer = 1
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.copy(:AIRLOCK, :CLOUDNINE)

BattleHandlers::AbilityOnSwitchIn.add(:IMPOSTER,
  proc { |ability, battler, battle, aiCheck|
      next 0 if battler.transformed?
      choice = battler.pbDirectOpposing
      next 0 if choice.fainted?
      next 0 if choice.transformed?
      next 0 if choice.illusion?
      next 0 if choice.substituted?
      next 0 if choice.effectActive?(:SkyDrop)
      next 0 if choice.semiInvulnerable?
      next 40 if aiCheck
      battle.pbShowAbilitySplash(battler, ability, true)
      battle.pbHideAbilitySplash(battler)
      battle.pbAnimation(:TRANSFORM, battler, choice)
      battler.pbTransform(choice)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:SCREENCLEANER,
  proc { |ability, battler, battle, aiCheck|
      anyScreen = false
      battle.sides.each do |side|
          side.eachEffect(true) do |_effect, _value, effectData|
              next 0 unless effectData.is_screen?
              anyScreen = true
              break
          end
          break if anyScreen
      end
      next 0 unless anyScreen

      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      score = 0
      battle.sides.each do |side|
          side.eachEffect(true) do |effect, value, effectData|
              next unless effectData.is_screen?
              if aiCheck
                  screenScore = 20 + value * 10
                  if side.index == battler.index % 2
                      score -= screenScore
                  else
                      score += screenScore
                  end
              else
                  side.disableEffect(effect)
              end
          end
      end
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score if aiCheck
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:CURIOUSMEDICINE,
  proc { |ability, battler, battle, aiCheck|
      done = false
      score = 0
      battler.eachAlly do |b|
          next unless b.hasAlteredStatSteps?
          if aiCheck
              score -= statStepsValueScore(b)
          else
              b.pbResetStatSteps
              done = true
          end
      end
	  battler.eachOpposing do |b|
          next unless b.hasAlteredStatSteps?
          if aiCheck
              score += statStepsValueScore(b)
          else
              b.pbResetStatSteps
              done = true
          end
      end
      next score if aiCheck
      if done
          battle.pbShowAbilitySplash(battler, ability)
          battle.pbDisplay(_INTL("All stat changes were eliminated!"))
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:NEUTRALIZINGGAS,
  proc { |ability, battler, battle, aiCheck|
      next 0 if battle.field.effectActive?(:NeutralizingGas)
      if aiCheck
          score = 0
          battler.eachOpposing do |b|
              score += 40 if b.abilityActive?
          end
          battler.eachAlly do |b|
              score -= 40 if b.abilityActive?
          end
          next score
      else
          battle.pbShowAbilitySplash(battler, ability)
          battle.field.applyEffect(:NeutralizingGas)
          battle.pbHideAbilitySplash(battler)
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:HOLIDAYCHEER,
  proc { |ability, battler, battle, aiCheck|
      anyHealing = false
      battle.eachSameSideBattler(battler.index) do |b|
          next 0 if b.fullHealth?
          anyHealing = true
      end
      next 0 unless anyHealing
      score = 0
      battle.pbShowAbilitySplash(battler, ability) unless aiCheck
      battle.eachSameSideBattler(battler.index) do |b|
            score += b.applyFractionalHealing(0.25, aiCheck: aiCheck)
      end
      battle.pbHideAbilitySplash(battler) unless aiCheck
      next score if aiCheck
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:EXTRASCOOP,
  proc { |ability, battler, battle, aiCheck|
    next battler.applyFractionalHealing(1.0/4.0, ability: ability, canOverheal: true, aiCheck: aiCheck)
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:LASTGASP,
  proc { |ability, battler, battle, aiCheck|
    next 0 if aiCheck
    battler.showMyAbilitySplash(ability)
    battler.applyEffect(:LastGasp)
    battler.applyEffect(:PerishSong, 3)
    battler.hideMyAbilitySplash
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:UNBOUND,
  proc { |ability, battler, battle, aiCheck|
      next 0 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battle.pbDisplay(_INTL("{1} overpowers type immunities!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
  }
)

CASHOUT_HEALING_DIVISOR = 10

BattleHandlers::AbilityOnSwitchIn.add(:CASHOUT,
  proc { |ability, battler, battle, aiCheck|
      next unless battler.pbOwnSide.effectActive?(:PayDay)
      maxCoinsCanHealFrom = battler.maxOverhealingPossible * CASHOUT_HEALING_DIVISOR
      coinsToConsume = [battler.pbOwnSide.countEffect(:PayDay),maxCoinsCanHealFrom].min
      healingAmt = coinsToConsume / CASHOUT_HEALING_DIVISOR
      battler.showMyAbilitySplash(ability) unless aiCheck
      healingMessage = _INTL("{1} gobbles up the scattered coins!",battler.pbThis)
      recoveredHP = battler.pbRecoverHP(healingAmt, true, true, true, healingMessage, canOverheal: true, aiCheck: aiCheck)
      if aiCheck
        next battler.getHealingEffectScore(recoveredHP)
      else
        battler.pbOwnSide.effects[:PayDay] -= coinsToConsume
        battler.hideMyAbilitySplash
      end
  }
)

BattleHandlers::AbilityOnSwitchIn.add(:FALSEFRONT,
  proc { |ability, battler, battle, aiCheck|
      next unless battler.canChangeType?
      next 0 if aiCheck
      battler.showMyAbilitySplash(ability)
      validTypes = %i[FIGHTING DARK FAIRY]
      validTypeNames = []
      validTypes.each do |typeID|
          validTypeNames.push(GameData::Type.get(typeID).name)
      end
      if validTypes.length == 1
          chosenType = validTypes[0]
      elsif validTypes.length > 1
          if battle.autoTesting
              chosenType = validTypes.sample
          elsif !battler.pbOwnedByPlayer? # Trainer AI
              validTypes.each do |type|
                next unless battler.pbHasAttackingType?(type)
                chosenType = type
              end
              chosenType = chosenType || validTypes[0]
          else
              chosenIndex = battle.scene.pbShowCommands(_INTL("Which type should {1} fake?", battler.pbThis(true)),validTypeNames,0)
              chosenType = validTypes[chosenIndex]
          end
      end
      battler.applyEffect(:Type3,chosenType)
      battler.hideMyAbilitySplash
  }
)