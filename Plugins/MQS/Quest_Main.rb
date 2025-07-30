#===============================================================================
# This class holds the information for an individual quest
#===============================================================================
class Quest
  attr_accessor :id
  attr_accessor :stage
  attr_accessor :time
  attr_accessor :location
  attr_accessor :new
  attr_accessor :colorID
  attr_accessor :story

  def initialize(id,colorID,story)
    self.id       = id
    self.stage    = 1
    self.time     = $game_map ? Time.now : _INTL("???")
    self.location = $game_map ? $game_map.name : _INTL("???")
    self.new      = true
    self.colorID  = colorID
    self.story    = story
  end
  
  def stage=(value)
    if value > $quest_data.getMaxStagesForQuest(self.id)
      value = $quest_data.getMaxStagesForQuest(self.id)
    end
    @stage = value
  end
end

#===============================================================================
# This class holds all the trainers quests
#===============================================================================
class Player_Quests
  attr_accessor :active_quests
  attr_accessor :completed_quests
  attr_accessor :failed_quests
  attr_accessor :selected_quest_id
  
  def initialize
    @active_quests     = []
    @completed_quests  = []
    @failed_quests     = []
    @selected_quest_id = 0
  end

  def reset
    @active_quests     = []
    @completed_quests  = []
    @failed_quests     = []
    @selected_quest_id = 0
  end
  
  # questID should be the symbolic name of the quest, e.g. :Quest1
  def activateQuest(quest,color=0,story=false,skipAlert: false)
    unless quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        echoln("Asked to activate quest #{quest}, but that quest has already been activated.")
        return false
      end
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        echoln("Asked to activate quest #{quest}, but that quest has already been completed.")
        return false
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        echoln("Asked to activate quest #{quest}, but that quest has already been failed.")
        return false
      end
    end
    @active_quests.push(Quest.new(quest,color,story))
    unless skipAlert
      questAlert(_INTL("\\me[{1}]Quest discovered:","Register phone"),quest)
    end
    return true
  end
  
  def failQuest(quest,color=0,story=false,skipAlert: false)
    unless quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        echoln("Asked to fail quest #{quest}, but that quest has already been completed.")
        return false
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        echoln("Asked to fail quest #{quest}, but that quest has already been failed.")
        return false
      end
    end 
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.colorID = color if color
        temp_quest.new = true # Setting this back to true makes the "!" icon appear when the quest updates
        temp_quest.time = Time.now
        @failed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        unless skipAlert
          questAlert(_INTL("Quest failed:"),quest)
        end
        break
      end
    end
    @failed_quests.push(Quest.new(quest,color,story)) unless found
    return true
  end
  
  def completeQuest(quest,color=0,story=false,skipAlert: false)
    unless quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        echoln("Asked to complete quest #{quest}, but that quest has already been completed.")
        return false
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        echoln("Asked to complete quest #{quest}, but that quest has already been failed.")
        return false
      end
    end
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.colorID = color if color
        temp_quest.new = true # Setting this back to true makes the "!" icon appear when the quest updates
        temp_quest.time = Time.now
        @completed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        unless skipAlert
          questAlert(_INTL("\\me[{1}]Quest completed:","Slots win"),quest)
        end
        break
      end
    end
    @completed_quests.push(Quest.new(quest,color,story)) unless found
    return true
  end
  
  def advanceQuestToStage(quest,stageNum,color=0,story=false,skipAlert: true)
    unless quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    if $quest_data.getMaxStagesForQuest(quest) < stageNum
      raise _INTL("Stage number {1} is too high for quest '{2}'.",stageNum,$quest_data.getName(quest))
    end
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        @active_quests[i].stage = stageNum
        @active_quests[i].colorID = color if color
        @active_quests[i].new = true # Setting this back to true makes the "!" icon appear when the quest updates
        found = true
        unless skipAlert
          questAlert(_INTL("\\se[{1}]Quest updated:","Mining found all"),quest)
        end
      end
      return true if found
    end
    unless found
      questNew = Quest.new(quest,color,story)
      questNew.stage = stageNum
      @active_quests.push(questNew)
    end
    return true
  end

  def advanceQuest(quest,color=0,story=false,skipAlert: true)
    unless quest.is_a?(Symbol)
      raise _INTL("The 'quest' argument should be a symbol, e.g. ':Quest1'.")
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        echoln("Asked to advance quest #{quest}, but that quest has already been completed.")
        return false
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        echoln("Asked to advance quest #{quest}, but that quest has already been failed.")
        return false
      end
    end 
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        if @active_quests[i].stage >= $quest_data.getMaxStagesForQuest(quest)
          return completeQuest(quest,color,story,skipAlert: skipAlert)
        end
        @active_quests[i].stage += 1
        @active_quests[i].colorID = color if color
        @active_quests[i].new = true # Setting this back to true makes the "!" icon appear when the quest updates
        found = true
        unless skipAlert
          questAlert(_INTL("\\se[{1}]Quest updated:","Mining found all").quest)
        end
      end
      return true if found
    end
    unless found
      questNew = Quest.new(quest,color,story)
      questNew.stage = 1
      @active_quests.push(questNew)
    end
    return true
  end

  def questAlert(text,quest)
    pbMessage(_INTL("\\wm\<ac>\\c[2]{1}</c>\n{2}</ac>\\wtnp[{3}]",text,$quest_data.getName(quest),questAlertDuration))
  end

  def questAlertDuration
    return 60 - $Options.textspeed * 4
  end
