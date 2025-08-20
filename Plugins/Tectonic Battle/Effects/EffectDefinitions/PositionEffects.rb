GameData::BattleEffect.register_effect(:Position, {
    :id => :FutureSightCounter,
    :real_name => "Turns Till Move",
    :type => :Integer,
    :ticks_down => true,
    :sub_effects => %i[FutureSightMove FutureSightUserPartyIndex FutureSightUserIndex FutureSightType],
    :expire_proc => proc do |battle, index, position, battler|
        userIndex = position.effects[:FutureSightUserIndex]
        partyIndex = position.effects[:FutureSightUserPartyIndex]
        move = position.effects[:FutureSightMove]
        moveUser = nil
        battle.eachBattler do |b|
            next if b.opposes?(userIndex)
            next if b.pokemonIndex != partyIndex
            moveUser = b
            break
        end
        # Target is the user
        next if moveUser && moveUser.index == battler.index
        # User isn't in battle, get it from the party
        if moveUser.nil? || moveUser.fainted?
            party = battle.pbParty(userIndex)
            pkmn = party[partyIndex]
            if pkmn
                moveUser = PokeBattle_Battler.new(battle, userIndex)
                moveUser.pbInitDummyPokemon(pkmn, partyIndex, true)
            end
        end
        next if moveUser.nil?
        moveName = GameData::Move.get(move).name
        battle.pbDisplay(_INTL("{1} took the {2} attack!", battler.pbThis, moveName))
        # NOTE: Future Sight failing against the target here doesn't count towards
        #       Stomping Tantrum.
        userLastMoveFailed = moveUser.lastMoveFailed
        battle.futureSight = true
        moveUser.pbUseMoveSimple(move, index)
        battle.futureSight = false
        moveUser.lastMoveFailed = userLastMoveFailed
        battler.pbFaint if battler.fainted?
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :FutureSightMove,
    :real_name => "Incoming Move",
    :type => :Move,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :FutureSightUserIndex,
    :real_name => "Foretold Move User Index",
    :type => :Position,
    :info_displayed => false,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :FutureSightUserPartyIndex,
    :real_name => "Foretold Move User Party Index",
    :type => :PartyPosition,
    :info_displayed => false,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :FutureSightType,
    :real_name => "Incoming Move Type",
    :type => :Type,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :HealingWish,
    :real_name => "Healing Wish",
    :entry_proc => proc do |battle, _index, position, battler|
        battle.pbCommonAnimation("HealingWish", battler)
        healingMessage = _INTL("The healing wish came true for {1}!", battler.pbThis(true))
        battler.pbRecoverHP(battler.totalhp, true, true, true, healingMessage)
        battler.pbCureStatus(false)
        position.disableEffect(:HealingWish)
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :LunarDance,
    :real_name => "Lunar Dance",
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        battle.pbCommonAnimation("LunarDance", battler)
        healingMessage = _INTL("The healing wish came true for {1}!", battler.pbThis(true))
        battler.pbRecoverHP(battler.totalhp, true, true, true, healingMessage)
        battler.pbCureStatus(false)
        battler.eachMove { |m| m.pp = m.total_pp }
        position.disableEffect(:LunarDance)
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :Wish,
    :real_name => "Turns Till Wish",
    :type => :Integer,
    :ticks_down => true,
    :swaps_with_battlers => true,
    :expire_proc => proc do |battle, index, position, battler|
        if battler.canHeal?
            wishMaker = battle.pbThisEx(index, position.effects[:WishMaker])
            healingMessage = _INTL("{1}'s wish came true!", wishMaker)
            battler.pbRecoverHP(position.effects[:WishAmount], true, true, true, healingMessage)
        end
    end,
    :sub_effects => %i[WishAmount WishMaker],
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :WishAmount,
    :real_name => "Wish Heal Amount",
    :type => :Integer,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :WishMaker,
    :real_name => "Wish Maker",
    :type => :PartyPosition,
    :info_displayed => false,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :Refuge,
    :real_name => "Refuge",
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        battle.pbCommonAnimation("HealingWish", battler)
        refugeMaker = battle.pbThisEx(battler.index, position.effects[:Refuge])
        battle.pbDisplay(_INTL("{1}'s refuge comforts {2}!", refugeMaker, battler.pbThis(true)))
        battler.pbCureStatus(false)
        position.disableEffect(:Refuge)
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :PassingAbility,
    :real_name => "PassingAbility",
    :info_displayed => false,
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        if battler.hasActiveAbility?(:LONGRECEIVER)
            abilityPasser = battler.ownerParty[position.effects[:PassingAbility]]
            if abilityPasser
                abilityPasserName = battle.pbThisEx(battler.index, position.effects[:PassingAbility])
                unless battler.hasAbility?(abilityPasser.ability) || GameData::Ability.get(abilityPasser.ability).is_uncopyable_ability?
                    battler.showMyAbilitySplash(:LONGRECEIVER)
                    battle.pbDisplay(_INTL("{1} passes its ability to {2}!", abilityPasserName, battler.pbThis(true)))
                    battler.hideMyAbilitySplash
                    battler.addAbility(abilityPasser.ability,true)
                    position.disableEffect(:PassingAbility)
                end
            end
        end
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :PassingStats,
    :real_name => "PassingStats",
    :info_displayed => false,
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        if battler.hasActiveAbility?(:OVERFLOWINGHEART)
            statPasser = battler.ownerParty[position.effects[:PassingStats]]
            if statPasser
                statPasserName = battle.pbThisEx(battler.index, position.effects[:PassingStats])
                unless battler.hasAbility?(statPasser.ability)
                    battler.showMyAbilitySplash(:OVERFLOWINGHEART)
                    battle.pbDisplay(_INTL("{2} reads {1}'s heart and gains its stats!", statPasserName, battler.pbThis(true)))
                    battler.applyEffect(:BaseAttack,statPasser.attack)
                    battler.applyEffect(:BaseDefense,statPasser.defense)
                    battler.applyEffect(:BaseSpecialAttack,statPasser.spatk)
                    battler.applyEffect(:BaseSpecialDefense,statPasser.spdef)
                    battler.applyEffect(:BaseSpeed,statPasser.speed)
                    position.disableEffect(:PassingStats)
                    battler.hideMyAbilitySplash
                end
            end
        end
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :Kickback,
    :real_name => "Kickback",
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        cushionAssisted = battle.pbThisEx(battler.index, position.effects[:Kickback])
        battle.pbDisplay(_INTL("{1}'s cushions the blow for {2}!", battler.pbThis(true), cushionAssisted))
        battler.applyRecoilDamage(position.effects[:KickbackAmount], true, false, nil, true)
        position.disableEffect(:Kickback)
    end,
    :sub_effects => [:KickbackAmount],
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :KickbackAmount,
    :real_name => "Kickback Amount",
    :type => :Integer,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :StormTrail,
    :real_name => "Storm Trail",
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        sourceMaker = battle.pbThisEx(battler.index, position.effects[:StormTrail])
        battle.pbDisplay(_INTL("{1} was powered up by the trail of stormy energy left by {2}!", battler.pbThis(true), sourceMaker))
        battler.tryRaiseStat(:SPEED, battler, showFailMsg: true)
        position.disableEffect(:StormTrail)
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :MistTrail,
    :real_name => "Mist Trail",
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        sourceMaker = battle.pbThisEx(battler.index, position.effects[:MistTrail])
        battle.pbDisplay(_INTL("{1} was enwrapped by the trail of mist left by {2}!", battler.pbThis(true), sourceMaker))
        battler.pbRaiseMultipleStatSteps(DEFENDING_STATS_1, battler, showFailMsg: true)
        position.disableEffect(:MistTrail)
    end,
})

GameData::BattleEffect.register_effect(:Position, {
    :id => :MagmaTrail,
    :real_name => "Magma Trail",
    :type => :PartyPosition,
    :swaps_with_battlers => true,
    :entry_proc => proc do |battle, _index, position, battler|
        sourceMaker = battle.pbThisEx(battler.index, position.effects[:MagmaTrail])
        battle.pbDisplay(_INTL("{1} was enraged by the trail of magma left by {2}!", battler.pbThis(true), sourceMaker))
        battler.pbRaiseMultipleStatSteps(ATTACKING_STATS_1, battler, showFailMsg: true)
        position.disableEffect(:MagmaTrail)
    end,
})