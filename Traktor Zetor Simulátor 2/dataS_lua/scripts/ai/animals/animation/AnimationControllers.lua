AnimationController = {}
local AnimationController_mt = Class(AnimationController)
function AnimationController.loadControllersFromXML(xmlFile, xmlBaseName, controllerList)
  local i = 0
  while true do
    local baseName = xmlBaseName .. string.format(".controller(%d)", i)
    local controllerName = getXMLString(xmlFile, baseName .. "#name")
    if controllerName == nil then
      break
    end
    local controller
    if controllerName == "animationLimitBySpeed" then
      controller = AnimationLimitBySpeedController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "animationLimitByAngle" then
      controller = AnimationLimitByAngleController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "locomotion" then
      controller = AnimationLocomotionController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "locomotion2Hack" then
      controller = AnimationLocomotion2HackController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "speedLimit" then
      controller = AnimationSpeedLimitController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "positionDataUpdate" then
      controller = AnimationPositionDataUpdateController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "finalPositionDataUpdate" then
      controller = AnimationFinalPositionDataUpdateController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "stepPositionDataUpdate" then
      controller = AnimationStepPositionDataUpdateController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "preventStateChange" then
      controller = PreventStateChangeController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "limitValue" then
      controller = AnimationLimitValueController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "updateValue" then
      controller = AnimationUpdateValueController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "shiftPosition" then
      controller = ShiftPositionController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "shiftPositionLinear" then
      controller = ShiftPositionLinearController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "calculateClipFactor" then
      controller = CalculateClipFactorController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "navMeshLimiter" then
      controller = NavMeshLimiterController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "cctMover" then
      controller = CCTMoverController:loadFromXML(xmlFile, baseName)
    elseif controllerName == "collection" then
      controller = ControllerCollection:loadFromXML(xmlFile, baseName)
    else
      print("unknown controller name : " .. controllerName)
      break
    end
    table.insert(controllerList, controller)
    i = i + 1
  end
end
AnimationController.functionStringHead = [[
    local f = function(self, agent, agentAnimationData, dt, animationInstance)
        local controllerList = self.controllers;
        local animation = animationInstance.animation;
        local animationState = animation.state;
--        local finalQuitAnimation = false;
        local quitAnimation = false;
]]
AnimationController.functionStringTail = [[
--        finalQuitAnimation = finalQuitAnimation or quitAnimation;
--        return finalQuitAnimation;
        return quitAnimation;
    end;
    return f;
]]
function AnimationController.loadControllersUpdateFunction(controllerList)
  local completeFunctionString = AnimationController.functionStringHead
  for i, controller in ipairs(controllerList) do
    local functionStringControllerSetup = [[
--            finalQuitAnimation = finalQuitAnimation or quitAnimation;
--            quitAnimation = false;
        ]]
    functionStringControllerSetup = functionStringControllerSetup .. string.format("local self = controllerList[%d];\n", i)
    local testFunctionString = AnimationController.functionStringHead
    local currentFunctionString = functionStringControllerSetup .. controller:getUpdateFunctionString()
    testFunctionString = testFunctionString .. currentFunctionString
    testFunctionString = testFunctionString .. AnimationController.functionStringTail
    local testTempFunction, errorMessage = loadstring(testFunctionString)
    if not testTempFunction then
      print(string.format("error: loading animation controller (%s) update function : %s", controller.name, errorMessage))
      return
    end
    completeFunctionString = completeFunctionString .. currentFunctionString
  end
  completeFunctionString = completeFunctionString .. AnimationController.functionStringTail
  local completeUpdateTempFunction, errorMessage = loadstring(completeFunctionString)
  if not completeUpdateTempFunction then
    print(string.format("error: loading animation controllers update function : %s", errorMessage))
    return
  end
  local completeUpdateFunction = completeUpdateTempFunction()
  return completeUpdateFunction
end
function AnimationController:new(name)
  if self == AnimationController then
    self = setmetatable({}, AnimationController_mt)
  end
  self.name = name
  return self
end
function AnimationController:onStart(agent, agentAnimationData, animationInstance)
end
function AnimationController.setUpdateFunction(animationController)
  local completeFunctionString = [[
        local f = function(self, agent, agentAnimationData, dt, animationInstance)
            local quitAnimation = false;
    ]]
  completeFunctionString = completeFunctionString .. AnimationController:getUpdateFunctionString()
  completeFunctionString = completeFunctionString .. [[
            return quitAnimation;
        end;
        return f;
    ]]
  local updateControllerTempFunction, errorMessage = loadstring(completeFunctionString)
  if not updateControllerTempFunction then
    print(string.format("error: loading AnimationController (%s) update function : %s", animationController.name, errorMessage))
    return
  end
  animationController.update = updateControllerTempFunction()
end
function AnimationController:getUpdateFunctionString()
  return "    "
end
AnimationController.setUpdateFunction(AnimationController)
function AnimationController:onStop(agent, agentAnimationData, animationInstance)
end
function AnimationController:isAnimationAllowedToStart(agent, agentAnimationData, animation)
  return true
end
function AnimationController:isStateChangeAllowed(agent, agentAnimationData, targetState)
  return true
end
AnimationLimitValueController = {}
local AnimationLimitValueController_mt = Class(AnimationLimitValueController, AnimationController)
function AnimationLimitValueController:loadFromXML(xmlFile, xmlBaseName)
  local controllerValueName = getXMLString(xmlFile, xmlBaseName .. "#valueName")
  local controllerMinValue = getXMLFloat(xmlFile, xmlBaseName .. "#minValue")
  local controllerMaxValue = getXMLFloat(xmlFile, xmlBaseName .. "#maxValue")
  if controllerValueName ~= "angle" and controllerValueName ~= "forwardSpeed" and controllerValueName ~= "distance" then
    error(string.format("error : AnimationLimitValueController:loadFromXML : unknown value name \"%s\"", controllerValueName))
  end
  if controllerValueName == "angle" then
    controllerMinValue = controllerMinValue / 180 * math.pi
    controllerMaxValue = controllerMaxValue / 180 * math.pi
  end
  return AnimationLimitValueController:new(controllerValueName, controllerMinValue, controllerMaxValue)
end
function AnimationLimitValueController:new(valueName, minValue, maxValue)
  if self == AnimationLimitValueController then
    self = setmetatable({}, AnimationLimitValueController_mt)
  end
  AnimationController.new(self, "animationLimitValue")
  self.valueName = valueName
  self.minValue = minValue
  self.maxValue = maxValue
  return self
