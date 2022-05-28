DifficultyScreen = {}
local DifficultyScreen_mt = Class(DifficultyScreen)
function DifficultyScreen:new()
  local instance = GuiElement:new(target, DifficultyScreen_mt)
  return instance
end
function DifficultyScreen:onEasyClick()
  self.returnScreen:setSelectedGameDifficulty(1)
end
function DifficultyScreen:onNormalClick()
  self.returnScreen:setSelectedGameDifficulty(2)
end
function DifficultyScreen:onHardClick()
  self.returnScreen:setSelectedGameDifficulty(3)
end
function DifficultyScreen:onBackClick()
  g_gui:showGui(self.returnScreenName)
end
function DifficultyScreen:setReturn(screen, screenName)
  self.returnScreen = screen
  self.returnScreenName = screenName
end
function DifficultyScreen:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
