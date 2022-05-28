MoneyEvent = {}
MoneyEvent_mt = Class(MoneyEvent, Event)
InitStaticEventClass(MoneyEvent, "MoneyEvent", EventIds.EVENT_MONEY)
function MoneyEvent:emptyNew()
  local self = Event:new(MoneyEvent_mt)
  self.className = "MoneyEvent"
  return self
end
function MoneyEvent:new(amount)
  local self = MoneyEvent:emptyNew()
  self.amount = amount
  return self
end
function MoneyEvent:readStream(streamId, connection)
  self.amount = streamReadFloat32(streamId)
  self:run(connection)
end
function MoneyEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.amount)
end
function MoneyEvent:run(connection)
  if connection:getIsServer() then
    g_currentMission.missionStats.money = self.amount
  else
    print("Error: MoneyEvent is a server to client only event")
  end
end
