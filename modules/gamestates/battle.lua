----------------------------------------
-- Importações de módulos
----------------------------------------
require("modules.oponent")
require("modules.utils")
require("modules.shaders")
require("modules.history")
require("modules.combat")
require("modules.actions")
require("modules.fs")

----------------------------------------
-- Entidade ItemsSlot
----------------------------------------

ItemSlot = {}
ItemSlot.__index = ItemSlot

function ItemSlot.new(items, scale, pos)
	local slot = setmetatable({}, ItemSlot)
	slot.items = items
	slot.scale = scale
	slot.pos = pos

	slot.socket = love.graphics.newImage("assets/UI/combat/consumables_socket.png")
	slot.font = returnFont(24)

	return slot
end

function ItemSlot:draw()
	love.graphics.setColor(1, 1, 1, 1)

	local socketW = self.socket:getWidth() * self.scale
	local socketH = self.socket:getHeight() * self.scale

	love.graphics.draw(self.socket, self.pos[1] - socketW / 2, self.pos[2] - socketH / 2, 0, self.scale, self.scale)
	love.graphics.setFont(self.font)

	local itemScale = 0.25
	if self.items[3] then
		local item = self.items[3]

		if item.quantity > 0 then
			local itemSprite = item.sprite
			local itemW = itemSprite:getWidth() * itemScale
			local itemH = itemSprite:getHeight() * itemScale
			local posX = self.pos[1] + socketW / 4 - itemW / 2 - 8
			local posY = self.pos[2] - itemH / 2
			love.graphics.draw(itemSprite, posX, posY, 0, itemScale, itemScale)
			love.graphics.print(tostring(item.quantity) .. "x", posX, posY, 0, 0.5)
		end
	end

	if self.items[1] then
		local item = self.items[1]

		if item.quantity > 0 then
			local itemSprite = item.sprite
			local itemW = itemSprite:getWidth() * itemScale
			local itemH = itemSprite:getHeight() * itemScale
			local posX = self.pos[1] - socketW / 4 - itemW / 2 + 4
			local posY = self.pos[2] - itemH / 2 - socketH / 4 + 8
			love.graphics.draw(itemSprite, posX, posY, 0, itemScale, itemScale)
			love.graphics.print(tostring(item.quantity) .. "x", posX, posY, 0, 0.5)
		end
	end

	if self.items[2] then
		local item = self.items[2]

		if item.quantity > 0 then
			local itemSprite = item.sprite
			local itemW = itemSprite:getWidth() * itemScale
			local itemH = itemSprite:getHeight() * itemScale
			local posX = self.pos[1] - socketW / 4 - itemW / 2 + 4
			local posY = self.pos[2] - itemH / 2 + socketH / 4
			love.graphics.draw(itemSprite, posX, posY, 0, itemScale, itemScale)
			love.graphics.print(tostring(item.quantity) .. "x", posX, posY, 0, 0.5)
		end
	end

	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade ActionSlot
----------------------------------------

ActionSlot = {}
ActionSlot.__index = ActionSlot

function ActionSlot.new(action, index, scale, screenW, text)
	local slot = setmetatable({}, ActionSlot)
	slot.action = action
	slot.originalIndex = index
	slot.index = index
	slot.scale = scale
	slot.screen = screenW
	slot.current = text and text.current or nil
	slot.total = text and text.total or nil
	slot.font = returnFont(16)

	slot.active = false
	slot.disabled = false
	slot.isMoving = false
	slot.gap = 15

	-- sprites
	slot.socket = love.graphics.newImage("assets/UI/combat/action_socket.png")
	slot.actionSprite = love.graphics.newImage("assets/UI/combat/" .. action .. ".png")

	-- position
	local y = love.graphics.getHeight() - 100
	local slotWidth = slot.socket:getWidth() * scale
	local totalWidth = 5 * slotWidth + 4 * slot.gap
	local startX = (screenW - totalWidth) / 2
	local x = startX + (index - 1) * (slotWidth + slot.gap) + slotWidth / 2

	slot.startX = startX
	slot.originalPos = { x, y }
	slot.pos = { x, y }
	slot.targetPos = {}

	return slot
end

function ActionSlot:moveTo(newIndex)
	if newIndex < 1 or newIndex > 5 or newIndex == self.index then
		return
	end

	local slotWidth = self.socket:getWidth() * self.scale
	local newX = self.startX + (newIndex - 1) * (slotWidth + self.gap) + slotWidth / 2
	self.targetPos = { newX, self.pos[2] }
	self.isMoving = true
	self.index = newIndex
end

function ActionSlot:resetPosition()
	self.targetPos = { self.originalPos[1], self.originalPos[2] }
	self.isMoving = true
	self.index = self.originalIndex
end

