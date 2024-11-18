require "config"
require "util"
require "table-supplement"

function vector2Add(v1, v2)
    return {x=v1.x+v2.x, y=v1.y+v2.y}
end
function vector2Half(v)
    return {x=v.x/2, y=v.y/2}
end
function math.power(a, b)
    return math.exp(b * math.log(a))
end

function printAllPlayers(text, force)
    for i, player in pairs(game.players) do
        if force == nil or player.force == force then
            player.print(text)
        end
    end
end


function debugPrint(text, even_if_not_debug_mode)
    if (settings.startup["life-pods-debug"].value or even_if_not_debug_mode) then
        printAllPlayers({"lifepods.debug", text})
    end
end

function debugError(text)
    if (settings.startup["life-pods-debug"].value) then
        error(text)
    end
end

function getItem(itemName)
    for i, item in pairs(prototypes.item) do
        if (item.name == itemName) then return item end
    end
    return nil
end
function formattimelong(ticks)
    if (ticks > TICKS_PER_HOUR) then
        local hours = math.floor(ticks / TICKS_PER_HOUR)
        local minutes = math.floor((ticks % TICKS_PER_HOUR) / TICKS_PER_MINUTE)
        return hours .. "h" .. minutes
    else
        return util.formattime(ticks)
    end
end

function podRecipeNameFromItem(product, level)
    return podRecipeNameFromItemName(product.name, level)
end
function podRecipeNameFromItemName(name, level)
    if type(name) == "table" then error("Received table for argument 'name':" .. table.tostring(name)) end
    return "life-pod-" .. level .. "-" .. name
end
function itemLevelFromRecipeName(recipeName)
    local stripped = string.sub(recipeName, string.len("life-pod-") + 1, -1)
    local level_len = string.find(stripped, "-")
    local level = string.sub(stripped, 1, level_len - 1)
    local item = string.sub(stripped, level_len + 1)
    return {item=item, level=level}
end

function podDamagePerSec(pod)
    local damage = CONFIG.POD_HEALTH_PER_SEC * pod.endgame_speedup
    for tier=1,3 do
        if (pod.repair.get_module_inventory().get_item_count("life-pods-damage-reduction-module-"..tier) > 0) then
            damage = damage * CONFIG.CRYOSTASIS_HEALTH_PER_SEC_BONUS[tier]
        end
    end
    return damage
end

function podHeartsConsumptionPerPopPerSec(pod)
    local consumption = pod.consumption * pod.endgame_speedup
    if pod.repair then
        for tier=1,3 do
            if (pod.repair.get_module_inventory().get_item_count("life-pods-consumption-module-"..tier) > 0) then
                consumption = consumption * CONFIG.CONSUMPTION_MODULE_BONUS[tier]
            end
        end
    end
    return consumption
end

function podHeartsConsumptionPerSec(pod)
    return podHeartsConsumptionPerPopPerSec(pod) * pod.alivePop
end

function podSecondsPerInput(pod)
    if not pod.recipe then
        debugError("Error: something bad happened with recipes....\n\n" .. table.tostring(pod))
        return 0
    end
    if not pod.recipe.products[1] then
        debugError("Error: something bad happened with recipes.products ....\n\n" .. table.tostring(pod))
        return 0
    end
    return pod.recipe.products[1].amount / (podHeartsConsumptionPerSec(pod) * pod.recipe.ingredients[1].amount)
end

function podSecsTillDeath(pod)
    local hp_per_sec = podDamagePerSec(pod)
    local hpTime = (pod.repair.health - ((pod.alivePop - 1) * CONFIG.POD_HEALTH_PER_POP))/ hp_per_sec
    local healSupply = pod.repair.fluidbox[1]
    if (healSupply and healSupply.amount) then
        return hpTime + healSupply.amount / podHeartsConsumptionPerSec(pod)
    end
    return hpTime
end

function shuffle(list)
    local shuffled = {}
        for i, v in pairs(list) do
            local pos = math.random(1, #shuffled+1)
            table.insert(shuffled, pos, v)
        end
    return shuffled
end

function recipeCategoryFromLevel(lvl)
    return "life-pod-" .. lvl
end
function lvlFromRecipeCategory(cat)
    return string.sub(cat, 10, -1)
end

function all_human_forces()
    local result = {}
    for name, force in pairs(game.forces) do
        if #force.players > 0 then
            result[name] = force
        end
    end
    return result
end