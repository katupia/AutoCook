

function AutoCook.initAutoCraftRecipes()
    if AutoCook.Verbose then print('initAutoCraftRecipes') end
    local allRecipes = getAllRecipes()
    local count = 0
    for i=0,allRecipes:size()-1 do
        local recipe = allRecipes:get(i);
        if not recipe:isHidden() and recipe:getCategory() == 'Cooking' then
            local sources = recipe:getSource()
            local someFoodSource = false
            --take only packaged food as source
            for sourceIt=0, sources:size()-1 do
                local source = sources:get(sourceIt)
                local items = source:getItems()
                for itemIt2=0, items:size()-1 do
                    local itemStr = items:get(itemIt2)
                    local item = getScriptManager():getItem(itemStr)
                    if item and item:getTypeString() == 'Food' and not item:isCantEat() then--no access to Item.Type.Food ?!
                        --if AutoCook.Verbose then print('initAutoCraftRecipes rejected: '..recipe:getName()..' for '..itemStr) end
                        someFoodSource = true
                        break
                    end
                end
                if someFoodSource then break end
            end
            --ensure unpack result is auto-edible
            local validResultItem = false
            local result = recipe:getResult()
            if result then
                local resultType = result:getFullType()
                local item = getScriptManager():getItem(resultType)
                validResultItem =  item and item:getTypeString() == 'Food' and item:getHungerChange() < 0 -- result should be food with beneficial effect on hunger
                if not validResultItem then
                    if AutoCook.Verbose then print('initAutoCraftRecipes rejected for not edible result: '..recipe:getName()..' for '..resultType) end
                end
            end
            -- if not AutoEat.predicateAutoEdibleFood(item) then reject recipe
            if validResultItem and not someFoodSource then--only try recipes that use no food item as source and give an edible result
                AutoCook.AutoCraftRecipes[result:getFullType()] = recipe
                count = count + 1
                if AutoCook.Verbose then print('initAutoCraftRecipes include: '..recipe:getName()) end
            end
        end
    end
    if AutoCook.Verbose then print('initAutoCraftRecipes loaded: '..count) end
end

function AutoCook.getPossibleCraftedFoodTypes(player, recipe, containers, exclude)
    if AutoCook.Verbose then print ("AutoCook.getPossibleCraftedFoodTypes") end
    local result = {}
    -- check all recipe items that end with "Open" and return all available in containers
    for i=0,recipe:getPossibleItems():size()-1 do
        local itemType = recipe:getPossibleItems():get(i):getFullType()
        -- skip if excluded
        if (not exclude or not exclude[itemType]) and AutoCook.AutoCraftRecipes[itemType] then
            -- if we have a recipe to retrieve the valid ingredient
            local openCanRecipe = AutoCook.AutoCraftRecipes[itemType]
            if openCanRecipe then
                if RecipeManager.IsRecipeValid(openCanRecipe, player, nil, containers) then
                    if AutoCook.Verbose then print ("AutoCook.getPossibleCraftedFoodTypes: found possible crafted food " .. itemType) end
                    table.insert(result, itemType)
                end
            end
        end
    end
    return result
end
