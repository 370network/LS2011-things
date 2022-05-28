MapsUtil = {}
MapsUtil.mapList = {}
MapsUtil.idToMap = {}
function MapsUtil.addMapItem(id, scriptFilename, className, briefingImagePrefix, briefingTextPrefix, defaultVehiclesXMLFilename, title, description, iconFilename, baseDirectory, customEnvironment)
  assert(MapsUtil.idToMap[id] == nil, "Map ids need to be unique (" .. id .. ")")
  local item = {}
  item.id = tostring(id)
  item.scriptFilename = scriptFilename
  item.className = className
  item.briefingImagePrefix = briefingImagePrefix
  item.briefingTextPrefix = briefingTextPrefix
  item.defaultVehiclesXMLFilename = defaultVehiclesXMLFilename
  item.title = title
  item.description = description
  item.iconFilename = iconFilename
  item.baseDirectory = baseDirectory
  item.customEnvironment = customEnvironment
  table.insert(MapsUtil.mapList, item)
  MapsUtil.idToMap[id] = item
end
function MapsUtil.getMapById(id)
  return MapsUtil.idToMap[id]
end
