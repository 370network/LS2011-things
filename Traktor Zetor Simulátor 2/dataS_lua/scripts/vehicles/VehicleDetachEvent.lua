VehicleDetachEvent = {}
VehicleDetachEvent_mt = Class(VehicleDetachEvent, Event)
InitStaticEventClass(VehicleDetachEvent, "VehicleDetachEvent", EventIds.EVENT_VEHICLE_DETACH)
function VehicleDetachEvent:emptyNew()
  local self = Event:new(VehicleDetachEvent_mt)
  self.className = "VehicleDetachEvent"
  return self
end
function VehicleDetachEvent:new(vehicle, implement)
  local self = VehicleDetachEvent:emptyNew()
  self.implement = implement
  self.vehicle = vehicle
  return self
end
function VehicleDetachEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  local implementId = streamReadInt32(streamId)
  self.implement = networkGetObject(implementId)
  self.vehicle = networkGetObject(id)
  self:run(connection)
end
function VehicleDetachEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.vehicle))
  streamWriteInt32(streamId, networkGetObjectId(self.implement))
end
function VehicleDetachEvent:run(connection)
  self.vehicle:detachImplementByObject(self.implement, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(VehicleDetachEvent:new(self.vehicle, self.implement), nil, connection, self.object)
  end
end
