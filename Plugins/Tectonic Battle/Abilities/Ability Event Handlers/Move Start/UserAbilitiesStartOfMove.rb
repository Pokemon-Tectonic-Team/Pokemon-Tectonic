#=============================================================================
# Protean-style abilities
#=============================================================================
BattleHandlers::UserAbilityStartOfMove.add(:PROTEAN,
  proc { |ability, user, targets, move, battle|
    moveUseTypeChangeAbility(ability, user, move, battle)
  }
)

BattleHandlers::UserAbilityStartOfMove.copy(:PROTEAN,:FREESTYLE)

BattleHandlers::UserAbilityStartOfMove.add(:SHAKYCODE,
  proc { |ability, user, targets, move, battle|
    moveUseTypeChangeAbility(ability, user, move, battle) if battle.eclipsed?
  }
)

BattleHandlers::UserAbilityStartOfMove.add(:MUTABLE,
  proc { |ability, user, targets, move, battle|
    next if user.effectActive?(:Mutated)
    next unless moveUseTypeChangeAbility(ability, user, move, battle)
    user.applyEffect(:Mutated)
  }
)

BattleHandlers::UserAbilityStartOfMove.add(:SHIFTINGFIST,
  proc { |ability, user, targets, move, battle|
    moveUseTypeChangeAbility(ability, user, move, battle, true) if move.punchingMove?
  }
)

BattleHandlers::UserAbilityStartOfMove.add(:REFRACTIVE,
  proc { |ability, user, targets, move, battle|
    moveUseTypeChangeAbility(ability, user, move, battle, true) if move.lightMove?
  }
)