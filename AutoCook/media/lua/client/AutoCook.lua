require "ISContinue"

AutoCook = {}
AutoCook.Verbose = false
AutoCook.MaxSpices = -1
AutoCook.SmartSpices = true
AutoCook.SmartSpicesMaxWeight = 84
AutoCook.SmartSpicesMinWeight = 76
AutoCook.MaxDuplicate = 2
AutoCook.NutritionistMinWeight = 76.5
AutoCook.NutritionistMaxWeight = 82.5
AutoCook.ProteinTarget = 200 --very simplistic algo based on a single target is likely to not do the job
AutoCook.ProteinMax = 300
AutoCook.GainCalories = 1
AutoCook.GainCarbs = 3
AutoCook.GainLipids = 3
AutoCook.GainProtein = -2
AutoCook.GainHunger = 10
AutoCook.AvailableMinProteinItem = 3.001 --allows to continue overproteining slightly with vegetables when overproteined.
AutoCook.CookMode = 1 --1 = variety & freshness(default)/ 2=leftovers / 3=loose weight / 4=gain weight / 5=nutritionist(weight balance & strength optim)
AutoCook.UseRotten = true
AutoCook.AutoCraftIngredients = true
AutoCook.AutoCraftRecipes = {}
AutoCook.AutoCraftItemCache = {} --holds created items used for comparison
AutoCook.PrioritizeVariety = true

function AutoCook:init(player)
    if player == nil or player:getModData() == nil then
       return 
    end

    if player:getModData().AutoCook == nil then
        -- create new mod data
        if AutoCook.Verbose then print ("AutoCook:init: creating new modData") end
        player:getModData().AutoCook = {}
        if player:HasTrait("Nutritionist") or player:HasTrait("Nutritionist2") then
            AutoCook.CookMode = 5
        end
    else
        -- load mod data
        if AutoCook.Verbose then print ("AutoCook:init: loading modData") end
        for key, value in pairs(player:getModData().AutoCook) do
            if AutoCook.Verbose then print ("AutoCook:init: loading " .. tostring(key) .. " = " .. tostring(value)) end
            AutoCook[key] = value
        end
    end

    -- precache needed recipes
    AutoCook.initAutoCraftRecipes()
end

function AutoCook:stopAutoCook()
    if AutoCook.Verbose then print ("AutoCook:stopAutoCook") end
    if self.returnToContainer then
        --implement own returner with target container and error mngt
        self:returnItemsToOriginalContainer()
        --ISCraftingUI.ReturnItemsToOriginalContainer(self.playerObj, self.returnToContainer);--how the hell does he know where it comes from ?
        self.returnToContainer = {};
    end
end


function AutoCook:queueGetSourceitemsAction(player, recipe, containerList)
    local sourceItems = {}
    local items = RecipeManager.getAvailableItemsNeeded(recipe, player, containerList, nil, nil);

    if items:isEmpty() then return sourceItems end;
    for i=1,items:size() do
        local item = items:get(i-1)
        table.insert(sourceItems, item)
        if not recipe:isCanBeDoneFromFloor() then
            if item:getContainer() ~= player:getInventory() then
                if not instanceof(item, "Food") then
                    self:addToReturnContainer(item)
                end
                ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), player:getInventory(), nil));
            end
        end
    end
    return sourceItems
end

function AutoCook:getTypeTable(list) 
    local result= {}
    for i=1,list:size() do
        local item = list:get(i-1);
        result[item:getFullType()] = true
    end
    return result
end

