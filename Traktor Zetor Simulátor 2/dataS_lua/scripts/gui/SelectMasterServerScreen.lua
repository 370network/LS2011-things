SelectMasterServerScreen = {}
local SelectMasterServerScreen_mt = Class(SelectMasterServerScreen)
function SelectMasterServerScreen:new()
  local instance = GuiElement:new(target, SelectMasterServerScreen_mt)
  instance.masterServers = {}
  instance.serverElements = {}
  return instance
end
function SelectMasterServerScreen:setNextScreenName(nextScreenName)
  self.nextScreenName = nextScreenName
end
function SelectMasterServerScreen:setPrevScreenName(prevScreenName)
  self.prevScreenName = prevScreenName
end
function SelectMasterServerScreen:onOpen()
  g_masterServerConnection:setCallbackTarget(self)
  self.masterServers = {}
end
function SelectMasterServerScreen:onClose()
end
function SelectMasterServerScreen:onCreateList(listElement)
  self.list = listElement
end
function SelectMasterServerScreen:onMasterServerList(name)
  table.insert(self.masterServers, {
    id = table.getn(self.masterServers),
    name = name
  })
end
function SelectMasterServerScreen:onMasterServerListEnd()
  self:updateServersGraphics()
  self.list:setSelectedRow(1)
end
function SelectMasterServerScreen:onMasterServerConnectionReady()
  local gui = g_gui:showGui(self.nextScreenName)
  gui.target:onMasterServerConnectionReady()
end
function SelectMasterServerScreen:onMasterServerConnectionFailed(reason)
  ConnectToMasterServerScreen.goBackCleanup()
  g_connectionFailedDialog:showMasterServerConnectionFailedReason(reason, self.prevScreenName)
end
function SelectMasterServerScreen:onDoubleClick()
  self:onStartClick()
end
function SelectMasterServerScreen:onBackClick()
  ConnectToMasterServerScreen.goBackCleanup()
  g_gui:showGui(self.prevScreenName)
end
function SelectMasterServerScreen:onStartClick()
  if self.listTemplateParent.selectedRow > 0 then
    g_gui:showGui("ConnectToMasterServerScreen")
    g_connectToMasterServerScreen:connectToBack(self.listTemplateParent.selectedRow - 1)
  end
end
function SelectMasterServerScreen:setText(text)
  if self.textElement ~= nil then
    self.textElement:setText(text)
  end
end
function SelectMasterServerScreen:onCreateText(element)
  self.textElement = element
end
function SelectMasterServerScreen:onCreateListTemplate(element)
  if self.listTemplate == nil then
    self.listTemplate = element
    self.listTemplateParent = self.listTemplate.parent
    self.listTemplate.parent:removeElement(self.listTemplate)
  end
end
function SelectMasterServerScreen:onCreateServer(element)
  if self.currentServer ~= nil then
    self.serverElements[self.currentServer.id].name = element
  end
end
function SelectMasterServerScreen:updateServersGraphics()
  while table.getn(self.listTemplateParent.listItems) > 0 do
    local element = self.listTemplateParent.listItems[1]
    self.listTemplateParent:removeElement(element)
    element:delete()
  end
  for i = 1, table.getn(self.masterServers) do
    self.currentServer = self.masterServers[i]
    if self.listTemplate ~= nil then
      self.serverElements[self.currentServer.id] = {}
      local new = self.listTemplate:clone(self.listTemplateParent)
      new:updateAbsolutePosition()
      local elements = self.serverElements[self.currentServer.id]
      if elements.name ~= nil then
        elements.name:setText(self.currentServer.name)
      end
    end
    self.currentServer = nil
  end
end
