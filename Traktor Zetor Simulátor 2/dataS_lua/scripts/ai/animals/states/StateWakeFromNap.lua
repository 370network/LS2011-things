StateWakeFromNap = {}
Class(StateWakeFromNap, State)
StateRepository:addState(StateWakeFromNap)
function StateWakeFromNap:initialize()
  local name = "WakeFromNap"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToStandUpToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateRest, DefaultPreconditions.threeSecondsPassed)
  }
  StateWakeFromNap:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
