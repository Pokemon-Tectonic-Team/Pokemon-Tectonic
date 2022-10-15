class PokeBattle_Move
    def pbDisplayUseMessage(user,targets=[])

        @battle.triggerBattlerIsUsingMoveDialogue(user,targets,self)
    
        if zMove? && !@specialUseZMove
          @battle.pbCommonAnimation("ZPower",user,nil) if @battle.scene.pbCommonAnimationExists?("ZPower")
          PokeBattle_ZMove.from_status_move(@battle, @id, user) if statusMove?
          @battle.pbDisplay(_INTL("{1} surrounded itself with its Z-Power!",user.pbThis)) if !statusMove?
          @battle.pbDisplay(_INTL("{1} unleashed its full force Z-Move!",user.pbThis))
        end
        
        if isEmpowered?
          pbMessage(_INTL("\\ts[{3}]{1} used <c2=06644bd2>{2}</c2>!",user.pbThis,@name,MessageConfig.pbGetTextSpeed() * 2))
        else
          @battle.pbDisplayBrief(_INTL("{1} used {2}!",user.pbThis,@name))
        end
        if damagingMove?
          if !multiHitMove?
            targets.each do |target|
              bp = pbBaseDamage(@baseDamage,user,target).floor
              if bp != @baseDamage
                if targets.length == 1
                  @battle.pbDisplayBrief(_INTL("Its base power was adjusted to {1}!",bp))
                else
                  @battle.pbDisplayBrief(_INTL("Its base power was adjusted to {1} against {2}!",bp,target.pbThis(true)))
                end
              end
            end
          end
          # Display messages letting the player know that weather is debuffing a move (if it is)
          if $PokemonSystem.weather_messages == 0
            if applyRainDebuff?(user)
              if @battle.pbCheckGlobalAbility(:DREARYCLOUDS)
                @battle.pbDisplay(_INTL("{1}'s attack is dampened a lot by the dreary rain.",user.pbThis))
              else
                @battle.pbDisplay(_INTL("{1}'s attack is dampened by the rain.",user.pbThis))
              end
            end
            if applySunDebuff?(user)
              if @battle.pbCheckGlobalAbility(:BLINDINGLIGHT)
                @battle.pbDisplay(_INTL("{1} is blinded by the bright light of the sun.",user.pbThis))
              else
                @battle.pbDisplay(_INTL("{1} is distracted by the shining sun.",user.pbThis))
              end
            end
          end
        end
    end

    def canParentalBond?(user,targets,checkingForAI=false)
      return user.shouldAbilityApply?(:PARENTALBOND,checkingForAI) && pbDamagingMove? && !chargingTurnMove? && targets.length==1
    end

    # The maximum number of hits in a round this move will actually perform. This
    # can be 1 for Beat Up, and can be 2 for any moves affected by Parental Bond.
    def pbNumHits(user,targets,checkingForAI=false)
      return 2 if canParentalBond?(user,targets,checkingForAI)
      numHits = 1
      numHits += 1 if user.shouldAbilityApply?(:SPACEINTERLOPER,checkingForAI) && pbDamagingMove?
      numHits += 1 if user.effects[PBEffects::VolleyStance] && move.specialMove?
      return numHits
    end

      # Reset move usage counters (child classes can increment them).
    def pbChangeUsageCounters(user,specialUsage)
        user.effects[PBEffects::FuryCutter]   = 0
        user.effects[PBEffects::IceBall]   = 0
        user.effects[PBEffects::RollOut]   = 0
        user.effects[PBEffects::ParentalBond] = 0
        user.effects[PBEffects::ProtectRate]  = 1
        @battle.field.effects[PBEffects::FusionBolt]  = false
        @battle.field.effects[PBEffects::FusionFlare] = false
    end

    #=============================================================================
    # Check if target is immune to the move because of its ability
    #=============================================================================
    def pbImmunityByAbility(user,target)
        return false if @battle.moldBreaker
        ret = false
        if target.abilityActive?
            ret = BattleHandlers.triggerMoveImmunityTargetAbility(target.ability,user,target,self,@calcType,@battle)
        end
        if !ret
            target.eachAlly do |b|
                next if !b.abilityActive?
                ret = BattleHandlers.triggerMoveImmunityAllyAbility(b.ability,user,target,self,@calcType,@battle,b)
                break if ret
            end
        end
        return ret
    end
    
    #=============================================================================
    # Weaken the damage dealt (doesn't actually change a battler's HP)
    #=============================================================================
    def pbCheckDamageAbsorption(user,target)
        # Substitute will take the damage
        if target.effects[PBEffects::Substitute]>0 && !ignoresSubstitute?(user) && (!user || user.index!=target.index)
            target.damageState.substitute = true
            return
        end
        # Disguise will take the damage
        if !@battle.moldBreaker && target.isSpecies?(:MIMIKYU) && target.form==0 && target.ability == :DISGUISE
            target.damageState.disguise = true
            return
        end
        # Ice Face will take the damage
        if !@battle.moldBreaker && target.species == :EISCUE && target.form==0 && target.ability == :ICEFACE && physicalMove?
            target.damageState.iceface = true
            return
        end
    end
    
    def pbReduceDamage(user,target)
        damage = target.damageState.calcDamage
        target.damageState.displayedDamage = damage
        # Substitute takes the damage
        if target.damageState.substitute
            damage = target.effects[PBEffects::Substitute] if damage>target.effects[PBEffects::Substitute]
            target.damageState.hpLost       = damage
            target.damageState.totalHPLost += damage
            target.damageState.displayedDamage = damage
            return
        end
        # Disguise takes the damage
        if target.damageState.disguise
            target.damageState.displayedDamage = 0
            return
        end
        # Ice Face takes the damage
        if target.damageState.iceface
            target.damageState.displayedDamage = 0
            return
        end
        # Target takes the damage
        damageAdjusted = false
        if damage>=target.hp
        damage = target.hp
        # Survive a lethal hit with 1 HP effects
            if nonLethal?(user,target)
                damage -= 1
                damageAdjusted = true
            elsif target.effects[PBEffects::Endure]
                target.damageState.endured = true
                damage -= 1
                damageAdjusted = true
            elsif target.effects[PBEffects::EmpoweredEndure] > 0
                target.damageState.endured = true
                damage -= 1
                damageAdjusted = true
                target.effects[PBEffects::EmpoweredEndure] -= 1
            elsif target.hasActiveAbility?(:DIREDIVERSION) && !target.item.nil? && target.itemActive? && !@battle.moldBreaker
                target.damageState.direDiversion = true
                damage -= 1
                damageAdjusted = true
            elsif damage==target.totalhp
                if target.hasActiveAbility?(:STURDY) && !@battle.moldBreaker
                    target.damageState.sturdy = true
                    damage -= 1
                    damageAdjusted = true
                elsif target.hasActiveItem?(:FOCUSSASH) && target.hp==target.totalhp
                    target.damageState.focusSash = true
                    damage -= 1
                    damageAdjusted = true
                elsif target.hasActiveItem?(:CASSBERRY) && target.hp==target.totalhp
                    target.damageState.endureBerry = true
                    damage -= 1
                    damageAdjusted = true
                elsif target.hasActiveItem?(:FOCUSBAND) && @battle.pbRandom(100)<10
                    target.damageState.focusBand = true
                    damage -= 1
                    damageAdjusted = true
                end
            end
        end
        target.damageState.displayedDamage = damage if damageAdjusted
        damage = 0 if damage<0
        target.damageState.displayedDamage = 0 if target.damageState.displayedDamage < 0
        target.damageState.hpLost       = damage
        target.damageState.totalHPLost += damage
    end

    #=============================================================================
    # Animate the damage dealt, including lowering the HP
    #=============================================================================
    # Animate being damaged and losing HP (by a move)
    def pbAnimateHitAndHPLost(user,targets,fastHitAnimation=false)
        # Animate allies first, then foes
        animArray = []
        for side in 0...2   # side here means "allies first, then foes"
        targets.each do |b|
            next if b.damageState.unaffected || b.damageState.hpLost==0
            next if (side==0 && b.opposes?(user)) || (side==1 && !b.opposes?(user))
            oldHP = b.hp+b.damageState.hpLost
            PBDebug.log("[Move damage] #{b.pbThis} lost #{b.damageState.hpLost} HP (#{oldHP}=>#{b.hp})")
            effectiveness = b.damageState.typeMod / Effectiveness::NORMAL_EFFECTIVE
            animArray.push([b,oldHP,effectiveness])
        end
        if animArray.length>0
            @battle.scene.pbHitAndHPLossAnimation(animArray,fastHitAnimation)
            animArray.clear
        end
        end
    end

    #=============================================================================
    # Messages upon being hit
    #=============================================================================
    def pbEffectivenessMessage(user,target,numTargets=1)
        return if target.damageState.disguise
        return if target.damageState.iceface
        return if defined?($PokemonSystem.effectiveness_messages) && $PokemonSystem.effectiveness_messages == 1
        if Effectiveness.hyper_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's hyper effective on {1}!",target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's hyper effective!"))
            end
        elsif Effectiveness.super_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's super effective on {1}!",target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's super effective!"))
            end
        elsif Effectiveness.barely_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's barely effective on {1}...",target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's barely effective..."))
            end
        elsif Effectiveness.not_very_effective?(target.damageState.typeMod)
            if numTargets > 1
                @battle.pbDisplay(_INTL("It's not very effective on {1}...",target.pbThis(true)))
            else
                @battle.pbDisplay(_INTL("It's not very effective..."))
            end
        end
    end
  
    def pbHitEffectivenessMessages(user,target,numTargets=1)
        return if target.damageState.disguise
        return if target.damageState.iceface
        if target.damageState.substitute
            @battle.pbDisplay(_INTL("The substitute took damage for {1}!",target.pbThis(true)))
        end
        if target.damageState.critical
            onAddendum = numTargets > 1 ? " on #{target.pbThis(true)}" : ""
            if target.damageState.forced_critical
              @battle.pbDisplay(_INTL("#{user.pbThis} performed a critical attack#{onAddendum}!",))
            else
				      @battle.pbDisplay(_INTL("A critical hit#{onAddendum}!"))
            end
        end
        # Effectiveness message, for moves with 1 hit
        if target.damageState.messagesPerHit
            pbEffectivenessMessage(user,target,numTargets)
        end
        if target.damageState.substitute && target.effects[PBEffects::Substitute]==0
            target.effects[PBEffects::Substitute] = 0
            @battle.pbDisplay(_INTL("{1}'s substitute faded!",target.pbThis))
        end
    end

	def pbEndureKOMessage(target)
		if target.damageState.disguise
			@battle.pbShowAbilitySplash(target)
			if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
				@battle.pbDisplay(_INTL("Its disguise served it as a decoy!"))
			else
				@battle.pbDisplay(_INTL("{1}'s disguise served it as a decoy!",target.pbThis))
			end
			@battle.pbHideAbilitySplash(target)
			target.pbChangeForm(1,_INTL("{1}'s disguise was busted!",target.pbThis))
		elsif target.damageState.iceface
			@battle.pbShowAbilitySplash(target)
			target.pbChangeForm(1,_INTL("{1} transformed!",target.pbThis))
			@battle.pbHideAbilitySplash(target)
		elsif target.damageState.endured
			@battle.pbDisplay(_INTL("{1} endured the hit!",target.pbThis))
		elsif target.damageState.sturdy
			@battle.pbShowAbilitySplash(target)
			if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
				@battle.pbDisplay(_INTL("{1} endured the hit!",target.pbThis))
			else
				@battle.pbDisplay(_INTL("{1} hung on with Sturdy!",target.pbThis))
			end
			@battle.pbHideAbilitySplash(target)
		elsif target.damageState.focusSash
			@battle.pbCommonAnimation("UseItem",target)
			@battle.pbDisplay(_INTL("{1} hung on using its Focus Sash!",target.pbThis))
			target.pbConsumeItem
		elsif target.damageState.focusBand
            @battle.pbCommonAnimation("UseItem",target)
			@battle.pbDisplay(_INTL("{1} hung on using its Focus Band!",target.pbThis))
		elsif target.damageState.direDiversion
			@battle.pbDisplay(_INTL("{1} blocked the hit with its item! It barely hung on!",target.pbThis))
			target.pbConsumeItem
		elsif target.damageState.endureBerry
			itemName = GameData::Item.get(target.item).real_name
			@battle.pbDisplay(_INTL("{1} hung on by consuming its {2}!",target.pbThis,itemName))
			target.pbConsumeItem
		end
	end

    def selectPartyMemberForEffect(idxBattler,selectableProc=nil)
        # Get player's party
        party    = @battle.pbParty(idxBattler)
        partyPos = @battle.pbPartyOrder(idxBattler)
        partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
        modParty = @battle.pbPlayerDisplayParty(idxBattler)
        # Start party screen
        pkmnScene = PokemonParty_Scene.new
        pkmnScreen = PokemonPartyScreen.new(pkmnScene,modParty)
        #pkmnScreen.pbStartScene(_INTL("Use move on which Pokémon?"),@battle.pbNumPositions(0,0))
        idxParty = -1
        # Loop while in party screen
        loop do
          # Select a Pokémon
          idxParty = pkmnScreen.pbChooseAblePokemon(selectableProc)
          next if idxParty < 0
          idxPartyRet = -1
          partyPos.each_with_index do |pos,i|
            next if pos!=idxParty+partyStart
            idxPartyRet = i
            break
          end
          next if idxPartyRet < 0
          pkmn = party[idxPartyRet]
          next if !pkmn || pkmn.egg?
          yield pkmn
          break
        end
        pkmnScene.pbEndScene
    end

    def pbAromatherapyHeal(pkmn,battler=nil)
      if battler
          battler.pbCureStatus()
      else
        oldStatus = (battler) ? battler.status : pkmn.status
        curedName = (battler) ? battler.pbThis : pkmn.name
        pkmn.status      = :NONE
        pkmn.statusCount = 0
        case oldStatus
          when :SLEEP
            @battle.pbDisplay(_INTL("{1} was woken from sleep.",curedName))
          when :POISON
            @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",curedName))
          when :BURN
            @battle.pbDisplay(_INTL("{1}'s burn was healed.",curedName))
          when :PARALYSIS
            @battle.pbDisplay(_INTL("{1} was cured of numb.",curedName))
          when :FROZEN
            @battle.pbDisplay(_INTL("{1} warmed up.",curedName))
          when :FROSTBITE
            @battle.pbDisplay(_INTL("{1} frostbite was healed.",curedName))
          when :FLUSTERED
            @battle.pbDisplay(_INTL("{1} is no longer flustered.",curedName))
          when :FROZEN
            @battle.pbDisplay(_INTL("{1} is no longer mystified.",curedName))
          end
        end
    end

    # Used by Counter/Mirror Coat/Metal Burst/Revenge/Focus Punch/Bide/Assurance.
    def pbRecordDamageLost(user,target)
      damage = target.damageState.hpLost
      # NOTE: In Gen 3 where a move's category depends on its type, Hidden Power
      #       is for some reason countered by Counter rather than Mirror Coat,
      #       regardless of its calculated type. Hence the following two lines of
      #       code.
      moveType = nil
      moveType = :NORMAL if @function=="090"   # Hidden Power
      if physicalMove?(moveType)
        target.effects[PBEffects::Counter]       = damage
        target.effects[PBEffects::CounterTarget] = user.index
      elsif specialMove?(moveType)
        target.effects[PBEffects::MirrorCoat]       = damage
        target.effects[PBEffects::MirrorCoatTarget] = user.index
      end
      if target.effects[PBEffects::Bide] > 0
        target.effects[PBEffects::BideDamage] += damage
        target.effects[PBEffects::BideTarget] = user.index if user.index != target.index
      end
      target.damageState.fainted = true if target.fainted?
      target.lastHPLost = damage             # For Focus Punch
      target.tookDamage = true if damage>0   # For Assurance
      target.lastAttacker.push(user.index)   # For Revenge
      if target.opposes?(user)
        target.lastHPLostFromFoe = damage              # For Metal Burst
        target.lastFoeAttacker.push(user.index)        # For Metal Burst
        target.lastRoundHighestTypeModFromFoe = target.damageState.typeMod if target.damageState.typeMod > target.lastRoundHighestTypeModFromFoe
      end
    end
end