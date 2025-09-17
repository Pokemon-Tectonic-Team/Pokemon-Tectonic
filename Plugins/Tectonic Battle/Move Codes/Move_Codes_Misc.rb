#===============================================================================
# No additional effect.
#===============================================================================
class PokeBattle_Move_Basic < PokeBattle_Move
end

#===============================================================================
# No additional effect.
#===============================================================================
class PokeBattle_Move_Invalid < PokeBattle_Move
    def initialize(battle, move)
        raise _INTL("An Invalid move is being instanced. This shouldn't happen!")
    end
end

#===============================================================================
# Does absolutely nothing. (Splash)
#===============================================================================
class PokeBattle_Move_DoesNothingUnusableInGravity < PokeBattle_Move
    def unusableInGravity?; return true; end

    def pbEffectGeneral(_user)
        @battle.pbDisplay(_INTL("But nothing happened!"))
    end
end

#===============================================================================
# Struggle, if defined as a move in moves.txt. Typically it won't be.
#===============================================================================
class PokeBattle_Move_Struggle < PokeBattle_Struggle
end

#===============================================================================
# All current battlers will perish after 3 more rounds. (Perish Song)
#===============================================================================
class PokeBattle_Move_StartPerishCountsForAllBattlers < PokeBattle_Move
    def pbMoveFailed?(_user, targets, show_message)
        failed = true
        targets.each do |b|
            next if b.effectActive?(:PerishSong)
            failed = false
            break
        end
        if failed
            @battle.pbDisplay(_INTL("But it failed, since everyone has heard the song already!")) if show_message
            return true
        end
        return false
    end

    def pbFailsAgainstTarget?(_user, target, _show_message)
        return target.effectActive?(:PerishSong)
    end

    def pbEffectAgainstTarget(user, target)
        target.applyEffect(:PerishSong, 3)
    end

    def getEffectScore(user, _target)
        return 0 unless user.alliesInReserve?
        return 60
    end
end

#===============================================================================
# If target would be KO'd by this attack, it survives with 1HP instead.
# (False Swipe, Hold Back)
#===============================================================================
class PokeBattle_Move_CannotMakeTargetFaint < PokeBattle_Move
    def nonLethal?(_user, _target); return true; end
end

#===============================================================================
# Swaps form if the user is Meloetta. (Relic Song)
#===============================================================================
class PokeBattle_Move_ChangeUserMeloettaForm < PokeBattle_Move
    def pbEndOfMoveUsageEffect(user, _targets, numHits, _switchedBattlers)
        return if numHits == 0
        return if user.fainted? || user.transformed?
        return unless user.isSpecies?(:MELOETTA)
        return if user.hasActiveAbility?(:SHEERFORCE)
        newForm = (user.form + 1) % 2
        user.pbChangeForm(newForm, _INTL("{1} transformed!", user.pbThis))
    end
end

#===============================================================================
# Interrupts a foe switching out or using U-turn/Volt Switch/Parting Shot. Power
# is doubled in that case. (Pursuit)
# (Handled in Battle's pbAttackPhase): Makes this attack happen before switching.
#===============================================================================
class PokeBattle_Move_PursueSwitchingFoe < PokeBattle_Move
    def pbAccuracyCheck(user, target)
        return true if @battle.switching
        return super
    end

    def pbBaseDamage(baseDmg, _user, _target)
        baseDmg *= 2 if @battle.switching
        return baseDmg
    end

    def pbBaseDamageAI(baseDmg, user, target)
        baseDmg *= 2 if @battle.aiPredictsSwitch?(user,target.index)
        return baseDmg
    end
end

