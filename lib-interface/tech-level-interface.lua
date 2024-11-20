require "lifepods-utils"

techInterface = {
    getIngredients = nil,
    getUnitCount = nil,
    getPrereqs = nil
}

local function count_green_prereqs(the_tech, techInterface)
    local prereqs = 0
    for _, prereq in pairs(techInterface.getPrereqs(the_tech)) do
        local recursive_level = getTechLevel(prereq, techInterface)
        if recursive_level == "greenblack" then return 100 end -- Minor hack to ensure that if a previous one is gb, this one is too.
        if (recursive_level == "green") then
            prereqs = prereqs + 1 + count_green_prereqs(prereq, techInterface)
        end
    end
    return prereqs
end

function getTechLevelInterface(tech, techInterface)
    local ingredient_names = techInterface.getIngredients(tech)
    local ingredient_count = techInterface.getUnitCount(tech)

    local ingredient_set = {}
    for _, ingredient in pairs(ingredient_names) do
        ingredient_set[ingredient] = true
    end

    if tech.name == "steam-power" then return "start" end
    if tech.name == "electronics" then return "start" end
    if tech.name == "planet-discovery-fulgora" then return "latewhite" end
    if tech.name == "planet-discovery-vulcanus" then return "latewhite" end
    if tech.name == "planet-discovery-gleba" then return "latewhite" end
    if tech.name == "planet-discovery-aquilo" then return "cryogenic" end
    if tech.name == "automation-science-pack" then return "red" end
    if tech.name == "logistic-science-pack" then return "green" end
    if tech.name == "military-science-pack" then return "greenblack" end
    if tech.name == "chemical-science-pack" then return "blue" end
    if tech.name == "production-science-pack" then return "purple" end
    if tech.name == "utility-science-pack" then return "yellow" end
    if tech.name == "space-science-pack" then return "white" end

    if ingredient_set["promethium-science-pack"] then return "final" end    
    if ingredient_set["cryogenic-science-pack"] then return "cryogenic" end
    if ingredient_set["agricultural-science-pack"] then return "innerplanetstech" end
    if ingredient_set["electromagnetic-science-pack"] then return "innerplanetstech" end
    if ingredient_set["metallurgic-science-pack"] then return "innerplanetstech" end
    if ingredient_set["space-science-pack"] or ingredient_count > 3000 then return "white" end
    if ingredient_set["utility-science-pack"] then
        if ingredient_set["production-science-pack"] or ingredient_count > 1000 then return "purpleyellow"
        else return "yellow" end
    end
    if ingredient_set["production-science-pack"] then return "purple" end
    if ingredient_set["chemical-science-pack"] then
        if ingredient_set["military-science-pack"] or ingredient_count > 500 then return "blueblack" end
        return "blue"
    end
    if ingredient_set["logistic-science-pack"] then
        if ingredient_set["military-science-pack"]  or ingredient_count > 300 or count_green_prereqs(tech, techInterface) > 2 then
            return "greenblack"
        else return "green" end
    end
    if ingredient_set["automation-science-pack"] then return "red" end

    local maxTechLevelSoFar = "start"

    for _, prereq in pairs(techInterface.getPrereqs(tech)) do
        local recursive_level = getTechLevel(prereq, techInterface)
        maxTechLevelSoFar = techLevelMax(maxTechLevelSoFar, recursive_level)
    end
    return maxTechLevelSoFar
end