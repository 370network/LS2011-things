JoinGameScreen = {}
local JoinGameScreen_mt = Class(JoinGameScreen)
function JoinGameScreen:new()
  local instance = GuiElement:new(target, JoinGameScreen_mt)
  instance.servers = {}
  instance.serverElements = {}
  instance.requestedDetailsServerId = -1
  instance.numServersElement = {}
  instance.totalNumServers = 0
  return instance
end
function JoinGameScreen:onOpen()
  self.requestedDetailsServerId = -1
  self.isRequestPending = false
  g_masterServerConnection:setCallbackTarget(self)
  self.startButtonElement:setDisabled(true)
  self.numServersElement:setText("")
  self:getServers()
end
function JoinGameScreen:onClose()
end
function JoinGameScreen:onDoubleClick()
  self:onStartClick()
end
function JoinGameScreen:onStartClick()
  if self.listTemplateParent.selectedRow > 0 then
    local server = self.servers[self.listTemplateParent.selectedRow]
    if server ~= nil and server.allModsAvailable then
      if not server.hasPassword then
        self:startGame("", server.id)
      else
        g_passwordDialog:setCallbacks(self.onPasswordEntered, self)
        g_gui:showGui("PasswordDialog")
      end
    end
  end
end
function JoinGameScreen:startGame(password, serverId)
  local missionInfo = FSCareerMissionInfo:new("", nil, 0)
  missionInfo:loadDefaults()
  missionInfo.farmSiloAmounts = {}
  local missionDynamicInfo = {}
  missionDynamicInfo.serverId = serverId
  missionDynamicInfo.isMultiplayer = true
  missionDynamicInfo.isClient = true
  missionDynamicInfo.password = password
  g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
  g_gui:showGui("MPLoadingScreen")
  g_mpLoadingScreen:startClient()
end
function JoinGameScreen:onPasswordEntered(password)
  local server = self.servers[self.listTemplateParent.selectedRow]
  self:startGame(password, server.id)
end
function JoinGameScreen:onBackClick()
  g_masterServerConnection:disconnectFromMasterServer()
  g_connectionManager:shutdownAll()
  g_gui:showGui("MultiplayerScreen")
end
function JoinGameScreen:onSearchClick()
  g_gui:showGui("FilterGameScreen")
end
function JoinGameScreen:onListSelectionChanged(selectedRow)
  if self.startButtonElement ~= nil then
    local isValid = false
    if 0 < selectedRow then
      local server = self.servers[selectedRow]
      if server ~= nil and server.allModsAvailable then
        isValid = true
      end
    end
    if isValid then
      self.startButtonElement:setDisabled(false)
    else
      self.startButtonElement:setDisabled(true)
    end
  end
end
function JoinGameScreen:setText(text)
  if self.textElement ~= nil then
    self.textElement:setText(text)
  end
end
function JoinGameScreen:onCreateStart(element)
  self.startButtonElement = element
end
function JoinGameScreen:onCreateText(element)
  self.textElement = element
end
function JoinGameScreen:onCreateList(element)
  self.list = element
  local listElement = self.list
  local screenElement = self
  function self.list:shouldFocusChange(direction)
    local selectedListElement = listElement:getSelectedElement()
    if selectedListElement then
      local currentDetailsButton = selectedListElement.elements[2]
      if direction == FocusManager.RIGHT then
        if currentDetailsButton.state == ButtonElement.STATE_NORMAL then
          currentDetailsButton:onFocusEnter()
          return false
        else
          return true
        end
      elseif direction == FocusManager.LEFT then
        if currentDetailsButton.state == ButtonElement.STATE_FOCUSED then
          currentDetailsButton:onFocusLeave()
          return false
        else
          return true
        end
      end
    end
    return ListElement.shouldFocusChange(listElement, direction)
  end
  function self.list:onFocusLeave(...)
    local selectedListElement = listElement:getSelectedElement()
    if selectedListElement then
      local currentDetailsButton = selectedListElement.elements[2]
      currentDetailsButton:onFocusLeave()
    end
    return ListElement.onFocusLeave(listElement, ...)
  end
  function self.list:onFocusActivate(...)
    local selectedListElement = listElement:getSelectedElement()
    if selectedListElement then
      local currentDetailsButton = selectedListElement.elements[2]
      if currentDetailsButton.state == ButtonElement.STATE_FOCUSED then
        return currentDetailsButton:onFocusActivate(...)
      end
    end
    return ListElement.onFocusActivate(listElement, ...)
  end
