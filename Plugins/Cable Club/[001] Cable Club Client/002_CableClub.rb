module CableClub
  ACTIVITY_OPTIONS = {:battle => _INTL("battle"),
                      :trade => _INTL("trade"),
                      :record_mix => _INTL("mix records")}
  def self.pokemon_order(client_id)
    case client_id
    when 0; [0, 1, 2, 3, 4, 5]
    when 1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.pokemon_target_order(client_id)
    case client_id
    when 0..1; [1, 0, 3, 2, 5, 4]
    else; raise "Unknown client_id: #{client_id}"
    end
  end

  def self.do_battle(connection, client_id, seed, battle_rules, player_party, partner, partner_party)
    $Trainer.heal_party # Avoids having to transmit damaged state.
    partner_party.each{|pkmn| pkmn.heal} # back to back battles desync without it.
    oldlevels = battle_rules.adjustLevels($Trainer.party,partner_party)
    olditems  = $Trainer.party.transform { |p| p.items.transform { |i| i } }
    olditems2 = partner_party.transform { |p| p.items.transform { |i| i }  }
    if !DISABLE_SKETCH_ONLINE
      oldmoves  = $player.party.transform { |p| p.moves.dup }
      oldmoves2 = partner_party.transform { |p| p.moves.dup }
    end
    scene = pbNewBattleScene
    battle = PokeBattle_CableClub.new(connection, client_id, scene, player_party, partner_party, partner, seed)
    battle.endSpeechesWin = [partner.win_text]
    battle.endSpeeches = [partner.lose_text]
    battle.items = []
    battle.internalBattle = false
    battle_rules.applyBattleRules(battle)
    trainerbgm = pbGetTrainerBattleBGM(partner)
    Events.onStartBattle.trigger(nil, nil)
    # XXX: Configuring Online Battle Rules
    setBattleRule("environment", :None)
    setBattleRule("weather", :None)
    setBattleRule("terrain", :None)
    setBattleRule("backdrop", "indoor1")
    pbPrepareBattle(battle)
    $PokemonTemp.clearBattleRules
    exc = nil
    pbBattleAnimation(trainerbgm, (battle.singleBattle?) ? 1 : 3, [partner]) {
      pbSceneStandby {
        begin
          battle.pbStartBattle
        rescue Connection::Disconnected
          scene.pbEndBattle(0)
          exc = $!
        ensure
          $Trainer.party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.setItems(olditems[i])
            pkmn.moves = oldmoves[i] if !DISABLE_SKETCH_ONLINE
          end
          partner_party.each_with_index do |pkmn, i|
            pkmn.heal
            pkmn.makeUnmega
            pkmn.makeUnprimal
            pkmn.setItems(olditems2[i])
            pkmn.moves = oldmoves2[i] if !DISABLE_SKETCH_ONLINE
          end
          battle_rules.unadjustLevels($Trainer.party,partner_party,oldlevels)
        end
      }
    }
    raise exc if exc
  end

  def self.do_trade(index, you, your_pkmn)
    my_pkmn = $Trainer.party[index]
    $Trainer.pokedex.register(your_pkmn)
    $Trainer.pokedex.set_owned(your_pkmn.species)
    pbFadeOutInWithMusic(99999) {
      scene = PokemonTrade_Scene.new
      scene.pbStartScreen(my_pkmn, your_pkmn, $Trainer.name, you.name)
      scene.pbTrade
      scene.pbEndScreen
    }
    $Trainer.party[index] = your_pkmn
  end

  def self.choose_pokemon
    chosen = -1
    pbFadeOutIn(99999) {
      scene = PokemonParty_Scene.new
      screen = PokemonPartyScreen.new(scene, $Trainer.party)
      screen.pbStartScene(_INTL("Choose a Pokémon."), false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    }
    return chosen
  end
  
  def self.choose_team(ruleset)
    return (0..$Trainer.party.length - 1).to_a
    # team_order = nil
    # pbFadeOutIn(99999) {
    #   scene = PokemonParty_Scene.new
    #   screen = PokemonPartyScreen.new(scene, $Trainer.party)
    #   team_order = screen.pbPokemonMultipleEntryScreenOrder(ruleset)
    # }
    # return team_order
  end
  
  def self.check_pokemon(pkmn)
    pbFadeOutIn(99999) {
      scene = PokemonSummary_Scene.new
      screen = PokemonSummaryScreen.new(scene,true)
      screen.pbStartScreen([pkmn],0)
    }
  end

  def self.write_party(writer)
    writer.int($Trainer.party_count)
    $Trainer.party.each do |pkmn|
      write_pkmn(writer, pkmn)
    end
  end

  def self.write_pkmn(writer, pkmn)
    writer.sym(pkmn.species)
    writer.int(pkmn.level)
    writer.int(pkmn.personalID)
    writer.int(pkmn.owner.id)
    writer.str(pkmn.owner.name)
    writer.int(pkmn.owner.gender)
    writer.int(pkmn.exp)
    writer.int(pkmn.form)
    writer.nil_or(:sym, pkmn.items[0])
    writer.nil_or(:sym, pkmn.items[1])
    writer.int(pkmn.numMoves)
    pkmn.moves.each do |move|
      writer.sym(move.id)
      writer.int(move.ppup)
    end
    writer.int(pkmn.first_moves.length)
    pkmn.first_moves.each do |move|
      writer.sym(move)
    end
    writer.int(pkmn.gender)
    writer.nil_or(:bool,pkmn.shiny?)
    writer.nil_or(:sym, pkmn.ability_id)
    writer.nil_or(:int, pkmn.ability_index)
    writer.nil_or(:sym, pkmn.nature_id)
    writer.nil_or(:sym, pkmn.nature_for_stats_id)
    GameData::Stat.each_main do |s|
      writer.int(pkmn.ev[s.id])
    end
    writer.int(pkmn.happiness)
    writer.str(pkmn.name)
    writer.sym(pkmn.poke_ball)
    writer.int(pkmn.steps_to_hatch)
    writer.int(pkmn.obtain_method)
    writer.int(pkmn.obtain_map)
    writer.nil_or(:str,pkmn.obtain_text)
    writer.int(pkmn.obtain_level)
    writer.int(pkmn.hatched_map)
    writer.int(pkmn.cool)
    writer.int(pkmn.beauty)
    writer.int(pkmn.cute)
    writer.int(pkmn.smart)
    writer.int(pkmn.tough)
    writer.int(pkmn.sheen)
    writer.int(pkmn.numRibbons)
    pkmn.ribbons.each do |ribbon|
      writer.sym(ribbon)
    end
    writer.bool(!!pkmn.fused)
    if pkmn.fused
      write_pkmn(writer, pkmn.fused)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      writer.str(pkmn.superHue.to_s)
      writer.nil_or(:bool,pkmn.superVariant)
    end
  end

  def self.parse_party(record)
    party = []
    record.int.times do
      party << parse_pkmn(record)
    end
    return party
  end

  def self.parse_pkmn(record)
    species = record.sym
    level = record.int
    pkmn = Pokemon.new(species, level, $Trainer)
    pkmn.personalID = record.int
    pkmn.owner.id = record.int
    pkmn.owner.name = record.str
    pkmn.owner.gender = record.int
    pkmn.exp = record.int
    form = record.int
    #pkmn.forced_form = form if MultipleForms.hasFunction?(pkmn.species,"getForm")
    pkmn.form_simple = form
    items = [record.sym,record.sym]
    # filter out blank items
    items = items.select {|i| i.length > 0}
    pkmn.setItems(items)
    pkmn.forget_all_moves
    record.int.times do |i|
      pkmn.moves[i] = Pokemon::Move.new(record.sym)
      pkmn.moves[i].ppup = record.int
    end
    pkmn.moves.compact!
    pkmn.clear_first_moves
    record.int.times do |i|
      pkmn.add_first_move(record.sym)
    end
    pkmn.gender = record.int
    pkmn.shiny = record.nil_or(:bool)
    pkmn.ability = record.nil_or(:sym)
    pkmn.ability_index = record.nil_or(:int)
    pkmn.nature = record.sym
    pkmn.nature_for_stats = record.nil_or(:sym)
    GameData::Stat.each_main do |s|
      pkmn.ev[s.id] = record.int
    end
    pkmn.happiness = record.int
    pkmn.name = record.str
    pkmn.poke_ball = record.sym
    pkmn.steps_to_hatch = record.int
    pkmn.obtain_method = record.int
    pkmn.obtain_map = record.int
    pkmn.obtain_text = record.nil_or(:str)
    pkmn.obtain_level = record.int
    pkmn.hatched_map = record.int
    pkmn.cool = record.int
    pkmn.beauty = record.int
    pkmn.cute = record.int
    pkmn.smart = record.int
    pkmn.tough = record.int
    pkmn.sheen = record.int
    record.int.times do |i|
      pkmn.giveRibbon(record.sym)
    end
    if record.bool() # fused
      pkmn.fused = parse_pkmn(record)
    end
    if defined?(EliteBattle) # EBDX compat
      # this looks so dumb I know, but the variable can be nil, false, or an int.
      superhue = record.str
      if superhue == ""
        pkmn.superHue = nil
      elsif superhue=="false"
        pkmn.superHue = false
      else
        pkmn.superHue = superhue.to_i
      end
      pkmn.superVariant = record.nil_or(:bool)
    end
    pkmn.calc_stats
    return pkmn
  end

  def self.parse_battle_rules(record)
    rules = []
    record.int.times do
      rules << parse_battle_rule(record)
    end
    return rules
  end
  
  def self.parse_battle_rule(record)
    name = record.str
    desc = record.str
    rule = PokemonOnlineRules.new
    rule.setTeamPreview(record.int)
    rule.setNumberRange(record.int,record.int)
    # level adjustment
    level_adjustment = record.nil_or(:str)
    if level_adjustment
      level_adjustment_data = level_adjustment.split(";")
      level_adjustmentClass = level_adjustment_data.shift
      level_adjustment_args = process_args_type_hint(*level_adjustment_data)
      if Object.const_defined?(level_adjustmentClass)
        rule.setLevelAdjustment(Kernel.const_get(level_adjustmentClass),*level_adjustment_args)
      end
    end
    # battle rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addBattleRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # pokemon rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addPokemonRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # subset rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addSubsetRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    # team rules
    record.int.times do
      clause_data = record.str.split(";")
      clauseClass = clause_data.shift
      clause_args = process_args_type_hint(*clause_data)
      if Object.const_defined?(clauseClass)
        rule.addTeamRule(Kernel.const_get(clauseClass),*clause_args)
      end
    end
    return [name,desc,rule]
  end
  
  def self.write_battle_rule(writer,battle_rule)  
    name,desc,rule = battle_rule
    writer.str(name)
    writer.str(desc)
    writer.int(rule.team_preview)
    writer.int(rule.ruleset.minLength)
    writer.int(rule.ruleset.maxLength)
    if rule.rules_hash[:level_adjust]
      writer.str(rule.rules_hash[:level_adjust].join(";"))
    else
      writer.nil_or(:str,nil)
    end
    writer.int(rule.rules_hash[:battle].length)
    rule.rules_hash[:battle].each do |br|
      writer.str(br.join(";"))
    end
    writer.int(rule.rules_hash[:pokemon].length)
    rule.rules_hash[:pokemon].each do |pr|
      writer.str(pr.join(";"))
    end
    writer.int(rule.rules_hash[:subset].length)
    rule.rules_hash[:subset].each do |sr|
      writer.str(sr.join(";"))
    end
    writer.int(rule.rules_hash[:team].length)
    rule.rules_hash[:team].each do |tr|
      writer.str(tr.join(";"))
    end
  end
  
  def self.get_server_info
    ret = [HOST,PORT]
    if safeExists?("serverinfo.ini")
      File.foreach("serverinfo.ini") do |line|
        case line
        when /^\s*[Hh][Oo][Ss][Tt]\s*=\s*(.+)$/
          ret[0]=$1 if !nil_or_empty?($1)
        when /^\s*[Pp][Oo][Rr][Tt]\s*=\s*(\d{1,5})$/
          if !nil_or_empty?($1)
            port = $1.to_i
            ret[1]= port if port>0 && port<=65535
          end
        end
      end
    end
    return ret
  end
  
  # only handles int, bool, sym, and str
  def self.apply_args_type_hint(*args)
    ret = []
    args.each do |arg|
      case arg
      when Integer; ret.push([:int,arg])
      when TrueClass,FalseClass; ret.push([:bool,arg])
      when String; ret.push([:str,arg])
      when Symbol; ret.push([:sym,arg])
      end
    end
    return ret
  end
  
  # takes a long chain of args, every second element is the original argument
  def self.process_args_type_hint(*args)
    ret = []
    r = nil
    args.each do |arg|
      if r
        case r
        when :int; ret.push(arg.to_i)
        when :bool
          if arg == "true"
            ret.push(true)
          elsif arg == "false"
            ret.push(false)
          else
            raise "expected bool, got #{arg}"
          end
        when :str; ret.push(arg)
        when :sym; ret.push(arg.to_sym)
        end
        r = nil
      else
        r = arg.to_sym
      end
    end
    return ret
  end
end