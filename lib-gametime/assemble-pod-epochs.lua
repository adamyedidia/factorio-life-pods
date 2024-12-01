require "lifepods-utils"
require "table-supplement"
require "config"

-- TODO make this read from CONFIG.levels
storage.lifepod_products = {start={}, red={}, green={}, greenblack={}, blue={}, blueblack={}, purple={}, yellow={}, purpleyellow={}, white={}, latewhite={}, innerplanetstech={}, earlycryogenic={}, cryogenic={}, final={} }

local function startsWith(String, prefix)
    return string.sub(String,1,string.len(prefix))==prefix
end

function initTechDictionary()
    storage.item_values = {}

    for name, recipe in pairs(game.forces.player.recipes) do
        --printAllPlayers(name .. ": " .. recipe.category)
        if startsWith(recipe.category, "life-pod-") then
            local lvl = lvlFromRecipeCategory(recipe.category)
            local itemname = itemLevelFromRecipeName(name).item
            if not startsWith(itemname, "life-pods") and itemname ~= "rocket-part" then  -- Exclude the stabilization modules and rocket parts
                if type(itemname) == "table" then error("Got table for 'itemname': " .. table.tostring(itemname)) end
                table.insert(storage.lifepod_products[lvl], itemname)

                local input_num = recipe.ingredients[1].amount
                storage.item_values[itemname] = recipe.products[1].amount/input_num
            end
        end
    end

    helpers.write_file("life-pods-products.log", "Life Pods Products List\n\n", false)
    for level, products in pairs(storage.lifepod_products) do
        helpers.write_file("life-pods-products.log", "Products at level " .. level .. ": " .. #products .. "\n", true)
        for i, itemname in pairs(products) do
            if type(itemname) == "table" then error("Got table for 'itemname': " .. table.tostring(itemname)) end

            local recipe = game.forces.player.recipes[podRecipeNameFromItemName(itemname, level)]
            local input_num = recipe.ingredients[1].amount
            local input = itemname
            helpers.write_file("life-pods-products.log", "  " .. i .. ". " .. input .. ": " .. (recipe.products[1].amount/input_num) .. "\n", true)
        end
    end
end

