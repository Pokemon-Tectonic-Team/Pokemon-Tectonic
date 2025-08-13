#===============================================================================
# Increases the user's Attack and accuracy by 3 steps each. (Hone Claws)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkAcc3 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 3, :ACCURACY, 3]
    end
end

#===============================================================================
# Increases the user's Attack and Defense by 2 steps each. (Bulk Up)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkDef2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :DEFENSE, 2]
    end
end

# Empowered Bulk Up
class PokeBattle_Move_EmpoweredBulkUp < PokeBattle_Move_RaiseUserAtkDef2
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        @battle.pbDisplay(_INTL("{1} gained a massive amount of mass!", user.pbThis))
        user.incrementEffect(:WeightChange, 1000)
        transformType(user, :FIGHTING)
    end
end

#===============================================================================
# User's Attack and Defense are raised by two steps each, and (Built Different)
# changes user's type to Rock.
#===============================================================================
class PokeBattle_Move_RaiseUserAtkDef2SetUserTypesToRock < PokeBattle_Move_RaiseUserAtkDef2
    def pbMoveFailed?(user, targets, show_message)
        return false if GameData::Type.exists?(:ROCK) && !user.pbHasType?(:ROCK) && user.canChangeType?
        super
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:Type3, :ROCK)
    end
end

#===============================================================================
# Raises Attack and Defense by 2 steps, and Crit Chance by 1.
# (Art of War)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkDef2CriticalHitRate1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :DEFENSE, 2]
	end

	def pbMoveFailed?(user, _targets, show_message)
        return super if user.effectAtMax?(:RaisedCritChance) 
        return false
    end

	def pbEffectGeneral(user)
		super
		user.incrementEffect(:RaisedCritChance, 1) unless user.effectAtMax?(:RaisedCritChance)
    end

    def getEffectScore(user, _target)
        score = super
        score += getCriticalRateBuffEffectScore(user, 2)
        return score
    end
end

#===============================================================================
# Increases the user's Attack, Defense and accuracy by 2 steps each. (Coil)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkDefAcc2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :DEFENSE, 2, :ACCURACY, 2]
    end
end

#===============================================================================
# Increases the user's Attack and Sp. Def by 2 step each. (Flow State)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpDef < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :SPECIAL_DEFENSE, 2]
    end
end

# Empowered Flow State
class PokeBattle_Move_EmpoweredFlowState < PokeBattle_MultiStatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 1, :SPECIAL_DEFENSE, 1]
    end

    def pbEffectGeneral(user)
        super

        user.applyEffect(:EmpoweredFlowState)

        transformType(user, :WATER)
    end
end

#===============================================================================
# Increases the user's Attack, Sp. Def and accuracy by 2 steps each. (Grounding)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpDefAcc2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :SPECIAL_DEFENSE, 2, :ACCURACY, 2]
    end
end

#===============================================================================
# Increases the user's Attack by 2 steps, and Speed by 1. (Dragon Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserAtk2Spd1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :SPEED, 1]
    end
end

# Empowered Dragon Dance
class PokeBattle_Move_60D < PokeBattle_MultiStatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :SPEED, 2]
    end

    def pbEffectGeneral(user)
        super
        transformType(user, :DRAGON)
    end
end

#===============================================================================
# Increases the user's Attack and Speed by 2 steps each. (Shift Gear)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpd2 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end

    def initialize(battle, move)
        super
        @statUp = [:SPEED, 2, :ATTACK, 2]
    end
end

#===============================================================================
# Increases the user's Attack and Defense by 2 steps each, and Speed by 1.
# (Shiver Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkDef2Spd1 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end

    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :DEFENSE, 2, :SPEED, 1]
    end
end

# Empowered Shiver Dance
class PokeBattle_Move_EmpoweredShiverDance < PokeBattle_MultiStatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 2, :DEFENSE, 2, :SPEED, 2]
    end

    def pbEffectGeneral(user)
        super
        transformType(user, :ICE)
    end
end

#===============================================================================
# Increases the user's Attack and Special Attack by 1 steps each.
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpAtk1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = ATTACKING_STATS_1
    end
