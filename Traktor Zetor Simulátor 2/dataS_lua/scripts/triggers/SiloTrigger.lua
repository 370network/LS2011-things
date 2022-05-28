SiloTrigger = {}
local SiloTrigger_mt = Class(SiloTrigger, Object)
InitStaticObjectClass(SiloTrigger, "SiloTrigger", ObjectIds.OBJECT_SILO_TRIGGER)
function SiloTrigger:onCreate(id)
  local trigger = SiloTrigger:new(g_server ~= nil, g_client ~= nil)
  local index = g_currentMission:addOnCreateLoadedObject(trigger)
  trigger:load(id)
  trigger:register(true)
end
function SiloTrigger:new(isServer, isClient)
  local self = Object:new(isServer, isClient, SiloTrigger_mt)
  self.className = "SiloTrigger"
  self.rootNode = 0
  self.siloTriggerDirtyFlag = self:getNextDirtyFlag()
  return self
end
function SiloTrigger:load(id)
  self.rootNode = id
  if self.isServer then
    self.triggerIds = {}
    table.insert(self.triggerIds, id)
    addTrigger(id, "triggerCallback", self)
    for i = 1, 3 do
      local child = getChildAt(id, i - 1)
      table.insert(self.triggerIds, child)
      addTrigger(child, "triggerCallback", self)
    end
  end
  self.fillType = Fillable.FILLTYPE_UNKNOWN
  local fruitType = getUserAttribute(id, "fruitType")
  if fruitType ~= nil then
    local desc = FruitUtil.fruitTypes[fruitType]
    if desc ~= nil then
      self.fillType = FruitUtil.fruitTypeToFillType[desc.index]
    end
  elseif Utils.getNoNil(getUserAttribute(id, "fillTypeWheat"), false) then
    self.fillType = Fillable.FILLTYPE_WHEAT
  elseif Utils.getNoNil(getUserAttribute(id, "fillTypeGrass"), false) then
    self.fillType = Fillable.FILLTYPE_GRASS
  end
  local particlePositionStr = getUserAttribute(id, "particlePosition")
  if particlePositionStr ~= nil then
    local x, y, z = Utils.getVectorFromString(particlePositionStr)
    if x ~= nil and y ~= nil and z ~= nil then
      self.particlePosition = {
        x,
        y,
        z
      }
    end
  end
  self.isEnabled = true
  self.fill = 0
  self.siloTrailerId = 0
  self.fillDone = false
  self.isFilling = false
  self.fillLitersPerSecond = Utils.getNoNil(tonumber(getUserAttribute(id, "fillLitersPerSecond")), 1500)
  if self.isClient then
    local particleSystem = Utils.getNoNil(getUserAttribute(id, "particleSystem"), "wheatParticleSystemLong")
    self.siloParticleSystemRoot = loadI3DFile("data/vehicles/particleSystems/" .. particleSystem .. ".i3d")
    local x, y, z = getTranslation(id)
    if self.particlePosition ~= nil then
      x = x + self.particlePosition[1]
      y = y + self.particlePosition[2]
      z = z + self.particlePosition[3]
    end
    setTranslation(self.siloParticleSystemRoot, x, y, z)
    link(getParent(id), self.siloParticleSystemRoot)
    for i = 0, getNumOfChildren(self.siloParticleSystemRoot) - 1 do
      local child = getChildAt(self.siloParticleSystemRoot, i)
      if getClassName(child) == "Shape" then
        local geometry = getGeometry(child)
        if geometry ~= 0 and getClassName(geometry) == "ParticleSystem" then
          self.siloParticleSystem = geometry
        end
      end
    end
    if self.siloParticleSystem ~= nil then
      setEmittingState(self.siloParticleSystem, false)
    end
    self.siloFillSound = createSample("siloFillSound")
    loadSample(self.siloFillSound, "data/maps/sounds/siloFillSound.wav", false)
  end
end
function SiloTrigger:delete()
  if self.isClient then
    delete(self.siloFillSound)
  end
  if self.isServer then
    for i = 1, table.getn(self.triggerIds) do
      removeTrigger(self.triggerIds[i])
    end
  end
  if self.siloParticleSystemRoot ~= nil then
    delete(self.siloParticleSystemRoot)
  end
  delete(self.rootNode)
  SiloTrigger:superClass().delete(self)
end
function SiloTrigger:readStream(streamId, connection)
  SiloTrigger:superClass().readStream(self, streamId)
  if connection:getIsServer() then
    local isFilling = streamReadBool(streamId)
    if isFilling then
      self:startFill()
    else
      self:stopFill()
    end
  end
end
function SiloTrigger:writeStream(streamId, connection)
  SiloTrigger:superClass().writeStream(self, streamId)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.isFilling)
  end
end
function SiloTrigger:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    local isFilling = streamReadBool(streamId)
    if isFilling then
      self:startFill()
    else
      self:stopFill()
    end
  end
end
function SiloTrigger:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.isFilling)
  end
end
function SiloTrigger:update(dt)
  if self.isServer and self.fill >= 4 and self.siloTrailer ~= nil and not self.fillDone then
    local trailer = self.siloTrailer
    local fillLevel = trailer.fillLevel
    local siloAmount = g_currentMission:getSiloAmount(self.fillType)
    if 0 < siloAmount then
      local deltaFillLevel = math.min(self.fillLitersPerSecond * 0.001 * dt, siloAmount)
      trailer:setFillLevel(fillLevel + deltaFillLevel, self.fillType)
      local newFillLevel = trailer.fillLevel
      g_currentMission:setSiloAmount(self.fillType, math.max(siloAmount - (newFillLevel - fillLevel), 0))
      if fillLevel ~= newFillLevel then
        self:startFill()
      else
        self.fillDone = true
        self:stopFill()
      end
    else
      self.fillDone = true
      self:stopFill()
    end
  end
end
function SiloTrigger:stopFill()
  if self.isFilling then
    self.isFilling = false
    if self.isServer then
      self:raiseDirtyFlags(self.siloTriggerDirtyFlag)
    end
    if self.isClient then
      if self.siloFillSoundEnabled then
        stopSample(self.siloFillSound)
        self.siloFillSoundEnabled = false
      end
      if self.siloParticleSystem ~= nil then
        setEmittingState(self.siloParticleSystem, false)
      end
    end
  end
end
function SiloTrigger:startFill()
  if not self.isFilling then
    self.isFilling = true
    if self.isServer then
      self:raiseDirtyFlags(self.siloTriggerDirtyFlag)
    end
    if self.isClient then
      if not self.siloFillSoundEnabled then
        playSample(self.siloFillSound, 0, 1, 0)
        self.siloFillSoundEnabled = true
      end
      if self.siloParticleSystem ~= nil then
        setEmittingState(self.siloParticleSystem, true)
      end
    end
  end
end
function SiloTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  assert(self.isServer)
  if self.isEnabled then
    local trailer = g_currentMission.objectToTrailer[otherShapeId]
    if trailer ~= nil and trailer:allowFillType(self.fillType, true) and trailer.allowFillFromAir then
      if onEnter then
        self.fill = self.fill + 1
        self.siloTrailer = trailer
        self.fillDone = false
      elseif onLeave then
        self.fill = math.max(self.fill - 1, 0)
        self.siloTrailer = nil
        self.fillDone = false
        self:stopFill()
      end
    end
  end
end