function ActionSlot:getPosEnd()
	return self.pos[1] + (self.socket:getWidth() * self.scale) / 2 + self.gap
end

function ActionSlot:disable()
	self.disabled = true
end

function ActionSlot:enable()
	self.disabled = false
end

function ActionSlot:update(dt)
	if self.isMoving then
		local dx = self.targetPos[1] - self.pos[1]
		local dy = self.targetPos[2] - self.pos[2]
		if math.abs(dx) < 1 and math.abs(dy) < 1 then
			self.pos[1] = self.targetPos[1]
			self.pos[2] = self.targetPos[2]
			self.targetPos = {}
			self.isMoving = false
		else
			self.pos[1] = self.pos[1] + dx * dt * 10
			self.pos[2] = self.pos[2] + dy * dt * 10
		end
	end
end

function ActionSlot:updateText(text)
	self.current = text and text.current or nil
	self.total = text and text.total or nil
end

function ActionSlot:draw()
	love.graphics.setColor(1, 1, 1, 1)

	if self.disabled then
		love.graphics.setShader(darknessShader)
	elseif self.active then
		love.graphics.setShader(brightnessShader)
	end

	local socketW = self.socket:getWidth() * self.scale
	local socketH = self.socket:getHeight() * self.scale

	local actionW = self.actionSprite:getWidth() * self.scale
	local actionH = self.actionSprite:getHeight() * self.scale

	love.graphics.draw(self.socket, self.pos[1] - socketW / 2, self.pos[2] - socketH / 2, 0, self.scale, self.scale)
	love.graphics.draw(
		self.actionSprite,
		self.pos[1] - actionW / 2,
		self.pos[2] - actionH / 2,
		0,
		self.scale,
		self.scale
	)

	love.graphics.setFont(self.font)
	if self.current and self.total then
		local padding = 18
		local text = tostring(self.current) .. "/" .. tostring(self.total)
		love.graphics.print(text, self.pos[1] - socketW / 2 + padding, self.pos[2] - socketH / 2 + padding)
	end

	if self.disabled or self.active then
		love.graphics.setShader()
	end

	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade HealthBar
----------------------------------------

HealthBar = {}
HealthBar.__index = HealthBar

function HealthBar.new(creature, pos, who)
	local healthBar = setmetatable({}, HealthBar)
	healthBar.creature = creature
	healthBar.pos = pos
	healthBar.scale = 0.72
	healthBar.targetRatio = 1
	healthBar.currentRatio = 1
	healthBar.isShieldBreaking = false
	healthBar.shieldBreakTimer = 0
	healthBar.shieldBreakDuration = 0.6
	healthBar.shieldPieces = nil

	healthBar.empty = love.graphics.newImage("assets/UI/combat/empty_healthbar.png")
	healthBar.full = love.graphics.newImage("assets/UI/combat/" .. who .. "_healthbar.png")
	healthBar.shielded = love.graphics.newImage("assets/UI/combat/shielded_healthbar.png")

	return healthBar
end

function HealthBar:update(dt)
	local hpRatio = self.creature.hp / self.creature.maxHp
	self.targetRatio = hpRatio

	local speed = 6
	self.currentRatio = self.currentRatio + (self.targetRatio - self.currentRatio) * (1 - math.exp(-speed * dt))

	if self.isShieldBreaking and self.shieldBreakTimer > 0 then
		self.shieldBreakTimer = self.shieldBreakTimer - dt
		if self.shieldPieces then
			for _, piece in ipairs(self.shieldPieces) do
				piece.vy = piece.vy + (piece.gravity or 0) * dt
				piece.offsetX = piece.offsetX + piece.vx * dt
				piece.offsetY = piece.offsetY + piece.vy * dt
			end
		end
		if self.shieldBreakTimer <= 0 then
			self.isShieldBreaking = false
			self.shieldPieces = nil
		end
	end
end

function HealthBar:triggerShieldBreak()
	local emptyW = self.empty:getWidth() * self.scale
	local shieldW = self.shielded:getWidth() * self.scale
	local shieldH = self.shielded:getHeight() * self.scale
	local baseX = self.pos[1] - emptyW / 2
	local baseY = self.pos[2]

	local cols = 12
	local rows = 2
	local pieceW = shieldW / cols
	local pieceH = shieldH / rows

	self.isShieldBreaking = true
	self.shieldBreakTimer = self.shieldBreakDuration
	self.shieldPieces = {}

	for row = 0, rows - 1 do
		for col = 0, cols - 1 do
			local piece = {}
			piece.x = baseX + col * pieceW
			piece.y = baseY + row * pieceH
			piece.w = pieceW
			piece.h = pieceH
			piece.offsetX = 0
			piece.offsetY = 0
			local dir = (col - (cols - 1) / 2) / cols
			piece.vx = (50 + math.random() * 80) * dir
			piece.vy = -(50 + math.random() * 70)
			piece.gravity = 220 + math.random() * 80
			table.insert(self.shieldPieces, piece)
		end
	end
