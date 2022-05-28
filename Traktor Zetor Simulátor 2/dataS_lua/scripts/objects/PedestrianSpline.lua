PedestrianSpline = {}
PedestrianSpline.pedestrianTypes = {}
function PedestrianSpline.addPedestrianType(filename, walkClipName, walkSpeed)
  table.insert(PedestrianSpline.pedestrianTypes, {
    filename = filename,
    walkClipName = walkClipName,
    walkSpeed = walkSpeed
  })
end
local PedestrianSpline_mt = Class(PedestrianSpline)
function PedestrianSpline:onCreate(id)
  g_currentMission:addUpdateable(PedestrianSpline:new(id))
end
function PedestrianSpline:new(id)
  local self = {}
  setmetatable(self, PedestrianSpline_mt)
  self.splineId = id
  self.viewDistance = Utils.getNoNil(getUserAttribute(id, "viewDistance"), 60) * getViewDistanceCoeff()
  self.speed = Utils.getNoNil(getUserAttribute(id, "speed"), 1)
  self.timeScale = self.speed * 0.001
  local length = getSplineLength(self.splineId)
  if length ~= 0 then
    self.timeScale = self.timeScale / length
  end
  setVisibility(self.splineId, false)
  self.pedestrians = {}
  local numPedestrians = Utils.getNoNil(getUserAttribute(id, "numPedestrians"), 10)
  local numScale = 1
  local profileId = Utils.getProfileClassId()
  if profileId == 2 then
    numScale = 0.9
  elseif profileId <= 1 then
    numScale = 0.7
  end
  numPedestrians = numPedestrians * numScale
  for i = 1, numPedestrians do
    local pedestrianType = PedestrianSpline.pedestrianTypes[math.random(1, table.getn(PedestrianSpline.pedestrianTypes))]
    local pedestrianId = createTransformGroup("PedestrianRoot")
    link(getRootNode(), pedestrianId)
    local rootNode = Utils.loadSharedI3DFile(pedestrianType.filename)
    local pedestrianSkeletonId = getChildAt(rootNode, 0)
    local pedestrianGraphicsId = getChildAt(rootNode, 1)
    setRigidBodyType(pedestrianGraphicsId, "NoRigidBody")
    link(pedestrianId, pedestrianSkeletonId)
    link(getRootNode(), pedestrianGraphicsId)
    delete(rootNode)
    local charSet = getAnimCharacterSet(pedestrianSkeletonId)
    enableAnimTrack(charSet, 0)
    assignAnimTrackClip(charSet, 0, getAnimClipIndex(charSet, pedestrianType.walkClipName))
    setAnimTrackSpeedScale(charSet, 0, self.speed / pedestrianType.walkSpeed)
    setAnimTrackLoopState(charSet, 0, true)
    setAnimTrackTime(charSet, 0, 0)
    setAnimTrackBlendWeight(charSet, 0, 1)
    local timeOffset = math.random() * 0.5 / numPedestrians
    local splineTime = 1 / numPedestrians * (i - 1) + timeOffset
    table.insert(self.pedestrians, {
      pedestrianId = pedestrianId,
      pedestrianGraphicsId = pedestrianGraphicsId,
      pedestrianType = pedestrianType,
      charSet = charSet,
      splineTime = splineTime,
      isVisible = true
    })
  end
  return self
end
function PedestrianSpline:delete()
  for i = 1, table.getn(self.pedestrians) do
    delete(self.pedestrians[i].pedestrianGraphicsId)
    delete(self.pedestrians[i].pedestrianId)
  end
end
function PedestrianSpline:update(dt)
  local px, py, pz = getWorldTranslation(getCamera())
  for i = 1, table.getn(self.pedestrians) do
    local pedestrian = self.pedestrians[i]
    pedestrian.splineTime = pedestrian.splineTime + self.timeScale * dt
    local x, y, z = getSplinePosition(self.splineId, pedestrian.splineTime)
    local distance = Utils.vector3Length(px - x, py - y, pz - z)
    if distance < self.viewDistance then
      if g_currentMission.environment.isSunOn then
        pedestrian.isVisible = true
      end
      if pedestrian.isVisible then
        enableAnimTrack(pedestrian.charSet, 0)
        local dx, dy, dz = getSplineDirection(self.splineId, pedestrian.splineTime)
        setTranslation(pedestrian.pedestrianId, x, y, z)
        setDirection(pedestrian.pedestrianId, dx, dy, dz, 0, 1, 0)
        setVisibility(pedestrian.pedestrianGraphicsId, true)
      end
    elseif pedestrian.isVisible then
      pedestrian.isVisible = false
      disableAnimTrack(pedestrian.charSet, 0)
      setVisibility(pedestrian.pedestrianGraphicsId, false)
    end
  end
end
