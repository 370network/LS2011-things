g_inputButtonEvent = {}
g_inputButtonLast = {}
g_inputButtonType = {}
InputBinding = {}
InputBinding.externalInputButtons = {
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
}
InputBinding.externalAnalogAxes = {}
InputBinding.externalDigitalAxes = {}
InputBinding.analogAxes = {
  0,
  0,
  0,
  0
}
InputBinding.digitalAxes = {
  0,
  0,
  0,
  0
}
InputBinding.digitalActionIds = {}
InputBinding.analogActionIds = {}
InputBinding.digitalActions = {}
InputBinding.analogActions = {}
InputBinding.digitalActionBlockingData = {}
InputBinding.analogActionBlockingData = {}
InputBinding.mouseButtonState = {}
InputBinding.wrapMousePositionEnabled = false
InputBinding.mouseMotionScaleXDefault = 0.75
InputBinding.mouseMotionScaleYDefault = 0.75
InputBinding.mouseMotionScaleX = 0.75
InputBinding.mouseMotionScaleY = 0.75
InputBinding.NUM_ANALOG_ACTIONS = 0
InputBinding.NUM_DIGITAL_ACTIONS = 0
InputBinding.version = 3
InputBinding.INPUTTYPE_NONE = 0
InputBinding.INPUTTYPE_KEYBOARD = 1
InputBinding.INPUTTYPE_MOUSE_BUTTON = 2
InputBinding.INPUTTYPE_MOUSE_WHEEL = 3
InputBinding.INPUTTYPE_GAMEPAD = 3
InputBinding.wasPrintKeyPressed = false
InputBinding.modDigitalActionDefaultData = {}
function InputBinding.getGamepadDeviceIdOfDigitalAction(actionIndex)
  return InputBinding.digitalActions[actionIndex].gamepadDevice
end
function InputBinding.getMouseButtonOfDigitalAction(actionIndex)
  return InputBinding.digitalActions[actionIndex].mouseButton
end
function InputBinding.hasEvent(actionIndex, removeEvent)
  if g_inputButtonEvent[actionIndex] then
    if removeEvent then
      for eventId, _ in pairs(g_inputButtonEvent) do
        g_inputButtonEvent[eventId] = false
      end
    end
    return true
  else
    return false
  end
end
function InputBinding.isPressed(actionIndex)
  return g_inputButtonLast[actionIndex]
end
function InputBinding.getInputTypeOfDigitalAction(actionIndex)
  return g_inputButtonType[actionIndex]
end
function InputBinding.getKeyNamesOfDigitalAction(actionIndex)
  local digitalActionData = InputBinding.digitalActions[actionIndex]
  local getKeyNames = function(keys)
    local finalString
    local keyString = KeyboardHelper.getKeyNames(keys)
    if #keys <= 1 then
      finalString = g_i18n:getText("Key") .. " " .. string.upper(keyString)
    else
      finalString = g_i18n:getText("Keys") .. " " .. string.upper(keyString)
    end
    return finalString
  end
  if digitalActionData.keys1 then
    return getKeyNames(digitalActionData.keys1)
  elseif digitalActionData.keys2 then
    return getKeyNames(digitalActionData.keys2)
  else
    return ""
  end
end
function InputBinding.getDigitalActionGamepadButtonNames(actionIndex)
  local digitalActionData = InputBinding.digitalActions[actionIndex]
  return GamepadHelper.getButtonNames(digitalActionData.gamepadButtons, digitalActionData.gamepadDevice)
end
function InputBinding.isAxisZero(value)
  return value == nil or math.abs(value) < 1.0E-4
end
function InputBinding.getDigitalInputAxis(axis)
  local input = Utils.getNoNil(InputBinding.digitalAxes[axis], 0)
  if InputBinding.isAxisZero(input) then
    for i = 1, table.getn(InputBinding.externalDigitalAxes) do
      input = Utils.getNoNil(InputBinding.externalDigitalAxes[i][axis], 0)
      if not InputBinding.isAxisZero(input) then
        break
      end
    end
  end
  return input
end
function InputBinding.getAnalogInputAxis(axis)
  local input = Utils.getNoNil(InputBinding.analogAxes[axis], 0)
  if InputBinding.isAxisZero(input) then
    for i = 1, table.getn(InputBinding.externalAnalogAxes) do
      input = Utils.getNoNil(InputBinding.externalAnalogAxes[i][axis], 0)
      if not InputBinding.isAxisZero(input) then
        break
      end
    end
  end
  return input
end
function InputBinding.registerDigitalInputAxis()
  table.insert(InputBinding.externalDigitalAxes, {
    0,
    0,
    0,
    0
  })
  return table.getn(InputBinding.externalDigitalAxes)
end
function InputBinding.registerAnalogInputAxis()
  table.insert(InputBinding.externalAnalogAxes, {
    0,
    0,
    0,
    0
  })
  return table.getn(InputBinding.externalAnalogAxes)
end
function InputBinding.setDigitalInputAxis(id, axis, value)
  for actionIndex, actionData in pairs(InputBinding.analogActions) do
    if actionData.gamepadAxis == axis then
      if actionData.gamepadAxisInvert then
        InputBinding.externalDigitalAxes[id][actionIndex] = -value
      else
        InputBinding.externalDigitalAxes[id][actionIndex] = value
      end
    end
  end
end
function InputBinding.setAnalogInputAxis(id, axis, value)
  for actionIndex, actionData in pairs(InputBinding.analogActions) do
    if actionData.gamepadAxis == axis then
      if actionData.gamepadAxisInvert then
        InputBinding.externalAnalogAxes[id][actionIndex] = -value
      else
        InputBinding.externalAnalogAxes[id][actionIndex] = value
      end
    end
  end
end
function InputBinding.addDownButton(button)
  if 1 <= button and button <= 16 then
    InputBinding.externalInputButtons[button] = InputBinding.externalInputButtons[button] + 1
  end
end
function InputBinding.removeDownButton(button)
  if 1 <= button and button <= 16 then
    InputBinding.externalInputButtons[button] = math.max(InputBinding.externalInputButtons[button] - 1, 0)
  end
end
function InputBinding.checkFormat()
  local isNewFormat = true
  local xmlFile = loadXMLFile("InputBindings", g_inputBindingPath)
  local i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "INVALID")
    if inputKey1 == "INVALID" then
      isNewFormat = false
      break
    end
    i = i + 1
  end
  delete(xmlFile)
  return isNewFormat
end
function InputBinding.checkVersion(inputBindingPath, inputBindingPathTemplate)
  local xmlFile1 = loadXMLFile("InputBindings1", inputBindingPath)
  local xmlFile2 = loadXMLFile("InputBindings2", inputBindingPathTemplate)
  local version1 = Utils.getNoNil(getXMLFloat(xmlFile1, "inputBinding#version"), 0.1)
  local version2 = Utils.getNoNil(getXMLFloat(xmlFile2, "inputBinding#version"), 0.1)
  if version1 ~= version2 then
    return false
  end
  return true
