# Progresses or ends quests when all of a certain thing is gotten

def completeTriIslandQuest
  if pbGetSelfSwitch(1, 'A', 416) && pbGetSelfSwitch(1, 'A', 417) && pbGetSelfSwitch(1, 'A', 415)
      completeQuest(:QUEST_LEGEND_TRI_ISLAND)
  end
end

def stageThreeCalyrexQuest
  if pbGetSelfSwitch(24, 'A', 333) && pbGetSelfSwitch(1, 'A', 434) && pbGetSelfSwitch(1, 'A', 436)
      advanceQuestToStage(:QUEST_LEGEND_CALYREX2, 5)
  end
end

def completeGuardianIslandQuest
    if pbGetSelfSwitch(2, 'A', 386) && pbGetSelfSwitch(2, 'A', 387) && pbGetSelfSwitch(2, 'A', 388) && pbGetSelfSwitch(2, 'A', 389)
        completeQuest(:QUEST_LEGEND_GUARDIAN_ISLAND)
    end
end

def stageTwoSigilQuest
    if pbGetSelfSwitch(1, 'A', 135) && pbGetSelfSwitch(7, 'A', 330)
        advanceQuestToStage(:QUEST_LEGEND_SIGIL, 2)
    end
end

def completeFormerChamps
    if pbGetSelfSwitch(41, 'D', 34) && pbGetSelfSwitch(33, 'D', 165) && pbGetSelfSwitch(3, 'D', 270) && pbGetSelfSwitch(3, 'B', 265) && pbGetSelfSwitch(3, 'D', 270) && pbGetSelfSwitch(5, 'D', 316)
        completeQuest(:QUEST_FORMER_CHAMPIONS)
    end
end

def completeSpiritAtollQuest
    if pbGetSelfSwitch(1, 'A', 375) && pbGetSelfSwitch(1, 'A', 419) && pbGetSelfSwitch(1, 'A', 420)
        completeQuest(:QUEST_LEGEND_ATOLL)
    end
end

def completeKilnaThievesQuest
    if pbGetSelfSwitch(37, 'A', 3) && pbGetSelfSwitch(42, 'A', 3)
        completeQuest(:QUEST_STONES_KILNA)
    end
end

def completeSvaitTouristsQuest
    if pbGetSelfSwitch(5, 'A', 293) && pbGetSelfSwitch(8, 'A', 293)
        completeQuest(:QUEST_STONES_SVAIT)
    end
end

def completeStrangeStoneQuest
    if pbGetSelfSwitch(43, 'A', 8) && pbGetSelfSwitch(44, 'A', 8)
        completeQuest(:QUEST_STONES_VELENZ)
    end
end

def stageTwoWeatherTrioQuest
    if pbGetSelfSwitch(4, 'A', 218) && pbGetSelfSwitch(1, 'A', 196)
        advanceQuestToStage(:QUEST_LEGEND_WEATHER_TRIO, 2)
    end
end

# Ends quest if Lugia is caught

BallHandlers::OnPokemonCaught += proc { |ball, battle, pkmn|
    next unless pkmn.species == :LUGIA
    next unless $game_map.map_id == 239 # ocean fishing contest

    completeQuest(:QUEST_LEGEND_LUGIA)
}