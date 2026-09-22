----------------------------------------
-- Importações de Módulos
----------------------------------------
require("modules.engine.text")
require("modules.fs")
require("modules.utils")

----------------------------------------
-- Estado do Menu
----------------------------------------

local MenuState = {}
MenuState.__index = MenuState

MenuState.sprites = {}
MenuState.texts = {}

MenuState.titleFont = nil
MenuState.promptFont = nil
MenuState.sounds = {}
MenuState.timer = 0
MenuState.logoScale = 0
MenuState.musicTimer = 2.5
MenuState.isFirstRender = true

function MenuState:load()
	local width, height = love.graphics.getDimensions()
	
	for _, gameState in pairs(GAMESTATE) do
		if gameState.restartGame then
			gameState:restartGame()
		end
	end

	self.logoScale = 0

	-- sprites
	self.sprites.bg = love.graphics.newImage("assets/UI/menu/menu_bg.png")
	self.sprites.logo = love.graphics.newImage("assets/UI/menu/logo.png")

	-- texto do prompt
	self.texts.prompt = Text.new(
		"Press Enter or Space to Play",
		36,
		{ 1, 1, 1, 1 },
		{ width / 2, height * 0.9 },
		0,
		true,
		math.huge,
		function(text, dt)
			text.time = (text.time or 0) + dt
			local alpha = 0.5 + 0.5 * math.sin(text.time * 4)
			text.color[4] = alpha
		end
	)

	-- sounds
	self.sounds.start = love.audio.newSource("sounds/start.mp3", "static")
	self.sounds.start:setVolume(0.5)

	self.sounds.bg = love.audio.newSource("sounds/menu_bg.wav", "static")
	self.sounds.bg:setLooping(true)
	self.sounds.bg:setVolume(0.25)

	if self.isFirstRender then
		self.sounds.deadly_encounter = love.audio.newSource("sounds/deadly_encounter.mp3", "static")
		self.sounds.deadly_encounter:play()
		self.isFirstRender = false
	else
		self.sounds.bg:play()
	end
end

function MenuState:update(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
		if self.timer <= 0 then
			local tutorial = GAMESTATE[CTX.TUTORIAL]
			SetGameCtx(tutorial:hasBeenSeen() and CTX.BATTLE or CTX.TUTORIAL)
		end
	end

	if self.musicTimer > 0 then
		self.musicTimer = self.musicTimer - dt
		if self.musicTimer <= 0 then
			self.sounds.bg:play()
		end
	end

	local maxLogoScale = 0.8
	local speed = 3
	if self.logoScale < maxLogoScale then
		self.logoScale = self.logoScale + (maxLogoScale - self.logoScale) * (1 - math.exp(-speed * dt))
		if self.logoScale > maxLogoScale then
			self.logoScale = maxLogoScale
		end
	end

	self.timeCount = (self.timeCount or 0) + dt
	self.logoRotation = math.sin(self.timeCount * 2) * 0.02

	self.texts.prompt:update(self.timer > 0 and 6 * dt or dt)

	cleanUpTexts(self.texts)
end

function MenuState:draw()
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

		-- background
	local bg = self.sprites.bg
	local bgW, bgH = bg:getWidth(), bg:getHeight()
	local scale = math.max(screenW / bgW, screenH / bgH)
	local drawX = (screenW - bgW * scale) / 2
	local drawY = (screenH - bgH * scale) / 2
	love.graphics.draw(bg, drawX, drawY, 0, scale, scale)

	-- logo
	local logo = self.sprites.logo
	local logoW, logoH = logo:getWidth(), logo:getHeight()
	love.graphics.draw(self.sprites.logo, screenW / 2, screenH * 0.2, self.logoRotation, self.logoScale, self.logoScale, logoW / 2, logoH / 2)

	for key, text in pairs(self.texts) do
		text:draw()
	end

	-- reset de cor
	love.graphics.setColor(1, 1, 1, 1)
end

function MenuState:keypressed(key, scancode, isrepeat)
	if key == "return" or key == "space" then
		if self.timer <= 0 then
			self.timer = 1.75
			self.sounds.bg:stop()
			self.sounds.start:play()
		end
	end
end

function MenuState:mousepressed(x, y, button, istouch)
    if button == 1 then
        self:keypressed("return") -- reaproveita a lógica do teclado
    end
end

return MenuState
