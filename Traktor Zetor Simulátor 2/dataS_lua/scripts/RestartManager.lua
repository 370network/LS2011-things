RestartManager = {}
RestartManager.START_SCREEN_MAIN = 1
RestartManager.START_SCREEN_JOIN_GAME = 2
RestartManager.START_SCREEN_MULTIPLAYER = 3
function RestartManager:init(args)
  self.xmlBaseNode = "settingsRestoreData"
  RestartManager:loadXML()
  self.restartOnResolutionChange = true
  self.lastRestartString = args
  self.restartString = ""
  self.restarting = string.find(args, "-restart") ~= nil
end
function RestartManager:loadXML()
  local xmlTemplate = getAppBasePath() .. "profileTemplate/settingsRestoreDataTemplate.xml"
  local xmlPath = getUserProfileAppPath() .. "settingsRestoreData.xml"
  copyFile(xmlTemplate, xmlPath, false)
  self.xmlFile = loadXMLFile("settingsRestoreDataXML", xmlPath)
end
function RestartManager:handleRestart()
  if RestartManager:checkForResolutionChange() then
  end
  self:checkForStartScreen()
end
function RestartManager:checkForResolutionChange()
  local resolutionChanged = getXMLBool(self.xmlFile, self.xmlBaseNode .. ".resolutionChanged")
  if resolutionChanged then
    self.workingResolutionWidth = getXMLInt(self.xmlFile, self.xmlBaseNode .. ".workingResolutionWidth")
    self.workingResolutionHeight = getXMLInt(self.xmlFile, self.xmlBaseNode .. ".workingResolutionHeight")
    self.restartDisplayTime = 15000
    self.yesNoDialog = g_gui:showGui("YesNoDialog")
    self.yesNoDialog.target:setText(g_i18n:getText("DisplayOK") .. "\n" .. tostring(self.restartDisplayTime / 1000))
    self.yesNoDialog.target:setCallbacks(self.restartDisplayOk, self)
    self.restartDisplayTimerId = addTimer(1000, "restartDisplayTimeUpdate", self)
    return true
  end
end
function RestartManager:setResolutionChange(workingResolutionWidth, workingResolutionHeight)
  self.resolutionChanged = true
  setXMLInt(self.xmlFile, self.xmlBaseNode .. ".workingResolutionWidth", workingResolutionWidth)
  setXMLInt(self.xmlFile, self.xmlBaseNode .. ".workingResolutionHeight", workingResolutionHeight)
  setXMLBool(self.xmlFile, self.xmlBaseNode .. ".resolutionChanged", true)
  saveXMLFile(self.xmlFile)
end
function RestartManager:checkForStartScreen()
  local startScreenValid = Utils.getNoNil(getXMLBool(self.xmlFile, self.xmlBaseNode .. ".startScreenValid"), false)
  if startScreenValid then
    local startScreen = getXMLInt(self.xmlFile, self.xmlBaseNode .. ".startScreen")
    if startScreen ~= nil then
    end
    if startScreen == RestartManager.START_SCREEN_MAIN then
    elseif startScreen == RestartManager.START_SCREEN_JOIN_GAME then
      g_multiplayerScreen:onJoinGameClick()
    elseif startScreen == RestartManager.START_SCREEN_MULTIPLAYER then
      g_gui:showGui("MultiplayerScreen")
    end
  end
  setXMLBool(self.xmlFile, self.xmlBaseNode .. ".startScreenValid", false)
  setXMLInt(self.xmlFile, self.xmlBaseNode .. ".startScreen", 0)
  saveXMLFile(self.xmlFile)
end
function RestartManager:setStartScreen(screen)
  self.startScreen = screen
  setXMLInt(self.xmlFile, self.xmlBaseNode .. ".startScreen", screen)
  setXMLBool(self.xmlFile, self.xmlBaseNode .. ".startScreenValid", true)
  saveXMLFile(self.xmlFile)
end
function RestartManager:restartDisplayTimeUpdate()
  self.restartDisplayTime = self.restartDisplayTime - 1000
  if self.restartDisplayTime > 0 then
    self.yesNoDialog.target:setText(g_i18n:getText("DisplayOK") .. "\n" .. tostring(self.restartDisplayTime / 1000))
    setTimerTime(self.restartDisplayTimerId, 1000)
    return true
  else
    self.restartDisplayTime = nil
    self.yesNoDialog = nil
    self.restartDisplayTimerId = nil
    self:restartDisplayNotOk()
    return false
  end
end
function RestartManager:restartDisplayOk(yes)
  removeTimer(self.restartDisplayTimerId)
  self.restartDisplayTime = nil
  self.yesNoDialog = nil
  self.restartDisplayTimerId = nil
  if yes then
    self:cleanRestartData()
    g_gui:showGui("MainScreen")
  else
    self:restartDisplayNotOk()
  end
end
function RestartManager:restartDisplayNotOk()
  local workingResolution
  local numR = getNumOfScreenModes()
  for i = 0, numR - 1 do
    local x, y = getScreenModeInfo(i)
    if x == self.workingResolutionWidth and y == self.workingResolutionHeight then
      workingResolution = i
      break
    end
  end
  workingResolution = workingResolution or numR - 1
  setScreenMode(workingResolution)
  self:cleanRestartData()
  restartApplication()
end
function RestartManager:restartIfNeeded()
  local restartNeeded = true
  if restartNeeded then
    restartApplication()
  end
end
function RestartManager:cleanRestartData()
  setXMLBool(self.xmlFile, self.xmlBaseNode .. ".resolutionChanged", false)
  saveXMLFile(self.xmlFile)
end
