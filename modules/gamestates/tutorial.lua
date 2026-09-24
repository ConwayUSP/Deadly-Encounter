----------------------------------------
-- Importacoes de Modulos
----------------------------------------
require("modules.engine.text")
require("modules.utils")

----------------------------------------
-- Estado do Tutorial
----------------------------------------

local TutorialState = {}
TutorialState.__index = TutorialState

TutorialState.sprites = {}
TutorialState.texts = {}
TutorialState.seenThisSession = false
TutorialState.isLeaving = false

function TutorialState:hasBeenSeen()
	return self.seenThisSession
end

function TutorialState:load()
	local width, height = love.graphics.getDimensions()

	self.isLeaving = false
	self.sprites.bg = love.graphics.newImage("assets/UI/tutorial/tutorial.jpg")

	self.texts.prompt = Text.new(
		"Press any key to continue",
		32,
		{ 0, 0, 0, 1 },
		{ width / 2, 80 },
		0,
		false,
		math.huge,
		function(text, dt)
			text.time = (text.time or 0) + dt
			text.color[4] = 0.5 + 0.5 * math.sin(text.time * 4)
		end,
		width / 2 - 80
	)
	self.texts.prompt.align = "right"
end

function TutorialState:update(dt)
	self.texts.prompt:update(dt)
end

function TutorialState:draw()
	local screenW, screenH = love.graphics.getDimensions()
	local bg = self.sprites.bg

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(bg, 0, 0, 0, screenW / bg:getWidth(), screenH / bg:getHeight())
	self.texts.prompt:draw()
	love.graphics.setColor(1, 1, 1, 1)
end

function TutorialState:continueToGame()
	if self.isLeaving then return end

	self.isLeaving = true
	self.seenThisSession = true
	SetGameCtx(CTX.BATTLE)
end

function TutorialState:keypressed(key, scancode, isrepeat)
	self:continueToGame()
end

function TutorialState:mousepressed(x, y, button, istouch)
	if button == 1 then
		self:continueToGame()
	end
end

return TutorialState
