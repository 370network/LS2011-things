AnimationControl = {
  availableNumberOfTracks = 4,
  defaultBlendTime = 500,
  latency = 1000
}
function AnimationControl:initializeAnimations(animationId, animationDataFilename)
  if AnimationControl.loaded then
    return
  end
  local characterSet = getAnimCharacterSet(animationId)
  local xmlFile = loadXMLFile("AnimationData", animationDataFilename)
  local animations = {}
  local animationPoses = {}
  local animationTransitions = {}
  local animationStates = {}
  local animationBlendData = {}
  local clipEventData = {}
  local i = 0
  while true do
    local baseName = string.format("xml.animationStates.animationState(%d)", i)
    local animationStateName = getXMLString(xmlFile, baseName .. "#name")
    local animationStateType = getXMLString(xmlFile, baseName .. "#type")
    if animationStateName == nil then
      break
    end
    if animationStateName == "" then
      error("error: you have to specifiy an animation state name")
      break
    end
    if animationStates[animationStateName] then
      error("error: the given animation state name \"" .. animationStateName .. "\" was specified multiple times")
      break
    end
    local animationState = AnimationState:new({name = animationStateName, type = animationStateType})
    animationStates[animationStateName] = animationState
    i = i + 1
  end
  Animation.loadAnimationsFromXML(characterSet, xmlFile, "xml.animations", animations, animationStates)
  local i = 0
  while true do
    local baseName = string.format("xml.animationPoses.animationPose(%d)", i)
    local animationPoseName = getXMLString(xmlFile, baseName .. "#name")
    local animationStateName = getXMLString(xmlFile, baseName .. "#state")
    if animationPoseName == nil then
      break
    end
    if animationPoseName == "" or animationStateName == nil or animationStateName == "" then
      error("error: you have to specifiy an animation pose name and state")
      break
    end
    if animationPoses[animationPoseName] then
      error("error: the given animation pose name \"" .. animationPoseName .. "\" was specified multiple times")
      break
    end
    if not animationStates[animationStateName] then
      error("error: the given animation state name \"" .. animationStateName .. "\" was not specified before")
      break
    end
    local animationPose = AnimationPose:new({name = animationPoseName, stateName = animationStateName})
    animationPoses[animationPoseName] = animationPose
    animationStates[animationStateName].animationPoses[animationPoseName] = animationPose
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("xml.animationPoses.walkAnimationPose(%d)", i)
    local animationPoseName = getXMLString(xmlFile, baseName .. "#name")
    local animationStateName = getXMLString(xmlFile, baseName .. "#state")
    if animationPoseName == nil then
      break
    end
    if animationPoseName == "" or animationStateName == nil or animationStateName == "" then
      print("error: you have to specifiy an animation pose name and state")
      break
    end
    if animationPoses[animationPoseName] then
      print("error: the given animation pose name \"" .. animationPoseName .. "\" was specified multiple times")
      break
    end
    if not animationStates[animationStateName] then
      error("error: the given animation state name \"" .. animationStateName .. "\" was not specified before")
      break
    end
    local animationPose = WalkAnimationPose:new({name = animationPoseName, stateName = animationStateName})
    animationPoses[animationPoseName] = animationPose
    animationStates[animationStateName].animationPoses[animationPoseName] = animationPose
    i = i + 1
  end
  local function addAnimationTransition(sourceAnimationPoseName, animationName, targetAnimationPoseName, beginTimeFactor, endTimeFactor, conditions, controllers, updateControllersFunction)
    local generalTransitionData = animationTransitions[sourceAnimationPoseName] or {
      transitionsToState = {},
      transitionsToPose = {},
      transitions = {}
    }
    animationTransitions[sourceAnimationPoseName] = generalTransitionData
    local animation = animations[animationName]
    local sourcePose = animationPoses[sourceAnimationPoseName]
    local targetPose = animationPoses[targetAnimationPoseName]
    local newTransition = {
      sourcePoseName = sourceAnimationPoseName,
      sourcePose = sourcePose,
      targetPoseName = targetAnimationPoseName,
      targetPose = targetPose,
      animationName = animationName,
      animation = animation,
      beginTime = beginTimeFactor * animation.duration,
      endTime = endTimeFactor * animation.duration,
      time = (endTimeFactor - beginTimeFactor) * animation.duration,
      conditions = conditions,
      controllers = controllers,
      updateControllersFunction = updateControllersFunction
    }
    table.insert(generalTransitionData.transitions, newTransition)
    local poseTransitionData = generalTransitionData.transitionsToPose[targetAnimationPoseName] or {
      transitions = {}
    }
    generalTransitionData.transitionsToPose[targetAnimationPoseName] = poseTransitionData
    table.insert(poseTransitionData.transitions, newTransition)
    local stateTransitionData = generalTransitionData.transitionsToState[targetPose.stateName] or {
      transitions = {}
    }
    generalTransitionData.transitionsToState[targetPose.stateName] = stateTransitionData
    table.insert(stateTransitionData.transitions, newTransition)
  end
  local i = 0
  while true do
    local baseName = string.format("xml.animationTransitions.animationTransition(%d)", i)
    local sourcePoseName = getXMLString(xmlFile, baseName .. "#sourcePose")
    local animationName = getXMLString(xmlFile, baseName .. "#animation")
    local targetPoseName = getXMLString(xmlFile, baseName .. "#targetPose")
    local beginTimeFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#beginTimeFactor"), 0)
    local endTimeFactor = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#endTimeFactor"), 1)
    if sourcePoseName == nil then
      break
    end
    if sourcePoseName == "" or animationName == nil or animationName == "" or targetPoseName == nil or targetPoseName == "" then
      print("error: you have to specifiy a name for the transition animation and the connected poses")
      break
    end
    if not animations[animationName] then
      print("error: the specified animation name \"" .. animationName .. "\" was not registered as animation")
      break
    end
    if not animationPoses[sourcePoseName] then
      print("error: the specified source animation pose name \"" .. sourcePoseName .. "\" was not registered")
      break
    end
    if not animationPoses[targetPoseName] then
      print("error: the specified target animation pose name \"" .. targetPoseName .. "\" was not registered")
      break
    end
    local conditions = {}
    local j = 0
    while true do
      local conditionBaseName = baseName .. string.format(".condition(%d)", j)
      local variableName = getXMLString(xmlFile, conditionBaseName .. "#variable")
      local comparisonType = getXMLString(xmlFile, conditionBaseName .. "#operator")
      local comparisonValue = getXMLFloat(xmlFile, conditionBaseName .. "#value")
      local flag = getXMLString(xmlFile, conditionBaseName .. "#flag")
      local notSet = getXMLBool(xmlFile, conditionBaseName .. "#notSet")
      if variableName == nil and flag == nil then
        break
      end
      local conditionFunction
      if variableName ~= nil then
        if variableName == "" or comparisonType == nil or comparisonType == "" or comparisonValue == nil then
          print("error: condition setup is wrong or missing")
          break
        end
        if variableName ~= "distance" and variableName ~= "angle" and variableName ~= "forwardSpeed" then
          print("error: unknown variable name used (" .. variableName .. ")")
        end
        if variableName == "angle" then
          comparisonValue = comparisonValue / 180 * math.pi
        end
        local functionString = ""
        functionString = functionString .. "local table = ...; "
        functionString = functionString .. "return table." .. variableName .. " and table." .. variableName .. " " .. comparisonType .. " " .. comparisonValue .. ";"
        local errorMessage
        conditionFunction, errorMessage = loadstring(functionString)
        if errorMessage then
          print("error: could not create condition function (" .. errorMessage .. ")")
        end
      elseif flag ~= nil then
        local functionString = ""
        functionString = functionString .. "local agentAnimationData = ...; "
        functionString = functionString .. string.format([[
 
                    return %s agentAnimationData.flagsHash[%s];
                ]], notSet and "not" or "", flag)
        local errorMessage
        conditionFunction, errorMessage = loadstring(functionString)
        if errorMessage then
          print("error: could not create condition function (" .. errorMessage .. ")")
        end
      end
      table.insert(conditions, conditionFunction)
      j = j + 1
    end
    local controllers = {}
    AnimationController.loadControllersFromXML(xmlFile, baseName, controllers)
    local updateControllersFunction = AnimationController.loadControllersUpdateFunction(controllers)
    addAnimationTransition(sourcePoseName, animationName, targetPoseName, beginTimeFactor, endTimeFactor, conditions, controllers, updateControllersFunction)
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("xml.animationBlendData.blendData(%d)", i)
    local sourceAnimationName = getXMLString(xmlFile, baseName .. "#sourceAnimation")
    local targetAnimationName = getXMLString(xmlFile, baseName .. "#targetAnimation")
    local stepSize = getXMLFloat(xmlFile, baseName .. "#stepSize")
    if sourceAnimationName == nil then
      break
    end
    if sourceAnimationName == "" or targetAnimationName == nil or targetAnimationName == "" or stepSize == nil then
      print("error: missing data for blend data")
      break
    end
    if animations[sourceAnimationName] and animations[targetAnimationName] then
      local steps = {}
      local j = 0
      while true do
        local conditionBaseName = baseName .. string.format(".step(%d)", j)
        local blendIndex = j + 1
        local sourceTime = getXMLFloat(xmlFile, conditionBaseName .. "#sourceTime")
        local targetTime = getXMLFloat(xmlFile, conditionBaseName .. "#targetTime")
        local blendTime = getXMLFloat(xmlFile, conditionBaseName .. "#blendTime")
        local quality = getXMLFloat(xmlFile, conditionBaseName .. "#quality")
        if sourceTime == nil then
          break
        end
        if targetTime == nil or blendTime == nil or quality == nil then
          print("error: blend step setup is wrong or missing")
          break
        end
        if blendIndex ~= AnimationControl.mapTimeToBlendIndex(sourceTime, stepSize) then
          print("error: blend index or source time is not correct for the given step size")
          break
        end
        local stepData = {
          sourceTime = sourceTime,
          targetTime = targetTime,
          blendTime = blendTime,
          quality = quality
        }
        table.insert(steps, stepData)
        j = j + 1
      end
      animationBlendData[sourceAnimationName] = animationBlendData[sourceAnimationName] or {}
      animationBlendData[sourceAnimationName][targetAnimationName] = {stepSize = stepSize, steps = steps}
    end
    i = i + 1
  end
  for animationPoseName, animationPoseData in pairs(animationPoses) do
    if not animationTransitions[animationPoseName] or not next(animationTransitions[animationPoseName].transitions) then
      print("error : animation pose " .. animationPoseName .. " has no animation that could follow")
    end
  end
  local animationPoseChangeToStateData = {}
  local animationPoseChangeToAnimationPoseData = {}
  for animationPoseName, animationPoseData in pairs(animationPoses) do
    animationPoseChangeToStateData[animationPoseName] = {}
    animationPoseChangeToAnimationPoseData[animationPoseName] = {}
    local nodesToVisitList = {}
    local nodesToVisitHash = {}
    local nodesVisitedList = {}
    local currentNodeName = animationPoseName
    local currentNodeData
    for nodeName, _ in pairs(animationPoses) do
      local nodeData = {
        name = nodeName,
        parent = nil,
        cost = nil,
        transitionToNode = nil
      }
      if currentNodeName ~= nodeName then
        table.insert(nodesToVisitList, nodeData)
        nodesToVisitHash[nodeName] = nodeData
      else
        nodeData.parent = nodeData
        nodeData.cost = 0
        table.insert(nodesVisitedList, nodeData)
        currentNodeData = nodeData
      end
    end
    local sortingFunctionTest = function(e1, e2)
      if not e1 then
        return false
      elseif not e2 then
        return false
      end
      if not e1.cost and not e2.cost then
        return tostring(e1) < tostring(e2)
      elseif not e1.cost then
        return true
      elseif not e2.cost then
        return false
      else
        return e1.cost > e2.cost
      end
    end
    local sortingFunction = function(e1, e2)
      if not e1 then
        return false
      elseif not e2 then
        return false
      end
      if not e1.cost and not e2.cost then
        return tostring(e1) < tostring(e2)
      elseif not e1.cost then
        return true
      elseif not e2.cost then
        return false
      else
        return e1.cost > e2.cost
      end
    end
    while true do
      local isSortingNeeded = false
      for _, transitionData in ipairs(animationTransitions[currentNodeName].transitions) do
        local targetNodeName = transitionData.targetPoseName
        local targetNodeData = nodesToVisitHash[targetNodeName]
        if targetNodeData then
          local formerCosts = targetNodeData.cost
          local newCosts = currentNodeData.cost + transitionData.time
          if not formerCosts or formerCosts > newCosts then
            targetNodeData.cost = newCosts
            targetNodeData.parent = currentNodeData
            targetNodeData.transitionToNode = transitionData
            isSortingNeeded = true
          end
        end
      end
      if isSortingNeeded then
        table.sort(nodesToVisitList, sortingFunction)
      end
      currentNodeData = table.remove(nodesToVisitList)
      if currentNodeData then
        currentNodeName = currentNodeData.name
        nodesToVisitHash[currentNodeName] = nil
        table.insert(nodesVisitedList, currentNodeData)
        if not currentNodeData.parent then
          print("error : next node \"" .. currentNodeName .. "\" was not visited before, which means the used graph has independent parts, which is not allowed.")
        end
      else
        break
      end
    end
    local firstNode = nodesVisitedList[1]
    firstNode.path = {}
    for i = 2, table.getn(nodesVisitedList) do
      local currentNode = nodesVisitedList[i]
      local path = {}
      for _, transition in ipairs(currentNode.parent.path) do
        table.insert(path, transition)
      end
      table.insert(path, currentNode.transitionToNode)
      currentNode.path = path
    end
    local transitionData = animationTransitions[animationPoseName].transitionsToPose[animationPoseName]
    if transitionData then
      local bestTransition
      for _, transition in ipairs(transitionData.transitions) do
        if not bestTransition or transition.time < bestTransition.time then
          bestTransition = transition
        end
      end
      animationPoseChangeToAnimationPoseData[animationPoseName][animationPoseName] = {
        path = {bestTransition},
        cost = bestTransition.time
      }
    end
    for i = 2, table.getn(nodesVisitedList) do
      local currentNode = nodesVisitedList[i]
      animationPoseChangeToAnimationPoseData[animationPoseName][currentNode.name] = {
        path = currentNode.path,
        cost = currentNode.cost
      }
    end
    for targetAnimationPoseName, targetTransitionData in pairs(animationPoseChangeToAnimationPoseData[animationPoseName]) do
      local stateName = animationPoses[targetAnimationPoseName].stateName
      local currentStateTransitionData = animationPoseChangeToStateData[animationPoseName][stateName]
      if not currentStateTransitionData or targetTransitionData.cost < currentStateTransitionData.cost then
        currentStateTransitionData = currentStateTransitionData or {}
        currentStateTransitionData.path = targetTransitionData.path
        currentStateTransitionData.cost = targetTransitionData.cost
        animationPoseChangeToStateData[animationPoseName][stateName] = currentStateTransitionData
      end
    end
  end
  for animationPoseName, _ in pairs(animationPoses) do
    for targetAnimationPoseName, _ in pairs(animationPoses) do
      if not animationPoseChangeToAnimationPoseData[animationPoseName][targetAnimationPoseName] then
      end
    end
  end
  for animationPoseName, _ in pairs(animationPoses) do
    for stateName, _ in pairs(animationStates) do
      if not animationPoseChangeToStateData[animationPoseName][stateName] then
      end
    end
  end
  local aiStateToAnimationStateMapping = {}
  local i = 0
  while true do
    local baseName = string.format("xml.aiStateAnimationStateMappings.mapping(%d)", i)
    local aiStateName = getXMLString(xmlFile, baseName .. "#aiState")
    local animationStateName = getXMLString(xmlFile, baseName .. "#animationState")
    local defaultUrgency = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#urgency"), "1")
    local flagsToSetString = getXMLString(xmlFile, baseName .. "#flagsToSet")
    if aiStateName == nil then
      break
    end
    if aiStateName == "" or animationStateName == nil or animationStateName == "" then
      print("error: ai state mapping : you have to specifiy an ai state and an animation state")
      break
    end
    if aiStateToAnimationStateMapping[aiStateName] then
      print("error: ai state mapping : mapping for the ai state \"" .. aiStateName .. "\" was already specified")
      break
    end
    if not animationStates[animationStateName] then
      print("error: ai state mapping : the specified animation state \"" .. animationStateName .. "\" is unknown")
      break
    end
    if defaultUrgency ~= "1" and defaultUrgency ~= "2" and defaultUrgency ~= "3" and defaultUrgency ~= "4" then
      print("error: ai state mapping : the specified urgency \"" .. defaultUrgency .. "\" is unknown")
      break
    end
    local flagsToSet
    if flagsToSetString then
      flagsToSet = Utils.splitString(" ", flagsToSetString)
    else
      flagsToSet = {}
    end
    aiStateToAnimationStateMapping[aiStateName] = {
      animationStateName = animationStateName,
      urgency = defaultUrgency,
      flagsToSet = flagsToSet
    }
    i = i + 1
  end
  local animationStatesTemp = {}
  for animationStateName, _ in pairs(animationStates) do
    animationStatesTemp[animationStateName] = true
  end
  for aiStateName, mappingData in pairs(aiStateToAnimationStateMapping) do
    animationStatesTemp[mappingData.animationStateName] = nil
  end
  for animationStateName, _ in pairs(animationStatesTemp) do
    print("error : ai state mapping : animation state \"" .. animationStateName .. "\" was not mapped to an ai state")
  end
  clipEventData = AnimationEventManager.loadClipEventData(xmlFile, animations)
  delete(xmlFile)
  AnimationControl.animations = animations
  AnimationControl.animationPoses = animationPoses
  AnimationControl.animationTransitions = animationTransitions
  AnimationControl.animationStates = animationStates
  AnimationControl.animationPoseChangeToStateData = animationPoseChangeToStateData
  AnimationControl.animationPoseChangeToAnimationPoseData = animationPoseChangeToAnimationPoseData
  AnimationControl.aiStateToAnimationStateMapping = aiStateToAnimationStateMapping
  AnimationControl.animationBlendData = animationBlendData
  AnimationControl.clipEventData = clipEventData
  AnimationControl.loaded = true