#===============================================================================
# Transforms the user into one of its Mega Forms. (Gene Boost)
#===============================================================================
class PokeBattle_Move_ChangeUserMewtwoChoiceOfForm < PokeBattle_Move
    def resolutionChoice(user)
        if @battle.autoTesting
            @chosenForm = rand(2) + 1
        elsif !user.pbOwnedByPlayer? # Trainer AI
            @chosenForm = 2 # Always chooses mega mind form
        else
            form1Name = GameData::Species.get_species_form(:MEWTWO,1).form_name
            form2Name = GameData::Species.get_species_form(:MEWTWO,2).form_name
            formNames = [form1Name,form2Name]
            chosenIndex = @battle.scene.pbShowCommands(_INTL("Which form should {1} take?", user.pbThis(true)),formNames,0)
            @chosenForm = chosenIndex + 1
        end
    end

    def pbCanChooseMove?(user, commandPhase, show_message)
        unless user.form == 0
            if show_message
                msg = _INTL("{1} has already transformed!", user.pbThis)
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            return false
        end
        return true
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.countsAs?(:MEWTWO)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis)) if show_message
            return true
        end
        unless user.form == 0
            @battle.pbDisplay(_INTL("But {1} has already transformed!", user.pbThis)) if show_message
            return true
        end
        return false
    end
    
    def pbEffectGeneral(user)
        user.pbChangeForm(@chosenForm, _INTL("{1} augmented its genes and transformed!", user.pbThis))
    end

    def resetMoveUsageState
        @chosenForm = nil
    end

    def getEffectScore(_user, _target)
        return 100
    end
end

#===============================================================================
# Target transforms into their pre-evolution. (Young Again)
#===============================================================================
class PokeBattle_Move_TransformTargetPreEvolution < PokeBattle_Move
    def pbFailsAgainstTarget?(_user, target, show_message)
        if target.illusion?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is disguised by an Illusion!", target.pbThis(true)))
            end
            return true
        end
        if target.boss?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is an avatar!", target.pbThis(true)))
            end
            return true
        end
        unless target.species_data
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} doesn't have a defined species somehow!", target.pbThis(true)))
            end
            return true
        end
        unless GameData::Species.get(target.technicalSpecies).has_previous_species?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} has no previous species to transform into!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectAgainstTarget(user, target)
        target.transformSpecies(GameData::Species.get(target.technicalSpecies).get_previous_species)
    end

    def getEffectScore(user, target)
        score = 95
        score += 45 if target.aboveHalfHealth?
        if user.battle.pbCanSwitch?(target.index)
            score -= 30
            score += getForceOutEffectScore(user, target)
        end
        return score
    end
end

#===============================================================================
# Target's last move used loses 4 PP. (Spiteful Chant, Eerie Spell)
#===============================================================================
class PokeBattle_Move_LowerPPOfTargetLastMoveBy4 < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbEffectAgainstTarget(_user, target)
        target.eachMove do |m|
            next if m.id != target.lastRegularMoveUsed
            reduction = [4, m.pp].min
            target.pbSetPP(m, m.pp - reduction)
            @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",
               target.pbThis(true), m.name, reduction))
            break
        end
    end

    def getTargetAffectingEffectScore(_user, target)
        target.eachMove do |m|
            next if m.id != target.lastRegularMoveUsed
            return 30
        end
        return 0
    end
end

#===============================================================================
# Uses the highest base-power attacking move known by any non-user Pokémon in the user's party. (Optimized Action)
#===============================================================================
class PokeBattle_Move_UseHighestBasePowerMoveFromUserParty < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def getOptimizedMove(user)
        optimizedMove = nil
        optimizedBP = -1
        @battle.pbParty(user.index).each_with_index do |pkmn, i|
            next if !pkmn || i == user.pokemonIndex
            next unless pkmn.able?
            pkmn.moves.each do |move|
                next if move.category == 2
                next unless move.base_damage > optimizedBP
                next unless @battle.canInvokeMove?(move)
                optimizedMove = move.id
                optimizedBP = move.base_damage
            end
        end
        return optimizedMove
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless getOptimizedMove(user)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since there are no moves {1} can use!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        user.pbUseMoveSimple(getOptimizedMove(user))
    end
end

