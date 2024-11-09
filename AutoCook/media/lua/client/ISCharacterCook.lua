require "ISUI/ISPanelJoypad"
require "ISCharacterInfoWindow_AddTab"
require "AutoCook"

ISCharacterCook = ISPanelJoypad:derive("ISCharacterCook");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISCharacterCook:initialise()
    if AutoCook.Verbose then print ("ISCharacterCook:initialise") end
    ISPanelJoypad.initialise(self);
end

function ISCharacterCook:createChildren()
    if AutoCook.Verbose then print ("ISCharacterCook:createChildren") end
    AutoCook.init(self, self.char)

    self.textY = 0
    self.inputX = self:getWidth() / 2
    
    -- Cooking mode and ingredients
    self:createCookingModeCombo()
    self.textY = self.textY + 5
    self:createNumberInput("MaxDuplicate", "UI_AutoCookMaxDuplicate", 1, 6, "UI_AutoCookMaxDuplicateTooltip", UIFont.Small)
    self:createTickBox("PrioritizeVariety", "UI_AutoCookPrioVariety", "UI_AutoCookPrioVarietyTooltip")
    self:createTickBox("UseRotten", "UI_AutoCookUseRotten", "UI_AutoCookUseRottenTooltip")
    self:createTickBox("AutoCraftIngredients", "UI_AutoCookAutoCraftIngredients", "UI_AutoCookAutoCraftIngredientsTooltip")
    self.textY = self.textY + 15

    -- Spices
    self:createNumberInput("MaxSpices", "UI_AutoCookMaxSpices", -1, 10, "UI_AutoCookMaxSpicesTooltip", UIFont.Medium)
    self:createTickBox("SmartSpices", "UI_AutoCookSmartSpices", "UI_AutoCookSmartSpicesTooltip")
    self.textY = self.textY + 10

    self:setScrollChildren(true)
    self:addScrollBars()
end

function ISCharacterCook:setVisible(visible)
    self.javaObject:setVisible(visible);
end

function ISCharacterCook:prerender()
    ISPanelJoypad.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
    
    local isNutritionist = self.char:HasTrait("Nutritionist") or self.char:HasTrait("Nutritionist2");
    if isNutritionist ~= self.isNutritionist then self:createChildren() end--recreate combo list on change
end

function ISCharacterCook:addTextLine(str,textX, textY, maxTextWidth)
    local txt = "- "..str;
    self:drawText(txt, textX, textY, 1, 1, 1, 1, UIFont.Small)
    local txtWidth = getTextManager():MeasureStringX(UIFont.Small, txt);
    if txtWidth > maxTextWidth then maxTextWidth = txtWidth end
    return maxTextWidth;
end

