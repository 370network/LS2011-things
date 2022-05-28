TextInputElement = {}
TextInputElement.STATE_NORMAL = 1
TextInputElement.STATE_PRESSED = 2
TextInputElement.STATE_FOCUSED = 3
local TextInputElement_mt = Class(TextInputElement, GuiElement)
function TextInputElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = TextInputElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.overlays = {}
  instance.state = TextInputElement.STATE_NORMAL
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
  instance.alignment = RenderText.ALIGN_CENTER
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
  instance.forcePressed = false
  instance.cursorBlinkTime = 0
  instance.cursorBlinkInterval = 400
  instance.cursorOffset = {0, 0}
  instance.cursorSize = {0.0016, 0.029}
  instance.cursorNeededSize = {
    instance.cursorOffset[1] + instance.cursorSize[1],
    instance.cursorOffset[2] + instance.cursorSize[2]
  }
  instance.cursorPosition = 1
  instance.firstVisibleCharacterPosition = 1
  instance.lastVisibleCharacterPosition = 1
  instance.maxCharacters = nil
  instance.maxTextWidth = nil
  instance.frontDotsText = "..."
  instance.backDotsText = "..."
  return instance
end
function TextInputElement:loadFromXML(xmlFile, key)
  TextInputElement:superClass().loadFromXML(self, xmlFile, key)
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
  local text = getXMLString(xmlFile, key .. "#text")
  if text ~= nil then
    if text:sub(1, 6) == "$l10n_" then
      text = g_i18n:getText(text:sub(7))
    end
    self:setText(text)
  end
  local onTextChanged = getXMLString(xmlFile, key .. "#onTextChanged")
  if onTextChanged ~= nil then
    if self.target ~= nil then
      self.onTextChanged = self.target[onTextChanged]
    else
      loadstring("g_asdasd_tempFunc = " .. onTextChanged)()
      self.onTextChanged = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local onEnterPressed = getXMLString(xmlFile, key .. "#onEnterPressed")
  if onEnterPressed ~= nil then
    if self.target ~= nil then
      self.onEnterPressed = self.target[onEnterPressed]
    else
      loadstring("g_asdasd_tempFunc = " .. onEnterPressed)()
      self.onEnterPressed = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local onEscPressed = getXMLString(xmlFile, key .. "#onEscPressed")
  if onEscPressed ~= nil then
    if self.target ~= nil then
      self.onEscPressed = self.target[onEscPressed]
    else
      loadstring("g_asdasd_tempFunc = " .. onEscPressed)()
      self.onEscPressed = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local onIsUnicodeAllowed = getXMLString(xmlFile, key .. "#onIsUnicodeAllowed")
  if onIsUnicodeAllowed ~= nil then
    if self.target ~= nil then
      self.onIsUnicodeAllowed = self.target[onIsUnicodeAllowed]
    else
      loadstring("g_asdasd_tempFunc = " .. onIsUnicodeAllowed)()
      self.onIsUnicodeAllowed = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  local textColor = self:getColorArray(getXMLString(xmlFile, key .. "#textColor"))
  if textColor ~= nil then
    self.textColor = textColor
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
  local alignment = getXMLString(xmlFile, key .. "#alignment")
  if alignment ~= nil then
    alignment = alignment:lower()
    if alignment == "right" then
      self.alignment = RenderText.ALIGN_RIGHT
    elseif alignment == "center" then
      self.alignment = RenderText.ALIGN_CENTER
    else
      self.alignment = RenderText.ALIGN_LEFT
    end
  end
  local disabled = getXMLBool(xmlFile, key .. "#disabled")
  if disabled ~= nil then
    self.disabled = disabled
  end
  local maxCharacters = getXMLInt(xmlFile, key .. "#maxCharacters")
  if maxCharacters ~= nil then
    self.maxCharacters = maxCharacters
  end
  local maxTextWidth = getXMLFloat(xmlFile, key .. "#maxTextWidth")
  if maxTextWidth ~= nil then
    self.maxTextWidth = maxTextWidth
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
  local cursorFilename = getXMLString(xmlFile, key .. "#cursorFilename")
  if cursorFilename ~= nil then
    self.cursorFilename = cursorFilename
  end
  if self.cursorFilename ~= nil then
    local cursorFilename = string.gsub(self.cursorFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(cursorFilename)
    if overlay ~= 0 then
      self.cursorOverlay = overlay
    end
  end
  local cursorOffset = self:get2DArray(getXMLString(xmlFile, key .. "#cursorOffset"))
  if cursorOffset ~= nil then
    self.cursorOffset = cursorOffset
  end
  local cursorSize = self:get2DArray(getXMLString(xmlFile, key .. "#cursorSize"))
  if cursorSize ~= nil then
    self.cursorSize = cursorSize
  end
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_NORMAL] = overlay
    end
  end
  if self.imagePressedFilename ~= nil then
    local imagePressedFilename = string.gsub(self.imagePressedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imagePressedFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_PRESSED] = overlay
    end
  end
  if self.imageFocusedFilename ~= nil then
    local imageFocusedFilename = string.gsub(self.imageFocusedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFocusedFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_FOCUSED] = overlay
    end
  end
  if self.overlays[TextInputElement.STATE_PRESSED] == nil then
    self.overlays[TextInputElement.STATE_PRESSED] = self.overlays[TextInputElement.STATE_FOCUSED]
  end
  if self.overlays[TextInputElement.STATE_FOCUSED] == nil then
    self.overlays[TextInputElement.STATE_FOCUSED] = self.overlays[TextInputElement.STATE_PRESSED]
  end
  if self.overlays[TextInputElement.STATE_PRESSED] == nil then
    self.overlays[TextInputElement.STATE_PRESSED] = self.overlays[TextInputElement.STATE_NORMAL]
  end
  if self.overlays[TextInputElement.STATE_FOCUSED] == nil then
    self.overlays[TextInputElement.STATE_FOCUSED] = self.overlays[TextInputElement.STATE_NORMAL]
  end
  self:_finalize()
