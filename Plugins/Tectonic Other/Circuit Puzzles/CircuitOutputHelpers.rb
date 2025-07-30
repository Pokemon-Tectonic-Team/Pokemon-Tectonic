OASIS_SWITCHBOX_VAR = 43
OASIS_SYSTEM_MAP_ID = 406
INTEGRATION_CHAMBER_MAP_ID = 382

def electricFenceDectivates
    pbSEPlay("Anim/PRSFX- Paralysis", 100, 70)
end

def electricFenceActivates
    pbSEPlay("Anim/PRSFX- Paralysis", 100, 120)
end

def switchCurrent(eventIDs,toggleSelf=true)
    eventIDs = [eventIDs] unless eventIDs.is_a?(Array)  
    mainEvent = eventIDs[0]

    if toggleSelf
        pbSEPlay("GUI storage put down", 140, 70)
        toggleSwitch(get_self.id)
        pbWait(40)
    end

    slideCameraToEvent(mainEvent,5)

    255.downto(0) do |i|
        next if i % 3 != 0
        eventIDs.each do |eventID|
            get_character(eventID).opacity = i
        end
        pbWait(1)
    end

    pbSEPlay("Anim/PRSFX- Waterfall1", 100, 120)
    toggleSwitches(eventIDs)

    0.upto(255) do |i|
        next if i % 3 != 0
        eventIDs.each do |eventID|
            get_character(eventID).opacity = i
        end
        pbWait(1)
    end
    pbWait(20)
    slideCameraToPlayer(5)
end

def resetCurrent(eventIDs)
    eventIDs = [eventIDs] unless eventIDs.is_a?(Array)  
    mainEvent = eventIDs[0]

    pbSEPlay("GUI storage put down", 140, 70)
    pbWait(40)

    slideCameraToEvent(mainEvent,5)

    255.downto(0) do |i|
        next if i % 3 != 0
        eventIDs.each do |eventID|
            get_character(eventID).opacity = i
        end
        pbWait(1)
    end

    pbSEPlay("Anim/PRSFX- Waterfall1", 100, 120)
    setSwitchesAll(eventIDs,'A',false)

    0.upto(255) do |i|
        next if i % 3 != 0
        eventIDs.each do |eventID|
            get_character(eventID).opacity = i
        end
        pbWait(1)
    end
    pbWait(20)
    slideCameraToPlayer(5)
end

##########################################################
### TUTORIAL
##########################################################

def circuitTutorialBasic(eventIDs)
    solved, state = circuitPuzzle(:TUTORIAL_BASIC)

    if solved
        setSwitchesAll(eventIDs,'A',true)
        electricFenceDectivates
    else
        setSwitchesAll(eventIDs,'A',false)
        electricFenceActivates
    end
end

def circuitTutorialResistors(eventIDs)
    solved, state = circuitPuzzle(:TUTORIAL_RESISTORS)

    if solved
        setSwitchesAll(eventIDs,'A',true)
        electricFenceDectivates
    else
        setSwitchesAll(eventIDs,'A',false)
        electricFenceActivates
    end
end

##########################################################
### WAVE LENGTH
##########################################################

def circuitWaveLengthExit(mapEventIDs,oasisEventIDs)
    solved, state = circuitPuzzle(:WL_EXIT)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(oasisEventIDs,'A',true,OASIS_SYSTEM_MAP_ID)
        incrementGlobalVar(OASIS_SWITCHBOX_VAR)
        electricFenceDectivates
    end
end

def circuitWaveLengthPrison(mapEventIDs,integrationEventIDs)
    solved, state = circuitPuzzle(:WL_PRISON)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(integrationEventIDs,'A',true,INTEGRATION_CHAMBER_MAP_ID)
        electricFenceDectivates
    end
end

##########################################################
### READ ONLY
##########################################################

def circuitReadOnlyExit(mapEventIDs,oasisEventIDs)
    solved, state = circuitPuzzle(:RO_EXIT)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(oasisEventIDs,'A',true,OASIS_SYSTEM_MAP_ID)
        incrementGlobalVar(OASIS_SWITCHBOX_VAR)
        electricFenceDectivates
    end
