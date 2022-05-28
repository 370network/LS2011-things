CreateGameScreen = {}
local CreateGameScreen_mt = Class(CreateGameScreen)
function CreateGameScreen:new()
  local instance = GuiElement:new(target, CreateGameScreen_mt)
  instance.capacityTable = {"2"}
  instance.capacityNumberTable = {2}
  instance.capacityInitialized = false
  instance.mods = {}
  instance.lastCheckedPort = nil
  instance.isPortTesting = false
  instance.mappedPort = 0
  instance.connectionsTable = {}
  instance.connectionsInfos = {}
  table.insert(instance.connectionsTable, "DSL 1000 (1024/128)")
  table.insert(instance.connectionsInfos, {maxCapacity = 2, uploadRate = 12})
  table.insert(instance.connectionsTable, "DSL 2000 (2048/192)")
  table.insert(instance.connectionsInfos, {maxCapacity = 4, uploadRate = 18})
  table.insert(instance.connectionsTable, "DSL 4000 (4096/256)")
  table.insert(instance.connectionsInfos, {maxCapacity = 4, uploadRate = 25})
  table.insert(instance.connectionsTable, "DSL 6000 (6016/576)")
  table.insert(instance.connectionsInfos, {maxCapacity = 8, uploadRate = 40})
  table.insert(instance.connectionsTable, "DSL 16000 (16000/1024)")
  table.insert(instance.connectionsInfos, {maxCapacity = 10, uploadRate = 60})
  table.insert(instance.connectionsTable, "DSL 25000 (25064/5056)")
  table.insert(instance.connectionsInfos, {maxCapacity = 10, uploadRate = 100})
  table.insert(instance.connectionsTable, "LAN/DSL 50k (51392/10048)")
  table.insert(instance.connectionsInfos, {maxCapacity = 10, uploadRate = 200})
  local name = ""
  if g_languageShort == "pl" then
    name = g_settingsNickname .. " - " .. g_i18n:getText("ServerName_Game")
  elseif Utils.endsWith(g_settingsNickname, "s") then
    name = g_settingsNickname .. "' " .. g_i18n:getText("ServerName_Game")
  elseif Utils.endsWith(g_settingsNickname, "'") then
    name = g_settingsNickname .. "s " .. g_i18n:getText("ServerName_Game")
  else
    name = g_settingsNickname .. "'s " .. g_i18n:getText("ServerName_Game")
  end
  instance.defaultServerName = name
  return instance
end
function CreateGameScreen:onOpen()
  self.isPortTesting = false
  self:fillCapacity()
  if not self.capacityInitialized then
    self.capacityInitialized = true
    local numPlayers = getXMLInt(g_savegameXML, "savegames.settings.createGame#capacity")
    if numPlayers ~= nil then
      for i = 1, table.getn(self.capacityNumberTable) do
        if numPlayers == self.capacityNumberTable[i] then
          self.capacityElement:setState(i)
          break
        end
      end
    end
  end
end
function CreateGameScreen:onClose()
end
function CreateGameScreen:getPort()
  local port = tonumber(self.portElement.text)
  if port == nil then
    port = g_defaultServerPort
  end
  self.portElement:setText(tostring(port))
  return port
end
function CreateGameScreen:onStartClick()
  local serverName = Utils.trim(self.serverNameElement.text)
  local filteredServerName = filterText(serverName)
  if serverName == "" then
    self.serverNameElement:setText(self.defaultServerName)
  elseif filteredServerName ~= serverName then
    self.serverNameElement:setText(filteredServerName)
  else
    local port = self:getPort()
    local capacity = self.capacityNumberTable[self.capacityElement.state]
    setXMLString(g_savegameXML, "savegames.settings.createGame#password", self.passwordElement.text)
    setXMLString(g_savegameXML, "savegames.settings.createGame#name", serverName)
    setXMLInt(g_savegameXML, "savegames.settings.createGame#port", port)
    setXMLInt(g_savegameXML, "savegames.settings.createGame#bandwidth", self.bandwidthElement.state)
    setXMLInt(g_savegameXML, "savegames.settings.createGame#capacity", capacity)
    saveXMLFile(g_savegameXML)
    self.missionDynamicInfo.serverPort = port
    self.missionDynamicInfo.isMultiplayer = true
    self.missionDynamicInfo.isClient = false
    self.missionDynamicInfo.autoAccept = false
    self.missionDynamicInfo.password = self.passwordElement.text
    self.missionDynamicInfo.serverName = serverName
    self.missionDynamicInfo.capacity = capacity
    self.missionDynamicInfo.mods = self.mods
    local uploadRate = self.connectionsInfos[self.bandwidthElement.state].uploadRate
    g_maxUploadRate = uploadRate * 1024 / 1000
    g_connectionFailedDialog:setNextScreenName("CreateGameScreen")
    g_mpLoadingScreen:setMissionInfo(self.missionInfo, self.missionDynamicInfo)
    g_mpLoadingScreen:showPortTesting()
    self:checkPort()
  end
end
function CreateGameScreen:onBackClick()
  g_gui:showGui("CareerScreen")
end
function CreateGameScreen:startGameAfterPortCheck()
  g_mpLoadingScreen:startServer()
