MissionPDA = {}
source("dataS/scripts/environment/EnvironmentTmpEvent.lua")
MissionPDA.alpha = 1
MissionPDA.alphaInc = 0.05
local MissionPDA_mt = Class(MissionPDA)
function MissionPDA:new()
  local instance = {}
  setmetatable(instance, MissionPDA_mt)
  instance.screen = 1
  instance.numberOfScreens = 6
  instance.textTitles = {}
  for i = 1, 6 do
    table.insert(instance.textTitles, g_i18n:getText("PDATitle" .. i))
  end
  instance.worldSizeX = 2048
  instance.worldSizeZ = 2048
  instance.worldCenterOffsetX = instance.worldSizeX * 0.5
  instance.worldCenterOffsetZ = instance.worldSizeZ * 0.5
  instance.hudPDABasePosX = -0.008
  instance.hudPDABasePosY = -0.003
  instance.hudPDABaseWidth = 0.45
  instance.hudPDABaseHeight = instance.hudPDABaseWidth * 0.5625 * 1.3333333333333333
  instance.hudPDAFrameOverlay = Overlay:new("hudPDAFrameOverlay", "dataS2/missions/hud_pda_frame.png", instance.hudPDABasePosX, instance.hudPDABasePosY, instance.hudPDABaseWidth, instance.hudPDABaseHeight)
  instance.hudPDABackgroundOverlay = Overlay:new("hudPDABackgroundOverlay", "dataS2/missions/hud_pda_bg.png", instance.hudPDABasePosX, instance.hudPDABasePosY, instance.hudPDABaseWidth, instance.hudPDABaseHeight)
  instance.pdaMapWidth = instance.hudPDABaseWidth * 0.8
  instance.pdaMapHeight = instance.pdaMapWidth * 1.3333333333333333 / 2
  instance.pdaMapPosX = instance.hudPDABasePosX + instance.hudPDABaseWidth / 2 - instance.pdaMapWidth / 2
  instance.pdaMapPosY = instance.hudPDABasePosY + 0.11 * instance.hudPDABaseHeight
  instance.pdaMapUVs = {}
  for i = 1, 8 do
    table.insert(instance.pdaMapUVs, 0)
  end
  instance.pdaMapVisWidthMin = 0.2
  instance.pdaMapVisWidth = 0.2
  instance.pdaMapAspectRatio = 0.5
  instance.pdaMapVisHeight = instance.pdaMapVisWidth * instance.pdaMapAspectRatio
  instance.pdaMapArrowSize = instance.pdaMapWidth / 6
  instance.pdaMapArrowXPos = instance.pdaMapPosX + instance.pdaMapWidth / 2 - instance.pdaMapArrowSize / 2
  instance.pdaMapArrowYPos = instance.pdaMapPosY + instance.pdaMapHeight / 2 - instance.pdaMapArrowSize * 1.3333333333333333 / 2
  instance.pdaMapArrowRotation = 0
  instance.pdaMapArrowUVs = {}
  for i = 1, 8 do
    table.insert(instance.pdaMapArrowUVs, 0)
  end
  instance.hotspots = {}
  instance.isMapZoomed = false
  instance.pdaPlayerMapArrow = Overlay:new("pdaMapArrow", "dataS2/missions/pda_map_arrow.png", instance.pdaMapArrowXPos, instance.pdaMapArrowYPos, instance.pdaMapArrowSize, instance.pdaMapArrowSize * 1.3333333333333333)
  instance.pdaMapArrowRed = Overlay:new("pdaMapArrow", "dataS2/missions/pda_map_arrow_red.png", instance.pdaMapArrowXPos, instance.pdaMapArrowYPos, instance.pdaMapArrowSize, instance.pdaMapArrowSize * 1.3333333333333333)
  instance.pdaX = instance.hudPDABasePosX + instance.hudPDABaseWidth * 0.12
  instance.pdaY = instance.hudPDABasePosY + instance.hudPDABaseHeight - instance.hudPDABaseHeight * 0.1
  instance.pdaWidth = instance.hudPDABaseWidth * 0.745
  instance.pdaHeight = instance.hudPDABaseHeight * 0.645
  instance.pdaTopSpacing = instance.pdaHeight * 0.09
  instance.pdaTitleY = instance.pdaY - instance.pdaTopSpacing - 0.012
  instance.pdaTitleX = instance.pdaX + instance.pdaWidth * 0.05
  instance.pdaTitleTextSize = instance.pdaHeight / 8
  instance.pdaCol1 = instance.pdaX
  instance.pdaCol2 = instance.pdaX + instance.pdaWidth * 0.6
  instance.pdaCol3 = instance.pdaX + instance.pdaWidth * 0.8
  instance.pdaHeadRow = instance.pdaY - 3 * instance.pdaTopSpacing
  instance.pdaFontSize = instance.pdaHeight / 12
  instance.pdaRowSpacing = instance.pdaFontSize * 1.15
  instance.playerXPos = 0
  instance.playerYPos = 0
  instance.playerZPos = 0
  instance.pdaCoordsXPos = instance.pdaX + instance.pdaWidth + 0.001
  instance.pdaCoordsYPos = instance.pdaY - 13 * instance.pdaTopSpacing - 0.005
  instance.pdaWeatherWidth = instance.pdaMapWidth * 0.96
  instance.pdaWeatherHeight = instance.pdaWeatherWidth * 1.3333333333333333 / 2
  instance.pdaWeatherPosX = instance.hudPDABasePosX + instance.hudPDABaseWidth / 2 - instance.pdaWeatherWidth / 2
  instance.pdaWeatherPosY = instance.hudPDABasePosY + 0.12 * instance.hudPDABaseHeight
  instance.pdaWeatherIconSize = instance.pdaWeatherWidth * 0.16666
  instance.pdaWeatherIconPosX = instance.pdaWeatherPosX + 0.042 * instance.pdaWeatherWidth
  instance.pdaWeatherIconPosY = instance.pdaWeatherPosY + 0.43 * instance.pdaWeatherHeight
  instance.pdaWeatherIconSpacing = instance.pdaWeatherWidth * 0.25
  instance.pdaWeatherTextPosX = instance.pdaWeatherPosX + 0.115 * instance.pdaWeatherWidth
  instance.pdaWeatherTextDayPosY = instance.pdaWeatherPosY + 0.82 * instance.pdaWeatherHeight
  instance.pdaWeatherTextDayTemperaturePosY = instance.pdaWeatherPosY + 0.24 * instance.pdaWeatherHeight
  instance.pdaWeatherTextNightTemperaturePosY = instance.pdaWeatherPosY + 0.06 * instance.pdaWeatherHeight
  instance.pdaWeatherTextSpacing = instance.pdaWeatherWidth * 0.25
  instance.pdaWeatherTextSize = instance.pdaWeatherWidth * 0.08
  instance.dayShownWeather = 0
  instance.dayShownPrices = 0
  instance.pdaWeatherBGOverlay = Overlay:new("pdaWeatherBGOverlay", "dataS2/missions/hud_pda_weather_bg.png", instance.pdaWeatherPosX, instance.pdaWeatherPosY, instance.pdaWeatherWidth, instance.pdaWeatherHeight)
  setOverlayUVs(instance.pdaWeatherBGOverlay.overlayId, 0, 0, 0, 1, 4, 0, 4, 1)
  instance.weatherIconSun = "dataS2/missions/hud_pda_weather_sun.png"
  instance.weatherIconRain = "dataS2/missions/hud_pda_weather_rain.png"
  instance.weatherIconHail = "dataS2/missions/hud_pda_weather_hail.png"
  instance.pdaWeatherIcons = {}
  for i = 1, 4 do
    table.insert(instance.pdaWeatherIcons, Overlay:new("pdaWeatherIcon" .. i, instance.weatherIconSun, instance.pdaWeatherIconPosX + (i - 1) * instance.pdaWeatherIconSpacing, instance.pdaWeatherIconPosY, instance.pdaWeatherIconSize, instance.pdaWeatherIconSize * 4 / 3))
  end
  instance.pdaWeatherDays = {}
  for i = 1, 7 do
    table.insert(instance.pdaWeatherDays, g_i18n:getText("Day" .. i))
  end
  instance.pdaWeatherTemperaturesDay = {}
  instance.pdaWeatherTemperaturesNight = {}
  for i = 1, 4 do
    instance.pdaWeatherTemperaturesDay[i] = 0
    instance.pdaWeatherTemperaturesNight[i] = 0
    instance.pdaWeatherTemperaturesDay[i] = math.random(17, 25)
    instance.pdaWeatherTemperaturesNight[i] = math.random(8, 16)
  end
  instance.priceArrowUp = "dataS2/missions/hud_pda_priceArrow_up.png"
  instance.priceArrowFlat = "dataS2/missions/hud_pda_priceArrow_flat.png"
  instance.priceArrowDown = "dataS2/missions/hud_pda_priceArrow_down.png"
  FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_WHEAT].yesterdaysPrice = 0.21
  FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_RAPE].yesterdaysPrice = 0.56
  instance.priceArrowSize = instance.hudPDABaseWidth * 0.04
  instance.pdaPriceArrows = {}
  for i = 1, FruitUtil.NUM_FRUITTYPES do
    table.insert(instance.pdaPriceArrows, Overlay:new("pdaPriceArrow" .. i, instance.priceArrowFlat, instance.pdaCol3, instance.pdaHeadRow - instance.pdaRowSpacing * i, instance.priceArrowSize, instance.priceArrowSize * 4 / 3))
  end
  instance.pdaPricesCol = {}
  instance.pdaPricesCol[1] = instance.pdaX
  instance.pdaPricesCol[2] = instance.pdaX + instance.pdaWidth * 0.3
  instance.pdaPricesCol[3] = instance.pdaX + instance.pdaWidth * 0.5
  instance.pdaPricesCol[4] = instance.pdaX + instance.pdaWidth * 0.7
  instance.pdaPricesCol[5] = instance.pdaX + instance.pdaWidth * 0.94
  instance.showTriggerStart = 1
  instance.pdaUserCol = {}
  instance.pdaUserCol[1] = instance.pdaX
  instance.pdaUserCol[2] = instance.pdaX + instance.pdaWidth * 0.55
  instance.pdaUserCol[3] = instance.pdaX + instance.pdaWidth * 0.78
  instance.pdaBeepSound = createSample("pdaBeepSample")
  loadSample(instance.pdaBeepSound, "data/maps/sounds/pdaBeep.wav", false)
  instance.showPDA = false
  instance.enablePDA = true
  instance.smoothSpeed = 0
  return instance