end
function AnimationControl.mapTimeToBlendIndex(currentTime, stepSize)
  return math.floor(currentTime / stepSize) + 1
end
function AnimationControl.mapBlendIndexToTime(currentBlendIndex, stepSize)
  return (currentBlendIndex - 1) * stepSize
end
function AnimationControl.initialize(animationId, animationDataFilename)
  AnimationControl:initializeAnimations(animationId, animationDataFilename)
end
function AnimationControl.dispose()
  AnimationControl.animations = nil
  AnimationControl.animationPoses = nil
  AnimationControl.animationTransitions = nil
  AnimationControl.animationStates = nil
  AnimationControl.animationPoseChangeToStateData = nil
  AnimationControl.animationPoseChangeToAnimationPoseData = nil
  AnimationControl.aiStateToAnimationStateMapping = nil
  AnimationControl.animationBlendData = nil
  AnimationControl.loaded = nil
end
function AnimationControl.prepare(agent, bonesId, meshId, animationId, translationMarkerId, initialAIStateName)
  agent.animationData = setmetatable({}, AnimalAnimationData_mt)
  local agentAnimationData = agent.animationData
  agentAnimationData.flagsHash = {}
  AnimationEventManager.prepareAgent(agent, agentAnimationData)
  agentAnimationData.bonesId = bonesId
  agentAnimationData.meshId = meshId
  agentAnimationData.animationId = animationId
  agentAnimationData.translationMarkerId = translationMarkerId
  agentAnimationData.characterSet = getAnimCharacterSet(agentAnimationData.animationId)
  for _, animation in pairs(AnimationControl.animations) do
    animation:prepare(agent, agentAnimationData)
  end
  agentAnimationData.freeTrackIds = {}
  for i = 1, AnimationControl.availableNumberOfTracks do
    agentAnimationData.freeTrackIds[i] = AnimationControl.availableNumberOfTracks - i
  end
  agentAnimationData.usedTrackIds = {}
  agentAnimationData.aiStateName = initialAIStateName
  if agent.herd.isVisible then
    AnimationControl.setInitialAgentData(agent, agentAnimationData)
  else
    setVisibility(agentAnimationData.meshId, false)
  end
  local radius = 1
  local height = 2
  local stepOffset = 0.6
  local slopeLimit = 45
  local skinWidth = 0.1
  local collisionMask = Player.movementCollisionMask
  local mass = 500
  agentAnimationData.cctIndex = createCCT(bonesId, radius, height, stepOffset, slopeLimit, skinWidth, collisionMask, mass)
