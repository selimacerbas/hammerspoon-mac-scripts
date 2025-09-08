--- === CursorScope ===
--- Cursor highlight + live magnifier (“scope”) that follows the cursor across displays.
--- New:
---   • Fix: snapshot follows the *current* screen (uses absolute→local coords)
---   • position = { corner = "bottomRight"|"topRight"|"bottomLeft"|"topLeft", x = 20, y = 80 }
---   • scopeShape = "rectangle" | "circle"
local obj              = {}
obj.__index            = obj

obj.name               = "CursorScope"
obj.version            = "0.2.0"
obj.author             = "You"
obj.license            = "MIT"

-- Defaults
obj._cfg               = {
    shape             = "ring", -- highlight: "ring" | "crosshair" | "dot"
    idleColor         = { red = 0, green = 0.6, blue = 1, alpha = 0.9 },
    clickColor        = { red = 1, green = 0, blue = 0, alpha = 0.95 },
    radius            = 28,
    lineWidth         = 4,

    scopeSize         = 220,         -- px
    scopeZoom         = 2.0,         -- 1.5–4.0 recommended
    scopeShape        = "rectangle", -- "rectangle" | "circle"
    scopeCornerRadius = 12,          -- for rectangle shape
    scopeBorderWidth  = 2,
    scopeBorderColor  = { red = 1, green = 1, blue = 1, alpha = 0.9 },
    scopeBackground   = { red = 0, green = 0, blue = 0, alpha = 0.25 },

    position          = { corner = "bottomRight", x = 20, y = 80 }, -- corner & offsets
    margin            = 12,                                         -- kept for back-compat; ignored when position is set
}

obj._running           = false
obj._log               = hs.logger.new("CursorScope", "info")

-- UI objects
obj._highlightCircle   = nil
obj._crosshairH        = nil
obj._crosshairV        = nil
obj._dot               = nil
obj._scopeCanvas       = nil
obj._menubar           = nil
obj._scopeShapeApplied = nil

-- Infra
obj._mouseTap          = nil
obj._timer             = nil
obj._lastPos           = hs.mouse.getAbsolutePosition()
obj._lastScreen        = nil
obj._currentColor      = obj._cfg.idleColor

obj.defaultHotkeys     = {
    start = { { "ctrl", "alt", "cmd" }, "Z" },
    stop  = { { "ctrl", "alt", "cmd" }, "U" },
}

-- Utils
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

function obj:configure(cfg)
    if type(cfg) == "table" then for k, v in pairs(cfg) do self._cfg[k] = v end end
    return self
end

-- Menubar
function obj:_ensureMenubar(on)
    if on and not self._menubar then
        self._menubar = hs.menubar.new()
        if self._menubar then
            self._menubar:setTitle("🎯")
            self._menubar:setTooltip("CursorScope is ON — click to stop")
            self._menubar:setClickCallback(function() self:stop() end)
        end
    elseif not on and self._menubar then
        self._menubar:delete(); self._menubar = nil
    end
end

-- Highlight (hs.drawing for light weight)
function obj:_buildHighlight()
    self:_destroyHighlight()
    local r, lw, col = self._cfg.radius, self._cfg.lineWidth, self._currentColor
    local pos = hs.mouse.getAbsolutePosition()
    local frame = hs.geometry.rect(pos.x - r, pos.y - r, 2 * r, 2 * r)

    if self._cfg.shape == "ring" then
        local c = hs.drawing.circle(frame)
        c:setStroke(true):setFill(false):setStrokeColor(col):setStrokeWidth(lw)
        c:setBehaviorByLabels({ "canJoinAllSpaces" }):setLevel(hs.drawing.windowLevels.overlay):show()
        self._highlightCircle = c
    elseif self._cfg.shape == "crosshair" then
        local h = hs.drawing.line({ x = pos.x - r, y = pos.y }, { x = pos.x + r, y = pos.y })
        local v = hs.drawing.line({ x = pos.x, y = pos.y - r }, { x = pos.x, y = pos.y + r })
        for _, line in ipairs({ h, v }) do
            line:setStroke(true):setStrokeColor(col):setStrokeWidth(lw)
            line:setBehaviorByLabels({ "canJoinAllSpaces" }):setLevel(hs.drawing.windowLevels.overlay):show()
        end
        self._crosshairH, self._crosshairV = h, v
    else
        local d = hs.drawing.circle(hs.geometry.rect(pos.x - r / 2, pos.y - r / 2, r, r))
        d:setFill(true):setStroke(false):setFillColor(col)
        d:setBehaviorByLabels({ "canJoinAllSpaces" }):setLevel(hs.drawing.windowLevels.overlay):show()
        self._dot = d
    end
