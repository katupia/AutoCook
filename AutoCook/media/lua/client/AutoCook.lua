require "ISContinue"

AutoCook = {}
AutoCook.Verbose = false
AutoCook.MaxSpices = -1
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
AutoCook.CookMode = 0--0 = variety & freshness(default)/ 1=loose weight / 2=gain weight / 3=nutritionnist(weight balance & strength optim)

function AutoCook:stopAutoCook()
    if AutoCook.Verbose then print ("AutoCook:stopAutoCook") end
    if self.returnToContainer then
        --implement own returner with target container and error mngt
        self:returnItemsToOriginalContainer()
        --ISCraftingUI.ReturnItemsToOriginalContainer(self.playerObj, self.returnToContainer);--how the hell does he know where it comes from ?
        self.returnToContainer = {};
    end
end

function AutoCook:continue()--continue method is used by ISContinue
    if AutoCook.Verbose then print ("AutoCook:continue") end
    if self.addAction and self.addAction.baseItem then
        self.baseItem = self.addAction.baseItem;--in cases base item changed during last add action
        if AutoCook.Verbose then print ("AutoCook:continue item switch to "..self.baseItem:getName()) end
    end
    
    local containerList = ISInventoryPaneContextMenu.getContainers(self.playerObj);
    local items = self.recipe:getItemsCanBeUse(self.playerObj, self.baseItem, containerList);--use vanilla to get the list of potential food items

    local usedItem = self:chooseItem(items,self.baseItem,self.recipe);--here is the automat food selection

    if not usedItem then--if there is no more available item stop auto cook
        self:stopAutoCook();
        return
    end
    
    --get source items
    if not self.playerObj:getInventory():contains(usedItem) then -- take the item if it's not in our inventory
        self:addToReturnContainer(usedItem);
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, usedItem, usedItem:getContainer(), self.playerObj:getInventory(), nil));
    end
    if not self.playerObj:getInventory():contains(self.baseItem) then -- take the base item if it's not in our inventory
        ISTimedActionQueue.add(ISInventoryTransferAction:new(self.playerObj, self.baseItem, self.baseItem:getContainer(), self.playerObj:getInventory(), nil));
    end
    
    --add the timed action to cook the add chosenItem to baseItem in recipe.
    self.addAction = ISAddItemInRecipe:new(self.playerObj, self.recipe, self.baseItem, usedItem, (70 - self.playerObj:getPerkLevel(Perks.Cooking)))
    ISTimedActionQueue.add(self.addAction);

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
function AutoCook:chooseItem(items, baseItem, recipe)
    if AutoCook.Verbose then print ("AutoCook:chooseItem "..baseItem:getName()) end
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
           and (AutoCook.MaxSpices < 0 or not item:isSpice() or self.nbSpices < AutoCook.MaxSpices) then--allow to select max spice number
            item = self:filterFood(item)
            if item then
                local itemName = item:getFullType()
                local numIter = self:getNumberAlreadyUsed(itemName)+1;
                while (not listsItems[numIter]) do
                    table.insert(listsItems, {});--prepare empty tables
                end
                
                table.insert(listsItems[numIter], item);--add element to correct table
            end
        end
    end
    
    --we switch ingredient as much as possible (higher priority than all other stuff)
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
    
    if evoItem then
        self:setItemUsed(evoItem:getFullType());
    end
    
    return evoItem
end

function AutoCook:filterFood(item)
    local nutrition = self.playerObj:getNutrition();
    local playerWeight = nutrition:getWeight();
    
    if playerWeight > AutoCook.NutritionistMinWeight and AutoCook.CookMode == 4 then
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

function AutoCook:selectForWeightLoss(leftItem, rightItem)
    if AutoCook.Verbose then print ("AutoCook:selectForWeightLoss item comparison") end
    local leftHunger = leftItem:getHungChange();
    local leftCalories = leftItem:getCalories();
    local rightHunger = rightItem:getHungChange();
    local rightCalories = rightItem:getCalories();
    if rightCalories <= 0 then
        if leftCalories > 0 or rightHunger > leftHunger then
            return rightItem
        else
            return leftItem
        end
    elseif leftCalories <= 0 then
        return leftItem
    else
        local leftRatio = -leftHunger/leftCalories
        local rightRatio = -rightHunger/rightCalories
        if rightRatio > leftRatio then
            return rightItem
        else
            return leftItem
        end
    end
