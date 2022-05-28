FSBaseMission = {}
FSBaseMission.USER_STATE_LOADING = 1
FSBaseMission.USER_STATE_SYNCHRONIZING = 2
FSBaseMission.USER_STATE_CONNECTED = 3
source("dataS/scripts/BaseMissionFinishedLoadingEvent.lua")
source("dataS/scripts/BaseMissionReadyEvent.lua")
source("dataS/scripts/SetDensityMapEvent.lua")
source("dataS/scripts/CreateCowsEvent.lua")
source("dataS/scripts/BaseMissionSetFruitAmount.lua")
source("dataS/scripts/ConnectionRequestEvent.lua")
source("dataS/scripts/ConnectionRequestAnswerEvent.lua")
source("dataS/scripts/MoneyEvent.lua")
source("dataS/scripts/UserEvent.lua")
source("dataS/scripts/GamePauseEvent.lua")
local FSBaseMission_mt = Class(FSBaseMission, BaseMission)
function FSBaseMission:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = FSBaseMission_mt
  end
  local self = FSBaseMission:superClass():new(baseDirectory, mt)
  self.bronzeTime = 0
  self.silverTime = 0
  self.goldTime = 0
  self.record = 0
  self.minTime = 0
  self.sunk = false
  self.medalOverlay = nil
  self.isFreePlayMission = false
  self.tipTriggers = {}
  self.siloAmountListeners = {}
  self.cowIncomeInterval = 300000
  self.cowIncomeTime = self.cowIncomeInterval
  self.renderTime = false
  self.missionCompletedOverlayId = nil
  self.missionFailedOverlayId = nil
  self.hudBaseWidth = 0.18286
  self.hudBaseHeight = 0.1219
  self.hudBasePosX = 0.81
  self.hudBasePosY = 1 - self.hudBaseHeight
  self.hudBaseWeatherPosX = self.hudBasePosX + 0.11143
  self.hudBaseWeatherPosY = self.hudBasePosY + 0.02762
  self.hudBaseWeatherWidth = 0.04929
  self.hudBaseWeatherHeight = 0.06571
  self.hudMissionBasePosX = self.hudHelpBasePosX + self.hudHelpBaseWidth + 0.03
  self.hudMissionBasePosY = self.hudHelpBasePosY
  self.hudMissionBaseWidth = self.hudHelpBaseWidth
  self.hudMissionBaseHeight = self.hudHelpBaseHeight
  self.completeDisplayX = 0.313
  self.completeDisplayY = 0.37250000000000005
  self.completeDisplayWidth = 0.374
  self.completeDisplayHeight = 0.382
  self.hudBaseOverlay = Overlay:new("hudBaseOverlay", "dataS2/missions/hud_env_base.png", self.hudBasePosX, self.hudBasePosY, self.hudBaseWidth, self.hudBaseHeight)
  self.hudBaseSunOverlay = Overlay:new("hudBaseSunOverlay", "dataS2/missions/hud_sun.png", self.hudBaseWeatherPosX, self.hudBaseWeatherPosY, self.hudBaseWeatherWidth, self.hudBaseWeatherHeight)
  self.hudBaseRainOverlay = Overlay:new("hudBaseRainOverlay", "dataS2/missions/hud_rain.png", self.hudBaseWeatherPosX, self.hudBaseWeatherPosY, self.hudBaseWeatherWidth, self.hudBaseWeatherHeight)
  self.hudBaseHailOverlay = Overlay:new("hudBaseHailOverlay", "dataS2/missions/hud_hail.png", self.hudBaseWeatherPosX, self.hudBaseWeatherPosY, self.hudBaseWeatherWidth, self.hudBaseWeatherHeight)
  self.hudMissionBaseOverlay = Overlay:new("hudMissionBaseOverlay", "dataS2/missions/hud_help_base.png", self.hudMissionBasePosX, self.hudMissionBasePosY, self.hudMissionBaseWidth, self.hudMissionBaseHeight)
  self.fruitSymbolSize = 0.08
  self.fruitSymbolX = 0.923
  self.fruitSymbolY = 0.28
  self.fruitOverlays = {}
  for fruitName, fruitType in pairs(FruitUtil.fruitTypes) do
    if fruitType.hudFruitOverlayFilename ~= nil then
      self.fruitOverlays[fruitType.index] = Overlay:new("hudFruitOverlay", fruitType.hudFruitOverlayFilename, self.fruitSymbolX, self.fruitSymbolY, self.fruitSymbolSize, self.fruitSymbolSize * 1.3333333333333333)
    end
  end
  self.showWeatherForecast = false
  self.showHudMissionBase = false
  self.showHudEnv = true
  self.reputation = 0
  self.missionStats = MissionStats:new()
  self.missionPDA = MissionPDA:new()
  self.fruits = {}
  self.fruitsList = {}
  self.playerStartIsAbsolute = false
  self.playersToAccept = {}
  self.playersLoading = {}
  self.numPlayersSynchronizing = 0
  self.playersSynchronizing = {}
  self.users = {}
  self.userIdCounter = 0
  self.playerUserId = -1
  self.blockedIps = {}
  self.lastMilkPickupDay = 0
  self.terrainSize = 1
  self.terrainDetailMapSize = 1
  self.fruitMapSize = 1
  self.dynamicFoliageLayers = {}
  self.allowClientsCreateFields = false
  self.allowClientsSellVehicles = false
  self.allowClientsOwnMoney = false
  self.sendingDensityMapEvents = {}
  self.connectionWasAccepted = false
  self.milkProductionScale = 1
  self.milkPriceScale = 1
  self.manureProductionScale = 1
  self.densityMapPercentageFraction = 0.9
  return self
end
function FSBaseMission:delete()
  removeConsoleCommand("gsCheatMoney")
  removeConsoleCommand("gsCheatSilo")
  removeConsoleCommand("gsCheatFeedingTrough")
  removeConsoleCommand("gsSetMilkDifficulty")
  if self.missionCompletedOverlayId ~= nil then
    delete(self.missionCompletedOverlayId)
  end
  if self.missionFailedOverlayId ~= nil then
    delete(self.missionFailedOverlayId)
  end
  self.missionPDA:delete()
  self.hudBaseOverlay:delete()
  self.hudBaseSunOverlay:delete()
  self.hudBaseRainOverlay:delete()
  self.hudBaseHailOverlay:delete()
  self.hudMissionBaseOverlay:delete()
  if self.medalOverlay ~= nil then
    self.medalOverlay:delete()
  end
  if self.inGameMessage ~= nil then
    self.inGameMessage:delete()
  end
  if self.inGameIcon ~= nil then
    self.inGameIcon:delete()
  end
  FSBaseMission:superClass().delete(self)
