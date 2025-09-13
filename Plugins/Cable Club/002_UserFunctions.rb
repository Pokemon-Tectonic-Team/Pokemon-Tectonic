# Returns false if an error occurred.
def pbCableClub
  scene = CableClub_Scene.new
  screen = CableClubScreen.new(scene)
  return screen.pbStartScreen
end

def pbChangeOnlineTrainerType
  old_trainer_type = $Trainer.online_trainer_type
  if $Trainer.online_trainer_type==$Trainer.trainer_type
    pbMessage(_INTL("What Trainer Class do you want to present to your opponents?"))
  else
    trainername=GameData::TrainerType.get($Trainer.online_trainer_type).name
    pbMessage(_INTL("Your current online Trainer Class is {1}.",trainername))
  end
  commands=[]
  trainer_types=[]
  CableClub::ONLINE_TRAINER_TYPE_LIST.each do |type|
    t=type
    t=type[$Trainer.gender] if type.is_a?(Array)
    commands.push(GameData::TrainerType.get(t).name)
    trainer_types.push(t)
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("What Trainer Class do you want to present to your opponents?"),commands,-1)
    if cmd>=0 && cmd<commands.length-1
      trainername=commands[cmd]
      if ['a','e','i','o','u'].include?(trainername[0,1].downcase)
        msg=_INTL("An {1} is the kind of Trainer you want to be?",trainername)
        if pbConfirmMessage(msg)
          pbMessage(_INTL("You will appear as an {1} in online battles.",trainername))
          $Trainer.online_trainer_type=trainer_types[cmd]
          break
        end
      else
        msg=_INTL("A {1} is the kind of Trainer you want to be?",trainername)
        if pbConfirmMessage(msg)
          pbMessage(_INTL("You will appear as a {1} in online battles.",trainername))
          $Trainer.online_trainer_type=trainer_types[cmd]
          break
        end
      end
    else
      break
    end
  end
  if old_trainer_type != $Trainer.online_trainer_type
    CableClub.onUpdateTrainerType.trigger(nil, $Trainer.online_trainer_type)
  end
end

def pbChangeOnlineWinText
  commands = []
  CableClub::ONLINE_WIN_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("What do you want to say when you win?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_WIN_SPEECHES_LIST.length-1
      win_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\nThis is what you wish to say?",win_text))
        pbMessage(_INTL("\"{1}\"\\nThis is what you will say when you win.",win_text))
        $Trainer.online_win_text=cmd
        break
      end
    else
      break
    end
  end
end

def pbChangeOnlineLoseText
  commands = []
  CableClub::ONLINE_LOSE_SPEECHES_LIST.each do |text|
    commands.push(_INTL(text))
  end
  commands.push(_INTL("Cancel"))
  loop do
    cmd=pbMessage(_INTL("What do you want to say when you lose?"),commands,-1)
    if cmd>=0 && cmd<CableClub::ONLINE_LOSE_SPEECHES_LIST.length-1
      lose_text=commands[cmd]
      if pbConfirmMessage(_INTL("\"{1}\"\\nThis is what you wish to say?",lose_text))
        pbMessage(_INTL("\"{1}\"\\nThis is what you will say when you lose.",lose_text))
        $Trainer.online_lose_text=cmd
        break
      end
    else
      break
    end
  end
end