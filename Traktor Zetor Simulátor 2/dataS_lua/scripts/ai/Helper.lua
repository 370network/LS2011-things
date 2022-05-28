Helper = {}
function Helper:convertListToHash(list, hashValue)
  assert(list)
  local hash = {}
  for i, v in ipairs(list) do
    if hashValue ~= nil then
      hash[v] = hashValue
    else
      hash[v] = i
    end
  end
  return hash
end
function Helper:checkListValidity(list)
  local number = 0
  local hasError = false
  for k, v in pairs(list) do
    number = number + 1
    if not list[number] then
      hasError = true
    end
  end
  if not hasError and number == #list then
    return true
  else
    return false
  end
end
function Helper:copyTableFlat(table)
  assert(table)
  local copy = {}
  for i, v in pairs(table) do
    copy[i] = v
  end
  return copy
end
function Helper:printTable(table, maxDepth, depth)
  maxDepth = maxDepth or 1
  depth = depth or 1
  if maxDepth < depth then
    return
  end
  local resultString = ""
  for i = 1, depth do
    resultString = resultString .. "-"
  end
  for key, value in pairs(table) do
    print(resultString .. " : " .. tostring(key) .. " -> " .. tostring(value))
    if type(value) == "table" then
      Helper:printTable(table, maxDepth, depth + 1)
    end
  end
end
