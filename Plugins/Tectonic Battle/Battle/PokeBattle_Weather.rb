class PokeBattle_Battle
    SPECIAL_EFFECT_WAIT_TURNS = 4

    def defaultWeather=(value)
        @field.defaultWeather = value
        @field.weather         = value
        @field.weatherDuration = -1
    end

    def weatherSuppressed?
        eachBattler do |b|
            return true if b.hasActiveAbility?(:AIRLOCK)
        end
        return false
    end

    # Returns the effective weather (note that weather effects can be negated)
    def pbWeather
        return :None if weatherSuppressed?
        return @field.weather
    end

    # Used for causing weather by a move or by an ability.
    def pbStartWeather(user, newWeather, duration = -1, showAnim = true, ignoreFainted = false, ability = nil)
        oldWeather = @field.weather

        resetExisting = @field.weather == newWeather
        endWeather(newWeather == :None) unless resetExisting

        # Set the new weather and duration
        @field.weather = newWeather
        duration = user.getWeatherSettingDuration(newWeather, duration, ignoreFainted) if duration > 0 && user

        noChange = resetExisting && duration == @field.weatherDuration

        # If we're resetting an existing weather, don't set the duration to lower than it was before
        if resetExisting
            @field.weatherDuration = duration if duration > @field.weatherDuration || duration < 0
        else
            @field.weatherDuration = duration
        end

        @field.resetSpecialEffect unless resetExisting

        # Show animation, if desired
        unless noChange
            pbShowAbilitySplash(user, ability) if user && ability
            weather_data = GameData::BattleWeather.try_get(@field.weather)
            pbCommonAnimation(weather_data.animation) if showAnim && weather_data
        end

        if resetExisting
            displayResetWeatherMessage unless noChange
        else
            displayFreshWeatherMessage unless noChange
            # Check for end of primordial weather, and weather-triggered form changes
            eachBattler { |b| b.pbCheckFormOnWeatherChange }
            pbEndPrimordialWeather
        end
        
        if $Options.weather_messages == 0 && !noChange
            if @field.weatherDuration < 0
                pbDisplay(_INTL("It'll last indefinitely!"))
            else
                moreTurns = @field.weatherDuration
                moreTurns -= 1 unless @turnCount == 0
                pbDisplay(_INTL("It'll last for {1} more turns!", moreTurns))
            end
        end
        pbHideAbilitySplash(user) if user && ability

        triggerWeatherChangeDialogue(oldWeather, @field.weather) unless resetExisting

        battlers.each do |b|
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerWeatherChangedAbility(ability, oldWeather, b, self)
            end
        end
    end

    def displayResetWeatherMessage
        case @field.weather
        when :Sunshine      then pbDisplay(_INTL("The sunshine continues!"))
        when :Rainstorm     then pbDisplay(_INTL("The rainstorm shows no sign of stopping!"))
        when :Sandstorm     then pbDisplay(_INTL("The sandstorm returns to full strength!"))
        when :Hail          then pbDisplay(_INTL("The hail keeps coming!"))
        when :Eclipse       then pbDisplay(_INTL("The eclipse extends unnaturally!"))
        when :Moonglow      then pbDisplay(_INTL("The bright moon doesn't wane!"))
        when :RingEclipse   then pbDisplay(_INTL("The planetary ring tightens its grip!"))
        when :BloodMoon     then pbDisplay(_INTL("The nightmarish moon is unending!"))
        when :StarStorm     then pbDisplay(_INTL("The star storm continues!"))
        when :IceAge        then pbDisplay(_INTL("The ice age may go on forever!"))
        end
    end

    def displayFreshWeatherMessage
        case @field.weather
        when :Sunshine      then pbDisplay(_INTL("The sun is shining in the sky!"))
        when :Rainstorm     then pbDisplay(_INTL("A rainstorm covers the sky!"))
        when :Sandstorm     then pbDisplay(_INTL("A sandstorm brewed!"))
        when :Hail          then pbDisplay(_INTL("It started to hail!"))
        when :HarshSun      then pbDisplay(_INTL("The sunlight turned extremely harsh!"))
        when :HeavyRain     then pbDisplay(_INTL("A heavy rain began to fall!"))
        when :StrongWinds   then pbDisplay(_INTL("Mysterious strong winds are protecting Flying-type Pokémon!"))
        when :Eclipse       then pbDisplay(_INTL("An eclipse covers the sun!"))
        when :Moonglow      then pbDisplay(_INTL("The light of the moon shines down!"))
        when :RingEclipse   then pbDisplay(_INTL("A planetary ring dominates the sky!"))
        when :BloodMoon     then pbDisplay(_INTL("A nightmare possessed the moon!"))
        when :StarStorm     then pbDisplay(_INTL("Stardust is churning around!"))
        when :IceAge        then pbDisplay(_INTL("An ice age began!"))
        end
    end

    def endWeather(affectAbilities=true)
        return if @field.weather == :None
        case @field.weather
        when :Sunshine      then pbDisplay(_INTL("The sunshine faded."))
        when :Rainstorm     then pbDisplay(_INTL("The rainstorm stopped."))
        when :Sandstorm     then pbDisplay(_INTL("The sandstorm subsided."))
        when :Hail          then pbDisplay(_INTL("The hail stopped."))
        when :Eclipse       then pbDisplay(_INTL("The eclipse ended."))
        when :Moonglow      then pbDisplay(_INTL("The moonlight faded."))
        when :HeavyRain     then pbDisplay(_INTL("The heavy rain has lifted!"))
        when :HarshSun      then pbDisplay(_INTL("The harsh sunlight faded!"))
        when :StrongWinds   then pbDisplay(_INTL("The mysterious air current has dissipated!"))
        when :RingEclipse   then pbDisplay(_INTL("The planetary ring flew off!"))
        when :BloodMoon     then pbDisplay(_INTL("The nightmare is purged from the moon!"))
        when :StarStorm     then pbDisplay(_INTL("The star storm ceases!"))
        when :IceAge        then pbDisplay(_INTL("The ice age makes way!"))
        end
        oldWeather = @field.weather
        @field.weather	= :None
        @field.weatherDuration = 0
        @field.resetSpecialEffect
        triggerWeatherChangeDialogue(oldWeather, :None)
        if affectAbilities
            battlers.each do |b|
                b.eachActiveAbility do |ability|
                    BattleHandlers.triggerWeatherChangedAbility(ability, oldWeather, b, self)
                end
            end
        end
    end

    PRIMORDIAL_WEATHER_LINGER_TURNS = 4

    # Ability-set Primordial Sea, Desolate Land, Delta Stream begin to run out
    def pbEndPrimordialWeather
        return unless @field.weatherDuration < 0
        case @field.weather
        when :HarshSun
            if !pbCheckGlobalAbility(:DESOLATELAND) && @field.defaultWeather != :HarshSun
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The harsh sunlight began to fade!"))
            end
        when :HeavyRain
            if !pbCheckGlobalAbility(:PRIMORDIALSEA) && @field.defaultWeather != :HeavyRain
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The heavy rain began to lift!"))
            end
        when :StrongWinds
            if !pbCheckGlobalAbility(:DELTASTREAM) && @field.defaultWeather != :StrongWinds
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The mysterious air current began to dissipate!"))
            end
        when :RingEclipse
            if !pbCheckGlobalAbility(:SATURNALSKY) && @field.defaultWeather != :RingEclipse
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The planetary ring begins to lose its grip!"))
            end
        when :BloodMoon
            if !pbCheckGlobalAbility(:STYGIANNIGHT) && @field.defaultWeather != :BloodMoon
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The nightmare moon begins to retreat!"))
            end
        when :StarStorm
            if !pbCheckGlobalAbility(:EVENTHORIZON) && @field.defaultWeather != :StarStorm
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The barrage of stardust shows signs of stopping!"))
            end
        when :IceAge
            if !pbCheckGlobalAbility(:HEATDEATH) && @field.defaultWeather != :IceAge
                @field.weatherDuration = PRIMORDIAL_WEATHER_LINGER_TURNS
                pbDisplay(_INTL("The ice age begins to end!"))
            end
        end

        if @field.weatherDuration > 0
            moreTurns = @field.weatherDuration - 1
            pbDisplay(_INTL("It'll last for {1} more turns!", moreTurns))
        end
    end

    def extendWeather(numTurns = 1)
        return if pbWeather == :None
        weatherName = GameData::BattleWeather.get(pbWeather).name
        if @field.weatherDuration < 0
            pbDisplay(_INTL("The {1} would be extended, but it's already indefinite!",weatherName))
            return
        end
        @field.weatherDuration += numTurns
        if numTurns == 1
            pbDisplay(_INTL("The {1} extends by a turn!",weatherName))
        else
            pbDisplay(_INTL("The {1} extends by {2} turns!",weatherName,numTurns))
        end
    end

    def primevalWeatherPresent?(showMessages = true)
        case @field.weather
        when :HarshSun
            pbDisplay(_INTL("The extremely harsh sunlight was not lessened at all!")) if showMessages
            return true
        when :HeavyRain
            pbDisplay(_INTL("There is no relief from this heavy rain!")) if showMessages
            return true
        when :StrongWinds
            pbDisplay(_INTL("The mysterious air current blows on regardless!")) if showMessages
            return true
        when :RingEclipse
            pbDisplay(_INTL("The skyline is still dominated by a planet!")) if showMessages
            return true
        when :BloodMoon
            pbDisplay(_INTL("The nightmarish moon is unaffected!")) if showMessages
            return true
        when :StarStorm
            pbDisplay(_INTL("The star storm is unstoppable!")) if showMessages
            return true
        when :IceAge
            pbDisplay(_INTL("The ice age is still in control!")) if showMessages
            return true
        end
        return false
    end

    #=============================================================================
    # Start Of Round weather
    #=============================================================================

    def pbSORWeather(priority)
        curWeather = pbWeather

        @field.specialTimer += 1

        threshold = SPECIAL_EFFECT_WAIT_TURNS
        threshold /= 2 if weatherSpedUp?

        showWeatherMessages = $Options.weather_messages == 0

        if curWeather == :StarStorm && @field.specialTimer > 1 &&  @field.specialTimer % 3 == 1
            if  @field.specialTimer == 4
                pbDisplay(_INTL("The stardust expands! Its damage has doubled!"))
            else
                pbDisplay(_INTL("The stardust expands yet again!"))
            end
        end

        if @field.specialTimer >= threshold
            case curWeather
            when :Eclipse,:RingEclipse
                primevalVariant = curWeather == :RingEclipse
                if showWeatherMessages
                    if primevalVariant
                        pbDisplay(_INTL("The Total Ring Eclipse arrives!"))
                    else
                        pbDisplay(_INTL("The Total Eclipse arrives!"))
                    end
                end
                pbCommonAnimation("Eclipse")
                anyAffected = false
                debuff = primevalVariant ? ALL_STATS_3 : ALL_STATS_2
                priority.each do |b|
                    next if b.fainted?
                    next unless b.debuffedByEclipse?
                    if primevalVariant
                        pbDisplay(_INTL("{1} is severely panicked!", b.pbThis))
                    else
                        pbDisplay(_INTL("{1} is panicked!", b.pbThis))
                    end
                    b.pbLowerMultipleStatSteps(debuff, showFailMsg: true)
                    anyAffected = true
                end
                pbDisplay(_INTL("But no one was panicked.")) if showWeatherMessages && !anyAffected
                eachBattler do |b|
                    b.eachActiveAbility do |ability|
                        BattleHandlers.triggerTotalEclipseAbility(ability, b, self)
                    end
                end
                @field.specialTimer = 0
                @field.specialWeatherEffect = true
            when :Moonglow, :BloodMoon
                primevalVariant = curWeather == :BloodMoon
                if showWeatherMessages
                    if primevalVariant
                        pbDisplay(_INTL("The Full Blood Moon rises!"))
                    else
                        pbDisplay(_INTL("The Full Moon rises!"))
                    end
                end
                pbCommonAnimation("Moonglow")
                anyAffected = false
                priority.each do |b|
                    next if b.fainted?
                    next unless b.flinchedByMoonglow?
                    pbDisplay(_INTL("{1} is moonstruck! It'll flinch this turn!", b.pbThis))
                    b.pbFlinch
                    if primevalVariant
                        b.applyFractionalDamage(1.0/4.0)
                        pbDisplay(_INTL("{1} is afflicted by the nightmarish moon!", b.pbThis))
                    end
                    anyAffected = true
                end
                pbDisplay(_INTL("But no one was moonstruck.")) if showWeatherMessages && !anyAffected
                eachBattler do |b|
                    b.eachActiveAbility do |ability|
                        BattleHandlers.triggerFullMoonAbility(ability, b, self)
                    end
                end
                @field.specialTimer = 0
                @field.specialWeatherEffect = true
            end
        else
            @field.specialWeatherEffect = false

            # Special effect happening next turn
            if @field.specialTimer + 1 == threshold && @field.weatherDuration > 1
                if showWeatherMessages
                    case curWeather
                    when :Eclipse
                        pbDisplay(_INTL("The Total Eclipse is approaching."))
                    when :Moonglow
                        pbDisplay(_INTL("The Full Moon is approaching."))
                    when :RingEclipse
                        pbDisplay(_INTL("The Total Ring Eclipse is approaching."))
                    when :BloodMoon
                        pbDisplay(_INTL("The Full Blood Moon is approaching."))
                    end
                end
            end
        end
    end

    # Returns true if the weather went away
    def tickDownWeather
        # NOTE: Primordial weather doesn't need to be checked here, because if it
        #       could wear off here, it will have worn off already.
        # Count down weather duration
        @field.weatherDuration -= 1 if @field.weatherDuration > 0

        # Weather wears off
        if @field.weatherDuration == 0
            endWeather
            @field.weather = :None
            # Check for form changes caused by the weather changing
            eachBattler { |b| b.pbCheckFormOnWeatherChange }
            # Start up the default weather
            pbStartWeather(nil, @field.defaultWeather) if @field.defaultWeather != :None
            return if @field.weather == :None
        end
    end

    def weatherSpedUp?
        return true if eclipsed? && pbCheckGlobalAbility(:EPHEMERATE)
        return true if moonGlowing? && pbCheckGlobalAbility(:SOLSTICE)
        return false
    end

    #=============================================================================
    # End Of Round weather
    #=============================================================================
    def pbEORWeather(priority)
        PBDebug.log("[DEBUG] Counting down weathers")

        return if tickDownWeather

        # Tick down twice if weathers are being sped up
        return if weatherSpedUp? && tickDownWeather

        # Weather continues
        weather_data = GameData::BattleWeather.try_get(@field.weather)
        pbCommonAnimation(weather_data.animation) if weather_data && @field.specialTimer < SPECIAL_EFFECT_WAIT_TURNS - 1

        # Effects due to weather
        showWeatherMessages = $Options.weather_messages == 0
        hailDamage = 0
        sandstormDamage = 0
        priority.each do |b|
            # Weather-related abilities
            b.eachActiveAbility do |ability|
                oldHP = b.hp
                BattleHandlers.triggerEORWeatherAbility(ability, pbWeather, b, self)
                break if b.pbHealthLossChecks(oldHP)
            end
            sandstormDamage += applySandstormDamage(b, showWeatherMessages) if sandy?
            hailDamage += applyHailDamage(b, showWeatherMessages) if icy?
        end
        
        # Winter's Wages
        if hailDamage > 0
            priority.each do |b|
                next unless b.hasActiveAbility?(:WINTERSWAGES)
                pbShowAbilitySplash(b, :WINTERSWAGES)
                healingMessage = _INTL("{1} absorbs the suffering from the hailstorm.", b.pbThis)
                b.pbRecoverHP(hailDamage, true, true, true, healingMessage)
                pbHideAbilitySplash(b)
            end
        end
        # Desert Scavenger
        if sandstormDamage > 0
            priority.each do |b|
                next unless b.hasActiveAbility?(:DESERTSCAVENGER)
                pbShowAbilitySplash(b, :DESERTSCAVENGER)
                healingMessage = _INTL("{1} absorbs the suffering from the sandstorm", b.pbThis)
                b.pbRecoverHP(sandstormDamage, true, true, true, healingMessage)
                pbHideAbilitySplash(b)
            end
        end
    end

    def applySandstormDamage(battler, showMessages = true, aiCheck: false)
        return 0 unless battler.takesSandstormDamage?
        damageDoubled = pbCheckGlobalAbility(:IRONSTORM)
        if showMessages && !aiCheck
            if pbWeather == :StarStorm
                if @field.specialTimer >= 5
                    if damageDoubled
                        pbDisplay(_INTL("{1} is shredded by gigantic particles of iron stardust!", battler.pbThis))
                    else
                        pbDisplay(_INTL("{1} is buffeted by gigantic particles of stardust!", battler.pbThis))
                    end 
                elsif @field.specialTimer >= 3
                    if damageDoubled
                        pbDisplay(_INTL("{1} is shredded by large particles of iron stardust!", battler.pbThis))
                    else
                        pbDisplay(_INTL("{1} is buffeted by large particles of stardust!", battler.pbThis))
                    end 
                else
                    if damageDoubled
                        pbDisplay(_INTL("{1} is shredded by iron stardust!", battler.pbThis))
                    else
                        pbDisplay(_INTL("{1} is buffeted by stardust!", battler.pbThis))
                    end  
                end
            else
                if damageDoubled
                    pbDisplay(_INTL("{1} is shredded by the iron-infused sandstorm!", battler.pbThis))
                else
                    pbDisplay(_INTL("{1} is buffeted by the sandstorm!", battler.pbThis))
                end  
            end
        end
        fraction = 1.0 / 16.0
        fraction *= 2 if damageDoubled
        fraction *= 2 if curseActive?(:CURSE_BOOSTED_SAND)
        fraction *= 2 * (@field.specialTimer - 1) / 3 if pbWeather == :StarStorm
        sandstormDamage = battler.applyFractionalDamage(fraction, aiCheck: aiCheck)
        return sandstormDamage
    end

    def applyHailDamage(battler, showMessages = true, aiCheck: false)
        return 0 unless battler.takesHailDamage?
        damageDoubled = pbCheckGlobalAbility(:BITTERCOLD)
        if showMessages && !aiCheck
            if pbWeather == :IceAge
                if damageDoubled
                    pbDisplay(_INTL("{1} is pummeled by the bitterly cold shards of ice!", battler.pbThis))
                else
                    pbDisplay(_INTL("{1} is buffeted by shards of ice!", battler.pbThis))
                end
            else
                if damageDoubled
                    pbDisplay(_INTL("{1} is pummeled by the bitterly cold hail!", battler.pbThis))
                else
                    pbDisplay(_INTL("{1} is buffeted by the hail!", battler.pbThis))
                end
            end
        end
        fraction = 1.0 / 16.0
        fraction *= 2 if damageDoubled
        fraction *= 2 if curseActive?(:CURSE_BOOSTED_HAIL)
        hailDamage = battler.applyFractionalDamage(fraction, aiCheck: aiCheck)
        # Ice Age anti-healing effect
        if hailDamage > 0 && pbWeather == :IceAge && !battler.effectActive?(:HealBlock)
            battler.applyEffect(:HealBlock)
        end
        return hailDamage
    end

    #=============================================================================
    # Weather helper methods
    #=============================================================================
    def sunny?
        return %i[Sunshine HarshSun].include?(pbWeather)
    end

    def rainy?
        return %i[Rainstorm HeavyRain].include?(pbWeather)
    end

    def sandy?
        return %i[Sandstorm StarStorm].include?(pbWeather)
    end

    def icy?
        return %i[Hail IceAge].include?(pbWeather)
    end

    def eclipsed?
        return %i[Eclipse RingEclipse].include?(pbWeather)
    end

    def moonGlowing?
        return %i[Moonglow BloodMoon].include?(pbWeather)
    end

    def partialEclipse?
        return eclipsed? && !@field.specialWeatherEffect
    end

    def totalEclipse?
        return eclipsed? && @field.specialWeatherEffect
    end

    def waxingMoon?
        return moonGlowing? && !@field.specialWeatherEffect
    end

    def fullMoon?
        return moonGlowing? && @field.specialWeatherEffect
    end
end
