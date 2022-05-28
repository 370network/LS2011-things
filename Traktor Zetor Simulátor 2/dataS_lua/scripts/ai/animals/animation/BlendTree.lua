BlendTree = {}
function BlendTree.initialize(agent, agentAnimationData, initialAnimationTransition, ...)
  agentAnimationData.activeStates = {}
  agentAnimationData.activeAnimations = {}
  local initialAnimationInstance = initialAnimationTransition.animation:startDrivingAnimation(agent, agentAnimationData, ...)
  if not initialAnimationInstance then
    print("error BlendTree.initialize(): cannot instantiate initial animation")
  end
  AnimationEventManager.startListeningForEvents(agent, agentAnimationData, initialAnimationInstance)
  local BlendLeaf = BlendLeaf:new(agent, agentAnimationData, initialAnimationInstance)
  agentAnimationData.blendTree = {
    rootNode = BlendLeaf,
    drivingAnimationTransition = initialAnimationTransition,
    drivingAnimationInstance = initialAnimationInstance,
    drivingAnimationState = initialAnimationInstance.animation.state
  }
  initialAnimationInstance.animation.state:onEnterByDrivingAnimation(agent, agentAnimationData)
  for _, controller in ipairs(agentAnimationData.blendTree.drivingAnimationTransition.controllers) do
    controller:onStart(agent, agentAnimationData, initialAnimationInstance)
  end
  return initialAnimationInstance
end
function BlendTree.getDrivingAnimationTransition(agent, agentAnimationData)
  return agentAnimationData.blendTree.drivingAnimationTransition
end
function BlendTree.getDrivingAnimationInstance(agent, agentAnimationData)
  return agentAnimationData.blendTree.drivingAnimationInstance
end
function BlendTree.animationStarted(agent, agentAnimationData, animation)
  local activeStateCount = agentAnimationData.activeStates[animation.state]
  if not activeStateCount then
    animation.state:onEnter(agent, agentAnimationData)
    agentAnimationData.activeStates[animation.state] = 1
  else
    agentAnimationData.activeStates[animation.state] = activeStateCount + 1
  end
end
function BlendTree.animationStopped(agent, agentAnimationData, animation)
  local activeStateCount = agentAnimationData.activeStates[animation.state]
  if 1 < activeStateCount then
    agentAnimationData.activeStates[animation.state] = activeStateCount - 1
  else
    animation.state:onLeave(agent, agentAnimationData)
    agentAnimationData.activeStates[animation.state] = nil
  end
end
function BlendTree.isStateChangeAllowed(agent, agentAnimationData, targetState)
  local blendTreeData = agentAnimationData.blendTree
  for _, controller in ipairs(blendTreeData.drivingAnimationTransition.controllers) do
    if not controller:isStateChangeAllowed(agent, agentAnimationData, blendTreeData.drivingAnimationInstance, targetState) then
      return false
    end
  end
  return true
end
function BlendTree.addAnimation(agent, agentAnimationData, animationTransition, animationStartTime, blendTime)
  local animation = animationTransition.animation
  local blendTreeData = agentAnimationData.blendTree
  local animationInstance
  if 0 < blendTime then
    animationInstance = animation:startDrivingAnimation(agent, agentAnimationData, animationStartTime)
    if not animationInstance then
      print("error BlendTree.addAnimation(): cannot instantiate animation")
      return false
    end
    AnimationEventManager.startListeningForEvents(agent, agentAnimationData, animationInstance)
    local BlendLeaf = BlendLeaf:new(agent, agentAnimationData, animationInstance)
    blendTreeData.drivingAnimationInstance:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
    blendTreeData.rootNode = BlendNode:new(blendTreeData.rootNode, BlendLeaf, blendTime)
  else
    blendTreeData.drivingAnimationInstance:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
    blendTreeData.rootNode:completeStop(agent, agentAnimationData)
    animationInstance = animation:startDrivingAnimation(agent, agentAnimationData, animationStartTime)
    if not animationInstance then
      print("error BlendTree.addAnimation(): cannot instantiate animation")
      return false
    end
    AnimationEventManager.startListeningForEvents(agent, agentAnimationData, animationInstance)
    local BlendLeaf = BlendLeaf:new(agent, agentAnimationData, animationInstance)
    blendTreeData.rootNode = BlendLeaf
  end
  for _, controller in ipairs(blendTreeData.drivingAnimationTransition.controllers) do
    controller:onStop(agent, agentAnimationData, blendTreeData.drivingAnimationInstance)
  end
  blendTreeData.drivingAnimationInstance.animation.state:onLeaveByDrivingAnimation(agent, agentAnimationData)
  blendTreeData.drivingAnimationTransition = animationTransition
  blendTreeData.drivingAnimationInstance = animationInstance
  blendTreeData.drivingAnimationState = animationInstance.animation.state
  blendTreeData.drivingAnimationInstance.animation.state:onEnterByDrivingAnimation(agent, agentAnimationData)
  for _, controller in ipairs(blendTreeData.drivingAnimationTransition.controllers) do
    controller:onStart(agent, agentAnimationData, blendTreeData.drivingAnimationInstance)
  end
  return true
