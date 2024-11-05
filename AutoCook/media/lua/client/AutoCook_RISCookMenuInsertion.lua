require "AutoCook"

--we can do that but other mods will be broken.
if ActiveMods.getById("currentGame"):isModActive("AuthenticZStudderFix") then
    require('ISUI/InventoryPaneContextMenuFix')
end

local function onAddAutoCookContextOption(playerID, context, items)
    if #items < 1 then
        return
    end
    local baseItem = items[1]
    local player = getSpecificPlayer(playerID)
    
    if not baseItem then
        print("onAddAutoCookContextOption: item nil")
        return
    elseif not instanceof(baseItem, "InventoryItem") then
        baseItem = baseItem.items[1]
    end
    
    local containerList = ISInventoryPaneContextMenu.getContainers(player)
    local evorecipes = RecipeManager.getEvolvedRecipe(baseItem, player, containerList, false)
    -- check if item is a base item for a evo recipe
    if evorecipes then
        for i=0,evorecipes:size()-1 do
            local recipe = evorecipes:get(i)
            local fromName = getText("ContextMenu_EvolvedRecipe_" .. recipe:getUntranslatedName())
            -- if the item not a prepared meal already
            if not recipe:isResultItem(baseItem) then
                -- add the menu option
                local autoCook = AutoCook:new(player, recipe, baseItem);
                local option = context:addOption(getText("ContextMenu_AutoCook_From_Category", fromName), autoCook, AutoCook.continue)
                local items = recipe:getItemsCanBeUse(player, baseItem, containerList)
                local itemCount = 0
                if items then
                   itemCount = items:size() 
                end
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip:setName(recipe:getName())

                local resultItem = ScriptManager.instance:getItem(recipe:getFullResultItem())
                if resultItem and resultItem:getNormalTexture() and resultItem:getNormalTexture() ~= "Question_On" then
                    tooltip:setTexture(resultItem:getNormalTexture():getName())
                elseif baseItem:getTexture() and baseItem:getTexture():getName() ~= "Question_On" then
                    tooltip:setTexture(baseItem:getTexture():getName())
                end

                if AutoCook.AutoCraftIngredients then
                    local availableItemTypes = AutoCook:getTypeTable(items)
                    local possibleCraftedIngredients = AutoCook:getPossibleCraftedFoodTypes(player, recipe, containerList, availableItemTypes)
                    local possibleItems = #possibleCraftedIngredients

                    -- check if the only available items are crafted spices
                    if itemCount == 0 and possibleItems == 1 then
                        --local craftedIngredient = InventoryItemFactory.CreateItem(possibleCraftedIngredients[1]:getFullType())
                        --if resultItem:isSpice() or craftedIngredient:isSpice() then
                        -- script item doesnt support this and not worth creating item for this... just exclude gravy and wait for complaints
                        if possibleCraftedIngredients[1] == "Base.Gravy" then
                            possibleItems = 0
                        end
                    end
                    itemCount = itemCount + possibleItems
                end

                local tooltipText
                if itemCount > 0 then
                    tooltipText = getText("ContextMenu_AutoCook_Tooltip", itemCount, fromName)
                    -- include info about current config?
                else
                    -- if no source items available add error tooltip
                    option.notAvailable = true
                    tooltipText = getText("ContextMenu_AutoCook_Tooltip_No_Mats")
                end
                tooltip.description = tooltipText
                option.toolTip = tooltip
            end  
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(onAddAutoCookContextOption)