MultiplayerScreen = {}
local MultiplayerScreen_mt = Class(MultiplayerScreen)
function MultiplayerScreen:new()
  local instance = GuiElement:new(target, MultiplayerScreen_mt)
  return instance
end
function MultiplayerScreen:onJoinGameClick()
  self:initJoinGameScreen()
  g_gui:showGui("ConnectToMasterServerScreen")
  g_connectToMasterServerScreen:connectToFront()
end
function MultiplayerScreen:initJoinGameScreen()
  g_connectionManager:startupWithWorkingPort(g_defaultServerPort)
  g_connectionFailedDialog:setNextScreenName("MultiplayerScreen")
  g_connectToMasterServerScreen:setNextScreenName("JoinGameScreen")
  g_connectToMasterServerScreen:setPrevScreenName("MultiplayerScreen")
  g_selectMasterServerScreen:setPrevScreenName("MultiplayerScreen")
end
function MultiplayerScreen:onCreateGameClick()
  g_careerScreen:setIsMultiplayer(true)
  g_gui:showGui("CareerScreen")
end
function MultiplayerScreen:onBackClick()
  g_gui:showGui("MainScreen")
end
