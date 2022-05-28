VehicleEnterRequestEvent = {}
VehicleEnterRequestEvent_mt = Class(VehicleEnterRequestEvent, Event)
InitStaticEventClass(VehicleEnterRequestEvent, "VehicleEnterRequestEvent", EventIds.EVENT_VEHICLE_ENTER_REQUEST)
function VehicleEnterRequestEvent:emptyNew()
  local self = Event:new(VehicleEnterRequestEvent_mt)
  self.className = "VehicleEnterRequestEvent"
  return self
end
function VehicleEnterRequestEvent:new(object, controllerName)
  local self = VehicleEnterRequestEvent:emptyNew()
  self.object = object
  self.objectId = networkGetObjectId(self.object)
  self.controllerName = controllerName
  return self
end
function VehicleEnterRequestEvent:readStream(streamId, connection)
  self.objectId = streamReadInt32(streamId)
  self.controllerName = streamReadString(streamId)
  self.object = networkGetObject(self.objectId)
  self:run(connection)
end
function VehicleEnterRequestEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, self.objectId)
  streamWriteString(streamId, self.controllerName)
end
function VehicleEnterRequestEvent:run(connection)
  if self.object.isControlled == false then
    self.object:setOwner(connection)
    g_server:broadcastEvent(VehicleEnterResponseEvent:new(self.objectId, false, self.controllerName), true, connection, self.object)
    connection:sendEvent(VehicleEnterResponseEvent:new(self.objectId, true))
    if not self.object.isEntered then
      self.object:onEnter(false)
    end
  end
end
