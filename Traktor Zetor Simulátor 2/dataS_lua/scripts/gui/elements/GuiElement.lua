GuiElement = {}
local GuiElement_mt = Class(GuiElement)
function GuiElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = GuiElement_mt
  end
  local instance = setmetatable({}, custom_mt)
  instance.elements = {}
  instance.target = target
  instance.profile = ""
  instance.position = {0, 0}
  instance.absPosition = {0, 0}
  instance.size = {1, 1}
  instance.visible = true
  return instance
end
function GuiElement:delete()
  for i = table.getn(self.elements), 1, -1 do
    self.elements[i].parent = nil
    self.elements[i]:delete()
  end
  if self.parent ~= nil then
    self.parent:removeElement(self)
  end
  FocusManager:removeElement(self)
end
function GuiElement:loadFromXML(xmlFile, key)
  local profile = getXMLString(xmlFile, key .. "#profile")
  if profile ~= nil then
    self.profile = profile
    local pro = g_gui:getProfile(profile)
    if pro ~= nil then
      self:loadProfile(pro)
    end
  end
  local onCreate = getXMLString(xmlFile, key .. "#onCreate")
  if onCreate ~= nil then
    self.onCreateArgs = getXMLString(xmlFile, key .. "#onCreateArgs")
    if self.target ~= nil then
      self.onCreate = self.target[onCreate]
    else
      loadstring("g_asdasd_tempFuncOnCreate = " .. onCreate)()
      self.onCreate = g_asdasd_tempFuncOnCreate
      g_asdasd_tempFuncOnCreate = nil
    end
  end
  local onOpen = getXMLString(xmlFile, key .. "#onOpen")
  if onOpen ~= nil then
    if self.target ~= nil then
      self.onOpenCallback = self.target[onOpen]
    else
      loadstring("g_asdasd_tempFuncOnOpen = " .. onOpen)()
      self.onOpenCallback = g_asdasd_tempFuncOnOpen
      g_asdasd_tempFuncOnOpen = nil
    end
  end
  local onClose = getXMLString(xmlFile, key .. "#onClose")
  if onClose ~= nil then
    if self.target ~= nil then
      self.onCloseCallback = self.target[onClose]
    else
      loadstring("g_asdasd_tempFuncOnClose = " .. onClose)()
      self.onCloseCallback = g_asdasd_tempFuncOnClose
      g_asdasd_tempFuncOnClose = nil
    end
  end
  local position = self:get2DArray(getXMLString(xmlFile, key .. "#position"))
  if position ~= nil then
    self.position = position
  end
  local size = self:get2DArray(getXMLString(xmlFile, key .. "#size"))
  if size ~= nil then
    self.size = size
  end
  local positionOrigin = getXMLString(xmlFile, key .. "#positionOrigin")
  if positionOrigin ~= nil then
    self:updatePositionForOrigin(positionOrigin)
  end
  local visible = getXMLBool(xmlFile, key .. "#visible")
  if visible ~= nil then
    self.visible = visible
  end
  FocusManager:loadElementFromXML(xmlFile, key, self)
end
function GuiElement:saveToXML(xmlFile, key)
end
function GuiElement:loadProfile(profile)
  local pos = profile:getValue("position")
  if pos ~= nil then
    local x, y = Utils.getVectorFromString(pos)
    if x ~= nil and y ~= nil then
      self.position = {x, y}
    end
  end
  local size = profile:getValue("size")
  if size ~= nil then
    local x, y = Utils.getVectorFromString(size)
    if x ~= nil and y ~= nil then
      self.size = {x, y}
    end
  end
  local positionOrigin = profile:getValue("positionOrigin")
  if positionOrigin ~= nil then
    self:updatePositionForOrigin(positionOrigin)
  end
  local visible = profile:getValue("visible")
  if visible ~= nil then
    self.visible = visible:lower() == "true"
  end
end
function GuiElement:clone(parent)
  local ret = self:new()
  ret:copyAttributes(self)
  if parent ~= nil then
    parent:addElement(ret)
  end
  for i = 1, table.getn(self.elements) do
    self.elements[i]:clone(ret)
  end
  if ret.onCreate ~= nil then
    if ret.target ~= nil then
      ret.onCreate(ret.target, ret, ret.onCreateArgs)
    else
      ret.onCreate(ret, ret.onCreateArgs)
    end
  end
  return ret
end
function GuiElement:copyAttributes(src)
  self.visible = src.visible
  self.position = {
    src.position[1],
    src.position[2]
  }
  self.size = {
    src.size[1],
    src.size[2]
  }
  self.onCreate = src.onCreate
  self.onCreateArgs = src.onCreateArgs
  self.onCloseCallback = src.onCloseCallback
  self.onOpenCallback = src.onOpenCallback
  self.target = src.target
  self.profile = src.profile
end
function GuiElement:addElement(element)
  table.insert(self.elements, element)
  element.parent = self
end
function GuiElement:removeElement(element)
  for i, v in ipairs(self.elements) do
    if v == element then
      table.remove(self.elements, i)
      element.parent = nil
      break
    end
  end
end
function GuiElement:updateAbsolutePosition()
  if self.parent ~= nil then
    self.absPosition[1] = self.position[1] + self.parent.absPosition[1]
    self.absPosition[2] = self.position[2] + self.parent.absPosition[2]
  else
    self.absPosition[1] = self.position[1]
    self.absPosition[2] = self.position[2]
  end
  for k, v in ipairs(self.elements) do
    v:updateAbsolutePosition()
  end
