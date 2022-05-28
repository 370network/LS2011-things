DistantTrain = {}
local DistantTrain_mt = Class(DistantTrain)
function DistantTrain:onCreate(id)
  g_currentMission:addUpdateable(DistantTrain:new(id))
end
function DistantTrain:new(id)
  local instance = {}
  setmetatable(instance, DistantTrain_mt)
  instance.nurbsId = getChildAt(id, 0)
  instance.DistantTrainId = getChildAt(id, 1)
  instance.time = 1
  instance.currentDelay = math.random(20000, 120000)
  local dx, dy, dz = getSplineDirection(instance.nurbsId, 0.5)
  setDirection(instance.DistantTrainId, dx, 0, dz, 0, 1, 0)
  return instance
end
function DistantTrain:delete()
end
function DistantTrain:update(dt)
  if self.currentDelay > 0 then
    self.currentDelay = self.currentDelay - dt
  else
    self.time = self.time - 1.5E-4 * dt
    if 0 > self.time then
      self.time = 1
      self.currentDelay = math.random(20000, 120000)
    end
    local x, y, z = getSplinePosition(self.nurbsId, self.time)
    setTranslation(self.DistantTrainId, x, y, z)
  end
end
