data:extend({
    {
      effects = {
        {
          recipe = "life-pods-repair-module",
          type = "unlock-recipe"
        }
      },
      icon_size = 32,
      icon = "__life-pods__/graphics/lifepod-icon.png",
      name = "life-pods-repair-module",
      order = "a-a-a-a",
      prerequisites = {
        "circuit-network",
        "electric-energy-distribution-1"
      },
      type = "technology",
      unit = {
        count = 50,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
        },
        time = 10
      }
    },
    {
      effects = {
        {
          recipe = "life-pods-damage-reduction-module-1",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-consumption-module-1",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-science-module-1",
          type = "unlock-recipe"
        }
      },
      icon_size = 32,
      icon = "__life-pods__/graphics/lifepod-icon.png",
      name = "life-pods-enhanced-modules-1",
      order = "a-a-a-a",
      prerequisites = {
        "life-pods-repair-module",
        "modules"
      },
      type = "technology",
      unit = {
        count = 100,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
        },
        time = 30
      }
    },
  {
      effects = {
        {
          recipe = "life-pods-damage-reduction-module-2",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-consumption-module-2",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-science-module-2",
          type = "unlock-recipe"
        },
      },
      icon_size = 32,
      icon = "__life-pods__/graphics/lifepod-icon.png",
      name = "life-pods-enhanced-modules-2",
      order = "a-a-a-a",
      prerequisites = {
        "life-pods-enhanced-modules-1",
      },
      type = "technology",
      unit = {
        count = 150,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
          {
            "chemical-science-pack",
            1
          },
        },
        time = 30
      }
    },
  {
      effects = {
        {
          recipe = "life-pods-damage-reduction-module-3",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-consumption-module-3",
          type = "unlock-recipe"
        },
        {
          recipe = "life-pods-science-module-3",
          type = "unlock-recipe"
        },
      },
      icon_size = 32,
      icon = "__life-pods__/graphics/lifepod-icon.png",
      name = "life-pods-enhanced-modules-3",
      order = "a-a-a-a",
      prerequisites = {
        "life-pods-enhanced-modules-2",
        "modules"
      },
      type = "technology",
      unit = {
        count = 200,
        ingredients = {
          {
            "automation-science-pack",
            1
          },
          {
            "logistic-science-pack",
            1
          },
          {
            "chemical-science-pack",
            1
          },
          {
            "production-science-pack",
            1
          },
        },
        time = 60
      }
    },
  })