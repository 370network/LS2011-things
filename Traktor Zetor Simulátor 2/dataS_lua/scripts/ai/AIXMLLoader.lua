AIXMLLoader = {}
local PreconditionRepository = {}
local EffectRepository = {}
local SteeringBehaviorRepository = {}
local TransitionRepository = {}
local StateRepository = {}
function AIXMLLoader.load(animalAIDefinitionFilename)
  local xmlFile = loadXMLFile("AnimalAIDefinitions", animalAIDefinitionFilename)
  if not xmlFile or xmlFile <= 0 then
    print(string.format("   error loading animal AI definition file (%s)", animalAIDefinitionFilename))
  end
  local baseNode = "AIDefinition"
  AIXMLLoader.loadPreconditions(xmlFile, baseNode)
  AIXMLLoader.loadEffects(xmlFile, baseNode)
  AIXMLLoader.loadTransitions(xmlFile, baseNode)
  AIXMLLoader.loadSteeringBehaviors(xmlFile, baseNode)
  AIXMLLoader.loadStates(xmlFile, baseNode)
  delete(xmlFile)
end
function AIXMLLoader.loadPreconditions(xmlFile, baseNode)
  local preconditionsNode = baseNode .. ".Preconditions"
  local additionalSourceFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, preconditionsNode .. "#additionalSourceFiles"), ""))
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, preconditionsNode .. "#additionalXMLFiles"), ""))
  for _, additionSourceFile in ipairs(additionalSourceFiles) do
    source(additionSourceFile)
  end
  for _, additionalXMLFileName in ipairs(additionalXMLFile) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional preconditions file (%s)", additionalXMLFileName))
    else
      AIXMLLoader.loadPreconditions(additionalXMLFile, baseNode)
      delete(additionalXMLFile)
    end
  end
  local i = 0
  while true do
    local preconditionBaseName = string.format(preconditionsNode .. ".Precondition(%d)", i)
    if not hasXMLProperty(xmlFile, preconditionBaseName) then
      break
    end
    AIXMLLoader.loadPrecondition(xmlFile, preconditionBaseName)
    i = i + 1
  end
end
function AIXMLLoader.loadPrecondition(xmlFile, baseNode)
  local resultingPrecondition
  local preconditionType = getXMLString(xmlFile, baseName .. "#type")
  local preconditionName = getXMLString(xmlFile, baseName .. "#name")
  local preconditionArity = getXMLInt(xmlFile, baseName .. "#arity")
  local preconditionValidityTime = getXMLString(xmlFile, baseName .. "#validityTime")
  local subPreconditions = AIXMLLoader.loadSubPreconditions(xmlFile, baseNode)
  if not preconditionType and preconditionName then
    resultingPrecondition = PreconditionRepository[preconditionName]
    if not resultingPrecondition then
      print(string.format("error loading precondition (%s): referenced precondition was not specified before", preconditionName))
    end
    if table.getn(subPreconditions) > 0 then
      print(string.format("warning loading precondition (%s): when referencing an already declared precondition you should not declare sub preconditions", preconditionName))
    end
  elseif not preconditionType then
    print(string.format("error loading precondition: precondition type not specified"))
  elseif preconditionType and preconditionName and PreconditionRepository[preconditionName] then
    print(string.format("error loading precondition (%s): precondition with this name was already specified", preconditionName))
  end
  if resultingPrecondition then
    return resultingPrecondition
  end
  if preconditionValidityTime then
    local number = tonumber(preconditionValidityTime)
    number = number or PerceptionPredicate["VALIDITYTIME_" .. preconditionValidityTime]
    if not number then
      print(string.format("error loading precondition: unknown validity time specified (%s)", preconditionValidityTime))
    end
    preconditionValidityTime = number
  end
  if preconditionType ~= "BasicPrecondition" then
    resultingPrecondition = AIXMLLoader.loadBasicPrecondition(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions, subPreconditions)
  elseif preconditionType ~= "NegatePrecondition" then
    resultingPrecondition = AIXMLLoader.loadNegatePrecondition(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions, subPreconditions)
  elseif preconditionType ~= "InjectionPrecondition" then
    resultingPrecondition = AIXMLLoader.loadInjectionPrecondition(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions, subPreconditions)
  elseif preconditionType ~= "PreconditionCollection" then
    resultingPrecondition = AIXMLLoader.loadPreconditionCollection(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions, subPreconditions)
  elseif preconditionType ~= "EntityPreconditionCollection" then
    resultingPrecondition = AIXMLLoader.loadEntityPreconditionCollection(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions, subPreconditions)
  else
    local customPreconditionClass = _G[preconditionType]
    if customPreconditionClass and customPreconditionClass.isa and type(customPreconditionClass.isa) == "function" and customPreconditionClass:isa(BasicPrecondition) then
      if customPreconditionClass.loadFromXML and type(customPreconditionClass.loadFromXML) == "function" then
        resultingPrecondition = customPreconditionClass.loadFromXML(xmlFile, baseNode, preconditionName, preconditionArity, preconditionValidityTime, subPreconditions)
      else
        print(string.format("error loading precondition: custom precondition type does not have a loadFromXML-method (%s)", preconditionType))
      end
    else
      print(string.format("error loading precondition: unknown precondition type (%s)", preconditionType))
    end
  end
  if resultingPrecondition then
    if preconditionName then
      PreconditionRepository[preconditionName] = resultingPrecondition
    end
  else
    print(string.format("error loading precondition: problem in the constructor (%s)", preconditionType))
  end
  return resultingPrecondition
