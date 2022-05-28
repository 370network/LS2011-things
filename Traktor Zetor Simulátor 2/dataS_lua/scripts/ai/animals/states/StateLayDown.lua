StateLayDown = {}
local StateLayDown_mt = Class(StateLayDown, State)
StateRepository:addState(StateLayDown)
function StateLayDown:initialize()
  local name = "LayDown"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateRest, DefaultPreconditions.tenSecondsPassed)
  }
  StateLayDown:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateLayDown:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-1.0E-4 * (dt / 1000))
end
