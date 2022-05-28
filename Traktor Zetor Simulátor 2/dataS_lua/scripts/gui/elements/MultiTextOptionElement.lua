MultiTextOptionElement = {}
local MultiTextOptionElement_mt = Class(MultiTextOptionElement, GuiElement)
function MultiTextOptionElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = MultiTextOptionElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.isChecked = false
  instance.disabled = false
  instance.state = 1
  instance.texts = {}
  return instance
end
function MultiTextOptionElement:loadFromXML(xmlFile, key)
  MultiTextOptionElement:superClass().loadFromXML(self, xmlFile, key)
  local isChecked = getXMLBool(xmlFile, key .. "#isChecked")
  if isChecked ~= nil then
    self:setIsChecked(isChecked)
  end
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
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
  local text = getXMLString(xmlFile, key .. "#texts")
  if text ~= nil then
    self.texts = Utils.splitString("|", text)
  end
end
function MultiTextOptionElement:saveToXML(xmlFile, key)
  MultiTextOptionElement:superClass().saveToXML(self, xmlFile, key)
end
function MultiTextOptionElement:loadProfile(profile)
  MultiTextOptionElement:superClass().loadProfile(self, profile)
end
function MultiTextOptionElement:copyAttributes(src)
  MultiTextOptionElement:superClass().copyAttributes(self, src)
  self.isChecked = src.isChecked
  self.disabled = src.disabled
  self.onClick = src.onClick
  self.text = src.text
end
function MultiTextOptionElement:onOpen()
  MultiTextOptionElement:superClass().onOpen(self)
end
function MultiTextOptionElement:onClose()
  MultiTextOptionElement:superClass().onClose(self)
end
function MultiTextOptionElement:setState(state)
  self.state = math.max(math.min(state, table.getn(self.texts)), 1)
  self:updateTextElement()
end
function MultiTextOptionElement:setDisabled(disabled)
  self.disabled = disabled
  if self.elements[1] ~= nil then
    self.elements[1]:setDisabled(self.disabled)
  end
  if self.elements[2] ~= nil then
    self.elements[2]:setDisabled(self.disabled)
  end
end
function MultiTextOptionElement:addElement(element)
  MultiTextOptionElement:superClass().addElement(self, element)
  if table.getn(self.elements) == 1 then
    element.target = self
    element.onClick = MultiTextOptionElement.onLeftButtonClicked
    self:setDisabled(self.disabled)
  elseif table.getn(self.elements) == 2 then
    element.target = self
    element.onClick = MultiTextOptionElement.onRightButtonClicked
    self:setDisabled(self.disabled)
  elseif table.getn(self.elements) == 3 then
    self.textElement = element
    self:updateTextElement()
  end
end
function MultiTextOptionElement:addText(text, i)
  if i == nil then
    table.insert(self.texts, text)
  else
    table.insert(self.texts, i, text)
  end
  self:updateTextElement()
end
function MultiTextOptionElement:setTexts(texts)
  self.texts = texts
  self.state = math.min(self.state, table.getn(self.texts))
  self:updateTextElement()
end
function MultiTextOptionElement:getIsActive()
  return not self.disabled and self.visible
end
function MultiTextOptionElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    return MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
  end
  return false
end
function MultiTextOptionElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
  return MultiTextOptionElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
end
function MultiTextOptionElement:update(dt)
  MultiTextOptionElement:superClass().update(self, dt)
end
function MultiTextOptionElement:draw()
  MultiTextOptionElement:superClass().draw(self)
end
function MultiTextOptionElement:onRightButtonClicked()
  self.state = math.min(self.state + 1, table.getn(self.texts))
  self:updateTextElement()
  if self.onClick ~= nil then
    if self.target ~= nil then
      self.onClick(self.target, self.state)
    else
      self.onClick(self.state)
    end
  end
end
function MultiTextOptionElement:onLeftButtonClicked()
  self.state = math.max(self.state - 1, 1)
  self:updateTextElement()
  if self.onClick ~= nil then
    if self.target ~= nil then
      self.onClick(self.target, self.state)
    else
      self.onClick(self.state)
    end
  end
end
function MultiTextOptionElement:updateTextElement()
  if self.texts[self.state] ~= nil then
    self.textElement:setText(self.texts[self.state])
  else
    self.textElement:setText("")
  end
end