end

function HealthBar:draw()
	love.graphics.setColor(1, 1, 1, 1)

	local emptyW = self.empty:getWidth() * self.scale

	-- background
	love.graphics.draw(self.empty, self.pos[1] - emptyW / 2, self.pos[2], 0, self.scale, self.scale)

	-- foreground (vida)
	if not self.creature.shielded then
		local barWidth = emptyW * self.currentRatio
		local offset = 0

		love.graphics.setScissor(
			self.pos[1] - emptyW / 2 + offset,
			self.pos[2],
			barWidth,
			self.full:getHeight() * self.scale
		)
		love.graphics.draw(self.full, self.pos[1] - emptyW / 2, self.pos[2], 0, self.scale, self.scale)
		love.graphics.setScissor()
	end

	-- shield intact
	if self.creature.shielded then
		love.graphics.draw(self.shielded, self.pos[1] - emptyW / 2, self.pos[2], 0, self.scale, self.scale)
	elseif self.isShieldBreaking and self.shieldBreakTimer > 0 and self.shieldPieces then
		-- shield breaking into pieces
		local shieldW = self.shielded:getWidth() * self.scale
		local shieldH = self.shielded:getHeight() * self.scale
		local baseX = self.pos[1] - emptyW / 2
		local baseY = self.pos[2]
		local alpha = math.max(0, math.min(1, self.shieldBreakTimer / self.shieldBreakDuration))

		local r, g, b, a = love.graphics.getColor()
		love.graphics.setColor(1, 1, 1, alpha)

		for _, piece in ipairs(self.shieldPieces) do
			love.graphics.setScissor(piece.x + piece.offsetX, piece.y + piece.offsetY, piece.w, piece.h)
			love.graphics.draw(self.shielded, baseX + piece.offsetX, baseY + piece.offsetY, 0, self.scale, self.scale)
		end
		love.graphics.setScissor()
		love.graphics.setColor(r, g, b, a)
	end

	-- reset de cor
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade UpgradesOwned
----------------------------------------

UpgradesOwned = {}
UpgradesOwned.__index = UpgradesOwned

function UpgradesOwned.new(initialUpgrades, initialPos, direction)
	local upgradesOwned = setmetatable({}, UpgradesOwned)

	upgradesOwned.upgrades = initialUpgrades or {}
	upgradesOwned.pos = initialPos
	upgradesOwned.direction = direction
	upgradesOwned.scale = 0.25

	return upgradesOwned
end

function UpgradesOwned:draw()
	local x, y = self.pos[1], self.pos[2]
	local spacing = 0
	local size = self.upgrades[1] and self.upgrades[1].sprite:getWidth() * self.scale or 0
	for i, upgrade in ipairs(self.upgrades) do
		love.graphics.draw(upgrade.sprite, x, y, 0, self.scale, self.scale)
		x = x + self.direction * (size + spacing)
	end

	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade CounterText
----------------------------------------

CounterText = {}
CounterText.__index = CounterText

function CounterText.new(pos)
	local counterText = setmetatable({}, CounterText)
	counterText.pos = pos

	counterText.counter = nil
	counterText.scale = 1
	counterText.isActive = false

	return counterText
end

function CounterText:setCounter(counter)
	self.counter = counter
	self.scale = 1
	self.isActive = true
end

function CounterText:update(dt)
	if not self.isActive then
		return
	end

	self.scale = self.scale + 2 * dt

	if self.scale > 2 then
		self.isActive = false
	end
end

function CounterText:draw()
	if not self.isActive then
		return
	end

	local width = self.counter:getWidth()
	local height = self.counter:getHeight()

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(
		self.counter,
		self.pos.x - (width * self.scale) / 2,
		self.pos.y - (height * self.scale) / 2,
		0,
		self.scale,
		self.scale
	)
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade PlusAmmoText
----------------------------------------

PlusAmmoText = {}
PlusAmmoText.__index = PlusAmmoText

function PlusAmmoText.new(sprite, amount, pos)
	local plus = setmetatable({}, PlusAmmoText)
	plus.sprite = sprite
	plus.amount = amount or 0
	plus.pos = { pos[1], pos[2] }
	plus.speedY = 60
	plus.lifetime = 2.0
	plus.timer = plus.lifetime
	plus.alpha = 1
	plus.font = returnFont(24)
	plus.isOver = false

	return plus
end

function PlusAmmoText:update(dt)
	self.pos[2] = self.pos[2] - self.speedY * dt
	self.timer = self.timer - dt
	if self.timer <= 0 then
		self.isOver = true
		self.alpha = 0
	else
		self.alpha = self.timer / self.lifetime
	end
