ListElement = {}
local ListElement_mt = Class(ListElement, GuiElement)
function ListElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = ListElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.disabled = false
  instance.scrollSelection = false
  instance.listItems = {}
  instance.listItemStartYOffset = 0
  instance.listItemHeight = 0.18125
  instance.listItemSpacing = 0
  instance.visibleItems = 5
  instance.firstVisibleItem = 1
  instance.numColumns = 1
  instance.columnPositions = {0}
  instance.selectedRow = 0
  instance.preSelectedRow = 0
  instance.mouseRow = 0
  instance.time = 0
  instance.doubleClickInterval = 1000
  instance.lastClickTime = nil
  instance.usePreSelection = false
  instance.doesFocusScrollList = true
  return instance
end
function ListElement:loadFromXML(xmlFile, key)
  ListElement:superClass().loadFromXML(self, xmlFile, key)
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
  end
  self.usePreSelection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#usePreSelection"), self.usePreSelection)
  self.doesFocusScrollList = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusScrollsList"), self.doesFocusScrollList)
  local maxNumItems = getXMLInt(xmlFile, key .. "#maxNumItems")
  if maxNumItems ~= nil then
    self.maxNumItems = maxNumItems
  end
  local visibleItems = getXMLInt(xmlFile, key .. "#visibleItems")
  if visibleItems ~= nil then
    self.visibleItems = visibleItems
  end
  local listItemStartYOffset = getXMLFloat(xmlFile, key .. "#listItemStartYOffset")
  if listItemStartYOffset ~= nil then
    self.listItemStartYOffset = listItemStartYOffset
  end
  local listItemHeight = getXMLFloat(xmlFile, key .. "#listItemHeight")
  if listItemHeight ~= nil then
    self.listItemHeight = listItemHeight
  end
  local listItemSpacing = getXMLFloat(xmlFile, key .. "#listItemSpacing")
  if listItemSpacing ~= nil then
    self.listItemSpacing = listItemSpacing
  end
  local onSelectionChanged = getXMLString(xmlFile, key .. "#onSelectionChanged")
  if onSelectionChanged ~= nil then
    if self.target ~= nil then
      self.onSelectionChanged = self.target[onSelectionChanged]
    else
      loadstring("g_asdasd_tempFunconSelectionChanged = " .. onSelectionChanged)()
      self.onSelectionChanged = g_asdasd_tempFunconSelectionChanged
      g_asdasd_tempFunconSelectionChanged = nil
    end
  end
  local onScroll = getXMLString(xmlFile, key .. "#onScroll")
  if onScroll ~= nil then
    if self.target ~= nil then
      self.onScroll = self.target[onScroll]
    else
      loadstring("g_asdasd_tempFunconScroll = " .. onScroll)()
      self.onScroll = g_asdasd_tempFunconScroll
      g_asdasd_tempFunconScroll = nil
    end
  end
  local onDoubleClick = getXMLString(xmlFile, key .. "#onDoubleClick")
  if onDoubleClick ~= nil then
    if self.target ~= nil then
      self.onDoubleClick = self.target[onDoubleClick]
    else
      loadstring("g_asdasd_tempFunconDoubleClick = " .. onDoubleClick)()
      self.onDoubleClick = g_asdasd_tempFunconDoubleClick
      g_asdasd_tempFunconDoubleClick = nil
    end
  end
  local doubleClickInterval = getXMLInt(xmlFile, key .. "#doubleClickInterval")
  if doubleClickInterval ~= nil then
    self.doubleClickInterval = doubleClickInterval
  end
end
function ListElement:saveToXML(xmlFile, key)
  ListElement:superClass().saveToXML(self, xmlFile, key)
end
function ListElement:loadProfile(profile)
  ListElement:superClass().loadProfile(self, profile)
end
function ListElement:copyAttributes(src)
  ListElement:superClass().copyAttributes(self, src)
  self.disabled = src.disabled
  self.maxNumItems = src.maxNumItems
  self.visibleItems = src.visibleItems
  self.listItemStartYOffset = src.listItemStartYOffset
  self.listItemHeight = src.listItemHeight
  self.listItemSpacing = src.listItemSpacing
  self.onSelectionChanged = src.onSelectionChanged
  self.onScroll = src.onScroll
  self.onDoubleClick = src.onDoubleClick
  self.doubleClickInterval = src.doubleClickInterval
end
function ListElement:onOpen()
  ListElement:superClass().onOpen(self)
  if self.scrollSelection then
    self:setSelectedRow(math.max(self.selectedRow, 1))
  else
    self:setSelectedRow(self.selectedRow)
  end
end
function ListElement:onClose()
  ListElement:superClass().onClose(self)
end
function ListElement:setDisabled(disabled)
  self.disabled = disabled
  for i, v in ipairs(self.listItems) do
    if v.setDisabled ~= nil then
      v:setDisabled(self.disabled)
    end
  end