end
function AnimationLimitValueController:getUpdateFunctionString()
  return [[
    --print(string.format("   AnimationLimitValueController:update : current speed %.2f , minSpeed %.2f maxSpeed %.2f", agentAnimationData.forwardSpeed, self.minForwardSpeed and self.minForwardSpeed or -1, self.maxForwardSpeed and self.maxForwardSpeed or -1));
        if (self.minValue and agentAnimationData[self.valueName] < self.minValue) then
            agentAnimationData[self.valueName] = self.minValue;
        end;
        if (self.maxValue and agentAnimationData[self.valueName] > self.maxValue) then
            agentAnimationData[self.valueName] = self.maxValue;
        end;
    ]]
end
AnimationController.setUpdateFunction(AnimationLimitValueController)
AnimationUpdateValueController = {}
local AnimationUpdateValueController_mt = Class(AnimationUpdateValueController, AnimationController)
function AnimationUpdateValueController:loadFromXML(xmlFile, xmlBaseName)
  local controllerValueName = getXMLString(xmlFile, xmlBaseName .. "#valueName")
  if controllerValueName ~= "angle" and controllerValueName ~= "forwardSpeed" and controllerValueName ~= "distance" then
    error(string.format("error : AnimationLimitValueController:loadFromXML : unknown value name \"%s\"", controllerValueName))
  end
  return AnimationUpdateValueController:new(controllerValueName)
end
function AnimationUpdateValueController:new(valueName)
  if self == AnimationUpdateValueController then
    self = setmetatable({}, AnimationUpdateValueController_mt)
  end
  AnimationController.new(self, "animationUpdateValue")
  self.valueName = valueName
  return self
end
function AnimationUpdateValueController:onStart(agent, agentAnimationData, animationInstance)
  local range = agentAnimationData.nextValues[self.valueName] - agentAnimationData.lastValues[self.valueName]
  local changePerMS
  if animationInstance.duration > 0 then
    changePerMS = range / animationInstance.duration
  else
    changePerMS = 0
  end
  agentAnimationData[self] = agentAnimationData[self] or {changePerMS = changePerMS}
end
function AnimationUpdateValueController:getUpdateFunctionString()
  return [[
        agentAnimationData[self.valueName] = 
            agentAnimationData[self.valueName] + agentAnimationData[self].changePerMS;
    ]]
end
AnimationController.setUpdateFunction(AnimationUpdateValueController)
AnimationPositionDataUpdateController = {}
local AnimationPositionDataUpdateController_mt = Class(AnimationPositionDataUpdateController, AnimationController)
function AnimationPositionDataUpdateController:loadFromXML(xmlFile, xmlBaseName)
  return AnimationPositionDataUpdateController:new()
end
function AnimationPositionDataUpdateController:new()
  if AnimationPositionDataUpdateController.instance then
    return AnimationPositionDataUpdateController.instance
  end
  local instance = setmetatable({}, AnimationPositionDataUpdateController_mt)
  AnimationController.new(instance, "positionDataUpdate")
  AnimationPositionDataUpdateController.instance = instance
  return instance
end
function AnimationPositionDataUpdateController:onStart(agent, agentAnimationData, animationInstance)
end
function AnimationPositionDataUpdateController:getUpdateFunctionString()
  return [[
        --print(string.format("AnimationPositionDataUpdateController:update()"))
        -- TODO: remove hack
        WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt);
    ]]
end
AnimationController.setUpdateFunction(AnimationPositionDataUpdateController)
function AnimationPositionDataUpdateController:onStop(agent, agentAnimationData, animationInstance)
  WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt)
end
AnimationFinalPositionDataUpdateController = {}
local AnimationFinalPositionDataUpdateController_mt = Class(AnimationFinalPositionDataUpdateController, AnimationController)
function AnimationFinalPositionDataUpdateController:loadFromXML(xmlFile, xmlBaseName)
  return AnimationFinalPositionDataUpdateController:new()
end
function AnimationFinalPositionDataUpdateController:new()
  if AnimationFinalPositionDataUpdateController.instance then
    return AnimationFinalPositionDataUpdateController.instance
  end
  local instance = setmetatable({}, AnimationFinalPositionDataUpdateController_mt)
  AnimationController.new(instance, "finalPositionDataUpdate")
  AnimationFinalPositionDataUpdateController.instance = instance
  return instance
end
function AnimationFinalPositionDataUpdateController:onStart(agent, agentAnimationData, animationInstance)
end
function AnimationFinalPositionDataUpdateController:getUpdateFunctionString()
  return [[
        --print(string.format("AnimationFinalPositionDataUpdateController:update()"))
    ]]
end
AnimationController.setUpdateFunction(AnimationFinalPositionDataUpdateController)
function AnimationFinalPositionDataUpdateController:onStop(agent, agentAnimationData, animationInstance)
  WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt)
end
AnimationStepPositionDataUpdateController = {}
local AnimationStepPositionDataUpdateController_mt = Class(AnimationStepPositionDataUpdateController, AnimationController)
function AnimationStepPositionDataUpdateController:loadFromXML(xmlFile, xmlBaseName)
  return AnimationStepPositionDataUpdateController:new()
end
function AnimationStepPositionDataUpdateController:new()
  if AnimationStepPositionDataUpdateController.instance then
    return AnimationStepPositionDataUpdateController.instance
  end
  local instance = setmetatable({}, AnimationStepPositionDataUpdateController_mt)
  AnimationController.new(instance, "stepPositionDataUpdate")
  AnimationStepPositionDataUpdateController.instance = instance
  return instance
