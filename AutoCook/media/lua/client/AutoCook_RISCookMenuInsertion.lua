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
                local tooltipText

                tooltip:setName(recipe:getName())
                if baseItem:getTexture() and baseItem:getTexture():getName() ~= "Question_On" then
                    tooltip:setTexture(baseItem:getTexture():getName())
                end

                if AutoCook.AutoCraftIngredients then
                    itemCount = itemCount + #AutoCook:getPossibleCraftedFoodTypes(player, recipe, containerList)
                end

                -- if no source items available
                if itemCount == 0 then
                    -- add error tooltip
                    option.notAvailable = true
                    tooltipText = getText("ContextMenu_AutoCook_Tooltip_No_Mats")
                else
                    tooltipText = getText("ContextMenu_AutoCook_Tooltip", itemCount, fromName)
                    -- include info about current config?
                end
                tooltip.description = tooltipText
                option.toolTip = tooltip
            end  
        end
    end
end

Events.OnPreFillInventoryObjectContextMenu.Add(onAddAutoCookContextOption)