hs.loadSpoon("Vifari")
hs.loadSpoon("KeyCaster")

------------------------------------------------------------
-- FocusMode
------------------------------------------------------------
hs.loadSpoon("FocusMode")

-- (Optional) change settings before start
spoon.FocusMode.dimAlpha = 0.5
spoon.FocusMode.mouseDim = true
spoon.FocusMode.windowCornerRadius = 8

-- (Optional) rebind hotkeys (defaults are ⌃⌥⌘ I to start, ⌃⌥⌘ O to stop)
spoon.FocusMode:bindHotkeys({
    start = { { "ctrl", "alt", "cmd" }, "I" },
    stop  = { { "ctrl", "alt", "cmd" }, "O" },
})

-- Start automatically on launch (optional)
spoon.FocusMode:start()

------------------------------------------------------------
--CursorScope
------------------------------------------------------------
hs.loadSpoon("CursorScope")
spoon.CursorScope:configure({
    global = { fps = 60 },
    cursor = {
        shape = "ring",
        radius = 32,
        idleColor = { red = 0.2, green = 1, blue = 0.2, alpha = 0.9 },
        clickColor = { red = 1, green = 0.3, blue = 0.1, alpha = 1.0 },
    },
    scope = {
        enabled  = true,
        shape    = "rectangle",
        size     = 400,
        zoom     = 2.5,
        position = { corner = "topLeft", x = 24, y = 24 },
    },
})
spoon.CursorScope:bindHotkeys() -- ⌃⌥⌘Z start, ⌃⌥⌘U stop

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

        -- (keep your Safari block as-is)
        local function includeSafari()
            s.window_filter:setAppFilter("Safari", {
                visible      = true,
                currentSpace = true,
                fullscreen   = false,
                allowRoles   = { "AXWindow" },
            })
        end
        includeSafari()
        local safariManaged = true

        -- ① Bind defaults
        s:bindHotkeys(s.default_hotkeys)

        -- -- ② Make “half” the only width in the cycle list
        s.window_ratios = { 1 / 2 } -- always snap to 50% when we cycle. (Doc: window_ratios)
        --
        --
        -- -- ③ Auto-normalize new/visible windows to 50%
        local A = s.actions.actions() -- PaperWM actions table (zero-arg functions)  -- uses API shown in repo README
        local normalized = {}         -- remember which windows we've normalized

        local function normalizeToHalf(win)
            if not win then return end
            local id = win:id()
            if not id or normalized[id] then return end

            -- only act on windows PaperWM actually manages
            if not s.window_filter:isWindowAllowed(win) then return end -- hs.window.filter API

            -- make sure PaperWM has (re)indexed windows before acting
            s:refreshWindows() -- PaperWM API

            -- give PaperWM a moment to anchor the window, then set it to 50%
            hs.timer.doAfter(0.10, function()
                local prev = hs.window.frontmostWindow()
                win:focus()
                A.cycle_width() -- with window_ratios={1/2}, one cycle => 50%
                normalized[id] = true
                if prev and prev:id() ~= id then prev:focus() end
            end)
        end

        -- subscribe to relevant events from the spoon’s window_filter
        s.window_filter:subscribe({
            hs.window.filter.windowCreated,
            hs.window.filter.windowVisible,
        }, function(win)
            -- slight debounce so PaperWM can see the window
            hs.timer.doAfter(0.05, function() normalizeToHalf(win) end)
        end)


        -- Your existing helpers…
        hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", A.refresh_windows)

        hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
            if safariManaged then
                s.window_filter:setAppFilter("Safari", false)
                safariManaged = false
                hs.alert.show("PaperWM: Safari EXCLUDED")
            else
                includeSafari()
                safariManaged = true
                hs.alert.show("PaperWM: Safari INCLUDED")
            end
            A.refresh_windows()
        end)

        -- Modal “Nav Mode” (keep as-is)
        local nav = hs.hotkey.modal.new({ "cmd" }, "return")
        local tip
        function nav:entered() tip = hs.alert.show("PaperWM: NAV MODE  (Esc to exit)") end

        function nav:exited() if tip then hs.alert.closeAll() end end

        -- ——— Space-safe wrappers, This part is crucial with the integration of FocusMode ---
        local function now() return hs.timer.secondsSinceEpoch() end
        local lastMoveAt = 0

        local function wrapMove(fn)
            return function()
                lastMoveAt = now()
                -- optional: quiet FocusMode if it’s running
                if _G.FocusMode and FocusMode._running and FocusMode._suspend then
                    FocusMode:_suspend(1.2)
                end
                fn()                                      -- perform PaperWM move_window_N
                hs.timer.doAfter(0.25, A.refresh_windows) -- let Mission Control settle, then refresh
            end
        end

        local function withRefresh(fn)
            return function()
                local dt = now() - lastMoveAt
                if dt < 1.0 then
                    -- if this follows a move, give Spaces a tick before refreshing+focusing
                    hs.timer.doAfter(0.15, function()
                        A.refresh_windows(); fn()
                    end)
                else
                    A.refresh_windows()
                    fn()
                end
            end
        end

        local function wrapSwitch(fn)
            return function()
                fn()
                hs.timer.doAfter(0.25, A.refresh_windows)
            end
        end
        nav:bind({}, "escape", function() nav:exit() end)
        nav:bind({ "cmd" }, "return", function() nav:exit() end)

        nav:bind({}, "h", nil, withRefresh(A.focus_left), nil, withRefresh(A.focus_left))
        nav:bind({}, "l", nil, withRefresh(A.focus_right), nil, withRefresh(A.focus_right))
        nav:bind({}, "j", nil, withRefresh(A.focus_down), nil, withRefresh(A.focus_down))
        nav:bind({}, "k", nil, withRefresh(A.focus_up), nil, withRefresh(A.focus_up))

        nav:bind({ "shift" }, "h", nil, withRefresh(A.swap_left), nil, withRefresh(A.swap_left))
        nav:bind({ "shift" }, "j", nil, withRefresh(A.swap_down), nil, withRefresh(A.swap_down))
        nav:bind({ "shift" }, "k", nil, withRefresh(A.swap_up), nil, withRefresh(A.swap_up))
        nav:bind({ "shift" }, "l", nil, withRefresh(A.swap_right), nil, withRefresh(A.swap_right))

        nav:bind({}, "c", nil, A.center_window)
        nav:bind({}, "f", nil, A.full_width)
        nav:bind({}, "r", nil, A.cycle_width)

        nav:bind({}, ",", nil, wrapSwitch(A.switch_space_l), wrapSwitch(A.switch_space_l))
        nav:bind({}, ".", nil, wrapSwitch(A.switch_space_r), wrapSwitch(A.switch_space_r))
        nav:bind({}, "1", nil, wrapSwitch(A.switch_space_1), wrapSwitch(A.switch_space_1))
        nav:bind({}, "2", nil, wrapSwitch(A.switch_space_2), wrapSwitch(A.switch_space_2))
        nav:bind({}, "3", nil, wrapSwitch(A.switch_space_3), wrapSwitch(A.switch_space_3))

        nav:bind({ "shift" }, "1", nil, wrapMove(A.move_window_1), nil, wrapMove(A.move_window_1))
        nav:bind({ "shift" }, "2", nil, wrapMove(A.move_window_2), nil, wrapMove(A.move_window_2))
        nav:bind({ "shift" }, "3", nil, wrapMove(A.move_window_3), nil, wrapMove(A.move_window_3))
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
    mode                 = "line",
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


-- Load and auto-start Vifari
if hs.loadSpoon("Vifari") and spoon.Vifari then
    spoon.Vifari:start()
else
    hs.alert.show("Vifari spoon not found")
end

-- Your hotkeys can stay as-is:
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "D", function()
    hs.alert.show("Vifari Started")
    spoon.Vifari:start()
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "S", function()
    hs.alert.show("Vifari Stopped")
    spoon.Vifari:stop()
end)
