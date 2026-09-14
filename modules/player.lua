----------------------------------------
-- Importações de Módulos
----------------------------------------
require("table")
require("modules.engine.animation")
require("modules.inventory")
require("modules.combat")

----------------------------------------
-- Entidade Player
----------------------------------------

Player = {}
Player.__index = Player

Player.TRANSITION_DUR = 0.15

Player.name = "you"
Player.maxHp = 200
Player.hp = Player.maxHp
Player.maxCounters = 3
Player.counters = Player.maxCounters
Player.ammo = 0
Player.defCount = 0
Player.dmgMult = 1
Player.action = ACTION.NONE
Player.prevAction = ACTION.NONE
Player.actionTimer = Player.TRANSITION_DUR
Player.isTransitioning = false
Player.scaleX = 1
Player.inventory = Inventory.new()
Player.blinkDuration = 2
Player.blinkTimer = 0
Player.dmgTimer = 0
Player.shakeX = 0
Player.shakeY = 0
initCreatureAnimations(Player)
Combat.assimilateAttacks(Player, 1, 1)

function Player:reset()
	Player.hp = Player.maxHp
	Player.maxCounters = 3
	Player.counters = Player.maxCounters
	Player.ammo = 0
	Player.defCount = 0
	Player.dmgMult = 1
	Player.action = ACTION.NONE
	Player.inventory = Inventory.new()
	Player.blinkTimer = 0
end

function Player:setAction(action)
	if action == self.action then
		return
	end
	self.isTransitioning = true
	self.actionTimer = Player.TRANSITION_DUR
	self.prevAction = self.action
	self.action = action
end

function Player:getScaleX()
	local zeroToOne = math.abs(self.actionTimer - Player.TRANSITION_DUR / 2) * 1 / (Player.TRANSITION_DUR / 2)
	return zeroToOne
end

function Player:update(dt)
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

	if self.dmgTimer > 0 then
		local shakeIntensity = 4
		self.dmgTimer = self.dmgTimer - dt

		self.shakeX = love.math.random(-shakeIntensity, shakeIntensity)
    self.shakeY = love.math.random(-shakeIntensity, shakeIntensity)

    if self.dmgTimer <= 0 then
      self.shakeX = 0
      self.shakeY = 0
    end
	end
end

function Player:resetForBattle()
	self.hp = self.maxHp
	self.maxCounters = 3
	self.counters = self.maxCounters
	self.ammo = 0
	self.defCount = 0
	self.dmgMult = 1
	self.action = ACTION.NONE
	self.blinkTimer = 0

	for _, upgrade in pairs(self.inventory.upgrades) do
		if upgrade.onStart then
			upgrade:activate(self)
		end
	end

	for _, item in pairs(self.inventory.items) do
		item.quantity = item.initialQuantity
	end
end

function Player:hasUpgrade(upgradeId)
	for _, upgrade in pairs(self.inventory.upgrades) do
		if upgrade.id == upgradeId then
			return upgrade
		end
	end

	return nil
end

function Player:getBuff(buff)
	self.inventory:insert(buff)
end

function Player:useBuff(buff)
	if buff.quantity <= 0 then
		return
	end

	buff.quantity = buff.quantity - 1
	self.inventory:addToUsed(buff)
end

function Player:draw(pos)
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

return Player
