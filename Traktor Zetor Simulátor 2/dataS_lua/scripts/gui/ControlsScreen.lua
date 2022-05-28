ControlsScreen = {
  UNSPECIFIED = -1,
  COLUMN_ACTION = 1,
  COLUMN_KEY1 = 2,
  COLUMN_KEY2 = 3,
  COLUMN_MOUSE = 4,
  COLUMN_GAMEPAD = 5,
  lockedActionsForKey1 = {
    "MENU",
    "MENU_CANCEL"
  },
  lockedActionsForKey2 = {},
  lockedActionsForGamepad = {},
  lockedActionsForMouse = {}
}
local ControlsScreen_mt = Class(ControlsScreen)
function ControlsScreen:new()
  local instance = {}
  setmetatable(instance, ControlsScreen_mt)
  instance.selectedIndex = 0
  instance.inputSets = {}
  instance.inputGuiElementSets = {}
  instance.elementsToTablePosition = {}
  instance.tablePositionToElement = {}
  instance.selectedColumn = ControlsScreen.UNSPECIFIED
  instance.selectedRow = ControlsScreen.UNSPECIFIED
  instance.userMadeChanges = false
  instance.controlsMessageStandardColor = {
    0.6,
    1,
    0.6,
    1
  }
  instance.controlsMessageWarningColor = {
    1,
    0.6,
    0.4,
    1
  }
  instance.lockedPositions = {}
  instance.lockedActions = {}
  local prepareLockedActions = function(lockedActionHash, actionNameList, columnName)
    for _, actionName in ipairs(actionNameList) do
      local actionId = InputBinding[actionName]
      if not lockedActionHash[actionId] then
        lockedActionHash[actionId] = {}
      end
      lockedActionHash[actionId][columnName] = true
    end
  end
  prepareLockedActions(instance.lockedActions, ControlsScreen.lockedActionsForKey1, ControlsScreen.COLUMN_KEY1)
  prepareLockedActions(instance.lockedActions, ControlsScreen.lockedActionsForKey2, ControlsScreen.COLUMN_KEY2)
  prepareLockedActions(instance.lockedActions, ControlsScreen.lockedActionsForGamepad, ControlsScreen.COLUMN_GAMEPAD)
  prepareLockedActions(instance.lockedActions, ControlsScreen.lockedActionsForMouse, ControlsScreen.COLUMN_MOUSE)
  instance.tempIsSliderScrolling = false
  return instance
end
function ControlsScreen:onControlsScreenCreated(element)
  self.listElement.elements = {}
  self.listElement.listItems = {}
  local digitalBindingsHash, analogBindingsHash, digitalActionList, analogActionList = InputBinding.getBindings()
  local listIndex = 0
  for actionIndex, actionIdentifier in ipairs(digitalActionList) do
    listIndex = listIndex + 1
    self.currentInputSet = digitalBindingsHash[actionIdentifier]
    self.currentInputSet.listIndex = listIndex
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier] = {}
    local newInputGuiElementSet = self.listTemplate:clone(self.listTemplate.parent)
    newInputGuiElementSet:updateAbsolutePosition()
    self.currentInputSet = nil
  end
  for actionIndex, actionIdentifier in ipairs(analogActionList) do
    local negativeAxisActionIdentifier = actionIdentifier .. "_1"
    local positiveAxisActionIdentifier = actionIdentifier .. "_2"
    listIndex = listIndex + 1
    self.currentInputSet = analogBindingsHash[negativeAxisActionIdentifier]
    self.currentInputSet.listIndex = listIndex
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier] = {}
    local newInputGuiElementSet = self.listTemplate:clone(self.listTemplate.parent)
    newInputGuiElementSet:updateAbsolutePosition()
    self.currentInputSet = nil
    listIndex = listIndex + 1
    self.currentInputSet = analogBindingsHash[positiveAxisActionIdentifier]
    self.currentInputSet.listIndex = listIndex
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier] = {}
    local newInputGuiElementSet = self.listTemplate:clone(self.listTemplate.parent)
    newInputGuiElementSet:updateAbsolutePosition()
    self.currentInputSet = nil
  end
  self.buttonDefaults = element.elements[2].elements[2]
  self.buttonSave = element.elements[2].elements[3]
  self.buttonCancel = element.elements[2].elements[4]
  self.minColumn = ControlsScreen.COLUMN_KEY1
  self.maxColumn = ControlsScreen.COLUMN_GAMEPAD
  self.minRow = 1
  self.maxRow = listIndex
  self.focusedColumn = self.minColumn
  self.focusedRow = self.maxRow
  local controlsScreen = self
  function self.listElement:shouldFocusChange(direction)
    if controlsScreen.waitForInput then
      return false
    end
    if direction == FocusManager.TOP then
      if controlsScreen.focusedRow <= controlsScreen.minRow then
        return true
      else
        controlsScreen:focusElement(controlsScreen.focusedColumn, controlsScreen.focusedRow - 1)
        return false
      end
    elseif direction == FocusManager.BOTTOM then
      if controlsScreen.focusedRow >= controlsScreen.maxRow then
        return true
      else
        controlsScreen:focusElement(controlsScreen.focusedColumn, controlsScreen.focusedRow + 1)
        return false
      end
    elseif direction == FocusManager.LEFT then
      if controlsScreen.focusedColumn <= controlsScreen.minColumn then
        return true
      else
        controlsScreen:focusElement(controlsScreen.focusedColumn - 1, controlsScreen.focusedRow)
        return false
      end
    elseif direction == FocusManager.RIGHT then
      if controlsScreen.focusedColumn >= controlsScreen.maxColumn then
        return true
      else
        controlsScreen:focusElement(controlsScreen.focusedColumn + 1, controlsScreen.focusedRow)
        return false
      end
    end
  end
  function self.listElement:onFocusLeave()
    local focusedElement = controlsScreen.tablePositionToElement[controlsScreen.focusedColumn][controlsScreen.focusedRow]
    focusedElement:setSelected(false)
  end
  function self.listElement:onFocusEnter()
    local focusedElement = controlsScreen.tablePositionToElement[controlsScreen.focusedColumn][controlsScreen.focusedRow]
    controlsScreen.listElement:setSelectedRow(controlsScreen.focusedRow)
    controlsScreen.listElement:updateItemPositions()
    controlsScreen.listSlider:setValue(controlsScreen.listSlider.maxValue - controlsScreen.listElement.firstVisibleItem + controlsScreen.listSlider.minValue)
    focusedElement:setSelected(true)
  end
  function self.listElement:onFocusActivate()
    if controlsScreen.waitForInput then
      return
    end
    local focusedElement = controlsScreen.tablePositionToElement[controlsScreen.focusedColumn][controlsScreen.focusedRow]
    if controlsScreen.focusedColumn == ControlsScreen.COLUMN_KEY1 then
      controlsScreen:onClickKey1(focusedElement)
    elseif controlsScreen.focusedColumn == ControlsScreen.COLUMN_KEY2 then
      controlsScreen:onClickKey2(focusedElement)
    elseif controlsScreen.focusedColumn == ControlsScreen.COLUMN_MOUSE then
      controlsScreen:onClickMouse(focusedElement)
    elseif controlsScreen.focusedColumn == ControlsScreen.COLUMN_GAMEPAD then
      controlsScreen:onClickGamepad(focusedElement)
    end
  end
  self.listSlider:setMinValue(1)
  self.listSlider:setMaxValue(self.maxRow - self.listElement.visibleItems + 1)
  self.listSlider:setValue(self.maxRow - self.listElement.visibleItems + 1)
  self.listElement:scrollTo(1)
