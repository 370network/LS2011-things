AITractorLowerImplementEvent = {}
AITractorLowerImplementEvent_mt = Class(AITractorLowerImplementEvent, Event)
InitStaticEventClass(AITractorLowerImplementEvent, "AITractorLowerImplementEvent", EventIds.EVENT_AITRACTOR_LOWER_IMPLEMENT)
function AITractorLowerImplementEvent:emptyNew()
  local self = Event:new(AITractorLowerImplementEvent_mt)
  self.className = "AITractorLowerImplementEvent"
  return self
end
function AITractorLowerImplementEvent:new(object)
  local self = AITractorLowerImplementEvent:emptyNew()
  self.object = object
  return self
end
function AITractorLowerImplementEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AITractorLowerImplementEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function AITractorLowerImplementEvent:run(connection)
  AITractor.lowerImplements(self.object)
end