end
function AnimationControl.setInitialAgentData(agent, agentAnimationData)
  AnimationControl.forcePositionUpdate(agent)
  agentAnimationData.distance = 0
  agentAnimationData.angle = 0
  agentAnimationData.forwardSpeed = 0
  local aiStateName = agentAnimationData.aiStateName
  local mappingData = AnimationControl.aiStateToAnimationStateMapping[aiStateName]
  local newAnimationStateName = mappingData and mappingData.animationStateName
  local newAnimationState = AnimationControl.animationStates[newAnimationStateName]
  if not newAnimationStateName or not newAnimationState then
    error("error : initial state for animal animation is unknown \"" .. tostring(aiStateName) .. "\"")
    return
  end
  local newAnimationPoseName, newAnimationPose = next(newAnimationState.animationPoses)
  local transitionData = AnimationControl.animationTransitions[newAnimationPoseName]
  if not transitionData then
    error("error : no transition found from state \"" .. tostring(aiStateName) .. "\" pose \"" .. tostring(newAnimationPoseName) .. "\"")
    return
  end
  local _, newAnimationTransition = transitionData.transitionsToPose[newAnimationPoseName] and next(transitionData.transitionsToPose[newAnimationPoseName].transitions)
  if not newAnimationTransition then
    _, newAnimationTransition = transitionData.transitionsToState[newAnimationStateName] and next(transitionData.transitionsToState[newAnimationStateName].transitions)
    if not newAnimationTransition then
      _, newAnimationTransition = next(transitionData.transitions)
      if not newAnimationTransition then
        error("error : no transition available at state \"" .. tostring(aiStateName) .. "\" pose \"" .. tostring(newAnimationPoseName) .. "\"")
        return
      end
    end
  end
  if table.getn(agentAnimationData.freeTrackIds) ~= AnimationControl.availableNumberOfTracks then
    print("error: there are still tracks in use (1)")
  end
  if next(agentAnimationData.usedTrackIds) then
    print("error: there are still tracks in use (2)")
  end
  agentAnimationData.targetAnimationState = AnimationControl.animationStates[newAnimationTransition.targetPose.stateName]
  BlendTree.initialize(agent, agentAnimationData, newAnimationTransition, 0)
