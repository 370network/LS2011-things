source("dataS/scripts/SellCowEvent.lua")
source("dataS/scripts/SellVehicleEvent.lua")
source("dataS/scripts/BuyCowEvent.lua")
source("dataS/scripts/BuyVehicleEvent.lua")
ShopScreen = {}
local ShopScreen_mt = Class(ShopScreen)
function ShopScreen:new()
  local self = GuiElement:new(target, ShopScreen_mt)
  self.createVehicleIconIndex = 1
  self.createVehicleTextIndex = 1
  self.upButton = nil
  self.downButton = nil
  self.buyButtons = {}
  self.sellButtons = {}
  self.storeItems = StoreItemsUtil.storeItems
  self.sectionList = {
    "section_tractors",
    "section_combines",
    "section_trailers",
    "section_tools",
    "section_misc",
    "section_animals",
    "section_mods"
  }
  self.selectedSection = 1
  for i, sectionName in ipairs(self.sectionList) do
    if sectionName == "section_animals" then
      self.animalsSectionId = i
    end
  end
  self.buyButtonList = {}
  self.sellButtonList = {}
  self.messageTextSpeed = 500
  self.messageTextTime = 0
  self.messageTextColorDirection = 1
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    1,
    1,
    1,
    1
  }
  self.usedPlaces = {}
  self.time = 0
  self.isSelling = false
  return self
end
function ShopScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function ShopScreen:onOpen()
  self.lastMoney = g_currentMission.missionStats.money
  self.usedPlaces = {}
  self:updateOwnedVehicles()
  self:updateList()
  self:updateCapitalText()
  self.messageText.text = ""
  InputBinding.setShowMouseCursor(true)
  self:updateFocusLinkageSystem()
  FocusManager:setFocus(FocusManager:getElementById("6"))
  self.isOpen = true
end
function ShopScreen:onClose()
  self.isOpen = false
  InputBinding.setShowMouseCursor(false)
end
function ShopScreen:updateOwnedVehicles()
  self.numOwnedVehicles = {}
  for k, v in pairs(g_currentMission.vehicles) do
    local filename = v.configFileName:lower()
    self.numOwnedVehicles[filename] = Utils.getNoNil(self.numOwnedVehicles[filename], 0) + 1
  end
end
function ShopScreen:updateList()
  self.list1:deleteListItems()
  self.buyButtonList = {}
  self.sellButtonList = {}
  for i = 1, table.getn(StoreItemsUtil.storeItems) do
    self.currentItem = StoreItemsUtil.storeItems[i]
    if self.currentItem.achievementsNeeded <= 100 * (g_achievementManager.numberOfUnlockedAchievements / g_achievementManager.numberOfAchievements) and self.currentItem.section == self.sectionList[self.selectedSection] then
      local newListItem = self.listItem1Template:clone(self.list1)
      newListItem:updateAbsolutePosition()
      local index = self.list1:getNumRows()
      local buyButton = newListItem.elements[6]
      FocusManager:loadElementFromCustomValues(buyButton, string.format("listItem" .. index .. "-" .. "1"), {}, false, false)
      local sellButton = newListItem.elements[7]
      FocusManager:loadElementFromCustomValues(sellButton, string.format("listItem" .. index .. "-" .. "2"), {}, false, false)
      if FocusManager.currentFocusData.focusElement then
        if FocusManager.currentFocusData.focusElement.focusId == buyButton.focusId then
          FocusManager.currentFocusData.focusElement = buyButton
        elseif FocusManager.currentFocusData.focusElement.focusId == sellButton.focusId then
          FocusManager.currentFocusData.focusElement = sellButton
        end
      end
    end
    self.currentItem = nil
  end
  self:updateBuyAndSellButtons()
  self:updateFocusLinkageSystem()
end
function ShopScreen:updateBuyAndSellButtons()
  for _, buyButton in pairs(self.buyButtonList) do
    buyButton.disabled = false
    if buyButton.shopItem.price > g_currentMission.missionStats.money then
      buyButton.disabled = true
    end
    if self.selectedSection == self.animalsSectionId and not AnimalHusbandry.isInUse then
      buyButton.disabled = true
    end
  end
  for _, sellButton in pairs(self.sellButtonList) do
    sellButton.disabled = true
    local dataStoreItem = sellButton.shopItem
    if dataStoreItem.species ~= nil and dataStoreItem.species ~= "" then
      if dataStoreItem.species == "cow" and self.selectedSection == self.animalsSectionId and AnimalHusbandry.isInUse and AnimalHusbandry.canRemoveAnimal() then
        sellButton.disabled = false
      end
    else
      local filename = dataStoreItem.xmlFilename:lower()
      if self.numOwnedVehicles[filename] ~= nil and self.numOwnedVehicles[filename] > 0 then
        sellButton.disabled = false
      end
    end
  end