end
function AnimationStepPositionDataUpdateController:onStart(agent, agentAnimationData, animationInstance)
  agentAnimationData.nextValues = agentAnimationData.nextValues or {}
  agentAnimationData.lastValues = agentAnimationData.lastValues or {}
  agentAnimationData.lastValues.forwardSpeed = agentAnimationData.forwardSpeed
  agentAnimationData.lastValues.angle = agentAnimationData.angle
  agentAnimationData.lastValues.distance = agentAnimationData.distance
  WalkAnimationState:updateWalkingAnimationData(agent, agentAnimationData, dt)
  agentAnimationData.nextValues.forwardSpeed = agentAnimationData.forwardSpeed
  agentAnimationData.nextValues.angle = agentAnimationData.angle
  agentAnimationData.nextValues.distance = agentAnimationData.distance
  agentAnimationData.forwardSpeed = agentAnimationData.lastValues.forwardSpeed
  agentAnimationData.angle = agentAnimationData.lastValues.angle
  agentAnimationData.distance = agentAnimationData.lastValues.distance
  local duration = animationInstance.animation.duration
  if 0 < duration then
    local distanceRange = agentAnimationData.nextValues.distance - agentAnimationData.lastValues.distance
    agentAnimationData.distanceChangePerMS = distanceRange / duration
    local forwardSpeedRange = agentAnimationData.nextValues.forwardSpeed - agentAnimationData.lastValues.forwardSpeed
    agentAnimationData.forwardSpeedChangePerMS = forwardSpeedRange / duration
    local angleRange = agentAnimationData.nextValues.angle - agentAnimationData.lastValues.angle
    agentAnimationData.angleChangePerMS = angleRange / duration
  else
    agentAnimationData.distanceChangePerMS = 0
    agentAnimationData.forwardSpeedChangePerMS = 0
    agentAnimationData.angleChangePerMS = 0
  end
end
function AnimationStepPositionDataUpdateController:getUpdateFunctionString()
  return [[
        --print("AnimationStepPositionDataUpdateController:update");
        agentAnimationData.distance = agentAnimationData.distance + agentAnimationData.distanceChangePerMS * dt;
        agentAnimationData.forwardSpeed = agentAnimationData.forwardSpeed + agentAnimationData.forwardSpeedChangePerMS * dt;
        agentAnimationData.angle = agentAnimationData.angle + agentAnimationData.angleChangePerMS * dt;
    ]]
end
AnimationController.setUpdateFunction(AnimationStepPositionDataUpdateController)
function AnimationStepPositionDataUpdateController:onStop(agent, agentAnimationData, animationInstance)
end
AnimationLimitBySpeedController = {}
local AnimationLimitBySpeedController_mt = Class(AnimationLimitBySpeedController, AnimationController)
function AnimationLimitBySpeedController:loadFromXML(xmlFile, xmlBaseName)
  local controllerMinSpeed = getXMLFloat(xmlFile, xmlBaseName .. "#minSpeed")
  local controllerMaxSpeed = getXMLFloat(xmlFile, xmlBaseName .. "#maxSpeed")
  return AnimationLimitBySpeedController:new(controllerMinSpeed, controllerMaxSpeed)
end
function AnimationLimitBySpeedController:new(minForwardSpeed, maxForwardSpeed)
  if self == AnimationLimitBySpeedController then
    self = setmetatable({}, AnimationLimitBySpeedController_mt)
  end
  AnimationController.new(self, "animationLimitBySpeed")
  self.minForwardSpeed = minForwardSpeed
  self.maxForwardSpeed = maxForwardSpeed
  return self
end
function AnimationLimitBySpeedController:getUpdateFunctionString()
  return [[
        --print(string.format("   AnimationLimitBySpeedController:update : current speed %.2f , minSpeed %.2f maxSpeed %.2f", agentAnimationData.forwardSpeed, self.minForwardSpeed and self.minForwardSpeed or -1, self.maxForwardSpeed and self.maxForwardSpeed or -1));
        if (self.minForwardSpeed and agentAnimationData.forwardSpeed < self.minForwardSpeed) then
--print(string.format("AnimationLimitBySpeedController minspeed breached   current speed %.2f   min speed %.2f", agentAnimationData.forwardSpeed, self.minForwardSpeed));
            quitAnimation = true;
        end;
        if (self.maxForwardSpeed and agentAnimationData.forwardSpeed > self.maxForwardSpeed) then
--print(string.format("AnimationLimitBySpeedController maxspeed breached   current speed %.2f   max speed %.2f", agentAnimationData.forwardSpeed, self.maxForwardSpeed));
            quitAnimation = true;
        end;
    ]]
end
AnimationController.setUpdateFunction(AnimationLimitBySpeedController)
function AnimationLimitBySpeedController:isAnimationAllowedToStart(agent, agentAnimationData, animation)
  return animation.state.name == "walk"
end
AnimationLimitByAngleController = {}
local AnimationLimitByAngleController_mt = Class(AnimationLimitByAngleController, AnimationController)
function AnimationLimitByAngleController:loadFromXML(xmlFile, xmlBaseName)
  local controllerMinAngle = getXMLFloat(xmlFile, xmlBaseName .. "#minAngle")
  local controllerMaxAngle = getXMLFloat(xmlFile, xmlBaseName .. "#maxAngle")
  return AnimationLimitByAngleController:new(controllerMinAngle and controllerMinAngle / 180 * math.pi, controllerMaxAngle and controllerMaxAngle / 180 * math.pi)
end
function AnimationLimitByAngleController:new(minAngle, maxAngle)
  if self == AnimationLimitByAngleController then
    self = setmetatable({}, AnimationLimitByAngleController_mt)
  end
  AnimationController.new(self, "animationLimitByAngle")
  self.minAngle = minAngle
  self.maxAngle = maxAngle
  return self
end
function AnimationLimitByAngleController:getUpdateFunctionString()
  return [[
        --print(string.format("   AnimationLimitByAngleController:update : current angle %.2f , minAngle %.2f maxAngle %.2f", agentAnimationData.angle, self.minAngle and self.minAngle or 0, self.maxAngle and self.maxAngle or 0));
        if (self.minAngle and agentAnimationData.angle < self.minAngle) then
            quitAnimation = true;
        end;
        if (self.maxAngle and agentAnimationData.angle > self.maxAngle) then
            quitAnimation = true;
        end;
    ]]
end
AnimationController.setUpdateFunction(AnimationLimitByAngleController)
function AnimationLimitByAngleController:isAnimationAllowedToStart(agent, agentAnimationData, animation)
  return animation.state.name == "walk"
end
AnimationLocomotionController = {}
local AnimationLocomotionController_mt = Class(AnimationLocomotionController, AnimationController)
function AnimationLocomotionController:loadFromXML(xmlFile, xmlBaseName)
  return AnimationLocomotionController:new()
end
function AnimationLocomotionController:new(minForwardSpeed, maxForwardSpeed)
  if self == AnimationLocomotionController then
    self = setmetatable({}, AnimationLocomotionController_mt)
  end
  AnimationController.new(self, "locomotion")
  return self
