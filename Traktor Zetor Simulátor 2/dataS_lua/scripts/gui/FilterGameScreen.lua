FilterGameScreen = {}
local FilterGameScreen_mt = Class(FilterGameScreen)
function FilterGameScreen:new()
  local self = GuiElement:new(target, FilterGameScreen_mt)
  self.capacityTable = {}
  self.capacityNumbers = {}
  self.mapSelectionElement = nil
  self.selectedMap = ""
  self.hasNoPassword = false
  self.isNotEmpty = true
  self.noMods = false
  self.onlyWithAllModsAvailable = false
  self.selectedLanguage = g_settingsLanguage
  self.serverName = ""
  for i = 2, 10 do
    table.insert(self.capacityTable, tostring(i))
    table.insert(self.capacityNumbers, i)
  end
  self.capacityState = table.getn(self.capacityNumbers)
  self.capacity = self.capacityNumbers[self.capacityState]
  self.selectedMapState = 1
  return self
end
function FilterGameScreen:onOpen()
  if self.selectedLanguage < 0 then
    self.languageSelectionElement:setState(1)
  else
    self.languageSelectionElement:setState(self.selectedLanguage + 2)
  end
  self.capacityElement:setState(self.capacityState)
  self.mapSelectionElement:setState(self.selectedMapState)
  self.hasNoPasswordElement:setIsChecked(self.hasNoPassword)
  self.isNotEmptyElement:setIsChecked(self.isNotEmpty)
  self.onlyWithAllModsAvailableElement:setIsChecked(self.onlyWithAllModsAvailable)
  self.serverNameElement:setText(self.serverName)
end
function FilterGameScreen:onClose()
end
function FilterGameScreen:onCreateServerName(element)
  self.serverNameElement = element
  element:setText(self.serverName)
end
function FilterGameScreen:toggleHasNoPasswordOnCreate(element)
  element:setIsChecked(self.hasNoPassword)
  self.hasNoPasswordElement = element
end
function FilterGameScreen:numPlayerOnCreate(element)
  element:setTexts(self.capacityTable)
  element:setState(self.capacityState)
  self.capacity = self.capacityNumbers[element.state]
  self.capacityElement = element
end
function FilterGameScreen:toggleIsNotEmptyOnCreate(element)
  element:setIsChecked(self.isNotEmpty)
  self.isNotEmptyElement = element
end
function FilterGameScreen:mapSelectionOnCreate(element)
  self.mapSelectionElement = element
  self.mapTable = {}
  self.mapIds = {}
  setTextBold(element.textBold)
  table.insert(self.mapTable, g_i18n:getText("AnyMap"))
  table.insert(self.mapIds, "")
  for i = 1, table.getn(MapsUtil.mapList) do
    local title = MapsUtil.mapList[i].title
    title = Utils.limitTextToWidth(title, 0.025, 0.245, false, "..")
    table.insert(self.mapTable, title)
    table.insert(self.mapIds, MapsUtil.mapList[i].id)
  end
  setTextBold(false)
  self.mapSelectionElement:setTexts(self.mapTable)
  self.mapSelectionElement:setState(self.selectedMapState)
  self.selectedMap = self.mapIds[self.mapSelectionElement.state]
end
function FilterGameScreen:languageSelectionOnCreate(element)
  local languageTable = {}
  local numL = getNumOfLanguages()
  table.insert(languageTable, g_i18n:getText("AllLanguages"))
  for i = 0, numL - 1 do
    table.insert(languageTable, getLanguageName(i))
  end
  element:setTexts(languageTable)
  element:setState(g_settingsLanguage + 2)
  self.languageSelectionElement = element
end
function FilterGameScreen:toggleModsAvailableOnCreate(element)
  element:setIsChecked(self.onlyWithAllModsAvailable)
  self.onlyWithAllModsAvailableElement = element
end
function FilterGameScreen:onSearchClick()
  self.capacityState = self.capacityElement.state
  self.capacity = self.capacityNumbers[self.capacityElement.state]
  self.selectedMapState = self.mapSelectionElement.state
  self.selectedMap = self.mapIds[self.mapSelectionElement.state]
  self.hasNoPassword = self.hasNoPasswordElement.isChecked
  self.isNotEmpty = self.isNotEmptyElement.isChecked
  if self.languageSelectionElement.state == 1 then
    self.selectedLanguage = -1
  else
    self.selectedLanguage = Utils.clamp(self.languageSelectionElement.state - 2, 0, getNumOfLanguages() - 1)
  end
  self.onlyWithAllModsAvailable = self.onlyWithAllModsAvailableElement.isChecked
  self.serverName = self.serverNameElement.text
  g_gui:showGui("JoinGameScreen")
end
function FilterGameScreen:onBackClick()
  g_gui:showGui("JoinGameScreen")
end
