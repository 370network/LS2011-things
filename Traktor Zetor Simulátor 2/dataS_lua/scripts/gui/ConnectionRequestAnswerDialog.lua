ConnectionRequestAnswerDialog = {}
local ConnectionRequestAnswerDialog_mt = Class(ConnectionRequestAnswerDialog)
function ConnectionRequestAnswerDialog:new()
  local instance = {}
  instance = setmetatable(instance, ConnectionRequestAnswerDialog_mt)
  return instance
end
function ConnectionRequestAnswerDialog:setAnswer(answer)
  if answer == ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD then
    self.answerTextElement:setText(g_i18n:getText("WrongPassword"))
  elseif answer == ConnectionRequestAnswerEvent.ANSWER_FULL then
    self.answerTextElement:setText(g_i18n:getText("GameFull"))
  else
    self.answerTextElement:setText(g_i18n:getText("ServerDenied"))
  end
end
function ConnectionRequestAnswerDialog:onOkClick()
  OnInGameMenuMenu()
  if masterServerConnectFront ~= nil then
    g_multiplayerScreen:initJoinGameScreen()
    g_gui:showGui("ConnectToMasterServerScreen")
    if g_masterServerConnection.lastBackServerIndex >= 0 then
      g_connectToMasterServerScreen:connectToBack(g_masterServerConnection.lastBackServerIndex)
    else
      g_connectToMasterServerScreen:connectToFront()
    end
  end
end
function ConnectionRequestAnswerDialog:onCreateAnswerText(element)
  self.answerTextElement = element
end
