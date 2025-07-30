module ItemIconEvents
  ModifyItemIconFileName = HandlerHash2.new
  ModifyItemIconBitmap = HandlerHash2.new

  def self.triggerModifyItemIconFileName(item, iconName)
    ret = ModifyItemIconFileName.trigger(item, iconName)
    return ret.nil? ? iconName : ret
  end
  
  def self.triggerModifyItemIconBitmap(item, iconBitmap)
    ModifyItemIconBitmap.trigger(item, iconBitmap)
  end

  def self.item_dynamic_icon?(item)
    return ModifyItemIconFileName.hasKey?(item) || ModifyItemIconBitmap.hasKey?(item)
  end
end

##############################################
# Modify Item Icon File Name
##############################################
ItemIconEvents::ModifyItemIconFileName.add(:TAROTAMULET,
  proc { |item, iconName|
      iconName += "_ACTIVE" if tarotAmuletActive?    
      next iconName
  }
)

ItemIconEvents::ModifyItemIconFileName.add(:CELLBOOSTER,
  proc { |item, iconName|
      iconName += "_INACTIVE" if cellBoosterInactive?    
      next iconName
  }
)

##############################################
# Modify Item Icon Bitmap
##############################################
ItemIconEvents::ModifyItemIconBitmap.add(:AIDKIT,
  proc { |item, bitmap|
      base = Color.new(235, 235, 235)
      shadow = Color.new(50, 50, 50)
      currentUses = $PokemonGlobal.teamHealerCurrentUses
      if currentUses
        textPos = [currentUses.to_s, 36, 14, 1, base, shadow, true]
        pbDrawTextPositions(bitmap,[textPos])
      end
  }
)

ItemIconEvents::ModifyItemIconBitmap.add(:EXPEZDISPENSER,
  proc { |item, bitmap|
      base = Color.new(235, 235, 235)
      shadow = Color.new(50, 50, 50)
      expAmount = $PokemonGlobal.expJAR || 0
      dividedTimes = 0
      while expAmount >= 1000
        expAmount /= 1000
        dividedTimes += 1
      end
      case dividedTimes
      when 0
        label = expAmount.to_s
      when 1
        label = _INTL("{1}K",expAmount.to_s)
      when 2
        label = _INTL("{1}M",expAmount.to_s)
      when 3
        label = _INTL("{1}B",expAmount.to_s)
      when 4
        label = _INTL("{1}T",expAmount.to_s)
      else
        label = _INTL("Lots")
      end
      textPos = [label, 2, 14, 0, base, shadow, true]
      pbDrawTextPositions(bitmap,[textPos])
  }
)

ItemIconEvents::ModifyItemIconBitmap.add(:OMINOUSEGG,
  proc { |item, bitmap|
      base = Color.new(235, 235, 235)
      shadow = Color.new(50, 50, 50)
      currentUses = getGlobalVariable(TRAINERS_PERFECTED_GLOBAL_VAR)
      if currentUses
        textPos = [currentUses.to_s, 38, 14, 1, base, shadow, true]
        pbDrawTextPositions(bitmap,[textPos])
      end
  }
)