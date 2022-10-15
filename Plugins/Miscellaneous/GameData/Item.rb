module GameData
    class Item
        def self.icon_filename(item)
            return "Graphics/Items/back" if item.nil?
            item_data = self.try_get(item)
            return "Graphics/Items/000" if item_data.nil?
            itemID = item_data.id
            # Check for files
            ret = sprintf("Graphics/Items/%s", itemID)
            if itemID == :TAROTAMULET && $PokemonGlobal.tarot_amulet_active
                ret += "_ACTIVE"
            end
            return ret if pbResolveBitmap(ret)
            # Check for TM/HM type icons
            if item_data.is_machine?
              prefix = "machine"
              if item_data.is_HM?
                prefix = "machine_hm"
              elsif item_data.is_TR?
                prefix = "machine_tr"
              end
              move_type = GameData::Move.get(item_data.move).type
              type_data = GameData::Type.get(move_type)
              ret = sprintf("Graphics/Items/%s_%s", prefix, type_data.id)
              return ret if pbResolveBitmap(ret)
              if !item_data.is_TM?
                ret = sprintf("Graphics/Items/machine_%s", type_data.id)
                return ret if pbResolveBitmap(ret)
              end
            end
            return "Graphics/Items/000"
        end

        def can_hold?;           return !is_important? && @pocket == 5; end

        def is_key_item?;        return @type == 6 || @type == 13; end
        def is_consumable_key_item?;      return @type == 13; end
        
        def is_important?
            return true if is_key_item? || is_HM? || is_TM?
            return false
        end

        def description
            if is_machine?
                return pbGetMessage(MessageTypes::MoveDescriptions, GameData::Move.get(@move).id_number)
            else
                return pbGetMessage(MessageTypes::ItemDescriptions, @id_number)
            end
        end
        
    end
end