##############################################
# TYPE REWARDS (18 of them)
##############################################
typeThreshold = [50]
typeRewards = [[:EXPCANDYXL,5]]

PokEstate::LoadDataDependentAwards += proc {
    # For every type, create three award event subscribers at different thresholds
    GameData::Type.each do |type|
        next if type.pseudo_type
        next if type.id == :MUTANT
        typeThreshold.each_with_index do |threshold,thresholdIndex|
            id = ("TYPE" + type.id.to_s + "AWARD" + thresholdIndex.to_s).to_sym
            PokEstate::GrantAwards.add(id,
                proc { |pokedex|
                    next typeReward(type.id,threshold,typeRewards[thresholdIndex])
                }
            )
        end
    end
}

##############################################
# TRIBE REWARDS (22 of them)
##############################################
tribeThreshold = [50]
tribeRewards = [[:EXPCANDYXL,4]]

PokEstate::LoadDataDependentAwards += proc {
    # For every type, create three award event subscribers at different thresholds
    GameData::Tribe.each do |tribe|
        next if !$DEBUG && tribe.id.start_with?("DEBUG_") # skip debug tribes if not in debug mode
        tribeThreshold.each_with_index do |threshold,thresholdIndex|
            id = ("TRIBE" + tribe.id.to_s + "AWARD" + thresholdIndex.to_s).to_sym
            PokEstate::GrantAwards.add(id,
                proc { |pokedex|
                    next tribeReward(tribe.id,threshold,tribeRewards[thresholdIndex])
                }
            )
        end
    end
}

##############################################
# ROUTE REWARDS (45  of them)
##############################################
# 1
SMALL_ROUTES_CASABA = [
    67, # Old Ice Cream Shop
]

# 13
SMALL_ROUTES_PRE_SURF = [
    56, # Novo Town
    25, # Grouz
    36, # Grouz Mine
    326, # Carnation Graves
    6, # LuxTech Campus
    122, # LuxTech Sewers
    40, # Gigalith's Guts
    120, # Hollowed Layer
    214, # Team Chasm HQ
    121, # Kilna Ascent
    37, # Svait
    117, # Ice Cave
    8, # Velenz
    129, # Barren Crater
]

# 7
SMALL_ROUTES_POST_SURF = [
    155, # Prizca West
    34, # Battle Plaza
    223, # Battle Plaza Underground
    187, # Prizca East
    220, # Ancient Sewers
    217, # Sweetrock Harbor
    316, # Sandstone Estuary
]
 
# 6
MEDIUM_ROUTES_CASABA = [
    136, # Casaba Villa
    138, # Scenic Trail
    30, # Windy Way
    51, # Foreclosed Tunnel
    38, # Bluepoint Beach
    26, # Bluepoint Grotto
]

# 6
MEDIUM_ROUTES_PRE_SURF =
[
    59, # Feebas' Fin
    60, # Shipping Lane
    3, # The Shelf
    55, # Lingering Delta
    11, # Eleig River Crossing
    7, # Repora Forest
]

# 7
MEDIUM_ROUTES_POST_SURF = [
    130, # Canal Desert
    186, # Frostflow Farms
    216, # Highland Lake
    193, # Volcanic Shore
    196, # Boiling Cave
    288, # Underground River
    218, # Abyssal Cavern
]

# 0
BIG_ROUTES_CASABA = [
]

# 2
BIG_ROUTES_PRE_SURF = [
    53, # The Shelf
    301, # County Park
]

# 2
BIG_ROUTES_POST_SURF = [
    185, # Eleig Stretch
    211, # Split Peaks
]

PokEstate::LoadDataDependentAwards += proc {
    # CASABA ISLAND #
    SMALL_ROUTES_CASABA.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYS,5]
                next areaReward(routeID,reward)
            }
        )
    end

    MEDIUM_ROUTES_CASABA.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYS,10]
                next areaReward(routeID,reward)
            }
        )
    end

    BIG_ROUTES_CASABA.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYS,15]
                next areaReward(routeID,reward)
            }
        )
    end

    # PRE-SURF ROUTES #

    SMALL_ROUTES_PRE_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYM,3]
                next areaReward(routeID,reward)
            }
        )
    end

    MEDIUM_ROUTES_PRE_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYM,6]
                next areaReward(routeID,reward)
            }
        )
    end

    BIG_ROUTES_PRE_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYM,9]
                next areaReward(routeID,reward)
            }
        )
    end

    # POST-SURF #

    SMALL_ROUTES_POST_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYL,2]
                next areaReward(routeID,reward)
            }
        )
    end

    MEDIUM_ROUTES_POST_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYL,4]
                next areaReward(routeID,reward)
            }
        )
    end

    BIG_ROUTES_POST_SURF.each do |routeID|
        routeName = pbGetMapNameFromId(routeID)
        id = ("ROUTE" + routeName + "AWARD").to_sym
        PokEstate::GrantAwards.add(id,
            proc { |pokedex|
                reward = [:EXPCANDYL,6]
                next areaReward(routeID,reward)
            }
        )
    end

    # HUGE ROUTES #

    PokEstate::GrantAwards.add("MENAGERIEREWARD",
        proc { |pokedex|
            reward = [:EXPCANDYXL,10]
            next areaReward(213,reward)
        }
    )

    PokEstate::GrantAwards.add("OCEANFISHINGREWARD",
        proc { |pokedex|
            reward = [:EXPCANDYXL,15]
            next areaReward(239,reward)
        }
    )
}

##############################################
# OVERALL DEX COMPLETION
##############################################
PokEstate::LoadDataDependentAwards += proc {

    threshold100Percent = nonLegendarySpeciesCount(false)
    threshold25Percent = (threshold100Percent / 4.0).floor
    threshold50Percent = (threshold100Percent / 2.0).floor
    threshold75Percent = (3.0 * threshold100Percent / 4.0).floor

    PokEstate::GrantAwards.add(:DEXCOMPLETION25PERCENT,
        proc { |pokedex|
            next {
                reward: [:MASTERBALL,3],
                description: _INTL("{1} non-legendary species (25%)",threshold25Percent),
                page: 4,
                threshold: threshold25Percent,
                amount: nonLegendarySpeciesCount(true),
            }
        }
    )

    PokEstate::GrantAwards.add(:DEXCOMPLETION50PERCENT,
        proc { |pokedex|
            next {
                reward: [:BALLLAUNCHER],
                description: _INTL("{1} non-legendary species (50%)",threshold50Percent),
                page: 4,
                threshold: threshold50Percent,
                amount: nonLegendarySpeciesCount(true),
            }
        }
    )

    PokEstate::GrantAwards.add(:DEXCOMPLETION75PERCENT,
        proc { |pokedex|
            next {
                reward: [:GLEAMPOWDER],
                description: _INTL("{1} non-legendary species (75%)",threshold75Percent),
                page: 4,
                threshold: threshold75Percent,
                amount: nonLegendarySpeciesCount(true),
            }
        }
    )

    PokEstate::GrantAwards.add(:DEXCOMPLETION100PERCENT,
        proc { |pokedex|
            next {
                reward: [:SHINYCHARM],
                description: _INTL("{1} non-legendary species (100%)",threshold100Percent),
                page: 4,
                threshold: threshold100Percent,
                amount: nonLegendarySpeciesCount(true),
            }
        }
    )
}