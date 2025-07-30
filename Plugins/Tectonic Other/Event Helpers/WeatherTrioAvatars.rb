# Gives the blue orb, and does a little scene where the cave brightens and the rain
def kyogreDefeated(eventID)
	defeatBoss(:BLUEORB)
	weatherBossDefeated(eventID,100)
end

# Gives the red orb, and does a little scene where the cave darkens and the bright sunshine dissapears
def groudonDefeated(eventID)
	defeatBoss(:REDORB)
	weatherBossDefeated(eventID,50)
end

# Does a little scene where the cave darkens and the extreme wind dissapears
def rayquazaDefeated(eventID)
	defeatBoss(%i[RELICCROWN PRIMALBEAD])
	weatherBossDefeated(eventID,50)
end

def weatherBossDefeated(eventID,newFogOpacity)
	pbSetSelfSwitch(eventID,'A',true)
	pbWait(Graphics.frame_rate)
	lockPlayerInput
	baseWaitTime = Graphics.frame_rate / 4
	weatherCallback = proc {
		pbSetSelfSwitch(eventID,'B',true)
		unlockPlayerInput
	}
	$game_screen.weather(:None,0,baseWaitTime,true,true,weatherCallback)
	weatherWaitTime = baseWaitTime * 2 * $game_screen.weather_strength
	$game_map.start_fog_opacity_change(newFogOpacity, weatherWaitTime)
end