end
function ShopScreen:updateFocusLinkageSystem()
  local focusElementsList = {}
  local positionDataHash = {}
  local rootElement = FocusManager:getFocusedElement()
  local minListIndex = self.list1.firstVisibleItem
  local maxListIndex = math.min(self.list1:getNumRows(), self.list1.firstVisibleItem + self.list1.visibleItems - 1)
  for i = minListIndex, maxListIndex do
    local buyButton = FocusManager:getElementById("listItem" .. i .. "-" .. "1")
    local sellButton = FocusManager:getElementById("listItem" .. i .. "-" .. "2")
    table.insert(focusElementsList, buyButton)
    table.insert(focusElementsList, sellButton)
    if rootElement == buyButton and not buyButton:canReceiveFocus() and sellButton:canReceiveFocus() then
      rootElement = sellButton
    elseif rootElement == sellButton and not sellButton:canReceiveFocus() and buyButton:canReceiveFocus() then
      rootElement = buyButton
    end
  end
  local upButton = FocusManager:getElementById("1")
  local downButton = FocusManager:getElementById("5")
  local backButton = FocusManager:getElementById("6")
  local previousGroupButton = FocusManager:getElementById("2")
  local nextGroupButton = FocusManager:getElementById("3")
  table.insert(focusElementsList, upButton)
  table.insert(focusElementsList, downButton)
  table.insert(focusElementsList, backButton)
  table.insert(focusElementsList, previousGroupButton)
  table.insert(focusElementsList, nextGroupButton)
  rootElement = rootElement:canReceiveFocus() and rootElement or backButton
  FocusManager.focusSystemMadeChanges = true
  FocusManager:createLinkageSystemForElements(focusElementsList, rootElement, positionDataHash)
  FocusManager.focusSystemMadeChanges = false
end
function ShopScreen:onCreateSectionText(element)
  self.sectionText = element
  self:updateSectionText()
end
function ShopScreen:updateSectionText()
  self.sectionText:setText(g_i18n:getText(self.sectionList[self.selectedSection]))
end
function ShopScreen:onCreateList(element)
  self.list1 = element
end
function ShopScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function ShopScreen:onCreateIcon(element)
  if self.currentItem ~= nil then
    element:setImageFilename(self.currentItem.imageActive)
  end
end
function ShopScreen:onCreateTitleText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.name)
  end
end
function ShopScreen:onCreateCapitalText(element)
  self.capitalText = element
end
function ShopScreen:onCreateMessageText(element)
  self.messageText = element
end
function ShopScreen:updateCapitalText()
  if g_currentMission ~= nil then
    self.capitalText:setText(g_i18n:getText("Capital") .. ": " .. g_i18n:getText("Currency_symbol") .. " " .. string.format("%1.0f", g_i18n:getCurrency(g_currentMission.missionStats.money)))
  end
end
function ShopScreen:onCreateDescText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.description)
  end
end
function ShopScreen:onCreateSellPriceText(element)
  if self.currentItem ~= nil then
    local sellPrice = self:getSellPrice(self.currentItem)
    element:setText(g_i18n:getText("Currency_symbol") .. " " .. tostring(sellPrice))
  end
end
function ShopScreen:onCreateBuyPriceText(element)
  if self.currentItem ~= nil then
    element:setText(g_i18n:getText("Currency_symbol") .. " " .. tostring(self.currentItem.price))
  end
end
function ShopScreen:onCreateSpecsText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.specs)
  end
end
function ShopScreen:onCreateBuyButton(element)
  if self.currentItem ~= nil then
    do
      local currentItem = self.currentItem
      function element.onClick(unused)
        self:onBuyClick(currentItem, false)
      end
      element.shopItem = self.currentItem
      table.insert(self.buyButtonList, element)
    end
  end
  element:setDisabled(true)
end
function ShopScreen:onCreateSellButton(element)
  if self.currentItem ~= nil then
    do
      local currentItem = self.currentItem
      function element.onClick(unused)
        self:onSellClick(currentItem)
      end
      element.shopItem = self.currentItem
      table.insert(self.sellButtonList, element)
    end
  end
end
function ShopScreen:onUpButtonCreate(element)
  self.upButton = element
end
function ShopScreen:onDownButtonCreate(element)
  self.downButton = element
end
function ShopScreen:onLeftButtonCreate(element)
  self.leftButton = element
end
function ShopScreen:onRightButtonCreate(element)
  self.rightButton = element
end
function ShopScreen:onUpClick()
  self.list1:scrollList(-1)
end
function ShopScreen:onDownClick()
  self.list1:scrollList(1)
