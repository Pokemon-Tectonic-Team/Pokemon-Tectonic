class PokemonBag
    attr_accessor :lastpocket
  
    def self.pocketNames
      return Settings.bag_pocket_names
    end
  
    def self.numPockets
      return self.pocketNames.length-1
    end
  
    def initialize
      @lastpocket = 1
      @pockets    = []
      @choices    = []
      for i in 0..PokemonBag.numPockets
        @pockets[i] = []
        @choices[i] = 0
      end
      @registeredItems = []
      @registeredIndex = [0, 0, 1]
    end
  
    def rearrange
      if (@pockets.length - 1) != PokemonBag.numPockets
        newpockets = []
        for i in 0..PokemonBag.numPockets
          newpockets[i] = []
          @choices[i] = 0 if !@choices[i]
        end
        num_pockets = PokemonBag.numPockets
        for i in 0...[@pockets.length, num_pockets].min
          for item in @pockets[i]
            p = GameData::Item.get(item[0]).pocket
            newpockets[p].push(item)
          end
        end
        @pockets = newpockets
      end
    end
  
    def reassignPockets
      hashOfAllItems = {}
      for i in 0..PokemonBag.numPockets
          @pockets[i].each do |item_element|
              itemID = item_element[0]
              next unless GameData::Item.try_get(itemID)
              itemCount = item_element[1]
              if hashOfAllItems.has_key?(itemID)
                  hashOfAllItems[itemID] += itemCount
              else
                  hashOfAllItems[itemID] = itemCount
              end
          end
          @pockets[i] = []
      end
  
      hashOfAllItems.each do |key, value|
          echoln("Storing #{value} of #{key} back into the bag")
          pbStoreItem(key, value)
      end
  end
  
    def clear
      @pockets.each { |pocket| pocket.clear }
    end
  
    def pockets
      rearrange
      return @pockets
    end
  
    def maxPocketSize(pocket)
      return -1
    end
  
    # Gets the index of the current selected item in the pocket
    def getChoice(pocket)
      if pocket <= 0 || pocket > PokemonBag.numPockets
        raise ArgumentError.new(_INTL("Invalid pocket: {1}", pocket.inspect))
      end
      rearrange
      return [@choices[pocket], @pockets[pocket].length].min || 0
    end
  
    # Sets the index of the current selected item in the pocket
    def setChoice(pocket,value)
      if pocket <= 0 || pocket > PokemonBag.numPockets
        raise ArgumentError.new(_INTL("Invalid pocket: {1}", pocket.inspect))
      end
      rearrange
      @choices[pocket] = value if value <= @pockets[pocket].length
    end
  
    def getAllChoices
      ret = @choices.clone
      for i in 0...@choices.length
        @choices[i] = 0
      end
      return ret
    end
  
    def setAllChoices(choices)
      @choices = choices
    end
  
    def pbQuantity(item)
      item = GameData::Item.get(item)
      pocket = item.pocket
      return ItemStorageHelper.pbQuantity(@pockets[pocket], item.id)
    end
  
    def pbHasItem?(item)
      return pbQuantity(item) > 0
    end
  
    def pbCanStore?(item, qty = 1)
      item = GameData::Item.get(item)
      pocket = item.pocket
      maxsize = maxPocketSize(pocket)
      maxsize = @pockets[pocket].length + 1 if maxsize < 0
      return ItemStorageHelper.pbCanStore?(
         @pockets[pocket], maxsize, Settings::BAG_MAX_PER_SLOT, item.id, qty)
    end
  
    def pbStoreItem(item, qty = 1, sort = true)
      item = GameData::Item.get(item)
      pocket = item.pocket
      maxsize = maxPocketSize(pocket)
      maxsize = @pockets[pocket].length + 1 if maxsize < 0
      return ItemStorageHelper.pbStoreItem(
         @pockets[pocket], maxsize, Settings::BAG_MAX_PER_SLOT, item.id, qty, sort)
    end
  
    def pbStoreAllOrNone(item, qty = 1)
      return false if !pbCanStore?(item, qty)
      return pbStoreItem(item, qty)
    end
  
    def pbChangeItem(old_item, new_item)
      old_item = GameData::Item.get(old_item)
      new_item = GameData::Item.get(new_item)
      pocket = old_item.pocket
      ret = false
      @pockets[pocket].each do |item|
        next if !item || item[0] != old_item.id
        item[0] = new_item.id
        ret = true
      end
      return ret
    end
  
    def pbChangeQuantity(pocket, index, newqty = 1)
      return false if pocket <= 0 || pocket > self.numPockets
      return false if !@pockets[pocket][index]
      newqty = [newqty, maxPocketSize(pocket)].min
      @pockets[pocket][index][1] = newqty
      return true
    end
  
    def pbDeleteItem(item, qty = 1)
      item = GameData::Item.get(item)
      pocket = item.pocket
      ret = ItemStorageHelper.pbDeleteItem(@pockets[pocket], item.id, qty)
      return ret
    end
  
    def registeredItems
      @registeredItems = [] if !@registeredItems
      return @registeredItems
    end
  
    def pbIsRegistered?(item)
      item = GameData::Item.get(item).id
      registeredlist = self.registeredItems
      return registeredlist.include?(item)
    end
  
    # Registers the item in the Ready Menu.
    def pbRegisterItem(item)
      item = GameData::Item.get(item).id
      registeredlist = self.registeredItems
      registeredlist.push(item) if !registeredlist.include?(item)
    end
  
    # Unregisters the item from the Ready Menu.
    def pbUnregisterItem(item)
      item = GameData::Item.get(item).id
      registeredlist = self.registeredItems
      for i in 0...registeredlist.length
        next if registeredlist[i] != item
        registeredlist[i] = nil
        break
      end
      registeredlist.compact!
    end
  
    def registeredIndex
      @registeredIndex = [0, 0, 1] if !@registeredIndex
      return @registeredIndex
    end
  
    def sortItems
      @pockets.each do |pocket|
        ItemStorageHelper.sortItems(pocket)
      end
    end
  end

  
#===============================================================================
# Shortcut methods
#===============================================================================
def pbQuantity(*args)
  return $PokemonBag.pbQuantity(*args)
end

def pbHasItem?(*args)
  return $PokemonBag.pbHasItem?(*args)
end

def pbCanStore?(*args)
  return $PokemonBag.pbCanStore?(*args)
end

def pbStoreItem(*args)
  return $PokemonBag.pbStoreItem(*args)
end

def pbStoreAllOrNone(*args)
  return $PokemonBag.pbStoreAllOrNone(*args)
end

def pbDeleteItem(item,amount=1)
	$PokemonBag.pbDeleteItem(item,amount)
end

def pbSilentItem(item,quantity=1)
	$PokemonBag.pbStoreItem(item,quantity)
end

def pbRegisterItem(item)
  $PokemonBag.pbRegisterItem(item)
end