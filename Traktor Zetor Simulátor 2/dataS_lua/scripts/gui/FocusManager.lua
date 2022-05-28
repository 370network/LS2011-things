FocusManager = {
  TOP = 1,
  BOTTOM = 2,
  LEFT = 3,
  RIGHT = 4,
  DELAY_TIME = 500,
  DELAY_TIME_MIN = 50
}
FocusManager.guiFocusData = {}
FocusManager.delays = {}
FocusManager.delaysNext = {}
FocusManager.opposingDirectionsHash = {
  [FocusManager.TOP] = FocusManager.BOTTOM,
  [FocusManager.BOTTOM] = FocusManager.TOP,
  [FocusManager.LEFT] = FocusManager.RIGHT,
  [FocusManager.RIGHT] = FocusManager.LEFT
}
function FocusManager:setGui(gui)
  if self.currentFocusData then
    local focusElement = self.currentFocusData.focusElement
    if focusElement then
      FocusManager:unsetFocus(focusElement)
    end
  end
  self.currentFocusData = self.guiFocusData[gui]
  if not self.currentFocusData then
    self.guiFocusData[gui] = {}
    self.guiFocusData[gui].idToElementMapping = {}
    self.currentFocusData = self.guiFocusData[gui]
  else
    local focusElement = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement
    if focusElement then
      FocusManager:setFocus(focusElement)
      if not self.focusSystemMadeChanges then
        FocusManager:unsetFocus(focusElement)
      end
    end
  end
  self.delaysNext[FocusManager.TOP] = FocusManager.DELAY_TIME
  self.delaysNext[FocusManager.BOTTOM] = FocusManager.DELAY_TIME
  self.delaysNext[FocusManager.LEFT] = FocusManager.DELAY_TIME
  self.delaysNext[FocusManager.RIGHT] = FocusManager.DELAY_TIME
end
function FocusManager:getElementById(id)
  return self.currentFocusData.idToElementMapping[id]
end
function FocusManager:getFocusedElement()
  return self.currentFocusData.focusElement
