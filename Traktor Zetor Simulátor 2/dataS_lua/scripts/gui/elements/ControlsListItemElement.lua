ControlsListItemElement = {}
local ControlsListItemElement_mt = Class(ControlsListItemElement, GuiElement)
function ControlsListItemElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = ControlsListItemElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.selected = false
  instance.disabled = false
  instance.overlayColor = {
    1,
    1,
    1,
    1
  }
  instance.selectedOverlayColor = {
    1,
    1,
    1,
    1
  }
  return instance
end
function ControlsListItemElement:loadFromXML(xmlFile, key)
  ControlsListItemElement:superClass().loadFromXML(self, xmlFile, key)
  local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local selectedImageFilename = getXMLString(xmlFile, key .. "#selectedImageFilename")
  if selectedImageFilename ~= nil then
    self.selectedImageFilename = selectedImageFilename
  end
  local onClick = getXMLString(xmlFile, key .. "#onClick")
  if onClick ~= nil then
    if self.target ~= nil then
      self.onClick = self.target[onClick]
    else
      loadstring("g_asdasd_tempFuncOnClick = " .. onClick)()
      self.onClick = g_asdasd_tempFuncOnClick
      g_asdasd_tempFuncOnClick = nil
    end
  end
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.image = overlay
    end
  end
  if self.selectedImageFilename ~= nil then
    local selectedImageFilename = string.gsub(self.selectedImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(selectedImageFilename)
    if overlay ~= 0 then
      self.selectedImage = overlay
    end
  end
end
function ControlsListItemElement:saveToXML(xmlFile, key)
  ControlsListItemElement:superClass().saveToXML(self, xmlFile, key)
end
function ControlsListItemElement:loadProfile(profile)
  ControlsListItemElement:superClass().loadProfile(self, profile)
end
function ControlsListItemElement:copyAttributes(src)
  ControlsListItemElement:superClass().copyAttributes(self, src)
  self.onClick = src.onClick
  self.imageFilename = src.imageFilename
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.image = overlay
    end
  end
  self.selectedImageFilename = src.selectedImageFilename
  if self.selectedImageFilename ~= nil then
    local selectedImageFilename = string.gsub(self.selectedImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(selectedImageFilename)
    if overlay ~= 0 then
      self.selectedImage = overlay
    end
  end
end
function ControlsListItemElement:onOpen()
  ControlsListItemElement:superClass().onOpen(self)
end
function ControlsListItemElement:onClose()
  ControlsListItemElement:superClass().onClose(self)
  self:reset()
end
function ControlsListItemElement:reset()
  ControlsListItemElement:superClass().reset(self)
  self.selected = false
end
function ControlsListItemElement:getIsActive()
  return self.visible and not self.disabled
end
function ControlsListItemElement:setSelected(selected)
  self.selected = selected
end
function ControlsListItemElement:setDisabled(disabled)
  ControlsListItemElement:superClass().setDisabled(self, disabled)
  self.disabled = disabled
end
function ControlsListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if ControlsListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    self:setSelected(false)
    if not eventUsed and self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
      self:setSelected(true)
      if self.target and self.target.onFocusElement then
        self.target:onFocusElement(self)
      end
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
        eventUsed = true
      end
      if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
        eventUsed = true
        self.mouseDown = false
        if self.onClick ~= nil then
          if self.target ~= nil then
            self.onClick(self.target, self)
          else
            self.onClick(self)
          end
        end
      end
    else
      self.mouseDown = false
    end
  end
  return eventUsed
end
function ControlsListItemElement:draw()
  if self.visible then
    if self.image ~= nil then
      setOverlayColor(self.image, unpack(self.overlayColor))
      renderOverlay(self.image, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    if self.selectedImage ~= nil and self.selected and not self.disabled then
      setOverlayColor(self.selectedImage, unpack(self.selectedOverlayColor))
      renderOverlay(self.selectedImage, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
  end
  ControlsListItemElement:superClass().draw(self)
end
