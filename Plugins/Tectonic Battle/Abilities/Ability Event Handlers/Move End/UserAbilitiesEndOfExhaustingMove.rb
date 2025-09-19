BattleHandlers::UserAbilityEndOfExhaustingMove.add(:REMANENTVOLTAGE,
  proc { |ability, user, targets, _move, battle|
      battle.pbShowAbilitySplash(user, ability)
      battle.pbDisplay(_INTL("{1} anchors itself in the ground!", user.pbThis))
      user.disableEffect(:HyperBeam)
      user.applyEffect(:Stuck, 2)
      user.applyEffect(:TypeRestricted, :ELECTRIC)
      user.applyEffect(:TypeRestrictedTurns, 2)
      battle.pbHideAbilitySplash(user)
  }
)