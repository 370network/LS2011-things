BuyCowEvent = {}
BuyCowEvent_mt = Class(BuyCowEvent, Event)
InitStaticEventClass(BuyCowEvent, "BuyCowEvent", EventIds.EVENT_BUY_COW)
function BuyCowEvent:emptyNew()
  local self = Event:new(BuyCowEvent_mt)
  self.className = "BuyCowEvent"
  return self
end
function BuyCowEvent:new(animalName, animalIsVisible, animalPositionX, animalPositionY, animalPositionZ, animalDirectionX, animalDirectionY, animalDirectionZ, appearanceId, isIssuer)
  local self = BuyCowEvent:emptyNew()
  self.animalName = animalName
  self.animalIsVisible = animalIsVisible
  self.animalPositionX, self.animalPositionY, self.animalPositionZ = animalPositionX, animalPositionY, animalPositionZ
  self.animalDirectionX, self.animalDirectionY, self.animalDirectionZ = animalDirectionX, animalDirectionY, animalDirectionZ
  self.appearanceId = appearanceId
  self.isIssuer = isIssuer
  return self
end
function BuyCowEvent:readStream(streamId, connection)
  if connection:getIsServer() then
    self.animalName = streamReadString(streamId)
    self.animalIsVisible = streamReadBool(streamId)
    if self.animalIsVisible then
      self.animalPositionX, self.animalPositionY, self.animalPositionZ = streamReadFloat32(streamId), streamReadFloat32(streamId), streamReadFloat32(streamId)
      self.animalDirectionX, self.animalDirectionY, self.animalDirectionZ = streamReadFloat32(streamId), streamReadFloat32(streamId), streamReadFloat32(streamId)
      self.appearanceId = streamReadUIntN(streamId, 3)
    end
    self.isIssuer = streamReadBool(streamId)
  end
  self:run(connection)
end
function BuyCowEvent:writeStream(streamId, connection)
  if not connection:getIsServer() then
    streamWriteString(streamId, self.animalName)
    streamWriteBool(streamId, self.animalIsVisible)
    if self.animalIsVisible then
      streamWriteFloat32(streamId, self.animalPositionX)
      streamWriteFloat32(streamId, self.animalPositionY)
      streamWriteFloat32(streamId, self.animalPositionZ)
      streamWriteFloat32(streamId, self.animalDirectionX)
      streamWriteFloat32(streamId, self.animalDirectionY)
      streamWriteFloat32(streamId, self.animalDirectionZ)
      streamWriteUIntN(streamId, self.appearanceId, 3)
    end
    streamWriteBool(streamId, self.isIssuer)
  end
end
function BuyCowEvent:run(connection)
  if not connection:getIsServer() then
    local dataStoreItem
    for i = 1, table.getn(StoreItemsUtil.storeItems) do
      if StoreItemsUtil.storeItems[i].species ~= nil and StoreItemsUtil.storeItems[i].species == "cow" then
        dataStoreItem = StoreItemsUtil.storeItems[i]
        break
      end
    end
    local animalName = AnimalHusbandry.addAnimal()
    local animal, animalIsVisible = AnimalHusbandry.herd:getAnimalByName(animalName)
    local posX, posY, posZ, dirX, dirY, dirZ, appearanceId
    if animalIsVisible then
      posX, posY, posZ = animal:getPosition()
      dirX, dirY, dirZ = animal:getDirection()
      appearanceId = animal.appearanceId
    end
    g_currentMission:addMoney(-dataStoreItem.price, g_currentMission:findUserIdByConnection(connection))
    g_server:broadcastEvent(BuyCowEvent:new(animalName, animalIsVisible, posX, posY, posZ, dirX, dirY, dirZ, appearanceId, false), nil, connection)
    connection:sendEvent(BuyCowEvent:new(animalName, animalIsVisible, posX, posY, posZ, dirX, dirY, dirZ, appearanceId, true))
  else
    if g_server == nil then
      AnimalHusbandry.addAnimal(self.animalName, self.animalPositionX, self.animalPositionY, self.animalPositionZ, self.animalDirectionX, self.animalDirectionY, self.animalDirectionZ, self.appearanceId, self.animalIsVisible)
    end
    if self.isIssuer then
      g_shopScreen:onCowBought(self.animalName, self.animalPositionX, self.animalPositionY, self.animalPositionZ, self.animalDirectionX, self.animalDirectionY, self.animalDirectionZ, self.appearanceId, self.animalIsVisible)
    end
  end
end
