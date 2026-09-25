local BattleUI = {}
BattleUI.__index = BattleUI

function BattleUI.new(battleState)
	local ui = setmetatable({}, BattleUI)
	ui.battle = battleState
	return ui
end

function BattleUI:update(dt, musicPosition, isBattleActive)
	local battle = self.battle

	battle.beatIcon:update(musicPosition, isBattleActive)

	if battle.flashTimer and battle.flashTimer > 0 then
		battle.flashTimer = math.max(0, battle.flashTimer - dt)
	end

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

	for _, text in pairs(battle.texts) do
		if text.update then
			text:update(dt)
		end
	end
	cleanUpTexts(battle.texts)
end

function BattleUI:draw()
	local battle = self.battle
	local screenH = love.graphics.getHeight()

	redBordersShader:send("playerHP", Player.hp)
	love.graphics.setShader(redBordersShader)

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
	local amountY = screenH - battle.sprites.amount:getHeight() - 60
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

	-- Nomes, ações e feedbacks flutuantes.
	for _, text in pairs(battle.texts) do
		if text.isShadow then
			text:draw()
		end
	end

	for _, plus in ipairs(battle.plusAmmoTexts) do
		plus:draw()
	end

	for _, text in pairs(battle.texts) do
		if not text.isShadow then
			text:draw()
		end
	end

	battle.counter:draw()

	-- O clarão é uma sobreposição de tela e também fica fora da câmera.
	if battle.flashTimer and battle.flashTimer > 0 then
		local alpha = math.max(0, math.min(1, battle.flashTimer / battle.flashDuration))
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), screenH)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setShader()
end

return BattleUI
