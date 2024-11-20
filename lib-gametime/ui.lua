require "config"
require "lifepods-utils"
require "lib-gametime.population-monitor"
require "lib-gametime.tech-level-gametime"

local HAPPY_SPRITE = "virtual-signal/life-pod-alive"
local WORRIED_SPRITE = "virtual-signal/life-pod-injured"
local DEAD_SPRITE = "virtual-signal/life-pod-dead"

local POD_UI_WIDTH = 200

function top_ui(player)
    return player.gui.top.vertical_top
end

function initPlayerGUI(index)
    initTopDialog(game.players[index])
    debugPrint({"lifepods.debug-mode"})
end

function recipeQualityString(recipe_quality)
    if recipe_quality == "normal" then
        return ""
    else
        return recipe_quality .. " "
    end
end

-- Print our custom intro message after the normal cutscene intro.
script.on_event(defines.events.on_cutscene_waypoint_reached, function(event)
    if event.waypoint_index == 1 then
        if game.is_multiplayer() then
            game.players[event.player_index].print({"lifepods.starting-message-1"})
            game.players[event.player_index].print({"lifepods.starting-message-2"})
        else
            game.show_message_dialog{text = {"lifepods.starting-message-1"}}
            game.show_message_dialog{text = {"lifepods.starting-message-2"}}
        end

    end
end)
script.on_event(defines.events.on_player_created, function(event)
    initPlayerGUI(event.player_index)
    displayGlobalPop() -- This does it for everyone, but whatever.
    if storage.nextLifePod and storage.nextLifePod.tracked and storage.nextLifePod.tracked.recipe then
        updateRadarInfo()
    end
    if storage.mode == "rescue" and storage.rescueTick and storage.rescueTick - storage.nextLifePod.arrivalTick < CONFIG.RESCUE_SPEEDUP_WARNING_TIME then
        local player = game.players[event.player_index]
        player.print({"lifepods.rescue-speedup-at-start"})
    end
end)

function initTopDialog(player)
    local vertical_top = player.gui.top.add{type="flow", name="vertical_top", direction="vertical"}
    vertical_top.add{type="frame", name="lifepods"}
    vertical_top.lifepods.add{type="table", name="population", column_count="2" }
    vertical_top.lifepods.population.add{type="label", name="popActiveNumber", caption="0"}
    vertical_top.lifepods.population.add{type="label", name="popActiveText", caption={"lifepods.ui-in-danger"} }
    vertical_top.lifepods.population.add{type="label", name="popStableNumber", caption="0"}
    vertical_top.lifepods.population.add{type="label", name="popStableText", caption={"lifepods.ui-safe"} }
    vertical_top.lifepods.population.add{type="label", name="popDeadNumber", caption="0" }
    vertical_top.lifepods.population.add{type="label", name="popDeadText", caption={"lifepods.ui-dead"} }

    vertical_top.lifepods.population.popActiveNumber.style.font_color = CONFIG.COLORS.ACTIVE_POD
    vertical_top.lifepods.population.popActiveText.style.font_color = CONFIG.COLORS.ACTIVE_POD
    vertical_top.lifepods.population.popStableNumber.style.font_color = CONFIG.COLORS.STABLE_POD
    vertical_top.lifepods.population.popStableText.style.font_color = CONFIG.COLORS.STABLE_POD
    vertical_top.lifepods.population.popDeadNumber.style.font_color = CONFIG.COLORS.DEAD_POD
    vertical_top.lifepods.population.popDeadText.style.font_color = CONFIG.COLORS.DEAD_POD

    vertical_top.lifepods.add{type="flow", name="nextLifePod", direction="vertical" }
    vertical_top.lifepods.nextLifePod.add{type="label", name="recipe", caption=" " }
    vertical_top.lifepods.nextLifePod.add{type="label", name="podlocation", caption=" " }
    vertical_top.lifepods.nextLifePod.add{type="label", name="time", caption=" " }

    vertical_top.add{type="label", name="rescue" }
    vertical_top.add{type="flow", name="selectedpod" }
