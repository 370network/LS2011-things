PortDialog = {}
local PortDialog_mt = Class(PortDialog)
function PortDialog:new()
  local instance = {}
  instance = setmetatable(instance, PortDialog_mt)
  return instance
end
function PortDialog:onOpen(element)
  InputBinding.setShowMouseCursor(true)
end
function PortDialog:onClose(element)
end
function PortDialog:onContinueClick()
  g_createGameScreen:startGameAfterPortCheck()
end
function PortDialog:onCancelClick()
  g_gui:showGui("CreateGameScreen")
end
function PortDialog:onCreateText(element)
  self.textElement = element
end
function PortDialog:showPortTestFailed()
  self.textElement:setText(g_i18n:getText("Port_Test_Failed"))
  g_gui:showGui("PortDialog")
end
function PortDialog:showPortTestConflict()
  self.textElement:setText(g_i18n:getText("Port_Test_Conflict"))
  g_gui:showGui("PortDialog")
end
