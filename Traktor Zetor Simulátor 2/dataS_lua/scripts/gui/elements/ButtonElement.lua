ButtonElement = {}
ButtonElement.STATE_NORMAL = 1
ButtonElement.STATE_PRESSED = 2
ButtonElement.STATE_FOCUSED = 3
ButtonElement.NUM_STATES = 4
ButtonElement.OVERLAY_NORMAL = ButtonElement.STATE_NORMAL
ButtonElement.OVERLAY_PRESSED = ButtonElement.STATE_PRESSED
ButtonElement.OVERLAY_FOCUSED = ButtonElement.STATE_FOCUSED
ButtonElement.OVERLAY_DISABLED = ButtonElement.NUM_STATES
local ButtonElement_mt = Class(ButtonElement, GuiElement)
function ButtonElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = ButtonElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.overlays = {}
  instance.state = ButtonElement.STATE_NORMAL
  instance.mouseDown = false
  instance.textColor = {
    1,
    1,
    1,
    1
  }
  instance.textDisabledColor = {
    1,
    1,
    1,
    1
  }
  instance.textOffset = {0, 0}
  instance.textSize = 0.03
  instance.textBold = false
  instance.text2Color = {
    1,
    1,
    1,
    1
  }
  instance.text2DisabledColor = {
    1,
    1,
    1,
    1
  }
  instance.text2Offset = {0, 0}
  instance.text2Size = 0
  instance.text2Bold = false
  instance.disabled = false
  instance.imageColor = {
    1,
    1,
    1,
    1
  }
  instance.imageFocusedColor = {
    1,
    1,
    1,
    1
  }
  instance.imagePressedColor = {
    1,
    1,
    1,
    1
  }
  instance.imageDisabledColor = {
    1,
    1,
    1,
    1
  }
  return instance
end
function ButtonElement:delete()
  if self.overlays[self.OVERLAY_NORMAL] ~= nil then
    delete(self.overlays[self.OVERLAY_NORMAL])
  end
  if self.overlays[self.OVERLAY_PRESSED] ~= nil then
    delete(self.overlays[self.OVERLAY_PRESSED])
  end
  if self.overlays[self.OVERLAY_FOCUSED] ~= nil then
    delete(self.overlays[self.OVERLAY_FOCUSED])
  end
  if self.overlays[self.OVERLAY_DISABLED] ~= nil then
    delete(self.overlays[self.OVERLAY_DISABLED])
  end
  ButtonElement:superClass().delete(self)
end
function ButtonElement:loadFromXML(xmlFile, key)
  ButtonElement:superClass().loadFromXML(self, xmlFile, key)
  local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local imageFocusedFilename = getXMLString(xmlFile, key .. "#imageFocusedFilename")
  if imageFocusedFilename ~= nil then
    self.imageFocusedFilename = imageFocusedFilename
  end
  local imagePressedFilename = getXMLString(xmlFile, key .. "#imagePressedFilename")
  if imagePressedFilename ~= nil then
    self.imagePressedFilename = imagePressedFilename
  end
  local imageDisabledFilename = getXMLString(xmlFile, key .. "#imageDisabledFilename")
  if imageDisabledFilename ~= nil then
    self.imageDisabledFilename = imageDisabledFilename
  end
  local onClick = getXMLString(xmlFile, key .. "#onClick")
  if onClick ~= nil then
    if self.target ~= nil then
      self.onClick = self.target[onClick]
    else
      loadstring("g_asdasd_tempFunc = " .. onClick)()
      self.onClick = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
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
  local text = getXMLString(xmlFile, key .. "#text")
  if text ~= nil then
    if text:sub(1, 6) == "$l10n_" then
      text = g_i18n:getText(text:sub(7))
    end
    self.text = text
  end
  local textColor = self:getColorArray(getXMLString(xmlFile, key .. "#textColor"))
  if textColor ~= nil then
    self.textColor = textColor
  end
  local textDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#textDisabledColor"))
  if textDisabledColor ~= nil then
    self.textDisabledColor = textDisabledColor
  end
  local textOffset = self:get2DArray(getXMLString(xmlFile, key .. "#textOffset"))
  if textOffset ~= nil then
    self.textOffset = textOffset
  end
  local textSize = getXMLFloat(xmlFile, key .. "#textSize")
  if textSize ~= nil then
    self.textSize = textSize
  end
  local textBold = getXMLBool(xmlFile, key .. "#textBold")
  if textBold ~= nil then
    self.textBold = textBold
  end
  local text2Color = self:getColorArray(getXMLString(xmlFile, key .. "#text2Color"))
  if text2Color ~= nil then
    self.text2Color = text2Color
  end
  local text2DisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#text2DisabledColor"))
  if text2DisabledColor ~= nil then
    self.text2DisabledColor = text2DisabledColor
  end
  local text2Offset = self:get2DArray(getXMLString(xmlFile, key .. "#text2Offset"))
  if text2Offset ~= nil then
    self.text2Offset = text2Offset
  end
  local text2Size = getXMLFloat(xmlFile, key .. "#text2Size")
  if text2Size ~= nil then
    self.text2Size = text2Size
  end
  local text2Bold = getXMLBool(xmlFile, key .. "#text2Bold")
  if text2Bold ~= nil then
    self.text2Bold = text2Bold
  end
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
  end
  local imageColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  local imageFocusedColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageFocusedColor"))
  if imageFocusedColor ~= nil then
    self.imageFocusedColor = imageFocusedColor
  end
  local imagePressedColor = self:getColorArray(getXMLString(xmlFile, key .. "#imagePressedColor"))
  if imagePressedColor ~= nil then
    self.imagePressedColor = imagePressedColor
  end
  local imageDisabledColor = self:getColorArray(getXMLString(xmlFile, key .. "#imageDisabledColor"))
  if imageDisabledColor ~= nil then
    self.imageDisabledColor = imageDisabledColor
  end
  self:createOverlay(self.OVERLAY_NORMAL, self.imageFilename)
  self:createOverlay(self.OVERLAY_PRESSED, self.imagePressedFilename)
  self:createOverlay(self.OVERLAY_FOCUSED, self.imageFocusedFilename)
  self:createOverlay(self.OVERLAY_DISABLED, self.imageDisabledFilename)
