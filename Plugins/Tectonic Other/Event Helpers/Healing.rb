# Modes are :NURSE, :RANGER, and :MACHINE
def pokeCenterHealing(pokeBallsEventID = nil, mode: :NURSE, respawn: false, pushDirection: Down, extraCharges: 0, setCenter: true)
    pokeBallsEvent = get_event(pokeBallsEventID) || nil

    stowFollowerIfActive
    pbSetPokemonCenter if setCenter && !respawn
    if mode == :NURSE
        if respawn
            pbMessage(_INTL("First, you should restore your Pokémon to full health."))
        else
            pbMessage(_INTL("I'll take your Pokémon for a few seconds."))
        end
    elsif mode == :RANGER
        if respawn
            pbMessage(_INTL("Let's get your Pokémon patched up."))
        else
            pbMessage(_INTL("Here, let me heal your Pokémon."))
        end
    end
    $Trainer.heal_party
    if pokeBallsEvent
        if mode != :MACHINE
            pbMoveRoute(get_self,
            [
                PBMoveRoute::TurnLeft,
                PBMoveRoute::Wait,2,
            ])
            command_210 # Wait for move's completion
        end
        setGlobalVariable(6,0)
        count = $Trainer.pokemon_count
        for i in 1..count
            pbSet(6,i)
            pbSEPlay("Battle ball shake")
            pbWait(10)
        end
        pbMoveRoute(pokeBallsEvent,
            [
                PBMoveRoute::StepAnimeOn,
            ])
    end
    pbMEPlay("Pkmn healing")
    pbWait(58)
    if pokeBallsEvent
        setGlobalVariable(6,0)
        pbMoveRoute(pokeBallsEvent,
            [
                PBMoveRoute::StepAnimeOff,
            ])
        unless mode == :MACHINE
            pbMoveRoute(get_self, 
            [
                PBMoveRoute::Wait,15,
                PBMoveRoute::TurnDown,
            ])
            command_210 # Wait for move's completion
        end
    end
    if respawn
        if mode == :NURSE
            pbMessage(_INTL("We hope you excel!"))
        elsif mode == :RANGER
            pbMessage(_INTL("Best of luck to you!"))
        end
    end

    pbRespawnTrainers

    # Refill the aid kit
    if extraCharges > 0
        pbMessage(_INTL("You stuff your Aid Kit full from your large stack of supplies!"))
    end
    refillAidKit(extraCharges)

    # Push the player away from the healing event
    # To prevent accidental do-overs when spamming
    if pushDirection
        moveRouteDirection = nil
        case pushDirection
        when Up
            moveRouteDirection = PBMoveRoute::Up
        when Down
            moveRouteDirection = PBMoveRoute::Down
        when Left
            moveRouteDirection = PBMoveRoute::Left
        when Right
            moveRouteDirection = PBMoveRoute::Right
        end
        pbMoveRoute(get_player,
        [
            PBMoveRoute::ChangeSpeed,5,
            moveRouteDirection,
        ])
    end

    # Starting Over to false
    setGlobalSwitch(Settings::STARTING_OVER_SWITCH,false) if respawn

    unstowFollowerIfAllowed
    autoSave
end