end
function InputBinding.load()
  local xmlFile = loadXMLFile("InputBindings", g_inputBindingPath)
  InputBinding.version = Utils.getNoNil(getXMLFloat(xmlFile, "inputBinding#version"), 0.1)
  InputBinding.mouseMotionScaleX = Utils.getNoNil(getXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleX"), 1) * InputBinding.mouseMotionScaleXDefault
  InputBinding.mouseMotionScaleY = Utils.getNoNil(getXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleY"), 1) * InputBinding.mouseMotionScaleYDefault
  InputBinding.NUM_DIGITAL_ACTIONS = 0
  InputBinding.NUM_ANALOG_ACTIONS = 0
  local i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    InputBinding.loadInputButtonFromXML(xmlFile, baseName, nil, false)
    i = i + 1
  end
  i = 0
  while true do
    local baseName = string.format("inputBinding.axis(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    InputBinding.loadInputAxisFromXML(xmlFile, baseName, nil, false)
    i = i + 1
  end
  delete(xmlFile)
  for actionIndex, defaultData in pairs(InputBinding.modDigitalActionDefaultData) do
    actionIndex = InputBinding[defaultData.name]
    digitalActionTable = InputBinding.digitalActions[actionIndex]
    digitalActionTable.name = defaultData.name
    digitalActionTable.keys1 = defaultData.keys1
    digitalActionTable.key1, digitalActionTable.key1Modifiers = InputBinding.splitActivatingAndModifyingKeys(defaultData.keys1)
    digitalActionTable.keys2 = defaultData.keys2
    digitalActionTable.key2, digitalActionTable.key2Modifiers = InputBinding.splitActivatingAndModifyingKeys(defaultData.keys2)
    digitalActionTable.gamepadButtons = defaultData.gamepadButtons
    digitalActionTable.gamepadButton, digitalActionTable.gamepadButtonModifiers = InputBinding.splitActivatingAndModifyingGamepadButtons(defaultData.gamepadButtons)
    digitalActionTable.gamepadDevice = defaultData.gamepadDevice
    digitalActionTable.mouseButton = defaultData.mouseButton
    digitalActionTable.categories = defaultData.categories
    digitalActionTable.isMod = true
    digitalActionTable.customEnvironment = defaultData.customEnvironment
  end
  for i = 1, 16 do
  end
  for actionIndex, actionData in pairs(InputBinding.analogActions) do
    if actionData.gamepadAxis then
    end
  end
  InputBinding.setBlockingInputForActions()
end
function InputBinding.loadInputButtonFromXML(xmlFile, baseName, customEnvironment, isMod)
  local inputName = getXMLString(xmlFile, baseName .. "#name")
  if inputName == nil or inputName == "" then
    return
  end
  local isReusingExistingAction = InputBinding[inputName] ~= nil and isMod
  local inputKeys1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "")
  local inputKeys2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key2"), "")
  local inputButtons = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button"), "")
  local inputButtonDevice = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#device"), 0)
  local inputMouseButton = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#mouse"), "")
  local inputCategories = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#category"), "")
  local inputData
  if not isReusingExistingAction or isMod then
    local mouseButton
    if inputMouseButton ~= "" then
      if Input[inputMouseButton] == nil then
        print("Error: invalid mouse button '" .. inputMouseButton .. "'  for input event '" .. inputName .. "'")
        return
      else
        mouseButton = Input[inputMouseButton]
      end
    end
    inputData = {}
    inputData.name = inputName
    inputData.keys1 = InputBinding.loadKeyList(inputKeys1, inputName)
    inputData.key1, inputData.key1Modifiers = InputBinding.splitActivatingAndModifyingKeys(inputData.keys1)
    inputData.keys2 = InputBinding.loadKeyList(inputKeys2, inputName)
    inputData.key2, inputData.key2Modifiers = InputBinding.splitActivatingAndModifyingKeys(inputData.keys2)
    inputData.gamepadButtons = InputBinding.loadGamepadButtonList(inputButtons, inputName)
    inputData.gamepadButton, inputData.gamepadButtonModifiers = InputBinding.splitActivatingAndModifyingGamepadButtons(inputData.gamepadButtons)
    inputData.gamepadDevice = inputButtonDevice
    inputData.mouseButton = mouseButton
    inputData.categories = Utils.listToSet(Utils.splitString(" ", inputCategories))
  end
  local actionIndex = InputBinding.NUM_DIGITAL_ACTIONS + 1
  local digitalActionTable
  if isReusingExistingAction then
    actionIndex = InputBinding[inputName]
    digitalActionTable = InputBinding.digitalActions[actionIndex]
  else
    InputBinding[inputName] = actionIndex
    InputBinding.digitalActionIds[inputName] = actionIndex
    digitalActionTable = inputData
    InputBinding.digitalActions[actionIndex] = digitalActionTable
  end
  digitalActionTable.isMod = digitalActionTable.isMod or isMod
  digitalActionTable.customEnvironment = Utils.getNoNil(digitalActionTable.customEnvironment, customEnvironment)
  if not isReusingExistingAction then
    g_inputButtonEvent[actionIndex] = false
    g_inputButtonLast[actionIndex] = false
    g_inputButtonType[actionIndex] = InputBinding.INPUTTYPE_NONE
    InputBinding.NUM_DIGITAL_ACTIONS = InputBinding.NUM_DIGITAL_ACTIONS + 1
  end
  if isMod then
    local defaultData = {}
    InputBinding.modDigitalActionDefaultData[actionIndex] = defaultData
    defaultData.name = inputName
    defaultData.keys1 = inputData.keys1
    defaultData.keys2 = inputData.keys2
    defaultData.gamepadButtons = inputData.gamepadButtons
    defaultData.gamepadDevice = inputData.gamepadDevice
    defaultData.mouseButton = inputData.mouseButton
    defaultData.categories = inputData.categories
    defaultData.customEnvironment = digitalActionTable.customEnvironment
  end
end
function InputBinding.loadInputAxisFromXML(xmlFile, baseName, customEnvironment, isMod)
  local axisActionName = getXMLString(xmlFile, baseName .. "#name")
  if axisActionName == nil or axisActionName == "" then
    return
  end
  local isReusingExistingAction = InputBinding[inputName] ~= nil and isMod
  local axisKeys1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "")
  local axisKeys2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key2"), "")
  local axisKeys3 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key3"), "")
  local axisKeys4 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key4"), "")
  local axisButtons = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button"), "")
  local axisAxis = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#axis"), "")
  local axisButton1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button1"), "")
  local axisButton2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button2"), "")
  local axisDevice = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#device"), 0)
  local invert = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invert"), false)
  local axisCategories = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#category"), "")
  local axis
  if axisAxis ~= "" then
    axis = Input[axisAxis]
  end
  local actionIndex = InputBinding.NUM_ANALOG_ACTIONS + 1
  local analogActionTable = {}
  if isReusingExistingAction then
    actionIndex = InputBinding[axisActionName]
    analogActionTable = InputBinding.analogActions[actionIndex]
  else
    InputBinding[axisActionName] = actionIndex
    InputBinding.analogActionIds[axisActionName] = actionIndex
    local analogActionTable = {}
    InputBinding.analogActions[actionIndex] = analogActionTable
    analogActionTable.name = axisActionName
    analogActionTable.keys1 = InputBinding.loadKeyList(axisKeys1, axisActionName)
    analogActionTable.key1, analogActionTable.key1Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionTable.keys1)
    analogActionTable.keys2 = InputBinding.loadKeyList(axisKeys2, axisActionName)
    analogActionTable.key2, analogActionTable.key2Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionTable.keys2)
    analogActionTable.keys3 = InputBinding.loadKeyList(axisKeys3, axisActionName)
    analogActionTable.key3, analogActionTable.key3Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionTable.keys3)
    analogActionTable.keys4 = InputBinding.loadKeyList(axisKeys4, axisActionName)
    analogActionTable.key4, analogActionTable.key4Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionTable.keys4)
    analogActionTable.gamepadUsesDigitalInput = axis == nil
    if analogActionTable.gamepadUsesDigitalInput then
      local buttons1 = InputBinding.loadGamepadButtonList(axisButton1, axisActionName)
      analogActionTable.gamepadButtons1 = buttons1
      local buttons2 = InputBinding.loadGamepadButtonList(axisButton2, axisActionName)
      analogActionTable.gamepadButtons2 = buttons2
      analogActionTable.gamepadButtons = {}
      analogActionTable.gamepadAxis = nil
    else
      analogActionTable.gamepadButtons = InputBinding.loadGamepadButtonList(axisButtons, axisActionName)
      analogActionTable.gamepadAxis = axis
      analogActionTable.gamepadButtons1 = {}
      analogActionTable.gamepadButtons2 = {}
    end
    analogActionTable.gamepadAxisInvert = invert
    analogActionTable.gamepadDevice = axisDevice
    analogActionTable.categories = Utils.listToSet(Utils.splitString(" ", axisCategories))
  end
  analogActionTable.isMod = analogActionTable.isMod or isMod
  analogActionTable.customEnvironment = Utils.getNoNil(analogActionTable.customEnvironment, customEnvironment)
  if not isReusingExistingAction then
    InputBinding.NUM_ANALOG_ACTIONS = InputBinding.NUM_ANALOG_ACTIONS + 1
  end
