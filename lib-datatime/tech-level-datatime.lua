require "lib-interface.tech-level-interface"
require "lib-datatime.global-lookup-datatime"

local techPrototypeImpl = {
    getIngredients = function(tech)
        if tech == nil then
            return {}
        end
        if tech.unit == nil then
            return {}
        end
        local ingredients = tech.unit.ingredients
        ingredients = table.mapField(ingredients, 1)
        return ingredients
    end,
    getUnitCount = function(tech)
        if tech == nil then
            return 0
        end
        if tech.unit == nil then
            return 0
        end
        return tech.unit.count
    end,
    getPrereqs = function(tech)
        if tech == nil then
            return {}
        end
        if tech.prerequisites == nil then
            if settings.startup["life-pods-mod-compatibility-mode"].value == "strict" then
                error("Tech " .. tech.name .. " has no prerequisites.")
            else
                return {}
            end
        end
        local prereqs = {}
        for _, prereq_name in pairs(tech.prerequisites) do
            prereqs[prereq_name] = global_lookup_by_name.technology(prereq_name)
        end
        return prereqs
    end
}

function getTechLevel(tech)
    return getTechLevelInterface(tech, techPrototypeImpl)
end

function techLevelMin(a, b)
    if a == "start" or b == "start" then return "start" end
    if (CONFIG.tech_times[a] < CONFIG.tech_times[b]) then
        return a
    else
        return b
    end
end

function techLevelMax(a, b)
    if a == nil then error("nil Level (a)") end
    if b == nil then error("nil Level (b)") end
    if a == "start" then return b end
    if b == "start" then return a end
    if CONFIG.tech_times[a] == nil then error("invalid level: " .. a) end
    if CONFIG.tech_times[b] == nil then error("invalid level: " .. b) end
    if (CONFIG.tech_times[a] < CONFIG.tech_times[b]) then
        return b
    else
        return a
    end
end