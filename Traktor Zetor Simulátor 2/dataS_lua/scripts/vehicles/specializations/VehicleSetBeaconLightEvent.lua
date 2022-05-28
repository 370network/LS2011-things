VehicleSetBeaconLightEvent = {}
VehicleSetBeaconLightEvent_mt = Class(VehicleSetBeaconLightEvent, Event)
InitStaticEventClass(VehicleSetBeaconLightEvent, "VehicleSetBeaconLightEvent", EventIds.EVENT_VEHICLE_SET_BEACON_LIGHT)
function VehicleSetBeaconLightEvent:emptyNew()
  local self = Event:new(VehicleSetBeaconLightEvent_mt)
  self.className = "VehicleSetBeaconLightEvent"
  return self
end
function VehicleSetBeaconLightEvent:new(object, active)
  local self = VehicleSetBeaconLightEvent:emptyNew()
  self.active = active
  self.object = object
  return self
end
function VehicleSetBeaconLightEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.active = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function VehicleSetBeaconLightEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.active)
end
function VehicleSetBeaconLightEvent:run(connection)
  self.object:setBeaconLightsVisibility(self.active, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(VehicleSetBeaconLightEvent:new(self.object, self.active), nil, connection, self.object)
  end
end
