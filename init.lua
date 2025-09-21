------------------------------------------------------------
-- 0) Generic git-based spoon installer/updater
------------------------------------------------------------
local HOME      = os.getenv("HOME")
local SPOON_DIR = HOME .. "/.hammerspoon/Spoons"

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

    -- Path A: in-place update if target is a git repo already
    if exists(target) and exists(target .. "/.git") then
        sh(string.format([[/usr/bin/git -C %q remote set-url origin %q]], target, url))
        sh(string.format([[/usr/bin/git -C %q fetch --prune origin]], target))
        sh(string.format([[ /usr/bin/git -C %q checkout %q ]], target, branch))
        if reset then
            sh(string.format([[ /usr/bin/git -C %q reset --hard origin/%q ]], target, branch))
        else
            sh(string.format([[ /usr/bin/git -C %q pull --ff-only origin %q ]], target, branch))
        end
    else
        -- Path B: clone fresh to a temp dir and move *.spoon folder into place
        local tmp = string.format("%s/._tmp_%s_%d", SPOON_DIR, name, os.time())
        sh(string.format([[rm -rf %q]], tmp))
        local ok = sh(string.format(
            [[/usr/bin/git clone --branch %q --depth %d %q %q]],
            branch, depth, url, tmp
        ))
        if not ok then
            hs.alert.show("Clone failed for " .. name)
            return false
        end

        -- Find the actual spoon directory within the repo (supports nested layouts)
        local candidate = tmp .. "/" .. name .. ".spoon"
        local src
        if exists(candidate) then
            src = candidate
        else
            local iter, dirObj = hs.fs.dir(tmp)
            if iter then
                for f in iter, dirObj do
                    if f and f:match("%.spoon$") then
                        src = tmp .. "/" .. f; break
                    end
                end
            end
            src = src or tmp -- fallback: repo itself is the spoon
        end

        sh(string.format([[rm -rf %q]], target))
        sh(string.format([[mkdir -p %q]], SPOON_DIR))
        sh(string.format([[mv %q %q]], src, target))
        sh(string.format([[rm -rf %q]], tmp))
    end

    -- If target is not a spoon root (missing init.lua), do a one-shot unpack
    if not exists(target .. "/init.lua") then
        local tmp = string.format("%s/._tmp_fix_%s_%d", SPOON_DIR, name, os.time())
        sh(string.format([[rm -rf %q]], tmp))
        local ok = sh(string.format(
            [[/usr/bin/git clone --branch %q --depth %d %q %q]],
            branch, depth, url, tmp
        ))
        if ok then
            local candidate = tmp .. "/" .. name .. ".spoon"
            local src
            if exists(candidate) then
                src = candidate
            else
                local iter, dirObj = hs.fs.dir(tmp)
                if iter then
                    for f in iter, dirObj do
                        if f and f:match("%.spoon$") then
                            src = tmp .. "/" .. f; break
                        end
                    end
                end
                src = src or tmp
            end
            sh(string.format([[rm -rf %q]], target))
            sh(string.format([[mv %q %q]], src, target))
        end
        sh(string.format([[rm -rf %q]], tmp))
    end

    -- Log the exact build
    local _, b = sh(string.format([[ /usr/bin/git -C %q rev-parse --abbrev-ref HEAD ]], target))
    local _, c = sh(string.format([[ /usr/bin/git -C %q log -1 --pretty=%%h ]], target))
    b = (b or ""):gsub("$", "")
    c = (c or ""):gsub("$", "")
    hs.printf("%s.spoon => branch=%s commit=%s", name, b, c)
    return true
end

-- === Soft reload (skip repo updates) ===
local ENSURE_SKIP_KEY = "EnsureSpoons.skip"
local skipEnsures = hs.settings.get(ENSURE_SKIP_KEY) == true
if skipEnsures then hs.settings.set(ENSURE_SKIP_KEY, false) end

-- Hotkey: Ctrl+Alt+Cmd+L → reload without updating any spoons
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "L", function()
    hs.settings.set(ENSURE_SKIP_KEY, true)
    hs.alert.show("Reloading without updating spoons…")
    hs.reload()
