source("dataS/scripts/VehicleRemoveEvent.lua")
source("dataS/scripts/OnCreateLoadedObjectEvent.lua")
BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.STATE_CONTINUED = 6
BaseMission.VEHICLE_LOAD_OK = 1
BaseMission.VEHICLE_LOAD_ERROR = 2
BaseMission.VEHICLE_LOAD_DELAYED = 3
BaseMission.allowPhysicsPausing = true
function BaseMission:new(baseDirectory, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, BaseMission_mt)
  end
  instance.baseDirectory = baseDirectory
  instance.physicsPaused = false
  instance.firstTimeRun = false
  instance.waterY = -200
  instance.players = {}
  instance.connectionsToPlayer = {}
  instance.updateables = {}
  instance.nonUpdateables = {}
  instance.currentTipTrigger = nil
  instance.trailerTipTriggers = {}
  instance.environment = nil
  instance.tipTriggerRangeThreshold = 1
  instance.isTipTriggerInRange = false
  instance.state = BaseMission.STATE_INTRO
  instance.endDelayTime = 5000
  instance.endTimeStamp = 0
  instance.isRunning = false
  instance.isLoaded = false
  instance.sounds = {}
  instance.controlledVehicle = nil
  instance.controlPlayer = true
  instance.storeIsActive = false
  instance.vehicles = {}
  instance.steerables = {}
  instance.objectToTrailer = {}
  instance.attachables = {}
  instance.trafficVehicles = {}
  instance.trafficVehiclesToSpawn = {}
  instance.vehiclesToDelete = {}
  instance.nodeToVehicle = {}
  instance.loadSpawnPlaces = {}
  instance.storeSpawnPlaces = {}
  instance.usedLoadPlaces = {}
  instance.vehiclesToSpawn = {}
  local trafficDensity = Utils.getNoNil(getXMLFloat(g_savegameXML, "savegames.settings.traffic#density"), 1)
  instance.maxNumTrafficVehicles = trafficDensity * (12 + Utils.getProfileClassId() * 4)
  instance.timeAtLastTrafficVehicleSpawn = 0
  instance.tafficVehicleSpawnInterval = Utils.getNoNil(getXMLFloat(g_savegameXML, "savegames.settings.traffic#spawnInterval"), 1000)
  instance.nodeObjects = {}
  instance.itemsToSave = {}
  instance.maps = {}
  instance.mountThreshold = 6
  instance.preSimulateTime = 4000
  instance.disableCombineAI = true
  instance.disableTractorAI = true
  instance.maxNumHirables = 10
  instance.time = 0
  instance.missionTime = 0
  instance.extraPrintTexts = {}
  instance.warnings = {}
  instance.warningsNumLines = {}
  instance.helpButtonTexts = {}
  instance.hudHelpBaseWidth = 0.365714
  instance.hudHelpBaseHeight = 0.121905
  instance.hudHelpBasePosX = 0.007143
  instance.hudHelpBasePosY = 1 - instance.hudHelpBaseHeight - 0.011429
  instance.hudWarningBasePosX = 0.317143
  instance.hudWarningBasePosY = 0.508571
  instance.hudWarningBaseWidth = 0.365714
  instance.hudWarningBaseHeight = 0.24381
  instance.hudHelpBaseOverlay = Overlay:new("hudHelpBaseOverlay", "dataS2/missions/hud_help_base.png", instance.hudHelpBasePosX, instance.hudHelpBasePosY, instance.hudHelpBaseWidth, instance.hudHelpBaseHeight)
  instance.hudWarningBaseOverlay = Overlay:new("hudWarningBaseOverlay", "dataS2/missions/hud_warning_base.png", instance.hudWarningBasePosX, instance.hudWarningBasePosY, instance.hudWarningBaseWidth, instance.hudWarningBaseHeight)
  instance.hudAttachmentOverlay = Overlay:new("hudAttachmentOverlay", "dataS2/missions/hud_attachment.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.hudTipperOverlay = Overlay:new("hudTipperOverlay", "dataS2/missions/hud_tipper.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.hudFuelOverlay = Overlay:new("hudFuelOverlay", "dataS2/missions/hud_fuel.png", 0.935, 0.18, 0.06, 0.07999999999999999)
  instance.showVehicleInfo = true
  instance.showHelpText = true
  instance.disableHelpTextNextFrame = false
  instance.activatableObjects = {}
  instance.activateListeners = {}
  instance.paused = false
  instance.isLoadingMap = false
  instance.onCreateLoadedObjects = {}
  instance.coinTelescopeOverlay = Overlay:new("coinTelescopeOverlay", "dataS2/missions/telescopeView.png", 0, 0, 1, 1)
  instance.telescopeActive = false
  instance.objectsToClassName = {}
  return instance
end
function BaseMission:delete()
  if self:getIsClient() and not self.controlPlayer and self.controlledVehicle ~= nil then
    self:onLeaveVehicle()
  end
  if g_server ~= nil then
    g_server:delete()
  end
  if g_client ~= nil then
    g_client:delete()
  end
  setCamera(g_defaultCamera)
  if self.player ~= nil then
    self.player:delete()
  end
  RoadUtil.delete()
  for k, v in pairs(self.vehicles) do
    v:delete()
  end
  for k, v in pairs(self.vehiclesToDelete) do
    k:delete()
  end
  for _, item in pairs(self.itemsToSave) do
    item.item:delete()
  end
  if self.environment ~= nil then
    self.environment:destroy()
    self.environment = nil
  end
  self.hudHelpBaseOverlay:delete()
  self.hudWarningBaseOverlay:delete()
  self.hudAttachmentOverlay:delete()
  self.hudTipperOverlay:delete()
  self.hudFuelOverlay:delete()
  self.coinTelescopeOverlay:delete()
  for k, v in pairs(self.updateables) do
    v:delete()
  end
  for k, v in pairs(self.nonUpdateables) do
    v:delete()
  end
  for k, v in pairs(g_modEventListeners) do
    v:deleteMap()
  end
  for k, v in pairs(self.maps) do
    delete(v)
  end
  g_currentMission = nil
end
function BaseMission:load()
  RoadUtil.init()
  self.controlPlayer = true
  self.controlledVehicle = nil
  updateAllDestructionShapeConnections()
end
function BaseMission:onObjectCreated(object)
  if object:isa(Player) then
    self.players[object.rootNode] = object
    if self:getIsServer() then
      self.connectionsToPlayer[object.creatorConnection] = object
    end
  elseif object:isa(Vehicle) then
    self:addVehicle(object)
  end
end
function BaseMission:onObjectDeleted(object)
  if object:isa(Player) then
    if self.player == object then
      self.player = nil
    end
    self.players[object.rootNode] = nil
    if self:getIsServer() then
      self.connectionsToPlayer[object.creatorConnection] = nil
    end
  elseif object:isa(Vehicle) and object.isAddedToMission then
    self:removeVehicle(object, false)
  end
end
function BaseMission:loadMap(filename, addPhysics)
  if addPhysics == nil then
    addPhysics = true
  end
  if self.missionInfo.customEnvironment ~= nil then
    _G[self.missionInfo.customEnvironment].g_onCreateUtil.activateOnCreateFunctions()
  end
  self.isLoadingMap = true
  local node = loadI3DFile(filename, addPhysics)
  if node ~= 0 then
    self:findDynamicObjects(node)
  end
  self.isLoadingMap = false
  if self.missionInfo.customEnvironment ~= nil then
    _G[self.missionInfo.customEnvironment].g_onCreateUtil.deactivateOnCreateFunctions()
  end
  if node ~= 0 then
    table.insert(self.maps, node)
    link(getRootNode(), node)
  else
    print("Error: failed to load map " .. filename)
  end
  if self.environment.water ~= nil then
    local x, y, z = getWorldTranslation(self.environment.water)
    self.waterY = y
  end
  for k, v in pairs(g_modEventListeners) do
    if v.loadMap ~= nil then
      v:loadMap(filename)
    end
  end
  return node
end
function BaseMission:findDynamicObjects(node)
  for i = 1, getNumOfChildren(node) do
    local c = getChildAt(node, i - 1)
    if "Dynamic" == getRigidBodyType(c) then
      local object = PhysicsObject:new(self:getIsServer(), self:getIsClient())
      local index = g_currentMission:addOnCreateLoadedObject(object)
      object:loadOnCreate(c)
      object:register(true)
    else
      self:findDynamicObjects(c)
    end
  end
end
function BaseMission:loadVehicle(filename, x, yOffset, z, yRot, save)
  if not self:getIsServer() then
    print("Error: loadVehicle is only allowed on a server")
    printCallstack()
    return
  end
  local xmlFile = loadXMLFile("TempConfig", filename)
  local typeName = getXMLString(xmlFile, "vehicle#type")
  delete(xmlFile)
  local ret
  if typeName == nil then
    print("Error loadVehicle: invalid vehicle config file '" .. filename .. "', no type specified")
  else
    local typeDef = VehicleTypeUtil.vehicleTypes[typeName]
    local modName, baseDirectory = getModNameAndBaseDirectory(filename)
    if modName ~= nil then
      if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
        print("Error: Mod '" .. modName .. "' of vehicle '" .. filename .. "'")
        print("       is not loaded. This vehicle will not be loaded.")
        return
      end
      if typeDef == nil then
        typeName = modName .. "." .. typeName
        typeDef = VehicleTypeUtil.vehicleTypes[typeName]
      end
    end
    if typeDef == nil then
      print("Error loadVehicle: unknown type '" .. typeName .. "' in '" .. filename .. "'")
    else
      local callString = "g_asd_tempVehicleClass = " .. typeDef.className
      loadstring(callString)()
      if g_asd_tempVehicleClass ~= nil then
        local vehicle = g_asd_tempVehicleClass:new(self:getIsServer(), self:getIsClient())
        vehicle:load(filename, x, yOffset, z, yRot, typeName)
        if save ~= nil then
          vehicle.isVehicleSaved = save
        end
        vehicle:register()
        ret = vehicle
      end
      g_asd_tempVehicleClass = nil
    end
  end
  return ret
end
function BaseMission:loadVehicleFromXML(xmlFile, key, xmlFilename, allowDelayed)
  local filename = getXMLString(xmlFile, key .. "#filename")
  if filename ~= nil then
    filename = Utils.getFilename(filename, self.baseDirectory)
    local vehicle = self:loadVehicle(filename, 0, 0, 0, 0)
    if vehicle ~= nil then
      local r = vehicle:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
      if r == BaseMission.VEHICLE_LOAD_ERROR then
        print("Warning: corrupt vehicles xml '" .. xmlFilename .. "', vehicle " .. key .. " could not be loaded")
        self:removeVehicle(vehicle)
      elseif r == BaseMission.VEHICLE_LOAD_DELAYED then
        if allowDelayed then
          table.insert(self.vehiclesToSpawn, {xmlKey = key, xmlFilename = xmlFilename})
        end
        self:removeVehicle(vehicle)
      end
    end
  end
end
function BaseMission:loadVehicleAtPlace(xmlFilename, places, usedPlaces, rotationOffset)
  local xmlFile = loadXMLFile("VehicleXML", xmlFilename)
  local sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
  local sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
  local widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
  local lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
  local x, y, z, place, width, offset = PlacementUtil.getPlace(places, sizeWidth, sizeLength, widthOffset, lengthOffset, usedPlaces)
  if x ~= nil then
    local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
    yRot = yRot + rotationOffset
    local vehicle = self:loadVehicle(xmlFilename, x, offset, z, yRot, true)
    if vehicle ~= nil then
      PlacementUtil.markPlaceUsed(usedPlaces, place, width)
      return true
    end
  end
  return false
end
function BaseMission:addVehicle(vehicle)
  if vehicle.enterReferenceNode ~= nil and vehicle.exitPoint ~= nil then
    table.insert(self.steerables, vehicle)
  end
  if vehicle.attacherJoint ~= nil then
    table.insert(self.attachables, vehicle)
  end
  if vehicle.fillRootNode ~= nil then
    self.objectToTrailer[vehicle.fillRootNode] = vehicle
  end
  vehicle:addNodeVehicleMapping(self.nodeToVehicle)
  table.insert(self.vehicles, vehicle)
  vehicle.isAddedToMission = true
end
function BaseMission:removeVehicle(vehicle, callDelete)
  if self:getIsClient() and vehicle == self.controlledVehicle then
    self:onLeaveVehicle()
  end
  if vehicle.enterReferenceNode ~= nil and vehicle.exitPoint ~= nil then
    for i = 1, table.getn(self.steerables) do
      if self.steerables[i] == vehicle then
        table.remove(self.steerables, i)
        break
      end
    end
  end
  if vehicle.attacherJoint ~= nil then
    for i = 1, table.getn(self.attachables) do
      if self.attachables[i] == vehicle then
        table.remove(self.attachables, i)
        break
      end
    end
  end
  if vehicle.fillRootNode ~= nil then
    self.objectToTrailer[vehicle.fillRootNode] = nil
  end
  for i = 1, table.getn(self.trafficVehicles) do
    if self.trafficVehicles[i] == vehicle then
      table.remove(self.trafficVehicles, i)
      break
    end
  end
  for i = 1, table.getn(self.vehicles) do
    if self.vehicles[i] == vehicle then
      table.remove(self.vehicles, i)
      break
    end
  end
  vehicle:removeNodeVehicleMapping(self.nodeToVehicle)
  self.vehiclesToDelete[vehicle] = nil
  vehicle.isAddedToMission = false
  if callDelete == nil or callDelete == true then
    if self:getIsServer() then
      self.vehiclesToDelete[vehicle] = vehicle
    else
      g_client:getServerConnection():sendEvent(VehicleRemoveEvent:new(vehicle))
    end
  end
end
function BaseMission:addUpdateable(updateable)
  assert(updateable.isa == nil or not updateable:isa(Object), "No network objects allowed in addUpdateable")
  self.updateables[updateable] = updateable
end
function BaseMission:removeUpdateable(updateable)
  self.updateables[updateable] = nil
end
function BaseMission:addNonUpdateable(nonUpdateable)
  assert(nonUpdateable.isa == nil or not nonUpdateable:isa(Object), "No network objects allowed in addNonUpdateable")
  self.nonUpdateables[nonUpdateable] = nonUpdateable
end
function BaseMission:removeNonUpdateable(nonUpdateable)
  self.nonUpdateables[nonUpdateable] = nil
end
function BaseMission:addOnCreateLoadedObject(object)
  if not self.isLoadingMap then
    print("Error: only allowed to add objects while loading maps")
    return
  end
  table.insert(self.onCreateLoadedObjects, object)
  return table.getn(self.onCreateLoadedObjects)
end
function BaseMission:getOnCreateLoadedObject(index)
  return self.onCreateLoadedObjects[index]
end
function BaseMission:getNumOnCreateLoadedObjects()
  return table.getn(self.onCreateLoadedObjects)
end
function BaseMission:addNodeObject(node, object)
  self.nodeObjects[node] = object
end
function BaseMission:removeNodeObject(node)
  self.nodeObjects[node] = nil
end
function BaseMission:getNodeObject(node)
  return self.nodeObjects[node]
end
function BaseMission:addActivatableObject(activatableObject)
  if activatableObject.activateText == nil then
    print("Error BaseMission addActivatableObject: missing attribute activateText")
    return
  end
  table.insert(self.activatableObjects, activatableObject)
end
function BaseMission:removeActivatableObject(activatableObject)
  for i = 1, table.getn(self.activatableObjects) do
    if self.activatableObjects[i] == activatableObject then
      table.remove(self.activatableObjects, i)
      break
    end
  end
end
function BaseMission:addActivateListener(listener)
  table.insert(self.activateListeners, listener)
end
function BaseMission:addItemToSave(item)
  if item.getSaveAttributesAndNodes == nil then
    print("Error: adding item which does not have a getSaveAttributesAndNodes function")
    return
  end
  if self.objectsToClassName[item] == nil then
    print("Error: adding item which does not have a className registered. Use registerObjectClassName(object,className)")
    return
  end
  self.itemsToSave[item] = {
    item = item,
    className = self.objectsToClassName[item]
  }
end
function BaseMission:removeItemToSave(item)
  self.itemsToSave[item] = nil
end
function BaseMission:pauseGame()
  self.paused = true
  self.isRunning = false
  simulatePhysics(false)
  simulateParticleSystems(false)
end
function BaseMission:unpauseGame()
  self.paused = false
  self.isRunning = true
  simulatePhysics(true)
  simulateParticleSystems(true)
end
function BaseMission:toggleVehicle(delta)
  local numVehicles = table.getn(self.steerables)
  if 0 < numVehicles then
    local index = 1
    local oldIndex = 1
    if not self.controlPlayer then
      for i = 1, numVehicles do
        if self.controlledVehicle == self.steerables[i] then
          oldIndex = i
          index = i + delta
          if numVehicles < index then
            index = 1
          end
          if index < 1 then
            index = numVehicles
          end
          break
        end
      end
    end
    local found = false
    repeat
      if not self.steerables[index].isBroken and not self.steerables[index].isControlled then
        found = true
      else
        index = index + delta
        if numVehicles < index then
          index = 1
        end
        if index < 1 then
          index = numVehicles
        end
      end
    until found or index == oldIndex
    if found then
      g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(self.steerables[index], g_settingsNickname))
    end
  end
