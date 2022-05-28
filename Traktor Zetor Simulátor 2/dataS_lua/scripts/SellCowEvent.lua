SellCowEvent = {}
SellCowEvent_mt = Class(SellCowEvent, Event)
InitStaticEventClass(SellCowEvent, "SellCowEvent", EventIds.EVENT_SELL_COW)
function SellCowEvent:emptyNew()
  local self = Event:new(SellCowEvent_mt)
  self.className = "SellCowEvent"
  return self
end
function SellCowEvent:new(isIssuer, successful, animalName)
  local self = SellCowEvent:emptyNew()
  self.animalName = animalName
  self.isIssuer = isIssuer
  self.successful = successful
  return self
end
function SellCowEvent:readStream(streamId, connection)
  if connection:getIsServer() then
    self.isIssuer = streamReadBool(streamId)
    self.successful = streamReadBool(streamId)
    if self.successful then
      self.animalName = streamReadString(streamId)
    end
  end
  self:run(connection)
end
function SellCowEvent:writeStream(streamId, connection)
  if not connection:getIsServer() then
    streamWriteBool(streamId, self.isIssuer)
    streamWriteBool(streamId, self.successful)
    if self.successful then
      streamWriteString(streamId, self.animalName)
    end
  end
end
function SellCowEvent:run(connection)
  if not connection:getIsServer() then
    local dataStoreItem
    if connection:getIsLocal() or g_currentMission.allowClientsSellVehicles then
      for i = 1, table.getn(StoreItemsUtil.storeItems) do
        if StoreItemsUtil.storeItems[i].species ~= nil and StoreItemsUtil.storeItems[i].species == "cow" then
          dataStoreItem = StoreItemsUtil.storeItems[i]
          break
        end
      end
    end
    if dataStoreItem ~= nil and AnimalHusbandry.canRemoveAnimal() then
      local animalName = AnimalHusbandry.herd.animals[1].name
      AnimalHusbandry.removeAnimal()
      g_currentMission:addSharedMoney(g_shopScreen:getSellPrice(dataStoreItem))
      g_server:broadcastEvent(SellCowEvent:new(false, true, animalName), nil, connection)
      connection:sendEvent(SellCowEvent:new(true, true, animalName))
    else
      connection:sendEvent(SellCowEvent:new(true, false, animalName))
    end
  else
    if self.successful and g_server == nil then
      AnimalHusbandry.removeAnimal()
    end
    if self.isIssuer then
      if self.successful then
        g_shopScreen:onCowSold(self.animalName)
      else
        g_shopScreen:onCowSellFailed(self.animalName)
      end
    end
  end
end
