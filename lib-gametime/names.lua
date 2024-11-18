require "lifepods-utils"

local ALL_NAMES = {
    --Book Characters
    "Wiggin",
    "Vorkosigan",
    "Dent",  --Hitchiker's Guide
    "Chanur",
    "Cameron",
    "Lambert",
    "Atreides",
    "Nuwen",
    "Arroway", -- Contact
    "Gobuchul", -- Culture Series I guess.
    "Watney", -- Martian
    "Creideiki", -- Uplift braindead guy
    "Perceval", -- Dust??
    "Calvin", -- I, Robot

    --Book Planets
    "Trantor",
    "Anarres", -- Le Guin something.

    --Movies/Show Characters
    "Skywalker",
    "Kirk",
    "Picard",
    "Reynolds",
    "Sheridan",
    "Roslin",
    "Cooper",

    --Movie/Show Planets
    "Gallifrey",

    -- Real People
    "Armstrong",
    "Aldrin",
    "Gagarin",

    -- Real Planets
    "Earth",
    "Mars",
    "Centauri",
}

local SUFFIXES = {"", " Jr", " III", " IV"}
local function suffixFromEpoch(epoch)
    if epoch <= #SUFFIXES then return SUFFIXES[epoch] end
    return " " .. epoch
end

function initNames()
    storage.podNames = shuffle(ALL_NAMES)
    storage.podEpoch = 1
end

function getNextPodName()
    storage.nextLifePod.name = storage.podNames[#storage.podNames] .. suffixFromEpoch(storage.podEpoch)
    storage.podNames[#storage.podNames] = nil
    if #storage.podNames == 0 then
        --debugPrint("Recycling names")
        storage.podNames = shuffle(ALL_NAMES)
        storage.podEpoch = storage.podEpoch + 1
    end
end

