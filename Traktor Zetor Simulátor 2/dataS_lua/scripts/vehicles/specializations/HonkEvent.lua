HonkEvent = {}
HonkEvent_mt = Class(HonkEvent, Event)
InitStaticEventClass(HonkEvent, "HonkEvent", EventIds.EVENT_HONK)
function HonkEvent:emptyNew()
  local self = Event:new(HonkEvent_mt)
  self.className = "HonkEvent"
  return self
end
function HonkEvent:new(object, isPlaying)
  local self = HonkEvent:emptyNew()
  self.object = object
  self.isPlaying = isPlaying
  return self
end
function HonkEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.isPlaying = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function HonkEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isPlaying)
end
function HonkEvent:run(connection)
  self.object:playHonk(self.isPlaying, true)
  if not connection:getIsServer() then
    g_server:broadcastEvent(HonkEvent:new(self.object, self.isPlaying), nil, connection, self.object)
  end
end
function HonkEvent.sendEvent(vehicle, isPlaying, noEventSend)
  if isPlaying ~= vehicle.honkPlaying and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(HonkEvent:new(vehicle, isPlaying), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(HonkEvent:new(vehicle, isPlaying))
    end
  end
end
