TextElement = {}
local TextElement_mt = Class(TextElement, GuiElement)
function TextElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = TextElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.textColor = {
    1,
    1,
    1,
    1
  }
  instance.textDisabledColor = {
    0.5,
    0.5,
    0.5,
    1
  }
  instance.textOffset = {0, 0}
  instance.textSize = 0.03
  instance.textBold = false
  instance.text2Color = {
    1,
    1,
    1,
    1
  }
  instance.text2DisabledColor = {
    1,
    1,
    1,
    0
  }
  instance.text2Offset = {0, 0}
  instance.text2Size = 0
  instance.text2Bold = false
  instance.alignment = RenderText.ALIGN_CENTER
  instance.textWrapWidth = 1
  instance.disabled = false
  return instance
end
function TextElement:loadFromXML(xmlFile, key)
  TextElement:superClass().loadFromXML(self, xmlFile, key)
  local text = getXMLString(xmlFile, key .. "#text")
  if text ~= nil then
    if text:sub(1, 6) == "$l10n_" then
      text = g_i18n:getText(text:sub(7))
    end
    self.text = text
  end
  local textColor = self:getColorArray(getXMLString(xmlFile, key .. "#textColor"))
  if textColor ~= nil then
    self.textColor = textColor
  end
  local textDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#textDisabledColor"))
  if textDisabledColor ~= nil then
    self.textDisabledColor = textDisabledColor
  end
  local text2DisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#text2DisabledColor"))
  if text2DisabledColor ~= nil then
    self.text2DisabledColor = text2DisabledColor
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
  local text2Color = self:getColorArray(getXMLString(xmlFile, key .. "#text2Color"))
  if text2Color ~= nil then
    self.text2Color = text2Color
  end
  local text2Offset = self:get2DArray(getXMLString(xmlFile, key .. "#text2Offset"))
  if text2Offset ~= nil then
    self.text2Offset = text2Offset
  end
  local text2Size = getXMLFloat(xmlFile, key .. "#text2Size")
  if text2Size ~= nil then
    self.text2Size = text2Size
  end
  local text2Bold = getXMLBool(xmlFile, key .. "#text2Bold")
  if text2Bold ~= nil then
    self.text2Bold = text2Bold
  end
  local alignment = getXMLString(xmlFile, key .. "#alignment")
  if alignment ~= nil then
    alignment = alignment:lower()
    if alignment == "right" then
      self.alignment = RenderText.ALIGN_RIGHT
    elseif alignment == "center" then
      self.alignment = RenderText.ALIGN_CENTER
    else
      self.alignment = RenderText.ALIGN_LEFT
    end
  end
  local textWrapWidth = getXMLFloat(xmlFile, key .. "#textWrapWidth")
  if textWrapWidth ~= nil then
    self.textWrapWidth = textWrapWidth
  end
end
function TextElement:saveToXML(xmlFile, key)
  TextElement:superClass().saveToXML(self, xmlFile, key)
end
function TextElement:loadProfile(profile)
  TextElement:superClass().loadProfile(self, profile)
  local textColor = self:getColorArray(profile:getValue("textColor"))
  if textColor ~= nil then
    self.textColor = textColor
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
  local text2Color = self:getColorArray(profile:getValue("text2Color"))
  if text2Color ~= nil then
    self.text2Color = text2Color
  end
  local text2Offset = self:get2DArray(profile:getValue("text2Offset"))
  if text2Offset ~= nil then
    self.text2Offset = text2Offset
  end
  local text2Size = tonumber(profile:getValue("text2Size"))
  if text2Size ~= nil then
    self.text2Size = text2Size
  end
  local text2Bold = profile:getValue("text2Bold")
  if text2Bold ~= nil then
    self.text2Bold = text2Bold:lower() == "true"
  end
  local alignment = profile:getValue("alignment")
  if alignment ~= nil then
    alignment = alignment:lower()
    if alignment == "right" then
      self.alignment = RenderText.ALIGN_RIGHT
    elseif alignment == "center" then
      self.alignment = RenderText.ALIGN_CENTER
    else
      self.alignment = RenderText.ALIGN_LEFT
    end
  end
  local textWrapWidth = tonumber(profile:getValue("textWrapWidth"))
  if textWrapWidth ~= nil then
    self.textWrapWidth = textWrapWidth
  end
end
function TextElement:copyAttributes(src)
  TextElement:superClass().copyAttributes(self, src)
  self.text = src.text
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
  self.text2Color = {
    src.text2Color[1],
    src.text2Color[2],
    src.text2Color[3],
    src.text2Color[4]
  }
  self.text2DisabledColor = {
    src.text2DisabledColor[1],
    src.text2DisabledColor[2],
    src.text2DisabledColor[3],
    src.text2DisabledColor[4]
  }
  self.textBold = src.textBold
  self.text2Size = src.text2Size
  self.text2Bold = src.text2Bold
  self.alignment = src.alignment
  self.textWrapWidth = src.textWrapWidth
end
function TextElement:onOpen()
  TextElement:superClass().onOpen(self)
end
function TextElement:onClose()
  TextElement:superClass().onClose(self)
end
function TextElement:setText(text)
  self.text = text
end
function TextElement:setDisabled(disabled)
  self.disabled = disabled
end
function TextElement:setTextColor(r, g, b, a)
  self.textColor = {
    r,
    g,
    b,
    a
  }
end
function TextElement:getTextColor()
  if self.disabled then
    return self.textDisabledColor
  else
    return self.textColor
  end
end
function TextElement:setText2Color(r, g, b, a)
  self.text2Color = {
    r,
    g,
    b,
    a
  }
end
function TextElement:getText2Color()
  if self.disabled then
    return self.text2DisabledColor
  else
    return self.text2Color
  end
end
function TextElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  TextElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function TextElement:keyEvent(unicode, sym, modifier, isDown)
  TextElement:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function TextElement:update(dt)
  TextElement:superClass().update(self, dt)
end
function TextElement:draw()
  if self.visible and self.text ~= nil and self.text ~= "" then
    setTextAlignment(self.alignment)
    local xPos = self.absPosition[1]
    if self.alignment == RenderText.ALIGN_CENTER then
      xPos = xPos + self.size[1] * 0.5
    elseif self.alignment == RenderText.ALIGN_RIGHT then
      xPos = xPos + self.size[1]
    end
    setTextWrapWidth(self.textWrapWidth)
    if self.text2Size > 0 then
      setTextBold(self.text2Bold)
      setTextColor(unpack(self:getText2Color()))
      renderText(xPos + self.text2Offset[1], self.absPosition[2] + self.text2Offset[2], self.text2Size, self.text)
    end
    setTextBold(self.textBold)
    setTextColor(unpack(self:getTextColor()))
    renderText(xPos + self.textOffset[1], self.absPosition[2] + self.textOffset[2], self.textSize, self.text)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextWrapWidth(0)
  end
  TextElement:superClass().draw(self)
end
