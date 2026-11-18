----------------------------------------
-- Importações de Módulos
----------------------------------------
require("modules.engine.animation")
require("modules.utils")

----------------------------------------
-- ENUM de Items e Upgrades
----------------------------------------

BUFF_TYPE = {}
BUFF_TYPE.UPGRADE = "upgrade"
BUFF_TYPE.ITEM = "item"

UPGRADE = {}
UPGRADE.PARRY = "parry"
UPGRADE.SHIELD = "shield"
UPGRADE.DEFIBRILLATOR = "defibrillator"
UPGRADE.REVERSE_CARD = "reverse card"
UPGRADE.LUCKY_TOTEM = "lucky totem"
UPGRADE.STOPWATCH = "stopwatch"

ITEM = {}
ITEM.FLASHBANG = "flashbang"
ITEM.POTION = "potion"
ITEM.ENERGY_DRINK = "energy drink"

----------------------------------------
-- Entidade Item/Upgrade
----------------------------------------

ItemUpgrade = {}
ItemUpgrade.__index = ItemUpgrade

-- cria um novo buff, o id é um dos enums acima
function ItemUpgrade.new(id, desc, effectFunc, type, quantity, onStart)
	local buff = setmetatable({}, ItemUpgrade)
	buff.id = id
	buff.description = desc
	buff.applyEffect = effectFunc
	buff.onStart = onStart or false
	buff.type = type
	buff.initialQuantity = quantity or 1
	buff.quantity = buff.initialQuantity

	local spritePath = pngPathFormat({ "assets", "buffs", id })
	buff.sprite = love.graphics.newImage(spritePath)

	return buff
end

-- na hora do combate, ativa o efeito do item/upgrade e o discarta
function ItemUpgrade:activate(creature, ...)
	self.applyEffect(creature, ...)
	creature.inventory:discardBuff(self)
end

function ItemUpgrade:draw(pos, scale, withQuantity)
	love.graphics.draw(self.sprite, pos[1], pos[2], 0, scale, scale)
	if withQuantity then
		local qtyText = tostring(self.quantity) .. "x"
		local previousFont = love.graphics.getFont()
		love.graphics.setFont(returnFont(24))
		love.graphics.print(qtyText, pos[1] + 20, pos[2] + 20)
		love.graphics.setFont(previousFont)
	end
end
