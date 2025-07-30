TRAINERS_PERFECTED_GLOBAL_VAR = 79

OMINOUS_EGG_REWARDS = {
    30 => :LIFEORB,
    60 => :PRISMSTONE,
    90 => :MASTERBALL,
    120 => :RELICSTATUE,
    150 => :SHINYCHARM,
}

GlobalStateHandlers::GlobalVariableChanged.add(TRAINERS_PERFECTED_GLOBAL_VAR,
    proc { |variableID, value|
        if $PokemonBag && pbHasItem?(:OMINOUSEGG)
            checkForOminousEggRewards
        end
    }
)

def receiveOminousEgg
    pbReceiveItem(:OMINOUSEGG)
    checkForOminousEggRewards
end

def checkForOminousEggRewards
    perfectedCount = getGlobalVariable(TRAINERS_PERFECTED_GLOBAL_VAR)

    $PokemonGlobal.ominous_egg_stage = 0 if $PokemonGlobal.ominous_egg_stage.nil?

    rewards = []

    OMINOUS_EGG_REWARDS.each_with_index do |kvp, index|
        key = kvp[0]
        value = kvp[1]
        if perfectedCount >= key && $PokemonGlobal.ominous_egg_stage == index
            rewards.push(value)
            $PokemonGlobal.ominous_egg_stage += 1
        end
    end

    unless rewards.empty?
        playOminousEggCutscene

        rewards.each do |item|
            pbReceiveItem(item)
        end
    end
end

def playOminousEggCutscene
    pbWait(20)
    pbMessage(_INTL("\\i[OMINOUSEGG]...you hear whispers from the Ominous Egg."))
    pbWait(20)
    case $PokemonGlobal.ominous_egg_stage
    when 1
        pbMessage(_INTL("\\i[OMINOUSEGG]...sacrifice..."))
    when 2
        pbMessage(_INTL("\\i[OMINOUSEGG]...strength in avarice..."))
    when 3
        pbMessage(_INTL("\\i[OMINOUSEGG]...urge to dominate..."))
    when 4
        pbMessage(_INTL("\\i[OMINOUSEGG]...to stand above others..."))
    when 5
        pbMessage(_INTL("\\i[OMINOUSEGG]...nothing can hide from you..."))
    end
end

def checkOminousEggProgress
    pbWait(20)
    pbMessage(_INTL("\\i[OMINOUSEGG]...you hear whispers from the Ominous Egg."))
    pbWait(20)

    anyShown = false

    perfectedCount = getGlobalVariable(TRAINERS_PERFECTED_GLOBAL_VAR)
    OMINOUS_EGG_REWARDS.each_with_index do |kvp, index|
        key = kvp[0]
        if perfectedCount < key
            pbMessage(_INTL("\\i[OMINOUSEGG]...the next stage requires..."))
            pbMessage(_INTL("\\i[OMINOUSEGG]...{1} feedings...",key - perfectedCount))
            anyShown = true
            break
        end
    end

    unless anyShown
        pbMessage(_INTL("\\i[OMINOUSEGG]...metamorphosis complete..."))
    end
    pbWait(20)
end

ItemHandlers::UseInField.add(:OMINOUSEGG,proc { |item|
    checkOminousEggProgress
    next true
})