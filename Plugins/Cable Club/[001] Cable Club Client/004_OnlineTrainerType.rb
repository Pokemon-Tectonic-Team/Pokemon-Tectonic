class Player
  attr_writer :online_trainer_type
  def online_trainer_type
    return @online_trainer_type || self.trainer_type
  end
  
  attr_writer :online_win_text
  def online_win_text
    return @online_win_text || 0
  end
  attr_writer :online_lose_text
    def online_lose_text
    return @online_lose_text || 0
  end
end

class NPCTrainer
  attr_accessor :win_text
  alias _cc_initialize initialize
  def initialize(name, trainer_type)
    _cc_initialize(name, trainer_type)
    @win_text = nil
  end
end

module CableClub
  @@onUpdateTrainerType                 = Event.new
  
  # Fires whenever the online_trainer_type is changed
  # Parameters:
  # e[0] - the new online_trainer_type
  def self.onUpdateTrainerType;     @@onUpdateTrainerType;     end
  def self.onUpdateTrainerType=(v); @@onUpdateTrainerType = v; end
end