end
function ControlsScreen:onFocusElement(element)
  self:focusElement(unpack(self.elementsToTablePosition[element]))
end
function ControlsScreen:focusElement(column, row)
  if self.focusedColumn == column and self.focusedRow == row then
  else
    local oldElement = self.tablePositionToElement[self.focusedColumn][self.focusedRow]
    oldElement:setSelected(false)
    self.focusedColumn = column
    self.focusedRow = row
    self.listElement:setSelectedRow(self.focusedRow)
    self.listSlider:setValue(self.listSlider.maxValue - self.listElement.firstVisibleItem + self.listSlider.minValue)
    local newElement = self.tablePositionToElement[column][row]
    newElement:setSelected(true)
  end
  if not FocusManager:hasFocus(self.listElement) then
    FocusManager:setFocus(self.listElement)
  end
end
function ControlsScreen:onControlsScreenOpen()
  if self.screenClosedTemporarily then
    self.screenClosedTemporarily = false
  else
    self:loadBindings()
    self.controlsMessage1Element:setText("")
    self.controlsMessage2Element:setText("")
  end
end
function ControlsScreen:onCreateListTemplate(element)
  if self.listTemplate == nil then
    self.listTemplate = element
  end
end
function ControlsScreen:registerElement(element, column, row)
  self.elementsToTablePosition[element] = {column, row}
  if not self.tablePositionToElement[column] then
    self.tablePositionToElement[column] = {}
  end
  self.tablePositionToElement[column][row] = element
end
function ControlsScreen:onCreateAction(element)
  if self.currentInputSet ~= nil then
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier].action = element
  end
end
function ControlsScreen:onCreateActionItem(element)
  if self.currentInputSet ~= nil then
    self:registerElement(element, ControlsScreen.COLUMN_ACTION, self.currentInputSet.listIndex)
  end
end
function ControlsScreen:onCreateKey1(element)
  if self.currentInputSet ~= nil then
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier].key1 = element
  end
end
function ControlsScreen:onCreateKey1Item(element)
  if self.currentInputSet ~= nil then
    self:registerElement(element, ControlsScreen.COLUMN_KEY1, self.currentInputSet.listIndex)
  end
end
function ControlsScreen:onCreateKey2(element)
  if self.currentInputSet ~= nil then
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier].key2 = element
  end
end
function ControlsScreen:onCreateKey2Item(element)
  if self.currentInputSet ~= nil then
    self:registerElement(element, ControlsScreen.COLUMN_KEY2, self.currentInputSet.listIndex)
  end
end
function ControlsScreen:onCreateMouse(element)
  if self.currentInputSet ~= nil then
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier].mouse = element
  end
end
function ControlsScreen:onCreateMouseItem(element)
  if self.currentInputSet ~= nil then
    self:registerElement(element, ControlsScreen.COLUMN_MOUSE, self.currentInputSet.listIndex)
  end
end
function ControlsScreen:onCreateGamepad(element)
  if self.currentInputSet ~= nil then
    self.inputGuiElementSets[self.currentInputSet.actionIdentifier].gamepad = element
  end