end
function FSBaseMission:load()
  if self:getIsServer() then
    if g_isDevelopmentVersion then
      addConsoleCommand("gsCheatMoney", "Add a lot of money", "consoleCommandCheatMoney", self)
      addConsoleCommand("gsCheatSilo", "Add silo amount", "consoleCommandCheatSilo", self)
      addConsoleCommand("gsCheatFeedingTrough", "Add grass to feeding through", "consoleCommandCheatFeedingTrough", self)
    end
    addConsoleCommand("gsSetMilkDifficulty", "Set milk and manure production difficulty", "consoleCommandSetMilkDifficulty", self)
    if self.milkProductionScale ~= 1 or self.milkPriceScale ~= 1 or self.manureProductionScale ~= 1 then
      print("Loaded milk difficulty: Milk production = " .. math.floor(self.milkProductionScale * 100) .. "%. Milk price = " .. math.floor(self.milkPriceScale * 100) .. "%. Manure production = " .. math.floor(self.manureProductionScale * 100) .. "%.")
      self:setMilkAndManureScales(self.milkProductionScale, self.milkPriceScale, self.manureProductionScale)
    end
  end
  self.inGameMessage = InGameMessage:new()
  self.inGameIcon = InGameIcon:new()
  FSBaseMission:superClass().load(self)
  if self:getIsServer() and AnimalHusbandry.isInUse then
    local object = AnimalsNetworkObject:new(self:getIsServer(), self:getIsClient())
    object:register()
  end
end
function FSBaseMission:loadFinished()
  if g_client ~= nil then
    self.player = Player:new(g_server ~= nil, true)
    local connection
    if self:getIsServer() then
      connection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID]
    end
    self.player:load("data/character/farmer/farmer_player.i3d", self.playerStartX, self.playerStartY, self.playerStartZ, self.playerRotX, self.playerRotY, self.playerStartIsAbsolute, g_settingsNickname, connection)
    self.player:onEnter(true)
    self.player:register(false)
  end
end
function FSBaseMission:getClientPosition()
  return getWorldTranslation(getCamera())
end
function FSBaseMission:setLoadingScreen(loadingScreen)
  self.loadingScreen = loadingScreen
end
function FSBaseMission:onConnectionOpened(connection)
end
function FSBaseMission:onConnectionAccepted(connection)
  self.connectionWasAccepted = true
  if self.loadingScreen ~= nil then
    self.loadingScreen:onWaitingForAccept()
  end
  g_client:getServerConnection():sendEvent(ConnectionRequestEvent:new(g_settingsNickname, g_settingsLanguage, self.missionDynamicInfo.password), nil, true)
end
function FSBaseMission:onConnectionRequest(connection, nickname, language, password)
  if connection.streamId ~= NetworkNode.LOCAL_STREAM_ID then
    if table.getn(self.users) >= self.missionDynamicInfo.capacity then
      connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_FULL), nil, true)
      return
    end
    local ip = streamGetIpAndPort(connection.streamId)
    if self.blockedIps[ip] ~= nil then
      connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_DENIED), nil, true)
      return
    end
    if self.missionDynamicInfo.password == password then
      table.insert(self.playersToAccept, {
        connection = connection,
        nickname = nickname,
        language = language
      })
    else
      connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD), nil, true)
      return
    end
  else
    self.userIdCounter = self.userIdCounter + 1
    assert(self.userIdCounter == 1)
    self.playerUserId = 1
    table.insert(self.users, {
      connection = connection,
      userId = self.userIdCounter,
      nickname = nickname,
      language = language,
      connectedTime = self.time,
      state = FSBaseMission.USER_STATE_CONNECTED,
      money = 0,
      moneySent = 0,
      updateSendTime = self.time
    })
    self:sendNumPlayersToMasterServer(table.getn(self.users))
    connection:sendEvent(ConnectionRequestAnswerEvent:new(ConnectionRequestAnswerEvent.ANSWER_OK, self.missionStats.difficulty, self.missionStats.timeScale), nil, true)
  end
end
function FSBaseMission:onConnectionDenyAccept(connection, isDenied, isAlwaysDenied)
  local playerToAccept
  for i = 1, table.getn(self.playersToAccept) do
    local p = self.playersToAccept[i]
    if p.connection == connection then
      playerToAccept = p
      table.remove(self.playersToAccept, i)
      break
    end
  end
  if playerToAccept == nil then
    return
  end
  local answer = ConnectionRequestAnswerEvent.ANSWER_OK
  if isAlwaysDenied then
    local ip = streamGetIpAndPort(connection.streamId)
    self.blockedIps[ip] = true
    answer = ConnectionRequestAnswerEvent.ANSWER_DENIED
  elseif isDenied then
    answer = ConnectionRequestAnswerEvent.ANSWER_DENIED
  else
    local nickname = playerToAccept.nickname
    local language = playerToAccept.language
    local newNickname = nickname
    local nickValid = true
    for _, user in pairs(self.users) do
      if user.nickname == nickname then
        nickValid = false
        break
      end
    end
    local index = 1
    while not nickValid do
      newNickname = nickname .. " (" .. index .. ")"
      nickValid = true
      for _, user in pairs(self.users) do
        if user.nickname == newNickname then
          nickValid = false
          break
        end
      end
      index = index + 1
    end
    self.userIdCounter = self.userIdCounter + 1
    local user = {
      connection = connection,
      userId = self.userIdCounter,
      nickname = newNickname,
      language = language,
      connectedTime = self.time,
      state = FSBaseMission.USER_STATE_LOADING,
      money = 0,
      moneySent = 0,
      updateSendTime = self.time
    }
    table.insert(self.users, user)
    self:sendNumPlayersToMasterServer(table.getn(self.users))
    self.playersLoading[connection] = {connection = connection, user = user}
  end
  connection:sendEvent(ConnectionRequestAnswerEvent:new(answer, self.missionStats.difficulty, self.missionStats.timeScale), nil, true)
