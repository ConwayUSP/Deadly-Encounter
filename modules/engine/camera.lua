Camera = {}
Camera.__index = Camera

function Camera.new()
  local self = setmetatable({}, Camera)

  self.x = 0
  self.y = 0

  self.rotation = 0
  self.scale = 1
  self.zoomScale = 1
  self.zoomPulseIntensity = 0
  self.zoomPulseDuration = 0
  self.zoomPulseTimer = 0

  self.shakeEnabled = true

  self.shakeIntensity = 0
  self.shakeDuration = 0
  self.shakeTimer = 0

  self.shakeX = 0
  self.shakeY = 0

  return self
end

-- Dispara um impacto curto de zoom que retorna suavemente à escala neutra.
function Camera:pulseZoom(intensity, duration)
  self.zoomPulseIntensity = intensity or 0.02
  self.zoomPulseDuration = duration or 0.25
  self.zoomPulseTimer = self.zoomPulseDuration
  self.zoomScale = 1 + self.zoomPulseIntensity
end

function Camera:resetZoom()
  self.zoomScale = 1
  self.zoomPulseIntensity = 0
  self.zoomPulseDuration = 0
  self.zoomPulseTimer = 0
end

function Camera:update(dt)
  if self.zoomPulseTimer > 0 then
    self.zoomPulseTimer = math.max(0, self.zoomPulseTimer - dt)

    local remaining = self.zoomPulseTimer / self.zoomPulseDuration
    local easedRemaining = remaining * remaining * (3 - 2 * remaining)
    self.zoomScale = 1 + self.zoomPulseIntensity * easedRemaining

    if self.zoomPulseTimer == 0 then
      self.zoomScale = 1
    end
  end

  if self.shakeTimer > 0 then
    self.shakeTimer = self.shakeTimer - dt

    self.shakeX = love.math.random(-self.shakeIntensity, self.shakeIntensity)

    self.shakeY = love.math.random(-self.shakeIntensity, self.shakeIntensity)

    if self.shakeTimer <= 0 then
      self.shakeX = 0
      self.shakeY = 0
    end
  end
end

function Camera:isShakeEnabled()
  return self.shakeEnabled
end

function Camera:toggleShake()
  self.shakeEnabled = not self.shakeEnabled
end

function Camera:shake(intensity, duration)
  if not self.shakeEnabled then
    return
  end

  self.shakeIntensity = intensity
  self.shakeDuration = duration
  self.shakeTimer = duration
end

function Camera:attach()
  love.graphics.push()

  local width, height = love.graphics.getDimensions()

  -- Aplica apenas o pulso no centro da tela e preserva as transformações
  -- já existentes da câmera.
  love.graphics.translate(width / 2, height / 2)
  love.graphics.scale(self.zoomScale, self.zoomScale)
  love.graphics.translate(-width / 2, -height / 2)

  love.graphics.translate( -self.x + self.shakeX, -self.y + self.shakeY )
  love.graphics.rotate(self.rotation)
  love.graphics.scale(self.scale, self.scale)
end

function Camera:detach()
  love.graphics.pop()
end