end
function InputBinding.loadKeyList(inputKeyString, inputName)
  if inputKeyString ~= "" then
    local inputKeyList = Utils.splitString(" ", inputKeyString)
    local keyList = {}
    local keysCount = #inputKeyList
    for i = 1, keysCount do
      local keyInput = inputKeyList[i]
      if Input[keyInput] == nil then
        print("Error: invalid key '" .. keyInput .. "'  for input event '" .. inputName .. "'")
        return {}, nil, {}
      end
      keyList[i] = Input[keyInput]
    end
    return keyList
  else
    return {}
  end
end
function InputBinding.splitActivatingAndModifyingKeys(keyList)
  local keyId
  local keyModifierIdList = {}
  local keysCount = #keyList
  for i = 1, keysCount - 1 do
    keyModifierIdList[i] = keyList[i]
  end
  keyId = keyList[keysCount]
  return keyId, keyModifierIdList
end
function InputBinding.loadGamepadButtonList(inputButtonString, inputName)
  if inputButtonString ~= "" then
    local inputButtonList = Utils.splitString(" ", inputButtonString)
    local buttonList = {}
    local activatingButtonId
    local modifyingButtonIdList = {}
    local deviceList = {}
    local activatingButtonDeviceId
    local modifyingButtonDeviceIdList = {}
    local buttonsCount = #inputButtonList
    for i, buttonInput in ipairs(inputButtonList) do
      local buttonString
      local deviceString = string.gmatch(buttonInput, ".+%[(%d+%)]")()
      local deviceId
      if not deviceString then
        buttonString = buttonInput
        deviceId = 0
      else
        buttonString = string.gmatch(buttonInput, "(.+)%[%d+%]")()
        deviceId = tonumber(deviceString)
      end
      if not buttonString or Input[buttonString] == nil or not deviceId then
        print("Error: invalid button '" .. buttonInput .. "'  for input event '" .. inputName .. "'")
        return {}, nil, {}, {}, nil, {}
      else
        if i == buttonsCount then
          activatingButtonId = Input[buttonString]
          activatingButtonDeviceId = deviceId
        else
          modifyingButtonIdList[i] = Input[buttonString]
          modifyingButtonDeviceIdList[i] = deviceId
        end
        buttonList[i] = Input[buttonString]
        deviceList[i] = deviceId
      end
    end
    return buttonList, activatingButtonId, modifyingButtonIdList, deviceList, activatingButtonDeviceId, modifyingButtonDeviceIdList
  else
    return {}, nil, {}, {}, nil, {}
  end
end
function InputBinding.splitActivatingAndModifyingGamepadButtons(buttonList)
  local activatingButtonId
  local modifyingButtonIdList = {}
  local buttonsCount = #buttonList
  for i = 1, buttonsCount - 1 do
    modifyingButtonIdList[i] = buttonList[i]
  end
  activatingButtonId = buttonList[buttonsCount]
  return activatingButtonId, modifyingButtonIdList
