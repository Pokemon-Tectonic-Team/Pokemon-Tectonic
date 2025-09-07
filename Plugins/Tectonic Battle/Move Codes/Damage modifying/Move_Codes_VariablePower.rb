#===============================================================================
# Power increases with the user's HP. (Eruption, Water Spout, Dragon Energy)
#===============================================================================
class PokeBattle_Move_ScalesWithUserHP < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, _target)
        # From 65 to 130 in increments of 5, Overhealed caps at 195
        hpFraction = user.hp / user.totalhp.to_f
        hpFraction = 0.5 if hpFraction < 0.5
        hpFraction = 1.5 if hpFraction > 1.5
        basePower = (26 * hpFraction).floor * 5
        return basePower
    end
	
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the more HP the user has left. Affected by Overhealing.")
        detailsList << _INTL("Range 65-195")
        detailsList << _INTL("<u>50% HP:</u> 65 BP")
        detailsList << _INTL("<u>75% HP:</u> 95 BP")
        detailsList << _INTL("<u>100% HP:</u> 130 BP")
        detailsList << _INTL("<u>125% HP:</u> 160 BP")
        detailsList << _INTL("<u>150% HP:</u> 195 BP")
    end
	
end

#===============================================================================
# Power increases with the target's HP. (Crush Grip, Wring Out)
#===============================================================================
class PokeBattle_Move_ScalesWithTargetHP < PokeBattle_Move
    def pbBaseDamage(_baseDmg, _user, target)
        # From 20 to 120 in increments of 5
        basePower = (20 * target.hp.to_f / target.totalhp.to_f).floor * 5
        basePower += 20
        return basePower
    end
end

#===============================================================================
# Power increases the quicker the target is than the user. (Gyro Ball, Sugar Ball)
#===============================================================================
class PokeBattle_Move_ScalesSlowerThanTarget < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, target)
        ratio = target.pbSpeed.to_f / user.pbSpeed.to_f
        basePower = 5 * (5 * ratio).floor
        basePower = 150 if basePower > 150
        basePower = 40 if basePower < 40
        return basePower
    end
	
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the slower the user is compared to the target. Range 40-150")
        detailsList << _INTL("<u>1/2 of the target's speed:</u> 50 BP")
        detailsList << _INTL("<u>1/3 of the target's speed:</u> 75 BP")
        detailsList << _INTL("<u>1/4 of the target's speed:</u> 100 BP")
        detailsList << _INTL("<u>1/5 of the target's speed:</u> 125 BP")
        detailsList << _INTL("<u>1/6 of the target's speed:</u> 150 BP")
    end
	
end

#===============================================================================
# Power increases with the user's positive stat changes (ignores negative ones). (Rising Power)
# (after applying stat steps)
#===============================================================================
class PokeBattle_Move_ScalesUsersPositiveStatSteps < PokeBattle_Move
    def pbBaseDamage(baseDmg, user, _target)
        mult = 0
        GameData::Stat.each_battle { |s| mult += user.steps[s.id] if user.steps[s.id] > 0 }
        return baseDmg + 10 * mult
    end
end

#===============================================================================
# Power increases with the target's positive stat changes (ignores negative ones).
# (Punishment)
#===============================================================================
class PokeBattle_Move_ScalesTargetsPositiveStatSteps < PokeBattle_Move
    def pbBaseDamage(_baseDmg, _user, target)
        mult = 3
        GameData::Stat.each_battle { |s| mult += target.steps[s.id] if target.steps[s.id] > 0 }
        return [10 * mult, 200].min
    end
end

#===============================================================================
# Power increases the less PP this move has.
#===============================================================================
class PokeBattle_Move_ScalesWithLostPP < PokeBattle_Move
    def pbBaseDamage(_baseDmg, _user, _target)
        dmgs = [200, 160, 120, 80, 40]
        ppLeft = [@pp, dmgs.length - 1].min # PP is reduced before the move is used
        return dmgs[ppLeft]
    end

    def shouldHighlight?(_user, _target)
        return @pp == 1
    end
end

#===============================================================================
# Power increases the less HP the user has. (Flail, Shiver Squirm)
#===============================================================================
def flailBasePowerFormula(ratio)
    return [(20 / ((ratio * 5)**0.75)).floor * 5,200].min
end

class PokeBattle_Move_ScalesWithLostHP < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, _target)
        ratio = user.hp.to_f / user.totalhp.to_f
        return flailBasePowerFormula(ratio)
    end
	
    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the lower the user's HP is. Range 25-200")
        detailsList << _INTL("<u>100% HP:</u> 25 BP")
        detailsList << _INTL("<u>50% HP:</u> 50 BP")
        detailsList << _INTL("<u>30% HP:</u> 70 BP")
        detailsList << _INTL("<u>20% HP:</u> 100 BP")
        detailsList << _INTL("<u>15% HP:</u> 120 BP")
        detailsList << _INTL("<u>10% HP:</u> 165 BP")
        detailsList << _INTL("<u>7.5% HP:</u> 200 BP")
    end
end

#===============================================================================
# Power increases the quicker the user is than the target. (Electro Ball, Hunt Down)
#===============================================================================
class PokeBattle_Move_ScalesFasterThanTarget < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, target)
        ratio = user.pbSpeed.to_f / target.pbSpeed.to_f
        basePower = 10 + (7 * ratio).floor * 5
        basePower = 150 if basePower > 150
        basePower = 40 if basePower < 40
        return basePower
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the faster the user is compared to the target. Range 40-150")
        detailsList << _INTL("<u>Slower than target:</u> 40 BP")
        detailsList << _INTL("<u>Same Speed as target:</u> 45 BP")
        detailsList << _INTL("<u>1.5x faster than target:</u> 60 BP")
        detailsList << _INTL("<u>2x faster than target:</u> 80 BP")
        detailsList << _INTL("<u>3x faster than target:</u> 115 BP")
        detailsList << _INTL("<u>4x faster than target:</u> 150 BP")
    end