end
function AnimationControl.forcePositionUpdate(agent)
  local agentAnimationData = agent.animationData
  agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ = agent.positionX, agent.positionY, agent.positionZ
  agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ = agent.directionX, agent.directionY, agent.directionZ
  setTranslation(agentAnimationData.bonesId, agent.positionX, agent.positionY, agent.positionZ)
  setDirection(agentAnimationData.bonesId, agent.directionX, agent.directionY, agent.directionZ, 0, 1, 0)
end
function AnimationControl.stateChanged(agent, aiStateName, urgencyLevel)
  local agentAnimationData = agent.animationData
  aiStateName = aiStateName or agent.stateData.currentState.name
  local mappingData = AnimationControl.aiStateToAnimationStateMapping[aiStateName]
  local newAnimationStateName = mappingData and mappingData.animationStateName
  if not newAnimationStateName or not AnimationControl.animationStates[newAnimationStateName] then
    print("error : changing state : unknown ai state name \"" .. tostring(aiStateName) .. "\", ignoring state change")
    return
  end
  agentAnimationData.aiStateName = aiStateName
  if not agent.herd.isVisible then
    return
  end
  local newAnimationState = AnimationControl.animationStates[newAnimationStateName]
  newAnimationState:setFlags(agent, agentAnimationData, mappingData.flagsToSet)
  if agentAnimationData.targetAnimationState.name == newAnimationStateName then
    return
  end
  agentAnimationData.targetAnimationState = newAnimationState
  urgencyLevel = urgencyLevel or mappingData.urgency or "1"
  agentAnimationData.targetAnimationStateUrgency = urgencyLevel
  if not BlendTree.isStateChangeAllowed(agent, agentAnimationData, agentAnimationData.targetAnimationState) then
    return
  end
  AnimationControl._changeAnimationToReachState(agent, agentAnimationData)