end
function MissionPDA:createMapHotspot(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  local mapHotspot = MapHotspot:new(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  table.insert(self.hotspots, mapHotspot)
  return mapHotspot
end
function MissionPDA:delete()
  self.hudPDABackgroundOverlay:delete()
  self.hudPDAFrameOverlay:delete()
  if self.pdaMapOverlay ~= nil then
    self.pdaMapOverlay:delete()
    self.pdaMapOverlay = nil
  end
  self.pdaPlayerMapArrow:delete()
  self.pdaMapArrowRed:delete()
  delete(self.pdaBeepSound)
  for k, v in pairs(self.hotspots) do
    v:delete()
  end
end
function MissionPDA:loadMap(filename)
  if self.pdaMapOverlay ~= nil then
    self.pdaMapOverlay:delete()
  end
  self.pdaMapOverlay = Overlay:new("pdaMapOverlay", filename, self.pdaMapPosX, self.pdaMapPosY, self.pdaMapWidth, self.pdaMapHeight)
end
function MissionPDA:mouseEvent(posX, posY, isDown, isUp, button)
end
function MissionPDA:keyEvent(unicode, sym, modifier, isDown)
end
function MissionPDA:update(dt)
  if self.enablePDA and g_gui.currentGui == nil then
    if InputBinding.hasEvent(InputBinding.TOGGLE_PDA_ZOOM) then
      if self.screen == 3 then
        self.showTriggerStart = self.showTriggerStart + 3
      elseif self.screen == 1 then
        self.isMapZoomed = not self.isMapZoomed
      end
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_PDA) and not g_currentMission.telescopeActive then
      playSample(self.pdaBeepSound, 1, 0.3, 0)
      if self.showPDA then
        if self.screen == self.numberOfScreens then
          self.showPDA = false
          self.screen = 1
        else
          self.screen = self.screen + 1
          if self.screen == self.numberOfScreens and not g_currentMission.missionDynamicInfo.isMultiplayer then
            self.showPDA = false
            self.screen = 1
          end
        end
      else
        self.showPDA = true
        self.screen = 1
      end
    end
  end
end
function MissionPDA:draw()
  if self.showPDA and self.enablePDA then
    local missionStats = g_currentMission.missionStats
    self.hudPDABackgroundOverlay:render()
    if self.screen == 1 then
      self:drawMap()
    elseif self.screen == 2 then
      self.pdaWeatherBGOverlay:render()
      if self.dayShownWeather ~= g_currentMission.environment.currentDay then
        if g_currentMission.environment.dayNightCycle then
          if g_server ~= nil then
            for i = 1, 3 do
              self.pdaWeatherTemperaturesDay[i] = self.pdaWeatherTemperaturesDay[i + 1]
              self.pdaWeatherTemperaturesNight[i] = self.pdaWeatherTemperaturesNight[i + 1]
            end
            self.pdaWeatherTemperaturesDay[4] = math.random(17, 25)
            self.pdaWeatherTemperaturesNight[4] = math.random(9, 16)
            g_server:broadcastEvent(EnvironmentTmpEvent:new(self.pdaWeatherTemperaturesDay, self.pdaWeatherTemperaturesNight))
          end
          local currentTime = g_currentMission.environment.dayTime / 60000
          local timeUntilNextRain = math.max(0, (currentTime + g_currentMission.environment.timeUntilNextRain) / 1440)
          local timeUntilRainAfterNext = (currentTime + g_currentMission.environment.timeUntilNextRain + g_currentMission.environment.timeUntilRainAfterNext) / 1440
          local nextRainType = self.weatherIconRain
          if g_currentMission.environment.nextRainType == 1 then
            nextRainType = self.weatherIconHail
          end
          local rainTypeAfterNext = self.weatherIconRain
          if g_currentMission.environment.rainTypeAfterNext == 1 then
            rainTypeAfterNext = self.weatherIconHail
          end
          for i = 0, 3 do
            local currentNewIcon = self.weatherIconSun
            self.pdaWeatherIcons[i + 1]:delete()
            if i <= timeUntilNextRain and timeUntilNextRain < i + 1 then
              currentNewIcon = nextRainType
              if nextRainType == self.weatherIconHail and self.pdaWeatherTemperaturesDay[i + 1] >= 19 then
                self.pdaWeatherTemperaturesDay[i + 1] = self.pdaWeatherTemperaturesDay[i + 1] - 8
                self.pdaWeatherTemperaturesNight[i + 1] = self.pdaWeatherTemperaturesDay[i + 1] - 4
              end
            end
            if i <= timeUntilRainAfterNext and timeUntilRainAfterNext < i + 1 then
              currentNewIcon = rainTypeAfterNext
              if rainTypeAfterNext == self.weatherIconHail and self.pdaWeatherTemperaturesDay[i + 1] >= 19 then
                self.pdaWeatherTemperaturesDay[i + 1] = self.pdaWeatherTemperaturesDay[i + 1] - 8
                self.pdaWeatherTemperaturesNight[i + 1] = self.pdaWeatherTemperaturesDay[i + 1] - 4
              end
            end
            self.pdaWeatherIcons[i + 1] = Overlay:new("pdaWeatherIcon" .. i + 1, currentNewIcon, self.pdaWeatherIconPosX + i * self.pdaWeatherIconSpacing, self.pdaWeatherIconPosY, self.pdaWeatherIconSize, self.pdaWeatherIconSize * 4 / 3)
          end
          self.dayShownWeather = g_currentMission.environment.currentDay
        else
          self.dayShownWeather = g_currentMission.environment.currentDay
        end
      end
      for k, v in pairs(self.pdaWeatherIcons) do
        v:render()
      end
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextColor(0, 0, 0, 1)
      setTextBold(true)
      for i = 0, 3 do
        if i == 0 then
          renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY - 0.002, self.pdaWeatherTextSize, g_i18n:getText("Today"))
        else
          renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY - 0.002, self.pdaWeatherTextSize, self.pdaWeatherDays[math.mod(math.mod(self.dayShownWeather, 7) + i - 1, 7) + 1])
        end
        renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayTemperaturePosY - 0.002, self.pdaWeatherTextSize * 1.1, tostring(self.pdaWeatherTemperaturesDay[i + 1]) .. g_i18n:getText("TemperatureSymbol"))
        renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextNightTemperaturePosY - 0.002, self.pdaWeatherTextSize * 1.1, tostring(self.pdaWeatherTemperaturesNight[i + 1]) .. g_i18n:getText("TemperatureSymbol"))
      end
      for i = 0, 3 do
        setTextColor(0.9, 0.95, 1, 1)
        if i == 0 then
          renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY, self.pdaWeatherTextSize, g_i18n:getText("Today"))
        else
          renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayPosY, self.pdaWeatherTextSize, self.pdaWeatherDays[math.mod(math.mod(self.dayShownWeather, 7) + i - 1, 7) + 1])
        end
        setTextColor(1, 1, 0.5, 1)
        renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextDayTemperaturePosY, self.pdaWeatherTextSize * 1.1, tostring(self.pdaWeatherTemperaturesDay[i + 1]) .. g_i18n:getText("TemperatureSymbol"))
        setTextColor(0.2, 0.3, 0.7, 1)
        renderText(self.pdaWeatherTextPosX + i * self.pdaWeatherTextSpacing, self.pdaWeatherTextNightTemperaturePosY, self.pdaWeatherTextSize * 1.1, tostring(self.pdaWeatherTemperaturesNight[i + 1]) .. g_i18n:getText("TemperatureSymbol"))
      end
      setTextBold(false)
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextColor(1, 1, 1, 1)
    elseif self.screen == 3 then
      if self.dayShownPrices ~= g_currentMission.environment.currentDay then
        for i = 1, table.getn(self.pdaPriceArrows) do
          local currentNewArrow = self.priceArrowFlat
          local delta = FruitUtil.fruitIndexToDesc[i].pricePerLiter - FruitUtil.fruitIndexToDesc[i].yesterdaysPrice
          if 0 < delta then
            currentNewArrow = self.priceArrowUp
          elseif delta < 0 then
            currentNewArrow = self.priceArrowDown
          end
          self.pdaPriceArrows[i]:delete()
          self.pdaPriceArrows[i] = Overlay:new("pdaPriceArrow" .. i, currentNewArrow, self.pdaPricesCol[5], self.pdaHeadRow - self.pdaRowSpacing * i, self.priceArrowSize, self.priceArrowSize * 4 / 3)
        end
        self.dayShownWeather = g_currentMission.environment.currentDay
      end
      setTextColor(0.8, 1, 0.9, 1)
      local temp = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_WHEAT].name
      temp = string.upper(string.sub(temp, 1, 1)) .. string.sub(temp, 2, string.len(temp))
      local stationCounter = 0
      local printedFruitName = {}
      local usedTipTriggerNames = {}
      local tipTriggers = {}
      for k, currentTipTrigger in pairs(g_currentMission.tipTriggers) do
        if currentTipTrigger.appearsOnPDA then
          local stationName = currentTipTrigger.stationName
          if g_i18n:hasText(stationName) then
            stationName = g_i18n:getText(stationName)
          end
          if usedTipTriggerNames[stationName] == nil then
            usedTipTriggerNames[stationName] = true
            table.insert(tipTriggers, {stationName = stationName, tipTrigger = currentTipTrigger})
          end
        end
      end
      table.sort(tipTriggers, MissionPDA.tipTriggerSorter)
      if self.showTriggerStart > table.getn(tipTriggers) then
        self.showTriggerStart = 1
      end
      local lastTipTrigger = math.min(self.showTriggerStart + 2, table.getn(tipTriggers))
      for k = self.showTriggerStart, lastTipTrigger do
        local currentTipTrigger = tipTriggers[k].tipTrigger
        local stationName = tipTriggers[k].stationName
        if stationCounter < 3 then
          stationCounter = stationCounter + 1
          setTextBold(true)
          renderText(self.pdaPricesCol[stationCounter + 1], self.pdaHeadRow, self.pdaFontSize, stationName)
          setTextBold(false)
          for i = 1, FruitUtil.NUM_FRUITTYPES do
            if currentTipTrigger.acceptedFruitTypes[i] then
              local difficultyMultiplier = math.max(3 * (3 - missionStats.difficulty), 1)
              renderText(self.pdaPricesCol[stationCounter + 1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, tostring(math.floor(g_i18n:getCurrency(math.ceil(FruitUtil.fruitIndexToDesc[i].pricePerLiter * 1000 * currentTipTrigger.priceMultipliers[i] * difficultyMultiplier)))))
              if not printedFruitName[i] then
                printedFruitName[i] = true
                local fruitName = FruitUtil.fruitIndexToDesc[i].name
                if g_i18n:hasText(fruitName) then
                  fruitName = g_i18n:getText(fruitName)
                end
                renderText(self.pdaPricesCol[1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, fruitName .. " " .. g_i18n:getText("PricePerTon"))
                self.pdaPriceArrows[i].y = self.pdaHeadRow - self.pdaRowSpacing * i
                self.pdaPriceArrows[i]:render()
              end
            end
          end
        end
      end
      setTextColor(0.8, 1, 0.9, 1)
      setTextAlignment(RenderText.ALIGN_RIGHT)
      renderText(self.pdaPricesCol[5] + 0.025, self.pdaY - self.pdaHeight - 0.04, self.pdaFontSize * 0.9, string.format("%d / %d", math.ceil(self.showTriggerStart / 3), math.ceil(table.getn(tipTriggers) / 3)))
      setTextAlignment(RenderText.ALIGN_LEFT)
    elseif self.screen == 4 then
      setTextBold(true)
      setTextColor(0.8, 1, 0.9, 1)
      setTextBold(false)
      local yOffset = 0.01
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, g_i18n:getText("Wheat_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_WHEAT], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 2 + yOffset, self.pdaFontSize, g_i18n:getText("Barley_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 2 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_BARLEY], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 3 + yOffset, self.pdaFontSize, g_i18n:getText("Rapeseed_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 3 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_RAPE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 4 + yOffset, self.pdaFontSize, g_i18n:getText("Maize_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 4 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_MAIZE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 5 + yOffset, self.pdaFontSize, g_i18n:getText("Cows_owned"))
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 5 + yOffset, self.pdaFontSize, string.format("%1.0f", AnimalHusbandry.getNumberOfAnimals(), 0))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 6 + yOffset, self.pdaFontSize, g_i18n:getText("LiquidManure_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 6 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_LIQUIDMANURE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 7 + yOffset, self.pdaFontSize, g_i18n:getText("Manure_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 7 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_MANURE], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 8 + yOffset, self.pdaFontSize, g_i18n:getText("MaizeSilage_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 8 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_CHAFF], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 9 + yOffset, self.pdaFontSize, g_i18n:getText("GrassSilage_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 9 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_GRASS], 0)))
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 10 + yOffset, self.pdaFontSize, g_i18n:getText("Milk_storage") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 10 + yOffset, self.pdaFontSize, string.format("%1.0f", Utils.getNoNil(missionStats.farmSiloAmounts[Fillable.FILLTYPE_MILK], 0)))
      setTextColor(1, 1, 1, 1)
    elseif self.screen == 5 then
      setTextBold(true)
      setTextColor(0.8, 1, 0.9, 1)
      setTextBold(false)
      local yOffset = 0.01
      renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, g_i18n:getText("Capital") .. " [" .. g_i18n:getText("Currency_symbol") .. "]")
      renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 1 + yOffset, self.pdaFontSize, string.format("%1.0f", g_i18n:getCurrency(missionStats.money)))
      if not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission.missionDynamicInfo.isClient then
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 2.5 + yOffset, self.pdaFontSize, g_i18n:getText("Session"))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 2.5 + yOffset, self.pdaFontSize, g_i18n:getText("Total"))
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 3.5 + yOffset, self.pdaFontSize, g_i18n:getText("threshedArea") .. " [" .. g_i18n:getText("area_unit_short") .. "]")
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 3.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(g_currentMission.missionStats.hectaresThreshedSession, 0)))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 3.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(g_currentMission.missionStats.hectaresThreshedTotal, 0)))
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 4.5 + yOffset, self.pdaFontSize, g_i18n:getText("sownArea") .. " [" .. g_i18n:getText("area_unit_short") .. "]")
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 4.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(g_currentMission.missionStats.hectaresSeededSession, 0)))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 4.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(g_currentMission.missionStats.hectaresSeededTotal, 0)))
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 5.5 + yOffset, self.pdaFontSize, g_i18n:getText("Distance") .. " [" .. g_i18n:getText("Measuring_unit") .. "]")
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 5.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(missionStats.traveledDistanceSession, 0)))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 5.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(missionStats.traveledDistanceTotal, 0)))
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 6.5 + yOffset, self.pdaFontSize, g_i18n:getText("Fuel") .. " [" .. g_i18n:getText("fluid_unit_short") .. "]")
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 6.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(missionStats.fuelUsageSession, 0)))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 6.5 + yOffset, self.pdaFontSize, string.format("%.2f", Utils.getNoNil(missionStats.fuelUsageTotal, 0)))
        local playTimeHoursF = missionStats.playTime / 60 + 1.0E-4
        local playTimeHours = math.floor(playTimeHoursF)
        local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
        local playTimeSessionHoursF = missionStats.playTimeSession / 60 + 1.0E-4
        local playTimeSessionHours = math.floor(playTimeSessionHoursF)
        local playTimeSessionMinutes = math.floor((playTimeSessionHoursF - playTimeSessionHours) * 60)
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 7.5 + yOffset, self.pdaFontSize, g_i18n:getText("Duration"))
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 7.5 + yOffset, self.pdaFontSize, string.format("%02d:%02d", playTimeSessionHours, playTimeSessionMinutes))
        renderText(self.pdaCol3, self.pdaHeadRow - self.pdaRowSpacing * 7.5 + yOffset, self.pdaFontSize, string.format("%02d:%02d", playTimeHours, playTimeMinutes))
      end
      if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.deliveredBottles ~= nil and g_currentMission.sessionDeliveredBottles ~= nil then
        renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 9 + yOffset, self.pdaFontSize, g_i18n:getText("Bottles"))
        renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 9 + yOffset, self.pdaFontSize, string.format("%d", g_currentMission.deliveredBottles))
        if g_currentMission.reputation ~= nil then
          renderText(self.pdaCol1, self.pdaHeadRow - self.pdaRowSpacing * 10 + yOffset, self.pdaFontSize, g_i18n:getText("Reputation") .. " [%]")
          renderText(self.pdaCol2, self.pdaHeadRow - self.pdaRowSpacing * 10 + yOffset, self.pdaFontSize, string.format("%d", g_currentMission.reputation))
        end
      end
      setTextColor(1, 1, 1, 1)
    else
      setTextColor(0.8, 1, 0.9, 1)
      setTextBold(true)
      renderText(self.pdaUserCol[1], self.pdaHeadRow, self.pdaFontSize, g_i18n:getText("PDATitleNickname"))
      renderText(self.pdaUserCol[2], self.pdaHeadRow, self.pdaFontSize, g_i18n:getText("PDATitlePlaytime"))
      renderText(self.pdaUserCol[3], self.pdaHeadRow, self.pdaFontSize, g_i18n:getText("PDATitleLanguage"))
      setTextBold(false)
      local numUsers = table.getn(g_currentMission.users)
      for i = 1, table.getn(g_currentMission.users) do
        local playtime = g_currentMission.time - g_currentMission.users[i].connectedTime
        local playTimeHoursF = playtime / 3600000 + 1.0E-4
        local playTimeHours = math.floor(playTimeHoursF)
        local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
        local formatedPlaytime = string.format("%02d:%02d", playTimeHours, playTimeMinutes)
        local language = tostring(getLanguageName(g_currentMission.users[i].language))
        renderText(self.pdaUserCol[1], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, g_currentMission.users[i].nickname)
        renderText(self.pdaUserCol[2], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, formatedPlaytime)
        renderText(self.pdaUserCol[3], self.pdaHeadRow - self.pdaRowSpacing * i, self.pdaFontSize, language)
      end
    end
    self.hudPDAFrameOverlay:render()
    setTextBold(true)
    setTextColor(0, 0, 0, 1)
    renderText(self.pdaTitleX, self.pdaTitleY - 0.002, self.pdaTitleTextSize, self.textTitles[self.screen])
    setTextColor(1, 1, 1, 1)
    renderText(self.pdaTitleX, self.pdaTitleY, self.pdaTitleTextSize, self.textTitles[self.screen])
    setTextBold(false)
    MissionPDA.alpha = MissionPDA.alpha + MissionPDA.alphaInc
    if 1 < MissionPDA.alpha then
      MissionPDA.alphaInc = -MissionPDA.alphaInc
      MissionPDA.alpha = 1
    elseif 0 > MissionPDA.alpha then
      MissionPDA.alphaInc = -MissionPDA.alphaInc
      MissionPDA.alpha = 0
    end
  end
