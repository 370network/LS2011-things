BalerSetBaleTimeEvent = {}
BalerSetBaleTimeEvent_mt = Class(BalerSetBaleTimeEvent, Event)
InitStaticEventClass(BalerSetBaleTimeEvent, "BalerSetBaleTimeEvent", EventIds.EVENT_BALER_SET_BALE_TIME)
function BalerSetBaleTimeEvent:emptyNew()
  local self = Event:new(BalerSetBaleTimeEvent_mt)
  self.className = " BalerSetBaleTimeEvent"
  return self
end
function BalerSetBaleTimeEvent:new(object, bale, baleTime)
  local self = BalerSetBaleTimeEvent:emptyNew()
  self.bale = bale
  self.baleTime = baleTime
  self.object = object
  return self
end
function BalerSetBaleTimeEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.bale = streamReadInt32(streamId)
  self.baleTime = streamReadFloat32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function BalerSetBaleTimeEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt32(streamId, self.bale)
  streamWriteFloat32(streamId, self.baleTime)
end
function BalerSetBaleTimeEvent:run(connection)
  Baler.setBaleTime(self.object, self.bale, self.baleTime)
end