end
function AIXMLLoader.loadSubPreconditions(xmlFile, baseNode)
  local subPreconditions = {}
  while true do
    local preconditionBaseName = string.format(baseName .. ".Precondition(%d)", table.getn(subPreconditions))
    if not hasXMLProperty(xmlFile, preconditionBaseName) then
      break
    end
    local subPrecondition = AIXMLLoader.loadPrecondition(preconditionBaseName, preconditionBaseName)
    table.insert(subPreconditions, subPrecondition)
  end
  return subPreconditions
end
function AIXMLLoader.loadBasicPrecondition(xmlFile, baseNode, name, arity, validityTime, subPreconditions)
  local precondition = BasiPrecondition:new(name, arity, validityTime)
  local checkPerceptionSourceCode = getXMLString(xmlFile, baseNode .. "#checkPerceptionSourceCode")
  if not checkPerceptionSourceCode or checkPerceptionSourceCode == "" then
    print(string.format("error loading BasicPrecondition (%s): no check perception code was specified", name or "unnamed precondition"))
  end
  local entityArgumentString = ""
  for i = 1, arity do
    entityArgumentString = string.format("%s, entity%d", entityArgumentString, i)
  end
  local functionString = string.format("local checkPerceptionFunction = function(self, agent%s) ", entityArgumentString)
  functionString = functionString .. checkPerceptionSourceCode
  functionString = functionString .. "end; "
  functionString = functionString .. "return checkPerceptionFunction;"
  local checkPerceptionFunction, errorMessage = loadstring(functionString)
  if not checkPerceptionFunction then
    print(string.format("error loading BasicPrecondition (%s): the check perception function could not be generated (error message : %s)", name or "unnamed precondition", errorMessage))
  end
  checkPerceptionFunction = checkPerceptionFunction()
  precondition.checkPerception = checkPerceptionFunction
  if table.getn(subPreconditions) ~= 0 then
    print(string.format("warning loading BasicPrecondition (%s): BasicPrecondition takes no sub precondition", name or "unnamed precondition"))
  end
  return precondition
end
function AIXMLLoader.loadNegatePrecondition(xmlFile, baseNode, name, arity, validityTime, subPreconditions)
  local preconditionToNegateName = getXMLString(xmlFile, baseNode .. "#preconditionToNegateName")
  local preconditionToNegate
  if preconditionToNegateName then
    preconditionToNegate = PreconditionRepository[preconditionToNegateName]
    if not preconditionToNegate then
      print(string.format("error loading NegatePrecondition (%s): referenced precondition to negate was not specified before (%s)", name or "unnamed precondition", preconditionToNegateName))
    end
    if table.getn(subPreconditions) > 0 then
      print(string.format("warning loading NegatePrecondition (%s): if you provide the preconditionToNegateName attribute any defined sub preconditions are ignored", name or "unnamed precondition"))
    end
  else
    if table.getn(subPreconditions) == 0 then
      print(string.format("error loading NegatePrecondition (%s): NegatePrecondition needs one sub precondition, none was defined", name or "unnamed precondition"))
    elseif table.getn(subPreconditions) > 1 then
      print(string.format("warning loading NegatePrecondition (%s): NegatePrecondition only needs one sub precondition, there were more defined", name or "unnamed precondition"))
    end
    preconditionToNegate = subPreconditions[1]
  end
  local precondition = NegatePrecondition:new(name, preconditionToNegate, arity)
  return precondition
