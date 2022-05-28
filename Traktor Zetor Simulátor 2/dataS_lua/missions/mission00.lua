Mission00 = {}
local Mission00_mt = Class(Mission00, FSBaseMission)
function Mission00:new(baseDirectory, customMt)
  local mt = customMt
  if mt == nil then
    mt = Mission00_mt
  end
  local self = Mission00:superClass():new(baseDirectory, mt)
  self.renderTime = true
  self.isFreePlayMission = true
  self.vehiclesToSpawn = {}
  self.foundBottleCount = 0
  self.deliveredBottles = 0
  self.foundBottles = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  self.foundInfoTriggers = "00000000000000000000"
  self.missionMapBottleTriggers = {}
  self.missionMapGlassContainerTriggers = {}
  self.disableCombineAI = false
  self.disableTractorAI = false
  self.messages = {}
  self.chatMessages = {}
  self.autoSaveTime = 0
  self.autoSaveInterval = 900000
  g_mission00StartPoint = nil
  return self
end
function Mission00:delete()
  removeConsoleCommand("gsAutoSaveInterval")
  removeConsoleCommand("gsAutoSave")
  delete(self.bottlePickupSound)
  delete(self.bottleDropSound)
  for i = 1, table.getn(self.missionMapBottleTriggers) do
    removeTrigger(self.missionMapBottleTriggers[i])
  end
  for i = 1, table.getn(self.missionMapGlassContainerTriggers) do
    removeTrigger(self.missionMapGlassContainerTriggers[i])
  end
  Mission00:superClass().delete(self)
end
function Mission00:load()
  self.environment.timeScale = self.missionStats.timeScale
  self.showWeatherForecast = true
  self.bottlePickupSound = createSample("bottlePickupSound")
  loadSample(self.bottlePickupSound, "data/maps/sounds/bottlePickupSound.wav", false)
  self.bottleDropSound = createSample("bottleDropSound")
  loadSample(self.bottleDropSound, "data/maps/sounds/bottleDropSound.wav", false)
  self:loadMessages("dataS/missions/messages_career.xml")
  if self.missionInfo.vehiclesXMLLoad ~= nil then
    self:loadVehicles(self.missionInfo.vehiclesXMLLoad, self.missionInfo.resetVehicles)
  end
  self.environment.dayTime = self.missionInfo.dayTime * 1000 * 60
  if self.missionInfo.nextRainValid then
    self.environment.timeUntilNextRain = self.missionInfo.timeUntilNextRain
    self.environment.timeUntilRainAfterNext = self.missionInfo.timeUntilRainAfterNext
    self.environment.rainTime = self.missionInfo.rainTime
    self.environment.nextRainDuration = self.missionInfo.nextRainDuration
    self.environment.nextRainType = self.missionInfo.nextRainType
    self.environment.rainTypeAfterNext = self.missionInfo.rainTypeAfterNext
  end
  self.environment.currentDay = self.missionInfo.currentDay
  self.foundBottleCount = self.missionInfo.foundBottleCount
  self.deliveredBottles = self.missionInfo.deliveredBottles
  self.foundBottles = self.missionInfo.foundBottles
  self.sessionDeliveredBottles = 0
  self.reputation = self.missionInfo.reputation
  self.foundInfoTriggers = self.missionInfo.foundInfoTriggers
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    local desc = FruitUtil.fruitIndexToDesc[i]
    desc.pricePerLiter = Utils.getNoNil(self.missionInfo.fruitPrices[desc.name], desc.pricePerLiter)
    desc.yesterdaysPrice = Utils.getNoNil(self.missionInfo.yesterdaysFruitPrices[desc.name], desc.yesterdaysPrice)
  end
  if g_mission00StartPoint ~= nil then
    local x, y, z = getTranslation(g_mission00StartPoint)
    local dirX, dirY, dirZ = localDirectionToWorld(g_mission00StartPoint, 0, 0, -1)
    self.playerStartX = x
    self.playerStartY = y
    self.playerStartZ = z
    self.playerRotX = 0
    self.playerRotY = Utils.getYRotationFromDirection(dirX, dirZ)
    self.playerStartIsAbsolute = true
  end
  Mission00:superClass().load(self)
  if self:getIsServer() then
    self:loadMilktruck()
  end
  if self:getIsServer() then
    addConsoleCommand("gsAutoSave", "Enables/disables auto save", "consoleCommandAutoSave", self)
    addConsoleCommand("gsAutoSaveInterval", "Sets the auto save interval", "consoleCommandAutoSaveInterval", self)
  end
