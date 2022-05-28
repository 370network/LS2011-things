ConnectionLostDialog = {}
local ConnectionLostDialog_mt = Class(ConnectionLostDialog)
function ConnectionLostDialog:new()
  local instance = {}
  instance = setmetatable(instance, ConnectionLostDialog_mt)
  return instance
end
function ConnectionLostDialog:onOpen(element)
  InputBinding.setShowMouseCursor(true)
end
function ConnectionLostDialog:onClose(element)
end
function ConnectionLostDialog:onOkClick()
  OnInGameMenuMenu()
end
function ConnectionLostDialog:onCreateText(element)
  self.failedTextElement = element
end
function ConnectionLostDialog:setFailedText(text)
  self.failedTextElement:setText(text)
end
