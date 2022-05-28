InGameMenu = {}
local InGameMenu_mt = Class(InGameMenu)
function InGameMenu:new()
  local instance = {}
  instance = setmetatable(instance, InGameMenu_mt)
  instance.ignoreOnClose = false
  instance.playerAlreadySaved = false
  instance.doSaveGame = false
  instance.doSaveGamePart2 = false
  instance.continueEnabled = true
  instance.briefingImages = {}
  instance.briefingBg = nil
  return instance
end
function InGameMenu:setText(text)
  if self.textElement ~= nil then
    self.textElement:setText(text)
  end
end
function InGameMenu:onOpen(element)
  if not self.ignoreOnClose then
    self.briefingBg:setVisible(true)
    for i = 1, 3 do
      self.briefingImages[i]:setVisible(true)
    end
    self.continueButton:setDisabled(false)
    self.continueEnabled = true
    self.errorText:setVisible(false)
    if g_currentMission.inGameMessage ~= nil then
      g_currentMission.inGameMessage.visible = false
    end
    g_currentMission:pauseGame()
    InputBinding.setShowMouseCursor(true)
    self.playerAlreadySaved = false
  end
end
function InGameMenu:onClose(element)
  if not self.ignoreOnClose and g_currentMission ~= nil then
    g_currentMission:unpauseGame()
    InputBinding.setShowMouseCursor(false)
  end
end
function InGameMenu:setMissionInfo(missionInfo, missionDynamicInfo)
  self.missionInfo = missionInfo
  self.missionDynamicInfo = missionDynamicInfo
  if missionInfo:isa(FSCareerMissionInfo) then
    for i = 1, 3 do
      self.briefingImages[i]:setImageFilename(self.missionInfo.briefingImagePrefix .. "_briefing" .. i .. ".png")
    end
    self.infoText:setText("")
    self.saveRestartButton:setText(g_i18n:getText("Button_SaveGame"))
  else
    for i = 1, 3 do
      if self.missionInfo.briefingImageBasePath ~= nil then
        self.briefingImages[i]:setImageFilename(self.missionInfo.briefingImageBasePath .. i .. ".png")
      else
        self.briefingImages[i]:setImageFilename("dataS2/menu/briefingScreen/blank.png")
      end
      self:setRecordsText()
    end
    self.saveRestartButton:setText(g_i18n:getText("Button_RestartGame"))
  end
  if missionDynamicInfo.isMultiplayer and missionDynamicInfo.isClient then
    self.saveRestartButton:setDisabled(true)
  else
    self.saveRestartButton:setDisabled(false)
  end
end
function InGameMenu:setRecordsText()
  if self.missionInfo ~= nil and self.missionInfo.missionType == "time" then
    local formattedGoldTime = ""
    local formattedSilverTime = ""
    local formattedBronzeTime = ""
    local timeHoursF = self.missionInfo.goldTime / 60 + 1.0E-4
    local timeHours = math.floor(timeHoursF)
    local timeMinutes = math.floor((timeHoursF - timeHours) * 60 + 1.0E-4)
    formattedGoldTime = string.format("%02d:%02d " .. g_i18n:getText("minutes"), timeHours, timeMinutes)
    timeHoursF = self.missionInfo.silverTime / 60 + 1.0E-4
    timeHours = math.floor(timeHoursF)
    timeMinutes = math.floor((timeHoursF - timeHours) * 60 + 1.0E-4)
    formattedSilverTime = string.format("%02d:%02d " .. g_i18n:getText("minutes"), timeHours, timeMinutes)
    timeHoursF = self.missionInfo.bronzeTime / 60 + 1.0E-4
    timeHours = math.floor(timeHoursF)
    timeMinutes = math.floor((timeHoursF - timeHours) * 60 + 1.0E-4)
    formattedBronzeTime = string.format("%02d:%02d " .. g_i18n:getText("minutes"), timeHours, timeMinutes)
    self.infoText:setText(g_i18n:getText("Gold") .. ": " .. formattedGoldTime .. "      " .. g_i18n:getText("Silver") .. ": " .. formattedSilverTime .. "      " .. g_i18n:getText("Bronze") .. ": " .. formattedBronzeTime)
  end
  if self.missionInfo.missionType == "stacking" then
    self.infoText:setText("Gold: " .. self.missionInfo.goldTime .. " " .. g_i18n:getText("pallets") .. "      Silber: " .. self.missionInfo.silverTime .. " " .. g_i18n:getText("pallets") .. "      Bronze: " .. self.missionInfo.bronzeTime .. " " .. g_i18n:getText("pallets"))
  end
  if self.missionInfo.missionType == "strawElevatoring" then
    self.infoText:setText("Gold: " .. self.missionInfo.goldTime .. " " .. g_i18n:getText("bales") .. "      Silber: " .. self.missionInfo.silverTime .. " " .. g_i18n:getText("bales") .. "      Bronze: " .. self.missionInfo.bronzeTime .. " " .. g_i18n:getText("bales"))
  end