#===============================================================================
# The target uses its most recent move again. (Instruct)
#===============================================================================
class PokeBattle_Move_TargetUsesItsLastUsedMoveAgain < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbFailsAgainstTarget?(_user, target, show_message)
        unless target.lastRegularMoveUsed
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} hasn't used a move yet!", target.pbThis(true)))
            end
            return true
        end
        unless target.pbHasMove?(target.lastRegularMoveUsed)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} no longer knows its most recent move!", target.pbThis(true)))
            end
            return true
        end
        if target.usingMultiTurnAttack?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} is locked into an attack!", target.pbThis(true)))
            end
            return true
        end
        targetMove = @battle.choices[target.index][2]
        if targetMove && (targetMove.function == "FailsIfUserDamagedThisTurn" ||   # Focus Punch
                          targetMove.function == "UsedAfterUserTakesPhysicalDamage" ||   # Shell Trap
                          targetMove.function == "UsedAfterUserTakesSpecialDamage" ||   # Masquerblade
                          targetMove.function == "BurnAttackerBeforeUserActs" ||     # Beak Blast
                          targetMove.function == "FrostbiteAttackerBeforeUserActs" ||    # Cold Snap
                          targetMove.function == "SetupSpikesBeforeUserActs")   # Shard Surge
            @battle.pbDisplay(_INTL("But it failed, since {1} is focusing!", target.pbThis(true))) if show_message
            return true
        end
        if GameData::Move.get(target.lastRegularMoveUsed).uninvocable?
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1}'s last used move cant be instructed!", target.pbThis(true)))
            end
            return true
        end
        if @battle.getBattleMoveInstanceFromID(target.lastRegularMoveUsed).is_a?(PokeBattle_TwoTurnMove)
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1}'s last used move is a two-turn move!", target.pbThis(true)))
            end
            return true
        end
        idxMove = -1
        target.eachMoveWithIndex do |m, i|
            idxMove = i if m.id == target.lastRegularMoveUsed
        end
        if target.getMoves[idxMove].pp == 0 && target.getMoves[idxMove].total_pp > 0
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1}'s last used move it out of PP!", target.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbFailsAgainstTargetAI?(user, target)
        return false if user.pbSpeed(true) < target.pbSpeed(true) # Assume target will actually use a move
        return pbFailsAgainstTarget?(user, target, false)
    end

    def pbEffectAgainstTarget(_user, target)
        target.applyEffect(:Instruct)
    end

    def getEffectScore(_user, _target)
        return 130 # Score assumes you put Instruct on the team for a reason, do not put Instruct on a team without really thinking about it
    end
end

#===============================================================================
# Two turn attack. Skips first turn, and transforms the user into their second form
# on the 2nd turn. Only ampharos can use it. (Transcendant Energy)
#===============================================================================
class PokeBattle_Move_TwoTurnChangeUserAmpharosForm < PokeBattle_TwoTurnMove
    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:AMPHAROS)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        elsif user.form != 0
            @battle.pbDisplay(_INTL("But {1} can't use it the way it is now!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbChargingTurnMessage(user, _targets)
        @battle.pbDisplay(_INTL("{1} is radiating energy!", user.pbThis))
    end

    def pbEffectGeneral(user)
        return unless @damagingTurn
        user.pbChangeForm(1, _INTL("{1} transcended its limits and transformed!", user.pbThis))
    end

    def getEffectScore(user, _target)
        score = super
        score += 100
        score += 50 if user.firstTurn?
        return score
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        if @chargingTurn && !@damagingTurn
            @battle.pbCommonAnimation("StatUp", user)
        else
            @battle.pbCommonAnimation("MegaEvolution", user)
            super
        end
    end
end

#===============================================================================
# Transforms the user into one of its forms. (Mutate)
#===============================================================================
class PokeBattle_Move_ChangeUserDeoxusChoiceOfForm < PokeBattle_Move
    def resolutionChoice(user)
        if @battle.autoTesting
            @chosenForm = rand(3) + 1
        elsif !user.pbOwnedByPlayer? # Trainer AI
            @chosenForm = 2 # Always chooses defense form
        else
            form1Name = GameData::Species.get_species_form(:DEOXYS,1).form_name
            form2Name = GameData::Species.get_species_form(:DEOXYS,2).form_name
            form3Name = GameData::Species.get_species_form(:DEOXYS,3).form_name
            formNames = [form1Name,form2Name,form3Name]
            chosenIndex = @battle.scene.pbShowCommands(_INTL("Which form should {1} take?", user.pbThis(true)),formNames,0)
            @chosenForm = chosenIndex + 1
        end
    end

    def pbCanChooseMove?(user, commandPhase, show_message)
        unless user.form == 0
            if show_message
                msg = _INTL("{1} has already mutated!", user.pbThis)
                commandPhase ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
            end
            return false
        end
        return true
    end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.countsAs?(:DEOXYS)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis)) if show_message
            return true
        end
        unless user.form == 0
            @battle.pbDisplay(_INTL("But {1} has already mutated!", user.pbThis)) if show_message
            return true
        end
        return false
    end
    
    def pbEffectGeneral(user)
        user.pbChangeForm(@chosenForm, _INTL("{1} reforms its genes with space energy!", user.pbThis))
    end

    def resetMoveUsageState
        @chosenForm = nil
    end

    def getEffectScore(_user, _target)
        return 100
    end
