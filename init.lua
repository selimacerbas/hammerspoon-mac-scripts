hs.loadSpoon("Vifari")
hs.loadSpoon("KeyCaster")

------------------------------------------------------------
-- SpoonInstall + PaperWM
------------------------------------------------------------
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.PaperWM = {
    url    = "https://github.com/mogenson/PaperWM.spoon",
    desc   = "PaperWM.spoon repository",
    branch = "release",
}

spoon.SpoonInstall:andUse("PaperWM", {
    repo   = "PaperWM",
    start  = true,
    config = { screen_margin = 16, window_gap = 2 },
    fn     = function(s)
        PaperWM = s

        -- Safari handling (you can toggle this at runtime with ⌃⌥⌘S)
        local function includeSafari()
            s.window_filter:setAppFilter("Safari", {
                visible      = true,
                currentSpace = true,
                fullscreen   = false,          -- ignore fullscreen Safari
                allowRoles   = { "AXWindow" }, -- standard browser windows only
            })
        end
        includeSafari()
        local safariManaged = true

        -- Bind the built-in defaults
        s:bindHotkeys(s.default_hotkeys)

        -- Handy: refresh layout (fixes “index not found” glitches)
        local A = s.actions.actions()
        hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", A.refresh_windows)

        -- Toggle Safari tiling on/off (workaround for Safari oddities)
        hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
            if safariManaged then
                s.window_filter:setAppFilter("Safari", false) -- exclude completely
                safariManaged = false
                hs.alert.show("PaperWM: Safari EXCLUDED")
            else
                includeSafari()
                safariManaged = true
                hs.alert.show("PaperWM: Safari INCLUDED")
            end
            A.refresh_windows()
        end)

        ------------------------------------------------------------
        -- Modal “Nav Mode” — press ⌘ + Enter to enter; Esc to exit
        ------------------------------------------------------------
        local nav = hs.hotkey.modal.new({ "cmd" }, "return")
        local tip
        function nav:entered() tip = hs.alert.show("PaperWM: NAV MODE  (Esc to exit)") end

        function nav:exited() if tip then hs.alert.closeAll() end end

        -- exit keys
        nav:bind({}, "escape", function() nav:exit() end)
        nav:bind({ "cmd" }, "return", function() nav:exit() end) -- toggle out with ⌘↩

        -- movement (with repeat while held)
        nav:bind({}, "h", nil, A.focus_left, nil, A.focus_left)
        nav:bind({}, "j", nil, A.focus_down, nil, A.focus_down)
        nav:bind({}, "k", nil, A.focus_up, nil, A.focus_up)
        nav:bind({}, "l", nil, A.focus_right, nil, A.focus_right)

        -- quick layout controls
        nav:bind({}, "c", nil, A.center_window)
        nav:bind({}, "f", nil, A.full_width)
        nav:bind({}, "r", nil, A.cycle_width)

        -- switch space
        nav:bind({}, ",", nil, A.switch_space_l, A.switch_space_l)
        nav:bind({}, ".", nil, A.switch_space_r, nil, A.switch_space_r)
        nav:bind({}, "1", nil, A.switch_space_1, nil, A.switch_space_1)
        nav:bind({}, "2", nil, A.switch_space_2, nil, A.switch_space_2)
        nav:bind({}, "3", nil, A.switch_space_3, nil, A.switch_space_3)
    end
})

------------------------------------------------------------
-- Helper to auto-install single-spoon repos (no docs.json)
------------------------------------------------------------
local function ensureSpoon(name, gitURL, branch)
    local spoondir = os.getenv("HOME") .. "/.hammerspoon/Spoons/"
    local target   = spoondir .. name .. ".spoon"
    if not hs.fs.attributes(target) then
        hs.alert.show("Installing " .. name .. "…")
        local cmd = string.format(
            [[mkdir -p %q && /usr/bin/git clone --depth 1 %s %q %q]],
            spoondir,
            branch and ("-b " .. branch) or "",
            gitURL,
            target
        )
        -- normalize spaces
        cmd = cmd:gsub("%s%s+", " ")
        hs.execute(cmd)
    end
end
------------------------------------------------------------
-- Add-ons (auto-clone once, then load)
------------------------------------------------------------
ensureSpoon("ActiveSpace", "https://github.com/mogenson/ActiveSpace.spoon", "main")
ActiveSpace = hs.loadSpoon("ActiveSpace")
-- ActiveSpace.compact = true -- uncomment if you prefer a tighter menubar display
ActiveSpace:start()

ensureSpoon("WarpMouse", "https://github.com/mogenson/WarpMouse.spoon", "main")
WarpMouse = hs.loadSpoon("WarpMouse")
-- WarpMouse.margin = 8 -- optional: pixels beyond the edge before warp triggers
WarpMouse:start()

------------------------------------------------------------
-- Tips (not code): macOS Mission Control settings
-- - Uncheck: “Automatically rearrange Spaces based on most recent use”
-- - Check:   “Displays have separate Spaces”
------------------------------------------------------------


-- Optional: For column
spoon.KeyCaster:configure({
    mode                 = "column",
    fadingDuration       = 2.0,
    maxVisible           = 5,
    minAlphaWhileVisible = 0.35,
    followInterval       = 0.4,
    box                  = { w = 260, h = 36, spacing = 8, corner = 10 },
    position             = { corner = "bottomLeft", x = 20, y = 80 },
    margin               = { right = 20, bottom = 80 },
    font                 = { name = "Menlo", size = 18 }, -- change to any installed font name
    -- column behavior
    column               = {
        maxCharsPerBox = 14,  -- start a new box after 14 glyphs
        newBoxOnPause  = 0.70 -- or after 0.7s idle
    },
    -- line behaviour
    line                 = {
        box = { w = 420, h = 36, corner = 10 },
        maxSegments = 60,
        gap = 6, -- px between segments
    },
    -- visuals
})

-- Bind your requested hotkeys:
spoon.KeyCaster:bindHotkeys(spoon.KeyCaster.defaultHotkeys)

-- Vifari
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "D", function()
    hs.alert.show("Vifari Started")
    spoon.Vifari:start()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
    hs.alert.show("Vifari Stopped")
    spoon.Vifari:stop()
end)