function ISCharacterCook:render()
    if not self.char:getModData() then self:clearStencilRect(); return end
    ------------------------------------
    
    local textX = self.textX
    local fontHeight = FONT_HGT_SMALL
    local textY = self.textY
    local maxTextWidth = 0

    local nutrition = self.char:getNutrition()
    
    if AutoCook.Verbose then
        --lipids --must be over -1000 for decent recovery modifier. place a warning at -500 (IsoGameCharacter getRecoveryMod())
        --must be below 400 to not increase a lot (x2 but depends on carbs). 700 (x3)
        --decreases over time => try to minimise (unless underweight)
        maxTextWidth = self:addTextLine(getText("Tooltip_food_Fat") .. " " .. nutrition:getLipids(),textX, textY, maxTextWidth);
        textY = textY + fontHeight
        
        --proteins --must be over -1000 for decent recovery modifier. (IsoGameCharacter getRecoveryMod())
        --proteins --Wiki:(As of b34.5, Protein values between 50 and 300 provide a 1.5 multiplier to Str XP gain. Likewise, values below -300 apply a .7 gain penalty. Weight scales, such as in hospitals, can provide detailed nutrition info)
        --place a warning out of 50 and 300 => eat proteins in the morning ?! maybe
        --decreases over time => target 300 and never more
        maxTextWidth = self:addTextLine(getText("Tooltip_food_Prots") .. " " .. nutrition:getProteins(),textX, textY, maxTextWidth);
        textY = textY + fontHeight
        
        --must be below 400 to not increase a lot (x2, but depends on lipids). 700 (x3)
        --decreases over time => try to minimise (unless underweight)
        maxTextWidth = self:addTextLine(getText("Tooltip_food_Carbs") .. " " .. nutrition:getCarbohydrates(),textX, textY, maxTextWidth);
        textY = textY + fontHeight
        
        --Beware approximation!!! gain weight when above 1100 calories. ++above 4000
        --Beware approximation!!! gain loss when below 0. linear then saturated below-2500
        --decreases over time => adjust for weight balance
        maxTextWidth = self:addTextLine(getText("Tooltip_food_Calories") .. " " .. nutrition:getCalories(),textX, textY, maxTextWidth);
        textY = textY + fontHeight
        
        --35- => dies. 50- emaciated. 65- VUnderweight. 75- Underweight. 85+ Overweight. 100+ Obese
        --reference for algo selection
        maxTextWidth = self:addTextLine(getText("Tooltip_item_Weight") .. " " .. nutrition:getWeight(),textX, textY, maxTextWidth);
        textY = textY + fontHeight
    end
    
    if self.isNutritionist then
        --lipids --must be over -1000 for decent recovery modifier. place a warning at -500 (IsoGameCharacter getRecoveryMod())
        --must be below 400 to not increase a lot (x2 but depends on carbs). 700 (x3)
        --decreases over time => try to minimise (unless underweight)
        if nutrition:getLipids() < -1500 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookFatLowWarning3"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getLipids() < -1000 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookFatLowWarning2"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getLipids() < -500 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookFatLowWarning1"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getLipids() > 700 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookFatHighWarning2"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getLipids() > 400 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookFatHighWarning1"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        end
        
        if nutrition:getCarbohydrates() > 700 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookCarbsHighWarning2"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getCarbohydrates() > 400 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookCarbsHighWarning1"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        end
        
        if nutrition:getProteins() < -1500 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookProteinsLowWarning4"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getProteins() < -1000 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookProteinsLowWarning3"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getProteins() < -300 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookProteinsLowWarning2"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getProteins() < 50 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookProteinsLowWarning1"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        elseif nutrition:getProteins() > 300 then
            maxTextWidth = self:addTextLine(getText("UI_AutoCookProteinsHighWarning1"),textX, textY, maxTextWidth);
            textY = textY + fontHeight
        end
        
    end
    
    -------------------------------
    textY = textY + fontHeight--more satisfying with an empty line

    local widthRequired = self.textX * 2 + maxTextWidth;
    if widthRequired > self:getWidth() then
        self:setWidthAndParentWidth(widthRequired);
    end
    
    local tabHeight = self.y
    local maxHeight = getCore():getScreenHeight() - tabHeight - 20
    if ISWindow and ISWindow.TitleBarHeight then maxHeight = maxHeight - ISWindow.TitleBarHeight end
    
    self:setHeightAndParentHeight(math.min(textY, maxHeight));
    self:setScrollHeight(textY)
    
    self:clearStencilRect()
end

function ISCharacterCook:onMouseWheel(del)
    self:setYScroll(self:getYScroll() - del * 30)
    return true
end

function ISCharacterCook:new(x, y, width, height, playerNum)
    local o = {};
    o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.playerNum = playerNum
    o.char = getSpecificPlayer(playerNum);
    o:noBackground();
    o.textX = 20
    o.inputX = 300
    o.textY = 0
    
    ISCharacterCook.instance = o;
   return o;
end

local function addComboOption(combo,name,previousWidth)
    local txt = getText(name)
    local txtWidth = getTextManager():MeasureStringX(UIFont.Small, txt);
    combo:addOption(txt)
    if previousWidth > txtWidth then return previousWidth end
    return txtWidth
end

