StartleAnimalEvent = {}
StartleAnimalEvent_mt = Class(StartleAnimalEvent, Event)
InitStaticEventClass(StartleAnimalEvent, "StartleAnimalEvent", EventIds.EVENT_STARTLE_ANIMAL)
function StartleAnimalEvent:emptyNew()
  local self = Event:new(StartleAnimalEvent_mt)
  self.className = "StartleAnimalEvent"
  return self
end
function StartleAnimalEvent:new(x, y, z, dx, dy, dz)
  local self = StartleAnimalEvent:emptyNew()
  self.x = x
  self.y = y
  self.z = z
  self.dx = dx
  self.dy = dy
  self.dz = dz
  return self
end
function StartleAnimalEvent:readStream(streamId, connection)
  self.x = streamReadFloat32(streamId)
  self.y = streamReadFloat32(streamId)
  self.z = streamReadFloat32(streamId)
  self.dx = streamReadFloat32(streamId)
  self.dy = streamReadFloat32(streamId)
  self.dz = streamReadFloat32(streamId)
  self:run(connection)
end
function StartleAnimalEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.x)
  streamWriteFloat32(streamId, self.y)
  streamWriteFloat32(streamId, self.z)
  streamWriteFloat32(streamId, self.dx)
  streamWriteFloat32(streamId, self.dy)
  streamWriteFloat32(streamId, self.dz)
end
function StartleAnimalEvent:run(connection)
  local playerWrapper = AnimalHusbandry.playerWrappers[connection]
  if playerWrapper ~= nil then
    playerWrapper:startleAnimal(self.x, self.y, self.z, self.dx, self.dy, self.dz)
  end
end
