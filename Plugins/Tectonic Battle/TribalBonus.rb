class TribalBonus
    attr_reader :tribeCounts
    attr_reader :tribesGivingBonus
    attr_accessor :trainer

    def initialize(trainer)
        @trainer = trainer
        updateTribeCount
    end

    def resetTribeCounts()
        @tribeCounts = {}
        @tribesGivingBonus = []
        # Reset all counts
        GameData::Tribe.each do |tribe|
            next if !$DEBUG && tribe.id.start_with?("DEBUG_") # skip debug tribes if not in debug mode
            @tribeCounts[tribe.id] = 0
        end
    end

    def updateTribeCount()
        resetTribeCounts()

        # Count all tribes that exist for pokemon in player's party
        @trainer.party.each {|pokemon|
            tribes = pokemon.tribes
            tribes.each {|tribe|
                next if !@tribeCounts.has_key?(tribe)
                @tribeCounts[tribe] += 1
            }
        }
        
        GameData::Tribe.each do |tribeData|
            next if !$DEBUG and tribeData.id.start_with?("DEBUG_") # don't check skipped tribes to avoid key errors
            next unless @tribeCounts[tribeData.id] >= tribeData.threshold
            @tribesGivingBonus.push(tribeData.id)
        end
    end

    def getActiveBonusesList(concat = true, foe = false)
        list = []
        @tribesGivingBonus.each do |tribeID|
            description = getTribeName(tribeID)
            description += _INTL(" Tribe") if concat
            list.push(description)
        end

        return list
    end

    def self.initStatBonusHash
        newBonusHash = {
            :HP => 0,
            :ATTACK => 0,
            :DEFENSE => 0,
            :SPECIAL_ATTACK => 0,
            :SPECIAL_DEFENSE => 0,
            :SPEED => 0,
        }
        return newBonusHash
    end

    def getTribeBonusStats(battler)
        # Returns a hash of all bonuses given the current pokemon
        tribeBonuses = TribalBonus.initStatBonusHash

        level = battler.ownerLevelCap

        if battler.battle.is_online?
            level = MAX_LEVEL_CAP
        end

        if hasTribeBonus?(:LOYAL)
            smallBonus = getSingleStatBonusSmall(level)
            GameData::Stat.each_main_battle do |stat|
                next if stat == :SPEED
                tribeBonuses[stat.id] += smallBonus
            end
        end

        if hasTribeBonus?(:INDUSTRIOUS) && (battler.battle.is_online? || !@trainer.is_a?(Player) || @trainer.money >= 100_000)
            mediumBonus = getSingleStatBonusMedium(level)
            GameData::Stat.each_main_battle do |stat|
                next if stat == :SPEED
                tribeBonuses[stat.id] += mediumBonus
            end
        end

        return tribeBonuses
    end

    def getSingleStatBonusSmall(level)
        return 4 + (level / 16).floor # 4 to 8
    end

    def getSingleStatBonusMedium(level)
        return 5 + (level / 12).floor # 5 to 10
    end

    def getSingleStatBonusLarge(level)
        return 6 + (level / 8).floor # 7 to 14
    end

    def hasTribeBonus?(tribeID)
        return @tribesGivingBonus.include?(tribeID)
    end

    def hasAnyTribeOverlap?
        updateTribeCount
        @tribeCounts.each do |tribe, count|
            return true if count >= 2
        end
        return false
    end

    def hasAnyTribalBonus?
        updateTribeCount
        return !@tribesGivingBonus.empty?
    end
end

def playerTribalBonus()
    $Trainer.tribalBonus = TribalBonus.new($Trainer) unless $Trainer.tribalBonus
    $Trainer.tribalBonus.trainer = $Trainer unless $Trainer.tribalBonus.trainer
    return $Trainer.tribalBonus
end

def getTribeName(tribe_id)
    return GameData::Tribe.get(tribe_id).name
end