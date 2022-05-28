MPLoadingScreen = {}
local MPLoadingScreen_mt = Class(MPLoadingScreen)
function MPLoadingScreen:new(loadFunction)
  local instance = {}
  setmetatable(instance, MPLoadingScreen_mt)
  instance.count = -1
  instance.doLoad = false
  instance.doPreSimulate = false
  instance.loadFunction = loadFunction
  instance.isLoaded = false
  instance.key = 1234
  instance.briefingImages = {}
  instance.briefingBg = nil
  instance.showBriefing = true
  instance.isClient = false
  instance.isPortTesting = false
  return instance
end
function MPLoadingScreen:update(dt)
  if self.count >= 0 then
    self.count = self.count + 1
    if self.count >= 2 then
      self.count = -1
      if self.doLoad then
        self.doLoad = false
        g_currentMission:onConnectionRequestAcceptedLoad(self.loadConnection)
        self.isLoaded = true
      elseif self.doPreSimulate then
        self.doPreSimulate = false
        simulatePhysics(false)
        self:onReadyToStart()
      end
    end
  end
end
function MPLoadingScreen:onOpen()
  self:setBriefingPicsAndText()
end
function MPLoadingScreen:onStartClick()
  g_currentMission:loadFinished()
  if g_currentMission:getIsServer() then
    g_currentMission:unpauseGame()
  end
  InputBinding.setShowMouseCursor(false)
  g_gui:showGui("")
end
function MPLoadingScreen:onCreateCancelButton(element)
  self.cancelButton = element
  self.cancelButton:setVisible(false)
end
function MPLoadingScreen:onCreateCareerBriefing(element)
end
function MPLoadingScreen:onCreateMissionBriefing(element)
end
function MPLoadingScreen:onBriefingBackgroundCreate(element)
  self.briefingBg = element
end
function MPLoadingScreen:onImage1Create(element)
  self.briefingImages[1] = element
end
function MPLoadingScreen:onImage2Create(element)
  self.briefingImages[2] = element
end
function MPLoadingScreen:onImage3Create(element)
  self.briefingImages[3] = element
end
function MPLoadingScreen:onCreateLoadingBg(element)
  self.loadingBg = element
end
function MPLoadingScreen:onCreateLoadingButton(element)
  self.loadingButton = element
end
function MPLoadingScreen:onCreateStatus(element)
  self.statusText = element
end
function MPLoadingScreen:onCreateInfoText(element)
  self.infoText = element
  self.infoText:setText("")
end
function MPLoadingScreen:startClient()
  self.isClient = true
  self.isPortTesting = false
  self.cancelButton:setVisible(true)
  self.statusText:setText(g_i18n:getText("Game_is_connecting_please_wait"))
  g_masterServerConnection:setCallbackTarget(self)
  masterServerRequestServerDetails(self.missionDynamicInfo.serverId)
end
function MPLoadingScreen:startLocal()
  self.isClient = false
  self.isPortTesting = false
  self.cancelButton:setVisible(false)
  self.statusText:setText("")
  self.missionDynamicInfo.mods = ModsUtil.modList
  self:initializeLoading()
end
function MPLoadingScreen:showPortTesting()
  self:setBriefingPicsAndText()
  self.statusText:setText(g_i18n:getText("Testing_port"))
  g_gui:showGui("MPLoadingScreen")
  self.isPortTesting = true
  self.cancelButton:setVisible(true)
end
function MPLoadingScreen:startServer()
  self.isClient = false
  self.isPortTesting = false
  self.cancelButton:setVisible(false)
  self.serverName = self.missionDynamicInfo.serverName
  self.serverPassword = self.missionDynamicInfo.password
  self.capacity = self.missionDynamicInfo.capacity
  self.mods = self.missionDynamicInfo.mods
  g_server = Server:new()
  g_client = Client:new()
  g_server:start(self.missionDynamicInfo.serverPort)
  g_connectToMasterServerScreen:setNextScreenName("MPLoadingScreen")
  g_connectToMasterServerScreen:setPrevScreenName("CreateGameScreen")
  g_selectMasterServerScreen:setPrevScreenName("CreateGameScreen")
  g_gui:showGui("ConnectToMasterServerScreen")
  g_connectToMasterServerScreen:connectToFront()
