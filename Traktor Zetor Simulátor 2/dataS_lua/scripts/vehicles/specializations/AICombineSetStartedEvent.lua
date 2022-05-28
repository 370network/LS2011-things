AICombineSetStartedEvent = {}
AICombineSetStartedEvent_mt = Class(AICombineSetStartedEvent, Event)
InitStaticEventClass(AICombineSetStartedEvent, "AICombineSetStartedEvent", EventIds.EVENT_AICOMBINE_SET_STARTED)
function AICombineSetStartedEvent:emptyNew()
  local self = Event:new(AICombineSetStartedEvent_mt)
  self.className = "AICombineSetStartedEvent"
  return self
end
function AICombineSetStartedEvent:new(object, isStarted)
  local self = AICombineSetStartedEvent:emptyNew()
  self.object = object
  self.isStarted = isStarted
  return self
end
function AICombineSetStartedEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isStarted = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AICombineSetStartedEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isStarted)
end
function AICombineSetStartedEvent:run(connection)
  if self.isStarted then
    self.object:startAIThreshing(true)
  else
    self.object:stopAIThreshing(true)
  end
  if not connection:getIsServer() then
    g_server:broadcastEvent(AICombineSetStartedEvent:new(self.object, self.isStarted), nil, connection, self.object)
  end
end
