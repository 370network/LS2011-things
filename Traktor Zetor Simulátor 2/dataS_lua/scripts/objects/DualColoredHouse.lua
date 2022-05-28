DualColoredHouse = {}
local DualColoredHouse_mt = Class(DualColoredHouse)
function DualColoredHouse:onCreate(id)
  g_currentMission:addUpdateable(DualColoredHouse:new(id))
end
function DualColoredHouse:new(name)
  local instance = {}
  setmetatable(instance, DualColoredHouse_mt)
  local numChildren = getNumOfChildren(name)
  local lods = {}
  for i = 0, numChildren - 1 do
    table.insert(lods, getChildAt(name, i))
  end
  instance.me = name
  local colors1 = {}
  local colors2 = {}
  local xmlFileName = Utils.getNoNil(getUserAttribute(name, "xmlFile"), "")
  local xmlFile = loadXMLFile("colors.xml", xmlFileName)
  local i = 0
  while true do
    local key = string.format("colors.color(%d)", i)
    local colorName = getXMLString(xmlFile, key .. "#colorName")
    local rgb1 = getXMLString(xmlFile, key .. "#color1")
    local rgb2 = getXMLString(xmlFile, key .. "#color2")
    if rgb1 == nil or rgb2 == nil then
      break
    end
    local r1, g1, b1 = Utils.getVectorFromString(rgb1)
    local r2, g2, b2 = Utils.getVectorFromString(rgb2)
    if r1 ~= nil and g1 ~= nil and b1 ~= nil then
      table.insert(colors1, {
        r = r1,
        g = g1,
        b = b1,
        colorName = colorName
      })
    end
    if r2 ~= nil and g2 ~= nil and b2 ~= nil then
      table.insert(colors2, {
        r = r2,
        g = g2,
        b = b2,
        colorName = colorName
      })
    end
    i = i + 1
  end
  delete(xmlFile)
  local colorIndex = math.random(1, table.getn(colors1))
  for i = 1, numChildren do
    setShaderParameter(lods[i], "color1", colors1[colorIndex].r, colors1[colorIndex].g, colors1[colorIndex].b, 0, false)
    setShaderParameter(lods[i], "color2", colors2[colorIndex].r, colors2[colorIndex].g, colors2[colorIndex].b, 0, false)
  end
  return instance
end
function DualColoredHouse:delete()
end
function DualColoredHouse:update(dt)
end
