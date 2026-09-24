----------------------------------------
-- Importações de módulos
----------------------------------------
require("modules.actions")
require("modules.utils")
require("modules.constructors.buffs")

-- prevent invalid actions by returning to defaults
local function solveInvalidAction(action, self)
	if action == ACTION.ATK and self.ammo == 0 then
		return ACTION.RECHARGE
	elseif action == ACTION.HEAVY_ATK and self.ammo < 2 then
		return ACTION.RECHARGE
	elseif action == ACTION.COUNTER and self.counters == 0 then
		return ACTION.DEFENSE
	else
		return action
	end
end

Oponents = {}
Oponents.JOSHUA = "Joshua"
Oponents.DJABO = "D'Jabo"
Oponents.LARRY = "Larry"
Oponents.OZARD = "O'Zard"
Oponents.SEBASTIAO = "Sebastiao"
Oponents.ABERRATION = "Aberracao"

-- Emo
function initJoshua()
	-- Joshua. He's an emo. Has the most basic decision
	local joshuaStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
				{ weight = 1, value = ACTION.COUNTER },
				{ weight = 1, value = ACTION.DEFENSE },
				{ weight = 2, value = ACTION.RECHARGE },
				{ weight = 3, value = ACTION.HEAVY_ATK }, -- focus on doing a heavy attack
				{ weight = 3, value = ACTION.ATK }, -- focus on attacks
		}
		-- increase chance of recharging
		if self.ammo == 0 then
			actions[3].weight = 9
		end

		-- prevent invalid actions
		local choice = weightedChoice(actions)
		return solveInvalidAction(choice, self)
	end

	return Oponent.new(Oponents.JOSHUA, 200, 3, nil, nil, joshuaStrategy)
end

-- Djabo
function initDjabo()
	-- Djabo is a cheater
	-- Relies on counter and furiously attacking
	local djaboStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
			{ weight = 2, value = ACTION.COUNTER },
			{ weight = 1, value = ACTION.DEFENSE },
			{ weight = 3, value = ACTION.RECHARGE },
			{ weight = 3, value = ACTION.HEAVY_ATK },
			{ weight = 3, value = ACTION.ATK },
		}
		-- increase chance of recharging if no charges
		if self.ammo == 0 then
			actions[3].weight = 9
		end

		-- player may use heavy attack
		-- so increase counter
		if player.ammo >= 3 then
			actions[1].weight = 3
		end

		-- increase chance to attack if more ammo
		if self.ammo >= 2 then
			actions[4].weight = 4
			actions[5].weight = 5
		end

		-- prevent invalid actions
		local choice = solveInvalidAction(weightedChoice(actions), self)
		if (choice == ACTION.ATK or choice == ACTION.HEAVY_ATK)
			and player.ammo >= 3
			and self:hasItem(ITEM.FLASHBANG)
			and math.random() < 0.4 then
			self:useItem(ITEM.FLASHBANG)
		end

		return choice
	end

	-- Has flashbangs and reverse cards and more counters
	return Oponent.new(Oponents.DJABO, 200, 3, {initFlashbang(2)}, {initReverseCard(), initReverseCard()}, djaboStrategy)
end


-- Pirata
function initLarry()
	-- Larry is a pirate
	-- Relies on luck (has a totem)
	-- Tries to shoot whenever possible
	local larryStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
			{ weight = 1, value = ACTION.COUNTER },
			{ weight = 2, value = ACTION.HEAVY_ATK },
			{ weight = 4, value = ACTION.RECHARGE },
			{ weight = 2, value = ACTION.DEFENSE },
			{ weight = 4, value = ACTION.ATK },
		}
		-- increase chance of recharging
		if self.ammo == 0 then
			actions[3].weight = 9
		end

		-- prevent invalid actions
		local choice = weightedChoice(actions)
		return solveInvalidAction(choice, self)
	end

	-- has totem
	return Oponent.new(Oponents.LARRY, 200, 3, nil, {initTotem()}, larryStrategy)
end