end

#===============================================================================
# Initiate quest data
#===============================================================================
class PokemonGlobalMetadata  
  def quests
    @quests = Player_Quests.new unless @quests
    return @quests
  end
  
  alias quest_init initialize
  def initialize
    quest_init
    @quests = Player_Quests.new
  end
end

#===============================================================================
# Helper and utility functions for managing quests
#===============================================================================

# Helper function for activating quests
def activateQuest(quest,color=0,story=false,skipAlert: false)
  return unless $PokemonGlobal
  return $PokemonGlobal.quests.activateQuest(quest,color,story,skipAlert: skipAlert)
end

# Helper function for marking quests as completed
def completeQuest(quest,color=0,story=false,skipAlert: false)
  return unless $PokemonGlobal
  return $PokemonGlobal.quests.completeQuest(quest,color,story,skipAlert: skipAlert)
end

# Helper function for marking quests as failed
def failQuest(quest,color=0,story=false,skipAlert: false)
  return unless $PokemonGlobal
  return $PokemonGlobal.quests.failQuest(quest,color,story,skipAlert: skipAlert)
end

# Helper function for advancing quests to given stage
def advanceQuestToStage(quest,stageNum,color=0,story=false,skipAlert: true)
  return unless $PokemonGlobal
  return $PokemonGlobal.quests.advanceQuestToStage(quest,stageNum,color,story,skipAlert: skipAlert)
end

# Helper function for advancing quests to the next stage
def advanceQuest(quest,color=0,story=false,skipAlert: true)
  return unless $PokemonGlobal
  return $PokemonGlobal.quests.advanceQuest(quest,color,story,skipAlert: skipAlert)
end

# Get symbolic names of active quests
# Unused
def getActiveQuests
  active = []
  $PokemonGlobal.quests.active_quests.each do |s|
    active.push(s.id)
  end
  return active
end

# Get symbolic names of completed quests
# Unused
def getCompletedQuests
  completed = []
  $PokemonGlobal.quests.completed_quests.each do |s|
    completed.push(s.id)
  end
  return completed
end

# Get symbolic names of failed quests
# Unused
def getFailedQuests
  failed = []
  $PokemonGlobal.quests.failed_quests.each do |s|
    failed.push(s.id)
  end
  return failed
end

def completedQuest?(matchQuest)
  return getCompletedQuests.any? {|questID| questID == matchQuest}
end

#===============================================================================
# Class that contains utility methods to return quest properties
#===============================================================================
class QuestData

  # Get ID number for quest
  def getID(quest)
    return "#{QuestModule.const_get(quest)[:ID]}"
  end

  # Get quest name
  def getName(quest)
    return _INTL(QuestModule.const_get(quest)[:Name])
  end

  # Get name of quest giver
  def getQuestGiver(quest)
    return _INTL(QuestModule.const_get(quest)[:QuestGiver])
  end

  # Get array of quest stages
  def getQuestStages(quest)
    arr = []
    for key in QuestModule.const_get(quest).keys
      arr.push(key) if key.to_s.include?("Stage")
    end
    return arr
  end

  # Get quest reward
  def getQuestReward(quest)
    return _INTL(QuestModule.const_get(quest)[:RewardString])
  end

  # Get overall quest description
  def getQuestDescription(quest,stage=nil)
    questData = QuestModule.const_get(quest)
    if stage
      loc = ("QuestDescription" + "#{stage}").to_sym
      if questData[loc]
        return _INTL(questData[loc])
      end
    end
    return _INTL(questData[:QuestDescription])
  end

  # Get current task location
  def getStageLocation(quest,stage)
    loc = ("Location" + "#{stage}").to_sym
    return _INTL(QuestModule.const_get(quest)[loc])
  end  

  # Get summary of current task
  def getStageDescription(quest,stage)
    stg = ("Stage" + "#{stage}").to_sym
    return _INTL(QuestModule.const_get(quest)[stg])
  end 

  # Get maximum number of tasks for quest
  def getMaxStagesForQuest(quest)
    quests = getQuestStages(quest)
    return quests.length
  end
  
end

# Global variable to make it easier to refer to methods in above class
$quest_data = QuestData.new

#===============================================================================
# Class that contains utility methods to return quest properties
#===============================================================================

# Utility function to check whether the player current has any quests
def hasAnyQuests?
  if $PokemonGlobal.quests.active_quests.length >0 || 
    $PokemonGlobal.quests.completed_quests.length >0 ||
    $PokemonGlobal.quests.failed_quests.length >0
    return true
  end
  return false      
end