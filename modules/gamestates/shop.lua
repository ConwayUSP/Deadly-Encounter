----------------------------------------
-- Importações de Módulos
----------------------------------------
require("table")
require("modules.constructors.buffs")
require("modules.utils")
require("modules.fs")
require("modules.shaders")

----------------------------------------
-- Constantes
----------------------------------------

local ITEMS_FOR_SALE = 3
local DESCRIPTION_WIDTH = 200
local DESCRIPTION_Y = 510
local DESCRIPTION_GAP = 60
local DESCRIPTIONS_TOTAL_WIDTH = 0
local DESCRIPTION_START_X = 0
local PURCHASED_SLOT_SIZE = 60
local SHADER = brightnessShader

----------------------------------------
-- Entidade DescriptionCard
----------------------------------------

local DescriptionCard = {}
DescriptionCard.__index = DescriptionCard

function DescriptionCard.new(item, pos)
	local card = setmetatable({}, DescriptionCard)
	local x, y = pos.x, pos.y - 30

	local function updateFunc(text, _, descCard)
		local color = text.color or { 0, 0, 0, 1 }
		color[4] = descCard.alpha
		text.color = color
	end

	card.item = item
	card.type = item.type
	card.title = Text.new(capitalize(item.id), 24, { 1, 1, 1, 1 }, { x, y }, nil, false, math.huge, updateFunc)
	card.description = Text.new(
		item.description,
		16,
		{ 1, 1, 1, 1 },
		{ x, y + 30 },
		nil,
		false,
		math.huge,
		updateFunc,
		DESCRIPTION_WIDTH
	)

	card.scale = 0.55
	card.bg = love.graphics.newImage("assets/UI/shop/description_" .. item.type .. ".png")

	card.position = { x = x - 20 or 0, y = y - 60 or 0 }
	card.alpha = 0
	card.fadeDuration = 0.2
	return card
end

function DescriptionCard:update(dt, isSelected)
	if isSelected then
		if self.alpha < 1 then
			self.alpha = math.min(1, self.alpha + dt / self.fadeDuration)
		end
	else
		self.alpha = 0
	end

	self.title:update(dt, self)
	self.description:update(dt, self)
	if self.badgeText then
		self.badgeText:update(dt, self)
	end
end

function DescriptionCard:draw()
	if self.alpha <= 0 then
		return
	end

	love.graphics.setColor(1, 1, 1, self.alpha)
	love.graphics.draw(self.bg, self.position.x, self.position.y, 0, self.scale, self.scale)

	love.graphics.setColor(1, 1, 1)
	self.title:draw(self.position.x, self.position.y)
	self.description:draw(self.position.x, self.position.y)
	
	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

----------------------------------------
-- Entidade ItemSlot
----------------------------------------

local ItemSlot = {}
ItemSlot.__index = ItemSlot

function ItemSlot.new(item, pos, index)
	local slot = setmetatable({}, ItemSlot)
	local yOffset = -50

	slot.item = item
	slot.position = { x = pos.x, y = pos.y + yOffset }
	slot.scale = 0.75
	slot.buyed = false
	slot.selected = false

	slot.rope = love.graphics.newImage("assets/UI/shop/rope_0" .. index .. ".png")
	slot.frame = love.graphics.newImage("assets/UI/shop/frame_0" .. index .. ".png")

	slot.ropeW = slot.rope:getWidth() * slot.scale
	slot.ropeH = slot.rope:getHeight() * slot.scale
	slot.frameW = slot.frame:getWidth() * slot.scale
	slot.frameH = slot.frame:getHeight() * slot.scale

	local itemW = item.sprite:getWidth() * slot.scale
	local itemH = item.sprite:getHeight() * slot.scale
	local x = pos.x - itemW / 2
	local y = pos.y + slot.ropeH - 20 + (slot.frameW - itemH) / 2

	slot.itemPosition = { x = x, y = y + yOffset }
	slot.timer = 0
	slot.gravity = 1000
	slot.velocityY = -300
	slot.velocityX = 100 * (math.random() < 0.5 and -1 or 1)

	slot.velocitySlotY = 330

	return slot
end

