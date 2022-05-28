VehicleLowerImplementEvent = {}
VehicleLowerImplementEvent_mt = Class(VehicleLowerImplementEvent, Event)
InitStaticEventClass(VehicleLowerImplementEvent, "VehicleLowerImplementEvent", EventIds.EVENT_VEHICLE_LOWER_IMPLEMENT)
function VehicleLowerImplementEvent:emptyNew()
  local self = Event:new(VehicleLowerImplementEvent_mt)
  self.className = "VehicleLowerImplementEvent"
  return self
end
function VehicleLowerImplementEvent:new(vehicle, jointIndex, moveDown)
  local self = VehicleLowerImplementEvent:emptyNew()
  self.jointIndex = jointIndex
  self.vehicle = vehicle
  self.moveDown = moveDown
  return self
end
function VehicleLowerImplementEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.vehicle = networkGetObject(id)
  self.jointIndex = streamReadInt8(streamId)
  self.moveDown = streamReadBool(streamId)
  self:run(connection)
end
function VehicleLowerImplementEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.vehicle))
  streamWriteInt8(streamId, self.jointIndex)
  streamWriteBool(streamId, self.moveDown)
end
function VehicleLowerImplementEvent:run(connection)
  self.vehicle:setJointMoveDown(self.jointIndex, self.moveDown, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(VehicleLowerImplementEvent:new(self.vehicle, self.jointIndex, self.moveDown), nil, connection, self.object)
  end
end
function VehicleLowerImplementEvent.sendEvent(vehicle, jointIndex, moveDown, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(VehicleLowerImplementEvent:new(vehicle, jointIndex, moveDown), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(VehicleLowerImplementEvent:new(vehicle, jointIndex, moveDown))
    end
  end
end
