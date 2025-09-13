def pbCableClubPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("What do you want to do?"),[
        _INTL("Connect"),
        _INTL("Customise Trainer Class"),
        _INTL("Customise Win Message"),
        _INTL("Customise Lose Message"),
        _INTL("Cancel")
        ],-1,nil,command)
    case command
    when 0 then pbCableClub
    when 1 then pbChangeOnlineTrainerType
    when 2 then pbChangeOnlineWinText
    when 3 then pbChangeOnlineLoseText
    else        break
    end
  end
end