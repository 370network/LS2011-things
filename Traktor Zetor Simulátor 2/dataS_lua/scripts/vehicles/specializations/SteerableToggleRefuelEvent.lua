SteerableToggleRefuelEvent = {}
SteerableToggleRefuelEvent_mt = Class(SteerableToggleRefuelEvent, Event)
InitStaticEventClass(SteerableToggleRefuelEvent, "SteerableToggleRefuelEvent", EventIds.EVENT_STEERABLE_TOGGLE_REFUEL)
function SteerableToggleRefuelEvent:emptyNew()
  local self = Event:new(SteerableToggleRefuelEvent_mt)
  self.className = "SteerableToggleRefuelEvent"
  return self
end
function SteerableToggleRefuelEvent:new(object, isRefueling)
  local self = SteerableToggleRefuelEvent:emptyNew()
  self.object = object
  self.isRefueling = isRefueling
  return self
end
function SteerableToggleRefuelEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isRefueling = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function SteerableToggleRefuelEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isRefueling)
end
function SteerableToggleRefuelEvent:run(connection)
  if self.isRefueling then
    self.object:startRefuel(true)
  else
    self.object:stopRefuel(true)
  end
  if not connection:getIsServer() then
    g_server:broadcastEvent(SteerableToggleRefuelEvent:new(self.object, self.isRefueling), nil, connection, self.object)
  end
end
