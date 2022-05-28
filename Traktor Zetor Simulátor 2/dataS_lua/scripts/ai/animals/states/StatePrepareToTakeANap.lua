StatePrepareToTakeANap = {}
Class(StatePrepareToTakeANap, State)
StateRepository:addState(StatePrepareToTakeANap)
function StatePrepareToTakeANap:initialize()
  local name = "PrepareToTakeANap"
  local changeStateActionsList = {
    DefaultChangeStateActions.startToStandUpToEscapeFromPlayer,
    ChangeStateAction:new():initialize(StateTakeANap, DefaultPreconditions.threeSecondsPassed)
  }
  StatePrepareToTakeANap:superClass().initialize(self, name, changeStateActionsList, AnimalMotionData.SPEED_STAND, AnimalMotionData.ACCELERATION_STAND)
end
