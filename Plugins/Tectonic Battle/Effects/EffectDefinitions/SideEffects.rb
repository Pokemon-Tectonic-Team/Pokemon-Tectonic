##########################################
# Team combo effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :EchoedVoiceCounter,
    :real_name => "Echoed Voice Counter",
    :type => :Integer,
    :maximum => 5,
    :court_changed => false,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :EchoedVoiceUsed,
    :real_name => "Echoed Voice Used",
    :resets_eor => true,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Round,
    :real_name => "Round Singers",
    :resets_eor => true,
})

##########################################
# Screens
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Reflect,
    :real_name => "Reflect",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Defense is raised! This will last for {2} more turns!", teamName, value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Reflect was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Reflect wore off.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :LightScreen,
    :real_name => "Light Screen",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Sp. Def is raised! This will last for {2} more turns!", teamName, value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Light Screen was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Light Screen wore off.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :AuroraVeil,
    :real_name => "Aurora Veil",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Defense and Sp. Def are raised! This will last for {2} more turns!",
teamName, value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Aurora Veil was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Aurora Veil wore off!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :RepulsionField,
    :real_name => "Repulsion Field",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} takes less damage from moves with 100+ base power! This will last for {2} more turns!",
teamName, value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Repulsion Field was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Repulsion Field wore off!", teamName))
    end,
})

##########################################
# Misc. immunity effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :LuckyChant,
    :real_name => "Lucky Chant",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} is now blessed!", teamName))
        battle.pbDisplay(_INTL("They'll be protected from critical hits for {1} more turns!", teamName, value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Lucky Chant was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Lucky Chant.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Mist,
    :real_name => "Mist",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} is shrouded in mist!", teamName))
        battle.pbDisplay(_INTL("Their stats can't be lowered for {1} more turns!", value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Mist was swept away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Mist.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Safeguard,
    :real_name => "Safeguard",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} became cloaked in a mystical veil!", teamName))
        battle.pbDisplay(_INTL("They'll be protected from status ailments for {1} more turns!", value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Safeguard was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Safeguard.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :DiamondField,
    :real_name => "Diamond Field",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} is protected by a diamond sheen!", teamName))
        battle.pbDisplay(_INTL("They can't be crit and take less damage for {1} more turns!", value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Diamond Field was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Diamond Field.", teamName))
    end,
})


GameData::BattleEffect.register_effect(:Side, {
    :id => :NaturalProtection,
    :real_name => "Natural Protection",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} became determined to survive!", teamName))
        battle.pbDisplay(_INTL("They'll take half damage from sources that aren't attacks for {1} more turns!", value - 1))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Natural Protection was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer inspired by Natural Protection.", teamName))
    end,
})

##########################################
# Temporary full side protecion effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :CraftyShield,
    :real_name => "Crafty Shield",
    :resets_eor => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Crafty Shield protected {1}!", teamName))
    end,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, move, _battle|
            move.statusMove? && !move.pbTarget(user).targets_all
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :MatBlock,
    :real_name => "Mat Block",
    :resets_eor => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("The kicked up mat will block attacks against {1} this turn!", teamName))
    end,
    :protection_info => {
        :does_negate_proc => proc do |_user, _target, move, _battle|
            move.damagingMove?
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :QuickGuard,
    :real_name => "Quick Guard",
    :resets_eor => true,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, _move, battle|
            # Checking the move priority saved from pbCalculatePriority
            battle.choices[user.index][4] > 0
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :WideGuard,
    :real_name => "Wide Guard",
    :resets_eor => true,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, move, _battle|
            move.pbTarget(user).num_targets > 1
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Quarantine,
    :real_name => "Quarantine",
    :resets_eor => true,
    :protection_info => {
        :hit_proc => proc do |user, target, move, battle|
            user.applyEffect(:Disable,3) if user.canBeDisabled?(true,move)
        end,
        :does_negate_proc => proc do |_user, _target, move, _battle|
            move.statusMove?
        end,
    },
})

##########################################
# Pledge combo effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Rainbow,
    :real_name => "Rainbow Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A rainbow appeared in the sky above {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The rainbow on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The rainbow on {1}'s side dissapeared.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :SeaOfFire,
    :real_name => "Sea of Fire Turns",
    :type => :Integer,
    :ticks_down => true,
    :remain_proc => proc do |battle, side, _teamName|
        battle.pbCommonAnimation("SeaOfFire") if side.index == 0
        battle.pbCommonAnimation("SeaOfFireOpp") if side.index == 1
        battle.eachBattler do |b|
            next if b.opposes?(side.index)
            next if !b.takesIndirectDamage? || b.pbHasType?(:FIRE)
            battle.pbDisplay(_INTL("{1} is hurt by the sea of fire!", b.pbThis))
            b.applyFractionalDamage(1.0 / 8.0)
        end
    end,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A sea of fire enveloped {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sea of fire on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sea of fire on {1}'s side dissapeared.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Swamp,
    :real_name => "Swamp Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A swamp enveloped {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The swamp on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The swamp on {1}'s side dissapeared.", teamName))
    end,
})

