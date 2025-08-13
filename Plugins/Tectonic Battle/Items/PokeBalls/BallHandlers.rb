module BallHandlers
    IsUnconditional = ItemHandlerHash.new
    ModifyCatchRate = ItemHandlerHash.new
    OnCatch         = ItemHandlerHash.new
    OnFailCatch     = ItemHandlerHash.new

    OnPokemonCaught      = Event.new

    def self.isUnconditional?(ball, battle, battler)
        ret = IsUnconditional.trigger(ball, battle, battler)
        return !ret.nil? ? ret : false
    end

    def self.modifyCatchRate(ball, catchRate, battle, battler)
        ret = ModifyCatchRate.trigger(ball, catchRate, battle, battler)
        pseudoBonus = [1.0 + (0.1 * battle.ballsUsed), 4].min
        return !ret.nil? ? (ret * pseudoBonus) : (catchRate * pseudoBonus)
    end

    def self.onCatch(ball, battle, pkmn)
        battle.ballsUsed = 0
        OnCatch.trigger(ball, battle, pkmn)
        OnPokemonCaught.trigger(ball, battle, pkmn)
        incrementSuccessfulCaptureCount(ball)
        checkForCaptureAchievements(ball, battle, pkmn)
    end

    def self.onFailCatch(ball, battle, battler)
        battle.ballsUsed += 1
        OnFailCatch.trigger(ball, battle, battler)
    end
end
