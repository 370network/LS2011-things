DemoEndScreen = {}
local DemoEndScreen_mt = Class(DemoEndScreen)
function DemoEndScreen:new()
  local instance = {}
  setmetatable(instance, DemoEndScreen_mt)
  instance.items = {}
  instance.countdown = 3000
  instance.quitButton = nil
  return instance
end
function DemoEndScreen:onCreateBackground(element)
  if g_isGamesloadDemo then
    element:setImageFilename("dataS2/menu/demo_end_screen" .. g_languageSuffix .. ".png")
  elseif g_isTriSynergyDemo then
    element:setImageFilename("dataS2/menu/demo_end_screen_trisynergy_en.png")
  else
    element:setImageFilename("dataS2/menu/demo_end_screen02" .. g_languageSuffix .. ".png")
  end
end
function DemoEndScreen:onCreateGetGame(element)
  element.visible = true
end
function DemoEndScreen:onCreateQuit(element)
  self.quitButton = element
  self.quitButton.disabled = true
end
function DemoEndScreen:onClickQuit()
  doExit()
end
function DemoEndScreen:onGetGameClick()
  if g_isGamesloadDemo then
    openWebFile("gamesloadForward.php", "")
    doExit()
  elseif g_isTriSynergyDemo then
    openWebFile("forward/trisynergyFS2011.php", "")
    doExit()
  else
    openWebFile("fs2011Purchase.php", "")
    doExit()
  end
end
function DemoEndScreen:mouseEvent(posX, posY, isDown, isUp, button)
end
function DemoEndScreen:keyEvent(unicode, sym, modifier, isDown)
end
function DemoEndScreen:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown < 0 then
    self.quitButton.disabled = false
  end
end
function DemoEndScreen:draw()
end