end
function MissionPDA:setEnvironmentTemperature(pdaWeatherTemperaturesDay, pdaWeatherTemperaturesNight)
  self.pdaWeatherTemperaturesDay = pdaWeatherTemperaturesDay
  self.pdaWeatherTemperaturesNight = pdaWeatherTemperaturesNight
end
function MissionPDA:drawMap()
  if g_currentMission.controlPlayer then
    self.playerXPos, self.playerYPos, self.playerZPos, self.pdaMapArrowRotation = self:determinePlayerPosition(g_currentMission.player)
    self.pdaMapVisWidth = self.pdaMapVisWidthMin
  else
    self.playerXPos, self.playerYPos, self.playerZPos, self.pdaMapArrowRotation = self:determineVehiclePosition(g_currentMission.controlledVehicle)
    local speed = g_currentMission.controlledVehicle.lastSpeed * g_currentMission.controlledVehicle.speedDisplayScale * 3600
    self.smoothSpeed = self.smoothSpeed * 0.95 + speed * 0.05
    local targetSize = math.max(self.smoothSpeed / 100, self.pdaMapVisWidthMin)
    local test = self.pdaMapVisWidth - targetSize
    if math.abs(test) > 0.01 then
      self.pdaMapVisWidth = self.pdaMapVisWidth - test / 32
    end
  end
  if self.isMapZoomed then
    self.pdaMapVisWidth = 1
  end
  self.playerXPos = (math.floor(self.playerXPos) + self.worldCenterOffsetX) / self.worldSizeX
  self.playerXPos = math.min(self.playerXPos, 1)
  self.playerXPos = math.max(self.playerXPos, 0)
  self.playerZPos = (math.floor(self.playerZPos) + self.worldCenterOffsetZ) / self.worldSizeZ
  self.playerZPos = math.min(self.playerZPos, 1)
  self.playerZPos = math.max(self.playerZPos, 0)
  self.pdaMapVisHeight = self.pdaMapVisWidth * self.pdaMapAspectRatio
  local leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached = self:updatePdaMapUVs()
  if self.pdaMapOverlay ~= nil then
    self.pdaMapOverlay:render()
  end
  self:setMapObjectOverlayUVs(self.pdaPlayerMapArrow, self.pdaMapArrowRotation)
  self:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
  self.pdaPlayerMapArrow:render()
  for _, player in pairs(g_currentMission.players) do
    if player.isControlled and not player.isEntered then
      local posX, posY, posZ, rotY = self:determinePlayerPosition(player)
      posX = (math.floor(posX) + self.worldCenterOffsetX) / self.worldSizeX
      posZ = (math.floor(posZ) + self.worldCenterOffsetZ) / self.worldSizeZ
      if self:setMapObjectOverlayPosition(self.pdaMapArrowRed, posX, posZ, self.pdaMapArrowRed.width, self.pdaMapArrowRed.height, true, false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached) then
        self:setMapObjectOverlayUVs(self.pdaMapArrowRed, rotY)
        self.pdaMapArrowRed:render()
      end
    end
  end
  for _, steerable in pairs(g_currentMission.steerables) do
    if steerable.isControlled and not steerable.isEntered then
      local posX, posY, posZ, rotY = self:determineVehiclePosition(steerable)
      posX = (math.floor(posX) + self.worldCenterOffsetX) / self.worldSizeX
      posZ = (math.floor(posZ) + self.worldCenterOffsetZ) / self.worldSizeZ
      if self:setMapObjectOverlayPosition(self.pdaMapArrowRed, posX, posZ, self.pdaMapArrowRed.width, self.pdaMapArrowRed.height, true, false, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached) then
        self:setMapObjectOverlayUVs(self.pdaMapArrowRed, rotY)
        self.pdaMapArrowRed:render()
      end
    end
  end
  self:renderPlayersCoordinates()
