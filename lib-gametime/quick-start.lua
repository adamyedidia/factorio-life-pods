require "config"
require "lifepods-utils"

function effectiveTime(tick)
    return tick + storage.quickStartTimeBonus
end

function initQuickStart()
    local chest_force = game.forces.player
    if not settings.global["life-pods-quick-start"].value then
        storage.quickStartTimeBonus = 0
        return
    end
    storage.quickStartTimeBonus = 60 * TICKS_PER_MINUTE
    local position = {-2,-3}
    local crushed_entities = game.surfaces[1].find_entities({{-3,-3}, {-1,-1}})
    for _, entity in pairs(crushed_entities) do
        entity.destroy()
    end

    if not game.surfaces[1].can_place_entity{name="steel-chest", position=position, force=chest_force} then
        printAllPlayers({"lifepods.quickstart-invalid-chest"})
    else
        local ironchest = game.surfaces[1].create_entity{name="steel-chest", position=position, force=chest_force}
        ironchest.insert{name="iron-plate", count=4800 }
    end
    position = {-3,-2}
    if not game.surfaces[1].can_place_entity{name="steel-chest", position=position, force=chest_force} then
        printAllPlayers({"lifepods.quickstart-invalid-chest"})
    else
        local miscchest = game.surfaces[1].create_entity{name="steel-chest", position=position, force=chest_force }
        miscchest.insert{name="copper-plate", count=1800 }
        miscchest.insert{name="electronic-circuit", count=400 }
        miscchest.insert{name="iron-gear-wheel", count=400 }
        miscchest.insert{name="inserter", count=100 }
        miscchest.insert{name="transport-belt", count=200 }
        miscchest.insert{name="stone-brick", count=200 }
        miscchest.insert{name="steel-plate", count=400 }
        miscchest.insert{name="stone", count=200 }
        miscchest.insert{name="wood", count=200}
        miscchest.insert{name="coal", count=400 }
    end

    for _, force in pairs(game.forces) do
        for name, tech in pairs(force.technologies) do
            if #tech.research_unit_ingredients == 1 and tech.enabled and not tech.upgrade then
                force.technologies[name].researched = true
            end
        end
    end
end