end
function AnimationControl._changeAnimationToReachState(agent, agentAnimationData)
  local currentAnimationTransition = BlendTree.getDrivingAnimationTransition(agent, agentAnimationData)
  local urgencyLevel = agentAnimationData.targetAnimationStateUrgency
  if urgencyLevel == "1" then
    local path = AnimationControl.animationPoseChangeToStateData[currentAnimationTransition.targetPoseName][agentAnimationData.targetAnimationState.name].path
    local finalPose = path[table.getn(path)].targetPose
    local nextAnimationTransition = finalPose:getNextAnimationTransition(agent, agentAnimationData)
    local blendTime = AnimationControl.defaultBlendTime
    local animationStartTime = 0
    local addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, nextAnimationTransition, animationStartTime, blendTime)
    if not addingAnimationSucceeded then
      BlendTree.addAnimation(agent, agentAnimationData, nextAnimationTransition, animationStartTime, 0)
    end
  elseif urgencyLevel == "2" then
    local path = AnimationControl.animationPoseChangeToStateData[currentAnimationTransition.targetPoseName][agentAnimationData.targetAnimationState.name].path
    local animationTransitionsToPlay = {}
    local finalAnimationTransition = currentAnimationTransition
    for i, transitionInPath in ipairs(path) do
      if finalAnimationTransition.animation.name ~= transitionInPath.animation.name then
        table.insert(animationTransitionsToPlay, transitionInPath)
        finalAnimationTransition = transitionInPath
      else
      end
    end
    local lastTransitionInPath = path[table.getn(path)]
    local firstAnimationInTargetState = lastTransitionInPath.targetPose:getNextAnimationTransition(agent, agentAnimationData)
    if 0 < firstAnimationInTargetState.time and finalAnimationTransition.animation.name ~= firstAnimationInTargetState.animation.name then
      finalAnimationTransition = firstAnimationInTargetState
      table.insert(animationTransitionsToPlay, finalAnimationTransition)
    end
    local neededAnimationTracks = BlendTree.getNeededTrackCount(agent, agentAnimationData)
    for i = 1, table.getn(animationTransitionsToPlay) do
      neededAnimationTracks = neededAnimationTracks + animationTransitionsToPlay[i].animation:getNeededTrackCount()
    end
    if neededAnimationTracks > AnimationControl.availableNumberOfTracks then
      for i = table.getn(animationTransitionsToPlay) - 1, 1, -1 do
        local currentAnimation = table.remove(animationTransitionsToPlay, i).animation
        neededAnimationTracks = neededAnimationTracks - currentAnimation:getNeededTrackCount()
        if neededAnimationTracks <= AnimationControl.availableNumberOfTracks then
          break
        end
      end
    end
    local totalBlendTime = 0
    local lastAnimation = currentAnimationTransition.animation
    local lastAnimationTime = 0
    for i = 1, table.getn(animationTransitionsToPlay) do
      local currentAnimationTransition = animationTransitionsToPlay[i]
      local currentAnimation = currentAnimationTransition.animation
      local blendTime, animationStartTime
      local blendData = AnimationControl.animationBlendData[lastAnimation.name] and AnimationControl.animationBlendData[lastAnimation.name][currentAnimation.name]
      if blendData then
        local currentBlendStep = blendData.steps[AnimationControl.mapTimeToBlendIndex(lastAnimationTime, blendData.stepSize)]
        blendTime = currentBlendStep.blendTime
        animationStartTime = currentBlendStep.targetTime
      else
        blendTime = AnimationControl.defaultBlendTime
        animationStartTime = 0
      end
      totalBlendTime = totalBlendTime + blendTime
      local addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, currentAnimationTransition, animationStartTime, totalBlendTime)
      if not addingAnimationSucceeded then
        local minTrackCountInBlendTree = BlendTree.getLastAnimation(agent, agentAnimationData):getNeededTrackCount()
        local trackCountByAnimation = currentAnimation:getNeededTrackCount()
        if minTrackCountInBlendTree + trackCountByAnimation > AnimationControl.availableNumberOfTracks then
          local finalAnimation = animationTransitionsToPlay[table.getn(animationTransitionsToPlay)]
          addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, finalAnimation, animationStartTime, 0)
        else
          while not addingAnimationSucceeded do
            BlendTree.stopFirstAnimation(agent, agentAnimationData)
            addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, animationTransitionsToPlay[i], animationStartTime, totalBlendTime)
          end
        end
      end
      lastAnimation = currentAnimation
      lastAnimationTime = animationStartTime
    end
  else
    if urgencyLevel == "3" then
      local path = AnimationControl.animationPoseChangeToStateData[currentAnimationTransition.targetPoseName][agentAnimationData.targetAnimationState.name].path
      local animationTransitionsToPlay = {}
      local finalAnimationTransition = currentAnimationTransition
      for i, transitionInPath in ipairs(path) do
        if finalAnimationTransition.animation.name ~= transitionInPath.animation.name then
          table.insert(animationTransitionsToPlay, transitionInPath)
          finalAnimationTransition = transitionInPath
        else
        end
      end
      local neededAnimationTracks = BlendTree.getNeededTrackCount(agent, agentAnimationData)
      for i = 1, table.getn(animationTransitionsToPlay) do
        neededAnimationTracks = neededAnimationTracks + animationTransitionsToPlay[i].animation:getNeededTrackCount()
      end
      if neededAnimationTracks > AnimationControl.availableNumberOfTracks then
        for i = table.getn(animationTransitionsToPlay) - 1, 1, -1 do
          local currentAnimation = table.remove(animationTransitionsToPlay, i).animation
          neededAnimationTracks = neededAnimationTracks - currentAnimation:getNeededTrackCount()
          if neededAnimationTracks <= AnimationControl.availableNumberOfTracks then
            break
          end
        end
      end
      local totalBlendTime = 0
      local lastAnimation = currentAnimationTransition.animation
      local lastAnimationTime = 0
      for i = 1, table.getn(animationTransitionsToPlay) do
        local currentAnimationTransition = animationTransitionsToPlay[i]
        local currentAnimation = currentAnimationTransition.animation
        local blendTime, animationStartTime
        local blendData = AnimationControl.animationBlendData[lastAnimation.name] and AnimationControl.animationBlendData[lastAnimation.name][currentAnimation.name]
        if blendData then
          local currentBlendStep = blendData.steps[AnimationControl.mapTimeToBlendIndex(lastAnimationTime, blendData.stepSize)]
          blendTime = currentBlendStep.blendTime
          animationStartTime = currentBlendStep.targetTime
        else
          blendTime = AnimationControl.defaultBlendTime
          animationStartTime = 0
        end
        totalBlendTime = totalBlendTime + blendTime
        local addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, currentAnimationTransition, animationStartTime, totalBlendTime)
        if not addingAnimationSucceeded then
          local minTrackCountInBlendTree = BlendTree.getLastAnimation(agent, agentAnimationData):getNeededTrackCount()
          local trackCountByAnimation = currentAnimation:getNeededTrackCount()
          if minTrackCountInBlendTree + trackCountByAnimation > AnimationControl.availableNumberOfTracks then
            local finalAnimation = animationTransitionsToPlay[table.getn(animationTransitionsToPlay)]
            addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, finalAnimation, animationStartTime, 0)
          else
            while not addingAnimationSucceeded do
              BlendTree.stopFirstAnimation(agent, agentAnimationData)
              addingAnimationSucceeded = BlendTree.addAnimation(agent, agentAnimationData, animationTransitionsToPlay[i], animationStartTime, totalBlendTime)
            end
          end
        end
        lastAnimation = currentAnimation
        lastAnimationTime = animationStartTime
      end
    else
    end
  end
  BlendTree.updateTree(agent, agentAnimationData, 0)
