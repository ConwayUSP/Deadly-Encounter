----------------------------------------
-- Importação de módulos
----------------------------------------
require("modules.gamectx")

----------------------------------------
-- Tabela de estados do jogo
----------------------------------------

GAMESTATE = {}
GAMESTATE[CTX.MENU] = require("modules.gamestates.menu")
GAMESTATE[CTX.TUTORIAL] = require("modules.gamestates.tutorial")
GAMESTATE[CTX.BATTLE] = require("modules.gamestates.battle")
GAMESTATE[CTX.SHOP] = require("modules.gamestates.shop")
GAMESTATE[CTX.DEATH_SCREEN] = require("modules.gamestates.deathscreen")
GAMESTATE[CTX.VICTORY_SCREEN] = require("modules.gamestates.victoryscreen")
