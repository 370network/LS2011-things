SowingMachineSetSeedIndex = {}
SowingMachineSetSeedIndex_mt = Class(SowingMachineSetSeedIndex, Event)
InitStaticEventClass(SowingMachineSetSeedIndex, "SowingMachineSetSeedIndex", EventIds.EVENT_SOWING_MACHINE_SET_SEED_INDEX)
function SowingMachineSetSeedIndex:emptyNew()
  local self = Event:new(SowingMachineSetSeedIndex_mt)
  self.className = "SowingMachineSetSeedIndex"
  return self
end
function SowingMachineSetSeedIndex:new(object, seedIndex)
  local self = SowingMachineSetSeedIndex:emptyNew()
  self.object = object
  self.seedIndex = seedIndex
  return self
end
function SowingMachineSetSeedIndex:readStream(streamId, connection)
  self.object = networkGetObject(streamReadInt32(streamId))
  self.seedIndex = streamReadUInt8(streamId)
  self:run(connection)
end
function SowingMachineSetSeedIndex:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteUInt8(streamId, self.seedIndex)
end
function SowingMachineSetSeedIndex:run(connection)
  if not connection:getIsServer() then
    g_server:broadcastEvent(self, false, connection, self.object)
  end
  self.object:setSeedIndex(self.seedIndex, true)
end
function SowingMachineSetSeedIndex.sendEvent(object, seedIndex, noEventSend)
  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(SowingMachineSetSeedIndex:new(object, seedIndex), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(SowingMachineSetSeedIndex:new(object, seedIndex))
    end
  end
end
