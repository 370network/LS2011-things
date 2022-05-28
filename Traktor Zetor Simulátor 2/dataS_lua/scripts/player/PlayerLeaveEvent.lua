PlayerLeaveEvent = {}
PlayerLeaveEvent_mt = Class(PlayerLeaveEvent, Event)
InitStaticEventClass(PlayerLeaveEvent, "PlayerLeaveEvent", EventIds.EVENT_PLAYER_LEAVE)
function PlayerLeaveEvent:emptyNew()
  local self = Event:new(PlayerLeaveEvent_mt)
  self.className = "PlayerLeaveEvent"
  return self
end
function PlayerLeaveEvent:new(object)
  local self = PlayerLeaveEvent:emptyNew()
  self.object = object
  return self
end
function PlayerLeaveEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function PlayerLeaveEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function PlayerLeaveEvent:run(connection)
  self.object:onLeave()
  if not connection:getIsServer() then
    if self.object.owner ~= nil then
      self.object:setOwner(nil)
    end
    g_server:broadcastEvent(PlayerLeaveEvent:new(self.object), nil, connection, self.object)
  end
end