end

#===============================================================================
# Increases the user's Attack and Special Attack by 2 steps each. (Work Up)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpAtk2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = ATTACKING_STATS_2
    end
end

#===============================================================================
# Increases the user's Attack and Sp. Attack by 2 step eachs.
# In sunny weather, increases are 4 steps each instead. (Growth)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpAtk2Or4InSun < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = ATTACKING_STATS_2
    end

    def pbOnStartUse(_user, _targets)
        if @battle.sunny?
            @statUp = [:ATTACK, 4, :SPECIAL_ATTACK, 4]
        else
            @statUp = ATTACKING_STATS_2
        end
    end

    def shouldHighlight?(_user, _target)
        return @battle.sunny?
    end
end

#===============================================================================
# Increases the user's Attack and Sp. Attack by 2 step eachs.
# In moonglow, also increases the user's Speed by 2 steps. (Scheme)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpAtk2AndSpeed2InMoonglow < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = ATTACKING_STATS_2
    end

    def pbOnStartUse(_user, _targets)
        if @battle.moonGlowing?
            @statUp = [:ATTACK, 1, :SPECIAL_ATTACK, 2, :SPEED, 2]
        else
            @statUp = ATTACKING_STATS_2
        end
    end

    def shouldHighlight?(_user, _target)
        return @battle.moonGlowing?
    end
end

#===============================================================================
# Increases the user's Attack and Sp. Attack by 4 step eachs. (True Senses)
#===============================================================================
class PokeBattle_Move_RaiseUserAtkSpAtk4 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:ATTACK, 4, :SPECIAL_ATTACK, 4]
    end
end

#===============================================================================
# Increases the user's Defense and Special Defense by 1 step each.
#===============================================================================
class PokeBattle_Move_RaiseUserDefSpDef1 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end
    
    def initialize(battle, move)
        super
        @statUp = DEFENDING_STATS_1
    end
end

#===============================================================================
# Increases the user's Defense and Special Defense by 2 steps each.
# (Cosmic Power, Defend Order)
#===============================================================================
class PokeBattle_Move_RaiseUserDefSpDef2 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end
    
    def initialize(battle, move)
        super
        @statUp = DEFENDING_STATS_2
    end
end

#===============================================================================
# Increases the user's Defense and Sp. Def by 1 step. User curls up. (Curl Up)
#===============================================================================
class PokeBattle_Move_RaiseUserDefSpDef1CurlsUp < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end

    def initialize(battle, move)
        super
        @statUp = DEFENDING_STATS_1
    end

    def pbEffectGeneral(user)
        user.applyEffect(:DefenseCurl)
        super
    end
end

#===============================================================================
# Increases the user's defensive stats by 1 step each.
# Charges up user's next attack if it is Electric-type. (Charge)
#===============================================================================
class PokeBattle_Move_RaiseUserDefSpDef1EmpowersNextElectricAttack < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = DEFENDING_STATS_1
    end

    def pbEffectGeneral(user)
        user.applyEffect(:EnergyCharge)
        super
    end

    def getEffectScore(user, target)
        score = super
        user.eachMove do |m|
            next if m.type != :ELECTRIC || !m.damagingMove?
            score += 40
            break
        end
        return score
    end
end

#===============================================================================
# Increases the user's Sp. Atk by 2 steps, and Speed by 1 step. (Lightning Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk2Spd1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPEED, 1]
    end
end

# Empowered Lightning Dance
class PokeBattle_Move_EmpoweredLightningDance < PokeBattle_MultiStatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPEED, 2]
    end

    def pbEffectGeneral(user)
        super
        transformType(user, :ELECTRIC)
    end
end

#===============================================================================
# Increases the user's Speed and Sp. Atk by 2 steps. (Frolic)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtk2Spd2 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end

    def initialize(battle, move)
        super
        @statUp = [:SPEED, 2, :SPECIAL_ATTACK, 2]
    end
end

