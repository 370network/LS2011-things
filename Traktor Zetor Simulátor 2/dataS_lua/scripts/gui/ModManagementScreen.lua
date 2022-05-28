ModManagementScreen = {}
local ModManagementScreen_mt = Class(ModManagementScreen)
function ModManagementScreen:new()
  local self = GuiElement:new(target, ModManagementScreen_mt)
  self.upButton = nil
  self.downButton = nil
  self.deleteButtons = {}
  self.time = 0
  self.hasModsDeleted = false
  return self
end
function ModManagementScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function ModManagementScreen:onOpen()
  self:setupList()
end
function ModManagementScreen:onClose()
end
function ModManagementScreen:setupList()
  self.list1:deleteListItems()
  self.deleteButtons = {}
  if g_createGameScreen.mapModName ~= nil then
    local item = ModsUtil.findModItemByModName(g_createGameScreen.mapModName)
    self.addedMods[item] = item
  end
  for i = 1, table.getn(ModsUtil.modList) do
    self.currentItem = ModsUtil.modList[i]
    local newListItem = self.listItem1Template:clone(self.list1)
    newListItem:updateAbsolutePosition()
    self.currentItem = nil
  end
  self:updateFocusLinkageSystem()
  InputBinding.setShowMouseCursor(true)
end
function ModManagementScreen:onCreateList(element)
  self.list1 = element
end
function ModManagementScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function ModManagementScreen:onCreateIcon(element)
  if self.currentItem ~= nil then
    element:setImageFilename(self.currentItem.iconFilename)
  end
end
function ModManagementScreen:onCreateTitleText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.title)
  end
end
function ModManagementScreen:onCreateDescText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.description)
  end
end
function ModManagementScreen:onCreateAuthorText(element)
  if self.currentItem ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentItem.author, element.textSize, 0.275, false, "..")
    setTextBold(false)
    element:setText(text)
  end
end
function ModManagementScreen:onCreateVersionText(element)
  if self.currentItem ~= nil then
    element:setText(g_i18n:getText("ModVersion") .. ": " .. self.currentItem.version)
  end
end
function ModManagementScreen:onCreateHashText(element)
  if self.currentItem ~= nil and self.currentItem.fileHash ~= nil then
    element:setText(g_i18n:getText("ModFileHash") .. ": " .. self.currentItem.fileHash)
  end
end
function ModManagementScreen:onCreateDeleteButton(element)
  if self.currentItem ~= nil then
    do
      local currentItem = self.currentItem
      function element.onClick(unusedSelf)
        self:onDeleteClick(currentItem)
      end
      table.insert(self.deleteButtons, element)
      local index = table.getn(self.deleteButtons)
      FocusManager:loadElementFromCustomValues(element, string.format("deleteButton" .. index), {}, false, false)
    end
  end
end
function ModManagementScreen:onUpButtonCreate(element)
  self.upButton = element
end
function ModManagementScreen:onDownButtonCreate(element)
  self.downButton = element
end
function ModManagementScreen:onUpClick()
  self.list1:scrollList(-1)
  self:updateFocusLinkageSystem()
end
function ModManagementScreen:onDownClick()
  self.list1:scrollList(1)
  self:updateFocusLinkageSystem()
end
function ModManagementScreen:onBackClick()
  if self.hasModsDeleted then
    restartApplication()
    return
  end
  g_gui:showGui("SettingsScreen")
end
function ModManagementScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function ModManagementScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function ModManagementScreen:draw()
end
function ModManagementScreen:onListSelectionChanged(selectedRow)
  self:updateFocusLinkageSystem()
end
function ModManagementScreen:onDeleteClick(item)
  self.modItemToDelete = item
  local yesNoDialog = g_gui:showGui("YesNoDialog")
  yesNoDialog.target:setText(g_i18n:getText("YouWantToDeleteThisMod"))
  yesNoDialog.target:setCallbacks(self.onYesNoDeleteMod, self)
end
function ModManagementScreen:onYesNoDeleteMod(yes)
  if yes then
    local item = self.modItemToDelete
    if item.isDirectory then
      deleteFolder(item.absBaseFilename)
    else
      deleteFile(item.absBaseFilename)
    end
    ModsUtil.removeModItem(self.modItemToDelete)
    self.hasModsDeleted = true
  end
  g_gui:showGui("ModManagementScreen")
end
function ModManagementScreen:updateFocusLinkageSystem()
  local focusElementsList = {}
  local positionDataHash = {}
  local rootElement = FocusManager:getFocusedElement()
  local minListIndex = self.list1.firstVisibleItem
  local maxListIndex = math.min(self.list1:getNumRows(), self.list1.firstVisibleItem + self.list1.visibleItems - 1)
  for i = minListIndex, maxListIndex do
    local deleteButton = self.deleteButtons[i]
    table.insert(focusElementsList, deleteButton)
  end
  local upButton = FocusManager:getElementById("1")
  local downButton = FocusManager:getElementById("4")
  local backButton = FocusManager:getElementById("6")
  table.insert(focusElementsList, upButton)
  table.insert(focusElementsList, downButton)
  table.insert(focusElementsList, backButton)
  rootElement = rootElement:canReceiveFocus() and rootElement or backButton
  FocusManager:createLinkageSystemForElements(focusElementsList, rootElement, positionDataHash)
end