end
function updateRadarInfo()
    for _, player in pairs(game.players) do
        if storage.nextLifePod.tracked.recipe then
             top_ui(player).lifepods.nextLifePod.recipe.caption =
            {'lifepods.ui-pod-needs', storage.nextLifePod.name, prototypes.item[storage.nextLifePod.product].localised_name, recipeQualityString(storage.nextLifePod.recipe_quality), capitalize(storage.nextLifePod.planet)}
        end
        if storage.nextLifePod.tracked.location then
            top_ui(player).lifepods.nextLifePod.podlocation.caption = {'lifepods.ui-pod-location', storage.nextLifePod.name, capitalize(storage.nextLifePod.planet)}
        end
        if storage.nextLifePod.tracked.time then
            -- Time is updated every second in on_tick.
        end
        if storage.nextLifePod.tracked.consumption_rate then
            -- TODO dedupe this somehow
            local consumption_multiplier_as_a_function_of_quality = function(quality)
                if quality == "normal" then return 1.0 end
                if quality == "uncommon" then return 0.2 end
                if quality == "rare" then return 0.2 * 0.25 end
                if quality == "epic" then return 0.2 * 0.25 * 0.33 end
                return 0.2 * 0.25 * 0.33 * 0.5
            end

            local seconds_per_item = storage.nextLifePod.tracked.consumption_rate / consumption_multiplier_as_a_function_of_quality(storage.nextLifePod.recipe_quality)

            local localized_product = prototypes.item[storage.nextLifePod.product].localised_name
            local rate_string
            if seconds_per_item > 10 then
                rate_string = formattimelong(seconds_per_item * TICKS_PER_SECOND)
            elseif seconds_per_item > 0.5 then
                rate_string = (math.floor(seconds_per_item * 10) / 10) .. "s"
            else
                local num_per_sec = math.ceil(1 / seconds_per_item)
                rate_string = "x" .. num_per_sec .. "/s"
            end
            top_ui(player).lifepods.nextLifePod.recipe.caption =
            {'lifepods.ui-pod-needs-with-rate', storage.nextLifePod.name, prototypes.item[storage.nextLifePod.product].localised_name, rate_string, recipeQualityString(storage.nextLifePod.recipe_quality), capitalize(storage.nextLifePod.planet)}
        end
    end
end

local function podKey(pod)
    if not pod then
        debugPrint("Terrible problem - nil pod in podKey()", true)
        return "NIL POD"
    else
        return "pod"..pod.name..pod.id
    end
end
local function addPop(flow, sprite, health)
    flow.add{type="sprite", sprite=sprite }
    flow.add{type="progressbar", size=0.2, value=health }
    flow.style.maximal_width=32
end

local function updateModuleIcon(pod, ui)
    if ui.moduleicon then ui.moduleicon.destroy() end
    if ui.techicon then ui.techicon.destroy() end
    if ui.spacer then ui.spacer.destroy() end
    if pod.current_tech_name then
        ui.add{type="sprite-button", name="techicon", sprite="technology/"..pod.current_tech_name, style="slot_button" }
        ui.techicon.tooltip = prototypes.technology[pod.current_tech_name].localised_name
    else
        ui.add{type="flow", name="spacer" }
        ui.spacer.style.minimal_width = 38
        ui.spacer.style.maximal_width = 38
    end

    if pod.repair.get_module_inventory().get_item_count() > 0 then
        local module = pod.repair.get_module_inventory()[1]
        local sprite = ui.add{type="sprite", name="moduleicon", sprite="item/"..module.name }
        sprite.tooltip = module.prototype.localised_name
    end
end

