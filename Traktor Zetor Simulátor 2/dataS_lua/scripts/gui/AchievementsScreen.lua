AchievementsScreen = {}
local AchievementsScreen_mt = Class(AchievementsScreen)
function AchievementsScreen:new()
  local instance = {}
  setmetatable(instance, AchievementsScreen_mt)
  instance.selectedIndex = 0
  instance.achievementElements = {}
  instance.list = {}
  return instance
end
function AchievementsScreen:onCreateList(list)
  self.list = list
end
function AchievementsScreen:onBackClick()
  g_gui:showGui("MainScreen")
end
function AchievementsScreen:onOpen()
  self.statsText:setText(string.format(g_i18n:getText("achievementStats"), g_achievementManager.numberOfUnlockedAchievements, g_achievementManager.numberOfAchievements))
  self:getAchievements()
end
function AchievementsScreen:onListSelectionChanged(rowIndex)
  self.selectedIndex = rowIndex
end
function AchievementsScreen:scrollListUp()
  self.list:scrollList(-1)
end
function AchievementsScreen:scrollListDown()
  self.list:scrollList(1)
end
function AchievementsScreen:onAchievementsScreenCreated(element)
  self:getAchievements()
end
function AchievementsScreen:onCreateListTemplate(element)
  if self.listTemplate == nil then
    self.listTemplate = element
  end
end
function AchievementsScreen:onCreateAchievementBitmap(element)
  if self.currentAchievement ~= nil then
    if self.currentAchievement.unlocked then
      element:setImageFilename(self.currentAchievement.imageFilename)
    else
      element:setImageFilename("dataS2/menu/achievements/achievement_blank.png")
      element.imageColor = {
        1,
        1,
        1,
        0.25
      }
    end
  end
end
function AchievementsScreen:onCreateStats(element)
  self.statsText = element
end
function AchievementsScreen:getAchievements()
  self.list:deleteListItems()
  local i = 1
  while true do
    do
      local achievement = g_achievementManager.achievementList[tostring(i)]
      if achievement ~= nil then
        if self.listTemplate ~= nil then
          self.achievementElements[achievement.id] = {}
          self.currentAchievement = achievement
          local new = self.listTemplate:clone(self.list)
          new:updateAbsolutePosition()
          self.currentAchievement = nil
          self:updateAchievementInfo(achievement)
        end
      else
        break
      end
      i = i + 1
    end
  end
  self.startIndex = 1
  self.selectedIndex = 1
end
function AchievementsScreen:updateAchievementInfo(achievement)
  local elements = self.achievementElements[achievement.id]
  if elements.title ~= nil then
    elements.title:setText(achievement.name)
  end
  if elements.desc ~= nil then
    elements.desc:setText(achievement.description)
  end
end
function AchievementsScreen:onCreateAchievementTitle(element)
  if self.currentAchievement ~= nil then
    self.achievementElements[self.currentAchievement.id].title = element
  end
end
function AchievementsScreen:onCreateAchievementDesc(element)
  if self.currentAchievement ~= nil then
    self.achievementElements[self.currentAchievement.id].desc = element
  end
end
function AchievementsScreen:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
