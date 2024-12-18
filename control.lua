require "util"
require "lifepods-utils"
require "config"
require "lib-gametime.game-options"
require "lib-gametime.init"
require "lib-gametime.lua-migrations"
require "lib-gametime.ui"
require "lib-gametime.names"
require "lib-gametime.quick-start"
require "lib-gametime.tech-level-gametime"
require "lib-gametime.population-monitor"
require "lib-gametime.assemble-pod-epochs"
script.on_event(defines.events.on_tick, function(event)
    if (not global.init) then
        prepareNextPod()
        global.nextLifePod.arrivalTick = event.tick + math.floor(global.nextLifePod.arrivalTick * CONFIG.FIRST_POD_FACTOR)
        global.nextLifePod.warningTick = event.tick + math.floor(global.nextLifePod.warningTick * CONFIG.FIRST_POD_FACTOR)

        global.init = true
        return
    end

    -- Check for rescue
    if ((global.mode == "rescue") and global.rescueTick and (event.tick >= global.rescueTick)) then
        rescueArrives()
        -- Rescue already came; user pressed "Continue" on victory screen.
        printAllPlayers({"lifepods.changing-to-rocket-mode"})
        setRocketMode()
    end
    -- Check for rescue speedup warning
    if ((global.mode == "rescue") and global.rescueTick and (event.tick == global.rescueTick - CONFIG.RESCUE_SPEEDUP_WARNING_TIME)) then
        rescueSpeedupWarning()
    end
    -- Update Rescue Counter
    if ((global.mode == "rescue") and global.rescueTick and (event.tick % TICKS_PER_SECOND == 0)) then
        for _, player in pairs(game.players) do
            top_ui(player).rescue.caption = {"lifepods.rescue-time", formattimelong(global.rescueTick - event.tick)}
        end
    end

    -- Maintenance on existing pods.
    for i, pod in pairs(global.lifePods) do
        if (i % TICKS_PER_SECOND == event.tick % TICKS_PER_SECOND) then
            secondTickForPodUniversal(pod)
            if not(pod.stabilized) then
                secondTickForPodActive(pod)
                if ((i % TICKS_PER_SECOND) == event.tick % (10 * TICKS_PER_SECOND)) then
                    tenSecondTickForPod(pod)
                end
            end
        end
    end

    if (global.nextLifePod.tracked.time and not nextLifePodAfterRescue()) then
        if ((global.nextLifePod.arrivalTick - event.tick) % TICKS_PER_SECOND == 0) then
            tickLifePod(event.tick)
        end
    end
    if (global.nextLifePod.tracked.location and not nextLifePodAfterRescue()) then
        makeSureLocationMarked()
    end
    if (event.tick >= global.nextLifePod.arrivalTick) then
        landNewPod()
    end
    if (event.tick >= global.nextLifePod.warningTick and not nextLifePodAfterRescue()) then
        newPodWarning(event.tick)
    end

    --Update HumanInterface for each player.
    --TODO is this really inefficient?
    for index,player in pairs(game.players) do
        if index==event.tick % TICKS_PER_SECOND then
            if player.gui.center.humaninterface then
                updateHumanInterface(player)
            end
            if #top_ui(player).selectedpod.children>0 then
                displaySinglePodMouseover(player)
            end
        end
    end
end)

script.on_init(function()
    if not global then
        global = {}
    end
    
    global.lifePods = {}
    global.deadPodsPopulation = 0
    global.difficulty = {
        name = "Normal", 
        values = {
            hearts_factor = 1,
            distance_factor = 1,
            period_factor = 1,
            tech_rate_factor = 1
        }
    }
    global.mode = "rocket"  -- Or whichever default mode you want
    global.rescueTick = 0   -- Also initialize this since it's used in rescue mode

    global.nextLifePod = {
        arrivalTick = game.tick,
        warningTick = game.tick,
        tracked = {
            time = false,
            location = false,
            recipe = false,
            consumption_rate = false,
            overflowing = false
        },
        warningMinimapGhosts = {}
    }
    
    -- Initialize nextToNextLifePod structure
    global.nextToNextLifePod = {
        feedback_extra_time = 0,
        radar_overflow = 0
    }

    init_lifepod_products()
end)

