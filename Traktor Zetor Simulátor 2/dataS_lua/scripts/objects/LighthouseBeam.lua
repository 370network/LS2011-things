LighthouseBeam = {}
local LighthouseBeam_mt = Class(LighthouseBeam)
function LighthouseBeam:onCreate(id)
  g_currentMission:addUpdateable(LighthouseBeam:new(id))
end
function LighthouseBeam:new(name)
  local instance = {}
  setmetatable(instance, LighthouseBeam_mt)
  instance.me = name
  return instance
end
function LighthouseBeam:delete()
end
function LighthouseBeam:update(dt)
  local beamRot = -0.001 * dt
  rotate(self.me, 0, beamRot, 0)
end
