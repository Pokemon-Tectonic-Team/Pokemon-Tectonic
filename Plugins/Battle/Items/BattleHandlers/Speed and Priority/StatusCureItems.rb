BattleHandlers::StatusCureItem.add(:ASPEARBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:FROZEN)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:FROZEN)
    battle.pbDisplay(_INTL("{1}'s {2} unchilled it!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:CHERIBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:PARALYSIS)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:PARALYSIS)
    battle.pbDisplay(_INTL("{1}'s {2} cured its paralysis!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:CHESTOBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:SLEEP)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:SLEEP)
    battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:PECHABERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:POISON)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:POISON)
    battle.pbDisplay(_INTL("{1}'s {2} cured its poisoning!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:RAWSTBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:BURN)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:BURN)
    battle.pbDisplay(_INTL("{1}'s {2} healed its burn!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:LUMBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasAnyStatusNoTrigger
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus
    next true
  }
)

BattleHandlers::StatusCureItem.add(:PERSIMBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:FLUSTERED)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:FLUSTERED)
    battle.pbDisplay(_INTL("{1}'s {2} made it no longer flustered!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:DURINBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if !battler.hasStatusNoTrigger(:MYSTIFIED)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced,:MYSTIFIED)
    battle.pbDisplay(_INTL("{1}'s {2} made it no longer mystified!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:MENTALHERB,
  proc { |item,battler,battle,forced|
    activate = false
    battler.eachEffect(true) do |effect,value,data|
      next if !data.is_mental?
      activate = true
      break
    end
    activate = true if battler.flustered? || battler.mystified?
  
    next false if !activate

    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}")
    battle.pbCommonAnimation("UseItem",battler) if !forced

    # Disable all mental effects
    battler.eachEffect(true) do |effect,value,data|
      next if !data.is_mental?
      battler.disableEffect(effect)
    end
    next true
  }
)