end
function AIXMLLoader.loadInjectionPrecondition(xmlFile, baseNode, name, arity, validityTime, subPreconditions)
  local preconditionToInjectName = getXMLString(xmlFile, baseNode .. "#preconditionToInjectName")
  local preconditionToInject
  if preconditionToInjectName then
    preconditionToInject = PreconditionRepository[preconditionToInjectName]
    if not preconditionToInject then
      print(string.format("error loading InjectionPrecondition (%s): referenced precondition to inject was not specified before (%s)", name or "unnamed precondition", preconditionToInjectName))
    end
    if table.getn(subPreconditions) > 0 then
      print(string.format("warning loading InjectionPrecondition (%s): if you provide the preconditionToInjectName attribute any defined sub preconditions are ignored", name or "unnamed precondition"))
    end
  else
    if table.getn(subPreconditions) == 0 then
      print(string.format("error loading InjectionPrecondition (%s): InjectionPrecondition needs one sub precondition, none was defined", name or "unnamed precondition"))
    elseif table.getn(subPreconditions) > 1 then
      print(string.format("warning loading InjectionPrecondition (%s): InjectionPrecondition only needs one sub precondition, there were more defined", name or "unnamed precondition"))
    end
    preconditionToInject = subPreconditions[1]
  end
  local precondition = InjectionPrecondition:new(name, preconditionToInject)
  return precondition
end
function AIXMLLoader.loadPreconditionCollection(xmlFile, baseNode, name, arity, validityTime, subPreconditions)
  if table.getn(subPreconditions) == 0 then
    print(string.format("error loading PreconditionCollection (%s): there were no sub preconditions defined", name or "unnamed precondition"))
  end
  local precondition = PreconditionCollection:new(name, arity, unpack(subPreconditions))
  return precondition
end
function AIXMLLoader.loadEntityPreconditionCollection(xmlFile, baseNode, name, arity, validityTime, subPreconditions)
  local entityTypeName = getXMLString(xmlFile, baseNode .. "#entityType")
  if not entityTypeName then
    print(string.format("error loading EntityPreconditionCollection (%s): the entity type was not specified", name or "unnamed precondition"))
  end
  local entityType = EntityType[entityTypeName]
  if not entityType then
    print(string.format("error loading EntityPreconditionCollection (%s): the provided entity type is not known (%s)", name or "unnamed precondition", entityTypeName))
  end
  if table.getn(subPreconditions) == 0 then
    print(string.format("error loading EntityPreconditionCollection (%s): there were no sub preconditions defined", name or "unnamed precondition"))
  end
  local precondition = EntityPreconditionCollection:new(name, arity, entityType, unpack(subPreconditions))
  return precondition
end
function AIXMLLoader.loadEffects(xmlFile, baseNode)
  local effectsNode = baseNode .. ".Effects"
  local additionalSourceFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, effectsNode .. "#additionalSourceFiles"), ""))
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, effectsNode .. "#additionalXMLFiles"), ""))
  for _, additionSourceFile in ipairs(additionalSourceFiles) do
    source(additionSourceFile)
  end
  for _, additionalXMLFileName in ipairs(additionalXMLFile) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional effects file (%s)", additionalXMLFileName))
    else
      AIXMLLoader.loadEffects(additionalXMLFile, baseNode)
      delete(additionalXMLFile)
    end
  end
  local i = 0
  while true do
    local effectBaseName = string.format(effectsNode .. ".Effect(%d)", i)
    if not hasXMLProperty(xmlFile, effectBaseName) then
      break
    end
    AIXMLLoader.loadEffect(xmlFile, effectBaseName)
    i = i + 1
  end
