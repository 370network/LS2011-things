SliderElement = {}
SliderElement.STATE_NORMAL = 1
SliderElement.STATE_PRESSED = 2
SliderElement.STATE_FOCUSED = 3
SliderElement.DIRECTION_X = 1
SliderElement.DIRECTION_Y = 2
local SliderElement_mt = Class(SliderElement, GuiElement)
function SliderElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = SliderElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  self.mouseDown = false
  instance.minValue = 0
  instance.maxValue = 100
  instance.currentValue = 0
  instance.minSliderPos = 0.08
  instance.maxSliderPos = 0.92
  instance.stepSize = 1
  instance.direction = SliderElement.DIRECTION_X
  instance.showValue = true
  instance.text2Offset = {0.005, 0.006}
  instance.text2Size = 0.033
  instance.text2Color = {
    0,
    0,
    0,
    1
  }
  instance.text2DisabledColor = {
    1,
    1,
    1,
    0.8
  }
  instance.text2Bold = true
  instance.textOffset = {0.005, 0.008}
  instance.textSize = 0.033
  instance.textColor = {
    1,
    1,
    1,
    1
  }
  instance.textDisabledColor = {
    1,
    1,
    1,
    0.8
  }
  instance.textBold = true
  instance.imageColor = {
    1,
    1,
    1,
    1
  }
  instance.imageDisabledColor = {
    1,
    1,
    1,
    0.8
  }
  instance.sliderOffset = -0.012
  instance.sliderSize = {1, 1}
  instance.sliderPosition = {0, 0}
  instance.minAbsSliderPos = 0.08
  instance.maxAbsSliderPos = 0.92
  instance.valueTexts = {}
  return instance