end

function PlusAmmoText:draw()
	local prevFont = love.graphics.getFont()

	love.graphics.setFont(self.font or prevFont)
	love.graphics.setColor(1, 1, 1, self.alpha)

	local iconScale = 0.5
	local iconW = self.sprite:getWidth() * iconScale
	local iconH = self.sprite:getHeight() * iconScale
	local x = self.pos[1]
	local y = self.pos[2]

	love.graphics.draw(self.sprite, x - iconW / 2, y - iconH / 2, 0, iconScale, iconScale)

	local text = "+ " .. tostring(self.amount)
	local textX = x + iconW / 2 + 8
	local textY = y - iconH / 2
	love.graphics.print(text, textX, textY)

	love.graphics.setFont(prevFont)
	
	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Estado do jogo no contexto de batalha
----------------------------------------

local BattleState = {}
BattleState.__index = BattleState

BattleState.sprites = {}
BattleState.texts = {}
BattleState.sounds = {}
BattleState.upgradesOwned = {}
BattleState.healthBar = {}
BattleState.actionSlots = {}
BattleState.counter = nil
BattleState.itemSlots = nil
BattleState.plusAmmoTexts = {}
BattleState.oponentPool = generateOponentPool()
BattleState.battleNum = 1
BattleState.oponent = BattleState.oponentPool[BattleState.battleNum]
BattleState.decisionTime = 5
BattleState.timer = BattleState.decisionTime
BattleState.turn = 1
BattleState.hist = History.new()
BattleState.hasEnded = false
BattleState.endTimer = math.huge
BattleState.finalResult = nil
BattleState.actionsEnabled = true
BattleState.font = returnFont(32)
BattleState.flashDuration = 0.25
BattleState.flashTimer = 0

-- para caso o jogo recomece
function BattleState:restartGame()
	self.oponentPool = generateOponentPool()
	self.battleNum = 1
	self.oponent = self.oponentPool[self.battleNum]
	Player:reset()
	self:reset()
end

function BattleState:reset()
	self.texts = {}
	self.plusAmmoTexts = {}
	self.decisionTime = 5
	self.timer = self.decisionTime
	self.turn = 1
	self.hist = History.new()
	self.hasEnded = false
	self.endTimer = math.huge
	self.finalResult = nil
	self.actionsEnabled = true
	self.flashTimer = 0
	self:resetUI()
end

function BattleState:resetUI()
	self.upgradesOwned = {}
	self.healthBar = {}
	self.actionSlots = {}
	self.itemSlots = nil
	self.plusAmmoTexts = {}
	self.counter = CounterText.new({ x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() * 2 / 5 })

	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

	-- coisa
	self.sprites.coisa = love.graphics.newImage("assets/UI/combat/coisa.png")
	local coisaW = self.sprites.coisa:getWidth()
	local coisaScale = 0.65

	-- health bars
	xOffset = 40
	local centerFirstPart = (screenW - coisaW * coisaScale * 0.5) / 4
	local centerSecondPart = screenW - centerFirstPart
	local healthBarYOffset = 80
	local healthBarPlayer = HealthBar.new(Player, { centerFirstPart, healthBarYOffset }, "your")
	local healthBarOponent = HealthBar.new(self.oponent, { centerSecondPart, healthBarYOffset }, "enemy")
	self.healthBar.player = healthBarPlayer
	self.healthBar.oponent = healthBarOponent

	-- textos
	local xOffset = centerFirstPart - self.healthBar.player.empty:getWidth() * self.healthBar.player.scale / 2
	local yOffset = 135
	self.texts.playerName = Text.new(string.upper(Player.name), 32, { 0, 0, 0, 1 }, { xOffset, yOffset })

	local textPlayerWidth = self.texts.playerName:getDimensions()
	local playerUpgradesOwned =
		UpgradesOwned.new(Player.inventory.upgrades, { xOffset + textPlayerWidth + 20, yOffset }, 1)

	xOffset = centerSecondPart + self.healthBar.oponent.empty:getWidth() * self.healthBar.oponent.scale / 2
	self.texts.oponentName = Text.new(string.upper(self.oponent.name), 32, { 0, 0, 0, 1 }, { xOffset, yOffset })

	local textOponentWidth = self.texts.oponentName:getDimensions()
	local oponentBuffs = {}
	for _, v in ipairs(self.oponent.inventory.upgrades) do
		table.insert(oponentBuffs, v)
	end
	for _, v in ipairs(self.oponent.inventory.items) do
		table.insert(oponentBuffs, v)
	end
	local oponentUpgradesOwned = UpgradesOwned.new(oponentBuffs, { xOffset - textOponentWidth - 60, yOffset }, -1)
	self.texts.oponentName.pos[1] = self.texts.oponentName.pos[1] - textOponentWidth

	-- upgrades owned
	self.upgradesOwned.player = playerUpgradesOwned
	self.upgradesOwned.oponent = oponentUpgradesOwned

	-- items slots
	local itemScale = 0.7
	self.itemSlots = ItemSlot.new(Player.inventory.items, itemScale, { 0, screenH - 100 })

	local itemSlotW = self.itemSlots.socket:getWidth() * itemScale
	-- action slots
	local slotScale = 0.7
	for i = 1, 5 do
		self.actionSlots[i] = ActionSlot.new(ACTION_IDX[i], i, slotScale, screenW - itemSlotW)
	end

	self:verifyActionSlots()
	self:updateActionSlots()

	self.itemSlots.pos[1] = self.actionSlots[5]:getPosEnd() + self.itemSlots.socket:getWidth() * itemScale / 2
