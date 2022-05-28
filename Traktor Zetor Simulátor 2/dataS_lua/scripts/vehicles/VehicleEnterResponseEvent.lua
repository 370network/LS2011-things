VehicleEnterResponseEvent = {}
VehicleEnterResponseEvent_mt = Class(VehicleEnterResponseEvent, Event)
InitStaticEventClass(VehicleEnterResponseEvent, "VehicleEnterResponseEvent", EventIds.EVENT_VEHICLE_ENTER_RESPONSE)
function VehicleEnterResponseEvent:emptyNew()
  local self = Event:new(VehicleEnterResponseEvent_mt)
  self.className = "VehicleEnterResponseEvent"
  self.eventId = EventIds.EVENT_VEHICLE_ENTER_RESPONSE
  return self
end
function VehicleEnterResponseEvent:new(id, isOwner, controllerName)
  local self = VehicleEnterResponseEvent:emptyNew()
  self.id = id
  self.isOwner = isOwner
  self.controllerName = controllerName
  return self
end
function VehicleEnterResponseEvent:readStream(streamId, connection)
  self.id = streamReadInt32(streamId)
  self.isOwner = streamReadBool(streamId)
  if not self.isOwner then
    self.controllerName = streamReadString(streamId)
  end
  self:run(connection)
end
function VehicleEnterResponseEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, self.id)
  streamWriteBool(streamId, self.isOwner)
  if not self.isOwner then
    streamWriteString(streamId, self.controllerName)
  end
end
function VehicleEnterResponseEvent:run(connection)
  local object = networkGetObject(self.id)
  if self.isOwner then
    g_currentMission:onEnterVehicle(object)
  else
    if not object.isEntered then
      object:onEnter(false)
    end
    object.controllerName = self.controllerName
  end
end
