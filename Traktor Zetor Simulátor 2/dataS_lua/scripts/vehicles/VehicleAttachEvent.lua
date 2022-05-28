VehicleAttachEvent = {}
VehicleAttachEvent_mt = Class(VehicleAttachEvent, Event)
InitStaticEventClass(VehicleAttachEvent, "VehicleAttachEvent", EventIds.EVENT_VEHICLE_ATTACH)
function VehicleAttachEvent:emptyNew()
  local self = Event:new(VehicleAttachEvent_mt)
  self.className = "VehicleAttachEvent"
  return self
end
function VehicleAttachEvent:new(vehicle, implement, jointIndex)
  local self = VehicleAttachEvent:emptyNew()
  self.jointIndex = jointIndex
  self.vehicle = vehicle
  self.implement = implement
  return self
end
function VehicleAttachEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  local implementId = streamReadInt32(streamId)
  self.jointIndex = streamReadInt32(streamId)
  self.vehicle = networkGetObject(id)
  self.implement = networkGetObject(implementId)
  self:run(connection)
end
function VehicleAttachEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.vehicle))
  streamWriteInt32(streamId, networkGetObjectId(self.implement))
  streamWriteInt32(streamId, self.jointIndex)
end
function VehicleAttachEvent:run(connection)
  self.vehicle:attachImplement(self.implement, self.jointIndex, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(VehicleAttachEvent:new(self.vehicle, self.implement, self.jointIndex), nil, connection, self.object)
  end
end
