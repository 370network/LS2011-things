BitmapElement = {}
local BitmapElement_mt = Class(BitmapElement, GuiElement)
function BitmapElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = BitmapElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.imageColor = {
    1,
    1,
    1,
    1
  }
  return instance
end
function BitmapElement:delete()
  if self.overlay ~= nil then
    delete(self.overlay)
  end
  ButtonElement:superClass().delete(self)
end
function BitmapElement:loadFromXML(xmlFile, key)
  BitmapElement:superClass().loadFromXML(self, xmlFile, key)
  local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local imageColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  self:setImageFilename(self.imageFilename)
end
function BitmapElement:copyAttributes(src)
  BitmapElement:superClass().copyAttributes(self, src)
  self:setImageFilename(src.imageFilename)
  self.imageColor = {
    src.imageColor[1],
    src.imageColor[2],
    src.imageColor[3],
    src.imageColor[4]
  }
end
function BitmapElement:saveToXML(xmlFile, key)
  BitmapElement:superClass().saveToXML(self, xmlFile, key)
end
function BitmapElement:loadProfile(profile)
  BitmapElement:superClass().loadProfile(self, profile)
  local imageFilename = profile:getValue("imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local imageColor = self:getColorArray(profile:getValue("imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
end
function BitmapElement:onOpen()
  BitmapElement:superClass().onOpen(self)
end
function BitmapElement:onClose()
  BitmapElement:superClass().onClose(self)
end
function BitmapElement:setImageFilename(filename)
  if self.overlay ~= nil then
    delete(self.overlay)
  end
  self.imageFilename = filename
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.overlay = createImageOverlay(imageFilename)
  end
end
function BitmapElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  BitmapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
end
function BitmapElement:keyEvent(unicode, sym, modifier, isDown)
  BitmapElement:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function BitmapElement:update(dt)
  BitmapElement:superClass().update(self, dt)
end
function BitmapElement:draw()
  if self.visible and self.overlay ~= nil then
    setOverlayColor(self.overlay, unpack(self.imageColor))
    renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
  end
  BitmapElement:superClass().draw(self)
end