end
function ControlsScreen:onCreateGamepadItem(element)
  if self.currentInputSet ~= nil then
    self:registerElement(element, ControlsScreen.COLUMN_GAMEPAD, self.currentInputSet.listIndex)
  end
end
function ControlsScreen:onCreateControlsMessage1(element)
  self.controlsMessage1Element = element
end
function ControlsScreen:onCreateControlsMessage2(element)
  self.controlsMessage2Element = element
end
function ControlsScreen:onCreateList(element)
  self.listElement = element
end
function ControlsScreen:onListScroll(newRow)
  if self.tempIsSliderScrolling then
    return
  end
  self.listSlider:setValue(self.listSlider.maxValue - newRow + self.listSlider.minValue)
end
function ControlsScreen:onCreateListSlider(element)
  self.listSlider = element
end
function ControlsScreen:onChangedListSlider(newValue)
  self.tempIsSliderScrolling = true
  local index = self.listSlider.maxValue - newValue + 1
  self.listElement:scrollTo(math.floor(index + 0.001))
  self.tempIsSliderScrolling = false
end
function ControlsScreen:onListUpClick()
  self.listElement:scrollList(-1)
end
function ControlsScreen:onListDownClick()
  self.listElement:scrollList(1)
end
function ControlsScreen:loadBindings()
  self.inputSets = {}
  local inputSetCount = 0
  self.lockedPositions[ControlsScreen.COLUMN_ACTION] = {}
  self.lockedPositions[ControlsScreen.COLUMN_KEY1] = {}
  self.lockedPositions[ControlsScreen.COLUMN_KEY2] = {}
  self.lockedPositions[ControlsScreen.COLUMN_MOUSE] = {}
  self.lockedPositions[ControlsScreen.COLUMN_GAMEPAD] = {}
  self.userMadeChanges = false
  local digitalBindingsHash, analogBindingsHash, digitalActionList, analogActionList = InputBinding.getBindings()
  for actionIndex, actionIdentifier in ipairs(digitalActionList) do
    inputSetCount = inputSetCount + 1
    self.inputSets[inputSetCount] = digitalBindingsHash[actionIdentifier]
    if self.lockedActions[actionIndex] and self.lockedActions[actionIndex][ControlsScreen.COLUMN_KEY1] then
      self.lockedPositions[ControlsScreen.COLUMN_KEY1][inputSetCount] = true
    end
    if self.lockedActions[actionIndex] and self.lockedActions[actionIndex][ControlsScreen.COLUMN_KEY2] then
      self.lockedPositions[ControlsScreen.COLUMN_KEY2][inputSetCount] = true
    end
    if self.lockedActions[actionIndex] and self.lockedActions[actionIndex][ControlsScreen.COLUMN_GAMEPAD] then
      self.lockedPositions[ControlsScreen.COLUMN_GAMEPAD][inputSetCount] = true
    end
    if self.lockedActions[actionIndex] and self.lockedActions[actionIndex][ControlsScreen.COLUMN_MOUSE] then
      self.lockedPositions[ControlsScreen.COLUMN_MOUSE][inputSetCount] = true
    end
  end
  for actionIndex, actionIdentifier in ipairs(analogActionList) do
    local negativeAxisActionIdentifier, positiveAxisActionIdentifier = InputBinding.getAxisActionIdentifiers(actionIdentifier)
    inputSetCount = inputSetCount + 1
    self.inputSets[inputSetCount] = analogBindingsHash[negativeAxisActionIdentifier]
    inputSetCount = inputSetCount + 1
    self.inputSets[inputSetCount] = analogBindingsHash[positiveAxisActionIdentifier]
  end
  for k, tablePosition in pairs(self.elementsToTablePosition) do
    k:setDisabled(not not self.lockedPositions[tablePosition[1]][tablePosition[2]])
  end
  self.maxGamepadDeviceId = 0
  for _, inputsetData in pairs(self.inputSets) do
    if inputsetData.gamepadDeviceId then
      if inputsetData.gamepadDeviceId > self.maxGamepadDeviceId then
        self.maxGamepadDeviceId = inputsetData.gamepadDeviceId
      end
      if not self.minGamepadDeviceId or inputsetData.gamepadDeviceId < self.minGamepadDeviceId then
        self.minGamepadDeviceId = inputsetData.gamepadDeviceId
      end
    end
  end
  for _, inputsetData in pairs(self.inputSets) do
    self:updateInputStrings(inputsetData)
  end
end
function ControlsScreen:saveBindings()
  local digitalBindings, analogBindings = {}, {}
  for index, inputSet in pairs(self.inputSets) do
    local isAxis = InputBinding.isAxisActionIdentifier(inputSet.actionIdentifier)
    local bindingToUse
    if isAxis then
      bindingToUse = analogBindings
    else
      bindingToUse = digitalBindings
    end
    bindingToUse[inputSet.actionIdentifier] = inputSet
  end
  InputBinding.storeBindings(digitalBindings, analogBindings)
