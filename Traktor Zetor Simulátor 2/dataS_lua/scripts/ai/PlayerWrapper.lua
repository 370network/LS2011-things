PlayerWrapper = {}
local PlayerWrapper_mt = Class(PlayerWrapper, Entity)
function PlayerWrapper:new(connection)
  if self == PlayerWrapper then
    self = setmetatable({}, PlayerWrapper_mt)
  end
  PlayerWrapper:superClass().new(self)
  local playerPositionX, playerPositionY, playerPositionZ = -9999, 0, -9999
  PlayerWrapper:superClass().initialize(self, {
    positionX = playerPositionX,
    positionY = playerPositionY,
    positionZ = playerPositionZ,
    name = "Player",
    type = EntityType.PLAYER
  })
  self.directionX, self.directionY, self.directionZ = 1, 0, 0
  self.connection = connection
  self.player = g_currentMission.connectionsToPlayer[self.connection]
  self.isInteresting = true
  self.isEnticing = false
  self.isFrightening = false
  return self
end
function PlayerWrapper:delete()
  PlayerWrapper:superClass().delete(self)
end
function PlayerWrapper:findPlayer()
  if g_currentMission:getIsServer() then
    return g_currentMission.connectionsToPlayer[self.connection]
  else
    return g_currentMission.player
  end
end
function PlayerWrapper:findControlledObject()
  local player = self:findPlayer()
  if player ~= nil and player.isControlled then
    return player, true
  end
  if g_currentMission:getIsServer() then
    for _, vehicle in pairs(g_currentMission.steerables) do
      if vehicle.isControlled and vehicle.owner == self.connection then
        return vehicle, false
      end
    end
  else
    return g_currentMission.controlledVehicle, false
  end
  return nil, false
end
function PlayerWrapper:update(dt)
  self.player = self:findPlayer()
  local controlledObject, isControllingPlayer = self:findControlledObject()
  local isInVehicle = not isControllingPlayer
  local isDriving = false
  local noSpeedAvailable = false
  if controlledObject ~= nil then
    if isControllingPlayer then
      self.positionX, self.positionY, self.positionZ = getWorldTranslation(controlledObject.rootNode)
      self.directionX, self.directionY, self.directionZ = 1, 0, 0
    else
      self.positionX, self.positionY, self.positionZ = getWorldTranslation(controlledObject.components[1].node)
      self.directionX, self.directionY, self.directionZ = 1, 0, 0
    end
    if controlledObject.lastSpeed then
      if controlledObject.lastSpeed > 0.0015 then
        isDriving = true
      end
    else
      noSpeedAvailable = true
    end
  end
  self.isFrightening = isInVehicle and (isDriving or noSpeedAvailable)
  local isActiveForInput = g_gui.currentGui == nil
  if isActiveForInput and self.player ~= nil and self.player == g_currentMission.player and isControllingPlayer and InputBinding.hasEvent(InputBinding.STARTLE_ANIMAL) then
    local originX, originY, originZ = getWorldTranslation(self.player.cameraId)
    local directionX, directionY, directionZ = localDirectionToWorld(self.player.cameraId, 0, 0, 1)
    local shoutingPersonIsMe = true
    self.player:playStartleAnimalSound(not shoutingPersonIsMe)
    g_client:getServerConnection():sendEvent(StartleAnimalEvent:new(originX, originY, originZ, directionX, directionY, directionZ))
  end
end
function PlayerWrapper:startleAnimal(originX, originY, originZ, directionX, directionY, directionZ)
  if not AnimalHusbandry.isInUse then
    return
  end
  if not AnimalHusbandry.useAnimalAI then
    return
  end
  if not AnimalHusbandry.herd.isVisible then
    return
  end
  local maxDistance = 5
  local minAngleFactor = 0.25
  for _, animal in ipairs(AnimalHusbandry.herd.visibleAnimals) do
    local connectionToAnimalX, connectionToAnimalY, connectionToAnimalZ = originX - animal.positionX, originY - animal.positionY, originZ - animal.positionZ
    local distance = Utils.vector3Length(connectionToAnimalX, connectionToAnimalY, connectionToAnimalZ)
    if maxDistance >= distance then
      local directionToAnimalX, directionToAnimalY, directionToAnimalZ
      if 0 < distance then
        directionToAnimalX, directionToAnimalY, directionToAnimalZ = connectionToAnimalX / distance, connectionToAnimalY / distance, connectionToAnimalZ / distance
      else
        directionToAnimalX, directionToAnimalY, directionToAnimalZ = directionX, directionY, directionZ
      end
      local angleFactor = Utils.dotProduct(directionToAnimalX, directionToAnimalY, directionToAnimalZ, directionX, directionY, directionZ)
      if minAngleFactor < angleFactor then
        Perception:injectPerception(animal, DefaultPreconditions.playerSlapped, true, self)
      end
    end
  end
end
function PlayerWrapper:raycastCallbackFunction(hitObjectId, x, y, z, distance)
  for _, animal in ipairs(AnimalHusbandry.herd.visibleAnimals) do
    if hitObjectId == animal.boundingBoxId then
      self.hitAnimal = animal
      return false
    end
  end
  return true
end
