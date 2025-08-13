RAIN_DEBUFF_ACTIVE = true
SUN_DEBUFF_ACTIVE = true

class PokeBattle_Move
    attr_reader   :battle
    attr_reader   :realMove
    attr_accessor :id
    attr_reader   :name
    attr_reader   :function
    attr_reader   :baseDamage
    attr_accessor :type
    attr_reader   :category
    attr_reader   :accuracy
    attr_accessor :pp
    attr_writer   :total_pp
    attr_reader   :effectChance
    attr_reader   :target
    attr_reader   :priority
    attr_reader   :flags
    attr_accessor :calcType
    attr_accessor :powerBoost
    attr_accessor :snatched
    attr_accessor :category_override
  
    def to_int; return @id; end
  
    #=============================================================================
    # Creating a move
    #=============================================================================
    def initialize(battle, move)
      @battle     = battle
      @realMove   = move
      @id         = move.id
      @name       = move.name   # Get the move's name
      # Get data on the move
      @function   = move.function_code
      @baseDamage = move.base_damage
      @type       = move.type
      @category   = move.category
      @category_override = nil # By default, won't overwrite @category
      @accuracy   = move.accuracy
      @pp         = move.pp   # Can be changed with Mimic/Transform
      @effectChance = move.effect_chance
      @target     = move.target
      @priority   = move.priority
      @flags      = move.flags
      @calcType   = nil
      @powerBoost = false   # For Aerilate, Pixilate, Refrigerate, Galvanize
      @snatched   = false
    end
  
    # This is the code actually used to generate a PokeBattle_Move object. The
    # object generated is a subclass of this one which depends on the move's
    # function code (found in the script section PokeBattle_MoveEffect).
    def PokeBattle_Move.from_pokemon_move(battle, move)
      validate move => Pokemon::Move
      moveFunction = move.function_code || "Basic"
      className = sprintf("PokeBattle_Move_%s", moveFunction)
      if Object.const_defined?(className)
        begin
          return Object.const_get(className).new(battle, move)
        rescue StandardError
          raise "Error while trying to create a move of class #{className}"
        end
      else
        raise "A class for move function code #{moveFunction} does not exist!"
      end
      return PokeBattle_UnimplementedMove.new(battle, move)
    end
  
    #=============================================================================
    # About the move
    #=============================================================================
    def pbTarget(user)
        targetData = GameData::Target.get(@target)
        # Effects that make things spread
        if damagingMove? && targetData.can_target_one_foe?
          return GameData::Target.get(:AllNearFoes) if user.effectActive?(:FlareWitch)
          return GameData::Target.get(:AllNearFoes) if @calcType == :PSYCHIC && user.hasActiveAbility?(:MULTITASKER)
          return GameData::Target.get(:AllNearFoes) if @calcType == :FIGHTING && user.hasActiveAbility?(:EVENHANDED)
          return GameData::Target.get(:AllNearFoes) if user.hasActiveAbility?(:SPACIALDISTORTION)
        end
        return targetData
    end
  
    def total_pp
      return @total_pp if @total_pp && @total_pp>0   # Usually undefined
      return @realMove.total_pp if @realMove
      return 0
    end
  
    # NOTE: This method is only ever called while using a move (and also by the
    #       AI), so using @calcType here is acceptable.
    def physicalMove?(thisType=nil)
      return calculatedCategory == 0
    end
  
    def specialMove?(thisType=nil)
      return calculatedCategory == 1
    end

    def adaptiveMove?
      return @category == 3
    end

    def calculatedCategory
      return @category_override || @category
    end
  
    def damagingMove?(aiCheck = false); return @category != 2; end
    def statusMove?;   return @category == 2; end
  
    def usableWhenAsleep?;       return false; end
    def unusableInGravity?;      return false; end
    def healingMove?;            return false; end
    def recoilMove?;             return false; end
    def flinchingMove?;          return false; end
    def callsAnotherMove?;       return false; end
    # Whether the move can/will hit more than once in the same turn (including
    # Beat Up which may instead hit just once). Not the same as pbNumHits>1.
    def multiHitMove?;           return false; end
    def chargingTurnMove?;       return false; end
    def successCheckPerHit?;     return false; end
    def hitsFlyingTargets?;      return false; end
    def hitsDiggingTargets?;     return false; end
    def hitsDivingTargets?;      return false; end
    def ignoresReflect?;         return false; end   # For Brick Break
    def cannotRedirect?;         return false; end   # For Future Sight/Doom Desire
    def worksWithNoTargets?;     return false; end   # For Explosion
    def damageReducedByBurn?;    return true;  end   # For Facade
    def triggersHyperMode?;      return false; end
    def immuneToRainDebuff?;     return false; end
    def immuneToSunDebuff?;      return false; end
    def setsARoom?;              return false; end

    def canProtectAgainst?;     return @flags.include?("CanProtect"); end
    def canMagicCoat?;          return @flags.include?("CanMagicCoat"); end
    def canSnatch?;             return @flags.include?("CanSnatch"); end
    def canMirrorMove?;         return @flags.include?("CanMirrorMove"); end
    def canRandomCrit?;         return @flags.include?("CanRandomCrit"); end
    def doubleCritChance?;      return @flags.include?("DoubleCritChance"); end

    def punchingMove?;          return @flags.include?("Punch"); end
    def kickingMove?;           return @flags.include?("Kicking"); end
    def bitingMove?;            return @flags.include?("Biting"); end
    def bladeMove?;             return @flags.include?("Blade"); end
    
    def soundMove?;             return @flags.include?("Sound"); end
    def windMove?;              return @flags.include?("Wind"); end
    def lightMove?;             return @flags.include?("Light"); end
    def pulseMove?;             return @flags.include?("Pulse"); end
    
    def danceMove?;             return @flags.include?("Dance"); end

    def tagged?
      return true if punchingMove?
      return true if kickingMove?
      return true if bitingMove?
      return true if bladeMove?

      return true if windMove?
      return true if windMove?
      return true if lightMove?
      return true if pulseMove?
      return false
    end

    def foretoldMove?;          return @flags.include?("Foretold"); end
    def empoweredMove?;         return @flags.include?("Empowered"); end

    def turnsBetweenUses(); return 0; end
    def aiAutoKnows?(pokemon); return nil; end
    def statUp; return []; end
    def criticalHitMultiplier(user,target); return 1.5; end
  
    def nonLethal?(user,_target); return false; end   # For False Swipe
    def switchOutMove?; return false; end
    def forceSwitchMove?; return false; end
    def hazardMove?; return false; end
    def statStepStealingMove?; return false; end
    def redirectionMove?; return false; end
    def hazardRemovalMove?; return false; end
    def screenRemovalMove?; return false; end
    def rampagingMove?; return false; end
  
    def ignoresSubstitute?(user)   # user is the Pokémon using this move
      return true if soundMove?
      return true if user && user.hasActiveAbility?(GameData::Ability.getByFlag("IgnoreSubstitute"))
      return false
    end

    def hitsInvulnerable?; return false; end

    def randomEffect?
      return true if @flags.include?("FakeRandomEffect")
      return @effectChance > 0 && @effectChance < 100
    end

    def guaranteedEffect?
      return false if @flags.include?("FakeRandomEffect")
      return @effectChance >= 100
    end

    def spreadMove?
        return GameData::Target.get(@target).spread?
    end

    def getDetailsForMoveDex(detailsList = []); end;
  end
  