end
function FSBaseMission:onConnectionRequestAnswer(connection, answer, difficulty, timeScale)
  if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
    self.missionStats.difficulty = difficulty
    self.missionStats.timeScale = timeScale
    self:onConnectionRequestAccepted(connection)
  else
    g_connectionRequestAnswerDialog:setAnswer(answer)
    g_gui:showGui("ConnectionRequestAnswerDialog")
  end
end
function FSBaseMission:onConnectionRequestAccepted(connection)
  if self.loadingScreen ~= nil then
    self.loadingScreen:loadWithConnection(connection)
  end
end
function FSBaseMission:onConnectionRequestAcceptedLoad(connection)
  simulatePhysics(false)
  self:load()
  simulatePhysics(true)
  self.isLoaded = true
  if not self:getIsServer() then
    local x, y, z = self:getClientPosition()
    if self.loadingScreen ~= nil then
      self.loadingScreen:onWaitingForDynamicData()
    end
    self:pauseGame()
    AnimalHusbandry.addPlayer(connection)
    connection:sendEvent(BaseMissionFinishedLoadingEvent:new(x, y, z, getViewDistanceCoeff()), nil, true)
  else
    AnimalHusbandry.addPlayer(connection.localConnection)
    self:pauseGame()
    if self.loadingScreen ~= nil then
      self.loadingScreen:onFinishedReceivingDynamicData()
    end
  end
end
function FSBaseMission:onConnectionFinishedLoading(connection, x, y, z, viewDistanceCoeff)
  assert(not connection:getIsLocal(), "No local connection allowed in BaseMission:onConnectionFinishedLoading")
  if self.playersSynchronizing[connection] ~= nil or self.playersLoading[connection] == nil then
    g_server:closeConnection(connection)
    return
  end
  connection:setIsReadyForEvents(true)
  local user = self.playersLoading[connection].user
  self.playersLoading[connection] = nil
  user.state = FSBaseMission.USER_STATE_SYNCHRONIZING
  self.playersSynchronizing[connection] = {connection = connection, user = user}
  self.numPlayersSynchronizing = self.numPlayersSynchronizing + 1
  self:pauseGame()
  g_server:broadcastEvent(GamePauseEvent:new(true), nil, connection, nil, true)
  AnimalHusbandry.addPlayer(connection)
  g_server:sendEventIds(connection)
  g_server:sendObjectClassIds(connection)
  connection:sendEvent(OnCreateLoadedObjectEvent:new())
  g_server:sendObjects(connection, x, y, z, viewDistanceCoeff)
  connection:sendEvent(EnvironmentTimeEvent:new(self.environment.dayTime))
  connection:sendEvent(EnvironmentTmpEvent:new(self.missionPDA.pdaWeatherTemperaturesDay, self.missionPDA.pdaWeatherTemperaturesNight))
  connection:sendEvent(EnvironmentPriceEvent:new(FruitUtil.fruitIndexToDesc))
  for fillType, amount in pairs(self.missionStats.farmSiloAmounts) do
    connection:sendEvent(BaseMissionSetFruitAmount:new(fillType, amount))
  end
  connection:sendEvent(CreateCowsEvent:new())
  if self.loadingScreen ~= nil then
    self.loadingScreen:setDynamicDataPercentage(1 - self.densityMapPercentageFraction)
  end
  g_server:broadcastEvent(UserEvent:new(self.users, self.missionDynamicInfo.capacity))
  local densityMapEvent = SetDensityMapEvent:new()
  self.sendingDensityMapEvents[connection] = densityMapEvent
  connection:sendEvent(densityMapEvent, false)
end
function FSBaseMission:onDensityMapsProgress(connection, percentage)
  if percentage < 1 then
    if not self:getIsServer() and self.loadingScreen ~= nil then
      self.loadingScreen:setDynamicDataPercentage(percentage * self.densityMapPercentageFraction + (1 - self.densityMapPercentageFraction))
    end
  elseif self:getIsServer() then
    connection:sendEvent(BaseMissionReadyEvent:new(), nil, true)
  end
end
function FSBaseMission:onFinishedReceivingDynamicData(connection)
  if self.loadingScreen ~= nil then
    self.loadingScreen:onFinishedReceivingDynamicData()
    connection:sendEvent(BaseMissionReadyEvent:new(), nil, true)
  end
end
function FSBaseMission:onConnectionReady(connection)
  if self.playersSynchronizing[connection] == nil then
    g_server:closeConnection(connection)
    return
  end
  if self.sendingDensityMapEvents[connection] ~= nil then
    self.sendingDensityMapEvents[connection]:delete()
    self.sendingDensityMapEvents[connection] = nil
  end
  connection:setIsReadyForObjects(true)
  self.numPlayersSynchronizing = self.numPlayersSynchronizing - 1
  if self.numPlayersSynchronizing <= 0 then
    self:unpauseGame()
    g_server:broadcastEvent(GamePauseEvent:new(false), nil, nil, nil, true)
  end
  local user = self.playersSynchronizing[connection].user
  user.state = FSBaseMission.USER_STATE_CONNECTED
  self.playersSynchronizing[connection] = nil
end
function FSBaseMission:onConnectionClosed(connection)
  if not self:getIsServer() then
    if self.receivingDensityMapEvent ~= nil then
      self.receivingDensityMapEvent:delete()
      self.receivingDensityMapEvent = nil
    end
    self:pauseGame()
    if self.connectionWasAccepted then
      g_connectionLostDialog:setFailedText(g_i18n:getText("ConnectionLost"))
    else
      g_connectionLostDialog:setFailedText(g_i18n:getText("Game_Connection_failed"))
    end
    g_gui:showGui("ConnectionLostDialog")
  else
    if self.sendingDensityMapEvents[connection] ~= nil then
      self.sendingDensityMapEvents[connection]:delete()
      self.sendingDensityMapEvents[connection] = nil
    end
    for i = 1, table.getn(self.playersToAccept) do
      if self.playersToAccept[i].connection == connection then
        table.remove(self.playersToAccept, i)
        break
      end
    end
    self.playersLoading[connection] = nil
    AnimalHusbandry.removePlayer(connection)
    for _, vehicle in pairs(self.vehicles) do
      if vehicle.owner == connection then
        g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(vehicle))
      end
    end
    for i = 1, table.getn(self.users) do
      if self.users[i].connection == connection then
        self.missionStats.money = self.missionStats.money + self.users[i].money
        table.remove(self.users, i)
        break
      end
    end
    if self.playersSynchronizing[connection] ~= nil then
      self.playersSynchronizing[connection] = nil
      self.numPlayersSynchronizing = self.numPlayersSynchronizing - 1
      if self.numPlayersSynchronizing <= 0 then
        self:unpauseGame()
        g_server:broadcastEvent(GamePauseEvent:new(false), nil, nil, nil, true)
      end
    end
    if self.connectionsToPlayer[connection] ~= nil then
      local player = self.connectionsToPlayer[connection]
      player:unregister()
      player:delete()
      self.connectionsToPlayer[connection] = nil
    end
    self:sendNumPlayersToMasterServer(table.getn(self.users))
    g_server:broadcastEvent(UserEvent:new(self.users, self.missionDynamicInfo.capacity))
  end