local function updateUI(pod, gui)
    local rate = gui.firstrow.rate
    local seconds_per_input = podSecondsPerInput(pod)
    if seconds_per_input > 10 then
        rate.label.caption="= "..formattimelong(TICKS_PER_SECOND * seconds_per_input)
    elseif seconds_per_input > 1/2 then
        local formatted = math.floor(seconds_per_input * 10) / 10
        rate.label.caption="= "..formatted.."s"
    else
        local input_per_second = math.floor(1/seconds_per_input)
        rate.label.caption=" x"..input_per_second.." = 1s"
    end
    local individual_consumption_str = math.floor(podHeartsConsumptionPerPopPerSec(pod) * 100) / 100
    local tooltip = {"lifepods.ui-consumption-time", pod.alivePop, individual_consumption_str}
    rate.tooltip = tooltip
    rate.label.tooltip = tooltip
    rate.image.tooltip = tooltip

    updateModuleIcon(pod, gui.firstrow)

    for i=1,pod.startingPop do
        local flow = gui.pop.children[i]
        flow.clear()
        if pod.repair.health >= i * CONFIG.POD_HEALTH_PER_POP or (pod.alivePop >= i and pod.stabilized) then
            addPop(flow, HAPPY_SPRITE, 1)
        elseif pod.repair.health > (i - 1) * CONFIG.POD_HEALTH_PER_POP then
            addPop(flow, WORRIED_SPRITE, (pod.repair.health % CONFIG.POD_HEALTH_PER_POP) / CONFIG.POD_HEALTH_PER_POP)
        else
            addPop(flow, DEAD_SPRITE, 0)
        end
    end

    if pod.stabilized then
        gui.stabilization.value = 1
    else
        gui.stabilization.value = pod.percent_stabilized
    end
    local pod_stabilization_time = (1-pod.percent_stabilized) * CONFIG.POD_TICKS_TO_FULL_REPAIR / pod.endgame_speedup
    local module_inventory = pod.repair.get_module_inventory()
    -- Compare it to 1+epsilon because of how we give moduels one extra push in order to avoid off-by-one errors in control.lua
    local sufficient_module = pod.stabilized or (module_inventory.get_item_count() > 0 and pod.percent_stabilized + module_inventory[1].health > 1.0 - (10 * TICKS_PER_SECOND / CONFIG.POD_TICKS_TO_FULL_REPAIR * pod.endgame_speedup))
    local time = podSecsTillDeath(pod) * TICKS_PER_SECOND
    local safe = (time > pod_stabilization_time)
    if not sufficient_module then
        gui.stabilization.style.color={r = 1, g = 0, b = 0, a = 1 }
    elseif pod.stabilized or safe then
        gui.stabilization.style.color={r = 0, g = 1, b = 0, a = 1 }
    else
        gui.stabilization.style.color={r = 1, g = 0, b = 1, a = 1 }
    end

    local hearts = 0
    if pod.repair.fluidbox[1] and pod.repair.fluidbox[1].amount then
        hearts = pod.repair.fluidbox[1].amount
    end
    local hearts_caption = math.floor(hearts)
    if hearts_caption >= 10000 then
        hearts_caption = math.floor(hearts_caption / 1000) .. "k"
    end
    gui.ttl.hearts.label.amount.caption = hearts_caption
    if hearts > 0 then
        gui.ttl.hearts.label.time.caption = formattimelong(TICKS_PER_SECOND * hearts / podHeartsConsumptionPerSec(pod))
    else
        gui.ttl.hearts.label.time.caption = ""
    end

    local health = math.floor(pod.repair.health - CONFIG.POD_HEALTH_PER_POP * (pod.alivePop - 1))
    gui.ttl.hp.label.time.caption=formattimelong(TICKS_PER_SECOND * health / podDamagePerSec(pod))
    gui.ttl.hp.label.amount.caption=(health .."/"..CONFIG.POD_HEALTH_PER_POP)
    gui.ttl.hp.image.clear()
    if pod.repair.health % CONFIG.POD_HEALTH_PER_POP > 0 then
        gui.ttl.hp.image.add{type="sprite", sprite=WORRIED_SPRITE}
    else
        gui.ttl.hp.image.add{type="sprite", sprite=HAPPY_SPRITE}
    end
end

local function addGUITitleBar(pod, frame)
    frame.style.maximal_width = POD_UI_WIDTH
    frame.add{type="flow", name="top"}
    frame.top.add{type="label", name="title", caption=pod.name }
    frame.top.title.style.maximal_width = 100
    frame.top.title.style.minimal_width = 100
    frame.top.title.style.font_color = {r=0,g=1,b=0,a=1}
    frame.top.title.style.font = "default"
