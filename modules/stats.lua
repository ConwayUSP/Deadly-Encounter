-- Contabiliza estatísticas de run do jogo
-- Exibe essas estatísticas como table/string
-- Lista de estatísticas:
--  * Tempo de jogo (time)
--  * Inimigos derrotados (enemiesDefeated)
--  * Dano recebido (damangeTaken)
--  * Turnos executados (turns)

local Stats = {}

Stats.time = 0
Stats.enemiesDefeated = 0
Stats.damangeTaken = 0
Stats.damageDone = 0
Stats.turns = 0
Stats.itemsBought = 0
Stats.itemsUsed = 0

-- Reseta estatísitca
function Stats.reset()
    Stats.time = 0
    Stats.enemiesDefeated = 0
    Stats.damangeTaken = 0
    Stats.damageDone = 0
    Stats.turn = 0
    Stats.itemsBought = 0
    Stats.itemsUsed = 0
end

-- Incrementa estatísitca de duração da partida
function Stats.tick(dt)
    Stats.time = Stats.time + math.min(dt, 0.25)
end

-- Incrementa estatísitca de inimigos vencidos
function Stats.incEnemyDefeated()
    Stats.enemiesDefeated = Stats.enemiesDefeated + 1
end

-- Adiciona dmg a estatística de dano tomado
function Stats.addDamageDone(dmg)
    Stats.damageDone = Stats.damageDone + dmg
end

-- Adiciona dmg a estatísticas de dano recebido
function Stats.addDamageTaken(dmg)
    Stats.damangeTaken = Stats.damangeTaken + dmg
end

-- Incrementa contagem de turnos executados
function Stats.incTurn()
    Stats.turns = Stats.turns + 1
end

-- Incrementa estatistica de itens comprados na loja
function Stats.incItemBought()
    Stats.itemsBought = Stats.itemsBought + 1
end

-- Incrementa estatísitca de item usado
function Stats.incItemUsed()
    Stats.itemsUsed = Stats.itemsUsed + 1
end

-- Retorna duração da partida como string em mm:ss
function Stats.getTimeAsString()
    local intSeconds = math.floor(Stats.time)
    return string.format("%dm %02ds",
        math.floor(intSeconds / 60),
        intSeconds % 60
    )
end

return Stats