end
function ButtonElement:saveToXML(xmlFile, key)
  ButtonElement:superClass().saveToXML(self, xmlFile, key)
end
function ButtonElement:loadProfile(profile)
  ButtonElement:superClass().loadProfile(self, profile)
  local imageFilename = profile:getValue("imageFilename")
  if imageFilename ~= nil then
    self.imageFilename = imageFilename
  end
  local imageFocusedFilename = profile:getValue("imageFocusedFilename")
  if imageFocusedFilename ~= nil then
    self.imageFocusedFilename = imageFocusedFilename
  end
  local imagePressedFilename = profile:getValue("imagePressedFilename")
  if imagePressedFilename ~= nil then
    self.imagePressedFilename = imagePressedFilename
  end
  local imageDisabledFilename = profile:getValue("imageDisabledFilename")
  if imageDisabledFilename ~= nil then
    self.imageDisabledFilename = imageDisabledFilename
  end
  local textColor = self:getColorArray(profile:getValue("textColor"))
  if textColor ~= nil then
    self.textColor = textColor
  end
  local textDisabledColor = self:getColorArray(profile:getValue("textDisabledColor"))
  if textDisabledColor ~= nil then
    self.textDisabledColor = textDisabledColor
  end
  local textOffset = self:get2DArray(profile:getValue("textOffset"))
  if textOffset ~= nil then
    self.textOffset = textOffset
  end
  local textSize = tonumber(profile:getValue("textSize"))
  if textSize ~= nil then
    self.textSize = textSize
  end
  local textBold = profile:getValue("textBold")
  if textBold ~= nil then
    self.textBold = textBold:lower() == "true"
  end
  local text2Color = self:getColorArray(profile:getValue("text2Color"))
  if text2Color ~= nil then
    self.text2Color = text2Color
  end
  local text2DisabledColor = self:getColorArray(profile:getValue("text2DisabledColor"))
  if text2DisabledColor ~= nil then
    self.text2DisabledColor = text2DisabledColor
  end
  local text2Offset = self:get2DArray(profile:getValue("text2Offset"))
  if text2Offset ~= nil then
    self.text2Offset = text2Offset
  end
  local text2Size = tonumber(profile:getValue("text2Size"))
  if text2Size ~= nil then
    self.text2Size = text2Size
  end
  local text2Bold = profile:getValue("text2Bold")
  if text2Bold ~= nil then
    self.text2Bold = text2Bold:lower() == "true"
  end
  local imageColor = self:getColorArray(profile:getValue("imageColor"))
  if imageColor ~= nil then
    self.imageColor = imageColor
  end
  local imageFocusedColor = self:getColorArray(profile:getValue("imageFocusedColor"))
  if imageFocusedColor ~= nil then
    self.imageFocusedColor = imageFocusedColor
  end
  local imagePressedColor = self:getColorArray(profile:getValue("imagePressedColor"))
  if imagePressedColor ~= nil then
    self.imagePressedColor = imagePressedColor
  end
  local imageDisabledColor = self:getColorArray(profile:getValue("imageDisabledColor"))
  if imageDisabledColor ~= nil then
    self.imageDisabledColor = imageDisabledColor
  end
