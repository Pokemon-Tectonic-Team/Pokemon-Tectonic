class SpeciesHandlerHash < HandlerHash2
end

module MultipleForms
  @@formSpecies = SpeciesHandlerHash.new

  def self.copy(sym,*syms)
    @@formSpecies.copy(sym,*syms)
  end

  def self.register(sym,hash)
    @@formSpecies.add(sym,hash)
  end

  def self.registerIf(cond,hash)
    @@formSpecies.addIf(cond,hash)
  end

  def self.hasFunction?(pkmn,func)
    spec = (pkmn.is_a?(Pokemon)) ? pkmn.species : pkmn
    sp = @@formSpecies[spec]
    return sp && sp[func]
  end

  def self.getFunction(pkmn,func)
    spec = (pkmn.is_a?(Pokemon)) ? pkmn.species : pkmn
    sp = @@formSpecies[spec]
    return (sp && sp[func]) ? sp[func] : nil
  end

  def self.call(func,pkmn,*args)
    sp = @@formSpecies[pkmn.species]
    return nil if !sp || !sp[func]
    return sp[func].call(pkmn,*args)
  end
end



def drawSpot(bitmap,spotpattern,x,y,red,green,blue)
  height = spotpattern.length
  width  = spotpattern[0].length
  for yy in 0...height
    spot = spotpattern[yy]
    for xx in 0...width
      if spot[xx]==1
        xOrg = (x+xx)<<1
        yOrg = (y+yy)<<1
        color = bitmap.get_pixel(xOrg,yOrg)
        r = color.red+red
        g = color.green+green
        b = color.blue+blue
        color.red   = [[r,0].max,255].min
        color.green = [[g,0].max,255].min
        color.blue  = [[b,0].max,255].min
        bitmap.set_pixel(xOrg,yOrg,color)
        bitmap.set_pixel(xOrg+1,yOrg,color)
        bitmap.set_pixel(xOrg,yOrg+1,color)
        bitmap.set_pixel(xOrg+1,yOrg+1,color)
      end
    end
  end
end

def pbSpindaSpots(pkmn,bitmap)
  spot1 = [
     [0,0,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,0,0]
  ]
  spot2 = [
     [0,0,1,1,1,0,0],
     [0,1,1,1,1,1,0],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1],
     [0,1,1,1,1,1,0],
     [0,0,1,1,1,0,0]
  ]
  spot3 = [
     [0,0,0,0,0,1,1,1,1,0,0,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1,1],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,1,1,1,1,1,1,1,0,0,0],
     [0,0,0,0,0,1,1,1,0,0,0,0,0]
  ]
  spot4 = [
     [0,0,0,0,1,1,1,0,0,0,0,0],
     [0,0,1,1,1,1,1,1,1,0,0,0],
     [0,1,1,1,1,1,1,1,1,1,0,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,1],
     [1,1,1,1,1,1,1,1,1,1,1,0],
     [0,1,1,1,1,1,1,1,1,1,1,0],
     [0,0,1,1,1,1,1,1,1,1,0,0],
     [0,0,0,0,1,1,1,1,1,0,0,0]
  ]
  id = pkmn.aestheticsID
  h = (id>>28)&15
  g = (id>>24)&15
  f = (id>>20)&15
  e = (id>>16)&15
  d = (id>>12)&15
  c = (id>>8)&15
  b = (id>>4)&15
  a = (id)&15
  if pkmn.shiny?
    drawSpot(bitmap,spot1,b+33,a+25,-75,-10,-150)
    drawSpot(bitmap,spot2,d+21,c+24,-75,-10,-150)
    drawSpot(bitmap,spot3,f+39,e+7,-75,-10,-150)
    drawSpot(bitmap,spot4,h+15,g+6,-75,-10,-150)
  else
    drawSpot(bitmap,spot1,b+33,a+25,0,-115,-75)
    drawSpot(bitmap,spot2,d+21,c+24,0,-115,-75)
    drawSpot(bitmap,spot3,f+39,e+7,0,-115,-75)
    drawSpot(bitmap,spot4,h+15,g+6,0,-115,-75)
  end
end

#===============================================================================
# Regular form differences
#===============================================================================

MultipleForms.register(:UNOWN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(28)
  }
})

MultipleForms.register(:SPINDA,{
  "alterBitmap" => proc { |pkmn,bitmap|
    pbSpindaSpots(pkmn,bitmap)
  }
})

MultipleForms.register(:CASTFORM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:GROUDON,{
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:REDORB)
    next
  }
})

MultipleForms.register(:KYOGRE,{
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:BLUEORB)
    next
  }
})

