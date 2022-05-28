AdminUsersScreen = {}
local AdminUsersScreen_mt = Class(AdminUsersScreen)
function AdminUsersScreen:new()
  local self = GuiElement:new(target, AdminUsersScreen_mt)
  self.upButton = nil
  self.downButton = nil
  self.time = 0
  self.userIds = {}
  return self
end
function AdminUsersScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function AdminUsersScreen:onOpen()
  InputBinding.setShowMouseCursor(true)
  self:generateUsersList()
end
function AdminUsersScreen:onClose()
  InputBinding.setShowMouseCursor(false)
end
function AdminUsersScreen:onCreateList(element)
  self.list1 = element
end
function AdminUsersScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function AdminUsersScreen:onCreateText(element)
  if self.currentUser ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentUser.nickname, element.textSize, 0.5, true, "..")
    setTextBold(false)
    element:setText(text)
  end
end
function AdminUsersScreen:onCreateKickClient(element)
  if self.currentUser ~= nil then
    do
      local currentUser = self.currentUser
      function element.onClick(unused)
        self:onKickUserClick(currentUser)
      end
      FocusManager:loadElementFromCustomValues(element, string.format("listItem" .. table.getn(self.list1.listItems) .. "-" .. "1"), {}, false, false)
    end
  end
end
function AdminUsersScreen:onCreateBanClient(element)
  if self.currentUser ~= nil then
    do
      local currentUser = self.currentUser
      function element.onClick(unused)
        self:onBanUserClick(currentUser)
      end
      FocusManager:loadElementFromCustomValues(element, string.format("listItem" .. table.getn(self.list1.listItems) .. "-" .. "2"), {}, false, false)
    end
  end
end
function AdminUsersScreen:onUpButtonCreate(element)
  self.upButton = element
end
function AdminUsersScreen:onDownButtonCreate(element)
  self.downButton = element
end
function AdminUsersScreen:onKickUserClick(user)
  g_currentMission:kickUser(user)
  self:generateUsersList()
end
function AdminUsersScreen:onBanUserClick(user)
  g_currentMission:banUser(user)
  self:generateUsersList()
end
function AdminUsersScreen:onUpClick()
  self.list1:scrollList(-1)
  self:updateFocusLinkageSystem()
end
function AdminUsersScreen:onDownClick()
  self.list1:scrollList(1)
  self:updateFocusLinkageSystem()
end
function AdminUsersScreen:onBackClick()
  g_gui:showGui("")
end
function AdminUsersScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function AdminUsersScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function AdminUsersScreen:generateUsersList()
  self.list1:deleteListItems()
  self.userIds = {}
  if g_currentMission:getIsServer() then
    for i = 1, table.getn(g_currentMission.users) do
      if g_currentMission.users[i].userId ~= g_currentMission.playerUserId then
        self.currentUser = g_currentMission.users[i]
        self.userIds[i] = g_currentMission.users[i].userId
        local newListItem = self.listItem1Template:clone(self.list1)
        newListItem:updateAbsolutePosition()
        self.currentUser = nil
      end
    end
  end
  self:updateFocusLinkageSystem()
end
function AdminUsersScreen:updateFocusLinkageSystem()
  local focusElementsList = {}
  local positionDataHash = {}
  local rootElement = FocusManager:getFocusedElement()
  local minListIndex = self.list1.firstVisibleItem
  local maxListIndex = math.min(self.list1:getNumRows(), self.list1.firstVisibleItem + self.list1.visibleItems - 1)
  for i = minListIndex, maxListIndex do
    local kickUserButton = FocusManager:getElementById("listItem" .. i .. "-" .. "1")
    local banUserButton = FocusManager:getElementById("listItem" .. i .. "-" .. "2")
    table.insert(focusElementsList, kickUserButton)
    table.insert(focusElementsList, banUserButton)
  end
  local upButton = FocusManager:getElementById("1")
  local downButton = FocusManager:getElementById("2")
  local backButton = FocusManager:getElementById("3")
  table.insert(focusElementsList, upButton)
  table.insert(focusElementsList, downButton)
  table.insert(focusElementsList, backButton)
  FocusManager:createLinkageSystemForElements(focusElementsList, rootElement, positionDataHash)
end
