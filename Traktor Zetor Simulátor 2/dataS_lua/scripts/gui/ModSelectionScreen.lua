ModSelectionScreen = {}
local ModSelectionScreen_mt = Class(ModSelectionScreen)
function ModSelectionScreen:new()
  local self = GuiElement:new(target, ModSelectionScreen_mt)
  self.upButton = nil
  self.downButton = nil
  self.addedMods = {}
  self.modToggleButtons = {}
  self.time = 0
  return self
end
function ModSelectionScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function ModSelectionScreen:onOpen()
  self.addedMods = {}
  for _, modItem in pairs(g_createGameScreen.mods) do
    self.addedMods[modItem] = modItem
  end
  self:setupList()
  InputBinding.setShowMouseCursor(true)
end
function ModSelectionScreen:onClose()
  InputBinding.setShowMouseCursor(true)
end
function ModSelectionScreen:setupList()
  self.list1:deleteListItems()
  self.modToggleButtons = {}
  if g_createGameScreen.mapModName ~= nil then
    local item = ModsUtil.findModItemByModName(g_createGameScreen.mapModName)
    self.addedMods[item] = item
  end
  for i = 1, table.getn(ModsUtil.modList) do
    if ModsUtil.modList[i].isMultiplayerSupported and ModsUtil.modList[i].fileHash ~= nil then
      self.currentItem = ModsUtil.modList[i]
      local newListItem = self.listItem1Template:clone(self.list1)
      newListItem:updateAbsolutePosition()
      self.currentItem = nil
    end
  end
  local modButtonIndex = 1
  for i = 1, table.getn(ModsUtil.modList) do
    if ModsUtil.modList[i].isMultiplayerSupported and ModsUtil.modList[i].fileHash ~= nil then
      local currentItem = ModsUtil.modList[i]
      local modToggleButton = self.modToggleButtons[modButtonIndex]
      if g_createGameScreen.mapModName ~= nil and currentItem.modName == g_createGameScreen.mapModName then
        modToggleButton:setDisabled(true)
      end
      modButtonIndex = modButtonIndex + 1
    end
  end
  self:updateFocusLinkageSystem()
  InputBinding.setShowMouseCursor(true)
end
function ModSelectionScreen:onCreateList(element)
  self.list1 = element
end
function ModSelectionScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function ModSelectionScreen:onCreateIcon(element)
  if self.currentItem ~= nil then
    element:setImageFilename(self.currentItem.iconFilename)
  end
end
function ModSelectionScreen:onCreateTitleText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.title)
  end
end
function ModSelectionScreen:onCreateDescText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.description)
  end
end
function ModSelectionScreen:onCreateAuthorText(element)
  if self.currentItem ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentItem.author, element.textSize, 0.275, false, "..")
    setTextBold(false)
    element:setText(text)
  end
end
function ModSelectionScreen:onCreateVersionText(element)
  if self.currentItem ~= nil then
    element:setText(g_i18n:getText("ModVersion") .. ": " .. self.currentItem.version)
  end
end
function ModSelectionScreen:onCreateHashText(element)
  if self.currentItem ~= nil then
    element:setText(g_i18n:getText("ModFileHash") .. ": " .. self.currentItem.fileHash)
  end
end
function ModSelectionScreen:onCreateToggleModSelected(element)
  if self.currentItem ~= nil then
    do
      local currentItem = self.currentItem
      function element.onClick(unusedSelf, state)
        self:onToggleClick(state, currentItem)
      end
      element:setIsChecked(self.addedMods[self.currentItem] ~= nil)
      table.insert(self.modToggleButtons, element)
      local index = table.getn(self.modToggleButtons)
      FocusManager:loadElementFromCustomValues(element, string.format("modToggleButton" .. index), {}, false, false)
    end
  end
end
function ModSelectionScreen:onUpButtonCreate(element)
  self.upButton = element
end
function ModSelectionScreen:onDownButtonCreate(element)
  self.downButton = element
end
function ModSelectionScreen:onUpClick()
  self.list1:scrollList(-1)
  self:updateFocusLinkageSystem()
end
function ModSelectionScreen:onDownClick()
  self.list1:scrollList(1)
  self:updateFocusLinkageSystem()
end
function ModSelectionScreen:onCancelClick()
  g_gui:showGui("CreateGameScreen")
end
function ModSelectionScreen:onSaveClick()
  local mods = {}
  for _, modItem in pairs(self.addedMods) do
    table.insert(mods, modItem)
  end
  g_createGameScreen:setSelectedMods(mods)
  g_gui:showGui("CreateGameScreen")
end
function ModSelectionScreen:onSelectAllModsClick()
  self.addedMods = {}
  for i = 1, table.getn(ModsUtil.modList) do
    local item = ModsUtil.modList[i]
    self.addedMods[item] = item
  end
  self:setupList()
end
function ModSelectionScreen:onDeselectAllModsClick()
  self.addedMods = {}
  self:setupList()
end
function ModSelectionScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function ModSelectionScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onCancelClick()
  end
end
function ModSelectionScreen:draw()
end
function ModSelectionScreen:onListSelectionChanged(selectedRow)
  self:updateFocusLinkageSystem()
end
function ModSelectionScreen:onToggleClick(state, item)
  if g_createGameScreen.mapModName == nil or item.modName ~= g_createGameScreen.mapModName then
    if state then
      self.addedMods[item] = item
    else
      self.addedMods[item] = nil
    end
  end
end
function ModSelectionScreen:updateFocusLinkageSystem()
  local focusElementsList = {}
  local positionDataHash = {}
  local rootElement = FocusManager:getFocusedElement()
  local minListIndex = self.list1.firstVisibleItem
  local maxListIndex = math.min(self.list1:getNumRows(), self.list1.firstVisibleItem + self.list1.visibleItems - 1)
  for i = minListIndex, maxListIndex do
    local modToggleButton = self.modToggleButtons[i]
    table.insert(focusElementsList, modToggleButton)
  end
  local upButton = FocusManager:getElementById("1")
  local downButton = FocusManager:getElementById("4")
  local backButton = FocusManager:getElementById("6")
  local cancelButton = FocusManager:getElementById("5")
  local selectAllButton = FocusManager:getElementById("2")
  local deselectAllButton = FocusManager:getElementById("3")
  table.insert(focusElementsList, upButton)
  table.insert(focusElementsList, downButton)
  table.insert(focusElementsList, backButton)
  table.insert(focusElementsList, cancelButton)
  table.insert(focusElementsList, selectAllButton)
  table.insert(focusElementsList, deselectAllButton)
  rootElement = rootElement:canReceiveFocus() and rootElement or backButton
  FocusManager:createLinkageSystemForElements(focusElementsList, rootElement, positionDataHash)
end
