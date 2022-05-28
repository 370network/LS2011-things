CareerScreen = {}
CareerScreen.defaultMoney = 1000
CareerScreen.numSavegames = 6
local CareerScreen_mt = Class(CareerScreen)
function CareerScreen:new(mt)
  local self = {}
  if mt == nil then
    mt = CareerScreen_mt
  end
  setmetatable(self, mt)
  self.isMultiplayer = false
  self.selectedIndex = 6
  self.savegameTextsLeft = {}
  self.savegameTextsRight = {}
  self.savegames = {}
  self.time = 0
  for i = 1, CareerScreen.numSavegames do
    local savegame = FSCareerMissionInfo:new("", nil, i)
    savegame:loadDefaults()
    createFolder(savegame.savegameDirectory)
    local savegamePath = savegame.savegameDirectory .. "/careerSavegame.xml"
    local savegamePathTemplate = getAppBasePath() .. "profileTemplate/careerSavegameTemplate.xml"
    copyFile(savegamePathTemplate, savegamePath, false)
    local xmlFile = loadXMLFile("careerSavegameXML", savegamePath)
    local revision = getXMLInt(xmlFile, "careerSavegame#revision")
    if revision == nil or revision ~= g_careerSavegameRevision then
      copyFile(savegamePathTemplate, savegamePath, true)
      delete(xmlFile)
      xmlFile = loadXMLFile("careerSavegameXML", savegamePath)
    end
    if not savegame:loadFromXML(xmlFile, "careerSavegame") then
      savegame:loadDefaults()
    end
    table.insert(self.savegames, savegame)
  end
  return self
end
function CareerScreen:onCreateList(list)
  self.list = list
end
function CareerScreen:onCreateCareerScreen()
  self.selectedIndex = 1
  self.list:setSelectedRow(self.selectedIndex)
end
function CareerScreen:scrollListUp()
  self.list:scrollList(-1)
end
function CareerScreen:scrollListDown()
  self.list:scrollList(1)
end
function CareerScreen:onStartClick()
  if not g_isDemo then
    local savegame = self.savegames[self.selectedIndex]
    if not savegame.isValid then
      g_difficultyScreen:setReturn(self, g_gui.currentGuiName)
      g_gui:showGui("DifficultyScreen")
    else
      self:startSelectedGame()
    end
  end
end
function CareerScreen:onBackClick()
  if self.isMultiplayer then
    g_gui:showGui("MultiplayerScreen")
  else
    g_gui:showGui("MainScreen")
  end
end
function CareerScreen:onClickGame()
end
function CareerScreen:onDoubleClick()
  self:onStartClick()
end
function CareerScreen:onResetVehiclesClick()
  if self.selectedIndex > 0 then
    local yesNoDialog = g_gui:showGui("YesNoDialog")
    yesNoDialog.target:setText(g_i18n:getText("YouWantToResetVehicles"))
    yesNoDialog.target:setCallbacks(self.onYesNoResetVehicles, self)
  end
end
function CareerScreen:onDeleteClick()
  if self.selectedIndex > 0 then
    local yesNoDialog = g_gui:showGui("YesNoDialog")
    yesNoDialog.target:setText(g_i18n:getText("YouWantToDeleteThat"))
    yesNoDialog.target:setCallbacks(self.onYesNoDeleteSavegame, self)
  end
end
function CareerScreen:onYesNoResetVehicles(yes)
  if yes then
    self:resetVehiclesOfSelectedGame()
  end
  g_gui:showGui("CareerScreen")
end
function CareerScreen:onYesNoDeleteSavegame(yes)
  if yes then
    self:deleteSelectedGame()
  end
  g_gui:showGui("CareerScreen")
end
function CareerScreen:onCreateTitle(element, args)
  local index = tonumber(args)
  element:setText(g_i18n:getText("Savegame") .. " " .. index)
end
function CareerScreen:onCreateTextLeft(element, args)
  local index = tonumber(args)
  self.savegameTextsLeft[index] = element
