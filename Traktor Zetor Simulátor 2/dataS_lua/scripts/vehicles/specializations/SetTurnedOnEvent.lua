SetTurnedOnEvent = {}
SetTurnedOnEvent_mt = Class(SetTurnedOnEvent, Event)
InitStaticEventClass(SetTurnedOnEvent, "SetTurnedOnEvent", EventIds.EVENT_SET_TURNED_ON)
function SetTurnedOnEvent:emptyNew()
  local self = Event:new(SetTurnedOnEvent_mt)
  self.className = "SetTurnedOnEvent"
  return self
end
function SetTurnedOnEvent:new(object, turnedOn)
  local self = SetTurnedOnEvent:emptyNew()
  self.object = object
  self.turnedOn = turnedOn
  return self
end
function SetTurnedOnEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.turnedOn = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function SetTurnedOnEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.turnedOn)
end
function SetTurnedOnEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  self.object:setIsTurnedOn(self.turnedOn, true)
end
function SetTurnedOnEvent.sendEvent(vehicle, turnedOn, noEventSend)
  if turnedOn ~= vehicle.isTurnedOn and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(SetTurnedOnEvent:new(vehicle, turnedOn), nil, nil, vehicle)
    else
      g_client:getServerConnection():sendEvent(SetTurnedOnEvent:new(vehicle, turnedOn))
    end
  end
end