end

#===============================================================================
# Ignores all abilities that alter this move's success or damage.
# Transforms Necrozma into its Ultra form before attacking.
# (Light That Burns the Sky)
#===============================================================================
class PokeBattle_Move_IgnoreTargetAbilityChangeUserNecrozmaForm < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:NECROZMA)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end 
        return false
    end 

    def pbChangeUsageCounters(user, specialUsage)
        super
        @battle.moldBreaker = true unless specialUsage
    end

    def pbDisplayUseMessage(user, _targets = [])
        @battle.pbDisplayBrief(_INTL("{1} used Light That Burns the Sky!", user.pbThis))
    end

    def pbDisplayChargeMessage(user)
        if user.form == 1
            @battle.pbCommonAnimation("UltraBurst", user)
            user.pbChangeForm(3, _INTL("Bright lights bursts out of {1}!", user.pbThis))
        elsif user.form == 2
            @battle.pbCommonAnimation("UltraBurst", user)
            user.pbChangeForm(4, _INTL("Bright lights bursts out of {1}", user.pbThis))
        end 
    end

    def getEffectScore(user, _target)
        score = super
        score += 100
        score += 50 if user.firstTurn?
        return score
    end
end

#===============================================================================
# User switches places with its ally. (Ally Switch)
#===============================================================================
class PokeBattle_Move_UserSwapsPositionsWithAlly < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        eachValidSwitch(user) do |_ally|
            return false
        end
        if show_message
            @battle.pbDisplay(_INTL("But it failed, since {1} has no valid allies to switch with!", user.pbThis(true)))
        end
        return true
    end

    def eachValidSwitch(battler)
        idxUserOwner = @battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
        battler.eachAlly do |b|
            next if @battle.pbGetOwnerIndexFromBattlerIndex(b.index) != idxUserOwner
            next unless b.near?(battler)
            yield b
        end
    end

    def pbEffectGeneral(user)
        idxA = user.index
        idxB = -1
        eachValidSwitch(user) do |ally|
            idxB = ally.index
        end
        if @battle.pbSwapBattlers(idxA, idxB)
            @battle.pbDisplay(_INTL("{1} and {2} switched places!",
               @battle.battlers[idxB].pbThis, @battle.battlers[idxA].pbThis(true)))
        end
    end

    def getEffectScore(_user, _target)
        echoln("The AI will never use Ally Switch.")
        return 0
    end
end

#===============================================================================
# Allies of the user also attack the target with Slash. (All For One)
#===============================================================================
class PokeBattle_Move_AlliesAlsoUseSlashAgainstTarget < PokeBattle_Move
    def pbEffectAfterAllHits(user, target)
        user.eachAlly do |b|
            break if target.fainted?
            @battle.pbDisplay(_INTL("{1} joins in the attack!", b.pbThis))
            battle.forceUseMove(b, :SLASH, target.index)
        end
    end
end

#===============================================================================
# Can't miss if attacking a target that already used an attack this turn. (Power Whip)
#===============================================================================
class PokeBattle_Move_CantMissAgainstTargetAlreadyAttacked < PokeBattle_Move
    def pbAccuracyCheck(user, target)
        targetChoice = @battle.choices[target.index][0]
        return true if targetChoice == :UseMove && target.movedThisRound?
        return super
    end
end

def selfHitBasePower(level)
    calcLevel = [level, 50].min
    selfHitBasePower = (20 + calcLevel)
    selfHitBasePower = selfHitBasePower.ceil
    return selfHitBasePower
end

