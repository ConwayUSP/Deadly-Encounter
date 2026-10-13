----------------------------------------
-- Importações de Módulos
----------------------------------------
math.randomseed(os.time()) -- precisa ficar aqui no topo pra randomizar os oponentes
require("modules.actions")
require("modules.engine.camera")
require("modules.gamectx")
require("modules.gamestate")
require("modules.oponent")
require("modules.utils")

Player = require("modules.player")

local Resolution = require("modules.resolution")
local GAME_WIDTH, GAME_HEIGHT = Resolution.getGameDimensions()
local gameCanvas
local uiCanvas

GameCtx = CTX.MENU
camera = Camera.new()

local Transition = require("modules.engine.transition")
MainTransition = Transition.new(0.5, Transition.FADEINOUT)

-- Função auxiliar para trocar de contexto e carregar o novo estado
function SetGameCtx(newCtx)
	local sounds = GAMESTATE[GameCtx].sounds
	if sounds then
		for _, sound in pairs(sounds) do
			sound:stop()
		end
	end
	camera:resetZoom()

	MainTransition:start(function()
		GameCtx = newCtx
		GAMESTATE[GameCtx]:load()
	end)
end

function love.load()
	Resolution.setUIScale(isMobile() and 1.25 or 1.0)
	local uiW, uiH = Resolution.getUIDimensions()
	gameCanvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT, { dpiscale = 1 })
	uiCanvas = love.graphics.newCanvas(math.floor(uiW + 0.5), math.floor(uiH + 0.5), { dpiscale = 1 })
	gameCanvas:setFilter("linear", "linear")
	uiCanvas:setFilter("linear", "linear")

	-- carrega o estado inicial manualmente para usar uma transição
	GAMESTATE[GameCtx]:load()
end

function love.update(dt)
	MainTransition:update(dt)
	-- do not update the scene while transition is running
	if MainTransition.isActive then
		return
	end
	
	GAMESTATE[GameCtx]:update(dt)
	camera:update(dt)	
end

function love.draw()
	local gameState = GAMESTATE[GameCtx]

	love.graphics.setCanvas(gameCanvas)
		love.graphics.clear(0, 0, 0)
		camera:attach()
			gameState:draw()
		camera:detach()
	love.graphics.setCanvas()

	love.graphics.setCanvas(uiCanvas)
	love.graphics.clear(0, 0, 0, 0)
	if gameState.drawUI then
		gameState:drawUI()
	end
	love.graphics.setCanvas()

	local scale, x, y = Resolution.getViewport()
	local uiScale = Resolution.getUIScale()
	local postProcessShader = gameState.getPostProcessShader and gameState:getPostProcessShader() or nil
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setShader(postProcessShader)
	love.graphics.draw(gameCanvas, x, y, 0, scale, scale)
	love.graphics.setShader()
	love.graphics.draw(uiCanvas, x, y, 0, scale * uiScale, scale * uiScale)
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.scale(scale, scale)
	MainTransition:draw()
	love.graphics.pop()
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end

	if MainTransition.isActive then return end

	-- if key == "s" then
	-- 	SetGameCtx(CTX.SHOP)
	-- end

	GAMESTATE[GameCtx]:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch, presses)
	if MainTransition.isActive then return end

	local gameState = GAMESTATE[GameCtx]
	local inputX, inputY = Resolution.toGameCoordinates(x, y)
	if not inputX then return end

	if gameState.uiMousepressed then
		inputX, inputY = Resolution.toUICoordinates(x, y)
		gameState:uiMousepressed(inputX, inputY, button, istouch)
	elseif gameState.mousepressed then
		gameState:mousepressed(inputX, inputY, button, istouch)
    end
end
