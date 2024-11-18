require "lib-gametime.names"
require "lib-gametime.init"
require "lib-gametime.game-options"
require "lib-gametime.tech-level-gametime"
require "lifepods-utils"
require "table-supplement"

script.on_configuration_changed(function(data)
    if (data.mod_changes and data.mod_changes["life-pods"]) then
        if data.mod_changes["life-pods"].old_version == nil then
            for index, _ in pairs(game.players) do
                initPlayerGUI(index)
            end
        end
        if change_passes(data, "1.1.0") then
            printAllPlayers("Updating Life Pods to version " .. "1.1.0")
            for index, pod in pairs(storage.lifePods) do
                pod.consumption = pod.consumption / 10
            end
        end
        if change_passes(data, "1.1.1") then
            printAllPlayers("Updating Life Pods to version " .. "1.1.1")
            for _, player in pairs(game.players) do
                if player.gui.top.lifepods and player.gui.top.lifepods.population and player.gui.top.lifepods.population.popInFlightNumber then
                    player.gui.top.lifepods.population.popInFlightNumber.caption = ""
                    player.gui.top.lifepods.population.popInFlightText.caption = ""
                end
            end
        end
        if change_passes(data, "1.4.0") then
            printAllPlayers("Updating Life Pods to version " .. "1.4.0")
            initNames()
            storage.nextLifePod["name"] = "PLACEHOLDER"
            for _, pod in pairs(storage.lifePods) do
                getNextPodName()
                pod.name = storage.nextLifePod.name
                pod["tag"] = game.forces.player.add_chart_tag(game.surfaces[1],
                    {
                        position=pod.repair.position,
                        text = pod.name,
                        icon = {type="item", name="life-pod-icon"} -- consider storage.nextLifePod.product.name instead?
                    }
                )

            end
            getNextPodName()

            for ind, player in pairs(game.players) do
                player.gui.top.clear()
                initPlayerGUI(ind)
            end
        end
        if change_passes(data, "1.4.7") then
            printAllPlayers("Updating Life Pods to version " .. "1.4.7")
            storage.quickStartTimeBonus = 0
        end
        if change_passes(data, "1.5.0") then
            printAllPlayers("Updating Life Pods to version " .. "1.5.0")
            storage.podEpoch = 1
            for _, pod in pairs(storage.lifePods) do
                if not pod.endgame_speedup then pod.endgame_speedup = 1 end
                if not pod.percent_stabilized then pod.percent_stabilized = 0 end
            end
            if storage.nextLifePod.warningMinimapGhosts then
                for _, entity in pairs(storage.nextLifePod.warningMinimapGhosts) do
                    if entity.valid then entity.destroy() end
                end
            end
            local minimap_label = game.forces.player.add_chart_tag(game.surfaces[1],
                {
                    position=storage.nextLifePod.arrivalPosition,
                    text = storage.nextLifePod.nam,
                    icon = {type="item", name="life-pod-warning-icon"}
                }
            )
            storage.nextLifePod.warningMinimapGhosts = minimap_label
        end
        if change_passes(data, "1.5.7") then
            printAllPlayers("Updating Life Pods to version " .. "1.5.7")
            for _, pod in pairs(storage.lifePods) do
                if type(pod.product) == "table" then pod.product = pod.product.name end
                if pod.recipe and not pod.stabilized then
                    if pod.product == nil then error(table.tostring(pod)) end
                    local new_recipe_name = podRecipeNameFromItemName(pod.product, "final")
                    local hearts_box = pod.repair.fluidbox[1]
                    pod.repair.recipe = new_recipe_name
                    pod.recipe = pod.repair.recipe
                    pod.repair.fluidbox[1] = hearts_box
                end
            end
            for level, products in pairs(storage.lifepod_products) do
                for i, product_table in pairs(products) do
                    products[i] = product_table.name
                end
            end
        end
        if change_passes(data, "1.5.9") then
            printAllPlayers("Updating Life Pods to version " .. "1.5.11")
            if not storage.nextLifePod.recipe then
                storage.nextLifePod.recipe = game.forces.player.recipes[podRecipeNameFromItemName(storage.nextLifePod.product.name, getTechEra(storage.nextLifePod.arrivalTick))]
            end
            if not storage.nextLifePod.consumption then
                storage.nextLifePod.consumption = heartsPerPop(effectiveTime(storage.nextLifePod.arrivalTick))
                storage.nextLifePod.endgame_speedup = 1
                if storage.mode == "rescue" and storage.rescueTick and storage.rescueTick - storage.nextLifePod.arrivalTick < CONFIG.RESCUE_SPEEDUP_WARNING_TIME then
                    storage.nextLifePod.endgame_speedup = CONFIG.RESCUE_SPEEDUP_WARNING_TIME / (storage.rescueTick - storage.nextLifePod.arrivalTick)
                end
            end
            storage.nextLifePod.alivePop = CONFIG.POD_STARTING_POP
            if storage.nextLifePod.product.name then storage.nextLifePod.product = storage.nextLifePod.product.name end
        end
        if change_passes(data, "1.6.6") then
            printAllPlayers("Updating Life Pods to version " .. "1.6.6")
            for _, pod in pairs(storage.lifePods) do
                if pod.stabilized then
                    local new_recipe_name = podRecipeNameFromItemName(pod.product, "final")
                    pod.repair.recipe = new_recipe_name
                    pod.recipe = pod.repair.recipe
                    pod.repair.recipe = nil
                end
            end
        end
        if change_passes(data, "1.8.2") then
            printAllPlayers("Updating Life Pods to version " .. "1.8.2")
            for _, pod in pairs(storage.lifePods) do
                if pod.science_force == nil then
                    pod.science_force = table.choice(all_human_forces())
                end
                if pod.minimap_label then
                    pod.minimap_labels = {}
                    for force_name, force in pairs(all_human_forces()) do
                        pod.minimap_labels[force_name] = force.add_chart_tag(game.surfaces[1],
                            {
                                position=storage.nextLifePod.arrivalPosition,
                                text = pod.name,
                                icon = {type="item", name="life-pod-icon"} -- consider storage.nextLifePod.product instead?
                            }
                        )
                    end
                end
            end
            storage.nextLifePod.warningMinimapGhosts = {}
            for force_name, force in pairs(all_human_forces()) do
                storage.nextLifePod.warningMinimapGhosts[force_name] = force.add_chart_tag(game.surfaces[1],
                    {
                    position=storage.nextLifePod.arrivalPosition,
                    text = storage.nextLifePod.name  .. " INCOMING",
                    icon = {type="item", name="life-pod-warning-icon"}
                    }
                )
            end
        end
    end

end)
function change_passes(data, version)
    if data.mod_changes["life-pods"].old_version == nil then return true end
    return data.mod_changes["life-pods"].new_version >= version
           and
           data.mod_changes["life-pods"].old_version < version
end