function ISCharacterCook:createCookingModeCombo()
    local comboHeight = FONT_HGT_MEDIUM
    self.textY = self.textY + FONT_HGT_SMALL

    -- create label
    if self.cookModeLabel then self:removeChild(self.cookModeLabel) end
    self.cookModeLabel = ISLabel:new(self.textX, self.textY, FONT_HGT_MEDIUM, getText("UI_AutoCookMode"), 1, 1, 1, 1, UIFont.Medium, true)
	self.cookModeLabel:initialise();
	self.cookModeLabel:instantiate();
	self:addChild(self.cookModeLabel)

    local preText = getText("UI_AutoCookMode").." "
    local preTextWidth = getTextManager():MeasureStringX(UIFont.Medium, preText); -- could be label.x
    
    -- create combo box
    local combo = ISComboBox:new(self.inputX, self.textY, 10, comboHeight, self, self.onComboSelectCookMode)
    --combo.noSelectionText = "Select Cook Mode"
    local width = 0;
    width = addComboOption(combo,"UI_AutoCookFreshness",width)
    width = addComboOption(combo,"UI_AutoCookLeftovers",width)
    width = addComboOption(combo,"UI_AutoCookWeightLoss",width)
    width = addComboOption(combo,"UI_AutoCookWeightGain",width)
    local isNutritionist = self.char:HasTrait("Nutritionist") or self.char:HasTrait("Nutritionist2");
    self.isNutritionist = isNutritionist;
    if isNutritionist then
        width = addComboOption(combo,"UI_AutoCookNutritionist",width)
    end

    combo.selected = AutoCook.CookMode
    combo:setWidth(width+30)
    if self.comboCookMode then self:removeChild(self.comboCookMode) end
    self:addChild(combo)
    self.comboCookMode = combo

    self.textY = self.comboCookMode:getBottom()
end

function ISCharacterCook:onComboSelectCookMode()
    AutoCook.CookMode = self.comboCookMode.selected
    self.char:getModData().AutoCook.CookMode = AutoCook.CookMode
end

function ISCharacterCook:createTickBox(settingId, text, tooltip)
    local txtWidth = getTextManager():MeasureStringX(UIFont.Medium, getText(text))
    local tickBoxHeight = FONT_HGT_MEDIUM
    local viewID = "tickbox_" .. settingId
    if self[viewID] then self:removeChild(self[settingId]) end
    self[viewID] = ISTickBox:new(self.textX, self.textY, txtWidth, tickBoxHeight, viewID, self, self.onTickChange, settingId);
    self[viewID]:initialise()
    self:addChild(self[viewID])
    self[viewID]:addOption(getText(text))
    self[viewID]:setSelected(1, AutoCook[settingId])
    self[viewID].tooltip = getText(tooltip)

    self.textY = self[viewID]:getBottom()
end

function ISCharacterCook:onTickChange(index, isEnabled, settingId)
    AutoCook[settingId] = isEnabled
    self.char:getModData().AutoCook[settingId] = AutoCook[settingId]
end

