StateStandUp = {}
local StateStandUp_mt = Class(StateStandUp, State)
StateRepository:addState(StateStandUp)
function StateStandUp:initialize()
  local name = "StandUp"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateIdle, DefaultPreconditions.tenSecondsPassed)
  }
  StateStandUp:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateStandUp:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.THIRST]:changeValue(5.0E-4 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(-1.0E-4 * (dt / 1000))
end
