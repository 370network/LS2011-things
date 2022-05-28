ShutdownDialog = {}
local ShutdownDialog_mt = Class(ShutdownDialog)
function ShutdownDialog:new()
  local instance = {}
  instance = setmetatable(instance, ShutdownDialog_mt)
  return instance
end
function ShutdownDialog:onOpen(element)
  InputBinding.setShowMouseCursor(true)
end
function ShutdownDialog:onClose(element)
end
function ShutdownDialog:onOkClick()
  g_gui:showGui("JoinGameScreen")
end