end
function InGameMenu:setMasterServerConnectionFailed()
  self.continueEnabled = false
  self.continueButton:setDisabled(true)
  self.errorText:setVisible(true)
  self.errorText:setText(g_i18n:getText("MasterServerConnectionLost"))
  self.briefingBg:setVisible(false)
  for i = 1, 3 do
    self.briefingImages[i]:setVisible(false)
  end
end
function InGameMenu:onBriefingBackgroundCreate(element)
  self.briefingBg = element
end
function InGameMenu:onImage1Create(element)
  self.briefingImages[1] = element
end
function InGameMenu:onImage2Create(element)
  self.briefingImages[2] = element
end
function InGameMenu:onImage3Create(element)
  self.briefingImages[3] = element
end
function InGameMenu:onCreateCareerBriefing(element)
  self.briefingCareer = element
  self.briefingCareer:setVisible(false)
end
function InGameMenu:onCreateMissionBriefing(element)
  self.briefingMission = element
  self.briefingMission:setVisible(false)
end
function InGameMenu:onCreateSaveRestartButton(element)
  self.saveRestartButton = element
end
function InGameMenu:onCreateContinueButton(element)
  self.continueButton = element
end
function InGameMenu:onCreateInfoText(element)
  self.infoText = element
  self.infoText:setText("")
end
function InGameMenu:onCreateErrorText(element)
  self.errorText = element
  self.errorText:setVisible(false)
end
function InGameMenu:onCreateSavingText(element)
  self.savingText = element
  self.savingText:setVisible(false)
end
function InGameMenu:onSaveClick()
  if self.missionInfo:isa(FSCareerMissionInfo) then
    self.playerAlreadySaved = true
    self.doSaveGame = true
    self.savingText:setVisible(true)
  else
    g_currentMission:delete()
    g_careerScreen:onStartMission(self.missionInfo, self.missionDynamicInfo)
  end
end
function InGameMenu:update(dt)
  if self.doSaveGame then
    self.doSaveGamePart2 = true
  end
  if self.doSaveGame then
    self.doSaveGame = false
    self.doSaveGamePart2 = true
  elseif self.doSaveGamePart2 then
    g_careerScreen:saveSelectedGame()
    self.doSaveGamePart2 = false
    self.savingText:setVisible(false)
  end
  if InputBinding.hasEvent(InputBinding.MENU, true) or InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    InputBinding.hasEvent(InputBinding.MENU_CANCEL, true)
    InputBinding.hasEvent(InputBinding.MENU, true)
    self:onContinueClick()
  end
end
function InGameMenu:onCancelClick()
  local isCareer = self.missionInfo:isa(FSCareerMissionInfo)
  local isMultiplayerClient = self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient
  if (not self.playerAlreadySaved or not isCareer) and not isMultiplayerClient then
    self.ignoreOnClose = true
    local yesNoDialog = g_gui:showGui("YesNoDialog")
    self.ignoreOnClose = false
    if self.missionInfo:isa(FSCareerMissionInfo) then
      yesNoDialog.target:setText(g_i18n:getText("DontForgetToSave"))
    else
      yesNoDialog.target:setText(g_i18n:getText("MissionWantToEnd"))
    end
    yesNoDialog.target:setCallbacks(self.onYesNoEnd, self)
  else
    OnInGameMenuMenu()
  end
end
function InGameMenu:onYesNoEnd(yes)
  if yes then
    if self.missionDynamicInfo.isMultiplayer and g_server ~= nil then
      g_server:broadcastEvent(ShutdownEvent:new())
    end
    OnInGameMenuMenu()
  else
    self.ignoreOnClose = true
    g_gui:showGui("InGameMenu")
    self.ignoreOnClose = false
  end
end
function InGameMenu:onContinueClick()
  if self.continueEnabled then
    g_gui:showGui("")
  end
end
function InGameMenu:draw()
  if self.missionInfo ~= nil and self.continueEnabled then
    setTextWrapWidth(0.575)
    for i = 1, 3 do
      renderText(0.35714, 0.92 - (i - 1) * 0.26667, 0.025, self.missionInfo.briefingText[i])
    end
    setTextWrapWidth(0)
  end
end
