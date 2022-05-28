StateRest = {}
local StateRest_mt = Class(StateRest, State)
StateRepository:addState(StateRest)
function StateRest:initialize()
  local name = "Rest"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToStandUpToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StatePrepareToSleep, PreconditionCollection:new("gotoSleepBecauseItsNight", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isNight)),
    ChangeStateAction:new():initialize(StateStandUp, PreconditionCollection:new("standUpBecauseVeryHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryHungry)),
    ChangeStateAction:new():initialize(StateStandUp, PreconditionCollection:new("standUpBecauseVeryThirsty", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryThirsty)),
    ChangeStateAction:new():initialize(StatePrepareToTakeANap, PreconditionCollection:new("takeANapBecauseVeryExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isVeryExhausted)),
    ChangeStateAction:new():initialize(StateStandUp, PreconditionCollection:new("standUpBecauseHungry", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isHungry)),
    ChangeStateAction:new():initialize(StatePrepareToTakeANap, PreconditionCollection:new("takeANapBecauseExhausted", 1, DefaultPreconditions.isStateChangePracticable, DefaultPreconditions.isExhausted))
  }
  StateRest:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
function StateRest:updateAgentAttributeData(agent, dt)
  local attributes_hash = agent.attributes
  attributes_hash[AnimalAttributeData.HUNGER]:changeValue(0.001 * (dt / 1000))
  attributes_hash[AnimalAttributeData.ENERGY]:changeValue(0.001 * (dt / 1000))
end