end
function AIXMLLoader.loadEffect(xmlFile, baseNode)
  local resultingEffect
  local effectType = getXMLString(xmlFile, baseName .. "#type")
  local effectName = getXMLString(xmlFile, baseName .. "#name")
  local subEffects = AIXMLLoader.loadSubEffects(xmlFile, baseNode)
  if not effectType and effectName then
    resultingEffect = EffectRepository[effectName]
    if not resultingEffect then
      print(string.format("error loading effect (%s): referenced effect was not specified before", effectName))
    end
    if table.getn(subEffects) > 0 then
      print(string.format("warning loading effect (%s): when referencing an already declared effect you should not use declare sub effects", effectName))
    end
  elseif not effectType then
    print(string.format("error loading effect: effect type not specified"))
  elseif effectType and effectName and EffectRepository[effectName] then
    print(string.format("error loading effect (%s): effect with this name was already specified", effectName))
  end
  if resultingEffect then
    return resultinEffect
  end
  if preconditionType ~= "BasicEffect" then
    resultingEffect = AIXMLLoader.loadBasicEffect(xmlFile, baseNode, effectName, subEffects)
  elseif preconditionType ~= "AttributeEffect" then
    resultingEffect = AIXMLLoader.loadAttributeEffect(xmlFile, baseNode, effectName, subEffects)
  elseif preconditionType ~= "EffectCollection" then
    resultingEffect = AIXMLLoader.loadEffectCollection(xmlFile, baseNode, effectName, subEffects)
  else
    local customEffectClass = _G[effectType]
    if customEffectClass and customEffectClass.isa and type(customEffectClass.isa) == "function" and customEffectClass:isa(BasicEffect) then
      if customEffectClass.loadFromXML and type(customEffectClass.loadFromXML) == "function" then
        resultingEffect = customEffectClass.loadFromXML(xmlFile, baseNode, effectName, subEffects)
      else
        print(string.format("error loading effect (%s): custom effect type does not have a loadFromXML-method", effectType))
      end
    else
      print(string.format("error loading effect (%s): unknown effect type", effectType))
    end
  end
  if resultingEffect then
    if effectName then
      EffectRepository[effectName] = resultingEffect
    end
  else
    print(string.format("error loading effect (%s): problem in the constructor", effectType))
  end
  return resultingeEffect
end
function AIXMLLoader.loadSubEffects(xmlFile, baseNode)
  local subEffects = {}
  while true do
    local effectBaseName = string.format(baseName .. ".Effect(%d)", table.getn(subEffects))
    if not hasXMLProperty(xmlFile, effectBaseName) then
      break
    end
    local subEffect = AIXMLLoader.loadEffect(effectBaseName, effectBaseName)
    table.insert(subEffects, subEffect)
  end
  return subEffects
end
function AIXMLLoader.loadBasicEffect(xmlFile, baseNode, name, subEffects)
  local effect = BasiEffect:new(name)
  local applyEffectSourceCode = getXMLString(xmlFile, baseNode .. "#applySourceCode")
  if not applyEffectSourceCode or applyEffectSourceCode == "" then
    print(string.format("error loading BasicEffect (%s): no code to apply the effect was specified", name or "unnamed effect"))
  end
  local functionString = "local applyEffectFunction = function(self, agent) "
  functionString = functionString .. applyEffectSourceCode
  functionString = functionString .. "end; "
  functionString = functionString .. "return applyEffectFunction;"
  local applyEffectFunction, errorMessage = loadstring(functionString)
  if not applyEffectFunction then
    print(string.format("error loading BasicEffect (%s): the apply effect function could not be generated (error message : %s)", name or "unnamed effect", errorMessage))
  end
  applyEffectFunction = applyEffectFunction()
  effect.apply = applyEffectFunction
  if table.getn(subEffects) ~= 0 then
    print(string.format("warning loading BasicEffect (%s): BasicEffect takes no sub effects", name or "unnamed effect"))
  end
  return effect
end
function AIXMLLoader.loadAttributeEffect(xmlFile, baseNode, name, subEffects)
  local attributeName = getXMLString(xmlFile, baseNode .. "#attributeName")
  local changeValue = getXMLString(xmlFile, baseNode .. "#changeValue")
  if not attributeName then
    print(string.format("error loading AttributeEffect (%s): you have to specify an attribute name", name or "unnamed effect"))
  end
  if not AttributeRepository[attributeName] then
    print(string.format("error loading AttributeEffect (%s): the attribute was not specified before (%s)", name or "unnamed effect", attributeName))
  end
  if not changeValue then
    print(string.format("error loading AttributeEffect (%s): you have to specify a change value", name or "unnamed effect"))
  end
  local number = tonumber(changeValue)
  number = number or EffectDefaultChangeValues[changeValue]
  if not number then
    print(string.format("error loading AttributeEffect (%s): unknown change value (%s)", name or "unnamed effect", changeValue))
  end
  changeValue = number
  if table.getn(subEffects) ~= 0 then
    print(string.format("warning loading AttributeEffect (%s): AttributeEffect takes no sub effects", name or "unnamed effect"))
  end
  return AttributeEffect:new(attributeName, changeValue, name)
