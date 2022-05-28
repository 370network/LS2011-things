AdvancedControlsScreen = {}
local AdvancedControlsScreen_mt = Class(AdvancedControlsScreen)
function AdvancedControlsScreen:new()
  local self = GuiElement:new(target, AdvancedControlsScreen_mt)
  self.resolution = getScreenMode()
  self.workingResolution = self.resolution
  self.msaa = getMSAA()
  self.aniso = getFilterAnisotropy()
  self.performanceClass = getGPUPerformanceClass()
  self.timeScale = g_settingsTimeScale
  self.joystickEnabled = g_settingsJoystickEnabled
  self.helpText = g_settingsHelpText
  self.language = g_settingsLanguage
  self.masterVolume = getMasterVolume()
  self.deadzoneValues = {}
  self.deadzoneStrings = {}
  self.deadzoneStep = 0.02
  for i = 0, 0.2, self.deadzoneStep do
    table.insert(self.deadzoneStrings, string.format("%d%%", i * 100))
    table.insert(self.deadzoneValues, i)
  end
  self.mouseSensitivityValues = {}
  self.mouseSensitivityStrings = {}
  self.oneMouseSensitivityState = 1
  self.mouseSensitivityStep = 0.25
  for i = 0.5, 2, self.mouseSensitivityStep do
    table.insert(self.mouseSensitivityStrings, string.format("%d%%", i * 100))
    table.insert(self.mouseSensitivityValues, i)
    if math.abs(i - 1) < 0.001 then
      self.oneMouseSensitivityState = table.getn(self.mouseSensitivityValues)
    end
  end
  return self
end
function AdvancedControlsScreen:onOpen()
  local deadzone = getGamepadDefaultDeadzone()
  local deadzoneState = table.getn(self.deadzoneValues)
  for i = 1, table.getn(self.deadzoneValues) do
    if deadzone <= self.deadzoneValues[i] + self.deadzoneStep * 0.5 then
      deadzoneState = i
      break
    end
  end
  self.deadzoneElement:setState(deadzoneState)
  local scaleX = InputBinding.mouseMotionScaleX / InputBinding.mouseMotionScaleXDefault
  local scaleY = InputBinding.mouseMotionScaleY / InputBinding.mouseMotionScaleYDefault
  local scale = (scaleX + scaleY) * 0.5
  local scaleState = self.oneMouseSensitivityState
  for i = 1, table.getn(self.mouseSensitivityValues) do
    if scale <= self.mouseSensitivityValues[i] + self.mouseSensitivityStep * 0.5 then
      scaleState = i
      break
    end
  end
  self.mouseSensitivityElement:setState(scaleState)
end
function AdvancedControlsScreen:onClickSave()
  local deadzone = self.deadzoneValues[self.deadzoneElement.state]
  setGamepadDefaultDeadzone(deadzone)
  local scale = self.mouseSensitivityValues[self.mouseSensitivityElement.state]
  InputBinding.mouseMotionScaleX = InputBinding.mouseMotionScaleXDefault * scale
  InputBinding.mouseMotionScaleY = InputBinding.mouseMotionScaleYDefault * scale
  InputBinding.saveSettingsToXML()
  g_gui:showGui("ControlsScreen")
end
function AdvancedControlsScreen:onClickBack()
  g_gui:showGui("ControlsScreen")
end
function AdvancedControlsScreen:onCreateDeadzone(element)
  self.deadzoneElement = element
  element:setTexts(self.deadzoneStrings)
end
function AdvancedControlsScreen:onCreateMouseSensitivity(element)
  self.mouseSensitivityElement = element
  element:setTexts(self.mouseSensitivityStrings)
end
function AdvancedControlsScreen:update()
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onClickBack()
  end
end