end
function TextInputElement:saveToXML(xmlFile, key)
  TextInputElement:superClass().saveToXML(self, xmlFile, key)
end
function TextInputElement:loadProfile(profile)
  TextInputElement:superClass().loadProfile(self, profile)
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
  local maxCharacters = tonumber(profile:getValue("maxCharacters"))
  if maxCharacters ~= nil then
    self.maxCharacters = maxCharacters
  end
  local maxTextWidth = tonumber(profile:getValue("maxTextWidth"))
  if maxTextWidth ~= nil then
    self.maxTextWidth = maxTextWidth
  end
  local textColor = self:getColorArray(profile:getValue("textColor"))
  if textColor ~= nil then
    self.textColor = textColor
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
  local alignment = profile:getValue("alignment")
  if alignment ~= nil then
    alignment = alignment:lower()
    if alignment == "right" then
      self.alignment = RenderText.ALIGN_RIGHT
    elseif alignment == "center" then
      self.alignment = RenderText.ALIGN_CENTER
    else
      self.alignment = RenderText.ALIGN_LEFT
    end
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
  local cursorFilename = profile:getValue("cursorFilename")
  if cursorFilename ~= nil then
    self.cursorFilename = cursorFilename
  end
  local cursorOffset = self:get2DArray(profile:getValue("cursorOffset"))
  if cursorOffset ~= nil then
    self.cursorOffset = cursorOffset
  end
  local cursorSize = self:get2DArray(profile:getValue("cursorSize"))
  if cursorSize ~= nil then
    self.cursorSize = cursorSize
  end
  self:_finalize()
