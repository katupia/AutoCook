require "AutoCook"

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


function AutoCook:selectPreferedFood(leftItem, rightItem)
    if AutoCook.CookMode == 2 then return self:selectForLeftovers(leftItem, rightItem) end
    if AutoCook.CookMode == 3 then return self:selectForWeightLoss(leftItem, rightItem) end
    if AutoCook.CookMode == 4 then return self:selectForWeightGain(leftItem, rightItem) end
    if AutoCook.CookMode == 5 then return self:selectNutritionist(leftItem, rightItem) end
    return self:selectDefault(leftItem, rightItem)--0/1/any
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

function AutoCook:selectForLeftovers(leftItem, rightItem)
    if AutoCook.Verbose then print ("AutoCook:selectForLeftovers item comparison") end
    local age = leftItem:getAge();
    local agingDelta = leftItem:getOffAge() - age;
    local rottingDelta = leftItem:getOffAgeMax() - age;
            
    local newAge = rightItem:getAge();
    local newAgingDelta = rightItem:getOffAge() - newAge;       -- time left until stale 
    local newRottingDelta = rightItem:getOffAgeMax() - newAge;  -- time left until rotten

    -- take the ingredient that is the closest to rotting
    if AutoCook.Verbose then print(rottingDelta .. " - " .. newRottingDelta) end
    if newRottingDelta < rottingDelta then
        if AutoCook.Verbose then print("item " .. rightItem:getName() .. " is closer to rot than " .. leftItem:getName()) end
        return rightItem
    elseif newRottingDelta > rottingDelta then
        if AutoCook.Verbose then print("item " .. leftItem:getName() .. " is closer to rot than " .. rightItem:getName()) end
        return leftItem
    else
        -- if ingredients same age, prefer smaller "leftover" stacks
        return self:selectForWeightLoss(leftItem, rightItem);
    end
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
