ChatDialog = {}
local ChatDialog_mt = Class(ChatDialog)
function ChatDialog:new()
  local instance = {}
  instance = setmetatable(instance, ChatDialog_mt)
  instance.ignoreOnClose = false
  return instance
end
function ChatDialog:onCreateTextInput(element)
  self.textElement = element
end
function ChatDialog:onOpen(element)
  if not self.ignoreOnClose then
    if g_currentMission.inGameMessage ~= nil then
      g_currentMission.inGameMessage.visible = false
    end
    InputBinding.setShowMouseCursor(true)
    self.textElement:setForcePressed(true)
  end
  g_currentMission:setLastChatMessageTime()
end
function ChatDialog:onClose(element)
  if not self.ignoreOnClose then
    if g_currentMission ~= nil then
      InputBinding.setShowMouseCursor(false)
    end
    self.textElement:setForcePressed(false)
  end
end
function ChatDialog:onSendClick()
  if self.textElement.text ~= "" then
    if g_server ~= nil then
      g_server:broadcastEvent(ChatEvent:new(self.textElement.text, g_settingsNickname))
    else
      g_client:getServerConnection():sendEvent(ChatEvent:new(self.textElement.text, g_settingsNickname))
    end
    g_currentMission:addChatMessage(g_settingsNickname, self.textElement.text)
    self.textElement:setText("")
  end
  g_gui:showGui("")
end
function ChatDialog:update(dt)
  g_currentMission:setLastChatMessageTime()
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    InputBinding.hasEvent(InputBinding.MENU, true)
    self.textElement:setText("")
    self:onSendClick()
  end
end
function ChatDialog:onEnterPressed()
  self:onSendClick()
end