end
function InputBinding.setBlockingInputForActions()
  InputBinding.digitalActionBlockingData = {}
  InputBinding.analogActionBlockingData = {}
  local gamepadButtonIdentifiers = {}
  local function getGamepadButtonIdentifier(gamepadId, buttonId)
    if not gamepadButtonIdentifiers[gamepadId] then
      gamepadButtonIdentifiers[gamepadId] = {}
    end
    if not gamepadButtonIdentifiers[gamepadId][buttonId] then
      gamepadButtonIdentifiers[gamepadId][buttonId] = {
        true,
        gamepadId,
        buttonId
      }
    end
    return gamepadButtonIdentifiers[gamepadId][buttonId]
  end
  local gamepadAxisIdentifiers = {}
  local function getGamepadAxisIdentifier(gamepadId, axisId)
    if not gamepadAxisIdentifiers[gamepadId] then
      gamepadAxisIdentifiers[gamepadId] = {}
    end
    if not gamepadAxisIdentifiers[gamepadId][axisId] then
      gamepadAxisIdentifiers[gamepadId][axisId] = {
        false,
        gamepadId,
        axisId
      }
    end
    return gamepadAxisIdentifiers[gamepadId][axisId]
  end
  local digitalActionData = {}
  local digitalActionBlockingData = {}
  for actionIndex, actionData in pairs(InputBinding.digitalActions) do
    local gamepadSet = {}
    for _, buttonId in ipairs(actionData.gamepadButtons) do
      gamepadSet[getGamepadButtonIdentifier(actionData.gamepadDevice, buttonId)] = true
    end
    digitalActionData[actionIndex] = {
      categorySet = actionData.categories,
      activatingKey1Set = Utils.listToSet({
        actionData.key1
      }),
      modifyingKey1Set = Utils.listToSet(actionData.key1Modifiers),
      activatingKey2Set = Utils.listToSet({
        actionData.key2
      }),
      modifyingKey2Set = Utils.listToSet(actionData.key2Modifiers),
      gamepadSet = gamepadSet
    }
    digitalActionBlockingData[actionIndex] = {
      blockingKey1SetList = {},
      blockingKey2SetList = {},
      blockingDigitalActionSet = {},
      blockingAnalogActionSet = {},
      blockingGamepadButtonSetList = {}
    }
  end
  local analogActionData = {}
  local analogActionBlockingData = {}
  for actionIndex, actionData in pairs(InputBinding.analogActions) do
    local activatingGamepadSet = {}
    local modifyingGamepadSet = {}
    local activatingGamepadButton1Set = {}
    local activatingGamepadButton2Set = {}
    if actionData.gamepadAxis then
      activatingGamepadSet[getGamepadAxisIdentifier(actionData.gamepadDevice, actionData.gamepadAxis)] = true
    end
    for _, buttonId in ipairs(actionData.gamepadButtons) do
      modifyingGamepadSet[getGamepadButtonIdentifier(actionData.gamepadDevice, buttonId)] = true
    end
    for _, buttonId in ipairs(actionData.gamepadButtons1) do
      activatingGamepadButton1Set[getGamepadButtonIdentifier(actionData.gamepadDevice, buttonId)] = true
    end
    for _, buttonId in ipairs(actionData.gamepadButtons2) do
      activatingGamepadButton2Set[getGamepadButtonIdentifier(actionData.gamepadDevice, buttonId)] = true
    end
    analogActionData[actionIndex] = {
      categorySet = actionData.categories,
      activatingKey1Set = Utils.listToSet({
        actionData.key1
      }),
      modifyingKey1Set = Utils.listToSet(actionData.key1Modifiers),
      activatingKey2Set = Utils.listToSet({
        actionData.key2
      }),
      modifyingKey2Set = Utils.listToSet(actionData.key2Modifiers),
      activatingKey3Set = Utils.listToSet({
        actionData.key3
      }),
      modifyingKey3Set = Utils.listToSet(actionData.key3Modifiers),
      activatingKey4Set = Utils.listToSet({
        actionData.key4
      }),
      modifyingKey4Set = Utils.listToSet(actionData.key4Modifiers),
      activatingGamepadSet = activatingGamepadSet,
      modifyingGamepadSet = modifyingGamepadSet,
      activatingGamepadButton1Set = activatingGamepadButton1Set,
      activatingGamepadButton2Set = activatingGamepadButton2Set
    }
    analogActionBlockingData[actionIndex] = {
      blockingKey1SetList = {},
      blockingKey2SetList = {},
      blockingDigitalActionSet = {},
      blockingAnalogActionSet = {},
      blockingGamepadButtonSetList = {}
    }
  end
  local checkAnalogActionBlockingKeys = function(actionDataTable, actionBlockingDataTable, actionIndex, actionIndexToCheck, actionBlockingKeyNumber, actionKeyNumber, actionToCheckKeyNumber)
    if next(Utils.getSetIntersection(actionDataTable[actionIndex]["activatingKey" .. actionKeyNumber .. "Set"], actionDataTable[actionIndexToCheck]["activatingKey" .. actionToCheckKeyNumber .. "Set"])) and Utils.isRealSubset(actionDataTable[actionIndex]["modifyingKey" .. actionKeyNumber .. "Set"], actionDataTable[actionIndexToCheck]["modifyingKey" .. actionToCheckKeyNumber .. "Set"]) then
      table.insert(actionBlockingDataTable[actionIndex]["blockingKey" .. actionBlockingKeyNumber .. "SetList"], actionDataTable[actionIndexToCheck]["modifyingKey" .. actionToCheckKeyNumber .. "Set"])
      actionBlockingDataTable[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
    end
  end
  for actionIndex, _ in pairs(InputBinding.digitalActions) do
    for actionIndexToCheck, _ in pairs(InputBinding.digitalActions) do
      if actionIndexToCheck ~= actionIndex and next(Utils.getSetIntersection(digitalActionData[actionIndex].categorySet, digitalActionData[actionIndexToCheck].categorySet)) then
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, digitalActionData[actionIndexToCheck].activatingKey1Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, digitalActionData[actionIndexToCheck].modifyingKey1Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, digitalActionData[actionIndexToCheck].modifyingKey1Set)
          digitalActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, digitalActionData[actionIndexToCheck].activatingKey2Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, digitalActionData[actionIndexToCheck].modifyingKey2Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, digitalActionData[actionIndexToCheck].modifyingKey2Set)
          digitalActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, digitalActionData[actionIndexToCheck].activatingKey2Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, digitalActionData[actionIndexToCheck].modifyingKey2Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, digitalActionData[actionIndexToCheck].modifyingKey2Set)
          digitalActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, digitalActionData[actionIndexToCheck].activatingKey1Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, digitalActionData[actionIndexToCheck].modifyingKey1Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, digitalActionData[actionIndexToCheck].modifyingKey1Set)
          digitalActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].gamepadSet, digitalActionData[actionIndexToCheck].gamepadSet)) and Utils.isRealSubset(digitalActionData[actionIndex].gamepadSet, digitalActionData[actionIndexToCheck].gamepadSet) then
          table.insert(digitalActionBlockingData[actionIndex].blockingGamepadButtonSetList, digitalActionData[actionIndexToCheck].gamepadSet)
          digitalActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
      end
    end
    for actionIndexToCheck, _ in pairs(InputBinding.analogActions) do
      if next(Utils.getSetIntersection(digitalActionData[actionIndex].categorySet, analogActionData[actionIndexToCheck].categorySet)) then
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, analogActionData[actionIndexToCheck].activatingKey1Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, analogActionData[actionIndexToCheck].modifyingKey1Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, analogActionData[actionIndexToCheck].modifyingKey1Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, analogActionData[actionIndexToCheck].activatingKey2Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, analogActionData[actionIndexToCheck].modifyingKey2Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, analogActionData[actionIndexToCheck].modifyingKey2Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, analogActionData[actionIndexToCheck].activatingKey3Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, analogActionData[actionIndexToCheck].modifyingKey3Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, analogActionData[actionIndexToCheck].modifyingKey3Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey1Set, analogActionData[actionIndexToCheck].activatingKey4Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey1Set, analogActionData[actionIndexToCheck].modifyingKey4Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey1SetList, analogActionData[actionIndexToCheck].modifyingKey4Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, analogActionData[actionIndexToCheck].activatingKey1Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, analogActionData[actionIndexToCheck].modifyingKey1Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, analogActionData[actionIndexToCheck].modifyingKey1Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, analogActionData[actionIndexToCheck].activatingKey2Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, analogActionData[actionIndexToCheck].modifyingKey2Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, analogActionData[actionIndexToCheck].modifyingKey2Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, analogActionData[actionIndexToCheck].activatingKey3Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, analogActionData[actionIndexToCheck].modifyingKey3Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, analogActionData[actionIndexToCheck].modifyingKey3Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].activatingKey2Set, analogActionData[actionIndexToCheck].activatingKey4Set)) and Utils.isRealSubset(digitalActionData[actionIndex].modifyingKey2Set, analogActionData[actionIndexToCheck].modifyingKey4Set) then
          table.insert(digitalActionBlockingData[actionIndex].blockingKey2SetList, analogActionData[actionIndexToCheck].modifyingKey4Set)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
        if next(Utils.getSetIntersection(digitalActionData[actionIndex].gamepadSet, analogActionData[actionIndexToCheck].modifyingGamepadSet)) and Utils.isSubset(digitalActionData[actionIndex].gamepadSet, analogActionData[actionIndexToCheck].modifyingGamepadSet) then
          table.insert(digitalActionBlockingData[actionIndex].blockingGamepadButtonSetList, analogActionData[actionIndexToCheck].modifyingGamepadSet)
          digitalActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
      end
    end
  end
  for actionIndex, _ in pairs(InputBinding.analogActions) do
    for actionIndexToCheck, _ in pairs(InputBinding.digitalActions) do
      if next(Utils.getSetIntersection(analogActionData[actionIndex].categorySet, digitalActionData[actionIndexToCheck].categorySet)) then
        if next(analogActionData[actionIndex].activatingGamepadButton1Set) and Utils.isRealSubset(analogActionData[actionIndex].activatingGamepadButton1Set, digitalActionData[actionIndexToCheck].gamepadSet) then
          table.insert(analogActionBlockingData[actionIndex].blockingGamepadButtonSetList, digitalActionData[actionIndexToCheck].gamepadSet)
          analogActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
        if next(analogActionData[actionIndex].activatingGamepadButton2Set) and Utils.isRealSubset(analogActionData[actionIndex].activatingGamepadButton2Set, digitalActionData[actionIndexToCheck].gamepadSet) then
          table.insert(analogActionBlockingData[actionIndex].blockingGamepadButtonSetList, digitalActionData[actionIndexToCheck].gamepadSet)
          analogActionBlockingData[actionIndex].blockingDigitalActionSet[actionIndexToCheck] = true
        end
      end
    end
    for actionIndexToCheck, _ in pairs(InputBinding.analogActions) do
      if actionIndexToCheck ~= actionIndex and next(Utils.getSetIntersection(analogActionData[actionIndex].categorySet, analogActionData[actionIndexToCheck].categorySet)) then
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 1, 1)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 1, 2)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 1, 3)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 1, 4)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 2, 1)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 2, 2)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 2, 3)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 1, 2, 4)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 3, 1)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 3, 2)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 3, 3)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 3, 4)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 4, 1)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 4, 2)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 4, 3)
        checkAnalogActionBlockingKeys(analogActionData, analogActionBlockingData, actionIndex, actionIndexToCheck, 2, 4, 4)
        if next(Utils.getSetIntersection(analogActionData[actionIndex].activatingGamepadSet, analogActionData[actionIndexToCheck].activatingGamepadSet)) and Utils.isRealSubset(analogActionData[actionIndex].modifyingGamepadSet, analogActionData[actionIndexToCheck].modifyingGamepadSet) then
          table.insert(analogActionBlockingData[actionIndex].blockingGamepadButtonSetList, analogActionData[actionIndexToCheck].modifyingGamepadSet)
          analogActionBlockingData[actionIndex].blockingAnalogActionSet[actionIndexToCheck] = true
        end
      end
    end
  end
  local optimizeSetList = function(setList)
    for i = #setList, 1, -1 do
      local set1 = setList[i]
      local setNotNeeded = true
      for element, _ in pairs(set1) do
        local elementNotNeeded = false
        for j, set2 in ipairs(setList) do
          if i ~= j and set2[element] and Utils.isSubset(set2, set1) then
            elementNotNeeded = true
            break
          end
        end
        if not elementNotNeeded then
          setNotNeeded = false
          break
        end
      end
      if setNotNeeded then
        table.remove(setList, i)
      end
    end
  end
  for actionIndex, actionBlockingData in pairs(digitalActionBlockingData) do
    local finalBlockingGamepadButtons = {}
    optimizeSetList(actionBlockingData.blockingGamepadButtonSetList)
    for i, gamepadSet in ipairs(actionBlockingData.blockingGamepadButtonSetList) do
      local buttonList, index = {}, 0
      for gamepadData, _ in pairs(gamepadSet) do
        if gamepadData[1] then
          index = index + 1
          buttonList[index] = gamepadData[3]
        end
      end
      finalBlockingGamepadButtons[i] = buttonList
    end
    local finalBlockingKey1ListOfLists = {}
    optimizeSetList(actionBlockingData.blockingKey1SetList)
    for i, keySet in ipairs(actionBlockingData.blockingKey1SetList) do
      local keyList, index = {}, 0
      for keyId, _ in pairs(keySet) do
        index = index + 1
        keyList[index] = keyId
      end
      finalBlockingKey1ListOfLists[i] = keyList
    end
    local finalBlockingKey2ListOfLists = {}
    optimizeSetList(actionBlockingData.blockingKey2SetList)
    for i, keySet in ipairs(actionBlockingData.blockingKey2SetList) do
      local keyList, index = {}, 0
      for keyId, _ in pairs(keySet) do
        index = index + 1
        keyList[index] = keyId
      end
      finalBlockingKey2ListOfLists[i] = keyList
    end
    InputBinding.digitalActionBlockingData[actionIndex] = {
      blockingKeys1 = finalBlockingKey1ListOfLists,
      blockingKeys2 = finalBlockingKey2ListOfLists,
      blockingGamepadButtons = finalBlockingGamepadButtons,
      blockingDigitalActions = Utils.setToList(digitalActionBlockingData[actionIndex].blockingDigitalActionSet),
      blockingAnalogActions = Utils.setToList(digitalActionBlockingData[actionIndex].blockingAnalogActionSet)
    }
  end
  for actionIndex, actionBlockingData in pairs(analogActionBlockingData) do
    local finalBlockingGamepadButtons = {}
    optimizeSetList(actionBlockingData.blockingGamepadButtonSetList)
    for i, gamepadSet in ipairs(actionBlockingData.blockingGamepadButtonSetList) do
      local buttonList, index = {}, 0
      for gamepadData, _ in pairs(gamepadSet) do
        if gamepadData[1] then
          index = index + 1
          buttonList[index] = gamepadData[3]
        end
      end
      finalBlockingGamepadButtons[i] = buttonList
    end
    local finalBlockingKey1ListOfLists = {}
    optimizeSetList(actionBlockingData.blockingKey1SetList)
    for i, keySet in ipairs(actionBlockingData.blockingKey1SetList) do
      local keyList, index = {}, 0
      for keyId, _ in pairs(keySet) do
        index = index + 1
        keyList[index] = keyId
      end
      finalBlockingKey1ListOfLists[i] = keyList
    end
    local finalBlockingKey2ListOfLists = {}
    optimizeSetList(actionBlockingData.blockingKey2SetList)
    for i, keySet in ipairs(actionBlockingData.blockingKey2SetList) do
      local keyList, index = {}, 0
      for keyId, _ in pairs(keySet) do
        index = index + 1
        keyList[index] = keyId
      end
      finalBlockingKey2ListOfLists[i] = keyList
    end
    InputBinding.analogActionBlockingData[actionIndex] = {
      blockingKeys1 = finalBlockingKey1ListOfLists,
      blockingKeys2 = finalBlockingKey2ListOfLists,
      blockingGamepadButtons = finalBlockingGamepadButtons,
      blockingDigitalActions = Utils.setToList(analogActionBlockingData[actionIndex].blockingDigitalActionSet),
      blockingAnalogActions = Utils.setToList(analogActionBlockingData[actionIndex].blockingAnalogActionSet)
    }
  end
