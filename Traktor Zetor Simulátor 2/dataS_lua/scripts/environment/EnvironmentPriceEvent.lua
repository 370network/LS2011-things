EnvironmentPriceEvent = {}
EnvironmentPriceEvent_mt = Class(EnvironmentPriceEvent, Event)
InitStaticEventClass(EnvironmentPriceEvent, "EnvironmentPriceEvent", EventIds.EVENT_ENVIRONMENT_PRICE)
function EnvironmentPriceEvent:emptyNew()
  local self = Event:new(EnvironmentPriceEvent_mt)
  self.className = "EnvironmentPriceEvent"
  return self
end
function EnvironmentPriceEvent:new(fruits)
  local self = EnvironmentPriceEvent:emptyNew()
  self.fruits = fruits
  return self
end
function EnvironmentPriceEvent:readStream(streamId, connection)
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    local price = streamReadFloat32(streamId)
    FruitUtil.fruitIndexToDesc[i].yesterdaysPrice = FruitUtil.fruitIndexToDesc[i].pricePerLiter
    FruitUtil.fruitIndexToDesc[i].pricePerLiter = price
  end
end
function EnvironmentPriceEvent:writeStream(streamId, connection)
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    streamWriteFloat32(streamId, self.fruits[i].pricePerLiter)
  end
end
function EnvironmentPriceEvent:run(connection)
  print("The server should not receive a priceEvent update")
end