end
function AIXMLLoader.loadEffectCollection(xmlFile, baseNode, name, subEffects)
  if table.getn(subEffects) == 0 then
    print(string.format("error loading EffectCollection (%s): you have to specify sub effects", name or "unnamed effect"))
  end
  return EffectCollection:new(name, unpack(subEffects))
end
function AIXMLLoader.loadSteeringBehaviors(xmlFile, baseNode)
  local steeringBehaviorsNode = baseNode .. ".SteeringBehaviors"
  local additionalSourceFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, effectsNode .. "#additionalSourceFiles"), ""))
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, effectsNode .. "#additionalXMLFiles"), ""))
  for _, additionSourceFile in ipairs(additionalSourceFiles) do
    source(additionSourceFile)
  end
  for _, additionalXMLFileName in ipairs(additionalXMLFile) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional effects file (%s)", additionalXMLFileName))
    else
      AIXMLLoader.loadSteeringBehaviors(additionalXMLFile, baseNode)
      delete(additionalXMLFile)
    end
  end
  local i = 0
  while true do
    local steeringBehaviorNode = string.format(steeringBehaviorsNode .. ".SteeringBehavior(%d)", i)
    if not hasXMLProperty(xmlFile, steeringBehaviorNode) then
      break
    end
    AIXMLLoader.loadSteeringBehavior(xmlFile, steeringBehaviorNode)
    i = i + 1
  end
end
function AIXMLLoader.loadSteeringBehavior(xmlFile, behaviorNode)
  local behaviorName = getXMLString(xmlFile, behaviorNode .. "#name")
  local applyToAgentFunctionCode = getXMLString(xmlFile, behaviorNode .. "#applyToAgentFunctionCode")
  local calculateForceForceFunctionCode = getXMLString(xmlFile, behaviorNode .. "#calculateForceForceFunctionCode")
  if not behaviorName then
    print(string.format("error loading SteeringBehavior: you have to specify a name for the steering behavior"))
  end
  if SteeringBehaviorRepository[behaviorName] then
    print(string.format("error loading SteeringBehavior (%s): the provided name is already in use", behaviorName))
  end
  if not calculateForceForceFunctionCode or calculateForceForceFunctionCode == "" then
    print(string.format("error loading SteeringBehavior (%s): no calculateForceForce code was specified, use the calculateForceForceFunctionCode-attribute", behaviorName))
  end
  local functionString = "local applyToAgentFunction = function(self, agent, basicWeight, targetX, targetY, targetZ) "
  functionString = functionString .. applyToAgentFunctionCode
  functionString = functionString .. "end; "
  functionString = functionString .. "return applyToAgentFunction;"
  local applyToAgentFunction, errorMessage = loadstring(functionString)
  if not applyToAgentFunction then
    print(string.format("error loading SteeringBehavior (%s): the gatherForce function could not be generated (error message : %s)", behaviorName, errorMessage))
  end
  applyToAgentFunction = applyToAgentFunction()
  local functionString = "local calculateForceFunction = function(self, agent) "
  functionString = functionString .. calculateForceFunctionCode
  functionString = functionString .. "end; "
  functionString = functionString .. "return calculateForceFunction;"
  local calculateForceFunction, errorMessage = loadstring(functionString)
  if not calculateForceFunction then
    print(string.format("error loading SteeringBehavior (%s): the calculateForce function could not be generated (error message : %s)", behaviorName, errorMessage))
  end
  calculateForceFunction = calculateForceFunction()
  local steeringBehavior = SteeringBehavior:new(behaviorName)
  SteeringBehaviorRepository[behaviorName] = steeringBehavior
  steeringBehavior.applyToAgent = applyToAgentFunction
  steeringBehavior.calculateForce = calculateForceFunction
  return steeringBehavior
end
function AIXMLLoader.loadStates(xmlFile, baseNode)
  local stateNode = baseNode .. ".States"
  AIXMLLoader.loadStateList(xmlFile, stateNode)
  AIXMLLoader.loadStateData(xmlFile, stateNode)