##########################################
# Hazards
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Spikes,
    :real_name => "Spikes",
    :type => :Integer,
    :maximum => 3,
    :is_hazard => true,
    :is_spike => true,
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Spikes around {1}'s feet were swept aside!", teamName))
        side.applyEffect(:SpikesRemovedThisTurn)
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :SpikesRemovedThisTurn,
    :real_name => "Spikes Removed",
    :info_displayed => false,
    :resets_eor => true,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :PoisonSpikes,
    :real_name => "Poison Spikes",
    :type => :Integer,
    :maximum => 2,
    :is_spike => true,
    :status_applying_hazard => {
        :status => :POISON,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:POISON)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Poison Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Poison Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Poison Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FlameSpikes,
    :real_name => "Flame Spikes",
    :type => :Integer,
    :maximum => 2,
    :is_spike => true,
    :status_applying_hazard => {
        :status => :BURN,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:FIRE)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Flame Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Flame Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Flame Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FrostSpikes,
    :real_name => "Frost Spikes",
    :type => :Integer,
    :maximum => 2,
    :is_spike => true,
    :is_hazard => true,
    :status_applying_hazard => {
        :status => :FROSTBITE,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:ICE)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Frost Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Frost Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Frost Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :StealthRock,
    :real_name => "Stealth Rock",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The pointed stones around {1} were removed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FeatherWard,
    :real_name => "Feather Ward",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Sharp feathers float in the air around {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sharp feathers around {1} were removed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :LiveWire,
    :real_name => "Live Wire",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("A live wire was set on the ground around {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The live wire near {1} was removed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :StickyWeb,
    :real_name => "Sticky Web",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A sticky web has been laid out beneath {1}'s feet!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sticky web beneath {1}'s feet was removed!", teamName))
    end,
})

##########################################
# Totem effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :MisdirectingFog,
    :real_name => "Misdirecting Fog",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("A fog covered {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The fog on {1}'s side was dispelled!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The fog on {1}'s side dissipated.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :PrimalForest,
    :real_name => "Primal Forest",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("A primal forest surrounded {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The primal forest on {1}'s side was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The primal forest on {1}'s side shriveled up.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :CruelCocoon,
    :real_name => "Cruel Cocoon",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("{1} was enclosed in a cocoon of scales!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The cocoon enclosing {1}'s side was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The cocoon enclosing {1}'s side dried up.", teamName))
    end,
    :eor_proc => proc do |battle, side, _teamName, value|
        battle.eachSameSideBattler(side.index) do |b|
            healingMessage = _INTL("{1} was healed by the cruel cocoon at the expense of its PP!", b.pbThis)
            b.applyFractionalHealing(1.0/8.0, customMessage: healingMessage)
            b.eachMove do |m|
                next if m.pp <= 0
                b.pbSetPP(m, m.pp - 1)
            end
        end
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :TurbulentSky,
    :real_name => "Turbulent Sky",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("A turbulent sky appeared above {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The turbulent sky above {1}'s side was calmed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("The turbulent sky above {1}'s side calmed down.", teamName))
    end,
})

##########################################
# Internal Tracking
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :LastRoundFainted,
    :real_name => "Last Round Fainted",
    :type => :Integer,
    :default => -1,
    :info_displayed => false,
    :court_changed => false,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :TyrannicalImmunity,
    :real_name => "Spent Tyrannical Immunity",
    :info_displayed => false,
    :court_changed => false,
})

##########################################
# Other
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Tailwind,
    :real_name => "Tailwind Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("A Tailwind blew from behind {1}!", teamName))
        if value > 99
            battle.pbDisplay(_INTL("It will last forever!"))
        else
            battle.pbDisplay(_INTL("It will last for {1} more turns!", value - 1))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Tailwind was stopped!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Tailwind petered out.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :EmpoweredTailwind,
    :real_name => "Primeval Tailwind",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        teamName = teamName.downcase
        battle.pbDisplay(_INTL("A Primeval Tailwind blew from behind {1}!", teamName))
        if value > 99
            battle.pbDisplay(_INTL("It will last forever!"))
        else
            battle.pbDisplay(_INTL("It will last for {1} more turns!", value - 1))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Primeval Tailwind was stopped!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Primeval Tailwind petered out.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :EmpoweredEmbargo,
    :real_name => "Items Supressed",
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("{1} can no longer use items!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Bulwark,
    :real_name => "Bulwark",
    :resets_eor => true,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :ErodedRock,
    :real_name => "Eroded Rocks",
    :type => :Integer,
    :maximum => 4,
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        battle.pbDisplay(_INTL("A rock lands on the ground around {1}.", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("Each rock on the ground around {1} was absorbed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :PerennialPayload,
    :real_name => "Perennial Payload",
    :type => :Hash,
    :eor_proc => proc do |battle, side, _teamName, value|
        value.each_key do |key|
            value[key] -= 1
            pkmn = battle.pbParty(side.index)[key]
            if pkmn
                if value[key] <= 0
                    # Revive the pokemon
                    pkmn.heal_HP
                    pkmn.heal_status
                    battle.pbDisplay(_INTL("{1} recovered all the way to full health!", pkmn.name))
                    value[key] = nil
                else
                    battle.pbDisplay(_INTL("{1} is regrowing.", pkmn.name))
                end
            end
        end
        value.compact!
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Traumatized,
    :real_name => "Traumatized",
    :info_displayed => false,
    :type => :Hash,
    :entry_proc => proc do |battle, battlerIndex, side, battler, value|
        echoln(value.to_s)
        if value.key?(battler.pokemonIndex)
            statHash = value[battler.pokemonIndex]
            echoln(statHash.to_s)
            statDown = []
            statHash.each do |key, value|
                next unless value > 0
                statDown.push(key)
                statDown.push(value)
            end
            echoln(statDown.to_s)
            unless statDown.empty?
                battle.pbDisplay(_INTL("{1} remembers its fears!", battler.pbThis))
                battler.pbLowerMultipleStatSteps(statDown, nil)
            end
        end
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :PayDay,
    :real_name => "Money Dropped",
    :type => :Integer,
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        battle.pbDisplay(_INTL("{1} coins were scattered to the ground!", increment))
    end,
})