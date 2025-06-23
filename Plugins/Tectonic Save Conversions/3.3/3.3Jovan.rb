SaveData.register_conversion(:jovan_quest_3_3_0) do
    game_version '3.3.0'
    display_title 'Converting Jovan quest for 3.3.0'
    to_all do |save_data|
        globalSwitches = save_data[:switches]
        globalVariables = save_data[:variables]
        selfSwitches = save_data[:self_switches]
        itemBag = save_data[:bag]
    
        globalVariables[44] += 1 if selfSwitches[[138,18,'A']] # Jovan in Scenic Trail
        globalVariables[44] += 1 if selfSwitches[[136,2,'C']] # Jovan on Bluepoint Beach/Tamarind on docks (TODO: handle player missing X-Ray)
        globalVariables[44] += 1 if selfSwitches[[60,45,'A']] # Jovan in Shipping Lane
        # Optional LuxTech event is already handled by checking Gym flag
        globalVariables[44] += 1 if selfSwitches[[155,73,'A']] # Jovan in Prizca West
    end
end