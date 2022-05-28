SiloAmountMover = {}
local SiloAmountMover_mt = Class(SiloAmountMover)
function SiloAmountMover:onCreate(id)
  g_currentMission:addNonUpdateable(SiloAmountMover:new(id))
end
function SiloAmountMover:new(nodeId)
  local self = {}
  setmetatable(self, SiloAmountMover_mt)
  self.nodeId = nodeId
  local minY, maxY = Utils.getVectorFromString(getUserAttribute(nodeId, "moveMinMaxY"))
  if minY ~= nil and maxY ~= nil then
    local maxAmount = tonumber(getUserAttribute(nodeId, "moveMaxAmount"))
    if maxAmount ~= nil then
      self.moveMinY = minY
      self.moveMaxY = maxY
      self.moveMaxAmount = maxAmount
    end
  end
  local fillType = getUserAttribute(nodeId, "fillType")
  if fillType ~= nil then
    self.fillType = Fillable.fillTypeNameToInt[fillType]
  end
  if self.fillType == nil then
    self.fillType = Fillable.FILLTYPE_LIQUIDMANURE
  end
  if self.moveMinY ~= nil then
    g_currentMission:addSiloAmountListener(self, self.fillType)
    self:onSiloAmountChanged(self.fillType, g_currentMission:getSiloAmount(self.fillType))
  else
    print("Error: SiloAmountMover '" .. getName(nodeId) .. "' invalid or missing user attributes 'moveMinMaxY' and 'moveMaxAmount'")
  end
  return self
end
function SiloAmountMover:delete()
  g_currentMission:removeSiloAmountListener(self)
end
function SiloAmountMover:onSiloAmountChanged(fillType, amount)
  if amount < 0.001 then
    amount = 0
  end
  local x, y, z = getTranslation(self.nodeId)
  local y = self.moveMinY + (self.moveMaxY - self.moveMinY) * Utils.clamp(amount, 0, self.moveMaxAmount) / self.moveMaxAmount
  setTranslation(self.nodeId, x, y, z)
end
