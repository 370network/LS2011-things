MouseControlsVehicle = {}
MouseControlsVehicle.BUTTON_NONE = 0
MouseControlsVehicle.BUTTON_LEFT = 1
MouseControlsVehicle.BUTTON_RIGHT = 2
MouseControlsVehicle.BUTTON_MIDDLE = 3
MouseControlsVehicle.BUTTON_LEFTRIGHT = 4
MouseControlsVehicle.AXIS_NONE = 0
MouseControlsVehicle.AXIS_X = 1
MouseControlsVehicle.AXIS_Y = 2
function MouseControlsVehicle.prerequisitesPresent(specializations)
  return true
end
function MouseControlsVehicle:load(xmlFile)
  self.mouseButton = MouseControlsVehicle.BUTTON_NONE
  self.mouseAxis = MouseControlsVehicle.AXIS_NONE
  self.mouseDirectionX = 0
  self.mouseDirectionY = 0
  self.mouseControlAxisX = ""
  self.mouseControlAxisY = ""
  self.mouseControlsIconFilenames = {}
  self.mouseControlsAxes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.mouseControls.mouseControl(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local iconFilename = getXMLString(xmlFile, key .. "#iconFilename")
    local mouseButtonStr = getXMLString(xmlFile, key .. "#mouseButton")
    local mouseAxisStr = getXMLString(xmlFile, key .. "#mouseAxis")
    if iconFilename ~= nil and mouseButtonStr ~= nil and mouseAxisStr ~= nil then
      local mouseButton = MouseControlsVehicle.convertMouseButtonString(mouseButtonStr)
      local mouseAxis = MouseControlsVehicle.convertMouseAxisString(mouseAxisStr)
      if mouseButton ~= MouseControlsVehicle.BUTTON_NONE and mouseAxis ~= MouseControlsVehicle.AXIS_NONE then
        iconFilename = Utils.getFilename(iconFilename, self.baseDirectory)
        g_mouseControlsHelp:addIconFilename(iconFilename)
        if self.mouseControlsIconFilenames[mouseButton] == nil then
          self.mouseControlsIconFilenames[mouseButton] = {}
        end
        self.mouseControlsIconFilenames[mouseButton][mouseAxis] = iconFilename
        local axis = getXMLString(xmlFile, key .. "#axis")
        if axis ~= nil then
          if self.mouseControlsAxes[mouseButton] == nil then
            self.mouseControlsAxes[mouseButton] = {}
          end
          self.mouseControlsAxes[mouseButton][mouseAxis] = axis
        end
      end
    end
    i = i + 1
  end
end
function MouseControlsVehicle:delete()
end
function MouseControlsVehicle:mouseEvent(posX, posY, isDown, isUp, button)
  local posXDelta = InputBinding.mouseMovementX
  local posYDelta = -InputBinding.mouseMovementY
  if math.abs(posXDelta) > math.abs(posYDelta) then
    if 5.0E-4 < posXDelta then
      self.mouseDirectionX = self.mouseDirectionX + math.min(1.5 * (posXDelta / 0.02), 4)
    elseif posXDelta < -5.0E-4 then
      self.mouseDirectionX = self.mouseDirectionX + math.max(1.5 * (posXDelta / 0.02), -4)
    end
  elseif 5.0E-4 < posYDelta then
    self.mouseDirectionY = self.mouseDirectionY + math.min(1.5 * (posYDelta / 0.02), 4)
  elseif posYDelta < -5.0E-4 then
    self.mouseDirectionY = self.mouseDirectionY + math.max(1.5 * (posYDelta / 0.02), -4)
  end
  if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) and Input.isMouseButtonPressed(Input.MOUSE_BUTTON_RIGHT) then
    self.mouseButton = MouseControlsVehicle.BUTTON_LEFTRIGHT
    g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_LEFTRIGHT)
  elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) then
    self.mouseButton = MouseControlsVehicle.BUTTON_LEFT
    g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_LEFT)
  elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_RIGHT) then
    self.mouseButton = MouseControlsVehicle.BUTTON_RIGHT
    g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_RIGHT)
  elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_MIDDLE) then
    self.mouseButton = MouseControlsVehicle.BUTTON_MIDDLE
    g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_MIDDLE)
  else
    self.mouseButton = MouseControlsVehicle.BUTTON_NONE
    g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_NONE)
  end
  self.mouseControlAxisX = ""
  self.mouseControlAxisY = ""
  if self.mouseButton ~= MouseControlsVehicle.BUTTON_NONE then
    local xFilename = ""
    local yFilename = ""
    local buttonFilenames = self.mouseControlsIconFilenames[self.mouseButton]
    if buttonFilenames ~= nil then
      xFilename = buttonFilenames[MouseControlsVehicle.AXIS_X] or xFilename
      yFilename = buttonFilenames[MouseControlsVehicle.AXIS_Y] or yFilename
    end
    g_mouseControlsHelp:setIconFilename(xFilename, yFilename)
    local buttonAxes = self.mouseControlsAxes[self.mouseButton]
    if buttonAxes ~= nil then
      self.mouseControlAxisX = buttonAxes[MouseControlsVehicle.AXIS_X] or self.mouseControlAxisX
      self.mouseControlAxisY = buttonAxes[MouseControlsVehicle.AXIS_Y] or self.mouseControlAxisY
    end
  end
end
function MouseControlsVehicle:keyEvent(unicode, sym, modifier, isDown)
end
function MouseControlsVehicle:update(dt)
end
function MouseControlsVehicle:postUpdateTick(dt)
  self.mouseDirectionY = 0
  self.mouseDirectionX = 0
end
function MouseControlsVehicle:draw()
end
function MouseControlsVehicle:onLeave()
  g_mouseControlsHelp:setMouseButton(MouseControlsHelp.BUTTON_NONE)
end
function MouseControlsVehicle.convertMouseButtonString(mouseButton)
  if mouseButton ~= nil then
    mouseButton = mouseButton:lower()
    if mouseButton == "left" then
      return MouseControlsVehicle.BUTTON_LEFT
    elseif mouseButton == "right" then
      return MouseControlsVehicle.BUTTON_RIGHT
    elseif mouseButton == "leftright" then
      return MouseControlsVehicle.BUTTON_LEFTRIGHT
    end
  end
  return MouseControlsVehicle.BUTTON_NONE
end
function MouseControlsVehicle.convertMouseAxisString(mouseAxis)
  if mouseAxis ~= nil then
    mouseAxis = mouseAxis:lower()
    if mouseAxis == "x" then
      return MouseControlsVehicle.AXIS_X
    elseif mouseAxis == "y" then
      return MouseControlsVehicle.AXIS_Y
    end
  end
  return MouseControlsVehicle.AXIS_NONE
end
