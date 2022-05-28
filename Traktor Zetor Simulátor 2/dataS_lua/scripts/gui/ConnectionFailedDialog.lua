ConnectionFailedDialog = {}
local ConnectionFailedDialog_mt = Class(ConnectionFailedDialog)
local localRemoveActivation = removeActivation
removeActivation = nil
function ConnectionFailedDialog:new(mt)
  local instance = {}
  if mt == nil then
    mt = ConnectionFailedDialog_mt
  end
  instance = setmetatable(instance, mt)
  return instance
end
function ConnectionFailedDialog:onOpen(element)
  InputBinding.setShowMouseCursor(true)
end
function ConnectionFailedDialog:onClose(element)
end
function ConnectionFailedDialog:onCreateText(element)
  self.textElement = element
end
function ConnectionFailedDialog:setFailedText(text)
  self.textElement:setText(text)
end
function ConnectionFailedDialog:setNextScreenName(screenName)
  self.screenName = screenName
end
function ConnectionFailedDialog:onOkClick()
  g_gui:showGui(self.screenName)
end
function ConnectionFailedDialog:showMasterServerConnectionFailedReason(reason, nextScreenName)
  print("Error: Failed to connect")
  if MasterServerConnection.FAILED_NONE == reason then
    print("Error: reason is none, this should never happen.")
  elseif MasterServerConnection.FAILED_WRONG_VERSION == reason then
    g_wrongGameVersionDialog:setNextScreenName(nextScreenName)
    g_wrongGameVersionDialog:setFailedText(g_i18n:getText("Wrong_Game_Version"))
    g_gui:showGui("WrongGameVersionDialog")
  elseif MasterServerConnection.FAILED_PERMANENT_BAN == reason then
    localRemoveActivation()
    g_invalidKeyDialog:setNextScreenName(nextScreenName)
    g_invalidKeyDialog:setFailedText(g_i18n:getText("permanent_ban"))
    g_gui:showGui("InvalidKeyDialog")
  else
    self:setNextScreenName(nextScreenName)
    if MasterServerConnection.FAILED_UNKNOWN == reason then
      self:setFailedText(g_i18n:getText("Connection_failed"))
      g_gui:showGui("ConnectionFailedDialog")
    elseif MasterServerConnection.FAILED_MAINTENANCE == reason then
      self:setFailedText(g_i18n:getText("Server_maintenance"))
      g_gui:showGui("ConnectionFailedDialog")
    elseif MasterServerConnection.FAILED_TEMPORARY_BAN == reason then
      localRemoveActivation()
      self:setFailedText(g_i18n:getText("temporary_ban"))
      g_gui:showGui("ConnectionFailedDialog")
    elseif MasterServerConnection.FAILED_CONNECTION_LOST == reason then
      self:setFailedText(g_i18n:getText("Connection_failed"))
      g_gui:showGui("ConnectionFailedDialog")
    end
  end
end
