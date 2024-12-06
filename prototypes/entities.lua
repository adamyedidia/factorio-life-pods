require "config"
require "lifepods-utils"

local life_pod_categories = {"life-pod-final"}
for _, name in pairs(CONFIG.levels) do
  table.insert(life_pod_categories, recipeCategoryFromLevel(name))
end

invisible =
    {
      filename = "__core__/graphics/empty.png",
      priority = "low",
      width = 1,
      height = 1,
      direction_count = 1,
      shift = {1.6, -1.1}
    }

invisible_pipe = {
      filename = "__core__/graphics/empty.png",
      priority = "low",
      width = 1,
      height = 1,
      frame_count=1,
}

invisible_animation =     {
      filename = "__core__/graphics/empty.png",
      width = 1,
      height = 1,
      line_length = 1,
      frame_count = 1,
      shift = {0,0},
      animation_speed = 1
    }


pipepictures = function()
  return {
    straight_vertical_single = invisible_pipe,
    straight_vertical = invisible_pipe,
    straight_vertical_window = invisible_pipe,
    straight_horizontal_window = invisible_pipe,
    straight_horizontal = invisible_pipe,
    corner_up_right = invisible_pipe,
    corner_up_left = invisible_pipe,
    corner_down_right = invisible_pipe,
    corner_down_left = invisible_pipe,
    t_up = invisible_pipe,
    t_down = invisible_pipe,
    t_right = invisible_pipe,
    t_left = invisible_pipe,
    cross = invisible_pipe,
    ending_up = invisible_pipe,
    ending_down = invisible_pipe,
    ending_right = invisible_pipe,
    ending_left = invisible_pipe,
    horizontal_window_background = invisible_pipe,
    vertical_window_background = invisible_pipe,
    fluid_background = invisible_pipe,
    low_temperature_flow = invisible_pipe,
    middle_temperature_flow = invisible_pipe,
    high_temperature_flow = invisible_pipe,
    gas_flow=invisible_pipe,
  }
end


pipecoverspictures = function()
  return {
    north =
    {
      filename = "__base__/graphics/entity/pipe-covers/pipe-cover-north.png",
      priority = "extra-high",
      width = 44,
      height = 32
    },
    east =
    {
      filename = "__base__/graphics/entity/pipe-covers/pipe-cover-east.png",
      priority = "extra-high",
      width = 32,
      height = 32
    },
    south =
    {
      filename = "__base__/graphics/entity/pipe-covers/pipe-cover-south.png",
      priority = "extra-high",
      width = 46,
      height = 52
    },
    west =
    {
      filename = "__base__/graphics/entity/pipe-covers/pipe-cover-west.png",
      priority = "extra-high",
      width = 32,
      height = 32
    }
  }
end