end
function BaseMission:getIsClient()
  return g_client ~= nil
end
function BaseMission:getIsServer()
  return g_server ~= nil
end
function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isRunning and g_gui.currentGui == nil then
    if g_server ~= nil then
      g_server:mouseEvent(posX, posY, isDown, isUp, button)
    end
    if g_client ~= nil then
      g_client:mouseEvent(posX, posY, isDown, isUp, button)
    end
    if self:getIsClient() then
      if self.controlPlayer then
        self.player:mouseEvent(posX, posY, isDown, isUp, button)
      else
        self.controlledVehicle:mouseEvent(posX, posY, isDown, isUp, button)
      end
    end
  end
  for k, v in pairs(g_modEventListeners) do
    v:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function BaseMission:keyEvent(unicode, sym, modifier, isDown)
  if self.isRunning and g_gui.currentGui == nil then
    if self:getIsServer() then
      g_server:keyEvent(unicode, sym, modifier, isDown)
    end
    if self:getIsClient() then
      g_client:keyEvent(unicode, sym, modifier, isDown)
    end
    if not self.controlPlayer then
      self.controlledVehicle:keyEvent(unicode, sym, modifier, isDown)
    end
  end
  for k, v in pairs(g_modEventListeners) do
    v:keyEvent(unicode, sym, modifier, isDown)
  end