end
function FSBaseMission:onShutdownEvent(connection)
  if not self:getIsServer() then
    g_gui:showGui("ShutdownDialog")
  else
    AnimalHusbandry.removePlayer(connection)
    for i = 1, table.getn(self.users) do
      if self.users[i].connection == connection then
        self.missionStats.money = self.missionStats.money + self.users[i].money
        table.remove(self.users, i)
        break
      end
    end
    self:sendNumPlayersToMasterServer(table.getn(self.users))
    g_server:broadcastEvent(UserEvent:new(self.users, self.missionDynamicInfo.capacity))
  end
end
function FSBaseMission:onMasterServerConnectionFailed(reason)
  g_gui:showGui("InGameMenu")
  g_inGameMenu:setMasterServerConnectionFailed()
end
function FSBaseMission:findUserIdByConnection(connection)
  for _, user in ipairs(self.users) do
    if user.connection == connection then
      return user.userId
    end
  end
  return -1
end
function FSBaseMission:findUserByUserId(userId)
  if userId == nil then
    return nil
  end
  for _, user in ipairs(self.users) do
    if user.userId == userId then
      return user
    end
  end
  return nil
end
function FSBaseMission:kickUser(user)
  for _, user1 in ipairs(self.users) do
    if user1.userId == user.userId then
      g_server:closeConnection(user.connection)
      break
    end
  end
end
function FSBaseMission:banUser(user)
  for _, user1 in ipairs(self.users) do
    if user1.userId == user.userId then
      local ip = streamGetIpAndPort(user.connection.streamId)
      self.blockedIps[ip] = true
      g_server:closeConnection(user.connection)
      break
    end
  end
end
function FSBaseMission:addVehicle(vehicle)
  FSBaseMission:superClass().addVehicle(self, vehicle)
  g_shopScreen:onVehiclesChanged()
end
function FSBaseMission:removeVehicle(vehicle, callDelete)
  FSBaseMission:superClass().removeVehicle(self, vehicle, callDelete)
  g_shopScreen:onVehiclesChanged()
end
function FSBaseMission:loadMap(filename)
  local node = FSBaseMission:superClass().loadMap(self, filename)
  if node ~= 0 then
    local terrainNode = getChild(node, "terrain")
    if terrainNode ~= 0 then
      self.terrainRootNode = terrainNode
      self.terrainSize = getTerrainSize(self.terrainRootNode)
      local foliageViewCoeff = getFoliageViewDistanceCoeff()
      local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(self.terrainRootNode)
      setTerrainLodBlendDynamicDistances(self.terrainRootNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)
      self.terrainDetailId = getChild(self.terrainRootNode, "terrainDetail")
      if self.terrainDetailId ~= 0 then
        local numChildren = getNumOfChildren(self.terrainDetailId)
        if 0 < numChildren then
          local viewDistance = getTerrainDetailViewDistance(self.terrainDetailId)
          for i = 0, numChildren - 1 do
            setShaderParameter(getChildAt(self.terrainDetailId, i), "alphaBlendStartEnd", viewDistance - 10, viewDistance - 7, 0, 0, true)
          end
        end
        self.terrainDetailMapSize = getDensityMapSize(self.terrainDetailId)
      end
      local diffGrowthScale = 0.8
      if self.missionStats.difficulty >= 2 then
        diffGrowthScale = 1
        if self.missionStats.difficulty >= 3 then
          diffGrowthScale = 3
        end
      end
      local timeGrowthScale = Utils.lerp(1, 0.8, (self.missionStats.timeScale - 1) / 59)
      local growthStateFactor = diffGrowthScale * timeGrowthScale
      for i = 1, FruitUtil.NUM_FRUITTYPES do
        local fruitType = FruitUtil.fruitIndexToDesc[i]
        local fruitName = fruitType.name
        local entry = {}
        entry.id = getChild(self.terrainRootNode, fruitName)
        entry.cutShortId = getChild(self.terrainRootNode, fruitName .. "_cut_short")
        entry.cutLongId = getChild(self.terrainRootNode, fruitName .. "_cut_long")
        entry.windrowId = getChild(self.terrainRootNode, fruitName .. "_windrow")
        if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
          local dir = self.missionInfo.savegameDirectory
          if entry.id ~= 0 then
            loadGrowthStateFromFile(entry.id, dir .. "/" .. getName(entry.id) .. "_growthState.xml")
          end
        end
        if entry.id ~= 0 then
          self.fruitMapSize = math.max(self.fruitMapSize, getDensityMapSize(entry.id))
          local growthStateTime = getGrowthStateTime(entry.id)
          setGrowthStateTime(entry.id, growthStateTime * growthStateFactor)
          if 0 < getNumOfChildren(entry.id) then
            local viewDistance = getFoliageViewDistance(entry.id)
            setShaderParameter(getChildAt(entry.id, 0), "alphaBlendStartEnd", viewDistance - 5, viewDistance, 0, 0, true)
          end
        end
        if entry.cutShortId ~= 0 and 0 < getNumOfChildren(entry.cutShortId) then
          local viewDistance = getFoliageViewDistance(entry.cutShortId)
          setShaderParameter(getChildAt(entry.cutShortId, 0), "alphaBlendStartEnd", viewDistance - 5, viewDistance, 0, 0, true)
        end
        if entry.cutLongId ~= 0 and 0 < getNumOfChildren(entry.cutLongId) then
          local viewDistance = getFoliageViewDistance(entry.cutLongId)
          setShaderParameter(getChildAt(entry.cutLongId, 0), "alphaBlendStartEnd", viewDistance - 5, viewDistance, 0, 0, true)
        end
        if entry.windrowId ~= 0 and 0 < getNumOfChildren(entry.windrowId) then
          local viewDistance = getFoliageViewDistance(entry.windrowId)
          setShaderParameter(getChildAt(entry.windrowId, 0), "alphaBlendStartEnd", viewDistance - 5, viewDistance, 0, 0, true)
        end
        if entry.id ~= 0 or entry.cutShortId ~= 0 or entry.cutLongId ~= 0 or entry.windrowId ~= 0 then
          self.fruits[fruitType.index] = entry
          table.insert(self.fruitsList, entry)
        end
      end
      self.grassId = self:loadFoliageLayer("shortGrass", -7, -2)
      self.stonesId = self:loadFoliageLayer("stones", -7, -2)
      self.bushesId = self:loadFoliageLayer("bushes", -7, -2)
      self.normalGrassId = self:loadFoliageLayer("normalGrass", -7, -2)
      self.cultivatorChannel = 0
      self.ploughChannel = 1
      self.sowingChannel = 2
      self.sprayChannel = 3
      self.numCutLongChannels = 2
      self.maxCutLongValue = 3
      self.numWindrowChannels = 2
      self.maxWindrowValue = 3
      self.maxFruitValue = 4
      self.windrowCutLongRatio = 4
    end
  end
  return node
