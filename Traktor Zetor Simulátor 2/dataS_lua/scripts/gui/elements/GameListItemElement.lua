GameListItemElement = {}
local GameListItemElement_mt = Class(GameListItemElement, GuiElement)
function GameListItemElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = GameListItemElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.selected = false
  instance.preSelected = false
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
  instance.preSelectedOverlayColor = {
    1,
    1,
    1,
    1
  }
  return instance
end
function GameListItemElement:loadFromXML(xmlFile, key)
  GameListItemElement:superClass().loadFromXML(self, xmlFile, key)
  local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local selectedImageFilename = getXMLString(xmlFile, key .. "#selectedImageFilename")
  if selectedImageFilename ~= nil then
    self.selectedImageFilename = selectedImageFilename
  end
  self.preSelectedImageFilename = Utils.getNoNil(getXMLString(xmlFile, key .. "#preSelectedImageFilename"), self.selectedImageFilename)
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
  if self.preSelectedImageFilename ~= nil then
    local preSelectedImageFilename = string.gsub(self.preSelectedImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(preSelectedImageFilename)
    if overlay ~= 0 then
      self.preSelectedImage = overlay
    end
  end
end
function GameListItemElement:saveToXML(xmlFile, key)
  GameListItemElement:superClass().saveToXML(self, xmlFile, key)
end
function GameListItemElement:loadProfile(profile)
  GameListItemElement:superClass().loadProfile(self, profile)
end
function GameListItemElement:copyAttributes(src)
  GameListItemElement:superClass().copyAttributes(self, src)
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
  self.preSelectedImageFilename = src.preSelectedImageFilename
  if self.preSelectedImageFilename ~= nil then
    local preSelectedImageFilename = string.gsub(self.preSelectedImageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(preSelectedImageFilename)
    if overlay ~= 0 then
      self.preSelectedImage = overlay
    end
  end
end
function GameListItemElement:onOpen()
  GameListItemElement:superClass().onOpen(self)
end
function GameListItemElement:onClose()
  GameListItemElement:superClass().onClose(self)
  self:reset()
end
function GameListItemElement:reset()
  GameListItemElement:superClass().reset(self)
  self.selected = false
end
function GameListItemElement:getIsActive()
  return self.visible
end
function GameListItemElement:setSelected(selected)
  self.selected = selected
end
function GameListItemElement:setPreSelected(preSelected)
  self.preSelected = preSelected
end
function GameListItemElement:draw()
  if self.visible then
    if self.image ~= nil then
      setOverlayColor(overlay, unpack(self.overlayColor))
      renderOverlay(self.image, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    if self.selectedImage ~= nil and self.selected then
      setOverlayColor(overlay, unpack(self.selectedOverlayColor))
      renderOverlay(self.selectedImage, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    elseif self.preSelectedImage ~= nil and self.preSelected then
      setOverlayColor(overlay, unpack(self.preSelectedOverlayColor))
      renderOverlay(self.preSelectedImage, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
  end
  GameListItemElement:superClass().draw(self)
end