end
function AnimationControl.outsideUpdate(herd, dt)
  for _, animal in ipairs(herd.visibleAnimals) do
    AnimationControl.updateAnimation(animal, dt)
  end
end
function AnimationControl.updateAnimation(agent, dt)
  local agentAnimationData = agent.animationData
  agentAnimationData.animationPositionY = agent.positionY
  BlendTree.update(agent, agentAnimationData, dt)
end
function AnimationControl.printTrackData(agent, agentAnimationData)
  print(string.format("AnimationControl.printTrackData"))
  local clipHash = {}
  for animationName, animationData in pairs(AnimationControl.animations) do
    clipHash[animationData.clipId] = animationData
  end
  for i = 0, AnimationControl.availableNumberOfTracks - 1 do
    local enabled = isAnimTrackEnabled(agentAnimationData.characterSet, i)
    local clipId
    if enabled then
      clipId = getAnimTrackAssignedClip(agentAnimationData.characterSet, i)
    end
    print(string.format("   track %d - %s", i, clipId and string.format("animation : %s  clip : %s  (the animation name can differ if two animations use the same clip)", clipHash[clipId].name, clipHash[clipId].clipName) or "not assigned"))
  end
end
function AnimationControl.printPositionData(agent, agentAnimationData)
  agentAnimationData.lastPositionX, agentAnimationData.lastPositionY, agentAnimationData.lastPositionZ = agentAnimationData.lastPositionX or agentAnimationData.animationPositionX, agentAnimationData.lastPositionY or agentAnimationData.animationPositionY, agentAnimationData.lastPositionZ or agentAnimationData.animationPositionZ
  agentAnimationData.lastDirectionX, agentAnimationData.lastDirectionY, agentAnimationData.lastDirectionZ = agentAnimationData.lastDirectionX or agentAnimationData.animationDirectionX, agentAnimationData.lastDirectionY or agentAnimationData.animationDirectionY, agentAnimationData.lastDirectionZ or agentAnimationData.animationDirectionZ
  local positionChangeX, positionChangeY, positionChangeZ = agentAnimationData.animationPositionX - agentAnimationData.lastPositionX, agentAnimationData.animationPositionY - agentAnimationData.lastPositionY, agentAnimationData.animationPositionZ - agentAnimationData.lastPositionZ
  local directionChangeX, directionChangeY, directionChangeZ = agentAnimationData.animationDirectionX - agentAnimationData.lastDirectionX, agentAnimationData.animationDirectionY - agentAnimationData.lastDirectionY, agentAnimationData.animationDirectionZ - agentAnimationData.lastDirectionZ
  local distance = Utils.vector3Length(positionChangeX, positionChangeY, positionChangeZ)
  local dot = Utils.dotProduct(agentAnimationData.lastDirectionX, agentAnimationData.lastDirectionY, agentAnimationData.lastDirectionZ, agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ)
  local angle = dot == 1 and 0 or math.acos(dot)
  if distance ~= 0 then
    print(string.format("--- last position     %.2f %.2f %.2f", agentAnimationData.lastPositionX, agentAnimationData.lastPositionY, agentAnimationData.lastPositionZ))
    print(string.format("--- current position  %.2f %.2f %.2f", agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ))
    print(string.format("+++ last direction    %.2f %.2f %.2f", agentAnimationData.lastDirectionX, agentAnimationData.lastDirectionY, agentAnimationData.lastDirectionZ))
    print(string.format("+++ current direction %.2f %.2f %.2f", agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ))
    print(string.format("--- position change   %.2f %.2f %.2f  distance %.15f", positionChangeX, positionChangeY, positionChangeZ, distance))
    print(string.format("+++ direction change  %.2f %.2f %.2f  angle %.6f", directionChangeX, directionChangeY, directionChangeZ, angle))
  end
  agentAnimationData.lastPositionX, agentAnimationData.lastPositionY, agentAnimationData.lastPositionZ = agentAnimationData.animationPositionX, agentAnimationData.animationPositionY, agentAnimationData.animationPositionZ
  agentAnimationData.lastDirectionX, agentAnimationData.lastDirectionY, agentAnimationData.lastDirectionZ = agentAnimationData.animationDirectionX, agentAnimationData.animationDirectionY, agentAnimationData.animationDirectionZ
end
function AnimationControl.stop(agent)
  local agentAnimationData = agent.animationData
  BlendTree.stop(agent, agentAnimationData)
  setVisibility(agentAnimationData.meshId, false)
  local errorHappened = false
  if table.getn(agentAnimationData.freeTrackIds) ~= AnimationControl.availableNumberOfTracks then
    errorHappened = true
    print("error: there are still tracks in use (1)")
  end
  if next(agentAnimationData.usedTrackIds) then
    errorHappened = true
    print("error: there are still tracks in use (2)")
  end
  if errorHappened then
    AnimationControl.printTrackData(agent, agentAnimationData)
  end
end
function AnimationControl.resume(agent)
  local agentAnimationData = agent.animationData
  AnimationControl.setInitialAgentData(agent, agentAnimationData)
  setVisibility(agentAnimationData.meshId, true)
end
function AnimationControl.releaseAgent(agent)
  local agentAnimationData = agent.animationData
  BlendTree.releaseAgent(agent, agentAnimationData)
  removeCCT(agentAnimationData.cctIndex)
  agent.animationData = nil
  delete(agent.animationId)
  delete(agent.bonesId)
  delete(agent.meshId)
  delete(agent.translationMarkerId)
end