end
function BaseMission:update(dt)
  if self:getIsServer() then
    g_server:update(dt, self.isRunning)
  end
  if self:getIsClient() then
    g_client:update(dt, self.isRunning)
  end
  if not self.isRunning then
    return
  end
  if self.firstTimeRun then
    local numToSpawn = table.getn(self.vehiclesToSpawn)
    if 0 < numToSpawn then
      for i = 1, numToSpawn do
        local xmlFilename = self.vehiclesToSpawn[i].xmlFilename
        local xmlFile = loadXMLFile("VehiclesXML", xmlFilename)
        local key = self.vehiclesToSpawn[i].xmlKey
        self:loadVehicleFromXML(xmlFile, key, xmlFilename, false)
        delete(xmlFile)
      end
      self.vehiclesToSpawn = {}
      self.usedLoadPlaces = {}
    end
  end
  for k, v in pairs(self.vehiclesToDelete) do
    k:unregister()
    k:delete()
  end
  self.vehiclesToDelete = {}
  self.time = self.time + dt
  RoadUtil.update(dt)
  self:manageTrafficVehicles(dt)
  if self:getIsClient() and g_gui.currentGui == nil then
    if InputBinding.hasEvent(InputBinding.ENTER) then
      if self.controlPlayer then
        if self.vehicleInMountRange ~= nil then
          g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(self.vehicleInMountRange, g_settingsNickname))
        end
      else
        self:onLeaveVehicle()
      end
    end
    if InputBinding.hasEvent(InputBinding.ACTIVATE_OBJECT) and 0 < table.getn(self.activatableObjects) then
      for i = table.getn(self.activatableObjects), 1, -1 do
        if self.activatableObjects[i]:getIsActivatable() then
          local object = self.activatableObjects[i]
          table.remove(self.activatableObjects, i)
          object:onActivateObject()
          for _, v in pairs(self.activateListeners) do
            v:onActivateObject(object)
          end
          break
        end
      end
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_HELP_TEXT) then
      self.showHelpText = not self.showHelpText
    end
    if InputBinding.hasEvent(InputBinding.SWITCH_VEHICLE) and self.player ~= nil and not self.player.isFrozen then
      local delta = 1
      if Input.isKeyPressed(Input.KEY_lshift) then
        delta = -1
      end
      self:toggleVehicle(delta)
    end
  end
  if self:getIsClient() then
    self.vehicleInMountRange = self:getSteerableInRange()
    self.trailerInTipRange, self.currentTipTrigger = self:getTrailerInTipRange()
    self.attachableInMountRange, self.attachableInMountRangeIndex, self.attachableInMountRangeVehicle = self:getAttachableInRange()
  end
  if self.environment ~= nil then
    self.environment:update(dt)
  end
  for k, v in pairs(self.updateables) do
    v:update(dt)
  end
  for k, v in pairs(g_modEventListeners) do
    v:update(dt)
  end
  self.firstTimeRun = true
