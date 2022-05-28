ListItemElement = {}
ListItemElement.STATE_NORMAL = 1
ListItemElement.STATE_FOCUSED = 2
ListItemElement.STATE_SELECTED = 3
local ListItemElement_mt = Class(ListItemElement, GuiElement)
function ListItemElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = ListItemElement_mt
  end
  local self = GuiElement:new(target, custom_mt)
  self.disabled = false
  self.imageColor = {
    1,
    1,
    1,
    1
  }
  self.imageFocusedColor = {
    1,
    1,
    1,
    1
  }
  self.imageSelectedColor = {
    1,
    1,
    1,
    1
  }
  self.imageDisabledColor = {
    1,
    1,
    1,
    1
  }
  self.allowSelected = true
  self.overlays = {}
  self.mouseEntered = false
  self.state = ListItemElement.STATE_NORMAL
  return self
end
function ListItemElement:loadFromXML(xmlFile, key)
  ListItemElement:superClass().loadFromXML(self, xmlFile, key)
  local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local imageFocusedFilename = getXMLString(xmlFile, key .. "#imageFocusedFilename")
  if imageFocusedFilename ~= nil then
    self.imageFocusedFilename = imageFocusedFilename
  end
  local imageSelectedFilename = getXMLString(xmlFile, key .. "#imageSelectedFilename")
  if imageSelectedFilename ~= nil then
    self.imageSelectedFilename = imageSelectedFilename
  end
  local imageDisabledFilename = getXMLString(xmlFile, key .. "#imageDisabledFilename")
  if imageDisabledFilename ~= nil then
    self.imageDisabledFilename = imageDisabledFilename
  end
  local onFocus = getXMLString(xmlFile, key .. "#onFocus")
  if onFocus ~= nil then
    if self.target ~= nil then
      self.onFocus = self.target[onFocus]
    else
      loadstring("g_asdasd_tempFuncOnFocus = " .. onFocus)()
      self.onFocus = g_asdasd_tempFuncOnFocus
      g_asdasd_tempFuncOnFocus = nil
    end
  end
  local onLeave = getXMLString(xmlFile, key .. "#onLeave")
  if onLeave ~= nil then
    if self.target ~= nil then
      self.onLeave = self.target[onLeave]
    else
      loadstring("g_asdasd_tempFuncOnLeave = " .. onLeave)()
      self.onLeave = g_asdasd_tempFuncOnLeave
      g_asdasd_tempFuncOnLeave = nil
    end
  end
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
  end
  local allowSelected = getXMLBool(xmlFile, key .. "#allowSelected")
  if allowSelected ~= nil then
    self.allowSelected = allowSelected
  end
  local imageColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  local imageFocusedColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageFocusedColor"))
  if imageFocusedColor ~= nil then
    self.imageFocusedColor = imageFocusedColor
  end
  local imageSelectedColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageSelectedColor"))
  if imageSelectedColor ~= nil then
    self.imageSelectedColor = imageSelectedColor
  end
  local imageDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageDisabledColor"))
  if imageDisabledColor ~= nil then
    self.imageDisabledColor = imageDisabledColor
  end
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_NORMAL] = overlay
    end
  end
  if self.imageSelectedFilename ~= nil then
    local imageSelectedFilename = string.gsub(self.imageSelectedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageSelectedFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_SELECTED] = overlay
    end
  end
  if self.imageFocusedFilename ~= nil then
    local imageFocusedFilename = string.gsub(self.imageFocusedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFocusedFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_FOCUSED] = overlay
    end
  end
  if self.overlays[ListItemElement.STATE_SELECTED] == nil then
    self.overlays[ListItemElement.STATE_SELECTED] = self.overlays[ListItemElement.STATE_FOCUSED]
  end
  if self.overlays[ListItemElement.STATE_FOCUSED] == nil then
    self.overlays[ListItemElement.STATE_FOCUSED] = self.overlays[ListItemElement.STATE_SELECTED]
  end
  if self.overlays[ListItemElement.STATE_SELECTED] == nil then
    self.overlays[ListItemElement.STATE_SELECTED] = self.overlays[ListItemElement.STATE_NORMAL]
  end
  if self.overlays[ListItemElement.STATE_FOCUSED] == nil then
    self.overlays[ListItemElement.STATE_FOCUSED] = self.overlays[ListItemElement.STATE_NORMAL]
  end
end
function ListItemElement:saveToXML(xmlFile, key)
  ListItemElement:superClass().saveToXML(self, xmlFile, key)
end
function ListItemElement:loadProfile(profile)
  ListItemElement:superClass().loadProfile(self, profile)
