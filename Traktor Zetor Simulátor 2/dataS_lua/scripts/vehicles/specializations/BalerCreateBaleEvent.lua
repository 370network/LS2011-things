BalerCreateBaleEvent = {}
BalerCreateBaleEvent_mt = Class(BalerCreateBaleEvent, Event)
InitStaticEventClass(BalerCreateBaleEvent, "BalerCreateBaleEvent", EventIds.EVENT_BALER_CREATE_BALE)
function BalerCreateBaleEvent:emptyNew()
  local self = Event:new(BalerCreateBaleEvent_mt)
  self.className = "BalerCreateBaleEvent"
  return self
end
function BalerCreateBaleEvent:new(object, usedFruitType, baleTime)
  local self = BalerCreateBaleEvent:emptyNew()
  self.usedFruitType = usedFruitType
  self.baleTime = baleTime
  self.object = object
  return self
end
function BalerCreateBaleEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.usedFruitType = streamReadInt8(streamId)
  self.baleTime = streamReadFloat32(streamId)
  self:run(connection)
end
function BalerCreateBaleEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt8(streamId, self.usedFruitType)
  streamWriteFloat32(streamId, self.baleTime)
end
function BalerCreateBaleEvent:run(connection)
  Baler.createBale(self.object, self.usedFruitType)
  Baler.setBaleTime(self.object, table.getn(self.object.bales), self.baleTime)
end
