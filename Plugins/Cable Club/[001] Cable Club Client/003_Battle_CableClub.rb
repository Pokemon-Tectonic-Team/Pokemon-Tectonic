# super ugly convoluted vibe coded hack to make Array.sample predictable
# but i tested it and it seems to work - LunaFlare
module DeterministicSample
  def self.included(base)
    base.prepend(InstanceMethods)
  end

  module InstanceMethods
    def initialize(*args)
      super
      override_array_sample
    end

    private

    def override_array_sample
      Array.class_eval do
        unless method_defined?(:cable_club_sample)
          alias_method :original_ruby_sample, :sample
          
          define_method :cable_club_sample do |n = nil, random: nil|
            # Get the current battle instance dynamically
            battle = Thread.current[:current_cable_club_battle]
            return original_ruby_sample(n, random: random) unless battle&.respond_to?(:pbRandom)
            if n.nil?
              # Sample single element
              return nil if empty?
              self[battle.pbRandom(length)]
            else
              # Sample n elements (without replacement by default)
              return [] if n <= 0 || empty?
              n = [n, length].min
              
              # Use reservoir sampling algorithm with pbRandom
              result = []
              self.each_with_index do |item, index|
                if index < n
                  result << item
                else
                  # Random index from 0 to index (inclusive)
                  j = battle.pbRandom(index + 1)
                  if j < n
                    result[j] = item
                  end
                end
              end
              result
            end
          end
          
          define_method :sample do |n = nil, random: nil|
            # Use deterministic sample if we have access to the battle instance
            battle = Thread.current[:current_cable_club_battle]
            if battle&.respond_to?(:pbRandom)
              cable_club_sample(n, random: random)
            else
              original_ruby_sample(n, random: random)
            end
          end
        end
      end
    end
  end
end

class PokeBattle_Battle
  attr_reader :client_id
  def is_online?
    return @client_id != nil
  end
end

