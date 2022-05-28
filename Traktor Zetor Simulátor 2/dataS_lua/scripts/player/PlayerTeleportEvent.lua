PlayerTeleportEvent = {}
PlayerTeleportEvent_mt = Class(PlayerTeleportEvent, Event)
InitStaticEventClass(PlayerTeleportEvent, "PlayerTeleportEvent", EventIds.EVENT_PLAYER_TELEPORT)
function PlayerTeleportEvent:emptyNew()
  local self = Event:new(PlayerTeleportEvent_mt)
  self.className = "PlayerTeleportEvent"
  return self
end
function PlayerTeleportEvent:new(x, y, z)
  local self = PlayerTeleportEvent:emptyNew()
  self.x = x
  self.y = y
  self.z = z
  return self
end
function PlayerTeleportEvent:readStream(streamId, connection)
  self.x = streamReadFloat32(streamId)
  self.y = streamReadFloat32(streamId)
  self.z = streamReadFloat32(streamId)
  self:run(connection)
end
function PlayerTeleportEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.x)
  streamWriteFloat32(streamId, self.y)
  streamWriteFloat32(streamId, self.z)
end
function PlayerTeleportEvent:run(connection)
  assert(not connection:getIsServer(), "This is a client to server only event")
  local player = g_currentMission.connectionsToPlayer[connection]
  if player ~= nil then
    player:moveToAbsolute(self.x, self.y, self.z)
  end
end
