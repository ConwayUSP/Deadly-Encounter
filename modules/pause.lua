-- Renderiza um botão de pausa dentro da Arena de Batalha e Loja
-- Possui dois modos de tela: "menu" com botões de resumir, encerrar a partida ou abrir o tutorial
-- "tutorial" mostra o tutorial de referência do jogo.
-- "<Esc>" para entrar e sair do menu de pausa
-- Toca a musica do menu principal do jogo de fundo

require("modules.engine.text")
require("modules.utils")
local Resolution = require("modules.resolution")

local Pause = {}

Pause.isOpen = false
Pause.view = "menu" -- "menu" | "tutorial"
Pause.buttons = {}
Pause.texts = {}
Pause.sounds = {}

local ICON_SIZE, ICON_MARGIN = 56, 16
local BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_GAP = 360, 90, 24

function Pause.load()
    local width, height = Resolution.getUIDimensions()

    Pause.icon = {
        x = width - ICON_SIZE - ICON_MARGIN,
        y = ICON_MARGIN,
        w = ICON_SIZE,
        h = ICON_SIZE,
        padding = 12
    }

    -- botoes do menu de pausa
    local options = {
        { label = "Resume",   action = function() Pause.resume() end },
        { label = "Tutorial", action = function() Pause.openTutorial() end },
        { label = "Quit",     action = function() Pause.quitToMenu() end },
    }

    -- calcula posicao dos botoes, centrados na tela e com espaçamento
    local totalHeight = #options * BUTTON_HEIGHT + (#options - 1) * BUTTON_GAP
    local startY = (height - totalHeight) / 2 + 40 -- espaço para o titulo
    local x = (width - BUTTON_WIDTH) / 2

    Pause.buttons = {}
    for i, option in ipairs(options) do
        local y = startY + (i - 1) * (BUTTON_HEIGHT + BUTTON_GAP)
        Pause.buttons[i] = {
            x = x,
            y = y,
            w = BUTTON_WIDTH,
            h = BUTTON_HEIGHT,
            action = option.action,
            text = Text.new(option.label, 40, { 1, 1, 1, 1 }, { width / 2, y + BUTTON_HEIGHT / 2 }, 0, true)
        }
    end

    Pause.texts.title = Text.new("Paused", 72, { 1, 1, 1, 1 }, { width / 2, startY - 80 }, 0, true)

    Pause.texts.tutorialPrompt = Text.new(
        isMobile() and "Tap to Go back" or "Press any key to go back",
        32,
        { 0, 0, 0, 1 },
        { width / 2, 64 },
        0,
        false,
        math.huge,
        nil,
        width / 2 - 64
    )
    Pause.texts.tutorialPrompt.align = "right"

    Pause.sounds.bg = love.audio.newSource("sounds/menu_bg.wav", "static")
	Pause.sounds.bg:setLooping(true)
	Pause.sounds.bg:setVolume(0.15)
end

--  Permite pausar o jogo apenas no campo de batalha ou na loja
function Pause.canPause()
    return GameCtx == CTX.BATTLE or GameCtx == CTX.SHOP
end

function Pause.open()
    Pause.isOpen = true
    Pause.view = "menu"
    Pause.sounds.paused = love.audio.pause()
    love.audio.play(Pause.sounds.bg)
end

function Pause.resume()
    love.audio.pause(Pause.sounds.bg)
    love.audio.play(Pause.sounds.paused)
    Pause.sounds.paused = nil
    Pause.isOpen = false
end

function Pause.openTutorial()
    Pause.tutorialImage = love.graphics.newImage("assets/UI/tutorial/tutorial.jpg")
    Pause.view = "tutorial"
end

-- volta ao menu do jogo, limpando recursos de audio
function Pause.quitToMenu()
    love.audio.stop()
    Pause.sounds.paused = nil
    Pause.isOpen = false
    SetGameCtx(CTX.MENU)
end

function Pause.keypressed(key)
    if Pause.isOpen then
        if Pause.view == "tutorial" then
            Pause.view = "menu"
        elseif Pause.view == "menu" and key == "escape" then
            Pause.resume()
        end
        return true
    elseif not Pause.isOpen and Pause.canPause() and key == "escape" then
        Pause.open()
    end
    return false
end

function Pause.mousepressed(x, y, button)
    if button ~= 1 then return false end
    local screenX, screenY = Resolution.toScreenCoordinates(x, y)
    if screenX == nil and screenY == nil then return false end

    if Pause.isOpen then
        if Pause.view == "menu" then
            -- executa um botao clicado
            for _, btn in ipairs(Pause.buttons) do
                if isPointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
                    btn.action()
                end
            end
        elseif Pause.view == "tutorial" then
            Pause.view = "menu"
        end
        return true
    -- abre a pausa se o icon foi clicado
    elseif not Pause.isOpen and Pause.canPause() and isPointInRect(x, y, Pause.icon.x, Pause.icon.y, Pause.icon.w, Pause.icon.h) then
        Pause.open()
        return true
    end
    return false
end

function Pause.draw()
    if not Pause.isOpen and Pause.canPause() then
        Pause.drawIcon()
    elseif Pause.isOpen and Pause.view == "menu" then
        Pause.drawMenuScreen()
    elseif Pause.isOpen and Pause.view == "tutorial" then
        Pause.drawTutorialScreen()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Pause.drawIcon()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", Pause.icon.x, Pause.icon.y, Pause.icon.w, Pause.icon.h)
    love.graphics.setColor(1, 1, 1, 1)
end

function Pause.drawTutorialScreen()
    local screenW, screenH = Resolution.getGameDimensions()
    love.graphics.draw(Pause.tutorialImage, 0, 0, 0, screenW / Pause.tutorialImage:getWidth(),
        screenH / Pause.tutorialImage:getHeight())
    Pause.texts.tutorialPrompt:draw()
end

function Pause.drawMenuScreen()
    -- cria um véu semi transparente no fundo
    local screenW, screenH = Resolution.getGameDimensions()
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    Pause.texts.title:draw()

    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    for _, button in ipairs(Pause.buttons) do
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h)
        button.text:draw()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Pause