end
function JoinGameScreen:onCreateListTemplate(element)
  if self.listTemplate == nil then
    self.listTemplate = element
    self.listTemplateParent = self.listTemplate.parent
    self.listTemplate.parent:removeElement(self.listTemplate)
  end
end
function JoinGameScreen:onMissionScreenCreated(element)
end
function JoinGameScreen:onCreateNumServers(element)
  self.numServersElement = element
end
function JoinGameScreen:onRefreshClick()
  self:getServers()
end
function JoinGameScreen:getServers()
  if self.isRequestPending then
    return
  end
  masterServerAddAvailableModStart()
  for i = 1, table.getn(ModsUtil.modList) do
    if ModsUtil.modList[i].isMultiplayerSupported and ModsUtil.modList[i].fileHash ~= nil then
      masterServerAddAvailableMod(ModsUtil.modList[i].fileHash)
    end
  end
  masterServerAddAvailableModEnd()
  self.isRequestPending = true
  local filter = g_filterGameScreen
  masterServerRequestFilteredServers(filter.serverName, filter.hasNoPassword, filter.capacity, filter.isNotEmpty, filter.selectedMap, filter.onlyWithAllModsAvailable, filter.selectedLanguage)
end
function JoinGameScreen:updateServersGraphics()
  self.numServersElement:setText(string.format(g_i18n:getText("NumOfNumOpenGames"), table.getn(self.servers), self.totalNumServers))
  while table.getn(self.listTemplateParent.listItems) > 0 do
    local element = self.listTemplateParent.listItems[1]
    self.listTemplateParent:removeElement(element)
    element:delete()
  end
  for i = 1, table.getn(self.servers) do
    self.currentServer = self.servers[i]
    if self.listTemplate ~= nil then
      self.serverElements[self.currentServer.id] = {}
      local new = self.listTemplate:clone(self.listTemplateParent)
      new:updateAbsolutePosition()
      local dr, dg, db, da = 0.7, 0.7, 0.7, 0.8
      local dr2, dg2, db2, da2 = 0, 0, 0, 0.2
      local elements = self.serverElements[self.currentServer.id]
      if elements.password ~= nil and not self.currentServer.hasPassword then
        elements.password.imageColor = {
          0.3,
          0.3,
          0.3,
          0.5
        }
      end
      if elements.lanInternet ~= nil and self.currentServer.isLanServer then
        elements.lanInternet:setImageFilename("dataS/menu/lan_icon.png")
      end
      if elements.name ~= nil then
        setTextBold(elements.name.textBold)
        elements.name:setText(Utils.limitTextToWidth(self.currentServer.name, 0.03, 0.294, false, ".."))
        setTextBold(false)
        if not self.currentServer.allModsAvailable then
          elements.name:setTextColor(dr, dg, db, da)
          elements.name:setText2Color(dr2, dg2, db2, da2)
        end
      end
      if elements.map ~= nil then
        setTextBold(elements.map.textBold)
        elements.map:setText(Utils.limitTextToWidth(self.currentServer.mapName, 0.03, 0.21, false, ".."))
        setTextBold(false)
        if not self.currentServer.allModsAvailable then
          elements.map:setTextColor(dr, dg, db, da)
          elements.map:setText2Color(dr2, dg2, db2, da2)
        end
      end
      if elements.numPlayers ~= nil then
        elements.numPlayers:setText(self.currentServer.numPlayers .. "/" .. self.currentServer.capacity)
        if not self.currentServer.allModsAvailable then
          elements.numPlayers:setTextColor(dr, dg, db, da)
          elements.numPlayers:setText2Color(dr2, dg2, db2, da2)
        end
      end
      if elements.language ~= nil then
        elements.language:setText(getLanguageCode(self.currentServer.language):upper())
        if not self.currentServer.allModsAvailable then
          elements.language:setTextColor(dr, dg, db, da)
          elements.language:setText2Color(dr2, dg2, db2, da2)
        end
      end
    end
    self.currentServer = nil
  end