#===============================================================================
# Raises the user's Sp. Attack and Sp. Defense by 2 steps each, and Speed by 1.
# (Quiver Dance)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkSpDef2Spd1 < PokeBattle_MultiStatUpMove
    def aiAutoKnows?(pokemon); return true; end

    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPECIAL_DEFENSE, 2, :SPEED, 1]
    end
end

# Empowered Quiver Dance
class PokeBattle_Move_EmpoweredQuiverDance < PokeBattle_MultiStatUpMove
    include EmpoweredMove

    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPECIAL_DEFENSE, 2, :SPEED, 2]
    end

    def pbEffectGeneral(user)
        super
        transformType(user, :BUG)
    end
end

#===============================================================================
# Increases the user's Sp. Atk and accuracy by 3 steps each.
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkAcc3 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 3, :ACCURACY, 3]
    end
end

#===============================================================================
# Raises the user's Sp. Attack and Sp. Defense by 2 step eachs. (Calm Mind)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkSpDef2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPECIAL_DEFENSE, 2]
    end
end

# Empowered Calm Mind
class PokeBattle_Move_EmpoweredCalmMind < PokeBattle_Move_RaiseUserSpAtkSpDef2
    include EmpoweredMove

    def pbEffectGeneral(user)
        user.pbMaximizeStatStep(:ACCURACY, user, self)
        super
        transformType(user, :PSYCHIC)
    end
end

#===============================================================================
# Increases Sp. Atk and Sp. Def by 2 steps, and Crit Chance by 1 step.
# (Many Blessings)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkSpDef2CriticalHitRate1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPECIAL_DEFENSE, 2]
	end
    
	def pbMoveFailed?(user, _targets, show_message)
        return super if user.effectAtMax?(:RaisedCritChance)
        return false
    end
    
	def pbEffectGeneral(user)
		super
		user.incrementEffect(:RaisedCritChance, 1) unless user.effectAtMax?(:RaisedCritChance)
    end

    def getEffectScore(user, _target)
        score = super
        score += getCriticalRateBuffEffectScore(user, 1)
        return score
    end
end

#===============================================================================
# Increases the user's Sp. Atk, Sp. Def and accuracy by 2 steps each. (Store Fuel)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkSpDefAcc2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :SPECIAL_DEFENSE, 2, :ACCURACY, 2]
    end
end

#===============================================================================
# Increases the user's Sp. Atk and Defense by 2 steps each. (Vanguard)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkDef2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :DEFENSE, 2]
    end
end

#===============================================================================
# Increases the user's Sp. Atk, Defense and accuracy by 2 steps each. (Aerial View)
#===============================================================================
class PokeBattle_Move_RaiseUserSpAtkDefAcc2 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPECIAL_ATTACK, 2, :DEFENSE, 2, :ACCURACY, 2]
    end
end

#===============================================================================
# Raises the user's Attack, Defense, Speed, Special Attack and Special Defense
# by 1 step each. (Ancient Power, Ominous Wind, Silver Wind)
#===============================================================================
class PokeBattle_Move_RaiseUserMainStats1 < PokeBattle_MultiStatUpMove
    def initialize(battle, move)
        super
        @statUp = ALL_STATS_1
    end
end

# Empowered Ancient Power
class PokeBattle_Move_EmpoweredAncientPower < PokeBattle_Move_RaiseUserMainStats1
    include EmpoweredMove
end

#===============================================================================
# Raises all stats by 2 steps. Fails unless the user is asleep. (Oneiromancy)
#===============================================================================
class PokeBattle_Move_RaiseUserMainStats2IfAsleep < PokeBattle_MultiStatUpMove
    def usableWhenAsleep?; return true; end

    def initialize(battle, move)
        super
        @statUp = ALL_STATS_2
    end

    def pbMoveFailed?(user, targets, show_message)
        unless user.asleep?
            @battle.pbDisplay(_INTL("But it failed, since {1} isn't asleep!", user.pbThis(true))) if show_message
            return true
        end
        super
    end
end

