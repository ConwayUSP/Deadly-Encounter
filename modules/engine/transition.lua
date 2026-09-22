----------------------------------------
-- Importações de Módulos
----------------------------------------

require("modules.utils")

----------------------------------------
-- Classe Transition
----------------------------------------


local Transition = {}
Transition.__index = Transition

Transition.FADEINOUT = "fadeinout"

function Transition.new(duration, type)
    local self = setmetatable({}, Transition)

    self.duration = duration or 0.5
    self.type = type or Transition.SLIDE_LEFT

    -- time elapsed since the animation has started
    self.elapsed = 0
    self.isActive = false
    self.progress = 0 -- progress of the transition
    self.onComplete = nil -- function to call on completion
    self.callbackTriggered = false

    return self
end

-- start the transition
function Transition:start(onComplete)
    -- enable activity and reset elapsed
    self.elapsed = 0
    self.isActive = true
    self.onComplete = onComplete
    self.callbackTriggered = false
end


function Transition:update(dt)
    -- transition disabled do nothing
    if not self.isActive then return end

    -- increase progress
    self.elapsed = self.elapsed + dt
    self.progress = math.min(self.elapsed / self.duration, 1)

    if self.type == Transition.FADEINOUT then
        -- load the scene at half so the fadeout effect works
        if self.progress >= 0.5 and not self.callbackTriggered then
            self.callbackTriggered = true
            if self.onComplete then self.onComplete() end
        end
    else
        -- Only loads the scene if the effect ended
        if self.progress == 1 and not self.callbackTriggered then
            self.callbackTriggered = true
            if self.onComplete then
				self.onComplete()
			end
		end
	end
    -- if completed deactivate
    if self.progress == 1 then
        self.isActive = false
    end
end

function Transition:draw()
	if not self.isActive or self.elapsed <= 0 then return end

	if self.type == Transition.SLIDE_LEFT then
		self:drawSlideLeft()
    elseif self.type == Transition.FADEINOUT then
        self:drawFadeInOut()
	end
end

-- Slide a Rectangle from right to left
function Transition:drawSlideLeft()
    local width = love.graphics.getWidth()
    local offset = width * self.progress

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", width - offset, 0, offset, love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
end

function Transition:drawFadeInOut()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local alpha = -4 * self.progress ^ 2 + 4 * self.progress
    -- local alpha = self.progress

    love.graphics.setColor(0, 0, 0, alpha) -- increase transparency
    love.graphics.rectangle("fill", 0, 0, width, love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)

end

return Transition