end
function AnimationLocomotionController:getUpdateFunctionString()
  return [[
        local dt_s = dt / 1000;
        
        local currentForwardSpeed = agentAnimationData.forwardSpeed;        --length / movementLatency_s;--  agent.speed;       -- TODO: if agents position is not the animations position the speed has to get measured again
        local currentRotationalSpeed = agentAnimationData.rotationalSpeed;  --angleToRotate / movementLatency_s;--agent.rotationalSpeedY;       -- TODO: if agents position is not the animations position the speed has to get measured again
            
        -- update visible position of the animation according to the agent's position
        agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = 
            MotionControl:getRotatedDirection(
                agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ,
                0, currentRotationalSpeed * dt_s, 0)
        agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
            agentAnimationData.animationPositionX + agentAnimationData.animationDirectionX * currentForwardSpeed * dt_s,--1.598 * dt_s,
            agent.positionY,--eneralAnimationData.animationPositionY + agentAnimationData.animationDirectionY * currentForwardSpeed * 1.5 * dt_s,
            agentAnimationData.animationPositionZ + agentAnimationData.animationDirectionZ * currentForwardSpeed * dt_s;--1.598 * dt_s;
        agentAnimationData.animationPositionY = 
            getTerrainHeightAtWorldPos(
                agent.herd.groundObjectId, 
                agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ);
            
    --    setTranslation(agentAnimationData.bonesId, agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ);
    --    setDirection(agentAnimationData.bonesId, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ, 0, 1, 0);    
    ]]
end
AnimationController.setUpdateFunction(AnimationLocomotionController)
function AnimationLocomotionController:isStateChangeAllowed(agent, agentAnimationData, targetState)
  return targetState.name == "walk"
end
AnimationLocomotion2HackController = {}
local AnimationLocomotion2HackController_mt = Class(AnimationLocomotion2HackController, AnimationController)
function AnimationLocomotion2HackController:loadFromXML(xmlFile, xmlBaseName)
  return AnimationLocomotion2HackController:new()
end
function AnimationLocomotion2HackController:new(minForwardSpeed, maxForwardSpeed)
  if self == AnimationLocomotion2HackController then
    self = setmetatable({}, AnimationLocomotion2HackController_mt)
  end
  AnimationController.new(self, "locomotion2hack")
  return self
end
function AnimationLocomotion2HackController:getUpdateFunctionString()
  return [[
    
--        if (animationInstance.animation.state:isFlagSet(agent, agentAnimationData, "positionIsConstrained")) then   -- TODO: should be checked before altering the position
--print("position is constrained")
            animationInstance.animation.positionUpdater:setPosition(
                    agent, agentAnimationData, 
                    agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ);
--        end;
    ]]
end
AnimationController.setUpdateFunction(AnimationLocomotion2HackController)
AnimationSpeedLimitController = {}
local AnimationSpeedLimitController_mt = Class(AnimationSpeedLimitController, AnimationController)
function AnimationSpeedLimitController:loadFromXML(xmlFile, xmlBaseName)
  local controllerMinSpeed = getXMLFloat(xmlFile, xmlBaseName .. "#minSpeed")
  local controllerMaxSpeed = getXMLFloat(xmlFile, xmlBaseName .. "#maxSpeed")
  return AnimationSpeedLimitController:new(controllerMinSpeed, controllerMaxSpeed)
end
function AnimationSpeedLimitController:new(minForwardSpeed, maxForwardSpeed)
  if self == AnimationSpeedLimitController then
    self = setmetatable({}, AnimationSpeedLimitController_mt)
  end
  AnimationController.new(self, "speedLimit")
  self.minForwardSpeed = minForwardSpeed
  self.maxForwardSpeed = maxForwardSpeed
  return self
end
function AnimationSpeedLimitController:getUpdateFunctionString()
  return [[
    --print(string.format("   AnimationSpeedLimitController:update : current speed %.2f , minSpeed %.2f maxSpeed %.2f", agentAnimationData.forwardSpeed, self.minForwardSpeed and self.minForwardSpeed or -1, self.maxForwardSpeed and self.maxForwardSpeed or -1));
        if (self.minForwardSpeed and agentAnimationData.forwardSpeed < self.minForwardSpeed) then
            agentAnimationData.forwardSpeed = self.minForwardSpeed;
        end;
        if (self.maxForwardSpeed and agentAnimationData.forwardSpeed > self.maxForwardSpeed) then
            agentAnimationData.forwardSpeed = self.maxForwardSpeed;
        end;

    --print(string.format("   AnimationSpeedLimitController:update : current speed %.2f", agentAnimationData.forwardSpeed));
    ]]
end
AnimationController.setUpdateFunction(AnimationSpeedLimitController)
PreventStateChangeController = {}
local PreventStateChangeController_mt = Class(PreventStateChangeController, AnimationController)
function PreventStateChangeController:loadFromXML(xmlFile, xmlBaseName)
  return PreventStateChangeController:new()
end
function PreventStateChangeController:new()
  if self == PreventStateChangeController then
    self = setmetatable({}, PreventStateChangeController_mt)
  end
  AnimationController.new(self, "preventStateChange")
  return self
end
function PreventStateChangeController:isStateChangeAllowed(agent, agentAnimationData, targetState)
  return false
end
ShiftPositionController = {}
local ShiftPositionController_mt = Class(ShiftPositionController, AnimationController)
function ShiftPositionController:loadFromXML(xmlFile, xmlBaseName)
  local positionChangePerS = Utils.getNoNil(getXMLFloat(xmlFile, xmlBaseName .. "#positionChangePerS"), 0.1)
  local rotationChangePerS = Utils.getNoNil(getXMLFloat(xmlFile, xmlBaseName .. "#rotationChangePerS"), 0.1)
  local positionChangePerMS = positionChangePerS / 1000
  local rotationChangePerMS = rotationChangePerS / 1000
  return ShiftPositionController:new(positionChangePerMS, rotationChangePerMS)
end
function ShiftPositionController:new(positionChangePerMS, rotationChangePerMS)
  if self == ShiftPositionController then
    self = setmetatable({}, ShiftPositionController_mt)
  end
  AnimationController.new(self, "shiftPosition")
  self.positionChangePerMS = positionChangePerMS
  self.rotationChangePerMS = rotationChangePerMS
  return self
