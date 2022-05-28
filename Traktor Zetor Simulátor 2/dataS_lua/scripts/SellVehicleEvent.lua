SellVehicleEvent = {}
SellVehicleEvent_mt = Class(SellVehicleEvent, Event)
InitStaticEventClass(SellVehicleEvent, "SellVehicleEvent", EventIds.EVENT_SELL_VEHICLE)
function SellVehicleEvent:emptyNew()
  local self = Event:new(SellVehicleEvent_mt)
  self.className = "SellVehicleEvent"
  return self
end
function SellVehicleEvent:new(filename)
  local self = SellVehicleEvent:emptyNew()
  self.filename = filename
  return self
end
function SellVehicleEvent:newServerToClient(successful)
  local self = SellVehicleEvent:emptyNew()
  self.successful = successful
  return self
end
function SellVehicleEvent:readStream(streamId, connection)
  if not connection:getIsServer() then
    self.filename = Utils.convertFromNetworkFilename(streamReadString(streamId))
  else
    self.successful = streamReadBool(streamId)
  end
  self:run(connection)
end
function SellVehicleEvent:writeStream(streamId, connection)
  if connection:getIsServer() then
    streamWriteString(streamId, Utils.convertToNetworkFilename(self.filename))
  else
    streamWriteBool(streamId, self.successful)
  end
end
function SellVehicleEvent:run(connection)
  if not connection:getIsServer() then
    self.filename = self.filename:lower()
    local dataStoreItem
    if connection:getIsLocal() or g_currentMission.allowClientsSellVehicles then
      for i = 1, table.getn(StoreItemsUtil.storeItems) do
        local item = StoreItemsUtil.storeItems[i]
        local filename = item.xmlFilename:lower()
        if filename == self.filename then
          dataStoreItem = item
          break
        end
      end
    end
    local sent = false
    if dataStoreItem ~= nil then
      for k, v in pairs(g_currentMission.vehicles) do
        if v.configFileName:lower() == self.filename and (not v.isControlled or v.isEntered and v.owner == connection) then
          g_currentMission:removeVehicle(v)
          g_currentMission:addSharedMoney(g_shopScreen:getSellPrice(dataStoreItem))
          connection:sendEvent(SellVehicleEvent:newServerToClient(true))
          sent = true
          break
        end
      end
    end
    if not sent then
      connection:sendEvent(SellVehicleEvent:newServerToClient(false))
    end
  elseif self.successful then
    g_shopScreen:onVehicleSold()
  else
    g_shopScreen:onVehicleSellFailed()
  end
end
