BaseMissionSetFruitAmount = {}
BaseMissionSetFruitAmount_mt = Class(BaseMissionSetFruitAmount, Event)
InitStaticEventClass(BaseMissionSetFruitAmount, "BaseMissionSetFruitAmount", EventIds.EVENT_SET_FRUIT_AMOUNT)
function BaseMissionSetFruitAmount:emptyNew()
  local self = Event:new(BaseMissionSetFruitAmount_mt)
  self.className = "BaseMissionSetFruitAmount"
  return self
end
function BaseMissionSetFruitAmount:new(fillType, amount)
  local self = BaseMissionSetFruitAmount:emptyNew()
  self.fillType = fillType
  self.amount = amount
  return self
end
function BaseMissionSetFruitAmount:readStream(streamId, connection)
  self.fillType = streamReadUIntN(streamId, Fillable.sendNumBits)
  self.amount = streamReadFloat32(streamId)
  self:run(connection)
end
function BaseMissionSetFruitAmount:writeStream(streamId, connection)
  streamWriteUIntN(streamId, self.fillType, Fillable.sendNumBits)
  streamWriteFloat32(streamId, self.amount)
end
function BaseMissionSetFruitAmount:run(connection)
  g_currentMission:setSiloAmountInternal(self.fillType, self.amount)
end
