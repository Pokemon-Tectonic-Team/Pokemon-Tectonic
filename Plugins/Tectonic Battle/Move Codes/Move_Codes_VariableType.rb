#===============================================================================
# Type changes depending on the weather. (Weather Burst)
#===============================================================================
class PokeBattle_Move_TypeDependsOnWeather < PokeBattle_Move
    def aiAutoKnows?(pokemon); return true; end

    def immuneToRainDebuff?; return true; end
    def immuneToSunDebuff?; return true; end
    
    def shouldHighlight?(_user, _target)
        return @battle.pbWeather != :None
    end

    def pbBaseType(_user)
        ret = :NORMAL
        case @battle.pbWeather
        when :Sunshine, :HarshSun
            ret = :FIRE if GameData::Type.exists?(:FIRE)
        when :Rainstorm, :HeavyRain
            ret = :WATER if GameData::Type.exists?(:WATER)
        when :Sandstorm, :StarStorm
            ret = :ROCK if GameData::Type.exists?(:ROCK)
        when :Hail, :IceAge
            ret = :ICE if GameData::Type.exists?(:ICE)
        when :Eclipse, :RingEclipse
            ret = :PSYCHIC if GameData::Type.exists?(:PSYCHIC)
        when :Moonglow, :BloodMoon
            ret = :FAIRY if GameData::Type.exists?(:FAIRY)
        when :StrongWinds
            ret = :FLYING if GameData::Type.exists?(:FLYING)
        end
        return ret
    end

    # def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    #     t = pbBaseType(user)
    #     hitNum = 1 if t == :FIRE # Type-specific anims
    #     hitNum = 2 if t == :WATER
    #     hitNum = 3 if t == :ROCK
    #     hitNum = 4 if t == :ICE
    #     super
    # end
end

#===============================================================================
# Type depends on the user's held item. (Judgment, Multi-Attack, Techno Blast)
#===============================================================================
class PokeBattle_Move_TypeDependsOnUserSpecialItem < PokeBattle_Move
    def initialize(battle, move)
        super
        if @id == :TECHNOBLAST
            @itemTypes = {
                :SHOCKDRIVE => :ELECTRIC,
                :BURNDRIVE  => :FIRE,
                :CHILLDRIVE => :ICE,
                :DOUSEDRIVE => :WATER,
            }
        end
    end

    def pbBaseType(user)
        ret = :NORMAL
        if user.itemActive?
            if @id == :TECHNOBLAST
                @itemTypes.each do |item, itemType|
                    next unless user.hasItem?(item)
                    ret = itemType if GameData::Type.exists?(itemType)
                    break
                end
            elsif @id == :MULTIATTACK && user.hasItem?(:MEMORYSET)
                return user.itemTypeChosen
            elsif @id == :JUDGMENT && user.hasItem?(:PRISMATICPLATE)
                return user.itemTypeChosen
            end
        end
        return ret
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        if @id == :TECHNOBLAST # Type-specific anim
            t = pbBaseType(user)
            hitNum = 0
            hitNum = 1 if t == :ELECTRIC
            hitNum = 2 if t == :FIRE
            hitNum = 3 if t == :ICE
            hitNum = 4 if t == :WATER
        end
        super
    end
    
    def pbEffectAfterAllHits(user, target)
        if @id == :TECHNOBLAST
            @itemTypes.keys.each do |driveItem|
                user.aiLearnsItem(driveItem)
            end
        end
    end
end

#===============================================================================
# Changes type to match the user's Gem, Plate, or Crystal Veil. (Prismatic Power)
#===============================================================================
class PokeBattle_Move_TypeDependsOnUserGemPlateVeil < PokeBattle_Move
    def pbBaseType(user)
        ret = :NORMAL
        if user.hasActiveItem?(%i[CRYSTALVEIL PRISMATICPLATE])
            ret = user.itemTypeChosen
        elsif user.hasGem?
            user.eachActiveItem do |itemID|
                next unless GameData::Item.get(itemID).is_gem?
                typeName = itemID.to_s
                typeName.gsub!("GEM","")
                typeName.gsub!("RING","")
                ret = typeName.to_sym
                break
            end
        end
        return ret
    end
end

#===============================================================================
# This move's type is the same as the user's first type. (Revelation Dance)
#===============================================================================
class PokeBattle_Move_TypeIsUserFirstType < PokeBattle_Move
    def pbBaseType(user)
        userTypes = user.pbTypes(true)
        return userTypes[0]
    end
end