end

function obj:_destroyHighlight()
    local function kill(d) if d then d:delete() end end
    kill(self._highlightCircle); self._highlightCircle = nil
    kill(self._crosshairH); self._crosshairH = nil
    kill(self._crosshairV); self._crosshairV = nil
    kill(self._dot); self._dot = nil
end

function obj:_recolorHighlight(col)
    self._currentColor = col
    if self._highlightCircle then self._highlightCircle:setStrokeColor(col) end
    if self._crosshairH then self._crosshairH:setStrokeColor(col) end
    if self._crosshairV then self._crosshairV:setStrokeColor(col) end
    if self._dot then self._dot:setFillColor(col) end
end

function obj:_moveHighlight(pos)
    local r = self._cfg.radius
    if self._highlightCircle then
        self._highlightCircle:setFrame(hs.geometry.rect(pos.x - r, pos.y - r, 2 * r, 2 * r))
    end
    if self._crosshairH and self._crosshairV then
        self._crosshairH:setTopLeft({ x = pos.x - r, y = pos.y }); self._crosshairH:setSize({ w = 2 * r, h = 0 })
        self._crosshairV:setTopLeft({ x = pos.x, y = pos.y - r }); self._crosshairV:setSize({ w = 0, h = 2 * r })
    end
    if self._dot then
        self._dot:setFrame(hs.geometry.rect(pos.x - r / 2, pos.y - r / 2, r, r))
    end
end

-- Scope UI

-- Compute scope frame from corner + offsets
function obj:_calcScopeFrame(screen)
    local sz     = self._cfg.scopeSize
    local sf     = screen:fullFrame()
    local pos    = self._cfg.position or {}
    local corner = (pos.corner or "bottomRight")
    local ox     = pos.x or self._cfg.margin
    local oy     = pos.y or self._cfg.margin

    local x, y
    if corner == "bottomRight" then
        x = sf.x + sf.w - sz - ox; y = sf.y + sf.h - sz - oy
    elseif corner == "topRight" then
        x = sf.x + sf.w - sz - ox; y = sf.y + oy
    elseif corner == "bottomLeft" then
        x = sf.x + ox; y = sf.y + sf.h - sz - oy
    else -- topLeft
        x = sf.x + ox; y = sf.y + oy
    end
    return hs.geometry.rect(x, y, sz, sz)
end

