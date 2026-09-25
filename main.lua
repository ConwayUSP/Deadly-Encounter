----------------------------------------
-- Importações de Módulos
----------------------------------------
math.randomseed(os.time()) -- precisa ficar aqui no topo pra randomizar os oponentes
require("modules.actions")
require("modules.engine.camera")
require("modules.gamectx")
require("modules.gamestate")
require("modules.oponent")

Player = require("modules.player")

local GAME_WIDTH, GAME_HEIGHT = 1920, 1080
local gameCanvas

-- Todo o layout continua usando a resolução original do jogo.
love.graphics.getWidth = function() return GAME_WIDTH end
love.graphics.getHeight = function() return GAME_HEIGHT end
love.graphics.getDimensions = function() return GAME_WIDTH, GAME_HEIGHT end

local function getViewport()
	local screenW, screenH = love.window.getMode()
	local scale = math.min(screenW / GAME_WIDTH, screenH / GAME_HEIGHT)
	return scale, (screenW - GAME_WIDTH * scale) / 2, (screenH - GAME_HEIGHT * scale) / 2
end

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
	gameCanvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)
	gameCanvas:setFilter("linear", "linear")

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
	love.graphics.setCanvas(gameCanvas)
		love.graphics.clear(0, 0, 0)
		camera:attach()
			GAMESTATE[GameCtx]:draw()
		camera:detach()
		if GAMESTATE[GameCtx].drawUI then
			GAMESTATE[GameCtx]:drawUI()
		end
		MainTransition:draw()
	love.graphics.setCanvas()

	local scale, x, y = getViewport()
	love.graphics.clear(0, 0, 0)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(gameCanvas, x, y, 0, scale, scale)
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end

	if MainTransition.isActive then return end

	if key == "s" then
		SetGameCtx(CTX.SHOP)
	end

	GAMESTATE[GameCtx]:keypressed(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch, presses)
    if MainTransition.isActive then return end
	local scale, offsetX, offsetY = getViewport()
	x, y = (x - offsetX) / scale, (y - offsetY) / scale

    if GAMESTATE[GameCtx].mousepressed then
        GAMESTATE[GameCtx]:mousepressed(x, y, button, istouch)
    end
end