data:extend({
  -- Item Icon for Minimap
  {
    type = "item",
    name = "life-pod-icon",
    icon_size = 32,
    icon = "__life-pods__/graphics/lifepod-icon.png",
    hidden = true, --don't show in lists of all items.
    stack_size = 1,  --required but irrelevant.
  },
  -- Warning Icon for Minimap
  {
    type = "item",
    name = "life-pod-warning-icon",
    icon_size = 32,
    icon = "__life-pods__/graphics/warning.png",
    hidden = true, --don't show in lists of all items.
    stack_size = 1,  --required but irrelevant.
  },
  {
    type = "assembling-machine",
    name = "life-pod-repair",
    icon_size = 32,
    description = "life-pod-description",
    icon = "__life-pods__/graphics/lifepod-icon.png",
     -- Removing "player-creation" does not prevent biters from attacking.
    flags = {"player-creation", "not-repairable", "not-blueprintable", "not-deconstructable", "breaths-air"},
    map_color = {r = 1, g = 1, b = 1},
    max_health = CONFIG.POD_STARTING_POP * CONFIG.POD_HEALTH_PER_POP,
    corpse = "medium-remnants",
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    working_sound = { sound = { filename = "__base__/sound/furnace.ogg" } },
    resistances = {
      -- Large biters do 36 physical damage/sec; large spitters do 14 acid.
      -- Pods heal at 2 health per sec; each human has 1000 health (per CONFIG.POD_HEALTH_PER_POP)
      {
        -- It would take 100 large biters about 3 minutes to kill a human.
        percent = 99.8,
        type = "physical"
      },
      {
        -- It would take 100 large spitters about 3 minutes to kill a human.
        percent = 99.5,
        type = "acid"
      },
      {
        -- A grenade does 35 base damage; 1000 grenades @ 1/sec kills a human.
        percent = 90,
        type = "explosion"
      },
      {
        -- Flamethrower does about 1 dmg/sec base.
        percent = 50,
        type = "fire"
      },
      {
        -- Poison capsule does 160 base damage over 20 sec. 13 simultaneous capsules kill a human.
        percent = 50,
        type = "poison"
      },
    },
    collision_box = {{-1.2, -1.0}, {1.2, 1.0}},
    selection_box = {{-1.375, -1.4}, {1.375, 0.9}},
    crafting_categories = life_pod_categories,
    ingredient_count = 1,
    result_inventory_size = 1,
    energy_usage = "30kW",
    crafting_speed = 1,
    source_inventory_size = 1,
    energy_source = {type = "void",},
    fluid_boxes =
    {
      {
        production_type = "output",
        pipe_covers = pipecoverspictures(),
        base_level = -1,
        base_area = 600,
        volume = 600,
        pipe_connections = {},
      },
      {
        production_type = "input",
        pipe_covers = pipecoverspictures(),
        base_level = -1,
        volume = 600,
        pipe_connections = {},
      },
    },
    pipe_covers = pipecoverspictures(),
    pictures =
    {
      filename = "__life-pods__/graphics/lifepod.png",
      priority = "extra-high",
      width = 100,
      height = 100,
      frame_count = 1,
      shift = {0, 0}
    },
    working_visualisations = {},
    -- module_specification = {
    --   module_slots = 1
    -- },
    module_slots = 1,
    allowed_effects={"productivity"},
  },
  -- Invisible radar is to give vision of the area. Might be a better way.
  {
    type = "radar",
    name = "life-pod-radar",
    flags = {"not-repairable", "not-blueprintable", "not-deconstructable", "not-on-map"},
    max_health = 1,
    corpse = "big-remnants",
    resistances =
    {
      {
        type = "fire",
        percent = 70
      }
    },
    selection_box = nil,
    energy_per_sector = "1000MJ",  -- Technically this will do a scan every 27 hrs.
    max_distance_of_sector_revealed = 2,
    max_distance_of_nearby_sector_revealed = 0,
    energy_per_nearby_scan = "10kJ",
    energy_source = {type = "void",},
    energy_usage = "10kW",
    pictures =
    {
      filename = "__core__/graphics/empty.png",
      priority = "low",
      width = 1,
      height = 1,
      apply_projection = false,
      frame_count = 1,
      direction_count = 1,
      line_length = 1,
      shift = {0, 0}
    },
  },
  -- Text for label above pod.
  -- flying-text is now deprecated -adamy
  -- {
  --   type = "flying-text",
  --   name = "life-pod-flying-text",
  --   flags = {"not-on-map"},
  --   time_to_live = 1000000,
  --   speed = 0.00
  -- },
  -- Invisible beacon for projecting speed modules
  -- Removed life-pod-beacon for now because of this lua error:
  -- Failed to load mods: Error while loading entity prototype "life-pod-beacon" (beacon): Key "module_slots" not found in property tree at ROOT.beacon.life-pod-beacon
  -- {
  --   type = "beacon",
  --   name = "life-pod-beacon",
  --   flags = {"not-repairable", "not-blueprintable", "not-deconstructable"},
  --   max_health = 1,
  --   corpse = "big-remnants",
  --   selection_box = nil,
  --   allowed_effects = {"consumption", "speed", "pollution", "productivity"},
  --   base_picture = invisible,
  --   animation = invisible_animation,
  --   animation_shadow = invisible_animation,
  --   radius_visualisation_picture =
  --   {
  --     filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
  --     width = 10,
  --     height = 10,
  --   },
  --   supply_area_distance = 20,
  --   energy_source = {type = "void",},
  --   energy_usage = "10kW",
  --   distribution_effectivity = 1,
  --   module_specification =
  --   {
  --     module_slots = 5,
  --     module_info_icon_shift = {0, 0.5},
  --     module_info_multi_row_initial_height_modifier = -0.3
  --   }
  -- },
})