end
function ShiftPositionController:getUpdateFunctionString()
  return [[
        -- correct visible position/rotation of the animation in small steps towards the agent's position/rotation
                
        local positionConnectionX, --[=[positionConnectionY,--]=] positionConnectionZ = 
            agent.positionX - agentAnimationData.animationPositionX,
            --[=[0,--]=]
            agent.positionZ - agentAnimationData.animationPositionZ;
        local positionDifference = Utils.vector3Length(
            positionConnectionX,
            0,
            positionConnectionZ);
            
        if (positionDifference > 0) then
            local correctingDirectionX, --[=[correctingDirectionY,--]=] correctingDirectionZ = 
                positionConnectionX / positionDifference,
                --0,
                positionConnectionZ / positionDifference;
            
            local appliedTranslation = 
                math.min(positionDifference, self.positionChangePerMS * dt);
            local appliedTranslationX, appliedTranslationZ = 
                correctingDirectionX * appliedTranslation,
                correctingDirectionZ * appliedTranslation;
        
            agentAnimationData.animationPositionX, --[=[agentAnimationData.animationPositionY,--]=] agentAnimationData.animationPositionZ = 
                agentAnimationData.animationPositionX + 
                    appliedTranslationX,
                --[=[agentAnimationData.animationPositionY,--]=]
                agentAnimationData.animationPositionZ + 
                    appliedTranslationZ;
            
    --local rotationDifference = 0;
    --local appliedRotation = 0;
    --print(self.positionChangePerMS);
    --print(string.format("ShiftPositionController:update() positionDifference : %.5f  rotationDifference : %.2f", positionDifference, rotationDifference));
    --print(string.format("ShiftPositionController:update() appliedTranslation : %.5f (%.5f %.5f)  appliedRotation : %.2f", appliedTranslation, appliedTranslationX, appliedTranslationZ, appliedRotation));

        end;
    ]]
end
AnimationController.setUpdateFunction(ShiftPositionController)
ShiftPositionLinearController = {}
local ShiftPositionLinearController_mt = Class(ShiftPositionLinearController, AnimationController)
function ShiftPositionLinearController:loadFromXML(xmlFile, xmlBaseName)
  local positionChangePerS = Utils.getNoNil(getXMLFloat(xmlFile, xmlBaseName .. "#positionChangePerS"), 0.1)
  local rotationChangePerS = Utils.getNoNil(getXMLFloat(xmlFile, xmlBaseName .. "#rotationChangePerS"), 0.1)
  local positionChangePerMS = positionChangePerS / 1000
  local rotationChangePerMS = rotationChangePerS / 1000
  return ShiftPositionLinearController:new(positionChangePerMS, rotationChangePerMS)
end
function ShiftPositionLinearController:new(positionChangePerMS, rotationChangePerMS)
  if self == ShiftPositionLinearController then
    self = setmetatable({}, ShiftPositionLinearController_mt)
  end
  AnimationController.new(self, "shiftPositionLinear")
  self.positionChangePerMS = positionChangePerMS
  self.rotationChangePerMS = rotationChangePerMS
  return self
end
function ShiftPositionLinearController:getUpdateFunctionString()
  return [[
        -- correct visible position/rotation of the animation in small steps towards the agent's position/rotation
                
        local positionConnectionX, positionConnectionY, positionConnectionZ = 
            agent.positionX - agentAnimationData.animationPositionX,
            0,
            agent.positionZ - agentAnimationData.animationPositionZ;
            
        -- project connection on the animation direction
        local factor = Utils.dotProduct(
            positionConnectionX, positionConnectionY, positionConnectionZ,
            agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ);
        positionConnectionX, positionConnectionY, positionConnectionZ = 
            agentAnimationData.animationDirectionX * factor, 
            agentAnimationData.animationDirectionY * factor, 
            agentAnimationData.animationDirectionZ * factor;
            
        local positionDifference = Utils.vector3Length(
            positionConnectionX,
            0,
            positionConnectionZ);
            
        if (positionDifference > 0) then
            local correctingDirectionX, --[=[correctingDirectionY,--]=] correctingDirectionZ = 
                positionConnectionX / positionDifference,
                --0,
                positionConnectionZ / positionDifference;
            
            local appliedTranslation = 
                math.min(positionDifference, self.positionChangePerMS * dt);
            local appliedTranslationX, appliedTranslationZ = 
                correctingDirectionX * appliedTranslation,
                correctingDirectionZ * appliedTranslation;
        
            agentAnimationData.animationPositionX, --[=[agentAnimationData.animationPositionY,--]=] agentAnimationData.animationPositionZ = 
                agentAnimationData.animationPositionX + 
                    appliedTranslationX,
                --[=[agentAnimationData.animationPositionY,--]=]
                agentAnimationData.animationPositionZ + 
                    appliedTranslationZ;
            
--    local rotationDifference = 0;
--    local appliedRotation = 0;
--    print(self.positionChangePerMS);
--    print(string.format("ShiftPositionLinearController:update() positionDifference : %.5f  rotationDifference : %.2f", positionDifference, rotationDifference));
--    print(string.format("ShiftPositionLinearController:update() appliedTranslation : %.5f (%.5f %.5f)  appliedRotation : %.2f", appliedTranslation, appliedTranslationX, appliedTranslationZ, appliedRotation));

        end;
    ]]
end
AnimationController.setUpdateFunction(ShiftPositionLinearController)
CalculateClipFactorController = {}
local CalculateClipFactorController_mt = Class(CalculateClipFactorController, AnimationController)
function CalculateClipFactorController:loadFromXML(xmlFile, xmlBaseName)
  local useSubClip = Utils.getNoNil(getXMLBool(xmlFile, xmlBaseName .. "#useSubClip"), false)
  local subClipIndex = getXMLFloat(xmlFile, xmlBaseName .. "#subClipId")
  return CalculateClipFactorController:new(useSubClip, subClipIndex)
end
function CalculateClipFactorController:new(useSubClip, subClipIndex)
  if self == CalculateClipFactorController then
    self = setmetatable({}, CalculateClipFactorController_mt)
  end
  if useSubClip and subClipIndex ~= "1" and subClipIndex ~= "2" then
    print("error CalculateClipFactorController : wrong subClipIndex specified")
  end
  AnimationController.new(self, "shiftPosition")
  self.useSubClip = useSubClip
  self.subClipIndex = subClipIndex
  return self
end
function CalculateClipFactorController:onStart(agent, agentAnimationData, animationInstance)
  agentAnimationData.clipFactor = 0
  if self.useSubClip then
    if self.subClipIndex == "1" then
      agentAnimationData.clipFactorAnimationInstance = animationInstance.animation1Instance
    else
      agentAnimationData.clipFactorAnimationInstance = animationInstance.animation2Instance
    end
  else
    agentAnimationData.clipFactorAnimationInstance = animationInstance
  end
  agentAnimationData.clipFactorAnimationDuration = agentAnimationData.clipFactorAnimationInstance.animation.duration
