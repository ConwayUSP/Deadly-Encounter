----------------------------------------
-- Importações de Módulos
----------------------------------------
require("modules.engine.animation")
require("modules.constructors.oponents")
require("modules.inventory")
require("modules.combat")

----------------------------------------
-- Classe Oponente
----------------------------------------

Oponent = {}
Oponent.__index = Oponent

Oponent.dmgTimer = 0
Oponent.shakeX = 0
Oponent.shakeY = 0

Oponent.TRANSITION_DUR = 0.15

function Oponent.new(name, maxHP, maxCounters, items, upgrades, strategyFunc, attackVariation, heavyAttackVariation)
	local oponent = setmetatable({}, Oponent)

	oponent.name = name
	oponent.maxHp = maxHP
	oponent.hp = maxHP
	oponent.maxCounters = maxCounters
	oponent.counters = maxCounters
	oponent.defCount = 0
	oponent.dmgMult = 1
	oponent.makeDecision = strategyFunc
	oponent.ammo = 0
	oponent.inventory = Inventory.new(items, upgrades)
	oponent.action = ACTION.NONE
	oponent.prevAction = ACTION.NONE
	oponent.actionTimer = Oponent.TRANSITION_DUR
	oponent.isTransitioning = false
	oponent.scaleX = 1
	oponent.blinkDuration = 2
	oponent.blinkTimer = 0
	oponent.dmgTimer = 0
	initCreatureAnimations(oponent)
	Combat.assimilateAttacks(oponent, attackVariation or 2, heavyAttackVariation or 2)

	-- ativa os upgrades para o oponente já surgir buffado
	for _, upgrade in pairs(oponent.inventory.upgrades) do
		if upgrade.onStart then
			upgrade:activate(oponent)
		end
	end

	return oponent
end

function Oponent:setAction(action)
	if action == self.action then
		return
	end
	self.isTransitioning = true
	self.actionTimer = Oponent.TRANSITION_DUR
	self.prevAction = self.action
	self.action = action
end

function Oponent:update(dt)
	if self.isTransitioning then
		self.actionTimer = self.actionTimer - dt
		if self.actionTimer <= 0 then
			self.isTransitioning = false
			self.scaleX = 1
		else
			self.scaleX = self:getScaleX()
		end
	end

	
	if self.blinkTimer > 0 then
		self.blinkTimer = math.max(0, self.blinkTimer - dt)
	end

	if self.dmgTimer > 0 and self.action ~= ACTION.DEAD then
		local shakeIntensity = 4
		self.dmgTimer = self.dmgTimer - dt

		self.shakeX = love.math.random(-shakeIntensity, shakeIntensity)
    self.shakeY = love.math.random(-shakeIntensity, shakeIntensity)

    if self.dmgTimer <= 0 and self.action ~= ACTION.DEAD then
      self.shakeX = 0
      self.shakeY = 0
    end
	end
end

function Oponent:getScaleX()
	local zeroToOne = math.abs(self.actionTimer - Player.TRANSITION_DUR / 2) * 1 / (Player.TRANSITION_DUR / 2)
	return zeroToOne
end

function Oponent:hasUpgrade(upgradeId)
	for _, upgrade in pairs(self.inventory.upgrades) do
		if upgrade.id == upgradeId then
			return upgrade
		end
	end

	return nil
end

function Oponent:hasItem(itemId)
	for _, item in pairs(self.inventory.items) do
		if item.id == itemId and item.quantity > 0 then
			return true
		end
	end
	return false
end

function Oponent:getItem(buffId)
	local item = self.inventory:get(buffId, BUFF_TYPE.ITEM)
	return item
end

function Oponent:useItem(itemId)
	local item = self:getItem(itemId)
	if not item then
		return
	end

	self:useBuff(item)
end

function Oponent:useBuff(buff)
	if buff.quantity <= 0 then
		return
	end

	buff.quantity = buff.quantity - 1
	self.inventory:addToUsed(buff)
end

function Oponent:draw(pos)
	local animation
	if self.isTransitioning and self.actionTimer > self.TRANSITION_DUR / 2 then
		animation = self.animations[self.prevAction]
	else
		animation = self.animations[self.action]
	end
	local quad = animation.frames[animation.currFrame]
	local offset = {
		x = animation.frameDim.width / 2,
		y = animation.frameDim.height / 2,
	}
	local scale = 0.75
	local blinking = self.blinkTimer and self.blinkTimer > 0
	if blinking then
		local t = (self.blinkDuration or 2) - self.blinkTimer
		local phase = math.floor(t * 10) % 2
		if phase == 1 then
			return
		end
	end

		
	if self.dmgTimer > 0 and self.action ~= ACTION.DEAD then
		whiteShader:send("fillColor", {1, 1, 1, 1})
		love.graphics.setShader(whiteShader)
	end

	if self.isTransitioning and self.actionTimer > self.TRANSITION_DUR / 2 then
		love.graphics.draw(
			self.spriteSheets[self.prevAction],
			quad,
			pos[1],
			pos[2],
			0,
			self.scaleX * scale,
			scale,
			offset.x + self.shakeX,
			offset.y + self.shakeY
		)
	else
		love.graphics.draw(
			self.spriteSheets[self.action],
			quad,
			pos[1],
			pos[2],
			0,
			self.scaleX * scale,
			scale,
			offset.x + self.shakeX,
			offset.y + self.shakeY
		)
	end

	love.graphics.setShader()
	love.graphics.setColor(1, 1, 1, 1)
end

function generateOponentPool()
	local pool = {
		initJoshua(),
		initOZard(),
		initDjabo(),
		initLarry(),
		initSebastiao(),
		initAberration(),
	}

	-- randomiza a ordem dos oponentes
	for i = #pool - 1, 3, -1 do
		local j = math.random(2, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	return pool
end

return Oponent