end
local function addGUIRateRow(pod, frame)
    local firstrow = frame.add{type="flow", name="firstrow" }
    firstrow.style.maximal_width = POD_UI_WIDTH
    firstrow.style.minimal_width = POD_UI_WIDTH

    local rate = firstrow.add{type="flow", name="rate" }
    rate.style.maximal_width = POD_UI_WIDTH - 110
    rate.style.minimal_width = POD_UI_WIDTH - 110
    rate.add{type="sprite", name="image", sprite="item/"..pod.product }
    rate.add{type="label", name="label", caption=""}
end
local function addToGUI(pod, gui)
    local frame = gui.add{type="frame", name=podKey(pod), direction="vertical"}
    addGUITitleBar(pod, frame)
    addGUIRateRow(pod, frame)



    frame.add{type="table", name="pop", column_count=5 }
    for i=1,pod.startingPop do
        local flow = frame.pop.add{type="flow", name=i, direction="vertical"}
    end
    frame.add{type="progressbar", name="stabilization", size=1 }


    local ttl = frame.add{type="flow", name="ttl" }
    local hearts_section = ttl.add{type="flow", name="hearts" }
    hearts_section.style.maximal_width = 70
    hearts_section.style.minimal_width = 70
    local hearts_text = hearts_section.add{type="flow", name="label", direction="vertical" }
    local text = hearts_text.add{type="label", name="amount",caption="" }
    text.style.maximal_height=20
    hearts_text.add{type="label", name="time", caption="" }
    hearts_section.add{type="sprite", sprite="fluid/pod-health" }

    local hp_section = ttl.add{type="flow", name="hp" }
    hp_section.style.maximal_width = 130
    hp_section.style.minimal_width = 130
    hp_section.add{type="flow", name="image"}
    local health_text = hp_section.add{type="table", name="label", column_count=1 }
    text = health_text.add{type="label", name="amount", caption=""}
    text.style.maximal_height=18
    health_text.style.vertical_spacing=-2
    health_text.add{type="label", name="time", caption="" }
    updateUI(pod, frame)
end

local function updateUIStabilized(pod, gui)
    updateModuleIcon(pod, gui.firstrow)
end
local function addToGUIStabilized(pod, gui)
    local frame = gui.add{type="frame", name=podKey(pod), direction="vertical"}
    addGUITitleBar(pod, frame)

    frame.top.add{type="flow", name="spacer" }
    frame.top.spacer.style.maximal_width = 80
    frame.top.spacer.style.minimal_width = 80
    local pop = frame.top.add{type="label", name="pop", caption = pod.alivePop .. "/" .. pod.startingPop }
    pop.style.maximal_width = 50
    pop.style.minimal_width = 50
    if pod.alivePop == pod.startingPop then
        pop.style.font_color = {r=0,g=1,b=0,a=1 }
    else
        pop.style.font_color = {r=1,g=0.5,b=0,a=1 }
    end

    addGUIRateRow(pod, frame)

    updateUIStabilized(pod, frame)
end
function removePodFromUI(pod)
    for _, player in pairs(game.players) do
        if player.gui.center.humaninterface then
            if pod.stabilized then
                player.gui.center.humaninterface.main.stable.table[podKey(pod)].destroy()
            else
                player.gui.center.humaninterface.main.active.table[podKey(pod)].destroy()
            end
        end
    end

end

function updateHumanInterface(player)
    local actives = player.gui.center.humaninterface.main.active.table
    local stables = player.gui.center.humaninterface.main.stable.table
    for _, pod in pairs(storage.lifePods) do
        if pod.stabilized and stables[podKey(pod)] then
            -- Pod is still stable; update it.
            updateUIStabilized(pod, stables[podKey(pod)])
        elseif pod.stabilized then
            -- Pod has stabilized; remove it from the active list and add it to the stable list.
            if actives[podKey(pod)] then actives[podKey(pod)].destroy() end
            addToGUIStabilized(pod, stables)
            -- Also make sure the window is in wide mode since now there are stable pods.
            player.gui.center.humaninterface.titlebar.spacer.style.maximal_width = 464
            player.gui.center.humaninterface.titlebar.spacer.style.minimal_width = 464
        elseif not pod.stabilized and not actives[podKey(pod)] then
            -- Pod has just landed. Add it.
            addToGUI(pod, actives)
        else
            -- Pod is still active
            updateUI(pod, actives[podKey(pod)])
        end
    end
end