end
function CalculateClipFactorController:getUpdateFunctionString()
  return [[
        local clipTime = getAnimTrackTime(agentAnimationData.characterSet, agentAnimationData.clipFactorAnimationInstance.assignedTrackId);
        if (agentAnimationData.clipFactorAnimationDuration > 0) then
            agentAnimationData.clipFactor = (clipTime / agentAnimationData.clipFactorAnimationDuration);
        else
            agentAnimationData.clipFactor = 1;
        end;
        
        --print(agentAnimationData.clipFactor);
    ]]
end
AnimationController.setUpdateFunction(CalculateClipFactorController)
function CalculateClipFactorController:onStop(agent, agentAnimationData, animationInstance)
  agentAnimationData.clipFactor = nil
  agentAnimationData.clipFactorAnimationInstance = nil
  agentAnimationData.clipFactorAnimationDuration = nil
end
NavMeshLimiterController = {}
local NavMeshLimiterController_mt = Class(NavMeshLimiterController, AnimationController)
function NavMeshLimiterController:loadFromXML(xmlFile, xmlBaseName)
  return NavMeshLimiterController:new()
end
function NavMeshLimiterController:new()
  if self == NavMeshLimiterController then
    self = setmetatable({}, NavMeshLimiterController_mt)
  end
  AnimationController.new(self, "navMeshLimiter")
  return self
end
function NavMeshLimiterController:onStart(agent, agentAnimationData, animationInstance)
  agentAnimationData.lastValidPositionX, agentAnimationData.lastValidPositionY, agentAnimationData.lastValidPositionZ = agentAnimationData.lastValidPositionX or agentAnimationData.animationPositionX, agentAnimationData.lastValidPositionY or agentAnimationData.animationPositionY, agentAnimationData.lastValidPositionZ or agentAnimationData.animationPositionZ
