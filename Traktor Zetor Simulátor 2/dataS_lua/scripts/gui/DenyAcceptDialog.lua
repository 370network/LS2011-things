DenyAcceptDialog = {}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog)
function DenyAcceptDialog:new()
  local instance = {}
  instance = setmetatable(instance, DenyAcceptDialog_mt)
  return instance
end
function DenyAcceptDialog:onOpen()
  if g_currentMission.inGameMessage ~= nil then
    g_currentMission.inGameMessage.visible = false
  end
  InputBinding.setShowMouseCursor(true)
end
function DenyAcceptDialog:onClose()
  InputBinding.setShowMouseCursor(false)
end
function DenyAcceptDialog:setText(text)
  if self.textElement ~= nil then
    self.textElement:setText(text)
  end
end
function DenyAcceptDialog:setIp(ip)
  if self.domainAndIPTextElement ~= nil then
    local domain = netGetHostByAddr(ip)
    if domain ~= ip then
      self.domainAndIPTextElement:setText(domain .. " (" .. ip .. ")")
    else
      self.domainAndIPTextElement:setText(ip)
    end
  end
end
function DenyAcceptDialog:onCreateText(element)
  self.textElement = element
end
function DenyAcceptDialog:domainAndIPOnCreateText(element)
  self.domainAndIPTextElement = element
end
function DenyAcceptDialog:onAcceptClick()
  if self.onAcceptCallback ~= nil then
    if self.target ~= nil then
      self.onAcceptCallback(self.target, self.connection, false, false)
    else
      self.onAcceptCallback(self.connection, false, false)
    end
  end
  g_gui:showGui("")
end
function DenyAcceptDialog:onDenyClick()
  if self.onAcceptCallback ~= nil then
    if self.target ~= nil then
      self.onAcceptCallback(self.target, self.connection, true, false)
    else
      self.onAcceptCallback(self.connection, true, false)
    end
  end
  g_gui:showGui("")
end
function DenyAcceptDialog:onDenyAlwaysClick()
  if self.onAcceptCallback ~= nil then
    if self.target ~= nil then
      self.onAcceptCallback(self.target, self.connection, true, true)
    else
      self.onAcceptCallback(self.connection, true, true)
    end
  end
  g_gui:showGui("")
end
function DenyAcceptDialog:setCallbacks(onAcceptCallback, target)
  self.onAcceptCallback = onAcceptCallback
  self.target = target
end
function DenyAcceptDialog:setConnection(connection, nickname)
  self.connection = connection
  self.nickname = nickname
  self:setText(nickname)
  local ip = streamGetIpAndPort(connection.streamId)
  self:setIp(ip)
end
function DenyAcceptDialog:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU, true) or InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    InputBinding.hasEvent(InputBinding.MENU, true)
    InputBinding.hasEvent(InputBinding.MENU_CANCEL, true)
    self:onNoClick()
  end
end
