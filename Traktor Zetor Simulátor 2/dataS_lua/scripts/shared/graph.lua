Graph = {}
Graph_mt = Class(Graph)
function Graph:new(numValues, left, bottom, width, height, minValue, maxValue, showLabels, textExtra)
  local self = {}
  setmetatable(self, Graph_mt)
  self.values = {}
  self.lowValues = {}
  self.numValues = numValues
  self.nextIndex = 1
  self.overlayId = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
  self.left = left
  self.bottom = bottom
  self.width = width
  self.height = height
  self.minValue = minValue
  self.maxValue = maxValue
  self.textExtra = textExtra
  self.showLabels = showLabels
  return self
end
function Graph:delete()
  delete(self.overlayId)
end
function Graph:setColor(r, g, b, a)
  setOverlayColor(self.overlayId, r, g, b, a)
end
function Graph:addValue(value, lowValue)
  self.values[self.nextIndex] = value
  self.lowValues[self.nextIndex] = lowValue
  self.nextIndex = self.nextIndex + 1
  if self.nextIndex > self.numValues then
    self.nextIndex = 1
  end
end
function Graph:draw()
  local hasValues = false
  local numFirst = self.numValues - self.nextIndex + 1
  for i = self.nextIndex, self.numValues do
    if self.values[i] ~= nil then
      self:drawValue(i - self.nextIndex, self.values[i], self.lowValues[i])
      hasValues = true
    end
  end
  for i = 1, self.nextIndex - 1 do
    if self.values[i] ~= nil then
      self:drawValue(i - 1 + numFirst, self.values[i], self.lowValues[i])
      hasValues = true
    end
  end
  if hasValues and self.showLabels then
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.left - 0.005, self.bottom, 0.025, string.format("%1.2f", self.minValue) .. self.textExtra)
    renderText(self.left - 0.005, self.bottom + self.height, 0.025, string.format("%1.2f", self.maxValue) .. self.textExtra)
    setTextAlignment(RenderText.ALIGN_LEFT)
  end
end
function Graph:drawValue(i, value, lowValue)
  local height = 0.002
  if lowValue ~= nil then
    height = self.height / (self.maxValue - self.minValue) * (value - lowValue)
  end
  if 0 < height then
    local posX = self.left + self.width / (self.numValues - 1) * i
    local posY = self.bottom + self.height / (self.maxValue - self.minValue) * (value - self.minValue) - height
    renderOverlay(self.overlayId, posX, posY, self.width / (self.numValues - 1), height)
  end
end