end
function ButtonElement:copyAttributes(src)
  ButtonElement:superClass().copyAttributes(self, src)
  self.imageFilename = src.imageFilename
  self:createOverlay(self.OVERLAY_NORMAL, self.imageFilename)
  self.imagePressedFilename = src.imagePressedFilename
  self:createOverlay(self.OVERLAY_PRESSED, self.imagePressedFilename)
  self.imageFocusedFilename = src.imageFocusedFilename
  self:createOverlay(self.OVERLAY_FOCUSED, self.imageFocusedFilename)
  self.imageDisabledFilename = src.imageDisabledFilename
  self:createOverlay(self.OVERLAY_DISABLED, self.imageDisabledFilename)
  self.imageDisabledColor = {
    src.imageDisabledColor[1],
    src.imageDisabledColor[2],
    src.imageDisabledColor[3],
    src.imageDisabledColor[4]
  }
  self.imagePressedColor = {
    src.imagePressedColor[1],
    src.imagePressedColor[2],
    src.imagePressedColor[3],
    src.imagePressedColor[4]
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
  self.text = src.text
  self.textBold = src.textBold
  self.textSize = src.textSize
  self.textOffset = {
    src.textOffset[1],
    src.textOffset[2]
  }
  self.textDisabledColor = {
    src.textDisabledColor[1],
    src.textDisabledColor[2],
    src.textDisabledColor[3],
    src.textDisabledColor[4]
  }
  self.textColor = {
    src.textColor[1],
    src.textColor[2],
    src.textColor[3],
    src.textColor[4]
  }
  self.text2Bold = src.text2Bold
  self.text2Size = src.text2Size
  self.text2Offset = {
    src.text2Offset[1],
    src.text2Offset[2]
  }
  self.text2DisabledColor = {
    src.text2DisabledColor[1],
    src.text2DisabledColor[2],
    src.text2DisabledColor[3],
    src.text2DisabledColor[4]
  }
  self.text2Color = {
    src.text2Color[1],
    src.text2Color[2],
    src.text2Color[3],
    src.text2Color[4]
  }
  self.onClick = src.onClick
  self.onLeave = src.onLeave
  self.onFocus = src.onFocus
end
function ButtonElement:onOpen()
  ButtonElement:superClass().onOpen(self)
end
function ButtonElement:onClose()
  ButtonElement:superClass().onClose(self)
  self:reset()
end
function ButtonElement:reset()
  ButtonElement:superClass().reset(self)
  self.state = ButtonElement.STATE_NORMAL
  self.mouseDown = false
end
function ButtonElement:getIsActive()
  return not self.disabled and self.visible
end
function ButtonElement:setDisabled(disabled)
  self.disabled = disabled
end
function ButtonElement:setText(text)
  self.text = text
end
function ButtonElement:getOverlayColor()
  if self.disabled then
    return self.imageDisabledColor
  elseif self.state == ButtonElement.STATE_PRESSED then
    return self.imagePressedColor
  elseif self.state == ButtonElement.STATE_FOCUSED then
    return self.imageFocusedColor
  end
  return self.imageColor
end
function ButtonElement:getTextColor()
  if self.disabled then
    return self.textDisabledColor
  else
    return self.textColor
  end
end
function ButtonElement:getText2Color()
  if self.disabled then
    return self.text2DisabledColor
  else
    return self.text2Color
  end
end
function ButtonElement:setImageFilename(filename)
  self.imageFilename = filename
  self:createOverlay(ButtonElement.OVERLAY_NORMAL, self.imageFilename)
end
function ButtonElement:setImageFocusedFilename(filename)
  self.imageFocusedFilename = filename
  self:createOverlay(ButtonElement.OVERLAY_FOCUSED, self.imageFocusedFilename)
end
function ButtonElement:setImagePressedFilename(filename)
  self.imagePressedFilename = filename
  self:createOverlay(ButtonElement.OVERLAY_PRESSED, self.imagePressedFilename)
end
function ButtonElement:setImageDisabledFilename(filename)
  self.imageDisabledFilename = filename
  self:createOverlay(ButtonElement.OVERLAY_DISABLED, self.imageDisabledFilename)
end
function ButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if ButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    local ret = false
    if not eventUsed and self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
      FocusManager:setFocus(self)
      ret = true
      self.state = ButtonElement.STATE_FOCUSED
      if self.onFocus ~= nil then
        self.mouseEntered = true
        if self.target ~= nil then
          self.onFocus(self.target, self)
        else
          self.onFocus(self)
        end
      end
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
      end
      if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
        self.mouseDown = false
        if self.onClick ~= nil then
          if self.target ~= nil then
            self.onClick(self.target, self)
          else
            self.onClick(self)
          end
        end
      end
      if self.mouseDown then
        self.state = ButtonElement.STATE_PRESSED
      end
    else
      FocusManager:unsetFocus(self)
      if self.onLeave ~= nil and self.mouseEntered then
        self.mouseEntered = false
        if self.target ~= nil then
          self.onLeave(self.target, self)
        else
          self.onLeave(self)
        end
      end
      self.mouseDown = false
      if not self.focusActive then
        self.state = ButtonElement.STATE_NORMAL
      end
    end
    return ret
  end
  return eventUsed
end
function ButtonElement:keyEvent(unicode, sym, modifier, isDown)
  if self:getIsActive() and ButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown) then
    return true
  end
  return false
