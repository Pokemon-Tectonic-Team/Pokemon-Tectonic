#===============================================================================
# Bag mechanics
#===============================================================================
class PokemonBagScreen
    def initialize(scene,bag)
      @bag   = bag
      @scene = scene
    end
  
    def pbStartScreen
        @scene.pbStartScene(@bag)
        item = nil

        openPocketImmediately = false
        
        loop do
          item = @scene.pbChooseItem(openPocketImmediately)
          break if !item
          itm = GameData::Item.get(item)
          cmdUse      = -1
          cmdRegister = -1
          cmdGive     = -1
          cmdToss     = -1
          cmdDebug    = -1
          cmdCancel   = -1
          commands = []
          # Generate command list
          canUseAsTM = itm.is_machine? && $Trainer.party.length > 0
          if ItemHandlers.hasOutHandler(item) || canUseAsTM
            if ItemHandlers.hasUseText(item)
              commands[cmdUse = commands.length]    = ItemHandlers.getUseText(item)
            else
              commands[cmdUse = commands.length]    = _INTL("Use")
            end
          end
          commands[cmdGive = commands.length]       = _INTL("Give") if $Trainer.pokemon_party.length > 0 && itm.can_hold?
          commands[cmdToss = commands.length]       = _INTL("Toss") if !itm.is_important? || $DEBUG
          if @bag.pbIsRegistered?(item)
            commands[cmdRegister = commands.length] = _INTL("Deselect")
          elsif pbCanRegisterItem?(item)
            commands[cmdRegister = commands.length] = _INTL("Register")
          end
          commands[cmdDebug = commands.length]      = _INTL("Debug") if $DEBUG
          commands[cmdCancel = commands.length]     = _INTL("Cancel")
          # Show commands generated above
          itemname = itm.name
          command = @scene.pbShowCommands(_INTL("{1} is selected.",itemname),commands)
          openPocketImmediately = true unless command == cmdCancel
          if cmdUse>=0 && command==cmdUse   # Use item
            if (ItemHandlers.hasUseOnPokemon(item) || canUseAsTM) && !teamEditingAllowed?()
              showNoTeamEditingMessage()
              next
            end
            ret = pbUseItem(@bag,item,@scene)
            # ret: 0=Item wasn't used; 1=Item used; 2=Close Bag to use in field
            break if ret==2   # End screen
            @scene.pbRefresh
            next
          elsif cmdGive>=0 && command==cmdGive   # Give item to Pokémon
            if !teamEditingAllowed?()
              showNoTeamEditingMessage()
              next
            end
            if $Trainer.pokemon_count == 0
              @scene.pbDisplay(_INTL("There is no Pokémon."))
            elsif itm.is_important?
              @scene.pbDisplay(_INTL("The {1} can't be held.",itemname))
            else
              pbFadeOutIn {
                sscene = PokemonParty_Scene.new
                sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
                sscreen.pbPokemonGiveScreen(item)
                @scene.pbRefresh
              }
            end
          elsif cmdToss>=0 && command==cmdToss   # Toss item
            qty = @bag.pbQuantity(item)
            if qty>1
              helptext = _INTL("Toss out how many {1}?",itm.name_plural)
              qty = @scene.pbChooseNumber(helptext,qty)
            end
            if qty>0
              itemname = itm.name_plural if qty>1
              if pbConfirm(_INTL("Is it OK to throw away {1} {2}?",qty,itemname))
                pbDisplay(_INTL("Threw away {1} {2}.",qty,itemname))
                qty.times { @bag.pbDeleteItem(item) }
                @scene.pbRefresh
              end
            end
          elsif cmdRegister>=0 && command==cmdRegister   # Register item
            if @bag.pbIsRegistered?(item)
              @bag.pbUnregisterItem(item)
            else
              @bag.pbRegisterItem(item)
            end
            @scene.pbRefresh
          elsif cmdDebug>=0 && command==cmdDebug   # Debug
            command = 0
            loop do
              command = @scene.pbShowCommands(_INTL("Do what with {1}?",itemname),[
                _INTL("Change quantity"),
                _INTL("Make Mystery Gift"),
                _INTL("Cancel")
                ],command)
              case command
              ### Cancel ###
              when -1, 2
                break
              ### Change quantity ###
              when 0
                qty = @bag.pbQuantity(item)
                itemplural = itm.name_plural
                params = ChooseNumberParams.new
                params.setRange(0, Settings::BAG_MAX_PER_SLOT)
                params.setDefaultValue(qty)
                newqty = pbMessageChooseNumber(
                   _INTL("Choose new quantity of {1} (max. {2}).",itemplural, Settings::BAG_MAX_PER_SLOT),params) { @scene.pbUpdate }
                if newqty>qty
                  @bag.pbStoreItem(item,newqty-qty)
                elsif newqty<qty
                  @bag.pbDeleteItem(item,qty-newqty)
                end
                @scene.pbRefresh
                break if newqty==0
              ### Make Mystery Gift ###
              when 1
                pbCreateMysteryGift(1,item)
              end
            end
          end
        end
        @scene.pbEndScene
        $PokemonTemp.dependentEvents.refresh_sprite(false)
        return item
      end
  
    def pbDisplay(text)
      @scene.pbDisplay(text)
    end
  
    def pbConfirm(text)
      return @scene.pbConfirm(text)
    end
  
    # UI logic for the item screen for choosing an item.
    def pbChooseItemScreen(proc=nil)
      oldlastpocket = @bag.lastpocket
      oldchoices = @bag.getAllChoices
      @scene.pbStartScene(@bag,true,proc)
      item = @scene.pbChooseItem
      @scene.pbEndScene
      @bag.lastpocket = oldlastpocket
      @bag.setAllChoices(oldchoices)
      return item
    end
  
    # UI logic for withdrawing an item in the item storage screen.
    def pbWithdrawItemScreen
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      storage = $PokemonGlobal.pcItemStorage
      @scene.pbStartScene(storage)
      loop do
        item = @scene.pbChooseItem
        break if !item
        itm = GameData::Item.get(item)
        qty = storage.pbQuantity(item)
        if qty>1 && !itm.is_important?
          qty = @scene.pbChooseNumber(_INTL("How many do you want to withdraw?"),qty)
        end
        next if qty<=0
        if @bag.pbCanStore?(item,qty)
          if !storage.pbDeleteItem(item,qty)
            raise "Can't delete items from storage"
          end
          if !@bag.pbStoreItem(item,qty)
            raise "Can't withdraw items from storage"
          end
          @scene.pbRefresh
          dispqty = (itm.is_important?) ? 1 : qty
          itemname = (dispqty>1) ? itm.name_plural : itm.name
          pbDisplay(_INTL("Withdrew {1} {2}.",dispqty,itemname))
        else
          pbDisplay(_INTL("There's no more room in the Bag."))
        end
      end
      @scene.pbEndScene
    end
  
    # UI logic for depositing an item in the item storage screen.
    def pbDepositItemScreen
      @scene.pbStartScene(@bag)
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      storage = $PokemonGlobal.pcItemStorage
      loop do
        item = @scene.pbChooseItem
        break if !item
        itm = GameData::Item.get(item)
        qty = @bag.pbQuantity(item)
        if qty>1 && !itm.is_important?
          qty = @scene.pbChooseNumber(_INTL("How many do you want to deposit?"),qty)
        end
        if qty>0
          if !storage.pbCanStore?(item,qty)
            pbDisplay(_INTL("There's no room to store items."))
          else
            if !@bag.pbDeleteItem(item,qty)
              raise "Can't delete items from Bag"
            end
            if !storage.pbStoreItem(item,qty)
              raise "Can't deposit items to storage"
            end
            @scene.pbRefresh
            dispqty  = (itm.is_important?) ? 1 : qty
            itemname = (dispqty>1) ? itm.name_plural : itm.name
            pbDisplay(_INTL("Deposited {1} {2}.",dispqty,itemname))
          end
        end
      end
      @scene.pbEndScene
    end
  
    # UI logic for tossing an item in the item storage screen.
    def pbTossItemScreen
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      storage = $PokemonGlobal.pcItemStorage
      @scene.pbStartScene(storage)
      loop do
        item = @scene.pbChooseItem
        break if !item
        itm = GameData::Item.get(item)
        if itm.is_important?
          @scene.pbDisplay(_INTL("That's too important to toss out!"))
          next
        end
        qty = storage.pbQuantity(item)
        itemname       = itm.name
        itemnameplural = itm.name_plural
        if qty>1
          qty=@scene.pbChooseNumber(_INTL("Toss out how many {1}?",itemnameplural),qty)
        end
        if qty>0
          itemname = itemnameplural if qty>1
          if pbConfirm(_INTL("Is it OK to throw away {1} {2}?",qty,itemname))
            if !storage.pbDeleteItem(item,qty)
              raise "Can't delete items from storage"
            end
            @scene.pbRefresh
            pbDisplay(_INTL("Threw away {1} {2}.",qty,itemname))
          end
        end
      end
      @scene.pbEndScene
    end
  end
  