#===============================================================================
# Cures user of any status condition. (Refresh)
#===============================================================================
class PokeBattle_Move_CureUserStatus < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.pbHasAnyStatus?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no status condition!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.pbCureStatus
    end

    def getEffectScore(_user, _target)
        return 75
    end
end

#===============================================================================
# Cures all party Pokémon of permanent status problems. (Aromatherapy, Heal Bell)
#===============================================================================
class PokeBattle_Move_CureUserPartyStatus < PokeBattle_Move
    def worksWithNoTargets?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        @battle.pbParty(user.index).each do |pkmn|
            return false if validPokemon(pkmn)
        end
        @battle.pbDisplay(_INTL("But it failed, since there are no status conditions in the party!")) if show_message
        return true
    end

    def validPokemon(pkmn)
        return pkmn&.able? && pkmn.status != :NONE
    end

    def pbEffectGeneral(user)
        # Cure all Pokémon in the user's and partner trainer's party.
        # NOTE: This intentionally affects the partner trainer's inactive Pokémon
        #       too.
        @battle.pbParty(user.index).each_with_index do |pkmn, i|
            next unless pkmn
            battler = @battle.pbFindBattler(i, user)
            if battler
                healStatus(battler)
            else
                healStatus(pkmn)
            end
        end
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        super
        if @id == :AROMATHERAPY
            @battle.pbDisplay(_INTL("A soothing aroma wafted through the area!"))
        elsif @id == :HEALBELL
            @battle.pbDisplay(_INTL("A bell chimed!"))
        end
    end

    def getEffectScore(user, target)
        return 0 if target && target.index != user.index
        score = 0
        score -= statusSpikesWeightOnSide(user.pbOwnSide) if user.alliesInReserve?
        statusesInParty = 0 
        @battle.pbParty(user.index).each do |pkmn|
            statusesInParty += 1 if validPokemon(pkmn)
        end
        if statusesInParty > 0
            statusScore = 70 + statusesInParty * 40
            statusScore = 200 if statusScore > 200
            score += statusScore
        end
        return score
    end
end