function ItemSlot:draw()
	love.graphics.setColor(1, 1, 1)

	-- corda
	love.graphics.draw(self.rope, self.position.x - self.ropeW / 2, self.position.y, 0, self.scale, self.scale)

	local baseCenterX = self.position.x
	local baseTopY = self.position.y + self.ropeH - 20

	local bobOffset = 0
	local t = self.timer

	love.graphics.setShader()

	-- frame
	love.graphics.draw(self.frame, baseCenterX - self.frameW / 2, baseTopY, 0, self.scale, self.scale)

	if self.selected then
		-- love.graphics.setColor(1, 1, 1)
		love.graphics.setShader(SHADER)
		bobOffset = math.sin(t * 4) * 3
	end

	-- item
	love.graphics.draw(
		self.item.sprite,
		self.itemPosition.x,
		self.itemPosition.y + bobOffset,
		0,
		self.scale,
		self.scale
	)
	love.graphics.setShader()

	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

function ItemSlot:update(dt)
	if self.selected then
		self.timer = self.timer + dt
	else
		self.timer = 0
	end

	if not self.buyed then
		return
	end

	self.velocitySlotY = self.velocitySlotY - self.gravity * dt * 2
	self.position.y = self.position.y + self.velocitySlotY * dt

	self.position.y = self.position.y + self.velocitySlotY * dt
	self.velocityY = self.velocityY + self.gravity * dt
	self.itemPosition.y = self.itemPosition.y + self.velocityY * dt
	self.itemPosition.x = self.itemPosition.x + self.velocityX * dt
end

----------------------------------------
-- Entidade PurchasedSlot
----------------------------------------

PurchasedSlot = {}
PurchasedSlot.__index = PurchasedSlot

function PurchasedSlot.new(item, pos)
	local slot = setmetatable({}, PurchasedSlot)
	slot.item = item
	slot.position = pos or { x = 0, y = 0 }
	slot.scale = 0.25
	slot.rectSize = PURCHASED_SLOT_SIZE
	return slot
end

function PurchasedSlot:draw()
	local half = self.rectSize / 2

	-- fundo do slot
	love.graphics.setColor(0.277, 0.242, 0.261, 1)
	love.graphics.rectangle("fill", self.position.x - half, self.position.y - half, self.rectSize, self.rectSize, 8, 8)

	-- item centralizado
	love.graphics.setColor(1, 1, 1)
	local spriteW = self.item.sprite:getWidth() * self.scale
	local spriteH = self.item.sprite:getHeight() * self.scale
	local itemX = self.position.x - spriteW / 2
	local itemY = self.position.y - spriteH / 2
	love.graphics.draw(self.item.sprite, itemX, itemY, 0, self.scale, self.scale)

	-- reset
	love.graphics.setColor(1, 1, 1, 1)
end

function PurchasedSlot:addItem(item)
	if item.type == BUFF_TYPE.UPGRADE then
		return
	end

	self.item = item
end

----------------------------------------
-- Entidade ShopState
----------------------------------------

local ShopState = {}
ShopState.__index = ShopState

-- todos os itens disponíves à venda
ShopState.sprites = {}
ShopState.texts = {}
ShopState.sounds = {}
ShopState.itemsForSale = {}
ShopState.selectedItemIndex = 0
ShopState.buyed = false
ShopState.buyedIndex = 0
ShopState.descriptionCards = {}
ShopState.purchasedSlots = {}
ShopState.timer = 0
ShopState.slots = {}
ShopState.font = nil

function ShopState:setInitialItems()
	self.allItems = {
		initParry(),
		initShield(),
		initDefibrillator(),
		initReverseCard(),
		initTotem(),
		initStopWatch(),
		initEnergyDrink(),
		initFlashbang(),
		initPotion(),
	}
end

ShopState.allItems = {}
ShopState:setInitialItems()

function ShopState:setPurchasedSlots(items)
	self.purchasedSlots = {}

	local count = #items
	if count == 0 then
		return
	end

	local rectSize = PURCHASED_SLOT_SIZE
	local gap = 10
	local totalWidth = rectSize * count + gap * (count - 1)
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	local startX = (screenW - totalWidth) / 2 + rectSize / 2
	local y = screenH - 80

	for i, item in ipairs(items) do
		local x = startX + (i - 1) * (rectSize + gap)
		local purchasedSlot = PurchasedSlot.new(item, { x = x, y = y })
		purchasedSlot.rectSize = rectSize
		table.insert(self.purchasedSlots, purchasedSlot)
	end
end

