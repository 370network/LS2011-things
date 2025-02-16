SetMotorTurnedOnEvent = {}
SetMotorTurnedOnEvent_mt = Class(SetMotorTurnedOnEvent, Event)
InitStaticEventClass(SetMotorTurnedOnEvent, "SetMotorTurnedOnEvent", EventIds.EVENT_SET_MOTOR_TURNED_ON)
function SetMotorTurnedOnEvent:emptyNew()
  local self = Event:new(SetMotorTurnedOnEvent_mt)
  self.className = "SetMotorTurnedOnEvent"
  return self
end
function SetMotorTurnedOnEvent:new(object, turnedOn)
  local self = SetMotorTurnedOnEvent:emptyNew()
  self.object = object
  self.turnedOn = turnedOn
  return self
end
function SetMotorTurnedOnEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.turnedOn = streamReadBool(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function SetMotorTurnedOnEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.turnedOn)
end
function SetMotorTurnedOnEvent:run(connection)
  if self.turnedOn then
    self.object:startMotor(true)
  else
    self.object:stopMotor(true)
  end
  if not connection:getIsServer() then
    g_server:broadcastEvent(SetMotorTurnedOnEvent:new(self.object, self.turnedOn), nil, connection, self.object)
  end
end