function AutoCook:continue()--continue method is used by ISContinue
    if self.addAction and self.addAction.baseItem then
        self.baseItem = self.addAction.baseItem;--in cases base item changed during last add action
        if AutoCook.Verbose then print ("AutoCook:continue item switch to "..self.baseItem:getName()) end
    end

    local ingredients = self.baseItem:getExtraItems()
    local ingredientsCount = 0
    if ingredients then
        ingredientsCount = ingredients:size()
    end
    
    if AutoCook.Verbose then print ("AutoCook:continue on " .. self.baseItem:getName() .. " - ingredients: " .. ingredientsCount) end
    
    local containerList = ISInventoryPaneContextMenu.getContainers(self.playerObj);
    local items = self.recipe:getItemsCanBeUse(self.playerObj, self.baseItem, containerList);--use vanilla to get the list of potential food items

    -- if configured, add potientially valid ingredients we can craft
    if AutoCook.AutoCraftIngredients then
        -- exclude already available ingredients
        local availableItemTypes = AutoCook:getTypeTable(items)
        local potentialCraftedFoodTypes = AutoCook.getPossibleCraftedFoodTypes(self.playerObj, self.recipe, containerList, availableItemTypes);
        for _, potentialCraftedFoodType in pairs(potentialCraftedFoodTypes) do
            -- create comparable fake item from result type or use a precached one
            if not AutoCook.AutoCraftItemCache[potentialCraftedFoodType] then
                AutoCook.AutoCraftItemCache[potentialCraftedFoodType] = InventoryItemFactory.CreateItem(potentialCraftedFoodType)
            end
            local potentialIngredientItem = AutoCook.AutoCraftItemCache[potentialCraftedFoodType]
            -- dont add item if not spice and full or spice and already in or meal empty
            if not ((ingredientsCount == 0 or self:getNumberAlreadyUsed(potentialCraftedFoodType) > 0) and potentialIngredientItem:isSpice()
                or ingredientsCount == self.recipe:getMaxItems() and not potentialIngredientItem:isSpice()) then
                items:add(AutoCook.AutoCraftItemCache[potentialCraftedFoodType])
            end
        end
    end

    local usedItem = self:chooseItem(items,self.baseItem,self.recipe);--here is the automat food selection
    items:clear() -- assure release all references

    if not usedItem then--if there is no more available item stop auto cook
        self:stopAutoCook();
        return
    end

    --if item needs to be created, get necessary tools and craft it
    local isReal = (usedItem:getContainer() ~= nil or usedItem:getWorldItem() ~= nil)
    if AutoCook.Verbose then print ("AutoCook:chose item " .. usedItem:getType() .. " - isReal: " .. tostring(isReal)) end
    if not isReal then
        local cannedItemRecipe = AutoCook.AutoCraftRecipes[usedItem:getFullType()]
        -- transfer everything we need
        local sourceItems = self:queueGetSourceitemsAction(self.playerObj, cannedItemRecipe, containerList)
        -- craft the thing
        ISTimedActionQueue.add(ISCraftAction:new(self.playerObj, sourceItems[1], cannedItemRecipe:getTimeToMake(), cannedItemRecipe, self.playerObj:getInventory(), containerList));
    else
        --get source items
        if not self.playerObj:getInventory():contains(usedItem) then -- take the item if it's not in our inventory
            self:addToReturnContainer(usedItem);
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, usedItem, usedItem:getContainer(), self.playerObj:getInventory(), nil));
        end
        if not self.playerObj:getInventory():contains(self.baseItem) then -- take the base item if it's not in our inventory
            ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, self.baseItem, self.baseItem:getContainer(), self.playerObj:getInventory(), nil));
        end

        -- set item used
        self:setItemUsed(usedItem:getFullType());

        --add the timed action to cook the add chosenItem to baseItem in recipe.
        self.addAction = ISAddItemInRecipe:new(self.playerObj, self.recipe, self.baseItem, usedItem, (70 - self.playerObj:getPerkLevel(Perks.Cooking)))
        ISTimedActionQueue.add(self.addAction);
    end

    --add instant timed action to call autocook again once addItem is performed
    ISTimedActionQueue.add(ISContinue:new(self, self.playerObj, 1));
    
    if usedItem:isSpice() then
        self.nbSpices = self.nbSpices + 1
    end
end

function AutoCook:addToReturnContainer(item)
    if item then
        local toReturnStruct = {}
        toReturnStruct.usedItem = item;
        toReturnStruct.sourceContainer = item:getContainer();
        if AutoCook.Verbose then print ("AutoCook:addToReturnContainer "..item:getName().." "..tostring(item)) end
        table.insert(self.returnToContainer, toReturnStruct);
    end
end
function AutoCook:returnItemsToOriginalContainer()
    for _,toReturnStruct in pairs(self.returnToContainer) do
        if AutoCook.Verbose then print ("AutoCook:returnItemsToOriginalContainer "..tostring(toReturnStruct.usedItem and toReturnStruct.usedItem:getName() or "nil").." "..tostring(toReturnStruct.usedItem)) end
        if AutoCook.Verbose then print ("AutoCook:returnItemsToOriginalContainer "..tostring(toReturnStruct.sourceContainer and toReturnStruct.sourceContainer:getType() or "nil").." "..tostring(toReturnStruct.sourceContainer)) end
        if toReturnStruct.usedItem and toReturnStruct.sourceContainer and toReturnStruct.sourceContainer ~= self.playerObj:getInventory() and self.playerObj:getInventory():contains(toReturnStruct.usedItem) then
            local action = ISInventoryTransferAction:new(self.playerObj, toReturnStruct.usedItem, self.playerObj:getInventory(), toReturnStruct.sourceContainer, nil)
            ISTimedActionQueue.add(action)
        end
    end
end

function AutoCook:allowSpice()
    -- if SmartSpices enabled, use all spices on risk of underweight, none when risk of overweight, else as set
    if AutoCook.SmartSpices then
        local nutrition = self.playerObj:getNutrition();
        local playerWeight = nutrition:getWeight();
        if (playerWeight > AutoCook.SmartSpicesMaxWeight - 1 and nutrition:isIncWeight()) or playerWeight > AutoCook.SmartSpicesMaxWeight then
            -- player is tending to or is overweight
            return false
        elseif (playerWeight < AutoCook.SmartSpicesMinWeight + 1 and nutrition:isDecWeight()) or playerWeight < AutoCook.SmartSpicesMinWeight then
            -- player is tending to or is underweight
            return true
        end
    end
        
     --allow to select max spice number
    return (AutoCook.MaxSpices < 0 or self.nbSpices < AutoCook.MaxSpices)
