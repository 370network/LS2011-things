SettingsScreen = {}
local SettingsScreen_mt = Class(SettingsScreen)
function SettingsScreen:new()
  local self = GuiElement:new(target, SettingsScreen_mt)
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
  return self
end
function SettingsScreen:onOpenSettingsScreen()
  self.nickNameElement:setText(g_settingsNickname)
  self.resolution = getScreenMode()
  local numR = getNumOfScreenModes()
  self.resultionElement:setState(numR - self.resolution)
  self.language = g_settingsLanguage
  self.languageElement:setState(self.language + 1)
  self.msaa = getMSAA()
  self.msaaElement:setState(Utils.getMSAAIndex(self.msaa))
  self.aniso = getFilterAnisotropy()
  self.anisoElement:setState(Utils.getAnsioIndex(self.aniso))
  self.joystickEnabled = g_settingsJoystickEnabled
  self.joystickEnabledElement:setIsChecked(self.joystickEnabled)
  self.performanceClass = getGPUPerformanceClass()
  self.performanceClassElement:setState(Utils.getProfileClassIndex(self.performanceClass))
  self.timeScale = g_settingsTimeScale
  self.timeScaleElement:setState(Utils.getTimeScaleIndex(self.timeScale))
  self.helpText = g_settingsHelpText
  self.helpTextElement:setIsChecked(self.helpText)
end
function SettingsScreen:onClickSave()
  setGamepadEnabled(self.joystickEnabled)
  setScreenMode(self.resolution)
  setMSAA(self.msaa)
  setFilterAnisotropy(self.aniso)
  setGPUPerformanceClass(self.performanceClass)
  setXMLBool(g_savegameXML, "savegames.settings.autohelp", self.helpText)
  if not searchText(self.nickNameElement.text) then
    setXMLString(g_savegameXML, "savegames.settings.nickname", self.nickNameElement.text)
  end
  setXMLFloat(g_savegameXML, "savegames.settings#timescale", self.timeScale)
  setXMLInt(g_savegameXML, "savegames.settings#language", self.language)
  setMasterVolume(self.masterVolume)
  saveXMLFile(g_savegameXML)
  if self.workingResolution ~= self.resolution then
    RestartManager:setResolutionChange(getScreenModeInfo(self.workingResolution))
  end
  restartApplication()
end
function SettingsScreen:onCreateNickName(element)
  self.nickNameElement = element
  element:setText(g_settingsNickname)
end
function SettingsScreen:infoTextOnCreate(element)
  self.infoText = element
  element:setText("")
end
function SettingsScreen:onClickBack()
  g_gui:showGui("MainScreen")
end
function SettingsScreen:onClickControls()
  g_gui:showGui("ControlsScreen")
end
function SettingsScreen:onClickMods()
  g_gui:showGui("ModManagementScreen")
end
function SettingsScreen:resolutionOnCreate(element)
  self.resultionElement = element
  local resTable = {}
  local numR = getNumOfScreenModes()
  for i = 0, numR - 1 do
    local x, y = getScreenModeInfo(numR - i - 1)
    local aspect = x / y
    local aspectStr = ""
    if aspect == 1.25 then
      aspectStr = "(5:4)"
    elseif 1.3 < aspect and aspect < 1.4 then
      aspectStr = "(4:3)"
    elseif 1.7 < aspect and aspect < 1.8 then
      aspectStr = "(16:9)"
    else
      aspectStr = string.format("(%1.1f:1)", aspect)
    end
    table.insert(resTable, string.format("%dx%d %s", x, y, aspectStr))
  end
  element:setTexts(resTable)
  element:setState(numR - self.resolution)
end
function SettingsScreen:resolutionOnClick(state)
  local numR = getNumOfScreenModes()
  self.resolution = numR - state
end
function SettingsScreen:languageOnCreate(element)
  self.languageElement = element
  local languageTable = {}
  local numL = getNumOfLanguages()
  for i = 0, numL - 1 do
    table.insert(languageTable, getLanguageName(i))
  end
  element:setTexts(languageTable)
  element:setState(self.language + 1)
end
function SettingsScreen:languageOnClick(state)
  self.language = state - 1
  self.language = Utils.clamp(self.language, 0, getNumOfLanguages() - 1)
