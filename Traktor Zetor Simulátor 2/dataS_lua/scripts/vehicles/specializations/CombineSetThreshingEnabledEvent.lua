CombineSetThreshingEnabledEvent = {}
CombineSetThreshingEnabledEvent_mt = Class(CombineSetThreshingEnabledEvent, Event)
InitStaticEventClass(CombineSetThreshingEnabledEvent, "CombineSetThreshingEnabledEvent", EventIds.EVENT_COMBINE_SET_TRESHING_ENABLED)
function CombineSetThreshingEnabledEvent:emptyNew()
  local self = Event:new(CombineSetThreshingEnabledEvent_mt)
  self.className = "CombineSetThreshingEnabledEvent"
  return self
end
function CombineSetThreshingEnabledEvent:new(object, enabled)
  local self = CombineSetThreshingEnabledEvent:emptyNew()
  self.object = object
  self.enabled = enabled
  return self
end
function CombineSetThreshingEnabledEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.enabled = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function CombineSetThreshingEnabledEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.enabled)
end
function CombineSetThreshingEnabledEvent:run(connection)
  self.object:setIsThreshing(self.enabled, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(CombineSetThreshingEnabledEvent:new(self.object, self.enabled), nil, connection, self.object)
  end
end
