----------------------------------------
-- Estado Confronto
----------------------------------------

Combat = {}
Combat.WIN = "vitoria"
Combat.LOSS = "derrota"
Combat.ONGOING = "inacabado"
Combat.sounds = {
	SHIELD_BREAK = love.audio.newSource("sounds/shield_breaking.mp3", "static"),
	DEATH_01 = love.audio.newSource("sounds/death_01.mp3", "static"),
	DEATH_02 = love.audio.newSource("sounds/death_02.mp3", "static"),
	DEATH_03 = love.audio.newSource("sounds/death_03.mp3", "static"),
	DEATH_BOSS = love.audio.newSource("sounds/death_boss.mp3", "static"),
	COUNTER = love.audio.newSource("sounds/counter.mp3", "static"),
	RELOAD = love.audio.newSource("sounds/reload.mp3", "static"),
	DEFENSE = love.audio.newSource("sounds/defense.mp3", "static"),
	ATTACK_01 = love.audio.newSource("sounds/attack_01.mp3", "static"),
	ATTACK_02 = love.audio.newSource("sounds/attack_02.mp3", "static"),
	-- ATTACK_03 = love.audio.newSource("sounds/attack_03.mp3", "static"),
	HEAVY_ATTACK_01 = love.audio.newSource("sounds/heavy_attack_01.mp3", "static"),
	HEAVY_ATTACK_02 = love.audio.newSource("sounds/heavy_attack_02.mp3", "static"),
	-- HEAVY_ATTACK_03 = love.audio.newSource("sounds/heavy_attack_03.mp3", "static"),
}

Combat.soundPriority = {
	DEATH = 1,
	COUNTER = 2,
	HEAVY_ATTACK = 3,
	ATTACK = 4,
	DEFENSE = 5,
	RELOAD = 6,
}
Combat.queuedSounds = {}
Combat.queuedSoundsBySource = {}
Combat.baseVolumes = {}

function Combat.beginSoundRound()
	Combat.queuedSounds = {}
	Combat.queuedSoundsBySource = {}
end

-- enfileira os sons por prioridade
function Combat.queueSound(sound, priority)
	-- armazena volume inicial
	if not Combat.baseVolumes[sound] then
		Combat.baseVolumes[sound] = sound:getVolume()
	end

	-- se já existe, não adiciona de novo na fila
	local queuedSound = Combat.queuedSoundsBySource[sound]
	if queuedSound then return end

	queuedSound = { sound = sound, priority = priority }
	table.insert(Combat.queuedSounds, queuedSound)
	Combat.queuedSoundsBySource[sound] = queuedSound
end

-- toca as músicas enfileiradas
function Combat.playQueuedSounds()
	local highestPriority = Combat.soundPriority.RELOAD

	-- descobre que tem a menor prioridade (menor numero)
	for _, queuedSound in ipairs(Combat.queuedSounds) do
		highestPriority = math.min(highestPriority, queuedSound.priority)
	end

	-- itera sobre a fila e quem tiver menor prioridade é tocado com volume menor
	for _, queuedSound in ipairs(Combat.queuedSounds) do
		local volumeMultiplier = queuedSound.priority > highestPriority and 0.2 or 1
		local sound = queuedSound.sound
		sound:setVolume(Combat.baseVolumes[sound] * volumeMultiplier)
		sound:play()
	end
end

local function attackSoundKey(prefix, variation)
	return string.format("%s_%02d", prefix, tonumber(variation) or 1)
end

-- associa uma criatura a um som de ataque
function Combat.assimilateAttacks(creature, attackVariation, heavyAttackVariation)
	creature.attackSound = Combat.sounds[attackSoundKey("ATTACK", attackVariation)]
	creature.heavyAttackSound = Combat.sounds[attackSoundKey("HEAVY_ATTACK", heavyAttackVariation)]
end

-- infileira o som de ataque
function Combat.playAttackSound(creature, isHeavyAttack)
	local sound = isHeavyAttack and creature.heavyAttackSound or creature.attackSound
	local priority = isHeavyAttack and Combat.soundPriority.HEAVY_ATTACK or Combat.soundPriority.ATTACK
	Combat.queueSound(sound, priority)
end

----------------------------------------
-- Funções de combate
----------------------------------------

-- simula um turno do combate, retornando o resultado do combate após o turno
function simulateTurn(player, oponent, hist)
	Combat.beginSoundRound()
	oponent:setAction(oponent:makeDecision(player, hist))

	useItems(player, oponent)
	useItems(oponent, player)

	invalidPlayerAction = validateAction(player, hist)
	invalidOponentAction = validateAction(oponent, hist)

	-- acao player invalida == VACILO
	if invalidPlayerAction then
		player.action = ACTION.MISS
	end

	-- acao oponent invalida == RECARGA
	if invalidOponentAction then
		oponent.action = ACTION.RECHARGE
	end

	applyAction(player, oponent)
	applyAction(oponent, player)

	local result = combatResult(player, oponent)
	Combat.playQueuedSounds()
	return result
end