end
function InputBinding.keyEvent(unicode, sym, modifier, isDown)
  if isDown and sym == Input.KEY_print then
    InputBinding.wasPrintKeyPressed = true
  end
end
function InputBinding.mouseEvent(posX, posY, isDown, isUp, button)
  if isDown then
    InputBinding.mouseButtonState[button] = true
  elseif button ~= Input.MOUSE_BUTTON_WHEEL_UP and button ~= Input.MOUSE_BUTTON_WHEEL_DOWN then
    InputBinding.mouseButtonState[button] = false
  end
  if InputBinding.mousePosXLast == nil or InputBinding.mousePosYLast == nil then
    InputBinding.mousePosXLast = posX
    InputBinding.mousePosYLast = posY
  end
  InputBinding.mouseMovementX = InputBinding.mouseMotionScaleX * (posX - InputBinding.mousePosXLast)
  InputBinding.mouseMovementY = InputBinding.mouseMotionScaleY * (posY - InputBinding.mousePosYLast)
  InputBinding.mousePosXLast = posX
  InputBinding.mousePosYLast = posY
end
function InputBinding.update(dt)
  local numGamepads = getNumOfGamepads()
  local inputButtons = {}
  for d = 0, numGamepads - 1 do
    inputButtons[d] = {}
    for i = 0, Input.MAX_NUM_BUTTONS - 1 do
      local isDown = 0 < getInputButton(i, d) or d == 0 and 0 < InputBinding.externalInputButtons[i + 1]
      inputButtons[d][i] = isDown
    end
  end
  for actionIndex, actionData in pairs(InputBinding.analogActions) do
    local blockingData = InputBinding.analogActionBlockingData[actionIndex]
    if actionData.gamepadAxis and inputButtons[actionData.gamepadDevice] then
      local isAxisActive = true
      if actionData.gamepadButtons[1] then
        for _, buttonId in ipairs(actionData.gamepadButtons) do
          if not inputButtons[actionData.gamepadDevice][buttonId] then
            isAxisActive = false
            break
          end
        end
      end
      if isAxisActive then
        for _, blockingButtonList in pairs(blockingData.blockingGamepadButtons) do
          local buttonSetPressed = true
          for _, buttonId in ipairs(blockingButtonList) do
            if not inputButtons[actionData.gamepadDevice][buttonId] then
              buttonSetPressed = false
              break
            end
          end
          if buttonSetPressed then
            isAxisActive = false
            break
          end
        end
      end
      if isAxisActive then
        if actionData.gamepadAxisInvert then
          InputBinding.analogAxes[actionIndex] = -getInputAxis(actionData.gamepadAxis, actionData.gamepadDevice)
        else
          InputBinding.analogAxes[actionIndex] = getInputAxis(actionData.gamepadAxis, actionData.gamepadDevice)
        end
      else
        InputBinding.analogAxes[actionIndex] = 0
      end
    end
    local positiveRangeActivated = false
    local negativeRangeActivated = false
    if Input.isKeyPressed(actionData.key1) and Input.areKeysPressed(actionData.key1Modifiers) then
      positiveRangeActivated = true
      for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys1) do
        if Input.areKeysPressed(blockingKeyCombinationList) then
          positiveRangeActivated = false
          break
        end
      end
    elseif Input.isKeyPressed(actionData.key3) and Input.areKeysPressed(actionData.key3Modifiers) then
      positiveRangeActivated = true
      for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys2) do
        if Input.areKeysPressed(blockingKeyCombinationList) then
          positiveRangeActivated = false
          break
        end
      end
    end
    if not positiveRangeActivated then
      if Input.isKeyPressed(actionData.key2) and Input.areKeysPressed(actionData.key2Modifiers) then
        negativeRangeActivated = true
        for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys1) do
          if Input.areKeysPressed(blockingKeyCombinationList) then
            negativeRangeActivated = false
            break
          end
        end
      elseif Input.isKeyPressed(actionData.key4) and Input.areKeysPressed(actionData.key4Modifiers) then
        negativeRangeActivated = true
        for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys2) do
          if Input.areKeysPressed(blockingKeyCombinationList) then
            negativeRangeActivated = false
            break
          end
        end
      end
    end
    if inputButtons[actionData.gamepadDevice] then
      if actionData.gamepadButtons1[1] and inputButtons[actionData.gamepadDevice][actionData.gamepadButtons1[1]] then
        local isBlocked = false
        for _, blockedButtonCombination in pairs(blockingData.blockingGamepadButtons) do
          local buttonCombinationPressed = true
          for _, buttonId in pairs(blockedButtonCombination) do
            if not inputButtons[actionData.gamepadDevice][buttonId] then
              buttonCombinationPressed = false
              break
            end
          end
          if buttonCombinationPressed then
            isBlocked = true
            break
          end
        end
        if not isBlocked then
          positiveRangeActivated = true
        end
      end
      if actionData.gamepadButtons2[1] and inputButtons[actionData.gamepadDevice][actionData.gamepadButtons2[1]] then
        local isBlocked = false
        for _, blockedButtonCombination in pairs(blockingData.blockingGamepadButtons) do
          local buttonCombinationPressed = true
          for _, buttonId in pairs(blockedButtonCombination) do
            if not inputButtons[actionData.gamepadDevice][buttonId] then
              buttonCombinationPressed = false
              break
            end
          end
          if buttonCombinationPressed then
            isBlocked = true
            break
          end
        end
        if not isBlocked then
          negativeRangeActivated = true
        end
      end
    end
    if positiveRangeActivated and negativeRangeActivated then
      InputBinding.digitalAxes[actionIndex] = 0
    elseif positiveRangeActivated then
      InputBinding.digitalAxes[actionIndex] = 1
    elseif negativeRangeActivated then
      InputBinding.digitalAxes[actionIndex] = -1
    else
      InputBinding.digitalAxes[actionIndex] = 0
    end
  end
  for actionIndex, actionData in pairs(InputBinding.digitalActions) do
    local blockingData = InputBinding.digitalActionBlockingData[actionIndex]
    local inputType = InputBinding.INPUTTYPE_NONE
    local isDown = false
    if actionData.key1 and (Input.isKeyPressed(actionData.key1) and Input.areKeysPressed(actionData.key1Modifiers) or actionData.key1 == Input.KEY_print and InputBinding.wasPrintKeyPressed) then
      local inputNotBlock = true
      for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys1) do
        if Input.areKeysPressed(blockingKeyCombinationList) then
          inputNotBlock = false
          break
        end
      end
      if inputNotBlock then
        isDown = true
        inputType = InputBinding.INPUTTYPE_KEYBOARD
      end
    end
    if actionData.key2 and (Input.isKeyPressed(actionData.key2) and Input.areKeysPressed(actionData.key2Modifiers) or actionData.key2 == Input.KEY_print and InputBinding.wasPrintKeyPressed) then
      local inputNotBlock = true
      for _, blockingKeyCombinationList in ipairs(blockingData.blockingKeys2) do
        if Input.areKeysPressed(blockingKeyCombinationList) then
          inputNotBlock = false
          break
        end
      end
      if inputNotBlock then
        isDown = true
        inputType = InputBinding.INPUTTYPE_KEYBOARD
      end
    end
    if actionData.gamepadButton and inputButtons[actionData.gamepadDevice] and inputButtons[actionData.gamepadDevice][actionData.gamepadButton] then
      local isPressed = true
      for _, buttonId in ipairs(actionData.gamepadButtonModifiers) do
        if not inputButtons[actionData.gamepadDevice][buttonId] then
          isPressed = false
          break
        end
      end
      if isPressed then
        local isBlocked = false
        for _, blockedButtonCombination in pairs(blockingData.blockingGamepadButtons) do
          local buttonCombinationPressed = true
          for _, buttonId in pairs(blockedButtonCombination) do
            if not inputButtons[actionData.gamepadDevice][buttonId] then
              buttonCombinationPressed = false
              break
            end
          end
          if buttonCombinationPressed then
            isBlocked = true
            break
          end
        end
        if not isBlocked then
          isDown = true
          inputType = InputBinding.INPUTTYPE_GAMEPAD
        end
      end
    end
    if actionData.mouseButton then
      local button = actionData.mouseButton
      if Utils.getNoNil(InputBinding.mouseButtonState[button], false) then
        isDown = true
        if button ~= Input.MOUSE_BUTTON_WHEEL_UP and button ~= Input.MOUSE_BUTTON_WHEEL_DOWN then
          inputType = InputBinding.INPUTTYPE_MOUSE_BUTTON
        else
          inputType = InputBinding.INPUTTYPE_MOUSE_WHEEL
        end
      end
    end
    g_inputButtonEvent[actionIndex] = isDown and not g_inputButtonLast[actionIndex]
    g_inputButtonLast[actionIndex] = isDown
    g_inputButtonType[actionIndex] = inputType
  end
  InputBinding.mouseButtonState[Input.MOUSE_BUTTON_WHEEL_UP] = false
  InputBinding.mouseButtonState[Input.MOUSE_BUTTON_WHEEL_DOWN] = false
  if InputBinding.wrapMousePositionEnabled then
    wrapMousePosition(0.5, 0.5)
    InputBinding.mousePosXLast = 0.5
    InputBinding.mousePosYLast = 0.5
  end
  InputBinding.wasPrintKeyPressed = false
