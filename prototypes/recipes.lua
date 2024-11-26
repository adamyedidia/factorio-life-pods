data:extend({
    {
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "repair-pack",
                amount = 100
            },
            {
                type = "item",
                name = "copper-cable",
                amount = 100
            },
            {
                type = "item",
                name = "water-barrel",
                amount = 100
            },
            {
                type = "item",
                name = "medium-electric-pole",
                amount = 100
            },
            {
                type = "item",
                name = "raw-fish",
                amount = 10
            },
        },
        name = "life-pods-repair-module",
        results = {{type="item", name="life-pods-repair-module", amount=1}},
        type = "recipe",
    },
    {
        name = "life-pods-damage-reduction-module-1",
        results = {{type="item", name="life-pods-damage-reduction-module-1", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-repair-module",
                amount = 1
            },
            {
                type = "item",
                name = "raw-fish",
                amount = 10
            },
            {
                type = "item",
                name = "electronic-circuit",
                amount = 20
            }
        },
    },
    {
        name = "life-pods-damage-reduction-module-2",
        results = {{type="item", name="life-pods-damage-reduction-module-2", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-damage-reduction-module-1",
                amount = 1
            },
            {
                type = "item",
                name = "raw-fish",
                amount = 10
            },
            {
                type = "item",
                name = "advanced-circuit",
                amount = 20
            },
        },
    },
    {
        name = "life-pods-damage-reduction-module-3",
        results = {{type="item", name="life-pods-damage-reduction-module-3", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-damage-reduction-module-2",
                amount = 1
            },
            {
                type = "item",
                name = "raw-fish",
                amount = 10
            },
            {
                type = "item",
                name = "processing-unit",
                amount = 20
            },
        },
    },
    {
        name = "life-pods-consumption-module-1",
        results = {{type="item", name="life-pods-consumption-module-1", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-repair-module",
                amount = 1
            },
            {
                type = "item",
                name = "medium-electric-pole",
                amount = 40
            },
            {
                type = "item",
                name = "repair-pack",
                amount = 40
            },
        },
    },
    {
        name = "life-pods-consumption-module-2",
        results = {{type="item", name="life-pods-consumption-module-2", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-consumption-module-1",
                amount = 1
            },
            {
                type = "item",
                name = "medium-electric-pole",
                amount = 40
            },
            {
                type = "item",
                name = "repair-pack",
                amount = 40
            },
            {
                type = "item",
                name = "construction-robot",
                amount = 5
            },
        },
    },
    {
        name = "life-pods-consumption-module-3",
        results = {{type="item", name="life-pods-consumption-module-3", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-consumption-module-2",
                amount = 1
            },
            {
                type = "item",
                name = "medium-electric-pole",
                amount = 40
            },
            {
                type = "item",
                name = "repair-pack",
                amount = 40
            },
            {
                type = "item",
                name = "construction-robot",
                amount = 5
            },
            {
                type = "item",
                name = "efficiency-module-2",
                amount = 1
            }
        },
    },
    {
        name = "life-pods-science-module-1",
        results = {{type="item", name="life-pods-science-module-1", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-repair-module",
                amount = 1
            },
            {
                type = "item",
                name = "automation-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "logistic-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "chemical-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "military-science-pack",
                amount = 5
            },
        },
    },
    {
        name = "life-pods-science-module-2",
        results = {{type="item", name="life-pods-science-module-2", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-science-module-1",
                amount = 1
            },
            {
                type = "item",
                name = "automation-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "logistic-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "chemical-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "military-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "production-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "utility-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "space-science-pack",
                amount = 5
            },
        },
    },
    {
        name = "life-pods-science-module-3",
        results = {{type="item", name="life-pods-science-module-3", amount=1}},
        type = "recipe",
        enabled = false,
        energy_required = 10,
        ingredients = {
            {
                type = "item",
                name = "life-pods-science-module-2",
                amount = 1
            },
            {
                type = "item",
                name = "automation-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "logistic-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "chemical-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "military-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "production-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "utility-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "space-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "metallurgic-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "electromagnetic-science-pack",
                amount = 5
            },
            {
                type = "item",
                name = "agricultural-science-pack",
                amount = 5
            },
        },
    },
})