end

def circuitReadOnlyPrison(mapEventIDs,integrationEventIDs)
    solved, state = circuitPuzzle(:RO_PRISON)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(integrationEventIDs,'A',true,INTEGRATION_CHAMBER_MAP_ID)
        electricFenceDectivates
    end
end

##########################################################
### TERMINAL CONFUSION
##########################################################

def circuitTerminalConfusionExit(mapEventIDs,oasisEventIDs)
    solved, state = circuitPuzzle(:TC_EXIT)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(oasisEventIDs,'A',true,OASIS_SYSTEM_MAP_ID)
        electricFenceDectivates
    else
        setSwitchesAll(mapEventIDs,'A',state>12)
    end
end

def circuitTerminalConfusionPrison(mapEventIDs,integrationEventIDs)
    solved, state = circuitPuzzle(:TC_PRISON)

    if solved
        setSwitchesAll(mapEventIDs,'A',true)
        setSwitchesAll(integrationEventIDs,'A',true,INTEGRATION_CHAMBER_MAP_ID)
        electricFenceDectivates
    end
end

##########################################################
### INTEGRATION CHAMBER
##########################################################
def circuitIntegrationChamberWave(mapEventID)
    solved, state = circuitPuzzle(:IC_WAVE)

    case state
    when 0
        pbSEPlay("GUI storage put down", 140, 70)
        pbSetAllSwitches(mapEventID, false)
    when 1
        pbSEPlay("GUI storage put down", 140, 70)
        pbSetOnlySwitch(mapEventID,'A')
    when 2
        pbSEPlay("GUI storage put down", 140, 70)
        pbSetOnlySwitch(mapEventID,'B')
    when 3
        pbSEPlay("GUI storage put down", 140, 70)
        pbSetOnlySwitch(mapEventID,'C')
    end
end

def circuitIntegrationChamberCage(puzzleEventID,fenceEventID)
    solved, state = circuitPuzzle(:IC_AVATAR_CAGE)

    # Enable or disable puzzle
    pbSetSelfSwitch(puzzleEventID,'B',solved || state > 5)
    pbSEPlay("GUI storage put down", 140, 70)

    # Enable or disable barrier
    if solved || [4,5,6].include?(state)
        pbSetSelfSwitch(fenceEventID,'A',true)
        electricFenceDectivates
    else
        pbSetSelfSwitch(fenceEventID,'A',false)
        electricFenceActivates
    end
end

def circuitIntegrationChamberMaze(barrierEventIDs)
    solved, state = circuitPuzzle(:IC_ELECTRIC_MAZE)

    pbSetSelfSwitch(barrierEventIDs[0],'A',[0,1,2,3,4,7].include?(state))
    pbSetSelfSwitch(barrierEventIDs[1],'A',[0,1,2,3,4,5,6].include?(state))
    pbSetSelfSwitch(barrierEventIDs[2],'A',![7,8].include?(state))
    pbSetSelfSwitch(barrierEventIDs[3],'A',![7,8].include?(state))

    electricFenceActivates
end

def circuitIntegrationChamberExit(puzzleEventID,fenceEventID,signal1EventID,signal2EventID)
    solved, state = circuitPuzzle(:IC_EXIT)

    if solved
        pbSetSelfSwitch(puzzleEventID,'B') # Enable puzzle
        pbSetSelfSwitch(fenceEventID,'A') # Disable fence
        pbSetSelfSwitch(signal1EventID,'A') # Enable signal 1
        pbSetSelfSwitch(signal2EventID,'A',true,406) # Disable signal 2
        electricFenceDectivates 
    else
        case state
        when 0
            pbSetSelfSwitch(puzzleEventID,'B') # Enable puzzle
        when 2
            pbSetSelfSwitch(fenceEventID,'A') # Disable fence
            pbSetSelfSwitch(signal1EventID,'A') # Enable signal 1
            pbSetSelfSwitch(signal2EventID,'A',true,406) # Disable signal 2
            electricFenceDectivates
        end
    end
end