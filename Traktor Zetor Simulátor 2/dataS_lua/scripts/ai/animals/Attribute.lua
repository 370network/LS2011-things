AnimalAttributeData = {
  HUNGER = "food saturation",
  THIRST = "water saturation",
  ENERGY = "energy",
  MILK = "milk"
}
local AnimalAttributeData_mt = Class(AnimalAttributeData)
function AnimalAttributeData:new(presets_hash)
  presets_hash = presets_hash or {}
  assert(presets_hash.animal, "You didn't specify the animal object")
  local self = {}
  setmetatable(self, AnimalAttributeData_mt)
  local function loadAttribute(attributeName, initialValue)
    self[attributeName] = Attribute:new({
      animal = presets_hash.animal,
      name = attributeName,
      initialValue = initialValue
    })
  end
  loadAttribute(AnimalAttributeData.HUNGER, hunger or math.random() * math.random())
  loadAttribute(AnimalAttributeData.THIRST, thirst or math.random() * math.random())
  loadAttribute(AnimalAttributeData.ENERGY, energy or 1 - math.random() * math.random())
  loadAttribute(AnimalAttributeData.MILK, milk or math.random() * math.random())
  return self
end
DefaultAttributeValues = {
  ANY = 0,
  TINY = 0.1,
  A_BIT = 0.2,
  SLIGHTLY = 0.3,
  MODERATE = 0.5,
  MUCH = 0.7,
  A_LOT = 0.9,
  COMPLETELY = 1
}
Attribute = {}
local Attribute_mt = Class(Attribute)
function Attribute:new(presets_hash)
  presets_hash = presets_hash or {}
  assert(presets_hash.animal, "You didn't specify the animal object")
  assert(presets_hash.name, "You didn't specify a name for this attribute")
  if self == Attribute then
    self = {}
    setmetatable(self, Attribute_mt)
  end
  self.animal = presets_hash.animal
  self.name = presets_hash.name
  self.value = presets_hash.initialValue or 0.5
  self.minimum = presets_hash.minimum or 0
  self.maximum = presets_hash.maximum or 1
  return self
end
function Attribute:changeValue(change)
  self.value = math.max(self.minimum, math.min(self.maximum, self.value + change))
end
function Attribute:multiplyValue(multiplier)
  self.value = math.max(self.minimum, math.min(self.maximum, self.value * multiplier))
end
AttributeCallback = {}
local AttributeCallback_mt = Class(AttributeCallback)
function AttributeCallback:new(presets_hash)
  presets_hash = presets_hash or {}
  assert(presets_hash.attributeName, "You didn't specify a name to monitor")
  assert(presets_hash.callbackFunction, "You didn't specify the callback function")
  assert(presets_hash.callbackObject, "You didn't specify the callback object")
  if self == AttributeCallback then
    self = {}
    setmetatable(self, AttributeCallback_mt)
  end
  self.attribute = presets_hash.attribute
  self.callbackFunction = presets_hash.callbackFunction
  self.callbackObject = presets_hash.callbackObject
  if presets_hash.triggerFunction then
    self.triggerFunction = presets_hash.triggerFunction
  elseif presets_hash.triggerValue and presets_hash.triggerType then
    local value = "test"
    functionString = "local value = ...; return value " .. presets_hash.triggerType .. " " .. presets_hash.triggerValue .. ";"
    local triggerFunction, errorMessage = loadstring(functionString)
    if not triggerFunction then
      error("Error while creating the trigger function: " .. errorMessage .. ", please check the specified \"triggerType\" and \"triggerValue\"")
    end
    self.triggerFunction = triggerFunction
  else
    error("You didn't specify a trigger function or value and type")
  end
  return self
end
function AttributeCallback:checkAttribute(attributesHash)
  if self.triggerFunction(attributesHash[self.attributeName].value) then
    callbackObject:callbackFunction()
  end
end
DefaultAttributeCallbacks = {}
function DefaultAttributeCallbacks:onHunger(callbackObject, callbackFunction)
  return AttributeCallback:new({
    attributeName = AnimalAttributeData.HUNGER,
    callbackFunction = callbackFunction,
    callbackObject = callbackObject,
    triggerValue = 0.5,
    triggerType = ">"
  })
end