class PokeBattle_CableClub < PokeBattle_Battle
  include DeterministicSample
  attr_reader :connection
  attr_reader :battleRNG
  attr_reader :rngCalls
  def initialize(connection, client_id, scene, player_party, opponent_party, opponent, seed)
    @connection = connection
    @client_id = client_id
    # Disable custom backsprite feature because overriding the player Trainer messes with Tribes
    # online_back_check = GameData::TrainerType.player_back_sprite_filename($Trainer.online_trainer_type)
    # if online_back_check
    #   player = NPCTrainer.new($Trainer.name, $Trainer.online_trainer_type)
    # else
    #   player = NPCTrainer.new($Trainer.name, $Trainer.trainertype)
    # end
    # attach parties to trainers for tribe calculations
    # player.party = player_party
    player = $Trainer
    opponent.party = opponent_party
    Thread.current[:current_cable_club_battle] = self
    super(scene, player_party, opponent_party, [player], [opponent])
    @battleAI  = PokeBattle_CableClub_AI.new(self)
    @battleRNG = Random.new(seed)
    @rngCalls = 0
  end

  # Override command phase to swap AI and player order
  def pbCommandPhase
      @scene.pbBeginCommandPhase

      # Reset choices if commands can be shown
      @battlers.each_with_index do |b, i|
          next unless b
          pbClearChoice(i) if pbCanShowCommands?(i)
      end

      # Reset choices to perform Mega Evolution if it wasn't done somehow
      for side in 0...2
          @megaEvolution[side].each_with_index do |megaEvo, i|
              @megaEvolution[side][i] = -1 if megaEvo >= 0
          end
      end

      preSelectionAlerts

      if pbCheckGlobalAbility(:INVESTIGATOR)
          # Each of the player's pokemon (or NPC allies)
          eachSameSideBattler do |b|
              next unless b.hasActiveAbility?(:INVESTIGATOR)
              possibleInvestigation = []
              b.eachOpposing do |bOpp|
                  next if bOpp.fainted?
                  possibleInvestigation.push(bOpp)
              end
              next if possibleInvestigation.length == 0
              investigating = possibleInvestigation.sample
              pbShowAbilitySplash(b, :INVESTIGATOR)
              # Cannot predict opponent online
              pbDisplay(_INTL("{1} cannot get a read on {2}!", b.pbThis, investigating.pbThis(true)))
              pbHideAbilitySplash(b)
          end
      end

      # Choose actions for the round (Player first, then "AI" online oponent)

      # Turn skipped due to ambush
      if @turnCount == 0 && @foeAmbushing
          # The player is ambushed by the foe!
          pbDisplayBossNarration(_INTL("You were <imp>ambushed</imp>! The foe gets a free turn!"))
          eachSameSideBattler do |b|
              b.extraMovesPerTurn = 0
          end
      else
          pbCommandPhaseLoop(true) # Player chooses their actions
      end

      # Turn skipped due to ambush
      if @turnCount == 0 && @playerAmbushing
          # Player ambushes successfully!
          pbDisplayBossNarration(_INTL("Your foe was <imp>ambushed</imp>! You get a free turn!"))
          eachOtherSideBattler do |b|
              b.extraMovesPerTurn = 0
          end
      else
          # AI chooses their actions
          pbCommandPhaseLoop(false)
      end

      return if @decision != 0 # Battle ended, stop choosing actions

      triggerAllChoicesDialogue
  end
  
  def pbRandom(x)
    @rngCalls += 1
    echoln("RNG calls this battle: #{rngCalls}")
    return @battleRNG.rand(x)
  end

  def dispose
    Thread.current[:current_cable_club_battle] = nil
    super
  end

  # Added optional args to not make v18 break.
  def pbSwitchInBetween(index, lax=false, cancancel=false, safeSwitch=nil)
    if pbOwnedByPlayer?(index)
      choice = super(index, checkLaxOnly: lax, canCancel: cancancel, safeSwitch: safeSwitch)
      # bug fix for the unknown type :switch. cause: going into the pokemon menu then backing out and attacking, which sends the switch symbol regardless.
      if !cancancel # forced switches do not allow canceling, and both sides would expect a response.
        @connection.send do |writer|
          writer.sym(:switch)
          writer.int(choice)
        end
      end
      return choice
    else
      frame = 0
      @scene.pbShowWindow(PokeBattle_Scene::MESSAGE_BOX)
      cw = @scene.sprites["messageWindow"]
      cw.letterbyletter = false
      begin
        loop do
          frame += 1
          cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
          @scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::BACK) && pbConfirmMessageSerious("Would you like to disconnect?")
          @connection.update do |record|
            case (type = record.sym)
            when :forfeit
              pbSEPlay("Battle flee")
              pbDisplay(_INTL("{1} forfeited the match!", @opponent[0].full_name))
              @decision = 1
              pbAbort

            when :switch
              return record.int

            else
              raise "Unknown message: #{type}"
            end
          end
        end
      ensure
        cw.letterbyletter = false
      end
    end
  end

  def pbRun(idxPokemon, duringBattle=false)
    ret = super(idxPokemon, duringBattle)
    if ret == 1
      @connection.send do |writer|
        writer.sym(:forfeit)
      end
      @connection.discard(1)
    end
    return ret
  end

  # Rearrange the battlers into a consistent order, do the function, then restore the order.
  def pbCalculatePriority(*args)
    battlers = @battlers.dup
    begin
      order = CableClub::pokemon_order(@client_id)
      order.each_with_index do |o,i|
        @battlers[i] = battlers[o]
      end
      return super(*args)
    ensure
      @battlers = battlers
    end
  end
  
  def pbCanShowCommands?(idxBattler)
    last_index = pbGetOpposingIndicesInOrder(0).reverse.last
    return true if last_index==idxBattler
    return super(idxBattler)
  end
  
  # avoid unnecessary checks and check in same order
  def pbEORSwitch(favorDraws=false)
    return if @decision>0 && !favorDraws
    return if @decision==5 && favorDraws
    pbJudge
    return if @decision>0
    # Check through each fainted battler to see if that spot can be filled.
    switched = []
    loop do
      switched.clear
      # check in same order
      battlers = []
      order = CableClub::pokemon_order(@client_id)
      order.each_with_index do |o,i|
        battlers[i] = @battlers[o]
      end
      battlers.each do |b|
        next if !b || !b.fainted?
        idxBattler = b.index
        next if !pbCanChooseNonActive?(idxBattler)
        if !pbOwnedByPlayer?(idxBattler)   # Opponent/ally is switching in
          idxPartyNew = pbSwitchInBetween(idxBattler)
          opponent = pbGetOwnerFromBattlerIndex(idxBattler)
          pbRecallAndReplace(idxBattler,idxPartyNew)
          switched.push(idxBattler)
        else
          idxPlayerPartyNew = pbGetReplacementPokemonIndex(idxBattler)   # Owner chooses
          pbRecallAndReplace(idxBattler,idxPlayerPartyNew)
          switched.push(idxBattler)
        end
      end
      break if switched.length==0
      pbPriority(true).each do |b|
        b.pbEffectsOnSwitchIn(true) if switched.include?(b.index)
      end
    end
  end
end

