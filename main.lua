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

local Resolution = require("modules.resolution")
local GAME_WIDTH, GAME_HEIGHT = Resolution.getGameDimensions()
local gameCanvas

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

	local scale, x, y = Resolution.getViewport()
	love.graphics.clear(0, 0, 0, 1)
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
	local gameX, gameY = Resolution.toGameCoordinates(x, y)
	if not gameX then return end

    if GAMESTATE[GameCtx].mousepressed then
        GAMESTATE[GameCtx]:mousepressed(gameX, gameY, button, istouch)
    end
end
