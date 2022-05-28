StateStop = {}
local StateStop_mt = Class(StateStop, StateStand)
StateRepository:addState(StateStop)
function StateStop:initialize()
  local name = "Stop"
  local changeStateActionsList = {
    ChangeStateAction:new():initialize(StateStartled, DefaultPreconditions.playerSlapped),
    ChangeStateAction:new():initialize(StateEscape, EntityPreconditionCollection:new("shouldEscapeFromPlayerWhileStopping", 2, EntityType.PLAYER, DefaultPreconditions.isFrightening, DefaultPreconditions.isNear)),
    ChangeStateAction:new():initialize(StateIdle, PreconditionCollection:new("hasStopped", 1, DefaultPreconditions.fiveSecondsPassed, DefaultPreconditions.isNotMoving))
  }
  StateStop:superClass().initialize(self, name, changeStateActionsList)
end