end
function InputBinding.getBindings()
  local digitalBindingsHash = {}
  local digitalActionList = {}
  local analogBindingsHash = {}
  local analogActionList = {}
  for actionIdentifier, actionIndex in pairs(InputBinding.digitalActionIds) do
    local digitalActionData = InputBinding.digitalActions[actionIndex]
    digitalActionList[actionIndex] = actionIdentifier
    local i18n = g_i18n
    if digitalActionData.customEnvironment ~= nil then
      i18n = _G[digitalActionData.customEnvironment].g_i18n
    end
    digitalBindingsHash[actionIdentifier] = {}
    digitalBindingsHash[actionIdentifier].actionId = actionIndex
    digitalBindingsHash[actionIdentifier].actionIdentifier = actionIdentifier
    digitalBindingsHash[actionIdentifier].name = i18n:getText(actionIdentifier)
    digitalBindingsHash[actionIdentifier].key1Ids = digitalActionData.keys1
    digitalBindingsHash[actionIdentifier].key2Ids = digitalActionData.keys2
    digitalBindingsHash[actionIdentifier].mouseButtonId = digitalActionData.mouseButton
    digitalBindingsHash[actionIdentifier].mouseAxisId = nil
    digitalBindingsHash[actionIdentifier].gamepadButtonIds = digitalActionData.gamepadButtons
    digitalBindingsHash[actionIdentifier].gamepadAxisId = nil
    digitalBindingsHash[actionIdentifier].gamepadDeviceId = digitalBindingsHash[actionIdentifier].gamepadButtonIds and digitalActionData.gamepadDevice
    digitalBindingsHash[actionIdentifier].axisIsInverted = nil
    digitalBindingsHash[actionIdentifier].categories = digitalActionData.categories
  end
  for actionIdentifier, actionIndex in pairs(InputBinding.analogActionIds) do
    local analogActionData = InputBinding.analogActions[actionIndex]
    local negativeAxisActionIdentifier, positiveAxisActionIdentifier = InputBinding.getAxisActionIdentifiers(actionIdentifier)
    analogActionList[actionIndex] = actionIdentifier
    local i18n = g_i18n
    if analogActionData.customEnvironment ~= nil then
      i18n = _G[analogActionData.customEnvironment].g_i18n
    end
    analogBindingsHash[negativeAxisActionIdentifier] = {}
    analogBindingsHash[negativeAxisActionIdentifier].actionId = actionIndex
    analogBindingsHash[negativeAxisActionIdentifier].actionIdentifier = negativeAxisActionIdentifier
    analogBindingsHash[negativeAxisActionIdentifier].name = i18n:getText(negativeAxisActionIdentifier)
    analogBindingsHash[negativeAxisActionIdentifier].key1Ids = analogActionData.keys1
    analogBindingsHash[negativeAxisActionIdentifier].key2Ids = analogActionData.keys3
    analogBindingsHash[negativeAxisActionIdentifier].mouseButtonId = nil
    analogBindingsHash[negativeAxisActionIdentifier].mouseAxisId = nil
    if analogActionData.gamepadUsesDigitalInput then
      analogBindingsHash[negativeAxisActionIdentifier].gamepadButtonIds = analogActionData.gamepadButtons1
      analogBindingsHash[negativeAxisActionIdentifier].gamepadAxisId = nil
    else
      analogBindingsHash[negativeAxisActionIdentifier].gamepadButtonIds = analogActionData.gamepadButtons
      analogBindingsHash[negativeAxisActionIdentifier].gamepadAxisId = analogActionData.gamepadAxis
    end
    analogBindingsHash[negativeAxisActionIdentifier].gamepadDeviceId = (analogBindingsHash[negativeAxisActionIdentifier].gamepadAxisId or analogBindingsHash[negativeAxisActionIdentifier].gamepadButtonIds[1]) and analogActionData.gamepadDevice or nil
    analogBindingsHash[negativeAxisActionIdentifier].axisIsInverted = analogActionData.gamepadAxisInvert
    analogBindingsHash[negativeAxisActionIdentifier].categories = analogActionData.categories
    analogBindingsHash[positiveAxisActionIdentifier] = {}
    analogBindingsHash[positiveAxisActionIdentifier].actionId = actionIndex
    analogBindingsHash[positiveAxisActionIdentifier].actionIdentifier = positiveAxisActionIdentifier
    analogBindingsHash[positiveAxisActionIdentifier].name = i18n:getText(positiveAxisActionIdentifier)
    analogBindingsHash[positiveAxisActionIdentifier].key1Ids = analogActionData.keys2
    analogBindingsHash[positiveAxisActionIdentifier].key2Ids = analogActionData.keys4
    analogBindingsHash[positiveAxisActionIdentifier].mouseButtonId = nil
    analogBindingsHash[positiveAxisActionIdentifier].mouseAxisId = nil
    if analogActionData.gamepadUsesDigitalInput then
      analogBindingsHash[positiveAxisActionIdentifier].gamepadButtonIds = analogActionData.gamepadButtons2
      analogBindingsHash[positiveAxisActionIdentifier].gamepadAxisId = nil
    else
      analogBindingsHash[positiveAxisActionIdentifier].gamepadButtonIds = analogActionData.gamepadButtons
      analogBindingsHash[positiveAxisActionIdentifier].gamepadAxisId = analogActionData.gamepadAxis
    end
    analogBindingsHash[positiveAxisActionIdentifier].gamepadDeviceId = (analogBindingsHash[positiveAxisActionIdentifier].gamepadAxisId or analogBindingsHash[positiveAxisActionIdentifier].gamepadButtonIds[1]) and analogActionData.gamepadDevice or nil
    analogBindingsHash[positiveAxisActionIdentifier].axisIsInverted = analogActionData.gamepadAxisInvert
    analogBindingsHash[positiveAxisActionIdentifier].categories = analogActionData.categories
  end
  return digitalBindingsHash, analogBindingsHash, digitalActionList, analogActionList
