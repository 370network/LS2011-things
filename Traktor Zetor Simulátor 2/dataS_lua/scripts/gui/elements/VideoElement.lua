VideoElement = {}
local VideoElement_mt = Class(VideoElement, GuiElement)
function VideoElement:new(target, custom_mt)
  if custom_mt == nil then
    custom_mt = VideoElement_mt
  end
  local instance = GuiElement:new(target, custom_mt)
  instance.target = target
  instance.mouseDown = false
  instance.allowStop = true
  instance.isLooping = false
  instance.volume = 1
  return instance
end
function VideoElement:loadFromXML(xmlFile, key)
  VideoElement:superClass().loadFromXML(self, xmlFile, key)
  local videoFilename = getXMLString(xmlFile, key .. "#videoFilename")
  local isLooping = getXMLBool(xmlFile, key .. "#isLooping")
  if isLooping ~= nil then
    self.isLooping = isLooping
  end
  local allowStop = getXMLBool(xmlFile, key .. "#allowStop")
  if allowStop ~= nil then
    self.allowStop = allowStop
  end
  local volume = getXMLFloat(xmlFile, key .. "#volume")
  if volume ~= nil then
    self.volume = volume
  end
  local onEndVideo = getXMLString(xmlFile, key .. "#onEndVideo")
  if onEndVideo ~= nil then
    if self.target ~= nil then
      self.onEndVideo = self.target[onEndVideo]
    else
      loadstring("g_asdasd_tempFunc = " .. onEndVideo)()
      self.onEndVideo = g_asdasd_tempFunc
      g_asdasd_tempFunc = nil
    end
  end
  self:changeVideo(videoFilename)
end
function VideoElement:saveToXML(xmlFile, key)
  VideoElement:superClass().saveToXML(self, xmlFile, key)
end
function VideoElement:loadProfile(profile)
  VideoElement:superClass().loadProfile(self, profile)
  local videoFilename = profile:getValue("videoFilename")
  if videoFilename ~= nil then
    self.videoFilename = videoFilename
  end
  local volume = tonumber(profile:getValue("volume"))
  if volume ~= nil then
    self.volume = volume
  end
  local allowStop = profile:getValue("allowStop")
  if allowStop ~= nil then
    self.allowStop = allowStop:lower() == "true"
  end
  local isLooping = profile:getValue("isLooping")
  if isLooping ~= nil then
    self.isLooping = isLooping:lower() == "true"
  end
end
function VideoElement:copyAttributes(src)
  VideoElement:superClass().copyAttributes(self, src)
  self.videoFilename = src.videoFilename
  if self.videoFilename ~= nil then
    local videoFilename = string.gsub(self.videoFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.overlay = createVideoOverlay(videoFilename, self.isLooping, self.volume)
  end
  self.allowStop = src.allowStop
  self.volume = src.volume
end
function VideoElement:delete()
  self:disposeVideo()
  VideoElement:superClass().delete(self)
end
function VideoElement:disposeVideo()
  if self.overlay ~= nil then
    self:stopVideo()
    delete(self.overlay)
    self.overlay = nil
  end
end
function VideoElement:getIsActive()
  return self.visible
end
function VideoElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
  if self:getIsActive() then
    if VideoElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
      eventUsed = true
    end
    local ret = eventUsed
    if not eventUsed and self.allowStop then
      ret = true
      if isDown and self.overlay ~= nil then
        self:disposeVideo()
        if self.onEndVideo ~= nil then
          if self.target ~= nil then
            self.onEndVideo(self.target)
          else
            self.onEndVideo()
          end
        end
      end
      return ret
    end
  end
  return eventUsed
end
function VideoElement:keyEvent(unicode, sym, modifier, isDown)
  if self:getIsActive() then
    if VideoElement:superClass().keyEvent(self, unicode, sym, modifier, isDown) then
      eventUsed = true
    end
    local ret = eventUsed
    ret = true
    if isDown and self.overlay ~= nil then
      self:disposeVideo()
      if self.onEndVideo ~= nil then
        if self.target ~= nil then
          self.onEndVideo(self.target)
        else
          self.onEndVideo()
        end
      end
    end
    return ret
  end
  return eventUsed
end
function VideoElement:update(dt)
  VideoElement:superClass().update(self, dt)
  if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
    updateVideoOverlay(self.overlay)
  elseif self.overlay ~= nil then
    self:disposeVideo()
    if self.onEndVideo ~= nil then
      if self.target ~= nil then
        self.onEndVideo(self.target)
      else
        self.onEndVideo()
      end
    end
  end
end
function VideoElement:draw()
  if self.visible and self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
    renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
  end
  VideoElement:superClass().draw(self)
end
function VideoElement:playVideo()
  if self.overlay ~= nil then
    playVideoOverlay(self.overlay)
  end
end
function VideoElement:stopVideo()
  if self.overlay ~= nil and isVideoOverlayPlaying(self.overlay) then
    stopVideoOverlay(self.overlay)
  end
end
function VideoElement:changeVideo(newVideoFilename)
  self:disposeVideo()
  self.videoFilename = newVideoFilename
  if self.videoFilename ~= nil then
    local videoFilename = string.gsub(self.videoFilename, "$l10nSuffix", g_gui.languageSuffix)
    self.overlay = createVideoOverlay(videoFilename, self.isLooping, self.volume)
  end
end