class PokeBattle_CableClub_AI < PokeBattle_AI
  def pbDefaultChooseEnemyCommand(index)
    echoln("Cable Club: Start AI check")
    # Hurray for default methods. have to reverse it to show the expected order.
    our_indices = @battle.pbGetOpposingIndicesInOrder(1).reverse
    their_indices = @battle.pbGetOpposingIndicesInOrder(0).reverse
    # Sends our choices after they have all been locked in.
    if index == their_indices.last
      echoln("Cable Club: Sending choices")
      # TODO: patch this up to be index agnostic.
      # Would work fine if restricted to single/double battles
      target_order = CableClub::pokemon_target_order(@battle.client_id)
      @battle.connection.send do |writer|
        writer.sym(:battle_data)
        # Send Seed
        cur_seed=@battle.battleRNG.srand
        @battle.battleRNG.srand(cur_seed)
        writer.sym(:seed)
        writer.int(cur_seed)
        # Send Extra Battle Mechanics
        writer.sym(:mechanic)
        # Mega Evolution
        mega=@battle.megaEvolution[0][0]
        mega^=1 if mega>=0
        writer.int(mega)
        # Send Choices for Player's Mons
        for our_index in our_indices
          pkmn = @battle.battlers[our_index]
          writer.sym(:choice)
          # choice picked was changed to be a symbol now.
          writer.sym(@battle.choices[our_index][0])
          writer.int(@battle.choices[our_index][1])
          move = !!@battle.choices[our_index][2]
          writer.nil_or(:bool, move)
          # -1 invokes the RNG, out of order (somehow?!) which causes desync.
          # But this is a single battle, so the only possible choice is the foe.
          if @battle.singleBattle? && @battle.choices[our_index][3] == -1
            @battle.choices[our_index][3] = their_indices[0]
          end
          # Target from their POV.
          our_target = @battle.choices[our_index][3]
          their_target = target_order[our_target] rescue our_target
          writer.int(their_target)
        end
        echoln("Cable Club: Sent choices")
      end
      frame = 0
      @battle.scene.pbShowWindow(PokeBattle_Scene::MESSAGE_BOX)
      cw = @battle.scene.sprites["messageWindow"]
      cw.letterbyletter = false
      echoln("Cable Club: Waiting for opponent's choices")
      begin
        loop do
          frame += 1
          cw.text = _INTL("Waiting" + "." * (1 + ((frame / 8) % 3)))
          @battle.scene.pbFrameUpdate(cw)
          Graphics.update
          Input.update
          raise Connection::Disconnected.new("disconnected") if Input.trigger?(Input::BACK) && pbConfirmMessageSerious("Would you like to disconnect?")
          @battle.connection.update do |record|
            case (type = record.sym)
            when :forfeit
              echoln("Cable Club: Opponent forfeited")
              pbSEPlay("Battle flee")
              @battle.pbDisplay(_INTL("{1} forfeited the match!", @battle.opponent[0].full_name))
              @battle.decision = 1
              @battle.pbAbort
            
            when :battle_data
              loop do
                case (t = record.sym)
                when :seed
                  seed=record.int()
                  @battle.battleRNG.srand(seed) if @battle.client_id==1
                when :mechanic
                  @battle.megaEvolution[1][0] = record.int
                when :choice
                  echoln("Cable Club: Receiving opponent's choice")
                  their_index = their_indices.shift
                  partner_pkmn = @battle.battlers[their_index]
                  @battle.choices[their_index][0] = record.sym
                  @battle.choices[their_index][1] = record.int
                  move = record.nil_or(:bool)
                  if move
                    move = (@battle.choices[their_index][1]<0) ? @battle.struggle : partner_pkmn.getMoves[@battle.choices[their_index][1]]
                  end
                  @battle.choices[their_index][2] = move
                  @battle.choices[their_index][3] = record.int
                  if their_indices.empty?
                    echoln("Cable Club: Received all opponent's choices")
                    break
                  end
                else
                  raise "Unknown message: #{t}"
                end
              end
              return

            else
              raise "Unknown message: #{type}"
            end
          end
        end
      ensure
        cw.letterbyletter = true
      end
    end
  end

  def pbDefaultChooseNewEnemy(index, party)
    raise "Expected this to be unused."
  end
end

#===============================================================================
# This move permanently turns into the last move used by the target. (Sketch)
#===============================================================================
class PokeBattle_Move_ReplaceMoveWithTargetLastMoveUsed
  alias _cc_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if CableClub::DISABLE_SKETCH_ONLINE && !@battle.internalBattle
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return _cc_pbMoveFailed?(user, targets)
  end
end