end
function MPLoadingScreen:loadWithConnection(connection)
  self.cancelButton:setVisible(false)
  self.statusText:setText(g_i18n:getText("Game_is_loading_please_wait"))
  self.count = 0
  self.doLoad = true
  self.loadConnection = connection
end
function MPLoadingScreen:onWaitingForAccept()
  self.statusText:setText(g_i18n:getText("Waiting_for_accept"))
end
function MPLoadingScreen:onCancelClick()
  if self.isPortTesting then
    masterServerCancelPortTest()
    netShutdown(0, 0)
    g_gui:showGui("CreateGameScreen")
  elseif self.isClient then
    if g_currentMission ~= nil then
      OnInGameMenuMenu()
    else
      g_masterServerConnection:disconnectFromMasterServer()
      g_connectionManager:shutdownAll()
      g_multiplayerScreen:onJoinGameClick()
    end
  end
end
function MPLoadingScreen:onWaitingForDynamicData()
  self.statusText:setText(g_i18n:getText("Waiting_for_data"))
end
function MPLoadingScreen:onCreatingGame()
  self.statusText:setText(g_i18n:getText("Creating_game"))
end
function MPLoadingScreen:setDynamicDataPercentage(progress)
  self.statusText:setText(g_i18n:getText("Waiting_for_data") .. " " .. math.floor(progress * 100) .. "%")
end
function MPLoadingScreen:onFinishedReceivingDynamicData()
  if g_currentMission:getIsServer() then
    if g_currentMission.preSimulateTime > 0 then
      simulatePhysics(true)
      extraUpdatePhysics(g_currentMission.preSimulateTime)
      self.count = 0
      self.doPreSimulate = true
    else
      self:onReadyToStart()
    end
  else
    self:onReadyToStart()
  end
end
function MPLoadingScreen:onReadyToStart()
  self.loadingBg:setVisible(false)
  self.statusText:setVisible(false)
  self.loadingButton:setVisible(true)
end
function MPLoadingScreen:initializeLoading()
  self:setBriefingPicsAndText()
  if self.missionInfo:isa(FSCareerMissionInfo) then
    InitClientOnce()
    if table.getn(self.missionDynamicInfo.mods) > 0 then
      masterServerConnectFront = nil
      masterServerConnectBack = nil
      netConnect = nil
      if not g_isDemo then
        for i = 1, table.getn(self.missionDynamicInfo.mods) do
          local modItem = self.missionDynamicInfo.mods[i]
          loadMod(modItem.modName, modItem.modDir, modItem.modFile)
        end
      end
    end
  end
  SpecializationUtil.initSpecializations()
  self.loadFunction(self.missionInfo, self.missionDynamicInfo, self)
end
function MPLoadingScreen:setBriefingPicsAndText()
  self.showBriefing = true
  if self.missionInfo ~= nil then
    if self.missionInfo:isa(FSCareerMissionInfo) then
      for i = 1, 3 do
        if self.missionInfo.briefingImagePrefix ~= nil then
          self.briefingImages[i]:setImageFilename(self.missionInfo.briefingImagePrefix .. "_briefing" .. i .. ".png")
        else
          self.showBriefing = false
        end
      end
      self.infoText:setText("")
    else
      for i = 1, 3 do
        if self.missionInfo.briefingImageBasePath ~= nil then
          self.briefingImages[i]:setImageFilename(self.missionInfo.briefingImageBasePath .. i .. ".png")
        else
          self.showBriefing = false
        end
      end
      self:setRecordsText()
    end
    if self.showBriefing then
      for i = 1, 3 do
        self.briefingImages[i]:setVisible(true)
      end
      self.briefingBg:setVisible(true)
    else
      for i = 1, 3 do
        self.briefingImages[i]:setVisible(false)
      end
      self.briefingBg:setVisible(false)
    end
  end
