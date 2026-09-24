local FinalScreen = require("modules.gamestates.finalscreen")

local VictoryState = {}
VictoryState.__index = VictoryState

VictoryState.sprites = {}
VictoryState.texts = {}
VictoryState.sounds = {}
VictoryState.screen = nil

function VictoryState:load()
	self.texts = {
		prompt = isMobile() and "Tap to Play Again" or "Press Enter or Space to Play Again"
	}
	self.timer = 7
	self.readyToPlay = false

	-- sprites
	self.screen = FinalScreen:new(self.texts.prompt, self.timer)
	self.sprites.bg = love.graphics.newImage("assets/UI/victory/victory_bg.png")

	-- sounds
	self.sounds.bg = love.audio.newSource("sounds/victory_bg.mp3", "static")
	self.sounds.bg:setLooping(true)
	self.sounds.vitoria = love.audio.newSource("sounds/victory_crowd.mp3", "static")
	self.sounds.vitoria:play()
end

function VictoryState:update(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.readyToPlay = true
		end
	end

	if self.readyToPlay and not self.sounds.bg:isPlaying() then
		self.sounds.bg:play()
	end

	self.screen:update(dt)
end

function VictoryState:draw()
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

	-- background
	local bg = self.sprites.bg
	local bgW, bgH = bg:getWidth(), bg:getHeight()
	local scale = math.max(screenW / bgW, screenH / bgH)
	local drawX = (screenW - bgW * scale) / 2
	local drawY = (screenH - bgH * scale) / 2
	love.graphics.draw(bg, drawX, drawY, 0, scale, scale)

	self.screen:draw()
end

function VictoryState:keypressed(key, scancode, isrepeat)
	if self.readyToPlay then
		self.screen:keypressed(key, scancode, isrepeat)
	end
end

function VictoryState:mousepressed(x, y, button, istouch)
    if button == 1 and self.readyToPlay then
        self.screen:keypressed("return")
    end
end

return VictoryState