end

-- passa para o próximo oponente e reseta uns atributos
function BattleState:nextBattle()
	self.battleNum = self.battleNum + 1
	self.oponent = self.oponentPool[self.battleNum]
	self.texts = {}
	self.timer = 0
	self.turn = 1
	self.hasEnded = false
	self.endTimer = math.huge
	self.finalResult = nil
	self.actionsEnabled = true
	self.hist = History.new()
	self.decisionTime = 5

	Player:resetForBattle()
end

-- simula um confronto entre o player e o oponente, atualizando o historico do combate
function BattleState:simulateBattle()
	local turnResult = simulateTurn(Player, self.oponent, self.hist)
	self.hist:addSnapshot(Player)

	local width, height = love.graphics.getDimensions()
	self.texts.playerActionShadow = Text.new(
		toPrettyActionName(Player.action),
		64,
		{ 0, 0, 0, 1 },
		{ 2.5 * width / 12 + 5, height * 0.27 + 5 },
		0,
		0,
		1.5,
		function(text, dt)
			text.scale = text.scale and (text.scale + math.sin(dt / 10)) or 1
		end
	)
	self.texts.playerActionShadow.isShadow = true
	self.texts.playerAction = Text.new(
		toPrettyActionName(Player.action),
		64,
		mapToColor(Player.action),
		{ 2.5 * width / 12, height * 0.27 },
		0,
		0,
		1.5,
		function(text, dt)
			text.scale = text.scale and (text.scale + math.sin(dt / 10)) or 1
		end
	)

	local oponentAction = self.oponent.action
	self.texts.oponentActionShadow = Text.new(
		toPrettyActionName(oponentAction),
		64,
		{ 0, 0, 0, 1 },
		{ 9.5 * width / 12 + 5, height * 0.27 + 5 },
		0,
		0,
		1.5,
		function(text, dt)
			text.scale = text.scale and (text.scale + math.sin(dt / 10)) or 1
		end
	)
	self.texts.oponentActionShadow.isShadow = true
	self.texts.oponentAction = Text.new(
		toPrettyActionName(oponentAction),
		64,
		mapToColor(oponentAction),
		{ 9.5 * width / 12, height * 0.27 },
		0,
		0,
		1.5,
		function(text, dt)
			text.scale = text.scale and (text.scale + math.sin(dt / 10)) or 1
		end
	)

	if turnResult ~= Combat.ONGOING then
		self.finalResult = turnResult
		self.hasEnded = true
		self.endTimer = 2
		if turnResult == Combat.WIN then
			self.oponent:setAction(ACTION.DEAD)
		else
			Player:setAction(ACTION.DEAD)
		end
	end
end

function BattleState:addPlusAmmoText(criatura, amount)
	if not amount or amount <= 0 then
		return
	end

	local width, height = love.graphics.getDimensions()
	local xOffset = 150
	local yOffset = math.random(-50, 50)
	local pos = criatura.name == Player.name and { 2.5 * width / 12 + xOffset, height / 2 + yOffset }
		or { 9.5 * width / 12 - xOffset, height / 2 + yOffset }
	local textPos = { pos[1], pos[2] }

	local sprite = self.sprites.amount
	local plus = PlusAmmoText.new(sprite, amount, textPos)
	table.insert(self.plusAmmoTexts, plus)
end

function BattleState:addDamageOrHealingText(criatura, amount)
	if not amount or amount == 0 then
		return
	end

	local width, height = love.graphics.getDimensions()
	local xOffset = 150
	local yOffset = math.random(-50, 50)
	local pos = criatura.name == Player.name and { 2.5 * width / 12 + xOffset, height / 2.5 + yOffset }
		or { 9.5 * width / 12 - xOffset, height / 2.5 + yOffset }
	local textPos = { pos[1], pos[2] }

	local content = amount > 0 and "+" .. tostring(amount) or tostring(amount)
	local color = amount > 0 and { 0, 1, 0, 1 } or { 1, 0, 0, 1 }

	local text = Text.new(content, 32, color, textPos, 0, 0, 1.5, function(text, dt)
		text.pos[2] = text.pos[2] - 60 * dt
		text.color[4] = text.color[4] - dt / 1.5
	end)
	table.insert(self.texts, text)