end
function Mission00:loadMilktruck()
  if self:getIsServer() then
    local milktruckFilename = "data/vehicles/trucks/milktruck.xml"
    local xmlFile = loadXMLFile("TempConfig", milktruckFilename)
    local spawnTestRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spawnTest#radius"), 15)
    delete(xmlFile)
    local spawnTestInterval = 1000
    local sequence, loopIndex = RoadUtil.getRandomRoadSequence(nil, "milkTruck1Indices", "milkTruck1Directions")
    if sequence ~= nil then
      table.insert(self.trafficVehiclesToSpawn, {
        filename = milktruckFilename,
        spawnTestNextTime = 0,
        spawnTestRadius = spawnTestRadius,
        spawnTestInterval = spawnTestInterval,
        sequence = sequence,
        loopIndex = loopIndex
      })
    end
  end
end
function Mission00:mouseEvent(posX, posY, isDown, isUp, button)
  Mission00:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function Mission00:keyEvent(unicode, sym, modifier, isDown)
  Mission00:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function Mission00:update(dt)
  if self.firstTimeRun and self:getIsServer() then
    local numToSpawn = table.getn(self.vehiclesToSpawn)
    if 0 < numToSpawn then
      local xmlFile = loadXMLFile("VehiclesXML", self.missionInfo.vehiclesXMLLoad)
      for i = 1, numToSpawn do
        local key = self.vehiclesToSpawn[i].xmlKey
        local filename = getXMLString(xmlFile, key .. "#filename")
        if filename ~= nil then
          filename = Utils.convertFromNetworkFilename(filename)
          local vehicle = self:loadVehicle(filename, 0, 0, 0, 0)
          if vehicle ~= nil then
            local r = vehicle:loadFromAttributesAndNodes(xmlFile, key, true)
            if r ~= BaseMission.VEHICLE_LOAD_OK then
              print("Warning: corrupt savegame, vehicle " .. filename .. " could not be loaded")
              self:removeVehicle(vehicle)
            end
          end
        end
      end
      delete(xmlFile)
      self.vehiclesToSpawn = {}
      self.usedLoadPlaces = {}
    end
  end
  Mission00:superClass().update(self, dt)
  if self.environment.dayTime > 72000000 or self.environment.dayTime < 21600000 then
    self.environment.timeScale = g_currentMission.missionStats.timeScale * 4
  else
    self.environment.timeScale = g_currentMission.missionStats.timeScale
  end
  if self:getIsServer() and self.missionDynamicInfo.autoSave and self.autoSaveTime <= self.time then
    g_careerScreen:saveSelectedGame()
    self.autoSaveTime = self.time + self.autoSaveInterval
  end
end
function Mission00:draw()
  Mission00:superClass().draw(self)
  setTextWrapWidth(0.5)
  setTextBold(false)
  if table.getn(self.chatMessages) > 0 and g_currentMission.time - self.lastChatMessageTime < 10000 and (g_gui.currentGui == nil or g_gui.currentGuiName == "ChatDialog") then
    local currentLine = -1
    for i = table.getn(self.chatMessages), 1, -1 do
      local text = self.chatMessages[i].sender .. ": " .. self.chatMessages[i].msg
      local height, numLines = getTextHeight(0.025, text)
      currentLine = currentLine + numLines
      if 5 <= currentLine then
        break
      end
      setTextColor(0, 0, 0, 0.75)
      renderText(0.025, 0.4 + currentLine * 1.1 * 0.025 - 0.0013, 0.025, text)
      setTextColor(1, 1, 1, 1)
      renderText(0.025, 0.4 + currentLine * 1.1 * 0.025, 0.025, text)
    end
  end
  setTextWrapWidth(0)
