PlayerEnterEvent = {}
PlayerEnterEvent_mt = Class(PlayerEnterEvent, Event)
InitStaticEventClass(PlayerEnterEvent, "PlayerEnterEvent", EventIds.EVENT_PLAYER_ENTER)
function PlayerEnterEvent:emptyNew()
  local self = Event:new(PlayerEnterEvent_mt)
  self.className = "PlayerEnterEvent"
  return self
end
function PlayerEnterEvent:new(object, exitVehicle)
  local self = PlayerEnterEvent:emptyNew()
  self.object = object
  self.exitVehicle = exitVehicle
  return self
end
function PlayerEnterEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  local vehicleId = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self.exitVehicle = networkGetObject(vehicleId)
  self:run(connection)
end
function PlayerEnterEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt32(streamId, networkGetObjectId(self.exitVehicle))
end
function PlayerEnterEvent:run(connection)
  if not connection:getIsServer() then
    self.object:setOwner(connection)
    self.object:moveToExitPoint(self.exitVehicle)
    g_server:broadcastEvent(PlayerEnterEvent:new(self.object, self.exitVehicle), nil, connection, self.object)
  end
  if not self.object.isEntered then
    self.object:onEnter(false)
  end
end
