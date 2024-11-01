require "AutoCook"

--hook the ISInventoryPaneContextMenu.doEvorecipeMenu to install our button
local genuine_ISInventoryPaneContextMenu_doEvorecipeMenu = ISInventoryPaneContextMenu.doEvorecipeMenu
function ISInventoryPaneContextMenu.doEvorecipeMenu(context, items, player, evorecipe, baseItem, containerList)
    genuine_ISInventoryPaneContextMenu_doEvorecipeMenu(context, items, player, evorecipe, baseItem, containerList);

    local playerObj = getSpecificPlayer(player)
    for i=0,evorecipe:size()-1 do
        local recipe = evorecipe:get(i);
        local items = recipe:getItemsCanBeUse(playerObj, baseItem, containerList);
        if not items or items:size() == 0 then break; end
        
        local fromName = getText("ContextMenu_EvolvedRecipe_" .. recipe:getUntranslatedName())
        if not recipe:isResultItem(baseItem) then
            local autoCook = AutoCook:new(playerObj, recipe, baseItem);
            context:addOption(getText("ContextMenu_AutoCook_From_Category", fromName), autoCook, AutoCook.continue);
        end
    end
end

