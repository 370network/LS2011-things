AgentManager = {}
local AgentManager_mt = Class(AgentManager)
function AgentManager:new()
  local instance = setmetatable({}, AgentManager_mt)
  instance.agents = {}
  instance.navMeshes = {}
  instance.worldState = WorldState:new()
  return instance
end
function AgentManager:delete()
end
function AgentManager:addAgent(agentToAdd)
  table.insert(self.agents, agentToAdd)
end
function AgentManager:removeAgent(agentToRemove)
  for i, agent in ipairs(self.agents) do
    if agent == agentToRemove then
      table.remove(self.agents, i)
      break
    end
  end
end
function AgentManager:addNavMesh(navMesh)
  table.insert(self.navMeshes, navMesh)
end
function AgentManager:update(dt)
  for _, agent in ipairs(self.agents) do
    agent:update(dt)
  end
end
function AgentManager:draw()
  for _, agent in ipairs(self.agents) do
    agent:draw()
  end
end
