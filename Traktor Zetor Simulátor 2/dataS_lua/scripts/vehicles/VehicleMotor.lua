VehicleMotor = {}
VehicleMotor_mt = Class(VehicleMotor)
function VehicleMotor:new(minRpm, maxRpm, forwardTorqueCurve, backwardTorqueCurve, brakeForce, accelerations, forwardGearRatios, backwardGearRatio, differentialRatio, rpmFadeOutRange, maxTorques)
  local instance = {}
  setmetatable(instance, VehicleMotor_mt)
  instance.minRpm = minRpm
  instance.maxRpm = maxRpm
  instance.forwardTorqueCurve = forwardTorqueCurve
  instance.backwardTorqueCurve = backwardTorqueCurve
  instance.brakeForce = brakeForce
  instance.forwardGearRatios = forwardGearRatios
  instance.backwardGearRatio = backwardGearRatio
  instance.differentialRatio = differentialRatio
  instance.transmissionEfficiency = 1
  instance.lastMotorRpm = 0
  instance.rpmFadeOutRange = rpmFadeOutRange
  instance.speedLevel = 0
  instance.accelerations = accelerations
  instance.maxTorques = maxTorques
  instance.nonClampedMotorRpm = 0
  return instance
end
function VehicleMotor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
  self.lowBrakeForceScale = lowBrakeForceScale
  self.lowBrakeForceSpeedLimit = lowBrakeForceSpeedLimit
end
function VehicleMotor:getTorque(acceleration)
  local torque = 0
  local brakePedal = 0
  if 0 <= acceleration then
    torque = self.forwardTorqueCurve:get(self.lastMotorRpm)
  else
    torque = self.backwardTorqueCurve:get(self.lastMotorRpm)
  end
  local maxRpm = self:getMaxRpm()
  local fadeStartRpm = maxRpm - self.rpmFadeOutRange
  if fadeStartRpm < self.nonClampedMotorRpm then
    if maxRpm < self.nonClampedMotorRpm then
      brakePedal = Utils.lerp(0, 1, math.min((self.nonClampedMotorRpm - maxRpm) / self.rpmFadeOutRange, 1))
      torque = 0
    else
      torque = Utils.lerp(torque, 0, math.min((self.nonClampedMotorRpm - fadeStartRpm) / self.rpmFadeOutRange, 1))
    end
  end
  return torque, brakePedal
end
function VehicleMotor:computeMotorRpm(wheelRpm, acceleration)
  local temp = self:getGearRatio(acceleration) * self.differentialRatio
  self.nonClampedMotorRpm = wheelRpm * temp
  self.lastMotorRpm = math.max(self.nonClampedMotorRpm, self.minRpm)
end
function VehicleMotor:getGearRatio(acceleration)
  if 0 <= acceleration then
    if self.speedLevel ~= 0 then
      return self.forwardGearRatios[self.speedLevel]
    else
      return self.forwardGearRatios[3]
    end
  else
    return self.backwardGearRatio
  end
end
function VehicleMotor:getMaxRpm()
  if self.maxRpmOverride ~= nil then
    return self.maxRpmOverride
  elseif self.speedLevel ~= 0 then
    return self.maxRpm[self.speedLevel]
  else
    return self.maxRpm[3]
  end
end
function VehicleMotor:setSpeedLevel(level, force)
  if level ~= 0 and self.speedLevel == level and not force then
    self.speedLevel = 0
  else
    self.speedLevel = level
  end
end