end
function ShopScreen:onLeftClick()
  self.selectedSection = self.selectedSection - 1
  if self.selectedSection == 0 then
    self.selectedSection = #self.sectionList
  end
  self:onCategorySelectionChanged()
end
function ShopScreen:onRightClick()
  self.selectedSection = self.selectedSection + 1
  if self.selectedSection > #self.sectionList then
    self.selectedSection = 1
  end
  self:onCategorySelectionChanged()
end
function ShopScreen:onCategorySelectionChanged()
  self:updateSectionText()
  self:updateList()
  self.list1:setSelectedRow(1)
  self.list1:scrollList(0)
  if self.selectedSection == self.animalsSectionId and not AnimalHusbandry.isInUse then
    self.messageTextColor1 = {
      1,
      1,
      1,
      1
    }
    self.messageTextColor2 = {
      0,
      0.85,
      0.15,
      1
    }
    self.messageText.text = g_i18n:getText("StoreNoCowsInMission")
    self:updateCapitalText()
  end
end
function ShopScreen:onBackClick()
  if self.isSelling then
    return
  end
  g_gui:showGui("")
end
function ShopScreen:onItemListScrolled()
  self:updateFocusLinkageSystem()
end
function ShopScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function ShopScreen:update(dt)
  self.time = self.time + dt
  self.messageTextTime = self.messageTextTime + self.messageTextColorDirection * dt
  if self.messageTextTime > self.messageTextSpeed then
    self.messageTextTime = self.messageTextSpeed
    self.messageTextColorDirection = -self.messageTextColorDirection
  end
  if self.messageTextTime < 0 then
    self.messageTextTime = 0
    self.messageTextColorDirection = -self.messageTextColorDirection
  end
  for i = 1, 4 do
    local ratio = self.messageTextTime / self.messageTextSpeed
    self.messageText.textColor[i] = (1 - ratio) * self.messageTextColor1[i] + self.messageTextColor2[i] * ratio
  end
  if self.lastMoney ~= g_currentMission.missionStats.money then
    self:onMoneyChanged()
  end
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function ShopScreen:draw()
  if g_currentCareerGame ~= nil then
    g_currentCareerGame:renderStats()
  end
end
function ShopScreen:onCowBought(animalName)
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    0,
    0.85,
    0.15,
    1
  }
  self.messageText.text = string.format(g_i18n:getText("StoreBoughtCow"), animalName)
  self:updateCapitalText()
  self.isBuying = false
end
function ShopScreen:onVehicleBought()
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    0,
    0.85,
    0.15,
    1
  }
  self.messageText.text = g_i18n:getText("StorePurchaseReady")
  self:updateOwnedVehicles()
  self:updateCapitalText()
  self.isBuying = false
end
function ShopScreen:onVehicleBuyFailed()
  self.messageTextColor1 = {
    1,
    1,
    0.25,
    1
  }
  self.messageTextColor2 = {
    0.75,
    0,
    0,
    1
  }
  self.messageText.text = g_i18n:getText("StoreNoSpace")
  self:updateCapitalText()
  self.isBuying = false
end
function ShopScreen:onBuyClick(item, outsideBuy)
  if self.isSelling then
    return
  end
  local dataStoreItem = item
  if outsideBuy or g_currentMission.missionStats.money >= dataStoreItem.price then
    if dataStoreItem.species ~= nil and dataStoreItem.species ~= "" then
      if dataStoreItem.species == "cow" then
        g_client:getServerConnection():sendEvent(BuyCowEvent:new())
        self:updateCapitalText()
      end
    elseif g_currentMission.missionDynamicInfo.isMultiplayer then
      local filename = dataStoreItem.xmlFilename:lower()
      self.isBuying = true
      self.messageTextColor1 = {
        1,
        1,
        1,
        1
      }
      self.messageTextColor2 = {
        0,
        0.85,
        0.15,
        1
      }
      self.messageText.text = g_i18n:getText("StoreBuyingVehicle")
      g_client:getServerConnection():sendEvent(BuyVehicleEvent:new(filename, outsideBuy))
    else
      local xmlFile = loadXMLFile("TempConfig", dataStoreItem.xmlFilename)
      local sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
      local sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
      local widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
      local lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
      local x, y, z, place, width, offset = PlacementUtil.getPlace(g_currentMission.storeSpawnPlaces, sizeWidth, sizeLength, widthOffset, lengthOffset, self.usedPlaces)
      if x ~= nil then
        local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
        yRot = yRot + Utils.degToRad(dataStoreItem.rotation)
        local vehicle = g_currentMission:loadVehicle(dataStoreItem.xmlFilename, x, offset, z, yRot, true)
        if vehicle ~= nil then
          PlacementUtil.markPlaceUsed(self.usedPlaces, place, width)
          if not outsideBuy then
            g_currentMission:addMoney(-dataStoreItem.price)
          end
          self:updateCapitalText()
          local filename = dataStoreItem.xmlFilename:lower()
          self.numOwnedVehicles[filename] = Utils.getNoNil(self.numOwnedVehicles[filename], 0) + 1
        end
        self.messageTextColor1 = {
          1,
          1,
          1,
          1
        }
        self.messageTextColor2 = {
          0,
          0.85,
          0.15,
          1
        }
        self.messageText.text = g_i18n:getText("StorePurchaseReady")
      else
        self.messageTextColor1 = {
          1,
          1,
          0.25,
          1
        }
        self.messageTextColor2 = {
          0.75,
          0,
          0,
          1
        }
        self.messageText.text = g_i18n:getText("StoreNoSpace")
      end
    end
  end
  if not outsideBuy then
    self:updateBuyAndSellButtons()
    self:updateFocusLinkageSystem()
  end