end
function SliderElement:loadFromXML(xmlFile, key)
  SliderElement:superClass().loadFromXML(self, xmlFile, key)
  local sliderBaseImageFilename = getXMLString(xmlFile, key .. "#sliderBaseImageFilename")
  if sliderBaseImageFilename ~= nil then
    self.sliderBaseImageFilename = sliderBaseImageFilename
  end
  local sliderImageFilename = getXMLString(xmlFile, key .. "#sliderImageFilename")
  if sliderImageFilename ~= nil then
    self.sliderImageFilename = sliderImageFilename
  end
  local direction = getXMLString(xmlFile, key .. "#direction")
  if direction ~= nil then
    if direction == "y" then
      self.direction = SliderElement.DIRECTION_Y
    elseif direction == "x" then
      self.direction = SliderElement.DIRECTION_X
    end
  end
  local showValue = getXMLBool(xmlFile, key .. "#showValue")
  if showValue ~= nil then
    self.showValue = showValue
  end
  local minValue = getXMLFloat(xmlFile, key .. "#minValue")
  if minValue ~= nil then
    self.minValue = minValue
  end
  local maxValue = getXMLFloat(xmlFile, key .. "#maxValue")
  if maxValue ~= nil then
    self.maxValue = maxValue
  end
  local currentValue = getXMLFloat(xmlFile, key .. "#currentValue")
  if currentValue ~= nil then
    self.currentValue = currentValue
  end
  local minSliderPos = getXMLString(xmlFile, key .. "#minSliderPos")
  if minSliderPos ~= nil then
    self.minSliderPos = self:evaluateFormula(minSliderPos)
  end
  local maxSliderPos = getXMLString(xmlFile, key .. "#maxSliderPos")
  if maxSliderPos ~= nil then
    self.maxSliderPos = self:evaluateFormula(maxSliderPos)
  end
  local stepSize = getXMLFloat(xmlFile, key .. "#stepSize")
  if stepSize ~= nil then
    self.stepSize = stepSize
  end
  local onClick = getXMLString(xmlFile, key .. "#onClick")
  if onClick ~= nil then
    if self.target ~= nil then
      self.onClick = self.target[onClick]
    else
      loadstring("g_asdasd_tempFunc = " .. onClick)()
      self.onClick = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local onChanged = getXMLString(xmlFile, key .. "#onChanged")
  if onChanged ~= nil then
    if self.target ~= nil then
      self.onChanged = self.target[onChanged]
    else
      loadstring("g_asdasd_tempFunc = " .. onChanged)()
      self.onChanged = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local textColor = self:getColorArray(getXMLString(xmlFile, key .. "#textColor"))
  if textColor ~= nil then
    self.textColor = textColor
  end
  local textDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#textDisabledColor"))
  if textDisabledColor ~= nil then
    self.textDisabledColor = textDisabledColor
  end
  local textOffset = self:get2DArray(getXMLString(xmlFile, key .. "#textOffset"))
  if textOffset ~= nil then
    self.textOffset = textOffset
  end
  local textSize = getXMLFloat(xmlFile, key .. "#textSize")
  if textSize ~= nil then
    self.textSize = textSize
  end
  local textBold = getXMLBool(xmlFile, key .. "#textBold")
  if textBold ~= nil then
    self.textBold = textBold
  end
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
  end
  local imageColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  local imageDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageDisabledColor"))
  if imageDisabledColor ~= nil then
    self.imageDisabledColor = imageDisabledColor
  end
  local sliderOffset = getXMLFloat(xmlFile, key .. "#sliderOffset")
  if sliderOffset ~= nil then
    self.sliderOffset = sliderOffset
  end
  local sliderSize = self:get2DArray(getXMLString(xmlFile, key .. "#sliderSize"))
  if sliderSize ~= nil then
    self.sliderSize = sliderSize
  end
  if self.sliderBaseImageFilename ~= nil then
    local sliderBaseImageFilename = string.gsub(self.sliderBaseImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.baseOverlay = createImageOverlay(sliderBaseImageFilename)
  end
  if self.sliderImageFilename ~= nil then
    local sliderImageFilename = string.gsub(self.sliderImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.sliderOverlay = createImageOverlay(sliderImageFilename)
  end
end
function SliderElement:saveToXML(xmlFile, key)
  SliderElement:superClass().saveToXML(self, xmlFile, key)
end
function SliderElement:loadProfile(profile)
  SliderElement:superClass().loadProfile(self, profile)
  local sliderBaseImageFilename = profile:getValue("sliderBaseImageFilename")
  if sliderBaseImageFilename ~= nil then
    self.sliderBaseImageFilename = sliderBaseImageFilename
  end
  local sliderImageFilename = profile:getValue("sliderImageFilename")
  if sliderImageFilename ~= nil then
    self.sliderImageFilename = sliderImageFilename
  end
  local direction = profile:getValue("direction")
  if direction ~= nil then
    if direction == "y" then
      self.direction = SliderElement.DIRECTION_Y
    elseif direction == "x" then
      self.direction = SliderElement.DIRECTION_X
    end
  end
  local showValue = profile:getValue("showValue")
  if showValue ~= nil then
    self.showValue = showValue:lower() == "true"
  end
  local textColor = self:getColorArray(profile:getValue("textColor"))
  if textColor ~= nil then
    self.textColor = textColor
  end
  local textDisabledColor = self:getColorArray(profile:getValue("textDisabledColor"))
  if textDisabledColor ~= nil then
    self.textDisabledColor = textDisabledColor
  end
  local textOffset = self:get2DArray(profile:getValue("textOffset"))
  if textOffset ~= nil then
    self.textOffset = textOffset
  end
  local textSize = tonumber(profile:getValue("textSize"))
  if textSize ~= nil then
    self.textSize = textSize
  end
  local textBold = profile:getValue("textBold")
  if textBold ~= nil then
    self.textBold = textBold:lower() == "true"
  end
  local imageColor = self:getColorArray(profile:getValue("imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  local imageDisabledColor = self:getColorArray(profile:getValue("imageDisabledColor"))
  if imageDisabledColor ~= nil then
    self.imageDisabledColor = imageDisabledColor
  end
  local sliderOffset = tonumber(profile:getValue("sliderOffset"))
  if sliderOffset ~= nil then
    self.sliderOffset = sliderOffset
  end
  local sliderSize = self:get2DArray(profile:getValue("sliderSize"))
  if sliderSize ~= nil then
    self.sliderSize = sliderSize
  end
end
function SliderElement:copyAttributes(src)
  SliderElement:superClass().copyAttributes(self, src)
  self.sliderBaseImageFilename = src.sliderBaseImageFilename
  if self.sliderBaseImageFilename ~= nil then
    local sliderBaseImageFilename = string.gsub(self.sliderBaseImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.baseOverlay = createImageOverlay(sliderBaseImageFilename)
  end
  self.sliderImageFilename = src.sliderImageFilename
  if self.sliderImageFilename ~= nil then
    local sliderImageFilename = string.gsub(self.sliderImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.baseOverlay = createImageOverlay(sliderImageFilename)
  end
  self.direction = src.direction
  self.showValue = self.showValue
  self.minValue = src.minValue
  self.maxValue = src.maxValue
  self.currentValue = src.currentValue
  self.minSliderPos = src.minSliderPos
  self.maxSliderPos = src.maxSliderPos
  self.stepSize = src.stepSize
  self.onClick = src.onClick
  self.onChanged = src.onChanged
  self.textColor = {
    src.textColor[1],
    src.textColor[2],
    src.textColor[3],
    src.textColor[4]
  }
  self.textDisabledColor = {
    src.textDisabledColor[1],
    src.textDisabledColor[2],
    src.textDisabledColor[3],
    src.textDisabledColor[4]
  }
  self.textOffset = {
    src.textOffset[1],
    src.textOffset[2]
  }
  self.text2Offset = {
    src.text2Offset[1],
    src.text2Offset[2]
  }
  self.textSize = src.textSize
  self.textBold = src.textBold
  self.disabled = src.disabled
  self.imageColor = {
    src.imageColor[1],
    src.imageColor[2],
    src.imageColor[3],
    src.imageColor[4]
  }
  self.imageDisabledColor = {
    src.imageDisabledColor[1],
    src.imageDisabledColor[2],
    src.imageDisabledColor[3],
    src.imageDisabledColor[4]
  }
  self.sliderOffset = src.sliderOffset
  self.sliderSize = {
    src.sliderSize[1],
    src.sliderSize[2]
  }
end
function SliderElement:onOpen()
  SliderElement:superClass().onOpen(self)
end
function SliderElement:onClose()
  SliderElement:superClass().onClose(self)
end
function SliderElement:getIsActive()
  return not self.disabled and self.visible
end
function SliderElement:setDisabled(disabled)
  self.disabled = disabled
end
function SliderElement:setTexts(texts)
  self.valueTexts = texts
end
function SliderElement:setValue(newValue)
  local oldNew = newValue
  local rem = (newValue - self.minValue) % self.stepSize
  if rem >= self.stepSize - rem then
    newValue = newValue + self.stepSize - rem
  else
    newValue = newValue - rem
  end
  newValue = math.min(math.max(newValue, self.minValue), self.maxValue)
  local numDecimalPlaces = 5
  local mult = 10 ^ numDecimalPlaces
  newValue = math.floor(newValue * mult + 0.5) / mult
  if newValue ~= self.currentValue then
    self.currentValue = newValue
    self:updateSliderPosition()
    self:callOnChanged()
    return true
  end
  return false
end
function SliderElement:setMinValue(minValue)
  self.minValue = minValue
  self:setValue(self.currentValue)
  self:updateSliderPosition()
end
function SliderElement:setMaxValue(maxValue)
  self.maxValue = maxValue
  self:setValue(self.currentValue)
  self:updateSliderPosition()
end
function SliderElement:updateAbsolutePosition()
  SliderElement:superClass().updateAbsolutePosition(self)
  self:updateSliderLimits()
end
function SliderElement:setSize(x, y)
  SliderElement:superClass().setSize(self, x, y)
  self:updateSliderLimits()
end
function SliderElement:updateSliderLimits()
  local axis = 1
  if self.direction == SliderElement.DIRECTION_Y then
    axis = 2
  end
  self.minAbsSliderPos = self.absPosition[axis] + self.size[axis] * self.minSliderPos + self.sliderSize[axis] * 0.5
  self.maxAbsSliderPos = self.absPosition[axis] + self.size[axis] * self.maxSliderPos - self.sliderSize[axis] * 0.5
  self:updateSliderPosition()
end
function SliderElement:getOverlayColor()
  if self.disabled then
    return self.imageDisabledColor
  end
  return self.imageColor
end
function SliderElement:getTextColor()
  if self.disabled then
    return self.textDisabledColor
  else
    return self.textColor
  end
end
function SliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if SliderElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    if self.mouseDown and isUp and button == Input.MOUSE_BUTTON_LEFT then
      eventUsed = true
      self.mouseDown = false
      if self.onClick ~= nil then
        if self.target ~= nil then
          self.onClick(self.target, self.currentValue)
        else
          self.onClick(self.currentValue)
        end
      end
    end
    if not eventUsed and (self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) or self:checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2])) then
      FocusManager:setFocus(self)
      eventUsed = true
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
        self:setValue(self.currentValue + self.stepSize)
      end
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
        self:setValue(self.currentValue - self.stepSize)
      end
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
      end
    end
    if self.mouseDown then
      eventUsed = true
      local newValue = 0
      local mousePos = posX
      if self.direction == SliderElement.DIRECTION_Y then
        mousePos = posY
      end
      newValue = self.minValue + (mousePos - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos) * (self.maxValue - self.minValue)
      self:setValue(newValue)
    end
  end
  return eventUsed
end
function SliderElement:updateSliderPosition()
  local axis1 = 1
  local axis2 = 2
  if self.direction == SliderElement.DIRECTION_Y then
    axis1 = 2
    axis2 = 1
  end
  self.sliderPosition[axis2] = self.absPosition[axis2] + self.sliderOffset
  self.sliderPosition[axis1] = self.minAbsSliderPos + (self.maxAbsSliderPos - self.minAbsSliderPos) * ((self.currentValue - self.minValue) / (self.maxValue - self.minValue)) - self.sliderSize[axis1] * 0.5
end
function SliderElement:callOnChanged()
  if self.onChanged ~= nil then
    if self.target ~= nil then
      self.onChanged(self.target, self.currentValue)
    else
      self.onChanged(self.currentValue)
    end
  end
end
function SliderElement:keyEvent(unicode, sym, modifier, isDown)
  if self:getIsActive() and SliderElement:superClass().keyEvent(self, unicode, sym, modifier, isDown) then
    return true
  end
  return false
end
function SliderElement:update(dt)
  SliderElement:superClass().update(self, dt)
end
function SliderElement:draw()
  if self.visible then
    if self.baseOverlay ~= nil then
      setOverlayColor(self.baseOverlay, unpack(self:getOverlayColor()))
      renderOverlay(self.baseOverlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    if self.sliderOverlay ~= nil then
      setOverlayColor(self.sliderOverlay, unpack(self:getOverlayColor()))
      renderOverlay(self.sliderOverlay, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2])
    end
    local text = tostring(self.currentValue)
    if self.valueTexts ~= nil then
      local valueText = self.valueTexts[self.currentValue]
      if valueText ~= nil then
        text = valueText
      end
    end
    if self.showValue then
      setTextColor(unpack(self.text2Color))
      setTextBold(self.text2Bold)
      renderText(self.absPosition[1] + self.size[1] + self.text2Offset[1], self.absPosition[2] + self.text2Offset[2], self.text2Size, text)
      setTextColor(unpack(self.textColor))
      renderText(self.absPosition[1] + self.size[1] + self.textOffset[1], self.absPosition[2] + self.textOffset[2], self.textSize, text)
      setTextBold(self.textBold)
    end
  end
  SliderElement:superClass().draw(self)
end
function SliderElement:shouldFocusChange(direction)
  local dir1 = FocusManager.LEFT
  local dir2 = FocusManager.RIGHT
  if self.direction == SliderElement.DIRECTION_Y then
    dir1 = FocusManager.BOTTOM
    dir2 = FocusManager.TOP
  end
  if direction == dir1 then
    if self.currentValue <= self.minValue then
      return true
    else
      self:setValue(self.currentValue - self.stepSize)
      if self.onClick ~= nil then
        if self.target ~= nil then
          self.onClick(self.target, self.currentValue)
        else
          self.onClick(self.currentValue)
        end
      end
      return false
    end
  elseif direction == dir2 then
    if self.currentValue >= self.maxValue then
      return true
    else
      self:setValue(self.currentValue + self.stepSize)
      if self.onClick ~= nil then
        if self.target ~= nil then
          self.onClick(self.target, self.currentValue)
        else
          self.onClick(self.currentValue)
        end
      end
      return false
    end
  end
  return true
end
function SliderElement:onFocusLeave()
end
function SliderElement:onFocusEnter()
end
function SliderElement:onFocusActivate()
  if self.onClick ~= nil then
    if self.target ~= nil then
      self.onClick(self.target, self.currentValue)
    else
      self.onClick(self.currentValue)
    end
  end
end