end
function InputBinding.getAxisActionIdentifiers(actionIdentifier)
  return actionIdentifier .. "_1", actionIdentifier .. "_2"
end
function InputBinding.getActionIdentifierFromAxisActionIdentifier(axisActionIdentifier)
  return string.sub(axisActionIdentifier, 1, -3)
end
function InputBinding.isAxisActionIdentifier(actionIdentifier)
  return string.sub(actionIdentifier, -2, -1) == "_1" or string.sub(actionIdentifier, -2, -1) == "_2"
end
function InputBinding.isAxisActionIdentifierForNegativeAxis(actionIdentifier)
  return string.sub(actionIdentifier, -2, -1) == "_1"
end
function InputBinding.storeBindings(digitalBindings, analogBindings)
  for actionIdentifier, inputSet in pairs(digitalBindings) do
    local actionIndex = inputSet.actionId
    local digitalActionData = InputBinding.digitalActions[actionIndex]
    digitalActionData.keys1 = inputSet.key1Ids
    digitalActionData.key1, digitalActionData.key1Modifiers = InputBinding.splitActivatingAndModifyingKeys(digitalActionData.keys1)
    digitalActionData.keys2 = inputSet.key2Ids
    digitalActionData.key2, digitalActionData.key2Modifiers = InputBinding.splitActivatingAndModifyingKeys(digitalActionData.keys2)
    digitalActionData.mouseButton = inputSet.mouseButtonId
    digitalActionData.gamepadButtons = inputSet.gamepadButtonIds
    digitalActionData.gamepadButton, digitalActionData.gamepadButtonModifiers = InputBinding.splitActivatingAndModifyingGamepadButtons(digitalActionData.gamepadButtons)
    digitalActionData.gamepadDevice = inputSet.gamepadDeviceId or 0
  end
  for actionIdentifier, inputSet in pairs(analogBindings) do
    local actionIndex = inputSet.actionId
    local analogActionData = InputBinding.analogActions[actionIndex]
    local isNegativeAxis = InputBinding.isAxisActionIdentifierForNegativeAxis(actionIdentifier)
    analogActionData.gamepadUsesDigitalInput = inputSet.gamepadAxisId == nil
    if isNegativeAxis then
      analogActionData.keys1 = inputSet.key1Ids
      analogActionData.key1, analogActionData.key1Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionData.keys1)
      analogActionData.keys3 = inputSet.key2Ids
      analogActionData.key3, analogActionData.key3Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionData.keys3)
      if analogActionData.gamepadUsesDigitalInput then
        analogActionData.gamepadButtons1 = inputSet.gamepadButtonIds
      else
        analogActionData.gamepadButtons1 = {}
      end
    else
      analogActionData.keys2 = inputSet.key1Ids
      analogActionData.key2, analogActionData.key2Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionData.keys2)
      analogActionData.keys4 = inputSet.key2Ids
      analogActionData.key4, analogActionData.key4Modifiers = InputBinding.splitActivatingAndModifyingKeys(analogActionData.keys4)
      if analogActionData.gamepadUsesDigitalInput then
        analogActionData.gamepadButtons2 = inputSet.gamepadButtonIds
      else
        analogActionData.gamepadButtons2 = {}
      end
    end
    if analogActionData.gamepadUsesDigitalInput then
      analogActionData.gamepadButtons = {}
      analogActionData.gamepadAxis = nil
    else
      analogActionData.gamepadButtons = inputSet.gamepadButtonIds
      analogActionData.gamepadAxis = inputSet.gamepadAxisId
    end
    analogActionData.gamepadDevice = inputSet.gamepadDeviceId or 0
    analogActionData.gamepadAxisInvert = inputSet.axisIsInverted
  end
  InputBinding.setBlockingInputForActions()
end
function InputBinding.saveSettingsToXML()
  local xmlFile = loadXMLFile("InputBindings", g_inputBindingPath)
  setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleX", InputBinding.mouseMotionScaleX / InputBinding.mouseMotionScaleXDefault)
  setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleY", InputBinding.mouseMotionScaleY / InputBinding.mouseMotionScaleYDefault)
  saveXMLFile(xmlFile)
  delete(xmlFile)
