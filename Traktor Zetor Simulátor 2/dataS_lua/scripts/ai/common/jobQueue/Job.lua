Job = {}
local Job_mt = Class(Job)
function Job:new()
  return self
end
function Job:doJob(...)
  error("has to get overwritten")
end
function Job:equals(...)
  error("has to get overwritten")
end
