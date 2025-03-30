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
    local expectedTechProgress = storage.expectedTechProgress

    local adjustedTime = techAdjustedTime(unadjustedTime)

    -- Dead people make it expect less tech, in case the tech curve got too far ahead of you.
    if (expectedTechProgress == nil) then
        expectedTechProgress = 0
    end
    if (expectedTechProgress < CONFIG.tech_times.red) then
        return "start", CONFIG.tech_times.red - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.green ) then
        return "red", CONFIG.tech_times.green - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.greenblack) then
        return "green", CONFIG.tech_times.greenblack - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.blue) then
        return "greenblack", CONFIG.tech_times.blue - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.blueblack) then
        return "blue", CONFIG.tech_times.blueblack - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.purple_yellow_first) then
        return "blueblack", CONFIG.tech_times.purple_yellow_first - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.purple_yellow_second) then
        return storage.yellow_purple_order[1], CONFIG.tech_times.purple_yellow_second - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.purpleyellow) then
        return storage.yellow_purple_order[2], CONFIG.tech_times.purpleyellow - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.white) then
        -- purpleyellow has no items in it and I don't understand why not.
        return storage.yellow_purple_order[2], CONFIG.tech_times.white - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.latewhite) then
        return "white", CONFIG.tech_times.latewhite - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.innerplanetstech) then
        return "latewhite", CONFIG.tech_times.innerplanetstech - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.earlycryogenic) then
        return "innerplanetstech", CONFIG.tech_times.earlycryogenic - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.cryogenic) then
        return "earlycryogenic", CONFIG.tech_times.cryogenic - expectedTechProgress
    elseif (expectedTechProgress < CONFIG.tech_times.final) then
        return "cryogenic", CONFIG.tech_times.final - expectedTechProgress
    else
        return "final", CONFIG.tech_times.final - expectedTechProgress
    end
end