end
function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
  local focusId = getXMLString(xmlFile, xmlBaseNode .. "#focusId")
  if not focusId then
    return
  end
  element.focusId = focusId
  element.focusChangeData = {}
  element.focusChangeData[FocusManager.TOP] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeTop")
  element.focusChangeData[FocusManager.BOTTOM] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeBottom")
  element.focusChangeData[FocusManager.LEFT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeLeft")
  element.focusChangeData[FocusManager.RIGHT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeRight")
  element.focusActive = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") ~= nil
  local isAlwaysFocusedOnOpen = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") == "onOpen"
  local focusChangeOverride = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeOverride")
  if focusChangeOverride then
    if element.target then
      element.focusChangeOverride = element.target[focusChangeOverride]
    else
      loadstring("g_asdasd_tempFuncOnClose = " .. focusChangeOverride)()
      element.focusChangeOverride = g_asdasd_tempFuncOnClose
      g_asdasd_tempFuncOnClose = nil
    end
  end
  self.currentFocusData.idToElementMapping[focusId] = element
  if element.focusActive then
    self.currentFocusData.initialFocusElement = isAlwaysFocusedOnOpen and element
    self:setFocus(element)
  elseif not self.currentFocusData.focusElement then
    self.currentFocusData.focusElement = element
  end
end
function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
  if not focusId then
    return
  end
  element.focusId = focusId
  element.focusChangeData = focusChangeData
  element.focusActive = focusActive
  if self.currentFocusData.idToElementMapping[focusId] then
    print("warning(FocusManager:loadElementFromCustomValues): element with id " .. focusId .. " was already added")
  end
  self.currentFocusData.idToElementMapping[focusId] = element
  if element.focusActive then
    self.currentFocusData.initialFocusElement = isAlwaysFocusedOnOpen and element
    self:setFocus(element)
  end
end
function FocusManager:removeElement(element)
  if not element.focusId then
    return
  end
  if element.focusActive then
    element:onFocusLeave()
    FocusManager:unsetFocus(element)
  end
  self.currentFocusData.idToElementMapping[element.focusId] = nil
end
function FocusManager:linkElements(sourceElement, direction, targetElement)
  sourceElement.focusChangeData[direction] = targetElement.focusId
end
function FocusManager:checkElement(element, dt)
  if self.currentFocusData.focusElement ~= element then
    return
  end
  self:updateFocus(element, InputBinding.isPressed(InputBinding.MENU_UP), FocusManager.TOP, dt)
  self:updateFocus(element, InputBinding.isPressed(InputBinding.MENU_DOWN), FocusManager.BOTTOM, dt)
  self:updateFocus(element, InputBinding.isPressed(InputBinding.MENU_LEFT), FocusManager.LEFT, dt)
  self:updateFocus(element, InputBinding.isPressed(InputBinding.MENU_RIGHT), FocusManager.RIGHT, dt)
  if InputBinding.hasEvent(InputBinding.MENU_ACCEPT, true) and element.focusActive then
    self.focusSystemMadeChanges = true
    element:onFocusActivate()
    self.focusSystemMadeChanges = false
  end
end
function FocusManager:updateFocus(element, isFocusMoving, direction, dt)
  if isFocusMoving then
    if self.delays[direction] then
      self.delays[direction] = self.delays[direction] - dt
      if self.delays[direction] <= 0 then
        self.delays[direction] = nil
      end
      return
    end
    self.delays[direction] = self.delaysNext[direction]
    self.delaysNext[direction] = math.max(self.DELAY_TIME_MIN, self.delaysNext[direction] * 0.1 ^ (dt / 100))
    if self.currentFocusData.focusElement ~= element then
      return
    end
    if element:shouldFocusChange(direction) then
      local nextElement, nextElementIsSet
      if element.focusChangeOverride then
        if element.target then
          nextElementIsSet, nextElement = element.focusChangeOverride(element.target, direction)
        else
          nextElementIsSet, nextElement = element:focusChangeOverride(direction)
        end
      end
      if not nextElementIsSet then
        nextElement = self.currentFocusData.idToElementMapping[element.focusChangeData[direction]]
      end
      if nextElement and nextElement:canReceiveFocus() then
        self:setFocus(nextElement, direction)
        return nextElement
      else
        self:setFocus(element)
      end
    end
  else
    self.delays[direction] = nil
    self.delaysNext[direction] = self.DELAY_TIME
  end
end
function FocusManager:setFocus(element, ...)
  if not element.focusId then
    return
  end
  if self.currentFocusData.focusElement and self.currentFocusData.focusElement == element and self.currentFocusData.focusElement.focusActive then
    return
  end
  if self.currentFocusData.focusElement and self.currentFocusData.focusElement ~= element and self.currentFocusData.focusElement.focusActive then
    self.currentFocusData.focusElement.focusActive = false
    self.currentFocusData.focusElement:onFocusLeave(...)
  end
  element.focusActive = true
  self.currentFocusData.focusElement = element
  element:onFocusEnter(...)
end
function FocusManager:unsetFocus(element)
  if self.currentFocusData.focusElement ~= element then
    return
  end
  if not element.focusActive then
    return
  end
  self.currentFocusData.focusElement.focusActive = false
  self.currentFocusData.focusElement:onFocusLeave()
end
function FocusManager:hasFocus(element)
  return self.currentFocusData.focusElement == element and element.focusActive
end
function FocusManager:createLinkageSystemForElements(elementsList, rootElement, elementsPositionData)
  local elementsToLink = {}
  elementsPositionData = elementsPositionData or {}
  for i, element in ipairs(elementsList) do
    if element.focusId then
      element.focusChangeData = {}
      if element.focusActive then
        element:onFocusLeave()
        element.focusActive = false
      end
      if element:canReceiveFocus() then
        local elementPositionData = elementsPositionData[element]
        if not elementPositionData then
          elementPositionData = {}
          elementsPositionData[element] = elementPositionData
        end
        if not elementPositionData[FocusManager.RIGHT] then
          elementPositionData[FocusManager.RIGHT] = {}
        end
        elementPositionData[FocusManager.RIGHT].positionX = elementPositionData[FocusManager.RIGHT].positionX or elementPositionData.positionX or element.absPosition[1] + element.size[1]
        elementPositionData[FocusManager.RIGHT].positionY = elementPositionData[FocusManager.RIGHT].positionY or elementPositionData.positionY or element.absPosition[2] + element.size[2] * 0.5
        if not elementPositionData[FocusManager.LEFT] then
          elementPositionData[FocusManager.LEFT] = {}
        end
        elementPositionData[FocusManager.LEFT].positionX = elementPositionData[FocusManager.LEFT].positionX or elementPositionData.positionX or element.absPosition[1]
        elementPositionData[FocusManager.LEFT].positionY = elementPositionData[FocusManager.LEFT].positionY or elementPositionData.positionY or element.absPosition[2] + element.size[2] * 0.5
        if not elementPositionData[FocusManager.TOP] then
          elementPositionData[FocusManager.TOP] = {}
        end
        elementPositionData[FocusManager.TOP].positionX = elementPositionData[FocusManager.TOP].positionX or elementPositionData.positionX or element.absPosition[1] + element.size[1] * 0.5
        elementPositionData[FocusManager.TOP].positionY = elementPositionData[FocusManager.TOP].positionY or elementPositionData.positionY or element.absPosition[2] + element.size[2]
        if not elementPositionData[FocusManager.BOTTOM] then
          elementPositionData[FocusManager.BOTTOM] = {}
        end
        elementPositionData[FocusManager.BOTTOM].positionX = elementPositionData[FocusManager.BOTTOM].positionX or elementPositionData.positionX or element.absPosition[1] + element.size[1] * 0.5
        elementPositionData[FocusManager.BOTTOM].positionY = elementPositionData[FocusManager.BOTTOM].positionY or elementPositionData.positionY or element.absPosition[2]
        elementPositionData.positionX = elementPositionData.positionX or element.absPosition[1] + element.size[1] * 0.5
        elementPositionData.positionY = elementPositionData.positionY or element.absPosition[2] + element.size[2] * 0.5
        table.insert(elementsToLink, element)
      end
    else
      print("warning(FocusManager:createLinkageSystemForElements): passed element has no focus information")
    end
  end
  local getDistance = function(elementData, elementDataToCheck, direction)
    local directionX = elementDataToCheck[FocusManager.opposingDirectionsHash[direction]].positionX - elementData[direction].positionX
    local directionY = elementDataToCheck[FocusManager.opposingDirectionsHash[direction]].positionY - elementData[direction].positionY
    local distance = Utils.vector2Length(directionX, directionY)
    return distance
  end
  for i, element in ipairs(elementsToLink) do
    element.focusChangeData[FocusManager.RIGHT] = {}
    element.focusChangeData[FocusManager.LEFT] = {}
    element.focusChangeData[FocusManager.TOP] = {}
    element.focusChangeData[FocusManager.BOTTOM] = {}
    element.focusChangeDataDistances = {}
    element.focusChangeDataDistances[FocusManager.RIGHT] = {}
    element.focusChangeDataDistances[FocusManager.LEFT] = {}
    element.focusChangeDataDistances[FocusManager.TOP] = {}
    element.focusChangeDataDistances[FocusManager.BOTTOM] = {}
    local elementPositionData = elementsPositionData[element]
    for j, elementToCheck in ipairs(elementsToLink) do
      if i ~= j then
        local elementToCheckPositionData = elementsPositionData[elementToCheck]
        local directionX = elementToCheckPositionData.positionX - elementPositionData.positionX
        local directionY = elementToCheckPositionData.positionY - elementPositionData.positionY
        element.focusChangeDataDistances[elementToCheck] = Utils.vector2Length(directionX, directionY)
        if math.abs(directionX) > math.abs(directionY) then
          if 0 < directionX then
            element.focusChangeDataDistances[FocusManager.RIGHT][elementToCheck] = getDistance(elementPositionData, elementToCheckPositionData, FocusManager.RIGHT)
            table.insert(element.focusChangeData[FocusManager.RIGHT], elementToCheck)
          else
            element.focusChangeDataDistances[FocusManager.LEFT][elementToCheck] = getDistance(elementPositionData, elementToCheckPositionData, FocusManager.LEFT)
            table.insert(element.focusChangeData[FocusManager.LEFT], elementToCheck)
          end
        elseif 0 < directionY then
          element.focusChangeDataDistances[FocusManager.TOP][elementToCheck] = getDistance(elementPositionData, elementToCheckPositionData, FocusManager.TOP)
          table.insert(element.focusChangeData[FocusManager.TOP], elementToCheck)
        else
          element.focusChangeDataDistances[FocusManager.BOTTOM][elementToCheck] = getDistance(elementPositionData, elementToCheckPositionData, FocusManager.BOTTOM)
          table.insert(element.focusChangeData[FocusManager.BOTTOM], elementToCheck)
        end
      end
    end
    table.sort(element.focusChangeData[FocusManager.RIGHT], function(element1, element2)
      return element.focusChangeDataDistances[FocusManager.RIGHT][element1] < element.focusChangeDataDistances[FocusManager.RIGHT][element2]
    end)
    table.sort(element.focusChangeData[FocusManager.LEFT], function(element1, element2)
      return element.focusChangeDataDistances[FocusManager.LEFT][element1] < element.focusChangeDataDistances[FocusManager.LEFT][element2]
    end)
    table.sort(element.focusChangeData[FocusManager.TOP], function(element1, element2)
      return element.focusChangeDataDistances[FocusManager.TOP][element1] < element.focusChangeDataDistances[FocusManager.TOP][element2]
    end)
    table.sort(element.focusChangeData[FocusManager.BOTTOM], function(element1, element2)
      return element.focusChangeDataDistances[FocusManager.BOTTOM][element1] < element.focusChangeDataDistances[FocusManager.BOTTOM][element2]
    end)
    element.focusChangeData[FocusManager.RIGHT] = next(element.focusChangeData[FocusManager.RIGHT]) and element.focusChangeData[FocusManager.RIGHT][1].focusId or nil
    element.focusChangeData[FocusManager.LEFT] = next(element.focusChangeData[FocusManager.LEFT]) and element.focusChangeData[FocusManager.LEFT][1].focusId or nil
    element.focusChangeData[FocusManager.TOP] = next(element.focusChangeData[FocusManager.TOP]) and element.focusChangeData[FocusManager.TOP][1].focusId or nil
    element.focusChangeData[FocusManager.BOTTOM] = next(element.focusChangeData[FocusManager.BOTTOM]) and element.focusChangeData[FocusManager.BOTTOM][1].focusId or nil
    element.focusChangeDataDistances = nil
  end
  if rootElement then
    self.currentFocusData.initialFocusElement = rootElement
    FocusManager:setFocus(rootElement)
    if not self.focusSystemMadeChanges then
      FocusManager:unsetFocus(rootElement)
    end
  end
end
