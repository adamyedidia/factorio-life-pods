TICKS = 1
TICKS_PER_SECOND = 60
SECONDS_PER_MINUTE = 60
MINUTES_PER_HOUR = 60
SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR
TICKS_PER_MINUTE = SECONDS_PER_MINUTE * TICKS_PER_SECOND
TICKS_PER_HOUR = MINUTES_PER_HOUR * TICKS_PER_MINUTE
TWO_PI = 6.28

local debug_factor = 1.0

CONFIG = {
    -- Multiplicative effect of each difficulty point.
    -- Takes effect whenever difficulty is set.
    difficulty = {
        period_factor = 0.9,
        hearts_factor = 0.9,
        distance_factor = 0.9,
        tech_rate_factor = 0.9,
    },


    difficulty_names = {Chieftain = "Chieftain", Beginner = "Beginner", Easy = "Easy", Relaxed = "Relaxed", Normal = "Normal", Hard = "Hard", Punishing = "Punishing", Insane = "Insane", DevOnlyUltraHard = "DevOnlyUltraHard"},
    difficulty_values = {Chieftain = -7, Beginner = -5, Easy = -3, Relaxed = -2, Normal = -1, Hard = 0, Punishing = 1, Insane = 3, DevOnlyUltraHard = 7},

    -- Negative Feedback: Each dead population increases tech time and time to next pod.
    dead_pop_feedback = {
        tech_times = 1 * TICKS_PER_MINUTE,
        next_pod_time = 1 * TICKS_PER_MINUTE,
    },

    levels = {
        "start",
        "red",
        "green",
        "greenblack",
        "blue",
        "blueblack",
        "purple",
        "yellow",
        "purpleyellow",
        "white",
        "latewhite",
        "innerplanetstech",
        "earlycryogenic",
        "cryogenic",
        "final",
    },
    level_icons = {
        start = {all = {}, next = "automation-science-pack"},
        red = {all = {"automation-science-pack"}, next = "logistic-science-pack"},
        green = {all = {"automation-science-pack", "logistic-science-pack"}, next = "military-science-pack"},
        greenblack = {all = {"automation-science-pack", "logistic-science-pack", "military-science-pack"}, next="chemical-science-pack"},
        blue = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack"}, next="military-science-pack"},
        blueblack = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack"}, next="PURPLE YELLOW FIRST"},
        purple = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack"}, next = "utility-science-pack"},
        yellow = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "utility-science-pack"}, next = "production-science-pack"},
        purpleyellow = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack"}, next = "space-science-pack"},
        white = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack"}, next="metallurgic-science-pack"},
        latewhite = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack"}, next="metallurgic-science-pack"},
        innerplanetstech = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack", "metallurgic-science-pack", "electromagnetic-science-pack", "agricultural-science-pack"}, next="cryogenic-science-pack"},
        earlycryogenic = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack", "metallurgic-science-pack", "electromagnetic-science-pack", "agricultural-science-pack", "cryogenic-science-pack"}, next="cryogenic-science-pack"},
        cryogenic = {all = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "military-science-pack", "production-science-pack", "utility-science-pack", "space-science-pack", "metallurgic-science-pack", "electromagnetic-science-pack", "agricultural-science-pack", "cryogenic-science-pack"}, next="FINAL"},
        final = {all="FINAL", next="NONE"}
    },
    -- Time at which pods start demanding items requiring each tech.
    -- Takes effect at game load, for pod after next.
    -- All scaled by difficulty.values.tech_rate_factor

    tech_times = {
        red = 1 * TICKS_PER_HOUR * debug_factor, -- Should be more than the first maximum period so the first thing is in start era.
        green = 2 * TICKS_PER_HOUR * debug_factor,
        greenblack = 5 * TICKS_PER_HOUR * debug_factor,
        blue = 8 * TICKS_PER_HOUR * debug_factor,
        blueblack = 11 * TICKS_PER_HOUR * debug_factor,
        purple_yellow_first = 15 * TICKS_PER_HOUR * debug_factor,
        purple_yellow_second = 16.5 * TICKS_PER_HOUR * debug_factor,
        purpleyellow = 18 * TICKS_PER_HOUR * debug_factor,
        white = 20 * TICKS_PER_HOUR * debug_factor,
        -- Life pods start landing on inner planets at 6 * TICKS_PER_HOUR after white era begins
        latewhite = 32 * TICKS_PER_HOUR * debug_factor,
        innerplanetstech = 42 * TICKS_PER_HOUR * debug_factor,
        earlycryogenic = 52 * TICKS_PER_HOUR * debug_factor,
        cryogenic = 58 * TICKS_PER_HOUR * debug_factor,
        final = 66 * TICKS_PER_HOUR * debug_factor,
    },

    -- First pod comes sooner by this factor.
    -- Takes effect at game start; cannot be changed mid-game.
    FIRST_POD_FACTOR = 0.4,

    -- Time between pods.
    -- Takes effect at game load, for pod after next.
    -- Both scaled by difficulty.values.period_factor
    LIFE_POD_PERIOD_MIN = 48 * TICKS_PER_MINUTE,
    LIFE_POD_PERIOD_MAX = 52 * TICKS_PER_MINUTE,


    -- Distance grows exponentially
    -- Actual distance is randomly between 0.75 and 1.25 times next expected distance.
    -- Takes effect at game load, for pod after next.
    -- Scaled by 1/difficulty.values.distance_factor
    LIFE_POD_INITIAL_DISTANCE = 30,
    LIFE_POD_DISTANCE_SCALE_PER_HOUR = 1.4,
    -- Exponential growth stops at this tick
    DISTANCE_MAX_TICK = 4 * TICKS_PER_HOUR, --30 * 1.4 ^ 9 = 115

    -- Conversion between various raw materials and hearts.
    -- Arbitary units, converted to Hearts according to following setting
    -- Takes effect when factorio is restarted.
    RAW_ITEM_VALUES = {
        ["copper-ore"] = 1.3,
        ["iron-ore"] = 1.8,
        ["coal"] = 0.7,
        ["stone"] = 0.7,
        ["crude-oil"] = 2,
        ["uranium-ore"] = 14,
        ["water"] = 0.05,
        ["wood"] = 50,
        ["raw-fish"] = 1000,
        ["calcite"] = 5,
        ["tungsten-ore"] = 25,
        ["scrap"] = 2.5,
        ["holmium-ore"] = 100,
        ["yumako"] = 50,
        ["jellynut"] = 50,
        ["spoilage"] = 5,
        ["biter-egg"] = 300,
        ["pentapod-egg"] = 300,
        ["lithium-brine"] = 20,
        ["fluorine"] = 70,
        ["ammoniacal-solution"] = 3,
        ["ice"] = 5,
        ["metallic-asteroid-chunk"] = 200,
        ["oxide-asteroid-chunk"] = 400,
        ["carbonic-asteroid-chunk"] = 300,
        ["promethium-asteroid-chunk"] = 100000,
    },

    -- Hearts per unit of conversion above.
    -- Takes effect when factorio is restarted.
    HEARTS_PER_UNIT = 1,
    -- Hearts given per second of machine time needed to make the demand item.
    -- Takes effect when factorio is restarted.
    HEARTS_PER_TIME = 0.3,
    -- Do not use recipes worth more than this much.
    -- at 20 hours, pods eat POD_STARTING_POP * (HEARTS_PER_POP.base + 30 * HEARTS_PER_POP.derivative) ~ 30 hearts/sec
    MAX_UNITS_PER_RECIPE = 8 * (SECONDS_PER_HOUR * 30),

    -- Seconds to process one hearts recipe. Make the recipes fast, so if you get the demand at the last minute it's ok.
    -- Takes effect when factorio is restarted.
    HEARTS_RECIPE_TIME = 2 / TICKS_PER_SECOND,
    -- Scale up recipes to this amount. Should be MIN_HEARTS_PER_RECIPE / HEARTS_RECIPE_TIME > POD_HEALTH_PER_SEC * HEARTS_PER_POP * POD_STARTING_POP
    -- Takes effect when factorio is restarted.
    MIN_HEARTS_PER_RECIPE = 40,
    MAX_ITEMS_PER_SECOND = 100,

    -- Hearts eaten per pop per second. Final consumption is (base + time * derivative)
    -- Takes effect at game load, for pod after next.
    -- Both scaled by 1/difficulty.values.hearts_factor
    HEARTS_PER_POP = {
        base = 0.3,
        derivative = 0.1/TICKS_PER_HOUR
    },

    -- Extra warning time per radar scan.
    -- Takes effect at game load instantly.
    RADAR_SCAN_TICKS = 7.5 * TICKS_PER_SECOND,
    -- Effect overflow factor for radar scans overflowing into the next warning.
    -- Takes effect at game load instantly.
    RADAR_OVERFLOW_FACTOR = 0.5,
    -- Takes effect at game load instantly.
    -- Warning shorter than this are not issued
    TOO_SHORT_WARNING = 5 * TICKS_PER_SECOND,

    -- Population of a new pod
    -- Takes effect at game load instantly.
    POD_STARTING_POP = 10,
    -- HP per pop
    -- Takes effect when factorio is restarted. Don't change this, then load a game without restarting factorio.
    POD_HEALTH_PER_POP = 1000,
    -- HP lost per second without supply.
    -- Takes effect at game load instantly.
    POD_HEALTH_PER_SEC = 2,

    CRYOSTASIS_HEALTH_PER_SEC_BONUS = {0.8, 0.6, 0.4},
    CONSUMPTION_MODULE_BONUS = {0.95, 0.9, 0.8},
    TECH_CHANCE_PER_SECOND = 2 / SECONDS_PER_HOUR,
    -- Measured in research units
    TECH_PROGRESS_PER_BOOST = 20,

    -- Time until a pod is fully repaired
    POD_TICKS_TO_FULL_REPAIR = 4 * TICKS_PER_HOUR,

    -- Time at which things start to speed up.
    -- All pods that land with less than this long till rescue are accelerated so that the time to rescue looks like
    -- this long. For example, if a pod lands 2 hrs before rescue, its consumption, damage, and stabilization rate
    -- are all multiplied by 5/2.
    RESCUE_SPEEDUP_WARNING_TIME = 5 * TICKS_PER_HOUR,
    MIN_POD_TIME_BEFORE_RESCUE = 10 * TICKS_PER_MINUTE,

    -- Constant for stupid hack; no gameplay effect.
    MACHINE_SIZE_ENCODING = 100,

    COLORS = {
        STABLE_POD = {r = 0, g = 1, b = 0, a = 1 },
        ACTIVE_POD = {r = 1, g = 1, b = 0, a = 1 },
        DEAD_POD = {r = 1, g = 0, b = 0, a = 1 }
    },

    --Deaths "allowed" (only effect is the UI)
    RESCUE_MAX_DEATHS_PER_HOUR = 5,
    ROCKET_MAX_DEATHS = 100,
}

