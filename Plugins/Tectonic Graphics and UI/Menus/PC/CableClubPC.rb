def pbCableClubPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("What do you want to do?"),[
        _INTL("Connect"),
        _INTL("Customize"),
        _INTL("Cancel")
        ],-1,nil,command)
    case command
    when 0 then pbCableClub
    when 1 then pbCableClubCustomMenu
    else        break
    end
  end
end

def pbCableClubCustomMenu
  command = 0
  loop do
    command = pbMessage(_INTL("What do you want to change?"),[
        _INTL("Trainer Class"),
        _INTL("Win Message"),
        _INTL("Loss Message"),
        _INTL("Cancel")
        ],-1,nil,command)
    case command
    when 0 then pbChangeOnlineTrainerType
    when 1 then pbChangeOnlineWinText
    when 2 then pbChangeOnlineLoseText
    else        break
    end
  end
end

