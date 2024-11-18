require "config"
require "lib-datatime.tech-level-datatime"
require "lib-datatime.global-lookup-datatime"
require "lib-interface.item-values-interface"

-- a Value is {resources = #}
-- (it used to have time and machine_size, but those were removed; time is handled as a regular resource.
local valuesImpl = {
    combineValues = function(values, amounts)
        local combined = {resources = 0}
        for name, amount in pairs(amounts) do
            if values[name] ==  nil then error("Invalid combine; missing key " .. name) end
            combined.resources = combined.resources + amount * values[name].resources
        end
        return combined
    end,
    splitValues = function(value, amounts)
        local result = {}
        for name, amount in pairs(amounts) do
            result[name] = {resources = value.resources / amount}
        end
        return result
    end,
    valueBetter = function(a, b)
        return a.resources <= b.resources
    end,
    maxValue = {resources = CONFIG.MAX_UNITS_PER_RECIPE},
}

local recipeImpl = {
    --Copied from https://forums.factorio.com/viewtopic.php?p=34789#p34789
     getIngredients = function(original_recipe)
       -- Some recipes have {expensive: {...}, normal: {...}} as two separate recipes, with the data inside.
       -- We just take the normal one for convenience
       local recipe = original_recipe
       if original_recipe.normal then
           recipe = original_recipe.normal
       end
       local ingredients = {}
       if recipe.ingredients == nil then
           return ingredients
       end
       for i,ingredient in pairs(recipe.ingredients) do
          if (ingredient.name and ingredient.amount) then
             ingredients[ingredient.name] = ingredient.amount
          elseif (ingredient[1] and ingredient[2]) then
             ingredients[ingredient[1]] = ingredient[2]
          end
       end
       ingredients["time"] = recipe.energy_required or 0
       return ingredients
    end,

    getProducts = function(original_recipe)
       -- Some recipes have {expensive: {...}, normal: {...}} as two separate recipes, with the data inside.
       -- We just take the normal one for convenience
       local recipe = original_recipe
       if original_recipe.normal then
           recipe = original_recipe.normal
       end
       local products = {}
       -- Some recipes have {results: {...}}, others have {result: name, result_count: num}
       if (recipe.results) then
           for _,product in pairs(recipe.results) do
               if (product.name and product.amount) then
                   products[product.name] = product.amount
                   if product.probability then
                       products[product.name] = products[product.name] * product.probability
                   end
               end
          end
       elseif (recipe.result) then
           local amount = 1
           if (recipe.result_count) then
               amount = recipe.result_count
           end
           products[recipe.result] = amount
       end
       return products
    end,
}
local techImpl = {
    getRecipes = function(tech)
        if tech.dummy_recipes then return tech.dummy_recipes end
        local result = {}
        if tech.effects == nil then return {} end
        for _, modifier in pairs(tech.effects) do
            if (modifier.type == "unlock-recipe") then
                local recipe = global_lookup_by_name.recipe(modifier.recipe)
                if recipe == nil then error("Can't find recipe: " .. table.tostring(modifier.recipe)) end
                if not recipe.hidden then
                    result[modifier.recipe] = recipe
                end
            end
        end
        return result
    end,

    getRawLevel = function(tech)
        if tech.dummy_tech_level then return tech.dummy_tech_level end
        return getTechLevel(tech)
    end,

    tweakLevel = function(level, tech, the_recipe)
        if ((level == "yellow") or (level == "purpleyellow") or (level == "final")  or (level == "white") or (level == "mystery")) then return level end
        local machine_size = table.count(recipeImpl.getIngredients(the_recipe)) - 1 -- -1 because of "time" ingredient
        if (level == "purple" or machine_size > 4.5) then return "purple" end -- Yellow factory
        if (level == "blueblack" or level == "blue" or level == "greenblack" or level == "green") then return level end
        if (level == "red" or machine_size > 2.5) then return "red" end -- Grey factory, Blue Factory or just red
        return "start"
    end
}

local FORBIDDEN_LISTS = {data.raw.fluid}
function isValidFinalItem(itemname)
    for name, list in pairs(FORBIDDEN_LISTS) do
        if list[itemname] then
            return false
        end
    end
    return true
end

function itemValuesProcessor()
    return itemValuesProcessorInterface(techImpl, recipeImpl, valuesImpl, isValidFinalItem, false, false, settings.startup["life-pods-mod-compatibility-mode"].value == "strict")
end




--------------------
---- Unit Tests ----
--------------------


-- TODO Make this a separate startup option
if settings.startup["life-pods-debug"].value and false then
    require "testing"
    local vals = {
        a = {resources=1},
        b = {resources=2},
        c = {resources=3}
    }

    local fix = fixture()
    test("values.combineValuesSimple", fix, function(asserts)
        local vals_a = {a={resources=1}}
        local amounts = {a=1}
        local combined = valuesImpl.combineValues(vals_a, amounts)
        -- error(table.tostring(combined))
        asserts.expectTableValuesEqual(combined, {resources=1})
    end)

    test("values.combineValues", fix, function(asserts)
        local amounts = {a=1, b=1, c=2}
        local combined = valuesImpl.combineValues(vals, amounts)
        -- error(table.tostring(combined))
        asserts.expectTableValuesEqual(combined, {resources=9})
    end)

    test("values.splitValues", fix, function(asserts)
        local v = {resources=6}
        local products = {a=2, b=3 }
        local split = valuesImpl.splitValues(v, products)
        -- error(table.tostring(split))
        asserts.expectTableValuesEqual(split,{
            a={resources=3},
            b={resources=2}
        })
    end)

    test("values.valueBetter", fix, function(asserts)
        asserts.expectTrue(valuesImpl.valueBetter(vals.a, vals.b))
        asserts.expectTrue(valuesImpl.valueBetter(vals.a, vals.a))
    end)

    test("recipe.getIngredients on real recipe (iron-plate)", fix, function(asserts)
        local the_recipe = global_lookup_by_name.recipe("iron-plate")
        local ingredients = recipeImpl.getIngredients(the_recipe)
        -- error(table.tostring(ingredients))
        asserts.expectTableValuesEqual(ingredients, {["iron-ore"]=1, time=3.5})
    end)

    test("recipe.getProducts on real recipe (iron-plate)", fix, function(asserts)
        local the_recipe = global_lookup_by_name.recipe("iron-plate")
        local products = recipeImpl.getProducts(the_recipe)
        -- error(table.tostring(products))
        asserts.expectTableValuesEqual(products, {["iron-plate"]=1})
    end)

    test("tech.getRecipes on real tech (optics)", fix, function(asserts)
        local the_tech = global_lookup_by_name.technology("optics")
        asserts.expectNotNil(the_tech)
        local recipes = techImpl.getRecipes(the_tech)
        -- error(table.tostring(recipes))
        asserts.expectNotNil(recipes["small-lamp"])
        asserts.expectEqual(recipes["small-lamp"].type, "recipe")
    end)

    local techs_to_test_levels = {["nuclear-power"]= "blueblack", ["logistics"]= "red", ["flamethrower"]= "greenblack", ["speed-module"]="greenblack", ["electric-engine"]="greenblack", ["plastics"]="green"}
    for tech_name, right_level in pairs(techs_to_test_levels) do
        test("tech.getRawLevel on real tech (" .. tech_name .. ")", fix, function(asserts)
            local the_tech = global_lookup_by_name.technology(tech_name)
            asserts.expectNotNil(the_tech)
            local level = techImpl.getRawLevel(the_tech)
            -- error(tech_name .. " (" .. level .."): " table.tostring(the_tech))
            asserts.expectEqual(level, right_level)
        end)
    end

    test("tech.tweakLevel on real item (oil-refinery)", fix, function(asserts)
        local the_tech = global_lookup_by_name.technology("oil-processing")
        asserts.expectNotNil(the_tech)
        local the_recipe = global_lookup_by_name.recipe("oil-refinery")
        local level = techImpl.getRawLevel(the_tech)
        asserts.expectEqual(level, "green")
        local tweaked = techImpl.tweakLevel(level, the_tech, the_recipe)
        -- error("Raw: " .. level .."; Tweaked: " .. tweaked .. "; tech: " .. table.tostring(the_tech))
        asserts.expectEqual(tweaked, "purple")
    end)

    fix.done(true)
end