VehicleLeaveEvent = {}
VehicleLeaveEvent_mt = Class(VehicleLeaveEvent, Event)
InitStaticEventClass(VehicleLeaveEvent, "VehicleLeaveEvent", EventIds.EVENT_VEHICLE_LEAVE)
function VehicleLeaveEvent:emptyNew()
  local self = Event:new(VehicleLeaveEvent_mt)
  self.className = "VehicleLeaveEvent"
  return self
end
function VehicleLeaveEvent:new(object)
  local self = VehicleLeaveEvent:emptyNew()
  self.object = object
  return self
end
function VehicleLeaveEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function VehicleLeaveEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function VehicleLeaveEvent:run(connection)
  if not connection:getIsServer() then
    if self.object.owner ~= nil then
      self.object:setOwner(nil)
    end
    g_server:broadcastEvent(VehicleLeaveEvent:new(self.object), nil, connection, self.object)
  end
  self.object:onLeave()
end
