local Resolution = require("modules.resolution")

local STOPWATCH_FEEDBACK_DURATION = 0.6
local STOPWATCH_FADE_DURATION = 0.2
local STOPWATCH_OPACITY = 0.25
local STOPWATCH_SCALE = 1.35

local BattleUI = {}
BattleUI.__index = BattleUI

function BattleUI.new(battleState)
	local ui = setmetatable({}, BattleUI)
	ui.battle = battleState
	ui.stopwatchTimer = 0
	return ui
end

---@param sprite love.Image
function BattleUI:showStopwatchFeedback(sprite)
	self.stopwatchSprite = sprite
	self.stopwatchTimer = STOPWATCH_FEEDBACK_DURATION
end

function BattleUI:update(dt, musicPosition, isBattleActive)
	local battle = self.battle

	battle.beatIcon:update(musicPosition, isBattleActive)

	if battle.flashTimer and battle.flashTimer > 0 then
		battle.flashTimer = math.max(0, battle.flashTimer - dt)
	end

	self.stopwatchTimer = math.max(0, self.stopwatchTimer - dt)

	battle:verifyActionSlots()
	battle:updateActionSlots()

	for _, slot in pairs(battle.actionSlots) do
		slot:update(dt)
	end

	battle.counter:update(dt)

	for i = #battle.plusAmmoTexts, 1, -1 do
		local plus = battle.plusAmmoTexts[i]
		plus:update(dt)
		if plus.isOver then
			table.remove(battle.plusAmmoTexts, i)
		end
	end

	for _, healthBar in pairs(battle.healthBar) do
		healthBar:update(dt)
	end

	battle.actionFeedback.player:update(dt)
	battle.actionFeedback.oponent:update(dt)

	for _, text in pairs(battle.texts) do
		if text.update then
			text:update(dt)
		end
	end
	cleanUpTexts(battle.texts)
end

function BattleUI:draw()
	local battle = self.battle
	local screenW, screenH = Resolution.getUIDimensions()

	-- Ícone central e informações dos combatentes.
	battle.beatIcon:draw()
	battle.upgradesOwned.player:draw()
	battle.upgradesOwned.oponent:draw()
	battle.healthBar.player:draw()
	battle.healthBar.oponent:draw()

	-- Ações e munição.
	for _, slot in pairs(battle.actionSlots) do
		slot:draw()
	end

	local startX = battle.actionSlots[1].startX
		- battle.actionSlots[1].socket:getWidth() * battle.actionSlots[1].scale / 2
		- battle.sprites.amount:getWidth()
		- 20
	local amountX = startX
	local amountY = battle.actionSlots[1].originalPos[2] - battle.sprites.amount:getHeight() / 2 + 12
	love.graphics.draw(battle.sprites.amount, amountX, amountY, 0, 1, 1)

	local prevFont = love.graphics.getFont()
	love.graphics.setFont(battle.font)
	love.graphics.print(
		tostring(Player.ammo) .. "x",
		amountX + battle.sprites.amount:getWidth() + 5,
		amountY + battle.sprites.amount:getHeight() / 2 - battle.font:getHeight() / 2
	)
	love.graphics.setFont(prevFont)

	battle.itemSlots:draw()

	-- Textos usam suas próprias cores; nenhum shader da UI deve ser herdado aqui.
	love.graphics.setShader()

	-- Nomes e feedbacks flutuantes.
	for _, text in pairs(battle.texts) do
		if text.isShadow then
			text:draw()
		end
	end

	for _, plus in ipairs(battle.plusAmmoTexts) do
		plus:draw()
	end

	battle.actionFeedback.player:draw()
	battle.actionFeedback.oponent:draw()

	for _, text in pairs(battle.texts) do
		if not text.isShadow then
			text:draw()
		end
	end

	if battle.counter.isActive and self.stopwatchTimer > 0 then
		local sprite = self.stopwatchSprite
		local pos = battle.counter.pos
		local fade = math.min(1, self.stopwatchTimer / STOPWATCH_FADE_DURATION)
		local alpha = STOPWATCH_OPACITY * fade * fade * (3 - 2 * fade)
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.draw(sprite, pos.x, pos.y, 0, STOPWATCH_SCALE, STOPWATCH_SCALE, sprite:getWidth() / 2, sprite:getHeight() / 2)
		love.graphics.setColor(1, 1, 1, 1)
	end
	battle.counter:draw()

	-- O clarão é uma sobreposição de tela e também fica fora da câmera.
	if battle.flashTimer and battle.flashTimer > 0 then
		local alpha = math.max(0, math.min(1, battle.flashTimer / battle.flashDuration))
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setShader()
end

return BattleUI
