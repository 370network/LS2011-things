PasswordDialog = {}
local PasswordDialog_mt = Class(PasswordDialog)
function PasswordDialog:new()
  local instance = {}
  instance = setmetatable(instance, PasswordDialog_mt)
  return instance
end
function PasswordDialog:onCreateTextInput(element)
  self.textElement = element
end
function PasswordDialog:onOpen(element)
end
function PasswordDialog:onClose(element)
end
function PasswordDialog:onStartClick()
  if self.onPasswordEntered ~= nil then
    if self.target ~= nil then
      self.onPasswordEntered(self.target, self.textElement.text)
    else
      self.onPasswordEntered(self.textElement.text)
    end
  end
end
function PasswordDialog:setCallbacks(onPasswordEntered, target)
  self.onPasswordEntered = onPasswordEntered
  self.target = target
end
function PasswordDialog:update(dt)
end