#===============================================================================
# Heals the party of status conditions and gains an Aqua Ring. (Whale Song)
#===============================================================================
class PokeBattle_Move_CureUserPartyStatusStartHealUserEachTurn < PokeBattle_Move_CureUserPartyStatus
    def worksWithNoTargets?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if super(user, _targets, false) && user.effectActive?(:AquaRing)
            @battle.pbDisplay(_INTL("But it failed, since {1} already has a veil of water and none of its party members have a status condition!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        super
        user.applyEffect(:AquaRing)
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        super
        @battle.pbDisplay(_INTL("Majestic whale sounds reverberate!"))
    end

    def getEffectScore(user, _target)
        score = super
        score += getAquaRingEffectScore(user)
        return score
    end
end

#===============================================================================
# Damages, while also healing the team of statuses. (Purifying Water)
#===============================================================================
class PokeBattle_Move_CureUserPartyStatusDamagingMove < PokeBattle_Move
    def pbEffectAfterAllHits(user, _target)
        @battle.eachSameSideBattler(user) do |b|
            healStatus(b)
        end
        # Cure all Pokémon in the user's and partner trainer's party.
        # NOTE: This intentionally affects the partner trainer's inactive Pokémon
        #       too.
        @battle.pbParty(user.index).each_with_index do |pkmn, i|
            next if !pkmn || !pkmn.able?
            next if @battle.pbFindBattler(i, user) # Skip Pokémon in battle
            healStatus(pkmn)
        end
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        super
        @battle.pbDisplay(_INTL("The area was purified!"))
    end

    def getEffectScore(user, _target)
        score = 0
        statuses = 0
        @battle.pbParty(user.index).each do |pkmn|
            score += 40 if pkmn && pkmn.status != :NONE
        end
        return score
    end
end

#===============================================================================
# Safeguards the user's side from being inflicted with status problems.
# (Safeguard)
#===============================================================================
class PokeBattle_Move_StartUserSideImmunityToInflictedStatus < PokeBattle_Move
    def initialize(battle, move)
        super
        @safeguardDuration = 10
    end

    def pbEffectGeneral(user)
        user.pbOwnSide.applyEffect(:Safeguard, applyEffectDurationModifiers(@safeguardDuration, user))
    end

    def getEffectScore(user, _target)
        return getSafeguardEffectScore(user, applyEffectDurationModifiers(@safeguardDuration, user))
    end
end

#===============================================================================
# User passes its first status problem to the target. (Psycho Shift)
#===============================================================================
class PokeBattle_Move_GiveUserStatusToTarget < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.pbHasAnyStatus?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} doesn't have any status conditions!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def statusBeingMoved(user)
        return user.getStatuses[0]
    end

    def pbFailsAgainstTarget?(user, target, show_message)
        return !target.pbCanInflictStatus?(statusBeingMoved(user), user, show_message, self)
    end

    def pbEffectAgainstTarget(user, target)
        target.pbInflictStatus(statusBeingMoved(user), 0, nil, user)
        user.pbCureStatus(true, statusBeingMoved(user))
    end

    def getEffectScore(user, target)
        status = statusBeingMoved(user)
        score = 0
        score += getStatusSettingEffectScore(status, user, target, ignoreCheck: true)
        score += getStatusSettingEffectScore(status, target, user, ignoreCheck: true)
        return score
    end
end

#===============================================================================
# Transfers the user's status to the target (Vicious Cleaning)
#===============================================================================
class PokeBattle_Move_GiveUserStatusToTargetDamagingMove < PokeBattle_Move
    def pbEffectAgainstTarget(user, target)
        user.getStatuses.each do |status|
            next if status == :NONE
            if target.pbCanInflictStatus?(status, user, false, self)
                case status
                when :SLEEP
                    target.applySleep
                when :POISON
                    target.applyPoison(user, nil, user.statusCount != 0)
                when :BURN
                    target.applyBurn(user)
                when :NUMB
                    target.applyNumb(user)
                when :FROSTBITE
                    target.applyFrostbite(user)
                when :DIZZY
                    target.applyDizzy(user)
                when :LEECHED
                    target.applyLeeched(user)
                end
            else
                statusData = GameData::Status.get(status)
                @battle.pbDisplay(_INTL("{1} tries to transfer its {2} to {3}, but...", user.pbThis, statusData.name,
target.pbThis(true)))
                target.pbCanInflictStatus?(status, user, true, self)
            end
            user.pbCureStatus(status)
        end
    end

    def shouldHighlight?(user, _target)
        return user.pbHasAnyStatus?
    end
end

#===============================================================================
# Cures the target's burn. (Sparkling Aria)
#===============================================================================
class PokeBattle_Move_CureTargetBurn < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        return if target.status != :BURN
        target.pbCureStatus(true, :BURN)
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        if !target.substituted? && target.burned?
            if target.opposes?(user)
                score -= 30
            else
                score += 30
            end
        end
        return score
    end
end

#===============================================================================
# Cures the target's frostbite. (Rousing Hula)
#===============================================================================
class PokeBattle_Move_CureTargetFrostbite < PokeBattle_Move
    def pbAdditionalEffect(_user, target)
        return if target.fainted? || target.damageState.substitute
        return if target.status != :FROSTBITE
        target.pbCureStatus(true, :FROSTBITE)
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        if !target.substituted? && target.frostbitten?
            if target.opposes?(user)
                score -= 30
            else
                score += 30
            end
        end
        return score
    end
end

#===============================================================================
# Cures the target's permanent status problems. Heals user by 1/2 of its max HP.
# (Purify)
#===============================================================================
class PokeBattle_Move_CureTargetStatusHealUserHalfOfTotalHP < PokeBattle_HalfHealingMove
    def pbFailsAgainstTarget?(_user, target, show_message)
        unless target.pbHasAnyStatus?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no status conditions!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        target.pbCureStatus
        super
    end

    def getEffectScore(user, target)
        # The target for this is set as the user since its the user that heals
        score = super
        if target.opposes?(user)
            score += 40
        else
            score -= 40
        end
        return score
    end
end