end
function InputBinding.saveToXML()
  local xmlFile = loadXMLFile("InputBindings", g_inputBindingPath)
  local i = 0
  local i = 0
  for actionIndex, digitalActionData in ipairs(InputBinding.digitalActions) do
    local baseName = string.format("inputBinding.input(%d)", i)
    setXMLString(xmlFile, baseName .. "#name", digitalActionData.name)
    setXMLString(xmlFile, baseName .. "#key1", KeyboardHelper.getKeysXMLString(digitalActionData.keys1))
    setXMLString(xmlFile, baseName .. "#key2", KeyboardHelper.getKeysXMLString(digitalActionData.keys2))
    setXMLString(xmlFile, baseName .. "#mouse", MouseHelper.getButtonXMLString(digitalActionData.mouseButton))
    setXMLString(xmlFile, baseName .. "#button", GamepadHelper.getButtonsXMLString(digitalActionData.gamepadButtons))
    setXMLInt(xmlFile, baseName .. "#device", GamepadHelper.getDeviceXMLInt(digitalActionData.gamepadDevice))
    local categoriesList = Utils.setToList(digitalActionData.categories)
    table.sort(categoriesList)
    setXMLString(xmlFile, baseName .. "#category", table.concat(categoriesList, " "))
    i = i + 1
  end
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    setXMLString(xmlFile, baseName .. "#name", "")
    i = i + 1
  end
  local i = 0
  for actionIndex, analogActionData in ipairs(InputBinding.analogActions) do
    local baseName = string.format("inputBinding.axis(%d)", i)
    setXMLString(xmlFile, baseName .. "#name", analogActionData.name)
    setXMLString(xmlFile, baseName .. "#key1", KeyboardHelper.getKeysXMLString(analogActionData.keys1))
    setXMLString(xmlFile, baseName .. "#key2", KeyboardHelper.getKeysXMLString(analogActionData.keys2))
    setXMLString(xmlFile, baseName .. "#key3", KeyboardHelper.getKeysXMLString(analogActionData.keys3))
    setXMLString(xmlFile, baseName .. "#key4", KeyboardHelper.getKeysXMLString(analogActionData.keys4))
    setXMLString(xmlFile, baseName .. "#button", GamepadHelper.getButtonsXMLString(analogActionData.gamepadButtons))
    setXMLString(xmlFile, baseName .. "#axis", GamepadHelper.getAxisXMLString(analogActionData.gamepadAxis))
    setXMLString(xmlFile, baseName .. "#button1", GamepadHelper.getButtonsXMLString(analogActionData.gamepadButtons1))
    setXMLString(xmlFile, baseName .. "#button2", GamepadHelper.getButtonsXMLString(analogActionData.gamepadButtons2))
    setXMLInt(xmlFile, baseName .. "#device", GamepadHelper.getDeviceXMLInt(analogActionData.gamepadDevice))
    setXMLBool(xmlFile, baseName .. "#invert", analogActionData.gamepadAxisInvert)
    local categoriesList = Utils.setToList(analogActionData.categories)
    table.sort(categoriesList)
    setXMLString(xmlFile, baseName .. "#category", table.concat(categoriesList, " "))
    i = i + 1
  end
  while true do
    local baseName = string.format("inputBinding.axis(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    setXMLString(xmlFile, baseName .. "#name", "")
    i = i + 1
  end
  saveXMLFile(xmlFile)
  delete(xmlFile)
end
function InputBinding.startInputGatheringOverride(inputCallbackFunction, inputCallbackObject)
  InputBinding.gatherInputCallbackFunction = inputCallbackFunction
  InputBinding.gatherInputCallbackObject = inputCallbackObject
  InputBinding.gatherInputStoredMouseEvent = mouseEvent
  InputBinding.gatherInputStoredKeyEvent = keyEvent
  InputBinding.gatherInputStoredUpdate = update
  InputBinding.storedInput = {}
  for actionIndex, state in pairs(g_inputButtonLast) do
    InputBinding.storedInput[actionIndex] = state
  end
  for keyId, _ in pairs(Input.keyPressedState) do
    Input.keyPressedState[keyId] = false
  end
  for buttonId, _ in pairs(Input.mouseButtonPressedState) do
    Input.mouseButtonPressedState[buttonId] = false
  end
  local gatheredInput = {}
  gatheredInput.keyboard = {}
  gatheredInput.keyboard.keys = {}
  gatheredInput.keyboard.invalidKeys = {}
  gatheredInput.mouse = {}
  gatheredInput.mouse.buttons = {}
  gatheredInput.mouse.axes = {}
  gatheredInput.gamepad = {}
  local function raiseCallback()
    if InputBinding.gatherInputCallbackObject then
      InputBinding.gatherInputCallbackFunction(InputBinding.gatherInputCallbackObject, gatheredInput)
    else
      InputBinding.gatherInputCallbackFunction(gatheredInput)
    end
  end
  function mouseEvent(posX, posY, isDown, isUp, button)
    gatheredInput.mouse.axes[0] = posX
    gatheredInput.mouse.axes[1] = posY
    if button ~= Input.MOUSE_BUTTON_WHEEL_UP and button ~= Input.MOUSE_BUTTON_WHEEL_DOWN then
      gatheredInput.mouse.buttons[button] = isDown or nil
    else
      gatheredInput.mouse.buttons[button] = true
    end
  end
  function keyEvent(unicode, sym, modifier, isDown)
    gatheredInput.keyboard.keys[sym] = isDown or nil
  end
  local gamepadBlockedButtons = {}
  local numGamepads = getNumOfGamepads()
  for d = 1, numGamepads do
    gamepadBlockedButtons[d] = {}
    for i = 1, Input.MAX_NUM_BUTTONS do
      local isDown = getInputButton(i - 1, d - 1) > 0 or d == 1 and 0 < InputBinding.externalInputButtons[i]
      if isDown then
        gamepadBlockedButtons[d][i] = true
      end
    end
  end
  function update(dt)
    local numGamepads = getNumOfGamepads()
    for d = 1, numGamepads do
      local axes = {}
      local buttons = {}
      for i = 1, Input.MAX_NUM_AXES do
        if math.abs(getInputAxis(i - 1, d - 1)) > 0.5 then
          axes[i - 1] = true
        end
      end
      for i = 1, Input.MAX_NUM_BUTTONS do
        local isDown = getInputButton(i - 1, d - 1) > 0 or d == 1 and 0 < InputBinding.externalInputButtons[i]
        if isDown then
          if not gamepadBlockedButtons[d][i] then
            buttons[i - 1] = true
          end
        else
          gamepadBlockedButtons[d][i] = nil
        end
      end
      if next(axes) or next(buttons) then
        if not gatheredInput.gamepad[d - 1] then
          gatheredInput.gamepad[d - 1] = {}
        end
        gatheredInput.gamepad[d - 1].buttons = buttons
        gatheredInput.gamepad[d - 1].axes = axes
      else
        gatheredInput.gamepad[d - 1] = nil
      end
    end
    raiseCallback()
    gatheredInput.mouse.buttons[Input.MOUSE_BUTTON_WHEEL_UP] = nil
    gatheredInput.mouse.buttons[Input.MOUSE_BUTTON_WHEEL_DOWN] = nil
  end
end
function InputBinding.stopInputGatheringOverride(inputCallbackFunction, inputCallbackObject)
  mouseEvent = InputBinding.gatherInputStoredMouseEvent
  keyEvent = InputBinding.gatherInputStoredKeyEvent
  update = InputBinding.gatherInputStoredUpdate
  InputBinding.gatherInputCallbackFunction = nil
  InputBinding.gatherInputCallbackObject = nil
  InputBinding.gatherInputStoredMouseEvent = nil
  InputBinding.gatherInputStoredKeyEvent = nil
  InputBinding.gatherInputStoredUpdate = nil
  for actionIndex, state in pairs(InputBinding.storedInput) do
    g_inputButtonLast[actionIndex] = state
  end
  InputBinding.storedInput = nil
end
function InputBinding.setShowMouseCursor(show)
  InputBinding.mousePosXLast = nil
  InputBinding.mousePosYLast = nil
  setShowMouseCursor(show)
  g_mouse:showMouse(show)
  InputBinding.wrapMousePositionEnabled = not show
end