-- "settings and" so this doesn't trigger at pre-data time, like in settings.lua itself.
if (settings and settings.startup["life-pods-debug"].value) then
    CONFIG.LIFE_POD_PERIOD_MIN = 15 * TICKS_PER_SECOND
    CONFIG.LIFE_POD_PERIOD_MAX = 16 * TICKS_PER_SECOND

    CONFIG.POD_HEALTH_PER_POP = 50

    CONFIG.TOO_SHORT_WARNING = 0.1 * TICKS_PER_SECOND

    CONFIG.dead_pop_feedback.next_pod_time = 1 * TICKS_PER_SECOND
    CONFIG.TECH_CHANCE_PER_SECOND = 0.2

    CONFIG.POD_TICKS_TO_FULL_REPAIR = 50 * TICKS_PER_SECOND
    CONFIG.RESCUE_SPEEDUP_WARNING_TIME = 59.7 * TICKS_PER_MINUTE
    CONFIG.tech_times = {
        red = 2.001 * TICKS_PER_SECOND, -- Should be more than the first maximum period so the first thing is in start era.
        green = 3 * TICKS_PER_SECOND,
        greenblack = 4 * TICKS_PER_SECOND,
        blue = 5 * TICKS_PER_SECOND,
        blueblack = 6 * TICKS_PER_SECOND,
        purple_yellow_first = 7 * TICKS_PER_SECOND,
        purple_yellow_second = 8 * TICKS_PER_SECOND,
        purpleyellow = 10 * TICKS_PER_SECOND,
        white = 15 * TICKS_PER_SECOND,
        latewhite = 20 * TICKS_PER_SECOND,
        innerplanetstech = 25 * TICKS_PER_SECOND,
        earlycryogenic = 27 * TICKS_PER_SECOND,
        cryogenic = 30 * TICKS_PER_SECOND,
        final = 35 * TICKS_PER_SECOND,
    }
    CONFIG.RESCUE_MAX_DEATHS_PER_HOUR = 100
end