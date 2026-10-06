-- Importações de Módulos
----------------------------------------
require("table")
require("modules.engine.text")
require("modules.utils")
require("modules.fs")
local Resolution = require("modules.resolution")

----------------------------------------
-- Entidade Final Screen (representa Victory Screen e Death Screen)
----------------------------------------

FinalScreen = {}
FinalScreen.__index = FinalScreen

function FinalScreen:new(prompt, timer)
	local screen = setmetatable({}, FinalScreen)
	local width, height = Resolution.getGameDimensions()

	screen.timer = timer or 2.5
	screen.texts = {}

	-- texto do prompt (pisca na transparência)
	screen.texts.prompt = Text.new(
		prompt,
		32,
		{ 1, 1, 1, 0 },
		{ width / 2, height * 0.75 },
		0,
		true,
		math.huge,
		function(text, dt)
			text.time = (text.time or 0) + dt
			local alpha = 0.5 * math.sin(text.time * 4)
			text.color[4] = alpha
		end
	)

	return screen
end

function FinalScreen:update(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	end

	self.texts.prompt:update(dt)
end

function FinalScreen:draw()
	self.texts.prompt:draw()

	-- reset de cor
	love.graphics.setColor(1, 1, 1, 1)
end

function FinalScreen:keypressed(key, scancode, isrepeat)
	if key == "return" or key == "space" then
		SetGameCtx(CTX.MENU)
	end
end

return FinalScreen
