AchievementMessage = {}
local AchievementMessage_mt = Class(AchievementMessage)
function AchievementMessage:new()
  local instance = {}
  setmetatable(instance, AchievementMessage_mt)
  instance.items = {}
  instance.message = ""
  instance.width = 0.365714
  instance.height = 0.1219
  instance.posX = 0.5 - instance.width / 2
  instance.posY = 0.319048
  instance.messageTextSize = 0.025
  instance.messageTextSpacingY = instance.messageTextSize + 0.005
  instance.messageTextPosY = instance.posY + 0.064
  instance.messageTextPosX = instance.posX + 0.075
  instance.fadeTime = 1000
  instance.visibleTime = 2000
  instance.visible = false
  instance.time = 0
  instance.showTrophy = false
  instance.alpha = 0
  instance:addItem(Overlay:new("backgroundOverlay", "dataS2/menu/achievementMessage_background.png", instance.posX, instance.posY, instance.width, instance.height))
  instance.achievementSound = createSample("achievementSound")
  loadSample(instance.achievementSound, "data/maps/sounds/achievementSound.wav", false)
  return instance
end
function AchievementMessage:delete()
  for i = 1, table.getn(self.items) do
    self.items[i]:delete()
  end
  if self.achievementSound ~= nil then
    delete(self.achievementSound)
  end
end
function AchievementMessage:addItem(item)
  table.insert(self.items, item)
end
function AchievementMessage:mouseEvent(posX, posY, isDown, isUp, button)
  if self.visible and isDown and button == 1 and self.time <= self.fadeTime + self.visibleTime then
    self:hideMessage()
  end
end
function AchievementMessage:update(dt)
  if self.visible and g_gui.currentGui == nil then
    if InputBinding.hasEvent(InputBinding.SKIP_MESSAGE_BOX) and self.time <= self.fadeTime + self.visibleTime then
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
  end
end
function AchievementMessage:showMessage(achievement, duration)
  self.message = achievement.name
  self.visibleTime = duration
  self.time = 0
  self.alpha = 0
  self.visible = true
  playSample(self.achievementSound, 1, 1, 0)
end
function AchievementMessage:hideMessage()
  self.time = self.fadeTime + self.visibleTime
end
function AchievementMessage:render()
  if self.visible and g_gui.currentGui == nil then
    for i = 1, table.getn(self.items) do
      self.items[i]:setColor(1, 1, 1, self.alpha)
      self.items[i]:render()
    end
    setTextColor(1, 0.95, 0.25, self.alpha)
    setTextBold(true)
    renderText(self.messageTextPosX, self.messageTextPosY, self.messageTextSize, g_i18n:getText("achievementUnlocked"))
    renderText(self.messageTextPosX, self.messageTextPosY - self.messageTextSpacingY, self.messageTextSize, self.message)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
  end
end
