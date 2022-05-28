SteerableToggleLightEvent = {}
SteerableToggleLightEvent_mt = Class(SteerableToggleLightEvent, Event)
InitStaticEventClass(SteerableToggleLightEvent, "SteerableToggleLightEvent", EventIds.EVENT_STEERABLE_TOGGLE_LIGHT)
function SteerableToggleLightEvent:emptyNew()
  local self = Event:new(SteerableToggleLightEvent_mt)
  self.className = "SteerableToggleLightEvent"
  return self
end
function SteerableToggleLightEvent:new(object, lightActive)
  local self = SteerableToggleLightEvent:emptyNew()
  self.lightActive = lightActive
  self.object = object
  return self
end
function SteerableToggleLightEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.lightActive = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function SteerableToggleLightEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.lightActive)
end
function SteerableToggleLightEvent:run(connection)
  self.object:setLightsVisibility(self.lightActive, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(SteerableToggleLightEvent:new(self.object, self.lightActive), nil, connection, self.object)
  end
end
