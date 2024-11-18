function summarizePop()
    local active = 0
    local stable = 0
    local dead = storage.deadPodsPopulation
    for _, pod in pairs (storage.lifePods) do
        dead = dead + pod.startingPop - pod.alivePop
        if pod.stabilized then
            stable = stable + pod.alivePop
        else
            active = active + pod.alivePop
        end

    end
    return {active=active, dead=dead, stable=stable}
end

local function maxDead()
    if storage.mode == "rocket" then
        return "/" .. CONFIG.ROCKET_MAX_DEATHS
    elseif storage.mode == "rescue" then
        return "/" .. math.floor(CONFIG.RESCUE_MAX_DEATHS_PER_HOUR * storage.rescueTick / TICKS_PER_HOUR / 10) * 10
    elseif storage.mode == "infinity" then
        return ""
    else
        debugError("Unsupported maxDead for mode: " .. storage.mode)
        return ""
    end
end

function displayGlobalPop()
    local summary = summarizePop()
    for _, player in pairs(game.players) do
        if top_ui(player).lifepods then
            top_ui(player).lifepods.population.popActiveNumber.caption= summary.active
            top_ui(player).lifepods.population.popStableNumber.caption= summary.stable
            top_ui(player).lifepods.population.popDeadNumber.caption= summary.dead .. maxDead()
        end
    end
end