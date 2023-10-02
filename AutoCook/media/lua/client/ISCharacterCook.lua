require "ISUI/ISPanelJoypad"
require "ISCharacterInfoWindow_AddTab"
require "AutoCook"

ISCharacterCook = ISPanelJoypad:derive("ISCharacterCook");

function ISCharacterCook:initialise()
    ISPanelJoypad.initialise(self);
end

function ISCharacterCook:createChildren()
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
    if isNutritionist ~= self.isNutritionist then self:createComboMode() end--recreate combo list on change
end

function ISCharacterCook:addTextLine(str,textX, textY, maxTextWidth)
    local txt = "- "..str;
    self:drawText(txt, textX, textY, 1, 1, 1, 1, UIFont.Small)
    txtWidth = getTextManager():MeasureStringX(UIFont.Small, txt);
    if txtWidth > maxTextWidth then maxTextWidth = txtWidth end
    return maxTextWidth;
end

function ISCharacterCook:render()
    if not self.char:getModData() then self:clearStencilRect(); return end
    ------------------------------------
    
    local textX = 20
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local textY = fontHeight
    local maxTextWidth = 0

    local preText = getText("UI_AutoCookMode").." "
    self:drawText(preText, textX, textY, 1, 1, 1, 1, UIFont.Medium)
    local txtWidth = getTextManager():MeasureStringX(UIFont.Medium, preText);
    if txtWidth > maxTextWidth then maxTextWidth = txtWidth end
    textY = textY + getTextManager():getFontHeight(UIFont.Medium)

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

    local widthRequired = textX * 2 + maxTextWidth;
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

function ISCharacterCook:new (x, y, width, height, playerNum)
    local o = {};
    o = ISPanelJoypad:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;
    o.playerNum = playerNum
    o.char = getSpecificPlayer(playerNum);
    o:noBackground();
    --prebuild some stuff
    o:createComboMode();
    
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

local function getCookModeText()
    
end

function ISCharacterCook:createComboMode()
    
    local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
    local comboOffset = 3 * 2
    local comboHeight = FONT_HGT_MEDIUM + comboOffset
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local textX = 20
    local textY = fontHeight
    
    local preText = getText("UI_AutoCookMode").." "
    local preTextWidth = getTextManager():MeasureStringX(UIFont.Medium, preText);
    
    local combo = ISComboBox:new(textX+preTextWidth, fontHeight-comboOffset, 10, comboHeight, self, self.onComboSelectCookMode)
    --combo.noSelectionText = "Select Cook Mode"
    local width = 0;
    width = addComboOption(combo,"UI_AutoCookFreshness",width)
    width = addComboOption(combo,"UI_AutoCookWeightLoss",width)
    width = addComboOption(combo,"UI_AutoCookWeightGain",width)
    local isNutritionist = self.char:HasTrait("Nutritionist") or self.char:HasTrait("Nutritionist2");
    self.isNutritionist = isNutritionist;
    if isNutritionist then
        width = addComboOption(combo,"UI_AutoCookNutritionist",width)
        combo.selected = 4
    else
        combo.selected = 1
    end
    combo:setWidth(width+30)
    if self.comboCookMode then self:removeChild(self.comboCookMode) end
    self:addChild(combo)
    self.comboCookMode = combo
end

function ISCharacterCook:onComboSelectCookMode()
    AutoCook.CookMode = self.comboCookMode.selected
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
