AdminGameScreen = {}
local AdminGameScreen_mt = Class(AdminGameScreen)
function AdminGameScreen:new()
  local instance = GuiElement:new(target, AdminGameScreen_mt)
  instance.capacityTable = {}
  for i = 2, 10 do
    table.insert(instance.capacityTable, tostring(i))
  end
  return instance
end
function AdminGameScreen:onOpen()
  self.capacity = g_currentMission.missionDynamicInfo.capacity
  self.serverNameElement:setText(g_currentMission.missionDynamicInfo.serverName)
  self.passwordElement:setText(g_currentMission.missionDynamicInfo.password)
  self.autoAcceptElement:setIsChecked(g_currentMission.missionDynamicInfo.autoAccept)
  self.autoSaveElement:setIsChecked(g_currentMission.missionDynamicInfo.autoSave)
  self.createFieldsElement:setIsChecked(g_currentMission.allowClientsCreateFields)
  self.sellVehiclesElement:setIsChecked(g_currentMission.allowClientsSellVehicles)
  self.ownMoneyElement:setIsChecked(g_currentMission.allowClientsOwnMoney)
  self.numPlayersElement:setTexts(self.capacityTable)
  self.numPlayersElement:setState(self.capacity - 1)
  InputBinding.setShowMouseCursor(true)
end
function AdminGameScreen:onClose()
  InputBinding.setShowMouseCursor(false)
end
function AdminGameScreen:onSaveClick()
  local serverName = Utils.trim(self.serverNameElement.text)
  local filteredServerName = filterText(serverName)
  if filteredServerName ~= serverName then
    self.serverNameElement:setText(filteredServerName)
  else
    if serverName ~= "" then
      g_currentMission.missionDynamicInfo.serverName = serverName
    end
    g_currentMission.missionDynamicInfo.capacity = self.capacity
    g_currentMission.missionDynamicInfo.password = self.passwordElement.text
    g_currentMission.missionDynamicInfo.autoAccept = self.autoAcceptElement.isChecked
    g_currentMission.allowClientsCreateFields = self.createFieldsElement.isChecked
    g_currentMission.allowClientsSellVehicles = self.sellVehiclesElement.isChecked
    g_currentMission:setAllowClientsOwnMoney(self.ownMoneyElement.isChecked)
    local autoSave = self.autoSaveElement.isChecked
    if autoSave ~= g_currentMission.missionDynamicInfo.autoSave then
      g_currentMission.autoSaveTime = g_currentMission.time + g_currentMission.autoSaveInterval
    end
    g_currentMission.missionDynamicInfo.autoSave = autoSave
    masterServerSetServerInfo(g_currentMission.missionDynamicInfo.serverName, g_currentMission.missionDynamicInfo.password ~= "", g_currentMission.missionDynamicInfo.capacity, table.getn(g_currentMission.users))
    g_gui:showGui("")
  end
end
function AdminGameScreen:onBackClick()
  g_gui:showGui("")
end
function AdminGameScreen:onUsersClick()
  g_gui:showGui("AdminUsersScreen")
end
function AdminGameScreen:onCreateServerName(element)
  self.serverNameElement = element
end
function AdminGameScreen:onCreatePassword(element)
  self.passwordElement = element
end
function AdminGameScreen:numPlayerOnCreate(element)
  self.numPlayersElement = element
end
function AdminGameScreen:numPlayerOnClick(state)
  self.capacity = state + 1
end
function AdminGameScreen:onCreateAutoSave(element)
  self.autoSaveElement = element
end
function AdminGameScreen:toggleAutoAcceptOnClickOnCreate(element)
  self.autoAcceptElement = element
end
function AdminGameScreen:onCreateCreateFields(element)
  self.createFieldsElement = element
end
function AdminGameScreen:onCreateSellVehicles(element)
  self.sellVehiclesElement = element
end
function AdminGameScreen:onCreateOwnMoney(element)
  self.ownMoneyElement = element
end