end
function BaseMission:draw()
  if self.isRunning and g_gui.currentGui == nil then
    if self.telescopeActive then
      self.coinTelescopeOverlay:render()
    end
    if self.controlledVehicle ~= nil then
      if self.showVehicleInfo then
        self.controlledVehicle:draw()
      end
    elseif self.player ~= nil then
      self.player:draw()
    end
    setTextAlignment(RenderText.ALIGN_LEFT)
    if self.controlledVehicle ~= nil and self.attachableInMountRange ~= nil and self.controlledVehicle.attacherJoints[self.attachableInMountRangeIndex].jointIndex == 0 then
      self.hudAttachmentOverlay:render()
    end
    if self.controlledVehicle ~= nil and self.trailerInTipRange ~= nil and self.currentTipTrigger ~= nil then
      local fruitType = self.trailerInTipRange:getCurrentFruitType()
      if fruitType == FruitUtil.FRUITTYPE_UNKNOWN or self.currentTipTrigger.acceptedFruitTypes[fruitType] then
        self.hudTipperOverlay:render()
      end
    end
    if 0 < table.getn(self.activatableObjects) then
      for i = table.getn(self.activatableObjects), 1, -1 do
        if self.activatableObjects[i]:getIsActivatable() then
          self:addHelpButtonText(self.activatableObjects[i].activateText, InputBinding.ACTIVATE_OBJECT)
          self.activatableObjects[i]:drawActivate()
          break
        end
      end
    end
    if g_settingsHelpText and self.showHelpText and not self.disableHelpTextNextFrame then
      local renderTextsLeft = {}
      local renderTextsRight = {}
      if self.controlledVehicle ~= nil then
        if self.trailerInTipRange ~= nil then
          local canDump = true
          if self.currentTipTrigger ~= nil then
            local fruitType = self.trailerInTipRange:getCurrentFruitType()
            if fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN and not self.currentTipTrigger.acceptedFruitTypes[fruitType] then
              g_currentMission:addWarning(g_i18n:getText(FruitUtil.fruitIndexToDesc[fruitType].name) .. g_i18n:getText("notAcceptedHere"), 0.018, 0.033)
              canDump = false
            else
            end
          end
          if canDump then
            self:addHelpButtonText(g_i18n:getText("Dump"), InputBinding.ATTACH)
          end
        elseif self.attachableInMountRange ~= nil and self.controlledVehicle.attacherJoints[self.attachableInMountRangeIndex].jointIndex == 0 then
          self:addHelpButtonText(g_i18n:getText("Attach"), InputBinding.ATTACH)
        elseif self.controlledVehicle.selectedImplement ~= 0 then
          local implement = self.controlledVehicle.attachedImplements[self.controlledVehicle.selectedImplement]
          local jointDesc = self.controlledVehicle.attacherJoints[implement.jointDescIndex]
          if implement.object.allowsLowering and jointDesc.allowsLowering then
            if jointDesc.moveDown then
              self:addHelpButtonText(string.format(g_i18n:getText("lift_OBJECT"), implement.object.typeDesc), InputBinding.LOWER_IMPLEMENT)
            elseif implement.object.needsLowering then
              self:addHelpButtonText(string.format(g_i18n:getText("lower_OBJECT"), implement.object.typeDesc), InputBinding.LOWER_IMPLEMENT)
            end
          end
        end
      elseif self.vehicleInMountRange ~= nil and self.controlPlayer and not self.vehicleInMountRange.isControlled then
        self:addHelpButtonText(g_i18n:getText("Enter"), InputBinding.ENTER)
      end
      if self.environment ~= nil and self.environment.dayNightCycle and (self.environment.dayTime > 73800000 or self.environment.dayTime < 19800000) and self.controlledVehicle ~= nil and not self.controlledVehicle.lightsActive then
        self:addHelpButtonText(g_i18n:getText("Turn_on_lights"), InputBinding.TOGGLE_LIGHTS)
      end
      for i = 1, table.getn(self.helpButtonTexts) do
        local inputPossibilities = {}
        local inputPossibilitiesCount = 0
        local actionIndex = self.helpButtonTexts[i].actionIndex
        local keyNames = InputBinding.getKeyNamesOfDigitalAction(actionIndex)
        if keyNames ~= nil and keyNames ~= "" then
          inputPossibilitiesCount = inputPossibilitiesCount + 1
          inputPossibilities[inputPossibilitiesCount] = keyNames
        end
        if 0 < getNumOfGamepads() then
          local gamepadButtonNames = InputBinding.getDigitalActionGamepadButtonNames(actionIndex)
          if gamepadButtonNames ~= nil and gamepadButtonNames ~= "" then
            inputPossibilitiesCount = inputPossibilitiesCount + 1
            inputPossibilities[inputPossibilitiesCount] = gamepadButtonNames
          end
        end
        keyText = ""
        if inputPossibilities[inputPossibilitiesCount] then
          keyText = inputPossibilities[inputPossibilitiesCount]
        end
        if inputPossibilities[inputPossibilitiesCount - 1] then
          keyText = inputPossibilities[inputPossibilitiesCount - 1] .. " " .. g_i18n:getText("or") .. " " .. keyText
        end
        for i = inputPossibilitiesCount - 2, 1, -1 do
          keyText = inputPossibilities[i] .. ", " .. keyText
        end
        keyText = keyText .. ":"
        if 0 < inputPossibilitiesCount then
          if 2 < inputPossibilitiesCount then
            table.insert(renderTextsLeft, keyText)
            table.insert(renderTextsRight, "")
            table.insert(renderTextsLeft, "")
            table.insert(renderTextsRight, self.helpButtonTexts[i].text)
          else
            table.insert(renderTextsLeft, keyText)
            table.insert(renderTextsRight, self.helpButtonTexts[i].text)
          end
        end
      end
      self.helpButtonTexts = {}
      setTextColor(1, 1, 1, 1)
      setTextBold(false)
      for i = 1, table.getn(self.extraPrintTexts) do
        table.insert(renderTextsLeft, self.extraPrintTexts[i])
        table.insert(renderTextsRight, "")
      end
      self.extraPrintTexts = {}
      local num = math.min(30, table.getn(renderTextsLeft))
      local helpTextSize = 0.019
      if 1 <= num then
        self.hudHelpBaseOverlay.height = self.hudHelpBaseHeight
        self.hudHelpBaseOverlay.y = self.hudHelpBasePosY
        if 6 <= num then
          self.hudHelpBaseOverlay.height = self.hudHelpBaseOverlay.height + (num - 4) * 1.25 * helpTextSize
          self.hudHelpBaseOverlay.y = self.hudHelpBaseOverlay.y - (num - 4) * 1.2 * helpTextSize
        elseif 5 <= num then
          self.hudHelpBaseOverlay.height = self.hudHelpBaseOverlay.height + helpTextSize
          self.hudHelpBaseOverlay.y = self.hudHelpBaseOverlay.y - helpTextSize
        end
        self.hudHelpBaseOverlay:render()
      end
      for i = 1, num do
        local left = renderTextsLeft[i]
        local right = renderTextsRight[i]
        renderText(0.025, (4 - i) * 0.021 + self.hudHelpBasePosY + 0.02, helpTextSize, left)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(0.35, (4 - i) * 0.021 + self.hudHelpBasePosY + 0.02, helpTextSize, right)
        setTextAlignment(RenderText.ALIGN_LEFT)
      end
    end
    if 1 <= table.getn(self.warnings) then
      setTextColor(1, 0.85, 0, 1)
      self.hudWarningBaseOverlay:render()
      setTextWrapWidth(0.33)
      setTextAlignment(RenderText.ALIGN_CENTER)
      renderText(0.495, self.hudWarningBasePosY + 0.105, 0.019, self.warnings[1])
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextWrapWidth(0)
      setTextColor(1, 1, 1, 1)
    end
    self.warnings = {}
    if g_server ~= nil then
      g_server:draw()
    elseif g_client ~= nil then
      g_client:draw()
    end
    for k, v in pairs(g_modEventListeners) do
      v:draw()
    end
  end
  self.disableHelpTextNextFrame = false