end
function JoinGameScreen:onCreateServerName(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].name = element
  end
end
function JoinGameScreen:onCreateServerMap(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].map = element
  end
end
function JoinGameScreen:onCreateServerPassword(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].password = element
  end
end
function JoinGameScreen:onCreateServerLanInternet(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].lanInternet = element
  end
end
function JoinGameScreen:onCreateServerNumPlayers(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].numPlayers = element
  end
end
function JoinGameScreen:onCreateServerLanguage(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].language = element
  end
end
function JoinGameScreen:onCreateDetailButton(element)
  if self.currentServer ~= nil then
    do
      local currentServer = self.currentServer
      function element.onClick(unused)
        self:onDetailClick(currentServer)
      end
    end
  end
end
function JoinGameScreen:onDetailClick(server)
  if self.requestedDetailsServerId < 0 then
    self.requestedDetailsServerId = server.id
    masterServerRequestServerDetails(server.id)
  end
end
function JoinGameScreen:onServerInfoDetails(id, ip, port, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashs)
  if id == self.requestedDetailsServerId then
    self.requestedDetailsServerId = -1
    self.serverDetailsId = id
    self.serverDetailsIP = ip
    self.serverDetailsPort = port
    self.serverDetailsName = name
    self.serverDetailsLanguage = language
    self.serverDetailsCapacity = capacity
    self.serverDetailsNumPlayers = numPlayers
    self.serverDetailsMapName = mapName
    self.serverDetailsHasPassword = hasPassword
    self.serverDetailsIsLanServer = isLanServer
    self.serverDetailsModTitles = modTitles
    self.serverDetailsModHashs = modHashs
    self.serverDatailsAllModsAvailable = ModsUtil.getAreAllModsAvailable(modHashs)
    g_gui:showGui("ServerDetailDialog")
  end
end
function JoinGameScreen:onServerInfoDetailsFailed()
  self.requestedDetailsServerId = -1
end
function JoinGameScreen:onMasterServerConnectionReady()
end
function JoinGameScreen:onMasterServerConnectionFailed(reason)
  g_masterServerConnection:disconnectFromMasterServer()
  g_connectionManager:shutdownAll()
  g_connectionFailedDialog:showMasterServerConnectionFailedReason(reason, "MultiplayerScreen")
end
function JoinGameScreen:onServerInfoStart(numServers, totalNumServers)
  self.totalNumServers = totalNumServers
  self.servers = {}
end
function JoinGameScreen:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer)
  local server = {
    id = id,
    name = name,
    hasPassword = hasPassword,
    language = language,
    capacity = capacity,
    numPlayers = numPlayers,
    mapName = mapName,
    allModsAvailable = allModsAvailable,
    isLanServer = isLanServer
  }
  table.insert(self.servers, server)
end
function JoinGameScreen:onServerInfoEnd()
  self.isRequestPending = false
  self:updateServersGraphics()
end
function JoinGameScreen:onCreateUpButton(upButton)
  self.upButton = upButton
end
function JoinGameScreen:focusOverrideUpButton(direction)
  local focusOverriden, nextElement = false
  if direction == FocusManager.BOTTOM and table.getn(self.list.listItems) == 0 then
    focusOverriden = true
    nextElement = self.downButton
  end
  return focusOverriden, nextElement
end
function JoinGameScreen:onCreateDownButton(downButton)
  self.downButton = downButton
end
function JoinGameScreen:focusOverrideDownButton(direction)
  local focusOverriden, nextElement = false
  if direction == FocusManager.TOP and table.getn(self.list.listItems) == 0 then
    focusOverriden = true
    nextElement = self.upButton
  end
  return focusOverriden, nextElement
end
function JoinGameScreen:scrollListUp()
  self.list:scrollList(-1)
end
function JoinGameScreen:scrollListDown()
  self.list:scrollList(1)
end