end
function ControlsScreen:updateInputStrings(inputSet)
  local guiElementSet = self.inputGuiElementSets[inputSet.actionIdentifier]
  if guiElementSet.action ~= nil then
    guiElementSet.action:setText(inputSet.name)
  end
  if guiElementSet.key1 ~= nil then
    if inputSet.key1Ids then
      guiElementSet.key1:setText(KeyboardHelper.getKeyNames(inputSet.key1Ids))
    else
      guiElementSet.key1:setText("")
    end
  end
  if guiElementSet.key2 ~= nil then
    if inputSet.key2Ids then
      guiElementSet.key2:setText(KeyboardHelper.getKeyNames(inputSet.key2Ids))
    else
      guiElementSet.key2:setText("")
    end
  end
  if guiElementSet.mouse ~= nil then
    if InputBinding.isAxisActionIdentifier(inputSet.actionIdentifier) then
      guiElementSet.mouse:setText("--")
    elseif inputSet.mouseButtonId then
      guiElementSet.mouse:setText(MouseHelper.getButtonName(inputSet.mouseButtonId))
    else
      guiElementSet.mouse:setText("")
    end
  end
  if guiElementSet.gamepad ~= nil then
    local buttonString
    if inputSet.gamepadButtonIds and inputSet.gamepadButtonIds[1] then
      buttonString = ""
      for i, buttonId in ipairs(inputSet.gamepadButtonIds) do
        local buttonName = GamepadHelper.getButtonName(buttonId, inputSet.gamepadDeviceId)
        buttonString = buttonString .. (i == 1 and "" or ", ") .. buttonName
      end
    end
    local axisString
    if inputSet.gamepadAxisId then
      axisString = GamepadHelper.getAxisName(inputSet.gamepadAxisId, inputSet.gamepadDeviceId)
    end
    local deviceString
    if (buttonString or axisString) and inputSet.gamepadDeviceId > 0 and self.maxGamepadDeviceId ~= self.minGamepadDeviceId then
      deviceString = GamepadHelper.getDeviceString(inputSet.gamepadDeviceId)
    end
    local finalString = (axisString or "") .. (axisString and buttonString and " + " or "") .. (buttonString or "") .. (deviceString and " " .. deviceString or "")
    guiElementSet.gamepad:setText(finalString)
  end
end
function ControlsScreen:onClickKey1(element)
  if self.waitForInput then
    return
  end
  local selectedLine = self.elementsToTablePosition[element][2]
  if selectedLine ~= nil then
    if self.inputSets[selectedLine].key1Id == "--" then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapKeyHere"))
    elseif self.lockedPositions[ControlsScreen.COLUMN_KEY1][selectedLine] then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapKeyHere"))
    else
      self:beginWaitForInput(ControlsScreen.COLUMN_KEY1, selectedLine)
    end
  end
end
function ControlsScreen:onClickKey2(element)
  if self.waitForInput then
    return
  end
  local selectedLine = self.elementsToTablePosition[element][2]
  if selectedLine ~= nil then
    if self.lockedPositions[ControlsScreen.COLUMN_KEY2][selectedLine] then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapKeyHere"))
    else
      self:beginWaitForInput(ControlsScreen.COLUMN_KEY2, selectedLine)
    end
  end
end
function ControlsScreen:onClickMouse(element)
  if self.waitForInput and self.selectedColumn == ControlsScreen.COLUMN_MOUSE then
    return
  end
  local selectedLine = self.elementsToTablePosition[element][2]
  if selectedLine ~= nil then
    if InputBinding.isAxisActionIdentifier(self.inputSets[selectedLine].actionIdentifier) then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapMouseHere"))
    elseif self.lockedPositions[ControlsScreen.COLUMN_MOUSE][selectedLine] then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapMouseHere"))
    else
      self:beginWaitForInput(ControlsScreen.COLUMN_MOUSE, selectedLine)
    end
  end
end
function ControlsScreen:onClickGamepad(element)
  if self.waitForInput then
    return
  end
  local selectedLine = self.elementsToTablePosition[element][2]
  if selectedLine ~= nil then
    if self.inputSets[selectedLine].gamepadButtonId == "--" then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapGamepadHere"))
    elseif self.lockedPositions[ControlsScreen.COLUMN_GAMEPAD][selectedLine] then
      self.controlsMessage1Element:setText(g_i18n:getText("CannotMapGamepadHere"))
    else
      self:beginWaitForInput(ControlsScreen.COLUMN_GAMEPAD, selectedLine)
    end
  end
end
function ControlsScreen:beginWaitForInput(selectedColumn, selectedRow)
  if selectedColumn == ControlsScreen.COLUMN_KEY1 or selectedColumn == ControlsScreen.COLUMN_KEY2 then
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("PressKeyToMap"), self.inputSets[selectedRow].name))
  elseif selectedColumn == ControlsScreen.COLUMN_MOUSE then
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("PressMouseButtonToMap"), self.inputSets[selectedRow].name))
  elseif selectedColumn == ControlsScreen.COLUMN_GAMEPAD then
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("PressGamepadButtonToMap"), self.inputSets[selectedRow].name))
  end
  self.controlsMessage2Element:setText(g_i18n:getText("PressESCToCancel"))
  self.controlsMessage1Element.textColor = self.controlsMessageStandardColor
  self.controlsMessage2Element.textColor = self.controlsMessageStandardColor
  self.selectedColumn = selectedColumn
  self.selectedRow = selectedRow
  for k, v in pairs(self.elementsToTablePosition) do
    k:setDisabled(v[1] ~= self.selectedColumn or v[2] ~= self.selectedRow)
  end
  self.buttonDefaults:setDisabled(true)
  self.buttonSave:setDisabled(true)
  self.buttonCancel:setDisabled(true)
  self.waitForInput = true
  self.inputGathered = false
  self.gatheredInput = {}
  self.gatheredInput.keyboard = {}
  self.gatheredInput.keyboard.keys = {}
  self.gatheredInput.keyboard.invalidKeys = {}
  self.gatheredInput.mouse = {}
  self.gatheredInput.mouse.buttons = {}
  self.gatheredInput.mouse.axes = {}
  self.gatheredInput.gamepad = {}
  InputBinding.startInputGatheringOverride(ControlsScreen.inputOverrideCallback, self)