function nextLifePodAfterRescue()
    return (global.mode == "rescue") and global.rescueTick and (global.nextLifePod.arrivalTick > global.rescueTick)
end

script.on_event(defines.events.on_entity_died, function(event)
    if (not (event.entity.name == "life-pod-repair")) then return end
    local deadPod = global.lifePods[event.entity.unit_number]
    printAllPlayers({"lifepods.pod-died", deadPod.name})
    deadPod.radar.destroy()
    deadPod.beacon.destroy()
    if deadPod.label.valid then
        rendering.destroy(deadPod.label)
    else
        debugPrint("Invalid Label on pod ".. deadPod.name .. "; " .. deadPod.id, true)
    end
    for _, label in pairs(deadPod.minimap_labels) do
        label.destroy()
    end
    removePodFromUI(deadPod)
    global.deadPodsPopulation = global.deadPodsPopulation + deadPod.startingPop
    global.lifePods[deadPod.id] = nil
end)

script.on_event(defines.events.on_sector_scanned, function(event)
    if (not global.nextLifePod.tracked.overflowing) then
        global.nextLifePod.warningTick = global.nextLifePod.warningTick - CONFIG.RADAR_SCAN_TICKS
    else
        global.nextToNextLifePod.radar_overflow = global.nextToNextLifePod.radar_overflow + CONFIG.RADAR_SCAN_TICKS
    end
end)

function newPodWarning(tick)
    if CONFIG.TOO_SHORT_WARNING > global.nextLifePod.arrivalTick - tick then
        global.nextLifePod.tracked.overflowing = true
        global.nextToNextLifePod.radar_overflow = global.nextLifePod.arrivalTick - tick
        return
    end
    if (not global.nextLifePod.tracked.recipe) then
        printAllPlayers({"lifepods.warning-item", global.nextLifePod.name})
        global.nextLifePod.tracked.recipe = true
    elseif (not global.nextLifePod.tracked.location) then
        printAllPlayers({"lifepods.warning-location", global.nextLifePod.name})
        local distanceToCenter = math.floor(util.distance(global.nextLifePod.arrivalPosition, {x=0,y=0}))
        -- for _, player in pairs(game.players) do
        --     local distanceToMe = math.floor(util.distance(global.nextLifePod.arrivalPosition, player.position))
        --     player.print("Distance " .. distanceToCenter .. " from center; " .. distanceToMe .. " from you.")
        -- end
        global.nextLifePod.tracked.location = true
        markLocation(global.nextLifePod.arrivalPosition, global.nextLifePod.name .. " INCOMING")
    elseif (not global.nextLifePod.tracked.time) then
        printAllPlayers({"lifepods.warning-time", global.nextLifePod.name})
        global.nextLifePod.tracked.time = true
    elseif (not global.nextLifePod.tracked.consumption_rate) then

        local seconds_per_item = podSecondsPerInput(global.nextLifePod)
        global.nextLifePod.tracked.consumption_rate = seconds_per_item

        local localized_product = game.item_prototypes[global.nextLifePod.product].localised_name
        local rate_string
        if seconds_per_item >= 1 then
            local time = formattimelong(seconds_per_item * TICKS_PER_SECOND)
            printAllPlayers({"lifepods.warning-consumption_rate-gt1", global.nextLifePod.name, localized_product, time})
        else
            local num_per_sec = math.ceil(1 / seconds_per_item)
            printAllPlayers({"lifepods.warning-consumption_rate-lt1", global.nextLifePod.name, localized_product, num_per_sec})
        end

        -- Set next warning tick to arrivaltick, so it doesn't trigger again.
        -- We'll later set overflowing (a few lines down), so this won't get changed until next pod arrives.
        global.nextLifePod.warningTick = global.nextLifePod.arrivalTick + 1
    end


    updateRadarInfo()

    -- If last warning is done, send further radar scans to next pod.
    if global.nextLifePod.tracked.consumption_rate then
        global.nextLifePod.tracked.overflowing = true
        return
    end
    -- Otherwise, send extra radar oomph to next detection.
    if (tick < global.nextLifePod.arrivalTick) then
        local overflow = tick - global.nextLifePod.warningTick
        global.nextLifePod.warningTick = global.nextLifePod.arrivalTick + 1 - overflow * CONFIG.RADAR_OVERFLOW_FACTOR
    else
        debugPrint("Something weird happened with the next warning tick: " .. (global.nextLifePod.arrivalTick + tick)/2 .. ", " .. global.nextLifePod.arrivalTick .. ", " .. game.tick, true)
        global.nextLifePod.arrivalTick = tick + TICKS_PER_MINUTE
    end
