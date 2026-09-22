function returnFont(size)
  local path = "assets/fonts/"
  local name = "Cute Dino"
  local fontPath = path .. name .. ".ttf"

  if love.filesystem.getInfo(fontPath) then
    return love.graphics.newFont(fontPath, size)
  else
    return love.graphics.newFont(size)
  end
end

function capitalize(string)
  return string:gsub("^%l", string.upper)
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