end
function ControlsScreen:endWaitForInput()
  for k, tablePosition in pairs(self.elementsToTablePosition) do
    k:setDisabled(not not self.lockedPositions[tablePosition[1]][tablePosition[2]])
  end
  self:updateInputStrings(self.inputSets[self.selectedRow])
  self.selectedColumn = ControlsScreen.UNSPECIFIED
  self.selectedRow = ControlsScreen.UNSPECIFIED
  self.buttonDefaults:setDisabled(false)
  self.buttonSave:setDisabled(false)
  self.buttonCancel:setDisabled(false)
  self.waitForInput = false
  InputBinding.stopInputGatheringOverride()
  self.gatheredInput = nil
  self.inputGathered = false
end
function ControlsScreen:updateStoredInput(currentInput)
  local endInput = false
  if self.selectedColumn == ControlsScreen.COLUMN_KEY1 or self.selectedColumn == ControlsScreen.COLUMN_KEY2 then
    for keyId, _ in pairs(self.gatheredInput.keyboard.keys) do
      if not currentInput.keyboard.keys[keyId] then
        endInput = true
        break
      end
    end
    if next(currentInput.keyboard.keys) then
      for keyId, _ in pairs(currentInput.keyboard.keys) do
        self.inputGathered = true
        self.gatheredInput.keyboard.keys[keyId] = true
      end
    end
  elseif self.selectedColumn == ControlsScreen.COLUMN_MOUSE then
    for mouseButtonId, _ in pairs(self.gatheredInput.mouse.buttons) do
      if not currentInput.mouse.buttons[mouseButtonId] then
        endInput = true
        break
      end
    end
    if next(currentInput.mouse.buttons) then
      for mouseButtonId, _ in pairs(currentInput.mouse.buttons) do
        self.inputGathered = true
        self.gatheredInput.mouse.buttons[mouseButtonId] = true
      end
    end
  elseif self.selectedColumn == ControlsScreen.COLUMN_GAMEPAD then
    for gamepadId, gamepadData in pairs(self.gatheredInput.gamepad) do
      for buttonId, _ in pairs(gamepadData.buttons) do
        if not currentInput.gamepad[gamepadId] or not currentInput.gamepad[gamepadId].buttons[buttonId] then
          endInput = true
          break
        end
      end
      local isAxis = InputBinding.isAxisActionIdentifier(self.inputSets[self.selectedRow].actionIdentifier)
      if isAxis then
        for axisId, _ in pairs(gamepadData.axes) do
          if not currentInput.gamepad[gamepadId] or not currentInput.gamepad[gamepadId].axes[axisId] then
            endInput = true
            break
          end
        end
      end
    end
    if next(currentInput.gamepad) then
      for gamepadId, gamepadData in pairs(currentInput.gamepad) do
        if not self.gatheredInput.gamepad[gamepadId] then
          self.gatheredInput.gamepad[gamepadId] = {}
          self.gatheredInput.gamepad[gamepadId].buttons = {}
          self.gatheredInput.gamepad[gamepadId].axes = {}
        end
        for gamepadButtonId, _ in pairs(gamepadData.buttons) do
          self.inputGathered = true
          self.gatheredInput.gamepad[gamepadId].buttons[gamepadButtonId] = true
        end
        for gamepadAxisId, _ in pairs(gamepadData.axes) do
          self.inputGathered = true
          self.gatheredInput.gamepad[gamepadId].axes[gamepadAxisId] = true
        end
      end
    end
  end
  return endInput