end
function NavMeshLimiterController:getUpdateFunctionString()
  local functionString = ""
  functionString = functionString .. [[
        local navMesh = agent.herd.animationNavMesh;
        
        local targetPositionX, targetPositionY, targetPositionZ = 
            agentAnimationData.animationPositionX, 
            agentAnimationData.animationPositionY,
            agentAnimationData.animationPositionZ;
        local lastValidPositionX, lastValidPositionY, lastValidPositionZ = 
            agentAnimationData.lastValidPositionX, 
            agentAnimationData.lastValidPositionY, 
            agentAnimationData.lastValidPositionZ;

        local isWallHit, hitDistance = navMeshRaycast(
            navMesh, 
            lastValidPositionX, lastValidPositionY, lastValidPositionZ,
            targetPositionX, targetPositionY, targetPositionZ);

        if (hitDistance == 0) then
--print("(hitDistance == 0)  +++++++")
            isWallHit, hitDistance = navMeshRaycast(
                navMesh, 
                targetPositionX, targetPositionY, targetPositionZ,
                lastValidPositionX, lastValidPositionY, lastValidPositionZ);
--print(string.format("  animationPosition %.10f %.10f %.10f", agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ));
--print(string.format("  lastValidPosition %.10f %.10f %.10f", lastValidPositionX, lastValidPositionY, lastValidPositionZ));

        end;
        
--print(string.format("isWallHit %s hitDistance %s", tostring(isWallHit), tostring(hitDistance)));

        local distanceToWall = getNavMeshDistanceToWall(
            navMesh,
            targetPositionX, targetPositionY, targetPositionZ,
            10, "navMeshObstacleCallback", self);

        local isPositionAllowed = isWallHit and (hitDistance == 1) and (distanceToWall > 0.01);

            
        local distanceMax = 10;
        local distance = 
            Utils.vector3Length(
                agent.positionX - lastValidPositionX,
                agent.positionY - lastValidPositionY,
                agent.positionZ - lastValidPositionZ);
        local disableBlockingBecauseOfDistance = (distance > distanceMax);

        if (isPositionAllowed or disableBlockingBecauseOfDistance) then
            -- the current position of the animation is allowed (or something blocked the animation for too long and the block is overriden)
            
            if (disableBlockingBecauseOfDistance) then      -- TODO: move to special controller
                -- animation is to far away from its supposed position (maybe stuck), beam the animal to the supposed position
                
                agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
                    agent.positionX, 
                    getTerrainHeightAtWorldPos(
                        agent.herd.groundObjectId, 
                        agent.positionX, 
                        agent.positionY, 
                        agent.positionZ),
                    agent.positionZ;
            end;

            agentAnimationData.lastValidPositionX, agentAnimationData.lastValidPositionY, agentAnimationData.lastValidPositionZ = 
                agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ;
        else
--print(string.format("hitDistance %s", tostring(hitDistance)));
        
            -- the current position of the animation is outside the allowed nav mesh
            -- find a position that lies at the border of the nav mesh that preserves most of the animation movement
            
            local distanceToWall = getNavMeshDistanceToWall(
                navMesh,
                lastValidPositionX, lastValidPositionY, lastValidPositionZ,
                10, "navMeshObstacleCallback", self);
            
            -- prepare obstacle normal to be in the x,y plane
            local wallNormalX, wallNormalY, wallNormalZ = self.obstacleNormalX, 0, self.obstacleNormalZ;
            local cutNormalLength = Utils.vector3Length(wallNormalX, wallNormalY, wallNormalZ);
            if (cutNormalLength > 0.0001) then
                wallNormalX, wallNormalY, wallNormalZ = 
                    wallNormalX / cutNormalLength, 
                    wallNormalY / cutNormalLength, 
                    wallNormalZ / cutNormalLength;
            else
                -- we are directly on the wall, try to use a position slightly behind the current movement
                local adjustedPositionX, adjustedPositionY, adjustedPositionZ = 
                    lastValidPositionX - agentAnimationData.animationDirectionX * 0.01, 
                    lastValidPositionY - agentAnimationData.animationDirectionY * 0.01, 
                    lastValidPositionZ - agentAnimationData.animationDirectionZ * 0.01;
--print(string.format("  adjustedPosition %.2f %.2f %.2f", adjustedPositionX, adjustedPositionY, adjustedPositionZ));
                getNavMeshDistanceToWall(
                    navMesh,
                    adjustedPositionX, adjustedPositionY, adjustedPositionZ,
                    10, "navMeshObstacleCallback", self);
                wallNormalX, wallNormalY, wallNormalZ = self.obstacleNormalX, 0, self.obstacleNormalZ;
                cutNormalLength = Utils.vector3Length(wallNormalX, wallNormalY, wallNormalZ);
                
                if (cutNormalLength > 0.0001) then
                    wallNormalX, wallNormalY, wallNormalZ = 
                        wallNormalX / cutNormalLength, 
                        wallNormalY / cutNormalLength, 
                        wallNormalZ / cutNormalLength;
                else
                    -- still no valid normal available
                    -- we are probably on the wall and facing along the wall
                    wallNormalX, wallNormalY, wallNormalZ = 
                        agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ;
                    -- TODO: is not correct, use perpendicular value
--print("CCC")
                end;
            end;
            
            local wallSideDirectionX, wallSideDirectionY, wallSideDirectionZ = Utils.crossProduct(wallNormalX, wallNormalY, wallNormalZ, 0, 1, 0);

            local connectionToPositionX, connectionToPositionY, connectionToPositionZ = 
                agentAnimationData.animationPositionX - lastValidPositionX, 
                agentAnimationData.animationPositionY - lastValidPositionY, 
                agentAnimationData.animationPositionZ - lastValidPositionZ;
            
            -- cast ray in side direction on nav mesh       -- TODO
            local distanceOnRay = Utils.dotProduct(connectionToPositionX, connectionToPositionY, connectionToPositionZ, wallSideDirectionX, wallSideDirectionY, wallSideDirectionZ);
            
            local finalPositionX, finalPositionY, finalPositionZ = 
                lastValidPositionX + wallNormalX * 0.0025 + wallSideDirectionX * distanceOnRay,     -- (the wallNormalX * 0.0025 was added because of accuracy problems)
                lastValidPositionY + wallNormalY * 0.0025 + wallSideDirectionY * distanceOnRay,
                lastValidPositionZ + wallNormalZ * 0.0025 + wallSideDirectionZ * distanceOnRay;


            isWallHit, hitDistance = navMeshRaycast(
                navMesh, 
                lastValidPositionX, lastValidPositionY, lastValidPositionZ,
                finalPositionX, finalPositionY, finalPositionZ);

            if (hitDistance == 0) then
--print("new (hitDistance == 0)  +++++++")
                isWallHit, hitDistance = navMeshRaycast(
                    navMesh, 
                    finalPositionX, finalPositionY, finalPositionZ,
                    lastValidPositionX, lastValidPositionY, lastValidPositionZ);
--print(string.format("  finalPosition %.10f %.10f %.10f", finalPositionX, finalPositionY, finalPositionZ));
--print(string.format("  lastValidPosition %.10f %.10f %.10f", lastValidPositionX, lastValidPositionY, lastValidPositionZ));
            end;
--print(string.format("new isWallHit %s hitDistance %s", tostring(isWallHit), tostring(hitDistance)));

--print(string.format("hitDistance %s", tostring(hitDistance)));

            if (isWallHit and (hitDistance < 1)) then
            
--print("AAA")
--[==[
print(string.format("position not allowed"));
print(string.format("  old distanceToWall %.2f", distanceToWall));

print(string.format("  lastValidPosition %.10f %.10f %.10f", lastValidPositionX, lastValidPositionY, lastValidPositionZ));
print(string.format("  animationPosition %.10f %.10f %.10f", agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ));
print(string.format("  animationDirection %.2f %.2f %.2f", agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ));
--print(string.format("  obstaclePosition %.2f %.2f %.2f", obstaclePositionX, obstaclePositionY, obstaclePositionZ));
print(string.format("  obstacleNormal %.2f %.2f %.2f", wallNormalX, wallNormalY, wallNormalZ));
print(string.format("  wallSideDirection %.2f %.2f %.2f", wallSideDirectionX, wallSideDirectionY, wallSideDirectionZ));
print(string.format("  connectionToPosition %.2f %.2f %.2f", connectionToPositionX, connectionToPositionY, connectionToPositionZ));
--print(string.format("  directionToPosition %.2f %.2f %.2f", directionToPositionX, directionToPositionY, directionToPositionZ));
print(string.format("  distanceOnRay %.2f", distanceOnRay));
print(string.format("  finalPosition %.2f %.2f %.2f", finalPositionX, finalPositionY, finalPositionZ));
print(string.format("  moved amount %.5f %.5f %.5f", finalPositionX - lastValidPositionX, finalPositionY - lastValidPositionY, finalPositionZ - lastValidPositionZ));
--print(string.format("  final distanceToWall %.2f", finalDistanceToWall));
--]==]
                -- also the new calculated position is outside the navmesh 
                -- (usually this means we are in a corner)
                -- we reset the position to the last valid position
                agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
                    agentAnimationData.lastValidPositionX, agentAnimationData.lastValidPositionY, agentAnimationData.lastValidPositionZ;
                    
                    
            else
--print("BBB")
                -- the adjusted position is valid
                
                finalPositionY = getTerrainHeightAtWorldPos(
                    agent.herd.groundObjectId, 
                    finalPositionX, 
                    finalPositionY, 
                    finalPositionZ);

                agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
                    finalPositionX, finalPositionY, finalPositionZ;
                agentAnimationData.lastValidPositionX, agentAnimationData.lastValidPositionY, agentAnimationData.lastValidPositionZ = 
                    finalPositionX, finalPositionY, finalPositionZ;
            end;
            
            -- clear values of nav mesh callback function
            self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ = nil, nil, nil;
            self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ = nil, nil, nil;
            self.distance = nil;
            
        end;
        
    ]]
  return functionString
end
AnimationController.setUpdateFunction(NavMeshLimiterController)
function NavMeshLimiterController:navMeshObstacleCallback(distance, positionX, positionY, positionZ, normalX, normalY, normalZ)
  self.obstaclePositionX, self.obstaclePositionY, self.obstaclePositionZ = positionX, positionY, positionZ
  self.obstacleNormalX, self.obstacleNormalY, self.obstacleNormalZ = normalX, normalY, normalZ
  self.distance = distance
end
function NavMeshLimiterController:onStop(agent, agentAnimationData, animationInstance)
end
CCTMoverController = {}
local CCTMoverController_mt = Class(CCTMoverController, AnimationController)
function CCTMoverController:loadFromXML(xmlFile, xmlBaseName)
  return CCTMoverController:new()
