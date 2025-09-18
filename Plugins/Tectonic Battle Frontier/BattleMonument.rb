def battleMonumentSinglesRegister
    pbMessage(_INTL("Welcome to the Battle Monument."))

    if pbConfirmMessage(_INTL("Take the singles battle challenge?"))
        rules = pbBattleMonumentRules(false)
        pbBattleChallenge.set(
            "monumentsingle",
            5,
            rules,
            false
        )

        rules.setNumber(6)

        errorList = []
        if rules.ruleset.isValid?($Trainer.party,errorList)
            pbBattleChallenge.setParty($Trainer.party)
            pbMessage(_INTL("Please come this way."))
            pbBattleChallenge.start
            return true
        else
            pbMessage(_INTL("Your party is not legal for this challenge."))
            errorList.each do |error|
                pbMessage(error)
            end
        end
    end

    pbBattleChallenge.pbCancel
    return false
end

def battleMonumentSinglesBattle(opponentEventID,followerEventID,nurseEventID)
    opponentEvent = get_character(opponentEventID)
    followerEvent = get_character(followerEventID)
    nurseEvent = get_character(nurseEventID)

    nextTrainer = pbBattleChallenge.nextTrainer
    
    # Set the sprite for the opponent
    opponentCharacterName = nextTrainer.trainer_type.to_s
    opponentEvent.character_name = opponentCharacterName
    #opponentEvent.opacity = 200

    # Set the sprite for the follower pokemon
    pokemon = nextTrainer.to_trainer.displayPokemonAtIndex(0)
    followerCharacterName = GameData::Species.ow_sprite_filename(pokemon.species,pokemon.form,pokemon.gender,pokemon.shiny?).gsub!("Graphics/Characters/","")
    followerEvent.character_name = followerCharacterName
    #followerEvent.opacity = 200

    fadeIn

    pbMessage(_INTL("The match will now begin!"))
    if pbBattleChallengeBattle
        pbBattleChallenge.pbAddWin
        # Player is victorous in their run
        if pbBattleChallenge.pbMatchOver?
            pbBattleChallenge.setDecision(1)
            battleMonumentTransferToStart
        else
            pbWait(10)
            pbMoveRoute(nurseEvent, [
                PBMoveRoute::Right,
                PBMoveRoute::Right,
                ]
            )
            pbWait(30)
            pbMessage(_INTL("Let me heal your party."))
            healPartyWithDelay(true)
            nurseEvent.move_to_original
            pbWait(30)
            fadeToBlack
            pbBattleChallenge.pbGoOn
        end
    else
        pbBattleChallenge.setDecision(2)
        battleMonumentTransferToStart
    end
end

def battleMonumentTransferToStart
    pbSEPlay('Door Exit',80,100)
    blackFadeOutIn {
        pbBattleChallenge.pbGoToStart
    }
end

def battleMonumentRecievePlayerInLobby
    fadeIn
    battleChallenge = pbBattleChallenge
    wins = battleChallenge.battleNumber - 1
    if pbBattleChallenge.decision == 1
        checkBattleMonumentVictoryAchievements
        pbMessage(_INTL("Congratulations on your victory!"))
        earnBattlePoints(50)
        battleMonumentTeamSnapshot
    elsif wins
        pbMessage(_INTL("Thanks for playing."))
        
        echoln("Wins: #{wins}")
        case wins
        when 1
            earnBattlePoints(3)
        when 2
            earnBattlePoints(6)
        when 3
            earnBattlePoints(12)
        when 4
            earnBattlePoints(25)
        when 5
            earnBattlePoints(50)
        end
    else
        pbMessage(_INTL("Better luck next time."))
    end
    pbBattleChallenge.pbEnd
    pbMessage(_INTL("Come back another time."))
end

def battleMonumentTeamSnapshot
    teamSnapshot(_INTL("Battle Monument Team {1}",Time.now.strftime("[%Y-%m-%d] %H_%M_%S.%L")))  
end

def lerp_i(int1, int2, factor)
    return int1.to_f * (1.0-factor) + int2.to_f * factor
end

def lerp_col(col1, col2, factor)
    return Color.new(
        lerp_i(col1.red, col2.red, factor),
        lerp_i(col1.green, col2.green, factor),
        lerp_i(col1.blue, col2.blue, factor),
        lerp_i(col1.alpha, col2.alpha, factor)
    )
end

HOLOGRAM_BASE = Color.new(11, 94, 99)
HOLOGRAM_LIGHT = Color.new(118, 240, 255)

def hologramize(bitmap, stretch=1.3)
    copiedBitmap = Bitmap.new(bitmap.width, bitmap.height)

    width = copiedBitmap.width
    height = copiedBitmap.height
    for x in 0...width
        for y in 0...height
            base_color = bitmap.get_pixel(x,y)
            color = bitmap.get_pixel((x-width/2.0)/stretch+(width/2.0), y) #Sample from enlarged image
            color.alpha = (y % 2 == 1) ? color.alpha : 0 #Interlace
            color = lerp_col(color, base_color, 0.66) #Mix with original sprite
            h, s, l = rgb_to_hsl(color.red, color.green, color.blue)
            c1, c2 = HOLOGRAM_BASE, HOLOGRAM_LIGHT
            c1.alpha, c2.alpha = color.alpha, color.alpha
            color = lerp_col(c1, c2, (l/100.0)) #Gradientize
            copiedBitmap.set_pixel(x, y, color)
        end
    end
    return copiedBitmap
end

SHOW_HOLOGRAMIZATION_DEBUG = false

def hologramizeBattleSprite(name, overwriteExisting=true)
    identifier = "Hologram of #{name}"

    battlerFrontFilePath = GameData::TrainerType.front_sprite_filename(name)
    hologramFrontFilePath = GameData::TrainerType.front_sprite_filename_hologram(name + ".png")
    if hologramFrontFilePath.nil? #If image doesn't exist yet
        hologramFrontFilePath = "./Graphics/Trainers/Holograms/" + name + ".png"
    end

    if overwriteExisting || !pbResolveBitmap(hologramFrontFilePath)
        echoln("Creating front sprite for #{identifier}")
        battlebitmap = AnimatedBitmap.new(battlerFrontFilePath)
        copiedBattleBitmap = battlebitmap.copy
        hologramizedBattle = hologramize(copiedBattleBitmap.bitmap)
        hologramizedBattle.to_file(hologramFrontFilePath)
    elsif SHOW_HOLOGRAMIZATION_DEBUG
        echoln("Front sprite already exists for #{identifier}")
    end
end

def hologramizeAllBattleSprites(overwriteExisting=true)
    monument_trainers = GameData::Trainer.getMonumentTrainers
    monument_trainers.map! { |t| t.trainer_type.to_s }
    monument_trainers.uniq!
    
    monument_trainers.each do |t|
        hologramizeBattleSprite(t, overwriteExisting)
    end
end