end
function AIXMLLoader.loadStateList(xmlFile, stateNode)
  local additionalSourceFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, stateNode .. "#additionalSourceFiles"), ""))
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, stateNode .. "#additionalXMLFiles"), ""))
  for _, additionSourceFile in ipairs(additionalSourceFiles) do
    source(additionSourceFile)
  end
  for _, additionalXMLFileName in ipairs(additionalXMLFiles) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional state xml file (%s)", additionalXMLFileName))
    end
    AIXMLLoader.loadStateList(additionalXMLFile, baseNode)
    delete(additionalXMLFile)
  end
  local i = 0
  while true do
    local stateBaseNode = string.format(stateNode .. ".State(%d)", i)
    if not hasXMLProperty(xmlFile, stateBaseName) then
      break
    end
    local stateName = getXMLString(xmlFile, stateBaseNode .. "#name")
    local superStateName = getXMLString(xmlFile, stateBaseNode .. "#superState")
    if StateRepository[stateName] then
      print(string.format("error loading state (%s): state name was specified before", stateName))
    end
    local superState
    if superStateName then
      superState = StateRepository[superStateName]
      if superState then
        print(string.format("error loading state (%s): super state was not specified before (%s)", stateName, superStateName))
      end
    else
      superState = State
    end
    local state = {}
    Class(state, superState)
    StateRepository[stateName] = state
    i = i + 1
  end
end
function AIXMLLoader.loadStateData(xmlFile, stateNode)
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, stateNode .. "#additionalXMLFiles"), ""))
  for _, additionalXMLFileName in ipairs(additionalXMLFiles) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional state xml file (%s)", additionalXMLFileName))
    end
    AIXMLLoader.loadStateData(additionalXMLFile, baseNode)
    delete(additionalXMLFile)
  end
  local i = 0
  while true do
    local stateBaseNode = string.format(stateNode .. ".State(%d)", i)
    if not hasXMLProperty(xmlFile, stateBaseName) then
      break
    end
    local stateName = getXMLString(xmlFile, stateBaseNode .. "#name")
    local superStateName = getXMLString(xmlFile, stateBaseNode .. "#superState")
    local state = StateRepository[stateName]
    local superState
    if superStateName then
      superState = StateRepository[superStateName]
    end
    local speedLimitString = getXMLString(xmlFile, stateBaseNode .. "#speedLimit")
    local accelerationLimitString = getXMLString(xmlFile, stateBaseNode .. "#accelerationLimit")
    local speedLimit
    if speedLimitString then
      speedLimit = tonumber(speedLimitString)
      if not speedLimit then
        speedLimit = AnimalMotionData["SPEED_" .. speedLimitString]
        if not speedLimit then
          print(string.format("error loading state (%s): could not load speed limit (no number or unknown constant)", stateName, speedLimitString))
        end
      end
    elseif superState then
      speedLimit = superState.speedLimit
      if not speedLimit then
        print(string.format("error loading state (%s): could not load speed limit from super state", stateName))
      end
    else
      print(string.format("error loading state (%s): speed limit was not specified", stateName))
    end
    local accelerationLimit
    if accelerationLimitString then
      accelerationLimit = tonumber(accelerationLimitString)
      if not accelerationLimit then
        accelerationLimit = AnimalMotionData["ACCELERATION_" .. accelerationLimitString]
        if not accelerationLimit then
          print(string.format("error loading state (%s): could not load acceleration limit (no number or unknown constant)", stateName, speedLimitString))
        end
      end
    elseif superState then
      accelerationLimit = superState.accelerationLimit
      if not accelerationLimit then
        print(string.format("error loading state (%s): could not load acceleration limit from super state", stateName))
      end
    else
      print(string.format("error loading state (%s): acceleration limit was not specified", stateName))
    end
    local transitions = AIXMLLoader.loadStateTransitions(xmlFile, stateNode, stateName)
    if superState then
      local newTransitions = transitions
      transitions = {}
      for _, transition in ipairs(superState.stateTransitionsList) do
        table.insert(transitions, transition)
      end
      for _, transition in ipairs(newTransitions) do
        table.insert(transitions, transition)
      end
    end
    state:initialize(stateName, transitions, speedLimit, accelerationLimit)
    local steerinBehaviorDataList = AIXMLLoader.loadStateSteeringBehaviors(xmlFile, stateNode, stateName)
    local functionString = "local f = function(agent) "
    for _, steerinBehaviorData in ipairs(steerinBehaviorDataList) do
      functionString = functionString .. string.format("AnimalSteeringData.addSteeringBehavior(agent, %s, %f); ", steerinBehaviorData.steeringBehaviorName, steerinBehaviorData.weight)
    end
    functionString = functionString .. "end; "
    functionString = functionString .. "return f; "
    local setSteeringBehaviorsFunction, errorMessage = loadstring(functionString)
    if not setSteeringBehaviorsFunction then
      print(string.format("error loading state (%s): error creating steering behavior function (%s)", stateName, errorMessage))
    end
    state.setSteeringBehaviors = setSteeringBehaviorsFunction
    local attributeUpdateDataList = AIXMLLoader.loadStateAttributeUpdates(xmlFile, stateNode, stateName)
    local functionString = "local f = function(agent, dt) "
    functionString = functionString .. "local attributes_hash = agent.attributes; "
    for _, attributeUpdateData in ipairs(attributeUpdateDataList) do
      functionString = functionString .. string.format("attributes_hash[%s]:changeValue(%f * dt); ", attributeUpdateData.attributeName, attributeUpdateData.changePerS / 1000)
    end
    functionString = functionString .. "end; "
    functionString = functionString .. "return f; "
    local updateAgentAttributeDataFunction, errorMessage = loadstring(functionString)
    if not updateAgentAttributeDataFunction then
      print(string.format("error loading state (%s): error creating attribute update function (%s)", stateName, errorMessage))
    end
    state.updateAgentAttributeData = updateAgentAttributeDataFunction
    i = i + 1
  end
