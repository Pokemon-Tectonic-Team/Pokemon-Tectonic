BattleHandlers::UserItemAfterMoveUse.add(:LIFEORB,
    proc { |item, user, targets, move, numHits, battle|
        next unless user.takesIndirectDamage?
        next if !move.damagingMove? || numHits == 0
        hitBattler = false
        targets.each do |b|
            hitBattler = true if !b.damageState.unaffected && !b.damageState.substitute
            break if hitBattler
        end
        next unless hitBattler
        battle.pbDisplay(_INTL("{1} lost some of its HP!", user.pbThis))
        user.applyFractionalDamage(1.0 / 10.0, false)
        user.aiLearnsItem(item)
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:SHELLBELL,
    proc { |item, user, targets, _move, _numHits, _battle|
        next unless user.canHeal?
        totalDamage = 0
        targets.each { |b| totalDamage += b.damageState.totalHPLost }
        next if totalDamage <= 0
        healAmount = (totalDamage / 5.0)
        healAmount = 1 if healAmount < 1
        recoverMessage = _INTL("{1} restored a little HP using its {2}!", user.pbThis, getItemName(item))
        user.pbRecoverHP(healAmount, true, true, true, recoverMessage)
        user.aiLearnsItem(item)
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:THROATSPRAY,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.soundMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.tryRaiseStat(:SPECIAL_ATTACK, user, item: item, increment: 2)
    }
)


BattleHandlers::UserItemAfterMoveUse.add(:WHETSTONE,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.bladeMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.tryRaiseStat(:ATTACK, user, item: item, increment: 2)
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:PROTEINSHAKE,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.punchingMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.applyFractionalHealing(1.0 / 3.0, item: item, canOverheal: true) != 0
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:STRESSBALL,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.pulseMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.applyFractionalHealing(1.0 / 3.0, item: item, canOverheal: true) != 0
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:PINWHEEL,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.windMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.tryRaiseStat(:SPEED, user, item: item, increment: 2)
    }
)

BattleHandlers::UserItemAfterMoveUse.add(:INSOLES,
    proc { |item, user, _targets, move, numHits, battle|
        next if battle.pbAllFainted?(user.idxOwnSide) || battle.pbAllFainted?(user.idxOpposingSide)
        next unless move.kickingMove?
        next if numHits == 0
        user.pbHeldItemTriggered(item) if user.tryRaiseStat(:SPEED, user, item: item, increment: 2)
    }
)