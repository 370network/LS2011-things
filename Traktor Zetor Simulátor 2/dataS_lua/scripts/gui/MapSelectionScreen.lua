MapSelectionScreen = {}
local ModSelectionScreen_mt = Class(MapSelectionScreen)
function MapSelectionScreen:new()
  local self = GuiElement:new(target, ModSelectionScreen_mt)
  self.time = 0
  self.isMultiplayer = false
  return self
end
function MapSelectionScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function MapSelectionScreen:onOpen()
  self.list1:deleteListItems()
  self.maps = {}
  for i = 1, table.getn(MapsUtil.mapList) do
    self.currentItem = MapsUtil.mapList[i]
    if not self.isMultiplayer or self.currentItem.customEnvironment == nil or ModsUtil.findModItemByModName(self.currentItem.customEnvironment).isMultiplayerSupported then
      table.insert(self.maps, self.currentItem)
      local newListItem = self.listItem1Template:clone(self.list1)
      newListItem:updateAbsolutePosition()
    end
    self.currentItem = nil
  end
  self.list1:setSelectedRow(1)
  InputBinding.setShowMouseCursor(true)
end
function MapSelectionScreen:onClose()
  InputBinding.setShowMouseCursor(true)
end
function MapSelectionScreen:onCreateList(element)
  self.list1 = element
end
function MapSelectionScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function MapSelectionScreen:onCreateIcon(element)
  if self.currentItem ~= nil then
    element:setImageFilename(self.currentItem.iconFilename)
  end
end
function MapSelectionScreen:onCreateTitleText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.title)
  end
end
function MapSelectionScreen:onCreateDescText(element)
  if self.currentItem ~= nil then
    element:setText(self.currentItem.description)
  end
end
function MapSelectionScreen:onListSelectionChanged(rowIndex)
  self.selectedIndex = rowIndex
end
function MapSelectionScreen:onDoubleClick()
  self:onStartClick()
end
function MapSelectionScreen:onUpClick()
  self.list1:scrollList(-1)
end
function MapSelectionScreen:onDownClick()
  self.list1:scrollList(1)
end
function MapSelectionScreen:onBackClick()
  g_gui:showGui(self.returnScreenName)
end
function MapSelectionScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function MapSelectionScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function MapSelectionScreen:draw()
end
function MapSelectionScreen:onStartClick()
  if self.list1.selectedRow > 0 then
    local map = self.maps[self.list1.selectedRow]
    self.returnScreen:setSelectedGameMap(map)
  end
end
function MapSelectionScreen:setReturn(screen, screenName)
  self.returnScreen = screen
  self.returnScreenName = screenName
end
function MapSelectionScreen:setIsMultiplayer(isMultiplayer)
  self.isMultiplayer = isMultiplayer
end
