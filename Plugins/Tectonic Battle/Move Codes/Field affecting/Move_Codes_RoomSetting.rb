#===============================================================================
# Causes SE damage to be 25% higher, and NVE damage to be 25% lower.
# (Polarized Room)
#===============================================================================
class PokeBattle_Move_StartPolarizeTypeMatchups5 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :PolarizedRoom
    end
end

class PokeBattle_Move_StartPolarizeTypeMatchups8 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :PolarizedRoom
    end
end

# Empowered Polarized Room
class PokeBattle_Move_EmpoweredPolarizedRoom < PokeBattle_Move_StartPolarizeTypeMatchups8
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.pbRaiseMultipleStatSteps(DEFENDING_STATS_1, user, move: self)
        transformType(user, :STEEL)
    end
end

#===============================================================================
# Pokemon's Attack and Sp. Atk are swapped. (Puzzle Room)
#===============================================================================
class PokeBattle_Move_StartSwapAttackingStats5 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :PuzzleRoom
    end
end

class PokeBattle_Move_StartSwapAttackingStats8 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :PuzzleRoom
    end
end

# Empowered Puzzle Room
class PokeBattle_Move_EmpoweredPuzzleRoom < PokeBattle_Move_StartSwapAttackingStats8
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.pbRaiseMultipleStatSteps(ATTACKING_STATS_1, user, move: self)
        transformType(user, :FAIRY)
    end
end

#===============================================================================
# Swaps all battlers' offensive and defensive stats (Sp. Def <-> Sp. Atk and Def <-> Atk).
# (Odd Room)
#===============================================================================
class PokeBattle_Move_StartSwapOffensiveAndDefensiveStats5 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :OddRoom
    end
end

class PokeBattle_Move_StartSwapOffensiveAndDefensiveStats8 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :OddRoom
    end
end

# Empowered Odd Room
class PokeBattle_Move_EmpoweredOddRoom < PokeBattle_Move_StartSwapOffensiveAndDefensiveStats8
    include EmpoweredMove

    def pbEffectGeneral(user)
        super
        user.tryRaiseStat(:SPEED, user, move: self)
        transformType(user, :PSYCHIC)
    end
end

#===============================================================================
# For 4 rounds, swaps the effects of speed on round order. (Trick Room)
#===============================================================================
class PokeBattle_Move_StartSwapSpeedOrder4 < PokeBattle_RoomMove
    def initialize(battle, move)
        super
        @roomEffect = :TrickRoom
    end
end