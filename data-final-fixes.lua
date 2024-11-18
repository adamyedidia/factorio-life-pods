require "lib-datatime.start-recipes"
require "lib-datatime.item-values-datatime"
require "lifepods-utils"
require "config"
require "table-supplement"

local all_techs = table.onelevelcopy(data.raw.technology)

local BASE_VALUES = {
    ["time"] = {resources = CONFIG.HEARTS_PER_TIME},
    ["raw-value"] = {resources = 1} }
addStartRecipes(all_techs)

--error("\nLevels: " .. table.tostring(CONFIG.levels) .. "\nBASE_VALUES: " .. table.tostring(BASE_VALUES) .. "\nall_techs: " .. table.tostring(table.mapField(all_techs, "name")))
local processor = itemValuesProcessor()
local all_values = processor.processAllTechs(all_techs, CONFIG.levels, BASE_VALUES)
--error(table.tostring(all_values))

function makePodRecipe(itemname, value, level)
    local hearts_per_input = value.resources * CONFIG.HEARTS_PER_UNIT
    local scale = math.ceil(CONFIG.MIN_HEARTS_PER_RECIPE / hearts_per_input)

    if (scale > 5) then
        scale = 10 * math.ceil(scale / 10)
    end
    local ingredients_list = {{type="item", name=itemname, amount=scale} }

    local name = podRecipeNameFromItemName(itemname, level)
    return {
             type = "recipe",
             name = name,
             enabled = "true",
             ingredients = ingredients_list,
             results =
             {
                 {type="fluid", name="pod-health", amount=5 * math.ceil(hearts_per_input * scale / 5)},
             },
             category = recipeCategoryFromLevel(level),
             energy_required = CONFIG.HEARTS_RECIPE_TIME,
             hidden = "true"
          }
end

-- Loop over all valid life pods products, and make a life pods item->hearts recipe.
for level, items in pairs(all_values) do
    for itemname, value in pairs(items) do
        -- Don't make recipes for dummy objects.
        if BASE_VALUES[itemname] == nil and isValidFinalItem(itemname) then
            local podRecipe = makePodRecipe(itemname, value, level)
            data:extend({podRecipe})
            table.insert(data.raw.module["life-pods-repair-module"].limitation, podRecipe.name)
        else
            --error("invalid item: " .. itemname)
        end
    end
end

-- Uncomment this to see values
-- error("Petroleum=" .. itemValues['petroleum-gas'].resources .. "; heavy-oil=" .. itemValues['heavy-oil'].resources .."; uranium-235=" .. itemValues['uranium-235'].resources .. "; uranium-238="..itemValues['uranium-238'].resources )