-- retorna true se a ação for inválida, false caso contrário
function validateAction(creature, hist)
	local action = creature.action

	if action == ACTION.ATK then
		-- sem munição suficiente
		if creature.ammo < 1 then
			return true
		end
	elseif action == ACTION.HEAVY_ATK then
		-- sem munição suficiente
		if creature.ammo < 2 then
			return true
		end
	elseif action == ACTION.COUNTER then
		-- sem contra-ataques restantes
		if creature.counters < 1 then
			return true
		end
	elseif action == ACTION.DEFENSE then
		if creature.defCount >= 2 then
			creature.defCount = 0
			return true
		end
	end

	return false
end

--
function applyAction(attacker, target)
	local attackerAction = attacker.action
	local targetAction = target.action

	if attackerAction == ACTION.RECHARGE then
		reload(attacker)
	elseif attackerAction == ACTION.ATK then
		Combat.playAttackSound(attacker, false)
		if targetAction == ACTION.COUNTER then
			attack(attacker, attacker)
			spendAmmo(attacker)
			Combat.queueSound(Combat.sounds.COUNTER, Combat.soundPriority.COUNTER)
		else
			attack(target, attacker)
			spendAmmo(attacker)
		end
	elseif attackerAction == ACTION.HEAVY_ATK then
		Combat.playAttackSound(attacker, true)
		if targetAction == ACTION.COUNTER then
			heavyAttack(attacker, attacker)
			spendAmmo(attacker)
			Combat.queueSound(Combat.sounds.COUNTER, Combat.soundPriority.COUNTER)
		else
			heavyAttack(target, attacker)
			spendAmmo(attacker)
		end
	elseif attackerAction == ACTION.COUNTER then
		attacker.counters = attacker.counters - 1
	elseif attackerAction == ACTION.DEFENSE then
		attacker.defCount = attacker.defCount + 1
		Combat.queueSound(Combat.sounds.DEFENSE, Combat.soundPriority.DEFENSE)
	end

	if attackerAction ~= ACTION.DEFENSE then
		attacker.defCount = 0
	end
end

function combatResult(player, oponent)
	if player.hp <= 0 then
		return Combat.LOSS
	elseif oponent.hp <= 0 then
		return Combat.WIN
	else
		return Combat.ONGOING
	end
end

-- ativa os itens que estão em usedItems
function useItems(creature, oponent)
	for _, buff in pairs(creature.inventory.usedQueue) do
		if buff.type == BUFF_TYPE.ITEM then
			buff:activate(creature, oponent)
		end
	end
end

----------------------------------------
-- Habilidades
----------------------------------------

function reload(creature)
	creature.ammo = creature.ammo + 1
	Combat.queueSound(Combat.sounds.RELOAD, Combat.soundPriority.RELOAD)
end

function attack(target, attacker)
	if target.action ~= ACTION.DEFENSE then
		causeDamage(target, 40, attacker)
	else
		defense(target)
	end
end

function heavyAttack(target, attacker)
	if target.action ~= ACTION.DEFENSE then
		causeDamage(target, 80, attacker)
	else
		defense(target)
		causeDamage(target, 30, attacker)
	end
end

function defense(target)
	local parry = target:hasUpgrade(UPGRADE.PARRY)
	if parry then
		parry:activate(target, 1)
	end
end

function spendAmmo(creature)
	local amount = 0

	if creature.action == ACTION.ATK then
		amount = 1
	elseif creature.action == ACTION.HEAVY_ATK then
		amount = 2
	end

	local totem = creature:hasUpgrade(UPGRADE.LUCKY_TOTEM)
	if totem then
		totem:activate(creature, amount)
	end

	creature.ammo = creature.ammo - amount
end

function cure(creature)
	local cure
	if creature.hp + 60 <= creature.maxHp then
		cure = 60
	else
		cure = creature.maxHp - creature.hp
	end
	
	creature.hp = creature.hp + cure
	if cure > 0 then
		GAMESTATE[CTX.BATTLE]:addDamageOrHealingText(creature, cure)
	end
end

function causeDamage(target, dmg, attacker)
	if target.shielded then
		target.shielded = false
		GAMESTATE[CTX.BATTLE]:onShieldBroken(target)
		local priority = attacker.action == ACTION.HEAVY_ATK and Combat.soundPriority.HEAVY_ATTACK
			or Combat.soundPriority.ATTACK
		Combat.queueSound(Combat.sounds.SHIELD_BREAK, priority)

		return
	end

	dmg = dmg * attacker.dmgMult
	target.dmgTimer = 0.5
  
	if target.name == "you" then
		camera:shake(dmg / 100, 0.5)
	end

	GAMESTATE[CTX.BATTLE]:addDamageOrHealingText(target, -dmg)

	if target.hp - dmg <= 0 then
		local defibrillator = target:hasUpgrade(UPGRADE.DEFIBRILLATOR)
		if defibrillator then
			defibrillator:activate(target)
		else
			target.hp = 0
			target.action = ACTION.DEAD

			if target.name == Oponents.ABERRATION then
				Combat.queueSound(Combat.sounds.DEATH_BOSS, Combat.soundPriority.DEATH)
			else
				local deathSounds = {
					Combat.sounds.DEATH_01,
					Combat.sounds.DEATH_02,
					Combat.sounds.DEATH_03,
				}
				Combat.queueSound(deathSounds[math.random(#deathSounds)], Combat.soundPriority.DEATH)
			end
		end
	else
		target.hp = target.hp - dmg
	end
end
