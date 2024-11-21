--
-- For general infra things not related to actual gameplay.

local setupCommands, setMode, setDifficulty, setRescue, setInfinityMode, tweakDifficulty

function initGameOptions()
    setupCommands()
    setMode()
    setDifficulty()
end

setupCommands = function()
    game.planets.vulcanus.create_surface()
    game.planets.fulgora.create_surface()
    game.planets.gleba.create_surface()
    game.planets.aquilo.create_surface()

    game.surfaces[2].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[3].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[4].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[5].request_to_generate_chunks({x=0, y=0}, 12)

    if remote.interfaces["lifepods settings"] then return end
    remote.add_interface("lifepods settings", {
        recalculate = setup,
        get = function ()
            printAllPlayers("Mode: " .. storage.mode)
            printAllPlayers("Difficulty: " .. storage.difficulty.overall)
            for name, value in pairs(storage.difficulty.values) do
                debugPrint(name .. ": " .. value)
            end
        end,
        tweak = function(name, value)
            tweakDifficulty(name, value)
        end
    })
end
script.on_load(function(event)
    setupCommands()
end)

setDifficulty = function()
    local difficulty_string = settings.global["life-pods-difficulty-choice"].value
    storage.difficulty.overall = CONFIG.difficulty_values[difficulty_string]
    if #game.connected_players > 1 and settings.global["life-pods-difficulty-scales-with-players"].value then
        storage.difficulty.overall = storage.difficulty.overall + #game.connected_players
    end
    printAllPlayers({"lifepods.setting-difficulty", storage.difficulty.overall})
    for name, _ in pairs(storage.difficulty.values) do
        storage.difficulty.values[name] = CONFIG.difficulty[name]^(storage.difficulty.overall)
    end

end
script.on_event(defines.events.on_player_joined_game, function(event) setDifficulty() end)
script.on_event(defines.events.on_player_left_game, function(event) setDifficulty() end)

local tweakDifficulty = function(type, value)
    storage.difficulty.values[type] = value
end

setMode = function()
    local setting = settings.global["life-pods-mode"].value
    printAllPlayers({"lifepods.setting-mode", settings.global["life-pods-mode"].value})
    if (setting == "rocket") then
        setRocketMode()  -- TODO: This doesn't need its own function anymore.
    elseif (setting == "infinity") then
        setInfinityMode()
    elseif (setting == "rescue") then
        setRescue(settings.global["life-pods-rescue-time"].value)
    end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if (event.setting == "life-pods-mode" or event.setting == "life-pods-rescue-time") then
        setMode()
    end
    if (event.setting == "life-pods-difficulty-choice" or event.setting == "life-pods-difficulty-scales-with-players") then
        setDifficulty()
    end
end)
setRescue = function(hours)
    storage.mode = "rescue"
    storage.rescueTick = hours * TICKS_PER_HOUR
    displayGlobalPop()
end
setRocketMode = function()
    storage.rescueTick = nil
    storage.mode = "rocket"
    for _, player in pairs(game.players) do
        if top_ui(player).rescue then
            top_ui(player).rescue.caption = ""
        end
    end
    displayGlobalPop()
end
setInfinityMode = function()
    storage.rescueTick = nil
    storage.mode = "infinity"
    for _, player in pairs(game.players) do
        if top_ui(player).rescue then
            top_ui(player).rescue.caption = ""
        end
    end
    displayGlobalPop()
end