end
function CareerScreen:onCreateTextRight(element, args)
  local index = tonumber(args)
  self.savegameTextsRight[index] = element
end
function CareerScreen:onCreateGameListItem(element, args)
  local index = tonumber(args)
  self:updateSavegameText(index)
end
function CareerScreen:onListSelectionChanged(rowIndex)
  self.selectedIndex = rowIndex
end
function CareerScreen:updateSavegameText(index)
  local savegame = self.savegames[index]
  local desc1, desc2
  if savegame.isValid then
    local timeHoursF = savegame.dayTime / 60 + 1.0E-4
    local timeHours = math.floor(timeHoursF)
    local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
    local playTimeHoursF = savegame.playTime / 60 + 1.0E-4
    local playTimeHours = math.floor(playTimeHoursF)
    local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
    desc1 = g_i18n:getText("Money") .. ":\n" .. g_i18n:getText("In_game_time") .. ":\n" .. g_i18n:getText("Duration") .. ":\n" .. g_i18n:getText("Difficulty") .. ":\n" .. g_i18n:getText("Save_date") .. ":"
    desc2 = string.format("%1.0f", g_i18n:getCurrency(savegame.money)) .. " " .. g_i18n:getText("Currency_symbol") .. "\n" .. string.format("%02d:%02d", timeHours, timeMinutes) .. " h\n" .. string.format("%02d:%02d", playTimeHours, playTimeMinutes) .. " hh:mm\n" .. g_i18n:getText("Diff" .. savegame.difficulty) .. "\n" .. savegame.saveDate
  else
    desc1 = g_i18n:getText("This_savegame_is_currently_unused")
    desc2 = ""
  end
  self.savegameTextsLeft[index]:setText(desc1)
  self.savegameTextsRight[index]:setText(desc2)
end
function CareerScreen:update(dt)
  self.time = self.time + dt
  if InputBinding.hasEvent(InputBinding.MENU_CANCEL, true) then
    self:onBackClick()
  end
end
function CareerScreen:setSelectedGameDifficulty(difficulty)
  local savegame = self.savegames[self.selectedIndex]
  savegame.difficulty = difficulty
  g_mapSelectionScreen:setReturn(self, g_gui.currentGuiName)
  g_mapSelectionScreen:setIsMultiplayer(self.isMultiplayer)
  g_gui:showGui("MapSelectionScreen")
end
function CareerScreen:setSelectedGameMap(map)
  local savegame = self.savegames[self.selectedIndex]
  savegame:setMapId(map.id)
  self:startSelectedGame()
end
function CareerScreen:startSelectedGame()
  if self.selectedIndex > 0 then
    local savegame = self.savegames[self.selectedIndex]
    if g_isDemo then
      return
    end
    local dir = savegame.savegameDirectory
    createFolder(dir)
    if not savegame.isValid or not fileExists(savegame.vehiclesXML) then
      savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
    else
      savegame.vehiclesXMLLoad = savegame.vehiclesXML
    end
    if not savegame.isValid then
      for i = 1, FruitUtil.NUM_FRUITTYPES do
        local name = FruitUtil.fruitIndexToDesc[i].name
        savegame.farmSiloAmounts[name] = (3 - savegame.difficulty) * math.random(8000, 9000)
      end
      savegame.farmSiloAmounts.liquidManure = 0
      savegame.farmSiloAmounts.manure = 0
      savegame.farmSiloAmounts.grass = 0
      savegame.farmSiloAmounts.dryGrass = 0
      savegame.farmSiloAmounts.chaff = 0
      if g_isDevelopmentVersion then
        savegame.farmSiloAmounts.liquidManure = 10000
        savegame.farmSiloAmounts.manure = 10000
      end
      savegame.money = 3000 + 1000 * 3 ^ (3 - savegame.difficulty)
    end
    local missionInfo = savegame
    local missionDynamicInfo = {}
    missionDynamicInfo.isMultiplayer = false
    missionDynamicInfo.autoSave = false
    if savegame.isValid and savegame.densityMapRevision == g_densityMapRevision then
      setTerrainLoadDirectory(missionInfo.savegameDirectory)
    else
      setTerrainLoadDirectory("")
    end
    self:onStartMission(missionInfo, missionDynamicInfo)
  end