end
function BaseMission:onEnterVehicle(vehicle)
  if self.controlPlayer then
    g_client:getServerConnection():sendEvent(PlayerLeaveEvent:new(self.player))
    self.player:onLeave()
  else
    g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(self.controlledVehicle))
    self.controlledVehicle:onLeave()
  end
  self.controlledVehicle = vehicle
  self.controlledVehicle:onEnter(true)
  self.controlledVehicle.controllerName = g_settingsNickname
  self.controlPlayer = false
end
function BaseMission:onLeaveVehicle()
  if not self.controlPlayer then
    g_client:getServerConnection():sendEvent(VehicleLeaveEvent:new(self.controlledVehicle))
    self.controlledVehicle:onLeave()
    self.controlPlayer = true
    self.player:onEnter(true)
    g_client:getServerConnection():sendEvent(PlayerEnterEvent:new(self.player, self.controlledVehicle))
    self.player:moveToExitPoint(self.controlledVehicle)
    self.controlledVehicle = nil
  end
end
function BaseMission:getTrailerInTipRange(vehicle, minDistance)
  if minDistance == nil then
    minDistance = self.tipTriggerRangeThreshold
  end
  local ret, retTrigger
  if vehicle == nil then
    vehicle = self.controlledVehicle
  end
  if vehicle ~= nil then
    if vehicle.fillRootNode ~= nil and vehicle.tipReferencePoint ~= nil then
      local trailerX, trailerY, trailerZ = getWorldTranslation(vehicle.tipReferencePoint)
      local triggers = self.trailerTipTriggers[vehicle]
      if triggers ~= nil then
        for k, tipTrigger in pairs(triggers) do
          local triggerX, triggerY, triggerZ = getWorldTranslation(tipTrigger.triggerId)
          local distance = Utils.vector2Length(trailerX - triggerX, trailerZ - triggerZ)
          if minDistance > distance then
            ret = vehicle
            retTrigger = tipTrigger
            minDistance = distance
          end
        end
      end
    end
    for k, implement in pairs(vehicle.attachedImplements) do
      local tempRet, tempRetTrigger, newMinDistance = self:getTrailerInTipRange(implement.object, minDistance)
      if tempRet ~= nil and tempRetTrigger ~= nil then
        ret = tempRet
        retTrigger = tempRetTrigger
      end
      minDistance = newMinDistance
    end
  end
  return ret, retTrigger, minDistance