MultipleForms.register(:RAYQUAZA,{
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasMove?(:DRAGONASCENT)
    next
  }
})

MultipleForms.register(:BURMY,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:WORMADAM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:CHERRIM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ROTOM,{
  "onSetForm" => proc { |pkmn, form, oldForm|
    form_moves = GameData::Species.get(:ROTOM).form_specific_moves
    move_index = -1
    pkmn.moves.each_with_index do |move, i|
      next if !form_moves.any? { |m| m == move.id }
      move_index = i
      break
    end
    if form == 0
      # Turned back into the base form; forget form-specific moves
      if move_index >= 0
        move_name = pkmn.moves[move_index].name
        pkmn.forget_move_at_index(move_index)
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, move_name))
        pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves == 0
      end
    else
      # Turned into an alternate form; try learning that form's unique move
      new_move_id = form_moves[form]
      if move_index >= 0
        # Knows another form's unique move; replace it
        old_move_name = pkmn.moves[move_index].name
        if GameData::Move.exists?(new_move_id)
          pkmn.moves[move_index].id = new_move_id
          new_move_name = pkmn.moves[move_index].name
          pbMessage(_INTL("{1} forgot how to use {2}.\\nAnd...\1", pkmn.name, old_move_name))
          pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]", pkmn.name, new_move_name))
        else
          pkmn.forget_move_at_index(move_index)
          pbMessage(_INTL("{1} forgot {2}...", pkmn.name, old_move_name))
          pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves == 0
        end
      else
        # Just try to learn this form's unique move
        pbLearnMove(pkmn, new_move_id, true)
      end
    end
  }
})

MultipleForms.register(:ARCEUS,{
  "getForm" => proc { |pkmn|
    next 0 unless pkmn.hasAbility?(:MULTITYPE)
    next 0 unless pkmn.hasItem?(:PRISMATICPLATE)
    next GameData::Type.get(pkmn.itemTypeChosen).id_number
  }
})

MultipleForms.register(:BASCULIN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(2)
  }
})


MultipleForms.register(:KYUREM,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form+2 if pkmn.form==1 || pkmn.form==2
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-2 if pkmn.form>=3   # Fused forms stop glowing
  },
  "onSetForm" => proc { |pkmn, form, oldForm|
    case form
    when 0   # Normal
      pkmn.moves.each do |move|
        if [:ICEBURN, :FREEZESHOCK].include?(move.id)
          move.id = :GLACIATE if GameData::Move.exists?(:GLACIATE)
        end
        if [:FUSIONFLARE, :FUSIONBOLT].include?(move.id)
          move.id = :SCARYFACE if GameData::Move.exists?(:SCARYFACE)
        end
      end
    when 1   # White
      pkmn.moves.each do |move|
        move.id = :ICEBURN if move.id == :GLACIATE && GameData::Move.exists?(:ICEBURN)
        move.id = :FUSIONFLARE if move.id == :SCARYFACE && GameData::Move.exists?(:FUSIONFLARE)
      end
    when 2   # Black
      pkmn.moves.each do |move|
        move.id = :FREEZESHOCK if move.id == :GLACIATE && GameData::Move.exists?(:FREEZESHOCK)
        move.id = :FUSIONBOLT if move.id == :SCARYFACE && GameData::Move.exists?(:FUSIONBOLT)
      end
    end
  }
})

MultipleForms.register(:KELDEO,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasMove?(:SECRETSWORD) # Resolute Form
    next 0                                # Ordinary Form
  }
})

MultipleForms.register(:GENESECT,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:SHOCKDRIVE)
    next 2 if pkmn.hasItem?(:BURNDRIVE)
    next 3 if pkmn.hasItem?(:CHILLDRIVE)
    next 4 if pkmn.hasItem?(:DOUSEDRIVE)
    next 0
  }
})

MultipleForms.register(:CRAMORANT,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:SCATTERBUG,{
  "getFormOnCreation" => proc { |pkmn|
    next $Trainer.secret_ID % 18
  }
})

MultipleForms.copy(:SCATTERBUG,:SPEWPA,:VIVILLON)

MultipleForms.register(:ESPURR,{
  "getFormOnCreation" => proc { |pkmn|
    next pkmn.gender
  }
})

MultipleForms.copy(:ESPURR,:MEOWSTIC)

MultipleForms.register(:AEGISLASH,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:XERNEAS,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next 1
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ZYGARDE,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 3 if pkmn.form==2 && (pkmn.fainted? || endBattle)
  }
})

MultipleForms.register(:ORICORIO,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(4)   # 0=red, 1=yellow, 2=pink, 3=purple
  },
})