function ShopState:load()
	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
	self.sprites.bg = love.graphics.newImage("assets/UI/shop/shop_bg.png")
	self.sprites.sign = love.graphics.newImage("assets/UI/shop/plate.png")
	self.sprites.bag = love.graphics.newImage("assets/UI/shop/bag.png")

	-- sounds
	self.sounds.buy = love.audio.newSource("sounds/buy_00.wav", "static")
	self.sounds.select = love.audio.newSource("sounds/select.wav", "static")
	self.sounds.bell = love.audio.newSource("sounds/shop_bell.wav", "static")
	self.sounds.bg = love.audio.newSource("sounds/shop_bg.mp3", "static")

	self.sounds.buy:setVolume(0.35)
	self.sounds.bell:setVolume(0.8)

	self.sounds.bg:play()
	self.sounds.bg:setLooping(true)
	self.sounds.bg:setVolume(1.0)

	self.sounds.bell:play()

	local function blinkUpdate(text, dt)
		local alpha = text.color[4] or 1
		alpha = alpha + dt * 0.5
		if alpha > 1 then
			alpha = 0.5
		end
		text.color[4] = alpha
	end

	local padding = 30
	self.texts.warning = Text.new(
		"Press space to buy",
		48,
		{ 1, 1, 1, 1 },
		{ screenW - 150, screenH - padding },
		nil,
		true,
		math.huge,
		blinkUpdate
	)
	local textWidth, textHeight = self.texts.warning:getDimensions()
	self.texts.warning.pos[1] = screenW - textWidth/2 - padding
	self.texts.warning.pos[2] = screenH - padding - textHeight/2

	DESCRIPTIONS_TOTAL_WIDTH = DESCRIPTION_WIDTH * ITEMS_FOR_SALE + DESCRIPTION_GAP * (ITEMS_FOR_SALE - 1)
	DESCRIPTION_START_X = (screenW - DESCRIPTIONS_TOTAL_WIDTH) / 2

	-- debug buffs
	-- Player:getBuff(initShield())
	-- Player:getBuff(initPotion())
	-- Player:getBuff(initEnergyDrink())
	-- Player:getBuff(initFlashbang())

	self:reset()
end

function ShopState:restartGame()
	self:setInitialItems()
end

-- reinicia a loja, limpando os itens à venda e sorteando novos
function ShopState:reset()
	self.itemsForSale = {}
	self.slots = {}
	self.timer = 0
	self.descriptionCards = {}
	self.selectedItemIndex = -1
	self.buyed = false
	self.buyedIndex = -1
	self:setPurchasedSlots(Player.inventory.items)
	self:randomizeItems()
end