end
function BaseMission:getIsTrailerInTipRange(trailer, tipTrigger)
  if trailer.tipReferencePoint ~= nil then
    local trailerX, trailerY, trailerZ = getWorldTranslation(trailer.tipReferencePoint)
    local triggerX, triggerY, triggerZ = getWorldTranslation(tipTrigger.triggerId)
    local distance = Utils.vector2Length(trailerX - triggerX, trailerZ - triggerZ)
    if distance < self.tipTriggerRangeThreshold then
      return true
    end
  end
  return false
end
function BaseMission:getSteerableInRange()
  local nearestVehicle
  if self.player ~= nil then
    local nearestDistance = self.mountThreshold
    local px, py, pz = getWorldTranslation(self.player.rootNode)
    for i = 1, table.getn(self.steerables) do
      if not self.steerables[i].isBroken then
        local vx, vy, vz = getWorldTranslation(self.steerables[i].enterReferenceNode)
        if vx == nil then
          print("nil: index: " .. i)
          print("num steerables: " .. table.getn(self.steerables))
        end
        local distance = Utils.vector2Length(px - vx, pz - vz)
        if nearestDistance > distance then
          nearestVehicle = self.steerables[i]
          nearestDistance = distance
        end
      end
    end
  end
  return nearestVehicle