end
function MPLoadingScreen:setRecordsText()
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
function MPLoadingScreen:onServerInfoDetails(id, ip, port, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashs)
  if id == self.missionDynamicInfo.serverId then
    if not self.missionInfo:setMapId(mapId) then
      g_connectionFailedDialog:setNextScreenName("JoinGameScreen")
      g_connectionFailedDialog:setFailedText(g_i18n:getText("Game_Connection_failed"))
      g_gui:showGui("ConnectionFailedDialog")
      return
    end
    for i = 1, table.getn(modHashs) do
      local modItem = ModsUtil.findModItemByFileHash(modHashs[i])
      if modItem == nil then
        g_connectionFailedDialog:setNextScreenName("JoinGameScreen")
        g_connectionFailedDialog:setFailedText(g_i18n:getText("Game_Connection_failed"))
        g_gui:showGui("ConnectionFailedDialog")
        return
      end
    end
    self.missionDynamicInfo.mods = {}
    for i = 1, table.getn(modHashs) do
      local modItem = ModsUtil.findModItemByFileHash(modHashs[i])
      table.insert(self.missionDynamicInfo.mods, modItem)
    end
    masterServerRequestConnectionToServer(id, "onNatPunchSuceeded", "onNatPunchFailed", self)
  end
end
function MPLoadingScreen:onServerInfoDetailsFailed()
  g_connectionFailedDialog:setNextScreenName("JoinGameScreen")
  g_connectionFailedDialog:setFailedText(g_i18n:getText("Game_Connection_failed"))
  g_gui:showGui("ConnectionFailedDialog")
end
function MPLoadingScreen:onNatPunchSuceeded(ip, port)
  self.missionDynamicInfo.serverAddress = ip
  self.missionDynamicInfo.serverPort = port
  self:initializeLoading()
end
function MPLoadingScreen:onNatPunchFailed()
  g_connectionFailedDialog:setNextScreenName("JoinGameScreen")
  g_connectionFailedDialog:setFailedText(g_i18n:getText("Game_Connection_failed"))
  g_gui:showGui("ConnectionFailedDialog")
end
function MPLoadingScreen:onMasterServerConnectionReady()
  g_masterServerConnection:setCallbackTarget(self)
  self:onCreatingGame()
  local hasPassword = self.missionDynamicInfo.password ~= ""
  masterServerAddServerModStart()
  for i = 1, table.getn(self.missionDynamicInfo.mods) do
    local modItem = self.missionDynamicInfo.mods[i]
    assert(modItem.fileHash ~= nil)
    local modTitleStr = ModScreen.packModInfo(modItem.title, modItem.version, modItem.author)
    masterServerAddServerMod(modTitleStr, modItem.fileHash)
  end
  masterServerAddServerModEnd()
  local map = MapsUtil.getMapById(self.missionInfo.mapId)
  masterServerAddServer(self.missionDynamicInfo.serverPort, self.missionDynamicInfo.serverName, hasPassword, self.missionDynamicInfo.capacity, 0, map.title, self.missionInfo.mapId)
  self:initializeLoading()
end
function MPLoadingScreen:onMasterServerConnectionFailed(reason)
  assert(g_currentMission == nil)
  g_masterServerConnection:disconnectFromMasterServer()
  if g_client ~= nil then
    g_client:delete()
    g_client = nil
  end
  if g_server ~= nil then
    g_server:delete()
    g_server = nil
  else
    g_connectionManager:shutdownAll()
  end
  local nextScreen = "CreateGameScreen"
  if self.isClient then
    nextScreen = "MultiplayerScreen"
  end
  g_connectionFailedDialog:showMasterServerConnectionFailedReason(reason, nextScreen)
end
function MPLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
  self.missionInfo = missionInfo
  self.missionDynamicInfo = missionDynamicInfo
  self.doPreSimulate = false
  self.doLoad = false
  self.isLoaded = false
  self.loadingBg:setVisible(true)
  self.statusText:setVisible(true)
  self.loadingButton:setVisible(false)
end
function MPLoadingScreen:draw()
  if self.missionInfo ~= nil and self.missionInfo.briefingText[1] ~= nil and self.showBriefing then
    setTextWrapWidth(0.575)
    for i = 1, 3 do
      renderText(0.35714, 0.92 - (i - 1) * 0.26667, 0.025, self.missionInfo.briefingText[i])
    end
    setTextWrapWidth(0)
  end
end
