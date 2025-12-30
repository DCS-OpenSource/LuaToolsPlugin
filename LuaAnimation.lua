-- animator.lua
-- Simple animator for DCS draw arguments.
-- - speed = seconds to sweep the FULL range (min -> max).
-- - Moving a partial distance takes proportionally less time.
-- - Call animator:update() once per device update.

local animator = {}
animator.__index = animator

-- Animation object
local animation = {}
animation.__index = animation

local cockpit = GetDevice(0) -- mainpanel device for internal animations

-- Helpers
local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

local function apply_draw_and_clickable(anim)
    if anim.cockpit == true then
        cockpit:set_argument_value(anim.arg_num, anim.value)
    else
        set_aircraft_draw_argument_value(anim.arg_num, anim.value)
    end
    
    if anim.clickableName then
        local ref = get_clickable_element_reference(anim.clickableName)
        if ref and ref.update then ref:update() end
    end
end

--- Constructor
--- @param update_rate number must match your device make_default_activity rate (seconds)
function animator:new(update_rate)
    local self = setmetatable({}, animator)
    self.update_rate = update_rate or 0.05
    self.animations = {}
    return self
end

--- Register a new animation
--- @param arg_num number
--- @param range table {min, max}
--- @param speed number seconds to traverse full range (min->max)
--- @param loop boolean|nil if true, animation ping-pongs between min and max
--- @param isCockpit boolean|nil if true, animates the cockpit instead of external model
function animator:create(arg_num, range, speed, loop, isCockpit)
    local a = setmetatable({
        arg_num  = arg_num,
        min      = range[1],
        max      = range[2],
        speed    = (speed and speed > 0) and speed or 1.0,
        value    = range[1],
        target   = range[1],
        running  = false,
        clickableName = nil,   -- optional: name for get_clickable_element_reference()
        param = nil,
        loop = loop or false,
        cockpit = isCockpit or false
    }, animation)

    table.insert(self.animations, a)
    return a
end

-- ================= Animation instance methods =================

--- Start animating toward a target. If target is nil, toggles min/max.
--- @param target number|nil
function animation:start(target)
    local lo = math.min(self.min, self.max)
    local hi = math.max(self.min, self.max)

    if target == nil then
        -- Toggle based on midpoint
        local mid = (self.min + self.max) * 0.5
        target = (self.value < mid) and self.max or self.min
    else
        target = clamp(target, lo, hi)
    end

    self.target  = target
    self.running = (self.value ~= self.target)
end

--- Instantly set value (no animation)
--- @param value number
function animation:set(value)
    local lo = math.min(self.min, self.max)
    local hi = math.max(self.min, self.max)
    self.value   = clamp(value, lo, hi)
    self.target  = self.value
    self.running = false
    apply_draw_and_clickable(self)
end

--- Optional: mark a clickable to be refreshed each update
--- @param name string
function animation:setClickableUpdate(name)
    self.clickableName = name
end

--- Optional: Create a param handle
--- @param paramName string
function animation:setParamName(paramName)
    self.param = get_param_handle(paramName)
end

--- Optional helpers
function animation:isRunning() return self.running end
function animation:get() return self.value end
function animation:stop() self.running = false end

-- ================= Animator update loop =================

--- Advance all animations one tick (call in your device update())
function animator:update()
    -- Be defensive: if animations table doesn't exist, just no-op
    if not self.animations or #self.animations == 0 then return end

    local eps = 1e-6

    for _, anim in ipairs(self.animations) do
        if anim.running then
            -- Full range in `speed` seconds -> per-tick step based on full range
            local fullRange = math.abs(anim.max - anim.min)
            if fullRange <= 1e-12 then
                -- Degenerate range: jump to target and stop
                anim.value   = anim.target
                anim.running = false
            else
                local step      = fullRange * (self.update_rate / anim.speed)
                local remaining = math.abs(anim.target - anim.value)

                if remaining <= step then
                    -- We consider this "reached target"
                    anim.value = anim.target

                    if anim.loop then
                        -- SAWTOOTH / WRAP LOOP:
                        -- Always loop from low -> high.
                        local lo = math.min(anim.min, anim.max)
                        local hi = math.max(anim.min, anim.max)

                        -- If we reached (or are very close to) the high end,
                        -- snap back to low and go up again.
                        if math.abs(anim.target - hi) <= eps then
                            anim.value   = lo   -- snap to start
                            anim.target  = hi   -- and head to end again
                            anim.running = true
                        else
                            -- If target wasn't exactly at hi (e.g. someone set a mid target),
                            -- just restart the loop from lo -> hi as well.
                            anim.value   = lo
                            anim.target  = hi
                            anim.running = true
                        end
                    else
                        anim.running = false
                    end
                else
                    -- Normal movement toward target
                    anim.value = anim.value + (anim.target > anim.value and step or -step)
                end
            end

            if anim.param then
                anim.param:set(anim.value)
            end
        end

        -- Always apply draw & clickable, even when not moving
        apply_draw_and_clickable(anim)
    end
end


return animator