end
function BaseMission:getAttachableInRange(vehicle, nearestDistanceSq)
  if vehicle == nil then
    vehicle = self.controlledVehicle
  end
  if nearestDistanceSq == nil then
    nearestDistanceSq = 0.36
  end
  if vehicle ~= nil then
    local nearestAttachable
    local nearestIndex = 0
    local nearestVehicle
    for j = 1, table.getn(vehicle.attacherJoints) do
      local jointDesc = vehicle.attacherJoints[j]
      if jointDesc.jointIndex ~= 0 then
        local attached = vehicle.attachedImplements[vehicle:getAttachedIndexFromJointDescIndex(j)].object
        local a, index, v, d = self:getAttachableInRange(attached, nearestDistanceSq)
        if a ~= nil then
          nearestDistanceSq = d
          nearestVehicle = v
          nearestIndex = index
          nearestAttachable = a
        end
      else
        local px, py, pz = getWorldTranslation(jointDesc.jointTransform)
        local jdx, jdy, jdz = localDirectionToWorld(jointDesc.jointTransform, 1, 0, 0)
        for k, attachable in pairs(self.attachables) do
          local attacherJoint = attachable.attacherJoint
          if attachable.attacherVehicle == nil and attacherJoint.jointType == jointDesc.jointType then
            local vx, vy, vz = getWorldTranslation(attacherJoint.node)
            local distanceSq = Utils.vector2LengthSq(px - vx, pz - vz)
            local distanceY = math.abs(py - vy)
            if nearestDistanceSq > distanceSq and distanceY < 1.3 then
              local dx, dy, dz = localDirectionToWorld(attacherJoint.node, 1, 0, 0)
              local cosAngle = dx * jdx + dy * jdy + dz * jdz
              local cosAngleLimit = 0.34202
              if cosAngle > cosAngleLimit then
                nearestAttachable = attachable
                nearestDistanceSq = distanceSq
                nearestIndex = j
                nearestVehicle = vehicle
              end
            end
          end
        end
      end
    end
    return nearestAttachable, nearestIndex, nearestVehicle, nearestDistanceSq
  end
  return nil
