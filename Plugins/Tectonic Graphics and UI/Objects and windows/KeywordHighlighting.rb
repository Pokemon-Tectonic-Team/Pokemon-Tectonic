def battleKeywordsImportant
    return [
        "rainstorm",
        "sunshine",
        "sandstorm",
        "hail",
        "total eclipse",
        "eclipse",
        "full moon",
        "moonglow",
        "burning spikes",
        "burning",
        "burned",
        "burns",
        "burn",
        "frostbiting",
        "frostbitten",
        "frostbites",
        "frostbite",
        "numbing",
        "numbed",
        "numbs",
        "numb",
        "poison spikes",
        "poisoning",
        "poisoned",
        "poisons",
        "poison",
        "leeching",
        "leeched",
        "leeches",
        "leech",
        "dizzying",
        "dizzied",
        "dizzies",
        "dizzy",
        "waterlogging",
        "waterlogged",
        "waterlogs",
        "waterlog",
        "asleep",
        "sleep",
        "drowsy",
        "cursing",
        "cursed",
        "curse",
        "fracturing",
        "fractured",
        "fracture",
        "jinxing",
        "jinxed",
        "jinx",
        "disabled",
        "disables",
        "disable",
        "maximizes",
        "maximize",
        "minimized",
        "minimizes",
        "minimize",
        "minimizing",
        "aqua ring",
        "recoil",
        "flinching",
        "flinched",
        "flinch",
        "random added effects",
        "random added effect",
        "trapping",
        "trapped",
        "traps",
        "trap",
        "gravity",
        "trick room",
        "puzzle room",
        "odd room",
        "polarized room",
        "insight room",
        "emotion room",
        "willful room",
        "rooms",
        "room",
        "tailwind",
        "weather",
        "random critical hits",
        "random critical hit",
        "critical hit chance",
        "critical hits",
        "critical hit",
        "screens",
        "invulnerable",
        "clothing",
        "Grey Mist",
        "Stockpile",
        "hazards",
        "hazard",
        "frozen spikes",
        "offensive",
        "defensive",
        "coins",
        "money",
        "spread",
        "multi-hits",
        "multi-hit",
        "rampaging",
        "rampages",
        "rampage",
        "charging",
        "charges",
        "charge",
        "exhausted",
        "exhausting",
        "energized",
        "energize",
        "substitutes",
        "substitute",
    ]
end

def battleKeywordsImportantCaseSensitive
    return [
        "Sp. Atk",
        "Special Attack",
        "Attack",
        "Sp. Def",
        "Special Defense",
        "Defense",
        "Speed",
        "Accuracy",
        "Evasion",
        "Frost Spikes",
        "Flame Spikes",
        "Poison Spikes",
        "Spikes",
    ]
end

def battleKeywordsUnimportant
    return [
        "twice",
        "doubles",
        "double",
        "doubled",
        "three times",
        "four times",
        "five times",
        "half",
        "one third",
        "two thirds",
        "one quarter",
        "three quarters",
        "one fifth",
        "1/6th",
        "1/8th",
        "1/10th",
        "1/12th",
        "1/16th",
        "all stats",
        "all its stats",
    ]
end

def battleKeywordsUnimportantCaseSensitive
    return [
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        "eleven",
        "twelve",
        "thirteen",
        "fourteen",
        "fifteen",
        "sixteen",
        "seventeen",
        "eighteen",
        "nineteen",
        "twenty",
    ]
end

def addBattleKeywordHighlighting(description)
    # Highlight very important words in red
    importantColorTag = getSkinColor(nil, 2, darkMode?, true)
    battleKeywordsImportant.each do |keyword|
        description = description.gsub(/\b(#{keyword})\b/i,"#{importantColorTag}\\1</c3>")
    end
    battleKeywordsImportantCaseSensitive.each do |keyword|
        description = description.gsub(/\b(#{keyword})\b/,"#{importantColorTag}\\1</c3>")
    end

    # Outline less important keywords
    unimportantColorTag = getSkinColor(nil, 13, darkMode?, true)
    battleKeywordsUnimportant.each do |keyword|
        description = description.gsub(/\b(#{keyword})\b/i,"#{unimportantColorTag}\\1</c3>")
    end
    battleKeywordsUnimportantCaseSensitive.each do |keyword|
    description = description.gsub(/\b(#{keyword})\b/,"#{unimportantColorTag}\\1</c3>")
    end

    return description
end