end
function ButtonElement:update(dt)
  ButtonElement:superClass().update(self, dt)
end
function ButtonElement:draw()
  if self.visible then
    local overlay
    if self.disabled then
      overlay = self.overlays[ButtonElement.OVERLAY_DISABLED]
      if overlay == nil then
        overlay = self.overlays[ButtonElement.OVERLAY_NORMAL]
      end
    else
      overlay = self.overlays[self.state]
      if overlay == nil then
        if self.state == ButtonElement.STATE_PRESSED then
          overlay = self.overlays[ButtonElement.OVERLAY_FOCUSED]
        end
        if overlay == nil then
          overlay = self.overlays[ButtonElement.OVERLAY_NORMAL]
        end
      end
    end
    if overlay == nil then
      if self.state == ButtonElement.STATE_PRESSED then
        overlay = self.overlays[ButtonElement.OVERLAY_FOCUSED]
      end
      if overlay == nil then
        overlay = self.overlays[ButtonElement.OVERLAY_NORMAL]
      end
    end
    if overlay ~= nil then
      setOverlayColor(overlay, unpack(self:getOverlayColor()))
      renderOverlay(overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    if self.text ~= nil and self.text ~= "" then
      setTextAlignment(RenderText.ALIGN_LEFT)
      if self.text2Size > 0 then
        setTextBold(self.text2Bold)
        setTextColor(unpack(self:getText2Color()))
        renderText(self.absPosition[1] + self.text2Offset[1], self.absPosition[2] + self.text2Offset[2], self.text2Size, self.text)
      end
      setTextBold(self.textBold)
      setTextColor(unpack(self:getTextColor()))
      renderText(self.absPosition[1] + self.textOffset[1], self.absPosition[2] + self.textOffset[2], self.textSize, self.text)
      setTextBold(false)
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextColor(1, 1, 1, 1)
    end
  end
  ButtonElement:superClass().draw(self)
end
function ButtonElement:canReceiveFocus()
  return not self.disabled and not not self:getIsVisible()
end
function ButtonElement:onFocusLeave()
  self.state = ButtonElement.STATE_NORMAL
  if self.onLeave ~= nil then
    if self.target ~= nil then
      self.onLeave(self.target, self)
    else
      self.onLeave(self)
    end
  end
end
function ButtonElement:onFocusEnter()
  self.state = ButtonElement.STATE_FOCUSED
  if self.onFocus ~= nil then
    if self.target ~= nil then
      self.onFocus(self.target, self)
    else
      self.onFocus(self)
    end
  end
end
function ButtonElement:onFocusActivate()
  if not self.disabled and self.onClick ~= nil then
    if self.target ~= nil then
      self.onClick(self.target, self)
    else
      self.onClick(self)
    end
  end
end
function ButtonElement:createOverlay(index, imageFilename)
  if self.overlays[index] ~= nil then
    delete(self.overlays[index])
    self.overlays[index] = nil
  end
  if imageFilename ~= nil then
    local imageFilename = string.gsub(imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.overlays[index] = overlay
    end
  end
end