end
function MissionPDA:determinePlayerPosition(player)
  local posX, posY, posZ = getTranslation(player.rootNode)
  return posX, posY, posZ, player.rotY
end
function MissionPDA:determineVehiclePosition(steerable)
  local posX, posY, posZ = getTranslation(steerable.rootNode)
  local dx, dy, dz = localDirectionToWorld(steerable.rootNode, 0, 0, 1)
  local yRot = Utils.getYRotationFromDirection(dx, dz) + math.pi
  return posX, posY, posZ, yRot
end
function MissionPDA:renderHotspots(leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
  local minDistance = 1000000
  local closestHotspot = 0
  for k, currentHotspot in pairs(self.hotspots) do
    if currentHotspot.objectId ~= 0 then
      local objectX, objectY, objectZ = getTranslation(currentHotspot.objectId)
      currentHotspot.xMapPos = objectX + self.worldCenterOffsetX
      currentHotspot.yMapPos = objectZ + self.worldCenterOffsetZ
    end
    local objectX = currentHotspot.xMapPos / self.worldSizeX
    local objectZ = currentHotspot.yMapPos / self.worldSizeZ
    currentHotspot.visible = self:setMapObjectOverlayPosition(currentHotspot.overlay, objectX, objectZ, currentHotspot.width, currentHotspot.height, currentHotspot.enabled, currentHotspot.persistent, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
    if currentHotspot.persistent and currentHotspot.enabled then
      local deltaX = objectX - self.playerXPos
      local deltaY = objectZ - self.playerZPos
      local dist = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
      if minDistance > dist then
        closestHotspot = k
        minDistance = dist
      end
    end
  end
  for k, currentHotspot in pairs(self.hotspots) do
    if currentHotspot.persistent then
      if k == closestHotspot then
        if not currentHotspot.blinking then
          currentHotspot:setBlinking(true)
        end
      elseif currentHotspot.blinking then
        currentHotspot:setBlinking(false)
      end
    end
  end
  for k, v in pairs(self.hotspots) do
    v:render()
  end
end
function MissionPDA:setMapObjectOverlayUVs(overlay, rotation)
  self.pdaMapArrowUVs[1] = -0.5 * math.cos(-rotation) + 0.5 * math.sin(-rotation) + 0.5
  self.pdaMapArrowUVs[2] = -0.5 * math.sin(-rotation) - 0.5 * math.cos(-rotation) + 0.5
  self.pdaMapArrowUVs[3] = -0.5 * math.cos(-rotation) - 0.5 * math.sin(-rotation) + 0.5
  self.pdaMapArrowUVs[4] = -0.5 * math.sin(-rotation) + 0.5 * math.cos(-rotation) + 0.5
  self.pdaMapArrowUVs[5] = 0.5 * math.cos(-rotation) + 0.5 * math.sin(-rotation) + 0.5
  self.pdaMapArrowUVs[6] = 0.5 * math.sin(-rotation) - 0.5 * math.cos(-rotation) + 0.5
  self.pdaMapArrowUVs[7] = 0.5 * math.cos(-rotation) - 0.5 * math.sin(-rotation) + 0.5
  self.pdaMapArrowUVs[8] = 0.5 * math.sin(-rotation) + 0.5 * math.cos(-rotation) + 0.5
  setOverlayUVs(overlay.overlayId, self.pdaMapArrowUVs[1], self.pdaMapArrowUVs[2], self.pdaMapArrowUVs[3], self.pdaMapArrowUVs[4], self.pdaMapArrowUVs[5], self.pdaMapArrowUVs[6], self.pdaMapArrowUVs[7], self.pdaMapArrowUVs[8])
end
function MissionPDA:updatePdaMapUVs()
  local leftBorderReached = false
  local rightBorderReached = false
  local topBorderReached = false
  local bottomBorderReached = false
  local x = self.playerXPos
  local y = self.playerZPos
  self.pdaMapUVs[1] = x - self.pdaMapVisWidth / 2
  self.pdaMapUVs[2] = 1 - y - self.pdaMapVisHeight / 2
  self.pdaMapUVs[3] = self.pdaMapUVs[1]
  self.pdaMapUVs[4] = 1 - y + self.pdaMapVisHeight / 2
  self.pdaMapUVs[5] = x + self.pdaMapVisWidth / 2
  self.pdaMapUVs[6] = 1 - y - self.pdaMapVisHeight / 2
  self.pdaMapUVs[7] = self.pdaMapUVs[5]
  self.pdaMapUVs[8] = 1 - y + self.pdaMapVisHeight / 2
  self.pdaPlayerMapArrow.x = self.pdaMapArrowXPos
  self.pdaPlayerMapArrow.y = self.pdaMapArrowYPos
  if self.pdaMapUVs[1] < 0 then
    leftBorderReached = true
    self.pdaPlayerMapArrow.x = self.pdaMapArrowXPos + self.pdaMapWidth * self.pdaMapUVs[1] * 1 / self.pdaMapVisWidth
    if self.pdaPlayerMapArrow.x < self.pdaMapPosX - self.pdaMapArrowSize then
      self.pdaPlayerMapArrow.x = self.pdaMapPosX - self.pdaMapArrowSize
    end
    self.pdaMapUVs[1] = 0
    self.pdaMapUVs[3] = self.pdaMapUVs[1]
    self.pdaMapUVs[5] = self.pdaMapVisWidth
    self.pdaMapUVs[7] = self.pdaMapUVs[5]
  end
  if self.pdaMapUVs[1] > 1 - self.pdaMapVisWidth then
    rightBorderReached = true
    self.pdaPlayerMapArrow.x = self.pdaMapArrowXPos + self.pdaMapWidth * (self.pdaMapUVs[1] - (1 - self.pdaMapVisWidth)) * 1 / self.pdaMapVisWidth
    if self.pdaPlayerMapArrow.x > self.pdaMapPosX + self.pdaMapWidth then
      self.pdaPlayerMapArrow.x = self.pdaMapPosX + self.pdaMapWidth
    end
    self.pdaMapUVs[1] = 1 - self.pdaMapVisWidth
    self.pdaMapUVs[3] = self.pdaMapUVs[1]
    self.pdaMapUVs[5] = 1
    self.pdaMapUVs[7] = self.pdaMapUVs[5]
  end
  if self.pdaMapUVs[2] < 0 then
    bottomBorderReached = true
    self.pdaPlayerMapArrow.y = self.pdaMapArrowYPos + self.pdaMapHeight * self.pdaMapUVs[2] * 1 / self.pdaMapVisHeight
    if self.pdaPlayerMapArrow.y < self.pdaMapPosY - self.pdaMapArrowSize * 1.25 then
      self.pdaPlayerMapArrow.y = self.pdaMapPosY - self.pdaMapArrowSize * 1.25
    end
    self.pdaMapUVs[2] = 0
    self.pdaMapUVs[6] = self.pdaMapUVs[2]
    self.pdaMapUVs[4] = self.pdaMapVisHeight
    self.pdaMapUVs[8] = self.pdaMapUVs[4]
  end
  if self.pdaMapUVs[2] > 1 - self.pdaMapVisHeight then
    topBorderReached = true
    self.pdaPlayerMapArrow.y = self.pdaMapArrowYPos + self.pdaMapHeight * (self.pdaMapUVs[2] - (1 - self.pdaMapVisHeight)) * 1 / self.pdaMapVisHeight
    if self.pdaPlayerMapArrow.y > self.pdaMapPosY + self.pdaMapHeight then
      self.pdaPlayerMapArrow.y = self.pdaMapPosY + self.pdaMapHeight
    end
    self.pdaMapUVs[2] = 1 - self.pdaMapVisHeight
    self.pdaMapUVs[6] = self.pdaMapUVs[2]
    self.pdaMapUVs[4] = 1
    self.pdaMapUVs[8] = self.pdaMapUVs[4]
  end
  if self.pdaMapOverlay ~= nil then
    setOverlayUVs(self.pdaMapOverlay.overlayId, self.pdaMapUVs[1], self.pdaMapUVs[2], self.pdaMapUVs[3], self.pdaMapUVs[4], self.pdaMapUVs[5], self.pdaMapUVs[6], self.pdaMapUVs[7], self.pdaMapUVs[8])
  end
  return leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached
end
function MissionPDA:setMapObjectOverlayPosition(overlay, objectX, objectZ, width, height, enabled, persistent, leftBorderReached, rightBorderReached, topBorderReached, bottomBorderReached)
  local playerX = self.playerXPos
  local playerZ = self.playerZPos
  local halfMapWidth = self.pdaMapVisWidth * 0.5
  local halfMapHeight = self.pdaMapVisHeight * 0.5
  local visible = false
  if persistent or objectX < playerX + halfMapWidth and objectX > playerX - halfMapWidth and objectZ < playerZ + halfMapHeight and objectZ > playerZ - halfMapHeight then
    visible = true
    overlay.x = self.pdaMapPosX + self.pdaMapWidth / 2 - width / 2
    overlay.y = self.pdaMapPosY + self.pdaMapHeight / 2 - height / 2
    if not leftBorderReached and not rightBorderReached then
      overlay.x = overlay.x + (objectX - playerX) * 1 / self.pdaMapVisWidth * 0.36
    elseif leftBorderReached then
      overlay.x = overlay.x + (objectX - halfMapWidth) * 1 / self.pdaMapVisWidth * 0.36
    else
      overlay.x = overlay.x + (objectX - (1 - halfMapWidth)) * 1 / self.pdaMapVisWidth * 0.36
    end
    if not topBorderReached and not bottomBorderReached then
      overlay.y = overlay.y - (objectZ - playerZ) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
    elseif topBorderReached then
      overlay.y = overlay.y - (objectZ - halfMapHeight) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
    else
      overlay.y = overlay.y - (objectZ - (1 - halfMapHeight)) * 1 / self.pdaMapVisWidth * 0.36 * 1.3333333333333333
    end
  end
  if persistent and enabled then
    local deltaX = objectX - playerX
    local deltaY = objectZ - playerZ
    local dir = 1000000
    if math.abs(deltaY) > 1.0E-4 then
      dir = deltaX / deltaY
    end
    if overlay.y > self.pdaMapPosY + self.pdaMapHeight - height then
      overlay.y = self.pdaMapPosY + self.pdaMapHeight - height
      overlay.x = self.pdaPlayerMapArrow.x
      overlay.x = overlay.x - dir * (self.pdaMapHeight / 2 - 1.4 * height)
    end
    if overlay.y < self.pdaMapPosY - height / 4 then
      overlay.y = self.pdaMapPosY - height / 4
      overlay.x = self.pdaPlayerMapArrow.x
      overlay.x = overlay.x + dir * (self.pdaMapHeight / 2 - 1.125 * height)
    end
    if overlay.x > self.pdaMapPosX + self.pdaMapWidth - width * 0.75 then
      overlay.x = self.pdaMapPosX + self.pdaMapWidth - width * 0.75
      overlay.y = self.pdaPlayerMapArrow.y
      overlay.y = overlay.y - 1 / dir * (self.pdaMapWidth / 2 + width * 2)
      if overlay.y > self.pdaMapPosY + self.pdaMapHeight - height then
        overlay.y = self.pdaMapPosY + self.pdaMapHeight - height
      end
      if overlay.y < self.pdaMapPosY - height / 4 then
        overlay.y = self.pdaMapPosY - height / 4
      end
    end
    if overlay.x < self.pdaMapPosX - width / 4 then
      overlay.x = self.pdaMapPosX - width / 4
      overlay.y = self.pdaPlayerMapArrow.y
      overlay.y = overlay.y + 1 / dir * (self.pdaMapWidth / 2 + width * 2)
      if overlay.y > self.pdaMapPosY + self.pdaMapHeight - height then
        overlay.y = self.pdaMapPosY + self.pdaMapHeight - height
      end
      if overlay.y < self.pdaMapPosY - height / 4 then
        overlay.y = self.pdaMapPosY - height / 4
      end
    end
  end
  return visible
end
function MissionPDA:renderPlayersCoordinates()
  local renderString = "[" .. self.playerXPos * self.worldSizeX .. ", " .. self.playerZPos * self.worldSizeZ .. "]"
  setTextAlignment(RenderText.ALIGN_RIGHT)
  setTextColor(0, 0, 0, 1)
  setTextBold(true)
  renderText(self.pdaCoordsXPos, self.pdaCoordsYPos - 0.002, self.pdaFontSize, renderString)
  setTextColor(0.8, 1, 0.9, 1)
  renderText(self.pdaCoordsXPos, self.pdaCoordsYPos, self.pdaFontSize, renderString)
  setTextAlignment(RenderText.ALIGN_LEFT)
  setTextColor(1, 1, 1, 1)
  setTextBold(false)
end
function MissionPDA.tipTriggerSorter(a, b)
  return a.stationName < b.stationName
end
MapHotspot = {}
local MapHotspot_mt = Class(MapHotspot)
function MapHotspot:new(name, imageFilename, xMapPos, yMapPos, width, height, blinking, persistent, objectId)
  local tempOverlay
  if imageFilename ~= nil then
    tempOverlay = Overlay:new(name, imageFilename, 0, 0, width, height)
  end
  return setmetatable({
    overlay = tempOverlay,
    xMapPos = xMapPos,
    yMapPos = yMapPos,
    width = width,
    height = height,
    blinking = blinking,
    persistent = persistent,
    objectId = objectId,
    visible = true,
    enabled = true
  }, MapHotspot_mt)
end
function MapHotspot:delete()
  self.enabled = false
  if self.overlay ~= nil then
    self.overlay:delete()
  end
end
function MapHotspot:render()
  if self.visible and self.enabled then
    if self.blinking then
      self.overlay:setColor(1, 1, 1, MissionPDA.alpha)
    end
    self.overlay:render()
  end
end
function MapHotspot:setBlinking(blinking)
  self.blinking = blinking
  if not blinking then
    self.overlay:setColor(1, 1, 1, 1)
  end
end