end
function ControlsScreen:inputOverrideCallback(currentInput)
  local endInput = self:updateStoredInput(currentInput)
  if currentInput.keyboard then
    if currentInput.keyboard.keys[Input.KEY_esc] then
      self.controlsMessage1Element:setText(g_i18n:getText("SelectActionToRemap"))
      self.controlsMessage2Element:setText("")
      self.controlsMessage1Element.textColor = self.controlsMessageStandardColor
      self.controlsMessage2Element.textColor = self.controlsMessageStandardColor
      return self:endWaitForInput()
    elseif currentInput.keyboard.keys[8] then
      local currentInputSet = self.inputSets[self.selectedRow]
      if self.selectedColumn == ControlsScreen.COLUMN_KEY1 then
        currentInputSet.key1Ids = {}
      elseif self.selectedColumn == ControlsScreen.COLUMN_KEY2 then
        currentInputSet.key2Ids = {}
      elseif self.selectedColumn == ControlsScreen.COLUMN_MOUSE then
        currentInputSet.mouseButtonId = nil
        currentInputSet.inputMouseButton = ""
      elseif self.selectedColumn == ControlsScreen.COLUMN_GAMEPAD then
        local isAxis = InputBinding.isAxisActionIdentifier(currentInputSet.actionIdentifier)
        if isAxis then
          local isNegativeAxis = InputBinding.isAxisActionIdentifierForNegativeAxis(currentInputSet.actionIdentifier)
          local negativeAxisSetIndex = isNegativeAxis and self.selectedRow or self.selectedRow - 1
          local positiveAxisSetIndex = isNegativeAxis and self.selectedRow + 1 or self.selectedRow
          local negativeAxisInputSet = self.inputSets[negativeAxisSetIndex]
          local positiveAxisInputSet = self.inputSets[positiveAxisSetIndex]
          negativeAxisInputSet.gamepadDeviceId = 0
          negativeAxisInputSet.gamepadButtonIds = {}
          negativeAxisInputSet.gamepadAxisId = nil
          positiveAxisInputSet.gamepadDeviceId = 0
          positiveAxisInputSet.gamepadButtonIds = {}
          positiveAxisInputSet.gamepadAxisId = nil
          if isNegativeAxis then
            self:updateInputStrings(positiveAxisInputSet)
          else
            self:updateInputStrings(negativeAxisInputSet)
          end
        else
          currentInputSet.gamepadDeviceId = 0
          currentInputSet.gamepadButtonIds = {}
          currentInputSet.gamepadAxisId = nil
        end
      end
      self.userMadeChanges = true
      self.controlsMessage1Element:setText(g_i18n:getText("SelectActionToRemap"))
      self.controlsMessage2Element:setText("")
      self.controlsMessage1Element.textColor = self.controlsMessageStandardColor
      self.controlsMessage2Element.textColor = self.controlsMessageStandardColor
      return self:endWaitForInput()
    elseif next(currentInput.keyboard.invalidKeys) then
      self.controlsMessage1Element:setText(g_i18n:getText("KeyCannotBeMapped"))
      self.controlsMessage2Element:setText("")
      self.controlsMessage1Element.textColor = self.controlsMessageWarningColor
      self.controlsMessage2Element.textColor = self.controlsMessageWarningColor
      return self:endWaitForInput()
    end
  end
  if endInput then
    if self.selectedColumn == ControlsScreen.COLUMN_KEY1 or self.selectedColumn == ControlsScreen.COLUMN_KEY2 then
      self:assignKeyboard(self.gatheredInput)
    elseif self.selectedColumn == ControlsScreen.COLUMN_MOUSE then
      self:assignMouse(self.gatheredInput)
    elseif self.selectedColumn == ControlsScreen.COLUMN_GAMEPAD then
      self:assignGamepad(self.gatheredInput)
    end
  end
end
function ControlsScreen:assignKeyboard(gatheredInput)
  local currentInputSet = self.inputSets[self.selectedRow]
  local keyList = {}
  local normalKeys = {}
  local specialKeys = {}
  for keyId, _ in pairs(gatheredInput.keyboard.keys) do
    local found = false
    for _, specialKey in pairs(Input.SpecialKeys) do
      if keyId == specialKey.sym then
        found = true
        table.insert(specialKeys, keyId)
        break
      end
    end
    if not found then
      table.insert(normalKeys, keyId)
    end
  end
  table.sort(specialKeys)
  table.sort(normalKeys)
  local keysCount = 0
  for i, keyId in ipairs(specialKeys) do
    keysCount = keysCount + 1
    keyList[keysCount] = keyId
    break
  end
  for i, keyId in ipairs(normalKeys) do
    keysCount = keysCount + 1
    keyList[keysCount] = keyId
    break
  end
  if next(keyList) then
    if self.selectedColumn == ControlsScreen.COLUMN_KEY1 then
      currentInputSet.key1Ids = keyList
    elseif self.selectedColumn == ControlsScreen.COLUMN_KEY2 then
      currentInputSet.key2Ids = keyList
    end
    self.userMadeChanges = true
    self.controlsMessage2Element:setText("")
    for _, inputSet in pairs(self.inputSets) do
      if inputSet.actionIdentifier ~= currentInputSet.actionIdentifier and (next(inputSet.key1Ids) or next(inputSet.key2Ids)) and next(Utils.getSetIntersection(currentInputSet.categories, inputSet.categories)) then
        local duplicateEntryFound = false
        local tempTable = {}
        local differenceFound = false
        if self.selectedColumn == ControlsScreen.COLUMN_KEY1 then
          for _, keyId in ipairs(currentInputSet.key1Ids) do
            tempTable[keyId] = true
          end
        else
          for _, keyId in ipairs(currentInputSet.key2Ids) do
            tempTable[keyId] = true
          end
        end
        for _, keyId in ipairs(inputSet.key1Ids) do
          if not tempTable[keyId] then
            differenceFound = true
            break
          end
          tempTable[keyId] = nil
        end
        for _, keyId in ipairs(inputSet.key2Ids) do
          if not tempTable[keyId] then
            differenceFound = true
            break
          end
          tempTable[keyId] = nil
        end
        differenceFound = differenceFound or not not next(tempTable)
        if not differenceFound then
          duplicateEntryFound = true
        end
        if duplicateEntryFound then
          self.controlsMessage2Element:setText(g_i18n:getText("KeyAlreadyMapped") .. " (" .. inputSet.name .. ")")
          break
        end
      end
    end
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("ActionRemapped"), currentInputSet.name, KeyboardHelper.getKeyNames(keyList)))
    return self:endWaitForInput()
  elseif next(gatheredInput.keyboard.invalidKeys) then
    self.controlsMessage1Element:setText(g_i18n:getText("KeyCannotBeMapped"))
    self.controlsMessage2Element:setText("")
    self.controlsMessage1Element.textColor = self.controlsMessageWarningColor
    self.controlsMessage2Element.textColor = self.controlsMessageWarningColor
    return self:endWaitForInput()
  end
