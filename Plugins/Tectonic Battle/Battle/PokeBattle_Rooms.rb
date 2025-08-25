
class PokeBattle_Battle
    def pbStartRoom(roomEffect, user, ability = nil, aiCheck = false, duration: nil)
        duration = duration || (ability ? 4 : 8)
        duration = user.getRoomDuration(duration, aiCheck: aiCheck)
        effectName = GameData::BattleEffect.get(roomEffect).name
        
        if @field.effectActive?(roomEffect)
            if @field.countEffect(roomEffect) >= duration
                pbDisplay(_INTL("The {1} stayed the same.", effectName)) unless aiCheck
                return 0
            else
                if aiCheck
                    return (duration - @field.countEffect(roomEffect)) * 20
                else
                    pbDisplay(_INTL("The {1} was refreshed!", effectName))
                    @field.effects[roomEffect] = duration
                end
            end
        else
            if aiCheck
                return duration * 20
            else
                @field.applyEffect(roomEffect, duration)
            end
        end
        
        if aiCheck
            return 0
        else
            moreTurns = duration
            moreTurns -= 1 unless @turnCount == 0
            pbDisplay(_INTL("It'll last for {1} more turns.", moreTurns))
        end
    end
end