#===============================================================================
# All stats raised by 2 steps. Fails unless an opponent is below half life.
# (Gloat)
#===============================================================================
class PokeBattle_Move_RaiseUserMainStats2IfFoeBelowHalf < PokeBattle_MultiStatUpMove
	def initialize(battle, move)
        super
        @statUp = ALL_STATS_2
    end
	
	def pbMoveFailed?(user, targets, show_message)
        anyOppLow = false
        user.eachOpposing do |b|
            next if b.aboveHalfHealth?
            anyOppLow = true
            break
        end
        unless anyOppLow
            @battle.pbDisplay(_INTL("But it failed, since there were no foes below half health!")) if show_message
            return true
        end
        super
    end
end

#===============================================================================
# All stats raised by 2 steps. Fails if the attack was not used the turn after a foe fainted.
# (Foxtrot Finale)
#===============================================================================
class PokeBattle_Move_RaiseUserMainStats2IfFoeFaintedLastTurn < PokeBattle_MultiStatUpMove
	def initialize(battle, move)
        super
        @statUp = ALL_STATS_2
    end
	
	def pbMoveFailed?(user, targets, show_message)
        unless user.pbOpposingSide.faintLastRound?
            @battle.pbDisplay(_INTL("But it failed, since there was no victory to celebrate!")) if show_message
            return true
        end
        super
    end
end

#===============================================================================
# Raises worst stat four steps, second worst stat by two steps. (Breakdance)
#===============================================================================
class PokeBattle_Move_RaiseUserWorstStat4SecondWorstStat2 < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        @statArray = []
        GameData::Stat.each_main_battle do |statData|
            statID = statData.id
            @statArray.push(statID) if user.pbCanRaiseStatStep?(statID, user, self)
        end
        if @statArray.length == 0
            @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!", user.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        statsUserCanRaise = user.finalStats.select do |stat, _finalValue|
            next user.pbCanRaiseStatStep?(stat, user, self)
        end
        statsRanked = statsUserCanRaise.sort_by { |_s, v| v }
        user.tryRaiseStat(statsRanked[0][0], user, increment: 3, move: self) if statsRanked.length > 0
        user.tryRaiseStat(statsRanked[1][0], user, increment: 3, move: self) if statsRanked.length > 1
    end

    # TODO
    def getEffectScore(user, _target)
        score = 100
        score += 20 if user.firstTurn?
        GameData::Stat.each_main_battle do |statData|
            score -= user.steps[statData.id] * 5
        end
        return score
    end
end

#===============================================================================
# If the move misses, the user gains Accuracy and Speed. (Joust)
#===============================================================================
class PokeBattle_Move_RaiseUserAccSpd1IfMisses < PokeBattle_Move
    # This method is called if a move fails to hit all of its targets
    def pbCrashDamage(user)
        return unless user.pbRaiseMultipleStatSteps([:ACCURACY, 1, :SPEED, 1], user, move: self)
        @battle.pbDisplay(_INTL("{1} circles back around for a retry!", user.pbThis))
    end

    def getEffectScore(user, _target)
        return getMultiStatUpEffectScore([:ACCURACY, 1, :SPEED, 1], user, user) * 0.5
    end
end

#===============================================================================
# Increases Speed by 2 steps and Crit Chance by 2 steps. (Deep Breathing)
#===============================================================================
class PokeBattle_Move_RaiseUserSpd2CriticalHitRate2 < PokeBattle_StatUpMove
    def initialize(battle, move)
        super
        @statUp = [:SPEED, 2]
    end

    def pbMoveFailed?(user, _targets, show_message)
        if user.effectAtMax?(:RaisedCritChance)
            return super
        end
        return false
    end

    def pbEffectGeneral(user)
        super
        user.incrementEffect(:RaisedCritChance, 2)
    end

    def getEffectScore(user, _target)
        score = super
        score += getCriticalRateBuffEffectScore(user, 2)
        return score
    end
end

# Empowered Deep Breathing
class PokeBattle_Move_EmpoweredDeepBreathing < PokeBattle_Move_RaiseUserSpd2CriticalHitRate2
    include EmpoweredMove
end