end
function BlendTree.stopFirstAnimation(agent, agentAnimationData)
  local newRootNode = agentAnimationData.blendTree.rootNode:stopFirstAnimation(agent, agentAnimationData)
  if newRootNode then
    agentAnimationData.blendTree.rootNode = newRootNode
  else
    print("error BlendTree.stopFirstAnimation(): cannot stop last remaining animation in blend tree")
  end
end
function BlendTree.stopLastAnimation(agent, agentAnimationData)
  local newRootNode = agentAnimationData.blendTree.rootNode:stopLastAnimation(agent, agentAnimationData)
  if newRootNode then
    agentAnimationData.blendTree.rootNode = newRootNode
  else
    print("error BlendTree.stopLastAnimation(): cannot stop last remaining animation in blend tree")
  end
end
function BlendTree.update(agent, agentAnimationData, dt)
  local blendTreeData = agentAnimationData.blendTree
  local replaceDrivingAnimation = false
  for state, _ in pairs(agentAnimationData.activeStates) do
    local quitAnimation = state:update(agent, agentAnimationData, dt)
    replaceDrivingAnimation = replaceDrivingAnimation or quitAnimation
  end
  local quitAnimation = blendTreeData.drivingAnimationTransition:updateControllersFunction(agent, agentAnimationData, dt, blendTreeData.drivingAnimationInstance)
  replaceDrivingAnimation = replaceDrivingAnimation or quitAnimation
  AnimationEventManager.checkForEvent(agent, agentAnimationData)
  local quitAnimation = blendTreeData.drivingAnimationInstance:updateDrivingAnimation(agent, agentAnimationData, dt)
  replaceDrivingAnimation = replaceDrivingAnimation or quitAnimation
  if replaceDrivingAnimation then
    BlendTree.replaceDrivingAnimation(agent, agentAnimationData)
  end
  return BlendTree.updateTree(agent, agentAnimationData, dt)
end
function BlendTree.updateTree(agent, agentAnimationData, dt)
  local animationFinished, newRootNode = agentAnimationData.blendTree.rootNode:update(agent, agentAnimationData, 1, dt)
  if newRootNode then
    agentAnimationData.blendTree.rootNode = newRootNode
  end
  if animationFinished then
    return true
  end
  return false
end
function BlendTree.printTree(agent, agentAnimationData)
  print("BlendTree.printTree")
  local currentElement = agentAnimationData.blendTree.rootNode
  while currentElement do
    if currentElement:class() == BlendNode then
      print(string.format("   BlendNode : from %s to %s", currentElement.firstElementToBlend.name, currentElement.secondElementToBlend.name))
      currentElement = currentElement.firstElementToBlend
    else
      print("   Animation : " .. currentElement.animationInstance.animation.name)
      currentElement = nil
    end
  end
end
function BlendTree.getCurrentAnimationInstance(agent, agentAnimationData)
  return agentAnimationData.blendTree.rootNode:getCurrentAnimationInstance()
end
function BlendTree.getNeededTrackCount(agent, agentAnimationData)
  return agentAnimationData.blendTree.rootNode:getNeededTrackCount()
end
function BlendTree.getAnimationCount(agent, agentAnimationData)
  return agentAnimationData.blendTree.rootNode:getAnimationCount()