end
function markLocation(position, name)
    for _, force in pairs(all_human_forces()) do
        force.chart(game.surfaces[1], {lefttop = position, rightbottom = position})
    end
    makeSureLocationMarked()
end
function makeSureLocationMarked()
    for force_name, force in pairs(all_human_forces()) do
        if global.nextLifePod.warningMinimapGhosts == nil or
                global.nextLifePod.warningMinimapGhosts[force_name] == nil or
                not global.nextLifePod.warningMinimapGhosts[force_name].valid then
        debugPrint("Marking Location for force " .. force_name)
            global.nextLifePod.warningMinimapGhosts[force_name] = force.add_chart_tag(game.surfaces[1],
                {
                position=global.nextLifePod.arrivalPosition,
                text = global.nextLifePod.name  .. " INCOMING",
                icon = {type="item", name="life-pod-warning-icon"}
                }
            )
        end
    end
end
function clearMarkLocation()
    for force_name, force in pairs(all_human_forces()) do
        if global.nextLifePod.warningMinimapGhosts[force_name] and global.nextLifePod.warningMinimapGhosts[force_name].valid then
            global.nextLifePod.warningMinimapGhosts[force_name].destroy()
        end
    end
end

function tickLifePod(tick)
    for _, player in pairs(game.players) do
        top_ui(player).lifepods.nextLifePod.time.caption = {"lifepods.ui-pod-time", global.nextLifePod.name, util.formattime(global.nextLifePod.arrivalTick - tick)}
    end
end
function clearNextPodUI()
    -- TODO how does this interact with players joining/leaving?
    for _, player in pairs(game.players) do
        top_ui(player).lifepods.nextLifePod.time.caption=" "
        top_ui(player).lifepods.nextLifePod.recipe.caption=" "
        top_ui(player).lifepods.nextLifePod.podlocation.caption=" "
    end
end

function landNewPod()
    local name = global.nextLifePod.name
    printAllPlayers({"lifepods.pod-landed", name, game.item_prototypes[global.nextLifePod.product].localised_name})
    -- If they haven't explored it yet (odd because it means they never got the location warning), explore it now.
    -- This probably means the minimap_label won't work, as it seems you can't add tags the same tick you chart.
    -- TODO something like what I did for the warning one, where it checks every tick aftrward if the tag is valid.
    -- TODO Verify if above is fixed or still a bug?
    if not global.nextLifePod.tracked.recipe then
        printAllPlayers({"lifepods.scold-no-radars"})
    end
    for _, force in pairs(all_human_forces()) do
        force.chart(game.surfaces[1], {lefttop = global.nextLifePod.arrivalPosition, rightbottom = global.nextLifePod.arrivalPosition})
    end


    local crushed_entities = game.surfaces[1].find_entities({vector2Add(global.nextLifePod.arrivalPosition, {x=-5,y=-5}), vector2Add(global.nextLifePod.arrivalPosition, {x=5,y=5})})
    for _, entity in pairs(crushed_entities) do
        if (entity and entity.valid and entity.health and entity.health > 0) then
            entity.die()
        end
    end

    local pod_force = game.forces.player
    local repair = game.surfaces[1].create_entity{name="life-pod-repair", position=global.nextLifePod.arrivalPosition, force=pod_force}
    local radar = game.surfaces[1].create_entity{name="life-pod-radar", position=global.nextLifePod.arrivalPosition, force=pod_force }
    local beacon = game.surfaces[1].create_entity{name="life-pod-beacon", position=global.nextLifePod.arrivalPosition, force=pod_force }
    beacon.get_module_inventory(1).insert({name="speed-module-3", count=2})
    beacon.get_module_inventory(1).insert({name="efficiency-module-3", count=3})

    radar.destructible = false
    beacon.destructible = false
    local label_id = rendering.draw_text{
        text = "",
        surface = game.surfaces[1],
        target = repair,
        target_offset = {-0.5, 0.2},
        color = {r=0, g=1, b=0},
        scale = 1,
        alignment = "center"
    }
    local minimap_labels = {}
    for force_name, force in pairs(all_human_forces()) do
        minimap_labels[force_name] = force.add_chart_tag(game.surfaces[1],
            {
                position=global.nextLifePod.arrivalPosition,
                text = name,
                icon = {type="item", name="life-pod-icon"} -- consider global.nextLifePod.product instead?
            }
        )
    end
    repair.set_recipe(global.nextLifePod.recipe)

    local pod = {
        id = repair.unit_number, name=name, endgame_speedup = global.nextLifePod.endgame_speedup,
        repair = repair, radar = radar, label = label, beacon = beacon,
        alivePop = global.nextLifePod.alivePop, startingPop = global.nextLifePod.alivePop,
        recipe = global.nextLifePod.recipe, product = global.nextLifePod.product, minimap_labels = minimap_labels,
        consumption = global.nextLifePod.consumption, percent_stabilized = 0, stabilized = false,
        science_force = table.choice(all_human_forces()),
        label = label_id
    }

    global.lifePods[pod.id] = pod

    clearNextPodUI()
    clearMarkLocation()

    displayPodStats(pod)
    displayGlobalPop()
    prepareNextPod()