end
function Mission00:loadVehicles(xmlFilename, resetVehicles)
  if self:getIsServer() then
    local xmlFile = loadXMLFile("VehiclesXML", xmlFilename)
    local vehicleI = 0
    while true do
      local key = string.format("careerVehicles.vehicle(%d)", vehicleI)
      if not hasXMLProperty(xmlFile, key) then
        break
      end
      local filename = getXMLString(xmlFile, key .. "#filename")
      if filename ~= nil then
        filename = Utils.convertFromNetworkFilename(filename)
        local vehicle = self:loadVehicle(filename, 0, 0, 0, 0)
        if vehicle ~= nil then
          local r = vehicle:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
          if r == BaseMission.VEHICLE_LOAD_ERROR then
            print("Warning: corrupt savegame, vehicle " .. filename .. " could not be loaded")
            self:removeVehicle(vehicle)
          elseif r == BaseMission.VEHICLE_LOAD_DELAYED then
            table.insert(self.vehiclesToSpawn, {xmlKey = key})
            self:removeVehicle(vehicle)
          end
        end
      end
      vehicleI = vehicleI + 1
    end
    local i = 0
    while true do
      local key = string.format("careerVehicles.item(%d)", i)
      local className = getXMLString(xmlFile, key .. "#className")
      if className == nil then
        break
      end
      if className:find("[^%w_.]") ~= nil then
        print("Error: Corrupt savegame, item " .. i .. " has invalid className '" .. className .. "'")
      else
        local callString = "g_asd_tempItemClass = " .. className
        loadstring(callString)()
        local itemClass = g_asd_tempItemClass
        g_asd_tempItemClass = nil
        if itemClass ~= nil then
          local item = itemClass:new(self:getIsServer(), self:getIsClient())
          if item:loadFromAttributesAndNodes(xmlFile, key) then
            item:register()
            self:addItemToSave(item)
          else
            print("Warning: corrupt savegame, item " .. i .. " with className " .. className .. " could not be loaded")
          end
        end
      end
      i = i + 1
    end
    delete(xmlFile)
  end
end
function Mission00:saveVehicles(file)
  for _, vehicle in pairs(self.vehicles) do
    if vehicle.isVehicleSaved then
      file:write("    <vehicle filename=\"" .. Utils.encodeToHTML(Utils.convertToNetworkFilename(vehicle.configFileName)) .. "\"")
      local attributes, nodes = vehicle:getSaveAttributesAndNodes("       ")
      if attributes ~= nil and attributes ~= "" then
        file:write(" " .. attributes)
      end
      if nodes ~= nil and nodes ~= "" then
        file:write(">\n" .. nodes .. [[

    </vehicle>
]])
      else
        file:write("/>\n")
      end
    end
  end
  for _, item in pairs(self.itemsToSave) do
    file:write("    <item className=\"" .. item.className .. "\"")
    local attributes, nodes = item.item:getSaveAttributesAndNodes("       ")
    if attributes ~= nil and attributes ~= "" then
      file:write(" " .. attributes)
    end
    if nodes ~= nil and nodes ~= "" then
      file:write(">\n" .. nodes .. [[

    </item>
]])
    else
      file:write("/>\n")
    end
  end
