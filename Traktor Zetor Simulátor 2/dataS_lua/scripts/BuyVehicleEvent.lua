BuyVehicleEvent = {}
BuyVehicleEvent_mt = Class(BuyVehicleEvent, Event)
InitStaticEventClass(BuyVehicleEvent, "BuyVehicleEvent", EventIds.EVENT_BUY_VEHICLE)
function BuyVehicleEvent:emptyNew()
  local self = Event:new(BuyVehicleEvent_mt)
  self.className = "BuyVehicleEvent"
  return self
end
function BuyVehicleEvent:new(filename, outsideBuy)
  local self = BuyVehicleEvent:emptyNew()
  self.filename = filename
  self.outsideBuy = outsideBuy
  return self
end
function BuyVehicleEvent:newServerToClient(successful)
  local self = BuyVehicleEvent:emptyNew()
  self.successful = successful
  return self
end
function BuyVehicleEvent:readStream(streamId, connection)
  if not connection:getIsServer() then
    self.filename = Utils.convertFromNetworkFilename(streamReadString(streamId))
  else
    self.successful = streamReadBool(streamId)
  end
  self:run(connection)
end
function BuyVehicleEvent:writeStream(streamId, connection)
  if connection:getIsServer() then
    streamWriteString(streamId, Utils.convertToNetworkFilename(self.filename))
  else
    streamWriteBool(streamId, self.successful)
  end
end
function BuyVehicleEvent:run(connection)
  if not connection:getIsServer() then
    self.filename = self.filename:lower()
    local dataStoreItem
    for i = 1, table.getn(StoreItemsUtil.storeItems) do
      local item = StoreItemsUtil.storeItems[i]
      local filename = item.xmlFilename:lower()
      if filename == self.filename then
        dataStoreItem = item
        break
      end
    end
    local sent = false
    if dataStoreItem ~= nil then
      local xmlFile = loadXMLFile("TempConfig", dataStoreItem.xmlFilename)
      local sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
      local sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
      local widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
      local lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
      local usedPlaces = {}
      local x, y, z, place, width, offset = PlacementUtil.getPlace(g_currentMission.storeSpawnPlaces, sizeWidth, sizeLength, widthOffset, lengthOffset, usedPlaces)
      if x ~= nil then
        local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
        yRot = yRot + Utils.degToRad(dataStoreItem.rotation)
        local vehicle = g_currentMission:loadVehicle(dataStoreItem.xmlFilename, x, offset, z, yRot, true)
        if vehicle ~= nil and not self.outsideBuy then
          g_currentMission:addMoney(-dataStoreItem.price, g_currentMission:findUserIdByConnection(connection))
        end
        connection:sendEvent(BuyVehicleEvent:newServerToClient(true))
        sent = true
      end
    end
    if not sent then
      connection:sendEvent(BuyVehicleEvent:newServerToClient(false))
    end
  elseif self.successful then
    g_shopScreen:onVehicleBought()
  else
    g_shopScreen:onVehicleBuyFailed()
  end
end