end
function FSBaseMission:loadFoliageLayer(name, startBlendDiff, endBlendDiff)
  local id = getChild(self.terrainRootNode, name)
  if id ~= 0 then
    local viewDistance = getFoliageViewDistance(id)
    if 0 < getNumOfChildren(id) then
      setShaderParameter(getChildAt(id, 0), "fadeStartEnd", viewDistance + startBlendDiff, viewDistance + endBlendDiff, 0, 0, true)
    end
    table.insert(self.dynamicFoliageLayers, id)
  end
  return id
end
function FSBaseMission:addOnCreateLoadedObject(object)
  if table.getn(self.users) > 1 then
    print("Error: addOnCreateLoadedObject is only allowed during map loading when no client is connected")
    printCallstack()
    return
  end
  return FSBaseMission:superClass().addOnCreateLoadedObject(self, object)
end
function FSBaseMission:addTipTrigger(tipTrigger)
  self.tipTriggers[tipTrigger] = tipTrigger
end
function FSBaseMission:removeTipTrigger(tipTrigger)
  self.tipTriggers[tipTrigger] = nil
end
function FSBaseMission:mouseEvent(posX, posY, isDown, isUp, button)
  FSBaseMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
  if self.isRunning and g_gui.currentGui == nil then
    self.missionPDA:mouseEvent(posX, posY, isDown, isUp, button)
  end
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameIcon:mouseEvent(posX, posY, isDown, isUp, button)
end
function FSBaseMission:keyEvent(unicode, sym, modifier, isDown)
  FSBaseMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  if self.isRunning and g_gui.currentGui == nil then
    self.missionPDA:keyEvent(unicode, sym, modifier, isDown)
    if g_flightAndNoHUDKeysEnabled and sym == Input.KEY_o and isDown then
      local showGUI = not self.showHudEnv
      self.showHudEnv = showGUI
      self.allowShowWeatherForecast = self.showWeatherForecast or self.allowShowWeatherForecast
      self.allowRenderTime = self.renderTime or self.allowRenderTime
      self.allowShowVehicleInfo = self.showVehicleInfo or self.allowShowVehicleInfo
      self.allowHelpText = g_settingsHelpText or self.allowHelpText
      self.showWeatherForecast = showGUI and self.allowShowWeatherForecast
      g_settingsHelpText = showGUI and self.allowHelpText
      self.renderTime = showGUI and self.allowRenderTime
      self.showVehicleInfo = showGUI and self.allowShowVehicleInfo
      self.showHudMissionBase = showGUI
    end
  end