-- OZard
-- Its a healer and defender (has a potion and shield)
-- Uses only heavy attacks
function initOZard()
	local ozardStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
			{ weight = 1, value = ACTION.COUNTER },
			{ weight = 2, value = ACTION.HEAVY_ATK }, -- focus on doing a heavy attack
			{ weight = 4, value = ACTION.RECHARGE },
			{ weight = 4, value = ACTION.DEFENSE },
			{ weight = 2, value = ACTION.ATK }, -- focus on attacks
		}

		if self.hp < self.maxHp / 2 and self:hasItem(ITEM.POTION) and math.random() < 0.6 then
				self:useItem(ITEM.POTION)
		end

-- increase chance of recharging
		if self.ammo == 0 then
				actions[3].weight = 9
		end

		if player.hp < player.maxHp / 2 then
			actions[5].weight = 4
			actions[4].weight = 2
		end

		-- prevent invalid actions
		local choice = weightedChoice(actions)
		return solveInvalidAction(choice, self)
	end

	-- add shield and potions
	return Oponent.new(Oponents.OZARD, 200, 3, {initPotion(2)}, {initShield()}, ozardStrategy)
end

-- Cangaceiro
function initSebastiao()
	local sebastiaoStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
			{ weight = 1, value = ACTION.COUNTER },
			{ weight = 3, value = ACTION.HEAVY_ATK },
			{ weight = 4, value = ACTION.RECHARGE },
			{ weight = 2, value = ACTION.DEFENSE },
			{ weight = 4, value = ACTION.ATK },
		}
		-- increase chance of recharging
		if self.ammo == 0 then
			actions[3].weight = 9
		end

		-- prevent invalid actions
		local choice = solveInvalidAction(weightedChoice(actions), self)

		-- uses energy drinks on heavy attacks
		if choice == ACTION.HEAVY_ATK and self:hasItem(ITEM.ENERGY_DRINK) and math.random() < 0.7 then
				self:useItem(ITEM.ENERGY_DRINK)
		end

		-- tries to use energy drinks more precautios
		if choice == ACTION.ATK and self:hasItem(ITEM.ENERGY_DRINK) and math.random() < 0.3 then
				self:useItem(ITEM.ENERGY_DRINK)
		end

		return choice
	end

	-- sebastian, he can parry and drink energetic to give a boost
	return Oponent.new(Oponents.SEBASTIAO, 200, 3, {initEnergyDrink(3)}, {initParry()}, sebastiaoStrategy)
end

-- Aberração
function initAberration()
	-- Changes its statistics to fight
    -- Works with probabilities, increase the probabilities according to the environment
	-- Also has a strange power to affect the player senses
    local aberrationStrategy = function(self, player, turn, hist)
		-- 1 = counter
		-- 2 = heavy atk
		-- 3 = recharge
		-- 4 = defense
		-- 5 = atk
		local actions = {
			{ weight = 2, value = ACTION.COUNTER },
			{ weight = 2, value = ACTION.HEAVY_ATK },
			{ weight = 2, value = ACTION.RECHARGE },
			{ weight = 2, value = ACTION.DEFENSE },
			{ weight = 2, value = ACTION.ATK },
		}

		-- if with less than half of health
		-- interfes with player action slots
		if self.hp <= self.maxHp / 2 and math.random() < 0.6 then
			GAMESTATE[GameCtx]:shuffleActionSlots()
		end

		if self.ammo <= 2 then
			actions[3].weight = 3
		end

		if self.ammo == 0 then
			actions[3].weight = 7
		end

		if player.ammo >= 5 then
			actions[4].weight = 5
			actions[1].weight = 3
		end

		if player.hp <= player.maxHp / 2 then
			actions[5].weight = 5
			actions[2].weight = 2
		end

		-- prevent invalid actions
		local choice = weightedChoice(actions)
		return solveInvalidAction(choice, self)
	end

	return Oponent.new(Oponents.ABERRATION, 250, 3, {initEnergyDrink(2)}, {initReverseCard(), initDefibrillator(85)}, aberrationStrategy)
end
