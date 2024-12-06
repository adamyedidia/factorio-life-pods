require "lib-interface.tech-level-interface"
require "lib-gametime.population-monitor"
require "lib-gametime.quick-start"

local techGametimeImpl = {
    getIngredients = function(tech)
        local ingredients = tech.research_unit_ingredients
        ingredients = table.mapField(ingredients, "name")
        return ingredients
    end,
    getUnitCount = function(tech)
        return tech.research_unit_count
    end,
    getPrereqs = function (tech)
        if tech.prerequisites == nil then
            error("Tech " .. tech.name .. " has no prerequisites.")
        end
        return tech.prerequisites
    end
}

function getTechLevel(tech)
    return getTechLevelInterface(tech, techGametimeImpl)
end

function techAdjustedTime(unadjustedTime)
    return (effectiveTime(unadjustedTime) - (summarizePop().dead * CONFIG.dead_pop_feedback.tech_times)) / storage.difficulty.values.tech_rate_factor
end
function getTechEra(unadjustedTime)
    local adjustedTime = techAdjustedTime(unadjustedTime)
    -- Dead people make it expect less tech, in case the tech curve got too far ahead of you.
    if (adjustedTime < CONFIG.tech_times.red) then
        return "start", CONFIG.tech_times.red - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.green ) then
        return "red", CONFIG.tech_times.green - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.greenblack) then
        return "green", CONFIG.tech_times.greenblack - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.blue) then
        return "greenblack", CONFIG.tech_times.blue - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.blueblack) then
        return "blue", CONFIG.tech_times.blueblack - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.purple_yellow_first) then
        return "blueblack", CONFIG.tech_times.purple_yellow_first - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.purple_yellow_second) then
        return storage.yellow_purple_order[1], CONFIG.tech_times.purple_yellow_second - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.purpleyellow) then
        return storage.yellow_purple_order[2], CONFIG.tech_times.purpleyellow - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.white) then
        return "purpleyellow", CONFIG.tech_times.white - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.latewhite) then
        return "white", CONFIG.tech_times.latewhite - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.innerplanetstech) then
        return "latewhite", CONFIG.tech_times.innerplanetstech - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.earlycryogenic) then
        return "innerplanetstech", CONFIG.tech_times.earlycryogenic - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.cryogenic) then
        return "earlycryogenic", CONFIG.tech_times.cryogenic - adjustedTime
    elseif (adjustedTime < CONFIG.tech_times.final) then
        return "cryogenic", CONFIG.tech_times.final - adjustedTime
    else
        return "final", CONFIG.tech_times.final - adjustedTime
    end
end