end
function FSBaseMission:update(dt)
  FSBaseMission:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  self.inGameIcon:update(dt)
  if not self.isRunning then
    return
  end
  if table.getn(self.playersToAccept) > 0 then
    if self.missionDynamicInfo.autoAccept then
      self:onConnectionDenyAccept(self.playersToAccept[1].connection, false, false)
    elseif self:getCanAcceptPlayers() then
      g_denyAcceptDialog:setCallbacks(self.onConnectionDenyAccept, self)
      g_denyAcceptDialog:setConnection(self.playersToAccept[1].connection, self.playersToAccept[1].nickname)
      g_gui:showGui("DenyAcceptDialog")
    end
  end
  self.missionStats:update(dt)
  self.missionPDA:update(dt)
  if self:getIsServer() then
    for i = 2, table.getn(self.users) do
      if self.users[i].updateSendTime < self.time and self.users[i].state == FSBaseMission.USER_STATE_CONNECTED then
        if self.users[i].money ~= self.users[i].moneySent then
          self.users[i].moneySent = self.users[i].money
          self.users[i].connection:sendEvent(MoneyEvent:new(self.users[i].money))
        end
        if self.users[i].siloAmountsSent == nil then
          self.users[i].siloAmountsSent = {}
        end
        local siloAmountsSent = self.users[i].siloAmountsSent
        for fillType, amount in pairs(self.missionStats.farmSiloAmounts) do
          if siloAmountsSent[fillType] ~= amount then
            self.users[i].connection:sendEvent(BaseMissionSetFruitAmount:new(fillType, amount))
            siloAmountsSent[fillType] = amount
          end
        end
        self.users[i].updateSendTime = self.time + 500
      end
    end
    if self.cowIncomeTime <= self.time then
      local numCows = AnimalHusbandry.getNumberOfAnimals()
      if 0 < numCows then
        local dayToInterval = self.cowIncomeInterval / 86400000
        local difficultyMultiplier = 2 ^ (3 - self.missionStats.difficulty)
        local difficultyUsageMultiplier = Utils.lerp(0.6, 1, (self.missionStats.difficulty - 1) / 2)
        local grass = self:getSiloAmount(Fillable.FILLTYPE_GRASS)
        local dryGrass = self:getSiloAmount(Fillable.FILLTYPE_DRYGRASS)
        local chaff = self:getSiloAmount(Fillable.FILLTYPE_CHAFF)
        local totalGrass = grass + dryGrass
        local grassNeeded = numCows * g_grassPerCowPerDay * dayToInterval * difficultyUsageMultiplier
        local chaffNeeded = numCows * g_chaffPerCowPerDay * dayToInterval * difficultyUsageMultiplier
        local grassMultiplier = math.min(totalGrass / grassNeeded, 1)
        local chaffMultiplier = math.min(chaff / chaffNeeded, 1)
        local grassChaffMultiplier = grassMultiplier + chaffMultiplier
        local newMilk = difficultyMultiplier * grassChaffMultiplier * numCows * g_milkLitersPerCowPerDay * dayToInterval
        if 0 < newMilk then
          self:setSiloAmount(Fillable.FILLTYPE_MILK, self:getSiloAmount(Fillable.FILLTYPE_MILK) + newMilk)
        end
        local newLiquidManure = difficultyMultiplier * numCows * g_liquidManureLitersPerCowPerDay * dayToInterval
        self:setSiloAmount(Fillable.FILLTYPE_LIQUIDMANURE, self:getSiloAmount(Fillable.FILLTYPE_LIQUIDMANURE) + newLiquidManure)
        local newManure = difficultyMultiplier * numCows * g_manureLitersPerCowPerDay * dayToInterval
        self:setSiloAmount(Fillable.FILLTYPE_MANURE, self:getSiloAmount(Fillable.FILLTYPE_MANURE) + newManure)
        local grassUsage = math.min(grassNeeded, grass)
        if 0 < grassUsage then
          self:setSiloAmount(Fillable.FILLTYPE_GRASS, grass - grassUsage)
        end
        if grassNeeded > grassUsage then
          local dryGrassUsage = math.min(grassNeeded - grassUsage, dryGrass)
          if 0 < dryGrassUsage then
            self:setSiloAmount(Fillable.FILLTYPE_DRYGRASS, dryGrass - dryGrassUsage)
          end
        end
        local chaffUsage = math.min(chaffNeeded, chaff)
        if 0 < chaffUsage then
          self:setSiloAmount(Fillable.FILLTYPE_CHAFF, chaff - chaffUsage)
        end
      end
      self.cowIncomeTime = self.cowIncomeTime + self.cowIncomeInterval
    end
  end
  if self:getIsClient() and g_gui.currentGui == nil then
    if self.missionDynamicInfo.isMultiplayer then
      if InputBinding.hasEvent(InputBinding.CHAT) then
        g_gui:showGui("ChatDialog")
      end
      if InputBinding.hasEvent(InputBinding.BANK) then
        g_gui:showGui("MoneyScreen")
      end
      if InputBinding.hasEvent(InputBinding.TOGGLE_ADMIN) and self:getIsServer() then
        g_gui:showGui("AdminGameScreen")
      end
    end
    if InputBinding.hasEvent(InputBinding.MENU, true) then
      g_gui:showGui("InGameMenu")
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_STORE) and not g_isDemo and self.player ~= nil and not self.player.isFrozen then
      g_gui:showGui("ShopScreen")
    end
  end
end
function FSBaseMission:draw()
  FSBaseMission:superClass().draw(self)
  if self.paused and g_gui.currentGui == nil then
    local percentageStr = ""
    if self:getIsServer() then
      local percentage = 0
      local numSendingEvents = 0
      for _, event in pairs(self.sendingDensityMapEvents) do
        numSendingEvents = numSendingEvents + 1
        percentage = percentage + (event.percentage * self.densityMapPercentageFraction + (1 - self.densityMapPercentageFraction))
      end
      if 0 < numSendingEvents then
        percentage = percentage / numSendingEvents
      end
      percentageStr = " " .. math.floor(percentage * 100) .. "%"
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(0.5, 0.5, 0.04, g_i18n:getText("Waiting_for_data") .. percentageStr)
    setTextAlignment(RenderText.ALIGN_LEFT)
  end
  if self.isRunning and g_gui.currentGui == nil then
    if self.showHudEnv then
      self.hudBaseOverlay:render()
    end
    if self.showHudMissionBase then
      self.hudMissionBaseOverlay:render()
    end
    if self.fruitOverlayFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      local overlay = self.fruitOverlays[self.fruitOverlayFruitType]
      if overlay ~= nil then
        overlay:render()
      end
    end
    self.fruitOverlayFruitType = FruitUtil.FRUITTYPE_UNKNOWN
    self.missionPDA:draw()
    if self.environment ~= nil then
      if self.renderTime then
        setTextColor(1, 1, 1, 1)
        self:drawTime(false, self.environment.dayTime / 3600000)
      end
      if self.showWeatherForecast and self.environment.timeUntilNextRain ~= nil then
        if self.environment.timeUntilNextRain < 720 then
          if self.environment.nextRainType == 1 then
            self.hudBaseHailOverlay:render()
          else
            self.hudBaseRainOverlay:render()
          end
        else
          self.hudBaseSunOverlay:render()
        end
      end
    end
  end
  self.inGameMessage:draw()
  self.inGameIcon:draw()
end
function FSBaseMission:getCanAcceptPlayers()
  return g_gui.currentGui == nil
end
function FSBaseMission:drawMissionCompleted()
  if self.missionFailedOverlayId == nil then
    self.missionCompletedOverlayId = createImageOverlay("dataS2/missions/mission_completed.png")
  end
  renderOverlay(self.missionCompletedOverlayId, self.completeDisplayX, self.completeDisplayY, self.completeDisplayWidth, self.completeDisplayHeight)
  if self.medalOverlay ~= nil then
    self.medalOverlay:render()
  end
  local timePosX = self.completeDisplayX + self.completeDisplayWidth * 0.275
  local timePosY = self.completeDisplayY + self.completeDisplayHeight * 0.25
  setTextBold(true)
  local time = self.record / 60000
  local timeHours = math.floor(time)
  local timeMinutes = math.floor((time - timeHours) * 60)
  renderText(timePosX, timePosY, 0.045, g_i18n:getText("Time") .. string.format(": %02d:%02d", timeHours, timeMinutes))
  setTextAlignment(RenderText.ALIGN_CENTER)
  renderText(0.5, 0.41, 0.045, g_i18n:getText("missionAccomplished"))
  setTextAlignment(RenderText.ALIGN_LEFT)
  setTextBold(false)
