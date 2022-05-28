AITractorRaiseImplementEvent = {}
AITractorRaiseImplementEvent_mt = Class(AITractorRaiseImplementEvent, Event)
InitStaticEventClass(AITractorRaiseImplementEvent, "AITractorRaiseImplementEvent", EventIds.EVENT_AITRACTOR_RAISE_IMPLEMENT)
function AITractorRaiseImplementEvent:emptyNew()
  local self = Event:new(AITractorRaiseImplementEvent_mt)
  self.className = "AITractorRaiseImplementEvent"
  return self
end
function AITractorRaiseImplementEvent:new(object, usedFruitType, baleTime)
  local self = AITractorRaiseImplementEvent:emptyNew()
  self.object = object
  return self
end
function AITractorRaiseImplementEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AITractorRaiseImplementEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function AITractorRaiseImplementEvent:run(connection)
  AITractor.raiseImplements(self.object)
end
