local fontCache = {}

-- Resolve o tamanho da fonte com base no OS
-- Mobile ganha scaling de 1.25 (16 -> 24, 24 -> 30, 32 -> 40, 36 -> 45) para fontes de até 36px
local function resolveFontSize(size)
    if not isMobile() or size >= 48 then
        return size
    end
    return math.max(24, math.floor(size * 1.25 + 0.5))
end

function returnFont(size)
  size = resolveFontSize(size)
  if fontCache[size] then
    return fontCache[size]
  end

  local fontPath = "assets/fonts/Cute Dino.ttf"
  local font = love.filesystem.getInfo(fontPath) and love.graphics.newFont(fontPath, size) or love.graphics.newFont(size)
  fontCache[size] = font
  return font
end

function capitalize(string)
  return string:gsub("^%l", string.upper)
end

function isMobile()
    local os = love.system.getOS()
    return os == "Android" or os == "iOS"
end


-- Chooses from a list of items using their respective weights
function weightedChoice(items)
    local total = 0
    for _, item in ipairs(items) do
        total = total + item.weight
    end

    -- probability
    local p = math.random() * total

    for _, item in ipairs(items) do
        if p < item.weight then
            return item.value
        end
        p = p - item.weight
    end
end

-- Get the id in a table from a value
function getIdFromValue(value, table)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
end

function isPointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= (rx + rw) and py >= ry and py <= (ry + rh)
end
