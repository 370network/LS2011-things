ModScreen = {}
local ModScreen_mt = Class(ModScreen)
function ModScreen:new()
  local self = GuiElement:new(target, ModScreen_mt)
  self.createModIconIndex = 1
  self.createModTextIndex = 1
  self.upButton = nil
  self.downButton = nil
  self.backButton = nil
  self.getModsButton = nil
  self.time = 0
  return self
end
function ModScreen:onCreate(element)
  self.list1:removeElement(self.listItem1Template)
end
function ModScreen:onOpen()
  self.list1:deleteListItems()
  for i = 1, table.getn(g_joinGameScreen.serverDetailsModTitles) do
    self.currentModTitle, self.currentModVersion, self.currentModAuthor = ModScreen.unpackModInfo(g_joinGameScreen.serverDetailsModTitles[i])
    self.currentModHash = g_joinGameScreen.serverDetailsModHashs[i]
    local newListItem = self.listItem1Template:clone(self.list1)
    newListItem:updateAbsolutePosition()
    self.currentModTitle = nil
    self.currentModVersion = nil
    self.currentModAuthor = nil
  end
  self.getModsButton:setVisible(not g_joinGameScreen.serverDatailsAllModsAvailable)
end
function ModScreen:onClose()
end
function ModScreen:onCreateList(element)
  self.list1 = element
end
function ModScreen:onCreateListItem(element)
  if self.listItem1Template == nil then
    self.listItem1Template = element
  end
end
function ModScreen:onCreateTitleText(element)
  if self.currentModTitle ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentModTitle, element.textSize, 0.63, false, "..")
    setTextBold(false)
    element:setText(text)
    if not ModsUtil.getIsModAvailable(self.currentModHash) then
      element:setTextColor(0.7, 0.7, 0.7, 0.8)
    end
  end
end
function ModScreen:onCreateVersionText(element)
  if self.currentModVersion ~= nil then
    element:setText(g_i18n:getText("ModVersion") .. ": " .. self.currentModVersion)
    if not ModsUtil.getIsModAvailable(self.currentModHash) then
      element:setTextColor(0.7, 0.7, 0.7, 0.8)
    end
  end
end
function ModScreen:onCreateAuthorText(element)
  if self.currentModAuthor ~= nil then
    setTextBold(element.textBold)
    local text = Utils.limitTextToWidth(self.currentModAuthor, element.textSize, 0.31, false, "..")
    setTextBold(false)
    element:setText(text)
    if not ModsUtil.getIsModAvailable(self.currentModHash) then
      element:setTextColor(0.7, 0.7, 0.7, 0.8)
    end
  end
end
function ModScreen:onCreateHashText(element)
  if self.currentModHash ~= nil then
    element:setText(g_i18n:getText("ModFileHash") .. ": " .. self.currentModHash)
    if not ModsUtil.getIsModAvailable(self.currentModHash) then
      element:setTextColor(0.7, 0.7, 0.7, 0.8)
    end
  end
end
function ModScreen:onCreateNotAvailableText(element)
  if self.currentModHash ~= nil and not ModsUtil.getIsModAvailable(self.currentModHash) then
    element:setText(g_i18n:getText("ModNotAvailable"))
  end
end
function ModScreen:onUpButtonCreate(element)
  self.upButton = element
end
function ModScreen:onDownButtonCreate(element)
  self.downButton = element
end
function ModScreen:onCreateBackButton(element)
  self.backButton = element
end
function ModScreen:onUpClick()
  self.list1:scrollList(-1)
end
function ModScreen:onDownClick()
  self.list1:scrollList(1)
end
function ModScreen:onBackClick()
  g_gui:showGui("ServerDetailDialog")
end
function ModScreen:onCreateGetMods(element)
  self.getModsButton = element
end
function ModScreen:onGetModsClick()
  local modListStr = ""
  for i = 1, table.getn(g_joinGameScreen.serverDetailsModTitles) do
    if not ModsUtil.getIsModAvailable(g_joinGameScreen.serverDetailsModHashs[i]) then
      if modListStr == "" then
        modListStr = g_joinGameScreen.serverDetailsModHashs[i]
      else
        modListStr = modListStr .. ";" .. g_joinGameScreen.serverDetailsModHashs[i]
      end
    end
  end
  if modListStr ~= "" then
    openWebFile("fs2011MetaModSearch.php", "search=" .. modListStr)
  end
end
function ModScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function ModScreen:focusOverrideDownButton(direction)
  local nextElementIsSet, nextElement = false
  if direction == FocusManager.RIGHT and not self.getModsButton:canReceiveFocus() then
    nextElementIsSet, nextElement = true, self.backButton
  end
  return nextElementIsSet, nextElement
end
function ModScreen:focusOverrideBackButton(direction)
  local nextElementIsSet, nextElement = false
  if direction == FocusManager.LEFT and not self.getModsButton:canReceiveFocus() then
    nextElementIsSet, nextElement = true, self.downButton
  end
  return nextElementIsSet, nextElement
end
function ModScreen.packModInfo(modTitle, version, author)
  modTitle = string.gsub(modTitle, ";", " ")
  version = string.gsub(version, ";", " ")
  author = string.gsub(author, ";", " ")
  return modTitle .. ";" .. version .. ";" .. author
end
function ModScreen.unpackModInfo(str)
  local parts = Utils.splitString(";", str)
  local modTitle = parts[1]
  local version = parts[2]
  local author = parts[3]
  if modTitle == nil or modTitle == "" then
    modTitle = "Unknown Title"
  end
  if version == nil or version == "" then
    version = "0.01"
  end
  if author == nil then
    author = ""
  end
  return modTitle, version, author
end
