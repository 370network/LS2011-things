ToggleButtonElement = {}
local ToggleButtonElement_mt = Class(ToggleButtonElement, GuiElement)
function ToggleButtonElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = ToggleButtonElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.isChecked = false
  instance.disabled = false
  return instance
end
function ToggleButtonElement:loadFromXML(xmlFile, key)
  ToggleButtonElement:superClass().loadFromXML(self, xmlFile, key)
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
end
function ToggleButtonElement:saveToXML(xmlFile, key)
  ToggleButtonElement:superClass().saveToXML(self, xmlFile, key)
end
function ToggleButtonElement:loadProfile(profile)
  ToggleButtonElement:superClass().loadProfile(self, profile)
end
function ToggleButtonElement:copyAttributes(src)
  ToggleButtonElement:superClass().copyAttributes(self, src)
  self.isChecked = src.isChecked
  self.disabled = src.disabled
  self.onClick = src.onClick
end
function ToggleButtonElement:onOpen()
  ToggleButtonElement:superClass().onOpen(self)
end
function ToggleButtonElement:onClose()
  ToggleButtonElement:superClass().onClose(self)
end
function ToggleButtonElement:setIsChecked(isChecked)
  self.isChecked = isChecked
  if self.elements[1] ~= nil then
    self.elements[1]:setVisible(self.isChecked)
  end
  if self.elements[2] ~= nil then
    self.elements[2]:setVisible(not self.isChecked)
  end
end
function ToggleButtonElement:setDisabled(disabled)
  self.disabled = disabled
  if self.elements[1] ~= nil then
    self.elements[1]:setDisabled(self.disabled)
  end
  if self.elements[2] ~= nil then
    self.elements[2]:setDisabled(self.disabled)
  end
end
function ToggleButtonElement:addElement(element)
  ToggleButtonElement:superClass().addElement(self, element)
  if table.getn(self.elements) <= 2 then
    element.target = self
    element.onClick = ToggleButtonElement.onButtonClicked
    self:setIsChecked(self.isChecked)
    self:setDisabled(self.disabled)
  end
end
function ToggleButtonElement:getIsActive()
  return not self.disabled and self.visible
end
function ToggleButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if not eventUsed and self:checkOverlayOverlap(posX, posY, self.elements[1].absPosition[1], self.elements[1].absPosition[2], self.elements[1].size[1], self.elements[1].size[2]) then
      FocusManager:setFocus(self)
    end
    return ToggleButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
  end
  return false
end
function ToggleButtonElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
  return ToggleButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
end
function ToggleButtonElement:update(dt)
  ToggleButtonElement:superClass().update(self, dt)
end
function ToggleButtonElement:draw()
  ToggleButtonElement:superClass().draw(self)
end
function ToggleButtonElement:onButtonClicked()
  self:setIsChecked(not self.isChecked)
  if self.onClick ~= nil then
    if self.target ~= nil then
      self.onClick(self.target, self.isChecked)
    else
      self.onClick(self.isChecked)
    end
  end
end
function ToggleButtonElement:canReceiveFocus()
  return not self.disabled and not not self.visible
end
function ToggleButtonElement:onFocusLeave()
  if self.elements[1] ~= nil then
    self.elements[1]:onFocusLeave()
  end
  if self.elements[2] ~= nil then
    self.elements[2]:onFocusLeave()
  end
end
function ToggleButtonElement:onFocusEnter()
  if self.elements[1] ~= nil then
    self.elements[1]:onFocusEnter()
  end
  if self.elements[2] ~= nil then
    self.elements[2]:onFocusEnter()
  end
end
function ToggleButtonElement:onFocusActivate()
  self:onButtonClicked()
end
