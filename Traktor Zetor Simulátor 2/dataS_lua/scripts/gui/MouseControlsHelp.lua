MouseControlsHelp = {}
MouseControlsHelp.BUTTON_NONE = 0
MouseControlsHelp.BUTTON_LEFT = 1
MouseControlsHelp.BUTTON_RIGHT = 2
MouseControlsHelp.BUTTON_MIDDLE = 3
MouseControlsHelp.BUTTON_LEFTRIGHT = 4
local MouseControlsHelp_mt = Class(MouseControlsHelp)
function MouseControlsHelp:new()
  return setmetatable({active = true}, MouseControlsHelp_mt)
end
function MouseControlsHelp:init()
  self.xPos = 0.005
  local yPos = 0.91
  local iconWidth = 0.06
  local iconHeight = 0.08
  local xMaxDisplacement = 0.208
  self.yPos = yPos
  self.iconWidth = iconWidth
  self.iconHeight = iconHeight
  self.mouseIconOverlays = {}
  local mouseIconFilenames = {
    [MouseControlsHelp.BUTTON_LEFT] = "mouseLMB",
    [MouseControlsHelp.BUTTON_RIGHT] = "mouseRMB",
    [MouseControlsHelp.BUTTON_MIDDLE] = "mouseMMB",
    [MouseControlsHelp.BUTTON_LEFTRIGHT] = "mouseBMB"
  }
  for icon, filename in pairs(mouseIconFilenames) do
    self.mouseIconOverlays[icon] = Overlay:new(filename, "dataS2/menu/mouseControlsHelp/" .. filename .. ".png", self.xPos, yPos, iconWidth, iconHeight)
  end
  self.arrowLROverlay = Overlay:new("arrowLR", "dataS2/menu/mouseControlsHelp/arrowLR.png", self.xPos + 0.155, yPos, iconWidth, iconHeight)
  self.arrowUDOverlay = Overlay:new("arrowUD", "dataS2/menu/mouseControlsHelp/arrowUD.png", self.xPos + 0.042, yPos, iconWidth, iconHeight)
  self.toolIconLROverlay = {}
  self.toolIconUDOverlay = {}
  self.currentMouseMode = 0
  self.currentLRToolIconName = ""
  self.currentUDToolIconName = ""
end
function MouseControlsHelp:render()
  if self.active and g_currentMission ~= nil and not g_currentMission.controlPlayer and self.currentMouseMode ~= MouseControlsHelp.BUTTON_NONE and (self.currentLRToolIconName ~= "" or self.currentUDToolIconName ~= "") then
    g_currentMission.disableHelpTextNextFrame = true
    self.mouseIconOverlays[self.currentMouseMode]:render()
    if self.toolIconLROverlay[self.currentLRToolIconName] ~= nil then
      self.arrowLROverlay:render()
      self.toolIconLROverlay[self.currentLRToolIconName]:render()
    end
    if self.toolIconUDOverlay[self.currentUDToolIconName] ~= nil then
      self.arrowUDOverlay:render()
      self.toolIconUDOverlay[self.currentUDToolIconName]:render()
    end
  end
end
function MouseControlsHelp:setMouseButton(mode)
  self.currentMouseMode = mode
end
function MouseControlsHelp:setIconFilename(iconXFilename, iconYFilename)
  self.currentLRToolIconName = iconXFilename
  self.currentUDToolIconName = iconYFilename
end
function MouseControlsHelp:addIconFilename(filename)
  self.toolIconLROverlay[filename] = Overlay:new(filename, filename, self.xPos + 0.208, self.yPos, self.iconWidth, self.iconHeight)
  self.toolIconUDOverlay[filename] = Overlay:new(filename, filename, self.xPos + 0.09, self.yPos, self.iconWidth, self.iconHeight)
end