-- build/rebuild canvas when needed (e.g. shape change)
function obj:_buildScopeCanvas(frame)
    if self._scopeCanvas then
        self._scopeCanvas:delete(); self._scopeCanvas = nil
    end
    local cv = hs.canvas.new(frame)
    cv:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    cv:level(hs.canvas.windowLevels.overlay)

    local shape = (self._cfg.scopeShape or "rectangle")
    if shape == "circle" then
        -- 1) clip to circle
        cv[#cv + 1] = { id = "clip", type = "oval", action = "clip", frame = { x = 0, y = 0, w = 100, h = 100 } }
        -- 2) background (clipped)
        cv[#cv + 1] = { id = "bg", type = "rectangle", action = "fill", fillColor = self._cfg.scopeBackground, frame = { x = 0, y = 0, w = 100, h = 100 } }
        -- 3) image (clipped)
        cv[#cv + 1] = { id = "img", type = "image", image = nil, imageScaling = "scaleToFit", frame = { x = 0, y = 0, w = 100, h = 100 } }
        -- 4) reset clip so the border isn’t clipped
        cv[#cv + 1] = { id = "reset", type = "resetClip" }
        -- 5) circular border (on top)
        cv[#cv + 1] = {
            id = "border",
            type = "oval",
            action = "stroke",
            strokeColor = self._cfg.scopeBorderColor,
            strokeWidth = self._cfg.scopeBorderWidth,
            frame = { x = 0, y = 0, w = 100, h = 100 },
        }
    else
        -- rectangle with optional rounded corners
        cv[#cv + 1] = {
            id = "bg",
            type = "rectangle",
            action = "fill",
            fillColor = self._cfg.scopeBackground,
            frame = { x = 0, y = 0, w = 100, h = 100 },
            roundedRectRadii = { xRadius = self._cfg.scopeCornerRadius, yRadius = self._cfg.scopeCornerRadius },
        }
        cv[#cv + 1] = { id = "img", type = "image", image = nil, imageScaling = "scaleToFit", frame = { x = 0, y = 0, w = 100, h = 100 } }
        cv[#cv + 1] = {
            id = "border",
            type = "rectangle",
            action = "stroke",
            strokeColor = self._cfg.scopeBorderColor,
            strokeWidth = self._cfg.scopeBorderWidth,
            frame = { x = 0, y = 0, w = 100, h = 100 },
            roundedRectRadii = { xRadius = self._cfg.scopeCornerRadius, yRadius = self._cfg.scopeCornerRadius },
        }
    end

    self._scopeCanvas = cv
    self._scopeShapeApplied = shape
    cv:show()
end

-- ensure canvas exists and is on proper screen/position; rebuild if shape changed
function obj:_ensureScopeOnScreen(screen)
    local frame = self:_calcScopeFrame(screen)
    if not self._scopeCanvas or self._scopeShapeApplied ~= (self._cfg.scopeShape or "rectangle") then
        self:_buildScopeCanvas(frame)
    else
        self._scopeCanvas:frame(frame)
    end
end

-- Capture under cursor and update scope image
function obj:_updateScopeImage(pos, screen)
    if not self._scopeCanvas then return end

    local sz           = self._cfg.scopeSize
    local zoom         = self._cfg.scopeZoom
    local capW         = math.floor(sz / zoom)
    local capH         = math.floor(sz / zoom)
    local halfW        = math.floor(capW / 2)
    local halfH        = math.floor(capH / 2)

    local sf           = screen:fullFrame()
    -- Compute capture in ABSOLUTE coords
    local absX         = clamp(pos.x - halfW, sf.x, sf.x + sf.w - capW)
    local absY         = clamp(pos.y - halfH, sf.y, sf.y + sf.h - capH)
    local capRectAbs   = hs.geometry.rect(absX, absY, capW, capH)

    -- *** KEY FIX: convert ABSOLUTE -> LOCAL before snapshotting this screen ***
    local capRectLocal = screen:absoluteToLocal(capRectAbs)
    local img          = screen:snapshot(capRectLocal)
    if img then self._scopeCanvas["img"].image = img end
end

-- Event taps and timer
function obj:_startEventTapAndTimer()
    local ev = hs.eventtap.event.types
    self._mouseTap = hs.eventtap.new({ ev.mouseMoved, ev.leftMouseDown, ev.rightMouseDown, ev.otherMouseDown },
        function(e)
            local typ = e:getType()
            if typ == ev.mouseMoved then
                self._lastPos = hs.mouse.getAbsolutePosition()
            else
                self:_recolorHighlight(self._cfg.clickColor)
                hs.timer.doAfter(0.15,
                    function() if self._running then self:_recolorHighlight(self._cfg.idleColor) end end)
            end
            return false
        end):start()

    self._timer = hs.timer.doEvery(1 / 30, function()
        local pos = self._lastPos
        local scr = hs.mouse.getCurrentScreen() or self._lastScreen or hs.screen.mainScreen()
        if not scr then return end
        if self._lastScreen ~= scr then
            self:_ensureScopeOnScreen(scr) -- rebuild/move scope for new display
            self._lastScreen = scr
        end
        self:_moveHighlight(pos)
        self:_updateScopeImage(pos, scr)
    end)
end

function obj:_stopEventTapAndTimer()
    if self._mouseTap then
        self._mouseTap:stop(); self._mouseTap = nil
    end
    if self._timer then
        self._timer:stop(); self._timer = nil
    end
end

-- Public
function obj:start()
    if self._running then return self end
    self._running = true
    self._currentColor = self._cfg.idleColor
    self:_buildHighlight()
    local scr = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    self:_ensureScopeOnScreen(scr)
    self._lastScreen = scr
    self:_startEventTapAndTimer()
    self:_ensureMenubar(true)
    return self
end

function obj:stop()
    if not self._running then return self end
    self._running = false
    self:_stopEventTapAndTimer()
    self:_destroyHighlight()
    if self._scopeCanvas then
        self._scopeCanvas:delete(); self._scopeCanvas = nil
    end
    self:_ensureMenubar(false)
    return self
end

function obj:toggle() if self._running then return self:stop() else return self:start() end end

function obj:bindHotkeys(map)
    map = map or self.defaultHotkeys
    if map.start then hs.hotkey.bind(map.start[1], map.start[2], function() self:start() end) end
    if map.stop then hs.hotkey.bind(map.stop[1], map.stop[2], function() self:stop() end) end
    if map.toggle then hs.hotkey.bind(map.toggle[1], map.toggle[2], function() self:toggle() end) end
    return self
end

return obj
