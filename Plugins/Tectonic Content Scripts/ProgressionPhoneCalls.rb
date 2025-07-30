ZAIN_2_BADGES_PHONECALL_GLOBAL = 230
ZAIN_3_BADGES_PHONECALL_GLOBAL = 231
GROUZ_AVATAR_PHONECALL_GLOBAL = 226
CATACOMBS_PHONECALL_GLOBAL = 227
WHITEBLOOM_PHONECALL_GLOBAL = 228
BATTLE_MONUMENT_PHONECALL_GLOBAL = 229
DR_HEKATA_PHONECALL_GLOBAL = 232
ESTATE_PHONECALL_GLOBAL = 233
JOVAN_PHONECALL_GLOBAL = 234
JOVAN_CONTACTED_GLOBAL = 235

Events.onBadgeEarned += proc { |_sender,_e|
    totalBadges = _e[1]
	if totalBadges == 2
		$PokemonGlobal.shouldProc2BadgesZainCall = true
	elsif totalBadges == 3
		$PokemonGlobal.shouldProc3BadgesZainCall = true
	elsif totalBadges == 4
        $PokemonGlobal.shouldProcGrouzAvatarCall = true
    elsif totalBadges == 6
        $PokemonGlobal.shouldProcCatacombsCall = true
    elsif totalBadges == 7 && !getGlobalSwitch(JOVAN_CONTACTED_GLOBAL)
        $PokemonGlobal.shouldProcJovanCall = true
	elsif totalBadges == 8
        $PokemonGlobal.shouldProcWhitebloomCall = true
    end
}

def gameWon?
	return $game_switches[68]
end

Events.onMapChange += proc { |_sender, _e|
	if playerIsOutdoors? || $game_map.map_id == 214 # Team Chasm HQ
		if $PokemonGlobal.shouldProcGrouzAvatarCall
			$game_switches[GROUZ_AVATAR_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcGrouzAvatarCall = false
		elsif $PokemonGlobal.shouldProcCatacombsCall
			$game_switches[CATACOMBS_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcCatacombsCall = false
		elsif $PokemonGlobal.shouldProcWhitebloomCall
			$game_switches[WHITEBLOOM_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcWhitebloomCall = false
		elsif $PokemonGlobal.shouldProc2BadgesZainCall
			$game_switches[ZAIN_2_BADGES_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProc2BadgesZainCall = false
		elsif $PokemonGlobal.shouldProc3BadgesZainCall
			$game_switches[ZAIN_3_BADGES_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProc3BadgesZainCall = false
        elsif $PokemonGlobal.shouldProcJovanCall
            $game_switches[JOVAN_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcJovanCall = false
        end
	end
}

Events.onMapChange += proc { |_sender, _e|
    checkForVanyaBattleMonumentPhonecallTrigger
}

Events.onMapChange += proc { |_sender, _e|
    checkForDrHekataPhonecallTrigger
}

Events.onStepTaken += proc { |_sender,_e|
    if playerIsOutdoors? && $PokemonGlobal.shouldProcEstateCall
        $game_switches[ESTATE_PHONECALL_GLOBAL] = true
        $PokemonGlobal.shouldProcEstateCall = false
    end
}

def checkForVanyaBattleMonumentPhonecallTrigger
    return unless gameWon?
    return if boatWaypointUnlocked?(:MONUMENT_ISLAND)
    return unless $game_map.map_id == 188 # Prizca Castle
    setGlobalSwitch(BATTLE_MONUMENT_PHONECALL_GLOBAL) # Trigger the phone call from Vanya
end

WHITE_CHAMBER_MAP_IDS = [
    42, # Zeraora's Chamber
    84, # Meloetta's Chamber
    24, # Shaymin's Chamber
    106, # Yveltal's Chamber
    176, # Heroes' Chamber
    199, # Xerneas' Chamber
    291, # Deoxys's Chamber
    303, # Zygarde's Chamber
    330, # King's Chamber
    315, # Uplifted Abysm
    5, # Secret Location
]

def checkForDrHekataPhonecallTrigger
    return unless WHITE_CHAMBER_MAP_IDS.include?($game_map.map_id)
    return unless gameWon?
    return unless getGlobalVariable(37) == 0 && # Legend cloning quest has not started
	setGlobalSwitch(DR_HEKATA_PHONECALL_GLOBAL) # Trigger the phone call from Dr. Hekata
end