end
function GuiElement:onOpen()
  if self.onOpenCallback ~= nil then
    if self.target ~= nil then
      self.onOpenCallback(self.target, self)
    else
      self.onOpenCallback(self)
    end
  end
  for k, v in ipairs(self.elements) do
    v:onOpen()
  end
end
function GuiElement:onClose()
  if self.onCloseCallback ~= nil then
    if self.target ~= nil then
      self.onCloseCallback(self.target, self)
    else
      self.onCloseCallback(self)
    end
  end
  for k, v in ipairs(self.elements) do
    v:onClose()
  end
end
function GuiElement:reset()
  for k, v in ipairs(self.elements) do
    v:reset()
  end
end
function GuiElement:setPosition(x, y)
  self.position = {x, y}
  self:updateAbsolutePosition()
end
function GuiElement:setSize(x, y)
  self.size = {x, y}
end
function GuiElement:setVisible(visible)
  self.visible = visible
end
function GuiElement:getIsVisible()
  if not self.visible then
    return false
  end
  if self.parent ~= nil then
    return self.parent:getIsVisible()
  end
  return true
end
function GuiElement:setDisabled(disabled)
  for i = 1, table.getn(self.elements) do
    self.elements[i]:setDisabled(disabled)
  end
end
function GuiElement:getColorArray(colorStr)
  local r, g, b, a = Utils.getVectorFromString(colorStr)
  if r ~= nil and g ~= nil and b ~= nil and a ~= nil then
    return {
      r,
      g,
      b,
      a
    }
  end
  return nil
end
function GuiElement:get2DArray(str)
  if str ~= nil then
    local parts = Utils.splitString(" ", str)
    local x, y = unpack(parts)
    if x ~= nil and y ~= nil then
      return {
        self:evaluateFormula(x),
        self:evaluateFormula(y)
      }
    end
  end
  return nil
end
function GuiElement:checkOverlayOverlap(posX, posY, overlayX, overlayY, overlaySizeX, overlaySizeY)
  return overlayX <= posX and posX <= overlayX + overlaySizeX and overlayY <= posY and posY <= overlayY + overlaySizeY
end
function GuiElement:mouseEvent(posX, posY, isDown, isUp, button)
  local ret = false
  if self.visible then
    for i = table.getn(self.elements), 1, -1 do
      local v = self.elements[i]
      if v:mouseEvent(posX, posY, isDown, isUp, button) then
        ret = true
      end
    end
  end
  return ret
end
function GuiElement:keyEvent(unicode, sym, modifier, isDown)
  local eventUsed = false
  if self.visible then
    for i = table.getn(self.elements), 1, -1 do
      local v = self.elements[i]
      if v:keyEvent(unicode, sym, modifier, isDown, eventUsed) then
        eventUsed = true
      end
    end
  end
  return eventUsed
end
function GuiElement:update(dt)
  FocusManager:checkElement(self, dt)
  for k, v in ipairs(self.elements) do
    v:update(dt)
  end
end
function GuiElement:draw()
  if self.visible then
    for k, v in ipairs(self.elements) do
      v:draw()
    end
  end
end
function GuiElement:shouldFocusChange(direction)
  for _, v in ipairs(self.elements) do
    if not v:shouldFocusChange(direction) then
      return false
    end
  end
  return true
end
function GuiElement:canReceiveFocus()
  if not self.visible then
    return false
  end
  for _, v in ipairs(self.elements) do
    if not v:canReceiveFocus() then
      return false
    end
  end
  return true
end
function GuiElement:onFocusLeave()
  for _, v in ipairs(self.elements) do
    v:onFocusLeave()
  end
end
function GuiElement:onFocusEnter()
  for _, v in ipairs(self.elements) do
    v:onFocusEnter()
  end
end
function GuiElement:onFocusActivate()
  for _, v in ipairs(self.elements) do
    v:onFocusActivate()
  end
end
function GuiElement:evaluateFormula(str)
  if str:find("[_%a]") == nil then
    local f = loadstring("g_asd_tempMathValue = " .. str)
    if f ~= nil then
      f()
      str = g_asd_tempMathValue
      g_asd_tempMathValue = nil
    end
  end
  return tonumber(str)
end
function GuiElement:updatePositionForOrigin(origin)
  if origin == "topLeft" then
    self.position[2] = self.position[2] - self.size[2]
  elseif origin == "topRight" then
    self.position[1] = self.position[1] - self.size[1]
    self.position[2] = self.position[2] - self.size[2]
  elseif origin == "bottomRight" then
    self.position[1] = self.position[1] - self.size[1]
  elseif origin == "bottomCenter" then
    self.position[1] = self.position[1] - self.size[1] * 0.5
  elseif origin == "topCenter" then
    self.position[1] = self.position[1] - self.size[1] * 0.5
    self.position[2] = self.position[2] - self.size[2]
  elseif origin == "centerLeft" then
    self.position[2] = self.position[2] - self.size[2] * 0.5
  elseif origin == "centerRight" then
    self.position[1] = self.position[1] - self.size[1]
    self.position[2] = self.position[2] - self.size[2] * 0.5
  elseif origin == "center" then
    self.position[1] = self.position[1] - self.size[1] * 0.5
    self.position[2] = self.position[2] - self.size[2] * 0.5
  end
end
