AITractorRotateRightEvent = {}
AITractorRotateRightEvent_mt = Class(AITractorRotateRightEvent, Event)
InitStaticEventClass(AITractorRotateRightEvent, "AITractorRotateRightEvent", EventIds.EVENT_AITRACTOR_ROTATE_RIGHT)
function AITractorRotateRightEvent:emptyNew()
  local self = Event:new(AITractorRotateRightEvent_mt)
  self.className = "AITractorRotateRightEvent"
  return self
end
function AITractorRotateRightEvent:new(object)
  local self = AITractorRotateRightEvent:emptyNew()
  self.object = object
  return self
end
function AITractorRotateRightEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AITractorRotateRightEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function AITractorRotateRightEvent:run(connection)
  AITractor.aiRotateRight(self.object)
end