function ISCharacterCook:createNumberInput(settingId, text, min, max, tooltip, labelFontSize)
    if not labelFontSize then
        labelFontSize = UIFont.Small
    end
    local labelViewId = "label_"..settingId
    -- create label
    if self[labelViewId] then self:removeChild(self[labelViewId]) end
    self[labelViewId] = ISLabel:new(self.textX, self.textY, getTextManager():getFontHeight(labelFontSize), getText(text), 1, 1, 1, 1, labelFontSize, true)
	self[labelViewId]:initialise()
	self[labelViewId]:instantiate()
	self:addChild(self[labelViewId])
	self[labelViewId].tooltip = getText(tooltip)

    local inputViewId = "input_"..settingId
    if self[inputViewId] then self:removeChild(self[inputViewId]) end
    local yOffset = -2
    if labelFontSize == UIFont.Medium then
        yOffset = 2
    end
    
    local minXSecondColumn = self.textX + self[labelViewId]:getWidth() + 5
    if self.inputX < minXSecondColumn then
        self.inputX = minXSecondColumn
    end
    self[inputViewId] = ISTextEntryBox:new("N/A", self.inputX, self.textY + yOffset, 55, FONT_HGT_SMALL + 2 * 2)
	self[inputViewId]:initialise()
	self[inputViewId]:instantiate()
	self[inputViewId].font = UIFont.Medium
	self[inputViewId]:setOnlyNumbers(true)
	self[inputViewId]:setEditable(false)
    if AutoCook[settingId] then
        -- set current value
        self:onNumberInput(nil, settingId, inputViewId)
    end
	self:addChild(self[inputViewId])

	-- +/- buttons
    local plusViewID = "buttonPlus_"..settingId
    if self[plusViewID] then self:removeChild(self[plusViewID]) end
    self[plusViewID] = ISButton:new(self[inputViewId].x + self[inputViewId]:getWidth() + 2, self[inputViewId].y, self[inputViewId]:getHeight(), self[inputViewId]:getHeight(), "+", self, self.onNumberInput)
    self[plusViewID]:initialise()
    self[plusViewID]:instantiate()
    self[plusViewID].internal = "PLUS"
    self[plusViewID].settingId = settingId
    self[plusViewID].inputViewId = inputViewId
    self[plusViewID].max = max
    self:addChild(self[plusViewID])

    local minusViewID = "buttonMinus_"..settingId
    if self[minusViewID] then self:removeChild(self[minusViewID]) end
    self[minusViewID] = ISButton:new(self[plusViewID].x + self[plusViewID]:getWidth() + 1, self[inputViewId].y, self[inputViewId]:getHeight(), self[inputViewId]:getHeight(), "-", self, self.onNumberInput)
    self[minusViewID]:initialise()
    self[minusViewID]:instantiate()
    self[minusViewID].internal = "MINUS"
    self[minusViewID].settingId = settingId
    self[minusViewID].inputViewId = inputViewId
    self[minusViewID].min = min
    self:addChild(self[minusViewID])

    self:setHeight(self[minusViewID]:getBottom())
    self.textY = self[minusViewID]:getBottom()
    
    if self:getWidth() < self[minusViewID]:getRight() then
        self:setWidth(self[minusViewID]:getRight())
    end
end

function ISCharacterCook:onNumberInput(button, settingId, inputViewId)
    if button ~= nil then
        settingId = button.settingId
        inputViewId = button.inputViewId

        if button.internal == "PLUS" and AutoCook[settingId] < button.max then
            AutoCook[settingId] = AutoCook[settingId] + 1;
        end
        if button.internal == "MINUS" and AutoCook[settingId] > button.min then
            AutoCook[settingId] = AutoCook[settingId] - 1;
        end
        self.char:getModData().AutoCook[settingId] = AutoCook[settingId]
    end
    if AutoCook[settingId] < 0 then
        self[inputViewId]:setText(getText("UI_AutoCookAll"));
    else
        self[inputViewId]:setText(tostring(AutoCook[settingId]));
    end
end

function ISCharacterCook:ensureVisible()
    if not self.joyfocus then return end
    local child = nil;--TODO manage scroll? self.progressBars[self.joypadIndex]
    if not child then return end
    local y = child:getY()
    if y - 40 < 0 - self:getYScroll() then
        self:setYScroll(0 - y + 40)
    elseif y + child:getHeight() + 40 > 0 - self:getYScroll() + self:getHeight() then
        self:setYScroll(0 - (y + child:getHeight() + 40 - self:getHeight()))
    end
end

function ISCharacterCook:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData);
    self.joypadIndex = nil
    self.barWithTooltip = nil
end

function ISCharacterCook:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData);
end

function ISCharacterCook:onJoypadDown(button)
    if button == Joypad.AButton then
    end
    if button == Joypad.YButton then
    end
    if button == Joypad.BButton then
    end
    if button == Joypad.LBumper then
        getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
    end
    if button == Joypad.RBumper then
        getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
    end
end

function ISCharacterCook:onJoypadDirDown()
    self.joypadIndex = self.joypadIndex + 1
    self:ensureVisible()
    self:updateTooltipForJoypad()
end

function ISCharacterCook:onJoypadDirLeft()
end

function ISCharacterCook:onJoypadDirRight()
end


addCharacterPageTab("Cook",ISCharacterCook)