MultipleForms.register(:WISHIWASHI,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:SILVALLY,{
  "getForm" => proc { |pkmn|
    next 0 unless pkmn.hasAbility?(:RKSSYSTEM)
    next 0 unless pkmn.hasItem?(:MEMORYSET)
    next GameData::Type.get(pkmn.itemTypeChosen).id_number
  }
})

MultipleForms.register(:MINIOR,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(7)   # Meteor forms are 0-6, Core forms are 7-13
  },
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form-7 if pkmn.form>=7
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-7 if pkmn.form>=7 && endBattle
  }
})

MultipleForms.register(:MIMIKYU,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:NECROZMA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    # Fused forms are 1 and 2, Ultra form is 3 or 4 depending on which fusion
    next pkmn.form-2 if pkmn.form>=3 && (pkmn.fainted? || endBattle)
  },
  "onSetForm" => proc { |pkmn, form, oldForm|
    next if form > 2 || oldForm > 2   # Ultra form changes don't affect moveset
    form_moves = GameData::Species.get(:NECROZMA).form_specific_moves
    if form == 0
      # Turned back into the base form; forget form-specific moves
      move_index = -1
      pkmn.moves.each_with_index do |move, i|
        next if !form_moves.any? { |m| m == move.id }
        move_index = i
        break
      end
      if move_index >= 0
        move_name = pkmn.moves[move_index].name
        pkmn.forget_move_at_index(move_index)
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, move_name))
        pbLearnMove(:CONFUSION) if pkmn.numMoves == 0
      end
    else
      # Turned into an alternate form; try learning that form's unique move
      new_move_id = form_moves[form]
      pbLearnMove(pkmn, new_move_id, true)
    end
  }
})

MultipleForms.register(:AMPHAROS, {
    "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
        next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
    },
})

MultipleForms.register(:GARCHOMP, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:GYARADOS, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:LYCANROC, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:MEWTWO, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.fainted? || endBattle
  },
})

MultipleForms.register(:ZAMAZENTA,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:RUSTEDSHIELD)
    next 0
  },
  "onSetForm" => proc { |pkmn, form, oldForm|
    case form
    when 0   # Normal
      pkmn.moves.each do |move|
        if [:BEHEMOTHBASH].include?(move.id)
          move.id = :IRONHEAD if GameData::Move.exists?(:IRONHEAD)
        end
      end
    when 1   # Crowned
      pkmn.moves.each do |move|
        move.id = :BEHEMOTHBASH if move.id == :IRONHEAD && GameData::Move.exists?(:BEHEMOTHBASH)
      end
    end
  }
})

MultipleForms.register(:ZACIAN,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:RUSTEDSWORD)
    next 0
  },
  "onSetForm" => proc { |pkmn, form, oldForm|
    case form
    when 0   # Normal
      pkmn.moves.each do |move|
        if [:BEHEMOTHBLADE].include?(move.id)
          move.id = :IRONHEAD if GameData::Move.exists?(:IRONHEAD)
        end
      end
    when 1   # Crowned
      pkmn.moves.each do |move|
        move.id = :BEHEMOTHBLADE if move.id == :IRONHEAD && GameData::Move.exists?(:BEHEMOTHBLADE)
      end
    end
  }
})

MultipleForms.register(:PUMPKABOO, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.fainted? || endBattle
  },
})

MultipleForms.register(:GOURGEIST, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.fainted? || endBattle
  },
})

MultipleForms.register(:GARDEVOIR, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:GALLADE, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:MAROMATISSE, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:EISCUE, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:URSHIFU,{
  "onSetForm" => proc { |pkmn, form, oldForm|
    form_moves = GameData::Species.get(:URSHIFU).form_specific_moves
    move_index = -1
    pkmn.moves.each_with_index do |move, i|
      next if !form_moves.any? { |m| m == move.id }
      move_index = i
      break
    end
    # Turned into an alternate form; try learning that form's unique move
    new_move_id = form_moves[form]
    if move_index >= 0
      # Knows another form's unique move; replace it
      old_move_name = pkmn.moves[move_index].name
      pkmn.moves[move_index].id = new_move_id
      new_move_name = pkmn.moves[move_index].name
      pbMessage(_INTL("{1} forgot how to use {2}.\\nAnd...\1", pkmn.name, old_move_name))
      pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]", pkmn.name, new_move_name))
    else
      # Just try to learn this form's unique move
      pbLearnMove(pkmn, new_move_id, true)
    end
  }
})

MultipleForms.register(:MORPEKO, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:INDEEDEE,{
  "getFormOnCreation" => proc { |pkmn|
    next pkmn.gender
  },
})

MultipleForms.register(:DIANCIE, {
    "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
        next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
    },
})