end
function SettingsScreen:msaaOnCreate(element)
  self.msaaElement = element
  local msaaTable = {}
  table.insert(msaaTable, g_i18n:getText("Off"))
  table.insert(msaaTable, "2")
  table.insert(msaaTable, "4")
  table.insert(msaaTable, "8")
  element:setTexts(msaaTable)
  element:setState(Utils.getMSAAIndex(self.msaa))
end
function SettingsScreen:msaaOnClick(state)
  self.msaa = 0
  if state == 2 then
    self.msaa = 2
  end
  if state == 3 then
    self.msaa = 4
  end
  if state == 4 then
    self.msaa = 8
  end
end
function SettingsScreen:anisoOnCreate(element)
  self.anisoElement = element
  local anisoTable = {}
  table.insert(anisoTable, g_i18n:getText("Off"))
  table.insert(anisoTable, "2")
  table.insert(anisoTable, "4")
  table.insert(anisoTable, "8")
  element:setTexts(anisoTable)
  element:setState(Utils.getAnsioIndex(self.aniso))
end
function SettingsScreen:anisoOnClick(state)
  self.aniso = 0
  if state == 2 then
    self.aniso = 2
  end
  if state == 3 then
    self.aniso = 4
  end
  if state == 4 then
    self.aniso = 8
  end
end
function SettingsScreen:toggleGamepadOnCreate(element)
  self.joystickEnabledElement = element
  element:setIsChecked(self.joystickEnabled)
end
function SettingsScreen:toggleGamepadOnClick(state)
  self.joystickEnabled = state
end
function SettingsScreen:profileOnCreate(element)
  self.performanceClassElement = element
  local profileTable = {}
  table.insert(profileTable, string.format("Auto (%s)", getAutoGPUPerformanceClass()))
  table.insert(profileTable, "Low")
  table.insert(profileTable, "Medium")
  table.insert(profileTable, "High")
  table.insert(profileTable, "Very High")
  element:setTexts(profileTable)
  element:setState(Utils.getProfileClassIndex(self.performanceClass))
end
function SettingsScreen:profileOnClick(state)
  self.performanceClass = "auto"
  if state == 2 then
    self.performanceClass = "low"
  end
  if state == 3 then
    self.performanceClass = "medium"
  end
  if state == 4 then
    self.performanceClass = "high"
  end
  if state == 5 then
    self.performanceClass = "very high"
  end
end
function SettingsScreen:timeScaleOnCreate(element)
  self.timeScaleElement = element
  local timeScaleTable = {}
  table.insert(timeScaleTable, g_i18n:getText("RealTime"))
  table.insert(timeScaleTable, "4x")
  table.insert(timeScaleTable, "16x")
  table.insert(timeScaleTable, "32x")
  table.insert(timeScaleTable, "60x")
  element:setTexts(timeScaleTable)
  element:setState(Utils.getTimeScaleIndex(self.timeScale))
end
function SettingsScreen:timeScaleOnClick(state)
  self.timeScale = 1
  if state == 2 then
    self.timeScale = 4
  end
  if state == 3 then
    self.timeScale = 16
  end
  if state == 4 then
    self.timeScale = 32
  end
  if state == 5 then
    self.timeScale = 60
  end
end
function SettingsScreen:masterVolumeOnCreate(element)
  self.masterVolumeElement = element
  local masterVolumeTable = {}
  table.insert(masterVolumeTable, g_i18n:getText("Off"))
  table.insert(masterVolumeTable, "20%")
  table.insert(masterVolumeTable, "40%")
  table.insert(masterVolumeTable, "60%")
  table.insert(masterVolumeTable, "80%")
  table.insert(masterVolumeTable, "100%")
  element:setTexts(masterVolumeTable)
  element:setState(Utils.getMasterVolumeIndex(self.masterVolume))
end
function SettingsScreen:masterVolumeOnClick(state)
  self.masterVolume = Utils.getMasterVolumeFromIndex(state)
end
function SettingsScreen:toggleAutoHelpOnCreate(element)
  self.helpTextElement = element
  element:setIsChecked(self.helpText)
end
function SettingsScreen:toggleAutoHelpOnClick(state)
  self.helpText = state
end
function SettingsScreen:onCreateSave(element)
  self.saveButtonElement = element
end
function SettingsScreen:update()
  if searchText(self.nickNameElement.text) then
    self.saveButtonElement:setDisabled(true)
    self.infoText:setText(g_i18n:getText("IllegalNick"))
  else
    self.saveButtonElement:setDisabled(false)
    self.infoText:setText("")
  end
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onClickBack()
  end
end
