InGameMessage = {}
local InGameMessage_mt = Class(InGameMessage)
function InGameMessage:new()
  local instance = {}
  setmetatable(instance, InGameMessage_mt)
  instance.items = {}
  instance.title = ""
  instance.message = {}
  instance.width = 0.365714
  instance.height = 0.48762
  instance.posX = 0.5 - instance.width / 2
  instance.posY = 0.379048
  instance.titleTextSize = 0.025
  instance.titleTextSpacingY = instance.titleTextSize + 0.001
  instance.titleTextPosY = instance.posY + instance.height - instance.titleTextSize - 0.16
  instance.textSize = 0.019
  instance.textSpacingY = instance.textSize + 0.001
  instance.textPosY = instance.titleTextPosY - instance.textSpacingY - 0.003
  instance.fadeTime = 1000
  instance.visibleTime = 2000
  instance.visible = false
  instance.time = 0
  instance.showTrophy = false
  instance.alpha = 0
  local controllerPosX = instance.posX + 0.33
  local controllerPosY = instance.posY + 0.035
  local controllerWidth = 0.06
  local controllerHeight = 0.08
  instance:addItem(Overlay:new("backgroundOverlay", "dataS2/menu/inGameMessage_background.png", instance.posX, instance.posY, instance.width, instance.height))
  instance.trophyOverlay = Overlay:new("trophyOverlay", "dataS2/missions/trophy.png", instance.posX + instance.width - 0.075, instance.posY + instance.height - 0.15, 0.15, 0.19999999999999998)
  instance.mouseOverlay = Overlay:new("mouseOverlay", "dataS2/menu/mouseControlsHelp/mouseLMB.png", controllerPosX, controllerPosY, controllerWidth, controllerHeight)
  return instance
end
function InGameMessage:delete()
  for i = 1, table.getn(self.items) do
    self.items[i]:delete()
  end
  self.trophyOverlay:delete()
  self.mouseOverlay:delete()
end
function InGameMessage:addItem(item)
  table.insert(self.items, item)
end
function InGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
end
function InGameMessage:update(dt)
  if self.visible and g_gui.currentGui == nil then
    if InputBinding.hasEvent(InputBinding.SKIP_MESSAGE_BOX) and self.time >= self.fadeTime and self.time <= self.fadeTime + self.visibleTime then
      self:hideMessage()
    end
    self.time = self.time + dt
    self.alpha = math.min(1, self.time / self.fadeTime)
    if self.time > self.fadeTime + self.visibleTime then
      self.alpha = math.max(0, (self.fadeTime - (self.time - self.fadeTime - self.visibleTime)) / self.fadeTime)
    end
    if self.time > self.fadeTime * 2 + self.visibleTime then
      self.time = 0
      self.visible = false
    end
    if self.visible and self.time <= self.fadeTime + self.visibleTime and InputBinding.hasEvent(InputBinding.MENU_ACCEPT, true) then
      self:hideMessage()
    end
  end
end
function InGameMessage:showMessage(title, message, duration, showTrophy)
  self.message = message
  self.title = title
  self.visibleTime = duration
  self.time = 0
  self.showTrophy = showTrophy
  self.alpha = 0
  self.visible = true
end
function InGameMessage:hideMessage()
  self.time = self.fadeTime + self.visibleTime
end
function InGameMessage:draw()
  if self.visible and g_gui.currentGui == nil then
    for i = 1, table.getn(self.items) do
      self.items[i]:setColor(1, 1, 1, self.alpha)
      self.items[i]:render()
    end
    if self.showTrophy then
      self.trophyOverlay:setColor(1, 1, 1, self.alpha)
      self.trophyOverlay:render()
    end
    self.mouseOverlay:setColor(1, 1, 1, self.alpha)
    self.mouseOverlay:render()
    setTextColor(0.5, 1, 0.5, self.alpha)
    setTextBold(true)
    renderText(self.posX + 0.013, self.titleTextPosY, self.titleTextSize, self.title)
    setTextBold(false)
    setTextColor(1, 1, 1, self.alpha)
    setTextWrapWidth(0.33)
    renderText(self.posX + 0.015, self.textPosY, self.textSize, self.message)
    setTextWrapWidth(0)
    setTextColor(1, 1, 1, 1)
  end
end