end
function AutoCook:selectForWeightGain(leftItem, rightItem)
    if AutoCook.Verbose then print ("AutoCook:selectForWeightGain item comparison") end
    local leftHunger = leftItem:getHungChange();
    local leftCalories = leftItem:getCalories();
    local rightHunger = rightItem:getHungChange();
    local rightCalories = rightItem:getCalories();
    if rightCalories <= 0 then
        if leftCalories > 0 or rightHunger > leftHunger then
            return leftItem
        else
            return rightItem
        end
    elseif leftCalories <= 0 then
        return rightItem
    else
        local leftRatio = -leftHunger/leftCalories
        local rightRatio = -rightHunger/rightCalories
        if rightRatio > leftRatio then
            return leftItem
        else
            return rightItem
        end
    end
end
function AutoCook:selectForStrength(leftItem, rightItem, playerObj, baseItem)
    if AutoCook.Verbose then print ("AutoCook:selectForStrength item comparison") end
    --try to get calories between 50 and 300 target 300 for simplicity but is likely to not be accurate enough
    local protein = playerObj:getNutrition():getProteins();
    if instanceof(baseItem, "Food") then
        protein = protein + baseItem:getProteins();
    end
    local leftProteins = protein + leftItem:getProteins()
    local rightProteins = protein + rightItem:getProteins()
    if leftProteins < AutoCook.ProteinTarget then
        if rightProteins < AutoCook.ProteinTarget and rightProteins > leftProteins then
                return rightItem
        else
            return leftItem
        end
    else
        if rightProteins < AutoCook.ProteinTarget then
            return rightItem
        else--we could go over max protein, beware
            if leftProteins < rightProteins and leftProteins < AutoCook.ProteinMax then
                return leftItem
            elseif rightProteins < leftProteins and rightProteins < AutoCook.ProteinMax then
                return rightItem
            else
                return nil--do not eat then to avoid overprotein
            end
        end
    end
end

function AutoCook:selectDefault(leftItem, rightItem)
    if AutoCook.Verbose then print ("AutoCook:selectDefault item comparison") end
    local age = leftItem:getAge();
    local agingDelta = leftItem:getOffAge() - age;
    local rottingDelta = leftItem:getOffAgeMax() - age;
            
    local newAge = rightItem:getAge();
    local newAgingDelta = rightItem:getOffAge() - newAge;
    local newRottingDelta = rightItem:getOffAgeMax() - newAge;
    --we take the ingredient that is the closest to loose freshness
    --if both have lost freshness we take the ingredient that's the closest to rot
    if newAgingDelta > 0 and (newAgingDelta < agingDelta or agingDelta < 0) or (agingDelta < 0 and newRottingDelta > 0 and (newRottingDelta < rottingDelta or rottingDelta < 0 )) then
        return rightItem
    end
    return leftItem--TODO filter depending on selected limitations
end

function AutoCook:selectNutritionist(leftItem, rightItem)
    if AutoCook.Verbose then print ("AutoCook:selectNutritionist item comparison") end
    local nutrition = self.playerObj:getNutrition();
    local playerWeight = nutrition:getWeight();
    if playerWeight < AutoCook.NutritionistMinWeight then
        return self:selectForWeightGain(leftItem, rightItem);
    elseif playerWeight > AutoCook.NutritionistMaxWeight then
        return self:selectForWeightLoss(leftItem, rightItem);
    else
        return self:selectForStrength(leftItem, rightItem, self.playerObj, self.baseItem);
    end
end

function AutoCook:selectPreferedFood(leftItem, rightItem)
    if AutoCook.CookMode == 2 then return self:selectForWeightLoss(leftItem, rightItem) end
    if AutoCook.CookMode == 3 then return self:selectForWeightGain(leftItem, rightItem) end
    if AutoCook.CookMode == 4 then return self:selectNutritionist(leftItem, rightItem) end
    return self:selectDefault(leftItem, rightItem)--0/1/any
end

function AutoCook:getNumberAlreadyUsed(itemName)
    for i=1,#self.usedItems do
        if self.usedItems[i].itemName == itemName then
            return self.usedItems[i].number;
        end
    end
    return 0
end

function AutoCook:setItemUsed(itemName)
    for i=1,#self.usedItems do
        if self.usedItems[i].itemName == itemName then
            self.usedItems[i].number = self.usedItems[i].number + 1;
            return
        end
    end
    local usedItemStruct = {}
    usedItemStruct.itemName = itemName
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
