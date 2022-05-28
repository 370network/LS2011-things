MainScreen = {}
local MainScreen_mt = Class(MainScreen)
function MainScreen:new()
  local instance = GuiElement:new(target, MainScreen_mt)
  instance.firstTimeOpened = true
  return instance
end
function MainScreen:onCreate()
  if g_isDemo then
    local missionButton = FocusManager:getElementById("2")
    local optionsButton = FocusManager:getElementById("5")
    local creditsButton = FocusManager:getElementById("6")
    local quitButton = FocusManager:getElementById("7")
    missionButton.focusChangeData[FocusManager.TOP] = nil
    missionButton.focusChangeData[FocusManager.BOTTOM] = optionsButton.focusId
    optionsButton.focusChangeData[FocusManager.TOP] = missionButton.focusId
    optionsButton.focusChangeData[FocusManager.BOTTOM] = creditsButton.focusId
    creditsButton.focusChangeData[FocusManager.TOP] = optionsButton.focusId
    creditsButton.focusChangeData[FocusManager.BOTTOM] = quitButton.focusId
    quitButton.focusChangeData[FocusManager.TOP] = creditsButton.focusId
    quitButton.focusChangeData[FocusManager.BOTTOM] = nil
  end
end
function MainScreen:onOpen()
  if self.firstTimeOpened then
    self.firstTimeOpened = false
    playStreamedSample(g_menuMusic, 0)
  end
end
function MainScreen:onClose()
end
function MainScreen:onMultiplayerClick()
  if masterServerConnectFront == nil then
    RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
    restartApplication()
  else
    g_gui:showGui("MultiplayerScreen")
  end
end
function MainScreen:onCareerCreate(element)
  if g_isDemo then
    element.disabled = true
  end
end
function MainScreen:onMultiplayerCreate(element)
  if g_isDemo then
    element.disabled = true
  end
end
function MainScreen:onMissionsCreate(element)
end
function MainScreen:onAchievementsCreate(element)
  if g_isDemo then
    element.disabled = true
  end
end
function MainScreen:onSettingsCreate(element)
end
function MainScreen:onCreditsCreate(element)
end
function MainScreen:onQuitCreate(element)
end
function MainScreen:onCreateVersion(element)
  element:setText(g_gameVersionDisplay)
end
function MainScreen:onCareerClick()
  g_careerScreen:setIsMultiplayer(false)
  g_gui:showGui("CareerScreen")
end
function MainScreen:onMissionsClick()
  g_gui:showGui("MissionScreen")
end
function MainScreen:onAchievementsClick()
  g_gui:showGui("AchievementsScreen")
end
function MainScreen:onSettingsClick()
  g_gui:showGui("SettingsScreen")
end
function MainScreen:onCreditsClick()
  g_gui:showGui("CreditsScreen")
end
function MainScreen:onQuitClick()
  if g_isDemo then
    g_gui:showGui("DemoEndScreen")
  else
    doExit()
  end
end
