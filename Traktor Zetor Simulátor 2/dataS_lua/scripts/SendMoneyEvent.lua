SendMoneyEvent = {}
SendMoneyEvent_mt = Class(SendMoneyEvent, Event)
InitStaticEventClass(SendMoneyEvent, "SendMoneyEvent", EventIds.EVENT_SEND_MONEY)
function SendMoneyEvent:emptyNew()
  local self = Event:new(SendMoneyEvent_mt)
  self.className = "SendMoneyEvent"
  return self
end
function SendMoneyEvent:new(amount, userId)
  local self = SendMoneyEvent:emptyNew()
  self.amount = amount
  self.userId = userId
  return self
end
function SendMoneyEvent:readStream(streamId, connection)
  self.amount = streamReadFloat32(streamId)
  self.userId = streamReadInt32(streamId)
  self:run(connection)
end
function SendMoneyEvent:writeStream(streamId, connection)
  streamWriteFloat32(streamId, self.amount)
  streamWriteInt32(streamId, self.userId)
end
function SendMoneyEvent:run(connection)
  if not connection:getIsServer() then
    local senderUserId = g_currentMission:findUserIdByConnection(connection)
    if 0 <= senderUserId then
      local senderMoney = g_currentMission:getMoney(senderUserId)
      if senderMoney >= self.amount then
        g_currentMission:addMoney(-self.amount, senderUserId)
        g_currentMission:addMoney(self.amount, self.userId)
      end
    end
  else
    print("Error: SendMoneyEvent is a client to server only event")
  end
end
