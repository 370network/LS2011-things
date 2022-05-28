State = {}
Class(State, StateNode)
StateRepository = {
  idToState = {},
  stateId = 0,
  states = {}
}
local StateRepository_mt = Class(StateRepository)
function StateRepository:addState(newState)
  self.states[newState] = true
  assert(StateRepository.stateId < 32)
  newState.id = StateRepository.stateId
  StateRepository.idToState[StateRepository.stateId] = newState
  StateRepository.stateId = StateRepository.stateId + 1
end
function StateRepository:initializeStates()
  for state, _ in pairs(self.states) do
    state:initialize()
  end
end
function State:initialize(name, changeStateActionsList, speedLimitToUse, accelerationLimitToUse)
  stateTransitionCounter = stateTransitionCounter or 0
  for _, changeStateAction in ipairs(changeStateActionsList) do
    if changeStateAction.precondition.name ~= "playerSlappedInjected" and changeStateAction.precondition.name ~= "arrivedAtMilkingPlace" and changeStateAction.precondition.name ~= "readyToStopAtFeedingPlace" and changeStateAction.precondition.name ~= "readyToStopAtWateringPlace" and changeStateAction.precondition.name ~= "stoppedAtFeedingPlace" and changeStateAction.precondition.name ~= "stoppedAtWateringPlace" then
      changeStateAction.precondition = CheckIfNewStateIsAccessiblePrecondition:new(changeStateAction.targetState, "navmeshCheckHack" .. tostring(stateTransitionCounter), changeStateAction.precondition)
      stateTransitionCounter = stateTransitionCounter + 1
    end
  end
  State:superClass().initialize(self, name, changeStateActionsList)
  self.speedLimitToUse = speedLimitToUse
  self.accelerationLimitToUse = accelerationLimitToUse
end
function State:onEnter(agent)
  State:superClass().onEnter(self, agent)
  agent.stateData.currentState = self
  agent.stateData.currentNavMeshId = agent.herd.navMeshByStateHash[self]
  agent.stateData.timeEntered = AnimalHusbandry.time
  agent.stateData.target = agent.stateData.nextStateTarget
  agent.stateData.nextStateTarget = nil
  MotionControl:forceFullPositionUpdate(agent)
  agent.stateData.speedLimit = agent[self.speedLimitToUse]
  agent.stateData.accelerationLimit = agent[self.accelerationLimitToUse]
  if AnimalHusbandry.useAnimalVisualization then
    AnimationControl.stateChanged(agent)
  end
end
function State:onLeave(agent)
  State:superClass().onLeave(self, agent)
  agent.stateData.currentState = nil
  AnimalSteeringData.reset(agent)
  Perception:reset(agent)
end
function State:update(agent, dt)
  State.updateAgentAttributeData(self, agent, dt)
  self:updateAgentAttributeData(agent, dt)
end
function State:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.MILK]:changeValue(1.0E-4 * (dt / 1000))
end