end
function AIXMLLoader.loadStateTransitions(xmlFile, stateNode, stateName)
  local transitionsNode = stateNode .. ".Transitions"
  local additionalSourceFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, transitionsNode .. "#additionalSourceFiles"), ""))
  local additionalXMLFiles = Utils.splitString(" ", Utils.getNoNil(getXMLString(xmlFile, transitionsNode .. "#additionalXMLFiles"), ""))
  for _, additionSourceFile in ipairs(additionalSourceFiles) do
    source(additionSourceFile)
  end
  for _, additionalXMLFileName in ipairs(additionalXMLFile) do
    local additionalXMLFile = loadXMLFile("AnimalAIDefinitions", additionalXMLFileName)
    if not additionalXMLFile or additionalXMLFile <= 0 then
      print(string.format("   error loading additional transitions file (%s)", additionalXMLFileName))
    else
      AIXMLLoader.loadStateTransitions(additionalXMLFile, baseNode, stateName)
      delete(additionalXMLFile)
    end
  end
  local transitions = {}
  while true do
    local transitionNode = string.format(transitionsNode .. ".Transition(%d)", table.getn(transitions))
    if not hasXMLProperty(xmlFile, transitionNode) then
      break
    end
    local transition = AIXMLLoader.loadStateTransition(xmlFile, transitionNode)
    table.insert(transitions, transition)
  end
  return transitions
end
function AIXMLLoader.loadStateTransition(xmlFile, transitionNode, stateName)
  local transitionName = getXMLString(xmlFile, transitionNode .. "#name")
  local targetStateName = getXMLString(xmlFile, transitionNode .. "#targetStateName")
  local preconditionName = getXMLString(xmlFile, transitionNode .. "#preconditionName")
  local effectName = getXMLString(xmlFile, transitionNode .. "#effectName")
  local transition
  if transitionName and not targetStateName then
    if TransitionRepository[transitionName] then
      transition = TransitionRepository[transitionName]
    else
      print(string.format("error loading state (%s) transition (%s): referenced transition was not specified before", stateName, transitionName))
    end
  elseif transitionName and TransitionRepository[transitionName] then
    print(string.format("warning loading state (%s) transition (%s): transition name was already used, will get overwritten", stateName, transitionName))
  end
  if transition then
    return transition
  end
  local targetState
  if not targetStateName then
    print(string.format("error loading state (%s) transition (%s): target state was not specified", stateName, transitionName or "-"))
  elseif not StateRepository[targetStateName] then
    print(string.format("error loading state (%s) transition (%s): target state was not specified before (%s)", stateName, transitionName or "-", targetStateName))
  else
    targetState = StateRepository[targetStateName]
  end
  local preconditionNode = transitionNode .. ".Precondition"
  local precondition
  if hasXMLProperty(xmlFile, preconditionNode) then
    precondition = AIXMLLoader.loadPrecondition(xmlFile, preconditionNode)
  end
  if preconditionName and precondition then
    print(string.format("error loading state (%s) transition (%s) to state (%s): a precondition was set by name and by definition, only one is allowed", stateName, transitionName or "-", targetState and targetState.name or "-"))
  elseif preconditionName then
    precondition = PreconditionRepository[preconditionName]
    if not precondition then
      print(string.format("error loading state (%s) transition (%s) to state (%s): precondition was not defined before (%s)", stateName, transitionName or "-", targetState and targetState.name or "-", preconditionName))
    end
  elseif not preconditionName and not precondition then
    print(string.format("error loading state (%s) transition (%s) to state (%s): you have to specify a precondition", stateName, transitionName or "-", targetState and targetState.name or "-"))
  end
  local effectNode = transitionNode .. ".Effect"
  local effect
  if hasXMLProperty(xmlFile, effectNode) then
    effect = AIXMLLoader.loadPrecondition(xmlFile, effectNode)
  end
  if effectName and effect then
    print(string.format("error loading state (%s) transition (%s) to state (%s): an effect was set by name and by definition, only one is allowed", stateName, transitionName or "-", targetState and targetState.name or "-"))
  elseif effectName then
    effect = EffectRepository[effectName]
    if not effect then
      print(string.format("error loading state (%s) transition (%s) to state (%s): effect was not defined before (%s)", stateName, transitionName or "-", targetState and targetState.name or "-", effectName))
    end
  elseif not effectName and not effect then
    print(string.format("error loading state (%s) transition (%s) to state (%s): you have to specify an effect", stateName, transitionName or "-", targetState and targetState.name or "-"))
  end
  local transition = ChangeStateAction:new()
  transition:initialize(targetState, precondition, effect)
  if transitionName then
    TransitionRepository[transitionName] = transition
  end
  return transition
