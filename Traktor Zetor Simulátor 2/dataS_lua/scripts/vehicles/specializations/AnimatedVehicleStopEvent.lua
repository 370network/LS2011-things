AnimatedVehicleStopEvent = {}
AnimatedVehicleStopEvent_mt = Class(AnimatedVehicleStopEvent, Event)
InitStaticEventClass(AnimatedVehicleStopEvent, "AnimatedVehicleStopEvent", EventIds.EVENT_ANIMATED_VEHICLE_STOP)
function AnimatedVehicleStopEvent:emptyNew()
  local self = Event:new(AnimatedVehicleStopEvent_mt)
  self.className = "AnimatedVehicleStopEvent"
  self.eventId = EventIds.EVENT_ANIMATED_VEHICLE_STOP
  return self
end
function AnimatedVehicleStopEvent:new(object, name)
  local self = AnimatedVehicleStopEvent:emptyNew()
  self.name = name
  self.object = object
  return self
end
function AnimatedVehicleStopEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.name = streamReadString(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AnimatedVehicleStopEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteString(streamId, self.name)
end
function AnimatedVehicleStopEvent:run(connection)
  AnimatedVehicle.stopAnimation(self.object, self.name, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(AnimatedVehicleStopEvent:new(self.object, self.name), nil, connection, self.object)
  end
end
