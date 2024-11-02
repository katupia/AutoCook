require "ISUI/ISPanelJoypad"
require "ISCharacterInfoWindow_AddTab"
require "AutoCook"

ISCharacterCook = ISPanelJoypad:derive("ISCharacterCook");

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISCharacterCook:initialise()
    ISPanelJoypad.initialise(self);
end

function ISCharacterCook:createChildren()
    self.textY = 0
    --prebuild some stuff
    self.inputX = self:getWidth() / 2

    -- Cooking mode and ingredients
    self:createCookingModeCombo()
    self.textY = self.textY + 5
    self:createDuplicateInput()
    self:createRottenTick()
    self.textY = self.textY + 15

    -- Spices
    self:createSpiceInput()
    self:createSpiceTick()
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
        combo.selected = 5
    else
        combo.selected = 1
    end
    combo:setWidth(width+30)
    if self.comboCookMode then self:removeChild(self.comboCookMode) end
    self:addChild(combo)
    self.comboCookMode = combo

    self.textY = self.comboCookMode:getBottom()
end

function ISCharacterCook:onComboSelectCookMode()
    AutoCook.CookMode = self.comboCookMode.selected
end

function ISCharacterCook:createRottenTick()
    local smartOptionText = getText("UI_AutoCookUseRotten")
    local txtWidth = getTextManager():MeasureStringX(UIFont.Medium, smartOptionText)
    local tickBoxHeight = FONT_HGT_MEDIUM
    if self.rottenTickBox then self:removeChild(self.rottenTickBox) end
    self.rottenTickBox = ISTickBox:new(self.textX, self.textY, txtWidth, tickBoxHeight, "rottenTick", self, self.onChangeRottenMode);
    self.rottenTickBox:initialise()
    self:addChild(self.rottenTickBox)
    self.rottenTickBox:addOption(smartOptionText)
    self.rottenTickBox:setSelected(1, AutoCook.UseRotten)
    self.rottenTickBox.tooltip = getText("UI_AutoCookUseRottenTooltip")

    self.textY = self.rottenTickBox:getBottom()
end

function ISCharacterCook:onChangeRottenMode(index, isEnabled)
    AutoCook.UseRotten = isEnabled
end

function ISCharacterCook:createDuplicateInput()
    -- create label
    if self.duplicatesInputLabel then self:removeChild(self.duplicatesInputLabel) end
    self.duplicatesInputLabel = ISLabel:new(self.textX, self.textY, FONT_HGT_SMALL, getText("UI_AutoCookMaxDuplicate"), 1, 1, 1, 1, UIFont.Small, true)
	self.duplicatesInputLabel:initialise();
	self.duplicatesInputLabel:instantiate();
	self:addChild(self.duplicatesInputLabel)

    -- copy from ISFitnessUI
    local dupText = "N/A"
    if AutoCook.MaxDuplicate then
        dupText = tostring(AutoCook.MaxDuplicate)
    end
    if self.duplicatesInput then self:removeChild(self.duplicatesInput) end
    self.duplicatesInput = ISTextEntryBox:new(dupText, self.inputX, self.textY - 2, 55, FONT_HGT_SMALL + 2 * 2)
	self.duplicatesInput:initialise();
	self.duplicatesInput:instantiate();
	self.duplicatesInput.font = UIFont.Medium
	self.duplicatesInput:setOnlyNumbers(true);
	self.duplicatesInput:setEditable(false);
	self:addChild(self.duplicatesInput)

	-- +/- buttons
    if self.duplicatesInputPlus then self:removeChild(self.duplicatesInputPlus) end
	self.duplicatesInputPlus = ISButton:new(self.duplicatesInput.x + self.duplicatesInput:getWidth() + 2, self.duplicatesInput.y, self.duplicatesInput:getHeight(), self.duplicatesInput:getHeight(), "+", self, self.onDuplicatesInput)
	self.duplicatesInputPlus:initialise();
	self.duplicatesInputPlus:instantiate();
	self.duplicatesInputPlus.internal = "PLUS";
	self:addChild(self.duplicatesInputPlus)
	
    if self.duplicatesInputMinus then self:removeChild(self.duplicatesInputMinus) end
	self.duplicatesInputMinus = ISButton:new(self.duplicatesInputPlus.x + self.duplicatesInputPlus:getWidth() + 1, self.duplicatesInput.y, self.duplicatesInput:getHeight(), self.duplicatesInput:getHeight(), "-", self, self.onDuplicatesInput)
	self.duplicatesInputMinus:initialise();
	self.duplicatesInputMinus:instantiate();
	self.duplicatesInputMinus.internal = "MINUS";
	self:addChild(self.duplicatesInputMinus)

	self:setHeight(self.duplicatesInput:getBottom())

    self.textY = self.duplicatesInput:getBottom()