end
function CreateGameScreen:removePortMapping()
  if self.mappedPort ~= 0 then
    upnpRemovePortMapping(self.mappedPort, "UDP")
    upnpRemovePortMapping(self.mappedPort, "TCP")
    self.mappedPort = 0
    self.lastCheckedPort = nil
  end
end
function CreateGameScreen:checkPort()
  local port = self:getPort()
  if self.lastCheckedPort == nil or self.lastCheckedPort ~= port then
    self:removePortMapping()
    self.testingPort = port
    self.hasPortConflict = false
    local hasUPNPDevice = upnpDiscover(2000, "")
    if hasUPNPDevice then
      local ip = netGetDefaultLocalIp()
      upnpRemovePortMapping(port, "UDP")
      upnpRemovePortMapping(port, "TCP")
      local mapping1Error = upnpAddPortMapping(port, port, "Farming Simulator 2011 UDP (" .. ip .. ")", "UDP")
      local mapping2Error = upnpAddPortMapping(port, port, "Farming Simulator 2011 TCP (" .. ip .. ")", "TCP")
      if mapping1Error == Upnp.ADD_PORT_CONFLICT or mapping2Error == Upnp.ADD_PORT_CONFLICT then
        self.hasPortConflict = true
      else
        self.mappedPort = port
      end
      if mapping1Error == Upnp.ADD_PORT_SUCCESS then
      else
        print("Warning: Failed to add UDP port mapping (" .. port .. "), error code: " .. mapping1Error)
      end
      if mapping2Error == Upnp.ADD_PORT_SUCCESS then
      else
        print("Warning: Failed to add TCP port mapping (" .. port .. "), error code: " .. mapping2Error)
      end
    else
      print("Error: No UPnP device found")
    end
    self:startGameAfterPortCheck()
  else
    self:startGameAfterPortCheck()
  end
end
function CreateGameScreen:unusedPacketReceived()
end
function CreateGameScreen:onPortTestCallback(isSuccessful)
  if self.isPortTesting then
    self.isPortTesting = false
    netShutdown(500, 0)
    if isSuccessful then
      self.lastCheckedPort = self.testingPort
      self.mappedPort = self.testingPort
      self:startGameAfterPortCheck()
    else
      self:removePortMapping()
      if self.hasPortConflict then
        g_portDialog:showPortTestConflict()
      else
        g_portDialog:showPortTestFailed()
      end
    end
  end
end
function CreateGameScreen:onMasterServerConnectionFailed(reason)
  if self.isPortTesting then
    self.isPortTesting = false
    netShutdown(500, 0)
    g_connectionFailedDialog:showMasterServerConnectionFailedReason(reason, "CreateGameScreen")
  end
end
function CreateGameScreen:onCreateServerName(element)
  self.serverNameElement = element
  local serverName = getXMLString(g_savegameXML, "savegames.settings.createGame#name")
  if serverName == nil then
    serverName = self.defaultServerName
  end
  self.serverNameElement:setText(serverName)
end
function CreateGameScreen:onCreatePassword(element)
  self.passwordElement = element
  local password = getXMLString(g_savegameXML, "savegames.settings.createGame#password")
  if password ~= nil then
    self.passwordElement:setText(password)
  end
end
function CreateGameScreen:onCreatePort(element)
  self.portElement = element
  local port = getXMLInt(g_savegameXML, "savegames.settings.createGame#port")
  if port == nil then
    port = g_defaultServerPort
  end
  self.portElement:setText(tostring(port))
end
function CreateGameScreen:numPlayerOnCreate(element)
  self.capacityElement = element
  element:setTexts(self.capacityTable)
  element:setState(table.getn(self.capacityTable))
end
function CreateGameScreen:numPlayerOnClick(state)
  self.capacity = state
end
function CreateGameScreen:onCreateBandwidth(element)
  element:setTexts(self.connectionsTable)
  local state = 2
  local bandwidth = getXMLInt(g_savegameXML, "savegames.settings.createGame#bandwidth")
  if bandwidth ~= nil then
    state = bandwidth
  end
  element:setState(math.min(math.max(state, 1), table.getn(self.connectionsTable)))
  self.bandwidthElement = element
end
function CreateGameScreen:onClickBandwidth(state)
  self:fillCapacity()
end
function CreateGameScreen:fillCapacity()
  local info = self.connectionsInfos[self.bandwidthElement.state]
  self.capacityTable = {}
  self.capacityNumberTable = {}
  for i = 2, info.maxCapacity do
    table.insert(self.capacityTable, tostring(i))
    table.insert(self.capacityNumberTable, i)
  end
  local state = self.capacityElement.state
  self.capacityElement:setTexts(self.capacityTable)
  self.capacityElement:setState(math.min(state, table.getn(self.capacityTable)))
end
function CreateGameScreen:onAddModsClick()
  if not self.isPortTesting then
    g_gui:showGui("ModSelectionScreen")
  end
end
function CreateGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
  self.missionInfo = missionInfo
  self.missionDynamicInfo = missionDynamicInfo
  self.mapModName = self.missionInfo.map.customEnvironment
  self.mods = {}
  if self.mapModName ~= nil then
    table.insert(self.mods, ModsUtil.findModItemByModName(self.mapModName))
  end
end
function CreateGameScreen:setSelectedMods(addedMods)
  self.mods = addedMods
end
function CreateGameScreen:onIsUnicodeAllowed(unicode)
  return unicode >= string.byte("0", 1) and unicode <= string.byte("9", 1)
end