end

#===============================================================================
# Power increases the heavier the target is. (Grass Knot, Ghostly Grasp)
#===============================================================================
class PokeBattle_Move_ScalesTargetsWeight < PokeBattle_Move
    def pbBaseDamage(baseDmg, user, target)
        ret = baseDmg
        weight = [target.pbWeight / 10,2000].min
        ret += 19 + ((4 * (weight**0.5)) / 5).floor * 5
        return ret
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the heavier the target is. Range 20-195")
        detailsList << _INTL("<u>Less than 2 KG:</u> 20 BP")
        detailsList << _INTL("<u>2 - 6.9 KG:</u> 25 BP")
        detailsList << _INTL("<u>57 - 77 KG:</u> 50 BP")
        detailsList << _INTL("<u>400 - 450 KG:</u> 100 BP")
        detailsList << _INTL("<u>900 - 950 KG:</u> 140 BP")
        detailsList << _INTL("<u>>1000 KG:</u> 160 BP")
    end
end

#===============================================================================
# Power increases the heavier the user is than the target. (Heat Crash, Heavy Slam)
#===============================================================================
class PokeBattle_Move_ScalesHeavierThanTarget < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, target)
        ret = 40
        ratio = user.pbWeight.to_f / target.pbWeight.to_f
        ratio = 10 if ratio > 10
        ret += ((16 * (ratio**0.75)) / 5).floor * 5
        return ret
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the heavier the user is compared to the target. Range 40-125")
        detailsList << _INTL("<u>1/5 of target's weight:</u> 40 BP")
        detailsList << _INTL("<u>Same weight as target:</u> 55 BP")
        detailsList << _INTL("<u>2x heavier than target:</u> 65 BP")
        detailsList << _INTL("<u>5x heavier than target:</u> 90 BP")
        detailsList << _INTL("<u>10x heavier than target:</u> 125 BP")
    end
end

#===============================================================================
# Deals 20 extra BP per fainted party member. (From Beyond)
#===============================================================================
class PokeBattle_Move_ScalesFaintedPartyMembers < PokeBattle_Move
    def pbBaseDamage(baseDmg, user, target)
        user.ownerParty.each do |partyPokemon|
            next unless partyPokemon
            next if partyPokemon.personalID == user.personalID
            next unless partyPokemon.fainted?
            baseDmg += 20
        end
        return baseDmg
    end
end

#===============================================================================
# Power increases with the highest allies defense. (Hard Place)
#===============================================================================
class PokeBattle_Move_HardPlace < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, _target)
        highestDefense = 0
        user.eachAlly do |ally_battler|
            real_defense = ally_battler.pbDefense
            highestDefense = real_defense if real_defense > highestDefense
        end
        highestDefense = (highestDefense/5)*5 # Round to nearest 5
        highestDefense = 40 if highestDefense < 40
        highestDefense = 200 if highestDefense > 200
        return highestDefense
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the higher any ally's Defense is. Range 40-200")
        detailsList << _INTL("<u>No ally:</u> 40 BP")
        detailsList << _INTL("<u>Ally Defense 44 or less:</u> 40 BP")
        detailsList << _INTL("<u>Ally Defense 45-49:</u> 45 BP")
        detailsList << _INTL("<u>Ally Defense 100-104:</u> 100 BP")
        detailsList << _INTL("<u>Ally Defense 200 or more:</u> 200 BP")
    end
end

#===============================================================================
# Power increases the taller the user is than the target. (Cocodrop)
#===============================================================================
class PokeBattle_Move_ScalesTallerThanTarget < PokeBattle_Move
    def pbBaseDamage(_baseDmg, user, target)
        ret = 40
        ratio = user.pbHeight.to_f / target.pbHeight.to_f
        ratio = 10 if ratio > 10
        ret += ((16 * (ratio**0.75)) / 5).floor * 5
        return ret
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Does more damage the taller the user is compared to the target. Range 40-125")
        detailsList << _INTL("<u>Target 5x taller than user:</u> 40 BP")
        detailsList << _INTL("<u>Same height as target:</u> 55 BP")
        detailsList << _INTL("<u>2x taller than target:</u> 65 BP")
        detailsList << _INTL("<u>5x taller than target:</u> 90 BP")
        detailsList << _INTL("<u>10x taller than target:</u> 125 BP")
    end
end

#===============================================================================
# Power increases by consuming payday coins. (up to 1000). (Charity)
#===============================================================================
class PokeBattle_Move_ScalesCreatedMoney < PokeBattle_Move
    def initialize(battle, move)
        super
        @coinsToConsume = 0
    end

    def pbOnStartUse(user, targets)
        @coinsToConsume = [user.pbOwnSide.countEffect(:PayDay),1000].min
    end

    def pbBaseDamage(baseDmg, _user, _target)
        baseDmg += (@coinsToConsume / 10).floor
        return baseDmg
    end

    def pbEffectAfterAllHits(user, target)
        beforeCoins = user.pbOwnSide.effects[:PayDay]
        user.pbOwnSide.effects[:PayDay] -= @coinsToConsume
        user.pbOwnSide.effects[:PayDay] = 0 if user.pbOwnSide.effects[:PayDay] < 0
        actualCoinAmountConsumed = beforeCoins - user.pbOwnSide.effects[:PayDay]
        if actualCoinAmountConsumed > 0
            @battle.pbDisplay(_INTL("{1} coins were used in the attack!", actualCoinAmountConsumed))
        else
            @battle.pbDisplay(_INTL("There were no coins to use in the attack...", actualCoinAmountConsumed))
        end
    end
end