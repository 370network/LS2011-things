AITractorRotateLeftEvent = {}
AITractorRotateLeftEvent_mt = Class(AITractorRotateLeftEvent, Event)
InitStaticEventClass(AITractorRotateLeftEvent, "AITractorRotateLeftEvent", EventIds.EVENT_AITRACTOR_ROTATE_LEFT)
function AITractorRotateLeftEvent:emptyNew()
  local self = Event:new(AITractorRotateLeftEvent_mt)
  self.className = "AITractorRotateLeftEvent"
  return self
end
function AITractorRotateLeftEvent:new(object)
  local self = AITractorRotateLeftEvent:emptyNew()
  self.object = object
  return self
end
function AITractorRotateLeftEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AITractorRotateLeftEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function AITractorRotateLeftEvent:run(connection)
  AITractor.aiRotateLeft(self.object)
end
