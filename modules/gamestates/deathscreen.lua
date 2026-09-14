local FinalScreen = require("modules.gamestates.finalscreen")

local DeathState = {}
DeathState.__index = DeathState

DeathState.sprites = {}
DeathState.texts = {}
DeathState.sounds = {}
DeathState.screen = nil

function DeathState:load()
	self.texts = {
		prompt = "Press Enter or Space to Try Again",
	}
	self.timer = 2
	self.readyToPlay = false

	-- sprites
	self.screen = FinalScreen:new(self.texts.prompt, self.timer)
	self.sprites.bg = love.graphics.newImage("assets/UI/death/death_bg.png")

	-- sounds
	self.sounds.bg = love.audio.newSource("sounds/death_music.mp3", "static")
	self.sounds.bg:setLooping(true)
	self.sounds.merreu = love.audio.newSource("sounds/merreu.mp3", "static")
	self.sounds.merreu:play()
end

function DeathState:update(dt)
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

function DeathState:draw()
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

function DeathState:keypressed(key, scancode, isrepeat)
	if self.readyToPlay then
		self.screen:keypressed(key, scancode, isrepeat)
	end
end

function DeathState:mousepressed(x, y, button, istouch)
    if button == 1 and self.readyToPlay then
        self.screen:keypressed("return")
    end
end

return DeathState
