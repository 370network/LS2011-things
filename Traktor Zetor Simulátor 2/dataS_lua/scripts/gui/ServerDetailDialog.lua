ServerDetailDialog = {}
local ServerDetailDialog_mt = Class(ServerDetailDialog)
function ServerDetailDialog:new()
  local instance = {}
  instance = setmetatable(instance, ServerDetailDialog_mt)
  return instance
end
function ServerDetailDialog:onOpen()
  self.serverNameElement:setText(g_joinGameScreen.serverDetailsName)
  self.mapElement:setText(g_joinGameScreen.serverDetailsMapName)
  self.capacityElement:setText(tostring(g_joinGameScreen.serverDetailsCapacity))
  self.numPlayersElement:setText(tostring(g_joinGameScreen.serverDetailsNumPlayers))
  self.languageElement:setText(getLanguageName(g_joinGameScreen.serverDetailsLanguage))
  passwordStr = g_i18n:getText("Button_No")
  if g_joinGameScreen.serverDetailsHasPassword then
    passwordStr = g_i18n:getText("Button_Yes")
  end
  self.passwordElement:setText(passwordStr)
  self.startElement:setDisabled(not g_joinGameScreen.serverDatailsAllModsAvailable)
  self.notAllModsAvailableElement:setVisible(not g_joinGameScreen.serverDatailsAllModsAvailable)
end
function ServerDetailDialog:onCreateNotAllModsAvailable(element)
  self.notAllModsAvailableElement = element
end
function ServerDetailDialog:onCreateServerName(element)
  self.serverNameElement = element
end
function ServerDetailDialog:onCreateLanguage(element)
  self.languageElement = element
end
function ServerDetailDialog:onCreateCapacity(element)
  self.capacityElement = element
end
function ServerDetailDialog:onCreateNumPlayers(element)
  self.numPlayersElement = element
end
function ServerDetailDialog:onCreateMap(element)
  self.mapElement = element
end
function ServerDetailDialog:onCreatePassword(element)
  self.passwordElement = element
end
function ServerDetailDialog:onCreateStart(element)
  self.startElement = element
end
function ServerDetailDialog:onStartClick()
  if g_joinGameScreen.serverDatailsAllModsAvailable then
    if not g_joinGameScreen.serverDetailsHasPassword then
      g_joinGameScreen:startGame("", g_joinGameScreen.serverDetailsId)
    else
      g_passwordDialog:setCallbacks(self.onPasswordEntered, self)
      g_gui:showGui("PasswordDialog")
    end
  end
end
function ServerDetailDialog:onPasswordEntered(password)
  g_joinGameScreen:startGame(password, g_joinGameScreen.serverDetailsId)
end
function ServerDetailDialog:onModsClick()
  g_gui:showGui("ModScreen")
end
function ServerDetailDialog:onBackClick()
  g_gui:showGui("JoinGameScreen")
end