end
function TextInputElement:copyAttributes(src)
  TextInputElement:superClass().copyAttributes(self, src)
  self.imageFilename = src.imageFilename
  if self.imageFilename ~= nil then
    local imageFilename = string.gsub(self.imageFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_NORMAL] = overlay
    end
  end
  self.imagePressedFilename = src.imagePressedFilename
  if self.imagePressedFilename ~= nil then
    local imagePressedFilename = string.gsub(self.imagePressedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imagePressedFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_PRESSED] = overlay
    end
  end
  self.imageFocusedFilename = src.imageFocusedFilename
  if self.imageFocusedFilename ~= nil then
    local imageFocusedFilename = string.gsub(self.imageFocusedFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(imageFocusedFilename)
    if overlay ~= 0 then
      self.overlays[TextInputElement.STATE_FOCUSED] = overlay
    end
  end
  self.text = src.text
  self.textColor = {
    src.textColor[1],
    src.textColor[2],
    src.textColor[3],
    src.textColor[4]
  }
  self.textOffset = {
    src.textOffset[1],
    src.textOffset[2]
  }
  self.text2Offset = {
    src.text2Offset[1],
    src.text2Offset[2]
  }
  self.textSize = src.textSize
  self.textBold = src.textBold
  self.text2Color = {
    src.text2Color[1],
    src.text2Color[2],
    src.text2Color[3],
    src.text2Color[4]
  }
  self.textBold = src.textBold
  self.text2Size = src.text2Size
  self.text2Bold = src.text2Bold
  self.alignment = src.alignment
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
  self.maxCharacters = src.maxCharacters
  self.maxTextWidth = src.maxTextWidth
  self.cursorFilename = src.cursorFilename
  if self.cursorFilename ~= nil then
    local cursorFilename = string.gsub(self.cursorFilename, "$l10nSuffix", g_gui.languageSuffix)
    local overlay = createImageOverlay(cursorFilename)
    if overlay ~= 0 then
      self.cursorOverlay = overlay
    end
  end
  self.cursorOffset = {
    src.cursorOffset[1],
    src.cursorOffset[2]
  }
  self.cursorSize = {
    src.cursorSize[1],
    src.cursorSize[2]
  }
  self.onTextChanged = src.onTextChanged
  self.onEnterPressed = src.onEnterPressed
  self.onEscPressed = src.onEscPressed
  self.onIsUnicodeAllowed = src.onIsUnicodeAllowed
  self:_finalize()
end
function TextInputElement:_finalize()
  self.cursorNeededSize = {
    self.cursorOffset[1] + self.cursorSize[1],
    self.cursorOffset[2] + self.cursorSize[2]
  }
  if not self.maxTextWidth and (self.alignment == RenderText.ALIGN_CENTER or self.alignment == RenderText.ALIGN_RIGHT) then
    print("Error: TextInputElement loading using \"center\" or \"right\" alignment requires specification of \"maxTextWidth\"")
  end
  if self.maxTextWidth and self.maxTextWidth <= getTextWidth(self.textSize, self.frontDotsText) + self.cursorNeededSize[1] + getTextWidth(self.textSize, self.backDotsText) then
    print(string.format("Error: TextInputElement loading specified \"maxTextWidth\" is too small (%.4f) to display needed data", self.maxTextWidth))
  end
end
function TextInputElement:onOpen()
  TextInputElement:superClass().onOpen(self)
end
function TextInputElement:onClose()
  TextInputElement:superClass().onClose(self)
  self:reset()
end
function TextInputElement:reset()
  TextInputElement:superClass().reset(self)
  self.state = TextInputElement.STATE_NORMAL
  self.mouseDown = false
  if self.isRepeatingSpecialKeyDown then
    self:_stopSpecialKeyRepeating()
  end
end
function TextInputElement:getIsActive()
  return not self.disabled and self.visible
end
function TextInputElement:setDisabled(disabled)
  self.disabled = disabled
end
function TextInputElement:setText(text)
  text = tostring(text)
  local textLength = utf8Strlen(text)
  if self.maxCharacters and textLength > self.maxCharacters then
    text = utf8Substr(text, 0, self.maxCharacters)
    textLength = utf8Strlen(text)
  end
  self.text = text
  self.cursorPosition = textLength + 1
  self:updateVisibleTextElements()
end
function TextInputElement:setForcePressed(force)
  self.forcePressed = force
  if self.forcePressed then
    self.state = TextInputElement.STATE_PRESSED
  else
    self.state = TextInputElement.STATE_NORMAL
  end
  if self.isRepeatingSpecialKeyDown then
    self:_stopSpecialKeyRepeating()
  end
  self:updateVisibleTextElements()
end
function TextInputElement:getOverlayColor()
  if self.disabled then
    return self.imageDisabledColor
  elseif self.state == TextInputElement.STATE_PRESSED then
    return self.imagePressedColor
  elseif self.state == TextInputElement.STATE_FOCUSED then
    return self.imageFocusedColor
  end
  return self.imageColor
end
function TextInputElement:getTextColor()
  if self.disabled then
    return self.textDisabledColor
  else
    return self.textColor
  end
end
function TextInputElement:getText2Color()
  if self.disabled then
    return self.text2DisabledColor
  else
    return self.text2Color
  end
end
function TextInputElement:getIsUnicodeAllowed(unicode)
  if unicode == 13 or unicode == 10 then
    return false
  end
  if not getCanRenderUnicode(unicode) then
    return false
  end
  if self.onIsUnicodeAllowed then
    if self.target ~= nil then
      return self.onIsUnicodeAllowed(self.target, unicode)
    else
      return self.onIsUnicodeAllowed(unicode)
    end
  else
    return true
  end
end
function TextInputElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if TextInputElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    if not self.forcePressed then
      if eventUsed then
        self.state = TextInputElement.STATE_NORMAL
      end
      if not eventUsed and self:checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
        FocusManager:setFocus(self)
        eventUsed = true
        if self.state == TextInputElement.STATE_NORMAL then
          self.state = TextInputElement.STATE_FOCUSED
        end
        if isDown and button == Input.MOUSE_BUTTON_LEFT then
          self.mouseDown = true
          self.state = TextInputElement.STATE_PRESSED
        end
        if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
          self.mouseDown = false
          self.state = TextInputElement.STATE_PRESSED
          self:setForcePressed(true)
        end
      else
        if isDown and button == Input.MOUSE_BUTTON_LEFT or self.mouseDown or self.state ~= TextInputElement.STATE_PRESSED then
          self.state = TextInputElement.STATE_NORMAL
        end
        self.mouseDown = false
      end
    else
    end
  end
  return eventUsed
end
function TextInputElement:moveCursorLeft()
  self.cursorPosition = math.max(1, self.cursorPosition - 1)
end
function TextInputElement:moveCursorRight()
  self.cursorPosition = math.min(utf8Strlen(self.text) + 1, self.cursorPosition + 1)
end
function TextInputElement:deleteText(deleteRightCharacterFromCursor)
  local textLength = utf8Strlen(self.text)
  if 0 < textLength then
    local canDelete = false
    local deleteOffset
    if deleteRightCharacterFromCursor then
      if textLength >= self.cursorPosition then
        canDelete = true
        deleteOffset = 0
      end
    elseif self.cursorPosition > 1 then
      canDelete = true
      deleteOffset = -1
    end
    if canDelete then
      self.text = (self.cursorPosition + deleteOffset > 1 and utf8Substr(self.text, 0, self.cursorPosition + deleteOffset - 1) or "") .. (textLength > self.cursorPosition + deleteOffset and utf8Substr(self.text, self.cursorPosition + deleteOffset, -1) or "")
      self.cursorPosition = self.cursorPosition + deleteOffset
      if self.onTextChanged ~= nil then
        if self.target ~= nil then
          self.onTextChanged(self.target, self)
        else
          self.onTextChanged(self)
        end
      end
    end
  end
end
function TextInputElement:_stopSpecialKeyRepeating()
  self.isRepeatingSpecialKeyDown = false
  self.repeatingSpecialKeySym = nil
  self.repeatingSpecialKeyDelayTime = nil
  self.repeatingSpecialKeyRemainingDelayTime = nil
end
function TextInputElement:keyEvent(unicode, sym, modifier, isDown)
  TextInputElement:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  if self.isRepeatingSpecialKeyDown and not isDown and self.repeatingSpecialKeySym == sym then
    self:_stopSpecialKeyRepeating()
  end
  if self:getIsActive() and self.state == TextInputElement.STATE_PRESSED and isDown then
    local isSpecialKey = false
    local wasSpecialKey = false
    local symLeft = 276
    local symRight = 275
    local symDelete = 127
    local symBackspace = 8
    local symEscape = 27
    local symHome = 278
    local symEnd = 279
    local symEnter = 13
    local startSpecialKeyRepeating = false
    if sym == symLeft then
      self:moveCursorLeft()
      startSpecialKeyRepeating = true
      wasSpecialKey = true
    elseif sym == symRight then
      self:moveCursorRight()
      startSpecialKeyRepeating = true
      wasSpecialKey = true
    elseif sym == symHome then
      self.cursorPosition = 1
      wasSpecialKey = true
    elseif sym == symEnd then
      self.cursorPosition = utf8Strlen(self.text) + 1
      wasSpecialKey = true
    elseif sym == symDelete then
      self:deleteText(true)
      startSpecialKeyRepeating = true
      wasSpecialKey = true
    elseif sym == symBackspace then
      self:deleteText(false)
      startSpecialKeyRepeating = true
      wasSpecialKey = true
    elseif sym == symEscape then
      self:setForcePressed(not self.forcePressed)
      if self.onEscPressed ~= nil then
        if self.target ~= nil then
          self.onEscPressed(self.target, self)
        else
          self.onEscPressed(self)
        end
      end
      wasSpecialKey = true
    elseif sym == symEnter then
      if self.onEnterPressed ~= nil then
        if self.target ~= nil then
          self.onEnterPressed(self.target, self)
        else
          self.onEnterPressed(self)
        end
      end
      wasSpecialKey = true
    end
    if startSpecialKeyRepeating then
      self.isRepeatingSpecialKeyDown = true
      self.repeatingSpecialKeySym = sym
      self.repeatingSpecialKeyDelayTime = FocusManager.DELAY_TIME
      self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
    end
    if not wasSpecialKey and self:getIsUnicodeAllowed(unicode) then
      local textLength = utf8Strlen(self.text)
      if not self.maxCharacters or textLength < self.maxCharacters then
        self.text = (self.cursorPosition > 1 and utf8Substr(self.text, 0, self.cursorPosition - 1) or "") .. unicodeToUtf8(unicode) .. (textLength >= self.cursorPosition and utf8Substr(self.text, self.cursorPosition - 1) or "")
        self.cursorPosition = self.cursorPosition + 1
        if self.onTextChanged ~= nil then
          if self.target ~= nil then
            self.onTextChanged(self.target, self)
          else
            self.onTextChanged(self)
          end
        end
      end
    end
    self:updateVisibleTextElements()
  end
end
function TextInputElement:update(dt)
  TextInputElement:superClass().update(self, dt)
  self.cursorBlinkTime = self.cursorBlinkTime + dt
  while self.cursorBlinkTime > 2 * self.cursorBlinkInterval do
    self.cursorBlinkTime = self.cursorBlinkTime - 2 * self.cursorBlinkInterval
  end
  if self.isRepeatingSpecialKeyDown then
    self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyRemainingDelayTime - dt
    if self.repeatingSpecialKeyRemainingDelayTime <= 0 then
      local symLeft = 276
      local symRight = 275
      local symDelete = 127
      local symBackspace = 8
      if self.repeatingSpecialKeySym == symLeft then
        self:moveCursorLeft()
      elseif self.repeatingSpecialKeySym == symRight then
        self:moveCursorRight()
      elseif self.repeatingSpecialKeySym == symDelete then
        self:deleteText(true)
      elseif self.repeatingSpecialKeySym == symBackspace then
        self:deleteText(false)
      end
      self:updateVisibleTextElements()
      self.repeatingSpecialKeyDelayTime = math.max(FocusManager.DELAY_TIME_MIN, self.repeatingSpecialKeyDelayTime * 0.1 ^ (dt / 100))
      self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
    end
  end
end
function TextInputElement:shouldFocusChange(direction)
  return not self.forcePressed
end
function TextInputElement:onFocusLeave()
  self:setForcePressed(false)
  self.state = TextInputElement.STATE_NORMAL
  if self.onLeave ~= nil then
    if self.target ~= nil then
      self.onLeave(self.target, self)
    else
      self.onLeave(self)
    end
  end
end
function TextInputElement:onFocusEnter()
  self.state = TextInputElement.STATE_FOCUSED
  if self.onFocus ~= nil then
    if self.target ~= nil then
      self.onFocus(self.target, self)
    else
      self.onFocus(self)
    end
  end
end
function TextInputElement:onFocusActivate()
  if self.forcePressed then
    self:setForcePressed(false)
    self.state = TextInputElement.STATE_FOCUSED
  else
    self:setForcePressed(true)
  end
end
function TextInputElement:_drawTextPart(text, textXPos, displacementX, textYPos)
  local textWidth = 0
  if text ~= "" then
    setTextBold(self.textBold)
    textWidth = getTextWidth(self.textSize, text)
    local alignmentDisplacement = 0
    if self.alignment == RenderText.ALIGN_CENTER then
      alignmentDisplacement = textWidth * 0.5
    elseif self.alignment == RenderText.ALIGN_RIGHT then
      alignmentDisplacement = textWidth
    end
    if 0 < self.text2Size then
      setTextBold(self.text2Bold)
      setTextColor(unpack(self:getText2Color()))
      renderText(textXPos + alignmentDisplacement + displacementX + (self.text2Offset[1] - self.textOffset[1]), textYPos + (self.text2Offset[2] - self.textOffset[2]), self.text2Size, text)
    end
    setTextBold(self.textBold)
    setTextColor(unpack(self:getTextColor()))
    renderText(textXPos + alignmentDisplacement + displacementX, textYPos, self.textSize, text)
  end
  return textWidth
end
function TextInputElement:_drawCursor(textXPos, displacementX, textYPos)
  if self.cursorBlinkTime < self.cursorBlinkInterval and self.cursorOverlay ~= nil then
    renderOverlay(self.cursorOverlay, textXPos + displacementX + self.cursorOffset[1], textYPos + self.cursorOffset[2], self.cursorSize[1], self.cursorSize[2])
  end
  return self.cursorNeededSize[1]
end
function TextInputElement:draw()
  if self.visible then
    local overlay = self.overlays[self.state]
    if overlay ~= nil then
      setOverlayColor(overlay, unpack(self:getOverlayColor()))
      renderOverlay(overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
    end
    setTextBold(self.textBold)
    setTextAlignment(self.alignment)
    local textLength = utf8Strlen(self.text)
    local neededWidth = self:_getNeededTextWidth()
    local textXPos = self.absPosition[1] + self.textOffset[1]
    if self.alignment == RenderText.ALIGN_CENTER then
      textXPos = textXPos + self.maxTextWidth * 0.5 - neededWidth * 0.5
    elseif self.alignment == RenderText.ALIGN_RIGHT then
      textXPos = textXPos + self.maxTextWidth - neededWidth
    end
    local textYPos = self.absPosition[2] + self.textOffset[2]
    local displacementX = 0
    if self.areFrontDotsVisible then
      local additionalDisplacement = self:_drawTextPart(self.frontDotsText, textXPos, displacementX, textYPos)
      displacementX = displacementX + additionalDisplacement
    end
    if self.isVisibleTextPart1Visible then
      local additionalDisplacement = self:_drawTextPart(self.visibleTextPart1, textXPos, displacementX, textYPos)
      displacementX = displacementX + additionalDisplacement
    end
    if self.isCursorVisible then
      local additionalDisplacement = self:_drawCursor(textXPos, displacementX, textYPos)
      displacementX = displacementX + additionalDisplacement
    end
    if self.isVisibleTextPart2Visible then
      local additionalDisplacement = self:_drawTextPart(self.visibleTextPart2, textXPos, displacementX, textYPos)
      displacementX = displacementX + additionalDisplacement
    end
    if self.areBackDotsVisible then
      local additionalDisplacement = self:_drawTextPart(self.backDotsText, textXPos, displacementX, textYPos)
      displacementX = displacementX + additionalDisplacement
    end
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
  end
end
function TextInputElement:updateVisibleTextElements()
  self.isCursorVisible = false
  self.isVisibleTextPart1Visible = false
  self.visibleTextPart1 = ""
  self.isVisibleTextPart2Visible = false
  self.visibleTextPart2 = ""
  self.areFrontDotsVisible = false
  self.areBackDotsVisible = false
  setTextBold(self.textBold)
  local textLength = utf8Strlen(self.text)
  local availableTextWidth = self:_getAvailableTextWidth()
  if self:getIsActive() and self.state == TextInputElement.STATE_PRESSED then
    self.isCursorVisible = true
    if self.cursorPosition < self.firstVisibleCharacterPosition then
      self.firstVisibleCharacterPosition = self.cursorPosition
    end
    if self.firstVisibleCharacterPosition > 1 then
      self.areFrontDotsVisible = true
    end
    local textInvisibleFrontTrimmed = utf8Substr(self.text, self.firstVisibleCharacterPosition - 1)
    local textWidthInvisibleFrontTrimmed = getTextWidth(self.textSize, textInvisibleFrontTrimmed)
    availableTextWidth = self:_getAvailableTextWidth()
    if availableTextWidth and textWidthInvisibleFrontTrimmed > availableTextWidth and textLength >= self.cursorPosition then
      self.areBackDotsVisible = true
      availableTextWidth = self:_getAvailableTextWidth()
    end
    local visibleText = TextInputElement._limitTextToAvailableWidth(textInvisibleFrontTrimmed, self.textSize, availableTextWidth)
    local visibleTextWidth = getTextWidth(self.textSize, visibleText)
    local visibleTextLength = utf8Strlen(visibleText)
    if availableTextWidth and self.cursorPosition > self.firstVisibleCharacterPosition + visibleTextLength then
      self.areFrontDotsVisible = true
      availableTextWidth = self:_getAvailableTextWidth()
      local textTrimmedAtCursor = utf8Substr(textInvisibleFrontTrimmed, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
      visibleText = TextInputElement._limitTextToAvailableWidth(textTrimmedAtCursor, self.textSize, availableTextWidth, true)
      visibleTextWidth = getTextWidth(self.textSize, visibleText)
      visibleTextLength = utf8Strlen(visibleText)
      self.firstVisibleCharacterPosition = self.cursorPosition - visibleTextLength
    end
    if availableTextWidth and not self.areBackDotsVisible and self.firstVisibleCharacterPosition > 1 then
      local lastCharacterPosition = visibleTextLength + self.firstVisibleCharacterPosition
      local nextCharacter = utf8Substr(self.text, self.firstVisibleCharacterPosition - 1, 1)
      local additionalCharacterWidth = getTextWidth(self.textSize, nextCharacter)
      if availableTextWidth >= visibleTextWidth + additionalCharacterWidth and self.firstVisibleCharacterPosition > 1 then
        while availableTextWidth >= visibleTextWidth + additionalCharacterWidth and self.firstVisibleCharacterPosition > 1 do
          self.firstVisibleCharacterPosition = self.firstVisibleCharacterPosition - 1
          visibleTextWidth = visibleTextWidth + additionalCharacterWidth
          nextCharacter = utf8Substr(self.text, self.firstVisibleCharacterPosition - 1, 1)
          additionalCharacterWidth = getTextWidth(self.textSize, nextCharacter)
        end
        if self.firstVisibleCharacterPosition > 1 then
          self.areFrontDotsVisible = false
          local availableWidthWithoutFrontDots = self:_getAvailableTextWidth()
          self.areFrontDotsVisible = true
          local neededWidthForCompleteText = getTextWidth(self.textSize, self.text)
          if availableWidthWithoutFrontDots >= neededWidthForCompleteText then
            self.areFrontDotsVisible = false
            self.firstVisibleCharacterPosition = 1
          end
        else
          self.areFrontDotsVisible = false
        end
        visibleText = utf8Substr(self.text, self.firstVisibleCharacterPosition - 1, lastCharacterPosition)
      end
    end
    self.isVisibleTextPart1Visible = true
    self.visibleTextPart1 = utf8Substr(visibleText, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
    if visibleTextLength > self.cursorPosition - self.firstVisibleCharacterPosition then
      self.isVisibleTextPart2Visible = true
      self.visibleTextPart2 = utf8Substr(visibleText, self.cursorPosition - self.firstVisibleCharacterPosition)
    end
  else
    local textWidth = getTextWidth(self.textSize, self.text)
    if availableTextWidth and availableTextWidth < textWidth then
      self.areBackDotsVisible = true
      availableTextWidth = self:_getAvailableTextWidth()
    end
    if availableTextWidth and textWidth > availableTextWidth then
      self.visibleTextPart1 = self._limitTextToAvailableWidth(self.text, self.textSize, availableTextWidth)
      self.isVisibleTextPart1Visible = true
    else
      self.visibleTextPart1 = self.text
      self.isVisibleTextPart1Visible = true
    end
  end
  setTextBold(false)
end
function TextInputElement._limitTextToAvailableWidth(text, textSize, availableWidth, trimFront)
  local resultingText = text
  local indexOfFirstCharacter = 0
  local indexOfLastCharacter = utf8Strlen(text)
  if availableWidth then
    if trimFront then
      while availableWidth < getTextWidth(textSize, resultingText) do
        resultingText = utf8Substr(resultingText, 1)
        indexOfFirstCharacter = indexOfFirstCharacter + 1
      end
    else
      local textLength = utf8Strlen(resultingText)
      while availableWidth < getTextWidth(textSize, resultingText) do
        textLength = textLength - 1
        resultingText = utf8Substr(resultingText, 0, textLength)
        indexOfLastCharacter = indexOfLastCharacter - 1
      end
    end
  end
  return resultingText, indexOfFirstCharacter, indexOfLastCharacter
end
function TextInputElement:_getAvailableTextWidth()
  if not self.maxTextWidth then
    return nil
  end
  local availableTextWidth = self.maxTextWidth
  if self.areFrontDotsVisible then
    availableTextWidth = availableTextWidth - getTextWidth(self.textSize, self.frontDotsText)
  end
  if self.isCursorVisible then
    availableTextWidth = availableTextWidth - self.cursorNeededSize[1]
  end
  if self.areBackDotsVisible then
    availableTextWidth = availableTextWidth - getTextWidth(self.textSize, self.backDotsText)
  end
  return availableTextWidth
end
function TextInputElement:_getNeededTextWidth()
  local neededWidth = 0
  if self.areFrontDotsVisible then
    neededWidth = neededWidth + getTextWidth(self.textSize, self.frontDotsText)
  end
  if self.isVisibleTextPart1Visible then
    neededWidth = neededWidth + getTextWidth(self.textSize, self.visibleTextPart1)
  end
  if self.isCursorVisible then
    neededWidth = neededWidth + self.cursorNeededSize[1]
  end
  if self.isVisibleTextPart2Visible then
    neededWidth = neededWidth + getTextWidth(self.textSize, self.visibleTextPart2)
  end
  if self.areBackDotsVisible then
    neededWidth = neededWidth + getTextWidth(self.textSize, self.backDotsText)
  end
  return neededWidth
end
