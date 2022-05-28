InvalidKeyDialog = {}
local InvalidKeyDialog_mt = Class(InvalidKeyDialog, ConnectionFailedDialog)
function InvalidKeyDialog:new()
  local self = ConnectionFailedDialog:new(InvalidKeyDialog_mt)
  return self
end
function InvalidKeyDialog:onPurchaseClick()
  openWebFile("fs2011Purchase.php", "")
end
