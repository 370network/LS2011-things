YesNoDialog = {}
local YesNoDialog_mt = Class(YesNoDialog)
function YesNoDialog:new()
  local instance = {}
  instance = setmetatable(instance, YesNoDialog_mt)
  return instance
end
function YesNoDialog:setText(text)
  if self.textElement ~= nil then
    self.textElement:setText(text)
  end
end
function YesNoDialog:onCreateText(element)
  self.textElement = element
end
function YesNoDialog:onYesClick()
  if self.onYesNo ~= nil then
    if self.target ~= nil then
      self.onYesNo(self.target, true)
    else
      self.onYesNo()
    end
  end
end
function YesNoDialog:onNoClick()
  if self.onYesNo ~= nil then
    if self.target ~= nil then
      self.onYesNo(self.target, false)
    else
      self.onYesNo()
    end
  end
end
function YesNoDialog:setCallbacks(onYesNo, target)
  self.onYesNo = onYesNo
  self.target = target
end
function YesNoDialog:update(dt)
  if InputBinding.hasEvent(InputBinding.MENU, true) or InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    InputBinding.hasEvent(InputBinding.MENU, true)
    InputBinding.hasEvent(InputBinding.MENU_CANCEL, true)
    self:onNoClick()
  end
end
