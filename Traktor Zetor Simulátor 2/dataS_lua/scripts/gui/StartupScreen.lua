StartupScreen = {EVENTTYPE_VIDEO = 1, EVENTTYPE_PICTURE = 2}
local StartupScreen_mt = Class(StartupScreen)
function StartupScreen:new()
  local instance = {}
  setmetatable(instance, StartupScreen_mt)
  return instance
end
function StartupScreen:onCloseStartupScreen()
  self.videoElement:disposeVideo()
  self.pictureElement:setImageFilename(nil)
  self.pictureTimer = nil
  self.eventList = nil
  self.currentEventId = nil
end
function StartupScreen:onOpenStartupScreen()
  self.eventList = {}
  self:addStartupVideo("de", "dataS2/videos/AstragonLogo.ogv", true)
  self:addStartupPicture("pl", "dataS2/menu/intro01_pl.png", 3000)
  self:addStartupVideo("pl", "dataS2/videos/TechlandLogo_pl.ogv", true)
  self:addStartupPicture("en(trisynergy)", "dataS2/menu/ESRB_VideoWarning_en.png", 4000)
  self:addStartupPicture("en(trisynergy)", "dataS2/menu/introTriSynergy_en.png", 3000)
  self:addStartupVideo("de en en(trisynergy) cz pl fr es jp ru hu", "dataS2/videos/NvidiaLogo.ogv", true)
  self:addStartupVideo("de en en(trisynergy) cz pl fr es jp ru hu", "dataS2/videos/GIANTSLogo.ogv", false, {0.5, 0.5})
  self.currentEventId = 0
  self:showNextEvent()
end
function StartupScreen:addStartupVideo(languagesString, filename, isFullscreen, size)
  if self:shouldAddEvent(languagesString) then
    local videoEvent = {
      filename = filename,
      fullscreen = isFullscreen,
      size = size,
      eventType = StartupScreen.EVENTTYPE_VIDEO
    }
    table.insert(self.eventList, videoEvent)
  end
end
function StartupScreen:addStartupPicture(languagesString, filename, duration)
  if self:shouldAddEvent(languagesString) then
    local pictureEvent = {
      filename = filename,
      duration = duration,
      eventType = StartupScreen.EVENTTYPE_PICTURE
    }
    table.insert(self.eventList, pictureEvent)
  end
end
function StartupScreen:shouldAddEvent(languagesString)
  local languages = Utils.listToSet(Utils.splitString(" ", languagesString))
  return languages[g_languageShort] ~= nil
end
function StartupScreen:onVideoElementCreated(videoElement)
  self.videoElement = videoElement
  function self.videoElement.mouseEvent()
  end
  function self.videoElement.keyEvent()
  end
  self.videoElement:setVisible(false)
end
function StartupScreen:onPictureElementCreated(pictureElement)
  self.pictureElement = pictureElement
  self.pictureElement:setVisible(false)
end
function StartupScreen:showNextEvent()
  self.currentEventId = self.currentEventId + 1
  local nextEvent = self.eventList[self.currentEventId]
  if not nextEvent then
    return self:onStartupEnd()
  end
  if nextEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
    self.videoElement:setVisible(true)
    self.pictureElement:setVisible(false)
    self:playVideo(nextEvent)
  else
    self.pictureElement:setVisible(true)
    self.videoElement:setVisible(false)
    self:showPicture(nextEvent)
  end
end
function StartupScreen:playVideo(videoEvent)
  self.videoElement:changeVideo(videoEvent.filename)
  local adjustedVideoSizeX, adjustedVideoSizeY, adjustedVideoPositionX, adjustedVideoPositionY
  if videoEvent.fullscreen then
    adjustedVideoSizeX = 1
    adjustedVideoSizeY = 1
    adjustedVideoPositionX = 0
    adjustedVideoPositionY = 0
  else
    local x, y = getScreenModeInfo(getScreenMode())
    local aspectRatio = x / y
    adjustedVideoSizeX = videoEvent.size[1] / aspectRatio
    adjustedVideoSizeY = videoEvent.size[2]
    adjustedVideoPositionX = 0.5 * (1 - adjustedVideoSizeX)
    adjustedVideoPositionY = 0.5 * (1 - adjustedVideoSizeY)
  end
  self.videoElement:setSize(adjustedVideoSizeX, adjustedVideoSizeY)
  self.videoElement:setPosition(adjustedVideoPositionX, adjustedVideoPositionY)
  self.videoElement:playVideo()
  return true
end
function StartupScreen:showPicture(pictureEvent)
  self.pictureElement:setImageFilename(pictureEvent.filename)
  self.pictureTimer = addTimer(pictureEvent.duration, "onStartupEndEvent", self)
end
function StartupScreen:update(dt)
  local noButtonIsDown = true
  for d = 1, getNumOfGamepads() do
    for i = 1, Input.MAX_NUM_BUTTONS do
      local isDown = getInputButton(i - 1, d - 1) > 0
      if isDown then
        noButtonIsDown = false
        if not self.gamepadWasPressed then
          self:cancelCurrentEvent()
          self.gamepadWasPressed = true
        end
        break
      end
    end
  end
  if noButtonIsDown and self.gamepadWasPressed then
    self.gamepadWasPressed = nil
  end
end
function StartupScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if isDown then
    self:cancelCurrentEvent()
  end
end
function StartupScreen:keyEvent(unicode, sym, modifier, isDown)
  if isDown then
    self:cancelCurrentEvent()
  end
end
function StartupScreen:cancelCurrentEvent()
  local currentEvent = self.eventList[self.currentEventId]
  if currentEvent.eventType == StartupScreen.EVENTTYPE_VIDEO then
    self.videoElement:stopVideo()
  else
    removeTimer(self.pictureTimer)
  end
  self:onStartupEndEvent()
end
function StartupScreen:onStartupEndEvent()
  self.pictureTimer = nil
  self:showNextEvent()
end
function StartupScreen:onStartupEnd()
  g_gui:showGui("MainScreen")
end