end

function BattleState:onShieldBroken(criatura)
	if not self.healthBar then
		return
	end

	local bar = nil
	if criatura == Player then
		bar = self.healthBar.player
	elseif criatura == self.oponent then
		bar = self.healthBar.oponent
	end

	if bar then
		bar:triggerShieldBreak()
	end
end

function BattleState:endBattle()
	if self.finalResult == Combat.WIN and BattleState.battleNum == 6 then
		SetGameCtx(CTX.VICTORY_SCREEN)
	elseif self.finalResult == Combat.LOSS then
		SetGameCtx(CTX.DEATH_SCREEN)
	elseif self.finalResult == Combat.WIN then
		SetGameCtx(CTX.SHOP)
	end
end

function BattleState:load()
	self:reset()

	-- sprites
	self.sprites.bg = love.graphics.newImage("assets/UI/combat/combat_bg.png")
	self.sprites.one = love.graphics.newImage("assets/UI/combat/1.png")
	self.sprites.two = love.graphics.newImage("assets/UI/combat/2.png")
	self.sprites.three = love.graphics.newImage("assets/UI/combat/3.png")
	self.sprites.shoot = love.graphics.newImage("assets/UI/combat/shoot.png")
	self.sprites.amount = love.graphics.newImage("assets/UI/combat/amount.png")
	-- texto ammo
	local battle = self

	-- sounds
	self.sounds.select = love.audio.newSource("sounds/select.wav", "static")
	self.sounds.counter3 = love.audio.newSource("sounds/counter_3.mp3", "static")
	self.sounds.counter2 = love.audio.newSource("sounds/counter_2.mp3", "static")
	self.sounds.counter1 = love.audio.newSource("sounds/counter_1.mp3", "static")
	self.sounds.counterShoot = love.audio.newSource("sounds/counter_shoot.mp3", "static")
	self.sounds.shuffle = love.audio.newSource("sounds/shuffle.mp3", "static")
	self.sounds.shuffle:setVolume(0.5)
end

function BattleState:resetTurn()
	-- TODO: melhorar isso aqui que horror
	Player.dmgMult = 1
	self.oponent.dmgMult = 1

	Player.defibrilated = false
	self.oponent.defibrilated = false

	Player.timedRight = false
	self.oponent.timedRight = false

	Player.blinded = false
	self.oponent.blinded = false
end

function BattleState:verifyActionSlots()
	-- Disable buttons if player cannot perform action/Enable them if they can
	if Player.ammo == 0 then
		self.actionSlots[getIdFromValue(ACTION.ATK, ACTION_IDX)]:disable()
	else
		self.actionSlots[getIdFromValue(ACTION.ATK, ACTION_IDX)]:enable()
	end
	if Player.ammo < 2 then
		self.actionSlots[getIdFromValue(ACTION.HEAVY_ATK, ACTION_IDX)]:disable()
	else
		self.actionSlots[getIdFromValue(ACTION.HEAVY_ATK, ACTION_IDX)]:enable()
	end
	if Player.defCount >= 2 then
		self.actionSlots[getIdFromValue(ACTION.DEFENSE, ACTION_IDX)]:disable()
	else
		self.actionSlots[getIdFromValue(ACTION.DEFENSE, ACTION_IDX)]:enable()
	end
	if Player.counters == 0 then
		self.actionSlots[getIdFromValue(ACTION.COUNTER, ACTION_IDX)]:disable()
	else
		self.actionSlots[getIdFromValue(ACTION.COUNTER, ACTION_IDX)]:enable()
	end
end

function BattleState:updateActionSlots()
	self.actionSlots[getIdFromValue(ACTION.ATK, ACTION_IDX)]:updateText({ current = Player.ammo, total = 1 })
	self.actionSlots[getIdFromValue(ACTION.HEAVY_ATK, ACTION_IDX)]:updateText({ current = Player.ammo, total = 2 })
	self.actionSlots[getIdFromValue(ACTION.COUNTER, ACTION_IDX)]:updateText({
		current = Player.counters,
		total = Player.maxCounters,
	})
	self.actionSlots[getIdFromValue(ACTION.DEFENSE, ACTION_IDX)]:updateText({ current = Player.defCount, total = 2 })
end

local COUNTER_INTERVAL = 0.4