end
function CareerScreen:onStartMission(missionInfo, missionDynamicInfo)
  if self.isMultiplayer then
    g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
    g_gui:showGui("CreateGameScreen")
  else
    g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
    g_gui:showGui("MPLoadingScreen")
    g_mpLoadingScreen:startLocal()
  end
end
function CareerScreen:deleteSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  savegame:loadDefaults()
  savegame.isValid = false
  savegame.densityMapRevision = -1
  savegame.resetVehicles = false
  savegame:saveToXML()
  self:updateSavegameText(self.selectedIndex)
end
function CareerScreen:resetVehiclesOfSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  savegame:setResetVehicles(true)
end
function CareerScreen:backupSavegame(savegame)
  if savegame.isValid then
    local backupDir = savegame.savegameDirectory .. "_autoBackup" .. savegame.autoBackupIndex
    savegame.autoBackupIndex = savegame.autoBackupIndex + 1
    if savegame.autoBackupIndex > 10 then
      savegame.autoBackupIndex = 1
    end
    createFolder(backupDir)
    local files = Files:new(savegame.savegameDirectory)
    for _, file in pairs(files.files) do
      if not file.isDirectory then
        copyFile(savegame.savegameDirectory .. "/" .. file.filename, backupDir .. "/" .. file.filename, true)
      end
    end
  end
end
function CareerScreen:saveSelectedGame()
  local savegame = self.savegames[self.selectedIndex]
  if savegame.isValid then
    self:backupSavegame(savegame)
  end
  savegame.isValid = true
  savegame.densityMapRevision = g_densityMapRevision
  savegame.resetVehicles = false
  savegame:loadFromMission(g_currentMission)
  savegame:saveToXML()
  local dir = savegame.savegameDirectory
  createFolder(dir)
  local savedDensityMaps = {}
  for index, fruit in pairs(g_currentMission.fruits) do
    if fruit.id ~= 0 then
      local filename = getDensityMapFileName(fruit.id)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.id, dir .. "/" .. filename)
      end
      saveGrowthStateToFile(fruit.id, dir .. "/" .. getName(fruit.id) .. "_growthState.xml")
    end
    if fruit.cutShortId ~= 0 then
      local filename = getDensityMapFileName(fruit.cutShortId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.cutShortId, dir .. "/" .. filename)
      end
    end
    if fruit.cutLongId ~= 0 then
      local filename = getDensityMapFileName(fruit.cutLongId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.cutLongId, dir .. "/" .. filename)
      end
    end
    if fruit.windrowId ~= 0 then
      local filename = getDensityMapFileName(fruit.windrowId)
      if savedDensityMaps[filename] == nil then
        savedDensityMaps[filename] = true
        saveDensityMapToFile(fruit.windrowId, dir .. "/" .. filename)
      end
    end
  end
  local detailFilename = getDensityMapFileName(g_currentMission.terrainDetailId)
  if savedDensityMaps[detailFilename] == nil then
    savedDensityMaps[detailFilename] = true
    saveDensityMapToFile(g_currentMission.terrainDetailId, dir .. "/" .. detailFilename)
  end
  for i = 1, table.getn(g_currentMission.dynamicFoliageLayers) do
    local id = g_currentMission.dynamicFoliageLayers[i]
    local filename = getDensityMapFileName(id)
    if savedDensityMaps[filename] == nil then
      savedDensityMaps[filename] = true
      saveDensityMapToFile(id, dir .. "/" .. filename)
    end
  end
  self:updateSavegameText(self.selectedIndex)
end
function CareerScreen:setIsMultiplayer(isMultiplayer)
  self.isMultiplayer = isMultiplayer
end
