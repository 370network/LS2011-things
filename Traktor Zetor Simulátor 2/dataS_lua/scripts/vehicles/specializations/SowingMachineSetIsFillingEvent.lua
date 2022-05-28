SowingMachineSetIsFillingEvent = {}
SowingMachineSetIsFillingEvent_mt = Class(SowingMachineSetIsFillingEvent, Event)
InitStaticEventClass(SowingMachineSetIsFillingEvent, "SowingMachineSetIsFillingEvent", EventIds.EVENT_SOWING_MACHINE_SET_IS_FILLING)
function SowingMachineSetIsFillingEvent:emptyNew()
  local self = Event:new(SowingMachineSetIsFillingEvent_mt)
  self.className = "SowingMachineSetIsFillingEvent"
  return self
end
function SowingMachineSetIsFillingEvent:new(object, isFilling)
  local self = SowingMachineSetIsFillingEvent:emptyNew()
  self.object = object
  self.isFilling = isFilling
  return self
end
function SowingMachineSetIsFillingEvent:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.isFilling = streamReadBool(streamId)
  self:run(connection)
end
function SowingMachineSetIsFillingEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteBool(streamId, self.isFilling)
end
function SowingMachineSetIsFillingEvent:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  self.object:setIsSowingMachineFilling(self.isFilling, true)
end
function SowingMachineSetIsFillingEvent.sendEvent(object, isFilling, noEventSend)
  if isFilling ~= object.isSowingMachineFilling and (noEventSend == nil or noEventSend == false) then
    if g_server ~= nil then
      g_server:broadcastEvent(SowingMachineSetIsFillingEvent:new(object, isFilling), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(SowingMachineSetIsFillingEvent:new(object, isFilling))
    end
  end
end