local COUNTER_TIMINGS = {
	{ number = "three", sound = "counter3", time = COUNTER_INTERVAL * 3 },
	{ number = "two", sound = "counter2", time = COUNTER_INTERVAL * 2 },
	{ number = "one", sound = "counter1", time = COUNTER_INTERVAL },
}

function BattleState:update(dt)
	Player:update(dt)
	self.oponent:update(dt)
	if not self.hasEnded then
		local pt = self.timer
		self.timer = pt - dt

		-- count chegou a 0 -> shoot
		if self.timer <= 0 then
			self.counter:setCounter(self.sprites.shoot)
			self.sounds.counterShoot:play()
			self.turn = self.turn + 1
			self:simulateBattle()

			-- defibrillator effect
			if Player.defibrilated then
				Player.blinkTimer = Player.blinkDuration or 1.2
			end
			if self.oponent.defibrilated then
				self.oponent.blinkTimer = self.oponent.blinkDuration or 1.2
			end

			-- flashbang effect
			local blindedAtShoot = Player.blinded or self.oponent.blinded
			if blindedAtShoot then
				self.flashTimer = self.flashDuration
			end

			self.timer = self.decisionTime
			self.actionsEnabled = false
			self:resetTurn()
		end

		-- count chegou a 3.5 -> volta ao idle e limpa os textos
		if pt > 3.5 and self.timer < 3.5 and self.turn > 1 then
			self:setAction(0)
			self.oponent:setAction(ACTION.NONE)
			self.actionsEnabled = true
		end

		for _, counter in ipairs(COUNTER_TIMINGS) do
			if pt > counter.time and self.timer <= counter.time then
				self.counter:setCounter(self.sprites[counter.number])
				self.sounds[counter.sound]:play()
			end
		end
	else
		self.endTimer = self.endTimer - dt
		if self.endTimer <= 0 then
			self:endBattle()
		end
	end

	if self.flashTimer and self.flashTimer > 0 then
		self.flashTimer = math.max(0, self.flashTimer - dt)
	end

	self:verifyActionSlots()
	self:updateActionSlots()

	for _, slot in pairs(self.actionSlots) do
		slot:update(dt)
	end

	self.counter:update(dt)

	-- plus ammo texts
	for i = #self.plusAmmoTexts, 1, -1 do
		local plus = self.plusAmmoTexts[i]
		plus:update(dt)
		if plus.isOver then
			table.remove(self.plusAmmoTexts, i)
		end
	end

	for _, healthBar in pairs(self.healthBar) do
		healthBar:update(dt)
	end

	-- texts
	for _, text in pairs(self.texts) do
		if text.update then
			text:update(dt)
		end
	end
	cleanUpTexts(self.texts)
end

function BattleState:draw()
	redBordersShader:send("playerHP", Player.hp)
	love.graphics.setShader(redBordersShader)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

	-- background
	local bg = self.sprites.bg
	local bgW, bgH = bg:getWidth(), bg:getHeight()
	local scale = math.max(screenW / bgW, screenH / bgH)
	local drawX = (screenW - bgW * scale) / 2
	local drawY = (screenH - bgH * scale) / 2
	love.graphics.draw(bg, drawX, drawY, 0, scale, scale)

	-- coisa
	local coisa = self.sprites.coisa
	local coisaW = coisa:getWidth()
	local coisaScale = 0.65
	local coisaX = screenW / 2 - (coisaW * coisaScale) / 2
	local coisaY = 55
	love.graphics.draw(coisa, coisaX, coisaY, 0, coisaScale, coisaScale)

	-- reset de cor
	love.graphics.setColor(1, 1, 1, 1)

	-- player
	local width, height = love.graphics.getDimensions()
	local playerPos = { 2.5 * width / 12, height / 2 }
	Player:draw(playerPos)

	-- oponent
	local oponentPos = { 9.5 * width / 12, height / 2 }
	self.oponent:draw(oponentPos)

	-- upgrades
	self.upgradesOwned.player:draw()
	self.upgradesOwned.oponent:draw()

	-- health bars
	self.healthBar.player:draw()
	self.healthBar.oponent:draw()

	-- action slots
	for _, slot in pairs(self.actionSlots) do
		slot:draw()
	end

	-- ammo amount
	local startX = self.actionSlots[1].startX
		- self.actionSlots[1].socket:getWidth() * self.actionSlots[1].scale / 2
		- self.sprites.amount:getWidth()
		- 20
	local amountX = startX
	local amountY = screenH - self.sprites.amount:getHeight() - 60
	love.graphics.draw(self.sprites.amount, amountX, amountY, 0, 1, 1)

	local prevFont = love.graphics.getFont()
	love.graphics.setFont(self.font)
	love.graphics.print(
		tostring(Player.ammo) .. "x",
		amountX + self.sprites.amount:getWidth() + 5,
		amountY + self.sprites.amount:getHeight() / 2 - self.font:getHeight() / 2
	)
	love.graphics.setFont(prevFont)

	-- item slots
	self.itemSlots:draw()

	-- texts
	for _, text in pairs(self.texts) do
		if text.isShadow then
			text:draw()
		end
	end

	-- plus ammo texts
	for _, plus in ipairs(self.plusAmmoTexts) do
		plus:draw()
	end

	for _, text in pairs(self.texts) do
		if not text.isShadow then
			text:draw()
		end
	end

	-- counter
	self.counter:draw()

	-- clarão (flashbang)
	if self.flashTimer and self.flashTimer > 0 then
		local t = self.flashTimer / self.flashDuration
		local alpha = math.max(0, math.min(1, t))
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.rectangle("fill", 0, 0, screenW, screenH)
	end

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setShader()
end

