SaveData.register_conversion(:jovan_quest_3_3_0) do
    game_version '3.3.0'
    display_title 'Converting Jovan quest for 3.3.0'
    to_all do |save_data|
        globalSwitches = save_data[:switches]
        globalVariables = save_data[:variables]
        selfSwitches = save_data[:self_switches]
        itemBag = save_data[:bag]
    
        globalVariables[44] += 1 if selfSwitches[[138,18,'A']] # Jovan in Scenic Trail
        if selfSwitches[[136,2,'C']]
            # Player has seen the Tamarind dock event and got the Poke X-ray
            globalVariables[44] += 1
        elsif selfSwitches[[26,4,'A']]  
            # Player has not seen the Tamarind dock event, but has defeated the Avatar of Vigoroth (which is after getting the X-ray in the new update)
            globalVariables[44] += 1
            itemBag.pbStoreItem(:POKEXRAY, 1, false)
        end
        globalVariables[44] += 1 if selfSwitches[[60,45,'A']] # Jovan in Shipping Lane
        # Optional LuxTech event is already handled by checking Gym flag
        globalVariables[44] += 1 if selfSwitches[[155,73,'A']] # Jovan in Prizca West

        # Prepare phone call if appropriate
        badgeCount = 0
        (4..11).each do |switch|
            badgeCount += 1 if globalSwitches[switch]
        end
        save_data[:global_metadata].shouldProcJovanCall = true if globalVariables[44] == 4 && badgeCount == 7
    end
end