MouseHelper = {}
KeyboardHelper = {}
GamepadHelper = {
  nameToIdentifierMapping = {},
  profiles = {}
}
function MouseHelper.getButtonName(mouseButtonId)
  for _, specialKey in pairs(Input.SpecialKeys) do
    if mouseButtonId == specialKey.mouseButton then
      return specialKey.name
    end
  end
  print("error: mouse button not found")
end
function MouseHelper.getButtonXMLString(mouseButtonId)
  if mouseButtonId == nil or mouseButtonId == -1 then
    return ""
  end
  for _, specialKey in pairs(Input.SpecialKeys) do
    if mouseButtonId == specialKey.mouseButton then
      return specialKey.input
    end
  end
  print("error: mouse button not found")
end
function KeyboardHelper.getKeyNames(keyList)
  local keyText = ""
  for i, keyId in ipairs(keyList) do
    local keyString
    for _, specialKey in pairs(Input.SpecialKeys) do
      if keyId == specialKey.sym then
        keyString = specialKey.name
        break
      end
    end
    keyString = keyString or getKeyName(keyId)
    keyText = keyText .. (i == 1 and "" or " ") .. keyString
  end
  return keyText
end
function KeyboardHelper.getKeysXMLString(keyList)
  if keyList == nil or keyList == -1 then
    return ""
  end
  local keyText = ""
  for i, keyId in ipairs(keyList) do
    local keyString
    for _, specialKey in pairs(Input.SpecialKeys) do
      if keyId == specialKey.sym then
        keyString = specialKey.input
        break
      end
    end
    keyString = keyString or "KEY_" .. string.char(keyId)
    keyText = keyText .. (i == 1 and "" or " ") .. keyString
  end
  return keyText
end
function GamepadHelper.getGamepadInputCombinedName(gamepadsHash)
  local gamepadList = {}
  local gamepadListData = {}
  for gamepadId, gamepadData in pairs(gamepadsHash) do
    print("gamepadId : " .. gamepadId)
    table.insert(gamepadList, gamepadId)
    gamepadListData[gamepadId] = {}
    gamepadListData[gamepadId].buttonsList = {}
    gamepadListData[gamepadId].axesList = {}
    for gamepadButtonId, _ in pairs(gamepadData.buttons) do
      table.insert(gamepadListData[gamepadId].buttonsList, gamepadButtonId)
    end
    for gamepadAxisId, _ in pairs(gamepadData.axes) do
      table.insert(gamepadListData[gamepadId].axesList, gamepadAxisId)
    end
    table.sort(gamepadListData[gamepadId].buttonsList)
    table.sort(gamepadListData[gamepadId].axesList)
  end
  table.sort(gamepadList)
  local finalString = ""
  local buttonsString = ""
  local axesString = ""
  for i, gamepadId in ipairs(gamepadList) do
    print(tostring(gamepadId))
    print(tostring(gamepadListData[gamepadId]))
    for j, gamepadButtonId in ipairs(gamepadListData[gamepadId].buttonsList) do
      buttonsString = buttonsString .. (j ~= 1 and ", " or "") .. GamepadHelper.getButtonName(gamepadButtonId, gamepadId)
    end
    for j, gamepadAxisId in ipairs(gamepadListData[gamepadId].axesList) do
      axesString = axesString .. (j ~= 1 and ", " or "") .. GamepadHelper.getAxisName(gamepadAxisId, gamepadId)
    end
  end
  finalString = (buttonsString ~= "" and g_i18n:getText("Button") .. " " .. buttonsString .. " " or "") .. (axesString ~= "" and g_i18n:getText("Axis") .. " " .. axesString or "")
  return finalString
end
function GamepadHelper.getButtonName(buttonId, deviceId)
  if buttonId == nil then
    return ""
  end
  if deviceId == nil then
    deviceId = 0
  end
  return getGamepadButtonLabel(buttonId, deviceId)
end
function GamepadHelper.getAxisName(axisId, deviceId)
  if axisId == nil then
    return ""
  end
  return getGamepadAxisLabel(axisId, deviceId)
end
function GamepadHelper.getButtonNames(buttonIdList, deviceId)
  if buttonIdList == nil then
    return ""
  end
  local buttonString = ""
  local listCount = #buttonIdList
  for i, buttonId in ipairs(buttonIdList) do
    buttonString = buttonString .. (i == 1 and "" or " ") .. GamepadHelper.getButtonName(buttonId, i ~= listCount and deviceId or 0)
  end
  local buttonNamePrefix = ""
  if listCount == 1 then
    buttonNamePrefix = g_i18n:getText("Button") .. " "
  elseif 1 < listCount then
    buttonNamePrefix = g_i18n:getText("Buttons") .. " "
  end
  return buttonNamePrefix .. buttonString
end
function GamepadHelper.getButtonAndAxisNames(buttonIdList, axisId, deviceId)
  local buttonString = GamepadHelper.getButtonNames(buttonIdList)
  local axisString = GamepadHelper.getAxisName(axisId)
  local deviceString = GamepadHelper.getDeviceString(deviceId)
  return buttonString .. (buttonString ~= "" and axisString ~= "" and ", " or "") .. (axisString ~= "" and axisString or "") .. ((buttonString ~= "" or axisString ~= "") and " " .. deviceString or "")
end
function GamepadHelper.getDeviceString(deviceId)
  return "[" .. deviceId + 1 .. "]"
end
function GamepadHelper.getButtonsXMLString(buttonIdList)
  if buttonIdList == nil then
    return ""
  end
  local buttonString = ""
  for i, buttonId in ipairs(buttonIdList) do
    buttonString = buttonString .. (i == 1 and "" or " ") .. "BUTTON" .. "_" .. buttonId + 1
  end
  return buttonString
end
function GamepadHelper.getAxisXMLString(gamepadAxisId)
  if gamepadAxisId == nil or gamepadAxisId == -1 then
    return ""
  end
  return "AXIS_" .. gamepadAxisId + 1
end
function GamepadHelper.getDeviceXMLInt(gamepadId)
  if gamepadId == nil or gamepadId == -1 then
    return 0
  end
  return gamepadId
end
