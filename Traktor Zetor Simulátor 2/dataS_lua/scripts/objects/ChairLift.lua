ChairLift = {}
local ChairLift_mt = Class(ChairLift)
function ChairLift:onCreate(id)
  g_currentMission:addUpdateable(ChairLift:new(id))
end
function ChairLift:new(id)
  local instance = {}
  setmetatable(instance, ChairLift_mt)
  instance.nurbsId = getChildAt(id, 0)
  instance.chairLiftIds = {}
  table.insert(instance.chairLiftIds, getChildAt(id, 1))
  instance.times = {}
  table.insert(instance.times, 0)
  local length = getSplineLength(instance.nurbsId)
  instance.timeScale = Utils.getNoNil(getUserAttribute(id, "speed"), 10) / 3.6
  local numChairLifts = Utils.getNoNil(getUserAttribute(id, "numChairLifts"), 1)
  for i = 2, numChairLifts do
    local ChairLiftId = clone(instance.chairLiftIds[1], false, true)
    link(id, ChairLiftId)
    table.insert(instance.chairLiftIds, ChairLiftId)
    table.insert(instance.times, 1 / numChairLifts * (i - 1))
  end
  if length ~= 0 then
    instance.timeScale = instance.timeScale / length
  end
  return instance
end
function ChairLift:delete()
end
function ChairLift:update(dt)
  for i = 1, table.getn(self.chairLiftIds) do
    self.times[i] = self.times[i] - 0.001 * dt * self.timeScale
    local x, y, z = getSplinePosition(self.nurbsId, self.times[i])
    local dx, dy, dz = getSplineDirection(self.nurbsId, self.times[i])
    setTranslation(self.chairLiftIds[i], x, y, z)
    setDirection(self.chairLiftIds[i], dx, 0, dz, 0, 1, 0)
  end
end