end
function BaseMission:drawTime(big, timeHoursF)
  local timeHours = math.floor(timeHoursF)
  local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
  setTextBold(true)
  local offsetX = 0.011
  local offsetY = 0.022
  local fontSize = 0.04
  if big then
    offsetX = 0.03
    offsetY = 0.015
    fontSize = 0.05
  end
  renderText(self.hudBasePosX + 0.007 + offsetX, self.hudBasePosY + 0.02 + offsetY, fontSize, string.format("%02d:%02d", timeHours, timeMinutes))
end
function BaseMission:onSunkVehicle(vehicle)
end
function BaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
  self.missionInfo = missionInfo
  self.missionDynamicInfo = missionDynamicInfo
end
function BaseMission:addHelpButtonText(text, inputActionIndex)
  table.insert(self.helpButtonTexts, {text = text, actionIndex = inputActionIndex})
end
function BaseMission:addExtraPrintText(text)
  table.insert(self.extraPrintTexts, text)
end
function BaseMission:addWarning(text)
  table.insert(self.warnings, text)
end
function BaseMission:manageTrafficVehicles(dt)
  if self:getIsServer() then
    local numToAdd = table.getn(self.trafficVehiclesToSpawn)
    if not self.missionDynamicInfo.isMultiplayer then
      local numTrafficVehicles = table.getn(self.trafficVehicles) + numToAdd
      if numTrafficVehicles < self.maxNumTrafficVehicles and self.timeAtLastTrafficVehicleSpawn + self.tafficVehicleSpawnInterval < self.time then
        self.timeAtLastTrafficVehicleSpawn = self.time
        local filename = TrafficVehicleUtil.getRandomTrafficVehicle()
        local xmlFile = loadXMLFile("TempConfig", filename)
        local spawnTestRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spawnTest#radius"), 15)
        delete(xmlFile)
        local spawnTestInterval = 1000
        local sequence, loopIndex = RoadUtil.getRandomRoadSequence("trafficRoad")
        if sequence ~= nil then
          table.insert(self.trafficVehiclesToSpawn, {
            filename = filename,
            spawnTestNextTime = 0,
            spawnTestRadius = spawnTestRadius,
            spawnTestInterval = spawnTestInterval,
            sequence = sequence,
            loopIndex = loopIndex
          })
        else
          self.maxNumTrafficVehicles = 0
        end
      end
    end
    if 0 < numToAdd then
      for i = numToAdd, 1, -1 do
        local spawn = self.trafficVehiclesToSpawn[i]
        if self.time > spawn.spawnTestNextTime then
          self.spawnCollisionsFound = false
          local road = spawn.sequence[1].road2
          local timePos = spawn.sequence[1].timePos2
          local direction = spawn.sequence[1].directionOnRoad2
          local x, y, z = PathVehicle.getTrackPosition(road, timePos, direction)
          local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
          if PathVehicle.isVehicleAllowedToChange(x, terrainHeight, z, 50, 100) then
            overlapSphere(x, terrainHeight, z, spawn.spawnTestRadius, "spawnCollisionTestCallback", self)
          else
            self.spawnCollisionsFound = true
          end
          if self.spawnCollisionsFound then
            spawn.spawnTestNextTime = self.time + spawn.spawnTestInterval
          else
            table.remove(self.trafficVehiclesToSpawn, i)
            local vehicle = self:loadVehicle(spawn.filename, 0, 0.5, 0, 0, false)
            if vehicle ~= nil then
              table.insert(self.trafficVehicles, vehicle)
              vehicle:followSequence(spawn.sequence, spawn.loopIndex, true)
            end
            break
          end
        end
      end
    end
  end
end
function BaseMission:spawnCollisionTestCallback(transformId)
  if self.nodeToVehicle[transformId] ~= nil then
    self.spawnCollisionsFound = true
  end
end
function BaseMission:onCreateLoadSpawnPlace(id)
  local place = PlacementUtil.createPlace(id)
  table.insert(g_currentMission.loadSpawnPlaces, place)
end
function BaseMission:onCreateStoreSpawnPlace(id)
  local place = PlacementUtil.createPlace(id)
  table.insert(g_currentMission.storeSpawnPlaces, place)
end