end
function ShopScreen:onCowSold(animalName)
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    0,
    0.85,
    0.15,
    1
  }
  self.messageText.text = string.format(g_i18n:getText("StoreSoldCow"), animalName)
  self:updateCapitalText()
  self.isSelling = false
end
function ShopScreen:onCowSellFailed()
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    0,
    0.85,
    0.15,
    1
  }
  self.messageText.text = g_i18n:getText("StoreCannotSellCows")
  self:updateCapitalText()
  self.isSelling = false
end
function ShopScreen:onVehicleSold()
  self.messageTextColor1 = {
    1,
    1,
    1,
    1
  }
  self.messageTextColor2 = {
    0,
    0.85,
    0.15,
    1
  }
  self.messageText.text = g_i18n:getText("StoreSoldVehicle")
  self:updateOwnedVehicles()
  self:updateCapitalText()
  self.isSelling = false
end
function ShopScreen:onVehicleSellFailed()
  self.messageTextColor1 = {
    1,
    1,
    0.25,
    1
  }
  self.messageTextColor2 = {
    0.75,
    0,
    0,
    1
  }
  self.messageText.text = g_i18n:getText("StoreFailedToSellVehicle")
  self:updateCapitalText()
  self.isSelling = false
end
function ShopScreen:onSellClick(item)
  if self.isSelling then
    return
  end
  local dataStoreItem = item
  if dataStoreItem.species ~= nil and dataStoreItem.species ~= "" then
    if dataStoreItem.species == "cow" then
      if AnimalHusbandry.canRemoveAnimal() then
        self.isSelling = true
        self.messageTextColor1 = {
          1,
          1,
          1,
          1
        }
        self.messageTextColor2 = {
          0,
          0.85,
          0.15,
          1
        }
        self.messageText.text = g_i18n:getText("StoreSellingCow")
        g_client:getServerConnection():sendEvent(SellCowEvent:new())
      else
        self.messageTextColor1 = {
          1,
          1,
          0.25,
          1
        }
        self.messageTextColor2 = {
          0.75,
          0,
          0,
          1
        }
        self.messageText.text = g_i18n:getText("StoreCannotSellCows")
      end
    end
  else
    local filename = dataStoreItem.xmlFilename:lower()
    if self.numOwnedVehicles[filename] ~= nil and 0 < self.numOwnedVehicles[filename] then
      self.isSelling = true
      self.messageTextColor1 = {
        1,
        1,
        1,
        1
      }
      self.messageTextColor2 = {
        0,
        0.85,
        0.15,
        1
      }
      self.messageText.text = g_i18n:getText("StoreSellingVehicle")
      g_client:getServerConnection():sendEvent(SellVehicleEvent:new(filename))
    end
  end
  self.lastMoney = g_currentMission.missionStats.money
  self:updateBuyAndSellButtons()
  self:updateFocusLinkageSystem()
end
function ShopScreen:getSellPrice(dataStoreItem)
  local sellPrice = dataStoreItem.price * 0.5
  if g_currentMission ~= nil and g_currentMission.reputation ~= nil then
    if g_currentMission.reputation >= 100 then
      sellPrice = dataStoreItem.price * 0.85
    else
      sellPrice = sellPrice + g_currentMission.reputation / 100 * dataStoreItem.price * 0.25
    end
  end
  return math.floor(sellPrice)
end
function ShopScreen:onVehiclesChanged()
  if self.isOpen then
    self:updateOwnedVehicles()
    self:updateBuyAndSellButtons()
    self:updateFocusLinkageSystem()
    self:updateCapitalText()
    self.lastMoney = g_currentMission.missionStats.money
  end
end
function ShopScreen:onMoneyChanged()
  if self.isOpen then
    self:updateBuyAndSellButtons()
    self:updateFocusLinkageSystem()
    self:updateCapitalText()
    self.lastMoney = g_currentMission.missionStats.money
  end
end