function displayHumanInterface(player)
    player.gui.center.add{type="frame", name="humaninterface", direction="vertical" }
    local titlebar = player.gui.center.humaninterface.add{type="flow", direction="horizontal", name="titlebar"}
    titlebar.add{type="label", name="title", caption={"lifepods.ui-title"} }
    titlebar.title.style.font = "default-large-bold"
    titlebar.add{type="flow", name="spacer" }
    titlebar.spacer.style.maximal_width = 266
    titlebar.spacer.style.minimal_width = 266
    local level_beakers = titlebar.add{type="flow", direction="horizontal", name="level_beakers" }
    level_beakers.style.maximal_width = 400
    level_beakers.style.minimal_width = 400
    local era, remaining_time = getTechEra(game.tick)
    if CONFIG.level_icons[era].all == "FINAL" then
        level_beakers.add{type="label", caption={"lifepods.ui-level-final"}}
    else
        if table.isEmpty(CONFIG.level_icons[era].all) then
            level_beakers.add{type="label", caption={"lifepods.ui-level-start"}}
        end
        for _, beaker in ipairs(CONFIG.level_icons[era].all) do
            level_beakers.add{type="sprite", sprite="item/"..beaker }
        end
    end
    if CONFIG.level_icons[era].next == "FINAL" then
        level_beakers.add{type="label", caption={"", "(", {"lifepods.ui-level-final"}, " ", {"lifepods.ui-level-time", math.ceil(remaining_time / TICKS_PER_HOUR)}}}
    elseif CONFIG.level_icons[era].next ~= "NONE" then
        local next_icon = CONFIG.level_icons[era].next
        if CONFIG.level_icons[era].next == "PURPLE YELLOW FIRST" then
            if storage.yellow_purple_order[1] == 'purple' then
                next_icon = 'production-science-pack'
            else
                next_icon = 'utility-science-pack'
            end
        end
        level_beakers.add{type="label", caption="(+"}
        level_beakers.add{type="sprite", sprite="item/".. next_icon}
        level_beakers.add{type="label", caption={"lifepods.ui-level-time", math.ceil(remaining_time / TICKS_PER_HOUR)}}
    end
    titlebar.add{type="button", name="close-humaninterface", caption="x" }
    local main = player.gui.center.humaninterface.add{type="flow", direction="horizontal", name="main"}
    local stablescrollpane = main.add{type="scroll-pane", name="stable", direction="horizontal"}
    stablescrollpane.add{type="flow", name="table", direction="vertical" }
    local activescrollpane = main.add{type="scroll-pane", name="active", direction="horizontal"}
    activescrollpane.add{type="table", name="table", column_count=4 }
    activescrollpane.style.maximal_height=250
    stablescrollpane.style.maximal_height=250
    for _, pod in pairs(storage.lifePods) do
        if pod.stabilized then
            -- Add more space.
            titlebar.spacer.style.maximal_width = 464
            titlebar.spacer.style.minimal_width = 464
            addToGUIStabilized(pod, stablescrollpane.table)
        else
            addToGUI(pod, activescrollpane.table)
        end
    end
end


script.on_event("human-interface", function(event)
    local player = game.players[event.player_index]
    if player.gui.center.humaninterface then
        player.gui.center.humaninterface.destroy()
        return
    end
    displayHumanInterface(player)
end)

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "close-humaninterface" then
        game.players[event.player_index].gui.center.humaninterface.destroy()
    end
end)

function displaySinglePodMouseover(player)
    top_ui(player).selectedpod.clear()
    if player.selected and storage.lifePods[player.selected.unit_number] then
        addToGUI(
            storage.lifePods[player.selected.unit_number],
            top_ui(player).selectedpod
        )
    else
        debugPrint("Mousing over invalid lifepod!")
    end
end
script.on_event(defines.events.on_selected_entity_changed, function(event)
    if event.player_index and game.players[event.player_index] and game.players[event.player_index].selected
        and game.players[event.player_index].selected.name == "life-pod-repair" then
        displaySinglePodMouseover(game.players[event.player_index])
    end

    if event.last_entity and event.last_entity.name == "life-pod-repair" then
        top_ui(game.players[event.player_index]).selectedpod.clear()
    end
end)

