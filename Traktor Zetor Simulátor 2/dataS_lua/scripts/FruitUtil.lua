FruitUtil = {}
FruitUtil.FRUITTYPE_UNKNOWN = 0
FruitUtil.NUM_FRUITTYPES = 0
FruitUtil.fruitTypes = {}
FruitUtil.fruitIndexToDesc = {}
FruitUtil.fruitTypeToFillType = {}
FruitUtil.fillTypeToFruitType = {}
FruitUtil.sendNumBits = 6
function FruitUtil.registerFruitType(name, needsSeeding, allowsSeeding, hasStraw, minHarvestingGrowthState, pricePerLiter, literPerSqm, seedUsagePerSqm, seedPricePerLiter, hudFruitOverlayFilename)
  local key = "FRUITTYPE_" .. string.upper(name)
  if FruitUtil[key] == nil then
    if FruitUtil.NUM_FRUITTYPES >= 64 then
      print("Error FruitUtil.registerFruitType: Too many fruit types. Only 64 fruit types are supported")
      return
    end
    FruitUtil.NUM_FRUITTYPES = FruitUtil.NUM_FRUITTYPES + 1
    FruitUtil[key] = FruitUtil.NUM_FRUITTYPES
    local desc = {
      name = name,
      index = FruitUtil.NUM_FRUITTYPES
    }
    desc.needsSeeding = needsSeeding
    desc.allowsSeeding = allowsSeeding
    desc.hasStraw = hasStraw
    desc.minHarvestingGrowthState = minHarvestingGrowthState
    desc.pricePerLiter = pricePerLiter
    desc.yesterdaysPrice = pricePerLiter
    desc.literPerSqm = literPerSqm
    desc.seedUsagePerSqm = seedUsagePerSqm
    desc.seedPricePerLiter = seedPricePerLiter
    desc.hudFruitOverlayFilename = hudFruitOverlayFilename
    FruitUtil.fruitTypes[name] = desc
    FruitUtil.fruitIndexToDesc[FruitUtil.NUM_FRUITTYPES] = desc
    g_startPrices[FruitUtil.NUM_FRUITTYPES] = pricePerLiter
    g_startPriceSum = g_startPriceSum + pricePerLiter
    local fillType = Fillable.registerFillType(name)
    FruitUtil.fruitTypeToFillType[FruitUtil.NUM_FRUITTYPES] = fillType
    FruitUtil.fillTypeToFruitType[fillType] = FruitUtil.NUM_FRUITTYPES
  end
end
function FruitUtil.setAutoSeedFruitType(fruitType, autoSeedFruitType)
  FruitUtil.fruitIndexToDesc[fruitType].autoSeedFruitType = autoSeedFruitType
end
