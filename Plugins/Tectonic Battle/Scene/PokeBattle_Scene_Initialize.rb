class PokeBattle_Scene
    #=============================================================================
    # Create the battle scene and its elements
    #=============================================================================
    def initialize
      @battle       = nil
      @abortable    = false
      @aborted      = false
      @battleEnd    = false
      @animations   = []
      @frameCounter = 0
    end
  
    def pbStartBattle(battle)
      @battle   = battle
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @lastCmd  = Array.new(@battle.battlers.length,0)
      @lastMove = Array.new(@battle.battlers.length,0)
      pbInitSprites
      pbBattleIntroAnimation unless @battle.autoTesting
    end
  
    def pbInitSprites
      @sprites = {}
      # The background image and each side's base graphic
      pbCreateBackdropSprites
      # Create message box graphic
      overlayMessageName = "Graphics/Pictures/Battle/overlay_message"
      overlayMessageName += "_dark" if darkMode?
      messageBox = pbAddSprite("messageBox",0,Graphics.height-96,overlayMessageName,@viewport)
      messageBox.z = 195
      # Create message window (displays the message)
      msgWindow = Window_AdvancedTextPokemon.newWithSize("",
        16,Graphics.height-96+2,Graphics.width-32,96,@viewport)
      msgWindow.z              = 200
      msgWindow.opacity        = 0
      msgWindow.letterbyletter = true
      @sprites["messageWindow"] = msgWindow
      resetMessageTextColor
      # Create command window
      @sprites["commandWindow"] = CommandMenuDisplay.new(@viewport,200,@battle)
      # Create fight window
      @sprites["fightWindow"] = FightMenuDisplay.new(@viewport,200)
      # Create targeting window
      @sprites["targetWindow"] = TargetMenuDisplay.new(@viewport,200,@battle.sideSizes)
      pbShowWindow(MESSAGE_BOX)
      # The party lineup graphics (bar and balls) for both sides
      for side in 0...2
        partyBar = pbAddSprite("partyBar_#{side}",0,0,
          "Graphics/Pictures/Battle/overlay_lineup",@viewport)
        partyBar.z       = 120
        partyBar.mirror  = true if side==0   # Player's lineup bar only
        partyBar.visible = false
        for i in 0...getDisplayBallCount(side)
          ball = pbAddSprite("partyBall_#{side}_#{i}",0,0,nil,@viewport)
          ball.z       = 121
          ball.visible = false
        end
        # Ability splash bars
        newAbilityBar = AbilitySplashBar.new(side,@viewport)
        @sprites["abilityBar_#{side}"] = newAbilityBar
        # Tribe splash bars
        newTribeBar = TribeSplashBar.new(side,@viewport)
        @sprites["tribeBar_#{side}"] = newTribeBar
      end

      # Player's and partner trainer's back sprite
      @battle.player.each_with_index do |p,i|
        pbCreateTrainerBackSprite(i,p.trainer_type,@battle.player.length)
      end
      # Opposing trainer(s) sprites
      if @battle.trainerBattle?
        @battle.opponent.each_with_index do |p,i|
          pbCreateTrainerFrontSprite(i,p.trainer_type,@battle.opponent.length)
        end
      end
      createDataBoxes()

      @battle.battlers.each_with_index do |b,i|
        next if b.nil?
        pbCreatePokemonSprite(i)
        createAvatarTargetReticle(b,i) if i.even? # Only trainer pokemon
        createMoveOutcomePredictor(b,i) if i.odd? # Only enemy pokemon
      end

      # Wild battle, so set up the Pokémon sprite(s) accordingly
      if @battle.wildBattle?
        @battle.pbParty(1).each_with_index do |pkmn,i|
          index = i*2+1
          pkmn = @battle.battlers[index].disguisedAs || pkmn
          pbChangePokemon(index,pkmn)
          pkmnSprite = @sprites["pokemon_#{index}"]
          pkmnSprite.tone    = Tone.new(-80,-80,-80)
          pkmnSprite.visible = true
        end
      end
      
      @sprites["turnCountReminder"] = TurnCountReminder.new(-1,@viewport)
      @sprites["turnCountReminder"].x = Graphics.width / 2 + 20
      @sprites["turnCountReminder"].visible = false

      # Bug contest
      # "helpwindow" shows the currently caught Pokémon's details when asking if
      # you want to replace it with a newly caught Pokémon.
      @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
      @sprites["helpwindow"].z       = 90
      @sprites["helpwindow"].visible = false
    end

    def resetMessageTextColor
      msgWindow = @sprites["messageWindow"]
      msgWindow.baseColor      = PokeBattle_SceneConstants.getBaseColor
      msgWindow.shadowColor    = PokeBattle_SceneConstants.getShadowColor
    end

    def getDisplayBallCount(side)
      numBalls = PokeBattle_SceneConstants::NUM_BALLS
      if side == 0
        numBalls *= @battle.player.length
      else
        return 0 if @battle.wildBattle?
        numBalls *= @battle.opponent.length
      end
      return numBalls
    end  

    # Databoxes get closer together the more battlers on a side
    BASE_PIXELS_BETWEEN_DATABOXES = 2
    SQUISH_PIXELS_PER_ADDED_BATTLER = 6
    BASE_TRAINER_DEPTH = 40
    BASE_PLAYER_HEIGHT = 192
    SHIFT_PIXELS_PER_ADDED_TRAINER_BATTLER = 20
    SHIFT_PIXELS_PER_ADDED_PLAYER_BATTLER = 24

    def createDataBoxes()
        # Trainer side databoxes
        trainerSideSize = @battle.pbSideSize(1)
        extraTrainerBattlers = trainerSideSize - 1
        trainerY = BASE_TRAINER_DEPTH - extraTrainerBattlers * SHIFT_PIXELS_PER_ADDED_TRAINER_BATTLER
        trainerY -= 12 if @battle.battlers[1].boss?
        pixelsBetweenTrainerDataboxes = BASE_PIXELS_BETWEEN_DATABOXES - extraTrainerBattlers * SQUISH_PIXELS_PER_ADDED_BATTLER
        @battle.battlers.each do |b|
          next if !b || b.index.even?
          newDataBox = PokemonDataBox.new(b,trainerSideSize,@viewport,trainerY)
          @sprites["dataBox_#{b.index}"] = newDataBox
          trainerY += newDataBox.getHeight + pixelsBetweenTrainerDataboxes
        end

        # Player side databoxes
        playerSideSize = @battle.pbSideSize(0)
        extraPlayerBattlers = playerSideSize - 1
        playerY = Graphics.height - BASE_PLAYER_HEIGHT + extraPlayerBattlers * SHIFT_PIXELS_PER_ADDED_PLAYER_BATTLER
        pixelsBetweenPlayerDataboxes = BASE_PIXELS_BETWEEN_DATABOXES - extraPlayerBattlers * SQUISH_PIXELS_PER_ADDED_BATTLER
        @battle.battlers.reverse.each do |b|
          next if !b || b.index.odd?
          newDataBox = PokemonDataBox.new(b,playerSideSize,@viewport,playerY)
          @sprites["dataBox_#{b.index}"] = newDataBox
          playerY -= newDataBox.getHeight + pixelsBetweenPlayerDataboxes
        end
    end

    def deleteDataBoxes()
        @battle.battlers.each_with_index do |b,i|
            @sprites["dataBox_#{i}"].dispose if @sprites["dataBox_#{i}"]
        end
    end
  
    def pbCreateBackdropSprites
      if GameData::MapMetadata.exists?($game_map.map_id) && GameData::MapMetadata.get($game_map.map_id).outdoor_map
        case @battle.time
        when 1 then time = "eve"
        when 2 then time = "night"
        end
      end
      # Put everything together into backdrop, bases and message bar filenames
      backdropFilename = @battle.backdrop
      baseFilename = @battle.backdrop
      baseFilename = sprintf("%s_%s",baseFilename,@battle.backdropBase) if @battle.backdropBase
      messageFilename = @battle.backdrop
      if time
        trialName = sprintf("%s_%s",backdropFilename,time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/"+trialName+"_bg"))
          backdropFilename = trialName
        end
        trialName = sprintf("%s_%s",baseFilename,time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/"+trialName+"_base0"))
          baseFilename = trialName
        end
        trialName = sprintf("%s_%s",messageFilename,time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/"+trialName+"_message"))
          messageFilename = trialName
        end
      end
      if !pbResolveBitmap(sprintf("Graphics/Battlebacks/"+baseFilename+"_base0")) &&
         @battle.backdropBase
        baseFilename = @battle.backdropBase
        if time
          trialName = sprintf("%s_%s",baseFilename,time)
          if pbResolveBitmap(sprintf("Graphics/Battlebacks/"+trialName+"_base0"))
            baseFilename = trialName
          end
        end
      end
      # Finalise filenames
      battleBG   = "Graphics/Battlebacks/"+backdropFilename+"_bg"
      playerBase = "Graphics/Battlebacks/"+baseFilename+"_base0"
      enemyBase  = "Graphics/Battlebacks/"+baseFilename+"_base1"
      messageBG  = "Graphics/Battlebacks/"+messageFilename+"_message"
      # Apply graphics
      bg = pbAddSprite("battle_bg",0,0,battleBG,@viewport)
      bg.z = 0
      bg = pbAddSprite("battle_bg2",-Graphics.width,0,battleBG,@viewport)
      bg.z      = 0
      bg.mirror = true
      for side in 0...2
        baseX, baseY = PokeBattle_SceneConstants.pbBattlerPosition(side)
        base = pbAddSprite("base_#{side}",baseX,baseY,
           (side==0) ? playerBase : enemyBase,@viewport)
        base.z    = 1
        if base.bitmap
          base.ox = base.bitmap.width/2
          base.oy = (side==0) ? base.bitmap.height : base.bitmap.height/2
        end
        if @battle.bossBattle?
          if side != 0
            base.zoom_x *= 1.5
            base.zoom_y *= 1.5
          end
        end
      end
      cmdBarBG = pbAddSprite("cmdBar_bg",0,Graphics.height-96,messageBG,@viewport)
      cmdBarBG.z = 180
    end
  
    def pbCreateTrainerBackSprite(idxTrainer,trainerType,numTrainers=1)
      if idxTrainer==0   # Player's sprite
        trainerFile = GameData::TrainerType.player_back_sprite_filename(trainerType)
      else   # Partner trainer's sprite
        trainerFile = GameData::TrainerType.back_sprite_filename(trainerType)
      end
      spriteX, spriteY = PokeBattle_SceneConstants.pbTrainerPosition(0,idxTrainer,numTrainers)
      trainer = pbAddSprite("player_#{idxTrainer+1}",spriteX,spriteY,trainerFile,@viewport)
      return if !trainer.bitmap
      # Alter position of sprite
      trainer.z  = 30+idxTrainer
      if trainer.bitmap.width>trainer.bitmap.height*2
        trainer.src_rect.x     = 0
        trainer.src_rect.width = trainer.bitmap.width/5
      end
      trainer.ox = trainer.src_rect.width/2
      trainer.oy = trainer.bitmap.height
    end
  
    def pbCreateTrainerFrontSprite(idxTrainer,trainerType,numTrainers=1)
      
      monumTrainers = GameData::Trainer.getMonumentTrainers
      tNames = monumTrainers.map { |t| t.name}
      tClasses = monumTrainers.map { |t| t.trainer_type }
            
      if tNames.find_index(@battle.opponent[0].name) == tClasses.find_index(@battle.opponent[0].trainer_type) && !tNames.find_index(@battle.opponent[0].name).nil?
        trainerFile = GameData::TrainerType.front_sprite_filename_hologram(trainerType)
      else
        trainerFile = GameData::TrainerType.front_sprite_filename(trainerType)
      end
      spriteX, spriteY = PokeBattle_SceneConstants.pbTrainerPosition(1,idxTrainer,numTrainers)
      trainer = pbAddSprite("trainer_#{idxTrainer+1}",spriteX,spriteY,trainerFile,@viewport)
      return if !trainer.bitmap
      # Alter position of sprite
      trainer.z  = 7+idxTrainer
      trainer.ox = trainer.src_rect.width/2
      trainer.oy = trainer.bitmap.height
    end
  
    def pbCreatePokemonSprite(idxBattler)
      sideSize = @battle.pbSideSize(idxBattler)
      batSprite = PokemonBattlerSprite.new(@viewport,sideSize,idxBattler,@animations)
      @sprites["pokemon_#{idxBattler}"] = batSprite
      shaSprite = PokemonBattlerShadowSprite.new(@viewport,sideSize,idxBattler)
      shaSprite.visible = false
      @sprites["shadow_#{idxBattler}"] = shaSprite
    end

    def createMoveOutcomePredictor(battler,index)
      predictor = MoveOutcomePredictor.new(battler,@battle.pbSideSize(index),@viewport)
      predictor.visible = true
      @sprites["move_outcome_#{index}"] = predictor
    end

    def createAvatarTargetReticle(battler,index)
      cursor = AvatarTargetReticle.new(battler,@battle.pbSideSize(index),@viewport)
      cursor.visible = false
      @sprites["aggro_cursor_#{index}"] = cursor
    end
end
  