end
function Mission00:loadInfoTriggers(filename)
  self.missionMapInfo = self:loadMap(filename)
  local missionMapInfoTriggers = {}
  local infoTriggerParentId = getChild(self.missionMapInfo, "infoCheckpoints")
  if infoTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(infoTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(infoTriggerParentId, i)
      id = getChildAt(id, 0)
      missionMapInfoTriggers[i + 1] = id
    end
  end
  for i = 1, string.len(self.foundInfoTriggers) do
    if string.sub(self.foundInfoTriggers, i, i) == "1" then
      local triggerId = missionMapInfoTriggers[i]
      if triggerId ~= nil then
        removeTrigger(triggerId)
        local parentId = getParent(triggerId)
        setVisibility(parentId, false)
      end
    end
  end
end
function Mission00:loadCollectableBottles(filename)
  self.missionMapBottles = self:loadMap(filename)
  local bottleTriggerParentId = getChild(self.missionMapBottles, "collectableBottles")
  if bottleTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(bottleTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(bottleTriggerParentId, i)
      id = getChildAt(id, 0)
      addTrigger(id, "bottleTriggerCallback", self)
      self.missionMapBottleTriggers[i + 1] = id
    end
  end
  for i = 1, string.len(self.foundBottles) do
    if string.sub(self.foundBottles, i, i) == "1" then
      local triggerId = self.missionMapBottleTriggers[i]
      removeTrigger(triggerId)
      local parentId = getParent(triggerId)
      delete(triggerId)
      setVisibility(parentId, false)
    end
  end
end
function Mission00:loadGlassContainers(filename)
  self.missionMapGlassContainers = self:loadMap(filename)
  local glassContainerTriggerParentId = getChild(self.missionMapGlassContainers, "glassContainers")
  if glassContainerTriggerParentId ~= 0 then
    local numChildren = getNumOfChildren(glassContainerTriggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(glassContainerTriggerParentId, i)
      id = getChildAt(id, 0)
      addTrigger(id, "glassContainerTriggerCallback", self)
      self.missionMapGlassContainerTriggers[i + 1] = id
    end
  end
end
function Mission00:bottleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.controlPlayer and self.player ~= nil and otherId == self.player.rootNode then
    removeTrigger(triggerId)
    local bottleName = getName(triggerId)
    local bottleNumber = tonumber(string.sub(bottleName, string.len(bottleName) - 2, string.len(bottleName)))
    self.foundBottles = string.sub(self.foundBottles, 1, bottleNumber - 1) .. "1" .. string.sub(self.foundBottles, bottleNumber + 1, string.len(self.foundBottles))
    local parentId = getParent(triggerId)
    delete(triggerId)
    setVisibility(parentId, false)
    if self.inGameIcon.fileName ~= "dataS2/missions/bottle.png" then
      self.inGameIcon:setIcon("dataS2/missions/bottle.png")
    end
    self.inGameIcon:setText("+1")
    self.inGameIcon:showIcon(2000)
    if self.bottlePickupSound ~= nil then
      playSample(self.bottlePickupSound, 1, 1, 0)
    end
    self.foundBottleCount = self.foundBottleCount + 1
  end
end
function Mission00:glassContainerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.controlPlayer and self.player ~= nil and otherId == self.player.rootNode and self.foundBottleCount > 0 then
    self.missionStats.money = self.missionStats.money + self.foundBottleCount
    self.deliveredBottles = self.deliveredBottles + self.foundBottleCount
    self.sessionDeliveredBottles = self.sessionDeliveredBottles + self.foundBottleCount
    if self.bottleDropSound ~= nil then
      playSample(self.bottleDropSound, 1, 0.5, 0)
    end
    self:increaseReputation(self.foundBottleCount)
    self.foundBottleCount = 0
  end
end
function Mission00:infospotTouched(triggerId)
  Mission00:superClass().infospotTouched(self, triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  self.foundInfoTriggers = string.sub(self.foundInfoTriggers, 1, triggerNumber - 1) .. "1" .. string.sub(self.foundInfoTriggers, triggerNumber + 1)
end
function Mission00:onCreateStartPoint(id)
  g_mission00StartPoint = id
end
function Mission00:addChatMessage(sender, msg)
  self:setLastChatMessageTime()
  if table.getn(self.chatMessages) > 4 then
    table.remove(self.chatMessages, 1)
  end
  table.insert(self.chatMessages, {msg = msg, sender = sender})
end
function Mission00:setLastChatMessageTime()
  self.lastChatMessageTime = g_currentMission.time
end
function Mission00:consoleCommandAutoSaveInterval(interval)
  if self:getIsServer() then
    interval = tonumber(interval)
    if interval == nil then
      return "AutoSaveInterval = " .. string.format("%1.3f", self.autoSaveInterval / 60 / 1000) .. ". Arguments: interval[minutes]"
    end
    if interval < 1 then
      interval = 1
    end
    self.autoSaveInterval = interval * 60 * 1000
    self.autoSaveTime = self.time + self.autoSaveInterval
    return "AutoSaveInterval = " .. interval
  end
end
function Mission00:consoleCommandAutoSave(enabled)
  if self:getIsServer() then
    if enabled == nil or enabled == "" then
      return "AutoSave = " .. tostring(self.missionDynamicInfo.autoSave) .. ". Arguments: enabled[true|false]"
    end
    enabled = tostring(enabled):lower()
    if enabled == "true" then
      if not self.missionDynamicInfo.autoSave then
        self.autoSaveTime = self.time + self.autoSaveInterval
      end
      self.missionDynamicInfo.autoSave = true
    else
      self.missionDynamicInfo.autoSave = false
    end
    return "AutoSave = " .. tostring(self.missionDynamicInfo.autoSave)
  end
end
