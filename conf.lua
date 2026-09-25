function love.conf(t)
    -- No mobile, largura maior que altura fixa a orientação em landscape.
    t.window.width = 1920
    t.window.height = 1080

    t.window.title = "Deadly Encounter"
    t.window.icon = "assets/icon.png"
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.resizable = false

    -- Threads are not available on the web, so keep this disabled
    t.modules.thread = false
end