-- Detecta o input do usuário
function BattleState:keypressed(key, scancode, isrepeat)
	if not self.actionsEnabled then
		return
	end

	local num = tonumber(key)
	if num and num > 0 and num < 6 then
		-- ignore if slot is disabled
		if not self.actionSlots[num].disabled then
			self:setAction(num)
		end
	end

	if num and num >= 6 and num <= 8 then
		local itemIndex = num - 5
		if Player.inventory.items[itemIndex] then
			Player:useBuff(Player.inventory.items[itemIndex])
			self.sounds.select:play()
		end
	end
end

function BattleState:setAction(num)
	local prevAction = Player.action
	-- deselecionando o slot
	for i, slot in pairs(self.actionSlots) do
		if i == num then
			slot.active = not slot.active
		else
			slot.active = false
		end
	end

	-- alterando a acao do jogador
	if Player.action == ACTION_IDX[num] or num == 0 then
		Player:setAction(ACTION.NONE)
	else
		Player:setAction(ACTION_IDX[num])
	end

	local actionChanged = prevAction ~= Player.action
	if actionChanged and Player.action == ACTION.ATK or Player.action == ACTION.HEAVY_ATK then
		local stopwatch = Player:hasUpgrade(UPGRADE.STOPWATCH)
		if stopwatch then
			stopwatch:activate(Player, self.timer)
		end
	end

	if num ~= 0 then
		self.sounds.select:play()
	end
end

function BattleState:shuffleActionSlots()
	local usedIndexes = {}
	self.sounds.shuffle:play()
	for _, slot in pairs(self.actionSlots) do
		local newIndex = math.random(1, 5)
		while usedIndexes[newIndex] do
			newIndex = math.random(1, 5)
		end

		usedIndexes[newIndex] = true
		slot:moveTo(newIndex)
	end
end

function BattleState:mousepressed(x, y, button, istouch)
    if not self.actionsEnabled then return end
    if button ~= 1 then return end

    -- verifica clique nos botões de ação
    for i, slot in pairs(self.actionSlots) do
        if not slot.disabled then
            local w = slot.socket:getWidth() * slot.scale
            local h = slot.socket:getHeight() * slot.scale
            local startX = slot.pos[1] - w / 2
            local startY = slot.pos[2] - h / 2
            
            if isPointInRect(x, y, startX, startY, w, h) then
                self:setAction(i)
                return
            end
        end
    end

    -- verifica clique nos itens
    if self.itemSlots then
        local socketW = self.itemSlots.socket:getWidth() * self.itemSlots.scale
        local socketH = self.itemSlots.socket:getHeight() * self.itemSlots.scale
        local itemScale = 0.25
        local pos = self.itemSlots.pos

        local function checkItemClick(item, offsetX, offsetY)
            if item and item.quantity > 0 then
                local itemW = item.sprite:getWidth() * itemScale
                local itemH = item.sprite:getHeight() * itemScale

                local itemX = pos[1] + offsetX - itemW / 2
                local itemY = pos[2] + offsetY - itemH / 2

                -- padding de 12 pixels para facilitar o clique no celular / mouse
                local padding = 12 

                if isPointInRect(x, y, itemX - padding, itemY - padding, itemW + padding * 2, itemH + padding * 2) then
                    return true
                end
            end
            return false
        end

        -- uso de itens
        if checkItemClick(Player.inventory.items[1], -socketW / 4 + 4, -socketH / 4 + 8) then
            Player:useBuff(Player.inventory.items[1])
            self.sounds.select:play()
            return
        end
        if checkItemClick(Player.inventory.items[2], -socketW / 4 + 4, socketH / 4) then
            Player:useBuff(Player.inventory.items[2])
            self.sounds.select:play()
            return
        end
        if checkItemClick(Player.inventory.items[3], socketW / 4 - 8, 0) then
            Player:useBuff(Player.inventory.items[3])
            self.sounds.select:play()
            return
        end
    end
end

return BattleState