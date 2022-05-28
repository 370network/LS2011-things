WrongGameVersionDialog = {}
local WrongGameVersionDialog_mt = Class(WrongGameVersionDialog, ConnectionFailedDialog)
function WrongGameVersionDialog:new()
  local self = ConnectionFailedDialog:new(WrongGameVersionDialog_mt)
  return self
end
function WrongGameVersionDialog:onDownloadClick()
  openWebFile("fs2011Update.php", "")
end
