MoneyScreen = {}
local MoneyScreen_mt = Class(MoneyScreen)
source("dataS/scripts/SendMoneyEvent.lua")
function MoneyScreen:new()
  local self = GuiElement:new(target, MoneyScreen_mt)
  self.upButton = nil
  self.downButton = nil
  self.time = 0
  self.transmittedAmount = 0
  self.userIds = {}
  return self
end
function MoneyScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function MoneyScreen:onOpen()
  self.list1:deleteListItems()
  self.amountElements = {}
  self.userIds = {}
  if not g_currentMission:getIsServer() or g_currentMission.allowClientsOwnMoney then
    for i = 1, table.getn(g_currentMission.users) do
      if g_currentMission.users[i].userId ~= g_currentMission.playerUserId then
        self.currentUser = g_currentMission.users[i]
        self.userIds[i] = g_currentMission.users[i].userId
        local newListItem = self.listItem1Template:clone(self.list1)
        newListItem:updateAbsolutePosition()
        self.currentUser = nil
      end
    end
    self.clientAccountsDisabledElement:setVisible(false)
  else
    self.clientAccountsDisabledElement:setVisible(true)
  end
  self:updateBalanceText()
  InputBinding.setShowMouseCursor(true)
  self:updateFocusLinkageSystem()
end
function MoneyScreen:onClose()
  InputBinding.setShowMouseCursor(false)
end
function MoneyScreen:onCreateList(element)
  self.list1 = element
end
function MoneyScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function MoneyScreen:onCreateText(element)
  if self.currentUser ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentUser.nickname, element.textSize, 0.24, true, "..")
    setTextBold(false)
    element:setText(text)
  end
end
function MoneyScreen:onCreateBalanceTextItem(element)
  self.balanceText = element
end
function MoneyScreen:onCreateClientAccountsDisabled(element)
  self.clientAccountsDisabledElement = element
end
function MoneyScreen:onCreateAmountText(element)
  if self.currentUser ~= nil then
    element:setText("0")
    self.amountElements[self.currentUser.userId] = element
  end
end
function MoneyScreen:onCreateAddThousand(element)
  if self.currentUser ~= nil then
    do
      local currentUser = self.currentUser
      function element.onClick(unused)
        self:onAddThousandClick(currentUser)
      end
      FocusManager:loadElementFromCustomValues(element, string.format("listItem" .. table.getn(self.list1.listItems) .. "-" .. "1"), {}, false, false)
    end
  end
end
function MoneyScreen:onCreateAddTenThousand(element)
  if self.currentUser ~= nil then
    do
      local currentUser = self.currentUser
      function element.onClick(unused)
        self:onAddTenThousandClick(currentUser)
      end
      FocusManager:loadElementFromCustomValues(element, string.format("listItem" .. table.getn(self.list1.listItems) .. "-" .. "2"), {}, false, false)
    end
  end
end
function MoneyScreen:onCreateTransfer(element)
  if self.currentUser ~= nil then
    do
      local currentUser = self.currentUser
      function element.onClick(unused)
        self:onTransferClick(currentUser)
      end
      FocusManager:loadElementFromCustomValues(element, string.format("listItem" .. table.getn(self.list1.listItems) .. "-" .. "3"), {}, false, false)
    end
  end
end
function MoneyScreen:onUpButtonCreate(element)
  self.upButton = element
end
function MoneyScreen:onDownButtonCreate(element)
  self.downButton = element
end
function MoneyScreen:onAddThousandClick(user)
  local amount = tonumber(self.amountElements[user.userId].text)
  local amount = math.floor(math.max(math.min(math.min(amount + 1000, g_currentMission.missionStats.money), 9999999), 0))
  self.amountElements[user.userId]:setText(tostring(amount))
end
function MoneyScreen:onAddTenThousandClick(user)
  local amount = tonumber(self.amountElements[user.userId].text)
  local amount = math.floor(math.max(math.min(math.min(amount + 10000, g_currentMission.missionStats.money), 9999999), 0))
  self.amountElements[user.userId]:setText(tostring(amount))
end
function MoneyScreen:onUpClick()
  self.list1:scrollList(-1)
  self:updateFocusLinkageSystem()
end
function MoneyScreen:onDownClick()
  self.list1:scrollList(1)
  self:updateFocusLinkageSystem()
end
function MoneyScreen:onTransferClick(user)
  local amount = tonumber(self.amountElements[user.userId].text)
  if 0 < amount then
    self.amountElements[user.userId]:setText("0")
    g_client:getServerConnection():sendEvent(SendMoneyEvent:new(amount, user.userId))
  end
end
function MoneyScreen:onBackClick()
  g_gui:showGui("")
end
function MoneyScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function MoneyScreen:onIsUnicodeAllowed(unicode)
  return unicode >= string.byte("0", 1) and unicode <= string.byte("9", 1)
end
function MoneyScreen:updateBalanceText()
  if self.balanceText ~= nil then
    self.balanceText:setText(g_i18n:getText("Balance") .. " " .. string.format("%1.0f", g_i18n:getCurrency(g_currentMission.missionStats.money)) .. " " .. g_i18n:getText("Currency_symbol"))
  end
end
function MoneyScreen:update(dt)
  self.time = self.time + dt
  self:updateBalanceText()
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function MoneyScreen:updateFocusLinkageSystem()
  local focusElementsList = {}
  local positionDataHash = {}
  local rootElement = FocusManager:getFocusedElement()
  local minListIndex = self.list1.firstVisibleItem
  local maxListIndex = math.min(self.list1:getNumRows(), self.list1.firstVisibleItem + self.list1.visibleItems - 1)
  for i = minListIndex, maxListIndex do
    local addThousandButton = FocusManager:getElementById("listItem" .. i .. "-" .. "1")
    local addTenThousandButton = FocusManager:getElementById("listItem" .. i .. "-" .. "2")
    local transferButton = FocusManager:getElementById("listItem" .. i .. "-" .. "3")
    table.insert(focusElementsList, addThousandButton)
    table.insert(focusElementsList, addTenThousandButton)
    table.insert(focusElementsList, transferButton)
  end
  local upButton = FocusManager:getElementById("1")
  local downButton = FocusManager:getElementById("2")
  local backButton = FocusManager:getElementById("3")
  table.insert(focusElementsList, upButton)
  table.insert(focusElementsList, downButton)
  table.insert(focusElementsList, backButton)
  FocusManager:createLinkageSystemForElements(focusElementsList, rootElement, positionDataHash)
end