end
function ListItemElement:copyAttributes(src)
  ListItemElement:superClass().copyAttributes(self, src)
  self.imageFilename = src.imageFilename
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_NORMAL] = overlay
    end
  end
  self.imageSelectedFilename = src.imageSelectedFilename
  if self.imageSelectedFilename ~= nil then
    local imageSelectedFilename = string.gsub(self.imageSelectedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageSelectedFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_SELECTED] = overlay
    end
  end
  self.imageFocusedFilename = src.imageFocusedFilename
  if self.imageFocusedFilename ~= nil then
    local imageFocusedFilename = string.gsub(self.imageFocusedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFocusedFilename)
    if overlay ~= 0 then
      self.overlays[ListItemElement.STATE_FOCUSED] = overlay
    end
  end
  self.imageDisabledColor = {
    src.imageDisabledColor[1],
    src.imageDisabledColor[2],
    src.imageDisabledColor[3],
    src.imageDisabledColor[4]
  }
  self.imageSelectedColor = {
    src.imageSelectedColor[1],
    src.imageSelectedColor[2],
    src.imageSelectedColor[3],
    src.imageSelectedColor[4]
  }
  self.imageFocusedColor = {
    src.imageFocusedColor[1],
    src.imageFocusedColor[2],
    src.imageFocusedColor[3],
    src.imageFocusedColor[4]
  }
  self.imageColor = {
    src.imageColor[1],
    src.imageColor[2],
    src.imageColor[3],
    src.imageColor[4]
  }
  self.disabled = src.disabled
  self.allowSelected = src.allowSelected
  self.onLeave = src.onLeave
  self.onFocus = src.onFocus
  if self.overlays[ListItemElement.STATE_SELECTED] == nil then
    self.overlays[ListItemElement.STATE_SELECTED] = self.overlays[ListItemElement.STATE_FOCUSED]
  end
  if self.overlays[ListItemElement.STATE_FOCUSED] == nil then
    self.overlays[ListItemElement.STATE_FOCUSED] = self.overlays[ListItemElement.STATE_SELECTED]
  end
  if self.overlays[ListItemElement.STATE_SELECTED] == nil then
    self.overlays[ListItemElement.STATE_SELECTED] = self.overlays[ListItemElement.STATE_NORMAL]
  end
  if self.overlays[ListItemElement.STATE_FOCUSED] == nil then
    self.overlays[ListItemElement.STATE_FOCUSED] = self.overlays[ListItemElement.STATE_NORMAL]
  end
end
function ListItemElement:onOpen()
  ListItemElement:superClass().onOpen(self)
end
function ListItemElement:onClose()
  ListItemElement:superClass().onClose(self)
  self:reset()
end
function ListItemElement:reset()
  ListItemElement:superClass().reset(self)
  self.state = ListItemElement.STATE_NORMAL
end
function ListItemElement:getIsActive()
  return self.visible and not self.disabled
end
function ListItemElement:setSelected(selected)
  if self.allowSelected then
    if selected then
      self.state = ListItemElement.STATE_SELECTED
    elseif self.mouseEntered then
      self.state = ListItemElement.STATE_FOCUSED
    else
      self.state = ListItemElement.STATE_NORMAL
    end
  end
end
function ListItemElement:setDisabled(disabled)
  ListItemElement:superClass().setDisabled(self, disabled)
  self.disabled = disabled
end
function ListItemElement:getOverlayColor()
  if self.disabled then
    return self.imageDisabledColor
  elseif self.state == ListItemElement.STATE_SELECTED then
    return self.imageSelectedColor
  elseif self.state == ListItemElement.STATE_FOCUSED then
    return self.imageFocusedColor
  end
  return self.imageColor
end
function ListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if ListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    local ret = false
    if not eventUsed and self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
      FocusManager:setFocus(self)
      if not isDown and not isUp then
        ret = true
        if self.state ~= ListItemElement.STATE_SELECTED then
          self.state = ListItemElement.STATE_FOCUSED
        end
        if not self.mouseEntered then
          self.mouseEntered = true
          if self.onFocus ~= nil then
            if self.target ~= nil then
              self.onFocus(self.target, self)
            else
              self.onFocus(self)
            end
          end
        end
      end
    else
      if self.mouseEntered then
        self.mouseEntered = false
        if self.onLeave ~= nil then
          if self.target ~= nil then
            self.onLeave(self.target, self)
          else
            self.onLeave(self)
          end
        end
      end
      self.mouseDown = false
      if not self.focusActive and self.state ~= ListItemElement.STATE_SELECTED then
        self.state = ListItemElement.STATE_NORMAL
      end
    end
    return ret
  end
  return eventUsed
end
function ListItemElement:draw()
  if self.visible then
    local overlay = self.overlays[self.state]
    if overlay ~= nil then
      setOverlayColor(overlay, unpack(self:getOverlayColor()))
      renderOverlay(overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
  end
  ListItemElement:superClass().draw(self)
end
