#===============================================================================
#
#===============================================================================
class TilingCardsPauseMenu_Scene < TilingCardsMenu_Scene
	def initializeMenuButtons
		super
		@cardButtons = {
			:POKEMON => {
				:label => _INTL("Pokémon"),
				:active_proc => Proc.new {
					$Trainer.party_count > 0
				},
				:press_proc => Proc.new { |scene|
					pbPlayDecisionSE
					pbFadeOutIn {
						sscene = PokemonParty_Scene.new
						sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
						sscreen.pbPokemonScreen
						scene.drawButtons
					}
				},
			},
			:DOCUMENTATION =>  {
				:label => _INTL("Documents"),
				:press_proc => Proc.new { |scene|
                    storedLastMenuChoice = $PokemonTemp.menuLastChoice
                    $PokemonTemp.menuLastChoice = 0
                    
                    pbPlayDecisionSE
                    docsMenuScene = PokemonDocumentationMenu_Scene.new
                    docsMenuScreen = PokemonDocumentationMenu.new(docsMenuScene)
                    docsMenuScreen.pbStartPokemonMenu

                    scene.drawButtons
                    
                    $PokemonTemp.menuLastChoice = storedLastMenuChoice
				},
			},
			:BAG => {
				:label => _INTL("Item Bag"),
				:press_proc => Proc.new { |scene|
					pbPlayDecisionSE
					item = nil
					pbFadeOutIn {
                        bagScene = PokemonBag_Scene.new
                        screen = PokemonBagScreen.new(bagScene,$PokemonBag)
                        item = screen.pbStartScreen
                        (item) ? scene.pbEndScene : scene.drawButtons
					}
					if item
                        $game_temp.in_menu = false
                        pbUseKeyItemInField(item)
                        next true
					end
				},
			},
			:DEXNAV => {
				:label => _INTL("DexNav"),
				:active_proc => Proc.new {
					next dexNavActive?
				},
				:press_proc => Proc.new { |scene|
					pbPlayDecisionSE
					pbFadeOutIn {
						dexnavScene = NewDexNav.new
						scene.pbEndScene
						next true
					}
				}
			},
			:TRIBAL_BONUS => {
				:label => _INTL("Tribes"),
				:press_proc => Proc.new { |scene|
					pbFadeOutIn {
						tribalBonusScene = TribalBonusScene.new
						screen = TribalBonusScreen.new(tribalBonusScene)
						screen.pbStartScreen

						scene.drawButtons
					}
				}
			},
			:GAME_INFO => {
				:label => _INTL("Game State"),
				:press_proc => Proc.new { |scene|
					storedLastMenuChoice = $PokemonTemp.menuLastChoice
					$PokemonTemp.menuLastChoice = 0
					
					pbPlayDecisionSE
					infoMenuScene = PokemonGameInfoMenu_Scene.new
					infoMenuScreen = PokemonGameInfoMenu.new(infoMenuScene)
					infoMenuScreen.pbStartPokemonMenu

					scene.drawButtons
					
					$PokemonTemp.menuLastChoice = storedLastMenuChoice
				},
			},
			:OPTIONS => {
				:label => _INTL("Options"),
				:press_proc => Proc.new { |scene|
					storedLastMenuChoice = $PokemonTemp.menuLastChoice
					$PokemonTemp.menuLastChoice = 0
					
					pbPlayDecisionSE
					optionScene = PokemonOption_Scene.new
					optionScreen = PokemonOptionMenu.new(optionScene)
					optionScreen.pbStartPokemonMenu

					scene.drawButtons

					$PokemonTemp.menuLastChoice = storedLastMenuChoice
				},
			},
			:SAVE => {
				:label => _INTL("Save/Quit"),
				:active_proc => Proc.new {
					next !$game_system.nil? && !$game_system.save_disabled
				},
				:press_proc => Proc.new { |scene|
					scene.pbHideMenu
					saveScene = PokemonSave_Scene.new
					screen = PokemonSaveScreen.new(saveScene)
          quitResult = screen.pbSaveScreen(true)
          if quitResult == 1 # Quit to menu
            $scene.disposeSpritesets if $scene.is_a?(Scene_Map)
            scene.pbEndScene
            loadScene = PokemonLoad_Scene.new
            loadScreen = PokemonLoadScreen.new(loadScene)
            loadScreen.pbStartLoadScreen
            next true
          elsif quitResult == 2 # Quit to desktop
						scene.pbEndScene
						$scene = nil
						next true
					else
						scene.drawButtons
						scene.pbShowMenu
					end
				}
			},
		}
		if $DEBUG
			@yOffset -= 20
			@buttonRowHeight -= 8
			@cardButtons[:DEBUG] = {
				:label => _INTL("Debug"),
				:press_proc => Proc.new { |scene|
					pbPlayDecisionSE
					pbFadeOutIn {
						pbDebugMenu
						scene.drawButtons
					}
				},
			}
		end
	end

	def onMenuClose
		$PokemonTemp.menuLastChoice = @buttonSelectionIndex
	end

	def defaultCursorPosition
		$PokemonTemp.menuLastChoice
	end

	def pbStartScene
		super
		pbSEPlay("GUI menu open")
	end
end
  

class TilingCardsPauseMenu < TilingCardsMenu_Screen
	def pbStartPokemonMenu
		if !$Trainer
			if $DEBUG
				pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
				pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
			end
			return
		end
		super
	end
end