end

function ISCharacterCook:onDuplicatesInput(button)
    if button.internal == "PLUS" and AutoCook.MaxDuplicate < 6 then
        AutoCook.MaxDuplicate = AutoCook.MaxDuplicate + 1;
    end
    if button.internal == "MINUS" and AutoCook.MaxDuplicate > 1 then
        AutoCook.MaxDuplicate = AutoCook.MaxDuplicate - 1;
    end

    self.duplicatesInput:setText(tostring(AutoCook.MaxDuplicate));
end

function ISCharacterCook:createSpiceInput()
    -- create label
    if self.spiceInputLabel then self:removeChild(self.spiceInputLabel) end
    self.spiceInputLabel = ISLabel:new(self.textX, self.textY, FONT_HGT_MEDIUM, getText("UI_AutoCookMaxSpices"), 1, 1, 1, 1, UIFont.Medium, true)
	self.spiceInputLabel:initialise();
	self.spiceInputLabel:instantiate();
	self:addChild(self.spiceInputLabel)

    -- copy from ISFitnessUI
    local text = "N/A"
    if AutoCook.MaxSpices then
        text = tostring(AutoCook.MaxSpices)
    end
    if self.spiceInput then self:removeChild(self.spiceInput) end
    self.spiceInput = ISTextEntryBox:new(text, self.inputX, self.textY + 2, 55, FONT_HGT_SMALL + 2 * 2)
	self.spiceInput:initialise();
	self.spiceInput:instantiate();
	self.spiceInput.font = UIFont.Medium
	self.spiceInput:setOnlyNumbers(true);
	self.spiceInput:setEditable(false);
	self:addChild(self.spiceInput)

	-- +/- buttons
    if self.spiceInputPlus then self:removeChild(self.spiceInputPlus) end
	self.spiceInputPlus = ISButton:new(self.spiceInput.x + self.spiceInput:getWidth() + 2, self.spiceInput.y, self.spiceInput:getHeight(), self.spiceInput:getHeight(), "+", self, self.onSpiceInput)
	self.spiceInputPlus:initialise();
	self.spiceInputPlus:instantiate();
	self.spiceInputPlus.internal = "PLUS";
	self:addChild(self.spiceInputPlus)
	
    if self.spiceInputMinus then self:removeChild(self.spiceInputMinus) end
	self.spiceInputMinus = ISButton:new(self.spiceInputPlus.x + self.spiceInputPlus:getWidth() + 1, self.spiceInput.y, self.spiceInput:getHeight(), self.spiceInput:getHeight(), "-", self, self.onSpiceInput)
	self.spiceInputMinus:initialise();
	self.spiceInputMinus:instantiate();
	self.spiceInputMinus.internal = "MINUS";
	self:addChild(self.spiceInputMinus)

	self:setHeight(self.spiceInput:getBottom())

    self.textY = self.spiceInput:getBottom()
end

function ISCharacterCook:onSpiceInput(button)
    if button.internal == "PLUS" and AutoCook.MaxSpices < 10 then
        AutoCook.MaxSpices = AutoCook.MaxSpices + 1;
    end
    if button.internal == "MINUS" and AutoCook.MaxSpices >= 0 then
        AutoCook.MaxSpices = AutoCook.MaxSpices - 1;
    end

    if AutoCook.MaxSpices < 0 then
        self.spiceInput:setText("All");
    else
        self.spiceInput:setText(tostring(AutoCook.MaxSpices));
    end
end

function ISCharacterCook:createSpiceTick()
    if self.spiceTickBox then self:removeChild(self.spiceTickBox) end
    local smartOptionText = getText("UI_AutoCookSmartSpices")
    local txtWidth = getTextManager():MeasureStringX(UIFont.Medium, smartOptionText)
    local tickBoxHeight = FONT_HGT_MEDIUM
    self.spiceTickBox = ISTickBox:new(self.textX, self.textY, txtWidth, tickBoxHeight, "spiceTick", self, self.onChangeSpiceMode);
    self.spiceTickBox:initialise()
    self:addChild(self.spiceTickBox)
    self.spiceTickBox:addOption(smartOptionText)
    self.spiceTickBox:setSelected(1, AutoCook.SmartSpices)
    self.spiceTickBox.tooltip = getText("UI_AutoCookSmartSpicesTooltip")

    self.textY = self.spiceTickBox:getBottom()
end

function ISCharacterCook:onChangeSpiceMode(index, isEnabled)
    AutoCook.SmartSpices = isEnabled
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