end
function CCTMoverController:new()
  if self == CCTMoverController then
    self = setmetatable({}, CCTMoverController_mt)
  end
  AnimationController.new(self, "cctMover")
  return self
end
function CCTMoverController:onStart(agent, agentAnimationData, animationInstance)
  agentAnimationData.lastAnimationPositionX, agentAnimationData.lastAnimationPositionY, agentAnimationData.lastAnimationPositionZ = agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ
end
function CCTMoverController:getUpdateFunctionString()
  local functionString = ""
  functionString = functionString .. [[
print()
        local collisionMask;
        local distanceMax = 5;
        local distance = 
            Utils.vector3Length(
                agent.positionX - agentAnimationData.lastAnimationPositionX,
                agent.positionY - agentAnimationData.lastAnimationPositionY,
                agent.positionZ - agentAnimationData.lastAnimationPositionZ);
        if (distance > distanceMax) then
print(string.format("animal %s displacement too big", agent.name))
            collisionMask = 0;
        else
            collisionMask = Player.movementCollisionMask;
            --collisionMask = Player.kinematicCollisionMask;
        end;
        
        local movementX, movementY, movementZ = 
            agentAnimationData.animationPositionX - agentAnimationData.lastAnimationPositionX,
            agentAnimationData.animationPositionY - agentAnimationData.lastAnimationPositionY,
            agentAnimationData.animationPositionZ - agentAnimationData.lastAnimationPositionZ;
        
        setCCTPosition(agentAnimationData.cctIndex, 0, 0, 0);
        
        moveCCT(agentAnimationData.cctIndex, 
                -movementX, -movementY, -movementZ, 
                collisionMask);

print(string.format("distance to agent %.5f", distance))
print(string.format("last position %.5f %.5f %.5f", agentAnimationData.lastAnimationPositionX, agentAnimationData.lastAnimationPositionY, agentAnimationData.lastAnimationPositionZ))
print(string.format("requestedPosition position %.5f %.5f %.5f", agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ))
print(string.format("movement %.5f %.5f %.5f", movementX, movementY, movementZ))

                
        agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
            --getCCTPosition(agentAnimationData.cctIndex);
            getWorldTranslation(agentAnimationData.bonesId);
            
--        agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = 
--            agentAnimationData.lastAnimationPositionX + movementX,
--            agentAnimationData.lastAnimationPositionY + movementY,
--            agentAnimationData.lastAnimationPositionZ + movementZ;
print(string.format("final movement %.5f %.5f %.5f", agentAnimationData.animationPositionX - agentAnimationData.lastAnimationPositionX, agentAnimationData.animationPositionY - agentAnimationData.lastAnimationPositionY, agentAnimationData.animationPositionZ - agentAnimationData.lastAnimationPositionZ))
print(string.format("finalPosition position %.5f %.5f %.5f", agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ))
            
            
local hitSide, hitUp, hitDown = getCCTCollisionFlags(agentAnimationData.cctIndex);
if hitSide then
print(string.format("animal %s hit side", agent.name))
end;
if hitUp then
print(string.format("animal %s hit up", agent.name))
end;
if hitDown then
print(string.format("animal %s hit down", agent.name))
end;




        agentAnimationData.lastAnimationPositionX, agentAnimationData.lastAnimationPositionY, agentAnimationData.lastAnimationPositionZ = 
            agentAnimationData.animationPositionX,
            agentAnimationData.animationPositionY,
            agentAnimationData.animationPositionZ;

    ]]
  return functionString
end
AnimationController.setUpdateFunction(CCTMoverController)
function CCTMoverController:onStop(agent, agentAnimationData, animationInstance)
  agentAnimationData.lastPositionX, agentAnimationData.lastPositionY, agentAnimationData.lastPositionZ = nil, nil, nil
end
ControllerCollection = {}
local ControllerCollection_mt = Class(ControllerCollection, AnimationController)
function ControllerCollection:loadFromXML(xmlFile, xmlBaseName)
  local ifFlag = getXMLString(xmlFile, xmlBaseName .. "#ifFlag")
  local ifNotFlag = getXMLString(xmlFile, xmlBaseName .. "#ifNotFlag")
  local subControllerList = {}
  AnimationController.loadControllersFromXML(xmlFile, xmlBaseName, subControllerList)
  return ControllerCollection:new(subControllerList, ifFlag, ifNotFlag)
end
function ControllerCollection:new(subControllerList, ifFlag, ifNotFlag)
  if self == ControllerCollection then
    self = setmetatable({}, ControllerCollection_mt)
  end
  AnimationController.new(self, "controllerCollection")
  self.subControllerList = subControllerList
  self.ifFlag = ifFlag
  self.ifNotFlag = ifNotFlag
  return self
end
function ControllerCollection:onStart(agent, agentAnimationData, animationInstance)
  for _, subController in ipairs(self.subControllerList) do
    subController:onStart(agent, agentAnimationData, animationInstance)
  end
end
function ControllerCollection:getUpdateFunctionString()
  local functionString = ""
  if self.ifFlag then
    functionString = functionString .. [[
            if (agentAnimationData.flagsHash[self.ifFlag]) then 
        ]]
  end
  if self.ifNotFlag then
    functionString = functionString .. [[
            if (not agentAnimationData.flagsHash[self.ifNotFlag]) then 
        ]]
  end
  functionString = functionString .. [[
        local subControllerList = self.subControllerList;
    ]]
  for i, subController in ipairs(self.subControllerList) do
    local functionStringControllerSetup = string.format("local self = subControllerList[%d];\n", i)
    local testFunctionString = AnimationController.functionStringHead
    local currentFunctionString = functionStringControllerSetup .. subController:getUpdateFunctionString()
    testFunctionString = testFunctionString .. currentFunctionString
    testFunctionString = testFunctionString .. AnimationController.functionStringTail
    local testTempFunction, errorMessage = loadstring(testFunctionString)
    if not testTempFunction then
      print(string.format("error: loading animation controller (%s) update function : %s", controller.name, errorMessage))
      return
    end
    functionString = functionString .. currentFunctionString
  end
  if self.ifNotFlag then
    functionString = functionString .. [[
            end;
        ]]
  end
  if self.ifFlag then
    functionString = functionString .. [[
            end;
        ]]
  end
  return functionString
end
AnimationController.setUpdateFunction(ControllerCollection)
function ControllerCollection:onStop(agent, agentAnimationData, animationInstance)
  for _, subController in ipairs(self.subControllerList) do
    subController:onStop(agent, agentAnimationData, animationInstance)
  end
end