end
function ControlsScreen:assignMouse(gatheredInput)
  local currentInputSet = self.inputSets[self.selectedRow]
  if next(gatheredInput.mouse.buttons) then
    local minMouseButtonId
    for mouseButtonId, _ in pairs(gatheredInput.mouse.buttons) do
      if not minMouseButtonId or mouseButtonId < minMouseButtonId then
        minMouseButtonId = mouseButtonId
      end
    end
    currentInputSet.mouseButtonId = minMouseButtonId
    self.userMadeChanges = true
    self.controlsMessage2Element:setText("")
    for _, inputSet in pairs(self.inputSets) do
      if inputSet.mouseButtonId == currentInputSet.mouseButtonId and inputSet.actionIdentifier ~= currentInputSet.actionIdentifier and next(Utils.getSetIntersection(currentInputSet.categories, inputSet.categories)) then
        self.controlsMessage2Element:setText(g_i18n:getText("MouseAlreadyMapped") .. " (" .. inputSet.name .. ")")
        break
      end
    end
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("ActionRemapped"), currentInputSet.name, MouseHelper.getButtonName(currentInputSet.mouseButtonId)))
    return self:endWaitForInput()
  end
end
function ControlsScreen:assignGamepad(gatheredInput)
  local currentInputSet = self.inputSets[self.selectedRow]
  local isAxis = InputBinding.isAxisActionIdentifier(currentInputSet.actionIdentifier)
  local minGamepadId
  for gamepadId, gamepadData in pairs(gatheredInput.gamepad) do
    if not minGamepadId or gamepadId < minGamepadId then
      minGamepadId = gamepadId
    end
  end
  local minButton1Id, minButton2Id
  for buttonId, _ in pairs(gatheredInput.gamepad[minGamepadId].buttons) do
    if not minButton1Id or buttonId < minButton1Id then
      minButton2Id = minButton1Id
      minButton1Id = buttonId
    elseif not minButton2Id or buttonId < minButton2Id then
      minButton2Id = buttonId
    end
  end
  local minAxisId
  for axisId, _ in pairs(gatheredInput.gamepad[minGamepadId].axes) do
    if not minAxisId or axisId < minAxisId then
      minAxisId = axisId
    end
  end
  local deviceId = minGamepadId
  local buttonIds = {minButton1Id, minButton2Id}
  local axisId = minAxisId
  local axisIsTriggered = axisId ~= nil
  local buttonIsTriggered = buttonIds[1] ~= nil
  if isAxis then
    local actionIdentifier = InputBinding.getActionIdentifierFromAxisActionIdentifier(currentInputSet.actionIdentifier)
    local isNegativeAxis = InputBinding.isAxisActionIdentifierForNegativeAxis(currentInputSet.actionIdentifier)
    local negativeAxisSetIndex = isNegativeAxis and self.selectedRow or self.selectedRow - 1
    local positiveAxisSetIndex = isNegativeAxis and self.selectedRow + 1 or self.selectedRow
    local negativeAxisInputSet = self.inputSets[negativeAxisSetIndex]
    local positiveAxisInputSet = self.inputSets[positiveAxisSetIndex]
    if axisIsTriggered then
      negativeAxisInputSet.gamepadDeviceId = deviceId
      negativeAxisInputSet.gamepadButtonIds = buttonIds
      negativeAxisInputSet.gamepadAxisId = axisId
      positiveAxisInputSet.gamepadDeviceId = deviceId
      positiveAxisInputSet.gamepadButtonIds = buttonIds
      positiveAxisInputSet.gamepadAxisId = axisId
    else
      local currentDirection = positiveAxisInputSet
      local otherDirection = negativeAxisInputSet
      if isNegativeAxis then
        currentDirection, otherDirection = otherDirection, currentDirection
      end
      currentDirection.gamepadDeviceId = deviceId
      currentDirection.gamepadButtonIds = {
        buttonIds and buttonIds[1]
      }
      currentDirection.gamepadAxisId = nil
      if otherDirection.gamepadAxisId then
        otherDirection.gamepadDeviceId = nil
        otherDirection.gamepadButtonIds = nil
        otherDirection.gamepadAxisId = nil
      end
    end
    if isNegativeAxis then
      self:updateInputStrings(positiveAxisInputSet)
    else
      self:updateInputStrings(negativeAxisInputSet)
    end
    if axisIsTriggered then
    end
    self.controlsMessage2Element:setText("")
    local duplicateBindingFound = false
    local duplicateBinding
    for _, inputSet in pairs(self.inputSets) do
      if InputBinding.getActionIdentifierFromAxisActionIdentifier(inputSet.actionIdentifier) ~= InputBinding.getActionIdentifierFromAxisActionIdentifier(currentInputSet.actionIdentifier) and next(Utils.getSetIntersection(currentInputSet.categories, inputSet.categories)) then
        if axisIsTriggered then
          if inputSet.gamepadDeviceId == currentInputSet.gamepadDeviceId and inputSet.gamepadAxisId == currentInputSet.gamepadAxisId and (inputSet.gamepadButtonIds and currentInputSet.gamepadButtonIds and Utils.areListsEqual(inputSet.gamepadButtonIds, currentInputSet.gamepadButtonIds) or not inputSet.gamepadButtonIds and not currentInputSet.gamepadButtonIds) then
            self.controlsMessage2Element:setText(g_i18n:getText("AxisAlreadyMapped") .. " (" .. inputSet.name .. ")")
          end
        elseif inputSet.gamepadDeviceId == currentInputSet.gamepadDeviceId and inputSet.gamepadButtonIds and currentInputSet.gamepadButtonIds and Utils.areListsEqual(inputSet.gamepadButtonIds, currentInputSet.gamepadButtonIds) then
          self.controlsMessage2Element:setText(g_i18n:getText("ButtonAlreadyMapped") .. " (" .. inputSet.name .. ")")
        end
      end
    end
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("ActionRemapped"), currentInputSet.name, GamepadHelper.getButtonAndAxisNames(currentInputSet.gamepadButtonIds, currentInputSet.gamepadAxisId, currentInputSet.gamepadDeviceId)))
    self.userMadeChanges = true
    if not self.maxGamepadDeviceId or currentInputSet.gamepadDeviceId > self.maxGamepadDeviceId then
      self.maxGamepadDeviceId = currentInputSet.gamepadDeviceId
    end
    if not self.minGamepadDeviceId or currentInputSet.gamepadDeviceId < self.minGamepadDeviceId then
      self.minGamepadDeviceId = currentInputSet.gamepadDeviceId
    end
    return self:endWaitForInput()
  elseif not isAxis and buttonIsTriggered then
    currentInputSet.gamepadDeviceId = deviceId
    currentInputSet.gamepadButtonIds = buttonIds
    self.controlsMessage2Element:setText("")
    for _, inputSet in pairs(self.inputSets) do
      if inputSet.actionIdentifier ~= currentInputSet.actionIdentifier and next(Utils.getSetIntersection(currentInputSet.categories, inputSet.categories)) and inputSet.gamepadDeviceId == currentInputSet.gamepadDeviceId and inputSet.gamepadButtonIds and currentInputSet.gamepadButtonIds and Utils.areListsEqual(inputSet.gamepadButtonIds, currentInputSet.gamepadButtonIds) then
        self.controlsMessage2Element:setText(g_i18n:getText("ButtonAlreadyMapped") .. " (" .. inputSet.name .. ")")
      end
    end
    self.controlsMessage1Element:setText(string.format(g_i18n:getText("ActionRemapped"), currentInputSet.name, GamepadHelper.getButtonAndAxisNames(currentInputSet.gamepadButtonIds, currentInputSet.gamepadAxisId, currentInputSet.gamepadDeviceId)))
    self.userMadeChanges = true
    if not self.maxGamepadDeviceId or currentInputSet.gamepadDeviceId > self.maxGamepadDeviceId then
      self.maxGamepadDeviceId = currentInputSet.gamepadDeviceId
    end
    if not self.minGamepadDeviceId or currentInputSet.gamepadDeviceId < self.minGamepadDeviceId then
      self.minGamepadDeviceId = currentInputSet.gamepadDeviceId
    end
    return self:endWaitForInput()
  end
