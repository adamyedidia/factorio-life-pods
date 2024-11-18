require "lifepods-utils"
require "table-supplement"
require "config"

-- TODO make this read from CONFIG.levels
storage.lifepod_products = {start={}, red={}, green={}, greenblack={}, blue={}, blueblack={}, purple={}, yellow={}, purpleyellow={}, final={}, white={}, mystery={} }

local function startsWith(String, prefix)
    return string.sub(String,1,string.len(prefix))==prefix
end

function initTechDictionary()
    for name, recipe in pairs(game.forces.player.recipes) do
        --printAllPlayers(name .. ": " .. recipe.category)
        if startsWith(recipe.category, "life-pod-") then
            local lvl = lvlFromRecipeCategory(recipe.category)
            local itemname = itemLevelFromRecipeName(name).item
            if type(itemname) == "table" then error("Got table for 'itemname': " .. table.tostring(itemname)) end
            table.insert(storage.lifepod_products[lvl], itemname)
        end
    end

    game.write_file("life-pods-products.log", "Life Pods Products List\n\n", false)
    for level, products in pairs(storage.lifepod_products) do
        game.write_file("life-pods-products.log", "Products at level " .. level .. ": " .. #products .. "\n", true)
        for i, itemname in pairs(products) do
            if type(itemname) == "table" then error("Got table for 'itemname': " .. table.tostring(itemname)) end

            local recipe = game.forces.player.recipes[podRecipeNameFromItemName(itemname, level)]
            local input_num = recipe.ingredients[1].amount
            local input = itemname
            game.write_file("life-pods-products.log", "  " .. i .. ". " .. input .. ": " .. (recipe.products[1].amount/input_num) .. "\n", true)
        end
    end
end

