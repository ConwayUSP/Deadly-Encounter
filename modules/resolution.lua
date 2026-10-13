local Resolution = {}

local GAME_WIDTH = 1920
local GAME_HEIGHT = 1080
local UI_SCALE = 1

-- Dimensões lógicas usadas por todo o layout do jogo.
function Resolution.getGameWidth()
	return GAME_WIDTH
end

function Resolution.getGameHeight()
	return GAME_HEIGHT
end

function Resolution.getGameDimensions()
	return GAME_WIDTH, GAME_HEIGHT
end

function Resolution.setUIScale(scale)
	UI_SCALE = math.max(1, math.min(scale or 1, 1.35))
end

function Resolution.getUIScale()
	return UI_SCALE
end

function Resolution.getUIWidth()
	return GAME_WIDTH / UI_SCALE
end

function Resolution.getUIHeight()
	return GAME_HEIGHT / UI_SCALE
end

function Resolution.getUIDimensions()
	return Resolution.getUIWidth(), Resolution.getUIHeight()
end

function Resolution.getGameAspectRatio()
	return GAME_WIDTH / GAME_HEIGHT
end

function Resolution.getScreenDimensions()
	return love.graphics.getDimensions()
end

-- Área realmente utilizável da tela. Em dispositivos móveis, exclui regiões
-- ocupadas por notch, câmera ou elementos permanentes do sistema.
function Resolution.getSafeArea()
	local screenW, screenH = Resolution.getScreenDimensions()
	local os = love.system.getOS()

	if os == "Android" or os == "iOS" then
		local x, y, width, height = love.window.getSafeArea()
		if width > 0 and height > 0 then
			return x, y, width, height
		end
	end

	return 0, 0, screenW, screenH
end

-- Calcula um viewport contain: preserva 16:9 e mantém todo o jogo visível.
function Resolution.getViewport()
	local safeX, safeY, safeW, safeH = Resolution.getSafeArea()
	local scale = math.min(safeW / GAME_WIDTH, safeH / GAME_HEIGHT)
	local viewportW = GAME_WIDTH * scale
	local viewportH = GAME_HEIGHT * scale
	local offsetX = safeX + (safeW - viewportW) / 2
	local offsetY = safeY + (safeH - viewportH) / 2

	return scale, offsetX, offsetY, viewportW, viewportH
end

-- Converte entrada física (mouse/toque) para a resolução lógica do jogo.
function Resolution.toGameCoordinates(x, y)
	local scale, offsetX, offsetY = Resolution.getViewport()
	local gameX = (x - offsetX) / scale
	local gameY = (y - offsetY) / scale

	if gameX < 0 or gameX > GAME_WIDTH or gameY < 0 or gameY > GAME_HEIGHT then
		return nil, nil
	end

	return gameX, gameY
end

function Resolution.toUICoordinates(x, y)
	local gameX, gameY = Resolution.toGameCoordinates(x, y)
	if not gameX then return nil, nil end
	return gameX / UI_SCALE, gameY / UI_SCALE
end

function Resolution.toScreenCoordinates(x, y)
	local scale, offsetX, offsetY = Resolution.getViewport()
	return offsetX + x * scale, offsetY + y * scale
end

return Resolution
