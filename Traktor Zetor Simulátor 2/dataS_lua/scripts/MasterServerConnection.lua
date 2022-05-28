MasterServerConnection = {}
MasterServerConnection.FAILED_NONE = 0
MasterServerConnection.FAILED_UNKNOWN = 1
MasterServerConnection.FAILED_WRONG_VERSION = 2
MasterServerConnection.FAILED_MAINTENANCE = 3
MasterServerConnection.FAILED_TEMPORARY_BAN = 4
MasterServerConnection.FAILED_PERMANENT_BAN = 5
MasterServerConnection.FAILED_CONNECTION_LOST = 6
local MasterServerConnection_mt = Class(MasterServerConnection)
function MasterServerConnection:new()
  local self = {}
  setmetatable(self, MasterServerConnection_mt)
  self.lastBackServerIndex = -1
  masterServerInit(g_gameVersion, g_settingsLanguage)
  masterServerSetCallbacks("onMasterServerList", "onMasterServerListStart", "onMasterServerListEnd", "onConnectionReady", "onConnectionFailed", "onServerInfo", "onServerInfoStart", "onServerInfoEnd", "onServerInfoDetails", "onServerInfoDetailsFailed", self)
  return self
end
function MasterServerConnection:setCallbackTarget(target)
  self.masterServerCallbackTarget = target
end
function MasterServerConnection:onMasterServerList(name)
  self.masterServerCallbackTarget:onMasterServerList(name)
end
function MasterServerConnection:onMasterServerListStart(numMasterServers)
  self.masterServerCallbackTarget:onMasterServerListStart(numMasterServers)
end
function MasterServerConnection:onMasterServerListEnd()
  self.masterServerCallbackTarget:onMasterServerListEnd()
end
function MasterServerConnection:onConnectionReady()
  self.masterServerCallbackTarget:onMasterServerConnectionReady()
end
function MasterServerConnection:onConnectionFailed(reason)
  self.masterServerCallbackTarget:onMasterServerConnectionFailed(reason)
end
function MasterServerConnection:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer)
  self.masterServerCallbackTarget:onServerInfo(id, name, language, capacity, numPlayers, mapName, hasPassword, allModsAvailable, isLanServer)
end
function MasterServerConnection:onServerInfoStart(numServers, totalNumServers)
  self.masterServerCallbackTarget:onServerInfoStart(numServers, totalNumServers)
end
function MasterServerConnection:onServerInfoEnd()
  self.masterServerCallbackTarget:onServerInfoEnd()
end
function MasterServerConnection:onServerInfoDetails(id, ip, port, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashs)
  self.masterServerCallbackTarget:onServerInfoDetails(id, ip, port, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashs)
end
function MasterServerConnection:onServerInfoDetailsFailed()
  self.masterServerCallbackTarget:onServerInfoDetailsFailed()
end
function MasterServerConnection:connectToMasterServerFront()
  self.lastBackServerIndex = -1
  masterServerConnectFront()
end
function MasterServerConnection:connectToMasterServer(index)
  self.lastBackServerIndex = index
  masterServerConnectBack(index)
end
function MasterServerConnection:disconnectFromMasterServer()
  masterServerDisconnect()
end
