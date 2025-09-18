BattleHandlers::DamageCalcUserAbility.add(:ARCTICARIETTE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      if aiCheck
          mults[:base_damage_multiplier] *= 1.3 if move.soundMove?
      elsif move.powerBoost
          mults[:base_damage_multiplier] *= 1.3
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:NORMALIZE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      if aiCheck
          mults[:base_damage_multiplier] *= 1.5 if type != :NORMAL
      elsif move.powerBoost
          mults[:base_damage_multiplier] *= 1.5
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ANALYTIC,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      if aiCheck
          mults[:base_damage_multiplier] *= 1.3 if target.pbSpeed < user.pbSpeed
      elsif (target.battle.choices[target.index][0] != :UseMove &&
            target.battle.choices[target.index][0] != :Shift) ||
            target.movedThisRound?
          mults[:base_damage_multiplier] *= 1.3
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:DEFEATIST,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.belowHalfHealth?
      mults[:attack_multiplier] /= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PERFECTIONIST,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    unless target.damageState.critical # TODO: Ai check
      mults[:final_damage_multiplier] /= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:MEGALAUNCHER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.pulseMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:EMANATION,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.pulseMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:REFRACTIVE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.lightMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:RECKLESS,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.recoilMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:LINEBACKER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.recoilMove?
      mults[:base_damage_multiplier] *= 2.0
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:HOOLIGAN,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.recoilMove? || move.soundMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STONEMANE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.recoilMove?
      mults[:base_damage_multiplier] *= 1.2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STRONGJAW,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.bitingMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SHEERFORCE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.randomEffect?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TECHNICIAN,
  proc { |ability, user, target, move, mults, baseDmg, type, aiCheck|
      if    user.index != target.index && move && move.id != :STRUGGLE &&
            baseDmg * mults[:base_damage_multiplier] <= 60
          mults[:base_damage_multiplier] *= 1.5
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:IRONFIST,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.punchingMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)
BattleHandlers::DamageCalcUserAbility.copy(:IRONFIST, :MYSTICFIST)

BattleHandlers::DamageCalcUserAbility.add(:KNUCKLEDUSTER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.punchingMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SHIFTINGFIST,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.punchingMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:BRISK,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.windMove?
      mults[:attack_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:GALEFORCE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.windMove?
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:LOUD,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.soundMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:LOUD, :TUNEDOUT)

BattleHandlers::DamageCalcUserAbility.add(:EARSPLITTING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.soundMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SWORDPLAY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.bladeMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:SWORDPLAY, :RAZORSEDGE, :BLADEBRAINED)

BattleHandlers::DamageCalcUserAbility.add(:SHARPNESS,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.bladeMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:IRONHEEL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.kickingMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:IRONHEEL, :HEAVYDUTYHOOVES)

BattleHandlers::DamageCalcUserAbility.add(:BEAMING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.lightMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:RADIATE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.lightMove?
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:WELLROUNDED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.tagged?
      mults[:base_damage_multiplier] *= 1.2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:BADOMEN,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.foretoldMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:GORGING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.healingMove?
      mults[:attack_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:EXPERTISE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.super_effective?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:EXPERTISE,:NEUROFORCE)

BattleHandlers::DamageCalcUserAbility.add(:TINTEDLENS,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if Effectiveness.resistant?(typeModToCheck(user.battle, type, user, target, move, aiCheck))
      mults[:final_damage_multiplier] *= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SNIPER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.damageState.critical # TODO: Ai check
      mults[:final_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STAKEOUT,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:SwitchedIn)
      mults[:attack_multiplier] *= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:LIMINAL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:SwitchedIn)
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:AFTERIMAGE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:SwitchedIn)
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:QUARRELSOME,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.firstTurn?
      mults[:attack_multiplier] *= 2.0
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STEELWORKER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :STEEL
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.copy(:STEELWORKER, :STEELYSHELL, :PULVERIZE)

BattleHandlers::DamageCalcUserAbility.add(:STRATAGEM,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ROCK
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SURFSUP,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :WATER
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ERUDITE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :PSYCHIC
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:MULTITASKER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :PSYCHIC
      mults[:attack_multiplier] *= 1.35
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:EVENHANDED,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FIGHTING
      mults[:attack_multiplier] *= 1.35
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PECKINGORDER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FLYING
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TUNNELMAKER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :GROUND
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SUBZERO,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ICE
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PALEOLITHIC,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ROCK
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SUPERALLOY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :STEEL
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SCALDINGSMOKE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :POISON
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STEELYSPIRIT,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :STEEL
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:VERDANT,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :GRASS
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TOXICATTITUDE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :POISON
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:UNCANNYCOLD,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ICE
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:WATERBUBBLE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :WATER
      mults[:attack_multiplier] *= 2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SHOCKSTYLE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :FIGHTING
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:HUSTLE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:DRAGONSMAW,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :DRAGON
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TRANSISTOR,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ELECTRIC
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:MIDNIGHTSUN,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.sunny? && type == :DARK
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:DARKENEDSKIES,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.sandy? && type == :DARK
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:RAINPRISM,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.rainy? && type == :FAIRY
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:WORLDQUAKE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.eclipsed? && type == :GROUND
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TIDALFORCE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.moonGlowing? && type == :WATER
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TAIGATREKKER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.icy? && type == :GRASS
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:VARIETY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.lastMoveUsed != move.id && !user.lastMoveFailed
      mults[:attack_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PHASESHIFT,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if !user.lastMoveUsedType.nil? && type != user.lastMoveUsedType
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:ARMORPIERCING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if  target.steps[:DEFENSE] > 0 ||
        target.steps[:SPECIAL_DEFENSE] > 0 ||
        target.protectedByScreen?
      mults[:base_damage_multiplier] *= 2.0
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TERRITORIAL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.battle.pbWeather != :None
      mults[:attack_multiplier] *= 1.2
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SOULREAD,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      if !target.lastMoveUsedType.nil? && !target.pbTypes(true).include?(target.lastMoveUsedType)
          mults[:attack_multiplier] *= 2.0
          user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:DOUBLECHECK,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.tookDamage
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:DRAGONSLAYER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.hasType?(:DRAGON)
      mults[:base_damage_multiplier] *= 2.0
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SPACEINTERLOPER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      mults[:attack_multiplier] *= 0.5
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TIMEINTERLOPER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      mults[:attack_multiplier] *= 3.0 / 4.0
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:MARINEMENACE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.function == "TwoTurnAttackInvulnerableUnderwater" # Dive, # Depth Charge
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:EXCAVATOR,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.function == "TwoTurnAttackInvulnerableUnderground" # Dig, Undermine
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:STEEPFLYING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.function == "TwoTurnAttackInvulnerableInSky" # Fly, Divebomb
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:GRIPSTRENGTH,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.function == "BindTarget3" # 3-turn DOT trapping moves
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

UNCONVENTIONAL_MOVE_CODES = %w[
    AttacksWithTargetsStats
    AttacksWithDefense
    AttacksWithSpDef
    DoesPhysicalDamage
    DoesSpecialDamage
    TargetsAttackDefends
    TargetsSpAtkDefends
].freeze

BattleHandlers::DamageCalcUserAbility.add(:UNCONVENTIONAL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if UNCONVENTIONAL_MOVE_CODES.include?(move.function)
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:RATTLEEM,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.effectActive?(:FlinchImmunity)
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:AURORAPRISM,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    unless user.pbHasType?(type)
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:FLEXIBLE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    unless user.pbHasType?(type)
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:FIRSTSTRIKE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      priority = user.battle.choices[user.index][4] || move.priority || nil
      if priority > 0
        mults[:base_damage_multiplier] *= 1.3
        user.aiLearnsAbility(ability) unless aiCheck
      end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:HARDFALL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.pbHeight > user.pbHeight
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SCATHINGSYZYGY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.battle.eclipsed?
      mults[:base_damage_multiplier] *= 1.25
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:BALLLIGHTNING,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      damageMult = 1.0
      if user.pbSpeed > target.pbSpeed
        speedMult = user.pbSpeed / target.pbSpeed.to_f
        speedMult = 2.0 if speedMult > 2.0
        damageMult += speedMult / 4.0
      end
      mults[:base_damage_multiplier] *= damageMult
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:LATEBLOOMER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.pbSpeed < target.pbSpeed
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:VANDAL,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.hasAnyItem?
      mults[:attack_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TEAMPLAYER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      allyCount = 0
      user.eachAlly do |_b|
        allyCount += 1
      end
      mults[:attack_multiplier] *= (1 + 0.25 * allyCount)
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:CLEANFREAK,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      mults[:attack_multiplier] *= 1.5 if user.pbHasAnyStatus?
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PUFFUP,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
      mults[:attack_multiplier] *= 1 + (0.25 * user.countEffect(:Stockpile))
      user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:WREAKHAVOC,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.rampagingMove?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:SLINKY,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if move.is_a?(PokeBattle_Move_TwoTurnAttackInvulnerable)
      mults[:base_damage_multiplier] *= 2.0
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:TERRORIZE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    mults[:base_damage_multiplier] *= 0.9
    user.aiLearnsAbility(ability) unless aiCheck
  }
)

BattleHandlers::DamageCalcUserAbility.add(:PITFIGHTER,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.trapped?
      mults[:base_damage_multiplier] *= 1.3
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:HIVEMIND,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :BUG
      mults[:base_damage_multiplier] *= 1.5
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)

BattleHandlers::DamageCalcUserAbility.add(:RELUCTANTWARRIOR,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if user.belowHalfHealth?
      mults[:attack_multiplier] *= 1.3
	  user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)
	  
BattleHandlers::DamageCalcUserAbility.add(:TANGLINGVINES,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if target.pointsAt?(:TanglingVines, user)
      mults[:base_damage_multiplier] *= 1.3
      user.battle.pbDisplay(_INTL("The tangling vines strengthened the hit!"))
      user.aiLearnsAbility(ability) unless aiCheck
    end
  }
)