end
function FSBaseMission:drawMissionFailed()
  if self.missionFailedOverlayId == nil then
    self.missionFailedOverlayId = createImageOverlay("dataS2/missions/mission_failed.png")
  end
  self:drawCentered(self.missionFailedOverlayId, 0.5, 0.175)
  setTextBold(true)
  setTextAlignment(RenderText.ALIGN_CENTER)
  renderText(0.5, 0.48, 0.04, g_i18n:getText("missionFailed"))
  setTextAlignment(RenderText.ALIGN_LEFT)
  setTextBold(false)
end
function FSBaseMission:drawCentered(overlayId, width, height)
  renderOverlay(overlayId, 0.5 - width / 2, 0.5 - height / 2, width, height)
end
function FSBaseMission:setFruitOverlayFruitType(fruitType)
  self.fruitOverlayFruitType = fruitType
end
function FSBaseMission:finishMission(record)
  if g_finishedMissions[self.missionInfo.missionId] == nil then
    g_finishedMissions[self.missionInfo.missionId] = 1
  end
  if g_finishedMissionsRecord[self.missionInfo.missionId] == nil or record < g_finishedMissionsRecord[self.missionInfo.missionId] then
    g_finishedMissionsRecord[self.missionInfo.missionId] = record
  end
  local finishedStr = ""
  local recordStr = ""
  for k, v in pairs(g_finishedMissions) do
    finishedStr = finishedStr .. k .. " "
    recordStr = recordStr .. math.floor(g_finishedMissionsRecord[k]) .. " "
  end
  setXMLString(g_savegameXML, "savegames.missions#finished", finishedStr)
  setXMLString(g_savegameXML, "savegames.missions#record", recordStr)
  saveXMLFile(g_savegameXML)
  local medalPosX = self.completeDisplayX + self.completeDisplayWidth * 0.295
  local medalPosY = self.completeDisplayY + self.completeDisplayHeight * 0.38
  local medalHeight = 0.204
  self.record = record
  local recordFloor = math.floor(record)
  local timeMinutesF = record / 60000
  local timeMinutes = math.floor(timeMinutesF)
  local timeSeconds = math.floor((timeMinutesF - timeMinutes) * 60)
  local recordFloor = (timeSeconds + 60 * timeMinutes) * 1000
  local filename = "dataS2/missions/empty_medal.png"
  if recordFloor <= self.missionInfo.bronzeTime * 1000 then
    filename = "dataS2/missions/bronze_medal.png"
  end
  if recordFloor <= self.missionInfo.silverTime * 1000 then
    filename = "dataS2/missions/silver_medal.png"
  end
  if recordFloor <= self.missionInfo.goldTime * 1000 then
    filename = "dataS2/missions/gold_medal.png"
  end
  self.medalOverlay = Overlay:new("emptyMedalOverlay", filename, medalPosX, medalPosY, medalHeight * 0.75, medalHeight)
end
function FSBaseMission:onSunkVehicle(vehicle)
  FSBaseMission:superClass().onSunkVehicle(self, vehicle)
  if not self.isFreePlayMission then
    self.sunk = true
  end
end
function FSBaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
  FSBaseMission:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
  self.minTime = self.missionInfo.bronzeTime
  self.missionStats:setMissionInfo(self.missionInfo, self.missionDynamicInfo)
  self:updateMaxNumHirables()
  self.milkProductionScale = self.missionInfo.milkProductionScale
  self.milkPriceScale = self.missionInfo.milkPriceScale
  self.manureProductionScale = self.missionInfo.manureProductionScale
end
function FSBaseMission:updateMaxNumHirables()
  if self.missionDynamicInfo.isMultiplayer then
    if self.missionDynamicInfo.capacity ~= nil then
      self.maxNumHirables = self.missionDynamicInfo.capacity
    end
  else
    self.maxNumHirables = 10
  end
end
function FSBaseMission:addSiloAmountListener(listener, fillType)
  local listeners = self.siloAmountListeners[fillType]
  if listeners == nil then
    listeners = {}
    self.siloAmountListeners[fillType] = listeners
  end
  listeners[listener] = listener
end
function FSBaseMission:removeSiloAmountListener(listener, fillType)
  local listeners = self.siloAmountListeners[fillType]
  if listeners ~= nil then
    listeners[listener] = nil
  end
end
function FSBaseMission:getSiloAmount(fillType)
  return Utils.getNoNil(self.missionStats.farmSiloAmounts[fillType], 0)
end
function FSBaseMission:setSiloAmount(fillType, amount)
  if self:getIsServer() then
    self:setSiloAmountInternal(fillType, amount)
  else
    print("Error: FSBaseMission:setSiloAmount is only allowed on a server")
  end
end
function FSBaseMission:setSiloAmountInternal(fillType, amount)
  self.missionStats.farmSiloAmounts[fillType] = amount
  local listeners = self.siloAmountListeners[fillType]
  if listeners ~= nil then
    for listener in pairs(listeners) do
      listener:onSiloAmountChanged(fillType, amount)
    end
  end
end
function FSBaseMission:addSharedMoney(amount)
  if self:getIsServer() then
    if not self.allowClientsOwnMoney then
      self.missionStats.money = self.missionStats.money + amount
    else
      local amountPerUser = amount / table.getn(self.users)
      self.missionStats.money = self.missionStats.money + amountPerUser
      for i = 2, table.getn(self.users) do
        self.users[i].money = self.users[i].money + amountPerUser
      end
    end
  else
    print("Error: FSBaseMission:addSharedMoney is only allowed on a server")
  end
end
function FSBaseMission:addMoney(amount, userId)
  if self:getIsServer() then
    local user = self:findUserByUserId(userId)
    if userId == 1 or user == nil or not self.allowClientsOwnMoney then
      self.missionStats.money = self.missionStats.money + amount
    else
      user.money = user.money + amount
      user.moneySent = user.money
      user.connection:sendEvent(MoneyEvent:new(user.money))
    end
  else
    print("Error: FSBaseMission:addMoney is only allowed on a server")
  end
end
function FSBaseMission:getMoney(userId)
  if self:getIsServer() then
    local user = self:findUserByUserId(userId)
    if user ~= nil then
      if userId == 1 then
        return self.missionStats.money
      else
        return user.money
      end
    else
      return 0
    end
  else
    print("Error: FSBaseMission:getMoney is only allowed on a server")
  end
