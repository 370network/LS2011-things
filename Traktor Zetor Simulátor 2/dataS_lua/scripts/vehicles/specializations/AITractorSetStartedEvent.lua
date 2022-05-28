AITractorSetStartedEvent = {}
AITractorSetStartedEvent_mt = Class(AITractorSetStartedEvent, Event)
InitStaticEventClass(AITractorSetStartedEvent, "AITractorSetStartedEvent", EventIds.EVENT_AITRACTOR_SET_STARTED)
function AITractorSetStartedEvent:emptyNew()
  local self = Event:new(AITractorSetStartedEvent_mt)
  self.className = "AITractorSetStartedEvent"
  return self
end
function AITractorSetStartedEvent:new(object, isStarted)
  local self = AITractorSetStartedEvent:emptyNew()
  self.object = object
  self.isStarted = isStarted
  return self
end
function AITractorSetStartedEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isStarted = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AITractorSetStartedEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isStarted)
end
function AITractorSetStartedEvent:run(connection)
  if self.isStarted then
    self.object:startAITractor(true)
  else
    self.object:stopAITractor(true)
  end
  if not connection:getIsServer() then
    for k, v in pairs(g_server.clientConnections) do
      if v ~= connection and not v:getIsLocal() then
        v:sendEvent(AITractorSetStartedEvent:new(self.object, self.isStarted))
      end
    end
  end
end
