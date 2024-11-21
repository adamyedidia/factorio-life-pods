--
-- For Stuff related to initializing players, games, etc.

require "lib-gametime.assemble-pod-epochs"
require "lib-gametime.game-options"
require "lib-gametime.names"
require "lib-gametime.quick-start"
require "config"

function initMod()

    game.planets.vulcanus.create_surface()
    game.planets.fulgora.create_surface()
    game.planets.gleba.create_surface()
    game.planets.aquilo.create_surface()

    game.surfaces[2].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[3].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[4].request_to_generate_chunks({x=0, y=0}, 12)
    game.surfaces[5].request_to_generate_chunks({x=0, y=0}, 12)

    storage.hasHadPromethiumPod = false

    if (storage.init == nil) then storage.init = false end -- Tells it to set up the first pod.

    if (storage.nextLifePod == nil) then
        storage.nextLifePod = {

            name = "",
            warningTick = 0,  -- Filled in at init
            arrivalTick = 0,  -- Filled in at init
            product = nil,
            tracked = {},
            arrivalPosition = {x = 0, y = 0}, -- Filled in at init
            planet = "nauvis", -- Filled in at init

            warningMinimapGhosts = {},
        }
    end

    if (storage.nextToNextLifePod == nil) then
        storage.nextToNextLifePod = {
            feedback_extra_time = 0,
            radar_overflow = 0,
        }
    end

    if (CONFIG.LIFE_POD_PERIOD_MIN >= CONFIG.LIFE_POD_PERIOD_MAX) then
        debugError("Config Error: LIFE_POD_PERIOD or WARNING_TIME interval is invalid")
    end

    if (storage.deadPodsPopulation == nil) then
        storage.deadPodsPopulation = 0
    end

    if (storage.lifePods == nil) then
        storage.lifePods = {}
    end

    storage.Xoffsets = {
        {x=3,y=-3},
        {x=-2,y=-3},

        {x=-1,y=-2},
        {x=-2,y=-2},
        {x=2,y=-2},
        {x=3,y=-2},

        {x=-1,y=-1},
        {x=0,y=-1},
        {x=1,y=-1},
        {x=2,y=-1},

        {x=0,y=0},
        {x=1,y=0},

        {x=-1,y=1},
        {x=0,y=1},
        {x=1,y=1},
        {x=2,y=1},

        {x=-1,y=2},
        {x=-2,y=2},
        {x=2,y=2},
        {x=3,y=2},

        {x=3,y=3},
        {x=-2,y=3},
    }
    storage.difficulty = {
        values = {
            period_factor = 1,
            hearts_factor = 1,
            distance_factor = 1,
            tech_rate_factor = 1,
        },
        overall = 1
    }
    storage.mode = nil

    if (storage.yellow_purple_order == nil) then
        if math.random() < 0.5 then
            storage.yellow_purple_order = {"purple", "yellow"}
        else
            storage.yellow_purple_order = {"yellow", "purple"}
        end
    end

    initGameOptions()
    initNames()
    initTechDictionary()
    initQuickStart()
end
script.on_init(initMod)

