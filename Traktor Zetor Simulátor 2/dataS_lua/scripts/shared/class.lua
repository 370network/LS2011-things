function Class(members, baseClass)
  members = members or {}
  local mt = {__metatable = members, __index = members}
  if baseClass ~= nil then
    setmetatable(members, {__index = baseClass})
  end
  local function new(_, init)
    return setmetatable(init or {}, mt)
  end
  local copy = function(obj, ...)
    local newobj = obj:new(unpack(arg))
    for n, v in pairs(obj) do
      newobj[n] = v
    end
    return newobj
  end
  function members:class()
    return members
  end
  function members:superClass()
    return baseClass
  end
  function members:isa(other)
    local ret = false
    local curClass = members
    while curClass ~= nil and ret == false do
      if curClass == other then
        ret = true
      else
        curClass = curClass:superClass()
      end
    end
    return ret
  end
  members.new = members.new or new
  members.copy = members.copy or copy
  return mt
end