-- randomiza os itens que estarão à venda na loja
function ShopState:randomizeItems()
	local pickedIndexes = {}
	local pickedCount = 0
	local maxForSale = math.min(ITEMS_FOR_SALE, #self.allItems)
	while pickedCount < maxForSale do
		local index = math.random(1, #self.allItems)
		if not pickedIndexes[index] then
			pickedIndexes[index] = true
			pickedCount = pickedCount + 1

			table.insert(self.itemsForSale, self.allItems[index])

			-- coluna centralizada
			local columnCenterX = (DESCRIPTION_START_X + DESCRIPTION_WIDTH / 2)
				+ (pickedCount - 1) * (DESCRIPTION_WIDTH + DESCRIPTION_GAP)

			-- descrição
			local descX = columnCenterX - DESCRIPTION_WIDTH / 2
			local descY = DESCRIPTION_Y + (pickedCount == 2 and 60 or 0)
			local desc = DescriptionCard.new(self.allItems[index], { x = descX, y = descY })
			table.insert(self.descriptionCards, desc)

			-- slot
			local slot = ItemSlot.new(self.allItems[index], { x = columnCenterX, y = 0 }, pickedCount)
			table.insert(self.slots, slot)
		end
	end
end

-- faz o player comprar um item, adicionando ele ao inventário e removendo da loja
function ShopState:buyItem(item, idx)
	Player:getBuff(item)

	-- remove da lista global
	for i, baseItem in ipairs(self.allItems) do
		if baseItem == item then
			table.remove(self.allItems, i)
			break
		end
	end

	table.remove(self.itemsForSale, idx)
	table.remove(self.descriptionCards, idx)

	self.slots[self.selectedItemIndex].buyed = true
	self.buyedIndex = self.selectedItemIndex
end

function ShopState:update(dt)
	for i, card in ipairs(self.descriptionCards) do
		card:update(dt, i == self.selectedItemIndex)
	end

	for _, slot in ipairs(self.slots) do
		slot:update(dt)
	end

	for _, text in pairs(self.texts) do
		text:update(dt)
	end

	if self.timer > 0 then
		self.timer = self.timer - dt
	end

	if self.timer <= 0 and self.buyed then
		GAMESTATE[CTX.BATTLE]:nextBattle()
		SetGameCtx(CTX.BATTLE)
	end
end

function ShopState:selectItemSlot(index)
	if self.buyed then
		return
	end
	for i, slot in ipairs(self.slots) do
		if i == index then
			slot.selected = not slot.selected
		else
			slot.selected = false
		end
	end
end

function ShopState:keypressed(key, scancode, isrepeat)
	if key == "1" then
		self:selectItem(1)
		self:selectItemSlot(1)
	elseif key == "2" then
		self:selectItem(2)
		self:selectItemSlot(2)
	elseif key == "3" then
		self:selectItem(3)
		self:selectItemSlot(3)
	end

	if key == "return" or key == "space" then
		local selectedItem = self.itemsForSale[self.selectedItemIndex]
		if selectedItem then
			self:buyItem(selectedItem, self.selectedItemIndex)
			self:setPurchasedSlots(Player.inventory.items)
			self.buyed = true
			self.selectedItemIndex = 0
			self.timer = 2
			self.sounds.buy:play()
		end
	end
end

-- seleciona um dos itens dispoíveis para compra
function ShopState:selectItem(index)
	if self.buyed then
		return
	end

	self.sounds.select:play()

	if index == self.selectedItemIndex then
		self.selectedItemIndex = 0
		return
	end

	if self.selectedItemIndex == 0 or index >= 1 and index <= #self.itemsForSale then
		self.selectedItemIndex = index
	end
end

function ShopState:draw()
	-- fundo em tom bege suave
	love.graphics.clear(0.95, 0.90, 0.80)

	local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

	-- background
	local bg = self.sprites.bg
	local bgW, bgH = bg:getWidth(), bg:getHeight()
	local scale = math.max(screenW / bgW, screenH / bgH)
	local drawX = (screenW - bgW * scale) / 2
	local drawY = (screenH - bgH * scale) / 2
	love.graphics.draw(bg, drawX, drawY, 0, scale, scale)

	-- bolsa
	local bag = self.sprites.bag
	local bagScale = 0.7
	local bagW = bag:getWidth() * bagScale
	local screenHeight = love.graphics.getHeight()
	local bagY = screenHeight - bag:getHeight() * bagScale - 30
	love.graphics.draw(bag, (screenW - bagW) / 2, bagY, 0, bagScale, bagScale)

	-- items possuidos
	for _, slot in ipairs(self.purchasedSlots) do
		slot:draw()
	end

	-- slots dos itens
	for _, slot in ipairs(self.slots) do
		slot:draw()
	end

	-- placa
	local sign = self.sprites.sign
	local signScale = 0.75
	local signW = sign:getWidth() * signScale
	love.graphics.draw(sign, (screenW - signW) / 2, 40, 0, signScale, signScale)

	-- descrições
	for i, card in ipairs(self.descriptionCards) do
		if i == self.selectedItemIndex then
			card:draw()
		end
	end

	for _, text in pairs(self.texts) do
		text:draw()
	end

	-- reset de cor
	love.graphics.setColor(1, 1, 1)
end

function ShopState:mousepressed(x, y, button, istouch)
    if self.buyed or button ~= 1 then return end
    
    for i, slot in ipairs(self.slots) do
        local w = slot.frameW
        local h = slot.frameH
        local startX = slot.position.x - w / 2
        local startY = slot.position.y + slot.ropeH - 20
        
        if isPointInRect(x, y, startX, startY, w, h) then
            -- se já estava selecionado, compra o item
            if self.selectedItemIndex == i then
                local selectedItem = self.itemsForSale[self.selectedItemIndex]
                if selectedItem then
                    self:buyItem(selectedItem, self.selectedItemIndex)
                    self:setPurchasedSlots(Player.inventory.items)
                    self.buyed = true
                    self.selectedItemIndex = 0
                    self.timer = 2
                    self.sounds.buy:play()
                end
            else
                -- caso contrário, apenas seleciona
                self:selectItem(i)
                self:selectItemSlot(i)
            end
            return
        end
    end
end

return ShopState