end

function AutoCook:chooseItem(items, baseItem, recipe)
    if AutoCook.Verbose then print ("AutoCook:chooseItem for recipe ".. recipe:getOriginalname() .. " in " .. baseItem:getName()) end
    if not items or items:size() == 0 then--if there is no more available items stop auto cook
        return nil
    end

    
--take the one that will become rotten the fastest ?
--take the one that gives most nutrition ?
--take the one that gives most happiness ?
    local evoItem = nil
    local listsItems = {}--array of lists to differentiate depending on number of uses
    for i=1,items:size() do
        local item = items:get(i-1);
        if instanceof(item, "Food")--ensure we do not also apply survivor / carpentry / .. recipes ?
           and not self.playerObj:isKnownPoison(item)--if it is a poison and we know it: avoid
           and (recipe:isCookable() or not item:isbDangerousUncooked() or item:isCooked())--do not add dangerousuncook items on a recipe than cannot be cooked
           and (not item:isSpice() or self:allowSpice(item)) -- check if spice is allowed
           and (AutoCook.UseRotten or not item:isRotten()) then --only use rotten if enabled
            item = self:filterFood(item)
            if item then
                local itemType = item:getFullType()
                local numIter = self:getNumberAlreadyUsed(itemType)+1;
                while (not listsItems[numIter]) do
                    table.insert(listsItems, {});--prepare empty tables
                end
                
                table.insert(listsItems[numIter], item);--add element to correct table
            end
        end
    end
    
    --we switch ingredient as much as possible (higher priority than all other stuff)
    if AutoCook.PrioritizeVariety then
        for i=1,#listsItems do
            local chosenList = listsItems[i]
            if not evoItem and #chosenList > 0 and i <= AutoCook.MaxDuplicate then --loop for priority depending on already used item type
                local evoItemIter = 0
                for itemIter=1,#chosenList do
                    if not evoItem then
                        evoItem = chosenList[itemIter]
                        if evoItem then
                            evoItemIter = itemIter
                        else
                            evoItem = nil--reject food item
                        end
                    end
                end

                for itemIter=evoItemIter+1,#chosenList do
                    local item = chosenList[itemIter];
                    if item and evoItem then
                        evoItem = self:selectPreferedFood(evoItem,item);
                    elseif item then
                        evoItem = item;
                    end
                end
            end
        end
    else
        for i=1,#listsItems do
            if i <= AutoCook.MaxDuplicate then
                for key, item in pairs(listsItems[i]) do
                    if item and evoItem then
                        evoItem = self:selectPreferedFood(evoItem,item);
                    elseif item then
                        evoItem = item;
                    end
                end
            end
        end
    end
    
    return evoItem
end

function AutoCook:filterFood(item)
    local nutrition = self.playerObj:getNutrition();
    local playerWeight = nutrition:getWeight();
    
    if playerWeight > AutoCook.NutritionistMinWeight and AutoCook.CookMode == 5 then
        local refLipids = 0
        local refCarbs = 0
        if nutrition:getLipids() > 0 then refLipids = item:getLipids() end
        if nutrition:getCarbohydrates() > 0 then refCarbs = item:getCarbohydrates() end
        if refLipids + refCarbs > item:getProteins() then
            return nil--refuse items that have more lipids+carbs than proteins unless we are very low on lipids/carbs. this is VERY approximate.
        end
        
        local protein = nutrition:getProteins();
        if instanceof(self.baseItem, "Food") then
            protein = protein + self.baseItem:getProteins();
        end
        protein = protein + item:getProteins()
        if protein >= AutoCook.ProteinMax and item:getProteins() > AutoCook.AvailableMinProteinItem then--accept a bit of protein though because we have to eat anyway.
            return nil--avoid overprotein
        end
    end
    return item
end

function AutoCook:getNumberAlreadyUsed(itemType)
    for i=1,#self.usedItems do
        if self.usedItems[i].itemType == itemType then
            return self.usedItems[i].number;
        end
    end
    return 0
end

function AutoCook:setItemUsed(itemType)
    for i=1,#self.usedItems do
        if self.usedItems[i].itemType == itemType then
            self.usedItems[i].number = self.usedItems[i].number + 1;
            return
        end
    end
    local usedItemStruct = {}
    usedItemStruct.itemType = itemType
    usedItemStruct.number = 1
    table.insert(self.usedItems,usedItemStruct)
end

function AutoCook:new(playerObj, recipe, baseItem)
    if AutoCook.Verbose then print ("AutoCook:new "..recipe:getUntranslatedName()) end
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.playerObj = playerObj;
    o.recipe = recipe;
    o.baseItem = baseItem;
    o.addAction = nil;
    o.returnToContainer = {};
    
    o.usedItems = {};
    o.nbSpices = 0;
    
    return o;
end

-- load persisted values on reload script
if isDebugEnabled() then
    AutoCook:init(getPlayer())
end