end

function getNextPodRecipe()
    local era = getTechEra(global.nextLifePod.arrivalTick)
    global.nextLifePod.product = getRandomLifePodRecipe(era)
    global.nextLifePod.era = era
    global.nextLifePod.recipe = game.forces.player.recipes[podRecipeNameFromItemName(global.nextLifePod.product, era)]
end
function getRandomLifePodRecipe(era)
    local product = global.lifepod_products[era][math.random(#global.lifepod_products[era])]
    if product == nil then
        debugPrint("Error selecting next pod item; trying again.", true)
        return getRandomLifePodRecipe(era)
    end
    local needed_hearts_per_sec = podHeartsConsumptionPerSec(global.nextLifePod)
    local recipe = game.forces.player.recipes[podRecipeNameFromItemName(product, era)]
    if recipe == nil then
        debugPrint("Error with next pod recipe for item " .. product .."; trying again.", true)
        return getRandomLifePodRecipe(era)
    end
    -- hearts per sec / hearts per object = objects per sec
    global.nextLifePod.items_per_sec = needed_hearts_per_sec / (recipe.products[1].amount/recipe.ingredients[1].amount)
    if global.nextLifePod.items_per_sec > CONFIG.MAX_ITEMS_PER_SECOND then
        debugPrint("Cannot demand item " .. product .. "; would require " .. global.nextLifePod.items_per_sec .. " per sec.", true)
        return getRandomLifePodRecipe(era)
    end
    return product
end

function prepareNextPod()
    nextLifePodTime()
    global.nextLifePod.consumption = heartsPerPop(effectiveTime(global.nextLifePod.arrivalTick))
    -- endgame_speedup gets applied to consumption, damage taken, and stabilization rate.
    global.nextLifePod.endgame_speedup = 1
    if global.mode == "rescue" and
            global.rescueTick and
            global.rescueTick - global.nextLifePod.arrivalTick < CONFIG.RESCUE_SPEEDUP_WARNING_TIME and
            global.rescueTick > global.nextLifePod.arrivalTick then
        global.nextLifePod.endgame_speedup = CONFIG.RESCUE_SPEEDUP_WARNING_TIME / (global.rescueTick - global.nextLifePod.arrivalTick)
    end
    global.nextLifePod.alivePop = CONFIG.POD_STARTING_POP


    findLifePodLandingSite()
    getNextPodRecipe()
    getNextPodName()




    global.nextLifePod.tracked = {time = false, location = false, recipe = false, consumption_rate = false, overflowing=false}
end
function findLifePodLandingSite()
    -- Only subtelty is to ensure that we don't land on a previous pod.
    -- Do this by moving in a constant directon until we find a valid spot.
    local candidate
    candidate = vector2Add(vector2Half(global.nextLifePod.arrivalPosition), nextVectorJump())
    local verified = false
    while (not verified) do
        local crushed_entities = game.surfaces[1].find_entities({vector2Add(candidate, {x=-5,y=-5}), vector2Add(candidate, {x=5,y=5})})
        verified = true
        for _, entity in pairs(crushed_entities) do
            if entity.name == "life-pod-repair" then
                candidate = vector2Add(candidate, {x=-5,y=-5})
                verified = false
            end
        end
    end
    global.nextLifePod.arrivalPosition = candidate
end
function nextLifePodTime()
    local nextTime = math.floor(global.nextLifePod.arrivalTick
            + (math.random(CONFIG.LIFE_POD_PERIOD_MIN, CONFIG.LIFE_POD_PERIOD_MAX) * global.difficulty.values.period_factor)
            + global.nextToNextLifePod.feedback_extra_time)
    --debugPrint("Next Pod arrives at: " .. formattimelong(nextTime) .. "; currently " .. formattimelong(game.tick))
    global.nextToNextLifePod.feedback_extra_time = 0
    if global.mode == "rescue" and global.rescueTick and global.rescueTick > nextTime then
        nextTime = math.min(nextTime, global.rescueTick - CONFIG.MIN_POD_TIME_BEFORE_RESCUE)
    end
    global.nextLifePod.arrivalTick = nextTime
    global.nextLifePod.warningTick = math.floor(global.nextLifePod.arrivalTick
            - global.nextToNextLifePod.radar_overflow * CONFIG.RADAR_OVERFLOW_FACTOR) -- Radar overflow is half effective.
    global.nextToNextLifePod.radar_overflow = 0
end

function nextVectorJump()
    local expectedDistance = lifePodDistance(effectiveTime(global.nextLifePod.arrivalTick))
    local distance = math.random(0.85 * expectedDistance, 1.15 * expectedDistance)
    local angle = math.random() * TWO_PI
    return {x=math.floor(distance * math.cos(angle)), y=math.floor(distance * math.sin(angle))}
end
function lifePodDistance(tick)
    return CONFIG.LIFE_POD_INITIAL_DISTANCE * math.power(CONFIG.LIFE_POD_DISTANCE_SCALE_PER_HOUR, math.min(tick, CONFIG.DISTANCE_MAX_TICK) / TICKS_PER_HOUR) / global.difficulty.values.distance_factor
end

function secondTickForPodUniversal(pod)
    pod.repair.set_recipe(pod.recipe)
    if pod.stabilized and pod.repair.health < CONFIG.POD_HEALTH_PER_POP * pod.alivePop then
        pod.repair.health = math.min(CONFIG.POD_HEALTH_PER_POP * pod.alivePop, pod.repair.health + CONFIG.POD_HEALTH_PER_SEC)
    end
    if math.random() < CONFIG.TECH_CHANCE_PER_SECOND * global.difficulty.values.tech_rate_factor then
        if (pod.repair.get_module_inventory().get_item_count("life-pods-science-module-1") > 0) then
            podScienceBoost(pod, 'blue')
        end
        if (pod.repair.get_module_inventory().get_item_count("life-pods-science-module-2") > 0) then
            podScienceBoost(pod, 'purple')
        end
        if (pod.repair.get_module_inventory().get_item_count("life-pods-science-module-2-y") > 0) then
            podScienceBoost(pod, 'yellow')
        end
        if (pod.repair.get_module_inventory().get_item_count("life-pods-science-module-3") > 0) then
            podScienceBoost(pod, 'purpleyellow')
        end
    end
end


function secondTickForPodActive(pod)
    if pod.alivePop <= 0 then return end
    displayPodStats(pod)
    pod.repair.bonus_progress = pod.percent_stabilized * 0.99 -- Make sure it's always well less than 1.
    local healSupply = pod.repair.fluidbox[1]
    if (pod.repair.health <= CONFIG.POD_HEALTH_PER_POP * (pod.alivePop - 1)) then
        damagePod(pod)
    end
    local total_consumption = podHeartsConsumptionPerSec(pod)
    if (healSupply and healSupply.amount) then
        -- Transfer min of amount available, amount to restore full health, and max restore rate
        -- max restore rate is 1 second per second if pod isn't overflowing, 2 otherwise.
        -- "A and B or C" is lua for "A ? B : C" (might do something odd if B or C is 0)
        local transferSecondsWorth = math.min(
            healSupply.amount / total_consumption,
            1 + (CONFIG.POD_HEALTH_PER_POP * pod.alivePop - pod.repair.health) / CONFIG.POD_HEALTH_PER_SEC,
            ((healSupply.amount / pod.repair.get_recipe().products[1].amount) < 2) and 1 or 2)

        local lostHearts = transferSecondsWorth * total_consumption
        local gainedHP = (transferSecondsWorth - 1) * CONFIG.POD_HEALTH_PER_SEC
        if (healSupply.amount < lostHearts) then
            debugError("Transfering more than total (" .. lostHearts .. " of " .. healSupply.amount .. ")")
            lostHearts = healSupply.amount
        end
        healSupply.amount = healSupply.amount - lostHearts
        if healSupply.amount == 0 then
            pod.repair.fluidbox[1] = nil
        else
            pod.repair.fluidbox[1] = healSupply
        end
        pod.repair.health = pod.repair.health + gainedHP
    else
        local damage = podDamagePerSec(pod)
        pod.repair.damage(damage, game.forces.neutral, "laser") -- Need to pick a damage type to make pods not immune to. "laser" shouldn't ever hit them naturally.
    end
end
function tenSecondTickForPod(pod)
    if pod.alivePop <= 0 then return end
    if not pod.repair.valid then
        debugPrint("Funny invalid pod state: " .. pod.name, true)
        return
    end
    -- Display floating time till damage
    local time = podSecsTillDeath(pod)
    game.surfaces[1].create_entity({
        name = "flying-text",
        position = vector2Add(
            pod.repair.position,
            {x=-1,y=-3}),
        text = formattimelong(time * TICKS_PER_SECOND)})

    -- Increase Total Repair Progress
    if (pod.repair.get_module_inventory().get_item_count() > 0) then
        local progress_increase = 10 * TICKS_PER_SECOND / CONFIG.POD_TICKS_TO_FULL_REPAIR * pod.endgame_speedup
        local module = pod.repair.get_module_inventory()[1]
        if module.health > progress_increase then
            module.health = module.health - progress_increase
        else
            -- Give the pod one final boost. This is to ensure that off-by-one-tick errors don't leave a pod 99.9%
            -- stable when the module expires.
            pod.percent_stabilized = pod.percent_stabilized + progress_increase
            module.clear()
        end
        pod.percent_stabilized = pod.percent_stabilized + progress_increase
        if pod.percent_stabilized >= 1 then
            -- Remove the module if it's almost used up. This is to ensure that off-by-one-tick errors don't leave with
            -- an extra 1% module you don't deserve.
            if module.valid_for_read and module.health < 0.01 then
                module.clear()
            end
            stabilizePod(pod)
        end
    end
end

function heartsPerPop(tick)
    return (CONFIG.HEARTS_PER_POP.base + (CONFIG.HEARTS_PER_POP.derivative * tick)) / global.difficulty.values.hearts_factor
end

function stabilizePod(pod)
    printAllPlayers({"lifepods.pod-stabilized", pod.name})
    pod.repair.active = false
    pod.stabilized = true
    pod.repair.set_recipe(nil)
    displayGlobalPop()
end

function damagePod(pod)
    if pod.alivePop <= 0 then return end
    printAllPlayers({"lifepods.pod-human-died", pod.name})
    pod.alivePop = pod.alivePop - 1
    displayPodStats(pod)
    displayGlobalPop()
    -- Negative Feedback
    global.nextToNextLifePod.feedback_extra_time = global.nextToNextLifePod.feedback_extra_time + CONFIG.dead_pop_feedback.next_pod_time
end

function rescueArrives()
    global.rescueArrived = true
    local summary = summarizePop()
    local alive = summary.active + summary.stable
    printAllPlayers({"lifepods.final-score", alive, alive + summary.dead})
    game.set_game_state{game_finished=true, player_won=true, can_continue=true}
end
function rescueSpeedupWarning()
    printAllPlayers({"lifepods.rescue-speedup-warning-1"})
    printAllPlayers({"lifepods.rescue-speedup-warning-2"})
end

function displayPodStats(pod)
    local color
    if (pod.alivePop == pod.startingPop or pod.stabilized) then
        color = {r=0, g=1, b=0 }
    elseif (pod.alivePop >= (pod.startingPop / 2)) then
        color = {r=1, g=0.7, b=0.2 }
    elseif (pod.alivePop > 0) then
        color = {r=1, g=0.3, b=0.3 }
    else
        color = {r=0.5, g=0.5, b=0.5 }
    end
    -- pod.label.destroy()
    -- pod.label = game.surfaces[1].create_entity({
    --     name = "life-pod-flying-text",
    --     position = vector2Add(
    --         pod.repair.position,
    --         {x=-1,y=-2}),
    --     text = pod.name.." ("..pod.alivePop .. "/" .. pod.startingPop..")",
    --     color = color})
    rendering.set_text(pod.label, pod.name.." ("..pod.alivePop .. "/" .. pod.startingPop..")")
    rendering.set_color(pod.label, color)
end

function podScienceBoost(pod, moduleLevel)
    local force = pod.science_force
    local tech
    if pod.current_tech_name and isBoostableTech(force.technologies[pod.current_tech_name], moduleLevel) then
        tech = force.technologies[pod.current_tech_name]
    else
        tech = findBoostableTech(moduleLevel, force)
    end
    if tech == nil then
        printAllPlayers({"lifepods.breakthrough-no-tech-available", pod.name}, force)
        pod.current_tech_name = nil
    else
        pod.current_tech_name = tech.name
        local boost_percent = CONFIG.TECH_PROGRESS_PER_BOOST / tech.research_unit_count
        if force.current_research and (force.current_research.name == tech.name) then
            printAllPlayers({"lifepods.breakthrough", pod.name, tech.localised_name}, force)
            force.research_progress = math.min(1.0, force.research_progress + boost_percent)
        else
            local existing_progress = force.get_saved_technology_progress(tech)
            local new_percent
            if existing_progress then
                new_percent = boost_percent + existing_progress
            else
                new_percent = boost_percent
            end
            if new_percent >= 1.0 then
                printAllPlayers({"lifepods.breakthrough-discovery", pod.name, tech.localised_name}, force)
                tech.researched = true
                pod.current_tech_name = nil
            else
                printAllPlayers({"lifepods.breakthrough", pod.name, tech.localised_name}, force)
                force.set_saved_technology_progress(tech, new_percent)
            end
        end

    end
end
function findBoostableTech(moduleLevel, force)
    -- Maybe copy an existing pod
    if math.random() < 0.5 then
        for i, pod in pairs(shuffle(global.lifePods)) do
            if pod.current_tech_name and isBoostableTech(force.technologies[pod.current_tech_name], moduleLevel) then
                return force.technologies[pod.current_tech_name]
            end
        end
    end
    -- If that didn't work, pick a tech at random.
    for _, tech in pairs(shuffle(force.technologies)) do
        if isBoostableTech(tech, moduleLevel) then
            return tech
        end
    end
    -- If that didn't work, then there's nothing available.
    return nil
end
boostableTechLevels = {
    -- Level 1
    blue={green=true, greenblack=true, blue=true},
    -- Level 2
    purple={blue=true, blueblack=true, purple=true},
    yellow={blue=true, blueblack=true, yellow=true},
    -- Level 3
    purpleyellow={purple=true, yellow=true, purpleyellow=true, white=true}
}
function isBoostableTech(the_tech, moduleLevel)
    -- Can't boost something we already know.
    if the_tech.researched then return false end
    -- Can't boost disabled techs.
    if not the_tech.enabled then return false end
    local level = getTechLevel(the_tech)
    -- Tech level has to match the module capabilities
    if not boostableTechLevels[moduleLevel][level] then return false end
    -- Make sure prereqs are done.
    for name, prereq in pairs(the_tech.prerequisites) do
        if not prereq.researched then return false end
    end
    -- Special compatibility hack for mod "teamwork".
    if string.match(the_tech.name, 'backfill') then return false end
    return true
end