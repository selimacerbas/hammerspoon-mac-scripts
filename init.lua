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
-- PaperWM via ensureSpoon (git) — pick branch in one place
--
-- No hotkeys. You manually set the branch below, then reload
-- Hammerspoon (Cmd-Opt-Ctrl-R in your setup or from the menu).
-- The helper clones/updates PaperWM on that branch and loads it.
------------------------------------------------------------

------------------------------------------------------------
-- 0) Choose your PaperWM branch here
------------------------------------------------------------
local PAPERWM_BRANCH = "main" -- change to "release" when you want

------------------------------------------------------------
-- 1) Generic git-based spoon installer/updater
------------------------------------------------------------
local HOME           = os.getenv("HOME")
local SPOON_DIR      = HOME .. "/.hammerspoon/Spoons"

local function exists(p)
    return hs.fs.attributes(p) ~= nil
end

local function sh(cmd)
    local out, ok, _, rc = hs.execute(cmd, true)
    return (ok == true and rc == 0), (out or "")
end

-- ensureSpoonGit(name, url, opts)
-- opts.branch (string): git branch to ensure
-- opts.depth  (int|nil): default 1
-- opts.reset  (bool): default true (hard reset to origin/<branch>)
local function ensureSpoonGit(name, url, opts)
    opts         = opts or {}
    local branch = opts.branch or "main"
    local depth  = opts.depth or 1
    local reset  = (opts.reset ~= false)

    local target = string.format("%s/%s.spoon", SPOON_DIR, name)
    hs.fs.mkdir(SPOON_DIR)

    if not exists(target) then
        hs.alert.show("Installing " .. name .. " (" .. branch .. ")...")
        local cmd = string.format(
            [[/usr/bin/git clone --branch %q --depth %d %q %q]],
            branch, depth, url, target
        )
        local ok = sh(cmd)
        if not ok then
            hs.alert.show("Clone failed for " .. name)
            return false
        end
    else
        if not exists(target .. "/.git") then
            -- replace non-git (e.g., a zipped SpoonInstall copy)
            sh(string.format([[rm -rf %q]], target))
            local ok = sh(string.format(
                [[/usr/bin/git clone --branch %q --depth %d %q %q]],
                branch, depth, url, target
            ))
            if not ok then
                hs.alert.show("Re-clone failed for " .. name)
                return false
            end
        else
            -- update existing git checkout
            sh(string.format([[/usr/bin/git -C %q remote set-url origin %q]], target, url))
            sh(string.format([[/usr/bin/git -C %q fetch --prune origin]], target))
            sh(string.format([[ /usr/bin/git -C %q checkout %q ]], target, branch))
            if reset then
                sh(string.format([[ /usr/bin/git -C %q reset --hard origin/%q ]], target, branch))
            else
                sh(string.format([[ /usr/bin/git -C %q pull --ff-only origin %q ]], target, branch))
            end
        end
    end

    -- log the exact build
    local _, b = sh(string.format([[ /usr/bin/git -C %q rev-parse --abbrev-ref HEAD ]], target))
    local _, c = sh(string.format([[ /usr/bin/git -C %q log -1 --pretty=%%h ]], target))
    hs.printf("%s.spoon => branch=%s commit=%s", name, (b:gsub("$", "")), (c:gsub("$", "")))
    return true
end

------------------------------------------------------------
-- 2) PaperWM (from git) using the chosen branch
------------------------------------------------------------
local PAPERWM_REPO = "https://github.com/mogenson/PaperWM.spoon"
local PAPERWM_NAME = "PaperWM"
local PAPERWM_PATH = string.format("%s/%s.spoon", SPOON_DIR, PAPERWM_NAME)

ensureSpoonGit(PAPERWM_NAME, PAPERWM_REPO, { branch = PAPERWM_BRANCH, depth = 1, reset = true })

PaperWM               = hs.loadSpoon("PaperWM")

-- Base config
PaperWM.screen_margin = 16
PaperWM.window_gap    = 2

-- Exclude Safari from PaperWM management (and thus from PaperWM focus)
-- Do this before start(); then refresh *after* start() when API is ready.
PaperWM.window_filter:setAppFilter("Safari", false)

-- Start it
PaperWM:start()

-- Now that PaperWM is started, its methods are available
hs.timer.doAfter(0.05, function()
    if PaperWM.refreshWindows then PaperWM:refreshWindows() end
end)

-- For visibility: say which branch is running
hs.printf("PaperWM running from %s (branch=%s)", PAPERWM_PATH, PAPERWM_BRANCH)

------------------------------------------------------------
-- 3) Your existing PaperWM customizations (unchanged)
------------------------------------------------------------
local s = PaperWM -- alias for brevity


-- 1) Bind defaults
s:bindHotkeys(s.default_hotkeys)

-- 2) Make "half" the only width in the cycle list
s.window_ratios = { 1 / 2 }

-- 3) Auto-normalize new/visible windows to 50%
local A = s.actions.actions()
local normalized = {}

local function normalizeToHalf(win)
    if not win then return end
    local id = win:id()
    if not id or normalized[id] then return end
    if not s.window_filter:isWindowAllowed(win) then return end
    s:refreshWindows()
    hs.timer.doAfter(0.10, function()
        local prev = hs.window.frontmostWindow()
        win:focus(); A.cycle_width(); normalized[id] = true
        if prev and prev:id() ~= id then prev:focus() end
    end)
end

s.window_filter:subscribe({
    hs.window.filter.windowCreated,
    hs.window.filter.windowVisible,
}, function(win)
    hs.timer.doAfter(0.05, function() normalizeToHalf(win) end)
end)

-- Helpers
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function() A.refresh_windows() end)

-- Modal Nav Mode
local nav = hs.hotkey.modal.new({ "cmd" }, "return")
local tip
function nav:entered() tip = hs.alert.show("PaperWM: NAV MODE  (Esc to exit)") end

function nav:exited() if tip then hs.alert.closeAll() end end

local function now() return hs.timer.secondsSinceEpoch() end
local lastMoveAt = 0

local function wrapMove(fn)
    return function()
        lastMoveAt = now()
        if _G.FocusMode and FocusMode._running and FocusMode._suspend then
            FocusMode:_suspend(1.2)
        end
        fn(); hs.timer.doAfter(0.25, A.refresh_windows)
    end
end

local function withRefresh(fn)
    return function()
        local dt = now() - lastMoveAt
        if dt < 1.0 then
            hs.timer.doAfter(0.15, function()
                A.refresh_windows(); fn()
            end)
        else
            A.refresh_windows(); fn()
        end
    end
end

local function wrapSwitch(fn)
    return function()
        fn(); hs.timer.doAfter(0.25, A.refresh_windows)
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

------------------------------------------------------------
-- 4) Optional: other spoons via ensureSpoonGit
------------------------------------------------------------
ensureSpoonGit("ActiveSpace", "https://github.com/mogenson/ActiveSpace.spoon", { branch = "main" })
ActiveSpace = hs.loadSpoon("ActiveSpace"); ActiveSpace:start()

ensureSpoonGit("WarpMouse", "https://github.com/mogenson/WarpMouse.spoon", { branch = "main" })
WarpMouse = hs.loadSpoon("WarpMouse"); WarpMouse:start()



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
