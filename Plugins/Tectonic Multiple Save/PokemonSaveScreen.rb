#===============================================================================
#
#===============================================================================
class PokemonSaveScreen
    def initialize(scene)
        @scene = scene
    end

    def pbDisplay(text, brief = false)
        @scene.pbDisplay(text, brief)
    end

    def pbDisplayPaused(text)
        @scene.pbDisplayPaused(text)
    end

    def pbConfirm(text)
        return @scene.pbConfirm(text)
    end

    # Returns 1 if the player decides to quit to menu, 2 if they quit to desktop, false otherwise
    def pbSaveScreen(quitting = false, deleting = true)
        unless savingAllowed?
            showSaveBlockMessage
            return
        end
        # Check for renaming
        FileSave.rename
        # Count save file
        count = FileSave.count
        # Start
        saveCommand = -1
        mainMenuCommand = -1
        deleteCommand = -1
        quitCommand = -1
        cancelCommand = -1
        cmds = []
        cmds[saveCommand = cmds.length] = _INTL("Just Save")
        cmds[mainMenuCommand = cmds.length] = _INTL("Save & Quit to Menu") if quitting
        cmds[quitCommand = cmds.length] = _INTL("Save & Quit to Desktop") if quitting
        cmds[deleteCommand = cmds.length] = _INTL("Delete") if deleting
        cmds[cancelCommand = cmds.length] = _INTL("Cancel")
        saveChoice = pbCustomMessageForSave(_INTL("What do you want to do?"), cmds, cmds.length)
        if mainMenuCommand >= 0 && saveChoice == mainMenuCommand
          return 1 if inGameSaveScreen(count)
        elsif quitCommand >= 0 && saveChoice == quitCommand
          return 2 if inGameSaveScreen(count)
        elsif saveCommand >= 0 && saveChoice == saveCommand
          inGameSaveScreen(count)
        elsif deleteCommand >= 0 && saveChoice == deleteCommand
          inGameDeleteScreen(count)
        end
        return false
    end

    def inGameSaveScreen(count)
        ret = false
        @scene.pbStartScreen
        commands = []
        cmdSaveCurrent	= -1
        cmdSaveNew		= -1
        cmdSaveOld		= -1
        if !$current_save_file_name.nil? && count > 0
            commands[cmdSaveCurrent = commands.length] =
                _INTL("Save current save file")
        end
        commands[cmdSaveNew = commands.length] = _INTL("New Save File")
        commands[cmdSaveOld = commands.length] = _INTL("Old Save File")
        commands[commands.length] = _INTL("Cancel")
        saveTypeSelection = pbCustomMessageForSave(_INTL("What do you want to do?"), commands,
($current_save_file_name.nil? && count > 0 ? 3 : 4))
        # New save file
        if cmdSaveNew >= 0 && saveTypeSelection == cmdSaveNew
            SaveData.changeFILEPATH(FileSave.name(count + 1))
            if Game.save
                pbMessage(_INTL("\\se[]{1} saved the game.\\me[GUI save game]\\wtnp[30]", $Trainer.name))
                ret = true
            else
                pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
                ret = false
            end
            # Change the stored save file to what you just created
            $current_save_file_name = FileSave.name(count + 1)
            SaveData.changeFILEPATH(!$current_save_file_name.nil? ? $current_save_file_name : FileSave.name)
        end
        # Old save file
        if cmdSaveOld >= 0 && saveTypeSelection == cmdSaveOld
            if count <= 0
                pbMessage(_INTL("No save file was found."))
            else
                pbFadeOutIn do
                    file = ScreenChooseFileSave.new(count)
                    file.movePanel
                    file.endScene
                    ret = file.staymenu
                end
            end
        end
        # Save over current
        if cmdSaveCurrent >= 0 && saveTypeSelection == cmdSaveCurrent
            SaveData.changeFILEPATH($current_save_file_name)
            if Game.save
                pbMessage(_INTL("\\se[]{1} saved the game.\\me[GUI save game]\\wtnp[30]", $Trainer.name))
                ret = true
            else
                pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
                ret = false
            end
            SaveData.changeFILEPATH(!$current_save_file_name.nil? ? $current_save_file_name : FileSave.name)
        end
        @scene.pbEndScreen
        return ret
    end

    def inGameDeleteScreen(count)
        if count <= 0
            pbMessage(_INTL("No save file was found."))
            return false
        end
        commands = [_INTL("Delete One Save"), _INTL("Delete All Saves"), _INTL("Cancel")]
        deleteTypeSelection = pbCustomMessageForSave(_INTL("What do you want to do?"), commands, 3)
        case deleteTypeSelection
        when 0
            pbFadeOutIn do
                file = ScreenChooseFileSave.new(count)
                file.movePanel(2)
                file.endScene
                Graphics.frame_reset if file.deletefile
            end
        when 1
            if pbConfirmMessageSerious(_INTL("Delete all saves?"))
                pbMessage(_INTL("Once data has been deleted, there is no way to recover it.\1"))
                if pbConfirmMessageSerious(_INTL("Delete the saved data anyway?"))
                    pbMessage(_INTL("Deleting all data. Don't turn off the power.\\wtnp[0]"))
                    haserrorwhendelete = false
                    count.times do |i|
                        name = FileSave.name(i + 1, false)
                        begin
                            SaveData.delete_file(name)
                        rescue StandardError
                            haserrorwhendelete = true
                        end
                    end
                    pbMessage(_INTL("You have at least one file that cant delete and have error")) if haserrorwhendelete
                    Graphics.frame_reset
                    pbMessage(_INTL("The save file was deleted."))
                end
            end
        end
        # Return menu
        return false
    end
end