end
function BlendTree.getFirstAnimation(agent, agentAnimationData)
  return agentAnimationData.blendTree.rootNode:getFirstAnimation(agent, agentAnimationData)
end
function BlendTree.getLastAnimation(agent, agentAnimationData)
  return agentAnimationData.blendTree.rootNode:getLastAnimation(agent, agentAnimationData)
end
function BlendTree.replaceDrivingAnimation(agent, agentAnimationData)
  local blendTreeData = agentAnimationData.blendTree
  local drivingAnimationTransition = blendTreeData.drivingAnimationTransition
  local drivingAnimationPose = drivingAnimationTransition.targetPose
  local drivingAnimationInstance = blendTreeData.drivingAnimationInstance
  if agentAnimationData.targetAnimationState.name ~= drivingAnimationPose.stateName and drivingAnimationPose.name == "walkIdlePose" and agent.speed < 0.05 then
    local nextAnimationTransition = drivingAnimationPose:getNextAnimationTransition(agent, agentAnimationData)
    if nextAnimationTransition.animation.name == "idleShort" then
      AnimationControl._changeAnimationToReachState(agent, agentAnimationData)
      return
    end
  end
  local clipTime = drivingAnimationInstance:stopDrivingAnimation(agent, agentAnimationData)
  for _, controller in ipairs(drivingAnimationTransition.controllers) do
    controller:onStop(agent, agentAnimationData, drivingAnimationInstance)
  end
  local tableToUseForInstance = drivingAnimationInstance
  for key, _ in pairs(tableToUseForInstance) do
    tableToUseForInstance[key] = nil
  end
  local nextAnimationTransition = drivingAnimationPose:getNextAnimationTransition(agent, agentAnimationData)
  local nextAnimationStartTime = nextAnimationTransition.beginTime + clipTime
  local nextAnimationInstance = nextAnimationTransition.animation:startDrivingAnimation(agent, agentAnimationData, nextAnimationStartTime, tableToUseForInstance)
  if not nextAnimationInstance then
    if blendTreeData.rootNode:class() == BlendNode then
      if blendTreeData.rootNode.firstElementToBlend:class() == BlendNode then
        blendTreeData.rootNode.firstElementToBlend:completeStop(agent, agentAnimationData)
      else
        blendTreeData.rootNode.firstElementToBlend:stop(agent, agentAnimationData)
      end
    end
    nextAnimationInstance = nextAnimationTransition.animation:startDrivingAnimation(agent, agentAnimationData, nextAnimationStartTime, tableToUseForInstance)
    if not nextAnimationInstance then
      print("Error: Something prevented the new animation from starting (eg not enough free tracks")
    end
    local blendLeaf = BlendLeaf:new(agent, agentAnimationData, nextAnimationInstance)
    blendTreeData.rootNode = blendLeaf
  end
  blendTreeData.drivingAnimationInstance.animation.state:onLeaveByDrivingAnimation(agent, agentAnimationData)
  blendTreeData.drivingAnimationInstance = nextAnimationInstance
  blendTreeData.drivingAnimationTransition = nextAnimationTransition
  blendTreeData.drivingAnimationState = nextAnimationInstance.animation.state
  blendTreeData.drivingAnimationInstance.animation.state:onEnterByDrivingAnimation(agent, agentAnimationData)
  for _, controller in ipairs(blendTreeData.drivingAnimationTransition.controllers) do
    controller:onStart(agent, agentAnimationData, blendTreeData.drivingAnimationInstance)
  end
  AnimationEventManager.startListeningForEvents(agent, agentAnimationData, nextAnimationInstance)
  return true
end
function BlendTree.stop(agent, agentAnimationData)
  local blendTreeData = agentAnimationData.blendTree
  blendTreeData.drivingAnimationInstance:handleNotDrivingAnimationAnymore(agent, agentAnimationData)
  blendTreeData.drivingAnimationInstance.animation.state:onLeaveByDrivingAnimation(agent, agentAnimationData)
  blendTreeData.rootNode:completeStop(agent, agentAnimationData)
end
function BlendTree.releaseAgent(agent, agentAnimationData)
  if agentAnimationData.activeStates then
    for state, _ in pairs(agentAnimationData.activeStates) do
      state:onLeave(agent, agentAnimationData)
      agentAnimationData.activeStates[state] = nil
    end
  end
end