end
function ListElement:scrollTo(row)
  local oldRow = 0
  local newRow = 0
  if self.scrollSelection then
    if self.usePreSelection then
      self:setPreSelectedRow(row)
      newRow = self.preSelectedRow
    else
      self:setSelectedRow(row)
      newRow = self.selectedRow
    end
  else
    oldRow = self.firstVisibleItem
    self.firstVisibleItem = math.max(math.min(row, #self.listItems - self.visibleItems + 1), 1)
    newRow = self.firstVisibleItem
  end
  self:updateItemPositions()
  if newRow ~= oldRow and self.onScroll ~= nil then
    if self.target ~= nil then
      self.onScroll(self.target, newRow)
    else
      self.onScroll(newRow)
    end
  end
end
function ListElement:scrollList(rows)
  local row = 0
  if self.scrollSelection then
    if self.usePreSelection then
      row = math.max(self.preSelectedRow + rows, 1)
    else
      row = math.max(self.selectedRow + rows, 1)
    end
  else
    row = self.firstVisibleItem + rows
  end
  self:scrollTo(row)
end
function ListElement:setSelectedRow(row)
  self:_setSelectedOrPreselectedRow(row, false)
end
function ListElement:setPreSelectedRow(row)
  self:_setSelectedOrPreselectedRow(row, true)
end
function ListElement:_setSelectedOrPreselectedRow(row, usePreselected)
  local numItems = #self.listItems
  local newRow = math.max(math.min(row, numItems), 0)
  local tableEntry = usePreselected and "preSelectedRow" or "selectedRow"
  if newRow ~= self[tableEntry] then
    self.lastClickTime = nil
  end
  self[tableEntry] = newRow
  if self.firstVisibleItem < newRow - self.visibleItems + 1 then
    self.firstVisibleItem = math.max(newRow - self.visibleItems + 1, 1)
  elseif newRow < self.firstVisibleItem and 0 < newRow then
    self.firstVisibleItem = newRow
  end
  if not usePreselected and self.onSelectionChanged ~= nil then
    if self.target ~= nil then
      self.onSelectionChanged(self.target, newRow)
    else
      self.onSelectionChanged(newRow)
    end
  end
  local itemSelectionFunctionName = usePreselected and "setPreSelected" or "setSelected"
  for i = 1, self.visibleItems do
    local index = self.firstVisibleItem + i - 1
    if numItems < index then
      break
    end
    local listItem = self.listItems[index]
    local itemSelectionFunction = listItem[itemSelectionFunctionName]
    if itemSelectionFunction ~= nil then
      itemSelectionFunction(listItem, newRow == index)
    end
  end
end
function ListElement:getSelectedElement()
  if self.selectedRow >= 1 then
    return self.listItems[self.selectedRow], self.selectedRow
  end
end
function ListElement:getNumRows()
  return table.getn(self.listItems)
end
function ListElement:updateAbsolutePosition()
  ListElement:superClass().updateAbsolutePosition(self)
  self:updateItemPositions()
end
function ListElement:addElement(element)
  ListElement:superClass().addElement(self, element)
  if self.maxNumItems == nil or self.maxNumItems > table.getn(self.elements) then
    table.insert(self.listItems, element)
    self:setDisabled(self.disabled)
    self:updateItemPositions()
  end
end
function ListElement:removeElement(element)
  for i, v in ipairs(self.listItems) do
    if v == element then
      table.remove(self.listItems, i)
      self:setDisabled(self.disabled)
      if self.selectedRow >= #self.listItems then
        self:setSelectedRow(self.selectedRow - 1)
      end
      if self.usePreselection and self.preSelectedRow >= #self.listItems then
        self:setPreSelectedRow(self.preSelectedRow - 1)
      end
      self:updateItemPositions()
      break
    end
  end
  if 1 < self.firstVisibleItem and self.firstVisibleItem > table.getn(self.listItems) - self.visibleItems then
    self.firstVisibleItem = self.firstVisibleItem - 1
    self:updateItemPositions()
  end
  ListElement:superClass().removeElement(self, element)
end
function ListElement:deleteListItems()
  local numItems = #self.listItems
  for i = 1, numItems do
    self.listItems[1]:delete()
  end
  self.selectedRow = 0
  self.preSelectedRow = 0
end
function ListElement:getIsActive()
  return not self.disabled and self.visible
end
function ListElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if ListElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    self.mouseRow = 0
    if not eventUsed and self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
      FocusManager:setFocus(self)
      local topPos = self.absPosition[2] + self.size[2] - self.listItemStartYOffset - self.listItemHeight
      for i = 1, math.min(#self.listItems, self.visibleItems) do
        local itemPosY = topPos - (i - 1) * (self.listItemHeight + self.listItemSpacing)
        if posY > itemPosY and posY < itemPosY + self.listItemHeight then
          self.mouseRow = i
        end
      end
      if self.usePreSelection then
        self:setPreSelectedRow(self.firstVisibleItem + self.mouseRow - 1)
      end
      if isDown then
        if button == Input.MOUSE_BUTTON_LEFT then
          self.mouseDown = true
        end
        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
          eventUsed = true
          self:scrollList(-1)
        elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
          eventUsed = true
          self:scrollList(1)
        end
      end
      if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
        self.mouseDown = false
        if self.mouseRow ~= 0 then
          self:setSelectedRow(self.firstVisibleItem + self.mouseRow - 1)
          if self.lastClickTime ~= nil and self.lastClickTime > self.time - self.doubleClickInterval then
            if self.onDoubleClick ~= nil then
              if self.target ~= nil then
                self.onDoubleClick(self.target, self.selectedRow)
              else
                self.onDoubleClick(self.selectedRow)
              end
            end
            self.lastClickTime = nil
          else
            self.lastClickTime = self.time
          end
          if self.onClick ~= nil then
            if self.target ~= nil then
              self.onClick(self.target, self.selectedRow)
            else
              self.onClick(self.selectedRow)
            end
          end
        else
          self.lastClickTime = nil
        end
      end
    end
  end
  return eventUsed
end
function ListElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
  return ListElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
end
function ListElement:update(dt)
  ListElement:superClass().update(self, dt)
  self.time = self.time + dt
end
function ListElement:draw()
  ListElement:superClass().draw(self)
  local topPos = self.position[2] + self.size[2] - self.listItemStartYOffset
end
function ListElement:updateItemPositions()
  local topPos = self.size[2] - self.listItemStartYOffset - self.listItemHeight
  for i, v in ipairs(self.listItems) do
    if i < self.firstVisibleItem or i >= self.firstVisibleItem + self.visibleItems then
      local index = i - self.firstVisibleItem
      v:setPosition(v.position[1], topPos - index * (self.listItemHeight + self.listItemSpacing))
      v:setVisible(false)
    else
      local index = i - self.firstVisibleItem
      v:setPosition(v.position[1], topPos - index * (self.listItemHeight + self.listItemSpacing))
      v:setVisible(true)
      v:reset()
      if v.setSelected ~= nil then
        v:setSelected(i == self.selectedRow)
      end
    end
  end
end
function ListElement:shouldFocusChange(direction)
  local minSelectionLimit = self.doesFocusScrollList and 1 or self.firstVisibleItem
  local maxSelectionLimit = self.doesFocusScrollList and self:getNumRows() or self.firstVisibleItem + self.visibleItems - 1
  local currentRow = self.usePreSelection and self.preSelectedRow or self.selectedRow
  if direction == FocusManager.TOP then
    if minSelectionLimit >= currentRow then
      return true
    else
      self.scrollSelection = true
      self:scrollList(-1)
      self.scrollSelection = false
      return false
    end
  elseif direction == FocusManager.BOTTOM then
    if maxSelectionLimit <= currentRow then
      return true
    else
      self.scrollSelection = true
      self:scrollList(1)
      self.scrollSelection = false
      return false
    end
  end
  return true
end
function ListElement:canReceiveFocus()
  return self:getIsVisible() and not self.disabled and table.getn(self.listItems) > 0
end
function ListElement:onFocusActivate()
  if not self.usePreSelection or self.preSelectedRow == self.selectedRow then
    if self.onClick ~= nil then
      if self.target ~= nil then
        self.onClick(self.target, self.selectedRow)
      else
        self.onClick(self.selectedRow)
      end
      return
    end
    if self.onDoubleClick ~= nil then
      if self.target ~= nil then
        self.onDoubleClick(self.target, self.selectedRow)
      else
        self.onDoubleClick(self.selectedRow)
      end
      return
    end
  else
    self:setSelectedRow(self.preSelectedRow)
  end
end
function ListElement:onFocusLeave()
  if self.usePreSelection then
    self:setPreSelectedRow(0)
  end
end
function ListElement:onFocusEnter(focusChangeDirection)
  local elementCount = self:getNumRows()
  if 0 < elementCount then
    local firstSelectionIndex = self.doesFocusScrollList and 1 or self.firstVisibleItem
    local lastSelectionIndex = self.doesFocusScrollList and elementCount or self.firstVisibleItem + self.visibleItems - 1
    if focusChangeDirection == FocusManager.TOP then
      if self.usePreSelection then
        self:setPreSelectedRow(lastSelectionIndex)
      else
        self:setSelectedRow(lastSelectionIndex)
      end
      self:scrollList(0)
    elseif focusChangeDirection == FocusManager.BOTTOM then
      if self.usePreSelection then
        self:setPreSelectedRow(firstSelectionIndex)
      else
        self:setSelectedRow(firstSelectionIndex)
      end
      self:scrollList(0)
    end
  end
end
