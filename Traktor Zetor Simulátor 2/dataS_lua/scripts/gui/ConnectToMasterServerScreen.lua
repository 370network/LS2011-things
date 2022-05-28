ConnectToMasterServerScreen = {}
local ConnectToMasterServerScreen_mt = Class(ConnectToMasterServerScreen)
function ConnectToMasterServerScreen:new(loadFunction)
  local instance = {}
  setmetatable(instance, ConnectToMasterServerScreen_mt)
  return instance
end
function ConnectToMasterServerScreen.goBackCleanup()
  g_masterServerConnection:disconnectFromMasterServer()
  if g_client ~= nil then
    g_client:delete()
    g_client = nil
  end
  if g_server ~= nil then
    g_server:delete()
    g_server = nil
  else
    g_connectionManager:shutdownAll()
  end
end
function ConnectToMasterServerScreen:setNextScreenName(nextScreenName)
  self.nextScreenName = nextScreenName
end
function ConnectToMasterServerScreen:setPrevScreenName(prevScreenName)
  self.prevScreenName = prevScreenName
end
function ConnectToMasterServerScreen:onOpen()
  g_masterServerConnection:setCallbackTarget(self)
end
function ConnectToMasterServerScreen:onClose()
end
function ConnectToMasterServerScreen:onCancelClick()
  ConnectToMasterServerScreen.goBackCleanup()
  g_gui:showGui(self.prevScreenName)
end
function ConnectToMasterServerScreen:onCreateStatus(element)
  element:setText(g_i18n:getText("Connecting_To_Master_Server"))
end
function ConnectToMasterServerScreen:connectToFront()
  g_masterServerConnection:connectToMasterServerFront()
end
function ConnectToMasterServerScreen:connectToBack(index)
  g_masterServerConnection:disconnectFromMasterServer()
  g_masterServerConnection:connectToMasterServer(index)
end
function ConnectToMasterServerScreen:onMasterServerListStart(numMasterServers)
  self.numMasterServers = numMasterServers
  if self.numMasterServers > 1 then
    g_selectMasterServerScreen:setNextScreenName(self.nextScreenName)
    g_gui:showGui("SelectMasterServerScreen")
  end
end
function ConnectToMasterServerScreen:onMasterServerList(name)
end
function ConnectToMasterServerScreen:onMasterServerListEnd()
  if self.numMasterServers == 1 then
    self:connectToBack(0)
  end
end
function ConnectToMasterServerScreen:onMasterServerConnectionFailed(reason)
  ConnectToMasterServerScreen.goBackCleanup()
  g_connectionFailedDialog:showMasterServerConnectionFailedReason(reason, self.prevScreenName)
end
function ConnectToMasterServerScreen:onMasterServerConnectionReady()
  local gui = g_gui:showGui(self.nextScreenName)
  gui.target:onMasterServerConnectionReady()
end
