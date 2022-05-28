function initGuiLibrary(baseDir)
  source(baseDir .. "/GuiProfile.lua")
  source(baseDir .. "/elements/GuiElement.lua")
  source(baseDir .. "/elements/ButtonElement.lua")
  source(baseDir .. "/elements/ToggleButtonElement.lua")
  source(baseDir .. "/elements/VideoElement.lua")
  source(baseDir .. "/elements/SliderElement.lua")
  source(baseDir .. "/elements/TextElement.lua")
  source(baseDir .. "/elements/TextInputElement.lua")
  source(baseDir .. "/elements/BitmapElement.lua")
  source(baseDir .. "/elements/ListElement.lua")
  source(baseDir .. "/elements/GameListItemElement.lua")
  source(baseDir .. "/elements/ControlsListItemElement.lua")
  source(baseDir .. "/elements/MultiTextOptionElement.lua")
  source(baseDir .. "/elements/ListItemElement.lua")
end
Gui = {}
local Gui_mt = Class(Gui)
function Gui:new(languageSuffix)
  local instance = setmetatable({}, Gui_mt)
  instance.dialogs = {}
  instance.profiles = {}
  instance.languageSuffix = languageSuffix
  instance.guis = {}
  instance.currentGuiName = ""
  return instance
end
function Gui:loadProfiles(xmlFilename)
  local xmlFile = loadXMLFile("Temp", xmlFilename)
  local i = 0
  while true do
    local profile = GuiProfile:new()
    if not profile:loadFromXML(xmlFile, "GUIProfiles.Profile(" .. i .. ")") then
      break
    end
    self.profiles[profile.name] = profile
    i = i + 1
  end
  delete(xmlFile)
end
function Gui:loadGui(xmlFilename, name, target)
  local xmlFile = loadXMLFile("Temp", xmlFilename)
  FocusManager:setGui(name)
  local className = getXMLString(xmlFile, "GUI#className")
  local gui = GuiElement:new(target)
  gui:loadFromXML(xmlFile, "GUI")
  self:loadGuiRec(xmlFile, "GUI", gui, target)
  gui:updateAbsolutePosition()
  if gui.onCreate ~= nil then
    if target ~= nil then
      gui.onCreate(target, gui)
    else
      gui.onCreate()
    end
  end
  delete(xmlFile)
  self.guis[name] = gui
  return gui
end
function Gui:loadGuiRec(xmlFile, key, gui, target)
  local i = 0
  while true do
    local k = key .. ".GuiElement(" .. i .. ")"
    local t = getXMLString(xmlFile, k .. "#type")
    if t == nil then
      break
    end
    local newGui
    if t == "button" then
      newGui = ButtonElement:new(target)
    elseif t == "toggleButton" then
      newGui = ToggleButtonElement:new(target)
    elseif t == "video" then
      newGui = VideoElement:new(target)
    elseif t == "slider" then
      newGui = SliderElement:new(target)
    elseif t == "text" then
      newGui = TextElement:new(target)
    elseif t == "textInput" then
      newGui = TextInputElement:new(target)
    elseif t == "bitmap" then
      newGui = BitmapElement:new(target)
    elseif t == "list" then
      newGui = ListElement:new(target)
    elseif t == "multiTextOption" then
      newGui = MultiTextOptionElement:new(target)
    elseif t == "gameListItem" then
      newGui = GameListItemElement:new(target)
    elseif t == "controlsListItem" then
      newGui = ControlsListItemElement:new(target)
    elseif t == "listItem" then
      newGui = ListItemElement:new(target)
    else
      newGui = GuiElement:new(target)
    end
    newGui:loadFromXML(xmlFile, k)
    gui:addElement(newGui)
    self:loadGuiRec(xmlFile, k, newGui, target)
    if newGui.onCreate ~= nil then
      if newGui.target ~= nil then
        newGui.onCreate(newGui.target, newGui, newGui.onCreateArgs)
      else
        newGui.onCreate(newGui, newGui.onCreateArgs)
      end
    end
    i = i + 1
  end
end
function Gui:getProfile(name)
  return self.profiles[name]
end
function Gui:showGui(guiName)
  local gui = self.guis[guiName]
  if self.currentGui ~= nil then
    self.currentGui:onClose()
  end
  self.currentGui = gui
  self.currentGuiName = guiName
  self.currentListener = gui
  FocusManager:setGui(guiName)
  if gui ~= nil then
    gui:onOpen()
  end
  self:closeAllDialogs()
  if gui == nil then
  else
  end
  return gui
end
function Gui:showDialog(guiName)
  local gui = self.guis[guiName]
  if gui ~= nil then
    table.insert(self.dialogs, gui)
    gui:onOpen()
    self.currentListener = gui
    return gui
  end
end
function Gui:closeDialog(gui)
  for k, v in ipairs(self.dialogs) do
    if v == gui then
      v:onClose()
      table.remove(self.dialogs, k)
      if self.currentListener == gui then
        if table.getn(self.dialogs) > 0 then
          self.currentListener = self.dialogs[table.getn(self.dialogs)]
          break
        end
        self.currentListener = self.currentGui
      end
      break
    end
  end
end
function Gui:closeAllDialogs()
  for k, v in ipairs(self.dialogs) do
    v:onClose()
  end
  self.dialogs = {}
end
function Gui:mouseEvent(posX, posY, isDown, isUp, button)
  if self.currentListener ~= nil then
    self.currentListener:mouseEvent(posX, posY, isDown, isUp, button)
  end
  if self.currentGui ~= nil and self.currentGui.target ~= nil and self.currentGui.target.mouseEvent ~= nil then
    self.currentGui.target:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function Gui:keyEvent(unicode, sym, modifier, isDown)
  if self.currentListener ~= nil then
    self.currentListener:keyEvent(unicode, sym, modifier, isDown)
  end
  if self.currentGui ~= nil and self.currentGui.target ~= nil and self.currentGui.target.keyEvent ~= nil then
    self.currentGui.target:keyEvent(unicode, sym, modifier, isDown)
  end
end
function Gui:update(dt)
  if self.currentGui ~= nil then
    self.currentGui:update(dt)
    if self.currentGui and self.currentGui.target ~= nil and self.currentGui.target.update ~= nil then
      self.currentGui.target:update(dt)
    end
  end
  for k, v in ipairs(self.dialogs) do
    v:update(dt)
  end
end
function Gui:draw()
  if self.currentGui ~= nil then
    self.currentGui:draw()
    if self.currentGui.target ~= nil and self.currentGui.target.draw ~= nil then
      self.currentGui.target:draw()
    end
  end
  for k, v in ipairs(self.dialogs) do
    v:draw()
  end
end