end
function ControlsScreen:draw()
  if self.isVisible then
    ControlsScreen:superClass().draw(self)
  end
end
function ControlsScreen:onDefaultsClick()
  self.yesNoDialog = g_gui:showGui("YesNoDialog")
  self.yesNoDialog.target:setText(g_i18n:getText("LoadDefaultsText"))
  self.yesNoDialog.target:setCallbacks(self.onLoadDefaultsCallback, self)
end
function ControlsScreen:onAdvancedClick()
  if self.userMadeChanges then
    self.yesNoDialog = g_gui:showGui("YesNoDialog")
    self.yesNoDialog.target:setText(g_i18n:getText("LoseChangesText"))
    self.yesNoDialog.target:setCallbacks(self.onLoseChangesAdvancedControlsCallback, self)
  else
    g_gui:showGui("AdvancedControlsScreen")
  end
end
function ControlsScreen:onSaveClick()
  self:saveBindings()
  InputBinding.saveToXML()
  g_gui:showGui("SettingsScreen")
end
function ControlsScreen:onCancelClick()
  if self.userMadeChanges then
    self.yesNoDialog = g_gui:showGui("YesNoDialog")
    self.yesNoDialog.target:setText(g_i18n:getText("LoseChangesText"))
    self.yesNoDialog.target:setCallbacks(self.onLoseChangesCallback, self)
  else
    g_gui:showGui("SettingsScreen")
  end
end
function ControlsScreen:onLoadDefaultsCallback(yes)
  self.yesNoDialog = nil
  if yes then
    local inputBindingPathTemplate = getAppBasePath() .. "profileTemplate/inputBindingDefault.xml"
    copyFile(inputBindingPathTemplate, g_inputBindingPath, true)
    InputBinding.load()
    g_gui:showGui("SettingsScreen")
  else
    self.screenClosedTemporarily = true
    g_gui:showGui("ControlsScreen")
  end
end
function ControlsScreen:onLoseChangesCallback(yes)
  self.yesNoDialog = nil
  if yes then
    self.userMadeChanges = false
    g_gui:showGui("SettingsScreen")
  else
    self.screenClosedTemporarily = true
    g_gui:showGui("ControlsScreen")
  end
end
function ControlsScreen:onLoseChangesAdvancedControlsCallback(yes)
  self.yesNoDialog = nil
  if yes then
    self.userMadeChanges = false
    g_gui:showGui("AdvancedControlsScreen")
  else
    self.screenClosedTemporarily = true
    g_gui:showGui("ControlsScreen")
  end
end
function ControlsScreen:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onCancelClick()
  end
end