#===============================================================================
# Increases the target's attacking stats by 3 steps each, then the (Backhand)
# target hits itself with its own Attack or Sp. Atk, whichever is higher.
#===============================================================================
class PokeBattle_Move_RaiseTargetAtkSpAtk3TargetHitsSelfAdaptive < PokeBattle_Move
    def pbEffectAgainstTarget(user, target)
        target.pbRaiseMultipleStatSteps(ATTACKING_STATS_3, user, move: self)
        target.pbConfusionDamage(_INTL("It hurt itself in a rage!"), false, selfHitBasePower(target.level))
    end

    def getTargetAffectingEffectScore(user, target)
        score = 0
        score -= getMultiStatUpEffectScore(ATTACKING_STATS_3, user, target, evaluateThreat: false)
        score -= 70 if targetIsUnaware?(target, aiCheck: true)
        score += getMultiStatUpEffectScore(ATTACKING_STATS_3, user, user, evaluateThreat: false) if user.hasActiveAbilityAI?(:PETTY)
        return score
    end

    def calculateDamageForHitAI(user,target,type,baseDmg,numTargets)
        damage = calculateDamageForHit(user,target,type,baseDmg,numTargets,true)
        damage *= 1.75 unless targetIsUnaware?(target, aiCheck: true)
        return damage
    end

    def getDetailsForMoveDex(detailsList = [])
        detailsList << _INTL("Base power is 20 plus the target's level, capped at 70 BP.")
    end
end

#===============================================================================
# The user takes 33% less damage until end of this turn.
# (Shimmering Heat)
#===============================================================================
class PokeBattle_Move_UserTakesThirdLessDamageThisTurn < PokeBattle_Move
    def pbEffectAfterAllHits(user, _target)
        user.applyEffect(:ShimmeringHeat)
    end

    def getEffectScore(user, target)
        return getWantsToBeFasterScore(user, target, 3)
    end
end

#===============================================================================
# Faints the opponant if they are below 1/4 HP, after dealing damage. (Cull)
#===============================================================================
class PokeBattle_Move_FaintsTargetBelowQuarterOfTotalHP < PokeBattle_Move
    def canCull?(target)
        return target.hp < (target.totalhp / 4)
    end

    def pbEffectAgainstTarget(user, target)
        if canCull?(target)
            @battle.pbDisplay(_INTL("{1} culls {2}!", user.pbThis, target.pbThis(true)))
            target.pbReduceHP(target.hp, false)
            target.pbItemHPHealCheck
        end
    end

    def shouldHighlight?(_user, target)
        return canCull?(target)
    end
end

#===============================================================================
# The user, if a Deerling or Sawsbuck, changes their form in season order. (Season's End)
#===============================================================================
class PokeBattle_Move_ChangeUserDeerlingSawsbuckForm < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        unless user.countsAs?(:DEERLING) || user.countsAs?(:SAWSBUCK)
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis)) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        if user.countsAs?(:DEERLING) || user.countsAs?(:SAWSBUCK)
            newForm = (user.form + 1) % 4
            formChangeMessage = _INTL("The season shifts!")
            user.pbChangeForm(newForm, formChangeMessage)
        end
    end
end

########################################################
### Specific avatar only moves
########################################################

#===============================================================================
# Targets struck lose their flinch immunity. Only usable by the avatar of Rayquaza (Stratosphere Scream)
#===============================================================================
class PokeBattle_Move_RayquazaTargetLosesFlinchImmunity < PokeBattle_Move
    def ignoresSubstitute?(_user); return true; end

    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:RAYQUAZA) || !user.boss?
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectAfterAllHits(_user, target)
        return if target.fainted?
        return if target.damageState.unaffected
        if target.effectActive?(:FlinchImmunity)
            target.disableEffect(:FlinchImmunity)
            @battle.pbDisplay(_INTL("{1} is newly afraid. It can be flinched again!", target.pbThis))
        end
    end
end