end)

------------------------------------------------------------
-- 1) FocusMode
------------------------------------------------------------
ensureSpoonGit("FocusMode", "https://github.com/mogenson/FocusMode.spoon", { branch = "main" })
FocusMode = hs.loadSpoon("FocusMode")

FocusMode.dimAlpha = 0.5
FocusMode.mouseDim = true
FocusMode.windowCornerRadius = 8
FocusMode:bindHotkeys({
    start = { { "ctrl", "alt", "cmd" }, "I" },
    stop  = { { "ctrl", "alt", "cmd" }, "O" },
})
FocusMode:start()

------------------------------------------------------------
-- 2) CursorScope
------------------------------------------------------------
if not skipEnsures then
    ensureSpoonGit("CursorScope", "https://github.com/selimacerbas/CursorScope.spoon",
        { branch = "main" })
end
CursorScope = hs.loadSpoon("CursorScope")
CursorScope:configure({
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
CursorScope:bindHotkeys()

------------------------------------------------------------
-- 3) PaperWM
------------------------------------------------------------
local PAPERWM_BRANCH = "main"
local PAPERWM_REPO   = "https://github.com/mogenson/PaperWM.spoon"
local PAPERWM_NAME   = "PaperWM"
local PAPERWM_PATH   = string.format("%s/%s.spoon", SPOON_DIR, PAPERWM_NAME)

if not skipEnsures then ensureSpoonGit(PAPERWM_NAME, PAPERWM_REPO, { branch = PAPERWM_BRANCH, depth = 1, reset = true }) end

PaperWM               = hs.loadSpoon("PaperWM")
PaperWM.screen_margin = 16
PaperWM.window_gap    = 2
PaperWM.window_filter:setAppFilter("Safari", false)
PaperWM:start()
hs.timer.doAfter(0.05, function()
    if PaperWM.refreshWindows then PaperWM:refreshWindows() end
end)

hs.printf("PaperWM running from %s (branch=%s)", PAPERWM_PATH, PAPERWM_BRANCH)

local s = PaperWM
s:bindHotkeys(s.default_hotkeys)
s.window_ratios = { 1 / 2 }

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
s.window_filter:subscribe({ hs.window.filter.windowCreated, hs.window.filter.windowVisible }, function(win)
    hs.timer.doAfter(0.05, function() normalizeToHalf(win) end)
end)

hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "R", function() A.refresh_windows() end)

local nav = hs.hotkey.modal.new({ "cmd" }, "return")
local tip
function nav:entered() tip = hs.alert.show("PaperWM: NAV MODE (Esc to exit)") end

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
-- 4) ActiveSpace & WarpMouse
------------------------------------------------------------
if not skipEnsures then
    ensureSpoonGit("ActiveSpace", "https://github.com/mogenson/ActiveSpace.spoon",
        { branch = "main" })
end
ActiveSpace = hs.loadSpoon("ActiveSpace"); ActiveSpace:start()

if not skipEnsures then ensureSpoonGit("WarpMouse", "https://github.com/mogenson/WarpMouse.spoon", { branch = "main" }) end
WarpMouse = hs.loadSpoon("WarpMouse"); WarpMouse:start()

------------------------------------------------------------
-- 5) KeyCaster
------------------------------------------------------------
if not skipEnsures then
    ensureSpoonGit("KeyCaster", "https://github.com/selimacerbas/KeyCaster.spoon",
        { branch = "main" })
end
KeyCaster = hs.loadSpoon("KeyCaster")
KeyCaster:bindHotkeys(KeyCaster.defaultHotkeys)

------------------------------------------------------------
-- 6) Vifari
------------------------------------------------------------
if not skipEnsures then ensureSpoonGit("Vifari", "https://github.com/dzirtusss/vifari", { branch = "main" }) end
Vifari = hs.loadSpoon("Vifari"); Vifari:start()

------------------------------------------------------------
-- Tips: Mission Control settings
-- - Uncheck: “Automatically rearrange Spaces based on most recent use”
-- - Check:   “Displays have separate Spaces”
------------------------------------------------------------
