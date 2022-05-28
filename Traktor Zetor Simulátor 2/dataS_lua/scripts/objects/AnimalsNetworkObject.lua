AnimalsNetworkObject = {}
AnimalsNetworkObject_mt = Class(AnimalsNetworkObject, Object)
InitStaticObjectClass(AnimalsNetworkObject, "AnimalsNetworkObject", ObjectIds.OBJECT_ANIMALS_NETWORK_OBJECT)
function AnimalsNetworkObject:new(isServer, isClient, customMt)
  local mt = customMt
  if mt == nil then
    mt = AnimalsNetworkObject_mt
  end
  local self = Object:new(isServer, isClient, mt)
  self.className = "AnimalsNetworkObject"
  self.animalsDirtyFlag = self:getNextDirtyFlag()
  return self
end
function AnimalsNetworkObject:readStream(streamId, connection)
  if connection:getIsServer() then
    local numAnimals = streamReadUIntN(streamId, 5)
    local animals = AnimalHusbandry.herd.visibleAnimals
    if 0 < numAnimals then
      local numAnimalsToSet = math.min(numAnimals, table.getn(animals))
      local refX = streamReadFloat32(streamId)
      local refY = streamReadFloat32(streamId)
      local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAnimals - 1, 0.01, true)
      for i = 1, numAnimalsToSet do
        local posX = values[i].x
        local posZ = values[i].y
        local posY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, posX, 0, posZ)
        animals[i]:setPosition(posX, posY, posZ)
      end
      for i = 1, numAnimals do
        local angle = streamReadIntN(streamId, 12) * math.pi / 2047
        local dirX, dirZ = Utils.getDirectionFromYRotation(angle)
        local stateId = streamReadUIntN(streamId, 5)
        if numAnimalsToSet >= i then
          animals[i]:setDirection(dirX, 0, dirZ)
          local state = StateRepository.idToState[stateId]
          AnimationControl.stateChanged(animals[i], state.name)
        end
      end
    end
  end
end
function AnimalsNetworkObject:writeStream(streamId, connection)
  if not connection:getIsServer() then
    local animals = AnimalHusbandry.herd.visibleAnimals
    local numAnimals = table.getn(animals)
    streamWriteUIntN(streamId, numAnimals, 5)
    if 0 < numAnimals then
      local refX, refY
      local animalValues = {}
      for i = 1, numAnimals do
        local posX, posY, posZ = animals[i]:getPosition()
        if i == 1 then
          refX = posX
          refY = posZ
          streamWriteFloat32(streamId, posX)
          streamWriteFloat32(streamId, posZ)
        else
          table.insert(animalValues, {x = posX, y = posZ})
        end
      end
      assert(table.getn(animalValues) == numAnimals - 1)
      Utils.writeCompressed2DVectors(streamId, refX, refY, animalValues, 0.01)
      for i = 1, numAnimals do
        local dirX, dirY, dirZ = animals[i]:getDirection()
        local angle = Utils.getYRotationFromDirection(dirX, dirZ)
        local state = animals[i].stateData.currentState.id
        while angle > math.pi do
          angle = angle - 2 * math.pi
        end
        streamWriteIntN(streamId, math.floor(angle / math.pi * 2047), 12)
        streamWriteUIntN(streamId, state, 5)
      end
    end
  end
end
function AnimalsNetworkObject:readUpdateStream(streamId, timestamp, connection)
  self:readStream(streamId, connection)
end
function AnimalsNetworkObject:writeUpdateStream(streamId, connection, dirtyMask)
  self:writeStream(streamId, connection)
end
function AnimalsNetworkObject:update(dt)
end
function AnimalsNetworkObject:updateTick(dt)
  if self.isServer and table.getn(AnimalHusbandry.herd.visibleAnimals) > 0 then
    self:raiseDirtyFlags(self.animalsDirtyFlag)
  end
end
