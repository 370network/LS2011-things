PloughRotationEvent = {}
PloughRotationEvent_mt = Class(PloughRotationEvent, Event)
InitStaticEventClass(PloughRotationEvent, "PloughRotationEvent", EventIds.EVENT_PLOUGH_ROTATION)
function PloughRotationEvent:emptyNew()
  local self = Event:new(PloughRotationEvent_mt)
  self.className = "PloughRotationEvent"
  return self
end
function PloughRotationEvent:new(object, rotationMax)
  local self = PloughRotationEvent:emptyNew()
  self.object = object
  self.rotationMax = rotationMax
  return self
end
function PloughRotationEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.rotationMax = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function PloughRotationEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.rotationMax)
end
function PloughRotationEvent:run(connection)
  self.object:setRotationMax(self.rotationMax, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(PloughRotationEvent:new(self.object, self.rotationMax), nil, connection, self.object)
  end
end