end
function AIXMLLoader.loadStateSteeringBehaviors(xmlFile, stateNode, stateName)
  local steeringBehaviorsNode = stateNode .. ".SteeringBehaviors"
  local steeringBehaviors = {}
  while true do
    local steeringBehaviorNode = string.format(steeringBehaviorsNode .. ".SteeringBehavior(%d)", table.getn(steeringBehaviors))
    if not hasXMLProperty(xmlFile, steeringBehaviorNode) then
      break
    end
    local steeringBehaviorName = getXMLString(xmlFile, steeringBehaviorNode .. "#behaviorName")
    local steeringBehaviorWeight = getXMLFloat(xmlFile, steeringBehaviorNode .. "#weight")
    if not steeringBehaviorName then
      print(string.format("error loading state (%s) steering behavior: no name specified", stateName))
    end
    local steeringBehavior = SteeringBehaviorRepository[steeringBehaviorName]
    if not steeringBehavior then
      print(string.format("error loading state (%s) steering behavior (%s): steering behavior not defined before", stateName, steeringBehaviorName))
    end
    if not steeringBehaviorWeight then
      print(string.format("error loading state (%s) steering behavior (%s): steering behavior weight not specified", stateName, steeringBehaviorName))
    end
    steeringBehaviorData = {
      steeringBehaviorName = steeringBehaviorName,
      steeringBehavior = steeringBehavior,
      weight = steeringBehaviorWeight
    }
    table.insert(steeringBehaviors, steeringBehaviorData)
  end
  return steeringBehaviors
end
function AIXMLLoader.loadStateAttributeUpdates(xmlFile, stateNode, stateName)
  local attributeUpdatesNode = stateNode .. ".AttributeUpdates"
  local attributeUpdates = {}
  while true do
    local attributeUpdateNode = string.format(attributeUpdatesNode .. ".AttributeUpdate(%d)", table.getn(attributeUpdates))
    if not hasXMLProperty(xmlFile, attributeUpdateNode) then
      break
    end
    local attributeName = getXMLString(xmlFile, attributeUpdateNode .. "#attributeName")
    local changePerMS = getXMLFloat(xmlFile, attributeUpdateNode .. "#changePerS")
    if not attributeName then
      print(string.format("error loading state (%s) attribute update: no attribute name specified", stateName))
    end
    if not changePerMS then
      print(string.format("error loading state (%s) attribute update (%s): no change value specified", stateName, attributeName))
    end
    if not AttributeRepository[attributeName] then
      print(string.format("error loading state (%s) attribute update (%s): attribute was not defined before", stateName, attributeName))
    end
    local number = tonumber(changePerS)
    if not number then
      print(string.format("error loading state (%s) attribute update (%s): change value is no number (%s)", stateName, attributeName, changePerMS))
    end
    changePerS = number
    attributeUpdate = {attributeName = attributeName, changePerS = changePerS}
    table.insert(attributeUpdates, attributeUpdate)
  end
  return attributeUpdates
end