end
function FSBaseMission:setAllowClientsOwnMoney(allow)
  self.allowClientsOwnMoney = allow
  if not allow then
    for i = 2, table.getn(self.users) do
      self.missionStats.money = self.missionStats.money + self.users[i].money
      self.users[i].money = 0
    end
  end
end
function FSBaseMission:getTerrainDetailPixelsToSqm()
  local f = self.terrainSize / self.terrainDetailMapSize
  return f * f
end
function FSBaseMission:getFruitPixelsToSqm()
  local f = self.terrainSize / self.fruitMapSize
  return f * f
end
function FSBaseMission:sendNumPlayersToMasterServer(numPlayers)
  masterServerSetNumPlayers(numPlayers)
end
function FSBaseMission:onDayChanged()
  if self:getIsServer() and self.lastMilkPickupDay < self.environment.currentDay - 1 then
    local milk = self:getSiloAmount(Fillable.FILLTYPE_MILK)
    if 0 < milk then
      self:addSharedMoney(g_milkPricePerLiter * milk)
      self:setSiloAmount(Fillable.FILLTYPE_MILK, 0)
    end
  end
end
function FSBaseMission:onPickupMilk()
  local milk = self:getSiloAmount(Fillable.FILLTYPE_MILK)
  if 0 < milk then
    self:addSharedMoney(g_milkPricePerLiter * milk)
    self:setSiloAmount(Fillable.FILLTYPE_MILK, 0)
  end
  self.lastMilkPickupDay = self.environment.currentDay
end
function FSBaseMission:onCowUsedMilkingPlace()
  self:setSiloAmount(Fillable.FILLTYPE_MILK, self:getSiloAmount(Fillable.FILLTYPE_MILK) + g_milkingPlaceMilkPerCow)
end
function FSBaseMission:increaseReputation(value)
  local wasNot100 = self.reputation < 100
  self.reputation = self.reputation + value
  if self.inGameIcon ~= nil and wasNot100 then
    if self.inGameIcon.fileName ~= "dataS2/missions/repmedal.png" then
      self.inGameIcon:setIcon("dataS2/missions/repmedal.png")
    end
    self.inGameIcon:setText("+" .. value .. "%")
    self.inGameIcon:showIcon(2000)
  end
  if self.reputation >= 100 then
    self.reputation = 100
  end
end
function FSBaseMission:infospotTouched(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages ~= nil and self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end
function FSBaseMission:loadMessages(filePath)
  self.messages = {}
  local xmlFile = loadXMLFile("messages", filePath)
  local eom = false
  local i = 0
  repeat
    local message = {}
    local baseXMLName = string.format("messages.message(%d)", i)
    message.id = getXMLInt(xmlFile, baseXMLName .. "#id")
    if message.id ~= nil then
      message.title = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "title", "", self.customEnvironment, true)
      message.content = Utils.getXMLI18NValue(xmlFile, baseXMLName, getXMLString, "content", "", self.customEnvironment, true)
      message.duration = getXMLInt(xmlFile, baseXMLName .. ".duration")
      self.messages[message.id] = message
    else
      eom = true
    end
    i = i + 1
  until eom
  delete(xmlFile)
end
function FSBaseMission:setMilkAndManureScales(milkScale, milkPriceScale, manureScale)
  self.milkPriceScale = milkPriceScale
  self.milkProductionScale = milkScale
  self.manureProductionScale = manureScale
  g_milkPricePerLiter = g_originalMilkPricePerLiter * milkPriceScale
  g_milkLitersPerCowPerDay = g_originalMilkLitersPerCowPerDay * milkScale
  g_milkingPlaceMilkPerCow = g_originalMilkingPlaceMilkPerCow * milkScale
  g_liquidManureLitersPerCowPerDay = g_originalLiquidManureLitersPerCowPerDay * manureScale
  g_manureLitersPerCowPerDay = g_originalManureLitersPerCowPerDay * manureScale
end
function FSBaseMission:consoleCommandCheatMoney()
  if g_isDevelopmentVersion and self:getIsServer() then
    local num = 1000000
    self:addSharedMoney(num)
    return "Add money " .. num
  end
end
function FSBaseMission:consoleCommandCheatSilo(fillType, amount)
  if g_isDevelopmentVersion and self:getIsServer() then
    amount = tonumber(amount)
    if fillType == nil or amount == nil then
      return "Invalid arguments. Arguments: fillType amount"
    end
    local fillTypeInt = Fillable.fillTypeNameToInt[fillType]
    if fillTypeInt == nil then
      return "Invalid fillType " .. fillType
    end
    self:setSiloAmount(fillTypeInt, math.max(self:getSiloAmount(fillTypeInt) + amount, 0))
    return "Silo Amount(" .. fillType .. ") = " .. self:getSiloAmount(fillTypeInt)
  end
end
function FSBaseMission:consoleCommandCheatFeedingTrough(amount)
  if g_isDevelopmentVersion and self:getIsServer() then
    amount = tonumber(amount)
    if amount == nil then
      return "Invalid argument. Argument: amount"
    end
    fillTypeInt = Fillable.FILLTYPE_GRASS
    self:setSiloAmount(fillTypeInt, math.max(self:getSiloAmount(fillTypeInt) + amount, 0))
    return "Feeding Trough Fill Level = " .. self:getSiloAmount(fillTypeInt)
  end
end
function FSBaseMission:consoleCommandSetMilkDifficulty(difficulty)
  if self:getIsServer() then
    local difficulty = tonumber(difficulty)
    if difficulty == nil or difficulty < 1 or 3 < difficulty then
      return "Invalid argument. Argument: level [1,2,3,4]"
    end
    difficulty = math.floor(difficulty)
    local milkScale = 1
    local milkPriceScale = 1
    local manureScale = 1
    if difficulty == 2 then
      milkScale = 0.5
      milkPriceScale = 0.5
      manureScale = 0.75
    elseif difficulty == 3 then
      milkScale = 0.2
      milkPriceScale = 0.32
      manureScale = 0.5
    elseif difficulty == 4 then
      milkScale = 0.1
      milkPriceScale = 0.32
      manureScale = 0.25
    end
    self:setMilkAndManureScales(milkScale, milkPriceScale, manureScale)
    return "Milk Difficulty = " .. difficulty .. ". Milk production = " .. math.floor(milkScale * 100) .. "%. Milk price = " .. math.floor(milkPriceScale * 100) .. "%. Manure production = " .. math.floor(manureScale * 100) .. "%."
  end
end