#===============================================================================
# Summons an Avatar of Luvdisc and an Avatar of Remoraid.
# Only usable by the avatar of Kyogre (Seven Seas Edict)
#===============================================================================
class PokeBattle_Move_KyogreSummonAvatarLuvdiscRemoraid < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:KYOGRE) || !user.boss?
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end
        unless @battle.pbSideSize(user.index) == 1
            @battle.pbDisplay(_INTL("But there is no room for fish to join!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        @battle.pbDisplay(_INTL("Fish are drawn to the field!", user.pbThis))
        @battle.summonAvatarBattler(:LUVDISC, user.level, 0, user.index % 2)
        @battle.summonAvatarBattler(:REMORAID, user.level, 0, user.index % 2)
        @battle.pbSwapBattlers(user.index, user.index + 2)

        @battle.remakeDataBoxes
    end
end

#===============================================================================
# Summons permanent Gravity, which also doubles the weight of Pokemon on the opposing side.
# Only usable by the avatar of Groudon (Warping Core)
#===============================================================================
class PokeBattle_Move_GroudonStartGravityDoubleAllWeight < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        if !user.countsAs?(:GROUDON) || !user.boss?
            @battle.pbDisplay(_INTL("But {1} can't use the move!", user.pbThis(true))) if show_message
            return true
        end
        if @battle.field.effectActive?(:WarpingCore)
            @battle.pbDisplay(_INTL("But gravity is already warped!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbEffectGeneral(_user)
        @battle.field.applyEffect(:WarpingCore)
    end
end

#===============================================================================
# All Normal-type moves become Electric-type for the rest of the round.
# (Ion Deluge, Plasma Fists)
#===============================================================================
class PokeBattle_Move_NormalMovesBecomeElectric < PokeBattle_Move
    def pbMoveFailed?(user, _targets, show_message)
        return false if damagingMove?
        if @battle.field.effectActive?(:IonDeluge)
            @battle.pbDisplay(_INTL("But it failed, since ions already shower the field!")) if show_message
            return true
        end
        return true if pbMoveFailedLastInRound?(user, show_message)
        return false
    end

    def pbEffectGeneral(_user)
        @battle.field.applyEffect(:IonDeluge)
    end
end

#===============================================================================
# Accuracy perfect in moonglow. (Nightfelling)
#===============================================================================
class PokeBattle_Move_CantMissIfInMoonglow < PokeBattle_Move
    def pbBaseAccuracy(user, target)
        return 0 if @battle.moonGlowing?
        return super
    end

    def shouldHighlight?(_user, _target)
        return @battle.moonGlowing?
    end
end

#===============================================================================
# The user chooses one of Fire Fang, Ice Fang, and Thunder Fang to use. (Elemental Fang)
#===============================================================================
class PokeBattle_Move_UseChoiceOf3ElementalFangs < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def initialize(battle, move)
        super
        @validMoves = %i[
            FIREFANG
            THUNDERFANG
            ICEFANG
        ]
    end

    def resolutionChoice(user)
        validMoveNames = []
        @validMoves.each do |move|
            validMoveNames.push(getMoveName(move))
        end

        if @battle.autoTesting
            @chosenMove = @validMoves.sample
        elsif !user.pbOwnedByPlayer? # Trainer AI
            @chosenMove = @validMoves[0]
        else
            chosenIndex = @battle.scene.pbShowCommands(_INTL("Which move should {1} use?", user.pbThis(true)),validMoveNames,0)
            @chosenMove = @validMoves[chosenIndex]
        end
    end

    def pbEffectAgainstTarget(user, target)
        user.pbUseMoveSimple(@chosenMove, target.index) if @chosenMove
    end

    def resetMoveUsageState
        @chosenMove = nil
    end

    def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
        return # No animation
    end
end

#===============================================================================
# Fails if the user is not asleep. (Snore)
#===============================================================================
class PokeBattle_Move_FailsIfUserNotAsleep < PokeBattle_Move
    def usableWhenAsleep?; return true; end

    def pbMoveFailed?(user, _targets, show_message)
        unless user.asleep?
            @battle.pbDisplay(_INTL("But it failed, since {1} isn't asleep!", user.pbThis(true))) if show_message
            return true
        end
        return false
    end

    def pbMoveFailedAI?(user, targets)
        return true unless user.willStayAsleepAI?
        return pbMoveFailed?(user, targets, false)
    end
end

#===============================================================================
# Uses each other Sound move the Pokemon knows. (Broadcast Blast)
#===============================================================================
class PokeBattle_Move_UseAllOtherSoundMoves < PokeBattle_Move
    def callsAnotherMove?; return true; end

    def getAllOtherSoundMoves(user)
        moves = []
        user.getMoves.each do |m|
            next unless m.soundMove?
            next unless @battle.canInvokeMove?(m)
            moves.push(m.id)
        end
        return moves
    end

    def pbMoveFailed?(user, _targets, show_message)
        if getAllOtherSoundMoves(user).length == 0
            if show_message
                @battle.pbDisplay(_INTL("But it failed, since {1} knows no other sound-based moves!", user.pbThis(true)))
            end
            return true
        end
        return false
    end

    def pbEffectGeneral(user)
        moves = getAllOtherSoundMoves(user)
        moves.each do |sound_move|
            user.pbUseMoveSimple(sound_move)
        end
    end
end